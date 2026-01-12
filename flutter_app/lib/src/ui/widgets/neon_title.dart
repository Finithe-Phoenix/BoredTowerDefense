import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

class NeonTitle extends StatefulWidget {
  const NeonTitle({
    super.key,
    required this.text,
    this.fontSize = 48,
    this.color = NeonColors.cyan,
  });

  final String text;
  final double fontSize;
  final Color color;

  @override
  State<NeonTitle> createState() => _NeonTitleState();
}

class _NeonTitleState extends State<NeonTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
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
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Text(
          widget.text,
          style: TextStyle(
            fontFamily: NeonTextStyles.fontFamily,
            fontSize: widget.fontSize,
            fontWeight: FontWeight.bold,
            color: widget.color,
            shadows: [
              Shadow(
                color: widget.color.withOpacity(_pulseAnimation.value),
                blurRadius: 20 * _pulseAnimation.value,
              ),
              Shadow(
                color: widget.color.withOpacity(_pulseAnimation.value * 0.5),
                blurRadius: 40 * _pulseAnimation.value,
              ),
              Shadow(
                color: widget.color.withOpacity(_pulseAnimation.value * 0.3),
                blurRadius: 60 * _pulseAnimation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
