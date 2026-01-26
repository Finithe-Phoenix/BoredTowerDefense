import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../world/game_world.dart';
import '../utils/coords.dart';
import '../utils/path_check.dart';
import '../entities/tower.dart';
import '../entities/enemy.dart';
import '../effects/floating_text.dart';
import '../bored_games_game.dart';
import '../../ui/theme/neon_theme.dart';
import 'bullet_manager.dart';
import 'enemy_manager.dart';
import '../../services/audio_service.dart';
import '../../models/upgrade_data.dart';

class TowerManager extends Component with HasGameRef<BoredGamesGame> {
  TowerManager({
    required this.tileSize,
    required this.world,
    this.bulletManager,
    this.enemyManager,
  });

  final double tileSize;
  final GameWorld world;
  BulletManager? bulletManager;
  EnemyManager? enemyManager;

  bool showHeatmap = false;
  Vector2? ghostPosition;
  final List<Tower> _towers = [];
  final Set<math.Point<int>> occupied = {};
  bool blockRejected = false;
  double _ghostPulse = 0;
  double _targetingAccumulator = 0;
  final math.Random _random = math.Random();
  static const double _targetingIntervalBase = 1 / 30;
  double _resonanceTimer = 0;
  static const double _resonanceInterval = 0.5;

  /// Currently selected tower type for placement
  TowerType selectedTowerType = TowerType.pulseArcher;

  void updateGhost(Vector2? position) {
    ghostPosition = position;
    showHeatmap = position != null;
  }

  /// Get all placed towers
  List<Tower> get towers => _towers;

  int get towerCount => _towers.length;

  void applyUpgradeStats(UpgradeStats stats) {
    for (final tower in _towers) {
      tower.applyUpgradeStats(stats);
    }
  }

  Tower? towerAt(Vector2 worldPos) {
    for (final tower in _towers.reversed) {
      final pos = tower.position;
      final size = tower.size;
      if (worldPos.x >= pos.x &&
          worldPos.x <= pos.x + size.x &&
          worldPos.y >= pos.y &&
          worldPos.y <= pos.y + size.y) {
        return tower;
      }
    }
    return null;
  }

  bool removeTower(Tower tower) {
    if (!_towers.remove(tower)) return false;
    final cell = screenToGrid(tower.position, tileSize);
    occupied.remove(cell);
    tower.removeFromParent();
    return true;
  }

  bool placeTower(Vector2 worldPos) {
    final cell = screenToGrid(worldPos, tileSize);
    if (!_isCellWithin(cell)) return false;
    if (!world.isBuildable[cell.y][cell.x]) {
      _showPlacementFeedback('Forbidden tile', cell);
      return false;
    }
    if (occupied.contains(cell)) {
      _showPlacementFeedback('Already occupied', cell);
      return false;
    }

    // Validate that placing here does not block the path from start to end.
    if (world.startCell != null &&
        world.endCell != null &&
        !_wouldKeepPathOpen(cell)) {
      blockRejected = true;
      _showPlacementFeedback('Build would block path', cell);
      return false;
    }
    blockRejected = false;

    if (!world.isBuildable[cell.y][cell.x]) {
      _showPlacementFeedback('Tile locked', cell);
      return false;
    }

    final pos = gridToWorld(cell, tileSize);
    final tower = Tower(
      position: pos,
      size: tileSize,
      type: selectedTowerType,
      onFire: _onTowerFire,
      buildCost: gameRef.towerCost(selectedTowerType),
      damageMultiplier: gameRef.upgradeStats.towerDamageMult,
      rangeMultiplier: gameRef.upgradeStats.towerRangeMult,
      fireRateMultiplier: gameRef.upgradeStats.towerFireRateMult,
      projectileSpeedMultiplier: gameRef.upgradeStats.projectileSpeedMult,
      slowMultiplier: gameRef.upgradeStats.slowMult,
    );
    add(tower);
    _towers.add(tower);
    occupied.add(cell);

    // Play build sound
    AudioService.instance.playBuild();

    gameRef.notifyTutorialTowerPlaced();

    parent?.add(FloatingText(
      position: pos + Vector2(tileSize / 2, -tileSize / 2),
      text: '${selectedTowerType.name} deployed',
      type: FloatingTextType.levelUp,
      customColor: selectedTowerType.color,
      fontSize: 14,
      duration: 1.2,
      riseSpeed: 20,
    ));
    return true;
  }

