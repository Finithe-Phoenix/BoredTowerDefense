import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/bored_games_game.dart';
import 'package:bored_games/src/game/effects/shaders/shader_uniform_controller.dart';
import 'package:bored_games/src/game/entities/enemy.dart';
import 'package:bored_games/src/game/entities/tower.dart';
import 'package:bored_games/src/game/managers/enemy_manager.dart';
import 'package:bored_games/src/game/managers/tower_manager.dart';
import 'package:bored_games/src/game/world/game_world.dart';
import 'package:bored_games/src/models/quality_level.dart';

class _DummyWorld extends GameWorld {
  _DummyWorld({required double tileSize})
      : super(
          tileSize: tileSize,
          mapFile: 'assets/tiles/maps/level_01.tmx',
        ) {
    waypoints = <Vector2>[
      Vector2(tileSize, tileSize),
      Vector2(tileSize * 8, tileSize),
      Vector2(tileSize * 8, tileSize * 8),
    ];
    isBuildable = List<List<bool>>.generate(
      20,
      (_) => List<bool>.filled(20, true),
    );
  }

  @override
  Future<void> onLoad() async {}
}

class _FakeTowerManager extends TowerManager {
  _FakeTowerManager({required super.tileSize, required super.world});

  final List<Tower> mockTowers = <Tower>[];

  @override
  List<Tower> get towers => mockTowers;

  @override
  int get towerCount => mockTowers.length;
}

class _FakeEnemyManager extends EnemyManager {
  _FakeEnemyManager({required super.tileSize, required super.world});

  final List<Enemy> mockEnemies = <Enemy>[];

  @override
  List<Enemy> get activeEnemies => mockEnemies;

  @override
  int get aliveCount => mockEnemies.length;
}

class _ShaderTestGame extends BoredGamesGame {
  _ShaderTestGame({
    required this.fakeWorld,
    required this.fakeTowerManager,
    required this.fakeEnemyManager,
    Vector2? mockSize,
  })  : _mockSize = mockSize ?? Vector2(1280, 720),
        super(tileSize: 32);

  final _DummyWorld fakeWorld;
  final _FakeTowerManager fakeTowerManager;
  final _FakeEnemyManager fakeEnemyManager;
  final Vector2 _mockSize;

  QualityLevel qualityValue = QualityLevel.high;

  @override
  QualityLevel get quality => qualityValue;

  @override
  Vector2 get size => _mockSize;

  @override
  GameWorld get worldLayer => fakeWorld;

  @override
  TowerManager get towerManager => fakeTowerManager;

  @override
  EnemyManager get enemyManager => fakeEnemyManager;

  @override
  Future<void> onLoad() async {}

