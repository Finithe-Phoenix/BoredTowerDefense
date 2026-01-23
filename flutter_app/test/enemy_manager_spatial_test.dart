import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/enemy.dart';
import 'package:bored_games/src/game/managers/enemy_manager.dart';
import 'package:bored_games/src/game/world/game_world.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnemyManager creation', () {
    test('creates with required parameters', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      expect(manager.tileSize, 32);
      expect(manager.world, same(world));
    });

    test('initial currentWave is 0', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      expect(manager.currentWave, 0);
    });

    test('initial aliveCount is 0', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      expect(manager.aliveCount, 0);
    });

    test('initial currentModifier is normal', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      expect(manager.currentModifier, WaveModifier.normal);
    });

    test('initial activeEnemies is empty', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      expect(manager.activeEnemies, isEmpty);
    });

    test('initial currentBoss is null', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      expect(manager.currentBoss, isNull);
    });

    test('initial spawning is false', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      expect(manager.spawning, isFalse);
    });

    test('initial remaining is 0', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      expect(manager.remaining, 0);
    });
  });

  group('EnemyManager constants', () {
    test('baseHealth is 100', () {
      expect(EnemyManager.baseHealth, 100);
    });

    test('baseSpeed is 60', () {
      expect(EnemyManager.baseSpeed, 60);
    });

    test('baseGold is 10', () {
      expect(EnemyManager.baseGold, 10);
    });

    test('minEnemyCount is 3', () {
      expect(EnemyManager.minEnemyCount, 3);
    });

    test('maxEnemyCount is 80', () {
      expect(EnemyManager.maxEnemyCount, 80);
    });

    test('minGoldReward is 4', () {
      expect(EnemyManager.minGoldReward, 4);
    });
  });

  group('EnemyManager waveProgress', () {
    test('waveProgress is 0 when no enemies', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      expect(manager.waveProgress, 0.0);
    });

    test('waveProgress is clamped to 0-1', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      expect(manager.waveProgress, greaterThanOrEqualTo(0.0));
      expect(manager.waveProgress, lessThanOrEqualTo(1.0));
    });
  });

  group('EnemyManager waveIntensity', () {
    test('waveIntensity is 0 when not spawning', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      expect(manager.waveIntensity, 0.0);
    });
  });

  group('EnemyManager waveDescription', () {
    test('normal wave has empty description', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      expect(manager.waveDescription, '');
    });
  });

  group('EnemyManager isSpecialWave', () {
    test('normal wave is not special', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      expect(manager.isSpecialWave, isFalse);
    });
  });

  group('EnemyManager reset', () {
    test('reset resets all state', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      manager.reset();

      expect(manager.currentWave, 0);
      expect(manager.aliveCount, 0);
      expect(manager.spawning, isFalse);
      expect(manager.remaining, 0);
      expect(manager.currentModifier, WaveModifier.normal);
      expect(manager.currentBoss, isNull);
      expect(manager.activeEnemies, isEmpty);
    });

    test('reset can be called multiple times', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      manager.reset();
      manager.reset();
      manager.reset();

      expect(manager.currentWave, 0);
    });
  });

  group('EnemyManager callbacks', () {
    test('callbacks can be set', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
        onEnemyKilled: (e, g) {},
        onEnemyLeaked: (e) {},
        onWaveComplete: (w) {},
        onBossSpawn: (n) {},
        onBossPhaseChange: (n, p) {},
      );

      expect(manager.onEnemyKilled, isNotNull);
      expect(manager.onEnemyLeaked, isNotNull);
      expect(manager.onWaveComplete, isNotNull);
      expect(manager.onBossSpawn, isNotNull);
      expect(manager.onBossPhaseChange, isNotNull);
    });
  });

  group('EnemyManager queryEnemiesInRange', () {
    test('queryEnemiesInRange returns empty list when no enemies', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      final result = <Enemy>[];
      manager.queryEnemiesInRange(Vector2(100, 100), 100, result);

      expect(result, isEmpty);
    });
  });

  group('EnemyManager rebuildSpatialIndex', () {
    test('rebuildSpatialIndex does not throw when empty', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      expect(() => manager.rebuildSpatialIndex(), returnsNormally);
    });
  });

  group('EnemyManager.clearBucketPool', () {
    test('clearBucketPool is static and can be called', () {
      expect(() => EnemyManager.clearBucketPool(), returnsNormally);
    });
  });

  group('EnemyManager Component', () {
    test('EnemyManager is a Component', () {
      final world = GameWorld(tileSize: 32, mapFile: 'test.tmx');
      final manager = EnemyManager(
        tileSize: 32,
        world: world,
      );

      expect(manager, isA<Component>());
    });
  });
}
