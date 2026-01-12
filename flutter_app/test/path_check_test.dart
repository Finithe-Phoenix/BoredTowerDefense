import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/utils/path_check.dart';

void main() {
  test('isPathOpen returns true when a path exists', () {
    final grid = [
      [true, true, true],
      [false, false, true],
      [true, true, true],
    ];

    final result = isPathOpen(
      buildableMask: grid,
      startCell: const Point<int>(0, 0),
      endCell: const Point<int>(2, 2),
    );

    expect(result, isTrue);
  });

  test('isPathOpen returns false when blocked', () {
    final grid = [
      [true, false, true],
      [true, false, true],
      [true, false, true],
    ];

    final result = isPathOpen(
      buildableMask: grid,
      startCell: const Point<int>(0, 1),
      endCell: const Point<int>(2, 1),
    );

    expect(result, isFalse);
  });
}
