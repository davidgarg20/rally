import 'package:flutter/material.dart';
class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({super.key, required this.matchId});
  final String matchId;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Match $matchId (stub)')));
}
