import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bored_games_game.dart';
import '../../ui/theme/neon_theme.dart';

class TutorialGuide extends PositionComponent with HasGameRef<BoredGamesGame> {
  TutorialGuide() {
    anchor = Anchor.topCenter;
  }

  // Icons for each step (using unicode symbols)
  static const List<String> _stepIcons = ['◆', '▶', '⚡', '✦', '⊕', '◈'];

  static const List<String> _touchMessages = [
    'Toca una torre para armarla',
    'Arrastra a una casilla verde',
    'Las olas inician automáticamente',
    'Activa PULSE o MINE en el campo',
    'Toca 5x una torre para Focus Mode',
    'Usa SELL para recuperar oro',
  ];

  static const List<String> _desktopMessages = [
    'Selecciona una torre para armarla',
    'Arrastra a una casilla verde',
    'Las olas inician automáticamente',
    'Presiona SPACE/M para habilidades',
    'Clic 5x en torre para Focus Mode',
    'Usa SELL para recuperar oro',
  ];

  static const List<double> _autoAdvanceDelays = [
    0,
    0,
    0,
    7.0,
    7.0,
    6.0,
  ];

  int _step = 0;
  bool _hidden = false;
  double _stepTimer = 0;
  double _animTime = 0;
  double _fadeIn = 0;

  void _advance() {
    _stepTimer = 0;
    _fadeIn = 0;
    if (_step < _activeMessages.length - 1) {
      _step++;
    } else {
      _hidden = true;
    }
  }

  List<String> get _activeMessages {
    return gameRef.isTouchLayout ? _touchMessages : _desktopMessages;
  }

  void onTowerSelected() {
    if (_step == 0) _advance();
  }

  void onTowerPlaced() {
    if (_step == 1) _advance();
  }

  void onWaveStarted() {
    if (_step == 2) _advance();
  }

  void onAbilityUsed() {
    if (_step == 3) _advance();
  }

  void onFocusMode() {
    if (_step == 4) _advance();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;
    _fadeIn = (_fadeIn + dt * 3).clamp(0.0, 1.0);

    if (_hidden) return;
    if (_step < 0 || _step >= _activeMessages.length) {
      _hidden = true;
      return;
    }
    final delay = _autoAdvanceDelays[_step];
    if (delay <= 0) return;
    _stepTimer += dt;
    if (_stepTimer >= delay) {
      _advance();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_hidden || gameRef.size.y == 0) return;
    if (gameRef.hideHud) return;

    final screenWidth = gameRef.size.x;
    final opacity = _fadeIn;

    // Determine accent color based on step
    final accentColor = _getStepColor(_step);

    // Calculate dimensions
    final message = _activeMessages[_step];
    final icon = _stepIcons[_step];

    final textPainter = TextPainter(
      text: TextSpan(
        text: message,
        style: TextStyle(
          color: Colors.white.withOpacity(0.95 * opacity),
          fontSize: 12,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final iconPainter = TextPainter(
      text: TextSpan(
        text: icon,
        style: TextStyle(
          color: accentColor.withOpacity(opacity),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: accentColor.withOpacity(0.8 * opacity), blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Minimal pill design - positioned below wave indicator
    final contentWidth = iconPainter.width + 10 + textPainter.width;
    final pillWidth = contentWidth + 28;
    final pillHeight = 32.0;
    final x = (screenWidth - pillWidth) / 2;
    final y = 115.0; // Below wave indicator

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, pillWidth, pillHeight),
      const Radius.circular(16),
    );

    // Background with gradient
    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF0a0a18).withOpacity(0.92 * opacity),
        const Color(0xFF0f0f1a).withOpacity(0.88 * opacity),
      ],
    ).createShader(pillRect.outerRect);

    canvas.drawRRect(pillRect, Paint()..shader = bgGradient);

    // Animated border glow
    final pulseIntensity = 0.3 + math.sin(_animTime * 2) * 0.15;
    canvas.drawRRect(
      pillRect.inflate(2),
      Paint()
        ..color = accentColor.withOpacity(pulseIntensity * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Border
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = accentColor.withOpacity(0.5 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Left accent line
    final accentLineY = y + pillHeight / 2;
    canvas.drawLine(
      Offset(x + 8, accentLineY - 6),
      Offset(x + 8, accentLineY + 6),
      Paint()
        ..color = accentColor.withOpacity(0.8 * opacity)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Icon
    iconPainter.paint(canvas, Offset(x + 16, y + (pillHeight - iconPainter.height) / 2));

    // Text
    textPainter.paint(
      canvas,
      Offset(x + 16 + iconPainter.width + 10, y + (pillHeight - textPainter.height) / 2),
    );

    // Step indicator dots
    _drawStepDots(canvas, screenWidth, y + pillHeight + 8, opacity, accentColor);
  }

  void _drawStepDots(Canvas canvas, double screenWidth, double y, double opacity, Color activeColor) {
    final totalSteps = _activeMessages.length;
    const dotSize = 4.0;
    const dotSpacing = 10.0;
    final totalWidth = totalSteps * dotSize + (totalSteps - 1) * (dotSpacing - dotSize);
    final startX = (screenWidth - totalWidth) / 2;

    for (int i = 0; i < totalSteps; i++) {
      final isActive = i == _step;
      final isPast = i < _step;
      final dotX = startX + i * dotSpacing;

      if (isActive) {
        // Active dot with glow
        canvas.drawCircle(
          Offset(dotX, y),
          dotSize + 1,
          Paint()
            ..color = activeColor.withOpacity(0.4 * opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(dotX, y),
          dotSize,
          Paint()..color = activeColor.withOpacity(opacity),
        );
      } else if (isPast) {
        // Completed dot
        canvas.drawCircle(
          Offset(dotX, y),
          dotSize * 0.7,
          Paint()..color = activeColor.withOpacity(0.5 * opacity),
        );
      } else {
        // Future dot
        canvas.drawCircle(
          Offset(dotX, y),
          dotSize * 0.5,
          Paint()..color = Colors.white.withOpacity(0.2 * opacity),
        );
      }
    }
  }

  Color _getStepColor(int step) {
    switch (step) {
      case 0: return const Color(0xFF00FFFF); // Cyan - tower selection
      case 1: return const Color(0xFF00FF88); // Green - placement
      case 2: return const Color(0xFFFF00FF); // Magenta - waves
      case 3: return const Color(0xFFFFAA00); // Orange - abilities
      case 4: return const Color(0xFF00FFFF); // Cyan - focus mode
      case 5: return const Color(0xFFFFD700); // Gold - sell
      default: return NeonColors.cyan;
    }
  }
}

