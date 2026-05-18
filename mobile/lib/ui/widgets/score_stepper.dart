import 'package:flutter/material.dart';

class ScoreStepper extends StatelessWidget {
  const ScoreStepper({
    super.key, required this.label, required this.value, required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label)),
        IconButton(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 36, child: Center(child: Text('$value',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
        ),
        IconButton(
          onPressed: value < 30 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
