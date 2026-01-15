import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../screens/level_select_screen.dart';

class UniverseGraphWidget extends StatefulWidget {
  final List<WorldInfo> worlds;
  final Function(int worldId) onWorldSelected;

  const UniverseGraphWidget({
    super.key,
    required this.worlds,
    required this.onWorldSelected,
  });

  @override
  State<UniverseGraphWidget> createState() => _UniverseGraphWidgetState();
}

class _UniverseGraphWidgetState extends State<UniverseGraphWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final center = Offset(size.width / 2, size.height / 2);
        final radius = math.min(size.width, size.height) * 0.35;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return GestureDetector(
              onTapUp: (details) => _handleTap(details.localPosition, center, radius),
              child: CustomPaint(
                size: size,
                painter: _UniversePainter(
                  worlds: widget.worlds,
                  animationValue: _controller.value,
                  center: center,
                  radius: radius,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleTap(Offset tapPos, Offset center, double radius) {
    for (int i = 0; i < widget.worlds.length; i++) {
      final angle = (i / widget.worlds.length) * math.pi * 2;
      final nodePos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if ((tapPos - nodePos).distance < 40) {
        widget.onWorldSelected(widget.worlds[i].id);
        break;
      }
    }
  }
}

class _UniversePainter extends CustomPainter {
  final List<WorldInfo> worlds;
  final double animationValue;
  final Offset center;
  final double radius;

  _UniversePainter({
    required this.worlds,
    required this.animationValue,
    required this.center,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NeonColors.cyan.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw background lattice
    _drawLattice(canvas, size);

    // Draw Connections
    final connectionPaint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < worlds.length; i++) {
      final angle = (i / worlds.length) * math.pi * 2;
      final nextAngle = ((i + 1) / worlds.length) * math.pi * 2;

      final start = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(nextAngle),
        center.dy + radius * math.sin(nextAngle),
      );

      // Outer ring connection
      connectionPaint.color = worlds[i].accent.withOpacity(0.3);
      canvas.drawLine(start, end, connectionPaint);

      // Connection to center
      connectionPaint.color = worlds[i].accent.withOpacity(0.15);
      canvas.drawLine(center, start, connectionPaint);
    }

    // Draw Nodes
    for (int i = 0; i < worlds.length; i++) {
      final angle = (i / worlds.length) * math.pi * 2;
      final pos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      _drawWorldNode(canvas, pos, worlds[i]);
    }

    // Central Core Pulse
    _drawCenterCore(canvas);
  }

  void _drawLattice(Canvas canvas, Size size) {
    final latticePaint = Paint()
      ..color = NeonColors.cyan.withOpacity(0.05)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), latticePaint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), latticePaint);
    }
  }

  void _drawWorldNode(Canvas canvas, Offset pos, WorldInfo world) {
    final pulse = 0.5 + 0.5 * math.sin(animationValue * math.pi * 2 + world.id);
    
    // Outer Glow
    final glowPaint = Paint()
      ..color = world.accent.withOpacity(0.3 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(pos, 25, glowPaint);

    // Node Border
    final borderPaint = Paint()
      ..color = world.accent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(pos, 20, borderPaint);

    // Inner Core
    final corePaint = Paint()
      ..color = Colors.black.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 18, corePaint);

    // World ID Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'W${world.id}',
        style: NeonTextStyles.title.copyWith(
          fontSize: 12,
          color: world.accent,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));

    // Orbital Bits
    for (int i = 0; i < 3; i++) {
      final bitAngle = animationValue * math.pi * 4 + (i * math.pi * 2 / 3);
      final bitPos = Offset(
        pos.dx + 28 * math.cos(bitAngle),
        pos.dy + 28 * math.sin(bitAngle),
      );
      canvas.drawRect(
        Rect.fromCenter(center: bitPos, width: 3, height: 3),
        Paint()..color = world.accent.withOpacity(0.6),
      );
    }
  }

  void _drawCenterCore(Canvas canvas) {
    final pulse = 0.5 + 0.5 * math.sin(animationValue * math.pi * 4);
    
    final corePaint = Paint()
      ..color = NeonColors.cyan.withOpacity(0.2 + 0.3 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, 30 + 10 * pulse, corePaint);
    
    final innerPaint = Paint()
      ..color = NeonColors.cyan.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, 40, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
