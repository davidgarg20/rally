import pytest
from app.rating.doubles import carry_scaler

def test_equal_teammates_scaler_is_one():
    assert carry_scaler(player_rating=3.5, team_avg=3.5) == pytest.approx(1.0)

def test_lower_rated_teammate_scales_up():
    assert carry_scaler(player_rating=3.0, team_avg=4.0) > 1.0

def test_higher_rated_teammate_scales_down():
    assert carry_scaler(player_rating=5.0, team_avg=4.0) < 1.0

def test_clamped_lower_bound():
    assert carry_scaler(player_rating=6.5, team_avg=3.0) == pytest.approx(0.5)

def test_clamped_upper_bound():
    assert carry_scaler(player_rating=1.5, team_avg=6.0) == pytest.approx(1.5)
