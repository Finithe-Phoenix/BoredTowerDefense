import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'enemy.dart';
import '../managers/enemy_manager.dart';
import '../../ui/theme/neon_theme.dart';
import '../../models/upgrade_data.dart';

/// Targeting modes for towers
enum TargetMode { first, last, strongest, weakest, closest }

/// Tower type definitions with stats
enum TowerType {
  pulseArcher(
    name: 'Pulse Archer',
    damage: 15,
    fireRate: 2.0, // shots per second
    range: 160,
    cost: 50,
    color: Color(0xFF00FFFF), // Cyan
    projectileSpeed: 400,
    slowAmount: 0,
    slowDuration: 0,
    canDetectPhantom: false,
  ),
  circuitCannon(
    name: 'Circuit Cannon',
    damage: 50,
    fireRate: 0.5,
    range: 140,
    cost: 100,
    color: Color(0xFFFF00FF), // Magenta
    projectileSpeed: 250,
    slowAmount: 0,
    slowDuration: 0,
    canDetectPhantom: false,
  ),
  phaseMage(
    name: 'Phase Mage',
    damage: 25,
    fireRate: 1.2,
    range: 200,
    cost: 80,
    color: Color(0xFF9C27B0), // Purple
    projectileSpeed: 350,
    slowAmount: 0.5, // 50% slow
    slowDuration: 1.5,
    canDetectPhantom: true, // Can detect and reveal phantom enemies!
  ),
  glimmerField(
    name: 'Glimmer Field',
    damage: 8,
    fireRate: 4.0, // Very fast
    range: 120,
    cost: 120,
    color: Color(0xFFFFEB3B), // Yellow
    projectileSpeed: 500,
    slowAmount: 0.3, // 70% slow
    slowDuration: 0.5,
    canDetectPhantom: false,
  ),
  ionSniper(
    name: 'Ion Sniper',
    damage: 180,
    fireRate: 0.4,
    range: 300,
    cost: 250,
    color: Color(0xFF00E5FF),
    projectileSpeed: 800,
  ),
  teslaTerminal(
    name: 'Tesla Terminal',
    damage: 12,
    fireRate: 3.5,
    range: 150,
    cost: 180,
    color: Color(0xFFFFFF00),
    projectileSpeed: 0, // Instant hit (lightning)
  ),
  resonanceSiphon(
    name: 'Resonance Siphon',
    damage: 0,
    fireRate: 1.0,
    range: 100,
    cost: 150,
    color: Color(0xFFFF0066),
    projectileSpeed: 0,
  ),
  neuralDisruptor(
    name: 'Neural Disruptor',
    damage: 5,
    fireRate: 2.0,
    range: 130,
    cost: 200,
    color: Color(0xFF00FF00),
    projectileSpeed: 450,
  );

  const TowerType({
    required this.name,
    required this.damage,
    required this.fireRate,
    required this.range,
    required this.cost,
    required this.color,
    required this.projectileSpeed,
    this.slowAmount = 0,
    this.slowDuration = 0,
    this.canDetectPhantom = false,
  });

  final String name;
  final double damage;
  final double fireRate;
  final double range;
  final int cost;
  final Color color;
  final double projectileSpeed;
  final double slowAmount; // 0 = no slow, 0.5 = 50% slow
  final double slowDuration;
  final bool canDetectPhantom; // Whether this tower can see and attack phantom enemies

  /// Whether this tower applies slow on hit
  bool get appliesSlow => slowAmount > 0 && slowDuration > 0;
}

/// Callback for when tower fires
typedef TowerFireCallback = void Function(
    Tower tower, Enemy target, Vector2 targetPos);

class Tower extends PositionComponent {
  static bool lowFx = false;

  Tower({
    required Vector2 position,
    required double size,
    this.type = TowerType.pulseArcher,
    this.targetMode = TargetMode.first,
    this.onFire,
    this.buildCost = 0,
    double damageMultiplier = 1.0,
    double rangeMultiplier = 1.0,
    double fireRateMultiplier = 1.0,
    double projectileSpeedMultiplier = 1.0,
    double slowMultiplier = 1.0,
  }) : _fireCooldown = 0,
       _animationPhase = math.Random().nextDouble() * math.pi * 2,
       _random = math.Random(),
       _damageMultiplier = damageMultiplier,
       _rangeMultiplier = rangeMultiplier,
       _fireRateMultiplier = fireRateMultiplier,
       _projectileSpeedMultiplier = projectileSpeedMultiplier,
       _slowMultiplier = slowMultiplier {
    anchor = Anchor.topLeft;
    this.position = position;
    this.size = Vector2.all(size);
    _initializeParticles();
  }

