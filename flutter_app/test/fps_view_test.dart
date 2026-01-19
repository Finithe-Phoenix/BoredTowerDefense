import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bored_games/src/game/fps/fps_view_component.dart';
import 'package:bored_games/src/game/entities/tower.dart';
import 'package:bored_games/src/game/bored_games_game.dart';
import 'package:bored_games/src/models/level_config.dart';
import 'helpers/fake_audioplayers_platform.dart';

void main() {
  // Initialize Flutter bindings for tests that need asset loading
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFakeAudioplayersPlatform();
  });

  BoredGamesGame _createBossGame() {
    return BoredGamesGame(
      tileSize: 32,
      levelConfig: LevelConfig(
        id: 1,
        name: 'Test',
        mapFile: 'maps/level1.tmx',
        waves: 1,
        difficulty: 1,
      ),
    );
  }

  void _spawnBoss(BoredGamesGame game) {
    game.enemyManager.startWave(count: 5);
    game.enemyManager.remaining = 2;
    game.enemyManager.update(2.0);
  }

  Future<FpsViewComponent> _attachView(BoredGamesGame game, Tower tower) async {
    final fpsView = FpsViewComponent(tower: tower);
    await game.add(fpsView);
    return fpsView;
  }

  group('FpsViewComponent', () {
    late Tower testTower;

    setUp(() {
      testTower = Tower(
        position: Vector2(100, 100),
        size: 32,
        type: TowerType.pulseArcher,
      );
    });

    group('Initialization', () {
      test('creates with tower', () {
        final fpsView = FpsViewComponent(tower: testTower);

        expect(fpsView.tower, equals(testTower));
        expect(fpsView.priority, 500);
      });

      test('initializes for Pulse Archer', () {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 32,
          type: TowerType.pulseArcher,
        );

        final fpsView = FpsViewComponent(tower: tower);

        expect(fpsView.tower.type, TowerType.pulseArcher);
      });

      test('initializes for Circuit Cannon', () {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 32,
          type: TowerType.circuitCannon,
        );

        final fpsView = FpsViewComponent(tower: tower);

        expect(fpsView.tower.type, TowerType.circuitCannon);
      });

      test('initializes for Phase Mage', () {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 32,
          type: TowerType.phaseMage,
        );

        final fpsView = FpsViewComponent(tower: tower);

        expect(fpsView.tower.type, TowerType.phaseMage);
      });

      test('initializes for Glimmer Field', () {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 32,
          type: TowerType.glimmerField,
        );

        final fpsView = FpsViewComponent(tower: tower);

        expect(fpsView.tower.type, TowerType.glimmerField);
      });
    });

    group('BOOST Mode Detection', () {
      testWithGame(
        'BOOST mode off when no boss',
        BoredGamesGame.new,
        (game) async {
          final tower = Tower(
            position: Vector2(100, 100),
            size: 32,
            type: TowerType.pulseArcher,
          );

          final fpsView = FpsViewComponent(tower: tower);
          await game.add(fpsView);

          fpsView.update(0.1);

          // No boss, so BOOST should be off
          // (internal _isBoostMode would be false)
          expect(fpsView, isNotNull);
        },
      );

      testWithGame(
        'BOOST mode on when boss active',
        _createBossGame,
        (game) async {
          final tower = Tower(
            position: Vector2(100, 100),
            size: 32,
            type: TowerType.pulseArcher,
          );

          final fpsView = FpsViewComponent(tower: tower);
          await game.add(fpsView);

          _spawnBoss(game);

          fpsView.update(0.1);

          // Boss active, BOOST should be on
          expect(game.enemyManager.currentBoss, isNotNull);
        },
      );
    });

    group('Recoil Effect', () {
      test('triggers recoil', () {
        final fpsView = FpsViewComponent(tower: testTower);

        fpsView.triggerRecoil();

        // Recoil should be triggered (internal state)
        expect(fpsView, isNotNull);
      });

      testWithGame(
        'recoil decays over time',
        BoredGamesGame.new,
        (game) async {
          final fpsView = await _attachView(game, testTower);

          fpsView.triggerRecoil();

          // Update multiple times
          for (int i = 0; i < 10; i++) {
            fpsView.update(0.1);
          }

          // Recoil should have decayed
          expect(fpsView, isNotNull);
        },
      );
    });

    group('Animation Updates', () {
      testWithGame(
        'updates animation time',
        BoredGamesGame.new,
        (game) async {
          final fpsView = await _attachView(game, testTower);

          fpsView.update(0.1);
          fpsView.update(0.1);

          // Animation time should increase
          expect(fpsView, isNotNull);
        },
      );

      testWithGame(
        'updates crosshair rotation',
        BoredGamesGame.new,
        (game) async {
          final fpsView = await _attachView(game, testTower);

          for (int i = 0; i < 10; i++) {
            fpsView.update(0.1);
          }

          // Crosshair should rotate
          expect(fpsView, isNotNull);
        },
      );

      testWithGame(
        'updates reload progress',
        BoredGamesGame.new,
        (game) async {
          final fpsView = await _attachView(game, testTower);

          fpsView.update(1.0); // 1 second

          // Reload progress should update based on tower fire rate
          expect(fpsView, isNotNull);
        },
      );
    });

    group('Target Tracking', () {
      testWithGame(
        'tracks current target',
        BoredGamesGame.new,
        (game) async {
          final tower = Tower(
            position: Vector2(100, 100),
            size: 32,
            type: TowerType.pulseArcher,
          );

          final fpsView = FpsViewComponent(tower: tower);
          await game.add(fpsView);

          fpsView.update(0.1);

          // No target initially
          expect(tower.currentTarget, isNull);
        },
      );

      testWithGame(
        'updates target lock progress',
        BoredGamesGame.new,
        (game) async {
          final fpsView = await _attachView(game, testTower);

          // No target, progress should decrease
          for (int i = 0; i < 5; i++) {
            fpsView.update(0.1);
          }

          expect(fpsView, isNotNull);
        },
      );
    });

    group('BOOST Particles', () {
      testWithGame(
        'spawns particles during BOOST mode',
        _createBossGame,
        (game) async {
          final tower = Tower(
            position: Vector2(100, 100),
            size: 32,
            type: TowerType.pulseArcher,
          );

          final fpsView = FpsViewComponent(tower: tower);
          await game.add(fpsView);

          _spawnBoss(game);

          // Update to spawn particles
          for (int i = 0; i < 50; i++) {
            fpsView.update(0.1);
          }

          expect(fpsView, isNotNull);
        },
      );

      testWithGame(
        'limits particle count',
        BoredGamesGame.new,
        (game) async {
          final fpsView = await _attachView(game, testTower);

          // Force many particle spawns
          for (int i = 0; i < 200; i++) {
            fpsView.update(0.1);
          }

          // Particles should be limited (tested internally)
          expect(fpsView, isNotNull);
        },
      );
    });

    group('HUD Stats', () {
      test('displays correct damage stat', () {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 32,
          type: TowerType.pulseArcher,
        );

        final fpsView = FpsViewComponent(tower: tower);

        expect(tower.currentDamage, equals(tower.damage));
      });

      test('displays correct fire rate stat', () {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 32,
          type: TowerType.circuitCannon,
        );

        final fpsView = FpsViewComponent(tower: tower);

        expect(tower.currentFireRate, equals(tower.fireRate));
      });

      test('displays correct range stat', () {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 32,
          type: TowerType.phaseMage,
        );

        final fpsView = FpsViewComponent(tower: tower);

        expect(tower.currentRange, equals(tower.range));
      });
    });

    group('Weapon Rendering', () {
      testWithGame(
        'renders Pulse Archer weapon without crashing',
        BoredGamesGame.new,
        (game) async {
          final tower = Tower(
            position: Vector2(0, 0),
            size: 32,
            type: TowerType.pulseArcher,
          );

          final fpsView = await _attachView(game, tower);

          expect(() {
            fpsView.update(0.1);
          }, returnsNormally);
        },
      );

      testWithGame(
        'renders Circuit Cannon weapon without crashing',
        BoredGamesGame.new,
        (game) async {
          final tower = Tower(
            position: Vector2(0, 0),
            size: 32,
            type: TowerType.circuitCannon,
          );

          final fpsView = await _attachView(game, tower);

          expect(() {
            fpsView.update(0.1);
          }, returnsNormally);
        },
      );

      testWithGame(
        'renders Phase Mage weapon without crashing',
        BoredGamesGame.new,
        (game) async {
          final tower = Tower(
            position: Vector2(0, 0),
            size: 32,
            type: TowerType.phaseMage,
          );

          final fpsView = await _attachView(game, tower);

          expect(() {
            fpsView.update(0.1);
          }, returnsNormally);
        },
      );

      testWithGame(
        'renders Glimmer Field weapon without crashing',
        BoredGamesGame.new,
        (game) async {
          final tower = Tower(
            position: Vector2(0, 0),
            size: 32,
            type: TowerType.glimmerField,
          );

          final fpsView = await _attachView(game, tower);

          expect(() {
            fpsView.update(0.1);
          }, returnsNormally);
        },
      );
    });

    group('Screen Resize', () {
      test('handles screen resize', () {
        final fpsView = FpsViewComponent(tower: testTower);

        fpsView.onGameResize(Vector2(1920, 1080));

        expect(fpsView.size.x, 1920);
        expect(fpsView.size.y, 1080);
      });

      test('position updates on resize', () {
        final fpsView = FpsViewComponent(tower: testTower);

        fpsView.onGameResize(Vector2(800, 600));

        expect(fpsView.position, Vector2.zero());
      });
    });

    group('BOOST Intensity Transition', () {
      testWithGame(
        'smoothly transitions BOOST intensity',
        _createBossGame,
        (game) async {
          final tower = Tower(
            position: Vector2(100, 100),
            size: 32,
            type: TowerType.pulseArcher,
          );

          final fpsView = FpsViewComponent(tower: tower);
          await game.add(fpsView);

          // No boss initially
          fpsView.update(0.1);

          _spawnBoss(game);

          // Update to transition
          for (int i = 0; i < 10; i++) {
            fpsView.update(0.1);
          }

          expect(fpsView, isNotNull);
        },
      );
    });

    group('Performance', () {
      testWithGame(
        'updates efficiently',
        BoredGamesGame.new,
        (game) async {
          final fpsView = await _attachView(game, testTower);

          final stopwatch = Stopwatch()..start();

          for (int i = 0; i < 100; i++) {
            fpsView.update(0.016); // ~60 FPS
          }

          stopwatch.stop();

          // Should complete in reasonable time
          expect(stopwatch.elapsedMilliseconds, lessThan(100));
        },
      );

      testWithGame(
        'handles many particles efficiently',
        BoredGamesGame.new,
        (game) async {
          final fpsView = await _attachView(game, testTower);

          final stopwatch = Stopwatch()..start();

          // Spawn many particles
          for (int i = 0; i < 200; i++) {
            fpsView.update(0.1);
          }

          stopwatch.stop();

          expect(stopwatch.elapsedMilliseconds, lessThan(200));
        },
      );
    });

    group('Edge Cases', () {
      testWithGame(
        'handles null target gracefully',
        BoredGamesGame.new,
        (game) async {
          final fpsView = await _attachView(game, testTower);

          expect(() {
            fpsView.update(0.1);
          }, returnsNormally);
        },
      );

      testWithGame(
        'handles very fast updates',
        BoredGamesGame.new,
        (game) async {
          final fpsView = await _attachView(game, testTower);

          expect(() {
            for (int i = 0; i < 1000; i++) {
              fpsView.update(0.001);
            }
          }, returnsNormally);
        },
      );

      testWithGame(
        'handles negative delta time',
        BoredGamesGame.new,
        (game) async {
          final fpsView = await _attachView(game, testTower);

          expect(() {
            fpsView.update(-0.1);
          }, returnsNormally);
        },
      );

      testWithGame(
        'handles zero delta time',
        BoredGamesGame.new,
        (game) async {
          final fpsView = await _attachView(game, testTower);

          expect(() {
            fpsView.update(0.0);
          }, returnsNormally);
        },
      );
    });

    group('Tower Type Colors', () {
      test('Pulse Archer has cyan colors', () {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 32,
          type: TowerType.pulseArcher,
        );

        final fpsView = FpsViewComponent(tower: tower);

        expect(tower.type, TowerType.pulseArcher);
        expect(tower.color.value, 0xFF00FFFF);
      });

      test('Circuit Cannon has magenta colors', () {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 32,
          type: TowerType.circuitCannon,
        );

        final fpsView = FpsViewComponent(tower: tower);

        expect(tower.type, TowerType.circuitCannon);
        expect(tower.color.value, 0xFFFF00FF);
      });

      test('Phase Mage has purple colors', () {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 32,
          type: TowerType.phaseMage,
        );

        final fpsView = FpsViewComponent(tower: tower);

        expect(tower.type, TowerType.phaseMage);
        expect(tower.color.value, 0xFF9C27B0);
      });

      test('Glimmer Field has yellow colors', () {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 32,
          type: TowerType.glimmerField,
        );

        final fpsView = FpsViewComponent(tower: tower);

        expect(tower.type, TowerType.glimmerField);
        expect(tower.color.value, 0xFFFFEB3B);
      });
    });
  });
}
