import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rally/state/pending_matches_provider.dart';
import 'package:rally/state/recent_matches_provider.dart';
import 'package:rally/state/session_provider.dart';
import 'package:rally/ui/widgets/async_value_view.dart';
import 'package:rally/ui/widgets/empty_state.dart';
import 'package:rally/ui/widgets/match_tile.dart';
import 'package:rally/ui/widgets/rating_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final pending = ref.watch(pendingMatchesProvider);
    final recent = ref.watch(recentMatchesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rally')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.leaderboard_outlined), label: 'Leaderboard'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        onDestinationSelected: (i) {
          if (i == 1) context.push('/leaderboard');
          if (i == 2) context.push('/profile');
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/log'),
        icon: const Icon(Icons.add),
        label: const Text('Log a match'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentPlayerProvider);
          ref.invalidate(pendingMatchesProvider);
          ref.invalidate(recentMatchesProvider);
          await ref.read(currentPlayerProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AsyncValueView(
              value: player,
              data: (p) => p == null
                  ? const EmptyState(message: 'No profile yet')
                  : RatingCard(ratings: p.ratings),
            ),
            const SizedBox(height: 16),
            Text('Awaiting your confirmation',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            AsyncValueView(
              value: pending,
              data: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Nothing to confirm.'),
                    )
                  : Column(
                      children: [
                        for (final m in list)
                          MatchTile(match: m, onTap: () => context.push('/match/${m.id}'))
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Text('Recent matches',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            AsyncValueView(
              value: recent,
              data: (list) => list.isEmpty
                  ? const EmptyState(message: 'Log your first match to get started.')
                  : Column(
                      children: [
                        for (final m in list)
                          MatchTile(match: m, onTap: () => context.push('/match/${m.id}'))
                      ],
                    ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
