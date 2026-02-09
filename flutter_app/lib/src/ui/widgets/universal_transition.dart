import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Epic page transitions for consistent visual language across the entire app.
///
/// Usage with Navigator:
/// ```dart
/// Navigator.of(context).push(
///   UniversalTransition.dataStreamWipe(
///     builder: (context) => NewScreen(),
///   ),
/// );
/// ```
class UniversalTransition {
  /// Data stream wipe transition - Data streams wipe across revealing new screen
  static PageRouteBuilder<T> dataStreamWipe<T>({
    required WidgetBuilder builder,
    Duration duration = const Duration(milliseconds: 500),
    Color streamColor = const Color(0xFF00FFFF),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return Stack(
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                ),
              ),
              child: child,
            ),
            _DataStreamWipeEffect(
              animation: animation,
              streamColor: streamColor,
            ),
          ],
        );
      },
    );
  }

  /// Hexagon tile reveal - Hexagonal tiles expand from center
  static PageRouteBuilder<T> hexagonReveal<T>({
    required WidgetBuilder builder,
    Duration duration = const Duration(milliseconds: 600),
    Color hexColor = const Color(0xFF00FFFF),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return Stack(
          children: [
            child,
            _HexagonRevealEffect(
              animation: animation,
              hexColor: hexColor,
            ),
          ],
        );
      },
    );
  }

  /// Energy burst transition - Energy burst from center revealing screen
  static PageRouteBuilder<T> energyBurst<T>({
    required WidgetBuilder builder,
    Duration duration = const Duration(milliseconds: 550),
    Color burstColor = const Color(0xFF00FFFF),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return Stack(
          children: [
            FadeTransition(
              opacity: animation,
              child: child,
            ),
            _EnergyBurstEffect(
              animation: animation,
              burstColor: burstColor,
            ),
          ],
        );
      },
    );
  }

  /// Glitch distortion transition - Screen glitches and distorts during transition
  static PageRouteBuilder<T> glitchDistortion<T>({
    required WidgetBuilder builder,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _GlitchDistortionTransition(
          animation: animation,
          child: child,
        );
      },
    );
  }

  /// Default epic transition - Combines multiple effects for maximum impact
  static PageRouteBuilder<T> epic<T>({
    required WidgetBuilder builder,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return dataStreamWipe<T>(builder: builder, duration: duration);
  }
}

// ============================================================================
// DATA STREAM WIPE EFFECT
// ============================================================================

class _DataStreamWipeEffect extends StatelessWidget {
  final Animation<double> animation;
  final Color streamColor;

