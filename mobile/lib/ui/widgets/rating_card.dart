import 'package:flutter/material.dart';

import 'package:rally/models/player.dart';
import 'package:rally/models/rating_event.dart';
import 'package:rally/ui/design/colors.dart';
import 'package:rally/ui/design/spacing.dart';
import 'package:rally/ui/design/typography.dart';
import 'package:rally/ui/share/share_cards.dart';
import 'package:rally/ui/share/share_sheet.dart';

/// Hero card on the home screen. Single rating per player.
///
/// 7-day delta chip on the right shows recent trend when ≥2 events in the
/// last 7 days.
class RatingCard extends StatelessWidget {
  const RatingCard({
    super.key,
    required this.player,
    this.recentEvents = const [],
  });

  final Player player;
  final List<RatingHistoryPoint> recentEvents;

  double? _sevenDayDelta() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final pts = recentEvents
        .where((e) => e.createdAt.isAfter(cutoff))
        .toList();
    if (pts.length < 2) return null;
    pts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return pts.last.ratingAfter - pts.first.ratingAfter;
  }

  @override
  Widget build(BuildContext context) {
    final delta = _sevenDayDelta();

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
                        "current rating ${player.rating.round()}.",
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
                  player.rating.round().toString(),
                  style: RallyText.rating,
                ),
                RallySpace.hGapSm,
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${player.matchesPlayed} matches',
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
