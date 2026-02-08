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
  TextPainter? _namePainter;
  TextPainter? _distancePainter;
  String _distanceText = '';
  int _distanceValue = -1;
  final Path _hexPath = Path();

  Tower3D({
    required this.tower,
    required this.position3d,
    this.distanceToCamera = 0,
    this.isHovered = false,
    this.isSelected = false,
  });

  static final Paint _shadowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _bodyPaint = Paint();
  static final Paint _outlinePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _corePaint = Paint();
  static final Paint _highlightPaint = Paint();
  static final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _bracketPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static const TextStyle _nameTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(
        color: Color(0xCC000000),
        blurRadius: 4,
      ),
    ],
  );
  static const TextStyle _distanceTextStyle = TextStyle(
    color: Color(0xB3FFFFFF),
    fontSize: 10,
    shadows: [
      Shadow(
        color: Color(0xCC000000),
        blurRadius: 3,
      ),
    ],
  );

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
    _shadowPaint.color = Colors.black.withOpacity(0.3 * scale.clamp(0.0, 1.0));

    canvas.drawCircle(
      Offset(center.dx, center.dy + size * 0.3),
      size * 0.6,
      _shadowPaint,
    );

    // Tower body (hexagon)
    _hexPath.reset();
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 - math.pi / 2;
      final x = center.dx + math.cos(angle) * size * 0.5;
      final y = center.dy + math.sin(angle) * size * 0.5;
      if (i == 0) {
        _hexPath.moveTo(x, y);
      } else {
        _hexPath.lineTo(x, y);
      }
    }
    _hexPath.close();

    // Gradient for depth
    final gradient = RadialGradient(
      colors: [
        tower.color.withOpacity(0.8),
        tower.color.withOpacity(0.4),
        Colors.black.withOpacity(0.6),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    _bodyPaint.shader = gradient.createShader(
      Rect.fromCircle(center: center, radius: size * 0.5),
    );

    canvas.drawPath(_hexPath, _bodyPaint);

    // Outline
    _outlinePaint
      ..color = tower.color
      ..strokeWidth = 2 * scale.clamp(0.5, 1.0);

    canvas.drawPath(_hexPath, _outlinePaint);

    // Energy core
    _corePaint
      ..color = tower.color.withOpacity(0.9)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale);

    canvas.drawCircle(center, size * 0.2, _corePaint);

    // Core highlight
    _highlightPaint.color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(center, size * 0.1, _highlightPaint);
  }

  void _renderIndicator(Canvas canvas, Vector2 screenPos, double size) {
    final center = Offset(screenPos.x, screenPos.y);
    final color = isSelected ? Colors.red : Colors.yellow;

    // Pulsing ring
    _ringPaint.color = color.withOpacity(0.6);
    canvas.drawCircle(center, size * 0.8, _ringPaint);

    // Corner brackets
    final bracketSize = size * 0.3;
    _bracketPaint.color = color;

    // Top-left
    canvas.drawLine(
      Offset(center.dx - size, center.dy - size),
      Offset(center.dx - size + bracketSize, center.dy - size),
      _bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx - size, center.dy - size),
      Offset(center.dx - size, center.dy - size + bracketSize),
      _bracketPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(center.dx + size, center.dy - size),
      Offset(center.dx + size - bracketSize, center.dy - size),
      _bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx + size, center.dy - size),
      Offset(center.dx + size, center.dy - size + bracketSize),
      _bracketPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(center.dx - size, center.dy + size),
      Offset(center.dx - size + bracketSize, center.dy + size),
      _bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx - size, center.dy + size),
      Offset(center.dx - size, center.dy + size - bracketSize),
      _bracketPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(center.dx + size, center.dy + size),
      Offset(center.dx + size - bracketSize, center.dy + size),
      _bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx + size, center.dy + size),
      Offset(center.dx + size, center.dy + size - bracketSize),
      _bracketPaint,
    );
  }

  void _renderTowerInfo(Canvas canvas, Vector2 screenPos, double size) {
    if (!isHovered && !isSelected) return;

    _namePainter ??= (TextPainter(
      text: TextSpan(text: tower.type.name, style: _nameTextStyle),
      textDirection: TextDirection.ltr,
    )..layout());

    _namePainter!.paint(
      canvas,
      Offset(
        screenPos.x - _namePainter!.width / 2,
        screenPos.y - size - 20,
      ),
    );

    // Distance indicator
    final distValue = distanceToCamera.toInt();
    if (_distancePainter == null || _distanceValue != distValue) {
      _distanceValue = distValue;
      _distanceText = '${distValue}m';
      _distancePainter = TextPainter(
        text: TextSpan(text: _distanceText, style: _distanceTextStyle),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    _distancePainter!.paint(
      canvas,
      Offset(
        screenPos.x - _distancePainter!.width / 2,
        screenPos.y + size + 5,
      ),
    );
  }
}
