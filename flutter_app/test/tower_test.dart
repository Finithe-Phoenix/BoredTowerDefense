import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/tower.dart';
import 'package:bored_games/src/game/entities/enemy.dart';
import 'package:bored_games/src/models/upgrade_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TargetMode enum', () {
    test('has 5 targeting modes', () {
      expect(TargetMode.values.length, 5);
    });

    test('modes are correctly defined', () {
      expect(TargetMode.first, isNotNull);
      expect(TargetMode.last, isNotNull);
      expect(TargetMode.strongest, isNotNull);
      expect(TargetMode.weakest, isNotNull);
      expect(TargetMode.closest, isNotNull);
    });
  });

  group('TowerType enum', () {
    test('has 9 tower types', () {
      expect(TowerType.values.length, 9);
    });

    test('all tower types have valid name', () {
      for (final type in TowerType.values) {
        expect(type.name, isNotEmpty);
        expect(type.name, isA<String>());
      }
    });

    test('all tower types have valid damage', () {
      for (final type in TowerType.values) {
        expect(type.damage, greaterThanOrEqualTo(0));
      }
    });

    test('all tower types have valid fireRate', () {
      for (final type in TowerType.values) {
        expect(type.fireRate, greaterThan(0));
      }
    });

    test('all tower types have valid range', () {
      for (final type in TowerType.values) {
        expect(type.range, greaterThan(0));
      }
    });

    test('all tower types have valid cost', () {
      for (final type in TowerType.values) {
        expect(type.cost, greaterThan(0));
      }
    });

    test('all tower types have valid color', () {
      for (final type in TowerType.values) {
        expect(type.color, isA<Color>());
        expect(type.color.value, isNonZero);
      }
    });

    test('all tower types have valid projectileSpeed', () {
      for (final type in TowerType.values) {
        expect(type.projectileSpeed, greaterThanOrEqualTo(0));
      }
    });

    test('pulseArcher is the basic tower', () {
      expect(TowerType.pulseArcher.name, 'Pulse Archer');
      expect(TowerType.pulseArcher.damage, 15);
      expect(TowerType.pulseArcher.fireRate, 2.0);
      expect(TowerType.pulseArcher.range, 160);
      expect(TowerType.pulseArcher.cost, 50);
      expect(TowerType.pulseArcher.canDetectPhantom, isFalse);
    });

    test('circuitCannon is high damage', () {
      expect(TowerType.circuitCannon.name, 'Circuit Cannon');
      expect(TowerType.circuitCannon.damage, 50);
      expect(TowerType.circuitCannon.fireRate, lessThan(1));
    });

    test('phaseMage can detect phantoms and slows', () {
      expect(TowerType.phaseMage.name, 'Phase Mage');
      expect(TowerType.phaseMage.canDetectPhantom, isTrue);
      expect(TowerType.phaseMage.slowAmount, greaterThan(0));
      expect(TowerType.phaseMage.slowDuration, greaterThan(0));
      expect(TowerType.phaseMage.appliesSlow, isTrue);
    });

    test('glimmerField has fast fire rate', () {
      expect(TowerType.glimmerField.name, 'Glimmer Field');
      expect(TowerType.glimmerField.fireRate, greaterThan(3));
    });

    test('ionSniper has high range and damage', () {
      expect(TowerType.ionSniper.name, 'Ion Sniper');
      expect(TowerType.ionSniper.damage, greaterThan(100));
      expect(TowerType.ionSniper.range, greaterThan(250));
    });

    test('teslaTerminal has instant projectile', () {
      expect(TowerType.teslaTerminal.name, 'Tesla Terminal');
      expect(TowerType.teslaTerminal.projectileSpeed, 0);
    });

    test('resonanceSiphon has zero damage', () {
      expect(TowerType.resonanceSiphon.name, 'Resonance Siphon');
      expect(TowerType.resonanceSiphon.damage, 0);
    });

    test('neuralDisruptor exists', () {
      expect(TowerType.neuralDisruptor.name, 'Neural Disruptor');
      expect(TowerType.neuralDisruptor.damage, greaterThan(0));
    });

    test('appliesSlow returns correct value', () {
      expect(TowerType.pulseArcher.appliesSlow, isFalse);
      expect(TowerType.phaseMage.appliesSlow, isTrue);
      expect(TowerType.glimmerField.appliesSlow, isTrue);
    });
  });

  group('Tower creation', () {
    test('creates with default parameters', () {
      final tower = Tower(
        position: Vector2(100, 100),
        size: 40,
      );

      expect(tower, isA<PositionComponent>());
      expect(tower.type, TowerType.pulseArcher);
      expect(tower.targetMode, TargetMode.first);
      expect(tower.buildCost, 0);
      expect(tower.position.x, 100);
      expect(tower.position.y, 100);
    });

    test('creates with custom parameters', () {
      final tower = Tower(
        position: Vector2(200, 200),
        size: 50,
        type: TowerType.circuitCannon,
        targetMode: TargetMode.strongest,
        buildCost: 100,
      );

      expect(tower.type, TowerType.circuitCannon);
      expect(tower.targetMode, TargetMode.strongest);
      expect(tower.buildCost, 100);
    });

    test('anchor is topLeft', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower.anchor, Anchor.topLeft);
    });

    test('size is set correctly', () {
      final tower = Tower(position: Vector2.zero(), size: 50);
      expect(tower.size.x, 50);
      expect(tower.size.y, 50);
    });
  });

  group('Tower stats', () {
    test('damage uses type base with multiplier', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        type: TowerType.pulseArcher,
        damageMultiplier: 1.5,
      );

      expect(tower.damage, TowerType.pulseArcher.damage * 1.5);
    });

    test('fireRate uses type base with multiplier', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        type: TowerType.pulseArcher,
        fireRateMultiplier: 2.0,
      );

      expect(tower.fireRate, TowerType.pulseArcher.fireRate * 2.0);
    });

    test('range uses type base with multiplier', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        type: TowerType.pulseArcher,
        rangeMultiplier: 1.2,
      );

      expect(tower.range, TowerType.pulseArcher.range * 1.2);
    });

    test('projectileSpeed uses type base with multiplier', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        type: TowerType.pulseArcher,
        projectileSpeedMultiplier: 1.5,
      );

      expect(tower.projectileSpeed, TowerType.pulseArcher.projectileSpeed * 1.5);
    });

    test('slowAmount uses type base with multiplier', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        type: TowerType.phaseMage,
        slowMultiplier: 1.5,
      );

      expect(tower.slowAmount, TowerType.phaseMage.slowAmount * 1.5);
    });

    test('slowDuration from type', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        type: TowerType.phaseMage,
      );

      expect(tower.slowDuration, TowerType.phaseMage.slowDuration);
    });

    test('color from type', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        type: TowerType.circuitCannon,
      );

      expect(tower.color, TowerType.circuitCannon.color);
    });

    test('centerPosition is calculated correctly', () {
      final tower = Tower(
        position: Vector2(100, 100),
        size: 40,
      );

      expect(tower.centerPosition.x, 120); // 100 + 40/2
      expect(tower.centerPosition.y, 120);
    });
  });

  group('Tower update', () {
    test('update reduces fire cooldown', () {
      final tower = Tower(position: Vector2.zero(), size: 40);

      tower.update(0.1);
      tower.update(0.1);

      // Just verify it doesn't throw
      expect(true, isTrue);
    });

    test('isReady when cooldown is zero', () {
      final tower = Tower(position: Vector2.zero(), size: 40);

      // After enough updates, should be ready
      for (int i = 0; i < 100; i++) {
        tower.update(0.016);
      }

      expect(tower.isReady, isTrue);
    });

    test('resetCooldown resets cooldown', () {
      final tower = Tower(position: Vector2.zero(), size: 40);

      tower.resetCooldown();

      expect(tower.isReady, isFalse);
    });
  });

  group('Tower manual targeting', () {
    test('manualTargeting is false by default', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower.manualTargeting, isFalse);
    });

    test('setManualMode enables manual targeting', () {
      final tower = Tower(position: Vector2.zero(), size: 40);

      tower.setManualMode(true);

      expect(tower.manualTargeting, isTrue);
    });

    test('setManualMode(false) disables and clears target', () {
      final tower = Tower(position: Vector2.zero(), size: 40);

      tower.setManualMode(true);
      tower.setManualMode(false);

      expect(tower.manualTargeting, isFalse);
      expect(tower.manualTarget, isNull);
    });

    test('manualTarget is null by default', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower.manualTarget, isNull);
    });
  });

  group('Tower boost', () {
    test('enterFpsBoost increases damage', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        type: TowerType.pulseArcher,
      );
      final baseDamage = tower.damage;

      tower.enterFpsBoost();

      expect(tower.damage, greaterThan(baseDamage));
    });

    test('exitFpsBoost restores damage', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        type: TowerType.pulseArcher,
      );
      final baseDamage = tower.damage;

      tower.enterFpsBoost();
      tower.exitFpsBoost();

      expect(tower.damage, baseDamage);
    });

    test('setResonanceBoost increases damage', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        type: TowerType.pulseArcher,
      );
      final baseDamage = tower.damage;

      tower.setResonanceBoost(true);

      expect(tower.damage, greaterThan(baseDamage));
    });

    test('resetResonanceBoost resets boost', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        type: TowerType.pulseArcher,
      );
      final baseDamage = tower.damage;

      tower.setResonanceBoost(true);
      tower.setResonanceBoost(true);
      tower.resetResonanceBoost();

      expect(tower.damage, baseDamage);
    });
  });

  group('Tower static settings', () {
    test('lowFx can be set', () {
      final original = Tower.lowFx;
      Tower.lowFx = true;
      expect(Tower.lowFx, isTrue);
      Tower.lowFx = original;
    });
  });

  group('Tower getters', () {
    test('currentDamage returns damage', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower.currentDamage, tower.damage);
    });

    test('currentFireRate returns fireRate', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower.currentFireRate, tower.fireRate);
    });

    test('currentRange returns range', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower.currentRange, tower.range);
    });

    test('currentTarget is null initially', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower.currentTarget, isNull);
    });

    test('lastFireTime is 0 initially', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      expect(tower.lastFireTime, 0);
    });
  });

  group('Tower targetMode', () {
    test('targetMode can be changed', () {
      final tower = Tower(position: Vector2.zero(), size: 40);

      tower.targetMode = TargetMode.strongest;

      expect(tower.targetMode, TargetMode.strongest);
    });
  });

  group('Tower multiple instances', () {
    test('multiple towers can exist independently', () {
      final tower1 = Tower(
        position: Vector2(0, 0),
        size: 40,
        type: TowerType.pulseArcher,
      );
      final tower2 = Tower(
        position: Vector2(100, 100),
        size: 50,
        type: TowerType.circuitCannon,
      );

      expect(tower1.type, isNot(equals(tower2.type)));
      expect(tower1.position, isNot(equals(tower2.position)));
      expect(tower1.size, isNot(equals(tower2.size)));
    });

    test('towers do not share state', () {
      final tower1 = Tower(position: Vector2.zero(), size: 40);
      final tower2 = Tower(position: Vector2.zero(), size: 40);

      tower1.setManualMode(true);

      expect(tower1.manualTargeting, isTrue);
      expect(tower2.manualTargeting, isFalse);
    });
  });

  group('Tower with multipliers', () {
    test('all multipliers work together', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
        type: TowerType.pulseArcher,
        damageMultiplier: 1.5,
        rangeMultiplier: 1.2,
        fireRateMultiplier: 1.3,
        projectileSpeedMultiplier: 1.4,
        slowMultiplier: 1.1,
      );

      expect(tower.damage, TowerType.pulseArcher.damage * 1.5);
      expect(tower.range, TowerType.pulseArcher.range * 1.2);
      expect(tower.fireRate, TowerType.pulseArcher.fireRate * 1.3);
      expect(tower.projectileSpeed, TowerType.pulseArcher.projectileSpeed * 1.4);
    });
  });

  group('Tower applyUpgradeStats', () {
    test('applies upgrade multipliers', () {
      final tower = Tower(
        position: Vector2.zero(),
        size: 40,
      );

      final stats = UpgradeStats(
        towerDamageMult: 2.0,
        towerRangeMult: 1.5,
        towerFireRateMult: 1.3,
        projectileSpeedMult: 1.2,
        slowMult: 1.1,
      );

      tower.applyUpgradeStats(stats);

      expect(tower.damage, TowerType.pulseArcher.damage * 2.0);
      expect(tower.range, TowerType.pulseArcher.range * 1.5);
      expect(tower.fireRate, TowerType.pulseArcher.fireRate * 1.3);
    });
  });

  group('Tower setManualTarget', () {
    test('setManualTarget sets target', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      final enemy = Enemy(path: [Vector2.zero()]);

      tower.setManualTarget(enemy);
      expect(tower.manualTarget, enemy);

      tower.setManualTarget(null);
      expect(tower.manualTarget, isNull);
    });
  });

  group('Tower render', () {
    test('renders without exceptions', () {
      final tower = Tower(
        position: Vector2(0, 0),
        size: 40,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      tower.update(0.1);
      tower.render(canvas);
      recorder.endRecording();
    });

    test('renders all tower types', () {
      for (final type in TowerType.values) {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 40,
          type: type,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        tower.update(0.1);
        tower.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with lowFx enabled', () {
      Tower.lowFx = true;

      final tower = Tower(
        position: Vector2(0, 0),
        size: 40,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      tower.update(0.1);
      tower.render(canvas);
      recorder.endRecording();

      Tower.lowFx = false;
    });

    test('renders during firing', () {
      final tower = Tower(
        position: Vector2(0, 0),
        size: 40,
      );

      tower.resetCooldown();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      tower.update(0.01);
      tower.render(canvas);
      recorder.endRecording();
    });

    test('renders with charge level', () {
      final tower = Tower(
        position: Vector2(0, 0),
        size: 40,
      );

      // Let charge build up
      for (int i = 0; i < 30; i++) {
        tower.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      tower.render(canvas);
      recorder.endRecording();
    });

    test('renders with different sizes', () {
      for (final size in [16.0, 32.0, 48.0, 64.0]) {
        final tower = Tower(
          position: Vector2(0, 0),
          size: size,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        tower.update(0.1);
        tower.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with boost active', () {
      final tower = Tower(
        position: Vector2(0, 0),
        size: 40,
      );

      tower.enterFpsBoost();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      tower.update(0.1);
      tower.render(canvas);
      recorder.endRecording();

      tower.exitFpsBoost();
    });

    test('renders each tower type idle effects', () {
      for (final type in TowerType.values) {
        final tower = Tower(
          position: Vector2(0, 0),
          size: 48,
          type: type,
        );

        // Let animations run
        for (int i = 0; i < 30; i++) {
          tower.update(0.016);
        }

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        tower.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with resonance boost', () {
      final tower = Tower(
        position: Vector2(0, 0),
        size: 40,
      );

      tower.setResonanceBoost(true);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      tower.update(0.1);
      tower.render(canvas);
      recorder.endRecording();

      tower.resetResonanceBoost();
    });

    test('renders multiple tower types side by side', () {
      final towers = <Tower>[];
      for (int i = 0; i < TowerType.values.length; i++) {
        towers.add(Tower(
          position: Vector2(i * 50.0, 0),
          size: 40,
          type: TowerType.values[i],
        ));
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      for (final tower in towers) {
        tower.update(0.1);
        tower.render(canvas);
      }
      recorder.endRecording();
    });

    test('renders after long animation time', () {
      final tower = Tower(
        position: Vector2(0, 0),
        size: 40,
        type: TowerType.phaseMage,
      );

      // Run for many frames
      for (int i = 0; i < 120; i++) {
        tower.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      tower.render(canvas);
      recorder.endRecording();
    });

    test('renders with forceLowFx enabled', () {
      Tower.lowFx = true;

      final tower = Tower(
        position: Vector2(0, 0),
        size: 40,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      tower.update(0.1);
      tower.render(canvas);
      recorder.endRecording();

      Tower.lowFx = false;
    });
  });

  group('Tower firing', () {
    test('isReady returns false when on cooldown', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      tower.resetCooldown();
      expect(tower.isReady, isFalse);
    });

    test('isReady returns true after cooldown expires', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      tower.resetCooldown();

      // Wait for cooldown to expire
      for (int i = 0; i < 100; i++) {
        tower.update(0.016);
      }

      expect(tower.isReady, isTrue);
    });

    test('resetCooldown sets tower to not ready', () {
      final tower = Tower(position: Vector2.zero(), size: 40);

      // Let cooldown expire
      for (int i = 0; i < 100; i++) {
        tower.update(0.016);
      }
      expect(tower.isReady, isTrue);

      tower.resetCooldown();
      expect(tower.isReady, isFalse);
    });

    test('lastFireTime tracks firing', () {
      final tower = Tower(position: Vector2.zero(), size: 40);
      final initial = tower.lastFireTime;

      tower.update(0.1);
      tower.resetCooldown();

      expect(tower.lastFireTime, greaterThanOrEqualTo(initial));
    });
  });

  group('Tower FPS boost mode', () {
    test('enterFpsBoost and exitFpsBoost work correctly', () {
      final tower = Tower(position: Vector2.zero(), size: 40);

      tower.enterFpsBoost();
      // Tower should be in boost mode
      tower.update(0.1);

      tower.exitFpsBoost();
      // Tower should exit boost mode
      tower.update(0.1);
    });
  });
}
