import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../services/audio_service.dart';

class HudButton extends PositionComponent with TapCallbacks {
  HudButton({
    required this.label,
    required this.onPressed,
    required Vector2 position,
    Vector2? size,
    this.color = const Color(0xFF00FFFF),
    this.isSelected = false,
    this.reduceFlicker = false,
    bool enabled = true,
  })  : buttonSize = size ?? Vector2(110, 44),
        isEnabled = enabled {
    this.position = position;
    this.size = buttonSize;
    anchor = Anchor.topLeft;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _bgPaint = Paint();
  static final Paint _gradientPaint = Paint();
  static final Paint _borderPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _linePaint = Paint()..strokeCap = StrokeCap.round;
  static final Paint _pressPaint = Paint();
  static final Paint _hoverGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _highlightPaint = Paint();
  static final Paint _shadowPaint = Paint()..strokeWidth = 1;
  static final Paint _scanPaint = Paint();

  final String label;
  final VoidCallback onPressed;
  final Vector2 buttonSize;
  final Color color;
  bool isSelected;
  bool isEnabled;
  final bool reduceFlicker;

  bool get enabled => isEnabled;
  set enabled(bool value) => isEnabled = value;

  double _time = 0;
  double _hoverScale = 0;
  double _pressAnimation = 0;
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Smooth hover/selection animation
    final targetScale = (isSelected || _isHovered) ? 1.0 : 0.0;
    _hoverScale += (targetScale - _hoverScale) * dt * 8;
    _hoverScale = _hoverScale.clamp(0.0, 1.0);

    // Press animation decay
    if (!_isPressed && _pressAnimation > 0) {
      _pressAnimation = (_pressAnimation - dt * 8).clamp(0, 1);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromLTWH(0, 0, buttonSize.x, buttonSize.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // === MODERN BUTTON STYLE ===

    // Outer glow when selected
    if (isSelected) {
      _glowPaint.color = color.withOpacity(0.4);
      canvas.drawRRect(rrect.inflate(3), _glowPaint);
    }

    // Main background - glassmorphic style
    final bgColor = isSelected
        ? color.withOpacity(0.25)
        : (isEnabled ? const Color(0xFF0a0a18).withOpacity(0.8) : const Color(0xFF0a0a18).withOpacity(0.4));
    _bgPaint.color = bgColor;
    canvas.drawRRect(rrect, _bgPaint);

    // Gradient overlay for depth
    _gradientPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withOpacity(isSelected ? 0.15 : 0.08),
        Colors.transparent,
        Colors.black.withOpacity(0.2),
      ],
      stops: const [0.0, 0.3, 1.0],
    ).createShader(rect);
    canvas.drawRRect(rrect, _gradientPaint);

    // Border
    final borderColor = isSelected
        ? color
        : (isEnabled ? color.withOpacity(0.4) : color.withOpacity(0.15));
    _borderPaint.color = borderColor;
    _borderPaint.strokeWidth = isSelected ? 2 : 1;
    canvas.drawRRect(rrect, _borderPaint);

    // Bottom accent line when selected
    if (isSelected) {
      final lineY = buttonSize.y - 3;
      _linePaint.color = color;
      _linePaint.strokeWidth = 2;
      canvas.drawLine(Offset(8, lineY), Offset(buttonSize.x - 8, lineY), _linePaint);
    }

    // === PRESS EFFECT ===
    if (_pressAnimation > 0) {
      _pressPaint.color = color.withOpacity(0.3 * _pressAnimation);
      canvas.drawRRect(rrect, _pressPaint);
    }

    // === TEXT ===
    _drawLabel(canvas);
  }

  void _drawBackground(Canvas canvas, Rect rect) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    // Outer glow when selected/hovered
    if (_hoverScale > 0) {
      _hoverGlowPaint.color = color.withOpacity(0.25 * _hoverScale);
      canvas.drawRRect(rrect.inflate(4), _hoverGlowPaint);
    }

