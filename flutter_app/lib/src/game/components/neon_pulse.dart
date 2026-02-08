import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, RadialGradient;

import '../entities/enemy.dart';
import '../../ui/theme/neon_theme.dart';

class NeonPulse extends PositionComponent {
  NeonPulse({
    required Vector2 center,
    required this.radius,
    required this.slowFactor,
    required this.slowDuration,
    required this.enemies,
    this.expandDuration = 0.3,
    this.holdDuration = 0.5,
    this.reducedFx = false,
  }) : _phase = _PulsePhase.expanding,
       _timer = 0,
       _currentRadius = 0,
       _particleCount = reducedFx ? 18 : 40,
       _arcCount = reducedFx ? 4 : 8 {
    position = center;
    anchor = Anchor.center;
    _rngState = (center.hashCode ^ 0x6d2b79f5) & 0x7fffffff;
    _initializeParticles();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _empHexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _linePaint = Paint()
    ..strokeWidth = 1
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _noisePaint = Paint();
  static final Paint _redPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..blendMode = BlendMode.plus
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _cyanPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..blendMode = BlendMode.plus
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _dataPaint = Paint()
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  static final Paint _particleGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _particleCorePaint = Paint();
  static final Paint _arcPaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _ringGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _ringCorePaint = Paint()
    ..style = PaintingStyle.stroke;
  static final Paint _fillPaint = Paint();
  static final Path _hexPath = Path();

  // Additional cached paints for render methods - avoid per-frame allocations
  static final Paint _innerRingGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _innerRingLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _outerRingGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 12
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _outerRingMainPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _outerRingEdgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _secondWaveGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _secondWaveLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _centerFlashPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _centerGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _centerPulsePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _energyLinePaint = Paint()
    ..strokeWidth = 1
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _arcGlowPaint = Paint()
    ..strokeWidth = 3
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _arcCorePaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;

  final double radius;
  final double slowFactor;
  final double slowDuration;
  final List<Enemy> Function() enemies;
  final double expandDuration;
  final double holdDuration;
  final bool reducedFx;
  int _rngState = 0x6d2b79f5;
  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }
  double _nextUnit() => _lcgNext() / 0x7fffffff;
  int _nextInt(int max) => max <= 0 ? 0 : _lcgNext() % max;
  bool _nextBool() => (_lcgNext() & 1) == 0;

  _PulsePhase _phase;
  double _timer;
  double _currentRadius;
  final Set<Enemy> _affectedEnemies = {};

  // Particle burst system
  final List<_PulseParticle> _particles = [];
  final int _particleCount;

  // Electric arc system
  final List<_ElectricArc> _arcs = [];
  final int _arcCount;

