import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/overlays/briefing_overlay.dart';

void main() {
  testWidgets('BriefingOverlay renders fallback text and dismisses', (tester) async {
    var dismissed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: BriefingOverlay(
          levelId: 999,
          onDismiss: () => dismissed++,
        ),
      ),
    );

    await tester.pump();

    // First tap skips the typewriter effect.
    await tester.tap(find.byType(BriefingOverlay));
    await tester.pump();

    expect(find.textContaining('ESTADO DEL SISTEMA'), findsOneWidget);

    await tester.tap(find.text('EJECUTAR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(dismissed, 1);
    expect(find.textContaining('ESTADO DEL SISTEMA'), findsNothing);
  });
}
