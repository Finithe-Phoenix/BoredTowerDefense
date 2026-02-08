import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../entities/enemy.dart';
import '../effects/explosion_effect.dart';

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
       _rngState = 0x4c957f2d {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(24);
    _rngState = (position.hashCode ^ 0x4c957f2d) & 0x7fffffff;
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
  int _rngState = 0x4c957f2d;
  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }
  double _nextUnit() => _lcgNext() / 0x7fffffff;

  // Orbiting particles
  final List<_OrbitParticle> _orbitParticles = [];
  static const int _particleCount = 6;

  // Visual properties
  static const Color _primaryColor = Color(0xFFFF0066); // Neon red/pink
  static const Color _secondaryColor = Color(0xFFFF7043); // Orange
  static const Color _armedColor = Color(0xFF00FF88); // Green when armed
  static const Color _hazardYellow = Color(0xFFFFDD00); // Hazard yellow

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _ringGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _corePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _innerDotPaint = Paint();
  static final Paint _hazardPaint = Paint();
  static final Paint _dangerFillPaint = Paint()
    ..style = PaintingStyle.fill;
  static final Paint _dangerBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _detectionPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _orbitPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _hexGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _hexStrokePaint = Paint()
    ..style = PaintingStyle.stroke;
  static final Paint _triFillPaint = Paint()
    ..style = PaintingStyle.fill;
  static final Paint _triGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _pulsingRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _scanLinePaint = Paint()
    ..strokeWidth = 1
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _flashPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _triggerCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _warningRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _dangerZoneFlashPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final TextStyle _progressTextStyle = TextStyle(
    color: Color(0xCCFFDD00),
    fontSize: 8,
    fontWeight: FontWeight.bold,
    fontFamily: 'monospace',
  );

  final TextPainter _progressPainter = TextPainter(textDirection: TextDirection.ltr);
  final TextPainter _statusPainter = TextPainter(textDirection: TextDirection.ltr);
  int _progressPercent = -1;
  String _statusText = '';
  int _statusColorValue = 0;
  final Path _trianglePath = Path();
  final Path _hexPath = Path();

  MineState get state => _state;
  bool get isArmed => _state == MineState.armed;

  void _initializeParticles() {
    for (int i = 0; i < _particleCount; i++) {
      _orbitParticles.add(_OrbitParticle(
        angle: (i / _particleCount) * math.pi * 2,
        radius: 18 + _nextUnit() * 4,
        speed: 1.5 + _nextUnit() * 0.5,
        size: 1.5 + _nextUnit(),
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
    final triggerRadiusSq = triggerRadius * triggerRadius; // Pre-compute squared

    for (final enemy in enemies()) {
      if (!enemy.isAlive) continue;

      // Use squared distance to avoid sqrt
      final distanceSq = (enemy.position - position).length2;
      if (distanceSq <= triggerRadiusSq) {
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
      position: position,
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
    _ringPaint.color = _hazardYellow.withOpacity(0.6);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 12),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      _ringPaint,
    );

    // Arming progress ring glow
    _ringGlowPaint.color = _hazardYellow.withOpacity(0.3);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 12),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      _ringGlowPaint,
    );

    // Core (dim, pulsing)
    final pulseIntensity = 0.3 + progress * 0.4 + math.sin(_pulseTimer * 10) * 0.1;
    _corePaint.color = _secondaryColor.withOpacity(pulseIntensity);
    canvas.drawCircle(center, 6, _corePaint);

    // Inner dot
    _innerDotPaint.color = _hazardYellow.withOpacity(0.7 * progress);
    canvas.drawCircle(
      center,
      3,
      _innerDotPaint,
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
    _hazardPaint.color = _hazardYellow.withOpacity(opacity * 0.5);
    for (int i = 0; i < segments; i++) {
      if (i % 2 == 0) {
        final startAngle = (i / segments) * math.pi * 2;
        final sweepAngle = math.pi / segments;

        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: 8),
          startAngle,
          sweepAngle,
          true,
          _hazardPaint,
        );
      }
    }

    canvas.restore();
  }

  void _renderDangerZone(Canvas canvas, Offset center, double opacity) {
    if (opacity <= 0) return;

    // Danger zone radius indicator
    _dangerFillPaint.color = _primaryColor.withOpacity(opacity * 0.1);

    canvas.drawCircle(
      center,
      explosionRadius,
      _dangerFillPaint,
    );

    // Danger zone border
    _dangerBorderPaint.color = _primaryColor.withOpacity(opacity * 0.3);

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
          _dangerBorderPaint,
        );
      }
    }
  }

  void _renderProgressText(Canvas canvas, Offset center, double progress) {
    final percentage = (progress * 100).toInt();
    if (_progressPercent != percentage) {
      _progressPercent = percentage;
      _progressPainter.text = TextSpan(text: '$percentage%', style: _progressTextStyle);
      _progressPainter.layout();
    }

    _progressPainter.paint(
      canvas,
      Offset(center.dx - _progressPainter.width / 2, center.dy + 16),
    );
  }

  void _renderArmed(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final pulse = math.sin(_pulseTimer * 4) * 0.3 + 0.7;

    // Danger zone preview (subtle)
    _renderDangerZone(canvas, center, 0.3);

    // Detection radius indicator (very subtle)
    _detectionPaint.color = _armedColor.withOpacity(0.05 + pulse * 0.05);
    canvas.drawCircle(center, 20, _detectionPaint);

    // Orbiting particles
    _orbitPaint.color = _armedColor.withOpacity(0.7);
    for (final particle in _orbitParticles) {
      final px = center.dx + math.cos(particle.angle) * particle.radius;
      final py = center.dy + math.sin(particle.angle) * particle.radius;

      canvas.drawCircle(
        Offset(px, py),
        particle.size,
        _orbitPaint,
      );
    }

    // Outer glow
    _glowPaint.color = _armedColor.withOpacity(0.2 * pulse);
    canvas.drawCircle(center, 14, _glowPaint);

    // Hexagon body with glow
    _drawHexagon(canvas, center, 10, _armedColor.withOpacity(0.7), 2);

    // Inner triangle (warning symbol) - animated
    final triRotation = math.sin(_pulseTimer * 2) * 0.1;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(triRotation);

    const triSize = 5.0;
    _trianglePath
      ..reset()
      ..moveTo(0, -triSize)
      ..lineTo(-triSize * 0.866, triSize * 0.5)
      ..lineTo(triSize * 0.866, triSize * 0.5)
      ..close();

    // Triangle glow
    _triGlowPaint.color = _armedColor.withOpacity(0.3);
    canvas.drawPath(
      _trianglePath,
      _triGlowPaint,
    );

    // Triangle fill
    _triFillPaint.color = _armedColor.withOpacity(pulse);
    canvas.drawPath(
      _trianglePath,
      _triFillPaint,
    );

    canvas.restore();

    // Pulsing ring
    final ringRadius = 12 + pulse * 3;
    _pulsingRingPaint.color = _armedColor.withOpacity(0.4);
    canvas.drawCircle(center, ringRadius, _pulsingRingPaint);

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
      _scanLinePaint..color = _armedColor.withOpacity(0.3),
    );
  }

  void _renderStatusText(Canvas canvas, Offset center, String text, Color color) {
    final colorValue = color.value;
    if (_statusText != text || _statusColorValue != colorValue) {
      _statusText = text;
      _statusColorValue = colorValue;
      _statusPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(0.6),
          fontSize: 6,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 1,
        ),
      );
      _statusPainter.layout();
    }

    _statusPainter.paint(
      canvas,
      Offset(center.dx - _statusPainter.width / 2, center.dy + 18),
    );
  }

  void _renderTriggered(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final flash = math.sin(_timer * 80) > 0 ? 1.0 : 0.3;

    // Danger zone flash
    _dangerZoneFlashPaint.color =
        _primaryColor.withOpacity((0.2 - _timer).clamp(0.0, 1.0) * flash);
    canvas.drawCircle(
      center,
      explosionRadius * (0.3 + _timer * 2),
      _dangerZoneFlashPaint,
    );

    // Rapid flash effect
    _flashPaint.color = _primaryColor.withOpacity(flash);
    canvas.drawCircle(center, 18, _flashPaint);

    // Core - intense white
    _triggerCorePaint.color = Colors.white.withOpacity(flash);
    canvas.drawCircle(center, 10, _triggerCorePaint);

    // Expanding warning rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (_timer * 8 + i * 0.1) % 0.5;
      final warningRadius = 15 + ringProgress * 80;
      final warningAlpha = (0.5 - ringProgress) * 0.8;

      if (warningAlpha > 0) {
        _warningRingPaint.color = _primaryColor.withOpacity(warningAlpha);
        canvas.drawCircle(
          center,
          warningRadius,
          _warningRingPaint,
        );
      }
    }

    // "DETONATING" text
    _renderStatusText(canvas, center, 'BOOM!', Colors.white);
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Color color, double strokeWidth) {
    _hexPath.reset();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        _hexPath.moveTo(x, y);
      } else {
        _hexPath.lineTo(x, y);
      }
    }
    _hexPath.close();

    // Glow
    _hexGlowPaint
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 3;
    canvas.drawPath(
      _hexPath,
      _hexGlowPaint,
    );

    // Main stroke
    _hexStrokePaint
      ..color = color
      ..strokeWidth = strokeWidth;
    canvas.drawPath(
      _hexPath,
      _hexStrokePaint,
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
