import 'dart:async' as async;
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../game/bored_games_game.dart';
import '../../game/entities/tower.dart';
import '../../models/level_config.dart';
import '../../services/level_service.dart';
import '../theme/neon_theme.dart';
import '../widgets/cyber_grid_background.dart';
import '../widgets/tron_button.dart';

/// Benchmark screen that auto-plays the game to stress test
/// both device performance and game functionality
class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> with TickerProviderStateMixin {
  BoredGamesGame? _game;
  LevelConfig? _levelConfig;
  bool _gameReady = false;

  // Benchmark state
  bool _isRunning = false;
  bool _isComplete = false;
  double _elapsedTime = 0;
  double _minFps = double.infinity;
  double _maxFps = 0;
  double _avgFps = 0;
  final List<double> _fpsHistory = [];
  int _towersPlaced = 0;
  int _enemiesKilled = 0;
  int _wavesCompleted = 0;
  int _peakEnemies = 0;
  int _peakBullets = 0;
  int _currentEnemies = 0;
  int _currentBullets = 0;
  async.Timer? _autoPlayTimer;
  async.Timer? _statsTimer;
  async.Timer? _uiUpdateTimer;
  int _autoTowerIndex = 0;
  bool _needsUiUpdate = false;

  // Smart tower placement - positions near the path
  final List<Vector2> _goodTowerPositions = [];
  int _nextPositionIndex = 0;

  // Game speed control
  double _gameSpeed = 1.0;
  final List<double> _speedOptions = [1.0, 2.0, 5.0];

  // Tower placement order for auto-play (prioritize damage dealers)
  final List<TowerType> _towerOrder = [
    TowerType.pulseArcher,    // Fast, cheap, good early
    TowerType.circuitCannon,  // AOE damage
    TowerType.teslaTerminal,  // Chain lightning
    TowerType.ionSniper,      // High single target
    TowerType.phaseMage,      // Magic damage
    TowerType.glimmerField,   // Support/slow
  ];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    // Use level 1 as benchmark base
    final level = LevelService.instance.getLevel(1);
    _levelConfig = level ?? LevelService.instance.levels.first;
    _gameReady = false;

    _game = BoredGamesGame(
      levelConfig: _levelConfig!.copyWith(
        waves: 50, // 50 waves for stress testing
        startingGold: 999999, // Infinite gold for auto-placement
        startingLives: 9999, // Lots of lives - we want to stress test, not end early
      ),
      onGameOver: _onBenchmarkEnd,
      onVictory: _onBenchmarkEnd,
    )..hideHud = true; // Hide game HUD in benchmark mode

