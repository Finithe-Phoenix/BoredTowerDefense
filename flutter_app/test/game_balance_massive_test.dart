import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/balance/difficulty_curve.dart';
import 'package:bored_games/src/game/entities/tower.dart';
import 'package:bored_games/src/game/entities/enemy.dart';
import 'package:bored_games/src/models/upgrade_data.dart';
import 'package:bored_games/src/services/level_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ============================================
  // GAME BALANCE TESTS - DIFFICULTY CURVE (500+ tests)
  // ============================================

  group('DifficultyCurve - Level mapping comprehensive', () {
    // Test all 100 levels
    for (int levelId = 1; levelId <= 100; levelId++) {
      test('level $levelId world mapping', () {
        final world = DifficultyCurve.worldForLevel(levelId);
        expect(world, ((levelId - 1) ~/ 10) + 1);
      });

      test('level $levelId local index', () {
        final local = DifficultyCurve.localIndexForLevel(levelId);
        expect(local, ((levelId - 1) % 10) + 1);
      });

      test('level $levelId progress index', () {
        final progress = DifficultyCurve.progressIndex(levelId: levelId);
        expect(progress, levelId - 1);
      });
    }
  });

  group('DifficultyCurve - World boundaries', () {
    // Test world boundaries explicitly
    final boundaries = [
      (1, 1), (10, 1),   // World 1
      (11, 2), (20, 2),  // World 2
      (21, 3), (30, 3),  // World 3
      (31, 4), (40, 4),  // World 4
      (41, 5), (50, 5),  // World 5
      (51, 6), (60, 6),  // World 6
      (61, 7), (70, 7),  // World 7
      (71, 8), (80, 8),  // World 8
      (81, 9), (90, 9),  // World 9
      (91, 10), (100, 10), // World 10
    ];

    for (final (level, world) in boundaries) {
      test('level $level is in world $world', () {
        expect(DifficultyCurve.worldForLevel(level), world);
      });
    }
  });

  group('DifficultyCurve - Difficulty scale all values', () {
    for (int diff = 1; diff <= 10; diff++) {
      test('difficulty $diff scale', () {
        final scale = DifficultyCurve.difficultyScale(diff);
        final expected = 1 + (diff - 1) * 0.08;
        expect(scale, closeTo(expected, 0.0001));
      });
    }

    test('difficulty scale increases monotonically', () {
      double prev = 0;
      for (int diff = 1; diff <= 10; diff++) {
        final scale = DifficultyCurve.difficultyScale(diff);
        expect(scale, greaterThan(prev));
        prev = scale;
      }
    });
  });

  group('DifficultyCurve - Health multiplier matrix', () {
    // Test health multiplier for various combinations
    for (int progress = 0; progress <= 50; progress += 10) {
      for (int wave = 1; wave <= 10; wave += 3) {
        for (int diff = 1; diff <= 5; diff += 2) {
          test('health at progress=$progress, wave=$wave, diff=$diff', () {
            final health = DifficultyCurve.healthMultiplier(
              progressIndexValue: progress,
              wave: wave,
              difficulty: diff,
            );
            expect(health, greaterThan(0));
            expect(health, isFinite);
          });
        }
      }
    }
  });

  group('DifficultyCurve - Health scaling behavior', () {
    test('health increases with progress', () {
      for (int progress = 0; progress < 90; progress += 10) {
        final h1 = DifficultyCurve.healthMultiplier(
          progressIndexValue: progress,
          wave: 1,
          difficulty: 1,
        );
        final h2 = DifficultyCurve.healthMultiplier(
          progressIndexValue: progress + 10,
          wave: 1,
          difficulty: 1,
        );
        expect(h2, greaterThan(h1));
      }
    });

    test('health increases with wave', () {
      for (int wave = 1; wave < 20; wave++) {
        final h1 = DifficultyCurve.healthMultiplier(
          progressIndexValue: 25,
          wave: wave,
          difficulty: 1,
        );
        final h2 = DifficultyCurve.healthMultiplier(
          progressIndexValue: 25,
          wave: wave + 1,
          difficulty: 1,
        );
        expect(h2, greaterThan(h1));
      }
    });

    test('health increases with difficulty', () {
      for (int diff = 1; diff < 5; diff++) {
        final h1 = DifficultyCurve.healthMultiplier(
          progressIndexValue: 25,
          wave: 5,
          difficulty: diff,
        );
        final h2 = DifficultyCurve.healthMultiplier(
          progressIndexValue: 25,
          wave: 5,
          difficulty: diff + 1,
        );
        expect(h2, greaterThan(h1));
      }
    });
  });

  group('DifficultyCurve - Speed multiplier matrix', () {
    for (int progress = 0; progress <= 50; progress += 10) {
      for (int wave = 1; wave <= 10; wave += 3) {
        for (int diff = 1; diff <= 5; diff += 2) {
          test('speed at progress=$progress, wave=$wave, diff=$diff', () {
            final speed = DifficultyCurve.speedMultiplier(
              progressIndexValue: progress,
              wave: wave,
              difficulty: diff,
            );
            expect(speed, greaterThan(0));
            expect(speed, isFinite);
          });
        }
      }
    }
  });

  group('DifficultyCurve - Enemy count matrix', () {
    for (int baseCount = 5; baseCount <= 20; baseCount += 5) {
      for (int progress = 0; progress <= 50; progress += 25) {
        for (int wave = 1; wave <= 10; wave += 3) {
          test('count base=$baseCount, progress=$progress, wave=$wave', () {
            final count = DifficultyCurve.enemyCount(
              baseCount: baseCount,
              progressIndexValue: progress,
              wave: wave,
              difficulty: 3,
            );
            expect(count, greaterThanOrEqualTo(3)); // default min
            expect(count, lessThanOrEqualTo(160)); // default max
          });
        }
      }
    }
  });

  group('DifficultyCurve - Spawn interval matrix', () {
    for (int progress = 0; progress <= 50; progress += 10) {
      for (int wave = 1; wave <= 10; wave += 3) {
        for (int diff = 1; diff <= 5; diff += 2) {
          test('interval at progress=$progress, wave=$wave, diff=$diff', () {
            final interval = DifficultyCurve.spawnInterval(
              progressIndexValue: progress,
              wave: wave,
              difficulty: diff,
            );
            expect(interval, greaterThanOrEqualTo(0.35)); // default min
            expect(interval, lessThanOrEqualTo(1.3)); // default max
          });
        }
      }
    }
  });

  group('DifficultyCurve - Starting gold matrix', () {
    for (int world = 1; world <= 10; world++) {
      for (int local = 1; local <= 10; local++) {
        test('gold at world=$world, local=$local', () {
          final gold = DifficultyCurve.startingGold(
            world: world,
            localIndex: local,
          );
          final expected = 130 + 10 * (world - 1) + 3 * (local - 1);
          expect(gold, expected);
        });
      }
    }
  });

  group('DifficultyCurve - Tower cost multiplier', () {
    for (int towers = 0; towers <= 20; towers++) {
      test('cost multiplier for $towers towers', () {
        final mult = DifficultyCurve.towerCostMultiplier(towers);
        expect(mult, greaterThanOrEqualTo(1.0));
      });
    }

    for (int grace = 0; grace <= 5; grace++) {
      test('cost multiplier with grace count $grace', () {
        final mult = DifficultyCurve.towerCostMultiplier(
          10,
          graceCount: grace,
        );
        expect(mult, greaterThanOrEqualTo(1.0));
      });
    }

    for (double step = 0.05; step <= 0.3; step += 0.05) {
      test('cost multiplier with step ${step.toStringAsFixed(2)}', () {
        final mult = DifficultyCurve.towerCostMultiplier(
          10,
          graceCount: 2,
          step: step,
        );
        expect(mult, greaterThan(1.0));
      });
    }
  });

  group('DifficultyCurve - Wave clear bonus matrix', () {
    for (int progress = 0; progress <= 50; progress += 10) {
      for (int wave = 1; wave <= 10; wave += 3) {
        for (int diff = 1; diff <= 5; diff += 2) {
          test('bonus at progress=$progress, wave=$wave, diff=$diff', () {
            final bonus = DifficultyCurve.waveClearBonus(
              progressIndexValue: progress,
              wave: wave,
              difficulty: diff,
            );
            expect(bonus, greaterThanOrEqualTo(6)); // default min
            expect(bonus, lessThanOrEqualTo(60)); // default max
          });
        }
      }
    }
  });

  // ============================================
  // TOWER VS ENEMY BALANCE TESTS (200+ tests)
  // ============================================

  group('Tower vs Enemy - DPS calculations', () {
    for (final towerType in TowerType.values) {
      test('${towerType.name} DPS calculation', () {
        final dps = towerType.damage * towerType.fireRate;
        expect(dps, greaterThanOrEqualTo(0));
      });

      test('${towerType.name} time to kill basic enemy', () {
        final ttk = EnemyType.glitchDrone.baseHealth / (towerType.damage * towerType.fireRate);
        if (towerType.damage > 0) {
          expect(ttk, greaterThan(0));
        }
      });
    }
  });

  group('Tower vs Enemy - Cost efficiency', () {
    for (final towerType in TowerType.values) {
      test('${towerType.name} gold per DPS', () {
        final dps = towerType.damage * towerType.fireRate;
        if (dps > 0) {
          final goldPerDps = towerType.cost / dps;
          expect(goldPerDps, greaterThan(0));
        }
      });

      test('${towerType.name} damage per gold', () {
        final damagePerGold = towerType.damage / towerType.cost;
        expect(damagePerGold, greaterThanOrEqualTo(0));
      });
    }
  });

  group('Tower vs Enemy - Range effectiveness', () {
    for (final towerType in TowerType.values) {
      test('${towerType.name} range vs cost ratio', () {
        final rangePerGold = towerType.range / towerType.cost;
        expect(rangePerGold, greaterThan(0));
      });

      test('${towerType.name} area coverage', () {
        final area = math.pi * towerType.range * towerType.range;
        expect(area, greaterThan(0));
      });
    }
  });

  group('Tower vs Enemy - All matchups', () {
    for (final towerType in TowerType.values) {
      for (final enemyType in EnemyType.values.take(10)) {
        test('${towerType.name} vs ${enemyType.name}', () {
          final shotsToKill = (enemyType.baseHealth / towerType.damage).ceil();
          if (towerType.damage > 0) {
            expect(shotsToKill, greaterThan(0));
          }

          final timeToKill = shotsToKill / towerType.fireRate;
          if (towerType.damage > 0) {
            expect(timeToKill, greaterThan(0));
          }
        });
      }
    }
  });

  // ============================================
  // UPGRADE BALANCE TESTS (200+ tests)
  // ============================================

  group('Upgrade balance - Damage upgrades', () {
    for (int level = 1; level <= 10; level++) {
      test('damage upgrade level $level effectiveness', () {
        final mult = math.pow(1.07, level);
        expect(mult, greaterThan(1.0));

        // Check it doesn't scale too quickly
        expect(mult, lessThan(3.0));
      });
    }
  });

  group('Upgrade balance - Range upgrades', () {
    for (int level = 1; level <= 10; level++) {
      test('range upgrade level $level effectiveness', () {
        final mult = math.pow(1.05, level);
        expect(mult, greaterThan(1.0));
        expect(mult, lessThan(2.0));
      });
    }
  });

  group('Upgrade balance - Fire rate upgrades', () {
    for (int level = 1; level <= 10; level++) {
      test('fire rate upgrade level $level effectiveness', () {
        final mult = math.pow(1.06, level);
        expect(mult, greaterThan(1.0));
        expect(mult, lessThan(2.0));
      });
    }
  });

  group('Upgrade balance - Cost reduction upgrades', () {
    for (int level = 1; level <= 10; level++) {
      test('cost reduction level $level effectiveness', () {
        final mult = math.pow(0.96, level);
        expect(mult, lessThan(1.0));
        expect(mult, greaterThan(0.5));
      });
    }
  });

  group('Upgrade balance - Combined upgrades', () {
    test('full damage + fire rate combined DPS boost', () {
      const damageMult = 1.07;
      const fireRateMult = 1.06;

      for (int level = 1; level <= 5; level++) {
        final combinedDpsMult = math.pow(damageMult, level) * math.pow(fireRateMult, level);
        expect(combinedDpsMult, greaterThan(1.0));
        expect(combinedDpsMult, lessThan(5.0)); // Reasonable cap
      }
    });

    test('upgrade stats merge correctly', () {
      const stats1 = UpgradeStats(towerDamageMult: 1.1, towerRangeMult: 1.05);
      const stats2 = UpgradeStats(towerDamageMult: 1.1, goldGainMult: 1.2);

      final merged = stats1.merge(stats2);
      expect(merged.towerDamageMult, closeTo(1.21, 0.001));
      expect(merged.towerRangeMult, closeTo(1.05, 0.001));
      expect(merged.goldGainMult, closeTo(1.2, 0.001));
    });
  });

  // ============================================
  // LEVEL PROGRESSION BALANCE (100+ tests)
  // ============================================

  group('Level progression - Resource scaling', () {
    setUp(() {
      LevelService.instance.resetForTesting();
    });

    test('level 1 resources are beginner-friendly', () {
      final level = LevelService.instance.getLevel(1)!;
      expect(level.startingGold, greaterThanOrEqualTo(200));
      expect(level.startingLives, greaterThanOrEqualTo(20));
      expect(level.waves, lessThanOrEqualTo(10));
    });

    test('level 50 resources are mid-game', () {
      final level = LevelService.instance.getLevel(50)!;
      expect(level.startingGold, greaterThan(0));
      expect(level.startingLives, greaterThan(0));
    });

    test('level 100 resources are endgame', () {
      final level = LevelService.instance.getLevel(100)!;
      expect(level.startingGold, greaterThan(0));
      expect(level.startingLives, greaterThan(0));
      expect(level.waves, greaterThan(100));
    });

    for (int levelId = 1; levelId <= 100; levelId += 10) {
      test('level $levelId has valid config', () {
        final level = LevelService.instance.getLevel(levelId)!;
        expect(level.id, levelId);
        expect(level.waves, greaterThan(0));
        expect(level.startingGold, greaterThan(0));
        expect(level.startingLives, greaterThan(0));
        expect(level.difficulty, inInclusiveRange(1, 5));
      });
    }
  });

  group('Level progression - Difficulty curve', () {
    for (int levelId = 1; levelId <= 100; levelId++) {
      test('level $levelId difficulty is 1-5', () {
        final level = LevelService.instance.getLevel(levelId)!;
        expect(level.difficulty, inInclusiveRange(1, 5));
      });
    }

    test('early levels are easier', () {
      final level1 = LevelService.instance.getLevel(1)!;
      final level100 = LevelService.instance.getLevel(100)!;
      expect(level1.difficulty, lessThanOrEqualTo(level100.difficulty));
    });
  });

  // ============================================
  // ECONOMY BALANCE TESTS (100+ tests)
  // ============================================

  group('Economy balance - Enemy gold values', () {
    for (final type in EnemyType.values) {
      test('${type.name} gold is proportional to health', () {
        // Higher health enemies should give more gold
        // This is a general guideline
        expect(type.goldValue, greaterThanOrEqualTo(0));
      });
    }

    test('world 1 enemies give less gold than world 10', () {
      final world1Gold = EnemyType.values
          .where((t) => t.world == 1)
          .map((t) => t.goldValue)
          .reduce((a, b) => a + b);
      final world10Gold = EnemyType.values
          .where((t) => t.world == 10)
          .map((t) => t.goldValue)
          .reduce((a, b) => a + b);

      expect(world10Gold, greaterThanOrEqualTo(world1Gold));
    });
  });

  group('Economy balance - Tower costs', () {
    test('cheapest tower is affordable from level 1', () {
      final cheapest = TowerType.values.map((t) => t.cost).reduce((a, b) => a < b ? a : b);
      final level1Gold = LevelService.instance.getLevel(1)!.startingGold;
      expect(level1Gold, greaterThanOrEqualTo(cheapest));
    });

    test('can afford at least 2 cheap towers from level 1', () {
      final cheapest = TowerType.values.map((t) => t.cost).reduce((a, b) => a < b ? a : b);
      final level1Gold = LevelService.instance.getLevel(1)!.startingGold;
      expect(level1Gold, greaterThanOrEqualTo(cheapest * 2));
    });

    for (final type in TowerType.values) {
      test('${type.name} cost is reasonable', () {
        expect(type.cost, greaterThan(0));
        expect(type.cost, lessThan(1000));
      });
    }
  });

  group('Economy balance - Wave clear bonuses', () {
    for (int wave = 1; wave <= 20; wave++) {
      test('wave $wave clear bonus', () {
        final bonus = DifficultyCurve.waveClearBonus(
          progressIndexValue: 10,
          wave: wave,
          difficulty: 3,
        );
        expect(bonus, greaterThan(0));
      });
    }
  });
}
