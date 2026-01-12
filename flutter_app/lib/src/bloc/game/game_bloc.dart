import 'package:flutter_bloc/flutter_bloc.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc() : super(const GameState()) {
    on<GameStarted>(_onGameStarted);
    on<GoldChanged>(_onGoldChanged);
    on<LivesChanged>(_onLivesChanged);
    on<ScoreIncreased>(_onScoreIncreased);
    on<WaveStarted>(_onWaveStarted);
    on<WaveCompleted>(_onWaveCompleted);
    on<EnemyKilled>(_onEnemyKilled);
    on<EnemyLeaked>(_onEnemyLeaked);
    on<TowerPlaced>(_onTowerPlaced);
    on<PulseActivated>(_onPulseActivated);
    on<GamePauseToggled>(_onGamePauseToggled);
    on<GameOver>(_onGameOver);
    on<Victory>(_onVictory);
    on<GameReset>(_onGameReset);
  }

  void _onGameStarted(GameStarted event, Emitter<GameState> emit) {
    emit(GameState(
      status: GameStatus.playing,
      levelId: event.levelId,
      gold: event.startingGold,
      lives: event.startingLives,
      maxLives: event.startingLives,
      totalWaves: event.totalWaves,
    ));
  }

  void _onGoldChanged(GoldChanged event, Emitter<GameState> emit) {
    if (state.isGameEnded) return;
    emit(state.copyWith(gold: state.gold + event.amount));
  }

  void _onLivesChanged(LivesChanged event, Emitter<GameState> emit) {
    if (state.isGameEnded) return;
    final newLives = (state.lives + event.amount).clamp(0, state.maxLives);
    emit(state.copyWith(lives: newLives));
  }

  void _onScoreIncreased(ScoreIncreased event, Emitter<GameState> emit) {
    if (state.isGameEnded) return;
    emit(state.copyWith(score: state.score + event.amount));
  }

  void _onWaveStarted(WaveStarted event, Emitter<GameState> emit) {
    if (state.isGameEnded) return;
    emit(state.copyWith(currentWave: event.waveNumber));
  }

  void _onWaveCompleted(WaveCompleted event, Emitter<GameState> emit) {
    if (state.isGameEnded) return;

    // Bonus gold for completing wave
    final bonusGold = 20 + (event.waveNumber * 5);
    final bonusScore = 50 * event.waveNumber;

    var newState = state.copyWith(
      gold: state.gold + bonusGold,
      score: state.score + bonusScore,
    );

    // Check for victory
    if (event.waveNumber >= state.totalWaves) {
      newState = newState.copyWith(status: GameStatus.victory);
    }

    emit(newState);
  }

  void _onEnemyKilled(EnemyKilled event, Emitter<GameState> emit) {
    if (state.isGameEnded) return;
    emit(state.copyWith(
      gold: state.gold + event.goldReward,
      score: state.score + 10,
      enemiesKilled: state.enemiesKilled + 1,
    ));
  }

  void _onEnemyLeaked(EnemyLeaked event, Emitter<GameState> emit) {
    if (state.isGameEnded) return;

    final newLives = state.lives - 1;
    if (newLives <= 0) {
      emit(state.copyWith(
        lives: 0,
        status: GameStatus.gameOver,
      ));
    } else {
      emit(state.copyWith(lives: newLives));
    }
  }

  void _onTowerPlaced(TowerPlaced event, Emitter<GameState> emit) {
    if (state.isGameEnded) return;
    if (state.gold < event.cost) return;

    emit(state.copyWith(
      gold: state.gold - event.cost,
      towersPlaced: state.towersPlaced + 1,
    ));
  }

  void _onPulseActivated(PulseActivated event, Emitter<GameState> emit) {
    if (state.isGameEnded) return;
    if (state.gold < event.cost) return;

    emit(state.copyWith(
      gold: state.gold - event.cost,
      pulsesUsed: state.pulsesUsed + 1,
    ));
  }

  void _onGamePauseToggled(GamePauseToggled event, Emitter<GameState> emit) {
    if (state.isGameEnded) return;

    if (state.status == GameStatus.paused) {
      emit(state.copyWith(status: GameStatus.playing));
    } else if (state.status == GameStatus.playing) {
      emit(state.copyWith(status: GameStatus.paused));
    }
  }

  void _onGameOver(GameOver event, Emitter<GameState> emit) {
    emit(state.copyWith(status: GameStatus.gameOver));
  }

  void _onVictory(Victory event, Emitter<GameState> emit) {
    emit(state.copyWith(status: GameStatus.victory));
  }

  void _onGameReset(GameReset event, Emitter<GameState> emit) {
    emit(const GameState());
  }
}
