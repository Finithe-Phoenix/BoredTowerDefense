import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show RadialGradient;

import 'enemy.dart';
import 'tower.dart';
import '../../services/audio_service.dart';
import '../effects/impact_effect.dart';

class Projectile extends PositionComponent {
  Projectile({
    required Vector2 startPosition,
    required this.targetPosition,
    required this.speed,
    required this.damage,
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
    _initializeTrail();
    _initializeTypeEffects();
  }

  final Vector2 targetPosition;
  final double speed;
  final double damage;
  final Color color;
  final double slowAmount;
  final double slowDuration;
  final TowerType towerType;
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
    switch (towerType) {
      case TowerType.pulseArcher:
        _maxTrailLength = 10;
        _particleCount = 6;
        _wobbleAmount = 0;
        break;
      case TowerType.circuitCannon:
        _maxTrailLength = 6;
        _particleCount = 4;
        size = Vector2.all(10); // Larger projectile
        _wobbleAmount = 0;
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
    }
  }

  void _initializeTrail() {
    _trailPositions.clear();
    _trailAlphas.clear();
    for (int i = 0; i < _maxTrailLength; i++) {
      _trailPositions.add(position.clone());
      _trailAlphas.add(0);
    }

    // Initialize particles
    _particles.clear();
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

  /// Reset projectile for pool reuse
  void reset({
    required Vector2 startPosition,
    required Vector2 targetPosition,
    required double speed,
    required double damage,
    Color? color,
    Enemy? target,
  }) {
    position = startPosition.clone();
    this.targetPosition.setFrom(targetPosition);
    _active = true;
    this.target = target;
    _time = 0;
    _initializeTrail();
  }

  /// Deactivate projectile (for pooling)
  void deactivate() {
    _active = false;
    target = null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;

    _time += dt;
    _rotationAngle += dt * 10;
    _spiralPhase += dt * 8;
    _pulsePhase += dt * 15;

    // Update trail
    _updateTrail();

    // Update particles
    for (final particle in _particles) {
      particle.update(dt);
    }

    // Update electric segments for Phase Mage
    for (final segment in _electricSegments) {
      segment.update(dt, _random);
    }

    // Move toward target position
    final direction = targetPosition - position;
    final distance = direction.length;

    if (distance < 5) {
      // Hit - apply damage and effects if target still valid
      if (target != null && target!.isAlive) {
        target!.takeDamage(damage);

        // Apply slow effect if applicable
        if (appliesSlow) {
          target!.applySlow(slowAmount, slowDuration);
        }

        // Play hit sound
        AudioService.instance.playHit();

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
    parent?.add(ImpactEffect(
      position: position.clone(),
      color: color,
      towerType: towerType,
    ));
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

    // Draw type-specific effects
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
    }
  }

  void _renderPulseArcher(Canvas canvas) {
    // Sleek arrow-like projectile
    _drawTrail(canvas);

    final pulseScale = 1.0 + math.sin(_pulsePhase) * 0.1;

    // Motion blur trail effect
    canvas.save();
    final direction = targetPosition - position;
    if (direction.length > 0) {
      final angle = math.atan2(direction.y, direction.x);
      canvas.rotate(angle);
    }

    // Arrow shape glow
    final arrowPath = Path()
      ..moveTo(size.x * 0.8, 0)
      ..lineTo(-size.x * 0.4, -size.x * 0.3)
      ..lineTo(-size.x * 0.2, 0)
      ..lineTo(-size.x * 0.4, size.x * 0.3)
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.fill,
    );

    // Bright tip
    canvas.drawCircle(
      Offset(size.x * 0.6, 0),
      size.x * 0.2 * pulseScale,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.restore();

    // Energy particles
    _drawParticles(canvas);
  }

  void _renderCircuitCannon(Canvas canvas) {
    // Heavy, powerful projectile
    _drawTrail(canvas);

    final pulseScale = 1.0 + math.sin(_pulsePhase * 0.5) * 0.2;

    // Outer shockwave ring
    canvas.drawCircle(
      Offset.zero,
      size.x * 0.9 * pulseScale,
      Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Heavy core with gradient
    final coreGradient = RadialGradient(
      colors: [
        const Color(0xFFFFFFFF),
        color,
        color.withOpacity(0.5),
      ],
      stops: const [0.0, 0.4, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: size.x * 0.6));

    canvas.drawCircle(
      Offset.zero,
      size.x * 0.6 * pulseScale,
      Paint()..shader = coreGradient,
    );

    // Outer glow
    canvas.drawCircle(
      Offset.zero,
      size.x * 0.7 * pulseScale,
      Paint()
        ..color = color.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Rotating circuit lines
    canvas.save();
    canvas.rotate(_rotationAngle * 0.5);

    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final startX = math.cos(angle) * size.x * 0.3;
      final startY = math.sin(angle) * size.x * 0.3;
      final endX = math.cos(angle) * size.x * 0.7;
      final endY = math.sin(angle) * size.x * 0.7;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        Paint()
          ..color = color.withOpacity(0.6)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.restore();
  }

  void _renderPhaseMage(Canvas canvas) {
    // Mystical, ethereal projectile with electric arcs
    _drawTrail(canvas);

    final pulseScale = 1.0 + math.sin(_pulsePhase) * 0.15;

    // Electric arcs around projectile
    for (final segment in _electricSegments) {
      final startX = math.cos(segment.angle) * size.x * 0.3;
      final startY = math.sin(segment.angle) * size.x * 0.3;

      // Create zigzag path
      final arcPath = Path();
      arcPath.moveTo(startX, startY);

      final steps = 4;
      for (int i = 1; i <= steps; i++) {
        final progress = i / steps;
        final endAngle = segment.angle + segment.offset;
        final baseX = startX + (math.cos(endAngle) * segment.length - startX) * progress;
        final baseY = startY + (math.sin(endAngle) * segment.length - startY) * progress;

        final perpAngle = segment.angle + math.pi / 2;
        final jitter = math.sin(_time * 20 + i * 2) * 3;
        final jitterX = math.cos(perpAngle) * jitter;
        final jitterY = math.sin(perpAngle) * jitter;

        arcPath.lineTo(baseX + jitterX, baseY + jitterY);
      }

      canvas.drawPath(
        arcPath,
        Paint()
          ..color = color.withOpacity(0.7)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // Mystical core with inner glow
    canvas.drawCircle(
      Offset.zero,
      size.x * 0.5 * pulseScale,
      Paint()
        ..color = color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Spiraling rune ring
    canvas.save();
    canvas.rotate(_spiralPhase);

    for (int i = 0; i < 6; i++) {
      final runeAngle = i * math.pi / 3;
      final runeX = math.cos(runeAngle) * size.x * 0.4;
      final runeY = math.sin(runeAngle) * size.x * 0.4;
      final runeAlpha = 0.5 + math.sin(_pulsePhase + i) * 0.3;

      // Diamond rune
      final runePath = Path()
        ..moveTo(runeX, runeY - 2)
        ..lineTo(runeX + 1.5, runeY)
        ..lineTo(runeX, runeY + 2)
        ..lineTo(runeX - 1.5, runeY)
        ..close();

      canvas.drawPath(
        runePath,
        Paint()..color = color.withOpacity(runeAlpha),
      );
    }

    canvas.restore();

    // Core
    canvas.drawCircle(
      Offset.zero,
      size.x * 0.25 * pulseScale,
      Paint()..color = color,
    );

    // Inner bright
    canvas.drawCircle(
      Offset.zero,
      size.x * 0.12 * pulseScale,
      Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.9),
    );
  }

  void _renderGlimmerField(Canvas canvas) {
    // Rapid, sparkly projectile
    _drawTrail(canvas);

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
    canvas.drawCircle(
      Offset.zero,
      size.x * 0.4 * pulseScale,
      Paint()
        ..color = color.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Flickering core
    final flickerIntensity = 0.7 + _random.nextDouble() * 0.3;
    canvas.drawCircle(
      Offset.zero,
      size.x * 0.25 * pulseScale,
      Paint()..color = color.withOpacity(flickerIntensity),
    );

    // Bright center
    canvas.drawCircle(
      Offset.zero,
      size.x * 0.12 * pulseScale,
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // Extra particles
    _drawParticles(canvas);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color starColor) {
    final starPath = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + _spiralPhase;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
      // Inner point
      final innerAngle = angle + math.pi / 4;
      final innerX = center.dx + math.cos(innerAngle) * radius * 0.4;
      final innerY = center.dy + math.sin(innerAngle) * radius * 0.4;
      starPath.lineTo(innerX, innerY);
    }
    starPath.close();

    canvas.drawPath(
      starPath,
      Paint()
        ..color = starColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  void _drawTrail(Canvas canvas) {
    if (_trailPositions.length < 2) return;

    for (int i = 1; i < _trailPositions.length; i++) {
      final alpha = _trailAlphas[i];
      if (alpha < 0.05) continue;

      final trailOffset = _trailPositions[i] - position;
      final trailSize = size.x * 0.5 * (1 - i / _maxTrailLength);

      // Trail glow
      final glowPaint = Paint()
        ..color = color.withOpacity(alpha * 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + i * 0.5);
      canvas.drawCircle(
        Offset(trailOffset.x, trailOffset.y),
        trailSize * 1.5,
        glowPaint,
      );

      // Trail core
      final trailPaint = Paint()
        ..color = color.withOpacity(alpha * 0.6);
      canvas.drawCircle(
        Offset(trailOffset.x, trailOffset.y),
        trailSize,
        trailPaint,
      );
    }

    // Draw connecting line between trail points
    final linePaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (int i = 0; i < _trailPositions.length - 1; i++) {
      if (_trailAlphas[i] < 0.1 || _trailAlphas[i + 1] < 0.1) continue;

      final start = _trailPositions[i] - position;
      final end = _trailPositions[i + 1] - position;

      linePaint.color = color.withOpacity(_trailAlphas[i] * 0.3);
      canvas.drawLine(
        Offset(start.x, start.y),
        Offset(end.x, end.y),
        linePaint,
      );
    }
  }

  void _drawParticles(Canvas canvas) {
    for (final particle in _particles) {
      final px = math.cos(particle.angle + _time * particle.speed * 0.1) * particle.offset.x;
      final py = math.sin(particle.angle + _time * particle.speed * 0.1) * particle.offset.y;

      final particlePaint = Paint()
        ..color = color.withOpacity(particle.alpha * (0.5 + math.sin(_time * 5 + particle.angle) * 0.3))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size);

      canvas.drawCircle(Offset(px, py), particle.size, particlePaint);
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
