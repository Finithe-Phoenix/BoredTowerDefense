import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Types of floating text
enum FloatingTextType {
  damage,
  gold,
  heal,
  critical,
  levelUp,
  combo,
}

/// Floating text that rises and fades out
class FloatingText extends PositionComponent {
  FloatingText({
    required Vector2 position,
    required this.text,
    this.type = FloatingTextType.damage,
    this.customColor,
    this.fontSize = 14,
    this.duration = 0.8,
    this.riseSpeed = 40,
  }) : _timer = 0,
       _random = math.Random() {
    this.position = position;
    anchor = Anchor.center;
    _wobbleOffset = (_random.nextDouble() - 0.5) * 20;
  }

  final String text;
  final FloatingTextType type;
  final Color? customColor;
  final double fontSize;
  final double duration;
  final double riseSpeed;

  double _timer;
  final math.Random _random;
  late double _wobbleOffset;

  Color get _color => customColor ?? _getTypeColor();

  Color _getTypeColor() {
    switch (type) {
      case FloatingTextType.damage:
        return const Color(0xFFFF0066); // Neon red/magenta
      case FloatingTextType.gold:
        return const Color(0xFFFFDD00); // Gold
      case FloatingTextType.heal:
        return const Color(0xFF00FF88); // Neon green
      case FloatingTextType.critical:
        return const Color(0xFFFFFFFF); // White
      case FloatingTextType.levelUp:
        return const Color(0xFF00FFFF); // Cyan
      case FloatingTextType.combo:
        return const Color(0xFFFF00FF); // Magenta
    }
  }

  double get _scaleMult {
    switch (type) {
      case FloatingTextType.damage:
        return 1.0;
      case FloatingTextType.gold:
        return 1.1;
      case FloatingTextType.heal:
        return 1.0;
      case FloatingTextType.critical:
        return 1.4;
      case FloatingTextType.levelUp:
        return 1.3;
      case FloatingTextType.combo:
        return 1.2;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (_timer >= duration) {
      removeFromParent();
      return;
    }

    // Rise upward with slight horizontal drift
    position.y -= riseSpeed * dt;
    position.x += math.sin(_timer * 5) * dt * 10;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = _timer / duration;
    final alpha = (1 - progress).clamp(0.0, 1.0);

    // Scale animation - pop in then shrink out
    double scale;
    if (progress < 0.1) {
      scale = progress / 0.1 * 1.2; // Pop in
    } else if (progress < 0.2) {
      scale = 1.2 - (progress - 0.1) / 0.1 * 0.2; // Settle
    } else {
      scale = 1.0 - (progress - 0.2) / 0.8 * 0.3; // Shrink
    }
    scale *= _scaleMult;

    // Render glow behind text
    _renderTextGlow(canvas, scale, alpha);

    // Render main text
    _renderText(canvas, scale, alpha);

    // Type-specific effects
    _renderTypeEffects(canvas, progress, alpha);
  }

  void _renderTextGlow(Canvas canvas, double scale, double alpha) {
    final textStyle = TextStyle(
      color: _color.withOpacity(alpha * 0.5),
      fontSize: fontSize * scale,
      fontFamily: 'monospace',
      fontWeight: FontWeight.bold,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    // Draw multiple times for glow effect
    for (int i = 0; i < 3; i++) {
      final offset = i * 2.0;
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2 - offset / 2, -textPainter.height / 2 - offset / 2),
      );
    }
  }

