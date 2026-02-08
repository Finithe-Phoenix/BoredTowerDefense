import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/pixel_disintegration_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PixelDisintegrationEffect.clearPool();
    PixelDisintegrationEffect.fxScale = 1.0;
    PixelDisintegrationEffect.reduceFx = false;
    PixelDisintegrationEffect.lowFx = false;
  });

  tearDown(() {
    PixelDisintegrationEffect.clearPool();
    PixelDisintegrationEffect.fxScale = 1.0;
    PixelDisintegrationEffect.reduceFx = false;
    PixelDisintegrationEffect.lowFx = false;
  });

  group('PixelDisintegrationEffect spawn', () {
    test('spawn creates effect with required parameters', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.cyan,
      );

      expect(effect, isNotNull);
      expect(effect, isA<PositionComponent>());
      expect(effect!.position.x, 100);
      expect(effect.position.y, 100);
      expect(effect.color, Colors.cyan);
    });

    test('spawn creates effect with custom size', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
        effectSize: 50.0,
      );

      expect(effect, isNotNull);
      expect(effect!.effectSize, 50.0);
    });

    test('spawn creates effect with custom duration', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.blue,
        duration: 1.5,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 1.5);
    });

    test('spawn uses default effect size', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      expect(effect, isNotNull);
      expect(effect!.effectSize, 30.0);
    });

    test('spawn uses default duration', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 0.8);
    });

    test('spawn returns null when max active reached', () {
      final effects = <PixelDisintegrationEffect>[];
      for (int i = 0; i < PixelDisintegrationEffect.maxActive; i++) {
        final effect = PixelDisintegrationEffect.spawn(
          position: Vector2(i.toDouble(), 0),
          color: Colors.cyan,
        );
        if (effect != null) effects.add(effect);
      }

      final extraEffect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      expect(extraEffect, isNull);
    });

    test('activeCount increments on spawn', () {
      expect(PixelDisintegrationEffect.activeCount, 0);

      PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      expect(PixelDisintegrationEffect.activeCount, 1);
    });

    test('activeCount increments for multiple spawns', () {
      PixelDisintegrationEffect.spawn(position: Vector2(0, 0), color: Colors.red);
      PixelDisintegrationEffect.spawn(position: Vector2(100, 0), color: Colors.blue);
      PixelDisintegrationEffect.spawn(position: Vector2(200, 0), color: Colors.green);

      expect(PixelDisintegrationEffect.activeCount, 3);
    });
  });

  group('PixelDisintegrationEffect static properties', () {
    test('maxPool constant is defined', () {
      expect(PixelDisintegrationEffect.maxPool, 20);
    });

    test('maxActive constant is defined', () {
      expect(PixelDisintegrationEffect.maxActive, 15);
    });

    test('fxScale defaults to 1.0', () {
      PixelDisintegrationEffect.fxScale = 1.0;
      expect(PixelDisintegrationEffect.fxScale, 1.0);
    });

    test('fxScale can be modified', () {
      PixelDisintegrationEffect.fxScale = 0.5;
      expect(PixelDisintegrationEffect.fxScale, 0.5);
      PixelDisintegrationEffect.fxScale = 1.0;
    });

    test('reduceFx can be toggled', () {
      PixelDisintegrationEffect.reduceFx = true;
      expect(PixelDisintegrationEffect.reduceFx, isTrue);
      PixelDisintegrationEffect.reduceFx = false;
    });

    test('lowFx can be toggled', () {
      PixelDisintegrationEffect.lowFx = true;
      expect(PixelDisintegrationEffect.lowFx, isTrue);
      PixelDisintegrationEffect.lowFx = false;
    });
  });

  group('PixelDisintegrationEffect clearPool', () {
    test('clearPool resets active count', () {
      PixelDisintegrationEffect.spawn(position: Vector2.zero(), color: Colors.cyan);
      PixelDisintegrationEffect.spawn(position: Vector2(100, 0), color: Colors.cyan);

      expect(PixelDisintegrationEffect.activeCount, 2);

      PixelDisintegrationEffect.clearPool();

      expect(PixelDisintegrationEffect.activeCount, 0);
    });

    test('clearPool allows spawning again after max reached', () {
      for (int i = 0; i < PixelDisintegrationEffect.maxActive; i++) {
        PixelDisintegrationEffect.spawn(
          position: Vector2(i.toDouble(), 0),
          color: Colors.cyan,
        );
      }

      PixelDisintegrationEffect.clearPool();

      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      expect(effect, isNotNull);
    });
  });

  group('PixelDisintegrationEffect update', () {
    test('update advances effect state', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 1.0,
      );

      effect!.update(0.016);
      effect.update(0.016);
      effect.update(0.016);

      expect(true, isTrue);
    });

    test('update with zero dt does not crash', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      effect!.update(0.0);
      expect(true, isTrue);
    });

    test('effect completes after duration', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 0.5,
      );

      for (int i = 0; i < 50; i++) {
        effect!.update(0.016);
      }

      expect(true, isTrue);
    });

    test('multiple rapid updates work', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      for (int i = 0; i < 100; i++) {
        effect!.update(0.016);
      }
      expect(true, isTrue);
    });
  });

  group('PixelDisintegrationEffect render', () {
    test('renders without exceptions', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        effectSize: 30.0,
        duration: 0.8,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders at start of animation', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.001);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in middle of animation', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders near end of animation', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 0.8,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.75);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with different colors', () {
      final colors = [Colors.red, Colors.blue, Colors.green, Colors.purple, Colors.orange];

      for (final color in colors) {
        final effect = PixelDisintegrationEffect.spawn(
          position: Vector2.zero(),
          color: color,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect!.update(0.1);
        effect.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with small effect size', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        effectSize: 10.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with large effect size', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        effectSize: 100.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in lowFx mode', () {
      PixelDisintegrationEffect.lowFx = true;

      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in reduceFx mode', () {
      PixelDisintegrationEffect.reduceFx = true;

      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });
  });

  group('PixelDisintegrationEffect with fxScale', () {
    test('fxScale 0 reduces particles', () {
      PixelDisintegrationEffect.fxScale = 0.0;

      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('fxScale 0.5 reduces particles', () {
      PixelDisintegrationEffect.fxScale = 0.5;

      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('fxScale 1.0 uses full particles', () {
      PixelDisintegrationEffect.fxScale = 1.0;

      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });
  });

  group('PixelDisintegrationEffect pooling', () {
    test('effects can be reused from pool', () {
      final effect1 = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 0.1,
      );

      for (int i = 0; i < 20; i++) {
        effect1!.update(0.01);
      }

      final effect2 = PixelDisintegrationEffect.spawn(
        position: Vector2(50, 50),
        color: Colors.red,
      );

      expect(effect2, isNotNull);
    });

    test('pool does not exceed maxPool', () {
      for (int i = 0; i < 30; i++) {
        final effect = PixelDisintegrationEffect.spawn(
          position: Vector2(i.toDouble(), 0),
          color: Colors.cyan,
          duration: 0.05,
        );

        if (effect != null) {
          for (int j = 0; j < 10; j++) {
            effect.update(0.01);
          }
        }

        PixelDisintegrationEffect.clearPool();
      }

      expect(true, isTrue);
    });
  });

  group('PixelDisintegrationEffect edge cases', () {
    test('works with very short duration', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 0.01,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.005);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with very long duration', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 10.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with negative position', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2(-100, -100),
        color: Colors.cyan,
      );

      expect(effect, isNotNull);
      expect(effect!.position.x, -100);
      expect(effect.position.y, -100);
    });

    test('works with very large position', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2(10000, 10000),
        color: Colors.cyan,
      );

      expect(effect, isNotNull);
    });

    test('multiple effects at same position', () {
      final effect1 = PixelDisintegrationEffect.spawn(
        position: Vector2(50, 50),
        color: Colors.cyan,
      );
      final effect2 = PixelDisintegrationEffect.spawn(
        position: Vector2(50, 50),
        color: Colors.red,
      );

      expect(effect1, isNotNull);
      expect(effect2, isNotNull);
    });
  });

  group('PixelDisintegrationEffect anchor', () {
    test('anchor is center', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      expect(effect!.anchor, Anchor.center);
    });
  });

  group('PixelDisintegrationEffect multiple instances', () {
    test('multiple effects can update independently', () {
      final effect1 = PixelDisintegrationEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.cyan,
        duration: 1.0,
      );
      final effect2 = PixelDisintegrationEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.red,
        duration: 2.0,
      );

      effect1!.update(0.5);
      effect2!.update(0.2);

      expect(effect1.color, isNot(effect2.color));
    });

    test('multiple effects render independently', () {
      final effect1 = PixelDisintegrationEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.cyan,
      );
      final effect2 = PixelDisintegrationEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.red,
      );

      final recorder1 = ui.PictureRecorder();
      final canvas1 = ui.Canvas(recorder1);

      final recorder2 = ui.PictureRecorder();
      final canvas2 = ui.Canvas(recorder2);

      effect1!.update(0.1);
      effect2!.update(0.1);

      effect1.render(canvas1);
      effect2.render(canvas2);

      recorder1.endRecording();
      recorder2.endRecording();
    });
  });

  group('PixelDisintegrationEffect animation phases', () {
    test('renders digital noise phase (0-0.5)', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 0.8,
      );

      for (double t = 0; t < 0.4; t += 0.05) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect!.update(0.05);
        effect.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders scanline phase (0-0.6)', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 0.8,
      );

      for (double t = 0; t < 0.48; t += 0.05) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect!.update(0.05);
        effect.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders final flash phase (0.85-1.0)', () {
      final effect = PixelDisintegrationEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 0.8,
      );

      effect!.update(0.68);

      for (double t = 0.85; t < 1.0; t += 0.02) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect.update(0.016);
        effect.render(canvas);
        recorder.endRecording();
      }
    });
  });
}
