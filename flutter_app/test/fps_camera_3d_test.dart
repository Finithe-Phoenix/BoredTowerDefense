import 'package:flame/components.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/fps/fps_camera_3d.dart';

void main() {
  test('Vector3 math operations behave as expected', () {
    final a = Vector3(1, 2, 3);
    final b = Vector3(4, 5, 6);

    final sum = a + b;
    expect(sum.x, 5);
    expect(sum.y, 7);
    expect(sum.z, 9);

    final diff = b - a;
    expect(diff.x, 3);
    expect(diff.y, 3);
    expect(diff.z, 3);

    final scaled = a * 2;
    expect(scaled.x, 2);
    expect(scaled.y, 4);
    expect(scaled.z, 6);

    expect(a.length, closeTo(3.7416, 0.0001));
    expect(a.distanceTo(b), closeTo(5.1961, 0.0001));

    final unit = Vector3(0, 0, 0).normalized();
    expect(unit.x, 0);
    expect(unit.y, 0);
    expect(unit.z, 0);

    final dot = a.dot(b);
    expect(dot, 32);

    final cross = a.cross(b);
    expect(cross.x, -3);
    expect(cross.y, 6);
    expect(cross.z, -3);
  });

  test('Ray intersects axis-aligned bounding box', () {
    final ray = Ray(Vector3(0, 0, -10), Vector3(0, 0, 1));
    final hit = ray.intersectsAABB(Vector3(-1, -1, 0), Vector3(1, 1, 2));
    expect(hit, closeTo(10, 0.0001));

    final miss = Ray(Vector3(0, 0, -10), Vector3(0, 0, -1))
        .intersectsAABB(Vector3(-1, -1, 0), Vector3(1, 1, 2));
    expect(miss, isNull);
  });

  test('Camera3D projects points and creates rays', () {
    final camera = Camera3D(
      position: Vector3(0, 0, 0),
      lookAt: Vector3(0, 0, 1),
    );
    final screenSize = Vector2(800, 600);

    final center = camera.project(Vector3(0, 0, 5), screenSize);
    expect(center, isNotNull);
    expect(center!.x, closeTo(400, 0.1));
    expect(center.y, closeTo(300, 0.1));

    final behind = camera.project(Vector3(0, 0, -1), screenSize);
    expect(behind, isNull);

    final offscreen = camera.project(Vector3(1000, 0, 5), screenSize);
    expect(offscreen, isNull);

    final ray = camera.createRayFromScreen(Vector2(400, 300), screenSize);
    expect(ray.direction.z, greaterThan(0.9));
    expect(ray.direction.x.abs(), lessThan(0.05));
    expect(ray.direction.y.abs(), lessThan(0.05));

    expect(camera.distanceTo(Vector3(0, 0, 10)), closeTo(10, 0.0001));
  });
}
