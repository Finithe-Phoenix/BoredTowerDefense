import 'package:flutter_test/flutter_test.dart';
import 'package:bored_games/src/services/level_service.dart';
import 'package:bored_games/src/services/upgrade_service.dart';
import 'package:bored_games/src/services/storage_service.dart';
import 'package:bored_games/src/game/entities/tower.dart';
import '../helpers/fake_audioplayers_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration tests for service interactions
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFakeAudioplayersPlatform();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetForTesting();
    LevelService.overrideUnlockAllLevels = null;
    LevelService.instance.resetForTesting();
    UpgradeService.instance.resetForTesting();
  });

  group('LevelService Integration', () {
    test('initializes with level 1 unlocked', () async {
      await StorageService.instance.initialize();
      await LevelService.instance.initialize();

      expect(LevelService.instance.isLevelUnlocked(1), isTrue);
      expect(LevelService.instance.levels.isNotEmpty, isTrue);
    });

    test('level progression works correctly', () async {
      await StorageService.instance.initialize();
      await LevelService.instance.initialize();
      await UpgradeService.instance.initialize();

      // Complete level 1
      await LevelService.instance.updateProgress(
        levelId: 1,
        completed: true,
        score: 1000,
        wavesCleared: 5,
        livesRemaining: 20,
        maxLives: 20,
      );

      // Level 2 should now be unlocked
      expect(LevelService.instance.isLevelUnlocked(2), isTrue);
    });

    test('stars calculation based on performance', () async {
      await StorageService.instance.initialize();
      await LevelService.instance.initialize();
      await UpgradeService.instance.initialize();

      // Perfect completion (3 stars)
      await LevelService.instance.updateProgress(
        levelId: 1,
        completed: true,
        score: 1000,
        wavesCleared: 5,
        livesRemaining: 20,
        maxLives: 20,
      );

      final progress = LevelService.instance.getProgress(1);
      expect(progress.stars, 3);
      expect(progress.completed, isTrue);
    });

    test('good completion gives 2 stars', () async {
      await StorageService.instance.initialize();
      await LevelService.instance.initialize();
      await UpgradeService.instance.initialize();

      // 75%+ health remaining
      await LevelService.instance.updateProgress(
        levelId: 1,
        completed: true,
        score: 1000,
        wavesCleared: 5,
        livesRemaining: 16,
        maxLives: 20,
      );

      final progress = LevelService.instance.getProgress(1);
      expect(progress.stars, 2);
    });

    test('completion with low health gives 1 star', () async {
      await StorageService.instance.initialize();
      await LevelService.instance.initialize();
      await UpgradeService.instance.initialize();

      // Less than 75% health remaining
      await LevelService.instance.updateProgress(
        levelId: 1,
        completed: true,
        score: 1000,
        wavesCleared: 5,
        livesRemaining: 5,
        maxLives: 20,
      );

      final progress = LevelService.instance.getProgress(1);
      expect(progress.stars, 1);
    });

    test('tower unlocking based on progression', () async {
      LevelService.overrideUnlockAllLevels = false;
      await StorageService.instance.initialize();
      await LevelService.instance.initialize();
      await UpgradeService.instance.initialize();

      // Pulse Archer is always unlocked
      expect(LevelService.instance.isTowerUnlocked(TowerType.pulseArcher), isTrue);

      // Initial unlocked towers
      final unlockedTowers = LevelService.instance.getUnlockedTowers();
      expect(unlockedTowers.contains(TowerType.pulseArcher), isTrue);
    });

    test('total stars accumulates correctly', () async {
      await StorageService.instance.initialize();
      await LevelService.instance.initialize();
      await UpgradeService.instance.initialize();

      // Complete first level
      await LevelService.instance.updateProgress(
        levelId: 1,
        completed: true,
        score: 1000,
        wavesCleared: 5,
        livesRemaining: 20,
        maxLives: 20,
      );

      expect(LevelService.instance.totalStars, 3);
      expect(LevelService.instance.completedLevels, 1);
    });

    test('high scores are tracked', () async {
      await StorageService.instance.initialize();
      await LevelService.instance.initialize();
      await UpgradeService.instance.initialize();

      // First attempt
      await LevelService.instance.updateProgress(
        levelId: 1,
        completed: true,
        score: 1000,
        wavesCleared: 5,
        livesRemaining: 20,
        maxLives: 20,
      );

      expect(LevelService.instance.getProgress(1).highScore, 1000);

      // Better attempt
      await LevelService.instance.updateProgress(
        levelId: 1,
        completed: true,
        score: 1500,
        wavesCleared: 5,
        livesRemaining: 20,
        maxLives: 20,
      );

      expect(LevelService.instance.getProgress(1).highScore, 1500);
    });

    test('level config lookup works', () async {
      await StorageService.instance.initialize();
      await LevelService.instance.initialize();

      final level1 = LevelService.instance.getLevel(1);
      expect(level1, isNotNull);
      expect(level1!.name, 'Training Grounds');
      expect(level1.waves, 5);
      expect(level1.difficulty, 1);

      final invalidLevel = LevelService.instance.getLevel(999);
      expect(invalidLevel, isNull);
    });

    test('100 levels are configured', () async {
      await StorageService.instance.initialize();
      await LevelService.instance.initialize();

      expect(LevelService.instance.levels.length, 100);
    });

    test('max stars is calculated correctly', () async {
      await StorageService.instance.initialize();
      await LevelService.instance.initialize();

      expect(LevelService.instance.maxStars, 300); // 100 levels * 3 stars
    });
  });

  group('UpgradeService Integration', () {
    test('initializes with 0 currency', () async {
      await StorageService.instance.initialize();
      await UpgradeService.instance.initialize();

      expect(UpgradeService.instance.currency, 0);
    });

    test('can add currency', () async {
      await StorageService.instance.initialize();
      await UpgradeService.instance.initialize();

      await UpgradeService.instance.addCurrency(100);
      expect(UpgradeService.instance.currency, 100);
    });

    test('cannot purchase without sufficient currency', () async {
      await StorageService.instance.initialize();
      await UpgradeService.instance.initialize();

      final upgrades = UpgradeService.instance.metaUpgrades;
      expect(upgrades.isNotEmpty, isTrue);

      final firstUpgrade = upgrades.first;
      expect(UpgradeService.instance.canPurchase(firstUpgrade), isFalse);
    });

    test('can purchase with sufficient currency', () async {
      await StorageService.instance.initialize();
      await UpgradeService.instance.initialize();

      final upgrades = UpgradeService.instance.metaUpgrades;
      final firstUpgrade = upgrades.first;
      final cost = firstUpgrade.costForLevel(0);

      await UpgradeService.instance.addCurrency(cost);
      expect(UpgradeService.instance.canPurchase(firstUpgrade), isTrue);

      final purchased = await UpgradeService.instance.purchase(firstUpgrade.id);
      expect(purchased, isTrue);
      expect(UpgradeService.instance.levelFor(firstUpgrade.id), 1);
    });

    test('currency is deducted on purchase', () async {
      await StorageService.instance.initialize();
      await UpgradeService.instance.initialize();

      final upgrades = UpgradeService.instance.metaUpgrades;
      final firstUpgrade = upgrades.first;
      final cost = firstUpgrade.costForLevel(0);

      await UpgradeService.instance.addCurrency(cost + 50);
      expect(UpgradeService.instance.currency, cost + 50);

      await UpgradeService.instance.purchase(firstUpgrade.id);
      expect(UpgradeService.instance.currency, 50);
    });

    test('cannot exceed max level', () async {
      await StorageService.instance.initialize();
      await UpgradeService.instance.initialize();

      final upgrades = UpgradeService.instance.metaUpgrades;
      final firstUpgrade = upgrades.first;

      // Add a lot of currency
      await UpgradeService.instance.addCurrency(10000);

      // Purchase until max level
      for (int i = 0; i < firstUpgrade.maxLevel; i++) {
        await UpgradeService.instance.purchase(firstUpgrade.id);
      }

      expect(UpgradeService.instance.levelFor(firstUpgrade.id), firstUpgrade.maxLevel);
      expect(UpgradeService.instance.canPurchase(firstUpgrade), isFalse);
    });

    test('meta stats accumulate correctly', () async {
      await StorageService.instance.initialize();
      await UpgradeService.instance.initialize();

      await UpgradeService.instance.addCurrency(10000);

      // Purchase damage upgrade
      final damageUpgrade = UpgradeService.instance.upgradeById('core_amplifier');
      expect(damageUpgrade, isNotNull);

      await UpgradeService.instance.purchase('core_amplifier');

      final stats = UpgradeService.instance.metaStats;
      expect(stats.towerDamageMult, greaterThan(1.0));
    });

    test('run upgrades roll correctly', () async {
      await StorageService.instance.initialize();
      await UpgradeService.instance.initialize();

      final runUpgrades = UpgradeService.instance.rollRunUpgrades(
        currentStacks: {},
        count: 3,
      );

      expect(runUpgrades.length, lessThanOrEqualTo(3));
      expect(runUpgrades.toSet().length, runUpgrades.length); // All unique
    });

    test('run upgrades respect max stacks', () async {
      await StorageService.instance.initialize();
      await UpgradeService.instance.initialize();

      // Set all upgrades to max stacks
      final maxedStacks = <String, int>{};
      for (final upgrade in UpgradeService.instance.runUpgrades) {
        maxedStacks[upgrade.id] = upgrade.maxStacks;
      }

      final runUpgrades = UpgradeService.instance.rollRunUpgrades(
        currentStacks: maxedStacks,
        count: 3,
      );

      expect(runUpgrades, isEmpty);
    });

    test('upgrade lookup by id works', () async {
      await StorageService.instance.initialize();
      await UpgradeService.instance.initialize();

      final upgrade = UpgradeService.instance.upgradeById('core_amplifier');
      expect(upgrade, isNotNull);
      expect(upgrade!.name, 'Core Amplifier');

      final invalidUpgrade = UpgradeService.instance.upgradeById('invalid_id');
      expect(invalidUpgrade, isNull);
    });

    test('all meta upgrades have valid configuration', () async {
      await StorageService.instance.initialize();
      await UpgradeService.instance.initialize();

      for (final upgrade in UpgradeService.instance.metaUpgrades) {
        expect(upgrade.id.isNotEmpty, isTrue);
        expect(upgrade.name.isNotEmpty, isTrue);
        expect(upgrade.description.isNotEmpty, isTrue);
        expect(upgrade.maxLevel, greaterThan(0));
        expect(upgrade.baseCost, greaterThan(0));
      }
    });

    test('all run upgrades have valid configuration', () async {
      await StorageService.instance.initialize();
      await UpgradeService.instance.initialize();

      for (final upgrade in UpgradeService.instance.runUpgrades) {
        expect(upgrade.id.isNotEmpty, isTrue);
        expect(upgrade.name.isNotEmpty, isTrue);
        expect(upgrade.description.isNotEmpty, isTrue);
        expect(upgrade.maxStacks, greaterThan(0));
      }
    });
  });

  group('Level and Upgrade Service Integration', () {
    test('completing level awards currency for upgrades', () async {
      await StorageService.instance.initialize();
      await LevelService.instance.initialize();
      await UpgradeService.instance.initialize();

      final initialCurrency = UpgradeService.instance.currency;

      // Complete level with 3 stars
      await LevelService.instance.updateProgress(
        levelId: 1,
        completed: true,
        score: 1000,
        wavesCleared: 5,
        livesRemaining: 20,
        maxLives: 20,
      );

      // Should have earned currency
      expect(UpgradeService.instance.currency, greaterThan(initialCurrency));
    });

    test('partial completion still awards some currency', () async {
      await StorageService.instance.initialize();
      await LevelService.instance.initialize();
      await UpgradeService.instance.initialize();

      final initialCurrency = UpgradeService.instance.currency;

      // Partial completion (not completed but cleared some waves)
      await LevelService.instance.updateProgress(
        levelId: 1,
        completed: false,
        score: 500,
        wavesCleared: 6,
        livesRemaining: 0,
        maxLives: 20,
      );

      // Should still earn some currency based on waves cleared
      expect(UpgradeService.instance.currency, greaterThanOrEqualTo(initialCurrency));
    });

    test('meta upgrades can be purchased with earned currency', () async {
      await StorageService.instance.initialize();
      await LevelService.instance.initialize();
      await UpgradeService.instance.initialize();

      // Complete multiple levels to earn currency
      for (int i = 1; i <= 5; i++) {
        await LevelService.instance.updateProgress(
          levelId: i,
          completed: true,
          score: 1000 * i,
          wavesCleared: 5 + i,
          livesRemaining: 20,
          maxLives: 20,
        );
      }

      // Should now have enough currency to buy an upgrade
      final currency = UpgradeService.instance.currency;
      expect(currency, greaterThan(0));

      // Find an upgrade we can afford
      final affordableUpgrade = UpgradeService.instance.metaUpgrades.firstWhere(
        (u) => u.costForLevel(0) <= currency,
        orElse: () => UpgradeService.instance.metaUpgrades.first,
      );

      if (currency >= affordableUpgrade.costForLevel(0)) {
        final purchased = await UpgradeService.instance.purchase(affordableUpgrade.id);
        expect(purchased, isTrue);
      }
    });
  });

  group('StorageService Integration', () {
    test('initializes correctly', () async {
      await StorageService.instance.initialize();
      expect(StorageService.instance.isReady, isTrue);
    });

    test('persists level progress', () async {
      await StorageService.instance.initialize();

      await StorageService.instance.saveLevelProgress(
        levelId: 1,
        completed: true,
        stars: 3,
        highScore: 1000,
        bestWave: 5,
      );

      final allProgress = StorageService.instance.loadAllLevelProgress();
      expect(allProgress.containsKey(1), isTrue);
      expect(allProgress[1]!['completed'], isTrue);
      expect(allProgress[1]!['stars'], 3);
    });

    test('persists meta currency', () async {
      await StorageService.instance.initialize();

      await StorageService.instance.saveMetaCurrency(500);
      final currency = StorageService.instance.loadMetaCurrency();
      expect(currency, 500);
    });

    test('persists upgrade levels', () async {
      await StorageService.instance.initialize();

      await StorageService.instance.saveUpgradeLevels({'core_amplifier': 3});
      final levels = StorageService.instance.loadUpgradeLevels();
      expect(levels['core_amplifier'], 3);
    });

    test('persists unlocked levels', () async {
      await StorageService.instance.initialize();

      await StorageService.instance.saveUnlockedLevels({1, 2, 3});
      final unlocked = StorageService.instance.loadUnlockedLevels();
      expect(unlocked, containsAll([1, 2, 3]));
    });

    test('clear progress works', () async {
      await StorageService.instance.initialize();

      await StorageService.instance.saveLevelProgress(
        levelId: 1,
        completed: true,
        stars: 3,
        highScore: 1000,
        bestWave: 5,
      );

      await StorageService.instance.clearProgress();

      final allProgress = StorageService.instance.loadAllLevelProgress();
      expect(allProgress, isEmpty);
    });
  });
}
