import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rally/api/players_api.dart';
import 'package:rally/auth/auth_controller.dart';
import 'package:rally/models/rating_event.dart';
import 'package:rally/state/recent_matches_provider.dart';
import 'package:rally/state/session_provider.dart';
import 'package:rally/ui/widgets/async_value_view.dart';
import 'package:rally/ui/widgets/empty_state.dart';
import 'package:rally/ui/widgets/match_tile.dart';

final _historyProvider = FutureProvider<List<RatingHistoryPoint>>((ref) async {
  final res = await ref.watch(playersApiProvider).ratingHistory();
  return res.fold(onOk: (h) => h, onErr: (e) => throw e);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final history = ref.watch(_historyProvider);
    final matches = ref.watch(recentMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/onboarding/phone');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AsyncValueView(
            value: player,
            data: (p) => p == null
                ? const EmptyState(message: 'No profile')
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.displayName,
                              style: Theme.of(context).textTheme.headlineMedium),
                          Text(p.phoneE164),
                          const SizedBox(height: 8),
                          Text(
                            p.overall.rating == null
                                ? 'Rating: — (${p.overall.matchesPlayed} matches)'
                                : 'Rating: ${p.overall.rating!.round()} '
                                    '(${p.overall.matchesPlayed} matches)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text('Rating history (last 90 days)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AsyncValueView(
            value: history,
            data: (events) => events.isEmpty
                ? const EmptyState(message: 'No rated matches yet.')
                : _HistoryChart(events: events),
          ),
          const SizedBox(height: 16),
          Text('Match history',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AsyncValueView(
            value: matches,
            data: (list) => list.isEmpty
                ? const EmptyState(message: 'No matches.')
                : Column(
                    children: [
                      for (final m in list)
                        MatchTile(match: m, onTap: () => context.push('/match/${m.id}'))
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  const _HistoryChart({required this.events});
  final List<RatingHistoryPoint> events;

  /// Combine S + D events into a single "overall rating after this event"
  /// series. We rebuild a running per-format rating map as we walk events
  /// in time order, then for each event compute the match-count-weighted
  /// average using the per-format match counts up to that point.
  List<({DateTime t, double rating})> _overallSeries() {
    if (events.isEmpty) return const [];
    final sorted = [...events]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final lastRating = <String, double>{};
    final count = <String, int>{};
    final out = <({DateTime t, double rating})>[];
    for (final e in sorted) {
      lastRating[e.format] = e.ratingAfter;
      count[e.format] = (count[e.format] ?? 0) + 1;
      double weighted = 0;
      int total = 0;
      lastRating.forEach((fmt, r) {
        final c = count[fmt] ?? 0;
        weighted += r * c;
        total += c;
      });
      if (total > 0) {
        out.add((t: e.createdAt, rating: weighted / total));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final series = _overallSeries();
    if (series.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RallySpace.md,
          vertical: RallySpace.lg,
        ),
        child: Text(
          series.length == 1
              ? 'One match logged. Play more to see your trend.'
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

    double dayOffset(DateTime t) => now.difference(t).inDays.toDouble().clamp(0, spanDays);

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
