from fastapi import APIRouter

from app.deps import CurrentIdentity, DbSession
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