    // Wait for game to be fully loaded before allowing benchmark to start
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _gameReady = true;
        });
      }
    });
  }

  void _startBenchmark() {
    if (_game == null) return;

    setState(() {
      _isRunning = true;
      _isComplete = false;
      _elapsedTime = 0;
      _minFps = double.infinity;
      _maxFps = 0;
      _avgFps = 0;
      _fpsHistory.clear();
      _towersPlaced = 0;
      _enemiesKilled = 0;
      _wavesCompleted = 0;
      _peakEnemies = 0;
      _peakBullets = 0;
      _currentEnemies = 0;
      _currentBullets = 0;
      _autoTowerIndex = 0;
      _goodTowerPositions.clear();
      _nextPositionIndex = 0;
      _needsUiUpdate = false;
    });

    // Wait a bit for game to fully initialize, then start timers
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted || !_isRunning) return;
      _gameReady = true;

      // Calculate good tower positions near the enemy path
      _calculateSmartTowerPositions();

      // Start auto-play timer (place towers and manage game) - fast interval for aggressive stress testing
      _autoPlayTimer = async.Timer.periodic(const Duration(milliseconds: 200), _autoPlayTick);
      // Stats collection timer (frequent, but doesn't call setState)
      _statsTimer = async.Timer.periodic(const Duration(milliseconds: 100), _collectStats);
      // UI update timer (less frequent to avoid setState issues)
      _uiUpdateTimer = async.Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted && _needsUiUpdate) {
          _needsUiUpdate = false;
          setState(() {});
        }
      });
    });
  }

  /// Calculate smart tower positions near the enemy path
  void _calculateSmartTowerPositions() {
    if (_game == null || !_game!.isLoaded) return;
    final game = _game!;

    try {
      // Access the GameWorld through worldLayer, not world (which is Flame's World)
      final gameWorld = game.worldLayer;
      final waypoints = gameWorld.waypoints;
      if (waypoints.isEmpty) return;

      final tileSize = game.tileSize;
      final usedPositions = <String>{};

      // For each segment of the path, find buildable tiles nearby
      for (int i = 0; i < waypoints.length - 1; i++) {
        final start = waypoints[i];
        final end = waypoints[i + 1];

        // Sample points along this segment
        final segmentLength = (end - start).length;
        final numSamples = (segmentLength / tileSize).ceil();

        for (int s = 0; s <= numSamples; s++) {
          final t = numSamples > 0 ? s / numSamples : 0.0;
          final pathPoint = start + (end - start) * t;

          // Check tiles around this path point (1-3 tiles away)
          for (int dx = -3; dx <= 3; dx++) {
            for (int dy = -3; dy <= 3; dy++) {
              if (dx == 0 && dy == 0) continue; // Skip path tile itself

              final tileX = (pathPoint.x / tileSize).floor() + dx;
              final tileY = (pathPoint.y / tileSize).floor() + dy;

              // Check bounds
              if (tileX < 0 || tileY < 0 ||
                  tileX >= gameWorld.isBuildable.length ||
                  tileY >= gameWorld.isBuildable[0].length) continue;

              // Check if buildable
              if (!gameWorld.isBuildable[tileX][tileY]) continue;

              // Avoid duplicates
              final key = '$tileX,$tileY';
              if (usedPositions.contains(key)) continue;
              usedPositions.add(key);

              // Add position (center of tile)
              _goodTowerPositions.add(Vector2(
                tileX * tileSize + tileSize / 2,
                tileY * tileSize + tileSize / 2,
              ));
            }
          }
        }
      }

      // Sort by distance to first waypoint (prioritize early defense)
      if (waypoints.isNotEmpty) {
        final firstPoint = waypoints.first;
        _goodTowerPositions.sort((a, b) {
          final distA = (a - firstPoint).length;
          final distB = (b - firstPoint).length;
          return distA.compareTo(distB);
        });
      }
    } catch (e) {
      // Fall back to random if path calculation fails
    }
  }

  void _autoPlayTick(async.Timer timer) {
    if (!_isRunning || _isComplete || _game == null || !_gameReady) {
      timer.cancel();
      return;
    }

    final game = _game!;

    // Make sure game is fully loaded before accessing managers
    if (!game.isLoaded) return;

    try {
      // Auto-place towers - allow many towers for stress testing
      if (game.gold >= 50 && _towersPlaced < 100) {
        _tryPlaceTower();
      }

      // AGGRESSIVE WAVE SPAWNING for stress testing:
      // - Don't wait for all enemies to die
      // - Spawn new waves when enemy count drops below threshold
      // - Start new waves even while spawning (overlap waves)
      final currentEnemies = game.enemyManager.aliveCount;
      final waveNumber = game.enemyManager.currentWave;

      // Spawn new wave if enemy count is getting low (scales with wave number)
      final enemyThreshold = math.min(10 + waveNumber * 2, 50);
      if (currentEnemies < enemyThreshold && !game.enemyManager.spawning) {
        // Progressive difficulty: exponential increase in enemy count
        final baseEnemies = 10 + (waveNumber * 3);
        final enemyCount = math.min(baseEnemies, 40); // Cap at 40 enemies per wave for extreme stress
        game.startWave(count: enemyCount);
      }

      // Track kills
      _enemiesKilled = game.score ~/ 10; // Approximate from score
      _wavesCompleted = game.enemyManager.currentWave;
    } catch (e) {
      // Game not ready yet, skip this tick
    }
  }

  void _tryPlaceTower() {
    if (_game == null || !_game!.isLoaded) return;
    final game = _game!;

    try {
      final towerType = _towerOrder[_autoTowerIndex % _towerOrder.length];
      final cost = game.towerCost(towerType);

      if (game.gold < cost) return;

      // Select tower type
      game.towerManager.selectedTowerType = towerType;

      // SMART PLACEMENT: Use pre-calculated positions near the path
      if (_goodTowerPositions.isNotEmpty) {
        // Try positions from our smart list
        int attempts = 0;
        while (attempts < 10 && _nextPositionIndex < _goodTowerPositions.length) {
          final pos = _goodTowerPositions[_nextPositionIndex];
          _nextPositionIndex++;

          if (game.towerManager.placeTower(pos)) {
            game.gold -= cost;
            _towersPlaced++;
            _autoTowerIndex++;
            return;
          }
          attempts++;
        }

        // If we've exhausted good positions, reset and allow overlap check
        if (_nextPositionIndex >= _goodTowerPositions.length) {
          _nextPositionIndex = 0;
        }
      }

      // FALLBACK: Try random positions if smart placement fails
      final random = math.Random();
      final tileSize = game.tileSize;

      for (int attempt = 0; attempt < 20; attempt++) {
        final x = random.nextInt(15);
        final y = random.nextInt(15);
        final pos = Vector2(
          x * tileSize + tileSize / 2,
          y * tileSize + tileSize / 2,
        );

        if (game.towerManager.placeTower(pos)) {
          game.gold -= cost;
          _towersPlaced++;
          _autoTowerIndex++;
          return;
        }
      }
    } catch (e) {
      // Game not ready yet
    }
  }

  void _collectStats(async.Timer timer) {
    if (!_isRunning || _isComplete || _game == null || !_gameReady) {
      timer.cancel();
      return;
    }

    final game = _game!;

    // Make sure game is fully loaded
    if (!game.isLoaded) return;

    _elapsedTime += 0.1;

    try {
      // Track current and peak values
      _currentEnemies = game.enemyManager.aliveCount;
      _currentBullets = game.bulletManager.activeCount;
      _peakEnemies = math.max(_peakEnemies, _currentEnemies);
      _peakBullets = math.max(_peakBullets, _currentBullets);

      // Get real FPS from the game's refresh rate
      // Flame doesn't expose FPS directly, so we estimate from dt
      final currentFps = 1.0 / math.max(game.dt, 0.001);
      final clampedFps = currentFps.clamp(0.0, 144.0);

      _fpsHistory.add(clampedFps);
      // Keep history manageable (last 100 samples = 10 seconds)
      if (_fpsHistory.length > 100) {
        _fpsHistory.removeAt(0);
      }

      _minFps = math.min(_minFps, clampedFps);
      _maxFps = math.max(_maxFps, clampedFps);
      _avgFps = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
    } catch (e) {
      // Game not ready yet
    }

    // Signal that UI needs update (don't call setState directly here)
    _needsUiUpdate = true;
  }

  void _onBenchmarkEnd() {
    _isComplete = true;
    _isRunning = false;
    _autoPlayTimer?.cancel();
    _statsTimer?.cancel();
    _uiUpdateTimer?.cancel();
    if (mounted) setState(() {});
  }

  void _stopBenchmark() {
    _isRunning = false;
    _autoPlayTimer?.cancel();
    _statsTimer?.cancel();
    _uiUpdateTimer?.cancel();
    _onBenchmarkEnd();
  }

  void _restartBenchmark() {
    _autoPlayTimer?.cancel();
    _statsTimer?.cancel();
    _uiUpdateTimer?.cancel();
    _goodTowerPositions.clear();
    _nextPositionIndex = 0;
    setState(() {
      _isComplete = false;
      _gameSpeed = 1.0;
      _initGame();
    });
  }

  void _cycleSpeed() {
    final currentIndex = _speedOptions.indexOf(_gameSpeed);
    final nextIndex = (currentIndex + 1) % _speedOptions.length;
    setState(() {
      _gameSpeed = _speedOptions[nextIndex];
    });
    _game?.timeScale = _gameSpeed;
  }

  void _setSpeed(double speed) {
    setState(() {
      _gameSpeed = speed;
    });
    _game?.timeScale = _gameSpeed;
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _statsTimer?.cancel();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cache game reference to prevent flickering
    final game = _game;
    final isRunning = _isRunning;
    final isComplete = _isComplete;

    return Scaffold(
      body: Stack(
        children: [
          // Background - only show when no game
          if (!isRunning && !isComplete)
            const Positioned.fill(child: CyberGridBackground(child: SizedBox.expand())),

          // Game view
          if ((isRunning || isComplete) && game != null)
            Positioned.fill(
              child: GameWidget(game: game),
            ),

          // Safe area content
          SafeArea(
            child: Stack(
              children: [
                // Stats overlay - always show when game is active (don't flicker)
                if (isRunning && game != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: RepaintBoundary(
                      child: _buildStatsOverlay(),
                    ),
                  ),

                // Control buttons
                Positioned(
                  top: 10,
                  right: 10,
                  child: _buildControls(),
                ),

                // Start screen / Results overlay
                if (!isRunning && !isComplete)
                  _buildStartScreen(),

                if (isComplete)
                  _buildResultsOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGlowingIcon(Icons.speed_rounded, const Color(0xFFFF6600), 80),
            const SizedBox(height: 24),
            Text(
              'BENCHMARK MODE',
              style: NeonTextStyles.title.copyWith(
                color: const Color(0xFFFF6600),
                fontSize: 36,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sistema de prueba de rendimiento',
              style: NeonTextStyles.subtitle.copyWith(
                color: NeonColors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 48),
            _buildInfoCard(),
            const SizedBox(height: 48),
            TronButton(
              text: _game != null ? 'INICIAR BENCHMARK' : 'CARGANDO...',
              icon: Icons.play_arrow_rounded,
              onPressed: _startBenchmark,
              enabled: _game != null,
              color: const Color(0xFFFF6600),
              width: 280,
            ),
            const SizedBox(height: 20),
            TronButton(
              text: 'VOLVER',
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
              color: NeonColors.cyan,
              width: 280,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: Border.all(color: const Color(0xFFFF6600).withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6600).withOpacity(0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.auto_awesome, 'Torres automáticas'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.waves, 'Oleadas progresivas'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.analytics_outlined, 'Estadísticas en tiempo real'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.timer, 'Test de estrés del dispositivo'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF6600), size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: NeonTextStyles.body.copyWith(color: NeonColors.white.withOpacity(0.9)),
        ),
      ],
    );
  }

  Widget _buildGlowingIcon(IconData icon, Color color, double size) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.6), blurRadius: 30, spreadRadius: 5),
        ],
      ),
      child: Icon(icon, color: color, size: size),
    );
  }

  Widget _buildStatsOverlay() {
    // Compact modern design - semi-transparent pill-shaped stats
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6600).withOpacity(0.6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with title and speed controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6600).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speed, color: Color(0xFFFF6600), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'BENCHMARK',
                      style: NeonTextStyles.small.copyWith(
                        color: const Color(0xFFFF6600),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Compact speed buttons
              ..._speedOptions.map((speed) {
                final isSelected = _gameSpeed == speed;
                final label = 'x${speed.toInt()}';
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: GestureDetector(
                    onTap: () => _setSpeed(speed),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF6600) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFF6600) : Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          // Stats grid - compact 2 columns
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column - Performance
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompactStat('TIME', '${_elapsedTime.toStringAsFixed(0)}s', NeonColors.cyan),
                  _buildCompactStat('FPS', _avgFps.toStringAsFixed(0), _getFpsColor(_avgFps)),
                  _buildCompactStat('MIN', _minFps.isFinite ? _minFps.toStringAsFixed(0) : '-', Colors.white54),
                ],
              ),
              const SizedBox(width: 16),
              // Right column - Game stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompactStat('WAVE', '$_wavesCompleted', NeonColors.magenta),
                  _buildCompactStat('TWR', '$_towersPlaced', NeonColors.yellow),
                  _buildCompactStat('BLT', '$_currentBullets', _currentBullets > 200 ? NeonColors.red : NeonColors.green),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getFpsColor(double fps) {
    if (fps >= 55) return NeonColors.green;
    if (fps >= 30) return NeonColors.yellow;
    if (fps >= 15) return const Color(0xFFFF6600);
    return NeonColors.red;
  }

  Widget _buildCompactStat(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        if (_isRunning)
          IconButton(
            icon: const Icon(Icons.stop_rounded, color: Color(0xFFFF6600), size: 36),
            onPressed: _stopBenchmark,
          ),
        IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: NeonColors.cyan, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildResultsOverlay() {
    final grade = _calculateGrade();

    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: NeonColors.darkBg,
            border: Border.all(color: const Color(0xFFFF6600), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6600).withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGlowingIcon(Icons.analytics_rounded, const Color(0xFFFF6600), 60),
              const SizedBox(height: 20),
              Text(
                'BENCHMARK COMPLETO',
                style: NeonTextStyles.title.copyWith(
                  color: const Color(0xFFFF6600),
                  fontSize: 28,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),

              // Grade
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: grade.color, width: 2),
                  boxShadow: [
                    BoxShadow(color: grade.color.withOpacity(0.5), blurRadius: 20),
                  ],
                ),
                child: Text(
                  'GRADO: ${grade.letter}',
                  style: NeonTextStyles.title.copyWith(
                    color: grade.color,
                    fontSize: 32,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Results grid
              _buildResultsGrid(),
              const SizedBox(height: 32),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TronButton(
                    text: 'REINTENTAR',
                    icon: Icons.refresh_rounded,
                    onPressed: _restartBenchmark,
                    color: const Color(0xFFFF6600),
                    width: 180,
                  ),
                  TronButton(
                    text: 'SALIR',
                    icon: Icons.exit_to_app_rounded,
                    onPressed: () => Navigator.pop(context),
                    color: NeonColors.cyan,
                    width: 180,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildResultCard('TIEMPO', '${_elapsedTime.toStringAsFixed(1)}s', Icons.timer)),
            const SizedBox(width: 16),
            Expanded(child: _buildResultCard('FPS PROM', _avgFps.toStringAsFixed(1), Icons.speed)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildResultCard('FPS MIN', _minFps.isFinite ? _minFps.toStringAsFixed(1) : '-', Icons.trending_down)),
            const SizedBox(width: 16),
            Expanded(child: _buildResultCard('FPS MAX', _maxFps.toStringAsFixed(1), Icons.trending_up)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildResultCard('TORRES', '$_towersPlaced', Icons.cell_tower)),
            const SizedBox(width: 16),
            Expanded(child: _buildResultCard('OLEADAS', '$_wavesCompleted', Icons.waves)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildResultCard('PICO ENEM.', '$_peakEnemies', Icons.bug_report)),
            const SizedBox(width: 16),
            Expanded(child: _buildResultCard('PICO BALAS', '$_peakBullets', Icons.flash_on)),
          ],
        ),
      ],
    );
  }

  Widget _buildResultCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border.all(color: NeonColors.cyan.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: NeonColors.cyan, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: NeonTextStyles.small.copyWith(
                    color: NeonColors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: NeonTextStyles.body.copyWith(
                    color: NeonColors.cyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({String letter, Color color}) _calculateGrade() {
    // Grade based on average FPS
    if (_avgFps >= 55) return (letter: 'S', color: const Color(0xFFFFD700)); // Gold
    if (_avgFps >= 45) return (letter: 'A', color: NeonColors.green);
    if (_avgFps >= 35) return (letter: 'B', color: NeonColors.cyan);
    if (_avgFps >= 25) return (letter: 'C', color: NeonColors.yellow);
    if (_avgFps >= 15) return (letter: 'D', color: const Color(0xFFFF6600));
    return (letter: 'F', color: NeonColors.red);
  }
}
