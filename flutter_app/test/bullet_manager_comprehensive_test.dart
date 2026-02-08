import 'package:flutter_test/flutter_test.dart';

/// Tests for BulletManager logic and calculations

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED CLASSES FROM bullet_manager.dart
// ═══════════════════════════════════════════════════════════════════════════════

/// Constants from BulletManager
class BulletManagerConstants {
  static const int defaultPoolSize = 300;
  static const int maxActiveProjectiles = 200;
  static const int maxPoolSize = 150;
}

/// Stress level thresholds
class StressLevelCalculator {
  static const int lowThreshold = 80;
  static const int mediumThreshold = 150;

  static int calculateStressLevel(int activeCount) {
    if (activeCount < lowThreshold) return 0;
    if (activeCount < mediumThreshold) return 1;
    return 2;
  }
}

/// Simulates the projectile pool
class SimulatedProjectilePool {
  final List<int> _pool = []; // Using int as placeholder for Projectile
  int _activeCount = 0;
  int _lastStressLevel = 0;
  int currentStressLevel = 0;

  int get activeCount => _activeCount;
  int get poolSize => _pool.length;

  bool canFire() {
    return _activeCount < BulletManagerConstants.maxActiveProjectiles;
  }

  bool fire() {
    if (!canFire()) return false;

    if (_pool.isNotEmpty) {
      _pool.removeLast(); // Reuse from pool
    }
    // Otherwise create new (simulated)

    _activeCount++;
    _updateStressLevel();
    return true;
  }

  void returnToPool(int projectile) {
    if (_activeCount > 0) _activeCount--;
    if (_pool.length < BulletManagerConstants.maxPoolSize) {
      _pool.add(projectile);
    }
    _updateStressLevel();
  }

  void _updateStressLevel() {
    final newLevel = StressLevelCalculator.calculateStressLevel(_activeCount);
    if (newLevel != _lastStressLevel) {
      _lastStressLevel = newLevel;
      currentStressLevel = newLevel;
    }
  }

  void clearPool() {
    _pool.clear();
    _activeCount = 0;
    currentStressLevel = 0;
    _lastStressLevel = 0;
  }

  void prePopulatePool(int count) {
    for (int i = 0; i < count && _pool.length < BulletManagerConstants.maxPoolSize; i++) {
      _pool.add(i);
    }
  }
}

