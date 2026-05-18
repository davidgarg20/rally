import 'package:dio/dio.dart';

class AppError implements Exception {
  AppError({
    required this.code,
    required this.message,
    required this.httpStatus,
  });

  final String code;
  final String message;
  final int httpStatus;

  factory AppError.network() => AppError(
        code: 'network',
        message: 'No network connection.',
        httpStatus: 0,
      );

  factory AppError.unknown(Object e) => AppError(
        code: 'unknown',
        message: e.toString(),
        httpStatus: 0,
      );

  factory AppError.fromDioException(DioException e) {
    final res = e.response;
    if (res == null) {
      return AppError.network();
    }
    final data = res.data;
    if (data is Map && data['code'] is String && data['message'] is String) {
      return AppError(
        code: data['code'] as String,
        message: data['message'] as String,
        httpStatus: res.statusCode ?? 0,
      );
    }
    return AppError(
      code: 'http_${res.statusCode ?? 0}',
      message: res.statusMessage ?? 'Request failed',
      httpStatus: res.statusCode ?? 0,
    );
  }

  @override
  String toString() => 'AppError($code, $httpStatus): $message';
}
