import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Epic explosion effect with particles, shockwave, and energy discharge
class ExplosionEffect extends PositionComponent {
  ExplosionEffect({
    required Vector2 position,
    required this.color,
    this.explosionSize = 40.0,
    this.duration = 0.6,
  }) : _particles = [],
       _energyArcs = [],
       _debris = [],
       _smokePuffs = [],
       _time = 0,
       _random = math.Random() {
    this.position = position;
    anchor = Anchor.center;
    _initializeParticles();
    _initializeEnergyArcs();
    _initializeDebris();
    _initializeSmoke();
  }

  final Color color;
  final double explosionSize;
  final double duration;

  final List<_ExplosionParticle> _particles;
  final List<_EnergyArc> _energyArcs;
  final List<_DebrisChunk> _debris;
  final List<_SmokePuff> _smokePuffs;
  double _time;
  final math.Random _random;

  // Shockwave properties
  double _shockwaveRadius = 0;
  double _shockwaveAlpha = 1.0;

  // Multiple shockwaves
  final List<double> _shockwaveOffsets = [0, 0.08, 0.16];
  final List<double> _shockwaveSizes = [1.0, 0.7, 0.5];

  // Core flash
  double _coreFlashIntensity = 1.0;

  // Screen shake intensity (can be read by parent)
  double get shakeIntensity => _coreFlashIntensity * 0.8;

  void _initializeParticles() {
    const particleCount = 24;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * math.pi * 2 + _random.nextDouble() * 0.3;
      final speed = 80 + _random.nextDouble() * 120;
      final particleSize = 2 + _random.nextDouble() * 4;
      final lifetime = 0.3 + _random.nextDouble() * 0.3;

      _particles.add(_ExplosionParticle(
        angle: angle,
        speed: speed,
        size: particleSize,
        lifetime: lifetime,
        decay: 0.8 + _random.nextDouble() * 0.2,
        trailLength: (3 + _random.nextInt(4)).toDouble(),
      ));
    }

