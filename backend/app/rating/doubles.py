def carry_scaler(player_rating: float, team_avg: float,
                 lo: float = 0.5, hi: float = 1.5) -> float:
    raw = team_avg / player_rating
    return max(lo, min(hi, raw))
