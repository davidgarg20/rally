import 'package:firebase_core/firebase_core.dart';
import 'package:rally/env.dart';

Future<void> ensureFirebase() async {
  if (Env.isDev) return; // skip in dev; we use dev_token
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}
