import 'dart:ui';

import 'package:flutter/material.dart';
import '../../game/bored_games_game.dart';
import '../../models/upgrade_data.dart';
import '../theme/neon_theme.dart';
import '../widgets/epic_neon_button.dart';

class RunUpgradeOverlay extends StatelessWidget {
  const RunUpgradeOverlay({super.key, required this.game});

  final BoredGamesGame game;

  @override
  Widget build(BuildContext context) {
    final choices = game.pendingRunUpgrades;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        color: Colors.black.withOpacity(0.72),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 720;
              return Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'SELECT AN UPGRADE',
                    style: NeonTextStyles.title.copyWith(
                      fontSize: 28,
                      color: NeonColors.cyan,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tune the grid before the next wave.',
                    style: NeonTextStyles.small.copyWith(
                      color: NeonColors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: isWide ? 760 : double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children: choices
                              .map((upgrade) => _UpgradeChoiceCard(
                                    upgrade: upgrade,
                                    onSelect: () => game.selectRunUpgrade(upgrade.id),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: EpicNeonButton(
                      text: 'SKIP',
                      width: 160,
                      height: 40,
                      color: NeonColors.magenta,
                      onPressed: game.skipRunUpgrade,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UpgradeChoiceCard extends StatelessWidget {
  const _UpgradeChoiceCard({
    required this.upgrade,
    required this.onSelect,
  });

  final RunUpgradeDefinition upgrade;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NeonColors.darkBg.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NeonColors.cyan.withOpacity(0.6), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: NeonColors.cyan.withOpacity(0.2),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              upgrade.name,
              style: NeonTextStyles.subtitle.copyWith(
                fontSize: 16,
                color: NeonColors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              upgrade.description,
              style: NeonTextStyles.small.copyWith(
                color: NeonColors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            EpicNeonButton(
              text: 'LOCK IN',
              height: 34,
              width: 160,
              color: NeonColors.green,
              onPressed: onSelect,
            ),
          ],
        ),
      ),
    );
  }
}
