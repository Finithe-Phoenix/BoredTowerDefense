import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/models/upgrade_data.dart';

void main() {
  group('UpgradeStats', () {
    test('default constructor has neutral multipliers', () {
      const stats = UpgradeStats();
      expect(stats.towerDamageMult, 1.0);
      expect(stats.towerRangeMult, 1.0);
      expect(stats.towerFireRateMult, 1.0);
      expect(stats.projectileSpeedMult, 1.0);
      expect(stats.slowMult, 1.0);
      expect(stats.goldGainMult, 1.0);
      expect(stats.towerCostMult, 1.0);
      expect(stats.pulseCooldownMult, 1.0);
      expect(stats.mineCooldownMult, 1.0);
      expect(stats.abilityCostMult, 1.0);
      expect(stats.startingGoldBonus, 0);
      expect(stats.startingLivesBonus, 0);
      expect(stats.maxMinesBonus, 0);
    });

    test('merge multiplies multipliers and adds bonuses', () {
      const base = UpgradeStats(
        towerDamageMult: 1.1,
        towerRangeMult: 1.2,
        startingGoldBonus: 10,
        maxMinesBonus: 1,
      );
      const add = UpgradeStats(
        towerDamageMult: 1.05,
        towerFireRateMult: 1.2,
        startingGoldBonus: 5,
        maxMinesBonus: 2,
      );

      final merged = base.merge(add);
      expect(merged.towerDamageMult, closeTo(1.155, 0.0001));
      expect(merged.towerRangeMult, closeTo(1.2, 0.0001));
      expect(merged.towerFireRateMult, closeTo(1.2, 0.0001));
      expect(merged.startingGoldBonus, 15);
      expect(merged.maxMinesBonus, 3);
    });

    test('merge combines all multipliers', () {
      const base = UpgradeStats(
        projectileSpeedMult: 1.1,
        slowMult: 1.2,
        goldGainMult: 1.15,
        towerCostMult: 0.9,
        pulseCooldownMult: 0.85,
        mineCooldownMult: 0.95,
        abilityCostMult: 0.8,
        startingLivesBonus: 2,
      );
      const add = UpgradeStats(
        projectileSpeedMult: 1.05,
        slowMult: 1.1,
        goldGainMult: 1.1,
        towerCostMult: 0.95,
        pulseCooldownMult: 0.9,
        mineCooldownMult: 0.9,
        abilityCostMult: 0.9,
        startingLivesBonus: 1,
      );

      final merged = base.merge(add);
      expect(merged.projectileSpeedMult, closeTo(1.155, 0.0001));
      expect(merged.slowMult, closeTo(1.32, 0.0001));
      expect(merged.goldGainMult, closeTo(1.265, 0.0001));
      expect(merged.towerCostMult, closeTo(0.855, 0.0001));
      expect(merged.pulseCooldownMult, closeTo(0.765, 0.0001));
      expect(merged.mineCooldownMult, closeTo(0.855, 0.0001));
      expect(merged.abilityCostMult, closeTo(0.72, 0.0001));
      expect(merged.startingLivesBonus, 3);
    });

    test('scale applies multipliers per level', () {
      const stats = UpgradeStats(
        towerDamageMult: 1.1,
        pulseCooldownMult: 0.9,
        startingGoldBonus: 5,
        maxMinesBonus: 1,
      );

      final scaled = stats.scale(3);
      expect(scaled.towerDamageMult, closeTo(1.331, 0.0001));
      expect(scaled.pulseCooldownMult, closeTo(0.729, 0.0001));
      expect(scaled.startingGoldBonus, 15);
      expect(scaled.maxMinesBonus, 3);
    });

    test('scale returns neutral stats for level 0 or negative', () {
      const stats = UpgradeStats(
        towerDamageMult: 1.5,
        startingGoldBonus: 10,
      );

      final zeroScaled = stats.scale(0);
      expect(zeroScaled.towerDamageMult, 1.0);
      expect(zeroScaled.startingGoldBonus, 0);

      final negativeScaled = stats.scale(-1);
      expect(negativeScaled.towerDamageMult, 1.0);
      expect(negativeScaled.startingGoldBonus, 0);
    });

    test('scale with level 1 returns same multipliers', () {
      const stats = UpgradeStats(
        towerDamageMult: 1.2,
        towerRangeMult: 1.15,
        startingGoldBonus: 10,
      );

      final scaled = stats.scale(1);
      expect(scaled.towerDamageMult, closeTo(1.2, 0.0001));
      expect(scaled.towerRangeMult, closeTo(1.15, 0.0001));
      expect(scaled.startingGoldBonus, 10);
    });

    test('scale scales all fields correctly', () {
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
        startingGoldBonus: 5,
        startingLivesBonus: 1,
        maxMinesBonus: 1,
      );

      final scaled = stats.scale(2);
      expect(scaled.towerDamageMult, closeTo(1.21, 0.0001));
      expect(scaled.towerRangeMult, closeTo(1.1025, 0.0001));
      expect(scaled.towerFireRateMult, closeTo(1.1664, 0.0001));
      expect(scaled.projectileSpeedMult, closeTo(1.1236, 0.0001));
      expect(scaled.slowMult, closeTo(1.0816, 0.0001));
      expect(scaled.goldGainMult, closeTo(1.2544, 0.0001));
      expect(scaled.towerCostMult, closeTo(0.9025, 0.0001));
      expect(scaled.pulseCooldownMult, closeTo(0.8464, 0.0001));
      expect(scaled.mineCooldownMult, closeTo(0.8836, 0.0001));
      expect(scaled.abilityCostMult, closeTo(0.81, 0.0001));
      expect(scaled.startingGoldBonus, 10);
      expect(scaled.startingLivesBonus, 2);
      expect(scaled.maxMinesBonus, 2);
    });
  });

  group('UpgradeDefinition', () {
    test('costForLevel calculates correctly', () {
      const definition = UpgradeDefinition(
        id: 'test',
        name: 'Test Upgrade',
        description: 'A test upgrade',
        maxLevel: 5,
        baseCost: 100,
        costStep: 50,
        perLevel: UpgradeStats(towerDamageMult: 1.1),
      );

      expect(definition.costForLevel(0), 100);
      expect(definition.costForLevel(1), 150);
      expect(definition.costForLevel(2), 200);
      expect(definition.costForLevel(3), 250);
    });

    test('statsForLevel returns scaled stats', () {
      const definition = UpgradeDefinition(
        id: 'damage',
        name: 'Damage Boost',
        description: 'Increases tower damage',
        maxLevel: 3,
        baseCost: 50,
        costStep: 25,
        perLevel: UpgradeStats(towerDamageMult: 1.1),
      );

      final stats0 = definition.statsForLevel(0);
      expect(stats0.towerDamageMult, 1.0);

      final stats1 = definition.statsForLevel(1);
      expect(stats1.towerDamageMult, closeTo(1.1, 0.0001));

      final stats2 = definition.statsForLevel(2);
      expect(stats2.towerDamageMult, closeTo(1.21, 0.0001));

      final stats3 = definition.statsForLevel(3);
      expect(stats3.towerDamageMult, closeTo(1.331, 0.0001));
    });

    test('stores all properties', () {
      const definition = UpgradeDefinition(
        id: 'my_upgrade',
        name: 'My Upgrade',
        description: 'My description',
        maxLevel: 10,
        baseCost: 200,
        costStep: 75,
        perLevel: UpgradeStats(goldGainMult: 1.05),
      );

      expect(definition.id, 'my_upgrade');
      expect(definition.name, 'My Upgrade');
      expect(definition.description, 'My description');
      expect(definition.maxLevel, 10);
      expect(definition.baseCost, 200);
      expect(definition.costStep, 75);
      expect(definition.perLevel.goldGainMult, 1.05);
    });
  });

  group('RunUpgradeDefinition', () {
    test('stores basic properties', () {
      const runUpgrade = RunUpgradeDefinition(
        id: 'run_upgrade',
        name: 'Run Upgrade',
        description: 'A run upgrade',
        stats: UpgradeStats(towerDamageMult: 1.2),
      );

      expect(runUpgrade.id, 'run_upgrade');
      expect(runUpgrade.name, 'Run Upgrade');
      expect(runUpgrade.description, 'A run upgrade');
      expect(runUpgrade.stats.towerDamageMult, 1.2);
      expect(runUpgrade.maxStacks, 3); // Default
      expect(runUpgrade.instantGold, 0);
      expect(runUpgrade.instantLives, 0);
    });

    test('stores optional properties', () {
      const runUpgrade = RunUpgradeDefinition(
        id: 'gold_rush',
        name: 'Gold Rush',
        description: 'Instant gold',
        stats: UpgradeStats(),
        maxStacks: 5,
        instantGold: 100,
        instantLives: 2,
      );

      expect(runUpgrade.maxStacks, 5);
      expect(runUpgrade.instantGold, 100);
      expect(runUpgrade.instantLives, 2);
    });

    test('supports complex stats', () {
      const runUpgrade = RunUpgradeDefinition(
        id: 'complex',
        name: 'Complex Upgrade',
        description: 'Has many stats',
        stats: UpgradeStats(
          towerDamageMult: 1.1,
          towerRangeMult: 1.05,
          goldGainMult: 1.2,
          pulseCooldownMult: 0.9,
        ),
        maxStacks: 2,
      );

      expect(runUpgrade.stats.towerDamageMult, 1.1);
      expect(runUpgrade.stats.towerRangeMult, 1.05);
      expect(runUpgrade.stats.goldGainMult, 1.2);
      expect(runUpgrade.stats.pulseCooldownMult, 0.9);
    });
  });
}
