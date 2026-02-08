// Tests for Projectile reset/pooling and stress level system
// Simulation-based (no Flame engine required)
import 'dart:math' as math;
import 'package:test/test.dart';

/// Simulated Projectile matching the real implementation
class SimulatedProjectile {
  SimulatedProjectile({
    required this.startX,
    required this.startY,
    required this.targetX,
    required this.targetY,
    required this.speed,
    required this.damage,
    this.slowAmount = 0,
    this.slowDuration = 0,
    this.towerType = 'pulseArcher',
  }) {
    _active = true;
    _time = 0;
    _initializeTypeEffects();
  }

  double startX;
  double startY;
  double targetX;
  double targetY;
  double speed;
  double damage;
  double slowAmount;
  double slowDuration;
  String towerType;

  bool _active = true;
  double _time = 0;
  int _maxTrailLength = 12;
  int _particleCount = 8;
  double _wobbleAmount = 0;

  // Static stress control
  static bool lowFx = false;
  static bool allowTrails = true;
  static int stressLevel = 0;

  static void setStressLevel(int level) {
    stressLevel = level.clamp(0, 2);
    lowFx = stressLevel >= 2;
  }

  bool get isActive => _active;
  bool get appliesSlow => slowAmount > 0 && slowDuration > 0;
  int get maxTrailLength => _maxTrailLength;
  int get particleCount => _particleCount;
  double get wobbleAmount => _wobbleAmount;

  void _initializeTypeEffects() {
    _maxTrailLength = 12;
    _particleCount = 8;
    _wobbleAmount = 0;

    switch (towerType) {
      case 'pulseArcher':
        _maxTrailLength = 10;
        _particleCount = 6;
        break;
      case 'circuitCannon':
        _maxTrailLength = 6;
        _particleCount = 4;
        break;
      case 'phaseMage':
        _maxTrailLength = 16;
        _particleCount = 10;
        _wobbleAmount = 0.3;
        break;
      case 'glimmerField':
        _maxTrailLength = 8;
        _particleCount = 12;
        _wobbleAmount = 0.1;
        break;
      case 'ionSniper':
        _maxTrailLength = 20;
        _particleCount = 4;
        break;
      case 'plasmaBubble':
        _maxTrailLength = 14;
        _particleCount = 6;
        _wobbleAmount = 0.5;
        break;
      default:
        _maxTrailLength = 12;
        _particleCount = 8;
        break;
    }

    // Stress level adjustments
    if (stressLevel >= 1) {
      _maxTrailLength = math.max(3, (_maxTrailLength * 0.5).round());
      _particleCount = math.max(2, (_particleCount * 0.5).round());
    }
    if (lowFx || stressLevel >= 2) {
      _maxTrailLength = math.max(2, (_maxTrailLength * 0.35).round());
      _particleCount = (_particleCount * 0.25).round();
      if (_particleCount < 0) _particleCount = 0;
      _wobbleAmount = 0;
    }
  }

  void reset({
    required double newStartX,
    required double newStartY,
    required double newTargetX,
    required double newTargetY,
    required double newSpeed,
    required double newDamage,
    double newSlowAmount = 0,
    double newSlowDuration = 0,
    String newTowerType = 'pulseArcher',
  }) {
    startX = newStartX;
    startY = newStartY;
    targetX = newTargetX;
    targetY = newTargetY;
    speed = newSpeed;
    damage = newDamage;
    slowAmount = newSlowAmount;
    slowDuration = newSlowDuration;
    towerType = newTowerType;
    _active = true;
    _time = 0;
    _initializeTypeEffects();
  }

  void deactivate() {
    _active = false;
  }

