import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/enemy.dart';
import 'package:bored_games/src/game/managers/enemy_manager.dart';
import 'package:bored_games/src/game/world/game_world.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GameWorld _world() => GameWorld(tileSize: 32, mapFile: 'maps/level1.tmx');

  test('queryEnemiesInRange returns nearby enemies only', () {
    final manager = EnemyManager(tileSize: 32, world: _world());

    final nearEnemy = Enemy(path: const []);
    nearEnemy.position = Vector2(10, 10);
    final farEnemy = Enemy(path: const []);
    farEnemy.position = Vector2(200, 200);

    manager.activeEnemies.addAll([nearEnemy, farEnemy]);
    manager.rebuildSpatialIndex();

    final results = <Enemy>[];
    manager.queryEnemiesInRange(Vector2.zero(), 50, results);

    expect(results, contains(nearEnemy));
    expect(results, isNot(contains(farEnemy)));
  });

  test('spatial index updates as enemies move', () {
    final manager = EnemyManager(tileSize: 32, world: _world());
    final enemy = Enemy(path: const []);
    enemy.position = Vector2(5, 5);
    manager.activeEnemies.add(enemy);

    manager.rebuildSpatialIndex();
    final results = <Enemy>[];
    manager.queryEnemiesInRange(Vector2.zero(), 10, results);
    expect(results, contains(enemy));

    enemy.position = Vector2(200, 200);
    manager.rebuildSpatialIndex();
    results.clear();
    manager.queryEnemiesInRange(Vector2.zero(), 10, results);
    expect(results, isNot(contains(enemy)));
  });
}
