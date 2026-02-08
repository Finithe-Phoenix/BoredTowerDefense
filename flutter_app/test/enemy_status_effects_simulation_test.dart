// Tests for Enemy status effects: heal, slow, burn, shield, boost, stun
// Simulation-based (no Flame engine required)
import 'dart:math' as math;
import 'package:test/test.dart';

/// Simulated Enemy with status effects matching the real implementation
class SimulatedEnemy {
  SimulatedEnemy({
    this.maxHealth = 100,
    this.baseSpeed = 80,
    this.isPhantom = false,
    this.speedMult = 1.0,
    this.healthMult = 1.0,
    this.threatTier = 0,
  }) {
    _maxHealth = maxHealth * healthMult * _tierHealthMult;
    _health = _maxHealth;
    _speed = baseSpeed * speedMult * _tierSpeedMult;
  }

  final double maxHealth;
  final double baseSpeed;
  final bool isPhantom;
  final double speedMult;
  final double healthMult;
  final int threatTier;

  late double _maxHealth;
  late double _health;
  late double _speed;

  // Slow effect
  double _slowFactor = 1.0;
  double _slowDuration = 0;

  // Burn effect (damage over time)
  double _burnDamage = 0;
  double _burnDuration = 0;
  double _burnTickTimer = 0;
  static const double _burnTickInterval = 0.5;

  // Shield effect (damage reduction)
  double _shieldAmount = 0;
  double _shieldDuration = 0;

  // Boost effect (speed increase)
  double _boostFactor = 1.0;
  double _boostDuration = 0;

  // Stun effect (complete stop)
  double _stunDuration = 0;

  // Reveal (for phantoms)
  bool _isRevealed = false;
  double _revealTimer = 0;
  static const double _revealDuration = 3.0;

  // Death tracking
  bool deathCalled = false;
  double totalBurnDamage = 0;

  double get health => _health;
  double get currentMaxHealth => _maxHealth;
  double get speed => _stunDuration > 0 ? 0 : _speed * _slowFactor * _boostFactor;
  double get healthPercent => _health / _maxHealth;
  bool get isAlive => _health > 0;
  bool get isSlowed => _slowFactor < 1.0;
  bool get isBurning => _burnDuration > 0;
  bool get hasShield => _shieldAmount > 0;
  bool get isBoosted => _boostFactor > 1.0;
  bool get isStunned => _stunDuration > 0;
  bool get isRevealed => _isRevealed;
  bool get hasActiveStatusEffects =>
      isSlowed || isBurning || hasShield || isBoosted || isStunned;

  double get _tierHealthMult => 1 + (threatTier * 0.2);
  double get _tierSpeedMult => 1 + (threatTier * 0.04);

  void takeDamage(double amount) {
    if (!isAlive) return;

    if (isPhantom) reveal();

    // Shield absorbs damage first
    if (_shieldAmount > 0) {
      final absorbed = math.min(_shieldAmount, amount);
      _shieldAmount -= absorbed;
      amount -= absorbed;
    }

    _health -= amount;
    if (_health <= 0) {
      _health = 0;
      deathCalled = true;
    }
  }

  void applyHeal(double amount) {
    if (!isAlive) return;
    final healAmount = amount.clamp(0, _maxHealth - _health);
    if (healAmount <= 0) return;
    _health += healAmount;
  }

  void applySlow(double factor, double duration) {
    final newFactor = (1.0 - factor).clamp(0.1, 1.0);
    if (newFactor < _slowFactor) {
      _slowFactor = newFactor;
    }
    if (duration > _slowDuration) {
      _slowDuration = duration;
    }
  }

  void applyBurn(double damagePerTick, double duration) {
    _burnDamage = damagePerTick;
    _burnDuration = duration;
    _burnTickTimer = 0;
  }

  void applyShield(double amount, double duration) {
    _shieldAmount = amount;
    _shieldDuration = duration;
    _shieldMaxAmount = amount;
  }

  double _shieldMaxAmount = 0;

  void applyBoost(double factor, double duration) {
    _boostFactor = factor;
    _boostDuration = duration;
  }

  void applyStun(double duration) {
    _stunDuration = duration;
  }

  void reveal() {
    if (isPhantom && !_isRevealed) {
      _isRevealed = true;
      _revealTimer = _revealDuration;
    } else if (isPhantom) {
      _revealTimer = _revealDuration;
    }
  }