  final TowerType type;
  TargetMode targetMode;
  TowerFireCallback? onFire;
  final int buildCost;
  final math.Random _random;
  double _damageMultiplier;
  double _rangeMultiplier;
  double _fireRateMultiplier;
  double _projectileSpeedMultiplier;
  double _slowMultiplier;
  int _resonanceBoosters = 0;
  bool get _isBoosted => _isManualBoosted || _resonanceBoosters > 0;
  bool _isManualBoosted = false;

  Enemy? _currentTarget;
  Enemy? _manualTarget;
  bool _manualTargeting = false;
  double _fireCooldown;
  double _animationPhase;
  double _pulseAnimation = 0;
  double _rotationAngle = 0;
  double _chargeLevel = 0;
  bool _isFiring = false;
  double _fireFlashTimer = 0;
  final List<Enemy> _candidateEnemies = [];

  // Idle animation particles (orbiting energy)
  final List<_TowerParticle> _orbitParticles = [];
  static const int _particleCount = 6;

  // Muzzle flash particles
  final List<_MuzzleParticle> _muzzleParticles = [];
  static const int _muzzleParticleCount = 12;

  // Electric arc points for Phase Mage
  final List<Offset> _arcPoints = [];

  void _initializeParticles() {
    _orbitParticles.clear();
    for (int i = 0; i < _particleCount; i++) {
      _orbitParticles.add(_TowerParticle(
        angle: (i / _particleCount) * math.pi * 2,
        radius: 12 + _random.nextDouble() * 4,
        speed: 1.0 + _random.nextDouble() * 0.5,
        size: 1.5 + _random.nextDouble(),
        phase: _random.nextDouble() * math.pi * 2,
      ));
    }

    // Initialize muzzle particles
    _muzzleParticles.clear();
    for (int i = 0; i < _muzzleParticleCount; i++) {
      _muzzleParticles.add(_MuzzleParticle(
        angle: _random.nextDouble() * math.pi * 2,
        speed: 50 + _random.nextDouble() * 100,
        size: 1.5 + _random.nextDouble() * 2,
        lifetime: 0,
        maxLifetime: 0.15 + _random.nextDouble() * 0.1,
      ));
    }
  }

  /// Center position for targeting calculations
  Vector2 get centerPosition => position + size / 2;

  double get _boostMultiplier => _isBoosted ? 1.2 : 1.0;

  /// Get tower stats from type
  double get damage => type.damage * _damageMultiplier * (_isBoosted ? 2.2 : 1.0);
  double get fireRate => type.fireRate * _fireRateMultiplier * (_isBoosted ? 2.2 : 1.0);
  double get range => type.range * _rangeMultiplier;
  Color get color => type.color;
  double get projectileSpeed => type.projectileSpeed * _projectileSpeedMultiplier;
  double get slowAmount => type.slowAmount * _slowMultiplier;
  double get slowDuration => type.slowDuration;

  // FPS view support
  double get currentDamage => damage;
  double get currentFireRate => fireRate;
  double get currentRange => range;
  Enemy? get currentTarget => _currentTarget;
  double _lastFireTime = 0;
  double get lastFireTime => _lastFireTime;

  /// Whether the tower is ready to fire
  bool get isReady => _fireCooldown <= 0;

  void applyUpgradeStats(UpgradeStats stats) {
    _damageMultiplier = stats.towerDamageMult;
    _rangeMultiplier = stats.towerRangeMult;
    _fireRateMultiplier = stats.towerFireRateMult;
    _projectileSpeedMultiplier = stats.projectileSpeedMult;
    _slowMultiplier = stats.slowMult;
  }

  /// Manually reset the fire cooldown after a shot
  void resetCooldown() {
    _fireCooldown = 1.0 / fireRate;
    _chargeLevel = 0;
    _triggerMuzzleFlash();
  }

  void enterFpsBoost() {
    _isManualBoosted = true;
  }

  void exitFpsBoost() {
    _isManualBoosted = false;
  }

  void setResonanceBoost(bool boosted) {
    if (boosted) _resonanceBoosters++;
    else _resonanceBoosters = math.max(0, _resonanceBoosters - 1);
  }

  void resetResonanceBoost() {
    _resonanceBoosters = 0;
  }

  bool get manualTargeting => _manualTargeting;

  Enemy? get manualTarget => _manualTarget;

  void setManualMode(bool enabled) {
    _manualTargeting = enabled;
    if (!enabled) {
      _manualTarget = null;
    }
  }

