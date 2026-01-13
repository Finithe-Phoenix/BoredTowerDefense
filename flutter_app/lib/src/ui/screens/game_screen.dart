import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/bored_games_game.dart';
import '../../models/level_config.dart';
import '../../services/level_service.dart';
import '../overlays/pause_menu_overlay.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/victory_overlay.dart';
import '../overlays/run_upgrade_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.levelId});

  final int levelId;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late BoredGamesGame _game;
  late LevelConfig _levelConfig;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    final level = LevelService.instance.getLevel(widget.levelId);
    _levelConfig = level ?? LevelService.instance.levels.first;

    _game = BoredGamesGame(
      levelConfig: _levelConfig,
      onGameOver: _handleGameOver,
      onVictory: _handleVictory,
    );
  }

  void _handleGameOver() {
    _game.paused = true;

    // Save partial progress (best wave reached, high score if better)
    LevelService.instance.updateProgress(
      levelId: _levelConfig.id,
      completed: false,
      score: _game.score,
      wavesCleared: _game.enemyManager.currentWave,
      livesRemaining: 0,
      maxLives: _game.maxLives,
    ).then((_) {
      if (kDebugMode) {
        debugPrint('[GameScreen] Partial progress saved for level ${_levelConfig.id}');
      }
    });

    _game.overlays.add('gameOver');
  }

  void _handleVictory() {
    _game.paused = true;

    // Update and persist progress
    LevelService.instance.updateProgress(
      levelId: _levelConfig.id,
      completed: true,
      score: _game.score,
      wavesCleared: _game.enemyManager.currentWave,
      livesRemaining: _game.lives,
      maxLives: _game.maxLives,
    ).then((_) {
      if (kDebugMode) {
        debugPrint('[GameScreen] Progress saved for level ${_levelConfig.id}');
      }
    });

    _game.overlays.add('victory');
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      _game.paused = _isPaused;
      if (_isPaused) {
        _game.overlays.add('pause');
      } else {
        _game.overlays.remove('pause');
      }
    });
  }

  void _resumeGame() {
    setState(() {
      _isPaused = false;
      _game.paused = false;
      _game.overlays.remove('pause');
    });
  }

  void _restartLevel() {
    _game.overlays.clear();
    setState(() {
      _isPaused = false;
      _game = BoredGamesGame(
        levelConfig: _levelConfig,
        onGameOver: _handleGameOver,
        onVictory: _handleVictory,
      );
    });
  }

  void _quitToMenu() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _nextLevel() {
    final nextLevelId = _levelConfig.id + 1;
    final nextLevel = LevelService.instance.getLevel(nextLevelId);

    if (nextLevel != null) {
      Navigator.pushReplacementNamed(context, '/game', arguments: nextLevelId);
    } else {
      _quitToMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _togglePause();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              GameWidget(
                game: _game,
                overlayBuilderMap: {
                  'pause': (context, game) => PauseMenuOverlay(
                        onResume: _resumeGame,
                        onRestart: _restartLevel,
                        onQuit: _quitToMenu,
                      ),
                  'gameOver': (context, game) => GameOverOverlay(
                        score: _game.score,
                        wavesCleared: _game.enemyManager.currentWave,
                        onRestart: _restartLevel,
                        onQuit: _quitToMenu,
                      ),
                  'victory': (context, game) => VictoryOverlay(
                        score: _game.score,
                        livesRemaining: _game.lives,
                        maxLives: _game.maxLives,
                        onNextLevel: _nextLevel,
                        onRestart: _restartLevel,
                        onQuit: _quitToMenu,
                      ),
                  'upgrade': (context, game) => RunUpgradeOverlay(
                        game: _game,
                      ),
                },
              ),

              // Pause button
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    color: Colors.white.withOpacity(0.7),
                    size: 32,
                  ),
                  onPressed: _togglePause,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
