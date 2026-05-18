import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rally/auth/auth_controller.dart';
import 'package:rally/env.dart';
import 'package:rally/state/session_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.verificationId, required this.phoneE164});
  final String verificationId;
  final String phoneE164;
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  bool _verifying = false;
  String? _error;

  Future<void> _verify() async {
    final otp = _controller.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() { _verifying = true; _error = null; });
    try {
      await ref.read(authControllerProvider.notifier).verifyOtp(
        verificationId: widget.verificationId,
        otp: otp, phone: widget.phoneE164,
      );
      // Force-refresh the player fetch; router redirect routes us to
      // /home if a profile exists, or /onboarding/profile if not.
      ref.invalidate(currentPlayerProvider);
      await ref.read(currentPlayerProvider.future);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Verify ${widget.phoneE164}',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(Env.isDev
                ? 'Dev mode: enter 123456'
                : 'Enter the 6-digit code we sent over SMS.'),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'OTP',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _verifying ? null : _verify,
              child: _verifying
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
