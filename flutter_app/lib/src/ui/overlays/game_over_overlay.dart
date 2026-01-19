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
  late Animation<double> _fadeAnimation;

  final _random = math.Random();
  double _glitchOffset = 0;
  double _verticalGlitch = 0;
  bool _showGlitch = false;
  bool _showHeavyGlitch = false;
  int _glitchFrame = 0;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

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

    // Start aggressive glitch cycle
    Future.delayed(const Duration(milliseconds: 200), _triggerGlitchCycle);

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    );
  }

  void _updateGlitch() {
    if (_random.nextDouble() < 0.5) {
      setState(() {
        _showGlitch = true;
        _glitchOffset = (_random.nextDouble() - 0.5) * 15;
        _verticalGlitch = (_random.nextDouble() - 0.5) * 5;
        _glitchFrame = _random.nextInt(100);
        _showHeavyGlitch = _random.nextDouble() < 0.3;
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
        Future.delayed(
          Duration(milliseconds: 800 + _random.nextInt(1500)),
          _triggerGlitchCycle,
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glitchController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
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
        child: _WarningCorner(
          rotation: 0,
          pulseController: _pulseController,
        ),
      ),
      Positioned(
        top: 30,
        right: 30,
        child: _WarningCorner(
          rotation: math.pi / 2,
          pulseController: _pulseController,
        ),
      ),
      Positioned(
        bottom: 30,
        left: 30,
        child: _WarningCorner(
          rotation: -math.pi / 2,
          pulseController: _pulseController,
        ),
      ),
      Positioned(
        bottom: 30,
        right: 30,
        child: _WarningCorner(
          rotation: math.pi,
          pulseController: _pulseController,
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

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1;
    const spacing = 50.0;

    // Vertical lines with danger pulse
    for (double x = 0; x < size.width; x += spacing) {
      final distFromCenter = (x - size.width / 2).abs() / (size.width / 2);
      final pulse = 0.02 + math.sin(animation * math.pi * 2 + x * 0.01) * 0.02;
      final opacity = (pulse * (1 - distFromCenter * 0.5)).clamp(0.01, 0.08);

      paint.color = NeonColors.red.withOpacity(opacity);
      canvas.drawLine(
        Offset(x + glitchOffset * 0.1, 0),
        Offset(x + glitchOffset * 0.1, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      final pulse = 0.02 + math.sin(animation * math.pi * 2 + y * 0.01) * 0.02;
      paint.color = NeonColors.red.withOpacity(pulse.clamp(0.01, 0.06));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Center danger glow
    final centerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          NeonColors.red.withOpacity(0.15 + animation * 0.1),
          NeonColors.red.withOpacity(0),
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.6,
        height: size.height * 0.6,
      ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), centerGlow);
  }

  @override
  bool shouldRepaint(covariant _DangerGridPainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.glitchOffset != glitchOffset;
}

class _DangerScanlinesPainter extends CustomPainter {
  final double animation;
  final double intensity;

  _DangerScanlinesPainter({required this.animation, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    // Static scanlines
    final paint = Paint()..color = Colors.black.withOpacity(0.05 * intensity);
    for (double y = 0; y < size.height; y += 2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Moving danger scanline
    final scanY = (animation * size.height * 1.5) % size.height;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          NeonColors.red.withOpacity(0),
          NeonColors.red.withOpacity(0.1 * intensity),
          NeonColors.red.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 30, size.width, 60));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 30, size.width, 60), scanPaint);
  }

  @override
  bool shouldRepaint(covariant _DangerScanlinesPainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.intensity != intensity;
}

class _CorruptionPainter extends CustomPainter {
  final int frame;

  _CorruptionPainter({required this.frame});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(frame);

    // Corruption blocks
    for (int i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final w = 20 + random.nextDouble() * 100;
      final h = 2 + random.nextDouble() * 6;

      canvas.drawRect(
        Rect.fromLTWH(x, y, w, h),
        Paint()..color = NeonColors.red.withOpacity(0.1 + random.nextDouble() * 0.1),
      );
    }

    // Noise pixels
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      canvas.drawRect(
        Rect.fromLTWH(x, y, 2, 2),
        Paint()..color = Colors.white.withOpacity(0.1 + random.nextDouble() * 0.2),
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

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(frame);

    for (int i = 0; i < 6; i++) {
      final y = random.nextDouble() * size.height;
      final height = 1.0 + random.nextDouble() * 4;
      final xShift = (random.nextDouble() - 0.5) * 30;
      final color = random.nextBool() ? NeonColors.cyan : NeonColors.red;

      canvas.drawRect(
        Rect.fromLTWH(xShift, y, size.width, height),
        Paint()..color = color.withOpacity(0.15),
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
    final random = math.Random();
    final chars = input.split('');

    for (int i = 0; i < chars.length; i++) {
      if (random.nextDouble() < 0.2) {
        chars[i] = glitchChars[random.nextInt(glitchChars.length)];
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

class _WarningCorner extends StatelessWidget {
  final double rotation;
  final AnimationController pulseController;

  const _WarningCorner({
    required this.rotation,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        return Transform.rotate(
          angle: rotation,
          child: SizedBox(
            width: 50,
            height: 50,
            child: CustomPaint(
              painter: _WarningCornerPainter(
                opacity: 0.5 + pulseController.value * 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WarningCornerPainter extends CustomPainter {
  final double opacity;

  _WarningCornerPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NeonColors.red.withOpacity(opacity)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.7, 0);

    canvas.drawPath(path, paint);

    // Warning triangle
    final trianglePaint = Paint()
      ..color = NeonColors.red.withOpacity(opacity * 0.8)
      ..style = PaintingStyle.fill;

    final triangle = Path()
      ..moveTo(8, 20)
      ..lineTo(20, 8)
      ..lineTo(20, 20)
      ..close();

    canvas.drawPath(triangle, trianglePaint);

    // Corner dot
    canvas.drawCircle(
      const Offset(0, 0),
      4,
      Paint()
        ..color = NeonColors.red
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      const Offset(0, 0),
      2,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _WarningCornerPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
