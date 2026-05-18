import 'package:flutter/material.dart';
import 'package:rally/ui/design/colors.dart';

/// All text styles in one place. Use `RallyText.X` or
/// `Theme.of(context).textTheme.X`. Never hand-roll TextStyle in screens.
class RallyText {
  RallyText._();

  static const String _family = 'Roboto';

  /// 48 / 700 — for the rating number itself on the home card.
  static const TextStyle rating = TextStyle(
    fontFamily: _family,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -1.0,
    color: RallyColors.ink,
  );

  /// 28 / 700 — screen titles.
  static const TextStyle h1 = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: RallyColors.ink,
  );

  /// 22 / 600 — section titles.
  static const TextStyle h2 = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: RallyColors.ink,
  );

  /// 18 / 600 — card titles, button labels.
  static const TextStyle title = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: RallyColors.ink,
  );

  /// 16 / 500 — emphasis body.
  static const TextStyle subtitle = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: RallyColors.ink,
  );

  /// 14 / 400 — body text.
  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: RallyColors.ink,
  );

  /// 13 / 500 — labels, chips.
  static const TextStyle label = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: RallyColors.ink,
  );

  /// 12 / 400 — captions, timestamps, secondary info.
  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: RallyColors.inkMuted,
  );
}
