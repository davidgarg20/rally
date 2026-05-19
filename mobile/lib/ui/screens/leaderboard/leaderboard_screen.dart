import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rally/state/leaderboard_provider.dart';
import 'package:rally/state/session_provider.dart';
import 'package:rally/ui/design/colors.dart';
import 'package:rally/ui/design/spacing.dart';
import 'package:rally/ui/design/typography.dart';
import 'package:rally/ui/widgets/async_value_view.dart';
import 'package:rally/ui/widgets/empty_state.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          preferredSize: const Size.fromHeight(116),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: RallySpace.md,
              vertical: RallySpace.xs,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search by name or @username',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _search.clear(),
                          ),
                  ),
                ),
                RallySpace.gapSm,
                SegmentedButton<String>(
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
              ],
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
          data: (r) {
            final filtered = _query.isEmpty
                ? r.entries
                : r.entries
                    .where((e) =>
                        e.username.toLowerCase().contains(_query) ||
                        e.displayName.toLowerCase().contains(_query))
                    .toList();
            if (filtered.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  EmptyState(
                    title: r.entries.isEmpty
                        ? 'Not enough players yet.'
                        : 'No players match "$_query".',
                    subtitle: r.entries.isEmpty
                        ? 'Players need 5 confirmed matches to appear.'
                        : null,
                    icon: r.entries.isEmpty
                        ? Icons.hourglass_empty
                        : Icons.search_off,
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: RallySpace.sm,
                vertical: RallySpace.sm,
              ),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = filtered[i];
                final isMe = me?.id == e.playerId;
                return Container(
                  color: isMe ? RallyColors.brandLight : null,
                  child: ListTile(
                    onTap: () => context.push('/u/${e.username}'),
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
            );
          },
        ),
      ),
    );
  }
}
