import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rally/auth/auth_repository.dart';

const _kTokenKey = 'rally.token';
const _kUidKey = 'rally.uid';
const _kPhoneKey = 'rally.phone';

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

class AuthController extends AsyncNotifier<AuthSession?> {
  late SharedPreferences _prefs;
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthSession?> build() async {
    _prefs = await SharedPreferences.getInstance();
    final t = _prefs.getString(_kTokenKey);
    final u = _prefs.getString(_kUidKey);
    final p = _prefs.getString(_kPhoneKey);
    if (t == null || u == null || p == null) return null;
    return AuthSession(uid: u, phoneE164: p, token: t);
  }

  Future<String> sendOtp(String phone) => _repo.sendOtp(phone);

  Future<void> verifyOtp({
    required String verificationId,
    required String otp,
    required String phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final s = await _repo.verifyOtp(
        verificationId: verificationId,
        otpCode: otp,
        phoneE164: phone,
      );
      await _prefs.setString(_kTokenKey, s.token);
      await _prefs.setString(_kUidKey, s.uid);
      await _prefs.setString(_kPhoneKey, s.phoneE164);
      return s;
    });
  }

  Future<void> signOut() async {
    await _repo.signOut();
    await _prefs.remove(_kTokenKey);
    await _prefs.remove(_kUidKey);
    await _prefs.remove(_kPhoneKey);
    state = const AsyncData(null);
  }

  String? get tokenSync => state.valueOrNull?.token;
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);
