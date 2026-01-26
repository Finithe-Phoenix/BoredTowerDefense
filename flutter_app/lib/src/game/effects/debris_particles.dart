import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// =============================================================================
// CACHED STATIC PAINTS - Avoid per-frame allocations
// =============================================================================
final Paint _metalFragmentPaint = Paint();
final Paint _metalFragmentGlowPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
final Paint _emberPaint = Paint();
final Paint _emberGlowPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
final Paint _emberTrailPaint = Paint()
  ..strokeCap = StrokeCap.round
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
final Paint _hexShieldPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.5;
final Paint _hexShieldGlowPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2.5
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
final Paint _sparkPaint = Paint();
final Paint _sparkGlowPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
final Paint _sparkLinePaint = Paint()
  ..strokeCap = StrokeCap.round
  ..strokeWidth = 1.5;
final Paint _smokePaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
final Paint _smokeInnerPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
final Paint _holoFragmentPaint = Paint();
final Paint _holoFragmentGlowPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
final Paint _holoGlitchPaint = Paint();
final Path _reusablePath = Path();

// Cached blur filters
final Map<int, MaskFilter> _blurCache = {};

MaskFilter _blur(double sigma) {
  var key = sigma.round();
  if (key < 1) key = 1;
  if (key > 40) key = 40;
  return _blurCache.putIfAbsent(
    key,
    () => MaskFilter.blur(BlurStyle.normal, key.toDouble()),
  );
}

/// Floating debris particles for damaged areas.
/// Creates a layered effect of various debris types floating upward with wobble.
/// Spawns around damaged towers or after explosions.
///
/// Layers:
/// - Layer 1: Small metal/tech fragments floating
/// - Layer 2: Glowing ember particles (hot debris)
/// - Layer 3: Hexagonal broken shield pieces
/// - Layer 4: Sparking electrical fragments
/// - Layer 5: Smoke wisps rising
/// - Layer 6: Holographic data fragments (glitchy squares)
class DebrisParticles extends PositionComponent {
  DebrisParticles._internal({
    required Vector2 position,
    required this.areaSize,
    required this.color,
    required this.duration,
    required this.intensity,
  }) : _random = math.Random() {
    _reset(
      position: position,
      areaSize: areaSize,
      color: color,
      duration: duration,
      intensity: intensity,
    );
  }

  static const int maxPool = 16;
  static const int maxActive = 12;
  static final List<DebrisParticles> _pool = [];
  static int _activeCount = 0;
  static double fxScale = 1.0;
  static bool reduceFx = false;
  static bool lowFx = false;
  static int get activeCount => _activeCount;

  /// Clear the static pool to prevent memory accumulation between games
  static void clearPool() {
    _pool.clear();
    _activeCount = 0;
  }

  /// Spawn debris particles at a damaged area
  static DebrisParticles? spawn({
    required Vector2 position,
    double areaSize = 40.0,
    Color color = const Color(0xFF00FFFF),
    double duration = 3.0,
    double intensity = 1.0,
  }) {
    if (_activeCount >= maxActive) return null;
    DebrisParticles effect;
    if (_pool.isNotEmpty) {
      effect = _pool.removeLast();
      effect._reset(
        position: position,
        areaSize: areaSize,
        color: color,
        duration: duration,
        intensity: intensity,
      );
    } else {
      effect = DebrisParticles._internal(
        position: position,
        areaSize: areaSize,
        color: color,
        duration: duration,
        intensity: intensity,
      );
    }
    effect._markActive();
    return effect;
  }

  /// Spawn continuous debris for a damaged tower (longer duration, auto-respawn)
  static DebrisParticles? spawnContinuous({
    required Vector2 position,
    double areaSize = 30.0,
    Color color = const Color(0xFF00FFFF),
    double intensity = 0.6,
  }) {
    return spawn(
      position: position,
      areaSize: areaSize,
      color: color,
      duration: 999.0, // Very long duration for continuous effect
      intensity: intensity,
    );
  }

  Color color;
  double areaSize;
  double duration;
  double intensity;

  // Particle pools for each layer
  final List<_MetalFragment> _metalFragments = [];
  final List<_HotEmber> _hotEmbers = [];
  final List<_HexShieldPiece> _hexShieldPieces = [];
  final List<_ElectricalSpark> _electricalSparks = [];
  final List<_SmokeWisp> _smokeWisps = [];
  final List<_HoloDataFragment> _holoFragments = [];

  double _time = 0;
  final math.Random _random;
  bool _counted = false;
  bool _inPool = false;

