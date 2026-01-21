import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// Epic neon button with scanning effect, hover glow, and pulse animations
class EpicNeonButton extends StatefulWidget {
  const EpicNeonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = NeonColors.cyan,
    this.width = 280,
    this.height = 56,
    this.enabled = true,
    this.icon,
  });

  final String text;
  final VoidCallback onPressed;
  final Color color;
  final double width;
  final double height;
  final bool enabled;
  final IconData? icon;

  @override
  State<EpicNeonButton> createState() => _EpicNeonButtonState();
}

class _EpicNeonButtonState extends State<EpicNeonButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late AnimationController _hoverController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;
  late Animation<double> _hoverAnimation;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
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

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (widget.enabled) widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _pulseAnimation,
            _scanAnimation,
            _hoverAnimation,
          ]),
          builder: (context, child) {
            final glowIntensity = _isHovered
                ? 1.0
                : 0.3 + _pulseAnimation.value * 0.4;
            final scale = _isPressed ? 0.96 : (_isHovered ? 1.03 : 1.0);

            return Transform.scale(
              scale: scale,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      NeonColors.darkBg.withOpacity(0.9),
                      NeonColors.darkBg.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: effectiveColor.withOpacity(glowIntensity),
                    width: 2,
                  ),
                  boxShadow: [
                    // Outer glow
                    BoxShadow(
                      color: effectiveColor.withOpacity(glowIntensity * 0.4),
                      blurRadius: 15 + _hoverAnimation.value * 15,
                      spreadRadius: _hoverAnimation.value * 3,
                    ),
                    // Inner glow
                    BoxShadow(
                      color: effectiveColor.withOpacity(glowIntensity * 0.2),
                      blurRadius: 30,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Stack(
                    children: [
                      // Scanning line effect
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ScanEffectPainter(
                            progress: _scanAnimation.value,
                            color: effectiveColor,
                            intensity: _hoverAnimation.value,
                          ),
                        ),
                      ),

                      // Corner decorations
                      _buildCornerDecoration(
                          Alignment.topLeft, effectiveColor, glowIntensity),
                      _buildCornerDecoration(
                          Alignment.topRight, effectiveColor, glowIntensity),
                      _buildCornerDecoration(
                          Alignment.bottomLeft, effectiveColor, glowIntensity),
                      _buildCornerDecoration(
                          Alignment.bottomRight, effectiveColor, glowIntensity),

                      // Button content
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
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
                            Flexible(
                              child: Text(
                                widget.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCornerDecoration(
      Alignment alignment, Color color, double intensity) {
    const size = 12.0;
    return Positioned(
      left: alignment.x < 0 ? 4 : null,
      right: alignment.x > 0 ? 4 : null,
      top: alignment.y < 0 ? 4 : null,
      bottom: alignment.y > 0 ? 4 : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border(
            left: alignment.x < 0
                ? BorderSide(color: color.withOpacity(intensity), width: 2)
                : BorderSide.none,
            right: alignment.x > 0
                ? BorderSide(color: color.withOpacity(intensity), width: 2)
                : BorderSide.none,
            top: alignment.y < 0
                ? BorderSide(color: color.withOpacity(intensity), width: 2)
                : BorderSide.none,
            bottom: alignment.y > 0
                ? BorderSide(color: color.withOpacity(intensity), width: 2)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ScanEffectPainter extends CustomPainter {
  _ScanEffectPainter({
    required this.progress,
    required this.color,
    required this.intensity,
  });

  final double progress;
  final Color color;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity < 0.1) return;

    final x = size.width * progress;
    final gradient = LinearGradient(
      colors: [
        Colors.transparent,
        color.withOpacity(0.1 * intensity),
        color.withOpacity(0.3 * intensity),
        color.withOpacity(0.1 * intensity),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(x - 60, 0, 120, size.height));

    final paint = Paint()..shader = gradient;
    canvas.drawRect(Rect.fromLTWH(x - 60, 0, 120, size.height), paint);

    // Scan line
    final linePaint = Paint()
      ..color = color.withOpacity(0.6 * intensity)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
  }

  @override
  bool shouldRepaint(_ScanEffectPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.intensity != intensity;
}