  void _initializeParticles() {
    // Burst particles
    for (int i = 0; i < _particleCount; i++) {
      final angle = (i / _particleCount) * math.pi * 2 + _nextUnit() * 0.2;
      _particles.add(_PulseParticle(
        angle: angle,
        speed: 150 + _nextUnit() * 100,
        size: 2 + _nextUnit() * 3,
        lifetime: 0.4 + _nextUnit() * 0.3,
        orbitRadius: _nextUnit() * 20,
        orbitSpeed: (_nextUnit() - 0.5) * 10,
      ));
    }

    // Electric arcs to affected enemies
    for (int i = 0; i < _arcCount; i++) {
      _arcs.add(_ElectricArc(
        angle: (i / _arcCount) * math.pi * 2,
        segments: 4 + _nextInt(4),
        lifetime: 0.1 + _nextUnit() * 0.15,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    // Update particles
    for (final particle in _particles) {
      particle.update(dt);
    }

    // Regenerate arcs periodically
    if (!reducedFx &&
        (_phase == _PulsePhase.expanding || _phase == _PulsePhase.holding)) {
      for (final arc in _arcs) {
        arc.update(dt);
        if (!arc.isAlive) {
          arc.reset(_nextUnit, _nextInt);
        }
      }
    }

    switch (_phase) {
      case _PulsePhase.expanding:
        _currentRadius = ((_timer / expandDuration) * radius).clamp(0, radius);
        _applySlowToEnemiesInRange();
        if (_timer >= expandDuration) {
          _timer = 0;
          _phase = _PulsePhase.holding;
        }
        break;

      case _PulsePhase.holding:
        _currentRadius = radius;
        _applySlowToEnemiesInRange();
        if (_timer >= holdDuration) {
          _timer = 0;
          _phase = _PulsePhase.fading;
        }
        break;

      case _PulsePhase.fading:
        final fadeProgress = _timer / 0.3;
        if (fadeProgress >= 1.0) {
          removeFromParent();
        }
        break;
    }
  }

  void _applySlowToEnemiesInRange() {
    final radiusSq = _currentRadius * _currentRadius; // Pre-compute squared
    for (final enemy in enemies()) {
      // Use squared distance to avoid sqrt
      final distanceSq = (enemy.position - position).length2;
      if (distanceSq <= radiusSq && !_affectedEnemies.contains(enemy)) {
        enemy.applySlow(slowFactor, slowDuration);
        _affectedEnemies.add(enemy);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final opacity = _phase == _PulsePhase.fading
        ? (1.0 - _timer / 0.3).clamp(0.0, 1.0)
        : 1.0;

    // Draw particle burst
    _drawParticles(canvas, opacity);

    // Draw electric arcs to affected enemies
    if (!reducedFx) {
      _drawElectricArcs(canvas, opacity);
    }

    // Draw inner ring (leading edge)
    _drawInnerRing(canvas, opacity);

    // Draw outer ring (main pulse)
    _drawOuterRing(canvas, opacity);

    // Draw double-wave effect
    if (!reducedFx) {
      _drawDoubleWave(canvas, opacity);
    }

    // Draw center origin effect
    if (!reducedFx) {
      _drawCenterOrigin(canvas, opacity);
    }

    // Draw energy field fill
    if (!reducedFx) {
      _drawEnergyField(canvas, opacity);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EMP ENHANCEMENT EFFECTS
    // ═══════════════════════════════════════════════════════════════════════
    if (!reducedFx) {
      _drawEmpHexDisruption(canvas, opacity);
      _drawEmpInterferenceLines(canvas, opacity);
      _drawEmpStaticNoise(canvas, opacity);
      _drawEmpChromaticEdge(canvas, opacity);
      _drawEmpDataCorruption(canvas, opacity);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMP VISUAL EFFECT: HEXAGONAL GRID DISRUPTION
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawEmpHexDisruption(Canvas canvas, double opacity) {
    if (_phase == _PulsePhase.fading) return;

    const hexSize = 20.0;

    // Draw disrupted hexagons near the wave edge
    final waveEdge = _currentRadius;
    const distortionWidth = 40.0;

    for (double angle = 0; angle < math.pi * 2; angle += math.pi / 8) {
      for (double dist = waveEdge - distortionWidth; dist < waveEdge + distortionWidth * 0.5; dist += hexSize * 1.2) {
        if (dist < 0) continue;

        final distFromEdge = (dist - waveEdge).abs();
        final hexAlpha = (1 - distFromEdge / distortionWidth) * opacity * 0.6;
        if (hexAlpha < 0.05) continue;

        final cx = math.cos(angle) * dist;
        final cy = math.sin(angle) * dist;

        // Glitch offset
        final glitchX = (_nextUnit() - 0.5) * 4 * (1 - distFromEdge / distortionWidth);
        final glitchY = (_nextUnit() - 0.5) * 4 * (1 - distFromEdge / distortionWidth);

        _hexPath.reset();
        for (int i = 0; i < 6; i++) {
          final hexAngle = (i * 60 - 30) * math.pi / 180;
          final hx = cx + glitchX + math.cos(hexAngle) * hexSize * 0.5;
          final hy = cy + glitchY + math.sin(hexAngle) * hexSize * 0.5;
          if (i == 0) {
            _hexPath.moveTo(hx, hy);
          } else {
            _hexPath.lineTo(hx, hy);
          }
        }
        _hexPath.close();

        _empHexPaint.color = NeonColors.cyan.withOpacity(hexAlpha);
        canvas.drawPath(_hexPath, _empHexPaint);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMP VISUAL EFFECT: INTERFERENCE LINES
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawEmpInterferenceLines(Canvas canvas, double opacity) {
    if (_phase == _PulsePhase.fading) return;

    // Radial interference lines
    const lineCount = 24;
    for (int i = 0; i < lineCount; i++) {
      final angle = (i / lineCount) * math.pi * 2 + _timer * 3;
      final lineAlpha = (0.2 + math.sin(_timer * 10 + i * 0.5) * 0.15) * opacity;

      // Line with segments that flicker
      final innerR = _currentRadius * 0.6;
      final outerR = _currentRadius;

      for (double r = innerR; r < outerR; r += 8) {
        if (_nextUnit() > 0.7) continue;

        final x1 = math.cos(angle) * r;
        final y1 = math.sin(angle) * r;
        final x2 = math.cos(angle) * (r + 6);
        final y2 = math.sin(angle) * (r + 6);

        _linePaint.color = NeonColors.cyan.withOpacity(lineAlpha);
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), _linePaint);
      }
    }

    // Circular interference bands
    for (int i = 0; i < 3; i++) {
      final bandRadius = _currentRadius * (0.5 + i * 0.2);
      final bandAlpha = (0.15 + math.sin(_timer * 8 + i * 2) * 0.1) * opacity;

      _linePaint.color = NeonColors.cyan.withOpacity(bandAlpha);
      _linePaint.style = PaintingStyle.stroke;
      _linePaint.strokeWidth = 1;

      // Draw partial arc
      final arcStart = _timer * 5 + i;
      const arcSweep = math.pi * 0.5;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: bandRadius),
        arcStart,
        arcSweep,
        false,
        _linePaint,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMP VISUAL EFFECT: STATIC NOISE
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawEmpStaticNoise(Canvas canvas, double opacity) {
    if (_phase == _PulsePhase.fading && _timer > 0.15) return;

    final noiseIntensity = _phase == _PulsePhase.expanding
        ? 1.0
        : (_phase == _PulsePhase.holding ? 0.5 : (1 - _timer / 0.15));

    // Draw noise dots at the wave edge
    final noiseCount = (40 * noiseIntensity).toInt();
    for (int i = 0; i < noiseCount; i++) {
      final angle = _nextUnit() * math.pi * 2;
      final dist = _currentRadius * (0.85 + _nextUnit() * 0.3);

      final nx = math.cos(angle) * dist;
      final ny = math.sin(angle) * dist;

      final noiseAlpha = _nextUnit() * 0.6 * opacity * noiseIntensity;
      final noiseSize = 1 + _nextUnit() * 2;

      // Alternate between cyan and white
      final noiseColor = _nextBool() ? NeonColors.cyan : Colors.white;
      _noisePaint.color = noiseColor.withOpacity(noiseAlpha);

      canvas.drawCircle(Offset(nx, ny), noiseSize, _noisePaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMP VISUAL EFFECT: CHROMATIC ABERRATION AT EDGE
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawEmpChromaticEdge(Canvas canvas, double opacity) {
    if (_phase == _PulsePhase.fading) return;

    final chromaOffset = 3.0;

    // Red channel (shifted outward) - use cached paint
    _redPaint.color = Colors.red.withOpacity(0.25 * opacity);
    canvas.drawCircle(Offset.zero, _currentRadius + chromaOffset, _redPaint);

    // Blue/Cyan channel (shifted inward) - use cached paint
    _cyanPaint.color = NeonColors.cyan.withOpacity(0.25 * opacity);
    canvas.drawCircle(Offset.zero, _currentRadius - chromaOffset, _cyanPaint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMP VISUAL EFFECT: DATA CORRUPTION PATTERNS
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawEmpDataCorruption(Canvas canvas, double opacity) {
    if (_phase == _PulsePhase.fading) return;

    // Use cached data paint

    // Binary-style data bars at random positions within the pulse
    final barCount = 15;
    for (int i = 0; i < barCount; i++) {
      final angle = (i / barCount) * math.pi * 2 + _timer * 1.5;
      final dist = _currentRadius * (0.3 + _nextUnit() * 0.6);

      final cx = math.cos(angle) * dist;
      final cy = math.sin(angle) * dist;

      // Draw a short horizontal bar
      final barWidth = 8 + _nextUnit() * 12;
      final barAlpha = (0.3 + math.sin(_timer * 15 + i) * 0.2) * opacity;

      // Random color variation
      final barColor = i % 3 == 0 ? NeonColors.magenta : NeonColors.cyan;
      _dataPaint.color = barColor.withOpacity(barAlpha);

      canvas.drawLine(
        Offset(cx - barWidth / 2, cy),
        Offset(cx + barWidth / 2, cy),
        _dataPaint,
      );

      // Sometimes add a perpendicular tick
      if (_nextUnit() > 0.6) {
        final tickHeight = 4 + _nextUnit() * 6;
        canvas.drawLine(
          Offset(cx, cy - tickHeight / 2),
          Offset(cx, cy + tickHeight / 2),
          _dataPaint,
        );
      }
    }

    // Glitchy text-like patterns - use cached noise paint
    _noisePaint.color = NeonColors.cyan.withOpacity(0.4 * opacity);
    _noisePaint.strokeWidth = 1;

    for (int i = 0; i < 6; i++) {
      final gx = (_nextUnit() - 0.5) * _currentRadius * 1.5;
      final gy = (_nextUnit() - 0.5) * _currentRadius * 1.5;

      // Only draw if within radius
      if (gx * gx + gy * gy > _currentRadius * _currentRadius) continue;

      // Draw 3-4 short horizontal lines (simulating corrupted text)
      for (int j = 0; j < 3; j++) {
        final lineLen = 5 + _nextUnit() * 10;
        final ly = gy + j * 4;
        if (_nextUnit() > 0.3) {
          canvas.drawLine(
            Offset(gx, ly),
            Offset(gx + lineLen, ly),
            _noisePaint,
          );
        }
      }
    }
  }

  void _drawParticles(Canvas canvas, double opacity) {
    for (final particle in _particles) {
      if (!particle.isAlive) continue;

      final progress = particle.progress;
      final distance = particle.speed * progress * expandDuration;
      final orbitOffset = math.sin(progress * math.pi * 4 + particle.orbitRadius) * particle.orbitRadius;

      final x = math.cos(particle.angle) * (distance + orbitOffset);
      final y = math.sin(particle.angle) * (distance + orbitOffset);

      final alpha = (1 - progress) * opacity;
      final size = particle.size * (1 - progress * 0.5);

      // Particle glow - use cached paint
      _particleGlowPaint.color = NeonColors.cyan.withOpacity(alpha * 0.3);
      canvas.drawCircle(Offset(x, y), size * 2, _particleGlowPaint);

      // Particle core - use cached paint
      _particleCorePaint.color = NeonColors.cyan.withOpacity(alpha * 0.8);
      canvas.drawCircle(Offset(x, y), size, _particleCorePaint);
    }
  }

  void _drawElectricArcs(Canvas canvas, double opacity) {
    if (_phase == _PulsePhase.fading) return;

    for (final arc in _arcs) {
      if (!arc.isAlive) continue;

      final arcPath = Path();
      arcPath.moveTo(0, 0);

      final endX = math.cos(arc.angle) * _currentRadius;
      final endY = math.sin(arc.angle) * _currentRadius;

      // Create zigzag path
      for (int i = 1; i <= arc.segments; i++) {
        final t = i / arc.segments;
        final baseX = endX * t;
        final baseY = endY * t;

        // Add random perpendicular offset
        final perpX = -math.sin(arc.angle) * (i == arc.segments ? 0 : (_nextUnit() - 0.5) * 15);
        final perpY = math.cos(arc.angle) * (i == arc.segments ? 0 : (_nextUnit() - 0.5) * 15);

        arcPath.lineTo(baseX + perpX, baseY + perpY);
      }

      final arcAlpha = arc.alphaValue * opacity;

      // Arc glow - use cached paint
      _arcGlowPaint.color = NeonColors.cyan.withOpacity(arcAlpha * 0.5);
      canvas.drawPath(arcPath, _arcGlowPaint);

      // Arc core - use cached paint
      _arcCorePaint.color = Colors.white.withOpacity(arcAlpha * 0.8);
      canvas.drawPath(arcPath, _arcCorePaint);
    }
  }

  void _drawInnerRing(Canvas canvas, double opacity) {
    final innerRadius = _currentRadius * 0.85;

    // Inner ring glow - use cached paint
    _innerRingGlowPaint.color = NeonColors.cyan.withOpacity(0.15 * opacity);
    canvas.drawCircle(Offset.zero, innerRadius, _innerRingGlowPaint);

    // Inner ring line - use cached paint
    _innerRingLinePaint.color = NeonColors.cyan.withOpacity(0.4 * opacity);
    canvas.drawCircle(Offset.zero, innerRadius, _innerRingLinePaint);
  }

  void _drawOuterRing(Canvas canvas, double opacity) {
    // Outer ring glow (intense) - use cached paint
    _outerRingGlowPaint.color = NeonColors.cyan.withOpacity(0.4 * opacity);
    canvas.drawCircle(Offset.zero, _currentRadius, _outerRingGlowPaint);

    // Outer ring main - use cached paint
    _outerRingMainPaint.color = NeonColors.cyan.withOpacity(0.7 * opacity);
    canvas.drawCircle(Offset.zero, _currentRadius, _outerRingMainPaint);

    // Outer ring bright edge - use cached paint
    _outerRingEdgePaint.color = Colors.white.withOpacity(0.5 * opacity);
    canvas.drawCircle(Offset.zero, _currentRadius, _outerRingEdgePaint);
  }

  void _drawDoubleWave(Canvas canvas, double opacity) {
    // Second wave (delayed, slightly different color)
    final secondWaveProgress = ((_timer - 0.1) / expandDuration).clamp(0.0, 1.0);
    final secondWaveRadius = secondWaveProgress * radius * 0.9;

    if (secondWaveProgress > 0 && _phase != _PulsePhase.fading) {
      // Second wave glow - use cached paint
      _secondWaveGlowPaint.color = NeonColors.magenta.withOpacity(0.2 * opacity * (1 - secondWaveProgress));
      canvas.drawCircle(Offset.zero, secondWaveRadius, _secondWaveGlowPaint);

      // Second wave line - use cached paint
      _secondWaveLinePaint.color = NeonColors.magenta.withOpacity(0.4 * opacity * (1 - secondWaveProgress));
      canvas.drawCircle(Offset.zero, secondWaveRadius, _secondWaveLinePaint);
    }
  }

  void _drawCenterOrigin(Canvas canvas, double opacity) {
    final centerIntensity = _phase == _PulsePhase.expanding
        ? (1 - _timer / expandDuration)
        : (_phase == _PulsePhase.holding ? 0.3 : 0.0);

    if (centerIntensity <= 0) return;

    // Bright flash at origin - use cached paint
    _centerFlashPaint.color = Colors.white.withOpacity(0.9 * centerIntensity * opacity);
    canvas.drawCircle(Offset.zero, 15 * centerIntensity, _centerFlashPaint);

    // Colored glow - use cached paint
    _centerGlowPaint.color = NeonColors.cyan.withOpacity(0.5 * centerIntensity * opacity);
    canvas.drawCircle(Offset.zero, 25 * centerIntensity, _centerGlowPaint);

    // Pulsing ring at origin - use cached paint
    final pulseScale = 1 + math.sin(_timer * 20) * 0.2;
    _centerPulsePaint.color = NeonColors.cyan.withOpacity(0.8 * centerIntensity * opacity);
    canvas.drawCircle(Offset.zero, 10 * pulseScale * centerIntensity, _centerPulsePaint);
  }

  void _drawEnergyField(Canvas canvas, double opacity) {
    // Subtle radial gradient fill (shader must be dynamic due to _currentRadius)
    final gradient = RadialGradient(
      colors: [
        NeonColors.cyan.withOpacity(0.08 * opacity),
        NeonColors.cyan.withOpacity(0.03 * opacity),
        Colors.transparent,
      ],
      stops: const [0.0, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: _currentRadius));

    // Use cached fill paint for gradient
    _fillPaint.shader = gradient;
    canvas.drawCircle(Offset.zero, _currentRadius, _fillPaint);

    // Animated energy lines
    if (_phase != _PulsePhase.fading) {
      // Set energy line paint color once per frame
      _energyLinePaint.color = NeonColors.cyan.withOpacity(0.15 * opacity);

      const lineCount = 12;
      for (int i = 0; i < lineCount; i++) {
        final baseAngle = (i / lineCount) * math.pi * 2;
        final animAngle = baseAngle + _timer * 2;
        final lineLength = _currentRadius * (0.3 + math.sin(_timer * 5 + i) * 0.1);

        final startX = math.cos(animAngle) * (_currentRadius * 0.2);
        final startY = math.sin(animAngle) * (_currentRadius * 0.2);
        final endX = math.cos(animAngle) * lineLength;
        final endY = math.sin(animAngle) * lineLength;

        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          _energyLinePaint,
        );
      }
    }
  }
}

enum _PulsePhase { expanding, holding, fading }

class _PulseParticle {
  _PulseParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.lifetime,
    required this.orbitRadius,
    required this.orbitSpeed,
  }) : _time = 0;

  final double angle;
  final double speed;
  final double size;
  final double lifetime;
  final double orbitRadius;
  final double orbitSpeed;
  double _time;

  bool get isAlive => _time < lifetime;
  double get progress => _time / lifetime;

  void update(double dt) {
    _time += dt;
  }
}

class _ElectricArc {
  _ElectricArc({
    required this.angle,
    required this.segments,
    required this.lifetime,
  }) : _time = 0;

  double angle;
  int segments;
  double lifetime;
  double _time;

  bool get isAlive => _time < lifetime;
  double get alphaValue => isAlive ? (1 - _time / lifetime) : 0;

  void update(double dt) {
    _time += dt;
  }

  void reset(double Function() nextUnit, int Function(int) nextInt) {
    _time = 0;
    angle = nextUnit() * math.pi * 2;
    segments = 4 + nextInt(4);
    lifetime = 0.1 + nextUnit() * 0.15;
  }
}
