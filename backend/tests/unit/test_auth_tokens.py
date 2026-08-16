from app.auth.firebase import _verify_rally_token, create_access_token


def test_rally_access_token_round_trip() -> None:
    token = create_access_token("web-test-user", "player@example.com")

    identity = _verify_rally_token(token)

    assert identity is not None
    assert identity.uid == "web-test-user"
    assert identity.email == "player@example.com"
    assert identity.phone_e164 is None


def test_invalid_rally_access_token_is_rejected() -> None:
    assert _verify_rally_token("not-a-token") is None
