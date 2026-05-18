import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:rally/auth/dev_token.dart';
import 'package:rally/env.dart';

class AuthSession {
  AuthSession({required this.uid, required this.phoneE164, required this.token});
  final String uid;
  final String phoneE164;
  final String token;
}

class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _authOverride = auth;
  final FirebaseAuth? _authOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  /// Returns a verificationId. In dev, the verificationId is the phone itself.
  Future<String> sendOtp(String phoneE164) async {
    if (Env.isDev) return phoneE164;

    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      verificationCompleted: (_) {},
      verificationFailed: (e) => completer.completeError(e),
      codeSent: (verificationId, _) => completer.complete(verificationId),
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      timeout: const Duration(seconds: 60),
    );
    return completer.future;
  }

  /// Returns an `AuthSession` containing a backend-usable token.
  Future<AuthSession> verifyOtp({
    required String verificationId,
    required String otpCode,
    required String phoneE164,
  }) async {
    if (Env.isDev) {
      if (otpCode != '123456') throw Exception('Invalid dev OTP');
      final token = devTokenFor(phoneE164);
      // uid format: dev:u-<hex>:<phone> → uid = "u-<hex>"
      final uid = token.split(':')[1];
      return AuthSession(uid: uid, phoneE164: phoneE164, token: token);
    }

    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otpCode,
    );
    final result = await _auth.signInWithCredential(cred);
    final user = result.user!;
    final token = await user.getIdToken();
    return AuthSession(
      uid: user.uid,
      phoneE164: user.phoneNumber ?? phoneE164,
      token: token ?? '',
    );
  }

  Future<String?> currentToken() async {
    if (Env.isDev) return null; // dev token comes from controller cache
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  Future<void> signOut() async {
    if (!Env.isDev) await _auth.signOut();
  }
}
