import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// TRON-style button with wireframe materialization effect
/// Draws lines from center outward when appearing, with light trails
class TronButton extends StatefulWidget {
  const TronButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = NeonColors.cyan,
    this.secondaryColor,
    this.width = 280,
    this.height = 56,
    this.enabled = true,
    this.icon,
    this.delay = Duration.zero,
    this.materializationDuration = const Duration(milliseconds: 600),
  });

  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color? secondaryColor;
  final double width;
  final double height;
  final bool enabled;
  final IconData? icon;
  final Duration delay;
  final Duration materializationDuration;

  @override
  State<TronButton> createState() => _TronButtonState();
}

class _TronButtonState extends State<TronButton>
    with TickerProviderStateMixin {
  late AnimationController _materializeController;
  late AnimationController _pulseController;
  late AnimationController _hoverController;
  late Animation<double> _materializeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _hoverAnimation;

  bool _isHovered = false;
  bool _isPressed = false;
  bool _isMaterialized = false;

  @override
  void initState() {
    super.initState();

    _materializeController = AnimationController(
      duration: widget.materializationDuration,
      vsync: this,
    );

    _materializeAnimation = CurvedAnimation(
      parent: _materializeController,
      curve: Curves.easeOutCubic,
    );

    _materializeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isMaterialized = true);
      }
    });

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

    // Start materialization after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _materializeController.forward();
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _materializeController.dispose();
    _pulseController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    if (!_isMaterialized) return;
    setState(() => _isHovered = hovering);
    if (hovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.enabled ? widget.color : Colors.grey;
    final secondaryColor = widget.secondaryColor ?? const Color(0xFFFF6600);

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTapDown: (_) {
          if (_isMaterialized) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (_isMaterialized) {
            setState(() => _isPressed = false);
            if (widget.enabled) widget.onPressed();
          }
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _materializeAnimation,
            _pulseAnimation,
            _hoverAnimation,
          ]),
          builder: (context, child) {
            final materializeProgress = _materializeAnimation.value;
            final glowIntensity = _isHovered
                ? 1.0
                : 0.3 + _pulseAnimation.value * 0.4;
            final scale = _isPressed ? 0.96 : (_isHovered ? 1.03 : 1.0);
            final contentOpacity = materializeProgress.clamp(0.0, 1.0);

            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: CustomPaint(
                  painter: _TronButtonPainter(
                    progress: materializeProgress,
                    primaryColor: effectiveColor,
                    secondaryColor: secondaryColor,
                    glowIntensity: glowIntensity * materializeProgress,
                    isHovered: _isHovered,
                  ),
                  child: Opacity(
                    opacity: contentOpacity,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: effectiveColor,
                              size: 22,
                              shadows: [
                                Shadow(
                                  color: effectiveColor.withOpacity(0.8),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              fontFamily: NeonTextStyles.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: effectiveColor,
                              shadows: [
                                Shadow(
                                  color: effectiveColor.withOpacity(glowIntensity),
                                  blurRadius: 8,
                                ),
                                Shadow(
                                  color: effectiveColor.withOpacity(glowIntensity * 0.5),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TronButtonPainter extends CustomPainter {
  _TronButtonPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.glowIntensity,
    required this.isHovered,
  });

  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final double glowIntensity;
  final bool isHovered;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    // Background fill (fades in)
    if (progress > 0.3) {
      final bgOpacity = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);
      final bgPaint = Paint()
        ..color = Colors.black.withOpacity(0.7 * bgOpacity);
      canvas.drawRRect(rrect, bgPaint);
    }

    // Draw wireframe lines from center
    _drawWireframeLines(canvas, size, center);

    // Draw border with glow (appears after wireframe)
    if (progress > 0.5) {
      final borderProgress = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
      _drawBorder(canvas, size, borderProgress);
    }

    // Draw corner decorations
    if (progress > 0.7) {
      final cornerProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
      _drawCorners(canvas, size, cornerProgress);
    }

    // Draw light particles
    _drawParticles(canvas, size, center);
  }

  void _drawWireframeLines(Canvas canvas, Size size, Offset center) {
    if (progress <= 0) return;

    // Fade out internal wireframe lines after construction completes
    final fadeOutStart = 0.7;
    final fadeOutEnd = 1.0;
    final wireframeFade = progress >= fadeOutEnd
        ? 0.0
        : progress <= fadeOutStart
            ? 1.0
            : 1.0 - ((progress - fadeOutStart) / (fadeOutEnd - fadeOutStart));

    // Internal construction lines (these fade out)
    final internalLines = <_WireLine>[
      // Horizontal lines from center
      _WireLine(center, Offset(0, center.dy), 0.0, 0.4),
      _WireLine(center, Offset(size.width, center.dy), 0.0, 0.4),
      // Vertical lines from center
      _WireLine(center, Offset(center.dx, 0), 0.1, 0.5),
      _WireLine(center, Offset(center.dx, size.height), 0.1, 0.5),
      // Diagonal lines to corners
      _WireLine(center, Offset(0, 0), 0.2, 0.6),
      _WireLine(center, Offset(size.width, 0), 0.2, 0.6),
      _WireLine(center, Offset(0, size.height), 0.2, 0.6),
      _WireLine(center, Offset(size.width, size.height), 0.2, 0.6),
    ];

    // Only draw internal lines if they haven't faded out
    if (wireframeFade > 0) {
      for (final line in internalLines) {
        if (progress >= line.startTime) {
          final lineProgress = progress >= line.endTime
              ? 1.0
              : ((progress - line.startTime) / (line.endTime - line.startTime)).clamp(0.0, 1.0);

          final currentEnd = Offset.lerp(line.start, line.end, lineProgress)!;

          // Glow (fades out)
          final glowPaint = Paint()
            ..color = primaryColor.withOpacity(0.3 * glowIntensity * wireframeFade)
            ..strokeWidth = 4
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawLine(line.start, currentEnd, glowPaint);

          // Main line (fades out)
          final linePaint = Paint()
            ..color = primaryColor.withOpacity(0.8 * wireframeFade)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke;
          canvas.drawLine(line.start, currentEnd, linePaint);

          // Light trail at the end
          if (lineProgress > 0 && lineProgress < 1) {
            const trailLength = 0.15;
            final trailStart = math.max(0.0, lineProgress - trailLength);
            final trailStartPoint = Offset.lerp(line.start, line.end, trailStart)!;

            final trailPaint = Paint()
              ..shader = LinearGradient(
                colors: [
                  secondaryColor.withOpacity(0),
                  secondaryColor.withOpacity(0.8),
                  Colors.white,
                ],
                stops: const [0.0, 0.6, 1.0],
              ).createShader(Rect.fromPoints(trailStartPoint, currentEnd))
              ..strokeWidth = 3
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
            canvas.drawLine(trailStartPoint, currentEnd, trailPaint);

            // Bright point at the front
            final pointPaint = Paint()
              ..color = Colors.white
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
            canvas.drawCircle(currentEnd, 3, pointPaint);
          }
        }
      }
    }
  }

  void _drawBorder(Canvas canvas, Size size, double borderProgress) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    // Outer glow
    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(glowIntensity * 0.4 * borderProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(rrect, glowPaint);

    // Border
    final borderPaint = Paint()
      ..color = primaryColor.withOpacity(borderProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, borderPaint);
  }

  void _drawCorners(Canvas canvas, Size size, double cornerProgress) {
    const cornerSize = 12.0;
    final cornerPaint = Paint()
      ..color = primaryColor.withOpacity(cornerProgress)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Top-left
    canvas.drawLine(
      const Offset(4, 4),
      Offset(4, 4 + cornerSize * cornerProgress),
      cornerPaint,
    );
    canvas.drawLine(
      const Offset(4, 4),
      Offset(4 + cornerSize * cornerProgress, 4),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - 4, 4),
      Offset(size.width - 4, 4 + cornerSize * cornerProgress),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - 4, 4),
      Offset(size.width - 4 - cornerSize * cornerProgress, 4),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(4, size.height - 4),
      Offset(4, size.height - 4 - cornerSize * cornerProgress),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(4, size.height - 4),
      Offset(4 + cornerSize * cornerProgress, size.height - 4),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - 4, size.height - 4),
      Offset(size.width - 4, size.height - 4 - cornerSize * cornerProgress),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - 4, size.height - 4),
      Offset(size.width - 4 - cornerSize * cornerProgress, size.height - 4),
      cornerPaint,
    );
  }

  void _drawParticles(Canvas canvas, Size size, Offset center) {
    if (progress < 0.2 || progress > 0.8) return;

    final random = math.Random(42); // Fixed seed for consistent particles
    final particleProgress = ((progress - 0.2) / 0.6).clamp(0.0, 1.0);

    for (int i = 0; i < 8; i++) {
      final spawnTime = random.nextDouble() * 0.5;
      if (particleProgress < spawnTime) continue;

      final age = particleProgress - spawnTime;
      if (age > 0.4) continue;

      final alpha = (1.0 - age / 0.4).clamp(0.0, 1.0);
      final angle = random.nextDouble() * math.pi * 2;
      final distance = random.nextDouble() * size.width * 0.4 * (1 + age);

      final pos = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      // Glow
      final glowPaint = Paint()
        ..color = secondaryColor.withOpacity(alpha * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pos, 4, glowPaint);

      // Core
      final corePaint = Paint()
        ..color = Colors.white.withOpacity(alpha);
      canvas.drawCircle(pos, 2, corePaint);
    }
  }

  @override
  bool shouldRepaint(_TronButtonPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        glowIntensity != oldDelegate.glowIntensity ||
        isHovered != oldDelegate.isHovered;
  }
}

class _WireLine {
  final Offset start;
  final Offset end;
  final double startTime;
  final double endTime;

  _WireLine(this.start, this.end, this.startTime, this.endTime);
}
