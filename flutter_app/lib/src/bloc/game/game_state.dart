import 'package:equatable/equatable.dart';

enum GameStatus { initial, playing, paused, gameOver, victory }

class GameState extends Equatable {
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

  /// Whether the game is actively running
  bool get isPlaying => status == GameStatus.playing;

  /// Whether the game has ended (win or lose)
  bool get isGameEnded =>
      status == GameStatus.gameOver || status == GameStatus.victory;

  /// Stars earned based on lives remaining
  int get starsEarned {
    if (status != GameStatus.victory) return 0;
    if (lives == maxLives) return 3;
    if (lives >= maxLives * 0.75) return 2;
    return 1;
  }

  /// Progress through waves (0.0 - 1.0)
  double get waveProgress =>
      totalWaves > 0 ? currentWave / totalWaves : 0;

  /// Health percentage (0.0 - 1.0)
  double get healthPercent =>
      maxLives > 0 ? lives / maxLives : 0;

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

  @override
  List<Object?> get props => [
        status,
        levelId,
        gold,
        lives,
        maxLives,
        score,
        currentWave,
        totalWaves,
        enemiesKilled,
        towersPlaced,
        pulsesUsed,
      ];
}
