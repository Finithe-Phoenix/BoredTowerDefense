import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/models/upgrade_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpgradeStats - Default constructor', () {
    test('default towerDamageMult is 1.0', () {
      const stats = UpgradeStats();
      expect(stats.towerDamageMult, 1.0);
    });

    test('default towerRangeMult is 1.0', () {
      const stats = UpgradeStats();
      expect(stats.towerRangeMult, 1.0);
    });

    test('default towerFireRateMult is 1.0', () {
      const stats = UpgradeStats();
      expect(stats.towerFireRateMult, 1.0);
    });

    test('default projectileSpeedMult is 1.0', () {
      const stats = UpgradeStats();
      expect(stats.projectileSpeedMult, 1.0);
    });

    test('default slowMult is 1.0', () {
      const stats = UpgradeStats();
      expect(stats.slowMult, 1.0);
    });

    test('default goldGainMult is 1.0', () {
      const stats = UpgradeStats();
      expect(stats.goldGainMult, 1.0);
    });

    test('default towerCostMult is 1.0', () {
      const stats = UpgradeStats();
      expect(stats.towerCostMult, 1.0);
    });

    test('default pulseCooldownMult is 1.0', () {
      const stats = UpgradeStats();
      expect(stats.pulseCooldownMult, 1.0);
    });

    test('default mineCooldownMult is 1.0', () {
      const stats = UpgradeStats();
      expect(stats.mineCooldownMult, 1.0);
    });

    test('default abilityCostMult is 1.0', () {
      const stats = UpgradeStats();
      expect(stats.abilityCostMult, 1.0);
    });

    test('default startingGoldBonus is 0', () {
      const stats = UpgradeStats();
      expect(stats.startingGoldBonus, 0);
    });

    test('default startingLivesBonus is 0', () {
      const stats = UpgradeStats();
      expect(stats.startingLivesBonus, 0);
    });

    test('default maxMinesBonus is 0', () {
      const stats = UpgradeStats();
      expect(stats.maxMinesBonus, 0);
    });
  });

  group('UpgradeStats - Custom values', () {
    test('custom towerDamageMult', () {
      const stats = UpgradeStats(towerDamageMult: 1.5);
      expect(stats.towerDamageMult, 1.5);
    });

    test('custom towerRangeMult', () {
      const stats = UpgradeStats(towerRangeMult: 1.25);
      expect(stats.towerRangeMult, 1.25);
    });

    test('custom towerFireRateMult', () {
      const stats = UpgradeStats(towerFireRateMult: 0.8);
      expect(stats.towerFireRateMult, 0.8);
    });

    test('custom projectileSpeedMult', () {
      const stats = UpgradeStats(projectileSpeedMult: 2.0);
      expect(stats.projectileSpeedMult, 2.0);
    });

    test('custom slowMult', () {
      const stats = UpgradeStats(slowMult: 1.3);
      expect(stats.slowMult, 1.3);
    });

    test('custom goldGainMult', () {
      const stats = UpgradeStats(goldGainMult: 1.15);
      expect(stats.goldGainMult, 1.15);
    });

    test('custom towerCostMult', () {
      const stats = UpgradeStats(towerCostMult: 0.9);
      expect(stats.towerCostMult, 0.9);
    });

    test('custom pulseCooldownMult', () {
      const stats = UpgradeStats(pulseCooldownMult: 0.85);
      expect(stats.pulseCooldownMult, 0.85);
    });

    test('custom mineCooldownMult', () {
      const stats = UpgradeStats(mineCooldownMult: 0.75);
      expect(stats.mineCooldownMult, 0.75);
    });

    test('custom abilityCostMult', () {
      const stats = UpgradeStats(abilityCostMult: 0.7);
      expect(stats.abilityCostMult, 0.7);
    });

    test('custom startingGoldBonus', () {
      const stats = UpgradeStats(startingGoldBonus: 50);
      expect(stats.startingGoldBonus, 50);
    });

    test('custom startingLivesBonus', () {
      const stats = UpgradeStats(startingLivesBonus: 3);
      expect(stats.startingLivesBonus, 3);
    });

    test('custom maxMinesBonus', () {
      const stats = UpgradeStats(maxMinesBonus: 2);
      expect(stats.maxMinesBonus, 2);
    });
  });

  group('UpgradeStats - Merge multipliers', () {
    test('merge towerDamageMult', () {
      const a = UpgradeStats(towerDamageMult: 1.1);
      const b = UpgradeStats(towerDamageMult: 1.2);
      final result = a.merge(b);
      expect(result.towerDamageMult, closeTo(1.32, 0.0001));
    });

    test('merge towerRangeMult', () {
      const a = UpgradeStats(towerRangeMult: 1.1);
      const b = UpgradeStats(towerRangeMult: 1.1);
      final result = a.merge(b);
      expect(result.towerRangeMult, closeTo(1.21, 0.0001));
    });

    test('merge towerFireRateMult', () {
      const a = UpgradeStats(towerFireRateMult: 1.2);
      const b = UpgradeStats(towerFireRateMult: 1.3);
      final result = a.merge(b);
      expect(result.towerFireRateMult, closeTo(1.56, 0.0001));
    });

    test('merge projectileSpeedMult', () {
      const a = UpgradeStats(projectileSpeedMult: 1.5);
      const b = UpgradeStats(projectileSpeedMult: 2.0);
      final result = a.merge(b);
      expect(result.projectileSpeedMult, closeTo(3.0, 0.0001));
    });

    test('merge slowMult', () {
      const a = UpgradeStats(slowMult: 1.1);
      const b = UpgradeStats(slowMult: 1.2);
      final result = a.merge(b);
      expect(result.slowMult, closeTo(1.32, 0.0001));
    });

    test('merge goldGainMult', () {
      const a = UpgradeStats(goldGainMult: 1.15);
      const b = UpgradeStats(goldGainMult: 1.1);
      final result = a.merge(b);
      expect(result.goldGainMult, closeTo(1.265, 0.0001));
    });

    test('merge towerCostMult', () {
      const a = UpgradeStats(towerCostMult: 0.9);
      const b = UpgradeStats(towerCostMult: 0.95);
      final result = a.merge(b);
      expect(result.towerCostMult, closeTo(0.855, 0.0001));
    });

    test('merge pulseCooldownMult', () {
      const a = UpgradeStats(pulseCooldownMult: 0.9);
      const b = UpgradeStats(pulseCooldownMult: 0.9);
      final result = a.merge(b);
      expect(result.pulseCooldownMult, closeTo(0.81, 0.0001));
    });

    test('merge mineCooldownMult', () {
      const a = UpgradeStats(mineCooldownMult: 0.85);
      const b = UpgradeStats(mineCooldownMult: 0.9);
      final result = a.merge(b);
      expect(result.mineCooldownMult, closeTo(0.765, 0.0001));
    });

    test('merge abilityCostMult', () {
      const a = UpgradeStats(abilityCostMult: 0.8);
      const b = UpgradeStats(abilityCostMult: 0.9);
      final result = a.merge(b);
      expect(result.abilityCostMult, closeTo(0.72, 0.0001));
    });
  });

  group('UpgradeStats - Merge bonuses (additive)', () {
    test('merge startingGoldBonus', () {
      const a = UpgradeStats(startingGoldBonus: 10);
      const b = UpgradeStats(startingGoldBonus: 20);
      final result = a.merge(b);
      expect(result.startingGoldBonus, 30);
    });

    test('merge startingLivesBonus', () {
      const a = UpgradeStats(startingLivesBonus: 1);
      const b = UpgradeStats(startingLivesBonus: 2);
      final result = a.merge(b);
      expect(result.startingLivesBonus, 3);
    });

    test('merge maxMinesBonus', () {
      const a = UpgradeStats(maxMinesBonus: 1);
      const b = UpgradeStats(maxMinesBonus: 1);
      final result = a.merge(b);
      expect(result.maxMinesBonus, 2);
    });
  });

  group('UpgradeStats - Merge with neutral', () {
    test('merge with neutral returns same multipliers', () {
      const stats = UpgradeStats(
        towerDamageMult: 1.5,
        towerRangeMult: 1.2,
        startingGoldBonus: 10,
      );
      const neutral = UpgradeStats();
      final result = stats.merge(neutral);

      expect(result.towerDamageMult, closeTo(1.5, 0.0001));
      expect(result.towerRangeMult, closeTo(1.2, 0.0001));
      expect(result.startingGoldBonus, 10);
    });

    test('neutral merge with stats returns same', () {
      const stats = UpgradeStats(
        goldGainMult: 1.25,
        maxMinesBonus: 2,
      );
      const neutral = UpgradeStats();
      final result = neutral.merge(stats);

      expect(result.goldGainMult, closeTo(1.25, 0.0001));
      expect(result.maxMinesBonus, 2);
    });
  });

  group('UpgradeStats - Scale level 0 and negative', () {
    test('scale level 0 returns neutral', () {
      const stats = UpgradeStats(
        towerDamageMult: 1.5,
        startingGoldBonus: 10,
      );
      final scaled = stats.scale(0);

      expect(scaled.towerDamageMult, 1.0);
      expect(scaled.startingGoldBonus, 0);
    });

    test('scale level -1 returns neutral', () {
      const stats = UpgradeStats(
        towerDamageMult: 2.0,
        maxMinesBonus: 5,
      );
      final scaled = stats.scale(-1);

      expect(scaled.towerDamageMult, 1.0);
      expect(scaled.maxMinesBonus, 0);
    });

    test('scale level -100 returns neutral', () {
      const stats = UpgradeStats(
        goldGainMult: 1.5,
        startingLivesBonus: 10,
      );
      final scaled = stats.scale(-100);

      expect(scaled.goldGainMult, 1.0);
      expect(scaled.startingLivesBonus, 0);
    });
  });

  group('UpgradeStats - Scale level 1', () {
    test('scale level 1 returns same towerDamageMult', () {
      const stats = UpgradeStats(towerDamageMult: 1.15);
      final scaled = stats.scale(1);
      expect(scaled.towerDamageMult, closeTo(1.15, 0.0001));
    });

    test('scale level 1 returns same towerRangeMult', () {
      const stats = UpgradeStats(towerRangeMult: 1.08);
      final scaled = stats.scale(1);
      expect(scaled.towerRangeMult, closeTo(1.08, 0.0001));
    });

    test('scale level 1 returns same bonuses', () {
      const stats = UpgradeStats(
        startingGoldBonus: 25,
        startingLivesBonus: 1,
        maxMinesBonus: 1,
      );
      final scaled = stats.scale(1);

      expect(scaled.startingGoldBonus, 25);
      expect(scaled.startingLivesBonus, 1);
      expect(scaled.maxMinesBonus, 1);
    });
  });

  group('UpgradeStats - Scale level 2', () {
    test('scale level 2 squares multiplier', () {
      const stats = UpgradeStats(towerDamageMult: 1.1);
      final scaled = stats.scale(2);
      expect(scaled.towerDamageMult, closeTo(1.21, 0.0001));
    });

    test('scale level 2 doubles bonus', () {
      const stats = UpgradeStats(startingGoldBonus: 10);
      final scaled = stats.scale(2);
      expect(scaled.startingGoldBonus, 20);
    });
  });

  group('UpgradeStats - Scale level 3', () {
    test('scale level 3 cubes multiplier', () {
      const stats = UpgradeStats(towerDamageMult: 1.1);
      final scaled = stats.scale(3);
      expect(scaled.towerDamageMult, closeTo(1.331, 0.0001));
    });

    test('scale level 3 triples bonus', () {
      const stats = UpgradeStats(maxMinesBonus: 1);
      final scaled = stats.scale(3);
      expect(scaled.maxMinesBonus, 3);
    });
  });

  group('UpgradeStats - Scale all fields', () {
    test('scale applies power to all multipliers', () {
      const stats = UpgradeStats(
        towerDamageMult: 1.1,
        towerRangeMult: 1.05,
        towerFireRateMult: 1.08,
        projectileSpeedMult: 1.06,
        slowMult: 1.04,
        goldGainMult: 1.12,
        towerCostMult: 0.95,
        pulseCooldownMult: 0.92,
        mineCooldownMult: 0.94,
        abilityCostMult: 0.9,
      );

      final scaled = stats.scale(2);

      expect(scaled.towerDamageMult, closeTo(math.pow(1.1, 2), 0.0001));
      expect(scaled.towerRangeMult, closeTo(math.pow(1.05, 2), 0.0001));
      expect(scaled.towerFireRateMult, closeTo(math.pow(1.08, 2), 0.0001));
      expect(scaled.projectileSpeedMult, closeTo(math.pow(1.06, 2), 0.0001));
      expect(scaled.slowMult, closeTo(math.pow(1.04, 2), 0.0001));
      expect(scaled.goldGainMult, closeTo(math.pow(1.12, 2), 0.0001));
      expect(scaled.towerCostMult, closeTo(math.pow(0.95, 2), 0.0001));
      expect(scaled.pulseCooldownMult, closeTo(math.pow(0.92, 2), 0.0001));
      expect(scaled.mineCooldownMult, closeTo(math.pow(0.94, 2), 0.0001));
      expect(scaled.abilityCostMult, closeTo(math.pow(0.9, 2), 0.0001));
    });

    test('scale multiplies all bonuses', () {
      const stats = UpgradeStats(
        startingGoldBonus: 5,
        startingLivesBonus: 1,
        maxMinesBonus: 1,
      );

      final scaled = stats.scale(4);

      expect(scaled.startingGoldBonus, 20);
      expect(scaled.startingLivesBonus, 4);
      expect(scaled.maxMinesBonus, 4);
    });
  });

  group('UpgradeStats - Scale high levels', () {
    for (int level = 1; level <= 10; level++) {
      test('scale level $level for damage multiplier 1.1', () {
        const stats = UpgradeStats(towerDamageMult: 1.1);
        final scaled = stats.scale(level);
        expect(scaled.towerDamageMult, closeTo(math.pow(1.1, level), 0.0001));
      });
    }

    for (int level = 1; level <= 10; level++) {
      test('scale level $level for bonus 5', () {
        const stats = UpgradeStats(startingGoldBonus: 5);
        final scaled = stats.scale(level);
        expect(scaled.startingGoldBonus, 5 * level);
      });
    }
  });

  group('UpgradeDefinition - Basic properties', () {
    test('stores id', () {
      const def = UpgradeDefinition(
        id: 'test_id',
        name: 'Test',
        description: 'Test description',
        maxLevel: 5,
        baseCost: 100,
        costStep: 50,
        perLevel: UpgradeStats(),
      );
      expect(def.id, 'test_id');
    });

    test('stores name', () {
      const def = UpgradeDefinition(
        id: 'test',
        name: 'Test Name',
        description: 'Test description',
        maxLevel: 5,
        baseCost: 100,
        costStep: 50,
        perLevel: UpgradeStats(),
      );
      expect(def.name, 'Test Name');
    });

    test('stores description', () {
      const def = UpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'A detailed description',
        maxLevel: 5,
        baseCost: 100,
        costStep: 50,
        perLevel: UpgradeStats(),
      );
      expect(def.description, 'A detailed description');
    });

    test('stores maxLevel', () {
      const def = UpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 10,
        baseCost: 100,
        costStep: 50,
        perLevel: UpgradeStats(),
      );
      expect(def.maxLevel, 10);
    });

    test('stores baseCost', () {
      const def = UpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 5,
        baseCost: 200,
        costStep: 50,
        perLevel: UpgradeStats(),
      );
      expect(def.baseCost, 200);
    });

    test('stores costStep', () {
      const def = UpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 5,
        baseCost: 100,
        costStep: 75,
        perLevel: UpgradeStats(),
      );
      expect(def.costStep, 75);
    });

    test('stores perLevel stats', () {
      const stats = UpgradeStats(towerDamageMult: 1.1);
      const def = UpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 5,
        baseCost: 100,
        costStep: 50,
        perLevel: stats,
      );
      expect(def.perLevel.towerDamageMult, 1.1);
    });
  });

  group('UpgradeDefinition - costForLevel', () {
    test('cost for level 0 is baseCost', () {
      const def = UpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 5,
        baseCost: 100,
        costStep: 50,
        perLevel: UpgradeStats(),
      );
      expect(def.costForLevel(0), 100);
    });

    test('cost for level 1', () {
      const def = UpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 5,
        baseCost: 100,
        costStep: 50,
        perLevel: UpgradeStats(),
      );
      expect(def.costForLevel(1), 150);
    });

    test('cost for level 2', () {
      const def = UpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 5,
        baseCost: 100,
        costStep: 50,
        perLevel: UpgradeStats(),
      );
      expect(def.costForLevel(2), 200);
    });

    for (int level = 0; level < 10; level++) {
      test('cost for level $level follows formula', () {
        const def = UpgradeDefinition(
          id: 'test',
          name: 'Test',
          description: 'Test',
          maxLevel: 10,
          baseCost: 100,
          costStep: 25,
          perLevel: UpgradeStats(),
        );
        expect(def.costForLevel(level), 100 + 25 * level);
      });
    }
  });

  group('UpgradeDefinition - statsForLevel', () {
    test('stats for level 0 are neutral', () {
      const def = UpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 5,
        baseCost: 100,
        costStep: 50,
        perLevel: UpgradeStats(towerDamageMult: 1.1),
      );
      final stats = def.statsForLevel(0);
      expect(stats.towerDamageMult, 1.0);
    });

    test('stats for level 1 match perLevel', () {
      const def = UpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 5,
        baseCost: 100,
        costStep: 50,
        perLevel: UpgradeStats(towerDamageMult: 1.1),
      );
      final stats = def.statsForLevel(1);
      expect(stats.towerDamageMult, closeTo(1.1, 0.0001));
    });

    test('stats for level 2 are squared', () {
      const def = UpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 5,
        baseCost: 100,
        costStep: 50,
        perLevel: UpgradeStats(towerDamageMult: 1.1),
      );
      final stats = def.statsForLevel(2);
      expect(stats.towerDamageMult, closeTo(1.21, 0.0001));
    });

    for (int level = 0; level <= 5; level++) {
      test('stats for level $level', () {
        const def = UpgradeDefinition(
          id: 'test',
          name: 'Test',
          description: 'Test',
          maxLevel: 5,
          baseCost: 100,
          costStep: 50,
          perLevel: UpgradeStats(towerDamageMult: 1.1, startingGoldBonus: 5),
        );
        final stats = def.statsForLevel(level);

        if (level <= 0) {
          expect(stats.towerDamageMult, 1.0);
          expect(stats.startingGoldBonus, 0);
        } else {
          expect(stats.towerDamageMult, closeTo(math.pow(1.1, level), 0.0001));
          expect(stats.startingGoldBonus, 5 * level);
        }
      });
    }
  });

  group('RunUpgradeDefinition - Basic properties', () {
    test('stores id', () {
      const def = RunUpgradeDefinition(
        id: 'run_test',
        name: 'Test',
        description: 'Test',
        stats: UpgradeStats(),
      );
      expect(def.id, 'run_test');
    });

    test('stores name', () {
      const def = RunUpgradeDefinition(
        id: 'test',
        name: 'Run Test Name',
        description: 'Test',
        stats: UpgradeStats(),
      );
      expect(def.name, 'Run Test Name');
    });

    test('stores description', () {
      const def = RunUpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Run description',
        stats: UpgradeStats(),
      );
      expect(def.description, 'Run description');
    });

    test('stores stats', () {
      const stats = UpgradeStats(towerDamageMult: 1.2);
      const def = RunUpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        stats: stats,
      );
      expect(def.stats.towerDamageMult, 1.2);
    });
  });

  group('RunUpgradeDefinition - Default values', () {
    test('default maxStacks is 3', () {
      const def = RunUpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        stats: UpgradeStats(),
      );
      expect(def.maxStacks, 3);
    });

    test('default instantGold is 0', () {
      const def = RunUpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        stats: UpgradeStats(),
      );
      expect(def.instantGold, 0);
    });

    test('default instantLives is 0', () {
      const def = RunUpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        stats: UpgradeStats(),
      );
      expect(def.instantLives, 0);
    });
  });

  group('RunUpgradeDefinition - Custom values', () {
    test('custom maxStacks', () {
      const def = RunUpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        stats: UpgradeStats(),
        maxStacks: 5,
      );
      expect(def.maxStacks, 5);
    });

    test('custom instantGold', () {
      const def = RunUpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        stats: UpgradeStats(),
        instantGold: 100,
      );
      expect(def.instantGold, 100);
    });

    test('custom instantLives', () {
      const def = RunUpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        stats: UpgradeStats(),
        instantLives: 2,
      );
      expect(def.instantLives, 2);
    });

    test('all custom optional values', () {
      const def = RunUpgradeDefinition(
        id: 'gold_rush',
        name: 'Gold Rush',
        description: 'Instant gold and lives',
        stats: UpgradeStats(goldGainMult: 1.1),
        maxStacks: 10,
        instantGold: 200,
        instantLives: 5,
      );

      expect(def.id, 'gold_rush');
      expect(def.maxStacks, 10);
      expect(def.instantGold, 200);
      expect(def.instantLives, 5);
      expect(def.stats.goldGainMult, 1.1);
    });
  });

  group('UpgradeStats - Edge cases', () {
    test('merge with zero multiplier', () {
      const a = UpgradeStats(towerDamageMult: 2.0);
      const b = UpgradeStats(towerDamageMult: 0.0);
      final result = a.merge(b);
      expect(result.towerDamageMult, 0.0);
    });

    test('merge with very small multiplier', () {
      const a = UpgradeStats(towerDamageMult: 1.0001);
      const b = UpgradeStats(towerDamageMult: 1.0001);
      final result = a.merge(b);
      expect(result.towerDamageMult, closeTo(1.00020001, 0.0000001));
    });

    test('merge with very large multiplier', () {
      const a = UpgradeStats(towerDamageMult: 10.0);
      const b = UpgradeStats(towerDamageMult: 10.0);
      final result = a.merge(b);
      expect(result.towerDamageMult, closeTo(100.0, 0.0001));
    });

    test('scale high level', () {
      const stats = UpgradeStats(towerDamageMult: 1.1);
      final scaled = stats.scale(20);
      expect(scaled.towerDamageMult, closeTo(math.pow(1.1, 20), 0.1));
    });

    test('scale with reduction multiplier', () {
      const stats = UpgradeStats(towerCostMult: 0.9);
      final scaled = stats.scale(5);
      expect(scaled.towerCostMult, closeTo(math.pow(0.9, 5), 0.0001));
      expect(scaled.towerCostMult, lessThan(1.0));
    });
  });

  group('UpgradeStats - Chain merge', () {
    test('merge three stats', () {
      const a = UpgradeStats(towerDamageMult: 1.1);
      const b = UpgradeStats(towerDamageMult: 1.1);
      const c = UpgradeStats(towerDamageMult: 1.1);
      final result = a.merge(b).merge(c);
      expect(result.towerDamageMult, closeTo(1.331, 0.0001));
    });

    test('merge multiple different stats', () {
      const a = UpgradeStats(towerDamageMult: 1.1);
      const b = UpgradeStats(towerRangeMult: 1.1);
      const c = UpgradeStats(goldGainMult: 1.1);
      final result = a.merge(b).merge(c);

      expect(result.towerDamageMult, closeTo(1.1, 0.0001));
      expect(result.towerRangeMult, closeTo(1.1, 0.0001));
      expect(result.goldGainMult, closeTo(1.1, 0.0001));
    });

    test('merge five stats with bonuses', () {
      const stats = UpgradeStats(startingGoldBonus: 10);
      final result = stats.merge(stats).merge(stats).merge(stats).merge(stats);
      expect(result.startingGoldBonus, 50);
    });
  });

  group('UpgradeDefinition - Complex scenarios', () {
    test('damage boost upgrade simulation', () {
      const def = UpgradeDefinition(
        id: 'damage_boost',
        name: 'Damage Boost',
        description: 'Increases tower damage',
        maxLevel: 5,
        baseCost: 50,
        costStep: 25,
        perLevel: UpgradeStats(towerDamageMult: 1.1),
      );

      // Simulate upgrading from 0 to max
      int totalCost = 0;
      for (int level = 0; level < def.maxLevel; level++) {
        totalCost += def.costForLevel(level);
      }

      expect(totalCost, 50 + 75 + 100 + 125 + 150);

      final maxStats = def.statsForLevel(def.maxLevel);
      expect(maxStats.towerDamageMult, closeTo(math.pow(1.1, 5), 0.0001));
    });

    test('gold gain upgrade simulation', () {
      const def = UpgradeDefinition(
        id: 'gold_gain',
        name: 'Gold Gain',
        description: 'Increases gold earned',
        maxLevel: 10,
        baseCost: 100,
        costStep: 100,
        perLevel: UpgradeStats(goldGainMult: 1.05, startingGoldBonus: 5),
      );

      final stats5 = def.statsForLevel(5);
      expect(stats5.goldGainMult, closeTo(math.pow(1.05, 5), 0.0001));
      expect(stats5.startingGoldBonus, 25);

      final stats10 = def.statsForLevel(10);
      expect(stats10.goldGainMult, closeTo(math.pow(1.05, 10), 0.0001));
      expect(stats10.startingGoldBonus, 50);
    });
  });

  group('RunUpgradeDefinition - Complex scenarios', () {
    test('instant reward upgrade', () {
      const def = RunUpgradeDefinition(
        id: 'emergency_funds',
        name: 'Emergency Funds',
        description: 'Get instant gold',
        stats: UpgradeStats(),
        maxStacks: 1,
        instantGold: 500,
      );

      expect(def.maxStacks, 1);
      expect(def.instantGold, 500);
      expect(def.stats.towerDamageMult, 1.0); // No stat changes
    });

    test('stacking stat upgrade', () {
      const def = RunUpgradeDefinition(
        id: 'power_surge',
        name: 'Power Surge',
        description: 'Stackable damage boost',
        stats: UpgradeStats(towerDamageMult: 1.15),
        maxStacks: 5,
      );

      // Simulate stacking
      const neutral = UpgradeStats();
      var accumulated = neutral;
      for (int i = 0; i < def.maxStacks; i++) {
        accumulated = accumulated.merge(def.stats);
      }

      expect(accumulated.towerDamageMult, closeTo(math.pow(1.15, 5), 0.001));
    });
  });
}
