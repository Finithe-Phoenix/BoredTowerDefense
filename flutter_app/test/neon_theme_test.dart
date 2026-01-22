import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/theme/neon_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NeonColors', () {
    test('primary colors are defined', () {
      expect(NeonColors.cyan, const Color(0xFF00FFFF));
      expect(NeonColors.magenta, const Color(0xFFFF00FF));
      expect(NeonColors.purple, const Color(0xFF9C27B0));
      expect(NeonColors.yellow, const Color(0xFFFFEB3B));
      expect(NeonColors.orange, const Color(0xFFFF7043));
      expect(NeonColors.green, const Color(0xFF00FF88));
      expect(NeonColors.red, const Color(0xFFFF0066));
      expect(NeonColors.white, const Color(0xFFFFFFFF));
      expect(NeonColors.blue, const Color(0xFF0088FF));
    });

    test('background colors are defined', () {
      expect(NeonColors.darkBg, const Color(0xFF0A0A0F));
      expect(NeonColors.surfaceBg, const Color(0xFF1A1A2E));
      expect(NeonColors.surface, NeonColors.surfaceBg);
      expect(NeonColors.gridLine, const Color(0xFF1A1A2E));
      expect(NeonColors.deepBlack, const Color(0xFF030308));
    });

    test('state colors are defined', () {
      expect(NeonColors.success, const Color(0xFF00FF88));
      expect(NeonColors.warning, const Color(0xFFFFAA00));
      expect(NeonColors.error, const Color(0xFFFF4444));
      expect(NeonColors.info, const Color(0xFF00AAFF));
    });

    test('gradient presets have correct colors', () {
      expect(NeonColors.cyanMagentaGradient, [NeonColors.cyan, NeonColors.magenta]);
      expect(NeonColors.cyanPurpleGradient, [NeonColors.cyan, NeonColors.purple]);
      expect(NeonColors.magentaOrangeGradient, [NeonColors.magenta, NeonColors.orange]);
      expect(NeonColors.yellowOrangeGradient, [NeonColors.yellow, NeonColors.orange]);
      expect(NeonColors.greenCyanGradient, [NeonColors.green, NeonColors.cyan]);
      expect(NeonColors.redMagentaGradient, [NeonColors.red, NeonColors.magenta]);
    });

    test('blend and dim helpers match lerp behavior', () {
      final blended = NeonColors.blendWithGlow(NeonColors.cyan, 1.0);
      expect(
        blended,
        Color.lerp(NeonColors.cyan, NeonColors.white, 0.3),
      );

      final dimmed = NeonColors.dimmed(NeonColors.magenta, 0.5);
      expect(
        dimmed,
        Color.lerp(NeonColors.magenta, NeonColors.darkBg, 0.5),
      );
    });

    test('blendWithGlow with zero intensity returns original color', () {
      final blended = NeonColors.blendWithGlow(NeonColors.cyan, 0.0);
      expect(blended, NeonColors.cyan);
    });

    test('dimmed with zero factor returns original color', () {
      final dimmed = NeonColors.dimmed(NeonColors.cyan, 0.0);
      expect(dimmed, NeonColors.cyan);
    });
  });

  group('GlowIntensity', () {
    test('exposes blur and opacity values', () {
      expect(GlowIntensity.medium.blurRadius, 8);
      expect(GlowIntensity.medium.opacity, 0.5);
      final tinted = GlowIntensity.medium.applyTo(NeonColors.cyan);
      expect(tinted.alpha, 128);
    });

    test('all enum values have correct properties', () {
      expect(GlowIntensity.subtle.blurRadius, 4);
      expect(GlowIntensity.subtle.opacity, 0.3);

      expect(GlowIntensity.intense.blurRadius, 16);
      expect(GlowIntensity.intense.opacity, 0.7);

      expect(GlowIntensity.extreme.blurRadius, 24);
      expect(GlowIntensity.extreme.opacity, 0.9);
    });

    test('maskFilter returns blur mask', () {
      for (final intensity in GlowIntensity.values) {
        final filter = intensity.maskFilter;
        expect(filter, isA<ui.MaskFilter>());
      }
    });

    test('applyTo modifies color opacity', () {
      const color = Colors.white;
      for (final intensity in GlowIntensity.values) {
        final applied = intensity.applyTo(color);
        expect(applied.opacity, closeTo(intensity.opacity, 0.01));
      }
    });
  });

  group('NeonAnimations', () {
    test('duration constants are defined', () {
      expect(NeonAnimations.quickFlash, 0.05);
      expect(NeonAnimations.buttonPress, 0.15);
      expect(NeonAnimations.hoverTransition, 0.2);
      expect(NeonAnimations.explosion, 0.4);
      expect(NeonAnimations.scanLineCycle, 1.5);
      expect(NeonAnimations.idlePulse, 3.0);
      expect(NeonAnimations.slowPulse, 4.0);
    });

    test('animation curves are defined', () {
      expect(NeonAnimations.easeGlow, Curves.easeInOut);
      expect(NeonAnimations.bounceIn, Curves.bounceIn);
      expect(NeonAnimations.elasticOut, Curves.elasticOut);
      expect(NeonAnimations.sharpIn, Curves.easeInQuart);
      expect(NeonAnimations.sharpOut, Curves.easeOutQuart);
    });

    test('pulses remain in range', () {
      final pulse = NeonAnimations.pulse(1.0, speed: 2.0);
      expect(pulse, inInclusiveRange(0.0, 1.0));

      final sharp = NeonAnimations.sharpPulse(1.0, speed: 1.0);
      expect(sharp, inInclusiveRange(0.0, 1.0));

      final saw = NeonAnimations.sawtoothPulse(1.25, speed: 2.0);
      expect(saw, closeTo(0.5, 0.0001));

      final flicker = NeonAnimations.flickerPulse(0.1);
      expect(flicker, anyOf(0.0, 1.0));
    });

    test('pulse returns value between 0 and 1 for various times', () {
      for (double time = 0; time < 10; time += 0.5) {
        final value = NeonAnimations.pulse(time);
        expect(value, inInclusiveRange(0.0, 1.0));
      }
    });

    test('sharpPulse returns value between 0 and 1 for various times', () {
      for (double time = 0; time < 10; time += 0.5) {
        final value = NeonAnimations.sharpPulse(time);
        expect(value, inInclusiveRange(0.0, 1.0));
      }
    });

    test('sawtoothPulse returns value between 0 and 1 for various times', () {
      for (double time = 0; time < 10; time += 0.5) {
        final value = NeonAnimations.sawtoothPulse(time);
        expect(value, inInclusiveRange(0.0, 1.0));
      }
    });

    test('flickerPulse returns 0 or 1 for various times', () {
      for (double time = 0; time < 10; time += 0.1) {
        final value = NeonAnimations.flickerPulse(time);
        expect(value == 0.0 || value == 1.0, isTrue);
      }
    });
  });

  group('NeonEffects', () {
    test('utilities draw without exceptions', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(120, 80);

      NeonEffects.drawScanLines(canvas, size, 0.5);
      NeonEffects.drawGlowingCircle(
        canvas,
        const Offset(20, 20),
        10,
        NeonColors.cyan,
      );
      NeonEffects.drawGlowingLine(
        canvas,
        const Offset(0, 0),
        const Offset(50, 10),
        NeonColors.magenta,
      );
      NeonEffects.drawCornerBracket(
        canvas,
        const Offset(10, 10),
        12,
        NeonColors.green,
        topLeft: true,
      );

      final path = NeonEffects.createHexagonPath(const Offset(30, 30), 12);
      expect(path.getBounds().isEmpty, isFalse);

      recorder.endRecording();
    });

    test('builders return expected shapes', () {
      final paints = NeonEffects.createGlowLayers(NeonColors.cyan, layers: 3);
      expect(paints.length, 5);

      final offsets = NeonEffects.chromaticAberration(NeonColors.white, 2.0);
      expect(offsets.length, 3);
      expect(offsets.first.$2.dx, -2.0);
      expect(offsets.last.$2.dx, 2.0);
    });

    test('createGlowLayers with custom layer count', () {
      final layers = NeonEffects.createGlowLayers(NeonColors.cyan, layers: 5);
      // 5 glow layers + 1 core + 1 bright center = 7
      expect(layers.length, 7);
    });

    test('drawScanLines with custom parameters', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => NeonEffects.drawScanLines(
          canvas,
          const Size(100, 100),
          0.5,
          color: NeonColors.magenta,
          spacing: 5.0,
          opacity: 0.1,
        ),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('drawGlowingCircle with all glow intensities', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      for (final glow in GlowIntensity.values) {
        expect(
          () => NeonEffects.drawGlowingCircle(
            canvas,
            const Offset(50, 50),
            20,
            NeonColors.cyan,
            glow: glow,
          ),
          returnsNormally,
        );
      }

      recorder.endRecording();
    });

    test('drawGlowingLine with custom width and glow', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => NeonEffects.drawGlowingLine(
          canvas,
          const Offset(0, 0),
          const Offset(100, 100),
          NeonColors.magenta,
          width: 5.0,
          glow: GlowIntensity.extreme,
        ),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('drawCornerBracket with all corners', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => NeonEffects.drawCornerBracket(
          canvas,
          const Offset(10, 10),
          20,
          NeonColors.cyan,
          topLeft: true,
          topRight: true,
          bottomLeft: true,
          bottomRight: true,
          strokeWidth: 3.0,
        ),
        returnsNormally,
      );

      recorder.endRecording();
    });
  });

  group('NeonTextStyles', () {
    test('fontFamily is monospace', () {
      expect(NeonTextStyles.fontFamily, 'monospace');
    });

    test('title style is defined correctly', () {
      expect(NeonTextStyles.title.fontFamily, 'monospace');
      expect(NeonTextStyles.title.fontSize, 48);
      expect(NeonTextStyles.title.fontWeight, FontWeight.bold);
      expect(NeonTextStyles.title.color, NeonColors.cyan);
      expect(NeonTextStyles.title.letterSpacing, 4);
      expect(NeonTextStyles.title.shadows, isNotEmpty);
    });

    test('subtitle style is defined correctly', () {
      expect(NeonTextStyles.subtitle.fontFamily, 'monospace');
      expect(NeonTextStyles.subtitle.fontSize, 24);
      expect(NeonTextStyles.subtitle.fontWeight, FontWeight.w500);
      expect(NeonTextStyles.subtitle.color, NeonColors.magenta);
    });

    test('button style is defined correctly', () {
      expect(NeonTextStyles.button.fontFamily, 'monospace');
      expect(NeonTextStyles.button.fontSize, 18);
      expect(NeonTextStyles.button.fontWeight, FontWeight.bold);
      expect(NeonTextStyles.button.color, NeonColors.white);
    });

    test('body style is defined correctly', () {
      expect(NeonTextStyles.body.fontFamily, 'monospace');
      expect(NeonTextStyles.body.fontSize, 14);
      expect(NeonTextStyles.body.color, NeonColors.white);
    });

    test('small style is defined correctly', () {
      expect(NeonTextStyles.small.fontFamily, 'monospace');
      expect(NeonTextStyles.small.fontSize, 12);
      expect(NeonTextStyles.small.color, NeonColors.green);
    });

    test('hud style is defined correctly', () {
      expect(NeonTextStyles.hud.fontFamily, 'monospace');
      expect(NeonTextStyles.hud.fontSize, 14);
      expect(NeonTextStyles.hud.fontWeight, FontWeight.bold);
      expect(NeonTextStyles.hud.color, NeonColors.white);
    });

    test('withGlow adds shadows to style', () {
      final withGlow = NeonTextStyles.withGlow(NeonTextStyles.body, NeonColors.cyan);
      expect(withGlow.shadows, isNotNull);
      expect(withGlow.shadows!.length, 2);
    });
  });

  group('NeonTheme', () {
    test('dark theme uses neon palette', () {
      final theme = NeonTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.primaryColor, NeonColors.cyan);
      expect(theme.textTheme.bodyLarge?.color, NeonColors.white);
    });

    test('darkTheme has correct color scheme', () {
      final theme = NeonTheme.darkTheme;
      final colorScheme = theme.colorScheme;

      expect(colorScheme.brightness, Brightness.dark);
      expect(colorScheme.primary, NeonColors.cyan);
      expect(colorScheme.secondary, NeonColors.magenta);
      expect(colorScheme.surface, NeonColors.darkBg);
      expect(colorScheme.error, NeonColors.red);
    });

    test('darkTheme uses monospace font family', () {
      final theme = NeonTheme.darkTheme;
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        NeonTextStyles.fontFamily,
      );
    });

    test('darkTheme scaffoldBackgroundColor is darkBg', () {
      final theme = NeonTheme.darkTheme;
      expect(theme.scaffoldBackgroundColor, NeonColors.darkBg);
    });
  });
}
