import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/overlays/game_over_overlay.dart';
import 'package:bored_games/src/ui/widgets/neon_button.dart';

void main() {
  testWidgets('GameOverOverlay buttons invoke callbacks', (tester) async {
    var restarted = 0;
    var quit = 0;

    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: GameOverOverlay(
          score: 1200,
          wavesCleared: 6,
          onRestart: () => restarted++,
          onQuit: () => quit++,
        ),
      ),
    );

    expect(find.text('GAME OVER'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 1500));

    await tester.tap(find.widgetWithText(NeonButton, 'REINICIAR SISTEMA'));
    await tester.pump();
    await tester.tap(find.widgetWithText(NeonButton, 'ABORTAR MISION'));
    await tester.pump();

    expect(restarted, 1);
    expect(quit, 1);
  });
}
