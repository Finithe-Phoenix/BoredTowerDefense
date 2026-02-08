import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../entities/enemy.dart';

/// Energy overload explosion effect for tower destruction.
/// Creates a dramatic multi-layered explosion with:
/// - Layer 1: Central energy core collapse (bright flash imploding)
/// - Layer 2: Shockwave ring expanding outward
/// - Layer 3: Electric arcs bursting in all directions
/// - Layer 4: Debris chunks flying outward with trails
/// - Layer 5: Energy tendrils whipping around
/// - Layer 6: Holographic glitch distortion
/// - Layer 7: Final EMP pulse wave
class TowerDestructionEffect extends PositionComponent {
  TowerDestructionEffect._internal({
    required Vector2 position,
    required Color color,
    required double explosionSize,
    required double duration,
  }) {
    _reset(
      position: position,
      color: color,
      explosionSize: explosionSize,
      duration: duration,
    );
  }

  static const int maxPool = 8;
  static const int maxActive = 4;
  static final List<TowerDestructionEffect> _pool = [];
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

  static TowerDestructionEffect? spawn({
    required Vector2 position,
    required Color color,
    double explosionSize = 50.0,
    double duration = 1.5,
  }) {
    if (_activeCount >= maxActive) return null;
    TowerDestructionEffect effect;
    if (_pool.isNotEmpty) {
      effect = _pool.removeLast();
      effect._reset(
        position: position,
        color: color,
        explosionSize: explosionSize,
        duration: duration,
      );
    } else {
      effect = TowerDestructionEffect._internal(
        position: position,
        color: color,
        explosionSize: explosionSize,
        duration: duration,
      );
    }
    effect._markActive();
    return effect;
  }

  Color color = Colors.cyan;
  double explosionSize = 50.0;
  double duration = 1.5;

  // Particle collections for each layer
  final List<_ElectricArc> _electricArcs = [];
  final List<_DebrisChunk> _debrisChunks = [];
  final List<_EnergyTendril> _energyTendrils = [];
  final List<_GlitchFragment> _glitchFragments = [];
  final List<_ShockwaveRing> _shockwaveRings = [];

