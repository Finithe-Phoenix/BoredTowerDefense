import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/enemy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ============================================
  // ENEMY TYPE ENUM TESTS
  // ============================================

  group('EnemyType - All enemy types existence', () {
    final allTypes = EnemyType.values;

    test('EnemyType has 40 values (4 per world × 10 worlds)', () {
      expect(allTypes.length, 40);
    });

    for (final type in allTypes) {
      test('${type.name} exists', () {
        expect(type, isNotNull);
      });

      test('${type.name} has positive health multiplier', () {
        expect(type.healthMult, greaterThan(0));
      });

      test('${type.name} has positive speed multiplier', () {
        expect(type.speedMult, greaterThan(0));
      });

      test('${type.name} has positive size multiplier', () {
        expect(type.sizeMult, greaterThan(0));
      });

      test('${type.name} has non-empty name', () {
        expect(type.name, isNotEmpty);
      });

      test('${type.name} has valid color', () {
        expect(type.color, isNotNull);
      });

      test('${type.name} has valid world (1-10)', () {
        expect(type.world, inInclusiveRange(1, 10));
      });
    }
  });

  group('EnemyType - World 1 Enemies', () {
    final world1Types = [
      EnemyType.runner,
      EnemyType.overloaded,
      EnemyType.juggernaut,
      EnemyType.phantom,
    ];

    for (final type in world1Types) {
      test('${type.name} belongs to world 1', () {
        expect(type.world, 1);
      });
    }

    test('runner is basic enemy (not phantom)', () {
      expect(EnemyType.runner.isPhantom, isFalse);
    });

    test('phantom is phantom type', () {
      expect(EnemyType.phantom.isPhantom, isTrue);
    });

    test('juggernaut is slow but tanky', () {
      expect(EnemyType.juggernaut.speedMult, lessThan(1.0));
      expect(EnemyType.juggernaut.healthMult, greaterThan(2.0));
    });

    test('overloaded is fast but fragile', () {
      expect(EnemyType.overloaded.speedMult, greaterThan(1.0));
      expect(EnemyType.overloaded.healthMult, lessThan(1.0));
    });
  });

  group('EnemyType - World 2 Enemies', () {
    final world2Types = [
      EnemyType.glitcher,
      EnemyType.riftwalker,
      EnemyType.voidling,
      EnemyType.dimensionBreaker,
    ];

    for (final type in world2Types) {
      test('${type.name} belongs to world 2', () {
        expect(type.world, 2);
      });
    }

    test('riftwalker is phantom type', () {
      expect(EnemyType.riftwalker.isPhantom, isTrue);
    });

    test('dimensionBreaker is slow tank', () {
      expect(EnemyType.dimensionBreaker.speedMult, lessThan(1.0));
      expect(EnemyType.dimensionBreaker.healthMult, greaterThan(2.0));
    });
  });

  group('EnemyType - World 3 Enemies', () {
    final world3Types = [
      EnemyType.corruptedByte,
      EnemyType.malware,
      EnemyType.dataWorm,
      EnemyType.virusCarrier,
    ];

    for (final type in world3Types) {
      test('${type.name} belongs to world 3', () {
        expect(type.world, 3);
      });
    }
  });

  group('EnemyType - World 4 Enemies', () {
    final world4Types = [
      EnemyType.sparkDrone,
      EnemyType.plasmaCore,
      EnemyType.ionSurge,
      EnemyType.thunderHulk,
    ];

    for (final type in world4Types) {
      test('${type.name} belongs to world 4', () {
        expect(type.world, 4);
      });
    }

    test('thunderHulk is the tankiest in world 4', () {
      expect(EnemyType.thunderHulk.healthMult, greaterThan(3.0));
    });
  });

  group('EnemyType - World 5 Enemies', () {
    final world5Types = [
      EnemyType.crystalShard,
      EnemyType.gemCarrier,
      EnemyType.prismWalker,
      EnemyType.diamondGolem,
    ];

    for (final type in world5Types) {
      test('${type.name} belongs to world 5', () {
        expect(type.world, 5);
      });
    }

    test('prismWalker is phantom type', () {
      expect(EnemyType.prismWalker.isPhantom, isTrue);
    });

    test('diamondGolem is very tanky', () {
      expect(EnemyType.diamondGolem.healthMult, greaterThanOrEqualTo(4.0));
    });
  });

  group('EnemyType - World 6 Enemies', () {
    final world6Types = [
      EnemyType.sentryBot,
      EnemyType.droneSwarm,
      EnemyType.siegeWalker,
      EnemyType.cloakedAssassin,
    ];

    for (final type in world6Types) {
      test('${type.name} belongs to world 6', () {
        expect(type.world, 6);
      });
    }

    test('cloakedAssassin is phantom type', () {
      expect(EnemyType.cloakedAssassin.isPhantom, isTrue);
    });
  });

  group('EnemyType - World 7 Enemies', () {
    final world7Types = [
      EnemyType.codeFragment,
      EnemyType.matrixAgent,
      EnemyType.firewallBreaker,
      EnemyType.systemGhost,
    ];

    for (final type in world7Types) {
      test('${type.name} belongs to world 7', () {
        expect(type.world, 7);
      });
    }

    test('systemGhost is phantom type', () {
      expect(EnemyType.systemGhost.isPhantom, isTrue);
    });
  });

  group('EnemyType - World 8 Enemies', () {
    final world8Types = [
      EnemyType.stormRunner,
      EnemyType.cycloneSpirit,
      EnemyType.thunderTitan,
      EnemyType.lightningWraith,
    ];

    for (final type in world8Types) {
      test('${type.name} belongs to world 8', () {
        expect(type.world, 8);
      });
    }

    test('cycloneSpirit is phantom type', () {
      expect(EnemyType.cycloneSpirit.isPhantom, isTrue);
    });
  });

  group('EnemyType - World 9 Enemies', () {
    final world9Types = [
      EnemyType.voidStalker,
      EnemyType.abyssWalker,
      EnemyType.shadowSwarm,
      EnemyType.darknessTitan,
    ];

    for (final type in world9Types) {
      test('${type.name} belongs to world 9', () {
        expect(type.world, 9);
      });
    }

    test('voidStalker is phantom type', () {
      expect(EnemyType.voidStalker.isPhantom, isTrue);
    });

    test('darknessTitan is very tanky', () {
      expect(EnemyType.darknessTitan.healthMult, greaterThan(3.5));
    });
  });

  group('EnemyType - World 10 Enemies (Final)', () {
    final world10Types = [
      EnemyType.nexusHunter,
      EnemyType.omegaSentinel,
      EnemyType.realityShifter,
      EnemyType.apocalypseHerald,
    ];

    for (final type in world10Types) {
      test('${type.name} belongs to world 10', () {
        expect(type.world, 10);
      });
    }

    test('realityShifter is phantom type', () {
      expect(EnemyType.realityShifter.isPhantom, isTrue);
    });

    test('apocalypseHerald is the tankiest enemy', () {
      expect(EnemyType.apocalypseHerald.healthMult, greaterThanOrEqualTo(5.0));
    });

    test('apocalypseHerald is very slow', () {
      expect(EnemyType.apocalypseHerald.speedMult, lessThan(0.5));
    });
  });

  group('EnemyType - Phantom types across worlds', () {
    final phantomTypes = EnemyType.values.where((e) => e.isPhantom).toList();

    test('Multiple phantom types exist', () {
      // Worlds 3 and 4 don't have phantoms (8 total phantoms)
      expect(phantomTypes.length, 8);
    });

    for (final phantom in phantomTypes) {
      test('${phantom.name} is correctly marked as phantom', () {
        expect(phantom.isPhantom, isTrue);
      });
    }

    test('Phantoms are distributed across multiple worlds', () {
      final phantomWorlds = phantomTypes.map((e) => e.world).toSet();
      // 8 phantoms across 8 different worlds
      expect(phantomWorlds.length, 8);
    });
  });

  group('EnemyType - Balance checks', () {
    test('No enemy has zero health multiplier', () {
      for (final type in EnemyType.values) {
        expect(type.healthMult, greaterThan(0));
      }
    });

    test('No enemy has zero speed multiplier', () {
      for (final type in EnemyType.values) {
        expect(type.speedMult, greaterThan(0));
      }
    });

    test('Tank enemies (healthMult > 2) are slow (speedMult < 1)', () {
      final tanks = EnemyType.values.where((e) => e.healthMult > 2.0);
      for (final tank in tanks) {
        expect(tank.speedMult, lessThan(1.0),
            reason: '${tank.name} is tanky but should be slow');
      }
    });

    test('Fast enemies (speedMult > 1.3) are fragile (healthMult < 1.5)', () {
      final speedsters = EnemyType.values.where((e) => e.speedMult > 1.3);
      for (final fast in speedsters) {
        expect(fast.healthMult, lessThan(1.5),
            reason: '${fast.name} is fast but should be fragile');
      }
    });
  });

  group('EnemyType - getWorldEnemies helper', () {
    for (int world = 1; world <= 10; world++) {
      test('World $world returns exactly 4 enemies', () {
        final enemies = EnemyType.getWorldEnemies(world);
        expect(enemies.length, 4);
      });

      test('World $world enemies all belong to world $world', () {
        final enemies = EnemyType.getWorldEnemies(world);
        for (final enemy in enemies) {
          expect(enemy.world, world);
        }
      });
    }

    test('Invalid world returns empty list', () {
      expect(EnemyType.getWorldEnemies(0), isEmpty);
      expect(EnemyType.getWorldEnemies(11), isEmpty);
      expect(EnemyType.getWorldEnemies(-1), isEmpty);
    });
  });

  group('EnemyType - basicTypes helper', () {
    test('basicTypes returns world 1 starter enemies', () {
      final basics = EnemyType.basicTypes;
      // basicTypes returns the 4 starter enemies from world 1
      expect(basics, contains(EnemyType.runner));
      expect(basics, contains(EnemyType.overloaded));
      expect(basics, contains(EnemyType.juggernaut));
      expect(basics, contains(EnemyType.phantom));
    });

    test('basicTypes has 4 enemies (world 1 starters)', () {
      expect(EnemyType.basicTypes.length, 4);
    });
  });
}
