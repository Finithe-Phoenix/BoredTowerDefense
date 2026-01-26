import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show RadialGradient, LinearGradient, Alignment;

/// Overlay component that adds ambient cyberpunk effects.
/// The actual tile rendering is done by GameWorld.
class NeonGridComponent extends PositionComponent with HasGameRef<FlameGame> {
  NeonGridComponent({
    required this.gridSize,
    required this.lineColor,
    required this.glowColor,
    this.reducedFx = false,
  }) {
    priority = -10; // render behind other components
  }

  final double gridSize;
  final Color lineColor;
  final Color glowColor;
  final bool reducedFx;

  double _time = 0;
  final math.Random _random = math.Random(42);

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _bgPaint = Paint()..color = const Color(0xFF000000);
  static final Paint _gridPaint = Paint()..strokeWidth = 1;
  static final Paint _glowPaint = Paint()
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _horizonPaint = Paint()..strokeWidth = 1;
  static final Paint _nodeOuterPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _nodeCorePaint = Paint();
  static final Paint _nodeCenterPaint = Paint();
  static final Paint _linePaint = Paint()..strokeWidth = 1;
  static final Paint _pulseOuterPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _pulseInnerPaint = Paint();
  static final Paint _waveRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _waveInnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _scanPaint1 = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
  static final Paint _scanPaint2 = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
  static final Paint _thinScanPaint = Paint()..strokeWidth = 1;
  static final Paint _hScanPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  static final Paint _headGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _headPaint = Paint();
  static final Paint _charPaint = Paint();
  static final Paint _trailGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _ambientGlowPaint = Paint();
  static final Paint _hexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Paint _framePaint = Paint()
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  static final Paint _frameGlowPaint = Paint()
    ..strokeWidth = 4
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _detailPaint = Paint()..strokeWidth = 1;
  static final Paint _cornerNodePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _cornerCenterPaint = Paint();
  static final Paint _edgeGlowPaint = Paint();
  static final Paint _vignettePaint = Paint();
  static final Paint _flickerPaint = Paint();
  static final Path _hexPath = Path();

  // ═══════════════════════════════════════════════════════════════════════════
  // SHADER CACHE - Avoid per-frame createShader() allocations
  // ═══════════════════════════════════════════════════════════════════════════
  Shader? _cachedVignetteShader;
  Shader? _cachedAmbientGlowShader;
  Shader? _cachedHorizonGlowShader;
  Vector2 _cachedShaderSize = Vector2.zero();

  /// Invalidate shader cache when size changes
  void _invalidateShaderCache() {
    _cachedVignetteShader = null;
    _cachedAmbientGlowShader = null;
    _cachedHorizonGlowShader = null;
  }

  /// Get or create vignette shader (only recreated on resize)
  Shader _getVignetteShader() {
    if (_cachedVignetteShader == null || _cachedShaderSize != size) {
      final center = Offset(size.x / 2, size.y / 2);
      final radius = math.max(size.x, size.y) * 0.8;
      _cachedVignetteShader = const RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Color(0x00000000),
          Color(0x00000000),
          Color(0x40000000),
          Color(0x90000000),
        ],
        stops: [0.0, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      _cachedShaderSize.setFrom(size);
    }
    return _cachedVignetteShader!;
  }

  /// Get or create ambient glow shader (only recreated on resize)
  Shader _getAmbientGlowShader() {
    if (_cachedAmbientGlowShader == null || _cachedShaderSize != size) {
      const matrixGreen = Color(0xFF00FF41);
      const matrixDarkGreen = Color(0xFF003B00);
      _cachedAmbientGlowShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          matrixGreen.withOpacity(0.02),
          matrixGreen.withOpacity(0.01),
          matrixDarkGreen.withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
      _cachedShaderSize.setFrom(size);
    }
    return _cachedAmbientGlowShader!;
  }

