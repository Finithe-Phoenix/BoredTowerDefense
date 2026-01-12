import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

class AnimatedGridBackground extends StatefulWidget {
  const AnimatedGridBackground({super.key, this.child});

  final Widget? child;

  @override
  State<AnimatedGridBackground> createState() => _AnimatedGridBackgroundState();
}

class _AnimatedGridBackgroundState extends State<AnimatedGridBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NeonColors.darkBg,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _GridPainter(
              animation: _controller.value,
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.animation});

  final double animation;
  static const double gridSize = 40;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = NeonColors.gridLine.withOpacity(0.5)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Animated scan line (horizontal)
    final scanY = (animation * size.height * 2) % (size.height + 100) - 50;
    final scanGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          NeonColors.cyan.withOpacity(0.3),
          NeonColors.cyan.withOpacity(0.5),
          NeonColors.cyan.withOpacity(0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 30, size.width, 60));

    canvas.drawRect(
      Rect.fromLTWH(0, scanY - 30, size.width, 60),
      scanGradient,
    );

    // Corner accents
    _drawCornerAccent(canvas, Offset.zero, size, true, true);
    _drawCornerAccent(canvas, Offset(size.width, 0), size, false, true);
    _drawCornerAccent(canvas, Offset(0, size.height), size, true, false);
    _drawCornerAccent(canvas, Offset(size.width, size.height), size, false, false);
  }

  void _drawCornerAccent(
      Canvas canvas, Offset corner, Size size, bool isLeft, bool isTop) {
    final accentPaint = Paint()
      ..color = NeonColors.cyan.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const length = 50.0;
    final xDir = isLeft ? 1.0 : -1.0;
    final yDir = isTop ? 1.0 : -1.0;

    canvas.drawLine(
      corner,
      Offset(corner.dx + length * xDir, corner.dy),
      accentPaint,
    );
    canvas.drawLine(
      corner,
      Offset(corner.dx, corner.dy + length * yDir),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
