import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/core/api_client.dart';
import 'package:rally/core/errors.dart';
import 'package:rally/core/providers.dart';
import 'package:rally/core/result.dart';
import 'package:rally/models/match.dart';
import 'package:rally/models/player.dart';
import 'package:rally/models/rating_event.dart';

class PlayersApi {
  PlayersApi(this._client);
  final ApiClient _client;

  Future<Result<Player, AppError>> create({
    required String username,
    required String displayName, String? gender, DateTime? dob,
    String homeCity = 'BLR',
  }) => _wrap(() async {
        final res = await _client.dio.post('/players', data: {
          'username': username,
          'display_name': displayName,
          if (gender != null) 'gender': gender,
          if (dob != null) 'dob': dob.toIso8601String().substring(0, 10),
          'home_city': homeCity,
        });
        return Player.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Result<List<({String id, String username, String displayName})>, AppError>>
      searchPlayers(String query) => _wrap(() async {
        final res = await _client.dio.get(
          '/players/search',
          queryParameters: {'q': query, 'limit': 10},
        );
        return (res.data as List)
            .map((e) => (
                  id: e['id'] as String,
                  username: e['username'] as String,
                  displayName: e['display_name'] as String,
                ))
            .toList();
      });

  Future<Result<({bool available, String? reason}), AppError>> checkUsername(
    String username,
  ) => _wrap(() async {
        final res = await _client.dio.get(
          '/players/check-username',
          queryParameters: {'u': username},
        );
        final data = res.data as Map<String, dynamic>;
        return (
          available: data['available'] as bool,
          reason: data['reason'] as String?,
        );
      });

  Future<Result<Player, AppError>> me() => _wrap(() async {
        final res = await _client.dio.get('/players/me');
        return Player.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Result<Player, AppError>> patchMe({
    String? displayName, String? gender, DateTime? dob, String? homeCity,
  }) => _wrap(() async {
        final res = await _client.dio.patch('/players/me', data: {
          if (displayName != null) 'display_name': displayName,
          if (gender != null) 'gender': gender,
          if (dob != null) 'dob': dob.toIso8601String().substring(0, 10),
          if (homeCity != null) 'home_city': homeCity,
        });
        return Player.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Result<List<MatchOut>, AppError>> myMatches({String? status}) =>
      _wrap(() async {
        final res = await _client.dio.get(
          '/players/me/matches',
          queryParameters: {if (status != null) 'status': status},
        );
        return (res.data as List)
            .map((e) => MatchOut.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<Result<List<RatingHistoryPoint>, AppError>> ratingHistory({int days = 90}) =>
      _wrap(() async {
        final res = await _client.dio.get(
          '/players/me/rating-history',
          queryParameters: {'days': days},
        );
        return (res.data as List)
            .map((e) => RatingHistoryPoint.fromJson(e as Map<String, dynamic>))
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

final playersApiProvider = Provider<PlayersApi>(
  (ref) => PlayersApi(ref.watch(apiClientProvider)),
);
