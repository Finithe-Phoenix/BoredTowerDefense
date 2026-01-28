import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/balance/difficulty_curve.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DifficultyCurve.levelsPerWorld constant', () {
    test('levelsPerWorld is exactly 10', () {
      expect(DifficultyCurve.levelsPerWorld, 10);
    });

    test('levelsPerWorld is positive', () {
      expect(DifficultyCurve.levelsPerWorld, greaterThan(0));
    });

    test('levelsPerWorld is consistent', () {
      expect(DifficultyCurve.levelsPerWorld, DifficultyCurve.levelsPerWorld);
    });
  });

  group('DifficultyCurve.worldForLevel - World 1', () {
    test('level 1 is in world 1', () {
      expect(DifficultyCurve.worldForLevel(1), 1);
    });

    test('level 2 is in world 1', () {
      expect(DifficultyCurve.worldForLevel(2), 1);
    });

    test('level 5 is in world 1', () {
      expect(DifficultyCurve.worldForLevel(5), 1);
    });

    test('level 10 is in world 1', () {
      expect(DifficultyCurve.worldForLevel(10), 1);
    });

    for (int i = 1; i <= 10; i++) {
      test('level $i belongs to world 1', () {
        expect(DifficultyCurve.worldForLevel(i), 1);
      });
    }
  });

  group('DifficultyCurve.worldForLevel - World 2', () {
    test('level 11 is in world 2', () {
      expect(DifficultyCurve.worldForLevel(11), 2);
    });

    test('level 15 is in world 2', () {
      expect(DifficultyCurve.worldForLevel(15), 2);
    });

    test('level 20 is in world 2', () {
      expect(DifficultyCurve.worldForLevel(20), 2);
    });

    for (int i = 11; i <= 20; i++) {
      test('level $i belongs to world 2', () {
        expect(DifficultyCurve.worldForLevel(i), 2);
      });
    }
  });

  group('DifficultyCurve.worldForLevel - World 3', () {
    for (int i = 21; i <= 30; i++) {
      test('level $i belongs to world 3', () {
        expect(DifficultyCurve.worldForLevel(i), 3);
      });
    }
  });

  group('DifficultyCurve.worldForLevel - World 4', () {
    for (int i = 31; i <= 40; i++) {
      test('level $i belongs to world 4', () {
        expect(DifficultyCurve.worldForLevel(i), 4);
      });
    }
  });

  group('DifficultyCurve.worldForLevel - World 5', () {
    for (int i = 41; i <= 50; i++) {
      test('level $i belongs to world 5', () {
        expect(DifficultyCurve.worldForLevel(i), 5);
      });
    }
  });

  group('DifficultyCurve.worldForLevel - Higher Worlds', () {
    test('level 51 is in world 6', () {
      expect(DifficultyCurve.worldForLevel(51), 6);
    });

    test('level 60 is in world 6', () {
      expect(DifficultyCurve.worldForLevel(60), 6);
    });

    test('level 100 is in world 10', () {
      expect(DifficultyCurve.worldForLevel(100), 10);
    });

    test('level 150 is in world 15', () {
      expect(DifficultyCurve.worldForLevel(150), 15);
    });

    test('level 200 is in world 20', () {
      expect(DifficultyCurve.worldForLevel(200), 20);
    });
  });

  group('DifficultyCurve.localIndexForLevel - Basic', () {
    test('level 1 has local index 1', () {
      expect(DifficultyCurve.localIndexForLevel(1), 1);
    });

    test('level 10 has local index 10', () {
      expect(DifficultyCurve.localIndexForLevel(10), 10);
    });

    test('level 11 has local index 1', () {
      expect(DifficultyCurve.localIndexForLevel(11), 1);
    });

    test('level 20 has local index 10', () {
      expect(DifficultyCurve.localIndexForLevel(20), 10);
    });
  });

  group('DifficultyCurve.localIndexForLevel - Pattern verification', () {
    for (int world = 1; world <= 10; world++) {
      for (int local = 1; local <= 10; local++) {
        final levelId = (world - 1) * 10 + local;
        test('level $levelId (world $world) has local index $local', () {
          expect(DifficultyCurve.localIndexForLevel(levelId), local);
        });
      }
    }
  });

  group('DifficultyCurve.progressIndex - Sequential', () {
    for (int i = 1; i <= 50; i++) {
      test('level $i has progress index ${i - 1}', () {
        expect(DifficultyCurve.progressIndex(levelId: i), i - 1);
      });
    }
  });

  group('DifficultyCurve.progressIndex - Edge cases', () {
    test('progress index for level 1 is 0', () {
      expect(DifficultyCurve.progressIndex(levelId: 1), 0);
    });

    test('progress index for level 100 is 99', () {
      expect(DifficultyCurve.progressIndex(levelId: 100), 99);
    });

    test('progress index is world-agnostic sequential', () {
      expect(DifficultyCurve.progressIndex(levelId: 11), 10);
      expect(DifficultyCurve.progressIndex(levelId: 21), 20);
      expect(DifficultyCurve.progressIndex(levelId: 31), 30);
    });
  });

  group('DifficultyCurve.difficultyScale - Basic', () {
    test('difficulty 1 has scale 1.0', () {
      expect(DifficultyCurve.difficultyScale(1), 1.0);
    });

    test('difficulty 2 has scale 1.08', () {
      expect(DifficultyCurve.difficultyScale(2), closeTo(1.08, 0.0001));
    });

    test('difficulty 3 has scale 1.16', () {
      expect(DifficultyCurve.difficultyScale(3), closeTo(1.16, 0.0001));
    });

    test('difficulty 4 has scale 1.24', () {
      expect(DifficultyCurve.difficultyScale(4), closeTo(1.24, 0.0001));
    });

    test('difficulty 5 has scale 1.32', () {
      expect(DifficultyCurve.difficultyScale(5), closeTo(1.32, 0.0001));
    });
  });

  group('DifficultyCurve.difficultyScale - Formula verification', () {
    for (int diff = 1; diff <= 10; diff++) {
      test('difficulty $diff follows formula 1 + (diff-1)*0.08', () {
        final expected = 1 + (diff - 1) * 0.08;
        expect(DifficultyCurve.difficultyScale(diff), closeTo(expected, 0.0001));
      });
    }
  });

  group('DifficultyCurve.difficultyScale - Monotonicity', () {
    test('difficulty scale increases monotonically', () {
      for (int i = 1; i < 10; i++) {
        expect(
          DifficultyCurve.difficultyScale(i + 1),
          greaterThan(DifficultyCurve.difficultyScale(i)),
        );
      }
    });
  });

  group('DifficultyCurve.healthMultiplier - Basic behavior', () {
    test('health multiplier is positive', () {
      final health = DifficultyCurve.healthMultiplier(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      expect(health, greaterThan(0));
    });

    test('health multiplier at wave 1 difficulty 1 progress 0', () {
      final health = DifficultyCurve.healthMultiplier(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      expect(health, greaterThan(1.0));
    });
  });

  group('DifficultyCurve.healthMultiplier - Progress scaling', () {
    test('health increases from progress 0 to 10', () {
      final h0 = DifficultyCurve.healthMultiplier(
        progressIndexValue: 0, wave: 1, difficulty: 1);
      final h10 = DifficultyCurve.healthMultiplier(
        progressIndexValue: 10, wave: 1, difficulty: 1);
      expect(h10, greaterThan(h0));
    });

    test('health increases from progress 10 to 20', () {
      final h10 = DifficultyCurve.healthMultiplier(
        progressIndexValue: 10, wave: 1, difficulty: 1);
      final h20 = DifficultyCurve.healthMultiplier(
        progressIndexValue: 20, wave: 1, difficulty: 1);
      expect(h20, greaterThan(h10));
    });

    test('health increases from progress 20 to 50', () {
      final h20 = DifficultyCurve.healthMultiplier(
        progressIndexValue: 20, wave: 1, difficulty: 1);
      final h50 = DifficultyCurve.healthMultiplier(
        progressIndexValue: 50, wave: 1, difficulty: 1);
      expect(h50, greaterThan(h20));
    });

    for (int p = 0; p < 50; p += 5) {
      test('health at progress $p is less than at progress ${p + 5}', () {
        final h1 = DifficultyCurve.healthMultiplier(
          progressIndexValue: p, wave: 1, difficulty: 1);
        final h2 = DifficultyCurve.healthMultiplier(
          progressIndexValue: p + 5, wave: 1, difficulty: 1);
        expect(h2, greaterThan(h1));
      });
    }
  });

  group('DifficultyCurve.healthMultiplier - Wave scaling', () {
    for (int wave = 1; wave < 10; wave++) {
      test('health at wave $wave is less than at wave ${wave + 1}', () {
        final h1 = DifficultyCurve.healthMultiplier(
          progressIndexValue: 10, wave: wave, difficulty: 1);
        final h2 = DifficultyCurve.healthMultiplier(
          progressIndexValue: 10, wave: wave + 1, difficulty: 1);
        expect(h2, greaterThan(h1));
      });
    }
  });

  group('DifficultyCurve.healthMultiplier - Difficulty scaling', () {
    for (int diff = 1; diff < 5; diff++) {
      test('health at difficulty $diff is less than at difficulty ${diff + 1}', () {
        final h1 = DifficultyCurve.healthMultiplier(
          progressIndexValue: 10, wave: 5, difficulty: diff);
        final h2 = DifficultyCurve.healthMultiplier(
          progressIndexValue: 10, wave: 5, difficulty: diff + 1);
        expect(h2, greaterThan(h1));
      });
    }
  });

  group('DifficultyCurve.speedMultiplier - Basic behavior', () {
    test('speed multiplier is positive', () {
      final speed = DifficultyCurve.speedMultiplier(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      expect(speed, greaterThan(0));
    });

    test('speed at wave 1 difficulty 1 progress 0 is 1.0', () {
      final speed = DifficultyCurve.speedMultiplier(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      expect(speed, closeTo(1.0, 0.0001));
    });
  });

  group('DifficultyCurve.speedMultiplier - Progress scaling', () {
    for (int p = 0; p < 50; p += 5) {
      test('speed at progress $p is less than at progress ${p + 5}', () {
        final s1 = DifficultyCurve.speedMultiplier(
          progressIndexValue: p, wave: 1, difficulty: 1);
        final s2 = DifficultyCurve.speedMultiplier(
          progressIndexValue: p + 5, wave: 1, difficulty: 1);
        expect(s2, greaterThan(s1));
      });
    }
  });

  group('DifficultyCurve.speedMultiplier - Wave scaling', () {
    for (int wave = 1; wave < 10; wave++) {
      test('speed at wave $wave is less than at wave ${wave + 1}', () {
        final s1 = DifficultyCurve.speedMultiplier(
          progressIndexValue: 10, wave: wave, difficulty: 1);
        final s2 = DifficultyCurve.speedMultiplier(
          progressIndexValue: 10, wave: wave + 1, difficulty: 1);
        expect(s2, greaterThan(s1));
      });
    }
  });

  group('DifficultyCurve.speedMultiplier - Difficulty scaling', () {
    for (int diff = 1; diff < 5; diff++) {
      test('speed at difficulty $diff is less than at difficulty ${diff + 1}', () {
        final s1 = DifficultyCurve.speedMultiplier(
          progressIndexValue: 10, wave: 5, difficulty: diff);
        final s2 = DifficultyCurve.speedMultiplier(
          progressIndexValue: 10, wave: 5, difficulty: diff + 1);
        expect(s2, greaterThan(s1));
      });
    }
  });

  group('DifficultyCurve.enemyCount - Basic behavior', () {
    test('enemy count is positive', () {
      final count = DifficultyCurve.enemyCount(
        baseCount: 10,
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      expect(count, greaterThan(0));
    });

    test('enemy count respects min clamp', () {
      final count = DifficultyCurve.enemyCount(
        baseCount: 1,
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
        minCount: 5,
      );
      expect(count, greaterThanOrEqualTo(5));
    });

    test('enemy count respects max clamp', () {
      final count = DifficultyCurve.enemyCount(
        baseCount: 1000,
        progressIndexValue: 100,
        wave: 20,
        difficulty: 5,
        maxCount: 50,
      );
      expect(count, lessThanOrEqualTo(50));
    });
  });

  group('DifficultyCurve.enemyCount - Scaling', () {
    test('enemy count increases with wave', () {
      final c1 = DifficultyCurve.enemyCount(
        baseCount: 10, progressIndexValue: 5, wave: 1, difficulty: 1);
      final c5 = DifficultyCurve.enemyCount(
        baseCount: 10, progressIndexValue: 5, wave: 5, difficulty: 1);
      expect(c5, greaterThan(c1));
    });

    test('enemy count increases with progress', () {
      final c0 = DifficultyCurve.enemyCount(
        baseCount: 10, progressIndexValue: 0, wave: 1, difficulty: 1);
      final c50 = DifficultyCurve.enemyCount(
        baseCount: 10, progressIndexValue: 50, wave: 1, difficulty: 1);
      expect(c50, greaterThan(c0));
    });

    test('enemy count increases with difficulty', () {
      final c1 = DifficultyCurve.enemyCount(
        baseCount: 10, progressIndexValue: 10, wave: 5, difficulty: 1);
      final c5 = DifficultyCurve.enemyCount(
        baseCount: 10, progressIndexValue: 10, wave: 5, difficulty: 5);
      expect(c5, greaterThan(c1));
    });

    test('enemy count increases with base count', () {
      final c10 = DifficultyCurve.enemyCount(
        baseCount: 10, progressIndexValue: 5, wave: 5, difficulty: 1);
      final c20 = DifficultyCurve.enemyCount(
        baseCount: 20, progressIndexValue: 5, wave: 5, difficulty: 1);
      expect(c20, greaterThan(c10));
    });
  });

  group('DifficultyCurve.enemyCount - Default bounds', () {
    test('default min count is 3', () {
      final count = DifficultyCurve.enemyCount(
        baseCount: 0,
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      expect(count, greaterThanOrEqualTo(3));
    });

    test('default max count is 160', () {
      final count = DifficultyCurve.enemyCount(
        baseCount: 1000,
        progressIndexValue: 1000,
        wave: 100,
        difficulty: 5,
      );
      expect(count, lessThanOrEqualTo(160));
    });
  });

  group('DifficultyCurve.spawnInterval - Basic behavior', () {
    test('spawn interval is positive', () {
      final interval = DifficultyCurve.spawnInterval(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      expect(interval, greaterThan(0));
    });

    test('spawn interval respects min', () {
      final interval = DifficultyCurve.spawnInterval(
        progressIndexValue: 1000,
        wave: 100,
        difficulty: 5,
        minInterval: 0.5,
      );
      expect(interval, greaterThanOrEqualTo(0.5));
    });

    test('spawn interval respects max', () {
      final interval = DifficultyCurve.spawnInterval(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
        maxInterval: 2.0,
      );
      expect(interval, lessThanOrEqualTo(2.0));
    });
  });

  group('DifficultyCurve.spawnInterval - Scaling (decreases)', () {
    test('spawn interval decreases with progress', () {
      final i0 = DifficultyCurve.spawnInterval(
        progressIndexValue: 0, wave: 1, difficulty: 1);
      final i50 = DifficultyCurve.spawnInterval(
        progressIndexValue: 50, wave: 1, difficulty: 1);
      expect(i50, lessThan(i0));
    });

    test('spawn interval decreases with wave', () {
      final i1 = DifficultyCurve.spawnInterval(
        progressIndexValue: 10, wave: 1, difficulty: 1);
      final i10 = DifficultyCurve.spawnInterval(
        progressIndexValue: 10, wave: 10, difficulty: 1);
      expect(i10, lessThan(i1));
    });

    test('spawn interval decreases with difficulty', () {
      final i1 = DifficultyCurve.spawnInterval(
        progressIndexValue: 10, wave: 5, difficulty: 1);
      final i5 = DifficultyCurve.spawnInterval(
        progressIndexValue: 10, wave: 5, difficulty: 5);
      expect(i5, lessThan(i1));
    });
  });

  group('DifficultyCurve.spawnInterval - Default bounds', () {
    test('default min interval is 0.35', () {
      final interval = DifficultyCurve.spawnInterval(
        progressIndexValue: 1000,
        wave: 100,
        difficulty: 5,
      );
      expect(interval, closeTo(0.35, 0.0001));
    });

    test('default max interval is 1.3', () {
      final interval = DifficultyCurve.spawnInterval(
        progressIndexValue: 0,
        wave: 1,
        difficulty: 1,
      );
      expect(interval, lessThanOrEqualTo(1.3));
    });
  });

  group('DifficultyCurve.startingGold - Basic behavior', () {
    test('starting gold is positive', () {
      final gold = DifficultyCurve.startingGold(world: 1, localIndex: 1);
      expect(gold, greaterThan(0));
    });

    test('starting gold at world 1 level 1 is base value', () {
      final gold = DifficultyCurve.startingGold(world: 1, localIndex: 1);
      expect(gold, 130);
    });

    test('starting gold respects custom base', () {
      final gold = DifficultyCurve.startingGold(world: 1, localIndex: 1, base: 200);
      expect(gold, 200);
    });
  });

  group('DifficultyCurve.startingGold - World scaling', () {
    for (int world = 1; world <= 10; world++) {
      test('starting gold for world $world level 1', () {
        final gold = DifficultyCurve.startingGold(world: world, localIndex: 1);
        final expected = 130 + 10 * (world - 1);
        expect(gold, expected);
      });
    }
  });

  group('DifficultyCurve.startingGold - Level scaling', () {
    for (int local = 1; local <= 10; local++) {
      test('starting gold for world 1 level $local', () {
        final gold = DifficultyCurve.startingGold(world: 1, localIndex: local);
        final expected = 130 + 3 * (local - 1);
        expect(gold, expected);
      });
    }
  });

  group('DifficultyCurve.startingGold - Combined scaling', () {
    test('formula: base + 10*(world-1) + 3*(localIndex-1)', () {
      final gold = DifficultyCurve.startingGold(world: 5, localIndex: 7);
      final expected = 130 + 10 * 4 + 3 * 6; // 130 + 40 + 18 = 188
      expect(gold, expected);
    });

    for (int world = 1; world <= 5; world++) {
      for (int local = 1; local <= 10; local++) {
        test('gold formula for world $world level $local', () {
          final gold = DifficultyCurve.startingGold(world: world, localIndex: local);
          final expected = 130 + 10 * (world - 1) + 3 * (local - 1);
          expect(gold, expected);
        });
      }
    }
  });

  group('DifficultyCurve.towerCostMultiplier - Grace count', () {
    test('0 towers has multiplier 1.0', () {
      expect(DifficultyCurve.towerCostMultiplier(0), 1.0);
    });

    test('1 tower within grace has multiplier 1.0', () {
      expect(DifficultyCurve.towerCostMultiplier(1, graceCount: 2), 1.0);
    });

    test('2 towers at grace limit has multiplier 1.0', () {
      expect(DifficultyCurve.towerCostMultiplier(2, graceCount: 2), 1.0);
    });

    test('3 towers exceeds grace by 1', () {
      final mult = DifficultyCurve.towerCostMultiplier(3, graceCount: 2, step: 0.1);
      expect(mult, closeTo(1.1, 0.0001));
    });
  });

  group('DifficultyCurve.towerCostMultiplier - Step scaling', () {
    for (int towers = 0; towers <= 10; towers++) {
      test('multiplier for $towers towers (grace 2, step 0.1)', () {
        final mult = DifficultyCurve.towerCostMultiplier(
          towers, graceCount: 2, step: 0.1);
        final extra = math.max(0, towers - 2);
        final expected = 1 + extra * 0.1;
        expect(mult, closeTo(expected, 0.0001));
      });
    }
  });

  group('DifficultyCurve.towerCostMultiplier - Custom step', () {
    test('step 0.2 doubles increase rate', () {
      final mult1 = DifficultyCurve.towerCostMultiplier(5, graceCount: 0, step: 0.1);
      final mult2 = DifficultyCurve.towerCostMultiplier(5, graceCount: 0, step: 0.2);
      expect(mult2 - 1.0, closeTo((mult1 - 1.0) * 2, 0.0001));
    });

    test('step 0.05 halves increase rate', () {
      final mult1 = DifficultyCurve.towerCostMultiplier(10, graceCount: 0, step: 0.1);
      final mult2 = DifficultyCurve.towerCostMultiplier(10, graceCount: 0, step: 0.05);
      expect(mult2 - 1.0, closeTo((mult1 - 1.0) / 2, 0.0001));
    });
  });

  group('DifficultyCurve.waveClearBonus - Basic behavior', () {
    test('wave clear bonus is positive', () {
      final bonus = DifficultyCurve.waveClearBonus(
        progressIndexValue: 0, wave: 1, difficulty: 1);
      expect(bonus, greaterThan(0));
    });

    test('wave clear bonus respects min', () {
      final bonus = DifficultyCurve.waveClearBonus(
        progressIndexValue: 1000, wave: 1, difficulty: 5, minBonus: 10);
      expect(bonus, greaterThanOrEqualTo(10));
    });

    test('wave clear bonus respects max', () {
      final bonus = DifficultyCurve.waveClearBonus(
        progressIndexValue: 0, wave: 100, difficulty: 1, maxBonus: 50);
      expect(bonus, lessThanOrEqualTo(50));
    });
  });

  group('DifficultyCurve.waveClearBonus - Scaling', () {
    test('wave clear bonus increases with wave', () {
      final b1 = DifficultyCurve.waveClearBonus(
        progressIndexValue: 10, wave: 1, difficulty: 1);
      final b10 = DifficultyCurve.waveClearBonus(
        progressIndexValue: 10, wave: 10, difficulty: 1);
      expect(b10, greaterThan(b1));
    });

    test('wave clear bonus decreases with difficulty', () {
      final b1 = DifficultyCurve.waveClearBonus(
        progressIndexValue: 10, wave: 5, difficulty: 1);
      final b5 = DifficultyCurve.waveClearBonus(
        progressIndexValue: 10, wave: 5, difficulty: 5);
      expect(b5, lessThanOrEqualTo(b1));
    });

    test('wave clear bonus decreases with high progress', () {
      final b0 = DifficultyCurve.waveClearBonus(
        progressIndexValue: 0, wave: 5, difficulty: 1);
      final b100 = DifficultyCurve.waveClearBonus(
        progressIndexValue: 100, wave: 5, difficulty: 1);
      expect(b100, lessThan(b0));
    });
  });

  group('DifficultyCurve.waveClearBonus - Default bounds', () {
    test('default min bonus is 6', () {
      final bonus = DifficultyCurve.waveClearBonus(
        progressIndexValue: 1000, wave: 1, difficulty: 5);
      expect(bonus, greaterThanOrEqualTo(6));
    });

    test('default max bonus is 60', () {
      final bonus = DifficultyCurve.waveClearBonus(
        progressIndexValue: 0, wave: 1000, difficulty: 1);
      expect(bonus, lessThanOrEqualTo(60));
    });
  });

  group('DifficultyCurve - Integration tests', () {
    test('full level progression maintains consistency', () {
      for (int levelId = 1; levelId <= 100; levelId++) {
        final world = DifficultyCurve.worldForLevel(levelId);
        final local = DifficultyCurve.localIndexForLevel(levelId);
        final progress = DifficultyCurve.progressIndex(levelId: levelId);

        expect(world, greaterThanOrEqualTo(1));
        expect(local, inInclusiveRange(1, 10));
        expect(progress, levelId - 1);

        // Reconstruct levelId
        final reconstructed = (world - 1) * 10 + local;
        expect(reconstructed, levelId);
      }
    });

    test('game balance at world 1 level 1 wave 1', () {
      final health = DifficultyCurve.healthMultiplier(
        progressIndexValue: 0, wave: 1, difficulty: 1);
      final speed = DifficultyCurve.speedMultiplier(
        progressIndexValue: 0, wave: 1, difficulty: 1);
      final interval = DifficultyCurve.spawnInterval(
        progressIndexValue: 0, wave: 1, difficulty: 1);
      final gold = DifficultyCurve.startingGold(world: 1, localIndex: 1);

      expect(health, greaterThan(0));
      expect(speed, greaterThan(0));
      expect(interval, greaterThan(0));
      expect(gold, 130);
    });

    test('game balance at world 5 level 10 wave 10', () {
      final progress = DifficultyCurve.progressIndex(levelId: 50);
      final health = DifficultyCurve.healthMultiplier(
        progressIndexValue: progress, wave: 10, difficulty: 3);
      final speed = DifficultyCurve.speedMultiplier(
        progressIndexValue: progress, wave: 10, difficulty: 3);
      final interval = DifficultyCurve.spawnInterval(
        progressIndexValue: progress, wave: 10, difficulty: 3);
      final gold = DifficultyCurve.startingGold(world: 5, localIndex: 10);

      expect(health, greaterThan(1.0));
      expect(speed, greaterThan(1.0));
      expect(interval, greaterThan(0));
      expect(gold, greaterThan(130));
    });
  });

  group('DifficultyCurve - Edge cases', () {
    test('handles very high level IDs', () {
      expect(DifficultyCurve.worldForLevel(1000), 100);
      expect(DifficultyCurve.localIndexForLevel(1000), 10);
    });

    test('handles very high progress values', () {
      final health = DifficultyCurve.healthMultiplier(
        progressIndexValue: 1000, wave: 100, difficulty: 5);
      expect(health.isFinite, isTrue);
      expect(health, greaterThan(0));
    });

    test('handles very high wave counts', () {
      final count = DifficultyCurve.enemyCount(
        baseCount: 10, progressIndexValue: 50, wave: 100, difficulty: 3);
      expect(count, isA<int>());
      expect(count, greaterThan(0));
    });
  });
}