  // Spawn timers
  double _metalSpawnTimer = 0;
  double _emberSpawnTimer = 0;
  double _hexSpawnTimer = 0;
  double _sparkSpawnTimer = 0;
  double _smokeSpawnTimer = 0;
  double _holoSpawnTimer = 0;

  // Color variations for visual variety
  Color get _hotColor => const Color(0xFFFF6600); // Orange for hot debris
  Color get _emberColor => const Color(0xFFFFAA00); // Yellow-orange
  Color get _techColor => color; // Cyan for tech fragments (uses passed color)
  Color get _holoColor => const Color(0xFF00FFFF); // Cyan for holographic

  void _markActive() {
    if (_counted) return;
    _counted = true;
    _inPool = false;
    _activeCount++;
  }

  void _reset({
    required Vector2 position,
    required double areaSize,
    required Color color,
    required double duration,
    required double intensity,
  }) {
    this.position.setFrom(position);
    anchor = Anchor.center;
    this.areaSize = areaSize;
    this.color = color;
    this.duration = duration;
    this.intensity = intensity;
    _time = 0;
    _metalSpawnTimer = 0;
    _emberSpawnTimer = 0;
    _hexSpawnTimer = 0;
    _sparkSpawnTimer = 0;
    _smokeSpawnTimer = 0;
    _holoSpawnTimer = 0;
    _metalFragments.clear();
    _hotEmbers.clear();
    _hexShieldPieces.clear();
    _electricalSparks.clear();
    _smokeWisps.clear();
    _holoFragments.clear();
    _initializeParticles();
  }

  void _initializeParticles() {
    // Pre-populate with initial particles
    final metalCount = _scaledCount(8);
    final emberCount = _scaledCount(6);
    final hexCount = _scaledCount(4);
    final sparkCount = _scaledCount(5);
    final smokeCount = _scaledCount(3);
    final holoCount = _scaledCount(6);

    for (int i = 0; i < metalCount; i++) {
      _metalFragments.add(_createMetalFragment());
    }
    for (int i = 0; i < emberCount; i++) {
      _hotEmbers.add(_createHotEmber());
    }
    for (int i = 0; i < hexCount; i++) {
      _hexShieldPieces.add(_createHexShieldPiece());
    }
    for (int i = 0; i < sparkCount; i++) {
      _electricalSparks.add(_createElectricalSpark());
    }
    for (int i = 0; i < smokeCount; i++) {
      _smokeWisps.add(_createSmokeWisp());
    }
    for (int i = 0; i < holoCount; i++) {
      _holoFragments.add(_createHoloDataFragment());
    }
  }

