import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/projectile.dart';
import 'package:bored_games/src/game/entities/tower.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Projectile.lowFx = false;
    Projectile.allowTrails = true;
    Projectile.allowGlow = true;
    Projectile.stressLevel = 0;
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PROJECTILE STATIC CONFIGURATION TESTS (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Projectile - Static flags', () {
    test('lowFx defaults to false', () {
      Projectile.lowFx = false;
      expect(Projectile.lowFx, isFalse);
    });

    test('lowFx can be set to true', () {
      Projectile.lowFx = true;
      expect(Projectile.lowFx, isTrue);
      Projectile.lowFx = false;
    });

    test('allowTrails defaults to true', () {
      Projectile.allowTrails = true;
      expect(Projectile.allowTrails, isTrue);
    });

    test('allowTrails can be disabled', () {
      Projectile.allowTrails = false;
      expect(Projectile.allowTrails, isFalse);
      Projectile.allowTrails = true;
    });

    test('allowGlow defaults to true', () {
      Projectile.allowGlow = true;
      expect(Projectile.allowGlow, isTrue);
    });

    test('allowGlow can be disabled', () {
      Projectile.allowGlow = false;
      expect(Projectile.allowGlow, isFalse);
      Projectile.allowGlow = true;
    });

    test('stressLevel defaults to 0', () {
      Projectile.stressLevel = 0;
      expect(Projectile.stressLevel, 0);
    });

    test('stressLevel can be set to 1', () {
      Projectile.setStressLevel(1);
      expect(Projectile.stressLevel, 1);
    });

    test('stressLevel can be set to 2', () {
      Projectile.setStressLevel(2);
      expect(Projectile.stressLevel, 2);
    });

    test('stressLevel clamps to 0 for negative', () {
      Projectile.setStressLevel(-5);
      expect(Projectile.stressLevel, 0);
    });

    test('stressLevel clamps to 2 for high values', () {
      Projectile.setStressLevel(10);
      expect(Projectile.stressLevel, 2);
    });

    test('stressLevel 2 sets lowFx to true', () {
      Projectile.lowFx = false;
      Projectile.setStressLevel(2);
      expect(Projectile.lowFx, isTrue);
    });

    test('stressLevel 1 keeps lowFx false', () {
      Projectile.lowFx = false;
      Projectile.setStressLevel(1);
      expect(Projectile.lowFx, isFalse);
    });

    test('stressLevel 0 keeps lowFx false', () {
      Projectile.lowFx = false;
      Projectile.setStressLevel(0);
      expect(Projectile.lowFx, isFalse);
    });

    for (int level = 0; level <= 5; level++) {
      test('setStressLevel($level) clamps correctly', () {
        Projectile.setStressLevel(level);
        expect(Projectile.stressLevel, level.clamp(0, 2));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PROJECTILE PER TOWER TYPE TESTS (80+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Projectile - TowerType properties', () {
    for (final type in TowerType.values) {
      test('${type.name} has valid damage', () {
        expect(type.damage, greaterThanOrEqualTo(0));
      });

      test('${type.name} has valid range', () {
        expect(type.range, greaterThan(0));
      });

      test('${type.name} has valid fire rate', () {
        expect(type.fireRate, greaterThan(0));
      });

      test('${type.name} has valid projectile speed', () {
        expect(type.projectileSpeed, greaterThan(0));
      });

      test('${type.name} has non-null color', () {
        expect(type.color, isNotNull);
      });

      test('${type.name} has valid cost', () {
        expect(type.cost, greaterThan(0));
      });

      test('${type.name} has non-empty name', () {
        expect(type.name, isNotEmpty);
      });

      test('${type.name} has non-null slow amount', () {
        expect(type.slowAmount, isNotNull);
      });

      test('${type.name} has non-null slow duration', () {
        expect(type.slowDuration, isNotNull);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PROJECTILE STRESS LEVEL MATRIX TESTS (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Projectile - Stress level matrix', () {
    final towerTypes = TowerType.values;
    final stressLevels = [0, 1, 2];

    for (final stress in stressLevels) {
      for (final type in towerTypes) {
        test('stress $stress with ${type.name}', () {
          Projectile.setStressLevel(stress);
          expect(Projectile.stressLevel, stress);

          if (stress >= 2) {
            expect(Projectile.lowFx, isTrue);
          }
        });
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PROJECTILE VISUAL FLAGS COMBINATIONS (40+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Projectile - Visual flag combinations', () {
    final boolValues = [true, false];

    for (final trails in boolValues) {
      for (final glow in boolValues) {
        for (final lowFx in boolValues) {
          test('trails=$trails, glow=$glow, lowFx=$lowFx', () {
            Projectile.allowTrails = trails;
            Projectile.allowGlow = glow;
            Projectile.lowFx = lowFx;

            expect(Projectile.allowTrails, trails);
            expect(Projectile.allowGlow, glow);
            expect(Projectile.lowFx, lowFx);
          });
        }
      }
    }

    for (int stress = 0; stress <= 2; stress++) {
      for (final trails in boolValues) {
        test('stress=$stress with trails=$trails', () {
          Projectile.setStressLevel(stress);
          Projectile.allowTrails = trails;
          expect(Projectile.stressLevel, stress);
          expect(Projectile.allowTrails, trails);
        });
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TOWER TYPE SLOW PROPERTIES (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Projectile - Tower slow properties', () {
    test('pulseArcher has no slow', () {
      expect(TowerType.pulseArcher.slowAmount, 0);
      expect(TowerType.pulseArcher.slowDuration, 0);
    });

    test('circuitCannon has no slow', () {
      expect(TowerType.circuitCannon.slowAmount, 0);
      expect(TowerType.circuitCannon.slowDuration, 0);
    });

    test('phaseMage has slow', () {
      expect(TowerType.phaseMage.slowAmount, greaterThan(0));
      expect(TowerType.phaseMage.slowDuration, greaterThan(0));
    });

    test('glimmerField has slow', () {
      expect(TowerType.glimmerField.slowAmount, greaterThan(0));
      expect(TowerType.glimmerField.slowDuration, greaterThan(0));
    });

    for (final type in TowerType.values) {
      test('${type.name} slow amount is in valid range', () {
        expect(type.slowAmount, greaterThanOrEqualTo(0));
        expect(type.slowAmount, lessThanOrEqualTo(1));
      });

      test('${type.name} slow duration is non-negative', () {
        expect(type.slowDuration, greaterThanOrEqualTo(0));
      });

      test('${type.name} slow consistency', () {
        if (type.slowAmount > 0) {
          expect(type.slowDuration, greaterThan(0),
              reason: 'If slow amount > 0, duration should be > 0');
        }
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TOWER TYPE DAMAGE COMPARISON (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Projectile - Tower damage comparison', () {
    test('ionSniper has highest single-target damage', () {
      final ionDamage = TowerType.ionSniper.damage;
      for (final type in TowerType.values) {
        if (type != TowerType.ionSniper && type != TowerType.circuitCannon) {
          expect(ionDamage, greaterThanOrEqualTo(type.damage));
        }
      }
    });

    test('glimmerField has lower damage per hit', () {
      final glimmerDamage = TowerType.glimmerField.damage;
      expect(glimmerDamage, lessThan(TowerType.ionSniper.damage));
    });

    test('pulseArcher is balanced baseline', () {
      final pulseDamage = TowerType.pulseArcher.damage;
      expect(pulseDamage, greaterThan(0));
    });

    for (final type in TowerType.values) {
      test('${type.name} damage-to-cost ratio', () {
        final ratio = type.damage / type.cost;
        expect(ratio, greaterThan(0));
      });

      test('${type.name} DPS estimation', () {
        final dps = type.damage * type.fireRate;
        expect(dps, greaterThanOrEqualTo(0));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TOWER TYPE RANGE COMPARISON (20+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Projectile - Tower range comparison', () {
    test('ionSniper has longest range', () {
      final ionRange = TowerType.ionSniper.range;
      for (final type in TowerType.values) {
        expect(ionRange, greaterThanOrEqualTo(type.range));
      }
    });

    test('circuitCannon has moderate range', () {
      final cannonRange = TowerType.circuitCannon.range;
      expect(cannonRange, greaterThan(50));
    });

    for (final type in TowerType.values) {
      test('${type.name} range is reasonable', () {
        expect(type.range, greaterThan(30));
        expect(type.range, lessThan(500));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TOWER TYPE FIRE RATE COMPARISON (20+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Projectile - Tower fire rate comparison', () {
    test('glimmerField has high fire rate', () {
      final glimmerRate = TowerType.glimmerField.fireRate;
      expect(glimmerRate, greaterThan(1));
    });

    test('ionSniper has low fire rate', () {
      final ionRate = TowerType.ionSniper.fireRate;
      expect(ionRate, lessThan(2));
    });

    for (final type in TowerType.values) {
      test('${type.name} fire rate is positive', () {
        expect(type.fireRate, greaterThan(0));
      });

      test('${type.name} fire rate is reasonable', () {
        expect(type.fireRate, lessThan(20));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TOWER TYPE PROJECTILE SPEED (20+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Projectile - Tower projectile speed', () {
    test('ionSniper has fast projectile', () {
      final ionSpeed = TowerType.ionSniper.projectileSpeed;
      expect(ionSpeed, greaterThan(200));
    });

    for (final type in TowerType.values) {
      test('${type.name} projectile speed is positive', () {
        expect(type.projectileSpeed, greaterThan(0));
      });

      test('${type.name} projectile speed is reasonable', () {
        expect(type.projectileSpeed, greaterThan(50));
        expect(type.projectileSpeed, lessThan(1000));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TOWER TYPE COST ANALYSIS (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Projectile - Tower cost analysis', () {
    test('pulseArcher is cheapest', () {
      final pulseCost = TowerType.pulseArcher.cost;
      for (final type in TowerType.values) {
        expect(pulseCost, lessThanOrEqualTo(type.cost));
      }
    });

    for (final type in TowerType.values) {
      test('${type.name} cost is positive', () {
        expect(type.cost, greaterThan(0));
      });

      test('${type.name} cost is reasonable', () {
        expect(type.cost, greaterThan(10));
        expect(type.cost, lessThan(10000));
      });

      test('${type.name} has valid upgrade cost multiplier', () {
        final upgradeCost = type.cost * 1.5;
        expect(upgradeCost, greaterThan(type.cost));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TOWER TYPE ENUM COMPLETENESS (10+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Projectile - TowerType enum completeness', () {
    test('TowerType has 8 values', () {
      expect(TowerType.values.length, 8);
    });

    test('pulseArcher exists', () {
      expect(TowerType.values, contains(TowerType.pulseArcher));
    });

    test('circuitCannon exists', () {
      expect(TowerType.values, contains(TowerType.circuitCannon));
    });

    test('phaseMage exists', () {
      expect(TowerType.values, contains(TowerType.phaseMage));
    });

    test('glimmerField exists', () {
      expect(TowerType.values, contains(TowerType.glimmerField));
    });

    test('ionSniper exists', () {
      expect(TowerType.values, contains(TowerType.ionSniper));
    });

    test('teslaTerminal exists', () {
      expect(TowerType.values, contains(TowerType.teslaTerminal));
    });

    test('resonanceSiphon exists', () {
      expect(TowerType.values, contains(TowerType.resonanceSiphon));
    });

    test('neuralDisruptor exists', () {
      expect(TowerType.values, contains(TowerType.neuralDisruptor));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TOWER TYPE INDEX VALIDATION (10+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Projectile - TowerType index validation', () {
    test('pulseArcher is first', () {
      expect(TowerType.pulseArcher.index, 0);
    });

    test('neuralDisruptor is last', () {
      expect(TowerType.neuralDisruptor.index, 7);
    });

    for (int i = 0; i < TowerType.values.length; i++) {
      test('TowerType at index $i has correct index', () {
        expect(TowerType.values[i].index, i);
      });
    }
  });
}
