"""Persists Glicko-2 + margin updates to Postgres.

All ratings live on the `players` row directly (single rating per player).
"""
from __future__ import annotations
import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import (
    Match, MatchGame, MatchParticipant, Player, RatingEvent,
)
from app.rating import engine
from app.rating.engine import RatingSnapshot
from app.rating.glicko2 import Player as RatingPlayer


async def _load_participants(
    session: AsyncSession, match_id: uuid.UUID,
) -> list[MatchParticipant]:
    res = await session.execute(
        select(MatchParticipant).where(MatchParticipant.match_id == match_id)
    )
    return list(res.scalars().all())


async def _load_player(
    session: AsyncSession, player_id: uuid.UUID,
) -> Player:
    res = await session.execute(
        select(Player).where(Player.id == player_id)
    )
    return res.scalar_one()


async def _load_single_game(
    session: AsyncSession, match_id: uuid.UUID,
) -> tuple[int, int]:
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


def _to_rating_player(p: Player) -> RatingPlayer:
    return RatingPlayer(rating=p.rating, rd=p.rd, vol=p.volatility)


def _persist(p: Player, snap: RatingSnapshot) -> None:
    p.rating = snap.rating_after
    p.rd = snap.rd_after
    p.volatility = snap.vol_after
    p.matches_played += 1


def _write_event(
    session: AsyncSession, *,
    player_id: uuid.UUID, match_id: uuid.UUID, fmt: str,
    snap: RatingSnapshot,
) -> None:
    """Note: `fmt` is stored on the event for analytics ("was this match S
    or D?") but the rating itself is format-agnostic. The fmt column stays
    in the schema for now; can be dropped later if unused."""
    session.add(RatingEvent(
        player_id=player_id, match_id=match_id, format=fmt,
        rating_before=snap.rating_before, rating_after=snap.rating_after,
        rd_before=snap.rd_before, rd_after=snap.rd_after,
    ))


async def apply_singles_update(
    session: AsyncSession, match_id: uuid.UUID, winning_team: int,
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

    w_player = await _load_player(session, winner_part.player_id)
    l_player = await _load_player(session, loser_part.player_id)
    w_rp = _to_rating_player(w_player)
    l_rp = _to_rating_player(l_player)

    w_snap, l_snap = engine.update_singles(w_rp, l_rp, winner_score, loser_score)

    _write_event(session, player_id=winner_part.player_id, match_id=match_id,
                 fmt="S", snap=w_snap)
    _write_event(session, player_id=loser_part.player_id, match_id=match_id,
                 fmt="S", snap=l_snap)
    _persist(w_player, w_snap)
    _persist(l_player, l_snap)


async def apply_doubles_update(
    session: AsyncSession, match_id: uuid.UUID, winning_team: int,
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

    w_players = [await _load_player(session, mp.player_id) for mp in winner_parts]
    l_players = [await _load_player(session, mp.player_id) for mp in loser_parts]
    w_rps = [_to_rating_player(p) for p in w_players]
    l_rps = [_to_rating_player(p) for p in l_players]

    w1, w2, l1, l2 = engine.update_doubles(
        (w_rps[0], w_rps[1]), (l_rps[0], l_rps[1]),
        winner_score, loser_score,
    )
    snaps = [w1, w2, l1, l2]
    rows = winner_parts + loser_parts
    orm_players = w_players + l_players

    for mp, p, snap in zip(rows, orm_players, snaps, strict=True):
        _write_event(session, player_id=mp.player_id, match_id=match_id,
                     fmt="D", snap=snap)
        _persist(p, snap)


async def apply_match_rating(
    session: AsyncSession, match: Match, winning_team: int,
) -> None:
    if match.format == "S":
        await apply_singles_update(session, match.id, winning_team)
    else:
        await apply_doubles_update(session, match.id, winning_team)


async def age_rd_for_inactivity(
    session: AsyncSession, player_id: uuid.UUID, periods: int,
) -> None:
    p = await _load_player(session, player_id)
    rp = _to_rating_player(p)
    engine.age_rating(rp, periods)
    p.rd = rp.rd
