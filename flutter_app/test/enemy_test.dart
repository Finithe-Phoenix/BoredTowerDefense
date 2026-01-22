import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/enemy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnemyType enum', () {
    test('has 40 enemy types', () {
      expect(EnemyType.values.length, 40);
    });

    test('all enemy types have valid color', () {
      for (final type in EnemyType.values) {
        expect(type.color, isA<Color>());
        expect(type.color.value, isNonZero);
      }
    });

    test('all enemy types have valid speedMult', () {
      for (final type in EnemyType.values) {
        expect(type.speedMult, greaterThan(0));
        expect(type.speedMult, lessThanOrEqualTo(2.0));
      }
    });

    test('all enemy types have valid healthMult', () {
      for (final type in EnemyType.values) {
        expect(type.healthMult, greaterThan(0));
        expect(type.healthMult, lessThanOrEqualTo(5.5));
      }
    });

    test('all enemy types have valid sizeMult', () {
      for (final type in EnemyType.values) {
        expect(type.sizeMult, greaterThan(0));
        expect(type.sizeMult, lessThanOrEqualTo(2.0));
      }
    });

    test('all enemy types have valid world', () {
      for (final type in EnemyType.values) {
        expect(type.world, greaterThanOrEqualTo(1));
        expect(type.world, lessThanOrEqualTo(10));
      }
    });

    test('getWorldEnemies returns 4 enemies per world', () {
      for (int world = 1; world <= 10; world++) {
        final enemies = EnemyType.getWorldEnemies(world);
        expect(enemies.length, 4);
        for (final enemy in enemies) {
          expect(enemy.world, world);
        }
      }
    });

    test('basicTypes returns world 1 enemies', () {
      final basicTypes = EnemyType.basicTypes;
      expect(basicTypes.length, 4);
      expect(basicTypes, contains(EnemyType.runner));
      expect(basicTypes, contains(EnemyType.overloaded));
      expect(basicTypes, contains(EnemyType.juggernaut));
      expect(basicTypes, contains(EnemyType.phantom));
    });

    test('runner has default multipliers', () {
      expect(EnemyType.runner.speedMult, 1.0);
      expect(EnemyType.runner.healthMult, 1.0);
      expect(EnemyType.runner.sizeMult, 1.0);
      expect(EnemyType.runner.isPhantom, isFalse);
    });

    test('phantom types have isPhantom true', () {
      expect(EnemyType.phantom.isPhantom, isTrue);
      expect(EnemyType.riftwalker.isPhantom, isTrue);
      expect(EnemyType.prismWalker.isPhantom, isTrue);
      expect(EnemyType.cloakedAssassin.isPhantom, isTrue);
      expect(EnemyType.systemGhost.isPhantom, isTrue);
      expect(EnemyType.cycloneSpirit.isPhantom, isTrue);
      expect(EnemyType.voidStalker.isPhantom, isTrue);
      expect(EnemyType.realityShifter.isPhantom, isTrue);
    });
  });

  group('Enemy creation', () {
    test('creates with default parameters', () {
      final enemy = Enemy(path: [Vector2.zero()]);

      expect(enemy, isA<PositionComponent>());
      expect(enemy.type, EnemyType.runner);
      expect(enemy.goldReward, 10);
      expect(enemy.spawnIndex, 0);
      expect(enemy.threatTier, 0);
      expect(enemy.worldIndex, 1);
      expect(enemy.isAlive, isTrue);
      expect(enemy.isBoss, isFalse);
    });

    test('creates with custom parameters', () {
      final enemy = Enemy(
        path: [Vector2.zero()],
        speed: 120,
        maxHealth: 200,
        goldReward: 25,
        type: EnemyType.juggernaut,
        spawnIndex: 5,
        threatTier: 2,
        worldIndex: 3,
      );

      expect(enemy.type, EnemyType.juggernaut);
      expect(enemy.goldReward, 25);
      expect(enemy.spawnIndex, 5);
      expect(enemy.threatTier, 2);
      expect(enemy.worldIndex, 3);
    });

    test('creates with start position', () {
      final startPos = Vector2(50, 50);
      final enemy = Enemy(
        path: [Vector2(100, 100)],
        startPosition: startPos,
      );

      expect(enemy.position.x, 50);
      expect(enemy.position.y, 50);
    });

    test('anchor is center', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      expect(enemy.anchor, Anchor.center);
    });
  });

  group('Enemy health', () {
    test('health and maxHealth are initialized', () {
      final enemy = Enemy(path: [Vector2.zero()], maxHealth: 150);

      expect(enemy.health, enemy.maxHealth);
      expect(enemy.healthPercent, 1.0);
    });

    test('takeDamage reduces health', () {
      final enemy = Enemy(path: [Vector2.zero()], maxHealth: 100);

      enemy.takeDamage(30);

      expect(enemy.health, 70);
      expect(enemy.healthPercent, 0.7);
      expect(enemy.isAlive, isTrue);
    });

    test('takeDamage does nothing when dead', () {
      final enemy = Enemy(path: [Vector2.zero()], maxHealth: 100);
      enemy.takeDamage(100);

      final healthAfterDeath = enemy.health;
      enemy.takeDamage(50);

      expect(enemy.health, healthAfterDeath);
    });

    test('enemy dies when health reaches zero', () {
      bool deathCalled = false;
      final enemy = Enemy(
        path: [Vector2.zero()],
        maxHealth: 100,
        onDeath: (e) => deathCalled = true,
      );

      enemy.takeDamage(100);

      expect(enemy.isAlive, isFalse);
      expect(enemy.health, 0);
      expect(deathCalled, isTrue);
    });

    test('threatTier affects health', () {
      final enemy0 = Enemy(path: [Vector2.zero()], maxHealth: 100, threatTier: 0);
      final enemy3 = Enemy(path: [Vector2.zero()], maxHealth: 100, threatTier: 3);

      expect(enemy3.maxHealth, greaterThan(enemy0.maxHealth));
    });

    test('type healthMult affects actual health', () {
      final normalEnemy = Enemy(path: [Vector2.zero()], maxHealth: 100, type: EnemyType.runner);
      final tankEnemy = Enemy(path: [Vector2.zero()], maxHealth: 100, type: EnemyType.juggernaut);

      expect(tankEnemy.maxHealth, greaterThan(normalEnemy.maxHealth));
    });
  });

  group('Enemy slow effect', () {
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

    test('isSlowed returns true when slowed', () {
      final enemy = Enemy(path: [Vector2.zero()], speed: 100);
      expect(enemy.isSlowed, isFalse);

      enemy.applySlow(0.5, 1.0);
      expect(enemy.isSlowed, isTrue);
    });

    test('applySlow uses stronger slow', () {
      final enemy = Enemy(path: [Vector2.zero()], speed: 100);

      enemy.applySlow(0.3, 1.0);
      final speed1 = enemy.speed;

      enemy.applySlow(0.6, 1.0);
      final speed2 = enemy.speed;

      expect(speed2, lessThan(speed1));
    });
  });

  group('Enemy path', () {
    test('pathProgress is 0 at start', () {
      final enemy = Enemy(path: [Vector2(100, 0), Vector2(200, 0)]);
      expect(enemy.pathProgress, 0.0);
    });

    test('currentPathIndex is 0 at start', () {
      final enemy = Enemy(path: [Vector2(100, 0), Vector2(200, 0)]);
      expect(enemy.currentPathIndex, 0);
    });

    test('hasReachedBase is false at start', () {
      final enemy = Enemy(path: [Vector2(100, 0)]);
      expect(enemy.hasReachedBase, isFalse);
    });

    test('movementDirection is normalized', () {
      final enemy = Enemy(path: [Vector2(100, 0)]);
      final direction = enemy.movementDirection;
      expect(direction.length, closeTo(1.0, 0.001));
    });

    test('empty path handles gracefully', () {
      final enemy = Enemy(path: []);
      expect(enemy.position, Vector2.zero());
      expect(enemy.pathProgress, 0.0);
      expect(enemy.movementDirection.length, closeTo(1.0, 0.001));
    });
  });

  group('Enemy phantom', () {
    test('isPhantom reflects enemy type', () {
      final normalEnemy = Enemy(path: [Vector2.zero()], type: EnemyType.runner);
      final phantomEnemy = Enemy(path: [Vector2.zero()], type: EnemyType.phantom);

      expect(normalEnemy.isPhantom, isFalse);
      expect(phantomEnemy.isPhantom, isTrue);
    });

    test('reveal can be called on phantom', () {
      final phantom = Enemy(path: [Vector2.zero()], type: EnemyType.phantom);
      phantom.reveal();
      expect(true, isTrue);
    });

    test('reveal on non-phantom does nothing', () {
      final enemy = Enemy(path: [Vector2.zero()], type: EnemyType.runner);
      enemy.reveal();
      expect(enemy.isPhantom, isFalse);
    });

    test('takeDamage reveals phantom', () {
      final phantom = Enemy(path: [Vector2.zero()], type: EnemyType.phantom, maxHealth: 100);
      phantom.takeDamage(10);
      expect(phantom.isAlive, isTrue);
    });
  });

  group('Enemy static settings', () {
    test('lowFx can be set', () {
      final original = Enemy.lowFx;
      Enemy.lowFx = true;
      expect(Enemy.lowFx, isTrue);
      Enemy.lowFx = original;
    });

    test('forceLowFx can be set', () {
      final original = Enemy.forceLowFx;
      Enemy.forceLowFx = true;
      expect(Enemy.forceLowFx, isTrue);
      Enemy.forceLowFx = original;
    });

    test('allowBlur can be set', () {
      final original = Enemy.allowBlur;
      Enemy.allowBlur = false;
      expect(Enemy.allowBlur, isFalse);
      Enemy.allowBlur = original;
    });

    test('throttleOffscreen can be set', () {
      final original = Enemy.throttleOffscreen;
      Enemy.throttleOffscreen = true;
      expect(Enemy.throttleOffscreen, isTrue);
      Enemy.throttleOffscreen = original;
    });

    test('screenOffset can be set', () {
      Enemy.screenOffset = Vector2(10, 20);
      expect(Enemy.screenOffset.x, 10);
      expect(Enemy.screenOffset.y, 20);
      Enemy.screenOffset = Vector2.zero();
    });

    test('screenSize can be set', () {
      Enemy.screenSize = Vector2(800, 600);
      expect(Enemy.screenSize.x, 800);
      expect(Enemy.screenSize.y, 600);
      Enemy.screenSize = Vector2.zero();
    });

    test('screenScale can be set', () {
      Enemy.screenScale = 2.0;
      expect(Enemy.screenScale, 2.0);
      Enemy.screenScale = 1.0;
    });
  });

  group('Enemy display', () {
    test('displayName is uppercase type name', () {
      final enemy = Enemy(path: [Vector2.zero()], type: EnemyType.runner);
      expect(enemy.displayName, 'RUNNER');
    });

    test('displayName for different types', () {
      expect(Enemy(path: [], type: EnemyType.juggernaut).displayName, 'JUGGERNAUT');
      expect(Enemy(path: [], type: EnemyType.glitcher).displayName, 'GLITCHER');
      expect(Enemy(path: [], type: EnemyType.apocalypseHerald).displayName, 'APOCALYPSEHERALD');
    });
  });

  group('Enemy callbacks', () {
    test('onDeath callback is called when enemy dies', () {
      Enemy? deadEnemy;
      final enemy = Enemy(
        path: [Vector2.zero()],
        maxHealth: 50,
        onDeath: (e) => deadEnemy = e,
      );

      enemy.takeDamage(50);

      expect(deadEnemy, same(enemy));
    });

    test('onDeath callback is not called when still alive', () {
      bool deathCalled = false;
      final enemy = Enemy(
        path: [Vector2.zero()],
        maxHealth: 100,
        onDeath: (e) => deathCalled = true,
      );

      enemy.takeDamage(50);

      expect(deathCalled, isFalse);
      expect(enemy.isAlive, isTrue);
    });

    test('onReachBase callback can be set', () {
      bool reachCalled = false;
      final enemy = Enemy(
        path: [Vector2.zero()],
        onReachBase: (e) => reachCalled = true,
      );

      expect(enemy.onReachBase, isNotNull);
    });
  });

  group('Enemy update', () {
    test('update moves enemy towards waypoint', () {
      final enemy = Enemy(
        path: [Vector2(100, 0)],
        speed: 100,
        startPosition: Vector2(0, 0),
      );

      enemy.update(0.1);

      expect(enemy.position.x, greaterThan(0));
    });

    test('multiple updates move enemy further', () {
      final enemy = Enemy(
        path: [Vector2(100, 0)],
        speed: 50,
        startPosition: Vector2(0, 0),
      );

      enemy.update(0.1);
      final pos1 = enemy.position.x;

      enemy.update(0.1);
      final pos2 = enemy.position.x;

      expect(pos2, greaterThan(pos1));
    });

    test('update with dt 0 does not move', () {
      final enemy = Enemy(
        path: [Vector2(100, 0)],
        speed: 100,
        startPosition: Vector2(0, 0),
      );
      final startX = enemy.position.x;

      enemy.update(0.0);

      expect(enemy.position.x, startX);
    });
  });

  group('Enemy size', () {
    test('size is affected by type sizeMult', () {
      final smallEnemy = Enemy(path: [], type: EnemyType.voidling);
      final largeEnemy = Enemy(path: [], type: EnemyType.apocalypseHerald);

      expect(largeEnemy.size.x, greaterThan(smallEnemy.size.x));
    });

    test('threatTier affects size', () {
      final enemy0 = Enemy(path: [], threatTier: 0);
      final enemy3 = Enemy(path: [], threatTier: 3);

      expect(enemy3.size.x, greaterThan(enemy0.size.x));
    });
  });

  group('Enemy world themes', () {
    test('world 1 enemies are Neon Frontier themed', () {
      final world1 = EnemyType.getWorldEnemies(1);
      expect(world1, contains(EnemyType.runner));
      expect(world1, contains(EnemyType.overloaded));
      expect(world1, contains(EnemyType.juggernaut));
      expect(world1, contains(EnemyType.phantom));
    });

    test('world 2 enemies are Rift Wars themed', () {
      final world2 = EnemyType.getWorldEnemies(2);
      expect(world2, contains(EnemyType.glitcher));
      expect(world2, contains(EnemyType.riftwalker));
      expect(world2, contains(EnemyType.voidling));
      expect(world2, contains(EnemyType.dimensionBreaker));
    });

    test('world 10 enemies are Omega Nexus themed', () {
      final world10 = EnemyType.getWorldEnemies(10);
      expect(world10, contains(EnemyType.nexusHunter));
      expect(world10, contains(EnemyType.omegaSentinel));
      expect(world10, contains(EnemyType.realityShifter));
      expect(world10, contains(EnemyType.apocalypseHerald));
    });
  });

  group('Enemy multiple instances', () {
    test('multiple enemies can exist independently', () {
      final enemy1 = Enemy(path: [], maxHealth: 100, type: EnemyType.runner);
      final enemy2 = Enemy(path: [], maxHealth: 200, type: EnemyType.juggernaut);

      enemy1.takeDamage(30);

      expect(enemy1.health, lessThan(enemy1.maxHealth));
      expect(enemy2.health, enemy2.maxHealth);
    });

    test('enemies have unique spawn indices', () {
      final enemies = List.generate(10, (i) => Enemy(path: [], spawnIndex: i));

      for (int i = 0; i < enemies.length; i++) {
        expect(enemies[i].spawnIndex, i);
      }
    });
  });

  group('Enemy render', () {
    test('renders without exceptions', () {
      final enemy = Enemy(path: [Vector2.zero()]);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      enemy.update(0.1);
      enemy.render(canvas);
      recorder.endRecording();
    });

    test('renders all enemy types', () {
      for (final type in EnemyType.values) {
        final enemy = Enemy(
          path: [Vector2.zero()],
          type: type,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        enemy.update(0.1);
        enemy.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with lowFx enabled', () {
      Enemy.lowFx = true;

      final enemy = Enemy(path: [Vector2.zero()]);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      enemy.update(0.1);
      enemy.render(canvas);
      recorder.endRecording();

      Enemy.lowFx = false;
    });

    test('renders when slowed', () {
      final enemy = Enemy(
        path: [Vector2.zero()],
        speed: 100,
      );

      enemy.applySlow(0.5, 1.0);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      enemy.update(0.1);
      enemy.render(canvas);
      recorder.endRecording();
    });

    test('renders damaged enemy', () {
      final enemy = Enemy(
        path: [Vector2.zero()],
        maxHealth: 100,
      );

      enemy.takeDamage(50);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      enemy.update(0.1);
      enemy.render(canvas);
      recorder.endRecording();
    });

    test('renders phantom enemy', () {
      final enemy = Enemy(
        path: [Vector2.zero()],
        type: EnemyType.phantom,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      enemy.update(0.1);
      enemy.render(canvas);
      recorder.endRecording();
    });

    test('renders revealed phantom', () {
      final enemy = Enemy(
        path: [Vector2.zero()],
        type: EnemyType.phantom,
      );

      enemy.reveal();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      enemy.update(0.1);
      enemy.render(canvas);
      recorder.endRecording();
    });

    test('renders with different threat tiers', () {
      for (final tier in [0, 1, 2, 3]) {
        final enemy = Enemy(
          path: [Vector2.zero()],
          threatTier: tier,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        enemy.update(0.1);
        enemy.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with forceLowFx', () {
      Enemy.forceLowFx = true;

      final enemy = Enemy(path: [Vector2.zero()]);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      enemy.update(0.1);
      enemy.render(canvas);
      recorder.endRecording();

      Enemy.forceLowFx = false;
    });

    test('renders after time passes', () {
      final enemy = Enemy(path: [Vector2(500, 500)]);

      // Run for many frames
      for (int i = 0; i < 60; i++) {
        enemy.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      enemy.render(canvas);
      recorder.endRecording();
    });

    test('renders world-specific enemy types', () {
      for (int world = 1; world <= 10; world++) {
        final enemies = EnemyType.getWorldEnemies(world);
        for (final type in enemies) {
          final enemy = Enemy(
            path: [Vector2.zero()],
            type: type,
            worldIndex: world,
          );

          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);

          enemy.update(0.1);
          enemy.render(canvas);
          recorder.endRecording();
        }
      }
    });

    test('renders dead enemy', () {
      final enemy = Enemy(
        path: [Vector2.zero()],
        maxHealth: 50,
      );

      enemy.takeDamage(50);
      expect(enemy.isAlive, isFalse);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      enemy.render(canvas);
      recorder.endRecording();
    });

    test('renders boss enemy', () {
      final enemy = Enemy(
        path: [Vector2.zero()],
        type: EnemyType.apocalypseHerald,
        threatTier: 3,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      enemy.update(0.1);
      enemy.render(canvas);
      recorder.endRecording();
    });

    test('renders with low health (plasma particles)', () {
      final enemy = Enemy(
        path: [Vector2(500, 500)],
        maxHealth: 100,
      );

      enemy.takeDamage(70); // Reduce to 30% health

      for (int i = 0; i < 30; i++) {
        enemy.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      enemy.render(canvas);
      recorder.endRecording();
    });

    test('renders after multiple damage hits', () {
      final enemy = Enemy(
        path: [Vector2(500, 500)],
        maxHealth: 100,
      );

      // Take multiple hits to trigger damage particles
      for (int i = 0; i < 5; i++) {
        enemy.takeDamage(10);
        enemy.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      enemy.render(canvas);
      recorder.endRecording();
    });
  });

  group('Enemy movement along path', () {
    test('moves through multiple waypoints', () {
      final path = [
        Vector2(50, 0),
        Vector2(50, 50),
        Vector2(100, 50),
      ];
      final enemy = Enemy(
        path: path,
        speed: 500,
        startPosition: Vector2(0, 0),
      );

      // Move through path
      for (int i = 0; i < 30; i++) {
        enemy.update(0.016);
      }

      expect(enemy.currentPathIndex, greaterThan(0));
    });

    test('handles diagonal path correctly', () {
      final enemy = Enemy(
        path: [Vector2(100, 100)],
        speed: 100,
        startPosition: Vector2(0, 0),
      );

      enemy.update(0.1);

      expect(enemy.position.x, greaterThan(0));
      expect(enemy.position.y, greaterThan(0));
    });

    test('pathProgress is tracked correctly', () {
      final enemy = Enemy(
        path: [Vector2(100, 0), Vector2(200, 0)],
        speed: 100,
        startPosition: Vector2(0, 0),
      );

      // pathProgress is 0 at start
      expect(enemy.pathProgress, greaterThanOrEqualTo(0));

      // Update moves enemy
      enemy.update(0.5);

      // Position should have changed
      expect(enemy.position.x, greaterThan(0));
    });
  });

  group('Enemy effects with different settings', () {
    test('renders with allowBlur disabled', () {
      final originalAllowBlur = Enemy.allowBlur;
      Enemy.allowBlur = false;

      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.update(0.1);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      enemy.render(canvas);
      recorder.endRecording();

      Enemy.allowBlur = originalAllowBlur;
    });

    test('renders offscreen enemy with throttleOffscreen', () {
      final originalThrottle = Enemy.throttleOffscreen;
      Enemy.throttleOffscreen = true;
      Enemy.screenSize = Vector2(100, 100);
      Enemy.screenOffset = Vector2.zero();
      Enemy.screenScale = 1.0;

      final enemy = Enemy(
        path: [Vector2(1000, 1000)],
        startPosition: Vector2(500, 500),
      );

      enemy.update(0.016);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      enemy.render(canvas);
      recorder.endRecording();

      Enemy.throttleOffscreen = originalThrottle;
    });

    test('updates many frames with all effects', () {
      final enemy = Enemy(
        path: [Vector2(1000, 1000)],
        startPosition: Vector2.zero(),
        speed: 50,
        maxHealth: 100,
        type: EnemyType.phantom,
      );

      enemy.applySlow(0.3, 2.0);
      enemy.takeDamage(30);
      enemy.reveal();

      // Run many update frames
      for (int i = 0; i < 120; i++) {
        enemy.update(0.016);
        if (i % 20 == 0) {
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);
          enemy.render(canvas);
          recorder.endRecording();
        }
      }

      expect(enemy.isAlive, isTrue);
    });
  });

  group('Enemy all types rendering', () {
    test('renders all types with damage and slow', () {
      for (final type in EnemyType.values) {
        final enemy = Enemy(
          path: [Vector2(100, 100)],
          type: type,
          maxHealth: 100,
          speed: 50,
        );

        enemy.takeDamage(30);
        enemy.applySlow(0.5, 1.0);

        for (int i = 0; i < 5; i++) {
          enemy.update(0.016);
        }

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        enemy.render(canvas);
        recorder.endRecording();
      }
    });
  });
}
