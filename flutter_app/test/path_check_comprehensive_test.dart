import 'dart:collection';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// Tests for path_check BFS pathfinding utilities

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED FUNCTION FROM path_check.dart
// ═══════════════════════════════════════════════════════════════════════════════

/// Simple BFS on grid to ensure start can reach end without passing through blocked cells.
/// Returns true if path exists from startCell to endCell.
/// buildableMask: true = passable, false = blocked
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

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════

/// Create a grid of given dimensions, all passable
List<List<bool>> createOpenGrid(int rows, int cols) {
  return List.generate(rows, (_) => List<bool>.filled(cols, true));
}

/// Create a grid of given dimensions, all blocked
List<List<bool>> createBlockedGrid(int rows, int cols) {
  return List.generate(rows, (_) => List<bool>.filled(cols, false));
}

/// Print grid for debugging (optional)
void printGrid(List<List<bool>> grid, Point<int>? start, Point<int>? end) {
  for (int y = 0; y < grid.length; y++) {
    String row = '';
    for (int x = 0; x < grid[0].length; x++) {
      if (start != null && start.x == x && start.y == y) {
        row += 'S';
      } else if (end != null && end.x == x && end.y == y) {
        row += 'E';
      } else {
        row += grid[y][x] ? '.' : '#';
      }
    }
    // print(row);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('Basic Path Finding', () {
    test('direct horizontal path', () {
      final grid = createOpenGrid(3, 5);
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 1),
        endCell: const Point(4, 1),
      );
      expect(result, true);
    });

    test('direct vertical path', () {
      final grid = createOpenGrid(5, 3);
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(1, 0),
        endCell: const Point(1, 4),
      );
      expect(result, true);
    });

    test('diagonal path (L-shaped)', () {
      final grid = createOpenGrid(5, 5);
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(4, 4),
      );
      expect(result, true);
    });

    test('start equals end', () {
      final grid = createOpenGrid(3, 3);
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(1, 1),
        endCell: const Point(1, 1),
      );
      expect(result, true);
    });
  });

  group('No Path Scenarios', () {
    test('completely blocked grid', () {
      final grid = createBlockedGrid(5, 5);
      // Need to unblock start at least
      grid[0][0] = true;

      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(4, 4),
      );
      expect(result, false);
    });

    test('wall blocking path', () {
      // Create a vertical wall blocking left from right
      final grid = createOpenGrid(5, 5);
      for (int y = 0; y < 5; y++) {
        grid[y][2] = false; // wall at column 2
      }

      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 2),
        endCell: const Point(4, 2),
      );
      expect(result, false);
    });

    test('isolated island', () {
      // End is surrounded by walls
      final grid = createOpenGrid(5, 5);
      grid[1][1] = false;
      grid[1][2] = false;
      grid[1][3] = false;
      grid[2][1] = false;
      grid[2][3] = false;
      grid[3][1] = false;
      grid[3][2] = false;
      grid[3][3] = false;

      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(2, 2),
      );
      expect(result, false);
    });
  });

  group('Empty Grid Cases', () {
    test('empty grid returns false', () {
      final result = isPathOpen(
        buildableMask: [],
        startCell: const Point(0, 0),
        endCell: const Point(0, 0),
      );
      expect(result, false);
    });
  });

  group('Maze-like Paths', () {
    test('simple maze with solution', () {
      // S . . # .
      // # # . # .
      // . . . # .
      // . # # # .
      // . . . . E
      final grid = [
        [true, true, true, false, true],
        [false, false, true, false, true],
        [true, true, true, false, true],
        [true, false, false, false, true],
        [true, true, true, true, true],
      ];

      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(4, 4),
      );
      expect(result, true);
    });

    test('snake path', () {
      // S . . . .
      // # # # # .
      // . . . . .
      // . # # # #
      // . . . . E
      final grid = [
        [true, true, true, true, true],
        [false, false, false, false, true],
        [true, true, true, true, true],
        [true, false, false, false, false],
        [true, true, true, true, true],
      ];

      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(4, 4),
      );
      expect(result, true);
    });

    test('no path through maze', () {
      // S . # . .
      // # . # . .
      // # . # . E
      // # . # . .
      // # . # . .
      final grid = [
        [true, true, false, true, true],
        [false, true, false, true, true],
        [false, true, false, true, true],
        [false, true, false, true, true],
        [false, true, false, true, true],
      ];

      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(4, 2),
      );
      expect(result, false);
    });
  });

  group('Direction Tests', () {
    test('path going right', () {
      final grid = createOpenGrid(3, 5);
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 1),
        endCell: const Point(4, 1),
      );
      expect(result, true);
    });

    test('path going left', () {
      final grid = createOpenGrid(3, 5);
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(4, 1),
        endCell: const Point(0, 1),
      );
      expect(result, true);
    });

    test('path going down', () {
      final grid = createOpenGrid(5, 3);
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(1, 0),
        endCell: const Point(1, 4),
      );
      expect(result, true);
    });

    test('path going up', () {
      final grid = createOpenGrid(5, 3);
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(1, 4),
        endCell: const Point(1, 0),
      );
      expect(result, true);
    });
  });

  group('Corner Cases', () {
    test('1x1 grid, same start and end', () {
      final grid = [[true]];
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(0, 0),
      );
      expect(result, true);
    });

    test('1x1 grid blocked', () {
      final grid = [[false]];
      // Note: In real usage, start cell should be passable
      // but algorithm marks start as visited regardless
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(0, 0),
      );
      expect(result, true); // Start equals end, found immediately
    });

    test('2x2 grid corners', () {
      final grid = [[true, true], [true, true]];
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(1, 1),
      );
      expect(result, true);
    });

    test('path along edges', () {
      // Path must go around edge
      final grid = [
        [true, true, true],
        [true, false, true],
        [true, true, true],
      ];
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(2, 2),
      );
      expect(result, true);
    });
  });

  group('Large Grid Performance', () {
    test('large open grid', () {
      final grid = createOpenGrid(50, 50);
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(49, 49),
      );
      expect(result, true);
    });

    test('large grid with obstacles', () {
      final grid = createOpenGrid(20, 20);
      // Add some obstacles but keep path
      for (int i = 0; i < 15; i++) {
        grid[10][i] = false;
      }

      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(19, 19),
      );
      expect(result, true);
    });
  });

  group('Narrow Passage Tests', () {
    test('single cell wide passage', () {
      final grid = [
        [true, true, true, true, true],
        [false, false, true, false, false],
        [true, true, true, true, true],
      ];
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(4, 2),
      );
      expect(result, true);
    });

    test('blocked narrow passage', () {
      final grid = [
        [true, true, true, true, true],
        [false, false, false, false, false],
        [true, true, true, true, true],
      ];
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(4, 2),
      );
      expect(result, false);
    });
  });

  group('Tower Defense Scenarios', () {
    test('enemy spawn to base - open path', () {
      // Typical TD map where enemies go from left to right
      final grid = createOpenGrid(5, 10);
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 2), // spawn
        endCell: const Point(9, 2),   // base
      );
      expect(result, true);
    });

    test('placing tower blocks the only path', () {
      // Narrow corridor
      final grid = [
        [false, false, false, false, false],
        [true, true, true, true, true],
        [false, false, false, false, false],
      ];

      // Initial path exists
      expect(
        isPathOpen(
          buildableMask: grid,
          startCell: const Point(0, 1),
          endCell: const Point(4, 1),
        ),
        true,
      );

      // Block middle
      grid[1][2] = false;

      // Path now blocked
      expect(
        isPathOpen(
          buildableMask: grid,
          startCell: const Point(0, 1),
          endCell: const Point(4, 1),
        ),
        false,
      );
    });

    test('alternative path after blocking', () {
      // Two possible paths
      final grid = [
        [true, true, true, true, true],
        [true, false, false, false, true],
        [true, true, true, true, true],
      ];

      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(4, 2),
      );
      expect(result, true);
    });

    test('validate tower placement leaves path', () {
      final grid = createOpenGrid(5, 5);
      final spawn = const Point(0, 2);
      final base = const Point(4, 2);

      // Try to place tower
      final proposedTowerPos = const Point(2, 2);

      // Temporarily block
      grid[proposedTowerPos.y][proposedTowerPos.x] = false;

      final pathStillExists = isPathOpen(
        buildableMask: grid,
        startCell: spawn,
        endCell: base,
      );

      // In this case, path still exists going around
      expect(pathStillExists, true);
    });
  });

  group('Non-rectangular considerations', () {
    test('rectangular grid (more columns than rows)', () {
      final grid = createOpenGrid(3, 10);
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 1),
        endCell: const Point(9, 1),
      );
      expect(result, true);
    });

    test('rectangular grid (more rows than columns)', () {
      final grid = createOpenGrid(10, 3);
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(1, 0),
        endCell: const Point(1, 9),
      );
      expect(result, true);
    });
  });

  group('BFS Property Tests', () {
    test('BFS finds path if any exists', () {
      // Complex maze with exactly one path
      final grid = [
        [true, false, true, true, true],
        [true, false, true, false, true],
        [true, true, true, false, true],
        [false, false, false, false, true],
        [true, true, true, true, true],
      ];

      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(4, 4),
      );
      expect(result, true);
    });

    test('BFS handles multiple possible paths', () {
      // Grid with multiple paths - BFS should find any
      final grid = createOpenGrid(5, 5);
      grid[1][2] = false; // add obstacle that doesn't block all paths

      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(4, 4),
      );
      expect(result, true);
    });
  });

  group('Adjacent Cell Tests', () {
    test('start adjacent to end - horizontal', () {
      final grid = createOpenGrid(3, 3);
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 1),
        endCell: const Point(1, 1),
      );
      expect(result, true);
    });

    test('start adjacent to end - vertical', () {
      final grid = createOpenGrid(3, 3);
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(1, 0),
        endCell: const Point(1, 1),
      );
      expect(result, true);
    });

    test('no diagonal movement', () {
      // Only diagonal neighbor, but algorithm uses 4-directional movement
      final grid = [
        [true, false],
        [false, true],
      ];
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(1, 1),
      );
      expect(result, false);
    });
  });

  group('Passability Semantics', () {
    test('true means passable', () {
      final grid = [[true, true], [true, true]];
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(1, 1),
      );
      expect(result, true);
    });

    test('false means blocked', () {
      final grid = [[true, false], [false, true]];
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 0),
        endCell: const Point(1, 1),
      );
      expect(result, false);
    });
  });

  group('Full Blockade Patterns', () {
    test('horizontal wall', () {
      final grid = [
        [true, true, true, true, true],
        [true, true, true, true, true],
        [false, false, false, false, false],
        [true, true, true, true, true],
        [true, true, true, true, true],
      ];
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(2, 0),
        endCell: const Point(2, 4),
      );
      expect(result, false);
    });

    test('vertical wall', () {
      final grid = [
        [true, true, false, true, true],
        [true, true, false, true, true],
        [true, true, false, true, true],
        [true, true, false, true, true],
        [true, true, false, true, true],
      ];
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(0, 2),
        endCell: const Point(4, 2),
      );
      expect(result, false);
    });

    test('box enclosure', () {
      final grid = [
        [true, true, true, true, true],
        [true, false, false, false, true],
        [true, false, true, false, true],
        [true, false, false, false, true],
        [true, true, true, true, true],
      ];
      // Start inside the box
      final result = isPathOpen(
        buildableMask: grid,
        startCell: const Point(2, 2),
        endCell: const Point(0, 0),
      );
      expect(result, false);
    });
  });
}
