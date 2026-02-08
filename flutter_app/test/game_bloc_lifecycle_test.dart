// Tests for GameBloc full lifecycle, edge cases, and bonus calculations
// Rewritten without bloc_test dependency
import 'package:flutter_test/flutter_test.dart';
import 'package:bored_games/src/bloc/game/game_bloc.dart';
import 'package:bored_games/src/bloc/game/game_event.dart';
import 'package:bored_games/src/bloc/game/game_state.dart';

/// Helper: add event and wait for next state emission
Future<GameState> _addEvent(GameBloc bloc, GameEvent event) async {
  final future = bloc.stream.first;
  bloc.add(event);
  return future;
}

/// Helper: add event that should be ignored (no emission expected)
Future<void> _addIgnoredEvent(GameBloc bloc, GameEvent event) async {
  bloc.add(event);
  await Future.delayed(const Duration(milliseconds: 50));
}

void main() {
  group('GameBloc full game lifecycle', () {
    late GameBloc bloc;

    setUp(() {
      bloc = GameBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is correct', () {
      expect(bloc.state.status, GameStatus.initial);
      expect(bloc.state.gold, 200);
      expect(bloc.state.lives, 20);
      expect(bloc.state.score, 0);
      expect(bloc.state.currentWave, 0);
      expect(bloc.state.enemiesKilled, 0);
      expect(bloc.state.towersPlaced, 0);
    });

    test('full victory lifecycle: start → kills → waves → victory', () async {
      // Start game
      await _addEvent(bloc, const GameStarted(
        levelId: 1,
        startingGold: 200,
        startingLives: 20,
        totalWaves: 3,
      ));
      expect(bloc.state.status, GameStatus.playing);

      // Kill some enemies
      await _addEvent(bloc, const EnemyKilled(goldReward: 10));
      await _addEvent(bloc, const EnemyKilled(goldReward: 15));
      expect(bloc.state.enemiesKilled, 2);

      // Wave 1
      await _addEvent(bloc, const WaveStarted(1));
      await _addEvent(bloc, const WaveCompleted(1));
      // bonus gold = 20 + 5 = 25, bonus score = 50

      // Wave 2
      await _addEvent(bloc, const WaveStarted(2));
      await _addEvent(bloc, const WaveCompleted(2));
      // bonus gold = 20 + 10 = 30, bonus score = 100

      // Wave 3 - triggers victory
      await _addEvent(bloc, const WaveStarted(3));
      await _addEvent(bloc, const WaveCompleted(3));
      // bonus gold = 20 + 15 = 35, bonus score = 150

      expect(bloc.state.status, GameStatus.victory);
      expect(bloc.state.enemiesKilled, 2);
      // Gold: 200 + 10 + 15 + 25 + 30 + 35 = 315
      expect(bloc.state.gold, 315);
      // Score: 10 + 10 + 50 + 100 + 150 = 320
      expect(bloc.state.score, 320);
    });

    test('game over lifecycle: enemies leak until death', () async {
      await _addEvent(bloc, const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 3,
        totalWaves: 10,
      ));
      expect(bloc.state.status, GameStatus.playing);

      await _addEvent(bloc, const WaveStarted(1));
      await _addEvent(bloc, const EnemyLeaked());
      expect(bloc.state.lives, 2);

      await _addEvent(bloc, const EnemyLeaked());
      expect(bloc.state.lives, 1);

      await _addEvent(bloc, const EnemyLeaked()); // Dies here
      expect(bloc.state.status, GameStatus.gameOver);
      expect(bloc.state.lives, 0);
    });
  });

  group('GameBloc wave bonus calculations', () {
    test('wave 1 bonus: 25 gold, 50 score', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 10));
      await _addEvent(bloc, const WaveCompleted(1));

      // bonus gold = 20 + (1 * 5) = 25
      expect(bloc.state.gold, 125);
      // bonus score = 50 * 1 = 50
      expect(bloc.state.score, 50);
    });

    test('wave 5 bonus: 45 gold, 250 score', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 10));
      await _addEvent(bloc, const WaveCompleted(5));

      // bonus gold = 20 + (5 * 5) = 45
      expect(bloc.state.gold, 145);
      // bonus score = 50 * 5 = 250
      expect(bloc.state.score, 250);
    });

    test('wave 10 bonus: 70 gold, 500 score, triggers victory', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 10));
      await _addEvent(bloc, const WaveCompleted(10));

      // bonus gold = 20 + (10 * 5) = 70
      expect(bloc.state.gold, 170);
      // bonus score = 50 * 10 = 500
      expect(bloc.state.score, 500);
      // Wave 10 = totalWaves → victory
      expect(bloc.state.status, GameStatus.victory);
    });

    test('wave 0 bonus edge case', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 10));
      await _addEvent(bloc, const WaveCompleted(0));

      // bonus gold = 20 + (0 * 5) = 20
      expect(bloc.state.gold, 120);
      // bonus score = 50 * 0 = 0
      expect(bloc.state.score, 0);
    });

    test('cumulative wave bonuses', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 0, startingLives: 20, totalWaves: 5));

      await _addEvent(bloc, const WaveCompleted(1)); // +25g, +50s
      expect(bloc.state.gold, 25);
      expect(bloc.state.score, 50);

      await _addEvent(bloc, const WaveCompleted(2)); // +30g, +100s
      expect(bloc.state.gold, 55);
      expect(bloc.state.score, 150);

      await _addEvent(bloc, const WaveCompleted(3)); // +35g, +150s
      expect(bloc.state.gold, 90);
      expect(bloc.state.score, 300);
    });
  });

  group('GameBloc events after game ended', () {
    test('gold changes ignored after game over', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      // Reach game over
      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 1, totalWaves: 10));
      await _addEvent(bloc, const EnemyLeaked()); // Dies
      expect(bloc.state.status, GameStatus.gameOver);

      final goldBefore = bloc.state.gold;
      await _addIgnoredEvent(bloc, const GoldChanged(50));
      expect(bloc.state.gold, goldBefore);
    });

    test('enemy kills ignored after victory', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      // Reach victory
      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 1));
      await _addEvent(bloc, const WaveCompleted(1));
      expect(bloc.state.status, GameStatus.victory);

      final goldBefore = bloc.state.gold;
      final killsBefore = bloc.state.enemiesKilled;
      await _addIgnoredEvent(bloc, const EnemyKilled(goldReward: 20));
      expect(bloc.state.gold, goldBefore);
      expect(bloc.state.enemiesKilled, killsBefore);
    });

    test('wave starts ignored after game over', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 1, totalWaves: 10));
      await _addEvent(bloc, const EnemyLeaked());
      expect(bloc.state.status, GameStatus.gameOver);

      final waveBefore = bloc.state.currentWave;
      await _addIgnoredEvent(bloc, const WaveStarted(5));
      expect(bloc.state.currentWave, waveBefore);
    });

    test('tower placement ignored after victory', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 500, startingLives: 20, totalWaves: 1));
      await _addEvent(bloc, const WaveCompleted(1));
      expect(bloc.state.status, GameStatus.victory);

      final goldBefore = bloc.state.gold;
      await _addIgnoredEvent(bloc, const TowerPlaced(cost: 50, towerType: 'pulseArcher'));
      expect(bloc.state.gold, goldBefore);
    });

    test('pulse activation ignored after game over', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 500, startingLives: 1, totalWaves: 10));
      await _addEvent(bloc, const EnemyLeaked());
      expect(bloc.state.status, GameStatus.gameOver);

      final goldBefore = bloc.state.gold;
      await _addIgnoredEvent(bloc, const PulseActivated(cost: 30));
      expect(bloc.state.gold, goldBefore);
    });

    test('pause toggle ignored after game over', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 1, totalWaves: 10));
      await _addEvent(bloc, const EnemyLeaked());
      expect(bloc.state.status, GameStatus.gameOver);

      await _addIgnoredEvent(bloc, const GamePauseToggled());
      expect(bloc.state.status, GameStatus.gameOver);
    });

    test('score increase ignored after victory', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 1));
      await _addEvent(bloc, const WaveCompleted(1));
      expect(bloc.state.status, GameStatus.victory);

      final scoreBefore = bloc.state.score;
      await _addIgnoredEvent(bloc, const ScoreIncreased(100));
      expect(bloc.state.score, scoreBefore);
    });
  });

  group('GameBloc pause/resume', () {
    test('toggle from playing to paused', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 10));
      expect(bloc.state.status, GameStatus.playing);

      await _addEvent(bloc, const GamePauseToggled());
      expect(bloc.state.status, GameStatus.paused);
    });

    test('toggle from paused to playing', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 10));
      await _addEvent(bloc, const GamePauseToggled()); // → paused
      expect(bloc.state.status, GameStatus.paused);

      await _addEvent(bloc, const GamePauseToggled()); // → playing
      expect(bloc.state.status, GameStatus.playing);
    });

    test('toggle from initial state does nothing', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      expect(bloc.state.status, GameStatus.initial);
      await _addIgnoredEvent(bloc, const GamePauseToggled());
      expect(bloc.state.status, GameStatus.initial);
    });

    test('double toggle returns to playing', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 10));

      await _addEvent(bloc, const GamePauseToggled()); // → paused
      expect(bloc.state.status, GameStatus.paused);

      await _addEvent(bloc, const GamePauseToggled()); // → playing
      expect(bloc.state.status, GameStatus.playing);
    });
  });

  group('GameBloc lives clamping', () {
    test('lives clamped to maxLives when adding', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      // Start with 20 lives (maxLives=20)
      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 10));

      // Lose 2 lives via leaks
      await _addEvent(bloc, const EnemyLeaked());
      await _addEvent(bloc, const EnemyLeaked());
      expect(bloc.state.lives, 18);

      // Try to add 5 lives → should clamp to 20
      await _addEvent(bloc, const LivesChanged(5));
      expect(bloc.state.lives, 20);
    });

    test('lives clamped to 0 when subtracting', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 10));

      // Subtract more than current lives
      await _addEvent(bloc, const LivesChanged(-25));
      expect(bloc.state.lives, 0);
    });

    test('lives unchanged when adding zero', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 10, totalWaves: 10));
      expect(bloc.state.lives, 10);
      expect(bloc.state.maxLives, 10);

      // LivesChanged(0) produces same state, so no emission expected
      final stateBefore = bloc.state;
      await _addIgnoredEvent(bloc, const LivesChanged(0));
      expect(bloc.state, equals(stateBefore));
      expect(bloc.state.lives, 10);
    });
  });

  group('GameBloc gold mechanics', () {
    test('gold can go negative', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 10, startingLives: 20, totalWaves: 10));

      await _addEvent(bloc, const GoldChanged(-50));
      expect(bloc.state.gold, -40);
    });

    test('tower placement blocked without enough gold', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 30, startingLives: 20, totalWaves: 10));

      final goldBefore = bloc.state.gold;
      final towersBefore = bloc.state.towersPlaced;
      await _addIgnoredEvent(bloc, const TowerPlaced(cost: 50, towerType: 'pulseArcher'));
      expect(bloc.state.gold, goldBefore);
      expect(bloc.state.towersPlaced, towersBefore);
    });

    test('tower placement deducts gold exactly', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 10));

      await _addEvent(bloc, const TowerPlaced(cost: 50, towerType: 'pulseArcher'));
      expect(bloc.state.gold, 50);
      expect(bloc.state.towersPlaced, 1);
    });

    test('enemy kill rewards accumulate', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 10));

      await _addEvent(bloc, const EnemyKilled(goldReward: 10));
      await _addEvent(bloc, const EnemyKilled(goldReward: 20));
      await _addEvent(bloc, const EnemyKilled(goldReward: 5));

      expect(bloc.state.gold, 135); // 100 + 10 + 20 + 5
      expect(bloc.state.score, 30); // 3 × 10
      expect(bloc.state.enemiesKilled, 3);
    });

    test('pulse activation deducts gold', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 10));

      await _addEvent(bloc, const PulseActivated(cost: 30));
      expect(bloc.state.gold, 70);
      expect(bloc.state.pulsesUsed, 1);
    });

    test('pulse activation blocked without enough gold', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 20, startingLives: 20, totalWaves: 10));

      final goldBefore = bloc.state.gold;
      await _addIgnoredEvent(bloc, const PulseActivated(cost: 30));
      expect(bloc.state.gold, goldBefore);
    });

    test('multiple tower placements', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 200, startingLives: 20, totalWaves: 10));

      await _addEvent(bloc, const TowerPlaced(cost: 50, towerType: 'pulseArcher'));
      await _addEvent(bloc, const TowerPlaced(cost: 75, towerType: 'circuitCannon'));

      expect(bloc.state.gold, 75); // 200 - 50 - 75
      expect(bloc.state.towersPlaced, 2);
    });
  });

  group('GameBloc reset', () {
    test('reset returns to initial state', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 5, startingGold: 500, startingLives: 15, totalWaves: 10));
      await _addEvent(bloc, const EnemyKilled(goldReward: 50));
      await _addEvent(bloc, const TowerPlaced(cost: 100, towerType: 'pulseArcher'));

      await _addEvent(bloc, const GameReset());

      expect(bloc.state.status, GameStatus.initial);
      expect(bloc.state.gold, 200);
      expect(bloc.state.lives, 20);
      expect(bloc.state.score, 0);
      expect(bloc.state.currentWave, 0);
      expect(bloc.state.enemiesKilled, 0);
      expect(bloc.state.towersPlaced, 0);
    });

    test('reset after game over allows new game', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      // Start and die
      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 1, totalWaves: 10));
      await _addEvent(bloc, const EnemyLeaked());
      expect(bloc.state.status, GameStatus.gameOver);

      // Reset and start new game
      await _addEvent(bloc, const GameReset());
      expect(bloc.state.status, GameStatus.initial);

      await _addEvent(bloc, const GameStarted(
        levelId: 2, startingGold: 200, startingLives: 20, totalWaves: 5));
      expect(bloc.state.status, GameStatus.playing);
      expect(bloc.state.levelId, 2);
      expect(bloc.state.gold, 200);
      expect(bloc.state.lives, 20);
    });

    test('reset after victory allows new game', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 1));
      await _addEvent(bloc, const WaveCompleted(1));
      expect(bloc.state.status, GameStatus.victory);

      await _addEvent(bloc, const GameReset());
      await _addEvent(bloc, const GameStarted(
        levelId: 3, startingGold: 300, startingLives: 25, totalWaves: 15));
      expect(bloc.state.status, GameStatus.playing);
      expect(bloc.state.levelId, 3);
    });
  });

  group('GameBloc direct events', () {
    test('GameOver event sets game over status', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 10));
      await _addEvent(bloc, const GameOver());

      expect(bloc.state.status, GameStatus.gameOver);
    });

    test('Victory event sets victory status', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 10));
      await _addEvent(bloc, const Victory());

      expect(bloc.state.status, GameStatus.victory);
    });

    test('ScoreIncreased adds to score', () async {
      final bloc = GameBloc();
      addTearDown(() => bloc.close());

      await _addEvent(bloc, const GameStarted(
        levelId: 1, startingGold: 100, startingLives: 20, totalWaves: 10));
      await _addEvent(bloc, const ScoreIncreased(100));
      await _addEvent(bloc, const ScoreIncreased(50));

      expect(bloc.state.score, 150);
    });
  });

  group('GameState computed properties', () {
    test('starsEarned returns 3 at full health on victory', () {
      const state = GameState(
        status: GameStatus.victory,
        lives: 20,
        maxLives: 20,
      );
      expect(state.starsEarned, 3);
    });

    test('starsEarned returns 2 at 75%+ health on victory', () {
      const state = GameState(
        status: GameStatus.victory,
        lives: 16, // 80%
        maxLives: 20,
      );
      expect(state.starsEarned, 2);
    });

    test('starsEarned returns 1 below 75% health on victory', () {
      const state = GameState(
        status: GameStatus.victory,
        lives: 10, // 50%
        maxLives: 20,
      );
      expect(state.starsEarned, 1);
    });

    test('starsEarned returns 0 when not victory', () {
      const state = GameState(
        status: GameStatus.gameOver,
        lives: 20,
        maxLives: 20,
      );
      expect(state.starsEarned, 0);
    });

    test('starsEarned boundary: exactly 75%', () {
      const state = GameState(
        status: GameStatus.victory,
        lives: 15, // 75% exactly
        maxLives: 20,
      );
      expect(state.starsEarned, 2);
    });

    test('starsEarned boundary: just below 75%', () {
      const state = GameState(
        status: GameStatus.victory,
        lives: 14, // 70%
        maxLives: 20,
      );
      expect(state.starsEarned, 1);
    });

    test('waveProgress calculated correctly', () {
      const state = GameState(currentWave: 5, totalWaves: 10);
      expect(state.waveProgress, 0.5);
    });

    test('waveProgress zero when no waves', () {
      const state = GameState(currentWave: 0, totalWaves: 0);
      expect(state.waveProgress, 0);
    });

    test('healthPercent calculated correctly', () {
      const state = GameState(lives: 15, maxLives: 20);
      expect(state.healthPercent, 0.75);
    });

    test('healthPercent zero when maxLives is 0', () {
      const state = GameState(lives: 0, maxLives: 0);
      expect(state.healthPercent, 0);
    });

    test('isPlaying is true only for playing status', () {
      expect(const GameState(status: GameStatus.playing).isPlaying, isTrue);
      expect(const GameState(status: GameStatus.paused).isPlaying, isFalse);
      expect(const GameState(status: GameStatus.initial).isPlaying, isFalse);
    });

    test('isGameEnded is true for gameOver and victory', () {
      expect(const GameState(status: GameStatus.gameOver).isGameEnded, isTrue);
      expect(const GameState(status: GameStatus.victory).isGameEnded, isTrue);
      expect(const GameState(status: GameStatus.playing).isGameEnded, isFalse);
      expect(const GameState(status: GameStatus.initial).isGameEnded, isFalse);
    });

    test('GameState equality', () {
      const s1 = GameState(gold: 100, lives: 20);
      const s2 = GameState(gold: 100, lives: 20);
      const s3 = GameState(gold: 200, lives: 20);
      expect(s1, equals(s2));
      expect(s1, isNot(equals(s3)));
    });

    test('copyWith preserves unspecified fields', () {
      const state = GameState(
        status: GameStatus.playing,
        gold: 100,
        lives: 15,
        score: 500,
        currentWave: 3,
      );
      final copied = state.copyWith(gold: 200);
      expect(copied.gold, 200);
      expect(copied.status, GameStatus.playing);
      expect(copied.lives, 15);
      expect(copied.score, 500);
      expect(copied.currentWave, 3);
    });
  });
}
