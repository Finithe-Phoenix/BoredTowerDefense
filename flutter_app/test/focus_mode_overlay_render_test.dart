import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/focus_mode_overlay.dart';

import 'helpers/hud_test_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mountOverlay(
    WidgetTester tester,
    HudTestGame game,
    FocusModeOverlay overlay,
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

    await game.add(overlay);
    await tester.pump();
  }

  Future<int> renderAndCountPixels(
    FocusModeOverlay overlay, {
    int width = 1600,
    int height = 900,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    overlay.render(canvas);
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

  group('FocusModeOverlay render integration', () {
    testWidgets('does not render when focus mode is inactive', (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      game.mockFocusModeActive = false;
      final overlay = FocusModeOverlay();
      await mountOverlay(tester, game, overlay);

      overlay.update(0.1);
      final pixels = await tester.runAsync(() => renderAndCountPixels(overlay));
      expect(pixels, 0);
    });

    testWidgets('renders visible overlay when focus mode is active',
        (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      game.mockFocusModeActive = true;
      final overlay = FocusModeOverlay();
      await mountOverlay(tester, game, overlay);

      overlay.update(0.1);
      final pixels = await tester.runAsync(() => renderAndCountPixels(overlay));
      expect(pixels, greaterThan(0));
    });

    testWidgets('renders in reduced FX mode and supports hit markers',
        (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      game.mockFocusModeActive = true;
      game.mockReduceFx = true;
      final overlay = FocusModeOverlay();
      await mountOverlay(tester, game, overlay);

      overlay.registerHit(Vector2(300, 260), critical: false);
      overlay.registerHit(Vector2(360, 260), critical: true);
      overlay.update(0.08);

      final withMarkers =
          await tester.runAsync(() => renderAndCountPixels(overlay));
      expect(withMarkers, greaterThan(0));

      // Let markers expire and ensure overlay keeps rendering without crashes.
      overlay.update(1.0);
      final afterExpire =
          await tester.runAsync(() => renderAndCountPixels(overlay));
      expect(afterExpire, greaterThan(0));
    });

    testWidgets('zero-sized game viewport skips rendering', (tester) async {
      final game = HudTestGame(mockSize: Vector2.zero());
      game.mockFocusModeActive = true;
      final overlay = FocusModeOverlay();
      await mountOverlay(tester, game, overlay);

      overlay.update(0.1);
      final pixels = await tester.runAsync(() => renderAndCountPixels(overlay));
      expect(pixels, 0);
    });
  });
}
