from datetime import datetime
from fastapi import APIRouter
from pydantic import BaseModel

from app.deps import CurrentIdentity, DbSession
from app.matches.router import _serialize as _serialize_match
from app.matches.schemas import MatchOut
from app.players import service
from app.players.schemas import (
    HeadToHeadOut, OverallOut, PlayerCreate, PlayerOut, PlayerUpdate,
    PublicPlayerOut, RatingOut,
)

def _compute_overall(ratings) -> OverallOut:
    """Match-count weighted average of singles + doubles ratings.

    Before any matches are played, total_matches is 0 and we just average
    the cold-start ratings (which are equal, so the answer is 1500).
    Once matches start landing, weights kick in.
    """
    total_matches = sum(r.matches_played for r in ratings)
    if total_matches == 0:
        # No matches yet; everyone's at 1500.
        return OverallOut(
            rating=sum(r.rating for r in ratings) / len(ratings),
            matches_played=0,
        )
    weighted = sum(r.rating * r.matches_played for r in ratings)
    return OverallOut(
        rating=weighted / total_matches,
        matches_played=total_matches,
    )

router = APIRouter(prefix="/players", tags=["players"])


def _serialize(player, ratings) -> PlayerOut:
    return PlayerOut(
        id=str(player.id),
        phone_e164=player.phone_e164,
        username=player.username,
        display_name=player.display_name,
        gender=player.gender,
        dob=player.dob,
        home_city=player.home_city,
        ratings=[
            RatingOut(format=r.format, rating=r.rating, rd=r.rd,
                      matches_played=r.matches_played)
            for r in ratings
        ],
        overall=_compute_overall(ratings),
    )


@router.post("", response_model=PlayerOut, status_code=201)
async def create(
    body: PlayerCreate, session: DbSession, ident: CurrentIdentity,
) -> PlayerOut:
    p = await service.create_player(session, ident, body)
    ratings = await service.load_ratings(session, p.id)
    return _serialize(p, ratings)


class PlayerSearchEntry(BaseModel):
    id: str
    username: str
    display_name: str


@router.get("/search", response_model=list[PlayerSearchEntry])
async def search_players(
    q: str, session: DbSession, ident: CurrentIdentity,
    limit: int = 10,
) -> list[PlayerSearchEntry]:
    """Find players by partial username or display_name match.

    Excludes the requester. Returns up to ``limit`` matches.
    """
    from sqlalchemy import or_, select
    from app.db.models import Player

    q_clean = q.strip().lstrip("@").lower()
    if len(q_clean) < 1:
        return []

    me = await service.get_by_firebase_uid(session, ident.uid)
    me_id = me.id if me else None

    stmt = (
        select(Player)
        .where(
            or_(
                Player.username.ilike(f"%{q_clean}%"),
                Player.display_name.ilike(f"%{q_clean}%"),
            )
        )
        .limit(limit)
    )
    if me_id is not None:
        stmt = stmt.where(Player.id != me_id)

    rows = (await session.execute(stmt)).scalars().all()
    return [
        PlayerSearchEntry(
            id=str(p.id), username=p.username, display_name=p.display_name,
        )
        for p in rows
    ]


@router.get("/check-username")
async def check_username(
    u: str, session: DbSession, _ident: CurrentIdentity,
) -> dict[str, bool | str]:
    """Returns {'available': true/false, 'reason'?: '...'}.

    Reasons: 'taken', 'invalid_format'.
    """
    import re
    if not re.match(r"^[a-z][a-z0-9_]{2,19}$", u.lower()):
        return {"available": False, "reason": "invalid_format"}
    existing = await service.get_by_username(session, u)
    if existing:
        return {"available": False, "reason": "taken"}
    return {"available": True}


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


