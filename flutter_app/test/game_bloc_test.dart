import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/bloc/game/game_bloc.dart';
import 'package:bored_games/src/bloc/game/game_event.dart';
import 'package:bored_games/src/bloc/game/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameBloc initial state', () {
    test('initial state is default GameState', () {
      final bloc = GameBloc();
      expect(bloc.state, const GameState());
      expect(bloc.state.status, GameStatus.initial);
      bloc.close();
    });
  });

  group('GameBloc GameStarted', () {
    test('GameStarted seeds initial playing state', () async {
      final bloc = GameBloc();

      final stateFuture = bloc.stream.first;
      bloc.add(const GameStarted(
        levelId: 2,
        startingGold: 150,
        startingLives: 12,
        totalWaves: 7,
      ));

      final state = await stateFuture;
      expect(state.status, GameStatus.playing);
      expect(state.levelId, 2);
      expect(state.gold, 150);
      expect(state.lives, 12);
      expect(state.maxLives, 12);
      expect(state.totalWaves, 7);

      await bloc.close();
    });

    test('GameStarted resets score and counters', () async {
      final bloc = GameBloc();

      final stateFuture = bloc.stream.first;
      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));

      final state = await stateFuture;
      expect(state.score, 0);
      expect(state.currentWave, 0);
      expect(state.enemiesKilled, 0);
      expect(state.towersPlaced, 0);
      expect(state.pulsesUsed, 0);

      await bloc.close();
    });
  });

  group('GameBloc GoldChanged', () {
    test('GoldChanged adds gold', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const GoldChanged(50));
      final state = await stateFuture;

      expect(state.gold, 150);

      await bloc.close();
    });

    test('GoldChanged can subtract gold', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const GoldChanged(-30));
      final state = await stateFuture;

      expect(state.gold, 70);

      await bloc.close();
    });

    test('GoldChanged ignores changes after game end', () async {
      final bloc = GameBloc();

      final endedFuture = bloc.stream.first;
      bloc.add(const GameOver());
      final ended = await endedFuture;
      expect(ended.status, GameStatus.gameOver);

      bloc.add(const GoldChanged(50));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.gold, ended.gold);

      await bloc.close();
    });
  });

  group('GameBloc LivesChanged', () {
    test('LivesChanged clamps to maxLives and enemy leaks end the game', () async {
      final bloc = GameBloc();

      final startedFuture = bloc.stream.first;
      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 3,
        totalWaves: 5,
      ));
      await startedFuture;

      bloc.add(const LivesChanged(10));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.lives, 3);

      final leakOneFuture = bloc.stream.firstWhere((state) => state.lives == 2);
      bloc.add(const EnemyLeaked());
      final afterLeak = await leakOneFuture;
      expect(afterLeak.lives, 2);

      final leakTwoFuture = bloc.stream.firstWhere((state) => state.lives == 1);
      bloc.add(const EnemyLeaked());
      await leakTwoFuture;
      final gameOverFuture = bloc.stream.firstWhere(
        (state) => state.status == GameStatus.gameOver,
      );
      bloc.add(const EnemyLeaked());
      final gameOver = await gameOverFuture;
      expect(gameOver.lives, 0);
      expect(gameOver.status, GameStatus.gameOver);

      await bloc.close();
    });

    test('LivesChanged can reduce lives', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const LivesChanged(-3));
      final state = await stateFuture;

      expect(state.lives, 7);

      await bloc.close();
    });

    test('LivesChanged clamps to 0', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 5,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const LivesChanged(-10));
      final state = await stateFuture;

      expect(state.lives, 0);

      await bloc.close();
    });
  });

  group('GameBloc ScoreIncreased', () {
    test('ScoreIncreased adds to score', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const ScoreIncreased(100));
      final state = await stateFuture;

      expect(state.score, 100);

      await bloc.close();
    });

    test('ScoreIncreased accumulates', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      bloc.add(const ScoreIncreased(50));
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const ScoreIncreased(30));
      final state = await stateFuture;

      expect(state.score, 80);

      await bloc.close();
    });
  });

  group('GameBloc WaveStarted', () {
    test('WaveStarted updates currentWave', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const WaveStarted(3));
      final state = await stateFuture;

      expect(state.currentWave, 3);

      await bloc.close();
    });
  });

  group('GameBloc WaveCompleted', () {
    test('WaveCompleted awards bonus and sets victory on last wave', () async {
      final bloc = GameBloc();

      final startedFuture = bloc.stream.first;
      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 5,
        totalWaves: 2,
      ));
      final started = await startedFuture;
      expect(started.gold, 100);

      final wave1Future = bloc.stream.first;
      bloc.add(const WaveCompleted(1));
      final wave1 = await wave1Future;
      expect(wave1.status, GameStatus.playing);
      expect(wave1.gold, 100 + 25);
      expect(wave1.score, 50);

      final wave2Future = bloc.stream.firstWhere(
        (state) => state.status == GameStatus.victory,
      );
      bloc.add(const WaveCompleted(2));
      final wave2 = await wave2Future;
      expect(wave2.status, GameStatus.victory);
      expect(wave2.gold, 100 + 25 + 30);

      await bloc.close();
    });

    test('WaveCompleted awards bonus gold based on wave number', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 10,
      ));
      await bloc.stream.first;

      // Wave 5 bonus = 20 + (5 * 5) = 45
      final stateFuture = bloc.stream.first;
      bloc.add(const WaveCompleted(5));
      final state = await stateFuture;

      expect(state.gold, 145);

      await bloc.close();
    });

    test('WaveCompleted awards bonus score based on wave number', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 10,
      ));
      await bloc.stream.first;

      // Wave 3 bonus = 50 * 3 = 150
      final stateFuture = bloc.stream.first;
      bloc.add(const WaveCompleted(3));
      final state = await stateFuture;

      expect(state.score, 150);

      await bloc.close();
    });
  });

  group('GameBloc EnemyKilled', () {
    test('EnemyKilled adds gold reward and score', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const EnemyKilled(goldReward: 15));
      final state = await stateFuture;

      expect(state.gold, 115);
      expect(state.score, 10);
      expect(state.enemiesKilled, 1);

      await bloc.close();
    });

    test('EnemyKilled increments enemiesKilled counter', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      bloc.add(const EnemyKilled(goldReward: 10));
      await bloc.stream.first;
      bloc.add(const EnemyKilled(goldReward: 10));
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const EnemyKilled(goldReward: 10));
      final state = await stateFuture;

      expect(state.enemiesKilled, 3);

      await bloc.close();
    });
  });

  group('GameBloc EnemyLeaked', () {
    test('EnemyLeaked reduces lives by 1', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const EnemyLeaked());
      final state = await stateFuture;

      expect(state.lives, 9);

      await bloc.close();
    });

    test('EnemyLeaked causes game over when lives reach 0', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 1,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      final stateFuture = bloc.stream.firstWhere(
        (s) => s.status == GameStatus.gameOver,
      );
      bloc.add(const EnemyLeaked());
      final state = await stateFuture;

      expect(state.lives, 0);
      expect(state.status, GameStatus.gameOver);

      await bloc.close();
    });
  });

  group('GameBloc TowerPlaced', () {
    test('TowerPlaced deducts gold and increments counter', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const TowerPlaced(cost: 50, towerType: 'pulseArcher'));
      final state = await stateFuture;

      expect(state.gold, 50);
      expect(state.towersPlaced, 1);

      await bloc.close();
    });

    test('TowerPlaced does nothing if not enough gold', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 30,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      bloc.add(const TowerPlaced(cost: 50, towerType: 'pulseArcher'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.gold, 30);
      expect(bloc.state.towersPlaced, 0);

      await bloc.close();
    });
  });

  group('GameBloc PulseActivated', () {
    test('PulseActivated deducts gold and increments counter', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const PulseActivated(cost: 25));
      final state = await stateFuture;

      expect(state.gold, 75);
      expect(state.pulsesUsed, 1);

      await bloc.close();
    });

    test('PulseActivated does nothing if not enough gold', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 20,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      bloc.add(const PulseActivated(cost: 25));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.gold, 20);
      expect(bloc.state.pulsesUsed, 0);

      await bloc.close();
    });
  });

  group('GameBloc GamePauseToggled', () {
    test('GamePauseToggled pauses playing game', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const GamePauseToggled());
      final state = await stateFuture;

      expect(state.status, GameStatus.paused);

      await bloc.close();
    });

    test('GamePauseToggled resumes paused game', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      bloc.add(const GamePauseToggled()); // Pause
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const GamePauseToggled()); // Resume
      final state = await stateFuture;

      expect(state.status, GameStatus.playing);

      await bloc.close();
    });

    test('GamePauseToggled does nothing when game ended', () async {
      final bloc = GameBloc();

      bloc.add(const GameOver());
      await bloc.stream.first;

      bloc.add(const GamePauseToggled());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.status, GameStatus.gameOver);

      await bloc.close();
    });
  });

  group('GameBloc GameOver', () {
    test('GameOver sets status to gameOver', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const GameOver());
      final state = await stateFuture;

      expect(state.status, GameStatus.gameOver);

      await bloc.close();
    });
  });

  group('GameBloc Victory', () {
    test('Victory sets status to victory', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const Victory());
      final state = await stateFuture;

      expect(state.status, GameStatus.victory);

      await bloc.close();
    });
  });

  group('GameBloc GameReset', () {
    test('GameReset returns to initial state', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 5,
        startingGold: 500,
        startingLives: 30,
        totalWaves: 15,
      ));
      await bloc.stream.first;

      final stateFuture = bloc.stream.first;
      bloc.add(const GameReset());
      final state = await stateFuture;

      expect(state, const GameState());
      expect(state.status, GameStatus.initial);

      await bloc.close();
    });
  });

  group('GameBloc ignores events after game end', () {
    test('ScoreIncreased ignored after victory', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      bloc.add(const Victory());
      await bloc.stream.first;

      final scoreBeforeEvent = bloc.state.score;
      bloc.add(const ScoreIncreased(1000));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.score, scoreBeforeEvent);

      await bloc.close();
    });

    test('WaveStarted ignored after game over', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      bloc.add(const GameOver());
      await bloc.stream.first;

      final waveBeforeEvent = bloc.state.currentWave;
      bloc.add(const WaveStarted(3));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.currentWave, waveBeforeEvent);

      await bloc.close();
    });

    test('EnemyKilled ignored after game over', () async {
      final bloc = GameBloc();

      bloc.add(const GameStarted(
        levelId: 1,
        startingGold: 100,
        startingLives: 10,
        totalWaves: 5,
      ));
      await bloc.stream.first;

      bloc.add(const GameOver());
      await bloc.stream.first;

      final goldBeforeEvent = bloc.state.gold;
      bloc.add(const EnemyKilled(goldReward: 50));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.gold, goldBeforeEvent);

      await bloc.close();
    });
  });
}
