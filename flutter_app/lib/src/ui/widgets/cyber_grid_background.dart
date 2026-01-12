import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// Epic cyberpunk grid background with perspective, floating particles, and energy waves
class CyberGridBackground extends StatefulWidget {
  const CyberGridBackground({super.key, this.child});

  final Widget? child;

  @override
  State<CyberGridBackground> createState() => _CyberGridBackgroundState();
}

class _CyberGridBackgroundState extends State<CyberGridBackground>
    with TickerProviderStateMixin {
  late AnimationController _gridController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _gridController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _gridController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NeonColors.darkBg,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _gridController,
          _particleController,
          _pulseController,
        ]),
        builder: (context, child) {
          return CustomPaint(
            painter: _CyberGridPainter(
              gridAnimation: _gridController.value,
              particleAnimation: _particleController.value,
              pulseAnimation: _pulseController.value,
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

class _CyberGridPainter extends CustomPainter {
  _CyberGridPainter({
    required this.gridAnimation,
    required this.particleAnimation,
    required this.pulseAnimation,
  });

  final double gridAnimation;
  final double particleAnimation;
  final double pulseAnimation;

  static const int particleCount = 50;
  static final math.Random _random = math.Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    _drawPerspectiveGrid(canvas, size);
    _drawEnergyWaves(canvas, size);
    _drawFloatingParticles(canvas, size);
    _drawCornerAccents(canvas, size);
    _drawHexagonPattern(canvas, size);
    _drawVignette(canvas, size);
  }

  void _drawPerspectiveGrid(Canvas canvas, Size size) {
    final horizonY = size.height * 0.35;
    final vanishingPointX = size.width / 2;

    // Vertical lines going to horizon
    final linePaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const verticalLineCount = 30;
    for (int i = -verticalLineCount ~/ 2; i <= verticalLineCount ~/ 2; i++) {
      final bottomX = vanishingPointX + i * (size.width / verticalLineCount) * 2;
      final alpha = (1 - (i.abs() / (verticalLineCount / 2))).clamp(0.0, 1.0);

      linePaint.color = NeonColors.cyan.withOpacity(alpha * 0.3);

      canvas.drawLine(
        Offset(vanishingPointX, horizonY),
        Offset(bottomX, size.height),
        linePaint,
      );
    }

    // Horizontal lines with perspective
    const horizontalLineCount = 20;
    for (int i = 0; i <= horizontalLineCount; i++) {
      final t = i / horizontalLineCount;
      final perspectiveT = math.pow(t, 1.5);
      final y = horizonY + (size.height - horizonY) * perspectiveT;

      final alpha = t.clamp(0.1, 0.5);
      linePaint.color = NeonColors.cyan.withOpacity(alpha);

      // Calculate line width at this depth
      final leftX = vanishingPointX - (size.width / 2 + 200) * perspectiveT;
      final rightX = vanishingPointX + (size.width / 2 + 200) * perspectiveT;

      canvas.drawLine(Offset(leftX, y), Offset(rightX, y), linePaint);
    }

    // Animated grid lines flowing toward viewer
    final flowOffset = gridAnimation * size.height * 0.3;
    for (int i = 0; i < 5; i++) {
      final baseT = (i / 5 + flowOffset / size.height) % 1.0;
      final perspectiveT = math.pow(baseT, 1.5);
      final y = horizonY + (size.height - horizonY) * perspectiveT;

      if (y > horizonY && y < size.height) {
        final glowPaint = Paint()
          ..color = NeonColors.magenta.withOpacity(0.6 * baseT)
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        final leftX = vanishingPointX - (size.width / 2 + 200) * perspectiveT;
        final rightX = vanishingPointX + (size.width / 2 + 200) * perspectiveT;

        canvas.drawLine(Offset(leftX, y), Offset(rightX, y), glowPaint);
      }
    }
  }

  void _drawEnergyWaves(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.6;

    for (int i = 0; i < 3; i++) {
      final waveProgress = (pulseAnimation + i * 0.33) % 1.0;
      final radius = waveProgress * size.width * 0.8;
      final alpha = (1 - waveProgress) * 0.3;

      if (alpha > 0.01) {
        final wavePaint = Paint()
          ..color = NeonColors.purple.withOpacity(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

        canvas.drawCircle(Offset(centerX, centerY), radius, wavePaint);
      }
    }
  }

  void _drawFloatingParticles(Canvas canvas, Size size) {
    for (int i = 0; i < particleCount; i++) {
      final seed = _random.nextDouble();
      final x = ((seed * 1000 + particleAnimation * 200) % size.width);
      final baseY = (_random.nextDouble() * size.height);
      final y = (baseY - particleAnimation * 100 * (0.5 + seed)) % size.height;

      final particleSize = 1.0 + seed * 3;
      final alpha = 0.3 + seed * 0.5;

      final colors = [NeonColors.cyan, NeonColors.magenta, NeonColors.purple];
      final color = colors[i % colors.length];

      final particlePaint = Paint()
        ..color = color.withOpacity(alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particleSize);

      canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
    }
  }

  void _drawCornerAccents(Canvas canvas, Size size) {
    final accentPaint = Paint()
      ..color = NeonColors.cyan.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    const length = 80.0;
    const offset = 20.0;

    // Top-left
    canvas.drawLine(
      const Offset(offset, offset),
      const Offset(offset + length, offset),
      accentPaint,
    );
    canvas.drawLine(
      const Offset(offset, offset),
      const Offset(offset, offset + length),
      accentPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - offset, offset),
      Offset(size.width - offset - length, offset),
      accentPaint,
    );
    canvas.drawLine(
      Offset(size.width - offset, offset),
      Offset(size.width - offset, offset + length),
      accentPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(offset, size.height - offset),
      Offset(offset + length, size.height - offset),
      accentPaint,
    );
    canvas.drawLine(
      Offset(offset, size.height - offset),
      Offset(offset, size.height - offset - length),
      accentPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - offset, size.height - offset),
      Offset(size.width - offset - length, size.height - offset),
      accentPaint,
    );
    canvas.drawLine(
      Offset(size.width - offset, size.height - offset),
      Offset(size.width - offset, size.height - offset - length),
      accentPaint,
    );
  }

  void _drawHexagonPattern(Canvas canvas, Size size) {
    final hexPaint = Paint()
      ..color = NeonColors.gridLine.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const hexSize = 60.0;
    final rows = (size.height / (hexSize * 1.5)).ceil() + 1;
    final cols = (size.width / (hexSize * 1.732)).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final xOffset = col * hexSize * 1.732;
        final yOffset = row * hexSize * 1.5 + (col.isOdd ? hexSize * 0.75 : 0);

        // Only draw in upper portion
        if (yOffset < size.height * 0.4) {
          _drawHexagon(canvas, Offset(xOffset, yOffset), hexSize * 0.5, hexPaint);
        }
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawVignette(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Colors.transparent,
        Colors.transparent,
        NeonColors.darkBg.withOpacity(0.5),
        NeonColors.darkBg.withOpacity(0.9),
      ],
      stops: const [0.0, 0.5, 0.8, 1.0],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_CyberGridPainter oldDelegate) =>
      oldDelegate.gridAnimation != gridAnimation ||
      oldDelegate.particleAnimation != particleAnimation ||
      oldDelegate.pulseAnimation != pulseAnimation;
}
