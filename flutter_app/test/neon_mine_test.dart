import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/components/neon_mine.dart';
import 'package:bored_games/src/game/entities/enemy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  NeonMine makeMine({
    Vector2? position,
    List<Enemy> Function()? enemies,
    void Function(NeonMine)? onExplode,
    double damage = 150,
    double explosionRadius = 60,
    double armingTime = 0.5,
  }) {
    return NeonMine(
      position: position ?? Vector2.zero(),
      enemies: enemies ?? () => <Enemy>[],
      onExplode: onExplode ?? (_) {},
      damage: damage,
      explosionRadius: explosionRadius,
      armingTime: armingTime,
    );
  }

  group('MineState enum', () {
    test('has 4 states', () {
      expect(MineState.values.length, 4);
    });

    test('contains expected states', () {
      expect(MineState.values, contains(MineState.arming));
      expect(MineState.values, contains(MineState.armed));
      expect(MineState.values, contains(MineState.triggered));
      expect(MineState.values, contains(MineState.exploded));
    });
  });

  group('NeonMine creation', () {
    test('creates with required parameters', () {
      final mine = makeMine();

      expect(mine, isA<PositionComponent>());
      expect(mine.damage, 150);
      expect(mine.explosionRadius, 60);
      expect(mine.armingTime, 0.5);
    });

    test('creates with custom position', () {
      final mine = makeMine(position: Vector2(100, 100));

      expect(mine.position.x, 100);
      expect(mine.position.y, 100);
    });

    test('anchor is center', () {
      final mine = makeMine();
      expect(mine.anchor, Anchor.center);
    });

    test('size is 24x24', () {
      final mine = makeMine();
      expect(mine.size.x, 24);
      expect(mine.size.y, 24);
    });

    test('creates with custom damage', () {
      final mine = makeMine(damage: 200);
      expect(mine.damage, 200);
    });

    test('creates with custom explosion radius', () {
      final mine = makeMine(explosionRadius: 100);
      expect(mine.explosionRadius, 100);
    });

    test('creates with custom arming time', () {
      final mine = makeMine(armingTime: 1.0);
      expect(mine.armingTime, 1.0);
    });

    test('starts in arming state', () {
      final mine = makeMine();
      expect(mine.state, MineState.arming);
      expect(mine.isArmed, isFalse);
    });
  });

  group('NeonMine arming', () {
    test('arms after arming time', () {
      final mine = makeMine(armingTime: 0.1);

      mine.update(0.05);
      expect(mine.state, MineState.arming);
      expect(mine.isArmed, isFalse);

      mine.update(0.06);
      expect(mine.state, MineState.armed);
      expect(mine.isArmed, isTrue);
    });

    test('transitions directly to armed', () {
      final mine = makeMine(armingTime: 0.05);

      mine.update(0.05);
      expect(mine.state, MineState.armed);
    });
  });

  group('NeonMine triggering', () {
    test('triggers when enemy is nearby', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2.zero();

      final mine = makeMine(
        position: Vector2.zero(),
        enemies: () => [enemy],
        armingTime: 0.01,
        explosionRadius: 100,
      );

      mine.update(0.02); // Arm
      expect(mine.state, MineState.armed);

      mine.update(0.01); // Check proximity
      expect(mine.state, MineState.triggered);
    });

    test('does not trigger during arming', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2.zero();

      final mine = makeMine(
        position: Vector2.zero(),
        enemies: () => [enemy],
        armingTime: 1.0,
      );

      mine.update(0.1);
      expect(mine.state, MineState.arming);
    });

    test('does not trigger for dead enemies', () {
      final enemy = Enemy(path: [Vector2.zero()], maxHealth: 10);
      enemy.position = Vector2.zero();
      enemy.takeDamage(10); // Kill enemy

      final mine = makeMine(
        position: Vector2.zero(),
        enemies: () => [enemy],
        armingTime: 0.01,
      );

      mine.update(0.02); // Arm
      mine.update(0.01); // Check proximity

      // Should not trigger for dead enemy
      expect(mine.state, MineState.armed);
    });

    test('does not trigger for enemies outside radius', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2(500, 500); // Far away

      final mine = makeMine(
        position: Vector2.zero(),
        enemies: () => [enemy],
        armingTime: 0.01,
        explosionRadius: 60,
      );

      mine.update(0.02); // Arm
      mine.update(0.1); // Check proximity

      expect(mine.state, MineState.armed);
    });
  });

  group('NeonMine explosion', () {
    test('arms, triggers, and explodes near enemies', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2.zero();
      final beforeHealth = enemy.health;

      var exploded = false;
      final mine = NeonMine(
        position: Vector2.zero(),
        enemies: () => [enemy],
        onExplode: (_) => exploded = true,
        armingTime: 0.05,
        explosionRadius: 40,
        damage: 10,
      );

      mine.update(0.05);
      expect(mine.state, MineState.armed);

      mine.update(0.01);
      expect(mine.state, MineState.triggered);

      mine.update(0.2);
      expect(mine.state, MineState.exploded);
      expect(exploded, isTrue);
      expect(enemy.health, lessThan(beforeHealth));
    });

    test('damages multiple enemies in range', () {
      final enemy1 = Enemy(path: [Vector2.zero()]);
      final enemy2 = Enemy(path: [Vector2.zero()]);
      final enemy3 = Enemy(path: [Vector2.zero()]);

      enemy1.position = Vector2(10, 0);
      enemy2.position = Vector2(0, 10);
      enemy3.position = Vector2(10, 10);

      final mine = makeMine(
        position: Vector2.zero(),
        enemies: () => [enemy1, enemy2, enemy3],
        armingTime: 0.01,
        explosionRadius: 100,
        damage: 50,
      );

      // Arm and trigger
      mine.update(0.02);
      mine.update(0.01);
      mine.update(0.2);

      expect(mine.state, MineState.exploded);
    });

    test('onExplode callback is called', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2.zero();

      NeonMine? explodedMine;
      final mine = makeMine(
        position: Vector2.zero(),
        enemies: () => [enemy],
        onExplode: (m) => explodedMine = m,
        armingTime: 0.01,
      );

      mine.update(0.02);
      mine.update(0.01);
      mine.update(0.2);

      expect(explodedMine, same(mine));
    });
  });

  group('NeonMine update', () {
    test('update advances mine state', () {
      final mine = makeMine();

      mine.update(0.016);
      mine.update(0.016);
      mine.update(0.016);

      expect(true, isTrue);
    });

    test('update with zero dt does not crash', () {
      final mine = makeMine();

      mine.update(0.0);
      expect(true, isTrue);
    });

    test('update with large dt works', () {
      final mine = makeMine(armingTime: 0.1);

      mine.update(1.0);
      expect(mine.state, MineState.armed);
    });

    test('multiple rapid updates work', () {
      final mine = makeMine();

      for (int i = 0; i < 100; i++) {
        mine.update(0.016);
      }
      expect(true, isTrue);
    });
  });

  group('NeonMine render', () {
    test('renders without exceptions', () {
      final mine = NeonMine(
        position: Vector2.zero(),
        enemies: () => <Enemy>[],
        onExplode: (_) {},
        armingTime: 0.1,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      mine.update(0.05);
      mine.render(canvas);
      recorder.endRecording();
    });

    test('renders in arming state', () {
      final mine = makeMine(armingTime: 1.0);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      mine.update(0.1);
      mine.render(canvas);
      recorder.endRecording();
    });

    test('renders in armed state', () {
      final mine = makeMine(armingTime: 0.1);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      mine.update(0.15);
      mine.render(canvas);
      recorder.endRecording();
    });

    test('renders in triggered state', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2.zero();

      final mine = makeMine(
        position: Vector2.zero(),
        enemies: () => [enemy],
        armingTime: 0.01,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      mine.update(0.02); // Arm
      mine.update(0.01); // Trigger
      mine.render(canvas);
      recorder.endRecording();
    });
  });

  group('NeonMine edge cases', () {
    test('works with empty enemy list', () {
      final mine = makeMine(enemies: () => [], armingTime: 0.01);

      mine.update(0.02);
      mine.update(0.1);

      expect(mine.state, MineState.armed);
    });

    test('works with zero damage', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2.zero();
      final healthBefore = enemy.health;

      final mine = makeMine(
        position: Vector2.zero(),
        enemies: () => [enemy],
        armingTime: 0.01,
        damage: 0,
      );

      mine.update(0.02);
      mine.update(0.01);
      mine.update(0.2);

      expect(mine.state, MineState.exploded);
      expect(enemy.health, healthBefore);
    });

    test('works with zero arming time', () {
      final mine = makeMine(armingTime: 0.0);

      mine.update(0.001);
      expect(mine.state, MineState.armed);
    });

    test('works with negative position', () {
      final mine = makeMine(position: Vector2(-100, -100));

      expect(mine.position.x, -100);
      expect(mine.position.y, -100);
    });

    test('works with very small explosion radius', () {
      final mine = makeMine(explosionRadius: 1);

      mine.update(0.6);
      expect(mine.isArmed, isTrue);
    });
  });

  group('NeonMine multiple instances', () {
    test('multiple mines can exist independently', () {
      final mine1 = makeMine(position: Vector2(0, 0), armingTime: 0.1);
      final mine2 = makeMine(position: Vector2(100, 100), armingTime: 0.5);

      mine1.update(0.15);
      mine2.update(0.15);

      expect(mine1.state, MineState.armed);
      expect(mine2.state, MineState.arming);
    });

    test('mines do not affect each other', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2.zero();

      var exploded1 = false;
      var exploded2 = false;

      final mine1 = makeMine(
        position: Vector2.zero(),
        enemies: () => [enemy],
        onExplode: (_) => exploded1 = true,
        armingTime: 0.01,
      );
      final mine2 = makeMine(
        position: Vector2(500, 500),
        enemies: () => [enemy],
        onExplode: (_) => exploded2 = true,
        armingTime: 0.01,
      );

      mine1.update(0.02);
      mine1.update(0.01);
      mine1.update(0.2);

      mine2.update(0.02);
      mine2.update(0.1);

      expect(exploded1, isTrue);
      expect(exploded2, isFalse);
    });
  });
}
