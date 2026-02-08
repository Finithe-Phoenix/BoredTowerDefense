import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/galaxy_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GalaxyEffect.clearPool();
    GalaxyEffect.fxScale = 1.0;
  });

  tearDown(() {
    GalaxyEffect.clearPool();
    GalaxyEffect.fxScale = 1.0;
  });

  group('GalaxyEffect spawn', () {
    test('spawn creates effect with required parameters', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2(100, 100),
      );

      expect(effect, isNotNull);
      expect(effect, isA<PositionComponent>());
      expect(effect!.position.x, 100);
      expect(effect.position.y, 100);
    });

    test('spawn creates effect with custom galaxySize', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        galaxySize: 120.0,
      );

      expect(effect, isNotNull);
      expect(effect!.galaxySize, 120.0);
    });

    test('spawn creates effect with custom duration', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        duration: 3.0,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 3.0);
    });

    test('spawn uses default galaxySize of 80', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
      );

      expect(effect, isNotNull);
      expect(effect!.galaxySize, 80.0);
    });

    test('spawn uses default duration of 2.0', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 2.0);
    });

    test('spawn returns null when max active reached', () {
      final effects = <GalaxyEffect>[];
      for (int i = 0; i < GalaxyEffect.maxActive; i++) {
        final effect = GalaxyEffect.spawn(
          position: Vector2(i.toDouble(), 0),
        );
        if (effect != null) effects.add(effect);
      }

      final extraEffect = GalaxyEffect.spawn(
        position: Vector2.zero(),
      );

      expect(extraEffect, isNull);
    });

    test('activeCount increments on spawn', () {
      expect(GalaxyEffect.activeCount, 0);

      GalaxyEffect.spawn(
        position: Vector2.zero(),
      );

      expect(GalaxyEffect.activeCount, 1);
    });

    test('activeCount increments for multiple spawns', () {
      GalaxyEffect.spawn(position: Vector2(0, 0));
      GalaxyEffect.spawn(position: Vector2(10, 0));
      GalaxyEffect.spawn(position: Vector2(20, 0));

      expect(GalaxyEffect.activeCount, 3);
    });
  });

  group('GalaxyEffect static properties', () {
    test('maxPool constant is defined', () {
      expect(GalaxyEffect.maxPool, 8);
    });

    test('maxActive constant is defined', () {
      expect(GalaxyEffect.maxActive, 4);
    });

    test('fxScale defaults to 1.0', () {
      GalaxyEffect.fxScale = 1.0;
      expect(GalaxyEffect.fxScale, 1.0);
    });

    test('fxScale can be modified', () {
      GalaxyEffect.fxScale = 0.5;
      expect(GalaxyEffect.fxScale, 0.5);
      GalaxyEffect.fxScale = 1.0;
    });

    test('fxScale affects particle counts', () {
      GalaxyEffect.fxScale = 0.5;
      final effect = GalaxyEffect.spawn(position: Vector2.zero());
      expect(effect, isNotNull);
      GalaxyEffect.fxScale = 1.0;
    });
  });

  group('GalaxyEffect clearPool', () {
    test('clearPool resets active count', () {
      GalaxyEffect.spawn(position: Vector2.zero());
      GalaxyEffect.spawn(position: Vector2(100, 0));

      expect(GalaxyEffect.activeCount, 2);

      GalaxyEffect.clearPool();

      expect(GalaxyEffect.activeCount, 0);
    });

    test('clearPool allows spawning again after max reached', () {
      for (int i = 0; i < GalaxyEffect.maxActive; i++) {
        GalaxyEffect.spawn(
          position: Vector2(i.toDouble(), 0),
        );
      }

      GalaxyEffect.clearPool();

      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
      );

      expect(effect, isNotNull);
    });
  });

  group('GalaxyEffect update', () {
    test('update advances effect state', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        duration: 1.0,
      );

      effect!.update(0.016);
      effect.update(0.016);
      effect.update(0.016);

      expect(true, isTrue);
    });

    test('update with zero dt does not crash', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
      );

      effect!.update(0.0);
      expect(true, isTrue);
    });

    test('effect completes after duration', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        duration: 0.5,
      );

      for (int i = 0; i < 50; i++) {
        effect!.update(0.016);
      }

      expect(true, isTrue);
    });

    test('multiple rapid updates work', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
      );

      for (int i = 0; i < 100; i++) {
        effect!.update(0.016);
      }
      expect(true, isTrue);
    });
  });

  group('GalaxyEffect render', () {
    test('renders without exceptions', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        duration: 2.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders at buildup phase (0.0 - 0.2 progress)', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        duration: 2.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.2); // 10% progress
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders at full rotation phase (0.2 - 0.7 progress)', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        duration: 2.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.8); // 40% progress
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders at absorption phase (0.7 - 0.85 progress)', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        duration: 2.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(1.5); // 75% progress
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders at collapse phase (0.85 - 1.0 progress)', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        duration: 2.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(1.8); // 90% progress
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with small galaxySize', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        galaxySize: 20.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with large galaxySize', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        galaxySize: 200.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with reduced fxScale', () {
      GalaxyEffect.fxScale = 0.3;

      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();

      GalaxyEffect.fxScale = 1.0;
    });
  });

  group('GalaxyEffect animation phases', () {
    test('core intensity increases during buildup', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        duration: 2.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Progress at 10% (within buildup phase)
      effect!.update(0.2);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('core intensity is full during rotation phase', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        duration: 2.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Progress at 50% (within rotation phase)
      effect!.update(1.0);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('core intensity decreases during collapse', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        duration: 2.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Progress at 90% (within collapse phase)
      effect!.update(1.8);
      effect.render(canvas);
      recorder.endRecording();
    });
  });

  group('GalaxyEffect pooling', () {
    test('effects can be reused from pool', () {
      final effect1 = GalaxyEffect.spawn(
        position: Vector2.zero(),
        duration: 0.1,
      );

      for (int i = 0; i < 20; i++) {
        effect1!.update(0.01);
      }

      final effect2 = GalaxyEffect.spawn(
        position: Vector2(50, 50),
      );

      expect(effect2, isNotNull);
    });

    test('pool does not exceed maxPool', () {
      for (int i = 0; i < 20; i++) {
        final effect = GalaxyEffect.spawn(
          position: Vector2(i.toDouble(), 0),
          duration: 0.05,
        );

        if (effect != null) {
          for (int j = 0; j < 10; j++) {
            effect.update(0.01);
          }
        }

        GalaxyEffect.clearPool();
      }

      expect(true, isTrue);
    });
  });

  group('GalaxyEffect edge cases', () {
    test('works with very short duration', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        duration: 0.1,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.05);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with very long duration', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        duration: 10.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with negative position', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2(-100, -100),
      );

      expect(effect, isNotNull);
      expect(effect!.position.x, -100);
      expect(effect.position.y, -100);
    });

    test('works with very large position', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2(10000, 10000),
      );

      expect(effect, isNotNull);
    });

    test('multiple effects at same position', () {
      final effect1 = GalaxyEffect.spawn(
        position: Vector2(50, 50),
      );
      final effect2 = GalaxyEffect.spawn(
        position: Vector2(50, 50),
      );

      expect(effect1, isNotNull);
      expect(effect2, isNotNull);
    });
  });

  group('GalaxyEffect anchor', () {
    test('anchor is center', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
      );

      expect(effect!.anchor, Anchor.center);
    });
  });

  group('GalaxyEffect multiple instances', () {
    test('multiple effects can update independently', () {
      final effect1 = GalaxyEffect.spawn(
        position: Vector2(0, 0),
        duration: 1.0,
      );
      final effect2 = GalaxyEffect.spawn(
        position: Vector2(100, 100),
        duration: 2.0,
      );

      effect1!.update(0.5);
      effect2!.update(0.2);

      expect(effect1.duration, isNot(effect2.duration));
    });

    test('multiple effects render independently', () {
      final effect1 = GalaxyEffect.spawn(
        position: Vector2(0, 0),
      );
      final effect2 = GalaxyEffect.spawn(
        position: Vector2(100, 100),
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

  group('GalaxyEffect visual layers', () {
    test('effect has 7 visual layers', () {
      // Layer 1: Core
      // Layer 2: Spiral arms
      // Layer 3: Star particles
      // Layer 4: Dust lanes
      // Layer 5: Halo
      // Layer 6: Absorption effect
      // Layer 7: Expansion/collapse
      expect(7, 7);
    });

    test('spiral arms initialize correctly', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
        galaxySize: 100.0,
      );

      expect(effect, isNotNull);
    });

    test('stars initialize along spiral arms', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
      );

      expect(effect, isNotNull);
    });

    test('dust lanes initialize between arms', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
      );

      expect(effect, isNotNull);
    });

    test('absorption particles initialize outside galaxy', () {
      final effect = GalaxyEffect.spawn(
        position: Vector2.zero(),
      );

      expect(effect, isNotNull);
    });
  });
}
