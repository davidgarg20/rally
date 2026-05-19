import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/core/api_client.dart';
import 'package:rally/core/errors.dart';
import 'package:rally/core/providers.dart';
import 'package:rally/core/result.dart';
import 'package:rally/models/match.dart';

class MatchesApi {
  MatchesApi(this._client);
  final ApiClient _client;

  Future<Result<MatchOut, AppError>> submit(MatchSubmit body) => _wrap(() async {
        final res = await _client.dio.post('/matches', data: {
          'format': body.format == MatchFormat.singles ? 'S' : 'D',
          'played_at': body.playedAt.toIso8601String(),
          if (body.venue != null) 'venue': body.venue,
          'team1_phones': body.team1Phones,
          'team2_phones': body.team2Phones,
          'games': body.games
              .map((g) => {
                    'game_no': g.gameNo,
                    'team1_points': g.team1Points,
                    'team2_points': g.team2Points,
                  })
              .toList(),
        });
        return MatchOut.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Result<MatchOut, AppError>> get(String id) => _wrap(() async {
        final res = await _client.dio.get('/matches/$id');
        return MatchOut.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Result<MatchOut, AppError>> confirm(String id) => _wrap(() async {
        final res = await _client.dio.post('/matches/$id/confirm');
        return MatchOut.fromJson(res.data as Map<String, dynamic>);
      });

  /// Returns predicted rating delta per player if this match is confirmed.
  Future<Result<List<({String playerId, double before, double after})>, AppError>>
      preview(String id) => _wrap(() async {
        final res = await _client.dio.get('/matches/$id/preview');
        final raw = (res.data as Map)['rating_deltas'] as List;
        return raw
            .map((e) => (
                  playerId: e['player_id'] as String,
                  before: (e['rating_before'] as num).toDouble(),
                  after: (e['rating_after'] as num).toDouble(),
                ))
            .toList();
      });

  Future<Result<T, AppError>> _wrap<T>(Future<T> Function() fn) async {
    try {
      return Result.ok(await fn());
    } on DioException catch (e) {
      return Result.err(AppError.fromDioException(e));
    } catch (e) {
      return Result.err(AppError.unknown(e));
    }
  }
}

final matchesApiProvider = Provider<MatchesApi>(
  (ref) => MatchesApi(ref.watch(apiClientProvider)),
);
