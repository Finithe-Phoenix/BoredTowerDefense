import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../services/sprite_cache_service.dart';
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

  static const int maxPool = 30;
  static const int maxActive = 40;
  static final List<ImpactEffect> _pool = [];
  static int _activeCount = 0;
  static double fxScale = 1.0;
  static int get activeCount => _activeCount;

  /// Use cached sprites when active count is high for better performance
  static bool get _useCachedSprites => _activeCount > 20;

  /// Clear the static pool to prevent memory accumulation between games
  static void clearPool() {
    _pool.clear();
    _activeCount = 0;
  }

  // Cached Paint objects to avoid per-frame allocations
  final Paint _ringGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  final Paint _ringCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _particleGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  final Paint _particleCorePaint = Paint();
  final Paint _sparkGlowPaint = Paint()
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  final Paint _sparkCorePaint = Paint()
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  final Paint _electricPaint = Paint()
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  final Paint _starPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  final Paint _spritePaint = Paint();
  final Path _reusablePath = Path();

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

    // Use cached sprites under high stress for better performance
    if (_useCachedSprites) {
      _renderCachedSprite(canvas, fadeOut);
      return;
    }

    // Draw rings (using cached paints)
    for (final ring in _rings) {
      if (!ring.isActive) continue;

      final ringProgress = ring.progress;
      final radius = ring.currentRadius;
      final alpha = (1 - ringProgress) * fadeOut;

      // Ring glow
      _ringGlowPaint.color = color.withOpacity(alpha * 0.3);
      canvas.drawCircle(Offset.zero, radius, _ringGlowPaint);

      // Ring core
      _ringCorePaint.color = color.withOpacity(alpha * 0.6);
      canvas.drawCircle(Offset.zero, radius, _ringCorePaint);
    }

    // Draw particles (using cached paints and reusable path)
    for (final particle in _particles) {
      if (!particle.isActive) continue;

      final px = math.cos(particle.angle) * particle.distance;
      final py = math.sin(particle.angle) * particle.distance;
      final alpha = particle.alpha * fadeOut;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(particle.rotation);

      if (particle.isRune) {
        // Draw diamond rune using reusable path
        _reusablePath.reset();
        _reusablePath.moveTo(0, -particle.size);
        _reusablePath.lineTo(particle.size * 0.7, 0);
        _reusablePath.lineTo(0, particle.size);
        _reusablePath.lineTo(-particle.size * 0.7, 0);
        _reusablePath.close();

        _particleGlowPaint.color = color.withOpacity(alpha * 0.5);
        canvas.drawPath(_reusablePath, _particleGlowPaint);
        _particleCorePaint.color = color.withOpacity(alpha);
        canvas.drawPath(_reusablePath, _particleCorePaint);
      } else if (particle.isStar) {
        // Draw star
        _drawStar(canvas, Offset.zero, particle.size, color.withOpacity(alpha));
      } else {
        // Draw circle particle
        _particleGlowPaint.color = color.withOpacity(alpha * 0.4);
        canvas.drawCircle(Offset.zero, particle.size, _particleGlowPaint);
        _particleCorePaint.color = color.withOpacity(alpha);
        canvas.drawCircle(Offset.zero, particle.size * 0.6, _particleCorePaint);
      }

      canvas.restore();
    }

    // Draw sparks (using cached paints)
    for (final spark in _sparks) {
      if (!spark.isActive) continue;

      final alpha = spark.alpha * fadeOut;
      final startX = math.cos(spark.angle) * spark.distance;
      final startY = math.sin(spark.angle) * spark.distance;
      final endX = math.cos(spark.angle) * (spark.distance + spark.length);
      final endY = math.sin(spark.angle) * (spark.distance + spark.length);

      if (spark.isElectric) {
        // Draw zigzag electric spark using reusable path
        _reusablePath.reset();
        _reusablePath.moveTo(startX, startY);

        const steps = 3;
        for (int i = 1; i <= steps; i++) {
          final stepProgress = i / steps;
          final baseX = startX + (endX - startX) * stepProgress;
          final baseY = startY + (endY - startY) * stepProgress;

          final perpAngle = spark.angle + math.pi / 2;
          final jitter = math.sin(_timer * 30 + i * 2) * 3;
          final jitterX = math.cos(perpAngle) * jitter;
          final jitterY = math.sin(perpAngle) * jitter;

          _reusablePath.lineTo(baseX + jitterX, baseY + jitterY);
        }

        _electricPaint.color = color.withOpacity(alpha);
        canvas.drawPath(_reusablePath, _electricPaint);
      } else {
        // Draw straight spark
        _sparkGlowPaint.color = color.withOpacity(alpha * 0.4);
        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          _sparkGlowPaint,
        );
        _sparkCorePaint.color = color.withOpacity(alpha);
        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          _sparkCorePaint,
        );
      }
    }

    // Central flash removed to reduce hit strobing.
  }

  /// Renders using pre-cached sprites for high-performance mode
  void _renderCachedSprite(Canvas canvas, double fadeOut) {
    final spriteCache = SpriteCacheService.instance;

    // Try to get cached impact sprite
    final impactSprite = spriteCache.getImpactSprite(color);
    if (impactSprite != null) {
      final scale = 0.5 + fadeOut * 0.5; // Shrink as it fades
      _spritePaint.color = Color.fromRGBO(255, 255, 255, fadeOut);

      canvas.save();
      canvas.scale(scale, scale);
      canvas.drawImage(
        impactSprite,
        Offset(-impactSprite.width / 2, -impactSprite.height / 2),
        _spritePaint,
      );
      canvas.restore();
    }

    // Try to get cached ring sprite for expanding ring effect
    if (_rings.isNotEmpty) {
      final ringSprite = spriteCache.getImpactRingSprite(color);
      if (ringSprite != null) {
        for (final ring in _rings) {
          if (!ring.isActive) continue;

          final ringScale = ring.currentRadius / 20; // Scale based on ring size
          final ringAlpha = (1 - ring.progress) * fadeOut;
          _spritePaint.color = Color.fromRGBO(255, 255, 255, ringAlpha);

          canvas.save();
          canvas.scale(ringScale, ringScale);
          canvas.drawImage(
            ringSprite,
            Offset(-ringSprite.width / 2, -ringSprite.height / 2),
            _spritePaint,
          );
          canvas.restore();
        }
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color starColor) {
    _reusablePath.reset();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + _timer * 5;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      if (i == 0) {
        _reusablePath.moveTo(x, y);
      } else {
        _reusablePath.lineTo(x, y);
      }
      // Inner point
      final innerAngle = angle + math.pi / 4;
      final innerX = center.dx + math.cos(innerAngle) * radius * 0.4;
      final innerY = center.dy + math.sin(innerAngle) * radius * 0.4;
      _reusablePath.lineTo(innerX, innerY);
    }
    _reusablePath.close();

    _starPaint.color = starColor;
    canvas.drawPath(_reusablePath, _starPaint);
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
