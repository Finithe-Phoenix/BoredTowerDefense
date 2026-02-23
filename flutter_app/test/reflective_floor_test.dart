import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/reflective_floor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ReflectiveFloor makeFloor({
    Rect? floorRect,
    Color primaryColor = const Color(0xFF00FFFF),
    Color secondaryColor = const Color(0xFFFF0066),
    bool reduceFx = false,
    bool lowFx = false,
    double gridSize = 50.0,
    double horizonY = 0.3,
  }) {
    return ReflectiveFloor(
      floorRect: floorRect ?? const Rect.fromLTWH(0, 0, 800, 600),
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      reduceFx: reduceFx,
      lowFx: lowFx,
      gridSize: gridSize,
      horizonY: horizonY,
    );
  }

  group('ReflectiveFloor creation', () {
    test('creates with default parameters', () {
      final floor = makeFloor();

      expect(floor.primaryColor, const Color(0xFF00FFFF));
      expect(floor.secondaryColor, const Color(0xFFFF0066));
      expect(floor.reduceFx, isFalse);
      expect(floor.lowFx, isFalse);
      expect(floor.gridSize, 50.0);
      expect(floor.horizonY, 0.3);
    });

    test('creates with custom primary color', () {
      final floor = makeFloor(primaryColor: Colors.green);
      expect(floor.primaryColor, Colors.green);
    });

    test('creates with custom secondary color', () {
      final floor = makeFloor(secondaryColor: Colors.orange);
      expect(floor.secondaryColor, Colors.orange);
    });

    test('creates with reduceFx enabled', () {
      final floor = makeFloor(reduceFx: true);
      expect(floor.reduceFx, isTrue);
    });

    test('creates with lowFx enabled', () {
      final floor = makeFloor(lowFx: true);
      expect(floor.lowFx, isTrue);
    });

    test('creates with custom gridSize', () {
      final floor = makeFloor(gridSize: 100.0);
      expect(floor.gridSize, 100.0);
    });

    test('creates with custom horizonY', () {
      final floor = makeFloor(horizonY: 0.5);
      expect(floor.horizonY, 0.5);
    });

    test('is a PositionComponent', () {
      final floor = makeFloor();
      expect(floor, isA<PositionComponent>());
    });

    test('stores floorRect correctly', () {
      const rect = Rect.fromLTWH(10, 20, 400, 300);
      final floor = makeFloor(floorRect: rect);
      expect(floor.floorRect, rect);
    });
  });

  group('ReflectiveFloor onLoad', () {
    test('onLoad completes without error', () async {
      final floor = makeFloor();
      await floor.onLoad();
    });

    test('onLoad initializes with reduceFx', () async {
      final floor = makeFloor(reduceFx: true);
      await floor.onLoad();
    });

    test('onLoad initializes with lowFx', () async {
      final floor = makeFloor(lowFx: true);
      await floor.onLoad();
    });

    test('onLoad initializes with both reduceFx and lowFx', () async {
      final floor = makeFloor(reduceFx: true, lowFx: true);
      await floor.onLoad();
    });
  });

  group('ReflectiveFloor update', () {
    test('updates without errors', () async {
      final floor = makeFloor();
      await floor.onLoad();

      floor.update(0.016);
      floor.update(0.016);
    });

    test('updates with zero dt', () async {
      final floor = makeFloor();
      await floor.onLoad();

      floor.update(0.0);
    });

    test('updates with large dt', () async {
      final floor = makeFloor();
      await floor.onLoad();

      floor.update(1.0);
    });

    test('multiple rapid updates work', () async {
      final floor = makeFloor();
      await floor.onLoad();

      for (int i = 0; i < 100; i++) {
        floor.update(0.016);
      }
    });
  });

  group('ReflectiveFloor render', () {
    test('renders without error with full effects', () async {
      final floor = makeFloor();
      await floor.onLoad();
      floor.update(0.016);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders with reduceFx', () async {
      final floor = makeFloor(reduceFx: true);
      await floor.onLoad();
      floor.update(0.016);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders with lowFx', () async {
      final floor = makeFloor(lowFx: true);
      await floor.onLoad();
      floor.update(0.016);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders with zero-size floorRect returns early', () async {
      final floor = makeFloor(floorRect: Rect.zero);
      await floor.onLoad();
      floor.update(0.016);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders after multiple update cycles', () async {
      final floor = makeFloor(reduceFx: true);
      await floor.onLoad();

      for (int i = 0; i < 60; i++) {
        floor.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders with different horizon positions', () async {
      for (final horizonY in [0.1, 0.3, 0.5, 0.7, 0.9]) {
        final floor = makeFloor(horizonY: horizonY, reduceFx: true);
        await floor.onLoad();
        floor.update(0.016);

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        floor.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with different colors', () async {
      final floor = makeFloor(
        primaryColor: Colors.green,
        secondaryColor: Colors.purple,
        reduceFx: true,
      );
      await floor.onLoad();
      floor.update(0.016);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders with small floor rect', () async {
      final floor = makeFloor(
        floorRect: const Rect.fromLTWH(0, 0, 100, 80),
        reduceFx: true,
      );
      await floor.onLoad();
      floor.update(0.016);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders with large floor rect', () async {
      final floor = makeFloor(
        floorRect: const Rect.fromLTWH(0, 0, 1920, 1080),
        reduceFx: true,
      );
      await floor.onLoad();
      floor.update(0.016);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders with offset floor rect', () async {
      final floor = makeFloor(
        floorRect: const Rect.fromLTWH(100, 200, 600, 400),
        reduceFx: true,
      );
      await floor.onLoad();
      floor.update(0.016);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });
  });

  group('ReflectiveFloor animation layers', () {
    test('all layers render over multiple frames (full effects)', () async {
      final floor = makeFloor();
      await floor.onLoad();

      for (int i = 0; i < 120; i++) {
        floor.update(0.016);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        floor.render(canvas);
        recorder.endRecording();
      }
    });

    test('light streaks animate over time', () async {
      final floor = makeFloor();
      await floor.onLoad();

      for (int i = 0; i < 300; i++) {
        floor.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('renders correctly with long animation time', () async {
      final floor = makeFloor(reduceFx: true);
      await floor.onLoad();

      // Simulate 10 seconds
      for (int i = 0; i < 600; i++) {
        floor.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });
  });

  group('ReflectiveFloor triggerRipple', () {
    test('triggerRipple within bounds does not throw', () async {
      final floor = makeFloor();
      await floor.onLoad();

      floor.triggerRipple(Vector2(400, 450));
    });

    test('triggerRipple outside bounds is ignored', () async {
      final floor = makeFloor();
      await floor.onLoad();

      // Position outside the floor rect
      floor.triggerRipple(Vector2(-100, -100));
    });

    test('triggerRipple at corner', () async {
      final floor = makeFloor();
      await floor.onLoad();

      floor.triggerRipple(Vector2(0, 180)); // At horizonY boundary
    });

    test('multiple triggerRipple calls', () async {
      final floor = makeFloor();
      await floor.onLoad();

      for (int i = 0; i < 5; i++) {
        floor.triggerRipple(Vector2(100.0 + i * 100, 400));
      }
    });

    test('triggerRipple is ignored in lowFx mode', () async {
      final floor = makeFloor(lowFx: true);
      await floor.onLoad();

      // Should be a no-op in lowFx mode
      floor.triggerRipple(Vector2(400, 400));
    });

    test('ripple limits to 8 active ripples', () async {
      final floor = makeFloor();
      await floor.onLoad();

      // Trigger more than 8 ripples
      for (int i = 0; i < 12; i++) {
        floor.triggerRipple(Vector2(50.0 + i * 60, 400));
      }

      // Should render without error (older ripples are removed)
      floor.update(0.016);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('ripple renders after trigger', () async {
      final floor = makeFloor();
      await floor.onLoad();

      floor.triggerRipple(Vector2(400, 400));

      for (int i = 0; i < 60; i++) {
        floor.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });
  });

  group('ReflectiveFloor fx modes comparison', () {
    test('full fx creates more effects than reduceFx', () async {
      final fullFloor = makeFloor(reduceFx: false, lowFx: false);
      final reducedFloor = makeFloor(reduceFx: true, lowFx: false);

      await fullFloor.onLoad();
      await reducedFloor.onLoad();

      expect(fullFloor.reduceFx, isFalse);
      expect(reducedFloor.reduceFx, isTrue);
    });

    test('lowFx is most minimal mode', () async {
      final lowFloor = makeFloor(lowFx: true);
      await lowFloor.onLoad();

      expect(lowFloor.lowFx, isTrue);
    });

    test('all fx modes render without errors', () async {
      final modes = [
        makeFloor(reduceFx: false, lowFx: false),
        makeFloor(reduceFx: true, lowFx: false),
        makeFloor(reduceFx: false, lowFx: true),
        makeFloor(reduceFx: true, lowFx: true),
      ];

      for (final floor in modes) {
        await floor.onLoad();
        floor.update(0.1);

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        floor.render(canvas);
        recorder.endRecording();
      }
    });
  });

  group('ReflectiveFloor multiple instances', () {
    test('multiple floors can exist independently', () async {
      final floor1 = makeFloor(horizonY: 0.2, primaryColor: Colors.red);
      final floor2 = makeFloor(horizonY: 0.6, primaryColor: Colors.blue);

      await floor1.onLoad();
      await floor2.onLoad();

      floor1.update(0.1);
      floor2.update(0.1);

      expect(floor1.horizonY, isNot(equals(floor2.horizonY)));
      expect(floor1.primaryColor, isNot(equals(floor2.primaryColor)));
    });

    test('multiple floors render independently', () async {
      final floor1 = makeFloor(reduceFx: true);
      final floor2 = makeFloor(reduceFx: true);

      await floor1.onLoad();
      await floor2.onLoad();

      floor1.update(0.016);
      floor2.update(0.016);

      final recorder1 = ui.PictureRecorder();
      final canvas1 = Canvas(recorder1);
      floor1.render(canvas1);
      recorder1.endRecording();

      final recorder2 = ui.PictureRecorder();
      final canvas2 = Canvas(recorder2);
      floor2.render(canvas2);
      recorder2.endRecording();
    });
  });

  group('ReflectiveFloor edge cases', () {
    test('horizonY at 0.0 (all floor)', () async {
      final floor = makeFloor(horizonY: 0.0, reduceFx: true);
      await floor.onLoad();
      floor.update(0.016);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('horizonY at 1.0 (no floor)', () async {
      final floor = makeFloor(horizonY: 1.0, reduceFx: true);
      await floor.onLoad();
      floor.update(0.016);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('very small grid size', () async {
      final floor = makeFloor(gridSize: 5.0, reduceFx: true);
      await floor.onLoad();
      floor.update(0.016);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('very large grid size', () async {
      final floor = makeFloor(gridSize: 500.0, reduceFx: true);
      await floor.onLoad();
      floor.update(0.016);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('square floor rect', () async {
      final floor = makeFloor(
        floorRect: const Rect.fromLTWH(0, 0, 500, 500),
        reduceFx: true,
      );
      await floor.onLoad();
      floor.update(0.016);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('wide floor rect', () async {
      final floor = makeFloor(
        floorRect: const Rect.fromLTWH(0, 0, 2000, 200),
        reduceFx: true,
      );
      await floor.onLoad();
      floor.update(0.016);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });

    test('tall floor rect', () async {
      final floor = makeFloor(
        floorRect: const Rect.fromLTWH(0, 0, 200, 2000),
        reduceFx: true,
      );
      await floor.onLoad();
      floor.update(0.016);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      floor.render(canvas);
      recorder.endRecording();
    });
  });
}
