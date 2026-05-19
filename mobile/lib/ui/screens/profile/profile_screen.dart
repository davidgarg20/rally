import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rally/api/players_api.dart';
import 'package:rally/auth/auth_controller.dart';
import 'package:rally/models/rating_event.dart';
import 'package:rally/state/recent_matches_provider.dart';
import 'package:rally/state/session_provider.dart';
import 'package:rally/ui/design/colors.dart';
import 'package:rally/ui/design/spacing.dart';
import 'package:rally/ui/design/typography.dart';
import 'package:rally/ui/widgets/async_value_view.dart';
import 'package:rally/ui/widgets/empty_state.dart';
import 'package:rally/ui/widgets/match_tile.dart';
import 'package:rally/ui/widgets/rating_history_chart.dart';

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
                          Text('@${p.username}',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(p.phoneE164,
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 8),
                          Text(
                            'Rating: ${p.rating.round()} '
                            '(${p.matchesPlayed} matches)',
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
                : RatingHistoryChart(events: events),
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

