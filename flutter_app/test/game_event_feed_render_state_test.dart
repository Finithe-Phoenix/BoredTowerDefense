import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/hud/game_event_feed.dart';

import 'helpers/hud_test_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mountFeed(
    WidgetTester tester,
    HudTestGame game,
    GameEventFeed feed,
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

    await game.add(feed);
    await tester.pump();
  }

  Future<int> renderAndCountPixels(
    GameEventFeed feed, {
    int width = 640,
    int height = 360,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    feed.render(canvas);
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

  group('GameEventFeed render/state integration', () {
    testWidgets('renders visible pixels when active events exist',
        (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      final feed = GameEventFeed();
      await mountFeed(tester, game, feed);

      feed.waveStarted(2);
      feed.update(0.16);
      final pixels = await tester.runAsync(() => renderAndCountPixels(feed));
      expect(pixels, greaterThan(0));
    });

    testWidgets('respects hide HUD and focus mode guards', (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      final feed = GameEventFeed();
      await mountFeed(tester, game, feed);

      feed.waveStarted(1);
      feed.update(0.16);
      final visible = await tester.runAsync(() => renderAndCountPixels(feed));
      expect(visible, greaterThan(0));

      game.hideHud = true;
      final hidden = await tester.runAsync(() => renderAndCountPixels(feed));
      expect(hidden, 0);

      game.hideHud = false;
      game.mockFocusModeActive = true;
      final focused = await tester.runAsync(() => renderAndCountPixels(feed));
      expect(focused, 0);
    });

    testWidgets('expires events after duration during update', (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      final feed = GameEventFeed();
      await mountFeed(tester, game, feed);

      feed.waveStarted(3);
      feed.update(0.16);
      final activePixels =
          await tester.runAsync(() => renderAndCountPixels(feed));
      expect(activePixels, greaterThan(0));

      feed.update(GameEventFeed.eventDuration + 0.2);
      final expiredPixels =
          await tester.runAsync(() => renderAndCountPixels(feed));
      expect(expiredPixels, 0);
    });

    testWidgets('gold threshold and timer warning behaviors are enforced',
        (tester) async {
      final game = HudTestGame(mockSize: Vector2(1280, 720));
      final feed = GameEventFeed();
      await mountFeed(tester, game, feed);

      feed.goldEarned(40);
      final lowGoldPixels =
          await tester.runAsync(() => renderAndCountPixels(feed));
      expect(lowGoldPixels, 0);

      feed.goldEarned(50);
      feed.update(0.16);
      final highGoldPixels =
          await tester.runAsync(() => renderAndCountPixels(feed));
      expect(highGoldPixels, greaterThan(0));

      feed.update(GameEventFeed.eventDuration + 0.2);
      feed.timerExpired();
      feed.update(0.16);
      final timerPixels =
          await tester.runAsync(() => renderAndCountPixels(feed));
      expect(timerPixels, greaterThan(0));
    });

    testWidgets('all event types render without regressions', (tester) async {
      final game = HudTestGame(mockSize: Vector2(1366, 768));
      final feed = GameEventFeed();
      await mountFeed(tester, game, feed);

      final triggers = <void Function()>[
        () => feed.waveStarted(1),
        () => feed.waveComplete(1),
        () => feed.bossSpawned('THE CORE'),
        () => feed.bossDefeated('THE CORE'),
        () => feed.towerBuilt('ION SNIPER'),
        () => feed.abilityUsed('PULSE'),
        () => feed.goldEarned(80),
        () => feed.lowHealth(),
        () => feed.addEvent(GameEventType.info, 'SYSTEM ONLINE'),
      ];

      for (final trigger in triggers) {
        feed.update(GameEventFeed.eventDuration + 0.5);
        trigger();
        feed.update(0.16);
        final pixels = await tester.runAsync(() => renderAndCountPixels(feed));
        expect(pixels, greaterThan(0));
      }
    });
  });
}
