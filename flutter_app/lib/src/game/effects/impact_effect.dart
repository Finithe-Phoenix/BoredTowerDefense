import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../services/sprite_cache_service.dart';
import '../entities/enemy.dart';
import '../entities/tower.dart';

/// Visual effect spawned when a projectile hits an enemy
class ImpactEffect extends PositionComponent {
  ImpactEffect._internal({
    required Vector2 position,
    required Color color,
    required TowerType towerType,
    required double duration,
  }) : _rngState = 0x2a3b4c5d {
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
  static final Set<ImpactEffect> _live = <ImpactEffect>{};
  static int _activeCount = 0;
  static double fxScale = 1.0;
  static int get activeCount => _activeCount;

  /// Use cached sprites when active count is high for better performance
  static bool get _useCachedSprites => _activeCount > 20;

  /// Clear the static pool to prevent memory accumulation between games
  static void clearPool() {
    _ImpactParticle.clearPool();
    _ImpactRing.clearPool();
    _Spark.clearPool();
    _pool.clear();
    _live.clear();
    _activeCount = 0;
  }

  static void _reclaimDetachedActives() {
    if (_live.isEmpty) return;
    final detached = <ImpactEffect>[];
    for (final effect in _live) {
      if (effect._wasMounted && effect.parent == null && !effect.isMounted) {
        detached.add(effect);
      }
    }
    if (detached.isEmpty) return;

    for (final effect in detached) {
      if (effect._counted) {
        if (_activeCount > 0) {
          _activeCount -= 1;
        }
        effect._counted = false;
      }
      if (!effect._inPool && _pool.length < maxPool) {
        effect._inPool = true;
        _pool.add(effect);
      }
      _live.remove(effect);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _ringGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _ringCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _particleGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _particleCorePaint = Paint();
  static final Paint _sparkGlowPaint = Paint()
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _sparkCorePaint = Paint()
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  static final Paint _electricPaint = Paint()
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _starPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _bubbleDropletGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _bubbleDropletCorePaint = Paint();
  static final Paint _bubbleDropletRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _spritePaint = Paint();
  static final Path _reusablePath = Path();

  static ImpactEffect? spawn({
    required Vector2 position,
    required Color color,
    required TowerType towerType,
    double duration = 0.3,
  }) {
    if (_activeCount >= maxActive) {
      _reclaimDetachedActives();
      if (_activeCount >= maxActive) return null;
    }
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
  int _rngState;
  int _lcgNext(int state) => (state * 1664525 + 1013904223) & 0x7fffffff;
  double _nextUnit() {
    _rngState = _lcgNext(_rngState);
    return _rngState / 0x7fffffff;
  }

  double _timer = 0;
  bool _counted = false;
  bool _inPool = false;
  bool _wasMounted = false;
  double _offscreenAccumulator = 0;
  static const double _offscreenUpdateInterval = 0.12;
  final List<_ImpactParticle> _particles = [];
  final List<_ImpactRing> _rings = [];
  final List<_Spark> _sparks = [];

  void _recycleParticles() {
    for (final particle in _particles) {
      particle.recycle();
    }
    _particles.clear();
  }

  void _recycleRings() {
    for (final ring in _rings) {
      ring.recycle();
    }
    _rings.clear();
  }

  void _recycleSparks() {
    for (final spark in _sparks) {
      spark.recycle();
    }
    _sparks.clear();
  }

  void _markActive() {
    if (_counted) return;
    _counted = true;
    _inPool = false;
    _activeCount++;
    _live.add(this);
  }

  void _reset({
    required Vector2 position,
    required Color color,
    required TowerType towerType,
    required double duration,
  }) {
    this.position.setFrom(position);
    anchor = Anchor.center;
    this.color = color;
    this.towerType = towerType;
    this.duration = duration;
    _timer = 0;
    _recycleParticles();
    _recycleRings();
    _recycleSparks();
    _initializeParticles();
  }

  @override
  void onMount() {
    _wasMounted = true;
    super.onMount();
  }

  void _initializeParticles() {
    switch (towerType) {
      case TowerType.pulseArcher:
        // Fast, directional sparks
        final sparkCount = _scaledCount(8, allowZero: true);
        for (int i = 0; i < sparkCount; i++) {
          _sparks.add(_Spark.obtain(
            angle: _nextUnit() * math.pi * 2,
            speed: 80 + _nextUnit() * 60,
            length: 8 + _nextUnit() * 6,
            lifetime: 0.15 + _nextUnit() * 0.1,
          ));
        }
        if (fxScale > 0.2) {
          _rings.add(_ImpactRing.obtain(
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
          _rings.add(_ImpactRing.obtain(
            startRadius: 5 + i * 5,
            endRadius: 40 + i * 10,
            duration: 0.25 + i * 0.05,
          ));
        }
        // Large debris particles
        final particleCount = _scaledCount(12, allowZero: true);
        for (int i = 0; i < particleCount; i++) {
          _particles.add(_ImpactParticle.obtain(
            angle: _nextUnit() * math.pi * 2,
            speed: 40 + _nextUnit() * 80,
            size: 3 + _nextUnit() * 4,
            lifetime: 0.3 + _nextUnit() * 0.2,
            rotationSpeed: (_nextUnit() - 0.5) * 10,
          ));
        }
        break;

      case TowerType.phaseMage:
        // Mystical burst with arcane symbols
        final runeCount = _scaledCount(6, allowZero: true);
        for (int i = 0; i < runeCount; i++) {
          _particles.add(_ImpactParticle.obtain(
            angle: i * math.pi / 3,
            speed: 30 + _nextUnit() * 20,
            size: 4,
            lifetime: 0.4,
            rotationSpeed: 5,
            isRune: true,
          ));
        }
        // Electric discharge
        final sparkCount = _scaledCount(5, allowZero: true);
        for (int i = 0; i < sparkCount; i++) {
          _sparks.add(_Spark.obtain(
            angle: _nextUnit() * math.pi * 2,
            speed: 60 + _nextUnit() * 40,
            length: 12 + _nextUnit() * 8,
            lifetime: 0.2,
            isElectric: true,
          ));
        }
        if (fxScale > 0.2) {
          _rings.add(_ImpactRing.obtain(
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
          _particles.add(_ImpactParticle.obtain(
            angle: _nextUnit() * math.pi * 2,
            speed: 50 + _nextUnit() * 50,
            size: 1.5 + _nextUnit() * 2,
            lifetime: 0.2 + _nextUnit() * 0.15,
            rotationSpeed: (_nextUnit() - 0.5) * 15,
            isStar: true,
          ));
        }
        // Quick flash ring
        if (fxScale > 0.2) {
          _rings.add(_ImpactRing.obtain(
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
        final defaultSparkCount = _scaledCount(10, allowZero: true);
        for (int i = 0; i < defaultSparkCount; i++) {
          _sparks.add(_Spark.obtain(
            angle: _nextUnit() * math.pi * 2,
            speed: 100 + _nextUnit() * 50,
            length: 10 + _nextUnit() * 5,
            lifetime: 0.2,
          ));
        }
        break;
      case TowerType.plasmaBubble:
        // Pop/burst effect - bubble membrane fragments flying outward
        // Multiple expanding rings for pop effect
        final bubbleRingCount = _scaledCount(4);
        for (int i = 0; i < bubbleRingCount; i++) {
          _rings.add(_ImpactRing.obtain(
            startRadius: 8 + i * 4,
            endRadius: 35 + i * 8,
            duration: 0.2 + i * 0.05,
          ));
        }
        // Plasma droplets flying outward
        final dropletCount = _scaledCount(14, allowZero: true);
        for (int i = 0; i < dropletCount; i++) {
          _particles.add(_ImpactParticle.obtain(
            angle: _nextUnit() * math.pi * 2,
            speed: 60 + _nextUnit() * 80,
            size: 2 + _nextUnit() * 3,
            lifetime: 0.35 + _nextUnit() * 0.15,
            rotationSpeed: (_nextUnit() - 0.5) * 8,
            isBubbleDroplet: true,
          ));
        }
        // Electric discharge from popped bubble
        final bubbleSparkCount = _scaledCount(6, allowZero: true);
        for (int i = 0; i < bubbleSparkCount; i++) {
          _sparks.add(_Spark.obtain(
            angle: _nextUnit() * math.pi * 2,
            speed: 70 + _nextUnit() * 50,
            length: 10 + _nextUnit() * 8,
            lifetime: 0.25,
            isElectric: true,
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
    if (_isOffscreen()) return;
    super.render(canvas);

    final progress = (_timer / duration).clamp(0.0, 1.0);
    final fadeOut = 1.0 - progress;
    if (fadeOut <= 0.01) return;

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
      if (alpha <= 0.01) continue;

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

      final px = particle.dirX * particle.distance;
      final py = particle.dirY * particle.distance;
      final alpha = particle.alpha * fadeOut;
      if (alpha <= 0.01) {
        continue;
      }

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
      } else if (particle.isBubbleDroplet) {
        // Draw plasma bubble droplet - looks like a mini bubble fragment
        // Get pink color variant
        final hslColor = HSLColor.fromColor(color);
        final pinkColor = hslColor.withHue((hslColor.hue + 20) % 360).toColor();

        // Outer glow
        _bubbleDropletGlowPaint.color = color.withOpacity(alpha * 0.5);
        canvas.drawCircle(
            Offset.zero, particle.size * 1.5, _bubbleDropletGlowPaint);

        // Membrane ring
        _bubbleDropletRingPaint.color = pinkColor.withOpacity(alpha * 0.7);
        canvas.drawCircle(Offset.zero, particle.size, _bubbleDropletRingPaint);

        // Bright core
        _bubbleDropletCorePaint.color =
            const Color(0xFFFFFFFF).withOpacity(alpha * 0.8);
        canvas.drawCircle(
            Offset.zero, particle.size * 0.4, _bubbleDropletCorePaint);

        // Secondary pink core
        _bubbleDropletCorePaint.color = pinkColor.withOpacity(alpha * 0.6);
        canvas.drawCircle(
            Offset.zero, particle.size * 0.6, _bubbleDropletCorePaint);
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
      if (alpha <= 0.01) continue;
      final startX = spark.dirX * spark.distance;
      final startY = spark.dirY * spark.distance;
      final endX = spark.dirX * (spark.distance + spark.length);
      final endY = spark.dirY * (spark.distance + spark.length);

      if (spark.isElectric) {
        // Draw zigzag electric spark using reusable path
        _reusablePath.reset();
        _reusablePath.moveTo(startX, startY);

        const steps = 3;
        for (int i = 1; i <= steps; i++) {
          final stepProgress = i / steps;
          final baseX = startX + (endX - startX) * stepProgress;
          final baseY = startY + (endY - startY) * stepProgress;

          final jitter = math.sin(_timer * 30 + i * 2) * 3;
          final jitterX = spark.perpX * jitter;
          final jitterY = spark.perpY * jitter;

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

  bool _isOffscreen({double padding = 60}) {
    if (Enemy.screenSize.isZero()) return false;
    if (Enemy.screenScale <= 0) return false;
    final screenX = Enemy.screenOffset.x + position.x * Enemy.screenScale;
    final screenY = Enemy.screenOffset.y + position.y * Enemy.screenScale;
    return screenX < -padding ||
        screenY < -padding ||
        screenX > Enemy.screenSize.x + padding ||
        screenY > Enemy.screenSize.y + padding;
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
    _recycleParticles();
    _recycleRings();
    _recycleSparks();
    _live.remove(this);
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
    _live.remove(this);
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
  _ImpactParticle._internal({
    required this.angle,
    required this.dirX,
    required this.dirY,
    required this.speed,
    required this.size,
    required this.lifetime,
    required this.rotationSpeed,
    required this.isRune,
    required this.isStar,
    required this.isBubbleDroplet,
  })  : distance = 0,
        rotation = 0,
        _timer = 0;

  static const int _maxPool = 220;
  static final List<_ImpactParticle> _pool = [];

  static _ImpactParticle obtain({
    required double angle,
    required double speed,
    required double size,
    required double lifetime,
    double rotationSpeed = 0,
    bool isRune = false,
    bool isStar = false,
    bool isBubbleDroplet = false,
  }) {
    if (_pool.isNotEmpty) {
      final item = _pool.removeLast();
      item._reset(
        angle: angle,
        speed: speed,
        size: size,
        lifetime: lifetime,
        rotationSpeed: rotationSpeed,
        isRune: isRune,
        isStar: isStar,
        isBubbleDroplet: isBubbleDroplet,
      );
      return item;
    }
    final dirX = math.cos(angle);
    final dirY = math.sin(angle);
    return _ImpactParticle._internal(
      angle: angle,
      dirX: dirX,
      dirY: dirY,
      speed: speed,
      size: size,
      lifetime: lifetime,
      rotationSpeed: rotationSpeed,
      isRune: isRune,
      isStar: isStar,
      isBubbleDroplet: isBubbleDroplet,
    );
  }

  static void clearPool() {
    _pool.clear();
  }

  double angle;
  double dirX;
  double dirY;
  double speed;
  double size;
  double lifetime;
  double rotationSpeed;
  bool isRune;
  bool isStar;
  bool isBubbleDroplet;

  double distance;
  double rotation;
  double _timer;

  void _reset({
    required double angle,
    required double speed,
    required double size,
    required double lifetime,
    required double rotationSpeed,
    required bool isRune,
    required bool isStar,
    required bool isBubbleDroplet,
  }) {
    this.angle = angle;
    dirX = math.cos(angle);
    dirY = math.sin(angle);
    this.speed = speed;
    this.size = size;
    this.lifetime = lifetime;
    this.rotationSpeed = rotationSpeed;
    this.isRune = isRune;
    this.isStar = isStar;
    this.isBubbleDroplet = isBubbleDroplet;
    distance = 0;
    rotation = 0;
    _timer = 0;
  }

  void recycle() {
    if (_pool.length >= _maxPool) return;
    _pool.add(this);
  }

  bool get isActive => _timer < lifetime;
  double get alpha => (1 - _timer / lifetime).clamp(0.0, 1.0);

  void update(double dt) {
    _timer += dt;
    distance += speed * dt * (1 - _timer / lifetime); // Slow down over time
    rotation += rotationSpeed * dt;
  }
}

class _Spark {
  _Spark._internal({
    required this.angle,
    required this.dirX,
    required this.dirY,
    required this.perpX,
    required this.perpY,
    required this.speed,
    required this.length,
    required this.lifetime,
    required this.isElectric,
  })  : distance = 0,
        _timer = 0;

  static const int _maxPool = 260;
  static final List<_Spark> _pool = [];

  static _Spark obtain({
    required double angle,
    required double speed,
    required double length,
    required double lifetime,
    bool isElectric = false,
  }) {
    if (_pool.isNotEmpty) {
      final item = _pool.removeLast();
      item._reset(
        angle: angle,
        speed: speed,
        length: length,
        lifetime: lifetime,
        isElectric: isElectric,
      );
      return item;
    }
    final dirX = math.cos(angle);
    final dirY = math.sin(angle);
    return _Spark._internal(
      angle: angle,
      dirX: dirX,
      dirY: dirY,
      perpX: -dirY,
      perpY: dirX,
      speed: speed,
      length: length,
      lifetime: lifetime,
      isElectric: isElectric,
    );
  }

  static void clearPool() {
    _pool.clear();
  }

  double angle;
  double dirX;
  double dirY;
  double perpX;
  double perpY;
  double speed;
  double length;
  double lifetime;
  bool isElectric;

  double distance;
  double _timer;

  void _reset({
    required double angle,
    required double speed,
    required double length,
    required double lifetime,
    required bool isElectric,
  }) {
    this.angle = angle;
    dirX = math.cos(angle);
    dirY = math.sin(angle);
    perpX = -dirY;
    perpY = dirX;
    this.speed = speed;
    this.length = length;
    this.lifetime = lifetime;
    this.isElectric = isElectric;
    distance = 0;
    _timer = 0;
  }

  void recycle() {
    if (_pool.length >= _maxPool) return;
    _pool.add(this);
  }

  bool get isActive => _timer < lifetime;
  double get alpha => (1 - _timer / lifetime).clamp(0.0, 1.0);

  void update(double dt) {
    _timer += dt;
    distance += speed * dt;
  }
}

class _ImpactRing {
  _ImpactRing._internal({
    required this.startRadius,
    required this.endRadius,
    required this.duration,
  }) : _timer = 0;

  static const int _maxPool = 120;
  static final List<_ImpactRing> _pool = [];

  static _ImpactRing obtain({
    required double startRadius,
    required double endRadius,
    required double duration,
  }) {
    if (_pool.isNotEmpty) {
      final item = _pool.removeLast();
      item._reset(
        startRadius: startRadius,
        endRadius: endRadius,
        duration: duration,
      );
      return item;
    }
    return _ImpactRing._internal(
      startRadius: startRadius,
      endRadius: endRadius,
      duration: duration,
    );
  }

  static void clearPool() {
    _pool.clear();
  }

  double startRadius;
  double endRadius;
  double duration;

  double _timer;

  void _reset({
    required double startRadius,
    required double endRadius,
    required double duration,
  }) {
    this.startRadius = startRadius;
    this.endRadius = endRadius;
    this.duration = duration;
    _timer = 0;
  }

  void recycle() {
    if (_pool.length >= _maxPool) return;
    _pool.add(this);
  }

  bool get isActive => _timer < duration;
  double get progress => (_timer / duration).clamp(0.0, 1.0);
  double get currentRadius =>
      startRadius + (endRadius - startRadius) * progress;

  void update(double dt) {
    _timer += dt;
  }
}
