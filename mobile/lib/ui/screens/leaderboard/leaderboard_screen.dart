import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rally/state/leaderboard_provider.dart';
import 'package:rally/state/session_provider.dart';
import 'package:rally/ui/design/colors.dart';
import 'package:rally/ui/design/spacing.dart';
import 'package:rally/ui/design/typography.dart';
import 'package:rally/ui/widgets/async_value_view.dart';
import 'package:rally/ui/widgets/empty_state.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gen = ref.watch(leaderboardGenderProvider);
    final data = ref.watch(leaderboardProvider);
    final me = ref.watch(currentPlayerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(leaderboardProvider),
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: RallySpace.md,
              vertical: RallySpace.xs,
            ),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'All', label: Text('All')),
                ButtonSegment(value: 'M', label: Text('Men')),
                ButtonSegment(value: 'F', label: Text('Women')),
              ],
              selected: {gen},
              onSelectionChanged: (v) {
                ref.read(leaderboardGenderProvider.notifier).state = v.first;
              },
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(leaderboardProvider);
          await ref.read(leaderboardProvider.future);
        },
        child: AsyncValueView(
          value: data,
          data: (r) => r.entries.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 80),
                    EmptyState(
                      title: 'Not enough players yet.',
                      subtitle: 'Players need 5 confirmed matches to appear.',
                      icon: Icons.hourglass_empty,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RallySpace.sm,
                    vertical: RallySpace.sm,
                  ),
                  itemCount: r.entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = r.entries[i];
                    final isMe = me?.id == e.playerId;
                    return Container(
                      color: isMe ? RallyColors.brandLight : null,
                      child: ListTile(
                        leading: SizedBox(
                          width: 36,
                          child: Text(
                            '#${e.rank}',
                            style: RallyText.label.copyWith(
                              color: e.rank <= 3
                                  ? RallyColors.brand
                                  : RallyColors.inkMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          e.displayName,
                          style: RallyText.subtitle.copyWith(
                            fontWeight:
                                isMe ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '@${e.username} · ${e.matchesPlayed} matches',
                          style: RallyText.caption,
                        ),
                        trailing: Text(
                          e.rating.round().toString(),
                          style: RallyText.title.copyWith(
                            color: RallyColors.brand,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
