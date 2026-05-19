import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rally/api/players_api.dart';

typedef _Suggestion = ({String id, String username, String displayName});

/// Text field for picking an opponent or teammate.
///
/// As the user types, queries `/players/search` (debounced) and shows
/// matching usernames + display names in a dropdown. Selecting a row
/// inserts the username into the field. Phone numbers can still be typed
/// directly — they don't trigger search.
class OpponentField extends ConsumerStatefulWidget {
  const OpponentField({
    super.key,
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  ConsumerState<OpponentField> createState() => _OpponentFieldState();
}

class _OpponentFieldState extends ConsumerState<OpponentField> {
  Timer? _debounce;
  List<_Suggestion> _suggestions = const [];
  String _lastQueried = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Don't query the backend if the user is clearly typing a phone number.
  bool _looksLikePhone(String s) {
    final cleaned = s.replaceAll(RegExp(r'[+\s\-]'), '');
    return cleaned.length >= 2 && RegExp(r'^\d+$').hasMatch(cleaned);
  }

  Future<void> _fetch(String q) async {
    if (_looksLikePhone(q) || q.trim().length < 1) {
      setState(() => _suggestions = const []);
      return;
    }
    if (q == _lastQueried) return;
    _lastQueried = q;
    final res = await ref.read(playersApiProvider).searchPlayers(q);
    if (!mounted) return;
    res.fold(
      onOk: (list) => setState(() => _suggestions = list),
      onErr: (_) => setState(() => _suggestions = const []),
    );
  }

  void _scheduleFetch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _fetch(q));
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<_Suggestion>(
      // Drive the visible field with the parent's controller so submit can
      // read its value. Autocomplete owns its internal controller; we keep
      // them in sync via the fieldViewBuilder.
      optionsBuilder: (textEditingValue) {
        _scheduleFetch(textEditingValue.text);
        return _suggestions;
      },
      displayStringForOption: (s) => s.username,
      fieldViewBuilder: (ctx, internalCtrl, focusNode, onSubmit) {
        // Bridge the internal controller and the parent's controller in
        // both directions.
        if (internalCtrl.text != widget.controller.text) {
          internalCtrl.value = widget.controller.value;
        }
        internalCtrl.addListener(() {
          if (widget.controller.text != internalCtrl.text) {
            widget.controller.value = internalCtrl.value;
          }
        });
        return TextField(
          controller: internalCtrl,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: '@username or phone',
          ),
        );
      },
      optionsViewBuilder: (ctx, onSelected, options) {
        // Width matches the field. Material elevation makes the overlay a
        // distinct render layer so taps don't bleed into parents.
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.white,
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 240,
                maxWidth: MediaQuery.of(ctx).size.width - 32,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final s = options.elementAt(i);
                  // InkWell + explicit opaque hit-testing so the Stepper
                  // / scrollable parent doesn't steal the tap.
                  return InkWell(
                    onTap: () => onSelected(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              )),
                          const SizedBox(height: 2),
                          Text('@${s.username}',
                              style: const TextStyle(
                                color: Color(0xFF5F6B7A),
                                fontSize: 12,
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
