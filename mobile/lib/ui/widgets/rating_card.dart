import 'package:flutter/material.dart';
import 'package:rally/models/player.dart';

class RatingCard extends StatelessWidget {
  const RatingCard({super.key, required this.ratings, this.sparklineS, this.sparklineD});

  final List<PlayerRating> ratings;
  final List<double>? sparklineS;
  final List<double>? sparklineD;

  PlayerRating? _ratingFor(RatingFormat fmt) =>
      ratings.where((r) => r.format == fmt).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final s = _ratingFor(RatingFormat.singles);
    final d = _ratingFor(RatingFormat.doubles);
    final theme = Theme.of(context);

    Widget cell(String label, PlayerRating? r) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                r == null ? '—' : r.rating.toStringAsFixed(2),
                style: theme.textTheme.displayLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              Text('${r?.matchesPlayed ?? 0} matches',
                  style: theme.textTheme.bodySmall),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [cell('Singles', s), cell('Doubles', d)],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
