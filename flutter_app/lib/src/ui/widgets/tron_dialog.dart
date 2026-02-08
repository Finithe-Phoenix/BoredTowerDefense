import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// TRON-style dialog with wireframe materialization effect
class TronDialog extends StatefulWidget {
  const TronDialog({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.primaryColor = NeonColors.cyan,
    this.secondaryColor,
    this.width = 400,
    this.onClose,
    this.showCloseButton = true,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Color primaryColor;
  final Color? secondaryColor;
  final double width;
  final VoidCallback? onClose;
  final bool showCloseButton;

  /// Shows a TronDialog with materialization animation
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? title,
    IconData? icon,
    Color primaryColor = NeonColors.cyan,
    Color? secondaryColor,
    double width = 400,
    bool barrierDismissible = true,
    bool showCloseButton = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: title ?? 'Dialog',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: TronDialog(
            title: title,
            icon: icon,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            width: width,
            showCloseButton: showCloseButton,
            onClose: () => Navigator.pop(context),
            child: builder(context),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  @override
  State<TronDialog> createState() => _TronDialogState();
}

class _TronDialogState extends State<TronDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _materializeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _materializeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secondaryColor = widget.secondaryColor ?? const Color(0xFFFF6600);

    return AnimatedBuilder(
      animation: _materializeAnimation,
      builder: (context, child) {
        final progress = _materializeAnimation.value;

        return Material(
          color: Colors.transparent,
          child: SizedBox(
            width: widget.width,
            child: CustomPaint(
              painter: _TronDialogPainter(
                progress: progress,
                primaryColor: widget.primaryColor,
                secondaryColor: secondaryColor,
              ),
              child: Opacity(
                opacity: (progress * 1.5).clamp(0.0, 1.0),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      color: NeonColors.darkBg.withOpacity(0.95 * progress),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        if (widget.title != null || widget.showCloseButton)
                          _buildHeader(progress),

                        // Content
                        Transform.scale(
                          scale: 0.9 + 0.1 * progress,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: widget.child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.primaryColor.withOpacity(0.3 * progress),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              color: widget.primaryColor.withOpacity(progress),
              size: 28,
              shadows: [
                Shadow(
                  color: widget.primaryColor.withOpacity(0.8 * progress),
                  blurRadius: 10,
                ),
              ],
            ),
            const SizedBox(width: 12),
          ],
          if (widget.title != null)
            Expanded(
              child: Text(
                widget.title!,
                style: NeonTextStyles.subtitle.copyWith(
                  color: widget.primaryColor.withOpacity(progress),
                  letterSpacing: 4,
                ),
              ),
            ),
          if (widget.showCloseButton)
            IconButton(
              icon: Icon(
                Icons.close,
                color: widget.primaryColor.withOpacity(0.7 * progress),
              ),
              onPressed: widget.onClose,
            ),
        ],
      ),
    );
  }
}

class _TronDialogPainter extends CustomPainter {
  _TronDialogPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  static final Paint _borderGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _wireGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _wireLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _trailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _pointPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _cornerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _cornerGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _cornerDotPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Map<int, Shader> _trailShaderCache = {};
  final Path _cornerPath = Path();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Draw wireframe construction
    _drawWireframe(canvas, size, center);

    // Draw border
    if (progress > 0.4) {
      final borderProgress = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);

      // Glow
      _borderGlowPaint.color = primaryColor.withOpacity(0.4 * borderProgress);
      canvas.drawRRect(rrect, _borderGlowPaint);

      // Border
      _borderPaint.color = primaryColor.withOpacity(borderProgress);
      canvas.drawRRect(rrect, _borderPaint);
    }

    // Corner accents
    if (progress > 0.6) {
      final cornerProgress = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
      _drawCornerAccents(canvas, size, cornerProgress);
    }
  }

  void _drawWireframe(Canvas canvas, Size size, Offset center) {
    if (progress <= 0) return;
    if (size.width <= 0 || size.height <= 0) return;

    final lines = <_DialogLine>[
      // From center outward - horizontal
      _DialogLine(center, Offset(0, center.dy), 0.0, 0.3),
      _DialogLine(center, Offset(size.width, center.dy), 0.0, 0.3),
      // From center outward - vertical
      _DialogLine(center, Offset(center.dx, 0), 0.05, 0.35),
      _DialogLine(center, Offset(center.dx, size.height), 0.05, 0.35),
      // Diagonals to corners
      _DialogLine(center, Offset.zero, 0.1, 0.4),
      _DialogLine(center, Offset(size.width, 0), 0.1, 0.4),
      _DialogLine(center, Offset(0, size.height), 0.1, 0.4),
      _DialogLine(center, Offset(size.width, size.height), 0.1, 0.4),
      // Border construction
      _DialogLine(Offset.zero, Offset(size.width, 0), 0.3, 0.5),
      _DialogLine(Offset(size.width, 0), Offset(size.width, size.height), 0.35, 0.55),
      _DialogLine(Offset(size.width, size.height), Offset(0, size.height), 0.4, 0.6),
      _DialogLine(Offset(0, size.height), Offset.zero, 0.45, 0.65),
    ];

    for (final line in lines) {
      if (progress >= line.startTime) {
        final lineProgress = progress >= line.endTime
            ? 1.0
            : ((progress - line.startTime) / (line.endTime - line.startTime)).clamp(0.0, 1.0);

        final currentEnd = Offset.lerp(line.start, line.end, lineProgress)!;

        // Fading glow as line completes
        final fadeOut = progress > 0.5 ? 1.0 - ((progress - 0.5) / 0.5) : 1.0;

        // Glow
        _wireGlowPaint.color = primaryColor.withOpacity(0.3 * fadeOut);
        canvas.drawLine(line.start, currentEnd, _wireGlowPaint);

        // Line
        _wireLinePaint.color = primaryColor.withOpacity(0.6 * fadeOut);
        canvas.drawLine(line.start, currentEnd, _wireLinePaint);

        // Trail effect
        if (lineProgress > 0 && lineProgress < 1) {
          const trailLength = 0.2;
          final trailStart = math.max(0.0, lineProgress - trailLength);
          final trailStartPoint = Offset.lerp(line.start, line.end, trailStart)!;

          final dx = currentEnd.dx - trailStartPoint.dx;
          final dy = currentEnd.dy - trailStartPoint.dy;
          final length = math.sqrt(dx * dx + dy * dy);
          if (length > 0.01) {
            final lenKey = (length * 4).round();
            final shaderKey = (secondaryColor.value << 8) ^ lenKey;
            final shader = _trailShaderCache.putIfAbsent(
              shaderKey,
              () {
                if (_trailShaderCache.length > 128) {
                  _trailShaderCache.clear();
                }
                return LinearGradient(
                colors: [
                  secondaryColor.withOpacity(0),
                  secondaryColor.withOpacity(0.8),
                  Colors.white,
                ],
              ).createShader(Rect.fromLTWH(0, 0, lenKey / 4.0, 1));
              },
            );
            _trailPaint.shader = shader;
            canvas.save();
            canvas.translate(trailStartPoint.dx, trailStartPoint.dy);
            canvas.rotate(math.atan2(dy, dx));
            canvas.drawLine(Offset.zero, Offset(length, 0), _trailPaint);
            canvas.restore();
            _trailPaint.shader = null;
          }

          // Bright point
          _pointPaint.color = Colors.white;
          canvas.drawCircle(currentEnd, 2, _pointPaint);
        }
      }
    }
  }

  void _drawCornerAccents(Canvas canvas, Size size, double cornerProgress) {
    const cornerSize = 20.0;
    _cornerPaint.color = primaryColor.withOpacity(cornerProgress);
    _cornerGlowPaint.color = primaryColor.withOpacity(0.5 * cornerProgress);

    // Draw corner L-shapes with glow
    final corners = [
      [Offset(4, 4 + cornerSize), const Offset(4, 4), Offset(4 + cornerSize, 4)],
      [Offset(size.width - 4, 4 + cornerSize), Offset(size.width - 4, 4), Offset(size.width - 4 - cornerSize, 4)],
      [Offset(4, size.height - 4 - cornerSize), Offset(4, size.height - 4), Offset(4 + cornerSize, size.height - 4)],
      [Offset(size.width - 4, size.height - 4 - cornerSize), Offset(size.width - 4, size.height - 4), Offset(size.width - 4 - cornerSize, size.height - 4)],
    ];

    for (final corner in corners) {
      _cornerPath
        ..reset()
        ..moveTo(corner[0].dx, corner[0].dy)
        ..lineTo(corner[1].dx, corner[1].dy)
        ..lineTo(corner[2].dx, corner[2].dy);

      canvas.drawPath(_cornerPath, _cornerGlowPaint);
      canvas.drawPath(_cornerPath, _cornerPaint);

      // Small dot at the corner
      _cornerDotPaint.color = primaryColor.withOpacity(cornerProgress);
      canvas.drawCircle(
        corner[1],
        3,
        _cornerDotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TronDialogPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

class _DialogLine {
  final Offset start;
  final Offset end;
  final double startTime;
  final double endTime;

  _DialogLine(this.start, this.end, this.startTime, this.endTime);
}
