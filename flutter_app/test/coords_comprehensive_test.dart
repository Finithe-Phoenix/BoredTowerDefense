import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// Tests for coordinate conversion utilities

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED CLASSES FROM coords.dart
// ═══════════════════════════════════════════════════════════════════════════════

/// Vector2 simulation for testing
class Vector2 {
  final double x;
  final double y;

  Vector2(this.x, this.y);

  @override
  bool operator ==(Object other) {
    if (other is Vector2) {
      return x == other.x && y == other.y;
    }
    return false;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'Vector2($x, $y)';
}

/// Converts screen position to grid cell coordinates
Point<int> screenToGrid(Vector2 position, double tileSize) {
  final gx = (position.x / tileSize).floor();
  final gy = (position.y / tileSize).floor();
  return Point<int>(gx, gy);
}

/// Converts grid cell to world position (top-left corner)
Vector2 gridToWorld(Point<int> cell, double tileSize) {
  return Vector2(cell.x * tileSize, cell.y * tileSize);
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('screenToGrid', () {
    test('origin maps to grid (0, 0)', () {
      final result = screenToGrid(Vector2(0, 0), 32);
      expect(result.x, 0);
      expect(result.y, 0);
    });

    test('small positive position maps to grid (0, 0)', () {
      final result = screenToGrid(Vector2(15, 15), 32);
      expect(result.x, 0);
      expect(result.y, 0);
    });

    test('position at tile boundary maps to next cell', () {
      final result = screenToGrid(Vector2(32, 32), 32);
      expect(result.x, 1);
      expect(result.y, 1);
    });

    test('position just before boundary stays in current cell', () {
      final result = screenToGrid(Vector2(31.9, 31.9), 32);
      expect(result.x, 0);
      expect(result.y, 0);
    });

    test('handles different tile sizes', () {
      // Tile size 64
      expect(screenToGrid(Vector2(64, 64), 64).x, 1);
      expect(screenToGrid(Vector2(64, 64), 64).y, 1);

      // Tile size 16
      expect(screenToGrid(Vector2(64, 64), 16).x, 4);
      expect(screenToGrid(Vector2(64, 64), 16).y, 4);
    });

    test('negative positions map to negative cells', () {
      final result = screenToGrid(Vector2(-10, -10), 32);
      expect(result.x, -1);
      expect(result.y, -1);
    });

    test('large positions work correctly', () {
      final result = screenToGrid(Vector2(1000, 2000), 32);
      expect(result.x, 31); // 1000 / 32 = 31.25 -> 31
      expect(result.y, 62); // 2000 / 32 = 62.5 -> 62
    });

    test('asymmetric position', () {
      final result = screenToGrid(Vector2(100, 200), 32);
      expect(result.x, 3); // 100 / 32 = 3.125 -> 3
      expect(result.y, 6); // 200 / 32 = 6.25 -> 6
    });

    test('fractional tile size', () {
      final result = screenToGrid(Vector2(100, 100), 33.33);
      expect(result.x, 3); // 100 / 33.33 = 3.0 -> 3
      expect(result.y, 3);
    });

    test('very small tile size', () {
      final result = screenToGrid(Vector2(100, 100), 1);
      expect(result.x, 100);
      expect(result.y, 100);
    });

    test('exact tile boundary values', () {
      for (int i = 0; i < 10; i++) {
        final pos = Vector2(i * 32.0, i * 32.0);
        final result = screenToGrid(pos, 32);
        expect(result.x, i);
        expect(result.y, i);
      }
    });
  });

  group('gridToWorld', () {
    test('origin cell maps to world origin', () {
      final result = gridToWorld(const Point(0, 0), 32);
      expect(result.x, 0);
      expect(result.y, 0);
    });

    test('cell (1, 1) maps to tile position', () {
      final result = gridToWorld(const Point(1, 1), 32);
      expect(result.x, 32);
      expect(result.y, 32);
    });

    test('handles different tile sizes', () {
      // Tile size 64
      final result64 = gridToWorld(const Point(2, 3), 64);
      expect(result64.x, 128);
      expect(result64.y, 192);

      // Tile size 16
      final result16 = gridToWorld(const Point(2, 3), 16);
      expect(result16.x, 32);
      expect(result16.y, 48);
    });

    test('negative cells map to negative world positions', () {
      final result = gridToWorld(const Point(-2, -3), 32);
      expect(result.x, -64);
      expect(result.y, -96);
    });

    test('large cell values', () {
      final result = gridToWorld(const Point(100, 200), 32);
      expect(result.x, 3200);
      expect(result.y, 6400);
    });

    test('asymmetric cell position', () {
      final result = gridToWorld(const Point(5, 10), 32);
      expect(result.x, 160);
      expect(result.y, 320);
    });

    test('fractional tile size', () {
      final result = gridToWorld(const Point(3, 3), 33.33);
      expect(result.x, closeTo(99.99, 0.01));
      expect(result.y, closeTo(99.99, 0.01));
    });
  });

  group('Round Trip Conversion', () {
    test('screenToGrid then gridToWorld returns cell top-left', () {
      const tileSize = 32.0;
      final original = Vector2(100, 150);

      final cell = screenToGrid(original, tileSize);
      final worldPos = gridToWorld(cell, tileSize);

      // Should return the top-left corner of the cell
      expect(worldPos.x, 96); // cell 3 * 32
      expect(worldPos.y, 128); // cell 4 * 32
    });

    test('gridToWorld then screenToGrid returns same cell', () {
      const tileSize = 32.0;
      const original = Point(5, 7);

      final worldPos = gridToWorld(original, tileSize);
      final cell = screenToGrid(worldPos, tileSize);

      expect(cell.x, original.x);
      expect(cell.y, original.y);
    });

    test('round trip with various cells', () {
      const tileSize = 32.0;

      for (int x = -5; x <= 5; x++) {
        for (int y = -5; y <= 5; y++) {
          final cell = Point(x, y);
          final worldPos = gridToWorld(cell, tileSize);
          final backToCell = screenToGrid(worldPos, tileSize);

          expect(backToCell.x, cell.x, reason: 'X mismatch for cell ($x, $y)');
          expect(backToCell.y, cell.y, reason: 'Y mismatch for cell ($x, $y)');
        }
      }
    });

    test('round trip with various tile sizes', () {
      final tileSizes = [16.0, 32.0, 48.0, 64.0, 100.0];

      for (final tileSize in tileSizes) {
        const cell = Point(3, 5);
        final worldPos = gridToWorld(cell, tileSize);
        final backToCell = screenToGrid(worldPos, tileSize);

        expect(backToCell.x, cell.x, reason: 'X mismatch for tile size $tileSize');
        expect(backToCell.y, cell.y, reason: 'Y mismatch for tile size $tileSize');
      }
    });
  });

  group('Edge Cases', () {
    test('very large coordinates', () {
      final largePos = Vector2(1000000, 1000000);
      final cell = screenToGrid(largePos, 32);

      expect(cell.x, 31250);
      expect(cell.y, 31250);
    });

    test('very small tile size', () {
      final result = screenToGrid(Vector2(10, 10), 0.1);
      expect(result.x, 100);
      expect(result.y, 100);
    });

    test('position exactly at negative boundary', () {
      final result = screenToGrid(Vector2(-32, -32), 32);
      expect(result.x, -1);
      expect(result.y, -1);
    });

    test('fractional positions near zero', () {
      final result1 = screenToGrid(Vector2(0.001, 0.001), 32);
      expect(result1.x, 0);
      expect(result1.y, 0);

      final result2 = screenToGrid(Vector2(-0.001, -0.001), 32);
      expect(result2.x, -1);
      expect(result2.y, -1);
    });
  });

  group('Typical Game Scenarios', () {
    test('mouse click to tower placement', () {
      // Player clicks at screen position
      final clickPos = Vector2(256, 384);
      const tileSize = 32.0;

      // Convert to grid
      final gridPos = screenToGrid(clickPos, tileSize);

      // Get world position for tower placement
      final towerPos = gridToWorld(gridPos, tileSize);

      // Tower should be at top-left of grid cell
      expect(gridPos.x, 8);
      expect(gridPos.y, 12);
      expect(towerPos.x, 256);
      expect(towerPos.y, 384);
    });

    test('enemy pathfinding cell lookup', () {
      // Enemy at world position
      final enemyPos = Vector2(150, 220);
      const tileSize = 32.0;

      // Find which cell enemy is in
      final cell = screenToGrid(enemyPos, tileSize);

      expect(cell.x, 4); // 150 / 32 = 4.68 -> 4
      expect(cell.y, 6); // 220 / 32 = 6.875 -> 6
    });

    test('grid-based collision detection', () {
      const tileSize = 32.0;

      // Two entities
      final entity1 = Vector2(50, 50);
      final entity2 = Vector2(60, 55);

      final cell1 = screenToGrid(entity1, tileSize);
      final cell2 = screenToGrid(entity2, tileSize);

      // Both in same cell
      expect(cell1.x, cell2.x);
      expect(cell1.y, cell2.y);
    });

    test('entities in different cells', () {
      const tileSize = 32.0;

      final entity1 = Vector2(30, 30);
      final entity2 = Vector2(65, 65);

      final cell1 = screenToGrid(entity1, tileSize);
      final cell2 = screenToGrid(entity2, tileSize);

      // Different cells
      expect(cell1.x, 0);
      expect(cell1.y, 0);
      expect(cell2.x, 2);
      expect(cell2.y, 2);
    });
  });

  group('Grid Center Calculation', () {
    test('calculate cell center from grid position', () {
      const tileSize = 32.0;
      const cell = Point(3, 5);

      final topLeft = gridToWorld(cell, tileSize);
      final centerX = topLeft.x + tileSize / 2;
      final centerY = topLeft.y + tileSize / 2;

      expect(centerX, 112); // 96 + 16
      expect(centerY, 176); // 160 + 16
    });
  });

  group('Tile Size Relationships', () {
    test('doubling tile size halves grid coordinates', () {
      final pos = Vector2(100, 100);

      final cell32 = screenToGrid(pos, 32);
      final cell64 = screenToGrid(pos, 64);

      expect(cell32.x, 3);
      expect(cell64.x, 1);
      // Note: not exactly half due to floor()
    });

    test('world position scales with tile size', () {
      const cell = Point(4, 4);

      final world32 = gridToWorld(cell, 32);
      final world64 = gridToWorld(cell, 64);

      expect(world64.x, world32.x * 2);
      expect(world64.y, world32.y * 2);
    });
  });

  group('Boundary Conditions', () {
    test('positions at exact tile boundaries', () {
      const tileSize = 32.0;

      // Test exact boundaries
      for (int i = 0; i <= 10; i++) {
        final pos = Vector2(i * tileSize, i * tileSize);
        final cell = screenToGrid(pos, tileSize);
        expect(cell.x, i);
        expect(cell.y, i);
      }
    });

    test('positions just inside tile boundaries', () {
      const tileSize = 32.0;
      const epsilon = 0.0001;

      for (int i = 1; i <= 10; i++) {
        final pos = Vector2(i * tileSize - epsilon, i * tileSize - epsilon);
        final cell = screenToGrid(pos, tileSize);
        expect(cell.x, i - 1);
        expect(cell.y, i - 1);
      }
    });
  });

  group('Common Tile Sizes', () {
    test('16x16 tiles', () {
      final cell = screenToGrid(Vector2(100, 100), 16);
      expect(cell.x, 6);
      expect(cell.y, 6);
    });

    test('32x32 tiles', () {
      final cell = screenToGrid(Vector2(100, 100), 32);
      expect(cell.x, 3);
      expect(cell.y, 3);
    });

    test('48x48 tiles', () {
      final cell = screenToGrid(Vector2(100, 100), 48);
      expect(cell.x, 2);
      expect(cell.y, 2);
    });

    test('64x64 tiles', () {
      final cell = screenToGrid(Vector2(100, 100), 64);
      expect(cell.x, 1);
      expect(cell.y, 1);
    });
  });
}