  void update(double dt) {
    if (!_active) return;

    _time += dt;

    // Lifetime max (3 seconds)
    if (_time > 3.0) {
      deactivate();
      return;
    }

    // Bounds check
    const maxBound = 1200.0;
    const minBound = -100.0;
    if (startX < minBound || startX > maxBound ||
        startY < minBound || startY > maxBound) {
      deactivate();
      return;
    }

    // Move toward target
    final dx = targetX - startX;
    final dy = targetY - startY;
    final dist = math.sqrt(dx * dx + dy * dy);

    if (dist < 5.0) {
      // Reached target
      deactivate();
      return;
    }

    final nx = dx / dist;
    final ny = dy / dist;
    startX += nx * speed * dt;
    startY += ny * speed * dt;
  }
}

/// Simulated projectile pool
class SimulatedBulletPool {
  final List<SimulatedProjectile> _pool = [];
  int _activeCount = 0;

  int get activeCount => _activeCount;
  int get poolSize => _pool.length;

  SimulatedProjectile obtain({
    required double startX,
    required double startY,
    required double targetX,
    required double targetY,
    required double speed,
    required double damage,
    String towerType = 'pulseArcher',
  }) {
    // Try reuse from pool
    for (final p in _pool) {
      if (!p.isActive) {
        p.reset(
          newStartX: startX,
          newStartY: startY,
          newTargetX: targetX,
          newTargetY: targetY,
          newSpeed: speed,
          newDamage: damage,
          newTowerType: towerType,
        );
        _activeCount++;
        return p;
      }
    }

    // Create new
    final p = SimulatedProjectile(
      startX: startX,
      startY: startY,
      targetX: targetX,
      targetY: targetY,
      speed: speed,
      damage: damage,
      towerType: towerType,
    );
    _pool.add(p);
    _activeCount++;
    return p;
  }

  void returnToPool(SimulatedProjectile p) {
    p.deactivate();
    _activeCount = math.max(0, _activeCount - 1);
  }

  void updateAll(double dt) {
    for (final p in _pool) {
      if (p.isActive) {
        p.update(dt);
        if (!p.isActive) {
          _activeCount = math.max(0, _activeCount - 1);
        }
      }
    }
  }
}

