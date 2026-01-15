import 'dart:math' as math;

class DifficultyCurve {
  static const int levelsPerWorld = 10;

  static int worldForLevel(int levelId) =>
      ((levelId - 1) ~/ levelsPerWorld) + 1;

  static int localIndexForLevel(int levelId) =>
      ((levelId - 1) % levelsPerWorld) + 1;

  static int progressIndex({required int levelId}) {
    final world = worldForLevel(levelId);
    final local = localIndexForLevel(levelId);
    return (world - 1) * levelsPerWorld + (local - 1);
  }

  static double difficultyScale(int difficulty) {
    return 1 + (difficulty - 1) * 0.08;
  }

  static double healthMultiplier({
    required int progressIndexValue,
    required int wave,
    required int difficulty,
  }) {
    final earlyBoost = 0.18 * math.exp(-progressIndexValue / 12.0);
    final growth = 1.08 +
        earlyBoost +
        0.035 * progressIndexValue +
        0.03 * (wave - 1);
    final scaled = growth * difficultyScale(difficulty);
    return math.pow(scaled, 1.1).toDouble();
  }

  static double speedMultiplier({
    required int progressIndexValue,
    required int wave,
    required int difficulty,
  }) {
    final growth = 1 + 0.015 * progressIndexValue + 0.012 * (wave - 1);
    final diffScale = 1 + (difficulty - 1) * 0.05;
    return growth * diffScale;
  }

  static int enemyCount({
    required int baseCount,
    required int progressIndexValue,
    required int wave,
    required int difficulty,
    int minCount = 3,
    int maxCount = 160,
  }) {
    final base =
        baseCount + 0.8 * (wave - 1) + 0.4 * math.sqrt(progressIndexValue * 10.0);
    final diffScale = 1 + (difficulty - 1) * 0.08;
    return (base * diffScale).round().clamp(minCount, maxCount);
  }

  static double spawnInterval({
    required int progressIndexValue,
    required int wave,
    required int difficulty,
    double minInterval = 0.35,
    double maxInterval = 1.3,
  }) {
    final base = 1.0 / (1 + 0.024 * progressIndexValue + 0.035 * (wave - 1));
    final diffScale = 1 + (difficulty - 1) * 0.06;
    final interval = base / diffScale;
    return interval.clamp(minInterval, maxInterval);
  }

  static int startingGold({
    required int world,
    required int localIndex,
    int base = 130,
  }) {
    return (base + 10 * (world - 1) + 3 * (localIndex - 1)).round();
  }

  static double towerCostMultiplier(
    int towersPlaced, {
    int graceCount = 2,
    double step = 0.1,
  }) {
    final extra = math.max(0, towersPlaced - graceCount);
    return 1 + (extra * step);
  }

  static int waveClearBonus({
    required int progressIndexValue,
    required int wave,
    required int difficulty,
    int minBonus = 6,
    int maxBonus = 60,
  }) {
    final base = 12 + (wave * 3);
    final decay = (1 - 0.003 * progressIndexValue).clamp(0.7, 1.0);
    final diffScale = 1 + (difficulty - 1) * 0.05;
    return (base * decay / diffScale).round().clamp(minBonus, maxBonus);
  }
}
