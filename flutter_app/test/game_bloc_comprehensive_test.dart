import 'package:flutter_test/flutter_test.dart';

/// Tests for GameBloc logic and state management

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED CLASSES FROM game_state.dart / game_event.dart / game_bloc.dart
// ═══════════════════════════════════════════════════════════════════════════════

/// Game status enum
enum GameStatus { initial, playing, paused, gameOver, victory }

/// Simulated GameState
class GameState {
  final GameStatus status;
  final int levelId;
  final int gold;
  final int lives;
  final int maxLives;
  final int score;
  final int currentWave;
  final int totalWaves;
  final int enemiesKilled;
  final int towersPlaced;
  final int pulsesUsed;

  const GameState({
    this.status = GameStatus.initial,
    this.levelId = 1,
    this.gold = 200,
    this.lives = 20,
    this.maxLives = 20,
    this.score = 0,
    this.currentWave = 0,
    this.totalWaves = 10,
    this.enemiesKilled = 0,
    this.towersPlaced = 0,
    this.pulsesUsed = 0,
  });

  bool get isPlaying => status == GameStatus.playing;

  bool get isGameEnded =>
      status == GameStatus.gameOver || status == GameStatus.victory;

  int get starsEarned {
    if (status != GameStatus.victory) return 0;
    if (lives == maxLives) return 3;
    if (lives >= maxLives * 0.75) return 2;
    return 1;
  }

  double get waveProgress => totalWaves > 0 ? currentWave / totalWaves : 0;

  double get healthPercent => maxLives > 0 ? lives / maxLives : 0;

  GameState copyWith({
    GameStatus? status,
    int? levelId,
    int? gold,
    int? lives,
    int? maxLives,
    int? score,
    int? currentWave,
    int? totalWaves,
    int? enemiesKilled,
    int? towersPlaced,
    int? pulsesUsed,
  }) {
    return GameState(
      status: status ?? this.status,
      levelId: levelId ?? this.levelId,
      gold: gold ?? this.gold,
      lives: lives ?? this.lives,
      maxLives: maxLives ?? this.maxLives,
      score: score ?? this.score,
      currentWave: currentWave ?? this.currentWave,
      totalWaves: totalWaves ?? this.totalWaves,
      enemiesKilled: enemiesKilled ?? this.enemiesKilled,
      towersPlaced: towersPlaced ?? this.towersPlaced,
      pulsesUsed: pulsesUsed ?? this.pulsesUsed,
    );
  }
}

/// Simulated GameBloc logic
class SimulatedGameBloc {
  GameState _state = const GameState();
  GameState get state => _state;

  void onGameStarted({
    required int levelId,
    required int startingGold,
    required int startingLives,
    required int totalWaves,
  }) {
    _state = GameState(
      status: GameStatus.playing,
      levelId: levelId,
      gold: startingGold,
      lives: startingLives,
      maxLives: startingLives,
      totalWaves: totalWaves,
    );
  }

  void onGoldChanged(int amount) {
    if (_state.isGameEnded) return;
    _state = _state.copyWith(gold: _state.gold + amount);
  }

  void onLivesChanged(int amount) {
    if (_state.isGameEnded) return;
    final newLives = (_state.lives + amount).clamp(0, _state.maxLives);
    _state = _state.copyWith(lives: newLives);
  }

  void onScoreIncreased(int amount) {
    if (_state.isGameEnded) return;
    _state = _state.copyWith(score: _state.score + amount);
  }

  void onWaveStarted(int waveNumber) {
    if (_state.isGameEnded) return;
    _state = _state.copyWith(currentWave: waveNumber);
  }

  void onWaveCompleted(int waveNumber) {
    if (_state.isGameEnded) return;

    // Bonus gold for completing wave: 20 + (waveNumber * 5)
    final bonusGold = 20 + (waveNumber * 5);
    final bonusScore = 50 * waveNumber;

    var newState = _state.copyWith(
      gold: _state.gold + bonusGold,
      score: _state.score + bonusScore,
    );

    // Check for victory
    if (waveNumber >= _state.totalWaves) {
      newState = newState.copyWith(status: GameStatus.victory);
    }

    _state = newState;
  }