@router.get("/by-username/{username}", response_model=PublicPlayerOut)
async def public_profile(
    username: str, session: DbSession, _ident: CurrentIdentity,
) -> PublicPlayerOut:
    """Public profile for any player. No phone or DOB included."""
    from app.errors import NotFound
    from sqlalchemy import text

    target = await service.get_by_username(session, username)
    if not target:
        raise NotFound("player not found", code="player_not_found")

    ratings = await service.load_ratings(session, target.id)
    target_overall = _compute_overall(ratings).rating
    rank: int | None = None

    if target_overall is not None:
        # Rank in city = (# players with strictly higher overall) + 1.
        # Computed via raw SQL — clearest path for the weighted-average ranking.
        row = (await session.execute(
            text(
                """
                with overall_per_player as (
                    select p.id,
                           sum(pr.rating * pr.matches_played)
                             / nullif(sum(pr.matches_played), 0) as ov
                    from players p
                    join player_ratings pr on pr.player_id = p.id
                    where p.home_city = :city
                    group by p.id
                    having sum(pr.matches_played) > 0
                )
                select count(*) + 1
                from overall_per_player
                where ov > :target_ov
                """
            ),
            {"city": target.home_city, "target_ov": target_overall},
        )).scalar_one()
        rank = int(row)

    return PublicPlayerOut(
        id=str(target.id),
        username=target.username,
        display_name=target.display_name,
        gender=target.gender,
        home_city=target.home_city,
        ratings=[
            RatingOut(format=r.format, rating=r.rating, rd=r.rd,
                      matches_played=r.matches_played)
            for r in ratings
        ],
        overall=_compute_overall(ratings),
        rank=rank,
    )


@router.get("/by-username/{username}/head-to-head", response_model=HeadToHeadOut)
async def head_to_head(
    username: str, session: DbSession, ident: CurrentIdentity,
) -> HeadToHeadOut:
    """Wins/losses + last 5 matches between current user and target player."""
    from app.db.models import MatchGame, MatchParticipant
    from app.errors import NotFound
    from sqlalchemy import select, text

    me = await service.get_me_or_404(session, ident)
    target = await service.get_by_username(session, username)
    if not target:
        raise NotFound("player not found", code="player_not_found")

    # Find all validated matches where both players participated.
    rows = (await session.execute(
        text(
            """
            select m.id
            from matches m
            where m.status = 'validated'
              and exists (select 1 from match_participants where match_id = m.id and player_id = :me)
              and exists (select 1 from match_participants where match_id = m.id and player_id = :them)
            order by m.played_at desc
            """
        ),
        {"me": me.id, "them": target.id},
    )).all()
    match_ids = [r[0] for r in rows]

    me_wins = 0
    opp_wins = 0
    last_matches = []

    from app.matches.router import _serialize as _serialize_match_inline
    from app.matches.service import load_match

    for mid in match_ids:
        match = await load_match(session, mid)
        # Determine winner by scanning the single game (single-set engine).
        games_res = await session.execute(
            select(MatchGame).where(MatchGame.match_id == mid)
        )
        games = list(games_res.scalars().all())
        if not games:
            continue
        g = games[0]
        winning_team = 1 if g.team1_points > g.team2_points else 2
        # Which team was I on?
        parts_res = await session.execute(
            select(MatchParticipant).where(MatchParticipant.match_id == mid)
        )
        parts = list(parts_res.scalars().all())
        my_team = next((p.team for p in parts if p.player_id == me.id), None)
        if my_team == winning_team:
            me_wins += 1
        else:
            opp_wins += 1
        if len(last_matches) < 5:
            last_matches.append(await _serialize_match_inline(session, match))

    return HeadToHeadOut(
        me_wins=me_wins,
        opponent_wins=opp_wins,
        last_matches=last_matches,
    )


@router.get("/by-username/{username}/rating-history",
            response_model=list[RatingHistoryPoint])
async def public_rating_history(
    username: str, session: DbSession, _ident: CurrentIdentity,
    days: int = 90,
) -> list[RatingHistoryPoint]:
    """Rating events for any player. Public-readable like profile."""
    from app.errors import NotFound
    target = await service.get_by_username(session, username)
    if not target:
        raise NotFound("player not found", code="player_not_found")
    events = await service.rating_history(session, target.id, days)
    return [RatingHistoryPoint(
        match_id=str(e.match_id),
        format=e.format,
        rating_after=e.rating_after,
        created_at=e.created_at,
    ) for e in events]
