import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/app.dart';
import 'package:rally/core/firebase_init.dart';
import 'package:rally/core/remote_config.dart';
import 'package:rally/push/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureFirebase();

  // Resolve API URL from the remote config (gist) before the app
  // mounts. This is cheap (~200ms warm) and lets us rotate the backend
  // URL without rebuilding the APK.
  final apiBaseUrl = await resolveApiBaseUrl();

  final container = ProviderContainer(
    overrides: [
      apiBaseUrlProvider.overrideWith((_) => apiBaseUrl),
    ],
  );
  await container.read(fcmServiceProvider).init();
  runApp(UncontrolledProviderScope(
    container: container,
    child: const RallyApp(),
  ));
}
