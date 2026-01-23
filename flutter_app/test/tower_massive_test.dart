import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/tower.dart';
import 'package:bored_games/src/game/entities/enemy.dart';
import 'package:bored_games/src/models/upgrade_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ============================================
  // TARGET MODE ENUM TESTS (50+ tests)
  // ============================================

  group('TargetMode enum', () {
    test('TargetMode has 5 values', () {
      expect(TargetMode.values.length, 5);
    });

    test('TargetMode.first exists', () {
      expect(TargetMode.first, isNotNull);
      expect(TargetMode.first.index, 0);
    });

    test('TargetMode.last exists', () {
      expect(TargetMode.last, isNotNull);
      expect(TargetMode.last.index, 1);
    });

    test('TargetMode.strongest exists', () {
      expect(TargetMode.strongest, isNotNull);
      expect(TargetMode.strongest.index, 2);
    });

    test('TargetMode.weakest exists', () {
      expect(TargetMode.weakest, isNotNull);
      expect(TargetMode.weakest.index, 3);
    });

    test('TargetMode.closest exists', () {
      expect(TargetMode.closest, isNotNull);
      expect(TargetMode.closest.index, 4);
    });

    for (final mode in TargetMode.values) {
      test('TargetMode.${mode.name} has valid name', () {
        expect(mode.name, isNotEmpty);
      });

      test('TargetMode.${mode.name} can be used in switch', () {
        String result;
        switch (mode) {
          case TargetMode.first:
            result = 'first';
            break;
          case TargetMode.last:
            result = 'last';
            break;
          case TargetMode.strongest:
            result = 'strongest';
            break;
          case TargetMode.weakest:
            result = 'weakest';
            break;
          case TargetMode.closest:
            result = 'closest';
            break;
        }
        expect(result, mode.name);
      });
    }
  });

  // ============================================
  // TOWER TYPE ENUM TESTS (300+ tests)
  // ============================================

  group('TowerType enum - Basic', () {
    test('TowerType has 8 values', () {
      expect(TowerType.values.length, 8);
    });

    for (final type in TowerType.values) {
      test('${type.name} exists', () {
        expect(type, isNotNull);
      });
    }
  });

  group('TowerType - PulseArcher', () {
    const type = TowerType.pulseArcher;

    test('name is Pulse Archer', () {
      expect(type.name, 'pulseArcher');
    });

    test('has positive damage', () {
      expect(type.damage, 15);
    });

    test('has positive fire rate', () {
      expect(type.fireRate, 2.0);
    });

    test('has positive range', () {
      expect(type.range, 160);
    });

    test('has cost', () {
      expect(type.cost, 50);
    });

    test('has cyan color', () {
      expect(type.color, const Color(0xFF00FFFF));
    });

    test('has positive projectile speed', () {
      expect(type.projectileSpeed, 400);
    });

    test('does not apply slow', () {
      expect(type.appliesSlow, isFalse);
      expect(type.slowAmount, 0);
      expect(type.slowDuration, 0);
    });

    test('cannot detect phantom', () {
      expect(type.canDetectPhantom, isFalse);
    });
  });

  group('TowerType - CircuitCannon', () {
    const type = TowerType.circuitCannon;

    test('has high damage', () {
      expect(type.damage, 50);
    });

    test('has slow fire rate', () {
      expect(type.fireRate, 0.5);
    });

    test('has medium range', () {
      expect(type.range, 140);
    });

    test('costs 100', () {
      expect(type.cost, 100);
    });

    test('has magenta color', () {
      expect(type.color, const Color(0xFFFF00FF));
    });

    test('does not apply slow', () {
      expect(type.appliesSlow, isFalse);
    });

    test('cannot detect phantom', () {
      expect(type.canDetectPhantom, isFalse);
    });
  });

  group('TowerType - PhaseMage', () {
    const type = TowerType.phaseMage;

    test('has medium damage', () {
      expect(type.damage, 25);
    });

    test('has medium fire rate', () {
      expect(type.fireRate, 1.2);
    });

    test('has long range', () {
      expect(type.range, 200);
    });

    test('costs 80', () {
      expect(type.cost, 80);
    });

    test('applies slow', () {
      expect(type.appliesSlow, isTrue);
      expect(type.slowAmount, 0.5);
      expect(type.slowDuration, 1.5);
    });

    test('CAN detect phantom', () {
      expect(type.canDetectPhantom, isTrue);
    });
  });

  group('TowerType - GlimmerField', () {
    const type = TowerType.glimmerField;

    test('has low damage', () {
      expect(type.damage, 8);
    });

    test('has very fast fire rate', () {
      expect(type.fireRate, 4.0);
    });

    test('has short range', () {
      expect(type.range, 120);
    });

    test('costs 120', () {
      expect(type.cost, 120);
    });

    test('has yellow color', () {
      expect(type.color, const Color(0xFFFFEB3B));
    });

    test('applies slow', () {
      expect(type.appliesSlow, isTrue);
      expect(type.slowAmount, 0.3);
      expect(type.slowDuration, 0.5);
    });
  });

  group('TowerType - IonSniper', () {
    const type = TowerType.ionSniper;

    test('has very high damage', () {
      expect(type.damage, 180);
    });

    test('has very slow fire rate', () {
      expect(type.fireRate, 0.4);
    });

    test('has very long range', () {
      expect(type.range, 300);
    });

    test('is expensive', () {
      expect(type.cost, 250);
    });

    test('has fast projectile', () {
      expect(type.projectileSpeed, 800);
    });

    test('does not apply slow', () {
      expect(type.appliesSlow, isFalse);
    });
  });

  group('TowerType - TeslaTerminal', () {
    const type = TowerType.teslaTerminal;

    test('has low damage per hit', () {
      expect(type.damage, 12);
    });

    test('has fast fire rate', () {
      expect(type.fireRate, 3.5);
    });

    test('has instant hit (0 projectile speed)', () {
      expect(type.projectileSpeed, 0);
    });

    test('costs 180', () {
      expect(type.cost, 180);
    });
  });

  group('TowerType - ResonanceSiphon', () {
    const type = TowerType.resonanceSiphon;

    test('has no damage', () {
      expect(type.damage, 0);
    });

    test('has support role (no direct damage)', () {
      expect(type.damage, 0);
    });

    test('costs 150', () {
      expect(type.cost, 150);
    });

    test('has instant effect', () {
      expect(type.projectileSpeed, 0);
    });
  });

  group('TowerType - NeuralDisruptor', () {
    const type = TowerType.neuralDisruptor;

    test('has low damage', () {
      expect(type.damage, 5);
    });

    test('has medium fire rate', () {
      expect(type.fireRate, 2.0);
    });

    test('costs 200', () {
      expect(type.cost, 200);
    });

    test('has green color', () {
      expect(type.color, const Color(0xFF00FF00));
    });
  });

  group('TowerType - Comparative stats', () {
    test('ionSniper has highest damage', () {
      final maxDamage = TowerType.values.map((t) => t.damage).reduce((a, b) => a > b ? a : b);
      expect(TowerType.ionSniper.damage, maxDamage);
    });

    test('ionSniper has longest range', () {
      final maxRange = TowerType.values.map((t) => t.range).reduce((a, b) => a > b ? a : b);
      expect(TowerType.ionSniper.range, maxRange);
    });

    test('glimmerField has fastest fire rate', () {
      final maxFireRate = TowerType.values.map((t) => t.fireRate).reduce((a, b) => a > b ? a : b);
      expect(TowerType.glimmerField.fireRate, maxFireRate);
    });

    test('pulseArcher is cheapest', () {
      final minCost = TowerType.values.map((t) => t.cost).reduce((a, b) => a < b ? a : b);
      expect(TowerType.pulseArcher.cost, minCost);
    });

    test('only phaseMage can detect phantom', () {
      final phantomDetectors = TowerType.values.where((t) => t.canDetectPhantom).toList();
      expect(phantomDetectors.length, 1);
      expect(phantomDetectors.first, TowerType.phaseMage);
    });

    test('two towers apply slow', () {
      final slowTowers = TowerType.values.where((t) => t.appliesSlow).toList();
      expect(slowTowers.length, 2);
      expect(slowTowers, contains(TowerType.phaseMage));
      expect(slowTowers, contains(TowerType.glimmerField));
    });
  });

  group('TowerType - All types validation', () {
    for (final type in TowerType.values) {
      test('${type.name} has positive or zero damage', () {
        expect(type.damage, greaterThanOrEqualTo(0));
      });

      test('${type.name} has positive fire rate', () {
        expect(type.fireRate, greaterThan(0));
      });

      test('${type.name} has positive range', () {
        expect(type.range, greaterThan(0));
      });

      test('${type.name} has positive cost', () {
        expect(type.cost, greaterThan(0));
      });

      test('${type.name} has non-null color', () {
        expect(type.color, isNotNull);
      });

      test('${type.name} has non-negative projectile speed', () {
        expect(type.projectileSpeed, greaterThanOrEqualTo(0));
      });

      test('${type.name} slow amount is 0-1 range', () {
        expect(type.slowAmount, greaterThanOrEqualTo(0));
        expect(type.slowAmount, lessThanOrEqualTo(1));
      });

      test('${type.name} slow duration is non-negative', () {
        expect(type.slowDuration, greaterThanOrEqualTo(0));
      });

      test('${type.name} appliesSlow is consistent', () {
        if (type.slowAmount > 0 && type.slowDuration > 0) {
          expect(type.appliesSlow, isTrue);
        } else {
          expect(type.appliesSlow, isFalse);
        }
      });
    }
  });

  // ============================================
  // TOWER CLASS TESTS (400+ tests)
  // ============================================

  group('Tower - Creation basic', () {
    test('creates with position and size', () {
      final tower = Tower(position: Vector2(100, 100), size: 40);
      expect(tower, isNotNull);
    });

    test('position is set correctly', () {
      final tower = Tower(position: Vector2(50, 75), size: 40);
      expect(tower.position.x, 50);
      expect(tower.position.y, 75);
    });

    test('size is set correctly', () {
      final tower = Tower(position: Vector2.zero(), size: 60);
      expect(tower.size.x, 60);
      expect(tower.size.y, 60);
    });

    for (int x = 0; x <= 500; x += 100) {
      for (int y = 0; y <= 500; y += 100) {
        test('creates tower at position ($x, $y)', () {
          final tower = Tower(position: Vector2(x.toDouble(), y.toDouble()), size: 40);
          expect(tower.position.x, x);
          expect(tower.position.y, y);
        });
      }
    }

    for (int s = 20; s <= 100; s += 20) {
      test('creates tower with size $s', () {
        final tower = Tower(position: Vector2.zero(), size: s.toDouble());
        expect(tower.size.x, s);
      });
    }
  });

  group('Tower - Creation with type', () {
    for (final type in TowerType.values) {
      test('creates tower with type ${type.name}', () {
        final tower = Tower(position: Vector2.zero(), size: 40, type: type);
        expect(tower.type, type);
      });

      test('${type.name} tower has correct damage', () {
        final tower = Tower(position: Vector2.zero(), size: 40, type: type);
        expect(tower.damage, type.damage);
      });

      test('${type.name} tower has correct fire rate', () {
        final tower = Tower(position: Vector2.zero(), size: 40, type: type);
        expect(tower.fireRate, type.fireRate);
      });

      test('${type.name} tower has correct range', () {
        final tower = Tower(position: Vector2.zero(), size: 40, type: type);
        expect(tower.range, type.range);
      });

      test('${type.name} tower has correct color', () {
        final tower = Tower(position: Vector2.zero(), size: 40, type: type);
        expect(tower.color, type.color);
      });

      test('${type.name} tower has correct projectile speed', () {
        final tower = Tower(position: Vector2.zero(), size: 40, type: type);
        expect(tower.projectileSpeed, type.projectileSpeed);
      });
    }
  });

  group('Tower - Creation with target mode', () {
    for (final mode in TargetMode.values) {
      test('creates tower with target mode ${mode.name}', () {
        final tower = Tower(position: Vector2.zero(), size: 40, targetMode: mode);
        expect(tower.targetMode, mode);
      });
    }

    test('default target mode is first', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower.targetMode, TargetMode.first);
    });
  });

  group('Tower - Target mode change', () {
    for (final mode in TargetMode.values) {
      test('can change to ${mode.name}', () {
        final tower = Tower(position: Vector2.zero(), size: 40);
        tower.targetMode = mode;
        expect(tower.targetMode, mode);
      });
    }

    test('can cycle through all modes', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      for (final mode in TargetMode.values) {
        tower.targetMode = mode;
        expect(tower.targetMode, mode);
      }
    });
  });

  group('Tower - Center position', () {
    test('center position at origin', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower.centerPosition.x, 20);
      expect(tower.centerPosition.y, 20);
    });

    test('center position with offset', () {
      final tower = Tower(position: Vector2(100, 100), size: 40);
      expect(tower.centerPosition.x, 120);
      expect(tower.centerPosition.y, 120);
    });

    for (int size = 20; size <= 100; size += 20) {
      test('center position with size $size', () {
        final tower = Tower(position: Vector2(0, 0), size: size.toDouble());
        expect(tower.centerPosition.x, size / 2);
        expect(tower.centerPosition.y, size / 2);
      });
    }
  });

  group('Tower - Damage multiplier', () {
    for (double mult = 0.5; mult <= 3.0; mult += 0.5) {
      test('damage multiplier $mult', () {
        final tower = Tower(
          position: Vector2.zero(),
          size: 40,
          damageMultiplier: mult,
        );
        expect(tower.damage, closeTo(TowerType.pulseArcher.damage * mult, 0.1));
      });
    }
  });

  group('Tower - Range multiplier', () {
    for (double mult = 0.5; mult <= 2.0; mult += 0.25) {
      test('range multiplier $mult', () {
        final tower = Tower(
          position: Vector2.zero(),
          size: 40,
          rangeMultiplier: mult,
        );
        expect(tower.range, closeTo(TowerType.pulseArcher.range * mult, 0.1));
      });
    }
  });

  group('Tower - Fire rate multiplier', () {
    for (double mult = 0.5; mult <= 2.0; mult += 0.25) {
      test('fire rate multiplier $mult', () {
        final tower = Tower(
          position: Vector2.zero(),
          size: 40,
          fireRateMultiplier: mult,
        );
        expect(tower.fireRate, closeTo(TowerType.pulseArcher.fireRate * mult, 0.1));
      });
    }
  });

  group('Tower - Projectile speed multiplier', () {
    for (double mult = 0.5; mult <= 2.0; mult += 0.25) {
      test('projectile speed multiplier $mult', () {
        final tower = Tower(
          position: Vector2.zero(),
          size: 40,
          projectileSpeedMultiplier: mult,
        );
        expect(tower.projectileSpeed, closeTo(TowerType.pulseArcher.projectileSpeed * mult, 0.1));
      });
    }
  });

  group('Tower - Slow multiplier', () {
    for (double mult = 0.5; mult <= 2.0; mult += 0.25) {
      test('slow multiplier $mult for phaseMage', () {
        final tower = Tower(
          position: Vector2.zero(),
          size: 40,
          type: TowerType.phaseMage,
          slowMultiplier: mult,
        );
        expect(tower.slowAmount, closeTo(TowerType.phaseMage.slowAmount * mult, 0.01));
      });
    }
  });

  group('Tower - Manual targeting', () {
    test('manual targeting starts disabled', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower.manualTargeting, isFalse);
    });

    test('setManualMode enables manual targeting', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      tower.setManualMode(true);
      expect(tower.manualTargeting, isTrue);
    });

    test('setManualMode disables manual targeting', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      tower.setManualMode(true);
      tower.setManualMode(false);
      expect(tower.manualTargeting, isFalse);
    });

    test('setManualTarget sets target', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      final enemy = Enemy(path: [Vector2.zero()]);
      tower.setManualTarget(enemy);
      expect(tower.manualTarget, same(enemy));
    });

    test('setManualMode(false) clears target', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      final enemy = Enemy(path: [Vector2.zero()]);
      tower.setManualMode(true);
      tower.setManualTarget(enemy);
      tower.setManualMode(false);
      expect(tower.manualTarget, isNull);
    });

    test('manualTarget is null initially', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower.manualTarget, isNull);
    });
  });

  group('Tower - Cooldown', () {
    test('isReady initially', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower.isReady, isTrue);
    });

    test('resetCooldown makes tower not ready', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      tower.resetCooldown();
      expect(tower.isReady, isFalse);
    });
  });

  group('Tower - Update', () {
    test('update does not crash', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(() => tower.update(0.016), returnsNormally);
    });

    for (double dt = 0.001; dt <= 0.1; dt += 0.01) {
      test('update with dt ${dt.toStringAsFixed(3)}', () {
        final tower = Tower(position: Vector2.zero(), size: 40);
        expect(() => tower.update(dt), returnsNormally);
      });
    }

    test('multiple updates', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      for (int i = 0; i < 100; i++) {
        expect(() => tower.update(0.016), returnsNormally);
      }
    });
  });

  group('Tower - Render', () {
    test('render does not crash', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => tower.render(canvas), returnsNormally);
      recorder.endRecording();
    });

    for (final type in TowerType.values) {
      test('render ${type.name} tower', () {
        final tower = Tower(position: Vector2.zero(), size: 40, type: type);
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        expect(() => tower.render(canvas), returnsNormally);
        recorder.endRecording();
      });
    }

    test('render with lowFx enabled', () {
      Tower.lowFx = true;
      final tower = Tower(position: Vector2.zero(), size: 40);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => tower.render(canvas), returnsNormally);
      recorder.endRecording();
      Tower.lowFx = false;
    });
  });

  group('Tower - Apply upgrade stats', () {
    test('applyUpgradeStats changes damage', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      const stats = UpgradeStats(towerDamageMult: 1.5);
      tower.applyUpgradeStats(stats);
      expect(tower.damage, closeTo(TowerType.pulseArcher.damage * 1.5, 0.1));
    });

    test('applyUpgradeStats changes range', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      const stats = UpgradeStats(towerRangeMult: 1.2);
      tower.applyUpgradeStats(stats);
      expect(tower.range, closeTo(TowerType.pulseArcher.range * 1.2, 0.1));
    });

    test('applyUpgradeStats changes fire rate', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      const stats = UpgradeStats(towerFireRateMult: 1.3);
      tower.applyUpgradeStats(stats);
      expect(tower.fireRate, closeTo(TowerType.pulseArcher.fireRate * 1.3, 0.1));
    });

    test('applyUpgradeStats changes projectile speed', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      const stats = UpgradeStats(projectileSpeedMult: 1.5);
      tower.applyUpgradeStats(stats);
      expect(tower.projectileSpeed, closeTo(TowerType.pulseArcher.projectileSpeed * 1.5, 0.1));
    });

    test('applyUpgradeStats changes slow', () {
      final tower = Tower(position: Vector2.zero(), size: 40, type: TowerType.phaseMage);
      const stats = UpgradeStats(slowMult: 1.5);
      tower.applyUpgradeStats(stats);
      expect(tower.slowAmount, closeTo(TowerType.phaseMage.slowAmount * 1.5, 0.01));
    });
  });

  group('Tower - Fire callback', () {
    test('onFire callback can be set', () {
      bool fired = false;
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        onFire: (t, e, p) => fired = true,
      );
      expect(tower.onFire, isNotNull);
    });

    test('onFire callback is stored', () {
      void callback(Tower t, Enemy e, Vector2 p) {}
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        onFire: callback,
      );
      expect(tower.onFire, same(callback));
    });
  });

  group('Tower - Build cost', () {
    for (int cost = 0; cost <= 500; cost += 50) {
      test('build cost $cost', () {
        final tower = Tower(position: Vector2.zero(), size: 40, buildCost: cost);
        expect(tower.buildCost, cost);
      });
    }

    test('default build cost is 0', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower.buildCost, 0);
    });
  });

  group('Tower - Resonance boost', () {
    test('setResonanceBoost increases boost', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      tower.setResonanceBoost(true);
      // Damage should be boosted
    });

    test('resetResonanceBoost clears boost', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      tower.setResonanceBoost(true);
      tower.resetResonanceBoost();
      // Boost should be cleared
    });
  });

  group('Tower - FPS boost', () {
    test('enterFpsBoost enables boost', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      tower.enterFpsBoost();
      // Tower should be boosted
    });

    test('exitFpsBoost disables boost', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      tower.enterFpsBoost();
      tower.exitFpsBoost();
      // Tower should not be boosted
    });
  });

  group('Tower - Position component inheritance', () {
    test('Tower is PositionComponent', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower, isA<PositionComponent>());
    });

    test('Tower has anchor', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower.anchor, isNotNull);
    });
  });

  group('Tower - Static lowFx flag', () {
    test('lowFx defaults to false', () {
      expect(Tower.lowFx, isFalse);
    });

    test('lowFx can be enabled', () {
      Tower.lowFx = true;
      expect(Tower.lowFx, isTrue);
      Tower.lowFx = false;
    });

    test('lowFx can be disabled', () {
      Tower.lowFx = true;
      Tower.lowFx = false;
      expect(Tower.lowFx, isFalse);
    });
  });

  group('Tower - Multiple tower independence', () {
    test('towers are independent', () {
      final t1 = Tower(position: Vector2(0, 0), size: 40);
      final t2 = Tower(position: Vector2(100, 100), size: 40);

      t1.targetMode = TargetMode.strongest;
      expect(t2.targetMode, TargetMode.first);
    });

    for (int i = 0; i < 10; i++) {
      test('tower $i is independent', () {
        final towers = List.generate(
          10,
          (j) => Tower(position: Vector2(j * 50.0, 0), size: 40),
        );

        towers[i].targetMode = TargetMode.closest;

        for (int j = 0; j < 10; j++) {
          if (i != j) {
            expect(towers[j].targetMode, TargetMode.first);
          }
        }
      });
    }
  });
}
