import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Reflective floor effect for the game world.
/// Creates a cyberpunk-style reflective surface with multiple visual layers:
/// - Layer 1: Base reflective surface with gradient (dark at horizon, lighter at bottom)
/// - Layer 2: Faded reflections of grid lines (inverted, with blur)
/// - Layer 3: Light streak reflections (animated horizontal lines)
/// - Layer 4: Fresnel effect (more reflection at glancing angles)
/// - Layer 5: Subtle ripple distortion (wave-like movement)
/// - Layer 6: Specular highlights (bright spots from light sources)
class ReflectiveFloor extends PositionComponent {
  ReflectiveFloor({
    required this.floorRect,
    this.primaryColor = const Color(0xFF00FFFF),
    this.secondaryColor = const Color(0xFFFF0066),
    this.reduceFx = false,
    this.lowFx = false,
    this.gridSize = 50.0,
    this.horizonY = 0.3,
  });

  /// The rectangle defining the floor's position and size
  final Rect floorRect;

  /// Primary reflection color (cyan theme)
  final Color primaryColor;

  /// Secondary reflection color (magenta theme)
  final Color secondaryColor;

  /// Reduce effects for performance
  final bool reduceFx;

  /// Low effects mode (even more minimal)
  final bool lowFx;

  /// Size of the grid pattern
  final double gridSize;

  /// Horizon position as a fraction of height (0.0 = top, 1.0 = bottom)
  final double horizonY;

  int _rngState = 0x6d2b79f5;
  double _time = 0;
  static const int _alphaSteps = 16;

  Shader? _baseGradientShader;
  double _baseShaderWidth = 0;
  double _baseShaderFloorTop = 0;
  double _baseShaderFloorHeight = 0;
  int _basePulseStep = -1;

  Shader? _fresnelShader;
  double _fresnelShaderWidth = 0;
  double _fresnelShaderFloorTop = 0;
  double _fresnelShaderFloorHeight = 0;
  int _fresnelPulseStep = -1;

  Shader? _fresnelLeftShader;
  Shader? _fresnelRightShader;
  double _fresnelEdgeWidth = 0;
  double _fresnelEdgeHeight = 0;
  int _fresnelEdgePulseStep = -1;

  final Map<int, Shader> _travelingHighlightShaders = {};

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════

  // Layer 1: Base reflective surface
  static final Paint _baseSurfacePaint = Paint();
  static final Paint _baseGradientPaint = Paint();

  // Layer 2: Grid line reflections
  static final Paint _gridLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _gridGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _gridReflectionPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  // Layer 3: Light streaks
  static final Paint _streakPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _streakCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  // Layer 4: Fresnel effect
  static final Paint _fresnelPaint = Paint();

  // Layer 5: Ripple distortion
  static final Paint _ripplePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _rippleGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  // Layer 6: Specular highlights
  static final Paint _specularPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _specularCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _specularBrightPaint = Paint();

  // Reusable Path object
  static final Path _ripplePath = Path();

  // Light streak data
  late List<_LightStreak> _lightStreaks;

  // Specular highlight data
  late List<_SpecularHighlight> _specularHighlights;

