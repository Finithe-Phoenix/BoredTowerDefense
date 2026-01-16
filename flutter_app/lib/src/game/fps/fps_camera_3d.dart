import 'dart:math' as math;
import 'package:flame/components.dart';

/// 3D vector class for camera calculations
class Vector3 {
  double x, y, z;

  Vector3(this.x, this.y, this.z);

  Vector3.zero() : x = 0, y = 0, z = 0;

  Vector3 operator +(Vector3 other) => Vector3(x + other.x, y + other.y, z + other.z);
  Vector3 operator -(Vector3 other) => Vector3(x - other.x, y - other.y, z - other.z);
  Vector3 operator *(double scalar) => Vector3(x * scalar, y * scalar, z * scalar);

  double get length => math.sqrt(x * x + y * y + z * z);
  
  double distanceTo(Vector3 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  Vector3 normalized() {
    final len = length;
    if (len == 0) return Vector3.zero();
    return Vector3(x / len, y / len, z / len);
  }

  double dot(Vector3 other) => x * other.x + y * other.y + z * other.z;

  Vector3 cross(Vector3 other) => Vector3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  @override
  String toString() => 'Vector3($x, $y, $z)';
}

/// Ray for raycasting
class Ray {
  final Vector3 origin;
  final Vector3 direction;

  Ray(this.origin, this.direction);

  Vector3 pointAt(double t) => origin + (direction * t);

  /// Check intersection with axis-aligned bounding box
  /// Returns distance to intersection, or null if no intersection
  double? intersectsAABB(Vector3 min, Vector3 max) {
    double tmin = (min.x - origin.x) / direction.x;
    double tmax = (max.x - origin.x) / direction.x;

    if (tmin > tmax) {
      final temp = tmin;
      tmin = tmax;
      tmax = temp;
    }

    double tymin = (min.y - origin.y) / direction.y;
    double tymax = (max.y - origin.y) / direction.y;

    if (tymin > tymax) {
      final temp = tymin;
      tymin = tymax;
      tymax = temp;
    }

    if ((tmin > tymax) || (tymin > tmax)) return null;

    if (tymin > tmin) tmin = tymin;
    if (tymax < tmax) tmax = tymax;

    double tzmin = (min.z - origin.z) / direction.z;
    double tzmax = (max.z - origin.z) / direction.z;

    if (tzmin > tzmax) {
      final temp = tzmin;
      tzmin = tzmax;
      tzmax = temp;
    }

    if ((tmin > tzmax) || (tzmin > tmax)) return null;

    if (tzmin > tmin) tmin = tzmin;

    return tmin > 0 ? tmin : null;
  }
}

/// 3D Camera with perspective projection
class Camera3D {
  Vector3 position;
  Vector3 lookAt;
  double fov; // Field of view in degrees
  double nearPlane;
  double farPlane;

  Camera3D({
    required this.position,
    required this.lookAt,
    this.fov = 75.0,
    this.nearPlane = 0.1,
    this.farPlane = 1000.0,
  });

  /// Project a 3D point to 2D screen coordinates
  /// Returns null if point is behind camera or outside view frustum
  Vector2? project(Vector3 point, Vector2 screenSize) {
    // Transform to camera space
    final forward = (lookAt - position).normalized();
    final right = forward.cross(Vector3(0, 1, 0)).normalized();
    final up = right.cross(forward).normalized();

    final relative = point - position;

    // Camera space coordinates
    final x = relative.dot(right);
    final y = relative.dot(up);
    final z = relative.dot(forward);

    // Behind camera
    if (z <= nearPlane) return null;

    // Perspective projection
    final aspectRatio = screenSize.x / screenSize.y;
    final fovRad = fov * math.pi / 180.0;
    final tanHalfFov = math.tan(fovRad / 2);

    final projX = x / (z * tanHalfFov * aspectRatio);
    final projY = y / (z * tanHalfFov);

    // Outside view frustum
    if (projX.abs() > 1.0 || projY.abs() > 1.0) return null;

    // Convert to screen coordinates
    final screenX = (projX + 1.0) * 0.5 * screenSize.x;
    final screenY = (1.0 - projY) * 0.5 * screenSize.y;

    return Vector2(screenX, screenY);
  }

  /// Create a ray from screen position for raycasting
  Ray createRayFromScreen(Vector2 screenPos, Vector2 screenSize) {
    // Convert screen to NDC (-1 to 1)
    final ndcX = (screenPos.x / screenSize.x) * 2.0 - 1.0;
    final ndcY = 1.0 - (screenPos.y / screenSize.y) * 2.0;

    // Camera basis vectors
    final forward = (lookAt - position).normalized();
    final right = forward.cross(Vector3(0, 1, 0)).normalized();
    final up = right.cross(forward).normalized();

    // Calculate ray direction
    final aspectRatio = screenSize.x / screenSize.y;
    final fovRad = fov * math.pi / 180.0;
    final tanHalfFov = math.tan(fovRad / 2);

    final rayDir = (
      forward +
      (right * (ndcX * tanHalfFov * aspectRatio)) +
      (up * (ndcY * tanHalfFov))
    ).normalized();

    return Ray(position, rayDir);
  }

  /// Get distance from camera to point
  double distanceTo(Vector3 point) => position.distanceTo(point);
}
