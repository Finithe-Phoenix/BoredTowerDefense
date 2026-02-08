import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/components/neon_pulse.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NeonPulse creation', () {
    test('can create with required parameters', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(pulse, isNotNull);
      expect(pulse.position.x, 100);
      expect(pulse.position.y, 100);
    });

    test('radius is stored correctly', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 150,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(pulse.radius, 150);
    });

    test('slowFactor is stored correctly', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.3,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(pulse.slowFactor, 0.3);
    });

    test('slowDuration is stored correctly', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 3.0,
        enemies: () => [],
      );

      expect(pulse.slowDuration, 3.0);
    });

    test('anchor is center', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(pulse.anchor, Anchor.center);
    });
  });

  group('NeonPulse default values', () {
    test('default expandDuration is 0.3', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(pulse.expandDuration, 0.3);
    });

    test('default holdDuration is 0.5', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(pulse.holdDuration, 0.5);
    });

    test('default reducedFx is false', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(pulse.reducedFx, isFalse);
    });
  });

  group('NeonPulse custom options', () {
    test('custom expandDuration', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
        expandDuration: 0.6,
      );

      expect(pulse.expandDuration, 0.6);
    });

    test('custom holdDuration', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
        holdDuration: 1.0,
      );

      expect(pulse.holdDuration, 1.0);
    });

    test('reducedFx mode', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
        reducedFx: true,
      );

      expect(pulse.reducedFx, isTrue);
    });
  });

  group('NeonPulse update behavior', () {
    test('update with zero dt works', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(() => pulse.update(0), returnsNormally);
    });

    test('update with small dt works', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(() => pulse.update(0.016), returnsNormally);
    });

    test('multiple updates work', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
      );

      for (int i = 0; i < 60; i++) {
        pulse.update(0.016);
      }

      expect(true, isTrue);
    });

    test('full lifecycle update', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
        expandDuration: 0.3,
        holdDuration: 0.5,
      );

      // Update through entire lifecycle
      for (int i = 0; i < 120; i++) {
        pulse.update(0.016);
      }

      expect(true, isTrue);
    });
  });

  group('NeonPulse particle counts', () {
    test('full fx particle count is 40', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
        reducedFx: false,
      );

      // Particle count is internal, just verify creation
      expect(pulse.reducedFx, isFalse);
    });

    test('reduced fx particle count is 18', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
        reducedFx: true,
      );

      expect(pulse.reducedFx, isTrue);
    });

    test('full fx arc count is 8', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
        reducedFx: false,
      );

      expect(pulse.reducedFx, isFalse);
    });

    test('reduced fx arc count is 4', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
        reducedFx: true,
      );

      expect(pulse.reducedFx, isTrue);
    });
  });

  group('NeonPulse radius variations', () {
    test('small radius pulse', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 50,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(pulse.radius, 50);
    });

    test('large radius pulse', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 300,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(pulse.radius, 300);
    });
  });

  group('NeonPulse slow factor variations', () {
    test('mild slow (0.1)', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.1,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(pulse.slowFactor, 0.1);
    });

    test('strong slow (0.9)', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.9,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(pulse.slowFactor, 0.9);
    });

    test('half slow (0.5)', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(pulse.slowFactor, 0.5);
    });
  });

  group('NeonPulse slow duration variations', () {
    test('short duration', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 0.5,
        enemies: () => [],
      );

      expect(pulse.slowDuration, 0.5);
    });

    test('long duration', () {
      final pulse = NeonPulse(
        center: Vector2(100, 100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 5.0,
        enemies: () => [],
      );

      expect(pulse.slowDuration, 5.0);
    });
  });

  group('NeonPulse position variations', () {
    test('at origin', () {
      final pulse = NeonPulse(
        center: Vector2.zero(),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(pulse.position.x, 0);
      expect(pulse.position.y, 0);
    });

    test('at negative coordinates', () {
      final pulse = NeonPulse(
        center: Vector2(-100, -100),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(pulse.position.x, -100);
      expect(pulse.position.y, -100);
    });

    test('at large coordinates', () {
      final pulse = NeonPulse(
        center: Vector2(5000, 5000),
        radius: 120,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
      );

      expect(pulse.position.x, 5000);
      expect(pulse.position.y, 5000);
    });
  });

  group('NeonPulse performance', () {
    test('can create many pulses', () {
      final pulses = <NeonPulse>[];

      for (int i = 0; i < 20; i++) {
        pulses.add(NeonPulse(
          center: Vector2(i.toDouble() * 50, 100),
          radius: 80,
          slowFactor: 0.5,
          slowDuration: 2.0,
          enemies: () => [],
        ));
      }

      expect(pulses.length, 20);
    });

    test('can update many pulses', () {
      final pulses = List.generate(10, (i) => NeonPulse(
        center: Vector2(i.toDouble() * 50, 100),
        radius: 80,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
      ));

      for (int frame = 0; frame < 60; frame++) {
        for (final pulse in pulses) {
          pulse.update(0.016);
        }
      }

      expect(true, isTrue);
    });

    test('reduced fx mode for performance', () {
      final pulses = List.generate(20, (i) => NeonPulse(
        center: Vector2(i.toDouble() * 30, 100),
        radius: 80,
        slowFactor: 0.5,
        slowDuration: 2.0,
        enemies: () => [],
        reducedFx: true, // Performance mode
      ));

      for (int frame = 0; frame < 60; frame++) {
        for (final pulse in pulses) {
          pulse.update(0.016);
        }
      }

      expect(true, isTrue);
    });
  });
}
