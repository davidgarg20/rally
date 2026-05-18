from app.rating.glicko2 import Rating

DISPLAY_MIN, DISPLAY_MAX = 1.0, 7.0
GLICKO_MIN, GLICKO_MAX = 800.0, 2400.0
DISPLAY_SPAN = DISPLAY_MAX - DISPLAY_MIN
GLICKO_SPAN = GLICKO_MAX - GLICKO_MIN
FACTOR = DISPLAY_SPAN / GLICKO_SPAN


def from_display(rating: float, rd: float, volatility: float = 0.06) -> Rating:
    g_rating = GLICKO_MIN + (rating - DISPLAY_MIN) / FACTOR
    g_rd = rd / FACTOR
    return Rating(rating=g_rating, rd=g_rd, volatility=volatility)


def to_display(g_rating: float, g_rd: float) -> tuple[float, float]:
    rating = DISPLAY_MIN + (g_rating - GLICKO_MIN) * FACTOR
    rd = g_rd * FACTOR
    return rating, rd
