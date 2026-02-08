// Tests for Tower health system and construction lifecycle
// Simulation-based (no Flame engine required)
import 'dart:math' as math;
import 'package:test/test.dart';

/// Simulated Tower with health and construction matching the real implementation
class SimulatedTower {
  SimulatedTower({
    this.typeName = 'pulseArcher',
    this.baseDamage = 15,
    this.baseFireRate = 2.0,
    this.baseRange = 160,
    this.cost = 50,
    double maxHealth = 100,
  }) : _maxHealth = maxHealth,
       _health = maxHealth;

  final String typeName;
  final double baseDamage;
  final double baseFireRate;
  final double baseRange;
  final int cost;

  double _maxHealth;
  double _health;

  // Multipliers
  double _damageMultiplier = 1.0;
  double _fireRateMultiplier = 1.0;
  double _rangeMultiplier = 1.0;
  double _projectileSpeedMultiplier = 1.0;
  double _slowMultiplier = 1.0;

  // Boost states
  bool _isManualBoosted = false;
  int _resonanceBoosters = 0;
  bool get _isBoosted => _isManualBoosted || _resonanceBoosters > 0;

  // Construction state
  bool _isConstructing = false;
  double _constructionProgress = 0.0;
  double _constructionDuration = 2.0;
  double _constructionFlashTimer = 0.0;

  // Cooldown
  double _fireCooldown = 0;

  // Fracture state (damage visualization tracking)
  final List<double> _fractureImpactAngles = [];
  static const int _maxFractureImpacts = 5;

  // Manual targeting
  bool _manualTargeting = false;

  // Getters
  double get health => _health;
  double get maxHealth => _maxHealth;
  double get healthPercent => _health / _maxHealth;
  double get damage => baseDamage * _damageMultiplier * (_isBoosted ? 2.2 : 1.0);
  double get fireRate => baseFireRate * _fireRateMultiplier * (_isBoosted ? 2.2 : 1.0);
  double get range => baseRange * _rangeMultiplier;
  bool get isReady => _fireCooldown <= 0;
  bool get isConstructing => _isConstructing;
  double get constructionProgress => _constructionProgress;
  bool get manualTargeting => _manualTargeting;

  void takeDamage(double amount) {
    _health -= amount;
    if (_health < 0) _health = 0;

    if (amount > 0 && _fractureImpactAngles.length < _maxFractureImpacts) {
      _fractureImpactAngles.add(amount);
    }
  }

  void heal(double amount) {
    _health += amount;
    if (_health > _maxHealth) _health = _maxHealth;

    if (healthPercent > 0.8 && _fractureImpactAngles.isNotEmpty) {
      _fractureImpactAngles.removeLast();
    }
  }

  void setHealth(double health, {double? maxHealth}) {
    if (maxHealth != null) _maxHealth = maxHealth;
    _health = health.clamp(0, _maxHealth);
  }

  void applyUpgradeStats({
    double damageMult = 1.0,
    double rangeMult = 1.0,
    double fireRateMult = 1.0,
    double projectileSpeedMult = 1.0,
    double slowMult = 1.0,
  }) {
    _damageMultiplier = damageMult;
    _rangeMultiplier = rangeMult;
    _fireRateMultiplier = fireRateMult;
    _projectileSpeedMultiplier = projectileSpeedMult;
    _slowMultiplier = slowMult;
  }

  void resetCooldown() {
    _fireCooldown = 1.0 / fireRate;
  }

  void enterFpsBoost() {
    _isManualBoosted = true;
  }

  void exitFpsBoost() {
    _isManualBoosted = false;
  }

  void setResonanceBoost(bool boosted) {
    if (boosted) {
      _resonanceBoosters++;
    } else {
      _resonanceBoosters = math.max(0, _resonanceBoosters - 1);
    }
  }

  void resetResonanceBoost() {
    _resonanceBoosters = 0;
  }

  void setManualMode(bool enabled) {
    _manualTargeting = enabled;
  }

  void startConstruction({double duration = 2.0}) {
    _isConstructing = true;
    _constructionProgress = 0.0;
    _constructionDuration = duration;
    _constructionFlashTimer = 0.0;
  }

  void completeConstruction() {
    if (_isConstructing) {
      _constructionProgress = 1.0;
      _isConstructing = false;
      _constructionFlashTimer = 0.5;
    }
  }

  void cancelConstruction() {
    _isConstructing = false;
    _constructionProgress = 0.0;
    _constructionFlashTimer = 0.0;
  }

