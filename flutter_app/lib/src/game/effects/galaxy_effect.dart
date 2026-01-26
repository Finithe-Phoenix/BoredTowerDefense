import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Spiral galaxy effect for ultimate abilities
/// Features 7 layers: core, spiral arms, star particles, dust lanes, halo, absorption, expansion
class GalaxyEffect extends PositionComponent {
  GalaxyEffect._internal({
    required Vector2 position,
    required double galaxySize,
    required double duration,
  }) : _random = math.Random() {
    _reset(
      position: position,
      galaxySize: galaxySize,
      duration: duration,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OBJECT POOLING
  // ═══════════════════════════════════════════════════════════════════════════
  static const int maxPool = 8;
  static const int maxActive = 4;
  static final List<GalaxyEffect> _pool = [];
  static int _activeCount = 0;
  static double fxScale = 1.0;
  static int get activeCount => _activeCount;
  static final Map<int, MaskFilter> _blurCache = {};

  static MaskFilter _blur(double sigma) {
    var key = sigma.round();
    if (key < 1) key = 1;
    if (key > 50) key = 50;
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

  static GalaxyEffect? spawn({
    required Vector2 position,
    double galaxySize = 80.0,
    double duration = 2.0,
  }) {
    if (_activeCount >= maxActive) return null;
    GalaxyEffect effect;
    if (_pool.isNotEmpty) {
      effect = _pool.removeLast();
      effect._reset(
        position: position,
        galaxySize: galaxySize,
        duration: duration,
      );
    } else {
      effect = GalaxyEffect._internal(
        position: position,
        galaxySize: galaxySize,
        duration: duration,
      );
    }
    effect._markActive();
    return effect;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORS - Cyberpunk galaxy palette
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color _coreWhite = Color(0xFFFFFFFF);
  static const Color _coreBlue = Color(0xFF88CCFF);
  static const Color _armBlue = Color(0xFF4488FF);
  static const Color _armPurple = Color(0xFFAA66FF);
  static const Color _starWhite = Color(0xFFEEEEFF);
  static const Color _starPink = Color(0xFFFFAADD);
  static const Color _dustPurple = Color(0xFF442266);
  static const Color _haloPurple = Color(0xFF6633AA);
  static const Color _haloBlue = Color(0xFF3366CC);
  static const Color _absorptionCyan = Color(0xFF66FFFF);

  double galaxySize = 80.0;
  double duration = 2.0;

  final List<_SpiralArm> _spiralArms = [];
  final List<_StarParticle> _stars = [];
  final List<_DustLane> _dustLanes = [];
  final List<_AbsorptionParticle> _absorptionParticles = [];
  double _time = 0;
  final math.Random _random;
  bool _counted = false;
  bool _inPool = false;

  // Core properties
  double _coreIntensity = 0;
  double _coreRotation = 0;

  // Halo properties
  double _haloRadius = 0;
  double _haloAlpha = 0;

  // Expansion/collapse phase
  double _expansionScale = 1.0;
  bool _isCollapsing = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════

  // Layer 1: Core paints
  final Paint _coreOuterGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
  final Paint _coreMidGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  final Paint _coreInnerGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _coreCenterPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  // Layer 2: Spiral arm paints
  final Paint _armGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _armCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Path _armPath = Path();

  // Layer 3: Star particle paints
  final Paint _starGlowPaint = Paint();
  final Paint _starCorePaint = Paint();
  final Paint _starTrailPaint = Paint()
    ..strokeCap = StrokeCap.round;

  // Layer 4: Dust lane paints
  final Paint _dustPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

  // Layer 5: Halo paints
  final Paint _haloOuterPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  final Paint _haloInnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _haloGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

  // Layer 6: Absorption effect paints
  final Paint _absorptionTrailPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  final Paint _absorptionParticlePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  // Layer 7: Expansion/collapse paints
  final Paint _expansionRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  final Paint _collapseFlashPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

  // Reusable path for drawing
  final Path _reusablePath = Path();

  void _markActive() {
    if (_counted) return;
    _counted = true;
    _inPool = false;
    _activeCount++;
  }

  void _reset({
    required Vector2 position,
    required double galaxySize,
    required double duration,
  }) {
    this.position.setFrom(position);
    anchor = Anchor.center;
    this.galaxySize = galaxySize;
    this.duration = duration;
    _time = 0;
    _coreIntensity = 0;
    _coreRotation = 0;
    _haloRadius = 0;
    _haloAlpha = 0;
    _expansionScale = 1.0;
    _isCollapsing = false;
    _spiralArms.clear();
    _stars.clear();
    _dustLanes.clear();
    _absorptionParticles.clear();
    _initializeSpiralArms();
    _initializeStars();
    _initializeDustLanes();
    _initializeAbsorptionParticles();
  }

  void _initializeSpiralArms() {
    final armCount = _scaledCount(3, min: 2, max: 4);
    for (int i = 0; i < armCount; i++) {
      final baseAngle = (i / armCount) * math.pi * 2;
      final isPrimary = i < 2;
      _spiralArms.add(_SpiralArm(
        baseAngle: baseAngle,
        length: galaxySize * (isPrimary ? 1.0 : 0.7),
        width: isPrimary ? 8.0 : 5.0,
        spiralTightness: 0.4 + _random.nextDouble() * 0.2,
        rotationSpeed: 1.2 + _random.nextDouble() * 0.3,
        segmentCount: isPrimary ? 20 : 14,
        isPrimary: isPrimary,
      ));
    }
  }

  void _initializeStars() {
    final starCount = _scaledCount(60, min: 20, max: 80);
    for (int i = 0; i < starCount; i++) {
      // Distribute stars along spiral arms with some scatter
      final armIndex = i % _spiralArms.length;
      final arm = _spiralArms[armIndex];
      final t = _random.nextDouble(); // Position along arm (0 = center, 1 = edge)
      final scatter = (_random.nextDouble() - 0.5) * 20; // Perpendicular scatter

      _stars.add(_StarParticle(
        armIndex: armIndex,
        positionT: t,
        scatter: scatter,
        size: 1.0 + _random.nextDouble() * 2.5,
        brightness: 0.4 + _random.nextDouble() * 0.6,
        twinkleSpeed: 3 + _random.nextDouble() * 5,
        twinklePhase: _random.nextDouble() * math.pi * 2,
        isPink: _random.nextDouble() > 0.85, // 15% pink stars
      ));
    }
  }

  void _initializeDustLanes() {
    final dustCount = _scaledCount(4, min: 2, max: 6);
    for (int i = 0; i < dustCount; i++) {
      final baseAngle = (i / dustCount) * math.pi * 2 + math.pi / dustCount;
      _dustLanes.add(_DustLane(
        baseAngle: baseAngle,
        width: 15 + _random.nextDouble() * 10,
        length: galaxySize * (0.5 + _random.nextDouble() * 0.3),
        opacity: 0.2 + _random.nextDouble() * 0.15,
      ));
    }
  }

  void _initializeAbsorptionParticles() {
    final particleCount = _scaledCount(30, min: 15, max: 45);
    for (int i = 0; i < particleCount; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final distance = galaxySize * (1.2 + _random.nextDouble() * 0.8);
      _absorptionParticles.add(_AbsorptionParticle(
        angle: angle,
        initialDistance: distance,
        speed: 40 + _random.nextDouble() * 60,
        size: 1.5 + _random.nextDouble() * 2,
        delay: _random.nextDouble() * 0.5,
        trailLength: 8 + _random.nextDouble() * 12,
      ));
    }
  }

  int _scaledCount(int base, {int min = 1, int max = 100}) {
    final scaled = (base * fxScale).round();
    return scaled.clamp(min, max);
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

    // Phase timing
    // 0.0 - 0.2: Buildup (core appears, arms start forming)
    // 0.2 - 0.7: Full rotation (everything active)
    // 0.7 - 0.85: Absorption (particles pull in)
    // 0.85 - 1.0: Collapse/expansion finale

    // Core intensity
    if (progress < 0.2) {
      _coreIntensity = progress / 0.2;
    } else if (progress < 0.85) {
      _coreIntensity = 1.0;
    } else {
      _coreIntensity = 1.0 - (progress - 0.85) / 0.15;
    }

    // Core rotation
    _coreRotation += dt * 2.0;

    // Halo
    if (progress < 0.15) {
      _haloRadius = galaxySize * 1.3 * (progress / 0.15);
      _haloAlpha = progress / 0.15 * 0.5;
    } else if (progress < 0.85) {
      _haloRadius = galaxySize * 1.3;
      _haloAlpha = 0.5;
    } else {
      final collapseProgress = (progress - 0.85) / 0.15;
      _haloRadius = galaxySize * 1.3 * (1 + collapseProgress * 0.5);
      _haloAlpha = 0.5 * (1 - collapseProgress);
    }

    // Expansion/collapse phase
    if (progress > 0.85) {
      _isCollapsing = true;
      final collapseProgress = (progress - 0.85) / 0.15;
      // Quick collapse then expansion
      if (collapseProgress < 0.5) {
        _expansionScale = 1.0 - collapseProgress * 0.8;
      } else {
        _expansionScale = 0.6 + (collapseProgress - 0.5) * 4.0;
      }
    }

    // Update spiral arms
    for (final arm in _spiralArms) {
      arm.update(dt, progress);
    }

    // Update absorption particles
    for (final particle in _absorptionParticles) {
      particle.update(dt, _time, progress);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = _time / duration;

    canvas.save();
    canvas.scale(_expansionScale);

    // Layer 4: Dust lanes (behind arms)
    _drawDustLanes(canvas, progress);

    // Layer 5: Outer halo glow
    _drawHalo(canvas, progress);

    // Layer 2: Spiral arms
    _drawSpiralArms(canvas, progress);

    // Layer 3: Star particles along arms
    _drawStars(canvas, progress);

    // Layer 6: Energy absorption effect
    _drawAbsorptionEffect(canvas, progress);

    // Layer 1: Central bright core (on top)
    _drawCore(canvas, progress);

    canvas.restore();

    // Layer 7: Final expansion/collapse (outside scale transform)
    if (_isCollapsing) {
      _drawExpansionCollapse(canvas, progress);
    }
  }

  void _drawCore(Canvas canvas, double progress) {
    if (_coreIntensity <= 0) return;

    final coreSize = galaxySize * 0.25 * _coreIntensity;

    // Outer blue glow
    _coreOuterGlowPaint.color = _coreBlue.withOpacity(_coreIntensity * 0.3);
    canvas.drawCircle(Offset.zero, coreSize * 1.8, _coreOuterGlowPaint);

    // Mid purple-blue glow
    _coreMidGlowPaint.color = _armPurple.withOpacity(_coreIntensity * 0.4);
    canvas.drawCircle(Offset.zero, coreSize * 1.2, _coreMidGlowPaint);

    // Inner bright blue glow
    _coreInnerGlowPaint.color = _coreBlue.withOpacity(_coreIntensity * 0.7);
    canvas.drawCircle(Offset.zero, coreSize * 0.8, _coreInnerGlowPaint);

    // Bright white center
    _coreCenterPaint.color = _coreWhite.withOpacity(_coreIntensity * 0.9);
    canvas.drawCircle(Offset.zero, coreSize * 0.4, _coreCenterPaint);

    // Rotating core flares
    final flareCount = 6;
    for (int i = 0; i < flareCount; i++) {
      final angle = _coreRotation + (i / flareCount) * math.pi * 2;
      final flareLength = coreSize * (0.8 + math.sin(_time * 4 + i) * 0.2);
      final x = math.cos(angle) * flareLength;
      final y = math.sin(angle) * flareLength;

      _coreCenterPaint.color = _coreWhite.withOpacity(_coreIntensity * 0.5);
      canvas.drawCircle(Offset(x, y), 2, _coreCenterPaint);
    }
  }

  void _drawSpiralArms(Canvas canvas, double progress) {
    if (progress < 0.05) return; // Arms appear after initial flash

    final armProgress = progress < 0.2
        ? (progress - 0.05) / 0.15
        : progress < 0.85
            ? 1.0
            : 1.0 - (progress - 0.85) / 0.15;

    if (armProgress <= 0) return;

    for (final arm in _spiralArms) {
      _drawSingleArm(canvas, arm, armProgress);
    }
  }

  void _drawSingleArm(Canvas canvas, _SpiralArm arm, double armProgress) {
    _armPath.reset();

    final segmentCount = arm.segmentCount;
    bool pathStarted = false;

    for (int i = 0; i < segmentCount; i++) {
      final t = i / (segmentCount - 1);
      final visibleT = t * armProgress;

      // Logarithmic spiral: r = a * e^(b * theta)
      final theta = arm.currentAngle + visibleT * math.pi * 2 * arm.spiralTightness;
      final r = visibleT * arm.length;

      final x = math.cos(theta) * r;
      final y = math.sin(theta) * r;

      if (!pathStarted) {
        _armPath.moveTo(x, y);
        pathStarted = true;
      } else {
        _armPath.lineTo(x, y);
      }
    }

    // Outer glow
    final glowAlpha = armProgress * (arm.isPrimary ? 0.4 : 0.25);
    _armGlowPaint
      ..color = _armPurple.withOpacity(glowAlpha)
      ..strokeWidth = arm.width * 2.5
      ..maskFilter = _blur(arm.width);
    canvas.drawPath(_armPath, _armGlowPaint);

    // Core of arm
    final coreAlpha = armProgress * (arm.isPrimary ? 0.7 : 0.5);
    _armCorePaint
      ..color = _armBlue.withOpacity(coreAlpha)
      ..strokeWidth = arm.width;
    canvas.drawPath(_armPath, _armCorePaint);

    // Bright inner line
    _armCorePaint
      ..color = _coreBlue.withOpacity(coreAlpha * 0.6)
      ..strokeWidth = arm.width * 0.4;
    canvas.drawPath(_armPath, _armCorePaint);
  }

  void _drawStars(Canvas canvas, double progress) {
    if (progress < 0.1) return;

    final starAlpha = progress < 0.2
        ? (progress - 0.1) / 0.1
        : progress < 0.85
            ? 1.0
            : 1.0 - (progress - 0.85) / 0.15;

    if (starAlpha <= 0) return;

    for (final star in _stars) {
      if (star.armIndex >= _spiralArms.length) continue;

      final arm = _spiralArms[star.armIndex];

      // Calculate position along the arm
      final theta = arm.currentAngle + star.positionT * math.pi * 2 * arm.spiralTightness;
      final r = star.positionT * arm.length;

      // Add scatter perpendicular to arm
      final perpAngle = theta + math.pi / 2;
      final x = math.cos(theta) * r + math.cos(perpAngle) * star.scatter;
      final y = math.sin(theta) * r + math.sin(perpAngle) * star.scatter;

      // Twinkle effect
      final twinkle = 0.5 + 0.5 * math.sin(_time * star.twinkleSpeed + star.twinklePhase);
      final brightness = star.brightness * twinkle * starAlpha;

      if (brightness < 0.1) continue;

      // Star glow
      final starColor = star.isPink ? _starPink : _starWhite;
      _starGlowPaint
        ..color = starColor.withOpacity(brightness * 0.4)
        ..maskFilter = _blur(star.size * 2);
      canvas.drawCircle(Offset(x, y), star.size * 1.5, _starGlowPaint);

      // Star core
      _starCorePaint.color = _coreWhite.withOpacity(brightness * 0.8);
      canvas.drawCircle(Offset(x, y), star.size * 0.6, _starCorePaint);
    }
  }

  void _drawDustLanes(Canvas canvas, double progress) {
    if (progress < 0.1 || progress > 0.9) return;

    final dustAlpha = progress < 0.2
        ? (progress - 0.1) / 0.1
        : progress < 0.8
            ? 1.0
            : 1.0 - (progress - 0.8) / 0.1;

    if (dustAlpha <= 0) return;

    for (final dust in _dustLanes) {
      final angle = dust.baseAngle + _coreRotation * 0.5;

      // Draw dust as a dark region between arms
      _reusablePath.reset();

      final startR = galaxySize * 0.15;
      final endR = dust.length;
      final halfWidth = dust.width / 2;

      // Create a curved dust lane shape
      final segments = 10;
      final List<Offset> outerPoints = [];
      final List<Offset> innerPoints = [];

      for (int i = 0; i <= segments; i++) {
        final t = i / segments;
        final r = startR + (endR - startR) * t;
        final curveAngle = angle + t * 0.3; // Slight curve

        final perpAngle = curveAngle + math.pi / 2;
        final centerX = math.cos(curveAngle) * r;
        final centerY = math.sin(curveAngle) * r;

        outerPoints.add(Offset(
          centerX + math.cos(perpAngle) * halfWidth,
          centerY + math.sin(perpAngle) * halfWidth,
        ));
        innerPoints.add(Offset(
          centerX - math.cos(perpAngle) * halfWidth,
          centerY - math.sin(perpAngle) * halfWidth,
        ));
      }

      _reusablePath.moveTo(outerPoints.first.dx, outerPoints.first.dy);
      for (final p in outerPoints.skip(1)) {
        _reusablePath.lineTo(p.dx, p.dy);
      }
      for (final p in innerPoints.reversed) {
        _reusablePath.lineTo(p.dx, p.dy);
      }
      _reusablePath.close();

      _dustPaint.color = _dustPurple.withOpacity(dust.opacity * dustAlpha);
      canvas.drawPath(_reusablePath, _dustPaint);
    }
  }

  void _drawHalo(Canvas canvas, double progress) {
    if (_haloAlpha <= 0 || _haloRadius <= 0) return;

    // Outer diffuse glow
    _haloGlowPaint.color = _haloPurple.withOpacity(_haloAlpha * 0.2);
    canvas.drawCircle(Offset.zero, _haloRadius * 1.2, _haloGlowPaint);

    // Outer ring
    _haloOuterPaint.color = _haloBlue.withOpacity(_haloAlpha * 0.3);
    canvas.drawCircle(Offset.zero, _haloRadius, _haloOuterPaint);

    // Inner ring
    _haloInnerPaint.color = _armPurple.withOpacity(_haloAlpha * 0.4);
    canvas.drawCircle(Offset.zero, _haloRadius * 0.9, _haloInnerPaint);

    // Pulsing halo segments
    final segmentCount = 8;
    for (int i = 0; i < segmentCount; i++) {
      final angle = (i / segmentCount) * math.pi * 2 + _time * 0.5;
      final pulse = 0.7 + 0.3 * math.sin(_time * 3 + i * 0.5);

      final startAngle = angle - 0.15;
      final sweepAngle = 0.3;

      _haloOuterPaint.color = _coreBlue.withOpacity(_haloAlpha * 0.3 * pulse);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: _haloRadius),
        startAngle,
        sweepAngle,
        false,
        _haloOuterPaint,
      );
    }
  }

  void _drawAbsorptionEffect(Canvas canvas, double progress) {
    // Absorption is most visible between 0.5 and 0.9
    if (progress < 0.4 || progress > 0.95) return;

    final absorptionProgress = progress < 0.5
        ? (progress - 0.4) / 0.1
        : progress < 0.85
            ? 1.0
            : 1.0 - (progress - 0.85) / 0.1;

    if (absorptionProgress <= 0) return;

    for (final particle in _absorptionParticles) {
      if (!particle.isActive(_time)) continue;

      final currentDist = particle.currentDistance;
      if (currentDist <= 0) continue;

      final x = math.cos(particle.angle) * currentDist;
      final y = math.sin(particle.angle) * currentDist;

      final alpha = absorptionProgress * (currentDist / particle.initialDistance).clamp(0.0, 1.0);
      if (alpha < 0.05) continue;

      // Trail
      final trailDist = currentDist + particle.trailLength;
      final trailX = math.cos(particle.angle) * trailDist;
      final trailY = math.sin(particle.angle) * trailDist;

      _absorptionTrailPaint
        ..color = _absorptionCyan.withOpacity(alpha * 0.4)
        ..strokeWidth = particle.size;
      canvas.drawLine(Offset(trailX, trailY), Offset(x, y), _absorptionTrailPaint);

      // Particle core
      _absorptionParticlePaint.color = _coreWhite.withOpacity(alpha * 0.8);
      canvas.drawCircle(Offset(x, y), particle.size * 0.8, _absorptionParticlePaint);

      // Particle glow
      _absorptionParticlePaint.color = _absorptionCyan.withOpacity(alpha * 0.5);
      canvas.drawCircle(Offset(x, y), particle.size * 1.5, _absorptionParticlePaint);
    }
  }

  void _drawExpansionCollapse(Canvas canvas, double progress) {
    final collapseProgress = (progress - 0.85) / 0.15;

    // Expanding rings
    final ringCount = 3;
    for (int i = 0; i < ringCount; i++) {
      final ringProgress = (collapseProgress + i * 0.15).clamp(0.0, 1.0);
      final ringRadius = galaxySize * (0.5 + ringProgress * 2.0);
      final ringAlpha = (1 - ringProgress) * 0.6;

      if (ringAlpha < 0.05) continue;

      _expansionRingPaint.color = _armBlue.withOpacity(ringAlpha);
      canvas.drawCircle(Offset.zero, ringRadius, _expansionRingPaint);

      _expansionRingPaint.color = _armPurple.withOpacity(ringAlpha * 0.7);
      canvas.drawCircle(Offset.zero, ringRadius * 0.95, _expansionRingPaint);
    }

    // Final flash
    if (collapseProgress > 0.4 && collapseProgress < 0.7) {
      final flashProgress = (collapseProgress - 0.4) / 0.3;
      final flashAlpha = math.sin(flashProgress * math.pi) * 0.8;
      final flashRadius = galaxySize * (0.3 + flashProgress * 0.5);

      _collapseFlashPaint.color = _coreWhite.withOpacity(flashAlpha);
      canvas.drawCircle(Offset.zero, flashRadius, _collapseFlashPaint);

      _collapseFlashPaint.color = _coreBlue.withOpacity(flashAlpha * 0.6);
      canvas.drawCircle(Offset.zero, flashRadius * 1.5, _collapseFlashPaint);
    }

    // Energy discharge sparks
    if (collapseProgress > 0.3) {
      final sparkProgress = (collapseProgress - 0.3) / 0.7;
      final sparkCount = 12;

      for (int i = 0; i < sparkCount; i++) {
        final angle = (i / sparkCount) * math.pi * 2 + _time * 3;
        final dist = galaxySize * (0.2 + sparkProgress * 1.5);
        final x = math.cos(angle) * dist;
        final y = math.sin(angle) * dist;

        final sparkAlpha = (1 - sparkProgress) * 0.7;
        _starCorePaint.color = _coreWhite.withOpacity(sparkAlpha);
        canvas.drawCircle(Offset(x, y), 2, _starCorePaint);
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

// ═══════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class _SpiralArm {
  _SpiralArm({
    required this.baseAngle,
    required this.length,
    required this.width,
    required this.spiralTightness,
    required this.rotationSpeed,
    required this.segmentCount,
    required this.isPrimary,
  }) : currentAngle = baseAngle;

  final double baseAngle;
  final double length;
  final double width;
  final double spiralTightness;
  final double rotationSpeed;
  final int segmentCount;
  final bool isPrimary;

  double currentAngle;

  void update(double dt, double progress) {
    currentAngle = baseAngle + progress * rotationSpeed * math.pi * 2;
  }
}

class _StarParticle {
  _StarParticle({
    required this.armIndex,
    required this.positionT,
    required this.scatter,
    required this.size,
    required this.brightness,
    required this.twinkleSpeed,
    required this.twinklePhase,
    required this.isPink,
  });

  final int armIndex;
  final double positionT;
  final double scatter;
  final double size;
  final double brightness;
  final double twinkleSpeed;
  final double twinklePhase;
  final bool isPink;
}

class _DustLane {
  _DustLane({
    required this.baseAngle,
    required this.width,
    required this.length,
    required this.opacity,
  });

  final double baseAngle;
  final double width;
  final double length;
  final double opacity;
}

class _AbsorptionParticle {
  _AbsorptionParticle({
    required this.angle,
    required this.initialDistance,
    required this.speed,
    required this.size,
    required this.delay,
    required this.trailLength,
  }) : currentDistance = initialDistance;

  final double angle;
  final double initialDistance;
  final double speed;
  final double size;
  final double delay;
  final double trailLength;

  double currentDistance;

  bool isActive(double time) => time > delay;

  void update(double dt, double time, double progress) {
    if (!isActive(time)) return;

    // Accelerate toward center during absorption phase
    if (progress > 0.4 && progress < 0.95) {
      final absorptionStrength = progress < 0.5
          ? (progress - 0.4) / 0.1
          : progress < 0.85
              ? 1.0
              : (0.95 - progress) / 0.1;
      currentDistance -= speed * dt * absorptionStrength;
      if (currentDistance < 0) currentDistance = 0;
    }
  }
}
