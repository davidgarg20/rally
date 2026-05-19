import 'package:flutter/material.dart';

/// Circular avatar showing initials (1–2 chars) on a deterministic color
/// derived from the display name. Stand-in for profile photos.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.radius = 24,
  });

  final String name;
  final double radius;

  static const _palette = <Color>[
    Color(0xFF1E88E5),
    Color(0xFF14B870),
    Color(0xFFE63946),
    Color(0xFFF59E0B),
    Color(0xFF8E44AD),
    Color(0xFF16A085),
    Color(0xFFE76F51),
    Color(0xFF457B9D),
  ];

  String _initials() {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color _colorFor(String s) {
    int h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return _palette[h % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        _initials(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
