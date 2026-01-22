import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/projectile.dart';
import 'package:bored_games/src/game/entities/tower.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Projectile.lowFx = false;
    Projectile.allowTrails = true;
    Projectile.allowGlow = true;
    Projectile.stressLevel = 0;
  });

  Projectile makeProjectile({
    TowerType type = TowerType.pulseArcher,
    Vector2? startPosition,
    Vector2? targetPosition,
    double speed = 120,
    double damage = 10,
    Color color = const Color(0xFF00FFFF),
    double slowAmount = 0,
    double slowDuration = 0,
  }) {
    return Projectile(
      startPosition: startPosition ?? Vector2.zero(),
      targetPosition: targetPosition ?? Vector2(200, 0),
      speed: speed,
      damage: damage,
      towerType: type,
      color: color,
      slowAmount: slowAmount,
      slowDuration: slowDuration,
    );
  }

  group('Projectile creation', () {
    test('creates with required parameters', () {
      final projectile = makeProjectile();

      expect(projectile, isA<PositionComponent>());
      expect(projectile.speed, 120);
      expect(projectile.damage, 10);
      expect(projectile.isActive, isTrue);
    });

    test('creates with default tower type as pulseArcher', () {
      final projectile = makeProjectile();
      expect(projectile.towerType, TowerType.pulseArcher);
    });

    test('creates with custom tower type', () {
      final projectile = makeProjectile(type: TowerType.circuitCannon);
      expect(projectile.towerType, TowerType.circuitCannon);
    });

    test('creates with custom color', () {
      final projectile = makeProjectile(color: Colors.red);
      expect(projectile.color, Colors.red);
    });

    test('creates with slow parameters', () {
      final projectile = makeProjectile(slowAmount: 0.5, slowDuration: 2.0);
      expect(projectile.slowAmount, 0.5);
      expect(projectile.slowDuration, 2.0);
      expect(projectile.appliesSlow, isTrue);
    });

    test('appliesSlow is false when no slow', () {
      final projectile = makeProjectile();
      expect(projectile.appliesSlow, isFalse);
    });

    test('anchor is center', () {
      final projectile = makeProjectile();
      expect(projectile.anchor, Anchor.center);
    });

    test('position is set from startPosition', () {
      final projectile = makeProjectile(startPosition: Vector2(50, 50));
      expect(projectile.position.x, 50);
      expect(projectile.position.y, 50);
    });
  });

  group('Projectile update', () {
    test('update does not throw for all tower types', () {
      for (final type in TowerType.values) {
        final projectile = makeProjectile(type: type);
        expect(() => projectile.update(0.016), returnsNormally);
        expect(() => projectile.update(0.016), returnsNormally);
      }
    });

    test('projectile deactivates when reaching target', () {
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

    test('projectile moves towards target', () {
      final projectile = makeProjectile(
        startPosition: Vector2(0, 0),
        targetPosition: Vector2(100, 0),
        speed: 100,
      );

      final startX = projectile.position.x;
      projectile.update(0.1);

      expect(projectile.position.x, greaterThan(startX));
    });

    test('multiple updates move projectile further', () {
      final projectile = makeProjectile(
        startPosition: Vector2(0, 0),
        targetPosition: Vector2(100, 0),
        speed: 50,
      );

      projectile.update(0.1);
      final pos1 = projectile.position.x;

      projectile.update(0.1);
      final pos2 = projectile.position.x;

      expect(pos2, greaterThan(pos1));
    });
  });

  group('Projectile static settings', () {
    test('lowFx can be toggled', () {
      expect(Projectile.lowFx, isFalse);
      Projectile.lowFx = true;
      expect(Projectile.lowFx, isTrue);
      Projectile.lowFx = false;
    });

    test('allowTrails can be toggled', () {
      expect(Projectile.allowTrails, isTrue);
      Projectile.allowTrails = false;
      expect(Projectile.allowTrails, isFalse);
      Projectile.allowTrails = true;
    });

    test('allowGlow can be toggled', () {
      expect(Projectile.allowGlow, isTrue);
      Projectile.allowGlow = false;
      expect(Projectile.allowGlow, isFalse);
      Projectile.allowGlow = true;
    });

    test('stressLevel defaults to 0', () {
      expect(Projectile.stressLevel, 0);
    });

    test('setStressLevel sets level 0', () {
      Projectile.setStressLevel(0);
      expect(Projectile.stressLevel, 0);
      expect(Projectile.lowFx, isFalse);
    });

    test('setStressLevel sets level 1', () {
      Projectile.setStressLevel(1);
      expect(Projectile.stressLevel, 1);
      expect(Projectile.lowFx, isFalse);
    });

    test('setStressLevel sets level 2', () {
      Projectile.setStressLevel(2);
      expect(Projectile.stressLevel, 2);
      expect(Projectile.lowFx, isTrue);
    });

    test('setStressLevel clamps negative values', () {
      Projectile.setStressLevel(-1);
      expect(Projectile.stressLevel, 0);
    });

    test('setStressLevel clamps high values', () {
      Projectile.setStressLevel(5);
      expect(Projectile.stressLevel, 2);
    });
  });

  group('Projectile tower type effects', () {
    test('pulseArcher creates standard projectile', () {
      final projectile = makeProjectile(type: TowerType.pulseArcher);
      expect(projectile.towerType, TowerType.pulseArcher);
      projectile.update(0.016);
    });

    test('circuitCannon creates larger projectile', () {
      final projectile = makeProjectile(type: TowerType.circuitCannon);
      expect(projectile.towerType, TowerType.circuitCannon);
      expect(projectile.size.x, 10);
      projectile.update(0.016);
    });

    test('phaseMage creates projectile with electric effects', () {
      final projectile = makeProjectile(type: TowerType.phaseMage);
      expect(projectile.towerType, TowerType.phaseMage);
      projectile.update(0.016);
    });

    test('glimmerField creates smaller projectile', () {
      final projectile = makeProjectile(type: TowerType.glimmerField);
      expect(projectile.towerType, TowerType.glimmerField);
      expect(projectile.size.x, 4);
      projectile.update(0.016);
    });

    test('ionSniper creates elongated projectile', () {
      final projectile = makeProjectile(type: TowerType.ionSniper);
      expect(projectile.towerType, TowerType.ionSniper);
      expect(projectile.size.x, 12);
      expect(projectile.size.y, 4);
      projectile.update(0.016);
    });

    test('teslaTerminal creates projectile', () {
      final projectile = makeProjectile(type: TowerType.teslaTerminal);
      expect(projectile.towerType, TowerType.teslaTerminal);
      projectile.update(0.016);
    });

    test('resonanceSiphon creates projectile', () {
      final projectile = makeProjectile(type: TowerType.resonanceSiphon);
      expect(projectile.towerType, TowerType.resonanceSiphon);
      projectile.update(0.016);
    });

    test('neuralDisruptor creates projectile', () {
      final projectile = makeProjectile(type: TowerType.neuralDisruptor);
      expect(projectile.towerType, TowerType.neuralDisruptor);
      projectile.update(0.016);
    });
  });

  group('Projectile with lowFx', () {
    test('lowFx projectile still moves', () {
      Projectile.lowFx = true;
      final projectile = makeProjectile(
        startPosition: Vector2(0, 0),
        targetPosition: Vector2(100, 0),
        speed: 100,
      );

      projectile.update(0.1);
      expect(projectile.position.x, greaterThan(0));
    });

    test('lowFx projectile reaches target', () {
      Projectile.lowFx = true;
      final projectile = makeProjectile(
        startPosition: Vector2(0, 0),
        targetPosition: Vector2(10, 0),
        speed: 200,
      );

      // Update multiple times to reach target (distance < 5)
      for (int i = 0; i < 10; i++) {
        projectile.update(0.016);
      }
      // Projectile should have deactivated when reaching target
      expect(projectile.isActive, isFalse);
    });
  });

  group('Projectile multiple instances', () {
    test('multiple projectiles can exist independently', () {
      final p1 = makeProjectile(
        startPosition: Vector2(0, 0),
        targetPosition: Vector2(100, 0),
        speed: 50,
      );
      final p2 = makeProjectile(
        startPosition: Vector2(0, 100),
        targetPosition: Vector2(100, 100),
        speed: 100,
      );

      p1.update(0.1);
      p2.update(0.1);

      expect(p1.position.x, isNot(equals(p2.position.x)));
      expect(p1.speed, isNot(equals(p2.speed)));
    });

    test('projectiles have independent isActive state', () {
      final p1 = makeProjectile(
        startPosition: Vector2(0, 0),
        targetPosition: Vector2(10, 0),
        speed: 500,
      );
      final p2 = makeProjectile(
        startPosition: Vector2(0, 0),
        targetPosition: Vector2(100, 0),
        speed: 50,
      );

      // Update p1 multiple times to reach target
      for (int i = 0; i < 10; i++) {
        p1.update(0.016);
      }

      expect(p1.isActive, isFalse);
      expect(p2.isActive, isTrue);
    });
  });

  group('Projectile edge cases', () {
    test('very high speed reaches target quickly', () {
      final projectile = makeProjectile(
        startPosition: Vector2(0, 0),
        targetPosition: Vector2(10, 0),
        speed: 10000,
      );

      // With speed 10000, projectile moves very fast
      // Multiple updates to ensure it reaches target
      for (int i = 0; i < 5; i++) {
        projectile.update(0.016);
        if (!projectile.isActive) break;
      }
      expect(projectile.isActive, isFalse);
    });

    test('very low speed moves slowly', () {
      final projectile = makeProjectile(
        startPosition: Vector2(0, 0),
        targetPosition: Vector2(100, 0),
        speed: 1,
      );

      projectile.update(0.016);
      expect(projectile.isActive, isTrue);
      expect(projectile.position.x, lessThan(1));
    });

    test('diagonal target is reachable', () {
      final projectile = makeProjectile(
        startPosition: Vector2(0, 0),
        targetPosition: Vector2(50, 50),
        speed: 200,
      );

      for (int i = 0; i < 100; i++) {
        projectile.update(0.016);
        if (!projectile.isActive) break;
      }

      expect(projectile.isActive, isFalse);
    });

    test('negative target position works', () {
      final projectile = makeProjectile(
        startPosition: Vector2(0, 0),
        targetPosition: Vector2(-50, -50),
        speed: 200,
      );

      projectile.update(0.016);
      expect(projectile.position.x, lessThan(0));
      expect(projectile.position.y, lessThan(0));
    });
  });

  group('Projectile damage and slow', () {
    test('damage value is accessible', () {
      final projectile = makeProjectile(damage: 25);
      expect(projectile.damage, 25);
    });

    test('slowAmount and slowDuration are accessible', () {
      final projectile = makeProjectile(slowAmount: 0.7, slowDuration: 3.0);
      expect(projectile.slowAmount, 0.7);
      expect(projectile.slowDuration, 3.0);
    });

    test('appliesSlow is true only when both values are set', () {
      expect(makeProjectile(slowAmount: 0.5, slowDuration: 0).appliesSlow, isFalse);
      expect(makeProjectile(slowAmount: 0, slowDuration: 2.0).appliesSlow, isFalse);
      expect(makeProjectile(slowAmount: 0.5, slowDuration: 2.0).appliesSlow, isTrue);
    });
  });

  group('Projectile render', () {
    test('renders without exceptions', () {
      final projectile = makeProjectile();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      projectile.update(0.1);
      projectile.render(canvas);
      recorder.endRecording();
    });

    test('renders all tower types', () {
      for (final type in TowerType.values) {
        final projectile = makeProjectile(type: type);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        projectile.update(0.1);
        projectile.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with lowFx enabled', () {
      Projectile.lowFx = true;

      final projectile = makeProjectile();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      projectile.update(0.1);
      projectile.render(canvas);
      recorder.endRecording();

      Projectile.lowFx = false;
    });

    test('renders with trails disabled', () {
      Projectile.allowTrails = false;

      final projectile = makeProjectile();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      projectile.update(0.1);
      projectile.render(canvas);
      recorder.endRecording();

      Projectile.allowTrails = true;
    });

    test('renders with glow disabled', () {
      Projectile.allowGlow = false;

      final projectile = makeProjectile();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      projectile.update(0.1);
      projectile.render(canvas);
      recorder.endRecording();

      Projectile.allowGlow = true;
    });

    test('renders with different stress levels', () {
      for (final level in [0, 1, 2]) {
        Projectile.setStressLevel(level);

        final projectile = makeProjectile();

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        projectile.update(0.1);
        projectile.render(canvas);
        recorder.endRecording();
      }

      Projectile.setStressLevel(0);
    });

    test('renders projectile moving over time', () {
      final projectile = makeProjectile(
        startPosition: Vector2(0, 0),
        targetPosition: Vector2(200, 0),
        speed: 50,
      );

      for (int i = 0; i < 10; i++) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        projectile.update(0.016);
        projectile.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with custom colors', () {
      final colors = [
        Colors.red,
        Colors.green,
        Colors.blue,
        Colors.purple,
        Colors.yellow,
      ];

      for (final color in colors) {
        final projectile = makeProjectile(color: color);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        projectile.update(0.1);
        projectile.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders pulseArcher projectile effect', () {
      final projectile = makeProjectile(type: TowerType.pulseArcher);

      // Let animation run
      for (int i = 0; i < 30; i++) {
        projectile.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      projectile.render(canvas);
      recorder.endRecording();
    });

    test('renders circuitCannon projectile effect', () {
      final projectile = makeProjectile(type: TowerType.circuitCannon);

      for (int i = 0; i < 30; i++) {
        projectile.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      projectile.render(canvas);
      recorder.endRecording();
    });

    test('renders phaseMage projectile effect', () {
      final projectile = makeProjectile(type: TowerType.phaseMage);

      for (int i = 0; i < 30; i++) {
        projectile.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      projectile.render(canvas);
      recorder.endRecording();
    });

    test('renders ionSniper projectile effect', () {
      final projectile = makeProjectile(type: TowerType.ionSniper);

      for (int i = 0; i < 30; i++) {
        projectile.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      projectile.render(canvas);
      recorder.endRecording();
    });

    test('renders glimmerField projectile effect', () {
      final projectile = makeProjectile(type: TowerType.glimmerField);

      for (int i = 0; i < 30; i++) {
        projectile.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      projectile.render(canvas);
      recorder.endRecording();
    });

    test('renders neuralDisruptor projectile effect', () {
      final projectile = makeProjectile(type: TowerType.neuralDisruptor);

      for (int i = 0; i < 30; i++) {
        projectile.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      projectile.render(canvas);
      recorder.endRecording();
    });
  });
}
