import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/neon_grid_component.dart';
import 'managers/bullet_manager.dart';
import 'managers/enemy_manager.dart';
import 'managers/tower_manager.dart';
import 'world/game_world.dart';
import 'hud/hud_component.dart';

class BoredGamesGame extends FlameGame with HasCollisionDetection {
  BoredGamesGame({
    this.tileSize = 32,
  });

  final double tileSize;

  late final GameWorld worldLayer;
  late final EnemyManager enemyManager;
  late final TowerManager towerManager;
  late final BulletManager bulletManager;
  late final HudComponent hudComponent;

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Base layer: neon grid backdrop for Tron look.
    add(NeonGridComponent(
      gridSize: tileSize,
      lineColor: const Color(0xFF00FFFF),
      glowColor: const Color(0xAA00FFFF),
    ));

    worldLayer = GameWorld(tileSize: tileSize);
    enemyManager = EnemyManager(tileSize: tileSize);
    towerManager = TowerManager(tileSize: tileSize);
    bulletManager = BulletManager();
    hudComponent = HudComponent();

    // Add logical layers; order matters for rendering priority.
    await add(worldLayer);
    await add(enemyManager);
    await add(towerManager);
    await add(bulletManager);
    await add(hudComponent);
  }
}
