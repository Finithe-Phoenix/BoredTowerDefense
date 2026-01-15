import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../entities/enemy.dart';
import '../effects/explosion_effect.dart';
import '../../ui/theme/neon_theme.dart';

/// Mine states
enum MineState { arming, armed, triggered, exploded }

/// Deployable neon mine that explodes on enemy contact
class NeonMine extends PositionComponent {
  NeonMine({
    required Vector2 position,
    required this.enemies,
    required this.onExplode,
    this.damage = 150,
    this.explosionRadius = 60,
    this.armingTime = 0.5,
  }) : _state = MineState.arming,
       _timer = 0,
       _pulseTimer = 0,
       _random = math.Random() {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(24);
    _initializeParticles();
  }

  final List<Enemy> Function() enemies;
  final void Function(NeonMine mine) onExplode;
  final double damage;
  final double explosionRadius;
  final double armingTime;

  MineState _state;
  double _timer;
  double _pulseTimer;
  final math.Random _random;

  // Orbiting particles
  final List<_OrbitParticle> _orbitParticles = [];
  static const int _particleCount = 6;

  // Visual properties
  static const Color _primaryColor = Color(0xFFFF0066); // Neon red/pink
  static const Color _secondaryColor = Color(0xFFFF7043); // Orange
  static const Color _armedColor = Color(0xFF00FF88); // Green when armed
  static const Color _hazardYellow = Color(0xFFFFDD00); // Hazard yellow

  MineState get state => _state;
  bool get isArmed => _state == MineState.armed;

  void _initializeParticles() {
    for (int i = 0; i < _particleCount; i++) {
      _orbitParticles.add(_OrbitParticle(
        angle: (i / _particleCount) * math.pi * 2,
        radius: 18 + _random.nextDouble() * 4,
        speed: 1.5 + _random.nextDouble() * 0.5,
        size: 1.5 + _random.nextDouble(),
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _timer += dt;
    _pulseTimer += dt;

    // Update orbiting particles
    for (final particle in _orbitParticles) {
      particle.update(dt);
    }

    switch (_state) {
      case MineState.arming:
        if (_timer >= armingTime) {
          _state = MineState.armed;
          _timer = 0;
        }
        break;

      case MineState.armed:
        // Check for enemy proximity
        _checkEnemyProximity();
        break;

      case MineState.triggered:
        // Brief delay before explosion
        if (_timer >= 0.15) {
          _explode();
        }
        break;

      case MineState.exploded:
        // Already handled
        break;
    }
  }

  void _checkEnemyProximity() {
    final triggerRadius = math.max(28.0, explosionRadius * 0.4);

    for (final enemy in enemies()) {
      if (!enemy.isAlive) continue;

      final distance = (enemy.position - position).length;
      if (distance <= triggerRadius) {
        _trigger();
        break;
      }
    }
  }

  void _trigger() {
    _state = MineState.triggered;
    _timer = 0;
  }

  void _explode() {
    _state = MineState.exploded;

    // Damage all enemies in radius
    for (final enemy in enemies()) {
      if (!enemy.isAlive) continue;

      final distance = (enemy.position - position).length;
      if (distance <= explosionRadius) {
        // Damage falloff based on distance
        final falloff = 1.0 - (distance / explosionRadius) * 0.5;
        enemy.takeDamage(damage * falloff);
      }
    }

    // Spawn explosion effect
    final effect = ExplosionEffect.spawn(
      position: position.clone(),
      color: _primaryColor,
      explosionSize: explosionRadius,
      duration: 0.7,
    );
    if (effect != null) {
      parent?.add(effect);
    }

    // Notify callback and remove
    onExplode(this);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    switch (_state) {
      case MineState.arming:
        _renderArming(canvas);
        break;
      case MineState.armed:
        _renderArmed(canvas);
        break;
      case MineState.triggered:
        _renderTriggered(canvas);
        break;
      case MineState.exploded:
        // Don't render after explosion
        break;
    }
  }

  void _renderArming(Canvas canvas) {
    final progress = _timer / armingTime;
    final center = Offset(size.x / 2, size.y / 2);

    // Danger zone preview (fading in)
    _renderDangerZone(canvas, center, progress * 0.4);

    // Rotating hazard stripes
    _renderHazardStripes(canvas, center, progress);

    // Pulsing outer ring (incomplete)
    final ringPaint = Paint()
      ..color = _hazardYellow.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 12),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      ringPaint,
    );

    // Arming progress ring glow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 12),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = _hazardYellow.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Core (dim, pulsing)
    final pulseIntensity = 0.3 + progress * 0.4 + math.sin(_pulseTimer * 10) * 0.1;
    final corePaint = Paint()
      ..color = _secondaryColor.withOpacity(pulseIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, 6, corePaint);

    // Inner dot
    canvas.drawCircle(
      center,
      3,
      Paint()..color = _hazardYellow.withOpacity(0.7 * progress),
    );

    // Percentage text
    _renderProgressText(canvas, center, progress);
  }

  void _renderHazardStripes(Canvas canvas, Offset center, double opacity) {
    final rotation = _pulseTimer * 2; // Rotating stripes

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Draw 8 hazard segments
    const segments = 8;
    for (int i = 0; i < segments; i++) {
      if (i % 2 == 0) {
        final startAngle = (i / segments) * math.pi * 2;
        final sweepAngle = math.pi / segments;

        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: 8),
          startAngle,
          sweepAngle,
          true,
          Paint()..color = _hazardYellow.withOpacity(opacity * 0.5),
        );
      }
    }

