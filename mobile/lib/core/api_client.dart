import 'package:dio/dio.dart';

import 'package:rally/env.dart';

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  ApiClient({
    Dio? dio,
    required TokenProvider tokenProvider,
    String? baseUrl,
  })  : dio = dio ??
            Dio(BaseOptions(baseUrl: baseUrl ?? Env.apiBaseUrlFallback)),
        _tokenProvider = tokenProvider {
    this.dio.interceptors.insert(
      0,
      InterceptorsWrapper(
        onRequest: (opts, handler) async {
          opts.headers['ngrok-skip-browser-warning'] = '1';
          if (!opts.path.startsWith('/healthz')) {
            final token = await _tokenProvider();
            if (token != null && token.isNotEmpty) {
              opts.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(opts);
        },
      ) as Interceptor,
    );
    this.dio.options.connectTimeout = const Duration(seconds: 8);
    this.dio.options.receiveTimeout = const Duration(seconds: 12);
  }

  final Dio dio;
  final TokenProvider _tokenProvider;
}
