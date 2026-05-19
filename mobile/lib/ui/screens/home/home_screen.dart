import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rally/api/matches_api.dart';
import 'package:rally/api/players_api.dart';
import 'package:rally/models/match.dart';
import 'package:rally/models/rating_event.dart';
import 'package:rally/state/pending_matches_provider.dart';
import 'package:rally/state/recent_matches_provider.dart';
import 'package:rally/state/session_provider.dart';
import 'package:rally/ui/design/spacing.dart';
import 'package:rally/ui/design/typography.dart';
import 'package:rally/ui/widgets/async_value_view.dart';
import 'package:rally/ui/widgets/empty_state.dart';
import 'package:rally/ui/widgets/match_tile.dart';
import 'package:rally/ui/widgets/rating_card.dart';
import 'package:rally/ui/widgets/streak_badge.dart';

/// Rating history feeds the 7-day delta chip on the rating card.
final _ratingHistoryProvider = FutureProvider<List<RatingHistoryPoint>>((ref) async {
  final res = await ref.watch(playersApiProvider).ratingHistory(days: 30);
  return res.fold(onOk: (h) => h, onErr: (_) => <RatingHistoryPoint>[]);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final pending = ref.watch(pendingMatchesProvider);
    final recent = ref.watch(recentMatchesProvider);
    final history = ref.watch(_ratingHistoryProvider);

    final myPhone = player.valueOrNull?.phoneE164;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rally'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
            tooltip: 'Profile',
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
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
          ref.invalidate(_ratingHistoryProvider);
          await ref.read(currentPlayerProvider.future);
        },
        child: ListView(
          padding: RallyInsets.screen.copyWith(bottom: 96),
          children: [
            // Greeting
            AsyncValueView(
              value: player,
              data: (p) => p == null
                  ? const EmptyState(title: 'No profile yet')
                  : Padding(
                      padding: const EdgeInsets.only(
                        top: RallySpace.sm,
                        bottom: RallySpace.md,
                      ),
                      child: Text(
                        'Hi, ${p.displayName.split(' ').first}',
                        style: RallyText.h1,
                      ),
                    ),
            ),
            // Hero rating card
            AsyncValueView(
              value: player,
              data: (p) => p == null
                  ? const SizedBox.shrink()
                  : RatingCard(
                      player: p,
                      recentEvents: history.valueOrNull ?? const [],
                    ),
            ),
            // Streak (compact pill aligned right)
            if ((recent.valueOrNull?.isNotEmpty ?? false) && myPhone != null) ...[
              RallySpace.gapSm,
              Align(
                alignment: Alignment.centerLeft,
                child: StreakBadge(matches: recent.value!, myPhone: myPhone),
              ),
            ],
            RallySpace.gapLg,
            _SectionHeader(
              title: 'Awaiting your confirmation',
              trailingCount: pending.valueOrNull?.length,
            ),
            AsyncValueView(
              value: pending,
              data: (list) => list.isEmpty
                  ? const EmptyState(
                      title: 'All caught up.',
                      subtitle: 'No matches need your confirmation right now.',
                      icon: Icons.check_circle_outline,
                      compact: true,
                    )
                  : Column(
                      children: [
                        for (final m in list)
                          _PendingMatchTile(
                            match: m,
                            myPhone: myPhone,
                            myPlayerId: player.valueOrNull?.id,
                          ),
                      ],
                    ),
            ),
            RallySpace.gapLg,
            _SectionHeader(
              title: 'Recent matches',
              trailingCount: recent.valueOrNull?.length,
            ),
            AsyncValueView(
              value: recent,
              data: (list) => list.isEmpty
                  ? const EmptyState(
                      title: 'No matches yet.',
                      subtitle: 'Tap "Log a match" to get your first rating.',
                      icon: Icons.sports_tennis_outlined,
                    )
                  : Column(
                      children: [
                        for (final m in list)
                          MatchTile(
                            match: m,
                            myPhone: myPhone,
                            onTap: () => context.push('/match/${m.id}'),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailingCount});
  final String title;
  final int? trailingCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: RallySpace.xs,
        right: RallySpace.xs,
        bottom: RallySpace.sm,
      ),
      child: Row(
        children: [
          Text(title, style: RallyText.title),
          if (trailingCount != null && trailingCount! > 0) ...[
            RallySpace.hGapSm,
            Text('$trailingCount', style: RallyText.caption),
          ],
        ],
      ),
    );
  }
}


/// Pending tile that asynchronously fetches the rating-delta preview
/// and passes it to MatchTile. Falls back to a plain tile if the preview
/// fails (e.g., no rating data yet).
final _previewProvider =
    FutureProvider.family<List<({String playerId, double before, double after})>,
        String>((ref, matchId) async {
  final res = await ref.watch(matchesApiProvider).preview(matchId);
  return res.fold(onOk: (d) => d, onErr: (_) => const []);
});

class _PendingMatchTile extends ConsumerWidget {
  const _PendingMatchTile({
    required this.match,
    required this.myPhone,
    required this.myPlayerId,
  });

  final MatchOut match;
  final String? myPhone;
  final String? myPlayerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(_previewProvider(match.id));
    double? myDelta;
    final list = preview.valueOrNull;
    if (list != null && myPlayerId != null) {
      for (final p in list) {
        if (p.playerId == myPlayerId) {
          myDelta = p.after - p.before;
          break;
        }
      }
    }
    return MatchTile(
      match: match,
      myPhone: myPhone,
      previewDelta: myDelta,
      onTap: () => context.push('/match/${match.id}'),
    );
  }
}
