import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rally/state/leaderboard_provider.dart';
import 'package:rally/ui/widgets/async_value_view.dart';
import 'package:rally/ui/widgets/empty_state.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(leaderboardFormatProvider);
    final gen = ref.watch(leaderboardGenderProvider);
    final data = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bangalore leaderboard'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'S', label: Text('Singles')),
                    ButtonSegment(value: 'D', label: Text('Doubles')),
                  ],
                  selected: {fmt},
                  onSelectionChanged: (v) =>
                      ref.read(leaderboardFormatProvider.notifier).state = v.first,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All')),
                    ButtonSegment(value: 'M', label: Text('Men')),
                    ButtonSegment(value: 'F', label: Text('Women')),
                  ],
                  selected: {gen},
                  onSelectionChanged: (v) =>
                      ref.read(leaderboardGenderProvider.notifier).state = v.first,
                ),
              ],
            ),
          ),
        ),
      ),
      body: AsyncValueView(
        value: data,
        data: (r) => r.entries.isEmpty
            ? const EmptyState(
                message: 'Not enough players with 5+ matches yet. Be the first.',
                icon: Icons.timer_outlined,
              )
            : ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: r.entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final e = r.entries[i];
                  return ListTile(
                    leading: SizedBox(
                      width: 32,
                      child: Text('#${e.rank}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    title: Text(e.displayName),
                    subtitle: Text('${e.matchesPlayed} matches'),
                    trailing: Text(e.rating.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.titleMedium),
                  );
                },
              ),
      ),
    );
  }
}
