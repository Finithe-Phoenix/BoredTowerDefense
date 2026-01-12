import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = NeonColors.cyan,
    this.width = 250,
    this.height = 50,
    this.enabled = true,
  });

  final String text;
  final VoidCallback onPressed;
  final Color color;
  final double width;
  final double height;
  final bool enabled;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.enabled ? widget.color : Colors.grey;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (widget.enabled) widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            final glowIntensity = _isHovered ? 1.0 : _glowAnimation.value;
            final scale = _isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0);

            return Transform.scale(
              scale: scale,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: NeonColors.darkBg.withOpacity(0.8),
                  border: Border.all(
                    color: effectiveColor.withOpacity(glowIntensity),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveColor.withOpacity(glowIntensity * 0.5),
                      blurRadius: _isHovered ? 20 : 10,
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.text,
                    style: NeonTextStyles.button.copyWith(
                      color: effectiveColor,
                      shadows: [
                        Shadow(
                          color: effectiveColor.withOpacity(glowIntensity),
                          blurRadius: 10,
                        ),
                      ],
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
