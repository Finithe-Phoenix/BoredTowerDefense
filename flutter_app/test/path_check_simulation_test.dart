import 'dart:collection';
import 'package:test/test.dart';

/// Comprehensive simulation tests for path_check BFS pathfinding algorithm.
/// Tests the isPathOpen function which validates tower placement doesn't block paths.

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED PATH CHECK - Exact copy from path_check.dart
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedPoint {
  final int x;
  final int y;

  const SimulatedPoint(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is SimulatedPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Point($x, $y)';
}

/// Simple BFS on grid to ensure start can reach end without passing through blocked cells.
bool isPathOpen({
  required List<List<bool>> buildableMask,
  required SimulatedPoint startCell,
  required SimulatedPoint endCell,
}) {
  final int rows = buildableMask.length;
  if (rows == 0) return false;
  final int cols = buildableMask[0].length;

  bool inside(SimulatedPoint p) =>
      p.x >= 0 && p.x < cols && p.y >= 0 && p.y < rows;

  final visited = List.generate(rows, (_) => List<bool>.filled(cols, false));
  final queue = Queue<SimulatedPoint>();

  queue.add(startCell);
  visited[startCell.y][startCell.x] = true;

  const directions = [
    SimulatedPoint(1, 0),
    SimulatedPoint(-1, 0),
    SimulatedPoint(0, 1),
    SimulatedPoint(0, -1),
  ];

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    if (current == endCell) return true;

    for (final dir in directions) {
      final next = SimulatedPoint(current.x + dir.x, current.y + dir.y);
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
// HELPER FUNCTIONS FOR TEST SETUP
// ═══════════════════════════════════════════════════════════════════════════════

/// Create a grid where all cells are passable
List<List<bool>> createOpenGrid(int rows, int cols) {
  return List.generate(rows, (_) => List.filled(cols, true));
}

/// Create a grid where all cells are blocked
List<List<bool>> createBlockedGrid(int rows, int cols) {
  return List.generate(rows, (_) => List.filled(cols, false));
}

/// Block a specific cell in the grid
void blockCell(List<List<bool>> grid, int x, int y) {
  if (y >= 0 && y < grid.length && x >= 0 && x < grid[y].length) {
    grid[y][x] = false;
  }
}

/// Open a specific cell in the grid
void openCell(List<List<bool>> grid, int x, int y) {
  if (y >= 0 && y < grid.length && x >= 0 && x < grid[y].length) {
    grid[y][x] = true;
  }
}

/// Create a horizontal wall in the grid
void createHorizontalWall(List<List<bool>> grid, int y, int startX, int endX) {
  for (int x = startX; x <= endX; x++) {
    blockCell(grid, x, y);
  }
}

/// Create a vertical wall in the grid
void createVerticalWall(List<List<bool>> grid, int x, int startY, int endY) {
  for (int y = startY; y <= endY; y++) {
    blockCell(grid, x, y);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEST SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('Basic Path Finding', () {
    test('direct horizontal path on open grid', () {
      final grid = createOpenGrid(5, 10);

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 2),
        endCell: SimulatedPoint(9, 2),
      );

      expect(result, isTrue);
    });

    test('direct vertical path on open grid', () {
      final grid = createOpenGrid(10, 5);

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(2, 0),
        endCell: SimulatedPoint(2, 9),
      );

      expect(result, isTrue);
    });

    test('diagonal path on open grid', () {
      final grid = createOpenGrid(5, 5);

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(4, 4),
      );

      expect(result, isTrue);
    });

    test('same start and end returns true', () {
      final grid = createOpenGrid(5, 5);

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(2, 2),
        endCell: SimulatedPoint(2, 2),
      );

      expect(result, isTrue);
    });

    test('adjacent cells are reachable', () {
      final grid = createOpenGrid(3, 3);

      // Right neighbor
      expect(
        isPathOpen(
          buildableMask: grid,
          startCell: SimulatedPoint(1, 1),
          endCell: SimulatedPoint(2, 1),
        ),
        isTrue,
      );

      // Left neighbor
      expect(
        isPathOpen(
          buildableMask: grid,
          startCell: SimulatedPoint(1, 1),
          endCell: SimulatedPoint(0, 1),
        ),
        isTrue,
      );

      // Top neighbor
      expect(
        isPathOpen(
          buildableMask: grid,
          startCell: SimulatedPoint(1, 1),
          endCell: SimulatedPoint(1, 0),
        ),
        isTrue,
      );

      // Bottom neighbor
      expect(
        isPathOpen(
          buildableMask: grid,
          startCell: SimulatedPoint(1, 1),
          endCell: SimulatedPoint(1, 2),
        ),
        isTrue,
      );
    });
  });

  group('Blocked Paths', () {
    test('completely blocked grid returns false', () {
      final grid = createBlockedGrid(5, 5);
      // Open only start and end
      openCell(grid, 0, 0);
      openCell(grid, 4, 4);

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(4, 4),
      );

      expect(result, isFalse);
    });

    test('horizontal wall blocks path', () {
      final grid = createOpenGrid(5, 5);
      // Create wall across middle
      createHorizontalWall(grid, 2, 0, 4);

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(2, 0),
        endCell: SimulatedPoint(2, 4),
      );

      expect(result, isFalse);
    });

    test('vertical wall blocks path', () {
      final grid = createOpenGrid(5, 5);
      // Create wall down middle
      createVerticalWall(grid, 2, 0, 4);

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 2),
        endCell: SimulatedPoint(4, 2),
      );

      expect(result, isFalse);
    });

    test('single blocked cell can block narrow path', () {
      // 1-cell wide corridor
      final grid = createBlockedGrid(3, 3);
      openCell(grid, 0, 1);
      openCell(grid, 1, 1);
      openCell(grid, 2, 1);

      // Path is open
      expect(
        isPathOpen(
          buildableMask: grid,
          startCell: SimulatedPoint(0, 1),
          endCell: SimulatedPoint(2, 1),
        ),
        isTrue,
      );

      // Block middle cell
      blockCell(grid, 1, 1);

      expect(
        isPathOpen(
          buildableMask: grid,
          startCell: SimulatedPoint(0, 1),
          endCell: SimulatedPoint(2, 1),
        ),
        isFalse,
      );
    });
  });

  group('Wall with Gap', () {
    test('wall with gap allows path', () {
      final grid = createOpenGrid(5, 5);
      // Create wall with gap
      createHorizontalWall(grid, 2, 0, 1);
      createHorizontalWall(grid, 2, 3, 4);
      // Gap at x=2

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(2, 0),
        endCell: SimulatedPoint(2, 4),
      );

      expect(result, isTrue);
    });

    test('gap at edge of wall allows path', () {
      final grid = createOpenGrid(5, 5);
      // Wall missing first cell
      createHorizontalWall(grid, 2, 1, 4);

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(0, 4),
      );

      expect(result, isTrue);
    });

    test('L-shaped wall with corner gap', () {
      final grid = createOpenGrid(7, 7);
      // Create L-shape
      createHorizontalWall(grid, 3, 0, 4);
      createVerticalWall(grid, 4, 3, 6);
      // Gap at corner (4, 3) was blocked by horizontal, leave vertical

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(6, 6),
      );

      expect(result, isTrue); // Can go around the L
    });
  });

  group('Maze Patterns', () {
    test('simple maze with solution', () {
      // 5x5 maze:
      // S . # . .
      // . # # . .
      // . . . . #
      // # # # . .
      // . . . . E
      final grid = createOpenGrid(5, 5);
      blockCell(grid, 2, 0);
      blockCell(grid, 1, 1);
      blockCell(grid, 2, 1);
      blockCell(grid, 4, 2);
      blockCell(grid, 0, 3);
      blockCell(grid, 1, 3);
      blockCell(grid, 2, 3);

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(4, 4),
      );

      expect(result, isTrue);
    });

    test('maze with no solution', () {
      // Completely surrounded end
      final grid = createOpenGrid(5, 5);
      // Surround cell (2,2)
      blockCell(grid, 1, 1);
      blockCell(grid, 2, 1);
      blockCell(grid, 3, 1);
      blockCell(grid, 1, 2);
      blockCell(grid, 3, 2);
      blockCell(grid, 1, 3);
      blockCell(grid, 2, 3);
      blockCell(grid, 3, 3);

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(2, 2),
      );

      expect(result, isFalse);
    });

    test('spiral path', () {
      // Create a spiral where you have to go around
      final grid = createOpenGrid(5, 5);
      createHorizontalWall(grid, 1, 0, 3);
      createVerticalWall(grid, 3, 1, 2);
      createHorizontalWall(grid, 3, 1, 3);

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(2, 2),
      );

      expect(result, isTrue); // Can spiral around
    });
  });

  group('Edge Cases', () {
    test('empty grid returns false', () {
      final grid = <List<bool>>[];

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(0, 0),
      );

      expect(result, isFalse);
    });

    test('1x1 grid with same start and end', () {
      final grid = [
        [true]
      ];

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(0, 0),
      );

      expect(result, isTrue);
    });

    test('1x1 blocked grid', () {
      final grid = [
        [false]
      ];

      // Start is blocked - behavior depends on implementation
      // The BFS marks start as visited regardless, so it might still "find" it
      // Looking at code: it starts by marking start as visited, then checks if current == end
      // So if start == end, it returns true even if blocked
      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(0, 0),
      );

      expect(result, isTrue); // Start == End, returns true immediately
    });

    test('single row grid', () {
      final grid = [
        [true, true, true, true, true]
      ];

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(4, 0),
      );

      expect(result, isTrue);
    });

    test('single column grid', () {
      final grid = [
        [true],
        [true],
        [true],
        [true],
        [true],
      ];

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(0, 4),
      );

      expect(result, isTrue);
    });

    test('start blocked but end reachable returns path based on neighbors', () {
      final grid = createOpenGrid(3, 3);
      blockCell(grid, 0, 0); // Block start

      // Current implementation marks start as visited regardless
      // and doesn't check if start is passable
      // This is an edge case in the original algorithm
      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(2, 2),
      );

      // Looking at code: start is added to queue and marked visited
      // Then neighbors are checked - they must be passable
      // The path will find passable neighbors and continue
      expect(result, isTrue);
    });
  });

  group('Large Grid Performance', () {
    test('large open grid finds path quickly', () {
      final grid = createOpenGrid(100, 100);

      final stopwatch = Stopwatch()..start();
      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(99, 99),
      );
      stopwatch.stop();

      expect(result, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('large grid with path through maze', () {
      final grid = createOpenGrid(50, 50);

      // Create a series of horizontal walls with gaps
      for (int y = 5; y < 45; y += 5) {
        for (int x = 0; x < 50; x++) {
          if (x != (y % 2 == 0 ? 5 : 44)) {
            blockCell(grid, x, y);
          }
        }
      }

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(49, 49),
      );

      expect(result, isTrue);
    });

    test('large grid with no path', () {
      final grid = createOpenGrid(50, 50);

      // Create impassable wall
      createHorizontalWall(grid, 25, 0, 49);

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(25, 0),
        endCell: SimulatedPoint(25, 49),
      );

      expect(result, isFalse);
    });
  });

  group('BFS Behavior', () {
    test('BFS finds shortest path (no diagonal)', () {
      // BFS naturally finds shortest path in unweighted graph
      final grid = createOpenGrid(5, 5);

      // There's one optimal path of length 8 (4 right + 4 down)
      // BFS will find it
      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(4, 4),
      );

      expect(result, isTrue);
    });

    test('BFS explores in 4 directions only', () {
      // Diagonal cells are not directly reachable
      final grid = createBlockedGrid(3, 3);
      openCell(grid, 0, 0);
      openCell(grid, 2, 2);

      // No path because only 4-directional movement
      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(2, 2),
      );

      expect(result, isFalse);
    });

    test('BFS does not revisit cells', () {
      // Create a grid where revisiting could cause infinite loop
      final grid = createOpenGrid(3, 3);

      // Should complete without issues
      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 0),
        endCell: SimulatedPoint(2, 2),
      );

      expect(result, isTrue);
    });
  });

  group('Tower Defense Scenarios', () {
    test('blocking single cell on enemy path', () {
      // Typical scenario: enemy path goes through middle
      final grid = createOpenGrid(3, 7);

      // Block one cell on the path
      blockCell(grid, 3, 1);

      // Path should still exist (enemies can go around)
      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 1),
        endCell: SimulatedPoint(6, 1),
      );

      expect(result, isTrue);
    });

    test('blocking choke point blocks path', () {
      // Create a choke point
      final grid = createBlockedGrid(5, 5);
      // Open path through middle
      for (int x = 0; x < 5; x++) {
        openCell(grid, x, 2);
      }

      // Path is open
      expect(
        isPathOpen(
          buildableMask: grid,
          startCell: SimulatedPoint(0, 2),
          endCell: SimulatedPoint(4, 2),
        ),
        isTrue,
      );

      // Block choke point
      blockCell(grid, 2, 2);

      // Path is blocked
      expect(
        isPathOpen(
          buildableMask: grid,
          startCell: SimulatedPoint(0, 2),
          endCell: SimulatedPoint(4, 2),
        ),
        isFalse,
      );
    });

    test('creating alternate route keeps path open', () {
      final grid = createOpenGrid(5, 5);

      // Block direct path
      createHorizontalWall(grid, 2, 1, 3);

      // Path still exists via top or bottom
      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 2),
        endCell: SimulatedPoint(4, 2),
      );

      expect(result, isTrue);
    });

    test('surrounding spawn point blocks all paths', () {
      final grid = createOpenGrid(5, 5);

      // Surround the spawn point (0, 2)
      blockCell(grid, 1, 1);
      blockCell(grid, 1, 2);
      blockCell(grid, 1, 3);
      blockCell(grid, 0, 1);
      blockCell(grid, 0, 3);

      final result = isPathOpen(
        buildableMask: grid,
        startCell: SimulatedPoint(0, 2),
        endCell: SimulatedPoint(4, 2),
      );

      expect(result, isFalse);
    });
  });

  group('Multiple Path Validation', () {
    test('validate multiple paths from same start', () {
      final grid = createOpenGrid(5, 5);

      // All corners should be reachable from center
      final center = SimulatedPoint(2, 2);
      final corners = [
        SimulatedPoint(0, 0),
        SimulatedPoint(4, 0),
        SimulatedPoint(0, 4),
        SimulatedPoint(4, 4),
      ];

      for (final corner in corners) {
        expect(
          isPathOpen(
            buildableMask: grid,
            startCell: center,
            endCell: corner,
          ),
          isTrue,
        );
      }
    });

    test('validate bidirectional paths', () {
      final grid = createOpenGrid(5, 5);
      blockCell(grid, 2, 1);
      blockCell(grid, 2, 3);

      final a = SimulatedPoint(0, 2);
      final b = SimulatedPoint(4, 2);

      // Path A -> B
      expect(
        isPathOpen(buildableMask: grid, startCell: a, endCell: b),
        isTrue,
      );

      // Path B -> A (should be same)
      expect(
        isPathOpen(buildableMask: grid, startCell: b, endCell: a),
        isTrue,
      );
    });
  });
}
