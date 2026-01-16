import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// TRON-style card with wireframe materialization effect
class TronCard extends StatefulWidget {
  const TronCard({
    super.key,
    required this.child,
    this.color = NeonColors.cyan,
    this.secondaryColor,
    this.delay = Duration.zero,
    this.materializationDuration = const Duration(milliseconds: 500),
    this.width,
    this.height,
    this.onTap,
    this.borderRadius = 12.0,
    this.enabled = true,
  });

  final Widget child;
  final Color color;
  final Color? secondaryColor;
  final Duration delay;
  final Duration materializationDuration;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool enabled;

  @override
  State<TronCard> createState() => _TronCardState();
}

class _TronCardState extends State<TronCard>
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
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

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
    if (!_isMaterialized || !widget.enabled) return;
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
          if (_isMaterialized && widget.enabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (_isMaterialized && widget.enabled) {
            setState(() => _isPressed = false);
            widget.onTap?.call();
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
            final progress = _materializeAnimation.value;
            final glowIntensity = _isHovered ? 1.0 : _pulseAnimation.value;
            final scale = _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0);

            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: CustomPaint(
                  painter: _TronCardPainter(
                    progress: progress,
                    primaryColor: effectiveColor,
                    secondaryColor: secondaryColor,
                    glowIntensity: glowIntensity * progress,
                    isHovered: _isHovered,
                    borderRadius: widget.borderRadius,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: Opacity(
                      opacity: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: NeonColors.darkBg.withOpacity(0.85 * progress),
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                        ),
                        child: widget.child,
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

class _TronCardPainter extends CustomPainter {
  _TronCardPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.glowIntensity,
    required this.isHovered,
    required this.borderRadius,
  });

  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final double glowIntensity;
  final bool isHovered;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final center = Offset(size.width / 2, size.height / 2);

    // Draw wireframe construction
    _drawWireframe(canvas, size, center);

    // Draw border with glow
    if (progress > 0.4) {
      final borderProgress = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
      _drawBorder(canvas, rrect, borderProgress);
    }

    // Draw corner accents
    if (progress > 0.6) {
      final cornerProgress = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
      _drawCorners(canvas, size, cornerProgress);
    }
  }

  void _drawWireframe(Canvas canvas, Size size, Offset center) {
    if (progress <= 0) return;

    // Fade out internal wireframe lines completely after construction
    final fadeOutStart = 0.6;
    final fadeOutEnd = 1.0;
    final wireframeFade = progress >= fadeOutEnd
        ? 0.0
        : progress <= fadeOutStart
            ? 1.0
            : 1.0 - ((progress - fadeOutStart) / (fadeOutEnd - fadeOutStart));

    // Internal construction lines (these fade out completely)
    final internalLines = <_CardLine>[
      // From center to edges
      _CardLine(center, Offset(0, center.dy), 0.0, 0.3),
      _CardLine(center, Offset(size.width, center.dy), 0.0, 0.3),
      _CardLine(center, Offset(center.dx, 0), 0.05, 0.35),
      _CardLine(center, Offset(center.dx, size.height), 0.05, 0.35),
      // Diagonals
      _CardLine(center, Offset.zero, 0.1, 0.4),
      _CardLine(center, Offset(size.width, 0), 0.1, 0.4),
      _CardLine(center, Offset(0, size.height), 0.1, 0.4),
      _CardLine(center, Offset(size.width, size.height), 0.1, 0.4),
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
            ..color = primaryColor.withOpacity(0.2 * wireframeFade)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawLine(line.start, currentEnd, glowPaint);

          // Line (fades out)
          final linePaint = Paint()
            ..color = primaryColor.withOpacity(0.5 * wireframeFade)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke;
          canvas.drawLine(line.start, currentEnd, linePaint);

          // Trail
          if (lineProgress > 0 && lineProgress < 1) {
            const trailLength = 0.2;
            final trailStart = math.max(0.0, lineProgress - trailLength);
            final trailStartPoint = Offset.lerp(line.start, line.end, trailStart)!;

            final trailPaint = Paint()
              ..shader = LinearGradient(
                colors: [
                  secondaryColor.withOpacity(0),
                  secondaryColor.withOpacity(0.6),
                  Colors.white,
                ],
              ).createShader(Rect.fromPoints(trailStartPoint, currentEnd))
              ..strokeWidth = 2
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
            canvas.drawLine(trailStartPoint, currentEnd, trailPaint);

            // Bright point
            final pointPaint = Paint()
              ..color = Colors.white.withOpacity(0.8)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
            canvas.drawCircle(currentEnd, 2, pointPaint);
          }
        }
      }
    }
  }

  void _drawBorder(Canvas canvas, RRect rrect, double borderProgress) {
    // Glow
    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(glowIntensity * 0.3 * borderProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(rrect, glowPaint);

    // Border
    final borderPaint = Paint()
      ..color = primaryColor.withOpacity(borderProgress * (isHovered ? 1.0 : 0.6))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovered ? 2.0 : 1.5;
    canvas.drawRRect(rrect, borderPaint);
  }

  void _drawCorners(Canvas canvas, Size size, double cornerProgress) {
    const cornerSize = 16.0;
    final paint = Paint()
      ..color = primaryColor.withOpacity(cornerProgress * (isHovered ? 1.0 : 0.7))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Top-left
    canvas.drawLine(
      Offset(4, 4 + cornerSize * cornerProgress),
      const Offset(4, 4),
      paint,
    );
    canvas.drawLine(
      const Offset(4, 4),
      Offset(4 + cornerSize * cornerProgress, 4),
      paint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - 4, 4 + cornerSize * cornerProgress),
      Offset(size.width - 4, 4),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 4, 4),
      Offset(size.width - 4 - cornerSize * cornerProgress, 4),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(4, size.height - 4 - cornerSize * cornerProgress),
      Offset(4, size.height - 4),
      paint,
    );
    canvas.drawLine(
      Offset(4, size.height - 4),
      Offset(4 + cornerSize * cornerProgress, size.height - 4),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - 4, size.height - 4 - cornerSize * cornerProgress),
      Offset(size.width - 4, size.height - 4),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 4, size.height - 4),
      Offset(size.width - 4 - cornerSize * cornerProgress, size.height - 4),
      paint,
    );

    // Corner dots
    if (isHovered) {
      final dotPaint = Paint()
        ..color = primaryColor.withOpacity(cornerProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(const Offset(4, 4), 3, dotPaint);
      canvas.drawCircle(Offset(size.width - 4, 4), 3, dotPaint);
      canvas.drawCircle(Offset(4, size.height - 4), 3, dotPaint);
      canvas.drawCircle(Offset(size.width - 4, size.height - 4), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_TronCardPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        glowIntensity != oldDelegate.glowIntensity ||
        isHovered != oldDelegate.isHovered;
  }
}

class _CardLine {
  final Offset start;
  final Offset end;
  final double startTime;
  final double endTime;

  _CardLine(this.start, this.end, this.startTime, this.endTime);
}
