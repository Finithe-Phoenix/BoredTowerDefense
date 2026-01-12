import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../widgets/neon_button.dart';
import '../widgets/neon_title.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: NeonColors.darkBg.withOpacity(0.9),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: NeonColors.darkBg,
                border: Border.all(color: NeonColors.green, width: 2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: NeonColors.green.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const NeonTitle(
                    text: 'VICTORY',
                    fontSize: 48,
                    color: NeonColors.green,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'SYSTEM SECURED',
                    style: NeonTextStyles.subtitle.copyWith(
                      color: NeonColors.green.withOpacity(0.7),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Stars
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final earned = i < _stars;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: earned ? 1.0 : 0.3),
                        duration: Duration(milliseconds: 300 + i * 200),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: earned ? 0.8 + value * 0.4 : 1.0,
                            child: Icon(
                              Icons.star,
                              color: NeonColors.yellow.withOpacity(value),
                              size: 48,
                              shadows: earned
                                  ? [
                                      Shadow(
                                        color: NeonColors.yellow.withOpacity(value * 0.8),
                                        blurRadius: 20,
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 30),

                  // Stats
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: NeonColors.green.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        _StatRow(
                          label: 'FINAL SCORE',
                          value: '${widget.score}',
                          color: NeonColors.cyan,
                        ),
                        const SizedBox(height: 10),
                        _StatRow(
                          label: 'LIVES REMAINING',
                          value: '${widget.livesRemaining}/${widget.maxLives}',
                          color: NeonColors.green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  NeonButton(
                    text: 'NEXT LEVEL',
                    onPressed: widget.onNextLevel,
                    color: NeonColors.cyan,
                    width: 200,
                  ),
                  const SizedBox(height: 12),

                  NeonButton(
                    text: 'PLAY AGAIN',
                    onPressed: widget.onRestart,
                    color: NeonColors.green,
                    width: 200,
                  ),
                  const SizedBox(height: 12),

                  NeonButton(
                    text: 'QUIT TO MENU',
                    onPressed: widget.onQuit,
                    color: NeonColors.magenta,
                    width: 200,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: NeonTextStyles.body.copyWith(
            color: NeonColors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 40),
        Text(
          value,
          style: NeonTextStyles.button.copyWith(
            color: color,
            shadows: [
              Shadow(color: color.withOpacity(0.5), blurRadius: 10),
            ],
          ),
        ),
      ],
    );
  }
}
