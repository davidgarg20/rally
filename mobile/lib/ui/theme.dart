import 'package:flutter/material.dart';
import 'package:rally/ui/design/colors.dart';
import 'package:rally/ui/design/spacing.dart';
import 'package:rally/ui/design/typography.dart';

/// Assembles the Material theme from design tokens.
/// Tokens live in `lib/ui/design/` — change them there, not here.
class RallyTheme {
  RallyTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: RallyColors.brand,
      brightness: Brightness.light,
      primary: RallyColors.brand,
      surface: RallyColors.surface,
      surfaceContainerHighest: RallyColors.surfaceMuted,
      onSurface: RallyColors.ink,
      onSurfaceVariant: RallyColors.inkMuted,
      error: RallyColors.danger,
      tertiary: RallyColors.success,
      outlineVariant: RallyColors.divider,
    );

    final textTheme = const TextTheme(
      displayLarge: RallyText.rating,
      headlineLarge: RallyText.h1,
      headlineMedium: RallyText.h2,
      titleLarge: RallyText.title,
      titleMedium: RallyText.subtitle,
      bodyLarge: RallyText.body,
      bodyMedium: RallyText.body,
      labelLarge: RallyText.label,
      bodySmall: RallyText.caption,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: RallyColors.surface,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: RallyColors.surface,
        foregroundColor: RallyColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: RallyText.title,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: RallySpace.xs),
        color: RallyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RallyRadius.lg),
          side: const BorderSide(color: RallyColors.divider),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: RallySpace.lg,
            vertical: RallySpace.md,
          ),
          textStyle: RallyText.subtitle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RallyRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: RallySpace.lg,
            vertical: RallySpace.md,
          ),
          textStyle: RallyText.subtitle,
          side: const BorderSide(color: RallyColors.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RallyRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: RallySpace.md,
            vertical: RallySpace.sm,
          ),
          textStyle: RallyText.subtitle,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RallyColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RallySpace.md,
          vertical: RallySpace.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RallyRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RallyRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RallyRadius.md),
          borderSide: const BorderSide(color: RallyColors.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RallyRadius.md),
          borderSide: const BorderSide(color: RallyColors.danger, width: 1.5),
        ),
        labelStyle: const TextStyle(color: RallyColors.inkMuted),
        hintStyle: const TextStyle(color: RallyColors.inkMuted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: RallyColors.surfaceMuted,
        labelStyle: RallyText.label,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: RallySpace.sm,
          vertical: RallySpace.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RallyRadius.pill),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: RallyColors.divider,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: RallyColors.surface,
        elevation: 0,
        height: 64,
        indicatorColor: RallyColors.brandLight,
        labelTextStyle: WidgetStatePropertyAll(RallyText.caption),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: RallyColors.brand,
        foregroundColor: RallyColors.surface,
        elevation: 1,
      ),
    );
  }
}
