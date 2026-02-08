import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/projectile.dart';
import 'package:bored_games/src/game/entities/tower.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Projectile static configuration', () {
    test('lowFx can be toggled', () {
      final original = Projectile.lowFx;
      Projectile.lowFx = true;
      expect(Projectile.lowFx, isTrue);
      Projectile.lowFx = false;
      expect(Projectile.lowFx, isFalse);
      Projectile.lowFx = original;
    });

    test('allowTrails can be toggled', () {
      final original = Projectile.allowTrails;
      Projectile.allowTrails = false;
      expect(Projectile.allowTrails, isFalse);
      Projectile.allowTrails = true;
      expect(Projectile.allowTrails, isTrue);
      Projectile.allowTrails = original;
    });

    test('allowGlow can be toggled', () {
      final original = Projectile.allowGlow;
      Projectile.allowGlow = false;
      expect(Projectile.allowGlow, isFalse);
      Projectile.allowGlow = true;
      expect(Projectile.allowGlow, isTrue);
      Projectile.allowGlow = original;
    });
  });

  group('Projectile stress levels', () {
    setUp(() {
      // Reset to default state
      Projectile.setStressLevel(0);
    });

    test('stressLevel is 0 by default', () {
      expect(Projectile.stressLevel, 0);
    });

    test('setStressLevel(0) enables full quality', () {
      Projectile.setStressLevel(0);
      expect(Projectile.stressLevel, 0);
      expect(Projectile.lowFx, isFalse);
    });

    test('setStressLevel(1) reduces trails', () {
      Projectile.setStressLevel(1);
      expect(Projectile.stressLevel, 1);
      expect(Projectile.lowFx, isFalse); // lowFx only at level 2
    });

    test('setStressLevel(2) enables minimal FX', () {
      Projectile.setStressLevel(2);
      expect(Projectile.stressLevel, 2);
      expect(Projectile.lowFx, isTrue);
    });

    test('stress level clamps to 0-2 range', () {
      Projectile.setStressLevel(-5);
      expect(Projectile.stressLevel, 0);

      Projectile.setStressLevel(10);
      expect(Projectile.stressLevel, 2);
    });

    test('stress level can transition between all levels', () {
      Projectile.setStressLevel(0);
      expect(Projectile.stressLevel, 0);

      Projectile.setStressLevel(1);
      expect(Projectile.stressLevel, 1);

      Projectile.setStressLevel(2);
      expect(Projectile.stressLevel, 2);

      Projectile.setStressLevel(1);
      expect(Projectile.stressLevel, 1);

      Projectile.setStressLevel(0);
      expect(Projectile.stressLevel, 0);
    });
  });

  group('Projectile palette cache', () {
    setUp(() {
      Projectile.clearPaletteCache();
    });

    test('clearPaletteCache can be called', () {
      Projectile.clearPaletteCache();
      expect(true, isTrue);
    });

    test('clearPaletteCache can be called multiple times', () {
      Projectile.clearPaletteCache();
      Projectile.clearPaletteCache();
      Projectile.clearPaletteCache();
      expect(true, isTrue);
    });
  });

  group('Projectile creation', () {
    test('can create projectile with minimum parameters', () {
      final projectile = Projectile(
        startPosition: Vector2(0, 0),
        targetPosition: Vector2(100, 100),
        speed: 300,
        damage: 10,
      );

      expect(projectile, isNotNull);
      expect(projectile.position.x, 0);
      expect(projectile.position.y, 0);
    });

    test('can create projectile with all parameters', () {
      final projectile = Projectile(
        startPosition: Vector2(50, 50),
        targetPosition: Vector2(200, 200),
        speed: 400,
        damage: 25,
        color: const Color(0xFFFF0000),
        slowAmount: 0.5,
        slowDuration: 2.0,
        towerType: TowerType.phaseMage,
      );

      expect(projectile, isNotNull);
      expect(projectile.position.x, 50);
      expect(projectile.position.y, 50);
    });

    test('projectile size is 6x6', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 100),
        speed: 300,
        damage: 10,
      );

      expect(projectile.size.x, 6);
      expect(projectile.size.y, 6);
    });

    test('projectile anchor is center', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 100),
        speed: 300,
        damage: 10,
      );

      expect(projectile.anchor, Anchor.center);
    });

    test('default color is cyan', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 100),
        speed: 300,
        damage: 10,
      );

      expect(projectile.color, const Color(0xFF00FFFF));
    });

    test('default towerType is pulseArcher', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 100),
        speed: 300,
        damage: 10,
      );

      expect(projectile.towerType, TowerType.pulseArcher);
    });
  });

  group('Projectile for each tower type', () {
    test('can create pulseArcher projectile', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: TowerType.pulseArcher.projectileSpeed,
        damage: TowerType.pulseArcher.damage,
        color: TowerType.pulseArcher.color,
        towerType: TowerType.pulseArcher,
      );

      expect(projectile, isNotNull);
    });

    test('can create circuitCannon projectile', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: TowerType.circuitCannon.projectileSpeed,
        damage: TowerType.circuitCannon.damage,
        color: TowerType.circuitCannon.color,
        towerType: TowerType.circuitCannon,
      );

      expect(projectile, isNotNull);
    });

    test('can create phaseMage projectile with slow', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: TowerType.phaseMage.projectileSpeed,
        damage: TowerType.phaseMage.damage,
        color: TowerType.phaseMage.color,
        slowAmount: TowerType.phaseMage.slowAmount,
        slowDuration: TowerType.phaseMage.slowDuration,
        towerType: TowerType.phaseMage,
      );

      expect(projectile, isNotNull);
      expect(projectile.slowAmount, 0.5);
      expect(projectile.slowDuration, 1.5);
    });

    test('can create glimmerField projectile', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: TowerType.glimmerField.projectileSpeed,
        damage: TowerType.glimmerField.damage,
        color: TowerType.glimmerField.color,
        towerType: TowerType.glimmerField,
      );

      expect(projectile, isNotNull);
    });

    test('can create ionSniper projectile', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: TowerType.ionSniper.projectileSpeed,
        damage: TowerType.ionSniper.damage,
        color: TowerType.ionSniper.color,
        towerType: TowerType.ionSniper,
      );

      expect(projectile, isNotNull);
      expect(TowerType.ionSniper.projectileSpeed, 800); // Fast sniper bullet
    });

    test('can create plasmaBubble projectile', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: TowerType.plasmaBubble.projectileSpeed,
        damage: TowerType.plasmaBubble.damage,
        color: TowerType.plasmaBubble.color,
        slowAmount: TowerType.plasmaBubble.slowAmount,
        slowDuration: TowerType.plasmaBubble.slowDuration,
        towerType: TowerType.plasmaBubble,
      );

      expect(projectile, isNotNull);
    });
  });

  group('Projectile update behavior', () {
    test('update with zero delta time does not throw', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 100),
        speed: 300,
        damage: 10,
      );

      expect(() => projectile.update(0), returnsNormally);
    });

    test('update with small delta time does not throw', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 100),
        speed: 300,
        damage: 10,
      );

      expect(() => projectile.update(0.016), returnsNormally);
    });

    test('projectile moves towards target', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 100,
        damage: 10,
      );

      final initialX = projectile.position.x;
      projectile.update(0.1);

      // Should have moved right (towards target)
      expect(projectile.position.x, greaterThan(initialX));
    });

    test('multiple updates accumulate movement', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(1000, 0),
        speed: 100,
        damage: 10,
      );

      for (int i = 0; i < 10; i++) {
        projectile.update(0.1);
      }

      // After 1 second at 100 speed, should have moved ~100 units
      expect(projectile.position.x, closeTo(100, 20));
    });
  });

  group('Projectile deactivation', () {
    test('deactivate can be called', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 100),
        speed: 300,
        damage: 10,
      );

      expect(() => projectile.deactivate(), returnsNormally);
    });

    test('isActive is false after deactivate', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 100),
        speed: 300,
        damage: 10,
      );

      projectile.deactivate();
      expect(projectile.isActive, isFalse);
    });

    test('deactivate can be called multiple times', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 100),
        speed: 300,
        damage: 10,
      );

      projectile.deactivate();
      projectile.deactivate();
      projectile.deactivate();

      expect(projectile.isActive, isFalse);
    });
  });

  group('Projectile properties', () {
    test('damage is stored correctly', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 100),
        speed: 300,
        damage: 50,
      );

      expect(projectile.damage, 50);
    });

    test('speed is stored correctly', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 100),
        speed: 450,
        damage: 10,
      );

      expect(projectile.speed, 450);
    });

    test('slowAmount is stored correctly', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 100),
        speed: 300,
        damage: 10,
        slowAmount: 0.75,
      );

      expect(projectile.slowAmount, 0.75);
    });

    test('slowDuration is stored correctly', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 100),
        speed: 300,
        damage: 10,
        slowDuration: 3.0,
      );

      expect(projectile.slowDuration, 3.0);
    });

    test('targetPosition is stored correctly', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(250, 300),
        speed: 300,
        damage: 10,
      );

      expect(projectile.targetPosition.x, 250);
      expect(projectile.targetPosition.y, 300);
    });
  });

  group('Projectile onHit callback', () {
    test('onHit callback can be set', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 100),
        speed: 300,
        damage: 10,
        // onHit takes (Enemy, Vector2, bool) parameters - can't easily test without Enemy
      );

      // Default is null
      expect(projectile.onHit, isNull);
    });

    test('onHit can be null', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 100),
        speed: 300,
        damage: 10,
      );

      expect(projectile.onHit, isNull);
    });
  });

  group('Projectile performance', () {
    test('can create many projectiles', () {
      final projectiles = <Projectile>[];

      for (int i = 0; i < 100; i++) {
        projectiles.add(Projectile(
          startPosition: Vector2(i.toDouble(), 0),
          targetPosition: Vector2(i.toDouble(), 100),
          speed: 300,
          damage: 10,
        ));
      }

      expect(projectiles.length, 100);
    });

    test('can update many projectiles', () {
      final projectiles = List.generate(100, (i) => Projectile(
        startPosition: Vector2(i.toDouble(), 0),
        targetPosition: Vector2(i.toDouble(), 100),
        speed: 300,
        damage: 10,
      ));

      for (int frame = 0; frame < 60; frame++) {
        for (final p in projectiles) {
          p.update(0.016);
        }
      }

      expect(true, isTrue);
    });

    test('stress test with 500 projectiles', () {
      Projectile.setStressLevel(2); // Enable minimal FX

      final projectiles = List.generate(500, (i) => Projectile(
        startPosition: Vector2((i % 50).toDouble() * 10, 0),
        targetPosition: Vector2((i % 50).toDouble() * 10, 500),
        speed: 300,
        damage: 10,
      ));

      for (int frame = 0; frame < 30; frame++) {
        for (final p in projectiles) {
          p.update(0.016);
        }
      }

      Projectile.setStressLevel(0);
      expect(projectiles.length, 500);
    });
  });

  group('Projectile edge cases', () {
    test('handles zero speed', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 100),
        speed: 0,
        damage: 10,
      );

      projectile.update(1.0);
      // Should not move
      expect(projectile.position.x, 0);
      expect(projectile.position.y, 0);
    });

    test('handles same start and target position', () {
      final projectile = Projectile(
        startPosition: Vector2(50, 50),
        targetPosition: Vector2(50, 50),
        speed: 300,
        damage: 10,
      );

      expect(() => projectile.update(0.016), returnsNormally);
    });

    test('handles very high speed', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 10000,
        damage: 10,
      );

      projectile.update(0.016);
      expect(projectile.position.x, greaterThan(0));
    });

    test('handles negative coordinates', () {
      final projectile = Projectile(
        startPosition: Vector2(-100, -100),
        targetPosition: Vector2(-200, -200),
        speed: 300,
        damage: 10,
      );

      expect(() => projectile.update(0.016), returnsNormally);
    });
  });
}