  int _scaledCount(int base) {
    final scaled = (base * fxScale * intensity).round();
    if (lowFx) return (scaled * 0.3).round().clamp(1, base);
    if (reduceFx) return (scaled * 0.6).round().clamp(1, base);
    return scaled.clamp(1, base * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (lowFx && intensity < 0.3) return;

    _time += dt;

    // Check if effect should end
    if (_time >= duration) {
      _recycle();
      return;
    }

    // Update existing particles
    _updateMetalFragments(dt);
    _updateHotEmbers(dt);
    _updateHexShieldPieces(dt);
    _updateElectricalSparks(dt);
    _updateSmokeWisps(dt);
    _updateHoloDataFragments(dt);

    // Spawn new particles
    _spawnParticles(dt);
  }

  // Single-pass O(n) update+removal using swap-with-last technique
  void _updateMetalFragments(double dt) {
    var i = 0;
    while (i < _metalFragments.length) {
      final fragment = _metalFragments[i];
      fragment.update(dt, _time);
      if (fragment.isAlive) {
        i++;
      } else {
        final lastIndex = _metalFragments.length - 1;
        if (i < lastIndex) _metalFragments[i] = _metalFragments[lastIndex];
        _metalFragments.removeLast();
      }
    }
  }

  void _updateHotEmbers(double dt) {
    var i = 0;
    while (i < _hotEmbers.length) {
      final ember = _hotEmbers[i];
      ember.update(dt, _time);
      if (ember.isAlive) {
        i++;
      } else {
        final lastIndex = _hotEmbers.length - 1;
        if (i < lastIndex) _hotEmbers[i] = _hotEmbers[lastIndex];
        _hotEmbers.removeLast();
      }
    }
  }

  void _updateHexShieldPieces(double dt) {
    var i = 0;
    while (i < _hexShieldPieces.length) {
      final hex = _hexShieldPieces[i];
      hex.update(dt, _time);
      if (hex.isAlive) {
        i++;
      } else {
        final lastIndex = _hexShieldPieces.length - 1;
        if (i < lastIndex) _hexShieldPieces[i] = _hexShieldPieces[lastIndex];
        _hexShieldPieces.removeLast();
      }
    }
  }

  void _updateElectricalSparks(double dt) {
    var i = 0;
    while (i < _electricalSparks.length) {
      final spark = _electricalSparks[i];
      spark.update(dt, _time);
      if (spark.isAlive) {
        i++;
      } else {
        final lastIndex = _electricalSparks.length - 1;
        if (i < lastIndex) _electricalSparks[i] = _electricalSparks[lastIndex];
        _electricalSparks.removeLast();
      }
    }
  }

  void _updateSmokeWisps(double dt) {
    var i = 0;
    while (i < _smokeWisps.length) {
      final smoke = _smokeWisps[i];
      smoke.update(dt, _time);
      if (smoke.isAlive) {
        i++;
      } else {
        final lastIndex = _smokeWisps.length - 1;
        if (i < lastIndex) _smokeWisps[i] = _smokeWisps[lastIndex];
        _smokeWisps.removeLast();
      }
    }
  }

  void _updateHoloDataFragments(double dt) {
    var i = 0;
    while (i < _holoFragments.length) {
      final holo = _holoFragments[i];
      holo.update(dt, _time);
      if (holo.isAlive) {
        i++;
      } else {
        final lastIndex = _holoFragments.length - 1;
        if (i < lastIndex) _holoFragments[i] = _holoFragments[lastIndex];
        _holoFragments.removeLast();
      }
    }
  }

  void _spawnParticles(double dt) {
    final spawnRate = intensity * (lowFx ? 0.3 : (reduceFx ? 0.6 : 1.0));

    // Layer 1: Metal fragments
    final maxMetal = _scaledCount(12);
    _metalSpawnTimer += dt;
    if (_metalSpawnTimer >= 0.2 / spawnRate && _metalFragments.length < maxMetal) {
      _metalSpawnTimer = 0;
      _metalFragments.add(_createMetalFragment());
    }

    // Layer 2: Hot embers
    final maxEmbers = _scaledCount(10);
    _emberSpawnTimer += dt;
    if (_emberSpawnTimer >= 0.25 / spawnRate && _hotEmbers.length < maxEmbers) {
      _emberSpawnTimer = 0;
      _hotEmbers.add(_createHotEmber());
    }

    // Layer 3: Hex shield pieces
    final maxHex = _scaledCount(6);
    _hexSpawnTimer += dt;
    if (_hexSpawnTimer >= 0.4 / spawnRate && _hexShieldPieces.length < maxHex) {
      _hexSpawnTimer = 0;
      _hexShieldPieces.add(_createHexShieldPiece());
    }

    // Layer 4: Electrical sparks
    final maxSparks = _scaledCount(8);
    _sparkSpawnTimer += dt;
    if (_sparkSpawnTimer >= 0.15 / spawnRate && _electricalSparks.length < maxSparks) {
      _sparkSpawnTimer = 0;
      _electricalSparks.add(_createElectricalSpark());
    }

    // Layer 5: Smoke wisps
    if (!lowFx) {
      final maxSmoke = _scaledCount(5);
      _smokeSpawnTimer += dt;
      if (_smokeSpawnTimer >= 0.5 / spawnRate && _smokeWisps.length < maxSmoke) {
        _smokeSpawnTimer = 0;
        _smokeWisps.add(_createSmokeWisp());
      }
    }

    // Layer 6: Holographic data fragments
    if (!reduceFx) {
      final maxHolo = _scaledCount(10);
      _holoSpawnTimer += dt;
      if (_holoSpawnTimer >= 0.18 / spawnRate && _holoFragments.length < maxHolo) {
        _holoSpawnTimer = 0;
        _holoFragments.add(_createHoloDataFragment());
      }
    }
  }

  // ===========================================================================
  // PARTICLE CREATION
  // ===========================================================================

  _MetalFragment _createMetalFragment() {
    final angle = _random.nextDouble() * math.pi * 2;
    final dist = _random.nextDouble() * areaSize * 0.5;
    return _MetalFragment(
      x: math.cos(angle) * dist,
      y: math.sin(angle) * dist,
      velocityX: (_random.nextDouble() - 0.5) * 15,
      velocityY: -20 - _random.nextDouble() * 30,
      size: 2 + _random.nextDouble() * 3,
      rotation: _random.nextDouble() * math.pi * 2,
      rotationSpeed: (_random.nextDouble() - 0.5) * 4,
      lifetime: 1.5 + _random.nextDouble() * 1.5,
      wobblePhase: _random.nextDouble() * math.pi * 2,
      wobbleSpeed: 2 + _random.nextDouble() * 3,
      wobbleAmount: 3 + _random.nextDouble() * 5,
      color: _techColor,
      shape: _random.nextInt(3), // 0=square, 1=triangle, 2=diamond
    );
  }

  _HotEmber _createHotEmber() {
    final angle = _random.nextDouble() * math.pi * 2;
    final dist = _random.nextDouble() * areaSize * 0.4;
    return _HotEmber(
      x: math.cos(angle) * dist,
      y: math.sin(angle) * dist,
      velocityX: (_random.nextDouble() - 0.5) * 10,
      velocityY: -15 - _random.nextDouble() * 25,
      size: 2 + _random.nextDouble() * 2.5,
      lifetime: 2 + _random.nextDouble() * 2,
      pulsePhase: _random.nextDouble() * math.pi * 2,
      pulseSpeed: 4 + _random.nextDouble() * 4,
      wobblePhase: _random.nextDouble() * math.pi * 2,
      wobbleAmount: 2 + _random.nextDouble() * 4,
      color: _random.nextDouble() > 0.5 ? _hotColor : _emberColor,
    );
  }

  _HexShieldPiece _createHexShieldPiece() {
    final angle = _random.nextDouble() * math.pi * 2;
    final dist = _random.nextDouble() * areaSize * 0.6;
    return _HexShieldPiece(
      x: math.cos(angle) * dist,
      y: math.sin(angle) * dist,
      velocityX: (_random.nextDouble() - 0.5) * 12,
      velocityY: -12 - _random.nextDouble() * 20,
      size: 5 + _random.nextDouble() * 6,
      rotation: _random.nextDouble() * math.pi * 2,
      rotationSpeed: (_random.nextDouble() - 0.5) * 2,
      lifetime: 2.5 + _random.nextDouble() * 2,
      wobblePhase: _random.nextDouble() * math.pi * 2,
      wobbleAmount: 4 + _random.nextDouble() * 6,
      color: _techColor,
      flickerPhase: _random.nextDouble() * math.pi * 2,
      isBroken: _random.nextDouble() > 0.6,
    );
  }

  _ElectricalSpark _createElectricalSpark() {
    final angle = _random.nextDouble() * math.pi * 2;
    final dist = _random.nextDouble() * areaSize * 0.5;
    return _ElectricalSpark(
      x: math.cos(angle) * dist,
      y: math.sin(angle) * dist,
      velocityX: (_random.nextDouble() - 0.5) * 25,
      velocityY: -25 - _random.nextDouble() * 35,
      size: 1.5 + _random.nextDouble() * 2,
      lifetime: 0.5 + _random.nextDouble() * 0.8,
      color: _random.nextDouble() > 0.3 ? _techColor : Colors.white,
      arcLength: 3 + _random.nextDouble() * 6,
      arcAngle: _random.nextDouble() * math.pi * 2,
      flickerSpeed: 15 + _random.nextDouble() * 25,
    );
  }

  _SmokeWisp _createSmokeWisp() {
    final angle = _random.nextDouble() * math.pi * 2;
    final dist = _random.nextDouble() * areaSize * 0.3;
    return _SmokeWisp(
      x: math.cos(angle) * dist,
      y: math.sin(angle) * dist,
      velocityY: -8 - _random.nextDouble() * 12,
      size: 8 + _random.nextDouble() * 12,
      lifetime: 3 + _random.nextDouble() * 2,
      driftPhase: _random.nextDouble() * math.pi * 2,
      driftAmount: 10 + _random.nextDouble() * 15,
      expansionRate: 0.3 + _random.nextDouble() * 0.4,
    );
  }

  _HoloDataFragment _createHoloDataFragment() {
    final angle = _random.nextDouble() * math.pi * 2;
    final dist = _random.nextDouble() * areaSize * 0.5;
    return _HoloDataFragment(
      x: math.cos(angle) * dist,
      y: math.sin(angle) * dist,
      velocityX: (_random.nextDouble() - 0.5) * 18,
      velocityY: -18 - _random.nextDouble() * 28,
      size: 3 + _random.nextDouble() * 4,
      lifetime: 1.2 + _random.nextDouble() * 1.5,
      wobblePhase: _random.nextDouble() * math.pi * 2,
      wobbleAmount: 3 + _random.nextDouble() * 5,
      color: _holoColor,
      glitchIntensity: 0.3 + _random.nextDouble() * 0.7,
      glitchSpeed: 10 + _random.nextDouble() * 20,
      rgbOffset: 1 + _random.nextDouble() * 3,
    );
  }

  // ===========================================================================
  // RENDERING
  // ===========================================================================

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (lowFx && intensity < 0.3) return;

    // Calculate fade out near end of duration
    final fadeOut = duration > 10
        ? 1.0
        : (_time < duration - 0.5 ? 1.0 : (duration - _time) / 0.5).clamp(0.0, 1.0);

    // Layer 5: Smoke wisps (behind everything)
    if (!lowFx) {
      _renderSmokeWisps(canvas, fadeOut);
    }

    // Layer 1: Metal fragments
    _renderMetalFragments(canvas, fadeOut);

    // Layer 2: Hot embers
    _renderHotEmbers(canvas, fadeOut);

    // Layer 3: Hex shield pieces
    _renderHexShieldPieces(canvas, fadeOut);

    // Layer 4: Electrical sparks
    _renderElectricalSparks(canvas, fadeOut);

    // Layer 6: Holographic data fragments (on top)
    if (!reduceFx) {
      _renderHoloDataFragments(canvas, fadeOut);
    }
  }