  /// Get or create horizon glow shader (only recreated on resize)
  Shader _getHorizonGlowShader() {
    if (_cachedHorizonGlowShader == null || _cachedShaderSize != size) {
      final horizonY = size.y * 0.35;
      _cachedHorizonGlowShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0x00000000),
          glowColor.withOpacity(0.05),
          glowColor.withOpacity(0.1),
          glowColor.withOpacity(0.05),
          const Color(0x00000000),
        ],
        stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, horizonY - 20, size.x, 40));
      _cachedShaderSize.setFrom(size);
    }
    return _cachedHorizonGlowShader!;
  }

  // Pulse waves triggered by game events
  final List<_PulseWave> _pulseWaves = [];

  // Energy lines connecting random points
  late List<_EnergyLine> _energyLines;

  // Grid intersection points for pulsing nodes
  late List<_GridNode> _gridNodes;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    anchor = Anchor.topLeft;
    position = Vector2.zero();

    // Initialize energy lines
    _energyLines = reducedFx
        ? []
        : List.generate(6, (i) => _EnergyLine(
              startX: _random.nextDouble(),
              startY: _random.nextDouble(),
              endX: _random.nextDouble(),
              endY: _random.nextDouble(),
              speed: 0.3 + _random.nextDouble() * 0.4,
              phase: _random.nextDouble() * math.pi * 2,
            ));

    // Initialize grid nodes at major intersections
    _initializeGridNodes();
  }

  void _initializeGridNodes() {
    if (reducedFx) {
      _gridNodes = [];
      return;
    }
    _gridNodes = [];
    final nodeSpacing = gridSize * 3;
    final cols = (size.x / nodeSpacing).ceil();
    final rows = (size.y / nodeSpacing).ceil();

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (_random.nextDouble() > 0.7) { // Only some intersections have nodes
          _gridNodes.add(_GridNode(
            x: x * nodeSpacing + nodeSpacing / 2,
            y: y * nodeSpacing + nodeSpacing / 2,
            phase: _random.nextDouble() * math.pi * 2,
            pulseSpeed: 1.5 + _random.nextDouble() * 2,
            size: 2 + _random.nextDouble() * 3,
          ));
        }
      }
    }
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
    _invalidateShaderCache(); // Invalidate cached shaders on resize
    _initializeGridNodes();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Update pulse waves with single-pass removal
    int writeIdx = 0;
    for (int i = 0; i < _pulseWaves.length; i++) {
      final wave = _pulseWaves[i];
      wave.radius += wave.speed * dt;
      wave.alpha -= dt / wave.duration;
      if (wave.alpha > 0) {
        if (writeIdx != i) _pulseWaves[writeIdx] = wave;
        writeIdx++;
      }
    }
    if (writeIdx < _pulseWaves.length) {
      _pulseWaves.removeRange(writeIdx, _pulseWaves.length);
    }
  }

  /// Trigger a pulse wave from a position (e.g., when enemy dies, tower fires)
  void triggerPulseWave(Vector2 position, {Color? color, double speed = 150, double duration = 1.0}) {
    _pulseWaves.add(_PulseWave(
      x: position.x,
      y: position.y,
      radius: 0,
      speed: speed,
      alpha: 0.5,
      duration: duration,
      color: color ?? glowColor,
    ));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.isZero()) return;

    // Dark background base
    _drawBackground(canvas);

    // Perspective grid effect
    _drawPerspectiveGrid(canvas);

    if (!reducedFx) {
      // Grid nodes (pulsing points at intersections)
      _drawGridNodes(canvas);

      // Energy lines connecting points
      _drawEnergyLines(canvas);
    }

    // Pulse waves
    _drawPulseWaves(canvas);

    if (!reducedFx) {
      // Multiple scanning lines
      _drawScanLines(canvas);

      // Data rain effect (subtle)
      _drawDataRain(canvas);

      // Hex pattern overlay
      _drawHexPattern(canvas);

      // Corner HUD frames
      _drawCornerFrames(canvas);

      // Edge glow effects
      _drawEdgeGlows(canvas);

      // Vignette effect
      _drawVignette(canvas);

      // Ambient flicker
      _drawAmbientFlicker(canvas);
    }
  }

  void _drawBackground(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _bgPaint);
  }

  void _drawPerspectiveGrid(Canvas canvas) {
    // Simulated perspective grid lines converging at horizon
    final horizonY = size.y * 0.3;
    final vanishingX = size.x / 2;

    // Horizontal lines with perspective (get closer together toward horizon)
    const lineCount = 20;
    for (int i = 0; i <= lineCount; i++) {
      final t = i / lineCount;
      final perspectiveT = math.pow(t, 1.5); // Non-linear for perspective effect
      final y = horizonY + (size.y - horizonY) * perspectiveT;

      // Lines fade as they approach horizon
      final alpha = 0.03 * t;
      _gridPaint.color = glowColor.withOpacity(alpha);

      canvas.drawLine(Offset(0, y), Offset(size.x, y), _gridPaint);
    }

    // Vertical converging lines
    const vLineCount = 15;
    for (int i = 0; i <= vLineCount; i++) {
      final t = i / vLineCount;
      final bottomX = size.x * t;

      // Converge toward vanishing point
      const convergeFactor = 0.4;
      final topX = vanishingX + (bottomX - vanishingX) * convergeFactor;

      final alpha = 0.02 + 0.01 * math.sin(_time * 2 + i);
      _gridPaint.color = glowColor.withOpacity(alpha);
      _glowPaint.color = glowColor.withOpacity(alpha * 0.5);

      canvas.drawLine(Offset(topX, horizonY), Offset(bottomX, size.y), _glowPaint);
      canvas.drawLine(Offset(topX, horizonY), Offset(bottomX, size.y), _gridPaint);
    }

    // Horizon line
    _horizonPaint.color = glowColor.withOpacity(0.1);
    canvas.drawLine(Offset(0, horizonY), Offset(size.x, horizonY), _horizonPaint);

    // Horizon glow (using cached shader)
    _edgeGlowPaint.shader = _getHorizonGlowShader();
    canvas.drawRect(Rect.fromLTWH(0, horizonY - 20, size.x, 40), _edgeGlowPaint);
  }

  void _drawGridNodes(Canvas canvas) {
    for (final node in _gridNodes) {
      final pulse = 0.5 + math.sin(_time * node.pulseSpeed + node.phase) * 0.5;
      final alpha = 0.2 + pulse * 0.3;
      final nodeSize = node.size * (0.8 + pulse * 0.4);

      // Outer glow
      _nodeOuterPaint.color = glowColor.withOpacity(alpha * 0.3);
      canvas.drawCircle(Offset(node.x, node.y), nodeSize + 4, _nodeOuterPaint);

      // Core
      _nodeCorePaint.color = glowColor.withOpacity(alpha);
      canvas.drawCircle(Offset(node.x, node.y), nodeSize, _nodeCorePaint);

      // Bright center
      _nodeCenterPaint.color = Color.lerp(glowColor, const Color(0xFFFFFFFF), pulse)!.withOpacity(alpha * 1.2);
      canvas.drawCircle(Offset(node.x, node.y), nodeSize * 0.5, _nodeCenterPaint);
    }
  }

  void _drawEnergyLines(Canvas canvas) {
    for (final line in _energyLines) {
      final progress = ((_time * line.speed + line.phase) % 1.0);

      final startX = line.startX * size.x;
      final startY = line.startY * size.y;
      final endX = line.endX * size.x;
      final endY = line.endY * size.y;

      // Draw the base line
      _linePaint.color = glowColor.withOpacity(0.03);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), _linePaint);

      // Draw traveling energy pulse
      final pulseX = startX + (endX - startX) * progress;
      final pulseY = startY + (endY - startY) * progress;

      _pulseOuterPaint.color = glowColor.withOpacity(0.4);
      canvas.drawCircle(Offset(pulseX, pulseY), 4, _pulseOuterPaint);

      _pulseInnerPaint.color = glowColor.withOpacity(0.8);
      canvas.drawCircle(Offset(pulseX, pulseY), 2, _pulseInnerPaint);
    }
  }

  void _drawPulseWaves(Canvas canvas) {
    for (final wave in _pulseWaves) {
      _waveRingPaint.color = wave.color.withOpacity(wave.alpha * 0.5);
      canvas.drawCircle(Offset(wave.x, wave.y), wave.radius, _waveRingPaint);

      // Inner ring
      _waveInnerPaint.color = wave.color.withOpacity(wave.alpha * 0.8);
      canvas.drawCircle(Offset(wave.x, wave.y), wave.radius * 0.8, _waveInnerPaint);
    }
  }

  void _drawScanLines(Canvas canvas) {
    // Primary scan line
    final scanY1 = ((_time * 40) % (size.y + 100)) - 50;
    _scanPaint1.color = glowColor.withOpacity(0.04);
    canvas.drawRect(Rect.fromLTWH(0, scanY1 - 40, size.x, 80), _scanPaint1);

    // Secondary scan line (slower, different phase)
    final scanY2 = (((_time * 25) + size.y * 0.5) % (size.y + 100)) - 50;
    _scanPaint2.color = const Color(0xFFFF0066).withOpacity(0.02);
    canvas.drawRect(Rect.fromLTWH(0, scanY2 - 30, size.x, 60), _scanPaint2);

    // Thin bright scan line
    final thinScanY = ((_time * 80) % (size.y + 20)) - 10;
    _thinScanPaint.color = glowColor.withOpacity(0.15);
    canvas.drawLine(Offset(0, thinScanY), Offset(size.x, thinScanY), _thinScanPaint);

    // Horizontal scan (left to right)
    final scanX = ((_time * 60) % (size.x + 50)) - 25;
    _hScanPaint.color = glowColor.withOpacity(0.02);
    canvas.drawRect(Rect.fromLTWH(scanX - 20, 0, 40, size.y), _hScanPaint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MATRIX-STYLE FALLING CODE RAIN
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawDataRain(Canvas canvas) {
    // Matrix green color palette
    const matrixGreen = Color(0xFF00FF41);
    const matrixBrightGreen = Color(0xFF88FF88);
    const matrixDarkGreen = Color(0xFF003311);

    const columnSpacing = 18.0;
    final columnCount = (size.x / columnSpacing).ceil();
    const charHeight = 14.0;

    // Matrix characters (Katakana-like symbols represented as shapes)
    for (int col = 0; col < columnCount; col++) {
      final x = col * columnSpacing + columnSpacing / 2;

      // Each column has unique speed and phase
      final seed = col * 137 + 42;
      final colRandom = math.Random(seed);
      final speed = 40 + colRandom.nextDouble() * 80;
      final streamLength = 8 + colRandom.nextInt(20);
      final phase = colRandom.nextDouble() * 500;

      // Calculate head position (leading character)
      final totalCycleHeight = size.y + streamLength * charHeight;
      final headY = ((_time * speed + phase) % totalCycleHeight) - charHeight;

      // ═══════════════════════════════════════════════════════════════════
      // LAYER 1: HEAD CHARACTER (brightest, with glow)
      // ═══════════════════════════════════════════════════════════════════
      if (headY >= 0 && headY < size.y) {
        // Outer glow
        _headGlowPaint.color = matrixBrightGreen.withOpacity(0.6);
        canvas.drawCircle(Offset(x, headY + charHeight / 2), 6, _headGlowPaint);

        // Head character (bright white-green)
        _headPaint.color = const Color(0xFFFFFFFF);
        _drawMatrixChar(canvas, x, headY, charHeight, _headPaint, seed + (_time * 10).toInt());
      }

      // ═══════════════════════════════════════════════════════════════════
      // LAYER 2: TRAILING CHARACTERS (fading green)
      // ═══════════════════════════════════════════════════════════════════
      for (int i = 1; i < streamLength; i++) {
        final charY = headY - i * charHeight;
        if (charY < -charHeight || charY > size.y) continue;

        // Calculate fade based on position in trail
        final fadeFactor = 1.0 - (i / streamLength);
        final alpha = fadeFactor * fadeFactor * 0.7; // Quadratic falloff

        if (alpha < 0.02) continue;

        // Trail glow for first few characters
        if (i < 4) {
          _trailGlowPaint.color = matrixGreen.withOpacity(alpha * 0.4);
          canvas.drawCircle(Offset(x, charY + charHeight / 2), 4, _trailGlowPaint);
        }

        // Character color gradient from bright to dark green
        final charColor = Color.lerp(matrixBrightGreen, matrixDarkGreen, i / streamLength)!;
        _charPaint.color = charColor.withOpacity(alpha);

        // Occasional character change (flickering effect)
        final charSeed = seed + i * 17 + (colRandom.nextDouble() < 0.02 ? (_time * 100).toInt() : 0);
        _drawMatrixChar(canvas, x, charY, charHeight, _charPaint, charSeed);
      }

      // ═══════════════════════════════════════════════════════════════════
      // LAYER 3: RANDOM FLICKERING CHARACTERS (sparse, adds depth)
      // ═══════════════════════════════════════════════════════════════════
      if (colRandom.nextDouble() < 0.15) {
        final flickerY = (colRandom.nextDouble() * size.y).floorToDouble();
        final flickerAlpha = 0.1 + colRandom.nextDouble() * 0.2;
        final flickerPhase = math.sin(_time * 20 + col);

        if (flickerPhase > 0.7) {
          _charPaint.color = matrixGreen.withOpacity(flickerAlpha * flickerPhase);
          _drawMatrixChar(canvas, x, flickerY, charHeight, _charPaint, seed + (_time * 50).toInt());
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: AMBIENT MATRIX GLOW OVERLAY (using cached shader)
    // ═══════════════════════════════════════════════════════════════════════
    _ambientGlowPaint.shader = _getAmbientGlowShader();
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _ambientGlowPaint);
  }

  /// Draws a matrix-style character (katakana-like symbols using geometric shapes)
  void _drawMatrixChar(Canvas canvas, double x, double y, double height, Paint paint, int seed) {
    final charRandom = math.Random(seed % 50); // Limited variety for consistency
    final charType = charRandom.nextInt(12);
    final halfH = height / 2;
    final quarterH = height / 4;
    final width = height * 0.6;
    final halfW = width / 2;

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.2;
    paint.strokeCap = StrokeCap.round;

    switch (charType) {
      case 0: // ア-like
        canvas.drawLine(Offset(x - halfW, y + quarterH), Offset(x + halfW, y + quarterH), paint);
        canvas.drawLine(Offset(x, y + quarterH), Offset(x, y + height), paint);
        canvas.drawLine(Offset(x + halfW, y + quarterH), Offset(x, y + height - quarterH), paint);
        break;
      case 1: // カ-like
        canvas.drawLine(Offset(x - halfW, y), Offset(x + halfW, y), paint);
        canvas.drawLine(Offset(x, y), Offset(x - halfW, y + height), paint);
        canvas.drawLine(Offset(x + halfW, y), Offset(x + halfW, y + height), paint);
        break;
      case 2: // 二-like
        canvas.drawLine(Offset(x - halfW, y + quarterH), Offset(x + halfW, y + quarterH), paint);
        canvas.drawLine(Offset(x - halfW, y + height - quarterH), Offset(x + halfW, y + height - quarterH), paint);
        break;
      case 3: // ト-like
        canvas.drawLine(Offset(x, y), Offset(x, y + height), paint);
        canvas.drawLine(Offset(x, y + halfH), Offset(x + halfW, y + halfH - quarterH), paint);
        break;
      case 4: // ハ-like
        canvas.drawLine(Offset(x - halfW, y), Offset(x, y + height), paint);
        canvas.drawLine(Offset(x + halfW, y), Offset(x, y + height), paint);
        break;
      case 5: // 工-like
        canvas.drawLine(Offset(x - halfW, y), Offset(x + halfW, y), paint);
        canvas.drawLine(Offset(x, y), Offset(x, y + height), paint);
        canvas.drawLine(Offset(x - halfW, y + height), Offset(x + halfW, y + height), paint);
        break;
      case 6: // 十-like (cross)
        canvas.drawLine(Offset(x - halfW, y + halfH), Offset(x + halfW, y + halfH), paint);
        canvas.drawLine(Offset(x, y), Offset(x, y + height), paint);
        break;
      case 7: // 口-like (box)
        paint.style = PaintingStyle.stroke;
        canvas.drawRect(Rect.fromLTWH(x - halfW * 0.8, y + quarterH * 0.5, width * 0.8, height * 0.7), paint);
        break;
      case 8: // ム-like (triangle)
        final path = Path()
          ..moveTo(x, y)
          ..lineTo(x - halfW, y + height)
          ..lineTo(x + halfW, y + height)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 9: // 7-like
        canvas.drawLine(Offset(x - halfW, y), Offset(x + halfW, y), paint);
        canvas.drawLine(Offset(x + halfW, y), Offset(x - halfW * 0.5, y + height), paint);
        break;
      case 10: // Z-like
        canvas.drawLine(Offset(x - halfW, y), Offset(x + halfW, y), paint);
        canvas.drawLine(Offset(x + halfW, y), Offset(x - halfW, y + height), paint);
        canvas.drawLine(Offset(x - halfW, y + height), Offset(x + halfW, y + height), paint);
        break;
      case 11: // Single dot
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y + halfH), 2, paint);
        break;
    }
  }

  void _drawHexPattern(Canvas canvas) {
    // Subtle hexagonal pattern overlay
    const hexSize = 60.0;
    const hexWidth = hexSize * 1.732; // sqrt(3)
    const hexHeight = hexSize * 2;

    _hexPaint.color = glowColor.withOpacity(0.015);

    final cols = (size.x / hexWidth).ceil() + 1;
    final rows = (size.y / (hexHeight * 0.75)).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final offsetX = (row % 2) * (hexWidth / 2);
        final centerX = col * hexWidth + offsetX;
        final centerY = row * hexHeight * 0.75;

        // Only draw some hexagons for performance and subtlety
        if ((row + col) % 3 == 0) {
          _drawHexagon(canvas, centerX, centerY, hexSize * 0.5);
        }
      }
    }
  }

  void _drawHexagon(Canvas canvas, double cx, double cy, double radius) {
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
    canvas.drawPath(_hexPath, _hexPaint);
  }

  void _drawCornerFrames(Canvas canvas) {
    _framePaint.color = glowColor.withOpacity(0.6);
    _frameGlowPaint.color = glowColor.withOpacity(0.3);

    const cornerSize = 50.0;
    const margin = 15.0;

    // Top-left
    _drawEnhancedCorner(canvas, margin, margin, cornerSize, true, true);
    // Top-right
    _drawEnhancedCorner(canvas, size.x - margin, margin, cornerSize, false, true);
    // Bottom-left
    _drawEnhancedCorner(canvas, margin, size.y - margin, cornerSize, true, false);
    // Bottom-right
    _drawEnhancedCorner(canvas, size.x - margin, size.y - margin, cornerSize, false, false);
  }

  void _drawEnhancedCorner(Canvas canvas, double x, double y, double cornerSize,
      bool left, bool top) {
    final hDir = left ? 1.0 : -1.0;
    final vDir = top ? 1.0 : -1.0;

    // Main corner bracket
    _hexPath.reset();
    _hexPath.moveTo(x, y + cornerSize * vDir);
    _hexPath.lineTo(x, y);
    _hexPath.lineTo(x + cornerSize * hDir, y);

    canvas.drawPath(_hexPath, _frameGlowPaint);
    canvas.drawPath(_hexPath, _framePaint);

    // Inner detail lines
    _detailPaint.color = glowColor.withOpacity(0.3);

    canvas.drawLine(
      Offset(x + 8 * hDir, y + 8 * vDir),
      Offset(x + 8 * hDir, y + 20 * vDir),
      _detailPaint,
    );
    canvas.drawLine(
      Offset(x + 8 * hDir, y + 8 * vDir),
      Offset(x + 20 * hDir, y + 8 * vDir),
      _detailPaint,
    );

    // Additional tech details
    canvas.drawLine(
      Offset(x + 25 * hDir, y),
      Offset(x + 35 * hDir, y),
      _detailPaint,
    );
    canvas.drawLine(
      Offset(x, y + 25 * vDir),
      Offset(x, y + 35 * vDir),
      _detailPaint,
    );

    // Corner node with animation
    final pulseAlpha = 0.5 + math.sin(_time * 3) * 0.2;
    _cornerNodePaint.color = glowColor.withOpacity(pulseAlpha);
    canvas.drawCircle(Offset(x + 4 * hDir, y + 4 * vDir), 3, _cornerNodePaint);

    // Bright center
    _cornerCenterPaint.color = const Color(0xFFFFFFFF).withOpacity(pulseAlpha);
    canvas.drawCircle(Offset(x + 4 * hDir, y + 4 * vDir), 1.5, _cornerCenterPaint);
  }

  void _drawEdgeGlows(Canvas canvas) {
    // Animated edge intensity
    final edgePulse = 0.8 + math.sin(_time * 1.5) * 0.2;

    // Top edge glow
    _edgeGlowPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        glowColor.withOpacity(0.15 * edgePulse),
        const Color(0x00000000),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.x, 40));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 40), _edgeGlowPaint);

    // Bottom edge glow (magenta)
    _edgeGlowPaint.shader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        const Color(0xFFFF0066).withOpacity(0.12 * edgePulse),
        const Color(0x00000000),
      ],
    ).createShader(Rect.fromLTWH(0, size.y - 40, size.x, 40));
    canvas.drawRect(Rect.fromLTWH(0, size.y - 40, size.x, 40), _edgeGlowPaint);

    // Left edge
    _edgeGlowPaint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        glowColor.withOpacity(0.08 * edgePulse),
        const Color(0x00000000),
      ],
    ).createShader(Rect.fromLTWH(0, 0, 25, size.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, 25, size.y), _edgeGlowPaint);

    // Right edge
    _edgeGlowPaint.shader = LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [
        glowColor.withOpacity(0.08 * edgePulse),
        const Color(0x00000000),
      ],
    ).createShader(Rect.fromLTWH(size.x - 25, 0, 25, size.y));
    canvas.drawRect(Rect.fromLTWH(size.x - 25, 0, 25, size.y), _edgeGlowPaint);
  }

  void _drawVignette(Canvas canvas) {
    // Using cached vignette shader (only recreated on resize)
    _vignettePaint.shader = _getVignetteShader();
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _vignettePaint);
  }

  void _drawAmbientFlicker(Canvas canvas) {
    // Random ambient flicker overlay
    final flickerValue = math.sin(_time * 15) * math.sin(_time * 23);
    if (flickerValue > 0.7) {
      _flickerPaint.color = glowColor.withOpacity(0.01 * (flickerValue - 0.7) / 0.3);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _flickerPaint);
    }

    // Occasional bright flash
    final flashValue = math.sin(_time * 0.5) * math.sin(_time * 1.3);
    if (flashValue > 0.95) {
      _flickerPaint.color = glowColor.withOpacity(0.02);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _flickerPaint);
    }
  }
}

class _PulseWave {
  final double x;
  final double y;
  double radius;
  final double speed;
  double alpha;
  final double duration;
  final Color color;

  _PulseWave({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.alpha,
    required this.duration,
    required this.color,
  });
}

class _EnergyLine {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double speed;
  final double phase;

  _EnergyLine({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.speed,
    required this.phase,
  });
}

class _GridNode {
  final double x;
  final double y;
  final double phase;
  final double pulseSpeed;
  final double size;

  _GridNode({
    required this.x,
    required this.y,
    required this.phase,
    required this.pulseSpeed,
    required this.size,
  });
}
