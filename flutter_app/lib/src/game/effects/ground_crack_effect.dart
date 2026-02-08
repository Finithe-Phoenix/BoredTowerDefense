import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../entities/enemy.dart';

class _FastRng {
  int _state;

  _FastRng([int? seed]) : _state = (seed ?? 0x6d2b79f5) & 0x7fffffff;

  int _next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  double nextDouble() => _next() / 0x7fffffff;

  int nextInt(int max) => max <= 0 ? 0 : _next() % max;

  bool nextBool() => (_next() & 1) == 0;
}

/// Epic ground crack effect with shockwave for heavy impacts
/// Layers: crater, radial cracks, secondary branches, glowing energy,
/// debris particles, shockwave ring, ground displacement
class GroundCrackEffect extends PositionComponent {
  GroundCrackEffect._internal({
    required Vector2 position,
    required double impactSize,
    required double duration,
  }) : _random = _FastRng() {
    _reset(
      position: position,
      impactSize: impactSize,
      duration: duration,
    );
  }

  static const int maxPool = 16;
  static const int maxActive = 12;
  static final List<GroundCrackEffect> _pool = [];
  static int _activeCount = 0;
  static double fxScale = 1.0;
  static bool reduceFx = false;
  static bool lowFx = false;
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

  static GroundCrackEffect? spawn({
    required Vector2 position,
    double impactSize = 60.0,
    double duration = 1.5,
  }) {
    if (_activeCount >= maxActive) return null;
    GroundCrackEffect effect;
    if (_pool.isNotEmpty) {
      effect = _pool.removeLast();
      effect._reset(
        position: position,
        impactSize: impactSize,
        duration: duration,
      );
    } else {
      effect = GroundCrackEffect._internal(
        position: position,
        impactSize: impactSize,
        duration: duration,
      );
    }
    effect._markActive();
    return effect;
  }

  double impactSize = 60.0;
  double duration = 1.5;

  final List<_CrackLine> _primaryCracks = [];
  final List<_CrackLine> _secondaryCracks = [];
  final List<_DebrisParticle> _debris = [];
  final List<_EnergyPulse> _energyPulses = [];
  double _time = 0;
  final _FastRng _random;
  bool _counted = false;
  bool _inPool = false;
  double _offscreenAccumulator = 0;
  static const double _offscreenUpdateInterval = 0.12;

  // Shockwave properties
  double _shockwaveRadius = 0;
  double _shockwaveAlpha = 1.0;

  // Crater properties
  double _craterScale = 0;

  // Screen shake intensity (can be read by parent)
  double get shakeIntensity => _craterScale * 0.6;

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════

  // Layer 1: Central impact crater
  static final Paint _craterFillPaint = Paint()
    ..style = PaintingStyle.fill;
  static final Paint _craterGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _craterRimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  // Layer 2 & 3: Crack lines
  static final Paint _crackPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _crackGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  // Layer 4: Energy seeping through cracks
  static final Paint _energyGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _energyCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  // Layer 5: Debris particles
  static final Paint _debrisPaint = Paint();
  static final Paint _debrisGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _debrisTrailPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

  // Layer 6: Shockwave ring
  static final Paint _shockwaveOuterPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _shockwaveMainPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _shockwaveInnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  // Layer 7: Ground displacement distortion
  static final Paint _distortionPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _distortionArcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  // Reusable path for drawing
  final Path _reusablePath = Path();

  // Colors for the effect
  static const Color _craterColor = Color(0xFF1A0A0A);
  static const Color _crackColor = Color(0xFF2D1810);
  static const Color _energyColorOrange = Color(0xFFFF6B00);
  static const Color _energyColorRed = Color(0xFFFF2200);
  static const Color _rimColor = Color(0xFF4A2A1A);

  void _markActive() {
    if (_counted) return;
    _counted = true;
    _inPool = false;
    _activeCount++;
  }

  void _reset({
    required Vector2 position,
    required double impactSize,
    required double duration,
  }) {
    this.position.setFrom(position);
    anchor = Anchor.center;
    this.impactSize = impactSize;
    this.duration = duration;
    _time = 0;
    _shockwaveRadius = 0;
    _shockwaveAlpha = 1.0;
    _craterScale = 0;
    _primaryCracks.clear();
    _secondaryCracks.clear();
    _debris.clear();
    _energyPulses.clear();
    _initializeCracks();
    _initializeDebris();
    _initializeEnergyPulses();
  }

