import 'package:flutter/material.dart';
import 'package:rally/models/player.dart';
import 'package:rally/models/rating_event.dart';
import 'package:rally/ui/design/colors.dart';
import 'package:rally/ui/design/spacing.dart';
import 'package:rally/ui/design/typography.dart';
import 'package:rally/ui/share/share_cards.dart';
import 'package:rally/ui/share/share_sheet.dart';

/// Hero card on the home screen.
///
/// Visual hierarchy:
///   big number   = overall (weighted blend of singles + doubles by matches)
///   small chips  = singles + doubles individually
///
/// 7-day delta chip on the right shows recent overall trend when available.
class RatingCard extends StatelessWidget {
  const RatingCard({
    super.key,
    required this.player,
    this.recentEvents = const [],
  });

  final Player player;
  final List<RatingHistoryPoint> recentEvents;

  PlayerRating? _ratingFor(RatingFormat fmt) {
    for (final r in player.ratings) {
      if (r.format == fmt) return r;
    }
    return null;
  }

  /// Estimate overall delta: weighted-avg the per-format 7-day deltas by
  /// match counts. Returns null if not enough recent history.
  double? _sevenDayOverallDelta() {
    if (player.overall.rating == null) return null;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    double? deltaFor(String fmt) {
      final pts = recentEvents
          .where((e) => e.format == fmt && e.createdAt.isAfter(cutoff))
          .toList();
      if (pts.length < 2) return null;
      pts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return pts.last.ratingAfter - pts.first.ratingAfter;
    }
    final ds = deltaFor('S');
    final dd = deltaFor('D');
    final s = _ratingFor(RatingFormat.singles);
    final d = _ratingFor(RatingFormat.doubles);
    final sCount = s?.matchesPlayed ?? 0;
    final dCount = d?.matchesPlayed ?? 0;
    if (ds == null && dd == null) return null;
    if (ds == null) return dd;
    if (dd == null) return ds;
    final total = sCount + dCount;
    if (total == 0) return null;
    return (ds * sCount + dd * dCount) / total;
  }

  @override
  Widget build(BuildContext context) {
    final overall = player.overall;
    final delta = _sevenDayOverallDelta();

    return Card(
      child: Padding(
        padding: RallyInsets.cardPaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'RALLY RATING',
                  style: RallyText.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: RallyColors.brand,
                  ),
                ),
                const Spacer(),
                if (delta != null) _DeltaChip(delta: delta),
                RallySpace.hGapSm,
                InkWell(
                  borderRadius: BorderRadius.circular(RallyRadius.pill),
                  onTap: () => ShareCardSheet.show(
                    context,
                    cards: [
                      RatingShareCard(me: player, sevenDayDelta: delta),
                    ],
                    shareText: "I'm @${player.username} on Rally — "
                        "current rating ${(player.overall.rating ?? 1500).round()}.",
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: RallyColors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
            RallySpace.gapXs,
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  (overall.rating ?? 1500).round().toString(),
                  style: RallyText.rating,
                ),
                RallySpace.hGapSm,
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${overall.matchesPlayed} matches',
                    style: RallyText.caption,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});
  final double delta;

  @override
  Widget build(BuildContext context) {
    final positive = delta >= 0;
    final color = positive ? RallyColors.success : RallyColors.danger;
    final sign = positive ? '+' : '';
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
            positive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$sign${delta.round()} · 7d',
            style: RallyText.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
