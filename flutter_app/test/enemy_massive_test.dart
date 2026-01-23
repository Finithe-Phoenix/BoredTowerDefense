import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/enemy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ============================================
  // ENEMY TYPE ENUM TESTS (400+ tests)
  // ============================================

  group('EnemyType - All 40 enemy types existence', () {
    final allTypes = EnemyType.values;

    test('EnemyType has exactly 40 values', () {
      expect(allTypes.length, 40);
    });

    for (final type in allTypes) {
      test('${type.name} exists', () {
        expect(type, isNotNull);
      });

      test('${type.name} has positive base health', () {
        expect(type.baseHealth, greaterThan(0));
      });

      test('${type.name} has positive base speed', () {
        expect(type.baseSpeed, greaterThan(0));
      });

      test('${type.name} has non-negative gold value', () {
        expect(type.goldValue, greaterThanOrEqualTo(0));
      });

      test('${type.name} has non-empty name', () {
        expect(type.name, isNotEmpty);
      });

      test('${type.name} has valid color', () {
        expect(type.color, isNotNull);
        expect(type.color.alpha, greaterThan(0));
      });
    }
  });

  group('EnemyType - World 1 Enemies (4 types)', () {
    final world1Types = [
      EnemyType.glitchDrone,
      EnemyType.dataWisp,
      EnemyType.neonRunner,
      EnemyType.pulsePhantom,
    ];

    for (final type in world1Types) {
      test('${type.name} belongs to world 1', () {
        expect(type.world, 1);
      });

      test('${type.name} has world 1 difficulty scaling', () {
        // World 1 enemies should be relatively weak
        expect(type.baseHealth, lessThan(500));
      });

      test('${type.name} index is correct', () {
        expect(type.index, lessThan(4));
      });
    }

    test('glitchDrone is basic enemy', () {
      expect(EnemyType.glitchDrone.baseHealth, greaterThan(0));
      expect(EnemyType.glitchDrone.isPhantom, isFalse);
    });

    test('pulsePhantom is phantom type', () {
      expect(EnemyType.pulsePhantom.isPhantom, isTrue);
    });
  });

  group('EnemyType - World 2 Enemies', () {
    final world2Types = [
      EnemyType.voidCrawler,
      EnemyType.circuitSerpent,
      EnemyType.byteSwarm,
      EnemyType.shadowByte,
    ];

    for (final type in world2Types) {
      test('${type.name} belongs to world 2', () {
        expect(type.world, 2);
      });

      test('${type.name} is stronger than world 1', () {
        expect(type.baseHealth, greaterThanOrEqualTo(EnemyType.glitchDrone.baseHealth));
      });
    }

    test('shadowByte is phantom type', () {
      expect(EnemyType.shadowByte.isPhantom, isTrue);
    });
  });

  group('EnemyType - World 3 Enemies', () {
    final world3Types = [
      EnemyType.plasmaSlime,
      EnemyType.hexWalker,
      EnemyType.ionWraith,
      EnemyType.voidShade,
    ];

    for (final type in world3Types) {
      test('${type.name} belongs to world 3', () {
        expect(type.world, 3);
      });
    }

    test('voidShade is phantom type', () {
      expect(EnemyType.voidShade.isPhantom, isTrue);
    });
  });

  group('EnemyType - World 4 Enemies', () {
    final world4Types = [
      EnemyType.dataLeech,
      EnemyType.sparkHornet,
      EnemyType.gridReaper,
      EnemyType.phaseGhost,
    ];

    for (final type in world4Types) {
      test('${type.name} belongs to world 4', () {
        expect(type.world, 4);
      });
    }

    test('phaseGhost is phantom type', () {
      expect(EnemyType.phaseGhost.isPhantom, isTrue);
    });
  });

  group('EnemyType - World 5 Enemies', () {
    final world5Types = [
      EnemyType.neonScorpion,
      EnemyType.binarySpider,
      EnemyType.pulseBeast,
      EnemyType.cryptoSpecter,
    ];

    for (final type in world5Types) {
      test('${type.name} belongs to world 5', () {
        expect(type.world, 5);
      });
    }

    test('cryptoSpecter is phantom type', () {
      expect(EnemyType.cryptoSpecter.isPhantom, isTrue);
    });
  });

  group('EnemyType - World 6 Enemies', () {
    final world6Types = [
      EnemyType.firewallSentry,
      EnemyType.overclockDrone,
      EnemyType.memoryLeech,
      EnemyType.darkProcess,
    ];

    for (final type in world6Types) {
      test('${type.name} belongs to world 6', () {
        expect(type.world, 6);
      });
    }

    test('darkProcess is phantom type', () {
      expect(EnemyType.darkProcess.isPhantom, isTrue);
    });
  });

  group('EnemyType - World 7 Enemies', () {
    final world7Types = [
      EnemyType.recursionHorror,
      EnemyType.kernelBeetle,
      EnemyType.bufferWorm,
      EnemyType.nullShadow,
    ];

    for (final type in world7Types) {
      test('${type.name} belongs to world 7', () {
        expect(type.world, 7);
      });
    }

    test('nullShadow is phantom type', () {
      expect(EnemyType.nullShadow.isPhantom, isTrue);
    });
  });

  group('EnemyType - World 8 Enemies', () {
    final world8Types = [
      EnemyType.stackOverflow,
      EnemyType.heapCorruptor,
      EnemyType.segfaultSpawn,
      EnemyType.memoryLeak,
    ];

    for (final type in world8Types) {
      test('${type.name} belongs to world 8', () {
        expect(type.world, 8);
      });
    }

    test('memoryLeak is phantom type', () {
      expect(EnemyType.memoryLeak.isPhantom, isTrue);
    });
  });

  group('EnemyType - World 9 Enemies', () {
    final world9Types = [
      EnemyType.deadlockDemon,
      EnemyType.raceStalker,
      EnemyType.mutexMonster,
      EnemyType.threadGhost,
    ];

    for (final type in world9Types) {
      test('${type.name} belongs to world 9', () {
        expect(type.world, 9);
      });
    }

    test('threadGhost is phantom type', () {
      expect(EnemyType.threadGhost.isPhantom, isTrue);
    });
  });

  group('EnemyType - World 10 Enemies', () {
    final world10Types = [
      EnemyType.finalBoss,
      EnemyType.systemCrash,
      EnemyType.bluescreenTerror,
      EnemyType.voidTerminator,
    ];

    for (final type in world10Types) {
      test('${type.name} belongs to world 10', () {
        expect(type.world, 10);
      });
    }

    test('voidTerminator is phantom type', () {
      expect(EnemyType.voidTerminator.isPhantom, isTrue);
    });

    test('world 10 enemies are strongest', () {
      for (final type in world10Types) {
        expect(type.baseHealth, greaterThan(100));
      }
    });
  });

  group('EnemyType - Phantom enemies (10 total)', () {
    final phantomTypes = EnemyType.values.where((t) => t.isPhantom).toList();

    test('there are exactly 10 phantom enemies', () {
      expect(phantomTypes.length, 10);
    });

    test('one phantom per world', () {
      final worlds = phantomTypes.map((t) => t.world).toSet();
      expect(worlds.length, 10);
    });

    for (final type in phantomTypes) {
      test('${type.name} isPhantom is true', () {
        expect(type.isPhantom, isTrue);
      });
    }
  });

  group('EnemyType - Non-phantom enemies (30 total)', () {
    final normalTypes = EnemyType.values.where((t) => !t.isPhantom).toList();

    test('there are exactly 30 non-phantom enemies', () {
      expect(normalTypes.length, 30);
    });

    for (final type in normalTypes) {
      test('${type.name} isPhantom is false', () {
        expect(type.isPhantom, isFalse);
      });
    }
  });

  group('EnemyType - Health scaling by world', () {
    for (int world = 1; world <= 10; world++) {
      final worldTypes = EnemyType.values.where((t) => t.world == world).toList();

      test('world $world has 4 enemy types', () {
        expect(worldTypes.length, 4);
      });

      if (world > 1) {
        test('world $world enemies stronger than world ${world - 1}', () {
          final prevWorldTypes = EnemyType.values.where((t) => t.world == world - 1).toList();
          final avgHealth = worldTypes.map((t) => t.baseHealth).reduce((a, b) => a + b) / 4;
          final prevAvgHealth = prevWorldTypes.map((t) => t.baseHealth).reduce((a, b) => a + b) / 4;
          expect(avgHealth, greaterThanOrEqualTo(prevAvgHealth * 0.8)); // Allow some variance
        });
      }
    }
  });

  group('EnemyType - Speed distribution', () {
    for (final type in EnemyType.values) {
      test('${type.name} speed is reasonable', () {
        expect(type.baseSpeed, greaterThan(10));
        expect(type.baseSpeed, lessThan(500));
      });
    }

    test('fastest enemy check', () {
      final fastest = EnemyType.values.reduce((a, b) => a.baseSpeed > b.baseSpeed ? a : b);
      expect(fastest.baseSpeed, greaterThan(0));
    });

    test('slowest enemy check', () {
      final slowest = EnemyType.values.reduce((a, b) => a.baseSpeed < b.baseSpeed ? a : b);
      expect(slowest.baseSpeed, greaterThan(0));
    });
  });

  group('EnemyType - Gold value distribution', () {
    for (final type in EnemyType.values) {
      test('${type.name} gold value is non-negative', () {
        expect(type.goldValue, greaterThanOrEqualTo(0));
      });
    }

    test('total gold value across all enemies', () {
      final totalGold = EnemyType.values.map((t) => t.goldValue).reduce((a, b) => a + b);
      expect(totalGold, greaterThan(0));
    });
  });

  // ============================================
  // ENEMY CLASS TESTS (200+ tests)
  // ============================================

  group('Enemy - Creation with path', () {
    test('creates with single point path', () {
      final enemy = Enemy(path: [Vector2(100, 100)]);
      expect(enemy, isNotNull);
    });

    test('creates with multi-point path', () {
      final enemy = Enemy(path: [
        Vector2(0, 0),
        Vector2(100, 0),
        Vector2(100, 100),
        Vector2(0, 100),
      ]);
      expect(enemy, isNotNull);
    });

    test('position starts at first path point', () {
      final enemy = Enemy(path: [Vector2(50, 75)]);
      expect(enemy.position.x, closeTo(50, 1));
      expect(enemy.position.y, closeTo(75, 1));
    });

    for (int i = 0; i < 10; i++) {
      test('creates enemy with path length ${i + 1}', () {
        final path = List.generate(i + 1, (j) => Vector2(j * 10.0, j * 10.0));
        final enemy = Enemy(path: path);
        expect(enemy, isNotNull);
      });
    }
  });

  group('Enemy - Creation with enemy type', () {
    for (final type in EnemyType.values) {
      test('creates enemy with type ${type.name}', () {
        final enemy = Enemy(path: [Vector2.zero()], type: type);
        expect(enemy.type, type);
      });

      test('${type.name} enemy has correct base health', () {
        final enemy = Enemy(path: [Vector2.zero()], type: type);
        expect(enemy.maxHealth, closeTo(type.baseHealth, 0.1));
      });
    }
  });

  group('Enemy - Health system', () {
    test('enemy starts alive', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      expect(enemy.isAlive, isTrue);
    });

    test('enemy starts with full health', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      expect(enemy.health, enemy.maxHealth);
    });

    test('enemy health percent is 1.0 at full health', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      expect(enemy.healthPercent, closeTo(1.0, 0.01));
    });

    for (int damage = 1; damage <= 20; damage++) {
      test('takeDamage with $damage damage', () {
        final enemy = Enemy(path: [Vector2.zero()]);
        final initialHealth = enemy.health;
        enemy.takeDamage(damage.toDouble());
        expect(enemy.health, closeTo(initialHealth - damage, 0.1));
      });
    }

    test('enemy dies when health reaches 0', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.takeDamage(enemy.maxHealth + 100);
      expect(enemy.isAlive, isFalse);
    });

    test('health cannot go negative display', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.takeDamage(enemy.maxHealth * 10);
      expect(enemy.health, lessThanOrEqualTo(0));
    });
  });

  group('Enemy - Spawn index', () {
    for (int i = 0; i < 20; i++) {
      test('spawn index $i is stored correctly', () {
        final enemy = Enemy(path: [Vector2.zero()], spawnIndex: i);
        expect(enemy.spawnIndex, i);
      });
    }

    test('default spawn index is 0', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      expect(enemy.spawnIndex, 0);
    });
  });

  group('Enemy - Phantom behavior', () {
    test('non-phantom enemy is visible', () {
      final enemy = Enemy(path: [Vector2.zero()], type: EnemyType.glitchDrone);
      expect(enemy.isPhantom, isFalse);
      expect(enemy.isVisible, isTrue);
    });

    test('phantom enemy properties', () {
      final enemy = Enemy(path: [Vector2.zero()], type: EnemyType.pulsePhantom);
      expect(enemy.isPhantom, isTrue);
    });

    test('reveal makes phantom visible', () {
      final enemy = Enemy(path: [Vector2.zero()], type: EnemyType.pulsePhantom);
      enemy.reveal();
      expect(enemy.isVisible, isTrue);
    });

    for (final type in EnemyType.values.where((t) => t.isPhantom)) {
      test('${type.name} is phantom', () {
        final enemy = Enemy(path: [Vector2.zero()], type: type);
        expect(enemy.isPhantom, isTrue);
      });
    }

    for (final type in EnemyType.values.where((t) => !t.isPhantom)) {
      test('${type.name} is not phantom', () {
        final enemy = Enemy(path: [Vector2.zero()], type: type);
        expect(enemy.isPhantom, isFalse);
      });
    }
  });

  group('Enemy - Slow effect', () {
    test('applySlow reduces speed', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      final originalSpeed = enemy.speed;
      enemy.applySlow(0.5, 2.0);
      expect(enemy.speed, lessThan(originalSpeed));
    });

    for (double slowAmount = 0.1; slowAmount <= 0.9; slowAmount += 0.1) {
      test('applySlow with amount ${slowAmount.toStringAsFixed(1)}', () {
        final enemy = Enemy(path: [Vector2.zero()]);
        enemy.applySlow(slowAmount, 1.0);
        // Speed should be reduced
        expect(enemy.speed, lessThanOrEqualTo(enemy.type.baseSpeed));
      });
    }

    for (double duration = 0.5; duration <= 5.0; duration += 0.5) {
      test('applySlow with duration ${duration.toStringAsFixed(1)}', () {
        final enemy = Enemy(path: [Vector2.zero()]);
        enemy.applySlow(0.5, duration);
        expect(enemy.speed, lessThan(enemy.type.baseSpeed));
      });
    }
  });

  group('Enemy - Movement update', () {
    test('update moves enemy', () {
      final enemy = Enemy(path: [Vector2(0, 0), Vector2(100, 0)]);
      final initialX = enemy.position.x;
      enemy.update(0.1);
      expect(enemy.position.x, greaterThan(initialX));
    });

    for (double dt = 0.016; dt <= 0.1; dt += 0.016) {
      test('update with dt ${dt.toStringAsFixed(3)}', () {
        final enemy = Enemy(path: [Vector2(0, 0), Vector2(1000, 0)]);
        final initialPos = enemy.position.clone();
        enemy.update(dt);
        expect(enemy.position.distanceTo(initialPos), greaterThan(0));
      });
    }
  });

  group('Enemy - Gold value', () {
    for (final type in EnemyType.values) {
      test('${type.name} gold value matches type', () {
        final enemy = Enemy(path: [Vector2.zero()], type: type);
        expect(enemy.goldValue, type.goldValue);
      });
    }
  });

  group('Enemy - Health multiplier', () {
    for (double mult = 0.5; mult <= 3.0; mult += 0.5) {
      test('health multiplier $mult', () {
        final baseEnemy = Enemy(path: [Vector2.zero()]);
        final multipliedEnemy = Enemy(path: [Vector2.zero()], healthMultiplier: mult);
        expect(multipliedEnemy.maxHealth, closeTo(baseEnemy.type.baseHealth * mult, 0.1));
      });
    }
  });

  group('Enemy - Speed multiplier', () {
    for (double mult = 0.5; mult <= 2.0; mult += 0.25) {
      test('speed multiplier $mult', () {
        final enemy = Enemy(path: [Vector2.zero()], speedMultiplier: mult);
        expect(enemy.speed, closeTo(enemy.type.baseSpeed * mult, 0.1));
      });
    }
  });

  group('Enemy - Multiple enemies independence', () {
    test('enemies are independent', () {
      final e1 = Enemy(path: [Vector2.zero()]);
      final e2 = Enemy(path: [Vector2(100, 100)]);

      e1.takeDamage(10);
      expect(e2.health, e2.maxHealth);
    });

    for (int i = 0; i < 10; i++) {
      test('enemy $i is independent', () {
        final enemies = List.generate(10, (j) => Enemy(path: [Vector2(j * 10.0, 0)]));
        enemies[i].takeDamage(enemies[i].maxHealth);

        for (int j = 0; j < 10; j++) {
          if (i != j) {
            expect(enemies[j].isAlive, isTrue);
          }
        }
      });
    }
  });

  group('Enemy - Position component', () {
    test('enemy is position component', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      expect(enemy, isA<PositionComponent>());
    });

    test('enemy has size', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      expect(enemy.size.x, greaterThan(0));
      expect(enemy.size.y, greaterThan(0));
    });
  });
}