  void _initializeCracks() {
    // Primary radial cracks (6-10 main cracks)
    final primaryCount = _scaledCount(8, allowZero: false);
    for (int i = 0; i < primaryCount; i++) {
      final baseAngle = (i / primaryCount) * math.pi * 2;
      final angleVariation = (_random.nextDouble() - 0.5) * 0.4;
      final angle = baseAngle + angleVariation;
      final length = impactSize * (0.8 + _random.nextDouble() * 0.6);
      final width = 2.0 + _random.nextDouble() * 2.0;
      final segments = 3 + _random.nextInt(3);
      final spreadDelay = _random.nextDouble() * 0.15;

      _primaryCracks.add(_CrackLine(
        angle: angle,
        length: length,
        width: width,
        segments: segments,
        spreadDelay: spreadDelay,
        spreadDuration: 0.3 + _random.nextDouble() * 0.2,
        energyIntensity: 0.5 + _random.nextDouble() * 0.5,
      ));

      // Add secondary branches for each primary crack
      if (!reduceFx) {
        final branchCount = 1 + _random.nextInt(3);
        for (int j = 0; j < branchCount; j++) {
          final branchPoint = 0.3 + _random.nextDouble() * 0.5;
          final branchAngle = angle + (_random.nextDouble() - 0.5) * 1.2;
          final branchLength = length * (0.3 + _random.nextDouble() * 0.4);

          _secondaryCracks.add(_CrackLine(
            angle: branchAngle,
            length: branchLength,
            width: width * 0.6,
            segments: 2 + _random.nextInt(2),
            spreadDelay: spreadDelay + branchPoint * 0.2,
            spreadDuration: 0.2 + _random.nextDouble() * 0.15,
            energyIntensity: 0.3 + _random.nextDouble() * 0.4,
            branchPoint: branchPoint,
            parentAngle: angle,
            parentLength: length,
          ));
        }
      }
    }
  }

  void _initializeDebris() {
    if (lowFx) return;

    final debrisCount = _scaledCount(24, allowZero: true);
    for (int i = 0; i < debrisCount; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 30 + _random.nextDouble() * 80;
      final size = 1.5 + _random.nextDouble() * 3;
      final startDelay = _random.nextDouble() * 0.2;

      _debris.add(_DebrisParticle(
        angle: angle,
        speed: speed,
        size: size,
        lifetime: 0.6 + _random.nextDouble() * 0.6,
        startDelay: startDelay,
        gravity: 80 + _random.nextDouble() * 60,
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 15,
        isGlowing: _random.nextDouble() > 0.6,
      ));
    }
  }

