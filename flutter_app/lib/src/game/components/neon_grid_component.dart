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
    _initializeGridNodes();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Update pulse waves
    for (final wave in _pulseWaves) {
      wave.radius += wave.speed * dt;
      wave.alpha -= dt / wave.duration;
    }
    _pulseWaves.removeWhere((w) => w.alpha <= 0);
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
    final bgPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgPaint);
  }

  void _drawPerspectiveGrid(Canvas canvas) {
    // Simulated perspective grid lines converging at horizon
    final horizonY = size.y * 0.3;
    final vanishingX = size.x / 2;

    final gridPaint = Paint()
      ..color = glowColor.withOpacity(0.03)
      ..strokeWidth = 1;

    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.02)
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Horizontal lines with perspective (get closer together toward horizon)
    final lineCount = 20;
    for (int i = 0; i <= lineCount; i++) {
      final t = i / lineCount;
      final perspectiveT = math.pow(t, 1.5); // Non-linear for perspective effect
      final y = horizonY + (size.y - horizonY) * perspectiveT;

      // Lines fade as they approach horizon
      final alpha = 0.03 * t;
      gridPaint.color = glowColor.withOpacity(alpha);

      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }

    // Vertical converging lines
    final vLineCount = 15;
    for (int i = 0; i <= vLineCount; i++) {
      final t = i / vLineCount;
      final bottomX = size.x * t;

      // Converge toward vanishing point
      final convergeFactor = 0.4;
      final topX = vanishingX + (bottomX - vanishingX) * convergeFactor;

      final alpha = 0.02 + 0.01 * math.sin(_time * 2 + i);
      gridPaint.color = glowColor.withOpacity(alpha);
      glowPaint.color = glowColor.withOpacity(alpha * 0.5);

      canvas.drawLine(Offset(topX, horizonY), Offset(bottomX, size.y), glowPaint);
      canvas.drawLine(Offset(topX, horizonY), Offset(bottomX, size.y), gridPaint);
    }

    // Horizon line
    final horizonPaint = Paint()
      ..color = glowColor.withOpacity(0.1)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, horizonY), Offset(size.x, horizonY), horizonPaint);

    // Horizon glow
    final horizonGlow = Paint()
      ..shader = LinearGradient(
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
    canvas.drawRect(Rect.fromLTWH(0, horizonY - 20, size.x, 40), horizonGlow);
  }

  void _drawGridNodes(Canvas canvas) {
    for (final node in _gridNodes) {
      final pulse = 0.5 + math.sin(_time * node.pulseSpeed + node.phase) * 0.5;
      final alpha = 0.2 + pulse * 0.3;
      final nodeSize = node.size * (0.8 + pulse * 0.4);

      // Outer glow
      canvas.drawCircle(
        Offset(node.x, node.y),
        nodeSize + 4,
        Paint()
          ..color = glowColor.withOpacity(alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Core
      canvas.drawCircle(
        Offset(node.x, node.y),
        nodeSize,
        Paint()..color = glowColor.withOpacity(alpha),
      );

      // Bright center
      canvas.drawCircle(
        Offset(node.x, node.y),
        nodeSize * 0.5,
        Paint()..color = Color.lerp(glowColor, const Color(0xFFFFFFFF), pulse)!.withOpacity(alpha * 1.2),
      );
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
      final linePaint = Paint()
        ..color = glowColor.withOpacity(0.03)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);

      // Draw traveling energy pulse
      final pulseX = startX + (endX - startX) * progress;
      final pulseY = startY + (endY - startY) * progress;

      canvas.drawCircle(
        Offset(pulseX, pulseY),
        4,
        Paint()
          ..color = glowColor.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        Offset(pulseX, pulseY),
        2,
        Paint()..color = glowColor.withOpacity(0.8),
      );
    }
  }

  void _drawPulseWaves(Canvas canvas) {
    for (final wave in _pulseWaves) {
      final ringPaint = Paint()
        ..color = wave.color.withOpacity(wave.alpha * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(wave.x, wave.y), wave.radius, ringPaint);

      // Inner ring
      final innerRingPaint = Paint()
        ..color = wave.color.withOpacity(wave.alpha * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(wave.x, wave.y), wave.radius * 0.8, innerRingPaint);
    }
  }

  void _drawScanLines(Canvas canvas) {
    // Primary scan line
    final scanY1 = ((_time * 40) % (size.y + 100)) - 50;
    final scanPaint1 = Paint()
      ..color = glowColor.withOpacity(0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawRect(Rect.fromLTWH(0, scanY1 - 40, size.x, 80), scanPaint1);

    // Secondary scan line (slower, different phase)
    final scanY2 = (((_time * 25) + size.y * 0.5) % (size.y + 100)) - 50;
    final scanPaint2 = Paint()
      ..color = const Color(0xFFFF0066).withOpacity(0.02)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawRect(Rect.fromLTWH(0, scanY2 - 30, size.x, 60), scanPaint2);

    // Thin bright scan line
    final thinScanY = ((_time * 80) % (size.y + 20)) - 10;
    final thinScanPaint = Paint()
      ..color = glowColor.withOpacity(0.15)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, thinScanY),
      Offset(size.x, thinScanY),
      thinScanPaint,
    );

    // Horizontal scan (left to right)
    final scanX = ((_time * 60) % (size.x + 50)) - 25;
    final hScanPaint = Paint()
      ..color = glowColor.withOpacity(0.02)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRect(Rect.fromLTWH(scanX - 20, 0, 40, size.y), hScanPaint);
  }

  void _drawDataRain(Canvas canvas) {
    // Vertical data stream columns
    final columnCount = (size.x / 50).floor();
    final rainPaint = Paint()..strokeWidth = 1;

    for (int col = 0; col < columnCount; col++) {
      final x = 25 + col * 50.0;
      final phase = col * 0.7;
      final streamLength = 50 + math.sin(_time + phase) * 25;
      final yOffset = ((_time * 120 + col * 40) % (size.y + streamLength)) - streamLength;

      // Draw fading stream with varying characters
      for (int i = 0; i < 6; i++) {
        final segmentY = yOffset + i * 10;
        if (segmentY > 0 && segmentY < size.y) {
          final segmentAlpha = (1.0 - i / 6.0) * 0.1;
          final segmentColor = i == 0
              ? const Color(0xFFFFFFFF)
              : (col % 2 == 0 ? glowColor : const Color(0xFFFF0066));
          rainPaint.color = segmentColor.withOpacity(segmentAlpha);

          // Draw as small rectangle (simulating character)
          canvas.drawRect(
            Rect.fromLTWH(x - 2, segmentY, 4, 6),
            rainPaint,
          );
        }
      }
    }
  }

  void _drawHexPattern(Canvas canvas) {
    // Subtle hexagonal pattern overlay
    final hexSize = 60.0;
    final hexWidth = hexSize * 1.732; // sqrt(3)
    final hexHeight = hexSize * 2;

    final hexPaint = Paint()
      ..color = glowColor.withOpacity(0.015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final cols = (size.x / hexWidth).ceil() + 1;
    final rows = (size.y / (hexHeight * 0.75)).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final offsetX = (row % 2) * (hexWidth / 2);
        final centerX = col * hexWidth + offsetX;
        final centerY = row * hexHeight * 0.75;

        // Only draw some hexagons for performance and subtlety
        if ((row + col) % 3 == 0) {
          _drawHexagon(canvas, centerX, centerY, hexSize * 0.5, hexPaint);
        }
      }
    }
  }

  void _drawHexagon(Canvas canvas, double cx, double cy, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCornerFrames(Canvas canvas) {
    final framePaint = Paint()
      ..color = glowColor.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    const cornerSize = 50.0;
    const margin = 15.0;

    // Top-left
    _drawEnhancedCorner(canvas, margin, margin, cornerSize, true, true, framePaint, glowPaint);
    // Top-right
    _drawEnhancedCorner(canvas, size.x - margin, margin, cornerSize, false, true, framePaint, glowPaint);
    // Bottom-left
    _drawEnhancedCorner(canvas, margin, size.y - margin, cornerSize, true, false, framePaint, glowPaint);
    // Bottom-right
    _drawEnhancedCorner(canvas, size.x - margin, size.y - margin, cornerSize, false, false, framePaint, glowPaint);
  }

  void _drawEnhancedCorner(Canvas canvas, double x, double y, double cornerSize,
      bool left, bool top, Paint paint, Paint glow) {
    final hDir = left ? 1.0 : -1.0;
    final vDir = top ? 1.0 : -1.0;

    // Main corner bracket
    final path = Path()
      ..moveTo(x, y + cornerSize * vDir)
      ..lineTo(x, y)
      ..lineTo(x + cornerSize * hDir, y);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, paint);

    // Inner detail lines
    final detailPaint = Paint()
      ..color = glowColor.withOpacity(0.3)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(x + 8 * hDir, y + 8 * vDir),
      Offset(x + 8 * hDir, y + 20 * vDir),
      detailPaint,
    );
    canvas.drawLine(
      Offset(x + 8 * hDir, y + 8 * vDir),
      Offset(x + 20 * hDir, y + 8 * vDir),
      detailPaint,
    );

    // Additional tech details
    canvas.drawLine(
      Offset(x + 25 * hDir, y),
      Offset(x + 35 * hDir, y),
      detailPaint,
    );
    canvas.drawLine(
      Offset(x, y + 25 * vDir),
      Offset(x, y + 35 * vDir),
      detailPaint,
    );

    // Corner node with animation
    final pulseAlpha = 0.5 + math.sin(_time * 3) * 0.2;
    final nodePaint = Paint()
      ..color = glowColor.withOpacity(pulseAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(x + 4 * hDir, y + 4 * vDir), 3, nodePaint);

    // Bright center
    canvas.drawCircle(
      Offset(x + 4 * hDir, y + 4 * vDir),
      1.5,
      Paint()..color = const Color(0xFFFFFFFF).withOpacity(pulseAlpha),
    );
  }

  void _drawEdgeGlows(Canvas canvas) {
    // Animated edge intensity
    final edgePulse = 0.8 + math.sin(_time * 1.5) * 0.2;

    // Top edge glow
    final topGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          glowColor.withOpacity(0.15 * edgePulse),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.x, 40));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 40), topGlow);

    // Bottom edge glow (magenta)
    final bottomGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFF0066).withOpacity(0.12 * edgePulse),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromLTWH(0, size.y - 40, size.x, 40));
    canvas.drawRect(Rect.fromLTWH(0, size.y - 40, size.x, 40), bottomGlow);

    // Left edge
    final leftGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          glowColor.withOpacity(0.08 * edgePulse),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromLTWH(0, 0, 25, size.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, 25, size.y), leftGlow);

    // Right edge
    final rightGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          glowColor.withOpacity(0.08 * edgePulse),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromLTWH(size.x - 25, 0, 25, size.y));
    canvas.drawRect(Rect.fromLTWH(size.x - 25, 0, 25, size.y), rightGlow);
  }

  void _drawVignette(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = math.max(size.x, size.y) * 0.8;

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: const [
          Color(0x00000000),
          Color(0x00000000),
          Color(0x40000000),
          Color(0x90000000),
        ],
        stops: const [0.0, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }

  void _drawAmbientFlicker(Canvas canvas) {
    // Random ambient flicker overlay
    final flickerValue = math.sin(_time * 15) * math.sin(_time * 23);
    if (flickerValue > 0.7) {
      final flickerPaint = Paint()
        ..color = glowColor.withOpacity(0.01 * (flickerValue - 0.7) / 0.3);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), flickerPaint);
    }

    // Occasional bright flash
    final flashValue = math.sin(_time * 0.5) * math.sin(_time * 1.3);
    if (flashValue > 0.95) {
      final flashPaint = Paint()
        ..color = glowColor.withOpacity(0.02);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), flashPaint);
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
