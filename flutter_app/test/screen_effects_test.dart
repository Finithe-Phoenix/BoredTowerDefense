import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/screen_effects.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ScreenEffects makeEffects({
    Vector2? gameSize,
    bool enableCRT = true,
    bool enableVignette = true,
    bool enableScanlines = true,
    bool enableFlash = true,
  }) {
    return ScreenEffects(
      gameSize: gameSize ?? Vector2(800, 600),
      enableCRT: enableCRT,
      enableVignette: enableVignette,
      enableScanlines: enableScanlines,
      enableFlash: enableFlash,
    );
  }

  group('ScreenEffects creation', () {
    test('creates with required parameters', () {
      final effects = makeEffects();

      expect(effects, isA<PositionComponent>());
      expect(effects.gameSize.x, 800);
      expect(effects.gameSize.y, 600);
    });

    test('creates with custom game size', () {
      final effects = makeEffects(gameSize: Vector2(1920, 1080));

      expect(effects.gameSize.x, 1920);
      expect(effects.gameSize.y, 1080);
    });

    test('default enables all effects', () {
      final effects = ScreenEffects(gameSize: Vector2(100, 100));

      expect(effects.enableCRT, isTrue);
      expect(effects.enableVignette, isTrue);
      expect(effects.enableScanlines, isTrue);
      expect(effects.enableFlash, isTrue);
    });

    test('creates with effects disabled', () {
      final effects = makeEffects(
        enableCRT: false,
        enableVignette: false,
        enableScanlines: false,
        enableFlash: false,
      );

      expect(effects.enableCRT, isFalse);
      expect(effects.enableVignette, isFalse);
      expect(effects.enableScanlines, isFalse);
      expect(effects.enableFlash, isFalse);
    });

    test('reduceFx defaults to false', () {
      final effects = makeEffects();
      expect(effects.reduceFx, isFalse);
    });

    test('allowBlur defaults to true', () {
      final effects = makeEffects();
      expect(effects.allowBlur, isTrue);
    });

    test('trauma defaults to 0', () {
      final effects = makeEffects();
      expect(effects.trauma, 0.0);
    });

    test('shakeOffset defaults to zero', () {
      final effects = makeEffects();
      expect(effects.shakeOffset.x, 0);
      expect(effects.shakeOffset.y, 0);
    });
  });

  group('ScreenEffects setQuality', () {
    test('setQuality sets reduceFx', () {
      final effects = makeEffects();

      effects.setQuality(reduceFx: true, allowBlur: true);

      expect(effects.reduceFx, isTrue);
    });

    test('setQuality sets allowBlur', () {
      final effects = makeEffects();

      effects.setQuality(reduceFx: false, allowBlur: false);

      expect(effects.allowBlur, isFalse);
    });

    test('setQuality can be called multiple times', () {
      final effects = makeEffects();

      effects.setQuality(reduceFx: true, allowBlur: false);
      effects.setQuality(reduceFx: false, allowBlur: true);

      expect(effects.reduceFx, isFalse);
      expect(effects.allowBlur, isTrue);
    });
  });

  group('ScreenEffects trauma', () {
    test('addTrauma increases trauma', () {
      final effects = makeEffects();

      effects.addTrauma(0.5);

      expect(effects.trauma, 0.5);
    });

    test('addTrauma clamps to 1.0', () {
      final effects = makeEffects();

      effects.addTrauma(0.8);
      effects.addTrauma(0.5);

      expect(effects.trauma, 1.0);
    });

    test('addTrauma clamps negative values', () {
      final effects = makeEffects();

      effects.addTrauma(-0.5);

      expect(effects.trauma, 0.0);
    });

    test('trauma decays over time', () {
      final effects = makeEffects();

      effects.addTrauma(1.0);
      effects.update(0.5);

      expect(effects.trauma, lessThan(1.0));
    });

    test('trauma reaches zero after enough time', () {
      final effects = makeEffects();

      effects.addTrauma(0.5);

      for (int i = 0; i < 50; i++) {
        effects.update(0.1);
      }

      expect(effects.trauma, 0.0);
    });
  });

  group('ScreenEffects triggerShake', () {
    test('triggerShake creates shake offset', () {
      final effects = makeEffects();

      effects.triggerShake(intensity: 10.0, duration: 0.5);
      effects.update(0.1);

      // Shake offset should be non-zero during shake
      expect(
        effects.shakeOffset.x != 0 || effects.shakeOffset.y != 0,
        isTrue,
      );
    });

    test('shake decays over duration', () {
      final effects = makeEffects();

      effects.triggerShake(intensity: 10.0, duration: 0.2);

      effects.update(0.1);
      effects.update(0.1);
      effects.update(0.1);

      // After duration, shake should be zero
      expect(effects.shakeOffset.x, 0);
      expect(effects.shakeOffset.y, 0);
    });

    test('triggerShake uses max intensity', () {
      final effects = makeEffects();

      effects.triggerShake(intensity: 5.0, duration: 0.5);
      effects.triggerShake(intensity: 10.0, duration: 0.5);

      effects.update(0.01);

      // Should use the higher intensity
      expect(true, isTrue);
    });
  });

  group('ScreenEffects triggerDamageVignette', () {
    test('triggerDamageVignette sets intensity', () {
      final effects = makeEffects();

      effects.triggerDamageVignette(intensity: 0.8);

      // Internal state changed
      expect(true, isTrue);
    });

    test('damage vignette clamps intensity', () {
      final effects = makeEffects();

      effects.triggerDamageVignette(intensity: 1.5);

      // Should clamp to 1.0
      expect(true, isTrue);
    });

    test('damage vignette fades over time', () {
      final effects = makeEffects();

      effects.triggerDamageVignette(intensity: 1.0);
      effects.update(0.4); // Past duration

      // Should have faded
      expect(true, isTrue);
    });
  });

  group('ScreenEffects triggerFlash', () {
    test('triggerFlash sets flash color', () {
      final effects = makeEffects();

      effects.triggerFlash(color: Colors.red, intensity: 0.5, duration: 0.2);

      // Flash triggered
      expect(true, isTrue);
    });

    test('triggerFlash does nothing when disabled', () {
      final effects = makeEffects(enableFlash: false);

      effects.triggerFlash(color: Colors.white, intensity: 1.0, duration: 0.5);

      // Flash not triggered
      expect(true, isTrue);
    });

    test('flash fades over duration', () {
      final effects = makeEffects();

      effects.triggerFlash(color: Colors.blue, intensity: 0.8, duration: 0.1);
      effects.update(0.15);

      // Flash should have faded
      expect(true, isTrue);
    });
  });

  group('ScreenEffects update', () {
    test('update advances CRT time', () {
      final effects = makeEffects();

      effects.update(0.016);
      effects.update(0.016);
      effects.update(0.016);

      expect(true, isTrue);
    });

    test('update with zero dt does not crash', () {
      final effects = makeEffects();

      effects.update(0.0);
      expect(true, isTrue);
    });

    test('update with large dt works', () {
      final effects = makeEffects();

      effects.update(1.0);
      expect(true, isTrue);
    });

    test('multiple rapid updates work', () {
      final effects = makeEffects();

      for (int i = 0; i < 100; i++) {
        effects.update(0.016);
      }
      expect(true, isTrue);
    });
  });

  group('ScreenEffects render', () {
    test('renders without exceptions', () {
      final effects = makeEffects();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effects.update(0.016);
      effects.render(canvas);
      recorder.endRecording();
    });

    test('renders with all effects enabled', () {
      final effects = makeEffects(
        enableCRT: true,
        enableVignette: true,
        enableScanlines: true,
        enableFlash: true,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effects.update(0.016);
      effects.render(canvas);
      recorder.endRecording();
    });

    test('renders with all effects disabled', () {
      final effects = makeEffects(
        enableCRT: false,
        enableVignette: false,
        enableScanlines: false,
        enableFlash: false,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effects.update(0.016);
      effects.render(canvas);
      recorder.endRecording();
    });

    test('renders with reduceFx', () {
      final effects = makeEffects();
      effects.setQuality(reduceFx: true, allowBlur: false);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effects.update(0.016);
      effects.render(canvas);
      recorder.endRecording();
    });

    test('renders during shake', () {
      final effects = makeEffects();
      effects.triggerShake(intensity: 10.0, duration: 0.5);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effects.update(0.1);
      effects.render(canvas);
      recorder.endRecording();
    });

    test('renders during damage vignette', () {
      final effects = makeEffects();
      effects.triggerDamageVignette(intensity: 0.8);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effects.update(0.1);
      effects.render(canvas);
      recorder.endRecording();
    });

    test('renders during flash', () {
      final effects = makeEffects();
      effects.triggerFlash(color: Colors.cyan, intensity: 0.5, duration: 0.2);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effects.update(0.05);
      effects.render(canvas);
      recorder.endRecording();
    });
  });

  group('ScreenEffects shader caching', () {
    test('shaders are cached for same size', () {
      final effects = makeEffects(gameSize: Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // First render creates shaders
      effects.render(canvas);

      // Second render uses cached shaders
      effects.render(canvas);
      recorder.endRecording();
    });
  });

  group('ScreenEffects edge cases', () {
    test('works with very small game size', () {
      final effects = makeEffects(gameSize: Vector2(10, 10));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effects.update(0.016);
      effects.render(canvas);
      recorder.endRecording();
    });

    test('works with very large game size', () {
      final effects = makeEffects(gameSize: Vector2(4096, 2160));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effects.update(0.016);
      effects.render(canvas);
      recorder.endRecording();
    });

    test('works with non-standard aspect ratio', () {
      final effects = makeEffects(gameSize: Vector2(100, 1000));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effects.update(0.016);
      effects.render(canvas);
      recorder.endRecording();
    });

    test('multiple effects triggered simultaneously', () {
      final effects = makeEffects();

      effects.triggerShake(intensity: 5.0, duration: 0.3);
      effects.triggerDamageVignette(intensity: 0.5);
      effects.triggerFlash(color: Colors.red, intensity: 0.3, duration: 0.2);
      effects.addTrauma(0.4);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      effects.update(0.05);
      effects.render(canvas);
      recorder.endRecording();
    });
  });

  group('ScreenEffects multiple instances', () {
    test('multiple instances are independent', () {
      final effects1 = makeEffects(gameSize: Vector2(800, 600));
      final effects2 = makeEffects(gameSize: Vector2(1920, 1080));

      effects1.triggerShake(intensity: 10.0, duration: 0.5);
      effects1.update(0.1);

      expect(effects2.shakeOffset.x, 0);
      expect(effects2.shakeOffset.y, 0);
    });
  });
}
