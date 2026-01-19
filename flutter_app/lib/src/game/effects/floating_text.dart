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

/// Floating text that rises and fades out - simplified version
class FloatingText extends PositionComponent {
  FloatingText._internal({
    required Vector2 position,
    required String text,
    FloatingTextType type = FloatingTextType.damage,
    Color? customColor,
    double fontSize = 12,
    double duration = 0.6,
    double riseSpeed = 35,
  }) : _random = math.Random() {
    _reset(
      position: position,
      text: text,
      type: type,
      customColor: customColor,
      fontSize: fontSize,
      duration: duration,
      riseSpeed: riseSpeed,
    );
  }

  factory FloatingText({
    required Vector2 position,
    required String text,
    FloatingTextType type = FloatingTextType.damage,
    Color? customColor,
    double fontSize = 12,
    double duration = 0.6,
    double riseSpeed = 35,
  }) {
    if (_pool.isNotEmpty) {
      final instance = _pool.removeLast();
      instance._reset(
        position: position,
        text: text,
        type: type,
        customColor: customColor,
        fontSize: fontSize,
        duration: duration,
        riseSpeed: riseSpeed,
      );
      return instance;
    }
    return FloatingText._internal(
      position: position,
      text: text,
      type: type,
      customColor: customColor,
      fontSize: fontSize,
      duration: duration,
      riseSpeed: riseSpeed,
    );
  }

  static const int maxPool = 20;
  static final List<FloatingText> _pool = [];

  /// Clear the static pool to prevent memory accumulation between games
  static void clearPool() {
    // CRITICAL: Dispose all cached TextPainters before clearing pool
    for (final item in _pool) {
      item._cachedPainter?.dispose();
      item._cachedPainter = null;
    }
    _pool.clear();
  }

  String text = '';
  FloatingTextType type = FloatingTextType.damage;
  Color? customColor;
  double fontSize = 12;
  double duration = 0.6;
  double riseSpeed = 35;

  double _timer = 0;
  final math.Random _random;
  late double _wobbleOffset;
  bool _inPool = false;

  // Cached TextPainter to avoid per-frame allocations
  TextPainter? _cachedPainter;
  String _cachedText = '';
  double _cachedFontSize = 0;

  void _reset({
    required Vector2 position,
    required String text,
    required FloatingTextType type,
    required Color? customColor,
    required double fontSize,
    required double duration,
    required double riseSpeed,
  }) {
    this.position = position.clone();
    anchor = Anchor.center;
    this.text = text;
    this.type = type;
    this.customColor = customColor;
    this.fontSize = fontSize;
    this.duration = duration;
    this.riseSpeed = riseSpeed;
    _timer = 0;
    _wobbleOffset = (_random.nextDouble() - 0.5) * 12;
    _inPool = false;
  }

  Color get _color => customColor ?? _getTypeColor();

  Color _getTypeColor() {
    switch (type) {
      case FloatingTextType.damage:
        return const Color(0xFFFF0066);
      case FloatingTextType.gold:
        return const Color(0xFFFFDD00);
      case FloatingTextType.heal:
        return const Color(0xFF00FF88);
      case FloatingTextType.critical:
        return const Color(0xFFFFFFFF);
      case FloatingTextType.levelUp:
        return const Color(0xFF00FFFF);
      case FloatingTextType.combo:
        return const Color(0xFFFF00FF);
    }
  }

