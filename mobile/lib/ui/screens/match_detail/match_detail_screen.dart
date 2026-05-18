import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:rally/api/matches_api.dart';
import 'package:rally/models/match.dart';
import 'package:rally/state/leaderboard_provider.dart';
import 'package:rally/state/pending_matches_provider.dart';
import 'package:rally/state/recent_matches_provider.dart';
import 'package:rally/state/session_provider.dart';
import 'package:rally/ui/widgets/async_value_view.dart';

final _matchProvider = FutureProvider.family<MatchOut, String>((ref, id) async {
  final res = await ref.watch(matchesApiProvider).get(id);
  return res.fold(onOk: (m) => m, onErr: (e) => throw e);
});

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(_matchProvider(matchId));
    final me = ref.watch(currentPlayerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Match')),
      body: AsyncValueView(
        value: match,
        data: (m) => _MatchView(match: m, myPhone: me?.phoneE164, refresh: () {
          ref.invalidate(_matchProvider(matchId));
          ref.invalidate(pendingMatchesProvider);
          ref.invalidate(recentMatchesProvider);
          ref.invalidate(currentPlayerProvider);
          ref.invalidate(leaderboardProvider);
        }),
      ),
    );
  }
}

class _MatchView extends ConsumerStatefulWidget {
  const _MatchView({required this.match, required this.myPhone, required this.refresh});
  final MatchOut match;
  final String? myPhone;
  final VoidCallback refresh;
  @override
  ConsumerState<_MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends ConsumerState<_MatchView> {
  bool _busy = false;
  String? _error;

  bool get _isMine => widget.match.participants.any(
        (p) => p.phoneE164 == widget.myPhone,
      );

  bool get _amSubmitter => widget.match.participants
      .firstWhere(
        (p) => p.phoneE164 == widget.myPhone,
        orElse: () => const Participant(
          phoneE164: '', team: 0, isSubmitter: false, confirmed: false, disputed: false,
        ),
      )
      .isSubmitter;

  Future<void> _do(Future<dynamic> Function() action) async {
    setState(() { _busy = true; _error = null; });
    try {
      await action();
      widget.refresh();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${m.format == MatchFormat.singles ? 'Singles' : 'Doubles'} · ${m.status.name}',
                  style: theme.textTheme.titleMedium,
                ),
                Text(DateFormat.yMMMd().add_jm().format(m.playedAt.toLocal())),
                if (m.venue != null) Text('At ${m.venue!}'),
                const SizedBox(height: 12),
                for (final g in m.games)
                  Text('Game ${g.gameNo}: ${g.team1Points} – ${g.team2Points}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Players', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final p in m.participants)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('${p.team}')),
                    title: Text(p.displayName ?? '(invited) ${p.phoneE164}'),
                    subtitle: Text([
                      if (p.isSubmitter) 'submitter',
                      if (p.confirmed) 'confirmed',
                      if (p.disputed) 'disputed',
                    ].join(' · ')),
                    trailing: _DeltaText(playerId: p.playerId, deltas: m.ratingDeltas),
                  ),
              ],
            ),
          ),
        ),
        if (_isMine && m.status == MatchStatus.pending && !_amSubmitter) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () =>
                    _do(() => ref.read(matchesApiProvider).confirm(m.id)),
                child: const Text('Confirm'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () =>
                    _do(() => ref.read(matchesApiProvider).dispute(m.id)),
                child: const Text('Dispute'),
              ),
            ),
          ]),
        ] else if (_isMine && m.status == MatchStatus.validated) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : () =>
                _do(() => ref.read(matchesApiProvider).dispute(m.id)),
            child: const Text('Dispute (within 7 days)'),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ],
    );
  }
}

class _DeltaText extends StatelessWidget {
  const _DeltaText({required this.playerId, required this.deltas});
  final String? playerId;
  final List<RatingDelta> deltas;

  @override
  Widget build(BuildContext context) {
    if (playerId == null) return const SizedBox.shrink();
    final d = deltas.where((e) => e.playerId == playerId).firstOrNull;
    if (d == null) return const SizedBox.shrink();
    final delta = d.ratingAfter - d.ratingBefore;
    final sign = delta >= 0 ? '+' : '';
    final color = delta >= 0
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.error;
    return Text('$sign${delta.round()}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600));
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
