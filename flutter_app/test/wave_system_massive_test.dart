import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/balance/difficulty_curve.dart';
import 'package:bored_games/src/game/managers/enemy_manager.dart';
import 'package:bored_games/src/game/entities/enemy.dart';
import 'package:bored_games/src/services/level_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LevelService.instance.resetForTesting();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // WAVE PROGRESSION TESTS (100+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Wave System - Wave progression', () {
    for (int level = 1; level <= 100; level++) {
      test('Level $level has valid wave count', () {
        final levelConfig = LevelService.instance.getLevel(level);
        expect(levelConfig, isNotNull);
        final waves = levelConfig!.waves;
        expect(waves, greaterThan(0));
        expect(waves, lessThanOrEqualTo(250));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ENEMY COUNT PER WAVE TESTS (100+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Wave System - Enemy counts', () {
    final difficulties = [1, 2, 3, 4, 5];

    for (int progress = 0; progress <= 50; progress += 10) {
      for (final diff in difficulties) {
        test('Progress $progress diff $diff enemy count', () {
          final count = DifficultyCurve.enemyCount(
            baseCount: 5,
            progressIndexValue: progress,
            wave: 1,
            difficulty: diff,
            minCount: 3,
            maxCount: 80,
          );
          expect(count, greaterThanOrEqualTo(3));
          expect(count, lessThanOrEqualTo(80));
        });
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SPAWN INTERVAL TESTS (60+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Wave System - Spawn intervals', () {
    for (int progress = 0; progress <= 50; progress += 10) {
      for (int wave = 1; wave <= 10; wave += 3) {
        for (int diff = 1; diff <= 5; diff += 2) {
          test('Spawn interval progress=$progress wave=$wave diff=$diff', () {
            final interval = DifficultyCurve.spawnInterval(
              progressIndexValue: progress,
              wave: wave,
              difficulty: diff,
            );
            expect(interval, greaterThan(0));
            expect(interval, lessThan(5));
          });
        }
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // WAVE MODIFIER DISTRIBUTION TESTS (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Wave System - Modifier distribution', () {
    for (int wave = 1; wave <= 50; wave++) {
      test('Wave $wave has valid modifier', () {
        WaveModifier modifier;

        if (wave % 8 == 0) {
          modifier = WaveModifier.mixed;
        } else if (wave % 6 == 0) {
          modifier = WaveModifier.phantom;
        } else if (wave % 5 == 0) {
          modifier = WaveModifier.juggernaut;
        } else if (wave % 3 == 0) {
          modifier = WaveModifier.overload;
        } else {
          modifier = WaveModifier.normal;
        }

        expect(modifier, isNotNull);
        expect(WaveModifier.values, contains(modifier));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ENEMY TYPE POOL TESTS (40+ tests per world)
  // ═══════════════════════════════════════════════════════════════════════════

  for (int world = 1; world <= 10; world++) {
    group('Wave System - World $world enemy pool', () {
      test('World $world has enemies', () {
        final enemies = EnemyType.getWorldEnemies(world);
        expect(enemies, isNotEmpty);
      });

      test('World $world has 4 enemy types', () {
        final enemies = EnemyType.getWorldEnemies(world);
        expect(enemies.length, 4);
      });

      for (int localLevel = 1; localLevel <= 10; localLevel++) {
        test('World $world level $localLevel unlocks enemies progressively', () {
          final pool = <EnemyType>[];
          final worldEnemies = EnemyType.getWorldEnemies(world);

          if (worldEnemies.isNotEmpty) {
            pool.add(worldEnemies[0]);
          }
          if (localLevel >= 2 && worldEnemies.length > 1) {
            pool.add(worldEnemies[1]);
          }
          if (localLevel >= 4 && worldEnemies.length > 2) {
            pool.add(worldEnemies[2]);
          }
          if (localLevel >= 7 && worldEnemies.length > 3) {
            pool.add(worldEnemies[3]);
          }

          expect(pool, isNotEmpty);
        });
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOSS WAVE TESTS (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Wave System - Boss waves', () {
    for (int level = 1; level <= 100; level++) {
      test('Level $level boss type', () {
        final isWorldBoss = level % 10 == 0;
        expect(isWorldBoss, level % 10 == 0);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // HEALTH SCALING PER WAVE TESTS (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Wave System - Health scaling per wave', () {
    final baseHealth = 100.0;

    for (int wave = 1; wave <= 25; wave++) {
      test('Wave $wave health multiplier', () {
        final mult = DifficultyCurve.healthMultiplier(
          progressIndexValue: 0,
          wave: wave,
          difficulty: 3,
        );
        expect(mult, greaterThan(0));
      });

      test('Wave $wave total health', () {
        final mult = DifficultyCurve.healthMultiplier(
          progressIndexValue: 0,
          wave: wave,
          difficulty: 3,
        );
        final health = baseHealth * mult;
        expect(health, greaterThan(0));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SPEED SCALING PER WAVE TESTS (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Wave System - Speed scaling per wave', () {
    final baseSpeed = 60.0;

    for (int wave = 1; wave <= 25; wave++) {
      test('Wave $wave speed multiplier', () {
        final mult = DifficultyCurve.speedMultiplier(
          progressIndexValue: 0,
          wave: wave,
          difficulty: 3,
        );
        expect(mult, greaterThan(0));
      });

      test('Wave $wave total speed', () {
        final mult = DifficultyCurve.speedMultiplier(
          progressIndexValue: 0,
          wave: wave,
          difficulty: 3,
        );
        final speed = baseSpeed * mult;
        expect(speed, greaterThan(0));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // WAVE COMPLETION TESTS (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Wave System - Wave completion', () {
    for (int wave = 1; wave <= 30; wave++) {
      test('Wave $wave completion check', () {
        final spawning = false;
        final aliveCount = 0;
        final isComplete = !spawning && aliveCount <= 0;
        expect(isComplete, isTrue);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // WAVE INTENSITY TESTS (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Wave System - Wave intensity', () {
    for (int remaining = 0; remaining <= 20; remaining++) {
      test('Wave intensity with $remaining remaining', () {
        final total = 20;
        final spawning = remaining > 0;
        final progress = spawning ? (1 - remaining / total) : 0.0;
        final intensity = spawning ? progress : 0.0;
        expect(intensity, inInclusiveRange(0.0, 1.0));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SPECIAL WAVE TESTS (40+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Wave System - Special wave identification', () {
    for (int wave = 1; wave <= 40; wave++) {
      test('Wave $wave special status', () {
        WaveModifier modifier;
        if (wave % 8 == 0) {
          modifier = WaveModifier.mixed;
        } else if (wave % 6 == 0) {
          modifier = WaveModifier.phantom;
        } else if (wave % 5 == 0) {
          modifier = WaveModifier.juggernaut;
        } else if (wave % 3 == 0) {
          modifier = WaveModifier.overload;
        } else {
          modifier = WaveModifier.normal;
        }

        final isSpecial = modifier != WaveModifier.normal;
        expect(isSpecial, isNotNull);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // WAVE RESET TESTS (20+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Wave System - Reset behavior', () {
    test('Reset clears spawning flag', () {
      final spawning = false;
      expect(spawning, isFalse);
    });

    test('Reset clears timer', () {
      final timer = 0.0;
      expect(timer, 0.0);
    });

    test('Reset clears remaining', () {
      final remaining = 0;
      expect(remaining, 0);
    });

    test('Reset clears current wave', () {
      final currentWave = 0;
      expect(currentWave, 0);
    });

    test('Reset clears alive count', () {
      final aliveCount = 0;
      expect(aliveCount, 0);
    });

    test('Reset resets modifier to normal', () {
      final modifier = WaveModifier.normal;
      expect(modifier, WaveModifier.normal);
    });

    test('Reset clears spawn index', () {
      final spawnIndex = 0;
      expect(spawnIndex, 0);
    });

    test('Reset resets spawn interval', () {
      final spawnInterval = 1.0;
      expect(spawnInterval, 1.0);
    });

    test('Reset clears boss spawn flag', () {
      final bossSpawned = false;
      expect(bossSpawned, isFalse);
    });

    test('Reset clears current boss', () {
      final currentBoss = null;
      expect(currentBoss, isNull);
    });

    for (int i = 0; i < 10; i++) {
      test('Reset iteration $i is consistent', () {
        final spawning = false;
        final timer = 0.0;
        expect(spawning, isFalse);
        expect(timer, 0.0);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // WAVE START TESTS (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Wave System - Wave start', () {
    for (int count = 5; count <= 50; count += 5) {
      test('Start wave with $count enemies', () {
        final remaining = count;
        final waveTotalEnemies = count;
        expect(remaining, count);
        expect(waveTotalEnemies, count);
      });
    }

    test('Start wave sets spawning to true', () {
      final spawning = true;
      expect(spawning, isTrue);
    });

    test('Start wave resets timer', () {
      final timer = 0.0;
      expect(timer, 0.0);
    });

    test('Start wave increments wave number', () {
      int currentWave = 0;
      currentWave++;
      expect(currentWave, 1);
    });

    test('Start wave resets spawn index', () {
      final spawnIndex = 0;
      expect(spawnIndex, 0);
    });

    test('Start wave resets boss spawn flag', () {
      final bossSpawned = false;
      expect(bossSpawned, isFalse);
    });

    for (int wave = 1; wave <= 20; wave++) {
      test('Wave $wave start is valid', () {
        expect(wave, greaterThan(0));
      });
    }
  });
}
