import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Epic explosion effect with particles, shockwave, and energy discharge
class ExplosionEffect extends PositionComponent {
  ExplosionEffect._internal({
    required Vector2 position,
    required Color color,
    required double explosionSize,
    required double duration,
  }) : _random = math.Random() {
    _reset(
      position: position,
      color: color,
      explosionSize: explosionSize,
      duration: duration,
    );
  }

  static const int maxPool = 24;
  static const int maxActive = 18;
  static final List<ExplosionEffect> _pool = [];
  static int _activeCount = 0;
  static double fxScale = 1.0;
  static int get activeCount => _activeCount;
  static final Map<int, MaskFilter> _blurCache = {};

  static MaskFilter _blur(double sigma) {
    var key = sigma.round();
    if (key < 1) key = 1;
    if (key > 40) key = 40;
    return _blurCache.putIfAbsent(
      key,
      () => MaskFilter.blur(BlurStyle.normal, key.toDouble()),
    );
  }

  /// Clear the static pool to prevent memory accumulation between games
  static void clearPool() {
    _pool.clear();
    _activeCount = 0;
  }

  static ExplosionEffect? spawn({
    required Vector2 position,
    required Color color,
    double explosionSize = 40.0,
    double duration = 0.6,
  }) {
    if (_activeCount >= maxActive) return null;
    ExplosionEffect effect;
    if (_pool.isNotEmpty) {
      effect = _pool.removeLast();
      effect._reset(
        position: position,
        color: color,
        explosionSize: explosionSize,
        duration: duration,
      );
    } else {
      effect = ExplosionEffect._internal(
        position: position,
        color: color,
        explosionSize: explosionSize,
        duration: duration,
      );
    }
    effect._markActive();
    return effect;
  }

  Color color = Colors.white;
  double explosionSize = 40.0;
  double duration = 0.6;

  final List<_ExplosionParticle> _particles = [];
  final List<_EnergyArc> _energyArcs = [];
  final List<_DebrisChunk> _debris = [];
  final List<_SmokePuff> _smokePuffs = [];
  double _time = 0;
  final math.Random _random;
  bool _counted = false;
  bool _inPool = false;

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

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════
  final Paint _shockwaveGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _secondaryShockwavePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  final Paint _shockwaveRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  final Paint _shockwaveInnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Paint _arcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  final Paint _particleTrailPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  final Paint _particleGlowPaint = Paint();
  final Paint _particleCorePaint = Paint();
  final Paint _coreOuterGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
  final Paint _coreMidGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  final Paint _coreInnerGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _sparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  final Paint _sparkLinePaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  final Paint _debrisPaint = Paint();
  final Paint _debrisGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  final Paint _debrisLinePaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  final Paint _smokePaint = Paint();
  final Paint _smokeInnerPaint = Paint();
  final Paint _heatDistortionPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  final Path _reusablePath = Path();

  void _markActive() {
    if (_counted) return;
    _counted = true;
    _inPool = false;
    _activeCount++;
  }

  void _reset({
    required Vector2 position,
    required Color color,
    required double explosionSize,
    required double duration,
  }) {
    this.position = position.clone();
    anchor = Anchor.center;
    this.color = color;
    this.explosionSize = explosionSize;
    this.duration = duration;
    _time = 0;
    _shockwaveRadius = 0;
    _shockwaveAlpha = 1.0;
    _coreFlashIntensity = 1.0;
    _particles.clear();
    _energyArcs.clear();
    _debris.clear();
    _smokePuffs.clear();
    _initializeParticles();
    _initializeEnergyArcs();
    _initializeDebris();
    _initializeSmoke();
  }

