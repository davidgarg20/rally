import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/core/api_client.dart';
import 'package:rally/core/errors.dart';
import 'package:rally/core/providers.dart';
import 'package:rally/core/result.dart';
import 'package:rally/models/leaderboard.dart';

class LeaderboardApi {
  LeaderboardApi(this._client);
  final ApiClient _client;

  Future<Result<LeaderboardResponse, AppError>> fetch({
    String format = 'S', String gender = 'All', String city = 'BLR',
    int limit = 100,
  }) async {
    try {
      final res = await _client.dio.get('/leaderboard', queryParameters: {
        'format': format, 'gender': gender, 'city': city, 'limit': limit,
      });
      return Result.ok(
        LeaderboardResponse.fromJson(res.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return Result.err(AppError.fromDioException(e));
    } catch (e) {
      return Result.err(AppError.unknown(e));
    }
  }
}

final leaderboardApiProvider = Provider<LeaderboardApi>(
  (ref) => LeaderboardApi(ref.watch(apiClientProvider)),
);