  void _initializeEnergyPulses() {
    if (lowFx) return;

    final pulseCount = _scaledCount(6, allowZero: true);
    for (int i = 0; i < pulseCount; i++) {
      _energyPulses.add(_EnergyPulse(
        delay: i * 0.15,
        duration: 0.4 + _random.nextDouble() * 0.3,
        maxRadius: impactSize * (0.3 + _random.nextDouble() * 0.3),
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
    if (_isOffscreen()) {
      _offscreenAccumulator += dt;
      if (_offscreenAccumulator < _offscreenUpdateInterval) {
        return;
      }
      dt = _offscreenAccumulator;
      _offscreenAccumulator = 0;
    } else if (_offscreenAccumulator > 0) {
      dt += _offscreenAccumulator;
      _offscreenAccumulator = 0;
    }

    _time += dt;
    final progress = _time / duration;

    if (progress >= 1.0) {
      _recycle();
      return;
    }

    // Update crater scale (fast expand, then stable)
    if (progress < 0.15) {
      _craterScale = progress / 0.15;
    } else {
      _craterScale = 1.0;
    }

    // Update shockwave
    final shockwaveProgress = progress * 1.5; // Faster than overall duration
    if (shockwaveProgress < 1.0) {
      _shockwaveRadius = shockwaveProgress * impactSize * 2.5;
      _shockwaveAlpha = (1 - shockwaveProgress) * 0.9;
    } else {
      _shockwaveAlpha = 0;
    }

    // Update cracks
    if (_primaryCracks.isNotEmpty) {
      for (final crack in _primaryCracks) {
        crack.update(dt, _time);
      }
    }
    if (_secondaryCracks.isNotEmpty) {
      for (final crack in _secondaryCracks) {
        crack.update(dt, _time);
      }
    }

    // Update debris
    if (_debris.isNotEmpty) {
      for (final particle in _debris) {
        particle.update(dt, _time);
      }
    }

    // Update energy pulses
    if (_energyPulses.isNotEmpty) {
      for (final pulse in _energyPulses) {
        pulse.update(dt, _time);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_isOffscreen()) return;
    super.render(canvas);

    final progress = _time / duration;
    if (progress >= 1.0) return;
    if (_craterScale <= 0.01 &&
        _shockwaveAlpha <= 0.01 &&
        _primaryCracks.isEmpty &&
        _secondaryCracks.isEmpty &&
        _debris.isEmpty &&
        _energyPulses.isEmpty) {
      return;
    }

    // Layer 7: Ground displacement distortion (behind everything)
    if (!lowFx && progress <= 0.5) {
      _drawGroundDistortion(canvas, progress);
    }

    // Layer 6: Shockwave ring
    _drawShockwave(canvas);

    // Layer 1: Central impact crater
    _drawCrater(canvas, progress);

    // Layer 4: Energy seeping through cracks (beneath crack lines)
    if (!lowFx && _primaryCracks.isNotEmpty) {
      _drawCrackEnergy(canvas, progress);
    }

    // Layer 2 & 3: Crack lines (primary and secondary)
    if (_primaryCracks.isNotEmpty || _secondaryCracks.isNotEmpty) {
      _drawCracks(canvas, progress);
    }

    // Layer 5: Debris particles
    if (!lowFx && _debris.isNotEmpty) {
      _drawDebris(canvas);
    }

    // Draw energy pulses from crater
    if (!lowFx && _energyPulses.isNotEmpty) {
      _drawEnergyPulses(canvas);
    }
  }

  bool _isOffscreen({double padding = 100}) {
    if (Enemy.screenSize.isZero()) return false;
    if (Enemy.screenScale <= 0) return false;
    final screenX = Enemy.screenOffset.x + position.x * Enemy.screenScale;
    final screenY = Enemy.screenOffset.y + position.y * Enemy.screenScale;
    return screenX < -padding ||
        screenY < -padding ||
        screenX > Enemy.screenSize.x + padding ||
        screenY > Enemy.screenSize.y + padding;
  }

  void _drawCrater(Canvas canvas, double progress) {
    if (_craterScale <= 0) return;

    final craterRadius = impactSize * 0.3 * _craterScale;
    final fadeAlpha = progress < 0.8 ? 1.0 : (1 - (progress - 0.8) / 0.2);

    // Dark crater fill
    _craterFillPaint.color = _craterColor.withOpacity(0.9 * fadeAlpha);
    canvas.drawCircle(Offset.zero, craterRadius, _craterFillPaint);

    // Inner dark gradient simulation
    _craterFillPaint.color = const Color(0xFF0A0404).withOpacity(0.7 * fadeAlpha);
    canvas.drawCircle(Offset.zero, craterRadius * 0.6, _craterFillPaint);

    // Glowing rim (orange/red energy)
    final rimGlowIntensity = 0.5 + math.sin(_time * 8) * 0.2;
    _craterGlowPaint.color = _energyColorOrange.withOpacity(0.6 * fadeAlpha * rimGlowIntensity);
    canvas.drawCircle(Offset.zero, craterRadius, _craterGlowPaint);

    // Bright rim edge
    _craterRimPaint.color = _energyColorRed.withOpacity(0.8 * fadeAlpha * rimGlowIntensity);
    canvas.drawCircle(Offset.zero, craterRadius * 1.05, _craterRimPaint);

    // Inner core glow
    _energyCorePaint.color = _energyColorOrange.withOpacity(0.4 * fadeAlpha * rimGlowIntensity);
    canvas.drawCircle(Offset.zero, craterRadius * 0.4, _energyCorePaint);
  }

  void _drawCracks(Canvas canvas, double progress) {
    final fadeAlpha = progress < 0.7 ? 1.0 : (1 - (progress - 0.7) / 0.3);
    if (fadeAlpha <= 0.01) return;

    // Draw primary cracks
    for (final crack in _primaryCracks) {
      if (crack.currentProgress <= 0) continue;
      _drawSingleCrack(canvas, crack, fadeAlpha, isPrimary: true);
    }

    // Draw secondary cracks
    if (!reduceFx) {
      for (final crack in _secondaryCracks) {
        if (crack.currentProgress <= 0) continue;
        _drawSingleCrack(canvas, crack, fadeAlpha, isPrimary: false);
      }
    }
  }

  void _drawSingleCrack(Canvas canvas, _CrackLine crack, double fadeAlpha, {required bool isPrimary}) {
    final alpha = fadeAlpha * crack.currentProgress;

    // Calculate start point (for secondary cracks, start from branch point on parent)
    double startX = 0;
    double startY = 0;
    if (crack.branchPoint != null && crack.parentAngle != null && crack.parentLength != null) {
      startX = crack.parentDirX * crack.parentLength! * crack.branchPoint!;
      startY = crack.parentDirY * crack.parentLength! * crack.branchPoint!;
    }

    final endX = startX + crack.dirX * crack.length * crack.currentProgress;
    final endY = startY + crack.dirY * crack.length * crack.currentProgress;

    // Build jagged crack path
    _reusablePath.reset();
    _reusablePath.moveTo(startX, startY);

    final segmentCount = crack.segments;
    for (int i = 1; i <= segmentCount; i++) {
      final t = i / segmentCount;
      final baseX = startX + (endX - startX) * t;
      final baseY = startY + (endY - startY) * t;

      // Add jagged offset perpendicular to crack direction
      final jitter = i == segmentCount ? 0 : (_random.nextDouble() - 0.5) * 6 * crack.width;
      final perpX = crack.perpX * jitter;
      final perpY = crack.perpY * jitter;

      _reusablePath.lineTo(baseX + perpX, baseY + perpY);
    }

    // Draw glow underneath
    _crackGlowPaint
      ..color = _energyColorOrange.withOpacity(alpha * 0.4 * crack.energyIntensity)
      ..strokeWidth = crack.width * 3;
    canvas.drawPath(_reusablePath, _crackGlowPaint);

    // Draw dark crack line
    _crackPaint
      ..color = _crackColor.withOpacity(alpha * 0.9)
      ..strokeWidth = crack.width;
    canvas.drawPath(_reusablePath, _crackPaint);

    // Draw bright edge highlight
    _crackPaint
      ..color = _rimColor.withOpacity(alpha * 0.6)
      ..strokeWidth = crack.width * 0.4;
    canvas.drawPath(_reusablePath, _crackPaint);
  }

  void _drawCrackEnergy(Canvas canvas, double progress) {
    final energyAlpha = progress < 0.6
        ? 1.0
        : math.max(0, 1 - (progress - 0.6) / 0.4);

    if (energyAlpha <= 0) return;
    if (_primaryCracks.isEmpty) return;

    // Pulsating energy intensity
    final pulseIntensity = 0.6 + math.sin(_time * 12) * 0.4;

    // Draw energy glow along each crack
    for (final crack in _primaryCracks) {
      if (crack.currentProgress <= 0) continue;

      final endX = crack.dirX * crack.length * crack.currentProgress;
      final endY = crack.dirY * crack.length * crack.currentProgress;

      // Draw energy spots along crack
      final spotCount = (crack.segments * crack.currentProgress).ceil();
      for (int i = 0; i <= spotCount; i++) {
        final t = i / crack.segments;
        final spotX = endX * t;
        final spotY = endY * t;
        final spotSize = 3 + math.sin(_time * 10 + i * 2) * 2;

        // Outer orange glow
        _energyGlowPaint.color = _energyColorOrange.withOpacity(
          energyAlpha * 0.3 * pulseIntensity * crack.energyIntensity
        );
        canvas.drawCircle(Offset(spotX, spotY), spotSize * 2, _energyGlowPaint);

        // Inner red core
        _energyCorePaint.color = _energyColorRed.withOpacity(
          energyAlpha * 0.5 * pulseIntensity * crack.energyIntensity
        );
        canvas.drawCircle(Offset(spotX, spotY), spotSize, _energyCorePaint);
      }
    }
  }

  void _drawDebris(Canvas canvas) {
    if (_debris.isEmpty) return;
    for (final particle in _debris) {
      if (!particle.isActive) continue;

      final x = particle.dirX * particle.distance;
      final y = particle.dirY * particle.distance + particle.fallOffset;
      final alpha = particle.alphaValue;

      // Draw trail for glowing particles
      if (particle.isGlowing && particle.prevX != 0) {
        _debrisTrailPaint
          ..color = _energyColorOrange.withOpacity(alpha * 0.4)
          ..strokeWidth = particle.size * 0.8;
        canvas.drawLine(
          Offset(particle.prevX, particle.prevY),
          Offset(x, y),
          _debrisTrailPaint,
        );
      }

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.currentRotation);

      // Draw debris particle
      if (particle.isGlowing) {
        // Glowing ember
        _debrisGlowPaint.color = _energyColorOrange.withOpacity(alpha * 0.6);
        canvas.drawCircle(Offset.zero, particle.size * 1.5, _debrisGlowPaint);

        _debrisPaint.color = _energyColorRed.withOpacity(alpha * 0.9);
        canvas.drawCircle(Offset.zero, particle.size, _debrisPaint);

        _debrisPaint.color = Colors.white.withOpacity(alpha * 0.7);
        canvas.drawCircle(Offset.zero, particle.size * 0.4, _debrisPaint);
      } else {
        // Dark debris chunk
        _debrisPaint.color = _crackColor.withOpacity(alpha * 0.8);
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.7,
        );
        canvas.drawRect(rect, _debrisPaint);
      }

      canvas.restore();
    }
  }

  void _drawEnergyPulses(Canvas canvas) {
    if (_energyPulses.isEmpty) return;
    for (final pulse in _energyPulses) {
      if (!pulse.isActive) continue;

      final alpha = pulse.alphaValue;
      final radius = pulse.currentRadius;

      // Outer glow
      _energyGlowPaint.color = _energyColorOrange.withOpacity(alpha * 0.3);
      canvas.drawCircle(Offset.zero, radius, _energyGlowPaint);

      // Inner bright ring
      _craterRimPaint.color = _energyColorRed.withOpacity(alpha * 0.6);
      canvas.drawCircle(Offset.zero, radius * 0.8, _craterRimPaint);
    }
  }

  void _drawShockwave(Canvas canvas) {
    if (_shockwaveAlpha <= 0.05) return;
    if (_shockwaveRadius <= 0) return;

    // Outer glow ring
    _shockwaveOuterPaint.color = _energyColorOrange.withOpacity(_shockwaveAlpha * 0.3);
    canvas.drawCircle(Offset.zero, _shockwaveRadius, _shockwaveOuterPaint);

    // Main shockwave ring
    _shockwaveMainPaint.color = _energyColorRed.withOpacity(_shockwaveAlpha * 0.7);
    canvas.drawCircle(Offset.zero, _shockwaveRadius, _shockwaveMainPaint);

    // Inner bright edge
    _shockwaveInnerPaint.color = Colors.white.withOpacity(_shockwaveAlpha * 0.5);
    canvas.drawCircle(Offset.zero, _shockwaveRadius * 0.95, _shockwaveInnerPaint);

    // Secondary inner shockwave (slightly delayed)
    if (_time > 0.05) {
      final innerRadius = _shockwaveRadius * 0.6;
      final innerAlpha = _shockwaveAlpha * 0.5;

      _shockwaveMainPaint.color = _energyColorOrange.withOpacity(innerAlpha * 0.5);
      canvas.drawCircle(Offset.zero, innerRadius, _shockwaveMainPaint);
    }
  }

  void _drawGroundDistortion(Canvas canvas, double progress) {
    if (progress > 0.5) return;

    final distortionAlpha = (1 - progress / 0.5) * 0.4;
    final distortionRadius = impactSize * (0.8 + progress * 0.5);

    // Draw concentric distortion rings
    for (int i = 0; i < 4; i++) {
      final ringRadius = distortionRadius * (0.4 + i * 0.2);
      final ringAlpha = distortionAlpha * (1 - i * 0.2);
      final wobble = math.sin(_time * 15 + i * 2) * 2;

      _distortionPaint.color = Colors.white.withOpacity(ringAlpha * 0.3);

      // Draw slightly irregular ring
      _reusablePath.reset();
      for (int j = 0; j <= 16; j++) {
        final angle = (j / 16) * math.pi * 2;
        final radiusOffset = math.sin(angle * 4 + _time * 8) * wobble;
        final px = math.cos(angle) * (ringRadius + radiusOffset);
        final py = math.sin(angle) * (ringRadius + radiusOffset);

        if (j == 0) {
          _reusablePath.moveTo(px, py);
        } else {
          _reusablePath.lineTo(px, py);
        }
      }
      _reusablePath.close();
      canvas.drawPath(_reusablePath, _distortionPaint);
    }

    // Draw displacement arcs
    final arcCount = 6;
    for (int i = 0; i < arcCount; i++) {
      final arcAngle = (i / arcCount) * math.pi * 2 + _time * 2;
      final arcRadius = distortionRadius * (0.5 + progress * 0.3);
      final arcAlpha = distortionAlpha * 0.5;

      final startAngle = arcAngle - 0.3;
      final sweepAngle = 0.6;

      _distortionArcPaint.color = _energyColorOrange.withOpacity(arcAlpha * 0.3);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: arcRadius),
        startAngle,
        sweepAngle,
        false,
        _distortionArcPaint,
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

/// Represents a single crack line spreading from impact
class _CrackLine {
  _CrackLine({
    required this.angle,
    required this.length,
    required this.width,
    required this.segments,
    required this.spreadDelay,
    required this.spreadDuration,
    required this.energyIntensity,
    this.branchPoint,
    this.parentAngle,
    this.parentLength,
  }) : dirX = math.cos(angle),
       dirY = math.sin(angle),
       perpX = -math.sin(angle),
       perpY = math.cos(angle),
       parentDirX = parentAngle == null ? 0.0 : math.cos(parentAngle),
       parentDirY = parentAngle == null ? 0.0 : math.sin(parentAngle),
       currentProgress = 0;

  final double angle;
  final double length;
  final double width;
  final int segments;
  final double spreadDelay;
  final double spreadDuration;
  final double energyIntensity;
  final double dirX;
  final double dirY;
  final double perpX;
  final double perpY;
  final double parentDirX;
  final double parentDirY;

  // For secondary cracks branching off primary
  final double? branchPoint;
  final double? parentAngle;
  final double? parentLength;

  double currentProgress;

  void update(double dt, double totalTime) {
    if (totalTime < spreadDelay) {
      currentProgress = 0;
      return;
    }

    final activeTime = totalTime - spreadDelay;
    currentProgress = (activeTime / spreadDuration).clamp(0.0, 1.0);
  }
}

/// Debris particle rising from cracks
class _DebrisParticle {
  _DebrisParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.lifetime,
    required this.startDelay,
    required this.gravity,
    required this.rotation,
    required this.rotationSpeed,
    required this.isGlowing,
  }) : dirX = math.cos(angle),
       dirY = math.sin(angle),
       _time = 0,
       distance = 0,
       fallOffset = 0,
       currentRotation = rotation,
       _velocityY = -speed * 0.5,
       _prevX = 0,
       _prevY = 0;

  final double angle;
  final double dirX;
  final double dirY;
  final double speed;
  final double size;
  final double lifetime;
  final double startDelay;
  final double gravity;
  final double rotation;
  final double rotationSpeed;
  final bool isGlowing;

  double _time;
  double distance;
  double fallOffset;
  double currentRotation;
  double _velocityY;
  double _prevX;
  double _prevY;

  bool get isActive => _time > startDelay && _time < lifetime + startDelay;

  double get alphaValue {
    if (_time <= startDelay) return 0;
    final activeTime = _time - startDelay;
    return (1 - activeTime / lifetime).clamp(0.0, 1.0);
  }

  double get prevX => _prevX;
  double get prevY => _prevY;

  void update(double dt, double totalTime) {
    _time = totalTime;

    if (!isActive) return;

    // Store previous position for trail
    _prevX = dirX * distance;
    _prevY = dirY * distance + fallOffset;

    final activeTime = totalTime - startDelay;
    final decay = 1 - activeTime / lifetime * 0.3;
    distance += speed * dt * decay * 0.3;
    currentRotation += rotationSpeed * dt;

    // Rising then falling with gravity
    _velocityY += gravity * dt;
    fallOffset += _velocityY * dt;
  }
}

/// Energy pulse emanating from crater
class _EnergyPulse {
  _EnergyPulse({
    required this.delay,
    required this.duration,
    required this.maxRadius,
  }) : _time = 0,
       currentRadius = 0;

  final double delay;
  final double duration;
  final double maxRadius;

  double _time;
  double currentRadius;

  bool get isActive => _time > delay && _time < delay + duration;

  double get alphaValue {
    if (_time <= delay) return 0;
    final activeTime = _time - delay;
    final progress = activeTime / duration;
    // Fade in then out
    if (progress < 0.3) {
      return progress / 0.3;
    }
    return 1 - (progress - 0.3) / 0.7;
  }

  void update(double dt, double totalTime) {
    _time = totalTime;

    if (!isActive) return;

    final activeTime = totalTime - delay;
    final progress = activeTime / duration;
    currentRadius = maxRadius * progress;
  }
}

