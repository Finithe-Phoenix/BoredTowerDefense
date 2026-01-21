import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/materialization_overlay.dart';

void main() {
  testWidgets('MaterializationOverlay completes and hides', (tester) async {
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MaterializationOverlay(
          onComplete: () => completed = true,
        ),
      ),
    );

    expect(find.text('INITIALIZING SYSTEM'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2300));

    expect(completed, isTrue);
    expect(find.text('INITIALIZING SYSTEM'), findsNothing);
  });
}
