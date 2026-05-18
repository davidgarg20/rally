from datetime import datetime
from fastapi import APIRouter
from pydantic import BaseModel

from app.deps import CurrentIdentity, DbSession
from app.matches.router import _serialize as _serialize_match
from app.matches.schemas import MatchOut
from app.players import service
from app.players.schemas import PlayerCreate, PlayerOut, PlayerUpdate, RatingOut

router = APIRouter(prefix="/players", tags=["players"])


def _serialize(player, ratings) -> PlayerOut:
    return PlayerOut(
        id=str(player.id),
        phone_e164=player.phone_e164,
        display_name=player.display_name,
        gender=player.gender,
        dob=player.dob,
        home_city=player.home_city,
        ratings=[
            RatingOut(format=r.format, rating=r.rating, rd=r.rd,
                      matches_played=r.matches_played)
            for r in ratings
        ],
    )


@router.post("", response_model=PlayerOut, status_code=201)
async def create(
    body: PlayerCreate, session: DbSession, ident: CurrentIdentity,
) -> PlayerOut:
    p = await service.create_player(session, ident, body)
    ratings = await service.load_ratings(session, p.id)
    return _serialize(p, ratings)


@router.get("/me", response_model=PlayerOut)
async def get_me(session: DbSession, ident: CurrentIdentity) -> PlayerOut:
    p = await service.get_me_or_404(session, ident)
    ratings = await service.load_ratings(session, p.id)
    return _serialize(p, ratings)


@router.patch("/me", response_model=PlayerOut)
async def patch_me(
    body: PlayerUpdate, session: DbSession, ident: CurrentIdentity,
) -> PlayerOut:
    p = await service.get_me_or_404(session, ident)
    p = await service.update_me(session, p, body)
    ratings = await service.load_ratings(session, p.id)
    return _serialize(p, ratings)


class RatingHistoryPoint(BaseModel):
    match_id: str
    format: str
    rating_after: float
    created_at: datetime


@router.get("/me/matches", response_model=list[MatchOut])
async def my_matches(session: DbSession, ident: CurrentIdentity,
                     status: str | None = None) -> list[MatchOut]:
    me = await service.get_me_or_404(session, ident)
    matches = await service.list_my_matches(session, me.id, status)
    return [await _serialize_match(session, m) for m in matches]


@router.get("/me/rating-history", response_model=list[RatingHistoryPoint])
async def my_rating_history(session: DbSession, ident: CurrentIdentity,
                            days: int = 90) -> list[RatingHistoryPoint]:
    me = await service.get_me_or_404(session, ident)
    events = await service.rating_history(session, me.id, days)
    return [RatingHistoryPoint(
        match_id=str(e.match_id),
        format=e.format,
        rating_after=e.rating_after,
        created_at=e.created_at,
    ) for e in events]