    // Main background gradient
    _gradientPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(const Color(0xFF1a1a2e), color.withOpacity(0.3), _hoverScale * 0.3)!,
        Color.lerp(const Color(0xFF0a0a18), color.withOpacity(0.15), _hoverScale * 0.2)!,
        Color.lerp(const Color(0xFF080812), color.withOpacity(0.1), _hoverScale * 0.15)!,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);

    canvas.drawRRect(rrect, _gradientPaint);

    // Inner highlight at top
    final highlightRect = Rect.fromLTWH(2, 2, buttonSize.x - 4, 12);
    _highlightPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.15 + _hoverScale * 0.1),
        Colors.transparent,
      ],
    ).createShader(highlightRect);

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(4)));
    canvas.drawRect(highlightRect, _highlightPaint);
    canvas.restore();

    // Bottom shadow line
    _shadowPaint.color = Colors.black.withOpacity(0.3);
    canvas.drawLine(
      Offset(4, buttonSize.y - 2),
      Offset(buttonSize.x - 4, buttonSize.y - 2),
      _shadowPaint,
    );
  }

  void _drawAnimatedEffects(Canvas canvas, Rect rect) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    if (!reduceFlicker) {
      // Scanning line effect
      final scanProgress = (_time * 0.8) % 1.0;
      final scanY = scanProgress * buttonSize.y;

      final scanGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          color.withOpacity(0.08 + _hoverScale * 0.1),
          color.withOpacity(0.15 + _hoverScale * 0.15),
          color.withOpacity(0.08 + _hoverScale * 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 10, buttonSize.x, 20));

      canvas.save();
      canvas.clipRRect(rrect);
      _scanPaint.shader = scanGradient;
      canvas.drawRect(Rect.fromLTWH(0, scanY - 10, buttonSize.x, 20), _scanPaint);
      canvas.restore();
    }

    // Data particles effect when selected
    if (isSelected) {
      final particleCount = 3;
      for (int i = 0; i < particleCount; i++) {
        final particlePhase = (_time * 2 + i * 0.4) % 1.0;
        final particleX = 6 + particlePhase * (buttonSize.x - 12);
        final particleY = buttonSize.y - 6 - math.sin(particlePhase * math.pi) * 4;
        final particleAlpha = math.sin(particlePhase * math.pi) * 0.6;

        if (particleAlpha > 0) {
          canvas.drawCircle(
            Offset(particleX, particleY),
            1.5,
            Paint()
              ..color = color.withOpacity(particleAlpha)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
          );
        }
      }
    }
  }

  void _drawFrame(Canvas canvas, Rect rect) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    // Outer frame
    final borderPulse = reduceFlicker ? 0.0 : math.sin(_time * 3) * 0.05;
    final borderAlpha = 0.4 + _hoverScale * 0.3 + borderPulse;
    final borderPaint = Paint()
      ..color = color.withOpacity(borderAlpha.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2 : 1;

    canvas.drawRRect(rrect, borderPaint);

    // Inner subtle frame
    final innerRRect = RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(3));
    canvas.drawRRect(
      innerRRect,
      Paint()
        ..color = color.withOpacity(0.1 + _hoverScale * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // Corner accents - more prominent
    _drawCornerAccents(canvas, rect);

    // Tech detail lines
    _drawTechDetails(canvas, rect);
  }

  void _drawCornerAccents(Canvas canvas, Rect rect) {
    final accentAlpha = 0.7 + _hoverScale * 0.3;
    final accentPaint = Paint()
      ..color = color.withOpacity(accentAlpha)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const size = 10.0;
    const offset = 1.0;

    // Top-left
    canvas.drawLine(Offset(offset, size + offset), Offset(offset, offset), accentPaint);
    canvas.drawLine(Offset(offset, offset), Offset(size + offset, offset), accentPaint);

    // Top-right
    canvas.drawLine(Offset(rect.width - size - offset, offset), Offset(rect.width - offset, offset), accentPaint);
    canvas.drawLine(Offset(rect.width - offset, offset), Offset(rect.width - offset, size + offset), accentPaint);

    // Bottom-left
    canvas.drawLine(Offset(offset, rect.height - size - offset), Offset(offset, rect.height - offset), accentPaint);
    canvas.drawLine(Offset(offset, rect.height - offset), Offset(size + offset, rect.height - offset), accentPaint);

    // Bottom-right
    canvas.drawLine(Offset(rect.width - size - offset, rect.height - offset), Offset(rect.width - offset, rect.height - offset), accentPaint);
    canvas.drawLine(Offset(rect.width - offset, rect.height - size - offset), Offset(rect.width - offset, rect.height - offset), accentPaint);

    // Glow on corners when selected
    if (isSelected) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(offset + 2, offset + 2), 3, glowPaint);
      canvas.drawCircle(Offset(rect.width - offset - 2, offset + 2), 3, glowPaint);
      canvas.drawCircle(Offset(offset + 2, rect.height - offset - 2), 3, glowPaint);
      canvas.drawCircle(Offset(rect.width - offset - 2, rect.height - offset - 2), 3, glowPaint);
    }
  }

  void _drawTechDetails(Canvas canvas, Rect rect) {
    final detailPaint = Paint()
      ..color = color.withOpacity(0.2 + _hoverScale * 0.15)
      ..strokeWidth = 1;

    // Small tick marks on sides
    final midY = rect.height / 2;

    // Left side
    canvas.drawLine(Offset(0, midY - 4), Offset(3, midY - 4), detailPaint);
    canvas.drawLine(Offset(0, midY + 4), Offset(3, midY + 4), detailPaint);

    // Right side
    canvas.drawLine(Offset(rect.width - 3, midY - 4), Offset(rect.width, midY - 4), detailPaint);
    canvas.drawLine(Offset(rect.width - 3, midY + 4), Offset(rect.width, midY + 4), detailPaint);

    // Top center notch
    final centerX = rect.width / 2;
    canvas.drawLine(Offset(centerX - 8, 0), Offset(centerX - 4, 3), detailPaint);
    canvas.drawLine(Offset(centerX + 4, 3), Offset(centerX + 8, 0), detailPaint);
  }

  void _drawSelectionEffects(Canvas canvas, Rect rect) {
    // Pulsing side indicators
    final pulseAlpha = reduceFlicker ? 0.55 : 0.5 + math.sin(_time * 4) * 0.3;
    final indicatorPaint = Paint()
      ..color = color.withOpacity(pulseAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Left indicator
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-4, rect.height / 2 - 8, 3, 16),
        const Radius.circular(1.5),
      ),
      indicatorPaint,
    );

    // Right indicator
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.width + 1, rect.height / 2 - 8, 3, 16),
        const Radius.circular(1.5),
      ),
      indicatorPaint,
    );

    // Bottom highlight bar
    final barWidth = reduceFlicker ? 40.0 : 40 + math.sin(_time * 3) * 5;
    final barGradient = LinearGradient(
      colors: [
        Colors.transparent,
        color.withOpacity(0.4),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(rect.width / 2 - barWidth / 2, rect.height - 3, barWidth, 2));

    canvas.drawRect(
      Rect.fromLTWH(rect.width / 2 - barWidth / 2, rect.height - 3, barWidth, 2),
      Paint()..shader = barGradient,
    );
  }

  void _drawPressEffect(Canvas canvas, Rect rect) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    // Flash overlay
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color.withOpacity(_pressAnimation * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Expanding ring effect
    final ringRadius = 20 + (1 - _pressAnimation) * 30;
    final ringAlpha = _pressAnimation * 0.3;

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawCircle(
      Offset(buttonSize.x / 2, buttonSize.y / 2),
      ringRadius,
      Paint()
        ..color = color.withOpacity(ringAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.restore();
  }

  void _drawLabel(Canvas canvas) {
    // Modern clean text style
    final textColor = isEnabled
        ? (isSelected ? Colors.white : Colors.white.withOpacity(0.9))
        : Colors.white.withOpacity(0.4);

    final fontSize = buttonSize.x < 90 ? 10.0 : 11.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          letterSpacing: 1.2,
          shadows: isSelected
              ? [Shadow(color: color, blurRadius: 8)]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (buttonSize.x - textPainter.width) / 2,
        (buttonSize.y - textPainter.height) / 2,
      ),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isEnabled) return;
    _isPressed = true;
    _pressAnimation = 1.0;
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!isEnabled) return;
    _isPressed = false;
    AudioService.instance.playButton();
    onPressed();
    super.onTapUp(event);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _isPressed = false;
    super.onTapCancel(event);
  }
}
