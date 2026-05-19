import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Editable score row: label on the left, +/- buttons, and a typeable
/// number field in the middle. Lets users either tap +/- or type directly.
class ScoreStepper extends StatefulWidget {
  const ScoreStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.max = 99,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int max;

  @override
  State<ScoreStepper> createState() => _ScoreStepperState();
}

class _ScoreStepperState extends State<ScoreStepper> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant ScoreStepper old) {
    super.didUpdateWidget(old);
    // Sync external changes (from +/- buttons) into the field.
    if (widget.value.toString() != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value.toString(),
        selection: TextSelection.collapsed(offset: widget.value.toString().length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit(String raw) {
    final n = int.tryParse(raw);
    if (n == null || n < 0) {
      // Reset display to current value.
      _controller.text = widget.value.toString();
      return;
    }
    final clamped = n > widget.max ? widget.max : n;
    if (clamped != widget.value) widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(widget.label)),
        IconButton(
          onPressed: widget.value > 0 ? () => widget.onChanged(widget.value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 56,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            ),
            onSubmitted: _commit,
            onEditingComplete: () => _commit(_controller.text),
            onTapOutside: (_) => _commit(_controller.text),
          ),
        ),
        IconButton(
          onPressed: widget.value < widget.max
              ? () => widget.onChanged(widget.value + 1)
              : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
