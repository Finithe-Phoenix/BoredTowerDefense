import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bored_games_game.dart';
import '../entities/tower.dart';
import '../../ui/theme/neon_theme.dart';

class FocusModeOverlay extends PositionComponent with HasGameRef<BoredGamesGame> {
  FocusModeOverlay() {
    anchor = Anchor.topLeft;
    priority = 90;
  }

  final math.Random _random = math.Random();
  final List<double> _streakAngles =
      List<double>.generate(12, (i) => (i / 12) * math.pi * 2);
  final List<_HitMarker> _hitMarkers = [];
  double _time = 0;

  void registerHit(Vector2 screenPos, {required bool critical}) {
    if (_hitMarkers.length >= 6) {
      _hitMarkers.removeAt(0);
    }
    _hitMarkers.add(_HitMarker(
      position: screenPos.clone(),
      critical: critical,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    for (int i = _hitMarkers.length - 1; i >= 0; i--) {
      _hitMarkers[i].update(dt);
      if (_hitMarkers[i].expired) {
        _hitMarkers.removeAt(i);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!gameRef.focusModeActive) return;
    if (gameRef.size.isZero()) return;

    final width = gameRef.size.x;
    final height = gameRef.size.y;
    final center = Offset(width / 2, height / 2);
    final reduceFx = gameRef.reduceFx;
    final accent = gameRef.focusTower?.color ?? NeonColors.cyan;
    final fxPulse = gameRef.focusFxPulse;

    _drawVignette(canvas, width, height, accent, reduceFx);
    _drawFocusWarp(canvas, center, accent, fxPulse, reduceFx);
    if (!reduceFx) {
      _drawSpeedLines(canvas, center, accent);
    }
    _drawReticle(canvas, center, accent, reduceFx);
    _drawCornerHud(canvas, width, height, accent);
    _drawTargetLock(canvas, accent, reduceFx);
    _drawHitMarkers(canvas, accent);
    _drawFocusLabel(canvas, width, accent);
  }

  void _drawVignette(
    Canvas canvas,
    double width,
    double height,
    Color accent,
    bool reduceFx,
  ) {
    final intensity = reduceFx ? 0.35 : 0.55;
    final rect = Rect.fromLTWH(0, 0, width, height);
    final gradient = RadialGradient(
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(0.35 * intensity),
        Colors.black.withOpacity(0.75 * intensity),
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = gradient);

    final edgeAlpha = reduceFx ? 0.08 : 0.12;
    final edgePaint = Paint()
      ..color = accent.withOpacity(edgeAlpha);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, 2), edgePaint);
    canvas.drawRect(Rect.fromLTWH(0, height - 2, width, 2), edgePaint);
  }

  void _drawSpeedLines(Canvas canvas, Offset center, Color accent) {
    final pulse = 0.4 + math.sin(_time * 2.4) * 0.2;
    final linePaint = Paint()
      ..color = accent.withOpacity(0.18 + pulse * 0.2)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < _streakAngles.length; i++) {
      final angle = _streakAngles[i] + math.sin(_time * 0.6 + i) * 0.2;
      final base = 60 + i * 3.0;
      final wobble = math.sin(_time * 2.0 + i) * 8;
      final length = base + 30 + wobble.abs();
      final start = Offset(
        center.dx + math.cos(angle) * base,
        center.dy + math.sin(angle) * base,
      );
      final end = Offset(
        center.dx + math.cos(angle) * (base + length),
        center.dy + math.sin(angle) * (base + length),
      );
      canvas.drawLine(start, end, linePaint);
    }

    if (_random.nextDouble() < 0.12) {
      final blinkPaint = Paint()
        ..color = accent.withOpacity(0.3)
        ..strokeWidth = 2.0;
      final angle = _random.nextDouble() * math.pi * 2;
      final burst = 110 + _random.nextDouble() * 40;
      final start = Offset(
        center.dx + math.cos(angle) * burst,
        center.dy + math.sin(angle) * burst,
      );
      final end = Offset(
        center.dx + math.cos(angle) * (burst + 24),
        center.dy + math.sin(angle) * (burst + 24),
      );
      canvas.drawLine(start, end, blinkPaint);
    }
  }

  void _drawReticle(Canvas canvas, Offset center, Color accent, bool reduceFx) {
    final pulse = 0.65 + math.sin(_time * 3.0) * 0.1;
    final ringRadius = 36 + math.sin(_time * 2.2) * 2;
    final ringPaint = Paint()
      ..color = accent.withOpacity(0.6 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, ringRadius, ringPaint);

    final innerPaint = Paint()
      ..color = accent.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, ringRadius * 0.55, innerPaint);

