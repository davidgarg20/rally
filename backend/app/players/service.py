from __future__ import annotations
import uuid
from datetime import datetime, timedelta, UTC
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.firebase import FirebaseIdentity
from app.db.models import Match, MatchParticipant, Player, PlayerRating, RatingEvent
from app.errors import Conflict, NotFound
from app.players.schemas import PlayerCreate, PlayerUpdate


async def get_by_firebase_uid(
    session: AsyncSession, firebase_uid: str
) -> Player | None:
    res = await session.execute(
        select(Player).where(Player.firebase_uid == firebase_uid)
    )
    return res.scalar_one_or_none()


async def get_by_username(
    session: AsyncSession, username: str
) -> Player | None:
    res = await session.execute(
        select(Player).where(Player.username == username.lower())
    )
    return res.scalar_one_or_none()


async def create_player(
    session: AsyncSession, ident: FirebaseIdentity, data: PlayerCreate
) -> Player:
    existing = await get_by_firebase_uid(session, ident.uid)
    if existing:
        raise Conflict("player already exists", code="player_exists")

    username = data.username.lower()
    if await get_by_username(session, username):
        raise Conflict("username taken", code="username_taken")

    p = Player(
        phone_e164=ident.phone_e164,
        username=username,
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


async def list_my_matches(
    session: AsyncSession, player_id: uuid.UUID, status: str | None = None
) -> list[Match]:
    stmt = (
        select(Match)
        .join(MatchParticipant, MatchParticipant.match_id == Match.id)
        .where(MatchParticipant.player_id == player_id)
        .order_by(Match.played_at.desc())
    )
    if status:
        stmt = stmt.where(Match.status == status)
    res = await session.execute(stmt)
    return list(res.scalars().all())


async def rating_history(
    session: AsyncSession, player_id: uuid.UUID, days: int = 90
) -> list[RatingEvent]:
    since = datetime.now(UTC) - timedelta(days=days)
    res = await session.execute(
        select(RatingEvent)
        .where(
            (RatingEvent.player_id == player_id)
            & (RatingEvent.created_at >= since)
        )
        .order_by(RatingEvent.created_at.asc())
    )
    return list(res.scalars().all())