  void updateStatusTimers(double dt) {
    // Slow decay
    if (_slowDuration > 0) {
      _slowDuration -= dt;
      if (_slowDuration <= 0) {
        _slowDuration = 0;
        _slowFactor = 1.0;
      }
    }

    // Burn damage tick
    if (_burnDuration > 0) {
      _burnTickTimer += dt;
      while (_burnTickTimer >= _burnTickInterval && _burnDuration > 0) {
        _burnTickTimer -= _burnTickInterval;
        _burnDuration -= _burnTickInterval;
        final dmg = _burnDamage;
        totalBurnDamage += dmg;
        _health -= dmg;
        if (_health <= 0) {
          _health = 0;
          deathCalled = true;
        }
      }
      if (_burnDuration <= 0) {
        _burnDuration = 0;
        _burnDamage = 0;
        _burnTickTimer = 0;
      }
    }

    // Shield duration decay
    if (_shieldDuration > 0) {
      _shieldDuration -= dt;
      if (_shieldDuration <= 0) {
        _shieldDuration = 0;
        _shieldAmount = 0;
      }
    }

    // Boost decay
    if (_boostDuration > 0) {
      _boostDuration -= dt;
      if (_boostDuration <= 0) {
        _boostDuration = 0;
        _boostFactor = 1.0;
      }
    }

    // Stun decay
    if (_stunDuration > 0) {
      _stunDuration -= dt;
      if (_stunDuration <= 0) {
        _stunDuration = 0;
      }
    }

    // Reveal timer for phantoms
    if (isPhantom && _isRevealed) {
      _revealTimer -= dt;
      if (_revealTimer <= 0) {
        _isRevealed = false;
        _revealTimer = 0;
      }
    }
  }
}

