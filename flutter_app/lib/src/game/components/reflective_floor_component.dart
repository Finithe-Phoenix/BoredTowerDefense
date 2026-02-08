import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show LinearGradient, Alignment;

/// Component that renders a reflective floor effect for the cyberpunk game world.
/// Renders AFTER the main grid to create the illusion of a reflective surface.
///
/// Layers (in order):
/// 1. Base reflective surface gradient
/// 2. Faded mirror of grid lines (inverted Y, blurred, low opacity)
/// 3. Animated light streaks (horizontal glowing lines)
/// 4. Fresnel effect (stronger reflection at edges)
/// 5. Subtle ripple distortion (wave pattern)
/// 6. Specular highlights (bright moving spots)
class ReflectiveFloorComponent extends PositionComponent with HasGameRef<FlameGame> {
  ReflectiveFloorComponent({
    required this.glowColor,
    this.reducedFx = false,
    this.horizonRatio = 0.55,
  }) {
    priority = -9; // render just above the grid (-10) but behind game objects
  }

  final Color glowColor;
  final bool reducedFx;
  final double horizonRatio; // Where the horizon line is (0.55 = 55% from top)
  late final Color _specularCoreColor = Color.lerp(glowColor, const Color(0xFFFFFFFF), 0.5)!;

  double _time = 0;

  // Cached static layer (base surface + static grid + fresnel).
  Picture? _staticLayer;
  bool _staticLayerDirty = true;
  double _staticLayerWidth = 0;
  double _staticLayerHeight = 0;

  // Quantized intensity filters to avoid per-frame ColorFilter allocations.
  static const int _intensityLevels = 64;
  final Map<int, ColorFilter> _intensityFilterCache = {};

  // Static paints to avoid per-frame allocations
  static final Paint _baseSurfacePaint = Paint();
  static final Paint _gridLinePaint = Paint()
    ..strokeWidth = 1;
  static final Paint _gridGlowPaint = Paint()
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _lightStreakPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _lightStreakCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _fresnelPaint = Paint();
  static final Paint _ripplePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _specularPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _specularCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _specularCoreHighlightPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _specularFlarePaint = Paint();

  // Light streak data
  late List<_LightStreak> _lightStreaks;

  // Specular highlight data
  late List<_SpecularHighlight> _specularHighlights;

  int _rngState = 0x6d2b79f5;

  // ═══════════════════════════════════════════════════════════════════════════
  // SHADER CACHE - Avoid per-frame createShader() allocations
  // ═══════════════════════════════════════════════════════════════════════════
  Shader? _cachedBaseSurfaceShader;
  Shader? _cachedLeftFresnelShader;
  Shader? _cachedRightFresnelShader;
  Shader? _cachedBottomFresnelShader;
  Vector2 _cachedShaderSize = Vector2.zero();

  void _invalidateShaderCache() {
    _cachedBaseSurfaceShader = null;
    _cachedLeftFresnelShader = null;
    _cachedRightFresnelShader = null;
    _cachedBottomFresnelShader = null;
  }

