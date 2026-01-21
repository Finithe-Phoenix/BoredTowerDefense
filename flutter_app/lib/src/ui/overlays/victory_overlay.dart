import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../widgets/neon_button.dart';

class VictoryOverlay extends StatefulWidget {
  const VictoryOverlay({
    super.key,
    required this.score,
    required this.livesRemaining,
    required this.maxLives,
    required this.onNextLevel,
    required this.onRestart,
    required this.onQuit,
  });

  final int score;
  final int livesRemaining;
  final int maxLives;
  final VoidCallback onNextLevel;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _glitchController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  final _random = math.Random();
  double _glitchOffset = 0;
  bool _showGlitch = false;
  Timer? _glitchTimer;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..addListener(() {
      if (_random.nextDouble() < 0.3) {
        setState(() {
          _showGlitch = true;
          _glitchOffset = (_random.nextDouble() - 0.5) * 10;
        });
      } else {
        setState(() => _showGlitch = false);
      }
    });

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Trigger glitch periodically
    _glitchTimer = Timer(const Duration(milliseconds: 500), _triggerGlitchCycle);

    _scaleAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.elasticOut,
    );

    _slideAnimation = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );
  }

  void _triggerGlitchCycle() {
    if (!mounted) return;
    _glitchController.forward(from: 0).then((_) {
      if (mounted) {
        _glitchTimer?.cancel();
        _glitchTimer = Timer(
          Duration(milliseconds: 2000 + _random.nextInt(3000)),
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
    super.dispose();
  }

  int get _stars {
    if (widget.livesRemaining == widget.maxLives) return 3;
    if (widget.livesRemaining >= widget.maxLives * 0.75) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  const Color(0xFF001a0a).withOpacity(0.95),
                  const Color(0xFF000a05).withOpacity(0.98),
                  Colors.black.withOpacity(0.99),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated grid background
                CustomPaint(
                  painter: _TronGridPainter(
                    animation: _pulseController.value,
                    color: NeonColors.green,
                  ),
                  size: Size.infinite,
                ),

                // Scanlines
                CustomPaint(
                  painter: _ScanlinesPainter(
                    animation: _mainController.value,
                  ),
                  size: Size.infinite,
                ),

                // Main content
                Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_showGlitch ? _glitchOffset : 0, _slideAnimation.value),
                          child: child,
                        );
                      },
                      child: _buildContent(),
                    ),
                  ),
                ),

                // Corner decorations
                ..._buildCornerDecorations(),

                // Glitch overlay
                if (_showGlitch) _buildGlitchOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      margin: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Victory title with glitch effect
          _GlitchText(
            text: 'VICTORY',
            fontSize: 56,
            color: NeonColors.green,
            showGlitch: _showGlitch,
            glitchOffset: _glitchOffset,
          ),

          const SizedBox(height: 8),

          // Subtitle with typing effect
          _AnimatedSubtitle(
            text: '>>> SYSTEM SECURED <<<',
            color: NeonColors.cyan,
            controller: _mainController,
          ),

          const SizedBox(height: 30),

          // Hexagonal container for stars
          _HexagonalStarsContainer(
            stars: _stars,
            pulseAnimation: _pulseController,
          ),

          const SizedBox(height: 30),

          // Stats panel with cyber frame
          _CyberStatsPanel(
            stats: [
              _StatData('FINAL SCORE', '${widget.score}', NeonColors.cyan),
              _StatData('LIVES REMAINING', '${widget.livesRemaining}/${widget.maxLives}', NeonColors.green),
              _StatData('RATING', '${'★' * _stars}${'☆' * (3 - _stars)}', NeonColors.yellow),
            ],
            borderColor: NeonColors.green,
            pulseController: _pulseController,
          ),

          const SizedBox(height: 30),

          // Buttons with staggered animation
          _AnimatedButton(
            text: 'NEXT LEVEL',
            color: NeonColors.cyan,
            delay: 0,
            controller: _mainController,
            onPressed: widget.onNextLevel,
            isPrimary: true,
          ),
          const SizedBox(height: 12),
          _AnimatedButton(
            text: 'PLAY AGAIN',
            color: NeonColors.green,
            delay: 100,
            controller: _mainController,
            onPressed: widget.onRestart,
          ),
          const SizedBox(height: 12),
          _AnimatedButton(
            text: 'QUIT TO MENU',
            color: NeonColors.magenta,
            delay: 200,
            controller: _mainController,
            onPressed: widget.onQuit,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerDecorations() {
    return [
      Positioned(
        top: 20,
        left: 20,
        child: _CornerDecoration(color: NeonColors.green, rotation: 0),
      ),
      Positioned(
        top: 20,
        right: 20,
        child: _CornerDecoration(color: NeonColors.green, rotation: math.pi / 2),
      ),
      Positioned(
        bottom: 20,
        left: 20,
        child: _CornerDecoration(color: NeonColors.green, rotation: -math.pi / 2),
      ),
      Positioned(
        bottom: 20,
        right: 20,
        child: _CornerDecoration(color: NeonColors.green, rotation: math.pi),
      ),
    ];
  }

  Widget _buildGlitchOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _GlitchOverlayPainter(
            offset: _glitchOffset,
            color: NeonColors.cyan,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════

class _TronGridPainter extends CustomPainter {
  final double animation;
  final Color color;

  _TronGridPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.05 + animation * 0.03)
      ..strokeWidth = 1;

    const spacing = 40.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      final opacity = 0.03 + (math.sin(x * 0.01 + animation * math.pi * 2) * 0.02);
      paint.color = color.withOpacity(opacity.clamp(0.01, 0.1));
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      final opacity = 0.03 + (math.sin(y * 0.01 + animation * math.pi * 2) * 0.02);
      paint.color = color.withOpacity(opacity.clamp(0.01, 0.1));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Center glow
    final centerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.1 + animation * 0.05),
          color.withOpacity(0),
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.8,
        height: size.height * 0.8,
      ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), centerGlow);
  }

  @override
  bool shouldRepaint(covariant _TronGridPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _ScanlinesPainter extends CustomPainter {
  final double animation;

  _ScanlinesPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.03);

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Moving scanline
    final scanY = (animation * size.height * 2) % size.height;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0),
          Colors.white.withOpacity(0.03),
          Colors.white.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 20, size.width, 40));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 20, size.width, 40), scanPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanlinesPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _GlitchOverlayPainter extends CustomPainter {
  final double offset;
  final Color color;

  _GlitchOverlayPainter({required this.offset, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);

    for (int i = 0; i < 5; i++) {
      final y = random.nextDouble() * size.height;
      final height = 2.0 + random.nextDouble() * 8;
      final xOffset = (random.nextDouble() - 0.5) * 20;

      canvas.drawRect(
        Rect.fromLTWH(xOffset, y, size.width, height),
        Paint()..color = color.withOpacity(0.1),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlitchOverlayPainter oldDelegate) =>
      oldDelegate.offset != offset;
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _GlitchText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final bool showGlitch;
  final double glitchOffset;

  const _GlitchText({
    required this.text,
    required this.fontSize,
    required this.color,
    required this.showGlitch,
    required this.glitchOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Cyan offset layer (glitch)
        if (showGlitch)
          Transform.translate(
            offset: Offset(-glitchOffset * 0.5, 0),
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: NeonColors.cyan.withOpacity(0.7),
                fontFamily: 'monospace',
                letterSpacing: 8,
              ),
            ),
          ),

        // Red offset layer (glitch)
        if (showGlitch)
          Transform.translate(
            offset: Offset(glitchOffset * 0.5, 0),
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: NeonColors.magenta.withOpacity(0.7),
                fontFamily: 'monospace',
                letterSpacing: 8,
              ),
            ),
          ),

        // Main text
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: color,
            fontFamily: 'monospace',
            letterSpacing: 8,
            shadows: [
              Shadow(color: color, blurRadius: 20),
              Shadow(color: color.withOpacity(0.5), blurRadius: 40),
              Shadow(color: Colors.white.withOpacity(0.3), blurRadius: 2),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedSubtitle extends StatelessWidget {
  final String text;
  final Color color;
  final AnimationController controller;

  const _AnimatedSubtitle({
    required this.text,
    required this.color,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final visibleChars = (text.length * controller.value).floor();
        final visibleText = text.substring(0, visibleChars);
        final cursor = controller.value < 1 ? '█' : '';

        return Text(
          '$visibleText$cursor',
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 14,
            fontFamily: 'monospace',
            letterSpacing: 3,
            shadows: [Shadow(color: color, blurRadius: 10)],
          ),
        );
      },
    );
  }
}