  void _renderMetalFragments(Canvas canvas, double fadeOut) {
    for (final fragment in _metalFragments) {
      final alpha = fragment.alpha * fadeOut;
      if (alpha <= 0.01) continue;

      canvas.save();
      canvas.translate(fragment.currentX, fragment.currentY);
      canvas.rotate(fragment.currentRotation);

      // Glow
      if (!lowFx) {
        _metalFragmentGlowPaint.color = fragment.color.withOpacity(alpha * 0.3);
        canvas.drawCircle(Offset.zero, fragment.size * 1.5, _metalFragmentGlowPaint);
      }

      _metalFragmentPaint.color = fragment.color.withOpacity(alpha * 0.8);

      switch (fragment.shape) {
        case 0: // Square
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: fragment.size,
              height: fragment.size,
            ),
            _metalFragmentPaint,
          );
          break;
        case 1: // Triangle
          _reusablePath.reset();
          _reusablePath.moveTo(0, -fragment.size / 2);
          _reusablePath.lineTo(-fragment.size / 2, fragment.size / 2);
          _reusablePath.lineTo(fragment.size / 2, fragment.size / 2);
          _reusablePath.close();
          canvas.drawPath(_reusablePath, _metalFragmentPaint);
          break;
        case 2: // Diamond
          _reusablePath.reset();
          _reusablePath.moveTo(0, -fragment.size / 2);
          _reusablePath.lineTo(fragment.size / 3, 0);
          _reusablePath.lineTo(0, fragment.size / 2);
          _reusablePath.lineTo(-fragment.size / 3, 0);
          _reusablePath.close();
          canvas.drawPath(_reusablePath, _metalFragmentPaint);
          break;
      }

