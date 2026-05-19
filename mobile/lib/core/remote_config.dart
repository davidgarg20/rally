import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rally/env.dart';

const _kCachedApiBaseUrl = 'rally.api_base_url.cached';

/// Resolves the API base URL at app startup.
///
/// Order of preference:
/// 1. Fresh fetch from `Env.configUrl` (the GitHub gist).
/// 2. Cached value from a previous successful fetch (SharedPreferences).
/// 3. Compile-time fallback (`Env.apiBaseUrlFallback`).
///
/// The fresh value is always cached on success so a later offline launch
/// uses the latest known good URL.
Future<String> resolveApiBaseUrl() async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getString(_kCachedApiBaseUrl);

  try {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    final res = await dio.get(Env.configUrl);
    final data = res.data is String ? jsonDecode(res.data as String) : res.data;
    final url = (data as Map<String, dynamic>)['api_base_url'] as String?;
    if (url != null && url.isNotEmpty) {
      await prefs.setString(_kCachedApiBaseUrl, url);
      return url;
    }
  } catch (_) {
    // Fall through to cache / fallback.
  }

  return cached ?? Env.apiBaseUrlFallback;
}

/// Riverpod handle to the resolved URL. Other parts of the app should
/// read this rather than `Env.apiBaseUrlFallback` directly.
final apiBaseUrlProvider = StateProvider<String>(
  (_) => Env.apiBaseUrlFallback,
);
