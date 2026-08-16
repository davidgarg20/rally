from types import SimpleNamespace
from uuid import uuid4

import pytest

from app.auth.firebase import FirebaseIdentity
from app.errors import Conflict, Forbidden
from app.matches import service


class FakeSession:
    def __init__(self) -> None:
        self.committed = False

    async def commit(self) -> None:
        self.committed = True


@pytest.mark.asyncio
async def test_participant_can_dispute_pending_match(monkeypatch) -> None:
    me = SimpleNamespace(id=uuid4(), firebase_uid="me", display_name="Me")
    opponent = SimpleNamespace(id=uuid4(), firebase_uid="opponent", display_name="Opponent")
    match = SimpleNamespace(id=uuid4(), status="pending")
    my_row = SimpleNamespace(disputed_at=None)
    opponent_row = SimpleNamespace(disputed_at=None)
    sent_to: list[str] = []

    async def get_player(_session, _uid):
        return me

    async def get_match(_session, _match_id):
        return match

    async def get_participants(_session, _match_id):
        return [(my_row, me), (opponent_row, opponent)]

    async def send_notification(uid, **_kwargs):
        sent_to.append(uid)

    monkeypatch.setattr(service, "get_by_firebase_uid", get_player)
    monkeypatch.setattr(service, "load_match", get_match)
    monkeypatch.setattr(service, "load_participants", get_participants)
    monkeypatch.setattr(service.fcm, "send_to_uid", send_notification)

    session = FakeSession()
    result = await service.dispute_match(
        session, FirebaseIdentity(uid="me"), match.id,
    )

    assert result is match
    assert match.status == "disputed"
    assert my_row.disputed_at is not None
    assert session.committed is True
    assert sent_to == ["me", "opponent"]


@pytest.mark.asyncio
async def test_non_participant_cannot_dispute_match(monkeypatch) -> None:
    me = SimpleNamespace(id=uuid4(), firebase_uid="me", display_name="Me")
    opponent = SimpleNamespace(id=uuid4(), firebase_uid="opponent", display_name="Opponent")
    match = SimpleNamespace(id=uuid4(), status="pending")

    async def get_player(_session, _uid):
        return me

    async def get_match(_session, _match_id):
        return match

    async def get_participants(_session, _match_id):
        return [(SimpleNamespace(disputed_at=None), opponent)]

    monkeypatch.setattr(service, "get_by_firebase_uid", get_player)
    monkeypatch.setattr(service, "load_match", get_match)
    monkeypatch.setattr(service, "load_participants", get_participants)

    with pytest.raises(Forbidden):
        await service.dispute_match(
            FakeSession(), FirebaseIdentity(uid="me"), match.id,
        )


@pytest.mark.asyncio
async def test_validated_match_cannot_be_disputed(monkeypatch) -> None:
    me = SimpleNamespace(id=uuid4(), firebase_uid="me", display_name="Me")
    match = SimpleNamespace(id=uuid4(), status="validated")

    async def get_player(_session, _uid):
        return me

    async def get_match(_session, _match_id):
        return match

    monkeypatch.setattr(service, "get_by_firebase_uid", get_player)
    monkeypatch.setattr(service, "load_match", get_match)

    with pytest.raises(Conflict):
        await service.dispute_match(
            FakeSession(), FirebaseIdentity(uid="me"), match.id,
        )