  void _onTowerFire(Tower tower, Enemy target, Vector2 targetPos) {
    if (tower.manualTargeting) {
      gameRef.triggerFocusShot(tower);
    }
    // Resonance Siphon doesn't fire bullets
    if (tower.type == TowerType.resonanceSiphon) return;

    if (tower.type == TowerType.teslaTerminal) {
       _fireTeslaLightning(tower, target);
       return;
    }

    bulletManager?.fire(
      from: tower.centerPosition,
      to: targetPos,
      speed: tower.projectileSpeed,
      damage: tower.damage,
      color: tower.color,
      target: target,
      onHit: (enemy, hitPosition, killed) {
        if (tower.type == TowerType.neuralDisruptor && !killed && _random.nextDouble() < 0.25) {
           enemy.applySlow(0.9, 1.5); // Neural disruption = heavy slow/stun
        }
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
    // Sound removed - too many projectiles cause audio overload
  }

  void _fireTeslaLightning(Tower tower, Enemy target) {
    // Tesla Terminal: Instant hit + chain to 2 nearby enemies
    final damage = tower.damage;
    target.takeDamage(damage);

    // Chain logic
    final nearby = <Enemy>[];
    enemyManager?.queryEnemiesInRange(target.position, 60, nearby);
    int chained = 0;
    for (final e in nearby) {
       if (e != target && chained < 2) {
           e.takeDamage(damage * 0.7);
           chained++;
       }
    }
    // Sound removed - Tesla fires too rapidly
  }

  void _showPlacementFeedback(String message, math.Point<int> cell) {
    final position = gridToWorld(cell, tileSize) + Vector2(tileSize / 2, tileSize / 2);
    final text = FloatingText(
      position: position,
      text: message,
      type: FloatingTextType.damage,
      customColor: NeonColors.yellow,
      fontSize: 12,
      duration: 1.1,
      riseSpeed: 22,
    );
    parent?.add(text);
    if (kDebugMode) {
      debugPrint('[TowerManager] $message at $position (cell $cell)');
    }
  }

  void setSelectedTowerType(TowerType type) {
    if (selectedTowerType == type) return;
    selectedTowerType = type;
    _showSelectionHint(type);
    gameRef.notifyTutorialTowerSelected();
  }

  void _showSelectionHint(TowerType type) {
    final center = Vector2(gameRef.size.x / 2, gameRef.size.y - 40);
    final text = FloatingText(
      position: center,
      text: 'Drag to deploy ${type.name}',
      type: FloatingTextType.combo,
      customColor: type.color,
      fontSize: 14,
      duration: 1.3,
      riseSpeed: 16,
    );
    gameRef.add(text);
  }

  bool _isCellWithin(math.Point<int> cell) {
    return cell.y >= 0 &&
        cell.y < world.isBuildable.length &&
        cell.x >= 0 &&
        cell.x < world.isBuildable[cell.y].length;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _targetingAccumulator += dt;
    final enemies = enemyManager?.aliveCount ?? 0;
    final towerCount = _towers.length;
    double interval = _targetingIntervalBase;
    if (gameRef.reduceFx || enemies > 24 || towerCount > 20) {
      interval = 1 / 20;
    }
    if (enemies > 40 || towerCount > 30) {
      interval = 1 / 12;
    }
    if (_targetingAccumulator >= interval) {
      _targetingAccumulator = 0;
      final manager = enemyManager;
      if (manager != null) {
        manager.rebuildSpatialIndex();
        for (final tower in towers) {
          tower.updateTargeting(manager);
        }
      }
    }

    _ghostPulse += dt * 3;
    if (_ghostPulse > math.pi * 2) {
      _ghostPulse -= math.pi * 2;
    }

    if (towerCount > 0) {
      _resonanceTimer += dt;
      if (_resonanceTimer >= _resonanceInterval) {
        _resonanceTimer = 0;
        _updateResonanceFields();
      }
    } else {
      _resonanceTimer = 0;
    }
  }

  void _updateResonanceFields() {
    // Clear all boosts first
    for (final t in _towers) {
       t.resetResonanceBoost();
    }
    
    final siphons = _towers.where((t) => t.type == TowerType.resonanceSiphon);
    if (siphons.isEmpty) return;
    for (final siphon in siphons) {
       for (final tower in _towers) {
          if (tower == siphon) continue;
          if (tower.position.distanceTo(siphon.position) < 100) {
             tower.setResonanceBoost(true);
          }
       }
    }
  }

  // Cached paints for tower placement rendering
  final Paint _paintAllowedFill = Paint()..color = NeonColors.cyan.withOpacity(0.04);
  final Paint _paintBlockedFill = Paint()..color = NeonColors.magenta.withOpacity(0.06);
  final Paint _paintAllowed = Paint()
    ..color = NeonColors.cyan.withOpacity(0.12)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  final Paint _paintBlocked = Paint()
    ..color = NeonColors.magenta.withOpacity(0.16)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  final Paint _paintGhost = Paint();
  final Paint _paintGhostBlocked = Paint()..color = NeonColors.magenta.withOpacity(0.35);
  final Paint _paintWarning = Paint()..color = NeonColors.orange.withOpacity(0.22);
  final Paint _paintRange = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _paintPulse = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (world.isBuildable.isEmpty) return;

    final rows = world.isBuildable;

    // Only render heatmap in a limited area around the ghost position to save draw calls
    if (showHeatmap && ghostPosition != null) {
      final ghostCell = screenToGrid(ghostPosition!, tileSize);
      // Only draw tiles within 5-tile radius of ghost (reduces draw calls from 1000+ to ~100)
      const viewRadius = 5;
      final minY = (ghostCell.y - viewRadius).clamp(0, rows.length - 1);
      final maxY = (ghostCell.y + viewRadius).clamp(0, rows.length - 1);

      for (int y = minY; y <= maxY; y++) {
        final minX = (ghostCell.x - viewRadius).clamp(0, rows[y].length - 1);
        final maxX = (ghostCell.x + viewRadius).clamp(0, rows[y].length - 1);
        for (int x = minX; x <= maxX; x++) {
          final rect = Rect.fromLTWH(
            x * tileSize,
            y * tileSize,
            tileSize,
            tileSize,
          );
          final isBuildable = rows[y][x];
          canvas.drawRect(rect, isBuildable ? _paintAllowedFill : _paintBlockedFill);
          canvas.drawRect(rect, isBuildable ? _paintAllowed : _paintBlocked);
        }
      }
    }

    if (ghostPosition != null) {
      final cell = screenToGrid(ghostPosition!, tileSize);
        if (_isCellWithin(cell)) {
          final topLeft = gridToWorld(cell, tileSize);
          final rect = Rect.fromLTWH(
            topLeft.x,
            topLeft.y,
            tileSize,
            tileSize,
          );
          final canBuild =
              rows[cell.y][cell.x] && !occupied.contains(cell);
          _paintGhost.color = selectedTowerType.color.withOpacity(0.25);
          canvas.drawRect(rect, canBuild ? _paintGhost : _paintGhostBlocked);
          if (!canBuild && blockRejected) {
            canvas.drawRect(rect, _paintWarning);
          }

          // Draw range preview for ghost (even on blocked tiles).
          final rangeColor = canBuild ? selectedTowerType.color : NeonColors.magenta;
          _paintRange.color = rangeColor.withOpacity(canBuild ? 0.18 : 0.12);
          final range = gameRef.towerRange(selectedTowerType);
          canvas.drawCircle(
            Offset(topLeft.x + tileSize / 2, topLeft.y + tileSize / 2),
            range,
            _paintRange,
          );

          if (canBuild) {
            final explosionRadius = tileSize * 0.35 + math.sin(_ghostPulse) * 6;
            _paintPulse.color = selectedTowerType.color.withOpacity(0.25);
            canvas.drawCircle(
              Offset(topLeft.x + tileSize / 2, topLeft.y + tileSize / 2),
              explosionRadius,
              _paintPulse,
            );
          }
        }
      }
  }

  bool _wouldKeepPathOpen(math.Point<int> candidate) {
    // Enemies follow a fixed waypoint path; only block placement on path tiles.
    if (world.tileTypes.isEmpty) return true;
    return world.tileTypes[candidate.y][candidate.x] != 2;
  }
}