class _HexagonalStarsContainer extends StatelessWidget {
  final int stars;
  final AnimationController pulseAnimation;

  const _HexagonalStarsContainer({
    required this.stars,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          decoration: BoxDecoration(
            border: Border.all(
              color: NeonColors.yellow.withOpacity(0.3 + pulseAnimation.value * 0.2),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: NeonColors.yellow.withOpacity(0.1 + pulseAnimation.value * 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final earned = i < stars;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: earned ? 1.0 : 0.2),
                duration: Duration(milliseconds: 500 + i * 300),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  final safeValue = value.isFinite ? value : 0.0;
                  final clampedValue = safeValue.clamp(0.0, 1.0).toDouble();
                  final glowOpacity = (clampedValue * 0.8).clamp(0.0, 1.0).toDouble();
                  final flareOpacity = (clampedValue * 0.5).clamp(0.0, 1.0).toDouble();
                  final scaleValue = earned ? 0.5 + clampedValue * 0.7 : 1.0;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Transform.scale(
                      scale: scaleValue,
                      child: Icon(
                        earned ? Icons.star : Icons.star_border,
                        color: NeonColors.yellow.withOpacity(earned ? clampedValue : 0.2),
                        size: 52,
                        shadows: earned
                            ? [
                                Shadow(
                                  color: NeonColors.yellow.withOpacity(glowOpacity),
                                  blurRadius: 25,
                                ),
                                Shadow(
                                  color: NeonColors.orange.withOpacity(flareOpacity),
                                  blurRadius: 40,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        );
      },
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final Color color;

  _StatData(this.label, this.value, this.color);
}

class _CyberStatsPanel extends StatelessWidget {
  final List<_StatData> stats;
  final Color borderColor;
  final AnimationController pulseController;

  const _CyberStatsPanel({
    required this.stats,
    required this.borderColor,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            border: Border.all(
              color: borderColor.withOpacity(0.4 + pulseController.value * 0.2),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header line
              Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      borderColor.withOpacity(0.5),
                      borderColor,
                      borderColor.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              ...stats.map((stat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _CyberStatRow(
                  label: stat.label,
                  value: stat.value,
                  color: stat.color,
                ),
              )),

              // Footer line
              Container(
                height: 2,
                margin: const EdgeInsets.only(top: 15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      borderColor.withOpacity(0.5),
                      borderColor,
                      borderColor.withOpacity(0.5),
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

class _CyberStatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CyberStatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                boxShadow: [
                  BoxShadow(color: color, blurRadius: 8),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 2,
            shadows: [
              Shadow(color: color, blurRadius: 10),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedButton extends StatelessWidget {
  final String text;
  final Color color;
  final int delay;
  final AnimationController controller;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _AnimatedButton({
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
        final delayedProgress = ((controller.value - delay / 1000) * 2).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, 30 * (1 - delayedProgress)),
          child: Opacity(
            opacity: delayedProgress,
            child: NeonButton(
              text: text,
              onPressed: onPressed,
              color: color,
              width: isPrimary ? 220 : 200,
            ),
          ),
        );
      },
    );
  }
}

class _CornerDecoration extends StatelessWidget {
  final Color color;
  final double rotation;

  const _CornerDecoration({
    required this.color,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: SizedBox(
        width: 40,
        height: 40,
        child: CustomPaint(
          painter: _CornerPainter(color: color),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;

  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.6, 0);

    canvas.drawPath(path, paint);

    // Corner dot
    canvas.drawCircle(
      const Offset(0, 0),
      3,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
