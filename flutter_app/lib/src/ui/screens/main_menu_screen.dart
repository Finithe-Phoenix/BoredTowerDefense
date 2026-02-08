import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../widgets/cyber_grid_background.dart';
import '../widgets/epic_neon_title.dart';
import '../widgets/tron_button.dart';
import '../widgets/tron_dialog.dart';
import '../../services/procedural_music_service.dart';

class _FastRng {
  int _state;

  _FastRng([int? seed]) : _state = (seed ?? 0x6d2b79f5) & 0x7fffffff;

  int _next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  double nextDouble() => _next() / 0x7fffffff;

  int nextInt(int max) => max <= 0 ? 0 : _next() % max;

  bool nextBool() => (_next() & 1) == 0;
}

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

    // Start the epic main menu music "NEON HORIZON"
    ProceduralMusicService.instance.playMainMenuMusic();

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),

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

                    const SizedBox(height: 24),

                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Staggered TRON Buttons with built-in materialization
                                    TronButton(
                                      text: 'CAMPAIGN',
                                      icon: Icons.play_arrow_rounded,
                                      onPressed: () => _navigateWithFadeOut('/levels'),
                                      color: NeonColors.cyan,
                                      delay: const Duration(milliseconds: 300),
                                    ),
                                    const SizedBox(height: 16),

                                    TronButton(
                                      text: 'STORY',
                                      icon: Icons.auto_stories_rounded,
                                      onPressed: () => _navigateWithFadeOut('/story'),
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
                                      onPressed: () => _navigateWithFadeOut('/game', arguments: 1),
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
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

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

  /// Navigate to a route with music fade-out for immersive transitions
  void _navigateWithFadeOut(String route, {Object? arguments}) {
    // Start fade-out (non-blocking, runs in background)
    ProceduralMusicService.instance.fadeOutMainMenuMusic(
      duration: const Duration(milliseconds: 800),
    );
    // Navigate immediately for responsive feel
    Navigator.pushNamed(context, route, arguments: arguments);
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
    final random = _FastRng(42);

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
  final _FastRng random;
  static final Paint _overlayPaint = Paint();
  static final Paint _barPaint = Paint();
  static final Paint _barAccentPaint = Paint();
  static final Paint _scanlinePaint = Paint();
  static final Paint _flashPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    // Fading black overlay
    final overlayOpacity = (1.0 - progress).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      _overlayPaint..color = Colors.black.withOpacity(overlayOpacity * 0.9),
    );

    // Glitch horizontal bars
    if (progress < 0.8) {
      final barCount = (10 * (1.0 - progress)).toInt();
      for (int i = 0; i < barCount; i++) {
        final y = random.nextDouble() * size.height;
        final height = 2.0 + random.nextDouble() * 20;
        final xOffset = (random.nextDouble() - 0.5) * 50 * (1.0 - progress);

        _barPaint.color = NeonColors.cyan.withOpacity(0.3 * (1.0 - progress));
        canvas.drawRect(
          Rect.fromLTWH(xOffset, y, size.width, height),
          _barPaint,
        );

        // Magenta offset
        _barAccentPaint.color = NeonColors.magenta.withOpacity(0.2 * (1.0 - progress));
        canvas.drawRect(
          Rect.fromLTWH(-xOffset, y + 2, size.width, height * 0.5),
          _barAccentPaint,
        );
      }
    }

    // Scanlines
    if (progress < 0.9) {
      _scanlinePaint.color = Colors.white.withOpacity(0.05 * (1.0 - progress));
      for (double y = 0; y < size.height; y += 2) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), _scanlinePaint);
      }
    }

    // Central flash
    if (progress > 0.3 && progress < 0.6) {
      final flashProgress = ((progress - 0.3) / 0.3).clamp(0.0, 1.0);
      final flashOpacity = math.sin(flashProgress * math.pi) * 0.3;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        _flashPaint..color = NeonColors.cyan.withOpacity(flashOpacity),
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
  static final Paint _linePaint = Paint()
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  static final Paint _glowPaint = Paint()
    ..strokeWidth = 6
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _dotPaint = Paint();
  static final Paint _diamondPaint = Paint();
  static final Path _diamondPath = Path();

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.01) return;
    final center = size.width / 2;
    final lineWidth = size.width * 0.8 * progress;

    // Main line
    _linePaint.color = color.withOpacity(progress);

    canvas.drawLine(
      Offset(center - lineWidth / 2, size.height / 2),
      Offset(center + lineWidth / 2, size.height / 2),
      _linePaint,
    );

    // Glow
    _glowPaint.color = color.withOpacity(0.3 * progress);

    canvas.drawLine(
      Offset(center - lineWidth / 2, size.height / 2),
      Offset(center + lineWidth / 2, size.height / 2),
      _glowPaint,
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
      _dotPaint.color = color.withOpacity(decorProgress);
      canvas.drawCircle(
        Offset(center, size.height / 2),
        3 * decorProgress,
        _dotPaint,
      );
    }
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Color color) {
    _diamondPath.reset();
    _diamondPath.moveTo(center.dx, center.dy - size);
    _diamondPath.lineTo(center.dx + size, center.dy);
    _diamondPath.lineTo(center.dx, center.dy + size);
    _diamondPath.lineTo(center.dx - size, center.dy);
    _diamondPath.close();
    _diamondPaint.color = color;
    canvas.drawPath(_diamondPath, _diamondPaint);
  }

  @override
  bool shouldRepaint(_DecorativeLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

/// Epic corner decoration with HUD-style data readouts and effects
class _CornerDecoration extends StatefulWidget {
  const _CornerDecoration({required this.corner});

  final _Corner corner;

  @override
  State<_CornerDecoration> createState() => _CornerDecorationState();
}

class _CornerDecorationState extends State<_CornerDecoration>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _dataController;
  late AnimationController _particleController;

  final List<_CornerParticle> _particles = [];
  final _FastRng _random = _FastRng();

  // Simulated data values
  double _powerLevel = 0.75;
  double _systemLoad = 0.42;
  double _networkPing = 0.15;

  @override
  void initState() {
    super.initState();

    _initializeParticles();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    )..repeat();

    _dataController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..addListener(_updateData);
    _dataController.repeat();

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..addListener(_updateParticles);
    _particleController.repeat();
  }

  void _initializeParticles() {
    for (int i = 0; i < 6; i++) {
      _particles.add(_CornerParticle(
        angle: _random.nextDouble() * math.pi * 2,
        radius: 20 + _random.nextDouble() * 40,
        speed: 0.01 + _random.nextDouble() * 0.02,
        size: 1 + _random.nextDouble() * 1.5,
        opacity: 0.3 + _random.nextDouble() * 0.4,
      ));
    }
  }

  void _updateData() {
    if (!mounted) return;
    // Simulate fluctuating data values - no setState needed,
    // AnimatedBuilder already rebuilds via pulse/rotation controllers
    _powerLevel = (_powerLevel + (_random.nextDouble() - 0.5) * 0.02).clamp(0.5, 1.0);
    _systemLoad = (_systemLoad + (_random.nextDouble() - 0.5) * 0.03).clamp(0.2, 0.8);
    _networkPing = (_networkPing + (_random.nextDouble() - 0.5) * 0.01).clamp(0.05, 0.4);
  }

  void _updateParticles() {
    if (!mounted) return;
    // Update particle angles - no setState needed,
    // AnimatedBuilder already rebuilds via pulse/rotation controllers
    for (final particle in _particles) {
      particle.angle += particle.speed;
      if (particle.angle > math.pi * 2) particle.angle -= math.pi * 2;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _dataController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _rotationController]),
      builder: (context, child) {
        return CustomPaint(
          size: const Size(100, 100),
          painter: _EpicCornerDecorationPainter(
            corner: widget.corner,
            pulseValue: _pulseController.value,
            rotationValue: _rotationController.value,
            particles: _particles,
            powerLevel: _powerLevel,
            systemLoad: _systemLoad,
            networkPing: _networkPing,
          ),
        );
      },
    );
  }
}

