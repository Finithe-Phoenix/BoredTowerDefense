import 'dart:async';
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
            duration: const Duration(milliseconds: 700),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              // Enhanced transition with scale, rotation, and slide
              final scaleAnimation = Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ));

              final slideAnimation = Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ));

              final rotationAnimation = Tween<double>(
                begin: 0.02,
                end: 0.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ));

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: Transform.rotate(
                      angle: rotationAnimation.value,
                      child: child,
                    ),
                  ),
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
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 20),
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
  late AnimationController _clickController;
  late Animation<double> _materializeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _hoverAnimation;
  late Animation<double> _clickAnimation;

  Timer? _materializeTimer;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _materializeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _materializeAnimation = CurvedAnimation(
      parent: _materializeController,
      curve: Curves.elasticOut,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _hoverAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    );

    _clickController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _clickAnimation = CurvedAnimation(
      parent: _clickController,
      curve: Curves.easeOutBack,
    );

    _materializeTimer = Timer(widget.delay, () {
      if (mounted) {
        _materializeController.forward();
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _materializeTimer?.cancel();
    _materializeController.dispose();
    _pulseController.dispose();
    _hoverController.dispose();
    _clickController.dispose();
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
      onEnter: (_) {
        setState(() => _isHovered = true);
        if (isUnlocked) _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          if (isUnlocked) _clickController.forward(from: 0);
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _materializeAnimation,
            _pulseAnimation,
            _hoverAnimation,
            _clickAnimation,
          ]),
          builder: (context, child) {
            final progress = _materializeAnimation.value.clamp(0.0, 1.0);
            final pulse = _pulseAnimation.value;
            final hover = _hoverAnimation.value;
            final click = _clickAnimation.value.clamp(0.0, 1.0);

            // Enhanced scale with bounce on click
            final baseScale = _isPressed ? 0.95 : 1.0;
            final hoverScale = 1.0 + (hover * 0.08);
            final clickBounce =
                1.0 + (click * 0.15 * math.sin(click * math.pi));
            final totalScale = baseScale * hoverScale * clickBounce;

            // Rotation on hover
            final rotation = hover * 0.01 * math.sin(pulse * math.pi * 2);

            return Transform.scale(
              scale: totalScale,
              child: Transform.rotate(
                angle: rotation,
                child: CustomPaint(
                  painter: EpicLevelCardPainter(
                    progress: progress,
                    pulseValue: pulse,
                    primaryColor: effectiveColor,
                    isHovered: _isHovered && isUnlocked,
                    isCompleted: isCompleted,
                    isLocked: !isUnlocked,
                    levelNumber: widget.level.id,
                    stars: stars,
                    hoverProgress: hover,
                    clickProgress: click,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class EpicLevelCardPainter extends CustomPainter {
  EpicLevelCardPainter({
    required this.progress,
    required this.pulseValue,
    required this.primaryColor,
    required this.isHovered,
    required this.isCompleted,
    required this.isLocked,
    required this.levelNumber,
    required this.stars,
    this.hoverProgress = 0.0,
    this.clickProgress = 0.0,
  });

  final double progress;
  final double pulseValue;
  final Color primaryColor;
  final bool isHovered;
  final bool isCompleted;
  final bool isLocked;
  final int levelNumber;
  final int stars;
  final double hoverProgress;
  final double clickProgress;

  // Secondary color (orange for TRON effect)
  Color get secondaryColor => const Color(0xFFFF6600);

  static final Paint _outerGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _innerGlowPaint = Paint();
  static final Paint _segmentPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _starGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _starPaint = Paint();
  static final Paint _starOutlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Path _starPath = Path();
  final Path _hexPath = Path();

  static final Paint _wireGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  static final Paint _wireLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  static final Paint _wireTrailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _wirePointPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _particleGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _particleCorePaint = Paint();
  static final Paint _bgPaint = Paint();
  static final Paint _bgGlowPaint = Paint();
  static final Paint _hexGridPaint = Paint()
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;
  static final Paint _borderGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _borderPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _bracketPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2;
  static final Paint _bracketDotPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _lockOverlayPaint = Paint();
  static final Paint _lockBodyPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _lockShacklePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _lockKeyholePaint = Paint();
  static final Paint _badgeGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  static final Paint _badgeBgPaint = Paint();
  static final Paint _badgeCheckPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _scanPaint = Paint();
  static final Map<int, Shader> _wireTrailShaders = {};
  static final Map<int, Shader> _bgGlowShaders = {};
  static final Map<int, Shader> _coreGlowShaders = {};
  static final Map<int, Shader> _scanlineShaders = {};

  static int _lcgNext(int state) => (state * 1664525 + 1013904223) & 0x7fffffff;
  static double _lcgUnit(int state) => state / 0x7fffffff;
  TextPainter? _levelNumberPainter;
  String _levelNumberText = '';
  int _levelNumberColorValue = 0;
  double _levelNumberFontSize = 0;
  final Path _badgeCheckPath = Path();

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
            : ((progress - line.startTime) / (line.endTime - line.startTime))
                .clamp(0.0, 1.0);

        final currentEnd = Offset.lerp(line.start, line.end, lineProgress)!;

        // Glow effect
        _wireGlowPaint
          ..color = primaryColor.withOpacity(0.3 * wireframeFade)
          ..strokeWidth = 3;
        canvas.drawLine(line.start, currentEnd, _wireGlowPaint);

        // Main line
        _wireLinePaint
          ..color = primaryColor.withOpacity(0.7 * wireframeFade)
          ..strokeWidth = 1.2;
        canvas.drawLine(line.start, currentEnd, _wireLinePaint);

        // Light trail at the construction point
        if (lineProgress > 0 && lineProgress < 1) {
          const trailLength = 0.12;
          final trailStart = math.max(0.0, lineProgress - trailLength);
          final trailStartPoint =
              Offset.lerp(line.start, line.end, trailStart)!;

          final dx = currentEnd.dx - trailStartPoint.dx;
          final dy = currentEnd.dy - trailStartPoint.dy;
          final length = math.sqrt(dx * dx + dy * dy);
          if (length > 0.01) {
            final lenKey = length.round();
            final shaderKey = (lenKey << 16) ^ secondaryColor.value;
            final shader = _wireTrailShaders.putIfAbsent(shaderKey, () {
              final w = lenKey.toDouble();
              return LinearGradient(
                colors: [
                  secondaryColor.withOpacity(0),
                  secondaryColor.withOpacity(0.8),
                  Colors.white,
                ],
                stops: const [0.0, 0.6, 1.0],
              ).createShader(Rect.fromLTWH(0, 0, w, 1));
            });
            _wireTrailPaint
              ..shader = shader
              ..strokeWidth = 2.5;
            canvas.save();
            canvas.translate(trailStartPoint.dx, trailStartPoint.dy);
            canvas.rotate(math.atan2(dy, dx));
            canvas.drawLine(Offset.zero, Offset(length, 0), _wireTrailPaint);
            canvas.restore();
          }

          // Bright point at the front
          _wirePointPaint.color = Colors.white;
          canvas.drawCircle(currentEnd, 2.5, _wirePointPaint);
        }
      }
    }
  }

  void _drawParticles(Canvas canvas, Size size, Offset center) {
    if (progress < 0.1 || progress > 0.7) return;

    var state = 42;
    final particleProgress = ((progress - 0.1) / 0.5).clamp(0.0, 1.0);

    for (int i = 0; i < 6; i++) {
      state = _lcgNext(state);
      final spawnTime = _lcgUnit(state) * 0.4;
      if (particleProgress < spawnTime) continue;

      final age = particleProgress - spawnTime;
      if (age > 0.35) continue;

      final alpha = (1.0 - age / 0.35).clamp(0.0, 1.0);
      state = _lcgNext(state);
      final angle = _lcgUnit(state) * math.pi * 2;
      state = _lcgNext(state);
      final distance = _lcgUnit(state) * size.width * 0.35 * (1 + age);

      final pos = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      // Glow
      _particleGlowPaint.color = secondaryColor.withOpacity(alpha * 0.5);
      canvas.drawCircle(pos, 3, _particleGlowPaint);

      // Core
      _particleCorePaint.color = Colors.white.withOpacity(alpha * 0.9);
      canvas.drawCircle(pos, 1.5, _particleCorePaint);
    }
  }

  void _drawBackground(Canvas canvas, RRect rrect) {
    final bgFade = ((progress - 0.3) / 0.3).clamp(0.0, 1.0);
    _bgPaint.color = Colors.black.withOpacity(0.85 * bgFade);
    canvas.drawRRect(rrect, _bgPaint);

    // Inner glow
    if (!isLocked && progress > 0.5) {
      final opacityStep = (bgFade * 60).round();
      final key = (rrect.outerRect.width.round() << 32) ^
          (rrect.outerRect.height.round() << 16) ^
          (opacityStep << 8) ^
          primaryColor.value;
      final shader = _bgGlowShaders.putIfAbsent(key, () {
        final scalar = opacityStep / 60.0;
        return RadialGradient(
          colors: [
            primaryColor.withOpacity(0.12 * scalar),
            Colors.transparent,
          ],
        ).createShader(rrect.outerRect);
      });
      _bgGlowPaint.shader = shader;
      canvas.drawRRect(rrect, _bgGlowPaint);
    }
  }

  void _drawHexGrid(Canvas canvas, Size size) {
    final fadeIn = ((progress - 0.4) / 0.3).clamp(0.0, 1.0);
    final opacity = fadeIn * 0.08 * (isHovered ? 1.5 : 1.0);

    _hexGridPaint
      ..color = primaryColor.withOpacity(opacity)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final hexSize = 12.0;
    final rows = (size.height / (hexSize * 1.5)).ceil();
    final cols = (size.width / (hexSize * 1.732)).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final offsetX =
            col * hexSize * 1.732 + (row.isOdd ? hexSize * 0.866 : 0);
        final offsetY = row * hexSize * 1.5;

        if (offsetX < size.width && offsetY < size.height) {
          _drawHexagon(
              canvas, Offset(offsetX, offsetY), hexSize * 0.35, _hexGridPaint);
        }
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    _hexPath.reset();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        _hexPath.moveTo(x, y);
      } else {
        _hexPath.lineTo(x, y);
      }
    }
    _hexPath.close();
    canvas.drawPath(_hexPath, paint);
  }

  void _drawBorder(Canvas canvas, RRect rrect, Size size) {
    final borderFade = ((progress - 0.5) / 0.3).clamp(0.0, 1.0);
    final baseGlow = 0.4 + pulseValue * 0.3;
    final hoverGlow = 1.0 + hoverProgress * 0.5;
    final clickGlow = 1.0 + clickProgress * 2.0;
    final glowIntensity = baseGlow * hoverGlow * clickGlow;
    final borderGlowOpacity =
        (glowIntensity * 0.4 * borderFade).clamp(0.0, 1.0).toDouble();
    final borderOpacity =
        (borderFade * (0.8 + hoverProgress * 0.2)).clamp(0.0, 1.0).toDouble();

    // Click ripple effect
    if (clickProgress > 0) {
      final rippleRadius = clickProgress * size.width * 1.2;
      final rippleOpacity = (1.0 - clickProgress) * 0.5;
      final ripplePaint = Paint()
        ..color = primaryColor.withOpacity(rippleOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        rippleRadius,
        ripplePaint,
      );
    }

    // Outer glow
    _borderGlowPaint
      ..color = primaryColor.withOpacity(borderGlowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 + hoverProgress * 3;
    canvas.drawRRect(rrect, _borderGlowPaint);

    // Main border
    _borderPaint
      ..color = primaryColor.withOpacity(borderOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 + hoverProgress * 0.5;
    canvas.drawRRect(rrect, _borderPaint);
  }

  void _drawCornerBrackets(Canvas canvas, Size size) {
    final cornerFade = ((progress - 0.6) / 0.2).clamp(0.0, 1.0);
    final bracketSize = 10.0 * cornerFade;

    _bracketPaint.color =
        primaryColor.withOpacity(cornerFade * (isHovered ? 1.0 : 0.8));

    // Top-left
    canvas.drawLine(
        Offset(3, 3 + bracketSize), const Offset(3, 3), _bracketPaint);
    canvas.drawLine(
        const Offset(3, 3), Offset(3 + bracketSize, 3), _bracketPaint);

    // Top-right
    canvas.drawLine(Offset(size.width - 3, 3 + bracketSize),
        Offset(size.width - 3, 3), _bracketPaint);
    canvas.drawLine(Offset(size.width - 3, 3),
        Offset(size.width - 3 - bracketSize, 3), _bracketPaint);

    // Bottom-left
    canvas.drawLine(Offset(3, size.height - 3 - bracketSize),
        Offset(3, size.height - 3), _bracketPaint);
    canvas.drawLine(Offset(3, size.height - 3),
        Offset(3 + bracketSize, size.height - 3), _bracketPaint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - 3, size.height - 3 - bracketSize),
        Offset(size.width - 3, size.height - 3), _bracketPaint);
    canvas.drawLine(Offset(size.width - 3, size.height - 3),
        Offset(size.width - 3 - bracketSize, size.height - 3), _bracketPaint);

    // Corner dots when hovered
    if (isHovered && !isLocked) {
      _bracketDotPaint.color = primaryColor;

      canvas.drawCircle(const Offset(3, 3), 2.5, _bracketDotPaint);
      canvas.drawCircle(Offset(size.width - 3, 3), 2.5, _bracketDotPaint);
      canvas.drawCircle(Offset(3, size.height - 3), 2.5, _bracketDotPaint);
      canvas.drawCircle(
          Offset(size.width - 3, size.height - 3), 2.5, _bracketDotPaint);
    }
  }

  void _drawEnergyCore(Canvas canvas, Offset center, Size size) {
    if (isLocked) return;

    final coreFade = ((progress - 0.5) / 0.3).clamp(0.0, 1.0);
    final coreRadius = size.width * 0.22;
    final hoverBoost = 1.0 + hoverProgress * 0.15;
    final pulseRadius = coreRadius * (1.0 + pulseValue * 0.08) * hoverBoost;

    // Click burst effect
    if (clickProgress > 0) {
      for (int i = 0; i < 8; i++) {
        final angle = (i / 8) * math.pi * 2;
        final burstLength = clickProgress * coreRadius * 1.5;
        final burstEnd = Offset(
          center.dx + math.cos(angle) * burstLength,
          center.dy + math.sin(angle) * burstLength,
        );

        final burstPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              primaryColor.withOpacity((1.0 - clickProgress) * 0.8),
              primaryColor.withOpacity(0),
            ],
          ).createShader(Rect.fromPoints(center, burstEnd))
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

        canvas.drawLine(center, burstEnd, burstPaint);
      }
    }

    // Outer ring glow
    final glowIntensity = (0.2 + hoverProgress * 0.3) * coreFade * pulseValue;
    _outerGlowPaint.color = primaryColor.withOpacity(glowIntensity);
    canvas.drawCircle(center, pulseRadius * 1.4, _outerGlowPaint);

    // Energy ring
    _ringPaint
      ..color = primaryColor.withOpacity((0.5 + hoverProgress * 0.3) * coreFade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 + hoverProgress;
    canvas.drawCircle(center, pulseRadius, _ringPaint);

    // Inner glow
    final coreRadiusKey = coreRadius.round();
    final opacityStep = (coreFade * 60).round();
    final shaderKey =
        (coreRadiusKey << 16) ^ (opacityStep << 8) ^ primaryColor.value;
    final shader = _coreGlowShaders.putIfAbsent(shaderKey, () {
      final scalar = opacityStep / 60.0;
      return RadialGradient(
        colors: [
          primaryColor.withOpacity(0.3 * scalar),
          primaryColor.withOpacity(0.08 * scalar),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
          center: Offset.zero, radius: coreRadiusKey.toDouble()));
    });
    _innerGlowPaint.shader = shader;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawCircle(Offset.zero, coreRadiusKey.toDouble(), _innerGlowPaint);
    canvas.restore();

    // Rotating segments when hovered
    if (hoverProgress > 0) {
      _segmentPaint
        ..color =
            primaryColor.withOpacity((0.5 + hoverProgress * 0.3) * coreFade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      final segmentCount = 4 + (hoverProgress * 4).round();
      for (int i = 0; i < segmentCount; i++) {
        final startAngle =
            (i * (360 / segmentCount) + pulseValue * 360) * math.pi / 180;
        final sweepAngle = (30 + hoverProgress * 10) * math.pi / 180;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: pulseRadius + 3),
          startAngle,
          sweepAngle,
          false,
          _segmentPaint,
        );
      }
    }
  }

  void _drawLevelNumber(Canvas canvas, Offset center, Size size) {
    final textFade = ((progress - 0.7) / 0.2).clamp(0.0, 1.0);
    if (textFade <= 0.01) return;

    if (isLocked) return;

    final text = '$levelNumber';
    final fontSize = size.width * 0.28;
    final textColor = primaryColor.withOpacity(textFade);
    _levelNumberPainter ??= TextPainter(textDirection: TextDirection.ltr);
    if (_levelNumberText != text ||
        _levelNumberColorValue != textColor.value ||
        _levelNumberFontSize != fontSize) {
      _levelNumberText = text;
      _levelNumberColorValue = textColor.value;
      _levelNumberFontSize = fontSize;
      _levelNumberPainter!.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
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
      );
      _levelNumberPainter!.layout();
    }

    _levelNumberPainter!.paint(
      canvas,
      Offset(
        center.dx - _levelNumberPainter!.width / 2,
        center.dy - _levelNumberPainter!.height / 2 - 3,
      ),
    );
  }

  void _drawStars(Canvas canvas, Size size) {
    final starFade = ((progress - 0.8) / 0.2).clamp(0.0, 1.0);
    if (starFade <= 0.01) return;
    final starSize = size.width * 0.1;
    final starY = size.height - starSize * 1.5;
    final startX = size.width / 2 - starSize * 1.3;

    for (int i = 0; i < 3; i++) {
      final x = startX + i * starSize * 1.1;
      final isFilled = i < stars;

      if (isFilled) {
        // Glow
        _starGlowPaint.color = NeonColors.yellow.withOpacity(0.6 * starFade);
        _drawStarShape(
            canvas, Offset(x, starY), starSize * 0.5, _starGlowPaint);

        // Star
        _starPaint.color = NeonColors.yellow.withOpacity(starFade);
        _drawStarShape(canvas, Offset(x, starY), starSize * 0.4, _starPaint);
      } else {
        // Empty star outline
        _starOutlinePaint
          ..color = Colors.grey.withOpacity(0.3 * starFade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        _drawStarShape(
            canvas, Offset(x, starY), starSize * 0.4, _starOutlinePaint);
      }
    }
  }

  void _drawStarShape(
      Canvas canvas, Offset center, double radius, Paint paint) {
    _starPath.reset();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * math.pi / 180;
      final innerAngle = ((i * 72 + 36) - 90) * math.pi / 180;

      final outerX = center.dx + radius * math.cos(outerAngle);
      final outerY = center.dy + radius * math.sin(outerAngle);

      final innerX = center.dx + radius * 0.4 * math.cos(innerAngle);
      final innerY = center.dy + radius * 0.4 * math.sin(innerAngle);

      if (i == 0) {
        _starPath.moveTo(outerX, outerY);
      } else {
        _starPath.lineTo(outerX, outerY);
      }
      _starPath.lineTo(innerX, innerY);
    }
    _starPath.close();
    canvas.drawPath(_starPath, paint);
  }

  void _drawLockOverlay(Canvas canvas, Offset center, Size size) {
    final lockFade = ((progress - 0.6) / 0.2).clamp(0.0, 1.0);
    if (lockFade <= 0.01) return;

    // Darken overlay
    _lockOverlayPaint.color = Colors.black.withOpacity(0.5 * lockFade);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), _lockOverlayPaint);

    // Lock icon
    final lockSize = size.width * 0.22;
    final lockCenter = Offset(center.dx, center.dy - 3);

    // Lock body
    _lockBodyPaint.color = Colors.grey.withOpacity(0.6 * lockFade);

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(lockCenter.dx, lockCenter.dy + lockSize * 0.15),
        width: lockSize * 0.7,
        height: lockSize * 0.6,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(bodyRect, _lockBodyPaint);

    // Lock shackle
    _lockShacklePaint
      ..color = Colors.grey.withOpacity(0.6 * lockFade)
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
      _lockShacklePaint,
    );

    // Keyhole
    _lockKeyholePaint.color = Colors.black.withOpacity(0.8 * lockFade);
    canvas.drawCircle(
      Offset(lockCenter.dx, lockCenter.dy + lockSize * 0.1),
      lockSize * 0.08,
      _lockKeyholePaint,
    );
  }

  void _drawCompletionBadge(Canvas canvas, Size size) {
    final badgeFade = ((progress - 0.8) / 0.2).clamp(0.0, 1.0);
    final badgeSize = size.width * 0.1;
    final badgePos = Offset(size.width - badgeSize - 6, badgeSize + 6);

    // Glow
    _badgeGlowPaint.color = NeonColors.green.withOpacity(0.6 * badgeFade);
    canvas.drawCircle(badgePos, badgeSize * 1.2, _badgeGlowPaint);

    // Badge background
    _badgeBgPaint.color = NeonColors.green.withOpacity(0.8 * badgeFade);
    canvas.drawCircle(badgePos, badgeSize * 0.8, _badgeBgPaint);

    // Checkmark
    _badgeCheckPaint.color = Colors.white.withOpacity(badgeFade);

    _badgeCheckPath
      ..reset()
      ..moveTo(badgePos.dx - badgeSize * 0.35, badgePos.dy)
      ..lineTo(badgePos.dx - badgeSize * 0.1, badgePos.dy + badgeSize * 0.25)
      ..lineTo(badgePos.dx + badgeSize * 0.35, badgePos.dy - badgeSize * 0.25);
    canvas.drawPath(_badgeCheckPath, _badgeCheckPaint);
  }

  void _drawScanLine(Canvas canvas, Size size) {
    final scanY = (pulseValue * size.height * 1.5) - size.height * 0.25;

    final key = (size.width.round() << 16) ^ primaryColor.value;
    final shader = _scanlineShaders.putIfAbsent(key, () {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          primaryColor.withOpacity(0.25),
          primaryColor.withOpacity(0.4),
          primaryColor.withOpacity(0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 16));
    });
    _scanPaint.shader = shader;
    canvas.save();
    canvas.translate(0, scanY - 8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 16), _scanPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(EpicLevelCardPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        pulseValue != oldDelegate.pulseValue ||
        isHovered != oldDelegate.isHovered ||
        hoverProgress != oldDelegate.hoverProgress ||
        clickProgress != oldDelegate.clickProgress;
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