  double get _scaleMult {
    switch (type) {
      case FloatingTextType.damage:
        return 1.0;
      case FloatingTextType.gold:
        return 1.0;
      case FloatingTextType.heal:
        return 1.0;
      case FloatingTextType.critical:
        return 1.2;
      case FloatingTextType.levelUp:
        return 1.1;
      case FloatingTextType.combo:
        return 1.1;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (_timer >= duration) {
      _recycle();
      return;
    }

    // Simple rise upward
    position.y -= riseSpeed * dt;
  }

  void _recycle() {
    if (parent != null) {
      removeFromParent();
    }
    if (_inPool) return;

    // CRITICAL: Dispose TextPainter to free native resources
    _cachedPainter?.dispose();
    _cachedPainter = null;
    _cachedText = '';
    _cachedFontSize = 0;

    if (_pool.length < maxPool) {
      _inPool = true;
      _pool.add(this);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = _timer / duration;
    final alpha = (1 - progress).clamp(0.0, 1.0);

    // Simple scale animation
    double scale;
    if (progress < 0.15) {
      scale = progress / 0.15 * 1.1;
    } else {
      scale = 1.1 - progress * 0.2;
    }
    scale *= _scaleMult;

    // Cache TextPainter - only recreate if text changed
    if (_cachedPainter == null || _cachedText != text || _cachedFontSize != fontSize) {
      _cachedText = text;
      _cachedFontSize = fontSize;
      _cachedPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: _color,
            fontSize: fontSize,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    // Apply alpha and scale via canvas transform
    canvas.save();
    canvas.scale(scale, scale);

    // Draw shadow manually (cheaper than TextStyle shadows)
    _cachedPainter!.paint(
      canvas,
      Offset(-_cachedPainter!.width / 2 + 1 / scale, -_cachedPainter!.height / 2 + 1 / scale),
    );

    // Draw main text with alpha
    final paint = Paint()..color = _color.withOpacity(alpha);
    canvas.saveLayer(null, paint);
    _cachedPainter!.paint(
      canvas,
      Offset(-_cachedPainter!.width / 2, -_cachedPainter!.height / 2),
    );
    canvas.restore();

    canvas.restore();
  }
}

/// Resource popup that appears when gaining/losing resources - simplified
class ResourcePopup extends PositionComponent {
  ResourcePopup({
    required Vector2 position,
    required this.amount,
    required this.icon,
    this.isGain = true,
    this.duration = 0.8,
  }) : _timer = 0 {
    this.position = position;
    anchor = Anchor.center;
  }

  final int amount;
  final String icon;
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

    position.y -= 25 * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = _timer / duration;
    final alpha = (1 - progress).clamp(0.0, 1.0);

    // Simple scale
    double scale;
    if (progress < 0.15) {
      scale = progress / 0.15 * 1.1;
    } else {
      scale = 1.1 - progress * 0.15;
    }

    final color = isGain
        ? const Color(0xFF00FF88)
        : const Color(0xFFFF0066);

    final prefix = isGain ? '+' : '-';
    final text = '$prefix$amount';

    // Icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: icon,
        style: TextStyle(
          fontSize: 14 * scale,
          color: Colors.white.withOpacity(alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Amount
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(alpha),
          fontSize: 12 * scale,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final totalWidth = iconPainter.width + 4 + textPainter.width;

    iconPainter.paint(canvas, Offset(-totalWidth / 2, -iconPainter.height / 2));
    textPainter.paint(canvas, Offset(-totalWidth / 2 + iconPainter.width + 4, -textPainter.height / 2));
  }
}

/// Kill streak notification - simplified (mostly unused now, kept for compatibility)
class KillStreakNotification extends PositionComponent {
  KillStreakNotification({
    required Vector2 position,
    required this.streakCount,
    this.duration = 1.0,
  }) : _timer = 0 {
    this.position = position;
    anchor = Anchor.center;
  }

  final int streakCount;
  final double duration;

  double _timer;

  String get _streakText {
    if (streakCount >= 10) return 'UNSTOPPABLE';
    if (streakCount >= 7) return 'RAMPAGE';
    if (streakCount >= 5) return 'SPREE';
    if (streakCount >= 3) return 'TRIPLE';
    return 'DOUBLE';
  }

  Color get _color {
    if (streakCount >= 10) return const Color(0xFFFF00FF);
    if (streakCount >= 7) return const Color(0xFFFF6600);
    if (streakCount >= 5) return const Color(0xFFFFCC00);
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
    final alpha = progress < 0.7 ? 1.0 : (1 - (progress - 0.7) / 0.3);

    // Simple scale
    double scale;
    if (progress < 0.1) {
      scale = progress / 0.1 * 1.1;
    } else {
      scale = 1.1 - progress * 0.1;
    }

    // Minimal pill background
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 80 * scale, height: 22 * scale),
      const Radius.circular(11),
    );

    canvas.drawRRect(
      pillRect,
      Paint()..color = const Color(0xFF0a0a18).withOpacity(alpha * 0.85),
    );

    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = _color.withOpacity(alpha * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: _streakText,
        style: TextStyle(
          color: _color.withOpacity(alpha),
          fontSize: 10 * scale,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }
}
