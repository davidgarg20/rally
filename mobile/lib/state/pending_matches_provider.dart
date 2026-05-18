import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/api/players_api.dart';
import 'package:rally/models/match.dart';

final pendingMatchesProvider = FutureProvider<List<MatchOut>>((ref) async {
  final api = ref.watch(playersApiProvider);
  final res = await api.myMatches(status: 'pending');
  return res.fold(onOk: (m) => m, onErr: (e) => throw e);
});
