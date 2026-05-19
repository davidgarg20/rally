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
from app.rating.service import apply_match_rating
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


async def _resolve_identifiers(
    session: AsyncSession, identifiers: list[str]
) -> list[str]:
    """Normalize a list of phone-or-username strings into phones.

    - If an entry starts with '+', it's a phone — passed through.
    - Otherwise it's a username — looked up in the DB. If found, replaced
      with the player's phone. If not found, BadRequest.
    """
    resolved: list[str] = []
    for ident in identifiers:
        stripped = ident.strip().lstrip("@")
        if stripped.startswith("+") or stripped.replace(" ", "").isdigit():
            # phone (E.164 or raw digits)
            resolved.append(ident.strip())
            continue
        # username path
        from app.players.service import get_by_username
        player = await get_by_username(session, stripped)
        if not player:
            raise BadRequest(
                f"unknown player: @{stripped}", code="unknown_username",
            )
        resolved.append(player.phone_e164)
    return resolved


async def submit_match(
    session: AsyncSession, ident: FirebaseIdentity, body: MatchSubmit
) -> Match:
    submitter = await get_by_firebase_uid(session, ident.uid)
    if not submitter:
        raise NotFound("submitter player not found", code="player_not_found")

    # Allow opponents specified as @username or +91phone.
    body = body.model_copy(update={
        "team1_phones": await _resolve_identifiers(session, body.team1_phones),
        "team2_phones": await _resolve_identifiers(session, body.team2_phones),
    })

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


async def preview_rating_deltas(
    session: AsyncSession, match_id: uuid.UUID,
) -> list[dict]:
    """Predict per-player rating deltas if this pending match is confirmed.

    Doesn't mutate any persisted state. Returns a list of
    {player_id, rating_before, rating_after} dicts.
    """
    from app.db.models import PlayerRating
    from app.rating import engine
    from app.rating.glicko2 import Player as RatingPlayer

    match = await load_match(session, match_id)
    parts = await load_participants(session, match_id)
    games_rows = await load_games(session, match_id)
    if not games_rows:
        return []
    g = games_rows[0]
    winner_team = 1 if g.team1_points > g.team2_points else 2
    w_score = max(g.team1_points, g.team2_points)
    l_score = min(g.team1_points, g.team2_points)

    fmt = match.format
    # Load current ratings.
    rating_for: dict = {}
    for mp, _p in parts:
        res = await session.execute(
            select(PlayerRating).where(
                (PlayerRating.player_id == mp.player_id)
                & (PlayerRating.format == fmt)
            )
        )
        pr = res.scalar_one()
        rating_for[mp.player_id] = pr

    # Build engine Player instances (deep-copy state — engine mutates).
    eng_players = {
        pid: RatingPlayer(rating=pr.rating, rd=pr.rd, vol=pr.volatility)
        for pid, pr in rating_for.items()
    }
    befores = {pid: pl.rating for pid, pl in eng_players.items()}

    if fmt == "S":
        winner = next(mp for mp, _p in parts if mp.team == winner_team)
        loser = next(mp for mp, _p in parts if mp.team != winner_team)
        engine.update_singles(
            eng_players[winner.player_id],
            eng_players[loser.player_id],
            w_score, l_score,
        )
    else:
        winners = [mp for mp, _p in parts if mp.team == winner_team]
        losers = [mp for mp, _p in parts if mp.team != winner_team]
        engine.update_doubles(
            (eng_players[winners[0].player_id], eng_players[winners[1].player_id]),
            (eng_players[losers[0].player_id], eng_players[losers[1].player_id]),
            w_score, l_score,
        )

    return [
        {
            "player_id": str(pid),
            "rating_before": befores[pid],
            "rating_after": pl.rating,
        }
        for pid, pl in eng_players.items()
    ]


async def confirm_match(
    session: AsyncSession, ident: FirebaseIdentity, match_id: uuid.UUID
) -> Match:
    me = await get_by_firebase_uid(session, ident.uid)
    if not me:
        raise NotFound("player not found", code="player_not_found")

    match = await load_match(session, match_id)
    if match.status not in ("pending",):
        raise Conflict(f"match is {match.status}", code="not_pending")

    parts = await load_participants(session, match.id)
    my_row = next((mp for mp, p in parts if p.id == me.id), None)
    if my_row is None:
        raise Forbidden("not a participant", code="not_a_participant")

    submitter_team = next(mp.team for mp, p in parts if mp.is_submitter)
    if my_row.team == submitter_team:
        my_row.confirmed_at = my_row.confirmed_at or datetime.now(UTC)
        await session.commit()
        return match

    my_row.confirmed_at = my_row.confirmed_at or datetime.now(UTC)

    games_rows = await load_games(session, match.id)
    games = [(g.team1_points, g.team2_points) for g in games_rows]
    winning_team = match_winner(games)

    match.status = "validated"
    match.validated_at = datetime.now(UTC)
    await apply_match_rating(session, match, winning_team)
    await session.commit()

    for mp, p in parts:
        await fcm.send_to_uid(
            p.firebase_uid,
            title="Match validated",
            body="Your rating has been updated.",
            data={"match_id": str(match.id), "kind": "match_validated"},
        )

    return match


async def dispute_match(
    session: AsyncSession, ident: FirebaseIdentity, match_id: uuid.UUID
) -> Match:
    from app.db.models import RatingEvent, PlayerRating
    from sqlalchemy import delete

    me = await get_by_firebase_uid(session, ident.uid)
    if not me:
        raise NotFound("player not found", code="player_not_found")

    match = await load_match(session, match_id)
    if match.status == "disputed":
        return match
    if match.status not in ("pending", "validated"):
        raise Conflict(f"cannot dispute {match.status} match", code="cannot_dispute")

    parts = await load_participants(session, match.id)
    my_row = next((mp for mp, p in parts if p.id == me.id), None)
    if my_row is None:
        raise Forbidden("not a participant", code="not_a_participant")

    if match.status == "validated":
        events_res = await session.execute(
            select(RatingEvent).where(RatingEvent.match_id == match.id)
        )
        events = list(events_res.scalars().all())
        for ev in events:
            res = await session.execute(
                select(PlayerRating).where(
                    (PlayerRating.player_id == ev.player_id)
                    & (PlayerRating.format == ev.format)
                )
            )
            pr = res.scalar_one()
            delta = ev.rating_after - ev.rating_before
            rd_delta = ev.rd_after - ev.rd_before
            pr.rating = pr.rating - delta
            pr.rd = pr.rd - rd_delta
            pr.matches_played = max(0, pr.matches_played - 1)
        await session.execute(
            delete(RatingEvent).where(RatingEvent.match_id == match.id)
        )

    my_row.disputed_at = datetime.now(UTC)
    match.status = "disputed"
    await session.commit()
    return match
