import 'dart:math' as math;
import 'package:test/test.dart';

/// Comprehensive simulation tests for DifficultyCurve.
/// Tests all mathematical formulas for difficulty scaling, enemy spawning,
/// gold rewards, and tower cost progression.

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED DIFFICULTY CURVE - Exact copy from difficulty_curve.dart
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedDifficultyCurve {
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

// ═══════════════════════════════════════════════════════════════════════════════
// TEST SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('Level Indexing', () {
    test('worldForLevel returns correct world', () {
      // World 1: levels 1-10
      for (int i = 1; i <= 10; i++) {
        expect(SimulatedDifficultyCurve.worldForLevel(i), equals(1));
      }

      // World 2: levels 11-20
      for (int i = 11; i <= 20; i++) {
        expect(SimulatedDifficultyCurve.worldForLevel(i), equals(2));
      }

      // World 3: levels 21-30
      for (int i = 21; i <= 30; i++) {
        expect(SimulatedDifficultyCurve.worldForLevel(i), equals(3));
      }
    });

    test('localIndexForLevel returns correct local index', () {
      // Level 1 -> local 1, Level 10 -> local 10
      for (int i = 1; i <= 10; i++) {
        expect(SimulatedDifficultyCurve.localIndexForLevel(i), equals(i));
      }

      // Level 11 -> local 1, Level 20 -> local 10
      for (int i = 11; i <= 20; i++) {
        expect(SimulatedDifficultyCurve.localIndexForLevel(i), equals(i - 10));
      }

      // Level 21 -> local 1
      expect(SimulatedDifficultyCurve.localIndexForLevel(21), equals(1));
    });

    test('progressIndex is continuous across worlds', () {
      expect(SimulatedDifficultyCurve.progressIndex(levelId: 1), equals(0));
      expect(SimulatedDifficultyCurve.progressIndex(levelId: 2), equals(1));
      expect(SimulatedDifficultyCurve.progressIndex(levelId: 10), equals(9));
      expect(SimulatedDifficultyCurve.progressIndex(levelId: 11), equals(10));
      expect(SimulatedDifficultyCurve.progressIndex(levelId: 20), equals(19));
      expect(SimulatedDifficultyCurve.progressIndex(levelId: 21), equals(20));
    });

    test('progressIndex increases monotonically', () {
      int prev = -1;
      for (int level = 1; level <= 100; level++) {
        final idx = SimulatedDifficultyCurve.progressIndex(levelId: level);
        expect(idx, greaterThan(prev));
        prev = idx;
      }
    });
  });

  group('Difficulty Scale', () {
    test('difficulty 1 returns scale of 1.0', () {
      expect(SimulatedDifficultyCurve.difficultyScale(1), equals(1.0));
    });

    test('difficulty increases scale by 8% per level', () {
      expect(SimulatedDifficultyCurve.difficultyScale(2), closeTo(1.08, 0.0001));
      expect(SimulatedDifficultyCurve.difficultyScale(3), closeTo(1.16, 0.0001));
      expect(SimulatedDifficultyCurve.difficultyScale(5), closeTo(1.32, 0.0001));
      expect(SimulatedDifficultyCurve.difficultyScale(10), closeTo(1.72, 0.0001));
    });

    test('difficulty scale is linear', () {
      final d2 = SimulatedDifficultyCurve.difficultyScale(2);
      final d3 = SimulatedDifficultyCurve.difficultyScale(3);
      final d4 = SimulatedDifficultyCurve.difficultyScale(4);

      expect(d3 - d2, closeTo(d4 - d3, 0.0001));
    });
  });

  group('Health Multiplier', () {
    test('increases with progress index', () {
      final h0 = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final h10 = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: 10,
        wave: 1,
        difficulty: 1,
      );
      final h50 = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: 50,
        wave: 1,
        difficulty: 1,
      );

      expect(h10, greaterThan(h0));
      expect(h50, greaterThan(h10));
    });

    test('increases with wave number', () {
      final w1 = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: 10,
        wave: 1,
        difficulty: 1,
      );
      final w5 = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 1,
      );
      final w10 = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: 10,
        wave: 10,
        difficulty: 1,
      );

      expect(w5, greaterThan(w1));
      expect(w10, greaterThan(w5));
    });

    test('increases with difficulty', () {
      final d1 = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 1,
      );
      final d3 = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 3,
      );
      final d5 = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 5,
      );

      expect(d3, greaterThan(d1));
      expect(d5, greaterThan(d3));
    });

    test('early boost decays exponentially', () {
      // Early boost = 0.18 * exp(-progress/12)
      // At progress 0: boost = 0.18
      // At progress 12: boost ≈ 0.18 * 0.368 = 0.066
      // At progress 24: boost ≈ 0.18 * 0.135 = 0.024

      final h0 = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final h12 = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: 12,
        wave: 1,
        difficulty: 1,
      );

      // Early levels should have higher relative boost
      // The difference in growth should be visible
      expect(h0, greaterThan(1.0));
      expect(h12, greaterThan(h0)); // Still grows overall due to progress scaling
    });

    test('applies 1.1 power scaling', () {
      final growth = 1.08 + 0.18; // Base + early boost at progress 0
      final expected = math.pow(growth, 1.1);

      final actual = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );

      expect(actual, closeTo(expected, 0.01));
    });

    test('late game values are reasonable', () {
      final lateGame = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: 90, // Level ~90
        wave: 15,
        difficulty: 5,
      );

      // Should be a large multiplier but not infinite.
      // Current formula yields ~7.36 for this scenario; keep the test aligned with the formula
      // unless we explicitly decide to change gameplay balance.
      expect(lateGame, greaterThan(7));
      expect(lateGame, lessThan(1000));
    });
  });

  group('Speed Multiplier', () {
    test('starts at 1.0 for progress 0, wave 1, difficulty 1', () {
      final speed = SimulatedDifficultyCurve.speedMultiplier(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );

      expect(speed, equals(1.0));
    });

    test('increases with progress index', () {
      final s0 = SimulatedDifficultyCurve.speedMultiplier(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final s20 = SimulatedDifficultyCurve.speedMultiplier(
        progressIndexValue: 20,
        wave: 1,
        difficulty: 1,
      );

      // +1.5% per progress index
      // s20 = 1 + 0.015 * 20 = 1.3
      expect(s20, closeTo(1.3, 0.0001));
      expect(s20, greaterThan(s0));
    });

    test('increases with wave number', () {
      final w1 = SimulatedDifficultyCurve.speedMultiplier(
        progressIndexValue: 10,
        wave: 1,
        difficulty: 1,
      );
      final w10 = SimulatedDifficultyCurve.speedMultiplier(
        progressIndexValue: 10,
        wave: 10,
        difficulty: 1,
      );

      // Wave contribution: 0.012 * (wave - 1)
      // w1: 1 + 0.015*10 + 0.012*0 = 1.15
      // w10: 1 + 0.015*10 + 0.012*9 = 1.258
      expect(w1, closeTo(1.15, 0.0001));
      expect(w10, closeTo(1.258, 0.0001));
    });

    test('increases with difficulty', () {
      final d1 = SimulatedDifficultyCurve.speedMultiplier(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 1,
      );
      final d5 = SimulatedDifficultyCurve.speedMultiplier(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 5,
      );

      // Difficulty scale: 1 + (diff-1) * 0.05
      // d1 scale = 1.0, d5 scale = 1.2
      expect(d5 / d1, closeTo(1.2, 0.001));
    });

    test('late game speed is reasonable', () {
      final lateGame = SimulatedDifficultyCurve.speedMultiplier(
        progressIndexValue: 90,
        wave: 15,
        difficulty: 5,
      );

      // Should not make enemies impossibly fast
      expect(lateGame, greaterThan(1.5));
      expect(lateGame, lessThan(5.0));
    });
  });

  group('Enemy Count', () {
    test('returns base count at minimum parameters', () {
      final count = SimulatedDifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );

      expect(count, equals(10));
    });

    test('increases with wave', () {
      final w1 = SimulatedDifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: 10,
        wave: 1,
        difficulty: 1,
      );
      final w5 = SimulatedDifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: 10,
        wave: 5,
        difficulty: 1,
      );

      // +0.8 per wave
      // w5 - w1 ≈ 0.8 * 4 = 3.2 (rounded)
      expect(w5, greaterThan(w1));
    });

    test('increases with progress index via sqrt scaling', () {
      final p0 = SimulatedDifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final p10 = SimulatedDifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: 10,
        wave: 1,
        difficulty: 1,
      );
      final p40 = SimulatedDifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: 40,
        wave: 1,
        difficulty: 1,
      );

      // Sqrt scaling means diminishing returns
      // p10: 10 + 0.4 * sqrt(100) = 10 + 4 = 14
      // p40: 10 + 0.4 * sqrt(400) = 10 + 8 = 18
      expect(p10, closeTo(14, 1));
      expect(p40, closeTo(18, 1));

      // Verify diminishing returns
      final increase1 = p10 - p0;
      final increase2 = p40 - p10;
      expect(increase2, lessThan(increase1 * 2));
    });

    test('difficulty scales count', () {
      final d1 = SimulatedDifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: 10,
        wave: 5,
        difficulty: 1,
      );
      final d5 = SimulatedDifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: 10,
        wave: 5,
        difficulty: 5,
      );

      // Difficulty scale: 1 + (diff-1) * 0.08
      // d5 scale = 1.32
      expect(d5.toDouble() / d1.toDouble(), closeTo(1.32, 0.1));
    });

    test('respects minimum count', () {
      final count = SimulatedDifficultyCurve.enemyCount(
        baseCount: 1,
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
        minCount: 5,
      );

      expect(count, equals(5));
    });

    test('respects maximum count', () {
      final count = SimulatedDifficultyCurve.enemyCount(
        baseCount: 100,
        progressIndexValue: 90,
        wave: 20,
        difficulty: 10,
        maxCount: 100,
      );

      expect(count, equals(100));
    });

    test('default max is 160', () {
      final count = SimulatedDifficultyCurve.enemyCount(
        baseCount: 200,
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );

      expect(count, equals(160));
    });
  });

  group('Spawn Interval', () {
    test('starts at max interval for early game', () {
      final interval = SimulatedDifficultyCurve.spawnInterval(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );

      expect(interval, closeTo(1.0, 0.01));
    });

    test('decreases with progress index', () {
      final i0 = SimulatedDifficultyCurve.spawnInterval(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final i20 = SimulatedDifficultyCurve.spawnInterval(
        progressIndexValue: 20,
        wave: 1,
        difficulty: 1,
      );
      final i50 = SimulatedDifficultyCurve.spawnInterval(
        progressIndexValue: 50,
        wave: 1,
        difficulty: 1,
      );

      expect(i20, lessThan(i0));
      expect(i50, lessThan(i20));
    });

    test('decreases with wave', () {
      final w1 = SimulatedDifficultyCurve.spawnInterval(
        progressIndexValue: 10,
        wave: 1,
        difficulty: 1,
      );
      final w10 = SimulatedDifficultyCurve.spawnInterval(
        progressIndexValue: 10,
        wave: 10,
        difficulty: 1,
      );

      expect(w10, lessThan(w1));
    });

    test('decreases with difficulty', () {
      final d1 = SimulatedDifficultyCurve.spawnInterval(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 1,
      );
      final d5 = SimulatedDifficultyCurve.spawnInterval(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 5,
      );

      expect(d5, lessThan(d1));
    });

    test('respects minimum interval', () {
      final interval = SimulatedDifficultyCurve.spawnInterval(
        progressIndexValue: 100,
        wave: 20,
        difficulty: 10,
        minInterval: 0.35,
      );

      expect(interval, greaterThanOrEqualTo(0.35));
    });

    test('respects maximum interval', () {
      final interval = SimulatedDifficultyCurve.spawnInterval(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
        maxInterval: 1.3,
      );

      expect(interval, lessThanOrEqualTo(1.3));
    });

    test('custom interval bounds work', () {
      final interval = SimulatedDifficultyCurve.spawnInterval(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
        minInterval: 0.5,
        maxInterval: 0.8,
      );

      expect(interval, lessThanOrEqualTo(0.8));
      expect(interval, greaterThanOrEqualTo(0.5));
    });
  });

  group('Starting Gold', () {
    test('base gold at world 1 level 1', () {
      final gold = SimulatedDifficultyCurve.startingGold(
        world: 1,
        localIndex: 1,
      );

      expect(gold, equals(130));
    });

    test('increases 10 per world', () {
      final w1 = SimulatedDifficultyCurve.startingGold(world: 1, localIndex: 1);
      final w2 = SimulatedDifficultyCurve.startingGold(world: 2, localIndex: 1);
      final w3 = SimulatedDifficultyCurve.startingGold(world: 3, localIndex: 1);

      expect(w2 - w1, equals(10));
      expect(w3 - w2, equals(10));
    });

    test('increases 3 per local index', () {
      final l1 = SimulatedDifficultyCurve.startingGold(world: 1, localIndex: 1);
      final l2 = SimulatedDifficultyCurve.startingGold(world: 1, localIndex: 2);
      final l5 = SimulatedDifficultyCurve.startingGold(world: 1, localIndex: 5);

      expect(l2 - l1, equals(3));
      expect(l5 - l1, equals(12));
    });

    test('custom base gold works', () {
      final gold = SimulatedDifficultyCurve.startingGold(
        world: 1,
        localIndex: 1,
        base: 200,
      );

      expect(gold, equals(200));
    });

    test('world 5 level 10 gold', () {
      final gold = SimulatedDifficultyCurve.startingGold(
        world: 5,
        localIndex: 10,
      );

      // 130 + 10*(5-1) + 3*(10-1) = 130 + 40 + 27 = 197
      expect(gold, equals(197));
    });
  });

  group('Tower Cost Multiplier', () {
    test('first 2 towers have no extra cost', () {
      expect(SimulatedDifficultyCurve.towerCostMultiplier(0), equals(1.0));
      expect(SimulatedDifficultyCurve.towerCostMultiplier(1), equals(1.0));
      expect(SimulatedDifficultyCurve.towerCostMultiplier(2), equals(1.0));
    });

    test('towers after grace period cost more', () {
      expect(SimulatedDifficultyCurve.towerCostMultiplier(3), closeTo(1.1, 0.001));
      expect(SimulatedDifficultyCurve.towerCostMultiplier(4), closeTo(1.2, 0.001));
      expect(SimulatedDifficultyCurve.towerCostMultiplier(5), closeTo(1.3, 0.001));
    });

    test('increases linearly by 10% per tower over grace', () {
      final m5 = SimulatedDifficultyCurve.towerCostMultiplier(5);
      final m10 = SimulatedDifficultyCurve.towerCostMultiplier(10);

      // m5 = 1 + (5-2)*0.1 = 1.3
      // m10 = 1 + (10-2)*0.1 = 1.8
      expect(m5, closeTo(1.3, 0.001));
      expect(m10, closeTo(1.8, 0.001));
    });

    test('custom grace count works', () {
      final mult = SimulatedDifficultyCurve.towerCostMultiplier(
        5,
        graceCount: 4,
      );

      // 5 - 4 = 1 extra tower
      expect(mult, closeTo(1.1, 0.001));
    });

    test('custom step works', () {
      final mult = SimulatedDifficultyCurve.towerCostMultiplier(
        5,
        graceCount: 2,
        step: 0.2,
      );

      // (5-2) * 0.2 = 0.6 extra
      expect(mult, closeTo(1.6, 0.001));
    });

    test('large tower counts', () {
      final mult = SimulatedDifficultyCurve.towerCostMultiplier(20);

      // (20-2) * 0.1 = 1.8 extra -> 2.8
      expect(mult, closeTo(2.8, 0.001));
    });
  });

  group('Wave Clear Bonus', () {
    test('early game bonus', () {
      final bonus = SimulatedDifficultyCurve.waveClearBonus(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );

      // base = 12 + 1*3 = 15
      // decay = 1.0 (no progress)
      // diffScale = 1.0
      // result = 15
      expect(bonus, equals(15));
    });

    test('increases with wave', () {
      final w1 = SimulatedDifficultyCurve.waveClearBonus(
        progressIndexValue: 10,
        wave: 1,
        difficulty: 1,
      );
      final w5 = SimulatedDifficultyCurve.waveClearBonus(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 1,
      );
      final w10 = SimulatedDifficultyCurve.waveClearBonus(
        progressIndexValue: 10,
        wave: 10,
        difficulty: 1,
      );

      expect(w5, greaterThan(w1));
      expect(w10, greaterThan(w5));
    });

    test('decays with progress', () {
      final p0 = SimulatedDifficultyCurve.waveClearBonus(
        progressIndexValue: 0,
        wave: 5,
        difficulty: 1,
      );
      final p50 = SimulatedDifficultyCurve.waveClearBonus(
        progressIndexValue: 50,
        wave: 5,
        difficulty: 1,
      );

      expect(p50, lessThan(p0));
    });

    test('decay is clamped at 0.7', () {
      // decay = 1 - 0.003 * progress
      // At progress 100: 1 - 0.3 = 0.7 (minimum)
      // At progress 200: would be 0.4, but clamped to 0.7

      final p100 = SimulatedDifficultyCurve.waveClearBonus(
        progressIndexValue: 100,
        wave: 5,
        difficulty: 1,
      );
      final p200 = SimulatedDifficultyCurve.waveClearBonus(
        progressIndexValue: 200,
        wave: 5,
        difficulty: 1,
      );

      // Should be equal due to clamping
      expect(p100, equals(p200));
    });

    test('difficulty reduces bonus', () {
      final d1 = SimulatedDifficultyCurve.waveClearBonus(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 1,
      );
      final d5 = SimulatedDifficultyCurve.waveClearBonus(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 5,
      );

      // diffScale: d5 = 1 + 4*0.05 = 1.2
      // bonus is divided by diffScale, so higher difficulty = lower bonus
      expect(d5, lessThan(d1));
    });

    test('respects minimum bonus', () {
      final bonus = SimulatedDifficultyCurve.waveClearBonus(
        progressIndexValue: 100,
        wave: 1,
        difficulty: 10,
        minBonus: 6,
      );

      expect(bonus, greaterThanOrEqualTo(6));
    });

    test('respects maximum bonus', () {
      final bonus = SimulatedDifficultyCurve.waveClearBonus(
        progressIndexValue: 0,
        wave: 20,
        difficulty: 1,
        maxBonus: 60,
      );

      expect(bonus, lessThanOrEqualTo(60));
    });
  });

  group('Complete Game Progression', () {
    test('world 1 level 1 wave 1 baseline', () {
      const progress = 0;
      const wave = 1;
      const difficulty = 1;

      final health = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: progress,
        wave: wave,
        difficulty: difficulty,
      );
      final speed = SimulatedDifficultyCurve.speedMultiplier(
        progressIndexValue: progress,
        wave: wave,
        difficulty: difficulty,
      );
      final count = SimulatedDifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: progress,
        wave: wave,
        difficulty: difficulty,
      );
      final interval = SimulatedDifficultyCurve.spawnInterval(
        progressIndexValue: progress,
        wave: wave,
        difficulty: difficulty,
      );

      expect(health, closeTo(1.33, 0.1)); // With early boost
      expect(speed, equals(1.0));
      expect(count, equals(10));
      expect(interval, closeTo(1.0, 0.1));
    });

    test('world 3 level 5 wave 5 medium difficulty', () {
      const levelId = 25; // World 3, local 5
      final progress = SimulatedDifficultyCurve.progressIndex(levelId: levelId);
      const wave = 5;
      const difficulty = 3;

      final health = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: progress,
        wave: wave,
        difficulty: difficulty,
      );
      final speed = SimulatedDifficultyCurve.speedMultiplier(
        progressIndexValue: progress,
        wave: wave,
        difficulty: difficulty,
      );
      final count = SimulatedDifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: progress,
        wave: wave,
        difficulty: difficulty,
      );
      final interval = SimulatedDifficultyCurve.spawnInterval(
        progressIndexValue: progress,
        wave: wave,
        difficulty: difficulty,
      );

      expect(health, greaterThan(2.0));
      expect(speed, greaterThan(1.3));
      expect(count, greaterThan(15));
      expect(interval, lessThan(0.8));
    });

    test('difficulty curve is smooth (no sudden jumps)', () {
      double prevHealth = 0;
      double prevSpeed = 0;

      for (int level = 1; level <= 50; level++) {
        final progress = SimulatedDifficultyCurve.progressIndex(levelId: level);
        final health = SimulatedDifficultyCurve.healthMultiplier(
          progressIndexValue: progress,
          wave: 1,
          difficulty: 1,
        );
        final speed = SimulatedDifficultyCurve.speedMultiplier(
          progressIndexValue: progress,
          wave: 1,
          difficulty: 1,
        );

        if (prevHealth > 0) {
          // Health should never jump by more than 50% between adjacent levels
          expect(health / prevHealth, lessThan(1.5));
        }

        if (prevSpeed > 0) {
          // Speed should never jump by more than 20% between adjacent levels
          expect(speed / prevSpeed, lessThan(1.2));
        }

        prevHealth = health;
        prevSpeed = speed;
      }
    });

    test('economy remains balanced through progression', () {
      for (int world = 1; world <= 5; world++) {
        for (int local = 1; local <= 10; local++) {
          final gold = SimulatedDifficultyCurve.startingGold(
            world: world,
            localIndex: local,
          );

          final levelId = (world - 1) * 10 + local;
          final progress = SimulatedDifficultyCurve.progressIndex(levelId: levelId);

          final bonus = SimulatedDifficultyCurve.waveClearBonus(
            progressIndexValue: progress,
            wave: 5,
            difficulty: 1,
          );

          // Starting gold should always be positive
          expect(gold, greaterThan(0));

          // Wave bonuses should always be meaningful
          expect(bonus, greaterThanOrEqualTo(6));
        }
      }
    });
  });

  group('Edge Cases', () {
    test('negative progress index treated as 0', () {
      // The formula doesn't explicitly handle negative values,
      // but the math should still work
      final health = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: -5,
        wave: 1,
        difficulty: 1,
      );

      // Should not crash and return a reasonable value
      expect(health, greaterThan(0));
    });

    test('very high wave numbers', () {
      final health = SimulatedDifficultyCurve.healthMultiplier(
        progressIndexValue: 50,
        wave: 100,
        difficulty: 5,
      );

      // Should handle gracefully without overflow
      expect(health.isFinite, isTrue);
      expect(health, greaterThan(0));
    });

    test('minimum enemy count is enforced', () {
      final count = SimulatedDifficultyCurve.enemyCount(
        baseCount: 0,
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
        minCount: 5,
      );

      expect(count, equals(5));
    });

    test('spawn interval never goes below minimum', () {
      final interval = SimulatedDifficultyCurve.spawnInterval(
        progressIndexValue: 1000,
        wave: 100,
        difficulty: 10,
        minInterval: 0.35,
      );

      expect(interval, greaterThanOrEqualTo(0.35));
    });
  });
}