  // Ripple wave data
  late List<_RippleWave> _rippleWaves;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _rngState = 0x6d2b79f5 ^ primaryColor.value ^ secondaryColor.value;
    _initializeLightStreaks();
    _initializeSpecularHighlights();
    _initializeRippleWaves();
  }

  void _initializeLightStreaks() {
    final streakCount = lowFx ? 2 : (reduceFx ? 4 : 8);
    _lightStreaks = List.generate(streakCount, (i) {
      return _LightStreak(
        yPosition: 0.3 + _nextUnit() * 0.6,
        speed: 80 + _nextUnit() * 120,
        width: 60 + _nextUnit() * 100,
        phase: _nextUnit() * math.pi * 2,
        direction: _nextBool() ? 1.0 : -1.0,
        color: _nextBool() ? primaryColor : secondaryColor,
      );
    });
  }

  void _initializeSpecularHighlights() {
    final highlightCount = lowFx ? 0 : (reduceFx ? 2 : 5);
    _specularHighlights = List.generate(highlightCount, (i) {
      return _SpecularHighlight(
        xPosition: 0.1 + _nextUnit() * 0.8,
        yPosition: 0.5 + _nextUnit() * 0.4,
        size: 20 + _nextUnit() * 40,
        intensity: 0.3 + _nextUnit() * 0.4,
        pulseSpeed: 1.5 + _nextUnit() * 2,
        phase: _nextUnit() * math.pi * 2,
      );
    });
  }

  void _initializeRippleWaves() {
    final waveCount = lowFx ? 0 : (reduceFx ? 2 : 4);
    _rippleWaves = List.generate(waveCount, (i) {
      return _RippleWave(
        centerX: 0.2 + _nextUnit() * 0.6,
        centerY: 0.4 + _nextUnit() * 0.4,
        speed: 30 + _nextUnit() * 50,
        maxRadius: 100 + _nextUnit() * 150,
        phase: _nextUnit() * 100,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }

  double _nextUnit() => _lcgNext() / 0x7fffffff;

  bool _nextBool() => (_lcgNext() & 1) == 0;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = floorRect.width;
    final h = floorRect.height;
    if (w <= 0 || h <= 0) return;
    final floorTop = h * horizonY;
    final floorHeight = h - floorTop;
    if (floorHeight <= 0) return;

    canvas.save();
    canvas.translate(floorRect.left, floorRect.top);

    // Clip to floor area (below horizon)
    canvas.clipRect(Rect.fromLTWH(0, floorTop, w, floorHeight));

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: Base reflective surface with gradient
    // ═══════════════════════════════════════════════════════════════════════
    _renderBaseSurface(canvas, w, h, floorTop, floorHeight);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: Faded reflections of grid lines (inverted, with blur)
    // ═══════════════════════════════════════════════════════════════════════
    _renderGridReflections(canvas, w, h, floorTop, floorHeight);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: Light streak reflections (animated horizontal lines)
    // ═══════════════════════════════════════════════════════════════════════
    _renderLightStreaks(canvas, w, h, floorTop, floorHeight);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: Fresnel effect (more reflection at glancing angles)
    // ═══════════════════════════════════════════════════════════════════════
    _renderFresnelEffect(canvas, w, h, floorTop, floorHeight);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: Subtle ripple distortion (wave-like movement)
    // ═══════════════════════════════════════════════════════════════════════
    if (!lowFx) {
      _renderRippleDistortion(canvas, w, h, floorTop, floorHeight);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: Specular highlights (bright spots from light sources)
    // ═══════════════════════════════════════════════════════════════════════
    if (!lowFx) {
      _renderSpecularHighlights(canvas, w, h, floorTop, floorHeight);
    }

    canvas.restore();
  }

  /// Layer 1: Base reflective surface with gradient (dark at horizon, lighter at bottom)
  void _renderBaseSurface(Canvas canvas, double w, double h, double floorTop, double floorHeight) {
    // Main vertical gradient - dark at top (horizon), slightly lighter at bottom
    final basePulseRaw = 0.03 + math.sin(_time * 0.8) * 0.01;
    final basePulseStep = (basePulseRaw * _alphaSteps).round().clamp(0, _alphaSteps) as int;
    final basePulse = basePulseStep / _alphaSteps;
    if (_baseGradientShader == null ||
        _baseShaderWidth != w ||
        _baseShaderFloorTop != floorTop ||
        _baseShaderFloorHeight != floorHeight ||
        _basePulseStep != basePulseStep) {
      _baseShaderWidth = w;
      _baseShaderFloorTop = floorTop;
      _baseShaderFloorHeight = floorHeight;
      _basePulseStep = basePulseStep;
      _baseGradientShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF000510).withOpacity(0.95), // Very dark blue-black at horizon
          const Color(0xFF000815).withOpacity(0.9),
          const Color(0xFF001020).withOpacity(0.85),
          primaryColor.withOpacity(basePulse), // Subtle color tint at bottom
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, floorTop, w, floorHeight));
    }
    _baseGradientPaint.shader = _baseGradientShader;

    canvas.drawRect(Rect.fromLTWH(0, floorTop, w, floorHeight), _baseGradientPaint);

    // Subtle horizontal noise lines for texture
    if (!lowFx) {
      final noiseAlpha = 0.015 + math.sin(_time * 5) * 0.005;
      _baseSurfacePaint.color = primaryColor.withOpacity(noiseAlpha);

      for (double y = floorTop; y < h; y += 3) {
        final lineNoise = math.sin(_time * 10 + y * 0.2);
        if (lineNoise > 0.6) {
          canvas.drawLine(
            Offset(0, y),
            Offset(w, y),
            _baseSurfacePaint,
          );
        }
      }
    }
  }

  /// Layer 2: Faded reflections of grid lines (inverted, with blur)
  void _renderGridReflections(Canvas canvas, double w, double h, double floorTop, double floorHeight) {
    final vanishingX = w / 2;

    // Reflected horizontal lines (perspective grid)
    final horizonLineCount = reduceFx ? 10 : 20;
    for (int i = 0; i <= horizonLineCount; i++) {
      final t = i / horizonLineCount;
      final perspectiveT = math.pow(t, 1.8); // Stronger perspective compression
      final y = floorTop + floorHeight * perspectiveT;

      // Distance from horizon affects opacity (more visible near bottom)
      final distanceFromHorizon = (y - floorTop) / floorHeight;
      final alpha = 0.03 * distanceFromHorizon * distanceFromHorizon;

      if (alpha < 0.005) continue;

      // Animated shimmer
      final shimmer = 0.8 + math.sin(_time * 2 + i * 0.3) * 0.2;

      _gridReflectionPaint.color = primaryColor.withOpacity(alpha * shimmer);
      canvas.drawLine(Offset(0, y), Offset(w, y), _gridReflectionPaint);

      // Add glow to some lines
      if (!reduceFx && i % 3 == 0) {
        _gridGlowPaint.color = primaryColor.withOpacity(alpha * shimmer * 0.5);
        canvas.drawLine(Offset(0, y), Offset(w, y), _gridGlowPaint);
      }
    }

    // Reflected vertical converging lines
    final verticalLineCount = reduceFx ? 8 : 15;
    for (int i = 0; i <= verticalLineCount; i++) {
      final t = i / verticalLineCount;
      final bottomX = w * t;

      // Converge toward vanishing point at horizon
      final convergeFactor = 0.3;
      final topX = vanishingX + (bottomX - vanishingX) * convergeFactor;

      // Lines closer to center are more visible
      final centerDist = (t - 0.5).abs() * 2;
      final alpha = 0.02 * (1 - centerDist * 0.5);

      if (alpha < 0.005) continue;

      final shimmer = 0.8 + math.sin(_time * 1.5 + i * 0.4) * 0.2;

      _gridLinePaint.color = primaryColor.withOpacity(alpha * shimmer);
      canvas.drawLine(Offset(topX, floorTop), Offset(bottomX, h), _gridLinePaint);

      // Add glow to every 3rd line
      if (!reduceFx && i % 3 == 0) {
        _gridGlowPaint.color = primaryColor.withOpacity(alpha * shimmer * 0.4);
        canvas.drawLine(Offset(topX, floorTop), Offset(bottomX, h), _gridGlowPaint);
      }
    }
  }

  /// Layer 3: Light streak reflections (animated horizontal lines)
  void _renderLightStreaks(Canvas canvas, double w, double h, double floorTop, double floorHeight) {
    for (final streak in _lightStreaks) {
      // Calculate x position with movement
      final direction = streak.direction;
      final xBase = direction > 0
          ? ((_time * streak.speed + streak.phase * 100) % (w + streak.width * 2)) - streak.width
          : w - ((_time * streak.speed + streak.phase * 100) % (w + streak.width * 2)) + streak.width;

      // Y position in floor space
      final y = floorTop + floorHeight * streak.yPosition;

      // Distance from horizon affects visibility
      final distanceFromHorizon = (y - floorTop) / floorHeight;
      final baseAlpha = 0.15 * distanceFromHorizon;

      // Pulsing intensity
      final pulse = 0.6 + math.sin(_time * 3 + streak.phase) * 0.4;
      final alpha = baseAlpha * pulse;

      final alphaStep = (alpha * _alphaSteps).round().clamp(0, _alphaSteps) as int;
      if (alphaStep == 0) continue;
      final quantAlpha = alphaStep / _alphaSteps;

      // Draw streak gradient
      if (streak.shader == null ||
          streak.cachedAlphaStep != alphaStep ||
          streak.cachedColorValue != streak.color.value ||
          streak.cachedWidth != streak.width) {
        streak.cachedAlphaStep = alphaStep;
        streak.cachedColorValue = streak.color.value;
        streak.cachedWidth = streak.width;
        streak.shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            streak.color.withOpacity(quantAlpha * 0.3),
            streak.color.withOpacity(quantAlpha * 0.6),
            Colors.white.withOpacity(quantAlpha * 0.8),
            streak.color.withOpacity(quantAlpha * 0.6),
            streak.color.withOpacity(quantAlpha * 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, streak.width, 8));
      }
      _streakPaint.shader = streak.shader;
      canvas.save();
      canvas.translate(xBase, y - 4);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, streak.width, 8),
        _streakPaint,
      );
      canvas.restore();

      // Bright core line
      if (!reduceFx) {
        _streakCorePaint.color = Colors.white.withOpacity(quantAlpha * 0.6);
        canvas.drawLine(
          Offset(xBase + streak.width * 0.3, y),
          Offset(xBase + streak.width * 0.7, y),
          _streakCorePaint,
        );
      }
    }
  }

  /// Layer 4: Fresnel effect (more reflection at glancing angles - near horizon)
  void _renderFresnelEffect(Canvas canvas, double w, double h, double floorTop, double floorHeight) {
    // Fresnel gradient - stronger reflection near horizon (glancing angle)
    // and fading toward bottom (direct view angle)
    final fresnelPulseRaw = 0.08 + math.sin(_time * 1.2) * 0.02;
    final fresnelPulseStep = (fresnelPulseRaw * _alphaSteps).round().clamp(0, _alphaSteps) as int;
    final fresnelPulse = fresnelPulseStep / _alphaSteps;
    if (_fresnelShader == null ||
        _fresnelShaderWidth != w ||
        _fresnelShaderFloorTop != floorTop ||
        _fresnelShaderFloorHeight != floorHeight ||
        _fresnelPulseStep != fresnelPulseStep) {
      _fresnelShaderWidth = w;
      _fresnelShaderFloorTop = floorTop;
      _fresnelShaderFloorHeight = floorHeight;
      _fresnelPulseStep = fresnelPulseStep;
      _fresnelShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withOpacity(fresnelPulse * 1.5), // Stronger at horizon
          primaryColor.withOpacity(fresnelPulse * 0.8),
          primaryColor.withOpacity(fresnelPulse * 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.15, 0.4, 0.7],
      ).createShader(Rect.fromLTWH(0, floorTop, w, floorHeight));
    }
    _fresnelPaint.shader = _fresnelShader;

    canvas.drawRect(Rect.fromLTWH(0, floorTop, w, floorHeight), _fresnelPaint);

    // Add slight color shift near horizon edges (chromatic aberration hint)
    if (!reduceFx) {
      final edgeWidth = w * 0.15;
      final edgeHeight = floorHeight * 0.3;

      // Left edge magenta tint
      if (_fresnelLeftShader == null ||
          _fresnelRightShader == null ||
          _fresnelEdgeWidth != edgeWidth ||
          _fresnelEdgeHeight != edgeHeight ||
          _fresnelEdgePulseStep != fresnelPulseStep) {
        _fresnelEdgeWidth = edgeWidth;
        _fresnelEdgeHeight = edgeHeight;
        _fresnelEdgePulseStep = fresnelPulseStep;
        _fresnelLeftShader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            secondaryColor.withOpacity(fresnelPulse * 0.4),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, floorTop, edgeWidth, edgeHeight));
        _fresnelRightShader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            primaryColor.withOpacity(fresnelPulse * 0.4),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, floorTop, edgeWidth, edgeHeight));
      }
      _fresnelPaint.shader = _fresnelLeftShader;
      canvas.drawRect(Rect.fromLTWH(0, floorTop, edgeWidth, edgeHeight), _fresnelPaint);

      // Right edge cyan tint
      _fresnelPaint.shader = _fresnelRightShader;
      canvas.drawRect(Rect.fromLTWH(w - edgeWidth, floorTop, edgeWidth, edgeHeight), _fresnelPaint);
    }
  }

  /// Layer 5: Subtle ripple distortion (wave-like movement)
  void _renderRippleDistortion(Canvas canvas, double w, double h, double floorTop, double floorHeight) {
    for (final ripple in _rippleWaves) {
      // Calculate ripple radius (expanding over time)
      final cycleTime = ripple.maxRadius / ripple.speed;
      final progress = ((_time + ripple.phase) % cycleTime) / cycleTime;
      final currentRadius = ripple.maxRadius * progress;

      // Center position in screen coordinates
      final cx = w * ripple.centerX;
      final cy = floorTop + floorHeight * ripple.centerY;

      // Fade out as ripple expands
      final fadeAlpha = (1 - progress) * 0.15;

      if (fadeAlpha < 0.02) continue;

      // Draw concentric ripple rings
      for (int ring = 0; ring < 3; ring++) {
        final ringRadius = currentRadius - ring * 15;
        if (ringRadius <= 0) continue;

        final ringAlpha = fadeAlpha * (1 - ring * 0.3);

        // Glow
        _rippleGlowPaint.color = primaryColor.withOpacity(ringAlpha * 0.3);
        canvas.drawCircle(Offset(cx, cy), ringRadius, _rippleGlowPaint);

        // Core ring
        _ripplePaint.color = primaryColor.withOpacity(ringAlpha);
        canvas.drawCircle(Offset(cx, cy), ringRadius, _ripplePaint);
      }

      // Draw distortion lines radiating from center
      if (!reduceFx) {
        final lineCount = 8;
        for (int i = 0; i < lineCount; i++) {
          final angle = (i / lineCount) * math.pi * 2 + _time * 0.5;
          final innerRadius = currentRadius * 0.3;
          final outerRadius = currentRadius * 0.9;

          if (outerRadius <= 0) continue;

          final startX = cx + math.cos(angle) * innerRadius;
          final startY = cy + math.sin(angle) * innerRadius;
          final endX = cx + math.cos(angle) * outerRadius;
          final endY = cy + math.sin(angle) * outerRadius;

          _ripplePaint.color = primaryColor.withOpacity(fadeAlpha * 0.5);
          canvas.drawLine(Offset(startX, startY), Offset(endX, endY), _ripplePaint);
        }
      }
    }

    // Add subtle wave pattern across entire floor
    if (!reduceFx) {
      final waveFrequency = 0.02;
      final waveAmplitude = 0.03;
      final waveSpeed = 2.0;

      for (double y = floorTop + 10; y < h; y += 20) {
        final waveOffset = math.sin(_time * waveSpeed + y * waveFrequency) * waveAmplitude;
        final distanceFromHorizon = (y - floorTop) / floorHeight;
        final alpha = 0.02 * distanceFromHorizon * (0.5 + waveOffset);

        if (alpha < 0.005) continue;

        _ripplePaint.color = primaryColor.withOpacity(alpha);

        // Draw wavy line
        _ripplePath.reset();
        for (double x = 0; x <= w; x += 10) {
          final waveY = y + math.sin(_time * waveSpeed + x * 0.03) * 2;
          if (x == 0) {
            _ripplePath.moveTo(x, waveY);
          } else {
            _ripplePath.lineTo(x, waveY);
          }
        }
        canvas.drawPath(_ripplePath, _ripplePaint);
      }
    }
  }

  /// Layer 6: Specular highlights (bright spots from light sources)
  void _renderSpecularHighlights(Canvas canvas, double w, double h, double floorTop, double floorHeight) {
    for (final highlight in _specularHighlights) {
      // Position in screen coordinates
      final x = w * highlight.xPosition;
      final y = floorTop + floorHeight * highlight.yPosition;

      // Distance from horizon affects visibility
      final distanceFromHorizon = (y - floorTop) / floorHeight;

      // Pulsing intensity
      final pulse = 0.5 + math.sin(_time * highlight.pulseSpeed + highlight.phase) * 0.5;
      final intensity = highlight.intensity * pulse * distanceFromHorizon;

      if (intensity < 0.05) continue;

      // Outer glow (large, soft)
      _specularPaint.color = primaryColor.withOpacity(intensity * 0.2);
      canvas.drawCircle(Offset(x, y), highlight.size * 2, _specularPaint);

      // Mid glow
      _specularCorePaint.color = primaryColor.withOpacity(intensity * 0.4);
      canvas.drawCircle(Offset(x, y), highlight.size, _specularCorePaint);

      // Bright core
      _specularBrightPaint.color = Colors.white.withOpacity(intensity * 0.6);
      canvas.drawCircle(Offset(x, y), highlight.size * 0.3, _specularBrightPaint);

      // Draw elongated reflection (stretched horizontally like real reflections)
      if (!reduceFx) {
        final stretchWidth = highlight.size * 3;
        final stretchHeight = highlight.size * 0.5;
        final intensityStep = (intensity * _alphaSteps).round().clamp(0, _alphaSteps) as int;
        if (intensityStep > 0) {
          final quantIntensity = intensityStep / _alphaSteps;
          if (highlight.stretchShader == null ||
              highlight.cachedIntensityStep != intensityStep ||
              highlight.cachedStretchWidth != stretchWidth ||
              highlight.cachedStretchHeight != stretchHeight) {
            highlight.cachedIntensityStep = intensityStep;
            highlight.cachedStretchWidth = stretchWidth;
            highlight.cachedStretchHeight = stretchHeight;
            highlight.stretchShader = LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                primaryColor.withOpacity(quantIntensity * 0.15),
                Colors.white.withOpacity(quantIntensity * 0.25),
                primaryColor.withOpacity(quantIntensity * 0.15),
                Colors.transparent,
              ],
            ).createShader(Rect.fromLTWH(0, 0, stretchWidth * 2, stretchHeight));
          }

          _specularPaint.shader = highlight.stretchShader;
          canvas.save();
          canvas.translate(x - stretchWidth, y - stretchHeight / 2);
          canvas.drawOval(
            Rect.fromLTWH(0, 0, stretchWidth * 2, stretchHeight),
            _specularPaint,
          );
          canvas.restore();
          _specularPaint.shader = null;
        }
      }

      // Add secondary color highlight nearby for visual interest
      if (!reduceFx && highlight.intensity > 0.4) {
        final secondaryX = x + highlight.size * 1.5;
        final secondaryIntensity = intensity * 0.4;

        _specularCorePaint.color = secondaryColor.withOpacity(secondaryIntensity * 0.3);
        canvas.drawCircle(Offset(secondaryX, y), highlight.size * 0.5, _specularCorePaint);
      }
    }

    // Add traveling specular highlights
    if (!reduceFx) {
      final travelingCount = 2;
      for (int i = 0; i < travelingCount; i++) {
        final tSpeed = 100 + i * 50.0;
        final tX = ((_time * tSpeed + i * 200) % (w + 100)) - 50;
        final tY = floorTop + floorHeight * (0.6 + i * 0.15);

        final distanceFromHorizon = (tY - floorTop) / floorHeight;
        final tAlpha = 0.15 * distanceFromHorizon;
        final alphaStep = (tAlpha * _alphaSteps).round().clamp(0, _alphaSteps) as int;
        if (alphaStep == 0) continue;

        // Draw traveling highlight
        final shaderKey = (alphaStep << 24) ^ primaryColor.value;
        var travelShader = _travelingHighlightShaders[shaderKey];
        if (travelShader == null) {
          if (_travelingHighlightShaders.length > 32) {
            _travelingHighlightShaders.clear();
          }
          final quantAlpha = alphaStep / _alphaSteps;
          travelShader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              primaryColor.withOpacity(quantAlpha * 0.3),
              Colors.white.withOpacity(quantAlpha * 0.5),
              primaryColor.withOpacity(quantAlpha * 0.3),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(0, 0, 80, 6));
          _travelingHighlightShaders[shaderKey] = travelShader;
        }
        _specularPaint.shader = travelShader;
        canvas.save();
        canvas.translate(tX - 40, tY - 3);
        canvas.drawRect(Rect.fromLTWH(0, 0, 80, 6), _specularPaint);
        canvas.restore();
        _specularPaint.shader = null;
      }
    }
  }

  /// Trigger a ripple at a specific position (e.g., when something hits the floor)
  void triggerRipple(Vector2 position) {
    if (lowFx) return;

    // Convert position to normalized coordinates
    final normalizedX = (position.x - floorRect.left) / floorRect.width;
    final normalizedY = (position.y - floorRect.top - floorRect.height * horizonY) /
        (floorRect.height * (1 - horizonY));

    // Only trigger if within floor bounds
    if (normalizedX >= 0 && normalizedX <= 1 && normalizedY >= 0 && normalizedY <= 1) {
      _rippleWaves.add(_RippleWave(
        centerX: normalizedX,
        centerY: normalizedY,
        speed: 60 + _nextUnit() * 40,
        maxRadius: 80 + _nextUnit() * 60,
        phase: _time, // Start from current time
      ));

      // Limit number of active ripples
      if (_rippleWaves.length > 8) {
        _rippleWaves.removeAt(0);
      }
    }
  }
}