      canvas.restore();
    }
  }

  void _renderHotEmbers(Canvas canvas, double fadeOut) {
    for (final ember in _hotEmbers) {
      final alpha = ember.alpha * fadeOut;
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
        _emberGlowPaint.color = ember.color.withOpacity(alpha * 0.4 * pulse);
        canvas.drawCircle(
          Offset(ember.currentX, ember.currentY),
          effectiveSize * 2.5,
          _emberGlowPaint,
        );
      }

      // Core
      _emberPaint.color =
          Color.lerp(ember.color, Colors.white, pulse * 0.4)!.withOpacity(alpha);
      canvas.drawCircle(
        Offset(ember.currentX, ember.currentY),
        effectiveSize,
        _emberPaint,
      );
    }
  }

  void _renderHexShieldPieces(Canvas canvas, double fadeOut) {
    for (final hex in _hexShieldPieces) {
      final alpha = hex.alpha * fadeOut;
      if (alpha <= 0.01) continue;

      // Flicker effect
      final flicker = hex.isBroken
          ? (math.sin(hex.currentFlicker) > 0 ? 1.0 : 0.6)
          : 1.0;
      final effectiveAlpha = alpha * flicker;

      canvas.save();
      canvas.translate(hex.currentX, hex.currentY);
      canvas.rotate(hex.currentRotation);

      // Glow
      if (!lowFx) {
        _hexShieldGlowPaint.color = hex.color.withOpacity(effectiveAlpha * 0.4);
        _drawHexagon(canvas, hex.size, _hexShieldGlowPaint, hex.isBroken);
      }

      // Main hexagon
      _hexShieldPaint.color = hex.color.withOpacity(effectiveAlpha * 0.8);
      _drawHexagon(canvas, hex.size, _hexShieldPaint, hex.isBroken);

      // Inner highlight
      if (!lowFx && !hex.isBroken) {
        _hexShieldPaint.color = Colors.white.withOpacity(effectiveAlpha * 0.3);
        _drawHexagon(canvas, hex.size * 0.5, _hexShieldPaint, false);
      }

      canvas.restore();
    }
  }

  void _drawHexagon(Canvas canvas, double size, Paint paint, bool broken) {
    _reusablePath.reset();
    final skipSide = broken ? _random.nextInt(6) : -1;

    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final px = math.cos(angle) * size * 0.5;
      final py = math.sin(angle) * size * 0.5;

      if (i == 0) {
        _reusablePath.moveTo(px, py);
      } else if (broken && i == skipSide) {
        // Skip this segment for broken effect
        _reusablePath.moveTo(px, py);
      } else {
        _reusablePath.lineTo(px, py);
      }
    }
    if (!broken) {
      _reusablePath.close();
    }
    canvas.drawPath(_reusablePath, paint);
  }

  void _renderElectricalSparks(Canvas canvas, double fadeOut) {
    for (final spark in _electricalSparks) {
      final alpha = spark.alpha * fadeOut;
      if (alpha <= 0.01) continue;

      final flicker = spark.getFlicker();
      if (flicker < 0.3) continue;

      final x = spark.currentX;
      final y = spark.currentY;

      // Draw arc/streak
      final arcEndX = x + math.cos(spark.arcAngle) * spark.arcLength;
      final arcEndY = y + math.sin(spark.arcAngle) * spark.arcLength;

      // Glow
      if (!lowFx) {
        _sparkGlowPaint.color = spark.color.withOpacity(alpha * 0.4 * flicker);
        canvas.drawCircle(Offset(x, y), spark.size * 2, _sparkGlowPaint);
      }

      // Arc line
      _sparkLinePaint.color = spark.color.withOpacity(alpha * 0.6 * flicker);
      canvas.drawLine(Offset(x, y), Offset(arcEndX, arcEndY), _sparkLinePaint);

      // Core spark
      _sparkPaint.color = Colors.white.withOpacity(alpha * flicker);
      canvas.drawCircle(Offset(x, y), spark.size, _sparkPaint);

      // Secondary spark at arc end
      if (!lowFx && flicker > 0.7) {
        _sparkPaint.color = spark.color.withOpacity(alpha * 0.5 * flicker);
        canvas.drawCircle(Offset(arcEndX, arcEndY), spark.size * 0.6, _sparkPaint);
      }
    }
  }

  void _renderSmokeWisps(Canvas canvas, double fadeOut) {
    for (final smoke in _smokeWisps) {
      final alpha = smoke.alpha * fadeOut;
      if (alpha <= 0.01) continue;

      final x = smoke.currentX;
      final y = smoke.currentY;
      final currentSize = smoke.currentSize;

      // Outer smoke
      _smokePaint.color = Colors.grey.shade700.withOpacity(alpha * 0.3);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: currentSize * 1.3,
          height: currentSize * 0.8,
        ),
        _smokePaint,
      );

      // Inner darker smoke
      _smokeInnerPaint.color = Colors.grey.shade800.withOpacity(alpha * 0.4);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: currentSize * 0.7,
          height: currentSize * 0.5,
        ),
        _smokeInnerPaint,
      );
    }
  }

  void _renderHoloDataFragments(Canvas canvas, double fadeOut) {
    for (final holo in _holoFragments) {
      final alpha = holo.alpha * fadeOut;
      if (alpha <= 0.01) continue;

      final x = holo.currentX;
      final y = holo.currentY;
      final glitchOffset = holo.getGlitchOffset();

      // RGB split effect (chromatic aberration)
      // Red channel
      _holoGlitchPaint.color = const Color(0xFFFF0000).withOpacity(alpha * 0.4);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x - holo.rgbOffset + glitchOffset, y),
          width: holo.size,
          height: holo.size,
        ),
        _holoGlitchPaint,
      );

      // Green channel
      _holoGlitchPaint.color = const Color(0xFF00FF00).withOpacity(alpha * 0.35);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x + glitchOffset * 0.5, y),
          width: holo.size,
          height: holo.size,
        ),
        _holoGlitchPaint,
      );

      // Blue channel
      _holoGlitchPaint.color = const Color(0xFF0000FF).withOpacity(alpha * 0.4);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x + holo.rgbOffset + glitchOffset, y),
          width: holo.size,
          height: holo.size,
        ),
        _holoGlitchPaint,
      );

      // Core glow
      if (!lowFx) {
        _holoFragmentGlowPaint.color = holo.color.withOpacity(alpha * 0.3);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: holo.size * 1.5,
            height: holo.size * 1.5,
          ),
          _holoFragmentGlowPaint,
        );
      }

      // Main fragment
      _holoFragmentPaint.color = holo.color.withOpacity(alpha * 0.7);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, y),
          width: holo.size,
          height: holo.size,
        ),
        _holoFragmentPaint,
      );

      // Scanline effect within fragment
      if (!lowFx && alpha > 0.5) {
        final scanY = y + math.sin(_time * 20 + holo.wobblePhase) * holo.size * 0.3;
        _holoGlitchPaint.color = Colors.white.withOpacity(alpha * 0.2);
        canvas.drawLine(
          Offset(x - holo.size / 2, scanY),
          Offset(x + holo.size / 2, scanY),
          _holoGlitchPaint..strokeWidth = 1,
        );
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

  /// Stop the debris effect (for continuous effects)
  void stop() {
    _recycle();
  }

  /// Update intensity dynamically (useful for damage-based effects)
  void setIntensity(double newIntensity) {
    intensity = newIntensity.clamp(0.0, 2.0);
  }
}

