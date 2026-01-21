import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/overlays/victory_overlay.dart';
import 'package:bored_games/src/ui/widgets/neon_button.dart';

void main() {
  testWidgets('VictoryOverlay buttons invoke callbacks', (tester) async {
    var next = 0;
    var restart = 0;
    var quit = 0;

    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: VictoryOverlay(
          score: 2400,
          livesRemaining: 3,
          maxLives: 3,
          onNextLevel: () => next++,
          onRestart: () => restart++,
          onQuit: () => quit++,
        ),
      ),
    );

    expect(find.text('VICTORY'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 1000));

    await tester.tap(find.widgetWithText(NeonButton, 'NEXT LEVEL'));
    await tester.pump();
    await tester.tap(find.widgetWithText(NeonButton, 'PLAY AGAIN'));
    await tester.pump();
    await tester.tap(find.widgetWithText(NeonButton, 'QUIT TO MENU'));
    await tester.pump();

    expect(next, 1);
    expect(restart, 1);
    expect(quit, 1);
  });
}
