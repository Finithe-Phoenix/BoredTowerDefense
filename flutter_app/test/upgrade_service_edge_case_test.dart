// Tests for UpgradeService edge cases: purchase sequences, cost formulas, roll distribution
// Simulation-based (no external dependencies)
import 'dart:math' as math;
import 'package:test/test.dart';

class _FastRng {
  int _state;
  _FastRng([int? seed]) : _state = (seed ?? 0x6d2b79f5) & 0x7fffffff;

  int _next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  double nextDouble() => _next() / 0x7fffffff;
  int nextInt(int max) => max <= 0 ? 0 : _next() % max;
}

/// Simulated UpgradeStats matching the real implementation
class SimUpgradeStats {
  const SimUpgradeStats({
    this.towerDamageMult = 1.0,
    this.towerRangeMult = 1.0,
    this.towerFireRateMult = 1.0,
    this.projectileSpeedMult = 1.0,
    this.slowMult = 1.0,
    this.goldGainMult = 1.0,
    this.towerCostMult = 1.0,
    this.pulseCooldownMult = 1.0,
    this.mineCooldownMult = 1.0,
    this.startingGoldBonus = 0,
    this.startingLivesBonus = 0,
    this.maxMinesBonus = 0,
  });

  final double towerDamageMult;
  final double towerRangeMult;
  final double towerFireRateMult;
  final double projectileSpeedMult;
  final double slowMult;
  final double goldGainMult;
  final double towerCostMult;
  final double pulseCooldownMult;
  final double mineCooldownMult;
  final int startingGoldBonus;
  final int startingLivesBonus;
  final int maxMinesBonus;

  SimUpgradeStats merge(SimUpgradeStats other) {
    return SimUpgradeStats(
      towerDamageMult: towerDamageMult * other.towerDamageMult,
      towerRangeMult: towerRangeMult * other.towerRangeMult,
      towerFireRateMult: towerFireRateMult * other.towerFireRateMult,
      projectileSpeedMult: projectileSpeedMult * other.projectileSpeedMult,
      slowMult: slowMult * other.slowMult,
      goldGainMult: goldGainMult * other.goldGainMult,
      towerCostMult: towerCostMult * other.towerCostMult,
      pulseCooldownMult: pulseCooldownMult * other.pulseCooldownMult,
      mineCooldownMult: mineCooldownMult * other.mineCooldownMult,
      startingGoldBonus: startingGoldBonus + other.startingGoldBonus,
      startingLivesBonus: startingLivesBonus + other.startingLivesBonus,
      maxMinesBonus: maxMinesBonus + other.maxMinesBonus,
    );
  }

