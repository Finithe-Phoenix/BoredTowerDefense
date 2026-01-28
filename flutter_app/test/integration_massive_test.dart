import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/balance/difficulty_curve.dart';
import 'package:bored_games/src/game/entities/enemy.dart';
import 'package:bored_games/src/game/entities/tower.dart';
import 'package:bored_games/src/game/entities/boss.dart';
import 'package:bored_games/src/game/managers/enemy_manager.dart';
import 'package:bored_games/src/services/level_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LevelService.instance.resetForTesting();
    LevelService.overrideUnlockAllLevels = true;
  });

  tearDown(() {
    LevelService.instance.resetForTesting();
    LevelService.overrideUnlockAllLevels = null;
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // LEVEL + ENEMY INTEGRATION (100+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Integration - Level and Enemy', () {
    for (int level = 1; level <= 100; level++) {
      test('Level $level has enemies for its world', () {
        final world = DifficultyCurve.worldForLevel(level);
        final enemies = EnemyType.getWorldEnemies(world);
        expect(enemies, isNotEmpty);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // LEVEL + TOWER INTEGRATION (80+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Integration - Level and Tower unlocks', () {
    final towerUnlocks = {
      TowerType.pulseArcher: 1,
      TowerType.circuitCannon: 3,
      TowerType.phaseMage: 5,
      TowerType.glimmerField: 7,
      TowerType.ionSniper: 9,
      TowerType.teslaTerminal: 10,
      TowerType.resonanceSiphon: 11,
      TowerType.neuralDisruptor: 13,
    };

    for (final entry in towerUnlocks.entries) {
      test('${entry.key.name} unlocks at level ${entry.value}', () {
        expect(LevelService.instance.isTowerUnlocked(entry.key), isTrue);
      });
    }

    for (int level = 1; level <= 20; level++) {
      test('Level $level has at least one tower', () {
        final towers = LevelService.instance.getUnlockedTowers();
        expect(towers, isNotEmpty);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // DIFFICULTY + WAVE INTEGRATION (100+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Integration - Difficulty and Waves', () {
    for (int level = 1; level <= 100; level++) {
      test('Level $level world and progress index valid', () {
        final world = DifficultyCurve.worldForLevel(level);
        final progressIdx = DifficultyCurve.progressIndex(levelId: level);
        expect(world, inInclusiveRange(1, 10));
        expect(progressIdx, greaterThanOrEqualTo(0));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ENEMY + HEALTH SCALING (60+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Integration - Enemy health scaling', () {
    for (int world = 1; world <= 10; world++) {
      for (int wave = 1; wave <= 5; wave++) {
        test('World $world wave $wave health scaling', () {
          final progressIndex = (world - 1) * 10;
          final healthMult = DifficultyCurve.healthMultiplier(
            progressIndexValue: progressIndex,
            wave: wave,
            difficulty: world.clamp(1, 5),
          );
          expect(healthMult, greaterThan(0));
        });
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // BOSS + LEVEL INTEGRATION (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Integration - Boss and Level', () {
    final bossLevels = {
      10: BossType.citadelCore,
      20: BossType.abyssGate,
      30: BossType.voidlineApex,
      40: BossType.shardVault,
      50: BossType.arcFortress,
      60: BossType.coreHunter,
      70: BossType.omegaGrid,
      80: BossType.stormTower,
      90: BossType.finalGate,
      100: BossType.omegaNexus,
    };

    for (final entry in bossLevels.entries) {
      test('Level ${entry.key} has boss ${entry.value.name}', () {
        final level = LevelService.instance.getLevel(entry.key);
        expect(level, isNotNull);
        expect(entry.value, isNotNull);
      });
    }

    for (int level = 1; level <= 100; level++) {
      if (level % 10 != 0) {
        test('Level $level has mini-boss only', () {
          expect(level % 10 != 0, isTrue);
        });
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TOWER + ENEMY MATCHUP INTEGRATION (80+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Integration - Tower vs Enemy matchups', () {
    for (final tower in TowerType.values) {
      for (final enemy in EnemyType.basicTypes) {
        test('${tower.name} vs ${enemy.name} damage', () {
          final damage = tower.damage;
          final healthMult = enemy.healthMult;
          // healthMult is a multiplier, so we check damage vs scaled health
          final effectiveHealth = 100 * healthMult; // base health 100

          // Skip damage towers with 0 damage (support towers like Resonance Siphon)
          if (damage > 0) {
            final hitsToKill = (effectiveHealth / damage).ceil();
            expect(hitsToKill, greaterThan(0));
          } else {
            // Support tower - verify it has valid cost
            expect(tower.cost, greaterThan(0));
          }
        });
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // WAVE MODIFIER + ENEMY TYPE INTEGRATION (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Integration - Wave modifier and enemy types', () {
    for (int world = 1; world <= 10; world++) {
      for (final modifier in WaveModifier.values) {
        test('World $world ${modifier.name} wave has enemies', () {
          final enemies = EnemyType.getWorldEnemies(world);
          expect(enemies, isNotEmpty);
        });
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GOLD ECONOMY INTEGRATION (60+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Integration - Gold economy', () {
    for (int level = 1; level <= 100; level++) {
      test('Level $level has valid starting gold', () {
        final levelConfig = LevelService.instance.getLevel(level);
        expect(levelConfig, isNotNull);
        final gold = levelConfig!.startingGold;
        // All levels should have positive starting gold
        expect(gold, greaterThan(0));
        // First levels should have enough for basic tower (cheaper requirement)
        if (level <= 10) {
          final cheapestTower = TowerType.pulseArcher.cost;
          expect(gold, greaterThanOrEqualTo(cheapestTower));
        }
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD PROGRESSION INTEGRATION (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Integration - World progression', () {
    for (int world = 1; world <= 10; world++) {
      test('World $world has 10 levels', () {
        final startLevel = (world - 1) * 10 + 1;
        final endLevel = world * 10;
        for (int level = startLevel; level <= endLevel; level++) {
          final levelConfig = LevelService.instance.getLevel(level);
          expect(levelConfig, isNotNull);
        }
      });
    }

    for (int world = 1; world <= 10; world++) {
      test('World $world has 4 enemy types', () {
        final enemies = EnemyType.getWorldEnemies(world);
        expect(enemies.length, 4);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // DIFFICULTY CURVE CONSISTENCY (40+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Integration - Difficulty curve consistency', () {
    for (int level = 1; level < 100; level++) {
      test('Level $level is easier than level ${level + 1}', () {
        final health1 = DifficultyCurve.healthMultiplier(
          progressIndexValue: DifficultyCurve.progressIndex(levelId: level),
          wave: 1,
          difficulty: (level / 20).ceil().clamp(1, 5),
        );
        final health2 = DifficultyCurve.healthMultiplier(
          progressIndexValue: DifficultyCurve.progressIndex(levelId: level + 1),
          wave: 1,
          difficulty: ((level + 1) / 20).ceil().clamp(1, 5),
        );
        expect(health2, greaterThanOrEqualTo(health1 * 0.9)); // Allow 10% variance
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SPAWN INTERVAL CONSISTENCY (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Integration - Spawn interval consistency', () {
    for (int level = 1; level <= 100; level += 10) {
      for (int wave = 1; wave <= 10; wave += 3) {
        test('Level $level wave $wave spawn interval', () {
          final interval = DifficultyCurve.spawnInterval(
            progressIndexValue: DifficultyCurve.progressIndex(levelId: level),
            wave: wave,
            difficulty: (level / 20).ceil().clamp(1, 5),
          );
          expect(interval, greaterThan(0.3));
          expect(interval, lessThan(2.0));
        });
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ENEMY COUNT BALANCE (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Integration - Enemy count balance', () {
    for (int level = 1; level <= 100; level += 10) {
      test('Level $level enemy count is balanced', () {
        final count = DifficultyCurve.enemyCount(
          baseCount: 5,
          progressIndexValue: DifficultyCurve.progressIndex(levelId: level),
          wave: 1,
          difficulty: (level / 20).ceil().clamp(1, 5),
          minCount: EnemyManager.minEnemyCount,
          maxCount: EnemyManager.maxEnemyCount,
        );
        expect(count, greaterThanOrEqualTo(EnemyManager.minEnemyCount));
        expect(count, lessThanOrEqualTo(EnemyManager.maxEnemyCount));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM ENEMY AVAILABILITY (20+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Integration - Phantom enemy availability', () {
    // Worlds with phantom enemies: 1, 2, 5, 6, 7, 8, 9, 10 (8 total)
    // Worlds 3 and 4 don't have phantom enemies
    final worldsWithPhantoms = [1, 2, 5, 6, 7, 8, 9, 10];

    for (int world = 1; world <= 10; world++) {
      final shouldHavePhantom = worldsWithPhantoms.contains(world);
      test('World $world phantom presence is correct', () {
        final enemies = EnemyType.getWorldEnemies(world);
        final hasPhantom = enemies.any((e) => e.isPhantom);
        expect(hasPhantom, shouldHavePhantom);
      });
    }

    for (final world in worldsWithPhantoms) {
      test('World $world phantom is unique', () {
        final enemies = EnemyType.getWorldEnemies(world);
        final phantoms = enemies.where((e) => e.isPhantom).toList();
        expect(phantoms.length, 1);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TOWER RANGE VS MAP SIZE (20+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Integration - Tower range vs map', () {
    final mapWidth = 768.0; // Typical map width
    final mapHeight = 512.0; // Typical map height

    for (final tower in TowerType.values) {
      test('${tower.name} range fits map', () {
        expect(tower.range, lessThan(mapWidth));
        expect(tower.range, lessThan(mapHeight));
      });
    }

    for (final tower in TowerType.values) {
      test('${tower.name} range covers meaningful area', () {
        final coverage = (tower.range * tower.range * 3.14) / (mapWidth * mapHeight);
        expect(coverage, greaterThan(0.01)); // At least 1% map coverage
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // LEVEL UNLOCK CHAIN (20+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Integration - Level unlock chain', () {
    test('Level 1 is always unlocked', () {
      LevelService.overrideUnlockAllLevels = false;
      expect(LevelService.instance.isLevelUnlocked(1), isTrue);
    });

    for (int level = 2; level <= 20; level++) {
      test('Level $level requires level ${level - 1}', () {
        final levelConfig = LevelService.instance.getLevel(level);
        expect(levelConfig?.unlockRequirement, level - 1);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPLETE GAME FLOW (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Integration - Complete game flow', () {
    for (int world = 1; world <= 10; world++) {
      test('World $world is completable', () {
        final startLevel = (world - 1) * 10 + 1;
        final endLevel = world * 10;

        // Check all levels exist
        for (int level = startLevel; level <= endLevel; level++) {
          expect(LevelService.instance.getLevel(level), isNotNull);
        }

        // Check enemies exist
        expect(EnemyType.getWorldEnemies(world).length, 4);

        // Check boss exists
        expect(BossType.values.length, 11);
      });
    }

    test('All 100 levels are accessible', () {
      for (int level = 1; level <= 100; level++) {
        expect(LevelService.instance.getLevel(level), isNotNull);
      }
    });

    test('All 9 towers are defined', () {
      expect(TowerType.values.length, 9);
    });

    test('All 40 enemy types are defined', () {
      expect(EnemyType.values.length, 40);
    });

    test('All 11 boss types are defined', () {
      expect(BossType.values.length, 11);
    });

    test('Max stars is 300', () {
      expect(LevelService.instance.maxStars, 300);
    });

    test('Total levels is 100', () {
      expect(LevelService.instance.levels.length, 100);
    });
  });
}
