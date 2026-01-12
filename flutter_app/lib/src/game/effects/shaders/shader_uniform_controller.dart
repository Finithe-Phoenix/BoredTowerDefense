import 'dart:typed_data';

import 'package:flame/components.dart';

import '../../bored_games_game.dart';

/// Collects tower / enemy positions and exposes them as Float32Lists for shaders.
class ShaderUniformController extends Component with HasGameRef<BoredGamesGame> {
  static const int maxEntities = 10;

  ShaderUniformController() {
    priority = 100;
  }

  final Float32List towerPositionBuffer = Float32List(maxEntities * 2);
  final Float32List enemyPositionBuffer = Float32List(maxEntities * 2);

  int towerCount = 0;
  int enemyCount = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _updatePositions();
  }

  void _updatePositions() {
    towerCount = _fillBuffer(
      buffer: towerPositionBuffer,
      positions: gameRef.towerManager.towers
          .map((tower) => tower.centerPosition)
          .toList(),
    );
    enemyCount = _fillBuffer(
      buffer: enemyPositionBuffer,
      positions: gameRef.enemyManager.activeEnemies
          .map((enemy) => enemy.position)
          .toList(),
    );
  }

  int _fillBuffer({
    required Float32List buffer,
    required List<Vector2> positions,
  }) {
    buffer.fillRange(0, buffer.length, 0);
    final limited = positions.take(maxEntities).toList();
    for (var i = 0; i < limited.length; i++) {
      buffer[i * 2] = limited[i].x;
      buffer[i * 2 + 1] = limited[i].y;
    }
    return limited.length;
  }
}
