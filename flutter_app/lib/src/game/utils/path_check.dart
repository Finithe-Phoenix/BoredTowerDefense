import 'dart:collection';
import 'dart:math';

/// Simple BFS on grid to ensure start can reach end without passing through blocked cells.
bool isPathOpen({
  required List<List<bool>> buildableMask,
  required Point<int> startCell,
  required Point<int> endCell,
}) {
  final int rows = buildableMask.length;
  if (rows == 0) return false;
  final int cols = buildableMask[0].length;

  bool inside(Point<int> p) =>
      p.x >= 0 && p.x < cols && p.y >= 0 && p.y < rows;

  final visited = List.generate(rows, (_) => List<bool>.filled(cols, false));
  final queue = Queue<Point<int>>();

  queue.add(startCell);
  visited[startCell.y][startCell.x] = true;

  const directions = [
    Point<int>(1, 0),
    Point<int>(-1, 0),
    Point<int>(0, 1),
    Point<int>(0, -1),
  ];

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    if (current == endCell) return true;

    for (final dir in directions) {
      final next = Point<int>(current.x + dir.x, current.y + dir.y);
      if (!inside(next)) continue;
      if (visited[next.y][next.x]) continue;
      if (!buildableMask[next.y][next.x]) continue;
      visited[next.y][next.x] = true;
      queue.add(next);
    }
  }
  return false;
}
