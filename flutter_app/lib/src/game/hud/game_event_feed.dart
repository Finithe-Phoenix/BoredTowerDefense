import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bored_games_game.dart';

/// Displays game events in a scrolling feed (wave starts, boss spawns, upgrades, etc.)
class GameEventFeed extends PositionComponent with HasGameRef<BoredGamesGame> {
  GameEventFeed() {
    anchor = Anchor.topLeft;
  }

  final List<_GameEvent> _events = [];
  static const int maxEvents = 5;
  static const double eventDuration = 4.0;

  void addEvent(GameEventType type, String message, {Color? color}) {
    _events.insert(
        0,
        _GameEvent(
          type: type,
          message: message,
          color: color ?? _getDefaultColor(type),
        ));

    // Keep only recent events
    if (_events.length > maxEvents) {
      _events.removeLast();
    }
  }

  void waveStarted(int wave) {
    addEvent(GameEventType.waveStart, 'WAVE $wave INCOMING');
  }

  void waveComplete(int wave) {
    addEvent(GameEventType.waveComplete, 'WAVE $wave CLEARED',
        color: const Color(0xFF00FF88));
  }

  void bossSpawned(String bossName) {
    addEvent(GameEventType.bossSpawn, 'BOSS: $bossName',
        color: const Color(0xFFFF00FF));
  }

  void bossDefeated(String bossName) {
    addEvent(GameEventType.bossDefeat, '$bossName DESTROYED',
        color: const Color(0xFFFFD700));
  }

  void towerBuilt(String towerName) {
    addEvent(GameEventType.towerBuilt, '$towerName DEPLOYED',
        color: const Color(0xFF00FFFF));
  }

  void abilityUsed(String abilityName) {
    addEvent(GameEventType.ability, '$abilityName ACTIVATED',
        color: const Color(0xFFFF6600));
  }

  void goldEarned(int amount) {
    if (amount >= 50) {
      addEvent(GameEventType.gold, '+$amount GOLD',
          color: const Color(0xFFFFD700));
    }
  }

  void lowHealth() {
    addEvent(GameEventType.warning, 'LOW HEALTH WARNING',
        color: const Color(0xFFFF4444));
  }

  void timerExpired() {
    addEvent(GameEventType.warning, 'TIME EXPIRED',
        color: const Color(0xFFFF0066));
  }

  Color _getDefaultColor(GameEventType type) {
    switch (type) {
      case GameEventType.waveStart:
        return const Color(0xFFFF00FF);
      case GameEventType.waveComplete:
        return const Color(0xFF00FF88);
      case GameEventType.bossSpawn:
        return const Color(0xFFFF0066);
      case GameEventType.bossDefeat:
        return const Color(0xFFFFD700);
      case GameEventType.towerBuilt:
        return const Color(0xFF00FFFF);
      case GameEventType.ability:
        return const Color(0xFFFF6600);
      case GameEventType.gold:
        return const Color(0xFFFFD700);
      case GameEventType.warning:
        return const Color(0xFFFF4444);
      case GameEventType.info:
        return const Color(0xFFFFFFFF);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update events with single-pass removal
    int eventWriteIdx = 0;
    for (int i = 0; i < _events.length; i++) {
      final event = _events[i];
      event.update(dt);
      if (!event.isExpired) {
        if (eventWriteIdx != i) _events[eventWriteIdx] = event;
        eventWriteIdx++;
      }
    }
    if (eventWriteIdx < _events.length) {
      _events.removeRange(eventWriteIdx, _events.length);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (gameRef.hideHud || gameRef.focusModeActive) return;
    if (_events.isEmpty) return;

    final screenWidth = gameRef.size.x;
    final compact = gameRef.isTouchLayout || screenWidth < 820;

    // Position: left side, below the top bar
    final x = compact ? 8.0 : 16.0;
    final startY = 80.0;

    var offsetY = 0.0;
    final count = _events.length < maxEvents ? _events.length : maxEvents;
    for (int i = 0; i < count; i++) {
      final event = _events[i];
      event.render(canvas, x, startY + offsetY, compact);
      offsetY += event.height + 4;
    }
  }
}

enum GameEventType {
  waveStart,
  waveComplete,
  bossSpawn,
  bossDefeat,
  towerBuilt,
  ability,
  gold,
  warning,
  info,
}

class _GameEvent {
  _GameEvent({
    required this.type,
    required this.message,
    required this.color,
  });

  final GameEventType type;
  final String message;
  final Color color;

  double _lifetime = 0;
  double _pulsePhase = 0;

  static const double duration = 4.0;
  static const double fadeStart = 3.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _iconBgPaint = Paint();
  static final Paint _iconPaint = Paint()
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _pulseRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final TextPainter _textPainter =
      TextPainter(textDirection: TextDirection.ltr);
  String _cachedText = '';
  int _cachedTextColorValue = 0;
  int _cachedShadowColorValue = 0;
  int _cachedShadowDarkValue = 0;
  double _cachedFontSize = 0;
  double _cachedAlpha = -1;
  double get height => 22.0;

  bool get isExpired => _lifetime >= duration;

  void update(double dt) {
    _lifetime += dt;
    _pulsePhase += dt * 8;
  }

  void render(Canvas canvas, double x, double y, bool compact) {
    // Calculate alpha based on lifetime
    double alpha = 1.0;
    if (_lifetime < 0.3) {
      // Fade in
      alpha = _lifetime / 0.3;
    } else if (_lifetime > fadeStart) {
      // Fade out
      alpha = 1.0 - ((_lifetime - fadeStart) / (duration - fadeStart));
    }

    if (alpha <= 0) return;

    // Slide in effect
    final slideX = _lifetime < 0.3 ? -30 * (1 - _lifetime / 0.3) : 0.0;

    final iconSize = 16.0;
    final fontSize = compact ? 10.0 : 11.0;

    // Icon based on type
    _iconPaint.color = color.withOpacity(alpha);

    canvas.save();
    canvas.translate(x + slideX, y);

    // Icon background
    _iconBgPaint.color = color.withOpacity(0.2 * alpha);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, iconSize, iconSize),
        const Radius.circular(3),
      ),
      _iconBgPaint,
    );

