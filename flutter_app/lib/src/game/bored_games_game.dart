import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/neon_grid_component.dart';
import 'components/neon_mine.dart';
import 'components/neon_pulse.dart';
import 'effects/floating_text.dart';
import 'effects/focus_mode_overlay.dart';
import 'effects/particle_system.dart';
import 'effects/impact_effect.dart';
import 'effects/explosion_effect.dart';
import 'effects/screen_effects.dart';
import 'effects/shaders/shader_uniform_controller.dart';
import 'effects/shaders/world_uber_shader_component.dart';
import 'effects/shaders/particle_shader_component.dart';
import 'effects/shaders/screen_post_process_component.dart';
import 'effects/tutorial_guide.dart';
import 'effects/visual_director.dart';
import 'entities/enemy.dart';
import 'entities/tower.dart';
import 'entities/projectile.dart';
import 'fps/fps_view_component.dart';
import 'fps/fps_background_component.dart';
import 'hud/hud_component.dart';
import 'managers/bullet_manager.dart';
import 'managers/enemy_manager.dart';
import 'managers/tower_manager.dart';
import 'world/game_world.dart';
import '../models/level_config.dart';
import '../models/quality_level.dart';
import '../models/upgrade_data.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/upgrade_service.dart';
import 'balance/difficulty_curve.dart';
import '../ui/theme/neon_theme.dart';

enum PendingAbility { none, pulse, mine }

