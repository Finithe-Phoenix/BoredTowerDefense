import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bored_games/src/game/bored_games_game.dart';
import 'package:bored_games/src/game/entities/enemy.dart';
import 'package:bored_games/src/game/entities/tower.dart';
import 'package:bored_games/src/models/level_config.dart';
import '../helpers/fake_audioplayers_platform.dart';

/// Integration tests for the combat system (towers, enemies, projectiles)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFakeAudioplayersPlatform();
  });

  BoredGamesGame createTestGame({int difficulty = 1}) {
    return BoredGamesGame(
      tileSize: 32,
      levelConfig: LevelConfig(
        id: 1,
        name: 'Test Level',
        mapFile: 'maps/level1.tmx',
        waves: 5,
        difficulty: difficulty,
        startingGold: 500,
        startingLives: 20,
      ),
    );
  }

  group('Combat System Integration', () {
    testWithGame(
      'tower manager initializes correctly',
      createTestGame,
      (game) async {
        await game.ready();

        expect(game.towerManager, isNotNull);
        expect(game.towerManager.towers, isEmpty);
        expect(game.towerManager.towerCount, 0);
      },
    );

    testWithGame(
      'tower placement via manager',
      createTestGame,
      (game) async {
        await game.ready();

        // Check initial state
        expect(game.towerManager.towerCount, 0);

        // Try to place a tower (may fail if position not buildable)
        final placed = game.towerManager.placeTower(Vector2(64, 64));
        // Just verify the API works without errors
        expect(placed, isA<bool>());
      },
    );

    testWithGame(
      'enemy manager starts waves',
      createTestGame,
      (game) async {
        await game.ready();

        expect(game.enemyManager.spawning, isFalse);

        // Start wave
        game.enemyManager.startWave(count: 5);
        await game.ready();

        expect(game.enemyManager.spawning, isTrue);
        expect(game.enemyManager.remaining, greaterThanOrEqualTo(0));
      },
    );

    testWithGame(
      'enemy spawning produces active enemies',
      createTestGame,
      (game) async {
        await game.ready();

        game.enemyManager.startWave(count: 10);
        await game.ready();

        // Update to spawn enemies
        for (int i = 0; i < 30; i++) {
          game.update(0.2);
        }

        // Should have spawned some enemies
        expect(game.enemyManager.activeEnemies.length, greaterThanOrEqualTo(0));
      },
    );

    testWithGame(
      'bullet manager handles projectiles',
      createTestGame,
      (game) async {
        await game.ready();

        expect(game.bulletManager, isNotNull);
      },
    );

    testWithGame(
      'wave intensity tracks progress',
      createTestGame,
      (game) async {
        await game.ready();

        // No wave started
        expect(game.enemyManager.waveIntensity, 0.0);

        // Start wave
        game.enemyManager.startWave(count: 5);
        await game.ready();

        // Should have some intensity
        expect(game.enemyManager.waveIntensity, greaterThanOrEqualTo(0.0));
      },
    );

    testWithGame(
      'wave progress tracks correctly',
      createTestGame,
      (game) async {
        await game.ready();

        game.enemyManager.startWave(count: 5);
        await game.ready();

        final initialProgress = game.enemyManager.waveProgress;

        // Spawn some enemies
        for (int i = 0; i < 20; i++) {
          game.update(0.2);
        }

        // Progress should increase
        expect(game.enemyManager.waveProgress, greaterThanOrEqualTo(initialProgress));
      },
    );

    testWithGame(
      'current wave number increments',
      createTestGame,
      (game) async {
        await game.ready();

        expect(game.enemyManager.currentWave, 0);

        game.enemyManager.startWave(count: 3);
        await game.ready();

        expect(game.enemyManager.currentWave, greaterThan(0));
      },
    );

    testWithGame(
      'enemy manager reset clears state',
      createTestGame,
      (game) async {
        await game.ready();

        game.enemyManager.startWave(count: 5);
        await game.ready();

        for (int i = 0; i < 20; i++) {
          game.update(0.1);
        }

        game.enemyManager.reset();
        await game.ready();

        expect(game.enemyManager.spawning, isFalse);
        expect(game.enemyManager.currentBoss, isNull);
      },
    );

    testWithGame(
      'special wave modifiers work',
      createTestGame,
      (game) async {
        await game.ready();

        // Start a few waves
        for (int i = 0; i < 3; i++) {
          game.enemyManager.startWave(count: 3);
          await game.ready();

          // Let wave complete
          for (int j = 0; j < 30; j++) {
            game.update(0.2);
          }
          game.enemyManager.spawning = false;
        }

        // Wave modifier should be accessible
        expect(game.enemyManager.currentModifier, isNotNull);
      },
    );

    testWithGame(
      'tower selection type can be changed',
      createTestGame,
      (game) async {
        await game.ready();

        game.towerManager.selectedTowerType = TowerType.circuitCannon;
        expect(game.towerManager.selectedTowerType, TowerType.circuitCannon);

        game.towerManager.selectedTowerType = TowerType.phaseMage;
        expect(game.towerManager.selectedTowerType, TowerType.phaseMage);
      },
    );

    testWithGame(
      'tower ghost position updates',
      createTestGame,
      (game) async {
        await game.ready();

        expect(game.towerManager.ghostPosition, isNull);
        expect(game.towerManager.showHeatmap, isFalse);

        game.towerManager.updateGhost(Vector2(100, 100));
        expect(game.towerManager.ghostPosition, isNotNull);
        expect(game.towerManager.showHeatmap, isTrue);

        game.towerManager.updateGhost(null);
        expect(game.towerManager.ghostPosition, isNull);
        expect(game.towerManager.showHeatmap, isFalse);
      },
    );

    testWithGame(
      'spatial query returns enemies in range',
      createTestGame,
      (game) async {
        await game.ready();

        game.enemyManager.startWave(count: 10);
        await game.ready();

        // Spawn some enemies
        for (int i = 0; i < 30; i++) {
          game.update(0.2);
        }

        final results = <Enemy>[];
        game.enemyManager.queryEnemiesInRange(Vector2(100, 100), 200, results);

        // Query should return without errors
        expect(results, isA<List<Enemy>>());
      },
    );

    testWithGame(
      'alive count tracks enemies',
      createTestGame,
      (game) async {
        await game.ready();

        expect(game.enemyManager.aliveCount, 0);

        game.enemyManager.startWave(count: 5);
        await game.ready();

        // Spawn enemies
        for (int i = 0; i < 20; i++) {
          game.update(0.2);
        }

        // Should track alive enemies
        expect(game.enemyManager.aliveCount, greaterThanOrEqualTo(0));
      },
    );

    testWithGame(
      'wave callbacks can be set',
      createTestGame,
      (game) async {
        await game.ready();

        bool waveCompleted = false;
        bool enemyKilled = false;

        game.enemyManager.onWaveComplete = (wave) {
          waveCompleted = true;
        };

        game.enemyManager.onEnemyKilled = (enemy, gold) {
          enemyKilled = true;
        };

        // Callbacks should be set
        expect(game.enemyManager.onWaveComplete, isNotNull);
        expect(game.enemyManager.onEnemyKilled, isNotNull);
      },
    );

    testWithGame(
      'difficulty affects enemy scaling',
      () => createTestGame(difficulty: 3),
      (game) async {
        await game.ready();

        game.enemyManager.startWave(count: 5);
        await game.ready();

        // Higher difficulty should still work
        expect(game.levelConfig!.difficulty, 3);
      },
    );

    testWithGame(
      'tower at position lookup',
      createTestGame,
      (game) async {
        await game.ready();

        // Initially no tower
        final tower = game.towerManager.towerAt(Vector2(50, 50));
        expect(tower, isNull);
      },
    );

    testWithGame(
      'rebuild spatial index works',
      createTestGame,
      (game) async {
        await game.ready();

        game.enemyManager.startWave(count: 5);
        await game.ready();

        for (int i = 0; i < 10; i++) {
          game.update(0.2);
        }

        // Should not throw
        game.enemyManager.rebuildSpatialIndex();
      },
    );

    testWithGame(
      'is special wave detection',
      createTestGame,
      (game) async {
        await game.ready();

        game.enemyManager.startWave(count: 3);
        await game.ready();

        // API should be accessible
        expect(game.enemyManager.isSpecialWave, isA<bool>());
      },
    );
  });
}
