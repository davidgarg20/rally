from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import aliased

from app.auth.firebase import FirebaseIdentity
from app.db.models import Challenge, Player
from app.errors import Conflict, Forbidden, NotFound
from app.players.service import get_by_firebase_uid, get_by_username
from app.push import fcm


async def create_challenge(
    session: AsyncSession,
    ident: FirebaseIdentity,
    opponent_username: str,
) -> tuple[Challenge, Player, Player]:
    me = await get_by_firebase_uid(session, ident.uid)
    if not me:
        raise NotFound("player not found", code="player_not_found")

    opponent = await get_by_username(session, opponent_username.strip().lstrip("@"))
    if not opponent:
        raise NotFound("opponent not found", code="player_not_found")
    if opponent.id == me.id:
        raise Conflict("you cannot challenge yourself", code="self_challenge")

    existing = (
        await session.execute(
            select(Challenge).where(
                Challenge.status == "pending",
                or_(
                    and_(
                        Challenge.challenger_id == me.id,
                        Challenge.challenged_id == opponent.id,
                    ),
                    and_(
                        Challenge.challenger_id == opponent.id,
                        Challenge.challenged_id == me.id,
                    ),
                ),
            )
        )
    ).scalar_one_or_none()
    if existing:
        raise Conflict(
            "a challenge between these players is already pending",
            code="challenge_pending",
        )

    challenge = Challenge(
        challenger_id=me.id,
        challenged_id=opponent.id,
        status="pending",
    )
    session.add(challenge)
    await session.commit()
    await session.refresh(challenge)

    await fcm.send_to_uid(
        opponent.firebase_uid,
        title="New Rally challenge",
        body=f"{me.display_name} challenged you to a game.",
        data={"challenge_id": str(challenge.id), "kind": "challenge_created"},
    )
    return challenge, me, opponent


async def list_challenges(
    session: AsyncSession,
    ident: FirebaseIdentity,
) -> list[tuple[Challenge, Player, Player]]:
    me = await get_by_firebase_uid(session, ident.uid)
    if not me:
        raise NotFound("player not found", code="player_not_found")

    challenger = aliased(Player)
    challenged = aliased(Player)
    result = await session.execute(
        select(Challenge, challenger, challenged)
        .join(challenger, challenger.id == Challenge.challenger_id)
        .join(challenged, challenged.id == Challenge.challenged_id)
        .where(or_(Challenge.challenger_id == me.id, Challenge.challenged_id == me.id))
        .order_by(Challenge.created_at.desc())
        .limit(50)
    )
    return list(result.all())


async def load_challenge(session: AsyncSession, challenge_id: uuid.UUID) -> Challenge:
    challenge = (
        await session.execute(select(Challenge).where(Challenge.id == challenge_id))
    ).scalar_one_or_none()
    if not challenge:
        raise NotFound("challenge not found", code="challenge_not_found")
    return challenge


async def update_challenge(
    session: AsyncSession,
    ident: FirebaseIdentity,
    challenge_id: uuid.UUID,
    action: str,
) -> Challenge:
    me = await get_by_firebase_uid(session, ident.uid)
    if not me:
        raise NotFound("player not found", code="player_not_found")

    challenge = await load_challenge(session, challenge_id)
    if challenge.status != "pending":
        raise Conflict(f"challenge is {challenge.status}", code="challenge_not_pending")

    if action in ("accepted", "declined"):
        if challenge.challenged_id != me.id:
            raise Forbidden("only the challenged player can respond", code="not_challenged_player")
    elif action == "cancelled":
        if challenge.challenger_id != me.id:
            raise Forbidden("only the challenger can cancel", code="not_challenger")
    else:
        raise Conflict("unsupported challenge action", code="invalid_challenge_action")

    challenge.status = action
    challenge.responded_at = datetime.now(UTC)
    await session.commit()
    return challenge


async def challenge_with_players(
    session: AsyncSession,
    challenge: Challenge,
) -> tuple[Challenge, Player, Player]:
    players = (
        await session.execute(
            select(Player).where(Player.id.in_([challenge.challenger_id, challenge.challenged_id]))
        )
    ).scalars().all()
    by_id = {player.id: player for player in players}
    return challenge, by_id[challenge.challenger_id], by_id[challenge.challenged_id]
