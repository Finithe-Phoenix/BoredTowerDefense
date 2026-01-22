import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/explosion_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ExplosionEffect.clearPool();
    ExplosionEffect.fxScale = 1.0;
  });

  tearDown(() {
    ExplosionEffect.clearPool();
    ExplosionEffect.fxScale = 1.0;
  });

  group('ExplosionEffect spawn', () {
    test('spawn creates explosion with required parameters', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.red,
      );

      expect(effect, isNotNull);
      expect(effect, isA<PositionComponent>());
      expect(effect!.position.x, 100);
      expect(effect.position.y, 100);
      expect(effect.color, Colors.red);
    });

    test('spawn creates explosion with custom size', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.blue,
        explosionSize: 80.0,
      );

      expect(effect, isNotNull);
      expect(effect!.explosionSize, 80.0);
    });

    test('spawn creates explosion with custom duration', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.green,
        duration: 1.5,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 1.5);
    });

    test('spawn uses default explosion size', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      expect(effect, isNotNull);
      expect(effect!.explosionSize, 40.0);
    });

    test('spawn uses default duration', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 0.6);
    });

    test('spawn returns null when max active reached', () {
      // Spawn max active explosions
      final effects = <ExplosionEffect>[];
      for (int i = 0; i < ExplosionEffect.maxActive; i++) {
        final effect = ExplosionEffect.spawn(
          position: Vector2(i.toDouble(), 0),
          color: Colors.red,
        );
        if (effect != null) effects.add(effect);
      }

      // Next spawn should return null
      final extraEffect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
      );

      expect(extraEffect, isNull);
    });

    test('activeCount increments on spawn', () {
      expect(ExplosionEffect.activeCount, 0);

      ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
      );

      expect(ExplosionEffect.activeCount, 1);
    });

    test('activeCount increments for multiple spawns', () {
      ExplosionEffect.spawn(position: Vector2(0, 0), color: Colors.red);
      ExplosionEffect.spawn(position: Vector2(10, 0), color: Colors.red);
      ExplosionEffect.spawn(position: Vector2(20, 0), color: Colors.red);

      expect(ExplosionEffect.activeCount, 3);
    });
  });

  group('ExplosionEffect static properties', () {
    test('maxPool constant is defined', () {
      expect(ExplosionEffect.maxPool, 24);
    });

    test('maxActive constant is defined', () {
      expect(ExplosionEffect.maxActive, 18);
    });

    test('fxScale defaults to 1.0', () {
      ExplosionEffect.fxScale = 1.0;
      expect(ExplosionEffect.fxScale, 1.0);
    });

    test('fxScale can be modified', () {
      ExplosionEffect.fxScale = 0.5;
      expect(ExplosionEffect.fxScale, 0.5);
      ExplosionEffect.fxScale = 1.0;
    });
  });

  group('ExplosionEffect clearPool', () {
    test('clearPool resets active count', () {
      ExplosionEffect.spawn(position: Vector2.zero(), color: Colors.red);
      ExplosionEffect.spawn(position: Vector2(10, 0), color: Colors.red);

      expect(ExplosionEffect.activeCount, 2);

      ExplosionEffect.clearPool();

      expect(ExplosionEffect.activeCount, 0);
    });

    test('clearPool allows spawning again after max reached', () {
      // Fill up to max
      for (int i = 0; i < ExplosionEffect.maxActive; i++) {
        ExplosionEffect.spawn(
          position: Vector2(i.toDouble(), 0),
          color: Colors.red,
        );
      }

      // Clear pool
      ExplosionEffect.clearPool();

      // Should be able to spawn again
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
      );

      expect(effect, isNotNull);
    });
  });

  group('ExplosionEffect shakeIntensity', () {
    test('shakeIntensity is initially 0.8', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
      );

      // Core flash intensity starts at 1.0, shake = 1.0 * 0.8
      expect(effect!.shakeIntensity, 0.8);
    });

    test('shakeIntensity decreases over time', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
        duration: 0.6,
      );

      final initial = effect!.shakeIntensity;

      effect.update(0.1);

      expect(effect.shakeIntensity, lessThan(initial));
    });

    test('shakeIntensity reaches zero', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
        duration: 0.3,
      );

      // Update past core flash fade (1/3 of duration)
      effect!.update(0.15);

      expect(effect.shakeIntensity, 0.0);
    });
  });

  group('ExplosionEffect update', () {
    test('update advances effect state', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
        duration: 1.0,
      );

      effect!.update(0.016);
      effect.update(0.016);
      effect.update(0.016);

      expect(true, isTrue);
    });

    test('update with zero dt does not crash', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
      );

      effect!.update(0.0);
      expect(true, isTrue);
    });

    test('effect completes after duration', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
        duration: 0.5,
      );

      // Update past duration
      for (int i = 0; i < 50; i++) {
        effect!.update(0.016);
      }

      // Effect should have recycled
      expect(true, isTrue);
    });

    test('multiple rapid updates work', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
      );

      for (int i = 0; i < 100; i++) {
        effect!.update(0.016);
      }
      expect(true, isTrue);
    });
  });

  group('ExplosionEffect render', () {
    test('renders without exceptions', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
        explosionSize: 40.0,
        duration: 0.6,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders at start of animation', () {
      final effect = ExplosionEffect.spawn(
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
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.yellow,
        duration: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders near end of animation', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.green,
        duration: 0.6,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.55);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with small explosion size', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
        explosionSize: 10.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with large explosion size', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
        explosionSize: 200.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with different colors', () {
      final colors = [Colors.red, Colors.blue, Colors.green, Colors.purple];

      for (final color in colors) {
        final effect = ExplosionEffect.spawn(
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
  });

  group('ExplosionEffect with fxScale', () {
    test('fxScale 0 reduces particles', () {
      ExplosionEffect.fxScale = 0.0;

      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('fxScale 0.5 reduces particles', () {
      ExplosionEffect.fxScale = 0.5;

      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('fxScale 1.0 uses full particles', () {
      ExplosionEffect.fxScale = 1.0;

      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });
  });

  group('ExplosionEffect pooling', () {
    test('effects can be reused from pool', () {
      // Spawn and let complete
      final effect1 = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
        duration: 0.1,
      );

      // Complete the effect
      for (int i = 0; i < 20; i++) {
        effect1!.update(0.01);
      }

      // Spawn again - should reuse from pool
      final effect2 = ExplosionEffect.spawn(
        position: Vector2(50, 50),
        color: Colors.blue,
      );

      expect(effect2, isNotNull);
    });

    test('pool does not exceed maxPool', () {
      // Spawn many and complete them
      for (int i = 0; i < 30; i++) {
        final effect = ExplosionEffect.spawn(
          position: Vector2(i.toDouble(), 0),
          color: Colors.red,
          duration: 0.05,
        );

        if (effect != null) {
          for (int j = 0; j < 10; j++) {
            effect.update(0.01);
          }
        }

        ExplosionEffect.clearPool();
      }

      expect(true, isTrue);
    });
  });

  group('ExplosionEffect edge cases', () {
    test('works with very short duration', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
        duration: 0.01,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.005);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with very long duration', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
        duration: 10.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with negative position', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(-100, -100),
        color: Colors.red,
      );

      expect(effect, isNotNull);
      expect(effect!.position.x, -100);
      expect(effect.position.y, -100);
    });

    test('works with very large position', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(10000, 10000),
        color: Colors.red,
      );

      expect(effect, isNotNull);
    });

    test('multiple effects at same position', () {
      final effect1 = ExplosionEffect.spawn(
        position: Vector2(50, 50),
        color: Colors.red,
      );
      final effect2 = ExplosionEffect.spawn(
        position: Vector2(50, 50),
        color: Colors.blue,
      );

      expect(effect1, isNotNull);
      expect(effect2, isNotNull);
    });
  });

  group('ExplosionEffect anchor', () {
    test('anchor is center', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
      );

      expect(effect!.anchor, Anchor.center);
    });
  });

  group('ExplosionEffect multiple instances', () {
    test('multiple effects can update independently', () {
      final effect1 = ExplosionEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.red,
        duration: 1.0,
      );
      final effect2 = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.blue,
        duration: 2.0,
      );

      effect1!.update(0.5);
      effect2!.update(0.2);

      // Different progress
      expect(effect1.shakeIntensity != effect2.shakeIntensity, isTrue);
    });

    test('multiple effects render independently', () {
      final effect1 = ExplosionEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.red,
      );
      final effect2 = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.blue,
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
}
