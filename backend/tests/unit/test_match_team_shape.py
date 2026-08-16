import pytest

from app.errors import BadRequest
from app.matches.service import _check_team_shape


def test_doubles_accepts_two_distinct_players_per_team() -> None:
    _check_team_shape("D", ["a", "b"], ["c", "d"])


def test_doubles_rejects_missing_player() -> None:
    with pytest.raises(BadRequest) as error:
        _check_team_shape("D", ["a"], ["c", "d"])

    assert error.value.code == "invalid_team_size"


def test_doubles_rejects_same_player_twice() -> None:
    with pytest.raises(BadRequest) as error:
        _check_team_shape("D", ["a", "a"], ["c", "d"])

    assert error.value.code == "duplicate_player"


def test_doubles_rejects_player_on_both_teams() -> None:
    with pytest.raises(BadRequest) as error:
        _check_team_shape("D", ["a", "b"], ["b", "d"])

    assert error.value.code == "player_on_both_teams"
