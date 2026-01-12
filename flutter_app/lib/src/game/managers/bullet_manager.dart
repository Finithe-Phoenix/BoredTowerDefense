import 'dart:ui';

import 'package:flame/components.dart';

import '../entities/enemy.dart';
import '../entities/projectile.dart';
import '../entities/tower.dart';

class BulletManager extends Component {
  BulletManager({this.poolSize = 50});

  final int poolSize;

  final List<Projectile> _pool = [];
  final List<Projectile> _active = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Pre-allocate projectile pool
    for (int i = 0; i < poolSize; i++) {
      final proj = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2.zero(),
        speed: 0,
        damage: 0,
      );
      proj.deactivate();
      _pool.add(proj);
      add(proj);
    }
  }

  /// Fire a projectile from source to target
  void fire({
    required Vector2 from,
    required Vector2 to,
    required double speed,
    required double damage,
    Color color = const Color(0xFF00FFFF),
    Enemy? target,
    double slowAmount = 0,
    double slowDuration = 0,
    TowerType towerType = TowerType.pulseArcher,
  }) {
    Projectile projectile;
    if (_pool.isNotEmpty) {
      projectile = _pool.removeLast();
      projectile.reset(
        startPosition: from,
        targetPosition: to,
        speed: speed,
        damage: damage,
        color: color,
        target: target,
        slowAmount: slowAmount,
        slowDuration: slowDuration,
        towerType: towerType,
      );
    } else {
      projectile = Projectile(
        startPosition: from,
        targetPosition: to,
        speed: speed,
        damage: damage,
        color: color,
        target: target,
        slowAmount: slowAmount,
        slowDuration: slowDuration,
        towerType: towerType,
      );
      add(projectile);
    }

    _active.add(projectile);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Clean up inactive projectiles
    for (int i = _active.length - 1; i >= 0; i--) {
      final projectile = _active[i];
      if (projectile.isActive) continue;
      _active.removeAt(i);
      if (_pool.length < poolSize) {
        projectile.deactivate();
        _pool.add(projectile);
      } else {
        projectile.removeFromParent();
      }
    }
  }

  /// Number of active projectiles
  int get activeCount => _active.length;

  /// Clear all projectiles
  void clearAll() {
    for (int i = _active.length - 1; i >= 0; i--) {
      final projectile = _active[i];
      projectile.deactivate();
      _active.removeAt(i);
      if (_pool.length < poolSize) {
        _pool.add(projectile);
      } else {
        projectile.removeFromParent();
      }
    }
  }
}
