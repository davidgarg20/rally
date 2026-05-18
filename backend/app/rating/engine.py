"""Rally rating engine — Glicko-2 with margin-of-victory weighting.

Single-set matches only. Supports singles and doubles. No length factor —
we don't care whether the game was to 11, 15, 21, or 31. The whole
"point format" concept lives outside the engine.

Extension on top of standard Glicko-2:

Glicko-2 runs with a clean win/loss score (s=1.0 / s=0.0), so the winner
always gains rating and the loser always loses rating regardless of how
much stronger the favorite was. Margin of victory then *amplifies* the
magnitude of the rating/RD delta:
    margin_factor = 1 + BETA_MARGIN * (winner − loser) / winner
With BETA_MARGIN = 0.7: a 21-19 nailbiter scales the delta by 1.07
(almost-standard Glicko-2); a 21-15 by 1.20; a 21-0 shutout by 1.70.
Every win still gets at least the base Glicko-2 delta — margin only adds.

Trade-off vs. classical margin-adjusted Glicko-2: volatility doesn't respond
to margin (the Glicko-2 update sees a binary outcome). Worth it for the UX
guarantee that winning never lowers your rating.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

from app.rating.glicko2 import Player

# Cold-start: every new player starts identically. RD=350 is the Glicko-2
# convention for "unrated" — high uncertainty so the first few matches move
# the rating fast, then it stabilizes naturally after ~10 matches.
DEFAULT_RATING = 1500
DEFAULT_RD = 350
DEFAULT_VOL = 0.06

# Floor on rating — even a long losing streak can't push a player below this.
RATING_FLOOR = 100

# Margin-of-victory amplification coefficient. The post-Glicko delta is
# multiplied by (1 + BETA_MARGIN * margin_ratio).
BETA_MARGIN = 0.7

# Glicko-2 internal scale factor for age_rating round-tripping.
_GLICKO_SCALE = 173.7178

# Doubles split bias coefficient: how strongly the rating gap between partners
# shifts the team-delta split. With DOUBLES_BIAS = 0.0005:
#   gap 200 → 60/40, gap 500 → 75/25, gap 1000+ → capped (see MIN_DOUBLES_SHARE).
DOUBLES_BIAS = 0.0005

# Floor on the disfavored partner's share of the team delta — even with a huge
# rating gap, the disfavored partner still absorbs a small slice of credit
# or blame. Caps max split at (1 - MIN)/MIN, e.g. 0.05 → 95/5.
MIN_DOUBLES_SHARE = 0.05


@dataclass(frozen=True)
class RatingSnapshot:
    """Pre/post state for one player in one match. Use to persist rating_history."""
    rating_before: float
    rating_after: float
    rd_before: float
    rd_after: float
    vol_before: float
    vol_after: float


def make_player() -> Player:
    """Construct a new Player at the cold-start state (1500 / RD=350 / vol=0.06)."""
    return Player(rating=DEFAULT_RATING, rd=DEFAULT_RD, vol=DEFAULT_VOL)


def margin_ratio(winner_score: int, loser_score: int) -> float:
    """Return the margin ratio for a one-set result.

    margin_ratio ∈ (0, 1] — (winner − loser) / winner
    """
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
    """Margin amplification only: 1 + BETA_MARGIN * margin_ratio."""
    return 1.0 + BETA_MARGIN * margin_ratio(winner_score, loser_score)


def _apply_weighted(player: Player,
                    rating_before: float, rd_before: float, vol_before: float,
                    opp_rating: float, opp_rd: float,
                    score: float, scaling: float) -> RatingSnapshot:
    """Run Glicko-2 once with a clean win/loss score, then scale the resulting
    rating and RD deltas by `scaling`. Final rating floored at RATING_FLOOR.
    """
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


def update_singles(winner: Player, loser: Player,
                   winner_score: int, loser_score: int
                   ) -> tuple[RatingSnapshot, RatingSnapshot]:
    """Update both players' ratings after a singles match.

    Returns (winner_snapshot, loser_snapshot). Mutates both Player objects.
    """
    if winner is loser:
        raise ValueError("winner and loser must be different players")

    scaling = _scaling_for(winner_score, loser_score)

    w_r, w_rd, w_v = winner.rating, winner.rd, winner.vol
    l_r, l_rd, l_v = loser.rating, loser.rd, loser.vol

    w_snap = _apply_weighted(winner, w_r, w_rd, w_v, l_r, l_rd, 1.0, scaling)
    l_snap = _apply_weighted(loser, l_r, l_rd, l_v, w_r, w_rd, 0.0, scaling)
    return w_snap, l_snap


def _split_doubles_delta(p1_rating: float, p2_rating: float,
                         team_delta: float) -> tuple[float, float]:
    """Split a team's rating delta between two partners.

    Returns (delta_for_p1, delta_for_p2). Both shares retain the sign of
    team_delta (winners only gain, losers only lose).

    Bias direction:
      - On a win  (team_delta > 0): lower-rated partner gets the bigger share.
      - On a loss (team_delta < 0): higher-rated partner takes more of the burden.
    """
    if p1_rating == p2_rating:
        half = team_delta / 2
        return half, half

    max_bias = 0.5 - MIN_DOUBLES_SHARE
    bias = min(max_bias, abs(p1_rating - p2_rating) * DOUBLES_BIAS)

    if team_delta > 0:
        favored_share = 0.5 + bias
        other_share = 0.5 - bias
    else:
        favored_share = 0.5 - bias
        other_share = 0.5 + bias

    if p1_rating < p2_rating:
        return team_delta * favored_share, team_delta * other_share
    else:
        return team_delta * other_share, team_delta * favored_share


def update_doubles(
    winners: tuple[Player, Player], losers: tuple[Player, Player],
    winner_score: int, loser_score: int,
) -> tuple[RatingSnapshot, RatingSnapshot, RatingSnapshot, RatingSnapshot]:
    """Update all four players' ratings after a doubles match.

    Algorithm:
      1. Compute team-average rating (mean) and team RD (RMS of partner RDs).
      2. Run a virtual singles match between the team averages → team deltas.
      3. Split each team's rating delta asymmetrically between its partners.
      4. RD + volatility update per-player via individual Glicko-2 vs opposing
         team avg. Rating is overridden by the team-split share.

    Returns (w1, w2, l1, l2) snapshots.
    """
    w1, w2 = winners
    l1, l2 = losers
    if len({id(w1), id(w2), id(l1), id(l2)}) != 4:
        raise ValueError("doubles requires four distinct players")

    w1_r, w1_rd, w1_v = w1.rating, w1.rd, w1.vol
    w2_r, w2_rd, w2_v = w2.rating, w2.rd, w2.vol
    l1_r, l1_rd, l1_v = l1.rating, l1.rd, l1.vol
    l2_r, l2_rd, l2_v = l2.rating, l2.rd, l2.vol

    # Step 1: team averages.
    team_w_rating = (w1_r + w2_r) / 2
    team_l_rating = (l1_r + l2_r) / 2
    team_w_rd = math.sqrt((w1_rd ** 2 + w2_rd ** 2) / 2)
    team_l_rd = math.sqrt((l1_rd ** 2 + l2_rd ** 2) / 2)
    avg_vol = (w1_v + w2_v + l1_v + l2_v) / 4

    # Step 2: virtual singles between team averages → team deltas.
    virtual_w = Player(rating=team_w_rating, rd=team_w_rd, vol=avg_vol)
    virtual_l = Player(rating=team_l_rating, rd=team_l_rd, vol=avg_vol)
    vw_snap, vl_snap = update_singles(
        virtual_w, virtual_l, winner_score, loser_score
    )
    team_w_delta = vw_snap.rating_after - vw_snap.rating_before
    team_l_delta = vl_snap.rating_after - vl_snap.rating_before

    # Step 3: asymmetric split.
    d_w1, d_w2 = _split_doubles_delta(w1_r, w2_r, team_w_delta)
    d_l1, d_l2 = _split_doubles_delta(l1_r, l2_r, team_l_delta)

    # Step 4: per-player Glicko (for RD + vol). Rating gets overwritten below.
    scaling = _scaling_for(winner_score, loser_score)
    indiv_w1 = _apply_weighted(w1, w1_r, w1_rd, w1_v, team_l_rating, team_l_rd, 1.0, scaling)
    indiv_w2 = _apply_weighted(w2, w2_r, w2_rd, w2_v, team_l_rating, team_l_rd, 1.0, scaling)
    indiv_l1 = _apply_weighted(l1, l1_r, l1_rd, l1_v, team_w_rating, team_w_rd, 0.0, scaling)
    indiv_l2 = _apply_weighted(l2, l2_r, l2_rd, l2_v, team_w_rating, team_w_rd, 0.0, scaling)

    # Override rating with team-split share; floor applied here too.
    w1.rating = max(RATING_FLOOR, w1_r + d_w1)
    w2.rating = max(RATING_FLOOR, w2_r + d_w2)
    l1.rating = max(RATING_FLOOR, l1_r + d_l1)
    l2.rating = max(RATING_FLOOR, l2_r + d_l2)

    return (
        RatingSnapshot(w1_r, w1.rating, w1_rd, indiv_w1.rd_after, w1_v, indiv_w1.vol_after),
        RatingSnapshot(w2_r, w2.rating, w2_rd, indiv_w2.rd_after, w2_v, indiv_w2.vol_after),
        RatingSnapshot(l1_r, l1.rating, l1_rd, indiv_l1.rd_after, l1_v, indiv_l1.vol_after),
        RatingSnapshot(l2_r, l2.rating, l2_rd, indiv_l2.rd_after, l2_v, indiv_l2.vol_after),
    )


def age_rating(player: Player, periods_inactive: int) -> None:
    """Inflate a player's RD for N inactive rating periods (in-place).

    Glicko-2 step-6 formula: φ' = sqrt(φ² + N·σ²). Capped at DEFAULT_RD.
    """
    if periods_inactive <= 0:
        return
    phi = player.rd / _GLICKO_SCALE
    phi_aged = math.sqrt(phi ** 2 + periods_inactive * player.vol ** 2)
    player.rd = min(DEFAULT_RD, phi_aged * _GLICKO_SCALE)
