import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../widgets/cyber_grid_background.dart';
import '../widgets/epic_neon_title.dart';
import '../widgets/tron_button.dart';
import '../widgets/tron_dialog.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _glitchIntroController;
  late AnimationController _ambientController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _glitchIntroAnimation;

  bool _showContent = false;

  @override
  void initState() {
    super.initState();

    // Main fade controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Glitch intro effect
    _glitchIntroController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glitchIntroAnimation = CurvedAnimation(
      parent: _glitchIntroController,
      curve: Curves.easeOutExpo,
    );

    // Ambient animation
    _ambientController = AnimationController(
      duration: const Duration(milliseconds: 10000),
      vsync: this,
    )..repeat();

    // Sequence the intro
    _startIntroSequence();
  }

  void _startIntroSequence() async {
    // Wait a moment for the screen to load
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    // Start glitch intro
    _glitchIntroController.forward();

    // After glitch, show content
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CyberGridBackground(
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
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Animated Title Entry
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
                          child: Column(
                            children: [
                              // Decorative line above title
                              _AnimatedDecorativeLine(
                                fadeController: _fadeController,
                                color: NeonColors.cyan,
                              ),
                              const SizedBox(height: 16),
                              const EpicNeonTitle(
                                text: 'NEON DEFENSE',
                                fontSize: 52,
                                primaryColor: NeonColors.cyan,
                                secondaryColor: NeonColors.magenta,
                              ),
                              const SizedBox(height: 8),
                              const _SubtitleWidget(),
                              const SizedBox(height: 16),
                              // Decorative line below title
                              _AnimatedDecorativeLine(
                                fadeController: _fadeController,
                                color: NeonColors.magenta,
                                reverse: true,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Staggered TRON Buttons with built-in materialization
                      TronButton(
                        text: 'CAMPAIGN',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () => Navigator.pushNamed(context, '/levels'),
                        color: NeonColors.cyan,
                        delay: const Duration(milliseconds: 300),
                      ),
                      const SizedBox(height: 16),

                      TronButton(
                        text: 'STORY',
                        icon: Icons.auto_stories_rounded,
                        onPressed: () => Navigator.pushNamed(context, '/story'),
                        color: NeonColors.yellow,
                        delay: const Duration(milliseconds: 400),
                      ),
                      const SizedBox(height: 16),

                      TronButton(
                        text: 'CODEX',
                        icon: Icons.library_books_rounded,
                        onPressed: () => Navigator.pushNamed(context, '/codex'),
                        color: NeonColors.magenta,
                        delay: const Duration(milliseconds: 450),
                      ),
                      const SizedBox(height: 16),

                      TronButton(
                        text: 'UPGRADES',
                        icon: Icons.auto_awesome_rounded,
                        onPressed: () => Navigator.pushNamed(context, '/upgrades'),
                        color: NeonColors.cyan,
                        delay: const Duration(milliseconds: 500),
                      ),
                      const SizedBox(height: 16),

                      TronButton(
                        text: 'QUICK PLAY',
                        icon: Icons.bolt_rounded,
                        onPressed: () => Navigator.pushNamed(context, '/game', arguments: 1),
                        color: NeonColors.green,
                        delay: const Duration(milliseconds: 550),
                      ),
                      const SizedBox(height: 16),

                      TronButton(
                        text: 'SETTINGS',
                        icon: Icons.tune_rounded,
                        onPressed: () => Navigator.pushNamed(context, '/settings'),
                        color: NeonColors.purple,
                        delay: const Duration(milliseconds: 600),
                      ),
                      const SizedBox(height: 16),

                      TronButton(
                        text: 'CREDITS',
                        icon: Icons.auto_awesome_rounded,
                        onPressed: () => _showCreditsDialog(context),
                        color: NeonColors.yellow,
                        delay: const Duration(milliseconds: 650),
                      ),
                      const SizedBox(height: 16),

                      TronButton(
                        text: 'BENCHMARK',
                        icon: Icons.speed_rounded,
                        onPressed: () => Navigator.pushNamed(context, '/benchmark'),
                        color: const Color(0xFFFF6600),
                        delay: const Duration(milliseconds: 700),
                      ),

                      const Spacer(flex: 3),

                      // Version info with fade
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _fadeController,
                          curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
                        ),
                        child: const _VersionBadge(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

            // Corner decorations
            if (_showContent) ...[
              Positioned(
                top: 20,
                left: 20,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const _CornerDecoration(corner: _Corner.topLeft),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const _CornerDecoration(corner: _Corner.topRight),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const _CornerDecoration(corner: _Corner.bottomLeft),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const _CornerDecoration(corner: _Corner.bottomRight),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreditsDialog(BuildContext context) {
    TronDialog.show(
      context: context,
      title: 'CREDITS',
      icon: Icons.auto_awesome_rounded,
      primaryColor: NeonColors.magenta,
      width: 380,
      builder: (context) => const _CreditsContent(),
    );
  }
}

/// Glitch intro overlay that plays when the menu first loads
class _GlitchIntroOverlay extends StatelessWidget {
  const _GlitchIntroOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final random = math.Random(42);

    return IgnorePointer(
      child: CustomPaint(
        size: size,
        painter: _GlitchIntroPainter(
          progress: progress,
          random: random,
        ),
      ),
    );
  }
}

class _GlitchIntroPainter extends CustomPainter {
  _GlitchIntroPainter({required this.progress, required this.random});

  final double progress;
  final math.Random random;

  @override
  void paint(Canvas canvas, Size size) {
    // Fading black overlay
    final overlayOpacity = (1.0 - progress).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withOpacity(overlayOpacity * 0.9),
    );

    // Glitch horizontal bars
    if (progress < 0.8) {
      final barCount = (10 * (1.0 - progress)).toInt();
      for (int i = 0; i < barCount; i++) {
        final y = random.nextDouble() * size.height;
        final height = 2.0 + random.nextDouble() * 20;
        final xOffset = (random.nextDouble() - 0.5) * 50 * (1.0 - progress);

        canvas.drawRect(
          Rect.fromLTWH(xOffset, y, size.width, height),
          Paint()..color = NeonColors.cyan.withOpacity(0.3 * (1.0 - progress)),
        );

        // Magenta offset
        canvas.drawRect(
          Rect.fromLTWH(-xOffset, y + 2, size.width, height * 0.5),
          Paint()..color = NeonColors.magenta.withOpacity(0.2 * (1.0 - progress)),
        );
      }
    }

    // Scanlines
    if (progress < 0.9) {
      final scanlinePaint = Paint()
        ..color = Colors.white.withOpacity(0.05 * (1.0 - progress));
      for (double y = 0; y < size.height; y += 2) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
      }
    }

    // Central flash
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

/// Animated decorative line that expands from center
class _AnimatedDecorativeLine extends StatelessWidget {
  const _AnimatedDecorativeLine({
    required this.fadeController,
    required this.color,
    this.reverse = false,
  });

  final AnimationController fadeController;
  final Color color;
  final bool reverse;

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
              reverse: reverse,
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
    required this.reverse,
  });

  final double progress;
  final Color color;
  final bool reverse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    final lineWidth = size.width * 0.8 * progress;

    // Main line
    final linePaint = Paint()
      ..color = color.withOpacity(progress)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(center - lineWidth / 2, size.height / 2),
      Offset(center + lineWidth / 2, size.height / 2),
      linePaint,
    );

    // Glow
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

    // End decorations
    if (progress > 0.5) {
      final decorProgress = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
      final decorSize = 6.0 * decorProgress;

      // Left diamond
      _drawDiamond(
        canvas,
        Offset(center - lineWidth / 2, size.height / 2),
        decorSize,
        color.withOpacity(decorProgress),
      );

      // Right diamond
      _drawDiamond(
        canvas,
        Offset(center + lineWidth / 2, size.height / 2),
        decorSize,
        color.withOpacity(decorProgress),
      );

      // Center accent
      canvas.drawCircle(
        Offset(center, size.height / 2),
        3 * decorProgress,
        Paint()..color = color.withOpacity(decorProgress),
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

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerDecoration extends StatefulWidget {
  const _CornerDecoration({required this.corner});

  final _Corner corner;

  @override
  State<_CornerDecoration> createState() => _CornerDecorationState();
}

class _CornerDecorationState extends State<_CornerDecoration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(60, 60),
          painter: _CornerDecorationPainter(
            corner: widget.corner,
            pulseValue: _controller.value,
          ),
        );
      },
    );
  }
}

