import 'package:flutter/widgets.dart';

/// All spacing values used in the app. Never hard-code `padding: EdgeInsets.all(16)` —
/// use `RallySpace.md` or `RallyInsets.md` instead.
class RallySpace {
  RallySpace._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Vertical gaps you can drop into a Column.
  static const Widget gapXs = SizedBox(height: xs);
  static const Widget gapSm = SizedBox(height: sm);
  static const Widget gapMd = SizedBox(height: md);
  static const Widget gapLg = SizedBox(height: lg);
  static const Widget gapXl = SizedBox(height: xl);

  // Horizontal gaps for Rows.
  static const Widget hGapXs = SizedBox(width: xs);
  static const Widget hGapSm = SizedBox(width: sm);
  static const Widget hGapMd = SizedBox(width: md);
  static const Widget hGapLg = SizedBox(width: lg);
}

/// Pre-baked `EdgeInsets` for common cases.
class RallyInsets {
  RallyInsets._();

  static const sm = EdgeInsets.all(RallySpace.sm);
  static const md = EdgeInsets.all(RallySpace.md);
  static const lg = EdgeInsets.all(RallySpace.lg);

  static const screenH = EdgeInsets.symmetric(horizontal: RallySpace.md);
  static const screen = EdgeInsets.all(RallySpace.md);
  static const screenLarge = EdgeInsets.all(RallySpace.lg);

  static const cardPadding = EdgeInsets.all(RallySpace.md);
  static const cardPaddingLarge = EdgeInsets.all(RallySpace.lg);
}

/// Corner radii — keep visual rhythm consistent across cards, buttons, chips.
class RallyRadius {
  RallyRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}
