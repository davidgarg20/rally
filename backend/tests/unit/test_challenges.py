from types import SimpleNamespace
from uuid import uuid4

import pytest

from app.auth.firebase import FirebaseIdentity
from app.challenges import service
from app.errors import Conflict, Forbidden


class FakeSession:
    def __init__(self) -> None:
        self.committed = False

    async def commit(self) -> None:
        self.committed = True


@pytest.mark.asyncio
async def test_challenged_player_can_accept(monkeypatch) -> None:
    me = SimpleNamespace(id=uuid4())
    challenge = SimpleNamespace(
        id=uuid4(),
        challenger_id=uuid4(),
        challenged_id=me.id,
        status="pending",
        responded_at=None,
    )

    async def get_player(_session, _uid):
        return me

    async def get_challenge(_session, _challenge_id):
        return challenge

    monkeypatch.setattr(service, "get_by_firebase_uid", get_player)
    monkeypatch.setattr(service, "load_challenge", get_challenge)

    session = FakeSession()
    result = await service.update_challenge(
        session,
        FirebaseIdentity(uid="me"),
        challenge.id,
        "accepted",
    )

    assert result is challenge
    assert challenge.status == "accepted"
    assert challenge.responded_at is not None
    assert session.committed is True


@pytest.mark.asyncio
async def test_challenger_can_cancel(monkeypatch) -> None:
    me = SimpleNamespace(id=uuid4())
    challenge = SimpleNamespace(
        id=uuid4(),
        challenger_id=me.id,
        challenged_id=uuid4(),
        status="pending",
        responded_at=None,
    )

    async def get_player(_session, _uid):
        return me

    async def get_challenge(_session, _challenge_id):
        return challenge

    monkeypatch.setattr(service, "get_by_firebase_uid", get_player)
    monkeypatch.setattr(service, "load_challenge", get_challenge)

    session = FakeSession()
    await service.update_challenge(
        session,
        FirebaseIdentity(uid="me"),
        challenge.id,
        "cancelled",
    )

    assert challenge.status == "cancelled"
    assert session.committed is True


@pytest.mark.asyncio
async def test_challenger_cannot_accept_own_challenge(monkeypatch) -> None:
    me = SimpleNamespace(id=uuid4())
    challenge = SimpleNamespace(
        id=uuid4(),
        challenger_id=me.id,
        challenged_id=uuid4(),
        status="pending",
    )

    async def get_player(_session, _uid):
        return me

    async def get_challenge(_session, _challenge_id):
        return challenge

    monkeypatch.setattr(service, "get_by_firebase_uid", get_player)
    monkeypatch.setattr(service, "load_challenge", get_challenge)

    with pytest.raises(Forbidden):
        await service.update_challenge(
            FakeSession(),
            FirebaseIdentity(uid="me"),
            challenge.id,
            "accepted",
        )


@pytest.mark.asyncio
async def test_completed_challenge_cannot_change_again(monkeypatch) -> None:
    me = SimpleNamespace(id=uuid4())
    challenge = SimpleNamespace(
        id=uuid4(),
        challenger_id=uuid4(),
        challenged_id=me.id,
        status="declined",
    )

    async def get_player(_session, _uid):
        return me

    async def get_challenge(_session, _challenge_id):
        return challenge

    monkeypatch.setattr(service, "get_by_firebase_uid", get_player)
    monkeypatch.setattr(service, "load_challenge", get_challenge)

    with pytest.raises(Conflict):
        await service.update_challenge(
            FakeSession(),
            FirebaseIdentity(uid="me"),
            challenge.id,
            "accepted",
        )
