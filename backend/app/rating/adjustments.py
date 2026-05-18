"""Badminton-specific multiplicative adjustments to Glicko-2 rating deltas.

Both factors are multiplied together and applied to the *delta* coming out of
the standard Glicko-2 update. They never affect RD or volatility — only the
magnitude of the rating change.
"""
from __future__ import annotations
import math

from app.config import settings


def margin_factor(winner_score: int, loser_score: int) -> float:
    """Bigger margin in the deciding game → bigger rating change.

    With beta=0.7:  21–19 → 1.067,  21–15 → 1.200,  21–5 → 1.533.
    """
    margin = winner_score - loser_score
    return 1.0 + settings.beta_margin * (margin / winner_score)


def length_factor(winner_score: int) -> float:
    """Shorter matches = noisier signal = smaller rating change.

    Anchored at ``reference_points`` (default 21).
    11-pt → 0.724, 21-pt → 1.000, 31-pt → 1.215.
    """
    return math.sqrt(winner_score / settings.reference_points)


def total_adjustment(winner_score: int, loser_score: int) -> float:
    """Combined multiplier for a single game's rating delta."""
    return margin_factor(winner_score, loser_score) * length_factor(winner_score)


def match_adjustment(games: list[tuple[int, int]], winning_team: int) -> float:
    """Compute the multiplier across all games of a best-of-N match.

    We average per-game adjustments. This keeps the engine balanced:
    a 2–0 sweep contributes two game-adjustments, a 2–1 grind contributes
    three. The average prevents the multiplier from compounding with game
    count and dominating the actual Glicko delta.
    """
    if not games:
        return 1.0
    total = 0.0
    for t1, t2 in games:
        winner_score = max(t1, t2)
        loser_score = min(t1, t2)
        total += total_adjustment(winner_score, loser_score)
    return total / len(games)
