import uuid
from datetime import UTC, datetime, timedelta
from app.db.base import Base
from app.db.models import Match, MatchGame, MatchParticipant, Player

async def test_match_with_participants_and_games(engine, session):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    p1 = Player(phone_e164="+919800000010", display_name="A", firebase_uid="u-10")
    p2 = Player(phone_e164="+919800000011", display_name="B", firebase_uid="u-11")
    session.add_all([p1, p2])
    await session.flush()

    now = datetime.now(UTC)
    match = Match(
        format="S",
        played_at=now,
        submitted_by=p1.id,
        status="pending",
        validation_deadline=now + timedelta(hours=72),
    )
    session.add(match)
    await session.flush()

    session.add_all([
        MatchParticipant(match_id=match.id, player_id=p1.id, team=1, is_submitter=True, confirmed_at=now),
        MatchParticipant(match_id=match.id, player_id=p2.id, team=2),
        MatchGame(match_id=match.id, game_no=1, team1_points=21, team2_points=18),
        MatchGame(match_id=match.id, game_no=2, team1_points=21, team2_points=15),
    ])
    await session.commit()
