from __future__ import annotations
import uuid
from sqlalchemy import select
from fastapi import APIRouter

from app.deps import CurrentIdentity, DbSession
from app.db.models import RatingEvent
from app.matches import service
from app.matches.schemas import (
    GameOut, MatchOut, MatchSubmit, ParticipantOut, RatingDeltaOut,
)

router = APIRouter(prefix="/matches", tags=["matches"])


async def _serialize(session, match) -> MatchOut:
    parts = await service.load_participants(session, match.id)
    invites = await service.load_invites(session, match.id)
    games = await service.load_games(session, match.id)
    evt_res = await session.execute(
        select(RatingEvent).where(RatingEvent.match_id == match.id)
    )
    events = list(evt_res.scalars().all())

    participants: list[ParticipantOut] = []
    for mp, p in parts:
        participants.append(ParticipantOut(
            player_id=str(p.id),
            phone_e164=p.phone_e164,
            display_name=p.display_name,
            team=mp.team,
            is_submitter=mp.is_submitter,
            confirmed=mp.confirmed_at is not None,
            disputed=mp.disputed_at is not None,
        ))
    for inv in invites:
        participants.append(ParticipantOut(
            player_id=None,
            phone_e164=inv.phone_e164,
            display_name=None,
            team=inv.team,
            is_submitter=False,
            confirmed=False,
            disputed=False,
        ))

    return MatchOut(
        id=str(match.id),
        format=match.format,
        played_at=match.played_at,
        venue=match.venue,
        status=match.status,
        validation_deadline=match.validation_deadline,
        validated_at=match.validated_at,
        participants=participants,
        games=[GameOut(game_no=g.game_no, team1_points=g.team1_points,
                       team2_points=g.team2_points) for g in games],
        rating_deltas=[RatingDeltaOut(
            player_id=str(e.player_id),
            rating_before=e.rating_before,
            rating_after=e.rating_after,
        ) for e in events],
    )


@router.post("", response_model=MatchOut, status_code=201)
async def submit(body: MatchSubmit, session: DbSession,
                 ident: CurrentIdentity) -> MatchOut:
    m = await service.submit_match(session, ident, body)
    return await _serialize(session, m)


@router.get("/{match_id}", response_model=MatchOut)
async def get(match_id: uuid.UUID, session: DbSession,
              _ident: CurrentIdentity) -> MatchOut:
    m = await service.load_match(session, match_id)
    return await _serialize(session, m)
