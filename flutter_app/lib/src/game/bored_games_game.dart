import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/neon_grid_component.dart';
import 'components/neon_mine.dart';
import 'components/neon_pulse.dart';
import 'effects/floating_text.dart';
import 'effects/particle_system.dart';
import 'effects/screen_effects.dart';
import 'effects/shaders/shader_uniform_controller.dart';
import 'effects/shaders/world_uber_shader_component.dart';
import 'effects/shaders/particle_shader_component.dart';
import 'effects/shaders/screen_post_process_component.dart';
import 'effects/tutorial_guide.dart';
import 'effects/visual_director.dart';
import 'hud/hud_component.dart';
import 'managers/bullet_manager.dart';
import 'managers/enemy_manager.dart';
import 'managers/tower_manager.dart';
import 'world/game_world.dart';
import 'entities/enemy.dart';
import 'entities/tower.dart';
import '../ui/theme/neon_theme.dart';
import '../models/level_config.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/upgrade_service.dart';
import '../models/upgrade_data.dart';

enum QualityLevel { low, medium, high }

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

  late final WorldUberShaderComponent worldShaderComponent;
  late final ParticleShaderComponent particleShaderComponent;
  late final ScreenPostProcessComponent screenPostProcessComponent;
  final PositionComponent worldRoot = PositionComponent();
  late final GameWorld worldLayer;
  late final EnemyManager enemyManager;
  late final TowerManager towerManager;
  late final BulletManager bulletManager;
  late final HudComponent hudComponent;
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

  // Neon Pulse ability
  static const int pulseCostBase = 30;
  static const double pulseCooldownBase = 5.0;
  double _pulseCooldownTimer = 0;
  Vector2? _lastMousePosition;
  Vector2? get lastPointer => _lastMousePosition;
  bool _draggingPlacement = false;
  double _worldScale = 1.0;
  bool _worldLayoutReady = false;
  Tower? _focusTower;
  bool _focusMode = false;
  Tower? _tapTower;
  int _tapCount = 0;
  double _tapTimer = 0;
  static const int _focusTapCount = 5;
  static const double _tapResetDelay = 1.2;
  static const double _focusZoom = 1.6;
  QualityLevel _quality = QualityLevel.high;
  bool autoQuality = true;
  bool enableWorldShader = false;
  bool enableBackgroundParticles = false;
  double _smoothedFps = 60;
  double _lowFpsTimer = 0;
  double _highFpsTimer = 0;
  double _qualitySampleTimer = 0;
  static const double _qualitySampleInterval = 0.2;
  static const double _qualityDownSeconds = 2.5;
  static const double _qualityUpSeconds = 6.0;

  // Mine ability
  static const int mineCostBase = 40;
  static const double mineCooldownBase = 8.0;
  static const int maxActiveMinesBase = 5;
  double _mineCooldownTimer = 0;
  final List<NeonMine> _activeMines = [];
  UpgradeStats _metaStats = const UpgradeStats();
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

  double get pulseCooldown => pulseCooldownBase * _upgradeStats.pulseCooldownMult;

  int get mineCost => math.max(1, (mineCostBase * _upgradeStats.abilityCostMult).round());

  double get mineCooldown => mineCooldownBase * _upgradeStats.mineCooldownMult;

  int get maxActiveMines => maxActiveMinesBase + _upgradeStats.maxMinesBonus;

  double towerRange(TowerType type) => type.range * _upgradeStats.towerRangeMult;

  double towerDamage(TowerType type) => type.damage * _upgradeStats.towerDamageMult;

  double towerFireRate(TowerType type) => type.fireRate * _upgradeStats.towerFireRateMult;

  double towerProjectileSpeed(TowerType type) =>
      type.projectileSpeed * _upgradeStats.projectileSpeedMult;

  double towerSlowAmount(TowerType type) => type.slowAmount * _upgradeStats.slowMult;

  int towerCost(TowerType type) =>
      math.max(1, (type.cost * _upgradeStats.towerCostMult).round());

  List<RunUpgradeDefinition> get pendingRunUpgrades =>
      List.unmodifiable(_pendingRunUpgrades);

  bool get awaitingUpgradeChoice => _awaitingUpgradeChoice;

  @override
  Color backgroundColor() => Colors.black;

  @override
  void update(double dt) {
    super.update(dt);

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
    _updateTapTimer(dt);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    final worldPos = event.localPosition;
    _lastMousePosition = worldPos;
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
    if (_draggingPlacement) return;
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
      _registerTowerTap(tower);
      towerManager.updateGhost(null);
      return;
    }
    _attemptPlaceTower(event.localPosition);
    towerManager.updateGhost(null);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _lastMousePosition = event.localEndPosition;
    if (_focusMode) {
      return;
    }
    towerManager.updateGhost(_screenToWorld(event.localEndPosition));
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _draggingPlacement = true;
    _lastMousePosition = event.localPosition;
    if (_focusMode) {
      return;
    }
    towerManager.updateGhost(_screenToWorld(event.localPosition));
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
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
  void activateNeonPulse() {
    if (!pulseReady) return;
    if (gold < pulseCost) return;
    if (_lastMousePosition == null) return;
    if (_isInHudArea(_lastMousePosition!)) return;

    final worldPos = _screenToWorld(_lastMousePosition!);
    gold -= pulseCost;
    _pulseCooldownTimer = pulseCooldown;

    final pulse = NeonPulse(
      center: worldPos,
      radius: 100,
      slowFactor: 0.3, // 70% slow
      slowDuration: 3.0,
      enemies: () => enemyManager.activeEnemies,
    );

    worldRoot.add(pulse);
    AudioService.instance.playPulse();

    _applyVisual(() => visualDirector.notifyPulse(worldPos));
  }

  /// Deploy a mine at current mouse position
  void deployMine() {
    if (!mineReady) return;
    if (gold < mineCost) return;
    if (_lastMousePosition == null) return;
    if (_isInHudArea(_lastMousePosition!)) return;

    // Check if position is valid (on path, not too close to other mines)
    final minePos = _screenToWorld(_lastMousePosition!);

    // Don't place too close to existing mines
    for (final mine in _activeMines) {
      if ((mine.position - minePos).length < 30) {
        return; // Too close to another mine
      }
    }

    gold -= mineCost;
    _mineCooldownTimer = mineCooldown;

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

  void _onWaveComplete(int waveNumber) {
    if (_gameEnded) return;
    // Bonus gold for completing wave
    gold += 20 + (waveNumber * 5);
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

  bool _isInHudArea(Vector2 position) {
    if (position.y <= HudComponent.topBarHeight) return true;
    if (position.y >= size.y - HudComponent.bottomBarHeight) return true;
    return false;
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

  void _refreshUpgradeStats() {
    _upgradeStats = _metaStats.merge(_runStats);
    towerManager.applyUpgradeStats(_upgradeStats);
    _pulseCooldownTimer = _pulseCooldownTimer.clamp(0.0, pulseCooldown);
    _mineCooldownTimer = _mineCooldownTimer.clamp(0.0, mineCooldown);
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
    overlays.add('upgrade');
    paused = true;
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
    overlays.remove('upgrade');
    paused = false;
  }

  void skipRunUpgrade() {
    if (!_awaitingUpgradeChoice) return;
    _pendingRunUpgrades.clear();
    _awaitingUpgradeChoice = false;
    overlays.remove('upgrade');
    paused = false;
  }

  void _updateTapTimer(double dt) {
    if (_tapCount == 0) return;
    _tapTimer += dt;
    if (_tapTimer >= _tapResetDelay) {
      _tapCount = 0;
      _tapTower = null;
      _tapTimer = 0;
    }
  }

  void _registerTowerTap(Tower tower) {
    if (_tapTower != tower) {
      _tapTower = tower;
      _tapCount = 0;
    }
    _tapCount += 1;
    _tapTimer = 0;

    if (_tapCount >= _focusTapCount) {
      _tapCount = 0;
      _tapTower = null;
      if (_focusMode && _focusTower == tower) {
        _exitFocusMode();
      } else {
        _enterFocusMode(tower);
      }
    }
  }

  void _enterFocusMode(Tower tower) {
    _focusTower?.setManualMode(false);
    _focusTower = tower;
    _focusMode = true;
    _focusTower?.setManualMode(true);
    towerManager.updateGhost(null);
    _reflowWorld();
    add(FloatingText(
      position: Vector2(size.x / 2, HudComponent.topBarHeight + 12),
      text: 'FOCUS MODE',
      type: FloatingTextType.combo,
      customColor: tower.color,
      fontSize: 16,
      duration: 1.2,
      riseSpeed: 18,
    ));
  }

  void _exitFocusMode() {
    _focusTower?.setManualMode(false);
    _focusTower = null;
    _focusMode = false;
    _reflowWorld();
    add(FloatingText(
      position: Vector2(size.x / 2, HudComponent.topBarHeight + 12),
      text: 'FOCUS OFF',
      type: FloatingTextType.combo,
      customColor: NeonColors.cyan,
      fontSize: 14,
      duration: 1.0,
      riseSpeed: 16,
    ));
  }

  void _handleFocusTap(Vector2 screenPos) {
    if (_focusTower == null) return;
    if (_isInHudArea(screenPos)) return;
    final worldPos = _screenToWorld(screenPos);
    final tower = towerManager.towerAt(worldPos);
    if (tower != null) {
      _registerTowerTap(tower);
      return;
    }
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
    _syncEnemyViewport();
  }

  void _applyVisual(VoidCallback action) {
    if (_visualReady) {
      action();
    }
  }

  void _updateQuality(double dt) {
    if (!autoQuality) return;
    if (dt <= 0) return;

    _qualitySampleTimer += dt;
    if (_qualitySampleTimer < _qualitySampleInterval) return;
    _qualitySampleTimer = 0;

    final fps = 1 / dt;
    _smoothedFps += (fps - _smoothedFps) * 0.1;

    final lowThreshold = switch (_quality) {
      QualityLevel.high => 52.0,
      QualityLevel.medium => 38.0,
      QualityLevel.low => 0.0,
    };
    final highThreshold = switch (_quality) {
      QualityLevel.high => double.infinity,
      QualityLevel.medium => 55.0,
      QualityLevel.low => 45.0,
    };

    if (_smoothedFps < lowThreshold) {
      _lowFpsTimer += _qualitySampleInterval;
      _highFpsTimer = 0;
    } else if (_smoothedFps > highThreshold) {
      _highFpsTimer += _qualitySampleInterval;
      _lowFpsTimer = 0;
    } else {
      _lowFpsTimer = 0;
      _highFpsTimer = 0;
    }

    if (_lowFpsTimer >= _qualityDownSeconds) {
      _lowFpsTimer = 0;
      _highFpsTimer = 0;
      if (_quality == QualityLevel.high) {
        _setQuality(QualityLevel.medium);
      } else if (_quality == QualityLevel.medium) {
        _setQuality(QualityLevel.low);
      }
    }

    if (_highFpsTimer >= _qualityUpSeconds) {
      _lowFpsTimer = 0;
      _highFpsTimer = 0;
      if (_quality == QualityLevel.low) {
        _setQuality(QualityLevel.medium);
      } else if (_quality == QualityLevel.medium) {
        _setQuality(QualityLevel.high);
      }
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
    _syncEnemyViewport();
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
    _metaStats = UpgradeService.instance.metaStats;
    _upgradeStats = _metaStats;
    gold = (levelConfig?.startingGold ?? 200) + _upgradeStats.startingGoldBonus;
    lives = (levelConfig?.startingLives ?? 20) + _upgradeStats.startingLivesBonus;
    _maxLives = lives;
    final qualitySettings = StorageService.instance.loadQualitySettings();
    if (qualitySettings != null) {
      _quality = _parseQualityPreset(qualitySettings['preset'] as String?);
      final auto = qualitySettings['autoQuality'];
      if (auto is bool) {
        autoQuality = auto;
      }
    }

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
    _reflowWorld();
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
    _reflowWorld();
    if (_worldLayoutReady) {
      worldLayer.invalidateCache();
    }
  }
}
