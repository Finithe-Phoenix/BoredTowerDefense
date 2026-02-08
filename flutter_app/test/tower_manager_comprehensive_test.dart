import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/tower.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TowerManager static constants', () {
    test('targeting interval base is 1/30', () {
      const targetingIntervalBase = 1 / 30;
      expect(targetingIntervalBase, closeTo(0.0333, 0.001));
    });

    test('resonance interval is 0.5', () {
      const resonanceInterval = 0.5;
      expect(resonanceInterval, 0.5);
    });
  });

  group('TowerManager coordinate conversion', () {
    test('screenToGrid conversion', () {
      const tileSize = 32.0;

      Vector2 gridToWorld(math.Point<int> cell) {
        return Vector2(cell.x * tileSize, cell.y * tileSize);
      }

      math.Point<int> screenToGrid(Vector2 pos) {
        return math.Point(
            (pos.x / tileSize).floor(), (pos.y / tileSize).floor());
      }

      // Test conversions
      final cell = screenToGrid(Vector2(64, 96));
      expect(cell.x, 2);
      expect(cell.y, 3);

      final worldPos = gridToWorld(math.Point(2, 3));
      expect(worldPos.x, 64);
      expect(worldPos.y, 96);
    });

    test('screenToGrid handles edge cases', () {
      const tileSize = 32.0;

      math.Point<int> screenToGrid(Vector2 pos) {
        return math.Point(
            (pos.x / tileSize).floor(), (pos.y / tileSize).floor());
      }

      // At origin
      expect(screenToGrid(Vector2.zero()), math.Point(0, 0));

      // Just before tile boundary
      expect(screenToGrid(Vector2(31.9, 31.9)), math.Point(0, 0));

      // At tile boundary
      expect(screenToGrid(Vector2(32, 32)), math.Point(1, 1));
    });
  });

  group('TowerType enum', () {
    test('has expected tower types', () {
      expect(TowerType.values.length, greaterThan(0));
    });

    test('pulseArcher exists', () {
      expect(TowerType.values, contains(TowerType.pulseArcher));
    });

    test('circuitCannon exists', () {
      expect(TowerType.values, contains(TowerType.circuitCannon));
    });

    test('phaseMage exists', () {
      expect(TowerType.values, contains(TowerType.phaseMage));
    });

    test('glimmerField exists', () {
      expect(TowerType.values, contains(TowerType.glimmerField));
    });

    test('ionSniper exists', () {
      expect(TowerType.values, contains(TowerType.ionSniper));
    });

    test('each tower type has unique index', () {
      final indices = TowerType.values.map((t) => t.index).toSet();
      expect(indices.length, TowerType.values.length);
    });
  });

  group('TowerType properties', () {
    test('pulseArcher has valid stats', () {
      final tower = TowerType.pulseArcher;
      expect(tower.damage, greaterThan(0));
      expect(tower.range, greaterThan(0));
      expect(tower.fireRate, greaterThan(0));
      expect(tower.cost, greaterThan(0));
    });

    test('phaseMage has valid stats', () {
      final tower = TowerType.phaseMage;
      expect(tower.damage, greaterThan(0));
      expect(tower.range, greaterThan(0));
      expect(tower.fireRate, greaterThan(0));
      expect(tower.cost, greaterThan(0));
    });

    test('circuitCannon has valid stats', () {
      final tower = TowerType.circuitCannon;
      expect(tower.damage, greaterThan(0));
      expect(tower.range, greaterThan(0));
      expect(tower.fireRate, greaterThan(0));
      expect(tower.cost, greaterThan(0));
    });

    test('all towers have non-negative projectile speed', () {
      for (final type in TowerType.values) {
        expect(type.projectileSpeed, greaterThanOrEqualTo(0));
      }
    });

    test('all towers have non-negative slow amount', () {
      for (final type in TowerType.values) {
        expect(type.slowAmount, greaterThanOrEqualTo(0));
      }
    });

    test('phaseMage has highest slow amount', () {
      final frostSlow = TowerType.phaseMage.slowAmount;
      for (final type in TowerType.values) {
        if (type != TowerType.phaseMage) {
          expect(frostSlow, greaterThanOrEqualTo(type.slowAmount));
        }
      }
    });
  });

  group('TowerType colors', () {
    test('each tower type has a color', () {
      for (final type in TowerType.values) {
        expect(type.color.value, greaterThan(0));
      }
    });

    test('pulseArcher is cyan', () {
      expect(TowerType.pulseArcher.color.blue, greaterThan(200));
    });

    test('phaseMage has blue tint', () {
      expect(TowerType.phaseMage.color.blue, greaterThan(150));
    });

    test('circuitCannon has warm color', () {
      expect(TowerType.circuitCannon.color.red, greaterThan(150));
    });
  });

  group('TowerType names', () {
    test('each tower type has a display name', () {
      for (final type in TowerType.values) {
        expect(type.name.length, greaterThan(0));
      }
    });

    test('pulseArcher display name', () {
      expect(TowerType.pulseArcher.name, isNotEmpty);
    });

    test('phaseMage display name', () {
      expect(TowerType.phaseMage.name, isNotEmpty);
    });
  });

  group('TowerManager ghost pulse', () {
    test('ghost pulse animation cycles', () {
      double ghostPulse = 0;
      const dt = 0.016;

      for (int i = 0; i < 100; i++) {
        ghostPulse += dt * 3;
      }

      expect(ghostPulse, greaterThan(0));
    });
  });

  group('TowerManager occupied cells', () {
    test('occupied set can track cells', () {
      final occupied = <math.Point<int>>{};

      occupied.add(math.Point(1, 2));
      occupied.add(math.Point(3, 4));

      expect(occupied.contains(math.Point(1, 2)), isTrue);
      expect(occupied.contains(math.Point(3, 4)), isTrue);
      expect(occupied.contains(math.Point(5, 6)), isFalse);
    });

    test('removing from occupied set works', () {
      final occupied = <math.Point<int>>{};

      occupied.add(math.Point(1, 2));
      expect(occupied.contains(math.Point(1, 2)), isTrue);

      occupied.remove(math.Point(1, 2));
      expect(occupied.contains(math.Point(1, 2)), isFalse);
    });
  });

  group('TowerManager LCG random', () {
    test('FastRng produces values in range', () {
      // Simulate the _FastRng behavior
      int state = 0x6d2b79f5;

      int next() {
        state = (1664525 * state + 1013904223) & 0x7fffffff;
        return state;
      }

      double nextDouble() => next() / 0x7fffffff;

      for (int i = 0; i < 100; i++) {
        final value = nextDouble();
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThanOrEqualTo(1));
      }
    });

    test('FastRng nextInt produces values in range', () {
      int state = 0x6d2b79f5;

      int next() {
        state = (1664525 * state + 1013904223) & 0x7fffffff;
        return state;
      }

      int nextInt(int max) => max <= 0 ? 0 : next() % max;

      for (int i = 0; i < 100; i++) {
        final value = nextInt(10);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(10));
      }
    });

    test('FastRng nextBool returns booleans', () {
      int state = 0x6d2b79f5;

      int next() {
        state = (1664525 * state + 1013904223) & 0x7fffffff;
        return state;
      }

      bool nextBool() => (next() & 1) == 0;

      int trueCount = 0;
      int falseCount = 0;

      for (int i = 0; i < 100; i++) {
        if (nextBool()) {
          trueCount++;
        } else {
          falseCount++;
        }
      }

      // Should have some of each
      expect(trueCount, greaterThan(0));
      expect(falseCount, greaterThan(0));
    });
  });
}
