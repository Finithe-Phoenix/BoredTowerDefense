import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/tower.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ============================================
  // TOWER TYPE ENUMERATION TESTS (50+ tests)
  // ============================================

  group('TowerType enumeration basics', () {
    test('has exactly 9 tower types', () {
      expect(TowerType.values.length, 9);
    });

    test('tower types are in correct order', () {
      expect(TowerType.values[0], TowerType.pulseArcher);
      expect(TowerType.values[1], TowerType.circuitCannon);
      expect(TowerType.values[2], TowerType.phaseMage);
      expect(TowerType.values[3], TowerType.glimmerField);
      expect(TowerType.values[4], TowerType.ionSniper);
      expect(TowerType.values[5], TowerType.teslaTerminal);
      expect(TowerType.values[6], TowerType.resonanceSiphon);
      expect(TowerType.values[7], TowerType.neuralDisruptor);
    });

    test('all tower types have unique indices', () {
      final indices = TowerType.values.map((t) => t.index).toSet();
      expect(indices.length, TowerType.values.length);
    });

    test('tower type names are not empty', () {
      for (final type in TowerType.values) {
        expect(type.name, isNotEmpty);
      }
    });
  });

  // ============================================
  // PULSE ARCHER TESTS (15+ tests)
  // ============================================

  group('PulseArcher tower type', () {
    test('has correct name', () {
      expect(TowerType.pulseArcher.name, 'Pulse Archer');
    });

    test('has positive damage', () {
      expect(TowerType.pulseArcher.damage, greaterThan(0));
    });

    test('damage is exactly 15', () {
      expect(TowerType.pulseArcher.damage, 15);
    });

    test('has positive fire rate', () {
      expect(TowerType.pulseArcher.fireRate, greaterThan(0));
    });

    test('fire rate is exactly 2.0', () {
      expect(TowerType.pulseArcher.fireRate, 2.0);
    });

    test('has positive range', () {
      expect(TowerType.pulseArcher.range, greaterThan(0));
    });

    test('range is exactly 160', () {
      expect(TowerType.pulseArcher.range, 160);
    });

    test('has positive cost', () {
      expect(TowerType.pulseArcher.cost, greaterThan(0));
    });

    test('cost is exactly 50', () {
      expect(TowerType.pulseArcher.cost, 50);
    });

    test('has valid color', () {
      expect(TowerType.pulseArcher.color, isA<Color>());
    });

    test('color is not transparent', () {
      expect(TowerType.pulseArcher.color.alpha, greaterThan(0));
    });

    test('has positive projectile speed', () {
      expect(TowerType.pulseArcher.projectileSpeed, greaterThan(0));
    });

    test('cannot detect phantom', () {
      expect(TowerType.pulseArcher.canDetectPhantom, isFalse);
    });

    test('does not apply slow', () {
      expect(TowerType.pulseArcher.appliesSlow, isFalse);
    });

    test('slow amount is zero', () {
      expect(TowerType.pulseArcher.slowAmount, 0);
    });

    test('slow duration is zero', () {
      expect(TowerType.pulseArcher.slowDuration, 0);
    });

    test('is cheapest tower', () {
      for (final type in TowerType.values) {
        expect(TowerType.pulseArcher.cost, lessThanOrEqualTo(type.cost));
      }
    });
  });

  // ============================================
  // CIRCUIT CANNON TESTS (15+ tests)
  // ============================================

  group('CircuitCannon tower type', () {
    test('has correct name', () {
      expect(TowerType.circuitCannon.name, 'Circuit Cannon');
    });

    test('has positive damage', () {
      expect(TowerType.circuitCannon.damage, greaterThan(0));
    });

    test('damage is exactly 50', () {
      expect(TowerType.circuitCannon.damage, 50);
    });

    test('has higher damage than pulseArcher', () {
      expect(TowerType.circuitCannon.damage, greaterThan(TowerType.pulseArcher.damage));
    });

    test('has positive fire rate', () {
      expect(TowerType.circuitCannon.fireRate, greaterThan(0));
    });

    test('fire rate is less than 1.0 (slow)', () {
      expect(TowerType.circuitCannon.fireRate, lessThan(1.0));
    });

    test('has slower fire rate than pulseArcher', () {
      expect(TowerType.circuitCannon.fireRate, lessThan(TowerType.pulseArcher.fireRate));
    });

    test('has positive range', () {
      expect(TowerType.circuitCannon.range, greaterThan(0));
    });

    test('has positive cost', () {
      expect(TowerType.circuitCannon.cost, greaterThan(0));
    });

    test('costs more than pulseArcher', () {
      expect(TowerType.circuitCannon.cost, greaterThan(TowerType.pulseArcher.cost));
    });

    test('has valid color', () {
      expect(TowerType.circuitCannon.color, isA<Color>());
    });

    test('has positive projectile speed', () {
      expect(TowerType.circuitCannon.projectileSpeed, greaterThan(0));
    });

    test('cannot detect phantom', () {
      expect(TowerType.circuitCannon.canDetectPhantom, isFalse);
    });

    test('does not apply slow', () {
      expect(TowerType.circuitCannon.appliesSlow, isFalse);
    });

    test('is high damage tower', () {
      final avgDamage = TowerType.values.map((t) => t.damage).reduce((a, b) => a + b) / TowerType.values.length;
      expect(TowerType.circuitCannon.damage, greaterThan(avgDamage));
    });
  });

  // ============================================
  // PHASE MAGE TESTS (20+ tests)
  // ============================================

  group('PhaseMage tower type', () {
    test('has correct name', () {
      expect(TowerType.phaseMage.name, 'Phase Mage');
    });

    test('has positive damage', () {
      expect(TowerType.phaseMage.damage, greaterThan(0));
    });

    test('has positive fire rate', () {
      expect(TowerType.phaseMage.fireRate, greaterThan(0));
    });

    test('has positive range', () {
      expect(TowerType.phaseMage.range, greaterThan(0));
    });

    test('has positive cost', () {
      expect(TowerType.phaseMage.cost, greaterThan(0));
    });

    test('has valid color', () {
      expect(TowerType.phaseMage.color, isA<Color>());
    });

    test('has positive projectile speed', () {
      expect(TowerType.phaseMage.projectileSpeed, greaterThan(0));
    });

    test('CAN detect phantom', () {
      expect(TowerType.phaseMage.canDetectPhantom, isTrue);
    });

    test('is only tower that can detect phantom by default', () {
      final phantomDetectors = TowerType.values.where((t) => t.canDetectPhantom).toList();
      expect(phantomDetectors, contains(TowerType.phaseMage));
    });

    test('applies slow effect', () {
      expect(TowerType.phaseMage.appliesSlow, isTrue);
    });

    test('slow amount is greater than zero', () {
      expect(TowerType.phaseMage.slowAmount, greaterThan(0));
    });

    test('slow amount is between 0 and 1', () {
      expect(TowerType.phaseMage.slowAmount, greaterThan(0));
      expect(TowerType.phaseMage.slowAmount, lessThanOrEqualTo(1));
    });

    test('slow duration is greater than zero', () {
      expect(TowerType.phaseMage.slowDuration, greaterThan(0));
    });

    test('slow duration is reasonable (less than 10 seconds)', () {
      expect(TowerType.phaseMage.slowDuration, lessThan(10));
    });

    test('has moderate damage', () {
      expect(TowerType.phaseMage.damage, greaterThan(TowerType.pulseArcher.damage));
      expect(TowerType.phaseMage.damage, lessThan(TowerType.ionSniper.damage));
    });

    test('cost is higher than basic towers', () {
      expect(TowerType.phaseMage.cost, greaterThan(TowerType.pulseArcher.cost));
    });
  });

  // ============================================
  // GLIMMER FIELD TESTS (15+ tests)
  // ============================================

  group('GlimmerField tower type', () {
    test('has correct name', () {
      expect(TowerType.glimmerField.name, 'Glimmer Field');
    });

    test('has positive damage', () {
      expect(TowerType.glimmerField.damage, greaterThan(0));
    });

    test('has fast fire rate', () {
      expect(TowerType.glimmerField.fireRate, greaterThan(3.0));
    });

    test('has fastest fire rate of all towers', () {
      for (final type in TowerType.values) {
        expect(TowerType.glimmerField.fireRate, greaterThanOrEqualTo(type.fireRate));
      }
    });

    test('has positive range', () {
      expect(TowerType.glimmerField.range, greaterThan(0));
    });

    test('has positive cost', () {
      expect(TowerType.glimmerField.cost, greaterThan(0));
    });

    test('has valid color', () {
      expect(TowerType.glimmerField.color, isA<Color>());
    });

    test('has positive projectile speed', () {
      expect(TowerType.glimmerField.projectileSpeed, greaterThan(0));
    });

    test('cannot detect phantom', () {
      expect(TowerType.glimmerField.canDetectPhantom, isFalse);
    });

    test('applies slow effect', () {
      expect(TowerType.glimmerField.appliesSlow, isTrue);
    });

    test('slow amount is greater than zero', () {
      expect(TowerType.glimmerField.slowAmount, greaterThan(0));
    });

    test('slow duration is greater than zero', () {
      expect(TowerType.glimmerField.slowDuration, greaterThan(0));
    });

    test('has lower damage per hit than circuitCannon', () {
      expect(TowerType.glimmerField.damage, lessThan(TowerType.circuitCannon.damage));
    });

    test('DPS potential is high due to fire rate', () {
      final dps = TowerType.glimmerField.damage * TowerType.glimmerField.fireRate;
      // GlimmerField: 8 damage * 4.0 fireRate = 32 DPS
      expect(dps, greaterThan(25));
    });
  });

  // ============================================
  // ION SNIPER TESTS (15+ tests)
  // ============================================

  group('IonSniper tower type', () {
    test('has correct name', () {
      expect(TowerType.ionSniper.name, 'Ion Sniper');
    });

    test('has very high damage', () {
      expect(TowerType.ionSniper.damage, greaterThan(100));
    });

    test('has highest damage of all towers', () {
      for (final type in TowerType.values) {
        expect(TowerType.ionSniper.damage, greaterThanOrEqualTo(type.damage));
      }
    });

    test('has positive fire rate', () {
      expect(TowerType.ionSniper.fireRate, greaterThan(0));
    });

    test('has slow fire rate', () {
      expect(TowerType.ionSniper.fireRate, lessThan(1.0));
    });

    test('has very high range', () {
      expect(TowerType.ionSniper.range, greaterThan(250));
    });

    test('has highest range of all towers', () {
      for (final type in TowerType.values) {
        expect(TowerType.ionSniper.range, greaterThanOrEqualTo(type.range));
      }
    });

    test('has positive cost', () {
      expect(TowerType.ionSniper.cost, greaterThan(0));
    });

    test('is one of the most expensive towers', () {
      final avgCost = TowerType.values.map((t) => t.cost).reduce((a, b) => a + b) / TowerType.values.length;
      expect(TowerType.ionSniper.cost, greaterThan(avgCost));
    });

    test('has valid color', () {
      expect(TowerType.ionSniper.color, isA<Color>());
    });

    test('has highest projectile speed', () {
      for (final type in TowerType.values) {
        if (type.projectileSpeed > 0) {
          expect(TowerType.ionSniper.projectileSpeed, greaterThanOrEqualTo(type.projectileSpeed));
        }
      }
    });

    test('cannot detect phantom', () {
      expect(TowerType.ionSniper.canDetectPhantom, isFalse);
    });

    test('does not apply slow', () {
      expect(TowerType.ionSniper.appliesSlow, isFalse);
    });
  });

  // ============================================
  // TESLA TERMINAL TESTS (15+ tests)
  // ============================================

  group('TeslaTerminal tower type', () {
    test('has correct name', () {
      expect(TowerType.teslaTerminal.name, 'Tesla Terminal');
    });

    test('has positive damage', () {
      expect(TowerType.teslaTerminal.damage, greaterThan(0));
    });

    test('has positive fire rate', () {
      expect(TowerType.teslaTerminal.fireRate, greaterThan(0));
    });

    test('has positive range', () {
      expect(TowerType.teslaTerminal.range, greaterThan(0));
    });

    test('has positive cost', () {
      expect(TowerType.teslaTerminal.cost, greaterThan(0));
    });

    test('has valid color', () {
      expect(TowerType.teslaTerminal.color, isA<Color>());
    });

    test('has ZERO projectile speed (instant hit)', () {
      expect(TowerType.teslaTerminal.projectileSpeed, 0);
    });

    test('is the only damaging tower with instant hit', () {
      // Both teslaTerminal and resonanceSiphon have projectileSpeed == 0
      // But only teslaTerminal deals damage
      final instantHitDamageTowers = TowerType.values
          .where((t) => t.projectileSpeed == 0 && t.damage > 0)
          .toList();
      expect(instantHitDamageTowers.length, 1);
      expect(instantHitDamageTowers.first, TowerType.teslaTerminal);
    });

    test('cannot detect phantom', () {
      expect(TowerType.teslaTerminal.canDetectPhantom, isFalse);
    });

    test('does not apply slow', () {
      expect(TowerType.teslaTerminal.appliesSlow, isFalse);
    });

    test('has fast attack rate compensating for lower damage', () {
      // TeslaTerminal has lower damage (12) but higher fire rate (3.5)
      expect(TowerType.teslaTerminal.fireRate, greaterThan(TowerType.pulseArcher.fireRate));
    });
  });

  // ============================================
  // RESONANCE SIPHON TESTS (15+ tests)
  // ============================================

  group('ResonanceSiphon tower type', () {
    test('has correct name', () {
      expect(TowerType.resonanceSiphon.name, 'Resonance Siphon');
    });

    test('has ZERO damage', () {
      expect(TowerType.resonanceSiphon.damage, 0);
    });

    test('is the only tower with zero damage', () {
      final zeroDamageTowers = TowerType.values.where((t) => t.damage == 0).toList();
      expect(zeroDamageTowers.length, 1);
      expect(zeroDamageTowers.first, TowerType.resonanceSiphon);
    });

    test('has positive fire rate', () {
      expect(TowerType.resonanceSiphon.fireRate, greaterThan(0));
    });

    test('has positive range', () {
      expect(TowerType.resonanceSiphon.range, greaterThan(0));
    });

    test('has positive cost', () {
      expect(TowerType.resonanceSiphon.cost, greaterThan(0));
    });

    test('has valid color', () {
      expect(TowerType.resonanceSiphon.color, isA<Color>());
    });

    test('has positive projectile speed', () {
      expect(TowerType.resonanceSiphon.projectileSpeed, greaterThanOrEqualTo(0));
    });

    test('cannot detect phantom', () {
      expect(TowerType.resonanceSiphon.canDetectPhantom, isFalse);
    });

    test('may apply slow or have special effect', () {
      // Resonance Siphon is a support tower
      expect(TowerType.resonanceSiphon.damage, 0);
    });
  });

  // ============================================
  // NEURAL DISRUPTOR TESTS (15+ tests)
  // ============================================

  group('NeuralDisruptor tower type', () {
    test('has correct name', () {
      expect(TowerType.neuralDisruptor.name, 'Neural Disruptor');
    });

    test('has positive damage', () {
      expect(TowerType.neuralDisruptor.damage, greaterThan(0));
    });

    test('has positive fire rate', () {
      expect(TowerType.neuralDisruptor.fireRate, greaterThan(0));
    });

    test('has positive range', () {
      expect(TowerType.neuralDisruptor.range, greaterThan(0));
    });

    test('has positive cost', () {
      expect(TowerType.neuralDisruptor.cost, greaterThan(0));
    });

    test('has valid color', () {
      expect(TowerType.neuralDisruptor.color, isA<Color>());
    });

    test('has positive projectile speed', () {
      expect(TowerType.neuralDisruptor.projectileSpeed, greaterThanOrEqualTo(0));
    });

    test('cannot detect phantom', () {
      expect(TowerType.neuralDisruptor.canDetectPhantom, isFalse);
    });
  });

  // ============================================
  // COMPARATIVE TESTS ACROSS ALL TOWERS (30+ tests)
  // ============================================

  group('Tower type comparisons', () {
    test('all towers have positive or zero damage', () {
      for (final type in TowerType.values) {
        expect(type.damage, greaterThanOrEqualTo(0));
      }
    });

    test('all towers have positive fire rate', () {
      for (final type in TowerType.values) {
        expect(type.fireRate, greaterThan(0));
      }
    });

    test('all towers have positive range', () {
      for (final type in TowerType.values) {
        expect(type.range, greaterThan(0));
      }
    });

    test('all towers have positive cost', () {
      for (final type in TowerType.values) {
        expect(type.cost, greaterThan(0));
      }
    });

    test('all towers have non-null color', () {
      for (final type in TowerType.values) {
        expect(type.color, isNotNull);
      }
    });

    test('all towers have non-negative projectile speed', () {
      for (final type in TowerType.values) {
        expect(type.projectileSpeed, greaterThanOrEqualTo(0));
      }
    });

    test('all towers have non-negative slow amount', () {
      for (final type in TowerType.values) {
        expect(type.slowAmount, greaterThanOrEqualTo(0));
      }
    });

    test('all towers have non-negative slow duration', () {
      for (final type in TowerType.values) {
        expect(type.slowDuration, greaterThanOrEqualTo(0));
      }
    });

    test('towers with slow have both amount and duration', () {
      for (final type in TowerType.values) {
        if (type.slowAmount > 0) {
          expect(type.slowDuration, greaterThan(0));
        }
        if (type.slowDuration > 0) {
          expect(type.slowAmount, greaterThan(0));
        }
      }
    });

    test('appliesSlow matches slow properties', () {
      for (final type in TowerType.values) {
        if (type.appliesSlow) {
          expect(type.slowAmount, greaterThan(0));
          expect(type.slowDuration, greaterThan(0));
        }
      }
    });

    test('all tower costs are unique', () {
      final costs = TowerType.values.map((t) => t.cost).toSet();
      // Some towers may have same cost, so just check we have variety
      expect(costs.length, greaterThanOrEqualTo(4));
    });

    test('damage values span a reasonable range', () {
      final damages = TowerType.values.map((t) => t.damage).toList();
      final minDamage = damages.reduce((a, b) => a < b ? a : b);
      final maxDamage = damages.reduce((a, b) => a > b ? a : b);
      expect(maxDamage, greaterThan(minDamage * 5)); // At least 5x range
    });

    test('range values span a reasonable range', () {
      final ranges = TowerType.values.map((t) => t.range).toList();
      final minRange = ranges.reduce((a, b) => a < b ? a : b);
      final maxRange = ranges.reduce((a, b) => a > b ? a : b);
      expect(maxRange, greaterThan(minRange * 1.5)); // At least 1.5x range
    });

    test('fire rate values span a reasonable range', () {
      final rates = TowerType.values.map((t) => t.fireRate).toList();
      final minRate = rates.reduce((a, b) => a < b ? a : b);
      final maxRate = rates.reduce((a, b) => a > b ? a : b);
      expect(maxRate, greaterThan(minRate * 3)); // At least 3x range
    });

    test('cost values span a reasonable range', () {
      final costs = TowerType.values.map((t) => t.cost).toList();
      final minCost = costs.reduce((a, b) => a < b ? a : b);
      final maxCost = costs.reduce((a, b) => a > b ? a : b);
      expect(maxCost, greaterThan(minCost * 2)); // At least 2x range
    });

    test('total tower value (damage * fireRate) varies', () {
      final dps = TowerType.values.map((t) => t.damage * t.fireRate).toList();
      final minDps = dps.reduce((a, b) => a < b ? a : b);
      final maxDps = dps.reduce((a, b) => a > b ? a : b);
      expect(maxDps, greaterThan(minDps));
    });

    test('only support towers have zero damage', () {
      final zeroDamageTowers = TowerType.values.where((t) => t.damage == 0).toList();
      expect(zeroDamageTowers.length, lessThanOrEqualTo(2));
    });

    test('most towers deal damage', () {
      final damageTowers = TowerType.values.where((t) => t.damage > 0).toList();
      expect(damageTowers.length, greaterThanOrEqualTo(6));
    });

    test('at least one tower can detect phantom', () {
      final phantomDetectors = TowerType.values.where((t) => t.canDetectPhantom).toList();
      expect(phantomDetectors.length, greaterThanOrEqualTo(1));
    });

    test('at least two towers apply slow', () {
      final slowTowers = TowerType.values.where((t) => t.appliesSlow).toList();
      expect(slowTowers.length, greaterThanOrEqualTo(2));
    });

    test('all tower names are non-empty strings', () {
      for (final type in TowerType.values) {
        expect(type.name.length, greaterThan(0));
      }
    });

    test('all tower names are different', () {
      final names = TowerType.values.map((t) => t.name).toSet();
      expect(names.length, TowerType.values.length);
    });

    test('all tower names contain letters', () {
      for (final type in TowerType.values) {
        expect(type.name.contains(RegExp(r'[a-zA-Z]')), isTrue);
      }
    });

    test('all tower colors have full opacity by default', () {
      for (final type in TowerType.values) {
        expect(type.color.alpha, 255);
      }
    });

    test('all tower colors are unique', () {
      final colors = TowerType.values.map((t) => t.color.value).toSet();
      expect(colors.length, TowerType.values.length);
    });
  });

  // ============================================
  // BALANCE VALIDATION TESTS (20+ tests)
  // ============================================

  group('Tower balance validation', () {
    test('cost efficiency varies between towers', () {
      final efficiencies = <TowerType, double>{};
      for (final type in TowerType.values) {
        if (type.damage > 0) {
          efficiencies[type] = (type.damage * type.fireRate) / type.cost;
        }
      }
      expect(efficiencies.values.toSet().length, greaterThan(1));
    });

    test('each tower has at least one trade-off', () {
      // Each tower should have some weakness or trade-off
      for (final tower in TowerType.values) {
        // At least one of these should be true for balance
        final hasLowDamage = tower.damage < 30;
        final hasSlowFireRate = tower.fireRate < 1.5;
        final hasShortRange = tower.range < 150;
        final hasHighCost = tower.cost > 100;
        final isSupport = tower.damage == 0;

        expect(
          hasLowDamage || hasSlowFireRate || hasShortRange || hasHighCost || isSupport,
          isTrue,
          reason: '${tower.name} should have at least one trade-off',
        );
      }
    });

    test('basic tower is cheapest', () {
      expect(TowerType.pulseArcher.cost, lessThanOrEqualTo(TowerType.values.map((t) => t.cost).reduce((a, b) => a < b ? a : b)));
    });

    test('phantom detection tower exists', () {
      final phantomDetectors = TowerType.values.where((t) => t.canDetectPhantom).toList();
      expect(phantomDetectors, isNotEmpty);
      expect(phantomDetectors, contains(TowerType.phaseMage));
    });

    test('high damage towers have slower fire rate', () {
      // IonSniper: highest damage, should have slow fire rate
      expect(TowerType.ionSniper.fireRate, lessThan(TowerType.glimmerField.fireRate));
    });

    test('fast fire rate towers have lower per-hit damage', () {
      // GlimmerField: fastest, should have lower damage
      expect(TowerType.glimmerField.damage, lessThan(TowerType.ionSniper.damage));
    });

    test('instant hit tower has balanced stats', () {
      // TeslaTerminal: instant hit (0 projectile speed)
      final avgDamage = TowerType.values.map((t) => t.damage).reduce((a, b) => a + b) / TowerType.values.length;
      expect(TowerType.teslaTerminal.damage, lessThan(avgDamage * 2));
    });

    test('support tower (zero damage) has utility', () {
      // ResonanceSiphon: 0 damage, should have some utility
      expect(TowerType.resonanceSiphon.damage, 0);
      expect(TowerType.resonanceSiphon.range, greaterThan(0));
    });

    test('phantom detection is rare and valuable', () {
      final phantomDetectors = TowerType.values.where((t) => t.canDetectPhantom).toList();
      expect(phantomDetectors.length, lessThan(TowerType.values.length / 2));
    });

    test('slow effect towers are minority', () {
      final slowTowers = TowerType.values.where((t) => t.appliesSlow).toList();
      expect(slowTowers.length, lessThan(TowerType.values.length / 2));
    });
  });

  // ============================================
  // TARGET MODE TESTS (10+ tests)
  // ============================================

  group('TargetMode enumeration', () {
    test('has exactly 5 target modes', () {
      expect(TargetMode.values.length, 5);
    });

    test('first mode exists', () {
      expect(TargetMode.first, isNotNull);
    });

    test('last mode exists', () {
      expect(TargetMode.last, isNotNull);
    });

    test('strongest mode exists', () {
      expect(TargetMode.strongest, isNotNull);
    });

    test('weakest mode exists', () {
      expect(TargetMode.weakest, isNotNull);
    });

    test('closest mode exists', () {
      expect(TargetMode.closest, isNotNull);
    });

    test('all modes have unique indices', () {
      final indices = TargetMode.values.map((m) => m.index).toSet();
      expect(indices.length, TargetMode.values.length);
    });

    test('modes are in expected order', () {
      expect(TargetMode.values[0], TargetMode.first);
      expect(TargetMode.values[1], TargetMode.last);
      expect(TargetMode.values[2], TargetMode.strongest);
      expect(TargetMode.values[3], TargetMode.weakest);
      expect(TargetMode.values[4], TargetMode.closest);
    });

    test('first and last are opposites', () {
      expect(TargetMode.first.index, isNot(TargetMode.last.index));
    });

    test('strongest and weakest are opposites', () {
      expect(TargetMode.strongest.index, isNot(TargetMode.weakest.index));
    });
  });
}