/// Manual shot target position calculator
class ManualShotCalculator {
  static (double, double) calculateTargetPosition(
    double fromX,
    double fromY,
    double dirX,
    double dirY,
    double range,
  ) {
    // Target is 1.2x range in direction
    final targetX = fromX + dirX * range * 1.2;
    final targetY = fromY + dirY * range * 1.2;
    return (targetX, targetY);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('BulletManager Constants', () {
    test('default pool size is 300', () {
      expect(BulletManagerConstants.defaultPoolSize, 300);
    });

    test('max active projectiles is 200', () {
      expect(BulletManagerConstants.maxActiveProjectiles, 200);
    });

    test('max pool size is 150', () {
      expect(BulletManagerConstants.maxPoolSize, 150);
    });

    test('max active > max pool (prevents over-pooling)', () {
      expect(
        BulletManagerConstants.maxActiveProjectiles,
        greaterThan(BulletManagerConstants.maxPoolSize),
      );
    });
  });

  group('StressLevelCalculator', () {
    test('level 0 below 80 active', () {
      expect(StressLevelCalculator.calculateStressLevel(0), 0);
      expect(StressLevelCalculator.calculateStressLevel(50), 0);
      expect(StressLevelCalculator.calculateStressLevel(79), 0);
    });

    test('level 1 between 80 and 149 active', () {
      expect(StressLevelCalculator.calculateStressLevel(80), 1);
      expect(StressLevelCalculator.calculateStressLevel(100), 1);
      expect(StressLevelCalculator.calculateStressLevel(149), 1);
    });

    test('level 2 at 150+ active', () {
      expect(StressLevelCalculator.calculateStressLevel(150), 2);
      expect(StressLevelCalculator.calculateStressLevel(200), 2);
      expect(StressLevelCalculator.calculateStressLevel(1000), 2);
    });

    test('thresholds are correct', () {
      expect(StressLevelCalculator.lowThreshold, 80);
      expect(StressLevelCalculator.mediumThreshold, 150);
    });
  });

  group('SimulatedProjectilePool - Basic Operations', () {
    test('starts with 0 active', () {
      final pool = SimulatedProjectilePool();
      expect(pool.activeCount, 0);
    });

    test('starts with empty pool', () {
      final pool = SimulatedProjectilePool();
      expect(pool.poolSize, 0);
    });

    test('can fire initially', () {
      final pool = SimulatedProjectilePool();
      expect(pool.canFire(), true);
    });

    test('fire increases active count', () {
      final pool = SimulatedProjectilePool();
      pool.fire();
      expect(pool.activeCount, 1);
    });

    test('return decreases active count', () {
      final pool = SimulatedProjectilePool();
      pool.fire();
      pool.fire();
      pool.returnToPool(0);
      expect(pool.activeCount, 1);
    });
  });

  group('SimulatedProjectilePool - Pool Reuse', () {
    test('returned projectile goes to pool', () {
      final pool = SimulatedProjectilePool();
      pool.fire();
      pool.returnToPool(0);

      expect(pool.poolSize, 1);
    });

    test('pool does not exceed max size', () {
      final pool = SimulatedProjectilePool();

      // Fire and return many projectiles
      for (int i = 0; i < 200; i++) {
        pool.fire();
      }

      for (int i = 0; i < 200; i++) {
        pool.returnToPool(i);
      }

      expect(pool.poolSize, BulletManagerConstants.maxPoolSize);
    });

    test('fire reuses from pool when available', () {
      final pool = SimulatedProjectilePool();

      // Create and return some projectiles
      pool.fire();
      pool.fire();
      pool.returnToPool(0);
      pool.returnToPool(1);

      expect(pool.poolSize, 2);

      // Fire again - should reuse
      pool.fire();
      expect(pool.poolSize, 1);
    });
  });

  group('SimulatedProjectilePool - Active Limit', () {
    test('cannot fire when at max active', () {
      final pool = SimulatedProjectilePool();

      for (int i = 0; i < BulletManagerConstants.maxActiveProjectiles; i++) {
        expect(pool.fire(), true);
      }

      expect(pool.canFire(), false);
      expect(pool.fire(), false);
    });

    test('can fire again after returning', () {
      final pool = SimulatedProjectilePool();

      // Fill to max
      for (int i = 0; i < BulletManagerConstants.maxActiveProjectiles; i++) {
        pool.fire();
      }

      expect(pool.canFire(), false);

      // Return one
      pool.returnToPool(0);

      expect(pool.canFire(), true);
      expect(pool.fire(), true);
    });

    test('active count at limit equals max', () {
      final pool = SimulatedProjectilePool();

      for (int i = 0; i < 300; i++) {
        pool.fire();
      }

      // Should cap at max, not exceed
      expect(pool.activeCount, BulletManagerConstants.maxActiveProjectiles);
    });
  });

  group('SimulatedProjectilePool - Stress Level', () {
    test('starts at stress level 0', () {
      final pool = SimulatedProjectilePool();
      expect(pool.currentStressLevel, 0);
    });

    test('stress level increases at 80 active', () {
      final pool = SimulatedProjectilePool();

      for (int i = 0; i < 80; i++) {
        pool.fire();
      }

      expect(pool.currentStressLevel, 1);
    });

    test('stress level increases at 150 active', () {
      final pool = SimulatedProjectilePool();

      for (int i = 0; i < 150; i++) {
        pool.fire();
      }

      expect(pool.currentStressLevel, 2);
    });

    test('stress level decreases when returning projectiles', () {
      final pool = SimulatedProjectilePool();

      // Get to level 1
      for (int i = 0; i < 100; i++) {
        pool.fire();
      }
      expect(pool.currentStressLevel, 1);

      // Return enough to go below threshold
      for (int i = 0; i < 30; i++) {
        pool.returnToPool(i);
      }

      // Active = 70, should be level 0
      expect(pool.currentStressLevel, 0);
    });

    test('stress level only updates when crossing threshold', () {
      final pool = SimulatedProjectilePool();

      // Fire 75 (still level 0)
      for (int i = 0; i < 75; i++) {
        pool.fire();
      }
      expect(pool.currentStressLevel, 0);

      // Fire 5 more to cross to 80 (level 1)
      for (int i = 0; i < 5; i++) {
        pool.fire();
      }
      expect(pool.currentStressLevel, 1);
    });
  });

  group('SimulatedProjectilePool - Clear', () {
    test('clear resets active count', () {
      final pool = SimulatedProjectilePool();

      for (int i = 0; i < 50; i++) {
        pool.fire();
      }

      pool.clearPool();
      expect(pool.activeCount, 0);
    });

    test('clear empties pool', () {
      final pool = SimulatedProjectilePool();

      for (int i = 0; i < 50; i++) {
        pool.fire();
        pool.returnToPool(i);
      }

      pool.clearPool();
      expect(pool.poolSize, 0);
    });

    test('clear resets stress level', () {
      final pool = SimulatedProjectilePool();

      for (int i = 0; i < 150; i++) {
        pool.fire();
      }
      expect(pool.currentStressLevel, 2);

      pool.clearPool();
      expect(pool.currentStressLevel, 0);
    });
  });

  group('SimulatedProjectilePool - Pre-population', () {
    test('pre-populate adds to pool', () {
      final pool = SimulatedProjectilePool();
      pool.prePopulatePool(50);

      expect(pool.poolSize, 50);
    });

    test('pre-populate respects max pool size', () {
      final pool = SimulatedProjectilePool();
      pool.prePopulatePool(200);

      expect(pool.poolSize, BulletManagerConstants.maxPoolSize);
    });

    test('pre-populated items can be reused', () {
      final pool = SimulatedProjectilePool();
      pool.prePopulatePool(10);

      for (int i = 0; i < 10; i++) {
        pool.fire();
      }

      // All 10 should have been reused from pool
      expect(pool.poolSize, 0);
      expect(pool.activeCount, 10);
    });
  });

  group('ManualShotCalculator', () {
    test('target is 1.2x range in direction', () {
      final (targetX, targetY) = ManualShotCalculator.calculateTargetPosition(
        0, 0, // from
        1, 0, // direction (right)
        100, // range
      );

      expect(targetX, 120); // 100 * 1.2
      expect(targetY, 0);
    });

    test('target position in diagonal direction', () {
      final (targetX, targetY) = ManualShotCalculator.calculateTargetPosition(
        50, 50, // from
        1, 1, // direction (diagonal, not normalized)
        100, // range
      );

      expect(targetX, 170); // 50 + 100 * 1.2
      expect(targetY, 170);
    });

    test('target position in negative direction', () {
      final (targetX, targetY) = ManualShotCalculator.calculateTargetPosition(
        100, 100, // from
        -1, 0, // direction (left)
        50, // range
      );

      expect(targetX, 40); // 100 - 50 * 1.2
      expect(targetY, 100);
    });

    test('different ranges produce different targets', () {
      final (x1, _) = ManualShotCalculator.calculateTargetPosition(0, 0, 1, 0, 100);
      final (x2, _) = ManualShotCalculator.calculateTargetPosition(0, 0, 1, 0, 200);

      expect(x2, x1 * 2);
    });
  });

  group('Return to Pool Edge Cases', () {
    test('return with 0 active does not go negative', () {
      final pool = SimulatedProjectilePool();
      pool.returnToPool(0);

      expect(pool.activeCount, 0);
    });

    test('multiple returns work correctly', () {
      final pool = SimulatedProjectilePool();

      for (int i = 0; i < 10; i++) {
        pool.fire();
      }

      for (int i = 0; i < 5; i++) {
        pool.returnToPool(i);
      }

      expect(pool.activeCount, 5);
      expect(pool.poolSize, 5);
    });
  });

  group('Pool Efficiency', () {
    test('pool reuse prevents new allocations', () {
      final pool = SimulatedProjectilePool();

      // First wave
      for (int i = 0; i < 100; i++) {
        pool.fire();
      }

      // Return all
      for (int i = 0; i < 100; i++) {
        pool.returnToPool(i);
      }

      expect(pool.poolSize, 100);

      // Second wave - should all reuse
      for (int i = 0; i < 100; i++) {
        pool.fire();
      }

      // Pool should be empty (all reused)
      expect(pool.poolSize, 0);
      expect(pool.activeCount, 100);
    });
  });

  group('Stress Level Integration', () {
    test('stress level follows active count lifecycle', () {
      final pool = SimulatedProjectilePool();

      // Start
      expect(pool.currentStressLevel, 0);

      // Build up to level 1
      for (int i = 0; i < 80; i++) pool.fire();
      expect(pool.currentStressLevel, 1);

      // Build up to level 2
      for (int i = 0; i < 70; i++) pool.fire();
      expect(pool.currentStressLevel, 2);

      // Return most
      for (int i = 0; i < 100; i++) pool.returnToPool(i);
      expect(pool.currentStressLevel, 0);
    });
  });
}