  static double _intPow(double base, int exp) {
    if (exp <= 0) return 1.0;
    if (exp == 1) return base;
    double result = base;
    for (int i = 1; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  SimUpgradeStats scale(int level) {
    if (level <= 0) return const SimUpgradeStats();
    return SimUpgradeStats(
      towerDamageMult: _intPow(towerDamageMult, level),
      towerRangeMult: _intPow(towerRangeMult, level),
      towerFireRateMult: _intPow(towerFireRateMult, level),
      projectileSpeedMult: _intPow(projectileSpeedMult, level),
      slowMult: _intPow(slowMult, level),
      goldGainMult: _intPow(goldGainMult, level),
      towerCostMult: _intPow(towerCostMult, level),
      pulseCooldownMult: _intPow(pulseCooldownMult, level),
      mineCooldownMult: _intPow(mineCooldownMult, level),
      startingGoldBonus: startingGoldBonus * level,
      startingLivesBonus: startingLivesBonus * level,
      maxMinesBonus: maxMinesBonus * level,
    );
  }
}

class SimUpgradeDefinition {
  const SimUpgradeDefinition({
    required this.id,
    required this.name,
    required this.maxLevel,
    required this.baseCost,
    required this.costStep,
    required this.perLevel,
  });

  final String id;
  final String name;
  final int maxLevel;
  final int baseCost;
  final int costStep;
  final SimUpgradeStats perLevel;

  int costForLevel(int level) => baseCost + (costStep * level);
  SimUpgradeStats statsForLevel(int level) => perLevel.scale(level);
}

class SimRunUpgradeDefinition {
  const SimRunUpgradeDefinition({
    required this.id,
    required this.name,
    required this.stats,
    this.maxStacks = 3,
  });

  final String id;
  final String name;
  final SimUpgradeStats stats;
  final int maxStacks;
}

/// Simulated UpgradeService
class SimUpgradeService {
  int _currency = 0;
  final Map<String, int> _metaLevels = {};
  final _FastRng _random = _FastRng();

  int get currency => _currency;
  Map<String, int> get levels => Map.unmodifiable(_metaLevels);

  void resetForTesting() {
    _currency = 0;
    _metaLevels.clear();
  }

  int levelFor(String id) => _metaLevels[id] ?? 0;

  SimUpgradeDefinition? upgradeById(String id) {
    for (final upgrade in _metaUpgrades) {
      if (upgrade.id == id) return upgrade;
    }
    return null;
  }

  bool canPurchase(SimUpgradeDefinition upgrade) {
    final level = levelFor(upgrade.id);
    if (level >= upgrade.maxLevel) return false;
    return _currency >= upgrade.costForLevel(level);
  }

  bool purchase(String id) {
    final upgrade = upgradeById(id);
    if (upgrade == null) return false;

    final level = levelFor(id);
    if (level >= upgrade.maxLevel) return false;
    final cost = upgrade.costForLevel(level);
    if (_currency < cost) return false;

    _currency -= cost;
    _metaLevels[id] = level + 1;
    return true;
  }

  void addCurrency(int amount) {
    if (amount <= 0) return;
    _currency += amount;
  }

  SimUpgradeStats get metaStats {
    var stats = const SimUpgradeStats();
    for (final upgrade in _metaUpgrades) {
      final level = math.min(levelFor(upgrade.id), upgrade.maxLevel);
      if (level <= 0) continue;
      stats = stats.merge(upgrade.statsForLevel(level));
    }
    return stats;
  }

  List<SimRunUpgradeDefinition> rollRunUpgrades({
    required Map<String, int> currentStacks,
    int count = 3,
  }) {
    final available = _runUpgrades.where((upgrade) {
      final stacks = currentStacks[upgrade.id] ?? 0;
      return stacks < upgrade.maxStacks;
    }).toList(growable: false);

    if (available.isEmpty) return const [];
    final result = <SimRunUpgradeDefinition>[];
    final pool = available.toList();
    while (result.length < count && pool.isNotEmpty) {
      final index = _random.nextInt(pool.length);
      result.add(pool.removeAt(index));
    }
    return result;
  }

  static const List<SimUpgradeDefinition> _metaUpgrades = [
    SimUpgradeDefinition(id: 'core_amplifier', name: 'Core Amplifier', maxLevel: 8, baseCost: 60, costStep: 25, perLevel: SimUpgradeStats(towerDamageMult: 1.07)),
    SimUpgradeDefinition(id: 'range_array', name: 'Range Array', maxLevel: 6, baseCost: 55, costStep: 20, perLevel: SimUpgradeStats(towerRangeMult: 1.05)),
    SimUpgradeDefinition(id: 'overclock_grid', name: 'Overclock Grid', maxLevel: 6, baseCost: 70, costStep: 30, perLevel: SimUpgradeStats(towerFireRateMult: 1.06)),
    SimUpgradeDefinition(id: 'battery_cells', name: 'Battery Cells', maxLevel: 8, baseCost: 40, costStep: 18, perLevel: SimUpgradeStats(startingGoldBonus: 15)),
    SimUpgradeDefinition(id: 'shield_matrix', name: 'Shield Matrix', maxLevel: 10, baseCost: 45, costStep: 20, perLevel: SimUpgradeStats(startingLivesBonus: 1)),
    SimUpgradeDefinition(id: 'efficiency_loop', name: 'Efficiency Loop', maxLevel: 6, baseCost: 65, costStep: 25, perLevel: SimUpgradeStats(towerCostMult: 0.96)),
    SimUpgradeDefinition(id: 'salvage_protocol', name: 'Salvage Protocol', maxLevel: 6, baseCost: 60, costStep: 25, perLevel: SimUpgradeStats(goldGainMult: 1.06)),
    SimUpgradeDefinition(id: 'phase_tuning', name: 'Phase Tuning', maxLevel: 5, baseCost: 55, costStep: 20, perLevel: SimUpgradeStats(slowMult: 1.08)),
  ];

  static const List<SimRunUpgradeDefinition> _runUpgrades = [
    SimRunUpgradeDefinition(id: 'run_damage', name: 'Damage Surge', stats: SimUpgradeStats(towerDamageMult: 1.12), maxStacks: 4),
    SimRunUpgradeDefinition(id: 'run_range', name: 'Range Boost', stats: SimUpgradeStats(towerRangeMult: 1.1), maxStacks: 3),
    SimRunUpgradeDefinition(id: 'run_fire', name: 'Overclock Burst', stats: SimUpgradeStats(towerFireRateMult: 1.12), maxStacks: 4),
    SimRunUpgradeDefinition(id: 'run_gold', name: 'Gold Overflow', stats: SimUpgradeStats(goldGainMult: 1.15), maxStacks: 4),
    SimRunUpgradeDefinition(id: 'run_cost', name: 'Discount Circuit', stats: SimUpgradeStats(towerCostMult: 0.9), maxStacks: 2),
    SimRunUpgradeDefinition(id: 'run_slow', name: 'Stasis Field', stats: SimUpgradeStats(slowMult: 1.15), maxStacks: 3),
  ];
}

void main() {
  late SimUpgradeService service;

  setUp(() {
    service = SimUpgradeService();
  });

  group('UpgradeService currency management', () {
    test('starts with zero currency', () {
      expect(service.currency, 0);
    });

    test('addCurrency increases balance', () {
      service.addCurrency(100);
      expect(service.currency, 100);
    });

    test('addCurrency with zero does nothing', () {
      service.addCurrency(0);
      expect(service.currency, 0);
    });

    test('addCurrency with negative does nothing', () {
      service.addCurrency(-50);
      expect(service.currency, 0);
    });

    test('addCurrency accumulates', () {
      service.addCurrency(100);
      service.addCurrency(50);
      service.addCurrency(25);
      expect(service.currency, 175);
    });
  });

  group('UpgradeService cost formulas', () {
    test('cost formula: baseCost + costStep * level', () {
      final upgrade = service.upgradeById('core_amplifier')!;
      // baseCost=60, costStep=25
      expect(upgrade.costForLevel(0), 60);  // First purchase
      expect(upgrade.costForLevel(1), 85);  // Second purchase
      expect(upgrade.costForLevel(2), 110); // Third purchase
    });

    test('cost escalation across all levels', () {
      final upgrade = service.upgradeById('core_amplifier')!;
      int prevCost = 0;
      for (int level = 0; level < upgrade.maxLevel; level++) {
        final cost = upgrade.costForLevel(level);
        expect(cost, greaterThan(prevCost),
            reason: 'Cost at level $level should increase');
        prevCost = cost;
      }
    });

    test('total cost to max out core_amplifier', () {
      final upgrade = service.upgradeById('core_amplifier')!;
      int totalCost = 0;
      for (int level = 0; level < upgrade.maxLevel; level++) {
        totalCost += upgrade.costForLevel(level);
      }
      // sum from level 0..7: 60+85+110+135+160+185+210+235 = 1180
      expect(totalCost, 1180);
    });
  });

  group('UpgradeService purchase flow', () {
    test('purchase succeeds with enough currency', () {
      service.addCurrency(100);
      final result = service.purchase('core_amplifier'); // Costs 60
      expect(result, isTrue);
      expect(service.currency, 40);
      expect(service.levelFor('core_amplifier'), 1);
    });

    test('purchase fails without enough currency', () {
      service.addCurrency(30);
      final result = service.purchase('core_amplifier'); // Costs 60
      expect(result, isFalse);
      expect(service.currency, 30);
      expect(service.levelFor('core_amplifier'), 0);
    });

    test('purchase fails for non-existent upgrade', () {
      service.addCurrency(1000);
      final result = service.purchase('nonexistent_upgrade');
      expect(result, isFalse);
    });

    test('purchase fails when max level reached', () {
      service.addCurrency(10000);
      final upgrade = service.upgradeById('phase_tuning')!; // maxLevel=5

      for (int i = 0; i < upgrade.maxLevel; i++) {
        expect(service.purchase('phase_tuning'), isTrue);
      }
      // Now at max
      expect(service.purchase('phase_tuning'), isFalse);
    });

    test('purchase at exact cost threshold', () {
      final upgrade = service.upgradeById('core_amplifier')!;
      service.addCurrency(upgrade.costForLevel(0)); // Exactly 60
      expect(service.purchase('core_amplifier'), isTrue);
      expect(service.currency, 0);
    });

    test('sequential purchases with cost escalation', () {
      service.addCurrency(1000);

      // core_amplifier: costs 60, 85, 110, 135...
      service.purchase('core_amplifier'); // -60, balance 940
      expect(service.currency, 940);

      service.purchase('core_amplifier'); // -85, balance 855
      expect(service.currency, 855);

      service.purchase('core_amplifier'); // -110, balance 745
      expect(service.currency, 745);
    });
  });

  group('UpgradeService canPurchase', () {
    test('true when currency sufficient', () {
      service.addCurrency(100);
      final upgrade = service.upgradeById('core_amplifier')!;
      expect(service.canPurchase(upgrade), isTrue);
    });

    test('false when currency insufficient', () {
      service.addCurrency(10);
      final upgrade = service.upgradeById('core_amplifier')!;
      expect(service.canPurchase(upgrade), isFalse);
    });

    test('false when at max level', () {
      service.addCurrency(10000);
      final upgrade = service.upgradeById('phase_tuning')!;
      for (int i = 0; i < upgrade.maxLevel; i++) {
        service.purchase('phase_tuning');
      }
      expect(service.canPurchase(upgrade), isFalse);
    });
  });

  group('UpgradeService metaStats aggregation', () {
    test('default stats are identity values', () {
      final stats = service.metaStats;
      expect(stats.towerDamageMult, 1.0);
      expect(stats.towerRangeMult, 1.0);
      expect(stats.startingGoldBonus, 0);
    });

    test('single upgrade stats apply correctly', () {
      service.addCurrency(100);
      service.purchase('core_amplifier'); // +7% damage per level

      final stats = service.metaStats;
      expect(stats.towerDamageMult, closeTo(1.07, 0.001));
    });

    test('multiple upgrades merge multiplicatively', () {
      service.addCurrency(10000);
      service.purchase('core_amplifier'); // 1.07 damage
      service.purchase('core_amplifier'); // 1.07^2 = 1.1449 damage

      final stats = service.metaStats;
      expect(stats.towerDamageMult, closeTo(1.07 * 1.07, 0.001));
    });

    test('different upgrades combine independently', () {
      service.addCurrency(10000);
      service.purchase('core_amplifier'); // damage +7%
      service.purchase('range_array');    // range +5%

      final stats = service.metaStats;
      expect(stats.towerDamageMult, closeTo(1.07, 0.001));
      expect(stats.towerRangeMult, closeTo(1.05, 0.001));
    });

    test('additive bonuses accumulate correctly', () {
      service.addCurrency(10000);
      service.purchase('battery_cells'); // +15 gold
      service.purchase('battery_cells'); // +30 gold total

      final stats = service.metaStats;
      expect(stats.startingGoldBonus, 30);
    });

    test('full upgrade path: max core_amplifier damage', () {
      service.addCurrency(10000);
      for (int i = 0; i < 8; i++) {
        service.purchase('core_amplifier');
      }

      final stats = service.metaStats;
      // 1.07^8 ≈ 1.7182
      final expected = math.pow(1.07, 8);
      expect(stats.towerDamageMult, closeTo(expected, 0.01));
    });
  });

  group('UpgradeService rollRunUpgrades', () {
    test('returns requested count', () {
      final result = service.rollRunUpgrades(
        currentStacks: {},
        count: 3,
      );
      expect(result.length, 3);
    });

    test('respects max stacks', () {
      final maxed = <String, int>{
        'run_damage': 4,
        'run_range': 3,
        'run_fire': 4,
        'run_gold': 4,
        'run_cost': 2,
        'run_slow': 3,
      };
      final result = service.rollRunUpgrades(currentStacks: maxed);
      expect(result, isEmpty);
    });

    test('returns empty when all maxed', () {
      final maxed = <String, int>{
        'run_damage': 4,
        'run_range': 3,
        'run_fire': 4,
        'run_gold': 4,
        'run_cost': 2,
        'run_slow': 3,
      };
      final result = service.rollRunUpgrades(currentStacks: maxed);
      expect(result, isEmpty);
    });

    test('no duplicates in single roll', () {
      final result = service.rollRunUpgrades(
        currentStacks: {},
        count: 3,
      );
      final ids = result.map((u) => u.id).toSet();
      expect(ids.length, result.length); // All unique
    });

    test('fewer results when pool is smaller than count', () {
      // Only 2 upgrades available
      final stacks = <String, int>{
        'run_damage': 4, // maxed
        'run_fire': 4,   // maxed
        'run_gold': 4,   // maxed
        'run_cost': 2,   // maxed
      };
      final result = service.rollRunUpgrades(
        currentStacks: stacks,
        count: 3,
      );
      expect(result.length, 2); // Only run_range and run_slow available
    });

    test('count 0 returns empty', () {
      final result = service.rollRunUpgrades(
        currentStacks: {},
        count: 0,
      );
      expect(result, isEmpty);
    });

    test('count 1 returns single item', () {
      final result = service.rollRunUpgrades(
        currentStacks: {},
        count: 1,
      );
      expect(result.length, 1);
    });

    test('roll fairness: all items appear over many rolls', () {
      final counts = <String, int>{};
      for (int i = 0; i < 100; i++) {
        final result = service.rollRunUpgrades(
          currentStacks: {},
          count: 3,
        );
        for (final u in result) {
          counts[u.id] = (counts[u.id] ?? 0) + 1;
        }
      }
      // Each of the 6 upgrades should appear at least once in 100 rolls of 3
      expect(counts.length, 6);
    });
  });

  group('UpgradeService resetForTesting', () {
    test('reset clears all state', () {
      service.addCurrency(500);
      service.purchase('core_amplifier');

      service.resetForTesting();
      expect(service.currency, 0);
      expect(service.levelFor('core_amplifier'), 0);
      expect(service.levels, isEmpty);
    });

    test('can purchase after reset', () {
      service.addCurrency(100);
      service.purchase('core_amplifier');
      service.resetForTesting();

      service.addCurrency(100);
      expect(service.purchase('core_amplifier'), isTrue);
      expect(service.levelFor('core_amplifier'), 1);
    });
  });

  group('UpgradeStats scale method', () {
    test('scale 0 returns identity', () {
      const stats = SimUpgradeStats(towerDamageMult: 1.07);
      final scaled = stats.scale(0);
      expect(scaled.towerDamageMult, 1.0);
    });

    test('scale 1 returns same stats', () {
      const stats = SimUpgradeStats(towerDamageMult: 1.07);
      final scaled = stats.scale(1);
      expect(scaled.towerDamageMult, closeTo(1.07, 0.001));
    });

    test('scale compounds multiplicative stats', () {
      const stats = SimUpgradeStats(towerDamageMult: 1.07);
      final scaled = stats.scale(3);
      // 1.07^3 = 1.225043
      expect(scaled.towerDamageMult, closeTo(math.pow(1.07, 3), 0.001));
    });

    test('scale multiplies additive bonuses', () {
      const stats = SimUpgradeStats(startingGoldBonus: 15);
      final scaled = stats.scale(5);
      expect(scaled.startingGoldBonus, 75);
    });

    test('negative level returns identity', () {
      const stats = SimUpgradeStats(towerDamageMult: 1.07);
      final scaled = stats.scale(-1);
      expect(scaled.towerDamageMult, 1.0);
    });
  });

  group('UpgradeStats merge method', () {
    test('merge identity preserves values', () {
      const stats = SimUpgradeStats(towerDamageMult: 1.5);
      final merged = stats.merge(const SimUpgradeStats());
      expect(merged.towerDamageMult, 1.5);
    });

    test('merge multiplies multiplicative stats', () {
      const a = SimUpgradeStats(towerDamageMult: 1.1);
      const b = SimUpgradeStats(towerDamageMult: 1.2);
      final merged = a.merge(b);
      expect(merged.towerDamageMult, closeTo(1.32, 0.001));
    });

    test('merge adds additive stats', () {
      const a = SimUpgradeStats(startingGoldBonus: 15, startingLivesBonus: 2);
      const b = SimUpgradeStats(startingGoldBonus: 10, startingLivesBonus: 3);
      final merged = a.merge(b);
      expect(merged.startingGoldBonus, 25);
      expect(merged.startingLivesBonus, 5);
    });
  });
}
