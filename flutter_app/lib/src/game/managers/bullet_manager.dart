import 'dart:ui';

import 'package:flame/components.dart';

import '../bored_games_game.dart';
import '../entities/enemy.dart';
import '../entities/projectile.dart';
import '../entities/tower.dart';

class BulletManager extends Component with HasGameRef<BoredGamesGame> {
  BulletManager({this.poolSize = 50});

  final int poolSize;
  //...

  /// Fire a projectile for manual FPS mode
  void fireManualShot({
    required Vector2 from,
    required Vector2 direction,
    required Tower tower,
  }) {
    // Target position is a long distance in the chosen direction
    final targetPosition = from + direction * tower.range * 1.2; // Shoot a bit past max range

    fire(
      from: from,
      to: targetPosition,
      speed: tower.projectileSpeed,
      damage: tower.damage,
      color: tower.color,
      target: null, // No specific enemy target
      onHit: (enemy, hitPosition, killed) {
        // In manual mode, we register hits to provide visual feedback
        gameRef.registerFocusHit(
          tower: tower,
          target: enemy,
          hitWorld: hitPosition,
          killed: killed,
        );
      },
      slowAmount: tower.slowAmount,
      slowDuration: tower.slowDuration,
      towerType: tower.type,
    );
  }
  
  //...
