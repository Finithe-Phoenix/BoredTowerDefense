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

  static final Paint _coreGlowPaint = Paint();
  static final Paint _corePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  static final Paint _orbitPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _linePaint = Paint()..strokeWidth = 1.5;
  static final Paint _nodeGlowPaint = Paint();
  static final Paint _nodeBgPaint = Paint()
    ..color = Colors.black.withOpacity(0.8);
  static final Paint _nodeBorderPaint = Paint()..style = PaintingStyle.stroke;
  static final Path _orbitPath = Path();
  static const int _labelCacheLimit = 24;
  static final Map<int, TextPainter> _labelPainterCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
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
    _coreGlowPaint
      ..color = accent.withOpacity(0.3 * progress)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 * progress);
    _corePaint.color = accent.withOpacity(0.9 * progress);
    
    canvas.drawCircle(center, orbitRadius * 0.15, _coreGlowPaint);
    canvas.drawCircle(center, orbitRadius * 0.15, _corePaint);
  }

  void _drawOrbitRing(Canvas canvas, double progress) {
    _orbitPaint.color = accent.withOpacity(0.4 * progress);
    final sweep = progress * math.pi * 2;
    if (sweep <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: orbitRadius);
    // Start at top (-pi/2) to match previous orientation.
    canvas.drawArc(rect, -math.pi / 2, sweep, false, _orbitPaint);
  }

  void _drawConnectionLines(Canvas canvas, double progress) {
    _linePaint.color = accent.withOpacity(0.5 * progress);

    for (final nodePos in nodePositions) {
      final direction = nodePos - center;
      final endPoint = center + direction * progress;
      canvas.drawLine(center, endPoint, _linePaint);
    }
  }

  void _drawNodes(Canvas canvas, double progress) {
    var cacheExceeded = false;
    for (int i = 0; i < levels.length; i++) {
      final level = levels[i];
      final pos = nodePositions[i];
      final isUnlocked = levelService.isLevelUnlocked(level.id);
      final isSelected = selectedLevelId == level.id;
      final color = isUnlocked ? accent : Colors.grey[800]!;

      final scale = Curves.elasticOut.transform(progress);

      _nodeGlowPaint.color = color.withOpacity(0.4 * progress);
      if (scale > 0.01) {
        _nodeGlowPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * scale);
      } else {
        _nodeGlowPaint.maskFilter = null;
      }
      _nodeBorderPaint
        ..color = isSelected ? NeonColors.yellow : color
        ..strokeWidth = isSelected ? 3.0 : 2.0;

      canvas.drawCircle(pos, nodeRadius * scale, _nodeGlowPaint);
      canvas.drawCircle(pos, nodeRadius * scale, _nodeBgPaint);
      canvas.drawCircle(pos, nodeRadius * scale, _nodeBorderPaint);

      final localIndex = ((level.id - 1) % 10) + 1;
      final fontSize = (16 * scale).round();
      final labelColor = isUnlocked ? (isSelected ? NeonColors.yellow : Colors.white) : Colors.grey;
      final cacheKey = (fontSize << 24) ^ (labelColor.value & 0x00FFFFFF) ^ localIndex;
      final painter = _labelPainterCache.putIfAbsent(cacheKey, () {
        final tp = TextPainter(textDirection: TextDirection.ltr);
        tp.text = TextSpan(
          text: '$localIndex',
          style: NeonTextStyles.title.copyWith(
            fontSize: fontSize.toDouble(),
            color: labelColor,
          ),
        );
        tp.layout();
        return tp;
      });
      painter.paint(
        canvas,
        pos - Offset(painter.width / 2, painter.height / 2),
      );
      if (_labelPainterCache.length > _labelCacheLimit) {
        cacheExceeded = true;
      }
    }
    if (cacheExceeded) {
      for (final tp in _labelPainterCache.values) {
        tp.dispose();
      }
      _labelPainterCache.clear();
    }
  }

  @override
  bool shouldRepaint(_TronGridPainter oldDelegate) {
    return oldDelegate.animation != animation ||
           oldDelegate.selectedLevelId != selectedLevelId;
  }
}