// =============================================================================
// PARTICLE DATA CLASSES
// =============================================================================

/// Layer 1: Small metal/tech fragments floating
class _MetalFragment {
  _MetalFragment({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.lifetime,
    required this.wobblePhase,
    required this.wobbleSpeed,
    required this.wobbleAmount,
    required this.color,
    required this.shape,
  }) : _remainingLife = lifetime,
       currentRotation = rotation;

  double x;
  double y;
  double velocityX;
  double velocityY;
  double size;
  double rotation;
  double rotationSpeed;
  double lifetime;
  double wobblePhase;
  double wobbleSpeed;
  double wobbleAmount;
  Color color;
  int shape;
  double _remainingLife;
  double currentRotation;
  double _wobbleOffset = 0;

  bool get isAlive => _remainingLife > 0;
  double get alpha => (_remainingLife / lifetime).clamp(0.0, 1.0);
  double get currentX => x + _wobbleOffset;
  double get currentY => y;

  void update(double dt, double time) {
    x += velocityX * dt;
    y += velocityY * dt;

    // Slow down
    velocityX *= 0.98;
    velocityY *= 0.995;

    // Wobble side to side
    _wobbleOffset = math.sin(time * wobbleSpeed + wobblePhase) * wobbleAmount;

    // Rotate
    currentRotation += rotationSpeed * dt;

    _remainingLife -= dt;
  }
}

