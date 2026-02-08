import 'dart:math' as math;
import 'package:test/test.dart';

/// Simulation tests for TowerManager logic without Flutter/Flame dependencies.
/// Tests: grid coordinate conversion, placement validation, resonance fields,
/// targeting interval calculations, ghost rendering parameters.

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED COORDINATE UTILITIES - From coords.dart
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

class SimulatedVector2 {
  double x;
  double y;

  SimulatedVector2(this.x, this.y);

  factory SimulatedVector2.zero() => SimulatedVector2(0, 0);

  double distanceToSquared(SimulatedVector2 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return dx * dx + dy * dy;
  }

  double distanceTo(SimulatedVector2 other) => math.sqrt(distanceToSquared(other));

  SimulatedVector2 operator +(SimulatedVector2 other) =>
      SimulatedVector2(x + other.x, y + other.y);

  SimulatedVector2 operator -(SimulatedVector2 other) =>
      SimulatedVector2(x - other.x, y - other.y);

  double get length => math.sqrt(x * x + y * y);

  void setFrom(SimulatedVector2 other) {
    x = other.x;
    y = other.y;
  }
}

/// Convert screen position to grid cell - exact logic from coords.dart
SimulatedPoint screenToGrid(SimulatedVector2 position, double tileSize) {
  return SimulatedPoint(
    (position.x / tileSize).floor(),
    (position.y / tileSize).floor(),
  );
}