    // Icon symbol
    _drawIcon(canvas, type, iconSize, color.withOpacity(alpha));

    // Message text
    final textColor = Colors.white.withOpacity(0.9 * alpha);
    final shadowColor = color.withOpacity(0.5 * alpha);
    final shadowDark = Colors.black.withOpacity(0.8 * alpha);
    if (_cachedText != message ||
        _cachedTextColorValue != textColor.value ||
        _cachedShadowColorValue != shadowColor.value ||
        _cachedShadowDarkValue != shadowDark.value ||
        _cachedFontSize != fontSize ||
        _cachedAlpha != alpha) {
      _cachedText = message;
      _cachedTextColorValue = textColor.value;
      _cachedShadowColorValue = shadowColor.value;
      _cachedShadowDarkValue = shadowDark.value;
      _cachedFontSize = fontSize;
      _cachedAlpha = alpha;
      _textPainter.text = TextSpan(
        text: message,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          shadows: [
            Shadow(color: shadowColor, blurRadius: 6),
            Shadow(color: shadowDark, blurRadius: 4),
          ],
        ),
      );
      _textPainter.layout();
    }

    _textPainter.paint(
        canvas, Offset(iconSize + 8, (iconSize - _textPainter.height) / 2));

    // Pulsing accent for important events
    if (type == GameEventType.bossSpawn || type == GameEventType.warning) {
      final pulse = 0.5 + math.sin(_pulsePhase) * 0.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-2, -2, iconSize + 4, iconSize + 4),
          const Radius.circular(5),
        ),
        _pulseRingPaint
          ..color = color.withOpacity(0.3 * pulse * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    canvas.restore();
  }

  void _drawIcon(Canvas canvas, GameEventType type, double size, Color color) {
    final centerX = size / 2;
    final centerY = size / 2;
    _iconPaint
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (type) {
      case GameEventType.waveStart:
        // Wave icon (three horizontal lines)
        for (int i = 0; i < 3; i++) {
          final y = 4.0 + i * 4;
          canvas.drawLine(Offset(3, y), Offset(size - 3, y), _iconPaint);
        }
        break;

      case GameEventType.waveComplete:
        // Checkmark
        _iconPaint.strokeWidth = 2;
        canvas.drawLine(
            Offset(3, centerY), Offset(centerX - 1, size - 4), _iconPaint);
        _iconPaint.strokeWidth = 1.5;
        canvas.drawLine(
            Offset(centerX - 1, size - 4), Offset(size - 3, 4), _iconPaint);
        break;

      case GameEventType.bossSpawn:
      case GameEventType.bossDefeat:
        // Skull/danger icon
        canvas.drawCircle(Offset(centerX, centerY - 1), 5, _iconPaint);
        canvas.drawLine(
            Offset(3, size - 3), Offset(size - 3, size - 3), _iconPaint);
        break;

      case GameEventType.towerBuilt:
        // Tower icon (triangle pointing up)
        canvas.drawLine(Offset(centerX, 2), Offset(2, size - 2), _iconPaint);
        canvas.drawLine(
            Offset(2, size - 2), Offset(size - 2, size - 2), _iconPaint);
        canvas.drawLine(
            Offset(size - 2, size - 2), Offset(centerX, 2), _iconPaint);
        break;

      case GameEventType.ability:
        // Lightning bolt
        _iconPaint.strokeWidth = 2;
        canvas.drawLine(
            Offset(centerX + 2, 2), Offset(centerX - 2, centerY), _iconPaint);
        _iconPaint.strokeWidth = 1.5;
        canvas.drawLine(Offset(centerX - 2, centerY),
            Offset(centerX + 2, centerY), _iconPaint);
        canvas.drawLine(Offset(centerX + 2, centerY),
            Offset(centerX - 2, size - 2), _iconPaint);
        break;

      case GameEventType.gold:
        // Coin icon
        canvas.drawCircle(Offset(centerX, centerY), 5, _iconPaint);
        _iconPaint.strokeWidth = 1.5;
        canvas.drawLine(Offset(centerX, centerY - 3),
            Offset(centerX, centerY + 3), _iconPaint);
        break;

      case GameEventType.warning:
        // Exclamation mark
        _iconPaint.strokeWidth = 2;
        canvas.drawLine(
            Offset(centerX, 3), Offset(centerX, size - 6), _iconPaint);
        _iconPaint.strokeWidth = 1.5;
        canvas.drawCircle(Offset(centerX, size - 3), 1.5, _iconPaint);
        break;

      case GameEventType.info:
        // Info icon
        canvas.drawCircle(Offset(centerX, centerY), 5, _iconPaint);
        _iconPaint.strokeWidth = 2;
        canvas.drawLine(
            Offset(centerX, centerY), Offset(centerX, size - 4), _iconPaint);
        _iconPaint.strokeWidth = 1.5;
        canvas.drawCircle(Offset(centerX, 4), 1.5, _iconPaint);
        break;
    }
  }
}
