import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart' hide Vector3;
import 'package:flutter/material.dart';
import '../entities/tower.dart';
import 'fps_camera_3d.dart';

/// Represents a tower in 3D space for FPS view
class Tower3D {
  final Tower tower;
  Vector3 position3d;
  double distanceToCamera;
  bool isHovered;
  bool isSelected;

  Tower3D({
    required this.tower,
    required this.position3d,
    this.distanceToCamera = 0,
    this.isHovered = false,
    this.isSelected = false,
  });

  /// Get bounding box for raycasting
  /// Returns (min, max) corners of the box
  (Vector3, Vector3) getBoundingBox() {
    const size = 40.0; // Tower size in 3D space
    const height = 60.0;
    
    final min = Vector3(
      position3d.x - size / 2,
      position3d.y,
      position3d.z - size / 2,
    );
    
    final max = Vector3(
      position3d.x + size / 2,
      position3d.y + height,
      position3d.z + size / 2,
    );
    
    return (min, max);
  }

  /// Render tower in 3D with perspective
  void render(Canvas canvas, Camera3D camera, Vector2 screenSize) {
    // Project tower position to screen
    final screenPos = camera.project(position3d, screenSize);
    if (screenPos == null) return; // Behind camera or outside frustum

    // Calculate scale based on distance
    final scale = math.max(0.1, 1.0 / (distanceToCamera * 0.01));
    final renderSize = 40.0 * scale;

    // Draw tower as a simple 3D-looking shape
    _renderTowerShape(canvas, screenPos, renderSize, scale);

    // Draw hover/selection indicator
    if (isHovered || isSelected) {
      _renderIndicator(canvas, screenPos, renderSize);
    }

    // Draw tower info
    _renderTowerInfo(canvas, screenPos, renderSize);
  }

  void _renderTowerShape(Canvas canvas, Vector2 screenPos, double size, double scale) {
    final center = Offset(screenPos.x, screenPos.y);
    
    // Base shadow (for depth perception)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3 * scale.clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawCircle(
      Offset(center.dx, center.dy + size * 0.3),
      size * 0.6,
      shadowPaint,
    );

    // Tower body (hexagon)
    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 - math.pi / 2;
      final x = center.dx + math.cos(angle) * size * 0.5;
      final y = center.dy + math.sin(angle) * size * 0.5;
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();

    // Gradient for depth
    final gradient = RadialGradient(
      colors: [
        tower.color.withOpacity(0.8),
        tower.color.withOpacity(0.4),
        Colors.black.withOpacity(0.6),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final bodyPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: size * 0.5),
      );

    canvas.drawPath(hexPath, bodyPaint);

    // Outline
    final outlinePaint = Paint()
      ..color = tower.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale.clamp(0.5, 1.0);

    canvas.drawPath(hexPath, outlinePaint);

    // Energy core
    final corePaint = Paint()
      ..color = tower.color.withOpacity(0.9)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale);

    canvas.drawCircle(center, size * 0.2, corePaint);

    // Core highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.8);

    canvas.drawCircle(center, size * 0.1, highlightPaint);
  }

  void _renderIndicator(Canvas canvas, Vector2 screenPos, double size) {
    final center = Offset(screenPos.x, screenPos.y);
    final color = isSelected ? Colors.red : Colors.yellow;

    // Pulsing ring
    final ringPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, size * 0.8, ringPaint);

    // Corner brackets
    final bracketSize = size * 0.3;
    final bracketPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Top-left
    canvas.drawLine(
      Offset(center.dx - size, center.dy - size),
      Offset(center.dx - size + bracketSize, center.dy - size),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx - size, center.dy - size),
      Offset(center.dx - size, center.dy - size + bracketSize),
      bracketPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(center.dx + size, center.dy - size),
      Offset(center.dx + size - bracketSize, center.dy - size),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx + size, center.dy - size),
      Offset(center.dx + size, center.dy - size + bracketSize),
      bracketPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(center.dx - size, center.dy + size),
      Offset(center.dx - size + bracketSize, center.dy + size),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx - size, center.dy + size),
      Offset(center.dx - size, center.dy + size - bracketSize),
      bracketPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(center.dx + size, center.dy + size),
      Offset(center.dx + size - bracketSize, center.dy + size),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx + size, center.dy + size),
      Offset(center.dx + size, center.dy + size - bracketSize),
      bracketPaint,
    );
  }

  void _renderTowerInfo(Canvas canvas, Vector2 screenPos, double size) {
    if (!isHovered && !isSelected) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: tower.type.name,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        screenPos.x - textPainter.width / 2,
        screenPos.y - size - 20,
      ),
    );

    // Distance indicator
    final distText = '${distanceToCamera.toInt()}m';
    final distPainter = TextPainter(
      text: TextSpan(
        text: distText,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 10,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 3,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    distPainter.layout();
    distPainter.paint(
      canvas,
      Offset(
        screenPos.x - distPainter.width / 2,
        screenPos.y + size + 5,
      ),
    );
  }
}
