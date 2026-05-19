import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/auth/auth_controller.dart';
import 'package:rally/core/api_client.dart';
import 'package:rally/core/remote_config.dart';

final tokenProvider = Provider<TokenProvider>((ref) {
  return () async => ref.read(authControllerProvider).valueOrNull?.token;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final tp = ref.watch(tokenProvider);
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return ApiClient(tokenProvider: tp, baseUrl: baseUrl);
});
