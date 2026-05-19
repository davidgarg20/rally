import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:rally/models/player.dart' as player_model;
import 'package:rally/ui/share/share_cards.dart';
import 'package:rally/ui/share/share_sheet.dart';

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
      appBar: AppBar(
        title: const Text('Match'),
        actions: [
          match.when(
            data: (m) {
              if (m.status != MatchStatus.validated) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share',
                onPressed: () => _shareMatch(context, m, me),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
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
                    onTap: p.username == null
                        ? null
                        : () => context.push('/u/${p.username}'),
                    leading: CircleAvatar(child: Text('${p.team}')),
                    title: Text(p.displayName ?? '(invited) ${p.phoneE164}'),
                    subtitle: Text([
                      if (p.username != null) '@${p.username}',
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


/// Build a one-line share string about this match and trigger the OS share
/// sheet. Tries to lead with whether the current user won.
Future<void> _shareMatch(BuildContext context, MatchOut m, player_model.Player? me) async {
  String? formatPart() =>
      m.format == MatchFormat.singles ? 'singles' : 'doubles';

  // Score
  String? scoreText() {
    if (m.games.isEmpty) return null;
    final g = m.games.first;
    final hi = g.team1Points > g.team2Points ? g.team1Points : g.team2Points;
    final lo = g.team1Points > g.team2Points ? g.team2Points : g.team1Points;
    return '$hi–$lo';
  }

  // Did the current user win?
  int? myTeam;
  if (me != null) {
    for (final p in m.participants) {
      if (p.phoneE164 == me.phoneE164) {
        myTeam = p.team;
        break;
      }
    }
  }
  int? winningTeam;
  if (m.games.isNotEmpty) {
    final g = m.games.first;
    if (g.team1Points != g.team2Points) {
      winningTeam = g.team1Points > g.team2Points ? 1 : 2;
    }
  }
  final iWon = (myTeam != null && winningTeam != null) ? myTeam == winningTeam : null;

  // My rating delta
  double? myDelta;
  if (me != null) {
    for (final d in m.ratingDeltas) {
      if (d.playerId == me.id) {
        myDelta = d.ratingAfter - d.ratingBefore;
        break;
      }
    }
  }

  // Opponent username (best effort: first participant not on my team with a username)
  String? oppHandle;
  if (myTeam != null) {
    for (final p in m.participants) {
      if (p.team != myTeam && p.username != null) {
        oppHandle = '@${p.username}';
        break;
      }
    }
  }

  final lead = switch (iWon) {
    true => 'Beat',
    false => 'Lost to',
    null => 'Played',
  };
  final scorePart = scoreText() == null ? '' : ' ${scoreText()}';
  final oppPart = oppHandle == null ? '' : ' $oppHandle';
  final deltaPart = myDelta == null || myDelta == 0
      ? ''
      : ' (${myDelta > 0 ? '+' : ''}${myDelta.round()})';
  final ratingPart = me?.overall.rating == null
      ? ''
      : ' · Rally rating ${me!.overall.rating!.round()}';

  final text = '$lead$oppPart$scorePart in ${formatPart()}$deltaPart$ratingPart on Rally.';

  if (me == null) {
    // No identity loaded yet — fall back to text-only share.
    await Share.share(text);
    return;
  }
  await ShareCardSheet.show(
    context,
    cards: [
      ResultCard(match: m, me: me),
      RatingShareCard(me: me),
    ],
    shareText: text,
  );
}
