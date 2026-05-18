from __future__ import annotations
import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.firebase import FirebaseIdentity
from app.db.models import Player, PlayerRating
from app.errors import Conflict, NotFound
from app.players.schemas import PlayerCreate, PlayerUpdate


async def get_by_firebase_uid(
    session: AsyncSession, firebase_uid: str
) -> Player | None:
    res = await session.execute(
        select(Player).where(Player.firebase_uid == firebase_uid)
    )
    return res.scalar_one_or_none()


async def create_player(
    session: AsyncSession, ident: FirebaseIdentity, data: PlayerCreate
) -> Player:
    existing = await get_by_firebase_uid(session, ident.uid)
    if existing:
        raise Conflict("player already exists", code="player_exists")

    p = Player(
        phone_e164=ident.phone_e164,
        display_name=data.display_name,
        gender=data.gender,
        dob=data.dob,
        home_city=data.home_city,
        firebase_uid=ident.uid,
    )
    session.add(p)
    await session.flush()
    session.add_all([
        PlayerRating(player_id=p.id, format="S"),
        PlayerRating(player_id=p.id, format="D"),
    ])
    await session.commit()
    await session.refresh(p)
    return p


async def update_me(
    session: AsyncSession, player: Player, data: PlayerUpdate
) -> Player:
    if data.display_name is not None:
        player.display_name = data.display_name
    if data.gender is not None:
        player.gender = data.gender
    if data.dob is not None:
        player.dob = data.dob
    if data.home_city is not None:
        player.home_city = data.home_city
    await session.commit()
    return player


async def get_me_or_404(
    session: AsyncSession, ident: FirebaseIdentity
) -> Player:
    p = await get_by_firebase_uid(session, ident.uid)
    if not p:
        raise NotFound("player not found", code="player_not_found")
    return p


async def load_ratings(
    session: AsyncSession, player_id: uuid.UUID
) -> list[PlayerRating]:
    res = await session.execute(
        select(PlayerRating).where(PlayerRating.player_id == player_id)
    )
    return list(res.scalars().all())