  void _renderText(Canvas canvas, double scale, double alpha) {
    final textStyle = TextStyle(
      color: _color.withOpacity(alpha),
      fontSize: fontSize * scale,
      fontFamily: 'monospace',
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          color: _color.withOpacity(alpha * 0.8),
          blurRadius: 8,
        ),
        Shadow(
          color: Colors.black.withOpacity(alpha * 0.5),
          blurRadius: 4,
          offset: const Offset(1, 1),
        ),
      ],
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }

  void _renderTypeEffects(Canvas canvas, double progress, double alpha) {
    switch (type) {
      case FloatingTextType.critical:
        // Starburst behind critical hits
        if (progress < 0.3) {
          final burstProgress = progress / 0.3;
          final burstAlpha = (1 - burstProgress) * alpha;
          final burstRadius = 20 + burstProgress * 15;

          for (int i = 0; i < 8; i++) {
            final angle = i * math.pi / 4 + progress * 5;
            final lineLength = burstRadius;

            canvas.drawLine(
              Offset.zero,
              Offset(math.cos(angle) * lineLength, math.sin(angle) * lineLength),
              Paint()
                ..color = _color.withOpacity(burstAlpha * 0.5)
                ..strokeWidth = 2
                ..strokeCap = StrokeCap.round
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
            );
          }
        }
        break;

      case FloatingTextType.gold:
        // Gold sparkles
        for (int i = 0; i < 4; i++) {
          final sparklePhase = _timer * 8 + i * math.pi / 2;
          final sparkleAlpha = alpha * (0.5 + math.sin(sparklePhase) * 0.5);
          final sparkleX = math.cos(sparklePhase) * 15;
          final sparkleY = math.sin(sparklePhase * 0.5) * 8;

          canvas.drawCircle(
            Offset(sparkleX, sparkleY),
            2,
            Paint()
              ..color = _color.withOpacity(sparkleAlpha)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
          );
        }
        break;

      case FloatingTextType.combo:
        // Combo ring effect
        final ringRadius = 15 + progress * 10;
        final ringAlpha = alpha * 0.4;

        canvas.drawCircle(
          Offset.zero,
          ringRadius,
          Paint()
            ..color = _color.withOpacity(ringAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        break;

      default:
        break;
    }
  }
}

/// Resource popup that appears when gaining/losing resources
class ResourcePopup extends PositionComponent {
  ResourcePopup({
    required Vector2 position,
    required this.amount,
    required this.icon,
    this.isGain = true,
    this.duration = 1.2,
  }) : _timer = 0 {
    this.position = position;
    anchor = Anchor.center;
  }

  final int amount;
  final String icon; // Emoji or symbol
  final bool isGain;
  final double duration;

  double _timer;

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (_timer >= duration) {
      removeFromParent();
      return;
    }

    // Float upward
    position.y -= 30 * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = _timer / duration;
    final alpha = (1 - progress).clamp(0.0, 1.0);

    // Scale animation
    double scale;
    if (progress < 0.15) {
      scale = progress / 0.15 * 1.3; // Pop in
    } else if (progress < 0.25) {
      scale = 1.3 - (progress - 0.15) / 0.1 * 0.3; // Settle
    } else {
      scale = 1.0;
    }

    final color = isGain
        ? const Color(0xFF00FF88) // Green for gain
        : const Color(0xFFFF0066); // Red for loss

    final prefix = isGain ? '+' : '-';
    final text = '$prefix$amount';

    // Render icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: icon,
        style: TextStyle(
          fontSize: 16 * scale,
          color: Colors.white.withOpacity(alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Render amount
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(alpha),
          fontSize: 14 * scale,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: color.withOpacity(alpha * 0.8),
              blurRadius: 6,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final totalWidth = iconPainter.width + 4 + textPainter.width;

    iconPainter.paint(canvas, Offset(-totalWidth / 2, -iconPainter.height / 2));
    textPainter.paint(canvas, Offset(-totalWidth / 2 + iconPainter.width + 4, -textPainter.height / 2));

    // Glow effect
    canvas.drawCircle(
      Offset.zero,
      20 * scale,
      Paint()
        ..color = color.withOpacity(alpha * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }
}

/// Kill streak notification
class KillStreakNotification extends PositionComponent {
  KillStreakNotification({
    required Vector2 position,
    required this.streakCount,
    this.duration = 1.5,
  }) : _timer = 0 {
    this.position = position;
    anchor = Anchor.center;
  }

  final int streakCount;
  final double duration;

  double _timer;

  String get _streakText {
    if (streakCount >= 10) return 'MASSACRE!';
    if (streakCount >= 7) return 'UNSTOPPABLE!';
    if (streakCount >= 5) return 'KILLING SPREE!';
    if (streakCount >= 3) return 'MULTI-KILL!';
    return 'DOUBLE KILL!';
  }

  Color get _color {
    if (streakCount >= 10) return const Color(0xFFFF0000);
    if (streakCount >= 7) return const Color(0xFFFF00FF);
    if (streakCount >= 5) return const Color(0xFFFFDD00);
    if (streakCount >= 3) return const Color(0xFF00FFFF);
    return const Color(0xFF00FF88);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (_timer >= duration) {
      removeFromParent();
      return;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = _timer / duration;
    final alpha = progress < 0.8 ? 1.0 : (1 - (progress - 0.8) / 0.2);

    // Scale animation with bounce
    double scale;
    if (progress < 0.1) {
      scale = progress / 0.1 * 1.5;
    } else if (progress < 0.2) {
      scale = 1.5 - (progress - 0.1) / 0.1 * 0.3;
    } else if (progress < 0.3) {
      scale = 1.2 + (progress - 0.2) / 0.1 * 0.1;
    } else {
      scale = 1.3 - (progress - 0.3) / 0.7 * 0.3;
    }

    // Glow background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 160 * scale, height: 40 * scale),
        const Radius.circular(20),
      ),
      Paint()
        ..color = _color.withOpacity(alpha * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 140 * scale, height: 30 * scale),
        const Radius.circular(15),
      ),
      Paint()..color = Colors.black.withOpacity(alpha * 0.7),
    );

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 140 * scale, height: 30 * scale),
        const Radius.circular(15),
      ),
      Paint()
        ..color = _color.withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: _streakText,
        style: TextStyle(
          color: _color.withOpacity(alpha),
          fontSize: 14 * scale,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          shadows: [
            Shadow(
              color: _color.withOpacity(alpha * 0.8),
              blurRadius: 8,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    // Streak count
    final countPainter = TextPainter(
      text: TextSpan(
        text: 'x$streakCount',
        style: TextStyle(
          color: Colors.white.withOpacity(alpha),
          fontSize: 10 * scale,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    countPainter.paint(
      canvas,
      Offset(50 * scale, -countPainter.height / 2),
    );
  }
}
