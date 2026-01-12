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
  }) : _phase = _PulsePhase.expanding,
       _timer = 0,
       _currentRadius = 0,
       _random = math.Random() {
    position = center;
    anchor = Anchor.center;
    _initializeParticles();
  }

  final double radius;
  final double slowFactor;
  final double slowDuration;
  final List<Enemy> Function() enemies;
  final double expandDuration;
  final double holdDuration;
  final math.Random _random;

  _PulsePhase _phase;
  double _timer;
  double _currentRadius;
  final Set<Enemy> _affectedEnemies = {};

  // Particle burst system
  final List<_PulseParticle> _particles = [];
  static const int _particleCount = 40;

  // Electric arc system
  final List<_ElectricArc> _arcs = [];
  static const int _arcCount = 8;

  void _initializeParticles() {
    // Burst particles
    for (int i = 0; i < _particleCount; i++) {
      final angle = (i / _particleCount) * math.pi * 2 + _random.nextDouble() * 0.2;
      _particles.add(_PulseParticle(
        angle: angle,
        speed: 150 + _random.nextDouble() * 100,
        size: 2 + _random.nextDouble() * 3,
        lifetime: 0.4 + _random.nextDouble() * 0.3,
        orbitRadius: _random.nextDouble() * 20,
        orbitSpeed: (_random.nextDouble() - 0.5) * 10,
      ));
    }

    // Electric arcs to affected enemies
    for (int i = 0; i < _arcCount; i++) {
      _arcs.add(_ElectricArc(
        angle: (i / _arcCount) * math.pi * 2,
        segments: 4 + _random.nextInt(4),
        lifetime: 0.1 + _random.nextDouble() * 0.15,
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
    if (_phase == _PulsePhase.expanding || _phase == _PulsePhase.holding) {
      for (final arc in _arcs) {
        arc.update(dt);
        if (!arc.isAlive) {
          arc.reset(_random);
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
    for (final enemy in enemies()) {
      final distance = (enemy.position - position).length;
      if (distance <= _currentRadius && !_affectedEnemies.contains(enemy)) {
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
    _drawElectricArcs(canvas, opacity);

    // Draw inner ring (leading edge)
    _drawInnerRing(canvas, opacity);

    // Draw outer ring (main pulse)
    _drawOuterRing(canvas, opacity);

    // Draw double-wave effect
    _drawDoubleWave(canvas, opacity);

    // Draw center origin effect
    _drawCenterOrigin(canvas, opacity);

    // Draw energy field fill
    _drawEnergyField(canvas, opacity);
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

      // Particle glow
      canvas.drawCircle(
        Offset(x, y),
        size * 2,
        Paint()
          ..color = NeonColors.cyan.withOpacity(alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Particle core
      canvas.drawCircle(
        Offset(x, y),
        size,
        Paint()..color = NeonColors.cyan.withOpacity(alpha * 0.8),
      );
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
        final perpX = -math.sin(arc.angle) * (i == arc.segments ? 0 : (_random.nextDouble() - 0.5) * 15);
        final perpY = math.cos(arc.angle) * (i == arc.segments ? 0 : (_random.nextDouble() - 0.5) * 15);

        arcPath.lineTo(baseX + perpX, baseY + perpY);
      }

      final arcAlpha = arc.alphaValue * opacity;

      // Arc glow
      canvas.drawPath(
        arcPath,
        Paint()
          ..color = NeonColors.cyan.withOpacity(arcAlpha * 0.5)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Arc core
      canvas.drawPath(
        arcPath,
        Paint()
          ..color = Colors.white.withOpacity(arcAlpha * 0.8)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawInnerRing(Canvas canvas, double opacity) {
    final innerRadius = _currentRadius * 0.85;

    // Inner ring glow
    canvas.drawCircle(
      Offset.zero,
      innerRadius,
      Paint()
        ..color = NeonColors.cyan.withOpacity(0.15 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Inner ring line
    canvas.drawCircle(
      Offset.zero,
      innerRadius,
      Paint()
        ..color = NeonColors.cyan.withOpacity(0.4 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawOuterRing(Canvas canvas, double opacity) {
    // Outer ring glow (intense)
    canvas.drawCircle(
      Offset.zero,
      _currentRadius,
      Paint()
        ..color = NeonColors.cyan.withOpacity(0.4 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Outer ring main
    canvas.drawCircle(
      Offset.zero,
      _currentRadius,
      Paint()
        ..color = NeonColors.cyan.withOpacity(0.7 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Outer ring bright edge
    canvas.drawCircle(
      Offset.zero,
      _currentRadius,
      Paint()
        ..color = Colors.white.withOpacity(0.5 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawDoubleWave(Canvas canvas, double opacity) {
    // Second wave (delayed, slightly different color)
    final secondWaveProgress = ((_timer - 0.1) / expandDuration).clamp(0.0, 1.0);
    final secondWaveRadius = secondWaveProgress * radius * 0.9;

    if (secondWaveProgress > 0 && _phase != _PulsePhase.fading) {
      // Second wave glow
      canvas.drawCircle(
        Offset.zero,
        secondWaveRadius,
        Paint()
          ..color = NeonColors.magenta.withOpacity(0.2 * opacity * (1 - secondWaveProgress))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Second wave line
      canvas.drawCircle(
        Offset.zero,
        secondWaveRadius,
        Paint()
          ..color = NeonColors.magenta.withOpacity(0.4 * opacity * (1 - secondWaveProgress))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawCenterOrigin(Canvas canvas, double opacity) {
    final centerIntensity = _phase == _PulsePhase.expanding
        ? (1 - _timer / expandDuration)
        : (_phase == _PulsePhase.holding ? 0.3 : 0.0);

    if (centerIntensity <= 0) return;

    // Bright flash at origin
    canvas.drawCircle(
      Offset.zero,
      15 * centerIntensity,
      Paint()
        ..color = Colors.white.withOpacity(0.9 * centerIntensity * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Colored glow
    canvas.drawCircle(
      Offset.zero,
      25 * centerIntensity,
      Paint()
        ..color = NeonColors.cyan.withOpacity(0.5 * centerIntensity * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );

    // Pulsing ring at origin
    final pulseScale = 1 + math.sin(_timer * 20) * 0.2;
    canvas.drawCircle(
      Offset.zero,
      10 * pulseScale * centerIntensity,
      Paint()
        ..color = NeonColors.cyan.withOpacity(0.8 * centerIntensity * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawEnergyField(Canvas canvas, double opacity) {
    // Subtle radial gradient fill
    final gradient = RadialGradient(
      colors: [
        NeonColors.cyan.withOpacity(0.08 * opacity),
        NeonColors.cyan.withOpacity(0.03 * opacity),
        Colors.transparent,
      ],
      stops: const [0.0, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: _currentRadius));

    canvas.drawCircle(
      Offset.zero,
      _currentRadius,
      Paint()..shader = gradient,
    );

    // Animated energy lines
    if (_phase != _PulsePhase.fading) {
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
          Paint()
            ..color = NeonColors.cyan.withOpacity(0.15 * opacity)
            ..strokeWidth = 1
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
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

  void reset(math.Random random) {
    _time = 0;
    angle = random.nextDouble() * math.pi * 2;
    segments = 4 + random.nextInt(4);
    lifetime = 0.1 + random.nextDouble() * 0.15;
  }
}
