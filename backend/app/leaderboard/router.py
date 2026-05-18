from __future__ import annotations
from typing import Literal
from fastapi import APIRouter, Query
from pydantic import BaseModel
from sqlalchemy import select

from app.db.models import Player, PlayerRating
from app.deps import CurrentIdentity, DbSession

router = APIRouter(prefix="/leaderboard", tags=["leaderboard"])

MIN_MATCHES = 5


class LeaderboardEntry(BaseModel):
    rank: int
    player_id: str
    display_name: str
    rating: float
    matches_played: int


class LeaderboardResponse(BaseModel):
    format: str
    city: str
    gender: str
    entries: list[LeaderboardEntry]


@router.get("", response_model=LeaderboardResponse)
async def get_leaderboard(
    session: DbSession,
    _ident: CurrentIdentity,
    format: Literal["S", "D"] = Query("S"),
    gender: Literal["All", "M", "F"] = Query("All"),
    limit: int = Query(100, ge=1, le=500),
    city: str = Query("BLR"),
) -> LeaderboardResponse:
    stmt = (
        select(Player.id, Player.display_name, PlayerRating.rating,
               PlayerRating.matches_played)
        .join(PlayerRating, PlayerRating.player_id == Player.id)
        .where(
            (PlayerRating.format == format)
            & (Player.home_city == city)
            & (PlayerRating.matches_played >= MIN_MATCHES)
        )
        .order_by(PlayerRating.rating.desc())
        .limit(limit)
    )
    if gender in ("M", "F"):
        stmt = stmt.where(Player.gender == gender)

    rows = (await session.execute(stmt)).all()
    entries = [
        LeaderboardEntry(
            rank=i + 1,
            player_id=str(pid),
            display_name=name,
            rating=rating,
            matches_played=mp,
        )
        for i, (pid, name, rating, mp) in enumerate(rows)
    ]
    return LeaderboardResponse(format=format, city=city, gender=gender, entries=entries)
