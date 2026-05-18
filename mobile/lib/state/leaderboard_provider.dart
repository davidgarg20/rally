import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/api/leaderboard_api.dart';
import 'package:rally/models/leaderboard.dart';

final leaderboardFormatProvider = StateProvider<String>((_) => 'S');
final leaderboardGenderProvider = StateProvider<String>((_) => 'All');

final leaderboardProvider = FutureProvider<LeaderboardResponse>((ref) async {
  final api = ref.watch(leaderboardApiProvider);
  final fmt = ref.watch(leaderboardFormatProvider);
  final gen = ref.watch(leaderboardGenderProvider);
  final res = await api.fetch(format: fmt, gender: gen);
  return res.fold(onOk: (r) => r, onErr: (e) => throw e);
});
