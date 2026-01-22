import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/bloc/game/game_state.dart';

void main() {
  group('GameStatus', () {
    test('all status values exist', () {
      expect(GameStatus.values, contains(GameStatus.initial));
      expect(GameStatus.values, contains(GameStatus.playing));
      expect(GameStatus.values, contains(GameStatus.paused));
      expect(GameStatus.values, contains(GameStatus.gameOver));
      expect(GameStatus.values, contains(GameStatus.victory));
    });

    test('status count is 5', () {
      expect(GameStatus.values.length, 5);
    });
  });

  group('GameState default values', () {
    test('default constructor has expected values', () {
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

  group('GameState derived flags', () {
    test('isPlaying reflects status', () {
      const initial = GameState();
      expect(initial.isPlaying, isFalse);

      const playing = GameState(status: GameStatus.playing);
      expect(playing.isPlaying, isTrue);

      const paused = GameState(status: GameStatus.paused);
      expect(paused.isPlaying, isFalse);

      const victory = GameState(status: GameStatus.victory);
      expect(victory.isPlaying, isFalse);

      const gameOver = GameState(status: GameStatus.gameOver);
      expect(gameOver.isPlaying, isFalse);
    });

    test('isGameEnded reflects status', () {
      const initial = GameState();
      expect(initial.isGameEnded, isFalse);

      const playing = GameState(status: GameStatus.playing);
      expect(playing.isGameEnded, isFalse);

      const paused = GameState(status: GameStatus.paused);
      expect(paused.isGameEnded, isFalse);

      const victory = GameState(status: GameStatus.victory);
      expect(victory.isGameEnded, isTrue);

      const gameOver = GameState(status: GameStatus.gameOver);
      expect(gameOver.isGameEnded, isTrue);
    });
  });

  group('GameState starsEarned', () {
    test('starsEarned uses victory and life thresholds', () {
      const notWon = GameState(status: GameStatus.playing, lives: 5, maxLives: 5);
      expect(notWon.starsEarned, 0);

      const full = GameState(status: GameStatus.victory, lives: 10, maxLives: 10);
      expect(full.starsEarned, 3);

      const mid = GameState(status: GameStatus.victory, lives: 8, maxLives: 10);
      expect(mid.starsEarned, 2);

      const low = GameState(status: GameStatus.victory, lives: 3, maxLives: 10);
      expect(low.starsEarned, 1);
    });

    test('starsEarned returns 0 for non-victory states', () {
      for (final status in [
        GameStatus.initial,
        GameStatus.playing,
        GameStatus.paused,
        GameStatus.gameOver,
      ]) {
        final state = GameState(status: status, lives: 20, maxLives: 20);
        expect(state.starsEarned, 0);
      }
    });

    test('starsEarned edge cases', () {
      // Exactly at 75% threshold
      const at75 = GameState(status: GameStatus.victory, lives: 15, maxLives: 20);
      expect(at75.starsEarned, 2);

      // Just below 75% threshold
      const below75 = GameState(status: GameStatus.victory, lives: 14, maxLives: 20);
      expect(below75.starsEarned, 1);

      // Just above 75% threshold
      const above75 = GameState(status: GameStatus.victory, lives: 16, maxLives: 20);
      expect(above75.starsEarned, 2);

      // With 1 life remaining
      const oneLive = GameState(status: GameStatus.victory, lives: 1, maxLives: 20);
      expect(oneLive.starsEarned, 1);
    });
  });

  group('GameState waveProgress', () {
    test('wave progress calculates correctly', () {
      const state = GameState(currentWave: 3, totalWaves: 10);
      expect(state.waveProgress, closeTo(0.3, 0.0001));
    });

    test('wave progress at start', () {
      const state = GameState(currentWave: 0, totalWaves: 10);
      expect(state.waveProgress, 0.0);
    });

    test('wave progress at end', () {
      const state = GameState(currentWave: 10, totalWaves: 10);
      expect(state.waveProgress, 1.0);
    });

    test('wave progress with zero total waves', () {
      const state = GameState(currentWave: 5, totalWaves: 0);
      expect(state.waveProgress, 0);
    });
  });

  group('GameState healthPercent', () {
    test('health percent calculates correctly', () {
      const state = GameState(lives: 4, maxLives: 8);
      expect(state.healthPercent, closeTo(0.5, 0.0001));
    });

    test('health percent at full', () {
      const state = GameState(lives: 20, maxLives: 20);
      expect(state.healthPercent, 1.0);
    });

    test('health percent at zero', () {
      const state = GameState(lives: 0, maxLives: 20);
      expect(state.healthPercent, 0.0);
    });

    test('health percent with zero max lives', () {
      const state = GameState(lives: 5, maxLives: 0);
      expect(state.healthPercent, 0);
    });
  });

  group('GameState copyWith', () {
    test('copyWith preserves values when omitted', () {
      const base = GameState(
        status: GameStatus.playing,
        levelId: 4,
        gold: 120,
        lives: 12,
        maxLives: 15,
        score: 50,
        currentWave: 2,
        totalWaves: 8,
        enemiesKilled: 3,
        towersPlaced: 2,
        pulsesUsed: 1,
      );

      final updated = base.copyWith(score: 99, gold: 150);
      expect(updated.status, GameStatus.playing);
      expect(updated.levelId, 4);
      expect(updated.score, 99);
      expect(updated.gold, 150);
      expect(updated.lives, 12);
      expect(updated.maxLives, 15);
      expect(updated.currentWave, 2);
      expect(updated.totalWaves, 8);
      expect(updated.enemiesKilled, 3);
      expect(updated.towersPlaced, 2);
      expect(updated.pulsesUsed, 1);
    });

    test('copyWith can modify all fields', () {
      const base = GameState();
      final modified = base.copyWith(
        status: GameStatus.victory,
        levelId: 10,
        gold: 500,
        lives: 15,
        maxLives: 25,
        score: 10000,
        currentWave: 5,
        totalWaves: 5,
        enemiesKilled: 100,
        towersPlaced: 10,
        pulsesUsed: 5,
      );

      expect(modified.status, GameStatus.victory);
      expect(modified.levelId, 10);
      expect(modified.gold, 500);
      expect(modified.lives, 15);
      expect(modified.maxLives, 25);
      expect(modified.score, 10000);
      expect(modified.currentWave, 5);
      expect(modified.totalWaves, 5);
      expect(modified.enemiesKilled, 100);
      expect(modified.towersPlaced, 10);
      expect(modified.pulsesUsed, 5);
    });

    test('copyWith returns new instance', () {
      const base = GameState();
      final copy = base.copyWith();
      expect(identical(base, copy), isFalse);
    });
  });

  group('GameState Equatable', () {
    test('equal states have same props', () {
      const state1 = GameState(gold: 100, lives: 10);
      const state2 = GameState(gold: 100, lives: 10);
      expect(state1, equals(state2));
      expect(state1.props, equals(state2.props));
    });

    test('different states have different props', () {
      const state1 = GameState(gold: 100);
      const state2 = GameState(gold: 200);
      expect(state1, isNot(equals(state2)));
    });

    test('props includes all fields', () {
      const state = GameState(
        status: GameStatus.playing,
        levelId: 5,
        gold: 100,
        lives: 10,
        maxLives: 20,
        score: 500,
        currentWave: 3,
        totalWaves: 10,
        enemiesKilled: 50,
        towersPlaced: 5,
        pulsesUsed: 2,
      );
      expect(state.props.length, 11);
      expect(state.props, contains(GameStatus.playing));
      expect(state.props, contains(5)); // levelId
      expect(state.props, contains(100)); // gold
    });
  });
}
