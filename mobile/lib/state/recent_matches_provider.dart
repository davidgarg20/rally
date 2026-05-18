import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/api/players_api.dart';
import 'package:rally/models/match.dart';

final recentMatchesProvider = FutureProvider<List<MatchOut>>((ref) async {
  final api = ref.watch(playersApiProvider);
  final res = await api.myMatches();
  return res.fold(
    onOk: (m) => m.take(10).toList(),
    onErr: (e) => throw e,
  );
});
