import 'dart:math';

import 'package:flame/components.dart';

import '../effects/explosion_effect.dart';
import '../entities/enemy.dart';
import '../world/game_world.dart';
import '../../services/audio_service.dart';

/// Callback types for wave events
typedef EnemyKilledCallback = void Function(Enemy enemy, int goldReward);
typedef EnemyLeakedCallback = void Function(Enemy enemy);
typedef WaveCompleteCallback = void Function(int waveNumber);

/// Wave modifier types
enum WaveModifier {
  normal,
  overload, // Fast enemies, less HP
  juggernaut, // Slow tanky enemies
  mixed, // Mix of types
  phantom, // Invisible enemies - need Phase Mage to detect!
}

class EnemyManager extends Component {
  EnemyManager({
    required this.tileSize,
    required this.world,
    this.onEnemyKilled,
    this.onEnemyLeaked,
    this.onWaveComplete,
  });

  final double tileSize;
  final GameWorld world;

  /// Callbacks for game state updates
  EnemyKilledCallback? onEnemyKilled;
  EnemyLeakedCallback? onEnemyLeaked;
  WaveCompleteCallback? onWaveComplete;

  bool spawning = false;
  double _timer = 0;
  int remaining = 0;
  int _currentWave = 0;
  int _aliveCount = 0;
  WaveModifier _currentModifier = WaveModifier.normal;
  int _spawnIndex = 0;
  int _waveTotalEnemies = 0;
  final List<Enemy> _activeEnemies = [];

  /// Base stats for wave scaling
  static const double baseHealth = 100;
  static const double baseSpeed = 60;
  static const int baseGold = 10;
  static const double healthScaling = 1.2; // HP_n = HP_base * 1.2^n

  /// Current wave number
  int get currentWave => _currentWave;

  /// Number of enemies currently alive
  int get aliveCount => _aliveCount;

  /// Current wave modifier
  WaveModifier get currentModifier => _currentModifier;

  /// Whether current wave is special (overload/juggernaut)
  bool get isSpecialWave => _currentModifier != WaveModifier.normal;

  /// Normalized wave spawn progress (0-1)
  double get waveProgress {
    if (_waveTotalEnemies == 0) return 0.0;
    final progress = 1 - (remaining / _waveTotalEnemies);
    return progress.clamp(0.0, 1.0);
  }

  /// Simple intensity metric for shader/vfx hooks
  double get waveIntensity => spawning ? waveProgress : 0.0;

  /// Get all active enemies
  List<Enemy> get activeEnemies => _activeEnemies;

  @override
  void update(double dt) {
    super.update(dt);
    Enemy.lowFx = _aliveCount > 18;
    if (!spawning || world.waypoints.isEmpty || remaining <= 0) return;

    _timer += dt;
    final spawnInterval = _currentModifier == WaveModifier.overload ? 0.6 : 1.0;

    if (_timer > spawnInterval) {
      _timer = 0;
      remaining -= 1;
      _spawnEnemy();
      if (remaining <= 0) {
        spawning = false;
      }
    }
  }

  void _spawnEnemy() {
    // Calculate scaled stats based on wave number
    final scaledHealth = baseHealth * pow(healthScaling, _currentWave);
    final scaledSpeed = baseSpeed + (_currentWave * 2);
    final scaledGold = baseGold + (_currentWave * 2);

    // Determine enemy type based on wave modifier
    EnemyType enemyType;
    switch (_currentModifier) {
      case WaveModifier.overload:
        enemyType = EnemyType.overloaded;
        break;
      case WaveModifier.juggernaut:
        enemyType = EnemyType.juggernaut;
        break;
      case WaveModifier.phantom:
        enemyType = EnemyType.phantom;
        break;
      case WaveModifier.mixed:
        // Alternate between all types including phantom
        final types = [EnemyType.runner, EnemyType.overloaded, EnemyType.juggernaut, EnemyType.phantom];
        enemyType = types[_spawnIndex % types.length];
        break;
      case WaveModifier.normal:
        enemyType = EnemyType.runner;
    }

    final enemy = Enemy(
      path: world.waypoints,
      speed: scaledSpeed,
      maxHealth: scaledHealth,
      goldReward: scaledGold,
      type: enemyType,
      onDeath: _onEnemyDeath,
      onReachBase: _onEnemyReachBase,
    );

    _aliveCount++;
    _spawnIndex++;
    add(enemy);
    _activeEnemies.add(enemy);
  }

