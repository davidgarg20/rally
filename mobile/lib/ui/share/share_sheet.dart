import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import 'package:rally/ui/design/colors.dart';
import 'package:rally/ui/design/spacing.dart';
import 'package:rally/ui/share/capture.dart';

/// Bottom-sheet picker that shows a horizontal pager of share cards
/// (each wrapped in a RepaintBoundary). User swipes to choose; Share
/// button captures the visible card as PNG and opens the OS share sheet.
class ShareCardSheet extends StatefulWidget {
  const ShareCardSheet({
    super.key,
    required this.cards,
    required this.shareText,
  });

  /// Each card widget. The widget must be a square, finite-size shareable
  /// (e.g. ResultCard, RatingShareCard) — it will be wrapped in a
  /// RepaintBoundary by the sheet.
  final List<Widget> cards;

  /// Caption / link to attach with the image when sharing.
  final String shareText;

  static Future<void> show(
    BuildContext context, {
    required List<Widget> cards,
    required String shareText,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareCardSheet(cards: cards, shareText: shareText),
    );
  }

  @override
  State<ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<ShareCardSheet> {
  final _pageController = PageController(viewportFraction: 0.85);
  late final List<GlobalKey> _keys =
      List.generate(widget.cards.length, (_) => GlobalKey());
  int _page = 0;
  bool _sharing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final file = await captureWidgetAsPng(_keys[_page]);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.shareText,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: RallyColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: RallyColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Share',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),

          // Pager of cards
          SizedBox(
            height: 380,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.cards.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                return Center(
                  child: RepaintBoundary(
                    key: _keys[i],
                    child: widget.cards[i],
                  ),
                );
              },
            ),
          ),

          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.cards.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? RallyColors.brand : RallyColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Share button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: RallySpace.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sharing ? null : _share,
                icon: _sharing
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share),
                label: const Text('Share this card'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
