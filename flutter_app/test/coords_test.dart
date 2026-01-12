import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/utils/coords.dart';

void main() {
  test('screenToGrid floors positions to grid cells', () {
    expect(screenToGrid(Vector2.zero(), 32), const Point<int>(0, 0));
    expect(screenToGrid(Vector2(31.9, 0), 32), const Point<int>(0, 0));
    expect(screenToGrid(Vector2(32, 64), 32), const Point<int>(1, 2));
  });

  test('gridToWorld maps grid cells to world coordinates', () {
    final world = gridToWorld(const Point<int>(2, 3), 32);
    expect(world.x, 64);
    expect(world.y, 96);
  });
}
