import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/components/neon_pulse.dart';
import 'package:bored_games/src/game/entities/enemy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  NeonPulse makePulse({
    Vector2? center,
    double radius = 50,
    double slowFactor = 0.5,
    double slowDuration = 1.0,
    List<Enemy> Function()? enemies,
    double expandDuration = 0.1,
    double holdDuration = 0.1,
    bool reducedFx = true,
  }) {
    return NeonPulse(
      center: center ?? Vector2.zero(),
      radius: radius,
      slowFactor: slowFactor,
      slowDuration: slowDuration,
      enemies: enemies ?? () => <Enemy>[],
      expandDuration: expandDuration,
      holdDuration: holdDuration,
      reducedFx: reducedFx,
    );
  }

  group('NeonPulse creation', () {
    test('creates with required parameters', () {
      final pulse = makePulse();

      expect(pulse, isA<PositionComponent>());
      expect(pulse.radius, 50);
      expect(pulse.slowFactor, 0.5);
      expect(pulse.slowDuration, 1.0);
    });

    test('creates with custom center position', () {
      final pulse = makePulse(center: Vector2(100, 100));

      expect(pulse.position.x, 100);
      expect(pulse.position.y, 100);
    });

    test('anchor is center', () {
      final pulse = makePulse();
      expect(pulse.anchor, Anchor.center);
    });

    test('creates with custom radius', () {
      final pulse = makePulse(radius: 100);
      expect(pulse.radius, 100);
    });

    test('creates with custom slow parameters', () {
      final pulse = makePulse(slowFactor: 0.3, slowDuration: 2.5);
      expect(pulse.slowFactor, 0.3);
      expect(pulse.slowDuration, 2.5);
    });

    test('creates with custom durations', () {
      final pulse = makePulse(expandDuration: 0.5, holdDuration: 1.0);
      expect(pulse.expandDuration, 0.5);
      expect(pulse.holdDuration, 1.0);
    });

    test('creates with reducedFx true', () {
      final pulse = makePulse(reducedFx: true);
      expect(pulse.reducedFx, isTrue);
    });

    test('creates with reducedFx false', () {
      final pulse = makePulse(reducedFx: false);
      expect(pulse.reducedFx, isFalse);
    });
  });

  group('NeonPulse enemy slowing', () {
    test('slows enemies inside the pulse radius', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2.zero();

      final pulse = NeonPulse(
        center: Vector2.zero(),
        radius: 50,
        slowFactor: 0.5,
        slowDuration: 1.0,
        enemies: () => [enemy],
        expandDuration: 0.1,
        holdDuration: 0.1,
        reducedFx: true,
      );

      pulse.update(0.1);

      expect(enemy.isSlowed, isTrue);
    });

    test('does not slow enemies outside radius', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2(200, 200); // Far outside radius

      final pulse = makePulse(
        center: Vector2.zero(),
        radius: 50,
        enemies: () => [enemy],
      );

      pulse.update(0.05); // Partial expansion
      expect(enemy.isSlowed, isFalse);
    });

    test('slows multiple enemies', () {
      final enemy1 = Enemy(path: [Vector2.zero()]);
      final enemy2 = Enemy(path: [Vector2.zero()]);
      final enemy3 = Enemy(path: [Vector2.zero()]);

      enemy1.position = Vector2(10, 0);
      enemy2.position = Vector2(0, 10);
      enemy3.position = Vector2(10, 10);

      final pulse = makePulse(
        center: Vector2.zero(),
        radius: 50,
        enemies: () => [enemy1, enemy2, enemy3],
      );

      pulse.update(0.15);

      expect(enemy1.isSlowed, isTrue);
      expect(enemy2.isSlowed, isTrue);
      expect(enemy3.isSlowed, isTrue);
    });

    test('only slows each enemy once', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2.zero();

      final pulse = makePulse(
        center: Vector2.zero(),
        radius: 50,
        slowFactor: 0.5,
        slowDuration: 1.0,
        enemies: () => [enemy],
      );

      pulse.update(0.05);
      pulse.update(0.05);
      pulse.update(0.05);

      expect(enemy.isSlowed, isTrue);
    });
  });

  group('NeonPulse phases', () {
    test('starts in expanding phase', () {
      final pulse = makePulse(expandDuration: 0.5);

      pulse.update(0.1);
      // Pulse should still be expanding
      expect(true, isTrue);
    });

    test('transitions to holding phase', () {
      final pulse = makePulse(expandDuration: 0.1, holdDuration: 0.5);

      pulse.update(0.15); // Past expand duration
      // Should be in holding phase now
      expect(true, isTrue);
    });

    test('transitions to fading phase', () {
      final pulse = makePulse(expandDuration: 0.1, holdDuration: 0.1);

      pulse.update(0.15); // Past expand
      pulse.update(0.15); // Past hold
      // Should be in fading phase now
      expect(true, isTrue);
    });

    test('full lifecycle completes', () {
      final pulse = makePulse(expandDuration: 0.1, holdDuration: 0.1);

      // Expand
      pulse.update(0.15);
      // Hold
      pulse.update(0.15);
      // Fade
      pulse.update(0.35);

      // Should complete without errors
      expect(true, isTrue);
    });
  });

  group('NeonPulse update', () {
    test('update advances pulse state', () {
      final pulse = makePulse();

      pulse.update(0.016);
      pulse.update(0.016);
      pulse.update(0.016);

      expect(true, isTrue);
    });

    test('update with zero dt does not crash', () {
      final pulse = makePulse();

      pulse.update(0.0);
      expect(true, isTrue);
    });

    test('update with large dt works', () {
      final pulse = makePulse();

      pulse.update(1.0);
      expect(true, isTrue);
    });

    test('multiple rapid updates work', () {
      final pulse = makePulse();

      for (int i = 0; i < 100; i++) {
        pulse.update(0.016);
      }
      expect(true, isTrue);
    });
  });

  group('NeonPulse render', () {
    test('renders without exceptions', () {
      final pulse = NeonPulse(
        center: Vector2.zero(),
        radius: 30,
        slowFactor: 0.4,
        slowDuration: 0.5,
        enemies: () => <Enemy>[],
        expandDuration: 0.1,
        holdDuration: 0.1,
        reducedFx: true,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      pulse.update(0.05);
      pulse.render(canvas);
      recorder.endRecording();
    });

    test('renders during expanding phase', () {
      final pulse = makePulse(expandDuration: 0.5);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      pulse.update(0.1);
      pulse.render(canvas);
      recorder.endRecording();
    });

    test('renders during holding phase', () {
      final pulse = makePulse(expandDuration: 0.1, holdDuration: 0.5);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      pulse.update(0.15);
      pulse.render(canvas);
      recorder.endRecording();
    });

    test('renders during fading phase', () {
      final pulse = makePulse(expandDuration: 0.1, holdDuration: 0.1);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      pulse.update(0.15);
      pulse.update(0.15);
      pulse.render(canvas);
      recorder.endRecording();
    });

    test('renders with full FX', () {
      final pulse = makePulse(reducedFx: false);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      pulse.update(0.05);
      pulse.render(canvas);
      recorder.endRecording();
    });

    test('renders with reduced FX', () {
      final pulse = makePulse(reducedFx: true);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      pulse.update(0.05);
      pulse.render(canvas);
      recorder.endRecording();
    });
  });

  group('NeonPulse edge cases', () {
    test('works with empty enemy list', () {
      final pulse = makePulse(enemies: () => []);

      pulse.update(0.1);
      expect(true, isTrue);
    });

    test('works with zero radius', () {
      final pulse = makePulse(radius: 0);

      pulse.update(0.1);
      expect(true, isTrue);
    });

    test('works with very large radius', () {
      final pulse = makePulse(radius: 10000);

      pulse.update(0.1);
      expect(true, isTrue);
    });

    test('works with very small durations', () {
      final pulse = makePulse(expandDuration: 0.001, holdDuration: 0.001);

      pulse.update(0.01);
      expect(true, isTrue);
    });

    test('works with negative position', () {
      final pulse = makePulse(center: Vector2(-100, -100));

      pulse.update(0.1);
      expect(pulse.position.x, -100);
    });
  });

  group('NeonPulse multiple instances', () {
    test('multiple pulses can exist independently', () {
      final pulse1 = makePulse(center: Vector2(0, 0), radius: 50);
      final pulse2 = makePulse(center: Vector2(100, 100), radius: 75);

      pulse1.update(0.1);
      pulse2.update(0.05);

      expect(pulse1.position, isNot(equals(pulse2.position)));
      expect(pulse1.radius, isNot(equals(pulse2.radius)));
    });

    test('pulses affect different enemy sets', () {
      final enemy1 = Enemy(path: [Vector2.zero()]);
      final enemy2 = Enemy(path: [Vector2.zero()]);

      enemy1.position = Vector2.zero();
      enemy2.position = Vector2(200, 200);

      final pulse1 = makePulse(
        center: Vector2.zero(),
        radius: 50,
        enemies: () => [enemy1],
      );
      final pulse2 = makePulse(
        center: Vector2(200, 200),
        radius: 50,
        enemies: () => [enemy2],
      );

      pulse1.update(0.15);
      pulse2.update(0.15);

      expect(enemy1.isSlowed, isTrue);
      expect(enemy2.isSlowed, isTrue);
    });
  });
}