    final crossPaint = Paint()
      ..color = accent.withOpacity(0.8 * pulse)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(center.dx - 18, center.dy),
      Offset(center.dx - 6, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx + 6, center.dy),
      Offset(center.dx + 18, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 18),
      Offset(center.dx, center.dy - 6),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + 6),
      Offset(center.dx, center.dy + 18),
      crossPaint,
    );

    if (!reduceFx) {
      NeonEffects.drawGlowingCircle(
        canvas,
        center,
        3,
        accent,
        glow: GlowIntensity.subtle,
      );
    }

    _drawReticleDecor(canvas, center, accent, reduceFx);
  }

  void _drawReticleDecor(
    Canvas canvas,
    Offset center,
    Color accent,
    bool reduceFx,
  ) {
    final tower = gameRef.focusTower;
    if (tower == null) return;
    final type = tower.type;
    final alpha = 0.5 + math.sin(_time * 2.8) * 0.2;
    final paint = Paint()
      ..color = accent.withOpacity(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    if (!reduceFx) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    }

    switch (type) {
      case TowerType.pulseArcher:
        for (int i = 0; i < 4; i++) {
          final angle = i * math.pi / 2 + _time * 0.4;
          final r1 = 22.0;
          final r2 = 28.0;
          final p1 = Offset(
            center.dx + math.cos(angle) * r1,
            center.dy + math.sin(angle) * r1,
          );
          final p2 = Offset(
            center.dx + math.cos(angle) * r2,
            center.dy + math.sin(angle) * r2,
          );
          canvas.drawLine(p1, p2, paint);
        }
        break;
      case TowerType.circuitCannon:
        final size = 30.0;
        final rect = Rect.fromCenter(
          center: center,
          width: size,
          height: size,
        );
        canvas.drawRect(rect, paint);
        canvas.drawLine(
          Offset(center.dx - size / 2, center.dy),
          Offset(center.dx + size / 2, center.dy),
          paint,
        );
        break;
      case TowerType.phaseMage:
        final diamond = Path()
          ..moveTo(center.dx, center.dy - 18)
          ..lineTo(center.dx + 18, center.dy)
          ..lineTo(center.dx, center.dy + 18)
          ..lineTo(center.dx - 18, center.dy)
          ..close();
        canvas.drawPath(diamond, paint);
        break;
      case TowerType.glimmerField:
        for (int i = 0; i < 6; i++) {
          final angle = i * math.pi / 3 + _time * 0.5;
          final r1 = 16.0;
          final r2 = 26.0;
          canvas.drawLine(
            Offset(
              center.dx + math.cos(angle) * r1,
              center.dy + math.sin(angle) * r1,
            ),
            Offset(
              center.dx + math.cos(angle) * r2,
              center.dy + math.sin(angle) * r2,
            ),
            paint,
          );
        }
        break;
    }
  }

  void _drawFocusWarp(
    Canvas canvas,
    Offset center,
    Color accent,
    double pulse,
    bool reduceFx,
  ) {
    if (pulse <= 0) return;
    final intensity = pulse * (reduceFx ? 0.25 : 0.55);
    final radius = 140 + pulse * 80;
    final blurPaint = Paint()
      ..color = accent.withOpacity(0.08 * intensity)
      ..maskFilter = reduceFx ? null : const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, radius, blurPaint);

    final chromaPaint = Paint()
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final angle = _streakAngles[i] + _time * 0.7;
      final start = Offset(
        center.dx + math.cos(angle) * (radius * 0.6),
        center.dy + math.sin(angle) * (radius * 0.6),
      );
      final end = Offset(
        center.dx + math.cos(angle) * (radius * 0.75),
        center.dy + math.sin(angle) * (radius * 0.75),
      );
      chromaPaint.color =
          NeonColors.red.withOpacity(0.25 * intensity);
      canvas.drawLine(start.translate(-2, 0), end.translate(-2, 0), chromaPaint);
      chromaPaint.color =
          NeonColors.cyan.withOpacity(0.25 * intensity);
      canvas.drawLine(start, end, chromaPaint);
    }
  }

  void _drawHitMarkers(Canvas canvas, Color accent) {
    if (_hitMarkers.isEmpty) return;
    for (final marker in _hitMarkers) {
      final progress = marker.progress;
      final alpha = (1 - progress).clamp(0.0, 1.0);
      final color = marker.critical
          ? NeonColors.red
          : accent;
      final size = marker.critical ? 16.0 : 12.0;
      final width = marker.critical ? 2.4 : 1.6;
      final paint = Paint()
        ..color = color.withOpacity(alpha)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.square;
      if (!gameRef.reduceFx) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      }
      final x = marker.position.x;
      final y = marker.position.y;
      canvas.drawLine(
        Offset(x - size, y - size),
        Offset(x - size / 2, y - size / 2),
        paint,
      );
      canvas.drawLine(
        Offset(x + size, y - size),
        Offset(x + size / 2, y - size / 2),
        paint,
      );
      canvas.drawLine(
        Offset(x - size, y + size),
        Offset(x - size / 2, y + size / 2),
        paint,
      );
      canvas.drawLine(
        Offset(x + size, y + size),
        Offset(x + size / 2, y + size / 2),
        paint,
      );

      if (marker.critical) {
        canvas.drawCircle(
          Offset(x, y),
          10 + (1 - progress) * 4,
          Paint()
            ..color = color.withOpacity(0.25 * alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  void _drawCornerHud(Canvas canvas, double width, double height, Color accent) {
    const size = 18.0;
    const pad = 12.0;
    NeonEffects.drawCornerBracket(
      canvas,
      const Offset(pad, pad),
      size,
      accent.withOpacity(0.7),
      topLeft: true,
    );
    NeonEffects.drawCornerBracket(
      canvas,
      Offset(width - pad, pad),
      size,
      accent.withOpacity(0.7),
      topRight: true,
    );
    NeonEffects.drawCornerBracket(
      canvas,
      Offset(pad, height - pad),
      size,
      accent.withOpacity(0.7),
      bottomLeft: true,
    );
    NeonEffects.drawCornerBracket(
      canvas,
      Offset(width - pad, height - pad),
      size,
      accent.withOpacity(0.7),
      bottomRight: true,
    );
  }

  void _drawTargetLock(Canvas canvas, Color accent, bool reduceFx) {
    final target = gameRef.focusTarget;
    if (target == null || !target.isAlive) return;

    final screenPos = gameRef.worldToScreen(target.position);
    final width = gameRef.size.x;
    final height = gameRef.size.y;
    if (screenPos.x < 0 ||
        screenPos.x > width ||
        screenPos.y < 0 ||
        screenPos.y > height) {
      return;
    }

    final lockPulse = 0.5 + math.sin(_time * 5.0) * 0.2;
    final lockColor = Color.lerp(accent, NeonColors.red, 0.35)!;
    final radius = reduceFx ? 18.0 : 24.0;
    final ringPaint = Paint()
      ..color = lockColor.withOpacity(0.7 * lockPulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(Offset(screenPos.x, screenPos.y), radius, ringPaint);

    final bracketSize = radius + 6;
    NeonEffects.drawCornerBracket(
      canvas,
      Offset(screenPos.x - bracketSize, screenPos.y - bracketSize),
      8,
      lockColor.withOpacity(0.8),
      topLeft: true,
    );
    NeonEffects.drawCornerBracket(
      canvas,
      Offset(screenPos.x + bracketSize, screenPos.y - bracketSize),
      8,
      lockColor.withOpacity(0.8),
      topRight: true,
    );
    NeonEffects.drawCornerBracket(
      canvas,
      Offset(screenPos.x - bracketSize, screenPos.y + bracketSize),
      8,
      lockColor.withOpacity(0.8),
      bottomLeft: true,
    );
    NeonEffects.drawCornerBracket(
      canvas,
      Offset(screenPos.x + bracketSize, screenPos.y + bracketSize),
      8,
      lockColor.withOpacity(0.8),
      bottomRight: true,
    );
  }

  void _drawFocusLabel(Canvas canvas, double width, Color accent) {
    final pulse = 0.7 + math.sin(_time * 3.2) * 0.2;
    final painter = TextPainter(
      text: TextSpan(
        text: 'FOCUS MODE',
        style: NeonTextStyles.small.copyWith(
          color: accent.withOpacity(pulse),
          fontSize: 11,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(width / 2 - painter.width / 2, 6),
    );
  }
}

class _HitMarker {
  _HitMarker({
    required this.position,
    required this.critical,
  });

  final Vector2 position;
  final bool critical;
  double _timer = 0;
  double get progress => (_timer / (critical ? 0.55 : 0.4)).clamp(0.0, 1.0);
  bool get expired => _timer >= (critical ? 0.55 : 0.4);

  void update(double dt) {
    _timer += dt;
  }
}