void main() {
  group('Enemy applyHeal', () {
    test('heals up to max health', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.takeDamage(50);
      expect(enemy.health, 50);

      enemy.applyHeal(30);
      expect(enemy.health, 80);
    });

    test('does not heal above max health', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.takeDamage(10);
      enemy.applyHeal(50);
      expect(enemy.health, enemy.currentMaxHealth);
    });

    test('does not heal dead enemy', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.takeDamage(200);
      expect(enemy.isAlive, isFalse);

      enemy.applyHeal(50);
      expect(enemy.health, 0);
    });

    test('heal with zero amount does nothing', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.takeDamage(30);
      final healthBefore = enemy.health;

      enemy.applyHeal(0);
      expect(enemy.health, healthBefore);
    });

    test('heal when at full health does nothing', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.applyHeal(50);
      expect(enemy.health, enemy.currentMaxHealth);
    });

    test('heal with negative amount is clamped to zero', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.takeDamage(30);
      final healthBefore = enemy.health;

      enemy.applyHeal(-10);
      expect(enemy.health, healthBefore);
    });

    test('multiple small heals accumulate correctly', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.takeDamage(60);
      expect(enemy.health, 40);

      for (int i = 0; i < 10; i++) {
        enemy.applyHeal(5);
      }
      expect(enemy.health, 90);
    });
  });

  group('Enemy takeDamage edge cases', () {
    test('damage when already dead does nothing', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.takeDamage(150);
      expect(enemy.health, 0);
      expect(enemy.deathCalled, isTrue);

      enemy.deathCalled = false;
      enemy.takeDamage(50);
      expect(enemy.health, 0);
      expect(enemy.deathCalled, isFalse);
    });

    test('exact lethal damage kills enemy', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.takeDamage(100);
      expect(enemy.isAlive, isFalse);
      expect(enemy.health, 0);
      expect(enemy.deathCalled, isTrue);
    });

    test('multiple rapid damage calls accumulate', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      for (int i = 0; i < 10; i++) {
        enemy.takeDamage(8);
      }
      expect(enemy.health, 20);
    });

    test('damage reveals phantom enemies', () {
      final enemy = SimulatedEnemy(maxHealth: 100, isPhantom: true);
      expect(enemy.isRevealed, isFalse);

      enemy.takeDamage(10);
      expect(enemy.isRevealed, isTrue);
    });
  });

  group('Enemy applySlow', () {
    test('applies slow factor correctly', () {
      final enemy = SimulatedEnemy();
      final normalSpeed = enemy.speed;

      enemy.applySlow(0.5, 3.0); // 50% slow for 3 seconds
      expect(enemy.isSlowed, isTrue);
      expect(enemy.speed, closeTo(normalSpeed * 0.5, 0.01));
    });

    test('slow expires after duration', () {
      final enemy = SimulatedEnemy();
      enemy.applySlow(0.5, 1.0);
      expect(enemy.isSlowed, isTrue);

      enemy.updateStatusTimers(1.0);
      expect(enemy.isSlowed, isFalse);
      expect(enemy.speed, enemy.baseSpeed);
    });

    test('stronger slow replaces weaker one', () {
      final enemy = SimulatedEnemy();
      enemy.applySlow(0.3, 2.0); // 30% slow (factor 0.7)
      final slowedSpeed1 = enemy.speed;

      enemy.applySlow(0.5, 2.0); // 50% slow (factor 0.5) - stronger
      expect(enemy.speed, lessThan(slowedSpeed1));
    });

    test('weaker slow does not replace stronger one', () {
      final enemy = SimulatedEnemy();
      enemy.applySlow(0.5, 2.0); // 50% slow (factor 0.5)
      final slowedSpeed = enemy.speed;

      enemy.applySlow(0.3, 2.0); // 30% slow (factor 0.7) - weaker
      expect(enemy.speed, slowedSpeed);
    });

    test('longer duration replaces shorter one', () {
      final enemy = SimulatedEnemy();
      enemy.applySlow(0.5, 1.0);
      enemy.applySlow(0.5, 3.0);

      enemy.updateStatusTimers(1.5); // Would have expired with 1s duration
      expect(enemy.isSlowed, isTrue);
    });

    test('slow factor clamped to minimum 0.1', () {
      final enemy = SimulatedEnemy();
      enemy.applySlow(1.0, 2.0); // 100% slow request
      expect(enemy.speed, greaterThan(0)); // Should not stop completely
    });

    test('slow factor clamped to maximum 1.0', () {
      final enemy = SimulatedEnemy();
      enemy.applySlow(-0.5, 2.0); // Negative slow (should clamp)
      expect(enemy.isSlowed, isFalse); // 1.0 - (-0.5) = 1.5 clamped to 1.0
    });
  });

  group('Enemy burn effect', () {
    test('applies burn damage over time', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.applyBurn(10, 2.0); // 10 dmg per tick for 2 seconds
      expect(enemy.isBurning, isTrue);

      enemy.updateStatusTimers(0.5); // One tick
      expect(enemy.totalBurnDamage, 10);
    });

    test('burn damage multiple ticks', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.applyBurn(5, 2.0);

      // Simulate 2 seconds at 0.1s timesteps
      for (int i = 0; i < 20; i++) {
        enemy.updateStatusTimers(0.1);
      }
      // 2.0 / 0.5 tick interval = 4 ticks × 5 dmg = 20 total
      expect(enemy.totalBurnDamage, closeTo(20, 1));
    });

    test('burn expires after duration', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.applyBurn(5, 1.0);

      enemy.updateStatusTimers(1.5);
      expect(enemy.isBurning, isFalse);
    });

    test('burn can kill enemy', () {
      final enemy = SimulatedEnemy(maxHealth: 20);
      enemy.applyBurn(15, 5.0); // 15 dmg per 0.5s tick

      // After 2 ticks (1 second), 30 dmg total > 20 HP
      enemy.updateStatusTimers(1.0);
      expect(enemy.isAlive, isFalse);
    });

    test('new burn replaces previous burn', () {
      final enemy = SimulatedEnemy(maxHealth: 200);
      enemy.applyBurn(5, 2.0);
      enemy.applyBurn(10, 3.0); // Stronger burn

      enemy.updateStatusTimers(0.5);
      expect(enemy.totalBurnDamage, 10); // 10, not 5
    });
  });

  group('Enemy shield effect', () {
    test('shield absorbs damage', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.applyShield(30, 5.0);
      expect(enemy.hasShield, isTrue);

      enemy.takeDamage(20);
      expect(enemy.health, 100); // No HP loss, shield absorbed
    });

    test('shield partially absorbs large damage', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.applyShield(20, 5.0);

      enemy.takeDamage(50);
      expect(enemy.health, 70); // 50 - 20 shield = 30 damage to HP
    });

    test('shield depletes after absorbing enough damage', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.applyShield(30, 5.0);

      enemy.takeDamage(30);
      expect(enemy.hasShield, isFalse);
    });

    test('shield expires after duration', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.applyShield(50, 2.0);

      enemy.updateStatusTimers(2.5);
      expect(enemy.hasShield, isFalse);
    });

    test('multiple small hits deplete shield gradually', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.applyShield(25, 10.0);

      for (int i = 0; i < 5; i++) {
        enemy.takeDamage(5);
      }
      expect(enemy.hasShield, isFalse);
      expect(enemy.health, 100); // All damage absorbed
    });
  });

  group('Enemy boost effect', () {
    test('boost increases speed', () {
      final enemy = SimulatedEnemy();
      final normalSpeed = enemy.speed;

      enemy.applyBoost(1.5, 3.0); // 50% speed boost for 3 seconds
      expect(enemy.isBoosted, isTrue);
      expect(enemy.speed, closeTo(normalSpeed * 1.5, 0.01));
    });

    test('boost expires after duration', () {
      final enemy = SimulatedEnemy();
      final normalSpeed = enemy.speed;

      enemy.applyBoost(1.5, 1.0);
      enemy.updateStatusTimers(1.5);

      expect(enemy.isBoosted, isFalse);
      expect(enemy.speed, closeTo(normalSpeed, 0.01));
    });

    test('boost factor of 1.0 is not considered boosted', () {
      final enemy = SimulatedEnemy();
      enemy.applyBoost(1.0, 5.0);
      expect(enemy.isBoosted, isFalse);
    });
  });

  group('Enemy stun effect', () {
    test('stun stops enemy completely', () {
      final enemy = SimulatedEnemy();
      enemy.applyStun(2.0);
      expect(enemy.isStunned, isTrue);
      expect(enemy.speed, 0);
    });

    test('stun expires after duration', () {
      final enemy = SimulatedEnemy();
      enemy.applyStun(1.0);

      enemy.updateStatusTimers(1.5);
      expect(enemy.isStunned, isFalse);
      expect(enemy.speed, greaterThan(0));
    });

    test('stun overrides slow and boost for speed calculation', () {
      final enemy = SimulatedEnemy();
      enemy.applySlow(0.5, 5.0);
      enemy.applyBoost(2.0, 5.0);
      enemy.applyStun(1.0);

      expect(enemy.speed, 0); // Stun overrides everything
    });

    test('after stun wears off, slow and boost still active', () {
      final enemy = SimulatedEnemy();
      enemy.applySlow(0.5, 5.0);
      enemy.applyStun(1.0);

      enemy.updateStatusTimers(1.5); // Stun expires
      expect(enemy.isStunned, isFalse);
      expect(enemy.isSlowed, isTrue); // Slow still active
      expect(enemy.speed, lessThan(enemy.baseSpeed));
    });
  });

  group('Enemy phantom reveal', () {
    test('reveal sets isRevealed flag', () {
      final enemy = SimulatedEnemy(isPhantom: true);
      expect(enemy.isRevealed, isFalse);

      enemy.reveal();
      expect(enemy.isRevealed, isTrue);
    });

    test('reveal timer expires after duration', () {
      final enemy = SimulatedEnemy(isPhantom: true);
      enemy.reveal();

      enemy.updateStatusTimers(3.5); // > 3.0 reveal duration
      expect(enemy.isRevealed, isFalse);
    });

    test('re-reveal refreshes timer', () {
      final enemy = SimulatedEnemy(isPhantom: true);
      enemy.reveal();
      enemy.updateStatusTimers(2.0); // 2/3 through

      enemy.reveal(); // Refresh
      enemy.updateStatusTimers(2.0); // Would have expired without refresh
      expect(enemy.isRevealed, isTrue);
    });

    test('non-phantom reveal has no effect', () {
      final enemy = SimulatedEnemy(isPhantom: false);
      enemy.reveal();
      expect(enemy.isRevealed, isFalse);
    });

    test('damage reveals phantom', () {
      final enemy = SimulatedEnemy(isPhantom: true, maxHealth: 100);
      enemy.takeDamage(10);
      expect(enemy.isRevealed, isTrue);
    });
  });

  group('Multiple status effects interaction', () {
    test('all effects can be active simultaneously', () {
      final enemy = SimulatedEnemy(maxHealth: 200);
      enemy.applySlow(0.5, 5.0);
      enemy.applyBurn(5, 3.0);
      enemy.applyShield(30, 5.0);
      enemy.applyBoost(1.3, 5.0);
      enemy.applyStun(0.5);

      expect(enemy.hasActiveStatusEffects, isTrue);
      expect(enemy.isSlowed, isTrue);
      expect(enemy.isBurning, isTrue);
      expect(enemy.hasShield, isTrue);
      expect(enemy.isBoosted, isTrue);
      expect(enemy.isStunned, isTrue);
    });

    test('effects expire independently', () {
      final enemy = SimulatedEnemy(maxHealth: 200);
      enemy.applySlow(0.5, 1.0);
      enemy.applyBoost(1.5, 2.0);
      enemy.applyStun(0.5);

      enemy.updateStatusTimers(0.7); // Stun expires
      expect(enemy.isStunned, isFalse);
      expect(enemy.isSlowed, isTrue);
      expect(enemy.isBoosted, isTrue);

      enemy.updateStatusTimers(0.5); // Slow expires
      expect(enemy.isSlowed, isFalse);
      expect(enemy.isBoosted, isTrue);

      enemy.updateStatusTimers(1.0); // Boost expires
      expect(enemy.isBoosted, isFalse);
    });

    test('slow and boost interact on speed', () {
      final enemy = SimulatedEnemy(baseSpeed: 100, speedMult: 1.0);
      enemy.applySlow(0.3, 5.0); // factor = 0.7
      enemy.applyBoost(1.5, 5.0); // x1.5

      // Speed = 100 * 0.7 * 1.5 = 105
      expect(enemy.speed, closeTo(105, 1));
    });

    test('shield absorbs burn damage does not apply (burn bypasses shield)', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.applyShield(50, 10.0);
      enemy.applyBurn(10, 2.0);

      enemy.updateStatusTimers(0.5); // One burn tick
      // Burn damage goes directly to HP (not through takeDamage/shield)
      expect(enemy.health, lessThan(100));
    });

    test('heal while shielded works on HP', () {
      final enemy = SimulatedEnemy(maxHealth: 100);
      enemy.takeDamage(40);
      enemy.applyShield(30, 5.0);

      enemy.applyHeal(20);
      expect(enemy.health, 80);
    });

    test('status effects persist through damage', () {
      final enemy = SimulatedEnemy(maxHealth: 200);
      enemy.applySlow(0.5, 5.0);
      enemy.applyBoost(1.3, 5.0);

      enemy.takeDamage(50);
      expect(enemy.isSlowed, isTrue);
      expect(enemy.isBoosted, isTrue);
    });
  });

  group('Enemy with threat tiers', () {
    test('threat tier increases health', () {
      final base = SimulatedEnemy(maxHealth: 100, threatTier: 0);
      final tier1 = SimulatedEnemy(maxHealth: 100, threatTier: 1);
      final tier3 = SimulatedEnemy(maxHealth: 100, threatTier: 3);

      expect(tier1.currentMaxHealth, greaterThan(base.currentMaxHealth));
      expect(tier3.currentMaxHealth, greaterThan(tier1.currentMaxHealth));
    });

    test('threat tier health formula is correct', () {
      // tierHealthMult = 1 + (tier * 0.2)
      final enemy = SimulatedEnemy(maxHealth: 100, healthMult: 1.0, threatTier: 2);
      // 100 * 1.0 * (1 + 2*0.2) = 100 * 1.4 = 140
      expect(enemy.currentMaxHealth, closeTo(140, 0.01));
    });

    test('threat tier speed formula is correct', () {
      // tierSpeedMult = 1 + (tier * 0.04)
      final enemy = SimulatedEnemy(baseSpeed: 100, speedMult: 1.0, threatTier: 3);
      // 100 * 1.0 * (1 + 3*0.04) = 100 * 1.12 = 112
      expect(enemy.speed, closeTo(112, 0.01));
    });
  });

  group('hasActiveStatusEffects computed property', () {
    test('false when no effects active', () {
      final enemy = SimulatedEnemy();
      expect(enemy.hasActiveStatusEffects, isFalse);
    });

    test('true with only slow', () {
      final enemy = SimulatedEnemy();
      enemy.applySlow(0.3, 2.0);
      expect(enemy.hasActiveStatusEffects, isTrue);
    });

    test('true with only burn', () {
      final enemy = SimulatedEnemy();
      enemy.applyBurn(5, 2.0);
      expect(enemy.hasActiveStatusEffects, isTrue);
    });

    test('false after all effects expire', () {
      final enemy = SimulatedEnemy();
      enemy.applySlow(0.5, 1.0);
      enemy.applyStun(0.5);

      enemy.updateStatusTimers(2.0);
      expect(enemy.hasActiveStatusEffects, isFalse);
    });
  });
}
