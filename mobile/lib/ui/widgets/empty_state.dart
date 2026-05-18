import 'package:flutter/material.dart';
import 'package:rally/ui/design/colors.dart';
import 'package:rally/ui/design/spacing.dart';
import 'package:rally/ui/design/typography.dart';

/// A friendlier empty state. Use it whenever a list could be empty.
///
/// Old call sites that use `message:` continue to work — `message` is an
/// alias for `title`.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    String? title,
    String? message,
    this.subtitle,
    this.icon,
    this.compact = false,
  })  : assert(title != null || message != null,
            'Provide either title or message'),
        title = title ?? message ?? '';

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// When true, renders inline without the big icon — good for cards inside
  /// a scrolling list where you don't want a 200px tall section.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RallySpace.md,
          vertical: RallySpace.md,
        ),
        child: Row(
          children: [
            Icon(
              icon ?? Icons.check_circle_outline,
              color: RallyColors.inkMuted,
              size: 20,
            ),
            RallySpace.hGapSm,
            Expanded(
              child: Text(
                title,
                style: RallyText.body.copyWith(color: RallyColors.inkMuted),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: RallySpace.lg,
        vertical: RallySpace.xl,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: RallyColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? Icons.inbox_outlined,
              size: 28,
              color: RallyColors.inkMuted,
            ),
          ),
          RallySpace.gapMd,
          Text(title, style: RallyText.subtitle, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            RallySpace.gapXs,
            Text(
              subtitle!,
              style: RallyText.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
