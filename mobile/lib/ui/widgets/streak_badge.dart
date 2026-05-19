import 'package:flutter/material.dart';

import 'package:rally/models/match.dart';
import 'package:rally/ui/design/colors.dart';
import 'package:rally/ui/design/spacing.dart';
import 'package:rally/ui/design/typography.dart';

/// "3W" / "2L" pill showing the player's current win or loss streak.
///
/// Walks validated matches most-recent-first and counts consecutive results
/// of the same kind. Returns an empty widget if there's no streak (zero
/// matches, or the player's most recent match is a tie / unscoreable).
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.matches, required this.myPhone});

  final List<MatchOut> matches;
  final String? myPhone;

  /// 1 / 2 / null based on which team the player was on for this match.
  int? _myTeam(MatchOut m) {
    if (myPhone == null) return null;
    for (final p in m.participants) {
      if (p.phoneE164 == myPhone) return p.team;
    }
    return null;
  }

  int? _winningTeam(MatchOut m) {
    if (m.games.isEmpty) return null;
    final g = m.games.first;
    if (g.team1Points == g.team2Points) return null;
    return g.team1Points > g.team2Points ? 1 : 2;
  }

  ({int count, bool isWin})? _streak() {
    final validated = matches
        .where((m) => m.status == MatchStatus.validated)
        .toList()
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
    if (validated.isEmpty) return null;

    bool? streakIsWin;
    int count = 0;
    for (final m in validated) {
      final mine = _myTeam(m);
      final winner = _winningTeam(m);
      if (mine == null || winner == null) break;
      final iWon = mine == winner;
      streakIsWin ??= iWon;
      if (iWon != streakIsWin) break;
      count++;
    }
    if (count == 0 || streakIsWin == null) return null;
    return (count: count, isWin: streakIsWin);
  }

  @override
  Widget build(BuildContext context) {
    final s = _streak();
    if (s == null) return const SizedBox.shrink();
    final color = s.isWin ? RallyColors.success : RallyColors.danger;
    final letter = s.isWin ? 'W' : 'L';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RallySpace.sm,
        vertical: RallySpace.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RallyRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            s.isWin ? Icons.local_fire_department : Icons.trending_down,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${s.count}$letter streak',
            style: RallyText.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