class _CornerParticle {
  double angle;
  double radius;
  double speed;
  double size;
  double opacity;

  _CornerParticle({
    required this.angle,
    required this.radius,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class _EpicCornerDecorationPainter extends CustomPainter {
  _EpicCornerDecorationPainter({
    required this.corner,
    required this.pulseValue,
    required this.rotationValue,
    required this.particles,
    required this.powerLevel,
    required this.systemLoad,
    required this.networkPing,
  });

  final _Corner corner;
  final double pulseValue;
  final double rotationValue;
  final List<_CornerParticle> particles;
  final double powerLevel;
  final double systemLoad;
  final double networkPing;
  static final Paint _outerGlowPaint = Paint();
  static final Paint _outerGlowPaint2 = Paint();
  static final Paint _outerGlowPaint3 = Paint();
  static final Paint _outerGlowPaint4 = Paint();
  static final Paint _particleGlowPaint = Paint();
  static final Paint _particleCorePaint = Paint();
  static final Paint _mainGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.square;
  static final Paint _mainPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.square;
  static final Paint _tickPaint = Paint();
  static final Paint _bracketPaint = Paint()
    ..style = PaintingStyle.stroke;
  static final Paint _bracket2Paint = Paint()
    ..style = PaintingStyle.stroke;
  static final Paint _barBgPaint = Paint();
  static final Paint _barFillPaint = Paint();
  static final Paint _barGlowPaint = Paint();
  static final Paint _dataBarPaint = Paint();
  static final Paint _pingPaint = Paint();
  static final Paint _outerArcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _innerArcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _coreGlowPaint = Paint();
  static final Paint _coreGlowPaint2 = Paint();
  static final Paint _coreGlowPaint3 = Paint();
  static final Paint _coreRingPaint = Paint()
    ..style = PaintingStyle.stroke;
  static final Paint _coreCenterPaint = Paint();
  static final Paint _corePulsePaint = Paint();
  static final Paint _pulseGlowPaint = Paint();
  static final Paint _pulseCorePaint = Paint();
  static final Paint _hexPaint = Paint()
    ..style = PaintingStyle.stroke;
  static final Paint _hexDotPaint = Paint();
  static final Paint _arcPaint = Paint()
    ..style = PaintingStyle.stroke;
  static final Paint _arcGlowPaint = Paint()
    ..style = PaintingStyle.stroke;
  static final Paint _indicatorPaint = Paint();
  static final Paint _indicatorGlowPaint = Paint();
  static final Paint _dataLinePaint = Paint();
  static final Paint _dataPointPaint = Paint();
  static final Path _hexPath = Path();
  static final Path _arcPath = Path();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final color = NeonColors.cyan;
    final secondaryColor = NeonColors.magenta;
    final accentColor = const Color(0xFFFF6600);
    final warningColor = NeonColors.yellow;

    final baseOpacity = 0.5 + pulseValue * 0.3;
    if (baseOpacity <= 0.01) return;

    // Determine corner position and direction
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

    // ===== LAYER 1: Deep outer glow =====
    _drawOuterGlow(canvas, cornerPos, color, baseOpacity);

    // ===== LAYER 2: Orbital particles =====
    _drawOrbitalParticles(canvas, cornerPos, color, secondaryColor, baseOpacity);

    // ===== LAYER 3: Main bracket structure =====
    _drawMainBracket(canvas, cornerPos, xDir, yDir, color, secondaryColor, baseOpacity);

    // ===== LAYER 4: Inner brackets =====
    _drawInnerBrackets(canvas, cornerPos, xDir, yDir, color, accentColor, baseOpacity);

    // ===== LAYER 5: Energy bars =====
    _drawEnergyBars(canvas, cornerPos, xDir, yDir, color, warningColor, baseOpacity);

    // ===== LAYER 6: Data readouts =====
    _drawDataReadouts(canvas, cornerPos, xDir, yDir, color, secondaryColor, baseOpacity);

    // ===== LAYER 7: Rotating rings =====
    _drawRotatingRings(canvas, cornerPos, color, secondaryColor, baseOpacity);

    // ===== LAYER 8: Power core =====
    _drawPowerCore(canvas, cornerPos, color, baseOpacity);

    // ===== LAYER 9: Energy pulses =====
    _drawEnergyPulses(canvas, cornerPos, xDir, yDir, color, accentColor, baseOpacity);

    // ===== LAYER 10: Hexagonal pattern =====
    _drawHexPattern(canvas, cornerPos, xDir, yDir, color, baseOpacity);

    // ===== LAYER 11: Electric arcs =====
    _drawElectricArcs(canvas, cornerPos, xDir, yDir, color, baseOpacity);

    // ===== LAYER 12: Data stream indicators =====
    _drawDataStreamIndicators(canvas, cornerPos, xDir, yDir, color, secondaryColor, baseOpacity);
  }

  void _drawOuterGlow(Canvas canvas, Offset pos, Color color, double opacity) {
    // Multi-layered glow
    _outerGlowPaint
      ..color = color.withOpacity(opacity * 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(pos, 12.0 * 4 + pulseValue * 4, _outerGlowPaint);

    _outerGlowPaint2
      ..color = color.withOpacity(opacity * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(pos, 12.0 * 3 + pulseValue * 4, _outerGlowPaint2);

    _outerGlowPaint3
      ..color = color.withOpacity(opacity * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(pos, 12.0 * 2 + pulseValue * 4, _outerGlowPaint3);

    _outerGlowPaint4
      ..color = color.withOpacity(opacity * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(pos, 12.0 * 1 + pulseValue * 4, _outerGlowPaint4);
  }

  void _drawOrbitalParticles(Canvas canvas, Offset pos, Color color, Color secondary, double opacity) {
    for (final particle in particles) {
      final x = pos.dx + math.cos(particle.angle) * particle.radius;
      final y = pos.dy + math.sin(particle.angle) * particle.radius;

      // Particle glow
      _particleGlowPaint
        ..color = (particle.opacity > 0.5 ? color : secondary).withOpacity(particle.opacity * opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(
        Offset(x, y),
        particle.size * 2,
        _particleGlowPaint,
      );

      // Particle core
      _particleCorePaint.color = Colors.white.withOpacity(particle.opacity * opacity * 0.6);
      canvas.drawCircle(Offset(x, y), particle.size, _particleCorePaint);
    }
  }

  void _drawMainBracket(Canvas canvas, Offset pos, double xDir, double yDir,
      Color color, Color secondary, double opacity) {
    const mainLength = 40.0;
    const thickness = 2.5;

    _mainGlowPaint
      ..color = color.withOpacity(opacity * 0.4)
      ..strokeWidth = thickness + 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    _mainPaint
      ..color = color.withOpacity(opacity)
      ..strokeWidth = thickness;

    // Horizontal line
    final hEnd = Offset(pos.dx + mainLength * xDir, pos.dy);
    canvas.drawLine(pos, hEnd, _mainGlowPaint);
    canvas.drawLine(pos, hEnd, _mainPaint);

    // Vertical line
    final vEnd = Offset(pos.dx, pos.dy + mainLength * yDir);
    canvas.drawLine(pos, vEnd, _mainGlowPaint);
    canvas.drawLine(pos, vEnd, _mainPaint);

    // Tick marks
    _tickPaint
      ..color = color.withOpacity(opacity * 0.6)
      ..strokeWidth = 1;

    for (int i = 1; i <= 6; i++) {
      final dist = 6.0 * i;
      final tickLength = i % 2 == 0 ? 4.0 : 2.5;

      // Horizontal ticks
      canvas.drawLine(
        Offset(pos.dx + dist * xDir, pos.dy),
        Offset(pos.dx + dist * xDir, pos.dy + tickLength * yDir),
        _tickPaint,
      );

      // Vertical ticks
      canvas.drawLine(
        Offset(pos.dx, pos.dy + dist * yDir),
        Offset(pos.dx + tickLength * xDir, pos.dy + dist * yDir),
        _tickPaint,
      );
    }
  }

  void _drawInnerBrackets(Canvas canvas, Offset pos, double xDir, double yDir,
      Color color, Color accent, double opacity) {
    const inset = 10.0;
    const length = 20.0;

    final innerPos = Offset(pos.dx + inset * xDir, pos.dy + inset * yDir);

    _bracketPaint
      ..color = accent.withOpacity(opacity * 0.7)
      ..strokeWidth = 1.5;

    // L-bracket
    canvas.drawLine(innerPos, Offset(innerPos.dx + length * xDir, innerPos.dy), _bracketPaint);
    canvas.drawLine(innerPos, Offset(innerPos.dx, innerPos.dy + length * yDir), _bracketPaint);

    // Second inner bracket
    final innerPos2 = Offset(pos.dx + inset * 1.8 * xDir, pos.dy + inset * 1.8 * yDir);
    _bracket2Paint
      ..color = color.withOpacity(opacity * 0.4)
      ..strokeWidth = 1;

    canvas.drawLine(innerPos2, Offset(innerPos2.dx + 12 * xDir, innerPos2.dy), _bracket2Paint);
    canvas.drawLine(innerPos2, Offset(innerPos2.dx, innerPos2.dy + 12 * yDir), _bracket2Paint);
  }

  void _drawEnergyBars(Canvas canvas, Offset pos, double xDir, double yDir,
      Color color, Color warning, double opacity) {
    // Power level bar
    final barStartX = pos.dx + 45 * xDir;
    final barY = pos.dy + 8 * yDir;
    const barWidth = 30.0;
    const barHeight = 4.0;

    // Bar background
    _barBgPaint.color = color.withOpacity(opacity * 0.2);
    canvas.drawRect(
      Rect.fromLTWH(
        xDir > 0 ? barStartX : barStartX - barWidth,
        yDir > 0 ? barY : barY - barHeight,
        barWidth,
        barHeight,
      ),
      _barBgPaint,
    );

    // Bar fill
    final fillWidth = barWidth * powerLevel;
    final barColor = powerLevel < 0.6 ? warning : color;
    _barFillPaint.color = barColor.withOpacity(opacity * 0.8);
    canvas.drawRect(
      Rect.fromLTWH(
        xDir > 0 ? barStartX : barStartX - fillWidth,
        yDir > 0 ? barY : barY - barHeight,
        fillWidth,
        barHeight,
      ),
      _barFillPaint,
    );

    // Bar glow
    _barGlowPaint
      ..color = barColor.withOpacity(opacity * 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRect(
      Rect.fromLTWH(
        xDir > 0 ? barStartX : barStartX - fillWidth,
        yDir > 0 ? barY : barY - barHeight,
        fillWidth,
        barHeight,
      ),
      _barGlowPaint,
    );
  }

  void _drawDataReadouts(Canvas canvas, Offset pos, double xDir, double yDir,
      Color color, Color secondary, double opacity) {
    // System load mini bars
    final dataX = pos.dx + 45 * xDir;
    final dataY = pos.dy + 18 * yDir;

    for (int i = 0; i < 5; i++) {
      final barHeight = 3.0 + (i == 2 ? systemLoad * 8 : (i % 2 == 0 ? 2 : 4));
      final barX = xDir > 0 ? dataX + i * 4 : dataX - i * 4 - 3;
      final barYStart = yDir > 0 ? dataY : dataY - barHeight;

      _dataBarPaint.color = (i == 2 ? secondary : color).withOpacity(opacity * 0.6);
      canvas.drawRect(
        Rect.fromLTWH(barX, barYStart, 3, barHeight),
        _dataBarPaint,
      );
    }

    // Network ping indicator (blinking dot)
    final pingX = pos.dx + 55 * xDir;
    final pingY = pos.dy + 30 * yDir;
    final pingActive = (rotationValue * 4).floor() % 2 == 0;

    _pingPaint
      ..color = (pingActive ? color : color.withOpacity(0.3)).withOpacity(opacity)
      ..maskFilter = pingActive ? const MaskFilter.blur(BlurStyle.normal, 2) : null;
    canvas.drawCircle(Offset(pingX, pingY), 3, _pingPaint);
  }

  void _drawRotatingRings(Canvas canvas, Offset pos, Color color, Color secondary, double opacity) {
    // Outer rotating ring
    _outerArcPaint
      ..color = color.withOpacity(opacity * 0.5)
      ..strokeWidth = 1.5;

    final outerAngle = rotationValue * math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: 22),
      outerAngle,
      math.pi * 0.4,
      false,
      _outerArcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: 22),
      outerAngle + math.pi,
      math.pi * 0.4,
      false,
      _outerArcPaint,
    );

    // Inner counter-rotating ring
    _innerArcPaint
      ..color = secondary.withOpacity(opacity * 0.4)
      ..strokeWidth = 1;

    final innerAngle = -rotationValue * math.pi * 2 * 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: 15),
      innerAngle,
      math.pi * 0.3,
      false,
      _innerArcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: 15),
      innerAngle + math.pi * 0.67,
      math.pi * 0.3,
      false,
      _innerArcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: 15),
      innerAngle + math.pi * 1.33,
      math.pi * 0.3,
      false,
      _innerArcPaint,
    );
  }

  void _drawPowerCore(Canvas canvas, Offset pos, Color color, double opacity) {
    final coreRadius = 4 + pulseValue * 2;

    // Outer glow layers
    _coreGlowPaint
      ..color = color.withOpacity(opacity * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(pos, coreRadius + 8, _coreGlowPaint);

    _coreGlowPaint2
      ..color = color.withOpacity(opacity * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(pos, coreRadius + 5, _coreGlowPaint2);

    _coreGlowPaint3
      ..color = color.withOpacity(opacity * 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(pos, coreRadius + 2, _coreGlowPaint3);

    // Core ring
    _coreRingPaint
      ..color = color.withOpacity(opacity * 0.7)
      ..strokeWidth = 1.5;
    canvas.drawCircle(pos, coreRadius, _coreRingPaint);

    // Core center
    _coreCenterPaint.color = Colors.white.withOpacity(opacity * 0.9);
    canvas.drawCircle(pos, 3, _coreCenterPaint);

    // Inner pulse
    _corePulsePaint
      ..color = color.withOpacity(opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(pos, 2, _corePulsePaint);
  }

  void _drawEnergyPulses(Canvas canvas, Offset pos, double xDir, double yDir,
      Color color, Color accent, double opacity) {
    // Traveling pulses along the bracket lines
    final pulseProgress = (rotationValue * 2) % 1.0;

    // Horizontal pulse
    final hPulseX = pos.dx + pulseProgress * 35 * xDir;
    canvas.drawCircle(
      Offset(hPulseX, pos.dy),
      3,
      _pulseGlowPaint
        ..color = accent.withOpacity(opacity * 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      Offset(hPulseX, pos.dy),
      1.5,
      _pulseCorePaint..color = Colors.white.withOpacity(opacity * 0.9),
    );

    // Vertical pulse (offset timing)
    final vPulseProgress = ((rotationValue * 2) + 0.5) % 1.0;
    final vPulseY = pos.dy + vPulseProgress * 35 * yDir;
    canvas.drawCircle(
      Offset(pos.dx, vPulseY),
      3,
      _pulseGlowPaint
        ..color = color.withOpacity(opacity * 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      Offset(pos.dx, vPulseY),
      1.5,
      _pulseCorePaint..color = Colors.white.withOpacity(opacity * 0.9),
    );
  }

  void _drawHexPattern(Canvas canvas, Offset pos, double xDir, double yDir,
      Color color, double opacity) {
    final hexCenter = Offset(pos.dx + 35 * xDir, pos.dy + 35 * yDir);
    const hexSize = 8.0;

    _hexPaint
      ..color = color.withOpacity(opacity * 0.25)
      ..strokeWidth = 0.8;

    // Draw small hexagon
    final path = _hexPath..reset();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final point = Offset(
        hexCenter.dx + hexSize * math.cos(angle),
        hexCenter.dy + hexSize * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, _hexPaint);

    // Animated fill segment
    final fillAngle = rotationValue * math.pi * 2;
    final fillPoint = Offset(
      hexCenter.dx + hexSize * 0.6 * math.cos(fillAngle),
      hexCenter.dy + hexSize * 0.6 * math.sin(fillAngle),
    );
    _hexDotPaint.color = color.withOpacity(opacity * 0.5);
    canvas.drawCircle(fillPoint, 2, _hexDotPaint);
  }

  void _drawElectricArcs(Canvas canvas, Offset pos, double xDir, double yDir,
      Color color, double opacity) {
    // Small electric arc effect near corner
    if (pulseValue > 0.7) {
      final arcOpacity = (pulseValue - 0.7) / 0.3;
      _arcPaint
        ..color = color.withOpacity(arcOpacity * opacity * 0.6)
        ..strokeWidth = 1
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

      final path = _arcPath..reset();
      path.moveTo(pos.dx + 8 * xDir, pos.dy + 2 * yDir);
      path.lineTo(pos.dx + 12 * xDir, pos.dy + 5 * yDir);
      path.lineTo(pos.dx + 10 * xDir, pos.dy + 8 * yDir);
      path.lineTo(pos.dx + 14 * xDir, pos.dy + 12 * yDir);

      canvas.drawPath(path, _arcPaint);

      // Arc glow
      _arcGlowPaint
        ..color = Colors.white.withOpacity(arcOpacity * opacity * 0.3)
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawPath(path, _arcGlowPaint);
    }
  }

  void _drawDataStreamIndicators(Canvas canvas, Offset pos, double xDir, double yDir,
      Color color, Color secondary, double opacity) {
    // Row of blinking status indicators
    final indicatorY = pos.dy + 50 * yDir;
    final numIndicators = 4;

    for (int i = 0; i < numIndicators; i++) {
      final indicatorX = pos.dx + (15 + i * 8) * xDir;
      final phase = (rotationValue * 6 + i * 0.25) % 1.0;
      final isActive = phase < 0.5;
      final indicatorColor = i == 0 ? secondary : color;

      _indicatorPaint.color = indicatorColor.withOpacity(isActive ? opacity * 0.8 : opacity * 0.2);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(indicatorX, indicatorY), width: 4, height: 4),
        _indicatorPaint,
      );

      if (isActive) {
        _indicatorGlowPaint
          ..color = indicatorColor.withOpacity(opacity * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawRect(
          Rect.fromCenter(center: Offset(indicatorX, indicatorY), width: 4, height: 4),
          _indicatorGlowPaint,
        );
      }
    }

    // Horizontal data line
    final lineY = pos.dy + 60 * yDir;
    final lineStart = pos.dx + 10 * xDir;
    final lineEnd = pos.dx + 50 * xDir;

    _dataLinePaint
      ..color = color.withOpacity(opacity * 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(lineStart, lineY),
      Offset(lineEnd, lineY),
      _dataLinePaint,
    );

    // Moving data point on line
    final dataPointX = lineStart + (lineEnd - lineStart) * ((rotationValue * 3) % 1.0);
    _dataPointPaint.color = secondary.withOpacity(opacity * 0.8);
    canvas.drawCircle(Offset(dataPointX, lineY), 2, _dataPointPaint);
  }

  @override
  bool shouldRepaint(_EpicCornerDecorationPainter oldDelegate) {
    return pulseValue != oldDelegate.pulseValue ||
        rotationValue != oldDelegate.rotationValue ||
        powerLevel != oldDelegate.powerLevel ||
        systemLoad != oldDelegate.systemLoad;
  }
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

