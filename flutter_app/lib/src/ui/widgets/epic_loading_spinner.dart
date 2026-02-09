import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Epic loading spinner with rotating hexagon rings, orbiting particles,
/// pulsing center core, and data stream segments.
///
/// Usage:
/// ```dart
/// // Simple spinner
/// EpicLoadingSpinner()
///
/// // Custom size and color
/// EpicLoadingSpinner(
///   size: 100,
///   accentColor: Colors.blue,
///   showLoadingText: true,
/// )
///
/// // Full-screen overlay
/// EpicLoadingSpinner.overlay(context: context)
/// ```
class EpicLoadingSpinner extends StatefulWidget {
  final double size;
  final Color accentColor;
  final bool showLoadingText;
  final String? customText;
  final double strokeWidth;

  const EpicLoadingSpinner({
    super.key,
    this.size = 80,
    this.accentColor = const Color(0xFF00FFFF),
    this.showLoadingText = false,
    this.customText,
    this.strokeWidth = 2.0,
  });

  /// Show loading spinner as a full-screen overlay
  static void show({
    required BuildContext context,
    String? text,
    Color accentColor = const Color(0xFF00FFFF),
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: EpicLoadingSpinner(
            size: 100,
            accentColor: accentColor,
            showLoadingText: true,
            customText: text,
          ),
        ),
      ),
    );
  }

  /// Dismiss the loading overlay
  static void dismiss(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Show loading spinner as an overlay with automatic dismiss
  static Future<T> withOverlay<T>({
    required BuildContext context,
    required Future<T> Function() task,
    String? text,
    Color accentColor = const Color(0xFF00FFFF),
  }) async {
    show(context: context, text: text, accentColor: accentColor);
    try {
      final result = await task();
      if (context.mounted) dismiss(context);
      return result;
    } catch (e) {
      if (context.mounted) dismiss(context);
      rethrow;
    }
  }

  @override
  State<EpicLoadingSpinner> createState() => _EpicLoadingSpinnerState();
}