  double _time = 0;
  int _rngState = 0x7f4a7c15;
  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }

  double _nextUnit() => _lcgNext() / 0x7fffffff;
  int _nextInt(int max) => max <= 0 ? 0 : _lcgNext() % max;
  bool _nextBool() => (_lcgNext() & 1) == 0;
  bool _counted = false;
  bool _inPool = false;
  double _offscreenAccumulator = 0;
  static const double _offscreenUpdateInterval = 0.12;

  // Layer 1: Core collapse properties
  double _coreRadius = 0;
  double _coreIntensity = 1.0;
  bool _coreImploding = true;

  // Layer 7: EMP pulse properties
  double _empRadius = 0;
  double _empIntensity = 0;
  bool _empTriggered = false;

  // Screen shake intensity (can be read by parent)
  double get shakeIntensity => _coreIntensity * 0.5 + _empIntensity * 0.8;

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════

  // Layer 1: Core collapse paints
  final Paint _coreOuterGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
  final Paint _coreMidGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  final Paint _coreInnerPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _coreWhitePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  final Paint _coreRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  // Layer 2: Shockwave paints
  final Paint _shockwaveOuterPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  final Paint _shockwaveMidPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  final Paint _shockwaveInnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final Paint _shockwaveDistortPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  // Layer 3: Electric arc paints
  final Paint _arcGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  final Paint _arcCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _arcSparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  // Layer 4: Debris paints
  final Paint _debrisGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  final Paint _debrisFillPaint = Paint();
  final Paint _debrisTrailPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  final Paint _debrisSparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
  final Path _debrisPath = Path();
  static final List<Offset> _unitHex =
      List<Offset>.unmodifiable(_buildUnitHex());

  static List<Offset> _buildUnitHex() {
    final points = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      points.add(Offset(math.cos(angle), math.sin(angle)));
    }
    return points;
  }

  // Layer 5: Energy tendril paints
  final Paint _tendrilGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  final Paint _tendrilCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _tendrilTipPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  // Layer 6: Holographic glitch paints
  final Paint _glitchRectPaint = Paint();
  final Paint _glitchLinePaint = Paint()..strokeWidth = 1;
  final Paint _glitchScanlinePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
  final Paint _glitchNoisePaint = Paint();

  // Layer 7: EMP pulse paints
  final Paint _empOuterPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 12
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  final Paint _empMidPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  final Paint _empInnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _empFlashPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
  final Paint _empArcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  // Reusable paths
  final Path _reusablePath = Path();

  void _markActive() {
    if (_counted) return;
    _counted = true;
    _inPool = false;
    _activeCount++;
  }

  void _reset({
    required Vector2 position,
    required Color color,
    required double explosionSize,
    required double duration,
  }) {
    this.position.setFrom(position);
    anchor = Anchor.center;
    this.color = color;
    this.explosionSize = explosionSize;
    this.duration = duration;
    _rngState = (position.hashCode ^
            color.value ^
            (explosionSize * 1000).round() ^
            0x7f4a7c15) &
        0x7fffffff;
    _time = 0;
    _coreRadius = explosionSize * 0.4;
    _coreIntensity = 1.0;
    _coreImploding = true;
    _empRadius = 0;
    _empIntensity = 0;
    _empTriggered = false;
    _electricArcs.clear();
    _debrisChunks.clear();
    _energyTendrils.clear();
    _glitchFragments.clear();
    _shockwaveRings.clear();
    _initializeElectricArcs();
    _initializeDebris();
    _initializeEnergyTendrils();
    _initializeGlitchFragments();
    _initializeShockwaves();
  }

  void _initializeElectricArcs() {
    final arcCount = _scaledCount(12, allowZero: true);
    if (arcCount == 0) return;

    for (int i = 0; i < arcCount; i++) {
      final angle = (i / arcCount) * math.pi * 2 + _nextUnit() * 0.4;
      final length = explosionSize * (0.6 + _nextUnit() * 0.8);

      _electricArcs.add(_ElectricArc(
        angle: angle,
        length: length,
        width: 1.5 + _nextUnit() * 2.5,
        lifetime: 0.2 + _nextUnit() * 0.3,
        delay: _nextUnit() * 0.15,
        segments: 5 + _nextInt(4),
        branchCount: _nextInt(3),
        flickerSpeed: 15 + _nextUnit() * 20,
      ));
    }
  }

  void _initializeDebris() {
    final debrisCount = _scaledCount(20, allowZero: true);
    if (debrisCount == 0) return;

    for (int i = 0; i < debrisCount; i++) {
      final angle = _nextUnit() * math.pi * 2;
      final speed = 60 + _nextUnit() * 120;
      final shapeType = _nextInt(
          5); // 0=square, 1=triangle, 2=hexShard, 3=circuitChunk, 4=energyFragment

      _debrisChunks.add(_DebrisChunk(
        angle: angle,
        speed: speed,
        size: 3 + _nextUnit() * 5,
        rotation: _nextUnit() * math.pi * 2,
        rotationSpeed: (_nextUnit() - 0.5) * 25,
        lifetime: 0.6 + _nextUnit() * 0.6,
        delay: _nextUnit() * 0.1,
        shape: shapeType,
        gravity: 40 + _nextUnit() * 30,
        hasTrail: shapeType >= 2,
        glowIntensity: 0.4 + _nextUnit() * 0.5,
        isEnergized: shapeType == 4,
      ));
    }

    // Add larger dramatic chunks
    final largeCount = _scaledCount(6, allowZero: true);
    for (int i = 0; i < largeCount; i++) {
      final angle = (i / largeCount) * math.pi * 2 + _nextUnit() * 0.5;
      _debrisChunks.add(_DebrisChunk(
        angle: angle,
        speed: 40 + _nextUnit() * 60,
        size: 6 + _nextUnit() * 4,
        rotation: _nextUnit() * math.pi * 2,
        rotationSpeed: (_nextUnit() - 0.5) * 15,
        lifetime: 0.8 + _nextUnit() * 0.4,
        delay: 0.05,
        shape: 3, // Circuit chunk
        gravity: 30 + _nextUnit() * 20,
        hasTrail: true,
        glowIntensity: 0.7,
        isEnergized: true,
      ));
    }
  }

  void _initializeEnergyTendrils() {
    final tendrilCount = _scaledCount(8, allowZero: true);
    if (tendrilCount == 0) return;

    for (int i = 0; i < tendrilCount; i++) {
      final angle = (i / tendrilCount) * math.pi * 2 + _nextUnit() * 0.3;

      _energyTendrils.add(_EnergyTendril(
        startAngle: angle,
        length: explosionSize * (0.5 + _nextUnit() * 0.6),
        width: 2 + _nextUnit() * 3,
        lifetime: 0.4 + _nextUnit() * 0.4,
        delay: 0.1 + _nextUnit() * 0.1,
        waveFrequency: 3 + _nextUnit() * 4,
        waveAmplitude: 8 + _nextUnit() * 12,
        whipSpeed: 8 + _nextUnit() * 6,
        segments: 8 + _nextInt(4),
      ));
    }
  }

  void _initializeGlitchFragments() {
    final glitchCount = _scaledCount(16, allowZero: true);
    if (glitchCount == 0) return;

    for (int i = 0; i < glitchCount; i++) {
      _glitchFragments.add(_GlitchFragment(
        x: (_nextUnit() - 0.5) * explosionSize * 2,
        y: (_nextUnit() - 0.5) * explosionSize * 2,
        width: 5 + _nextUnit() * 20,
        height: 2 + _nextUnit() * 8,
        lifetime: 0.1 + _nextUnit() * 0.2,
        delay: _nextUnit() * 0.5,
        flickerSpeed: 20 + _nextUnit() * 30,
        rgbOffset: 2 + _nextUnit() * 4,
        isHorizontal: _nextBool(),
      ));
    }
  }

  void _initializeShockwaves() {
    // Multiple shockwave rings with different timings
    _shockwaveRings.add(_ShockwaveRing(
      delay: 0,
      maxRadius: explosionSize * 2.5,
      duration: 0.5,
      thickness: 1.0,
    ));
    _shockwaveRings.add(_ShockwaveRing(
      delay: 0.08,
      maxRadius: explosionSize * 2.0,
      duration: 0.4,
      thickness: 0.7,
    ));
    _shockwaveRings.add(_ShockwaveRing(
      delay: 0.15,
      maxRadius: explosionSize * 1.6,
      duration: 0.35,
      thickness: 0.5,
    ));
  }

  int _scaledCount(int base, {bool allowZero = false}) {
    final scaled = (base * fxScale).round();
    if (scaled <= 0 && !allowZero) {
      return 1;
    }
    return scaled;
  }

  double _alpha(double value) {
    if (value <= 0) return 0;
    if (value >= 1) return 1;
    return value;
  }

  /// Get HSL-shifted color for visual variety
  Color _getSecondaryColor(double hueShift) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withHue((hsl.hue + hueShift) % 360).toColor();
  }

  Color _getTertiaryColor(double saturationMult, double lightnessMult) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation((hsl.saturation * saturationMult).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * lightnessMult).clamp(0.0, 1.0))
        .toColor();
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

    // Layer 1: Core collapse animation
    _updateCoreCollapse(progress);

    // Layer 7: EMP pulse trigger at ~70% through
    if (progress > 0.7 && !_empTriggered) {
      _empTriggered = true;
    }
    _updateEmpPulse(progress);

    // Update particles
    if (_electricArcs.isNotEmpty) {
      for (final arc in _electricArcs) {
        arc.update(dt);
      }
    }
    if (_debrisChunks.isNotEmpty) {
      for (final chunk in _debrisChunks) {
        chunk.update(dt);
      }
    }
    if (_energyTendrils.isNotEmpty) {
      for (final tendril in _energyTendrils) {
        tendril.update(dt);
      }
    }
    if (_glitchFragments.isNotEmpty) {
      for (final glitch in _glitchFragments) {
        glitch.update(dt);
      }
    }
    if (_shockwaveRings.isNotEmpty) {
      for (final wave in _shockwaveRings) {
        wave.update(dt);
      }
    }
  }

  void _updateCoreCollapse(double progress) {
    if (progress < 0.2) {
      // Initial flash and implosion
      _coreImploding = true;
      final impProgress = progress / 0.2;
      _coreRadius = explosionSize * 0.4 * (1 - impProgress * 0.7);
      _coreIntensity = 1.0 + impProgress * 0.5;
    } else if (progress < 0.3) {
      // Explosion outward
      _coreImploding = false;
      final expProgress = (progress - 0.2) / 0.1;
      _coreRadius = explosionSize * 0.12 + expProgress * explosionSize * 0.6;
      _coreIntensity = 1.5 - expProgress * 0.5;
    } else {
      // Fade out
      final fadeProgress = (progress - 0.3) / 0.7;
      _coreRadius = explosionSize * 0.72 * (1 - fadeProgress * 0.3);
      _coreIntensity = math.max(0, 1.0 - fadeProgress * 1.5);
    }
  }

  void _updateEmpPulse(double progress) {
    if (!_empTriggered) {
      _empIntensity = 0;
      return;
    }

    final empProgress = (progress - 0.7) / 0.3;
    _empRadius = empProgress * explosionSize * 4;
    _empIntensity = math.max(0, 1.0 - empProgress * 1.2);
  }

  @override
  void render(Canvas canvas) {
    if (_isOffscreen()) return;
    super.render(canvas);

    if (lowFx) {
      _renderLowFx(canvas);
      return;
    }

    final progress = _time / duration;
    if (progress >= 1.0) return;
    if (_coreIntensity <= 0.01 &&
        _empIntensity <= 0.01 &&
        _electricArcs.isEmpty &&
        _debrisChunks.isEmpty &&
        _energyTendrils.isEmpty &&
        _glitchFragments.isEmpty &&
        _shockwaveRings.isEmpty) {
      return;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 6: Holographic glitch distortion (behind everything)
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx) {
      _drawHolographicGlitch(canvas, progress);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 2: Shockwave rings
    // ═══════════════════════════════════════════════════════════════════════
    _drawShockwaves(canvas, progress);

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 5: Energy tendrils
    // ═══════════════════════════════════════════════════════════════════════
    _drawEnergyTendrils(canvas, progress);

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 3: Electric arcs
    // ═══════════════════════════════════════════════════════════════════════
    _drawElectricArcs(canvas, progress);

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 4: Debris chunks
    // ═══════════════════════════════════════════════════════════════════════
    _drawDebris(canvas, progress);

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 1: Central energy core collapse
    // ═══════════════════════════════════════════════════════════════════════
    _drawCoreCollapse(canvas, progress);

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 7: Final EMP pulse wave
    // ═══════════════════════════════════════════════════════════════════════
    if (_empTriggered) {
      _drawEmpPulse(canvas, progress);
    }
  }

  bool _isOffscreen({double padding = 110}) {
    if (Enemy.screenSize.isZero()) return false;
    if (Enemy.screenScale <= 0) return false;
    final screenX = Enemy.screenOffset.x + position.x * Enemy.screenScale;
    final screenY = Enemy.screenOffset.y + position.y * Enemy.screenScale;
    return screenX < -padding ||
        screenY < -padding ||
        screenX > Enemy.screenSize.x + padding ||
        screenY > Enemy.screenSize.y + padding;
  }

  void _renderLowFx(Canvas canvas) {
    // Simplified rendering for low-end devices
    final progress = _time / duration;
    final fadeOut = 1.0 - progress;

    // Simple expanding circle
    _coreOuterGlowPaint.color = color.withOpacity(fadeOut * 0.4);
    canvas.drawCircle(Offset.zero, explosionSize * (0.5 + progress * 0.5),
        _coreOuterGlowPaint);

    // Core flash
    if (progress < 0.3) {
      _coreWhitePaint.color =
          Colors.white.withOpacity((1 - progress / 0.3) * 0.8);
      canvas.drawCircle(
          Offset.zero, explosionSize * 0.3 * (1 - progress), _coreWhitePaint);
    }

    // Simple shockwave ring
    if (progress < 0.5) {
      final ringProgress = progress / 0.5;
      _shockwaveMidPaint
        ..color = color.withOpacity((1 - ringProgress) * 0.6)
        ..strokeWidth = 3;
      canvas.drawCircle(
          Offset.zero, explosionSize * 2 * ringProgress, _shockwaveMidPaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Layer 1: Central energy core collapse
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawCoreCollapse(Canvas canvas, double progress) {
    if (_coreIntensity <= 0) return;

    final secondaryColor = _getSecondaryColor(30);
    final tertiaryColor = _getTertiaryColor(1.2, 1.3);

    // Outer energy glow
    _coreOuterGlowPaint.color = color.withOpacity(_alpha(_coreIntensity * 0.3));
    canvas.drawCircle(Offset.zero, _coreRadius * 1.5, _coreOuterGlowPaint);

    // Mid glow with secondary color
    _coreMidGlowPaint.color = secondaryColor.withOpacity(
      _alpha(_coreIntensity * 0.5),
    );
    canvas.drawCircle(Offset.zero, _coreRadius, _coreMidGlowPaint);

    // Inner bright core
    _coreInnerPaint.color = tertiaryColor.withOpacity(
      _alpha(_coreIntensity * 0.7),
    );
    canvas.drawCircle(Offset.zero, _coreRadius * 0.6, _coreInnerPaint);

    // White hot center
    _coreWhitePaint.color = Colors.white.withOpacity(
      _alpha(_coreIntensity * 0.9),
    );
    canvas.drawCircle(Offset.zero, _coreRadius * 0.25, _coreWhitePaint);

    // Pulsing rings during implosion
    if (_coreImploding && !reduceFx) {
      final ringCount = 3;
      for (int i = 0; i < ringCount; i++) {
        final ringOffset = ((_time * 10 + i * 0.3) % 1.0);
        final ringRadius = _coreRadius * (0.5 + ringOffset * 1.5);
        final ringAlpha = (1 - ringOffset) * _coreIntensity * 0.4;

        _coreRingPaint.color = color.withOpacity(_alpha(ringAlpha));
        canvas.drawCircle(Offset.zero, ringRadius, _coreRingPaint);
      }
    }

    // Energy suction lines during implosion
    if (_coreImploding && !reduceFx) {
      final lineCount = 8;
      for (int i = 0; i < lineCount; i++) {
        final angle = (i / lineCount) * math.pi * 2 + _time * 3;
        final startDist = explosionSize * 0.8;
        final endDist = _coreRadius * 0.5;

        final startX = math.cos(angle) * startDist;
        final startY = math.sin(angle) * startDist;
        final endX = math.cos(angle) * endDist;
        final endY = math.sin(angle) * endDist;

        _coreRingPaint.color = color.withOpacity(_alpha(_coreIntensity * 0.3));
        canvas.drawLine(
            Offset(startX, startY), Offset(endX, endY), _coreRingPaint);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Layer 2: Shockwave rings
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawShockwaves(Canvas canvas, double progress) {
    if (_shockwaveRings.isEmpty) return;
    final secondaryColor = _getSecondaryColor(-20);

    for (final wave in _shockwaveRings) {
      if (!wave.isActive) continue;

      final waveAlpha = wave.alphaValue;
      if (waveAlpha <= 0) continue;

      final radius = wave.currentRadius;

      // Outer distortion glow
      _shockwaveDistortPaint.color =
          color.withOpacity(waveAlpha * 0.2 * wave.thickness);
      canvas.drawCircle(Offset.zero, radius, _shockwaveDistortPaint);

      // Main colored ring
      _shockwaveOuterPaint
        ..color = color.withOpacity(waveAlpha * 0.6 * wave.thickness)
        ..strokeWidth = 6 * wave.thickness;
      canvas.drawCircle(Offset.zero, radius, _shockwaveOuterPaint);

      // Secondary color ring
      _shockwaveMidPaint
        ..color = secondaryColor.withOpacity(waveAlpha * 0.5 * wave.thickness)
        ..strokeWidth = 3 * wave.thickness;
      canvas.drawCircle(Offset.zero, radius * 0.95, _shockwaveMidPaint);

      // Inner white edge
      _shockwaveInnerPaint
        ..color = Colors.white.withOpacity(waveAlpha * 0.7 * wave.thickness)
        ..strokeWidth = 1.5 * wave.thickness;
      canvas.drawCircle(Offset.zero, radius * 0.9, _shockwaveInnerPaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Layer 3: Electric arcs
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawElectricArcs(Canvas canvas, double progress) {
    if (_electricArcs.isEmpty) return;
    final secondaryColor = _getSecondaryColor(40);

    for (final arc in _electricArcs) {
      if (!arc.isActive) continue;

      final alpha = arc.alphaValue;
      if (alpha <= 0) continue;

      // Calculate flicker
      final flicker = arc.getFlicker(_time);

      // Build the arc path with zigzag
      _reusablePath.reset();
      _reusablePath.moveTo(0, 0);

      final endX = arc.dirX * arc.length * arc.extensionProgress;
      final endY = arc.dirY * arc.length * arc.extensionProgress;

      // Add zigzag segments
      var prevX = 0.0;
      var prevY = 0.0;
      for (int i = 1; i <= arc.segments; i++) {
        final t = i / arc.segments;
        final baseX = endX * t;
        final baseY = endY * t;

        // Random perpendicular offset
        final offsetMag =
            (i == arc.segments) ? 0.0 : (_nextUnit() - 0.5) * 15 * flicker;
        final perpX = arc.perpX * offsetMag;
        final perpY = arc.perpY * offsetMag;

        final segX = baseX + perpX;
        final segY = baseY + perpY;
        _reusablePath.lineTo(segX, segY);

        // Draw branches at certain segments
        if (arc.branchCount > 0 && i == arc.segments ~/ 2) {
          for (int b = 0; b < arc.branchCount; b++) {
            final branchAngle = arc.angle + (b - arc.branchCount / 2) * 0.6;
            final branchLen = arc.length * 0.3;
            final branchEndX = segX + math.cos(branchAngle) * branchLen;
            final branchEndY = segY + math.sin(branchAngle) * branchLen;

            _arcCorePaint
              ..color = secondaryColor.withOpacity(alpha * 0.5 * flicker)
              ..strokeWidth = arc.width * 0.5;
            canvas.drawLine(
              Offset(segX, segY),
              Offset(branchEndX, branchEndY),
              _arcCorePaint,
            );
          }
        }

        prevX = segX;
        prevY = segY;
      }

      // Draw arc glow
      _arcGlowPaint
        ..color = color.withOpacity(alpha * 0.4 * flicker)
        ..strokeWidth = arc.width * 2;
      canvas.drawPath(_reusablePath, _arcGlowPaint);

      // Draw arc core
      _arcCorePaint
        ..color = Colors.white.withOpacity(alpha * 0.9 * flicker)
        ..strokeWidth = arc.width;
      canvas.drawPath(_reusablePath, _arcCorePaint);

      // Spark at the tip
      if (arc.extensionProgress > 0.5) {
        final tipX = endX;
        final tipY = endY;
        _arcSparkPaint.color = Colors.white.withOpacity(alpha * 0.8 * flicker);
        canvas.drawCircle(Offset(tipX, tipY), 3 * flicker, _arcSparkPaint);

        _arcSparkPaint.color = color.withOpacity(alpha * 0.5 * flicker);
        canvas.drawCircle(Offset(tipX, tipY), 5 * flicker, _arcSparkPaint);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Layer 4: Debris chunks
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawDebris(Canvas canvas, double progress) {
    if (_debrisChunks.isEmpty) return;
    final secondaryColor = _getSecondaryColor(20);

    for (final chunk in _debrisChunks) {
      if (!chunk.isActive) continue;

      final alpha = chunk.alphaValue;
      if (alpha <= 0) continue;

      final x = chunk.currentX;
      final y = chunk.currentY;

      // Draw trail
      if (chunk.hasTrail && chunk.distance > 5) {
        final trailStartX = chunk.dirX * (chunk.distance - chunk.speed * 0.05);
        final trailStartY = chunk.dirY * (chunk.distance - chunk.speed * 0.05) +
            chunk.fallOffset * 0.9;

        _debrisTrailPaint
          ..color = (chunk.isEnergized ? color : secondaryColor)
              .withOpacity(alpha * 0.4)
          ..strokeWidth = chunk.size * 0.5;
        canvas.drawLine(
            Offset(trailStartX, trailStartY), Offset(x, y), _debrisTrailPaint);
      }

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(chunk.currentRotation);

      // Glow for energized debris
      if (chunk.isEnergized && !reduceFx) {
        _debrisGlowPaint.color = color.withOpacity(alpha * chunk.glowIntensity);
        canvas.drawCircle(Offset.zero, chunk.size * 1.5, _debrisGlowPaint);
      }

      _debrisFillPaint.color =
          (chunk.isEnergized ? color : secondaryColor).withOpacity(alpha * 0.8);

      switch (chunk.shape) {
        case 0: // Square
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero, width: chunk.size, height: chunk.size),
            _debrisFillPaint,
          );
          break;

        case 1: // Triangle
          _debrisPath.reset();
          _debrisPath.moveTo(0, -chunk.size / 2);
          _debrisPath.lineTo(-chunk.size / 2, chunk.size / 2);
          _debrisPath.lineTo(chunk.size / 2, chunk.size / 2);
          _debrisPath.close();
          canvas.drawPath(_debrisPath, _debrisFillPaint);
          break;

        case 2: // Hex shard
          _debrisPath.reset();
          for (int i = 0; i < _unitHex.length; i++) {
            final px = _unitHex[i].dx * chunk.size * 0.5;
            final py = _unitHex[i].dy * chunk.size * 0.5;
            if (i == 0) {
              _debrisPath.moveTo(px, py);
            } else {
              _debrisPath.lineTo(px, py);
            }
          }
          _debrisPath.close();
          canvas.drawPath(_debrisPath, _debrisFillPaint);
          // Inner highlight
          _debrisFillPaint.color = Colors.white.withOpacity(alpha * 0.4);
          canvas.drawCircle(Offset.zero, chunk.size * 0.15, _debrisFillPaint);
          break;

        case 3: // Circuit chunk (rectangle with notches)
          _debrisPath.reset();
          final w = chunk.size;
          final h = chunk.size * 0.6;
          _debrisPath.moveTo(-w / 2, -h / 2);
          _debrisPath.lineTo(-w / 4, -h / 2);
          _debrisPath.lineTo(-w / 4, -h / 2 - 2);
          _debrisPath.lineTo(w / 4, -h / 2 - 2);
          _debrisPath.lineTo(w / 4, -h / 2);
          _debrisPath.lineTo(w / 2, -h / 2);
          _debrisPath.lineTo(w / 2, h / 2);
          _debrisPath.lineTo(-w / 2, h / 2);
          _debrisPath.close();
          canvas.drawPath(_debrisPath, _debrisFillPaint);
          // Circuit lines
          _glitchLinePaint.color = Colors.white.withOpacity(alpha * 0.3);
          canvas.drawLine(
              Offset(-w / 3, 0), Offset(w / 3, 0), _glitchLinePaint);
          break;

        case 4: // Energy fragment (diamond with glow)
          _debrisPath.reset();
          _debrisPath.moveTo(0, -chunk.size * 0.7);
          _debrisPath.lineTo(chunk.size * 0.35, 0);
          _debrisPath.lineTo(0, chunk.size * 0.5);
          _debrisPath.lineTo(-chunk.size * 0.35, 0);
          _debrisPath.close();
          canvas.drawPath(_debrisPath, _debrisFillPaint);
          // Bright core
          _debrisFillPaint.color = Colors.white.withOpacity(alpha * 0.6);
          canvas.drawCircle(Offset.zero, chunk.size * 0.15, _debrisFillPaint);
          break;
      }

      canvas.restore();

      // Trailing spark for energized debris
      if (chunk.isEnergized && !reduceFx && alpha > 0.3) {
        final sparkX = x + math.sin(_time * 15 + chunk.angle * 5) * 2;
        final sparkY = y + math.cos(_time * 15 + chunk.angle * 5) * 2;
        _debrisSparkPaint.color = Colors.white.withOpacity(alpha * 0.5);
        canvas.drawCircle(Offset(sparkX, sparkY), 1.5, _debrisSparkPaint);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Layer 5: Energy tendrils
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawEnergyTendrils(Canvas canvas, double progress) {
    if (_energyTendrils.isEmpty) return;
    final secondaryColor = _getSecondaryColor(-30);

    for (final tendril in _energyTendrils) {
      if (!tendril.isActive) continue;

      final alpha = tendril.alphaValue;
      if (alpha <= 0) continue;

      final currentLength = tendril.length * tendril.extensionProgress;
      final baseAngle = tendril.currentAngle;
      final baseDirX = math.cos(baseAngle);
      final baseDirY = math.sin(baseAngle);
      final basePerpX = -baseDirY;
      final basePerpY = baseDirX;

      _reusablePath.reset();
      _reusablePath.moveTo(0, 0);

      // Build wavy tendril path
      var prevX = 0.0;
      var prevY = 0.0;
      for (int i = 1; i <= tendril.segments; i++) {
        final t = i / tendril.segments;
        final segLength = currentLength * t;

        // Base position along tendril
        final baseX = baseDirX * segLength;
        final baseY = baseDirY * segLength;

        // Wave offset perpendicular to tendril
        final wavePhase =
            t * tendril.waveFrequency * math.pi + _time * tendril.whipSpeed;
        final waveOffset = math.sin(wavePhase) * tendril.waveAmplitude * t;
        final perpX = basePerpX * waveOffset;
        final perpY = basePerpY * waveOffset;

        final segX = baseX + perpX;
        final segY = baseY + perpY;

        if (i == 1) {
          _reusablePath.quadraticBezierTo(
            (prevX + segX) / 2,
            (prevY + segY) / 2,
            segX,
            segY,
          );
        } else {
          _reusablePath.lineTo(segX, segY);
        }

        prevX = segX;
        prevY = segY;
      }

      // Draw tendril glow
      _tendrilGlowPaint
        ..color = color.withOpacity(alpha * 0.3)
        ..strokeWidth = tendril.width * 2.5;
      canvas.drawPath(_reusablePath, _tendrilGlowPaint);

      // Draw tendril core
      _tendrilCorePaint
        ..color = secondaryColor.withOpacity(alpha * 0.7)
        ..strokeWidth = tendril.width;
      canvas.drawPath(_reusablePath, _tendrilCorePaint);

      // White center line
      _tendrilCorePaint
        ..color = Colors.white.withOpacity(alpha * 0.5)
        ..strokeWidth = tendril.width * 0.4;
      canvas.drawPath(_reusablePath, _tendrilCorePaint);

      // Glowing tip
      if (tendril.extensionProgress > 0.3) {
        _tendrilTipPaint.color = Colors.white.withOpacity(alpha * 0.8);
        canvas.drawCircle(
            Offset(prevX, prevY), tendril.width, _tendrilTipPaint);

        _tendrilTipPaint.color = color.withOpacity(alpha * 0.5);
        canvas.drawCircle(
            Offset(prevX, prevY), tendril.width * 2, _tendrilTipPaint);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Layer 6: Holographic glitch distortion
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawHolographicGlitch(Canvas canvas, double progress) {
    if (_glitchFragments.isEmpty) return;
    if (progress > 0.7) return; // Glitch fades out

    final glitchIntensity = (1 - progress / 0.7);

    // Draw glitch fragments
    for (final glitch in _glitchFragments) {
      if (!glitch.isActive) continue;

      final alpha = glitch.alphaValue * glitchIntensity;
      if (alpha <= 0) continue;

      final flicker = glitch.getFlicker(_time);
      if (flicker < 0.3) continue; // Skip if flickered off

      // RGB split offset
      final offset = glitch.rgbOffset;

      // Red channel
      _glitchRectPaint.color =
          const Color(0xFFFF0000).withOpacity(alpha * 0.4 * flicker);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(glitch.x - offset, glitch.y),
          width: glitch.width,
          height: glitch.height,
        ),
        _glitchRectPaint,
      );

      // Green channel (center)
      _glitchRectPaint.color =
          const Color(0xFF00FF00).withOpacity(alpha * 0.35 * flicker);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(glitch.x, glitch.y),
          width: glitch.width,
          height: glitch.height,
        ),
        _glitchRectPaint,
      );

      // Blue channel
      _glitchRectPaint.color =
          const Color(0xFF0000FF).withOpacity(alpha * 0.4 * flicker);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(glitch.x + offset, glitch.y),
          width: glitch.width,
          height: glitch.height,
        ),
        _glitchRectPaint,
      );
    }

    // Scanline effect
    if (glitchIntensity > 0.3) {
      final scanlineCount = (8 * glitchIntensity).ceil();
      for (int i = 0; i < scanlineCount; i++) {
        final scanY = math.sin(_time * 25 + i * 4) * explosionSize;
        final scanAlpha =
            glitchIntensity * 0.2 * math.sin(_time * 30 + i * 2).abs();

        _glitchScanlinePaint.color = color.withOpacity(scanAlpha);
        canvas.drawLine(
          Offset(-explosionSize * 1.5, scanY),
          Offset(explosionSize * 1.5, scanY),
          _glitchScanlinePaint..strokeWidth = 1 + _nextUnit(),
        );
      }
    }

    // Digital noise
    if (glitchIntensity > 0.5) {
      final noiseCount = (15 * glitchIntensity).ceil();
      for (int i = 0; i < noiseCount; i++) {
        final nx = (math.sin(_time * 35 + i * 9) * 0.5) * explosionSize * 1.5;
        final ny = (math.cos(_time * 30 + i * 7) * 0.5) * explosionSize * 1.5;
        final noiseSize = 1 + _nextUnit() * 3;

        final noiseColor = _nextInt(3) == 0
            ? const Color(0xFFFF0000)
            : _nextInt(2) == 0
                ? const Color(0xFF00FF00)
                : const Color(0xFF0000FF);

        _glitchNoisePaint.color = noiseColor.withOpacity(glitchIntensity * 0.3);
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(nx, ny), width: noiseSize, height: noiseSize),
          _glitchNoisePaint,
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Layer 7: Final EMP pulse wave
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawEmpPulse(Canvas canvas, double progress) {
    if (_empIntensity <= 0) return;

    final secondaryColor = _getSecondaryColor(60);

    // Bright flash at center when triggered
    if (progress < 0.75) {
      final flashIntensity = (0.75 - progress) / 0.05;
      _empFlashPaint.color =
          Colors.white.withOpacity(flashIntensity.clamp(0.0, 1.0) * 0.8);
      canvas.drawCircle(Offset.zero, explosionSize * 0.5, _empFlashPaint);

      _empFlashPaint.color =
          color.withOpacity(flashIntensity.clamp(0.0, 1.0) * 0.5);
      canvas.drawCircle(Offset.zero, explosionSize * 0.8, _empFlashPaint);
    }

    // Main EMP ring - outer glow
    _empOuterPaint.color = color.withOpacity(_empIntensity * 0.4);
    canvas.drawCircle(Offset.zero, _empRadius, _empOuterPaint);

    // Mid ring
    _empMidPaint
      ..color = secondaryColor.withOpacity(_empIntensity * 0.6)
      ..strokeWidth = 4;
    canvas.drawCircle(Offset.zero, _empRadius * 0.95, _empMidPaint);

    // Inner bright edge
    _empInnerPaint
      ..color = Colors.white.withOpacity(_empIntensity * 0.8)
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, _empRadius * 0.9, _empInnerPaint);

    // Electric arcs along the EMP wave
    if (!reduceFx && _empIntensity > 0.3) {
      final arcCount = 12;
      for (int i = 0; i < arcCount; i++) {
        final angle = (i / arcCount) * math.pi * 2 + _time * 5;
        final arcStartRadius = _empRadius * 0.85;
        final arcEndRadius = _empRadius * 1.1;

        final startX = math.cos(angle) * arcStartRadius;
        final startY = math.sin(angle) * arcStartRadius;
        final endX = math.cos(angle) * arcEndRadius;
        final endY = math.sin(angle) * arcEndRadius;

        // Add some zigzag
        final midX = (startX + endX) / 2 + math.sin(_time * 20 + i) * 5;
        final midY = (startY + endY) / 2 + math.cos(_time * 20 + i) * 5;

        _reusablePath.reset();
        _reusablePath.moveTo(startX, startY);
        _reusablePath.lineTo(midX, midY);
        _reusablePath.lineTo(endX, endY);

        _empArcPaint.color = Colors.white.withOpacity(_empIntensity * 0.6);
        canvas.drawPath(_reusablePath, _empArcPaint);
      }
    }

    // Secondary EMP ring (smaller, trails behind)
    if (_empRadius > explosionSize) {
      final secondaryRadius = _empRadius * 0.7;
      final secondaryAlpha = _empIntensity * 0.3;

      _empMidPaint
        ..color = color.withOpacity(secondaryAlpha)
        ..strokeWidth = 2;
      canvas.drawCircle(Offset.zero, secondaryRadius, _empMidPaint);
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

// ═══════════════════════════════════════════════════════════════════════════
// PARTICLE CLASSES
// ═══════════════════════════════════════════════════════════════════════════

/// Electric arc that bursts outward from the explosion
class _ElectricArc {
  _ElectricArc({
    required this.angle,
    required this.length,
    required this.width,
    required this.lifetime,
    required this.delay,
    required this.segments,
    required this.branchCount,
    required this.flickerSpeed,
  })  : dirX = math.cos(angle),
        dirY = math.sin(angle),
        perpX = -math.sin(angle),
        perpY = math.cos(angle),
        _time = 0;

  final double angle;
  final double length;
  final double width;
  final double lifetime;
  final double delay;
  final int segments;
  final int branchCount;
  final double flickerSpeed;
  final double dirX;
  final double dirY;
  final double perpX;
  final double perpY;

  double _time;

  bool get isActive => _time > delay && _time < lifetime + delay;

  double get alphaValue {
    if (_time <= delay) return 0;
    final activeTime = _time - delay;
    return (1 - activeTime / lifetime).clamp(0.0, 1.0);
  }

  double get extensionProgress {
    if (_time <= delay) return 0;
    final activeTime = _time - delay;
    return (activeTime / (lifetime * 0.3)).clamp(0.0, 1.0);
  }

  double getFlicker(double globalTime) {
    return 0.5 + math.sin(globalTime * flickerSpeed) * 0.5;
  }

  void update(double dt) {
    _time += dt;
  }
}

/// Debris chunk flying from the explosion
class _DebrisChunk {
  _DebrisChunk({
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.lifetime,
    required this.delay,
    required this.shape,
    required this.gravity,
    required this.hasTrail,
    required this.glowIntensity,
    required this.isEnergized,
  })  : dirX = math.cos(angle),
        dirY = math.sin(angle),
        _time = 0,
        distance = 0,
        currentRotation = rotation,
        fallOffset = 0,
        _velocityY = 0;

  final double angle;
  final double dirX;
  final double dirY;
  final double speed;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final double lifetime;
  final double delay;
  final int shape;
  final double gravity;
  final bool hasTrail;
  final double glowIntensity;
  final bool isEnergized;

  double _time;
  double distance;
  double currentRotation;
  double fallOffset;
  double _velocityY;

  bool get isActive => _time > delay && _time < lifetime + delay;

  double get alphaValue {
    if (_time <= delay) return 0;
    final activeTime = _time - delay;
    return (1 - activeTime / lifetime).clamp(0.0, 1.0);
  }

  double get currentX => dirX * distance;
  double get currentY => dirY * distance + fallOffset;

  void update(double dt) {
    _time += dt;
    if (_time > delay) {
      final activeTime = _time - delay;
      final decay = 1 - activeTime / lifetime * 0.3;
      distance += speed * dt * decay;
      currentRotation += rotationSpeed * dt;
      _velocityY += gravity * dt;
      fallOffset += _velocityY * dt;
    }
  }
}

/// Energy tendril that whips around during the explosion
class _EnergyTendril {
  _EnergyTendril({
    required this.startAngle,
    required this.length,
    required this.width,
    required this.lifetime,
    required this.delay,
    required this.waveFrequency,
    required this.waveAmplitude,
    required this.whipSpeed,
    required this.segments,
  }) : _time = 0;

  final double startAngle;
  final double length;
  final double width;
  final double lifetime;
  final double delay;
  final double waveFrequency;
  final double waveAmplitude;
  final double whipSpeed;
  final int segments;

  double _time;

  bool get isActive => _time > delay && _time < lifetime + delay;

  double get alphaValue {
    if (_time <= delay) return 0;
    final activeTime = _time - delay;
    return (1 - activeTime / lifetime).clamp(0.0, 1.0);
  }

  double get extensionProgress {
    if (_time <= delay) return 0;
    final activeTime = _time - delay;
    return (activeTime / (lifetime * 0.4)).clamp(0.0, 1.0);
  }

  double get currentAngle {
    if (_time <= delay) return startAngle;
    final activeTime = _time - delay;
    // Tendril whips around as it extends
    return startAngle + math.sin(activeTime * whipSpeed) * 0.3;
  }

  void update(double dt) {
    _time += dt;
  }
}

/// Holographic glitch fragment
class _GlitchFragment {
  _GlitchFragment({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.lifetime,
    required this.delay,
    required this.flickerSpeed,
    required this.rgbOffset,
    required this.isHorizontal,
  }) : _time = 0;

  final double x;
  final double y;
  final double width;
  final double height;
  final double lifetime;
  final double delay;
  final double flickerSpeed;
  final double rgbOffset;
  final bool isHorizontal;

  double _time;

  bool get isActive => _time > delay && _time < lifetime + delay;

  double get alphaValue {
    if (_time <= delay) return 0;
    final activeTime = _time - delay;
    return (1 - activeTime / lifetime).clamp(0.0, 1.0);
  }

  double getFlicker(double globalTime) {
    return math.sin(globalTime * flickerSpeed) > 0 ? 1.0 : 0.0;
  }

  void update(double dt) {
    _time += dt;
  }
}

/// Shockwave ring
class _ShockwaveRing {
  _ShockwaveRing({
    required this.delay,
    required this.maxRadius,
    required this.duration,
    required this.thickness,
  }) : _time = 0;

  final double delay;
  final double maxRadius;
  final double duration;
  final double thickness;

  double _time;

  bool get isActive => _time > delay && _time < duration + delay;

  double get alphaValue {
    if (_time <= delay) return 0;
    final activeTime = _time - delay;
    return (1 - activeTime / duration).clamp(0.0, 1.0);
  }

  double get currentRadius {
    if (_time <= delay) return 0;
    final activeTime = _time - delay;
    return (activeTime / duration) * maxRadius;
  }

  void update(double dt) {
    _time += dt;
  }
}
