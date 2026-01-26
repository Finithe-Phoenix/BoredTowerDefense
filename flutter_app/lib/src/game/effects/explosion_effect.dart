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
  // STATIC CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _shockwaveGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _secondaryShockwavePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _shockwaveRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _shockwaveInnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _arcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _particleTrailPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _particleGlowPaint = Paint();
  static final Paint _particleCorePaint = Paint();
  static final Paint _coreOuterGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
  static final Paint _coreMidGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _coreInnerGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _sparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _sparkLinePaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _debrisPaint = Paint();
  static final Paint _debrisGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _debrisLinePaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _debrisTrailPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _debrisSparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _debrisHexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _debrisShardPaint = Paint();
  static final Path _debrisPath = Path();
  static final Paint _smokePaint = Paint();
  static final Paint _smokeInnerPaint = Paint();
  static final Paint _heatDistortionPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Path _reusablePath = Path();

  // ═══════════════════════════════════════════════════════════════════════════
  // CHROMATIC ABERRATION EFFECT PAINTS
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _chromaRedPaint = Paint()
    ..blendMode = BlendMode.plus
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _chromaGreenPaint = Paint()
    ..blendMode = BlendMode.plus
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _chromaBluePaint = Paint()
    ..blendMode = BlendMode.plus
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _chromaOuterPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _chromaRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _chromaGlitchPaint = Paint();
  static final Paint _chromaFlashPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  static final Paint _chromaSparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _chromaFragmentPaint = Paint();
  static final Paint _chromaVortexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Path _chromaPath = Path();

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
    this.position.setFrom(position);
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
    final debrisCount = _scaledCount(16, allowZero: true);
    if (debrisCount == 0) return;

    for (int i = 0; i < debrisCount; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 40 + _random.nextDouble() * 100;
      final shapeType = _random.nextInt(6); // 0=square, 1=triangle, 2=line, 3=hexShard, 4=crystal, 5=spark

      _debris.add(_DebrisChunk(
        angle: angle,
        speed: speed,
        size: shapeType >= 3 ? 2 + _random.nextDouble() * 3 : 3 + _random.nextDouble() * 4,
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * (shapeType >= 3 ? 30 : 20),
        lifetime: 0.5 + _random.nextDouble() * 0.4,
        shape: shapeType,
        gravity: shapeType == 5 ? 20 + _random.nextDouble() * 20 : 50 + _random.nextDouble() * 40,
        hasTrail: shapeType >= 3 && _random.nextDouble() > 0.5,
        glowIntensity: 0.3 + _random.nextDouble() * 0.5,
        bounceEnabled: shapeType < 3 && _random.nextDouble() > 0.6,
        bounceDamping: 0.5 + _random.nextDouble() * 0.3,
      ));
    }

    // Add some large dramatic shards
    final shardCount = _scaledCount(4, allowZero: true);
    for (int i = 0; i < shardCount; i++) {
      final angle = (i / shardCount) * math.pi * 2 + _random.nextDouble() * 0.3;
      _debris.add(_DebrisChunk(
        angle: angle,
        speed: 60 + _random.nextDouble() * 60,
        size: 5 + _random.nextDouble() * 4,
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 15,
        lifetime: 0.6 + _random.nextDouble() * 0.3,
        shape: 4, // Crystal shard
        gravity: 40 + _random.nextDouble() * 25,
        hasTrail: true,
        glowIntensity: 0.6 + _random.nextDouble() * 0.3,
        bounceEnabled: false,
        bounceDamping: 0.6,
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

    // ═══════════════════════════════════════════════════════════════════════
    // CHROMATIC ABERRATION LAYER (behind shockwaves)
    // ═══════════════════════════════════════════════════════════════════════
    _drawChromaticAberration(canvas, progress);

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

    // ═══════════════════════════════════════════════════════════════════════
    // CHROMATIC GLITCH OVERLAY (on top of everything)
    // ═══════════════════════════════════════════════════════════════════════
    _drawChromaticGlitchOverlay(canvas, progress);
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

      // ═══════════════════════════════════════════════════════════════════════
      // Draw trail behind debris (for shapes with trails)
      // ═══════════════════════════════════════════════════════════════════════
      if (chunk.hasTrail && chunk.prevX != 0 && chunk.prevY != 0) {
        _debrisTrailPaint
          ..color = color.withOpacity(alpha * 0.4)
          ..strokeWidth = chunk.size * 0.6;
        canvas.drawLine(
          Offset(chunk.prevX, chunk.prevY),
          Offset(x, y),
          _debrisTrailPaint,
        );
      }

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(chunk.currentRotation);

      _debrisPaint.color = color.withOpacity(alpha * 0.8);
      _debrisGlowPaint.color = color.withOpacity(alpha * chunk.glowIntensity);

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
          _debrisPath.reset();
          _debrisPath.moveTo(0, -chunk.size / 2);
          _debrisPath.lineTo(-chunk.size / 2, chunk.size / 2);
          _debrisPath.lineTo(chunk.size / 2, chunk.size / 2);
          _debrisPath.close();
          canvas.drawPath(_debrisPath, _debrisGlowPaint);
          canvas.drawPath(_debrisPath, _debrisPaint);
          break;

        case 2: // Line
          canvas.drawLine(
            Offset(-chunk.size / 2, 0),
            Offset(chunk.size / 2, 0),
            _debrisLinePaint
              ..color = color.withOpacity(alpha * 0.6),
          );
          break;

        case 3: // Hexagonal shard
          _debrisPath.reset();
          for (int i = 0; i < 6; i++) {
            final angle = i * math.pi / 3;
            final px = math.cos(angle) * chunk.size * 0.5;
            final py = math.sin(angle) * chunk.size * 0.5;
            if (i == 0) {
              _debrisPath.moveTo(px, py);
            } else {
              _debrisPath.lineTo(px, py);
            }
          }
          _debrisPath.close();
          // Glow
          _debrisHexPaint.color = color.withOpacity(alpha * chunk.glowIntensity);
          canvas.drawPath(_debrisPath, _debrisHexPaint);
          // Fill
          _debrisShardPaint.color = color.withOpacity(alpha * 0.7);
          canvas.drawPath(_debrisPath, _debrisShardPaint);
          // Inner highlight
          _debrisShardPaint.color = Colors.white.withOpacity(alpha * 0.4);
          canvas.drawCircle(Offset.zero, chunk.size * 0.15, _debrisShardPaint);
          break;

        case 4: // Crystal shard (elongated diamond)
          _debrisPath.reset();
          _debrisPath.moveTo(0, -chunk.size * 0.8); // Top
          _debrisPath.lineTo(chunk.size * 0.3, 0); // Right
          _debrisPath.lineTo(0, chunk.size * 0.4); // Bottom
          _debrisPath.lineTo(-chunk.size * 0.3, 0); // Left
          _debrisPath.close();
          // Outer glow
          canvas.drawPath(_debrisPath, _debrisGlowPaint);
          // Fill with gradient-like effect
          _debrisShardPaint.color = color.withOpacity(alpha * 0.6);
          canvas.drawPath(_debrisPath, _debrisShardPaint);
          // Inner crystal facet
          _debrisPath.reset();
          _debrisPath.moveTo(0, -chunk.size * 0.5);
          _debrisPath.lineTo(chunk.size * 0.15, 0);
          _debrisPath.lineTo(0, chunk.size * 0.2);
          _debrisPath.lineTo(-chunk.size * 0.15, 0);
          _debrisPath.close();
          _debrisShardPaint.color = Colors.white.withOpacity(alpha * 0.5);
          canvas.drawPath(_debrisPath, _debrisShardPaint);
          break;

        case 5: // Spark (glowing point with streak)
          // Streak behind
          _debrisSparkPaint.color = color.withOpacity(alpha * 0.3);
          canvas.drawLine(
            Offset(0, chunk.size * 1.5),
            Offset.zero,
            _debrisLinePaint..color = color.withOpacity(alpha * 0.5),
          );
          // Core glow
          _debrisSparkPaint.color = Colors.white.withOpacity(alpha * 0.8);
          canvas.drawCircle(Offset.zero, chunk.size * 0.3, _debrisSparkPaint);
          // Outer glow
          _debrisSparkPaint.color = color.withOpacity(alpha * chunk.glowIntensity);
          canvas.drawCircle(Offset.zero, chunk.size * 0.6, _debrisSparkPaint);
          break;
      }

      canvas.restore();

      // ═══════════════════════════════════════════════════════════════════════
      // Draw secondary spark for large debris
      // ═══════════════════════════════════════════════════════════════════════
      if (chunk.shape == 4 && chunk.hasTrail && alpha > 0.3) {
        // Small spark particles following crystal shards
        final sparkOffset = math.sin(_time * 15 + chunk.angle * 3) * 3;
        _debrisSparkPaint.color = Colors.white.withOpacity(alpha * 0.5);
        canvas.drawCircle(
          Offset(x + sparkOffset, y - sparkOffset),
          1.5,
          _debrisSparkPaint,
        );
      }
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

  // ═══════════════════════════════════════════════════════════════════════════
  // CHROMATIC ABERRATION EFFECT METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void _drawChromaticAberration(Canvas canvas, double progress) {
    if (progress > 0.7) return;

    final chromaIntensity = (1 - progress / 0.7);
    final chromaOffset = 6 + progress * 12; // RGB split distance increases with progress

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: RGB SPLIT CORE FLASH
    // ═══════════════════════════════════════════════════════════════════════
    final coreRadius = explosionSize * (0.4 + progress * 0.3) * chromaIntensity;

    // Red channel - offset left and up
    _chromaRedPaint.color = const Color(0xFFFF0000).withOpacity(chromaIntensity * 0.4);
    canvas.drawCircle(
      Offset(-chromaOffset, -chromaOffset * 0.5),
      coreRadius,
      _chromaRedPaint,
    );

    // Green channel - center
    _chromaGreenPaint.color = const Color(0xFF00FF00).withOpacity(chromaIntensity * 0.35);
    canvas.drawCircle(
      Offset.zero,
      coreRadius,
      _chromaGreenPaint,
    );

    // Blue channel - offset right and down
    _chromaBluePaint.color = const Color(0xFF0000FF).withOpacity(chromaIntensity * 0.4);
    canvas.drawCircle(
      Offset(chromaOffset, chromaOffset * 0.5),
      coreRadius,
      _chromaBluePaint,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: CHROMATIC ABERRATION RINGS
    // ═══════════════════════════════════════════════════════════════════════
    for (int ring = 0; ring < 3; ring++) {
      final ringProgress = (progress * 3 + ring * 0.15) % 1.0;
      final ringRadius = explosionSize * (0.3 + ringProgress * 1.2);
      final ringAlpha = chromaIntensity * (1 - ringProgress) * 0.5;

      if (ringAlpha > 0.05) {
        // Red ring
        _chromaOuterPaint.color = const Color(0xFFFF3333).withOpacity(ringAlpha);
        canvas.drawCircle(
          Offset(-chromaOffset * 0.5 * (1 - ringProgress), 0),
          ringRadius,
          _chromaOuterPaint,
        );

        // Cyan ring (complement)
        _chromaOuterPaint.color = const Color(0xFF33FFFF).withOpacity(ringAlpha * 0.8);
        canvas.drawCircle(
          Offset(chromaOffset * 0.5 * (1 - ringProgress), 0),
          ringRadius * 0.95,
          _chromaOuterPaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: CHROMATIC SPLIT SHOCKWAVE
    // ═══════════════════════════════════════════════════════════════════════
    final shockRadius = explosionSize * progress * 2.5;
    final shockAlpha = chromaIntensity * 0.4;

    // Draw three offset shockwaves for RGB effect
    _chromaRingPaint.strokeWidth = 3;
    _chromaRingPaint.color = const Color(0xFFFF0000).withOpacity(shockAlpha);
    canvas.drawCircle(Offset(-chromaOffset * 0.3, 0), shockRadius, _chromaRingPaint);

    _chromaRingPaint.color = const Color(0xFF00FF00).withOpacity(shockAlpha * 0.9);
    canvas.drawCircle(Offset.zero, shockRadius, _chromaRingPaint);

    _chromaRingPaint.color = const Color(0xFF0000FF).withOpacity(shockAlpha);
    canvas.drawCircle(Offset(chromaOffset * 0.3, 0), shockRadius, _chromaRingPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: CHROMATIC ENERGY RAYS
    // ═══════════════════════════════════════════════════════════════════════
    if (chromaIntensity > 0.3) {
      final rayCount = 8;
      for (int i = 0; i < rayCount; i++) {
        final angle = (i / rayCount) * math.pi * 2 + _time * 2;
        final rayLength = explosionSize * (0.5 + progress * 0.8);

        // Each ray has RGB split
        for (int c = 0; c < 3; c++) {
          final colorOffset = (c - 1) * 2.0;
          final rayColor = c == 0
              ? const Color(0xFFFF0000)
              : c == 1
                  ? const Color(0xFF00FF00)
                  : const Color(0xFF0000FF);

          _chromaPath.reset();
          _chromaPath.moveTo(0, 0);

          final endX = math.cos(angle) * rayLength + colorOffset;
          final endY = math.sin(angle) * rayLength;

          // Wavy ray
          const segments = 4;
          for (int seg = 1; seg <= segments; seg++) {
            final t = seg / segments;
            final wobble = math.sin(_time * 10 + i + seg * 2) * 3 * (1 - t);
            final perpX = -math.sin(angle) * wobble;
            final perpY = math.cos(angle) * wobble;

            _chromaPath.lineTo(
              endX * t + perpX + colorOffset,
              endY * t + perpY,
            );
          }

          _chromaVortexPaint.color = rayColor.withOpacity(chromaIntensity * 0.3 * (1 - progress));
          canvas.drawPath(_chromaPath, _chromaVortexPaint);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: RGB FRAGMENT PARTICLES
    // ═══════════════════════════════════════════════════════════════════════
    if (chromaIntensity > 0.2) {
      for (int i = 0; i < 12; i++) {
        final fragAngle = (i / 12) * math.pi * 2 + _time * 3;
        final fragDist = explosionSize * (0.2 + progress * 0.6);

        for (int c = 0; c < 3; c++) {
          final colorOffset = (c - 1) * chromaOffset * 0.3;
          final fragColor = c == 0
              ? const Color(0xFFFF5555)
              : c == 1
                  ? const Color(0xFF55FF55)
                  : const Color(0xFF5555FF);

          final fx = math.cos(fragAngle) * fragDist + colorOffset;
          final fy = math.sin(fragAngle) * fragDist;
          final fragSize = 2 + math.sin(_time * 8 + i) * 1;

          _chromaFragmentPaint.color = fragColor.withOpacity(chromaIntensity * 0.5);
          canvas.drawCircle(Offset(fx, fy), fragSize, _chromaFragmentPaint);
        }
      }
    }
  }

  void _drawChromaticGlitchOverlay(Canvas canvas, double progress) {
    if (progress > 0.4) return;

    final glitchIntensity = (1 - progress / 0.4);

    // ═══════════════════════════════════════════════════════════════════════
    // GLITCH SCANLINES
    // ═══════════════════════════════════════════════════════════════════════
    final scanlineCount = (6 * glitchIntensity).ceil();
    for (int i = 0; i < scanlineCount; i++) {
      final scanY = (math.sin(_time * 20 + i * 3) * explosionSize * 0.8);
      final scanWidth = explosionSize * (0.3 + _random.nextDouble() * 0.5);
      final scanAlpha = glitchIntensity * 0.3 * _random.nextDouble();

      // RGB offset scanlines
      _chromaGlitchPaint.color = const Color(0xFFFF0000).withOpacity(scanAlpha);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(-3, scanY),
          width: scanWidth,
          height: 2,
        ),
        _chromaGlitchPaint,
      );

      _chromaGlitchPaint.color = const Color(0xFF00FF00).withOpacity(scanAlpha * 0.9);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(0, scanY),
          width: scanWidth,
          height: 2,
        ),
        _chromaGlitchPaint,
      );

      _chromaGlitchPaint.color = const Color(0xFF0000FF).withOpacity(scanAlpha);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(3, scanY),
          width: scanWidth,
          height: 2,
        ),
        _chromaGlitchPaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // CHROMATIC FLASH BURST
    // ═══════════════════════════════════════════════════════════════════════
    if (progress < 0.15) {
      final flashProgress = progress / 0.15;
      final flashRadius = explosionSize * (0.5 + flashProgress * 0.5);
      final flashAlpha = (1 - flashProgress) * 0.6;

      // Bright white center with RGB corona
      _chromaFlashPaint.color = Colors.white.withOpacity(flashAlpha);
      canvas.drawCircle(Offset.zero, flashRadius * 0.5, _chromaFlashPaint);

      // RGB corona
      _chromaFlashPaint.color = const Color(0xFFFF3333).withOpacity(flashAlpha * 0.4);
      canvas.drawCircle(Offset(-4, -2), flashRadius * 0.7, _chromaFlashPaint);

      _chromaFlashPaint.color = const Color(0xFF33FF33).withOpacity(flashAlpha * 0.35);
      canvas.drawCircle(Offset.zero, flashRadius * 0.65, _chromaFlashPaint);

      _chromaFlashPaint.color = const Color(0xFF3333FF).withOpacity(flashAlpha * 0.4);
      canvas.drawCircle(Offset(4, 2), flashRadius * 0.7, _chromaFlashPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GLITCH SPARKS WITH RGB SPLIT
    // ═══════════════════════════════════════════════════════════════════════
    final sparkCount = (8 * glitchIntensity).ceil();
    for (int i = 0; i < sparkCount; i++) {
      final sparkAngle = _random.nextDouble() * math.pi * 2;
      final sparkDist = _random.nextDouble() * explosionSize * 0.6;

      final sx = math.cos(sparkAngle) * sparkDist;
      final sy = math.sin(sparkAngle) * sparkDist;

      // RGB offset sparks
      _chromaSparkPaint.color = const Color(0xFFFF0000).withOpacity(glitchIntensity * 0.6);
      canvas.drawCircle(Offset(sx - 2, sy), 1.5, _chromaSparkPaint);

      _chromaSparkPaint.color = const Color(0xFF00FF00).withOpacity(glitchIntensity * 0.55);
      canvas.drawCircle(Offset(sx, sy), 1.5, _chromaSparkPaint);

      _chromaSparkPaint.color = const Color(0xFF0000FF).withOpacity(glitchIntensity * 0.6);
      canvas.drawCircle(Offset(sx + 2, sy), 1.5, _chromaSparkPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // DIGITAL NOISE ARTIFACTS
    // ═══════════════════════════════════════════════════════════════════════
    if (glitchIntensity > 0.5) {
      final noiseCount = (10 * glitchIntensity).ceil();
      for (int i = 0; i < noiseCount; i++) {
        final nx = (_random.nextDouble() - 0.5) * explosionSize * 1.5;
        final ny = (_random.nextDouble() - 0.5) * explosionSize * 1.5;
        final noiseSize = 1 + _random.nextDouble() * 3;

        final noiseColor = _random.nextInt(3) == 0
            ? const Color(0xFFFF0000)
            : _random.nextInt(2) == 0
                ? const Color(0xFF00FF00)
                : const Color(0xFF0000FF);

        _chromaFragmentPaint.color = noiseColor.withOpacity(glitchIntensity * 0.4);
        canvas.drawRect(
          Rect.fromCenter(center: Offset(nx, ny), width: noiseSize, height: noiseSize),
          _chromaFragmentPaint,
        );
      }
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
    this.hasTrail = false,
    this.glowIntensity = 0.4,
    this.bounceEnabled = false,
    this.bounceDamping = 0.6,
  }) : _time = 0,
       distance = 0,
       currentRotation = rotation,
       fallOffset = 0,
       _prevX = 0,
       _prevY = 0,
       _velocityY = 0,
       _bounced = false;

  final double angle;
  final double speed;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final double lifetime;
  final int shape;
  final double gravity;
  final bool hasTrail;
  final double glowIntensity;
  final bool bounceEnabled;
  final double bounceDamping;

  double _time;
  double distance;
  double currentRotation;
  double fallOffset;
  double _prevX;
  double _prevY;
  double _velocityY;
  bool _bounced;

  bool get isAlive => _time < lifetime;

  double get alphaValue => isAlive ? (1 - _time / lifetime) : 0;

  double get prevX => _prevX;
  double get prevY => _prevY;

  void update(double dt) {
    // Store previous position for trail
    final currentX = math.cos(angle) * distance;
    final currentY = math.sin(angle) * distance + fallOffset;
    _prevX = currentX;
    _prevY = currentY;

    _time += dt;
    final decay = 1 - _time / lifetime * 0.3;
    distance += speed * dt * decay;
    currentRotation += rotationSpeed * dt;

    // Physics-based gravity with velocity
    _velocityY += gravity * dt;
    fallOffset += _velocityY * dt;

    // Bounce physics (simulates hitting ground at a certain Y offset)
    if (bounceEnabled && !_bounced && fallOffset > 30) {
      _velocityY = -_velocityY * bounceDamping;
      fallOffset = 30;
      _bounced = true;
    }
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
