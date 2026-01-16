import 'dart:ui';

import 'package:flame/components.dart';

import '../bored_games_game.dart';
import '../entities/enemy.dart';
import '../entities/projectile.dart';
import '../entities/tower.dart';

class BulletManager extends Component with HasGameRef<BoredGamesGame> {
  BulletManager({this.poolSize = 150});

  final int poolSize;

  // Object pool para reutilizar proyectiles
  static const int maxActiveProjectiles = 500;
  static final List<Projectile> _pool = [];
  static int _activeCount = 0;

  /// Devuelve el conteo de balas activas O(1)
  int get activeCount => _activeCount;

  /// Devuelve un proyectil al pool para reutilización
  static void returnToPool(Projectile p) {
    if (_activeCount > 0) _activeCount--;
    if (_pool.length < 150) {
      _pool.add(p);
    }
    // Actualizar nivel de estrés
    _updateStressLevel();
  }

  /// Actualiza el nivel de estrés basado en cantidad de balas
  static void _updateStressLevel() {
    if (_activeCount < 200) {
      Projectile.setStressLevel(0);
    } else if (_activeCount < 400) {
      Projectile.setStressLevel(1);
    } else {
      Projectile.setStressLevel(2);
    }
  }

  /// Limpia el pool (para cuando se reinicia el juego)
  static void clearPool() {
    _pool.clear();
    _activeCount = 0;
    Projectile.setStressLevel(0);
  }

  void fire({
    required Vector2 from,
    required Vector2 to,
    required double speed,
    required double damage,
    required Color color,
    Enemy? target,
    void Function(Enemy target, Vector2 hitPosition, bool killed)? onHit,
    double slowAmount = 0,
    double slowDuration = 0,
    TowerType towerType = TowerType.pulseArcher,
  }) {
    // Límite máximo de proyectiles activos
    if (_activeCount >= maxActiveProjectiles) return;

    Projectile projectile;

    // Reutilizar del pool si hay disponibles
    if (_pool.isNotEmpty) {
      projectile = _pool.removeLast();
      projectile.reset(
        startPosition: from,
        targetPosition: to,
        speed: speed,
        damage: damage,
        color: color,
        target: target,
        onHit: onHit,
        slowAmount: slowAmount,
        slowDuration: slowDuration,
        towerType: towerType,
      );
    } else {
      // Crear nuevo si el pool está vacío
      projectile = Projectile(
        startPosition: from,
        targetPosition: to,
        speed: speed,
        damage: damage,
        color: color,
        target: target,
        onHit: onHit,
        slowAmount: slowAmount,
        slowDuration: slowDuration,
        towerType: towerType,
      );
    }

    _activeCount++;
    _updateStressLevel();
    add(projectile);
  }

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
}
