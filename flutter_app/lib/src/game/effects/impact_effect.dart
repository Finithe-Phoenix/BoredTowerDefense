import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../entities/tower.dart';

/// Visual effect spawned when a projectile hits an enemy
class ImpactEffect extends PositionComponent {
  ImpactEffect._internal({
    required Vector2 position,
    required Color color,
    required TowerType towerType,
    required double duration,
  }) : _random = math.Random() {
    _reset(
      position: position,
      color: color,
      towerType: towerType,
      duration: duration,
    );
  }

  static const int maxPool = 60;
  static const int maxActive = 80;
  static final List<ImpactEffect> _pool = [];
  static int _activeCount = 0;
  static double fxScale = 1.0;

  static ImpactEffect? spawn({
    required Vector2 position,
    required Color color,
    required TowerType towerType,
    double duration = 0.3,
  }) {
    if (_activeCount >= maxActive) return null;
    ImpactEffect effect;
    if (_pool.isNotEmpty) {
      effect = _pool.removeLast();
      effect._reset(
        position: position,
        color: color,
        towerType: towerType,
        duration: duration,
      );
    } else {
      effect = ImpactEffect._internal(
        position: position,
        color: color,
        towerType: towerType,
        duration: duration,
      );
    }
    effect._markActive();
    return effect;
  }

  Color color = Colors.white;
  TowerType towerType = TowerType.pulseArcher;
  double duration = 0.3;
  final math.Random _random;

  double _timer = 0;
  bool _counted = false;
  bool _inPool = false;
  final List<_ImpactParticle> _particles = [];
  final List<_ImpactRing> _rings = [];
  final List<_Spark> _sparks = [];

  void _markActive() {
    if (_counted) return;
    _counted = true;
    _inPool = false;
    _activeCount++;
  }

  void _reset({
    required Vector2 position,
    required Color color,
    required TowerType towerType,
    required double duration,
  }) {
    this.position = position.clone();
    anchor = Anchor.center;
    this.color = color;
    this.towerType = towerType;
    this.duration = duration;
    _timer = 0;
    _particles.clear();
    _rings.clear();
    _sparks.clear();
    _initializeParticles();
  }

