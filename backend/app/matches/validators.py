"""Score validation. Single-set matches only.

We don't enforce a specific point format (11, 15, 21, 31, etc.). The only
rules:
  - Scores must be non-negative.
  - Scores can't exceed 100 (cheap sanity cap; nobody plays to 100).
  - Winner must score strictly more than loser.
"""


class GameScoreError(ValueError):
    pass


class MatchScoreError(ValueError):
    pass


_MAX_POINTS = 100


def game_winner(t1: int, t2: int) -> int:
    """Validate a single set's score and return the winning team (1 or 2)."""
    if t1 < 0 or t2 < 0:
        raise GameScoreError("negative score")
    if t1 > _MAX_POINTS or t2 > _MAX_POINTS:
        raise GameScoreError(f"score above cap of {_MAX_POINTS}")
    if t1 == t2:
        raise GameScoreError("tied score: no winner")
    return 1 if t1 > t2 else 2


def match_winner(games: list[tuple[int, int]]) -> int:
    """Single-set match: the one game's winner is the match winner."""
    if not games:
        raise MatchScoreError("no games recorded")
    if len(games) > 1:
        raise MatchScoreError("single-set engine: only one game per match")
    return game_winner(games[0][0], games[0][1])