  void setManualTarget(Enemy? target) {
    _manualTarget = target;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _fireCooldown -= dt;

    // Animation updates
    _animationPhase += dt * 2;
    _pulseAnimation = (math.sin(_animationPhase) + 1) / 2;

    // Update fire flash timer
    if (_fireFlashTimer > 0) {
      _fireFlashTimer -= dt;
      if (_fireFlashTimer <= 0) {
        _isFiring = false;
      }
    }

    // Update orbiting particles
    for (final particle in _orbitParticles) {
      particle.update(dt, type);
    }

    // Update muzzle particles
    for (final particle in _muzzleParticles) {
      particle.update(dt);
    }

    // Generate electric arcs for Phase Mage idle
    if (type == TowerType.phaseMage && _random.nextDouble() < dt * 3) {
      _generateElectricArc();
    }

    // Charge animation when cooldown is ready
    if (_fireCooldown <= 0 && _chargeLevel < 1) {
      _chargeLevel = (_chargeLevel + dt * 3).clamp(0, 1);
    }

    // Rotate towards target
    if (_currentTarget != null) {
      if (!_isTargetValid(_currentTarget!)) {
        _currentTarget = null;
      } else {
        final direction = _currentTarget!.position - centerPosition;
        final targetAngle = math.atan2(direction.y, direction.x);
        // Smooth rotation
        final angleDiff = _normalizeAngle(targetAngle - _rotationAngle);
        _rotationAngle += angleDiff * dt * 8;
      }
    }
  }

  /// Update targeting and shooting
  void updateTargeting(EnemyManager enemyManager) {
    final center = centerPosition;
    _currentTarget = null;
    if (_manualTargeting && _manualTarget != null) {
      if (_isTargetValid(_manualTarget!)) {
        _currentTarget = _manualTarget;
      } else {
        _manualTarget = null;
      }
    }

    if (_currentTarget == null) {
      enemyManager.queryEnemiesInRange(center, range, _candidateEnemies);
      _currentTarget = _findTarget(_candidateEnemies, center);
    }

    // Fire if ready and has target
    if (_currentTarget != null && _fireCooldown <= 0) {
      _fire(_currentTarget!);
      _fireCooldown = 1.0 / fireRate;
      _chargeLevel = 0;
      _triggerMuzzleFlash();
    }
  }

  void _generateElectricArc() {
    _arcPoints.clear();
    final arcLength = 8 + _random.nextDouble() * 6;
    final startAngle = _random.nextDouble() * math.pi * 2;
    Offset current = Offset(
      math.cos(startAngle) * 8,
      math.sin(startAngle) * 8,
    );
    _arcPoints.add(current);

    for (int i = 0; i < 4; i++) {
      final angle = startAngle + (i + 1) * 0.3 + (_random.nextDouble() - 0.5) * 0.5;
      current = Offset(
        math.cos(angle) * (8 + arcLength * (i + 1) / 4),
        math.sin(angle) * (8 + arcLength * (i + 1) / 4),
      );
      _arcPoints.add(current);
    }
  }

  void _triggerMuzzleFlash() {
    _isFiring = true;
    _fireFlashTimer = 0.15;

    // Reset and activate muzzle particles
    for (final particle in _muzzleParticles) {
      particle.reset(_random, _rotationAngle);
    }
  }

  double _normalizeAngle(double angle) {
    while (angle > math.pi) angle -= 2 * math.pi;
    while (angle < -math.pi) angle += 2 * math.pi;
    return angle;
  }

  bool _canTarget(Enemy enemy) {
    if (!enemy.isAlive) return false;
    if (enemy.isPhantom) {
      if (type.canDetectPhantom) {
        enemy.reveal();
      } else if (!enemy.isVisible) {
        return false;
      }
    }
    return true;
  }

  bool _isTargetValid(Enemy enemy) {
    if (!_canTarget(enemy)) return false;
    final center = centerPosition;
    final dx = enemy.position.x - center.x;
    final dy = enemy.position.y - center.y;
    return (dx * dx + dy * dy) <= range * range;
  }

  Enemy? _findTarget(List<Enemy> enemies, Vector2 center) {
    if (enemies.isEmpty) return null;

    Enemy? selected;
    switch (targetMode) {
      case TargetMode.first:
        var bestIndex = 1 << 30;
        for (final enemy in enemies) {
          if (!_canTarget(enemy)) continue;
          if (enemy.spawnIndex < bestIndex) {
            bestIndex = enemy.spawnIndex;
            selected = enemy;
          }
        }
        break;
      case TargetMode.last:
        var bestIndex = -1;
        for (final enemy in enemies) {
          if (!_canTarget(enemy)) continue;
          if (enemy.spawnIndex > bestIndex) {
            bestIndex = enemy.spawnIndex;
            selected = enemy;
          }
        }
        break;
      case TargetMode.strongest:
        var bestHealth = -1.0;
        for (final enemy in enemies) {
          if (!_canTarget(enemy)) continue;
          if (enemy.health > bestHealth) {
            bestHealth = enemy.health;
            selected = enemy;
          }
        }
        break;
      case TargetMode.weakest:
        var bestHealth = double.infinity;
        for (final enemy in enemies) {
          if (!_canTarget(enemy)) continue;
          if (enemy.health < bestHealth) {
            bestHealth = enemy.health;
            selected = enemy;
          }
        }
        break;
      case TargetMode.closest:
        var bestDistSq = double.infinity;
        final centerX = center.x;
        final centerY = center.y;
        for (final enemy in enemies) {
          if (!_canTarget(enemy)) continue;
          final dx = enemy.position.x - centerX;
          final dy = enemy.position.y - centerY;
          final distSq = (dx * dx) + (dy * dy);
          if (distSq < bestDistSq) {
            bestDistSq = distSq;
            selected = enemy;
          }
        }
        break;
    }
    return selected;
  }

