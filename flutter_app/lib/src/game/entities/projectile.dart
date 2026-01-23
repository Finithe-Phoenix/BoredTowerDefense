import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show RadialGradient;

import 'enemy.dart';
import 'tower.dart';
import '../../services/audio_service.dart';
import '../../services/sprite_cache_service.dart';
import '../effects/impact_effect.dart';
import '../managers/bullet_manager.dart';

class Projectile extends PositionComponent {
  static bool lowFx = false;
  static bool allowTrails = true;
  static bool allowGlow = true;

  /// Nivel de estrés del sistema (0-2)
  /// 0: Full quality (<200 bullets)
  /// 1: Reduced trails (200-400 bullets)
  /// 2: Minimal FX (400+ bullets)
  static int stressLevel = 0;

  /// Configura el nivel de estrés del sistema de proyectiles
  static void setStressLevel(int level) {
    stressLevel = level.clamp(0, 2);
    lowFx = stressLevel >= 2;
    // Nivel 1: reduce trails pero mantiene glow
    // Nivel 2: reduce todo (lowFx = true)
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════
  static final Paint _simplePaint = Paint();
  static final Paint _glowPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _trailGlowPaint = Paint();
  static final Paint _trailCorePaint = Paint();
  static final Paint _trailLinePaint = Paint()..strokeCap = StrokeCap.round;
  static final Paint _particlePaint = Paint();
  static final Paint _arcPaint = Paint()
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _circuitLinePaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  // Reusable paths to avoid per-frame allocations
  static final Path _reusableArrowPath = Path();
  static final Path _reusableArcPath = Path();
  static final Path _reusableRunePath = Path();
  static final Path _reusableStarPath = Path();

  Projectile({
    required Vector2 startPosition,
    required this.targetPosition,
    required this.speed,
    required this.damage,
    this.onHit,
    this.color = const Color(0xFF00FFFF),
    this.target,
    this.slowAmount = 0,
    this.slowDuration = 0,
    this.towerType = TowerType.pulseArcher,
  }) : _active = true,
       _random = math.Random() {
    position = startPosition.clone();
    size = Vector2.all(6);
    anchor = Anchor.center;
    _initializeTypeEffects();
    _initializeTrail();
  }

  final Vector2 targetPosition;
  double speed;
  double damage;
  void Function(Enemy target, Vector2 hitPosition, bool killed)? onHit;
  Color color;
  double slowAmount;
  double slowDuration;
  TowerType towerType;
  Enemy? target;

  bool _active;
  double _time = 0;
  double _rotationAngle = 0;
  final math.Random _random;

  // Trail system - varies by type
  int _maxTrailLength = 12;
  final List<Vector2> _trailPositions = [];
  final List<double> _trailAlphas = [];

  // Particle system
  int _particleCount = 8;
  final List<_ProjectileParticle> _particles = [];

  // Type-specific visual properties
  double _wobbleAmount = 0;
  double _spiralPhase = 0;
  List<_ElectricSegment> _electricSegments = [];
  double _pulsePhase = 0;

  /// Whether projectile is still flying
  bool get isActive => _active;

  /// Whether this projectile applies slow
  bool get appliesSlow => slowAmount > 0 && slowDuration > 0;

  void _initializeTypeEffects() {
    _maxTrailLength = 12;
    _particleCount = 8;
    _wobbleAmount = 0;
    _electricSegments = [];
    switch (towerType) {
      case TowerType.pulseArcher:
        _maxTrailLength = 10;
        _particleCount = 6;
        break;
      case TowerType.circuitCannon:
        _maxTrailLength = 6;
        _particleCount = 4;
        size = Vector2.all(10); // Larger projectile
        break;
      case TowerType.phaseMage:
        _maxTrailLength = 16;
        _particleCount = 10;
        _wobbleAmount = 0.3;
        // Initialize electric segments
        _electricSegments = List.generate(5, (i) => _ElectricSegment(
          angle: _random.nextDouble() * math.pi * 2,
          length: 8 + _random.nextDouble() * 6,
          offset: _random.nextDouble() * math.pi * 2,
        ));
        break;
      case TowerType.glimmerField:
        _maxTrailLength = 8;
        _particleCount = 12;
        size = Vector2.all(4); // Smaller but more particles
        _wobbleAmount = 0.1;
        break;
      case TowerType.ionSniper:
        _maxTrailLength = 20;
        _particleCount = 4;
        size = Vector2(12, 4);
        break;
      case TowerType.teslaTerminal:
      case TowerType.resonanceSiphon:
      case TowerType.neuralDisruptor:
        _maxTrailLength = 12;
        _particleCount = 8;
        break;
    }

    // Ajustar calidad según nivel de estrés
    if (stressLevel >= 1) {
      // Nivel 1: reduce trails y partículas moderadamente
      _maxTrailLength = math.max(3, (_maxTrailLength * 0.5).round());
      _particleCount = math.max(2, (_particleCount * 0.5).round());
    }
    if (lowFx || stressLevel >= 2) {
      // Nivel 2: reducción agresiva para alto estrés
      _maxTrailLength = math.max(2, (_maxTrailLength * 0.35).round());
      _particleCount = (_particleCount * 0.25).round();
      if (_particleCount < 0) {
        _particleCount = 0;
      }
      _wobbleAmount = 0;
      _electricSegments = [];
    }
  }

  void _initializeTrail() {
    _trailPositions.clear();
    _trailAlphas.clear();
    if (allowTrails && !lowFx && _maxTrailLength > 1) {
      for (int i = 0; i < _maxTrailLength; i++) {
        _trailPositions.add(position.clone());
        _trailAlphas.add(0);
      }
    }

    // Initialize particles
    _particles.clear();
    if (!lowFx && _particleCount > 0) {
      for (int i = 0; i < _particleCount; i++) {
        _particles.add(_ProjectileParticle(
          offset: Vector2(
            (_random.nextDouble() - 0.5) * 10,
            (_random.nextDouble() - 0.5) * 10,
          ),
          speed: 20 + _random.nextDouble() * 30,
          angle: _random.nextDouble() * math.pi * 2,
          size: 1 + _random.nextDouble() * 2,
          alpha: 0.3 + _random.nextDouble() * 0.5,
        ));
      }
    }
  }

  /// Reset projectile for pool reuse
  void reset({
    required Vector2 startPosition,
    required Vector2 targetPosition,
    required double speed,
    required double damage,
    Color? color,
    Enemy? target,
    void Function(Enemy target, Vector2 hitPosition, bool killed)? onHit,
    double slowAmount = 0,
    double slowDuration = 0,
    TowerType towerType = TowerType.pulseArcher,
  }) {
    position = startPosition.clone();
    this.targetPosition.setFrom(targetPosition);
    this.speed = speed;
    this.damage = damage;
    this.color = color ?? this.color;
    this.slowAmount = slowAmount;
    this.slowDuration = slowDuration;
    this.towerType = towerType;
    this.target = target;
    this.onHit = onHit;
    _active = true;
    _time = 0;
    _rotationAngle = 0;
    _spiralPhase = 0;
    _pulsePhase = 0;
    size = Vector2.all(6);
    _electricSegments = [];
    _initializeTypeEffects();
    _initializeTrail();
  }

  /// Deactivate projectile (for pooling)
  void deactivate() {
    _active = false;
    target = null;
    onHit = null;
    removeFromParent();
    BulletManager.returnToPool(this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;

    _time += dt;

    // Lifetime máximo (3 segundos) - evita balas zombies
    if (_time > 3.0) {
      deactivate();
      return;
    }

    // Bounds check - elimina balas fuera del mundo
    const maxBound = 1200.0;
    const minBound = -100.0;
    if (position.x < minBound || position.x > maxBound ||
        position.y < minBound || position.y > maxBound) {
      deactivate();
      return;
    }

    _rotationAngle += dt * 10;
    _spiralPhase += dt * 8;
    _pulsePhase += dt * 15;

    // Update trail
    if (allowTrails && !lowFx) {
      _updateTrail();
    }

    // Update particles
    if (!lowFx) {
      for (final particle in _particles) {
        particle.update(dt);
      }
    }

    // Update electric segments for Phase Mage
    if (!lowFx) {
      for (final segment in _electricSegments) {
        segment.update(dt, _random);
      }
    }

    // Move toward target position
    final direction = targetPosition - position;
    final distance = direction.length;

    if (distance < 5) {
      // Hit - apply damage and effects if target still valid
      if (target != null && target!.isAlive) {
        target!.takeDamage(damage);
        final killed = !target!.isAlive;

        // Apply slow effect if applicable
        if (appliesSlow && target!.isAlive) {
          target!.applySlow(slowAmount, slowDuration);
        }

        onHit?.call(target!, target!.position.clone(), killed);

        // Spawn impact effect
        _spawnImpactEffect();
      }
      deactivate();
      return;
    }

    // Move projectile with type-specific behavior
    var step = direction.normalized() * speed * dt;

    // Add wobble for Phase Mage
    if (_wobbleAmount > 0) {
      final perpendicular = Vector2(-direction.y, direction.x).normalized();
      step += perpendicular * math.sin(_spiralPhase) * _wobbleAmount * dt * 100;
    }

    if (step.length >= distance) {
      position = targetPosition.clone();
    } else {
      position += step;
    }
  }

  void _spawnImpactEffect() {
    final effect = ImpactEffect.spawn(
      position: position.clone(),
      color: color,
      towerType: towerType,
    );
    if (effect != null) {
      parent?.add(effect);
    }
  }

  void _updateTrail() {
    // Shift trail positions
    for (int i = _maxTrailLength - 1; i > 0; i--) {
      _trailPositions[i].setFrom(_trailPositions[i - 1]);
      _trailAlphas[i] = _trailAlphas[i - 1] * 0.85;
    }
    _trailPositions[0].setFrom(position);
    _trailAlphas[0] = 1.0;
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;
    super.render(canvas);

    // Use cached sprites for maximum performance in high-stress mode
    if (lowFx || stressLevel >= 1) {
      _renderCachedSprite(canvas);
      return;
    }

    // Draw type-specific effects (full quality)
    switch (towerType) {
      case TowerType.pulseArcher:
        _renderPulseArcher(canvas);
        break;
      case TowerType.circuitCannon:
        _renderCircuitCannon(canvas);
        break;
      case TowerType.phaseMage:
        _renderPhaseMage(canvas);
        break;
      case TowerType.glimmerField:
        _renderGlimmerField(canvas);
        break;
      case TowerType.ionSniper:
      case TowerType.teslaTerminal:
      case TowerType.resonanceSiphon:
      case TowerType.neuralDisruptor:
        _renderPulseArcher(canvas); // Fallback to basic for now
        break;
    }
  }

  /// High-performance rendering using pre-cached sprites
  void _renderCachedSprite(Canvas canvas) {
    final spriteCache = SpriteCacheService.instance;

    // Try to get cached glow sprite
    final glowSprite = spriteCache.getProjectileGlowSprite(color);
    if (glowSprite != null && stressLevel < 2) {
      // Draw glow from cache
      final glowScale = size.x / 16.0;
      canvas.save();
      canvas.scale(glowScale, glowScale);
      canvas.drawImage(
        glowSprite,
        Offset(-glowSprite.width / 2, -glowSprite.height / 2),
        _simplePaint,
      );
      canvas.restore();
    }

    // Try to get cached projectile sprite
    final sprite = spriteCache.getProjectileSprite(color);
    if (sprite != null) {
      // Draw with rotation toward target
      final direction = targetPosition - position;
      final angle = direction.length > 0 ? math.atan2(direction.y, direction.x) : 0.0;
      final spriteScale = size.x / 12.0;

      canvas.save();
      canvas.rotate(angle);
      canvas.scale(spriteScale, spriteScale);
      canvas.drawImage(
        sprite,
        Offset(-sprite.width / 2, -sprite.height / 2),
        _simplePaint,
      );
      canvas.restore();
    } else {
      // Fallback to simple circle if cache not ready
      _simplePaint.color = color.withOpacity(0.85);
      canvas.drawCircle(Offset.zero, size.x * 0.4, _simplePaint);
    }
  }

  void _renderPulseArcher(Canvas canvas) {
    // Sleek arrow-like projectile
    if (allowTrails) {
      _drawTrail(canvas);
    }

    final pulseScale = 1.0 + math.sin(_pulsePhase) * 0.1;

    // Motion blur trail effect
    canvas.save();
    final direction = targetPosition - position;
    if (direction.length > 0) {
      final angle = math.atan2(direction.y, direction.x);
      canvas.rotate(angle);
    }

    // Arrow shape glow
    _reusableArrowPath.reset();
    _reusableArrowPath.moveTo(size.x * 0.8, 0);
    _reusableArrowPath.lineTo(-size.x * 0.4, -size.x * 0.3);
    _reusableArrowPath.lineTo(-size.x * 0.2, 0);
    _reusableArrowPath.lineTo(-size.x * 0.4, size.x * 0.3);
    _reusableArrowPath.close();

    _glowPaint.color = color.withOpacity(0.3);
    canvas.drawPath(_reusableArrowPath, _glowPaint);

    _simplePaint.color = color.withOpacity(0.8);
    canvas.drawPath(_reusableArrowPath, _simplePaint);

    // Bright tip
    _glowPaint.color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(size.x * 0.6, 0), size.x * 0.2 * pulseScale, _glowPaint);

    canvas.restore();

    // Energy particles
    _drawParticles(canvas);
  }

  void _renderCircuitCannon(Canvas canvas) {
    // Heavy, powerful projectile
    if (allowTrails) {
      _drawTrail(canvas);
    }

    final pulseScale = 1.0 + math.sin(_pulsePhase * 0.5) * 0.2;

    // Outer shockwave ring
    _strokePaint
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset.zero, size.x * 0.9 * pulseScale, _strokePaint);

    // Heavy core with gradient
    final coreGradient = RadialGradient(
      colors: [
        const Color(0xFFFFFFFF),
        color,
        color.withOpacity(0.5),
      ],
      stops: const [0.0, 0.4, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: size.x * 0.6));

    _simplePaint.shader = coreGradient;
    canvas.drawCircle(Offset.zero, size.x * 0.6 * pulseScale, _simplePaint);
    _simplePaint.shader = null;

    // Outer glow
    _glowPaint
      ..color = color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, size.x * 0.7 * pulseScale, _glowPaint);

