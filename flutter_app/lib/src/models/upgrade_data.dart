import 'dart:math' as math;

class UpgradeStats {
  const UpgradeStats({
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

  UpgradeStats merge(UpgradeStats other) {
    return UpgradeStats(
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
  static double _intPow(double base, int exp) {
    if (exp <= 0) return 1.0;
    if (exp == 1) return base;
    double result = base;
    for (int i = 1; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  UpgradeStats scale(int level) {
    if (level <= 0) return const UpgradeStats();
    return UpgradeStats(
      towerDamageMult: _intPow(towerDamageMult, level),
      towerRangeMult: _intPow(towerRangeMult, level),
      towerFireRateMult: _intPow(towerFireRateMult, level),
      projectileSpeedMult: _intPow(projectileSpeedMult, level),
      slowMult: _intPow(slowMult, level),
      goldGainMult: _intPow(goldGainMult, level),
      towerCostMult: _intPow(towerCostMult, level),
      pulseCooldownMult: _intPow(pulseCooldownMult, level),
      mineCooldownMult: _intPow(mineCooldownMult, level),
      abilityCostMult: _intPow(abilityCostMult, level),
      startingGoldBonus: startingGoldBonus * level,
      startingLivesBonus: startingLivesBonus * level,
      maxMinesBonus: maxMinesBonus * level,
    );
  }
}

class UpgradeDefinition {
  const UpgradeDefinition({
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
  final UpgradeStats perLevel;

  int costForLevel(int level) => baseCost + (costStep * level);

  UpgradeStats statsForLevel(int level) => perLevel.scale(level);
}

class RunUpgradeDefinition {
  const RunUpgradeDefinition({
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
  final UpgradeStats stats;
  final int maxStacks;
  final int instantGold;
  final int instantLives;
}
