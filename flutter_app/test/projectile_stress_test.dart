import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/projectile.dart';
import 'package:bored_games/src/game/entities/tower.dart';
import 'package:bored_games/src/game/managers/bullet_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BulletManager.clearPool();
    Projectile.lowFx = false;
    Projectile.allowTrails = true;
    Projectile.allowGlow = true;
    Projectile.stressLevel = 0;
  });

  tearDown(() {
    BulletManager.clearPool();
    Projectile.lowFx = false;
    Projectile.stressLevel = 0;
  });

  group('Projectile creation', () {
    test('creates with required parameters', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 200,
        damage: 10,
      );

      expect(projectile, isA<PositionComponent>());
      expect(projectile.damage, 10);
    });

    test('creates with custom color', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 200,
        damage: 10,
        color: Colors.red,
      );

      expect(projectile.color, Colors.red);
    });

    test('creates with slow effect', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 200,
        damage: 10,
        slowAmount: 0.5,
        slowDuration: 2.0,
      );

      expect(projectile.slowAmount, 0.5);
      expect(projectile.slowDuration, 2.0);
    });

    test('creates with tower type', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 200,
        damage: 10,
        towerType: TowerType.phaseMage,
      );

      expect(projectile.towerType, TowerType.phaseMage);
    });
  });

  group('Projectile stress levels', () {
    test('setStressLevel updates static level', () {
      Projectile.setStressLevel(0);
      expect(Projectile.stressLevel, 0);

      Projectile.setStressLevel(1);
      expect(Projectile.stressLevel, 1);

      Projectile.setStressLevel(2);
      expect(Projectile.stressLevel, 2);
    });

    test('stress level 0 is low stress', () {
      Projectile.setStressLevel(0);
      expect(Projectile.stressLevel, 0);
    });

    test('stress level 1 is medium stress', () {
      Projectile.setStressLevel(1);
      expect(Projectile.stressLevel, 1);
    });

    test('stress level 2 is high stress', () {
      Projectile.setStressLevel(2);
      expect(Projectile.stressLevel, 2);
    });
  });

  group('Projectile visual settings', () {
    test('lowFx can be toggled', () {
      Projectile.lowFx = true;
      expect(Projectile.lowFx, isTrue);

      Projectile.lowFx = false;
      expect(Projectile.lowFx, isFalse);
    });

    test('allowTrails can be toggled', () {
      Projectile.allowTrails = true;
      expect(Projectile.allowTrails, isTrue);

      Projectile.allowTrails = false;
      expect(Projectile.allowTrails, isFalse);
    });

    test('allowGlow can be toggled', () {
      Projectile.allowGlow = true;
      expect(Projectile.allowGlow, isTrue);

      Projectile.allowGlow = false;
      expect(Projectile.allowGlow, isFalse);
    });
  });

  group('Projectile reset', () {
    test('reset updates projectile state', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 200,
        damage: 10,
      );

      projectile.reset(
        startPosition: Vector2(50, 50),
        targetPosition: Vector2(150, 150),
        speed: 300,
        damage: 20,
        color: Colors.blue,
      );

      expect(projectile.damage, 20);
      expect(projectile.color, Colors.blue);
    });

    test('reset with slow parameters', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 200,
        damage: 10,
      );

      projectile.reset(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 200,
        damage: 10,
        slowAmount: 0.7,
        slowDuration: 3.0,
      );

      expect(projectile.slowAmount, 0.7);
      expect(projectile.slowDuration, 3.0);
    });

    test('reset with tower type', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 200,
        damage: 10,
      );

      projectile.reset(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 200,
        damage: 10,
        towerType: TowerType.circuitCannon,
      );

      expect(projectile.towerType, TowerType.circuitCannon);
    });
  });

  group('Projectile update', () {
    test('update moves projectile towards target', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 200,
        damage: 10,
      );

      projectile.update(0.1);

      expect(projectile.position.x, greaterThan(0));
    });

    test('multiple updates move further', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 100,
        damage: 10,
      );

      projectile.update(0.1);
      final pos1 = projectile.position.x;

      projectile.update(0.1);
      final pos2 = projectile.position.x;

      expect(pos2, greaterThan(pos1));
    });
  });

  group('Projectile rendering', () {
    test('renders without error', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 200,
        damage: 10,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      projectile.update(0.016);
      projectile.render(canvas);
      recorder.endRecording();
    });

    test('renders with lowFx enabled', () {
      Projectile.lowFx = true;

      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 200,
        damage: 10,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      projectile.update(0.016);
      projectile.render(canvas);
      recorder.endRecording();
    });

    test('renders with different stress levels', () {
      for (int level = 0; level <= 2; level++) {
        Projectile.setStressLevel(level);

        final projectile = Projectile(
          startPosition: Vector2.zero(),
          targetPosition: Vector2(100, 0),
          speed: 200,
          damage: 10,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        projectile.update(0.016);
        projectile.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders all tower types', () {
      for (final type in TowerType.values) {
        final projectile = Projectile(
          startPosition: Vector2.zero(),
          targetPosition: Vector2(100, 0),
          speed: 200,
          damage: 10,
          towerType: type,
          color: type.color,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        projectile.update(0.016);
        projectile.render(canvas);
        recorder.endRecording();
      }
    });
  });

  group('Projectile trail', () {
    test('trail builds over time', () {
      Projectile.allowTrails = true;

      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 100,
        damage: 10,
      );

      for (int i = 0; i < 10; i++) {
        projectile.update(0.016);
      }

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      projectile.render(canvas);
      recorder.endRecording();
    });
  });

  group('Projectile callback', () {
    test('onHit callback can be set', () {
      bool hitCalled = false;

      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 200,
        damage: 10,
        onHit: (enemy, hitPos, killed) {
          hitCalled = true;
        },
      );

      expect(projectile.onHit, isNotNull);
    });
  });

  group('Projectile multiple instances', () {
    test('multiple projectiles are independent', () {
      final p1 = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 100,
        damage: 10,
      );

      final p2 = Projectile(
        startPosition: Vector2(50, 50),
        targetPosition: Vector2(150, 50),
        speed: 200,
        damage: 20,
      );

      expect(p1.damage, isNot(equals(p2.damage)));
      expect(p1.position, isNot(equals(p2.position)));
    });

    test('stress level is shared across all projectiles', () {
      Projectile.setStressLevel(1);

      final p1 = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 200,
        damage: 10,
      );

      final p2 = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 200,
        damage: 10,
      );

      expect(Projectile.stressLevel, 1);
    });
  });
}
