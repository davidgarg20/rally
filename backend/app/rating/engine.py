"""Rally rating engine — single Glicko-2 rating per player + margin amplification.

One rating per player. Singles and doubles both update the same number.

Algorithm (singles):
  1. Standard Glicko-2 update with binary outcome (1.0 win, 0.0 loss).
  2. Multiply the resulting rating delta by:
        1 + BETA_MARGIN * (winner_score - loser_score) / winner_score
     So a 21-19 grind scales the delta ~1.07, a 21-5 blowout ~1.53.
  3. Floor the rating at RATING_FLOOR.

Doubles: each player runs a "virtual singles match" against the opposing
team's average rating (arithmetic mean) + quadrature-mean RD. Glicko's
expected-score curve does the right thing — a lower-rated partner gets
more credit for an upset; a higher-rated one takes more of the blame on
a loss. No asymmetric per-partner share added on top.

Volatility doesn't respond to margin (Glicko sees a binary outcome). UX
guarantee that's worth the tradeoff: winning never lowers your rating.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

from app.rating.glicko2 import Player

# Cold-start state for new players.
DEFAULT_RATING = 1500.0
DEFAULT_RD = 350.0
DEFAULT_VOL = 0.06

# Floor on rating — even a long losing streak can't push a player below this.
RATING_FLOOR = 100.0

# Margin-of-victory amplification coefficient.
BETA_MARGIN = 0.7

# Glicko-2 internal scale factor for age_rating round-tripping.
_GLICKO_SCALE = 173.7178


@dataclass(frozen=True)
class RatingSnapshot:
    """Pre/post state for one player in one match. Use to persist rating_events."""
    rating_before: float
    rating_after: float
    rd_before: float
    rd_after: float
    vol_before: float
    vol_after: float


def make_player() -> Player:
    """Cold-start: rating=1500, rd=350, vol=0.06."""
    return Player(rating=DEFAULT_RATING, rd=DEFAULT_RD, vol=DEFAULT_VOL)


def margin_ratio(winner_score: int, loser_score: int) -> float:
    """(winner − loser) / winner. ∈ (0, 1]."""
    if winner_score <= 0:
        raise ValueError(f"winner_score must be > 0, got {winner_score}")
    if loser_score < 0:
        raise ValueError(f"loser_score must be >= 0, got {loser_score}")
    if winner_score <= loser_score:
        raise ValueError(
            f"winner_score ({winner_score}) must be > loser_score ({loser_score})"
        )
    return (winner_score - loser_score) / winner_score


def _scaling_for(winner_score: int, loser_score: int) -> float:
    """1 + BETA_MARGIN × margin_ratio."""
    return 1.0 + BETA_MARGIN * margin_ratio(winner_score, loser_score)


def _apply_weighted(
    player: Player,
    rating_before: float, rd_before: float, vol_before: float,
    opp_rating: float, opp_rd: float,
    score: float, scaling: float,
) -> RatingSnapshot:
    """Run Glicko-2 with a clean win/loss score, then scale rating + RD
    deltas by `scaling`. Floor rating. Returns a snapshot."""
    player.update_player([opp_rating], [opp_rd], [score])
    if scaling != 1.0:
        player.rating = rating_before + (player.rating - rating_before) * scaling
        player.rd = rd_before + (player.rd - rd_before) * scaling
    if player.rating < RATING_FLOOR:
        player.rating = RATING_FLOOR
    return RatingSnapshot(
        rating_before=rating_before, rating_after=player.rating,
        rd_before=rd_before, rd_after=player.rd,
        vol_before=vol_before, vol_after=player.vol,
    )


def update_singles(
    winner: Player, loser: Player,
    winner_score: int, loser_score: int,
) -> tuple[RatingSnapshot, RatingSnapshot]:
    """Update both players after a singles match. Mutates in place.
    Returns (winner_snapshot, loser_snapshot)."""
    if winner is loser:
        raise ValueError("winner and loser must be different players")

    scaling = _scaling_for(winner_score, loser_score)

    w_r, w_rd, w_v = winner.rating, winner.rd, winner.vol
    l_r, l_rd, l_v = loser.rating, loser.rd, loser.vol

    w_snap = _apply_weighted(winner, w_r, w_rd, w_v, l_r, l_rd, 1.0, scaling)
    l_snap = _apply_weighted(loser, l_r, l_rd, l_v, w_r, w_rd, 0.0, scaling)
    return w_snap, l_snap


def update_doubles(
    winners: tuple[Player, Player], losers: tuple[Player, Player],
    winner_score: int, loser_score: int,
) -> tuple[RatingSnapshot, RatingSnapshot, RatingSnapshot, RatingSnapshot]:
    """Update all four players after a doubles match.

    Each player runs a virtual 1v1 against the opposing team's average
    rating; quadrature mean for RD. Equal per-partner treatment —
    Glicko's expected-score curve naturally rewards lower-rated upsets.

    Returns (w1, w2, l1, l2) snapshots in the order given.
    """
    w1, w2 = winners
    l1, l2 = losers
    if len({id(w1), id(w2), id(l1), id(l2)}) != 4:
        raise ValueError("doubles requires four distinct players")

    # Team averages.
    team_w_rating = (w1.rating + w2.rating) / 2
    team_l_rating = (l1.rating + l2.rating) / 2
    team_w_rd = math.sqrt((w1.rd ** 2 + w2.rd ** 2) / 2)
    team_l_rd = math.sqrt((l1.rd ** 2 + l2.rd ** 2) / 2)

    scaling = _scaling_for(winner_score, loser_score)

    # Snapshot pre-match state for each player.
    w1_r, w1_rd, w1_v = w1.rating, w1.rd, w1.vol
    w2_r, w2_rd, w2_v = w2.rating, w2.rd, w2.vol
    l1_r, l1_rd, l1_v = l1.rating, l1.rd, l1.vol
    l2_r, l2_rd, l2_v = l2.rating, l2.rd, l2.vol

    w1_snap = _apply_weighted(w1, w1_r, w1_rd, w1_v, team_l_rating, team_l_rd, 1.0, scaling)
    w2_snap = _apply_weighted(w2, w2_r, w2_rd, w2_v, team_l_rating, team_l_rd, 1.0, scaling)
    l1_snap = _apply_weighted(l1, l1_r, l1_rd, l1_v, team_w_rating, team_w_rd, 0.0, scaling)
    l2_snap = _apply_weighted(l2, l2_r, l2_rd, l2_v, team_w_rating, team_w_rd, 0.0, scaling)
    return w1_snap, w2_snap, l1_snap, l2_snap


def age_rating(player: Player, periods_inactive: int) -> None:
    """Inflate RD for N inactive rating periods. Glicko-2 step 6.

    phi' = sqrt(phi^2 + N * sigma^2). Capped at DEFAULT_RD.
    """
    if periods_inactive <= 0:
        return
    phi = player.rd / _GLICKO_SCALE
    phi_aged = math.sqrt(phi ** 2 + periods_inactive * player.vol ** 2)
    player.rd = min(DEFAULT_RD, phi_aged * _GLICKO_SCALE)
