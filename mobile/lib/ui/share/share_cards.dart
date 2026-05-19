import 'package:flutter/material.dart';

import 'package:rally/models/match.dart';
import 'package:rally/models/player.dart';
import 'package:rally/models/public_player.dart';
import 'package:rally/ui/design/colors.dart';
import 'package:rally/ui/design/spacing.dart';

/// Common 1080×1080 (logical 360×360) card frame used by all share cards.
/// Brand wordmark bottom-left, username bottom-right.
class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.child, required this.username});

  final Widget child;
  final String username;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 360,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: RallyColors.divider),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 0,
            bottom: 0,
            child: const _Wordmark(),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Text(
              '@$username',
              style: const TextStyle(
                color: RallyColors.inkMuted,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: RallyColors.brand,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'R',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'RALLY',
          style: TextStyle(
            color: RallyColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

/// "Beat @karthik_r 21-15 · +14" style card for a single validated match.
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.match,
    required this.me,
  });

  final MatchOut match;
  final Player me;

  bool? _iWon() {
    if (match.games.isEmpty) return null;
    final g = match.games.first;
    if (g.team1Points == g.team2Points) return null;
    final winnerTeam = g.team1Points > g.team2Points ? 1 : 2;
    int? myTeam;
    for (final p in match.participants) {
      if (p.phoneE164 == me.phoneE164) {
        myTeam = p.team;
        break;
      }
    }
    if (myTeam == null) return null;
    return myTeam == winnerTeam;
  }

  String _scoreText() {
    if (match.games.isEmpty) return '';
    final g = match.games.first;
    final hi = g.team1Points > g.team2Points ? g.team1Points : g.team2Points;
    final lo = g.team1Points > g.team2Points ? g.team2Points : g.team1Points;
    return '$hi–$lo';
  }

  Participant? _opponent() {
    int? myTeam;
    for (final p in match.participants) {
      if (p.phoneE164 == me.phoneE164) {
        myTeam = p.team;
        break;
      }
    }
    if (myTeam == null) return null;
    for (final p in match.participants) {
      if (p.team != myTeam) return p;
    }
    return null;
  }

  double? _myDelta() {
    for (final d in match.ratingDeltas) {
      if (d.playerId == me.id) {
        return d.ratingAfter - d.ratingBefore;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final won = _iWon();
    final delta = _myDelta();
    final opp = _opponent();
    final isSingles = match.format == MatchFormat.singles;

    final headline = switch (won) {
      true => 'WIN',
      false => 'LOSS',
      null => 'MATCH',
    };
    final accent = won == true
        ? RallyColors.success
        : (won == false ? RallyColors.danger : RallyColors.brand);

    final oppLabel = opp?.username != null
        ? '@${opp!.username}'
        : (opp?.displayName ?? 'Opponent');

    return _CardFrame(
      username: me.username,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              headline,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: RallySpace.md),
          Text(
            won == true
                ? 'Beat $oppLabel'
                : won == false
                    ? 'Lost to $oppLabel'
                    : 'Played $oppLabel',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: RallyColors.ink,
            ),
          ),
          const SizedBox(height: RallySpace.lg),
          Text(
            _scoreText(),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 72,
              color: RallyColors.ink,
              height: 1.0,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: RallySpace.sm),
          Text(
            isSingles ? 'Singles' : 'Doubles',
            style: const TextStyle(
              color: RallyColors.inkMuted,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (delta != null && delta != 0)
            Row(
              children: [
                Icon(
                  delta > 0 ? Icons.trending_up : Icons.trending_down,
                  color: accent,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '${delta > 0 ? '+' : ''}${delta.round()} rating',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// "Rally rating 1572 · ↑+24 7d" style card.
class RatingShareCard extends StatelessWidget {
  const RatingShareCard({
    super.key,
    required this.me,
    this.sevenDayDelta,
    this.rankInCity,
  });

  final Player me;
  final double? sevenDayDelta;
  final int? rankInCity;

  @override
  Widget build(BuildContext context) {
    final rating = (me.overall.rating ?? 1500).round();
    final delta = sevenDayDelta;
    return _CardFrame(
      username: me.username,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RALLY RATING',
            style: TextStyle(
              color: RallyColors.brand,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: RallySpace.sm),
          Text(
            me.displayName,
            style: const TextStyle(
              color: RallyColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const Spacer(),
          Text(
            '$rating',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 96,
              color: RallyColors.ink,
              height: 1.0,
              letterSpacing: -3,
            ),
          ),
          const SizedBox(height: RallySpace.sm),
          Row(
            children: [
              if (delta != null && delta != 0) ...[
                Icon(
                  delta > 0 ? Icons.trending_up : Icons.trending_down,
                  color: delta > 0 ? RallyColors.success : RallyColors.danger,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${delta > 0 ? '+' : ''}${delta.round()} this week',
                  style: TextStyle(
                    color: delta > 0 ? RallyColors.success : RallyColors.danger,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                '${me.overall.matchesPlayed} matches'
                '${rankInCity != null ? ' · #$rankInCity in ${me.homeCity}' : ''}',
                style: const TextStyle(
                  color: RallyColors.inkMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

/// "You vs @karthik_r — 3-2" head-to-head card.
class HeadToHeadCard extends StatelessWidget {
  const HeadToHeadCard({
    super.key,
    required this.me,
    required this.opponent,
    required this.meWins,
    required this.opponentWins,
  });

  final Player me;
  final PublicPlayer opponent;
  final int meWins;
  final int opponentWins;

  @override
  Widget build(BuildContext context) {
    final total = meWins + opponentWins;
    final meFrac = total == 0 ? 0.5 : meWins / total;
    return _CardFrame(
      username: me.username,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HEAD TO HEAD',
            style: TextStyle(
              color: RallyColors.brand,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: RallySpace.sm),
          Text(
            '${me.displayName}  vs  ${opponent.displayName}',
            style: const TextStyle(
              color: RallyColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${me.username}',
                      style: const TextStyle(
                        color: RallyColors.inkMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$meWins',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 64,
                        color: RallyColors.success,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'vs',
                style: TextStyle(
                  color: RallyColors.inkMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '@${opponent.username}',
                      style: const TextStyle(
                        color: RallyColors.inkMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$opponentWins',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 64,
                        color: RallyColors.danger,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: RallySpace.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
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
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}