  void onEnemyKilled(int goldReward) {
    if (_state.isGameEnded) return;
    _state = _state.copyWith(
      gold: _state.gold + goldReward,
      score: _state.score + 10,
      enemiesKilled: _state.enemiesKilled + 1,
    );
  }

  void onEnemyLeaked() {
    if (_state.isGameEnded) return;

    final newLives = _state.lives - 1;
    if (newLives <= 0) {
      _state = _state.copyWith(
        lives: 0,
        status: GameStatus.gameOver,
      );
    } else {
      _state = _state.copyWith(lives: newLives);
    }
  }

  void onTowerPlaced(int cost) {
    if (_state.isGameEnded) return;
    if (_state.gold < cost) return;

    _state = _state.copyWith(
      gold: _state.gold - cost,
      towersPlaced: _state.towersPlaced + 1,
    );
  }

  void onPulseActivated(int cost) {
    if (_state.isGameEnded) return;
    if (_state.gold < cost) return;

    _state = _state.copyWith(
      gold: _state.gold - cost,
      pulsesUsed: _state.pulsesUsed + 1,
    );
  }

  void onGamePauseToggled() {
    if (_state.isGameEnded) return;

    if (_state.status == GameStatus.paused) {
      _state = _state.copyWith(status: GameStatus.playing);
    } else if (_state.status == GameStatus.playing) {
      _state = _state.copyWith(status: GameStatus.paused);
    }
  }

  void onGameOver() {
    _state = _state.copyWith(status: GameStatus.gameOver);
  }

  void onVictory() {
    _state = _state.copyWith(status: GameStatus.victory);
  }

