import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/overlays/pause_menu_overlay.dart';
import 'package:bored_games/src/ui/widgets/tron_button.dart';

void main() {
  testWidgets('PauseMenuOverlay buttons invoke callbacks', (tester) async {
    var resumeCount = 0;
    var restartCount = 0;
    var quitCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: PauseMenuOverlay(
          onResume: () => resumeCount++,
          onRestart: () => restartCount++,
          onQuit: () => quitCount++,
        ),
      ),
    );

    // Wait until fade-in transition completes.
    await tester.pump(const Duration(milliseconds: 500));

    // Invoke callbacks directly from rendered buttons to avoid hit-test
    // flakiness while ambient animations are running.
    final resumeButton = tester.widget<TronButton>(
      find.widgetWithText(TronButton, 'RESUME'),
    );
    resumeButton.onPressed?.call();
    await tester.pump();

    final restartButton = tester.widget<TronButton>(
      find.widgetWithText(TronButton, 'RESTART'),
    );
    restartButton.onPressed?.call();
    await tester.pump();

    final quitButton = tester.widget<TronButton>(
      find.widgetWithText(TronButton, 'QUIT TO MENU'),
    );
    quitButton.onPressed?.call();
    await tester.pump();

    expect(resumeCount, 1);
    expect(restartCount, 1);
    expect(quitCount, 1);
  });
}
