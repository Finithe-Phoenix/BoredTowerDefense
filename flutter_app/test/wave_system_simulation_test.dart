import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

/// Simulation tests for wave system and difficulty curve logic.
/// Tests enemy count scaling, health/speed multipliers, spawn intervals,
/// and wave modifier selection without requiring game context.

// ═══════════════════════════════════════════════════════════════════════════════
// DIFFICULTY CURVE SIMULATION
// ═══════════════════════════════════════════════════════════════════════════════

class DifficultyCurveSimulator {
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
// WAVE MODIFIER SIMULATION
// ═══════════════════════════════════════════════════════════════════════════════

enum SimulatedWaveModifier {
  normal,
  overload,
  juggernaut,
  mixed,
  phantom,
}

class WaveModifierSimulator {
  static SimulatedWaveModifier selectModifier({
    required int wave,
    required int world,
    required int availableTypes,
    required bool hasPhantom,
  }) {
    final hasEnoughTypes = availableTypes >= 2;

    if (world <= 1) {
      // World 1: Progressive introduction
      if (wave % 5 == 0 && availableTypes >= 3) return SimulatedWaveModifier.juggernaut;
      if (wave % 3 == 0 && availableTypes >= 2) return SimulatedWaveModifier.overload;
      return SimulatedWaveModifier.normal;
    }

    if (world == 2) {
      // World 2: Rift Wars - Phantom heavy
      if (wave % 6 == 0 && hasPhantom) return SimulatedWaveModifier.phantom;
      if (wave % 5 == 0 && hasEnoughTypes) return SimulatedWaveModifier.juggernaut;
      if (wave % 3 == 0 && hasEnoughTypes) return SimulatedWaveModifier.overload;
      return SimulatedWaveModifier.normal;
    }

    if (world == 3) {
      // World 3: Signal Wastes - Mixed corruption
      if (wave % 7 == 0 && availableTypes >= 3) return SimulatedWaveModifier.mixed;
      if (wave % 4 == 0 && hasPhantom) return SimulatedWaveModifier.phantom;
      if (wave % 5 == 0 && hasEnoughTypes) return SimulatedWaveModifier.juggernaut;
      if (wave % 3 == 0 && hasEnoughTypes) return SimulatedWaveModifier.overload;
      return SimulatedWaveModifier.normal;
    }

    // Worlds 4-10: Full variety
    if (wave % 8 == 0 && availableTypes >= 3) return SimulatedWaveModifier.mixed;
    if (wave % 6 == 0 && hasPhantom) return SimulatedWaveModifier.phantom;
    if (wave % 5 == 0 && hasEnoughTypes) return SimulatedWaveModifier.juggernaut;
    if (wave % 3 == 0 && hasEnoughTypes) return SimulatedWaveModifier.overload;
    return SimulatedWaveModifier.normal;
  }

  static int modifyEnemyCount({
    required int baseCount,
    required SimulatedWaveModifier modifier,
    int maxCount = 80,
  }) {
    int count;
    switch (modifier) {
      case SimulatedWaveModifier.overload:
        count = (baseCount * 1.25).ceil();
        break;
      case SimulatedWaveModifier.juggernaut:
        count = (baseCount * 0.7).ceil().clamp(2, maxCount);
        break;
      case SimulatedWaveModifier.phantom:
        count = (baseCount * 0.85).ceil().clamp(3, maxCount);
        break;
      case SimulatedWaveModifier.mixed:
        count = (baseCount * 1.1).ceil();
        break;
      case SimulatedWaveModifier.normal:
        count = baseCount;
        break;
    }
    return count.clamp(3, maxCount);
  }

