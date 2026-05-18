import pytest
from app.rating.glicko2 import Rating, update

def test_glickman_reference_example():
    player = Rating(rating=1500.0, rd=200.0, volatility=0.06)
    opponents = [
        Rating(rating=1400.0, rd=30.0, volatility=0.06),
        Rating(rating=1550.0, rd=100.0, volatility=0.06),
        Rating(rating=1700.0, rd=300.0, volatility=0.06),
    ]
    scores = [1.0, 0.0, 0.0]

    result = update(player, opponents, scores, tau=0.5)

    assert result.rating == pytest.approx(1464.06, abs=0.05)
    assert result.rd == pytest.approx(151.52, abs=0.5)
    assert result.volatility == pytest.approx(0.05999, abs=0.0005)


def test_no_matches_increases_rd_only():
    player = Rating(rating=1500.0, rd=200.0, volatility=0.06)
    result = update(player, [], [], tau=0.5)
    assert result.rating == pytest.approx(1500.0, abs=0.001)
    assert result.rd > 200.0
    assert result.volatility == pytest.approx(0.06, abs=0.0005)
