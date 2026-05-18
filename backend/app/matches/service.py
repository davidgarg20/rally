from __future__ import annotations
import logging
import uuid
from datetime import UTC, datetime, timedelta
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.firebase import FirebaseIdentity
from app.db.models import (
    Match, MatchGame, MatchInvite, MatchParticipant, Player,
)
from app.errors import BadRequest, Conflict, Forbidden, NotFound
from app.matches.dedup import find_duplicate
from app.matches.schemas import MatchSubmit
from app.matches.validators import match_winner
from app.players.service import get_by_firebase_uid
from app.push import fcm

log = logging.getLogger(__name__)

VALIDATION_WINDOW = timedelta(hours=72)


def _check_team_shape(fmt: str, t1: list[str], t2: list[str]) -> None:
    required = 1 if fmt == "S" else 2
    if len(t1) != required or len(t2) != required:
        raise BadRequest(
            f"{fmt} requires {required} player(s) per team",
            code="invalid_team_size",
        )
    overlap = set(t1) & set(t2)
    if overlap:
        raise BadRequest(
            f"player(s) on both teams: {sorted(overlap)}",
            code="player_on_both_teams",
        )


async def submit_match(
    session: AsyncSession, ident: FirebaseIdentity, body: MatchSubmit
) -> Match:
    submitter = await get_by_firebase_uid(session, ident.uid)
    if not submitter:
        raise NotFound("submitter player not found", code="player_not_found")

    _check_team_shape(body.format, body.team1_phones, body.team2_phones)

    if submitter.phone_e164 not in body.team1_phones + body.team2_phones:
        raise Forbidden(
            "submitter must be a participant",
            code="submitter_not_participant",
        )

    games = [(g.team1_points, g.team2_points) for g in
             sorted(body.games, key=lambda g: g.game_no)]
    try:
        _winner = match_winner(games)
    except ValueError as e:
        raise BadRequest(str(e), code="invalid_score") from e

    all_phones = body.team1_phones + body.team2_phones
    dup = await find_duplicate(session, submitter.id, body.played_at, all_phones)
    if dup:
        raise Conflict("duplicate match", code="duplicate_match")

    res = await session.execute(
        select(Player).where(Player.phone_e164.in_(all_phones))
    )
    registered = {p.phone_e164: p for p in res.scalars().all()}

    now = datetime.now(UTC)
    match = Match(
        format=body.format,
        played_at=body.played_at,
        venue=body.venue,
        submitted_by=submitter.id,
        status="pending",
        validation_deadline=now + VALIDATION_WINDOW,
    )
    session.add(match)
    await session.flush()

    for team, phones in [(1, body.team1_phones), (2, body.team2_phones)]:
        for phone in phones:
            if phone in registered:
                player = registered[phone]
                is_sub = (player.id == submitter.id)
                session.add(MatchParticipant(
                    match_id=match.id,
                    player_id=player.id,
                    team=team,
                    is_submitter=is_sub,
                    confirmed_at=(now if is_sub else None),
                ))
            else:
                session.add(MatchInvite(
                    match_id=match.id, phone_e164=phone, team=team,
                ))
                log.info("SMS invite to %s for match %s", phone, match.id)

    for g in body.games:
        session.add(MatchGame(
            match_id=match.id, game_no=g.game_no,
            team1_points=g.team1_points, team2_points=g.team2_points,
        ))

    await session.commit()
    await session.refresh(match)

    submitter_team = 1 if submitter.phone_e164 in body.team1_phones else 2
    opposing_team = 2 if submitter_team == 1 else 1
    opp_phones = body.team1_phones if opposing_team == 1 else body.team2_phones
    for phone in opp_phones:
        if phone in registered:
            await fcm.send_to_uid(
                registered[phone].firebase_uid,
                title="New match to confirm",
                body=f"{submitter.display_name} logged a match against you. Tap to confirm.",
                data={"match_id": str(match.id), "kind": "match_submitted"},
            )

    return match


async def load_match(session: AsyncSession, match_id: uuid.UUID) -> Match:
    res = await session.execute(select(Match).where(Match.id == match_id))
    m = res.scalar_one_or_none()
    if not m:
        raise NotFound("match not found", code="match_not_found")
    return m


async def load_participants(
    session: AsyncSession, match_id: uuid.UUID
) -> list[tuple[MatchParticipant, Player]]:
    res = await session.execute(
        select(MatchParticipant, Player)
        .join(Player, MatchParticipant.player_id == Player.id)
        .where(MatchParticipant.match_id == match_id)
    )
    return [(mp, p) for mp, p in res.all()]


async def load_invites(
    session: AsyncSession, match_id: uuid.UUID
) -> list[MatchInvite]:
    res = await session.execute(
        select(MatchInvite).where(MatchInvite.match_id == match_id)
    )
    return list(res.scalars().all())


async def load_games(
    session: AsyncSession, match_id: uuid.UUID
) -> list[MatchGame]:
    res = await session.execute(
        select(MatchGame).where(MatchGame.match_id == match_id)
        .order_by(MatchGame.game_no)
    )
    return list(res.scalars().all())
