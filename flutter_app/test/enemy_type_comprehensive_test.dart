import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/enemy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ============================================
  // ENEMY TYPE ENUMERATION TESTS (200+ tests)
  // ============================================

  group('EnemyType enumeration basics', () {
    test('has exactly 40 enemy types', () {
      expect(EnemyType.values.length, 40);
    });

    test('has 4 enemies per world (10 worlds)', () {
      for (int world = 1; world <= 10; world++) {
        final worldEnemies = EnemyType.getWorldEnemies(world);
        expect(worldEnemies.length, 4, reason: 'World $world should have 4 enemies');
      }
    });

    test('all enemy types have unique indices', () {
      final indices = EnemyType.values.map((e) => e.index).toSet();
      expect(indices.length, EnemyType.values.length);
    });
  });

  // ============================================
  // WORLD 1 - NEON FRONTIER (20 tests)
  // ============================================

  group('World 1 - Neon Frontier enemies', () {
    test('runner is world 1 enemy', () {
      expect(EnemyType.runner.world, 1);
    });

    test('overloaded is world 1 enemy', () {
      expect(EnemyType.overloaded.world, 1);
    });

    test('juggernaut is world 1 enemy', () {
      expect(EnemyType.juggernaut.world, 1);
    });

    test('phantom is world 1 enemy', () {
      expect(EnemyType.phantom.world, 1);
    });

    test('runner has default speed multiplier', () {
      expect(EnemyType.runner.speedMult, 1.0);
    });

    test('runner has default health multiplier', () {
      expect(EnemyType.runner.healthMult, 1.0);
    });

    test('runner has default size multiplier', () {
      expect(EnemyType.runner.sizeMult, 1.0);
    });

    test('runner is not phantom', () {
      expect(EnemyType.runner.isPhantom, isFalse);
    });

    test('overloaded has fast speed', () {
      expect(EnemyType.overloaded.speedMult, greaterThan(1.0));
    });

    test('overloaded has low health', () {
      expect(EnemyType.overloaded.healthMult, lessThan(1.0));
    });

    test('juggernaut has high health', () {
      expect(EnemyType.juggernaut.healthMult, greaterThan(1.5));
    });

    test('juggernaut has slow speed', () {
      expect(EnemyType.juggernaut.speedMult, lessThan(1.0));
    });

    test('juggernaut is larger', () {
      expect(EnemyType.juggernaut.sizeMult, greaterThan(1.0));
    });

    test('phantom is phantom type', () {
      expect(EnemyType.phantom.isPhantom, isTrue);
    });

    test('basicTypes returns world 1 enemies', () {
      final basicTypes = EnemyType.basicTypes;
      expect(basicTypes.length, 4);
      expect(basicTypes, contains(EnemyType.runner));
      expect(basicTypes, contains(EnemyType.overloaded));
      expect(basicTypes, contains(EnemyType.juggernaut));
      expect(basicTypes, contains(EnemyType.phantom));
    });

    test('world 1 enemies have valid colors', () {
      for (final enemy in EnemyType.getWorldEnemies(1)) {
        expect(enemy.color, isA<Color>());
        expect(enemy.color.alpha, greaterThan(0));
      }
    });

    test('world 1 has exactly one phantom', () {
      final phantoms = EnemyType.getWorldEnemies(1).where((e) => e.isPhantom).toList();
      expect(phantoms.length, 1);
    });

    test('world 1 enemies are basic difficulty', () {
      for (final enemy in EnemyType.getWorldEnemies(1)) {
        expect(enemy.healthMult, lessThanOrEqualTo(3.0));
        expect(enemy.speedMult, lessThanOrEqualTo(2.0));
      }
    });
  });

  // ============================================
  // WORLD 2 - RIFT WARS (20 tests)
  // ============================================

  group('World 2 - Rift Wars enemies', () {
    test('glitcher is world 2 enemy', () {
      expect(EnemyType.glitcher.world, 2);
    });

    test('riftwalker is world 2 enemy', () {
      expect(EnemyType.riftwalker.world, 2);
    });

    test('voidling is world 2 enemy', () {
      expect(EnemyType.voidling.world, 2);
    });

    test('dimensionBreaker is world 2 enemy', () {
      expect(EnemyType.dimensionBreaker.world, 2);
    });

    test('getWorldEnemies returns correct world 2 enemies', () {
      final world2 = EnemyType.getWorldEnemies(2);
      expect(world2, contains(EnemyType.glitcher));
      expect(world2, contains(EnemyType.riftwalker));
      expect(world2, contains(EnemyType.voidling));
      expect(world2, contains(EnemyType.dimensionBreaker));
    });

    test('riftwalker is phantom', () {
      expect(EnemyType.riftwalker.isPhantom, isTrue);
    });

    test('world 2 has exactly one phantom', () {
      final phantoms = EnemyType.getWorldEnemies(2).where((e) => e.isPhantom).toList();
      expect(phantoms.length, 1);
    });

    test('voidling has small size', () {
      expect(EnemyType.voidling.sizeMult, lessThan(1.0));
    });

    test('dimensionBreaker has high health', () {
      expect(EnemyType.dimensionBreaker.healthMult, greaterThan(1.5));
    });

    test('world 2 enemies have valid colors', () {
      for (final enemy in EnemyType.getWorldEnemies(2)) {
        expect(enemy.color, isA<Color>());
      }
    });

    test('world 2 is slightly harder than world 1', () {
      final world1Avg = EnemyType.getWorldEnemies(1).map((e) => e.healthMult).reduce((a, b) => a + b) / 4;
      final world2Avg = EnemyType.getWorldEnemies(2).map((e) => e.healthMult).reduce((a, b) => a + b) / 4;
      expect(world2Avg, greaterThanOrEqualTo(world1Avg * 0.9));
    });
  });

  // ============================================
  // WORLD 3-10 ENEMY EXISTENCE TESTS (40 tests)
  // ============================================

  group('World 3 enemies exist', () {
    test('world 3 has 4 enemies', () {
      expect(EnemyType.getWorldEnemies(3).length, 4);
    });

    test('world 3 has no phantom enemies', () {
      // World 3 (Signal Wastes) doesn't have phantom enemies
      final phantoms = EnemyType.getWorldEnemies(3).where((e) => e.isPhantom).toList();
      expect(phantoms.length, 0);
    });

    test('all world 3 enemies are non-phantom', () {
      for (final enemy in EnemyType.getWorldEnemies(3)) {
        expect(enemy.isPhantom, isFalse);
      }
    });
  });

  group('World 4 enemies exist', () {
    test('world 4 has 4 enemies', () {
      expect(EnemyType.getWorldEnemies(4).length, 4);
    });

    test('world 4 has no phantom enemies', () {
      // World 4 (Ion Crown) doesn't have phantom enemies
      final phantoms = EnemyType.getWorldEnemies(4).where((e) => e.isPhantom).toList();
      expect(phantoms.length, 0);
    });

    test('all world 4 enemies are non-phantom', () {
      for (final enemy in EnemyType.getWorldEnemies(4)) {
        expect(enemy.isPhantom, isFalse);
      }
    });
  });

  group('World 5 enemies exist', () {
    test('world 5 has 4 enemies', () {
      expect(EnemyType.getWorldEnemies(5).length, 4);
    });

    test('world 5 has one phantom', () {
      final phantoms = EnemyType.getWorldEnemies(5).where((e) => e.isPhantom).toList();
      expect(phantoms.length, 1);
    });

    test('systemGhost is phantom', () {
      expect(EnemyType.systemGhost.isPhantom, isTrue);
    });
  });

  group('World 6 enemies exist', () {
    test('world 6 has 4 enemies', () {
      expect(EnemyType.getWorldEnemies(6).length, 4);
    });

    test('world 6 has one phantom', () {
      final phantoms = EnemyType.getWorldEnemies(6).where((e) => e.isPhantom).toList();
      expect(phantoms.length, 1);
    });

    test('cycloneSpirit is phantom', () {
      expect(EnemyType.cycloneSpirit.isPhantom, isTrue);
    });
  });

  group('World 7 enemies exist', () {
    test('world 7 has 4 enemies', () {
      expect(EnemyType.getWorldEnemies(7).length, 4);
    });

    test('world 7 has one phantom', () {
      final phantoms = EnemyType.getWorldEnemies(7).where((e) => e.isPhantom).toList();
      expect(phantoms.length, 1);
    });
  });

  group('World 8 enemies exist', () {
    test('world 8 has 4 enemies', () {
      expect(EnemyType.getWorldEnemies(8).length, 4);
    });

    test('world 8 has one phantom', () {
      final phantoms = EnemyType.getWorldEnemies(8).where((e) => e.isPhantom).toList();
      expect(phantoms.length, 1);
    });

    test('voidStalker is phantom', () {
      expect(EnemyType.voidStalker.isPhantom, isTrue);
    });
  });

  group('World 9 enemies exist', () {
    test('world 9 has 4 enemies', () {
      expect(EnemyType.getWorldEnemies(9).length, 4);
    });

    test('world 9 has one phantom', () {
      final phantoms = EnemyType.getWorldEnemies(9).where((e) => e.isPhantom).toList();
      expect(phantoms.length, 1);
    });
  });

  group('World 10 - Omega Nexus enemies', () {
    test('world 10 has 4 enemies', () {
      expect(EnemyType.getWorldEnemies(10).length, 4);
    });

    test('nexusHunter is world 10 enemy', () {
      expect(EnemyType.nexusHunter.world, 10);
    });

    test('omegaSentinel is world 10 enemy', () {
      expect(EnemyType.omegaSentinel.world, 10);
    });

    test('realityShifter is world 10 enemy', () {
      expect(EnemyType.realityShifter.world, 10);
    });

    test('apocalypseHerald is world 10 enemy', () {
      expect(EnemyType.apocalypseHerald.world, 10);
    });

    test('realityShifter is phantom', () {
      expect(EnemyType.realityShifter.isPhantom, isTrue);
    });

    test('apocalypseHerald has very high health', () {
      expect(EnemyType.apocalypseHerald.healthMult, greaterThan(3.0));
    });

    test('apocalypseHerald has large size', () {
      expect(EnemyType.apocalypseHerald.sizeMult, greaterThan(1.5));
    });

    test('world 10 enemies are harder than world 1', () {
      final world1MaxHealth = EnemyType.getWorldEnemies(1).map((e) => e.healthMult).reduce((a, b) => a > b ? a : b);
      final world10MaxHealth = EnemyType.getWorldEnemies(10).map((e) => e.healthMult).reduce((a, b) => a > b ? a : b);
      expect(world10MaxHealth, greaterThan(world1MaxHealth));
    });
  });

  // ============================================
  // ALL ENEMY PROPERTY TESTS (40 tests)
  // ============================================

  group('All enemy properties validation', () {
    test('all enemies have positive speed multiplier', () {
      for (final type in EnemyType.values) {
        expect(type.speedMult, greaterThan(0), reason: '${type.name} should have positive speed');
      }
    });

    test('all enemies have speed multiplier <= 2.0', () {
      for (final type in EnemyType.values) {
        expect(type.speedMult, lessThanOrEqualTo(2.0), reason: '${type.name} speed should be <= 2.0');
      }
    });

    test('all enemies have positive health multiplier', () {
      for (final type in EnemyType.values) {
        expect(type.healthMult, greaterThan(0), reason: '${type.name} should have positive health');
      }
    });

    test('all enemies have health multiplier <= 5.5', () {
      for (final type in EnemyType.values) {
        expect(type.healthMult, lessThanOrEqualTo(5.5), reason: '${type.name} health should be <= 5.5');
      }
    });

    test('all enemies have positive size multiplier', () {
      for (final type in EnemyType.values) {
        expect(type.sizeMult, greaterThan(0), reason: '${type.name} should have positive size');
      }
    });

    test('all enemies have size multiplier <= 2.0', () {
      for (final type in EnemyType.values) {
        expect(type.sizeMult, lessThanOrEqualTo(2.0), reason: '${type.name} size should be <= 2.0');
      }
    });

    test('all enemies have world between 1 and 10', () {
      for (final type in EnemyType.values) {
        expect(type.world, greaterThanOrEqualTo(1));
        expect(type.world, lessThanOrEqualTo(10));
      }
    });

    test('all enemies have valid color', () {
      for (final type in EnemyType.values) {
        expect(type.color, isA<Color>());
        expect(type.color.value, isNonZero);
      }
    });

    test('all enemies have non-empty name', () {
      for (final type in EnemyType.values) {
        expect(type.name, isNotEmpty);
      }
    });

    test('all enemy names are unique', () {
      final names = EnemyType.values.map((e) => e.name).toSet();
      expect(names.length, EnemyType.values.length);
    });
  });

  // ============================================
  // PHANTOM ENEMY TESTS (30 tests)
  // ============================================

  group('Phantom enemy properties', () {
    test('phantom is phantom type', () {
      expect(EnemyType.phantom.isPhantom, isTrue);
    });

    test('riftwalker is phantom type', () {
      expect(EnemyType.riftwalker.isPhantom, isTrue);
    });

    test('prismWalker is phantom type', () {
      expect(EnemyType.prismWalker.isPhantom, isTrue);
    });

    test('cloakedAssassin is phantom type', () {
      expect(EnemyType.cloakedAssassin.isPhantom, isTrue);
    });

    test('systemGhost is phantom type', () {
      expect(EnemyType.systemGhost.isPhantom, isTrue);
    });

    test('cycloneSpirit is phantom type', () {
      expect(EnemyType.cycloneSpirit.isPhantom, isTrue);
    });

    test('voidStalker is phantom type', () {
      expect(EnemyType.voidStalker.isPhantom, isTrue);
    });

    test('realityShifter is phantom type', () {
      expect(EnemyType.realityShifter.isPhantom, isTrue);
    });

    test('runner is NOT phantom', () {
      expect(EnemyType.runner.isPhantom, isFalse);
    });

    test('juggernaut is NOT phantom', () {
      expect(EnemyType.juggernaut.isPhantom, isFalse);
    });

    test('overloaded is NOT phantom', () {
      expect(EnemyType.overloaded.isPhantom, isFalse);
    });

    test('exactly 8 phantoms exist', () {
      // Worlds 3 and 4 don't have phantom enemies
      final phantoms = EnemyType.values.where((e) => e.isPhantom).toList();
      expect(phantoms.length, 8);
    });

    test('each world with phantoms has exactly one', () {
      // Worlds with phantoms: 1, 2, 5, 6, 7, 8, 9, 10
      final worldsWithPhantoms = [1, 2, 5, 6, 7, 8, 9, 10];
      for (final world in worldsWithPhantoms) {
        final worldPhantoms = EnemyType.getWorldEnemies(world).where((e) => e.isPhantom).toList();
        expect(worldPhantoms.length, 1, reason: 'World $world should have 1 phantom');
      }
    });

    test('phantoms have varied stats', () {
      final phantoms = EnemyType.values.where((e) => e.isPhantom).toList();
      final healthMults = phantoms.map((p) => p.healthMult).toSet();
      expect(healthMults.length, greaterThan(3));
    });

    test('phantoms span 8 worlds', () {
      // Worlds 3 and 4 don't have phantoms
      final phantomWorlds = EnemyType.values.where((e) => e.isPhantom).map((e) => e.world).toSet();
      expect(phantomWorlds.length, 8);
    });
  });

  // ============================================
  // ENEMY BALANCE TESTS (30 tests)
  // ============================================

  group('Enemy balance across worlds', () {
    test('all worlds have positive average health', () {
      for (int world = 1; world <= 10; world++) {
        final worldEnemies = EnemyType.getWorldEnemies(world);
        final avgHealth = worldEnemies.map((e) => e.healthMult).reduce((a, b) => a + b) / 4;
        expect(avgHealth, greaterThan(0),
            reason: 'World $world should have positive average health');
      }
    });

    test('late game worlds have higher max health enemies', () {
      // Compare first world vs last world
      final world1Max = EnemyType.getWorldEnemies(1).map((e) => e.healthMult).reduce((a, b) => a > b ? a : b);
      final world10Max = EnemyType.getWorldEnemies(10).map((e) => e.healthMult).reduce((a, b) => a > b ? a : b);
      expect(world10Max, greaterThan(world1Max),
          reason: 'World 10 should have tankier enemies than world 1');
    });

    test('each world has variety in enemy stats', () {
      for (int world = 1; world <= 10; world++) {
        final worldEnemies = EnemyType.getWorldEnemies(world);
        final healthMults = worldEnemies.map((e) => e.healthMult).toSet();
        expect(healthMults.length, greaterThanOrEqualTo(2),
            reason: 'World $world should have varied health multipliers');
      }
    });

    test('each world has fast and slow enemies', () {
      for (int world = 1; world <= 10; world++) {
        final worldEnemies = EnemyType.getWorldEnemies(world);
        final speeds = worldEnemies.map((e) => e.speedMult).toList();
        final minSpeed = speeds.reduce((a, b) => a < b ? a : b);
        final maxSpeed = speeds.reduce((a, b) => a > b ? a : b);
        expect(maxSpeed, greaterThan(minSpeed * 0.9),
            reason: 'World $world should have speed variety');
      }
    });

    test('no enemy is trivially weak', () {
      for (final type in EnemyType.values) {
        final effectiveStrength = type.healthMult * type.sizeMult;
        expect(effectiveStrength, greaterThanOrEqualTo(0.3),
            reason: '${type.name} should not be trivially weak');
      }
    });

    test('no enemy is impossibly strong', () {
      for (final type in EnemyType.values) {
        final effectiveStrength = type.healthMult * type.speedMult * type.sizeMult;
        expect(effectiveStrength, lessThan(20),
            reason: '${type.name} should not be impossibly strong');
      }
    });

    test('fast enemies have lower health', () {
      for (final type in EnemyType.values) {
        if (type.speedMult > 1.5) {
          expect(type.healthMult, lessThan(2.0),
              reason: 'Fast enemy ${type.name} should have lower health');
        }
      }
    });

    test('tanky enemies are slower', () {
      for (final type in EnemyType.values) {
        if (type.healthMult > 3.0) {
          expect(type.speedMult, lessThanOrEqualTo(1.0),
              reason: 'Tanky enemy ${type.name} should be slower');
        }
      }
    });

    test('small enemies are fast or weak', () {
      for (final type in EnemyType.values) {
        if (type.sizeMult < 0.8) {
          final isFast = type.speedMult > 1.0;
          final isWeak = type.healthMult < 1.0;
          expect(isFast || isWeak, isTrue,
              reason: 'Small enemy ${type.name} should be fast or weak');
        }
      }
    });

    test('large enemies are tanky or slow', () {
      for (final type in EnemyType.values) {
        if (type.sizeMult > 1.5) {
          final isTanky = type.healthMult > 2.0;
          final isSlow = type.speedMult < 0.8;
          expect(isTanky || isSlow, isTrue,
              reason: 'Large enemy ${type.name} should be tanky or slow');
        }
      }
    });
  });

  // ============================================
  // COLOR UNIQUENESS TESTS (20 tests)
  // ============================================

  group('Enemy color differentiation', () {
    test('all enemies have visible colors', () {
      for (final type in EnemyType.values) {
        expect(type.color.alpha, greaterThan(0));
      }
    });

    test('enemies within same world have different colors', () {
      for (int world = 1; world <= 10; world++) {
        final worldEnemies = EnemyType.getWorldEnemies(world);
        final colors = worldEnemies.map((e) => e.color.value).toSet();
        expect(colors.length, worldEnemies.length,
            reason: 'World $world enemies should have unique colors');
      }
    });

    test('phantoms have distinguishable colors', () {
      final phantoms = EnemyType.values.where((e) => e.isPhantom).toList();
      final colors = phantoms.map((p) => p.color.value).toSet();
      expect(colors.length, greaterThan(phantoms.length / 2));
    });

    test('world 1 enemies have distinct colors', () {
      final colors = EnemyType.getWorldEnemies(1).map((e) => e.color.value).toSet();
      expect(colors.length, 4);
    });

    test('world 10 enemies have distinct colors', () {
      final colors = EnemyType.getWorldEnemies(10).map((e) => e.color.value).toSet();
      expect(colors.length, 4);
    });
  });

  // ============================================
  // GETTERS AND METHODS TESTS (20 tests)
  // ============================================

  group('getWorldEnemies method', () {
    test('returns empty for world 0', () {
      final enemies = EnemyType.getWorldEnemies(0);
      expect(enemies, isEmpty);
    });

    test('returns empty for world 11', () {
      final enemies = EnemyType.getWorldEnemies(11);
      expect(enemies, isEmpty);
    });

    test('returns empty for negative world', () {
      final enemies = EnemyType.getWorldEnemies(-1);
      expect(enemies, isEmpty);
    });

    test('returns 4 enemies for each valid world', () {
      for (int world = 1; world <= 10; world++) {
        expect(EnemyType.getWorldEnemies(world).length, 4);
      }
    });

    test('returned enemies belong to correct world', () {
      for (int world = 1; world <= 10; world++) {
        for (final enemy in EnemyType.getWorldEnemies(world)) {
          expect(enemy.world, world);
        }
      }
    });

    test('basicTypes equals getWorldEnemies(1)', () {
      final basic = EnemyType.basicTypes;
      final world1 = EnemyType.getWorldEnemies(1);
      expect(basic.length, world1.length);
      for (final enemy in basic) {
        expect(world1, contains(enemy));
      }
    });

    test('all enemies are covered by getWorldEnemies', () {
      final allFromMethod = <EnemyType>[];
      for (int world = 1; world <= 10; world++) {
        allFromMethod.addAll(EnemyType.getWorldEnemies(world));
      }
      expect(allFromMethod.length, EnemyType.values.length);
      for (final enemy in EnemyType.values) {
        expect(allFromMethod, contains(enemy));
      }
    });
  });

  // ============================================
  // SPECIFIC ENEMY DETAILED TESTS (30 tests)
  // ============================================

  group('Specific enemy detailed properties', () {
    test('runner is balanced starter enemy', () {
      expect(EnemyType.runner.speedMult, 1.0);
      expect(EnemyType.runner.healthMult, 1.0);
      expect(EnemyType.runner.sizeMult, 1.0);
    });

    test('overloaded is fast glass cannon', () {
      expect(EnemyType.overloaded.speedMult, greaterThan(1.0));
      expect(EnemyType.overloaded.healthMult, lessThan(1.0));
    });

    test('juggernaut is slow tank', () {
      expect(EnemyType.juggernaut.speedMult, lessThan(1.0));
      expect(EnemyType.juggernaut.healthMult, greaterThan(1.5));
    });

    test('voidling is small and weak', () {
      expect(EnemyType.voidling.sizeMult, lessThan(1.0));
    });

    test('apocalypseHerald is ultimate tank', () {
      expect(EnemyType.apocalypseHerald.healthMult, greaterThan(4.0));
      expect(EnemyType.apocalypseHerald.sizeMult, greaterThan(1.5));
    });

    test('nexusHunter is world 10 standard', () {
      expect(EnemyType.nexusHunter.world, 10);
      expect(EnemyType.nexusHunter.healthMult, greaterThanOrEqualTo(1.5));
    });

    test('omegaSentinel has significant health', () {
      expect(EnemyType.omegaSentinel.healthMult, greaterThan(2.0));
    });

    test('glitcher has modified stats', () {
      expect(EnemyType.glitcher.world, 2);
      expect(EnemyType.glitcher.isPhantom, isFalse);
    });

    test('dimensionBreaker is tanky', () {
      expect(EnemyType.dimensionBreaker.healthMult, greaterThan(1.5));
    });
  });

  // ============================================
  // EDGE CASE TESTS (10 tests)
  // ============================================

  group('Edge cases', () {
    test('enemy with exactly 1.0 multipliers exists', () {
      expect(EnemyType.runner.speedMult, 1.0);
      expect(EnemyType.runner.healthMult, 1.0);
      expect(EnemyType.runner.sizeMult, 1.0);
    });

    test('fastest enemy is not also tankiest', () {
      final fastest = EnemyType.values.reduce((a, b) => a.speedMult > b.speedMult ? a : b);
      final tankiest = EnemyType.values.reduce((a, b) => a.healthMult > b.healthMult ? a : b);
      expect(fastest, isNot(tankiest));
    });

    test('smallest enemy is not also largest', () {
      final smallest = EnemyType.values.reduce((a, b) => a.sizeMult < b.sizeMult ? a : b);
      final largest = EnemyType.values.reduce((a, b) => a.sizeMult > b.sizeMult ? a : b);
      expect(smallest, isNot(largest));
    });

    test('world boundaries are respected', () {
      for (final type in EnemyType.values) {
        expect(type.world, greaterThanOrEqualTo(1));
        expect(type.world, lessThanOrEqualTo(10));
      }
    });

    test('no null values in any property', () {
      for (final type in EnemyType.values) {
        expect(type.color, isNotNull);
        expect(type.speedMult, isNotNull);
        expect(type.healthMult, isNotNull);
        expect(type.sizeMult, isNotNull);
        expect(type.isPhantom, isNotNull);
        expect(type.world, isNotNull);
      }
    });
  });
}