    canvas.restore();
  }

  void _renderDangerZone(Canvas canvas, Offset center, double opacity) {
    if (opacity <= 0) return;

    // Danger zone radius indicator
    final dangerPaint = Paint()
      ..color = _primaryColor.withOpacity(opacity * 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      explosionRadius,
      dangerPaint,
    );

    // Danger zone border
    final borderPaint = Paint()
      ..color = _primaryColor.withOpacity(opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Dashed border effect
    const dashCount = 24;
    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        final startAngle = (i / dashCount) * math.pi * 2 + _pulseTimer * 0.5;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: explosionRadius),
          startAngle,
          math.pi / dashCount,
          false,
          borderPaint,
        );
      }
    }
  }

  void _renderProgressText(Canvas canvas, Offset center, double progress) {
    final percentage = (progress * 100).toInt();
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$percentage%',
        style: TextStyle(
          color: _hazardYellow.withOpacity(0.8),
          fontSize: 8,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + 16),
    );
  }

  void _renderArmed(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final pulse = math.sin(_pulseTimer * 4) * 0.3 + 0.7;

    // Danger zone preview (subtle)
    _renderDangerZone(canvas, center, 0.3);

    // Detection radius indicator (very subtle)
    final detectionPaint = Paint()
      ..color = _armedColor.withOpacity(0.05 + pulse * 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, 20, detectionPaint);

    // Orbiting particles
    for (final particle in _orbitParticles) {
      final px = center.dx + math.cos(particle.angle) * particle.radius;
      final py = center.dy + math.sin(particle.angle) * particle.radius;

      canvas.drawCircle(
        Offset(px, py),
        particle.size,
        Paint()
          ..color = _armedColor.withOpacity(0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // Outer glow
    final glowPaint = Paint()
      ..color = _armedColor.withOpacity(0.2 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, 14, glowPaint);

    // Hexagon body with glow
    _drawHexagon(canvas, center, 10, _armedColor.withOpacity(0.7), 2);

    // Inner triangle (warning symbol) - animated
    final triRotation = math.sin(_pulseTimer * 2) * 0.1;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(triRotation);

    final trianglePath = Path();
    const triSize = 5.0;
    trianglePath.moveTo(0, -triSize);
    trianglePath.lineTo(-triSize * 0.866, triSize * 0.5);
    trianglePath.lineTo(triSize * 0.866, triSize * 0.5);
    trianglePath.close();

    // Triangle glow
    canvas.drawPath(
      trianglePath,
      Paint()
        ..color = _armedColor.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Triangle fill
    canvas.drawPath(
      trianglePath,
      Paint()
        ..color = _armedColor.withOpacity(pulse)
        ..style = PaintingStyle.fill,
    );

    canvas.restore();

    // Pulsing ring
    final ringRadius = 12 + pulse * 3;
    final ringPaint = Paint()
      ..color = _armedColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center, ringRadius, ringPaint);

    // "ARMED" status indicator
    _renderStatusText(canvas, center, 'ARMED', _armedColor);

    // Rotating scan line
    _renderScanLine(canvas, center);
  }

  void _renderScanLine(Canvas canvas, Offset center) {
    final scanAngle = _pulseTimer * 3;
    final scanLength = 18.0;

    final endX = center.dx + math.cos(scanAngle) * scanLength;
    final endY = center.dy + math.sin(scanAngle) * scanLength;

    canvas.drawLine(
      center,
      Offset(endX, endY),
      Paint()
        ..color = _armedColor.withOpacity(0.3)
        ..strokeWidth = 1
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  void _renderStatusText(Canvas canvas, Offset center, String text, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(0.6),
          fontSize: 6,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + 18),
    );
  }

  void _renderTriggered(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final flash = math.sin(_timer * 80) > 0 ? 1.0 : 0.3;

    // Danger zone flash
    canvas.drawCircle(
      center,
      explosionRadius * (0.3 + _timer * 2),
      Paint()
        ..color = _primaryColor.withOpacity((0.2 - _timer).clamp(0.0, 1.0) * flash)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Rapid flash effect
    final flashPaint = Paint()
      ..color = _primaryColor.withOpacity(flash)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, 18, flashPaint);

    // Core - intense white
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(flash)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, 10, corePaint);

    // Expanding warning rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (_timer * 8 + i * 0.1) % 0.5;
      final warningRadius = 15 + ringProgress * 80;
      final warningAlpha = (0.5 - ringProgress) * 0.8;

      if (warningAlpha > 0) {
        canvas.drawCircle(
          center,
          warningRadius,
          Paint()
            ..color = _primaryColor.withOpacity(warningAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }

    // "DETONATING" text
    _renderStatusText(canvas, center, 'BOOM!', Colors.white);
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Color color, double strokeWidth) {
    final path = NeonEffects.createHexagonPath(center, radius);

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Main stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }
}

class _OrbitParticle {
  _OrbitParticle({
    required this.angle,
    required this.radius,
    required this.speed,
    required this.size,
  });

  double angle;
  final double radius;
  final double speed;
  final double size;

  void update(double dt) {
    angle += dt * speed;
  }
}
