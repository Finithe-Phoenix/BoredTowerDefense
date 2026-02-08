import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/screen_effects.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScreenEffects creation', () {
    test('can create with gameSize', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(effects, isNotNull);
      expect(effects.gameSize.x, 800);
      expect(effects.gameSize.y, 600);
    });

    test('can create with all options enabled', () {
      final effects = ScreenEffects(
        gameSize: Vector2(1920, 1080),
        enableCRT: true,
        enableVignette: true,
        enableScanlines: true,
        enableFlash: true,
      );

      expect(effects.enableCRT, isTrue);
      expect(effects.enableVignette, isTrue);
      expect(effects.enableScanlines, isTrue);
      expect(effects.enableFlash, isTrue);
    });

    test('can create with all options disabled', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
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

    test('defaults CRT to true', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(effects.enableCRT, isTrue);
    });

    test('defaults vignette to true', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(effects.enableVignette, isTrue);
    });

    test('defaults scanlines to true', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(effects.enableScanlines, isTrue);
    });

    test('defaults flash to true', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(effects.enableFlash, isTrue);
    });
  });

  group('ScreenEffects static instance', () {
    test('instance is set on creation', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(ScreenEffects.instance, isNotNull);
      expect(ScreenEffects.instance, effects);
    });

    test('instance is updated when new ScreenEffects created', () {
      final effects1 = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      final effects2 = ScreenEffects(
        gameSize: Vector2(1920, 1080),
      );

      expect(ScreenEffects.instance, effects2);
      expect(ScreenEffects.instance, isNot(effects1));
    });
  });

  group('ScreenEffects configuration', () {
    test('reduceFx can be toggled', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(effects.reduceFx, isFalse);

      effects.reduceFx = true;
      expect(effects.reduceFx, isTrue);

      effects.reduceFx = false;
      expect(effects.reduceFx, isFalse);
    });

    test('allowBlur can be toggled', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(effects.allowBlur, isTrue);

      effects.allowBlur = false;
      expect(effects.allowBlur, isFalse);

      effects.allowBlur = true;
      expect(effects.allowBlur, isTrue);
    });
  });

  group('ScreenEffects gameSize variations', () {
    test('handles standard HD', () {
      final effects = ScreenEffects(
        gameSize: Vector2(1280, 720),
      );

      expect(effects.gameSize.x, 1280);
      expect(effects.gameSize.y, 720);
    });

    test('handles Full HD', () {
      final effects = ScreenEffects(
        gameSize: Vector2(1920, 1080),
      );

      expect(effects.gameSize.x, 1920);
      expect(effects.gameSize.y, 1080);
    });

    test('handles 4K', () {
      final effects = ScreenEffects(
        gameSize: Vector2(3840, 2160),
      );

      expect(effects.gameSize.x, 3840);
      expect(effects.gameSize.y, 2160);
    });

    test('handles mobile portrait', () {
      final effects = ScreenEffects(
        gameSize: Vector2(375, 812),
      );

      expect(effects.gameSize.x, 375);
      expect(effects.gameSize.y, 812);
    });

    test('handles mobile landscape', () {
      final effects = ScreenEffects(
        gameSize: Vector2(812, 375),
      );

      expect(effects.gameSize.x, 812);
      expect(effects.gameSize.y, 375);
    });

    test('handles small game size', () {
      final effects = ScreenEffects(
        gameSize: Vector2(320, 240),
      );

      expect(effects.gameSize.x, 320);
      expect(effects.gameSize.y, 240);
    });
  });

  group('ScreenEffects update behavior', () {
    test('update with zero delta time works', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(() => effects.update(0), returnsNormally);
    });

    test('update with small delta time works', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(() => effects.update(0.016), returnsNormally);
    });

    test('update with large delta time works', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(() => effects.update(1.0), returnsNormally);
    });

    test('multiple updates work', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      for (int i = 0; i < 60; i++) {
        effects.update(0.016);
      }

      expect(true, isTrue);
    });
  });

  group('ScreenEffects flash methods', () {
    test('triggerFlash can be called', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
        enableFlash: true,
      );

      expect(() => effects.triggerFlash(), returnsNormally);
    });

    test('triggerFlash with custom intensity', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
        enableFlash: true,
      );

      expect(() => effects.triggerFlash(intensity: 0.5), returnsNormally);
    });

    test('triggerFlash when flash disabled', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
        enableFlash: false,
      );

      expect(() => effects.triggerFlash(), returnsNormally);
    });
  });

  group('ScreenEffects shake methods', () {
    test('triggerShake can be called', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(() => effects.triggerShake(), returnsNormally);
    });

    test('triggerShake with custom intensity', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(() => effects.triggerShake(intensity: 0.8), returnsNormally);
    });

    test('triggerShake with custom duration', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(() => effects.triggerShake(duration: 0.5), returnsNormally);
    });
  });

  group('ScreenEffects big hit effect', () {
    test('triggerBigHit can be called', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(() => effects.triggerBigHit(50.0), returnsNormally);
    });

    test('triggerBigHit with high damage', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(() => effects.triggerBigHit(100.0), returnsNormally);
    });

    test('triggerBigHit with low damage', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(() => effects.triggerBigHit(10.0), returnsNormally);
    });
  });

  group('ScreenEffects shield flash', () {
    test('triggerShieldFlash can be called', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(() => effects.triggerShieldFlash(), returnsNormally);
    });
  });

  group('ScreenEffects lens flare', () {
    test('triggerLensFlare can be called', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(() => effects.triggerLensFlare(
        position: Vector2(400, 300),
        color: const Color(0xFF00FFFF),
      ), returnsNormally);
    });

    test('triggerLensFlare at different positions', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(() => effects.triggerLensFlare(
        position: Vector2.zero(),
        color: const Color(0xFFFF00FF),
      ), returnsNormally);
      expect(() => effects.triggerLensFlare(
        position: Vector2(800, 600),
        color: const Color(0xFFFFFF00),
      ), returnsNormally);
      expect(() => effects.triggerLensFlare(
        position: Vector2(100, 500),
        color: const Color(0xFF00FF00),
      ), returnsNormally);
    });
  });

  group('ScreenEffects performance', () {
    test('handles rapid effect triggers', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      for (int i = 0; i < 20; i++) {
        effects.triggerFlash();
        effects.triggerShake();
        effects.update(0.016);
      }

      expect(true, isTrue);
    });

    test('handles many updates with effects enabled', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
        enableCRT: true,
        enableVignette: true,
        enableScanlines: true,
        enableFlash: true,
      );

      for (int i = 0; i < 300; i++) {
        effects.update(0.016);
      }

      expect(true, isTrue);
    });

    test('handles many updates with effects disabled', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
        enableCRT: false,
        enableVignette: false,
        enableScanlines: false,
        enableFlash: false,
      );

      for (int i = 0; i < 300; i++) {
        effects.update(0.016);
      }

      expect(true, isTrue);
    });

    test('handles many updates with reduceFx', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );
      effects.reduceFx = true;

      for (int i = 0; i < 300; i++) {
        effects.update(0.016);
      }

      expect(true, isTrue);
    });
  });

  group('ScreenEffects edge cases', () {
    test('handles zero game size', () {
      final effects = ScreenEffects(
        gameSize: Vector2.zero(),
      );

      expect(effects.gameSize.x, 0);
      expect(effects.gameSize.y, 0);
    });

    test('handles negative delta time', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(() => effects.update(-0.016), returnsNormally);
    });

    test('handles very large delta time', () {
      final effects = ScreenEffects(
        gameSize: Vector2(800, 600),
      );

      expect(() => effects.update(100.0), returnsNormally);
    });
  });
}
