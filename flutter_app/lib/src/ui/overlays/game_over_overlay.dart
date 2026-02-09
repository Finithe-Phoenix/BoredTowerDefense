import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../widgets/neon_button.dart';

class GameOverOverlay extends StatefulWidget {
  const GameOverOverlay({
    super.key,
    required this.score,
    required this.wavesCleared,
    required this.onRestart,
    required this.onQuit,
  });

  final int score;
  final int wavesCleared;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _glitchController;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late AnimationController _shatterController;
  late Animation<double> _fadeAnimation;

  int _rngState = 0x1234abcd;
  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }
  double _nextUnit() => _lcgNext() / 0x7fffffff;
  int _nextInt(int max) => max <= 0 ? 0 : _lcgNext() % max;

  double _glitchOffset = 0;
  double _verticalGlitch = 0;
  bool _showGlitch = false;
  bool _showHeavyGlitch = false;
  int _glitchFrame = 0;
  Timer? _glitchTimer;

  @override
  void initState() {
    super.initState();

    // Shatter entrance animation
    _shatterController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    )..addListener(_updateGlitch);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..repeat();

    // Start with shatter effect, then main animation
    _shatterController.forward().then((_) {
      _mainController.forward();
      // Start aggressive glitch cycle after shatter
      _glitchTimer = Timer(const Duration(milliseconds: 200), _triggerGlitchCycle);
    });

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    );
  }

  void _updateGlitch() {
    if (_nextUnit() < 0.5) {
      setState(() {
        _showGlitch = true;
        _glitchOffset = (_nextUnit() - 0.5) * 15;
        _verticalGlitch = (_nextUnit() - 0.5) * 5;
        _glitchFrame = _nextInt(100);
        _showHeavyGlitch = _nextUnit() < 0.3;
      });
    } else {
      setState(() {
        _showGlitch = false;
        _showHeavyGlitch = false;
      });
    }
  }

  void _triggerGlitchCycle() {
    if (!mounted) return;
    _glitchController.forward(from: 0).then((_) {
      if (mounted) {
        _glitchTimer?.cancel();
        _glitchTimer = Timer(
          Duration(milliseconds: 800 + _nextInt(1500)),
          _triggerGlitchCycle,
        );
      }
    });
  }

  @override
  void dispose() {
    _glitchTimer?.cancel();
    _mainController.dispose();
    _glitchController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    _shatterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _shakeController]),
        builder: (context, child) {
          final shake = _showGlitch
              ? Offset(
                  math.sin(_shakeController.value * math.pi * 4) * 2,
                  math.cos(_shakeController.value * math.pi * 4) * 1,
                )
              : Offset.zero;

          return Transform.translate(
            offset: shake,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    const Color(0xFF1a0505).withOpacity(0.95),
                    const Color(0xFF0a0202).withOpacity(0.98),
                    Colors.black.withOpacity(0.99),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Screen shatter entrance
                  AnimatedBuilder(
                    animation: _shatterController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _ScreenShatterPainter(
                          animation: _shatterController.value,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),

                  // Danger grid background
                  CustomPaint(
                    painter: _DangerGridPainter(
                      animation: _pulseController.value,
                      glitchOffset: _showGlitch ? _glitchOffset : 0,
                    ),
                    size: Size.infinite,
                  ),

                  // Heavy scanlines for danger
                  CustomPaint(
                    painter: _DangerScanlinesPainter(
                      animation: _mainController.value,
                      intensity: _showHeavyGlitch ? 1.0 : 0.5,
                    ),
                    size: Size.infinite,
                  ),

                  // Corruption overlay
                  if (_showHeavyGlitch)
                    CustomPaint(
                      painter: _CorruptionPainter(frame: _glitchFrame),
                      size: Size.infinite,
                    ),

                  // Main content
                  Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Transform.translate(
                        offset: Offset(
                          _showGlitch ? _glitchOffset * 0.3 : 0,
                          _showGlitch ? _verticalGlitch : 0,
                        ),
                        child: _buildContent(),
                      ),
                    ),
                  ),

                  // Warning borders
                  _WarningBorders(
                    pulseAnimation: _pulseController,
                    showGlitch: _showGlitch,
                  ),

                  // Corner warnings
                  ..._buildCornerWarnings(),

                  // Glitch overlay bars
                  if (_showGlitch) _buildGlitchBars(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Warning icon
          _AnimatedWarningIcon(
            controller: _pulseController,
            showGlitch: _showGlitch,
          ),

          const SizedBox(height: 20),

          // Game Over title with heavy glitch
          _GlitchTitle(
            text: 'GAME OVER',
            showGlitch: _showGlitch,
            glitchOffset: _glitchOffset,
            showHeavyGlitch: _showHeavyGlitch,
          ),

          const SizedBox(height: 8),

          // System breach message with typing effect
          _BreachMessage(
            controller: _mainController,
            showGlitch: _showGlitch,
          ),

          const SizedBox(height: 30),

          // Error-style stats panel
          _ErrorStatsPanel(
            stats: [
              _ErrorStat('WAVES SURVIVED', '${widget.wavesCleared}', NeonColors.orange),
              _ErrorStat('FINAL SCORE', '${widget.score}', NeonColors.cyan),
              _ErrorStat('SYSTEM STATUS', 'CRITICAL', NeonColors.red),
            ],
            pulseController: _pulseController,
            showGlitch: _showGlitch,
          ),

          const SizedBox(height: 30),

          // Retry button with emphasis
          _DangerButton(
            text: 'REINICIAR SISTEMA',
            color: NeonColors.yellow,
            delay: 0,
            controller: _mainController,
            onPressed: widget.onRestart,
            isPrimary: true,
          ),
          const SizedBox(height: 16),

          _DangerButton(
            text: 'ABORTAR MISION',
            color: NeonColors.red,
            delay: 150,
            controller: _mainController,
            onPressed: widget.onQuit,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerWarnings() {
    return [
      Positioned(
        top: 30,
        left: 30,
        child: _MalfunctionCorner(
          rotation: 0,
          pulseController: _pulseController,
          message: 'DEFENSE GRID: OFFLINE',
        ),
      ),
      Positioned(
        top: 30,
        right: 30,
        child: _MalfunctionCorner(
          rotation: math.pi / 2,
          pulseController: _pulseController,
          message: 'CORE INTEGRITY: 0%',
        ),
      ),
      Positioned(
        bottom: 30,
        left: 30,
        child: _MalfunctionCorner(
          rotation: -math.pi / 2,
          pulseController: _pulseController,
          message: 'ENERGY RESERVES: DEPLETED',
        ),
      ),
      Positioned(
        bottom: 30,
        right: 30,
        child: _MalfunctionCorner(
          rotation: math.pi,
          pulseController: _pulseController,
          message: 'SYSTEM STATUS: CRITICAL',
        ),
      ),
    ];
  }

  Widget _buildGlitchBars() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _GlitchBarsPainter(
            offset: _glitchOffset,
            frame: _glitchFrame,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════

class _DangerGridPainter extends CustomPainter {
  final double animation;
  final double glitchOffset;

  _DangerGridPainter({required this.animation, required this.glitchOffset});

  static final Paint _linePaint = Paint()..strokeWidth = 1;
  static final Paint _centerGlowPaint = Paint();
  static final Map<int, Shader> _centerGlowShaders = {};

  int _centerGlowKey(Size size, int opacityStep) {
    return (size.width.round() << 32) ^ (size.height.round() << 16) ^ opacityStep;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    const spacing = 50.0;

    // Vertical lines with danger pulse
    for (double x = 0; x < size.width; x += spacing) {
      final distFromCenter = (x - size.width / 2).abs() / (size.width / 2);
      final pulse = 0.02 + math.sin(animation * math.pi * 2 + x * 0.01) * 0.02;
      final opacity = (pulse * (1 - distFromCenter * 0.5)).clamp(0.01, 0.08);

      _linePaint.color = NeonColors.red.withOpacity(opacity);
      canvas.drawLine(
        Offset(x + glitchOffset * 0.1, 0),
        Offset(x + glitchOffset * 0.1, size.height),
        _linePaint,
      );
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      final pulse = 0.02 + math.sin(animation * math.pi * 2 + y * 0.01) * 0.02;
      _linePaint.color = NeonColors.red.withOpacity(pulse.clamp(0.01, 0.06));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _linePaint);
    }

    // Center danger glow
    final opacityStep = ((0.15 + animation * 0.1) * 60).round();
    final key = _centerGlowKey(size, opacityStep);
    final shader = _centerGlowShaders.putIfAbsent(key, () {
      if (_centerGlowShaders.length > 32) {
        _centerGlowShaders.clear();
      }
      final opacity = opacityStep / 60.0;
      return RadialGradient(
        colors: [
          NeonColors.red.withOpacity(opacity),
          NeonColors.red.withOpacity(0),
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.6,
        height: size.height * 0.6,
      ));
    });
    _centerGlowPaint.shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _centerGlowPaint);
  }

  @override
  bool shouldRepaint(covariant _DangerGridPainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.glitchOffset != glitchOffset;
}

class _DangerScanlinesPainter extends CustomPainter {
  final double animation;
  final double intensity;

  _DangerScanlinesPainter({required this.animation, required this.intensity});

  static final Paint _staticLinePaint = Paint();
  static final Paint _scanPaint = Paint();
  static final Map<int, Shader> _scanShaders = {};

  int _scanKey(Size size, int intensityStep) {
    return (size.width.round() << 16) ^ intensityStep;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    // Static scanlines
    _staticLinePaint.color = Colors.black.withOpacity(0.05 * intensity);
    for (double y = 0; y < size.height; y += 2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _staticLinePaint);
    }

    // Moving danger scanline
    final scanY = (animation * size.height * 1.5) % size.height;
    final intensityStep = (intensity * 20).round();
    final key = _scanKey(size, intensityStep);
    final shader = _scanShaders.putIfAbsent(key, () {
      if (_scanShaders.length > 32) {
        _scanShaders.clear();
      }
      final opacity = 0.1 * (intensityStep / 20.0);
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          NeonColors.red.withOpacity(0),
          NeonColors.red.withOpacity(opacity),
          NeonColors.red.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 60));
    });
    _scanPaint.shader = shader;
    canvas.save();
    canvas.translate(0, scanY - 30);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 60), _scanPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DangerScanlinesPainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.intensity != intensity;
}

