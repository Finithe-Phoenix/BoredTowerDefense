import 'dart:ui' as ui;

import 'package:flame/components.dart' hide Vector3;
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/enemy.dart';
import 'package:bored_games/src/game/fps/fps_enemy_3d.dart';
import 'package:bored_games/src/game/fps/fps_camera_3d.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Enemy3DShape enum', () {
    test('has 10 shape types', () {
      expect(Enemy3DShape.values.length, 10);
    });

    test('contains sphere shape', () {
      expect(Enemy3DShape.values, contains(Enemy3DShape.sphere));
    });

    test('contains cube shape', () {
      expect(Enemy3DShape.values, contains(Enemy3DShape.cube));
    });

    test('contains pyramid shape', () {
      expect(Enemy3DShape.values, contains(Enemy3DShape.pyramid));
    });

    test('contains ghost shape', () {
      expect(Enemy3DShape.values, contains(Enemy3DShape.ghost));
    });

    test('contains crystal shape', () {
      expect(Enemy3DShape.values, contains(Enemy3DShape.crystal));
    });

    test('contains hexagon shape', () {
      expect(Enemy3DShape.values, contains(Enemy3DShape.hexagon));
    });

    test('contains spike shape', () {
      expect(Enemy3DShape.values, contains(Enemy3DShape.spike));
    });

    test('contains worm shape', () {
      expect(Enemy3DShape.values, contains(Enemy3DShape.worm));
    });

    test('contains void_entity shape', () {
      expect(Enemy3DShape.values, contains(Enemy3DShape.void_entity));
    });

    test('contains boss shape', () {
      expect(Enemy3DShape.values, contains(Enemy3DShape.boss));
    });
  });

  group('Enemy3D creation', () {
    test('creates with required parameters', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3(0, 0, 10),
      );

      expect(enemy3d, isNotNull);
      expect(enemy3d.enemy, same(enemy));
    });

    test('creates with custom position3d', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3(100, 50, 200),
      );

      expect(enemy3d.position3d.x, 100);
      expect(enemy3d.position3d.y, 50);
      expect(enemy3d.position3d.z, 200);
    });

    test('creates with custom distanceToCamera', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3.zero(),
        distanceToCamera: 50.0,
      );

      expect(enemy3d.distanceToCamera, 50.0);
    });

    test('creates with isTargeted flag', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3.zero(),
        isTargeted: true,
      );

      expect(enemy3d.isTargeted, isTrue);
    });

    test('creates with custom animationPhase', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3.zero(),
        animationPhase: 1.5,
      );

      expect(enemy3d.animationPhase, 1.5);
    });

    test('defaults distanceToCamera to 0', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3.zero(),
      );

      expect(enemy3d.distanceToCamera, 0);
    });

    test('defaults isTargeted to false', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3.zero(),
      );

      expect(enemy3d.isTargeted, isFalse);
    });

    test('defaults animationPhase to 0', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3.zero(),
      );

      expect(enemy3d.animationPhase, 0);
    });
  });

  group('Enemy3D shape getter', () {
    test('returns sphere for basic enemy', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3.zero(),
      );

      expect(enemy3d.shape, Enemy3DShape.sphere);
    });
  });

  group('Enemy3D getBoundingBox', () {
    test('returns bounding box tuple', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3(100, 0, 100),
      );

      final (min, max) = enemy3d.getBoundingBox();

      expect(min, isA<Vector3>());
      expect(max, isA<Vector3>());
    });

    test('bounding box min is less than max', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3(50, 0, 50),
      );

      final (min, max) = enemy3d.getBoundingBox();

      expect(min.x, lessThan(max.x));
      expect(min.y, lessThan(max.y));
      expect(min.z, lessThan(max.z));
    });

    test('bounding box is centered on position', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3(100, 0, 100),
      );

      final (min, max) = enemy3d.getBoundingBox();
      final centerX = (min.x + max.x) / 2;
      final centerZ = (min.z + max.z) / 2;

      expect(centerX, closeTo(100, 0.01));
      expect(centerZ, closeTo(100, 0.01));
    });

    test('bounding box starts at ground level', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3(0, 0, 0),
      );

      final (min, _) = enemy3d.getBoundingBox();

      expect(min.y, 0);
    });
  });

  group('Enemy3D update', () {
    test('update advances animation phase', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3.zero(),
        animationPhase: 0,
      );

      enemy3d.update(0.1);

      expect(enemy3d.animationPhase, greaterThan(0));
    });

    test('update with zero dt does not change phase', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3.zero(),
        animationPhase: 1.0,
      );

      enemy3d.update(0.0);

      expect(enemy3d.animationPhase, 1.0);
    });

    test('update increases animation proportionally to dt', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3.zero(),
        animationPhase: 0,
      );

      enemy3d.update(1.0);
      final phase1 = enemy3d.animationPhase;

      final enemy3d2 = Enemy3D(
        enemy: enemy,
        position3d: Vector3.zero(),
        animationPhase: 0,
      );
      enemy3d2.update(2.0);

      expect(enemy3d2.animationPhase, closeTo(phase1 * 2, 0.01));
    });

    test('multiple updates work', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3.zero(),
      );

      for (int i = 0; i < 100; i++) {
        enemy3d.update(0.016);
      }

      expect(enemy3d.animationPhase, greaterThan(0));
    });
  });

  group('Enemy3D render', () {
    test('renders without exceptions', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3(0, 0, 50),
        distanceToCamera: 50,
      );

      final camera = Camera3D(
        position: Vector3(0, 30, 0),
        lookAt: Vector3(0, 0, 100),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final screenSize = Vector2(800, 600);

      enemy3d.update(0.1);
      enemy3d.render(canvas, camera, screenSize);
      recorder.endRecording();
    });

    test('renders with isTargeted true', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3(0, 0, 50),
        distanceToCamera: 50,
        isTargeted: true,
      );

      final camera = Camera3D(
        position: Vector3(0, 30, 0),
        lookAt: Vector3(0, 0, 100),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final screenSize = Vector2(800, 600);

      enemy3d.update(0.1);
      enemy3d.render(canvas, camera, screenSize);
      recorder.endRecording();
    });

    test('renders with damaged health', () {
      final enemy = Enemy(path: [Vector2.zero()], maxHealth: 100);
      enemy.takeDamage(50); // 50% health

      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3(0, 0, 50),
        distanceToCamera: 50,
      );

      final camera = Camera3D(
        position: Vector3(0, 30, 0),
        lookAt: Vector3(0, 0, 100),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final screenSize = Vector2(800, 600);

      enemy3d.update(0.1);
      enemy3d.render(canvas, camera, screenSize);
      recorder.endRecording();
    });

    test('renders with low health', () {
      final enemy = Enemy(path: [Vector2.zero()], maxHealth: 100);
      enemy.takeDamage(80); // 20% health

      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3(0, 0, 50),
        distanceToCamera: 50,
      );

      final camera = Camera3D(
        position: Vector3(0, 30, 0),
        lookAt: Vector3(0, 0, 100),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final screenSize = Vector2(800, 600);

      enemy3d.update(0.1);
      enemy3d.render(canvas, camera, screenSize);
      recorder.endRecording();
    });

    test('renders at various distances', () {
      final enemy = Enemy(path: [Vector2.zero()]);

      final camera = Camera3D(
        position: Vector3(0, 30, 0),
        lookAt: Vector3(0, 0, 100),
      );

      final distances = [10.0, 50.0, 100.0, 200.0];
      for (final distance in distances) {
        final enemy3d = Enemy3D(
          enemy: enemy,
          position3d: Vector3(0, 0, distance),
          distanceToCamera: distance,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        final screenSize = Vector2(800, 600);

        enemy3d.update(0.1);
        enemy3d.render(canvas, camera, screenSize);
        recorder.endRecording();
      }
    });

    test('renders at various screen sizes', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3(0, 0, 50),
        distanceToCamera: 50,
      );

      final camera = Camera3D(
        position: Vector3(0, 30, 0),
        lookAt: Vector3(0, 0, 100),
      );

      final screenSizes = [
        Vector2(320, 240),
        Vector2(800, 600),
        Vector2(1920, 1080),
      ];

      for (final size in screenSizes) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        enemy3d.update(0.1);
        enemy3d.render(canvas, camera, size);
        recorder.endRecording();
      }
    });
  });

  group('Enemy3D animation', () {
    test('animation phase affects rendering', () {
      final enemy = Enemy(path: [Vector2.zero()]);

      final camera = Camera3D(
        position: Vector3(0, 30, 0),
        lookAt: Vector3(0, 0, 100),
      );

      final screenSize = Vector2(800, 600);

      // Render at different animation phases
      for (double phase = 0; phase < 6.28; phase += 0.5) {
        final enemy3d = Enemy3D(
          enemy: enemy,
          position3d: Vector3(0, 0, 50),
          distanceToCamera: 50,
          animationPhase: phase,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        enemy3d.render(canvas, camera, screenSize);
        recorder.endRecording();
      }
    });
  });

  group('Enemy3D multiple instances', () {
    test('multiple enemies can exist independently', () {
      final enemy1 = Enemy(path: [Vector2.zero()]);
      final enemy2 = Enemy(path: [Vector2.zero()]);

      final enemy3d1 = Enemy3D(
        enemy: enemy1,
        position3d: Vector3(0, 0, 50),
        distanceToCamera: 50,
      );

      final enemy3d2 = Enemy3D(
        enemy: enemy2,
        position3d: Vector3(100, 0, 100),
        distanceToCamera: 100,
      );

      enemy3d1.update(0.1);
      enemy3d2.update(0.2);

      expect(enemy3d1.position3d.x, isNot(enemy3d2.position3d.x));
      expect(enemy3d1.distanceToCamera, isNot(enemy3d2.distanceToCamera));
    });

    test('multiple enemies can render independently', () {
      final enemy1 = Enemy(path: [Vector2.zero()]);
      final enemy2 = Enemy(path: [Vector2.zero()]);

      final enemy3d1 = Enemy3D(
        enemy: enemy1,
        position3d: Vector3(0, 0, 50),
        distanceToCamera: 50,
      );

      final enemy3d2 = Enemy3D(
        enemy: enemy2,
        position3d: Vector3(50, 0, 75),
        distanceToCamera: 75,
      );

      final camera = Camera3D(
        position: Vector3(0, 30, 0),
        lookAt: Vector3(0, 0, 100),
      );

      final screenSize = Vector2(800, 600);

      final recorder1 = ui.PictureRecorder();
      final canvas1 = ui.Canvas(recorder1);

      final recorder2 = ui.PictureRecorder();
      final canvas2 = ui.Canvas(recorder2);

      enemy3d1.update(0.1);
      enemy3d2.update(0.1);

      enemy3d1.render(canvas1, camera, screenSize);
      enemy3d2.render(canvas2, camera, screenSize);

      recorder1.endRecording();
      recorder2.endRecording();
    });
  });

  group('Enemy3D edge cases', () {
    test('handles enemy behind camera', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3(0, 0, -50), // Behind camera
        distanceToCamera: 50,
      );

      final camera = Camera3D(
        position: Vector3(0, 30, 0),
        lookAt: Vector3(0, 0, 100),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final screenSize = Vector2(800, 600);

      enemy3d.update(0.1);
      enemy3d.render(canvas, camera, screenSize);
      recorder.endRecording();
    });

    test('handles very close distance', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3(0, 0, 1),
        distanceToCamera: 1,
      );

      final camera = Camera3D(
        position: Vector3(0, 30, 0),
        lookAt: Vector3(0, 0, 100),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final screenSize = Vector2(800, 600);

      enemy3d.update(0.1);
      enemy3d.render(canvas, camera, screenSize);
      recorder.endRecording();
    });

    test('handles very far distance', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3(0, 0, 1000),
        distanceToCamera: 1000,
      );

      final camera = Camera3D(
        position: Vector3(0, 30, 0),
        lookAt: Vector3(0, 0, 1000),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final screenSize = Vector2(800, 600);

      enemy3d.update(0.1);
      enemy3d.render(canvas, camera, screenSize);
      recorder.endRecording();
    });

    test('handles negative position', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3(-100, -50, -200),
        distanceToCamera: 100,
      );

      expect(enemy3d.position3d.x, -100);
      expect(enemy3d.position3d.y, -50);
      expect(enemy3d.position3d.z, -200);
    });

    test('handles zero distance to camera', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: Vector3.zero(),
        distanceToCamera: 0,
      );

      final camera = Camera3D(
        position: Vector3(0, 30, 0),
        lookAt: Vector3(0, 0, 100),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final screenSize = Vector2(800, 600);

      enemy3d.update(0.1);
      enemy3d.render(canvas, camera, screenSize);
      recorder.endRecording();
    });
  });

  group('Enemy3D static paints', () {
    test('static paints are reused across instances', () {
      final enemy1 = Enemy(path: [Vector2.zero()]);
      final enemy2 = Enemy(path: [Vector2.zero()]);

      final enemy3d1 = Enemy3D(
        enemy: enemy1,
        position3d: Vector3(0, 0, 50),
      );

      final enemy3d2 = Enemy3D(
        enemy: enemy2,
        position3d: Vector3(100, 0, 100),
      );

      final camera = Camera3D(
        position: Vector3(0, 30, 0),
        lookAt: Vector3(0, 0, 100),
      );

      final screenSize = Vector2(800, 600);

      // Both should render without memory issues (static paints reused)
      final recorder1 = ui.PictureRecorder();
      final canvas1 = ui.Canvas(recorder1);
      enemy3d1.update(0.1);
      enemy3d1.render(canvas1, camera, screenSize);
      recorder1.endRecording();

      final recorder2 = ui.PictureRecorder();
      final canvas2 = ui.Canvas(recorder2);
      enemy3d2.update(0.1);
      enemy3d2.render(canvas2, camera, screenSize);
      recorder2.endRecording();
    });
  });
}
