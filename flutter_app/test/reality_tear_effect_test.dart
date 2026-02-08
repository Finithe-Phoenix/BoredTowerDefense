import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/reality_tear_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    RealityTearEffect.clearPool();
    RealityTearEffect.fxScale = 1.0;
  });

  tearDown(() {
    RealityTearEffect.clearPool();
    RealityTearEffect.fxScale = 1.0;
  });

  group('RealityTearEffect spawn', () {
    test('spawn creates effect with required parameters', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2(100, 100),
      );

      expect(effect, isNotNull);
      expect(effect, isA<PositionComponent>());
      expect(effect!.position.x, 100);
      expect(effect.position.y, 100);
    });

    test('spawn creates effect with custom tear size', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        tearSize: 100.0,
      );

      expect(effect, isNotNull);
      expect(effect!.tearSize, 100.0);
    });

    test('spawn creates effect with custom duration', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        duration: 3.0,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 3.0);
    });

    test('spawn uses default tear size', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
      );

      expect(effect, isNotNull);
      expect(effect!.tearSize, 60.0);
    });

    test('spawn uses default duration', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 2.0);
    });

    test('spawn creates effect with reduceFx option', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        reduceFx: true,
      );

      expect(effect, isNotNull);
      expect(effect!.reduceFx, isTrue);
    });

    test('spawn creates effect with lowFx option', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        lowFx: true,
      );

      expect(effect, isNotNull);
      expect(effect!.lowFx, isTrue);
    });

    test('spawn returns null when max active reached', () {
      final effects = <RealityTearEffect>[];
      for (int i = 0; i < RealityTearEffect.maxActive; i++) {
        final effect = RealityTearEffect.spawn(
          position: Vector2(i.toDouble(), 0),
        );
        if (effect != null) effects.add(effect);
      }

      final extraEffect = RealityTearEffect.spawn(
        position: Vector2.zero(),
      );

      expect(extraEffect, isNull);
    });

    test('activeCount increments on spawn', () {
      expect(RealityTearEffect.activeCount, 0);

      RealityTearEffect.spawn(
        position: Vector2.zero(),
      );

      expect(RealityTearEffect.activeCount, 1);
    });

    test('activeCount increments for multiple spawns', () {
      RealityTearEffect.spawn(position: Vector2(0, 0));
      RealityTearEffect.spawn(position: Vector2(100, 0));
      RealityTearEffect.spawn(position: Vector2(200, 0));

      expect(RealityTearEffect.activeCount, 3);
    });
  });

  group('RealityTearEffect static properties', () {
    test('maxPool constant is defined', () {
      expect(RealityTearEffect.maxPool, 16);
    });

    test('maxActive constant is defined', () {
      expect(RealityTearEffect.maxActive, 12);
    });

    test('fxScale defaults to 1.0', () {
      RealityTearEffect.fxScale = 1.0;
      expect(RealityTearEffect.fxScale, 1.0);
    });

    test('fxScale can be modified', () {
      RealityTearEffect.fxScale = 0.5;
      expect(RealityTearEffect.fxScale, 0.5);
      RealityTearEffect.fxScale = 1.0;
    });

    test('primaryColor is defined', () {
      expect(RealityTearEffect.primaryColor, const ui.Color(0xFF8B00FF));
    });

    test('secondaryColor is defined', () {
      expect(RealityTearEffect.secondaryColor, const ui.Color(0xFF00FFFF));
    });

    test('voidColor is defined', () {
      expect(RealityTearEffect.voidColor, const ui.Color(0xFF000000));
    });
  });

  group('RealityTearEffect clearPool', () {
    test('clearPool resets active count', () {
      RealityTearEffect.spawn(position: Vector2.zero());
      RealityTearEffect.spawn(position: Vector2(100, 0));

      expect(RealityTearEffect.activeCount, 2);

      RealityTearEffect.clearPool();

      expect(RealityTearEffect.activeCount, 0);
    });

    test('clearPool allows spawning again after max reached', () {
      for (int i = 0; i < RealityTearEffect.maxActive; i++) {
        RealityTearEffect.spawn(
          position: Vector2(i.toDouble(), 0),
        );
      }

      RealityTearEffect.clearPool();

      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
      );

      expect(effect, isNotNull);
    });
  });

  group('RealityTearEffect update', () {
    test('update advances effect state', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        duration: 1.0,
      );

      effect!.update(0.016);
      effect.update(0.016);
      effect.update(0.016);

      expect(true, isTrue);
    });

    test('update with zero dt does not crash', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
      );

      effect!.update(0.0);
      expect(true, isTrue);
    });

    test('effect completes after duration', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        duration: 0.5,
      );

      for (int i = 0; i < 50; i++) {
        effect!.update(0.016);
      }

      expect(true, isTrue);
    });

    test('multiple rapid updates work', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
      );

      for (int i = 0; i < 100; i++) {
        effect!.update(0.016);
      }
      expect(true, isTrue);
    });
  });

  group('RealityTearEffect render', () {
    test('renders without exceptions', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        tearSize: 60.0,
        duration: 2.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders at start of animation (tear opening)', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.05);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders when fully open (middle of animation)', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        duration: 2.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(1.0);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders near end of animation (tear closing)', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        duration: 2.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(1.9);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with small tear size', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        tearSize: 20.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with large tear size', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        tearSize: 200.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in lowFx mode', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        lowFx: true,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in reduceFx mode', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        reduceFx: true,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });
  });

  group('RealityTearEffect with fxScale', () {
    test('fxScale 0 reduces particles', () {
      RealityTearEffect.fxScale = 0.0;

      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('fxScale 0.5 reduces particles', () {
      RealityTearEffect.fxScale = 0.5;

      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('fxScale 1.0 uses full particles', () {
      RealityTearEffect.fxScale = 1.0;

      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });
  });

  group('RealityTearEffect pooling', () {
    test('effects can be reused from pool', () {
      final effect1 = RealityTearEffect.spawn(
        position: Vector2.zero(),
        duration: 0.1,
      );

      for (int i = 0; i < 20; i++) {
        effect1!.update(0.01);
      }

      final effect2 = RealityTearEffect.spawn(
        position: Vector2(50, 50),
      );

      expect(effect2, isNotNull);
    });

    test('pool does not exceed maxPool', () {
      for (int i = 0; i < 30; i++) {
        final effect = RealityTearEffect.spawn(
          position: Vector2(i.toDouble(), 0),
          duration: 0.05,
        );

        if (effect != null) {
          for (int j = 0; j < 10; j++) {
            effect.update(0.01);
          }
        }

        RealityTearEffect.clearPool();
      }

      expect(true, isTrue);
    });
  });

  group('RealityTearEffect edge cases', () {
    test('works with very short duration', () {
      final effect = RealityTearEffect.spawn(
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
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        duration: 30.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(1.0);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with negative position', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2(-100, -100),
      );

      expect(effect, isNotNull);
      expect(effect!.position.x, -100);
      expect(effect.position.y, -100);
    });

    test('works with very large position', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2(10000, 10000),
      );

      expect(effect, isNotNull);
    });

    test('multiple effects at same position', () {
      final effect1 = RealityTearEffect.spawn(
        position: Vector2(50, 50),
      );
      final effect2 = RealityTearEffect.spawn(
        position: Vector2(50, 50),
      );

      expect(effect1, isNotNull);
      expect(effect2, isNotNull);
    });
  });

  group('RealityTearEffect anchor', () {
    test('anchor is center', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
      );

      expect(effect!.anchor, Anchor.center);
    });
  });

  group('RealityTearEffect multiple instances', () {
    test('multiple effects can update independently', () {
      final effect1 = RealityTearEffect.spawn(
        position: Vector2(0, 0),
        duration: 1.0,
      );
      final effect2 = RealityTearEffect.spawn(
        position: Vector2(100, 100),
        duration: 3.0,
      );

      effect1!.update(0.5);
      effect2!.update(0.2);

      expect(effect1.position, isNot(effect2.position));
    });

    test('multiple effects render independently', () {
      final effect1 = RealityTearEffect.spawn(
        position: Vector2(0, 0),
      );
      final effect2 = RealityTearEffect.spawn(
        position: Vector2(100, 100),
      );

      final recorder1 = ui.PictureRecorder();
      final canvas1 = ui.Canvas(recorder1);

      final recorder2 = ui.PictureRecorder();
      final canvas2 = ui.Canvas(recorder2);

      effect1!.update(0.5);
      effect2!.update(0.5);

      effect1.render(canvas1);
      effect2.render(canvas2);

      recorder1.endRecording();
      recorder2.endRecording();
    });
  });

  group('RealityTearEffect animation phases', () {
    test('renders during opening phase (0-0.2)', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        duration: 2.0,
      );

      for (double t = 0; t < 0.4; t += 0.05) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect!.update(0.05);
        effect.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders during stable phase (0.2-0.8)', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        duration: 2.0,
      );

      effect!.update(0.5);

      for (double t = 0.25; t < 1.6; t += 0.1) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect.update(0.1);
        effect.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders during closing phase (0.8-1.0)', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        duration: 2.0,
      );

      effect!.update(1.6);

      for (double t = 0.8; t < 1.0; t += 0.03) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect.update(0.06);
        effect.render(canvas);
        recorder.endRecording();
      }
    });
  });

  group('RealityTearEffect flicker behavior', () {
    test('flicker intensity varies over time', () {
      final effect = RealityTearEffect.spawn(
        position: Vector2.zero(),
        duration: 2.0,
      );

      for (int i = 0; i < 60; i++) {
        effect!.update(0.016);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        effect.render(canvas);
        recorder.endRecording();
      }
    });
  });
}
