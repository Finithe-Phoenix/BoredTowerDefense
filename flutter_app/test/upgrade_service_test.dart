import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bored_games/src/services/storage_service.dart';
import 'package:bored_games/src/services/upgrade_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
    await UpgradeService.instance.initialize();
  });

  test('meta upgrades are available', () {
    expect(UpgradeService.instance.metaUpgrades, isNotEmpty);
    expect(UpgradeService.instance.upgradeById('core_amplifier'), isNotNull);
  });

  test('levels getter is unmodifiable', () {
    final levels = UpgradeService.instance.levels;
    expect(() => levels['x'] = 1, throwsUnsupportedError);
  });

  test('initialize loads storage when needed', () async {
    StorageService.instance.resetForTesting();
    UpgradeService.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await UpgradeService.instance.initialize();
    expect(StorageService.instance.isReady, isTrue);
    expect(UpgradeService.instance.currency, 0);
  });

  test('metaStats reflects purchased upgrades when possible', () async {
    final upgrade = UpgradeService.instance.metaUpgrades.first;
    final beforeLevel = UpgradeService.instance.levelFor(upgrade.id);
    final beforeStats = UpgradeService.instance.metaStats;
    final cost = upgrade.costForLevel(beforeLevel);

    if (beforeLevel < upgrade.maxLevel) {
      if (UpgradeService.instance.currency < cost) {
        await UpgradeService.instance.addCurrency(cost - UpgradeService.instance.currency);
      }
      final ok = await UpgradeService.instance.purchase(upgrade.id);
      expect(ok, isTrue);
      final afterStats = UpgradeService.instance.metaStats;
      expect(afterStats.towerDamageMult >= beforeStats.towerDamageMult, isTrue);
    } else {
      final stats = UpgradeService.instance.metaStats;
      expect(stats.towerDamageMult, greaterThanOrEqualTo(1.0));
    }
  });

  test('addCurrency increases currency', () async {
    final before = UpgradeService.instance.currency;
    await UpgradeService.instance.addCurrency(7);
    expect(UpgradeService.instance.currency, before + 7);
  });

  test('purchase increases upgrade level when affordable', () async {
    final upgrade = UpgradeService.instance.upgradeById('core_amplifier')!;
    final beforeLevel = UpgradeService.instance.levelFor(upgrade.id);
    final cost = upgrade.costForLevel(beforeLevel);
    if (UpgradeService.instance.currency < cost) {
      await UpgradeService.instance.addCurrency(cost - UpgradeService.instance.currency);
    }

    final ok = await UpgradeService.instance.purchase(upgrade.id);
    if (beforeLevel >= upgrade.maxLevel) {
      expect(ok, isFalse);
    } else {
      expect(ok, isTrue);
      expect(UpgradeService.instance.levelFor(upgrade.id), beforeLevel + 1);
    }
  });

  test('canPurchase checks currency when not maxed', () async {
    UpgradeService.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await UpgradeService.instance.initialize();
    final upgrade = UpgradeService.instance.upgradeById('core_amplifier')!;
    expect(UpgradeService.instance.canPurchase(upgrade), isFalse);

    final cost = upgrade.costForLevel(UpgradeService.instance.levelFor(upgrade.id));
    await UpgradeService.instance.addCurrency(cost);
    expect(UpgradeService.instance.canPurchase(upgrade), isTrue);
  });

  test('canPurchase returns false when maxed', () async {
    final upgrade = UpgradeService.instance.upgradeById('mine_forge')!;
    while (UpgradeService.instance.levelFor(upgrade.id) < upgrade.maxLevel) {
      final level = UpgradeService.instance.levelFor(upgrade.id);
      final cost = upgrade.costForLevel(level);
      if (UpgradeService.instance.currency < cost) {
        await UpgradeService.instance.addCurrency(cost - UpgradeService.instance.currency);
      }
      await UpgradeService.instance.purchase(upgrade.id);
    }
    expect(UpgradeService.instance.canPurchase(upgrade), isFalse);
  });

  test('upgradeById returns null when missing', () {
    expect(UpgradeService.instance.upgradeById('missing_upgrade'), isNull);
  });

  test('rollRunUpgrades respects max stacks and returns unique picks', () {
    final first = UpgradeService.instance.runUpgrades.first;
    final choices = UpgradeService.instance.rollRunUpgrades(
      currentStacks: {first.id: first.maxStacks},
      count: 3,
    );
    final ids = choices.map((upgrade) => upgrade.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.contains(first.id), isFalse);
    expect(choices.length <= 3, isTrue);
  });

  test('rollRunUpgrades returns empty when all maxed', () {
    final allMaxed = <String, int>{
      for (final upgrade in UpgradeService.instance.runUpgrades)
        upgrade.id: upgrade.maxStacks,
    };
    final choices = UpgradeService.instance.rollRunUpgrades(
      currentStacks: allMaxed,
      count: 3,
    );
    expect(choices, isEmpty);
  });
}