  static double modifySpawnInterval({
    required double baseInterval,
    required SimulatedWaveModifier modifier,
  }) {
    double interval;
    switch (modifier) {
      case SimulatedWaveModifier.overload:
        interval = baseInterval * 0.8;
        break;
      case SimulatedWaveModifier.juggernaut:
        interval = baseInterval * 1.15;
        break;
      case SimulatedWaveModifier.phantom:
        interval = baseInterval * 1.05;
        break;
      default:
        interval = baseInterval;
    }
    return interval.clamp(0.35, 1.6);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// THREAT TIER SIMULATION
// ═══════════════════════════════════════════════════════════════════════════════

class ThreatTierSimulator {
  static int baseThreatTier({
    required int currentWave,
    required int levelWorld,
  }) {
    int tier = 0;
    if (currentWave >= 4 || levelWorld >= 2) tier = 1;
    if (currentWave >= 8 || levelWorld >= 4) tier = 2;
    if (currentWave >= 12 || levelWorld >= 7) tier = 3;
    return tier;
  }

  static int resolveThreatTier({
    required int currentWave,
    required int levelWorld,
    required SimulatedWaveModifier modifier,
    required int spawnIndex,
  }) {
    var tier = baseThreatTier(currentWave: currentWave, levelWorld: levelWorld);

    if (modifier == SimulatedWaveModifier.juggernaut ||
        modifier == SimulatedWaveModifier.overload) {
      tier = math.max(tier, 1);
    }

    if (tier <= 0) return 0;

    final interval = switch (tier) {
      1 => 6,
      2 => 4,
      _ => 3,
    };

    if (spawnIndex % interval != 0) {
      tier = math.max(0, tier - 1);
    }

    return tier;
  }

  static int adjustGoldForThreatTier({
    required int baseGold,
    required int threatTier,
    int minGold = 4,
    int maxGold = 9999,
  }) {
    return (baseGold * (1 + threatTier * 0.18)).round().clamp(minGold, maxGold);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GOLD SCALE SIMULATION
// ═══════════════════════════════════════════════════════════════════════════════

class GoldScaleSimulator {
  static double goldScaleForProgress({
    required int levelWorld,
    required int localIndex,
    required int difficulty,
  }) {
    final scale = 0.92 -
        (levelWorld - 1) * 0.03 -
        (localIndex - 1) * 0.006 -
        (difficulty - 1) * 0.02;
    return scale.clamp(0.55, 0.95);
  }

  static int calculateScaledGold({
    required int baseGold,
    required int currentWave,
    required int levelWorld,
    required int localIndex,
    required int difficulty,
    int minGold = 4,
    int maxGold = 9999,
  }) {
    final scale = goldScaleForProgress(
      levelWorld: levelWorld,
      localIndex: localIndex,
      difficulty: difficulty,
    );
    return ((baseGold + (currentWave * 2)) * scale).round().clamp(minGold, maxGold);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEST SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('DifficultyCurveSimulator - World/Level Calculations', () {
    test('worldForLevel returns correct world for level 1-10', () {
      for (int level = 1; level <= 10; level++) {
        expect(DifficultyCurveSimulator.worldForLevel(level), 1);
      }
    });

    test('worldForLevel returns correct world for level 11-20', () {
      for (int level = 11; level <= 20; level++) {
        expect(DifficultyCurveSimulator.worldForLevel(level), 2);
      }
    });

    test('worldForLevel returns correct world for level 91-100', () {
      for (int level = 91; level <= 100; level++) {
        expect(DifficultyCurveSimulator.worldForLevel(level), 10);
      }
    });

    test('localIndexForLevel returns 1-10 cycling pattern', () {
      expect(DifficultyCurveSimulator.localIndexForLevel(1), 1);
      expect(DifficultyCurveSimulator.localIndexForLevel(10), 10);
      expect(DifficultyCurveSimulator.localIndexForLevel(11), 1);
      expect(DifficultyCurveSimulator.localIndexForLevel(20), 10);
    });

    test('progressIndex is continuous across worlds', () {
      expect(DifficultyCurveSimulator.progressIndex(levelId: 1), 0);
      expect(DifficultyCurveSimulator.progressIndex(levelId: 10), 9);
      expect(DifficultyCurveSimulator.progressIndex(levelId: 11), 10);
      expect(DifficultyCurveSimulator.progressIndex(levelId: 100), 99);
    });

    test('progressIndex formula is correct', () {
      for (int level = 1; level <= 100; level++) {
        final world = DifficultyCurveSimulator.worldForLevel(level);
        final local = DifficultyCurveSimulator.localIndexForLevel(level);
        final progress = DifficultyCurveSimulator.progressIndex(levelId: level);
        expect(progress, (world - 1) * 10 + (local - 1));
      }
    });
  });

  group('DifficultyCurveSimulator - Difficulty Scale', () {
    test('difficulty 1 has scale 1.0', () {
      expect(DifficultyCurveSimulator.difficultyScale(1), 1.0);
    });

    test('difficulty increases scale by 0.08 per level', () {
      expect(DifficultyCurveSimulator.difficultyScale(2), closeTo(1.08, 0.001));
      expect(DifficultyCurveSimulator.difficultyScale(3), closeTo(1.16, 0.001));
      expect(DifficultyCurveSimulator.difficultyScale(5), closeTo(1.32, 0.001));
    });
  });

  group('DifficultyCurveSimulator - Health Multiplier', () {
    test('health multiplier increases with progress', () {
      final health1 = DifficultyCurveSimulator.healthMultiplier(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final health50 = DifficultyCurveSimulator.healthMultiplier(
        progressIndexValue: 50,
        wave: 1,
        difficulty: 1,
      );

      expect(health50, greaterThan(health1));
    });

    test('health multiplier increases with wave', () {
      final health1 = DifficultyCurveSimulator.healthMultiplier(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final health10 = DifficultyCurveSimulator.healthMultiplier(
        progressIndexValue: 0,
        wave: 10,
        difficulty: 1,
      );

      expect(health10, greaterThan(health1));
    });

    test('health multiplier increases with difficulty', () {
      final healthEasy = DifficultyCurveSimulator.healthMultiplier(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 1,
      );
      final healthHard = DifficultyCurveSimulator.healthMultiplier(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 5,
      );

      expect(healthHard, greaterThan(healthEasy));
    });

    test('early boost decays with progress', () {
      final earlyBoost0 = 0.18 * math.exp(-0 / 12.0);
      final earlyBoost24 = 0.18 * math.exp(-24 / 12.0);
      final earlyBoost50 = 0.18 * math.exp(-50 / 12.0);

      expect(earlyBoost0, closeTo(0.18, 0.001));
      expect(earlyBoost24, lessThan(earlyBoost0));
      expect(earlyBoost50, lessThan(earlyBoost24));
    });

    test('health multiplier is always positive', () {
      for (int progress = 0; progress <= 100; progress += 10) {
        for (int wave = 1; wave <= 20; wave += 5) {
          final health = DifficultyCurveSimulator.healthMultiplier(
            progressIndexValue: progress,
            wave: wave,
            difficulty: 3,
          );
          expect(health, greaterThan(0));
        }
      }
    });
  });

  group('DifficultyCurveSimulator - Speed Multiplier', () {
    test('speed multiplier increases with progress', () {
      final speed1 = DifficultyCurveSimulator.speedMultiplier(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final speed50 = DifficultyCurveSimulator.speedMultiplier(
        progressIndexValue: 50,
        wave: 1,
        difficulty: 1,
      );

      expect(speed50, greaterThan(speed1));
    });

    test('speed multiplier increases with wave', () {
      final speed1 = DifficultyCurveSimulator.speedMultiplier(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final speed10 = DifficultyCurveSimulator.speedMultiplier(
        progressIndexValue: 0,
        wave: 10,
        difficulty: 1,
      );

      expect(speed10, greaterThan(speed1));
    });

    test('speed growth rate is 0.015 per progress + 0.012 per wave', () {
      final base = 1 + 0.015 * 10 + 0.012 * 5; // progress=10, wave=6
      final speed = DifficultyCurveSimulator.speedMultiplier(
        progressIndexValue: 10,
        wave: 6,
        difficulty: 1,
      );

      expect(speed, closeTo(base, 0.001));
    });

    test('difficulty increases speed by 0.05 per level', () {
      final speedDiff1 = DifficultyCurveSimulator.speedMultiplier(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 1,
      );
      final speedDiff2 = DifficultyCurveSimulator.speedMultiplier(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 2,
      );

      expect(speedDiff2 / speedDiff1, closeTo(1.05, 0.001));
    });
  });

  group('DifficultyCurveSimulator - Enemy Count', () {
    test('enemy count increases with wave', () {
      final count1 = DifficultyCurveSimulator.enemyCount(
        baseCount: 5,
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final count10 = DifficultyCurveSimulator.enemyCount(
        baseCount: 5,
        progressIndexValue: 0,
        wave: 10,
        difficulty: 1,
      );

      expect(count10, greaterThan(count1));
    });

    test('enemy count increases with progress via sqrt scaling', () {
      final count0 = DifficultyCurveSimulator.enemyCount(
        baseCount: 5,
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final count90 = DifficultyCurveSimulator.enemyCount(
        baseCount: 5,
        progressIndexValue: 90,
        wave: 1,
        difficulty: 1,
      );

      expect(count90, greaterThan(count0));
    });

    test('enemy count respects min and max bounds', () {
      final countMin = DifficultyCurveSimulator.enemyCount(
        baseCount: 1,
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
        minCount: 3,
        maxCount: 160,
      );

      final countMax = DifficultyCurveSimulator.enemyCount(
        baseCount: 200,
        progressIndexValue: 99,
        wave: 20,
        difficulty: 5,
        minCount: 3,
        maxCount: 160,
      );

      expect(countMin, greaterThanOrEqualTo(3));
      expect(countMax, lessThanOrEqualTo(160));
    });

    test('wave growth rate is 0.8 per wave', () {
      final count1 = DifficultyCurveSimulator.enemyCount(
        baseCount: 5,
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final count2 = DifficultyCurveSimulator.enemyCount(
        baseCount: 5,
        progressIndexValue: 0,
        wave: 2,
        difficulty: 1,
      );

      // Difference should be close to 0.8 (rounded)
      expect(count2 - count1, inInclusiveRange(0, 2));
    });
  });

  group('DifficultyCurveSimulator - Spawn Interval', () {
    test('spawn interval decreases with progress', () {
      final interval0 = DifficultyCurveSimulator.spawnInterval(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final interval50 = DifficultyCurveSimulator.spawnInterval(
        progressIndexValue: 50,
        wave: 1,
        difficulty: 1,
      );

      expect(interval50, lessThan(interval0));
    });

    test('spawn interval decreases with wave', () {
      final interval1 = DifficultyCurveSimulator.spawnInterval(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final interval10 = DifficultyCurveSimulator.spawnInterval(
        progressIndexValue: 0,
        wave: 10,
        difficulty: 1,
      );

      expect(interval10, lessThan(interval1));
    });

    test('spawn interval respects min and max bounds', () {
      final intervalMin = DifficultyCurveSimulator.spawnInterval(
        progressIndexValue: 99,
        wave: 20,
        difficulty: 5,
      );
      final intervalMax = DifficultyCurveSimulator.spawnInterval(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );

      expect(intervalMin, greaterThanOrEqualTo(0.35));
      expect(intervalMax, lessThanOrEqualTo(1.3));
    });
  });

  group('DifficultyCurveSimulator - Starting Gold', () {
    test('starting gold increases with world', () {
      final gold1 = DifficultyCurveSimulator.startingGold(world: 1, localIndex: 1);
      final gold5 = DifficultyCurveSimulator.startingGold(world: 5, localIndex: 1);

      expect(gold5, greaterThan(gold1));
      expect(gold5 - gold1, 40); // 10 * 4 worlds
    });

    test('starting gold increases with local index', () {
      final gold1 = DifficultyCurveSimulator.startingGold(world: 1, localIndex: 1);
      final gold10 = DifficultyCurveSimulator.startingGold(world: 1, localIndex: 10);

      expect(gold10, greaterThan(gold1));
      expect(gold10 - gold1, 27); // 3 * 9 levels
    });

    test('base starting gold is 130', () {
      expect(DifficultyCurveSimulator.startingGold(world: 1, localIndex: 1), 130);
    });
  });

  group('DifficultyCurveSimulator - Tower Cost Multiplier', () {
    test('no multiplier for first 2 towers (grace count)', () {
      expect(DifficultyCurveSimulator.towerCostMultiplier(0), 1.0);
      expect(DifficultyCurveSimulator.towerCostMultiplier(1), 1.0);
      expect(DifficultyCurveSimulator.towerCostMultiplier(2), 1.0);
    });

    test('multiplier increases by 0.1 after grace count', () {
      expect(DifficultyCurveSimulator.towerCostMultiplier(3), closeTo(1.1, 0.001));
      expect(DifficultyCurveSimulator.towerCostMultiplier(4), closeTo(1.2, 0.001));
      expect(DifficultyCurveSimulator.towerCostMultiplier(5), closeTo(1.3, 0.001));
    });

    test('custom grace count and step work', () {
      expect(DifficultyCurveSimulator.towerCostMultiplier(5, graceCount: 3, step: 0.2), closeTo(1.4, 0.001));
    });
  });

  group('DifficultyCurveSimulator - Wave Clear Bonus', () {
    test('bonus increases with wave', () {
      final bonus1 = DifficultyCurveSimulator.waveClearBonus(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final bonus10 = DifficultyCurveSimulator.waveClearBonus(
        progressIndexValue: 0,
        wave: 10,
        difficulty: 1,
      );

      expect(bonus10, greaterThan(bonus1));
    });

    test('bonus decays with progress', () {
      final bonus0 = DifficultyCurveSimulator.waveClearBonus(
        progressIndexValue: 0,
        wave: 5,
        difficulty: 1,
      );
      final bonus90 = DifficultyCurveSimulator.waveClearBonus(
        progressIndexValue: 90,
        wave: 5,
        difficulty: 1,
      );

      expect(bonus90, lessThanOrEqualTo(bonus0));
    });

    test('bonus respects min and max bounds', () {
      final bonusMin = DifficultyCurveSimulator.waveClearBonus(
        progressIndexValue: 99,
        wave: 1,
        difficulty: 5,
      );
      final bonusMax = DifficultyCurveSimulator.waveClearBonus(
        progressIndexValue: 0,
        wave: 20,
        difficulty: 1,
      );

      expect(bonusMin, greaterThanOrEqualTo(6));
      expect(bonusMax, lessThanOrEqualTo(60));
    });
  });

  group('WaveModifierSimulator - Selection Logic', () {
    test('world 1 uses juggernaut every 5 waves', () {
      for (int wave = 5; wave <= 20; wave += 5) {
        final modifier = WaveModifierSimulator.selectModifier(
          wave: wave,
          world: 1,
          availableTypes: 4,
          hasPhantom: false,
        );
        expect(modifier, SimulatedWaveModifier.juggernaut);
      }
    });

    test('world 1 uses overload every 3 waves (not on 5s)', () {
      for (int wave = 3; wave <= 20; wave += 3) {
        if (wave % 5 == 0) continue; // Skip juggernaut waves
        final modifier = WaveModifierSimulator.selectModifier(
          wave: wave,
          world: 1,
          availableTypes: 4,
          hasPhantom: false,
        );
        expect(modifier, SimulatedWaveModifier.overload);
      }
    });

    test('world 2 uses phantom every 6 waves', () {
      for (int wave = 6; wave <= 24; wave += 6) {
        final modifier = WaveModifierSimulator.selectModifier(
          wave: wave,
          world: 2,
          availableTypes: 4,
          hasPhantom: true,
        );
        expect(modifier, SimulatedWaveModifier.phantom);
      }
    });

    test('world 3 uses mixed every 7 waves', () {
      for (int wave = 7; wave <= 21; wave += 7) {
        final modifier = WaveModifierSimulator.selectModifier(
          wave: wave,
          world: 3,
          availableTypes: 4,
          hasPhantom: false,
        );
        expect(modifier, SimulatedWaveModifier.mixed);
      }
    });

    test('worlds 4+ use mixed every 8 waves', () {
      for (int wave = 8; wave <= 24; wave += 8) {
        final modifier = WaveModifierSimulator.selectModifier(
          wave: wave,
          world: 5,
          availableTypes: 4,
          hasPhantom: false,
        );
        expect(modifier, SimulatedWaveModifier.mixed);
      }
    });

    test('returns normal when not enough types', () {
      final modifier = WaveModifierSimulator.selectModifier(
        wave: 3,
        world: 1,
        availableTypes: 1,
        hasPhantom: false,
      );
      expect(modifier, SimulatedWaveModifier.normal);
    });
  });

  group('WaveModifierSimulator - Enemy Count Modification', () {
    test('overload increases count by 25%', () {
      final base = 20;
      final modified = WaveModifierSimulator.modifyEnemyCount(
        baseCount: base,
        modifier: SimulatedWaveModifier.overload,
      );
      expect(modified, 25); // 20 * 1.25 = 25
    });

    test('juggernaut decreases count by 30%', () {
      final base = 20;
      final modified = WaveModifierSimulator.modifyEnemyCount(
        baseCount: base,
        modifier: SimulatedWaveModifier.juggernaut,
      );
      expect(modified, 14); // 20 * 0.7 = 14
    });

    test('phantom decreases count by 15%', () {
      final base = 20;
      final modified = WaveModifierSimulator.modifyEnemyCount(
        baseCount: base,
        modifier: SimulatedWaveModifier.phantom,
      );
      expect(modified, 17); // 20 * 0.85 = 17
    });

    test('mixed increases count by 10%', () {
      final base = 20;
      final modified = WaveModifierSimulator.modifyEnemyCount(
        baseCount: base,
        modifier: SimulatedWaveModifier.mixed,
      );
      expect(modified, 22); // 20 * 1.1 = 22
    });

    test('count respects min of 3', () {
      final modified = WaveModifierSimulator.modifyEnemyCount(
        baseCount: 2,
        modifier: SimulatedWaveModifier.juggernaut,
      );
      expect(modified, greaterThanOrEqualTo(3));
    });

    test('count respects max of 80', () {
      final modified = WaveModifierSimulator.modifyEnemyCount(
        baseCount: 100,
        modifier: SimulatedWaveModifier.overload,
        maxCount: 80,
      );
      expect(modified, lessThanOrEqualTo(80));
    });
  });

  group('WaveModifierSimulator - Spawn Interval Modification', () {
    test('overload decreases interval by 20%', () {
      final base = 1.0;
      final modified = WaveModifierSimulator.modifySpawnInterval(
        baseInterval: base,
        modifier: SimulatedWaveModifier.overload,
      );
      expect(modified, closeTo(0.8, 0.001));
    });

    test('juggernaut increases interval by 15%', () {
      final base = 1.0;
      final modified = WaveModifierSimulator.modifySpawnInterval(
        baseInterval: base,
        modifier: SimulatedWaveModifier.juggernaut,
      );
      expect(modified, closeTo(1.15, 0.001));
    });

    test('phantom increases interval by 5%', () {
      final base = 1.0;
      final modified = WaveModifierSimulator.modifySpawnInterval(
        baseInterval: base,
        modifier: SimulatedWaveModifier.phantom,
      );
      expect(modified, closeTo(1.05, 0.001));
    });

    test('interval respects min of 0.35', () {
      final modified = WaveModifierSimulator.modifySpawnInterval(
        baseInterval: 0.3,
        modifier: SimulatedWaveModifier.overload,
      );
      expect(modified, greaterThanOrEqualTo(0.35));
    });

    test('interval respects max of 1.6', () {
      final modified = WaveModifierSimulator.modifySpawnInterval(
        baseInterval: 1.5,
        modifier: SimulatedWaveModifier.juggernaut,
      );
      expect(modified, lessThanOrEqualTo(1.6));
    });
  });

  group('ThreatTierSimulator - Base Threat Tier', () {
    test('tier 0 for early waves in world 1', () {
      expect(ThreatTierSimulator.baseThreatTier(currentWave: 1, levelWorld: 1), 0);
      expect(ThreatTierSimulator.baseThreatTier(currentWave: 3, levelWorld: 1), 0);
    });

    test('tier 1 at wave 4 or world 2', () {
      expect(ThreatTierSimulator.baseThreatTier(currentWave: 4, levelWorld: 1), 1);
      expect(ThreatTierSimulator.baseThreatTier(currentWave: 1, levelWorld: 2), 1);
    });

    test('tier 2 at wave 8 or world 4', () {
      expect(ThreatTierSimulator.baseThreatTier(currentWave: 8, levelWorld: 1), 2);
      expect(ThreatTierSimulator.baseThreatTier(currentWave: 1, levelWorld: 4), 2);
    });

    test('tier 3 at wave 12 or world 7', () {
      expect(ThreatTierSimulator.baseThreatTier(currentWave: 12, levelWorld: 1), 3);
      expect(ThreatTierSimulator.baseThreatTier(currentWave: 1, levelWorld: 7), 3);
    });
  });

  group('ThreatTierSimulator - Resolved Threat Tier', () {
    test('juggernaut/overload modifiers ensure minimum tier 1', () {
      final tierJuggernaut = ThreatTierSimulator.resolveThreatTier(
        currentWave: 1,
        levelWorld: 1,
        modifier: SimulatedWaveModifier.juggernaut,
        spawnIndex: 0,
      );
      expect(tierJuggernaut, greaterThanOrEqualTo(1));

      final tierOverload = ThreatTierSimulator.resolveThreatTier(
        currentWave: 1,
        levelWorld: 1,
        modifier: SimulatedWaveModifier.overload,
        spawnIndex: 0,
      );
      expect(tierOverload, greaterThanOrEqualTo(1));
    });

    test('tier is reduced if spawn index does not match interval', () {
      // Tier 1 has interval 6
      final tierOnInterval = ThreatTierSimulator.resolveThreatTier(
        currentWave: 5,
        levelWorld: 1,
        modifier: SimulatedWaveModifier.normal,
        spawnIndex: 6,
      );
      final tierOffInterval = ThreatTierSimulator.resolveThreatTier(
        currentWave: 5,
        levelWorld: 1,
        modifier: SimulatedWaveModifier.normal,
        spawnIndex: 7,
      );

      expect(tierOffInterval, lessThanOrEqualTo(tierOnInterval));
    });
  });

  group('ThreatTierSimulator - Gold Adjustment', () {
    test('gold increases by 18% per tier', () {
      final gold0 = ThreatTierSimulator.adjustGoldForThreatTier(baseGold: 100, threatTier: 0);
      final gold1 = ThreatTierSimulator.adjustGoldForThreatTier(baseGold: 100, threatTier: 1);
      final gold2 = ThreatTierSimulator.adjustGoldForThreatTier(baseGold: 100, threatTier: 2);
      final gold3 = ThreatTierSimulator.adjustGoldForThreatTier(baseGold: 100, threatTier: 3);

      expect(gold0, 100);
      expect(gold1, 118);
      expect(gold2, 136);
      expect(gold3, 154);
    });

    test('gold respects min bound', () {
      final gold = ThreatTierSimulator.adjustGoldForThreatTier(baseGold: 1, threatTier: 0);
      expect(gold, greaterThanOrEqualTo(4));
    });
  });

  group('GoldScaleSimulator', () {
    test('scale decreases with world', () {
      final scale1 = GoldScaleSimulator.goldScaleForProgress(
        levelWorld: 1,
        localIndex: 1,
        difficulty: 1,
      );
      final scale5 = GoldScaleSimulator.goldScaleForProgress(
        levelWorld: 5,
        localIndex: 1,
        difficulty: 1,
      );

      expect(scale5, lessThan(scale1));
    });

    test('scale decreases with local index', () {
      final scale1 = GoldScaleSimulator.goldScaleForProgress(
        levelWorld: 1,
        localIndex: 1,
        difficulty: 1,
      );
      final scale10 = GoldScaleSimulator.goldScaleForProgress(
        levelWorld: 1,
        localIndex: 10,
        difficulty: 1,
      );

      expect(scale10, lessThan(scale1));
    });

    test('scale decreases with difficulty', () {
      final scaleDiff1 = GoldScaleSimulator.goldScaleForProgress(
        levelWorld: 1,
        localIndex: 1,
        difficulty: 1,
      );
      final scaleDiff5 = GoldScaleSimulator.goldScaleForProgress(
        levelWorld: 1,
        localIndex: 1,
        difficulty: 5,
      );

      expect(scaleDiff5, lessThan(scaleDiff1));
    });

    test('scale respects bounds 0.55 to 0.95', () {
      final scaleMin = GoldScaleSimulator.goldScaleForProgress(
        levelWorld: 10,
        localIndex: 10,
        difficulty: 5,
      );
      final scaleMax = GoldScaleSimulator.goldScaleForProgress(
        levelWorld: 1,
        localIndex: 1,
        difficulty: 1,
      );

      expect(scaleMin, greaterThanOrEqualTo(0.55));
      expect(scaleMax, lessThanOrEqualTo(0.95));
    });

    test('base gold formula is correct', () {
      final gold = GoldScaleSimulator.calculateScaledGold(
        baseGold: 10,
        currentWave: 5,
        levelWorld: 1,
        localIndex: 1,
        difficulty: 1,
      );

      // (10 + 5 * 2) * 0.92 = 20 * 0.92 = 18.4 ≈ 18
      expect(gold, closeTo(18, 1));
    });
  });

  group('Complete Wave Progression Simulation', () {
    test('simulates 10 waves of progression', () {
      const levelId = 15; // World 2, Level 5
      final progressIndex = DifficultyCurveSimulator.progressIndex(levelId: levelId);

      for (int wave = 1; wave <= 10; wave++) {
        final health = DifficultyCurveSimulator.healthMultiplier(
          progressIndexValue: progressIndex,
          wave: wave,
          difficulty: 2,
        );
        final speed = DifficultyCurveSimulator.speedMultiplier(
          progressIndexValue: progressIndex,
          wave: wave,
          difficulty: 2,
        );
        final count = DifficultyCurveSimulator.enemyCount(
          baseCount: 5,
          progressIndexValue: progressIndex,
          wave: wave,
          difficulty: 2,
        );
        final interval = DifficultyCurveSimulator.spawnInterval(
          progressIndexValue: progressIndex,
          wave: wave,
          difficulty: 2,
        );

        expect(health, greaterThan(0));
        expect(speed, greaterThan(0));
        expect(count, greaterThanOrEqualTo(3));
        expect(interval, greaterThan(0));
      }
    });

    test('difficulty scaling is monotonic', () {
      const wave = 5;
      const progressIndex = 20;

      double prevHealth = 0;
      double prevSpeed = 0;

      for (int diff = 1; diff <= 5; diff++) {
        final health = DifficultyCurveSimulator.healthMultiplier(
          progressIndexValue: progressIndex,
          wave: wave,
          difficulty: diff,
        );
        final speed = DifficultyCurveSimulator.speedMultiplier(
          progressIndexValue: progressIndex,
          wave: wave,
          difficulty: diff,
        );

        expect(health, greaterThan(prevHealth));
        expect(speed, greaterThan(prevSpeed));

        prevHealth = health;
        prevSpeed = speed;
      }
    });
  });
}
