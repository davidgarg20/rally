import 'package:flutter/material.dart';

/// All colors used in the app. Never hard-code a `Color(0x...)` in a screen —
/// reference one of these or `Theme.of(context).colorScheme.X` instead.
///
/// To rebrand: change the values below and every screen updates automatically.
class RallyColors {
  RallyColors._();

  // ── Brand ───────────────────────────────────────────────────────────────
  static const brand = Color(0xFF1E88E5);
  static const brandDark = Color(0xFF1565C0);
  static const brandLight = Color(0xFFE3F2FD);

  // ── Neutrals ────────────────────────────────────────────────────────────
  static const ink = Color(0xFF111418);
  static const inkMuted = Color(0xFF5F6B7A);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF6F8FA);
  static const divider = Color(0xFFE3E6EB);

  // ── Semantic ────────────────────────────────────────────────────────────
  static const success = Color(0xFF14B870);
  static const danger = Color(0xFFE63946);
  static const warning = Color(0xFFF59E0B);

  // ── Match status pills ──────────────────────────────────────────────────
  static const statusPending = warning;
  static const statusValidated = brand;
  static const statusDisputed = danger;
  static const statusExpired = inkMuted;
}
