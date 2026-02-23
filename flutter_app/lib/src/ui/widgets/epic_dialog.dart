import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Epic holographic dialog with animated border construction, corner power
/// indicators, and advanced visual effects.
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => EpicDialog(
///     title: 'Confirm Action',
///     content: 'Are you sure you want to proceed?',
///     actions: [
///       EpicDialogAction(
///         label: 'Cancel',
///         onPressed: () => Navigator.pop(context),
///       ),
///       EpicDialogAction(
///         label: 'Confirm',
///         isPrimary: true,
///         onPressed: () {
///           // Handle confirmation
///           Navigator.pop(context);
///         },
///       ),
///     ],
///   ),
/// );
/// ```
class EpicDialog extends StatefulWidget {
  final String title;
  final String? content;
  final Widget? customContent;
  final List<EpicDialogAction> actions;
  final Color accentColor;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const EpicDialog({
    super.key,
    required this.title,
    this.content,
    this.customContent,
    this.actions = const [],
    this.accentColor = const Color(0xFF00FFFF),
    this.showCloseButton = true,
    this.onClose,
  }) : assert(
          content != null || customContent != null,
          'Either content or customContent must be provided',
        );

  @override
  State<EpicDialog> createState() => _EpicDialogState();

  /// Show an epic confirmation dialog
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color accentColor = const Color(0xFF00FFFF),
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => EpicDialog(
        title: title,
        content: message,
        accentColor: accentColor,
        actions: [
          EpicDialogAction(
            label: cancelLabel,
            onPressed: () => Navigator.pop(context, false),
          ),
          EpicDialogAction(
            label: confirmLabel,
            isPrimary: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  /// Show an epic info dialog
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String okLabel = 'OK',
    Color accentColor = const Color(0xFF00FFFF),
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => EpicDialog(
        title: title,
        content: message,
        accentColor: accentColor,
        actions: [
          EpicDialogAction(
            label: okLabel,
            isPrimary: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _EpicDialogState extends State<EpicDialog>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _borderController;
  late AnimationController _cornerController;
  late AnimationController _contentController;

  @override
  void initState() {
    super.initState();

    // Border construction animation
    _borderController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Corner power indicators
    _cornerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Content fade-in sequence
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Entrance animation
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Sequence: entrance -> border -> content
    _entranceController.forward().then((_) {
      _borderController.forward().then((_) {
        _contentController.forward();
      });
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _borderController.dispose();
    _cornerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _entranceController,
        builder: (context, child) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(
                parent: _entranceController,
                curve: Curves.easeOutBack,
              ),
            ),
            child: FadeTransition(
              opacity: _entranceController,
              child: child,
            ),
          );
        },
        child: _buildDialogContent(),
      ),
    );
  }

  Widget _buildDialogContent() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Stack(
        children: [
          // Backdrop blur effect
          Positioned.fill(
            child: _BackdropEffect(accentColor: widget.accentColor),
          ),

          // Animated border construction
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _borderController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _DialogBorderPainter(
                    progress: _borderController.value,
                    accentColor: widget.accentColor,
                  ),
                );
              },
            ),
          ),

          // Corner power indicators
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _cornerController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CornerIndicatorsPainter(
                    progress: _cornerController.value,
                    accentColor: widget.accentColor,
                  ),
                );
              },
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Row(
                  children: [
                    Expanded(
                      child: FadeTransition(
                        opacity: _contentController,
                        child: _HolographicTitle(
                          text: widget.title,
                          accentColor: widget.accentColor,
                        ),
                      ),
                    ),
                    if (widget.showCloseButton) _buildCloseButton(),
                  ],
                ),

                const SizedBox(height: 24),

                // Content
                FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _contentController,
                      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                    ),
                  ),
                  child: widget.customContent ??
                      Text(
                        widget.content!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                ),

                if (widget.actions.isNotEmpty) ...[
                  const SizedBox(height: 32),

                  // Actions
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _contentController,
                        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (int i = 0; i < widget.actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          _EpicDialogActionButton(
                            action: widget.actions[i],
                            accentColor: widget.accentColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onClose ?? () => Navigator.of(context).pop(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.accentColor.withOpacity(0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              // Rotating hexagon background on hover
              Center(
                child: AnimatedBuilder(
                  animation: _cornerController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _cornerController.value * math.pi * 2,
                      child: CustomPaint(
                        size: const Size(20, 20),
                        painter: _HexagonPainter(
                          color: widget.accentColor.withOpacity(0.2),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // X icon
              Center(
                child: Icon(
                  Icons.close,
                  color: widget.accentColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DIALOG ACTION
// ============================================================================

class EpicDialogAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color? customColor;

  const EpicDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.customColor,
  });
}

// ============================================================================
// ACTION BUTTON
// ============================================================================

class _EpicDialogActionButton extends StatefulWidget {
  final EpicDialogAction action;
  final Color accentColor;

  const _EpicDialogActionButton({
    required this.action,
    required this.accentColor,
  });

  @override
  State<_EpicDialogActionButton> createState() =>
      _EpicDialogActionButtonState();
}

class _EpicDialogActionButtonState extends State<_EpicDialogActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.action.customColor ?? widget.accentColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTap: widget.action.onPressed,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            final glowIntensity = _hoverController.value;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: widget.action.isPrimary
                    ? color.withOpacity(0.2 + glowIntensity * 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: color.withOpacity(0.6 + glowIntensity * 0.4),
                  width: widget.action.isPrimary ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  if (widget.action.isPrimary)
                    BoxShadow(
                      color: color.withOpacity(0.3 + glowIntensity * 0.2),
                      blurRadius: 8 + glowIntensity * 8,
                      spreadRadius: 0,
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // Hover particles
                  if (_isHovered)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _HoverParticlesPainter(
                          progress: _hoverController.value,
                          color: color,
                        ),
                      ),
                    ),

                  // Label
                  Text(
                    widget.action.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: widget.action.isPrimary
                          ? FontWeight.bold
                          : FontWeight.normal,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// VISUAL EFFECTS PAINTERS
// ============================================================================

class _BackdropEffect extends StatelessWidget {
  final Color accentColor;

  const _BackdropEffect({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F).withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: _ScanlinesOverlayPainter(),
        ),
      ),
    );
  }
}

class _ScanlinesOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DialogBorderPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _DialogBorderPainter({
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final borderLength = (size.width + size.height) * 2;
    final drawLength = borderLength * progress;

    // Draw animated border construction
    final path = Path();

    // Top edge
    if (drawLength > 0) {
      final topLength = math.min(drawLength, size.width);
      path.moveTo(0, 0);
      path.lineTo(topLength, 0);
    }

    // Right edge
    if (drawLength > size.width) {
      final rightLength = math.min(drawLength - size.width, size.height);
      path.moveTo(size.width, 0);
      path.lineTo(size.width, rightLength);
    }

    // Bottom edge
    if (drawLength > size.width + size.height) {
      final bottomLength = math.min(
        drawLength - size.width - size.height,
        size.width,
      );
      path.moveTo(size.width, size.height);
      path.lineTo(size.width - bottomLength, size.height);
    }

    // Left edge
    if (drawLength > size.width * 2 + size.height) {
      final leftLength = math.min(
        drawLength - size.width * 2 - size.height,
        size.height,
      );
      path.moveTo(0, size.height);
      path.lineTo(0, size.height - leftLength);
    }

    // Main border
    paint.color = accentColor;
    canvas.drawPath(path, paint);

    // Glow
    paint.color = accentColor.withOpacity(0.3);
    paint.strokeWidth = 4;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DialogBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CornerIndicatorsPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _CornerIndicatorsPainter({
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const cornerSize = 16.0;
    final corners = [
      Offset(0, 0), // Top-left
      Offset(size.width, 0), // Top-right
      Offset(size.width, size.height), // Bottom-right
      Offset(0, size.height), // Bottom-left
    ];

    for (int i = 0; i < corners.length; i++) {
      final corner = corners[i];
      final angle = (progress + i * 0.25) % 1.0;
      final opacity = 0.4 + math.sin(angle * math.pi * 2) * 0.3;

      paint.color = accentColor.withOpacity(opacity);

      // Draw corner brackets
      final path = Path();

      if (i == 0) {
        // Top-left
        path.moveTo(corner.dx + cornerSize, corner.dy);
        path.lineTo(corner.dx, corner.dy);
        path.lineTo(corner.dx, corner.dy + cornerSize);
      } else if (i == 1) {
        // Top-right
        path.moveTo(corner.dx - cornerSize, corner.dy);
        path.lineTo(corner.dx, corner.dy);
        path.lineTo(corner.dx, corner.dy + cornerSize);
      } else if (i == 2) {
        // Bottom-right
        path.moveTo(corner.dx - cornerSize, corner.dy);
        path.lineTo(corner.dx, corner.dy);
        path.lineTo(corner.dx, corner.dy - cornerSize);
      } else {
        // Bottom-left
        path.moveTo(corner.dx + cornerSize, corner.dy);
        path.lineTo(corner.dx, corner.dy);
        path.lineTo(corner.dx, corner.dy - cornerSize);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CornerIndicatorsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _HolographicTitle extends StatelessWidget {
  final String text;
  final Color accentColor;

  const _HolographicTitle({
    required this.text,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Glow effect
        Text(
          text,
          style: TextStyle(
            color: accentColor.withOpacity(0.3),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),

        // Main text
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: accentColor,
                blurRadius: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Color color;

  _HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HoverParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;
  final math.Random _random = math.Random(789);

  _HoverParticlesPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    const particleCount = 8;
    for (int i = 0; i < particleCount; i++) {
      final particleProgress = ((progress * 2) - (i / particleCount)).clamp(0.0, 1.0);
      if (particleProgress <= 0) continue;

      final x = size.width * _random.nextDouble();
      final y = size.height * (1.0 - particleProgress) * _random.nextDouble();
      final particleSize = (1.0 + _random.nextDouble()) * (1.0 - particleProgress);
      final opacity = (1.0 - particleProgress) * 0.6;

      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(_HoverParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