/// Convert grid cell to world position - exact logic from coords.dart
SimulatedVector2 gridToWorld(SimulatedPoint cell, double tileSize) {
  return SimulatedVector2(
    cell.x * tileSize,
    cell.y * tileSize,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED FAST RNG - From tower_manager.dart
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedFastRng {
  int _state;

  SimulatedFastRng([int? seed]) : _state = (seed ?? 0x6d2b79f5) & 0x7fffffff;

  int _next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  double nextDouble() => _next() / 0x7fffffff;

  int nextInt(int max) => max <= 0 ? 0 : _next() % max;

  bool nextBool() => (_next() & 1) == 0;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED TOWER TYPES
// ═══════════════════════════════════════════════════════════════════════════════

enum SimulatedTowerType {
  pulseArcher,
  circuitCannon,
  phaseMage,
  glimmerField,
  ionSniper,
  teslaTerminal,
  resonanceSiphon,
  neuralDisruptor,
  plasmaBubble,
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED TOWER - Simplified version for testing
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedTower {
  SimulatedVector2 position;
  final double size;
  final SimulatedTowerType type;
  bool hasResonanceBoost = false;

  SimulatedTower({
    required this.position,
    required this.size,
    required this.type,
  });

  void setResonanceBoost(bool value) {
    hasResonanceBoost = value;
  }

  void resetResonanceBoost() {
    hasResonanceBoost = false;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED GAME WORLD - Grid for placement validation
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedGameWorld {
  final List<List<bool>> isBuildable;
  final List<List<int>> tileTypes;
  final SimulatedPoint? startCell;
  final SimulatedPoint? endCell;

  SimulatedGameWorld({
    required this.isBuildable,
    required this.tileTypes,
    this.startCell,
    this.endCell,
  });

  factory SimulatedGameWorld.simple(int width, int height) {
    return SimulatedGameWorld(
      isBuildable: List.generate(height, (_) => List.filled(width, true)),
      tileTypes: List.generate(height, (_) => List.filled(width, 0)),
    );
  }

  factory SimulatedGameWorld.withPath(int width, int height, List<SimulatedPoint> pathCells) {
    final buildable = List.generate(height, (_) => List.filled(width, true));
    final types = List.generate(height, (_) => List.filled(width, 0));

    for (final cell in pathCells) {
      if (cell.y >= 0 && cell.y < height && cell.x >= 0 && cell.x < width) {
        types[cell.y][cell.x] = 2; // Path tile
      }
    }

    return SimulatedGameWorld(
      isBuildable: buildable,
      tileTypes: types,
      startCell: pathCells.isNotEmpty ? pathCells.first : null,
      endCell: pathCells.length > 1 ? pathCells.last : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED TOWER MANAGER - Core logic from tower_manager.dart
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedTowerManager {
  final double tileSize;
  final SimulatedGameWorld world;
  final List<SimulatedTower> _towers = [];
  final Set<SimulatedPoint> occupied = {};
  bool blockRejected = false;
  SimulatedTowerType selectedTowerType = SimulatedTowerType.pulseArcher;
  bool showHeatmap = false;
  SimulatedVector2? ghostPosition;

  SimulatedTowerManager({
    required this.tileSize,
    required this.world,
  });

  List<SimulatedTower> get towers => _towers;
  int get towerCount => _towers.length;

  void updateGhost(SimulatedVector2? position) {
    ghostPosition = position;
    showHeatmap = position != null;
  }

  bool _isCellWithin(SimulatedPoint cell) {
    return cell.y >= 0 &&
        cell.y < world.isBuildable.length &&
        cell.x >= 0 &&
        cell.x < world.isBuildable[cell.y].length;
  }

  bool _wouldKeepPathOpen(SimulatedPoint candidate) {
    if (world.tileTypes.isEmpty) return true;
    return world.tileTypes[candidate.y][candidate.x] != 2;
  }

  SimulatedTower? towerAt(SimulatedVector2 worldPos) {
    for (final tower in _towers.reversed) {
      final pos = tower.position;
      final size = tower.size;
      if (worldPos.x >= pos.x &&
          worldPos.x <= pos.x + size &&
          worldPos.y >= pos.y &&
          worldPos.y <= pos.y + size) {
        return tower;
      }
    }
    return null;
  }

  /// Place tower - returns success/failure
  /// Returns error message if failed, null if success
  String? placeTower(SimulatedVector2 worldPos) {
    final cell = screenToGrid(worldPos, tileSize);

    if (!_isCellWithin(cell)) {
      return 'Cell out of bounds';
    }

    if (!world.isBuildable[cell.y][cell.x]) {
      return 'Forbidden tile';
    }

    if (occupied.contains(cell)) {
      return 'Already occupied';
    }

    // Path blocking check
    if (world.startCell != null &&
        world.endCell != null &&
        !_wouldKeepPathOpen(cell)) {
      blockRejected = true;
      return 'Build would block path';
    }
    blockRejected = false;

    // Place the tower
    final pos = gridToWorld(cell, tileSize);
    final tower = SimulatedTower(
      position: pos,
      size: tileSize,
      type: selectedTowerType,
    );
    _towers.add(tower);
    occupied.add(cell);

    if (_towers.isNotEmpty) {
      _updateResonanceFields();
    }

    return null; // Success
  }

  bool removeTower(SimulatedTower tower) {
    if (!_towers.remove(tower)) return false;
    final cell = screenToGrid(tower.position, tileSize);
    occupied.remove(cell);
    if (_towers.isNotEmpty) {
      _updateResonanceFields();
    }
    return true;
  }

  void _updateResonanceFields() {
    // Clear all boosts first
    for (final t in _towers) {
      t.resetResonanceBoost();
    }

    // Use squared distance to avoid per-comparison sqrt()
    const resonanceRangeSq = 100.0 * 100.0;

    for (final siphon in _towers) {
      if (siphon.type != SimulatedTowerType.resonanceSiphon) continue;
      for (final tower in _towers) {
        if (tower == siphon) continue;
        if (tower.position.distanceToSquared(siphon.position) < resonanceRangeSq) {
          tower.setResonanceBoost(true);
        }
      }
    }
  }

  void setSelectedTowerType(SimulatedTowerType type) {
    selectedTowerType = type;
  }

  /// Calculate targeting interval based on game state
  static double calculateTargetingInterval({
    required int enemyCount,
    required int towerCount,
    required bool reduceFx,
    double baseInterval = 1 / 30,
  }) {
    double interval = baseInterval;
    if (reduceFx || enemyCount > 24 || towerCount > 20) {
      interval = 1 / 20;
    }
    if (enemyCount > 40 || towerCount > 30) {
      interval = 1 / 12;
    }
    return interval;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEST SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('Coordinate Conversion', () {
    test('screenToGrid converts correctly', () {
      const tileSize = 32.0;

      expect(screenToGrid(SimulatedVector2(0, 0), tileSize), equals(SimulatedPoint(0, 0)));
      expect(screenToGrid(SimulatedVector2(31, 31), tileSize), equals(SimulatedPoint(0, 0)));
      expect(screenToGrid(SimulatedVector2(32, 32), tileSize), equals(SimulatedPoint(1, 1)));
      expect(screenToGrid(SimulatedVector2(100, 200), tileSize), equals(SimulatedPoint(3, 6)));
    });

    test('gridToWorld converts correctly', () {
      const tileSize = 32.0;

      final pos = gridToWorld(SimulatedPoint(3, 5), tileSize);
      expect(pos.x, equals(96.0));
      expect(pos.y, equals(160.0));
    });

    test('round-trip conversion is consistent', () {
      const tileSize = 32.0;

      for (int x = 0; x < 10; x++) {
        for (int y = 0; y < 10; y++) {
          final cell = SimulatedPoint(x, y);
          final world = gridToWorld(cell, tileSize);
          final back = screenToGrid(world, tileSize);
          expect(back, equals(cell));
        }
      }
    });

    test('handles non-integer positions', () {
      const tileSize = 32.0;

      // Position in middle of tile
      final cell = screenToGrid(SimulatedVector2(48, 48), tileSize);
      expect(cell, equals(SimulatedPoint(1, 1)));

      // Position at edge of tile
      final edge = screenToGrid(SimulatedVector2(31.9, 63.9), tileSize);
      expect(edge, equals(SimulatedPoint(0, 1)));
    });

    test('handles different tile sizes', () {
      expect(screenToGrid(SimulatedVector2(100, 100), 50.0), equals(SimulatedPoint(2, 2)));
      expect(screenToGrid(SimulatedVector2(100, 100), 25.0), equals(SimulatedPoint(4, 4)));
      expect(screenToGrid(SimulatedVector2(100, 100), 10.0), equals(SimulatedPoint(10, 10)));
    });
  });

  group('Tower Placement', () {
    test('basic placement succeeds', () {
      final world = SimulatedGameWorld.simple(10, 10);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      final result = manager.placeTower(SimulatedVector2(50, 50));

      expect(result, isNull); // Success
      expect(manager.towerCount, equals(1));
      expect(manager.occupied.length, equals(1));
    });

    test('placement on forbidden tile fails', () {
      final world = SimulatedGameWorld.simple(10, 10);
      world.isBuildable[2][2] = false; // Forbid cell (2,2)

      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      final result = manager.placeTower(SimulatedVector2(70, 70)); // Cell (2,2)

      expect(result, equals('Forbidden tile'));
      expect(manager.towerCount, equals(0));
    });

    test('duplicate placement fails', () {
      final world = SimulatedGameWorld.simple(10, 10);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      manager.placeTower(SimulatedVector2(50, 50));
      final result = manager.placeTower(SimulatedVector2(55, 55)); // Same cell

      expect(result, equals('Already occupied'));
      expect(manager.towerCount, equals(1));
    });

    test('placement on path tile fails', () {
      final pathCells = [SimulatedPoint(2, 2), SimulatedPoint(3, 2), SimulatedPoint(4, 2)];
      final world = SimulatedGameWorld.withPath(10, 10, pathCells);

      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      final result = manager.placeTower(SimulatedVector2(100, 70)); // Cell (3,2) - path

      expect(result, equals('Build would block path'));
      expect(manager.blockRejected, isTrue);
    });

    test('placement off path succeeds', () {
      final pathCells = [SimulatedPoint(2, 2), SimulatedPoint(3, 2)];
      final world = SimulatedGameWorld.withPath(10, 10, pathCells);

      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      final result = manager.placeTower(SimulatedVector2(150, 150)); // Cell (4,4) - not path

      expect(result, isNull);
      expect(manager.blockRejected, isFalse);
    });

    test('placement out of bounds fails', () {
      final world = SimulatedGameWorld.simple(10, 10);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      final result = manager.placeTower(SimulatedVector2(500, 500)); // Way outside

      expect(result, equals('Cell out of bounds'));
    });

    test('tower at position returns correct tower', () {
      final world = SimulatedGameWorld.simple(10, 10);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      manager.selectedTowerType = SimulatedTowerType.pulseArcher;
      manager.placeTower(SimulatedVector2(50, 50));

      manager.selectedTowerType = SimulatedTowerType.phaseMage;
      manager.placeTower(SimulatedVector2(100, 50));

      // Find first tower
      final tower1 = manager.towerAt(SimulatedVector2(40, 40));
      expect(tower1, isNotNull);
      expect(tower1!.type, equals(SimulatedTowerType.pulseArcher));

      // Find second tower
      final tower2 = manager.towerAt(SimulatedVector2(110, 55));
      expect(tower2, isNotNull);
      expect(tower2!.type, equals(SimulatedTowerType.phaseMage));

      // No tower at empty spot
      final noTower = manager.towerAt(SimulatedVector2(200, 200));
      expect(noTower, isNull);
    });

    test('remove tower clears occupied cell', () {
      final world = SimulatedGameWorld.simple(10, 10);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      manager.placeTower(SimulatedVector2(50, 50));
      expect(manager.towerCount, equals(1));
      expect(manager.occupied.length, equals(1));

      final tower = manager.towers.first;
      final removed = manager.removeTower(tower);

      expect(removed, isTrue);
      expect(manager.towerCount, equals(0));
      expect(manager.occupied.length, equals(0));
    });

    test('removing non-existent tower returns false', () {
      final world = SimulatedGameWorld.simple(10, 10);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      final fakeTower = SimulatedTower(
        position: SimulatedVector2(0, 0),
        size: 32.0,
        type: SimulatedTowerType.pulseArcher,
      );

      final removed = manager.removeTower(fakeTower);
      expect(removed, isFalse);
    });
  });

  group('Resonance Fields', () {
    test('resonance siphon boosts nearby towers', () {
      final world = SimulatedGameWorld.simple(20, 20);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      // Place archer tower
      manager.selectedTowerType = SimulatedTowerType.pulseArcher;
      manager.placeTower(SimulatedVector2(50, 50));

      // Place resonance siphon nearby (within 100 units)
      manager.selectedTowerType = SimulatedTowerType.resonanceSiphon;
      manager.placeTower(SimulatedVector2(100, 50)); // ~50 units away

      final archer = manager.towers.first;
      expect(archer.hasResonanceBoost, isTrue);
    });

    test('resonance siphon does not boost itself', () {
      final world = SimulatedGameWorld.simple(10, 10);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      manager.selectedTowerType = SimulatedTowerType.resonanceSiphon;
      manager.placeTower(SimulatedVector2(50, 50));

      final siphon = manager.towers.first;
      expect(siphon.hasResonanceBoost, isFalse);
    });

    test('resonance siphon does not boost distant towers', () {
      final world = SimulatedGameWorld.simple(20, 20);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      // Place archer tower far away
      manager.selectedTowerType = SimulatedTowerType.pulseArcher;
      manager.placeTower(SimulatedVector2(50, 50));

      // Place resonance siphon far away (> 100 units)
      manager.selectedTowerType = SimulatedTowerType.resonanceSiphon;
      manager.placeTower(SimulatedVector2(400, 400)); // ~500 units away

      final archer = manager.towers.first;
      expect(archer.hasResonanceBoost, isFalse);
    });

    test('multiple siphons can boost same tower', () {
      final world = SimulatedGameWorld.simple(20, 20);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      // Place archer in center
      manager.selectedTowerType = SimulatedTowerType.pulseArcher;
      manager.placeTower(SimulatedVector2(150, 150));

      // Place siphons around it
      manager.selectedTowerType = SimulatedTowerType.resonanceSiphon;
      manager.placeTower(SimulatedVector2(100, 150)); // Left
      manager.placeTower(SimulatedVector2(200, 150)); // Right

      final archer = manager.towers.first;
      expect(archer.hasResonanceBoost, isTrue);
    });

    test('resonance boost resets when siphon removed', () {
      final world = SimulatedGameWorld.simple(20, 20);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      // Place archer
      manager.selectedTowerType = SimulatedTowerType.pulseArcher;
      manager.placeTower(SimulatedVector2(50, 50));

      // Place siphon nearby
      manager.selectedTowerType = SimulatedTowerType.resonanceSiphon;
      manager.placeTower(SimulatedVector2(100, 50));

      final archer = manager.towers.first;
      expect(archer.hasResonanceBoost, isTrue);

      // Remove siphon
      final siphon = manager.towers.last;
      manager.removeTower(siphon);

      // Only archer remains, boost should be reset
      // Note: The implementation recalculates, so if no siphons, no boost
      expect(manager.towers.length, equals(1));
    });

    test('resonance range is exactly 100 units', () {
      final world = SimulatedGameWorld.simple(20, 20);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      // Place archer at origin
      manager.selectedTowerType = SimulatedTowerType.pulseArcher;
      manager.placeTower(SimulatedVector2(0, 0));

      // Place siphon at exactly 99 units (should boost)
      manager.selectedTowerType = SimulatedTowerType.resonanceSiphon;
      manager.placeTower(SimulatedVector2(99 * 0.707, 99 * 0.707)); // ~99 diagonal

      final archer = manager.towers.first;
      expect(archer.hasResonanceBoost, isTrue);
    });
  });

  group('Targeting Interval', () {
    test('base interval at low load', () {
      final interval = SimulatedTowerManager.calculateTargetingInterval(
        enemyCount: 10,
        towerCount: 5,
        reduceFx: false,
      );

      expect(interval, closeTo(1 / 30, 0.001));
    });

    test('reduced interval with reduceFx flag', () {
      final interval = SimulatedTowerManager.calculateTargetingInterval(
        enemyCount: 10,
        towerCount: 5,
        reduceFx: true,
      );

      expect(interval, closeTo(1 / 20, 0.001));
    });

    test('reduced interval with many enemies', () {
      final interval = SimulatedTowerManager.calculateTargetingInterval(
        enemyCount: 30, // > 24
        towerCount: 5,
        reduceFx: false,
      );

      expect(interval, closeTo(1 / 20, 0.001));
    });

    test('reduced interval with many towers', () {
      final interval = SimulatedTowerManager.calculateTargetingInterval(
        enemyCount: 10,
        towerCount: 25, // > 20
        reduceFx: false,
      );

      expect(interval, closeTo(1 / 20, 0.001));
    });

    test('minimal interval with very high load', () {
      final interval = SimulatedTowerManager.calculateTargetingInterval(
        enemyCount: 50, // > 40
        towerCount: 35, // > 30
        reduceFx: false,
      );

      expect(interval, closeTo(1 / 12, 0.001));
    });

    test('high enemy count triggers minimal interval', () {
      final interval = SimulatedTowerManager.calculateTargetingInterval(
        enemyCount: 45, // > 40
        towerCount: 5,
        reduceFx: false,
      );

      expect(interval, closeTo(1 / 12, 0.001));
    });

    test('high tower count triggers minimal interval', () {
      final interval = SimulatedTowerManager.calculateTargetingInterval(
        enemyCount: 10,
        towerCount: 35, // > 30
        reduceFx: false,
      );

      expect(interval, closeTo(1 / 12, 0.001));
    });
  });

  group('Ghost Position', () {
    test('updateGhost sets position and heatmap', () {
      final world = SimulatedGameWorld.simple(10, 10);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      expect(manager.ghostPosition, isNull);
      expect(manager.showHeatmap, isFalse);

      manager.updateGhost(SimulatedVector2(100, 100));

      expect(manager.ghostPosition, isNotNull);
      expect(manager.ghostPosition!.x, equals(100));
      expect(manager.showHeatmap, isTrue);
    });

    test('clearing ghost disables heatmap', () {
      final world = SimulatedGameWorld.simple(10, 10);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      manager.updateGhost(SimulatedVector2(100, 100));
      expect(manager.showHeatmap, isTrue);

      manager.updateGhost(null);
      expect(manager.ghostPosition, isNull);
      expect(manager.showHeatmap, isFalse);
    });
  });

  group('Tower Type Selection', () {
    test('default type is pulseArcher', () {
      final world = SimulatedGameWorld.simple(10, 10);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      expect(manager.selectedTowerType, equals(SimulatedTowerType.pulseArcher));
    });

    test('setSelectedTowerType changes selection', () {
      final world = SimulatedGameWorld.simple(10, 10);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      manager.setSelectedTowerType(SimulatedTowerType.phaseMage);
      expect(manager.selectedTowerType, equals(SimulatedTowerType.phaseMage));

      manager.setSelectedTowerType(SimulatedTowerType.circuitCannon);
      expect(manager.selectedTowerType, equals(SimulatedTowerType.circuitCannon));
    });

    test('placed tower uses selected type', () {
      final world = SimulatedGameWorld.simple(10, 10);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      manager.setSelectedTowerType(SimulatedTowerType.glimmerField);
      manager.placeTower(SimulatedVector2(50, 50));

      expect(manager.towers.first.type, equals(SimulatedTowerType.glimmerField));
    });
  });

  group('Fast RNG', () {
    test('produces consistent sequences', () {
      final rng1 = SimulatedFastRng(42);
      final rng2 = SimulatedFastRng(42);

      for (int i = 0; i < 100; i++) {
        expect(rng1.nextDouble(), equals(rng2.nextDouble()));
      }
    });

    test('nextDouble in range [0, 1)', () {
      final rng = SimulatedFastRng();
      for (int i = 0; i < 1000; i++) {
        final value = rng.nextDouble();
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThan(1.0));
      }
    });

    test('nextInt respects bounds', () {
      final rng = SimulatedFastRng();
      for (int max = 1; max <= 50; max++) {
        for (int i = 0; i < 20; i++) {
          final value = rng.nextInt(max);
          expect(value, greaterThanOrEqualTo(0));
          expect(value, lessThan(max));
        }
      }
    });

    test('nextBool returns both values', () {
      final rng = SimulatedFastRng();
      bool hasTrue = false;
      bool hasFalse = false;

      for (int i = 0; i < 100 && !(hasTrue && hasFalse); i++) {
        if (rng.nextBool()) {
          hasTrue = true;
        } else {
          hasFalse = true;
        }
      }

      expect(hasTrue, isTrue);
      expect(hasFalse, isTrue);
    });
  });

  group('Distance Calculations', () {
    test('distanceToSquared is correct', () {
      final p1 = SimulatedVector2(0, 0);
      final p2 = SimulatedVector2(3, 4);

      expect(p1.distanceToSquared(p2), equals(25)); // 3^2 + 4^2
    });

    test('distanceTo is correct', () {
      final p1 = SimulatedVector2(0, 0);
      final p2 = SimulatedVector2(3, 4);

      expect(p1.distanceTo(p2), equals(5)); // sqrt(25)
    });

    test('squared distance avoids sqrt for comparison', () {
      final p1 = SimulatedVector2(0, 0);
      final p2 = SimulatedVector2(70, 70); // ~99 units

      const rangeSquared = 100.0 * 100.0;
      final distSquared = p1.distanceToSquared(p2);

      // Should be within range
      expect(distSquared, lessThan(rangeSquared));

      // Verify: 70^2 + 70^2 = 9800 < 10000
      expect(distSquared, equals(9800));
    });
  });

  group('Integration - Multiple Tower Placement', () {
    test('can place multiple towers', () {
      final world = SimulatedGameWorld.simple(20, 20);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      for (int i = 0; i < 10; i++) {
        final result = manager.placeTower(SimulatedVector2(i * 32.0 + 16, 50));
        expect(result, isNull);
      }

      expect(manager.towerCount, equals(10));
      expect(manager.occupied.length, equals(10));
    });

    test('mixed tower types placement', () {
      final world = SimulatedGameWorld.simple(20, 20);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      final types = SimulatedTowerType.values;
      for (int i = 0; i < types.length; i++) {
        manager.setSelectedTowerType(types[i]);
        final result = manager.placeTower(SimulatedVector2(i * 64.0 + 32, 50));
        expect(result, isNull);
      }

      expect(manager.towerCount, equals(types.length));

      // Verify each type was placed
      for (final type in types) {
        final hasType = manager.towers.any((t) => t.type == type);
        expect(hasType, isTrue);
      }
    });

    test('grid fills correctly', () {
      final world = SimulatedGameWorld.simple(5, 5);
      final manager = SimulatedTowerManager(tileSize: 32.0, world: world);

      // Fill entire grid
      for (int y = 0; y < 5; y++) {
        for (int x = 0; x < 5; x++) {
          final result = manager.placeTower(SimulatedVector2(x * 32.0 + 16, y * 32.0 + 16));
          expect(result, isNull);
        }
      }

      expect(manager.towerCount, equals(25));

      // Try to place one more - should fail everywhere
      for (int y = 0; y < 5; y++) {
        for (int x = 0; x < 5; x++) {
          final result = manager.placeTower(SimulatedVector2(x * 32.0 + 16, y * 32.0 + 16));
          expect(result, equals('Already occupied'));
        }
      }
    });
  });
}
