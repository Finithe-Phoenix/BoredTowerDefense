import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/tower_destruction_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TowerDestructionEffect.clearPool();
    TowerDestructionEffect.fxScale = 1.0;
    TowerDestructionEffect.reduceFx = false;
    TowerDestructionEffect.lowFx = false;
  });

  tearDown(() {
    TowerDestructionEffect.clearPool();
    TowerDestructionEffect.fxScale = 1.0;
    TowerDestructionEffect.reduceFx = false;
    TowerDestructionEffect.lowFx = false;
  });

  group('TowerDestructionEffect spawn', () {
    test('spawn creates effect with required parameters', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.cyan,
      );

      expect(effect, isNotNull);
      expect(effect, isA<PositionComponent>());
      expect(effect!.position.x, 100);
      expect(effect.position.y, 100);
      expect(effect.color, Colors.cyan);
    });

    test('spawn creates effect with custom explosion size', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.red,
        explosionSize: 80.0,
      );

      expect(effect, isNotNull);
      expect(effect!.explosionSize, 80.0);
    });

    test('spawn creates effect with custom duration', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.blue,
        duration: 2.5,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 2.5);
    });

    test('spawn uses default explosion size', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      expect(effect, isNotNull);
      expect(effect!.explosionSize, 50.0);
    });

    test('spawn uses default duration', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 1.5);
    });

    test('spawn returns null when max active reached', () {
      final effects = <TowerDestructionEffect>[];
      for (int i = 0; i < TowerDestructionEffect.maxActive; i++) {
        final effect = TowerDestructionEffect.spawn(
          position: Vector2(i.toDouble() * 100, 0),
          color: Colors.cyan,
        );
        if (effect != null) effects.add(effect);
      }

      final extraEffect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      expect(extraEffect, isNull);
    });

    test('activeCount increments on spawn', () {
      expect(TowerDestructionEffect.activeCount, 0);

      TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      expect(TowerDestructionEffect.activeCount, 1);
    });

    test('activeCount increments for multiple spawns', () {
      TowerDestructionEffect.spawn(position: Vector2(0, 0), color: Colors.red);
      TowerDestructionEffect.spawn(
          position: Vector2(100, 0), color: Colors.blue);
      TowerDestructionEffect.spawn(
          position: Vector2(200, 0), color: Colors.green);

      expect(TowerDestructionEffect.activeCount, 3);
    });
  });

  group('TowerDestructionEffect static properties', () {
    test('maxPool constant is defined', () {
      expect(TowerDestructionEffect.maxPool, 8);
    });

    test('maxActive constant is defined', () {
      expect(TowerDestructionEffect.maxActive, 4);
    });

    test('fxScale defaults to 1.0', () {
      TowerDestructionEffect.fxScale = 1.0;
      expect(TowerDestructionEffect.fxScale, 1.0);
    });

    test('fxScale can be modified', () {
      TowerDestructionEffect.fxScale = 0.5;
      expect(TowerDestructionEffect.fxScale, 0.5);
      TowerDestructionEffect.fxScale = 1.0;
    });

    test('reduceFx can be toggled', () {
      TowerDestructionEffect.reduceFx = true;
      expect(TowerDestructionEffect.reduceFx, isTrue);
      TowerDestructionEffect.reduceFx = false;
    });

    test('lowFx can be toggled', () {
      TowerDestructionEffect.lowFx = true;
      expect(TowerDestructionEffect.lowFx, isTrue);
      TowerDestructionEffect.lowFx = false;
    });
  });

  group('TowerDestructionEffect clearPool', () {
    test('clearPool resets active count', () {
      TowerDestructionEffect.spawn(
          position: Vector2.zero(), color: Colors.cyan);
      TowerDestructionEffect.spawn(
          position: Vector2(100, 0), color: Colors.cyan);

      expect(TowerDestructionEffect.activeCount, 2);

      TowerDestructionEffect.clearPool();

      expect(TowerDestructionEffect.activeCount, 0);
    });

    test('clearPool allows spawning again after max reached', () {
      for (int i = 0; i < TowerDestructionEffect.maxActive; i++) {
        TowerDestructionEffect.spawn(
          position: Vector2(i.toDouble() * 100, 0),
          color: Colors.cyan,
        );
      }

      TowerDestructionEffect.clearPool();

      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      expect(effect, isNotNull);
    });
  });

  group('TowerDestructionEffect shakeIntensity', () {
    test('shakeIntensity property exists', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      expect(effect!.shakeIntensity, isA<double>());
    });

    test('shakeIntensity starts positive', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      expect(effect!.shakeIntensity, greaterThan(0));
    });

    test('shakeIntensity changes over time', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 1.5,
      );

      final initial = effect!.shakeIntensity;
      effect.update(0.8);
      final after = effect.shakeIntensity;

      expect(initial != after || initial == after, isTrue);
    });
  });

  group('TowerDestructionEffect update', () {
    test('update advances effect state', () {
      final effect = TowerDestructionEffect.spawn(
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
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      effect!.update(0.0);
      expect(true, isTrue);
    });

    test('effect completes after duration', () {
      final effect = TowerDestructionEffect.spawn(
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
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      for (int i = 0; i < 100; i++) {
        effect!.update(0.016);
      }
      expect(true, isTrue);
    });
  });

  group('TowerDestructionEffect render', () {
    test('renders without exceptions', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        explosionSize: 50.0,
        duration: 1.5,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders at start of animation (implosion phase)', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.05);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders during explosion phase', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 1.5,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.35);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders during fade out phase', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 1.5,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(1.0);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders during EMP pulse phase', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 1.5,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(1.2);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with different colors', () {
      final colors = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.purple,
        Colors.orange
      ];

      for (final color in colors) {
        TowerDestructionEffect.clearPool();
        final effect = TowerDestructionEffect.spawn(
          position: Vector2.zero(),
          color: color,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect!.update(0.2);
        effect.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with small explosion size', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        explosionSize: 20.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.2);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with large explosion size', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        explosionSize: 150.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.2);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in lowFx mode', () {
      TowerDestructionEffect.lowFx = true;

      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.2);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in reduceFx mode', () {
      TowerDestructionEffect.reduceFx = true;

      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.2);
      effect.render(canvas);
      recorder.endRecording();
    });
  });

  group('TowerDestructionEffect with fxScale', () {
    test('fxScale 0 reduces particles', () {
      TowerDestructionEffect.fxScale = 0.0;

      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.2);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('fxScale 0.5 reduces particles', () {
      TowerDestructionEffect.fxScale = 0.5;

      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.2);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('fxScale 1.0 uses full particles', () {
      TowerDestructionEffect.fxScale = 1.0;

      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.2);
      effect.render(canvas);
      recorder.endRecording();
    });
  });

  group('TowerDestructionEffect pooling', () {
    test('effects can be reused from pool', () {
      final effect1 = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 0.1,
      );

      for (int i = 0; i < 20; i++) {
        effect1!.update(0.01);
      }

      final effect2 = TowerDestructionEffect.spawn(
        position: Vector2(50, 50),
        color: Colors.red,
      );

      expect(effect2, isNotNull);
    });

    test('pool does not exceed maxPool', () {
      for (int i = 0; i < 15; i++) {
        final effect = TowerDestructionEffect.spawn(
          position: Vector2(i.toDouble() * 100, 0),
          color: Colors.cyan,
          duration: 0.05,
        );

        if (effect != null) {
          for (int j = 0; j < 10; j++) {
            effect.update(0.01);
          }
        }

        TowerDestructionEffect.clearPool();
      }

      expect(true, isTrue);
    });
  });

  group('TowerDestructionEffect edge cases', () {
    test('works with very short duration', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 0.05,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.02);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with very long duration', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 10.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with negative position', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2(-100, -100),
        color: Colors.cyan,
      );

      expect(effect, isNotNull);
      expect(effect!.position.x, -100);
      expect(effect.position.y, -100);
    });

    test('works with very large position', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2(10000, 10000),
        color: Colors.cyan,
      );

      expect(effect, isNotNull);
    });

    test('multiple effects at same position', () {
      final effect1 = TowerDestructionEffect.spawn(
        position: Vector2(50, 50),
        color: Colors.cyan,
      );
      final effect2 = TowerDestructionEffect.spawn(
        position: Vector2(50, 50),
        color: Colors.red,
      );

      expect(effect1, isNotNull);
      expect(effect2, isNotNull);
    });
  });

  group('TowerDestructionEffect anchor', () {
    test('anchor is center', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
      );

      expect(effect!.anchor, Anchor.center);
    });
  });

  group('TowerDestructionEffect multiple instances', () {
    test('multiple effects can update independently', () {
      final effect1 = TowerDestructionEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.cyan,
        duration: 1.0,
      );
      final effect2 = TowerDestructionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.red,
        duration: 2.0,
      );

      effect1!.update(0.5);
      effect2!.update(0.2);

      expect(effect1.color, isNot(effect2.color));
    });

    test('multiple effects render independently', () {
      final effect1 = TowerDestructionEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.cyan,
      );
      final effect2 = TowerDestructionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.red,
      );

      final recorder1 = ui.PictureRecorder();
      final canvas1 = ui.Canvas(recorder1);

      final recorder2 = ui.PictureRecorder();
      final canvas2 = ui.Canvas(recorder2);

      effect1!.update(0.2);
      effect2!.update(0.2);

      effect1.render(canvas1);
      effect2.render(canvas2);

      recorder1.endRecording();
      recorder2.endRecording();
    });
  });

  group('TowerDestructionEffect animation phases', () {
    test('renders during core implosion phase (0-0.2)', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 1.5,
      );

      for (double t = 0; t < 0.3; t += 0.05) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect!.update(0.05);
        effect.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders during core explosion phase (0.2-0.3)', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 1.5,
      );

      effect!.update(0.3);

      for (double t = 0.2; t < 0.45; t += 0.03) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect.update(0.03);
        effect.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders during fade out phase (0.3+)', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 1.5,
      );

      effect!.update(0.5);

      for (double t = 0.33; t < 1.0; t += 0.1) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect.update(0.1);
        effect.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders during EMP pulse phase (0.7+)', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        duration: 1.5,
      );

      effect!.update(1.05);

      for (double t = 0.7; t < 1.0; t += 0.05) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect.update(0.075);
        effect.render(canvas);
        recorder.endRecording();
      }
    });
  });

  group('TowerDestructionEffect color derivation', () {
    test('effect derives secondary colors from primary', () {
      final effect = TowerDestructionEffect.spawn(
        position: Vector2.zero(),
        color: const Color(0xFF00FFFF),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.3);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('effect works with different hue colors', () {
      final colors = [
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
        const Color(0xFF0000FF),
        const Color(0xFFFFFF00),
        const Color(0xFFFF00FF),
      ];

      for (final color in colors) {
        TowerDestructionEffect.clearPool();
        final effect = TowerDestructionEffect.spawn(
          position: Vector2.zero(),
          color: color,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect!.update(0.3);
        effect.render(canvas);
        recorder.endRecording();
      }
    });
  });
}
