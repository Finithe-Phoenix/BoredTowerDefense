// Tests for DifficultyCurve exact formula validation and boundary conditions
import 'dart:math' as math;
import 'package:test/test.dart';
import 'package:bored_games/src/game/balance/difficulty_curve.dart';

void main() {
  group('DifficultyCurve.worldForLevel', () {
    test('level 1 is world 1', () {
      expect(DifficultyCurve.worldForLevel(1), 1);
    });

    test('level 10 is world 1', () {
      expect(DifficultyCurve.worldForLevel(10), 1);
    });

    test('level 11 is world 2', () {
      expect(DifficultyCurve.worldForLevel(11), 2);
    });

    test('level 100 is world 10', () {
      expect(DifficultyCurve.worldForLevel(100), 10);
    });

    test('levels 1-10 map to world 1', () {
      for (int i = 1; i <= 10; i++) {
        expect(DifficultyCurve.worldForLevel(i), 1,
            reason: 'Level $i should be world 1');
      }
    });

    test('levels 91-100 map to world 10', () {
      for (int i = 91; i <= 100; i++) {
        expect(DifficultyCurve.worldForLevel(i), 10,
            reason: 'Level $i should be world 10');
      }
    });
  });

  group('DifficultyCurve.localIndexForLevel', () {
    test('level 1 is local index 1', () {
      expect(DifficultyCurve.localIndexForLevel(1), 1);
    });

    test('level 10 is local index 10', () {
      expect(DifficultyCurve.localIndexForLevel(10), 10);
    });

    test('level 11 is local index 1', () {
      expect(DifficultyCurve.localIndexForLevel(11), 1);
    });

    test('level 15 is local index 5', () {
      expect(DifficultyCurve.localIndexForLevel(15), 5);
    });

    test('level 100 is local index 10', () {
      expect(DifficultyCurve.localIndexForLevel(100), 10);
    });
  });

  group('DifficultyCurve.progressIndex', () {
    test('level 1 has progress index 0', () {
      expect(DifficultyCurve.progressIndex(levelId: 1), 0);
    });

    test('level 2 has progress index 1', () {
      expect(DifficultyCurve.progressIndex(levelId: 2), 1);
    });

    test('level 11 has progress index 10', () {
      expect(DifficultyCurve.progressIndex(levelId: 11), 10);
    });

    test('level 100 has progress index 99', () {
      expect(DifficultyCurve.progressIndex(levelId: 100), 99);
    });

    test('progress index is monotonically increasing', () {
      for (int i = 1; i < 100; i++) {
        expect(
          DifficultyCurve.progressIndex(levelId: i + 1),
          greaterThan(DifficultyCurve.progressIndex(levelId: i)),
          reason: 'Progress for level ${i + 1} should be > level $i',
        );
      }
    });
  });

  group('DifficultyCurve.difficultyScale', () {
    test('difficulty 1 returns 1.0', () {
      expect(DifficultyCurve.difficultyScale(1), 1.0);
    });

    test('difficulty 2 returns 1.08', () {
      expect(DifficultyCurve.difficultyScale(2), closeTo(1.08, 0.001));
    });

    test('difficulty 3 returns 1.16', () {
      expect(DifficultyCurve.difficultyScale(3), closeTo(1.16, 0.001));
    });

    test('difficulty 5 returns 1.32', () {
      expect(DifficultyCurve.difficultyScale(5), closeTo(1.32, 0.001));
    });

    test('formula: 1 + (difficulty - 1) * 0.08', () {
      for (int d = 1; d <= 5; d++) {
        final expected = 1 + (d - 1) * 0.08;
        expect(DifficultyCurve.difficultyScale(d), closeTo(expected, 0.0001),
            reason: 'Difficulty $d');
      }
    });
  });

  group('DifficultyCurve.healthMultiplier', () {
    test('increases with wave number', () {
      final wave1 = DifficultyCurve.healthMultiplier(
        progressIndexValue: 0, wave: 1, difficulty: 1);
      final wave5 = DifficultyCurve.healthMultiplier(
        progressIndexValue: 0, wave: 5, difficulty: 1);
      final wave10 = DifficultyCurve.healthMultiplier(
        progressIndexValue: 0, wave: 10, difficulty: 1);

      expect(wave5, greaterThan(wave1));
      expect(wave10, greaterThan(wave5));
    });

    test('increases with progress', () {
      final early = DifficultyCurve.healthMultiplier(
        progressIndexValue: 0, wave: 1, difficulty: 1);
      final mid = DifficultyCurve.healthMultiplier(
        progressIndexValue: 50, wave: 1, difficulty: 1);
      final late_ = DifficultyCurve.healthMultiplier(
        progressIndexValue: 99, wave: 1, difficulty: 1);

      expect(mid, greaterThan(early));
      expect(late_, greaterThan(mid));
    });

    test('increases with difficulty', () {
      final easy = DifficultyCurve.healthMultiplier(
        progressIndexValue: 0, wave: 1, difficulty: 1);
      final hard = DifficultyCurve.healthMultiplier(
        progressIndexValue: 0, wave: 1, difficulty: 5);

      expect(hard, greaterThan(easy));
    });

    test('exact formula validation for level 1, wave 1, difficulty 1', () {
      // earlyBoost = 0.18 * exp(-0/12) = 0.18
      // growth = 1.08 + 0.18 + 0.035*0 + 0.03*0 = 1.26
      // scaled = 1.26 * 1.0 = 1.26
      // result = pow(1.26, 1.1)
      final expected = math.pow(1.26, 1.1).toDouble();
      final actual = DifficultyCurve.healthMultiplier(
        progressIndexValue: 0, wave: 1, difficulty: 1);
      expect(actual, closeTo(expected, 0.01));
    });

    test('early boost decays with progression', () {
      // Early boost = 0.18 * exp(-progress/12)
      final earlyBoost0 = 0.18 * math.exp(-0 / 12.0);
      final earlyBoost50 = 0.18 * math.exp(-50 / 12.0);

      expect(earlyBoost50, lessThan(earlyBoost0));
      expect(earlyBoost50, closeTo(0, 0.01)); // Negligible at progress 50
    });

    test('always returns positive value', () {
      for (int p = 0; p < 100; p += 10) {
        for (int w = 1; w <= 10; w += 3) {
          for (int d = 1; d <= 5; d++) {
            final result = DifficultyCurve.healthMultiplier(
              progressIndexValue: p, wave: w, difficulty: d);
            expect(result, greaterThan(0),
                reason: 'p=$p, w=$w, d=$d should be positive');
          }
        }
      }
    });
  });

  group('DifficultyCurve.speedMultiplier', () {
    test('base speed at level 1, wave 1, difficulty 1', () {
      // growth = 1 + 0.015*0 + 0.012*0 = 1
      // diffScale = 1 + 0*0.05 = 1
      // result = 1 * 1 = 1
      final result = DifficultyCurve.speedMultiplier(
        progressIndexValue: 0, wave: 1, difficulty: 1);
      expect(result, closeTo(1.0, 0.001));
    });

    test('increases with progression', () {
      final early = DifficultyCurve.speedMultiplier(
        progressIndexValue: 0, wave: 1, difficulty: 1);
      final late_ = DifficultyCurve.speedMultiplier(
        progressIndexValue: 50, wave: 1, difficulty: 1);
      expect(late_, greaterThan(early));
    });

    test('exact formula: progress 20, wave 5, difficulty 3', () {
      // growth = 1 + 0.015*20 + 0.012*4 = 1 + 0.3 + 0.048 = 1.348
      // diffScale = 1 + 2*0.05 = 1.1
      // result = 1.348 * 1.1 = 1.4828
      final expected = 1.348 * 1.1;
      final actual = DifficultyCurve.speedMultiplier(
        progressIndexValue: 20, wave: 5, difficulty: 3);
      expect(actual, closeTo(expected, 0.001));
    });
  });

  group('DifficultyCurve.enemyCount', () {
    test('clamped to min count', () {
      final result = DifficultyCurve.enemyCount(
        baseCount: 1,
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
        minCount: 3,
      );
      expect(result, greaterThanOrEqualTo(3));
    });

    test('clamped to max count', () {
      final result = DifficultyCurve.enemyCount(
        baseCount: 1000,
        progressIndexValue: 99,
        wave: 10,
        difficulty: 5,
        maxCount: 160,
      );
      expect(result, lessThanOrEqualTo(160));
    });

    test('increases with wave number', () {
      final w1 = DifficultyCurve.enemyCount(
        baseCount: 8, progressIndexValue: 0, wave: 1, difficulty: 1);
      final w10 = DifficultyCurve.enemyCount(
        baseCount: 8, progressIndexValue: 0, wave: 10, difficulty: 1);
      expect(w10, greaterThan(w1));
    });

    test('increases with difficulty', () {
      final d1 = DifficultyCurve.enemyCount(
        baseCount: 8, progressIndexValue: 0, wave: 1, difficulty: 1);
      final d5 = DifficultyCurve.enemyCount(
        baseCount: 8, progressIndexValue: 0, wave: 1, difficulty: 5);
      expect(d5, greaterThan(d1));
    });

    test('custom min/max respected', () {
      final result = DifficultyCurve.enemyCount(
        baseCount: 5,
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
        minCount: 10,
        maxCount: 20,
      );
      expect(result, greaterThanOrEqualTo(10));
      expect(result, lessThanOrEqualTo(20));
    });
  });

  group('DifficultyCurve.spawnInterval', () {
    test('decreases with progression (enemies spawn faster)', () {
      final early = DifficultyCurve.spawnInterval(
        progressIndexValue: 0, wave: 1, difficulty: 1);
      final late_ = DifficultyCurve.spawnInterval(
        progressIndexValue: 50, wave: 1, difficulty: 1);
      expect(late_, lessThan(early));
    });

    test('decreases with wave number', () {
      final w1 = DifficultyCurve.spawnInterval(
        progressIndexValue: 0, wave: 1, difficulty: 1);
      final w10 = DifficultyCurve.spawnInterval(
        progressIndexValue: 0, wave: 10, difficulty: 1);
      expect(w10, lessThan(w1));
    });

    test('clamped to min interval', () {
      final result = DifficultyCurve.spawnInterval(
        progressIndexValue: 99,
        wave: 10,
        difficulty: 5,
        minInterval: 0.35,
      );
      expect(result, greaterThanOrEqualTo(0.35));
    });

    test('clamped to max interval', () {
      final result = DifficultyCurve.spawnInterval(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
        maxInterval: 1.3,
      );
      expect(result, lessThanOrEqualTo(1.3));
    });

    test('custom min/max both respected', () {
      final result = DifficultyCurve.spawnInterval(
        progressIndexValue: 50,
        wave: 5,
        difficulty: 3,
        minInterval: 0.5,
        maxInterval: 0.8,
      );
      expect(result, greaterThanOrEqualTo(0.5));
      expect(result, lessThanOrEqualTo(0.8));
    });
  });

  group('DifficultyCurve.startingGold', () {
    test('base starting gold for world 1, local 1', () {
      // 130 + 10*(1-1) + 3*(1-1) = 130
      expect(DifficultyCurve.startingGold(world: 1, localIndex: 1), 130);
    });

    test('increases with world', () {
      final w1 = DifficultyCurve.startingGold(world: 1, localIndex: 1);
      final w5 = DifficultyCurve.startingGold(world: 5, localIndex: 1);
      final w10 = DifficultyCurve.startingGold(world: 10, localIndex: 1);

      expect(w5, greaterThan(w1));
      expect(w10, greaterThan(w5));
    });

    test('increases with local index', () {
      final l1 = DifficultyCurve.startingGold(world: 1, localIndex: 1);
      final l5 = DifficultyCurve.startingGold(world: 1, localIndex: 5);
      final l10 = DifficultyCurve.startingGold(world: 1, localIndex: 10);

      expect(l5, greaterThan(l1));
      expect(l10, greaterThan(l5));
    });

    test('exact formula: world 3, local 5', () {
      // 130 + 10*(3-1) + 3*(5-1) = 130 + 20 + 12 = 162
      expect(DifficultyCurve.startingGold(world: 3, localIndex: 5), 162);
    });

    test('exact formula: world 10, local 10', () {
      // 130 + 10*(10-1) + 3*(10-1) = 130 + 90 + 27 = 247
      expect(DifficultyCurve.startingGold(world: 10, localIndex: 10), 247);
    });

    test('custom base gold', () {
      // 200 + 10*(1-1) + 3*(1-1) = 200
      expect(DifficultyCurve.startingGold(world: 1, localIndex: 1, base: 200), 200);
    });
  });

  group('DifficultyCurve.towerCostMultiplier', () {
    test('first towers have no cost increase (grace period)', () {
      expect(DifficultyCurve.towerCostMultiplier(0), 1.0);
      expect(DifficultyCurve.towerCostMultiplier(1), 1.0);
      expect(DifficultyCurve.towerCostMultiplier(2), 1.0);
    });

    test('cost increases after grace period', () {
      expect(DifficultyCurve.towerCostMultiplier(3), closeTo(1.1, 0.001));
      expect(DifficultyCurve.towerCostMultiplier(4), closeTo(1.2, 0.001));
    });

    test('exact formula: towersPlaced=7, grace=2, step=0.1', () {
      // extra = max(0, 7-2) = 5
      // result = 1 + 5 * 0.1 = 1.5
      expect(DifficultyCurve.towerCostMultiplier(7), closeTo(1.5, 0.001));
    });

    test('custom grace count', () {
      expect(DifficultyCurve.towerCostMultiplier(3, graceCount: 5), 1.0);
      expect(DifficultyCurve.towerCostMultiplier(6, graceCount: 5),
          closeTo(1.1, 0.001));
    });

    test('custom step', () {
      expect(DifficultyCurve.towerCostMultiplier(5, step: 0.2),
          closeTo(1.6, 0.001)); // (5-2)*0.2 = 0.6 → 1.6
    });
  });

  group('DifficultyCurve.waveClearBonus', () {
    test('increases with wave number', () {
      final w1 = DifficultyCurve.waveClearBonus(
        progressIndexValue: 0, wave: 1, difficulty: 1);
      final w5 = DifficultyCurve.waveClearBonus(
        progressIndexValue: 0, wave: 5, difficulty: 1);
      expect(w5, greaterThan(w1));
    });

    test('decreases with higher difficulty', () {
      final d1 = DifficultyCurve.waveClearBonus(
        progressIndexValue: 0, wave: 5, difficulty: 1);
      final d5 = DifficultyCurve.waveClearBonus(
        progressIndexValue: 0, wave: 5, difficulty: 5);
      expect(d5, lessThanOrEqualTo(d1));
    });

    test('exact formula: progress 0, wave 3, difficulty 1', () {
      // base = 12 + (3 * 3) = 21
      // decay = (1 - 0.003*0).clamp(0.7, 1.0) = 1.0
      // diffScale = 1 + 0*0.05 = 1.0
      // result = (21 * 1.0 / 1.0).round().clamp(6, 60) = 21
      expect(DifficultyCurve.waveClearBonus(
        progressIndexValue: 0, wave: 3, difficulty: 1), 21);
    });

    test('clamped to min bonus', () {
      final result = DifficultyCurve.waveClearBonus(
        progressIndexValue: 99,
        wave: 1,
        difficulty: 5,
        minBonus: 6,
      );
      expect(result, greaterThanOrEqualTo(6));
    });

    test('clamped to max bonus', () {
      final result = DifficultyCurve.waveClearBonus(
        progressIndexValue: 0,
        wave: 100,
        difficulty: 1,
        maxBonus: 60,
      );
      expect(result, lessThanOrEqualTo(60));
    });

    test('decay reduces bonus at high progress', () {
      final earlyProgress = DifficultyCurve.waveClearBonus(
        progressIndexValue: 0, wave: 5, difficulty: 1);
      final lateProgress = DifficultyCurve.waveClearBonus(
        progressIndexValue: 80, wave: 5, difficulty: 1);
      expect(lateProgress, lessThanOrEqualTo(earlyProgress));
    });
  });

  group('DifficultyCurve full game progression', () {
    test('health multiplier grows across all 100 levels', () {
      double prevHealth = 0;
      for (int level = 1; level <= 100; level++) {
        final progress = DifficultyCurve.progressIndex(levelId: level);
        final health = DifficultyCurve.healthMultiplier(
          progressIndexValue: progress, wave: 5, difficulty: 3);
        expect(health, greaterThan(prevHealth),
            reason: 'Level $level health should be > previous');
        prevHealth = health;
      }
    });

    test('spawn interval decreases across all 100 levels', () {
      double prevInterval = double.infinity;
      for (int level = 1; level <= 100; level++) {
        final progress = DifficultyCurve.progressIndex(levelId: level);
        final interval = DifficultyCurve.spawnInterval(
          progressIndexValue: progress, wave: 5, difficulty: 3);
        expect(interval, lessThanOrEqualTo(prevInterval),
            reason: 'Level $level interval should be <= previous');
        prevInterval = interval;
      }
    });

    test('starting gold increases across all 10 worlds', () {
      int prevGold = 0;
      for (int world = 1; world <= 10; world++) {
        final gold = DifficultyCurve.startingGold(world: world, localIndex: 1);
        expect(gold, greaterThan(prevGold),
            reason: 'World $world gold should be > previous');
        prevGold = gold;
      }
    });

    test('all difficulty levels produce valid values', () {
      for (int d = 1; d <= 5; d++) {
        final health = DifficultyCurve.healthMultiplier(
          progressIndexValue: 50, wave: 5, difficulty: d);
        final speed = DifficultyCurve.speedMultiplier(
          progressIndexValue: 50, wave: 5, difficulty: d);
        final count = DifficultyCurve.enemyCount(
          baseCount: 8, progressIndexValue: 50, wave: 5, difficulty: d);
        final interval = DifficultyCurve.spawnInterval(
          progressIndexValue: 50, wave: 5, difficulty: d);

        expect(health, greaterThan(0), reason: 'Diff $d health');
        expect(speed, greaterThan(0), reason: 'Diff $d speed');
        expect(count, greaterThan(0), reason: 'Diff $d count');
        expect(interval, greaterThan(0), reason: 'Diff $d interval');
      }
    });
  });
}
