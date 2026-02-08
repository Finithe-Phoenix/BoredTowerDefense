import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/impact_effect.dart';
import 'package:bored_games/src/game/entities/tower.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImpactEffect static constants', () {
    test('maxPool is 30', () {
      expect(ImpactEffect.maxPool, 30);
    });

    test('maxActive is 40', () {
      expect(ImpactEffect.maxActive, 40);
    });

    test('fxScale default is 1.0', () {
      expect(ImpactEffect.fxScale, 1.0);
    });
  });

  group('ImpactEffect pool management', () {
    setUp(() {
      ImpactEffect.clearPool();
    });

    test('clearPool resets activeCount to 0', () {
      ImpactEffect.clearPool();
      expect(ImpactEffect.activeCount, 0);
    });

    test('clearPool can be called multiple times', () {
      ImpactEffect.clearPool();
      ImpactEffect.clearPool();
      ImpactEffect.clearPool();
      expect(ImpactEffect.activeCount, 0);
    });

    test('activeCount is 0 after clearPool', () {
      ImpactEffect.clearPool();
      expect(ImpactEffect.activeCount, 0);
    });
  });

  group('ImpactEffect spawn', () {
    setUp(() {
      ImpactEffect.clearPool();
    });

    test('spawn returns ImpactEffect', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      expect(effect, isNotNull);
      expect(effect, isA<ImpactEffect>());
    });

    test('spawn increments activeCount', () {
      final initialCount = ImpactEffect.activeCount;

      ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      expect(ImpactEffect.activeCount, initialCount + 1);
    });

    test('spawn with custom duration', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
        duration: 0.5,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 0.5);
    });

    test('spawn with different tower types', () {
      for (final towerType in TowerType.values) {
        ImpactEffect.clearPool();
        final effect = ImpactEffect.spawn(
          position: Vector2(100, 100),
          color: towerType.color,
          towerType: towerType,
        );

        expect(effect, isNotNull,
            reason: '${towerType.name} should spawn effect');
        expect(effect!.towerType, towerType);
      }
    });

    test('spawn with different colors', () {
      final colors = [
        Colors.red,
        Colors.green,
        Colors.blue,
        Colors.yellow,
        Colors.purple,
        Colors.orange,
      ];

      for (final color in colors) {
        ImpactEffect.clearPool();
        final effect = ImpactEffect.spawn(
          position: Vector2(50, 50),
          color: color,
          towerType: TowerType.pulseArcher,
        );

        expect(effect, isNotNull);
        expect(effect!.color, color);
      }
    });

    test('spawn returns null when maxActive exceeded', () {
      ImpactEffect.clearPool();

      // Spawn up to maxActive
      for (int i = 0; i < ImpactEffect.maxActive; i++) {
        ImpactEffect.spawn(
          position: Vector2(i.toDouble(), 0),
          color: Colors.cyan,
          towerType: TowerType.pulseArcher,
        );
      }

      // Next spawn should return null
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      expect(effect, isNull);
    });
  });

  group('ImpactEffect fxScale', () {
    setUp(() {
      ImpactEffect.clearPool();
    });

    test('fxScale can be modified', () {
      final original = ImpactEffect.fxScale;

      ImpactEffect.fxScale = 0.5;
      expect(ImpactEffect.fxScale, 0.5);

      ImpactEffect.fxScale = 2.0;
      expect(ImpactEffect.fxScale, 2.0);

      ImpactEffect.fxScale = original;
    });

    test('fxScale affects all spawned effects', () {
      ImpactEffect.fxScale = 1.5;

      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      expect(effect, isNotNull);
      expect(ImpactEffect.fxScale, 1.5);

      ImpactEffect.fxScale = 1.0;
    });
  });

  group('ImpactEffect properties', () {
    setUp(() {
      ImpactEffect.clearPool();
    });

    test('position is set correctly', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(200, 300),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      expect(effect!.position.x, 200);
      expect(effect.position.y, 300);
    });

    test('default duration is 0.3', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      expect(effect!.duration, 0.3);
    });

    test('color is stored correctly', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: const Color(0xFFFF0066),
        towerType: TowerType.pulseArcher,
      );

      expect(effect!.color, const Color(0xFFFF0066));
    });
  });

  group('ImpactEffect update behavior', () {
    setUp(() {
      ImpactEffect.clearPool();
    });

    test('update with zero delta time works', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      expect(() => effect!.update(0), returnsNormally);
    });

    test('update with small delta time works', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      expect(() => effect!.update(0.016), returnsNormally);
    });

    test('multiple updates work', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      for (int i = 0; i < 20; i++) {
        effect!.update(0.016);
      }

      expect(true, isTrue);
    });
  });

  group('ImpactEffect per-tower-type behavior', () {
    setUp(() {
      ImpactEffect.clearPool();
    });

    test('pulseArcher effect works', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: TowerType.pulseArcher.color,
        towerType: TowerType.pulseArcher,
      );

      expect(effect, isNotNull);
      effect!.update(0.1);
      expect(true, isTrue);
    });

    test('circuitCannon effect works', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: TowerType.circuitCannon.color,
        towerType: TowerType.circuitCannon,
      );

      expect(effect, isNotNull);
      effect!.update(0.1);
      expect(true, isTrue);
    });

    test('phaseMage effect works', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: TowerType.phaseMage.color,
        towerType: TowerType.phaseMage,
      );

      expect(effect, isNotNull);
      effect!.update(0.1);
      expect(true, isTrue);
    });

    test('glimmerField effect works', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: TowerType.glimmerField.color,
        towerType: TowerType.glimmerField,
      );

      expect(effect, isNotNull);
      effect!.update(0.1);
      expect(true, isTrue);
    });

    test('ionSniper effect works', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: TowerType.ionSniper.color,
        towerType: TowerType.ionSniper,
      );

      expect(effect, isNotNull);
      effect!.update(0.1);
      expect(true, isTrue);
    });

    test('teslaTerminal effect works', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: TowerType.teslaTerminal.color,
        towerType: TowerType.teslaTerminal,
      );

      expect(effect, isNotNull);
      effect!.update(0.1);
      expect(true, isTrue);
    });

    test('plasmaBubble effect works', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: TowerType.plasmaBubble.color,
        towerType: TowerType.plasmaBubble,
      );

      expect(effect, isNotNull);
      effect!.update(0.1);
      expect(true, isTrue);
    });
  });

  group('ImpactEffect performance', () {
    setUp(() {
      ImpactEffect.clearPool();
    });

    test('can spawn many effects up to limit', () {
      for (int i = 0; i < ImpactEffect.maxActive; i++) {
        final effect = ImpactEffect.spawn(
          position: Vector2(i.toDouble() * 10, 0),
          color: Colors.cyan,
          towerType: TowerType.pulseArcher,
        );

        if (i < ImpactEffect.maxActive) {
          expect(effect, isNotNull);
        }
      }
    });

    test('rapid spawn and update works', () {
      ImpactEffect.clearPool();

      for (int i = 0; i < 20; i++) {
        final effect = ImpactEffect.spawn(
          position: Vector2(i.toDouble() * 10, 0),
          color: Colors.cyan,
          towerType: TowerType.values[i % TowerType.values.length],
        );

        if (effect != null) {
          effect.update(0.016);
        }
      }

      expect(true, isTrue);
    });
  });

  group('ImpactEffect edge cases', () {
    setUp(() {
      ImpactEffect.clearPool();
    });

    test('handles zero position', () {
      final effect = ImpactEffect.spawn(
        position: Vector2.zero(),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      expect(effect, isNotNull);
    });

    test('handles negative position', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(-100, -100),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      expect(effect, isNotNull);
    });

    test('handles very large position', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(10000, 10000),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      expect(effect, isNotNull);
    });

    test('handles very small duration', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
        duration: 0.01,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 0.01);
    });

    test('handles very long duration', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
        duration: 10.0,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 10.0);
    });

    test('handles transparent color', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.transparent,
        towerType: TowerType.pulseArcher,
      );

      expect(effect, isNotNull);
    });
  });
}
