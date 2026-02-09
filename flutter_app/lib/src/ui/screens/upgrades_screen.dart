import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/upgrade_data.dart';
import '../../services/upgrade_service.dart';
import '../theme/neon_theme.dart';
import '../widgets/cyber_grid_background.dart';
import '../widgets/epic_neon_button.dart';
import '../widgets/epic_neon_title.dart';

class UpgradesScreen extends StatefulWidget {
  const UpgradesScreen({super.key});

  @override
  State<UpgradesScreen> createState() => _UpgradesScreenState();
}

class _UpgradesScreenState extends State<UpgradesScreen>
    with TickerProviderStateMixin {
  final UpgradeService _service = UpgradeService.instance;
  bool _loading = true;

  late AnimationController _fadeController;
  late AnimationController _glitchIntroController;
  late AnimationController _ambientController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glitchIntroAnimation;

  bool _showContent = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _glitchIntroController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glitchIntroAnimation = CurvedAnimation(
      parent: _glitchIntroController,
      curve: Curves.easeOutExpo,
    );

    _ambientController = AnimationController(
      duration: const Duration(milliseconds: 10000),
      vsync: this,
    )..repeat();

    _load();
    _startIntroSequence();
  }

  void _startIntroSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    _glitchIntroController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() => _showContent = true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glitchIntroController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _buyUpgrade(UpgradeDefinition upgrade) async {
    final ok = await _service.purchase(upgrade.id);
    if (mounted) {
      setState(() {});
    }
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough cores or max level reached.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CyberGridBackground(
        backgroundColor: Colors.black,
        enableParticles: true,
        enableGlitch: true,
        enableDataStreams: true,
        child: Stack(
          children: [
            // Glitch intro overlay
            AnimatedBuilder(
              animation: _glitchIntroAnimation,
              builder: (context, child) {
                if (_glitchIntroAnimation.value >= 1.0) {
                  return const SizedBox.shrink();
                }
                return _GlitchIntroOverlay(
                  progress: _glitchIntroAnimation.value,
                );
              },
            ),

            // Main content
            if (_showContent)
              SafeArea(
                child: _loading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                NeonColors.cyan,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'INITIALIZING FORGE...',
                              style: NeonTextStyles.body.copyWith(
                                color: NeonColors.cyan.withOpacity(0.7),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Header with epic fade-in
                          FadeTransition(
                            opacity: CurvedAnimation(
                              parent: _fadeController,
                              curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                            ),
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, -0.3),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _fadeController,
                                curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
                              )),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        _EpicBackButton(
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: EpicNeonTitle(
                                            text: 'UPGRADE FORGE',
                                            fontSize: 34,
                                            primaryColor: NeonColors.cyan,
                                            secondaryColor: NeonColors.magenta,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _AnimatedDecorativeLine(
                                      fadeController: _fadeController,
                                      color: NeonColors.magenta,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Epic currency banner
                          FadeTransition(
                            opacity: CurvedAnimation(
                              parent: _fadeController,
                              curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              child: _EpicCurrencyBanner(
                                cores: _service.currency,
                                ambientController: _ambientController,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Upgrade cards list
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              itemCount: _service.metaUpgrades.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final upgrade = _service.metaUpgrades[index];
                                final level = _service.levelFor(upgrade.id);
                                final maxed = level >= upgrade.maxLevel;
                                final cost = upgrade.costForLevel(level);
                                final canAfford = _service.currency >= cost;
                                return FadeTransition(
                                  opacity: CurvedAnimation(
                                    parent: _fadeController,
                                    curve: Interval(
                                      0.3 + (index * 0.05),
                                      0.8 + (index * 0.05),
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                  child: _EpicUpgradeCard(
                                    upgrade: upgrade,
                                    level: level,
                                    cost: cost,
                                    canAfford: canAfford,
                                    isMaxed: maxed,
                                    onUpgrade: () => _buyUpgrade(upgrade),
                                    delay: Duration(milliseconds: 300 + (index * 80)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),

            // Epic corner decorations (with IgnorePointer to allow taps through)
            if (_showContent && !_loading) ...[
              Positioned(
                top: 20,
                left: 20,
                child: IgnorePointer(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _CornerDecoration(
                      corner: _Corner.topLeft,
                      ambientController: _ambientController,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IgnorePointer(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _CornerDecoration(
                      corner: _Corner.topRight,
                      ambientController: _ambientController,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: IgnorePointer(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _CornerDecoration(
                      corner: _Corner.bottomLeft,
                      ambientController: _ambientController,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: IgnorePointer(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _CornerDecoration(
                      corner: _Corner.bottomRight,
                      ambientController: _ambientController,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Glitch intro overlay
class _GlitchIntroOverlay extends StatelessWidget {
  const _GlitchIntroOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: CustomPaint(
        size: size,
        painter: _GlitchIntroPainter(progress: progress),
      ),
    );
  }
}

class _GlitchIntroPainter extends CustomPainter {
  _GlitchIntroPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final overlayOpacity = (1.0 - progress).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withOpacity(overlayOpacity * 0.9),
    );

    if (progress < 0.8) {
      final random = math.Random(42);
      final barCount = (10 * (1.0 - progress)).toInt();
      for (int i = 0; i < barCount; i++) {
        final y = random.nextDouble() * size.height;
        final height = 2.0 + random.nextDouble() * 20;
        final xOffset = (random.nextDouble() - 0.5) * 50 * (1.0 - progress);

        canvas.drawRect(
          Rect.fromLTWH(xOffset, y, size.width, height),
          Paint()..color = NeonColors.cyan.withOpacity(0.3 * (1.0 - progress)),
        );

        canvas.drawRect(
          Rect.fromLTWH(-xOffset, y + 2, size.width, height * 0.5),
          Paint()..color = NeonColors.magenta.withOpacity(0.2 * (1.0 - progress)),
        );
      }
    }

    if (progress > 0.3 && progress < 0.6) {
      final flashProgress = ((progress - 0.3) / 0.3).clamp(0.0, 1.0);
      final flashOpacity = math.sin(flashProgress * math.pi) * 0.3;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = NeonColors.cyan.withOpacity(flashOpacity),
      );
    }
  }

  @override
  bool shouldRepaint(_GlitchIntroPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Animated decorative line
class _AnimatedDecorativeLine extends StatelessWidget {
  const _AnimatedDecorativeLine({
    required this.fadeController,
    required this.color,
  });

  final AnimationController fadeController;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fadeController,
      builder: (context, child) {
        final progress = CurvedAnimation(
          parent: fadeController,
          curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
        ).value;

        return SizedBox(
          width: 300,
          height: 20,
          child: CustomPaint(
            painter: _DecorativeLinePainter(
              progress: progress,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

class _DecorativeLinePainter extends CustomPainter {
  _DecorativeLinePainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.01) return;
    final center = size.width / 2;
    final lineWidth = size.width * 0.8 * progress;

    final linePaint = Paint()
      ..color = color.withOpacity(progress)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(center - lineWidth / 2, size.height / 2),
      Offset(center + lineWidth / 2, size.height / 2),
      linePaint,
    );

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3 * progress)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawLine(
      Offset(center - lineWidth / 2, size.height / 2),
      Offset(center + lineWidth / 2, size.height / 2),
      glowPaint,
    );

    if (progress > 0.5) {
      final decorProgress = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
      final decorSize = 6.0 * decorProgress;

      final dotPaint = Paint()..color = color.withOpacity(decorProgress);

      _drawDiamond(
        canvas,
        Offset(center - lineWidth / 2, size.height / 2),
        decorSize,
        color.withOpacity(decorProgress),
      );

      _drawDiamond(
        canvas,
        Offset(center + lineWidth / 2, size.height / 2),
        decorSize,
        color.withOpacity(decorProgress),
      );

      canvas.drawCircle(
        Offset(center, size.height / 2),
        3 * decorProgress,
        dotPaint,
      );
    }
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size, center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DecorativeLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Epic back button
class _EpicBackButton extends StatefulWidget {
  const _EpicBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_EpicBackButton> createState() => _EpicBackButtonState();
}

class _EpicBackButtonState extends State<_EpicBackButton>
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
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            final hover = _hoverController.value;
            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: NeonColors.darkBg.withOpacity(0.8 + hover * 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: NeonColors.cyan.withOpacity(0.6 + hover * 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: NeonColors.cyan.withOpacity(0.2 + hover * 0.4),
                    blurRadius: 12 + hover * 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back,
                color: NeonColors.cyan.withOpacity(0.8 + hover * 0.2),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Epic currency banner with animations
class _EpicCurrencyBanner extends StatelessWidget {
  const _EpicCurrencyBanner({
    required this.cores,
    required this.ambientController,
  });

  final int cores;
  final AnimationController ambientController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambientController,
      builder: (context, child) {
        final pulse = math.sin(ambientController.value * 2 * math.pi) * 0.5 + 0.5;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: NeonColors.darkBg.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: NeonColors.cyan.withOpacity(0.6 + pulse * 0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: NeonColors.cyan.withOpacity(0.3 + pulse * 0.2),
                blurRadius: 20 + pulse * 10,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: NeonColors.magenta.withOpacity(0.1 + pulse * 0.1),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              // Animated icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NeonColors.cyan.withOpacity(0.15 + pulse * 0.1),
                  border: Border.all(
                    color: NeonColors.cyan.withOpacity(0.5 + pulse * 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: NeonColors.cyan.withOpacity(0.4 + pulse * 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: ambientController.value * 2 * math.pi,
                  child: const Icon(
                    Icons.memory,
                    color: NeonColors.cyan,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DATA CORES',
                    style: NeonTextStyles.small.copyWith(
                      color: NeonColors.cyan.withOpacity(0.7),
                      letterSpacing: 2,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        NeonColors.yellow,
                        NeonColors.cyan,
                        NeonColors.yellow,
                      ],
                      stops: [0.0, pulse, 1.0],
                    ).createShader(bounds),
                    child: Text(
                      cores.toString(),
                      style: NeonTextStyles.title.copyWith(
                        fontSize: 26,
                        color: Colors.white,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: NeonColors.yellow.withOpacity(0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Energy bars indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (index) => Container(
                        width: 4,
                        height: 12 + (index % 2 == 0 ? 6 : 0) + pulse * 4,
                        margin: const EdgeInsets.only(left: 3),
                        decoration: BoxDecoration(
                          color: index < 3
                              ? NeonColors.cyan.withOpacity(0.7 + pulse * 0.3)
                              : NeonColors.cyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: index < 3
                              ? [
                                  BoxShadow(
                                    color: NeonColors.cyan.withOpacity(0.6),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CAPACITY',
                    style: NeonTextStyles.small.copyWith(
                      color: NeonColors.white.withOpacity(0.4),
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

/// Epic corner decoration
class _CornerDecoration extends StatefulWidget {
  const _CornerDecoration({
    required this.corner,
    required this.ambientController,
  });

  final _Corner corner;
  final AnimationController ambientController;

  @override
  State<_CornerDecoration> createState() => _CornerDecorationState();
}

class _CornerDecorationState extends State<_CornerDecoration>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, widget.ambientController]),
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 80),
          painter: _CornerDecorationPainter(
            corner: widget.corner,
            pulseValue: _pulseController.value,
            rotationValue: widget.ambientController.value,
          ),
        );
      },
    );
  }
}

class _CornerDecorationPainter extends CustomPainter {
  _CornerDecorationPainter({
    required this.corner,
    required this.pulseValue,
    required this.rotationValue,
  });

  final _Corner corner;
  final double pulseValue;
  final double rotationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final color = NeonColors.cyan;
    final baseOpacity = 0.5 + pulseValue * 0.3;

    late Offset cornerPos;
    late double xDir, yDir;

    switch (corner) {
      case _Corner.topLeft:
        cornerPos = const Offset(0, 0);
        xDir = 1;
        yDir = 1;
        break;
      case _Corner.topRight:
        cornerPos = Offset(size.width, 0);
        xDir = -1;
        yDir = 1;
        break;
      case _Corner.bottomLeft:
        cornerPos = Offset(0, size.height);
        xDir = 1;
        yDir = -1;
        break;
      case _Corner.bottomRight:
        cornerPos = Offset(size.width, size.height);
        xDir = -1;
        yDir = -1;
        break;
    }

    final mainPaint = Paint()
      ..color = color.withOpacity(baseOpacity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final glowPaint = Paint()
      ..color = color.withOpacity(baseOpacity * 0.4)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final hEnd = Offset(cornerPos.dx + 30 * xDir, cornerPos.dy);
    canvas.drawLine(cornerPos, hEnd, glowPaint);
    canvas.drawLine(cornerPos, hEnd, mainPaint);

    final vEnd = Offset(cornerPos.dx, cornerPos.dy + 30 * yDir);
    canvas.drawLine(cornerPos, vEnd, glowPaint);
    canvas.drawLine(cornerPos, vEnd, mainPaint);

    final arcPaint = Paint()
      ..color = NeonColors.magenta.withOpacity(baseOpacity * 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final arcAngle = rotationValue * math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: cornerPos, radius: 18),
      arcAngle,
      math.pi * 0.4,
      false,
      arcPaint,
    );

    final coreGlowPaint = Paint()
      ..color = color.withOpacity(baseOpacity * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(cornerPos, 8 + pulseValue * 4, coreGlowPaint);

    final dotPaint = Paint()..color = Colors.white.withOpacity(baseOpacity);
    canvas.drawCircle(cornerPos, 3, dotPaint);
  }

  @override
  bool shouldRepaint(_CornerDecorationPainter oldDelegate) {
    return pulseValue != oldDelegate.pulseValue ||
        rotationValue != oldDelegate.rotationValue;
  }
}

/// Epic upgrade card with TRON materialization
class _EpicUpgradeCard extends StatefulWidget {
  const _EpicUpgradeCard({
    required this.upgrade,
    required this.level,
    required this.cost,
    required this.canAfford,
    required this.isMaxed,
    required this.onUpgrade,
    required this.delay,
  });

  final UpgradeDefinition upgrade;
  final int level;
  final int cost;
  final bool canAfford;
  final bool isMaxed;
  final VoidCallback onUpgrade;
  final Duration delay;

  @override
  State<_EpicUpgradeCard> createState() => _EpicUpgradeCardState();
}

class _EpicUpgradeCardState extends State<_EpicUpgradeCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.level / widget.upgrade.maxLevel;
    final accent = widget.isMaxed
        ? NeonColors.green
        : widget.canAfford
            ? NeonColors.cyan
            : NeonColors.red;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _hoverController]),
        builder: (context, child) {
          final pulse = _pulseController.value;
          final hover = _hoverController.value;

          return Transform.scale(
            scale: 1.0 + (hover * 0.02),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: NeonColors.darkBg.withOpacity(0.9 + hover * 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accent.withOpacity(0.5 + pulse * 0.2 + hover * 0.2),
                  width: 1.5 + hover * 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.2 + pulse * 0.15 + hover * 0.3),
                    blurRadius: 20 + hover * 15,
                    spreadRadius: 2 + hover * 2,
                  ),
                  if (hover > 0)
                    BoxShadow(
                      color: NeonColors.magenta.withOpacity(0.1 * hover),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with icon
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withOpacity(0.15 + pulse * 0.1),
                          border: Border.all(
                            color: accent.withOpacity(0.5 + pulse * 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.isMaxed
                              ? Icons.check_circle
                              : Icons.auto_awesome,
                          color: accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  accent,
                                  Colors.white,
                                  accent,
                                ],
                                stops: [0.0, pulse, 1.0],
                              ).createShader(bounds),
                              child: Text(
                                widget.upgrade.name,
                                style: NeonTextStyles.title.copyWith(
                                  fontSize: 20,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.upgrade.description,
                              style: NeonTextStyles.small.copyWith(
                                color: NeonColors.white.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Epic progress bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  NeonColors.magenta.withOpacity(0.9),
                                  accent.withOpacity(0.9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Animated shine effect
                        if (progress > 0)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: OverflowBox(
                                maxWidth: double.infinity,
                                child: Transform.translate(
                                  offset: Offset(
                                    -200 + (_pulseController.value * 400),
                                    0,
                                  ),
                                  child: Container(
                                    width: 100,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Level indicator
                  Row(
                    children: [
                      Text(
                        'LEVEL',
                        style: NeonTextStyles.small.copyWith(
                          color: NeonColors.white.withOpacity(0.5),
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.level}/${widget.upgrade.maxLevel}',
                        style: NeonTextStyles.body.copyWith(
                          color: accent.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Cost and button
                  Row(
                    children: [
                      if (!widget.isMaxed) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.canAfford
                                  ? NeonColors.yellow.withOpacity(0.5)
                                  : NeonColors.red.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.memory,
                                size: 14,
                                color: widget.canAfford
                                    ? NeonColors.yellow
                                    : NeonColors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.cost}',
                                style: NeonTextStyles.small.copyWith(
                                  color: widget.canAfford
                                      ? NeonColors.yellow
                                      : NeonColors.red,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: NeonColors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: NeonColors.green.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: NeonColors.green,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'MAXED',
                                style: NeonTextStyles.small.copyWith(
                                  color: NeonColors.green,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      EpicNeonButton(
                        text: widget.isMaxed ? 'COMPLETE' : 'UPGRADE',
                        height: 42,
                        width: 150,
                        color: accent,
                        onPressed: widget.onUpgrade,
                        enabled: !widget.isMaxed && widget.canAfford,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
