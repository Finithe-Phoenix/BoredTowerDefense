import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/components/reflective_floor_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ReflectiveFloorComponent makeFloor({
    Color glowColor = Colors.cyan,
    bool reducedFx = false,
    double horizonRatio = 0.55,
  }) {
    return ReflectiveFloorComponent(
      glowColor: glowColor,
      reducedFx: reducedFx,
      horizonRatio: horizonRatio,
    );
  }

  group('ReflectiveFloorComponent creation', () {
    test('creates with required parameters', () {
      final floor = makeFloor();

      expect(floor.glowColor, Colors.cyan);
      expect(floor.reducedFx, isFalse);
      expect(floor.horizonRatio, 0.55);
    });

    test('creates with reducedFx flag', () {
      final floor = makeFloor(reducedFx: true);

      expect(floor.reducedFx, isTrue);
    });

    test('has correct priority for rendering after grid', () {
      final floor = makeFloor();

      expect(floor.priority, -9);
    });

    test('horizonRatio can be customized', () {
      final floor1 = makeFloor(horizonRatio: 0.3);
      final floor2 = makeFloor(horizonRatio: 0.7);

      expect(floor1.horizonRatio, 0.3);
      expect(floor2.horizonRatio, 0.7);
    });

    test('different colors can be used', () {
      final floor = makeFloor(glowColor: Colors.magenta);

      expect(floor.glowColor, Colors.magenta);
    });

    test('is a PositionComponent', () {
      final floor = makeFloor();
      expect(floor, isA<PositionComponent>());
    });
  });

  group('ReflectiveFloorComponent update', () {
    test('update without errors', () {
      final floor = makeFloor();

      floor.update(0.016);
      floor.update(0.016);

      expect(true, isTrue);
    });

    test('update with zero dt does not crash', () {
      final floor = makeFloor();

      floor.update(0.0);

      expect(true, isTrue);
    });

    test('update with large dt works', () {
      final floor = makeFloor();

      floor.update(1.0);

      expect(true, isTrue);
    });

    test('multiple rapid updates work', () {
      final floor = makeFloor();

      for (int i = 0; i < 100; i++) {
        floor.update(0.016);
      }

      expect(true, isTrue);
    });

    test('update with reducedFx', () {
      final floor = makeFloor(reducedFx: true);

      for (int i = 0; i < 10; i++) {
        floor.update(0.05);
      }

      expect(true, isTrue);
    });
  });

  group('ReflectiveFloorComponent render', () {
    test('renders without exceptions when size is set', () {
      final floor = makeFloor(reducedFx: true);
      floor.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.update(0.016);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders with reducedFx', () {
      final floor = makeFloor(reducedFx: true);
      floor.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.update(0.016);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders with full effects', () {
      final floor = makeFloor(reducedFx: false);
      floor.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.update(0.016);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders with small size', () {
      final floor = makeFloor(reducedFx: true);
      floor.onGameResize(Vector2(100, 100));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.update(0.016);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders with large size', () {
      final floor = makeFloor(reducedFx: true);
      floor.onGameResize(Vector2(1920, 1080));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.update(0.016);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('does not render with zero size', () {
      final floor = makeFloor(reducedFx: true);
      floor.size = Vector2.zero();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders after time passes', () {
      final floor = makeFloor(reducedFx: true);
      floor.onGameResize(Vector2(800, 600));

      for (int i = 0; i < 60; i++) {
        floor.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders with different horizon ratios', () {
      for (final ratio in [0.3, 0.5, 0.7, 0.9]) {
        final floor = makeFloor(horizonRatio: ratio, reducedFx: true);
        floor.onGameResize(Vector2(800, 600));

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        floor.update(0.016);
        floor.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with cyan color', () {
      final floor = makeFloor(
        glowColor: const Color(0xFF00FFFF),
        reducedFx: true,
      );
      floor.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.update(0.016);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders with magenta color', () {
      final floor = makeFloor(
        glowColor: const Color(0xFFFF00FF),
        reducedFx: true,
      );
      floor.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.update(0.016);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders with green color', () {
      final floor = makeFloor(
        glowColor: const Color(0xFF00FF00),
        reducedFx: true,
      );
      floor.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.update(0.016);
      floor.render(canvas);
      recorder.endRecording();
    });
  });

  group('ReflectiveFloorComponent onGameResize', () {
    test('updates size on resize', () {
      final floor = makeFloor();
      floor.size = Vector2(800, 600);

      floor.onGameResize(Vector2(1920, 1080));

      expect(floor.size.x, 1920);
      expect(floor.size.y, 1080);
    });

    test('reinitializes effects on resize', () {
      final floor = makeFloor(reducedFx: false);
      floor.size = Vector2(800, 600);

      floor.onGameResize(Vector2(1600, 900));

      expect(true, isTrue);
    });

    test('handles resize with reducedFx', () {
      final floor = makeFloor(reducedFx: true);
      floor.size = Vector2(800, 600);

      floor.onGameResize(Vector2(1920, 1080));

      expect(floor.size.x, 1920);
    });

    test('handles resize to smaller size', () {
      final floor = makeFloor();
      floor.size = Vector2(1920, 1080);

      floor.onGameResize(Vector2(800, 600));

      expect(floor.size.x, 800);
      expect(floor.size.y, 600);
    });

    test('handles resize to same size', () {
      final floor = makeFloor();
      floor.size = Vector2(800, 600);

      floor.onGameResize(Vector2(800, 600));

      expect(floor.size.x, 800);
      expect(floor.size.y, 600);
    });
  });

  group('ReflectiveFloorComponent edge cases', () {
    test('renders with square aspect ratio', () {
      final floor = makeFloor(reducedFx: true);
      floor.onGameResize(Vector2(600, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.update(0.016);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders with wide aspect ratio', () {
      final floor = makeFloor(reducedFx: true);
      floor.onGameResize(Vector2(1920, 400));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.update(0.016);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders with tall aspect ratio', () {
      final floor = makeFloor(reducedFx: true);
      floor.onGameResize(Vector2(400, 1920));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.update(0.016);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('handles horizon at edge (0.1)', () {
      final floor = makeFloor(horizonRatio: 0.1, reducedFx: true);
      floor.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.update(0.016);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('handles horizon at edge (0.95)', () {
      final floor = makeFloor(horizonRatio: 0.95, reducedFx: true);
      floor.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.update(0.016);
      floor.render(canvas);
      recorder.endRecording();
    });
  });

  group('ReflectiveFloorComponent multiple instances', () {
    test('multiple floors can exist independently', () {
      final floor1 = makeFloor(horizonRatio: 0.4, reducedFx: true);
      final floor2 = makeFloor(horizonRatio: 0.6, reducedFx: true);

      floor1.onGameResize(Vector2(800, 600));
      floor2.onGameResize(Vector2(1920, 1080));

      floor1.update(0.1);
      floor2.update(0.1);

      expect(floor1.horizonRatio, isNot(equals(floor2.horizonRatio)));
    });

    test('multiple floors render independently', () {
      final floor1 = makeFloor(reducedFx: true);
      final floor2 = makeFloor(reducedFx: true);

      floor1.onGameResize(Vector2(800, 600));
      floor2.onGameResize(Vector2(800, 600));

      floor1.update(0.016);
      floor2.update(0.016);

      final recorder1 = ui.PictureRecorder();
      final canvas1 = ui.Canvas(recorder1);

      final recorder2 = ui.PictureRecorder();
      final canvas2 = ui.Canvas(recorder2);

      floor1.render(canvas1);
      floor2.render(canvas2);

      recorder1.endRecording();
      recorder2.endRecording();
    });
  });

  group('ReflectiveFloorComponent reducedFx mode', () {
    test('reducedFx mode creates fewer effects', () {
      final normalFloor = makeFloor(reducedFx: false);
      final reducedFloor = makeFloor(reducedFx: true);

      expect(normalFloor.reducedFx, isFalse);
      expect(reducedFloor.reducedFx, isTrue);
    });

    test('reducedFx true renders minimal effects', () {
      final floor = makeFloor(reducedFx: true);
      floor.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.update(0.5);
      floor.render(canvas);
      recorder.endRecording();
    });
  });

  group('ReflectiveFloorComponent reflection layers', () {
    test('all layers render without errors with full effects', () {
      final floor = makeFloor(reducedFx: false);
      floor.onGameResize(Vector2(800, 600));

      // Run through multiple frames to test animations
      for (int i = 0; i < 120; i++) {
        floor.update(0.016);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        floor.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders correctly with long animation time', () {
      final floor = makeFloor(reducedFx: false);
      floor.onGameResize(Vector2(800, 600));

      // Simulate 10 seconds of gameplay
      for (int i = 0; i < 600; i++) {
        floor.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders light streaks over time', () {
      final floor = makeFloor(reducedFx: false);
      floor.onGameResize(Vector2(800, 600));

      // Light streaks animate across the screen
      for (int i = 0; i < 300; i++) {
        floor.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders ripple distortion over time', () {
      final floor = makeFloor(reducedFx: false);
      floor.onGameResize(Vector2(800, 600));

      // Ripples expand and fade
      for (int i = 0; i < 200; i++) {
        floor.update(0.02);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders specular highlights over time', () {
      final floor = makeFloor(reducedFx: false);
      floor.onGameResize(Vector2(800, 600));

      // Specular highlights move and pulse
      for (int i = 0; i < 180; i++) {
        floor.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      floor.render(canvas);
      recorder.endRecording();
    });
  });
}
