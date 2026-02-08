import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/enemy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnemyType enum', () {
    test('has 40 enemy types (4 per world × 10 worlds)', () {
      expect(EnemyType.values.length, 40);
    });

    test('each enemy type has unique index', () {
      final indices = EnemyType.values.map((e) => e.index).toSet();
      expect(indices.length, EnemyType.values.length);
    });

    test('all enemy types have positive speed multiplier', () {
      for (final type in EnemyType.values) {
        expect(type.speedMult, greaterThan(0),
            reason: '${type.name} should have positive speedMult');
      }
    });

    test('all enemy types have positive health multiplier', () {
      for (final type in EnemyType.values) {
        expect(type.healthMult, greaterThan(0),
            reason: '${type.name} should have positive healthMult');
      }
    });

    test('all enemy types have positive size multiplier', () {
      for (final type in EnemyType.values) {
        expect(type.sizeMult, greaterThan(0),
            reason: '${type.name} should have positive sizeMult');
      }
    });

    test('all enemy types have valid world (1-10)', () {
      for (final type in EnemyType.values) {
        expect(type.world, greaterThanOrEqualTo(1),
            reason: '${type.name} should be in world >= 1');
        expect(type.world, lessThanOrEqualTo(10),
            reason: '${type.name} should be in world <= 10');
      }
    });

    test('all enemy types have non-transparent color', () {
      for (final type in EnemyType.values) {
        expect(type.color.alpha, greaterThan(0),
            reason: '${type.name} should have visible color');
      }
    });
  });

  group('EnemyType World 1 - Neon Frontier', () {
    test('runner is basic type', () {
      expect(EnemyType.runner.world, 1);
      expect(EnemyType.runner.speedMult, 1.0);
      expect(EnemyType.runner.healthMult, 1.0);
      expect(EnemyType.runner.isPhantom, isFalse);
    });

    test('overloaded is fast with less HP', () {
      expect(EnemyType.overloaded.world, 1);
      expect(EnemyType.overloaded.speedMult, greaterThan(1.0));
      expect(EnemyType.overloaded.healthMult, lessThan(1.0));
    });

    test('juggernaut is slow with high HP', () {
      expect(EnemyType.juggernaut.world, 1);
      expect(EnemyType.juggernaut.speedMult, lessThan(1.0));
      expect(EnemyType.juggernaut.healthMult, greaterThan(2.0));
    });

    test('phantom is invisible type', () {
      expect(EnemyType.phantom.world, 1);
      expect(EnemyType.phantom.isPhantom, isTrue);
    });

    test('World 1 has 4 enemy types', () {
      final world1Enemies =
          EnemyType.values.where((e) => e.world == 1).toList();
      expect(world1Enemies.length, 4);
    });
  });

  group('EnemyType World 2 - Rift Wars', () {
    test('glitcher exists', () {
      expect(EnemyType.glitcher.world, 2);
      expect(EnemyType.glitcher.isPhantom, isFalse);
    });

    test('riftwalker is phantom', () {
      expect(EnemyType.riftwalker.world, 2);
      expect(EnemyType.riftwalker.isPhantom, isTrue);
    });

    test('voidling is fast and weak', () {
      expect(EnemyType.voidling.world, 2);
      expect(EnemyType.voidling.speedMult, greaterThan(1.0));
      expect(EnemyType.voidling.healthMult, lessThan(1.0));
    });

    test('dimensionBreaker is tanky', () {
      expect(EnemyType.dimensionBreaker.world, 2);
      expect(EnemyType.dimensionBreaker.healthMult, greaterThanOrEqualTo(3.0));
    });
  });

  group('EnemyType World 3 - Signal Wastes', () {
    test('corruptedByte is balanced', () {
      expect(EnemyType.corruptedByte.world, 3);
      expect(EnemyType.corruptedByte.speedMult, closeTo(1.0, 0.2));
      expect(EnemyType.corruptedByte.healthMult, closeTo(1.0, 0.2));
    });

    test('malware is slow and tanky', () {
      expect(EnemyType.malware.world, 3);
      expect(EnemyType.malware.speedMult, lessThan(1.0));
      expect(EnemyType.malware.healthMult, greaterThan(1.0));
    });

    test('dataWorm is very fast', () {
      expect(EnemyType.dataWorm.world, 3);
      expect(EnemyType.dataWorm.speedMult, greaterThanOrEqualTo(1.5));
    });

    test('virusCarrier is a carrier type', () {
      expect(EnemyType.virusCarrier.world, 3);
      expect(EnemyType.virusCarrier.healthMult, greaterThan(2.0));
    });
  });

  group('EnemyType World 4 - Ion Crown', () {
    test('sparkDrone is fast', () {
      expect(EnemyType.sparkDrone.world, 4);
      expect(EnemyType.sparkDrone.speedMult, greaterThan(1.0));
    });

    test('plasmaCore is tanky', () {
      expect(EnemyType.plasmaCore.world, 4);
      expect(EnemyType.plasmaCore.healthMult, greaterThanOrEqualTo(2.0));
    });

    test('ionSurge is very fast but weak', () {
      expect(EnemyType.ionSurge.world, 4);
      expect(EnemyType.ionSurge.speedMult, greaterThanOrEqualTo(1.5));
      expect(EnemyType.ionSurge.healthMult, lessThan(1.0));
    });

    test('thunderHulk is slowest in world', () {
      expect(EnemyType.thunderHulk.world, 4);
      expect(EnemyType.thunderHulk.speedMult, lessThanOrEqualTo(0.5));
      expect(EnemyType.thunderHulk.healthMult, greaterThanOrEqualTo(3.0));
    });
  });

  group('EnemyType World 5 - Shard Vault', () {
    test('crystalShard exists', () {
      expect(EnemyType.crystalShard.world, 5);
    });

    test('gemCarrier is tanky', () {
      expect(EnemyType.gemCarrier.world, 5);
      expect(EnemyType.gemCarrier.healthMult, greaterThan(1.5));
    });

    test('prismWalker is phantom', () {
      expect(EnemyType.prismWalker.world, 5);
      expect(EnemyType.prismWalker.isPhantom, isTrue);
    });

    test('diamondGolem is very tanky', () {
      expect(EnemyType.diamondGolem.world, 5);
      expect(EnemyType.diamondGolem.healthMult, greaterThanOrEqualTo(4.0));
      expect(EnemyType.diamondGolem.speedMult, lessThan(0.5));
    });
  });

  group('EnemyType World 6 - Arc Fortress', () {
    test('sentryBot is balanced', () {
      expect(EnemyType.sentryBot.world, 6);
      expect(EnemyType.sentryBot.healthMult, greaterThan(1.0));
    });

    test('droneSwarm is fast and weak', () {
      expect(EnemyType.droneSwarm.world, 6);
      expect(EnemyType.droneSwarm.speedMult, greaterThanOrEqualTo(1.5));
      expect(EnemyType.droneSwarm.healthMult, lessThanOrEqualTo(0.5));
    });

    test('siegeWalker is tanky', () {
      expect(EnemyType.siegeWalker.world, 6);
      expect(EnemyType.siegeWalker.healthMult, greaterThan(2.5));
    });

    test('cloakedAssassin is phantom', () {
      expect(EnemyType.cloakedAssassin.world, 6);
      expect(EnemyType.cloakedAssassin.isPhantom, isTrue);
    });
  });

  group('EnemyType World 7 - Omega Grid', () {
    test('codeFragment is fast', () {
      expect(EnemyType.codeFragment.world, 7);
      expect(EnemyType.codeFragment.speedMult, greaterThan(1.0));
    });

    test('matrixAgent is balanced', () {
      expect(EnemyType.matrixAgent.world, 7);
      expect(EnemyType.matrixAgent.healthMult, greaterThan(1.0));
    });

    test('firewallBreaker is slow and tanky', () {
      expect(EnemyType.firewallBreaker.world, 7);
      expect(EnemyType.firewallBreaker.speedMult, lessThan(1.0));
      expect(EnemyType.firewallBreaker.healthMult, greaterThan(2.0));
    });

    test('systemGhost is phantom', () {
      expect(EnemyType.systemGhost.world, 7);
      expect(EnemyType.systemGhost.isPhantom, isTrue);
    });
  });

  group('EnemyType World 8 - Storm Tower', () {
    test('stormRunner is fast', () {
      expect(EnemyType.stormRunner.world, 8);
      expect(EnemyType.stormRunner.speedMult, greaterThan(1.0));
    });

    test('cycloneSpirit is phantom', () {
      expect(EnemyType.cycloneSpirit.world, 8);
      expect(EnemyType.cycloneSpirit.isPhantom, isTrue);
    });

    test('thunderTitan is very tanky', () {
      expect(EnemyType.thunderTitan.world, 8);
      expect(EnemyType.thunderTitan.healthMult, greaterThan(3.0));
    });

    test('lightningWraith is very fast', () {
      expect(EnemyType.lightningWraith.world, 8);
      expect(EnemyType.lightningWraith.speedMult, greaterThanOrEqualTo(1.7));
    });
  });

  group('EnemyType World 9 - Final Gate', () {
    test('voidStalker is phantom', () {
      expect(EnemyType.voidStalker.world, 9);
      expect(EnemyType.voidStalker.isPhantom, isTrue);
    });

    test('abyssWalker is tanky', () {
      expect(EnemyType.abyssWalker.world, 9);
      expect(EnemyType.abyssWalker.healthMult, greaterThanOrEqualTo(2.0));
    });

    test('shadowSwarm is fast', () {
      expect(EnemyType.shadowSwarm.world, 9);
      expect(EnemyType.shadowSwarm.speedMult, greaterThanOrEqualTo(1.5));
    });

    test('darknessTitan is very tanky and slow', () {
      expect(EnemyType.darknessTitan.world, 9);
      expect(EnemyType.darknessTitan.healthMult, greaterThan(3.5));
      expect(EnemyType.darknessTitan.speedMult, lessThanOrEqualTo(0.5));
    });
  });

  group('EnemyType World 10 - Omega Nexus', () {
    test('nexusHunter is strong', () {
      expect(EnemyType.nexusHunter.world, 10);
      expect(EnemyType.nexusHunter.healthMult, greaterThan(1.0));
    });

    test('omegaSentinel is very tanky', () {
      expect(EnemyType.omegaSentinel.world, 10);
      expect(EnemyType.omegaSentinel.healthMult, greaterThan(2.0));
    });

    test('realityShifter is phantom', () {
      expect(EnemyType.realityShifter.world, 10);
      expect(EnemyType.realityShifter.isPhantom, isTrue);
    });

    test('apocalypseHerald is the ultimate enemy', () {
      expect(EnemyType.apocalypseHerald.world, 10);
      expect(EnemyType.apocalypseHerald.healthMult, greaterThanOrEqualTo(5.0));
      expect(EnemyType.apocalypseHerald.speedMult, lessThanOrEqualTo(0.5));
      expect(EnemyType.apocalypseHerald.sizeMult, greaterThan(1.5));
    });
  });

  group('EnemyType phantom distribution', () {
    test('worlds with phantom enemies have at least one phantom type', () {
      const worldsWithPhantoms = <int>{1, 2, 5, 6, 7, 8, 9, 10};
      for (final world in worldsWithPhantoms) {
        final phantoms =
            EnemyType.values.where((e) => e.world == world && e.isPhantom);
        expect(
          phantoms.isNotEmpty,
          isTrue,
          reason: 'World $world should have at least one phantom',
        );
      }
    });

    test('phantom types are minority', () {
      final phantoms = EnemyType.values.where((e) => e.isPhantom).toList();
      expect(phantoms.length, lessThan(EnemyType.values.length / 2));
    });

    test('phantom count is 8', () {
      final phantoms = EnemyType.values.where((e) => e.isPhantom).toList();
      expect(phantoms.length, 8);
    });
  });

  group('EnemyType.getWorldEnemies', () {
    test('returns 4 enemies for each world', () {
      for (int world = 1; world <= 10; world++) {
        final enemies = EnemyType.getWorldEnemies(world);
        expect(enemies.length, 4, reason: 'World $world should have 4 enemies');
      }
    });

    test('caches world enemies', () {
      final first = EnemyType.getWorldEnemies(1);
      final second = EnemyType.getWorldEnemies(1);
      expect(identical(first, second), isTrue);
    });

    test('returns empty for invalid world', () {
      final enemies = EnemyType.getWorldEnemies(0);
      expect(enemies, isEmpty);

      final enemies11 = EnemyType.getWorldEnemies(11);
      expect(enemies11, isEmpty);
    });

    test('all returned enemies belong to requested world', () {
      for (int world = 1; world <= 10; world++) {
        final enemies = EnemyType.getWorldEnemies(world);
        for (final enemy in enemies) {
          expect(enemy.world, world);
        }
      }
    });
  });

  group('EnemyType.basicTypes', () {
    test('contains 4 basic types', () {
      expect(EnemyType.basicTypes.length, 4);
    });

    test('contains runner', () {
      expect(EnemyType.basicTypes, contains(EnemyType.runner));
    });

    test('contains overloaded', () {
      expect(EnemyType.basicTypes, contains(EnemyType.overloaded));
    });

    test('contains juggernaut', () {
      expect(EnemyType.basicTypes, contains(EnemyType.juggernaut));
    });

    test('contains phantom', () {
      expect(EnemyType.basicTypes, contains(EnemyType.phantom));
    });

    test('all basic types are from World 1', () {
      for (final type in EnemyType.basicTypes) {
        expect(type.world, 1);
      }
    });
  });

  group('Enemy static configuration', () {
    test('lowFx can be toggled', () {
      final original = Enemy.lowFx;
      Enemy.lowFx = true;
      expect(Enemy.lowFx, isTrue);
      Enemy.lowFx = false;
      expect(Enemy.lowFx, isFalse);
      Enemy.lowFx = original;
    });

    test('forceLowFx can be toggled', () {
      final original = Enemy.forceLowFx;
      Enemy.forceLowFx = true;
      expect(Enemy.forceLowFx, isTrue);
      Enemy.forceLowFx = false;
      expect(Enemy.forceLowFx, isFalse);
      Enemy.forceLowFx = original;
    });

    test('allowBlur can be toggled', () {
      final original = Enemy.allowBlur;
      Enemy.allowBlur = false;
      expect(Enemy.allowBlur, isFalse);
      Enemy.allowBlur = true;
      expect(Enemy.allowBlur, isTrue);
      Enemy.allowBlur = original;
    });

    test('throttleOffscreen can be toggled', () {
      final original = Enemy.throttleOffscreen;
      Enemy.throttleOffscreen = true;
      expect(Enemy.throttleOffscreen, isTrue);
      Enemy.throttleOffscreen = false;
      expect(Enemy.throttleOffscreen, isFalse);
      Enemy.throttleOffscreen = original;
    });

    test('screenOffset can be set', () {
      final original = Enemy.screenOffset.clone();
      Enemy.screenOffset = Vector2(100, 200);
      expect(Enemy.screenOffset.x, 100);
      expect(Enemy.screenOffset.y, 200);
      Enemy.screenOffset = original;
    });

    test('screenSize can be set', () {
      final original = Enemy.screenSize.clone();
      Enemy.screenSize = Vector2(1920, 1080);
      expect(Enemy.screenSize.x, 1920);
      expect(Enemy.screenSize.y, 1080);
      Enemy.screenSize = original;
    });

    test('screenScale can be set', () {
      final original = Enemy.screenScale;
      Enemy.screenScale = 2.0;
      expect(Enemy.screenScale, 2.0);
      Enemy.screenScale = original;
    });
  });

  group('Enemy static constants', () {
    test('offscreenPadding is positive', () {
      expect(Enemy.offscreenPadding, greaterThan(0));
    });

    test('offscreenUpdateInterval is positive', () {
      expect(Enemy.offscreenUpdateInterval, greaterThan(0));
    });

    test('offscreenPadding is 60', () {
      expect(Enemy.offscreenPadding, 60.0);
    });

    test('offscreenUpdateInterval is 0.12', () {
      expect(Enemy.offscreenUpdateInterval, 0.12);
    });
  });

  group('Enemy callback types', () {
    test('EnemyDeathCallback type exists', () {
      EnemyDeathCallback? callback;
      expect(callback, isNull);
    });

    test('EnemyReachBaseCallback type exists', () {
      EnemyReachBaseCallback? callback;
      expect(callback, isNull);
    });
  });

  group('EnemyType color validation', () {
    test('World 1 enemies have warm colors', () {
      expect(EnemyType.runner.color.red, greaterThan(200));
      expect(EnemyType.overloaded.color.red, greaterThan(200));
    });

    test('World 2 enemies have neon colors', () {
      final world2 = EnemyType.getWorldEnemies(2);
      for (final enemy in world2) {
        final hasNeonComponent = enemy.color.red > 200 ||
            enemy.color.green > 200 ||
            enemy.color.blue > 200;
        expect(hasNeonComponent, isTrue,
            reason: '${enemy.name} should have neon color');
      }
    });

    test('World 7 enemies have green matrix colors', () {
      expect(EnemyType.codeFragment.color.green, greaterThan(200));
      expect(EnemyType.matrixAgent.color.green, greaterThan(0));
    });
  });

  group('EnemyType speed distribution', () {
    test('speeds range from 0.3 to 1.7', () {
      for (final type in EnemyType.values) {
        expect(type.speedMult, greaterThanOrEqualTo(0.3));
        expect(type.speedMult, lessThanOrEqualTo(1.7));
      }
    });

    test('fastest enemy is lightningWraith', () {
      final fastest =
          EnemyType.values.reduce((a, b) => a.speedMult > b.speedMult ? a : b);
      expect(fastest, EnemyType.lightningWraith);
    });

    test('slowest enemy is apocalypseHerald', () {
      final slowest =
          EnemyType.values.reduce((a, b) => a.speedMult < b.speedMult ? a : b);
      expect(slowest, EnemyType.apocalypseHerald);
    });
  });

  group('EnemyType health distribution', () {
    test('health multipliers range from 0.5 to 5.0', () {
      for (final type in EnemyType.values) {
        expect(type.healthMult, greaterThanOrEqualTo(0.5));
        expect(type.healthMult, lessThanOrEqualTo(5.0));
      }
    });

    test('tankiest enemy is apocalypseHerald', () {
      final tankiest = EnemyType.values
          .reduce((a, b) => a.healthMult > b.healthMult ? a : b);
      expect(tankiest, EnemyType.apocalypseHerald);
    });

    test('weakest enemies have healthMult 0.5', () {
      final weakest =
          EnemyType.values.where((e) => e.healthMult <= 0.5).toList();
      expect(weakest.isNotEmpty, isTrue);
    });
  });

  group('EnemyType size distribution', () {
    test('sizes range from 0.6 to 1.8', () {
      for (final type in EnemyType.values) {
        expect(type.sizeMult, greaterThanOrEqualTo(0.6));
        expect(type.sizeMult, lessThanOrEqualTo(1.8));
      }
    });

    test('largest enemy is apocalypseHerald', () {
      final largest =
          EnemyType.values.reduce((a, b) => a.sizeMult > b.sizeMult ? a : b);
      expect(largest, EnemyType.apocalypseHerald);
    });
  });
}
