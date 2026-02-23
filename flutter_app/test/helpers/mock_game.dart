import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'package:bored_games/src/game/bored_games_game.dart';
import 'package:bored_games/src/game/entities/tower.dart';
import 'package:bored_games/src/game/entities/enemy.dart';
import 'package:bored_games/src/models/quality_level.dart';
import 'package:bored_games/src/models/upgrade_data.dart';

/// Mock implementation of BoredGamesGame for testing HUD components
class MockBoredGamesGame extends FlameGame {
  MockBoredGamesGame({
    this.mockGold = 100,
    this.mockLives = 10,
    this.mockScore = 0,
    this.mockPulseReady = true,
    this.mockMineReady = true,
    this.mockPulseCooldownPercent = 0.0,
    this.mockMineCooldownPercent = 0.0,
    this.mockPulseCost = 30,
    this.mockMineCost = 20,
    this.mockActiveMineCount = 0,
    this.mockMaxActiveMines = 5,
    this.mockFpsUsesTotal = 0,
    this.mockMaxFpsUsesMatch = 3,
    this.mockPendingAbility = PendingAbility.none,
    this.mockHideHud = false,
    this.mockFocusModeActive = false,
    this.mockIsTouchLayout = false,
    this.mockQuality = QualityLevel.high,
    this.mockSellMode = false,
    this.mockFocusTower,
    this.mockFocusTarget,
    this.mockFocusFxPulse = 0.0,
    this.mockFocusModeTimer = 0.0,
    this.mockFocusModeMaxDuration = 10.0,
    this.mockReduceFx = false,
    this.mockAllowBlur = true,
    Vector2? mockSize,
  }) : _mockSize = mockSize ?? Vector2(1920, 1080);

  // Configurable mock values
  int mockGold;
  int mockLives;
  int mockScore;
  bool mockPulseReady;
  bool mockMineReady;
  double mockPulseCooldownPercent;
  double mockMineCooldownPercent;
  int mockPulseCost;
  int mockMineCost;
  int mockActiveMineCount;
  int mockMaxActiveMines;
  int mockFpsUsesTotal;
  int mockMaxFpsUsesMatch;
  PendingAbility mockPendingAbility;
  bool mockHideHud;
  bool mockFocusModeActive;
  bool mockIsTouchLayout;
  QualityLevel mockQuality;
  bool mockSellMode;
  Tower? mockFocusTower;
  Enemy? mockFocusTarget;
  double mockFocusFxPulse;
  double mockFocusModeTimer;
  double mockFocusModeMaxDuration;
  bool mockReduceFx;
  bool mockAllowBlur;
  final Vector2 _mockSize;

  // Callback trackers
  bool pulseActivated = false;
  bool mineDeployed = false;
  int sellTowerCallCount = 0;

  // Implement getters that HUD components use
  int get gold => mockGold;
  int get lives => mockLives;
  int get score => mockScore;
  bool get pulseReady => mockPulseReady;
  bool get mineReady => mockMineReady;
  double get pulseCooldownPercent => mockPulseCooldownPercent;
  double get mineCooldownPercent => mockMineCooldownPercent;
  int get pulseCost => mockPulseCost;
  int get mineCost => mockMineCost;
  int get activeMineCount => mockActiveMineCount;
  int get maxActiveMines => mockMaxActiveMines;
  int get fpsUsesTotal => mockFpsUsesTotal;
  int get maxFpsUsesMatch => mockMaxFpsUsesMatch;
  PendingAbility get pendingAbility => mockPendingAbility;
  bool get hideHud => mockHideHud;
  bool get focusModeActive => mockFocusModeActive;
  bool get isTouchLayout => mockIsTouchLayout;
  QualityLevel get quality => mockQuality;
  bool get sellMode => mockSellMode;
  Tower? get focusTower => mockFocusTower;
  Enemy? get focusTarget => mockFocusTarget;
  double get focusFxPulse => mockFocusFxPulse;
  double get focusModeTimer => mockFocusModeTimer;
  double get focusModeMaxDuration => mockFocusModeMaxDuration;
  bool get reduceFx => mockReduceFx;
  bool get allowBlur => mockAllowBlur;

  @override
  Vector2 get size => _mockSize;

  // Mock methods that abilities call
  void activateNeonPulse() {
    pulseActivated = true;
  }

  void deployMine() {
    mineDeployed = true;
  }

  void sellTower(Tower tower) {
    sellTowerCallCount++;
  }

  @override
  Color backgroundColor() => Colors.black;
}

/// Helper to create a component with mock game reference
Future<T> createComponentWithMockGame<T extends Component>(
  T component,
  MockBoredGamesGame game,
) async {
  await game.add(component);
  return component;
}
