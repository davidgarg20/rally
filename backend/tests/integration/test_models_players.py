import uuid
from sqlalchemy import text
from app.db.base import Base
from app.db.models import Player, PlayerRating

async def test_player_round_trip(engine, session):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    player = Player(
        phone_e164="+919800000001",
        display_name="Asha",
        firebase_uid="fb-uid-001",
    )
    session.add(player)
    await session.flush()
    session.add(PlayerRating(player_id=player.id, format="S"))
    session.add(PlayerRating(player_id=player.id, format="D"))
    await session.commit()

    got = (await session.execute(
        text("select display_name from players where phone_e164=:p"),
        {"p": "+919800000001"},
    )).scalar_one()
    assert got == "Asha"
