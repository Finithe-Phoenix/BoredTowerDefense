import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:bored_games/src/game/bored_games_game.dart';

/// Lightweight BoredGamesGame double used to mount HUD components in tests
/// without running the full game bootstrap.
class HudTestGame extends BoredGamesGame {
  HudTestGame({Vector2? mockSize})
      : _mockSize = mockSize ?? Vector2(1920, 1080),
        super();

  final Vector2 _mockSize;

  bool mockHideHud = false;
  bool mockFocusModeActive = false;
  bool mockReduceFx = false;
  bool mockIsTouchLayout = false;

  int mockGold = 300;
  bool mockPulseReady = true;
  bool mockMineReady = true;
  double mockPulseCooldownPercent = 0.0;
  double mockMineCooldownPercent = 0.0;
  int mockPulseCost = 30;
  int mockMineCost = 20;
  int mockActiveMineCount = 1;
  int mockMaxActiveMines = 5;
  int mockFpsUsesTotal = 0;
  int mockMaxFpsUsesMatch = 3;
  PendingAbility mockPendingAbility = PendingAbility.none;

  int pulseActivations = 0;
  int mineDeployments = 0;

  @override
  Future<void> onLoad() async {}

  @override
  void update(double dt) {}

  @override
  Vector2 get size => _mockSize;

  @override
  Color backgroundColor() => Colors.black;

  @override
  bool get hideHud => mockHideHud;

  @override
  set hideHud(bool value) => mockHideHud = value;

  @override
  bool get focusModeActive => mockFocusModeActive;

  @override
  bool get reduceFx => mockReduceFx;

  @override
  bool get isTouchLayout => mockIsTouchLayout;

  @override
  int get gold => mockGold;

  @override
  set gold(int value) => mockGold = value;

  @override
  bool get pulseReady => mockPulseReady;

  @override
  bool get mineReady => mockMineReady;

  @override
  double get pulseCooldownPercent => mockPulseCooldownPercent;

  @override
  double get mineCooldownPercent => mockMineCooldownPercent;

  @override
  int get pulseCost => mockPulseCost;

  @override
  int get mineCost => mockMineCost;

  @override
  int get activeMineCount => mockActiveMineCount;

  @override
  int get maxActiveMines => mockMaxActiveMines;

  @override
  int get fpsUsesTotal => mockFpsUsesTotal;

  @override
  int get maxFpsUsesMatch => mockMaxFpsUsesMatch;

  @override
  PendingAbility get pendingAbility => mockPendingAbility;

  @override
  void activateNeonPulse({Vector2? targetWorld}) {
    pulseActivations++;
  }

  @override
  void deployMine({Vector2? targetWorld}) {
    mineDeployments++;
  }
}