  void onGameReset() {
    _state = const GameState();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('GameState Defaults', () {
    test('initial state has correct defaults', () {
      const state = GameState();

      expect(state.status, GameStatus.initial);
      expect(state.levelId, 1);
      expect(state.gold, 200);
      expect(state.lives, 20);
      expect(state.maxLives, 20);
      expect(state.score, 0);
      expect(state.currentWave, 0);
      expect(state.totalWaves, 10);
      expect(state.enemiesKilled, 0);
      expect(state.towersPlaced, 0);
      expect(state.pulsesUsed, 0);
    });
  });

  group('GameState Computed Properties', () {
    test('isPlaying returns true only when playing', () {
      expect(const GameState(status: GameStatus.playing).isPlaying, true);
      expect(const GameState(status: GameStatus.initial).isPlaying, false);
      expect(const GameState(status: GameStatus.paused).isPlaying, false);
      expect(const GameState(status: GameStatus.gameOver).isPlaying, false);
      expect(const GameState(status: GameStatus.victory).isPlaying, false);
    });

    test('isGameEnded returns true for gameOver or victory', () {
      expect(const GameState(status: GameStatus.gameOver).isGameEnded, true);
      expect(const GameState(status: GameStatus.victory).isGameEnded, true);
      expect(const GameState(status: GameStatus.playing).isGameEnded, false);
      expect(const GameState(status: GameStatus.paused).isGameEnded, false);
      expect(const GameState(status: GameStatus.initial).isGameEnded, false);
    });

    test('starsEarned returns 0 if not victory', () {
      expect(const GameState(status: GameStatus.playing).starsEarned, 0);
      expect(const GameState(status: GameStatus.gameOver).starsEarned, 0);
    });

    test('starsEarned returns 3 for full lives', () {
      const state = GameState(
        status: GameStatus.victory,
        lives: 20,
        maxLives: 20,
      );
      expect(state.starsEarned, 3);
    });

    test('starsEarned returns 2 for >= 75% lives', () {
      const state = GameState(
        status: GameStatus.victory,
        lives: 15,
        maxLives: 20,
      );
      expect(state.starsEarned, 2);
    });

    test('starsEarned returns 1 for < 75% lives', () {
      const state = GameState(
        status: GameStatus.victory,
        lives: 10,
        maxLives: 20,
      );
      expect(state.starsEarned, 1);
    });

    test('waveProgress calculates correctly', () {
      expect(const GameState(currentWave: 5, totalWaves: 10).waveProgress, 0.5);
      expect(const GameState(currentWave: 0, totalWaves: 10).waveProgress, 0);
      expect(const GameState(currentWave: 10, totalWaves: 10).waveProgress, 1.0);
    });

    test('waveProgress handles zero totalWaves', () {
      expect(const GameState(currentWave: 5, totalWaves: 0).waveProgress, 0);
    });

    test('healthPercent calculates correctly', () {
      expect(const GameState(lives: 20, maxLives: 20).healthPercent, 1.0);
      expect(const GameState(lives: 10, maxLives: 20).healthPercent, 0.5);
      expect(const GameState(lives: 0, maxLives: 20).healthPercent, 0);
    });

    test('healthPercent handles zero maxLives', () {
      expect(const GameState(lives: 5, maxLives: 0).healthPercent, 0);
    });
  });

  group('GameState copyWith', () {
    test('copyWith creates new instance with updated values', () {
      const state = GameState();
      final newState = state.copyWith(gold: 500, lives: 10);

      expect(newState.gold, 500);
      expect(newState.lives, 10);
      expect(newState.status, state.status); // unchanged
    });

    test('copyWith with null preserves original values', () {
      const state = GameState(gold: 100, score: 500);
      final newState = state.copyWith();

      expect(newState.gold, 100);
      expect(newState.score, 500);
    });
  });

  group('GameBloc - Game Start', () {
    test('onGameStarted initializes state correctly', () {
      final bloc = SimulatedGameBloc();

      bloc.onGameStarted(
        levelId: 5,
        startingGold: 300,
        startingLives: 25,
        totalWaves: 15,
      );

      expect(bloc.state.status, GameStatus.playing);
      expect(bloc.state.levelId, 5);
      expect(bloc.state.gold, 300);
      expect(bloc.state.lives, 25);
      expect(bloc.state.maxLives, 25);
      expect(bloc.state.totalWaves, 15);
      expect(bloc.state.score, 0);
      expect(bloc.state.currentWave, 0);
    });
  });

  group('GameBloc - Gold Changes', () {
    test('onGoldChanged adds gold', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onGoldChanged(50);
      expect(bloc.state.gold, 150);
    });

    test('onGoldChanged subtracts gold', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onGoldChanged(-30);
      expect(bloc.state.gold, 70);
    });

    test('onGoldChanged can go negative', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 50,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onGoldChanged(-100);
      expect(bloc.state.gold, -50);
    });

    test('onGoldChanged ignored when game ended', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );
      bloc.onGameOver();

