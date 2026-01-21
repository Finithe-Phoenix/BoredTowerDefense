import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/overlays/pause_menu_overlay.dart';

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

    await tester.tap(find.text('RESUME'));
    await tester.pump();
    await tester.tap(find.text('RESTART'));
    await tester.pump();
    await tester.tap(find.text('QUIT TO MENU'));
    await tester.pump();

    expect(resumeCount, 1);
    expect(restartCount, 1);
    expect(quitCount, 1);
  });
}
