import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../bored_games_game.dart';
import '../../entities/enemy.dart';
import '../../../models/quality_level.dart';

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
  bool enabled = true;

  @override
  void update(double dt) {
    super.update(dt);
    if (!enabled) return;
    _updateTimer += dt;
    if (_updateTimer < updateInterval) return;
    _updateTimer = 0;
    if (_entityLimit() == 0) {
      towerCount = 0;
      enemyCount = 0;
      return;
    }
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
    final scale = gameRef.shaderScale;
    final limit = _entityLimit();
    towerCount = _fillBufferFromTowers(limit, scale);
    enemyCount = _fillBufferFromEnemies(limit, scale);
  }

  int _entityLimit() {
    return switch (gameRef.quality) {
      QualityLevel.high => maxEntities,
      QualityLevel.medium => 6,
      QualityLevel.low => 0,
    };
  }

  int _fillBufferFromTowers(int limit, double scale) {
    if (limit == 0) return 0;
    final towers = gameRef.towerManager.towers;
    final count = towers.length < limit ? towers.length : limit;
    final offX = Enemy.screenOffset.x * scale;
    final offY = Enemy.screenOffset.y * scale;
    final worldScale = Enemy.screenScale * scale;
    for (var i = 0; i < count; i++) {
      final tower = towers[i];
      final pos = tower.position;
      final size = tower.size;
      final worldX = pos.x + size.x * 0.5;
      final worldY = pos.y + size.y * 0.5;
      towerPositionBuffer[i * 2] = offX + worldX * worldScale;
      towerPositionBuffer[i * 2 + 1] = offY + worldY * worldScale;
    }
    return count;
  }

  int _fillBufferFromEnemies(int limit, double scale) {
    if (limit == 0) return 0;
    final enemies = gameRef.enemyManager.activeEnemies;
    final count = enemies.length < limit ? enemies.length : limit;
    final offX = Enemy.screenOffset.x * scale;
    final offY = Enemy.screenOffset.y * scale;
    final worldScale = Enemy.screenScale * scale;
    for (var i = 0; i < count; i++) {
      final pos = enemies[i].position;
      enemyPositionBuffer[i * 2] = offX + pos.x * worldScale;
      enemyPositionBuffer[i * 2 + 1] = offY + pos.y * worldScale;
    }
    return count;
  }

  ui.Image? get entityTexture => _entityTexture;

  void _updateTexture() {
    if (_texturePending || gameRef.size.isZero()) return;
    _texturePending = true;

    _pixelBuffer.fillRange(0, _pixelBuffer.length, 0);
    final scale = gameRef.shaderScale;
    _writeRow(
      row: 0,
      positions: towerPositionBuffer,
      count: towerCount,
      scale: scale,
    );
    _writeRow(
      row: 1,
      positions: enemyPositionBuffer,
      count: enemyCount,
      scale: scale,
    );

    ui.decodeImageFromPixels(
      _pixelBuffer,
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
    required double scale,
  }) {
    final width = _textureWidth;
    final scaledWidth = gameRef.size.x * scale;
    final scaledHeight = gameRef.size.y * scale;
    for (var i = 0; i < width; i++) {
      final base = (row * width + i) * 4;
      if (i >= count) {
        _pixelBuffer[base + 3] = 0;
        continue;
      }
      final x = positions[i * 2];
      final y = positions[i * 2 + 1];
      final nx = (x / scaledWidth).clamp(0.0, 1.0);
      final ny = (y / scaledHeight).clamp(0.0, 1.0);
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
