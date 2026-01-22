import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/overlays/game_result_overlay.dart';
import 'package:bored_games/src/ui/widgets/epic_neon_button.dart';

void main() {
  testWidgets('GameResultOverlay shows results and triggers actions', (tester) async {
    var continued = 0;
    var retried = 0;
    var exited = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: GameResultOverlay(
          isVictory: true,
          levelId: 1,
          score: 1234,
          wavesCleared: 4,
          towersBuilt: 3,
          enemiesKilled: 12,
          onContinue: () => continued++,
          onRetry: () => retried++,
          onExit: () => exited++,
        ),
      ),
    );

    final overlayFinder = find.byType(GameResultOverlay);
    final center = tester.getCenter(overlayFinder);

    await tester.tapAt(center);
    await tester.pump();
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.widgetWithText(EpicNeonButton, 'CONTINUAR'), findsOneWidget);
    expect(find.widgetWithText(EpicNeonButton, 'REINTENTAR'), findsOneWidget);

    await tester.tap(find.widgetWithText(EpicNeonButton, 'CONTINUAR'));
    await tester.pump();
    await tester.tap(find.widgetWithText(EpicNeonButton, 'REINTENTAR'));
    await tester.pump();
    await tester.tap(find.byType(TextButton));
    await tester.pump();

    expect(continued, 1);
    expect(retried, 1);
    expect(exited, 1);

    await tester.pump(const Duration(milliseconds: 400));
  });
}
