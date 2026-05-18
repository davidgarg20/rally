import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rally/models/match.dart';

class MatchTile extends StatelessWidget {
  const MatchTile({super.key, required this.match, required this.onTap});

  final MatchOut match;
  final VoidCallback onTap;

  String _scoreSummary() => match.games
      .map((g) => '${g.team1Points}–${g.team2Points}')
      .join(', ');

  Color _statusColor(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return switch (match.status) {
      MatchStatus.pending => cs.tertiary,
      MatchStatus.validated => cs.primary,
      MatchStatus.disputed => cs.error,
      MatchStatus.expired => cs.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(
          '${match.format == MatchFormat.singles ? 'Singles' : 'Doubles'} · ${_scoreSummary()}',
        ),
        subtitle: Text(DateFormat.yMMMd().add_jm().format(match.playedAt.toLocal())),
        trailing: Chip(
          label: Text(match.status.name),
          backgroundColor: _statusColor(context).withValues(alpha: 0.15),
          side: BorderSide.none,
        ),
      ),
    );
  }
}
