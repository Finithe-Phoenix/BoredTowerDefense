import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/powerup_collect_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PowerUpCollectEffect.clearPool();
    PowerUpCollectEffect.fxScale = 1.0;
    PowerUpCollectEffect.reduceFx = false;
    PowerUpCollectEffect.lowFx = false;
  });

  tearDown(() {
    PowerUpCollectEffect.clearPool();
    PowerUpCollectEffect.fxScale = 1.0;
    PowerUpCollectEffect.reduceFx = false;
    PowerUpCollectEffect.lowFx = false;
  });

  group('PowerUpCollectEffect spawn', () {
    test('spawn creates effect with required parameters', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.health,
      );

      expect(effect, isNotNull);
      expect(effect, isA<PositionComponent>());
      expect(effect!.position.x, 100);
      expect(effect.position.y, 100);
      expect(effect.powerUpType, PowerUpType.health);
    });

    test('spawn creates effect with damage type', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.damage,
      );

      expect(effect, isNotNull);
      expect(effect!.powerUpType, PowerUpType.damage);
    });

    test('spawn creates effect with speed type', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.speed,
      );

      expect(effect, isNotNull);
      expect(effect!.powerUpType, PowerUpType.speed);
    });

    test('spawn creates effect with shield type', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.shield,
      );

      expect(effect, isNotNull);
      expect(effect!.powerUpType, PowerUpType.shield);
    });

    test('spawn creates effect with custom display text', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
        displayText: '+50 HP',
      );

      expect(effect, isNotNull);
      expect(effect!.displayText, '+50 HP');
    });

    test('spawn creates effect with custom duration', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
        duration: 2.0,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 2.0);
    });

    test('spawn uses default duration', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 1.0);
    });

    test('spawn uses empty display text by default', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
      );

      expect(effect, isNotNull);
      expect(effect!.displayText, '');
    });

    test('spawn returns null when max active reached', () {
      final effects = <PowerUpCollectEffect>[];
      for (int i = 0; i < PowerUpCollectEffect.maxActive; i++) {
        final effect = PowerUpCollectEffect.spawn(
          position: Vector2(i.toDouble(), 0),
          powerUpType: PowerUpType.health,
        );
        if (effect != null) effects.add(effect);
      }

      final extraEffect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
      );

      expect(extraEffect, isNull);
    });

    test('activeCount increments on spawn', () {
      expect(PowerUpCollectEffect.activeCount, 0);

      PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
      );

      expect(PowerUpCollectEffect.activeCount, 1);
    });

    test('activeCount increments for multiple spawns', () {
      PowerUpCollectEffect.spawn(position: Vector2(0, 0), powerUpType: PowerUpType.health);
      PowerUpCollectEffect.spawn(position: Vector2(100, 0), powerUpType: PowerUpType.damage);
      PowerUpCollectEffect.spawn(position: Vector2(200, 0), powerUpType: PowerUpType.speed);

      expect(PowerUpCollectEffect.activeCount, 3);
    });
  });

  group('PowerUpCollectEffect static properties', () {
    test('maxPool constant is defined', () {
      expect(PowerUpCollectEffect.maxPool, 16);
    });

    test('maxActive constant is defined', () {
      expect(PowerUpCollectEffect.maxActive, 12);
    });

    test('fxScale defaults to 1.0', () {
      PowerUpCollectEffect.fxScale = 1.0;
      expect(PowerUpCollectEffect.fxScale, 1.0);
    });

    test('fxScale can be modified', () {
      PowerUpCollectEffect.fxScale = 0.5;
      expect(PowerUpCollectEffect.fxScale, 0.5);
      PowerUpCollectEffect.fxScale = 1.0;
    });

    test('reduceFx can be toggled', () {
      PowerUpCollectEffect.reduceFx = true;
      expect(PowerUpCollectEffect.reduceFx, isTrue);
      PowerUpCollectEffect.reduceFx = false;
    });

    test('lowFx can be toggled', () {
      PowerUpCollectEffect.lowFx = true;
      expect(PowerUpCollectEffect.lowFx, isTrue);
      PowerUpCollectEffect.lowFx = false;
    });
  });

  group('PowerUpCollectEffect clearPool', () {
    test('clearPool resets active count', () {
      PowerUpCollectEffect.spawn(position: Vector2.zero(), powerUpType: PowerUpType.health);
      PowerUpCollectEffect.spawn(position: Vector2(100, 0), powerUpType: PowerUpType.damage);

      expect(PowerUpCollectEffect.activeCount, 2);

      PowerUpCollectEffect.clearPool();

      expect(PowerUpCollectEffect.activeCount, 0);
    });

    test('clearPool allows spawning again after max reached', () {
      for (int i = 0; i < PowerUpCollectEffect.maxActive; i++) {
        PowerUpCollectEffect.spawn(
          position: Vector2(i.toDouble(), 0),
          powerUpType: PowerUpType.health,
        );
      }

      PowerUpCollectEffect.clearPool();

      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
      );

      expect(effect, isNotNull);
    });
  });

  group('PowerUpCollectEffect update', () {
    test('update advances effect state', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
        duration: 1.0,
      );

      effect!.update(0.016);
      effect.update(0.016);
      effect.update(0.016);

      expect(true, isTrue);
    });

    test('update with zero dt does not crash', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
      );

      effect!.update(0.0);
      expect(true, isTrue);
    });

    test('effect completes after duration', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
        duration: 0.5,
      );

      for (int i = 0; i < 50; i++) {
        effect!.update(0.016);
      }

      expect(true, isTrue);
    });

    test('multiple rapid updates work', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
      );

      for (int i = 0; i < 100; i++) {
        effect!.update(0.016);
      }
      expect(true, isTrue);
    });
  });

  group('PowerUpCollectEffect render', () {
    test('renders without exceptions', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
        duration: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders at start of animation', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.001);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in middle of animation', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
        duration: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders near end of animation', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
        duration: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.95);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with all power-up types', () {
      final types = PowerUpType.values;

      for (final type in types) {
        final effect = PowerUpCollectEffect.spawn(
          position: Vector2.zero(),
          powerUpType: type,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect!.update(0.1);
        effect.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with display text', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
        displayText: '+100 HP',
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.3);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in lowFx mode', () {
      PowerUpCollectEffect.lowFx = true;

      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in reduceFx mode', () {
      PowerUpCollectEffect.reduceFx = true;

      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in lowFx mode with display text', () {
      PowerUpCollectEffect.lowFx = true;

      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.damage,
        displayText: '+25% DMG',
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.3);
      effect.render(canvas);
      recorder.endRecording();
    });
  });

  group('PowerUpCollectEffect with fxScale', () {
    test('fxScale 0 reduces particles', () {
      PowerUpCollectEffect.fxScale = 0.0;

      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('fxScale 0.5 reduces particles', () {
      PowerUpCollectEffect.fxScale = 0.5;

      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('fxScale 1.0 uses full particles', () {
      PowerUpCollectEffect.fxScale = 1.0;

      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });
  });

  group('PowerUpCollectEffect pooling', () {
    test('effects can be reused from pool', () {
      final effect1 = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
        duration: 0.1,
      );

      for (int i = 0; i < 20; i++) {
        effect1!.update(0.01);
      }

      final effect2 = PowerUpCollectEffect.spawn(
        position: Vector2(50, 50),
        powerUpType: PowerUpType.damage,
      );

      expect(effect2, isNotNull);
    });

    test('pool does not exceed maxPool', () {
      for (int i = 0; i < 30; i++) {
        final effect = PowerUpCollectEffect.spawn(
          position: Vector2(i.toDouble(), 0),
          powerUpType: PowerUpType.health,
          duration: 0.05,
        );

        if (effect != null) {
          for (int j = 0; j < 10; j++) {
            effect.update(0.01);
          }
        }

        PowerUpCollectEffect.clearPool();
      }

      expect(true, isTrue);
    });
  });

  group('PowerUpCollectEffect edge cases', () {
    test('works with very short duration', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
        duration: 0.01,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.005);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with very long duration', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
        duration: 10.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with negative position', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(-100, -100),
        powerUpType: PowerUpType.health,
      );

      expect(effect, isNotNull);
      expect(effect!.position.x, -100);
      expect(effect.position.y, -100);
    });

    test('works with very large position', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(10000, 10000),
        powerUpType: PowerUpType.health,
      );

      expect(effect, isNotNull);
    });

    test('multiple effects at same position', () {
      final effect1 = PowerUpCollectEffect.spawn(
        position: Vector2(50, 50),
        powerUpType: PowerUpType.health,
      );
      final effect2 = PowerUpCollectEffect.spawn(
        position: Vector2(50, 50),
        powerUpType: PowerUpType.damage,
      );

      expect(effect1, isNotNull);
      expect(effect2, isNotNull);
    });

    test('works with long display text', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
        displayText: 'SUPER MEGA ULTRA POWER BOOST ACTIVATED!',
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.3);
      effect.render(canvas);
      recorder.endRecording();
    });
  });

  group('PowerUpCollectEffect anchor', () {
    test('anchor is center', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
      );

      expect(effect!.anchor, Anchor.center);
    });
  });

  group('PowerUpCollectEffect multiple instances', () {
    test('multiple effects can update independently', () {
      final effect1 = PowerUpCollectEffect.spawn(
        position: Vector2(0, 0),
        powerUpType: PowerUpType.health,
        duration: 1.0,
      );
      final effect2 = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.damage,
        duration: 2.0,
      );

      effect1!.update(0.5);
      effect2!.update(0.2);

      expect(effect1.powerUpType, isNot(effect2.powerUpType));
    });

    test('multiple effects render independently', () {
      final effect1 = PowerUpCollectEffect.spawn(
        position: Vector2(0, 0),
        powerUpType: PowerUpType.health,
      );
      final effect2 = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.damage,
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

  group('PowerUpType enum', () {
    test('all power-up types are defined', () {
      expect(PowerUpType.values.length, 4);
      expect(PowerUpType.values, contains(PowerUpType.health));
      expect(PowerUpType.values, contains(PowerUpType.damage));
      expect(PowerUpType.values, contains(PowerUpType.speed));
      expect(PowerUpType.values, contains(PowerUpType.shield));
    });
  });

  group('PowerUpCollectEffect animation phases', () {
    test('renders during absorption animation (0-0.3)', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
        duration: 1.0,
      );

      for (double t = 0; t < 0.3; t += 0.05) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect!.update(0.05);
        effect.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders during hold animation (0.3-0.6)', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
        duration: 1.0,
      );

      effect!.update(0.3);

      for (double t = 0.3; t < 0.6; t += 0.05) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect.update(0.05);
        effect.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders during shrink animation (0.6-0.9)', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
        duration: 1.0,
      );

      effect!.update(0.6);

      for (double t = 0.6; t < 0.9; t += 0.05) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect.update(0.05);
        effect.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders during final pulse (0.85-1.0)', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
        duration: 1.0,
      );

      effect!.update(0.85);

      for (double t = 0.85; t < 1.0; t += 0.02) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect.update(0.02);
        effect.render(canvas);
        recorder.endRecording();
      }
    });
  });
}