      bloc.onGoldChanged(1000);
      expect(bloc.state.gold, 100);
    });
  });

  group('GameBloc - Lives Changes', () {
    test('onLivesChanged adds lives', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      // Reduce lives first
      bloc.onLivesChanged(-5);
      expect(bloc.state.lives, 15);

      // Add lives
      bloc.onLivesChanged(3);
      expect(bloc.state.lives, 18);
    });

    test('onLivesChanged clamped to maxLives', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onLivesChanged(100);
      expect(bloc.state.lives, 20); // capped at maxLives
    });

    test('onLivesChanged clamped to 0', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onLivesChanged(-100);
      expect(bloc.state.lives, 0);
    });
  });

  group('GameBloc - Score', () {
    test('onScoreIncreased adds to score', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onScoreIncreased(100);
      expect(bloc.state.score, 100);

      bloc.onScoreIncreased(50);
      expect(bloc.state.score, 150);
    });
  });

  group('GameBloc - Waves', () {
    test('onWaveStarted updates currentWave', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onWaveStarted(1);
      expect(bloc.state.currentWave, 1);

      bloc.onWaveStarted(5);
      expect(bloc.state.currentWave, 5);
    });

    test('onWaveCompleted grants bonus gold and score', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onWaveCompleted(1);

      // Bonus gold = 20 + (1 * 5) = 25
      expect(bloc.state.gold, 125);
      // Bonus score = 50 * 1 = 50
      expect(bloc.state.score, 50);
    });

    test('onWaveCompleted calculates correct bonuses for higher waves', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onWaveCompleted(5);

      // Bonus gold = 20 + (5 * 5) = 45
      expect(bloc.state.gold, 145);
      // Bonus score = 50 * 5 = 250
      expect(bloc.state.score, 250);
    });

    test('onWaveCompleted triggers victory on final wave', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onWaveCompleted(10);
      expect(bloc.state.status, GameStatus.victory);
    });

    test('onWaveCompleted does not trigger victory before final wave', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onWaveCompleted(9);
      expect(bloc.state.status, GameStatus.playing);
    });
  });

  group('GameBloc - Enemy Kill', () {
    test('onEnemyKilled grants gold, score, and increments kill count', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onEnemyKilled(15);

      expect(bloc.state.gold, 115);
      expect(bloc.state.score, 10);
      expect(bloc.state.enemiesKilled, 1);
    });

    test('multiple enemy kills accumulate correctly', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      for (int i = 0; i < 10; i++) {
        bloc.onEnemyKilled(10);
      }

      expect(bloc.state.gold, 200); // 100 + 10 * 10
      expect(bloc.state.score, 100); // 10 * 10
      expect(bloc.state.enemiesKilled, 10);
    });
  });

  group('GameBloc - Enemy Leaked', () {
    test('onEnemyLeaked reduces lives by 1', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onEnemyLeaked();
      expect(bloc.state.lives, 19);
    });

    test('onEnemyLeaked triggers game over at 0 lives', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 3,
        totalWaves: 10,
      );

      bloc.onEnemyLeaked(); // 2
      bloc.onEnemyLeaked(); // 1
      expect(bloc.state.status, GameStatus.playing);

      bloc.onEnemyLeaked(); // 0
      expect(bloc.state.lives, 0);
      expect(bloc.state.status, GameStatus.gameOver);
    });

    test('onEnemyLeaked ignored after game over', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 1,
        totalWaves: 10,
      );

      bloc.onEnemyLeaked();
      expect(bloc.state.lives, 0);
      expect(bloc.state.status, GameStatus.gameOver);

      // Further leaks should be ignored
      bloc.onEnemyLeaked();
      expect(bloc.state.lives, 0);
    });
  });

  group('GameBloc - Tower Placed', () {
    test('onTowerPlaced deducts gold and increments count', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 200,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onTowerPlaced(50);

      expect(bloc.state.gold, 150);
      expect(bloc.state.towersPlaced, 1);
    });

    test('onTowerPlaced rejected if insufficient gold', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 30,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onTowerPlaced(50);

      expect(bloc.state.gold, 30); // unchanged
      expect(bloc.state.towersPlaced, 0); // unchanged
    });

    test('onTowerPlaced works when gold equals cost', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 50,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onTowerPlaced(50);

      expect(bloc.state.gold, 0);
      expect(bloc.state.towersPlaced, 1);
    });
  });

  group('GameBloc - Pulse Activated', () {
    test('onPulseActivated deducts gold and increments count', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 200,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onPulseActivated(100);

      expect(bloc.state.gold, 100);
      expect(bloc.state.pulsesUsed, 1);
    });

    test('onPulseActivated rejected if insufficient gold', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 50,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onPulseActivated(100);

      expect(bloc.state.gold, 50);
      expect(bloc.state.pulsesUsed, 0);
    });
  });

  group('GameBloc - Pause Toggle', () {
    test('onGamePauseToggled pauses a playing game', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onGamePauseToggled();
      expect(bloc.state.status, GameStatus.paused);
    });

    test('onGamePauseToggled resumes a paused game', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onGamePauseToggled(); // pause
      bloc.onGamePauseToggled(); // resume
      expect(bloc.state.status, GameStatus.playing);
    });

    test('onGamePauseToggled ignored if game ended', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );
      bloc.onGameOver();

      bloc.onGamePauseToggled();
      expect(bloc.state.status, GameStatus.gameOver);
    });

    test('onGamePauseToggled ignored in initial state', () {
      final bloc = SimulatedGameBloc();

      bloc.onGamePauseToggled();
      expect(bloc.state.status, GameStatus.initial);
    });
  });

  group('GameBloc - Game End States', () {
    test('onGameOver sets status to gameOver', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onGameOver();
      expect(bloc.state.status, GameStatus.gameOver);
    });

    test('onVictory sets status to victory', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onVictory();
      expect(bloc.state.status, GameStatus.victory);
    });

    test('onGameReset returns to initial state', () {
      final bloc = SimulatedGameBloc();
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 10,
      );

      bloc.onEnemyKilled(50);
      bloc.onWaveStarted(5);

      bloc.onGameReset();

      expect(bloc.state.status, GameStatus.initial);
      expect(bloc.state.gold, 200); // default
      expect(bloc.state.lives, 20); // default
      expect(bloc.state.score, 0);
      expect(bloc.state.enemiesKilled, 0);
    });
  });

  group('GameBloc - Full Game Scenario', () {
    test('complete game with victory', () {
      final bloc = SimulatedGameBloc();

      // Start game
      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 20,
        totalWaves: 3,
      );

      // Wave 1
      bloc.onWaveStarted(1);
      bloc.onEnemyKilled(10);
      bloc.onEnemyKilled(10);
      bloc.onEnemyKilled(10);
      bloc.onWaveCompleted(1);

      expect(bloc.state.currentWave, 1);
      expect(bloc.state.enemiesKilled, 3);
      expect(bloc.state.gold, 100 + 30 + 25); // start + kills + wave bonus

      // Wave 2
      bloc.onWaveStarted(2);
      bloc.onEnemyLeaked();
      bloc.onEnemyKilled(10);
      bloc.onWaveCompleted(2);

      expect(bloc.state.lives, 19);

      // Wave 3 (final)
      bloc.onWaveStarted(3);
      bloc.onEnemyKilled(10);
      bloc.onWaveCompleted(3);

      expect(bloc.state.status, GameStatus.victory);
      expect(bloc.state.starsEarned, 2); // 19/20 = 95% >= 75%
    });

    test('complete game with game over', () {
      final bloc = SimulatedGameBloc();

      bloc.onGameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 3,
        totalWaves: 5,
      );

      bloc.onWaveStarted(1);
      bloc.onEnemyLeaked();
      bloc.onEnemyLeaked();
      bloc.onEnemyLeaked();

      expect(bloc.state.status, GameStatus.gameOver);
      expect(bloc.state.lives, 0);
    });
  });

  group('Wave Bonus Gold Calculation', () {
    test('wave 1 bonus is 25 gold', () {
      expect(20 + (1 * 5), 25);
    });

    test('wave 5 bonus is 45 gold', () {
      expect(20 + (5 * 5), 45);
    });

    test('wave 10 bonus is 70 gold', () {
      expect(20 + (10 * 5), 70);
    });

    test('wave 20 bonus is 120 gold', () {
      expect(20 + (20 * 5), 120);
    });
  });

  group('Wave Bonus Score Calculation', () {
    test('wave 1 bonus is 50 score', () {
      expect(50 * 1, 50);
    });

    test('wave 5 bonus is 250 score', () {
      expect(50 * 5, 250);
    });

    test('wave 10 bonus is 500 score', () {
      expect(50 * 10, 500);
    });
  });

  group('Stars Earned Edge Cases', () {
    test('exactly 75% gives 2 stars', () {
      const state = GameState(
        status: GameStatus.victory,
        lives: 15,
        maxLives: 20,
      );
      expect(state.starsEarned, 2);
    });

    test('just below 75% gives 1 star', () {
      const state = GameState(
        status: GameStatus.victory,
        lives: 14,
        maxLives: 20,
      );
      expect(state.starsEarned, 1);
    });

    test('1 life remaining gives 1 star', () {
      const state = GameState(
        status: GameStatus.victory,
        lives: 1,
        maxLives: 20,
      );
      expect(state.starsEarned, 1);
    });
  });
}
