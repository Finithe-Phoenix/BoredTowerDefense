import 'dart:math';

import 'package:flame/components.dart';

Point<int> screenToGrid(Vector2 position, double tileSize) {
  final gx = (position.x / tileSize).floor();
  final gy = (position.y / tileSize).floor();
  return Point<int>(gx, gy);
}

Vector2 gridToWorld(Point<int> cell, double tileSize) {
  return Vector2(cell.x * tileSize.toDouble(), cell.y * tileSize.toDouble());
}
