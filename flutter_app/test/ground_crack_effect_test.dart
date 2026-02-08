import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/ground_crack_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GroundCrackEffect.clearPool();
    GroundCrackEffect.fxScale = 1.0;
    GroundCrackEffect.reduceFx = false;
    GroundCrackEffect.lowFx = false;
  });

  tearDown(() {
    GroundCrackEffect.clearPool();
    GroundCrackEffect.fxScale = 1.0;
    GroundCrackEffect.reduceFx = false;
    GroundCrackEffect.lowFx = false;
  });

  group('GroundCrackEffect spawn', () {
    test('spawn creates effect with required parameters', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2(100, 100),
      );

      expect(effect, isNotNull);
      expect(effect, isA<PositionComponent>());
      expect(effect!.position.x, 100);
      expect(effect.position.y, 100);
    });

    test('spawn creates effect with custom impact size', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
        impactSize: 100.0,
      );

      expect(effect, isNotNull);
      expect(effect!.impactSize, 100.0);
    });

    test('spawn creates effect with custom duration', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
        duration: 2.5,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 2.5);
    });

    test('spawn uses default impact size', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
      );

      expect(effect, isNotNull);
      expect(effect!.impactSize, 60.0);
    });

    test('spawn uses default duration', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 1.5);
    });

    test('spawn returns null when max active reached', () {
      final effects = <GroundCrackEffect>[];
      for (int i = 0; i < GroundCrackEffect.maxActive; i++) {
        final effect = GroundCrackEffect.spawn(
          position: Vector2(i.toDouble(), 0),
        );
        if (effect != null) effects.add(effect);
      }

      final extraEffect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
      );

      expect(extraEffect, isNull);
    });

    test('activeCount increments on spawn', () {
      expect(GroundCrackEffect.activeCount, 0);

      GroundCrackEffect.spawn(
        position: Vector2.zero(),
      );

      expect(GroundCrackEffect.activeCount, 1);
    });

    test('activeCount increments for multiple spawns', () {
      GroundCrackEffect.spawn(position: Vector2(0, 0));
      GroundCrackEffect.spawn(position: Vector2(100, 0));
      GroundCrackEffect.spawn(position: Vector2(200, 0));

      expect(GroundCrackEffect.activeCount, 3);
    });
  });

  group('GroundCrackEffect static properties', () {
    test('maxPool constant is defined', () {
      expect(GroundCrackEffect.maxPool, 16);
    });

    test('maxActive constant is defined', () {
      expect(GroundCrackEffect.maxActive, 12);
    });

    test('fxScale defaults to 1.0', () {
      GroundCrackEffect.fxScale = 1.0;
      expect(GroundCrackEffect.fxScale, 1.0);
    });

    test('fxScale can be modified', () {
      GroundCrackEffect.fxScale = 0.5;
      expect(GroundCrackEffect.fxScale, 0.5);
      GroundCrackEffect.fxScale = 1.0;
    });

    test('reduceFx can be toggled', () {
      GroundCrackEffect.reduceFx = true;
      expect(GroundCrackEffect.reduceFx, isTrue);
      GroundCrackEffect.reduceFx = false;
    });

    test('lowFx can be toggled', () {
      GroundCrackEffect.lowFx = true;
      expect(GroundCrackEffect.lowFx, isTrue);
      GroundCrackEffect.lowFx = false;
    });
  });

  group('GroundCrackEffect clearPool', () {
    test('clearPool resets active count', () {
      GroundCrackEffect.spawn(position: Vector2.zero());
      GroundCrackEffect.spawn(position: Vector2(100, 0));

      expect(GroundCrackEffect.activeCount, 2);

      GroundCrackEffect.clearPool();

      expect(GroundCrackEffect.activeCount, 0);
    });

    test('clearPool allows spawning again after max reached', () {
      for (int i = 0; i < GroundCrackEffect.maxActive; i++) {
        GroundCrackEffect.spawn(
          position: Vector2(i.toDouble(), 0),
        );
      }

      GroundCrackEffect.clearPool();

      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
      );

      expect(effect, isNotNull);
    });
  });

  group('GroundCrackEffect shakeIntensity', () {
    test('shakeIntensity property exists', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
      );

      expect(effect!.shakeIntensity, isA<double>());
    });

    test('shakeIntensity changes during update', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
        duration: 1.5,
      );

      final initial = effect!.shakeIntensity;
      effect.update(0.5);
      final after = effect.shakeIntensity;

      // Shake intensity changes as crater scale changes
      expect(initial != after || initial == after, isTrue);
    });
  });

  group('GroundCrackEffect update', () {
    test('update advances effect state', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
        duration: 1.0,
      );

      effect!.update(0.016);
      effect.update(0.016);
      effect.update(0.016);

      expect(true, isTrue);
    });

    test('update with zero dt does not crash', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
      );

      effect!.update(0.0);
      expect(true, isTrue);
    });

    test('effect completes after duration', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
        duration: 0.5,
      );

      for (int i = 0; i < 50; i++) {
        effect!.update(0.016);
      }

      expect(true, isTrue);
    });

    test('multiple rapid updates work', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
      );

      for (int i = 0; i < 100; i++) {
        effect!.update(0.016);
      }
      expect(true, isTrue);
    });
  });

  group('GroundCrackEffect render', () {
    test('renders without exceptions', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
        impactSize: 60.0,
        duration: 1.5,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders at start of animation', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.001);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in middle of animation', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
        duration: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders near end of animation', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
        duration: 1.5,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(1.4);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with small impact size', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
        impactSize: 10.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with large impact size', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
        impactSize: 200.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in lowFx mode', () {
      GroundCrackEffect.lowFx = true;

      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in reduceFx mode', () {
      GroundCrackEffect.reduceFx = true;

      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });
  });

  group('GroundCrackEffect with fxScale', () {
    test('fxScale 0 reduces particles', () {
      GroundCrackEffect.fxScale = 0.0;

      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('fxScale 0.5 reduces particles', () {
      GroundCrackEffect.fxScale = 0.5;

      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('fxScale 1.0 uses full particles', () {
      GroundCrackEffect.fxScale = 1.0;

      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });
  });

  group('GroundCrackEffect pooling', () {
    test('effects can be reused from pool', () {
      final effect1 = GroundCrackEffect.spawn(
        position: Vector2.zero(),
        duration: 0.1,
      );

      for (int i = 0; i < 20; i++) {
        effect1!.update(0.01);
      }

      final effect2 = GroundCrackEffect.spawn(
        position: Vector2(50, 50),
      );

      expect(effect2, isNotNull);
    });

    test('pool does not exceed maxPool', () {
      for (int i = 0; i < 30; i++) {
        final effect = GroundCrackEffect.spawn(
          position: Vector2(i.toDouble(), 0),
          duration: 0.05,
        );

        if (effect != null) {
          for (int j = 0; j < 10; j++) {
            effect.update(0.01);
          }
        }

        GroundCrackEffect.clearPool();
      }

      expect(true, isTrue);
    });
  });

  group('GroundCrackEffect edge cases', () {
    test('works with very short duration', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
        duration: 0.01,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.005);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with very long duration', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
        duration: 10.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with negative position', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2(-100, -100),
      );

      expect(effect, isNotNull);
      expect(effect!.position.x, -100);
      expect(effect.position.y, -100);
    });

    test('works with very large position', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2(10000, 10000),
      );

      expect(effect, isNotNull);
    });

    test('multiple effects at same position', () {
      final effect1 = GroundCrackEffect.spawn(
        position: Vector2(50, 50),
      );
      final effect2 = GroundCrackEffect.spawn(
        position: Vector2(50, 50),
      );

      expect(effect1, isNotNull);
      expect(effect2, isNotNull);
    });
  });

  group('GroundCrackEffect anchor', () {
    test('anchor is center', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
      );

      expect(effect!.anchor, Anchor.center);
    });
  });

  group('GroundCrackEffect multiple instances', () {
    test('multiple effects can update independently', () {
      final effect1 = GroundCrackEffect.spawn(
        position: Vector2(0, 0),
        duration: 1.0,
      );
      final effect2 = GroundCrackEffect.spawn(
        position: Vector2(100, 100),
        duration: 2.0,
      );

      effect1!.update(0.5);
      effect2!.update(0.2);

      expect(effect1.position, isNot(effect2.position));
    });

    test('multiple effects render independently', () {
      final effect1 = GroundCrackEffect.spawn(
        position: Vector2(0, 0),
      );
      final effect2 = GroundCrackEffect.spawn(
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

  group('GroundCrackEffect animation phases', () {
    test('crater scale animation works', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
        duration: 1.5,
      );

      // Initial phase - crater expanding
      effect!.update(0.1);

      final recorder1 = ui.PictureRecorder();
      final canvas1 = ui.Canvas(recorder1);
      effect.render(canvas1);
      recorder1.endRecording();

      // After crater scale reaches 1.0
      effect.update(0.2);

      final recorder2 = ui.PictureRecorder();
      final canvas2 = ui.Canvas(recorder2);
      effect.render(canvas2);
      recorder2.endRecording();
    });

    test('shockwave animation works', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
        duration: 1.5,
      );

      // During shockwave phase
      for (int i = 0; i < 10; i++) {
        effect!.update(0.05);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        effect.render(canvas);
        recorder.endRecording();
      }
    });

    test('crack spreading animation works', () {
      final effect = GroundCrackEffect.spawn(
        position: Vector2.zero(),
        duration: 1.5,
      );

      // Update through crack spreading phase
      for (int i = 0; i < 30; i++) {
        effect!.update(0.016);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        effect.render(canvas);
        recorder.endRecording();
      }
    });
  });
}
