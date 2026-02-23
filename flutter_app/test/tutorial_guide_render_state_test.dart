import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/tutorial_guide.dart';
import 'package:bored_games/src/services/storage_service.dart';

import 'helpers/hud_test_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mountGuide(
    WidgetTester tester,
    HudTestGame game,
    TutorialGuide guide,
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

    await game.add(guide);
    await tester.pump();
  }

  Future<int> renderAndCountPixels(
    TutorialGuide guide, {
    int width = 1600,
    int height = 900,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    guide.render(canvas);
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

  group('TutorialGuide render/state integration', () {
    setUp(() {
      StorageService.instance.resetForTesting();
    });

    testWidgets('handleTap returns false when no dismiss button is available',
        (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      final guide = TutorialGuide();
      await mountGuide(tester, game, guide);

      final handled = guide.handleTap(Vector2(640, 170));
      expect(handled, isFalse);
    });

    testWidgets('renders guide when active and visible', (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      final guide = TutorialGuide();
      await mountGuide(tester, game, guide);

      guide.update(0.25);
      final pixels = await tester.runAsync(() => renderAndCountPixels(guide));
      expect(pixels, greaterThan(0));
    });

    testWidgets('skip tap hides tutorial after dismiss button is rendered',
        (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      final guide = TutorialGuide();
      await mountGuide(tester, game, guide);

      guide.update(0.25);
      final beforeSkip =
          await tester.runAsync(() => renderAndCountPixels(guide));
      expect(beforeSkip, greaterThan(0));

      // Dismiss button is centered near y ~= size.y * 0.15 + 58.
      final tapHandled = guide.handleTap(Vector2(game.size.x * 0.5, 170));
      expect(tapHandled, isTrue);

      guide.update(0.1);
      final afterSkip =
          await tester.runAsync(() => renderAndCountPixels(guide));
      expect(afterSkip, 0);
    });

    testWidgets('tutorial auto-completes after progressing to final step',
        (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      final guide = TutorialGuide();
      await mountGuide(tester, game, guide);

      guide.update(0.2);
      final initial = await tester.runAsync(() => renderAndCountPixels(guide));
      expect(initial, greaterThan(0));

      guide.onTowerSelected(); // step 0 -> 1
      guide.onTowerPlaced(); // step 1 -> 2
      guide.onWaveStarted(); // step 2 -> 3
      guide.onAbilityUsed(); // step 3 -> 4
      guide.onFocusMode(); // step 4 -> 5

      guide.update(5.0); // below final auto-advance threshold (6.0)
      final preComplete =
          await tester.runAsync(() => renderAndCountPixels(guide));
      expect(preComplete, greaterThan(0));

      guide.update(1.2); // pass final threshold
      final postComplete =
          await tester.runAsync(() => renderAndCountPixels(guide));
      expect(postComplete, 0);
    });

    testWidgets('does not render when HUD is hidden', (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      game.hideHud = true;
      final guide = TutorialGuide();
      await mountGuide(tester, game, guide);

      guide.update(0.3);
      final pixels = await tester.runAsync(() => renderAndCountPixels(guide));
      expect(pixels, 0);
    });
  });
}
