from __future__ import annotations
import re
from datetime import datetime

from fastapi import APIRouter
from pydantic import BaseModel
from sqlalchemy import or_, select, text

from app.db.models import Player
from app.deps import CurrentIdentity, DbSession
from app.errors import NotFound
from app.matches.router import _serialize as _serialize_match
from app.matches.schemas import MatchOut
from app.players import service
from app.players.schemas import (
    HeadToHeadOut, PlayerCreate, PlayerOut, PlayerUpdate, PublicPlayerOut,
)


router = APIRouter(prefix="/players", tags=["players"])


def _serialize(player: Player) -> PlayerOut:
    return PlayerOut(
        id=str(player.id),
        phone_e164=player.phone_e164,
        username=player.username,
        display_name=player.display_name,
        gender=player.gender,
        dob=player.dob,
        home_city=player.home_city,
        rating=player.rating,
        rd=player.rd,
        matches_played=player.matches_played,
    )


# ─── Auth-required endpoints ──────────────────────────────────────────────

@router.post("", response_model=PlayerOut, status_code=201)
async def create(
    body: PlayerCreate, session: DbSession, ident: CurrentIdentity,
) -> PlayerOut:
    p = await service.create_player(session, ident, body)
    return _serialize(p)


class PlayerSearchEntry(BaseModel):
    id: str
    username: str
    display_name: str


@router.get("/search", response_model=list[PlayerSearchEntry])
async def search_players(
    q: str, session: DbSession, ident: CurrentIdentity,
    limit: int = 10,
) -> list[PlayerSearchEntry]:
    """Partial username or display_name match. Excludes the requester."""
    q_clean = q.strip().lstrip("@").lower()
    if not q_clean:
        return []

    me = await service.get_by_firebase_uid(session, ident.uid)
    me_id = me.id if me else None

    stmt = (
        select(Player)
        .where(or_(
            Player.username.ilike(f"%{q_clean}%"),
            Player.display_name.ilike(f"%{q_clean}%"),
        ))
        .limit(limit)
    )
    if me_id is not None:
        stmt = stmt.where(Player.id != me_id)
    rows = (await session.execute(stmt)).scalars().all()
    return [
        PlayerSearchEntry(id=str(p.id), username=p.username, display_name=p.display_name)
        for p in rows
    ]


@router.get("/check-username")
async def check_username(
    u: str, session: DbSession, _ident: CurrentIdentity,
) -> dict[str, bool | str]:
    """Returns {available: bool, reason?: 'taken' | 'invalid_format'}."""
    if not re.match(r"^[a-z][a-z0-9_]{2,19}$", u.lower()):
        return {"available": False, "reason": "invalid_format"}
    if await service.get_by_username(session, u):
        return {"available": False, "reason": "taken"}
    return {"available": True}


@router.get("/me", response_model=PlayerOut)
async def get_me(session: DbSession, ident: CurrentIdentity) -> PlayerOut:
    p = await service.get_me_or_404(session, ident)
    return _serialize(p)


@router.patch("/me", response_model=PlayerOut)
async def patch_me(
    body: PlayerUpdate, session: DbSession, ident: CurrentIdentity,
) -> PlayerOut:
    p = await service.get_me_or_404(session, ident)
    p = await service.update_me(session, p, body)
    return _serialize(p)


class RatingHistoryPoint(BaseModel):
    match_id: str
    rating_after: float
    created_at: datetime


@router.get("/me/matches", response_model=list[MatchOut])
async def my_matches(
    session: DbSession, ident: CurrentIdentity, status: str | None = None,
) -> list[MatchOut]:
    me = await service.get_me_or_404(session, ident)
    matches = await service.list_my_matches(session, me.id, status)
    return [await _serialize_match(session, m) for m in matches]


@router.get("/me/rating-history", response_model=list[RatingHistoryPoint])
async def my_rating_history(
    session: DbSession, ident: CurrentIdentity, days: int = 90,
) -> list[RatingHistoryPoint]:
    me = await service.get_me_or_404(session, ident)
    events = await service.rating_history(session, me.id, days)
    return [RatingHistoryPoint(
        match_id=str(e.match_id),
        rating_after=e.rating_after,
        created_at=e.created_at,
    ) for e in events]


# ─── Public-ish (auth-gated read-any) ─────────────────────────────────────

@router.get("/by-username/{username}", response_model=PublicPlayerOut)
async def public_profile(
    username: str, session: DbSession, _ident: CurrentIdentity,
) -> PublicPlayerOut:
    target = await service.get_by_username(session, username)
    if not target:
        raise NotFound("player not found", code="player_not_found")

    # Rank in city: count of players with strictly higher rating.
    rank_row = (await session.execute(
        text(
            """
            select count(*) + 1
            from players
            where home_city = :city
              and matches_played > 0
              and rating > :target_rating
            """
        ),
        {"city": target.home_city, "target_rating": target.rating},
    )).scalar_one()
    rank = int(rank_row) if target.matches_played > 0 else None

    return PublicPlayerOut(
        id=str(target.id),
        username=target.username,
        display_name=target.display_name,
        gender=target.gender,
        home_city=target.home_city,
        rating=target.rating,
        rd=target.rd,
        matches_played=target.matches_played,
        rank=rank,
    )


@router.get("/by-username/{username}/head-to-head", response_model=HeadToHeadOut)
async def head_to_head(
    username: str, session: DbSession, ident: CurrentIdentity,
) -> HeadToHeadOut:
    """W-L + last 5 matches between current user and target player."""
    from app.db.models import MatchGame, MatchParticipant
    from app.matches.service import load_match

    me = await service.get_me_or_404(session, ident)
    target = await service.get_by_username(session, username)
    if not target:
        raise NotFound("player not found", code="player_not_found")

    rows = (await session.execute(
        text(
            """
            select m.id
            from matches m
            where m.status = 'validated'
              and exists (select 1 from match_participants
                          where match_id = m.id and player_id = :me)
              and exists (select 1 from match_participants
                          where match_id = m.id and player_id = :them)
            order by m.played_at desc
            """
        ),
        {"me": me.id, "them": target.id},
    )).all()
    match_ids = [r[0] for r in rows]

    me_wins = 0
    opp_wins = 0
    last_matches = []

    for mid in match_ids:
        match = await load_match(session, mid)
        games = (await session.execute(
            select(MatchGame).where(MatchGame.match_id == mid)
        )).scalars().all()
        if not games:
            continue
        g = games[0]
        winning_team = 1 if g.team1_points > g.team2_points else 2
        parts = (await session.execute(
            select(MatchParticipant).where(MatchParticipant.match_id == mid)
        )).scalars().all()
        my_team = next((p.team for p in parts if p.player_id == me.id), None)
        if my_team == winning_team:
            me_wins += 1
        else:
            opp_wins += 1
        if len(last_matches) < 5:
            last_matches.append(await _serialize_match(session, match))

    return HeadToHeadOut(
        me_wins=me_wins, opponent_wins=opp_wins, last_matches=last_matches,
    )


@router.get("/by-username/{username}/rating-history",
            response_model=list[RatingHistoryPoint])
async def public_rating_history(
    username: str, session: DbSession, _ident: CurrentIdentity,
    days: int = 90,
) -> list[RatingHistoryPoint]:
    target = await service.get_by_username(session, username)
    if not target:
        raise NotFound("player not found", code="player_not_found")
    events = await service.rating_history(session, target.id, days)
    return [RatingHistoryPoint(
        match_id=str(e.match_id),
        rating_after=e.rating_after,
        created_at=e.created_at,
    ) for e in events]
