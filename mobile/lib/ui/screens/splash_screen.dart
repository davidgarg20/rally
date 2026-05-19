import 'package:flutter/material.dart';

import 'package:rally/ui/design/colors.dart';

/// In-Flutter splash. Bridges the moment between the native splash
/// (handled by flutter_native_splash, shown by Android before Flutter
/// boots) and the app's first real screen. Same brand-blue background
/// + the same logo so the handoff is seamless.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RallyColors.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              Image.asset(
                'assets/branding/logo_mono_1024.png',
                width: 140,
                height: 140,
              ),
              const SizedBox(height: 20),
              const Text(
                'RALLY',
                style: TextStyle(
                  color: RallyColors.ink,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'your rating, settled by the court',
                style: TextStyle(
                  color: RallyColors.ink.withValues(alpha: 0.75),
                  fontSize: 13,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(flex: 4),
              // Subtle indeterminate progress — only visible if config
              // fetch takes longer than usual.
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: RallyColors.ink.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