  Shader _getBaseSurfaceShader(double horizonY, double reflectionHeight) {
    if (_cachedBaseSurfaceShader == null || _cachedShaderSize != size) {
      _cachedBaseSurfaceShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          glowColor.withOpacity(0.02),
          glowColor.withOpacity(0.06),
          glowColor.withOpacity(0.04),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, horizonY, size.x, reflectionHeight));
      _cachedShaderSize.setFrom(size);
    }
    return _cachedBaseSurfaceShader!;
  }

  Shader _getLeftFresnelShader(double horizonY, double reflectionHeight) {
    if (_cachedLeftFresnelShader == null || _cachedShaderSize != size) {
      _cachedLeftFresnelShader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          glowColor.withOpacity(0.08),
          glowColor.withOpacity(0.03),
          glowColor.withOpacity(0),
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromLTWH(0, horizonY, size.x * 0.2, reflectionHeight));
      _cachedShaderSize.setFrom(size);
    }
    return _cachedLeftFresnelShader!;
  }

  Shader _getRightFresnelShader(double horizonY, double reflectionHeight) {
    if (_cachedRightFresnelShader == null || _cachedShaderSize != size) {
      _cachedRightFresnelShader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          glowColor.withOpacity(0.08),
          glowColor.withOpacity(0.03),
          glowColor.withOpacity(0),
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromLTWH(size.x * 0.8, horizonY, size.x * 0.2, reflectionHeight));
      _cachedShaderSize.setFrom(size);
    }
    return _cachedRightFresnelShader!;
  }

  Shader _getBottomFresnelShader(double horizonY, double reflectionHeight) {
    if (_cachedBottomFresnelShader == null || _cachedShaderSize != size) {
      _cachedBottomFresnelShader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          glowColor.withOpacity(0.06),
          glowColor.withOpacity(0.02),
          glowColor.withOpacity(0),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, size.y - reflectionHeight * 0.3, size.x, reflectionHeight * 0.3));
      _cachedShaderSize.setFrom(size);
    }
    return _cachedBottomFresnelShader!;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _rngState = 0x6d2b79f5 ^ glowColor.value;
    size = gameRef.size;
    anchor = Anchor.topLeft;
    position = Vector2.zero();

    _initializeLightStreaks();
    _initializeSpecularHighlights();
  }

  void _initializeLightStreaks() {
    if (reducedFx) {
      _lightStreaks = [];
      return;
    }

    _lightStreaks = List.generate(5, (i) => _LightStreak(
      y: horizonRatio + _nextUnit() * (1.0 - horizonRatio) * 0.8,
      speed: 0.02 + _nextUnit() * 0.04,
      width: 0.1 + _nextUnit() * 0.3,
      intensity: 0.03 + _nextUnit() * 0.05,
      phase: _nextUnit() * math.pi * 2,
    ));
  }

  void _initializeSpecularHighlights() {
    if (reducedFx) {
      _specularHighlights = [];
      return;
    }

    _specularHighlights = List.generate(4, (i) => _SpecularHighlight(
      xPhase: _nextUnit() * math.pi * 2,
      yOffset: horizonRatio + 0.1 + _nextUnit() * 0.3,
      speed: 0.3 + _nextUnit() * 0.5,
      size: 20 + _nextUnit() * 40,
      intensity: 0.08 + _nextUnit() * 0.07,
    ));
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
    _invalidateShaderCache(); // Invalidate cached shaders on resize
    _initializeLightStreaks();
    _initializeSpecularHighlights();
    _staticLayerDirty = true;
    _staticLayer?.dispose();
    _staticLayer = null;
    _intensityFilterCache.clear();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.isZero()) return;

    final horizonY = size.y * horizonRatio;

    // Only render reflection below the horizon
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, horizonY, size.x, size.y - horizonY));

    _ensureStaticLayer(horizonY);
    if (_staticLayer != null) {
      canvas.drawPicture(_staticLayer!);
    }

    // Layer 2 (dynamic): Animated vertical grid lines
    _drawReflectedGridLinesDynamic(canvas, horizonY);

    if (!reducedFx) {
      // Layer 3: Animated light streaks
      _drawLightStreaks(canvas, horizonY);

      // Layer 5: Ripple distortion
      _drawRippleDistortion(canvas, horizonY);

      // Layer 6: Specular highlights
      _drawSpecularHighlights(canvas, horizonY);
    }

    canvas.restore();
  }

  void _ensureStaticLayer(double horizonY) {
    if (!_staticLayerDirty &&
        _staticLayerWidth == size.x &&
        _staticLayerHeight == size.y) {
      return;
    }

    _staticLayerWidth = size.x;
    _staticLayerHeight = size.y;
    final recorder = PictureRecorder();
    final staticCanvas = Canvas(recorder);

    // Layer 1: Base reflective surface gradient
    _drawBaseReflectiveSurface(staticCanvas, horizonY);

    // Layer 2: Static mirrored grid lines (horizontal only)
    _drawReflectedGridLinesStatic(staticCanvas, horizonY);

    if (!reducedFx) {
      // Layer 4: Fresnel effect
      _drawFresnelEffect(staticCanvas, horizonY);
    }

    _staticLayer?.dispose();
    _staticLayer = recorder.endRecording();
    _staticLayerDirty = false;
  }

  /// Layer 1: Base reflective surface - darker at horizon, lighter at bottom
  void _drawBaseReflectiveSurface(Canvas canvas, double horizonY) {
    final reflectionHeight = size.y - horizonY;

    // Using cached shader (only recreated on resize)
    _baseSurfacePaint.shader = _getBaseSurfaceShader(horizonY, reflectionHeight);

    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.x, reflectionHeight),
      _baseSurfacePaint,
    );
  }

  /// Layer 2: Mirrored grid lines with blur and low opacity
  void _drawReflectedGridLinesStatic(Canvas canvas, double horizonY) {
    final reflectionHeight = size.y - horizonY;

    // Reflected horizontal lines (inverted from perspective grid)
    final lineCount = 15;
    for (int i = 0; i <= lineCount; i++) {
      final t = i / lineCount;
      final perspectiveT = math.pow(t, 1.3);

      // Mirror the Y position - lines closer to horizon should be closer to horizonY
      final originalY = horizonY - (horizonY * 0.3) * perspectiveT;
      final reflectedY = horizonY + (horizonY - originalY);

      // Only draw if in visible reflection area
      if (reflectedY > size.y) continue;

      // Fade based on distance from horizon (stronger near horizon, fading toward bottom)
      final distanceFromHorizon = (reflectedY - horizonY) / reflectionHeight;
      final alpha = 0.08 * (1.0 - distanceFromHorizon * 0.7);

      if (alpha < 0.01) continue;

      _gridGlowPaint.color = glowColor.withOpacity(alpha * 0.5);
      _gridLinePaint.color = glowColor.withOpacity(alpha);

      // Draw blurred glow line first
      canvas.drawLine(
        Offset(0, reflectedY),
        Offset(size.x, reflectedY),
        _gridGlowPaint,
      );

      // Draw core line
      canvas.drawLine(
        Offset(0, reflectedY),
        Offset(size.x, reflectedY),
        _gridLinePaint,
      );
    }
  }

  void _drawReflectedGridLinesDynamic(Canvas canvas, double horizonY) {
    final vanishingX = size.x / 2;

    // Reflected vertical converging lines
    final vLineCount = 12;
    for (int i = 0; i <= vLineCount; i++) {
      final t = i / vLineCount;
      final bottomX = size.x * t;

      // Original converging lines went from horizon to bottom
      // Reflection: mirror the convergence pattern below horizon
      final convergeFactor = 0.6;
      final topX = vanishingX + (bottomX - vanishingX) * convergeFactor;

      // Fade based on distance from center (more visible near edges for Fresnel)
      final centerDistance = (t - 0.5).abs() * 2;
      final alpha = 0.05 * (0.5 + centerDistance * 0.5);

      // Add time-based subtle animation
      final animatedAlpha = alpha * (0.8 + 0.2 * math.sin(_time * 0.5 + i));

      _gridGlowPaint.color = glowColor.withOpacity(animatedAlpha * 0.4);
      _gridLinePaint.color = glowColor.withOpacity(animatedAlpha);

      // Draw from horizon down, converging slightly
      final reflectionBottom = size.y;
      final reflectionBottomX = bottomX + (vanishingX - bottomX) * 0.1;

      canvas.drawLine(
        Offset(topX, horizonY),
        Offset(reflectionBottomX, reflectionBottom),
        _gridGlowPaint,
      );
      canvas.drawLine(
        Offset(topX, horizonY),
        Offset(reflectionBottomX, reflectionBottom),
        _gridLinePaint,
      );
    }
  }

  /// Layer 3: Animated horizontal light streaks moving across the floor
  void _drawLightStreaks(Canvas canvas, double horizonY) {
    final reflectionHeight = size.y - horizonY;

    for (final streak in _lightStreaks) {
      // Animate X position
      final xProgress = ((_time * streak.speed + streak.phase) % 1.2) - 0.1;
      final x = size.x * xProgress;

      // Y position in reflection area
      final y = horizonY + reflectionHeight * (streak.y - horizonRatio) / (1.0 - horizonRatio);

      // Streak width based on screen width
      final streakWidth = size.x * streak.width;

      // Intensity pulses over time
      final pulseIntensity = streak.intensity * (0.7 + 0.3 * math.sin(_time * 2 + streak.phase));

      // Fade at edges of streak
      _lightStreakPaint.shader = _getStreakShader(streak, streakWidth);
      _lightStreakPaint.colorFilter = _getIntensityFilter(pulseIntensity);

      canvas.save();
      canvas.translate(x - streakWidth / 2, y - 8);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, streakWidth, 16),
        _lightStreakPaint,
      );
      canvas.restore();

      // Core bright line
      _lightStreakCorePaint.color = glowColor.withOpacity(pulseIntensity);
      canvas.drawLine(
        Offset(x - streakWidth * 0.3, y),
        Offset(x + streakWidth * 0.3, y),
        _lightStreakCorePaint,
      );
    }
  }

  /// Layer 4: Fresnel effect - stronger reflection at glancing angles (edges)
  /// Using cached shaders (only recreated on resize)
  void _drawFresnelEffect(Canvas canvas, double horizonY) {
    final reflectionHeight = size.y - horizonY;

    // Left edge fresnel (cached)
    _fresnelPaint.shader = _getLeftFresnelShader(horizonY, reflectionHeight);
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.x * 0.2, reflectionHeight),
      _fresnelPaint,
    );

    // Right edge fresnel (cached)
    _fresnelPaint.shader = _getRightFresnelShader(horizonY, reflectionHeight);
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.8, horizonY, size.x * 0.2, reflectionHeight),
      _fresnelPaint,
    );

    // Bottom fresnel (cached)
    _fresnelPaint.shader = _getBottomFresnelShader(horizonY, reflectionHeight);
    canvas.drawRect(
      Rect.fromLTWH(0, size.y - reflectionHeight * 0.3, size.x, reflectionHeight * 0.3),
      _fresnelPaint,
    );
  }

  /// Layer 5: Subtle ripple distortion - animated wave rings
  void _drawRippleDistortion(Canvas canvas, double horizonY) {
    final reflectionHeight = size.y - horizonY;
    final centerX = size.x / 2;
    final centerY = horizonY + reflectionHeight * 0.5;

    // Multiple concentric ripples
    final rippleCount = 4;
    for (int i = 0; i < rippleCount; i++) {
      // Animate ripple expansion
      final phase = (_time * 0.3 + i * 0.5) % 2.0;
      final maxRadius = size.x * 0.6;
      final radius = maxRadius * phase;

      // Fade as ripple expands
      final alpha = 0.05 * (1.0 - phase / 2.0);

      if (alpha < 0.005) continue;

      _ripplePaint.color = glowColor.withOpacity(alpha);

      // Draw elliptical ripple (compressed vertically for perspective)
      canvas.save();
      canvas.translate(centerX, centerY);
      canvas.scale(1.0, 0.3); // Compress vertically for floor perspective

      canvas.drawCircle(Offset.zero, radius, _ripplePaint);

      canvas.restore();
    }

    // Secondary ripple source (off-center)
    final secondaryCenterX = size.x * 0.3;
    final secondaryCenterY = horizonY + reflectionHeight * 0.3;

    for (int i = 0; i < 3; i++) {
      final phase = ((_time * 0.25 + 0.3) + i * 0.6) % 2.0;
      final maxRadius = size.x * 0.4;
      final radius = maxRadius * phase;
      final alpha = 0.04 * (1.0 - phase / 2.0);

      if (alpha < 0.005) continue;

      _ripplePaint.color = glowColor.withOpacity(alpha);

      canvas.save();
      canvas.translate(secondaryCenterX, secondaryCenterY);
      canvas.scale(1.0, 0.25);

      canvas.drawCircle(Offset.zero, radius, _ripplePaint);

      canvas.restore();
    }
  }

  /// Layer 6: Specular highlights - bright spots that move based on time
  void _drawSpecularHighlights(Canvas canvas, double horizonY) {
    final reflectionHeight = size.y - horizonY;

    for (final highlight in _specularHighlights) {
      // Animate X position in a wave pattern
      final x = size.x * (0.5 + 0.4 * math.sin(_time * highlight.speed + highlight.xPhase));

      // Y position in reflection area
      final y = horizonY + reflectionHeight * (highlight.yOffset - horizonRatio) / (1.0 - horizonRatio);

      // Intensity pulses
      final pulseIntensity = highlight.intensity * (0.6 + 0.4 * math.sin(_time * 1.5 + highlight.xPhase));

      // Outer glow (larger, softer)
      _specularPaint.color = glowColor.withOpacity(pulseIntensity * 0.4);
      canvas.drawCircle(Offset(x, y), highlight.size * 1.5, _specularPaint);

      // Middle glow
      _specularCorePaint.color = glowColor.withOpacity(pulseIntensity * 0.7);
      canvas.drawCircle(Offset(x, y), highlight.size * 0.7, _specularCorePaint);

      // Bright core (white-ish)
      _specularCoreHighlightPaint.color = _specularCoreColor.withOpacity(pulseIntensity);
      canvas.drawCircle(
        Offset(x, y),
        highlight.size * 0.3,
        _specularCoreHighlightPaint,
      );

      // Horizontal lens flare streak
      final flareWidth = highlight.size * 3;
      _specularFlarePaint.shader = _getFlareShader(highlight, flareWidth);
      _specularFlarePaint.colorFilter = _getIntensityFilter(pulseIntensity);

      canvas.save();
      canvas.translate(x - flareWidth / 2, y - 2);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, flareWidth, 4),
        _specularFlarePaint,
      );
      canvas.restore();
    }
  }

  Shader _getStreakShader(_LightStreak streak, double streakWidth) {
    if (streak.cachedShader == null || streak.cachedWidth != streakWidth) {
      streak.cachedWidth = streakWidth;
      streak.cachedShader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0x00FFFFFF),
          Color(0x80FFFFFF), // 0.5 alpha
          Color(0xCCFFFFFF), // 0.8 alpha
          Color(0x80FFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, streakWidth, 16));
    }
    return streak.cachedShader!;
  }

  Shader _getFlareShader(_SpecularHighlight highlight, double flareWidth) {
    if (highlight.cachedFlareShader == null || highlight.cachedFlareWidth != flareWidth) {
      highlight.cachedFlareWidth = flareWidth;
      highlight.cachedFlareShader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0x00FFFFFF),
          Color(0x4DFFFFFF), // 0.3 alpha
          Color(0x00FFFFFF),
        ],
      ).createShader(Rect.fromLTWH(0, 0, flareWidth, 4));
    }
    return highlight.cachedFlareShader!;
  }

  ColorFilter _getIntensityFilter(double intensity) {
    final level = (intensity * _intensityLevels).round().clamp(0, _intensityLevels);
    return _intensityFilterCache.putIfAbsent(
      level,
      () => ColorFilter.mode(
        glowColor.withOpacity(level / _intensityLevels),
        BlendMode.modulate,
      ),
    );
  }

  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }

  double _nextUnit() => _lcgNext() / 0x7fffffff;
}

/// Data class for animated light streaks
class _LightStreak {
  final double y; // Normalized Y position (0-1)
  final double speed; // Animation speed
  final double width; // Streak width as ratio of screen width
  final double intensity; // Base intensity
  final double phase; // Animation phase offset
  Shader? cachedShader;
  double cachedWidth = 0;

  _LightStreak({
    required this.y,
    required this.speed,
    required this.width,
    required this.intensity,
    required this.phase,
  });
}

/// Data class for specular highlights
class _SpecularHighlight {
  final double xPhase; // Phase for X position animation
  final double yOffset; // Normalized Y position (0-1)
  final double speed; // Animation speed
  final double size; // Highlight size in pixels
  final double intensity; // Base intensity
  Shader? cachedFlareShader;
  double cachedFlareWidth = 0;

  _SpecularHighlight({
    required this.xPhase,
    required this.yOffset,
    required this.speed,
    required this.size,
    required this.intensity,
  });
}
