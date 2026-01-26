import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Types of power-ups with their associated colors
enum PowerUpType {
  /// Health power-up (green)
  health,

  /// Damage boost power-up (red)
  damage,

  /// Speed boost power-up (yellow)
  speed,

  /// Shield power-up (cyan)
  shield,
}

/// Epic power-up collection effect with energy absorption visuals
/// Features 7 visual layers for rich cyberpunk aesthetics:
/// - Layer 1: Radial burst of energy particles
/// - Layer 2: Spiral of orbiting particles that collapse inward
/// - Layer 3: Central absorption glow that grows then shrinks
/// - Layer 4: Energy rings expanding outward
/// - Layer 5: Electric sparks radiating from center
/// - Layer 6: Holographic text showing power-up name/value
/// - Layer 7: Final bright flash with color pulse
class PowerUpCollectEffect extends PositionComponent {
  PowerUpCollectEffect._internal({
    required Vector2 position,
    required PowerUpType powerUpType,
    required String displayText,
    required double duration,
  }) : _random = math.Random() {
    _reset(
      position: position,
      powerUpType: powerUpType,
      displayText: displayText,
      duration: duration,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OBJECT POOLING - Follows explosion_effect.dart pattern
  // ═══════════════════════════════════════════════════════════════════════════
  static const int maxPool = 16;
  static const int maxActive = 12;
  static final List<PowerUpCollectEffect> _pool = [];
  static int _activeCount = 0;
  static double fxScale = 1.0;
  static bool reduceFx = false;
  static bool lowFx = false;
  static int get activeCount => _activeCount;

  /// Cached blur filters to avoid per-frame allocations
  static final Map<int, MaskFilter> _blurCache = {};

  static MaskFilter _blur(double sigma) {
    var key = sigma.round();
    if (key < 1) key = 1;
    if (key > 30) key = 30;
    return _blurCache.putIfAbsent(
      key,
      () => MaskFilter.blur(BlurStyle.normal, key.toDouble()),
    );
  }

  /// Clear the static pool to prevent memory accumulation between games
  static void clearPool() {
    for (final item in _pool) {
      item._cachedPainter?.dispose();
      item._cachedPainter = null;
    }
    _pool.clear();
    _activeCount = 0;
  }

  /// Spawn a power-up collection effect from the pool
  static PowerUpCollectEffect? spawn({
    required Vector2 position,
    required PowerUpType powerUpType,
    String displayText = '',
    double duration = 1.0,
  }) {
    if (_activeCount >= maxActive) return null;
    PowerUpCollectEffect effect;
    if (_pool.isNotEmpty) {
      effect = _pool.removeLast();
      effect._reset(
        position: position,
        powerUpType: powerUpType,
        displayText: displayText,
        duration: duration,
      );
    } else {
      effect = PowerUpCollectEffect._internal(
        position: position,
        powerUpType: powerUpType,
        displayText: displayText,
        duration: duration,
      );
    }
    effect._markActive();
    return effect;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════

  // Layer 1: Radial burst particles
  static final Paint _burstParticleGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _burstParticleCorePaint = Paint();

  // Layer 2: Spiral orbiting particles
  static final Paint _spiralParticleGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _spiralParticleCorePaint = Paint();
  static final Paint _spiralTrailPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  // Layer 3: Central absorption glow
  static final Paint _absorptionOuterGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  static final Paint _absorptionMidGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _absorptionInnerGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _absorptionCorePaint = Paint();

  // Layer 4: Energy rings
  static final Paint _ringGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _ringCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _ringInnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  // Layer 5: Electric sparks
  static final Paint _sparkGlowPaint = Paint()
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _sparkCorePaint = Paint()
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  static final Paint _sparkBranchPaint = Paint()
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  // Layer 6: Holographic text
  static final Paint _textGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _textShadowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _scanlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _chromaRedPaint = Paint()
    ..blendMode = BlendMode.plus;
  static final Paint _chromaBluePaint = Paint()
    ..blendMode = BlendMode.plus;
  static final Paint _textAlphaPaint = Paint();

  // Layer 7: Final flash
  static final Paint _flashOuterPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
  static final Paint _flashMidPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _flashCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _pulsePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

  // Reusable paths
  static final Path _reusablePath = Path();
  static final Path _scanlinePath = Path();

  // ═══════════════════════════════════════════════════════════════════════════
  // INSTANCE PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════════
  PowerUpType powerUpType = PowerUpType.health;
  String displayText = '';
  double duration = 1.0;

  final math.Random _random;
  double _timer = 0;
  bool _counted = false;
  bool _inPool = false;

  // Particle lists
  final List<_BurstParticle> _burstParticles = [];
  final List<_SpiralParticle> _spiralParticles = [];
  final List<_EnergyRing> _energyRings = [];
  final List<_ElectricSpark> _electricSparks = [];

  // Cached TextPainter
  TextPainter? _cachedPainter;
  String _cachedText = '';

  void _markActive() {
    if (_counted) return;
    _counted = true;
    _inPool = false;
    _activeCount++;
  }

  void _reset({
    required Vector2 position,
    required PowerUpType powerUpType,
    required String displayText,
    required double duration,
  }) {
    this.position.setFrom(position);
    anchor = Anchor.center;
    this.powerUpType = powerUpType;
    this.displayText = displayText;
    this.duration = duration;
    _timer = 0;

    // Clear particle lists
    _burstParticles.clear();
    _spiralParticles.clear();
    _energyRings.clear();
    _electricSparks.clear();

    // Initialize all particle systems
    _initializeBurstParticles();
    _initializeSpiralParticles();
    _initializeEnergyRings();
    _initializeElectricSparks();
  }

  /// Get the primary color for this power-up type
  Color get _primaryColor {
    switch (powerUpType) {
      case PowerUpType.health:
        return const Color(0xFF00FF88); // Neon green
      case PowerUpType.damage:
        return const Color(0xFFFF3366); // Neon red/pink
      case PowerUpType.speed:
        return const Color(0xFFFFDD00); // Bright yellow
      case PowerUpType.shield:
        return const Color(0xFF00DDFF); // Cyan
    }
  }

  /// Get the secondary color (HSL shifted) for this power-up type
  Color get _secondaryColor {
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl.withHue((hsl.hue + 30) % 360).toColor();
  }

  /// Get the tertiary color (HSL shifted darker) for this power-up type
  Color get _tertiaryColor {
    final hsl = HSLColor.fromColor(_primaryColor);
    return hsl
        .withHue((hsl.hue - 20) % 360)
        .withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0))
        .toColor();
  }

  /// Get the glow color (brighter version) for this power-up type
  Color get _glowColor {
    switch (powerUpType) {
      case PowerUpType.health:
        return const Color(0xFF00FFAA);
      case PowerUpType.damage:
        return const Color(0xFFFF0044);
      case PowerUpType.speed:
        return const Color(0xFFFFFF00);
      case PowerUpType.shield:
        return const Color(0xFF00FFFF);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PARTICLE INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  void _initializeBurstParticles() {
    final count = _scaledCount(20, allowZero: true);
    if (count == 0) return;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + _random.nextDouble() * 0.3;
      final speed = 80 + _random.nextDouble() * 100;
      final size = 2 + _random.nextDouble() * 3;
      final lifetime = 0.3 + _random.nextDouble() * 0.3;

      _burstParticles.add(_BurstParticle(
        angle: angle,
        speed: speed,
        size: size,
        lifetime: lifetime,
        decay: 0.85 + _random.nextDouble() * 0.1,
      ));
    }
  }

  void _initializeSpiralParticles() {
    final count = _scaledCount(12, allowZero: true);
    if (count == 0) return;

    for (int i = 0; i < count; i++) {
      final startAngle = (i / count) * math.pi * 2;
      final startRadius = 40 + _random.nextDouble() * 20;
      final rotationSpeed = 8 + _random.nextDouble() * 4;
      final collapseSpeed = 60 + _random.nextDouble() * 30;

      _spiralParticles.add(_SpiralParticle(
        startAngle: startAngle,
        startRadius: startRadius,
        rotationSpeed: rotationSpeed * (i % 2 == 0 ? 1 : -1), // Alternate direction
        collapseSpeed: collapseSpeed,
        size: 2 + _random.nextDouble() * 2,
        lifetime: 0.6 + _random.nextDouble() * 0.2,
      ));
    }
  }

  void _initializeEnergyRings() {
    final count = _scaledCount(4);
    for (int i = 0; i < count; i++) {
      _energyRings.add(_EnergyRing(
        startDelay: i * 0.12,
        startRadius: 5 + i * 3,
        endRadius: 50 + i * 15,
        expandDuration: 0.4 + i * 0.1,
      ));
    }
  }

  void _initializeElectricSparks() {
    final count = _scaledCount(8, allowZero: true);
    if (count == 0) return;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + _random.nextDouble() * 0.5;
      final length = 20 + _random.nextDouble() * 30;

      _electricSparks.add(_ElectricSpark(
        baseAngle: angle,
        length: length,
        lifetime: 0.15 + _random.nextDouble() * 0.15,
        startDelay: _random.nextDouble() * 0.3,
        segments: 3 + _random.nextInt(3),
        hasBranches: _random.nextDouble() > 0.5,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // UPDATE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void update(double dt) {
    super.update(dt);

    _timer += dt;

    if (_timer >= duration) {
      _recycle();
      return;
    }

    // Update all particle systems
    for (final particle in _burstParticles) {
      particle.update(dt);
    }

    for (final particle in _spiralParticles) {
      particle.update(dt);
    }

    for (final ring in _energyRings) {
      ring.update(dt);
    }

    for (final spark in _electricSparks) {
      spark.update(dt, _timer);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RENDER
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (lowFx) {
      _renderSimple(canvas);
      return;
    }

    final progress = (_timer / duration).clamp(0.0, 1.0);

    // Layer 1: Radial burst particles (behind everything)
    _drawBurstParticles(canvas, progress);

    // Layer 2: Spiral orbiting particles
    if (!reduceFx) {
      _drawSpiralParticles(canvas, progress);
    }

    // Layer 3: Central absorption glow
    _drawAbsorptionGlow(canvas, progress);

    // Layer 4: Energy rings expanding outward
    _drawEnergyRings(canvas, progress);

    // Layer 5: Electric sparks
    if (!reduceFx) {
      _drawElectricSparks(canvas, progress);
    }

    // Layer 6: Holographic text
    if (displayText.isNotEmpty && !reduceFx) {
      _drawHolographicText(canvas, progress);
    }

    // Layer 7: Final flash with color pulse
    _drawFinalFlash(canvas, progress);
  }

  /// Render simplified version for low FX mode
  void _renderSimple(Canvas canvas) {
    final progress = (_timer / duration).clamp(0.0, 1.0);

    // Simple absorption glow
    final glowSize = progress < 0.5
        ? 30 * (progress / 0.5)
        : 30 * (1 - (progress - 0.5) / 0.5);
    final alpha = 1.0 - progress;

    _absorptionCorePaint.color = _primaryColor.withOpacity(alpha * 0.6);
    canvas.drawCircle(Offset.zero, glowSize, _absorptionCorePaint);

    // Simple expanding ring
    final ringRadius = progress * 60;
    final ringAlpha = (1 - progress) * 0.5;
    _ringCorePaint.color = _primaryColor.withOpacity(ringAlpha);
    canvas.drawCircle(Offset.zero, ringRadius, _ringCorePaint);

    // Simple text
    if (displayText.isNotEmpty) {
      _ensurePainter();
      if (_cachedPainter != null) {
        final textAlpha = progress < 0.2
            ? progress / 0.2
            : progress > 0.7
                ? 1 - (progress - 0.7) / 0.3
                : 1.0;
        final yOffset = -20 - progress * 15;

        canvas.save();
        canvas.translate(0, yOffset);
        _textAlphaPaint.color = Color.fromRGBO(255, 255, 255, textAlpha);
        canvas.saveLayer(null, _textAlphaPaint);
        _cachedPainter!.paint(
          canvas,
          Offset(-_cachedPainter!.width / 2, -_cachedPainter!.height / 2),
        );
        canvas.restore();
        canvas.restore();
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 1: RADIAL BURST PARTICLES
  // ═══════════════════════════════════════════════════════════════════════════

  void _drawBurstParticles(Canvas canvas, double progress) {
    for (final particle in _burstParticles) {
      if (!particle.isAlive) continue;

      final x = math.cos(particle.angle) * particle.distance;
      final y = math.sin(particle.angle) * particle.distance;
      final alpha = particle.alphaValue;

      // Particle glow
      _burstParticleGlowPaint.color = _primaryColor.withOpacity(alpha * 0.4);
      canvas.drawCircle(Offset(x, y), particle.currentSize * 2, _burstParticleGlowPaint);

      // Particle core
      _burstParticleCorePaint.color = _glowColor.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), particle.currentSize, _burstParticleCorePaint);

      // Bright center
      _burstParticleCorePaint.color = Colors.white.withOpacity(alpha * 0.8);
      canvas.drawCircle(Offset(x, y), particle.currentSize * 0.4, _burstParticleCorePaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 2: SPIRAL ORBITING PARTICLES
  // ═══════════════════════════════════════════════════════════════════════════

  void _drawSpiralParticles(Canvas canvas, double progress) {
    for (final particle in _spiralParticles) {
      if (!particle.isAlive) continue;

      final x = math.cos(particle.currentAngle) * particle.currentRadius;
      final y = math.sin(particle.currentAngle) * particle.currentRadius;
      final alpha = particle.alphaValue;

      // Draw trail
      if (particle.trailPositions.length > 1) {
        _spiralTrailPaint.color = _secondaryColor.withOpacity(alpha * 0.3);
        _spiralTrailPaint.strokeWidth = particle.size * 0.8;

        for (int i = 1; i < particle.trailPositions.length; i++) {
          final trailAlpha = alpha * (i / particle.trailPositions.length) * 0.5;
          _spiralTrailPaint.color = _secondaryColor.withOpacity(trailAlpha);
          canvas.drawLine(
            particle.trailPositions[i - 1],
            particle.trailPositions[i],
            _spiralTrailPaint,
          );
        }
      }

      // Particle glow
      _spiralParticleGlowPaint.color = _secondaryColor.withOpacity(alpha * 0.5);
      canvas.drawCircle(Offset(x, y), particle.size * 2, _spiralParticleGlowPaint);

      // Particle core
      _spiralParticleCorePaint.color = _glowColor.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), particle.size, _spiralParticleCorePaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 3: CENTRAL ABSORPTION GLOW
  // ═══════════════════════════════════════════════════════════════════════════

  void _drawAbsorptionGlow(Canvas canvas, double progress) {
    // Absorption animation: grow from 0-0.3, hold 0.3-0.6, shrink 0.6-0.9
    double absorptionScale;
    double absorptionAlpha;

    if (progress < 0.3) {
      // Growing phase
      absorptionScale = progress / 0.3;
      absorptionAlpha = progress / 0.3;
    } else if (progress < 0.6) {
      // Hold phase with pulse
      absorptionScale = 1.0 + math.sin((progress - 0.3) / 0.3 * math.pi * 4) * 0.1;
      absorptionAlpha = 1.0;
    } else if (progress < 0.9) {
      // Shrinking phase
      final shrinkProgress = (progress - 0.6) / 0.3;
      absorptionScale = 1.0 - shrinkProgress * 0.8;
      absorptionAlpha = 1.0 - shrinkProgress * 0.5;
    } else {
      // Final fade
      absorptionScale = 0.2;
      absorptionAlpha = 1.0 - (progress - 0.9) / 0.1;
    }

    final baseSize = 25.0;

    // Outer glow (large, soft)
    _absorptionOuterGlowPaint.color = _primaryColor.withOpacity(absorptionAlpha * 0.2);
    canvas.drawCircle(Offset.zero, baseSize * 2 * absorptionScale, _absorptionOuterGlowPaint);

    // Mid glow
    _absorptionMidGlowPaint.color = _primaryColor.withOpacity(absorptionAlpha * 0.4);
    canvas.drawCircle(Offset.zero, baseSize * 1.3 * absorptionScale, _absorptionMidGlowPaint);

    // Inner glow
    _absorptionInnerGlowPaint.color = _glowColor.withOpacity(absorptionAlpha * 0.6);
    canvas.drawCircle(Offset.zero, baseSize * 0.8 * absorptionScale, _absorptionInnerGlowPaint);

    // Core
    _absorptionCorePaint.color = Colors.white.withOpacity(absorptionAlpha * 0.8);
    canvas.drawCircle(Offset.zero, baseSize * 0.3 * absorptionScale, _absorptionCorePaint);

    // Energy tendrils toward center (during collapse)
    if (progress > 0.2 && progress < 0.7 && !reduceFx) {
      final tendrilCount = 6;
      final tendrilAlpha = absorptionAlpha * 0.4;

      for (int i = 0; i < tendrilCount; i++) {
        final angle = (i / tendrilCount) * math.pi * 2 + _timer * 3;
        final tendrilLength = baseSize * 1.5 * absorptionScale;

        _reusablePath.reset();
        _reusablePath.moveTo(
          math.cos(angle) * tendrilLength,
          math.sin(angle) * tendrilLength,
        );

        // Curve toward center
        _reusablePath.quadraticBezierTo(
          math.cos(angle + 0.3) * tendrilLength * 0.5,
          math.sin(angle + 0.3) * tendrilLength * 0.5,
          0,
          0,
        );

        _sparkGlowPaint.color = _secondaryColor.withOpacity(tendrilAlpha);
        _sparkGlowPaint.style = PaintingStyle.stroke;
        _sparkGlowPaint.strokeWidth = 2;
        canvas.drawPath(_reusablePath, _sparkGlowPaint);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 4: ENERGY RINGS EXPANDING OUTWARD
  // ═══════════════════════════════════════════════════════════════════════════

  void _drawEnergyRings(Canvas canvas, double progress) {
    for (final ring in _energyRings) {
      if (!ring.isActive(_timer)) continue;

      final ringProgress = ring.getProgress(_timer);
      final radius = ring.getCurrentRadius(_timer);
      final alpha = (1 - ringProgress) * (1 - progress * 0.5);

      if (alpha <= 0) continue;

      // Outer glow ring
      _ringGlowPaint.color = _primaryColor.withOpacity(alpha * 0.3);
      canvas.drawCircle(Offset.zero, radius, _ringGlowPaint);

      // Main ring
      _ringCorePaint.color = _primaryColor.withOpacity(alpha * 0.6);
      canvas.drawCircle(Offset.zero, radius, _ringCorePaint);

      // Inner bright ring
      _ringInnerPaint.color = Colors.white.withOpacity(alpha * 0.4);
      canvas.drawCircle(Offset.zero, radius * 0.95, _ringInnerPaint);

      // Secondary color ring (offset)
      if (!reduceFx) {
        _ringInnerPaint.color = _secondaryColor.withOpacity(alpha * 0.2);
        canvas.drawCircle(Offset.zero, radius * 1.02, _ringInnerPaint);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 5: ELECTRIC SPARKS RADIATING FROM CENTER
  // ═══════════════════════════════════════════════════════════════════════════

  void _drawElectricSparks(Canvas canvas, double progress) {
    for (final spark in _electricSparks) {
      if (!spark.isActive(_timer)) continue;

      final sparkAlpha = spark.getAlpha(_timer) * (1 - progress * 0.3);
      if (sparkAlpha <= 0) continue;

      // Draw main lightning bolt
      _reusablePath.reset();
      _reusablePath.moveTo(0, 0);

      final segments = spark.segments;
      var currentX = 0.0;
      var currentY = 0.0;

      for (int i = 1; i <= segments; i++) {
        final t = i / segments;
        final baseX = math.cos(spark.currentAngle) * spark.length * t;
        final baseY = math.sin(spark.currentAngle) * spark.length * t;

        // Add jitter perpendicular to direction
        final perpAngle = spark.currentAngle + math.pi / 2;
        final jitter = (i == segments) ? 0 : ((_random.nextDouble() - 0.5) * 10);
        final jitterX = math.cos(perpAngle) * jitter;
        final jitterY = math.sin(perpAngle) * jitter;

        currentX = baseX + jitterX;
        currentY = baseY + jitterY;

        _reusablePath.lineTo(currentX, currentY);

        // Draw branches
        if (spark.hasBranches && i == segments ~/ 2) {
          final branchAngle = spark.currentAngle + (_random.nextDouble() - 0.5) * 1.0;
          final branchLength = spark.length * 0.4;
          final branchEndX = currentX + math.cos(branchAngle) * branchLength;
          final branchEndY = currentY + math.sin(branchAngle) * branchLength;

          _sparkBranchPaint.color = _tertiaryColor.withOpacity(sparkAlpha * 0.6);
          canvas.drawLine(
            Offset(currentX, currentY),
            Offset(branchEndX, branchEndY),
            _sparkBranchPaint,
          );
        }
      }

      // Draw glow
      _sparkGlowPaint.color = _primaryColor.withOpacity(sparkAlpha * 0.5);
      _sparkGlowPaint.style = PaintingStyle.stroke;
      _sparkGlowPaint.strokeWidth = 3;
      canvas.drawPath(_reusablePath, _sparkGlowPaint);

      // Draw core
      _sparkCorePaint.color = Colors.white.withOpacity(sparkAlpha);
      canvas.drawPath(_reusablePath, _sparkCorePaint);

      // Spark endpoint glow
      _burstParticleGlowPaint.color = _glowColor.withOpacity(sparkAlpha * 0.6);
      canvas.drawCircle(Offset(currentX, currentY), 3, _burstParticleGlowPaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 6: HOLOGRAPHIC TEXT
  // ═══════════════════════════════════════════════════════════════════════════

  void _drawHolographicText(Canvas canvas, double progress) {
    _ensurePainter();
    if (_cachedPainter == null) return;

    // Text animation: fade in 0-0.15, hold, fade out 0.7-1.0
    double textAlpha;
    if (progress < 0.15) {
      textAlpha = progress / 0.15;
    } else if (progress > 0.7) {
      textAlpha = 1.0 - (progress - 0.7) / 0.3;
    } else {
      textAlpha = 1.0;
    }

    // Float upward
    final yOffset = -25 - progress * 20;

    // Scale: pop in, then hold
    double scale;
    if (progress < 0.1) {
      scale = progress / 0.1 * 1.1;
    } else if (progress < 0.15) {
      scale = 1.1 - (progress - 0.1) / 0.05 * 0.1;
    } else {
      scale = 1.0;
    }

    canvas.save();
    canvas.translate(0, yOffset);
    canvas.scale(scale, scale);

    final textWidth = _cachedPainter!.width;
    final textHeight = _cachedPainter!.height;
    final textOffset = Offset(-textWidth / 2, -textHeight / 2);

    // Glow behind text
    _textGlowPaint.color = _glowColor.withOpacity(textAlpha * 0.4);
    canvas.saveLayer(null, _textGlowPaint);
    _cachedPainter!.paint(canvas, textOffset);
    canvas.restore();

    // Secondary glow
    _textShadowPaint.color = _primaryColor.withOpacity(textAlpha * 0.3);
    _textShadowPaint.maskFilter = _blur(10);
    canvas.saveLayer(null, _textShadowPaint);
    _cachedPainter!.paint(canvas, textOffset);
    canvas.restore();

    // Chromatic aberration
    final chromaOffset = 1.5 + math.sin(_timer * 10) * 0.5;

    _chromaRedPaint.color = const Color(0xFFFF0000).withOpacity(textAlpha * 0.2);
    canvas.saveLayer(null, _chromaRedPaint);
    _cachedPainter!.paint(canvas, textOffset + Offset(-chromaOffset, 0));
    canvas.restore();

    _chromaBluePaint.color = const Color(0xFF0066FF).withOpacity(textAlpha * 0.2);
    canvas.saveLayer(null, _chromaBluePaint);
    _cachedPainter!.paint(canvas, textOffset + Offset(chromaOffset, 0));
    canvas.restore();

    // Main text
    _textAlphaPaint.color = Color.fromRGBO(255, 255, 255, textAlpha);
    canvas.saveLayer(null, _textAlphaPaint);
    _cachedPainter!.paint(canvas, textOffset);
    canvas.restore();

    // Scanlines
    _drawTextScanlines(canvas, textOffset, textWidth, textHeight, textAlpha);

    canvas.restore();
  }

  void _drawTextScanlines(
    Canvas canvas,
    Offset textOffset,
    double textWidth,
    double textHeight,
    double alpha,
  ) {
    final scanlineOffset = (_timer * 40) % 5;

    _scanlinePath.reset();

    for (double y = textOffset.dy - 2 + scanlineOffset; y < textOffset.dy + textHeight + 2; y += 5) {
      _scanlinePath.moveTo(textOffset.dx - 4, y);
      _scanlinePath.lineTo(textOffset.dx + textWidth + 4, y);
    }

    _scanlinePaint.color = _primaryColor.withOpacity(alpha * 0.12);
    canvas.drawPath(_scanlinePath, _scanlinePaint);
  }

  void _ensurePainter() {
    if (_cachedPainter != null && _cachedText == displayText) {
      return;
    }

    _cachedText = displayText;
    _cachedPainter?.dispose();

    _cachedPainter = TextPainter(
      text: TextSpan(
        text: displayText,
        style: TextStyle(
          color: _primaryColor,
          fontSize: 14,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 7: FINAL FLASH WITH COLOR PULSE
  // ═══════════════════════════════════════════════════════════════════════════

  void _drawFinalFlash(Canvas canvas, double progress) {
    // Initial flash at start (0-0.1)
    if (progress < 0.1) {
      final flashProgress = progress / 0.1;
      final flashAlpha = (1 - flashProgress) * 0.8;
      final flashRadius = 20 + flashProgress * 30;

      // Outer flash
      _flashOuterPaint.color = _primaryColor.withOpacity(flashAlpha * 0.3);
      canvas.drawCircle(Offset.zero, flashRadius * 1.5, _flashOuterPaint);

      // Mid flash
      _flashMidPaint.color = _glowColor.withOpacity(flashAlpha * 0.5);
      canvas.drawCircle(Offset.zero, flashRadius, _flashMidPaint);

      // Core flash
      _flashCorePaint.color = Colors.white.withOpacity(flashAlpha);
      canvas.drawCircle(Offset.zero, flashRadius * 0.5, _flashCorePaint);
    }

    // Final pulse at end (0.85-1.0)
    if (progress > 0.85) {
      final pulseProgress = (progress - 0.85) / 0.15;
      final pulseAlpha = math.sin(pulseProgress * math.pi);
      final pulseRadius = 30 + pulseProgress * 40;

      // Expanding pulse ring
      _pulsePaint.color = _primaryColor.withOpacity(pulseAlpha * 0.6);
      canvas.drawCircle(Offset.zero, pulseRadius, _pulsePaint);

      // Secondary color pulse
      _pulsePaint.color = _secondaryColor.withOpacity(pulseAlpha * 0.4);
      canvas.drawCircle(Offset.zero, pulseRadius * 1.1, _pulsePaint);

      // Bright center flash
      if (pulseProgress < 0.5) {
        final centerAlpha = (1 - pulseProgress * 2) * 0.7;
        _flashCorePaint.color = Colors.white.withOpacity(centerAlpha);
        canvas.drawCircle(Offset.zero, 15 * (1 - pulseProgress), _flashCorePaint);
      }
    }

    // Color cycling pulse throughout (subtle)
    if (!reduceFx && progress > 0.1 && progress < 0.85) {
      final pulseIntensity = math.sin(_timer * 12) * 0.15 + 0.15;
      final pulseRadius = 8 + math.sin(_timer * 8) * 3;

      _flashCorePaint.color = _primaryColor.withOpacity(pulseIntensity);
      canvas.drawCircle(Offset.zero, pulseRadius, _flashCorePaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECYCLING / CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

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

    // Dispose painter before pooling
    _cachedPainter?.dispose();
    _cachedPainter = null;
    _cachedText = '';

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

    // Dispose painter on removal
    _cachedPainter?.dispose();
    _cachedPainter = null;

    super.onRemove();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PARTICLE CLASSES
// ═══════════════════════════════════════════════════════════════════════════

/// Burst particle for Layer 1
class _BurstParticle {
  _BurstParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.lifetime,
    required this.decay,
  }) : _time = 0,
       distance = 0,
       currentSize = size;

  final double angle;
  final double speed;
  final double size;
  final double lifetime;
  final double decay;

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

/// Spiral particle for Layer 2
class _SpiralParticle {
  _SpiralParticle({
    required this.startAngle,
    required this.startRadius,
    required this.rotationSpeed,
    required this.collapseSpeed,
    required this.size,
    required this.lifetime,
  }) : _time = 0,
       currentAngle = startAngle,
       currentRadius = startRadius,
       trailPositions = [];

  final double startAngle;
  final double startRadius;
  final double rotationSpeed;
  final double collapseSpeed;
  final double size;
  final double lifetime;

  double _time;
  double currentAngle;
  double currentRadius;
  final List<Offset> trailPositions;

  static const int maxTrailLength = 8;

  bool get isAlive => _time < lifetime && currentRadius > 0;
  double get alphaValue => isAlive ? (1 - _time / lifetime) : 0;

  void update(double dt) {
    // Store previous position for trail
    final prevX = math.cos(currentAngle) * currentRadius;
    final prevY = math.sin(currentAngle) * currentRadius;
    trailPositions.add(Offset(prevX, prevY));
    if (trailPositions.length > maxTrailLength) {
      trailPositions.removeAt(0);
    }

    _time += dt;
    currentAngle += rotationSpeed * dt;
    currentRadius -= collapseSpeed * dt;
    if (currentRadius < 0) currentRadius = 0;
  }
}

/// Energy ring for Layer 4
class _EnergyRing {
  _EnergyRing({
    required this.startDelay,
    required this.startRadius,
    required this.endRadius,
    required this.expandDuration,
  });

  final double startDelay;
  final double startRadius;
  final double endRadius;
  final double expandDuration;

  bool isActive(double time) {
    return time >= startDelay && time < startDelay + expandDuration;
  }

  double getProgress(double time) {
    if (time < startDelay) return 0;
    return ((time - startDelay) / expandDuration).clamp(0.0, 1.0);
  }

  double getCurrentRadius(double time) {
    final progress = getProgress(time);
    return startRadius + (endRadius - startRadius) * progress;
  }

  void update(double dt) {
    // State is computed from global time, no internal state needed
  }
}

/// Electric spark for Layer 5
class _ElectricSpark {
  _ElectricSpark({
    required this.baseAngle,
    required this.length,
    required this.lifetime,
    required this.startDelay,
    required this.segments,
    required this.hasBranches,
  }) : currentAngle = baseAngle;

  final double baseAngle;
  final double length;
  final double lifetime;
  final double startDelay;
  final int segments;
  final bool hasBranches;

  double currentAngle;

  bool isActive(double time) {
    return time >= startDelay && time < startDelay + lifetime;
  }

  double getAlpha(double time) {
    if (time < startDelay) return 0;
    final progress = (time - startDelay) / lifetime;
    if (progress > 1) return 0;
    // Flash on, then fade
    if (progress < 0.2) return progress / 0.2;
    return 1 - (progress - 0.2) / 0.8;
  }

  void update(double dt, double time) {
    // Add slight angle jitter for electric effect
    currentAngle = baseAngle + math.sin(time * 20) * 0.1;
  }
}
