import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/settings/settings_cubit.dart';
import '../../bloc/settings/settings_state.dart';
import '../../game/bored_games_game.dart';
import '../../models/level_config.dart';
import '../../services/level_service.dart';
import '../../services/procedural_music_service.dart';
import '../../services/ambient_soundscape_service.dart';
import '../../services/audio_service.dart';
import '../overlays/pause_menu_overlay.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/victory_overlay.dart';
import '../overlays/run_upgrade_overlay.dart';
import '../widgets/materialization_overlay.dart';
import '../overlays/briefing_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.levelId});

  final int levelId;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static int _sessionCount = 0;
  late BoredGamesGame _game;
  late LevelConfig _levelConfig;
  bool _isPaused = false;
  bool _showMaterialization = true;
  bool _showBriefing = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final level = LevelService.instance.getLevel(widget.levelId);
    _levelConfig = level ?? LevelService.instance.levels.first;
    _focusNode.requestFocus();

    _game = BoredGamesGame(
      levelConfig: _levelConfig,
      onGameOver: _handleGameOver,
      onVictory: _handleVictory,
    );

    // Apply initial graphics quality and particle intensity from settings
    // Must be done after build to access context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final settings = context.read<SettingsCubit>().state;
        _game.setGraphicsQualityFromSettings(settings.graphicsQuality);
        _game.setParticleIntensityFromSettings(settings.particleIntensity);
      }
    });

    // Start procedural music for this world
    _startMusic();
  }

  Future<void> _startMusic() async {
    // Determine world from level ID (1-10 = world 1, 11-20 = world 2, etc.)
    final worldId = ((_levelConfig.id - 1) ~/ 10) + 1;
    await ProceduralMusicService.instance.playWorldMusic(worldId);
    // Start ambient soundscape for immersive atmosphere
    await AmbientSoundscapeService.instance.playWorldAmbient(worldId);
  }

  void _handleGameOver() {
    _game.paused = true;

    // Play defeat music
    ProceduralMusicService.instance.playDefeat();

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

    // Play victory music
    ProceduralMusicService.instance.playVictory();

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
        ProceduralMusicService.instance.pause();
        AmbientSoundscapeService.instance.pause();
      } else {
        _game.overlays.remove('pause');
        ProceduralMusicService.instance.resume();
        AmbientSoundscapeService.instance.resume();
      }
    });
  }

  void _resumeGame() {
    setState(() {
      _isPaused = false;
      _game.paused = false;
      _game.overlays.remove('pause');
      ProceduralMusicService.instance.resume();
      AmbientSoundscapeService.instance.resume();
    });
  }

  void _restartLevel() {
    // CRITICAL: Cleanup old game before creating new one
    _game.onRemove();

    _game.overlays.clear();
    setState(() {
      _isPaused = false;
      _game = BoredGamesGame(
        levelConfig: _levelConfig,
        onGameOver: _handleGameOver,
        onVictory: _handleVictory,
      );
    });

    // Apply graphics quality and particle intensity to new game instance
    final settings = context.read<SettingsCubit>().state;
    _game.setGraphicsQualityFromSettings(settings.graphicsQuality);
    _game.setParticleIntensityFromSettings(settings.particleIntensity);

    // Restart music for this world
    _startMusic();
  }

  void _quitToMenu() {
    // CRITICAL: Cleanup game resources before navigation
    _game.onRemove();
    ProceduralMusicService.instance.stop();
    AmbientSoundscapeService.instance.stop();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _nextLevel() {
    // CRITICAL: Cleanup current game before navigation
    _game.onRemove();
    ProceduralMusicService.instance.stop();
    AmbientSoundscapeService.instance.stop();

    final nextLevelId = _levelConfig.id + 1;
    final nextLevel = LevelService.instance.getLevel(nextLevelId);

    if (nextLevel != null) {
      Navigator.pushReplacementNamed(context, '/game', arguments: nextLevelId);
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    // CRITICAL: Ensure game resources are cleaned up when screen is disposed
    _game.onRemove();
    ProceduralMusicService.instance.stop();
    AmbientSoundscapeService.instance.stop();
    AudioService.instance.reset();
    ProceduralMusicService.instance.reset();
    _refreshAudioIfNeeded();
    _focusNode.dispose();
    super.dispose();
  }

  void _refreshAudioIfNeeded() {
    _sessionCount += 1;
    if (_sessionCount % 5 == 0) {
      AudioService.instance.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsCubit, SettingsState>(
      listener: (context, state) {
        // Apply graphics quality and particle intensity changes in real-time
        _game.setGraphicsQualityFromSettings(state.graphicsQuality);
        _game.setParticleIntensityFromSettings(state.particleIntensity);
      },
      child: KeyboardListener(
        focusNode: _focusNode,
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

              // Materialization Overlay
              if (_showMaterialization)
                MaterializationOverlay(
                  onComplete: () {
                    setState(() {
                      _showMaterialization = false;
                      // Show briefing for level 1, 11, 21 (first levels of worlds)
                      if ([1, 11, 21].contains(widget.levelId)) {
                        _showBriefing = true;
                        _game.paused = true;
                      }
                    });
                  },
                ),

              if (_showBriefing)
                BriefingOverlay(
                  levelId: widget.levelId,
                  onDismiss: () {
                    setState(() {
                      _showBriefing = false;
                      _game.paused = false;
                    });
                  },
                ),
            ],
          ),
        ),
        ), // Scaffold
      ), // KeyboardListener
    ); // BlocListener
  }
}
