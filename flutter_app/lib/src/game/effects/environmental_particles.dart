import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

/// Environment types for different visual themes
enum EnvironmentType {
  /// Default cyberpunk style - cyan/magenta palette
  defaultCyber,

  /// Industrial - orange/red sparks, smoke, machinery feel
  industrial,

  /// Digital - blue/green data streams, binary particles
  digital,

  /// Corrupted - glitchy, red/purple, unstable effects
  corrupted,
}

// ═══════════════════════════════════════════════════════════════════════════
// CACHED STATIC PAINTS - Avoid per-frame allocations
// ═══════════════════════════════════════════════════════════════════════════
final Paint _sparkPaint = Paint();
final Paint _sparkGlowPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
final Paint _emberPaint = Paint();
final Paint _emberGlowPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
final Paint _emberTrailPaint = Paint()
  ..strokeCap = StrokeCap.round
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
final Paint _mistPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
final Paint _mistInnerPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
final Paint _dataFragmentPaint = Paint();
final Paint _dataFragmentGlowPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
final Paint _lightningPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.5
  ..strokeCap = StrokeCap.round;
final Paint _lightningGlowPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
final Paint _holoDustPaint = Paint();
final Paint _holoDustGlowPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
final Path _reusablePath = Path();

// Note: MaskFilters are pre-configured on Paint objects above to avoid allocations

/// Environmental particle effects component for cyberpunk ambiance.
/// Renders multiple layers of ambient particles behind game elements.
class EnvironmentalParticles extends PositionComponent with HasGameRef<FlameGame> {
  EnvironmentalParticles({
    this.environmentType = EnvironmentType.defaultCyber,
    this.reduceFx = false,
    this.lowFx = false,
    this.intensity = 1.0,
  }) {
    priority = -5; // Render behind most game elements but above grid
  }

  /// Current environment theme
  EnvironmentType environmentType;

  /// Reduce effects for performance
  bool reduceFx;

  /// Minimal effects mode
  bool lowFx;

  /// Overall intensity multiplier (0.0 - 1.0)
  double intensity;

  double _time = 0;
  final math.Random _random = math.Random(42);

  // Particle pools for each layer
  final List<_Spark> _sparks = [];
  final List<_Ember> _embers = [];
  final List<_MistCloud> _mistClouds = [];
  final List<_DataFragment> _dataFragments = [];
  final List<_ElectricDischarge> _electricDischarges = [];
  final List<_HolographicDust> _holoDust = [];

  // Spawn timers
  double _sparkSpawnTimer = 0;
  double _emberSpawnTimer = 0;
  double _mistSpawnTimer = 0;
  double _dataSpawnTimer = 0;
  double _electricSpawnTimer = 0;
  double _holoSpawnTimer = 0;

  // Color palettes for different environments
  static const Map<EnvironmentType, _ColorPalette> _palettes = {
    EnvironmentType.defaultCyber: _ColorPalette(
      primary: Color(0xFF00FFFF),
      secondary: Color(0xFFFF00FF),
      accent: Color(0xFF00FF88),
      glow: Color(0xFF00CCFF),
      mist: Color(0x1500FFFF),
    ),
    EnvironmentType.industrial: _ColorPalette(
      primary: Color(0xFFFF6600),
      secondary: Color(0xFFFFAA00),
      accent: Color(0xFFFF3300),
      glow: Color(0xFFFF8800),
      mist: Color(0x20FF6600),
    ),
    EnvironmentType.digital: _ColorPalette(
      primary: Color(0xFF00FF41),
      secondary: Color(0xFF00CCFF),
      accent: Color(0xFF88FF88),
      glow: Color(0xFF00FF66),
      mist: Color(0x1500FF41),
    ),
    EnvironmentType.corrupted: _ColorPalette(
      primary: Color(0xFFFF0066),
      secondary: Color(0xFF9900FF),
      accent: Color(0xFFFF3366),
      glow: Color(0xFFCC00FF),
      mist: Color(0x20FF0066),
    ),
  };

