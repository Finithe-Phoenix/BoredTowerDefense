import 'dart:ui';

import 'package:flame/components.dart';

class NeonGridComponent extends PositionComponent {
  NeonGridComponent({
    required this.gridSize,
    required this.lineColor,
    required this.glowColor,
  }) {
    priority = -10; // render behind other components
  }

  final double gridSize;
  final Color lineColor;
  final Color glowColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = parent?.size ?? Vector2.all(0);
    anchor = Anchor.topLeft;
    position = Vector2.zero();
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.isZero()) return;

    final Paint glow = Paint()
      ..color = glowColor
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final Paint line = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5;

    // Draw vertical lines
    for (double x = 0; x <= size.x; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), glow);
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), line);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.y; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), glow);
      canvas.drawLine(Offset(0, y), Offset(size.x, y), line);
    }
  }
}
