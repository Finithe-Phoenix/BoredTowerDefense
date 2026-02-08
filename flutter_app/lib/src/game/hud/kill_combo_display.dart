import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bored_games_game.dart';

/// Displays kill combos with subtle, elegant animations
class KillComboDisplay extends PositionComponent with HasGameRef<BoredGamesGame> {
  KillComboDisplay() {
    anchor = Anchor.topRight;
  }

  int _currentCombo = 0;
  int _displayedCombo = 0;
  double _comboTimer = 0;
  double _displayTimer = 0;
  double _animTime = 0;

  static const double comboTimeout = 3.0;
  static const double displayDuration = 2.0;

  final List<_KillNotification> _notifications = [];
  static const int _maxNotifications = 2;

  static final Paint _comboBarBgPaint = Paint();
  static final Paint _comboBarFillPaint = Paint();
  TextPainter? _comboPainter;
  String _comboText = '';
  int _comboColorValue = 0;
  double _comboAlpha = -1;

  void registerKill({bool isCritical = false, bool isMultiKill = false}) {
    _currentCombo++;
    _comboTimer = comboTimeout;
    _displayTimer = displayDuration;
    _displayedCombo = _currentCombo;

    // Only show notifications at exact milestone (not >=)
    String message = '';
    Color color = const Color(0xFF00FF88);

    if (_currentCombo == 10) {
      message = 'UNSTOPPABLE';
      color = const Color(0xFFFF00FF);
    } else if (_currentCombo == 7) {
      message = 'RAMPAGE';
      color = const Color(0xFFFF6600);
    } else if (_currentCombo == 5) {
      message = 'SPREE';
      color = const Color(0xFFFFCC00);
    } else if (_currentCombo == 3) {
      message = 'TRIPLE';
      color = const Color(0xFF00FFFF);
    }

    if (message.isNotEmpty) {
      while (_notifications.length >= _maxNotifications) {
        _notifications.removeAt(0);
      }
      _notifications.add(_KillNotification(message, color));
    }
  }

  void reset() {
    _currentCombo = 0;
    _displayedCombo = 0;
    _comboTimer = 0;
    _displayTimer = 0;
    _notifications.clear();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt * 4;

    if (_comboTimer > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) {
        _currentCombo = 0;
      }
    }

    if (_displayTimer > 0) {
      _displayTimer -= dt;
    }

    // Update notifications with single-pass removal
    int notifWriteIdx = 0;
    for (int i = 0; i < _notifications.length; i++) {
      final notif = _notifications[i];
      notif.update(dt);
      if (!notif.isExpired) {
        if (notifWriteIdx != i) _notifications[notifWriteIdx] = notif;
        notifWriteIdx++;
      }
    }
    if (notifWriteIdx < _notifications.length) {
      _notifications.removeRange(notifWriteIdx, _notifications.length);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (gameRef.hideHud) return;
    if (gameRef.focusModeActive) return;

    final screenWidth = gameRef.size.x;

    // Position - right side, below score area
    final baseX = screenWidth - 70;
    final baseY = 95.0;

    // Draw notifications (above combo)
    _renderNotifications(canvas, baseX, baseY - 25);

    // Only show combo counter if >= 2
    if (_displayTimer <= 0 || _displayedCombo < 2) return;

    final alpha = _displayTimer > 0.5 ? 1.0 : (_displayTimer / 0.5);
    if (alpha <= 0) return;

    _renderComboCounter(canvas, baseX, baseY, alpha);
  }

  void _renderNotifications(Canvas canvas, double x, double y) {
    var offsetY = 0.0;
    for (final notif in _notifications.reversed.take(_maxNotifications)) {
      notif.render(canvas, x, y - offsetY);
      offsetY += 20;
    }
  }

  void _renderComboCounter(Canvas canvas, double x, double y, double alpha) {
    final comboColor = _getComboColor(_displayedCombo);

    // Minimal combo display
    final comboText = '${_displayedCombo}x';
    final comboColorValue = comboColor.value;
    if (_comboPainter == null ||
        _comboText != comboText ||
        _comboColorValue != comboColorValue ||
        _comboAlpha != alpha) {
      _comboText = comboText;
      _comboColorValue = comboColorValue;
      _comboAlpha = alpha;
      _comboPainter = TextPainter(
        text: TextSpan(
          text: comboText,
          style: TextStyle(
            color: comboColor.withOpacity(alpha),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 1,
            shadows: [
              Shadow(color: comboColor.withOpacity(0.4 * alpha), blurRadius: 4),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    _comboPainter!.paint(
      canvas,
      Offset(x - _comboPainter!.width / 2, y),
    );

    // Minimal timeout bar
    if (_comboTimer > 0) {
      final barWidth = 36.0;
      final barProgress = _comboTimer / comboTimeout;
      final barY = y + 24;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - barWidth / 2, barY, barWidth, 2),
          const Radius.circular(1),
        ),
        _comboBarBgPaint..color = Colors.white.withOpacity(0.1 * alpha),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - barWidth / 2, barY, barWidth * barProgress, 2),
          const Radius.circular(1),
        ),
        _comboBarFillPaint..color = comboColor.withOpacity(0.6 * alpha),
      );
    }
  }

  Color _getComboColor(int combo) {
    if (combo >= 10) return const Color(0xFFFF00FF);
    if (combo >= 7) return const Color(0xFFFF6600);
    if (combo >= 5) return const Color(0xFFFFCC00);
    if (combo >= 3) return const Color(0xFF00FFFF);
    return const Color(0xFF00FF88);
  }
}

class _KillNotification {
  _KillNotification(this.message, this.color);

  final String message;
  final Color color;
  double _lifetime = 0;
  static const double duration = 1.0;
  static final Paint _pillFillPaint = Paint();
  static final Paint _pillBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final TextPainter _textPainter = TextPainter(textDirection: TextDirection.ltr);
  String _cachedText = '';
  int _cachedColorValue = 0;
  double _cachedAlpha = -1;

  bool get isExpired => _lifetime >= duration;

  void update(double dt) {
    _lifetime += dt;
  }

  void render(Canvas canvas, double x, double y) {
    final progress = _lifetime / duration;
    final alpha = progress < 0.7 ? 1.0 : (1.0 - (progress - 0.7) / 0.3);
    final slideX = progress * 8;

    final textColorValue = color.withOpacity(alpha * 0.9).value;
    if (_cachedText != message ||
        _cachedColorValue != textColorValue ||
        _cachedAlpha != alpha) {
      _cachedText = message;
      _cachedColorValue = textColorValue;
      _cachedAlpha = alpha;
      _textPainter.text = TextSpan(
        text: message,
        style: TextStyle(
          color: color.withOpacity(alpha * 0.9),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 1,
        ),
      );
      _textPainter.layout();
    }

    final pillWidth = _textPainter.width + 10;
    final pillHeight = 14.0;
    final pillX = x - pillWidth / 2 + slideX;

    // Subtle pill background
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pillX, y - pillHeight / 2, pillWidth, pillHeight),
      const Radius.circular(7),
    );

    canvas.drawRRect(
      pillRect,
      _pillFillPaint..color = color.withOpacity(0.12 * alpha),
    );

    canvas.drawRRect(
      pillRect,
      _pillBorderPaint..color = color.withOpacity(0.4 * alpha),
    );

    _textPainter.paint(
      canvas,
      Offset(pillX + 5, y - _textPainter.height / 2),
    );
  }
}
