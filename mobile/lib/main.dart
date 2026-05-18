import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rally/app.dart';
import 'package:rally/core/firebase_init.dart';
import 'package:rally/push/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureFirebase();
  final container = ProviderContainer();
  await container.read(fcmServiceProvider).init();
  runApp(UncontrolledProviderScope(
    container: container,
    child: const RallyApp(),
  ));
}
