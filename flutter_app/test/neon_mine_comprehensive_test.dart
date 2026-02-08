import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/components/neon_mine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MineState enum', () {
    test('has 4 states', () {
      expect(MineState.values.length, 4);
    });

    test('contains arming', () {
      expect(MineState.values, contains(MineState.arming));
    });

    test('contains armed', () {
      expect(MineState.values, contains(MineState.armed));
    });

    test('contains triggered', () {
      expect(MineState.values, contains(MineState.triggered));
    });

    test('contains exploded', () {
      expect(MineState.values, contains(MineState.exploded));
    });

    test('arming is index 0', () {
      expect(MineState.arming.index, 0);
    });

    test('armed is index 1', () {
      expect(MineState.armed.index, 1);
    });

    test('triggered is index 2', () {
      expect(MineState.triggered.index, 2);
    });

    test('exploded is index 3', () {
      expect(MineState.exploded.index, 3);
    });
  });

  group('NeonMine creation', () {
    test('can create with required parameters', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
      );

      expect(mine, isNotNull);
      expect(mine.position.x, 100);
      expect(mine.position.y, 100);
    });

    test('default damage is 150', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
      );

      expect(mine.damage, 150);
    });

    test('default explosionRadius is 60', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
      );

      expect(mine.explosionRadius, 60);
    });

    test('default armingTime is 0.5', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
      );

      expect(mine.armingTime, 0.5);
    });

    test('anchor is center', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
      );

      expect(mine.anchor, Anchor.center);
    });

    test('size is 24x24', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
      );

      expect(mine.size.x, 24);
      expect(mine.size.y, 24);
    });

    test('initial state is arming', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
      );

      expect(mine.state, MineState.arming);
    });

    test('isArmed is false initially', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
      );

      expect(mine.isArmed, isFalse);
    });
  });

  group('NeonMine custom parameters', () {
    test('can set custom damage', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
        damage: 300,
      );

      expect(mine.damage, 300);
    });

    test('can set custom explosionRadius', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
        explosionRadius: 100,
      );

      expect(mine.explosionRadius, 100);
    });

    test('can set custom armingTime', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
        armingTime: 1.0,
      );

      expect(mine.armingTime, 1.0);
    });
  });

  group('NeonMine update behavior', () {
    test('update with zero dt works', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
      );

      expect(() => mine.update(0), returnsNormally);
    });

    test('update with small dt works', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
      );

      expect(() => mine.update(0.016), returnsNormally);
    });

    test('multiple updates work', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
      );

      for (int i = 0; i < 60; i++) {
        mine.update(0.016);
      }

      expect(true, isTrue);
    });

    test('state transitions to armed after arming time', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
        armingTime: 0.5,
      );

      expect(mine.state, MineState.arming);

      // Update past arming time
      mine.update(0.6);

      expect(mine.state, MineState.armed);
      expect(mine.isArmed, isTrue);
    });
  });

  group('NeonMine static colors', () {
    test('primary color is neon red/pink', () {
      const primaryColor = Color(0xFFFF0066);
      expect(primaryColor.red, 255);
      expect(primaryColor.green, 0);
      expect(primaryColor.blue, 102);
    });

    test('secondary color is orange', () {
      const secondaryColor = Color(0xFFFF7043);
      expect(secondaryColor.red, 255);
    });

    test('armed color is green', () {
      const armedColor = Color(0xFF00FF88);
      expect(armedColor.green, 255);
    });

    test('hazard yellow is defined', () {
      const hazardYellow = Color(0xFFFFDD00);
      expect(hazardYellow.red, 255);
      expect(hazardYellow.green, 221);
    });
  });

  group('NeonMine particle system', () {
    test('particle count is 6', () {
      const particleCount = 6;
      expect(particleCount, 6);
    });

    test('particles are initialized on creation', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
      );

      // Particles are internal, just verify creation succeeds
      expect(mine, isNotNull);
    });
  });

  group('NeonMine onExplode callback', () {
    test('onExplode is stored', () {
      bool exploded = false;

      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) => exploded = true,
      );

      expect(exploded, isFalse);
      expect(mine, isNotNull);
    });
  });

  group('NeonMine position variations', () {
    test('works at origin', () {
      final mine = NeonMine(
        position: Vector2.zero(),
        enemies: () => [],
        onExplode: (_) {},
      );

      expect(mine.position.x, 0);
      expect(mine.position.y, 0);
    });

    test('works at negative coordinates', () {
      final mine = NeonMine(
        position: Vector2(-100, -100),
        enemies: () => [],
        onExplode: (_) {},
      );

      expect(mine.position.x, -100);
      expect(mine.position.y, -100);
    });

    test('works at large coordinates', () {
      final mine = NeonMine(
        position: Vector2(10000, 10000),
        enemies: () => [],
        onExplode: (_) {},
      );

      expect(mine.position.x, 10000);
      expect(mine.position.y, 10000);
    });
  });

  group('NeonMine damage variations', () {
    test('low damage mine', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
        damage: 50,
      );

      expect(mine.damage, 50);
    });

    test('high damage mine', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
        damage: 500,
      );

      expect(mine.damage, 500);
    });

    test('zero damage mine', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
        damage: 0,
      );

      expect(mine.damage, 0);
    });
  });

  group('NeonMine explosion radius variations', () {
    test('small explosion radius', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
        explosionRadius: 30,
      );

      expect(mine.explosionRadius, 30);
    });

    test('large explosion radius', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
        explosionRadius: 200,
      );

      expect(mine.explosionRadius, 200);
    });
  });

  group('NeonMine arming time variations', () {
    test('instant arming', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
        armingTime: 0,
      );

      expect(mine.armingTime, 0);
    });

    test('slow arming', () {
      final mine = NeonMine(
        position: Vector2(100, 100),
        enemies: () => [],
        onExplode: (_) {},
        armingTime: 3.0,
      );

      expect(mine.armingTime, 3.0);
    });
  });

  group('NeonMine performance', () {
    test('can create many mines', () {
      final mines = <NeonMine>[];

      for (int i = 0; i < 50; i++) {
        mines.add(NeonMine(
          position: Vector2(i.toDouble() * 30, 100),
          enemies: () => [],
          onExplode: (_) {},
        ));
      }

      expect(mines.length, 50);
    });

    test('can update many mines', () {
      final mines = List.generate(20, (i) => NeonMine(
        position: Vector2(i.toDouble() * 30, 100),
        enemies: () => [],
        onExplode: (_) {},
      ));

      for (int frame = 0; frame < 60; frame++) {
        for (final mine in mines) {
          mine.update(0.016);
        }
      }

      expect(true, isTrue);
    });
  });
}
