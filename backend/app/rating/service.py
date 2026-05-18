"""Persists Glicko-2 + margin/length updates back to Postgres.

The math lives in ``app.rating.engine`` (pure, no DB). This module:
  - Loads ``PlayerRating`` rows into Player objects
  - Calls the engine
  - Writes ``RatingEvent`` rows
  - Writes the updated state back to ``PlayerRating``
"""
from __future__ import annotations
import math
import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import (
    Match, MatchGame, MatchParticipant, PlayerRating, RatingEvent,
)
from app.rating import engine
from app.rating.engine import RatingSnapshot
from app.rating.glicko2 import Player


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


async def _load_single_game(
    session: AsyncSession, match_id: uuid.UUID
) -> tuple[int, int]:
    """Single-set matches only: return (team1, team2) points from game 1."""
    res = await session.execute(
        select(MatchGame).where(MatchGame.match_id == match_id)
    )
    games = list(res.scalars().all())
    if not games:
        raise ValueError(f"match {match_id} has no game")
    if len(games) > 1:
        raise ValueError(
            f"match {match_id} has {len(games)} games — engine is single-set only"
        )
    g = games[0]
    return g.team1_points, g.team2_points


def _to_player(pr: PlayerRating) -> Player:
    return Player(rating=pr.rating, rd=pr.rd, vol=pr.volatility)


def _write_event(session: AsyncSession, *,
                 player_id: uuid.UUID, match_id: uuid.UUID,
                 fmt: str, snap: RatingSnapshot) -> None:
    session.add(RatingEvent(
        player_id=player_id, match_id=match_id, format=fmt,
        rating_before=snap.rating_before, rating_after=snap.rating_after,
        rd_before=snap.rd_before, rd_after=snap.rd_after,
    ))


def _persist(pr: PlayerRating, snap: RatingSnapshot) -> None:
    """Write the new state back to the ORM row."""
    pr.rating = snap.rating_after
    pr.rd = snap.rd_after
    pr.volatility = snap.vol_after
    pr.matches_played += 1


async def apply_singles_update(
    session: AsyncSession, match_id: uuid.UUID, winning_team: int
) -> None:
    parts = await _load_participants(session, match_id)
    assert len(parts) == 2, "singles must have exactly 2 participants"

    t1_pts, t2_pts = await _load_single_game(session, match_id)
    if winning_team == 1:
        winner_score, loser_score = t1_pts, t2_pts
    else:
        winner_score, loser_score = t2_pts, t1_pts

    by_team = {p.team: p for p in parts}
    winner_part = by_team[winning_team]
    loser_part = by_team[3 - winning_team]

    pr_w = await _load_rating(session, winner_part.player_id, "S")
    pr_l = await _load_rating(session, loser_part.player_id, "S")
    pl_w = _to_player(pr_w)
    pl_l = _to_player(pr_l)

    w_snap, l_snap = engine.update_singles(
        pl_w, pl_l, winner_score, loser_score
    )

    _write_event(session, player_id=winner_part.player_id, match_id=match_id,
                 fmt="S", snap=w_snap)
    _write_event(session, player_id=loser_part.player_id, match_id=match_id,
                 fmt="S", snap=l_snap)
    _persist(pr_w, w_snap)
    _persist(pr_l, l_snap)


async def apply_doubles_update(
    session: AsyncSession, match_id: uuid.UUID, winning_team: int
) -> None:
    parts = await _load_participants(session, match_id)
    assert len(parts) == 4, "doubles must have exactly 4 participants"

    t1_pts, t2_pts = await _load_single_game(session, match_id)
    if winning_team == 1:
        winner_score, loser_score = t1_pts, t2_pts
    else:
        winner_score, loser_score = t2_pts, t1_pts

    teams: dict[int, list[MatchParticipant]] = {1: [], 2: []}
    for p in parts:
        teams[p.team].append(p)

    winner_parts = teams[winning_team]
    loser_parts = teams[3 - winning_team]

    pr_w1 = await _load_rating(session, winner_parts[0].player_id, "D")
    pr_w2 = await _load_rating(session, winner_parts[1].player_id, "D")
    pr_l1 = await _load_rating(session, loser_parts[0].player_id, "D")
    pr_l2 = await _load_rating(session, loser_parts[1].player_id, "D")

    pl_w1 = _to_player(pr_w1)
    pl_w2 = _to_player(pr_w2)
    pl_l1 = _to_player(pr_l1)
    pl_l2 = _to_player(pr_l2)

    w1_snap, w2_snap, l1_snap, l2_snap = engine.update_doubles(
        (pl_w1, pl_w2), (pl_l1, pl_l2), winner_score, loser_score
    )

    _write_event(session, player_id=winner_parts[0].player_id, match_id=match_id,
                 fmt="D", snap=w1_snap)
    _write_event(session, player_id=winner_parts[1].player_id, match_id=match_id,
                 fmt="D", snap=w2_snap)
    _write_event(session, player_id=loser_parts[0].player_id, match_id=match_id,
                 fmt="D", snap=l1_snap)
    _write_event(session, player_id=loser_parts[1].player_id, match_id=match_id,
                 fmt="D", snap=l2_snap)
    _persist(pr_w1, w1_snap)
    _persist(pr_w2, w2_snap)
    _persist(pr_l1, l1_snap)
    _persist(pr_l2, l2_snap)


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
    """Inflate a player's RD for N inactive rating periods. Wraps engine.age_rating."""
    pr = await _load_rating(session, player_id, fmt)
    p = _to_player(pr)
    engine.age_rating(p, periods)
    pr.rd = p.rd
