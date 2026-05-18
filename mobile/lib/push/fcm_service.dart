import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rally/env.dart';
import 'package:rally/state/pending_matches_provider.dart';
import 'package:rally/state/recent_matches_provider.dart';
import 'package:rally/state/session_provider.dart';

class FcmService {
  FcmService(this.ref);
  final Ref ref;

  Future<void> init() async {
    if (Env.isDev) return;
    await FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.onMessage.listen((msg) {
      final kind = msg.data['kind'];
      if (kind == 'match_submitted') {
        ref.invalidate(pendingMatchesProvider);
      } else if (kind == 'match_validated' || kind == 'match_auto_validated') {
        ref.invalidate(currentPlayerProvider);
        ref.invalidate(pendingMatchesProvider);
        ref.invalidate(recentMatchesProvider);
      }
    });
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService(ref));
