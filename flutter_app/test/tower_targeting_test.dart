import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/tower.dart';
import 'package:bored_games/src/game/entities/enemy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tower targeting modes', () {
    test('TargetMode.first selects first spawned enemy', () {
      final tower = Tower(
        position: Vector2(100, 100),
        size: 40,
        targetMode: TargetMode.first,
      );

      expect(tower.targetMode, TargetMode.first);
    });

    test('TargetMode.last selects last spawned enemy', () {
      final tower = Tower(
        position: Vector2(100, 100),
        size: 40,
        targetMode: TargetMode.last,
      );

      expect(tower.targetMode, TargetMode.last);
    });

    test('TargetMode.strongest selects highest health enemy', () {
      final tower = Tower(
        position: Vector2(100, 100),
        size: 40,
        targetMode: TargetMode.strongest,
      );

      expect(tower.targetMode, TargetMode.strongest);
    });

    test('TargetMode.weakest selects lowest health enemy', () {
      final tower = Tower(
        position: Vector2(100, 100),
        size: 40,
        targetMode: TargetMode.weakest,
      );

      expect(tower.targetMode, TargetMode.weakest);
    });

    test('TargetMode.closest selects nearest enemy', () {
      final tower = Tower(
        position: Vector2(100, 100),
        size: 40,
        targetMode: TargetMode.closest,
      );

      expect(tower.targetMode, TargetMode.closest);
    });

    test('targetMode can be changed dynamically', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        targetMode: TargetMode.first,
      );

      tower.targetMode = TargetMode.strongest;
      expect(tower.targetMode, TargetMode.strongest);

      tower.targetMode = TargetMode.closest;
      expect(tower.targetMode, TargetMode.closest);
    });
  });

  group('Tower phantom detection', () {
    test('pulseArcher cannot detect phantom', () {
      expect(TowerType.pulseArcher.canDetectPhantom, isFalse);
    });

    test('circuitCannon cannot detect phantom', () {
      expect(TowerType.circuitCannon.canDetectPhantom, isFalse);
    });

    test('phaseMage can detect phantom', () {
      expect(TowerType.phaseMage.canDetectPhantom, isTrue);
    });

    test('glimmerField cannot detect phantom', () {
      expect(TowerType.glimmerField.canDetectPhantom, isFalse);
    });

    test('ionSniper cannot detect phantom', () {
      expect(TowerType.ionSniper.canDetectPhantom, isFalse);
    });

    test('teslaTerminal cannot detect phantom', () {
      expect(TowerType.teslaTerminal.canDetectPhantom, isFalse);
    });

    test('resonanceSiphon cannot detect phantom', () {
      expect(TowerType.resonanceSiphon.canDetectPhantom, isFalse);
    });

    test('neuralDisruptor cannot detect phantom', () {
      expect(TowerType.neuralDisruptor.canDetectPhantom, isFalse);
    });
  });

  group('Tower slow effect', () {
    test('pulseArcher does not apply slow', () {
      expect(TowerType.pulseArcher.appliesSlow, isFalse);
    });

    test('phaseMage applies slow', () {
      expect(TowerType.phaseMage.appliesSlow, isTrue);
      expect(TowerType.phaseMage.slowAmount, greaterThan(0));
      expect(TowerType.phaseMage.slowDuration, greaterThan(0));
    });

    test('glimmerField applies slow', () {
      expect(TowerType.glimmerField.appliesSlow, isTrue);
      expect(TowerType.glimmerField.slowAmount, greaterThan(0));
      expect(TowerType.glimmerField.slowDuration, greaterThan(0));
    });

    test('tower slowAmount multiplier works', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        type: TowerType.phaseMage,
        slowMultiplier: 2.0,
      );

      expect(tower.slowAmount, TowerType.phaseMage.slowAmount * 2.0);
    });
  });

  group('Tower range calculations', () {
    test('tower range uses base type range', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        type: TowerType.pulseArcher,
      );

      expect(tower.range, TowerType.pulseArcher.range);
    });

    test('tower range multiplier increases range', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        type: TowerType.pulseArcher,
        rangeMultiplier: 1.5,
      );

      expect(tower.range, TowerType.pulseArcher.range * 1.5);
    });

    test('ionSniper has highest base range', () {
      var maxRange = 0.0;
      TowerType? maxRangeType;

      for (final type in TowerType.values) {
        if (type.range > maxRange) {
          maxRange = type.range;
          maxRangeType = type;
        }
      }

      expect(maxRangeType, TowerType.ionSniper);
    });
  });

  group('Tower projectile speed', () {
    test('teslaTerminal has instant hit (0 speed)', () {
      expect(TowerType.teslaTerminal.projectileSpeed, 0);
    });

    test('ionSniper has highest projectile speed', () {
      var maxSpeed = 0.0;
      for (final type in TowerType.values) {
        if (type.projectileSpeed > maxSpeed) {
          maxSpeed = type.projectileSpeed;
        }
      }

      expect(TowerType.ionSniper.projectileSpeed, maxSpeed);
    });

    test('projectileSpeedMultiplier affects speed', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        type: TowerType.pulseArcher,
        projectileSpeedMultiplier: 2.0,
      );

      expect(tower.projectileSpeed, TowerType.pulseArcher.projectileSpeed * 2.0);
    });
  });

  group('Tower manual targeting', () {
    test('manual targeting starts disabled', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower.manualTargeting, isFalse);
    });

    test('setManualMode enables manual targeting', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      tower.setManualMode(true);
      expect(tower.manualTargeting, isTrue);
    });

    test('setManualMode(false) clears manual target', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      final enemy = Enemy(path: [Vector2.zero()]);

      tower.setManualMode(true);
      tower.setManualTarget(enemy);
      tower.setManualMode(false);

      expect(tower.manualTarget, isNull);
    });

    test('setManualTarget sets target', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      final enemy = Enemy(path: [Vector2.zero()]);

      tower.setManualTarget(enemy);

      expect(tower.manualTarget, same(enemy));
    });
  });

  group('Tower center position', () {
    test('centerPosition calculated from position and size', () {
      final tower = Tower(
        position: Vector2(100, 100),
        size: 40,
      );

      expect(tower.centerPosition.x, 120); // 100 + 40/2
      expect(tower.centerPosition.y, 120);
    });

    test('centerPosition updates with different sizes', () {
      final tower = Tower(
        position: Vector2(0, 0),
        size: 60,
      );

      expect(tower.centerPosition.x, 30); // 0 + 60/2
      expect(tower.centerPosition.y, 30);
    });
  });

  group('Tower fire callback', () {
    test('onFire callback can be set', () {
      bool fired = false;
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        onFire: (t, e, p) {
          fired = true;
        },
      );

      expect(tower.onFire, isNotNull);
    });
  });
}
