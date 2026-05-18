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
                          for (final r in p.ratings)
                            Text('${r.format.name}: ${r.rating.toStringAsFixed(2)} '
                                '(${r.matchesPlayed} matches)'),
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

  @override
  Widget build(BuildContext context) {
    final s = events.where((e) => e.format == 'S').toList();
    final d = events.where((e) => e.format == 'D').toList();

    LineChartBarData barFor(List<RatingHistoryPoint> pts, Color color) =>
        LineChartBarData(
          spots: [for (var i = 0; i < pts.length; i++) FlSpot(i.toDouble(), pts[i].ratingAfter)],
          color: color, isCurved: true, barWidth: 2,
          dotData: const FlDotData(show: false),
        );

    return SizedBox(
      height: 180,
      child: LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          if (s.isNotEmpty) barFor(s, Theme.of(context).colorScheme.primary),
          if (d.isNotEmpty) barFor(d, Theme.of(context).colorScheme.tertiary),
        ],
      )),
    );
  }
}
