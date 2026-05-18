import 'dart:math';

String devTokenFor(String phoneE164) {
  // Stable uid for a given phone so backend reuses the same Player.
  final hash = phoneE164.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0x7fffffff);
  return 'dev:u-${hash.toRadixString(16)}:$phoneE164';
}

String mockPhone() {
  final r = Random().nextInt(900000000) + 100000000;
  return '+9199${r.toString().padLeft(9, '0').substring(0, 9)}';
}
