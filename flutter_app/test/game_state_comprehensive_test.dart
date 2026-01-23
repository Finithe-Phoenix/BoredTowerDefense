import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/bloc/game/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameStatus enum', () {
    test('GameStatus has initial value', () {
      expect(GameStatus.initial, isNotNull);
    });

    test('GameStatus has playing value', () {
      expect(GameStatus.playing, isNotNull);
    });

    test('GameStatus has paused value', () {
      expect(GameStatus.paused, isNotNull);
    });

    test('GameStatus has gameOver value', () {
      expect(GameStatus.gameOver, isNotNull);
    });

    test('GameStatus has victory value', () {
      expect(GameStatus.victory, isNotNull);
    });

    test('GameStatus has exactly 5 values', () {
      expect(GameStatus.values.length, 5);
    });

    test('GameStatus values are distinct', () {
      final values = GameStatus.values.toSet();
      expect(values.length, GameStatus.values.length);
    });

    test('GameStatus.initial has index 0', () {
      expect(GameStatus.initial.index, 0);
    });

    test('GameStatus.playing has index 1', () {
      expect(GameStatus.playing.index, 1);
    });

    test('GameStatus.paused has index 2', () {
      expect(GameStatus.paused.index, 2);
    });

    test('GameStatus.gameOver has index 3', () {
      expect(GameStatus.gameOver.index, 3);
    });

    test('GameStatus.victory has index 4', () {
      expect(GameStatus.victory.index, 4);
    });
  });

  group('GameState - Default constructor', () {
    test('default status is initial', () {
      const state = GameState();
      expect(state.status, GameStatus.initial);
    });

    test('default levelId is 1', () {
      const state = GameState();
      expect(state.levelId, 1);
    });

    test('default gold is 200', () {
      const state = GameState();
      expect(state.gold, 200);
    });

    test('default lives is 20', () {
      const state = GameState();
      expect(state.lives, 20);
    });

    test('default maxLives is 20', () {
      const state = GameState();
      expect(state.maxLives, 20);
    });

    test('default score is 0', () {
      const state = GameState();
      expect(state.score, 0);
    });

    test('default currentWave is 0', () {
      const state = GameState();
      expect(state.currentWave, 0);
    });

    test('default totalWaves is 10', () {
      const state = GameState();
      expect(state.totalWaves, 10);
    });

    test('default enemiesKilled is 0', () {
      const state = GameState();
      expect(state.enemiesKilled, 0);
    });

    test('default towersPlaced is 0', () {
      const state = GameState();
      expect(state.towersPlaced, 0);
    });

    test('default pulsesUsed is 0', () {
      const state = GameState();
      expect(state.pulsesUsed, 0);
    });
  });

  group('GameState - Custom constructor', () {
    test('custom status', () {
      const state = GameState(status: GameStatus.playing);
      expect(state.status, GameStatus.playing);
    });

    test('custom levelId', () {
      const state = GameState(levelId: 42);
      expect(state.levelId, 42);
    });

    test('custom gold', () {
      const state = GameState(gold: 500);
      expect(state.gold, 500);
    });

    test('custom lives', () {
      const state = GameState(lives: 15);
      expect(state.lives, 15);
    });

    test('custom maxLives', () {
      const state = GameState(maxLives: 30);
      expect(state.maxLives, 30);
    });

    test('custom score', () {
      const state = GameState(score: 1000);
      expect(state.score, 1000);
    });

    test('custom currentWave', () {
      const state = GameState(currentWave: 5);
      expect(state.currentWave, 5);
    });

    test('custom totalWaves', () {
      const state = GameState(totalWaves: 20);
      expect(state.totalWaves, 20);
    });

    test('custom enemiesKilled', () {
      const state = GameState(enemiesKilled: 100);
      expect(state.enemiesKilled, 100);
    });

    test('custom towersPlaced', () {
      const state = GameState(towersPlaced: 8);
      expect(state.towersPlaced, 8);
    });

    test('custom pulsesUsed', () {
      const state = GameState(pulsesUsed: 3);
      expect(state.pulsesUsed, 3);
    });

    test('all custom values', () {
      const state = GameState(
        status: GameStatus.victory,
        levelId: 50,
        gold: 999,
        lives: 18,
        maxLives: 25,
        score: 5000,
        currentWave: 10,
        totalWaves: 10,
        enemiesKilled: 250,
        towersPlaced: 12,
        pulsesUsed: 5,
      );

      expect(state.status, GameStatus.victory);
      expect(state.levelId, 50);
      expect(state.gold, 999);
      expect(state.lives, 18);
      expect(state.maxLives, 25);
      expect(state.score, 5000);
      expect(state.currentWave, 10);
      expect(state.totalWaves, 10);
      expect(state.enemiesKilled, 250);
      expect(state.towersPlaced, 12);
      expect(state.pulsesUsed, 5);
    });
  });

  group('GameState - isPlaying getter', () {
    test('isPlaying is false for initial', () {
      const state = GameState(status: GameStatus.initial);
      expect(state.isPlaying, isFalse);
    });

    test('isPlaying is true for playing', () {
      const state = GameState(status: GameStatus.playing);
      expect(state.isPlaying, isTrue);
    });

    test('isPlaying is false for paused', () {
      const state = GameState(status: GameStatus.paused);
      expect(state.isPlaying, isFalse);
    });

    test('isPlaying is false for gameOver', () {
      const state = GameState(status: GameStatus.gameOver);
      expect(state.isPlaying, isFalse);
    });

    test('isPlaying is false for victory', () {
      const state = GameState(status: GameStatus.victory);
      expect(state.isPlaying, isFalse);
    });
  });

  group('GameState - isGameEnded getter', () {
    test('isGameEnded is false for initial', () {
      const state = GameState(status: GameStatus.initial);
      expect(state.isGameEnded, isFalse);
    });

    test('isGameEnded is false for playing', () {
      const state = GameState(status: GameStatus.playing);
      expect(state.isGameEnded, isFalse);
    });

    test('isGameEnded is false for paused', () {
      const state = GameState(status: GameStatus.paused);
      expect(state.isGameEnded, isFalse);
    });

    test('isGameEnded is true for gameOver', () {
      const state = GameState(status: GameStatus.gameOver);
      expect(state.isGameEnded, isTrue);
    });

    test('isGameEnded is true for victory', () {
      const state = GameState(status: GameStatus.victory);
      expect(state.isGameEnded, isTrue);
    });
  });

  group('GameState - starsEarned getter', () {
    test('starsEarned is 0 for non-victory', () {
      const state = GameState(status: GameStatus.playing, lives: 20, maxLives: 20);
      expect(state.starsEarned, 0);
    });

    test('starsEarned is 0 for gameOver', () {
      const state = GameState(status: GameStatus.gameOver, lives: 20, maxLives: 20);
      expect(state.starsEarned, 0);
    });

    test('starsEarned is 3 for full health victory', () {
      const state = GameState(status: GameStatus.victory, lives: 20, maxLives: 20);
      expect(state.starsEarned, 3);
    });

    test('starsEarned is 2 for 75% health victory', () {
      const state = GameState(status: GameStatus.victory, lives: 15, maxLives: 20);
      expect(state.starsEarned, 2);
    });

    test('starsEarned is 2 for exactly 75% health', () {
      const state = GameState(status: GameStatus.victory, lives: 15, maxLives: 20);
      expect(state.starsEarned, 2);
    });

    test('starsEarned is 1 for less than 75% health', () {
      const state = GameState(status: GameStatus.victory, lives: 14, maxLives: 20);
      expect(state.starsEarned, 1);
    });

    test('starsEarned is 1 for 50% health', () {
      const state = GameState(status: GameStatus.victory, lives: 10, maxLives: 20);
      expect(state.starsEarned, 1);
    });

    test('starsEarned is 1 for 1 life remaining', () {
      const state = GameState(status: GameStatus.victory, lives: 1, maxLives: 20);
      expect(state.starsEarned, 1);
    });
  });

  group('GameState - starsEarned edge cases', () {
    test('starsEarned with maxLives 100', () {
      const state = GameState(status: GameStatus.victory, lives: 100, maxLives: 100);
      expect(state.starsEarned, 3);
    });

    test('starsEarned with 76% health', () {
      const state = GameState(status: GameStatus.victory, lives: 76, maxLives: 100);
      expect(state.starsEarned, 2);
    });

    test('starsEarned with 74% health', () {
      const state = GameState(status: GameStatus.victory, lives: 74, maxLives: 100);
      expect(state.starsEarned, 1);
    });

    test('starsEarned with different max lives values', () {
      for (int max = 10; max <= 50; max += 10) {
        final fullHealth = GameState(status: GameStatus.victory, lives: max, maxLives: max);
        expect(fullHealth.starsEarned, 3);

        final threeQuarter = GameState(
          status: GameStatus.victory,
          lives: (max * 0.75).ceil(),
          maxLives: max,
        );
        expect(threeQuarter.starsEarned, greaterThanOrEqualTo(2));
      }
    });
  });

  group('GameState - waveProgress getter', () {
    test('waveProgress is 0 at wave 0', () {
      const state = GameState(currentWave: 0, totalWaves: 10);
      expect(state.waveProgress, 0.0);
    });

    test('waveProgress is 0.5 at wave 5 of 10', () {
      const state = GameState(currentWave: 5, totalWaves: 10);
      expect(state.waveProgress, 0.5);
    });

    test('waveProgress is 1.0 at final wave', () {
      const state = GameState(currentWave: 10, totalWaves: 10);
      expect(state.waveProgress, 1.0);
    });

    test('waveProgress with 0 totalWaves', () {
      const state = GameState(currentWave: 5, totalWaves: 0);
      expect(state.waveProgress, 0.0);
    });

    test('waveProgress is 0.25 at wave 5 of 20', () {
      const state = GameState(currentWave: 5, totalWaves: 20);
      expect(state.waveProgress, 0.25);
    });
  });

  group('GameState - waveProgress precision', () {
    for (int wave = 0; wave <= 10; wave++) {
      test('waveProgress at wave $wave of 10', () {
        final state = GameState(currentWave: wave, totalWaves: 10);
        expect(state.waveProgress, closeTo(wave / 10, 0.0001));
      });
    }

    for (int wave = 0; wave <= 20; wave += 2) {
      test('waveProgress at wave $wave of 20', () {
        final state = GameState(currentWave: wave, totalWaves: 20);
        expect(state.waveProgress, closeTo(wave / 20, 0.0001));
      });
    }
  });

  group('GameState - healthPercent getter', () {
    test('healthPercent is 1.0 at full health', () {
      const state = GameState(lives: 20, maxLives: 20);
      expect(state.healthPercent, 1.0);
    });

    test('healthPercent is 0.5 at half health', () {
      const state = GameState(lives: 10, maxLives: 20);
      expect(state.healthPercent, 0.5);
    });

    test('healthPercent is 0.0 at 0 lives', () {
      const state = GameState(lives: 0, maxLives: 20);
      expect(state.healthPercent, 0.0);
    });

    test('healthPercent with 0 maxLives', () {
      const state = GameState(lives: 10, maxLives: 0);
      expect(state.healthPercent, 0.0);
    });

    test('healthPercent at 75%', () {
      const state = GameState(lives: 15, maxLives: 20);
      expect(state.healthPercent, 0.75);
    });
  });

  group('GameState - healthPercent precision', () {
    for (int lives = 0; lives <= 20; lives++) {
      test('healthPercent at $lives of 20 lives', () {
        final state = GameState(lives: lives, maxLives: 20);
        expect(state.healthPercent, closeTo(lives / 20, 0.0001));
      });
    }
  });

  group('GameState - copyWith', () {
    test('copyWith with no changes returns equal state', () {
      const original = GameState();
      final copy = original.copyWith();
      expect(copy, original);
    });

    test('copyWith status', () {
      const original = GameState();
      final copy = original.copyWith(status: GameStatus.playing);
      expect(copy.status, GameStatus.playing);
      expect(copy.gold, original.gold);
    });

    test('copyWith levelId', () {
      const original = GameState();
      final copy = original.copyWith(levelId: 42);
      expect(copy.levelId, 42);
      expect(copy.status, original.status);
    });

    test('copyWith gold', () {
      const original = GameState();
      final copy = original.copyWith(gold: 500);
      expect(copy.gold, 500);
    });

    test('copyWith lives', () {
      const original = GameState();
      final copy = original.copyWith(lives: 15);
      expect(copy.lives, 15);
    });

    test('copyWith maxLives', () {
      const original = GameState();
      final copy = original.copyWith(maxLives: 30);
      expect(copy.maxLives, 30);
    });

    test('copyWith score', () {
      const original = GameState();
      final copy = original.copyWith(score: 1000);
      expect(copy.score, 1000);
    });

    test('copyWith currentWave', () {
      const original = GameState();
      final copy = original.copyWith(currentWave: 5);
      expect(copy.currentWave, 5);
    });

    test('copyWith totalWaves', () {
      const original = GameState();
      final copy = original.copyWith(totalWaves: 20);
      expect(copy.totalWaves, 20);
    });

    test('copyWith enemiesKilled', () {
      const original = GameState();
      final copy = original.copyWith(enemiesKilled: 50);
      expect(copy.enemiesKilled, 50);
    });

    test('copyWith towersPlaced', () {
      const original = GameState();
      final copy = original.copyWith(towersPlaced: 8);
      expect(copy.towersPlaced, 8);
    });

    test('copyWith pulsesUsed', () {
      const original = GameState();
      final copy = original.copyWith(pulsesUsed: 3);
      expect(copy.pulsesUsed, 3);
    });

    test('copyWith multiple values', () {
      const original = GameState();
      final copy = original.copyWith(
        status: GameStatus.playing,
        gold: 300,
        lives: 18,
        currentWave: 2,
      );

      expect(copy.status, GameStatus.playing);
      expect(copy.gold, 300);
      expect(copy.lives, 18);
      expect(copy.currentWave, 2);
      expect(copy.levelId, original.levelId);
    });
  });

  group('GameState - Equatable', () {
    test('same values are equal', () {
      const state1 = GameState(gold: 100, lives: 10);
      const state2 = GameState(gold: 100, lives: 10);
      expect(state1, state2);
    });

    test('different status are not equal', () {
      const state1 = GameState(status: GameStatus.playing);
      const state2 = GameState(status: GameStatus.paused);
      expect(state1, isNot(state2));
    });

    test('different gold are not equal', () {
      const state1 = GameState(gold: 100);
      const state2 = GameState(gold: 200);
      expect(state1, isNot(state2));
    });

    test('different lives are not equal', () {
      const state1 = GameState(lives: 10);
      const state2 = GameState(lives: 20);
      expect(state1, isNot(state2));
    });

    test('props contains all fields', () {
      const state = GameState();
      expect(state.props.length, 11);
    });
  });

  group('GameState - Game simulation scenarios', () {
    test('start game scenario', () {
      const initial = GameState();
      final playing = initial.copyWith(status: GameStatus.playing);

      expect(initial.isPlaying, isFalse);
      expect(playing.isPlaying, isTrue);
    });

    test('damage taken scenario', () {
      const state = GameState(status: GameStatus.playing, lives: 20, maxLives: 20);
      final damaged = state.copyWith(lives: 15);

      expect(damaged.lives, 15);
      expect(damaged.healthPercent, 0.75);
    });

    test('gold earned scenario', () {
      const state = GameState(gold: 200);
      final earned = state.copyWith(gold: 250);
      expect(earned.gold, 250);
    });

    test('tower placed scenario', () {
      const state = GameState(gold: 200, towersPlaced: 0);
      final afterPlace = state.copyWith(gold: 150, towersPlaced: 1);

      expect(afterPlace.gold, 150);
      expect(afterPlace.towersPlaced, 1);
    });

    test('wave cleared scenario', () {
      const state = GameState(currentWave: 1, totalWaves: 10, enemiesKilled: 10);
      final nextWave = state.copyWith(currentWave: 2, enemiesKilled: 25);

      expect(nextWave.currentWave, 2);
      expect(nextWave.waveProgress, 0.2);
      expect(nextWave.enemiesKilled, 25);
    });

    test('victory scenario', () {
      const state = GameState(
        status: GameStatus.playing,
        lives: 18,
        maxLives: 20,
        currentWave: 10,
        totalWaves: 10,
      );
      final victory = state.copyWith(status: GameStatus.victory);

      expect(victory.status, GameStatus.victory);
      expect(victory.isGameEnded, isTrue);
      expect(victory.starsEarned, 2);
    });

    test('game over scenario', () {
      const state = GameState(
        status: GameStatus.playing,
        lives: 1,
        maxLives: 20,
      );
      final gameOver = state.copyWith(lives: 0, status: GameStatus.gameOver);

      expect(gameOver.status, GameStatus.gameOver);
      expect(gameOver.isGameEnded, isTrue);
      expect(gameOver.healthPercent, 0.0);
    });

    test('pause and resume scenario', () {
      const playing = GameState(status: GameStatus.playing);
      final paused = playing.copyWith(status: GameStatus.paused);
      final resumed = paused.copyWith(status: GameStatus.playing);

      expect(playing.isPlaying, isTrue);
      expect(paused.isPlaying, isFalse);
      expect(resumed.isPlaying, isTrue);
    });
  });

  group('GameState - Full game progression', () {
    test('complete game from start to victory', () {
      // Initial state
      const initial = GameState();
      expect(initial.status, GameStatus.initial);

      // Start playing
      final playing = initial.copyWith(status: GameStatus.playing);
      expect(playing.isPlaying, isTrue);

      // Wave 1
      final wave1 = playing.copyWith(
        currentWave: 1,
        enemiesKilled: 10,
        gold: 250,
      );
      expect(wave1.waveProgress, 0.1);

      // Place tower
      final tower1 = wave1.copyWith(
        gold: 200,
        towersPlaced: 1,
      );
      expect(tower1.towersPlaced, 1);

      // Take damage
      final damaged = tower1.copyWith(lives: 18);
      expect(damaged.healthPercent, 0.9);

      // Progress to wave 5
      final wave5 = damaged.copyWith(
        currentWave: 5,
        enemiesKilled: 75,
        gold: 350,
        towersPlaced: 4,
        pulsesUsed: 2,
      );
      expect(wave5.waveProgress, 0.5);

      // Final wave
      final finalWave = wave5.copyWith(
        currentWave: 10,
        enemiesKilled: 200,
        lives: 15,
      );
      expect(finalWave.waveProgress, 1.0);

      // Victory!
      final victory = finalWave.copyWith(status: GameStatus.victory);
      expect(victory.isGameEnded, isTrue);
      expect(victory.starsEarned, 2); // 15/20 = 75%
    });

    test('game over progression', () {
      const initial = GameState();
      final playing = initial.copyWith(status: GameStatus.playing);

      var state = playing;
      for (int i = 20; i > 0; i--) {
        state = state.copyWith(lives: i);
        expect(state.healthPercent, closeTo(i / 20, 0.0001));
      }

      final gameOver = state.copyWith(lives: 0, status: GameStatus.gameOver);
      expect(gameOver.isGameEnded, isTrue);
      expect(gameOver.healthPercent, 0.0);
    });
  });

  group('GameState - Edge cases', () {
    test('negative gold is allowed', () {
      const state = GameState(gold: -100);
      expect(state.gold, -100);
    });

    test('negative lives is allowed', () {
      const state = GameState(lives: -5);
      expect(state.lives, -5);
      expect(state.healthPercent, lessThan(0));
    });

    test('currentWave greater than totalWaves', () {
      const state = GameState(currentWave: 15, totalWaves: 10);
      expect(state.waveProgress, 1.5);
    });

    test('very large values', () {
      const state = GameState(
        gold: 999999,
        score: 9999999,
        enemiesKilled: 99999,
      );
      expect(state.gold, 999999);
      expect(state.score, 9999999);
    });

    test('zero total waves', () {
      const state = GameState(currentWave: 5, totalWaves: 0);
      expect(state.waveProgress, 0.0);
    });

    test('zero max lives', () {
      const state = GameState(lives: 10, maxLives: 0);
      expect(state.healthPercent, 0.0);
    });
  });
}
