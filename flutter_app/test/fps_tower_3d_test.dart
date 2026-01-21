import 'dart:ui';

import 'package:flame/components.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/tower.dart';
import 'package:bored_games/src/game/fps/fps_camera_3d.dart';
import 'package:bored_games/src/game/fps/fps_tower_3d.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Tower3D bounding box and render output', () {
    final tower = Tower(
      position: Vector2.zero(),
      size: 40,
    );

    final tower3d = Tower3D(
      tower: tower,
      position3d: Vector3(0, 0, 100),
      distanceToCamera: 100,
      isHovered: true,
      isSelected: true,
    );

    final (min, max) = tower3d.getBoundingBox();
    expect(min.x, closeTo(-20, 0.001));
    expect(min.y, closeTo(0, 0.001));
    expect(min.z, closeTo(80, 0.001));
    expect(max.x, closeTo(20, 0.001));
    expect(max.y, closeTo(60, 0.001));
    expect(max.z, closeTo(120, 0.001));

    final camera = Camera3D(
      position: Vector3(0, 0, 0),
      lookAt: Vector3(0, 0, 1),
    );

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    tower3d.render(canvas, camera, Vector2(800, 600));
    recorder.endRecording();
  });
}