  _ColorPalette get _palette => _palettes[environmentType]!;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    anchor = Anchor.topLeft;
    position = Vector2.zero();
    _initializeParticles();
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
    _initializeParticles();
  }

  void _initializeParticles() {
    _sparks.clear();
    _embers.clear();
    _mistClouds.clear();
    _dataFragments.clear();
    _electricDischarges.clear();
    _holoDust.clear();

    if (size.isZero()) return;

    // Pre-populate with some particles
    final sparkCount = lowFx ? 5 : (reduceFx ? 10 : 20);
    final emberCount = lowFx ? 3 : (reduceFx ? 6 : 12);
    final mistCount = lowFx ? 2 : (reduceFx ? 3 : 5);
    final dataCount = lowFx ? 4 : (reduceFx ? 8 : 15);
    final holoCount = lowFx ? 5 : (reduceFx ? 10 : 20);

    for (int i = 0; i < sparkCount; i++) {
      _sparks.add(_createSpark());
    }
    for (int i = 0; i < emberCount; i++) {
      _embers.add(_createEmber());
    }
    for (int i = 0; i < mistCount; i++) {
      _mistClouds.add(_createMistCloud());
    }
    for (int i = 0; i < dataCount; i++) {
      _dataFragments.add(_createDataFragment());
    }
    for (int i = 0; i < holoCount; i++) {
      _holoDust.add(_createHoloDust());
    }
  }

  /// Change environment type with smooth transition
  void setEnvironmentType(EnvironmentType type) {
    if (environmentType == type) return;
    environmentType = type;
    // Particles will gradually adopt new colors as they respawn
  }

  /// Set quality level
  void setQuality({required bool reduceFx, required bool lowFx}) {
    final needsReinit = this.reduceFx != reduceFx || this.lowFx != lowFx;
    this.reduceFx = reduceFx;
    this.lowFx = lowFx;
    if (needsReinit) {
      _initializeParticles();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (lowFx && intensity < 0.3) return;

    _time += dt;

    // Update existing particles
    _updateSparks(dt);
    _updateEmbers(dt);
    _updateMistClouds(dt);
    _updateDataFragments(dt);
    _updateElectricDischarges(dt);
    _updateHoloDust(dt);

    // Spawn new particles
    _spawnParticles(dt);
  }

  // Single-pass O(n) update+removal using swap-with-last technique
  void _updateSparks(double dt) {
    var i = 0;
    while (i < _sparks.length) {
      final spark = _sparks[i];
      spark.update(dt);
      if (spark.isAlive) {
        i++;
      } else {
        final lastIndex = _sparks.length - 1;
        if (i < lastIndex) _sparks[i] = _sparks[lastIndex];
        _sparks.removeLast();
      }
    }
  }

  void _updateEmbers(double dt) {
    var i = 0;
    while (i < _embers.length) {
      final ember = _embers[i];
      ember.update(dt, _time);
      if (ember.isAlive) {
        i++;
      } else {
        final lastIndex = _embers.length - 1;
        if (i < lastIndex) _embers[i] = _embers[lastIndex];
        _embers.removeLast();
      }
    }
  }

  void _updateMistClouds(double dt) {
    var i = 0;
    while (i < _mistClouds.length) {
      final mist = _mistClouds[i];
      mist.update(dt, _time, size);
      if (mist.isAlive) {
        i++;
      } else {
        final lastIndex = _mistClouds.length - 1;
        if (i < lastIndex) _mistClouds[i] = _mistClouds[lastIndex];
        _mistClouds.removeLast();
      }
    }
  }

  void _updateDataFragments(double dt) {
    var i = 0;
    while (i < _dataFragments.length) {
      final data = _dataFragments[i];
      data.update(dt, _time);
      if (data.isAlive) {
        i++;
      } else {
        final lastIndex = _dataFragments.length - 1;
        if (i < lastIndex) _dataFragments[i] = _dataFragments[lastIndex];
        _dataFragments.removeLast();
      }
    }
  }

  void _updateElectricDischarges(double dt) {
    var i = 0;
    while (i < _electricDischarges.length) {
      final discharge = _electricDischarges[i];
      discharge.update(dt);
      if (discharge.isAlive) {
        i++;
      } else {
        final lastIndex = _electricDischarges.length - 1;
        if (i < lastIndex) _electricDischarges[i] = _electricDischarges[lastIndex];
        _electricDischarges.removeLast();
      }
    }
  }

  void _updateHoloDust(double dt) {
    var i = 0;
    while (i < _holoDust.length) {
      final holo = _holoDust[i];
      holo.update(dt, _time);
      if (holo.isAlive) {
        i++;
      } else {
        final lastIndex = _holoDust.length - 1;
        if (i < lastIndex) _holoDust[i] = _holoDust[lastIndex];
        _holoDust.removeLast();
      }
    }
  }

  void _spawnParticles(double dt) {
    final spawnRate = intensity * (lowFx ? 0.3 : (reduceFx ? 0.6 : 1.0));

    // Sparks
    final maxSparks = lowFx ? 8 : (reduceFx ? 15 : 30);
    _sparkSpawnTimer += dt;
    if (_sparkSpawnTimer >= 0.15 / spawnRate && _sparks.length < maxSparks) {
      _sparkSpawnTimer = 0;
      _sparks.add(_createSpark());
    }

    // Embers
    final maxEmbers = lowFx ? 5 : (reduceFx ? 10 : 20);
    _emberSpawnTimer += dt;
    if (_emberSpawnTimer >= 0.25 / spawnRate && _embers.length < maxEmbers) {
      _emberSpawnTimer = 0;
      _embers.add(_createEmber());
    }

    // Mist clouds
    final maxMist = lowFx ? 3 : (reduceFx ? 5 : 8);
    _mistSpawnTimer += dt;
    if (_mistSpawnTimer >= 2.0 / spawnRate && _mistClouds.length < maxMist) {
      _mistSpawnTimer = 0;
      _mistClouds.add(_createMistCloud());
    }

    // Data fragments
    final maxData = lowFx ? 6 : (reduceFx ? 12 : 25);
    _dataSpawnTimer += dt;
    if (_dataSpawnTimer >= 0.2 / spawnRate && _dataFragments.length < maxData) {
      _dataSpawnTimer = 0;
      _dataFragments.add(_createDataFragment());
    }

    // Electric discharges (occasional)
    if (!lowFx) {
      _electricSpawnTimer += dt;
      final electricInterval = reduceFx ? 3.0 : 1.5;
      if (_electricSpawnTimer >= electricInterval / spawnRate &&
          _electricDischarges.length < 3) {
        _electricSpawnTimer = 0;
        if (_random.nextDouble() < 0.4) {
          _electricDischarges.add(_createElectricDischarge());
        }
      }
    }

    // Holographic dust
    final maxHolo = lowFx ? 8 : (reduceFx ? 15 : 30);
    _holoSpawnTimer += dt;
    if (_holoSpawnTimer >= 0.1 / spawnRate && _holoDust.length < maxHolo) {
      _holoSpawnTimer = 0;
      _holoDust.add(_createHoloDust());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PARTICLE CREATION
  // ═══════════════════════════════════════════════════════════════════════════

  _Spark _createSpark() {
    return _Spark(
      x: _random.nextDouble() * size.x,
      y: size.y + 10,
      velocityX: (_random.nextDouble() - 0.5) * 30,
      velocityY: -30 - _random.nextDouble() * 50,
      size: 1.5 + _random.nextDouble() * 2,
      lifetime: 1.5 + _random.nextDouble() * 2,
      brightness: 0.5 + _random.nextDouble() * 0.5,
      color: _random.nextDouble() > 0.7 ? _palette.secondary : _palette.primary,
    );
  }

  _Ember _createEmber() {
    return _Ember(
      x: _random.nextDouble() * size.x,
      y: size.y * (0.5 + _random.nextDouble() * 0.5),
      velocityX: (_random.nextDouble() - 0.5) * 20,
      velocityY: -15 - _random.nextDouble() * 25,
      size: 2.5 + _random.nextDouble() * 3,
      lifetime: 2.5 + _random.nextDouble() * 2,
      pulsePhase: _random.nextDouble() * math.pi * 2,
      color: _palette.accent,
      glowColor: _palette.glow,
    );
  }

  _MistCloud _createMistCloud() {
    return _MistCloud(
      x: _random.nextDouble() * size.x,
      y: size.y * (0.7 + _random.nextDouble() * 0.3),
      velocityX: (_random.nextDouble() - 0.5) * 15,
      size: 60 + _random.nextDouble() * 100,
      lifetime: 6 + _random.nextDouble() * 4,
      phase: _random.nextDouble() * math.pi * 2,
      color: _palette.mist,
    );
  }

  _DataFragment _createDataFragment() {
    final shapeType = _random.nextInt(4); // 0=square, 1=triangle, 2=diamond, 3=hexagon
    return _DataFragment(
      x: _random.nextDouble() * size.x,
      y: -20,
      velocityX: (_random.nextDouble() - 0.5) * 40,
      velocityY: 20 + _random.nextDouble() * 40,
      size: 3 + _random.nextDouble() * 5,
      rotation: _random.nextDouble() * math.pi * 2,
      rotationSpeed: (_random.nextDouble() - 0.5) * 3,
      lifetime: 3 + _random.nextDouble() * 3,
      shape: shapeType,
      color: _random.nextDouble() > 0.5 ? _palette.primary : _palette.secondary,
    );
  }

  _ElectricDischarge _createElectricDischarge() {
    // Find two nearby particles to connect
    final startX = _random.nextDouble() * size.x;
    final startY = _random.nextDouble() * size.y * 0.7;
    final angle = (_random.nextDouble() - 0.5) * math.pi * 0.8;
    final length = 40 + _random.nextDouble() * 80;

    return _ElectricDischarge(
      startX: startX,
      startY: startY,
      endX: startX + math.cos(angle) * length,
      endY: startY + math.sin(angle) * length,
      lifetime: 0.1 + _random.nextDouble() * 0.15,
      segments: 4 + _random.nextInt(4),
      color: _palette.primary,
    );
  }

  _HolographicDust _createHoloDust() {
    return _HolographicDust(
      x: _random.nextDouble() * size.x,
      y: _random.nextDouble() * size.y,
      velocityX: (_random.nextDouble() - 0.5) * 10,
      velocityY: (_random.nextDouble() - 0.5) * 10,
      size: 1.5 + _random.nextDouble() * 2.5,
      lifetime: 3 + _random.nextDouble() * 3,
      colorPhase: _random.nextDouble() * math.pi * 2,
      shimmerSpeed: 2 + _random.nextDouble() * 3,
      baseColor: _palette.primary,
      shiftColor: _palette.secondary,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RENDERING
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.isZero()) return;
    if (lowFx && intensity < 0.3) return;

    final globalAlpha = intensity.clamp(0.0, 1.0);

    // Layer 3: Mist/fog at ground level (behind other particles)
    if (!lowFx) {
      _renderMistClouds(canvas, globalAlpha);
    }

    // Layer 1: Floating sparks
    _renderSparks(canvas, globalAlpha);

    // Layer 2: Glowing embers with trails
    _renderEmbers(canvas, globalAlpha);

    // Layer 4: Data fragments
    _renderDataFragments(canvas, globalAlpha);

    // Layer 5: Electric discharge (occasional)
    if (!lowFx) {
      _renderElectricDischarges(canvas, globalAlpha);
    }

    // Layer 6: Holographic dust
    if (!reduceFx) {
      _renderHoloDust(canvas, globalAlpha);
    }
  }

  void _renderSparks(Canvas canvas, double globalAlpha) {
    for (final spark in _sparks) {
      final alpha = spark.alpha * globalAlpha;
      if (alpha <= 0.01) continue;

      // Glow
      if (!lowFx) {
        _sparkGlowPaint.color = spark.color.withOpacity(alpha * 0.4);
        canvas.drawCircle(
          Offset(spark.x, spark.y),
          spark.size * 2,
          _sparkGlowPaint,
        );
      }

      // Core
      _sparkPaint.color =
          Color.lerp(spark.color, const Color(0xFFFFFFFF), spark.brightness * 0.5)!
              .withOpacity(alpha);
      canvas.drawCircle(
        Offset(spark.x, spark.y),
        spark.size,
        _sparkPaint,
      );
    }
  }

  void _renderEmbers(Canvas canvas, double globalAlpha) {
    for (final ember in _embers) {
      final alpha = ember.alpha * globalAlpha;
      if (alpha <= 0.01) continue;

      final pulse = 0.7 + math.sin(ember.currentPulse) * 0.3;
      final effectiveSize = ember.size * pulse;

      // Trail
      if (!lowFx && ember.trailX.isNotEmpty) {
        for (int i = 0; i < ember.trailX.length; i++) {
          final t = i / ember.trailX.length;
          final trailAlpha = alpha * (1 - t) * 0.4;
          final trailSize = effectiveSize * (1 - t * 0.6);

          _emberTrailPaint
            ..color = ember.color.withOpacity(trailAlpha)
            ..strokeWidth = trailSize;

          if (i > 0) {
            canvas.drawLine(
              Offset(ember.trailX[i - 1], ember.trailY[i - 1]),
              Offset(ember.trailX[i], ember.trailY[i]),
              _emberTrailPaint,
            );
          }
        }
      }

      // Outer glow
      if (!lowFx) {
        _emberGlowPaint.color = ember.glowColor.withOpacity(alpha * 0.3 * pulse);
        canvas.drawCircle(
          Offset(ember.x, ember.y),
          effectiveSize * 2.5,
          _emberGlowPaint,
        );
      }

      // Core
      _emberPaint.color =
          Color.lerp(ember.color, const Color(0xFFFFFFFF), pulse * 0.4)!
              .withOpacity(alpha);
      canvas.drawCircle(
        Offset(ember.x, ember.y),
        effectiveSize,
        _emberPaint,
      );
    }
  }

  void _renderMistClouds(Canvas canvas, double globalAlpha) {
    for (final mist in _mistClouds) {
      final alpha = mist.alpha * globalAlpha;
      if (alpha <= 0.01) continue;

      final wobble = math.sin(mist.currentPhase) * 20;
      final breathe = 1.0 + math.sin(mist.currentPhase * 0.7) * 0.15;
      final effectiveSize = mist.size * breathe;

      // Outer mist
      _mistPaint.color = mist.color.withOpacity(alpha * 0.6);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(mist.x + wobble, mist.y),
          width: effectiveSize * 1.5,
          height: effectiveSize * 0.4,
        ),
        _mistPaint,
      );

      // Inner brighter mist
      _mistInnerPaint.color = mist.color.withOpacity(alpha * 0.8);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(mist.x + wobble * 0.5, mist.y),
          width: effectiveSize * 0.8,
          height: effectiveSize * 0.25,
        ),
        _mistInnerPaint,
      );
    }
  }

  void _renderDataFragments(Canvas canvas, double globalAlpha) {
    for (final data in _dataFragments) {
      final alpha = data.alpha * globalAlpha;
      if (alpha <= 0.01) continue;

      canvas.save();
      canvas.translate(data.x, data.y);
      canvas.rotate(data.currentRotation);

      // Glow
      if (!lowFx) {
        _dataFragmentGlowPaint.color = data.color.withOpacity(alpha * 0.3);
        canvas.drawCircle(Offset.zero, data.size * 1.5, _dataFragmentGlowPaint);
      }

      _dataFragmentPaint.color = data.color.withOpacity(alpha * 0.8);

      switch (data.shape) {
        case 0: // Square
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: data.size,
              height: data.size,
            ),
            _dataFragmentPaint,
          );
          break;

        case 1: // Triangle
          _reusablePath.reset();
          _reusablePath.moveTo(0, -data.size / 2);
          _reusablePath.lineTo(-data.size / 2, data.size / 2);
          _reusablePath.lineTo(data.size / 2, data.size / 2);
          _reusablePath.close();
          canvas.drawPath(_reusablePath, _dataFragmentPaint);
          break;

        case 2: // Diamond
          _reusablePath.reset();
          _reusablePath.moveTo(0, -data.size / 2);
          _reusablePath.lineTo(data.size / 3, 0);
          _reusablePath.lineTo(0, data.size / 2);
          _reusablePath.lineTo(-data.size / 3, 0);
          _reusablePath.close();
          canvas.drawPath(_reusablePath, _dataFragmentPaint);
          break;

        case 3: // Hexagon
          _reusablePath.reset();
          for (int i = 0; i < 6; i++) {
            final angle = i * math.pi / 3 - math.pi / 6;
            final px = math.cos(angle) * data.size / 2;
            final py = math.sin(angle) * data.size / 2;
            if (i == 0) {
              _reusablePath.moveTo(px, py);
            } else {
              _reusablePath.lineTo(px, py);
            }
          }
          _reusablePath.close();
          canvas.drawPath(_reusablePath, _dataFragmentPaint);
          break;
      }

      canvas.restore();
    }
  }

  void _renderElectricDischarges(Canvas canvas, double globalAlpha) {
    for (final discharge in _electricDischarges) {
      final alpha = discharge.alpha * globalAlpha;
      if (alpha <= 0.01) continue;

      // Build lightning path
      _reusablePath.reset();
      _reusablePath.moveTo(discharge.startX, discharge.startY);

      final dx = discharge.endX - discharge.startX;
      final dy = discharge.endY - discharge.startY;
      final length = math.sqrt(dx * dx + dy * dy);
      final perpX = -dy / length;
      final perpY = dx / length;

      for (int i = 1; i <= discharge.segments; i++) {
        final t = i / discharge.segments;
        final baseX = discharge.startX + dx * t;
        final baseY = discharge.startY + dy * t;

        // Add zigzag offset (except for last point)
        final offset =
            i == discharge.segments ? 0.0 : (_random.nextDouble() - 0.5) * 15;

        _reusablePath.lineTo(
          baseX + perpX * offset,
          baseY + perpY * offset,
        );
      }

      // Outer glow
      _lightningGlowPaint.color = discharge.color.withOpacity(alpha * 0.5);
      canvas.drawPath(_reusablePath, _lightningGlowPaint);

      // Core lightning
      _lightningPaint.color =
          Color.lerp(discharge.color, const Color(0xFFFFFFFF), 0.5)!
              .withOpacity(alpha);
      canvas.drawPath(_reusablePath, _lightningPaint);
    }
  }

  void _renderHoloDust(Canvas canvas, double globalAlpha) {
    for (final holo in _holoDust) {
      final alpha = holo.alpha * globalAlpha;
      if (alpha <= 0.01) continue;

      final shimmer = math.sin(holo.currentColorPhase);
      final color = Color.lerp(holo.baseColor, holo.shiftColor, (shimmer + 1) / 2)!;
      final brightness = 0.6 + shimmer * 0.4;

      // Glow
      _holoDustGlowPaint.color = color.withOpacity(alpha * 0.3 * brightness);
      canvas.drawCircle(
        Offset(holo.x, holo.y),
        holo.size * 2,
        _holoDustGlowPaint,
      );

      // Core with color shift
      _holoDustPaint.color =
          Color.lerp(color, const Color(0xFFFFFFFF), brightness * 0.3)!
              .withOpacity(alpha * brightness);
      canvas.drawCircle(
        Offset(holo.x, holo.y),
        holo.size,
        _holoDustPaint,
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PARTICLE DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class _ColorPalette {
  const _ColorPalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.glow,
    required this.mist,
  });

  final Color primary;
  final Color secondary;
  final Color accent;
  final Color glow;
  final Color mist;
}

/// Layer 1: Floating sparks - small bright dots drifting upward
class _Spark {
  _Spark({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.lifetime,
    required this.brightness,
    required this.color,
  }) : _remainingLife = lifetime;

  double x;
  double y;
  double velocityX;
  double velocityY;
  double size;
  double lifetime;
  double brightness;
  Color color;
  double _remainingLife;

  bool get isAlive => _remainingLife > 0;
  double get alpha => (_remainingLife / lifetime).clamp(0.0, 1.0);

  void update(double dt) {
    x += velocityX * dt;
    y += velocityY * dt;

    // Slight drift
    velocityX *= 0.99;
    velocityY *= 0.995;

    _remainingLife -= dt;
  }
}

/// Layer 2: Glowing embers - orange/red particles with trails
class _Ember {
  _Ember({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.lifetime,
    required this.pulsePhase,
    required this.color,
    required this.glowColor,
  })  : _remainingLife = lifetime,
        currentPulse = pulsePhase,
        trailX = [],
        trailY = [];

  double x;
  double y;
  double velocityX;
  double velocityY;
  double size;
  double lifetime;
  double pulsePhase;
  Color color;
  Color glowColor;
  double _remainingLife;
  double currentPulse;

  // Trail positions
  final List<double> trailX;
  final List<double> trailY;
  static const int maxTrailLength = 8;

  bool get isAlive => _remainingLife > 0;
  double get alpha => (_remainingLife / lifetime).clamp(0.0, 1.0);

  void update(double dt, double time) {
    // Update trail
    if (trailX.length >= maxTrailLength) {
      trailX.removeAt(0);
      trailY.removeAt(0);
    }
    trailX.add(x);
    trailY.add(y);

    // Movement with slight wobble
    final wobble = math.sin(time * 3 + pulsePhase) * 5;
    x += (velocityX + wobble) * dt;
    y += velocityY * dt;

    // Slow rising
    velocityY *= 0.995;
    velocityX *= 0.98;

    // Update pulse
    currentPulse += dt * 4;

    _remainingLife -= dt;
  }
}

/// Layer 3: Cyberpunk mist/fog - subtle animated clouds at ground level
class _MistCloud {
  _MistCloud({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.size,
    required this.lifetime,
    required this.phase,
    required this.color,
  })  : _remainingLife = lifetime,
        currentPhase = phase;

  double x;
  double y;
  double velocityX;
  double size;
  double lifetime;
  double phase;
  Color color;
  double _remainingLife;
  double currentPhase;

  bool get isAlive => _remainingLife > 0;
  double get alpha {
    final life = _remainingLife / lifetime;
    // Fade in and out
    if (life > 0.8) return (1 - life) / 0.2;
    if (life < 0.2) return life / 0.2;
    return 1.0;
  }

  void update(double dt, double time, Vector2 bounds) {
    x += velocityX * dt;
    currentPhase += dt * 0.5;

    // Wrap around horizontally
    if (x < -size) x = bounds.x + size;
    if (x > bounds.x + size) x = -size;

    _remainingLife -= dt;
  }
}

/// Layer 4: Data fragments - small geometric shapes floating
class _DataFragment {
  _DataFragment({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.lifetime,
    required this.shape,
    required this.color,
  })  : _remainingLife = lifetime,
        currentRotation = rotation;

  double x;
  double y;
  double velocityX;
  double velocityY;
  double size;
  double rotation;
  double rotationSpeed;
  double lifetime;
  int shape; // 0=square, 1=triangle, 2=diamond, 3=hexagon
  Color color;
  double _remainingLife;
  double currentRotation;

  bool get isAlive => _remainingLife > 0;
  double get alpha => (_remainingLife / lifetime).clamp(0.0, 1.0);

  void update(double dt, double time) {
    x += velocityX * dt;
    y += velocityY * dt;

    // Slight drift
    velocityX *= 0.995;
    velocityY *= 0.998;

    // Rotation
    currentRotation += rotationSpeed * dt;

    _remainingLife -= dt;
  }
}

/// Layer 5: Electric discharge - occasional small lightning between particles
class _ElectricDischarge {
  _ElectricDischarge({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.lifetime,
    required this.segments,
    required this.color,
  }) : _remainingLife = lifetime;

  double startX;
  double startY;
  double endX;
  double endY;
  double lifetime;
  int segments;
  Color color;
  double _remainingLife;

  bool get isAlive => _remainingLife > 0;
  double get alpha => (_remainingLife / lifetime).clamp(0.0, 1.0);

  void update(double dt) {
    _remainingLife -= dt;
  }
}

/// Layer 6: Holographic dust - shimmering particles with color shifts
class _HolographicDust {
  _HolographicDust({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.lifetime,
    required this.colorPhase,
    required this.shimmerSpeed,
    required this.baseColor,
    required this.shiftColor,
  })  : _remainingLife = lifetime,
        currentColorPhase = colorPhase;

  double x;
  double y;
  double velocityX;
  double velocityY;
  double size;
  double lifetime;
  double colorPhase;
  double shimmerSpeed;
  Color baseColor;
  Color shiftColor;
  double _remainingLife;
  double currentColorPhase;

  bool get isAlive => _remainingLife > 0;
  double get alpha {
    final life = _remainingLife / lifetime;
    // Gentle fade in and out
    if (life > 0.85) return (1 - life) / 0.15;
    if (life < 0.15) return life / 0.15;
    return 1.0;
  }

  void update(double dt, double time) {
    x += velocityX * dt;
    y += velocityY * dt;

    // Very slow drift
    velocityX *= 0.999;
    velocityY *= 0.999;

    // Update color phase for shimmer
    currentColorPhase += shimmerSpeed * dt;

    _remainingLife -= dt;
  }
}
