import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../widgets/epic_neon_title.dart';
import '../widgets/tron_button.dart';

class PauseMenuOverlay extends StatefulWidget {
  const PauseMenuOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  @override
  State<PauseMenuOverlay> createState() => _PauseMenuOverlayState();
}

class _PauseMenuOverlayState extends State<PauseMenuOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _ambientController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _ambientController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    )..repeat();

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Container(
            color: Colors.black.withOpacity(0.85 * _fadeAnimation.value),
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _fadeController,
                    curve: Curves.easeOutCubic,
                  )),
                  child: _EpicPauseContainer(
                    ambientController: _ambientController,
                    onResume: widget.onResume,
                    onRestart: widget.onRestart,
                    onQuit: widget.onQuit,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EpicPauseContainer extends StatelessWidget {
  const _EpicPauseContainer({
    required this.ambientController,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  final AnimationController ambientController;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambientController,
      builder: (context, child) {
        final pulse = math.sin(ambientController.value * 2 * math.pi) * 0.5 + 0.5;

        return Container(
          width: 380,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: NeonColors.darkBg.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: NeonColors.cyan.withOpacity(0.6 + pulse * 0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: NeonColors.cyan.withOpacity(0.3 + pulse * 0.2),
                blurRadius: 30 + pulse * 15,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: NeonColors.magenta.withOpacity(0.15 + pulse * 0.1),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Epic decorative line above
              _DecorativeLine(
                color: NeonColors.cyan,
                progress: pulse,
              ),
              const SizedBox(height: 20),

              // Epic title
              const EpicNeonTitle(
                text: 'PAUSED',
                fontSize: 42,
                primaryColor: NeonColors.cyan,
                secondaryColor: NeonColors.magenta,
              ),

              const SizedBox(height: 12),

              // Subtitle
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    NeonColors.cyan,
                    NeonColors.magenta,
                    NeonColors.cyan,
                  ],
                  stops: [0.0, pulse, 1.0],
                ).createShader(bounds),
                child: Text(
                  'SIMULATION SUSPENDED',
                  style: NeonTextStyles.small.copyWith(
                    color: Colors.white,
                    letterSpacing: 3,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Epic decorative line below
              _DecorativeLine(
                color: NeonColors.magenta,
                progress: 1.0 - pulse,
              ),

              const SizedBox(height: 32),

              // Buttons
              TronButton(
                text: 'RESUME',
                icon: Icons.play_arrow_rounded,
                onPressed: onResume,
                color: NeonColors.green,
                width: 300,
                height: 56,
                delay: const Duration(milliseconds: 100),
              ),
              const SizedBox(height: 16),

              TronButton(
                text: 'RESTART',
                icon: Icons.refresh_rounded,
                onPressed: onRestart,
                color: NeonColors.yellow,
                width: 300,
                height: 56,
                delay: const Duration(milliseconds: 150),
              ),
              const SizedBox(height: 16),

              TronButton(
                text: 'QUIT TO MENU',
                icon: Icons.exit_to_app_rounded,
                onPressed: onQuit,
                color: NeonColors.red,
                width: 300,
                height: 56,
                delay: const Duration(milliseconds: 200),
              ),

              const SizedBox(height: 24),

              // Epic corner indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CornerIndicator(
                    pulse: pulse,
                    side: 'LEFT',
                  ),
                  _CornerIndicator(
                    pulse: 1.0 - pulse,
                    side: 'RIGHT',
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

class _DecorativeLine extends StatelessWidget {
  const _DecorativeLine({
    required this.color,
    required this.progress,
  });

  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 16,
      child: CustomPaint(
        painter: _DecorativeLinePainter(
          color: color,
          progress: progress,
        ),
      ),
    );
  }
}

class _DecorativeLinePainter extends CustomPainter {
  _DecorativeLinePainter({
    required this.color,
    required this.progress,
  });

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;

    // Main line
    final linePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      linePaint,
    );

    // Glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      glowPaint,
    );

    // Center diamond
    final diamondSize = 6.0 + progress * 3;
    final diamondPaint = Paint()..color = color.withOpacity(0.9);

    final path = Path()
      ..moveTo(center, size.height / 2 - diamondSize)
      ..lineTo(center + diamondSize, size.height / 2)
      ..lineTo(center, size.height / 2 + diamondSize)
      ..lineTo(center - diamondSize, size.height / 2)
      ..close();
    canvas.drawPath(path, diamondPaint);

    // End dots
    final dotPaint = Paint()..color = color.withOpacity(0.7);
    canvas.drawCircle(Offset(0, size.height / 2), 3, dotPaint);
    canvas.drawCircle(Offset(size.width, size.height / 2), 3, dotPaint);
  }

  @override
  bool shouldRepaint(_DecorativeLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CornerIndicator extends StatelessWidget {
  const _CornerIndicator({
    required this.pulse,
    required this.side,
  });

  final double pulse;
  final String side;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          side == 'LEFT' ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (side == 'LEFT') ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: NeonColors.cyan.withOpacity(0.7 + pulse * 0.3),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: NeonColors.cyan.withOpacity(0.5 + pulse * 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              side,
              style: NeonTextStyles.small.copyWith(
                color: NeonColors.cyan.withOpacity(0.6),
                letterSpacing: 2,
                fontSize: 10,
              ),
            ),
            if (side == 'RIGHT') ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: NeonColors.magenta.withOpacity(0.7 + pulse * 0.3),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: NeonColors.magenta.withOpacity(0.5 + pulse * 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: 50,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: side == 'LEFT' ? Alignment.centerLeft : Alignment.centerRight,
              end: side == 'LEFT' ? Alignment.centerRight : Alignment.centerLeft,
              colors: [
                (side == 'LEFT' ? NeonColors.cyan : NeonColors.magenta)
                    .withOpacity(0.7 + pulse * 0.3),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