/// Helper class for light streak data
class _LightStreak {
  _LightStreak({
    required this.yPosition,
    required this.speed,
    required this.width,
    required this.phase,
    required this.direction,
    required this.color,
  });

  final double yPosition; // 0-1 normalized position in floor space
  final double speed;
  final double width;
  final double phase;
  final double direction; // 1.0 or -1.0
  final Color color;

  int cachedAlphaStep = -1;
  int cachedColorValue = 0;
  double cachedWidth = 0;
  Shader? shader;
}

/// Helper class for specular highlight data
class _SpecularHighlight {
  _SpecularHighlight({
    required this.xPosition,
    required this.yPosition,
    required this.size,
    required this.intensity,
    required this.pulseSpeed,
    required this.phase,
  });

  final double xPosition; // 0-1 normalized position
  final double yPosition; // 0-1 normalized position in floor space
  final double size;
  final double intensity;
  final double pulseSpeed;
  final double phase;

  int cachedIntensityStep = -1;
  double cachedStretchWidth = 0;
  double cachedStretchHeight = 0;
  Shader? stretchShader;
}

/// Helper class for ripple wave data
class _RippleWave {
  _RippleWave({
    required this.centerX,
    required this.centerY,
    required this.speed,
    required this.maxRadius,
    required this.phase,
  });

  final double centerX; // 0-1 normalized position
  final double centerY; // 0-1 normalized position in floor space
  final double speed;
  final double maxRadius;
  final double phase;
}