  void _fire(Enemy target) {
    // Calculate lead position for moving target
    final targetPos = _calculateLeadPosition(target);

    // Try to get game time from the game instance
    try {
      final game = findGame();
      if (game != null) {
        _lastFireTime = (game as dynamic).gameTime ?? 0.0;
      }
    } catch (_) {
      // Fallback: use current time
      _lastFireTime = 0.0;
    }

    onFire?.call(this, target, targetPos);
  }

  Vector2 _calculateLeadPosition(Enemy target) {
    // Simple leading: predict where enemy will be
    final distance = (target.position - centerPosition).length;
    final flightTime = distance / projectileSpeed;
    final direction = target.position - centerPosition;
    if (direction.length > 0) {
      direction.normalize();
    }
    // Assume enemy continues in same direction
    return target.position + (direction * target.speed * flightTime * 0.5);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final reduceFx = Tower.lowFx;
    final center = Offset(size.x / 2, size.y / 2);

    // Type-specific idle effects
    if (!reduceFx) {
      _renderIdleEffects(canvas, center);
    }

    // Outer glow ring (pulsing) - color varies by type
    if (!reduceFx) {
      final outerGlowPaint = Paint()
        ..color = color.withOpacity(0.15 + _pulseAnimation * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, size.x * 0.7, outerGlowPaint);
    }

    // Orbiting energy particles
    if (!reduceFx) {
      _renderOrbitParticles(canvas, center);
    }

    // Base hexagon shape with gradient
    _renderMegaBase(canvas, center);

    // Type-specific core decoration
    _renderTypeDecoration(canvas, center);

    // Inner core (rotates toward target)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_rotationAngle);

    // Energy core with type-specific gradient
    _renderEnergyCore(canvas);

    // Targeting line/focus lens when has target
    if (_currentTarget != null) {
      _renderTargetingLens(canvas);
      _renderTargetingLine(canvas);
    }

    canvas.restore();

    // Charge indicator arcs
    if (_chargeLevel > 0) {
      _renderChargeIndicator(canvas, center);
    }

    // Muzzle flash and particles
    if (!reduceFx && _isFiring) {
      _renderMuzzleFlash(canvas, center);
    }

    // Range indicator when target acquired
    if (_currentTarget != null) {
      _renderRangeIndicator(canvas, center);
    }

    // Tower type indicator symbol
    _renderTypeSymbol(canvas, center);
  }