class _CornerDecorationPainter extends CustomPainter {
  _CornerDecorationPainter({required this.corner, required this.pulseValue});

  final _Corner corner;
  final double pulseValue;

  @override
  void paint(Canvas canvas, Size size) {
    final color = NeonColors.cyan;
    final opacity = 0.4 + pulseValue * 0.3;

    final linePaint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = color.withOpacity(opacity * 0.4)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    const lineLength = 25.0;
    late Offset corner1Start, corner1End, corner2Start, corner2End;
    late Offset dotPos;

    switch (corner) {
      case _Corner.topLeft:
        corner1Start = const Offset(0, 0);
        corner1End = Offset(lineLength, 0);
        corner2Start = const Offset(0, 0);
        corner2End = Offset(0, lineLength);
        dotPos = const Offset(0, 0);
        break;
      case _Corner.topRight:
        corner1Start = Offset(size.width, 0);
        corner1End = Offset(size.width - lineLength, 0);
        corner2Start = Offset(size.width, 0);
        corner2End = Offset(size.width, lineLength);
        dotPos = Offset(size.width, 0);
        break;
      case _Corner.bottomLeft:
        corner1Start = Offset(0, size.height);
        corner1End = Offset(lineLength, size.height);
        corner2Start = Offset(0, size.height);
        corner2End = Offset(0, size.height - lineLength);
        dotPos = Offset(0, size.height);
        break;
      case _Corner.bottomRight:
        corner1Start = Offset(size.width, size.height);
        corner1End = Offset(size.width - lineLength, size.height);
        corner2Start = Offset(size.width, size.height);
        corner2End = Offset(size.width, size.height - lineLength);
        dotPos = Offset(size.width, size.height);
        break;
    }

    // Draw glow
    canvas.drawLine(corner1Start, corner1End, glowPaint);
    canvas.drawLine(corner2Start, corner2End, glowPaint);

    // Draw lines
    canvas.drawLine(corner1Start, corner1End, linePaint);
    canvas.drawLine(corner2Start, corner2End, linePaint);

    // Draw corner dot
    canvas.drawCircle(
      dotPos,
      3 + pulseValue * 2,
      Paint()
        ..color = color.withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(
      dotPos,
      2,
      Paint()..color = Colors.white.withOpacity(opacity),
    );
  }

  @override
  bool shouldRepaint(_CornerDecorationPainter oldDelegate) =>
      oldDelegate.pulseValue != pulseValue;
}

class _SubtitleWidget extends StatefulWidget {
  const _SubtitleWidget();

