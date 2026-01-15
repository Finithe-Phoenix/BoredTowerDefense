import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Epic boss entrance effect with screen shake, particles, and dramatic visuals
class BossEntranceEffect extends PositionComponent {
  BossEntranceEffect({
    required Vector2 bossPosition,
    required Color bossColor,
  }) : _bossPosition = bossPosition,
       _bossColor = bossColor,
       _duration = 2.5 {
    position = bossPosition.clone();
    priority = 50;
  }

  final Vector2 _bossPosition;
  final Color _bossColor;
  final double _duration;
  double _elapsed = 0;

  final List<_EntranceParticle> _particles = [];
  static const int _particleCount = 60;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize particles in a circular pattern
    for (int i = 0; i < _particleCount; i++) {
      final angle = (i / _particleCount) * math.pi * 2;
      final speed = 200 + math.Random().nextDouble() * 150;
      _particles.add(_EntranceParticle(
        angle: angle,
        speed: speed,
        color: _bossColor,
        size: 4 + math.Random().nextDouble() * 6,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _elapsed += dt;

    // Update particles
    for (final particle in _particles) {
      particle.update(dt);
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

    // Outer glow
    final glowPaint = Paint()
      ..color = _bossColor.withOpacity(alpha * 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(Offset.zero, radius, glowPaint);

    // Shockwave ring
    final ringPaint = Paint()
      ..color = _bossColor.withOpacity(alpha * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * (1 - progress * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(Offset.zero, radius, ringPaint);

    // Inner bright ring
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(alpha * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset.zero, radius, innerPaint);
  }

  void _renderParticles(Canvas canvas) {
    for (final particle in _particles) {
      if (!particle.isActive) continue;

      final px = math.cos(particle.angle) * particle.distance;
      final py = math.sin(particle.angle) * particle.distance;

      // Particle trail
      final trailPaint = Paint()
        ..color = particle.color.withOpacity(particle.alpha * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(
        Offset(px, py),
        particle.size * 1.5,
        trailPaint,
      );

      // Particle core
      final corePaint = Paint()
        ..color = particle.color.withOpacity(particle.alpha);

      canvas.drawCircle(
        Offset(px, py),
        particle.size,
        corePaint,
      );
    }
  }

  void _renderWarningRings(Canvas canvas, double progress) {
    final ringCount = 3;
    for (int i = 0; i < ringCount; i++) {
      final ringProgress = (progress + i * 0.2).clamp(0.0, 1.0);
      final radius = 80 + (ringProgress * 200);
      final alpha = (1 - ringProgress) * 0.5;

      // Warning ring (hexagonal)
      final path = Path();
      const sides = 6;
      for (int j = 0; j < sides; j++) {
        final angle = (j / sides) * math.pi * 2 - math.pi / 2;
        final x = math.cos(angle) * radius;
        final y = math.sin(angle) * radius;

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      final hexPaint = Paint()
        ..color = const Color(0xFFFF0066).withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawPath(path, hexPaint);
    }
  }

  void _renderLightning(Canvas canvas, double progress) {
    final random = math.Random(42); // Fixed seed for consistent pattern
    final boltCount = 8;

    for (int i = 0; i < boltCount; i++) {
      final angle = (i / boltCount) * math.pi * 2;
      final distance = 100 + progress * 200;

      // Generate lightning bolt path
      final startX = math.cos(angle) * 30;
      final startY = math.sin(angle) * 30;
      final endX = math.cos(angle) * distance;
      final endY = math.sin(angle) * distance;

      final boltPath = Path();
      boltPath.moveTo(startX, startY);

      // Add zigzag segments
      final segments = 6;
      for (int j = 1; j <= segments; j++) {
        final t = j / segments;
        final x = startX + (endX - startX) * t;
        final y = startY + (endY - startY) * t;

        // Random offset perpendicular to bolt direction
        final perpAngle = angle + math.pi / 2;
        final offset = (random.nextDouble() - 0.5) * 30;
        final offsetX = math.cos(perpAngle) * offset;
        final offsetY = math.sin(perpAngle) * offset;

        boltPath.lineTo(x + offsetX, y + offsetY);
      }

      // Render lightning
      final alpha = (1 - progress) * 0.6;
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(alpha * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawPath(boltPath, glowPaint);

      final corePaint = Paint()
        ..color = Colors.white.withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(boltPath, corePaint);
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
  }) : distance = 0,
       _timer = 0,
       lifetime = 1.0 + math.Random().nextDouble() * 0.8;

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
