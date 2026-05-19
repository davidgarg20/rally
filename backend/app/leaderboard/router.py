from __future__ import annotations
from typing import Literal

from fastapi import APIRouter, Query
from pydantic import BaseModel
from sqlalchemy import select

from app.db.models import Player
from app.deps import CurrentIdentity, DbSession


router = APIRouter(prefix="/leaderboard", tags=["leaderboard"])

MIN_MATCHES = 5


class LeaderboardEntry(BaseModel):
    rank: int
    player_id: str
    username: str
    display_name: str
    rating: float
    matches_played: int


class LeaderboardResponse(BaseModel):
    gender: str
    entries: list[LeaderboardEntry]


@router.get("", response_model=LeaderboardResponse)
async def get_leaderboard(
    session: DbSession,
    _ident: CurrentIdentity,
    gender: Literal["All", "M", "F"] = Query("All"),
    limit: int = Query(100, ge=1, le=500),
) -> LeaderboardResponse:
    """Global leaderboard, sorted by per-player rating.

    Players need >= MIN_MATCHES total matches to appear.
    """
    stmt = (
        select(Player)
        .where(Player.matches_played >= MIN_MATCHES)
        .order_by(Player.rating.desc())
        .limit(limit)
    )
    if gender in ("M", "F"):
        stmt = stmt.where(Player.gender == gender)

    rows = (await session.execute(stmt)).scalars().all()
    entries = [
        LeaderboardEntry(
            rank=i + 1,
            player_id=str(p.id),
            username=p.username,
            display_name=p.display_name,
            rating=p.rating,
            matches_played=p.matches_played,
        )
        for i, p in enumerate(rows)
    ]
    return LeaderboardResponse(gender=gender, entries=entries)
