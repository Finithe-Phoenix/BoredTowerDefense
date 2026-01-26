import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart' hide Vector3;
import 'package:flutter/material.dart';
import '../entities/enemy.dart';
import 'fps_camera_3d.dart';

/// 3D shape types for enemies based on their characteristics
enum Enemy3DShape {
  sphere,      // Basic runners
  cube,        // Juggernauts/tanks
  pyramid,     // Fast enemies
  ghost,       // Phantom enemies
  crystal,     // Crystal/shard enemies
  hexagon,     // Tech/robot enemies
  spike,       // Aggressive enemies
  worm,        // Data worm type
  void_entity, // Void/dark enemies
  boss,        // Boss enemies (larger, more complex)
}

/// Represents an enemy in 3D space for FPS view
class Enemy3D {
  final Enemy enemy;
  Vector3 position3d;
  double distanceToCamera;
  bool isTargeted;
  double animationPhase;
  final math.Random _random;

  Enemy3D({
    required this.enemy,
    required this.position3d,
    this.distanceToCamera = 0,
    this.isTargeted = false,
    this.animationPhase = 0,
  }) : _random = math.Random(enemy.spawnIndex);

  /// Get the 3D shape based on enemy type
  Enemy3DShape get shape {
    final type = enemy.type;

    // Phantom enemies get ghost shape
    if (type.isPhantom) return Enemy3DShape.ghost;

    // Shape based on speed/health characteristics
    if (type.healthMult >= 2.5) return Enemy3DShape.cube;      // Tanks
    if (type.speedMult >= 1.4) return Enemy3DShape.pyramid;    // Fast
    if (type.healthMult >= 1.8) return Enemy3DShape.hexagon;   // Medium tanks

    // World-specific shapes
    switch (type.world) {
      case 3: return Enemy3DShape.worm;        // Signal Wastes - data enemies
      case 5: return Enemy3DShape.crystal;     // Shard Vault - crystal enemies
      case 6: return Enemy3DShape.hexagon;     // Arc Fortress - robotic
      case 9: return Enemy3DShape.void_entity; // Final Gate - void enemies
      case 10: return Enemy3DShape.spike;      // Omega Nexus - aggressive
      default: return Enemy3DShape.sphere;     // Default sphere
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

    // Calculate scale based on distance
    final scale = math.max(0.1, 1.0 / (distanceToCamera * 0.012));
    final baseSize = 25.0 * enemy.type.sizeMult;
    final renderSize = baseSize * scale;

    // Get enemy color with health-based modification
    final healthPercent = enemy.health / enemy.maxHealth;
    final baseColor = enemy.type.color;

    // Render based on shape type
    switch (shape) {
      case Enemy3DShape.sphere:
        _renderSphere(canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.cube:
        _renderCube(canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.pyramid:
        _renderPyramid(canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.ghost:
        _renderGhost(canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.crystal:
        _renderCrystal(canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.hexagon:
        _renderHexagon(canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.spike:
        _renderSpike(canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.worm:
        _renderWorm(canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.void_entity:
        _renderVoid(canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
      case Enemy3DShape.boss:
        _renderBoss(canvas, screenPos, renderSize, scale, baseColor, healthPercent);
        break;
    }

    // Draw health bar
    _renderHealthBar(canvas, screenPos, renderSize, healthPercent, baseColor);

    // Draw target indicator if targeted
    if (isTargeted) {
      _renderTargetIndicator(canvas, screenPos, renderSize);
    }
  }

  void _renderSphere(Canvas canvas, Vector2 pos, double size, double scale, Color color, double health) {
    final center = Offset(pos.x, pos.y);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4 * scale.clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + size * 0.4), width: size * 0.8, height: size * 0.3),
      shadowPaint,
    );

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scale);
    canvas.drawCircle(center, size * 0.6, glowPaint);

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

    final bodyPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: size * 0.5));
    canvas.drawCircle(center, size * 0.5, bodyPaint);

    // Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6);
    canvas.drawCircle(
      Offset(center.dx - size * 0.15, center.dy - size * 0.15),
      size * 0.12,
      highlightPaint,
    );

    // Pulsing core
    final pulseSize = 0.15 + math.sin(animationPhase) * 0.05;
    final corePaint = Paint()
      ..color = color.withOpacity(0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, size * pulseSize, corePaint);
  }

  void _renderCube(Canvas canvas, Vector2 pos, double size, double scale, Color color, double health) {
    final center = Offset(pos.x, pos.y);
    final halfSize = size * 0.45;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4 * scale.clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx + 4, center.dy + size * 0.5), width: size * 0.9, height: size * 0.3),
      shadowPaint,
    );

    // 3D cube effect - draw three visible faces
    final topOffset = size * 0.2;
    final sideOffset = size * 0.15;

    // Top face (lighter)
    final topPath = Path()
      ..moveTo(center.dx - halfSize, center.dy - halfSize + topOffset)
      ..lineTo(center.dx, center.dy - halfSize - topOffset)
      ..lineTo(center.dx + halfSize, center.dy - halfSize + topOffset)
      ..lineTo(center.dx, center.dy)
      ..close();

    final topPaint = Paint()..color = Color.lerp(color, Colors.white, 0.3)!;
    canvas.drawPath(topPath, topPaint);

    // Left face (medium)
    final leftPath = Path()
      ..moveTo(center.dx - halfSize, center.dy - halfSize + topOffset)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx, center.dy + halfSize)
      ..lineTo(center.dx - halfSize, center.dy + sideOffset)
      ..close();

    final leftPaint = Paint()..color = color;
    canvas.drawPath(leftPath, leftPaint);

    // Right face (darker)
    final rightPath = Path()
      ..moveTo(center.dx + halfSize, center.dy - halfSize + topOffset)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx, center.dy + halfSize)
      ..lineTo(center.dx + halfSize, center.dy + sideOffset)
      ..close();

