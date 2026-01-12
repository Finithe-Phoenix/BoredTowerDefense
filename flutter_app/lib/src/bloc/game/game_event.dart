import 'package:equatable/equatable.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

/// Game started with level config
class GameStarted extends GameEvent {
  const GameStarted({
    required this.levelId,
    required this.startingGold,
    required this.startingLives,
    required this.totalWaves,
  });

  final int levelId;
  final int startingGold;
  final int startingLives;
  final int totalWaves;

  @override
  List<Object?> get props => [levelId, startingGold, startingLives, totalWaves];
}

/// Gold changed (earned or spent)
class GoldChanged extends GameEvent {
  const GoldChanged(this.amount);
  final int amount;

  @override
  List<Object?> get props => [amount];
}

/// Lives changed (enemy leaked)
class LivesChanged extends GameEvent {
  const LivesChanged(this.amount);
  final int amount;

  @override
  List<Object?> get props => [amount];
}

/// Score increased
class ScoreIncreased extends GameEvent {
  const ScoreIncreased(this.amount);
  final int amount;

  @override
  List<Object?> get props => [amount];
}

/// Wave started
class WaveStarted extends GameEvent {
  const WaveStarted(this.waveNumber);
  final int waveNumber;

  @override
  List<Object?> get props => [waveNumber];
}

/// Wave completed
class WaveCompleted extends GameEvent {
  const WaveCompleted(this.waveNumber);
  final int waveNumber;

  @override
  List<Object?> get props => [waveNumber];
}

/// Enemy killed
class EnemyKilled extends GameEvent {
  const EnemyKilled({required this.goldReward});
  final int goldReward;

  @override
  List<Object?> get props => [goldReward];
}

/// Enemy reached base
class EnemyLeaked extends GameEvent {
  const EnemyLeaked();
}

/// Tower placed
class TowerPlaced extends GameEvent {
  const TowerPlaced({required this.cost, required this.towerType});
  final int cost;
  final String towerType;

  @override
  List<Object?> get props => [cost, towerType];
}

/// Neon Pulse activated
class PulseActivated extends GameEvent {
  const PulseActivated({required this.cost});
  final int cost;

  @override
  List<Object?> get props => [cost];
}

/// Game paused/resumed
class GamePauseToggled extends GameEvent {
  const GamePauseToggled();
}

/// Game over
class GameOver extends GameEvent {
  const GameOver();
}

/// Victory
class Victory extends GameEvent {
  const Victory();
}

/// Reset game
class GameReset extends GameEvent {
  const GameReset();
}