class _CorruptionPainter extends CustomPainter {
  final int frame;

  _CorruptionPainter({required this.frame});

  static final Paint _rectPaint = Paint();
  static final Paint _noisePaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    int rngState = frame ^ 0x6c8e9cf5;
    int lcgNext() {
      rngState = (1664525 * rngState + 1013904223) & 0x7fffffff;
      return rngState;
    }
    double nextUnit() => lcgNext() / 0x7fffffff;

    // Corruption blocks
    for (int i = 0; i < 8; i++) {
      final x = nextUnit() * size.width;
      final y = nextUnit() * size.height;
      final w = 20 + nextUnit() * 100;
      final h = 2 + nextUnit() * 6;

      canvas.drawRect(
        Rect.fromLTWH(x, y, w, h),
        _rectPaint..color = NeonColors.red.withOpacity(0.1 + nextUnit() * 0.1),
      );
    }

    // Noise pixels
    for (int i = 0; i < 30; i++) {
      final x = nextUnit() * size.width;
      final y = nextUnit() * size.height;

      canvas.drawRect(
        Rect.fromLTWH(x, y, 2, 2),
        _noisePaint..color = Colors.white.withOpacity(0.1 + nextUnit() * 0.2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CorruptionPainter oldDelegate) =>
      oldDelegate.frame != frame;
}

class _GlitchBarsPainter extends CustomPainter {
  final double offset;
  final int frame;

  _GlitchBarsPainter({required this.offset, required this.frame});

  static final Paint _barPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    int rngState = frame ^ 0x9e3779b9;
    int lcgNext() {
      rngState = (1664525 * rngState + 1013904223) & 0x7fffffff;
      return rngState;
    }
    double nextUnit() => lcgNext() / 0x7fffffff;
    bool nextBool() => (lcgNext() & 1) == 0;

    for (int i = 0; i < 6; i++) {
      final y = nextUnit() * size.height;
      final height = 1.0 + nextUnit() * 4;
      final xShift = (nextUnit() - 0.5) * 30;
      final color = nextBool() ? NeonColors.cyan : NeonColors.red;

      canvas.drawRect(
        Rect.fromLTWH(xShift, y, size.width, height),
        _barPaint..color = color.withOpacity(0.15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlitchBarsPainter oldDelegate) =>
      oldDelegate.offset != offset || oldDelegate.frame != frame;
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedWarningIcon extends StatelessWidget {
  final AnimationController controller;
  final bool showGlitch;

  const _AnimatedWarningIcon({
    required this.controller,
    required this.showGlitch,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final scale = 1.0 + controller.value * 0.1;
        final opacity = 0.7 + controller.value * 0.3;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: NeonColors.red.withOpacity(opacity),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: NeonColors.red.withOpacity(0.3 + controller.value * 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '!',
                style: TextStyle(
                  color: NeonColors.red.withOpacity(opacity),
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  shadows: [
                    Shadow(color: NeonColors.red, blurRadius: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlitchTitle extends StatelessWidget {
  final String text;
  final bool showGlitch;
  final double glitchOffset;
  final bool showHeavyGlitch;

  const _GlitchTitle({
    required this.text,
    required this.showGlitch,
    required this.glitchOffset,
    required this.showHeavyGlitch,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Cyan layer (chromatic aberration)
        if (showGlitch)
          Transform.translate(
            offset: Offset(-glitchOffset * 0.7, showHeavyGlitch ? -2 : 0),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: NeonColors.cyan.withOpacity(showHeavyGlitch ? 0.8 : 0.5),
                fontFamily: 'monospace',
                letterSpacing: 6,
              ),
            ),
          ),

        // Red layer (chromatic aberration)
        if (showGlitch)
          Transform.translate(
            offset: Offset(glitchOffset * 0.7, showHeavyGlitch ? 2 : 0),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: NeonColors.magenta.withOpacity(showHeavyGlitch ? 0.8 : 0.5),
                fontFamily: 'monospace',
                letterSpacing: 6,
              ),
            ),
          ),

        // Main text
        Text(
          showHeavyGlitch ? _corruptText(text) : text,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: NeonColors.red,
            fontFamily: 'monospace',
            letterSpacing: 6,
            shadows: [
              Shadow(color: NeonColors.red, blurRadius: 20),
              Shadow(color: NeonColors.red.withOpacity(0.5), blurRadius: 40),
              Shadow(color: NeonColors.orange.withOpacity(0.3), blurRadius: 60),
            ],
          ),
        ),
      ],
    );
  }

  String _corruptText(String input) {
    final glitchChars = ['#', '@', '!', '%', '&', '*', '?'];
    int rngState = (input.hashCode ^ 0x9e3779b9) & 0x7fffffff;
    int lcgNext() {
      rngState = (1664525 * rngState + 1013904223) & 0x7fffffff;
      return rngState;
    }
    double nextUnit() => lcgNext() / 0x7fffffff;
    int nextInt(int max) => max <= 0 ? 0 : lcgNext() % max;
    final chars = input.split('');

    for (int i = 0; i < chars.length; i++) {
      if (nextUnit() < 0.2) {
        chars[i] = glitchChars[nextInt(glitchChars.length)];
      }
    }
    return chars.join();
  }
}

class _BreachMessage extends StatelessWidget {
  final AnimationController controller;
  final bool showGlitch;

  const _BreachMessage({
    required this.controller,
    required this.showGlitch,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        const fullText = '>>> SYSTEM BREACH DETECTED <<<';
        final visibleChars = (fullText.length * controller.value).floor();
        var visibleText = fullText.substring(0, visibleChars);
        final cursor = controller.value < 1 ? '█' : '';

        // Add error prefix
        final errorText = controller.value > 0.3 ? 'ERROR: ' : '';

        return Column(
          children: [
            Text(
              '$errorText$visibleText$cursor',
              style: TextStyle(
                color: NeonColors.red.withOpacity(0.9),
                fontSize: 13,
                fontFamily: 'monospace',
                letterSpacing: 2,
                shadows: [Shadow(color: NeonColors.red, blurRadius: 8)],
              ),
            ),
            if (controller.value > 0.7)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'DEFENSIVE SYSTEMS OFFLINE',
                  style: TextStyle(
                    color: NeonColors.orange.withOpacity(0.7),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ErrorStat {
  final String label;
  final String value;
  final Color color;

  _ErrorStat(this.label, this.value, this.color);
}

class _ErrorStatsPanel extends StatelessWidget {
  final List<_ErrorStat> stats;
  final AnimationController pulseController;
  final bool showGlitch;

  const _ErrorStatsPanel({
    required this.stats,
    required this.pulseController,
    required this.showGlitch,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            border: Border.all(
              color: NeonColors.red.withOpacity(0.3 + pulseController.value * 0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: NeonColors.red.withOpacity(0.1 + pulseController.value * 0.1),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Column(
            children: [
              // Error header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: NeonColors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  '⚠ MISSION REPORT ⚠',
                  style: TextStyle(
                    color: NeonColors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Stats
              ...stats.map((stat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _ErrorStatRow(
                  label: stat.label,
                  value: stat.value,
                  color: stat.color,
                  showGlitch: showGlitch,
                ),
              )),

              // Separator line
              Container(
                height: 1,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      NeonColors.red.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorStatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool showGlitch;

  const _ErrorStatRow({
    required this.label,
    required this.value,
    required this.color,
    required this.showGlitch,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                boxShadow: [BoxShadow(color: color, blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontFamily: 'monospace',
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 2,
            shadows: [Shadow(color: color, blurRadius: 8)],
          ),
        ),
      ],
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String text;
  final Color color;
  final int delay;
  final AnimationController controller;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _DangerButton({
    required this.text,
    required this.color,
    required this.delay,
    required this.controller,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final delayedProgress = ((controller.value - delay / 1000) * 1.5).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, 40 * (1 - delayedProgress)),
          child: Opacity(
            opacity: delayedProgress,
            child: NeonButton(
              text: text,
              onPressed: onPressed,
              color: color,
              width: isPrimary ? 240 : 200,
            ),
          ),
        );
      },
    );
  }
}

class _WarningBorders extends StatelessWidget {
  final AnimationController pulseAnimation;
  final bool showGlitch;

  const _WarningBorders({
    required this.pulseAnimation,
    required this.showGlitch,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final opacity = 0.3 + pulseAnimation.value * 0.4;

        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: NeonColors.red.withOpacity(showGlitch ? opacity * 1.5 : opacity),
                  width: showGlitch ? 4 : 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MalfunctionCorner extends StatelessWidget {
  final double rotation;
  final AnimationController pulseController;
  final String message;

  const _MalfunctionCorner({
    required this.rotation,
    required this.pulseController,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        return Transform.rotate(
          angle: rotation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  children: [
                    // Corner bracket with glow
                    CustomPaint(
                      painter: _WarningCornerPainter(
                        opacity: 0.5 + pulseController.value * 0.5,
                      ),
                    ),
                    // Sparking effects
                    CustomPaint(
                      painter: _ElectricSparksPainter(
                        animation: pulseController.value,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Error message
              Transform.rotate(
                angle: -rotation, // Counter-rotate text to keep it readable
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    border: Border.all(
                      color: NeonColors.red.withOpacity(0.5 + pulseController.value * 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: NeonColors.red.withOpacity(0.9),
                      fontSize: 9,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(color: NeonColors.red, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WarningCornerPainter extends CustomPainter {
  final double opacity;

  _WarningCornerPainter({required this.opacity});

  static final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _trianglePaint = Paint()..style = PaintingStyle.fill;
  static final Paint _cornerGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _cornerCorePaint = Paint();
  static final Path _cornerPath = Path();
  static final Path _trianglePath = Path();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    _strokePaint
      ..color = NeonColors.red.withOpacity(opacity)
      ..strokeWidth = 3;

    _cornerPath
      ..reset()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.7, 0);

    canvas.drawPath(_cornerPath, _strokePaint);

    // Warning triangle
    _trianglePaint.color = NeonColors.red.withOpacity(opacity * 0.8);
    _trianglePath
      ..reset()
      ..moveTo(8, 20)
      ..lineTo(20, 8)
      ..lineTo(20, 20)
      ..close();
    canvas.drawPath(_trianglePath, _trianglePaint);

    // Corner dot
    canvas.drawCircle(
      const Offset(0, 0),
      4,
      _cornerGlowPaint..color = NeonColors.red,
    );
    canvas.drawCircle(
      const Offset(0, 0),
      2,
      _cornerCorePaint..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _WarningCornerPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

class _ScreenShatterPainter extends CustomPainter {
  final double animation;

  _ScreenShatterPainter({required this.animation});

  static final Paint _crackPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _fragmentPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || animation >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final currentRadius = maxRadius * animation;

    // Draw cracks expanding from center
    int rngState = 0x12345678;
    int lcgNext() {
      rngState = (1664525 * rngState + 1013904223) & 0x7fffffff;
      return rngState;
    }
    double nextUnit() => lcgNext() / 0x7fffffff;

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi + nextUnit() * 0.3;
      final endX = center.dx + math.cos(angle) * currentRadius;
      final endY = center.dy + math.sin(angle) * currentRadius;

      // Main crack
      _crackPaint.color = NeonColors.red.withOpacity(0.6 * (1 - animation));
      canvas.drawLine(center, Offset(endX, endY), _crackPaint);

      // Sub-cracks
      if (animation > 0.3) {
        final subAngle1 = angle + 0.3;
        final subAngle2 = angle - 0.3;
        final subLength = currentRadius * 0.4;
        final midX = center.dx + math.cos(angle) * (currentRadius * 0.6);
        final midY = center.dy + math.sin(angle) * (currentRadius * 0.6);

        _crackPaint.color = NeonColors.orange.withOpacity(0.4 * (1 - animation));
        canvas.drawLine(
          Offset(midX, midY),
          Offset(midX + math.cos(subAngle1) * subLength, midY + math.sin(subAngle1) * subLength),
          _crackPaint,
        );
        canvas.drawLine(
          Offset(midX, midY),
          Offset(midX + math.cos(subAngle2) * subLength, midY + math.sin(subAngle2) * subLength),
          _crackPaint,
        );
      }
    }

    // Dark energy seeping through
    if (animation > 0.5) {
      final seepProgress = (animation - 0.5) * 2;
      _fragmentPaint.color = const Color(0xFF2a0a0a).withOpacity(0.7 * seepProgress);
      canvas.drawCircle(center, currentRadius * 0.8, _fragmentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScreenShatterPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _ElectricSparksPainter extends CustomPainter {
  final double animation;

  _ElectricSparksPainter({required this.animation});

  static final Paint _sparkPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    int rngState = (animation * 1000).toInt() ^ 0xabcdef;
    int lcgNext() {
      rngState = (1664525 * rngState + 1013904223) & 0x7fffffff;
      return rngState;
    }
    double nextUnit() => lcgNext() / 0x7fffffff;

    // Electric sparks from corner
    for (int i = 0; i < 3; i++) {
      if (nextUnit() > 0.7) continue; // Random spark appearance

      final startX = nextUnit() * size.width * 0.3;
      final startY = nextUnit() * size.height * 0.3;
      final path = Path()..moveTo(startX, startY);

      // Jagged lightning path
      var currentX = startX;
      var currentY = startY;
      for (int j = 0; j < 4; j++) {
        currentX += (nextUnit() - 0.5) * 10;
        currentY += (nextUnit() - 0.5) * 10;
        path.lineTo(currentX, currentY);
      }

      _sparkPaint.color = NeonColors.yellow.withOpacity(0.6 + animation * 0.4);
      canvas.drawPath(path, _sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ElectricSparksPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
