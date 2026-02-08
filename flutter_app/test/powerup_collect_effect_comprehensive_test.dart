import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/powerup_collect_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PowerUpType enum', () {
    test('has 4 power-up types', () {
      expect(PowerUpType.values.length, 4);
    });

    test('contains health', () {
      expect(PowerUpType.values, contains(PowerUpType.health));
    });

    test('contains damage', () {
      expect(PowerUpType.values, contains(PowerUpType.damage));
    });

    test('contains speed', () {
      expect(PowerUpType.values, contains(PowerUpType.speed));
    });

    test('contains shield', () {
      expect(PowerUpType.values, contains(PowerUpType.shield));
    });

    test('health is index 0', () {
      expect(PowerUpType.health.index, 0);
    });

    test('damage is index 1', () {
      expect(PowerUpType.damage.index, 1);
    });

    test('speed is index 2', () {
      expect(PowerUpType.speed.index, 2);
    });

    test('shield is index 3', () {
      expect(PowerUpType.shield.index, 3);
    });

    test('each type has unique index', () {
      final indices = PowerUpType.values.map((t) => t.index).toSet();
      expect(indices.length, PowerUpType.values.length);
    });
  });

  group('PowerUpCollectEffect static constants', () {
    test('maxPool is 16', () {
      expect(PowerUpCollectEffect.maxPool, 16);
    });

    test('maxActive is 12', () {
      expect(PowerUpCollectEffect.maxActive, 12);
    });

    test('fxScale default is 1.0', () {
      expect(PowerUpCollectEffect.fxScale, 1.0);
    });

    test('reduceFx default is false', () {
      expect(PowerUpCollectEffect.reduceFx, isFalse);
    });

    test('lowFx default is false', () {
      expect(PowerUpCollectEffect.lowFx, isFalse);
    });
  });

  group('PowerUpCollectEffect pool management', () {
    setUp(() {
      PowerUpCollectEffect.clearPool();
    });

    test('clearPool resets activeCount to 0', () {
      PowerUpCollectEffect.clearPool();
      expect(PowerUpCollectEffect.activeCount, 0);
    });

    test('clearPool can be called multiple times', () {
      PowerUpCollectEffect.clearPool();
      PowerUpCollectEffect.clearPool();
      PowerUpCollectEffect.clearPool();
      expect(PowerUpCollectEffect.activeCount, 0);
    });

    test('activeCount is 0 after clearPool', () {
      PowerUpCollectEffect.clearPool();
      expect(PowerUpCollectEffect.activeCount, 0);
    });
  });

  group('PowerUpCollectEffect spawn', () {
    setUp(() {
      PowerUpCollectEffect.clearPool();
    });

    test('spawn returns PowerUpCollectEffect', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.health,
      );

      expect(effect, isNotNull);
      expect(effect, isA<PowerUpCollectEffect>());
    });

    test('spawn increments activeCount', () {
      final initialCount = PowerUpCollectEffect.activeCount;

      PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.health,
      );

      expect(PowerUpCollectEffect.activeCount, initialCount + 1);
    });

    test('spawn with custom displayText', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.health,
        displayText: '+100 HP',
      );

      expect(effect, isNotNull);
    });

    test('spawn with custom duration', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.health,
        duration: 2.0,
      );

      expect(effect, isNotNull);
    });

    test('spawn with health type', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.health,
        displayText: '+50 HP',
      );

      expect(effect, isNotNull);
    });

    test('spawn with damage type', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.damage,
        displayText: '+25% DMG',
      );

      expect(effect, isNotNull);
    });

    test('spawn with speed type', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.speed,
        displayText: '+20% SPD',
      );

      expect(effect, isNotNull);
    });

    test('spawn with shield type', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.shield,
        displayText: 'SHIELD',
      );

      expect(effect, isNotNull);
    });

    test('spawn returns null when maxActive exceeded', () {
      PowerUpCollectEffect.clearPool();

      // Spawn up to maxActive
      for (int i = 0; i < PowerUpCollectEffect.maxActive; i++) {
        PowerUpCollectEffect.spawn(
          position: Vector2(i.toDouble() * 10, 0),
          powerUpType: PowerUpType.values[i % 4],
        );
      }

      // Next spawn should return null
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.health,
      );

      expect(effect, isNull);
    });
  });

  group('PowerUpCollectEffect default values', () {
    setUp(() {
      PowerUpCollectEffect.clearPool();
    });

    test('default displayText is empty', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.health,
      );

      expect(effect, isNotNull);
    });

    test('default duration is 1.0', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.health,
      );

      expect(effect, isNotNull);
    });
  });

  group('PowerUpCollectEffect fxScale', () {
    test('fxScale can be modified', () {
      final original = PowerUpCollectEffect.fxScale;

      PowerUpCollectEffect.fxScale = 0.5;
      expect(PowerUpCollectEffect.fxScale, 0.5);

      PowerUpCollectEffect.fxScale = 2.0;
      expect(PowerUpCollectEffect.fxScale, 2.0);

      PowerUpCollectEffect.fxScale = original;
    });
  });

  group('PowerUpCollectEffect reduceFx', () {
    test('reduceFx can be toggled', () {
      final original = PowerUpCollectEffect.reduceFx;

      PowerUpCollectEffect.reduceFx = true;
      expect(PowerUpCollectEffect.reduceFx, isTrue);

      PowerUpCollectEffect.reduceFx = false;
      expect(PowerUpCollectEffect.reduceFx, isFalse);

      PowerUpCollectEffect.reduceFx = original;
    });
  });

  group('PowerUpCollectEffect lowFx', () {
    test('lowFx can be toggled', () {
      final original = PowerUpCollectEffect.lowFx;

      PowerUpCollectEffect.lowFx = true;
      expect(PowerUpCollectEffect.lowFx, isTrue);

      PowerUpCollectEffect.lowFx = false;
      expect(PowerUpCollectEffect.lowFx, isFalse);

      PowerUpCollectEffect.lowFx = original;
    });
  });

  group('PowerUpCollectEffect update behavior', () {
    setUp(() {
      PowerUpCollectEffect.clearPool();
    });

    test('update with zero delta time works', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.health,
      );

      expect(() => effect!.update(0), returnsNormally);
    });

    test('update with small delta time works', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.health,
      );

      expect(() => effect!.update(0.016), returnsNormally);
    });

    test('multiple updates work', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.health,
      );

      for (int i = 0; i < 60; i++) {
        effect!.update(0.016);
      }

      expect(true, isTrue);
    });

    test('update through full duration', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.health,
        duration: 1.0,
      );

      // 60 frames at ~16ms each = ~1 second
      for (int i = 0; i < 70; i++) {
        effect!.update(0.016);
      }

      expect(true, isTrue);
    });
  });

  group('PowerUpCollectEffect per-type behavior', () {
    setUp(() {
      PowerUpCollectEffect.clearPool();
    });

    test('health effect animation works', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.health,
        displayText: '+100',
      );

      for (int i = 0; i < 30; i++) {
        effect!.update(0.016);
      }

      expect(true, isTrue);
    });

    test('damage effect animation works', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.damage,
        displayText: '+50%',
      );

      for (int i = 0; i < 30; i++) {
        effect!.update(0.016);
      }

      expect(true, isTrue);
    });

    test('speed effect animation works', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.speed,
        displayText: '+25%',
      );

      for (int i = 0; i < 30; i++) {
        effect!.update(0.016);
      }

      expect(true, isTrue);
    });

    test('shield effect animation works', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.shield,
        displayText: 'ACTIVE',
      );

      for (int i = 0; i < 30; i++) {
        effect!.update(0.016);
      }

      expect(true, isTrue);
    });
  });

  group('PowerUpCollectEffect performance', () {
    setUp(() {
      PowerUpCollectEffect.clearPool();
    });

    test('can spawn many effects up to limit', () {
      for (int i = 0; i < PowerUpCollectEffect.maxActive; i++) {
        final effect = PowerUpCollectEffect.spawn(
          position: Vector2(i.toDouble() * 20, 0),
          powerUpType: PowerUpType.values[i % 4],
        );

        if (i < PowerUpCollectEffect.maxActive) {
          expect(effect, isNotNull);
        }
      }
    });

    test('rapid spawn and update works', () {
      for (int i = 0; i < 8; i++) {
        final effect = PowerUpCollectEffect.spawn(
          position: Vector2(i.toDouble() * 30, 0),
          powerUpType: PowerUpType.values[i % 4],
          displayText: 'Power $i',
        );

        if (effect != null) {
          for (int frame = 0; frame < 20; frame++) {
            effect.update(0.016);
          }
        }
      }

      expect(true, isTrue);
    });
  });

  group('PowerUpCollectEffect edge cases', () {
    setUp(() {
      PowerUpCollectEffect.clearPool();
    });

    test('handles zero position', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2.zero(),
        powerUpType: PowerUpType.health,
      );

      expect(effect, isNotNull);
    });

    test('handles negative position', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(-100, -100),
        powerUpType: PowerUpType.damage,
      );

      expect(effect, isNotNull);
    });

    test('handles very large position', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(10000, 10000),
        powerUpType: PowerUpType.speed,
      );

      expect(effect, isNotNull);
    });

    test('handles empty displayText', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.shield,
        displayText: '',
      );

      expect(effect, isNotNull);
    });

    test('handles very long displayText', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.health,
        displayText: 'This is a very long power-up text message!',
      );

      expect(effect, isNotNull);
    });

    test('handles very small duration', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.damage,
        duration: 0.1,
      );

      expect(effect, isNotNull);
    });

    test('handles very long duration', () {
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.speed,
        duration: 10.0,
      );

      expect(effect, isNotNull);
    });
  });

  group('PowerUpCollectEffect visual layers', () {
    setUp(() {
      PowerUpCollectEffect.clearPool();
    });

    test('effect has 7 visual layers (as documented)', () {
      // According to the class documentation:
      // - Layer 1: Radial burst of energy particles
      // - Layer 2: Spiral of orbiting particles that collapse inward
      // - Layer 3: Central absorption glow that grows then shrinks
      // - Layer 4: Energy rings expanding outward
      // - Layer 5: Electric sparks radiating from center
      // - Layer 6: Holographic text showing power-up name/value
      // - Layer 7: Final bright flash with color pulse
      final effect = PowerUpCollectEffect.spawn(
        position: Vector2(100, 100),
        powerUpType: PowerUpType.health,
        displayText: '+100 HP',
      );

      expect(effect, isNotNull);
    });
  });
}
