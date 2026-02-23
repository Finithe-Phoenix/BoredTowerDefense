import 'dart:math';

import 'package:flame/components.dart';

import '../effects/explosion_effect.dart';
import '../effects/pixel_disintegration_effect.dart';
import '../effects/boss_entrance_effect.dart';
import '../entities/enemy.dart';
import '../entities/boss.dart';
import '../world/game_world.dart';
import '../bored_games_game.dart';
import '../balance/difficulty_curve.dart';
import '../../services/audio_service.dart';
import '../../models/quality_level.dart';

/// Callback types for wave events
typedef EnemyKilledCallback = void Function(Enemy enemy, int goldReward);
typedef EnemyLeakedCallback = void Function(Enemy enemy);
typedef WaveCompleteCallback = void Function(int waveNumber);
typedef BossSpawnCallback = void Function(String bossName);
typedef BossPhaseCallback = void Function(String bossName, int phase);

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
    this.onBossSpawn,
    this.onBossPhaseChange,
  }) : _spatialCellSize = tileSize;

  final double tileSize;
  final GameWorld world;

  /// Callbacks for game state updates
  EnemyKilledCallback? onEnemyKilled;
  EnemyLeakedCallback? onEnemyLeaked;
  WaveCompleteCallback? onWaveComplete;
  BossSpawnCallback? onBossSpawn;
  BossPhaseCallback? onBossPhaseChange;

  bool spawning = false;
  double _timer = 0;
  int remaining = 0;
  int _currentWave = 0;
  int _aliveCount = 0;
  WaveModifier _currentModifier = WaveModifier.normal;
  int _spawnIndex = 0;
  int _waveTotalEnemies = 0;
  double _spawnInterval = 1.0;
  int _levelWorld = 1;
  int _localIndex = 1;
  int _progressIndex = 0;
  int _difficulty = 1;
  bool _tuningReady = false;
  final List<Enemy> _activeEnemies = [];
  final Map<int, List<Enemy>> _enemyBuckets = {};
  final double _spatialCellSize;
  double _threatPulseTimer = 0;
  Boss? _currentBoss;
  bool _bossSpawned = false;
  int _totalWavesInLevel = 0;
  bool _spatialIndexDirty = false;
  final List<EnemyType> _waveEnemyPool = [];
  EnemyType? _waveModifierEnemyType;

  /// Base stats for wave scaling
  static const double baseHealth = 100;
  static const double baseSpeed = 60;
  static const int baseGold = 10;
  static const int minEnemyCount = 3;
  static const int maxEnemyCount = 80; // Reduced from 160 to prevent OOM
  static const int minGoldReward = 4;
  static const double _nearBaseThreshold = 0.82;
  static const double _threatPulseInterval = 0.7;

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

  /// Current boss (if any)
  Boss? get currentBoss => _currentBoss;

  int _cellKey(int x, int y) => Object.hash(x, y);

  int _cellFor(double value) => (value / _spatialCellSize).floor();

  // Pool of reusable bucket lists to avoid allocations
  static final List<List<Enemy>> _bucketPool = [];
  static const int _maxBucketPool = 50;

  /// Clear the bucket pool to prevent memory accumulation between games
  static void clearBucketPool() {
    _bucketPool.clear();
  }

  List<Enemy> _getBucket(int key) {
    var bucket = _enemyBuckets[key];
    if (bucket == null) {
      // Reuse from pool if available
      if (_bucketPool.isNotEmpty) {
        bucket = _bucketPool.removeLast();
      } else {
        bucket = <Enemy>[];
      }
      _enemyBuckets[key] = bucket;
    }
    return bucket;
  }

  void rebuildSpatialIndex({bool force = true}) {
    if (!force && !_spatialIndexDirty) return;
    // Return all buckets to pool instead of just clearing
    for (final bucket in _enemyBuckets.values) {
      bucket.clear();
      if (_bucketPool.length < _maxBucketPool) {
        _bucketPool.add(bucket);
      }
    }
    _enemyBuckets.clear();

    if (_activeEnemies.isEmpty) return;

    for (final enemy in _activeEnemies) {
      if (!enemy.isAlive) continue;
      final cx = _cellFor(enemy.position.x);
      final cy = _cellFor(enemy.position.y);
      final key = _cellKey(cx, cy);
      final bucket = _getBucket(key);
      enemy.spatialKey = key;
      enemy.spatialIndex = bucket.length;
      bucket.add(enemy);
    }
    _spatialIndexDirty = false;
  }

  void _clearSpatialIndex() {
    for (final bucket in _enemyBuckets.values) {
      bucket.clear();
      if (_bucketPool.length < _maxBucketPool) {
        _bucketPool.add(bucket);
      }
    }
    _enemyBuckets.clear();
  }

  void _registerEnemy(Enemy enemy) {
    enemy.activeIndex = _activeEnemies.length;
    _activeEnemies.add(enemy);
    _aliveCount++;
    _addToSpatialIndex(enemy);
  }

  void _unregisterEnemy(Enemy enemy) {
    if (_aliveCount > 0) {
      _aliveCount--;
    }

    final index = enemy.activeIndex;
    if (index >= 0 &&
        index < _activeEnemies.length &&
        identical(_activeEnemies[index], enemy)) {
      final last = _activeEnemies.removeLast();
      if (!identical(last, enemy)) {
        _activeEnemies[index] = last;
        last.activeIndex = index;
      }
    } else {
      _activeEnemies.remove(enemy);
    }
    enemy.activeIndex = -1;
    _removeFromSpatialIndex(enemy);
  }

  void _addToSpatialIndex(Enemy enemy) {
    final cx = _cellFor(enemy.position.x);
    final cy = _cellFor(enemy.position.y);
    final key = _cellKey(cx, cy);
    final bucket = _getBucket(key);
    enemy.spatialKey = key;
    enemy.spatialIndex = bucket.length;
    bucket.add(enemy);
  }

  void _removeFromSpatialIndex(Enemy enemy) {
    final key = enemy.spatialKey;
    if (key == -1) return;
    final bucket = _enemyBuckets[key];
    if (bucket == null) {
      enemy.spatialKey = -1;
      enemy.spatialIndex = -1;
      return;
    }

    final index = enemy.spatialIndex;
    if (index >= 0 &&
        index < bucket.length &&
        identical(bucket[index], enemy)) {
      final last = bucket.removeLast();
      if (!identical(last, enemy)) {
        bucket[index] = last;
        last.spatialIndex = index;
      }
    } else {
      bucket.remove(enemy);
    }

    enemy.spatialKey = -1;
    enemy.spatialIndex = -1;

    if (bucket.isEmpty) {
      _enemyBuckets.remove(key);
      if (_bucketPool.length < _maxBucketPool) {
        _bucketPool.add(bucket);
      }
    }
  }

  void _updateSpatialIndex(Enemy enemy) {
    final cx = _cellFor(enemy.position.x);
    final cy = _cellFor(enemy.position.y);
    final key = _cellKey(cx, cy);
    if (key == enemy.spatialKey) return;
    _removeFromSpatialIndex(enemy);
    final bucket = _getBucket(key);
    enemy.spatialKey = key;
    enemy.spatialIndex = bucket.length;
    bucket.add(enemy);
  }

  void _onEnemyMoved(Enemy enemy) {
    _updateSpatialIndex(enemy);
  }

  void queryEnemiesInRange(Vector2 center, double range, List<Enemy> out) {
    out.clear();
    if (_activeEnemies.isEmpty) return;

    final centerX = center.x;
    final centerY = center.y;
    final minX = _cellFor(centerX - range);
    final maxX = _cellFor(centerX + range);
    final minY = _cellFor(centerY - range);
    final maxY = _cellFor(centerY + range);
    final rangeSq = range * range;

    for (int cy = minY; cy <= maxY; cy++) {
      for (int cx = minX; cx <= maxX; cx++) {
        final bucket = _enemyBuckets[_cellKey(cx, cy)];
        if (bucket == null || bucket.isEmpty) continue;
        for (int i = 0; i < bucket.length; i++) {
          final enemy = bucket[i];
          if (!enemy.isAlive) continue;
          final dx = enemy.position.x - centerX;
          final dy = enemy.position.y - centerY;
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
    final threshold = switch (gameRef.quality) {
      QualityLevel.low => gameRef.isTouchLayout ? 8 : 12,
      QualityLevel.medium => gameRef.isTouchLayout ? 14 : 20,
      QualityLevel.high => gameRef.isTouchLayout ? 20 : 28,
      QualityLevel.extreme => gameRef.isTouchLayout ? 26 : 36,
    };
    Enemy.lowFx = _aliveCount > threshold;
    Enemy.throttleOffscreen = Enemy.lowFx;
    _updateThreatPulse(dt);
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

    // Check if we should spawn a boss
    if (_shouldSpawnBoss()) {
      _spawnBoss();
      return;
    }

    // Calculate scaled stats based on wave and progression curve
    final healthMult = DifficultyCurve.healthMultiplier(
      progressIndexValue: _progressIndex,
      wave: _currentWave,
      difficulty: _difficulty,
    );
    final speedMult = DifficultyCurve.speedMultiplier(
      progressIndexValue: _progressIndex,
      wave: _currentWave,
      difficulty: _difficulty,
    );
    final scaledHealth = baseHealth * healthMult;
    final scaledSpeed = baseSpeed * speedMult;
    final scaledGold =
        ((baseGold + (_currentWave * 2)) * _goldScaleForProgress())
            .round()
            .clamp(minGoldReward, 9999);

    // Determine enemy type based on wave modifier and current world
    EnemyType enemyType;
    switch (_currentModifier) {
      case WaveModifier.overload:
        enemyType = _waveModifierEnemyType ??
            _getModifierEnemyType(WaveModifier.overload);
        break;
      case WaveModifier.juggernaut:
        enemyType = _waveModifierEnemyType ??
            _getModifierEnemyType(WaveModifier.juggernaut);
        break;
      case WaveModifier.phantom:
        enemyType = _waveModifierEnemyType ??
            _getModifierEnemyType(WaveModifier.phantom);
        break;
      case WaveModifier.mixed:
        // Alternate between all available world-specific types
        final pool =
            _waveEnemyPool.isEmpty ? _getAvailableTypes() : _waveEnemyPool;
        enemyType = pool[_spawnIndex % pool.length];
        break;
      case WaveModifier.normal:
        // Use progressive pool for normal waves with world-specific enemies
        final pool =
            _waveEnemyPool.isEmpty ? _getAvailableTypes() : _waveEnemyPool;
        enemyType = pool[_spawnIndex % pool.length];
    }

    final threatTier = _resolveThreatTier();
    final adjustedGold = (scaledGold * (1 + threatTier * 0.18))
        .round()
        .clamp(minGoldReward, 9999);

    final enemy = Enemy(
      path: world.waypoints,
      speed: scaledSpeed,
      maxHealth: scaledHealth,
      goldReward: adjustedGold,
      type: enemyType,
      spawnIndex: _spawnIndex,
      threatTier: threatTier,
      worldIndex: _levelWorld,
      onDeath: _onEnemyDeath,
      onReachBase: _onEnemyReachBase,
      onMoved: _onEnemyMoved,
    );

    _spawnIndex++;
    _registerEnemy(enemy);
    add(enemy);
  }

  bool _shouldSpawnBoss() {
    // Don't spawn boss if already spawned this wave
    if (_bossSpawned) return false;

    // Spawn mini-boss at the end of every level (last wave)
    if (_currentWave == _totalWavesInLevel && remaining == 1) {
      return true;
    }

    return false;
  }

  void _spawnBoss() {
    _bossSpawned = true;

    // Determine boss type
    BossType bossType;
    final levelId = gameRef.levelConfig?.id ?? 1;

    // World bosses (every 10th level)
    if (levelId % 10 == 0) {
      bossType = _getBossTypeForLevel(levelId);
    } else {
      // Mini-boss for regular levels
      bossType = BossType.miniBoss;
    }

    // Calculate boss stats
    final healthMult = DifficultyCurve.healthMultiplier(
      progressIndexValue: _progressIndex,
      wave: _currentWave,
      difficulty: _difficulty,
    );
    final speedMult = DifficultyCurve.speedMultiplier(
      progressIndexValue: _progressIndex,
      wave: _currentWave,
      difficulty: _difficulty,
    );

    // Boss has much higher stats
    final bossHealthMultiplier = bossType == BossType.miniBoss ? 8.0 : 15.0;
    final scaledHealth = baseHealth * healthMult * bossHealthMultiplier;
    final scaledSpeed = baseSpeed * speedMult * 0.6; // Bosses are slower
    final scaledGold = bossType == BossType.miniBoss ? 300 : 1000;

    final boss = Boss(
      path: world.waypoints,
      bossType: bossType,
      bossLevel: levelId,
      speed: scaledSpeed,
      maxHealth: scaledHealth,
      goldReward: scaledGold,
      onDeath: _onEnemyDeath,
      onReachBase: _onEnemyReachBase,
      onPhaseChange: _onBossPhaseChange,
      onAbilityUsed: _onBossAbility,
      onMoved: _onEnemyMoved,
    );

    _currentBoss = boss;
    _spawnIndex++;
    _registerEnemy(boss);
    add(boss);

    // Create epic entrance effect
    final entranceEffect = BossEntranceEffect(
      bossPosition: boss.position.clone(),
      bossColor: boss.type.color,
    );
    add(entranceEffect);

    // Notify game of boss spawn for battle dialogue
    onBossSpawn?.call(boss.displayName);
  }

  BossType _getBossTypeForLevel(int levelId) {
    switch (levelId) {
      case 10:
        return BossType.citadelCore;
      case 20:
        return BossType.abyssGate;
      case 30:
        return BossType.voidlineApex;
      case 40:
        return BossType.shardVault;
      case 50:
        return BossType.arcFortress;
      case 60:
        return BossType.coreHunter;
      case 70:
        return BossType.omegaGrid;
      case 80:
        return BossType.stormTower;
      case 90:
        return BossType.finalGate;
      case 100:
        return BossType.omegaNexus;
      default:
        return BossType.miniBoss;
    }
  }

  void _onBossPhaseChange(Boss boss, int phase) {
    // Trigger visual/audio effects for phase change
    AudioService.instance.playExplosion();

    // Notify game for battle dialogue
    onBossPhaseChange?.call(boss.displayName, phase);
  }

  void _onBossAbility(Boss boss, String abilityName) {
    switch (abilityName) {
      case 'spawn_minions':
        // Get the boss's current position and path progress
        final startNode = boss.currentPathIndex;
        if (startNode == null) return; // Cannot determine path position

        const minionCount = 3;
        for (int i = 0; i < minionCount; i++) {
          // Spawn in a small cluster around the boss
          final offset = (Vector2.random() - Vector2.all(0.5)) * 80;
          final startPosition = boss.position + offset;

          final minion = Enemy(
            path: world.waypoints,
            startPosition: startPosition,
            // Weak minions: 50% base health, no gold
            maxHealth: baseHealth * 0.5,
            speed: baseSpeed * 1.1, // Slightly faster
            goldReward: 0,
            type: EnemyType.runner,
            onDeath: _onEnemyDeath,
            onReachBase: _onEnemyReachBase,
            onMoved: _onEnemyMoved,
          );

          _registerEnemy(minion);
          add(minion);
        }
        break;
      // Future abilities can be handled here
      default:
        // For example, tower hacking, time manipulation, etc.
        break;
    }
  }

  void _onEnemyDeath(Enemy enemy) {
    _unregisterEnemy(enemy);

    // Spawn epic explosion effect at enemy position
    final expSize =
        (30.0 + (enemy.type.sizeMult * 20)) * (1 + enemy.threatTier * 0.15);
    final effect = ExplosionEffect.spawn(
      position: enemy.position,
      color: enemy.type.color,
      explosionSize: expSize,
      duration: 0.5 + (enemy.type == EnemyType.juggernaut ? 0.2 : 0),
    );
    if (effect != null) {
      add(effect);
    }

    // Spawn pixel disintegration effect for cyberpunk death visual
    final pixelEffect = PixelDisintegrationEffect.spawn(
      position: enemy.position,
      color: enemy.type.color,
      effectSize: expSize * 0.8,
      duration: 0.8 + (enemy.type == EnemyType.juggernaut ? 0.2 : 0),
    );
    if (pixelEffect != null) {
      add(pixelEffect);
    }

    onEnemyKilled?.call(enemy, enemy.goldReward);
    _checkWaveComplete();
  }

  void _onEnemyReachBase(Enemy enemy) {
    _unregisterEnemy(enemy);
    onEnemyLeaked?.call(enemy);
    _checkWaveComplete();
  }

  void _checkWaveComplete() {
    if (!spawning && _aliveCount <= 0) {
      onWaveComplete?.call(_currentWave);
    }
  }

  void _updateThreatPulse(double dt) {
    if (_activeEnemies.isEmpty) {
      _threatPulseTimer = 0;
      return;
    }

    if (_threatPulseTimer > 0) {
      _threatPulseTimer -= dt;
      return;
    }

    double maxProgress = 0.0;
    for (int i = 0; i < _activeEnemies.length; i++) {
      final enemy = _activeEnemies[i];
      if (!enemy.isAlive) continue;
      if (enemy.pathProgress > maxProgress) {
        maxProgress = enemy.pathProgress;
        if (maxProgress >= 1.0) break;
      }
    }

    if (maxProgress >= _nearBaseThreshold) {
      final intensity =
          ((maxProgress - _nearBaseThreshold) / (1 - _nearBaseThreshold))
              .clamp(0.0, 1.0);
      gameRef.triggerBaseThreat(intensity);
      _threatPulseTimer = _threatPulseInterval;
    } else {
      // Throttle the expensive scan when enemies are far from base.
      _threatPulseTimer = _threatPulseInterval * 0.35;
    }
  }

  /// Start a new wave with specified enemy count
  void startWave({int count = 5}) {
    if (spawning) return; // Don't interrupt ongoing wave

    _currentWave++;
    _spawnIndex = 0;
    _bossSpawned = false; // Reset boss spawn flag for new wave

    if (!_tuningReady) {
      _applyLevelTuning();
    }

    // Determine wave modifier
    _currentModifier = _selectModifierForWave(_currentWave);
    _waveEnemyPool
      ..clear()
      ..addAll(_getAvailableTypes());
    _waveModifierEnemyType = _currentModifier == WaveModifier.normal ||
            _currentModifier == WaveModifier.mixed
        ? null
        : _resolveModifierEnemyType(_waveEnemyPool, _currentModifier);

    // More enemies each wave, special waves have different counts
    var enemyCount = DifficultyCurve.enemyCount(
      baseCount: count,
      progressIndexValue: _progressIndex,
      wave: _currentWave,
      difficulty: _difficulty,
      minCount: minEnemyCount,
      maxCount: maxEnemyCount,
    );
    if (_currentModifier == WaveModifier.overload) {
      enemyCount = (enemyCount * 1.25).ceil(); // More but weaker
    } else if (_currentModifier == WaveModifier.juggernaut) {
      enemyCount = (enemyCount * 0.7)
          .ceil()
          .clamp(2, maxEnemyCount); // Fewer but stronger
    } else if (_currentModifier == WaveModifier.phantom) {
      enemyCount = (enemyCount * 0.85)
          .ceil()
          .clamp(3, maxEnemyCount); // Moderate count, tricky
    } else if (_currentModifier == WaveModifier.mixed) {
      enemyCount = (enemyCount * 1.1).ceil();
    }
    enemyCount = enemyCount.clamp(minEnemyCount, maxEnemyCount);

    remaining = enemyCount;
    _waveTotalEnemies = enemyCount;
    spawning = true;
    _timer = 0;
    var interval = DifficultyCurve.spawnInterval(
      progressIndexValue: _progressIndex,
      wave: _currentWave,
      difficulty: _difficulty,
    );
    if (_currentModifier == WaveModifier.overload) {
      interval *= 0.8;
    } else if (_currentModifier == WaveModifier.juggernaut) {
      interval *= 1.15;
    } else if (_currentModifier == WaveModifier.phantom) {
      interval *= 1.05;
    }
    _spawnInterval = interval.clamp(0.35, 1.6);
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
    _bossSpawned = false;
    _currentBoss = null;
    _activeEnemies.clear();
    _waveEnemyPool.clear();
    _waveModifierEnemyType = null;
    _clearSpatialIndex();
    _spatialIndexDirty = false;

    // Remove all existing enemies - iterate directly, avoid .toList() allocation
    final enemiesToRemove = children.whereType<Enemy>();
    for (final enemy in [...enemiesToRemove]) {
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
    _levelWorld = DifficultyCurve.worldForLevel(levelId);
    _localIndex = DifficultyCurve.localIndexForLevel(levelId);
    _progressIndex = DifficultyCurve.progressIndex(levelId: levelId);
    _difficulty = difficulty;
    _totalWavesInLevel = gameRef.levelConfig?.waves ?? 5;
    _tuningReady = true;
  }

  double _goldScaleForProgress() {
    final scale = 0.92 -
        (_levelWorld - 1) * 0.03 -
        (_localIndex - 1) * 0.006 -
        (_difficulty - 1) * 0.02;
    return scale.clamp(0.55, 0.95);
  }

  int _baseThreatTier() {
    int tier = 0;
    if (_currentWave >= 4 || _levelWorld >= 2) {
      tier = 1;
    }
    if (_currentWave >= 8 || _levelWorld >= 4) {
      tier = 2;
    }
    if (_currentWave >= 12 || _levelWorld >= 7) {
      tier = 3;
    }
    return tier;
  }

  int _resolveThreatTier() {
    var tier = _baseThreatTier();
    if (_currentModifier == WaveModifier.juggernaut) {
      tier = max(tier, 1);
    } else if (_currentModifier == WaveModifier.overload) {
      tier = max(tier, 1);
    }
    if (tier <= 0) return 0;
    final interval = switch (tier) {
      1 => 6,
      2 => 4,
      _ => 3,
    };
    if (_spawnIndex % interval != 0) {
      tier = max(0, tier - 1);
    }
    return tier;
  }

  List<EnemyType> _getAvailableTypes() {
    // Get world-specific enemies
    final worldEnemies = EnemyType.getWorldEnemies(_levelWorld);

    // If no world enemies (shouldn't happen), fallback to basic types
    if (worldEnemies.isEmpty) {
      return EnemyType.basicTypes;
    }

    // World 1: Progressive introduction
    if (_levelWorld == 1) {
      final pool = <EnemyType>[EnemyType.runner];
      if (_localIndex >= 3) pool.add(EnemyType.overloaded);
      if (_localIndex >= 5) pool.add(EnemyType.juggernaut);
      if (_localIndex >= 7) pool.add(EnemyType.phantom);
      return pool;
    }

    // Other worlds: Progressive unlock of world-specific enemies
    final pool = <EnemyType>[];

    // Always add the first enemy type of the world (the "basic" one)
    if (worldEnemies.isNotEmpty) {
      pool.add(worldEnemies[0]);
    }

    // Level 2+: Add second enemy type
    if (_localIndex >= 2 && worldEnemies.length > 1) {
      pool.add(worldEnemies[1]);
    }

    // Level 4+: Add third enemy type
    if (_localIndex >= 4 && worldEnemies.length > 2) {
      pool.add(worldEnemies[2]);
    }

    // Level 7+: Add fourth (usually tank) enemy type
    if (_localIndex >= 7 && worldEnemies.length > 3) {
      pool.add(worldEnemies[3]);
    }

    return pool.isEmpty ? EnemyType.basicTypes : pool;
  }

  /// Get the appropriate enemy type for wave modifier in current world
  EnemyType _getModifierEnemyType(WaveModifier modifier) {
    final worldEnemies = EnemyType.getWorldEnemies(_levelWorld);
    if (worldEnemies.isEmpty) {
      // Fallback to basic types
      switch (modifier) {
        case WaveModifier.overload:
          return EnemyType.overloaded;
        case WaveModifier.juggernaut:
          return EnemyType.juggernaut;
        case WaveModifier.phantom:
          return EnemyType.phantom;
        default:
          return EnemyType.runner;
      }
    }

    // Find appropriate enemy type based on modifier characteristics
    switch (modifier) {
      case WaveModifier.overload:
        // Fast enemy type (highest speed multiplier)
        return worldEnemies.reduce((a, b) => a.speedMult > b.speedMult ? a : b);

      case WaveModifier.juggernaut:
        // Tank enemy type (highest health multiplier)
        return worldEnemies
            .reduce((a, b) => a.healthMult > b.healthMult ? a : b);

      case WaveModifier.phantom:
        // Phantom type if available, otherwise fast phantom-like type
        final phantoms = worldEnemies.where((e) => e.isPhantom);
        if (phantoms.isNotEmpty) return phantoms.first;
        // Fallback to fastest for sneaky feel
        return worldEnemies.reduce((a, b) => a.speedMult > b.speedMult ? a : b);

      default:
        return worldEnemies.first;
    }
  }

  EnemyType _resolveModifierEnemyType(
      List<EnemyType> pool, WaveModifier modifier) {
    if (pool.isEmpty) return _getModifierEnemyType(modifier);
    switch (modifier) {
      case WaveModifier.overload:
        return pool.reduce((a, b) => a.speedMult > b.speedMult ? a : b);
      case WaveModifier.juggernaut:
        return pool.reduce((a, b) => a.healthMult > b.healthMult ? a : b);
      case WaveModifier.phantom:
        for (final enemy in pool) {
          if (enemy.isPhantom) return enemy;
        }
        return pool.reduce((a, b) => a.speedMult > b.speedMult ? a : b);
      default:
        return pool.first;
    }
  }

  WaveModifier _selectModifierForWave(int wave) {
    final pool = _getAvailableTypes();

    // Check if world has phantom-type enemies
    final hasPhantom = pool.any((e) => e.isPhantom);

    // Check if we have enough variety for special waves
    final hasEnoughTypes = pool.length >= 2;

    if (_levelWorld <= 1) {
      // World 1: Progressive introduction
      if (wave % 5 == 0 && pool.length >= 3) return WaveModifier.juggernaut;
      if (wave % 3 == 0 && pool.length >= 2) return WaveModifier.overload;
      return WaveModifier.normal;
    }

    if (_levelWorld == 2) {
      // World 2: Rift Wars - Phantom heavy
      if (wave % 6 == 0 && hasPhantom) return WaveModifier.phantom;
      if (wave % 5 == 0 && hasEnoughTypes) return WaveModifier.juggernaut;
      if (wave % 3 == 0 && hasEnoughTypes) return WaveModifier.overload;
      return WaveModifier.normal;
    }

    if (_levelWorld == 3) {
      // World 3: Signal Wastes - Mixed corruption
      if (wave % 7 == 0 && pool.length >= 3) return WaveModifier.mixed;
      if (wave % 4 == 0 && hasPhantom) return WaveModifier.phantom;
      if (wave % 5 == 0 && hasEnoughTypes) return WaveModifier.juggernaut;
      if (wave % 3 == 0 && hasEnoughTypes) return WaveModifier.overload;
      return WaveModifier.normal;
    }

    // Worlds 4-10: Full variety
    if (wave % 8 == 0 && pool.length >= 3) return WaveModifier.mixed;
    if (wave % 6 == 0 && hasPhantom) return WaveModifier.phantom;
    if (wave % 5 == 0 && hasEnoughTypes) return WaveModifier.juggernaut;
    if (wave % 3 == 0 && hasEnoughTypes) return WaveModifier.overload;
    return WaveModifier.normal;
  }
}
