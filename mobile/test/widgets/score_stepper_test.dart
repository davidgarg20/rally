import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rally/ui/widgets/score_stepper.dart';

void main() {
  testWidgets('increments and decrements', (tester) async {
    int v = 5;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(builder: (ctx, setState) {
          return ScoreStepper(
            label: 'Team 1', value: v,
            onChanged: (n) => setState(() => v = n),
          );
        }),
      ),
    ));
    expect(find.text('5'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    expect(find.text('6'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    expect(find.text('5'), findsOneWidget);
  });
}
