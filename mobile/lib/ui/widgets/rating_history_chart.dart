import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:rally/models/rating_event.dart';
import 'package:rally/ui/design/colors.dart';
import 'package:rally/ui/design/spacing.dart';
import 'package:rally/ui/design/typography.dart';

/// Shared overall-rating-over-time chart. Used by both your profile and
/// any public player profile.
class RatingHistoryChart extends StatelessWidget {
  const RatingHistoryChart({super.key, required this.events});
  final List<RatingHistoryPoint> events;

  /// Sort events chronologically and emit (time, rating_after) points.
  /// Single-rating system: no weighting needed.
  List<({DateTime t, double rating})> _series() {
    if (events.isEmpty) return const [];
    final sorted = [...events]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return [
      for (final e in sorted) (t: e.createdAt, rating: e.ratingAfter),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final series = _series();
    if (series.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RallySpace.md,
          vertical: RallySpace.lg,
        ),
        child: Text(
          series.length == 1
              ? 'One match logged. Play more to see the trend.'
              : 'No matches yet.',
          style: RallyText.caption,
        ),
      );
    }

    final now = DateTime.now();
    final start = series.first.t;
    final spanDays = now.difference(start).inDays.clamp(1, 90).toDouble();
    final ratings = series.map((p) => p.rating).toList();
    final minR = ratings.reduce((a, b) => a < b ? a : b);
    final maxR = ratings.reduce((a, b) => a > b ? a : b);
    final pad = (maxR - minR).clamp(40.0, 200.0) * 0.2;
    final yMin = (minR - pad).floorToDouble();
    final yMax = (maxR + pad).ceilToDouble();

    double dayOffset(DateTime t) =>
        now.difference(t).inDays.toDouble().clamp(0, spanDays);

    final spots = series
        .map((p) => FlSpot(spanDays - dayOffset(p.t), p.rating))
        .toList();

    final current = series.last.rating;

    return Padding(
      padding: const EdgeInsets.only(right: RallySpace.sm, top: RallySpace.sm),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: spanDays,
            minY: yMin,
            maxY: yMax,
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: ((yMax - yMin) / 3).clamp(1, 1e9),
              getDrawingHorizontalLine: (_) => FlLine(
                color: RallyColors.divider,
                strokeWidth: 1,
                dashArray: const [4, 4],
              ),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: ((yMax - yMin) / 3).clamp(1, 1e9),
                  getTitlesWidget: (value, _) => Text(
                    value.round().toString(),
                    style: RallyText.caption,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: spanDays / 2,
                  getTitlesWidget: (value, _) {
                    final days = (spanDays - value).round();
                    if (days == 0) return Text('today', style: RallyText.caption);
                    return Text('${days}d ago', style: RallyText.caption);
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => RallyColors.ink,
                getTooltipItems: (spots) => spots
                    .map(
                      (s) => LineTooltipItem(
                        s.y.round().toString(),
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                color: RallyColors.brand,
                barWidth: 2.5,
                isCurved: true,
                curveSmoothness: 0.2,
                preventCurveOverShooting: true,
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, _) => spot == spots.last,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 4,
                    color: RallyColors.brand,
                    strokeColor: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      RallyColors.brand.withValues(alpha: 0.18),
                      RallyColors.brand.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: current,
                  color: RallyColors.brand.withValues(alpha: 0.3),
                  strokeWidth: 1,
                  dashArray: const [3, 3],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: RallyText.caption.copyWith(
                      color: RallyColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                    labelResolver: (_) => current.round().toString(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
