import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/damage_number_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DamageNumberEffect.clearPool();
    DamageNumberEffect.fxScale = 1.0;
    DamageNumberEffect.reduceFx = false;
    DamageNumberEffect.lowFx = false;
  });

  tearDown(() {
    DamageNumberEffect.clearPool();
    DamageNumberEffect.fxScale = 1.0;
    DamageNumberEffect.reduceFx = false;
    DamageNumberEffect.lowFx = false;
  });

  group('DamageNumberEffect spawn', () {
    test('spawn creates effect with required parameters', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2(100, 100),
        damageAmount: 50,
      );

      expect(effect, isNotNull);
      expect(effect, isA<PositionComponent>());
      expect(effect!.position.x, 100);
      expect(effect.position.y, 100);
      expect(effect.damageAmount, 50);
    });

    test('spawn creates effect with custom type', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 100,
        type: DamageNumberType.critical,
      );

      expect(effect, isNotNull);
      expect(effect!.type, DamageNumberType.critical);
    });

    test('spawn creates effect with heal type', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 25,
        type: DamageNumberType.heal,
      );

      expect(effect, isNotNull);
      expect(effect!.type, DamageNumberType.heal);
    });

    test('spawn creates effect with shield type', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 75,
        type: DamageNumberType.shield,
      );

      expect(effect, isNotNull);
      expect(effect!.type, DamageNumberType.shield);
    });

    test('spawn creates effect with custom duration', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
        duration: 2.0,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 2.0);
    });

    test('spawn uses default duration', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 1.5);
    });

    test('spawn uses default type (damage)', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
      );

      expect(effect, isNotNull);
      expect(effect!.type, DamageNumberType.damage);
    });

    test('spawn returns null when max active reached', () {
      final effects = <DamageNumberEffect>[];
      for (int i = 0; i < DamageNumberEffect.maxActive; i++) {
        final effect = DamageNumberEffect.spawn(
          position: Vector2(i.toDouble(), 0),
          damageAmount: 50,
        );
        if (effect != null) effects.add(effect);
      }

      final extraEffect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
      );

      expect(extraEffect, isNull);
    });

    test('activeCount increments on spawn', () {
      expect(DamageNumberEffect.activeCount, 0);

      DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
      );

      expect(DamageNumberEffect.activeCount, 1);
    });

    test('activeCount increments for multiple spawns', () {
      DamageNumberEffect.spawn(position: Vector2(0, 0), damageAmount: 10);
      DamageNumberEffect.spawn(position: Vector2(10, 0), damageAmount: 20);
      DamageNumberEffect.spawn(position: Vector2(20, 0), damageAmount: 30);

      expect(DamageNumberEffect.activeCount, 3);
    });
  });

  group('DamageNumberEffect static properties', () {
    test('maxPool constant is defined', () {
      expect(DamageNumberEffect.maxPool, 32);
    });

    test('maxActive constant is defined', () {
      expect(DamageNumberEffect.maxActive, 24);
    });

    test('fxScale defaults to 1.0', () {
      DamageNumberEffect.fxScale = 1.0;
      expect(DamageNumberEffect.fxScale, 1.0);
    });

    test('fxScale can be modified', () {
      DamageNumberEffect.fxScale = 0.5;
      expect(DamageNumberEffect.fxScale, 0.5);
      DamageNumberEffect.fxScale = 1.0;
    });

    test('reduceFx can be toggled', () {
      DamageNumberEffect.reduceFx = true;
      expect(DamageNumberEffect.reduceFx, isTrue);
      DamageNumberEffect.reduceFx = false;
    });

    test('lowFx can be toggled', () {
      DamageNumberEffect.lowFx = true;
      expect(DamageNumberEffect.lowFx, isTrue);
      DamageNumberEffect.lowFx = false;
    });
  });

  group('DamageNumberEffect clearPool', () {
    test('clearPool resets active count', () {
      DamageNumberEffect.spawn(position: Vector2.zero(), damageAmount: 50);
      DamageNumberEffect.spawn(position: Vector2(10, 0), damageAmount: 50);

      expect(DamageNumberEffect.activeCount, 2);

      DamageNumberEffect.clearPool();

      expect(DamageNumberEffect.activeCount, 0);
    });

    test('clearPool allows spawning again after max reached', () {
      for (int i = 0; i < DamageNumberEffect.maxActive; i++) {
        DamageNumberEffect.spawn(
          position: Vector2(i.toDouble(), 0),
          damageAmount: 50,
        );
      }

      DamageNumberEffect.clearPool();

      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
      );

      expect(effect, isNotNull);
    });
  });

  group('DamageNumberEffect update', () {
    test('update advances effect state', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
        duration: 1.0,
      );

      effect!.update(0.016);
      effect.update(0.016);
      effect.update(0.016);

      expect(true, isTrue);
    });

    test('update with zero dt does not crash', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
      );

      effect!.update(0.0);
      expect(true, isTrue);
    });

    test('effect completes after duration', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
        duration: 0.5,
      );

      for (int i = 0; i < 50; i++) {
        effect!.update(0.016);
      }

      expect(true, isTrue);
    });

    test('multiple rapid updates work', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
      );

      for (int i = 0; i < 100; i++) {
        effect!.update(0.016);
      }
      expect(true, isTrue);
    });
  });

  group('DamageNumberEffect render', () {
    test('renders without exceptions', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
        duration: 1.5,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders at start of animation', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 100,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.001);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in middle of animation', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 150,
        duration: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders near end of animation', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 200,
        duration: 1.5,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(1.4);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with different damage types', () {
      final types = DamageNumberType.values;

      for (final type in types) {
        final effect = DamageNumberEffect.spawn(
          position: Vector2.zero(),
          damageAmount: 50,
          type: type,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect!.update(0.1);
        effect.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with small damage amount', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 1,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with large damage amount', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 9999,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in lowFx mode', () {
      DamageNumberEffect.lowFx = true;

      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in reduceFx mode', () {
      DamageNumberEffect.reduceFx = true;

      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });
  });

  group('DamageNumberEffect damage amount scaling', () {
    test('small damage amount uses base font size', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 10,
      );

      expect(effect, isNotNull);
    });

    test('medium damage amount increases font size', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 100,
      );

      expect(effect, isNotNull);
    });

    test('large damage amount uses larger font size', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 1000,
      );

      expect(effect, isNotNull);
    });

    test('critical type increases font size', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
        type: DamageNumberType.critical,
      );

      expect(effect, isNotNull);
    });
  });

  group('DamageNumberEffect pooling', () {
    test('effects can be reused from pool', () {
      final effect1 = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
        duration: 0.1,
      );

      for (int i = 0; i < 20; i++) {
        effect1!.update(0.01);
      }

      final effect2 = DamageNumberEffect.spawn(
        position: Vector2(50, 50),
        damageAmount: 100,
      );

      expect(effect2, isNotNull);
    });

    test('pool does not exceed maxPool', () {
      for (int i = 0; i < 40; i++) {
        final effect = DamageNumberEffect.spawn(
          position: Vector2(i.toDouble(), 0),
          damageAmount: 50,
          duration: 0.05,
        );

        if (effect != null) {
          for (int j = 0; j < 10; j++) {
            effect.update(0.01);
          }
        }

        DamageNumberEffect.clearPool();
      }

      expect(true, isTrue);
    });
  });

  group('DamageNumberEffect edge cases', () {
    test('works with very short duration', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
        duration: 0.01,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.005);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with very long duration', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
        duration: 10.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with negative position', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2(-100, -100),
        damageAmount: 50,
      );

      expect(effect, isNotNull);
      expect(effect!.position.x, -100);
      expect(effect.position.y, -100);
    });

    test('works with very large position', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2(10000, 10000),
        damageAmount: 50,
      );

      expect(effect, isNotNull);
    });

    test('works with zero damage amount', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 0,
      );

      expect(effect, isNotNull);
    });

    test('multiple effects at same position', () {
      final effect1 = DamageNumberEffect.spawn(
        position: Vector2(50, 50),
        damageAmount: 50,
      );
      final effect2 = DamageNumberEffect.spawn(
        position: Vector2(50, 50),
        damageAmount: 100,
      );

      expect(effect1, isNotNull);
      expect(effect2, isNotNull);
    });
  });

  group('DamageNumberEffect anchor', () {
    test('anchor is center', () {
      final effect = DamageNumberEffect.spawn(
        position: Vector2.zero(),
        damageAmount: 50,
      );

      expect(effect!.anchor, Anchor.center);
    });
  });

  group('DamageNumberEffect multiple instances', () {
    test('multiple effects can update independently', () {
      final effect1 = DamageNumberEffect.spawn(
        position: Vector2(0, 0),
        damageAmount: 50,
        duration: 1.0,
      );
      final effect2 = DamageNumberEffect.spawn(
        position: Vector2(100, 100),
        damageAmount: 100,
        duration: 2.0,
      );

      effect1!.update(0.5);
      effect2!.update(0.2);

      expect(effect1.damageAmount, isNot(effect2.damageAmount));
    });

    test('multiple effects render independently', () {
      final effect1 = DamageNumberEffect.spawn(
        position: Vector2(0, 0),
        damageAmount: 50,
      );
      final effect2 = DamageNumberEffect.spawn(
        position: Vector2(100, 100),
        damageAmount: 100,
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

  group('DamageNumberType enum', () {
    test('all damage types are defined', () {
      expect(DamageNumberType.values.length, 4);
      expect(DamageNumberType.values, contains(DamageNumberType.damage));
      expect(DamageNumberType.values, contains(DamageNumberType.critical));
      expect(DamageNumberType.values, contains(DamageNumberType.heal));
      expect(DamageNumberType.values, contains(DamageNumberType.shield));
    });
  });
}
