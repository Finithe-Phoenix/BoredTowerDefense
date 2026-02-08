import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

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

/// Epic boss entrance effect with screen shake, particles, and dramatic visuals
class BossEntranceEffect extends PositionComponent {
  BossEntranceEffect({
    required Vector2 bossPosition,
    required Color bossColor,
  }) : _bossPosition = bossPosition,
       _bossColor = bossColor,
       _duration = 2.5 {
    position.setFrom(bossPosition);
    priority = 50;
  }

  final Vector2 _bossPosition;
  final Color _bossColor;
  final double _duration;
  double _elapsed = 0;

  final List<_EntranceParticle> _particles = [];
  static const int _particleCount = 60;

  static final Paint _shockGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  static final Paint _shockRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _shockInnerPaint = Paint()
    ..style = PaintingStyle.stroke;
  static final Paint _particleTrailPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _particleCorePaint = Paint();
  static final Paint _hexRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _lightningGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _lightningCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Path _hexPath = Path();
  static final Path _boltPath = Path();
  static final List<Offset> _hexUnitPoints = _buildHexUnitPoints();

  static List<Offset> _buildHexUnitPoints() {
    final points = <Offset>[];
    const sides = 6;
    for (int i = 0; i < sides; i++) {
      final angle = (i / sides) * math.pi * 2 - math.pi / 2;
      points.add(Offset(math.cos(angle), math.sin(angle)));
    }
    return points;
  }

