import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/bored_games_game.dart';

void main() {
  group('PendingAbility', () {
    test('has all expected values', () {
      expect(PendingAbility.values, contains(PendingAbility.none));
      expect(PendingAbility.values, contains(PendingAbility.pulse));
      expect(PendingAbility.values, contains(PendingAbility.mine));
    });

    test('has exactly 3 values', () {
      expect(PendingAbility.values.length, 3);
    });
  });
}
