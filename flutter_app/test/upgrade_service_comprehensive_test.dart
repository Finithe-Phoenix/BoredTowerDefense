import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/services/upgrade_service.dart';
import 'package:bored_games/src/models/upgrade_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    UpgradeService.instance.resetForTesting();
  });

  tearDown(() {
    UpgradeService.instance.resetForTesting();
  });

  group('UpgradeService - Singleton', () {
    test('instance is not null', () {
      expect(UpgradeService.instance, isNotNull);
    });

    test('instance is always the same', () {
      final a = UpgradeService.instance;
      final b = UpgradeService.instance;
      expect(identical(a, b), isTrue);
    });
  });

  group('UpgradeService - Initial state', () {
    test('initial currency is 0', () {
      expect(UpgradeService.instance.currency, 0);
    });

    test('levels map is empty after reset', () {
      expect(UpgradeService.instance.levels, isEmpty);
    });

    test('metaUpgrades is not empty', () {
      expect(UpgradeService.instance.metaUpgrades, isNotEmpty);
    });

    test('runUpgrades is not empty', () {
      expect(UpgradeService.instance.runUpgrades, isNotEmpty);
    });
  });

  group('UpgradeService - Meta upgrades list', () {
    test('has core_amplifier upgrade', () {
      final upgrade = UpgradeService.instance.upgradeById('core_amplifier');
      expect(upgrade, isNotNull);
      expect(upgrade!.name, 'Core Amplifier');
    });

    test('has range_array upgrade', () {
      final upgrade = UpgradeService.instance.upgradeById('range_array');
      expect(upgrade, isNotNull);
      expect(upgrade!.name, 'Range Array');
    });

    test('has overclock_grid upgrade', () {
      final upgrade = UpgradeService.instance.upgradeById('overclock_grid');
      expect(upgrade, isNotNull);
      expect(upgrade!.name, 'Overclock Grid');
    });

    test('has ballistics_sync upgrade', () {
      final upgrade = UpgradeService.instance.upgradeById('ballistics_sync');
      expect(upgrade, isNotNull);
    });

    test('has battery_cells upgrade', () {
      final upgrade = UpgradeService.instance.upgradeById('battery_cells');
      expect(upgrade, isNotNull);
    });

    test('has shield_matrix upgrade', () {
      final upgrade = UpgradeService.instance.upgradeById('shield_matrix');
      expect(upgrade, isNotNull);
    });

    test('has efficiency_loop upgrade', () {
      final upgrade = UpgradeService.instance.upgradeById('efficiency_loop');
      expect(upgrade, isNotNull);
    });

    test('has pulse_reactor upgrade', () {
      final upgrade = UpgradeService.instance.upgradeById('pulse_reactor');
      expect(upgrade, isNotNull);
    });

    test('has mine_forge upgrade', () {
      final upgrade = UpgradeService.instance.upgradeById('mine_forge');
      expect(upgrade, isNotNull);
    });

    test('has salvage_protocol upgrade', () {
      final upgrade = UpgradeService.instance.upgradeById('salvage_protocol');
      expect(upgrade, isNotNull);
    });

    test('has phase_tuning upgrade', () {
      final upgrade = UpgradeService.instance.upgradeById('phase_tuning');
      expect(upgrade, isNotNull);
    });

    test('metaUpgrades count is 11', () {
      expect(UpgradeService.instance.metaUpgrades.length, 11);
    });

    test('upgradeById returns null for unknown id', () {
      final upgrade = UpgradeService.instance.upgradeById('nonexistent');
      expect(upgrade, isNull);
    });
  });

  group('UpgradeService - Meta upgrade properties', () {
    test('core_amplifier has correct properties', () {
      final upgrade = UpgradeService.instance.upgradeById('core_amplifier')!;
      expect(upgrade.maxLevel, 8);
      expect(upgrade.baseCost, 60);
      expect(upgrade.costStep, 25);
      expect(upgrade.perLevel.towerDamageMult, 1.07);
    });

    test('range_array has correct properties', () {
      final upgrade = UpgradeService.instance.upgradeById('range_array')!;
      expect(upgrade.maxLevel, 6);
      expect(upgrade.baseCost, 55);
      expect(upgrade.costStep, 20);
      expect(upgrade.perLevel.towerRangeMult, 1.05);
    });

    test('battery_cells has correct properties', () {
      final upgrade = UpgradeService.instance.upgradeById('battery_cells')!;
      expect(upgrade.maxLevel, 8);
      expect(upgrade.baseCost, 40);
      expect(upgrade.costStep, 18);
      expect(upgrade.perLevel.startingGoldBonus, 15);
    });

    test('shield_matrix has correct properties', () {
      final upgrade = UpgradeService.instance.upgradeById('shield_matrix')!;
      expect(upgrade.maxLevel, 10);
      expect(upgrade.baseCost, 45);
      expect(upgrade.costStep, 20);
      expect(upgrade.perLevel.startingLivesBonus, 1);
    });

    test('efficiency_loop reduces tower cost', () {
      final upgrade = UpgradeService.instance.upgradeById('efficiency_loop')!;
      expect(upgrade.perLevel.towerCostMult, lessThan(1.0));
      expect(upgrade.perLevel.towerCostMult, 0.96);
    });

    test('pulse_reactor reduces cooldown', () {
      final upgrade = UpgradeService.instance.upgradeById('pulse_reactor')!;
      expect(upgrade.perLevel.pulseCooldownMult, lessThan(1.0));
      expect(upgrade.perLevel.pulseCooldownMult, 0.92);
    });

    test('mine_forge has multiple effects', () {
      final upgrade = UpgradeService.instance.upgradeById('mine_forge')!;
      expect(upgrade.perLevel.mineCooldownMult, 0.92);
      expect(upgrade.perLevel.maxMinesBonus, 1);
    });
  });

  group('UpgradeService - Run upgrades list', () {
    test('has run_damage upgrade', () {
      final upgrades = UpgradeService.instance.runUpgrades;
      final upgrade = upgrades.firstWhere((u) => u.id == 'run_damage');
      expect(upgrade.name, 'Damage Surge');
      expect(upgrade.stats.towerDamageMult, 1.12);
      expect(upgrade.maxStacks, 4);
    });

    test('has run_range upgrade', () {
      final upgrades = UpgradeService.instance.runUpgrades;
      final upgrade = upgrades.firstWhere((u) => u.id == 'run_range');
      expect(upgrade.stats.towerRangeMult, 1.1);
      expect(upgrade.maxStacks, 3);
    });

    test('has run_fire upgrade', () {
      final upgrades = UpgradeService.instance.runUpgrades;
      final upgrade = upgrades.firstWhere((u) => u.id == 'run_fire');
      expect(upgrade.stats.towerFireRateMult, 1.12);
    });

    test('has run_gold upgrade', () {
      final upgrades = UpgradeService.instance.runUpgrades;
      final upgrade = upgrades.firstWhere((u) => u.id == 'run_gold');
      expect(upgrade.stats.goldGainMult, 1.15);
    });

    test('has run_pulse upgrade', () {
      final upgrades = UpgradeService.instance.runUpgrades;
      final upgrade = upgrades.firstWhere((u) => u.id == 'run_pulse');
      expect(upgrade.stats.pulseCooldownMult, 0.8);
    });

    test('has run_mine upgrade', () {
      final upgrades = UpgradeService.instance.runUpgrades;
      final upgrade = upgrades.firstWhere((u) => u.id == 'run_mine');
      expect(upgrade.stats.mineCooldownMult, 0.8);
    });

    test('has run_lives upgrade with instant effect', () {
      final upgrades = UpgradeService.instance.runUpgrades;
      final upgrade = upgrades.firstWhere((u) => u.id == 'run_lives');
      expect(upgrade.instantLives, 2);
      expect(upgrade.maxStacks, 2);
    });

    test('has run_cash upgrade with instant effect', () {
      final upgrades = UpgradeService.instance.runUpgrades;
      final upgrade = upgrades.firstWhere((u) => u.id == 'run_cash');
      expect(upgrade.instantGold, 80);
      expect(upgrade.maxStacks, 3);
    });

    test('has run_cost upgrade', () {
      final upgrades = UpgradeService.instance.runUpgrades;
      final upgrade = upgrades.firstWhere((u) => u.id == 'run_cost');
      expect(upgrade.stats.towerCostMult, 0.9);
    });

    test('has run_slow upgrade', () {
      final upgrades = UpgradeService.instance.runUpgrades;
      final upgrade = upgrades.firstWhere((u) => u.id == 'run_slow');
      expect(upgrade.stats.slowMult, 1.15);
    });

    test('runUpgrades count is 10', () {
      expect(UpgradeService.instance.runUpgrades.length, 10);
    });
  });

  group('UpgradeService - levelFor', () {
    test('levelFor returns 0 for unpurchased upgrade', () {
      expect(UpgradeService.instance.levelFor('core_amplifier'), 0);
    });

    test('levelFor returns 0 for unknown upgrade', () {
      expect(UpgradeService.instance.levelFor('nonexistent'), 0);
    });
  });

  group('UpgradeService - metaStats', () {
    test('metaStats returns neutral stats when no upgrades', () {
      final stats = UpgradeService.instance.metaStats;
      expect(stats.towerDamageMult, 1.0);
      expect(stats.towerRangeMult, 1.0);
      expect(stats.startingGoldBonus, 0);
    });
  });

  group('UpgradeService - rollRunUpgrades', () {
    test('rollRunUpgrades returns requested count', () {
      final upgrades = UpgradeService.instance.rollRunUpgrades(
        currentStacks: {},
        count: 3,
      );
      expect(upgrades.length, 3);
    });

    test('rollRunUpgrades returns unique upgrades', () {
      final upgrades = UpgradeService.instance.rollRunUpgrades(
        currentStacks: {},
        count: 3,
      );
      final ids = upgrades.map((u) => u.id).toSet();
      expect(ids.length, 3);
    });

    test('rollRunUpgrades respects maxStacks', () {
      // Max out an upgrade
      final maxedStacks = {
        'run_damage': 4, // maxStacks is 4
      };

      final upgrades = UpgradeService.instance.rollRunUpgrades(
        currentStacks: maxedStacks,
        count: 10, // Request more than available
      );

      // Should not include run_damage since it's maxed
      expect(upgrades.any((u) => u.id == 'run_damage'), isFalse);
    });

    test('rollRunUpgrades returns empty if all maxed', () {
      final maxedStacks = <String, int>{};
      for (final upgrade in UpgradeService.instance.runUpgrades) {
        maxedStacks[upgrade.id] = upgrade.maxStacks;
      }

      final upgrades = UpgradeService.instance.rollRunUpgrades(
        currentStacks: maxedStacks,
      );

      expect(upgrades, isEmpty);
    });

    test('rollRunUpgrades with count 1', () {
      final upgrades = UpgradeService.instance.rollRunUpgrades(
        currentStacks: {},
        count: 1,
      );
      expect(upgrades.length, 1);
    });

    test('rollRunUpgrades with count 5', () {
      final upgrades = UpgradeService.instance.rollRunUpgrades(
        currentStacks: {},
        count: 5,
      );
      expect(upgrades.length, 5);
    });

    test('rollRunUpgrades excludes partially stacked upgrades correctly', () {
      // Set some upgrades to partial stacks
      final stacks = {
        'run_lives': 1, // maxStacks is 2, so still available
        'run_cost': 2, // maxStacks is 2, so NOT available
      };

      // Run multiple times to check consistency
      for (int i = 0; i < 10; i++) {
        final upgrades = UpgradeService.instance.rollRunUpgrades(
          currentStacks: stacks,
          count: 10,
        );

        expect(upgrades.any((u) => u.id == 'run_cost'), isFalse);
        // run_lives might or might not appear depending on random selection
      }
    });
  });

  group('UpgradeService - Upgrade definitions validation', () {
    test('all meta upgrades have unique ids', () {
      final ids = UpgradeService.instance.metaUpgrades.map((u) => u.id).toSet();
      expect(ids.length, UpgradeService.instance.metaUpgrades.length);
    });

    test('all run upgrades have unique ids', () {
      final ids = UpgradeService.instance.runUpgrades.map((u) => u.id).toSet();
      expect(ids.length, UpgradeService.instance.runUpgrades.length);
    });

    test('all meta upgrades have positive maxLevel', () {
      for (final upgrade in UpgradeService.instance.metaUpgrades) {
        expect(upgrade.maxLevel, greaterThan(0),
            reason: '${upgrade.id} should have positive maxLevel');
      }
    });

    test('all meta upgrades have non-negative baseCost', () {
      for (final upgrade in UpgradeService.instance.metaUpgrades) {
        expect(upgrade.baseCost, greaterThanOrEqualTo(0),
            reason: '${upgrade.id} should have non-negative baseCost');
      }
    });

    test('all meta upgrades have non-negative costStep', () {
      for (final upgrade in UpgradeService.instance.metaUpgrades) {
        expect(upgrade.costStep, greaterThanOrEqualTo(0),
            reason: '${upgrade.id} should have non-negative costStep');
      }
    });

    test('all run upgrades have positive maxStacks', () {
      for (final upgrade in UpgradeService.instance.runUpgrades) {
        expect(upgrade.maxStacks, greaterThan(0),
            reason: '${upgrade.id} should have positive maxStacks');
      }
    });

    test('all meta upgrades have non-empty name', () {
      for (final upgrade in UpgradeService.instance.metaUpgrades) {
        expect(upgrade.name, isNotEmpty,
            reason: '${upgrade.id} should have non-empty name');
      }
    });

    test('all meta upgrades have non-empty description', () {
      for (final upgrade in UpgradeService.instance.metaUpgrades) {
        expect(upgrade.description, isNotEmpty,
            reason: '${upgrade.id} should have non-empty description');
      }
    });

    test('all run upgrades have non-empty name', () {
      for (final upgrade in UpgradeService.instance.runUpgrades) {
        expect(upgrade.name, isNotEmpty,
            reason: '${upgrade.id} should have non-empty name');
      }
    });

    test('all run upgrades have non-empty description', () {
      for (final upgrade in UpgradeService.instance.runUpgrades) {
        expect(upgrade.description, isNotEmpty,
            reason: '${upgrade.id} should have non-empty description');
      }
    });
  });

  group('UpgradeService - Cost calculations', () {
    test('core_amplifier cost for level 0', () {
      final upgrade = UpgradeService.instance.upgradeById('core_amplifier')!;
      expect(upgrade.costForLevel(0), 60);
    });

    test('core_amplifier cost for level 1', () {
      final upgrade = UpgradeService.instance.upgradeById('core_amplifier')!;
      expect(upgrade.costForLevel(1), 85);
    });

    test('core_amplifier cost for level 7', () {
      final upgrade = UpgradeService.instance.upgradeById('core_amplifier')!;
      expect(upgrade.costForLevel(7), 60 + 7 * 25);
    });

    test('battery_cells cost progression', () {
      final upgrade = UpgradeService.instance.upgradeById('battery_cells')!;
      for (int level = 0; level < upgrade.maxLevel; level++) {
        expect(upgrade.costForLevel(level), 40 + level * 18);
      }
    });
  });

  group('UpgradeService - Stats calculations', () {
    test('core_amplifier stats for level 1', () {
      final upgrade = UpgradeService.instance.upgradeById('core_amplifier')!;
      final stats = upgrade.statsForLevel(1);
      expect(stats.towerDamageMult, closeTo(1.07, 0.0001));
    });

    test('core_amplifier stats for level 5', () {
      final upgrade = UpgradeService.instance.upgradeById('core_amplifier')!;
      final stats = upgrade.statsForLevel(5);
      expect(stats.towerDamageMult, closeTo(1.4025517, 0.0001));
    });

    test('battery_cells stats for level 3', () {
      final upgrade = UpgradeService.instance.upgradeById('battery_cells')!;
      final stats = upgrade.statsForLevel(3);
      expect(stats.startingGoldBonus, 45);
    });

    test('shield_matrix stats for level 5', () {
      final upgrade = UpgradeService.instance.upgradeById('shield_matrix')!;
      final stats = upgrade.statsForLevel(5);
      expect(stats.startingLivesBonus, 5);
    });
  });

  group('UpgradeService - resetForTesting', () {
    test('resetForTesting resets currency', () {
      UpgradeService.instance.resetForTesting();
      expect(UpgradeService.instance.currency, 0);
    });

    test('resetForTesting clears levels', () {
      UpgradeService.instance.resetForTesting();
      expect(UpgradeService.instance.levels, isEmpty);
    });

    test('resetForTesting can be called multiple times', () {
      UpgradeService.instance.resetForTesting();
      UpgradeService.instance.resetForTesting();
      expect(UpgradeService.instance.currency, 0);
    });
  });
}
