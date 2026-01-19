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

    for (final notif in _notifications) {
      notif.update(dt);
    }
    _notifications.removeWhere((n) => n.isExpired);
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
    final comboPainter = TextPainter(
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

    comboPainter.paint(
      canvas,
      Offset(x - comboPainter.width / 2, y),
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
        Paint()..color = Colors.white.withOpacity(0.1 * alpha),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - barWidth / 2, barY, barWidth * barProgress, 2),
          const Radius.circular(1),
        ),
        Paint()..color = comboColor.withOpacity(0.6 * alpha),
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

  bool get isExpired => _lifetime >= duration;

  void update(double dt) {
    _lifetime += dt;
  }

  void render(Canvas canvas, double x, double y) {
    final progress = _lifetime / duration;
    final alpha = progress < 0.7 ? 1.0 : (1.0 - (progress - 0.7) / 0.3);
    final slideX = progress * 8;

    final textPainter = TextPainter(
      text: TextSpan(
        text: message,
        style: TextStyle(
          color: color.withOpacity(alpha * 0.9),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillWidth = textPainter.width + 10;
    final pillHeight = 14.0;
    final pillX = x - pillWidth / 2 + slideX;

    // Subtle pill background
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pillX, y - pillHeight / 2, pillWidth, pillHeight),
      const Radius.circular(7),
    );

    canvas.drawRRect(
      pillRect,
      Paint()..color = color.withOpacity(0.12 * alpha),
    );

    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = color.withOpacity(0.4 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    textPainter.paint(
      canvas,
      Offset(pillX + 5, y - textPainter.height / 2),
    );
  }
}
