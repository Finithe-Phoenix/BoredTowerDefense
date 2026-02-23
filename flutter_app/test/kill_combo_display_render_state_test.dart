import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/hud/kill_combo_display.dart';

import 'helpers/hud_test_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mountDisplay(
    WidgetTester tester,
    HudTestGame game,
    KillComboDisplay display,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: game.size.x,
          height: game.size.y,
          child: GameWidget(game: game),
        ),
      ),
    );
    await tester.pump();

    await game.add(display);
    await tester.pump();
  }

  Future<int> renderAndCountPixels(
    KillComboDisplay display, {
    int width = 1600,
    int height = 900,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    display.render(canvas);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) return 0;
    final bytes = data.buffer.asUint8List();
    var nonTransparent = 0;
    for (int i = 3; i < bytes.length; i += 4) {
      if (bytes[i] != 0) nonTransparent++;
    }
    return nonTransparent;
  }

  group('KillComboDisplay state/render integration', () {
    testWidgets('returns milestones only on exact combo thresholds',
        (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      final display = KillComboDisplay();
      await mountDisplay(tester, game, display);

      expect(display.registerKill(), isNull); // 1
      expect(display.registerKill(), isNull); // 2
      expect(display.registerKill(), 3); // 3
      expect(display.registerKill(), isNull); // 4
      expect(display.registerKill(), 5); // 5
      expect(display.registerKill(), isNull); // 6
      expect(display.registerKill(), 7); // 7
      expect(display.registerKill(), isNull); // 8
      expect(display.registerKill(), isNull); // 9
      expect(display.registerKill(), 10); // 10
      expect(display.currentCombo, 10);
    });

    testWidgets('combo timeout resets state and reset clears counters',
        (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      final display = KillComboDisplay();
      await mountDisplay(tester, game, display);

      display.registerKill();
      display.registerKill();
      display.registerKill();
      expect(display.currentCombo, 3);

      display.update(KillComboDisplay.comboTimeout + 0.05);
      expect(display.currentCombo, 0);

      display.registerKill();
      expect(display.currentCombo, 1);
      display.reset();
      expect(display.currentCombo, 0);
    });

    testWidgets('render draws while active and fades out after timers',
        (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      final display = KillComboDisplay();
      await mountDisplay(tester, game, display);

      display.registerKill();
      display.registerKill();
      display.registerKill();
      display.update(0.1);

      final activePixels =
          await tester.runAsync(() => renderAndCountPixels(display));
      expect(activePixels, greaterThan(0));

      display.update(KillComboDisplay.displayDuration + 1.2);
      final fadedPixels =
          await tester.runAsync(() => renderAndCountPixels(display));
      expect(fadedPixels, 0);
    });

    testWidgets('render obeys HUD visibility and focus mode guards',
        (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      final display = KillComboDisplay();
      await mountDisplay(tester, game, display);

      display.registerKill();
      display.registerKill();
      display.registerKill();
      display.update(0.1);

      final visible =
          await tester.runAsync(() => renderAndCountPixels(display));
      expect(visible, greaterThan(0));

      game.hideHud = true;
      final hidden = await tester.runAsync(() => renderAndCountPixels(display));
      expect(hidden, 0);

      game.hideHud = false;
      game.mockFocusModeActive = true;
      final focused =
          await tester.runAsync(() => renderAndCountPixels(display));
      expect(focused, 0);
    });

    testWidgets('single kill hides combo text while double kill shows it',
        (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      final display = KillComboDisplay();
      await mountDisplay(tester, game, display);

      display.registerKill();
      display.update(0.1);
      final singleKillPixels =
          await tester.runAsync(() => renderAndCountPixels(display));
      expect(singleKillPixels, 0);

      display.registerKill();
      display.update(0.1);
      final doubleKillPixels =
          await tester.runAsync(() => renderAndCountPixels(display));
      expect(doubleKillPixels, greaterThan(0));
    });
  });
}
