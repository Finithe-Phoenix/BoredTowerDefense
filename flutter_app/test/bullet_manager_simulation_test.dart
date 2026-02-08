import 'package:test/test.dart';

/// Simulation tests for BulletManager object pooling and stress level system.
/// Tests pure logic without Flame/Flutter dependencies.

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED BULLET MANAGER - Core logic from bullet_manager.dart
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedProjectile {
  int id;
  bool isActive;
  double damage;
  double speed;

  SimulatedProjectile(this.id)
      : isActive = false,
        damage = 0,
        speed = 0;

  void reset({required double damage, required double speed}) {
    this.damage = damage;
    this.speed = speed;
    isActive = true;
  }

  void deactivate() {
    isActive = false;
  }
}

class SimulatedBulletManager {
  static const int maxActiveProjectiles = 200;
  static const int maxPoolSize = 150;

  final List<SimulatedProjectile> _pool = [];
  int _activeCount = 0;
  int _lastStressLevel = 0;
  int _projectileIdCounter = 0;

  // Stress level tracking
  int currentStressLevel = 0;

  int get activeCount => _activeCount;
  int get poolSize => _pool.length;

  /// Fire a projectile - returns the projectile or null if at max capacity
  SimulatedProjectile? fire({
    required double damage,
    required double speed,
  }) {
    // Limit check
    if (_activeCount >= maxActiveProjectiles) return null;

    SimulatedProjectile projectile;

    // Reuse from pool if available
    if (_pool.isNotEmpty) {
      projectile = _pool.removeLast();
      projectile.reset(damage: damage, speed: speed);
    } else {
      // Create new
      projectile = SimulatedProjectile(_projectileIdCounter++);
      projectile.reset(damage: damage, speed: speed);
    }

    _activeCount++;
    _updateStressLevel();
    return projectile;
  }

  /// Return a projectile to the pool
  void returnToPool(SimulatedProjectile p) {
    if (_activeCount > 0) _activeCount--;
    p.deactivate();
    if (_pool.length < maxPoolSize) {
      _pool.add(p);
    }
    _updateStressLevel();
  }

