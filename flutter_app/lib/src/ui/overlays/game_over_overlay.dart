import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../widgets/neon_button.dart';
import '../widgets/neon_title.dart';

class GameOverOverlay extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: NeonColors.darkBg.withOpacity(0.9),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: NeonColors.darkBg,
              border: Border.all(color: NeonColors.red, width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: NeonColors.red.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const NeonTitle(
                  text: 'GAME OVER',
                  fontSize: 42,
                  color: NeonColors.red,
                ),
                const SizedBox(height: 10),
                Text(
                  'SYSTEM BREACH',
                  style: NeonTextStyles.subtitle.copyWith(
                    color: NeonColors.red.withOpacity(0.7),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 30),

                // Stats
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: NeonColors.red.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      _StatRow(
                        label: 'WAVES SURVIVED',
                        value: '$wavesCleared',
                        color: NeonColors.orange,
                      ),
                      const SizedBox(height: 10),
                      _StatRow(
                        label: 'FINAL SCORE',
                        value: '$score',
                        color: NeonColors.cyan,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                NeonButton(
                  text: 'TRY AGAIN',
                  onPressed: onRestart,
                  color: NeonColors.yellow,
                  width: 200,
                ),
                const SizedBox(height: 16),

                NeonButton(
                  text: 'QUIT TO MENU',
                  onPressed: onQuit,
                  color: NeonColors.red,
                  width: 200,
                ),
              ],
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
