import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/core/api_client.dart';

/// Overridden in main.dart once auth is wired.
final tokenProvider = Provider<TokenProvider>((ref) => () async => null);

final apiClientProvider = Provider<ApiClient>((ref) {
  final tp = ref.watch(tokenProvider);
  return ApiClient(tokenProvider: tp);
});
