import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/hud/ability_panel.dart';
import 'package:bored_games/src/game/bored_games_game.dart';

import 'helpers/hud_test_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mountPanel(
    WidgetTester tester,
    HudTestGame game,
    AbilityPanel panel,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: game.size.x,
          height: game.size.y,
          child: GameWidget(game: game),
        ),
      ),
    );
    await tester.pump();

    game.add(panel);
    await tester.pump();
  }

  void renderPanel(AbilityPanel panel) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    panel.render(canvas);
    recorder.endRecording();
  }

  Vector2 pulseTap(HudTestGame game) {
    final panelX = game.size.x - 200;
    final panelY = game.size.y - 140;
    return Vector2(
      panelX + 10 + AbilityPanel.abilitySize / 2,
      panelY + 10 + AbilityPanel.abilitySize / 2,
    );
  }

  Vector2 mineTap(HudTestGame game) {
    final panelX = game.size.x - 200;
    final panelY = game.size.y - 140;
    return Vector2(
      panelX + 10 + AbilityPanel.abilitySize + AbilityPanel.spacing + AbilityPanel.abilitySize / 2,
      panelY + 10 + AbilityPanel.abilitySize / 2,
    );
  }

  group('AbilityPanel render + interaction', () {
    testWidgets('activates pulse and mine when ready and affordable', (tester) async {
      final game = HudTestGame();
      final panel = AbilityPanel();

      await mountPanel(tester, game, panel);
      renderPanel(panel);

      expect(panel.handleTap(pulseTap(game)), isTrue);
      expect(game.pulseActivations, 1);
      expect(panel.handleTap(mineTap(game)), isTrue);
      expect(game.mineDeployments, 1);

      expect(panel.handleTap(Vector2(8, 8)), isFalse);
    });

    testWidgets('blocks taps when prerequisites are not met', (tester) async {
      final game = HudTestGame();
      final panel = AbilityPanel();

      await mountPanel(tester, game, panel);
      renderPanel(panel);

      game.mockGold = 0;
      expect(panel.handleTap(pulseTap(game)), isFalse);
      expect(panel.handleTap(mineTap(game)), isFalse);

      game.mockGold = 300;
      game.mockPulseReady = false;
      game.mockMineReady = false;
      expect(panel.handleTap(pulseTap(game)), isFalse);
      expect(panel.handleTap(mineTap(game)), isFalse);
    });

    testWidgets('respects HUD visibility and compact layout guards', (tester) async {
      final game = HudTestGame();
      final panel = AbilityPanel();
      await mountPanel(tester, game, panel);
      renderPanel(panel);

      game.hideHud = true;
      expect(panel.handleTap(pulseTap(game)), isFalse);

      game.hideHud = false;
      game.mockFocusModeActive = true;
      expect(panel.handleTap(pulseTap(game)), isFalse);

      game.mockFocusModeActive = false;
      game.mockIsTouchLayout = true;
      expect(panel.handleTap(pulseTap(game)), isFalse);

      final compactGame = HudTestGame(mockSize: Vector2(780, 1080));
      final compactPanel = AbilityPanel();
      await mountPanel(tester, compactGame, compactPanel);
      renderPanel(compactPanel);
      expect(compactPanel.handleTap(Vector2(730, 980)), isFalse);
    });

    testWidgets('renders cooldown, active, affordability and overdrive variants', (
      tester,
    ) async {
      final game = HudTestGame();
      final panel = AbilityPanel();
      await mountPanel(tester, game, panel);

      game.mockPulseReady = false;
      game.mockPulseCooldownPercent = 0.35;
      game.mockMineReady = false;
      game.mockMineCooldownPercent = 0.6;
      game.mockPendingAbility = PendingAbility.pulse;
      game.mockGold = 5;
      game.mockFpsUsesTotal = game.mockMaxFpsUsesMatch;
      panel.update(0.25);
      renderPanel(panel);

      game.mockPulseReady = true;
      game.mockMineReady = true;
      game.mockPendingAbility = PendingAbility.mine;
      game.mockGold = 600;
      game.mockActiveMineCount = 2;
      game.mockMaxActiveMines = 6;
      game.mockFpsUsesTotal = 0;
      panel.update(0.25);
      renderPanel(panel);

      game.mockReduceFx = true;
      renderPanel(panel);
    });

    testWidgets('releases cached resources on remove and can be rebuilt', (
      tester,
    ) async {
      final game = HudTestGame();
      final panel = AbilityPanel();
      await mountPanel(tester, game, panel);
      renderPanel(panel);

      panel.onRemove();
      panel.onRemove();

      final rebuilt = AbilityPanel();
      game.add(rebuilt);
      await tester.pump();
      renderPanel(rebuilt);
      expect(rebuilt.handleTap(pulseTap(game)), isTrue);
    });
  });
}
