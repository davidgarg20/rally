import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/api/players_api.dart';
import 'package:rally/models/match.dart';

/// "Recent" excludes pending matches because those have their own home
/// section ("Awaiting your confirmation"). Showing the same match in both
/// places double-counts it visually.
final recentMatchesProvider = FutureProvider<List<MatchOut>>((ref) async {
  final api = ref.watch(playersApiProvider);
  final res = await api.myMatches();
  return res.fold(
    onOk: (m) => m
        .where((match) => match.status != MatchStatus.pending)
        .take(10)
        .toList(),
    onErr: (e) => throw e,
  );
});
