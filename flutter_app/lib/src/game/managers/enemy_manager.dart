import 'dart:math';

import 'package:flame/components.dart';

import '../effects/explosion_effect.dart';
import '../entities/enemy.dart';
import '../world/game_world.dart';
import '../bored_games_game.dart';
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

class EnemyManager extends Component with HasGameRef<BoredGamesGame> {
  EnemyManager({
    required this.tileSize,
    required this.world,
    this.onEnemyKilled,
    this.onEnemyLeaked,
    this.onWaveComplete,
  }) : _spatialCellSize = tileSize;

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
  double _levelHealthScale = 1.0;
  double _levelSpeedScale = 1.0;
  double _spawnRateScale = 1.0;
  double _enemyCountScale = 1.0;
  double _goldScale = 1.0;
  double _spawnInterval = 1.0;
  int _levelWorld = 1;
  bool _tuningReady = false;
  final List<Enemy> _activeEnemies = [];
  final Map<int, List<Enemy>> _enemyBuckets = {};
  final double _spatialCellSize;

  /// Base stats for wave scaling
  static const double baseHealth = 100;
  static const double baseSpeed = 60;
  static const int baseGold = 10;
  static const double healthPerWave = 0.18; // Linear scaling per wave
  static const int minEnemyCount = 3;
  static const int maxEnemyCount = 160;
  static const int minGoldReward = 4;

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

  int _cellKey(int x, int y) => Object.hash(x, y);

  int _cellFor(double value) => (value / _spatialCellSize).floor();

  void rebuildSpatialIndex() {
    for (final bucket in _enemyBuckets.values) {
      bucket.clear();
    }
    if (_activeEnemies.isEmpty) return;

    for (final enemy in _activeEnemies) {
      if (!enemy.isAlive) continue;
      final cx = _cellFor(enemy.position.x);
      final cy = _cellFor(enemy.position.y);
      final key = _cellKey(cx, cy);
      final bucket = _enemyBuckets.putIfAbsent(key, () => <Enemy>[]);
      bucket.add(enemy);
    }
  }

