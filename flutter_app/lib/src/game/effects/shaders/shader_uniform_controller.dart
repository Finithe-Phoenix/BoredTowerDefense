import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../bored_games_game.dart';

/// Collects tower / enemy positions and exposes them as Float32Lists for shaders.
class ShaderUniformController extends Component with HasGameRef<BoredGamesGame> {
  static const int maxEntities = 10;
  static const int _textureWidth = maxEntities;
  static const int _textureHeight = 2;
  static const double updateInterval = 1 / 12;

  ShaderUniformController() {
    priority = 100;
  }

  final Float32List towerPositionBuffer = Float32List(maxEntities * 2);
  final Float32List enemyPositionBuffer = Float32List(maxEntities * 2);
  final Uint8List _pixelBuffer =
      Uint8List(_textureWidth * _textureHeight * 4);

  int towerCount = 0;
  int enemyCount = 0;
  ui.Image? _entityTexture;
  bool _texturePending = false;
  double _updateTimer = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _updateTimer += dt;
    if (_updateTimer < updateInterval) return;
    _updateTimer = 0;
    final hasEntities =
        gameRef.towerManager.towerCount > 0 || gameRef.enemyManager.aliveCount > 0;
    if (!hasEntities) {
      if (towerCount != 0 || enemyCount != 0) {
        _updatePositions();
        _updateTexture();
      }
      return;
    }
    _updatePositions();
    _updateTexture();
  }

  void _updatePositions() {
    towerCount = _fillBuffer(
      buffer: towerPositionBuffer,
      positions: gameRef.towerManager.towers
          .map((tower) => gameRef.worldToScreen(tower.centerPosition))
          .toList(),
    );
    enemyCount = _fillBuffer(
      buffer: enemyPositionBuffer,
      positions: gameRef.enemyManager.activeEnemies
          .map((enemy) => gameRef.worldToScreen(enemy.position))
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

  ui.Image? get entityTexture => _entityTexture;

  void _updateTexture() {
    if (_texturePending || gameRef.size.isZero()) return;
    _texturePending = true;

    _pixelBuffer.fillRange(0, _pixelBuffer.length, 0);
    _writeRow(
      row: 0,
      positions: towerPositionBuffer,
      count: towerCount,
    );
    _writeRow(
      row: 1,
      positions: enemyPositionBuffer,
      count: enemyCount,
    );

    final bytes = Uint8List.fromList(_pixelBuffer);
    ui.decodeImageFromPixels(
      bytes,
      _textureWidth,
      _textureHeight,
      ui.PixelFormat.rgba8888,
      (img) {
        _entityTexture?.dispose();
        _entityTexture = img;
        _texturePending = false;
      },
    );
  }

  void _writeRow({
    required int row,
    required Float32List positions,
    required int count,
  }) {
    final width = _textureWidth;
    final height = _textureHeight;
    final size = gameRef.size;
    for (var i = 0; i < width; i++) {
      final base = (row * width + i) * 4;
      if (i >= count) {
        _pixelBuffer[base + 3] = 0;
        continue;
      }
      final x = positions[i * 2];
      final y = positions[i * 2 + 1];
      final nx = (x / size.x).clamp(0.0, 1.0);
      final ny = (y / size.y).clamp(0.0, 1.0);
      _pixelBuffer[base] = (nx * 255).round();
      _pixelBuffer[base + 1] = (ny * 255).round();
      _pixelBuffer[base + 2] = 0;
      _pixelBuffer[base + 3] = 255;
    }
  }

  @override
  void onRemove() {
    _entityTexture?.dispose();
    super.onRemove();
  }
}
