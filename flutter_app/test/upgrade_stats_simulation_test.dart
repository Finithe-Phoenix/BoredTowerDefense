import 'package:test/test.dart';

/// Simulation test for UpgradeStats logic without Flutter dependencies.
/// Tests the mathematical operations: merge, scale, _intPow, cost calculations.

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED CLASSES - Replicate exact logic from upgrade_data.dart
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedUpgradeStats {
  const SimulatedUpgradeStats({
    this.towerDamageMult = 1.0,
    this.towerRangeMult = 1.0,
    this.towerFireRateMult = 1.0,
    this.projectileSpeedMult = 1.0,
    this.slowMult = 1.0,
    this.goldGainMult = 1.0,
    this.towerCostMult = 1.0,
    this.pulseCooldownMult = 1.0,
    this.mineCooldownMult = 1.0,
    this.abilityCostMult = 1.0,
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
  final double abilityCostMult;
  final int startingGoldBonus;
  final int startingLivesBonus;
  final int maxMinesBonus;

  SimulatedUpgradeStats merge(SimulatedUpgradeStats other) {
    return SimulatedUpgradeStats(
      towerDamageMult: towerDamageMult * other.towerDamageMult,
      towerRangeMult: towerRangeMult * other.towerRangeMult,
      towerFireRateMult: towerFireRateMult * other.towerFireRateMult,
      projectileSpeedMult: projectileSpeedMult * other.projectileSpeedMult,
      slowMult: slowMult * other.slowMult,
      goldGainMult: goldGainMult * other.goldGainMult,
      towerCostMult: towerCostMult * other.towerCostMult,
      pulseCooldownMult: pulseCooldownMult * other.pulseCooldownMult,
      mineCooldownMult: mineCooldownMult * other.mineCooldownMult,
      abilityCostMult: abilityCostMult * other.abilityCostMult,
      startingGoldBonus: startingGoldBonus + other.startingGoldBonus,
      startingLivesBonus: startingLivesBonus + other.startingLivesBonus,
      maxMinesBonus: maxMinesBonus + other.maxMinesBonus,
    );
  }

  /// Iterative power for integer exponents - avoids expensive math.pow()
  static double intPow(double base, int exp) {
    if (exp <= 0) return 1.0;
    if (exp == 1) return base;
    double result = base;
    for (int i = 1; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  SimulatedUpgradeStats scale(int level) {
    if (level <= 0) return const SimulatedUpgradeStats();
    return SimulatedUpgradeStats(
      towerDamageMult: intPow(towerDamageMult, level),
      towerRangeMult: intPow(towerRangeMult, level),
      towerFireRateMult: intPow(towerFireRateMult, level),
      projectileSpeedMult: intPow(projectileSpeedMult, level),
      slowMult: intPow(slowMult, level),
      goldGainMult: intPow(goldGainMult, level),
      towerCostMult: intPow(towerCostMult, level),
      pulseCooldownMult: intPow(pulseCooldownMult, level),
      mineCooldownMult: intPow(mineCooldownMult, level),
      abilityCostMult: intPow(abilityCostMult, level),
      startingGoldBonus: startingGoldBonus * level,
      startingLivesBonus: startingLivesBonus * level,
      maxMinesBonus: maxMinesBonus * level,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SimulatedUpgradeStats) return false;
    return towerDamageMult == other.towerDamageMult &&
        towerRangeMult == other.towerRangeMult &&
        towerFireRateMult == other.towerFireRateMult &&
        projectileSpeedMult == other.projectileSpeedMult &&
        slowMult == other.slowMult &&
        goldGainMult == other.goldGainMult &&
        towerCostMult == other.towerCostMult &&
        pulseCooldownMult == other.pulseCooldownMult &&
        mineCooldownMult == other.mineCooldownMult &&
        abilityCostMult == other.abilityCostMult &&
        startingGoldBonus == other.startingGoldBonus &&
        startingLivesBonus == other.startingLivesBonus &&
        maxMinesBonus == other.maxMinesBonus;
  }

  @override
  int get hashCode => Object.hash(
        towerDamageMult,
        towerRangeMult,
        towerFireRateMult,
        projectileSpeedMult,
        slowMult,
        goldGainMult,
        towerCostMult,
        pulseCooldownMult,
        mineCooldownMult,
        abilityCostMult,
        startingGoldBonus,
        startingLivesBonus,
        maxMinesBonus,
      );
}

class SimulatedUpgradeDefinition {
  const SimulatedUpgradeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.maxLevel,
    required this.baseCost,
    required this.costStep,
    required this.perLevel,
  });

  final String id;
  final String name;
  final String description;
  final int maxLevel;
  final int baseCost;
  final int costStep;
  final SimulatedUpgradeStats perLevel;

  int costForLevel(int level) => baseCost + (costStep * level);

  SimulatedUpgradeStats statsForLevel(int level) => perLevel.scale(level);
}

class SimulatedRunUpgradeDefinition {
  const SimulatedRunUpgradeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.stats,
    this.maxStacks = 3,
    this.instantGold = 0,
    this.instantLives = 0,
  });

  final String id;
  final String name;
  final String description;
  final SimulatedUpgradeStats stats;
  final int maxStacks;
  final int instantGold;
  final int instantLives;
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEST SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('SimulatedUpgradeStats._intPow', () {
    test('returns 1.0 for exponent 0', () {
      expect(SimulatedUpgradeStats.intPow(2.0, 0), equals(1.0));
      expect(SimulatedUpgradeStats.intPow(5.0, 0), equals(1.0));
      expect(SimulatedUpgradeStats.intPow(1.5, 0), equals(1.0));
    });

    test('returns 1.0 for negative exponents', () {
      expect(SimulatedUpgradeStats.intPow(2.0, -1), equals(1.0));
      expect(SimulatedUpgradeStats.intPow(3.0, -5), equals(1.0));
      expect(SimulatedUpgradeStats.intPow(1.1, -100), equals(1.0));
    });

    test('returns base for exponent 1', () {
      expect(SimulatedUpgradeStats.intPow(2.0, 1), equals(2.0));
      expect(SimulatedUpgradeStats.intPow(1.15, 1), equals(1.15));
      expect(SimulatedUpgradeStats.intPow(0.9, 1), equals(0.9));
    });

    test('calculates correct power for exponent 2', () {
      expect(SimulatedUpgradeStats.intPow(2.0, 2), equals(4.0));
      expect(SimulatedUpgradeStats.intPow(3.0, 2), equals(9.0));
      expect(SimulatedUpgradeStats.intPow(1.1, 2), closeTo(1.21, 0.0001));
    });

    test('calculates correct power for exponent 3', () {
      expect(SimulatedUpgradeStats.intPow(2.0, 3), equals(8.0));
      expect(SimulatedUpgradeStats.intPow(3.0, 3), equals(27.0));
      expect(SimulatedUpgradeStats.intPow(1.1, 3), closeTo(1.331, 0.0001));
    });

    test('calculates correct power for large exponents', () {
      expect(SimulatedUpgradeStats.intPow(2.0, 10), equals(1024.0));
      expect(SimulatedUpgradeStats.intPow(1.1, 5), closeTo(1.61051, 0.0001));
      expect(SimulatedUpgradeStats.intPow(1.05, 10), closeTo(1.62889, 0.0001));
    });

    test('handles fractional bases correctly', () {
      expect(SimulatedUpgradeStats.intPow(0.5, 2), equals(0.25));
      expect(SimulatedUpgradeStats.intPow(0.5, 3), equals(0.125));
      expect(SimulatedUpgradeStats.intPow(0.9, 2), closeTo(0.81, 0.0001));
    });

    test('handles base of 1.0 for any exponent', () {
      expect(SimulatedUpgradeStats.intPow(1.0, 1), equals(1.0));
      expect(SimulatedUpgradeStats.intPow(1.0, 5), equals(1.0));
      expect(SimulatedUpgradeStats.intPow(1.0, 100), equals(1.0));
    });

    test('handles typical upgrade multipliers', () {
      // Damage upgrade: 1.15x per level
      expect(SimulatedUpgradeStats.intPow(1.15, 1), equals(1.15));
      expect(SimulatedUpgradeStats.intPow(1.15, 2), closeTo(1.3225, 0.0001));
      expect(SimulatedUpgradeStats.intPow(1.15, 3), closeTo(1.520875, 0.0001));
      expect(SimulatedUpgradeStats.intPow(1.15, 5), closeTo(2.01136, 0.0001));
    });
  });

  group('SimulatedUpgradeStats.merge', () {
    test('merging with default stats returns same values', () {
      const stats = SimulatedUpgradeStats(
        towerDamageMult: 1.5,
        towerRangeMult: 1.2,
        startingGoldBonus: 50,
      );
      const defaultStats = SimulatedUpgradeStats();
      final merged = stats.merge(defaultStats);

      expect(merged.towerDamageMult, equals(1.5));
      expect(merged.towerRangeMult, equals(1.2));
      expect(merged.startingGoldBonus, equals(50));
    });

    test('multiplies all multiplier fields', () {
      const stats1 = SimulatedUpgradeStats(
        towerDamageMult: 1.5,
        towerRangeMult: 1.2,
        towerFireRateMult: 0.9,
        projectileSpeedMult: 1.1,
        slowMult: 1.3,
        goldGainMult: 1.4,
        towerCostMult: 0.85,
        pulseCooldownMult: 0.8,
        mineCooldownMult: 0.75,
        abilityCostMult: 0.9,
      );
      const stats2 = SimulatedUpgradeStats(
        towerDamageMult: 1.2,
        towerRangeMult: 1.1,
        towerFireRateMult: 0.95,
        projectileSpeedMult: 1.05,
        slowMult: 1.1,
        goldGainMult: 1.2,
        towerCostMult: 0.9,
        pulseCooldownMult: 0.9,
        mineCooldownMult: 0.85,
        abilityCostMult: 0.95,
      );
      final merged = stats1.merge(stats2);

      expect(merged.towerDamageMult, closeTo(1.8, 0.0001));
      expect(merged.towerRangeMult, closeTo(1.32, 0.0001));
      expect(merged.towerFireRateMult, closeTo(0.855, 0.0001));
      expect(merged.projectileSpeedMult, closeTo(1.155, 0.0001));
      expect(merged.slowMult, closeTo(1.43, 0.0001));
      expect(merged.goldGainMult, closeTo(1.68, 0.0001));
      expect(merged.towerCostMult, closeTo(0.765, 0.0001));
      expect(merged.pulseCooldownMult, closeTo(0.72, 0.0001));
      expect(merged.mineCooldownMult, closeTo(0.6375, 0.0001));
      expect(merged.abilityCostMult, closeTo(0.855, 0.0001));
    });

    test('adds all bonus fields', () {
      const stats1 = SimulatedUpgradeStats(
        startingGoldBonus: 50,
        startingLivesBonus: 2,
        maxMinesBonus: 1,
      );
      const stats2 = SimulatedUpgradeStats(
        startingGoldBonus: 30,
        startingLivesBonus: 1,
        maxMinesBonus: 2,
      );
      final merged = stats1.merge(stats2);

      expect(merged.startingGoldBonus, equals(80));
      expect(merged.startingLivesBonus, equals(3));
      expect(merged.maxMinesBonus, equals(3));
    });

    test('merge is associative', () {
      const a = SimulatedUpgradeStats(towerDamageMult: 1.2, startingGoldBonus: 10);
      const b = SimulatedUpgradeStats(towerDamageMult: 1.3, startingGoldBonus: 20);
      const c = SimulatedUpgradeStats(towerDamageMult: 1.1, startingGoldBonus: 15);

      final ab_c = a.merge(b).merge(c);
      final a_bc = a.merge(b.merge(c));

      expect(ab_c.towerDamageMult, closeTo(a_bc.towerDamageMult, 0.0001));
      expect(ab_c.startingGoldBonus, equals(a_bc.startingGoldBonus));
    });

    test('merge is commutative for multipliers', () {
      const a = SimulatedUpgradeStats(towerDamageMult: 1.5, towerRangeMult: 1.2);
      const b = SimulatedUpgradeStats(towerDamageMult: 1.3, towerRangeMult: 1.1);

      final ab = a.merge(b);
      final ba = b.merge(a);

      expect(ab.towerDamageMult, closeTo(ba.towerDamageMult, 0.0001));
      expect(ab.towerRangeMult, closeTo(ba.towerRangeMult, 0.0001));
    });

    test('merging multiple upgrades compounds correctly', () {
      const upgrade = SimulatedUpgradeStats(towerDamageMult: 1.1);
      var result = const SimulatedUpgradeStats();
      for (int i = 0; i < 5; i++) {
        result = result.merge(upgrade);
      }

      // 1.1^5 = 1.61051
      expect(result.towerDamageMult, closeTo(1.61051, 0.0001));
    });

    test('handles cost reduction multipliers correctly', () {
      const discount1 = SimulatedUpgradeStats(towerCostMult: 0.9);
      const discount2 = SimulatedUpgradeStats(towerCostMult: 0.85);
      final merged = discount1.merge(discount2);

      // 0.9 * 0.85 = 0.765 (23.5% total discount)
      expect(merged.towerCostMult, closeTo(0.765, 0.0001));
    });

    test('handles cooldown reduction multipliers correctly', () {
      const cooldown1 = SimulatedUpgradeStats(pulseCooldownMult: 0.8);
      const cooldown2 = SimulatedUpgradeStats(pulseCooldownMult: 0.9);
      final merged = cooldown1.merge(cooldown2);

      // 0.8 * 0.9 = 0.72 (28% faster cooldown)
      expect(merged.pulseCooldownMult, closeTo(0.72, 0.0001));
    });
  });

  group('SimulatedUpgradeStats.scale', () {
    test('scale(0) returns default stats', () {
      const stats = SimulatedUpgradeStats(
        towerDamageMult: 1.15,
        startingGoldBonus: 20,
      );
      final scaled = stats.scale(0);

      expect(scaled.towerDamageMult, equals(1.0));
      expect(scaled.startingGoldBonus, equals(0));
    });

    test('scale(-1) returns default stats', () {
      const stats = SimulatedUpgradeStats(
        towerDamageMult: 1.15,
        startingGoldBonus: 20,
      );
      final scaled = stats.scale(-1);

      expect(scaled.towerDamageMult, equals(1.0));
      expect(scaled.startingGoldBonus, equals(0));
    });

    test('scale(1) returns original multipliers and bonuses', () {
      const stats = SimulatedUpgradeStats(
        towerDamageMult: 1.15,
        towerRangeMult: 1.1,
        startingGoldBonus: 20,
        startingLivesBonus: 1,
      );
      final scaled = stats.scale(1);

      expect(scaled.towerDamageMult, equals(1.15));
      expect(scaled.towerRangeMult, equals(1.1));
      expect(scaled.startingGoldBonus, equals(20));
      expect(scaled.startingLivesBonus, equals(1));
    });

    test('scale(2) squares multipliers and doubles bonuses', () {
      const stats = SimulatedUpgradeStats(
        towerDamageMult: 1.15,
        startingGoldBonus: 20,
      );
      final scaled = stats.scale(2);

      expect(scaled.towerDamageMult, closeTo(1.3225, 0.0001)); // 1.15^2
      expect(scaled.startingGoldBonus, equals(40)); // 20 * 2
    });

    test('scale(5) applies correct compound effect', () {
      const stats = SimulatedUpgradeStats(
        towerDamageMult: 1.1,
        towerRangeMult: 1.05,
        startingGoldBonus: 10,
        maxMinesBonus: 1,
      );
      final scaled = stats.scale(5);

      expect(scaled.towerDamageMult, closeTo(1.61051, 0.0001)); // 1.1^5
      expect(scaled.towerRangeMult, closeTo(1.27628, 0.0001)); // 1.05^5
      expect(scaled.startingGoldBonus, equals(50)); // 10 * 5
      expect(scaled.maxMinesBonus, equals(5)); // 1 * 5
    });

    test('scale works correctly for cost reduction', () {
      const stats = SimulatedUpgradeStats(towerCostMult: 0.95);
      final scaled = stats.scale(5);

      // 0.95^5 = 0.77378
      expect(scaled.towerCostMult, closeTo(0.77378, 0.0001));
    });

    test('scale works correctly for cooldown reduction', () {
      const stats = SimulatedUpgradeStats(pulseCooldownMult: 0.9);
      final scaled = stats.scale(3);

      // 0.9^3 = 0.729
      expect(scaled.pulseCooldownMult, closeTo(0.729, 0.0001));
    });

    test('scale preserves all fields', () {
      const stats = SimulatedUpgradeStats(
        towerDamageMult: 1.1,
        towerRangeMult: 1.05,
        towerFireRateMult: 0.95,
        projectileSpeedMult: 1.08,
        slowMult: 1.12,
        goldGainMult: 1.15,
        towerCostMult: 0.92,
        pulseCooldownMult: 0.88,
        mineCooldownMult: 0.9,
        abilityCostMult: 0.93,
        startingGoldBonus: 15,
        startingLivesBonus: 1,
        maxMinesBonus: 1,
      );
      final scaled = stats.scale(3);

      expect(scaled.towerDamageMult, closeTo(1.331, 0.0001));
      expect(scaled.towerRangeMult, closeTo(1.157625, 0.0001));
      expect(scaled.towerFireRateMult, closeTo(0.857375, 0.0001));
      expect(scaled.projectileSpeedMult, closeTo(1.259712, 0.0001));
      expect(scaled.slowMult, closeTo(1.404928, 0.0001));
      expect(scaled.goldGainMult, closeTo(1.520875, 0.0001));
      expect(scaled.towerCostMult, closeTo(0.778688, 0.0001));
      expect(scaled.pulseCooldownMult, closeTo(0.681472, 0.0001));
      expect(scaled.mineCooldownMult, closeTo(0.729, 0.0001));
      expect(scaled.abilityCostMult, closeTo(0.804357, 0.0001));
      expect(scaled.startingGoldBonus, equals(45));
      expect(scaled.startingLivesBonus, equals(3));
      expect(scaled.maxMinesBonus, equals(3));
    });
  });

  group('SimulatedUpgradeDefinition', () {
    test('costForLevel calculates correctly', () {
      const def = SimulatedUpgradeDefinition(
        id: 'damage_up',
        name: 'Damage Up',
        description: 'Increases tower damage',
        maxLevel: 5,
        baseCost: 100,
        costStep: 50,
        perLevel: SimulatedUpgradeStats(towerDamageMult: 1.15),
      );

      expect(def.costForLevel(0), equals(100)); // base + 0 * step
      expect(def.costForLevel(1), equals(150)); // base + 1 * step
      expect(def.costForLevel(2), equals(200)); // base + 2 * step
      expect(def.costForLevel(3), equals(250)); // base + 3 * step
      expect(def.costForLevel(4), equals(300)); // base + 4 * step
      expect(def.costForLevel(5), equals(350)); // base + 5 * step
    });

    test('costForLevel with zero costStep returns baseCost', () {
      const def = SimulatedUpgradeDefinition(
        id: 'flat_cost',
        name: 'Flat Cost',
        description: 'Same cost each level',
        maxLevel: 3,
        baseCost: 200,
        costStep: 0,
        perLevel: SimulatedUpgradeStats(towerRangeMult: 1.1),
      );

      expect(def.costForLevel(0), equals(200));
      expect(def.costForLevel(1), equals(200));
      expect(def.costForLevel(2), equals(200));
      expect(def.costForLevel(3), equals(200));
    });

    test('statsForLevel returns scaled stats', () {
      const def = SimulatedUpgradeDefinition(
        id: 'speed_up',
        name: 'Speed Up',
        description: 'Increases projectile speed',
        maxLevel: 10,
        baseCost: 75,
        costStep: 25,
        perLevel: SimulatedUpgradeStats(
          projectileSpeedMult: 1.08,
          startingGoldBonus: 5,
        ),
      );

      final level0 = def.statsForLevel(0);
      expect(level0.projectileSpeedMult, equals(1.0));
      expect(level0.startingGoldBonus, equals(0));

      final level1 = def.statsForLevel(1);
      expect(level1.projectileSpeedMult, equals(1.08));
      expect(level1.startingGoldBonus, equals(5));

      final level3 = def.statsForLevel(3);
      expect(level3.projectileSpeedMult, closeTo(1.259712, 0.0001));
      expect(level3.startingGoldBonus, equals(15));

      final level5 = def.statsForLevel(5);
      expect(level5.projectileSpeedMult, closeTo(1.46933, 0.0001));
      expect(level5.startingGoldBonus, equals(25));
    });

    test('maxLevel is stored correctly', () {
      const def = SimulatedUpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test upgrade',
        maxLevel: 7,
        baseCost: 50,
        costStep: 10,
        perLevel: SimulatedUpgradeStats(),
      );

      expect(def.maxLevel, equals(7));
    });
  });

  group('SimulatedRunUpgradeDefinition', () {
    test('stores stats correctly', () {
      const stats = SimulatedUpgradeStats(
        towerDamageMult: 1.25,
        goldGainMult: 1.1,
      );
      const runUpgrade = SimulatedRunUpgradeDefinition(
        id: 'power_surge',
        name: 'Power Surge',
        description: 'Temporary damage boost',
        stats: stats,
      );

      expect(runUpgrade.stats.towerDamageMult, equals(1.25));
      expect(runUpgrade.stats.goldGainMult, equals(1.1));
    });

    test('default maxStacks is 3', () {
      const runUpgrade = SimulatedRunUpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        stats: SimulatedUpgradeStats(),
      );

      expect(runUpgrade.maxStacks, equals(3));
    });

    test('custom maxStacks is stored', () {
      const runUpgrade = SimulatedRunUpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        stats: SimulatedUpgradeStats(),
        maxStacks: 5,
      );

      expect(runUpgrade.maxStacks, equals(5));
    });

    test('instant gold and lives are stored', () {
      const runUpgrade = SimulatedRunUpgradeDefinition(
        id: 'gold_rush',
        name: 'Gold Rush',
        description: 'Instant gold',
        stats: SimulatedUpgradeStats(),
        instantGold: 100,
        instantLives: 2,
      );

      expect(runUpgrade.instantGold, equals(100));
      expect(runUpgrade.instantLives, equals(2));
    });

    test('default instant values are 0', () {
      const runUpgrade = SimulatedRunUpgradeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        stats: SimulatedUpgradeStats(),
      );

      expect(runUpgrade.instantGold, equals(0));
      expect(runUpgrade.instantLives, equals(0));
    });
  });

  group('Upgrade Progression Scenarios', () {
    test('typical damage upgrade progression', () {
      const damageUpgrade = SimulatedUpgradeDefinition(
        id: 'damage',
        name: 'Damage Boost',
        description: '+15% tower damage per level',
        maxLevel: 5,
        baseCost: 100,
        costStep: 75,
        perLevel: SimulatedUpgradeStats(towerDamageMult: 1.15),
      );

      // Simulate buying all 5 levels
      var totalCost = 0;
      var totalStats = const SimulatedUpgradeStats();

      for (int level = 0; level < 5; level++) {
        totalCost += damageUpgrade.costForLevel(level);
        totalStats = totalStats.merge(damageUpgrade.perLevel);
      }

      // Total cost: 100 + 175 + 250 + 325 + 400 = 1250
      expect(totalCost, equals(1250));

      // Total damage: 1.15^5 = 2.01136
      expect(totalStats.towerDamageMult, closeTo(2.01136, 0.0001));
    });

    test('combined upgrades stack multiplicatively', () {
      const damageUpgrade = SimulatedUpgradeStats(towerDamageMult: 1.15);
      const critUpgrade = SimulatedUpgradeStats(towerDamageMult: 1.1);

      // Level 3 damage + level 2 crit
      final damage3 = damageUpgrade.scale(3); // 1.520875
      final crit2 = critUpgrade.scale(2); // 1.21

      final combined = damage3.merge(crit2);

      // 1.520875 * 1.21 = 1.8402
      expect(combined.towerDamageMult, closeTo(1.8402, 0.0001));
    });

    test('cost reduction builds stack correctly', () {
      const economyUpgrade = SimulatedUpgradeStats(towerCostMult: 0.92);

      final level5 = economyUpgrade.scale(5);

      // 0.92^5 = 0.6591
      expect(level5.towerCostMult, closeTo(0.6591, 0.0001));

      // This means towers cost ~66% of original (34% discount)
    });

    test('run upgrades with stacks', () {
      const powerUp = SimulatedRunUpgradeDefinition(
        id: 'power',
        name: 'Power Up',
        description: '+20% damage',
        stats: SimulatedUpgradeStats(towerDamageMult: 1.2),
        maxStacks: 3,
      );

      // Collect 3 power ups
      var total = const SimulatedUpgradeStats();
      for (int i = 0; i < powerUp.maxStacks; i++) {
        total = total.merge(powerUp.stats);
      }

      // 1.2^3 = 1.728
      expect(total.towerDamageMult, closeTo(1.728, 0.0001));
    });

    test('mixed permanent and run upgrades', () {
      // Permanent upgrades
      final permanentDamage = const SimulatedUpgradeStats(towerDamageMult: 1.15).scale(3);
      final permanentSpeed = const SimulatedUpgradeStats(projectileSpeedMult: 1.1).scale(2);

      // Run upgrades (2 stacks of damage boost)
      var runBoosts = const SimulatedUpgradeStats();
      const runDamageBoost = SimulatedUpgradeStats(towerDamageMult: 1.1);
      runBoosts = runBoosts.merge(runDamageBoost).merge(runDamageBoost);

      // Combine all
      final total = permanentDamage.merge(permanentSpeed).merge(runBoosts);

      // Damage: 1.15^3 * 1.1^2 = 1.520875 * 1.21 = 1.8403
      expect(total.towerDamageMult, closeTo(1.8403, 0.0001));

      // Speed: 1.1^2 = 1.21
      expect(total.projectileSpeedMult, closeTo(1.21, 0.0001));
    });
  });

  group('Edge Cases', () {
    test('merging many stats does not accumulate floating point errors significantly', () {
      const small = SimulatedUpgradeStats(towerDamageMult: 1.01);
      var result = const SimulatedUpgradeStats();

      for (int i = 0; i < 100; i++) {
        result = result.merge(small);
      }

      // 1.01^100 ≈ 2.7048
      expect(result.towerDamageMult, closeTo(2.7048, 0.01));
    });

    test('scale with large level works correctly', () {
      const stats = SimulatedUpgradeStats(towerDamageMult: 1.05);
      final scaled = stats.scale(20);

      // 1.05^20 ≈ 2.6533
      expect(scaled.towerDamageMult, closeTo(2.6533, 0.01));
    });

    test('zero multipliers stay zero when scaled', () {
      // Not typical but test edge case
      const stats = SimulatedUpgradeStats(towerDamageMult: 0.0);
      final scaled = stats.scale(3);

      expect(scaled.towerDamageMult, equals(0.0));
    });

    test('very small multiplier reductions', () {
      const stats = SimulatedUpgradeStats(towerCostMult: 0.99);
      final scaled = stats.scale(10);

      // 0.99^10 ≈ 0.9044
      expect(scaled.towerCostMult, closeTo(0.9044, 0.0001));
    });

    test('negative bonuses are allowed', () {
      const stats = SimulatedUpgradeStats(startingGoldBonus: -10);
      final scaled = stats.scale(3);

      expect(scaled.startingGoldBonus, equals(-30));
    });

    test('merge with all zeros', () {
      const zeros = SimulatedUpgradeStats(
        towerDamageMult: 0,
        towerRangeMult: 0,
        startingGoldBonus: 0,
      );
      const normal = SimulatedUpgradeStats(
        towerDamageMult: 1.5,
        towerRangeMult: 1.2,
        startingGoldBonus: 50,
      );

      final merged = normal.merge(zeros);

      expect(merged.towerDamageMult, equals(0.0));
      expect(merged.towerRangeMult, equals(0.0));
      expect(merged.startingGoldBonus, equals(50));
    });
  });

  group('Equality and HashCode', () {
    test('identical stats are equal', () {
      const stats1 = SimulatedUpgradeStats(
        towerDamageMult: 1.5,
        startingGoldBonus: 50,
      );
      const stats2 = SimulatedUpgradeStats(
        towerDamageMult: 1.5,
        startingGoldBonus: 50,
      );

      expect(stats1, equals(stats2));
      expect(stats1.hashCode, equals(stats2.hashCode));
    });

    test('different stats are not equal', () {
      const stats1 = SimulatedUpgradeStats(towerDamageMult: 1.5);
      const stats2 = SimulatedUpgradeStats(towerDamageMult: 1.6);

      expect(stats1, isNot(equals(stats2)));
    });

    test('default stats are equal', () {
      const stats1 = SimulatedUpgradeStats();
      const stats2 = SimulatedUpgradeStats();

      expect(stats1, equals(stats2));
    });
  });
}