  void queryEnemiesInRange(Vector2 center, double range, List<Enemy> out) {
    out.clear();
    if (_activeEnemies.isEmpty) return;

    final minX = _cellFor(center.x - range);
    final maxX = _cellFor(center.x + range);
    final minY = _cellFor(center.y - range);
    final maxY = _cellFor(center.y + range);
    final rangeSq = range * range;

    for (int cy = minY; cy <= maxY; cy++) {
      for (int cx = minX; cx <= maxX; cx++) {
        final bucket = _enemyBuckets[_cellKey(cx, cy)];
        if (bucket == null || bucket.isEmpty) continue;
        for (final enemy in bucket) {
          if (!enemy.isAlive) continue;
          final dx = enemy.position.x - center.x;
          final dy = enemy.position.y - center.y;
          if ((dx * dx) + (dy * dy) <= rangeSq) {
            out.add(enemy);
          }
        }
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    Enemy.lowFx = _aliveCount > 18 || gameRef.reduceFx;
    if (!spawning || world.waypoints.isEmpty || remaining <= 0) return;

    _timer += dt;

    if (_timer > _spawnInterval) {
      _timer = 0;
      remaining -= 1;
      _spawnEnemy();
      if (remaining <= 0) {
        spawning = false;
      }
    }
  }

  void _spawnEnemy() {
    if (!_tuningReady) {
      _applyLevelTuning();
    }

    // Calculate scaled stats based on wave number
    final waveHealth = baseHealth * (1 + ((_currentWave - 1) * healthPerWave));
    final scaledHealth = waveHealth * _levelHealthScale;
    final scaledSpeed = (baseSpeed + (_currentWave * 2)) * _levelSpeedScale;
    final scaledGold =
        ((baseGold + (_currentWave * 2)) * _goldScale).round().clamp(minGoldReward, 9999);

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
      spawnIndex: _spawnIndex,
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
    if (!_tuningReady) {
      _applyLevelTuning();
    }

    // Determine wave modifier
    _currentModifier = _selectModifierForWave(_currentWave);

    // More enemies each wave, special waves have different counts
    int enemyCount = count + (_currentWave - 1);
    if (_currentModifier == WaveModifier.overload) {
      enemyCount = (enemyCount * 1.35).ceil(); // More but weaker
    } else if (_currentModifier == WaveModifier.juggernaut) {
      enemyCount = (enemyCount * 0.7).ceil().clamp(2, maxEnemyCount); // Fewer but stronger
    } else if (_currentModifier == WaveModifier.phantom) {
      enemyCount = (enemyCount * 0.85).ceil().clamp(3, maxEnemyCount); // Moderate count, tricky
    } else if (_currentModifier == WaveModifier.mixed) {
      enemyCount = (enemyCount * 1.1).ceil();
    }
    enemyCount = (enemyCount * _enemyCountScale).round().clamp(minEnemyCount, maxEnemyCount);

    remaining = enemyCount;
    _waveTotalEnemies = enemyCount;
    spawning = true;
    _timer = 0;
    final baseInterval = _currentModifier == WaveModifier.overload ? 0.6 : 1.0;
    _spawnInterval = (baseInterval / _spawnRateScale).clamp(0.35, 1.6);

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
    _spawnInterval = 1.0;
    _activeEnemies.clear();
    for (final bucket in _enemyBuckets.values) {
      bucket.clear();
    }

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

  void _applyLevelTuning() {
    final levelId = gameRef.levelConfig?.id ?? 1;
    final difficulty = gameRef.levelConfig?.difficulty ?? 1;
    _levelWorld = ((levelId - 1) ~/ 10) + 1;
    final localIndex = ((levelId - 1) % 10) + 1;

    final worldBoost = 1 + (_levelWorld - 1) * 0.08;
    final localBoost = 1 + (localIndex - 1) * 0.02;
    final difficultyBoost = 1 + (difficulty - 1) * 0.04;

    _levelHealthScale = worldBoost * localBoost * difficultyBoost;
    _levelSpeedScale = 1 + (_levelWorld - 1) * 0.03 + (localIndex - 1) * 0.006;
    _spawnRateScale = 1 + (_levelWorld - 1) * 0.04 + (localIndex - 1) * 0.01;
    _enemyCountScale = 1 + (_levelWorld - 1) * 0.03 + (localIndex - 1) * 0.01;
    _goldScale =
        (1 - (_levelWorld - 1) * 0.02 - (localIndex - 1) * 0.005).clamp(0.7, 1.0);
    _tuningReady = true;
  }

  WaveModifier _selectModifierForWave(int wave) {
    if (_levelWorld <= 1) {
      if (wave % 5 == 0) return WaveModifier.juggernaut;
      if (wave % 3 == 0) return WaveModifier.overload;
      return WaveModifier.normal;
    }
    if (_levelWorld == 2) {
      if (wave % 6 == 0) return WaveModifier.phantom;
      if (wave % 5 == 0) return WaveModifier.juggernaut;
      if (wave % 3 == 0) return WaveModifier.overload;
      return WaveModifier.normal;
    }
    if (_levelWorld == 3) {
      if (wave % 7 == 0) return WaveModifier.mixed;
      if (wave % 4 == 0) return WaveModifier.phantom;
      if (wave % 5 == 0) return WaveModifier.juggernaut;
      if (wave % 3 == 0) return WaveModifier.overload;
      return WaveModifier.normal;
    }

    if (wave % 8 == 0) return WaveModifier.mixed;
    if (wave % 6 == 0) return WaveModifier.phantom;
    if (wave % 5 == 0) return WaveModifier.juggernaut;
    if (wave % 3 == 0) return WaveModifier.overload;
    return WaveModifier.normal;
  }
}
