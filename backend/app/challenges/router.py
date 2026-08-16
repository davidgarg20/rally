from __future__ import annotations

import uuid

from fastapi import APIRouter

from app.challenges import service
from app.challenges.schemas import ChallengeCreate, ChallengeOut, ChallengePlayerOut
from app.db.models import Challenge, Player
from app.deps import CurrentIdentity, DbSession

router = APIRouter(prefix="/challenges", tags=["challenges"])


def _serialize(item: tuple[Challenge, Player, Player]) -> ChallengeOut:
    challenge, challenger, challenged = item
    return ChallengeOut(
        id=str(challenge.id),
        status=challenge.status,
        created_at=challenge.created_at,
        responded_at=challenge.responded_at,
        challenger=ChallengePlayerOut(
            id=str(challenger.id),
            username=challenger.username,
            display_name=challenger.display_name,
            rating=challenger.rating,
        ),
        challenged=ChallengePlayerOut(
            id=str(challenged.id),
            username=challenged.username,
            display_name=challenged.display_name,
            rating=challenged.rating,
        ),
    )


@router.get("", response_model=list[ChallengeOut])
async def list_mine(session: DbSession, ident: CurrentIdentity) -> list[ChallengeOut]:
    return [_serialize(item) for item in await service.list_challenges(session, ident)]


@router.post("", response_model=ChallengeOut, status_code=201)
async def create(
    body: ChallengeCreate,
    session: DbSession,
    ident: CurrentIdentity,
) -> ChallengeOut:
    item = await service.create_challenge(session, ident, body.opponent_username)
    return _serialize(item)


async def _update(
    challenge_id: uuid.UUID,
    action: str,
    session: DbSession,
    ident: CurrentIdentity,
) -> ChallengeOut:
    challenge = await service.update_challenge(session, ident, challenge_id, action)
    return _serialize(await service.challenge_with_players(session, challenge))


@router.post("/{challenge_id}/accept", response_model=ChallengeOut)
async def accept(
    challenge_id: uuid.UUID,
    session: DbSession,
    ident: CurrentIdentity,
) -> ChallengeOut:
    return await _update(challenge_id, "accepted", session, ident)


@router.post("/{challenge_id}/decline", response_model=ChallengeOut)
async def decline(
    challenge_id: uuid.UUID,
    session: DbSession,
    ident: CurrentIdentity,
) -> ChallengeOut:
    return await _update(challenge_id, "declined", session, ident)


@router.post("/{challenge_id}/cancel", response_model=ChallengeOut)
async def cancel(
    challenge_id: uuid.UUID,
    session: DbSession,
    ident: CurrentIdentity,
) -> ChallengeOut:
    return await _update(challenge_id, "cancelled", session, ident)
