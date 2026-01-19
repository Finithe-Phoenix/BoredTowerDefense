import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/bloc/game/game_bloc.dart';
import 'package:bored_games/src/bloc/game/game_event.dart';
import 'package:bored_games/src/bloc/game/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
}
