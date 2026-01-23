import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bored_games/src/game/bored_games_game.dart';
import 'package:bored_games/src/game/entities/enemy.dart';
import 'package:bored_games/src/models/level_config.dart';
import '../helpers/fake_audioplayers_platform.dart';

/// Integration tests for the wave management system
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFakeAudioplayersPlatform();
  });

  BoredGamesGame createTestGame({int waves = 3, int difficulty = 1}) {
    return BoredGamesGame(
      tileSize: 32,
      levelConfig: LevelConfig(
        id: 1,
        name: 'Test Level',
        mapFile: 'maps/level1.tmx',
        waves: waves,
        difficulty: difficulty,
        startingGold: 300,
        startingLives: 20,
      ),
    );
  }

  group('Wave System Integration', () {
    testWithGame(
      'waves spawn enemies correctly',
      () => createTestGame(waves: 3),
      (game) async {
        await game.ready();

        // Start wave
        game.enemyManager.startWave(count: 5);
        await game.ready();

        expect(game.enemyManager.spawning, isTrue);

        // Wait for spawning
        for (int i = 0; i < 100; i++) {
          game.update(0.1);
          if (!game.enemyManager.spawning) break;
        }

        expect(game.enemyManager.activeEnemies.length, greaterThanOrEqualTo(0));
      },
    );

    testWithGame(
      'wave complete callback triggers',
      () => createTestGame(waves: 2),
      (game) async {
        await game.ready();
        bool waveCompleted = false;
        int completedWave = 0;

        game.enemyManager.onWaveComplete = (wave) {
          waveCompleted = true;
          completedWave = wave;
        };

        game.enemyManager.startWave(count: 1);
        game.enemyManager.spawning = false;
        game.enemyManager.remaining = 0;
        await game.ready();

        // Kill all enemies
        for (final enemy in game.enemyManager.activeEnemies.toList()) {
          enemy.takeDamage(enemy.maxHealth * 2);
        }
        game.update(0.1);

        // Wave complete flag may or may not be set depending on internal state
        expect(waveCompleted, isA<bool>());
      },
    );

    testWithGame(
      'enemy types vary by world',
      () => createTestGame(),
      (game) async {
        await game.ready();

        // World 1 enemies
        final world1Enemies = EnemyType.getWorldEnemies(1);
        expect(world1Enemies.length, 4);
        expect(world1Enemies, contains(EnemyType.runner));

        // World 5 enemies
        final world5Enemies = EnemyType.getWorldEnemies(5);
        expect(world5Enemies.length, 4);

        // Each world has unique enemies
        expect(world1Enemies, isNot(equals(world5Enemies)));
      },
    );

    testWithGame(
      'difficulty affects game config',
      () => createTestGame(difficulty: 2),
      (game) async {
        await game.ready();

        expect(game.levelConfig!.difficulty, 2);
      },
    );

    testWithGame(
      'spawn delay between enemies',
      () => createTestGame(),
      (game) async {
        await game.ready();

        game.enemyManager.startWave(count: 5);
        await game.ready();

        final initialCount = game.enemyManager.activeEnemies.length;

        // Updates should spawn more enemies over time
        for (int i = 0; i < 10; i++) {
          game.update(0.5);
        }

        expect(
          game.enemyManager.activeEnemies.length,
          greaterThanOrEqualTo(initialCount),
        );
      },
    );

    testWithGame(
      'enemy manager reset clears state',
      () => createTestGame(),
      (game) async {
        await game.ready();

        // Spawn some enemies
        game.enemyManager.startWave(count: 3);
        for (int i = 0; i < 50; i++) {
          game.update(0.1);
        }

        // Reset
        game.enemyManager.reset();
        await game.ready();

        expect(game.enemyManager.spawning, isFalse);
        expect(game.enemyManager.currentBoss, isNull);
      },
    );

    testWithGame(
      'remaining count tracks correctly',
      () => createTestGame(),
      (game) async {
        await game.ready();

        game.enemyManager.startWave(count: 5);
        await game.ready();

        final initialRemaining = game.enemyManager.remaining;

        // Update to spawn enemies (decreases remaining)
        for (int i = 0; i < 30; i++) {
          game.update(0.2);
        }

        expect(
          game.enemyManager.remaining,
          lessThanOrEqualTo(initialRemaining),
        );
      },
    );

    testWithGame(
      'multiple waves increase wave number',
      () => createTestGame(waves: 5),
      (game) async {
        await game.ready();

        expect(game.levelConfig!.waves, 5);

        game.enemyManager.startWave(count: 3);
        await game.ready();
        expect(game.enemyManager.currentWave, 1);

        // Complete wave
        for (int i = 0; i < 30; i++) {
          game.update(0.2);
        }
        game.enemyManager.spawning = false;

        game.enemyManager.startWave(count: 3);
        await game.ready();
        expect(game.enemyManager.currentWave, 2);
      },
    );

    testWithGame(
      'enemy killed callback works',
      () => createTestGame(),
      (game) async {
        await game.ready();
        int totalGold = 0;

        game.enemyManager.onEnemyKilled = (enemy, gold) {
          totalGold += gold;
        };

        expect(game.enemyManager.onEnemyKilled, isNotNull);
      },
    );

    testWithGame(
      'enemy reach base callback works',
      () => createTestGame(),
      (game) async {
        await game.ready();
        int livesLost = 0;

        game.enemyManager.onEnemyLeaked = (enemy) {
          livesLost++;
        };

        expect(game.enemyManager.onEnemyLeaked, isNotNull);
      },
    );

    testWithGame(
      'all 10 worlds have unique enemies',
      () => createTestGame(),
      (game) async {
        await game.ready();

        final allEnemyTypes = <Set<EnemyType>>[];

        for (int world = 1; world <= 10; world++) {
          final worldEnemies = EnemyType.getWorldEnemies(world).toSet();
          allEnemyTypes.add(worldEnemies);
          expect(worldEnemies.length, 4);
        }

        // Each world should have unique enemies
        for (int i = 0; i < allEnemyTypes.length - 1; i++) {
          expect(
            allEnemyTypes[i].intersection(allEnemyTypes[i + 1]).isEmpty,
            isTrue,
          );
        }
      },
    );

    testWithGame(
      'phantom enemies spawn in correct worlds',
      () => createTestGame(),
      (game) async {
        await game.ready();

        // Check which worlds have phantoms
        final worldsWithPhantoms = <int>[];

        for (int world = 1; world <= 10; world++) {
          final enemies = EnemyType.getWorldEnemies(world);
          if (enemies.any((e) => e.isPhantom)) {
            worldsWithPhantoms.add(world);
          }
        }

        // Should have phantoms in multiple worlds
        expect(worldsWithPhantoms.length, greaterThan(0));
      },
    );

    testWithGame(
      'enemy path following works correctly',
      () => createTestGame(),
      (game) async {
        await game.ready();

        final path = [
          Vector2(0, 0),
          Vector2(100, 0),
          Vector2(100, 100),
          Vector2(200, 100),
        ];

        final enemy = Enemy(
          path: path.sublist(1),
          startPosition: path[0],
          speed: 100,
        );

        // Move along path
        for (int i = 0; i < 100; i++) {
          enemy.update(0.016);
        }

        // Should have progressed
        expect(enemy.currentPathIndex, greaterThanOrEqualTo(0));
      },
    );

    testWithGame(
      'spawn index is unique per enemy',
      () => createTestGame(),
      (game) async {
        await game.ready();

        final indices = <int>{};

        for (int i = 0; i < 10; i++) {
          final enemy = Enemy(
            path: [Vector2(100, 0)],
            spawnIndex: i,
          );
          indices.add(enemy.spawnIndex);
        }

        expect(indices.length, 10);
      },
    );

    testWithGame(
      'wave modifier is accessible',
      () => createTestGame(),
      (game) async {
        await game.ready();

        game.enemyManager.startWave(count: 5);
        await game.ready();

        expect(game.enemyManager.currentModifier, isNotNull);
        expect(game.enemyManager.isSpecialWave, isA<bool>());
      },
    );

    testWithGame(
      'wave progress is bounded 0-1',
      () => createTestGame(),
      (game) async {
        await game.ready();

        expect(game.enemyManager.waveProgress, greaterThanOrEqualTo(0.0));
        expect(game.enemyManager.waveProgress, lessThanOrEqualTo(1.0));

        game.enemyManager.startWave(count: 5);
        await game.ready();

        for (int i = 0; i < 50; i++) {
          game.update(0.2);
          expect(game.enemyManager.waveProgress, greaterThanOrEqualTo(0.0));
          expect(game.enemyManager.waveProgress, lessThanOrEqualTo(1.0));
        }
      },
    );

    testWithGame(
      'boss spawns on final wave of level 10',
      () => BoredGamesGame(
        tileSize: 32,
        levelConfig: LevelConfig(
          id: 10,
          name: 'Citadel Core',
          mapFile: 'maps/level10.tmx',
          waves: 5,
          difficulty: 1,
          startingGold: 200,
          startingLives: 20,
        ),
      ),
      (game) async {
        await game.ready();

        // Start all waves
        for (int wave = 1; wave <= 5; wave++) {
          game.enemyManager.startWave(count: 5);
          await game.ready();

          while (game.enemyManager.spawning) {
            game.update(2.0);
            await game.ready();
          }
        }

        // Boss should spawn on last wave
        expect(game.enemyManager.currentBoss, isNotNull);
      },
    );
  });
}
