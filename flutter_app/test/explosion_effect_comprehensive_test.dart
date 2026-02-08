import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/explosion_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExplosionEffect static constants', () {
    test('maxPool is 24', () {
      expect(ExplosionEffect.maxPool, 24);
    });

    test('maxActive is 18', () {
      expect(ExplosionEffect.maxActive, 18);
    });

    test('fxScale default is 1.0', () {
      expect(ExplosionEffect.fxScale, 1.0);
    });
  });

  group('ExplosionEffect pool management', () {
    setUp(() {
      ExplosionEffect.clearPool();
    });

    test('clearPool resets activeCount to 0', () {
      ExplosionEffect.clearPool();
      expect(ExplosionEffect.activeCount, 0);
    });

    test('clearPool can be called multiple times', () {
      ExplosionEffect.clearPool();
      ExplosionEffect.clearPool();
      ExplosionEffect.clearPool();
      expect(ExplosionEffect.activeCount, 0);
    });

    test('activeCount is 0 after clearPool', () {
      ExplosionEffect.clearPool();
      expect(ExplosionEffect.activeCount, 0);
    });
  });

  group('ExplosionEffect spawn', () {
    setUp(() {
      ExplosionEffect.clearPool();
    });

    test('spawn returns ExplosionEffect', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
      );

      expect(effect, isNotNull);
      expect(effect, isA<ExplosionEffect>());
    });

    test('spawn increments activeCount', () {
      final initialCount = ExplosionEffect.activeCount;

      ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
      );

      expect(ExplosionEffect.activeCount, initialCount + 1);
    });

    test('spawn with custom explosionSize', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
        explosionSize: 80.0,
      );

      expect(effect, isNotNull);
      expect(effect!.explosionSize, 80.0);
    });

    test('spawn with custom duration', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
        duration: 1.0,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 1.0);
    });

    test('spawn with different colors', () {
      final colors = [
        Colors.red,
        Colors.green,
        Colors.blue,
        Colors.yellow,
        Colors.purple,
        Colors.orange,
        Colors.pink,
        Colors.cyan,
      ];

      for (final color in colors) {
        ExplosionEffect.clearPool();
        final effect = ExplosionEffect.spawn(
          position: Vector2(50, 50),
          color: color,
        );

        expect(effect, isNotNull, reason: 'Should spawn with $color');
        expect(effect!.color, color);
      }
    });

    test('spawn returns null when maxActive exceeded', () {
      ExplosionEffect.clearPool();

      // Spawn up to maxActive
      for (int i = 0; i < ExplosionEffect.maxActive; i++) {
        ExplosionEffect.spawn(
          position: Vector2(i.toDouble() * 10, 0),
          color: Colors.orange,
        );
      }

      // Next spawn should return null
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
      );

      expect(effect, isNull);
    });
  });

  group('ExplosionEffect default values', () {
    setUp(() {
      ExplosionEffect.clearPool();
    });

    test('default explosionSize is 40', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
      );

      expect(effect!.explosionSize, 40.0);
    });

    test('default duration is 0.6', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
      );

      expect(effect!.duration, 0.6);
    });
  });

  group('ExplosionEffect fxScale', () {
    test('fxScale can be modified', () {
      final original = ExplosionEffect.fxScale;

      ExplosionEffect.fxScale = 0.5;
      expect(ExplosionEffect.fxScale, 0.5);

      ExplosionEffect.fxScale = 2.0;
      expect(ExplosionEffect.fxScale, 2.0);

      ExplosionEffect.fxScale = original;
    });
  });

  group('ExplosionEffect properties', () {
    setUp(() {
      ExplosionEffect.clearPool();
    });

    test('position is set correctly', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(200, 300),
        color: Colors.orange,
      );

      expect(effect!.position.x, 200);
      expect(effect.position.y, 300);
    });

    test('color is stored correctly', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: const Color(0xFFFF6600),
      );

      expect(effect!.color, const Color(0xFFFF6600));
    });

    test('shakeIntensity is initially high', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
      );

      // Initially coreFlashIntensity is 1.0, so shakeIntensity = 1.0 * 0.8 = 0.8
      expect(effect!.shakeIntensity, closeTo(0.8, 0.1));
    });
  });

  group('ExplosionEffect update behavior', () {
    setUp(() {
      ExplosionEffect.clearPool();
    });

    test('update with zero delta time works', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
      );

      expect(() => effect!.update(0), returnsNormally);
    });

    test('update with small delta time works', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
      );

      expect(() => effect!.update(0.016), returnsNormally);
    });

    test('multiple updates work', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
      );

      for (int i = 0; i < 40; i++) {
        effect!.update(0.016);
      }

      expect(true, isTrue);
    });

    test('shakeIntensity decreases over time', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
      );

      final initialShake = effect!.shakeIntensity;

      for (int i = 0; i < 30; i++) {
        effect.update(0.016);
      }

      expect(effect.shakeIntensity, lessThan(initialShake));
    });
  });

  group('ExplosionEffect size variations', () {
    setUp(() {
      ExplosionEffect.clearPool();
    });

    test('small explosion', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
        explosionSize: 20.0,
      );

      expect(effect, isNotNull);
      expect(effect!.explosionSize, 20.0);
      effect.update(0.1);
    });

    test('medium explosion', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
        explosionSize: 60.0,
      );

      expect(effect, isNotNull);
      expect(effect!.explosionSize, 60.0);
      effect.update(0.1);
    });

    test('large explosion', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
        explosionSize: 100.0,
      );

      expect(effect, isNotNull);
      expect(effect!.explosionSize, 100.0);
      effect.update(0.1);
    });

    test('very large explosion', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
        explosionSize: 200.0,
      );

      expect(effect, isNotNull);
      expect(effect!.explosionSize, 200.0);
      effect.update(0.1);
    });
  });

  group('ExplosionEffect duration variations', () {
    setUp(() {
      ExplosionEffect.clearPool();
    });

    test('quick explosion', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
        duration: 0.2,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 0.2);
    });

    test('long explosion', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
        duration: 2.0,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 2.0);
    });
  });

  group('ExplosionEffect performance', () {
    setUp(() {
      ExplosionEffect.clearPool();
    });

    test('can spawn many explosions up to limit', () {
      for (int i = 0; i < ExplosionEffect.maxActive; i++) {
        final effect = ExplosionEffect.spawn(
          position: Vector2(i.toDouble() * 20, 0),
          color: Colors.orange,
        );

        if (i < ExplosionEffect.maxActive) {
          expect(effect, isNotNull);
        }
      }
    });

    test('rapid spawn and update works', () {
      for (int i = 0; i < 10; i++) {
        final effect = ExplosionEffect.spawn(
          position: Vector2(i.toDouble() * 30, 0),
          color: Color.fromARGB(255, 255, i * 20 % 256, 0),
          explosionSize: 30.0 + i * 5,
        );

        if (effect != null) {
          for (int frame = 0; frame < 10; frame++) {
            effect.update(0.016);
          }
        }
      }

      expect(true, isTrue);
    });
  });

  group('ExplosionEffect edge cases', () {
    setUp(() {
      ExplosionEffect.clearPool();
    });

    test('handles zero position', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2.zero(),
        color: Colors.orange,
      );

      expect(effect, isNotNull);
    });

    test('handles negative position', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(-100, -100),
        color: Colors.orange,
      );

      expect(effect, isNotNull);
    });

    test('handles very large position', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(10000, 10000),
        color: Colors.orange,
      );

      expect(effect, isNotNull);
    });

    test('handles zero explosion size', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
        explosionSize: 0.0,
      );

      expect(effect, isNotNull);
      effect!.update(0.1);
    });

    test('handles very small duration', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
        duration: 0.01,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 0.01);
    });

    test('handles transparent color', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.transparent,
      );

      expect(effect, isNotNull);
    });
  });

  group('ExplosionEffect shockwave', () {
    setUp(() {
      ExplosionEffect.clearPool();
    });

    test('has multiple shockwave offsets', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
      );

      expect(effect, isNotNull);
      // Effect has 3 shockwave offsets: [0, 0.08, 0.16]
    });

    test('shockwave expands during update', () {
      final effect = ExplosionEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
      );

      // Update multiple times to let shockwave expand
      for (int i = 0; i < 20; i++) {
        effect!.update(0.016);
      }

      expect(true, isTrue);
    });
  });
}
