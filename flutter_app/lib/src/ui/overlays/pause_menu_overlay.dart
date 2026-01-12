import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../widgets/neon_button.dart';
import '../widgets/neon_title.dart';

class PauseMenuOverlay extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: NeonColors.darkBg.withOpacity(0.8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: NeonColors.darkBg,
              border: Border.all(color: NeonColors.cyan, width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: NeonColors.cyan.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const NeonTitle(
                  text: 'PAUSED',
                  fontSize: 36,
                  color: NeonColors.cyan,
                ),
                const SizedBox(height: 40),

                NeonButton(
                  text: 'RESUME',
                  onPressed: onResume,
                  color: NeonColors.green,
                  width: 200,
                ),
                const SizedBox(height: 16),

                NeonButton(
                  text: 'RESTART',
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
