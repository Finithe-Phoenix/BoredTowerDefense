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
import '../ui/theme/neon_theme.dart';
import '../models/level_config.dart';
import '../services/audio_service.dart';

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

  // Neon Pulse ability
  static const int pulseCost = 30;
  static const double pulseCooldown = 5.0;
  double _pulseCooldownTimer = 0;
  Vector2? _lastMousePosition;
  Vector2? get lastPointer => _lastMousePosition;

  // Mine ability
  static const int mineCost = 40;
  static const double mineCooldown = 8.0;
  static const int maxActiveMines = 5;
  double _mineCooldownTimer = 0;
  final List<NeonMine> _activeMines = [];

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
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    final worldPos = event.localPosition;
    _lastMousePosition = worldPos;

    // Check if we can afford the tower
    final cost = towerManager.selectedTowerType.cost;
    if (gold >= cost) {
      final beforeCount = towerManager.occupied.length;
      towerManager.placeTower(worldPos);
      // Deduct gold only if tower was actually placed
      if (towerManager.occupied.length > beforeCount) {
        gold -= cost;
      }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _lastMousePosition = event.localEndPosition;
    towerManager.updateGhost(event.localEndPosition);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _lastMousePosition = event.localPosition;
    towerManager.updateGhost(event.localPosition);
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

    gold -= pulseCost;
    _pulseCooldownTimer = pulseCooldown;

    final pulse = NeonPulse(
      center: _lastMousePosition!,
      radius: 100,
      slowFactor: 0.3, // 70% slow
      slowDuration: 3.0,
      enemies: () => enemyManager.activeEnemies,
    );

    add(pulse);
    AudioService.instance.playPulse();

    _applyVisual(() => visualDirector.notifyPulse(_lastMousePosition!));
  }

  /// Deploy a mine at current mouse position
  void deployMine() {
    if (!mineReady) return;
    if (gold < mineCost) return;
    if (_lastMousePosition == null) return;

    // Check if position is valid (on path, not too close to other mines)
    final minePos = _lastMousePosition!;

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
    add(mine);
    AudioService.instance.playMineDeploy();
  }

  void _onMineExplode(NeonMine mine) {
    _activeMines.remove(mine);
    score += 5; // Small score bonus for successful mine
    AudioService.instance.playMineExplode();

    _applyVisual(() => visualDirector.notifyMine(mine.position.clone()));
  }

  void _onEnemyKilled(Enemy enemy, int goldReward) {
    gold += goldReward;
    score += 10;
    AudioService.instance.playGoldEarned();

    _applyVisual(() => visualDirector.handleEnemyKill(enemy, goldReward));
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

  void _applyVisual(VoidCallback action) {
    if (_visualReady) {
      action();
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize from level config
    gold = levelConfig?.startingGold ?? 200;
    lives = levelConfig?.startingLives ?? 20;
    _totalWaves = levelConfig?.waves ?? 10;

    worldShaderComponent = WorldUberShaderComponent();
    particleShaderComponent = ParticleShaderComponent();
    shaderUniformController = ShaderUniformController();
    screenPostProcessComponent = ScreenPostProcessComponent();
    await add(worldShaderComponent);
    await add(particleShaderComponent);
    await add(shaderUniformController);

    // Base layer: neon grid backdrop for Tron look.
    add(NeonGridComponent(
      gridSize: tileSize,
      lineColor: const Color(0xFF00FFFF),
      glowColor: const Color(0xAA00FFFF),
    ));

    worldLayer = GameWorld(tileSize: tileSize);
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

    hudComponent = HudComponent();

    // Particle system
    particleEmitter = ParticleEmitter(position: Vector2.zero(), maxParticles: 200);
    GameParticles.instance.setEmitter(particleEmitter);

    // Add logical layers; order matters for rendering priority.
    await add(worldLayer);
    await add(enemyManager);
    await add(towerManager);
    await add(bulletManager);
    await add(particleEmitter);
    await add(hudComponent);

    screenEffects = ScreenEffects(gameSize: size)
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
  }
}
