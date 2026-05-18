import pytest
from app.rating.scale import to_display, from_display

def test_seed_round_trip():
    g = from_display(rating=3.625, rd=1.2)
    assert g.rating == pytest.approx(1500.0, abs=0.001)
    assert g.rd == pytest.approx(320.0, abs=0.001)

def test_endpoints():
    assert to_display(800.0, 0.0)[0] == pytest.approx(1.0)
    assert to_display(2400.0, 0.0)[0] == pytest.approx(7.0)
