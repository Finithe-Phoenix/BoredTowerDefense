import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bored_games_game.dart';
import '../../ui/theme/neon_theme.dart';

class TutorialGuide extends PositionComponent with HasGameRef<BoredGamesGame> {
  TutorialGuide() {
    anchor = Anchor.topCenter;
  }

  static const List<String> _touchMessages = [
    'Toca una torre para armarla.',
    'Arrastra a una casilla verde para colocar.',
    'Las olas inician solas tras tu primera torre.',
    'Toca PULSE o MINE y luego el campo para activar.',
    'Toca una torre 5x para Focus Mode y toca un enemigo.',
    'Toca SELL para recuperar 20% del oro.',
  ];

  static const List<String> _desktopMessages = [
    'Selecciona una torre para armarla.',
    'Arrastra a una casilla verde para colocar.',
    'Las olas inician solas tras tu primera torre.',
    'Presiona SPACE/M o toca Pulse/Mine y luego el campo.',
    'Clic 5x en una torre para Focus Mode y selecciona objetivo.',
    'Usa SELL para recuperar 20% del oro.',
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

  void _advance() {
    _stepTimer = 0;
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
    if (gameRef.hideHud) return; // Hide in benchmark mode

    final width = math.min(360.0, gameRef.size.x - 32);
    final textPainter = TextPainter(
      text: TextSpan(
        text: _activeMessages[_step],
        style: NeonTextStyles.body.copyWith(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 32);
    final height = math.max(56.0, textPainter.height + 20);
    final x = (gameRef.size.x - width) / 2;
    final y = 32.0;
    final rect = Rect.fromLTWH(x, y, width, height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.black.withOpacity(0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = NeonColors.cyan.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    textPainter.paint(canvas, Offset(x + 16, y + (height - textPainter.height) / 2));
  }
}