  void _initializeParticles() {
    switch (towerType) {
      case TowerType.pulseArcher:
        // Fast, directional sparks
        final sparkCount = _scaledCount(8, allowZero: true);
        for (int i = 0; i < sparkCount; i++) {
          _sparks.add(_Spark(
            angle: _random.nextDouble() * math.pi * 2,
            speed: 80 + _random.nextDouble() * 60,
            length: 8 + _random.nextDouble() * 6,
            lifetime: 0.15 + _random.nextDouble() * 0.1,
          ));
        }
        if (fxScale > 0.2) {
          _rings.add(_ImpactRing(
            startRadius: 5,
            endRadius: 25,
            duration: 0.2,
          ));
        }
        break;

      case TowerType.circuitCannon:
        // Heavy explosion with multiple rings
        final ringCount = _scaledCount(3);
        for (int i = 0; i < ringCount; i++) {
          _rings.add(_ImpactRing(
            startRadius: 5 + i * 5,
            endRadius: 40 + i * 10,
            duration: 0.25 + i * 0.05,
          ));
        }
        // Large debris particles
        final particleCount = _scaledCount(12, allowZero: true);
        for (int i = 0; i < particleCount; i++) {
          _particles.add(_ImpactParticle(
            angle: _random.nextDouble() * math.pi * 2,
            speed: 40 + _random.nextDouble() * 80,
            size: 3 + _random.nextDouble() * 4,
            lifetime: 0.3 + _random.nextDouble() * 0.2,
            rotationSpeed: (_random.nextDouble() - 0.5) * 10,
          ));
        }
        break;

      case TowerType.phaseMage:
        // Mystical burst with arcane symbols
        final runeCount = _scaledCount(6, allowZero: true);
        for (int i = 0; i < runeCount; i++) {
          _particles.add(_ImpactParticle(
            angle: i * math.pi / 3,
            speed: 30 + _random.nextDouble() * 20,
            size: 4,
            lifetime: 0.4,
            rotationSpeed: 5,
            isRune: true,
          ));
        }
        // Electric discharge
        final sparkCount = _scaledCount(5, allowZero: true);
        for (int i = 0; i < sparkCount; i++) {
          _sparks.add(_Spark(
            angle: _random.nextDouble() * math.pi * 2,
            speed: 60 + _random.nextDouble() * 40,
            length: 12 + _random.nextDouble() * 8,
            lifetime: 0.2,
            isElectric: true,
          ));
        }
        if (fxScale > 0.2) {
          _rings.add(_ImpactRing(
            startRadius: 8,
            endRadius: 30,
            duration: 0.3,
          ));
        }
        break;

      case TowerType.glimmerField:
        // Sparkle burst
        final sparkleCount = _scaledCount(16, allowZero: true);
        for (int i = 0; i < sparkleCount; i++) {
          _particles.add(_ImpactParticle(
            angle: _random.nextDouble() * math.pi * 2,
            speed: 50 + _random.nextDouble() * 50,
            size: 1.5 + _random.nextDouble() * 2,
            lifetime: 0.2 + _random.nextDouble() * 0.15,
            rotationSpeed: (_random.nextDouble() - 0.5) * 15,
            isStar: true,
          ));
        }
        // Quick flash ring
        if (fxScale > 0.2) {
          _rings.add(_ImpactRing(
            startRadius: 3,
            endRadius: 20,
            duration: 0.15,
          ));
        }
        break;
      case TowerType.ionSniper:
      case TowerType.teslaTerminal:
      case TowerType.resonanceSiphon:
      case TowerType.neuralDisruptor:
        // Default spark burst
        final sparkCount = _scaledCount(10, allowZero: true);
        for (int i = 0; i < sparkCount; i++) {
          _sparks.add(_Spark(
            angle: _random.nextDouble() * math.pi * 2,
            speed: 100 + _random.nextDouble() * 50,
            length: 10 + _random.nextDouble() * 5,
            lifetime: 0.2,
          ));
        }
        break;
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
    _timer += dt;

    // Update particles
    for (final particle in _particles) {
      particle.update(dt);
    }

    // Update sparks
    for (final spark in _sparks) {
      spark.update(dt);
    }

    // Update rings
    for (final ring in _rings) {
      ring.update(dt);
    }

    // Remove when done
    if (_timer >= duration) {
      _recycle();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = (_timer / duration).clamp(0.0, 1.0);
    final fadeOut = 1.0 - progress;

    // Draw rings
    for (final ring in _rings) {
      if (!ring.isActive) continue;

      final ringProgress = ring.progress;
      final radius = ring.currentRadius;
      final alpha = (1 - ringProgress) * fadeOut;

      // Ring glow
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()
          ..color = color.withOpacity(alpha * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Ring core
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()
          ..color = color.withOpacity(alpha * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Draw particles
    for (final particle in _particles) {
      if (!particle.isActive) continue;

      final px = math.cos(particle.angle) * particle.distance;
      final py = math.sin(particle.angle) * particle.distance;
      final alpha = particle.alpha * fadeOut;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(particle.rotation);

      if (particle.isRune) {
        // Draw diamond rune
        final runePath = Path()
          ..moveTo(0, -particle.size)
          ..lineTo(particle.size * 0.7, 0)
          ..lineTo(0, particle.size)
          ..lineTo(-particle.size * 0.7, 0)
          ..close();

        canvas.drawPath(
          runePath,
          Paint()
            ..color = color.withOpacity(alpha * 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawPath(
          runePath,
          Paint()..color = color.withOpacity(alpha),
        );
      } else if (particle.isStar) {
        // Draw star
        _drawStar(canvas, Offset.zero, particle.size, color.withOpacity(alpha));
      } else {
        // Draw circle particle
        canvas.drawCircle(
          Offset.zero,
          particle.size,
          Paint()
            ..color = color.withOpacity(alpha * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawCircle(
          Offset.zero,
          particle.size * 0.6,
          Paint()..color = color.withOpacity(alpha),
        );
      }

      canvas.restore();
    }

    // Draw sparks
    for (final spark in _sparks) {
      if (!spark.isActive) continue;

      final alpha = spark.alpha * fadeOut;
      final startX = math.cos(spark.angle) * spark.distance;
      final startY = math.sin(spark.angle) * spark.distance;
      final endX = math.cos(spark.angle) * (spark.distance + spark.length);
      final endY = math.sin(spark.angle) * (spark.distance + spark.length);

      if (spark.isElectric) {
        // Draw zigzag electric spark
        final arcPath = Path();
        arcPath.moveTo(startX, startY);

        final steps = 3;
        for (int i = 1; i <= steps; i++) {
          final progress = i / steps;
          final baseX = startX + (endX - startX) * progress;
          final baseY = startY + (endY - startY) * progress;

          final perpAngle = spark.angle + math.pi / 2;
          final jitter = math.sin(_timer * 30 + i * 2) * 3;
          final jitterX = math.cos(perpAngle) * jitter;
          final jitterY = math.sin(perpAngle) * jitter;

          arcPath.lineTo(baseX + jitterX, baseY + jitterY);
        }

        canvas.drawPath(
          arcPath,
          Paint()
            ..color = color.withOpacity(alpha)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      } else {
        // Draw straight spark
        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          Paint()
            ..color = color.withOpacity(alpha * 0.4)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          Paint()
            ..color = color.withOpacity(alpha)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Central flash removed to reduce hit strobing.
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color starColor) {
    final starPath = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + _timer * 5;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
      // Inner point
      final innerAngle = angle + math.pi / 4;
      final innerX = center.dx + math.cos(innerAngle) * radius * 0.4;
      final innerY = center.dy + math.sin(innerAngle) * radius * 0.4;
      starPath.lineTo(innerX, innerY);
    }
    starPath.close();

    canvas.drawPath(
      starPath,
      Paint()
        ..color = starColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
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

class _ImpactParticle {
  _ImpactParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.lifetime,
    this.rotationSpeed = 0,
    this.isRune = false,
    this.isStar = false,
  }) : distance = 0,
       rotation = 0,
       _timer = 0;

  final double angle;
  final double speed;
  final double size;
  final double lifetime;
  final double rotationSpeed;
  final bool isRune;
  final bool isStar;

  double distance;
  double rotation;
  double _timer;

  bool get isActive => _timer < lifetime;
  double get alpha => (1 - _timer / lifetime).clamp(0.0, 1.0);

  void update(double dt) {
    _timer += dt;
    distance += speed * dt * (1 - _timer / lifetime); // Slow down over time
    rotation += rotationSpeed * dt;
  }
}

class _Spark {
  _Spark({
    required this.angle,
    required this.speed,
    required this.length,
    required this.lifetime,
    this.isElectric = false,
  }) : distance = 0,
       _timer = 0;

  final double angle;
  final double speed;
  final double length;
  final double lifetime;
  final bool isElectric;

  double distance;
  double _timer;

  bool get isActive => _timer < lifetime;
  double get alpha => (1 - _timer / lifetime).clamp(0.0, 1.0);

  void update(double dt) {
    _timer += dt;
    distance += speed * dt;
  }
}

class _ImpactRing {
  _ImpactRing({
    required this.startRadius,
    required this.endRadius,
    required this.duration,
  }) : _timer = 0;

  final double startRadius;
  final double endRadius;
  final double duration;

  double _timer;

  bool get isActive => _timer < duration;
  double get progress => (_timer / duration).clamp(0.0, 1.0);
  double get currentRadius => startRadius + (endRadius - startRadius) * progress;

  void update(double dt) {
    _timer += dt;
  }
}