  @override
  State<_SubtitleWidget> createState() => _SubtitleWidgetState();
}

class _SubtitleWidgetState extends State<_SubtitleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              NeonColors.magenta,
              NeonColors.purple,
              NeonColors.cyan,
              NeonColors.purple,
              NeonColors.magenta,
            ],
            stops: [
              0.0,
              _controller.value * 0.5,
              _controller.value,
              _controller.value * 0.5 + 0.5,
              1.0,
            ].map((e) => e.clamp(0.0, 1.0)).toList(),
          ).createShader(bounds),
          child: Text(
            'TOWER DEFENSE',
            style: NeonTextStyles.subtitle.copyWith(
              letterSpacing: 10,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _VersionBadge extends StatefulWidget {
  const _VersionBadge();

  @override
  State<_VersionBadge> createState() => _VersionBadgeState();
}

class _VersionBadgeState extends State<_VersionBadge>
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
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _pulseController.value;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: NeonColors.cyan.withOpacity(0.3 + pulse * 0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: NeonColors.cyan.withOpacity(0.1 * pulse),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: NeonColors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: NeonColors.green.withOpacity(0.5 + pulse * 0.3),
                      blurRadius: 6 + pulse * 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'v1.0.0',
                style: NeonTextStyles.small.copyWith(
                  color: NeonColors.cyan.withOpacity(0.6 + pulse * 0.2),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CreditsContent extends StatelessWidget {
  const _CreditsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _creditItem('GAME', 'NEON DEFENSE', NeonColors.cyan),
        const SizedBox(height: 16),
        _creditItem('ENGINE', 'Flutter + Flame', NeonColors.green),
        const SizedBox(height: 16),
        _creditItem('STYLE', 'Tron / Synthwave', NeonColors.purple),
        const SizedBox(height: 16),
        _creditItem('VERSION', '1.0.0 Release', NeonColors.yellow),
        const SizedBox(height: 32),
        TronButton(
          text: 'CLOSE',
          width: 160,
          height: 44,
          color: NeonColors.magenta,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _creditItem(String label, String value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: NeonTextStyles.small.copyWith(
              color: NeonColors.white.withOpacity(0.5),
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: NeonTextStyles.body.copyWith(
              color: color,
              shadows: [
                Shadow(color: color.withOpacity(0.5), blurRadius: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