    final rightPaint = Paint()..color = Color.lerp(color, Colors.black, 0.3)!;
    canvas.drawPath(rightPath, rightPaint);

    // Edges
    final edgePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale.clamp(0.5, 1.0);
    canvas.drawPath(topPath, edgePaint);
    canvas.drawPath(leftPath, edgePaint);
    canvas.drawPath(rightPath, edgePaint);

    // Glow core
    final corePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(center.dx, center.dy - size * 0.1), size * 0.15, corePaint);
  }

  void _renderPyramid(Canvas canvas, Vector2 pos, double size, double scale, Color color, double health) {
    final center = Offset(pos.x, pos.y);
    final halfBase = size * 0.4;
    final height = size * 0.7;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3 * scale.clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + size * 0.35), width: size * 0.7, height: size * 0.25),
      shadowPaint,
    );

    // Rotation animation
    final rotation = animationPhase * 0.5;

    // Front face
    final frontPath = Path()
      ..moveTo(center.dx, center.dy - height * 0.6)
      ..lineTo(center.dx - halfBase * math.cos(rotation), center.dy + height * 0.3)
      ..lineTo(center.dx + halfBase * math.cos(rotation + 0.5), center.dy + height * 0.3)
      ..close();

    final frontPaint = Paint()..color = color;
    canvas.drawPath(frontPath, frontPaint);

    // Side face (darker)
    final sidePath = Path()
      ..moveTo(center.dx, center.dy - height * 0.6)
      ..lineTo(center.dx + halfBase * math.cos(rotation + 0.5), center.dy + height * 0.3)
      ..lineTo(center.dx + halfBase * 0.3, center.dy + height * 0.2)
      ..close();

    final sidePaint = Paint()..color = Color.lerp(color, Colors.black, 0.4)!;
    canvas.drawPath(sidePath, sidePaint);

    // Edge glow
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale.clamp(0.5, 1.0);
    canvas.drawPath(frontPath, edgePaint);

    // Energy trail (speed indicator)
    final trailPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (int i = 0; i < 3; i++) {
      final trailOffset = (i + 1) * 8.0;
      canvas.drawCircle(
        Offset(center.dx, center.dy + height * 0.3 + trailOffset),
        size * 0.1 * (1 - i * 0.25),
        trailPaint,
      );
    }
  }

  void _renderGhost(Canvas canvas, Vector2 pos, double size, double scale, Color color, double health) {
    final center = Offset(pos.x, pos.y);

    // Ghostly wobble
    final wobble = math.sin(animationPhase * 2) * 3;
    final floatOffset = math.sin(animationPhase) * 5;

    // Outer ethereal glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * scale);
    canvas.drawCircle(Offset(center.dx, center.dy - floatOffset), size * 0.7, glowPaint);

    // Ghost body path
    final ghostPath = Path();
    ghostPath.moveTo(center.dx, center.dy - size * 0.5 - floatOffset);

    // Top curve
    ghostPath.quadraticBezierTo(
      center.dx + size * 0.5, center.dy - size * 0.3 - floatOffset,
      center.dx + size * 0.4, center.dy + size * 0.2 - floatOffset,
    );

    // Wavy bottom
    for (int i = 0; i < 4; i++) {
      final waveX = center.dx + size * 0.4 - (i * size * 0.2);
      final waveY = center.dy + size * 0.3 - floatOffset + math.sin(animationPhase + i) * 5;
      final controlY = center.dy + size * 0.15 - floatOffset;
      ghostPath.quadraticBezierTo(
        waveX + size * 0.1, controlY,
        waveX - size * 0.1, waveY,
      );
    }

    // Left side back up
    ghostPath.quadraticBezierTo(
      center.dx - size * 0.5, center.dy - size * 0.3 - floatOffset,
      center.dx, center.dy - size * 0.5 - floatOffset,
    );

    // Semi-transparent body
    final bodyGradient = RadialGradient(
      colors: [
        color.withOpacity(0.6),
        color.withOpacity(0.3),
        color.withOpacity(0.1),
      ],
    );
    final bodyPaint = Paint()
      ..shader = bodyGradient.createShader(
        Rect.fromCircle(center: Offset(center.dx, center.dy - floatOffset), radius: size * 0.5),
      );
    canvas.drawPath(ghostPath, bodyPaint);

    // Eyes
    final eyeColor = Colors.white.withOpacity(0.9);
    final eyePaint = Paint()..color = eyeColor;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - size * 0.12 + wobble * 0.3, center.dy - size * 0.15 - floatOffset),
        width: size * 0.15,
        height: size * 0.2,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + size * 0.12 + wobble * 0.3, center.dy - size * 0.15 - floatOffset),
        width: size * 0.15,
        height: size * 0.2,
      ),
      eyePaint,
    );

    // Eye pupils
    final pupilPaint = Paint()..color = color;
    canvas.drawCircle(
      Offset(center.dx - size * 0.12 + wobble * 0.5, center.dy - size * 0.12 - floatOffset),
      size * 0.05,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + size * 0.12 + wobble * 0.5, center.dy - size * 0.12 - floatOffset),
      size * 0.05,
      pupilPaint,
    );
  }

  void _renderCrystal(Canvas canvas, Vector2 pos, double size, double scale, Color color, double health) {
    final center = Offset(pos.x, pos.y);
    final rotation = animationPhase * 0.3;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + size * 0.4), width: size * 0.6, height: size * 0.2),
      shadowPaint,
    );

    // Crystal facets
    final facets = 6;
    for (int i = 0; i < facets; i++) {
      final angle = (i / facets) * math.pi * 2 + rotation;
      final nextAngle = ((i + 1) / facets) * math.pi * 2 + rotation;

      final facetPath = Path()
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
      final facetColor = i.isEven
          ? color
          : Color.lerp(color, Colors.white, 0.3)!;

      final facetPaint = Paint()..color = facetColor.withOpacity(0.8);
      canvas.drawPath(facetPath, facetPaint);

      // Facet edge
      final edgePaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPath(facetPath, edgePaint);
    }

    // Bottom point
    for (int i = 0; i < facets; i++) {
      final angle = (i / facets) * math.pi * 2 + rotation;
      final nextAngle = ((i + 1) / facets) * math.pi * 2 + rotation;

      final bottomPath = Path()
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

      final bottomPaint = Paint()..color = Color.lerp(color, Colors.black, 0.4)!;
      canvas.drawPath(bottomPath, bottomPaint);
    }

    // Inner glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * scale);
    canvas.drawCircle(Offset(center.dx, center.dy - size * 0.1), size * 0.2, glowPaint);

    // Sparkle
    final sparklePhase = (animationPhase * 3) % (math.pi * 2);
    if (sparklePhase < math.pi * 0.5) {
      final sparklePaint = Paint()..color = Colors.white;
      canvas.drawCircle(
        Offset(center.dx + math.cos(rotation * 2) * size * 0.15, center.dy - size * 0.3),
        2,
        sparklePaint,
      );
    }
  }

  void _renderHexagon(Canvas canvas, Vector2 pos, double size, double scale, Color color, double health) {
    final center = Offset(pos.x, pos.y);
    final rotation = animationPhase * 0.2;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(center.dx, center.dy + size * 0.35), size * 0.35, shadowPaint);

    // Outer hexagon
    final outerPath = _createHexPath(center, size * 0.5, rotation);
    final outerGradient = RadialGradient(
      colors: [
        Color.lerp(color, Colors.white, 0.2)!,
        color,
        Color.lerp(color, Colors.black, 0.3)!,
      ],
    );
    final outerPaint = Paint()
      ..shader = outerGradient.createShader(Rect.fromCircle(center: center, radius: size * 0.5));
    canvas.drawPath(outerPath, outerPaint);

    // Hexagon outline
    final outlinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale.clamp(0.5, 1.0);
    canvas.drawPath(outerPath, outlinePaint);

    // Inner hexagon (rotating opposite)
    final innerPath = _createHexPath(center, size * 0.25, -rotation * 2);
    final innerPaint = Paint()..color = Color.lerp(color, Colors.white, 0.5)!;
    canvas.drawPath(innerPath, innerPaint);

    // Center core
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, size * 0.1, corePaint);

    // Circuit lines
    final circuitPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 + rotation;
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * size * 0.12, center.dy + math.sin(angle) * size * 0.12),
        Offset(center.dx + math.cos(angle) * size * 0.45, center.dy + math.sin(angle) * size * 0.45),
        circuitPaint,
      );
    }
  }

  Path _createHexPath(Offset center, double radius, double rotation) {
    final path = Path();
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

  void _renderSpike(Canvas canvas, Vector2 pos, double size, double scale, Color color, double health) {
    final center = Offset(pos.x, pos.y);
    final pulseScale = 1.0 + math.sin(animationPhase * 4) * 0.1;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(center.dx, center.dy + size * 0.4), size * 0.3, shadowPaint);

    // Core body
    final corePaint = Paint()..color = color;
    canvas.drawCircle(center, size * 0.25 * pulseScale, corePaint);

    // Spikes
    final spikeCount = 8;
    for (int i = 0; i < spikeCount; i++) {
      final angle = (i / spikeCount) * math.pi * 2 + animationPhase * 0.5;
      final spikeLength = size * (0.4 + math.sin(animationPhase + i) * 0.1);

      final spikePath = Path()
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

      final spikePaint = Paint()
        ..color = i.isEven ? color : Color.lerp(color, Colors.white, 0.3)!;
      canvas.drawPath(spikePath, spikePaint);
    }

    // Angry eye
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size * 0.2, height: size * 0.15),
      eyePaint,
    );

    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(center, size * 0.05, pupilPaint);

    // Energy aura
    final auraPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scale);
    canvas.drawCircle(center, size * 0.5 * pulseScale, auraPaint);
  }

  void _renderWorm(Canvas canvas, Vector2 pos, double size, double scale, Color color, double health) {
    final center = Offset(pos.x, pos.y);

    // Worm segments
    final segmentCount = 5;
    final segmentSize = size * 0.2;

    for (int i = segmentCount - 1; i >= 0; i--) {
      final segmentPhase = animationPhase + i * 0.5;
      final xOffset = math.sin(segmentPhase) * size * 0.15;
      final yOffset = i * segmentSize * 0.6;

      final segmentCenter = Offset(center.dx + xOffset, center.dy + yOffset - size * 0.2);
      final currentSize = segmentSize * (1.0 - i * 0.12);

      // Segment shadow
      if (i == segmentCount - 1) {
        final shadowPaint = Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(segmentCenter.dx, center.dy + size * 0.4),
            width: size * 0.5,
            height: size * 0.15,
          ),
          shadowPaint,
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
      final segmentPaint = Paint()
        ..shader = segmentGradient.createShader(
          Rect.fromCircle(center: segmentCenter, radius: currentSize),
        );
      canvas.drawCircle(segmentCenter, currentSize, segmentPaint);

      // Segment ring
      final ringPaint = Paint()
        ..color = Color.lerp(color, Colors.black, 0.2)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(segmentCenter, currentSize * 0.8, ringPaint);
    }

    // Head (first segment with eyes)
    final headCenter = Offset(center.dx + math.sin(animationPhase) * size * 0.15, center.dy - size * 0.2);

    // Eyes
    final eyeWhite = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(headCenter.dx - size * 0.06, headCenter.dy - size * 0.02), size * 0.05, eyeWhite);
    canvas.drawCircle(Offset(headCenter.dx + size * 0.06, headCenter.dy - size * 0.02), size * 0.05, eyeWhite);

    final eyePupil = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(headCenter.dx - size * 0.06, headCenter.dy - size * 0.02), size * 0.025, eyePupil);
    canvas.drawCircle(Offset(headCenter.dx + size * 0.06, headCenter.dy - size * 0.02), size * 0.025, eyePupil);
  }

  void _renderVoid(Canvas canvas, Vector2 pos, double size, double scale, Color color, double health) {
    final center = Offset(pos.x, pos.y);

    // Void distortion effect
    final distortionPhase = animationPhase * 2;

    // Outer void aura (dark)
    final auraPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * scale);
    canvas.drawCircle(center, size * 0.6, auraPaint);

    // Swirling void particles
    final particlePaint = Paint()..color = color.withOpacity(0.6);
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2 + distortionPhase;
      final distance = size * (0.3 + math.sin(distortionPhase + i) * 0.1);
      canvas.drawCircle(
        Offset(
          center.dx + math.cos(angle) * distance,
          center.dy + math.sin(angle) * distance,
        ),
        size * 0.05,
        particlePaint,
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
    final voidPaint = Paint()
      ..shader = voidGradient.createShader(Rect.fromCircle(center: center, radius: size * 0.5));
    canvas.drawCircle(center, size * 0.5, voidPaint);

    // Event horizon ring
    final horizonPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale.clamp(0.5, 1.0);
    canvas.drawCircle(center, size * 0.35, horizonPaint);

    // Inner distortion
    for (int i = 0; i < 3; i++) {
      final ringRadius = size * (0.15 + i * 0.08);
      final ringPaint = Paint()
        ..color = color.withOpacity(0.3 - i * 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    // Glowing eye in the void
    final eyePaint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size * 0.15, height: size * 0.08),
      eyePaint,
    );
  }

  void _renderBoss(Canvas canvas, Vector2 pos, double size, double scale, Color color, double health) {
    // Boss is rendered larger with more detail
    final bossSize = size * 1.5;
    _renderSpike(canvas, pos, bossSize, scale, color, health);

    // Additional boss crown/horns
    final center = Offset(pos.x, pos.y);
    final crownPaint = Paint()..color = Colors.amber;

    // Crown points
    for (int i = 0; i < 3; i++) {
      final angle = -math.pi / 2 + (i - 1) * 0.4;
      final crownPath = Path()
        ..moveTo(center.dx + math.cos(angle) * bossSize * 0.2, center.dy - bossSize * 0.3)
        ..lineTo(center.dx + math.cos(angle) * bossSize * 0.1, center.dy - bossSize * 0.5)
        ..lineTo(center.dx + math.cos(angle + 0.15) * bossSize * 0.2, center.dy - bossSize * 0.3)
        ..close();
      canvas.drawPath(crownPath, crownPaint);
    }
  }

  void _renderHealthBar(Canvas canvas, Vector2 pos, double size, double healthPercent, Color color) {
    if (healthPercent >= 1.0) return; // Don't show full health

    final barWidth = size * 1.2;
    final barHeight = 4.0;
    final barY = pos.y - size * 0.7;

    // Background
    final bgPaint = Paint()..color = Colors.black.withOpacity(0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(pos.x, barY), width: barWidth, height: barHeight),
        const Radius.circular(2),
      ),
      bgPaint,
    );

    // Health fill
    final healthColor = healthPercent > 0.5
        ? color
        : healthPercent > 0.25
            ? Colors.orange
            : Colors.red;
    final healthPaint = Paint()..color = healthColor;
    final healthWidth = barWidth * healthPercent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.x - barWidth / 2, barY - barHeight / 2, healthWidth, barHeight),
        const Radius.circular(2),
      ),
      healthPaint,
    );
  }

  void _renderTargetIndicator(Canvas canvas, Vector2 pos, double size) {
    final center = Offset(pos.x, pos.y);

    // Pulsing target circle
    final pulseScale = 1.0 + math.sin(animationPhase * 5) * 0.1;
    final targetPaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, size * 0.8 * pulseScale, targetPaint);

    // Crosshair
    final crossSize = size * 0.6;
    canvas.drawLine(
      Offset(center.dx - crossSize, center.dy),
      Offset(center.dx - crossSize * 0.4, center.dy),
      targetPaint,
    );
    canvas.drawLine(
      Offset(center.dx + crossSize * 0.4, center.dy),
      Offset(center.dx + crossSize, center.dy),
      targetPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - crossSize),
      Offset(center.dx, center.dy - crossSize * 0.4),
      targetPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + crossSize * 0.4),
      Offset(center.dx, center.dy + crossSize),
      targetPaint,
    );

    // Corner brackets
    final bracketPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final bracketSize = size * 0.2;
    final bracketOffset = size * 0.7;

    // Top-left
    canvas.drawLine(
      Offset(center.dx - bracketOffset, center.dy - bracketOffset),
      Offset(center.dx - bracketOffset + bracketSize, center.dy - bracketOffset),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx - bracketOffset, center.dy - bracketOffset),
      Offset(center.dx - bracketOffset, center.dy - bracketOffset + bracketSize),
      bracketPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(center.dx + bracketOffset, center.dy - bracketOffset),
      Offset(center.dx + bracketOffset - bracketSize, center.dy - bracketOffset),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx + bracketOffset, center.dy - bracketOffset),
      Offset(center.dx + bracketOffset, center.dy - bracketOffset + bracketSize),
      bracketPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(center.dx - bracketOffset, center.dy + bracketOffset),
      Offset(center.dx - bracketOffset + bracketSize, center.dy + bracketOffset),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx - bracketOffset, center.dy + bracketOffset),
      Offset(center.dx - bracketOffset, center.dy + bracketOffset - bracketSize),
      bracketPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(center.dx + bracketOffset, center.dy + bracketOffset),
      Offset(center.dx + bracketOffset - bracketSize, center.dy + bracketOffset),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx + bracketOffset, center.dy + bracketOffset),
      Offset(center.dx + bracketOffset, center.dy + bracketOffset - bracketSize),
      bracketPaint,
    );
  }
}
