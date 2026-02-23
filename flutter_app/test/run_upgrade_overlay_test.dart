import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/bored_games_game.dart';
import 'package:bored_games/src/models/upgrade_data.dart';
import 'package:bored_games/src/ui/overlays/run_upgrade_overlay.dart';
import 'package:bored_games/src/ui/widgets/epic_neon_button.dart';

class _TestGame extends BoredGamesGame {
  _TestGame(this._pending) : super();

  final List<RunUpgradeDefinition> _pending;
  String? selectedId;
  int closeCount = 0;
  int skipCount = 0;

  @override
  List<RunUpgradeDefinition> get pendingRunUpgrades =>
      List.unmodifiable(_pending);

  @override
  void selectRunUpgrade(String id) {
    selectedId = id;
  }

  @override
  void closeRunUpgradeOverlay() {
    closeCount++;
  }

  @override
  void skipRunUpgrade() {
    skipCount++;
  }
}

void main() {
  testWidgets('RunUpgradeOverlay triggers game callbacks', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final upgrades = [
      const RunUpgradeDefinition(
        id: 'alpha',
        name: 'Alpha Upgrade',
        description: 'Boost alpha output.',
        stats: UpgradeStats(),
      ),
      const RunUpgradeDefinition(
        id: 'beta',
        name: 'Beta Upgrade',
        description: 'Boost beta output.',
        stats: UpgradeStats(),
      ),
    ];
    final game = _TestGame(upgrades);

    await tester.pumpWidget(
      MaterialApp(
        home: RunUpgradeOverlay(game: game),
      ),
    );

    // Let entrance animations build interactable widgets.
    await tester.pump(const Duration(milliseconds: 900));

    // Select first upgrade through the visible CTA.
    await tester.tap(find.widgetWithText(EpicNeonButton, 'ACTIVATE').first);
    await tester.pump();
    expect(game.selectedId, 'alpha');

    await tester.tap(find.widgetWithText(EpicNeonButton, 'CLOSE'));
    await tester.pump();
    expect(game.closeCount, 1);

    await tester.tap(find.widgetWithText(EpicNeonButton, 'SKIP'));
    await tester.pump();
    expect(game.skipCount, 1);
  });
}