  void _initializeParticles() {
    final particleCount = _scaledCount(24, allowZero: true);
    if (particleCount == 0) return;

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
    final debrisCount = _scaledCount(8, allowZero: true);
    for (int i = 0; i < debrisCount; i++) {
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
    final arcCount = _scaledCount(8, allowZero: true);
    if (arcCount == 0) return;

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
    final debrisCount = _scaledCount(12, allowZero: true);
    if (debrisCount == 0) return;

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
    final smokeCount = _scaledCount(6, allowZero: true);
    if (smokeCount == 0) return;

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

  int _scaledCount(int base, {bool allowZero = false}) {
    final scaled = (base * fxScale).round();
    if (scaled <= 0 && !allowZero) {
      return 1;
    }
    return scaled;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _time += dt;
    final progress = _time / duration;

    if (progress >= 1.0) {
      _recycle();
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

    // Outer glow - use cached paint
    _shockwaveGlowPaint.color = color.withOpacity(alpha * 0.3);
    canvas.drawCircle(Offset.zero, radius, _shockwaveGlowPaint);

    // Main ring - use cached paint
    _shockwaveRingPaint.color = color.withOpacity(alpha);
    canvas.drawCircle(Offset.zero, radius, _shockwaveRingPaint);

    // Inner bright ring - use cached paint
    _shockwaveInnerPaint.color = Colors.white.withOpacity(alpha * 0.8);
    canvas.drawCircle(Offset.zero, radius * 0.95, _shockwaveInnerPaint);
  }

  void _drawShockwave(Canvas canvas) {
    if (_shockwaveAlpha <= 0) return;

    // Outer glow - use cached paint
    _shockwaveGlowPaint.color = color.withOpacity(_shockwaveAlpha * 0.3);
    canvas.drawCircle(Offset.zero, _shockwaveRadius, _shockwaveGlowPaint);

    // Main ring - use cached paint
    _shockwaveRingPaint.color = color.withOpacity(_shockwaveAlpha);
    canvas.drawCircle(Offset.zero, _shockwaveRadius, _shockwaveRingPaint);

    // Inner bright ring - use cached paint
    _shockwaveInnerPaint.color = Colors.white.withOpacity(_shockwaveAlpha * 0.8);
    canvas.drawCircle(Offset.zero, _shockwaveRadius * 0.9, _shockwaveInnerPaint);
  }

  void _drawSecondaryShockwave(Canvas canvas, double delayedProgress) {
    final radius = delayedProgress * explosionSize * 1.5 / 0.9;
    final alpha = (1 - delayedProgress / 0.9) * 0.4;

    if (alpha <= 0) return;

    _secondaryShockwavePaint.color = color.withOpacity(alpha);
    canvas.drawCircle(Offset.zero, radius, _secondaryShockwavePaint);
  }

  void _drawEnergyArcs(Canvas canvas) {
    for (final arc in _energyArcs) {
      if (!arc.isAlive) continue;

      final alpha = arc.alphaValue;
      _arcPaint
        ..color = color.withOpacity(alpha)
        ..strokeWidth = arc.width
        ..style = PaintingStyle.stroke;

      // Draw lightning-style arc
      _reusablePath.reset();
      _reusablePath.moveTo(0, 0);

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

        _reusablePath.lineTo(baseX + perpX, baseY + perpY);
      }

      canvas.drawPath(_reusablePath, _arcPaint);

      // Glow on arc
      _arcPaint
        ..color = Colors.white.withOpacity(alpha * 0.5)
        ..strokeWidth = arc.width * 0.5;
      canvas.drawPath(_reusablePath, _arcPaint);
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
        _particleTrailPaint
          ..color = color.withOpacity(alpha * 0.5)
          ..strokeWidth = particle.currentSize * 0.7;

        final trailStartX = math.cos(particle.angle) * (particle.distance - particle.trailLength * 8);
        final trailStartY = math.sin(particle.angle) * (particle.distance - particle.trailLength * 8);

        canvas.drawLine(
          Offset(trailStartX, trailStartY),
          Offset(x, y),
          _particleTrailPaint,
        );
      }

      // Particle glow
      _particleGlowPaint
        ..color = color.withOpacity(alpha * 0.4)
        ..maskFilter = _blur(particle.currentSize * 2);
      canvas.drawCircle(Offset(x, y), particle.currentSize * 1.5, _particleGlowPaint);

      // Particle core
      _particleCorePaint
        ..color = (particle.isDebris ? color : Colors.white).withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), particle.currentSize, _particleCorePaint);
    }
  }

  void _drawCoreFlash(Canvas canvas) {
    if (_coreFlashIntensity <= 0) return;

    // Large soft glow
    _coreOuterGlowPaint.color = color.withOpacity(_coreFlashIntensity * 0.3);
    canvas.drawCircle(Offset.zero, explosionSize * _coreFlashIntensity, _coreOuterGlowPaint);

    // Medium glow
    _coreMidGlowPaint.color = color.withOpacity(_coreFlashIntensity * 0.6);
    canvas.drawCircle(Offset.zero, explosionSize * 0.5 * _coreFlashIntensity, _coreMidGlowPaint);

    // Bright core
    _coreInnerGlowPaint.color = Colors.white.withOpacity(_coreFlashIntensity);
    canvas.drawCircle(Offset.zero, explosionSize * 0.2 * _coreFlashIntensity, _coreInnerGlowPaint);
  }

  void _drawImpactSparks(Canvas canvas, double progress) {
    if (progress > 0.4) return;

    const sparkCount = 12;
    final sparkAlpha = (1 - progress / 0.4);

    for (int i = 0; i < sparkCount; i++) {
      final angle = (i / sparkCount) * math.pi * 2 + _time * 5;
      final radius = explosionSize * 0.3 + progress * explosionSize * 0.5;

      _sparkPaint.color = Colors.white.withOpacity(sparkAlpha * 0.8);

      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;

      // Draw spark with streak
      final streakLength = 4 + progress * 6;
      final streakEndX = x - math.cos(angle) * streakLength;
      final streakEndY = y - math.sin(angle) * streakLength;

      canvas.drawLine(
        Offset(streakEndX, streakEndY),
        Offset(x, y),
        _sparkLinePaint
          ..color = color.withOpacity(sparkAlpha * 0.5),
      );

      canvas.drawCircle(Offset(x, y), 2, _sparkPaint);
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

      _debrisPaint.color = color.withOpacity(alpha * 0.8);
      _debrisGlowPaint.color = color.withOpacity(alpha * 0.3);

      switch (chunk.shape) {
        case 0: // Square
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: chunk.size,
            height: chunk.size,
          );
          canvas.drawRect(rect, _debrisGlowPaint);
          canvas.drawRect(rect, _debrisPaint);
          break;

        case 1: // Triangle
          _reusablePath.reset();
          _reusablePath.moveTo(0, -chunk.size / 2);
          _reusablePath.lineTo(-chunk.size / 2, chunk.size / 2);
          _reusablePath.lineTo(chunk.size / 2, chunk.size / 2);
          _reusablePath.close();
          canvas.drawPath(_reusablePath, _debrisGlowPaint);
          canvas.drawPath(_reusablePath, _debrisPaint);
          break;

        case 2: // Line
          canvas.drawLine(
            Offset(-chunk.size / 2, 0),
            Offset(chunk.size / 2, 0),
            _debrisLinePaint
              ..color = color.withOpacity(alpha * 0.6),
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
      _smokePaint
        ..color = Colors.grey.withOpacity(alpha * 0.3)
        ..maskFilter = _blur(currentSize / 2);
      canvas.drawCircle(Offset(x, y), currentSize, _smokePaint);

      // Inner darker smoke
      canvas.drawCircle(
        Offset(x, y),
        currentSize * 0.6,
        _smokeInnerPaint
          ..color = Colors.grey.shade800.withOpacity(alpha * 0.2)
          ..maskFilter = _blur(currentSize / 3),
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
        _heatDistortionPaint..color = Colors.white.withOpacity(ringAlpha),
      );
    }
  }

  void _recycle() {
    if (_counted) {
      if (_activeCount > 0) {
        _activeCount -= 1;
      }
      _counted = false;
    }
    if (parent != null) {
      removeFromParent();
    }
    if (_inPool) return;
    if (_pool.length < maxPool) {
      _inPool = true;
      _pool.add(this);
    }
  }

  @override
  void onRemove() {
    if (_counted) {
      if (_activeCount > 0) {
        _activeCount -= 1;
      }
      _counted = false;
    }
    super.onRemove();
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
