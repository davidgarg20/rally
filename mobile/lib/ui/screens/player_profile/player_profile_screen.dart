import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rally/api/players_api.dart';
import 'package:rally/models/match.dart';
import 'package:rally/models/public_player.dart';
import 'package:rally/models/rating_event.dart';
import 'package:rally/state/session_provider.dart';
import 'package:rally/ui/design/colors.dart';
import 'package:rally/ui/design/spacing.dart';
import 'package:rally/ui/design/typography.dart';
import 'package:rally/ui/widgets/async_value_view.dart';
import 'package:rally/ui/widgets/empty_state.dart';
import 'package:rally/ui/widgets/initials_avatar.dart';
import 'package:rally/ui/share/share_cards.dart';
import 'package:rally/ui/share/share_sheet.dart';
import 'package:rally/ui/widgets/match_tile.dart';
import 'package:rally/ui/widgets/rating_history_chart.dart';

final _profileProvider =
    FutureProvider.family<PublicPlayer, String>((ref, username) async {
  final res = await ref.watch(playersApiProvider).publicProfile(username);
  return res.fold(onOk: (p) => p, onErr: (e) => throw e);
});

final _h2hProvider =
    FutureProvider.family<HeadToHead, String>((ref, username) async {
  final res = await ref.watch(playersApiProvider).headToHead(username);
  return res.fold(onOk: (h) => h, onErr: (e) => throw e);
});

final _publicHistoryProvider =
    FutureProvider.family<List<RatingHistoryPoint>, String>((ref, username) async {
  final res = await ref.watch(playersApiProvider).publicRatingHistory(username);
  return res.fold(onOk: (h) => h, onErr: (_) => <RatingHistoryPoint>[]);
});

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key, required this.username});
  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(_profileProvider(username));
    final h2h = ref.watch(_h2hProvider(username));
    final me = ref.watch(currentPlayerProvider).valueOrNull;
    final isMe = me?.username == username;

    return Scaffold(
      appBar: AppBar(
        title: Text('@$username'),
        actions: [
          if (!isMe && me != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share',
              onPressed: () {
                final p = profile.valueOrNull;
                final h = h2h.valueOrNull;
                if (p == null) return;
                final cards = <Widget>[
                  if (h != null && (h.meWins + h.opponentWins) > 0)
                    HeadToHeadCard(
                      me: me,
                      opponent: p,
                      meWins: h.meWins,
                      opponentWins: h.opponentWins,
                    ),
                ];
                if (cards.isEmpty) return;
                ShareCardSheet.show(
                  context,
                  cards: cards,
                  shareText:
                      'Me vs @${p.username} on Rally — ${h!.meWins}-${h.opponentWins} lifetime.',
                );
              },
            ),
        ],
      ),
      body: AsyncValueView(
        value: profile,
        data: (p) => ListView(
          padding: RallyInsets.screen,
          children: [
            Center(child: InitialsAvatar(name: p.displayName, radius: 44)),
            RallySpace.gapMd,
            Center(
              child: Text(p.displayName, style: RallyText.h1),
            ),
            Center(
              child: Text('@${p.username}', style: RallyText.caption),
            ),
            RallySpace.gapLg,

            // Big rating card
            Card(
              child: Padding(
                padding: RallyInsets.cardPaddingLarge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RALLY RATING',
                      style: RallyText.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: RallyColors.brand,
                      ),
                    ),
                    RallySpace.gapXs,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          p.rating.round().toString(),
                          style: RallyText.rating,
                        ),
                        RallySpace.hGapSm,
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            '${p.matchesPlayed} matches'
                            '${p.rank != null ? '  ·  #${p.rank} in ${p.homeCity}' : ''}',
                            style: RallyText.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            RallySpace.gapLg,

            // Rating history chart for this player
            Text('Rating over time', style: RallyText.title),
            RallySpace.gapSm,
            Consumer(builder: (_, r, __) {
              final hist = r.watch(_publicHistoryProvider(username));
              return AsyncValueView(
                value: hist,
                data: (events) => RatingHistoryChart(events: events),
              );
            }),
            RallySpace.gapLg,

            // Head-to-head section (skip if viewing own profile)
            if (!isMe) ...[
              Text('Head to head', style: RallyText.title),
              RallySpace.gapSm,
              AsyncValueView(
                value: h2h,
                data: (h) {
                  final total = h.meWins + h.opponentWins;
                  if (total == 0) {
                    return const EmptyState(
                      title: 'No matches together yet.',
                      subtitle: 'Log a match to start the rivalry.',
                      icon: Icons.sports_tennis_outlined,
                      compact: true,
                    );
                  }
                  return Column(
                    children: [
                      _H2HBar(meWins: h.meWins, opponentWins: h.opponentWins),
                      RallySpace.gapSm,
                      for (final m in h.lastMatches)
                        MatchTile(
                          match: m,
                          myPhone: me?.phoneE164,
                          onTap: () => context.push('/match/${m.id}'),
                        ),
                    ],
                  );
                },
              ),
              RallySpace.gapLg,
              FilledButton.icon(
                onPressed: () => context.push('/log?opponent=$username'),
                icon: const Icon(Icons.add),
                label: Text('Log a match with @${p.username}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _H2HBar extends StatelessWidget {
  const _H2HBar({required this.meWins, required this.opponentWins});
  final int meWins;
  final int opponentWins;

  @override
  Widget build(BuildContext context) {
    final total = meWins + opponentWins;
    final meFrac = total == 0 ? 0.5 : meWins / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '$meWins',
              style: RallyText.title.copyWith(color: RallyColors.success),
            ),
            const Spacer(),
            Text(
              'vs',
              style: RallyText.caption,
            ),
            const Spacer(),
            Text(
              '$opponentWins',
              style: RallyText.title.copyWith(color: RallyColors.danger),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(RallyRadius.pill),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  flex: (meFrac * 1000).round(),
                  child: Container(color: RallyColors.success),
                ),
                Expanded(
                  flex: ((1 - meFrac) * 1000).round(),
                  child: Container(color: RallyColors.danger),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
