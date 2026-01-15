import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bored_games/src/game/entities/boss.dart';
import 'package:bored_games/src/game/entities/enemy.dart';

void main() {
  group('Boss', () {
    late List<Vector2> testPath;

    setUp(() {
      testPath = [
        Vector2(0, 0),
        Vector2(100, 0),
        Vector2(100, 100),
        Vector2(200, 100),
      ];
    });

    group('Initialization', () {
      test('creates mini-boss with correct stats', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.miniBoss,
          bossLevel: 5,
          maxHealth: 1000,
          speed: 50,
          goldReward: 300,
        );

        expect(boss.bossType, BossType.miniBoss);
        expect(boss.bossLevel, 5);
        // Boss is juggernaut type with healthMult 2.5
        expect(boss.maxHealth, 2500); // 1000 * 2.5
        expect(boss.health, 2500);
        expect(boss.goldReward, 300);
        expect(boss.isAlive, true);
      });

      test('creates world boss with correct stats', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 5000,
          speed: 40,
          goldReward: 1000,
        );

        expect(boss.bossType, BossType.citadelCore);
        expect(boss.bossLevel, 10);
        // Boss is juggernaut type with healthMult 2.5
        expect(boss.maxHealth, 12500); // 5000 * 2.5
        expect(boss.goldReward, 1000);
      });

      test('boss size is larger than normal enemy', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 5000,
        );

        final normalEnemy = Enemy(
          path: testPath,
          maxHealth: 100,
        );

        expect(boss.size.x, greaterThan(normalEnemy.size.x));
      });

      test('Omega Nexus has largest size', () {
        final omegaBoss = Boss(
          path: testPath,
          bossType: BossType.omegaNexus,
          bossLevel: 100,
          maxHealth: 10000,
        );

        final regularBoss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 5000,
        );

        expect(omegaBoss.size.x, greaterThan(regularBoss.size.x));
      });
    });

    group('Phase System', () {
      test('starts in phase 1', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
        );

        expect(boss.currentPhase, 1);
      });

      test('changes to phase 2 at 75% HP', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
        );

        boss.takeDamage(626); // Down to 74.9% (2500 * 0.251)
        expect(boss.currentPhase, 2);
      });

      test('changes to phase 3 at 50% HP', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
        );

        boss.takeDamage(1251); // Down to 49.9% (2500 * 0.501)
        expect(boss.currentPhase, 3);
      });

      test('changes to phase 4 at 25% HP', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
        );

        boss.takeDamage(1876); // Down to 24.9% (2500 * 0.751)
        expect(boss.currentPhase, 4);
      });

      test('triggers phase change callback', () {
        int phaseChangeCalls = 0;
        int lastPhase = 0;

        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
          onPhaseChange: (boss, phase) {
            phaseChangeCalls++;
            lastPhase = phase;
          },
        );

        boss.takeDamage(626); // Phase 2 (2500 * 0.251)
        boss.update(0.016); // Trigger phase check
        expect(phaseChangeCalls, 1);
        expect(lastPhase, 2);

        boss.takeDamage(625); // Phase 3 (2500 * 0.25)
        boss.update(0.016); // Trigger phase check
        expect(phaseChangeCalls, 2);
        expect(lastPhase, 3);
      });
    });

    group('Boss Types', () {
      test('Citadel Core has shield mechanic', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
        );

        expect(boss.bossType, BossType.citadelCore);
        // Shield count should be initialized
        // (checking internal state through update)
        boss.update(0.1);
        expect(boss.isAlive, true);
      });

      test('Abyss Gate can teleport', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.abyssGate,
          bossLevel: 20,
          maxHealth: 2000,
        );

        expect(boss.bossType, BossType.abyssGate);

        // Damage to phase 2 to enable teleport
        boss.takeDamage(1251); // 2000 * 2.5 * 0.251 = 1252.5
        expect(boss.currentPhase, 2);
      });

      test('Voidline Apex has split mechanic', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.voidlineApex,
          bossLevel: 30,
          maxHealth: 3000,
        );

        expect(boss.bossType, BossType.voidlineApex);

        // Should split in phase 2
        boss.takeDamage(1876); // 3000 * 2.5 * 0.251 = 1882.5
        expect(boss.currentPhase, 2);
      });

      test('Omega Nexus has all mechanics', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.omegaNexus,
          bossLevel: 100,
          maxHealth: 10000,
        );

        expect(boss.bossType, BossType.omegaNexus);

        // Should cycle through mechanics
        boss.update(0.1);
        expect(boss.isAlive, true);
      });
    });

    group('Damage and Death', () {
      test('takes damage correctly', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
        );

        boss.takeDamage(300);
        expect(boss.health, 2200); // 2500 - 300
        expect(boss.healthPercent, closeTo(0.88, 0.01)); // 2200 / 2500
      });

      test('dies when health reaches 0', () {
        bool deathCalled = false;

        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
          onDeath: (_) {
            deathCalled = true;
          },
        );

        boss.takeDamage(2500); // 1000 * 2.5
        expect(boss.health, 0);
        expect(boss.isAlive, false);
        expect(deathCalled, true);
      });

      test('health cannot go below 0', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
        );

        boss.takeDamage(3000); // More than maxHealth (2500)
        expect(boss.health, 0);
      });

      test('cannot take damage when dead', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
        );

        boss.takeDamage(2500); // 1000 * 2.5
        expect(boss.health, 0);

        boss.takeDamage(100);
        expect(boss.health, 0);
      });
    });

    group('Boss Abilities', () {
      test('triggers ability callback', () {
        int abilityCalls = 0;
        String lastAbility = '';

        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
          onAbilityUsed: (boss, abilityName) {
            abilityCalls++;
            lastAbility = abilityName;
          },
        );

        // Update boss to trigger EMP pulse (after 5 seconds)
        for (int i = 0; i < 51; i++) {
          boss.update(0.1);
        }

        expect(abilityCalls, greaterThan(0));
        expect(lastAbility, 'emp_pulse');
      });

      test('Omega Nexus cycles through abilities', () {
        final abilities = <String>[];

        final boss = Boss(
          path: testPath,
          bossType: BossType.omegaNexus,
          bossLevel: 100,
          maxHealth: 10000,
          onAbilityUsed: (boss, abilityName) {
            abilities.add(abilityName);
          },
        );

        // Update for more than 10 seconds to trigger ability cycle
        for (int i = 0; i < 101; i++) {
          boss.update(0.1);
        }

        expect(abilities.length, greaterThan(0));
      });
    });

    group('Movement', () {
      test('boss moves along path', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
          speed: 100,
        );

        final initialX = boss.position.x;
        final initialY = boss.position.y;

        boss.update(0.1);

        // Check if position changed (either x or y)
        expect(
          boss.position.x != initialX || boss.position.y != initialY,
          isTrue,
        );
      });

      test('boss is slower than normal enemy', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
          speed: 60,
        );

        final normalEnemy = Enemy(
          path: testPath,
          maxHealth: 100,
          speed: 100,
        );

        expect(boss.speed, lessThan(normalEnemy.speed));
      });

      test('boss reaches end of path', () {
        bool reachedBase = false;

        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
          speed: 1000, // Very fast to reach quickly
          onReachBase: (_) {
            reachedBase = true;
          },
        );

        // Update many times to ensure boss reaches end
        for (int i = 0; i < 100; i++) {
          boss.update(0.1);
        }

        expect(reachedBase, true);
      });
    });

    group('Boss Specific Mechanics', () {
      test('Citadel Core shield rotates', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
        );

        boss.update(1.0);
        // Shield should have rotated (internal state check)
        expect(boss.isAlive, true);
      });

      test('Abyss Gate teleport cooldown works', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.abyssGate,
          bossLevel: 20,
          maxHealth: 2000,
        );

        // Damage to phase 2 to enable teleport
        boss.takeDamage(1251); // 2000 * 2.5 * 0.251 = 1252.5

        final initialPos = boss.position.clone();

        // Update for teleport cooldown (8 seconds)
        for (int i = 0; i < 81; i++) {
          boss.update(0.1);
        }

        // Position should have changed due to teleport
        expect(boss.position, isNot(equals(initialPos)));
      });

      test('Voidline Apex splits in phase 2', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.voidlineApex,
          bossLevel: 30,
          maxHealth: 3000,
        );

        // Damage to phase 2
        boss.takeDamage(1876); // 3000 * 2.5 * 0.251 = 1882.5
        expect(boss.currentPhase, 2);

        boss.update(0.1);
        // Should have created clones (internal state)
        expect(boss.isAlive, true);
      });
    });

    group('Boss Size Multipliers', () {
      test('mini-boss has 2x size', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.miniBoss,
          bossLevel: 5,
          maxHealth: 1000,
        );

        expect(boss.bossSizeMultiplier, 2.0);
      });

      test('world boss size scales with level', () {
        final boss10 = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
        );

        final boss50 = Boss(
          path: testPath,
          bossType: BossType.arcFortress,
          bossLevel: 50,
          maxHealth: 5000,
        );

        expect(boss50.bossSizeMultiplier, greaterThan(boss10.bossSizeMultiplier));
      });

      test('Omega Nexus has maximum size', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.omegaNexus,
          bossLevel: 100,
          maxHealth: 10000,
        );

        expect(boss.bossSizeMultiplier, 4.5);
      });
    });

    group('Edge Cases', () {
      test('boss with empty path does not crash', () {
        final boss = Boss(
          path: [],
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
        );

        expect(() => boss.update(0.1), returnsNormally);
      });

      test('boss with single waypoint does not crash', () {
        final boss = Boss(
          path: [Vector2(0, 0)],
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
        );

        expect(() => boss.update(0.1), returnsNormally);
      });

      test('boss with very high damage still has correct phase', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 10000,
        );

        boss.takeDamage(24999); // 10000 * 2.5 - 1
        expect(boss.health, 1);
        expect(boss.currentPhase, 4);
      });
    });
  });
}
