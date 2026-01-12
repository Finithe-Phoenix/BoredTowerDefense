import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/projectile.dart';
import 'package:bored_games/src/game/entities/tower.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Projectile _makeProjectile(TowerType type) {
    return Projectile(
      startPosition: Vector2.zero(),
      targetPosition: Vector2(200, 0),
      speed: 120,
      damage: 10,
      towerType: type,
    );
  }

  test('projectile update does not throw for all tower types', () {
    for (final type in TowerType.values) {
      final projectile = _makeProjectile(type);
      expect(() => projectile.update(0.016), returnsNormally);
      expect(() => projectile.update(0.016), returnsNormally);
    }
  });

  test('projectile deactivates when starting near target', () {
    final projectile = Projectile(
      startPosition: Vector2.zero(),
      targetPosition: Vector2(1, 1),
      speed: 200,
      damage: 5,
    );

    expect(projectile.isActive, isTrue);
    projectile.update(0.016);
    expect(projectile.isActive, isFalse);
  });
}
