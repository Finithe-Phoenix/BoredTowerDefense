import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart' hide Vector3;
import 'package:flutter/material.dart';
import '../entities/enemy.dart';
import 'fps_camera_3d.dart';

class _FastRng {
  int _state;

  _FastRng([int? seed]) : _state = (seed ?? 0x6d2b79f5) & 0x7fffffff;

  int _next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  double nextDouble() => _next() / 0x7fffffff;

  int nextInt(int max) => max <= 0 ? 0 : _next() % max;

  bool nextBool() => (_next() & 1) == 0;
}

/// 3D shape types for enemies based on their characteristics
enum Enemy3DShape {
  sphere, // Basic runners
  cube, // Juggernauts/tanks
  pyramid, // Fast enemies
  ghost, // Phantom enemies
  crystal, // Crystal/shard enemies
  hexagon, // Tech/robot enemies
  spike, // Aggressive enemies
  worm, // Data worm type
  void_entity, // Void/dark enemies
  boss, // Boss enemies (larger, more complex)
}

/// Represents an enemy in 3D space for FPS view
class Enemy3D {
  final Enemy enemy;
  Vector3 position3d;
  double distanceToCamera;
  bool isTargeted;
  double animationPhase;
  final _FastRng _random;
  final Path _pathA = Path();
  final Path _pathB = Path();
  final Path _pathC = Path();
  final Path _hexPath = Path();

  Enemy3D({
    required this.enemy,
    required this.position3d,
    this.distanceToCamera = 0,
    this.isTargeted = false,
    this.animationPhase = 0,
  }) : _random = _FastRng(enemy.spawnIndex);

  static final MaskFilter _blur2 = MaskFilter.blur(BlurStyle.normal, 2);
  static final MaskFilter _blur3 = MaskFilter.blur(BlurStyle.normal, 3);
  static final MaskFilter _blur4 = MaskFilter.blur(BlurStyle.normal, 4);
  static final MaskFilter _blur6 = MaskFilter.blur(BlurStyle.normal, 6);
  static final MaskFilter _blur8 = MaskFilter.blur(BlurStyle.normal, 8);
  static final MaskFilter _blur12 = MaskFilter.blur(BlurStyle.normal, 12);
  static final MaskFilter _blur15 = MaskFilter.blur(BlurStyle.normal, 15);

  static final Paint _shadowPaint = Paint();
  static final Paint _glowPaint = Paint();
  static final Paint _gradientPaint = Paint();
  static final Paint _solidPaint = Paint();
  static final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _strokePaintThin = Paint()..style = PaintingStyle.stroke;
  static final Paint _particlePaint = Paint();
  static final Paint _healthBgPaint = Paint();
  static final Paint _healthFillPaint = Paint();
  static final Paint _targetPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _bracketPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _rimPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _sigilPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _damagePaint = Paint()..style = PaintingStyle.stroke;

  static MaskFilter _scaledBlur(double sigma) {
    if (sigma <= 2.5) return _blur2;
    if (sigma <= 3.5) return _blur3;
    if (sigma <= 5.0) return _blur4;
    if (sigma <= 7.0) return _blur6;
    if (sigma <= 10.0) return _blur8;
    if (sigma <= 13.5) return _blur12;
    return _blur15;
  }

  /// Get the 3D shape based on enemy type
  Enemy3DShape get shape {
    final type = enemy.type;
    if (enemy.isBoss ||
        enemy.threatTier >= 3 ||
        type == EnemyType.apocalypseHerald) {
      return Enemy3DShape.boss;
    }

    // Phantom enemies get ghost shape
    if (type.isPhantom) return Enemy3DShape.ghost;

    // Shape based on speed/health characteristics
    if (type.healthMult >= 2.5) return Enemy3DShape.cube; // Tanks
    if (type.speedMult >= 1.4) return Enemy3DShape.pyramid; // Fast
    if (type.healthMult >= 1.8) return Enemy3DShape.hexagon; // Medium tanks

    // World-specific shapes
    switch (type.world) {
      case 3:
        return Enemy3DShape.worm; // Signal Wastes - data enemies
      case 5:
        return Enemy3DShape.crystal; // Shard Vault - crystal enemies
      case 6:
        return Enemy3DShape.hexagon; // Arc Fortress - robotic
      case 9:
        return Enemy3DShape.void_entity; // Final Gate - void enemies
      case 10:
        return Enemy3DShape.spike; // Omega Nexus - aggressive
      default:
        return Enemy3DShape.sphere; // Default sphere
    }
  }