  const _DataStreamWipeEffect({
    required this.animation,
    required this.streamColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        if (animation.value >= 0.8) return const SizedBox.shrink();

        return CustomPaint(
          painter: _DataStreamWipePainter(
            progress: animation.value,
            streamColor: streamColor,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _DataStreamWipePainter extends CustomPainter {
  final double progress;
  final Color streamColor;
  final math.Random _random = math.Random(42); // Deterministic

  _DataStreamWipePainter({
    required this.progress,
    required this.streamColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const streamCount = 30;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < streamCount; i++) {
      final streamProgress = ((progress * streamCount) - i).clamp(0.0, 1.0);
      if (streamProgress <= 0) continue;

      final x = (size.width / streamCount) * i;
      final height = size.height * streamProgress;
      final opacity = (1.0 - streamProgress) * 0.6;

      // Main stream
      paint.color = streamColor.withOpacity(opacity);
      canvas.drawRect(
        Rect.fromLTWH(x, 0, size.width / streamCount, height),
        paint,
      );

      // Glow effect
      paint.color = streamColor.withOpacity(opacity * 0.3);
      canvas.drawRect(
        Rect.fromLTWH(x - 4, 0, (size.width / streamCount) + 8, height),
        paint,
      );

      // Data particles
      final particleCount = 5;
      for (int p = 0; p < particleCount; p++) {
        final particleY = height * (_random.nextDouble() * 0.3 + 0.7);
        final particleSize = 2.0 + _random.nextDouble() * 2;

        paint.color = streamColor.withOpacity(opacity * 0.8);
        canvas.drawCircle(
          Offset(x + (size.width / streamCount) / 2, particleY),
          particleSize,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DataStreamWipePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// HEXAGON REVEAL EFFECT
// ============================================================================

class _HexagonRevealEffect extends StatelessWidget {
  final Animation<double> animation;
  final Color hexColor;

  const _HexagonRevealEffect({
    required this.animation,
    required this.hexColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        if (animation.value >= 1.0) return const SizedBox.shrink();

        return IgnorePointer(
          child: CustomPaint(
            painter: _HexagonRevealPainter(
              progress: animation.value,
              hexColor: hexColor,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _HexagonRevealPainter extends CustomPainter {
  final double progress;
  final Color hexColor;

  _HexagonRevealPainter({
    required this.progress,
    required this.hexColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hexSize = 40.0;
    final cols = (size.width / (hexSize * 1.5)).ceil() + 2;
    final rows = (size.height / (hexSize * math.sqrt(3))).ceil() + 2;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxDistance = math.sqrt(centerX * centerX + centerY * centerY);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = hexColor;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = col * hexSize * 1.5;
        final y = row * hexSize * math.sqrt(3) + (col.isOdd ? hexSize * math.sqrt(3) / 2 : 0);

        final distance = math.sqrt(
          (x - centerX) * (x - centerX) + (y - centerY) * (y - centerY),
        );
        final normalizedDistance = distance / maxDistance;

        // Hexagons expand from center
        final hexProgress = ((progress * 1.5) - normalizedDistance).clamp(0.0, 1.0);
        if (hexProgress <= 0) continue;

        final hexAlpha = (1.0 - hexProgress).clamp(0.0, 1.0);
        final currentSize = hexSize * hexProgress;

        paint.color = hexColor.withOpacity(hexAlpha * 0.5);
        _drawHexagon(canvas, Offset(x, y), currentSize, paint);

        // Inner glow
        paint.color = hexColor.withOpacity(hexAlpha * 0.2);
        _drawHexagon(canvas, Offset(x, y), currentSize + 4, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
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
  bool shouldRepaint(_HexagonRevealPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// ENERGY BURST EFFECT
// ============================================================================

class _EnergyBurstEffect extends StatelessWidget {
  final Animation<double> animation;
  final Color burstColor;

  const _EnergyBurstEffect({
    required this.animation,
    required this.burstColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        if (animation.value >= 0.6) return const SizedBox.shrink();

        return IgnorePointer(
          child: CustomPaint(
            painter: _EnergyBurstPainter(
              progress: animation.value,
              burstColor: burstColor,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _EnergyBurstPainter extends CustomPainter {
  final double progress;
  final Color burstColor;
  final math.Random _random = math.Random(123); // Deterministic

  _EnergyBurstPainter({
    required this.progress,
    required this.burstColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // Central flash
    if (progress < 0.3) {
      final flashProgress = (progress / 0.3);
      final flashOpacity = (1.0 - flashProgress) * 0.8;

      paint.color = Colors.white.withOpacity(flashOpacity);
      canvas.drawCircle(center, maxRadius * flashProgress, paint);
    }

    // Energy rings expanding
    const ringCount = 5;
    for (int i = 0; i < ringCount; i++) {
      final ringDelay = i * 0.1;
      final ringProgress = ((progress - ringDelay) / (1.0 - ringDelay)).clamp(0.0, 1.0);
      if (ringProgress <= 0) continue;

      final radius = maxRadius * ringProgress;
      final opacity = (1.0 - ringProgress) * 0.4;

      paint.color = burstColor.withOpacity(opacity);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3.0;
      canvas.drawCircle(center, radius, paint);
    }

    // Burst particles
    paint.style = PaintingStyle.fill;
    const particleCount = 40;
    for (int i = 0; i < particleCount; i++) {
      final angle = (math.pi * 2 / particleCount) * i + _random.nextDouble() * 0.2;
      final particleProgress = (progress * (1.0 + _random.nextDouble() * 0.3)).clamp(0.0, 1.0);

      final distance = maxRadius * particleProgress * (0.5 + _random.nextDouble() * 0.5);
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;

      final size = (2.0 + _random.nextDouble() * 3) * (1.0 - particleProgress);
      final opacity = (1.0 - particleProgress) * 0.6;

      paint.color = burstColor.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), size, paint);
    }
  }

  @override
  bool shouldRepaint(_EnergyBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// GLITCH DISTORTION TRANSITION
// ============================================================================

class _GlitchDistortionTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _GlitchDistortionTransition({
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Glitch effect peaks at 0.3-0.5, then fades
        final glitchIntensity = _calculateGlitchIntensity(animation.value);

        return Stack(
          children: [
            // Base layer with opacity fade
            Opacity(
              opacity: animation.value,
              child: child,
            ),

            // Glitch layers
            if (glitchIntensity > 0) ...[
              // Red channel shift
              Positioned.fill(
                child: FractionalTranslation(
                  translation: Offset(-glitchIntensity * 0.02, 0),
                  child: Opacity(
                    opacity: glitchIntensity * 0.5,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFFF0000),
                        BlendMode.screen,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),

              // Blue channel shift
              Positioned.fill(
                child: FractionalTranslation(
                  translation: Offset(glitchIntensity * 0.02, 0),
                  child: Opacity(
                    opacity: glitchIntensity * 0.5,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF0000FF),
                        BlendMode.screen,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
      child: child,
    );
  }

  double _calculateGlitchIntensity(double progress) {
    // Glitch is strongest at 0.3-0.5 of transition
    if (progress < 0.2 || progress > 0.6) return 0.0;

    if (progress < 0.4) {
      // Ramp up
      return (progress - 0.2) / 0.2;
    } else {
      // Ramp down
      return (0.6 - progress) / 0.2;
    }
  }
}