/// Layer 2: Glowing ember particles (hot debris)
class _HotEmber {
  _HotEmber({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.lifetime,
    required this.pulsePhase,
    required this.pulseSpeed,
    required this.wobblePhase,
    required this.wobbleAmount,
    required this.color,
  }) : _remainingLife = lifetime,
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
  double pulseSpeed;
  double wobblePhase;
  double wobbleAmount;
  Color color;
  double _remainingLife;
  double currentPulse;
  double _wobbleOffset = 0;

  final List<double> trailX;
  final List<double> trailY;
  static const int maxTrailLength = 6;

  bool get isAlive => _remainingLife > 0;
  double get alpha => (_remainingLife / lifetime).clamp(0.0, 1.0);
  double get currentX => x + _wobbleOffset;
  double get currentY => y;

  void update(double dt, double time) {
    // Update trail
    if (trailX.length >= maxTrailLength) {
      trailX.removeAt(0);
      trailY.removeAt(0);
    }
    trailX.add(currentX);
    trailY.add(currentY);

    x += velocityX * dt;
    y += velocityY * dt;

    // Slow rising
    velocityY *= 0.995;
    velocityX *= 0.98;

    // Wobble
    _wobbleOffset = math.sin(time * 3 + wobblePhase) * wobbleAmount;

    // Pulse
    currentPulse += dt * pulseSpeed;

    _remainingLife -= dt;
  }
}

/// Layer 3: Hexagonal broken shield pieces
class _HexShieldPiece {
  _HexShieldPiece({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.lifetime,
    required this.wobblePhase,
    required this.wobbleAmount,
    required this.color,
    required this.flickerPhase,
    required this.isBroken,
  }) : _remainingLife = lifetime,
       currentRotation = rotation,
       currentFlicker = flickerPhase;

  double x;
  double y;
  double velocityX;
  double velocityY;
  double size;
  double rotation;
  double rotationSpeed;
  double lifetime;
  double wobblePhase;
  double wobbleAmount;
  Color color;
  double flickerPhase;
  bool isBroken;
  double _remainingLife;
  double currentRotation;
  double currentFlicker;
  double _wobbleOffset = 0;