  void _renderIdleEffects(Canvas canvas, Offset center) {
    switch (type) {
      case TowerType.pulseArcher:
        // Pulsing rings emanating outward
        for (int i = 0; i < 3; i++) {
          final phase = (_animationPhase + i * 0.3) % 1.5;
          final ringRadius = size.x * 0.3 + phase * size.x * 0.3;
          final ringAlpha = (1 - phase / 1.5) * 0.2;

          canvas.drawCircle(
            center,
            ringRadius,
            Paint()
              ..color = color.withOpacity(ringAlpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
          );
        }
        break;

      case TowerType.circuitCannon:
        // Heavy rotating gear-like elements
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(_animationPhase * 0.3);

        // Outer gear teeth
        for (int i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          final innerR = size.x * 0.5;
          final outerR = size.x * 0.58;

          final x1 = math.cos(angle - 0.15) * innerR;
          final y1 = math.sin(angle - 0.15) * innerR;
          final x2 = math.cos(angle) * outerR;
          final y2 = math.sin(angle) * outerR;
          final x3 = math.cos(angle + 0.15) * innerR;
          final y3 = math.sin(angle + 0.15) * innerR;

          final path = Path()
            ..moveTo(x1, y1)
            ..lineTo(x2, y2)
            ..lineTo(x3, y3);

          canvas.drawPath(
            path,
            Paint()
              ..color = color.withOpacity(0.3 + _pulseAnimation * 0.2)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
          );
        }
        canvas.restore();
        break;

      case TowerType.phaseMage:
        // Electric arcs dancing around
        if (_arcPoints.length > 1) {
          final arcPaint = Paint()
            ..color = color.withOpacity(0.6)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

          final arcPath = Path();
          arcPath.moveTo(center.dx + _arcPoints[0].dx, center.dy + _arcPoints[0].dy);
          for (int i = 1; i < _arcPoints.length; i++) {
            arcPath.lineTo(center.dx + _arcPoints[i].dx, center.dy + _arcPoints[i].dy);
          }
          canvas.drawPath(arcPath, arcPaint);

          // Glow at arc tips
          canvas.drawCircle(
            Offset(center.dx + _arcPoints.last.dx, center.dy + _arcPoints.last.dy),
            3,
            Paint()
              ..color = color.withOpacity(0.8)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
          );
        }

        // Mystical runes rotating
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(-_animationPhase * 0.5);

        for (int i = 0; i < 6; i++) {
          final angle = i * math.pi / 3;
          final runeX = math.cos(angle) * size.x * 0.55;
          final runeY = math.sin(angle) * size.x * 0.55;
          final runeAlpha = 0.3 + math.sin(_animationPhase * 2 + i) * 0.2;

          // Small diamond rune shape
          final runePath = Path()
            ..moveTo(runeX, runeY - 3)
            ..lineTo(runeX + 2, runeY)
            ..lineTo(runeX, runeY + 3)
            ..lineTo(runeX - 2, runeY)
            ..close();

          canvas.drawPath(
            runePath,
            Paint()
              ..color = color.withOpacity(runeAlpha)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
          );
        }
        canvas.restore();
        break;

      case TowerType.glimmerField:
        // Rapid flickering particles in a field
        for (int i = 0; i < 8; i++) {
          final sparkAngle = _animationPhase * 4 + i * math.pi / 4;
          final sparkRadius = size.x * (0.35 + math.sin(_animationPhase * 6 + i) * 0.15);
          final sparkX = center.dx + math.cos(sparkAngle) * sparkRadius;
          final sparkY = center.dy + math.sin(sparkAngle) * sparkRadius;
          final sparkAlpha = 0.4 + math.sin(_animationPhase * 8 + i * 2) * 0.4;

          if (sparkAlpha > 0.2) {
            canvas.drawCircle(
              Offset(sparkX, sparkY),
              1.5,
              Paint()
                ..color = color.withOpacity(sparkAlpha)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
            );
          }
        }

        // Energy field waves
        final fieldRadius = size.x * 0.5 + math.sin(_animationPhase * 5) * 3;
        canvas.drawCircle(
          center,
          fieldRadius,
          Paint()
            ..color = color.withOpacity(0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        break;

      case TowerType.ionSniper:
        // Slow energy accumulation
        final chargeOffset = math.sin(_animationPhase * 2) * 4;
        canvas.drawCircle(
          center + Offset(0, chargeOffset),
          size.x * 0.4,
          Paint()
            ..color = color.withOpacity(0.1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        break;

      case TowerType.teslaTerminal:
        // Harmonic vibration
        final scale = 1.0 + math.sin(_animationPhase * 10) * 0.05;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.scale(scale);
        canvas.drawCircle(
          Offset.zero,
          size.x * 0.4,
          Paint()
            ..color = color.withOpacity(0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        canvas.restore();
        break;
      
      case TowerType.resonanceSiphon:
        // Expansion waves
        final wave = (_animationPhase * 0.5) % 1.0;
        canvas.drawCircle(
          center,
          size.x * 0.6 * wave,
          Paint()
            ..color = color.withOpacity(0.2 * (1 - wave))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        break;

      case TowerType.neuralDisruptor:
        // Static noise field
        if (_random.nextDouble() < 0.2) {
           canvas.drawRect(
             Rect.fromCenter(center: center, width: size.x * 0.8, height: 2),
             Paint()..color = color.withOpacity(0.3)
           );
        }
        break;
    }
  }

  void _renderMegaBase(Canvas canvas, Offset center) {
    for (int i = 0; i < 2; i++) {
        final radius = size.x * (0.45 - i * 0.1);
        final hexPath = NeonEffects.createHexagonPath(center, radius);
        
        final basePaint = Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFF151520),
              const Color(0xFF0A0A0F),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius));
        canvas.drawPath(hexPath, basePaint);

        final borderPaint = Paint()
          ..color = color.withOpacity((0.6 - i * 0.2) + _pulseAnimation * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 - i * 0.5;
        canvas.drawPath(hexPath, borderPaint);
    }
  }

  void _renderOrbitParticles(Canvas canvas, Offset center) {
    for (final particle in _orbitParticles) {
      final px = center.dx + math.cos(particle.angle) * particle.radius;
      final py = center.dy + math.sin(particle.angle) * particle.radius;
      final alpha = 0.5 + math.sin(_animationPhase * 3 + particle.phase) * 0.3;

      // Particle glow
      canvas.drawCircle(
        Offset(px, py),
        particle.size * 2,
        Paint()
          ..color = color.withOpacity(alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Particle core
      canvas.drawCircle(
        Offset(px, py),
        particle.size,
        Paint()..color = color.withOpacity(alpha),
      );
    }
  }

  void _renderTypeDecoration(Canvas canvas, Offset center) {
    switch (type) {
      case TowerType.pulseArcher:
        // Concentric arc segments
        for (int ring = 0; ring < 2; ring++) {
          final ringRadius = size.x * (0.25 + ring * 0.08);
          for (int i = 0; i < 4; i++) {
            final startAngle = i * math.pi / 2 + _animationPhase * 0.5;
            canvas.drawArc(
              Rect.fromCircle(center: center, radius: ringRadius),
              startAngle,
              math.pi / 4,
              false,
              Paint()
                ..color = color.withOpacity(0.3)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1,
            );
          }
        }
        break;

      case TowerType.circuitCannon:
        // Heavy plating lines
        final platePaint = Paint()
          ..color = color.withOpacity(0.4)
          ..strokeWidth = 2;

        for (int i = 0; i < 3; i++) {
          final offset = (i - 1) * 6.0;
          canvas.drawLine(
            Offset(center.dx - size.x * 0.25, center.dy + offset),
            Offset(center.dx + size.x * 0.25, center.dy + offset),
            platePaint,
          );
        }
        break;

      case TowerType.phaseMage:
        // Inner mystic circle
        canvas.drawCircle(
          center,
          size.x * 0.22,
          Paint()
            ..color = color.withOpacity(0.2 + _pulseAnimation * 0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
        break;

      case TowerType.glimmerField:
        // Radiating lines
        for (int i = 0; i < 8; i++) {
          final angle = i * math.pi / 4 + _animationPhase;
          final inner = size.x * 0.15;
          final outer = size.x * 0.3;

          canvas.drawLine(
            Offset(center.dx + math.cos(angle) * inner, center.dy + math.sin(angle) * inner),
            Offset(center.dx + math.cos(angle) * outer, center.dy + math.sin(angle) * outer),
            Paint()
              ..color = color.withOpacity(0.3)
              ..strokeWidth = 1
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
          );
        }
        break;

      case TowerType.ionSniper:
        // Long cooling fins
        final pinPaint = Paint()..color = color.withOpacity(0.5)..strokeWidth = 2;
        for (int i = 0; i < 4; i++) {
           final angle = i * math.pi / 2 + math.pi/4;
           canvas.drawLine(
             center + Offset(math.cos(angle) * 10, math.sin(angle) * 10),
             center + Offset(math.cos(angle) * 25, math.sin(angle) * 25),
             pinPaint
           );
        }
        break;

      case TowerType.teslaTerminal:
        // Coils
        for (int i = 0; i < 3; i++) {
            canvas.drawCircle(center, 10 + i * 5.0, Paint()..color = color.withOpacity(0.2)..style = PaintingStyle.stroke);
        }
        break;

      case TowerType.resonanceSiphon:
        // Siphon triangles
        for (int i = 0; i < 3; i++) {
            final angle = i * 2 * math.pi / 3 + _animationPhase;
            final p1 = center + Offset(math.cos(angle) * 15, math.sin(angle) * 15);
            canvas.drawCircle(p1, 3, Paint()..color = color);
        }
        break;
      
      case TowerType.neuralDisruptor:
        // Binary patterns
        if (_random.nextDouble() < 0.1) {
            _drawBinaryBit(canvas, center);
        }
        break;
    }
  }

  void _drawBinaryBit(Canvas canvas, Offset center) {
    final bit = _random.nextBool() ? "1" : "0";
    final painter = TextPainter(
      text: TextSpan(text: bit, style: TextStyle(color: color.withOpacity(0.5), fontSize: 10, fontFamily: 'monospace')),
      textDirection: TextDirection.ltr
    )..layout();
    painter.paint(canvas, center + Offset((_random.nextDouble()-0.5)*20, (_random.nextDouble()-0.5)*20));
  }

  void _renderEnergyCore(Canvas canvas) {
    final coreSize = size.x * 0.2 + (_chargeLevel * size.x * 0.05);

    // Outer glow
    if (!Tower.lowFx) {
      canvas.drawCircle(
        Offset.zero,
        coreSize * 1.5,
        Paint()
          ..color = color.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Core gradient
    final coreGradient = RadialGradient(
      colors: [
        Color.lerp(color, const Color(0xFFFFFFFF), 0.5)!,
        color,
        color.withOpacity(0.5),
        color.withOpacity(0),
      ],
      stops: const [0, 0.3, 0.6, 1],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: coreSize));

    canvas.drawCircle(Offset.zero, coreSize, Paint()..shader = coreGradient);

    // Bright center
    canvas.drawCircle(
      Offset.zero,
      coreSize * 0.3,
      Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.8 + _pulseAnimation * 0.2),
    );

    // Rotating Energy Arms
    final arms = switch(type) {
        TowerType.ionSniper => 2,
        TowerType.teslaTerminal => 4,
        _ => 3
    };
    for (int i = 0; i < arms; i++) {
        final angle = (i * 2 * math.pi / arms) + _animationPhase * 2;
        canvas.drawLine(
            Offset.zero,
            Offset(math.cos(angle) * coreSize * 1.2, math.sin(angle) * coreSize * 1.2),
            Paint()..color = color.withOpacity(0.6)..strokeWidth = 1.5
        );
    }
  }

  void _renderTargetingLens(Canvas canvas) {
     final lensRadius = size.x * 0.15 * (1 + _chargeLevel * 0.2);
     canvas.drawCircle(
       Offset(size.x * 0.3, 0),
       lensRadius,
       Paint()..color = color.withOpacity(0.2)..style = PaintingStyle.fill
     );
     canvas.drawCircle(
       Offset(size.x * 0.3, 0),
       lensRadius,
       Paint()..color = color.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 1
     );
  }

  void _renderTargetingLine(Canvas canvas) {
    // Main targeting line with glow
    final lineLength = size.x * 0.5;

    // Glow
    canvas.drawLine(
      Offset.zero,
      Offset(lineLength, 0),
      Paint()
        ..color = color.withOpacity(0.3)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Core line
    canvas.drawLine(
      Offset.zero,
      Offset(lineLength, 0),
      Paint()
        ..color = color.withOpacity(0.6)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Animated dashes along the line
    final dashProgress = (_animationPhase * 2) % 1;
    for (int i = 0; i < 3; i++) {
      final dashPos = ((dashProgress + i * 0.33) % 1) * lineLength;
      canvas.drawCircle(
        Offset(dashPos, 0),
        2,
        Paint()
          ..color = color.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // Targeting reticle
    final reticleX = size.x * 0.45;
    final reticlePulse = 3 + math.sin(_animationPhase * 4) * 1;

    canvas.drawCircle(
      Offset(reticleX, 0),
      reticlePulse,
      Paint()
        ..color = color.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Crosshairs
    canvas.drawLine(
      Offset(reticleX - reticlePulse - 2, 0),
      Offset(reticleX - reticlePulse + 1, 0),
      Paint()..color = color.withOpacity(0.6)..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(reticleX + reticlePulse - 1, 0),
      Offset(reticleX + reticlePulse + 2, 0),
      Paint()..color = color.withOpacity(0.6)..strokeWidth = 1,
    );
  }

  void _renderChargeIndicator(Canvas canvas, Offset center) {
    // Multiple charge arcs
    for (int i = 0; i < 2; i++) {
      final arcRadius = size.x * (0.32 + i * 0.06);
      final arcAlpha = _chargeLevel * (0.8 - i * 0.3);

      // Glow
      if (!Tower.lowFx) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: arcRadius),
          -math.pi / 2,
          math.pi * 2 * _chargeLevel,
          false,
          Paint()
            ..color = color.withOpacity(arcAlpha * 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      // Core
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        -math.pi / 2,
        math.pi * 2 * _chargeLevel,
        false,
        Paint()
          ..color = color.withOpacity(arcAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Charge complete indicator
    if (_chargeLevel >= 0.95) {
      if (!Tower.lowFx) {
        canvas.drawCircle(
          center,
          size.x * 0.42,
          Paint()
            ..color = color.withOpacity(0.3 + math.sin(_animationPhase * 10) * 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }
  }

  void _renderMuzzleFlash(Canvas canvas, Offset center) {
    final flashIntensity = _fireFlashTimer / 0.15;

    // Type-specific muzzle flash
    switch (type) {
      case TowerType.pulseArcher:
        // Quick cyan pulse
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(_rotationAngle);

        // Flash cone
        final conePath = Path()
          ..moveTo(size.x * 0.2, 0)
          ..lineTo(size.x * 0.6, -size.x * 0.15 * flashIntensity)
          ..lineTo(size.x * 0.6, size.x * 0.15 * flashIntensity)
          ..close();

        canvas.drawPath(
          conePath,
          Paint()
            ..color = color.withOpacity(flashIntensity * 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.restore();
        break;

      case TowerType.circuitCannon:
      case TowerType.ionSniper:
        canvas.drawCircle(
          center,
          size.x * (0.3 + flashIntensity * 0.5),
          Paint()
            ..color = color.withOpacity(flashIntensity * 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        break;

      case TowerType.phaseMage:
      case TowerType.glimmerField:
      case TowerType.teslaTerminal:
      case TowerType.resonanceSiphon:
      case TowerType.neuralDisruptor:
        canvas.drawCircle(
          center,
          size.x * flashIntensity,
          Paint()
            ..color = color.withOpacity(flashIntensity * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        break;
    }

    // Muzzle particles
    for (final particle in _muzzleParticles) {
      if (!particle.isActive) continue;

      final progress = particle.lifetime / particle.maxLifetime;
      final px = center.dx + math.cos(particle.angle) * particle.distance;
      final py = center.dy + math.sin(particle.angle) * particle.distance;
      final alpha = (1 - progress) * 0.8;

      canvas.drawCircle(
        Offset(px, py),
        particle.size * (1 - progress * 0.5),
        Paint()
          ..color = color.withOpacity(alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  void _renderRangeIndicator(Canvas canvas, Offset center) {
    final rangeAlpha = 0.05 + _pulseAnimation * 0.05;
    final rangePaint = Paint()
      ..color = color.withOpacity(rangeAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Animated dashed circle
    for (int i = 0; i < 36; i++) {
      if (i % 2 == 0) {
        final startAngle = i * math.pi / 18 + _animationPhase * 0.1;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: range),
          startAngle,
          math.pi / 18,
          false,
          rangePaint,
        );
      }
    }

    // Corner marks at cardinal directions
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + _animationPhase * 0.05;
      final markX = center.dx + math.cos(angle) * range;
      final markY = center.dy + math.sin(angle) * range;

      canvas.drawCircle(
        Offset(markX, markY),
        2,
        Paint()..color = color.withOpacity(rangeAlpha * 2),
      );
    }
  }

  void _renderTypeSymbol(Canvas canvas, Offset center) {
    final symbolAlpha = 0.4 + _pulseAnimation * 0.2;
    final symbolPaint = Paint()
      ..color = color.withOpacity(symbolAlpha)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    switch (type) {
      case TowerType.pulseArcher:
        // Arrow symbol
        final arrowPath = Path()
          ..moveTo(-4, 3)
          ..lineTo(0, -4)
          ..lineTo(4, 3);
        canvas.drawPath(arrowPath, symbolPaint);
        break;

      case TowerType.circuitCannon:
        // Heavy crosshair
        canvas.drawLine(const Offset(-5, 0), const Offset(5, 0), symbolPaint);
        canvas.drawLine(const Offset(0, -5), const Offset(0, 5), symbolPaint);
        canvas.drawCircle(Offset.zero, 3, symbolPaint);
        break;

      case TowerType.phaseMage:
        // Arcane eye
        canvas.drawCircle(Offset.zero, 4, symbolPaint);
        canvas.drawCircle(Offset.zero, 1.5, Paint()..color = color.withOpacity(symbolAlpha));
        break;

      case TowerType.glimmerField:
        // Spark/star
        for (int i = 0; i < 4; i++) {
          final angle = i * math.pi / 2;
          canvas.drawLine(
            Offset.zero,
            Offset(math.cos(angle) * 5, math.sin(angle) * 5),
            symbolPaint,
          );
        }
        break;
      case TowerType.ionSniper:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 8, height: 2), symbolPaint);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 2, height: 8), symbolPaint);
        break;
      case TowerType.teslaTerminal:
        canvas.drawCircle(Offset.zero, 4, symbolPaint);
        canvas.drawLine(const Offset(-4, -4), const Offset(4, 4), symbolPaint);
        break;
      case TowerType.resonanceSiphon:
        canvas.drawCircle(Offset.zero, 5, symbolPaint);
        canvas.drawCircle(Offset.zero, 2, symbolPaint);
        break;
      case TowerType.neuralDisruptor:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 6, height: 6), symbolPaint);
        break;
    }

    canvas.restore();
  }
}

// Helper class for orbiting tower particles
class _TowerParticle {
  _TowerParticle({
    required this.angle,
    required this.radius,
    required this.speed,
    required this.size,
    required this.phase,
  });

  double angle;
  double radius;
  double speed;
  double size;
  double phase;

  void update(double dt, TowerType type) {
    // Different orbit speeds per tower type
    final speedMultiplier = switch (type) {
      TowerType.pulseArcher => 1.0,
      TowerType.circuitCannon => 0.5,
      TowerType.phaseMage => 1.5,
      TowerType.glimmerField => 2.0,
      TowerType.ionSniper => 0.4,
      TowerType.teslaTerminal => 1.8,
      TowerType.resonanceSiphon => 1.2,
      TowerType.neuralDisruptor => 1.4,
    };
    angle += dt * speed * speedMultiplier;
  }
}

// Helper class for muzzle flash particles
class _MuzzleParticle {
  _MuzzleParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.lifetime,
    required this.maxLifetime,
  }) : distance = 0;

  double angle;
  double speed;
  double size;
  double lifetime;
  double maxLifetime;
  double distance;

  bool get isActive => lifetime > 0 && lifetime < maxLifetime;

  void update(double dt) {
    if (lifetime > 0) {
      lifetime += dt;
      distance += speed * dt;
    }
  }

  void reset(math.Random random, double baseAngle) {
    angle = baseAngle + (random.nextDouble() - 0.5) * 0.8;
    speed = 50 + random.nextDouble() * 100;
    lifetime = 0.001; // Start active
    distance = 10;
  }
}
