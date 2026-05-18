from __future__ import annotations
import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import (
    Match, MatchParticipant, PlayerRating, RatingEvent,
)
from app.rating.glicko2 import update as glicko_update
from app.rating.scale import from_display, to_display
from app.rating.doubles import carry_scaler


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


async def apply_singles_update(
    session: AsyncSession, match_id: uuid.UUID, winning_team: int
) -> None:
    parts = await _load_participants(session, match_id)
    assert len(parts) == 2, "singles must have exactly 2 participants"

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

        g_me = from_display(r_me.rating, r_me.rd, r_me.volatility)
        g_opp = from_display(r_opp.rating, r_opp.rd, r_opp.volatility)
        new = glicko_update(g_me, [g_opp], [score])
        new_rating, new_rd = to_display(new.rating, new.rd)

        session.add(RatingEvent(
            player_id=me.player_id, match_id=match_id, format="S",
            rating_before=r_me.rating, rating_after=new_rating,
            rd_before=r_me.rd, rd_after=new_rd,
        ))
        r_me.rating = new_rating
        r_me.rd = new_rd
        r_me.volatility = new.volatility
        r_me.matches_played += 1


async def apply_doubles_update(
    session: AsyncSession, match_id: uuid.UUID, winning_team: int
) -> None:
    parts = await _load_participants(session, match_id)
    assert len(parts) == 4, "doubles must have exactly 4 participants"

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
    team_rd = {
        t: ( (ratings[teams[t][0].player_id].rd ** 2
              + ratings[teams[t][1].player_id].rd ** 2) / 2.0 ) ** 0.5
        for t in (1, 2)
    }

    for t, opp_t in [(1, 2), (2, 1)]:
        score = 1.0 if winning_team == t else 0.0
        for p in teams[t]:
            r = ratings[p.player_id]
            g_me = from_display(r.rating, r.rd, r.volatility)
            g_opp = from_display(team_avg[opp_t], team_rd[opp_t], 0.06)
            new = glicko_update(g_me, [g_opp], [score])
            new_rating, new_rd = to_display(new.rating, new.rd)

            base_delta = new_rating - r.rating
            scaler = carry_scaler(r.rating, team_avg[t])
            final_rating = r.rating + base_delta * scaler

            session.add(RatingEvent(
                player_id=p.player_id, match_id=match_id, format="D",
                rating_before=r.rating, rating_after=final_rating,
                rd_before=r.rd, rd_after=new_rd,
            ))
            r.rating = final_rating
            r.rd = new_rd
            r.volatility = new.volatility
            r.matches_played += 1


async def apply_match_rating(
    session: AsyncSession, match: Match, winning_team: int
) -> None:
    if match.format == "S":
        await apply_singles_update(session, match.id, winning_team)
    else:
        await apply_doubles_update(session, match.id, winning_team)
