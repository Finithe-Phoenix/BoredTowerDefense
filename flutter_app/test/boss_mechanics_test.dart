import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/boss.dart';
import 'package:bored_games/src/game/entities/enemy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BossType enum', () {
    test('has 11 boss types', () {
      expect(BossType.values.length, 11);
    });

    test('miniBoss is first type', () {
      expect(BossType.miniBoss, isNotNull);
      expect(BossType.values.first, BossType.miniBoss);
    });

    test('omegaNexus is last type', () {
      expect(BossType.omegaNexus, isNotNull);
      expect(BossType.values.last, BossType.omegaNexus);
    });

    test('all world bosses exist', () {
      expect(BossType.citadelCore, isNotNull);
      expect(BossType.abyssGate, isNotNull);
      expect(BossType.voidlineApex, isNotNull);
      expect(BossType.shardVault, isNotNull);
      expect(BossType.arcFortress, isNotNull);
      expect(BossType.coreHunter, isNotNull);
      expect(BossType.omegaGrid, isNotNull);
      expect(BossType.stormTower, isNotNull);
      expect(BossType.finalGate, isNotNull);
    });
  });

  group('BossMechanicState', () {
    test('initializes with default values', () {
      final state = BossMechanicState();

      expect(state.shieldAngle, 0);
      expect(state.shieldCount, 4);
      expect(state.empChargeTimer, 0);
      expect(state.teleportCooldown, 0);
      expect(state.portalPositions, isEmpty);
      expect(state.isSplit, isFalse);
      expect(state.splitCount, 0);
      expect(state.reflectionActive, isFalse);
      expect(state.timeScale, 1.0);
      expect(state.isPhaseShift, isFalse);
      expect(state.currentPhase, 1);
      expect(state.mechanicCycle, 0);
    });

    test('portalPositions can be modified', () {
      final state = BossMechanicState();
      state.portalPositions.add(Vector2(100, 100));

      expect(state.portalPositions.length, 1);
      expect(state.portalPositions.first.x, 100);
    });

    test('turretAngles can be modified', () {
      final state = BossMechanicState();
      state.turretAngles.add(1.5);
      state.turretAngles.add(3.0);

      expect(state.turretAngles.length, 2);
    });

    test('clonePositions can be modified', () {
      final state = BossMechanicState();
      state.clonePositions.add(Vector2(50, 50));

      expect(state.clonePositions.length, 1);
    });

    test('lightningTargets can be modified', () {
      final state = BossMechanicState();
      state.lightningTargets.add(Vector2(200, 200));

      expect(state.lightningTargets.length, 1);
    });

    test('hackedTowerIds can be modified', () {
      final state = BossMechanicState();
      state.hackedTowerIds.add(1);
      state.hackedTowerIds.add(2);

      expect(state.hackedTowerIds.length, 2);
    });
  });

  group('Boss creation', () {
    test('creates miniBoss with correct settings', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.miniBoss,
        bossLevel: 5,
      );

      expect(boss.bossType, BossType.miniBoss);
      expect(boss.bossLevel, 5);
      expect(boss.isBoss, isTrue);
      expect(boss.displayName, 'ELITE GUARD');
    });

    test('creates citadelCore boss', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.citadelCore,
        bossLevel: 10,
      );

      expect(boss.bossType, BossType.citadelCore);
      expect(boss.displayName, 'CITADEL CORE');
    });

    test('creates abyssGate boss', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.abyssGate,
        bossLevel: 20,
      );

      expect(boss.displayName, 'ABYSS GATE');
    });

    test('creates voidlineApex boss', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.voidlineApex,
        bossLevel: 30,
      );

      expect(boss.displayName, 'VOIDLINE APEX');
    });

    test('creates shardVault boss', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.shardVault,
        bossLevel: 40,
      );

      expect(boss.displayName, 'SHARD VAULT');
    });

    test('creates arcFortress boss', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.arcFortress,
        bossLevel: 50,
      );

      expect(boss.displayName, 'ARC FORTRESS');
    });

    test('creates coreHunter boss', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.coreHunter,
        bossLevel: 60,
      );

      expect(boss.displayName, 'CORE HUNTER');
    });

    test('creates omegaGrid boss', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.omegaGrid,
        bossLevel: 70,
      );

      expect(boss.displayName, 'OMEGA GRID');
    });

    test('creates stormTower boss', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.stormTower,
        bossLevel: 80,
      );

      expect(boss.displayName, 'STORM TOWER');
    });

    test('creates finalGate boss', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.finalGate,
        bossLevel: 90,
      );

      expect(boss.displayName, 'FINAL GATE');
    });

    test('creates omegaNexus boss', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.omegaNexus,
        bossLevel: 100,
      );

      expect(boss.displayName, 'OMEGA NEXUS');
    });
  });

  group('Boss size multiplier', () {
    test('miniBoss has 2.0x size', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.miniBoss,
        bossLevel: 5,
      );

      expect(boss.bossSizeMultiplier, 2.0);
    });

    test('omegaNexus has 4.5x size', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.omegaNexus,
        bossLevel: 100,
      );

      expect(boss.bossSizeMultiplier, 4.5);
    });

    test('world boss size scales with level', () {
      final boss10 = Boss(
        path: [Vector2.zero()],
        bossType: BossType.citadelCore,
        bossLevel: 10,
      );

      final boss50 = Boss(
        path: [Vector2.zero()],
        bossType: BossType.arcFortress,
        bossLevel: 50,
      );

      expect(boss50.bossSizeMultiplier, greaterThan(boss10.bossSizeMultiplier));
    });
  });

  group('Boss phases', () {
    test('phase 1 at full health', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.miniBoss,
        bossLevel: 5,
        maxHealth: 1000,
      );

      expect(boss.currentPhase, 1);
    });

    test('phase 2 at 75% health', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.miniBoss,
        bossLevel: 5,
        maxHealth: 1000,
      );

      // Account for type.healthMult multiplier in actual health calculation
      final actualMax = boss.maxHealth;
      boss.takeDamage(actualMax * 0.26); // Reduce to ~74%

      expect(boss.currentPhase, 2);
    });

    test('phase 3 at 50% health', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.miniBoss,
        bossLevel: 5,
        maxHealth: 1000,
      );

      // Account for type.healthMult multiplier in actual health calculation
      final actualMax = boss.maxHealth;
      boss.takeDamage(actualMax * 0.51); // Reduce to ~49%

      expect(boss.currentPhase, 3);
    });

    test('phase 4 at 25% health', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.miniBoss,
        bossLevel: 5,
        maxHealth: 1000,
      );

      // Account for type.healthMult multiplier in actual health calculation
      final actualMax = boss.maxHealth;
      boss.takeDamage(actualMax * 0.76); // Reduce to ~24%

      expect(boss.currentPhase, 4);
    });
  });

  group('Boss callbacks', () {
    test('onPhaseChange callback is triggered', () {
      int? calledPhase;
      Boss? calledBoss;

      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.miniBoss,
        bossLevel: 5,
        maxHealth: 1000,
        onPhaseChange: (b, phase) {
          calledBoss = b;
          calledPhase = phase;
        },
      );

      // Account for type.healthMult multiplier - damage enough to trigger phase 2
      final actualMax = boss.maxHealth;
      boss.takeDamage(actualMax * 0.26);
      boss.update(0.1);

      expect(calledBoss, same(boss));
      expect(calledPhase, 2);
    });

    test('onAbilityUsed callback can be set', () {
      String? abilityName;

      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.miniBoss,
        bossLevel: 5,
        onAbilityUsed: (b, ability) {
          abilityName = ability;
        },
      );

      expect(boss.onAbilityUsed, isNotNull);
    });

    test('onDeath callback works for boss', () {
      bool deathCalled = false;

      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.miniBoss,
        bossLevel: 5,
        maxHealth: 100,
        onDeath: (e) => deathCalled = true,
      );

      // Kill the boss - damage more than actual maxHealth (accounts for healthMult)
      boss.takeDamage(boss.maxHealth + 1);

      expect(deathCalled, isTrue);
      expect(boss.isAlive, isFalse);
    });
  });

  group('Boss update', () {
    test('update does not throw for alive boss', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.miniBoss,
        bossLevel: 5,
      );

      expect(() => boss.update(0.016), returnsNormally);
    });

    test('update handles dead boss gracefully', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.miniBoss,
        bossLevel: 5,
        maxHealth: 50,
      );

      boss.takeDamage(50);
      expect(() => boss.update(0.016), returnsNormally);
    });

    test('multiple updates do not throw', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.citadelCore,
        bossLevel: 10,
      );

      for (int i = 0; i < 100; i++) {
        boss.update(0.016);
      }

      expect(boss.isAlive, isTrue);
    });
  });

  group('Boss inheritance from Enemy', () {
    test('boss is an Enemy', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.miniBoss,
        bossLevel: 5,
      );

      expect(boss, isA<Enemy>());
    });

    test('boss has higher health than regular enemy', () {
      final enemy = Enemy(path: [Vector2.zero()], maxHealth: 100);
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.miniBoss,
        bossLevel: 5,
        maxHealth: 10000,
      );

      expect(boss.maxHealth, greaterThan(enemy.maxHealth));
    });

    test('boss can take damage', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.miniBoss,
        bossLevel: 5,
        maxHealth: 1000,
      );

      boss.takeDamage(100);

      expect(boss.health, lessThan(boss.maxHealth));
    });

    test('boss healthPercent works correctly', () {
      final boss = Boss(
        path: [Vector2.zero()],
        bossType: BossType.miniBoss,
        bossLevel: 5,
        maxHealth: 1000,
      );

      // Use actual maxHealth (accounts for type.healthMult multiplier)
      boss.takeDamage(boss.maxHealth * 0.5);

      expect(boss.healthPercent, closeTo(0.5, 0.01));
    });
  });
}