  @override
  void update(double dt) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mountController(
    WidgetTester tester,
    _ShaderTestGame game,
    ShaderUniformController controller,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: game.size.x,
          height: game.size.y,
          child: GameWidget(game: game),
        ),
      ),
    );
    await tester.pump();
    await game.add(controller);
    await tester.pump();
  }

  Tower _towerAt(double x, double y) => Tower(
        position: Vector2(x, y),
        size: 32,
        type: TowerType.pulseArcher,
      );

  Enemy _enemyAt(double x, double y) => Enemy(
        path: <Vector2>[Vector2.zero(), Vector2(120, 0)],
        startPosition: Vector2(x, y),
      );

  group('ShaderUniformController integration', () {
    late _DummyWorld world;
    late _FakeTowerManager towerManager;
    late _FakeEnemyManager enemyManager;
    late _ShaderTestGame game;
    late ShaderUniformController controller;

    setUp(() {
      world = _DummyWorld(tileSize: 32);
      towerManager = _FakeTowerManager(tileSize: 32, world: world);
      enemyManager = _FakeEnemyManager(tileSize: 32, world: world);
      game = _ShaderTestGame(
        fakeWorld: world,
        fakeTowerManager: towerManager,
        fakeEnemyManager: enemyManager,
      );
      controller = ShaderUniformController();
    });

    testWidgets('low quality disables entity tracking', (tester) async {
      game.qualityValue = QualityLevel.low;
      for (int i = 0; i < 8; i++) {
        towerManager.mockTowers.add(_towerAt(64 + i * 8, 80 + i * 4));
        enemyManager.mockEnemies.add(_enemyAt(120 + i * 6, 130 + i * 5));
      }

      await mountController(tester, game, controller);
      controller.update(ShaderUniformController.updateInterval + 0.01);

      expect(controller.towerCount, 0);
      expect(controller.enemyCount, 0);
    });

    testWidgets('medium quality caps entities to 6 and writes buffers',
        (tester) async {
      game.qualityValue = QualityLevel.medium;
      for (int i = 0; i < 9; i++) {
        towerManager.mockTowers.add(_towerAt(50 + i * 10, 90 + i * 7));
        enemyManager.mockEnemies.add(_enemyAt(150 + i * 8, 170 + i * 5));
      }

      await mountController(tester, game, controller);
      controller.update(ShaderUniformController.updateInterval + 0.01);

      expect(controller.towerCount, 6);
      expect(controller.enemyCount, 6);
      expect(controller.towerPositionBuffer[0], greaterThan(0));
      expect(controller.towerPositionBuffer[1], greaterThan(0));
      expect(controller.enemyPositionBuffer[0], greaterThan(0));
      expect(controller.enemyPositionBuffer[1], greaterThan(0));
    });

    testWidgets('high quality uses max entity limit of 10', (tester) async {
      game.qualityValue = QualityLevel.high;
      for (int i = 0; i < 14; i++) {
        towerManager.mockTowers.add(_towerAt(30 + i * 9, 60 + i * 6));
        enemyManager.mockEnemies.add(_enemyAt(90 + i * 7, 110 + i * 4));
      }

      await mountController(tester, game, controller);
      controller.update(ShaderUniformController.updateInterval + 0.01);

      expect(controller.towerCount, ShaderUniformController.maxEntities);
      expect(controller.enemyCount, ShaderUniformController.maxEntities);
    });

    testWidgets('update is rate limited by interval', (tester) async {
      game.qualityValue = QualityLevel.high;
      towerManager.mockTowers.add(_towerAt(90, 100));
      enemyManager.mockEnemies.add(_enemyAt(220, 240));

      await mountController(tester, game, controller);

      controller.update(ShaderUniformController.updateInterval * 0.4);
      expect(controller.towerCount, 0);
      expect(controller.enemyCount, 0);

      controller.update(ShaderUniformController.updateInterval * 0.4);
      expect(controller.towerCount, 0);
      expect(controller.enemyCount, 0);

      controller.update(ShaderUniformController.updateInterval * 0.3);
      expect(controller.towerCount, 1);
      expect(controller.enemyCount, 1);
    });

    testWidgets('counts reset when entities disappear after prior frame',
        (tester) async {
      game.qualityValue = QualityLevel.high;
      towerManager.mockTowers.add(_towerAt(120, 130));
      enemyManager.mockEnemies.add(_enemyAt(200, 210));

      await mountController(tester, game, controller);
      controller.update(ShaderUniformController.updateInterval + 0.01);
      expect(controller.towerCount, 1);
      expect(controller.enemyCount, 1);

      towerManager.mockTowers.clear();
      enemyManager.mockEnemies.clear();
      controller.update(ShaderUniformController.updateInterval + 0.01);

      expect(controller.towerCount, 0);
      expect(controller.enemyCount, 0);
    });

    testWidgets('disabled controller skips updates', (tester) async {
      game.qualityValue = QualityLevel.high;
      towerManager.mockTowers.add(_towerAt(70, 80));
      enemyManager.mockEnemies.add(_enemyAt(160, 170));

      await mountController(tester, game, controller);
      controller.enabled = false;
      controller.update(ShaderUniformController.updateInterval + 0.2);

      expect(controller.towerCount, 0);
      expect(controller.enemyCount, 0);
    });
  });
}
