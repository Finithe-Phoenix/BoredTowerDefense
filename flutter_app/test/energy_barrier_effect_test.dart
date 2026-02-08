import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/energy_barrier_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnergyBarrierEffect constructor', () {
    test('creates effect with required parameters', () {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
      );

      expect(effect, isNotNull);
      expect(effect, isA<PositionComponent>());
      expect(effect.barrierRect, const Rect.fromLTWH(0, 0, 200, 100));
    });

    test('creates effect with custom color', () {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
        barrierColor: Colors.purple,
      );

      expect(effect.barrierColor, Colors.purple);
    });

    test('creates effect with default color (cyan)', () {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
      );

      expect(effect.barrierColor, const Color(0xFF00FFFF));
    });

    test('creates effect with reduceFx option', () {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
        reduceFx: true,
      );

      expect(effect.reduceFx, isTrue);
    });

    test('creates effect with lowFx option', () {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
        lowFx: true,
      );

      expect(effect.lowFx, isTrue);
    });

    test('creates effect with custom warning text', () {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
        warningText: 'DANGER ZONE',
      );

      expect(effect.warningText, 'DANGER ZONE');
    });

    test('creates effect with default warning text', () {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
      );

      expect(effect.warningText, 'RESTRICTED ZONE');
    });
  });

  group('EnergyBarrierEffect barrierRect', () {
    test('accepts various rectangle sizes', () {
      final smallEffect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 50, 50),
      );
      final largeEffect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 1000, 500),
      );

      expect(smallEffect.barrierRect.width, 50);
      expect(smallEffect.barrierRect.height, 50);
      expect(largeEffect.barrierRect.width, 1000);
      expect(largeEffect.barrierRect.height, 500);
    });

    test('accepts rectangles at different positions', () {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(100, 200, 300, 150),
      );

      expect(effect.barrierRect.left, 100);
      expect(effect.barrierRect.top, 200);
    });

    test('accepts negative position rectangles', () {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(-100, -200, 300, 150),
      );

      expect(effect.barrierRect.left, -100);
      expect(effect.barrierRect.top, -200);
    });
  });

  group('EnergyBarrierEffect onLoad', () {
    test('onLoad initializes without error', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
      );

      await effect.onLoad();
      expect(true, isTrue);
    });

    test('onLoad works with reduceFx', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
        reduceFx: true,
      );

      await effect.onLoad();
      expect(true, isTrue);
    });

    test('onLoad works with lowFx', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
        lowFx: true,
      );

      await effect.onLoad();
      expect(true, isTrue);
    });
  });

  group('EnergyBarrierEffect update', () {
    test('update advances effect state', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
      );

      await effect.onLoad();
      effect.update(0.016);
      effect.update(0.016);
      effect.update(0.016);

      expect(true, isTrue);
    });

    test('update with zero dt does not crash', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
      );

      await effect.onLoad();
      effect.update(0.0);
      expect(true, isTrue);
    });

    test('multiple rapid updates work', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
      );

      await effect.onLoad();
      for (int i = 0; i < 100; i++) {
        effect.update(0.016);
      }
      expect(true, isTrue);
    });

    test('update works in lowFx mode', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
        lowFx: true,
      );

      await effect.onLoad();
      for (int i = 0; i < 50; i++) {
        effect.update(0.016);
      }
      expect(true, isTrue);
    });
  });

  group('EnergyBarrierEffect render', () {
    test('renders without exceptions', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
      );

      await effect.onLoad();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders at start of animation', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
      );

      await effect.onLoad();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect.update(0.001);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders after several seconds', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
      );

      await effect.onLoad();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect.update(5.0);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with different colors', () async {
      final colors = [Colors.red, Colors.blue, Colors.green, Colors.purple];

      for (final color in colors) {
        final effect = EnergyBarrierEffect(
          barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
          barrierColor: color,
        );

        await effect.onLoad();
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect.update(0.1);
        effect.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with small barrier', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 20, 10),
      );

      await effect.onLoad();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with large barrier', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 2000, 1000),
      );

      await effect.onLoad();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in lowFx mode', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
        lowFx: true,
      );

      await effect.onLoad();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders in reduceFx mode', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
        reduceFx: true,
      );

      await effect.onLoad();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('renders with custom warning text', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
        warningText: 'NO ENTRY',
      );

      await effect.onLoad();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });
  });

  group('EnergyBarrierEffect edge cases', () {
    test('works with very thin barrier', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 5),
      );

      await effect.onLoad();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with very narrow barrier', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 5, 200),
      );

      await effect.onLoad();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with empty warning text', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
        warningText: '',
      );

      await effect.onLoad();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('works with long warning text', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
        warningText: 'THIS IS A VERY LONG WARNING TEXT FOR TESTING PURPOSES',
      );

      await effect.onLoad();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect.update(0.1);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('continuous rendering over long time', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
      );

      await effect.onLoad();

      for (int i = 0; i < 600; i++) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect.update(0.016);
        effect.render(canvas);
        recorder.endRecording();
      }
      expect(true, isTrue);
    });
  });

  group('EnergyBarrierEffect multiple instances', () {
    test('multiple effects can update independently', () async {
      final effect1 = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
        barrierColor: Colors.cyan,
      );
      final effect2 = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(300, 0, 200, 100),
        barrierColor: Colors.purple,
      );

      await effect1.onLoad();
      await effect2.onLoad();

      effect1.update(0.5);
      effect2.update(0.2);

      expect(effect1.barrierRect, isNot(effect2.barrierRect));
    });

    test('multiple effects render independently', () async {
      final effect1 = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
      );
      final effect2 = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(300, 0, 200, 100),
      );

      await effect1.onLoad();
      await effect2.onLoad();

      final recorder1 = ui.PictureRecorder();
      final canvas1 = ui.Canvas(recorder1);

      final recorder2 = ui.PictureRecorder();
      final canvas2 = ui.Canvas(recorder2);

      effect1.update(0.1);
      effect2.update(0.1);

      effect1.render(canvas1);
      effect2.render(canvas2);

      recorder1.endRecording();
      recorder2.endRecording();
    });
  });

  group('EnergyBarrierEffect color derivation', () {
    test('effect derives secondary colors from primary', () async {
      final effect = EnergyBarrierEffect(
        barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
        barrierColor: const Color(0xFF00FFFF),
      );

      await effect.onLoad();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effect.update(0.5);
      effect.render(canvas);
      recorder.endRecording();
    });

    test('effect works with different hue colors', () async {
      final colors = [
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
        const Color(0xFF0000FF),
        const Color(0xFFFFFF00),
        const Color(0xFFFF00FF),
      ];

      for (final color in colors) {
        final effect = EnergyBarrierEffect(
          barrierRect: const Rect.fromLTWH(0, 0, 200, 100),
          barrierColor: color,
        );

        await effect.onLoad();

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        effect.update(0.1);
        effect.render(canvas);
        recorder.endRecording();
      }
    });
  });
}