  void _onEnemyDeath(Enemy enemy) {
    _aliveCount--;
    _activeEnemies.remove(enemy);

    // Spawn epic explosion effect at enemy position
    final expSize = 30.0 + (enemy.type.sizeMult * 20);
    final effect = ExplosionEffect.spawn(
      position: enemy.position.clone(),
      color: enemy.type.color,
      explosionSize: expSize,
      duration: 0.5 + (enemy.type == EnemyType.juggernaut ? 0.2 : 0),
    );
    if (effect != null) {
      add(effect);
    }

    // Play explosion sound
    AudioService.instance.playExplosion();

    onEnemyKilled?.call(enemy, enemy.goldReward);
    _checkWaveComplete();
  }

  void _onEnemyReachBase(Enemy enemy) {
    _aliveCount--;
    _activeEnemies.remove(enemy);
    onEnemyLeaked?.call(enemy);
    _checkWaveComplete();
  }

  void _checkWaveComplete() {
    if (!spawning && _aliveCount <= 0) {
      onWaveComplete?.call(_currentWave);
    }
  }

  /// Start a new wave with specified enemy count
  void startWave({int count = 5}) {
    if (spawning) return; // Don't interrupt ongoing wave

    _currentWave++;
    _spawnIndex = 0;

    // Determine wave modifier
    // Wave 4: First phantom wave (warning!)
    // Every 3rd wave is Overload, every 5th is Juggernaut
    // Every 4th wave (from wave 4) is Phantom, every 7th is Mixed
    if (_currentWave % 7 == 0) {
      _currentModifier = WaveModifier.mixed;
    } else if (_currentWave >= 4 && _currentWave % 4 == 0) {
      _currentModifier = WaveModifier.phantom; // Phantom waves at 4, 8, 12, etc.
    } else if (_currentWave % 5 == 0) {
      _currentModifier = WaveModifier.juggernaut;
    } else if (_currentWave % 3 == 0) {
      _currentModifier = WaveModifier.overload;
    } else {
      _currentModifier = WaveModifier.normal;
    }

    // More enemies each wave, special waves have different counts
    int enemyCount = count + (_currentWave - 1);
    if (_currentModifier == WaveModifier.overload) {
      enemyCount = (enemyCount * 1.5).toInt(); // More but weaker
    } else if (_currentModifier == WaveModifier.juggernaut) {
      enemyCount = (enemyCount * 0.6).toInt().clamp(2, 100); // Fewer but stronger
    } else if (_currentModifier == WaveModifier.phantom) {
      enemyCount = (enemyCount * 0.8).toInt().clamp(3, 100); // Moderate count, tricky
    }

    remaining = enemyCount;
    _waveTotalEnemies = enemyCount;
    spawning = true;
    _timer = 0;

    // Play wave start sound
    AudioService.instance.playWaveStart();
  }

  /// Reset to initial state
  void reset() {
    spawning = false;
    _timer = 0;
    remaining = 0;
    _currentWave = 0;
    _aliveCount = 0;
    _currentModifier = WaveModifier.normal;
    _spawnIndex = 0;
    _activeEnemies.clear();

    // Remove all existing enemies
    for (final enemy in children.whereType<Enemy>().toList()) {
      enemy.removeFromParent();
    }
  }

  /// Get wave description for HUD
  String get waveDescription {
    switch (_currentModifier) {
      case WaveModifier.overload:
        return 'OVERLOAD!';
      case WaveModifier.juggernaut:
        return 'JUGGERNAUT!';
      case WaveModifier.phantom:
        return 'PHANTOM!';
      case WaveModifier.mixed:
        return 'MIXED!';
      case WaveModifier.normal:
        return '';
    }
  }
}
