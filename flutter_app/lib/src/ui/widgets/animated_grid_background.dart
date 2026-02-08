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

  // Static cached paints - avoid per-frame allocation
  static final Paint _linePaint = Paint()
    ..color = NeonColors.gridLine.withOpacity(0.5)
    ..strokeWidth = 1;
  static final Paint _scanPaint = Paint();
  static final Paint _accentPaint = Paint()
    ..color = NeonColors.cyan.withOpacity(0.3)
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  // Pre-computed scan gradient colors
  static final List<Color> _scanColors = [
    Colors.transparent,
    NeonColors.cyan.withOpacity(0.3),
    NeonColors.cyan.withOpacity(0.5),
    NeonColors.cyan.withOpacity(0.3),
    Colors.transparent,
  ];
  static double _scanShaderWidth = 0;
  static Shader? _scanShader;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    // Draw vertical lines
    _ensureGridPath(size);
    canvas.drawPath(_gridPath, _linePaint);

    // Animated scan line (horizontal)
    final scanY = (animation * size.height * 2) % (size.height + 100) - 50;
    if (_scanShader == null || _scanShaderWidth != size.width) {
      _scanShaderWidth = size.width;
      _scanShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _scanColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, 60));
    }
    _scanPaint.shader = _scanShader;
    canvas.save();
    canvas.translate(0, scanY - 30);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 60), _scanPaint);
    canvas.restore();

    // Corner accents
    _drawCornerAccent(canvas, Offset.zero, size, true, true);
    _drawCornerAccent(canvas, Offset(size.width, 0), size, false, true);
    _drawCornerAccent(canvas, Offset(0, size.height), size, true, false);
    _drawCornerAccent(canvas, Offset(size.width, size.height), size, false, false);
  }

  void _drawCornerAccent(
      Canvas canvas, Offset corner, Size size, bool isLeft, bool isTop) {

    const length = 50.0;
    final xDir = isLeft ? 1.0 : -1.0;
    final yDir = isTop ? 1.0 : -1.0;

    canvas.drawLine(
      corner,
      Offset(corner.dx + length * xDir, corner.dy),
      _accentPaint,
    );
    canvas.drawLine(
      corner,
      Offset(corner.dx, corner.dy + length * yDir),
      _accentPaint,
    );
  }

  static final Path _gridPath = Path();
  static Size? _gridPathSize;
  static void _ensureGridPath(Size size) {
    if (_gridPathSize == size) return;
    _gridPathSize = size;
    _gridPath.reset();
    for (double x = 0; x < size.width; x += gridSize) {
      _gridPath
        ..moveTo(x, 0)
        ..lineTo(x, size.height);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      _gridPath
        ..moveTo(0, y)
        ..lineTo(size.width, y);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
