import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

class MaterializationOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const MaterializationOverlay({super.key, required this.onComplete});

  @override
  State<MaterializationOverlay> createState() => _MaterializationOverlayState();
}

class _MaterializationOverlayState extends State<MaterializationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _gridOpacityAnimation;
  late Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
      ),
    );

    _gridOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeIn),
      ),
    );

    _textOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.linear),
      ),
    );

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = (1.0 - _controller.value * 2).clamp(0.0, 1.0);
        if (_controller.value > 0.95) return const SizedBox.shrink();

        return Container(
          color: Colors.black.withOpacity(0.8 * (1.0 - _controller.value)),
          child: Stack(
            children: [
              // Grid Materialization
              Opacity(
                opacity: _gridOpacityAnimation.value * (1.0 - _controller.value),
                child: _buildGridBackground(),
              ),

              // Scanning Line
              Positioned(
                top: MediaQuery.of(context).size.height * _scanLineAnimation.value,
                left: 0,
                right: 0,
                child: _buildScanLine(),
              ),

              // Status Text
              Center(
                child: Opacity(
                  opacity: _textOpacityAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'INITIALIZING SYSTEM',
                        style: NeonTextStyles.title.copyWith(
                          color: NeonColors.cyan,
                          letterSpacing: 8,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'CONSTRUCTING GRID LATTICE...',
                        style: NeonTextStyles.body.copyWith(
                          color: NeonColors.magenta.withOpacity(0.7),
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(
      size: Size.infinite,
      painter: _MaterialGridPainter(),
    );
  }

  Widget _buildScanLine() {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: NeonColors.cyan,
        boxShadow: [
          BoxShadow(
            color: NeonColors.cyan.withOpacity(0.8),
            blurRadius: 15,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: NeonColors.cyan.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
    );
  }
}

class _MaterialGridPainter extends CustomPainter {
  static final Paint _gridPaint = Paint()
    ..color = NeonColors.cyan.withOpacity(0.15)
    ..strokeWidth = 0.5;
  static final Path _gridPath = Path();
  static Size? _gridSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    const spacing = 30.0;
    if (_gridSize != size) {
      _gridSize = size;
      _gridPath.reset();
      for (double i = 0; i < size.width; i += spacing) {
        _gridPath
          ..moveTo(i, 0)
          ..lineTo(i, size.height);
      }
      for (double i = 0; i < size.height; i += spacing) {
        _gridPath
          ..moveTo(0, i)
          ..lineTo(size.width, i);
      }
    }
    canvas.drawPath(_gridPath, _gridPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