void main() {
  setUp(() {
    SimulatedProjectile.stressLevel = 0;
    SimulatedProjectile.lowFx = false;
    SimulatedProjectile.allowTrails = true;
  });

  group('Projectile basic lifecycle', () {
    test('starts active', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
      );
      expect(p.isActive, isTrue);
    });

    test('deactivate sets inactive', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
      );
      p.deactivate();
      expect(p.isActive, isFalse);
    });

    test('update does nothing when inactive', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
      );
      p.deactivate();
      final oldX = p.startX;
      p.update(1.0);
      expect(p.startX, oldX);
    });

    test('auto-deactivates after 3 seconds', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 10000, targetY: 0,
        speed: 10, damage: 10,
      );
      p.update(3.1);
      expect(p.isActive, isFalse);
    });

    test('deactivates when reaching target', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 3, targetY: 0,
        speed: 400, damage: 10,
      );
      p.update(0.01); // Speed 400 * 0.01 = 4 units, past target (3 away)
      expect(p.isActive, isFalse);
    });

    test('deactivates when out of bounds', () {
      final p = SimulatedProjectile(
        startX: -200, startY: 0,
        targetX: -300, targetY: 0,
        speed: 400, damage: 10,
      );
      p.update(0.1);
      expect(p.isActive, isFalse);
    });
  });

  group('Projectile appliesSlow', () {
    test('true when slow amount and duration > 0', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
        slowAmount: 0.5,
        slowDuration: 1.5,
      );
      expect(p.appliesSlow, isTrue);
    });

    test('false when slowAmount is 0', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
        slowAmount: 0,
        slowDuration: 1.5,
      );
      expect(p.appliesSlow, isFalse);
    });

    test('false when slowDuration is 0', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
        slowAmount: 0.5,
        slowDuration: 0,
      );
      expect(p.appliesSlow, isFalse);
    });
  });

  group('Projectile reset for pool reuse', () {
    test('reset reactivates inactive projectile', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
      );
      p.deactivate();
      expect(p.isActive, isFalse);

      p.reset(
        newStartX: 50, newStartY: 50,
        newTargetX: 200, newTargetY: 200,
        newSpeed: 300, newDamage: 25,
      );
      expect(p.isActive, isTrue);
    });

    test('reset updates all parameters', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
        towerType: 'pulseArcher',
      );
      p.deactivate();

      p.reset(
        newStartX: 50, newStartY: 60,
        newTargetX: 200, newTargetY: 300,
        newSpeed: 500, newDamage: 30,
        newTowerType: 'circuitCannon',
      );

      expect(p.startX, 50);
      expect(p.startY, 60);
      expect(p.targetX, 200);
      expect(p.targetY, 300);
      expect(p.speed, 500);
      expect(p.damage, 30);
      expect(p.towerType, 'circuitCannon');
    });

    test('reset clears time accumulator', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 10000, targetY: 0,
        speed: 10, damage: 10,
      );
      p.update(2.5); // Accumulate time

      p.reset(
        newStartX: 0, newStartY: 0,
        newTargetX: 10000, newTargetY: 0,
        newSpeed: 10, newDamage: 10,
      );

      // Should NOT deactivate after another 0.6s (total would be 3.1 without reset)
      p.update(0.6);
      expect(p.isActive, isTrue);
    });

    test('reset changes tower type visual properties', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
        towerType: 'pulseArcher',
      );
      final oldTrail = p.maxTrailLength;
      final oldParticles = p.particleCount;

      p.reset(
        newStartX: 0, newStartY: 0,
        newTargetX: 100, newTargetY: 0,
        newSpeed: 400, newDamage: 10,
        newTowerType: 'phaseMage',
      );

      expect(p.maxTrailLength, isNot(equals(oldTrail)));
    });

    test('multiple reset cycles maintain correctness', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
      );

      for (int i = 0; i < 10; i++) {
        p.deactivate();
        p.reset(
          newStartX: 0, newStartY: 0,
          newTargetX: 100, newTargetY: 0,
          newSpeed: 400, newDamage: 10.0 + i,
        );
        expect(p.isActive, isTrue);
        expect(p.damage, 10.0 + i);
      }
    });
  });

  group('Projectile type-specific effects', () {
    test('pulseArcher has standard settings', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
        towerType: 'pulseArcher',
      );
      expect(p.maxTrailLength, 10);
      expect(p.particleCount, 6);
    });

    test('circuitCannon has shorter trail', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
        towerType: 'circuitCannon',
      );
      expect(p.maxTrailLength, 6);
      expect(p.particleCount, 4);
    });

    test('phaseMage has longest trail and wobble', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
        towerType: 'phaseMage',
      );
      expect(p.maxTrailLength, 16);
      expect(p.particleCount, 10);
      expect(p.wobbleAmount, 0.3);
    });

    test('glimmerField has high particle count', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
        towerType: 'glimmerField',
      );
      expect(p.particleCount, 12);
    });

    test('ionSniper has longest trail', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
        towerType: 'ionSniper',
      );
      expect(p.maxTrailLength, 20);
    });

    test('plasmaBubble has wobble and medium trail', () {
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
        towerType: 'plasmaBubble',
      );
      expect(p.maxTrailLength, 14);
      expect(p.wobbleAmount, 0.5);
    });
  });

  group('Projectile stress level system', () {
    test('stress level 0 - full quality', () {
      SimulatedProjectile.setStressLevel(0);
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
        towerType: 'phaseMage',
      );
      expect(p.maxTrailLength, 16);
      expect(p.particleCount, 10);
      expect(p.wobbleAmount, 0.3);
    });

    test('stress level 1 - reduced quality', () {
      SimulatedProjectile.setStressLevel(1);
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
        towerType: 'phaseMage',
      );
      // 16 * 0.5 = 8, 10 * 0.5 = 5
      expect(p.maxTrailLength, 8);
      expect(p.particleCount, 5);
    });

    test('stress level 2 - minimal FX', () {
      SimulatedProjectile.setStressLevel(2);
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
        towerType: 'phaseMage',
      );
      // After stress 1: trail=8, particles=5
      // After stress 2: trail = max(2, 8*0.35) = 3, particles = (5*0.25) = 1
      expect(p.maxTrailLength, lessThanOrEqualTo(3));
      expect(p.wobbleAmount, 0); // Removed at level 2
    });

    test('stress level clamped to 0-2', () {
      SimulatedProjectile.setStressLevel(-5);
      expect(SimulatedProjectile.stressLevel, 0);

      SimulatedProjectile.setStressLevel(10);
      expect(SimulatedProjectile.stressLevel, 2);
    });

    test('stress level 2 sets lowFx flag', () {
      SimulatedProjectile.setStressLevel(2);
      expect(SimulatedProjectile.lowFx, isTrue);
    });

    test('stress level 0 clears lowFx flag', () {
      SimulatedProjectile.setStressLevel(2);
      SimulatedProjectile.setStressLevel(0);
      expect(SimulatedProjectile.lowFx, isFalse);
    });

    test('trail minimum enforced at stress level 2', () {
      SimulatedProjectile.setStressLevel(2);
      final p = SimulatedProjectile(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
        towerType: 'circuitCannon', // Shortest trail (6)
      );
      expect(p.maxTrailLength, greaterThanOrEqualTo(2));
    });
  });

  group('Bullet pool simulation', () {
    test('pool creates new projectiles', () {
      final pool = SimulatedBulletPool();
      pool.obtain(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
      );
      expect(pool.activeCount, 1);
      expect(pool.poolSize, 1);
    });

    test('pool reuses deactivated projectiles', () {
      final pool = SimulatedBulletPool();
      final p1 = pool.obtain(
        startX: 0, startY: 0,
        targetX: 100, targetY: 0,
        speed: 400, damage: 10,
      );
      pool.returnToPool(p1);

      final p2 = pool.obtain(
        startX: 50, startY: 50,
        targetX: 200, targetY: 200,
        speed: 300, damage: 20,
      );

      expect(pool.poolSize, 1); // Reused, not new
      expect(identical(p1, p2), isTrue);
      expect(p2.startX, 50);
      expect(p2.damage, 20);
    });

    test('pool expands when all active', () {
      final pool = SimulatedBulletPool();
      pool.obtain(startX: 0, startY: 0, targetX: 100, targetY: 0, speed: 400, damage: 10);
      pool.obtain(startX: 0, startY: 0, targetX: 100, targetY: 0, speed: 400, damage: 10);
      pool.obtain(startX: 0, startY: 0, targetX: 100, targetY: 0, speed: 400, damage: 10);

      expect(pool.activeCount, 3);
      expect(pool.poolSize, 3);
    });

    test('pool handles 200 concurrent projectiles', () {
      final pool = SimulatedBulletPool();
      for (int i = 0; i < 200; i++) {
        pool.obtain(
          startX: 0, startY: 0,
          targetX: 500, targetY: 0,
          speed: 100, damage: 10,
        );
      }
      expect(pool.activeCount, 200);

      // Update to let some expire
      pool.updateAll(3.1);
      expect(pool.activeCount, 0);
    });

    test('pool reuse after mass deactivation', () {
      final pool = SimulatedBulletPool();
      final projectiles = <SimulatedProjectile>[];

      for (int i = 0; i < 50; i++) {
        projectiles.add(pool.obtain(
          startX: 0, startY: 0,
          targetX: 500, targetY: 0,
          speed: 100, damage: 10,
        ));
      }

      for (final p in projectiles) {
        pool.returnToPool(p);
      }
      expect(pool.activeCount, 0);

      // Reuse all 50
      for (int i = 0; i < 50; i++) {
        pool.obtain(
          startX: 0, startY: 0,
          targetX: 500, targetY: 0,
          speed: 200, damage: 20,
        );
      }
      expect(pool.poolSize, 50); // No new allocations
      expect(pool.activeCount, 50);
    });
  });
}
