import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../entities/enemy.dart';

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

/// Types of floating text
enum FloatingTextType {
  damage,
  gold,
  heal,
  critical,
  levelUp,
  combo,
}

bool _isScreenOffscreen(Vector2 pos, {double padding = 40}) {
  if (Enemy.screenSize.isZero()) return false;
  return pos.x < -padding ||
      pos.y < -padding ||
      pos.x > Enemy.screenSize.x + padding ||
      pos.y > Enemy.screenSize.y + padding;
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
  }) : _random = _FastRng() {
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
  final _FastRng _random;
  late double _wobbleOffset;
  bool _inPool = false;

  // Cached TextPainter to avoid per-frame allocations
  TextPainter? _cachedPainter;
  String _cachedText = '';
  double _cachedFontSize = 0;
  double _cachedTextWidth = 0;
  double _cachedTextHeight = 0;
  Rect? _cachedTextLayerRect;

  // Static cached Paint for render - avoids per-frame allocations
  static final Paint _renderPaint = Paint();

  void _reset({
    required Vector2 position,
    required String text,
    required FloatingTextType type,
    required Color? customColor,
    required double fontSize,
    required double duration,
    required double riseSpeed,
  }) {
    this.position.setFrom(position);
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
    _cachedTextWidth = 0;
    _cachedTextHeight = 0;
    _cachedTextLayerRect = null;

    if (_pool.length < maxPool) {
      _inPool = true;
      _pool.add(this);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_isScreenOffscreen(position, padding: 50)) return;
    super.render(canvas);

    final progress = _timer / duration;
    final alpha = (1 - progress).clamp(0.0, 1.0);
    if (alpha <= 0.01) return;

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
      _cachedTextWidth = _cachedPainter!.width;
      _cachedTextHeight = _cachedPainter!.height;
      _cachedTextLayerRect = Rect.fromLTWH(
        -_cachedTextWidth / 2 - 16,
        -_cachedTextHeight / 2 - 16,
        _cachedTextWidth + 32,
        _cachedTextHeight + 32,
      );
    }

    // Apply alpha and scale via canvas transform
    canvas.save();
    canvas.scale(scale, scale);

    if (_cachedTextWidth <= 0 || _cachedTextHeight <= 0) {
      canvas.restore();
      return;
    }

    // Draw shadow manually (cheaper than TextStyle shadows)
    _cachedPainter!.paint(
      canvas,
      Offset(-_cachedTextWidth / 2 + 1 / scale, -_cachedTextHeight / 2 + 1 / scale),
    );

    // Draw main text with alpha - avoid saveLayer when fully opaque
    if (alpha >= 0.99) {
      _cachedPainter!.paint(
        canvas,
        Offset(-_cachedTextWidth / 2, -_cachedTextHeight / 2),
      );
    } else {
      final textOffset = Offset(-_cachedTextWidth / 2, -_cachedTextHeight / 2);
      final textLayerRect = _cachedTextLayerRect!;
      _renderPaint.color = _color.withOpacity(alpha);
      canvas.saveLayer(textLayerRect, _renderPaint);
      _cachedPainter!.paint(canvas, textOffset);
      canvas.restore();
    }

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
    _initPainters();
  }

  final int amount;
  final String icon;
  final bool isGain;
  final double duration;

  double _timer;

  // Cached TextPainters
  TextPainter? _iconPainter;
  TextPainter? _textPainter;
  static final Paint _alphaPaint = Paint();

  void _initPainters() {
    final color = isGain ? const Color(0xFF00FF88) : const Color(0xFFFF0066);
    final prefix = isGain ? '+' : '-';
    final text = '$prefix$amount';

    _iconPainter = TextPainter(
      text: TextSpan(
        text: icon,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (_timer >= duration) {
      _iconPainter?.dispose();
      _textPainter?.dispose();
      removeFromParent();
      return;
    }

    position.y -= 25 * dt;
  }

  @override
  void render(Canvas canvas) {
    if (_isScreenOffscreen(position, padding: 60)) return;
    super.render(canvas);
    if (_iconPainter == null || _textPainter == null) return;

    final progress = _timer / duration;
    final alpha = (1 - progress).clamp(0.0, 1.0);
    if (alpha <= 0.01) return;

    // Simple scale
    double scale;
    if (progress < 0.15) {
      scale = progress / 0.15 * 1.1;
    } else {
      scale = 1.1 - progress * 0.15;
    }

    final totalWidth = _iconPainter!.width + 4 + _textPainter!.width;

    canvas.save();
    canvas.scale(scale, scale);

    if (alpha >= 0.99) {
      _iconPainter!.paint(canvas, Offset(-totalWidth / 2, -_iconPainter!.height / 2));
      _textPainter!.paint(
        canvas,
        Offset(-totalWidth / 2 + _iconPainter!.width + 4, -_textPainter!.height / 2),
      );
    } else {
      // Apply alpha via saveLayer
      final textLayerRect = Rect.fromLTWH(
        -totalWidth / 2 - 12,
        -_textPainter!.height / 2 - 12,
        totalWidth + 24,
        _textPainter!.height + 24,
      );
      _alphaPaint.color = Color.fromRGBO(255, 255, 255, alpha);
      canvas.saveLayer(textLayerRect, _alphaPaint);

      _iconPainter!.paint(canvas, Offset(-totalWidth / 2, -_iconPainter!.height / 2));
      _textPainter!.paint(
        canvas,
        Offset(-totalWidth / 2 + _iconPainter!.width + 4, -_textPainter!.height / 2),
      );

      canvas.restore(); // saveLayer
    }
    canvas.restore(); // scale
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
    _initPainter();
  }

  final int streakCount;
  final double duration;

  double _timer;

  // Cached painters and paints
  TextPainter? _textPainter;
  static final Paint _bgPaint = Paint();
  static final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _alphaPaint = Paint();

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

  void _initPainter() {
    _textPainter = TextPainter(
      text: TextSpan(
        text: _streakText,
        style: TextStyle(
          color: _color,
          fontSize: 10,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (_timer >= duration) {
      _textPainter?.dispose();
      removeFromParent();
      return;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_isScreenOffscreen(position, padding: 80)) return;
    super.render(canvas);
    if (_textPainter == null) return;

    final progress = _timer / duration;
    final alpha = progress < 0.7 ? 1.0 : (1 - (progress - 0.7) / 0.3);
    if (alpha <= 0.01) return;

    // Simple scale
    double scale;
    if (progress < 0.1) {
      scale = progress / 0.1 * 1.1;
    } else {
      scale = 1.1 - progress * 0.1;
    }

    canvas.save();
    canvas.scale(scale, scale);

    // Minimal pill background
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 80, height: 22),
      const Radius.circular(11),
    );

    _bgPaint.color = const Color(0xFF0a0a18).withOpacity(alpha * 0.85);
    canvas.drawRRect(pillRect, _bgPaint);

    _borderPaint.color = _color.withOpacity(alpha * 0.5);
    canvas.drawRRect(pillRect, _borderPaint);

    // Text with alpha
    final textLayerRect = Rect.fromLTWH(
      -_textPainter!.width / 2 - 12,
      -_textPainter!.height / 2 - 12,
      _textPainter!.width + 24,
      _textPainter!.height + 24,
    );
    _alphaPaint.color = Color.fromRGBO(255, 255, 255, alpha);
    canvas.saveLayer(textLayerRect, _alphaPaint);

    _textPainter!.paint(
      canvas,
      Offset(-_textPainter!.width / 2, -_textPainter!.height / 2),
    );

    canvas.restore(); // saveLayer
    canvas.restore(); // scale
  }
}