  static int _lcgNext(int state) => (state * 1664525 + 1013904223) & 0x7fffffff;
  static double _lcgUnit(int state) => state / 0x7fffffff;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize particles in a circular pattern
    final rng = _FastRng();
    for (int i = 0; i < _particleCount; i++) {
      final angle = (i / _particleCount) * math.pi * 2;
      final speed = 200 + rng.nextDouble() * 150;
      _particles.add(_EntranceParticle(
        angle: angle,
        speed: speed,
        color: _bossColor,
        size: 4 + rng.nextDouble() * 6,
        lifetime: 1.0 + rng.nextDouble() * 0.8,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _elapsed += dt;

    // Update particles (only when any could still be active)
    if (_elapsed < _duration * 0.8) {
      for (final particle in _particles) {
        particle.update(dt);
      }
    }

    // Remove effect when done
    if (_elapsed >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = (_elapsed / _duration).clamp(0.0, 1.0);
    if (progress >= 1.0) return;

    // Phase 1: Expanding shockwave (0 - 0.4)
    if (progress < 0.4) {
      _renderShockwave(canvas, progress / 0.4);
    }

    // Phase 2: Particles bursting out (0.2 - 0.8)
    if (progress >= 0.2 && progress < 0.8) {
      _renderParticles(canvas);
    }

    // Phase 3: Warning rings (0.5 - 1.0)
    if (progress >= 0.5) {
      _renderWarningRings(canvas, (progress - 0.5) / 0.5);
    }

    // Lightning bolts throughout
    if (progress < 0.7) {
      _renderLightning(canvas, progress);
    }
  }

  void _renderShockwave(Canvas canvas, double progress) {
    final radius = 50 + (progress * 400);
    final alpha = (1 - progress);
    if (alpha <= 0.01) return;

    // Outer glow
    _shockGlowPaint.color = _bossColor.withOpacity(alpha * 0.4);
    canvas.drawCircle(Offset.zero, radius, _shockGlowPaint);

    // Shockwave ring
    _shockRingPaint
      ..color = _bossColor.withOpacity(alpha * 0.7)
      ..strokeWidth = 6 * (1 - progress * 0.5);
    canvas.drawCircle(Offset.zero, radius, _shockRingPaint);

    // Inner bright ring
    _shockInnerPaint
      ..color = Colors.white.withOpacity(alpha * 0.8)
      ..strokeWidth = 3;
    canvas.drawCircle(Offset.zero, radius, _shockInnerPaint);
  }

  void _renderParticles(Canvas canvas) {
    for (final particle in _particles) {
      if (!particle.isActive) continue;
      if (particle.alpha <= 0.01) continue;

      final px = math.cos(particle.angle) * particle.distance;
      final py = math.sin(particle.angle) * particle.distance;

      // Particle trail
      _particleTrailPaint.color =
          particle.color.withOpacity(particle.alpha * 0.4);
      canvas.drawCircle(
        Offset(px, py),
        particle.size * 1.5,
        _particleTrailPaint,
      );

      // Particle core
      _particleCorePaint.color = particle.color.withOpacity(particle.alpha);
      canvas.drawCircle(
        Offset(px, py),
        particle.size,
        _particleCorePaint,
      );
    }
  }

  void _renderWarningRings(Canvas canvas, double progress) {
    final ringCount = 3;
    for (int i = 0; i < ringCount; i++) {
      final ringProgress = (progress + i * 0.2).clamp(0.0, 1.0);
      final radius = 80 + (ringProgress * 200);
      final alpha = (1 - ringProgress) * 0.5;
      if (alpha <= 0.02) continue;

      // Warning ring (hexagonal)
      final path = _hexPath..reset();
      for (int j = 0; j < _hexUnitPoints.length; j++) {
        final p = _hexUnitPoints[j];
        final x = p.dx * radius;
        final y = p.dy * radius;
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      _hexRingPaint.color = const Color(0xFFFF0066).withOpacity(alpha);
      canvas.drawPath(path, _hexRingPaint);
    }
  }

  void _renderLightning(Canvas canvas, double progress) {
    final boltCount = 8;

    for (int i = 0; i < boltCount; i++) {
      final angle = (i / boltCount) * math.pi * 2;
      final distance = 100 + progress * 200;

      // Generate lightning bolt path
      final startX = math.cos(angle) * 30;
      final startY = math.sin(angle) * 30;
      final endX = math.cos(angle) * distance;
      final endY = math.sin(angle) * distance;

      final boltPath = _boltPath..reset();
      boltPath.moveTo(startX, startY);

      // Add zigzag segments
      final segments = 6;
      int state = ((progress * 100000).toInt() ^ (i * 1315423911)) & 0x7fffffff;
      for (int j = 1; j <= segments; j++) {
        final t = j / segments;
        final x = startX + (endX - startX) * t;
        final y = startY + (endY - startY) * t;

        // Random offset perpendicular to bolt direction
        final perpAngle = angle + math.pi / 2;
        state = _lcgNext(state);
        final offset = (_lcgUnit(state) - 0.5) * 30;
        final offsetX = math.cos(perpAngle) * offset;
        final offsetY = math.sin(perpAngle) * offset;

        boltPath.lineTo(x + offsetX, y + offsetY);
      }

      // Render lightning
      final alpha = (1 - progress) * 0.6;
      if (alpha <= 0.02) continue;
      _lightningGlowPaint.color = Colors.white.withOpacity(alpha * 0.5);
      canvas.drawPath(boltPath, _lightningGlowPaint);

      _lightningCorePaint.color = Colors.white.withOpacity(alpha);
      canvas.drawPath(boltPath, _lightningCorePaint);
    }
  }

  /// Get screen shake intensity for this effect
  double getShakeIntensity() {
    if (_elapsed >= _duration) return 0.0;

    final progress = (_elapsed / _duration).clamp(0.0, 1.0);

    // Strong shake at start, fading out
    if (progress < 0.3) {
      return 8.0 * (1 - progress / 0.3);
    } else if (progress < 0.6) {
      return 4.0 * (1 - (progress - 0.3) / 0.3);
    }

    return 0.0;
  }
}

class _EntranceParticle {
  _EntranceParticle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.lifetime,
  }) : distance = 0,
       _timer = 0;

  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double lifetime;

  double distance;
  double _timer;

  bool get isActive => _timer < lifetime;
  double get progress => (_timer / lifetime).clamp(0.0, 1.0);
  double get alpha => (1 - progress).clamp(0.0, 1.0);

  void update(double dt) {
    _timer += dt;

    // Particles slow down over time
    final speedMultiplier = 1 - (progress * 0.7);
    distance += speed * dt * speedMultiplier;
  }
}

