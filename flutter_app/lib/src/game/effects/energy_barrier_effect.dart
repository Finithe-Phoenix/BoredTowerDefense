import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Energy barrier wall effect with animated cyberpunk patterns.
/// Renders a semi-transparent energy wall at game boundaries or between areas.
/// Features 7 visual layers for rich, dynamic effects.
class EnergyBarrierEffect extends PositionComponent {
  EnergyBarrierEffect({
    required this.barrierRect,
    this.barrierColor = const Color(0xFF00FFFF),
    this.reduceFx = false,
    this.lowFx = false,
    this.warningText = 'RESTRICTED ZONE',
  }) : _rngState = 42;

  /// The rectangle defining the barrier's position and size
  final Rect barrierRect;

  /// Primary color for the barrier (cyan/blue theme)
  final Color barrierColor;

  /// Reduce effects for performance
  final bool reduceFx;

  /// Low effects mode (even more minimal)
  final bool lowFx;

  /// Warning text to display on the barrier
  final String warningText;

  int _rngState;
  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }
  double _nextUnit() => _lcgNext() / 0x7fffffff;
  double _time = 0;
  static const double _warningCharWidth = 8.0;
  static const double _warningCharHeight = 12.0;
  static const double _warningCharSpacing = 2.0;

  Size _lastBarrierSize = Size.zero;
  List<Offset> _symbolPositions = const [];
  double _warningTextWidth = 0;

  // Cached shaders to avoid per-frame createShader allocations.
  Shader? _cachedBarrierGradient;
  int _cachedBarrierPulseKey = -1;
  int _cachedBarrierW = -1;
  int _cachedBarrierH = -1;

  Shader? _cachedEdgeLeftShader;
  Shader? _cachedEdgeRightShader;
  Shader? _cachedEdgeTopShader;
  Shader? _cachedEdgeBottomShader;
  int _cachedEdgePulseKey = -1;
  int _cachedEdgeW = -1;
  int _cachedEdgeH = -1;

  // Short-lived shader caches for moving bands (quantized positions).
  static const int _scanlineShaderCacheMax = 12;
  static const int _pulseShaderCacheMax = 12;
  final Map<int, Shader> _scanlineShaderCache = {};
  final Map<int, Shader> _pulseShaderCache = {};

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════

  // Layer 1: Main barrier wall
  static final Paint _barrierBasePaint = Paint();
  static final Paint _barrierGradientPaint = Paint();

  // Layer 2: Hexagonal pattern
  static final Paint _hexStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _hexFillPaint = Paint();
  static final Paint _hexGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  // Layer 3: Energy flow lines
  static final Paint _flowLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _flowGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _flowDotPaint = Paint();

  // Layer 4: Edge glow
  static final Paint _edgeGlowOuterPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _edgeGlowInnerPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _edgeCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  // Layer 5: Particle sparks
  static final Paint _sparkGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _sparkCorePaint = Paint();

  // Layer 6: Pulse waves
  static final Paint _pulseWavePaint = Paint();
  static final Paint _pulseWaveInnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  // Layer 7: Holographic text/symbols
  static final Paint _textGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _textPaint = Paint();
  static final Paint _scanLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _symbolPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _symbolGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  // Reusable Path objects
  static final Path _hexPath = Path();
  static final Path _flowPath = Path();
  static final Path _symbolPath = Path();

  // Particle sparks data
  late List<_BarrierSpark> _sparks;

  // Energy flow lines data
  late List<_EnergyFlowLine> _flowLines;

  // Derived colors using HSL manipulation
  late Color _secondaryColor;
  late Color _tertiaryColor;
  late Color _accentColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Derive secondary/tertiary colors using HSL manipulation
    final hsl = HSLColor.fromColor(barrierColor);
    _secondaryColor = hsl.withHue((hsl.hue + 30) % 360).toColor(); // Slightly shifted
    _tertiaryColor = hsl.withHue((hsl.hue + 180) % 360).toColor(); // Complementary
    _accentColor = hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();

    // Initialize particle sparks
    _initializeSparks();

    // Initialize energy flow lines
    _initializeFlowLines();

    _initWarningTextLayout();
  }

  void _initWarningTextLayout() {
    if (warningText.isEmpty) {
      _warningTextWidth = 0;
      return;
    }
    _warningTextWidth = warningText.length * (_warningCharWidth + _warningCharSpacing);
  }

  void _ensureLayout(double w, double h) {
    if (_lastBarrierSize.width == w && _lastBarrierSize.height == h) return;
    _lastBarrierSize = Size(w, h);
    _symbolPositions = [
      Offset(w * 0.1, h * 0.2),
      Offset(w * 0.9, h * 0.2),
      Offset(w * 0.1, h * 0.8),
      Offset(w * 0.9, h * 0.8),
      Offset(w * 0.5, h * 0.15),
      Offset(w * 0.5, h * 0.85),
    ];
  }

  void _initializeSparks() {
    final sparkCount = lowFx ? 0 : (reduceFx ? 8 : 20);
    _sparks = List.generate(sparkCount, (i) {
      return _BarrierSpark(
        x: _nextUnit(),
        y: _nextUnit(),
        vx: (_nextUnit() - 0.5) * 0.1,
        vy: -0.05 - _nextUnit() * 0.1, // Moving upward
        life: _nextUnit(),
        maxLife: 0.5 + _nextUnit() * 1.5,
        size: 2 + _nextUnit() * 3,
        phase: _nextUnit() * math.pi * 2,
      );
    });
  }

  void _initializeFlowLines() {
    final lineCount = lowFx ? 3 : (reduceFx ? 6 : 12);
    _flowLines = List.generate(lineCount, (i) {
      return _EnergyFlowLine(
        xOffset: _nextUnit(),
        speed: 0.3 + _nextUnit() * 0.4,
        phase: _nextUnit() * math.pi * 2,
        amplitude: 0.02 + _nextUnit() * 0.03,
        frequency: 2 + _nextUnit() * 3,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Update sparks
    if (!lowFx) {
      for (final spark in _sparks) {
        spark.life += dt / spark.maxLife;
        spark.x += spark.vx * dt;
        spark.y += spark.vy * dt;

        // Reset spark when it goes off barrier or dies
        if (spark.life >= 1.0 || spark.y < 0) {
          spark.x = _nextUnit();
          spark.y = 0.8 + _nextUnit() * 0.2;
          spark.life = 0;
          spark.vx = (_nextUnit() - 0.5) * 0.1;
          spark.vy = -0.05 - _nextUnit() * 0.1;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = barrierRect.width;
    final h = barrierRect.height;
    if (w <= 0 || h <= 0) return;
    _ensureLayout(w, h);

    canvas.save();
    canvas.translate(barrierRect.left, barrierRect.top);
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: Main barrier wall (semi-transparent vertical plane)
    // ═══════════════════════════════════════════════════════════════════════
    _renderMainBarrier(canvas, w, h);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: Hexagonal pattern overlay
    // ═══════════════════════════════════════════════════════════════════════
    if (!lowFx) {
      _renderHexPattern(canvas, w, h);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: Animated energy flow lines moving upward
    // ═══════════════════════════════════════════════════════════════════════
    _renderEnergyFlowLines(canvas, w, h);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: Glow effect at barrier edges
    // ═══════════════════════════════════════════════════════════════════════
    _renderEdgeGlow(canvas, w, h);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: Particle sparks at barrier surface
    // ═══════════════════════════════════════════════════════════════════════
    if (!lowFx) {
      _renderParticleSparks(canvas, w, h);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: Pulse waves traveling horizontally along barrier
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx) {
      _renderPulseWaves(canvas, w, h);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: Holographic text/warning symbols on barrier
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx) {
      _renderHolographicElements(canvas, w, h);
    }

    canvas.restore();
  }

  /// Layer 1: Main barrier wall with gradient and animation
  void _renderMainBarrier(Canvas canvas, double w, double h) {
    // Animated base opacity
    final basePulse = 0.15 + math.sin(_time * 2) * 0.05;
    final pulseKey = (basePulse * 1000).round();
    final wKey = w.round();
    final hKey = h.round();

    // Vertical gradient from bottom (brighter) to top (dimmer)
    if (_cachedBarrierGradient == null ||
        _cachedBarrierPulseKey != pulseKey ||
        _cachedBarrierW != wKey ||
        _cachedBarrierH != hKey) {
      _cachedBarrierGradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          barrierColor.withOpacity(basePulse + 0.1),
          barrierColor.withOpacity(basePulse),
          barrierColor.withOpacity(basePulse * 0.5),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
      _cachedBarrierPulseKey = pulseKey;
      _cachedBarrierW = wKey;
      _cachedBarrierH = hKey;
    }

    _barrierGradientPaint.shader = _cachedBarrierGradient;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _barrierGradientPaint);

    // Subtle noise texture effect (simulated with horizontal lines)
    if (!lowFx) {
      final noiseAlpha = 0.02 + math.sin(_time * 10) * 0.01;
      _barrierBasePaint.color = barrierColor.withOpacity(noiseAlpha);
      for (double y = 0; y < h; y += 4) {
        final lineAlpha = math.sin(_time * 20 + y * 0.1) * 0.5 + 0.5;
        if (lineAlpha > 0.7) {
          canvas.drawLine(Offset(0, y), Offset(w, y), _barrierBasePaint);
        }
      }
    }
  }

  /// Layer 2: Hexagonal pattern overlay
  void _renderHexPattern(Canvas canvas, double w, double h) {
    const hexSize = 30.0;
    final hexWidth = hexSize * 1.732; // sqrt(3)
    final hexHeight = hexSize * 2;

    final cols = (w / hexWidth).ceil() + 1;
    final rows = (h / (hexHeight * 0.75)).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final offsetX = (row % 2) * (hexWidth / 2);
        final centerX = col * hexWidth + offsetX;
        final centerY = row * hexHeight * 0.75;

        // Animated hex visibility based on wave pattern
        final distFromCenter = math.sqrt(
          math.pow(centerX - w / 2, 2) + math.pow(centerY - h / 2, 2),
        );
        final wavePhase = _time * 3 - distFromCenter * 0.01;
        final hexAlpha = (0.1 + math.sin(wavePhase) * 0.1).clamp(0.0, 0.3);

        if (hexAlpha < 0.05) continue;

        _drawHexagon(canvas, centerX, centerY, hexSize * 0.4, hexAlpha);
      }
    }
  }

  void _drawHexagon(Canvas canvas, double cx, double cy, double radius, double alpha) {
    _hexPath.reset();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        _hexPath.moveTo(x, y);
      } else {
        _hexPath.lineTo(x, y);
      }
    }
    _hexPath.close();

    // Hex fill
    _hexFillPaint.color = barrierColor.withOpacity(alpha * 0.3);
    canvas.drawPath(_hexPath, _hexFillPaint);

    // Hex stroke
    _hexStrokePaint.color = barrierColor.withOpacity(alpha);
    canvas.drawPath(_hexPath, _hexStrokePaint);

    // Hex glow (for some hexagons)
    if (alpha > 0.15 && !reduceFx) {
      _hexGlowPaint.color = barrierColor.withOpacity(alpha * 0.5);
      canvas.drawPath(_hexPath, _hexGlowPaint);
    }
  }

  /// Layer 3: Animated energy flow lines moving upward
  void _renderEnergyFlowLines(Canvas canvas, double w, double h) {
    for (final line in _flowLines) {
      // Calculate vertical position (moving upward, looping)
      final yProgress = ((_time * line.speed + line.phase) % 1.0);
      final baseY = h * (1 - yProgress);

      // Horizontal wave oscillation
      final waveX = math.sin(_time * line.frequency + line.phase) * w * line.amplitude;
      final lineX = w * line.xOffset + waveX;

      // Fade based on position
      final fadeAlpha = yProgress < 0.2
          ? yProgress / 0.2
          : (yProgress > 0.8 ? (1 - yProgress) / 0.2 : 1.0);
      if (fadeAlpha <= 0.02) continue;

      // Draw the energy flow line
      _flowPath.reset();
      final segmentHeight = h * 0.15;

      for (double t = 0; t <= 1; t += 0.1) {
        final y = baseY - segmentHeight * t;
        final xWave = math.sin(_time * line.frequency * 2 + t * math.pi * 2) * 10;
        final x = lineX + xWave;

        if (t == 0) {
          _flowPath.moveTo(x, y);
        } else {
          _flowPath.lineTo(x, y);
        }
      }

      // Draw glow
      _flowGlowPaint.color = barrierColor.withOpacity(0.3 * fadeAlpha);
      canvas.drawPath(_flowPath, _flowGlowPaint);

      // Draw core line
      _flowLinePaint.color = _accentColor.withOpacity(0.7 * fadeAlpha);
      canvas.drawPath(_flowPath, _flowLinePaint);

      // Draw energy node at front of line
      final nodeY = baseY;
      final nodePulse = 0.5 + math.sin(_time * 8 + line.phase) * 0.5;
      final nodeAlpha = fadeAlpha * nodePulse;
      if (nodeAlpha <= 0.03) continue;
      _flowDotPaint.color = Colors.white.withOpacity(0.8 * fadeAlpha * nodePulse);
      canvas.drawCircle(Offset(lineX, nodeY), 4, _flowDotPaint);

      // Node glow
      _sparkGlowPaint.color = barrierColor.withOpacity(0.5 * fadeAlpha * nodePulse);
      canvas.drawCircle(Offset(lineX, nodeY), 8, _sparkGlowPaint);
    }
  }

  /// Layer 4: Glow effect at barrier edges
  void _renderEdgeGlow(Canvas canvas, double w, double h) {
    final edgePulse = 0.6 + math.sin(_time * 1.5) * 0.2;
    final edgePulseKey = (edgePulse * 1000).round();
    final wKey = w.round();
    final hKey = h.round();
    final needsEdgeShader = _cachedEdgePulseKey != edgePulseKey ||
        _cachedEdgeW != wKey ||
        _cachedEdgeH != hKey;

    // Left edge glow
    if (needsEdgeShader || _cachedEdgeLeftShader == null) {
      _cachedEdgeLeftShader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          barrierColor.withOpacity(0.4 * edgePulse),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, 30, h));
    }
    _edgeGlowOuterPaint.shader = _cachedEdgeLeftShader;
    canvas.drawRect(Rect.fromLTWH(0, 0, 30, h), _edgeGlowOuterPaint);

    // Right edge glow
    if (needsEdgeShader || _cachedEdgeRightShader == null) {
      _cachedEdgeRightShader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          barrierColor.withOpacity(0.4 * edgePulse),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(w - 30, 0, 30, h));
    }
    _edgeGlowOuterPaint.shader = _cachedEdgeRightShader;
    canvas.drawRect(Rect.fromLTWH(w - 30, 0, 30, h), _edgeGlowOuterPaint);

    // Top edge glow
    if (needsEdgeShader || _cachedEdgeTopShader == null) {
      _cachedEdgeTopShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          barrierColor.withOpacity(0.3 * edgePulse),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, 20));
    }
    _edgeGlowOuterPaint.shader = _cachedEdgeTopShader;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 20), _edgeGlowOuterPaint);

    // Bottom edge glow (brighter - energy source)
    if (needsEdgeShader || _cachedEdgeBottomShader == null) {
      _cachedEdgeBottomShader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          barrierColor.withOpacity(0.6 * edgePulse),
          _secondaryColor.withOpacity(0.3 * edgePulse),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromLTWH(0, h - 40, w, 40));
    }
    _edgeGlowOuterPaint.shader = _cachedEdgeBottomShader;
    canvas.drawRect(Rect.fromLTWH(0, h - 40, w, 40), _edgeGlowOuterPaint);

    if (needsEdgeShader) {
      _cachedEdgePulseKey = edgePulseKey;
      _cachedEdgeW = wKey;
      _cachedEdgeH = hKey;
    }

    // Core edge lines (thin bright lines at edges)
    _edgeCorePaint.color = Colors.white.withOpacity(0.5 * edgePulse);

    // Left core line
    canvas.drawLine(Offset(0, 0), Offset(0, h), _edgeCorePaint);
    // Right core line
    canvas.drawLine(Offset(w, 0), Offset(w, h), _edgeCorePaint);
    // Top core line
    canvas.drawLine(Offset(0, 0), Offset(w, 0), _edgeCorePaint);
    // Bottom core line
    canvas.drawLine(Offset(0, h), Offset(w, h), _edgeCorePaint);
  }

  /// Layer 5: Particle sparks at barrier surface
  void _renderParticleSparks(Canvas canvas, double w, double h) {
    for (final spark in _sparks) {
      if (spark.life >= 1.0) continue;

      final x = spark.x * w;
      final y = spark.y * h;

      // Fade based on life
      final lifeAlpha = 1 - spark.life;
      final flickerAlpha = 0.5 + math.sin(_time * 15 + spark.phase) * 0.5;
      final alpha = lifeAlpha * flickerAlpha;
      if (alpha <= 0.03) continue;

      // Spark glow
      _sparkGlowPaint.color = barrierColor.withOpacity(0.6 * alpha);
      canvas.drawCircle(Offset(x, y), spark.size * 2, _sparkGlowPaint);

      // Spark core
      _sparkCorePaint.color = Colors.white.withOpacity(0.9 * alpha);
      canvas.drawCircle(Offset(x, y), spark.size, _sparkCorePaint);
    }
  }

  /// Layer 6: Pulse waves traveling horizontally along barrier
  void _renderPulseWaves(Canvas canvas, double w, double h) {
    const waveCount = 3;
    final waveSpeed = 150.0;
    final waveWidth = 80.0;

    for (int i = 0; i < waveCount; i++) {
      // Calculate wave position (traveling left to right, wrapping)
      final wavePhase = i / waveCount;
      final waveX = ((_time * waveSpeed + wavePhase * w * 2) % (w + waveWidth * 2)) - waveWidth;

      // Wave intensity based on position
      final waveAlpha = 0.4 + math.sin(_time * 4 + i) * 0.2;
      if (waveAlpha <= 0.01) continue;

      // Draw vertical wave stripe
      final quantizedWaveX = (waveX / 2).round() * 2;
      final waveKey = (quantizedWaveX.toInt() & 0x3fff) |
          ((i & 0x3) << 14) |
          (((waveAlpha * 100).round() & 0xff) << 16) |
          (((waveWidth.round()) & 0xff) << 24);
      var waveShader = _pulseShaderCache[waveKey];
      if (waveShader == null) {
        waveShader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            barrierColor.withOpacity(waveAlpha * 0.3),
            _accentColor.withOpacity(waveAlpha * 0.6),
            Colors.white.withOpacity(waveAlpha * 0.8),
            _accentColor.withOpacity(waveAlpha * 0.6),
            barrierColor.withOpacity(waveAlpha * 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 0.35, 0.5, 0.65, 0.8, 1.0],
        ).createShader(Rect.fromLTWH(quantizedWaveX - waveWidth / 2, 0, waveWidth, h));
        if (_pulseShaderCache.length >= _pulseShaderCacheMax) {
          _pulseShaderCache.remove(_pulseShaderCache.keys.first);
        }
        _pulseShaderCache[waveKey] = waveShader;
      }
      _pulseWavePaint.shader = waveShader;

      canvas.drawRect(
        Rect.fromLTWH(waveX - waveWidth / 2, 0, waveWidth, h),
        _pulseWavePaint,
      );

      // Inner bright line
      _pulseWaveInnerPaint.color = Colors.white.withOpacity(waveAlpha * 0.6);
      canvas.drawLine(Offset(waveX, 0), Offset(waveX, h), _pulseWaveInnerPaint);
    }
  }

  /// Layer 7: Holographic text and warning symbols
  void _renderHolographicElements(Canvas canvas, double w, double h) {
    // Holographic flicker effect
    final holoFlicker = 0.6 + math.sin(_time * 12) * 0.2 + math.sin(_time * 17) * 0.1;
    final glitchOffset = math.sin(_time * 25) > 0.9 ? (_nextUnit() - 0.5) * 4 : 0.0;

    // Warning text
    _renderWarningText(canvas, w, h, holoFlicker, glitchOffset);

    // Warning symbols (triangles with exclamation marks)
    _renderWarningSymbols(canvas, w, h, holoFlicker);

    // Scanning line effect
    _renderScanLine(canvas, w, h);
  }

  void _renderWarningText(Canvas canvas, double w, double h, double alpha, double glitchOffset) {
    final textY = h * 0.5;
    final textSpacing = w / 4;

    // Draw warning text at multiple positions
    for (int i = 0; i < 3; i++) {
      final textX = textSpacing * (i + 0.5);
      final textPhase = _time * 2 + i * 0.5;
      final textAlpha = alpha * (0.5 + math.sin(textPhase) * 0.3);

      if (textAlpha < 0.2) continue;

      // Simulate text with rectangles (since we can't use TextPainter here easily)
      final text = warningText;

      var charX = textX - _warningTextWidth / 2 + glitchOffset;

      for (int c = 0; c < text.length; c++) {
        if (text[c] != ' ') {
          // Character glow
          _textGlowPaint.color = barrierColor.withOpacity(textAlpha * 0.5);
          canvas.drawRect(
            Rect.fromLTWH(charX - 2, textY - 2, _warningCharWidth + 4, _warningCharHeight + 4),
            _textGlowPaint,
          );

          // Character body (simplified rectangle representation)
          _textPaint.color = _accentColor.withOpacity(textAlpha);
          canvas.drawRect(
            Rect.fromLTWH(charX, textY, _warningCharWidth, _warningCharHeight),
            _textPaint,
          );
        }
        charX += _warningCharWidth + _warningCharSpacing;
      }
    }
  }

  void _renderWarningSymbols(Canvas canvas, double w, double h, double alpha) {
    // Draw warning triangles at corners and edges
    for (int i = 0; i < _symbolPositions.length; i++) {
      final pos = _symbolPositions[i];
      final symbolPhase = _time * 3 + i * 0.7;
      final symbolAlpha = alpha * (0.4 + math.sin(symbolPhase) * 0.3);

      if (symbolAlpha < 0.15) continue;

      _drawWarningTriangle(canvas, pos.dx, pos.dy, 15, symbolAlpha);
    }
  }

  void _drawWarningTriangle(Canvas canvas, double cx, double cy, double size, double alpha) {
    _symbolPath.reset();

    // Triangle pointing up
    _symbolPath.moveTo(cx, cy - size);
    _symbolPath.lineTo(cx - size * 0.866, cy + size * 0.5);
    _symbolPath.lineTo(cx + size * 0.866, cy + size * 0.5);
    _symbolPath.close();

    // Triangle glow
    _symbolGlowPaint.color = _tertiaryColor.withOpacity(alpha * 0.5);
    canvas.drawPath(_symbolPath, _symbolGlowPaint);

    // Triangle stroke
    _symbolPaint.color = _tertiaryColor.withOpacity(alpha);
    canvas.drawPath(_symbolPath, _symbolPaint);

    // Exclamation mark line
    _symbolPaint.color = Colors.white.withOpacity(alpha);
    canvas.drawLine(
      Offset(cx, cy - size * 0.4),
      Offset(cx, cy + size * 0.1),
      _symbolPaint,
    );

    // Exclamation mark dot (use sparkCorePaint for fill)
    _sparkCorePaint.color = Colors.white.withOpacity(alpha);
    canvas.drawCircle(Offset(cx, cy + size * 0.3), 2, _sparkCorePaint);
  }

  void _renderScanLine(Canvas canvas, double w, double h) {
    // Vertical scanning line moving across barrier
    final scanSpeed = 100.0;
    final scanX = ((_time * scanSpeed) % (w + 20)) - 10;

    final scanAlpha = 0.3 + math.sin(_time * 5) * 0.1;
    if (scanAlpha <= 0.01) return;

    // Scan line glow
    final quantizedScanX = (scanX / 2).round() * 2;
    final scanKey = (quantizedScanX.toInt() & 0x3fff) |
        (((scanAlpha * 100).round() & 0xff) << 16) |
        ((h.round() & 0xff) << 24);
    var scanShader = _scanlineShaderCache[scanKey];
    if (scanShader == null) {
      scanShader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          barrierColor.withOpacity(scanAlpha * 0.3),
          Colors.white.withOpacity(scanAlpha * 0.5),
          barrierColor.withOpacity(scanAlpha * 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(quantizedScanX - 15, 0, 30, h));
      if (_scanlineShaderCache.length >= _scanlineShaderCacheMax) {
        _scanlineShaderCache.remove(_scanlineShaderCache.keys.first);
      }
      _scanlineShaderCache[scanKey] = scanShader;
    }
    _textGlowPaint.shader = scanShader;

    canvas.drawRect(Rect.fromLTWH(scanX - 15, 0, 30, h), _textGlowPaint);

    // Scan line core
    _scanLinePaint.color = Colors.white.withOpacity(scanAlpha * 0.8);
    canvas.drawLine(Offset(scanX, 0), Offset(scanX, h), _scanLinePaint);
  }
}

/// Helper class for barrier spark particles
class _BarrierSpark {
  _BarrierSpark({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.phase,
  });

  double x; // 0-1 normalized position
  double y; // 0-1 normalized position
  double vx;
  double vy;
  double life;
  final double maxLife;
  final double size;
  final double phase;
}

/// Helper class for energy flow lines
class _EnergyFlowLine {
  _EnergyFlowLine({
    required this.xOffset,
    required this.speed,
    required this.phase,
    required this.amplitude,
    required this.frequency,
  });

  final double xOffset; // 0-1 normalized x position
  final double speed;
  final double phase;
  final double amplitude;
  final double frequency;
}
