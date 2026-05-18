"""Rating service: applies Glicko-2 updates on match validation.

Engine details:
- Ratings stored on Glicko-2 native scale (1500 mean, 350 max RD).
- Singles: standard Glicko-2 between two players.
- Doubles: each player updated as if they played 1v1 vs the opposing team
  average rating (RD via quadratic mean).
- The final rating *delta* is scaled by a multiplicative
  margin/length factor (see ``app.rating.adjustments``) so blowouts move
  ratings more than nail-biters and shorter games move them less.
- Ratings floor at ``settings.rating_floor`` (default 100).
"""
from __future__ import annotations
import math
import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.db.models import (
    Match, MatchGame, MatchParticipant, PlayerRating, RatingEvent,
)
from app.rating.adjustments import match_adjustment
from app.rating.glicko2 import Rating, update as glicko_update


async def _load_participants(
    session: AsyncSession, match_id: uuid.UUID
) -> list[MatchParticipant]:
    res = await session.execute(
        select(MatchParticipant).where(MatchParticipant.match_id == match_id)
    )
    return list(res.scalars().all())


async def _load_rating(
    session: AsyncSession, player_id: uuid.UUID, fmt: str
) -> PlayerRating:
    res = await session.execute(
        select(PlayerRating).where(
            (PlayerRating.player_id == player_id) & (PlayerRating.format == fmt)
        )
    )
    return res.scalar_one()


async def _load_games(
    session: AsyncSession, match_id: uuid.UUID
) -> list[MatchGame]:
    res = await session.execute(
        select(MatchGame)
        .where(MatchGame.match_id == match_id)
        .order_by(MatchGame.game_no)
    )
    return list(res.scalars().all())


def _floor(rating: float) -> float:
    return max(settings.rating_floor, rating)


async def apply_singles_update(
    session: AsyncSession, match_id: uuid.UUID, winning_team: int
) -> None:
    parts = await _load_participants(session, match_id)
    assert len(parts) == 2, "singles must have exactly 2 participants"

    games_rows = await _load_games(session, match_id)
    games = [(g.team1_points, g.team2_points) for g in games_rows]
    mult = match_adjustment(games, winning_team)

    by_team = {p.team: p for p in parts}
    ratings = {
        p.player_id: await _load_rating(session, p.player_id, "S")
        for p in parts
    }

    for me_team, opp_team in [(1, 2), (2, 1)]:
        me = by_team[me_team]
        opp = by_team[opp_team]
        r_me = ratings[me.player_id]
        r_opp = ratings[opp.player_id]
        score = 1.0 if winning_team == me_team else 0.0

        g_me = Rating(r_me.rating, r_me.rd, r_me.volatility)
        g_opp = Rating(r_opp.rating, r_opp.rd, r_opp.volatility)
        new = glicko_update(g_me, [g_opp], [score])

        delta = new.rating - r_me.rating
        new_rating = _floor(r_me.rating + delta * mult)

        session.add(RatingEvent(
            player_id=me.player_id, match_id=match_id, format="S",
            rating_before=r_me.rating, rating_after=new_rating,
            rd_before=r_me.rd, rd_after=new.rd,
        ))
        r_me.rating = new_rating
        r_me.rd = new.rd
        r_me.volatility = new.volatility
        r_me.matches_played += 1


async def apply_doubles_update(
    session: AsyncSession, match_id: uuid.UUID, winning_team: int
) -> None:
    parts = await _load_participants(session, match_id)
    assert len(parts) == 4, "doubles must have exactly 4 participants"

    games_rows = await _load_games(session, match_id)
    games = [(g.team1_points, g.team2_points) for g in games_rows]
    mult = match_adjustment(games, winning_team)

    teams: dict[int, list[MatchParticipant]] = {1: [], 2: []}
    for p in parts:
        teams[p.team].append(p)
    assert len(teams[1]) == 2 and len(teams[2]) == 2

    ratings = {
        p.player_id: await _load_rating(session, p.player_id, "D")
        for p in parts
    }

    team_avg = {
        t: sum(ratings[p.player_id].rating for p in teams[t]) / 2.0
        for t in (1, 2)
    }
    # Quadratic mean for opposing-team RD: sqrt((rd1² + rd2²) / 2).
    team_rd = {
        t: math.sqrt(
            (ratings[teams[t][0].player_id].rd ** 2
             + ratings[teams[t][1].player_id].rd ** 2) / 2.0
        )
        for t in (1, 2)
    }

    for t, opp_t in [(1, 2), (2, 1)]:
        score = 1.0 if winning_team == t else 0.0
        for p in teams[t]:
            r = ratings[p.player_id]
            g_me = Rating(r.rating, r.rd, r.volatility)
            g_opp = Rating(team_avg[opp_t], team_rd[opp_t], settings.initial_volatility)
            new = glicko_update(g_me, [g_opp], [score])

            delta = new.rating - r.rating
            new_rating = _floor(r.rating + delta * mult)

            session.add(RatingEvent(
                player_id=p.player_id, match_id=match_id, format="D",
                rating_before=r.rating, rating_after=new_rating,
                rd_before=r.rd, rd_after=new.rd,
            ))
            r.rating = new_rating
            r.rd = new.rd
            r.volatility = new.volatility
            r.matches_played += 1


async def apply_match_rating(
    session: AsyncSession, match: Match, winning_team: int
) -> None:
    if match.format == "S":
        await apply_singles_update(session, match.id, winning_team)
    else:
        await apply_doubles_update(session, match.id, winning_team)


async def age_rd_for_inactivity(
    session: AsyncSession, player_id: uuid.UUID, fmt: str, periods: int
) -> None:
    """Inflate a player's RD to reflect missed rating periods (days).

    Formula: phi' = sqrt(phi² + n * sigma²), capped at ``initial_rd``.
    Does NOT change the rating itself — only confidence in it.
    """
    pr = await _load_rating(session, player_id, fmt)
    phi = pr.rd / 173.7178
    sigma = pr.volatility
    phi_new = math.sqrt(phi * phi + periods * sigma * sigma) * 173.7178
    pr.rd = min(settings.initial_rd, phi_new)
