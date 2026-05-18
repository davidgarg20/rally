class GameScoreError(ValueError):
    pass

class MatchScoreError(ValueError):
    pass


def game_winner(t1: int, t2: int) -> int:
    if t1 < 0 or t2 < 0:
        raise GameScoreError("negative score")
    hi, lo = max(t1, t2), min(t1, t2)
    if hi > 30 or lo > 30:
        raise GameScoreError("score above cap of 30")
    if hi < 21:
        raise GameScoreError("no winner: max score below 21")
    if hi == 30:
        if lo != 29:
            raise GameScoreError("score of 30 must be paired with 29")
    elif hi - lo < 2:
        raise GameScoreError("winner must lead by 2")
    return 1 if t1 > t2 else 2


def match_winner(games: list[tuple[int, int]]) -> int:
    if not games:
        raise MatchScoreError("no games recorded")
    wins = {1: 0, 2: 0}
    for t1, t2 in games:
        wins[game_winner(t1, t2)] += 1
    if wins[1] == wins[2]:
        raise MatchScoreError("game wins are tied")
    return 1 if wins[1] > wins[2] else 2
