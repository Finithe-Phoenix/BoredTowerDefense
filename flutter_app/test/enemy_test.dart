import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/enemy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('enemy with empty path reaches base on update', () {
    var reached = 0;
    final enemy = Enemy(
      path: const [],
      onReachBase: (_) => reached++,
    );

    enemy.update(0.016);
    expect(reached, 1);
  });

  test('enemy reaches end after single waypoint', () {
    var reached = 0;
    final enemy = Enemy(
      path: [Vector2(20, 0)],
      speed: 200,
      onReachBase: (_) => reached++,
    );

    enemy.update(0.016);
    expect(enemy.hasReachedBase, isTrue);
    enemy.update(0.016);
    expect(reached, 1);
  });

  test('slow effect expires after duration', () {
    final enemy = Enemy(
      path: const [],
      speed: 100,
    );
    final baseSpeed = enemy.speed;

    enemy.applySlow(0.5, 0.5);
    expect(enemy.speed, closeTo(baseSpeed * 0.5, 0.001));

    enemy.update(0.6);
    expect(enemy.speed, closeTo(baseSpeed, 0.001));
  });
}
