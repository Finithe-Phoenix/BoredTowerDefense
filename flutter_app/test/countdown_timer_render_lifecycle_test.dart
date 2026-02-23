import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/hud/countdown_timer_component.dart';

import 'helpers/hud_test_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mountTimer(
    WidgetTester tester,
    HudTestGame game,
    CountdownTimerComponent timer,
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

    game.add(timer);
    await tester.pump();
  }

  void renderTimer(CountdownTimerComponent timer) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    timer.render(canvas);
    recorder.endRecording();
  }

  group('CountdownTimerComponent lifecycle', () {
    test('fires completion callback once and supports post-complete recovery', () {
      var completed = 0;
      final timer = CountdownTimerComponent(
        totalDuration: 1.0,
        onComplete: () => completed++,
      );

      timer.start();
      timer.update(0.6);
      expect(timer.isActive, isTrue);
      expect(timer.remainingTime, closeTo(0.4, 0.001));
      expect(completed, 0);

      timer.update(0.6);
      expect(timer.isActive, isFalse);
      expect(timer.remainingTime, 0.0);
      expect(completed, 1);

      timer.resume();
      expect(timer.isActive, isFalse);

      timer.addTime(0.5);
      timer.resume();
      expect(timer.isActive, isTrue);
    });

    test('clamps time mutations and keeps progress/urgency coherent', () {
      final timer = CountdownTimerComponent(totalDuration: 60.0);
      timer.start();

      timer.setTime(100);
      expect(timer.remainingTime, 60.0);
      expect(timer.progress, 0.0);

      timer.setTime(-10);
      expect(timer.remainingTime, 0.0);
      expect(timer.progress, 1.0);
      expect(timer.urgencyLevel, 1.0);

      timer.addTime(12);
      expect(timer.remainingTime, 12.0);
      expect(timer.isWarning, isTrue);
      expect(timer.isCritical, isFalse);

      timer.stop();
      expect(timer.remainingTime, 60.0);
      expect(timer.isActive, isFalse);
    });
  });

  group('CountdownTimerComponent render states', () {
    testWidgets('renders normal, warning, critical, reduced-fx and hidden paths', (
      tester,
    ) async {
      final game = HudTestGame();
      final timer = CountdownTimerComponent(totalDuration: 130.0);
      await mountTimer(tester, game, timer);

      timer.start();

      final samples = <double>[
        125.0,
        95.0,
        61.0,
        59.0,
        42.0,
        30.0,
        20.0,
        10.0,
        9.95,
        5.0,
      ];

      for (final seconds in samples) {
        timer.setTime(seconds);
        timer.update(0.016);
        renderTimer(timer);
      }

      // Keep updating while critical to exercise shake/flash/glitch scheduling.
      for (int i = 0; i < 40; i++) {
        timer.update(0.1);
        renderTimer(timer);
      }

      game.mockReduceFx = true;
      renderTimer(timer);

      game.hideHud = true;
      renderTimer(timer);

      game.hideHud = false;
      game.mockFocusModeActive = true;
      renderTimer(timer);
    });

    testWidgets('renders across all digits for seven-segment mapping', (tester) async {
      final game = HudTestGame();
      final timer = CountdownTimerComponent(totalDuration: 120.0);
      await mountTimer(tester, game, timer);
      timer.start();

      for (int second = 0; second <= 69; second++) {
        timer.setTime(second.toDouble());
        renderTimer(timer);
      }
    });
  });
}
