import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rally/auth/auth_controller.dart';
import 'package:rally/state/session_provider.dart';
import 'package:rally/ui/screens/home/home_screen.dart';
import 'package:rally/ui/screens/leaderboard/leaderboard_screen.dart';
import 'package:rally/ui/screens/log_match/log_match_screen.dart';
import 'package:rally/ui/screens/match_detail/match_detail_screen.dart';
import 'package:rally/ui/screens/onboarding/otp_screen.dart';
import 'package:rally/ui/screens/onboarding/phone_screen.dart';
import 'package:rally/ui/screens/onboarding/profile_screen.dart';
import 'package:rally/ui/screens/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding/phone',
    redirect: (ctx, state) {
      final auth = ref.read(authControllerProvider).valueOrNull;
      final loggingIn = state.matchedLocation.startsWith('/onboarding');

      if (auth == null) return loggingIn ? null : '/onboarding/phone';

      // Authed. Check if profile exists.
      final player = ref.read(currentPlayerProvider).valueOrNull;
      if (player == null && state.matchedLocation != '/onboarding/profile') {
        // Avoid bouncing if we haven't tried yet.
        if (!ref.read(currentPlayerProvider).hasValue) return null;
        return '/onboarding/profile';
      }
      if (player != null && loggingIn) return '/home';
      return null;
    },
    refreshListenable: GoRouterRefreshNotifier(ref),
    routes: [
      GoRoute(path: '/onboarding/phone', builder: (_, __) => const PhoneScreen()),
      GoRoute(path: '/onboarding/otp', builder: (_, s) {
        final args = s.extra as Map<String, String>;
        return OtpScreen(
          verificationId: args['verificationId']!,
          phoneE164: args['phone']!,
        );
      }),
      GoRoute(path: '/onboarding/profile', builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/log', builder: (_, __) => const LogMatchScreen()),
      GoRoute(path: '/match/:id', builder: (_, s) =>
          MatchDetailScreen(matchId: s.pathParameters['id']!)),
      GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
    ref.listen(currentPlayerProvider, (_, __) => notifyListeners());
  }
}
