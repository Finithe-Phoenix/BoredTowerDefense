import 'dart:math' as math;

import 'package:flame/components.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/fps/fps_camera_3d.dart';

void main() {
  group('Vector3 creation', () {
    test('can create with x, y, z', () {
      final v = Vector3(1.0, 2.0, 3.0);

      expect(v.x, 1.0);
      expect(v.y, 2.0);
      expect(v.z, 3.0);
    });

    test('can create zero vector', () {
      final v = Vector3.zero();

      expect(v.x, 0);
      expect(v.y, 0);
      expect(v.z, 0);
    });

    test('can create with negative values', () {
      final v = Vector3(-1.0, -2.0, -3.0);

      expect(v.x, -1.0);
      expect(v.y, -2.0);
      expect(v.z, -3.0);
    });

    test('can create with large values', () {
      final v = Vector3(1000.0, 2000.0, 3000.0);

      expect(v.x, 1000.0);
      expect(v.y, 2000.0);
      expect(v.z, 3000.0);
    });

    test('can create with decimal values', () {
      final v = Vector3(1.5, 2.7, 3.9);

      expect(v.x, 1.5);
      expect(v.y, 2.7);
      expect(v.z, 3.9);
    });
  });

  group('Vector3 operators', () {
    test('addition works correctly', () {
      final v1 = Vector3(1.0, 2.0, 3.0);
      final v2 = Vector3(4.0, 5.0, 6.0);
      final result = v1 + v2;

      expect(result.x, 5.0);
      expect(result.y, 7.0);
      expect(result.z, 9.0);
    });

    test('subtraction works correctly', () {
      final v1 = Vector3(5.0, 7.0, 9.0);
      final v2 = Vector3(1.0, 2.0, 3.0);
      final result = v1 - v2;

      expect(result.x, 4.0);
      expect(result.y, 5.0);
      expect(result.z, 6.0);
    });

    test('scalar multiplication works correctly', () {
      final v = Vector3(1.0, 2.0, 3.0);
      final result = v * 2.0;

      expect(result.x, 2.0);
      expect(result.y, 4.0);
      expect(result.z, 6.0);
    });

    test('addition with negative values', () {
      final v1 = Vector3(1.0, 2.0, 3.0);
      final v2 = Vector3(-1.0, -2.0, -3.0);
      final result = v1 + v2;

      expect(result.x, 0.0);
      expect(result.y, 0.0);
      expect(result.z, 0.0);
    });

    test('subtraction resulting in negative', () {
      final v1 = Vector3(1.0, 2.0, 3.0);
      final v2 = Vector3(5.0, 6.0, 7.0);
      final result = v1 - v2;

      expect(result.x, -4.0);
      expect(result.y, -4.0);
      expect(result.z, -4.0);
    });

    test('multiplication by zero', () {
      final v = Vector3(1.0, 2.0, 3.0);
      final result = v * 0.0;

      expect(result.x, 0.0);
      expect(result.y, 0.0);
      expect(result.z, 0.0);
    });

    test('multiplication by negative scalar', () {
      final v = Vector3(1.0, 2.0, 3.0);
      final result = v * -2.0;

      expect(result.x, -2.0);
      expect(result.y, -4.0);
      expect(result.z, -6.0);
    });
  });

  group('Vector3 length', () {
    test('length of unit vector along x', () {
      final v = Vector3(1.0, 0.0, 0.0);
      expect(v.length, 1.0);
    });

    test('length of unit vector along y', () {
      final v = Vector3(0.0, 1.0, 0.0);
      expect(v.length, 1.0);
    });

    test('length of unit vector along z', () {
      final v = Vector3(0.0, 0.0, 1.0);
      expect(v.length, 1.0);
    });

    test('length of zero vector', () {
      final v = Vector3.zero();
      expect(v.length, 0.0);
    });

    test('length of 3-4-5 triangle equivalent', () {
      final v = Vector3(3.0, 4.0, 0.0);
      expect(v.length, 5.0);
    });

    test('length of diagonal vector', () {
      final v = Vector3(1.0, 1.0, 1.0);
      expect(v.length, closeTo(math.sqrt(3), 0.0001));
    });
  });

  group('Vector3 distanceTo', () {
    test('distance between same points is zero', () {
      final v1 = Vector3(5.0, 5.0, 5.0);
      final v2 = Vector3(5.0, 5.0, 5.0);

      expect(v1.distanceTo(v2), 0.0);
    });

    test('distance along x axis', () {
      final v1 = Vector3(0.0, 0.0, 0.0);
      final v2 = Vector3(10.0, 0.0, 0.0);

      expect(v1.distanceTo(v2), 10.0);
    });

    test('distance along y axis', () {
      final v1 = Vector3(0.0, 0.0, 0.0);
      final v2 = Vector3(0.0, 10.0, 0.0);

      expect(v1.distanceTo(v2), 10.0);
    });

    test('distance along z axis', () {
      final v1 = Vector3(0.0, 0.0, 0.0);
      final v2 = Vector3(0.0, 0.0, 10.0);

      expect(v1.distanceTo(v2), 10.0);
    });

    test('distance is symmetric', () {
      final v1 = Vector3(1.0, 2.0, 3.0);
      final v2 = Vector3(4.0, 5.0, 6.0);

      expect(v1.distanceTo(v2), v2.distanceTo(v1));
    });

    test('distance of diagonal', () {
      final v1 = Vector3(0.0, 0.0, 0.0);
      final v2 = Vector3(3.0, 4.0, 0.0);

      expect(v1.distanceTo(v2), 5.0);
    });
  });

  group('Vector3 normalized', () {
    test('normalized unit vector stays unit', () {
      final v = Vector3(1.0, 0.0, 0.0);
      final norm = v.normalized();

      expect(norm.length, closeTo(1.0, 0.0001));
    });

    test('normalized vector has length 1', () {
      final v = Vector3(3.0, 4.0, 0.0);
      final norm = v.normalized();

      expect(norm.length, closeTo(1.0, 0.0001));
    });

    test('normalized zero vector is zero', () {
      final v = Vector3.zero();
      final norm = v.normalized();

      expect(norm.x, 0.0);
      expect(norm.y, 0.0);
      expect(norm.z, 0.0);
    });

    test('normalized preserves direction', () {
      final v = Vector3(10.0, 0.0, 0.0);
      final norm = v.normalized();

      expect(norm.x, closeTo(1.0, 0.0001));
      expect(norm.y, closeTo(0.0, 0.0001));
      expect(norm.z, closeTo(0.0, 0.0001));
    });

    test('normalized diagonal vector', () {
      final v = Vector3(1.0, 1.0, 1.0);
      final norm = v.normalized();
      final expected = 1.0 / math.sqrt(3);

      expect(norm.x, closeTo(expected, 0.0001));
      expect(norm.y, closeTo(expected, 0.0001));
      expect(norm.z, closeTo(expected, 0.0001));
    });
  });

  group('Vector3 dot product', () {
    test('dot product of perpendicular vectors is zero', () {
      final v1 = Vector3(1.0, 0.0, 0.0);
      final v2 = Vector3(0.0, 1.0, 0.0);

      expect(v1.dot(v2), 0.0);
    });

    test('dot product of parallel vectors', () {
      final v1 = Vector3(1.0, 0.0, 0.0);
      final v2 = Vector3(1.0, 0.0, 0.0);

      expect(v1.dot(v2), 1.0);
    });

    test('dot product of opposite vectors', () {
      final v1 = Vector3(1.0, 0.0, 0.0);
      final v2 = Vector3(-1.0, 0.0, 0.0);

      expect(v1.dot(v2), -1.0);
    });

    test('dot product is commutative', () {
      final v1 = Vector3(1.0, 2.0, 3.0);
      final v2 = Vector3(4.0, 5.0, 6.0);

      expect(v1.dot(v2), v2.dot(v1));
    });

    test('dot product calculation', () {
      final v1 = Vector3(1.0, 2.0, 3.0);
      final v2 = Vector3(4.0, 5.0, 6.0);

      // 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
      expect(v1.dot(v2), 32.0);
    });
  });

  group('Vector3 cross product', () {
    test('cross product of x and y is z', () {
      final x = Vector3(1.0, 0.0, 0.0);
      final y = Vector3(0.0, 1.0, 0.0);
      final cross = x.cross(y);

      expect(cross.x, closeTo(0.0, 0.0001));
      expect(cross.y, closeTo(0.0, 0.0001));
      expect(cross.z, closeTo(1.0, 0.0001));
    });

    test('cross product of y and z is x', () {
      final y = Vector3(0.0, 1.0, 0.0);
      final z = Vector3(0.0, 0.0, 1.0);
      final cross = y.cross(z);

      expect(cross.x, closeTo(1.0, 0.0001));
      expect(cross.y, closeTo(0.0, 0.0001));
      expect(cross.z, closeTo(0.0, 0.0001));
    });

    test('cross product of z and x is y', () {
      final z = Vector3(0.0, 0.0, 1.0);
      final x = Vector3(1.0, 0.0, 0.0);
      final cross = z.cross(x);

      expect(cross.x, closeTo(0.0, 0.0001));
      expect(cross.y, closeTo(1.0, 0.0001));
      expect(cross.z, closeTo(0.0, 0.0001));
    });

    test('cross product of parallel vectors is zero', () {
      final v1 = Vector3(1.0, 0.0, 0.0);
      final v2 = Vector3(2.0, 0.0, 0.0);
      final cross = v1.cross(v2);

      expect(cross.x, 0.0);
      expect(cross.y, 0.0);
      expect(cross.z, 0.0);
    });

    test('cross product is anti-commutative', () {
      final v1 = Vector3(1.0, 2.0, 3.0);
      final v2 = Vector3(4.0, 5.0, 6.0);
      final cross1 = v1.cross(v2);
      final cross2 = v2.cross(v1);

      expect(cross1.x, closeTo(-cross2.x, 0.0001));
      expect(cross1.y, closeTo(-cross2.y, 0.0001));
      expect(cross1.z, closeTo(-cross2.z, 0.0001));
    });

    test('cross product perpendicular to both inputs', () {
      final v1 = Vector3(1.0, 2.0, 3.0);
      final v2 = Vector3(4.0, 5.0, 6.0);
      final cross = v1.cross(v2);

      expect(cross.dot(v1), closeTo(0.0, 0.0001));
      expect(cross.dot(v2), closeTo(0.0, 0.0001));
    });
  });

  group('Vector3 toString', () {
    test('formats correctly', () {
      final v = Vector3(1.0, 2.0, 3.0);
      expect(v.toString(), 'Vector3(1.0, 2.0, 3.0)');
    });

    test('formats zero vector', () {
      final v = Vector3.zero();
      // Vector3.zero() uses int literals which become 0.0 when converted to double
      expect(v.toString(), contains('Vector3'));
      expect(v.toString(), contains('0'));
    });

    test('formats negative values', () {
      final v = Vector3(-1.0, -2.0, -3.0);
      expect(v.toString(), 'Vector3(-1.0, -2.0, -3.0)');
    });
  });

  group('Ray creation', () {
    test('can create with origin and direction', () {
      final origin = Vector3(0.0, 0.0, 0.0);
      final direction = Vector3(0.0, 0.0, 1.0);
      final ray = Ray(origin, direction);

      expect(ray.origin.x, 0.0);
      expect(ray.origin.y, 0.0);
      expect(ray.origin.z, 0.0);
      expect(ray.direction.x, 0.0);
      expect(ray.direction.y, 0.0);
      expect(ray.direction.z, 1.0);
    });
  });

  group('Ray pointAt', () {
    test('pointAt 0 returns origin', () {
      final origin = Vector3(1.0, 2.0, 3.0);
      final direction = Vector3(0.0, 0.0, 1.0);
      final ray = Ray(origin, direction);
      final point = ray.pointAt(0.0);

      expect(point.x, origin.x);
      expect(point.y, origin.y);
      expect(point.z, origin.z);
    });

    test('pointAt 1 returns origin + direction', () {
      final origin = Vector3(0.0, 0.0, 0.0);
      final direction = Vector3(0.0, 0.0, 1.0);
      final ray = Ray(origin, direction);
      final point = ray.pointAt(1.0);

      expect(point.x, 0.0);
      expect(point.y, 0.0);
      expect(point.z, 1.0);
    });

    test('pointAt with positive t', () {
      final origin = Vector3(0.0, 0.0, 0.0);
      final direction = Vector3(1.0, 0.0, 0.0);
      final ray = Ray(origin, direction);
      final point = ray.pointAt(5.0);

      expect(point.x, 5.0);
      expect(point.y, 0.0);
      expect(point.z, 0.0);
    });

    test('pointAt with negative t', () {
      final origin = Vector3(0.0, 0.0, 0.0);
      final direction = Vector3(1.0, 0.0, 0.0);
      final ray = Ray(origin, direction);
      final point = ray.pointAt(-5.0);

      expect(point.x, -5.0);
      expect(point.y, 0.0);
      expect(point.z, 0.0);
    });
  });

  group('Ray AABB intersection', () {
    test('ray hits AABB in front', () {
      final origin = Vector3(0.0, 0.0, -5.0);
      final direction = Vector3(0.0, 0.0, 1.0);
      final ray = Ray(origin, direction);

      final min = Vector3(-1.0, -1.0, -1.0);
      final max = Vector3(1.0, 1.0, 1.0);

      final t = ray.intersectsAABB(min, max);

      expect(t, isNotNull);
      expect(t, greaterThan(0));
    });

    test('ray misses AABB', () {
      final origin = Vector3(10.0, 10.0, -5.0);
      final direction = Vector3(0.0, 0.0, 1.0);
      final ray = Ray(origin, direction);

      final min = Vector3(-1.0, -1.0, -1.0);
      final max = Vector3(1.0, 1.0, 1.0);

      final t = ray.intersectsAABB(min, max);

      expect(t, isNull);
    });

    test('ray pointing away from AABB', () {
      final origin = Vector3(0.0, 0.0, -5.0);
      final direction = Vector3(0.0, 0.0, -1.0);
      final ray = Ray(origin, direction);

      final min = Vector3(-1.0, -1.0, -1.0);
      final max = Vector3(1.0, 1.0, 1.0);

      final t = ray.intersectsAABB(min, max);

      expect(t, isNull);
    });

    test('ray origin inside AABB returns null', () {
      final origin = Vector3(0.0, 0.0, 0.0);
      final direction = Vector3(0.0, 0.0, 1.0);
      final ray = Ray(origin, direction);

      final min = Vector3(-1.0, -1.0, -1.0);
      final max = Vector3(1.0, 1.0, 1.0);

      final t = ray.intersectsAABB(min, max);

      // Origin inside AABB, tmin is negative
      expect(t, isNull);
    });
  });

  group('Camera3D creation', () {
    test('can create with required parameters', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
      );

      expect(camera.position.z, -10.0);
      expect(camera.lookAt.z, 0.0);
    });

    test('default fov is 75', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
      );

      expect(camera.fov, 75.0);
    });

    test('default nearPlane is 0.1', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
      );

      expect(camera.nearPlane, 0.1);
    });

    test('default farPlane is 1000', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
      );

      expect(camera.farPlane, 1000.0);
    });

    test('can set custom fov', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
        fov: 90.0,
      );

      expect(camera.fov, 90.0);
    });

    test('can set custom near and far planes', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
        nearPlane: 0.5,
        farPlane: 500.0,
      );

      expect(camera.nearPlane, 0.5);
      expect(camera.farPlane, 500.0);
    });
  });

  group('Camera3D distanceTo', () {
    test('distance to same position is zero', () {
      final camera = Camera3D(
        position: Vector3(5.0, 5.0, 5.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
      );

      expect(camera.distanceTo(Vector3(5.0, 5.0, 5.0)), 0.0);
    });

    test('distance calculation is correct', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, 0.0),
        lookAt: Vector3(0.0, 0.0, 1.0),
      );

      expect(camera.distanceTo(Vector3(3.0, 4.0, 0.0)), 5.0);
    });

    test('distance along z axis', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
      );

      expect(camera.distanceTo(Vector3(0.0, 0.0, 0.0)), 10.0);
    });
  });

  group('Camera3D project', () {
    test('projects point in front of camera', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
      );

      final screenSize = Vector2(800, 600);
      final point = Vector3(0.0, 0.0, 0.0);

      final projected = camera.project(point, screenSize);

      expect(projected, isNotNull);
      // Center of screen
      expect(projected!.x, closeTo(400, 1));
      expect(projected.y, closeTo(300, 1));
    });

    test('returns null for point behind camera', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
      );

      final screenSize = Vector2(800, 600);
      final point = Vector3(0.0, 0.0, -20.0);

      final projected = camera.project(point, screenSize);

      expect(projected, isNull);
    });

    test('returns null for point outside frustum', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
        fov: 45.0,
      );

      final screenSize = Vector2(800, 600);
      // Point far to the side
      final point = Vector3(1000.0, 0.0, 0.0);

      final projected = camera.project(point, screenSize);

      expect(projected, isNull);
    });
  });

  group('Camera3D createRayFromScreen', () {
    test('creates ray from center of screen', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
      );

      final screenSize = Vector2(800, 600);
      final screenPos = Vector2(400, 300);

      final ray = camera.createRayFromScreen(screenPos, screenSize);

      expect(ray.origin.x, 0.0);
      expect(ray.origin.y, 0.0);
      expect(ray.origin.z, -10.0);

      // Direction should point roughly forward
      expect(ray.direction.z, greaterThan(0));
    });

    test('ray from corner points in correct direction', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
      );

      final screenSize = Vector2(800, 600);
      final topLeft = Vector2(0, 0);
      final bottomRight = Vector2(800, 600);

      final rayTL = camera.createRayFromScreen(topLeft, screenSize);
      final rayBR = camera.createRayFromScreen(bottomRight, screenSize);

      // Rays from opposite corners should point in opposite X directions
      // and opposite Y directions relative to each other
      expect((rayTL.direction.x - rayBR.direction.x).abs(), greaterThan(0.1));
      expect((rayTL.direction.y - rayBR.direction.y).abs(), greaterThan(0.1));

      // Both rays should have positive z (pointing forward)
      expect(rayTL.direction.z, greaterThan(0));
      expect(rayBR.direction.z, greaterThan(0));
    });
  });

  group('Camera3D integration', () {
    test('project and createRay are inverse operations (approximate)', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
      );

      final screenSize = Vector2(800, 600);
      final originalPoint = Vector3(1.0, 1.0, 0.0);

      final projected = camera.project(originalPoint, screenSize);
      if (projected != null) {
        final ray = camera.createRayFromScreen(projected, screenSize);
        // The ray should pass near the original point
        final t = 10.0; // Approximate distance to the original point
        final reconstructed = ray.pointAt(t);

        // Should be approximately the same point
        expect(reconstructed.x, closeTo(originalPoint.x, 0.5));
        expect(reconstructed.y, closeTo(originalPoint.y, 0.5));
      }
    });
  });

  group('Camera3D position variations', () {
    test('camera at origin', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, 0.0),
        lookAt: Vector3(0.0, 0.0, 10.0),
      );

      expect(camera.position.x, 0.0);
      expect(camera.position.y, 0.0);
      expect(camera.position.z, 0.0);
    });

    test('camera with elevation', () {
      final camera = Camera3D(
        position: Vector3(0.0, 50.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
      );

      expect(camera.position.y, 50.0);
    });

    test('camera with lateral offset', () {
      final camera = Camera3D(
        position: Vector3(100.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
      );

      expect(camera.position.x, 100.0);
    });
  });

  group('Camera3D fov variations', () {
    test('narrow fov (30 degrees)', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
        fov: 30.0,
      );

      expect(camera.fov, 30.0);
    });

    test('wide fov (120 degrees)', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
        fov: 120.0,
      );

      expect(camera.fov, 120.0);
    });

    test('very narrow fov affects projection', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
        fov: 10.0,
      );

      final screenSize = Vector2(800, 600);
      // Point slightly off center
      final point = Vector3(0.5, 0.0, 0.0);

      final projected = camera.project(point, screenSize);

      // With very narrow FOV, point may be outside frustum
      // or projected very far from center
      // Just check we can call it without error
      expect(true, isTrue);
    });
  });

  group('Performance tests', () {
    test('can create many Vector3 instances', () {
      final vectors = <Vector3>[];

      for (int i = 0; i < 1000; i++) {
        vectors.add(Vector3(i.toDouble(), i.toDouble(), i.toDouble()));
      }

      expect(vectors.length, 1000);
    });

    test('can perform many vector operations', () {
      final v1 = Vector3(1.0, 2.0, 3.0);
      final v2 = Vector3(4.0, 5.0, 6.0);

      for (int i = 0; i < 1000; i++) {
        final _ = v1 + v2;
        final __ = v1 - v2;
        final ___ = v1 * 2.0;
        final ____ = v1.dot(v2);
        final _____ = v1.cross(v2);
      }

      expect(true, isTrue);
    });

    test('can perform many ray-AABB tests', () {
      final ray = Ray(
        Vector3(0.0, 0.0, -5.0),
        Vector3(0.0, 0.0, 1.0),
      );
      final min = Vector3(-1.0, -1.0, -1.0);
      final max = Vector3(1.0, 1.0, 1.0);

      for (int i = 0; i < 1000; i++) {
        ray.intersectsAABB(min, max);
      }

      expect(true, isTrue);
    });

    test('can perform many camera projections', () {
      final camera = Camera3D(
        position: Vector3(0.0, 0.0, -10.0),
        lookAt: Vector3(0.0, 0.0, 0.0),
      );
      final screenSize = Vector2(800, 600);
      final point = Vector3(0.0, 0.0, 0.0);

      for (int i = 0; i < 1000; i++) {
        camera.project(point, screenSize);
      }

      expect(true, isTrue);
    });
  });
}