    // Add some slower, larger particles for debris
    for (int i = 0; i < 8; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 30 + _random.nextDouble() * 50;

      _particles.add(_ExplosionParticle(
        angle: angle,
        speed: speed,
        size: 4 + _random.nextDouble() * 3,
        lifetime: 0.4 + _random.nextDouble() * 0.2,
        decay: 0.95,
        trailLength: 2,
        isDebris: true,
      ));
    }
  }

  void _initializeEnergyArcs() {
    const arcCount = 8;

    for (int i = 0; i < arcCount; i++) {
      final angle = (i / arcCount) * math.pi * 2 + _random.nextDouble() * 0.3;
      final length = explosionSize * 0.8 + _random.nextDouble() * explosionSize * 0.6;

      _energyArcs.add(_EnergyArc(
        angle: angle,
        length: length,
        width: 1.5 + _random.nextDouble() * 2.5,
        lifetime: 0.15 + _random.nextDouble() * 0.15,
        segments: 4 + _random.nextInt(3),
      ));
    }
  }

  void _initializeDebris() {
    const debrisCount = 12;

    for (int i = 0; i < debrisCount; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 40 + _random.nextDouble() * 80;

      _debris.add(_DebrisChunk(
        angle: angle,
        speed: speed,
        size: 3 + _random.nextDouble() * 4,
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 20,
        lifetime: 0.4 + _random.nextDouble() * 0.3,
        shape: _random.nextInt(3), // 0=square, 1=triangle, 2=line
        gravity: 50 + _random.nextDouble() * 30,
      ));
    }
  }

  void _initializeSmoke() {
    const smokeCount = 6;

    for (int i = 0; i < smokeCount; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final delay = _random.nextDouble() * 0.1;

      _smokePuffs.add(_SmokePuff(
        angle: angle,
        speed: 15 + _random.nextDouble() * 25,
        size: 8 + _random.nextDouble() * 12,
        lifetime: 0.5 + _random.nextDouble() * 0.3,
        delay: delay,
        expansionRate: 1.5 + _random.nextDouble(),
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _time += dt;
    final progress = _time / duration;

    if (progress >= 1.0) {
      removeFromParent();
      return;
    }

    // Update shockwave
    _shockwaveRadius = progress * explosionSize * 2;
    _shockwaveAlpha = (1 - progress) * 0.8;

    // Update core flash
    _coreFlashIntensity = math.max(0, 1 - progress * 3);

    // Update particles
    for (final particle in _particles) {
      particle.update(dt);
    }

    // Update energy arcs
    for (final arc in _energyArcs) {
      arc.update(dt);
    }

    // Update debris
    for (final chunk in _debris) {
      chunk.update(dt);
    }

    // Update smoke
    for (final puff in _smokePuffs) {
      puff.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = _time / duration;

    // Draw smoke (behind everything)
    _drawSmoke(canvas);

    // Draw multiple shockwave rings
    for (int i = 0; i < _shockwaveOffsets.length; i++) {
      final offset = _shockwaveOffsets[i];
      final sizeMult = _shockwaveSizes[i];
      if (progress > offset) {
        _drawShockwaveRing(canvas, progress - offset, sizeMult, 1 - i * 0.2);
      }
    }

    // Draw energy arcs
    _drawEnergyArcs(canvas);

    // Draw debris
    _drawDebris(canvas);

    // Draw particles
    _drawParticles(canvas);

    // Draw core flash
    _drawCoreFlash(canvas);

    // Draw impact sparks
    _drawImpactSparks(canvas, progress);

    // Draw heat distortion ring
    _drawHeatDistortion(canvas, progress);
  }

  void _drawShockwaveRing(Canvas canvas, double progress, double sizeMult, double alphaMult) {
    if (progress > 1.0) return;

    final radius = progress * explosionSize * 2 * sizeMult;
    final alpha = (1 - progress) * 0.8 * alphaMult;

    if (alpha <= 0) return;

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withOpacity(alpha * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(Offset.zero, radius, glowPaint);

    // Main ring
    final ringPaint = Paint()
      ..color = color.withOpacity(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset.zero, radius, ringPaint);

    // Inner bright ring
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(alpha * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(Offset.zero, radius * 0.95, innerPaint);
  }

  void _drawShockwave(Canvas canvas) {
    if (_shockwaveAlpha <= 0) return;

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withOpacity(_shockwaveAlpha * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(Offset.zero, _shockwaveRadius, glowPaint);

    // Main ring
    final ringPaint = Paint()
      ..color = color.withOpacity(_shockwaveAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset.zero, _shockwaveRadius, ringPaint);

    // Inner bright ring
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(_shockwaveAlpha * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(Offset.zero, _shockwaveRadius * 0.9, innerPaint);
  }

  void _drawSecondaryShockwave(Canvas canvas, double delayedProgress) {
    final radius = delayedProgress * explosionSize * 1.5 / 0.9;
    final alpha = (1 - delayedProgress / 0.9) * 0.4;

    if (alpha <= 0) return;

    final paint = Paint()
      ..color = color.withOpacity(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(Offset.zero, radius, paint);
  }

  void _drawEnergyArcs(Canvas canvas) {
    for (final arc in _energyArcs) {
      if (!arc.isAlive) continue;

      final alpha = arc.alphaValue;
      final arcPaint = Paint()
        ..color = color.withOpacity(alpha)
        ..strokeWidth = arc.width
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      // Draw lightning-style arc
      final path = Path();
      path.moveTo(0, 0);

      final endX = math.cos(arc.angle) * arc.length;
      final endY = math.sin(arc.angle) * arc.length;

      // Add zigzag segments
      const segments = 4;
      for (int i = 1; i <= segments; i++) {
        final t = i / segments;
        final baseX = endX * t;
        final baseY = endY * t;

        // Add random offset perpendicular to direction
        final perpX = -math.sin(arc.angle) * (i == segments ? 0 : (_random.nextDouble() - 0.5) * 10);
        final perpY = math.cos(arc.angle) * (i == segments ? 0 : (_random.nextDouble() - 0.5) * 10);

        path.lineTo(baseX + perpX, baseY + perpY);
      }

      canvas.drawPath(path, arcPaint);

      // Glow on arc
      arcPaint
        ..color = Colors.white.withOpacity(alpha * 0.5)
        ..strokeWidth = arc.width * 0.5;
      canvas.drawPath(path, arcPaint);
    }
  }

  void _drawParticles(Canvas canvas) {
    for (final particle in _particles) {
      if (!particle.isAlive) continue;

      final x = math.cos(particle.angle) * particle.distance;
      final y = math.sin(particle.angle) * particle.distance;
      final alpha = particle.alphaValue;

      // Draw particle trail
      if (particle.trailLength > 0) {
        final trailPaint = Paint()
          ..color = color.withOpacity(alpha * 0.5)
          ..strokeWidth = particle.currentSize * 0.7
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        final trailStartX = math.cos(particle.angle) * (particle.distance - particle.trailLength * 8);
        final trailStartY = math.sin(particle.angle) * (particle.distance - particle.trailLength * 8);

        canvas.drawLine(
          Offset(trailStartX, trailStartY),
          Offset(x, y),
          trailPaint,
        );
      }

      // Particle glow
      final glowPaint = Paint()
        ..color = color.withOpacity(alpha * 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.currentSize * 2);

      canvas.drawCircle(Offset(x, y), particle.currentSize * 1.5, glowPaint);

      // Particle core
      final corePaint = Paint()
        ..color = (particle.isDebris ? color : Colors.white).withOpacity(alpha);

      canvas.drawCircle(Offset(x, y), particle.currentSize, corePaint);
    }
  }

  void _drawCoreFlash(Canvas canvas) {
    if (_coreFlashIntensity <= 0) return;

    // Large soft glow
    final outerGlow = Paint()
      ..color = color.withOpacity(_coreFlashIntensity * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawCircle(Offset.zero, explosionSize * _coreFlashIntensity, outerGlow);

    // Medium glow
    final midGlow = Paint()
      ..color = color.withOpacity(_coreFlashIntensity * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawCircle(Offset.zero, explosionSize * 0.5 * _coreFlashIntensity, midGlow);

    // Bright core
    final coreGlow = Paint()
      ..color = Colors.white.withOpacity(_coreFlashIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(Offset.zero, explosionSize * 0.2 * _coreFlashIntensity, coreGlow);
  }

  void _drawImpactSparks(Canvas canvas, double progress) {
    if (progress > 0.4) return;

    const sparkCount = 12;
    final sparkAlpha = (1 - progress / 0.4);

    for (int i = 0; i < sparkCount; i++) {
      final angle = (i / sparkCount) * math.pi * 2 + _time * 5;
      final radius = explosionSize * 0.3 + progress * explosionSize * 0.5;

      final sparkPaint = Paint()
        ..color = Colors.white.withOpacity(sparkAlpha * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;

      // Draw spark with streak
      final streakLength = 4 + progress * 6;
      final streakEndX = x - math.cos(angle) * streakLength;
      final streakEndY = y - math.sin(angle) * streakLength;

      canvas.drawLine(
        Offset(streakEndX, streakEndY),
        Offset(x, y),
        Paint()
          ..color = color.withOpacity(sparkAlpha * 0.5)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawCircle(Offset(x, y), 2, sparkPaint);
    }
  }

  void _drawDebris(Canvas canvas) {
    for (final chunk in _debris) {
      if (!chunk.isAlive) continue;

      final x = math.cos(chunk.angle) * chunk.distance;
      final y = math.sin(chunk.angle) * chunk.distance + chunk.fallOffset;
      final alpha = chunk.alphaValue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(chunk.currentRotation);

      final paint = Paint()
        ..color = color.withOpacity(alpha * 0.8);

      final glowPaint = Paint()
        ..color = color.withOpacity(alpha * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      switch (chunk.shape) {
        case 0: // Square
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: chunk.size,
            height: chunk.size,
          );
          canvas.drawRect(rect, glowPaint);
          canvas.drawRect(rect, paint);
          break;

        case 1: // Triangle
          final path = Path()
            ..moveTo(0, -chunk.size / 2)
            ..lineTo(-chunk.size / 2, chunk.size / 2)
            ..lineTo(chunk.size / 2, chunk.size / 2)
            ..close();
          canvas.drawPath(path, glowPaint);
          canvas.drawPath(path, paint);
          break;

        case 2: // Line
          canvas.drawLine(
            Offset(-chunk.size / 2, 0),
            Offset(chunk.size / 2, 0),
            Paint()
              ..color = color.withOpacity(alpha * 0.6)
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round,
          );
          break;
      }

      canvas.restore();
    }
  }

  void _drawSmoke(Canvas canvas) {
    for (final puff in _smokePuffs) {
      if (!puff.isActive) continue;

      final x = math.cos(puff.angle) * puff.distance;
      final y = math.sin(puff.angle) * puff.distance;
      final alpha = puff.alphaValue;
      final currentSize = puff.currentSize;

      // Draw smoke puff with gradient
      final smokePaint = Paint()
        ..color = Colors.grey.withOpacity(alpha * 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentSize / 2);

      canvas.drawCircle(Offset(x, y), currentSize, smokePaint);

      // Inner darker smoke
      canvas.drawCircle(
        Offset(x, y),
        currentSize * 0.6,
        Paint()
          ..color = Colors.grey.shade800.withOpacity(alpha * 0.2)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentSize / 3),
      );
    }
  }

  void _drawHeatDistortion(Canvas canvas, double progress) {
    if (progress > 0.5) return;

    final distortionAlpha = (1 - progress / 0.5) * 0.15;
    final distortionRadius = explosionSize * (0.5 + progress);

    // Draw heat shimmer rings
    for (int i = 0; i < 3; i++) {
      final ringRadius = distortionRadius * (0.8 + i * 0.15);
      final ringAlpha = distortionAlpha * (1 - i * 0.3);

      canvas.drawCircle(
        Offset.zero,
        ringRadius,
        Paint()
          ..color = Colors.white.withOpacity(ringAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }
}

class _ExplosionParticle {
  _ExplosionParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.lifetime,
    required this.decay,
    required this.trailLength,
    this.isDebris = false,
  }) : _time = 0,
       distance = 0,
       currentSize = size;

  final double angle;
  final double speed;
  final double size;
  final double lifetime;
  final double decay;
  final double trailLength;
  final bool isDebris;

  double _time;
  double distance;
  double currentSize;

  bool get isAlive => _time < lifetime;

  double get alphaValue => isAlive ? (1 - _time / lifetime) : 0;

  void update(double dt) {
    _time += dt;
    distance += speed * dt * decay;
    currentSize = size * (1 - _time / lifetime * 0.5);
  }
}

class _EnergyArc {
  _EnergyArc({
    required this.angle,
    required this.length,
    required this.width,
    required this.lifetime,
    this.segments = 4,
  }) : _time = 0;

  final double angle;
  final double length;
  final double width;
  final double lifetime;
  final int segments;

  double _time;

  bool get isAlive => _time < lifetime;

  double get alphaValue => isAlive ? (1 - _time / lifetime) : 0;

  void update(double dt) {
    _time += dt;
  }
}

class _DebrisChunk {
  _DebrisChunk({
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.lifetime,
    required this.shape,
    required this.gravity,
  }) : _time = 0,
       distance = 0,
       currentRotation = rotation,
       fallOffset = 0;

  final double angle;
  final double speed;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final double lifetime;
  final int shape;
  final double gravity;

  double _time;
  double distance;
  double currentRotation;
  double fallOffset;

  bool get isAlive => _time < lifetime;

  double get alphaValue => isAlive ? (1 - _time / lifetime) : 0;

  void update(double dt) {
    _time += dt;
    final decay = 1 - _time / lifetime * 0.3;
    distance += speed * dt * decay;
    currentRotation += rotationSpeed * dt;
    fallOffset += gravity * _time * dt; // Accelerating fall
  }
}

class _SmokePuff {
  _SmokePuff({
    required this.angle,
    required this.speed,
    required this.size,
    required this.lifetime,
    required this.delay,
    required this.expansionRate,
  }) : _time = 0,
       distance = 0,
       currentSize = 0;

  final double angle;
  final double speed;
  final double size;
  final double lifetime;
  final double delay;
  final double expansionRate;

  double _time;
  double distance;
  double currentSize;

  bool get isActive => _time > delay && _time < lifetime + delay;

  double get alphaValue {
    if (_time <= delay) return 0;
    final activeTime = _time - delay;
    return (1 - activeTime / lifetime).clamp(0.0, 1.0);
  }

  void update(double dt) {
    _time += dt;
    if (_time > delay) {
      final activeTime = _time - delay;
      distance += speed * dt * (1 - activeTime / lifetime * 0.5);
      currentSize = size * (1 + activeTime * expansionRate);
    }
  }
}
