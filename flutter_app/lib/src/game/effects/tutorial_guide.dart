import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bored_games_game.dart';
import '../../ui/theme/neon_theme.dart';

class TutorialGuide extends PositionComponent with HasGameRef<BoredGamesGame> {
  TutorialGuide() {
    anchor = Anchor.topCenter;
  }

  static const List<String> _messages = [
    'Select a tower type to begin.',
    'Drag onto a green tile to place the tower.',
    'Waves start automatically once you place a tower.',
    'That is it - the Grid is yours!',
  ];

  int _step = 0;
  bool _hidden = false;

  void _advance() {
    if (_step < _messages.length - 1) {
      _step++;
    } else {
      _hidden = true;
    }
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

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_hidden || gameRef.size.y == 0) return;

    const width = 320.0;
    const height = 60.0;
    final x = gameRef.size.x / 2 - width / 2;
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

    final textPainter = TextPainter(
      text: TextSpan(
        text: _messages[_step],
        style: NeonTextStyles.body.copyWith(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 32);

    textPainter.paint(canvas, Offset(x + 16, y + (height - textPainter.height) / 2));
  }
}

