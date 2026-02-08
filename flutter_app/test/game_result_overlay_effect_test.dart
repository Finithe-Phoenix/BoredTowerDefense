import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/game_result_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameResultType enum', () {
    test('has 2 types', () {
      expect(GameResultType.values.length, 2);
    });

    test('contains victory type', () {
      expect(GameResultType.values, contains(GameResultType.victory));
    });

    test('contains defeat type', () {
      expect(GameResultType.values, contains(GameResultType.defeat));
    });
  });

  group('GameResultOverlay creation', () {
    test('creates with required gameSize', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      expect(overlay, isNotNull);
      expect(overlay, isA<PositionComponent>());
    });

    test('creates with onComplete callback', () {
      var completed = false;
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
        onComplete: () => completed = true,
      );

      expect(overlay, isNotNull);
    });

    test('starts inactive', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      expect(overlay.isActive, isFalse);
    });

    test('progress starts at 0', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      expect(overlay.progress, 0.0);
    });
  });

  group('GameResultOverlay setQuality', () {
    test('sets reduceFx flag', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.setQuality(reduceFx: true, allowBlur: false);
      expect(overlay.reduceFx, isTrue);
    });

    test('sets allowBlur flag', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.setQuality(reduceFx: false, allowBlur: true);
      expect(overlay.allowBlur, isTrue);
    });

    test('sets both flags', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.setQuality(reduceFx: true, allowBlur: true);
      expect(overlay.reduceFx, isTrue);
      expect(overlay.allowBlur, isTrue);
    });

    test('defaults to reduceFx false', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      expect(overlay.reduceFx, isFalse);
    });

    test('defaults to allowBlur true', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      expect(overlay.allowBlur, isTrue);
    });
  });

  group('GameResultOverlay triggerVictory', () {
    test('activates overlay', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory();
      expect(overlay.isActive, isTrue);
    });

    test('accepts score parameter', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory(score: 1000);
      expect(overlay.isActive, isTrue);
    });

    test('accepts wavesCompleted parameter', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory(wavesCompleted: 10);
      expect(overlay.isActive, isTrue);
    });

    test('accepts enemiesKilled parameter', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory(enemiesKilled: 50);
      expect(overlay.isActive, isTrue);
    });

    test('accepts towersBuilt parameter', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory(towersBuilt: 5);
      expect(overlay.isActive, isTrue);
    });

    test('accepts all stats parameters', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory(
        score: 5000,
        wavesCompleted: 15,
        enemiesKilled: 100,
        towersBuilt: 8,
      );
      expect(overlay.isActive, isTrue);
    });

    test('resets progress to 0', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory();
      expect(overlay.progress, 0.0);
    });
  });

  group('GameResultOverlay triggerDefeat', () {
    test('activates overlay', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerDefeat();
      expect(overlay.isActive, isTrue);
    });

    test('accepts score parameter', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerDefeat(score: 500);
      expect(overlay.isActive, isTrue);
    });

    test('accepts wavesCompleted parameter', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerDefeat(wavesCompleted: 5);
      expect(overlay.isActive, isTrue);
    });

    test('accepts enemiesKilled parameter', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerDefeat(enemiesKilled: 30);
      expect(overlay.isActive, isTrue);
    });

    test('accepts towersBuilt parameter', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerDefeat(towersBuilt: 3);
      expect(overlay.isActive, isTrue);
    });

    test('accepts all stats parameters', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerDefeat(
        score: 2000,
        wavesCompleted: 8,
        enemiesKilled: 60,
        towersBuilt: 4,
      );
      expect(overlay.isActive, isTrue);
    });

    test('resets progress to 0', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerDefeat();
      expect(overlay.progress, 0.0);
    });
  });

  group('GameResultOverlay hide', () {
    test('deactivates overlay', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory();
      expect(overlay.isActive, isTrue);

      overlay.hide();
      expect(overlay.isActive, isFalse);
    });

    test('can be called when already inactive', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.hide();
      expect(overlay.isActive, isFalse);
    });

    test('can be called multiple times', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory();
      overlay.hide();
      overlay.hide();
      overlay.hide();
      expect(overlay.isActive, isFalse);
    });
  });

  group('GameResultOverlay update', () {
    test('update does nothing when inactive', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.update(0.1);
      expect(overlay.progress, 0.0);
    });

    test('update advances progress when active', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory();
      overlay.update(0.5);

      expect(overlay.progress, greaterThan(0.0));
    });

    test('progress is clamped to 1.0', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory();
      overlay.update(10.0);

      expect(overlay.progress, lessThanOrEqualTo(1.0));
    });

    test('multiple updates work', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory();
      for (int i = 0; i < 100; i++) {
        overlay.update(0.016);
      }

      expect(overlay.progress, greaterThan(0.0));
    });

    test('update with zero dt does not advance', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory();
      final progressBefore = overlay.progress;
      overlay.update(0.0);

      expect(overlay.progress, progressBefore);
    });
  });

  group('GameResultOverlay onComplete callback', () {
    test('callback is called after animation completes', () {
      var completed = false;
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
        onComplete: () => completed = true,
      );

      overlay.triggerVictory();

      // Update enough to complete animation (2.0 + 1.0 seconds)
      for (int i = 0; i < 300; i++) {
        overlay.update(0.016);
      }

      expect(completed, isTrue);
    });

    test('callback is not called before animation completes', () {
      var completed = false;
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
        onComplete: () => completed = true,
      );

      overlay.triggerVictory();
      overlay.update(0.5);

      expect(completed, isFalse);
    });
  });

  group('GameResultOverlay render', () {
    test('renders without exceptions when inactive', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      overlay.render(canvas);
      recorder.endRecording();
    });

    test('renders victory without exceptions', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory();
      overlay.update(0.5);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      overlay.render(canvas);
      recorder.endRecording();
    });

    test('renders defeat without exceptions', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerDefeat();
      overlay.update(0.5);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      overlay.render(canvas);
      recorder.endRecording();
    });

    test('renders with reduceFx enabled', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.setQuality(reduceFx: true, allowBlur: true);
      overlay.triggerVictory();
      overlay.update(0.5);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      overlay.render(canvas);
      recorder.endRecording();
    });

    test('renders with allowBlur disabled', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.setQuality(reduceFx: false, allowBlur: false);
      overlay.triggerVictory();
      overlay.update(0.5);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      overlay.render(canvas);
      recorder.endRecording();
    });

    test('renders at different progress values', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory();

      final progressValues = [0.1, 0.3, 0.5, 0.7, 0.9, 1.0];
      for (final progress in progressValues) {
        while (overlay.progress < progress) {
          overlay.update(0.016);
        }

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        overlay.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with stats at later progress', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory(
        score: 1000,
        wavesCompleted: 10,
        enemiesKilled: 50,
        towersBuilt: 5,
      );

      // Update to show stats (after 0.4 progress)
      for (int i = 0; i < 60; i++) {
        overlay.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      overlay.render(canvas);
      recorder.endRecording();
    });
  });

  group('GameResultOverlay animation layers', () {
    test('renders background layer', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory();
      overlay.update(0.3);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      overlay.render(canvas);
      recorder.endRecording();
    });

    test('renders holographic text layer', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory();
      overlay.update(0.5);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      overlay.render(canvas);
      recorder.endRecording();
    });

    test('renders particle layer', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory();
      overlay.update(0.4);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      overlay.render(canvas);
      recorder.endRecording();
    });

    test('renders border layer', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory();
      overlay.update(0.3);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      overlay.render(canvas);
      recorder.endRecording();
    });

    test('renders stats layer', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory();
      // Stats appear after 0.4 progress
      for (int i = 0; i < 80; i++) {
        overlay.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      overlay.render(canvas);
      recorder.endRecording();
    });

    test('renders energy waves layer', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.setQuality(reduceFx: false, allowBlur: true);
      overlay.triggerVictory();
      // Energy waves appear after 0.3 progress
      for (int i = 0; i < 40; i++) {
        overlay.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      overlay.render(canvas);
      recorder.endRecording();
    });

    test('renders glitch overlay layer', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.setQuality(reduceFx: false, allowBlur: true);
      overlay.triggerVictory();
      // Glitch overlay after 0.2 progress
      for (int i = 0; i < 30; i++) {
        overlay.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      overlay.render(canvas);
      recorder.endRecording();
    });
  });

  group('GameResultOverlay edge cases', () {
    test('handles small game size', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(100, 100),
      );

      overlay.triggerVictory();
      overlay.update(0.5);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      overlay.render(canvas);
      recorder.endRecording();
    });

    test('handles large game size', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(3840, 2160),
      );

      overlay.triggerVictory();
      overlay.update(0.5);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      overlay.render(canvas);
      recorder.endRecording();
    });

    test('handles very high stats values', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory(
        score: 9999999,
        wavesCompleted: 999,
        enemiesKilled: 9999,
        towersBuilt: 999,
      );
      overlay.update(1.0);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      overlay.render(canvas);
      recorder.endRecording();
    });

    test('handles zero stats values', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerDefeat(
        score: 0,
        wavesCompleted: 0,
        enemiesKilled: 0,
        towersBuilt: 0,
      );
      overlay.update(1.0);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      overlay.render(canvas);
      recorder.endRecording();
    });

    test('switching from victory to defeat works', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory();
      overlay.update(0.3);
      overlay.hide();

      overlay.triggerDefeat();
      overlay.update(0.3);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      overlay.render(canvas);
      recorder.endRecording();
    });

    test('switching from defeat to victory works', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerDefeat();
      overlay.update(0.3);
      overlay.hide();

      overlay.triggerVictory();
      overlay.update(0.3);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      overlay.render(canvas);
      recorder.endRecording();
    });
  });

  group('GameResultOverlay multiple instances', () {
    test('multiple overlays can exist independently', () {
      final overlay1 = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      final overlay2 = GameResultOverlay(
        gameSize: Vector2(1920, 1080),
      );

      overlay1.triggerVictory();
      overlay2.triggerDefeat();

      overlay1.update(0.3);
      overlay2.update(0.5);

      expect(overlay1.isActive, isTrue);
      expect(overlay2.isActive, isTrue);
    });

    test('overlays have independent state', () {
      final overlay1 = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      final overlay2 = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay1.triggerVictory();
      overlay1.update(0.5);

      overlay2.triggerVictory();

      expect(overlay1.progress, greaterThan(overlay2.progress));
    });
  });

  group('GameResultOverlay static paints', () {
    test('static paints are reused across instances', () {
      final overlay1 = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      final overlay2 = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay1.triggerVictory();
      overlay2.triggerDefeat();

      overlay1.update(0.5);
      overlay2.update(0.5);

      final recorder1 = ui.PictureRecorder();
      final canvas1 = ui.Canvas(recorder1);
      overlay1.render(canvas1);
      recorder1.endRecording();

      final recorder2 = ui.PictureRecorder();
      final canvas2 = ui.Canvas(recorder2);
      overlay2.render(canvas2);
      recorder2.endRecording();
    });
  });

  group('GameResultOverlay complete animation cycle', () {
    test('renders complete victory animation', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerVictory(
        score: 5000,
        wavesCompleted: 10,
        enemiesKilled: 100,
        towersBuilt: 8,
      );

      // Run through complete animation
      for (int i = 0; i < 200; i++) {
        overlay.update(0.016);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        overlay.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders complete defeat animation', () {
      final overlay = GameResultOverlay(
        gameSize: Vector2(800, 600),
      );

      overlay.triggerDefeat(
        score: 2000,
        wavesCompleted: 5,
        enemiesKilled: 40,
        towersBuilt: 3,
      );

      // Run through complete animation
      for (int i = 0; i < 200; i++) {
        overlay.update(0.016);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        overlay.render(canvas);
        recorder.endRecording();
      }
    });
  });
}
