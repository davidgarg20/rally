import uuid
from datetime import UTC, datetime, timedelta
from sqlalchemy import select
from app.db.base import Base
from app.db.models import (
    Match, MatchParticipant, Player, PlayerRating, RatingEvent,
)
from app.rating.service import apply_singles_update


async def _setup(session, engine):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    p1 = Player(phone_e164="+919800000020", display_name="A", firebase_uid="u-20")
    p2 = Player(phone_e164="+919800000021", display_name="B", firebase_uid="u-21")
    session.add_all([p1, p2])
    await session.flush()
    session.add_all([
        PlayerRating(player_id=p1.id, format="S"),
        PlayerRating(player_id=p1.id, format="D"),
        PlayerRating(player_id=p2.id, format="S"),
        PlayerRating(player_id=p2.id, format="D"),
    ])
    now = datetime.now(UTC)
    m = Match(format="S", played_at=now, submitted_by=p1.id,
              status="pending", validation_deadline=now + timedelta(hours=72))
    session.add(m); await session.flush()
    session.add_all([
        MatchParticipant(match_id=m.id, player_id=p1.id, team=1, is_submitter=True, confirmed_at=now),
        MatchParticipant(match_id=m.id, player_id=p2.id, team=2),
    ])
    await session.commit()
    return p1, p2, m


async def test_singles_update_changes_ratings_and_emits_events(engine, session):
    p1, p2, m = await _setup(session, engine)

    # team 1 wins
    await apply_singles_update(session, match_id=m.id, winning_team=1)
    await session.commit()

    r1 = (await session.execute(
        select(PlayerRating).where(
            (PlayerRating.player_id == p1.id) & (PlayerRating.format == "S"))
    )).scalar_one()
    r2 = (await session.execute(
        select(PlayerRating).where(
            (PlayerRating.player_id == p2.id) & (PlayerRating.format == "S"))
    )).scalar_one()

    assert r1.rating > 3.5
    assert r2.rating < 3.5
    assert r1.matches_played == 1
    assert r2.matches_played == 1

    events = (await session.execute(select(RatingEvent))).scalars().all()
    assert len(events) == 2
    assert {e.player_id for e in events} == {p1.id, p2.id}
