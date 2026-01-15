import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../screens/level_select_screen.dart';
import '../theme/neon_theme.dart';
import '../../models/level_config.dart';
import '../../services/level_service.dart';

class AnimatedTronGrid extends StatefulWidget {
  const AnimatedTronGrid({
    super.key,
    required this.world,
    required this.levels,
    required this.levelService,
    required this.selectedLevelId,
    required this.onSelectLevel,
  });

  final WorldInfo world;
  final List<LevelConfig> levels;
  final LevelService levelService;
  final int? selectedLevelId;
  final ValueChanged<int> onSelectLevel;

  @override
  State<AnimatedTronGrid> createState() => _AnimatedTronGridState();
}

class _AnimatedTronGridState extends State<AnimatedTronGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(Offset tapPosition, List<Offset> nodePositions, double nodeRadius) {
    for (int i = 0; i < nodePositions.length; i++) {
      final nodePos = nodePositions[i];
      final distance = (tapPosition - nodePos).distance;
      if (distance <= nodeRadius) {
        widget.onSelectLevel(widget.levels[i].id);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final center = Offset(size.width / 2, size.height / 2);
            final orbitRadius = math.min(size.width, size.height) * 0.35;
            final nodeRadius = math.max(16.0, math.min(size.width, size.height) * 0.045);
            final count = math.max(1, widget.levels.length);
            final angleStep = (math.pi * 2) / count;
            final startAngle = -math.pi / 2;

            final nodePositions = <Offset>[];
            for (int i = 0; i < widget.levels.length; i++) {
              final angle = startAngle + angleStep * i;
              nodePositions.add(Offset(
                center.dx + orbitRadius * math.cos(angle),
                center.dy + orbitRadius * math.sin(angle),
              ));
            }

            return GestureDetector(
              onTapUp: (details) => _handleTap(details.localPosition, nodePositions, nodeRadius),
              child: CustomPaint(
                size: size,
                painter: _TronGridPainter(
                  animation: _animationController.value,
                  center: center,
                  orbitRadius: orbitRadius,
                  nodePositions: nodePositions,
                  nodeRadius: nodeRadius,
                  accent: widget.world.accent,
                  levels: widget.levels,
                  levelService: widget.levelService,
                  selectedLevelId: widget.selectedLevelId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TronGridPainter extends CustomPainter {
  _TronGridPainter({
    required this.animation,
    required this.center,
    required this.orbitRadius,
    required this.nodePositions,
    required this.nodeRadius,
    required this.accent,
    required this.levels,
    required this.levelService,
    required this.selectedLevelId,
  });

  final double animation;
  final Offset center;
  final double orbitRadius;
  final List<Offset> nodePositions;
  final double nodeRadius;
  final Color accent;
  final List<LevelConfig> levels;
  final LevelService levelService;
  final int? selectedLevelId;

  @override
  void paint(Canvas canvas, Size size) {
    // Phase 1: Core and orbit ring animation (0.0 to 0.4)
    final coreProgress = (animation / 0.4).clamp(0.0, 1.0);
    if (coreProgress > 0) {
      _drawCore(canvas, coreProgress);
      _drawOrbitRing(canvas, coreProgress);
    }

    // Phase 2: Connection lines animation (0.3 to 0.7)
    final linesProgress = ((animation - 0.3) / 0.4).clamp(0.0, 1.0);
    if (linesProgress > 0) {
      _drawConnectionLines(canvas, linesProgress);
    }

    // Phase 3: Nodes animation (0.6 to 1.0)
    final nodesProgress = ((animation - 0.6) / 0.4).clamp(0.0, 1.0);
    if (nodesProgress > 0) {
      _drawNodes(canvas, nodesProgress);
    }
  }

  void _drawCore(Canvas canvas, double progress) {
    final glowPaint = Paint()
      ..color = accent.withOpacity(0.3 * progress)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 * progress);
    final corePaint = Paint()
      ..color = accent.withOpacity(0.9 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(center, orbitRadius * 0.15, glowPaint);
    canvas.drawCircle(center, orbitRadius * 0.15, corePaint);
  }

  void _drawOrbitRing(Canvas canvas, double progress) {
    final paint = Paint()
      ..color = accent.withOpacity(0.4 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    for (int i = 0; i < 360; i++) {
      final angle = (i / 360) * math.pi * 2;
      final length = progress * (math.pi * 2);
      if (angle > length) continue;

      final point = Offset(
        center.dx + orbitRadius * math.cos(angle - math.pi / 2),
        center.dy + orbitRadius * math.sin(angle - math.pi / 2),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawConnectionLines(Canvas canvas, double progress) {
    final paint = Paint()
      ..color = accent.withOpacity(0.5 * progress)
      ..strokeWidth = 1.5;

    for (final nodePos in nodePositions) {
      final direction = nodePos - center;
      final endPoint = center + direction * progress;
      canvas.drawLine(center, endPoint, paint);
    }
  }

  void _drawNodes(Canvas canvas, double progress) {
    for (int i = 0; i < levels.length; i++) {
      final level = levels[i];
      final pos = nodePositions[i];
      final isUnlocked = levelService.isLevelUnlocked(level.id);
      final isSelected = selectedLevelId == level.id;
      final color = isUnlocked ? accent : Colors.grey[800]!;

      final scale = Curves.elasticOut.transform(progress);

      final glowPaint = Paint()
        ..color = color.withOpacity(0.4 * progress)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * scale);
      
      final bgPaint = Paint()
        ..color = Colors.black.withOpacity(0.8);
      
      final borderPaint = Paint()
        ..color = isSelected ? NeonColors.yellow : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 2.0;

      canvas.drawCircle(pos, nodeRadius * scale, glowPaint);
      canvas.drawCircle(pos, nodeRadius * scale, bgPaint);
      canvas.drawCircle(pos, nodeRadius * scale, borderPaint);

      final localIndex = ((level.id - 1) % 10) + 1;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$localIndex',
          style: NeonTextStyles.title.copyWith(
            fontSize: 16 * scale,
            color: isUnlocked ? (isSelected ? NeonColors.yellow : Colors.white) : Colors.grey,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(_TronGridPainter oldDelegate) {
    return oldDelegate.animation != animation ||
           oldDelegate.selectedLevelId != selectedLevelId;
  }
}
