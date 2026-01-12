import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// Epic animated title with glitch effect, scanner line, and chromatic aberration
class EpicNeonTitle extends StatefulWidget {
  const EpicNeonTitle({
    super.key,
    required this.text,
    this.fontSize = 56,
    this.primaryColor = NeonColors.cyan,
    this.secondaryColor = NeonColors.magenta,
  });

  final String text;
  final double fontSize;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  State<EpicNeonTitle> createState() => _EpicNeonTitleState();
}

class _EpicNeonTitleState extends State<EpicNeonTitle>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glitchController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;

  double _glitchOffset = 0;
  bool _showGlitch = false;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Glitch effect
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _glitchController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showGlitch = false;
          _glitchOffset = 0;
        });
      }
    });

    // Random glitch trigger
    _triggerRandomGlitch();

    // Scanner line
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(begin: -0.1, end: 1.1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );
  }

  void _triggerRandomGlitch() {
    Future.delayed(Duration(milliseconds: 2000 + _random.nextInt(4000)), () {
      if (mounted) {
        setState(() {
          _showGlitch = true;
          _glitchOffset = (_random.nextDouble() - 0.5) * 8;
        });
        _glitchController.forward(from: 0);
        _triggerRandomGlitch();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glitchController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _scanAnimation]),
      builder: (context, child) {
        return SizedBox(
          height: widget.fontSize * 1.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Chromatic aberration - red channel offset
              if (_showGlitch)
                Transform.translate(
                  offset: Offset(_glitchOffset * 2, 0),
                  child: Text(
                    widget.text,
                    style: _buildTextStyle(
                      NeonColors.red.withOpacity(0.7),
                      _pulseAnimation.value,
                    ),
                  ),
                ),

              // Chromatic aberration - blue channel offset
              if (_showGlitch)
                Transform.translate(
                  offset: Offset(-_glitchOffset * 2, 0),
                  child: Text(
                    widget.text,
                    style: _buildTextStyle(
                      NeonColors.cyan.withOpacity(0.7),
                      _pulseAnimation.value,
                    ),
                  ),
                ),

              // Main text with gradient
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    widget.primaryColor,
                    widget.secondaryColor,
                    widget.primaryColor,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds),
                child: Text(
                  widget.text,
                  style: _buildTextStyle(Colors.white, _pulseAnimation.value),
                ),
              ),

              // Scanner line overlay
              Positioned.fill(
                child: ClipRect(
                  child: CustomPaint(
                    painter: _ScanLinePainter(
                      progress: _scanAnimation.value,
                      color: widget.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  TextStyle _buildTextStyle(Color color, double intensity) {
    return TextStyle(
      fontFamily: NeonTextStyles.fontFamily,
      fontSize: widget.fontSize,
      fontWeight: FontWeight.bold,
      color: color,
      letterSpacing: 8,
      shadows: [
        Shadow(
          color: color.withOpacity(intensity),
          blurRadius: 10,
        ),
        Shadow(
          color: color.withOpacity(intensity * 0.8),
          blurRadius: 20,
        ),
        Shadow(
          color: color.withOpacity(intensity * 0.6),
          blurRadius: 40,
        ),
        Shadow(
          color: color.withOpacity(intensity * 0.4),
          blurRadius: 80,
        ),
      ],
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  _ScanLinePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          color.withOpacity(0.3),
          color.withOpacity(0.8),
          color.withOpacity(0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - 20, size.width, 40));

    canvas.drawRect(Rect.fromLTWH(0, y - 20, size.width, 40), paint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
