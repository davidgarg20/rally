import 'package:flutter/material.dart';

/// All colors used in the app. Never hard-code a `Color(0x...)` in a screen —
/// reference one of these or `Theme.of(context).colorScheme.X` instead.
///
/// To rebrand: change the values below and every screen updates automatically.
class RallyColors {
  RallyColors._();

  // ── Brand ───────────────────────────────────────────────────────────────
  // Lime/chartreuse accent — energetic, sporty, paired with cream + ink.
  static const brand = Color(0xFFB8E04A);
  static const brandDark = Color(0xFF9BC832);
  static const brandLight = Color(0xFFE8F5C8);

  // ── Neutrals ────────────────────────────────────────────────────────────
  // Warm cream backgrounds + near-black ink for high contrast type.
  static const ink = Color(0xFF1A1D1F);
  static const inkMuted = Color(0xFF6B7280);
  static const surface = Color(0xFFFBF7EE);
  static const surfaceMuted = Color(0xFFF3EFE4);
  static const divider = Color(0xFFE5E0D2);

  // ── Semantic ────────────────────────────────────────────────────────────
  static const success = Color(0xFF8DBF2F);
  static const danger = Color(0xFFE63946);
  static const warning = Color(0xFFF59E0B);

  // ── Match status pills ──────────────────────────────────────────────────
  static const statusPending = warning;
  static const statusValidated = brand;
  static const statusDisputed = danger;
  static const statusExpired = inkMuted;
}
