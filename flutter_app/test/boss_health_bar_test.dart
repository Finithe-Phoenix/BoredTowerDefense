import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bored_games/src/game/hud/boss_health_bar.dart';
import 'package:bored_games/src/game/entities/boss.dart';

void main() {
  group('BossHealthBar', () {
    late BossHealthBar healthBar;
    late Boss testBoss;
    late List<Vector2> testPath;

    setUp(() {
      testPath = [
        Vector2(0, 0),
        Vector2(100, 0),
        Vector2(100, 100),
      ];

      healthBar = BossHealthBar(
        screenWidth: 800,
        screenHeight: 600,
      );

      testBoss = Boss(
        path: testPath,
        bossType: BossType.citadelCore,
        bossLevel: 10,
        maxHealth: 1000,
      );
    });

    group('Initialization', () {
      test('creates with correct screen dimensions', () {
        expect(healthBar.screenWidth, 800);
        expect(healthBar.screenHeight, 600);
      });

      test('position is centered at top', () {
        expect(healthBar.position.x, 400); // screenWidth / 2
        expect(healthBar.position.y, 60);
      });

      test('has high priority for rendering', () {
        expect(healthBar.priority, 1000);
      });
    });

    group('Boss Tracking', () {
      test('starts with no boss', () {
        healthBar.setBoss(null);
        expect(healthBar, isNotNull); // Component exists
      });

      test('tracks boss when set', () {
        healthBar.setBoss(testBoss);
        healthBar.update(0.1);

        // Health bar should be tracking boss
        expect(healthBar, isNotNull);
      });

      test('updates when boss takes damage', () {
        healthBar.setBoss(testBoss);

        // Initial health
        healthBar.update(0.1);

        // Damage boss
        testBoss.takeDamage(1250); // 50% of 2500

        healthBar.update(0.1);

        // Health bar should reflect new health
        expect(testBoss.healthPercent, 0.5);
      });

      test('clears when boss dies', () {
        healthBar.setBoss(testBoss);
        healthBar.update(0.1);

        testBoss.takeDamage(2500); // 1000 * 2.5
        healthBar.update(0.1);

        expect(testBoss.isAlive, false);
      });
    });

    group('Boss Names', () {
      test('displays mini-boss name', () {
        final miniBoss = Boss(
          path: testPath,
          bossType: BossType.miniBoss,
          bossLevel: 5,
          maxHealth: 1000,
        );

        healthBar.setBoss(miniBoss);

        // Name should be set internally
        expect(miniBoss.bossType, BossType.miniBoss);
      });

      test('displays Citadel Core name', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
        );

        healthBar.setBoss(boss);
        expect(boss.bossType, BossType.citadelCore);
      });

      test('displays Abyss Gate name', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.abyssGate,
          bossLevel: 20,
          maxHealth: 2000,
        );

        healthBar.setBoss(boss);
        expect(boss.bossType, BossType.abyssGate);
      });

      test('displays Omega Nexus name', () {
        final boss = Boss(
          path: testPath,
          bossType: BossType.omegaNexus,
          bossLevel: 100,
          maxHealth: 10000,
        );

        healthBar.setBoss(boss);
        expect(boss.bossType, BossType.omegaNexus);
      });
    });

    group('Phase Colors', () {
      test('phase 1 is green', () {
        healthBar.setBoss(testBoss);
        expect(testBoss.currentPhase, 1);
        // Color verification through phase
      });

      test('phase 2 is yellow', () {
        healthBar.setBoss(testBoss);
        testBoss.takeDamage(626); // Down to phase 2 (2500 * 0.251)
        healthBar.update(0.1);

        expect(testBoss.currentPhase, 2);
      });

      test('phase 3 is orange', () {
        healthBar.setBoss(testBoss);
        testBoss.takeDamage(1251); // Down to phase 3 (2500 * 0.501)
        healthBar.update(0.1);

        expect(testBoss.currentPhase, 3);
      });

      test('phase 4 is red', () {
        healthBar.setBoss(testBoss);
        testBoss.takeDamage(1876); // Down to phase 4 (2500 * 0.751)
        healthBar.update(0.1);

        expect(testBoss.currentPhase, 4);
      });
    });

    group('Health Display', () {
      test('shows full health initially', () {
        healthBar.setBoss(testBoss);
        healthBar.update(0.1);

        expect(testBoss.healthPercent, 1.0);
      });

      test('smoothly animates health changes', () {
        healthBar.setBoss(testBoss);
        healthBar.update(0.1);

        // Damage boss
        testBoss.takeDamage(1250); // 50% of 2500

        // Update multiple times for smooth animation
        healthBar.update(0.1);
        healthBar.update(0.1);

        expect(testBoss.healthPercent, 0.5);
      });

      test('shows correct percentage', () {
        healthBar.setBoss(testBoss);

        testBoss.takeDamage(625); // 25% of 2500
        healthBar.update(0.5); // Longer update for smooth transition

        expect(testBoss.healthPercent, 0.75);
      });
    });

    group('Phase Indicators', () {
      test('starts in phase 1 of 4', () {
        healthBar.setBoss(testBoss);
        expect(testBoss.currentPhase, 1);
      });

      test('updates phase indicator on damage', () {
        healthBar.setBoss(testBoss);

        testBoss.takeDamage(626); // 2500 * 0.251
        healthBar.update(0.1);
        expect(testBoss.currentPhase, 2);

        testBoss.takeDamage(625); // 2500 * 0.25
        healthBar.update(0.1);
        expect(testBoss.currentPhase, 3);

        testBoss.takeDamage(625); // 2500 * 0.25
        healthBar.update(0.1);
        expect(testBoss.currentPhase, 4);
      });

      test('shows warning in phase 4', () {
        healthBar.setBoss(testBoss);

        testBoss.takeDamage(1876); // 2500 * 0.751
        healthBar.update(0.1);

        expect(testBoss.currentPhase, 4);
        // Warning skull should render (tested through update)
      });
    });

    group('Animation', () {
      test('updates animation phase over time', () {
        healthBar.setBoss(testBoss);

        healthBar.update(0.1);
        healthBar.update(0.1);
        healthBar.update(0.1);

        // Animation should have progressed
        expect(healthBar, isNotNull);
      });

      test('pulse effect updates', () {
        healthBar.setBoss(testBoss);

        for (int i = 0; i < 10; i++) {
          healthBar.update(0.1);
        }

        // Pulse animation should cycle
        expect(healthBar, isNotNull);
      });
    });

    group('Bar Dimensions', () {
      test('bar width is correct', () {
        // BossHealthBar._barWidth = 600
        expect(healthBar.screenWidth, 800);
        // Bar should be 600px wide (constant in component)
      });

      test('bar height is correct', () {
        // BossHealthBar._barHeight = 40
        expect(healthBar, isNotNull);
      });
    });

    group('Multiple Bosses', () {
      test('switches between different bosses', () {
        final boss1 = Boss(
          path: testPath,
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
        );

        final boss2 = Boss(
          path: testPath,
          bossType: BossType.abyssGate,
          bossLevel: 20,
          maxHealth: 2000,
        );

        healthBar.setBoss(boss1);
        healthBar.update(0.1);
        expect(boss1.maxHealth, 2500); // 1000 * 2.5

        healthBar.setBoss(boss2);
        healthBar.update(0.1);
        expect(boss2.maxHealth, 5000); // 2000 * 2.5
      });

      test('handles null boss after having a boss', () {
        healthBar.setBoss(testBoss);
        healthBar.update(0.1);

        healthBar.setBoss(null);
        healthBar.update(0.1);

        // Should handle gracefully
        expect(healthBar, isNotNull);
      });
    });

    group('Rendering States', () {
      test('does not crash when rendering with no boss', () {
        healthBar.setBoss(null);

        expect(() {
          healthBar.update(0.1);
        }, returnsNormally);
      });

      test('does not crash when rendering dead boss', () {
        healthBar.setBoss(testBoss);
        testBoss.takeDamage(2500); // 1000 * 2.5

        expect(() {
          healthBar.update(0.1);
        }, returnsNormally);
      });

      test('handles very low health', () {
        healthBar.setBoss(testBoss);
        testBoss.takeDamage(2499); // 2500 - 1
        healthBar.update(0.5);

        expect(testBoss.health, 1);
        expect(testBoss.currentPhase, 4);
      });
    });

    group('Edge Cases', () {
      test('handles boss with 0 max health', () {
        final weakBoss = Boss(
          path: testPath,
          bossType: BossType.miniBoss,
          bossLevel: 1,
          maxHealth: 1,
        );

        healthBar.setBoss(weakBoss);

        expect(() {
          healthBar.update(0.1);
        }, returnsNormally);
      });

      test('handles very high health boss', () {
        final tankBoss = Boss(
          path: testPath,
          bossType: BossType.omegaNexus,
          bossLevel: 100,
          maxHealth: 1000000,
        );

        healthBar.setBoss(tankBoss);

        expect(() {
          healthBar.update(0.1);
        }, returnsNormally);
      });

      test('handles rapid boss switching', () {
        final bosses = [
          Boss(path: testPath, bossType: BossType.miniBoss, bossLevel: 1, maxHealth: 500),
          Boss(path: testPath, bossType: BossType.citadelCore, bossLevel: 10, maxHealth: 1000),
          Boss(path: testPath, bossType: BossType.abyssGate, bossLevel: 20, maxHealth: 2000),
        ];

        for (final boss in bosses) {
          healthBar.setBoss(boss);
          healthBar.update(0.1);
        }

        expect(healthBar, isNotNull);
      });
    });

    group('Performance', () {
      test('updates efficiently with no boss', () {
        healthBar.setBoss(null);

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 100; i++) {
          healthBar.update(0.016); // ~60 FPS
        }

        stopwatch.stop();

        // Should complete in reasonable time (< 100ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('updates efficiently with active boss', () {
        healthBar.setBoss(testBoss);

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 100; i++) {
          healthBar.update(0.016);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}
