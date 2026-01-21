import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/epic_neon_button.dart';

void main() {
  testWidgets('EpicNeonButton fires callback when enabled', (tester) async {
    var pressed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: EpicNeonButton(
          text: 'LAUNCH',
          icon: Icons.bolt,
          onPressed: () => pressed++,
        ),
      ),
    );

    await tester.tap(find.text('LAUNCH'));
    await tester.pump();

    expect(pressed, 1);
    expect(find.byIcon(Icons.bolt), findsOneWidget);
  });

  testWidgets('EpicNeonButton ignores taps when disabled', (tester) async {
    var pressed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: EpicNeonButton(
          text: 'LOCKED',
          enabled: false,
          onPressed: () => pressed++,
        ),
      ),
    );

    await tester.tap(find.text('LOCKED'));
    await tester.pump();

    expect(pressed, 0);
  });
}
