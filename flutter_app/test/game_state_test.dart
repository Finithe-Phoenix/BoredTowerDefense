import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/bloc/game/game_state.dart';

void main() {
  test('derived flags reflect status', () {
    const initial = GameState();
    expect(initial.isPlaying, isFalse);
    expect(initial.isGameEnded, isFalse);

    const playing = GameState(status: GameStatus.playing);
    expect(playing.isPlaying, isTrue);
    expect(playing.isGameEnded, isFalse);

    const victory = GameState(status: GameStatus.victory);
    expect(victory.isPlaying, isFalse);
    expect(victory.isGameEnded, isTrue);
  });

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

  test('wave and health progress clamp to totals', () {
    const state = GameState(currentWave: 3, totalWaves: 10, lives: 4, maxLives: 8);
    expect(state.waveProgress, closeTo(0.3, 0.0001));
    expect(state.healthPercent, closeTo(0.5, 0.0001));

    const zeroTotals = GameState(currentWave: 3, totalWaves: 0, lives: 4, maxLives: 0);
    expect(zeroTotals.waveProgress, 0);
    expect(zeroTotals.healthPercent, 0);
  });

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
    expect(updated.levelId, 4);
    expect(updated.score, 99);
    expect(updated.gold, 150);
    expect(updated.towersPlaced, 2);
  });
}
