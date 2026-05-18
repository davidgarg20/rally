// test/api/api_client_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rally/core/api_client.dart';

void main() {
  test('injects bearer token on authed requests', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
    final captured = <String, String>{};
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opts, handler) {
        captured['authz'] = opts.headers['Authorization'] as String? ?? '';
        captured['path'] = opts.path;
        return handler.reject(
          DioException(requestOptions: opts, type: DioExceptionType.cancel),
        );
      },
    ));
    final client = ApiClient(dio: dio, tokenProvider: () async => 'tok-123');

    try { await client.dio.get('/players/me'); } on DioException {}
    expect(captured['authz'], 'Bearer tok-123');
  });

  test('skips token for healthz', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
    String? capturedAuth;
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opts, handler) {
        capturedAuth = opts.headers['Authorization'] as String?;
        return handler.reject(
          DioException(requestOptions: opts, type: DioExceptionType.cancel),
        );
      },
    ));
    final client = ApiClient(dio: dio, tokenProvider: () async => 'tok');
    try { await client.dio.get('/healthz'); } on DioException {}
    expect(capturedAuth, isNull);
  });
}
