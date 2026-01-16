import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../widgets/cyber_grid_background.dart';
import '../widgets/epic_neon_title.dart';
import '../widgets/tron_button.dart';
import '../widgets/tron_card.dart';
import '../widgets/universe_graph_widget.dart';
import '../../models/level_config.dart';
import '../../services/level_service.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen>
    with TickerProviderStateMixin {
  static const int _levelsPerWorld = 10;

  // State for selected world and level view
  int? _selectedWorldId;
  bool _showingLevels = false;

  static const List<WorldInfo> _worlds = [
    WorldInfo(
      id: 1,
      name: 'Neon Frontier',
      tagline: 'Reignite the grid and lock the first gates.',
      accent: NeonColors.cyan,
    ),
    WorldInfo(
      id: 2,
      name: 'Rift Wars',
      tagline: 'Shattered lanes and phantom storms rise.',
      accent: NeonColors.magenta,
    ),
    WorldInfo(
      id: 3,
      name: 'Signal Wastes',
      tagline: 'Dead zones flicker with rogue pulses.',
      accent: NeonColors.yellow,
    ),
    WorldInfo(
      id: 4,
      name: 'Ion Crown',
      tagline: 'Arc storms crown the upper lattice.',
      accent: NeonColors.green,
    ),
    WorldInfo(
      id: 5,
      name: 'Shard Vault',
      tagline: 'Ancient caches awaken with hostile code.',
      accent: NeonColors.red,
    ),
    WorldInfo(
      id: 6,
      name: 'Arc Fortress',
      tagline: 'Enemy sieges compress into tighter lanes.',
      accent: NeonColors.purple,
    ),
    WorldInfo(
      id: 7,
      name: 'Core Hunt',
      tagline: 'Every wave targets your core directly.',
      accent: NeonColors.orange,
    ),
    WorldInfo(
      id: 8,
      name: 'Omega Grid',
      tagline: 'Feedback loops overload the lattice.',
      accent: NeonColors.blue,
    ),
    WorldInfo(
      id: 9,
      name: 'Storm Tower',
      tagline: 'Lightning corridors fracture movement.',
      accent: NeonColors.cyan,
    ),
    WorldInfo(
      id: 10,
      name: 'Final Gate',
      tagline: 'The last lock holds the endless surge.',
      accent: NeonColors.white,
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }


  void _handleWorldSelected(int worldId) {
    setState(() {
      _selectedWorldId = worldId;
      _showingLevels = true;
    });
  }

  void _handleLevelSelected(int levelId) {
    // Check if level is unlocked
    if (!LevelService.instance.isLevelUnlocked(levelId)) {
      // Show locked message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Level $levelId is locked. Complete previous levels first.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: NeonColors.magenta,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Launch game
    Navigator.pushNamed(
      context,
      '/game',
      arguments: levelId,
    );
  }

  void _handleBackFromLevels() {
    setState(() {
      _showingLevels = false;
      _selectedWorldId = null;
    });
  }


  int _worldForLevel(int levelId) => ((levelId - 1) ~/ _levelsPerWorld) + 1;

  List<LevelConfig> _levelsForWorld(int worldId) {
    return LevelService.instance.levels
        .where((level) => _worldForLevel(level.id) == worldId)
        .toList(growable: false);
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CyberGridBackground(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _showingLevels && _selectedWorldId != null
                ? _buildLevelGrid()
                : _buildWorldSelection(),
          ),
        ),
      ),
    );
  }

  Widget _buildWorldSelection() {
    return Column(
      key: const ValueKey('world_selection'),
      children: [
        const SizedBox(height: 40),
        const EpicNeonTitle(
          text: 'UNIVERSE SELECTION',
          fontSize: 42,
          primaryColor: NeonColors.cyan,
          secondaryColor: NeonColors.magenta,
        ),
        const SizedBox(height: 8),
        Text(
          'Select sector to materialize transmission.',
          style: NeonTextStyles.body.copyWith(
            color: NeonColors.cyan.withOpacity(0.5),
            letterSpacing: 2,
          ),
        ),
        Expanded(
          child: UniverseGraphWidget(
            worlds: _worlds,
            onWorldSelected: _handleWorldSelected,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: TronButton(
            text: 'RETURN',
            width: 180,
            height: 44,
            onPressed: () => Navigator.pop(context),
            color: NeonColors.magenta,
            delay: const Duration(milliseconds: 300),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelGrid() {
    final world = _worlds.firstWhere((w) => w.id == _selectedWorldId);
    final levels = _levelsForWorld(_selectedWorldId!);

    return Column(
      key: const ValueKey('level_grid'),
      children: [
        const SizedBox(height: 40),
        EpicNeonTitle(
          text: world.name.toUpperCase(),
          fontSize: 36,
          primaryColor: world.accent,
          secondaryColor: NeonColors.white,
        ),
        const SizedBox(height: 8),
        Text(
          world.tagline,
          textAlign: TextAlign.center,
          style: NeonTextStyles.body.copyWith(
            color: world.accent.withOpacity(0.6),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsive: adjust columns based on screen width
              final screenWidth = constraints.maxWidth;
              int crossAxisCount;
              double cardSize;

              if (screenWidth > 1400) {
                crossAxisCount = 5;
                cardSize = 140;
              } else if (screenWidth > 1000) {
                crossAxisCount = 4;
                cardSize = 130;
              } else if (screenWidth > 700) {
                crossAxisCount = 3;
                cardSize = 120;
              } else {
                crossAxisCount = 2;
                cardSize = 110;
              }

              final horizontalPadding = screenWidth > 1000 ? 60.0 : 24.0;

              return GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: levels.length,
                itemBuilder: (context, index) {
                  return _TronLevelCard(
                    level: levels[index],
                    accentColor: world.accent,
                    delay: Duration(milliseconds: 80 + index * 40),
                    onTap: () => _handleLevelSelected(levels[index].id),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: TronButton(
            text: 'BACK',
            width: 180,
            height: 44,
            onPressed: _handleBackFromLevels,
            color: world.accent,
            delay: const Duration(milliseconds: 200),
          ),
        ),
      ],
    );
  }
}

class _TronLevelCard extends StatefulWidget {
  const _TronLevelCard({
    required this.level,
    required this.accentColor,
    required this.delay,
    required this.onTap,
  });

  final LevelConfig level;
  final Color accentColor;
  final Duration delay;
  final VoidCallback onTap;

  @override
  State<_TronLevelCard> createState() => _TronLevelCardState();
}

class _TronLevelCardState extends State<_TronLevelCard>
    with TickerProviderStateMixin {
  late AnimationController _materializeController;
  late AnimationController _pulseController;
  late AnimationController _hoverController;
  late Animation<double> _materializeAnimation;
  late Animation<double> _pulseAnimation;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _materializeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _materializeAnimation = CurvedAnimation(
      parent: _materializeController,
      curve: Curves.easeOutCubic,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
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

  @override
  Widget build(BuildContext context) {
    final isUnlocked = LevelService.instance.isLevelUnlocked(widget.level.id);
    final progress = LevelService.instance.getProgress(widget.level.id);
    final isCompleted = progress.completed;
    final stars = progress.stars;
    final effectiveColor = isUnlocked ? widget.accentColor : Colors.grey;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (isUnlocked) widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(
          animation: Listenable.merge([_materializeAnimation, _pulseAnimation]),
          builder: (context, child) {
            final progress = _materializeAnimation.value;
            final pulse = _pulseAnimation.value;
            final scale = _isPressed ? 0.95 : (_isHovered ? 1.05 : 1.0);

            return Transform.scale(
              scale: scale,
              child: CustomPaint(
                painter: _EpicLevelCardPainter(
                  progress: progress,
                  pulseValue: pulse,
                  primaryColor: effectiveColor,
                  isHovered: _isHovered && isUnlocked,
                  isCompleted: isCompleted,
                  isLocked: !isUnlocked,
                  levelNumber: widget.level.id,
                  stars: stars,
                ),
                child: const SizedBox.expand(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EpicLevelCardPainter extends CustomPainter {
  _EpicLevelCardPainter({
    required this.progress,
    required this.pulseValue,
    required this.primaryColor,
    required this.isHovered,
    required this.isCompleted,
    required this.isLocked,
    required this.levelNumber,
    required this.stars,
  });

  final double progress;
  final double pulseValue;
  final Color primaryColor;
  final bool isHovered;
  final bool isCompleted;
  final bool isLocked;
  final int levelNumber;
  final int stars;

  // Secondary color (orange for TRON effect)
  Color get secondaryColor => const Color(0xFFFF6600);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final cornerRadius = 6.0;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

    // TRON Materialization wireframe lines (draws first, fades out)
    _drawTronWireframe(canvas, size, center);

    // Background (fades in after wireframe starts)
    if (progress > 0.3) {
      _drawBackground(canvas, rrect);
    }

    // Hex grid overlay
    if (progress > 0.4 && !isLocked) {
      _drawHexGrid(canvas, size);
    }

    // Border with glow (appears after wireframe)
    if (progress > 0.5) {
      _drawBorder(canvas, rrect, size);
    }

    // Corner brackets
    if (progress > 0.6) {
      _drawCornerBrackets(canvas, size);
    }

    // Energy core (center circle)
    if (progress > 0.5) {
      _drawEnergyCore(canvas, center, size);
    }

    // Level number
    if (progress > 0.7) {
      _drawLevelNumber(canvas, center, size);
    }

    // Stars
    if (isCompleted && stars > 0 && progress > 0.8) {
      _drawStars(canvas, size);
    }

    // Lock overlay
    if (isLocked && progress > 0.6) {
      _drawLockOverlay(canvas, center, size);
    }

    // Completion badge
    if (isCompleted && progress > 0.8) {
      _drawCompletionBadge(canvas, size);
    }

    // Scan line effect when hovered
    if (isHovered && !isLocked) {
      _drawScanLine(canvas, size);
    }

    // Light particles during materialization
    _drawParticles(canvas, size, center);
  }

  void _drawTronWireframe(Canvas canvas, Size size, Offset center) {
    if (progress <= 0) return;

    // Wireframe lines fade out after construction
    final fadeOutStart = 0.6;
    final fadeOutEnd = 0.9;
    final wireframeFade = progress >= fadeOutEnd
        ? 0.0
        : progress <= fadeOutStart
            ? 1.0
            : 1.0 - ((progress - fadeOutStart) / (fadeOutEnd - fadeOutStart));

    if (wireframeFade <= 0) return;

    // Define wireframe lines from center to edges/corners
    final lines = <_WireframeLine>[
      // Horizontal lines
      _WireframeLine(center, Offset(0, center.dy), 0.0, 0.35),
      _WireframeLine(center, Offset(size.width, center.dy), 0.0, 0.35),
      // Vertical lines
      _WireframeLine(center, Offset(center.dx, 0), 0.05, 0.4),
      _WireframeLine(center, Offset(center.dx, size.height), 0.05, 0.4),
      // Diagonal lines to corners
      _WireframeLine(center, Offset.zero, 0.1, 0.5),
      _WireframeLine(center, Offset(size.width, 0), 0.1, 0.5),
      _WireframeLine(center, Offset(0, size.height), 0.1, 0.5),
      _WireframeLine(center, Offset(size.width, size.height), 0.1, 0.5),
    ];

    for (final line in lines) {
      if (progress >= line.startTime) {
        final lineProgress = progress >= line.endTime
            ? 1.0
            : ((progress - line.startTime) / (line.endTime - line.startTime)).clamp(0.0, 1.0);

        final currentEnd = Offset.lerp(line.start, line.end, lineProgress)!;

        // Glow effect
        final glowPaint = Paint()
          ..color = primaryColor.withOpacity(0.3 * wireframeFade)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawLine(line.start, currentEnd, glowPaint);

        // Main line
        final linePaint = Paint()
          ..color = primaryColor.withOpacity(0.7 * wireframeFade)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(line.start, currentEnd, linePaint);

        // Light trail at the construction point
        if (lineProgress > 0 && lineProgress < 1) {
          const trailLength = 0.12;
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
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          canvas.drawLine(trailStartPoint, currentEnd, trailPaint);

          // Bright point at the front
          final pointPaint = Paint()
            ..color = Colors.white
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
          canvas.drawCircle(currentEnd, 2.5, pointPaint);
        }
      }
    }
  }

  void _drawParticles(Canvas canvas, Size size, Offset center) {
    if (progress < 0.1 || progress > 0.7) return;

    final random = math.Random(42);
    final particleProgress = ((progress - 0.1) / 0.5).clamp(0.0, 1.0);

    for (int i = 0; i < 6; i++) {
      final spawnTime = random.nextDouble() * 0.4;
      if (particleProgress < spawnTime) continue;

      final age = particleProgress - spawnTime;
      if (age > 0.35) continue;

      final alpha = (1.0 - age / 0.35).clamp(0.0, 1.0);
      final angle = random.nextDouble() * math.pi * 2;
      final distance = random.nextDouble() * size.width * 0.35 * (1 + age);

      final pos = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      // Glow
      final glowPaint = Paint()
        ..color = secondaryColor.withOpacity(alpha * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(pos, 3, glowPaint);

      // Core
      final corePaint = Paint()
        ..color = Colors.white.withOpacity(alpha * 0.9);
      canvas.drawCircle(pos, 1.5, corePaint);
    }
  }

  void _drawBackground(Canvas canvas, RRect rrect) {
    final bgFade = ((progress - 0.3) / 0.3).clamp(0.0, 1.0);
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.85 * bgFade);
    canvas.drawRRect(rrect, bgPaint);

    // Inner glow
    if (!isLocked && progress > 0.5) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            primaryColor.withOpacity(0.12 * bgFade),
            Colors.transparent,
          ],
        ).createShader(rrect.outerRect);
      canvas.drawRRect(rrect, glowPaint);
    }
  }

  void _drawHexGrid(Canvas canvas, Size size) {
    final fadeIn = ((progress - 0.4) / 0.3).clamp(0.0, 1.0);
    final opacity = fadeIn * 0.08 * (isHovered ? 1.5 : 1.0);

    final paint = Paint()
      ..color = primaryColor.withOpacity(opacity)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final hexSize = 12.0;
    final rows = (size.height / (hexSize * 1.5)).ceil();
    final cols = (size.width / (hexSize * 1.732)).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final offsetX = col * hexSize * 1.732 + (row.isOdd ? hexSize * 0.866 : 0);
        final offsetY = row * hexSize * 1.5;

        if (offsetX < size.width && offsetY < size.height) {
          _drawHexagon(canvas, Offset(offsetX, offsetY), hexSize * 0.35, paint);
        }
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
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

  void _drawBorder(Canvas canvas, RRect rrect, Size size) {
    final borderFade = ((progress - 0.5) / 0.3).clamp(0.0, 1.0);
    final glowIntensity = isHovered ? 1.0 : (0.4 + pulseValue * 0.3);

    // Outer glow
    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(glowIntensity * 0.4 * borderFade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rrect, glowPaint);

    // Main border
    final borderPaint = Paint()
      ..color = primaryColor.withOpacity(borderFade * (isHovered ? 1.0 : 0.8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovered ? 2.0 : 1.5;
    canvas.drawRRect(rrect, borderPaint);
  }

  void _drawCornerBrackets(Canvas canvas, Size size) {
    final cornerFade = ((progress - 0.6) / 0.2).clamp(0.0, 1.0);
    final bracketSize = 10.0 * cornerFade;

    final paint = Paint()
      ..color = primaryColor.withOpacity(cornerFade * (isHovered ? 1.0 : 0.8))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(3, 3 + bracketSize), const Offset(3, 3), paint);
    canvas.drawLine(const Offset(3, 3), Offset(3 + bracketSize, 3), paint);

    // Top-right
    canvas.drawLine(
        Offset(size.width - 3, 3 + bracketSize), Offset(size.width - 3, 3), paint);
    canvas.drawLine(
        Offset(size.width - 3, 3), Offset(size.width - 3 - bracketSize, 3), paint);

    // Bottom-left
    canvas.drawLine(
        Offset(3, size.height - 3 - bracketSize), Offset(3, size.height - 3), paint);
    canvas.drawLine(
        Offset(3, size.height - 3), Offset(3 + bracketSize, size.height - 3), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - 3, size.height - 3 - bracketSize),
        Offset(size.width - 3, size.height - 3), paint);
    canvas.drawLine(Offset(size.width - 3, size.height - 3),
        Offset(size.width - 3 - bracketSize, size.height - 3), paint);

    // Corner dots when hovered
    if (isHovered && !isLocked) {
      final dotPaint = Paint()
        ..color = primaryColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(const Offset(3, 3), 2.5, dotPaint);
      canvas.drawCircle(Offset(size.width - 3, 3), 2.5, dotPaint);
      canvas.drawCircle(Offset(3, size.height - 3), 2.5, dotPaint);
      canvas.drawCircle(Offset(size.width - 3, size.height - 3), 2.5, dotPaint);
    }
  }

  void _drawEnergyCore(Canvas canvas, Offset center, Size size) {
    if (isLocked) return;

    final coreFade = ((progress - 0.5) / 0.3).clamp(0.0, 1.0);
    final coreRadius = size.width * 0.22;
    final pulseRadius = coreRadius * (1.0 + pulseValue * 0.08);

    // Outer ring glow
    final outerGlowPaint = Paint()
      ..color = primaryColor.withOpacity(0.2 * coreFade * pulseValue)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, pulseRadius * 1.4, outerGlowPaint);

    // Energy ring
    final ringPaint = Paint()
      ..color = primaryColor.withOpacity(0.5 * coreFade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, pulseRadius, ringPaint);

    // Inner glow
    final innerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.3 * coreFade),
          primaryColor.withOpacity(0.08 * coreFade),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: coreRadius));
    canvas.drawCircle(center, coreRadius, innerGlowPaint);

    // Rotating segments when hovered
    if (isHovered) {
      final segmentPaint = Paint()
        ..color = primaryColor.withOpacity(0.7 * coreFade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 4; i++) {
        final startAngle = (i * 90 + pulseValue * 360) * math.pi / 180;
        final sweepAngle = 40 * math.pi / 180;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: pulseRadius + 3),
          startAngle,
          sweepAngle,
          false,
          segmentPaint,
        );
      }
    }
  }

  void _drawLevelNumber(Canvas canvas, Offset center, Size size) {
    final textFade = ((progress - 0.7) / 0.2).clamp(0.0, 1.0);

    if (isLocked) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$levelNumber',
        style: TextStyle(
          fontSize: size.width * 0.28,
          fontWeight: FontWeight.bold,
          color: primaryColor.withOpacity(textFade),
          shadows: [
            Shadow(
              color: primaryColor.withOpacity(0.8 * textFade),
              blurRadius: 10,
            ),
            Shadow(
              color: Colors.white.withOpacity(0.25 * textFade),
              blurRadius: 3,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 - 3,
      ),
    );
  }

  void _drawStars(Canvas canvas, Size size) {
    final starFade = ((progress - 0.8) / 0.2).clamp(0.0, 1.0);
    final starSize = size.width * 0.1;
    final starY = size.height - starSize * 1.5;
    final startX = size.width / 2 - starSize * 1.3;

    for (int i = 0; i < 3; i++) {
      final x = startX + i * starSize * 1.1;
      final isFilled = i < stars;

      if (isFilled) {
        // Glow
        final glowPaint = Paint()
          ..color = NeonColors.yellow.withOpacity(0.6 * starFade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        _drawStarShape(canvas, Offset(x, starY), starSize * 0.5, glowPaint);

        // Star
        final starPaint = Paint()
          ..color = NeonColors.yellow.withOpacity(starFade);
        _drawStarShape(canvas, Offset(x, starY), starSize * 0.4, starPaint);
      } else {
        // Empty star outline
        final emptyPaint = Paint()
          ..color = Colors.grey.withOpacity(0.3 * starFade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        _drawStarShape(canvas, Offset(x, starY), starSize * 0.4, emptyPaint);
      }
    }
  }

  void _drawStarShape(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * math.pi / 180;
      final innerAngle = ((i * 72 + 36) - 90) * math.pi / 180;

      final outerX = center.dx + radius * math.cos(outerAngle);
      final outerY = center.dy + radius * math.sin(outerAngle);

      final innerX = center.dx + radius * 0.4 * math.cos(innerAngle);
      final innerY = center.dy + radius * 0.4 * math.sin(innerAngle);

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawLockOverlay(Canvas canvas, Offset center, Size size) {
    final lockFade = ((progress - 0.6) / 0.2).clamp(0.0, 1.0);

    // Darken overlay
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5 * lockFade);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // Lock icon
    final lockSize = size.width * 0.22;
    final lockCenter = Offset(center.dx, center.dy - 3);

    // Lock body
    final bodyPaint = Paint()
      ..color = Colors.grey.withOpacity(0.6 * lockFade)
      ..style = PaintingStyle.fill;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(lockCenter.dx, lockCenter.dy + lockSize * 0.15),
        width: lockSize * 0.7,
        height: lockSize * 0.6,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Lock shackle
    final shacklePaint = Paint()
      ..color = Colors.grey.withOpacity(0.6 * lockFade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lockSize * 0.12;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(lockCenter.dx, lockCenter.dy - lockSize * 0.1),
        width: lockSize * 0.4,
        height: lockSize * 0.4,
      ),
      math.pi,
      math.pi,
      false,
      shacklePaint,
    );

    // Keyhole
    final keyholePaint = Paint()
      ..color = Colors.black.withOpacity(0.8 * lockFade);
    canvas.drawCircle(
      Offset(lockCenter.dx, lockCenter.dy + lockSize * 0.1),
      lockSize * 0.08,
      keyholePaint,
    );
  }

  void _drawCompletionBadge(Canvas canvas, Size size) {
    final badgeFade = ((progress - 0.8) / 0.2).clamp(0.0, 1.0);
    final badgeSize = size.width * 0.1;
    final badgePos = Offset(size.width - badgeSize - 6, badgeSize + 6);

    // Glow
    final glowPaint = Paint()
      ..color = NeonColors.green.withOpacity(0.6 * badgeFade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(badgePos, badgeSize * 1.2, glowPaint);

    // Badge background
    final bgPaint = Paint()
      ..color = NeonColors.green.withOpacity(0.8 * badgeFade);
    canvas.drawCircle(badgePos, badgeSize * 0.8, bgPaint);

    // Checkmark
    final checkPaint = Paint()
      ..color = Colors.white.withOpacity(badgeFade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(badgePos.dx - badgeSize * 0.35, badgePos.dy)
      ..lineTo(badgePos.dx - badgeSize * 0.1, badgePos.dy + badgeSize * 0.25)
      ..lineTo(badgePos.dx + badgeSize * 0.35, badgePos.dy - badgeSize * 0.25);
    canvas.drawPath(path, checkPaint);
  }

  void _drawScanLine(Canvas canvas, Size size) {
    final scanY = (pulseValue * size.height * 1.5) - size.height * 0.25;

    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          primaryColor.withOpacity(0.25),
          primaryColor.withOpacity(0.4),
          primaryColor.withOpacity(0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 8, size.width, 16));

    canvas.drawRect(Rect.fromLTWH(0, scanY - 8, size.width, 16), scanPaint);
  }

  @override
  bool shouldRepaint(_EpicLevelCardPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        pulseValue != oldDelegate.pulseValue ||
        isHovered != oldDelegate.isHovered;
  }
}

/// Helper class for wireframe line animation
class _WireframeLine {
  final Offset start;
  final Offset end;
  final double startTime;
  final double endTime;

  _WireframeLine(this.start, this.end, this.startTime, this.endTime);
}

// Public classes that were previously private, so AnimatedTronGrid can use them.
class WorldInfo {
  const WorldInfo({
    required this.id,
    required this.name,
    required this.tagline,
    required this.accent,
  });

  final int id;
  final String name;
  final String tagline;
  final Color accent;
}

class WorldProgress {
  const WorldProgress({
    required this.total,
    required this.completed,
    required this.stars,
  });

  final int total;
  final int completed;
  final int stars;
}
