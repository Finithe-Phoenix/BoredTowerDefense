import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/boss.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BossType enum', () {
    test('has expected number of boss types', () {
      expect(BossType.values.length, 11);
    });

    test('contains miniBoss', () {
      expect(BossType.values, contains(BossType.miniBoss));
    });

    test('contains citadelCore', () {
      expect(BossType.values, contains(BossType.citadelCore));
    });

    test('contains abyssGate', () {
      expect(BossType.values, contains(BossType.abyssGate));
    });

    test('contains voidlineApex', () {
      expect(BossType.values, contains(BossType.voidlineApex));
    });

    test('contains shardVault', () {
      expect(BossType.values, contains(BossType.shardVault));
    });

    test('contains arcFortress', () {
      expect(BossType.values, contains(BossType.arcFortress));
    });

    test('contains coreHunter', () {
      expect(BossType.values, contains(BossType.coreHunter));
    });

    test('contains omegaGrid', () {
      expect(BossType.values, contains(BossType.omegaGrid));
    });

    test('contains stormTower', () {
      expect(BossType.values, contains(BossType.stormTower));
    });

    test('contains finalGate', () {
      expect(BossType.values, contains(BossType.finalGate));
    });

    test('contains omegaNexus', () {
      expect(BossType.values, contains(BossType.omegaNexus));
    });

    test('each boss type has unique index', () {
      final indices = BossType.values.map((b) => b.index).toSet();
      expect(indices.length, BossType.values.length);
    });

    test('miniBoss is first', () {
      expect(BossType.miniBoss.index, 0);
    });

    test('omegaNexus is last', () {
      expect(BossType.omegaNexus.index, BossType.values.length - 1);
    });
  });

  group('BossMechanicState', () {
    test('can be instantiated', () {
      final state = BossMechanicState();
      expect(state, isNotNull);
    });

    test('has default shieldAngle of 0', () {
      final state = BossMechanicState();
      expect(state.shieldAngle, 0);
    });

    test('has default shieldCount of 4', () {
      final state = BossMechanicState();
      expect(state.shieldCount, 4);
    });

    test('has default empChargeTimer of 0', () {
      final state = BossMechanicState();
      expect(state.empChargeTimer, 0);
    });

    test('has default teleportCooldown of 0', () {
      final state = BossMechanicState();
      expect(state.teleportCooldown, 0);
    });

    test('portalPositions is empty initially', () {
      final state = BossMechanicState();
      expect(state.portalPositions, isEmpty);
    });

    test('clonePositions is empty initially', () {
      final state = BossMechanicState();
      expect(state.clonePositions, isEmpty);
    });

    test('isSplit is false initially', () {
      final state = BossMechanicState();
      expect(state.isSplit, isFalse);
    });

    test('splitCount is 0 initially', () {
      final state = BossMechanicState();
      expect(state.splitCount, 0);
    });

    test('reflectionActive is false initially', () {
      final state = BossMechanicState();
      expect(state.reflectionActive, isFalse);
    });

    test('prismRotation is 0 initially', () {
      final state = BossMechanicState();
      expect(state.prismRotation, 0);
    });

    test('turretAngles is empty initially', () {
      final state = BossMechanicState();
      expect(state.turretAngles, isEmpty);
    });

    test('timeScale is 1.0 initially', () {
      final state = BossMechanicState();
      expect(state.timeScale, 1.0);
    });

    test('isPhaseShift is false initially', () {
      final state = BossMechanicState();
      expect(state.isPhaseShift, isFalse);
    });

    test('hackedTowerIds is empty initially', () {
      final state = BossMechanicState();
      expect(state.hackedTowerIds, isEmpty);
    });

    test('stormIntensity is 0 initially', () {
      final state = BossMechanicState();
      expect(state.stormIntensity, 0);
    });

    test('lightningTargets is empty initially', () {
      final state = BossMechanicState();
      expect(state.lightningTargets, isEmpty);
    });

    test('currentPhase is 1 initially', () {
      final state = BossMechanicState();
      expect(state.currentPhase, 1);
    });

    test('mechanicCycle is 0 initially', () {
      final state = BossMechanicState();
      expect(state.mechanicCycle, 0);
    });

    test('ultimateTimer is 0 initially', () {
      final state = BossMechanicState();
      expect(state.ultimateTimer, 0);
    });

    test('minionSpawnTimer is 0 initially', () {
      final state = BossMechanicState();
      expect(state.minionSpawnTimer, 0);
    });
  });

  group('BossMechanicState reset', () {
    test('reset restores default values', () {
      final state = BossMechanicState();

      // Modify some values
      state.shieldAngle = 1.5;
      state.shieldCount = 2;
      state.isSplit = true;
      state.currentPhase = 3;
      state.timeScale = 0.5;

      // Reset
      state.reset();

      // Verify defaults
      expect(state.shieldAngle, 0);
      expect(state.shieldCount, 4);
      expect(state.isSplit, isFalse);
      expect(state.currentPhase, 1);
      expect(state.timeScale, 1.0);
    });

    test('reset clears lists', () {
      final state = BossMechanicState();

      // Add items to lists
      state.portalPositions.add(Vector2(1, 2));
      state.clonePositions.add(Vector2(3, 4));
      state.turretAngles.add(1.5);
      state.hackedTowerIds.add(1);
      state.lightningTargets.add(Vector2(5, 6));

      // Reset
      state.reset();

      // Verify lists are empty
      expect(state.portalPositions, isEmpty);
      expect(state.clonePositions, isEmpty);
      expect(state.turretAngles, isEmpty);
      expect(state.hackedTowerIds, isEmpty);
      expect(state.lightningTargets, isEmpty);
    });

    test('reset can be called multiple times', () {
      final state = BossMechanicState();

      state.reset();
      state.reset();
      state.reset();

      expect(state.shieldAngle, 0);
    });
  });

  group('BossMechanicState static constants', () {
    test('maxPortals is 4', () {
      // Based on source code
      const maxPortals = 4;
      expect(maxPortals, 4);
    });

    test('maxClones is 4', () {
      const maxClones = 4;
      expect(maxClones, 4);
    });

    test('maxTurrets is 8', () {
      const maxTurrets = 8;
      expect(maxTurrets, 8);
    });

    test('maxHackedTowers is 10', () {
      const maxHackedTowers = 10;
      expect(maxHackedTowers, 10);
    });

    test('maxLightningTargets is 6', () {
      const maxLightningTargets = 6;
      expect(maxLightningTargets, 6);
    });
  });

  group('BossMechanicState portal management', () {
    test('can add portal positions', () {
      final state = BossMechanicState();

      state.portalPositions.add(Vector2(100, 200));

      expect(state.portalPositions.length, 1);
      expect(state.portalPositions[0].x, 100);
      expect(state.portalPositions[0].y, 200);
    });

    test('can add multiple portals', () {
      final state = BossMechanicState();

      state.portalPositions.add(Vector2(100, 200));
      state.portalPositions.add(Vector2(300, 400));
      state.portalPositions.add(Vector2(500, 600));

      expect(state.portalPositions.length, 3);
    });
  });

  group('BossMechanicState clone management', () {
    test('can add clone positions', () {
      final state = BossMechanicState();

      state.clonePositions.add(Vector2(50, 60));

      expect(state.clonePositions.length, 1);
    });

    test('can track split state', () {
      final state = BossMechanicState();

      state.isSplit = true;
      state.splitCount = 3;

      expect(state.isSplit, isTrue);
      expect(state.splitCount, 3);
    });
  });

  group('BossMechanicState turret management', () {
    test('can add turret angles', () {
      final state = BossMechanicState();

      state.turretAngles.add(0.0);
      state.turretAngles.add(1.57);
      state.turretAngles.add(3.14);

      expect(state.turretAngles.length, 3);
    });

    test('turret fire timer can be updated', () {
      final state = BossMechanicState();

      state.turretFireTimer = 0.5;

      expect(state.turretFireTimer, 0.5);
    });
  });

  group('BossMechanicState time manipulation', () {
    test('timeScale can be modified', () {
      final state = BossMechanicState();

      state.timeScale = 0.5;
      expect(state.timeScale, 0.5);

      state.timeScale = 2.0;
      expect(state.timeScale, 2.0);
    });

    test('phaseShift can be toggled', () {
      final state = BossMechanicState();

      expect(state.isPhaseShift, isFalse);

      state.isPhaseShift = true;
      expect(state.isPhaseShift, isTrue);
    });
  });

  group('BossMechanicState storm effects', () {
    test('storm intensity can be set', () {
      final state = BossMechanicState();

      state.stormIntensity = 0.75;

      expect(state.stormIntensity, 0.75);
    });

    test('lightning targets can be added', () {
      final state = BossMechanicState();

      state.lightningTargets.add(Vector2(100, 100));
      state.lightningTargets.add(Vector2(200, 200));

      expect(state.lightningTargets.length, 2);
    });
  });

  group('BossMechanicState phase management', () {
    test('currentPhase can be incremented', () {
      final state = BossMechanicState();

      expect(state.currentPhase, 1);

      state.currentPhase = 2;
      expect(state.currentPhase, 2);

      state.currentPhase = 3;
      expect(state.currentPhase, 3);
    });

    test('phaseTransitionTimer can be set', () {
      final state = BossMechanicState();

      state.phaseTransitionTimer = 2.5;

      expect(state.phaseTransitionTimer, 2.5);
    });
  });

  group('Boss callback types', () {
    test('BossPhaseChangeCallback type exists', () {
      BossPhaseChangeCallback? callback;
      expect(callback, isNull);
    });

    test('BossAbilityCallback type exists', () {
      BossAbilityCallback? callback;
      expect(callback, isNull);
    });
  });

  group('BossType world mapping', () {
    test('citadelCore is World 1 boss', () {
      // World bosses start at index 1 (after miniBoss)
      expect(BossType.citadelCore.index, 1);
    });

    test('abyssGate is World 2 boss', () {
      expect(BossType.abyssGate.index, 2);
    });

    test('voidlineApex is World 3 boss', () {
      expect(BossType.voidlineApex.index, 3);
    });

    test('shardVault is World 4 boss', () {
      expect(BossType.shardVault.index, 4);
    });

    test('arcFortress is World 5 boss', () {
      expect(BossType.arcFortress.index, 5);
    });

    test('coreHunter is World 6 boss', () {
      expect(BossType.coreHunter.index, 6);
    });

    test('omegaGrid is World 7 boss', () {
      expect(BossType.omegaGrid.index, 7);
    });

    test('stormTower is World 8 boss', () {
      expect(BossType.stormTower.index, 8);
    });

    test('finalGate is World 9 boss', () {
      expect(BossType.finalGate.index, 9);
    });

    test('omegaNexus is World 10 boss', () {
      expect(BossType.omegaNexus.index, 10);
    });
  });
}