class BoredGamesGame extends FlameGame
    with
        HasCollisionDetection,
        TapCallbacks,

        DragCallbacks,
        KeyboardEvents {
  BoredGamesGame({
    this.tileSize = 32,
    this.levelConfig,
    this.onGameOver,
    this.onVictory,
  });

  final double tileSize;
  final LevelConfig? levelConfig;
  final VoidCallback? onGameOver;
  final VoidCallback? onVictory;

  int _totalWaves = 10; // Default, can be set from levelConfig
  int _progressIndex = 0;
  int _difficulty = 1;

  late final WorldUberShaderComponent worldShaderComponent;
  late final ParticleShaderComponent particleShaderComponent;
  late final ScreenPostProcessComponent screenPostProcessComponent;
  late final PerspectiveWorldRoot worldRoot;
  late final GameWorld worldLayer;
  late final EnemyManager enemyManager;
  late final TowerManager towerManager;
  late final BulletManager bulletManager;
  late final HudComponent hudComponent;
  late final FocusModeOverlay focusOverlay;
  late final ParticleEmitter particleEmitter;
  late final ScreenEffects screenEffects;
  late final VisualDirector visualDirector;
  late final TutorialGuide tutorialGuide;
  late final ShaderUniformController shaderUniformController;

  bool _visualReady = false;

  // Game state - initialized from levelConfig in onLoad
  late int gold;
  late int lives;
  int score = 0;
  bool _gameEnded = false;
  bool autoStartWaves = true;
  double _autoWaveTimer = 0;
  bool _hasPlacedTower = false;
  static const double autoWaveDelay = 2.5;
  static const double autoWaveFirstTimeout = 10.0;
  static const int runUpgradeInterval = 2;

  // FPS Mode properties
  static const int maxFpsUsesPerMatch = 3;
  static const double fpsModeCostMultiplier = 1.5;
  int _fpsUsesTotal = 0;
  FpsViewComponent? _fpsViewComponent;
  FpsBackgroundComponent? _fpsBackground;
  double _focusModeTimer = 0;
  static const double _focusModeMaxDuration = 10.0;
  
  // Manual Long Press
  double _longPressTimer = 0;
  bool _isLongPressing = false;
  Vector2? _longPressOrigin;
  static const double _longPressDuration = 0.5;

  // Neon Pulse ability
  static const int pulseCostBase = 30;
  static const double pulseCooldown = 15.0; // New constant
  double _pulseCooldownTimer = 0;

  // Mine ability
  static const int mineCostBase = 20; // Changed from 40
  static const double mineCooldown = 10.0; // New constant
  double _mineCooldownTimer = 0;
  static const int maxActiveMinesBase = 5;
  final List<NeonMine> _activeMines = [];

  PendingAbility _pendingAbility = PendingAbility.none;
  PendingAbility get pendingAbility => _pendingAbility;

  Vector2? _lastMousePosition;
  Vector2? get mousePosition => _lastMousePosition;
  Vector2 _lastWorldPosition = Vector2.zero(); // Changed to non-nullable and initialized
  Vector2? get lastPointer => _lastMousePosition;
  bool _draggingPlacement = false;
  double _worldScale = 1.0;
  Vector2 _worldBasePosition = Vector2.zero();
  bool _worldLayoutReady = false;
  Tower? _focusTower;
  bool _focusMode = false;
  bool _sellMode = false;
  double _focusFxPulse = 0;
  final math.Random _threatShakeRandom = math.Random();
  double _threatShakeTimer = 0;
  double _threatShakeDuration = 0;
  double _threatShakeIntensity = 0;
  Vector2 _threatShakeOffset = Vector2.zero();
  double _fxBudgetTimer = 0;
  static const double _focusZoom = 2.5;
  static const double sellRefundRate = 0.2;
  QualityLevel _quality = QualityLevel.high;
  bool autoQuality = true;
  bool enableWorldShader = false;
  bool enableBackgroundParticles = false;
  double _smoothedFps = 60;
  double _lowFpsTimer = 0;
  double _highFpsTimer = 0;
  double _qualitySampleTimer = 0;
  static const double _qualitySampleInterval = 0.1; // More frequent sampling
  static const double _qualityDownSeconds = 1.0; // Faster downgrade
  static const double _qualityUpSeconds = 8.0; // Slower upgrade

  UpgradeStats _metaStats = const UpgradeStats();

  // Game time for FPS view
  double gameTime = 0;
  UpgradeStats _runStats = const UpgradeStats();
  UpgradeStats _upgradeStats = const UpgradeStats();
  final Map<String, int> _runUpgradeLevels = {};
  final List<RunUpgradeDefinition> _pendingRunUpgrades = [];
  bool _awaitingUpgradeChoice = false;
  int _maxLives = 0;


  /// Whether pulse ability is ready
  bool get pulseReady => _pulseCooldownTimer <= 0;

  /// Cooldown remaining (0-1 normalized)
  double get pulseCooldownPercent =>
      (_pulseCooldownTimer / pulseCooldown).clamp(0.0, 1.0);

  /// Whether mine ability is ready
  bool get mineReady => _mineCooldownTimer <= 0 && _activeMines.length < maxActiveMines;

  /// Mine cooldown remaining (0-1 normalized)
  double get mineCooldownPercent =>
      (_mineCooldownTimer / mineCooldown).clamp(0.0, 1.0);

  /// Current active mine count
  int get activeMineCount => _activeMines.length;

  int get maxLives => _maxLives;

  UpgradeStats get upgradeStats => _upgradeStats;

  /// Total waves for current level
  int get totalWaves => _totalWaves;

  QualityLevel get quality => _quality;

  bool get reduceFx => _quality != QualityLevel.high;

  bool get allowBlur => _quality == QualityLevel.high;

  bool get sellMode => _sellMode;

  bool get focusModeActive => _focusMode;

  Tower? get focusTower => _focusTower;

  Enemy? get focusTarget => _focusTower?.manualTarget;

  double get focusFxPulse => _focusFxPulse;

  double get focusModeTimer => _focusModeTimer;
  double get focusModeMaxDuration => _focusModeMaxDuration;
  int get fpsUsesTotal => _fpsUsesTotal;
  int get maxFpsUsesMatch => maxFpsUsesPerMatch;

  bool get isTouchLayout {
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      return true;
    }
    return size.x < 720 || size.y < 520;
  }

  double get shaderScale {
    return switch (_quality) {
      QualityLevel.high => 1.0,
      QualityLevel.medium => 0.75,
      QualityLevel.low => 0.5,
    };
  }

  bool get worldShaderEnabled =>
      enableWorldShader && _quality != QualityLevel.low;

  bool get particleShaderEnabled =>
      enableBackgroundParticles && _quality == QualityLevel.high;

  bool get postProcessEnabled => _quality == QualityLevel.high;

  int get pulseCost => math.max(1, (pulseCostBase * _upgradeStats.abilityCostMult).round());

  // double get pulseCooldown => pulseCooldownBase * _upgradeStats.pulseCooldownMult; // Removed, now a constant

  int get mineCost => math.max(1, (mineCostBase * _upgradeStats.abilityCostMult).round());

  // double get mineCooldown => mineCooldownBase * _upgradeStats.mineCooldownMult; // Removed, now a constant

  int get maxActiveMines => maxActiveMinesBase + _upgradeStats.maxMinesBonus;

  // PendingAbility get pendingAbility => _pendingAbility; // Moved to field definition

  double towerRange(TowerType type) => type.range * _upgradeStats.towerRangeMult;

  double towerDamage(TowerType type) => type.damage * _upgradeStats.towerDamageMult;

  double towerFireRate(TowerType type) => type.fireRate * _upgradeStats.towerFireRateMult;

  double towerProjectileSpeed(TowerType type) =>
      type.projectileSpeed * _upgradeStats.projectileSpeedMult;

  double towerSlowAmount(TowerType type) => type.slowAmount * _upgradeStats.slowMult;

  int towerCost(TowerType type) {
    final base = math.max(1, (type.cost * _upgradeStats.towerCostMult).round());
    if (!_worldLayoutReady) return base;
    final multiplier =
        DifficultyCurve.towerCostMultiplier(towerManager.towerCount);
    return math.max(1, (base * multiplier).round());
  }

  List<RunUpgradeDefinition> get pendingRunUpgrades =>
      List.unmodifiable(_pendingRunUpgrades);

  bool get awaitingUpgradeChoice => _awaitingUpgradeChoice;

  bool get upgradeOverlayActive => overlays.isActive('upgrade');

  @override
  Color backgroundColor() => Colors.black;

  @override
  void update(double dt) {
    super.update(dt);

    // Update game time
    gameTime += dt;

    // Update pulse cooldown
    if (_pulseCooldownTimer > 0) {
      _pulseCooldownTimer -= dt;
    }

    // Update mine cooldown
    if (_mineCooldownTimer > 0) {
      _mineCooldownTimer -= dt;
    }

    if (_visualReady) {
      visualDirector.update(dt);
    }

    _updateAutoWave(dt);
    _updateQuality(dt);
    _updateFxBudget(dt);
    _updateThreatShake(dt);
    _updateFocusFx(dt);
    _updateFocusTimer(dt);
    _updateLongPress(dt);
  }

  void _updateLongPress(double dt) {
    if (!_isLongPressing) return;
    _longPressTimer += dt;
    if (_longPressTimer >= _longPressDuration) {
      _isLongPressing = false; // Triggered
      if (_longPressOrigin != null) {
        _handleLongPress(_longPressOrigin!);
      }
    }
  }

  void _updateFocusTimer(double dt) {
    if (!_focusMode) return;
    _focusModeTimer -= dt;
    if (_focusModeTimer <= 0) {
      exitFocusMode();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    _isLongPressing = true;
    _longPressTimer = 0;
    _longPressOrigin = event.localPosition;
    final worldPos = event.localPosition;
    _lastMousePosition = worldPos;
    if (!_isInHudArea(worldPos)) {
      _lastWorldPosition = _screenToWorld(worldPos);
    }
    if (_sellMode) {
      towerManager.updateGhost(null);
      return;
    }
    if (_focusMode) {
      return;
    }
    if (_isInHudArea(worldPos)) {
      towerManager.updateGhost(null);
    } else {
      towerManager.updateGhost(_screenToWorld(worldPos));
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    _isLongPressing = false;
    if (_draggingPlacement) return;
    if (_sellMode) {
      if (_isInHudArea(event.localPosition)) {
        towerManager.updateGhost(null);
        return;
      }
      final worldPos = _screenToWorld(event.localPosition);
      final tower = towerManager.towerAt(worldPos);
      if (tower != null) {
        sellTower(tower);
        if (towerManager.towers.isEmpty) {
          _sellMode = false;
          add(FloatingText(
            position: Vector2(size.x / 2, HudComponent.topBarHeight + 14),
            text: 'SELL OFF',
            type: FloatingTextType.combo,
            customColor: NeonColors.cyan,
            fontSize: 12,
            duration: 0.8,
            riseSpeed: 16,
          ));
        }
      } else {
        add(FloatingText(
          position: event.localPosition.clone(),
          text: 'NO TOWER',
          type: FloatingTextType.damage,
          customColor: NeonColors.magenta,
          fontSize: 12,
          duration: 0.7,
          riseSpeed: 18,
        ));
      }
      towerManager.updateGhost(null);
      return;
    }
    if (_pendingAbility != PendingAbility.none) {
      if (!_isInHudArea(event.localPosition)) {
        final worldPos = _screenToWorld(event.localPosition);
        _lastWorldPosition = worldPos;
        if (_pendingAbility == PendingAbility.pulse) {
          activateNeonPulse(targetWorld: worldPos);
        } else if (_pendingAbility == PendingAbility.mine) {
          deployMine(targetWorld: worldPos);
        }
        _pendingAbility = PendingAbility.none;
      } else {
        _pendingAbility = PendingAbility.none;
        add(FloatingText(
          position: Vector2(size.x / 2, HudComponent.topBarHeight + 14),
          text: 'TARGET CANCELLED',
          type: FloatingTextType.combo,
          customColor: NeonColors.cyan,
          fontSize: 12,
          duration: 0.8,
          riseSpeed: 16,
        ));
      }
      towerManager.updateGhost(null);
      return;
    }
    if (_focusMode) {
      _handleFocusTap(event.localPosition);
      return;
    }
    if (_isInHudArea(event.localPosition)) {
      towerManager.updateGhost(null);
      return;
    }
    final worldPos = _screenToWorld(event.localPosition);
    final tower = towerManager.towerAt(worldPos);
    if (tower != null) {
      towerManager.updateGhost(null);
      return;
    }
    _attemptPlaceTower(event.localPosition);
    towerManager.updateGhost(null);
  }

  @override
  void _handleLongPress(Vector2 screenPos) {
    if (_sellMode || _pendingAbility != PendingAbility.none) return;

    final worldPos = _screenToWorld(screenPos);
    final tower = towerManager.towerAt(worldPos);

    if (tower != null) {
      if (_focusMode && _focusTower == tower) {
        exitFocusMode();
      } else {
        _enterFocusMode(tower);
      }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _lastMousePosition = event.localEndPosition;
    if (!_isInHudArea(event.localEndPosition)) {
      _lastWorldPosition = _screenToWorld(event.localEndPosition);
    }
    if (_sellMode) {
      towerManager.updateGhost(null);
      return;
    }
    if (_focusMode) {
      return;
    }
    towerManager.updateGhost(_screenToWorld(event.localEndPosition));
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isLongPressing = false;
    _draggingPlacement = true;
    _lastMousePosition = event.localPosition;
    if (!_isInHudArea(event.localPosition)) {
      _lastWorldPosition = _screenToWorld(event.localPosition);
    }
    if (_sellMode) {
      towerManager.updateGhost(null);
      return;
    }
    if (_focusMode) {
      return;
    }
    towerManager.updateGhost(_screenToWorld(event.localPosition));
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (_sellMode) {
      _draggingPlacement = false;
      towerManager.updateGhost(null);
      return;
    }
    if (_focusMode) {
      _draggingPlacement = false;
      towerManager.updateGhost(null);
      return;
    }
    if (_draggingPlacement && _lastMousePosition != null) {
      _attemptPlaceTower(_lastMousePosition!);
    }
    _draggingPlacement = false;
    towerManager.updateGhost(null);
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      // Space bar activates Neon Pulse
      if (event.logicalKey == LogicalKeyboardKey.space) {
        activateNeonPulse();
        return KeyEventResult.handled;
      }
      // M key deploys a mine
      if (event.logicalKey == LogicalKeyboardKey.keyM) {
        deployMine();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// Activate Neon Pulse ability at current mouse position
  void activateNeonPulse({Vector2? targetWorld}) {
    if (!pulseReady) {
      _showAbilityStatus('PULSE EN RECARGA', NeonColors.cyan);
      return;
    }
    if (gold < pulseCost) {
      _showAbilityStatus('NECESITAS ${pulseCost}G', NeonColors.yellow);
      return;
    }
    final worldPos = _resolveAbilityTarget(targetWorld);
    if (worldPos == null) {
      _pendingAbility = PendingAbility.pulse;
      _showAbilityTargetHint('Toca el campo para activar PULSE');
      return;
    }

    gold -= pulseCost;
    _pulseCooldownTimer = pulseCooldown;
    _pendingAbility = PendingAbility.none;
    notifyTutorialAbilityUsed();

    final pulse = NeonPulse(
      center: worldPos,
      radius: 100,
      slowFactor: 0.3, // 70% slow
      slowDuration: 3.0,
      enemies: () => enemyManager.activeEnemies,
      reducedFx: reduceFx,
    );

    worldRoot.add(pulse);
    AudioService.instance.playPulse();

    _applyVisual(() => visualDirector.notifyPulse(worldPos));
  }

  /// Deploy a mine at current mouse position
  void deployMine({Vector2? targetWorld}) {
    if (_activeMines.length >= maxActiveMines) {
      _showAbilityStatus('MAX MINAS', NeonColors.magenta);
      return;
    }
    if (_mineCooldownTimer > 0) {
      _showAbilityStatus('MINE EN RECARGA', NeonColors.magenta);
      return;
    }
    if (gold < mineCost) {
      _showAbilityStatus('NECESITAS ${mineCost}G', NeonColors.yellow);
      return;
    }
    final worldPos = _resolveAbilityTarget(targetWorld);
    if (worldPos == null) {
      _pendingAbility = PendingAbility.mine;
      _showAbilityTargetHint('Toca el camino para poner MINE');
      return;
    }

    // Check if position is valid (snap to path, not too close to other mines)
    final cell = screenToGrid(worldPos, tileSize);
    if (!_isCellWithinWorld(cell)) {
      _showMinePlacementFeedback(worldPos, 'Out of bounds');
      return;
    }

    math.Point<int>? targetCell = cell;
    if (!_isPathCell(cell)) {
      targetCell = _nearestPathCell(cell, 2);
      if (targetCell == null) {
        _showMinePlacementFeedback(worldPos, 'Place mines on path');
        return;
      }
    }

    final minePos = gridToWorld(targetCell, tileSize) +
        Vector2(tileSize / 2, tileSize / 2);

    // Don't place too close to existing mines
    for (final mine in _activeMines) {
      if ((mine.position - minePos).length < tileSize * 0.8) {
        return; // Too close to another mine
      }
    }

    gold -= mineCost;
    _mineCooldownTimer = mineCooldown;
    _pendingAbility = PendingAbility.none;
    notifyTutorialAbilityUsed();

    final mine = NeonMine(
      position: minePos,
      enemies: () => enemyManager.activeEnemies,
      onExplode: _onMineExplode,
      damage: 150,
      explosionRadius: 60,
    );

    _activeMines.add(mine);
    worldRoot.add(mine);
    AudioService.instance.playMineDeploy();
  }

  void _onMineExplode(NeonMine mine) {
    _activeMines.remove(mine);
    score += 5; // Small score bonus for successful mine
    AudioService.instance.playMineExplode();

    _applyVisual(() => visualDirector.notifyMine(mine.position.clone()));
  }

  void _onEnemyKilled(Enemy enemy, int goldReward) {
    final reward =
        math.max(1, (goldReward * _upgradeStats.goldGainMult).round());
    gold += reward;
    score += 10;
    AudioService.instance.playGoldEarned();

    _applyVisual(() => visualDirector.handleEnemyKill(enemy, reward));
  }

  void _onEnemyLeaked(Enemy enemy) {
    if (_gameEnded) return;
    lives -= 1;
    AudioService.instance.playEnemyLeak();
    _applyVisual(() => visualDirector.handleEnemyLeak(enemy));
    if (lives <= 0) {
      lives = 0;
      _gameEnded = true;
      AudioService.instance.playGameOver();
      onGameOver?.call();
    }
  }

  void triggerBaseThreat(double intensity) {
    if (_gameEnded) return;
    final clamped = intensity.clamp(0.0, 1.0);
    final baseShake = reduceFx ? 1.2 : 2.4;
    screenEffects.triggerDamageVignette(intensity: 0.25 + clamped * 0.45);
    _threatShakeIntensity = math.max(
      _threatShakeIntensity,
      baseShake + clamped * (reduceFx ? 0.8 : 1.6),
    );
    _threatShakeDuration = 0.18;
    _threatShakeTimer = 0;
    if (!reduceFx) {
      screenEffects.addTrauma(0.06 + clamped * 0.08);
    }
  }

  void triggerFocusShot(Tower tower) {
    if (!_focusMode || _focusTower != tower) return;
    final base = switch (tower.type) {
      TowerType.pulseArcher => 0.35,
      TowerType.circuitCannon => 0.6,
      TowerType.phaseMage => 0.45,
      TowerType.glimmerField => 0.3,
      TowerType.ionSniper => 0.8,
      TowerType.teslaTerminal => 0.4,
      TowerType.resonanceSiphon => 0.5,
      TowerType.neuralDisruptor => 0.4,
    };
    _focusFxPulse = 1.0;
    _threatShakeIntensity = math.max(_threatShakeIntensity, 0.8 + base * 1.4);
    _threatShakeDuration = 0.1 + base * 0.05;
    _threatShakeTimer = 0;

    screenEffects.triggerShake(
      intensity: 1.2 + base * 2.0,
      duration: 0.08 + base * 0.03,
    );
    screenEffects.addTrauma(0.02 + base * 0.03);
    if (!reduceFx) {
      screenEffects.triggerFlash(
        color: tower.color,
        intensity: 0.08 + base * 0.05,
        duration: 0.05,
      );
    }
  }

  void registerFocusHit({
    required Tower tower,
    required Enemy target,
    required Vector2 hitWorld,
    required bool killed,
  }) {
    if (!_focusMode || _focusTower != tower) return;
    final screenPos = worldToScreen(hitWorld);
    focusOverlay.registerHit(screenPos, critical: killed);
    if (killed) {
      AudioService.instance.playCriticalHit();
      screenEffects.triggerFlash(
        color: NeonColors.magenta,
        intensity: 0.12,
        duration: 0.06,
      );
    }
  }

  void _onWaveComplete(int waveNumber) {
    if (_gameEnded) return;

    // Bonus gold for completing wave
    gold += DifficultyCurve.waveClearBonus(
      progressIndexValue: _progressIndex,
      wave: waveNumber,
      difficulty: _difficulty,
    );
    score += 50 * waveNumber;

    // Check for victory
    if (waveNumber >= _totalWaves) {
      _gameEnded = true;
      AudioService.instance.playVictory();
      onVictory?.call();
    }

    _applyVisual(() => visualDirector.notifyWaveComplete(waveNumber));
    if (!_gameEnded && waveNumber < _totalWaves) {
      _maybeOfferRunUpgrade(waveNumber);
    }
  }

  void startWave({int count = 6}) {
    enemyManager.startWave(count: count);
    _applyVisual(() => visualDirector.notifyWaveStart(enemyManager.currentWave, enemyManager.currentModifier));
    notifyTutorialWaveStart();
    add(FloatingText(
      position: Vector2(size.x / 2, 60),
      text: 'Wave ${enemyManager.currentWave} launched!',
      type: FloatingTextType.combo,
      customColor: NeonColors.magenta,
      fontSize: 16,
      duration: 1.2,
      riseSpeed: 26,
    ));
  }

  void notifyTutorialTowerSelected() => tutorialGuide.onTowerSelected();

  void notifyTutorialTowerPlaced() => tutorialGuide.onTowerPlaced();

  void notifyTutorialWaveStart() => tutorialGuide.onWaveStarted();

  void notifyTutorialAbilityUsed() => tutorialGuide.onAbilityUsed();

  void notifyTutorialFocusMode() => tutorialGuide.onFocusMode();

  bool _isInHudArea(Vector2 position) {
    if (position.y <= HudComponent.topBarHeight) return true;
    if (position.y >= size.y - HudComponent.bottomBarHeight) return true;
    return false;
  }

  void _syncHudMetrics() {
    if (size.isZero()) return;
    final compactHud = isTouchLayout || size.x < 820 || size.y < 560;
    HudComponent.applyLayoutMetrics(
      width: size.x,
      height: size.y,
      compact: compactHud,
    );
  }

  void _showInsufficientGold(Vector2 position, int cost) {
    add(FloatingText(
      position: position.clone(),
      text: 'Need $cost gold',
      type: FloatingTextType.gold,
      customColor: NeonColors.yellow,
      fontSize: 12,
      duration: 0.9,
      riseSpeed: 22,
    ));
  }

  void toggleSellMode() {
    if (_focusMode) {
      exitFocusMode();
    }
    _sellMode = !_sellMode;
    _draggingPlacement = false;
    towerManager.updateGhost(null);
    _pendingAbility = PendingAbility.none;
    final label = _sellMode ? 'SELL MODE' : 'SELL OFF';
    final color = _sellMode ? NeonColors.red : NeonColors.cyan;
    add(FloatingText(
      position: Vector2(size.x / 2, HudComponent.topBarHeight + 14),
      text: label,
      type: FloatingTextType.combo,
      customColor: color,
      fontSize: 14,
      duration: 1.0,
      riseSpeed: 16,
    ));
  }

  void sellTower(Tower tower) {
    final removed = towerManager.removeTower(tower);
    if (!removed) return;

    final baseCost =
        tower.buildCost > 0 ? tower.buildCost : towerCost(tower.type);
    final refund = math.max(1, (baseCost * sellRefundRate).round());
    gold += refund;
    AudioService.instance.playGoldEarned();

    add(FloatingText(
      position: worldToScreen(tower.centerPosition),
      text: '+$refund',
      type: FloatingTextType.gold,
      fontSize: 14,
      duration: 0.9,
      riseSpeed: 20,
    ));
  }

  void _showMinePlacementFeedback(Vector2 worldPos, String message) {
    final screenPos = worldToScreen(worldPos);
    add(FloatingText(
      position: screenPos,
      text: message,
      type: FloatingTextType.damage,
      customColor: NeonColors.yellow,
      fontSize: 12,
      duration: 0.8,
      riseSpeed: 18,
    ));
  }

  Vector2? _resolveAbilityTarget(Vector2? targetWorld) {
    if (targetWorld != null) return targetWorld;
    if (_lastMousePosition != null && !_isInHudArea(_lastMousePosition!)) {
      return _screenToWorld(_lastMousePosition!);
    }
    return _lastWorldPosition;
  }

  void _showAbilityTargetHint(String message) {
    add(FloatingText(
      position: Vector2(size.x / 2, size.y - HudComponent.bottomBarHeight - 24),
      text: message,
      type: FloatingTextType.combo,
      customColor: NeonColors.cyan,
      fontSize: 12,
      duration: 1.4,
      riseSpeed: 18,
    ));
  }

  void _showAbilityStatus(String message, Color color) {
    add(FloatingText(
      position: Vector2(size.x / 2, size.y - HudComponent.bottomBarHeight - 24),
      text: message,
      type: FloatingTextType.combo,
      customColor: color,
      fontSize: 12,
      duration: 1.0,
      riseSpeed: 18,
    ));
  }

  bool _isCellWithinWorld(math.Point<int> cell) {
    return cell.y >= 0 &&
        cell.y < worldLayer.tileTypes.length &&
        cell.x >= 0 &&
        cell.x < worldLayer.tileTypes[cell.y].length;
  }

  bool _isPathCell(math.Point<int> cell) {
    if (!_isCellWithinWorld(cell)) return false;
    return worldLayer.tileTypes[cell.y][cell.x] == 2;
  }

  math.Point<int>? _nearestPathCell(math.Point<int> origin, int radius) {
    math.Point<int>? best;
    var bestDistSq = double.infinity;
    for (int y = origin.y - radius; y <= origin.y + radius; y++) {
      for (int x = origin.x - radius; x <= origin.x + radius; x++) {
        final candidate = math.Point<int>(x, y);
        if (!_isPathCell(candidate)) continue;
        final dx = origin.x - x;
        final dy = origin.y - y;
        final distSq = (dx * dx + dy * dy).toDouble();
        if (distSq < bestDistSq) {
          bestDistSq = distSq;
          best = candidate;
        }
      }
    }
    return best;
  }

  void _refreshUpgradeStats() {
    _upgradeStats = _metaStats.merge(_runStats);
    towerManager.applyUpgradeStats(_upgradeStats);
    _pulseCooldownTimer = _pulseCooldownTimer.clamp(0.0, pulseCooldown);
    _mineCooldownTimer = _mineCooldownTimer.clamp(0.0, mineCooldown);
  }

  void toggleRunUpgradeOverlay() {
    if (upgradeOverlayActive) {
      overlays.remove('upgrade');
      return;
    }
    if (_pendingRunUpgrades.isEmpty) {
      add(FloatingText(
        position: Vector2(size.x / 2, HudComponent.topBarHeight + 14),
        text: 'NO UPGRADES READY',
        type: FloatingTextType.combo,
        customColor: NeonColors.cyan,
        fontSize: 12,
        duration: 0.9,
        riseSpeed: 18,
      ));
      return;
    }
    overlays.add('upgrade');
  }

  void closeRunUpgradeOverlay() {
    if (upgradeOverlayActive) {
      overlays.remove('upgrade');
    }
  }

  void _maybeOfferRunUpgrade(int waveNumber) {
    if (_awaitingUpgradeChoice || _gameEnded) return;
    if (waveNumber % runUpgradeInterval != 0) return;

    final choices = UpgradeService.instance.rollRunUpgrades(
      currentStacks: _runUpgradeLevels,
      count: 3,
    );
    if (choices.isEmpty) return;
    _pendingRunUpgrades
      ..clear()
      ..addAll(choices);
    _awaitingUpgradeChoice = true;
    add(FloatingText(
      position: Vector2(size.x / 2, HudComponent.topBarHeight + 14),
      text: 'UPGRADE READY',
      type: FloatingTextType.combo,
      customColor: NeonColors.cyan,
      fontSize: 12,
      duration: 1.0,
      riseSpeed: 18,
    ));
  }

  void selectRunUpgrade(String id) {
    if (!_awaitingUpgradeChoice) return;
    RunUpgradeDefinition? choice;
    for (final upgrade in _pendingRunUpgrades) {
      if (upgrade.id == id) {
        choice = upgrade;
        break;
      }
    }
    if (choice == null) return;

    final current = _runUpgradeLevels[id] ?? 0;
    if (current >= choice.maxStacks) return;
    _runUpgradeLevels[id] = current + 1;
    _runStats = _runStats.merge(choice.stats);
    _refreshUpgradeStats();

    if (choice.instantGold > 0) {
      gold += choice.instantGold;
    }
    if (choice.instantLives > 0) {
      lives = math.min(lives + choice.instantLives, _maxLives);
    }

    _pendingRunUpgrades.clear();
    _awaitingUpgradeChoice = false;
    closeRunUpgradeOverlay();
  }

  void skipRunUpgrade() {
    if (!_awaitingUpgradeChoice) return;
    _pendingRunUpgrades.clear();
    _awaitingUpgradeChoice = false;
    closeRunUpgradeOverlay();
  }

  void _enterFocusMode(Tower tower) {
    // 0. Check for Boss Presence
    // DISABLED FOR TESTING
    /*
    if (enemyManager.currentBoss == null) {
      add(FloatingText(
        position: Vector2(size.x / 2, HudComponent.topBarHeight + 12),
        text: 'BOSS REQUIRED FOR OVERDRIVE',
        type: FloatingTextType.damage,
        customColor: NeonColors.magenta,
      ));
      return;
    }
    */

    // 1. Check Usage Limit
    // DISABLED FOR TESTING
    /*
    if (_fpsUsesTotal >= maxFpsUsesPerMatch) {
      add(FloatingText(
        position: Vector2(size.x / 2, HudComponent.topBarHeight + 12),
        text: 'OVERDRIVE EXHAUSTED FOR THIS MATCH',
        type: FloatingTextType.damage,
        customColor: NeonColors.magenta,
      ));
      return;
    }
    */
    if (_focusMode) return;

    _focusMode = true;
    _focusTower = tower;
    _focusModeTimer = _focusModeMaxDuration;
    _fpsUsesTotal++;

    // Add BACKGROUND (Behind world)
    _fpsBackground = FpsBackgroundComponent();
    add(_fpsBackground!);

    // Add FOREGROUND (Cockpit)
    _fpsViewComponent = FpsViewComponent(tower: tower);
    add(_fpsViewComponent!);
    towerManager.updateGhost(null);
    add(FloatingText(
      position: Vector2(size.x / 2, HudComponent.topBarHeight + 12),
      text: 'FPS MODE ENGAGED',
      type: FloatingTextType.combo,
      customColor: tower.color,
      fontSize: 16,
      duration: 1.2,
      riseSpeed: 18,
    ));
  }

  void exitFocusMode({bool playSfx = true}) {
    if (!_focusMode) return;
    
    // Remove tower boost
    _focusTower?.exitFpsBoost();
    
    _focusTower = null;
    _focusMode = false;

    // Remove the FpsViewComponent
    _fpsViewComponent?.removeFromParent();
    _fpsViewComponent = null;

    // Remove the FpsBackgroundComponent
    _fpsBackground?.removeFromParent();
    _fpsBackground = null;

    // Trigger Camera Reflow
    _reflowWorld();

    if (playSfx) {
      add(FloatingText(
        position: Vector2(size.x / 2, HudComponent.topBarHeight + 12),
        text: 'FPS DISENGAGED',
        type: FloatingTextType.combo,
        customColor: NeonColors.cyan,
        fontSize: 14,
        duration: 1.0,
        riseSpeed: 16,
      ));
    }
  }

  void _handleFocusTap(Vector2 screenPos) {
    if (_focusTower == null) return;
    if (_isInHudArea(screenPos)) return;
    final worldPos = _screenToWorld(screenPos);
    final enemy = _pickEnemy(worldPos);
    if (enemy == null) {
      _focusTower!.setManualTarget(null);
      add(FloatingText(
        position: screenPos.clone(),
        text: 'TARGET CLEARED',
        type: FloatingTextType.combo,
        customColor: NeonColors.cyan,
        fontSize: 12,
        duration: 0.8,
        riseSpeed: 20,
      ));
      return;
    }

    final center = _focusTower!.centerPosition;
    final dx = enemy.position.x - center.x;
    final dy = enemy.position.y - center.y;
    if ((dx * dx) + (dy * dy) > _focusTower!.range * _focusTower!.range) {
      add(FloatingText(
        position: screenPos.clone(),
        text: 'OUT OF RANGE',
        type: FloatingTextType.damage,
        customColor: NeonColors.magenta,
        fontSize: 12,
        duration: 0.9,
        riseSpeed: 20,
      ));
      return;
    }

    _focusTower!.setManualTarget(enemy);
    add(FloatingText(
      position: screenPos.clone(),
      text: 'TARGET LOCKED',
      type: FloatingTextType.combo,
      customColor: _focusTower!.color,
      fontSize: 12,
      duration: 0.9,
      riseSpeed: 20,
    ));
  }

  void manualFireRequest(Vector2 direction) {
    if (!_focusMode || _focusTower == null) return;
    if (!_focusTower!.isReady) return;

    bulletManager.fireManualShot(
      from: _focusTower!.centerPosition,
      direction: direction,
      tower: _focusTower!,
    );
    _focusTower!.resetCooldown();
  }

  Enemy? _pickEnemy(Vector2 worldPos) {
    Enemy? closest;
    var bestDistSq = 26.0 * 26.0;
    for (final enemy in enemyManager.activeEnemies) {
      if (!enemy.isAlive || !enemy.isVisible) continue;
      final dx = enemy.position.x - worldPos.x;
      final dy = enemy.position.y - worldPos.y;
      final distSq = (dx * dx) + (dy * dy);
      if (distSq <= bestDistSq) {
        bestDistSq = distSq;
        closest = enemy;
      }
    }
    return closest;
  }

  void _attemptPlaceTower(Vector2 worldPos) {
    if (_isInHudArea(worldPos)) return;

    final placementPos = _screenToWorld(worldPos);
    final cost = towerCost(towerManager.selectedTowerType);
    if (gold < cost) {
      _showInsufficientGold(worldPos, cost);
      return;
    }

    final placed = towerManager.placeTower(placementPos);
    if (placed) {
      gold -= cost;
      _hasPlacedTower = true;
      _autoWaveTimer = 0;
    }
  }

  void _updateAutoWave(double dt) {
    if (!autoStartWaves) return;
    if (_gameEnded) return;
    if (enemyManager.spawning || enemyManager.aliveCount > 0) {
      _autoWaveTimer = 0;
      return;
    }
    if (enemyManager.currentWave >= _totalWaves) {
      _autoWaveTimer = 0;
      return;
    }

    if (enemyManager.currentWave == 0 && !_hasPlacedTower) {
      _autoWaveTimer += dt;
      if (_autoWaveTimer >= autoWaveFirstTimeout) {
        _autoWaveTimer = 0;
        startWave(count: 6);
      }
      return;
    }

    _autoWaveTimer += dt;
    if (_autoWaveTimer >= autoWaveDelay) {
      _autoWaveTimer = 0;
      startWave(count: 6);
    }
  }

  Vector2 _screenToWorld(Vector2 screen) {
    if (!_worldLayoutReady) return screen;
    final offset = screen - worldRoot.position;
    if (_worldScale <= 0) return offset;
    return offset / _worldScale;
  }

  Vector2 worldToScreen(Vector2 world) {
    if (!_worldLayoutReady) return world;
    return worldRoot.position + (world * _worldScale);
  }

  void _reflowWorld() {
    if (!_worldLayoutReady) return;
    if (worldLayer.mapWidth == 0 || worldLayer.mapHeight == 0) return;
    final availableWidth = size.x;
    final availableHeight =
        size.y - HudComponent.topBarHeight - HudComponent.bottomBarHeight;
    if (availableWidth <= 0 || availableHeight <= 0) return;

    final worldWidth = worldLayer.mapWidth * tileSize;
    final worldHeight = worldLayer.mapHeight * tileSize;
    if (worldWidth <= 0 || worldHeight <= 0) return;

    final baseScale = math.min(
      availableWidth / worldWidth,
      availableHeight / worldHeight,
    );
    final zoom = _focusMode && _focusTower != null ? _focusZoom : 1.0;
    _worldScale = baseScale * zoom;

    if (_focusMode && _focusTower != null) {
      final centerScreen = Vector2(
        availableWidth / 2,
        HudComponent.topBarHeight + (availableHeight / 2),
      );
      final focusWorld = _focusTower!.centerPosition * _worldScale;
      worldRoot
        ..position = centerScreen - focusWorld
        ..scale = Vector2.all(_worldScale);
    } else {
      final scaledWidth = worldWidth * _worldScale;
      final scaledHeight = worldHeight * _worldScale;
      final offsetX = (availableWidth - scaledWidth) / 2;
      final offsetY = HudComponent.topBarHeight +
          (availableHeight - scaledHeight) / 2;
      worldRoot
        ..position = Vector2(offsetX, offsetY)
        ..scale = Vector2.all(_worldScale);
    }
    _worldBasePosition = worldRoot.position.clone();
    _syncEnemyViewport();
  }

  void _updateThreatShake(double dt) {
    if (!_worldLayoutReady || !_visualReady) return;

    if (_threatShakeTimer < _threatShakeDuration) {
      _threatShakeTimer += dt;
      final progress = (_threatShakeTimer / _threatShakeDuration).clamp(0.0, 1.0);
      final decay = 1 - progress;
      _threatShakeOffset = Vector2(
        (_threatShakeRandom.nextDouble() - 0.5) * 2 * _threatShakeIntensity * decay,
        (_threatShakeRandom.nextDouble() - 0.5) * 2 * _threatShakeIntensity * decay,
      );
    } else {
      _threatShakeOffset = Vector2.zero();
      _threatShakeIntensity = 0;
    }

    worldRoot.position = _worldBasePosition + _threatShakeOffset;
  }

  void _updateFocusFx(double dt) {
    if (_focusFxPulse <= 0) return;
    _focusFxPulse = math.max(0.0, _focusFxPulse - dt * 2.6);
  }

  void _applyVisual(VoidCallback action) {
    if (_visualReady) {
      action();
    }
  }

  void _updateQuality(double dt) {
    if (!autoQuality) return;
    _qualitySampleTimer += dt;
    if (_qualitySampleTimer < _qualitySampleInterval) return;
    _qualitySampleTimer = 0;

    final currentFps = 1.0 / dt;
    _smoothedFps = _smoothedFps * 0.9 + currentFps * 0.1;

    // Emergency mode: force lowest quality if FPS is critically low
    if (_smoothedFps < 20) {
      _quality = QualityLevel.low;
      enableWorldShader = false;
      enableBackgroundParticles = false;
      Tower.lowFx = true;
      return;
    }

    if (_smoothedFps < 40) {
      _lowFpsTimer += _qualitySampleInterval;
      _highFpsTimer = 0;
      if (_lowFpsTimer >= _qualityDownSeconds) {
        if (_quality == QualityLevel.high) {
          _quality = QualityLevel.medium;
          enableWorldShader = false;
        } else if (_quality == QualityLevel.medium) {
          _quality = QualityLevel.low;
          enableBackgroundParticles = false;
        }
        _lowFpsTimer = 0;
        Tower.lowFx = _quality != QualityLevel.high;
      }
    } else if (_smoothedFps > 50) {
      _highFpsTimer += _qualitySampleInterval;
      _lowFpsTimer = 0;
      if (_highFpsTimer >= _qualityUpSeconds) {
        if (_quality == QualityLevel.low) {
          _quality = QualityLevel.medium;
        } else if (_quality == QualityLevel.medium) {
          _quality = QualityLevel.high;
        }
        _highFpsTimer = 0;
        Tower.lowFx = _quality != QualityLevel.high;
      }
    } else {
      _lowFpsTimer = 0;
      _highFpsTimer = 0;
    }
  }

  void _setQuality(QualityLevel level) {
    if (_quality == level) return;
    _quality = level;
    _applyQuality();
    _saveQualitySettings();
  }

  void _applyQuality() {
    if (!_visualReady) return;
    worldLayer.setQuality(reduceFx: reduceFx, allowBlur: allowBlur);
    screenEffects.setQuality(reduceFx: reduceFx, allowBlur: allowBlur);
    worldShaderComponent.enabled = worldShaderEnabled;
    particleShaderComponent.enabled = particleShaderEnabled;
    screenPostProcessComponent.enabled = postProcessEnabled;
    shaderUniformController.enabled = worldShaderEnabled;
    Tower.lowFx = reduceFx;
    Enemy.forceLowFx = reduceFx;
    Enemy.allowBlur = allowBlur;
    Enemy.throttleOffscreen = reduceFx;
    final particleScale = switch (_quality) {
      QualityLevel.high => 1.0,
      QualityLevel.medium => 0.7,
      QualityLevel.low => 0.45,
    };
    GameParticles.instance.setQuality(
      burstScale: particleScale,
      allowGlow: _quality != QualityLevel.low,
      allowTrails: _quality == QualityLevel.high,
    );
    ImpactEffect.fxScale = particleScale;
    ExplosionEffect.fxScale = particleScale;
    Projectile.lowFx = _quality == QualityLevel.low;
    Projectile.allowTrails = _quality == QualityLevel.high;
    Projectile.allowGlow = _quality != QualityLevel.low;
    _syncEnemyViewport();
  }

  void _updateFxBudget(double dt) {
    if (!_visualReady) return;
    _fxBudgetTimer += dt;
    if (_fxBudgetTimer < 0.5) return;
    _fxBudgetTimer = 0;

    final enemies = enemyManager.aliveCount;
    final bullets = bulletManager.activeCount;
    final towers = towerManager.towerCount;
    final heavyLoad =
        enemies >= (isTouchLayout ? 24 : 32) ||
        bullets >= (isTouchLayout ? 120 : 160) ||
        towers >= (isTouchLayout ? 18 : 26);

    final baseScale = switch (_quality) {
      QualityLevel.high => 1.0,
      QualityLevel.medium => 0.7,
      QualityLevel.low => 0.45,
    };
    final fxScale = heavyLoad ? baseScale * 0.65 : baseScale;

    ImpactEffect.fxScale = fxScale;
    ExplosionEffect.fxScale = fxScale;
    Projectile.lowFx = _quality == QualityLevel.low || heavyLoad;
    Projectile.allowTrails = _quality == QualityLevel.high && !heavyLoad;
    Projectile.allowGlow = _quality != QualityLevel.low && !heavyLoad;
    Tower.lowFx = _quality != QualityLevel.high || heavyLoad;

    GameParticles.instance.setQuality(
      burstScale: fxScale,
      allowGlow: _quality == QualityLevel.high && !heavyLoad,
      allowTrails: _quality == QualityLevel.high && !heavyLoad,
    );
  }

  void _saveQualitySettings() {
    if (!StorageService.instance.isReady) return;
    StorageService.instance.saveQualitySettings(
      preset: _quality.name,
      autoQuality: autoQuality,
    );
  }

  QualityLevel _parseQualityPreset(String? value) {
    switch (value) {
      case 'low':
        return QualityLevel.low;
      case 'medium':
        return QualityLevel.medium;
      case 'high':
        return QualityLevel.high;
      default:
        return QualityLevel.high;
    }
  }

  void _applyDefaultQuality() {
    if (isTouchLayout) {
      _quality = QualityLevel.medium;
      autoQuality = true;
    }
  }

  bool isWorldPointVisible(Vector2 worldPos, {double padding = 40}) {
    if (!_worldLayoutReady || size.isZero()) return true;
    final screen = worldToScreen(worldPos);
    return screen.x >= -padding &&
        screen.x <= size.x + padding &&
        screen.y >= -padding &&
        screen.y <= size.y + padding;
  }

  void _syncEnemyViewport() {
    if (!_worldLayoutReady || size.isZero()) return;
    Enemy.screenOffset = worldRoot.position.clone();
    Enemy.screenScale = _worldScale;
    Enemy.screenSize = size.clone();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize from level config
    _totalWaves = levelConfig?.waves ?? 10;

    await StorageService.instance.initialize();
    await UpgradeService.instance.initialize();
    await AudioService.instance.initialize();
    
    _metaStats = UpgradeService.instance.metaStats;
    _upgradeStats = _metaStats;
    final levelId = levelConfig?.id ?? 1;
    _difficulty = levelConfig?.difficulty ?? 1;
    _progressIndex = DifficultyCurve.progressIndex(levelId: levelId);
    final worldIndex = DifficultyCurve.worldForLevel(levelId);
    final localIndex = DifficultyCurve.localIndexForLevel(levelId);
    final tunedGold = DifficultyCurve.startingGold(
      world: worldIndex,
      localIndex: localIndex,
    );
    gold = tunedGold + _upgradeStats.startingGoldBonus;
    lives = (levelConfig?.startingLives ?? 20) + _upgradeStats.startingLivesBonus;
    _maxLives = lives;
    final qualitySettings = StorageService.instance.loadQualitySettings();
    if (qualitySettings != null) {
      _quality = _parseQualityPreset(qualitySettings['preset'] as String?);
      final auto = qualitySettings['autoQuality'];
      if (auto is bool) {
        autoQuality = auto;
      }
    } else {
      _applyDefaultQuality();
    }

    worldRoot = PerspectiveWorldRoot();
    worldShaderComponent = WorldUberShaderComponent();
    particleShaderComponent = ParticleShaderComponent();
    shaderUniformController = ShaderUniformController();
    screenPostProcessComponent = ScreenPostProcessComponent(
      enabled: false,
    );
    worldShaderComponent.enabled = enableWorldShader;
    shaderUniformController.enabled = enableWorldShader;
    await add(worldShaderComponent);
    await add(particleShaderComponent);
    await add(shaderUniformController);

    await add(worldRoot);

    // Base layer: neon grid backdrop for Tron look.
    add(NeonGridComponent(
      gridSize: tileSize,
      lineColor: const Color(0xFF00FFFF),
      glowColor: const Color(0xAA00FFFF),
      reducedFx: true,
    ));

    final mapFile = levelConfig?.mapFile ?? 'maps/level1.tmx';
    worldLayer = GameWorld(
      tileSize: tileSize,
      mapFile: mapFile,
    );
    bulletManager = BulletManager();

    enemyManager = EnemyManager(
      tileSize: tileSize,
      world: worldLayer,
      onEnemyKilled: _onEnemyKilled,
      onEnemyLeaked: _onEnemyLeaked,
      onWaveComplete: _onWaveComplete,
    );

    towerManager = TowerManager(
      tileSize: tileSize,
      world: worldLayer,
      bulletManager: bulletManager,
      enemyManager: enemyManager,
    );
    towerManager.applyUpgradeStats(_upgradeStats);

    hudComponent = HudComponent();
    focusOverlay = FocusModeOverlay();

    // Particle system
    particleEmitter = ParticleEmitter(position: Vector2.zero(), maxParticles: 200);
    GameParticles.instance.setEmitter(particleEmitter);

    // Add logical layers; order matters for rendering priority.
    await worldRoot.add(worldLayer);
    await worldRoot.add(enemyManager);
    await worldRoot.add(towerManager);
    await worldRoot.add(bulletManager);
    await worldRoot.add(particleEmitter);
    _worldLayoutReady = true;
    _syncHudMetrics();
    _reflowWorld();
    await add(focusOverlay);
    await add(hudComponent);

    screenEffects = ScreenEffects(
      gameSize: size,
      enableCRT: false,
      enableVignette: false,
      enableScanlines: false,
      enableFlash: false,
    )
      ..priority = 1000;
    add(screenEffects);
    await add(screenPostProcessComponent);

    visualDirector = VisualDirector(
      game: this,
      screenEffects: screenEffects,
    );

    tutorialGuide = TutorialGuide();
    add(tutorialGuide);

    _visualReady = true;
    _applyQuality();
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    _syncHudMetrics();
    _reflowWorld();
    if (_worldLayoutReady) {
      worldLayer.invalidateCache();
    }
  }

  math.Point<int> screenToGrid(Vector2 pos, double tileSize) {
    final worldPos = _screenToWorld(pos);
    return math.Point(
      (worldPos.x / tileSize).floor(),
      (worldPos.y / tileSize).floor(),
    );
  }

  Vector2 gridToWorld(math.Point<int> cell, double tileSize) {
    return Vector2(
      cell.x * tileSize,
      cell.y * tileSize,
    );
  }
}

class PerspectiveWorldRoot extends PositionComponent with HasGameRef<BoredGamesGame> {
  @override
  void renderTree(Canvas canvas) {
    if (gameRef.focusModeActive) {
      canvas.save();
      final halfW = gameRef.size.x / 2;
      final halfH = gameRef.size.y / 2;
      
      // Perspective Transform
      final matrix = Matrix4.identity()
        ..setEntry(3, 2, 0.0015) // Perspective intensity
        ..rotateX(1.1) // Tilt back ~63 degrees
        ..translate(0.0, -200.0); // Adjust camera height

      // Apply transform relative to center
      canvas.translate(halfW, halfH);
      canvas.transform(matrix.storage);
      canvas.translate(-halfW, -halfH);
      
      super.renderTree(canvas);
      canvas.restore();
    } else {
      super.renderTree(canvas);
    }
  }
}
