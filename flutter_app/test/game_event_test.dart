import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/bloc/game/game_event.dart';

void main() {
  test('events with same props are equal', () {
    const a = GameStarted(
      levelId: 1,
      startingGold: 200,
      startingLives: 20,
      totalWaves: 10,
    );
    const b = GameStarted(
      levelId: 1,
      startingGold: 200,
      startingLives: 20,
      totalWaves: 10,
    );
    const c = GameStarted(
      levelId: 2,
      startingGold: 200,
      startingLives: 20,
      totalWaves: 10,
    );

    expect(a, equals(b));
    expect(a == c, isFalse);
  });

  test('simple events compare by type', () {
    const leak1 = EnemyLeaked();
    const leak2 = EnemyLeaked();
    const pause = GamePauseToggled();

    expect(leak1, equals(leak2));
    expect(leak1 == pause, isFalse);
  });
}