  bool get isAlive => _remainingLife > 0;
  double get alpha => (_remainingLife / lifetime).clamp(0.0, 1.0);
  double get currentX => x + _wobbleOffset;
  double get currentY => y;

  void update(double dt, double time) {
    x += velocityX * dt;
    y += velocityY * dt;

    velocityY *= 0.995;
    velocityX *= 0.98;

    _wobbleOffset = math.sin(time * 2 + wobblePhase) * wobbleAmount;
    currentRotation += rotationSpeed * dt;
    currentFlicker += dt * 15;

    _remainingLife -= dt;
  }
}

/// Layer 4: Sparking electrical fragments
class _ElectricalSpark {
  _ElectricalSpark({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.lifetime,
    required this.color,
    required this.arcLength,
    required this.arcAngle,
    required this.flickerSpeed,
  }) : _remainingLife = lifetime,
       _flickerTime = 0;

  double x;
  double y;
  double velocityX;
  double velocityY;
  double size;
  double lifetime;
  Color color;
  double arcLength;
  double arcAngle;
  double flickerSpeed;
  double _remainingLife;
  double _flickerTime;

  bool get isAlive => _remainingLife > 0;
  double get alpha => (_remainingLife / lifetime).clamp(0.0, 1.0);
  double get currentX => x;
  double get currentY => y;

  double getFlicker() {
    return 0.5 + math.sin(_flickerTime * flickerSpeed) * 0.5;
  }

  void update(double dt, double time) {
    x += velocityX * dt;
    y += velocityY * dt;

    velocityY *= 0.99;
    velocityX *= 0.99;

    // Randomly change arc direction
    arcAngle += (math.sin(time * 10) * 0.5) * dt;

    _flickerTime += dt;
    _remainingLife -= dt;
  }
}

/// Layer 5: Smoke wisps rising
class _SmokeWisp {
  _SmokeWisp({
    required this.x,
    required this.y,
    required this.velocityY,
    required this.size,
    required this.lifetime,
    required this.driftPhase,
    required this.driftAmount,
    required this.expansionRate,
  }) : _remainingLife = lifetime,
       currentSize = size;

  double x;
  double y;
  double velocityY;
  double size;
  double lifetime;
  double driftPhase;
  double driftAmount;
  double expansionRate;
  double _remainingLife;
  double currentSize;
  double _driftOffset = 0;

  bool get isAlive => _remainingLife > 0;
  double get alpha {
    final life = _remainingLife / lifetime;
    // Fade in and out
    if (life > 0.8) return (1 - life) / 0.2;
    if (life < 0.2) return life / 0.2;
    return 1.0;
  }
  double get currentX => x + _driftOffset;
  double get currentY => y;

  void update(double dt, double time) {
    y += velocityY * dt;
    velocityY *= 0.998;

    // Drift side to side
    _driftOffset = math.sin(time * 0.8 + driftPhase) * driftAmount;

    // Expand over time
    currentSize = size * (1 + (1 - _remainingLife / lifetime) * expansionRate);

    _remainingLife -= dt;
  }
}

/// Layer 6: Holographic data fragments (glitchy squares)
class _HoloDataFragment {
  _HoloDataFragment({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.lifetime,
    required this.wobblePhase,
    required this.wobbleAmount,
    required this.color,
    required this.glitchIntensity,
    required this.glitchSpeed,
    required this.rgbOffset,
  }) : _remainingLife = lifetime,
       _glitchTime = 0;

  double x;
  double y;
  double velocityX;
  double velocityY;
  double size;
  double lifetime;
  double wobblePhase;
  double wobbleAmount;
  Color color;
  double glitchIntensity;
  double glitchSpeed;
  double rgbOffset;
  double _remainingLife;
  double _glitchTime;
  double _wobbleOffset = 0;

  bool get isAlive => _remainingLife > 0;
  double get alpha => (_remainingLife / lifetime).clamp(0.0, 1.0);
  double get currentX => x + _wobbleOffset;
  double get currentY => y;

  double getGlitchOffset() {
    // Random-ish glitch offset
    final glitchValue = math.sin(_glitchTime * glitchSpeed);
    return glitchValue > 0.7 ? glitchIntensity * 3 : 0;
  }

  void update(double dt, double time) {
    x += velocityX * dt;
    y += velocityY * dt;

    velocityY *= 0.995;
    velocityX *= 0.98;

    _wobbleOffset = math.sin(time * 4 + wobblePhase) * wobbleAmount;
    _glitchTime += dt;

    _remainingLife -= dt;
  }
}
