import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rally/models/match.dart';
import 'package:rally/ui/design/colors.dart';
import 'package:rally/ui/design/spacing.dart';
import 'package:rally/ui/design/typography.dart';

/// A row in the home / profile match lists.
///
/// If `myPhone` is provided, the tile shows a win/loss indicator strip
/// on the left and the rating delta on the right (when validated).
class MatchTile extends StatelessWidget {
  const MatchTile({
    super.key,
    required this.match,
    required this.onTap,
    this.myPhone,
    this.previewDelta,
  });

  final MatchOut match;
  final VoidCallback onTap;
  final String? myPhone;

  /// If provided, shown as a "would change by +X" pill for pending matches.
  final double? previewDelta;

  Participant? get _me {
    if (myPhone == null) return null;
    for (final p in match.participants) {
      if (p.phoneE164 == myPhone) return p;
    }
    return null;
  }

  /// 1, 2, or null if scores haven't validated as a winner.
  int? _winningTeam() {
    int wins1 = 0, wins2 = 0;
    for (final g in match.games) {
      if (g.team1Points > g.team2Points) {
        wins1++;
      } else if (g.team2Points > g.team1Points) {
        wins2++;
      }
    }
    if (wins1 == wins2) return null;
    return wins1 > wins2 ? 1 : 2;
  }

  bool? _didIWin() {
    final me = _me;
    final winner = _winningTeam();
    if (me == null || winner == null) return null;
    return me.team == winner;
  }

  double? _myDelta() {
    final me = _me;
    if (me?.playerId == null) return null;
    for (final d in match.ratingDeltas) {
      if (d.playerId == me!.playerId) {
        return d.ratingAfter - d.ratingBefore;
      }
    }
    return null;
  }

  String _scoreSummary() => match.games
      .map((g) => '${g.team1Points}–${g.team2Points}')
      .join(', ');

  @override
  Widget build(BuildContext context) {
    final iWon = _didIWin();
    final delta = _myDelta();

    // Left strip color encodes win/loss when we know which team you were on.
    final stripColor = switch (iWon) {
      true => RallyColors.success,
      false => RallyColors.danger,
      null => RallyColors.divider,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: stripColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RallySpace.md,
                    vertical: RallySpace.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (iWon != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: RallySpace.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: stripColor.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(RallyRadius.pill),
                              ),
                              child: Text(
                                iWon ? 'WIN' : 'LOSS',
                                style: RallyText.caption.copyWith(
                                  color: stripColor,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          if (iWon != null) RallySpace.hGapSm,
                          Text(
                            match.format == MatchFormat.singles
                                ? 'Singles'
                                : 'Doubles',
                            style: RallyText.label.copyWith(
                              color: RallyColors.inkMuted,
                            ),
                          ),
                          const Spacer(),
                          _StatusChip(status: match.status),
                        ],
                      ),
                      RallySpace.gapXs,
                      Text(_scoreSummary(), style: RallyText.title),
                      RallySpace.gapXs,
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat.MMMd()
                                  .add_jm()
                                  .format(match.playedAt.toLocal()),
                              style: RallyText.caption,
                            ),
                          ),
                          if (delta != null && delta != 0)
                            Text(
                              '${delta >= 0 ? '+' : ''}${delta.round()}',
                              style: RallyText.label.copyWith(
                                color: delta >= 0
                                    ? RallyColors.success
                                    : RallyColors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          else if (previewDelta != null)
                            _PreviewPill(delta: previewDelta!),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewPill extends StatelessWidget {
  const _PreviewPill({required this.delta});
  final double delta;

  @override
  Widget build(BuildContext context) {
    final positive = delta >= 0;
    final color = positive ? RallyColors.success : RallyColors.danger;
    final sign = positive ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RallySpace.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RallyRadius.pill),
      ),
      child: Text(
        '$sign${delta.round()} if confirmed',
        style: RallyText.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      MatchStatus.pending => (RallyColors.statusPending, 'Pending'),
      MatchStatus.validated => (RallyColors.statusValidated, 'Validated'),
      MatchStatus.disputed => (RallyColors.statusDisputed, 'Disputed'),
      MatchStatus.expired => (RallyColors.statusExpired, 'Expired'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RallySpace.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RallyRadius.pill),
      ),
      child: Text(
        label,
        style: RallyText.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
