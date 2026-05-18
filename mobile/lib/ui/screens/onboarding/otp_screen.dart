import 'package:flutter/material.dart';
class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key, required this.verificationId, required this.phoneE164});
  final String verificationId;
  final String phoneE164;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('OTP $phoneE164 (stub)')));
}
