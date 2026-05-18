import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/api/players_api.dart';
import 'package:rally/models/player.dart';

final currentPlayerProvider = FutureProvider<Player?>((ref) async {
  final api = ref.watch(playersApiProvider);
  final res = await api.me();
  return res.fold(
    onOk: (p) => p,
    onErr: (e) => e.code == 'player_not_found' ? null : throw e,
  );
});