    // Rotating circuit lines
    canvas.save();
    canvas.rotate(_rotationAngle * 0.5);

    _circuitLinePaint.color = color.withOpacity(0.6);
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final startX = math.cos(angle) * size.x * 0.3;
      final startY = math.sin(angle) * size.x * 0.3;
      final endX = math.cos(angle) * size.x * 0.7;
      final endY = math.sin(angle) * size.x * 0.7;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), _circuitLinePaint);
    }

    canvas.restore();
  }

  void _renderPhaseMage(Canvas canvas) {
    // Mystical, ethereal projectile with electric arcs
    if (allowTrails) {
      _drawTrail(canvas);
    }

    final pulseScale = 1.0 + math.sin(_pulsePhase) * 0.15;

    // Electric arcs around projectile
    _arcPaint
      ..color = color.withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (final segment in _electricSegments) {
      final startX = math.cos(segment.angle) * size.x * 0.3;
      final startY = math.sin(segment.angle) * size.x * 0.3;

      // Create zigzag path using reusable path
      _reusableArcPath.reset();
      _reusableArcPath.moveTo(startX, startY);

      const steps = 4;
      for (int i = 1; i <= steps; i++) {
        final progress = i / steps;
        final endAngle = segment.angle + segment.offset;
        final baseX = startX + (math.cos(endAngle) * segment.length - startX) * progress;
        final baseY = startY + (math.sin(endAngle) * segment.length - startY) * progress;

        final perpendicularAngle = segment.angle + math.pi / 2;
        final jitter = math.sin(_time * 20 + i * 2) * 3;
        final jitterX = math.cos(perpendicularAngle) * jitter;
        final jitterY = math.sin(perpendicularAngle) * jitter;

        _reusableArcPath.lineTo(baseX + jitterX, baseY + jitterY);
      }

      canvas.drawPath(_reusableArcPath, _arcPaint);
    }

    // Mystical core with inner glow
    _glowPaint
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset.zero, size.x * 0.5 * pulseScale, _glowPaint);

    // Spiraling rune ring
    canvas.save();
    canvas.rotate(_spiralPhase);

    for (int i = 0; i < 6; i++) {
      final runeAngle = i * math.pi / 3;
      final runeX = math.cos(runeAngle) * size.x * 0.4;
      final runeY = math.sin(runeAngle) * size.x * 0.4;
      final runeAlpha = 0.5 + math.sin(_pulsePhase + i) * 0.3;

      // Diamond rune using reusable path
      _reusableRunePath.reset();
      _reusableRunePath.moveTo(runeX, runeY - 2);
      _reusableRunePath.lineTo(runeX + 1.5, runeY);
      _reusableRunePath.lineTo(runeX, runeY + 2);
      _reusableRunePath.lineTo(runeX - 1.5, runeY);
      _reusableRunePath.close();

      _simplePaint.color = color.withOpacity(runeAlpha);
      canvas.drawPath(_reusableRunePath, _simplePaint);
    }

    canvas.restore();

    // Core
    _simplePaint.color = color;
    canvas.drawCircle(Offset.zero, size.x * 0.25 * pulseScale, _simplePaint);

    // Inner bright
    _simplePaint.color = const Color(0xFFFFFFFF).withOpacity(0.9);
    canvas.drawCircle(Offset.zero, size.x * 0.12 * pulseScale, _simplePaint);
  }

  void _renderGlimmerField(Canvas canvas) {
    // Rapid, sparkly projectile
    if (allowTrails) {
      _drawTrail(canvas);
    }

    final pulseScale = 1.0 + math.sin(_pulsePhase * 2) * 0.2;

    // Multiple sparkle particles
    for (int i = 0; i < 8; i++) {
      final sparkAngle = _spiralPhase * 2 + i * math.pi / 4;
      final sparkDist = size.x * (0.3 + math.sin(_pulsePhase + i) * 0.2);
      final sparkX = math.cos(sparkAngle) * sparkDist;
      final sparkY = math.sin(sparkAngle) * sparkDist;
      final sparkAlpha = 0.4 + math.sin(_pulsePhase * 2 + i * 1.5) * 0.4;

      if (sparkAlpha > 0.2) {
        // Star shape for each sparkle
        _drawStar(canvas, Offset(sparkX, sparkY), 2, color.withOpacity(sparkAlpha));
      }
    }

    // Central burst
    _glowPaint.color = color.withOpacity(0.4);
    canvas.drawCircle(Offset.zero, size.x * 0.4 * pulseScale, _glowPaint);

    // Flickering core
    final flickerIntensity = 0.7 + _random.nextDouble() * 0.3;
    _simplePaint.color = color.withOpacity(flickerIntensity);
    canvas.drawCircle(Offset.zero, size.x * 0.25 * pulseScale, _simplePaint);

    // Bright center
    _simplePaint.color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset.zero, size.x * 0.12 * pulseScale, _simplePaint);

    // Extra particles
    _drawParticles(canvas);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color starColor) {
    _reusableStarPath.reset();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + _spiralPhase;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      if (i == 0) {
        _reusableStarPath.moveTo(x, y);
      } else {
        _reusableStarPath.lineTo(x, y);
      }
      // Inner point
      final innerAngle = angle + math.pi / 4;
      final innerX = center.dx + math.cos(innerAngle) * radius * 0.4;
      final innerY = center.dy + math.sin(innerAngle) * radius * 0.4;
      _reusableStarPath.lineTo(innerX, innerY);
    }
    _reusableStarPath.close();

    _glowPaint.color = starColor;
    canvas.drawPath(_reusableStarPath, _glowPaint);
  }

  void _drawTrail(Canvas canvas) {
    if (_trailPositions.length < 2) return;

    for (int i = 1; i < _trailPositions.length; i++) {
      final alpha = _trailAlphas[i];
      if (alpha < 0.05) continue;

      final trailOffset = _trailPositions[i] - position;
      final trailSize = size.x * 0.5 * (1 - i / _maxTrailLength);

      // Trail glow
      if (allowGlow) {
        _trailGlowPaint
          ..color = color.withOpacity(alpha * 0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + i * 0.5);
        canvas.drawCircle(Offset(trailOffset.x, trailOffset.y), trailSize * 1.5, _trailGlowPaint);
      }

      // Trail core
      _trailCorePaint.color = color.withOpacity(alpha * 0.6);
      canvas.drawCircle(Offset(trailOffset.x, trailOffset.y), trailSize, _trailCorePaint);
    }

    // Draw connecting line between trail points
    _trailLinePaint
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 2
      ..maskFilter = allowGlow ? const MaskFilter.blur(BlurStyle.normal, 2) : null;

    for (int i = 0; i < _trailPositions.length - 1; i++) {
      if (_trailAlphas[i] < 0.1 || _trailAlphas[i + 1] < 0.1) continue;

      final start = _trailPositions[i] - position;
      final end = _trailPositions[i + 1] - position;

      _trailLinePaint.color = color.withOpacity(_trailAlphas[i] * 0.3);
      canvas.drawLine(Offset(start.x, start.y), Offset(end.x, end.y), _trailLinePaint);
    }
  }

  void _drawParticles(Canvas canvas) {
    for (final particle in _particles) {
      final px = math.cos(particle.angle + _time * particle.speed * 0.1) * particle.offset.x;
      final py = math.sin(particle.angle + _time * particle.speed * 0.1) * particle.offset.y;

      _particlePaint.color = color.withOpacity(particle.alpha * (0.5 + math.sin(_time * 5 + particle.angle) * 0.3));
      if (allowGlow) {
        _particlePaint.maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size);
      } else {
        _particlePaint.maskFilter = null;
      }

      canvas.drawCircle(Offset(px, py), particle.size, _particlePaint);
    }
  }
}

class _ProjectileParticle {
  _ProjectileParticle({
    required this.offset,
    required this.speed,
    required this.angle,
    required this.size,
    required this.alpha,
  });

  Vector2 offset;
  double speed;
  double angle;
  double size;
  double alpha;

  void update(double dt) {
    angle += dt * speed * 0.05;
  }
}

class _ElectricSegment {
  _ElectricSegment({
    required this.angle,
    required this.length,
    required this.offset,
  });

  double angle;
  double length;
  double offset;
  double _timer = 0;

  void update(double dt, math.Random random) {
    _timer += dt;
    if (_timer > 0.1) {
      _timer = 0;
      // Randomly adjust angle
      angle += (random.nextDouble() - 0.5) * 0.5;
      offset = random.nextDouble() * math.pi * 2;
    }
  }
}
