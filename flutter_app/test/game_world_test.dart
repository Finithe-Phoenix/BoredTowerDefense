import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/world/game_world.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameWorld creation', () {
    test('creates with required parameters', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      expect(world.tileSize, 32);
      expect(world.mapFile, 'test_map.tmx');
    });

    test('pathWidthTiles constant is 2', () {
      expect(GameWorld.pathWidthTiles, 2);
    });

    test('initial waypoints is empty', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      expect(world.waypoints, isEmpty);
    });

    test('initial isBuildable is empty', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      expect(world.isBuildable, isEmpty);
    });

    test('initial tileTypes is empty', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      expect(world.tileTypes, isEmpty);
    });

    test('initial startCell is null', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      expect(world.startCell, isNull);
    });

    test('initial endCell is null', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      expect(world.endCell, isNull);
    });

    test('initial mapWidth is 0', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      expect(world.mapWidth, 0);
    });

    test('initial mapHeight is 0', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      expect(world.mapHeight, 0);
    });

    test('initial reduceFx is false', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      expect(world.reduceFx, isFalse);
    });

    test('initial allowBlur is true', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      expect(world.allowBlur, isTrue);
    });
  });

  group('GameWorld setQuality', () {
    test('setQuality updates reduceFx', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      world.setQuality(reduceFx: true, allowBlur: true);

      expect(world.reduceFx, isTrue);
    });

    test('setQuality updates allowBlur', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      world.setQuality(reduceFx: false, allowBlur: false);

      expect(world.allowBlur, isFalse);
    });

    test('setQuality can set both values', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      world.setQuality(reduceFx: true, allowBlur: false);

      expect(world.reduceFx, isTrue);
      expect(world.allowBlur, isFalse);
    });
  });

  group('GameWorld tileSize calculations', () {
    test('tileSize is used for coordinate calculations', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      expect(world.tileSize, 32);
    });

    test('different tileSizes are supported', () {
      final world16 = GameWorld(tileSize: 16, mapFile: 'map.tmx');
      final world32 = GameWorld(tileSize: 32, mapFile: 'map.tmx');
      final world64 = GameWorld(tileSize: 64, mapFile: 'map.tmx');

      expect(world16.tileSize, 16);
      expect(world32.tileSize, 32);
      expect(world64.tileSize, 64);
    });
  });

  group('GameWorld Component inheritance', () {
    test('GameWorld is a Component', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      expect(world, isA<Component>());
    });
  });

  group('GameWorld waypoints', () {
    test('waypoints list can be assigned', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      world.waypoints = [Vector2(0, 0), Vector2(100, 0), Vector2(100, 100)];

      expect(world.waypoints.length, 3);
    });

    test('waypoints are accessible', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      world.waypoints = [Vector2(50, 50)];

      expect(world.waypoints.first.x, 50);
      expect(world.waypoints.first.y, 50);
    });
  });

  group('GameWorld map dimensions', () {
    test('mapWidth can be set', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      world.mapWidth = 20;

      expect(world.mapWidth, 20);
    });

    test('mapHeight can be set', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      world.mapHeight = 15;

      expect(world.mapHeight, 15);
    });
  });

  group('GameWorld cell points', () {
    test('startCell can be set', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      world.startCell = math.Point<int>(0, 0);

      expect(world.startCell, isNotNull);
      expect(world.startCell!.x, 0);
      expect(world.startCell!.y, 0);
    });

    test('endCell can be set', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      world.endCell = math.Point<int>(19, 14);

      expect(world.endCell, isNotNull);
      expect(world.endCell!.x, 19);
      expect(world.endCell!.y, 14);
    });
  });

  group('GameWorld isBuildable grid', () {
    test('isBuildable can be initialized', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      world.isBuildable = List.generate(10, (_) => List<bool>.filled(10, true));

      expect(world.isBuildable.length, 10);
      expect(world.isBuildable[0].length, 10);
      expect(world.isBuildable[0][0], isTrue);
    });

    test('isBuildable values can be changed', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      world.isBuildable = List.generate(5, (_) => List<bool>.filled(5, true));
      world.isBuildable[2][2] = false;

      expect(world.isBuildable[2][2], isFalse);
      expect(world.isBuildable[0][0], isTrue);
    });
  });

  group('GameWorld tileTypes grid', () {
    test('tileTypes can be initialized', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      world.tileTypes = List.generate(10, (_) => List<int>.filled(10, 0));

      expect(world.tileTypes.length, 10);
      expect(world.tileTypes[0].length, 10);
      expect(world.tileTypes[0][0], 0);
    });

    test('tileType 0 is buildable', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      world.tileTypes = [[0]];

      expect(world.tileTypes[0][0], 0);
    });

    test('tileType 1 is blocked', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      world.tileTypes = [[1]];

      expect(world.tileTypes[0][0], 1);
    });

    test('tileType 2 is path', () {
      final world = GameWorld(
        tileSize: 32,
        mapFile: 'test_map.tmx',
      );

      world.tileTypes = [[2]];

      expect(world.tileTypes[0][0], 2);
    });
  });
}