  /// Get bounding box for raycasting
  (Vector3, Vector3) getBoundingBox() {
    final size = 20.0 * enemy.type.sizeMult;
    final height = 30.0 * enemy.type.sizeMult;

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

  /// Update animation
  void update(double dt) {
    animationPhase += dt * 3.0;
  }

  /// Render enemy in 3D with perspective
  void render(Canvas canvas, Camera3D camera, Vector2 screenSize) {
    // Project enemy position to screen
    final screenPos = camera.project(position3d, screenSize);
    if (screenPos == null) return;
    if (!screenPos.x.isFinite || !screenPos.y.isFinite) return;

    // Calculate scale based on distance.
    // Fallback to camera distance if distanceToCamera was not precomputed.
    final distance =
        distanceToCamera > 0 ? distanceToCamera : camera.distanceTo(position3d);
    if (!distance.isFinite || distance <= 0) return;
    final perspectiveScale = 1.0 / (distance * 0.012);
    if (!perspectiveScale.isFinite || perspectiveScale <= 0) return;
    final scale = perspectiveScale.clamp(0.1, 6.0).toDouble();
    final baseSize = 25.0 * enemy.type.sizeMult;
    final renderSize = baseSize * scale;
    if (!renderSize.isFinite || renderSize <= 0) return;

    // Get enemy color with health-based modification
    final healthPercent = enemy.maxHealth > 0
        ? (enemy.health / enemy.maxHealth).clamp(0.0, 1.0)
        : 0.0;
    final baseColor = enemy.type.color;

    // Render based on shape type
    switch (shape) {
      case Enemy3DShape.sphere:
        _renderSphere(
            canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.cube:
        _renderCube(
            canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.pyramid:
        _renderPyramid(
            canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.ghost:
        _renderGhost(
            canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.crystal:
        _renderCrystal(
            canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.hexagon:
        _renderHexagon(
            canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.spike:
        _renderSpike(
            canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.worm:
        _renderWorm(
            canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.void_entity:
        _renderVoid(
            canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.boss:
        _renderBoss(
            canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
    }

    _renderUniversalDetails(
      canvas,
      screenPos,
      renderSize,
      scale,
      baseColor,
      healthPercent,
    );

    // Draw health bar
    _renderHealthBar(canvas, screenPos, renderSize, healthPercent, baseColor);

    // Draw target indicator if targeted
    if (isTargeted) {
      _renderTargetIndicator(canvas, screenPos, renderSize);
    }
  }

  void _renderSphere(Canvas canvas, Vector2 pos, double size, double scale,
      Color color, double health) {
    final center = Offset(pos.x, pos.y);

    // Shadow
    _shadowPaint
      ..color = Colors.black.withOpacity(0.4 * scale.clamp(0.0, 1.0))
      ..maskFilter = _blur6;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(center.dx, center.dy + size * 0.4),
          width: size * 0.8,
          height: size * 0.3),
      _shadowPaint,
    );

    // Outer glow
    _glowPaint
      ..color = color.withOpacity(0.3)
      ..maskFilter = _scaledBlur(8 * scale);
    canvas.drawCircle(center, size * 0.6, _glowPaint);

    // Main body with gradient
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        Color.lerp(color, Colors.white, 0.3)!,
        color,
        Color.lerp(color, Colors.black, 0.5)!,
      ],
      stops: const [0.0, 0.4, 1.0],
    );

    _gradientPaint.shader = gradient
        .createShader(Rect.fromCircle(center: center, radius: size * 0.5));
    canvas.drawCircle(center, size * 0.5, _gradientPaint);

    // Highlight
    _solidPaint.color = Colors.white.withOpacity(0.6);
    canvas.drawCircle(
      Offset(center.dx - size * 0.15, center.dy - size * 0.15),
      size * 0.12,
      _solidPaint,
    );

    // Pulsing core
    final pulseSize = 0.15 + math.sin(animationPhase) * 0.05;
    _glowPaint
      ..color = color.withOpacity(0.9)
      ..maskFilter = _blur3;
    canvas.drawCircle(center, size * pulseSize, _glowPaint);
  }

  void _renderCube(Canvas canvas, Vector2 pos, double size, double scale,
      Color color, double health) {
    final center = Offset(pos.x, pos.y);
    final halfSize = size * 0.45;

    // Shadow
    _shadowPaint
      ..color = Colors.black.withOpacity(0.4 * scale.clamp(0.0, 1.0))
      ..maskFilter = _blur8;
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(center.dx + 4, center.dy + size * 0.5),
          width: size * 0.9,
          height: size * 0.3),
      _shadowPaint,
    );

    // 3D cube effect - draw three visible faces
    final topOffset = size * 0.2;
    final sideOffset = size * 0.15;

    // Top face (lighter)
    final topPath = _pathA
      ..reset()
      ..moveTo(center.dx - halfSize, center.dy - halfSize + topOffset)
      ..lineTo(center.dx, center.dy - halfSize - topOffset)
      ..lineTo(center.dx + halfSize, center.dy - halfSize + topOffset)
      ..lineTo(center.dx, center.dy)
      ..close();

    _solidPaint.color = Color.lerp(color, Colors.white, 0.3)!;
    canvas.drawPath(topPath, _solidPaint);

    // Left face (medium)
    final leftPath = _pathB
      ..reset()
      ..moveTo(center.dx - halfSize, center.dy - halfSize + topOffset)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx, center.dy + halfSize)
      ..lineTo(center.dx - halfSize, center.dy + sideOffset)
      ..close();

    _solidPaint.color = color;
    canvas.drawPath(leftPath, _solidPaint);

    // Right face (darker)
    final rightPath = _pathC
      ..reset()
      ..moveTo(center.dx + halfSize, center.dy - halfSize + topOffset)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx, center.dy + halfSize)
      ..lineTo(center.dx + halfSize, center.dy + sideOffset)
      ..close();

    _solidPaint.color = Color.lerp(color, Colors.black, 0.3)!;
    canvas.drawPath(rightPath, _solidPaint);

    // Edges
    _strokePaint
      ..color = color
      ..strokeWidth = 2 * scale.clamp(0.5, 1.0);
    canvas.drawPath(topPath, _strokePaint);
    canvas.drawPath(leftPath, _strokePaint);
    canvas.drawPath(rightPath, _strokePaint);

    // Glow core
    _glowPaint
      ..color = color.withOpacity(0.8)
      ..maskFilter = _blur4;
    canvas.drawCircle(
        Offset(center.dx, center.dy - size * 0.1), size * 0.15, _glowPaint);
  }

  void _renderPyramid(Canvas canvas, Vector2 pos, double size, double scale,
      Color color, double health) {
    final center = Offset(pos.x, pos.y);
    final halfBase = size * 0.4;
    final height = size * 0.7;

    // Shadow
    _shadowPaint
      ..color = Colors.black.withOpacity(0.3 * scale.clamp(0.0, 1.0))
      ..maskFilter = _blur6;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(center.dx, center.dy + size * 0.35),
          width: size * 0.7,
          height: size * 0.25),
      _shadowPaint,
    );

    // Rotation animation
    final rotation = animationPhase * 0.5;

    // Front face
    final frontPath = _pathA
      ..reset()
      ..moveTo(center.dx, center.dy - height * 0.6)
      ..lineTo(
          center.dx - halfBase * math.cos(rotation), center.dy + height * 0.3)
      ..lineTo(center.dx + halfBase * math.cos(rotation + 0.5),
          center.dy + height * 0.3)
      ..close();

    _solidPaint.color = color;
    canvas.drawPath(frontPath, _solidPaint);

    // Side face (darker)
    final sidePath = _pathB
      ..reset()
      ..moveTo(center.dx, center.dy - height * 0.6)
      ..lineTo(center.dx + halfBase * math.cos(rotation + 0.5),
          center.dy + height * 0.3)
      ..lineTo(center.dx + halfBase * 0.3, center.dy + height * 0.2)
      ..close();

    _solidPaint.color = Color.lerp(color, Colors.black, 0.4)!;
    canvas.drawPath(sidePath, _solidPaint);

    // Edge glow
    _strokePaint
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.5 * scale.clamp(0.5, 1.0);
    canvas.drawPath(frontPath, _strokePaint);

    // Energy trail (speed indicator)
    _glowPaint
      ..color = color.withOpacity(0.4)
      ..maskFilter = _blur4;
    for (int i = 0; i < 3; i++) {
      final trailOffset = (i + 1) * 8.0;
      canvas.drawCircle(
        Offset(center.dx, center.dy + height * 0.3 + trailOffset),
        size * 0.1 * (1 - i * 0.25),
        _glowPaint,
      );
    }
  }

  void _renderGhost(Canvas canvas, Vector2 pos, double size, double scale,
      Color color, double health) {
    final center = Offset(pos.x, pos.y);

    // Ghostly wobble
    final wobble = math.sin(animationPhase * 2) * 3;
    final floatOffset = math.sin(animationPhase) * 5;

    // Outer ethereal glow
    _glowPaint
      ..color = color.withOpacity(0.2)
      ..maskFilter = _scaledBlur(15 * scale);
    canvas.drawCircle(
        Offset(center.dx, center.dy - floatOffset), size * 0.7, _glowPaint);

    // Ghost body path
    final ghostPath = _pathA
      ..reset()
      ..moveTo(center.dx, center.dy - size * 0.5 - floatOffset);

    // Top curve
    ghostPath.quadraticBezierTo(
      center.dx + size * 0.5,
      center.dy - size * 0.3 - floatOffset,
      center.dx + size * 0.4,
      center.dy + size * 0.2 - floatOffset,
    );

    // Wavy bottom
    for (int i = 0; i < 4; i++) {
      final waveX = center.dx + size * 0.4 - (i * size * 0.2);
      final waveY = center.dy +
          size * 0.3 -
          floatOffset +
          math.sin(animationPhase + i) * 5;
      final controlY = center.dy + size * 0.15 - floatOffset;
      ghostPath.quadraticBezierTo(
        waveX + size * 0.1,
        controlY,
        waveX - size * 0.1,
        waveY,
      );
    }

    // Left side back up
    ghostPath.quadraticBezierTo(
      center.dx - size * 0.5,
      center.dy - size * 0.3 - floatOffset,
      center.dx,
      center.dy - size * 0.5 - floatOffset,
    );

    // Semi-transparent body
    final bodyGradient = RadialGradient(
      colors: [
        color.withOpacity(0.6),
        color.withOpacity(0.3),
        color.withOpacity(0.1),
      ],
    );
    _gradientPaint.shader = bodyGradient.createShader(
      Rect.fromCircle(
          center: Offset(center.dx, center.dy - floatOffset),
          radius: size * 0.5),
    );
    canvas.drawPath(ghostPath, _gradientPaint);

    // Eyes
    _solidPaint.color = Colors.white.withOpacity(0.9);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - size * 0.12 + wobble * 0.3,
            center.dy - size * 0.15 - floatOffset),
        width: size * 0.15,
        height: size * 0.2,
      ),
      _solidPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + size * 0.12 + wobble * 0.3,
            center.dy - size * 0.15 - floatOffset),
        width: size * 0.15,
        height: size * 0.2,
      ),
      _solidPaint,
    );

    // Eye pupils
    _solidPaint.color = color;
    canvas.drawCircle(
      Offset(center.dx - size * 0.12 + wobble * 0.5,
          center.dy - size * 0.12 - floatOffset),
      size * 0.05,
      _solidPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + size * 0.12 + wobble * 0.5,
          center.dy - size * 0.12 - floatOffset),
      size * 0.05,
      _solidPaint,
    );
  }

  void _renderCrystal(Canvas canvas, Vector2 pos, double size, double scale,
      Color color, double health) {
    final center = Offset(pos.x, pos.y);
    final rotation = animationPhase * 0.3;

    // Shadow
    _shadowPaint
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = _blur6;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(center.dx, center.dy + size * 0.4),
          width: size * 0.6,
          height: size * 0.2),
      _shadowPaint,
    );

    // Crystal facets
    final facets = 6;
    for (int i = 0; i < facets; i++) {
      final angle = (i / facets) * math.pi * 2 + rotation;
      final nextAngle = ((i + 1) / facets) * math.pi * 2 + rotation;

      _pathA
        ..reset()
        ..moveTo(center.dx, center.dy - size * 0.6)
        ..lineTo(
          center.dx + math.cos(angle) * size * 0.3,
          center.dy + size * 0.1,
        )
        ..lineTo(
          center.dx + math.cos(nextAngle) * size * 0.3,
          center.dy + size * 0.1,
        )
        ..close();

      // Alternating colors for facets
      final facetColor =
          i.isEven ? color : Color.lerp(color, Colors.white, 0.3)!;

      _solidPaint.color = facetColor.withOpacity(0.8);
      canvas.drawPath(_pathA, _solidPaint);

      // Facet edge
      _strokePaintThin
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 1;
      canvas.drawPath(_pathA, _strokePaintThin);
    }

    // Bottom point
    for (int i = 0; i < facets; i++) {
      final angle = (i / facets) * math.pi * 2 + rotation;
      final nextAngle = ((i + 1) / facets) * math.pi * 2 + rotation;

      _pathB
        ..reset()
        ..moveTo(center.dx, center.dy + size * 0.4)
        ..lineTo(
          center.dx + math.cos(angle) * size * 0.3,
          center.dy + size * 0.1,
        )
        ..lineTo(
          center.dx + math.cos(nextAngle) * size * 0.3,
          center.dy + size * 0.1,
        )
        ..close();

      _solidPaint.color = Color.lerp(color, Colors.black, 0.4)!;
      canvas.drawPath(_pathB, _solidPaint);
    }

    // Inner glow
    _glowPaint
      ..color = color.withOpacity(0.5)
      ..maskFilter = _scaledBlur(6 * scale);
    canvas.drawCircle(
        Offset(center.dx, center.dy - size * 0.1), size * 0.2, _glowPaint);

    // Sparkle
    final sparklePhase = (animationPhase * 3) % (math.pi * 2);
    if (sparklePhase < math.pi * 0.5) {
      _solidPaint.color = Colors.white;
      canvas.drawCircle(
        Offset(center.dx + math.cos(rotation * 2) * size * 0.15,
            center.dy - size * 0.3),
        2,
        _solidPaint,
      );
    }
  }

  void _renderHexagon(Canvas canvas, Vector2 pos, double size, double scale,
      Color color, double health) {
    final center = Offset(pos.x, pos.y);
    final rotation = animationPhase * 0.2;

    // Shadow
    _shadowPaint
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = _blur6;
    canvas.drawCircle(
        Offset(center.dx, center.dy + size * 0.35), size * 0.35, _shadowPaint);

    // Outer hexagon
    final outerPath = _createHexPath(center, size * 0.5, rotation);
    final outerGradient = RadialGradient(
      colors: [
        Color.lerp(color, Colors.white, 0.2)!,
        color,
        Color.lerp(color, Colors.black, 0.3)!,
      ],
    );
    _gradientPaint.shader = outerGradient
        .createShader(Rect.fromCircle(center: center, radius: size * 0.5));
    canvas.drawPath(outerPath, _gradientPaint);

    // Hexagon outline
    _strokePaint
      ..color = color
      ..strokeWidth = 2 * scale.clamp(0.5, 1.0);
    canvas.drawPath(outerPath, _strokePaint);

    // Inner hexagon (rotating opposite)
    final innerPath = _createHexPath(center, size * 0.25, -rotation * 2);
    _solidPaint.color = Color.lerp(color, Colors.white, 0.5)!;
    canvas.drawPath(innerPath, _solidPaint);

    // Center core
    _glowPaint
      ..color = Colors.white.withOpacity(0.8)
      ..maskFilter = _blur3;
    canvas.drawCircle(center, size * 0.1, _glowPaint);

    // Circuit lines
    _strokePaintThin
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1;
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 + rotation;
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * size * 0.12,
            center.dy + math.sin(angle) * size * 0.12),
        Offset(center.dx + math.cos(angle) * size * 0.45,
            center.dy + math.sin(angle) * size * 0.45),
        _strokePaintThin,
      );
    }
  }

  Path _createHexPath(Offset center, double radius, double rotation) {
    final path = _hexPath..reset();
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 - math.pi / 2 + rotation;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _renderSpike(Canvas canvas, Vector2 pos, double size, double scale,
      Color color, double health) {
    final center = Offset(pos.x, pos.y);
    final pulseScale = 1.0 + math.sin(animationPhase * 4) * 0.1;

    // Shadow
    _shadowPaint
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = _blur6;
    canvas.drawCircle(
        Offset(center.dx, center.dy + size * 0.4), size * 0.3, _shadowPaint);

    // Core body
    _solidPaint.color = color;
    canvas.drawCircle(center, size * 0.25 * pulseScale, _solidPaint);

    // Spikes
    final spikeCount = 8;
    for (int i = 0; i < spikeCount; i++) {
      final angle = (i / spikeCount) * math.pi * 2 + animationPhase * 0.5;
      final spikeLength = size * (0.4 + math.sin(animationPhase + i) * 0.1);

      _pathA
        ..reset()
        ..moveTo(
          center.dx + math.cos(angle - 0.2) * size * 0.2,
          center.dy + math.sin(angle - 0.2) * size * 0.2,
        )
        ..lineTo(
          center.dx + math.cos(angle) * spikeLength,
          center.dy + math.sin(angle) * spikeLength,
        )
        ..lineTo(
          center.dx + math.cos(angle + 0.2) * size * 0.2,
          center.dy + math.sin(angle + 0.2) * size * 0.2,
        )
        ..close();

      _solidPaint.color =
          i.isEven ? color : Color.lerp(color, Colors.white, 0.3)!;
      canvas.drawPath(_pathA, _solidPaint);
    }

    // Angry eye
    _solidPaint.color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size * 0.2, height: size * 0.15),
      _solidPaint,
    );

    _solidPaint.color = Colors.black;
    canvas.drawCircle(center, size * 0.05, _solidPaint);

    // Energy aura
    _glowPaint
      ..color = color.withOpacity(0.3)
      ..maskFilter = _scaledBlur(8 * scale);
    canvas.drawCircle(center, size * 0.5 * pulseScale, _glowPaint);
  }

  void _renderWorm(Canvas canvas, Vector2 pos, double size, double scale,
      Color color, double health) {
    final center = Offset(pos.x, pos.y);

    // Worm segments
    final segmentCount = 5;
    final segmentSize = size * 0.2;

    for (int i = segmentCount - 1; i >= 0; i--) {
      final segmentPhase = animationPhase + i * 0.5;
      final xOffset = math.sin(segmentPhase) * size * 0.15;
      final yOffset = i * segmentSize * 0.6;

      final segmentCenter =
          Offset(center.dx + xOffset, center.dy + yOffset - size * 0.2);
      final currentSize = segmentSize * (1.0 - i * 0.12);

      // Segment shadow
      if (i == segmentCount - 1) {
        _shadowPaint
          ..color = Colors.black.withOpacity(0.3)
          ..maskFilter = _blur4;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(segmentCenter.dx, center.dy + size * 0.4),
            width: size * 0.5,
            height: size * 0.15,
          ),
          _shadowPaint,
        );
      }

      // Segment body
      final segmentGradient = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Color.lerp(color, Colors.white, 0.2)!,
          color,
          Color.lerp(color, Colors.black, 0.3)!,
        ],
      );
      _gradientPaint.shader = segmentGradient.createShader(
        Rect.fromCircle(center: segmentCenter, radius: currentSize),
      );
      canvas.drawCircle(segmentCenter, currentSize, _gradientPaint);

      // Segment ring
      _strokePaintThin
        ..color = Color.lerp(color, Colors.black, 0.2)!
        ..strokeWidth = 1;
      canvas.drawCircle(segmentCenter, currentSize * 0.8, _strokePaintThin);
    }

    // Head (first segment with eyes)
    final headCenter = Offset(
        center.dx + math.sin(animationPhase) * size * 0.15,
        center.dy - size * 0.2);

    // Eyes
    _solidPaint.color = Colors.white;
    canvas.drawCircle(
        Offset(headCenter.dx - size * 0.06, headCenter.dy - size * 0.02),
        size * 0.05,
        _solidPaint);
    canvas.drawCircle(
        Offset(headCenter.dx + size * 0.06, headCenter.dy - size * 0.02),
        size * 0.05,
        _solidPaint);

    _solidPaint.color = Colors.black;
    canvas.drawCircle(
        Offset(headCenter.dx - size * 0.06, headCenter.dy - size * 0.02),
        size * 0.025,
        _solidPaint);
    canvas.drawCircle(
        Offset(headCenter.dx + size * 0.06, headCenter.dy - size * 0.02),
        size * 0.025,
        _solidPaint);
  }

  void _renderVoid(Canvas canvas, Vector2 pos, double size, double scale,
      Color color, double health) {
    final center = Offset(pos.x, pos.y);

    // Void distortion effect
    final distortionPhase = animationPhase * 2;

    // Outer void aura (dark)
    _glowPaint
      ..color = Colors.black.withOpacity(0.6)
      ..maskFilter = _scaledBlur(12 * scale);
    canvas.drawCircle(center, size * 0.6, _glowPaint);

    // Swirling void particles
    _particlePaint.color = color.withOpacity(0.6);
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2 + distortionPhase;
      final distance = size * (0.3 + math.sin(distortionPhase + i) * 0.1);
      canvas.drawCircle(
        Offset(
          center.dx + math.cos(angle) * distance,
          center.dy + math.sin(angle) * distance,
        ),
        size * 0.05,
        _particlePaint,
      );
    }

    // Central void (black hole effect)
    final voidGradient = RadialGradient(
      colors: [
        Colors.black,
        color.withOpacity(0.8),
        color.withOpacity(0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.6, 1.0],
    );
    _gradientPaint.shader = voidGradient
        .createShader(Rect.fromCircle(center: center, radius: size * 0.5));
    canvas.drawCircle(center, size * 0.5, _gradientPaint);

    // Event horizon ring
    _strokePaint
      ..color = color
      ..strokeWidth = 2 * scale.clamp(0.5, 1.0);
    canvas.drawCircle(center, size * 0.35, _strokePaint);

    // Inner distortion
    for (int i = 0; i < 3; i++) {
      final ringRadius = size * (0.15 + i * 0.08);
      _strokePaintThin
        ..color = color.withOpacity(0.3 - i * 0.08)
        ..strokeWidth = 1;
      canvas.drawCircle(center, ringRadius, _strokePaintThin);
    }

    // Glowing eye in the void
    _glowPaint
      ..color = color
      ..maskFilter = _blur3;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size * 0.15, height: size * 0.08),
      _glowPaint,
    );
  }

  void _renderBoss(Canvas canvas, Vector2 pos, double size, double scale,
      Color color, double health) {
    // Boss is rendered larger with more detail
    final bossSize = size * 1.5;
    _renderSpike(canvas, pos, bossSize, scale, color, health);

    // Additional boss crown/horns
    final center = Offset(pos.x, pos.y);
    _solidPaint.color = Colors.amber;

    // Crown points
    for (int i = 0; i < 3; i++) {
      final angle = -math.pi / 2 + (i - 1) * 0.4;
      _pathA
        ..reset()
        ..moveTo(center.dx + math.cos(angle) * bossSize * 0.2,
            center.dy - bossSize * 0.3)
        ..lineTo(center.dx + math.cos(angle) * bossSize * 0.1,
            center.dy - bossSize * 0.5)
        ..lineTo(center.dx + math.cos(angle + 0.15) * bossSize * 0.2,
            center.dy - bossSize * 0.3)
        ..close();
      canvas.drawPath(_pathA, _solidPaint);
    }

    _renderBossAddons(canvas, center, bossSize, scale, color);
  }

  void _renderBossAddons(
    Canvas canvas,
    Offset center,
    double size,
    double scale,
    Color color,
  ) {
    final accent = _accentColor(color);
    final ringRadius = size * 0.72;
    final ringRect = Rect.fromCircle(center: center, radius: ringRadius);
    final segments = 10;
    final step = (math.pi * 2) / segments;
    final sweep = step * 0.6;

    _strokePaint
      ..color = accent.withOpacity(0.55)
      ..strokeWidth = (2.0 * scale).clamp(1.2, 2.8).toDouble()
      ..maskFilter = _scaledBlur(4 * scale);

    for (int i = 0; i < segments; i++) {
      final start = animationPhase * 0.35 + i * step;
      canvas.drawArc(ringRect, start, sweep, false, _strokePaint);
    }
    _strokePaint.maskFilter = null;

    final baseY = -size * 0.35;
    final hornLen = size * 0.55;
    final hornWidth = size * 0.18;
    _solidPaint.color = Color.lerp(accent, Colors.white, 0.35)!;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (final sign in [-1, 1]) {
      canvas.save();
      canvas
          .rotate(-math.pi / 2 + sign * 0.35 + math.sin(animationPhase) * 0.08);
      _pathB
        ..reset()
        ..moveTo(-hornWidth, baseY)
        ..lineTo(0, baseY - hornLen)
        ..lineTo(hornWidth, baseY)
        ..close();
      canvas.drawPath(_pathB, _solidPaint);
      canvas.restore();
    }
    canvas.restore();
  }

  Color _accentColor(Color color) {
    return Color.lerp(color, enemy.worldAccentColor, 0.65)!;
  }

  void _renderUniversalDetails(
    Canvas canvas,
    Vector2 pos,
    double size,
    double scale,
    Color color,
    double health,
  ) {
    final center = Offset(pos.x, pos.y);
    final accent = _accentColor(color);
    final pulse =
        0.5 + 0.5 * math.sin(animationPhase * 2.4 + enemy.type.world * 0.2);
    final healthWeight = 0.65 + health * 0.35;

    _rimPaint
      ..color = Color.lerp(Colors.white, accent, 0.45)!
          .withOpacity((0.14 + pulse * 0.16) * healthWeight)
      ..strokeWidth = (1.2 * scale).clamp(0.8, 2.2).toDouble()
      ..maskFilter = _scaledBlur(2.5 * scale);
    canvas.drawCircle(center, size * 0.54, _rimPaint);
    _rimPaint.maskFilter = null;

    _sigilPaint
      ..color = accent.withOpacity(0.25 + 0.25 * pulse)
      ..strokeWidth = (1.0 * scale).clamp(0.8, 1.9).toDouble()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = null;
    _renderWorldSigil(canvas, center, size * 0.32, enemy.type.world);

    _renderThreatRing(canvas, center, size, scale, accent, pulse);
    _renderDamageScars(canvas, center, size, scale, health, accent);

    if (enemy.type.isPhantom) {
      _glowPaint
        ..color = accent.withOpacity(0.18 + pulse * 0.1)
        ..maskFilter = _scaledBlur(6 * scale);
      canvas.drawCircle(center, size * 0.68, _glowPaint);
    }
  }

  void _renderDamageScars(
    Canvas canvas,
    Offset center,
    double size,
    double scale,
    double health,
    Color accent,
  ) {
    if (health >= 0.72) return;

    final severity = ((0.72 - health) / 0.72).clamp(0.0, 1.0);
    _damagePaint
      ..color = Color.lerp(accent, Colors.redAccent, 0.55)!
          .withOpacity(0.25 + severity * 0.65)
      ..strokeWidth = (1.0 * scale).clamp(0.7, 1.9).toDouble()
      ..strokeCap = StrokeCap.round
      ..maskFilter = null;

    final jitter = math.sin(animationPhase * 6.0) * size * 0.025;
    canvas.drawLine(
      Offset(center.dx - size * 0.2 + jitter, center.dy - size * 0.08),
      Offset(center.dx + size * 0.1, center.dy + size * 0.14),
      _damagePaint,
    );

    if (severity > 0.35) {
      canvas.drawLine(
        Offset(center.dx - size * 0.1 - jitter * 0.6, center.dy - size * 0.22),
        Offset(center.dx + size * 0.18, center.dy - size * 0.02),
        _damagePaint,
      );
    }

    if (severity > 0.7) {
      canvas.drawLine(
        Offset(center.dx - size * 0.22, center.dy + size * 0.08),
        Offset(center.dx + size * 0.2 + jitter * 0.4, center.dy + size * 0.24),
        _damagePaint,
      );
    }
  }

  void _renderThreatRing(
    Canvas canvas,
    Offset center,
    double size,
    double scale,
    Color accent,
    double pulse,
  ) {
    final tier = enemy.threatTier;
    if (tier < 2 && !enemy.isBoss) return;

    final tierBoost = tier.clamp(0, 4);
    final segments = 6 + tierBoost * 2 + (enemy.isBoss ? 2 : 0);
    final ringRadius = size * (0.62 + tierBoost * 0.03);
    final ringRect = Rect.fromCircle(center: center, radius: ringRadius);
    final step = (math.pi * 2) / segments;
    final sweep = step * 0.55;

    _sigilPaint
      ..color = accent.withOpacity(0.35 + 0.3 * pulse)
      ..strokeWidth = (1.1 * scale).clamp(0.8, 2.0).toDouble()
      ..strokeCap = StrokeCap.round
      ..maskFilter = null;

    for (int i = 0; i < segments; i++) {
      final start = animationPhase * 0.35 + i * step;
      canvas.drawArc(ringRect, start, sweep, false, _sigilPaint);
    }

    if (tier >= 3 || enemy.isBoss) {
      _rimPaint
        ..color = accent.withOpacity(0.2 + 0.2 * pulse)
        ..strokeWidth = (1.6 * scale).clamp(1.0, 2.6).toDouble()
        ..maskFilter = _scaledBlur(4 * scale);
      canvas.drawCircle(center, ringRadius * 1.08, _rimPaint);
      _rimPaint.maskFilter = null;
    }
  }

  void _renderWorldSigil(
      Canvas canvas, Offset center, double radius, int world) {
    switch (world) {
      case 1:
        final y = center.dy + radius * 0.18;
        canvas.drawLine(
          Offset(center.dx - radius * 0.8, y - radius * 0.3),
          Offset(center.dx, y + radius * 0.28),
          _sigilPaint,
        );
        canvas.drawLine(
          Offset(center.dx, y + radius * 0.28),
          Offset(center.dx + radius * 0.8, y - radius * 0.3),
          _sigilPaint,
        );
        break;
      case 2:
        final ring = Rect.fromCircle(center: center, radius: radius * 0.9);
        for (int i = 0; i < 3; i++) {
          canvas.drawArc(
            ring,
            animationPhase * 0.45 + i * 2.1,
            math.pi / 2.9,
            false,
            _sigilPaint,
          );
        }
        break;
      case 3:
        for (int i = -1; i <= 1; i++) {
          final y = center.dy + i * radius * 0.34;
          canvas.drawLine(
            Offset(center.dx - radius * 0.85, y),
            Offset(center.dx + radius * 0.85, y),
            _sigilPaint,
          );
        }
        break;
      case 4:
        _pathC
          ..reset()
          ..moveTo(center.dx - radius * 0.15, center.dy - radius * 0.85)
          ..lineTo(center.dx + radius * 0.12, center.dy - radius * 0.2)
          ..lineTo(center.dx - radius * 0.03, center.dy - radius * 0.2)
          ..lineTo(center.dx + radius * 0.18, center.dy + radius * 0.85);
        canvas.drawPath(_pathC, _sigilPaint);
        break;
      case 5:
        _pathC
          ..reset()
          ..moveTo(center.dx, center.dy - radius * 0.9)
          ..lineTo(center.dx + radius * 0.65, center.dy)
          ..lineTo(center.dx, center.dy + radius * 0.9)
          ..lineTo(center.dx - radius * 0.65, center.dy)
          ..close();
        canvas.drawPath(_pathC, _sigilPaint);
        canvas.drawLine(
          Offset(center.dx, center.dy - radius * 0.9),
          Offset(center.dx, center.dy + radius * 0.9),
          _sigilPaint,
        );
        break;
      case 6:
        final r = radius * 0.85;
        final c = radius * 0.36;
        canvas.drawLine(
          Offset(center.dx - r, center.dy - r),
          Offset(center.dx - c, center.dy - r),
          _sigilPaint,
        );
        canvas.drawLine(
          Offset(center.dx - r, center.dy - r),
          Offset(center.dx - r, center.dy - c),
          _sigilPaint,
        );
        canvas.drawLine(
          Offset(center.dx + r, center.dy - r),
          Offset(center.dx + c, center.dy - r),
          _sigilPaint,
        );
        canvas.drawLine(
          Offset(center.dx + r, center.dy - r),
          Offset(center.dx + r, center.dy - c),
          _sigilPaint,
        );
        canvas.drawLine(
          Offset(center.dx - r, center.dy + r),
          Offset(center.dx - c, center.dy + r),
          _sigilPaint,
        );
        canvas.drawLine(
          Offset(center.dx - r, center.dy + r),
          Offset(center.dx - r, center.dy + c),
          _sigilPaint,
        );
        canvas.drawLine(
          Offset(center.dx + r, center.dy + r),
          Offset(center.dx + c, center.dy + r),
          _sigilPaint,
        );
        canvas.drawLine(
          Offset(center.dx + r, center.dy + r),
          Offset(center.dx + r, center.dy + c),
          _sigilPaint,
        );
        break;
      case 7:
        canvas.drawLine(
          Offset(center.dx - radius * 0.85, center.dy),
          Offset(center.dx + radius * 0.85, center.dy),
          _sigilPaint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - radius * 0.85),
          Offset(center.dx, center.dy + radius * 0.85),
          _sigilPaint,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: center,
            width: radius * 0.95,
            height: radius * 0.95,
          ),
          _sigilPaint,
        );
        break;
      case 8:
        final arcRect = Rect.fromCircle(center: center, radius: radius * 0.88);
        final angle = animationPhase * 0.55;
        canvas.drawArc(arcRect, angle, math.pi * 0.95, false, _sigilPaint);
        canvas.drawArc(
            arcRect, angle + math.pi, math.pi * 0.55, false, _sigilPaint);
        break;
      case 9:
        canvas.drawCircle(center, radius * 0.76, _sigilPaint);
        _solidPaint.color = Colors.black.withOpacity(0.6);
        canvas.drawCircle(
          Offset(center.dx + radius * 0.28, center.dy - radius * 0.03),
          radius * 0.5,
          _solidPaint,
        );
        break;
      case 10:
        final spin = animationPhase * 0.25;
        for (int i = 0; i < 3; i++) {
          final angle = spin + (i / 3) * math.pi * 2;
          final tip = Offset(
            center.dx + math.cos(angle) * radius * 0.92,
            center.dy + math.sin(angle) * radius * 0.92,
          );
          final left = Offset(
            center.dx + math.cos(angle + 0.55) * radius * 0.35,
            center.dy + math.sin(angle + 0.55) * radius * 0.35,
          );
          final right = Offset(
            center.dx + math.cos(angle - 0.55) * radius * 0.35,
            center.dy + math.sin(angle - 0.55) * radius * 0.35,
          );
          _pathC
            ..reset()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(left.dx, left.dy)
            ..lineTo(right.dx, right.dy)
            ..close();
          canvas.drawPath(_pathC, _sigilPaint);
        }
        break;
      default:
        canvas.drawCircle(center, radius * 0.65, _sigilPaint);
        break;
    }
  }

  void _renderHealthBar(Canvas canvas, Vector2 pos, double size,
      double healthPercent, Color color) {
    if (healthPercent >= 1.0) return; // Don't show full health

    final barWidth = size * 1.2;
    final barHeight = 4.0;
    final barY = pos.y - size * 0.7;

    // Background
    _healthBgPaint.color = Colors.black.withOpacity(0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(pos.x, barY), width: barWidth, height: barHeight),
        const Radius.circular(2),
      ),
      _healthBgPaint,
    );

    // Health fill
    final healthColor = healthPercent > 0.5
        ? color
        : healthPercent > 0.25
            ? Colors.orange
            : Colors.red;
    _healthFillPaint.color = healthColor;
    final healthWidth = barWidth * healthPercent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            pos.x - barWidth / 2, barY - barHeight / 2, healthWidth, barHeight),
        const Radius.circular(2),
      ),
      _healthFillPaint,
    );
  }

  void _renderTargetIndicator(Canvas canvas, Vector2 pos, double size) {
    final center = Offset(pos.x, pos.y);

    // Pulsing target circle
    final pulseScale = 1.0 + math.sin(animationPhase * 5) * 0.1;
    _targetPaint
      ..color = Colors.red.withOpacity(0.8)
      ..strokeWidth = 2;

    canvas.drawCircle(center, size * 0.8 * pulseScale, _targetPaint);

    // Crosshair
    final crossSize = size * 0.6;
    canvas.drawLine(
      Offset(center.dx - crossSize, center.dy),
      Offset(center.dx - crossSize * 0.4, center.dy),
      _targetPaint,
    );
    canvas.drawLine(
      Offset(center.dx + crossSize * 0.4, center.dy),
      Offset(center.dx + crossSize, center.dy),
      _targetPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - crossSize),
      Offset(center.dx, center.dy - crossSize * 0.4),
      _targetPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + crossSize * 0.4),
      Offset(center.dx, center.dy + crossSize),
      _targetPaint,
    );

    // Corner brackets
    _bracketPaint
      ..color = Colors.red
      ..strokeWidth = 2;

    final bracketSize = size * 0.2;
    final bracketOffset = size * 0.7;

    // Top-left
    canvas.drawLine(
      Offset(center.dx - bracketOffset, center.dy - bracketOffset),
      Offset(
          center.dx - bracketOffset + bracketSize, center.dy - bracketOffset),
      _bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx - bracketOffset, center.dy - bracketOffset),
      Offset(
          center.dx - bracketOffset, center.dy - bracketOffset + bracketSize),
      _bracketPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(center.dx + bracketOffset, center.dy - bracketOffset),
      Offset(
          center.dx + bracketOffset - bracketSize, center.dy - bracketOffset),
      _bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx + bracketOffset, center.dy - bracketOffset),
      Offset(
          center.dx + bracketOffset, center.dy - bracketOffset + bracketSize),
      _bracketPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(center.dx - bracketOffset, center.dy + bracketOffset),
      Offset(
          center.dx - bracketOffset + bracketSize, center.dy + bracketOffset),
      _bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx - bracketOffset, center.dy + bracketOffset),
      Offset(
          center.dx - bracketOffset, center.dy + bracketOffset - bracketSize),
      _bracketPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(center.dx + bracketOffset, center.dy + bracketOffset),
      Offset(
          center.dx + bracketOffset - bracketSize, center.dy + bracketOffset),
      _bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx + bracketOffset, center.dy + bracketOffset),
      Offset(
          center.dx + bracketOffset, center.dy + bracketOffset - bracketSize),
      _bracketPaint,
    );
  }
}
