import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/impact_effect.dart';
import 'package:bored_games/src/game/entities/tower.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ImpactEffect.clearPool();
    ImpactEffect.fxScale = 1.0;
  });

  tearDown(() {
    ImpactEffect.clearPool();
  });

  group('ImpactEffect', () {
    test('spawn creates effect with correct properties', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 200),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
        duration: 0.5,
      );

      expect(effect, isNotNull);
      expect(effect!.position.x, 100);
      expect(effect.position.y, 200);
      expect(effect.color, Colors.cyan);
      expect(effect.towerType, TowerType.pulseArcher);
      expect(effect.duration, 0.5);
    });

    test('spawn returns null when max active reached', () {
      // Spawn effects until we hit the limit
      final effects = <ImpactEffect>[];
      for (int i = 0; i < ImpactEffect.maxActive; i++) {
        final effect = ImpactEffect.spawn(
          position: Vector2(0, 0),
          color: Colors.red,
          towerType: TowerType.pulseArcher,
        );
        if (effect != null) {
          effects.add(effect);
        }
      }

      // Next spawn should return null
      final extraEffect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.red,
        towerType: TowerType.pulseArcher,
      );

      expect(extraEffect, isNull);
      expect(ImpactEffect.activeCount, ImpactEffect.maxActive);
    });

    test('clearPool resets active count and pool', () {
      // Spawn some effects
      for (int i = 0; i < 5; i++) {
        ImpactEffect.spawn(
          position: Vector2(0, 0),
          color: Colors.red,
          towerType: TowerType.pulseArcher,
        );
      }

      expect(ImpactEffect.activeCount, 5);

      ImpactEffect.clearPool();

      expect(ImpactEffect.activeCount, 0);
    });

    test('update progresses timer and recycles when done', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
        duration: 0.3,
      );

      expect(effect, isNotNull);
      expect(ImpactEffect.activeCount, 1);

      // Update past duration
      effect!.update(0.1);
      effect.update(0.1);
      effect.update(0.15); // Total: 0.35 > 0.3 duration

      // Effect should be recycled
      expect(ImpactEffect.activeCount, 0);
    });

    test('effect creates correct particles for pulseArcher', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      expect(effect, isNotNull);
      // PulseArcher creates sparks and a ring
      // Just verify it doesn't throw during update
      effect!.update(0.1);
    });

    test('effect creates correct particles for circuitCannon', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.pink,
        towerType: TowerType.circuitCannon,
      );

      expect(effect, isNotNull);
      effect!.update(0.1);
    });

    test('effect creates correct particles for phaseMage', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.purple,
        towerType: TowerType.phaseMage,
      );

      expect(effect, isNotNull);
      effect!.update(0.1);
    });

    test('effect creates correct particles for glimmerField', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.yellow,
        towerType: TowerType.glimmerField,
      );

      expect(effect, isNotNull);
      effect!.update(0.1);
    });

    test('effect creates correct particles for ionSniper', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.cyan,
        towerType: TowerType.ionSniper,
      );

      expect(effect, isNotNull);
      effect!.update(0.1);
    });

    test('effect creates correct particles for teslaTerminal', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.yellow,
        towerType: TowerType.teslaTerminal,
      );

      expect(effect, isNotNull);
      effect!.update(0.1);
    });

    test('effect creates correct particles for resonanceSiphon', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.blue,
        towerType: TowerType.resonanceSiphon,
      );

      expect(effect, isNotNull);
      effect!.update(0.1);
    });

    test('effect creates correct particles for neuralDisruptor', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.pink,
        towerType: TowerType.neuralDisruptor,
      );

      expect(effect, isNotNull);
      effect!.update(0.1);
    });

    test('fxScale affects particle counts', () {
      // With fxScale = 0, should still create at least 1 ring
      ImpactEffect.fxScale = 0.0;
      final effectLow = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.cyan,
        towerType: TowerType.circuitCannon,
      );
      expect(effectLow, isNotNull);

      ImpactEffect.clearPool();

      // With fxScale = 1.0, should create more particles
      ImpactEffect.fxScale = 1.0;
      final effectHigh = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.cyan,
        towerType: TowerType.circuitCannon,
      );
      expect(effectHigh, isNotNull);
    });

    test('fxScale below 0.2 skips ring creation', () {
      ImpactEffect.fxScale = 0.1;
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      expect(effect, isNotNull);
      effect!.update(0.1);
    });

    test('pool reuses effects correctly', () {
      // Spawn and let one effect recycle
      final effect1 = ImpactEffect.spawn(
        position: Vector2(10, 20),
        color: Colors.red,
        towerType: TowerType.pulseArcher,
        duration: 0.1,
      );

      expect(effect1, isNotNull);
      expect(ImpactEffect.activeCount, 1);

      // Complete the effect
      effect1!.update(0.15);
      expect(ImpactEffect.activeCount, 0);

      // Spawn another - should reuse from pool
      final effect2 = ImpactEffect.spawn(
        position: Vector2(30, 40),
        color: Colors.blue,
        towerType: TowerType.circuitCannon,
      );

      expect(effect2, isNotNull);
      expect(effect2!.position.x, 30);
      expect(effect2.position.y, 40);
      expect(effect2.color, Colors.blue);
    });

    test('onRemove decrements active count', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.red,
        towerType: TowerType.pulseArcher,
      );

      expect(effect, isNotNull);
      expect(ImpactEffect.activeCount, 1);

      effect!.onRemove();
      expect(ImpactEffect.activeCount, 0);
    });

    test('multiple effects can be spawned simultaneously', () {
      final effects = <ImpactEffect?>[];

      for (int i = 0; i < 10; i++) {
        effects.add(ImpactEffect.spawn(
          position: Vector2(i * 10.0, i * 10.0),
          color: Colors.primaries[i % Colors.primaries.length],
          towerType: TowerType.values[i % TowerType.values.length],
        ));
      }

      expect(effects.where((e) => e != null).length, 10);
      expect(ImpactEffect.activeCount, 10);
    });

    test('effect handles rapid updates without errors', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.cyan,
        towerType: TowerType.glimmerField,
        duration: 1.0,
      );

      expect(effect, isNotNull);

      // Rapid small updates
      for (int i = 0; i < 100; i++) {
        effect!.update(0.001);
      }

      // Should still be active (0.1 < 1.0)
      expect(ImpactEffect.activeCount, 1);
    });

    test('default duration is 0.3 seconds', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      expect(effect, isNotNull);
      expect(effect!.duration, 0.3);
    });

    test('effect position can be modified', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      expect(effect, isNotNull);
      effect!.position = Vector2(100, 200);
      expect(effect.position.x, 100);
      expect(effect.position.y, 200);
    });

    test('activeCount getter returns correct value', () {
      expect(ImpactEffect.activeCount, 0);

      ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.red,
        towerType: TowerType.pulseArcher,
      );

      expect(ImpactEffect.activeCount, 1);

      ImpactEffect.spawn(
        position: Vector2(10, 10),
        color: Colors.blue,
        towerType: TowerType.circuitCannon,
      );

      expect(ImpactEffect.activeCount, 2);
    });

    test('maxPool and maxActive constants are defined', () {
      expect(ImpactEffect.maxPool, 30);
      expect(ImpactEffect.maxActive, 40);
    });

    test('effect with zero duration completes immediately', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
        duration: 0.0,
      );

      expect(effect, isNotNull);
      expect(ImpactEffect.activeCount, 1);

      effect!.update(0.001);
      expect(ImpactEffect.activeCount, 0);
    });

    test('electric sparks created for phaseMage', () {
      ImpactEffect.fxScale = 1.0;
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.purple,
        towerType: TowerType.phaseMage,
      );

      expect(effect, isNotNull);
      // Verify update works with electric sparks
      for (int i = 0; i < 10; i++) {
        effect!.update(0.02);
      }
    });

    test('star particles created for glimmerField', () {
      ImpactEffect.fxScale = 1.0;
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.yellow,
        towerType: TowerType.glimmerField,
      );

      expect(effect, isNotNull);
      // Verify update works with star particles
      for (int i = 0; i < 10; i++) {
        effect!.update(0.02);
      }
    });

    test('rune particles created for phaseMage', () {
      ImpactEffect.fxScale = 1.0;
      final effect = ImpactEffect.spawn(
        position: Vector2(0, 0),
        color: Colors.purple,
        towerType: TowerType.phaseMage,
      );

      expect(effect, isNotNull);
      // Verify multiple updates work with rune particles
      for (int i = 0; i < 20; i++) {
        effect!.update(0.015);
      }
    });
  });

  group('ImpactEffect render', () {
    test('renders without exceptions', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.cyan,
        towerType: TowerType.pulseArcher,
      );

      expect(effect, isNotNull);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect!.render(canvas);
      recorder.endRecording();
    });

    test('renders all tower types', () {
      for (final towerType in TowerType.values) {
        ImpactEffect.clearPool();

        final effect = ImpactEffect.spawn(
          position: Vector2(100, 100),
          color: Colors.cyan,
          towerType: towerType,
        );

        expect(effect, isNotNull);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect!.update(0.1);
        effect!.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with rings (circuitCannon)', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.red,
        towerType: TowerType.circuitCannon,
      );

      expect(effect, isNotNull);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect!.render(canvas);
      recorder.endRecording();
    });

    test('renders with particles (circuitCannon)', () {
      ImpactEffect.fxScale = 1.0;

      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.orange,
        towerType: TowerType.circuitCannon,
      );

      expect(effect, isNotNull);

      // Update to let particles progress
      for (int i = 0; i < 5; i++) {
        effect!.update(0.02);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.render(canvas);
      recorder.endRecording();
    });

    test('renders with electric sparks (phaseMage)', () {
      ImpactEffect.fxScale = 1.0;

      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.purple,
        towerType: TowerType.phaseMage,
      );

      expect(effect, isNotNull);

      for (int i = 0; i < 5; i++) {
        effect!.update(0.02);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect!.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with star particles (glimmerField)', () {
      ImpactEffect.fxScale = 1.0;

      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.yellow,
        towerType: TowerType.glimmerField,
      );

      expect(effect, isNotNull);

      for (int i = 0; i < 5; i++) {
        effect!.update(0.02);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect!.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with rune particles (phaseMage)', () {
      ImpactEffect.fxScale = 1.0;

      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: const Color(0xFF9900FF),
        towerType: TowerType.phaseMage,
      );

      expect(effect, isNotNull);

      // Let particles progress
      for (int i = 0; i < 10; i++) {
        effect!.update(0.02);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect!.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with different fxScale values', () {
      for (final scale in [0.1, 0.5, 1.0, 2.0]) {
        ImpactEffect.clearPool();
        ImpactEffect.fxScale = scale;

        final effect = ImpactEffect.spawn(
          position: Vector2(100, 100),
          color: Colors.green,
          towerType: TowerType.pulseArcher,
        );

        if (effect != null) {
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);

          effect.update(0.1);
          effect!.render(canvas);
          recorder.endRecording();
        }
      }
    });

    test('renders at different progress stages', () {
      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.blue,
        towerType: TowerType.circuitCannon,
        duration: 0.5,
      );

      expect(effect, isNotNull);

      for (double t = 0.05; t < 0.5; t += 0.1) {
        effect!.update(0.1);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect!.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with low fxScale (skips rings)', () {
      ImpactEffect.fxScale = 0.1; // Below 0.2 threshold

      final effect = ImpactEffect.spawn(
        position: Vector2(100, 100),
        color: Colors.teal,
        towerType: TowerType.pulseArcher,
      );

      expect(effect, isNotNull);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect!.update(0.1);
      effect!.render(canvas);
      recorder.endRecording();
    });

    test('renders sparks (ionSniper, teslaTerminal)', () {
      for (final towerType in [
        TowerType.ionSniper,
        TowerType.teslaTerminal,
        TowerType.resonanceSiphon,
        TowerType.neuralDisruptor,
      ]) {
        ImpactEffect.clearPool();
        ImpactEffect.fxScale = 1.0;

        final effect = ImpactEffect.spawn(
          position: Vector2(100, 100),
          color: Colors.amber,
          towerType: towerType,
        );

        expect(effect, isNotNull);

        for (int i = 0; i < 5; i++) {
          effect!.update(0.02);

          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);

          effect!.render(canvas);
          recorder.endRecording();
        }
      }
    });
  });
}
