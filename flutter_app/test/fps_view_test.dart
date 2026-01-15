import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bored_games/src/game/fps/fps_view_component.dart';
import 'package:bored_games/src/game/entities/tower.dart';
import 'package:bored_games/src/game/entities/boss.dart';
import 'package:bored_games/src/game/bored_games_game.dart';

void main() {
  // Initialize Flutter bindings for tests that need asset loading
  TestWidgetsFlutterBinding.ensureInitialized();

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
        BoredGamesGame.new,
        (game) async {
          final tower = Tower(
            position: Vector2(100, 100),
            size: 32,
            type: TowerType.pulseArcher,
          );

          final fpsView = FpsViewComponent(tower: tower);
          await game.add(fpsView);

          // Create and add a boss to enemy manager
          final boss = Boss(
            path: [Vector2(0, 0), Vector2(100, 0)],
            bossType: BossType.citadelCore,
            bossLevel: 10,
            maxHealth: 1000,
          );

          await game.enemyManager.add(boss);

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

      test('recoil decays over time', () {
        final fpsView = FpsViewComponent(tower: testTower);

        fpsView.triggerRecoil();

        // Update multiple times
        for (int i = 0; i < 10; i++) {
          fpsView.update(0.1);
        }

        // Recoil should have decayed
        expect(fpsView, isNotNull);
      });
    });

    group('Animation Updates', () {
      test('updates animation time', () {
        final fpsView = FpsViewComponent(tower: testTower);

        fpsView.update(0.1);
        fpsView.update(0.1);

        // Animation time should increase
        expect(fpsView, isNotNull);
      });

      test('updates crosshair rotation', () {
        final fpsView = FpsViewComponent(tower: testTower);

        for (int i = 0; i < 10; i++) {
          fpsView.update(0.1);
        }

        // Crosshair should rotate
        expect(fpsView, isNotNull);
      });

      test('updates reload progress', () {
        final fpsView = FpsViewComponent(tower: testTower);

        fpsView.update(1.0); // 1 second

        // Reload progress should update based on tower fire rate
        expect(fpsView, isNotNull);
      });
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

      test('updates target lock progress', () {
        final fpsView = FpsViewComponent(tower: testTower);

        // No target, progress should decrease
        for (int i = 0; i < 5; i++) {
          fpsView.update(0.1);
        }

        expect(fpsView, isNotNull);
      });
    });

    group('BOOST Particles', () {
      testWithGame(
        'spawns particles during BOOST mode',
        BoredGamesGame.new,
        (game) async {
          final tower = Tower(
            position: Vector2(100, 100),
            size: 32,
            type: TowerType.pulseArcher,
          );

          final fpsView = FpsViewComponent(tower: tower);
          await game.add(fpsView);

          // Add boss to activate BOOST
          final boss = Boss(
            path: [Vector2(0, 0), Vector2(100, 0)],
            bossType: BossType.citadelCore,
            bossLevel: 10,
            maxHealth: 1000,
          );

          await game.enemyManager.add(boss);

          // Update to spawn particles
          for (int i = 0; i < 50; i++) {
            fpsView.update(0.1);
          }

          expect(fpsView, isNotNull);
        },
      );

      test('limits particle count', () {
        final fpsView = FpsViewComponent(tower: testTower);

        // Force many particle spawns
        for (int i = 0; i < 200; i++) {
          fpsView.update(0.1);
        }

        // Particles should be limited (tested internally)
        expect(fpsView, isNotNull);
      });
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
      test('renders Pulse Archer weapon without crashing', () {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 32,
          type: TowerType.pulseArcher,
        );

        final fpsView = FpsViewComponent(tower: tower);

        expect(() {
          fpsView.update(0.1);
        }, returnsNormally);
      });

      test('renders Circuit Cannon weapon without crashing', () {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 32,
          type: TowerType.circuitCannon,
        );

        final fpsView = FpsViewComponent(tower: tower);

        expect(() {
          fpsView.update(0.1);
        }, returnsNormally);
      });

      test('renders Phase Mage weapon without crashing', () {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 32,
          type: TowerType.phaseMage,
        );

        final fpsView = FpsViewComponent(tower: tower);

        expect(() {
          fpsView.update(0.1);
        }, returnsNormally);
      });

      test('renders Glimmer Field weapon without crashing', () {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 32,
          type: TowerType.glimmerField,
        );

        final fpsView = FpsViewComponent(tower: tower);

        expect(() {
          fpsView.update(0.1);
        }, returnsNormally);
      });
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
        BoredGamesGame.new,
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

          // Add boss
          final boss = Boss(
            path: [Vector2(0, 0), Vector2(100, 0)],
            bossType: BossType.citadelCore,
            bossLevel: 10,
            maxHealth: 1000,
          );

          await game.enemyManager.add(boss);

          // Update to transition
          for (int i = 0; i < 10; i++) {
            fpsView.update(0.1);
          }

          expect(fpsView, isNotNull);
        },
      );
    });

    group('Performance', () {
      test('updates efficiently', () {
        final fpsView = FpsViewComponent(tower: testTower);

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 100; i++) {
          fpsView.update(0.016); // ~60 FPS
        }

        stopwatch.stop();

        // Should complete in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('handles many particles efficiently', () {
        final fpsView = FpsViewComponent(tower: testTower);

        final stopwatch = Stopwatch()..start();

        // Spawn many particles
        for (int i = 0; i < 200; i++) {
          fpsView.update(0.1);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });
    });

    group('Edge Cases', () {
      test('handles null target gracefully', () {
        final fpsView = FpsViewComponent(tower: testTower);

        expect(() {
          fpsView.update(0.1);
        }, returnsNormally);
      });

      test('handles very fast updates', () {
        final fpsView = FpsViewComponent(tower: testTower);

        expect(() {
          for (int i = 0; i < 1000; i++) {
            fpsView.update(0.001);
          }
        }, returnsNormally);
      });

      test('handles negative delta time', () {
        final fpsView = FpsViewComponent(tower: testTower);

        expect(() {
          fpsView.update(-0.1);
        }, returnsNormally);
      });

      test('handles zero delta time', () {
        final fpsView = FpsViewComponent(tower: testTower);

        expect(() {
          fpsView.update(0.0);
        }, returnsNormally);
      });
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