  void update(double dt) {
    if (_isConstructing) {
      _constructionProgress += dt / _constructionDuration;
      if (_constructionProgress >= 1.0) {
        _constructionProgress = 1.0;
        _isConstructing = false;
        _constructionFlashTimer = 0.5;
      }
    }

    if (_fireCooldown > 0) {
      _fireCooldown -= dt;
    }

    if (_constructionFlashTimer > 0) {
      _constructionFlashTimer -= dt;
    }
  }
}

void main() {
  group('Tower health system', () {
    test('starts at full health', () {
      final tower = SimulatedTower(maxHealth: 100);
      expect(tower.health, 100);
      expect(tower.healthPercent, 1.0);
    });

    test('takeDamage reduces health', () {
      final tower = SimulatedTower(maxHealth: 100);
      tower.takeDamage(30);
      expect(tower.health, 70);
    });

    test('health does not go below zero', () {
      final tower = SimulatedTower(maxHealth: 100);
      tower.takeDamage(150);
      expect(tower.health, 0);
    });

    test('heal increases health', () {
      final tower = SimulatedTower(maxHealth: 100);
      tower.takeDamage(50);
      tower.heal(30);
      expect(tower.health, 80);
    });

    test('heal does not exceed max health', () {
      final tower = SimulatedTower(maxHealth: 100);
      tower.takeDamage(10);
      tower.heal(50);
      expect(tower.health, 100);
    });

    test('setHealth sets exact value', () {
      final tower = SimulatedTower(maxHealth: 100);
      tower.setHealth(42);
      expect(tower.health, 42);
    });

    test('setHealth clamps to maxHealth', () {
      final tower = SimulatedTower(maxHealth: 100);
      tower.setHealth(150);
      expect(tower.health, 100);
    });

    test('setHealth clamps to zero', () {
      final tower = SimulatedTower(maxHealth: 100);
      tower.setHealth(-50);
      expect(tower.health, 0);
    });

    test('setHealth with new maxHealth', () {
      final tower = SimulatedTower(maxHealth: 100);
      tower.setHealth(80, maxHealth: 200);
      expect(tower.maxHealth, 200);
      expect(tower.health, 80);
    });

    test('healthPercent calculated correctly', () {
      final tower = SimulatedTower(maxHealth: 200);
      tower.takeDamage(50);
      expect(tower.healthPercent, 0.75);
    });

    test('fracture impacts capped at max', () {
      final tower = SimulatedTower(maxHealth: 1000);
      for (int i = 0; i < 10; i++) {
        tower.takeDamage(10);
      }
      expect(tower._fractureImpactAngles.length, 5); // Max 5
    });

    test('heal removes fracture impacts above 80% health', () {
      final tower = SimulatedTower(maxHealth: 100);
      tower.takeDamage(30);
      tower.takeDamage(10);
      expect(tower._fractureImpactAngles.length, 2);

      tower.heal(25); // Now at 85% > 80%
      expect(tower._fractureImpactAngles.length, 1);
    });

    test('zero damage does not add fracture impact', () {
      final tower = SimulatedTower(maxHealth: 100);
      tower.takeDamage(0);
      expect(tower._fractureImpactAngles.isEmpty, isTrue);
    });
  });

  group('Tower construction lifecycle', () {
    test('starts construction correctly', () {
      final tower = SimulatedTower();
      tower.startConstruction(duration: 3.0);

      expect(tower.isConstructing, isTrue);
      expect(tower.constructionProgress, 0.0);
    });

    test('construction progresses with updates', () {
      final tower = SimulatedTower();
      tower.startConstruction(duration: 2.0);

      tower.update(1.0); // 50%
      expect(tower.constructionProgress, closeTo(0.5, 0.01));
      expect(tower.isConstructing, isTrue);
    });

    test('construction completes automatically', () {
      final tower = SimulatedTower();
      tower.startConstruction(duration: 2.0);

      tower.update(2.5); // > duration
      expect(tower.isConstructing, isFalse);
      expect(tower.constructionProgress, 1.0);
    });

    test('completeConstruction finishes instantly', () {
      final tower = SimulatedTower();
      tower.startConstruction(duration: 5.0);
      tower.update(0.5); // Only 10%

      tower.completeConstruction();
      expect(tower.isConstructing, isFalse);
      expect(tower.constructionProgress, 1.0);
    });

    test('completeConstruction does nothing if not constructing', () {
      final tower = SimulatedTower();
      tower.completeConstruction(); // Should not throw
      expect(tower.isConstructing, isFalse);
    });

    test('cancelConstruction resets all state', () {
      final tower = SimulatedTower();
      tower.startConstruction(duration: 3.0);
      tower.update(1.0);

      tower.cancelConstruction();
      expect(tower.isConstructing, isFalse);
      expect(tower.constructionProgress, 0.0);
    });

    test('short construction completes quickly', () {
      final tower = SimulatedTower();
      tower.startConstruction(duration: 0.5);

      tower.update(0.5);
      expect(tower.isConstructing, isFalse);
    });

    test('construction default duration is 2 seconds', () {
      final tower = SimulatedTower();
      tower.startConstruction(); // default 2.0

      tower.update(1.0);
      expect(tower.constructionProgress, closeTo(0.5, 0.01));
    });
  });

  group('Tower boost system', () {
    test('FPS boost doubles damage', () {
      final tower = SimulatedTower(baseDamage: 10);
      final normalDamage = tower.damage;

      tower.enterFpsBoost();
      expect(tower.damage, closeTo(normalDamage * 2.2, 0.01));
    });

    test('exit FPS boost returns to normal', () {
      final tower = SimulatedTower(baseDamage: 10);
      final normalDamage = tower.damage;

      tower.enterFpsBoost();
      tower.exitFpsBoost();
      expect(tower.damage, closeTo(normalDamage, 0.01));
    });

    test('resonance boost activates', () {
      final tower = SimulatedTower(baseDamage: 10);
      final normalDamage = tower.damage;

      tower.setResonanceBoost(true);
      expect(tower.damage, closeTo(normalDamage * 2.2, 0.01));
    });

    test('multiple resonance boosters stack count', () {
      final tower = SimulatedTower();
      tower.setResonanceBoost(true);
      tower.setResonanceBoost(true);

      tower.setResonanceBoost(false); // Decrement one
      expect(tower._isBoosted, isTrue); // Still boosted (1 left)
    });

    test('resonance boost does not go negative', () {
      final tower = SimulatedTower();
      tower.setResonanceBoost(false);
      tower.setResonanceBoost(false);
      expect(tower._isBoosted, isFalse);
    });

    test('resetResonanceBoost clears all', () {
      final tower = SimulatedTower();
      tower.setResonanceBoost(true);
      tower.setResonanceBoost(true);
      tower.setResonanceBoost(true);

      tower.resetResonanceBoost();
      expect(tower._isBoosted, isFalse);
    });

    test('FPS boost and resonance both active', () {
      final tower = SimulatedTower(baseDamage: 10);
      tower.enterFpsBoost();
      tower.setResonanceBoost(true);

      // Both set _isBoosted = true, damage should be 2.2x
      expect(tower.damage, closeTo(10 * 2.2, 0.01));
    });
  });

  group('Tower cooldown and firing readiness', () {
    test('starts ready to fire', () {
      final tower = SimulatedTower();
      expect(tower.isReady, isTrue);
    });

    test('resetCooldown makes tower not ready', () {
      final tower = SimulatedTower(baseFireRate: 2.0);
      tower.resetCooldown();
      expect(tower.isReady, isFalse);
    });

    test('cooldown recovers over time', () {
      final tower = SimulatedTower(baseFireRate: 2.0);
      tower.resetCooldown(); // cooldown = 0.5s

      tower.update(0.6);
      expect(tower.isReady, isTrue);
    });

    test('cooldown duration matches fire rate', () {
      final tower = SimulatedTower(baseFireRate: 4.0);
      tower.resetCooldown(); // cooldown = 0.25s

      tower.update(0.2);
      expect(tower.isReady, isFalse);

      tower.update(0.1);
      expect(tower.isReady, isTrue);
    });
  });

  group('Tower upgrade stats', () {
    test('damage multiplier applies correctly', () {
      final tower = SimulatedTower(baseDamage: 10);
      tower.applyUpgradeStats(damageMult: 1.5);
      expect(tower.damage, closeTo(15, 0.01));
    });

    test('range multiplier applies correctly', () {
      final tower = SimulatedTower(baseRange: 160);
      tower.applyUpgradeStats(rangeMult: 1.2);
      expect(tower.range, closeTo(192, 0.01));
    });

    test('multiple multipliers apply together', () {
      final tower = SimulatedTower(baseDamage: 10, baseFireRate: 2.0);
      tower.applyUpgradeStats(damageMult: 1.5, fireRateMult: 1.3);
      expect(tower.damage, closeTo(15, 0.01));
      expect(tower.fireRate, closeTo(2.6, 0.01));
    });
  });

  group('Tower manual targeting', () {
    test('manual mode defaults to off', () {
      final tower = SimulatedTower();
      expect(tower.manualTargeting, isFalse);
    });

    test('setManualMode enables manual targeting', () {
      final tower = SimulatedTower();
      tower.setManualMode(true);
      expect(tower.manualTargeting, isTrue);
    });

    test('disabling manual mode works', () {
      final tower = SimulatedTower();
      tower.setManualMode(true);
      tower.setManualMode(false);
      expect(tower.manualTargeting, isFalse);
    });
  });
}
