from __future__ import annotations
from typing import Literal
from fastapi import APIRouter, Query
from pydantic import BaseModel
from sqlalchemy import func, select

from app.db.models import Player, PlayerRating
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
    """Global leaderboard. Rating is match-count-weighted average of S + D.

    Players need >= MIN_MATCHES total matches (S + D combined) to appear.
    """
    weighted = func.sum(PlayerRating.rating * PlayerRating.matches_played)
    total_matches = func.sum(PlayerRating.matches_played)
    overall = (weighted / func.nullif(total_matches, 0)).label("overall")

    stmt = (
        select(
            Player.id.label("player_id"),
            Player.username,
            Player.display_name,
            overall,
            total_matches.label("total_matches"),
        )
        .join(PlayerRating, PlayerRating.player_id == Player.id)
        .group_by(Player.id, Player.username, Player.display_name)
        .having(total_matches >= MIN_MATCHES)
        .order_by(overall.desc())
        .limit(limit)
    )
    if gender in ("M", "F"):
        stmt = stmt.where(Player.gender == gender)

    rows = (await session.execute(stmt)).all()
    entries = [
        LeaderboardEntry(
            rank=i + 1,
            player_id=str(pid),
            username=uname,
            display_name=name,
            rating=float(rating),
            matches_played=int(matches),
        )
        for i, (pid, uname, name, rating, matches) in enumerate(rows)
    ]
    return LeaderboardResponse(gender=gender, entries=entries)