  void _updateStressLevel() {
    final newLevel = _activeCount < 80 ? 0 : (_activeCount < 150 ? 1 : 2);
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

  /// Calculate stress level for a given active count (static helper)
  static int calculateStressLevel(int activeCount) {
    return activeCount < 80 ? 0 : (activeCount < 150 ? 1 : 2);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEST SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('Object Pool Basics', () {
    test('initial state is empty', () {
      final manager = SimulatedBulletManager();

      expect(manager.activeCount, equals(0));
      expect(manager.poolSize, equals(0));
      expect(manager.currentStressLevel, equals(0));
    });

    test('fire creates new projectile when pool is empty', () {
      final manager = SimulatedBulletManager();

      final p = manager.fire(damage: 10, speed: 100);

      expect(p, isNotNull);
      expect(p!.isActive, isTrue);
      expect(p.damage, equals(10));
      expect(p.speed, equals(100));
      expect(manager.activeCount, equals(1));
    });

    test('returnToPool adds projectile to pool', () {
      final manager = SimulatedBulletManager();

      final p = manager.fire(damage: 10, speed: 100);
      expect(manager.activeCount, equals(1));
      expect(manager.poolSize, equals(0));

      manager.returnToPool(p!);

      expect(manager.activeCount, equals(0));
      expect(manager.poolSize, equals(1));
    });

    test('fire reuses pooled projectile', () {
      final manager = SimulatedBulletManager();

      final p1 = manager.fire(damage: 10, speed: 100);
      final originalId = p1!.id;
      manager.returnToPool(p1);

      final p2 = manager.fire(damage: 20, speed: 200);

      expect(p2!.id, equals(originalId)); // Same object reused
      expect(p2.damage, equals(20)); // But with new values
      expect(p2.speed, equals(200));
    });

    test('clearPool resets everything', () {
      final manager = SimulatedBulletManager();

      // Create and return some projectiles
      for (int i = 0; i < 10; i++) {
        final p = manager.fire(damage: i.toDouble(), speed: 100);
        if (i % 2 == 0) manager.returnToPool(p!);
      }

      expect(manager.activeCount, greaterThan(0));

      manager.clearPool();

      expect(manager.activeCount, equals(0));
      expect(manager.poolSize, equals(0));
      expect(manager.currentStressLevel, equals(0));
    });
  });

  group('Max Active Limit', () {
    test('cannot exceed maxActiveProjectiles', () {
      final manager = SimulatedBulletManager();

      // Fire up to max
      for (int i = 0; i < SimulatedBulletManager.maxActiveProjectiles; i++) {
        final p = manager.fire(damage: 1, speed: 1);
        expect(p, isNotNull);
      }

      expect(manager.activeCount, equals(SimulatedBulletManager.maxActiveProjectiles));

      // One more should fail
      final overflow = manager.fire(damage: 1, speed: 1);
      expect(overflow, isNull);
      expect(manager.activeCount, equals(SimulatedBulletManager.maxActiveProjectiles));
    });

    test('returning projectile allows firing again', () {
      final manager = SimulatedBulletManager();
      final projectiles = <SimulatedProjectile>[];

      // Fill to max
      for (int i = 0; i < SimulatedBulletManager.maxActiveProjectiles; i++) {
        projectiles.add(manager.fire(damage: 1, speed: 1)!);
      }

      // Confirm at max
      expect(manager.fire(damage: 1, speed: 1), isNull);

      // Return one
      manager.returnToPool(projectiles.first);
      expect(manager.activeCount, equals(SimulatedBulletManager.maxActiveProjectiles - 1));

      // Now can fire again
      final newP = manager.fire(damage: 1, speed: 1);
      expect(newP, isNotNull);
    });

    test('maxActiveProjectiles is 200', () {
      expect(SimulatedBulletManager.maxActiveProjectiles, equals(200));
    });
  });

  group('Pool Size Limit', () {
    test('pool does not exceed maxPoolSize', () {
      final manager = SimulatedBulletManager();
      final projectiles = <SimulatedProjectile>[];

      // Create more than max pool size
      for (int i = 0; i < 200; i++) {
        final p = manager.fire(damage: 1, speed: 1);
        if (p != null) projectiles.add(p);
      }

      // Return all
      for (final p in projectiles) {
        manager.returnToPool(p);
      }

      // Pool should be capped
      expect(manager.poolSize, equals(SimulatedBulletManager.maxPoolSize));
      expect(manager.poolSize, equals(150));
    });

    test('maxPoolSize is 150', () {
      expect(SimulatedBulletManager.maxPoolSize, equals(150));
    });
  });

  group('Stress Level System', () {
    test('stress level 0 below 80 active', () {
      final manager = SimulatedBulletManager();

      for (int i = 0; i < 79; i++) {
        manager.fire(damage: 1, speed: 1);
      }

      expect(manager.activeCount, equals(79));
      expect(manager.currentStressLevel, equals(0));
    });

    test('stress level 1 at 80+ active', () {
      final manager = SimulatedBulletManager();

      for (int i = 0; i < 80; i++) {
        manager.fire(damage: 1, speed: 1);
      }

      expect(manager.activeCount, equals(80));
      expect(manager.currentStressLevel, equals(1));
    });

    test('stress level 1 between 80-149', () {
      final manager = SimulatedBulletManager();

      for (int i = 0; i < 149; i++) {
        manager.fire(damage: 1, speed: 1);
      }

      expect(manager.activeCount, equals(149));
      expect(manager.currentStressLevel, equals(1));
    });

    test('stress level 2 at 150+ active', () {
      final manager = SimulatedBulletManager();

      for (int i = 0; i < 150; i++) {
        manager.fire(damage: 1, speed: 1);
      }

      expect(manager.activeCount, equals(150));
      expect(manager.currentStressLevel, equals(2));
    });

    test('stress level decreases when projectiles returned', () {
      final manager = SimulatedBulletManager();
      final projectiles = <SimulatedProjectile>[];

      // Ramp up to level 2
      for (int i = 0; i < 160; i++) {
        projectiles.add(manager.fire(damage: 1, speed: 1)!);
      }
      expect(manager.currentStressLevel, equals(2));

      // Return some to drop to level 1
      for (int i = 0; i < 20; i++) {
        manager.returnToPool(projectiles.removeLast());
      }
      expect(manager.activeCount, equals(140));
      expect(manager.currentStressLevel, equals(1));

      // Return more to drop to level 0
      for (int i = 0; i < 70; i++) {
        manager.returnToPool(projectiles.removeLast());
      }
      expect(manager.activeCount, equals(70));
      expect(manager.currentStressLevel, equals(0));
    });

    test('calculateStressLevel static method', () {
      expect(SimulatedBulletManager.calculateStressLevel(0), equals(0));
      expect(SimulatedBulletManager.calculateStressLevel(50), equals(0));
      expect(SimulatedBulletManager.calculateStressLevel(79), equals(0));
      expect(SimulatedBulletManager.calculateStressLevel(80), equals(1));
      expect(SimulatedBulletManager.calculateStressLevel(100), equals(1));
      expect(SimulatedBulletManager.calculateStressLevel(149), equals(1));
      expect(SimulatedBulletManager.calculateStressLevel(150), equals(2));
      expect(SimulatedBulletManager.calculateStressLevel(200), equals(2));
      expect(SimulatedBulletManager.calculateStressLevel(1000), equals(2));
    });

    test('stress level only updates on threshold crossing', () {
      final manager = SimulatedBulletManager();

      // Fire 85 projectiles
      for (int i = 0; i < 85; i++) {
        manager.fire(damage: 1, speed: 1);
      }
      expect(manager.currentStressLevel, equals(1));

      // Fire 5 more - no change
      for (int i = 0; i < 5; i++) {
        manager.fire(damage: 1, speed: 1);
      }
      expect(manager.currentStressLevel, equals(1));
      expect(manager.activeCount, equals(90));
    });
  });

  group('Pool Efficiency', () {
    test('FIFO pool behavior (stack - LIFO actually)', () {
      final manager = SimulatedBulletManager();

      // Create 3 projectiles
      final p1 = manager.fire(damage: 1, speed: 1)!;
      final p2 = manager.fire(damage: 2, speed: 2)!;
      final p3 = manager.fire(damage: 3, speed: 3)!;

      final id1 = p1.id;
      final id2 = p2.id;
      final id3 = p3.id;

      // Return in order 1, 2, 3
      manager.returnToPool(p1);
      manager.returnToPool(p2);
      manager.returnToPool(p3);

      // Pool is LIFO (stack), so 3 comes out first
      final r1 = manager.fire(damage: 10, speed: 10)!;
      final r2 = manager.fire(damage: 20, speed: 20)!;
      final r3 = manager.fire(damage: 30, speed: 30)!;

      expect(r1.id, equals(id3)); // Last in, first out
      expect(r2.id, equals(id2));
      expect(r3.id, equals(id1));
    });

    test('rapid fire and return cycle works', () {
      final manager = SimulatedBulletManager();

      // Simulate game loop: fire and return rapidly
      for (int cycle = 0; cycle < 100; cycle++) {
        final fired = <SimulatedProjectile>[];

        // Fire 10
        for (int i = 0; i < 10; i++) {
          final p = manager.fire(damage: cycle.toDouble(), speed: i.toDouble());
          if (p != null) fired.add(p);
        }

        // Return 8 (simulate 2 hits per cycle)
        for (int i = 0; i < 8 && fired.isNotEmpty; i++) {
          manager.returnToPool(fired.removeLast());
        }
      }

      // System should be stable
      expect(manager.activeCount, lessThanOrEqualTo(SimulatedBulletManager.maxActiveProjectiles));
      expect(manager.poolSize, lessThanOrEqualTo(SimulatedBulletManager.maxPoolSize));
    });

    test('pool prevents excessive object creation', () {
      final manager = SimulatedBulletManager();
      var maxIdSeen = 0;

      // Simulate many fire/return cycles with heavy reuse
      for (int cycle = 0; cycle < 50; cycle++) {
        // Fire 20
        final fired = <SimulatedProjectile>[];
        for (int i = 0; i < 20; i++) {
          final p = manager.fire(damage: 1, speed: 1);
          if (p != null) {
            fired.add(p);
            if (p.id > maxIdSeen) maxIdSeen = p.id;
          }
        }

        // Return all
        for (final p in fired) {
          manager.returnToPool(p);
        }
      }

      // With good pooling, we shouldn't create too many objects
      // 50 cycles * 20 = 1000 fires, but with pooling only ~150 objects needed
      expect(maxIdSeen, lessThan(200));
    });
  });

  group('Edge Cases', () {
    test('return same projectile twice does not break count', () {
      final manager = SimulatedBulletManager();

      final p = manager.fire(damage: 1, speed: 1)!;
      expect(manager.activeCount, equals(1));

      manager.returnToPool(p);
      expect(manager.activeCount, equals(0));

      // Return again (shouldn't happen in practice)
      manager.returnToPool(p);
      expect(manager.activeCount, equals(0)); // Doesn't go negative
    });

    test('fire with zero damage and speed works', () {
      final manager = SimulatedBulletManager();

      final p = manager.fire(damage: 0, speed: 0);

      expect(p, isNotNull);
      expect(p!.damage, equals(0));
      expect(p.speed, equals(0));
    });

    test('fire with negative values works', () {
      final manager = SimulatedBulletManager();

      final p = manager.fire(damage: -10, speed: -50);

      expect(p, isNotNull);
      expect(p!.damage, equals(-10));
      expect(p.speed, equals(-50));
    });

    test('multiple clear calls are safe', () {
      final manager = SimulatedBulletManager();

      manager.fire(damage: 1, speed: 1);
      manager.clearPool();
      manager.clearPool();
      manager.clearPool();

      expect(manager.activeCount, equals(0));
      expect(manager.poolSize, equals(0));
    });
  });

  group('Stress Level Thresholds', () {
    test('exact boundary at 80', () {
      expect(SimulatedBulletManager.calculateStressLevel(79), equals(0));
      expect(SimulatedBulletManager.calculateStressLevel(80), equals(1));
    });

    test('exact boundary at 150', () {
      expect(SimulatedBulletManager.calculateStressLevel(149), equals(1));
      expect(SimulatedBulletManager.calculateStressLevel(150), equals(2));
    });

    test('stress levels mapped to projectile quality', () {
      // Level 0: Full quality (<80 bullets)
      // Level 1: Reduced trails (80-149 bullets)
      // Level 2: Minimal FX (150+ bullets)

      final manager = SimulatedBulletManager();

      // At level 0
      for (int i = 0; i < 50; i++) {
        manager.fire(damage: 1, speed: 1);
      }
      expect(manager.currentStressLevel, equals(0));
      // Full visual quality expected

      // At level 1
      for (int i = 0; i < 50; i++) {
        manager.fire(damage: 1, speed: 1);
      }
      expect(manager.currentStressLevel, equals(1));
      // Reduced trails expected

      // At level 2
      for (int i = 0; i < 60; i++) {
        manager.fire(damage: 1, speed: 1);
      }
      expect(manager.currentStressLevel, equals(2));
      // Minimal FX expected
    });
  });

  group('Concurrent Operations Simulation', () {
    test('interleaved fire and return maintains consistency', () {
      final manager = SimulatedBulletManager();
      final active = <SimulatedProjectile>[];

      for (int i = 0; i < 500; i++) {
        // Randomly fire or return
        if (active.isEmpty || (active.length < 150 && i % 3 != 0)) {
          final p = manager.fire(damage: i.toDouble(), speed: 1);
          if (p != null) active.add(p);
        } else {
          manager.returnToPool(active.removeAt(0));
        }

        // Invariants should always hold
        expect(manager.activeCount, greaterThanOrEqualTo(0));
        expect(manager.activeCount, lessThanOrEqualTo(SimulatedBulletManager.maxActiveProjectiles));
        expect(manager.poolSize, lessThanOrEqualTo(SimulatedBulletManager.maxPoolSize));
      }
    });
  });
}