class _EpicLoadingSpinnerState extends State<EpicLoadingSpinner>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _glitchController;

  @override
  void initState() {
    super.initState();

    // Main rotation for rings
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Pulse animation for center core
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Particle orbit animation
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    // Glitch effect for text
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // Random glitches
    _scheduleRandomGlitch();
  }

  void _scheduleRandomGlitch() {
    Future.delayed(Duration(milliseconds: 800 + math.Random().nextInt(1200)), () {
      if (mounted) {
        _glitchController.forward(from: 0.0);
        _scheduleRandomGlitch();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Spinner
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: [
              // Rotating hexagon rings
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _HexagonRingsPainter(
                        rotation: _rotationController.value,
                        accentColor: widget.accentColor,
                        strokeWidth: widget.strokeWidth,
                      ),
                    );
                  },
                ),
              ),

              // Pulsing center core
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _CenterCorePainter(
                        pulse: _pulseController.value,
                        accentColor: widget.accentColor,
                      ),
                    );
                  },
                ),
              ),

              // Orbiting particles
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _OrbitingParticlesPainter(
                        progress: _particleController.value,
                        accentColor: widget.accentColor,
                      ),
                    );
                  },
                ),
              ),

              // Data stream segments
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _DataStreamSegmentsPainter(
                        progress: _rotationController.value,
                        accentColor: widget.accentColor,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Loading text
        if (widget.showLoadingText) ...[
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _glitchController,
            builder: (context, child) {
              return _GlitchLoadingText(
                text: widget.customText ?? 'LOADING',
                accentColor: widget.accentColor,
                glitchIntensity: _glitchController.value,
              );
            },
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// HEXAGON RINGS PAINTER
// ============================================================================

class _HexagonRingsPainter extends CustomPainter {
  final double rotation;
  final Color accentColor;
  final double strokeWidth;

  _HexagonRingsPainter({
    required this.rotation,
    required this.accentColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Draw 3 concentric hexagon rings
    final rings = [
      (radius: size.width * 0.45, speed: 1.0, opacity: 1.0),
      (radius: size.width * 0.35, speed: -1.5, opacity: 0.7),
      (radius: size.width * 0.25, speed: 2.0, opacity: 0.5),
    ];

    for (final ring in rings) {
      final angle = rotation * ring.speed * math.pi * 2;

      // Main hexagon
      paint.color = accentColor.withOpacity(ring.opacity);
      _drawHexagon(canvas, center, ring.radius, angle, paint);

      // Glow effect
      paint.color = accentColor.withOpacity(ring.opacity * 0.3);
      paint.strokeWidth = strokeWidth + 2;
      _drawHexagon(canvas, center, ring.radius, angle, paint);
      paint.strokeWidth = strokeWidth;
    }
  }

  void _drawHexagon(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    Paint paint,
  ) {
    final path = Path();

    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i + rotation;
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

  @override
  bool shouldRepaint(_HexagonRingsPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}

// ============================================================================
// CENTER CORE PAINTER
// ============================================================================

class _CenterCorePainter extends CustomPainter {
  final double pulse;
  final Color accentColor;

  _CenterCorePainter({
    required this.pulse,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.08;
    final pulseRadius = baseRadius + (pulse * baseRadius * 0.5);

    final paint = Paint()..style = PaintingStyle.fill;

    // Outer glow pulse
    paint.color = accentColor.withOpacity((1.0 - pulse) * 0.3);
    canvas.drawCircle(center, pulseRadius * 2, paint);

    // Middle glow
    paint.color = accentColor.withOpacity(0.5);
    canvas.drawCircle(center, pulseRadius, paint);

    // Core
    paint.color = accentColor;
    canvas.drawCircle(center, baseRadius, paint);

    // Bright center
    paint.color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(center, baseRadius * 0.5, paint);
  }

  @override
  bool shouldRepaint(_CenterCorePainter oldDelegate) {
    return oldDelegate.pulse != pulse;
  }
}

// ============================================================================
// ORBITING PARTICLES PAINTER
// ============================================================================

class _OrbitingParticlesPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final math.Random _random = math.Random(456);

  _OrbitingParticlesPainter({
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    const particleCount = 12;
    final orbitRadius = size.width * 0.38;

    for (int i = 0; i < particleCount; i++) {
      final particleAngle = (math.pi * 2 / particleCount) * i + (progress * math.pi * 2);
      final orbitOffset = _random.nextDouble() * 0.1 - 0.05;
      final currentRadius = orbitRadius * (1.0 + orbitOffset);

      final x = center.dx + math.cos(particleAngle) * currentRadius;
      final y = center.dy + math.sin(particleAngle) * currentRadius;

      // Particle trail
      final trailOpacity = 0.3 - (i % 3) * 0.1;
      paint.color = accentColor.withOpacity(trailOpacity);
      canvas.drawCircle(Offset(x, y), 2.5, paint);

      // Main particle
      paint.color = accentColor.withOpacity(0.8);
      canvas.drawCircle(Offset(x, y), 1.5, paint);

      // Bright core
      paint.color = Colors.white.withOpacity(0.6);
      canvas.drawCircle(Offset(x, y), 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbitingParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// DATA STREAM SEGMENTS PAINTER
// ============================================================================

class _DataStreamSegmentsPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _DataStreamSegmentsPainter({
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const segmentCount = 6;
    final radius = size.width * 0.42;

    for (int i = 0; i < segmentCount; i++) {
      final baseAngle = (math.pi * 2 / segmentCount) * i + (progress * math.pi * 2);
      final segmentLength = math.pi / 12; // ~15 degrees

      // Calculate opacity based on rotation position
      final normalizedAngle = (baseAngle % (math.pi * 2)) / (math.pi * 2);
      final opacity = 0.3 + math.sin(normalizedAngle * math.pi * 2) * 0.4;

      paint.color = accentColor.withOpacity(opacity);

      final startAngle = baseAngle;
      final endAngle = baseAngle + segmentLength;

      final startX = center.dx + math.cos(startAngle) * radius;
      final startY = center.dy + math.sin(startAngle) * radius;
      final endX = center.dx + math.cos(endAngle) * radius;
      final endY = center.dy + math.sin(endAngle) * radius;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);

      // Glow
      paint.color = accentColor.withOpacity(opacity * 0.3);
      paint.strokeWidth = 4;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      paint.strokeWidth = 2;
    }
  }

  @override
  bool shouldRepaint(_DataStreamSegmentsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// GLITCH LOADING TEXT
// ============================================================================

class _GlitchLoadingText extends StatelessWidget {
  final String text;
  final Color accentColor;
  final double glitchIntensity;

  const _GlitchLoadingText({
    required this.text,
    required this.accentColor,
    required this.glitchIntensity,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: 4,
    );

    return Stack(
      children: [
        // Glitch layers (only visible during glitch)
        if (glitchIntensity > 0) ...[
          // Red channel shift
          Transform.translate(
            offset: Offset(-glitchIntensity * 3, 0),
            child: Opacity(
              opacity: glitchIntensity * 0.6,
              child: Text(
                text,
                style: textStyle.copyWith(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 1
                    ..color = Colors.red,
                ),
              ),
            ),
          ),

          // Blue channel shift
          Transform.translate(
            offset: Offset(glitchIntensity * 3, 0),
            child: Opacity(
              opacity: glitchIntensity * 0.6,
              child: Text(
                text,
                style: textStyle.copyWith(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 1
                    ..color = Colors.blue,
                ),
              ),
            ),
          ),
        ],

        // Main text with glow
        Text(
          text,
          style: textStyle.copyWith(
            shadows: [
              Shadow(
                color: accentColor,
                blurRadius: 16,
              ),
              Shadow(
                color: accentColor.withOpacity(0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),

        // Animated dots
        Positioned(
          right: -20,
          bottom: 0,
          child: _AnimatedLoadingDots(accentColor: accentColor),
        ),
      ],
    );
  }
}

// ============================================================================
// ANIMATED LOADING DOTS
// ============================================================================

class _AnimatedLoadingDots extends StatefulWidget {
  final Color accentColor;

  const _AnimatedLoadingDots({required this.accentColor});

  @override
  State<_AnimatedLoadingDots> createState() => _AnimatedLoadingDotsState();
}

class _AnimatedLoadingDotsState extends State<_AnimatedLoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildDot(i),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDot(int index) {
    final delay = index * 0.2;
    final progress = ((_controller.value + delay) % 1.0);
    final opacity = (math.sin(progress * math.pi) * 0.8 + 0.2).clamp(0.0, 1.0);

    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: widget.accentColor.withOpacity(opacity),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withOpacity(opacity * 0.5),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
