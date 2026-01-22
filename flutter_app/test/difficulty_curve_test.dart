import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/balance/difficulty_curve.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DifficultyCurve level mapping', () {
    test('level mapping produces consistent world/local/progress', () {
      expect(DifficultyCurve.worldForLevel(1), 1);
      expect(DifficultyCurve.localIndexForLevel(1), 1);
      expect(DifficultyCurve.progressIndex(levelId: 1), 0);

      expect(DifficultyCurve.worldForLevel(10), 1);
      expect(DifficultyCurve.localIndexForLevel(10), 10);
      expect(DifficultyCurve.progressIndex(levelId: 10), 9);

      expect(DifficultyCurve.worldForLevel(11), 2);
      expect(DifficultyCurve.localIndexForLevel(11), 1);
      expect(DifficultyCurve.progressIndex(levelId: 11), 10);
    });

    test('worldForLevel for all worlds', () {
      expect(DifficultyCurve.worldForLevel(1), 1);
      expect(DifficultyCurve.worldForLevel(15), 2);
      expect(DifficultyCurve.worldForLevel(21), 3);
      expect(DifficultyCurve.worldForLevel(35), 4);
      expect(DifficultyCurve.worldForLevel(50), 5);
      expect(DifficultyCurve.worldForLevel(100), 10);
    });

    test('localIndexForLevel returns 1-10 for each world', () {
      for (int world = 1; world <= 5; world++) {
        for (int local = 1; local <= 10; local++) {
          final levelId = (world - 1) * 10 + local;
          expect(DifficultyCurve.localIndexForLevel(levelId), local);
        }
      }
    });

    test('progressIndex is sequential', () {
      for (int i = 1; i <= 50; i++) {
        expect(DifficultyCurve.progressIndex(levelId: i), i - 1);
      }
    });

    test('levelsPerWorld constant is 10', () {
      expect(DifficultyCurve.levelsPerWorld, 10);
    });
  });

  group('DifficultyCurve difficulty scale', () {
    test('difficulty scale is linear in difficulty', () {
      expect(DifficultyCurve.difficultyScale(1), 1.0);
      expect(DifficultyCurve.difficultyScale(3), closeTo(1.16, 0.0001));
    });

    test('difficulty scale increases with difficulty level', () {
      for (int i = 1; i <= 5; i++) {
        final scale = DifficultyCurve.difficultyScale(i);
        expect(scale, 1 + (i - 1) * 0.08);
      }
    });

    test('difficulty scale at max difficulty', () {
      expect(DifficultyCurve.difficultyScale(5), closeTo(1.32, 0.0001));
    });
  });

  group('DifficultyCurve health multiplier', () {
    test('health multipliers increase with wave/difficulty', () {
      final baseHealth = DifficultyCurve.healthMultiplier(
        progressIndexValue: 5,
        wave: 1,
        difficulty: 1,
      );
      final boostedHealth = DifficultyCurve.healthMultiplier(
        progressIndexValue: 5,
        wave: 4,
        difficulty: 3,
      );
      expect(boostedHealth, greaterThan(baseHealth));
    });

    test('health increases with progress index', () {
      final health1 = DifficultyCurve.healthMultiplier(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final health2 = DifficultyCurve.healthMultiplier(
        progressIndexValue: 50,
        wave: 1,
        difficulty: 1,
      );
      expect(health2, greaterThan(health1));
    });

    test('health increases with wave', () {
      final health1 = DifficultyCurve.healthMultiplier(
        progressIndexValue: 10,
        wave: 1,
        difficulty: 1,
      );
      final health10 = DifficultyCurve.healthMultiplier(
        progressIndexValue: 10,
        wave: 10,
        difficulty: 1,
      );
      expect(health10, greaterThan(health1));
    });

    test('health increases with difficulty', () {
      final healthEasy = DifficultyCurve.healthMultiplier(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 1,
      );
      final healthHard = DifficultyCurve.healthMultiplier(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 5,
      );
      expect(healthHard, greaterThan(healthEasy));
    });
  });

  group('DifficultyCurve speed multiplier', () {
    test('speed multipliers increase with wave/difficulty', () {
      final baseSpeed = DifficultyCurve.speedMultiplier(
        progressIndexValue: 5,
        wave: 1,
        difficulty: 1,
      );
      final boostedSpeed = DifficultyCurve.speedMultiplier(
        progressIndexValue: 5,
        wave: 4,
        difficulty: 3,
      );
      expect(boostedSpeed, greaterThan(baseSpeed));
    });

    test('speed increases with progress index', () {
      final speed1 = DifficultyCurve.speedMultiplier(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final speed50 = DifficultyCurve.speedMultiplier(
        progressIndexValue: 50,
        wave: 1,
        difficulty: 1,
      );
      expect(speed50, greaterThan(speed1));
    });

    test('speed increases with wave', () {
      final speed1 = DifficultyCurve.speedMultiplier(
        progressIndexValue: 10,
        wave: 1,
        difficulty: 1,
      );
      final speed10 = DifficultyCurve.speedMultiplier(
        progressIndexValue: 10,
        wave: 10,
        difficulty: 1,
      );
      expect(speed10, greaterThan(speed1));
    });
  });

  group('DifficultyCurve spawn interval', () {
    test('spawn interval clamps to min and max', () {
      final minClamped = DifficultyCurve.spawnInterval(
        progressIndexValue: 200,
        wave: 20,
        difficulty: 5,
      );
      expect(minClamped, closeTo(0.35, 0.0001));

      final maxClamped = DifficultyCurve.spawnInterval(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
        maxInterval: 0.9,
      );
      expect(maxClamped, closeTo(0.9, 0.0001));
    });

    test('spawn interval decreases with progress', () {
      final interval1 = DifficultyCurve.spawnInterval(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final interval2 = DifficultyCurve.spawnInterval(
        progressIndexValue: 30,
        wave: 1,
        difficulty: 1,
      );
      expect(interval2, lessThan(interval1));
    });

    test('spawn interval decreases with wave', () {
      final interval1 = DifficultyCurve.spawnInterval(
        progressIndexValue: 10,
        wave: 1,
        difficulty: 1,
      );
      final interval10 = DifficultyCurve.spawnInterval(
        progressIndexValue: 10,
        wave: 10,
        difficulty: 1,
      );
      expect(interval10, lessThan(interval1));
    });

    test('spawn interval decreases with difficulty', () {
      final intervalEasy = DifficultyCurve.spawnInterval(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 1,
      );
      final intervalHard = DifficultyCurve.spawnInterval(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 5,
      );
      expect(intervalHard, lessThan(intervalEasy));
    });

    test('spawn interval respects custom min/max', () {
      final interval = DifficultyCurve.spawnInterval(
        progressIndexValue: 100,
        wave: 10,
        difficulty: 3,
        minInterval: 0.5,
        maxInterval: 2.0,
      );
      expect(interval, greaterThanOrEqualTo(0.5));
      expect(interval, lessThanOrEqualTo(2.0));
    });
  });

  group('DifficultyCurve enemy count', () {
    test('enemy count clamps to max', () {
      final maxCount = DifficultyCurve.enemyCount(
        baseCount: 100,
        progressIndexValue: 1000,
        wave: 50,
        difficulty: 5,
        minCount: 3,
        maxCount: 80,
      );
      expect(maxCount, 80);
    });

    test('enemy count clamps to min', () {
      final minCount = DifficultyCurve.enemyCount(
        baseCount: 1,
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
        minCount: 3,
        maxCount: 80,
      );
      expect(minCount, 3);
    });

    test('enemy count increases with wave', () {
      final count1 = DifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: 5,
        wave: 1,
        difficulty: 1,
      );
      final count10 = DifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: 5,
        wave: 10,
        difficulty: 1,
      );
      expect(count10, greaterThan(count1));
    });

    test('enemy count increases with progress', () {
      final count1 = DifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      final count50 = DifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: 50,
        wave: 1,
        difficulty: 1,
      );
      expect(count50, greaterThan(count1));
    });

    test('enemy count increases with difficulty', () {
      final countEasy = DifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: 10,
        wave: 5,
        difficulty: 1,
      );
      final countHard = DifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: 10,
        wave: 5,
        difficulty: 5,
      );
      expect(countHard, greaterThan(countEasy));
    });
  });

  group('DifficultyCurve tower cost multiplier', () {
    test('no extra cost within grace count', () {
      final noExtra = DifficultyCurve.towerCostMultiplier(
        2,
        graceCount: 2,
        step: 0.1,
      );
      expect(noExtra, 1.0);
    });

    test('extra cost beyond grace count', () {
      final extra = DifficultyCurve.towerCostMultiplier(
        5,
        graceCount: 2,
        step: 0.1,
      );
      expect(extra, closeTo(1.3, 0.0001));
    });

    test('tower cost multiplier with zero towers', () {
      final mult = DifficultyCurve.towerCostMultiplier(0);
      expect(mult, 1.0);
    });

    test('tower cost multiplier increases linearly', () {
      final mult3 = DifficultyCurve.towerCostMultiplier(3, graceCount: 0, step: 0.1);
      final mult5 = DifficultyCurve.towerCostMultiplier(5, graceCount: 0, step: 0.1);
      expect(mult3, closeTo(1.3, 0.0001));
      expect(mult5, closeTo(1.5, 0.0001));
    });

    test('tower cost multiplier respects custom step', () {
      final mult = DifficultyCurve.towerCostMultiplier(5, graceCount: 2, step: 0.2);
      expect(mult, closeTo(1.6, 0.0001));
    });
  });

  group('DifficultyCurve wave clear bonus', () {
    test('wave clear bonus clamps to min', () {
      final minBonus = DifficultyCurve.waveClearBonus(
        progressIndexValue: 500,
        wave: 1,
        difficulty: 5,
        minBonus: 25,
        maxBonus: 40,
      );
      expect(minBonus, 25);
    });

    test('wave clear bonus clamps to max', () {
      final maxBonus = DifficultyCurve.waveClearBonus(
        progressIndexValue: 0,
        wave: 20,
        difficulty: 1,
        minBonus: 6,
        maxBonus: 30,
      );
      expect(maxBonus, 30);
    });

    test('wave clear bonus increases with wave', () {
      final bonus1 = DifficultyCurve.waveClearBonus(
        progressIndexValue: 10,
        wave: 1,
        difficulty: 1,
      );
      final bonus10 = DifficultyCurve.waveClearBonus(
        progressIndexValue: 10,
        wave: 10,
        difficulty: 1,
      );
      expect(bonus10, greaterThan(bonus1));
    });

    test('wave clear bonus decreases with difficulty', () {
      final bonusEasy = DifficultyCurve.waveClearBonus(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 1,
      );
      final bonusHard = DifficultyCurve.waveClearBonus(
        progressIndexValue: 10,
        wave: 5,
        difficulty: 5,
      );
      expect(bonusHard, lessThanOrEqualTo(bonusEasy));
    });
  });

  group('DifficultyCurve starting gold', () {
    test('starting gold increases with world', () {
      final gold1 = DifficultyCurve.startingGold(world: 1, localIndex: 1);
      final gold5 = DifficultyCurve.startingGold(world: 5, localIndex: 1);
      expect(gold5, greaterThan(gold1));
    });

    test('starting gold increases with local index', () {
      final gold1 = DifficultyCurve.startingGold(world: 1, localIndex: 1);
      final gold10 = DifficultyCurve.startingGold(world: 1, localIndex: 10);
      expect(gold10, greaterThan(gold1));
    });

    test('starting gold respects base value', () {
      final gold = DifficultyCurve.startingGold(world: 1, localIndex: 1, base: 200);
      expect(gold, 200);
    });

    test('starting gold formula', () {
      // base + 10 * (world - 1) + 3 * (localIndex - 1)
      final gold = DifficultyCurve.startingGold(world: 3, localIndex: 5, base: 130);
      expect(gold, 130 + 10 * 2 + 3 * 4); // 130 + 20 + 12 = 162
    });
  });
}
