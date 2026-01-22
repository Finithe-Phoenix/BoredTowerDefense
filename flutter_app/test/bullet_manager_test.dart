import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/managers/bullet_manager.dart';
import 'package:bored_games/src/game/entities/projectile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BulletManager.clearPool();
    Projectile.lowFx = false;
    Projectile.allowTrails = true;
    Projectile.allowGlow = true;
    Projectile.stressLevel = 0;
  });

  tearDown(() {
    BulletManager.clearPool();
  });

  group('BulletManager creation', () {
    test('creates with default poolSize', () {
      final manager = BulletManager();
      expect(manager.poolSize, 300);
    });

    test('creates with custom poolSize', () {
      final manager = BulletManager(poolSize: 500);
      expect(manager.poolSize, 500);
    });

    test('activeCount starts at 0 after clear', () {
      final manager = BulletManager();
      expect(manager.activeCount, 0);
    });
  });

  group('BulletManager constants', () {
    test('maxActiveProjectiles is 200', () {
      expect(BulletManager.maxActiveProjectiles, 200);
    });

    test('maxPoolSize is 150', () {
      expect(BulletManager.maxPoolSize, 150);
    });
  });

  group('BulletManager.clearPool', () {
    test('clearPool resets activeCount', () {
      final manager = BulletManager();

      BulletManager.clearPool();

      expect(manager.activeCount, 0);
    });

    test('clearPool resets stress level', () {
      BulletManager.clearPool();

      expect(Projectile.stressLevel, 0);
    });

    test('can call clearPool multiple times', () {
      BulletManager.clearPool();
      BulletManager.clearPool();
      BulletManager.clearPool();

      expect(true, isTrue);
    });
  });

  group('BulletManager.returnToPool', () {
    test('returnToPool does not throw', () {
      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 100,
        damage: 10,
      );

      expect(() => BulletManager.returnToPool(projectile), returnsNormally);
    });

    test('returnToPool with empty active count', () {
      BulletManager.clearPool();

      final projectile = Projectile(
        startPosition: Vector2.zero(),
        targetPosition: Vector2(100, 0),
        speed: 100,
        damage: 10,
      );

      // activeCount is 0, so it should handle gracefully
      BulletManager.returnToPool(projectile);

      expect(true, isTrue);
    });

    test('can return multiple projectiles to pool', () {
      for (int i = 0; i < 10; i++) {
        final projectile = Projectile(
          startPosition: Vector2.zero(),
          targetPosition: Vector2(100, 0),
          speed: 100,
          damage: 10,
        );
        BulletManager.returnToPool(projectile);
      }

      expect(true, isTrue);
    });
  });

  group('BulletManager multiple instances', () {
    test('multiple managers share static pool', () {
      final manager1 = BulletManager(poolSize: 100);
      final manager2 = BulletManager(poolSize: 200);

      // Both should see the same activeCount
      expect(manager1.activeCount, equals(manager2.activeCount));
    });

    test('clearPool affects all instances', () {
      final manager1 = BulletManager();
      final manager2 = BulletManager();

      BulletManager.clearPool();

      expect(manager1.activeCount, 0);
      expect(manager2.activeCount, 0);
    });
  });

  group('Projectile stress level integration', () {
    test('clearPool resets projectile stress level to 0', () {
      Projectile.setStressLevel(2);
      expect(Projectile.stressLevel, 2);

      BulletManager.clearPool();

      expect(Projectile.stressLevel, 0);
    });
  });
}
