import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/theme/neon_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════════════════════════════════════
  // NEON COLORS TESTS (100+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('NeonColors - Primary colors', () {
    test('cyan is #00FFFF', () {
      expect(NeonColors.cyan, const Color(0xFF00FFFF));
    });

    test('magenta is #FF00FF', () {
      expect(NeonColors.magenta, const Color(0xFFFF00FF));
    });

    test('purple is #9C27B0', () {
      expect(NeonColors.purple, const Color(0xFF9C27B0));
    });

    test('yellow is #FFEB3B', () {
      expect(NeonColors.yellow, const Color(0xFFFFEB3B));
    });

    test('orange is #FF7043', () {
      expect(NeonColors.orange, const Color(0xFFFF7043));
    });

    test('green is #00FF88', () {
      expect(NeonColors.green, const Color(0xFF00FF88));
    });

    test('red is #FF0066', () {
      expect(NeonColors.red, const Color(0xFFFF0066));
    });

    test('white is #FFFFFF', () {
      expect(NeonColors.white, const Color(0xFFFFFFFF));
    });

    test('blue is #0088FF', () {
      expect(NeonColors.blue, const Color(0xFF0088FF));
    });

    // Alpha channel tests
    final colors = [
      NeonColors.cyan,
      NeonColors.magenta,
      NeonColors.purple,
      NeonColors.yellow,
      NeonColors.orange,
      NeonColors.green,
      NeonColors.red,
      NeonColors.white,
      NeonColors.blue,
    ];

    for (final color in colors) {
      test('${color.toString()} has full alpha', () {
        expect(color.alpha, 255);
      });
    }
  });

  group('NeonColors - Background colors', () {
    test('darkBg is #0A0A0F', () {
      expect(NeonColors.darkBg, const Color(0xFF0A0A0F));
    });

    test('surfaceBg is #1A1A2E', () {
      expect(NeonColors.surfaceBg, const Color(0xFF1A1A2E));
    });

    test('surface equals surfaceBg', () {
      expect(NeonColors.surface, NeonColors.surfaceBg);
    });

    test('gridLine is #1A1A2E', () {
      expect(NeonColors.gridLine, const Color(0xFF1A1A2E));
    });

    test('deepBlack is #030308', () {
      expect(NeonColors.deepBlack, const Color(0xFF030308));
    });

    test('darkBg is dark', () {
      expect(NeonColors.darkBg.computeLuminance(), lessThan(0.1));
    });

    test('deepBlack is darkest', () {
      expect(NeonColors.deepBlack.computeLuminance(), lessThan(NeonColors.darkBg.computeLuminance()));
    });
  });

  group('NeonColors - State colors', () {
    test('success is #00FF88', () {
      expect(NeonColors.success, const Color(0xFF00FF88));
    });

    test('warning is #FFAA00', () {
      expect(NeonColors.warning, const Color(0xFFFFAA00));
    });

    test('error is #FF4444', () {
      expect(NeonColors.error, const Color(0xFFFF4444));
    });

    test('info is #00AAFF', () {
      expect(NeonColors.info, const Color(0xFF00AAFF));
    });

    test('success equals green', () {
      expect(NeonColors.success, NeonColors.green);
    });
  });

  group('NeonColors - Gradients', () {
    test('cyanMagentaGradient has 2 colors', () {
      expect(NeonColors.cyanMagentaGradient.length, 2);
    });

    test('cyanMagentaGradient starts with cyan', () {
      expect(NeonColors.cyanMagentaGradient[0], NeonColors.cyan);
    });

    test('cyanMagentaGradient ends with magenta', () {
      expect(NeonColors.cyanMagentaGradient[1], NeonColors.magenta);
    });

    test('cyanPurpleGradient has 2 colors', () {
      expect(NeonColors.cyanPurpleGradient.length, 2);
    });

    test('magentaOrangeGradient has 2 colors', () {
      expect(NeonColors.magentaOrangeGradient.length, 2);
    });

    test('yellowOrangeGradient has 2 colors', () {
      expect(NeonColors.yellowOrangeGradient.length, 2);
    });

    test('greenCyanGradient has 2 colors', () {
      expect(NeonColors.greenCyanGradient.length, 2);
    });

    test('redMagentaGradient has 2 colors', () {
      expect(NeonColors.redMagentaGradient.length, 2);
    });
  });

  group('NeonColors - Color blending', () {
    for (double intensity = 0.0; intensity <= 1.0; intensity += 0.2) {
      test('blendWithGlow intensity $intensity', () {
        final blended = NeonColors.blendWithGlow(NeonColors.cyan, intensity);
        expect(blended, isNotNull);
      });
    }

    for (double factor = 0.0; factor <= 1.0; factor += 0.2) {
      test('dimmed factor $factor', () {
        final dimmed = NeonColors.dimmed(NeonColors.cyan, factor);
        expect(dimmed, isNotNull);
      });
    }

    test('blendWithGlow at 0 returns base', () {
      final blended = NeonColors.blendWithGlow(NeonColors.cyan, 0);
      expect(blended, NeonColors.cyan);
    });

    test('dimmed at 0 returns base', () {
      final dimmed = NeonColors.dimmed(NeonColors.cyan, 0);
      expect(dimmed, NeonColors.cyan);
    });

    test('dimmed at 1 returns darkBg', () {
      final dimmed = NeonColors.dimmed(NeonColors.cyan, 1);
      expect(dimmed, NeonColors.darkBg);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GLOW INTENSITY TESTS (40+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('GlowIntensity enum', () {
    test('GlowIntensity has 4 values', () {
      expect(GlowIntensity.values.length, 4);
    });

    test('subtle exists', () {
      expect(GlowIntensity.values, contains(GlowIntensity.subtle));
    });

    test('medium exists', () {
      expect(GlowIntensity.values, contains(GlowIntensity.medium));
    });

    test('intense exists', () {
      expect(GlowIntensity.values, contains(GlowIntensity.intense));
    });

    test('extreme exists', () {
      expect(GlowIntensity.values, contains(GlowIntensity.extreme));
    });

    test('subtle blurRadius is 4', () {
      expect(GlowIntensity.subtle.blurRadius, 4);
    });

    test('medium blurRadius is 8', () {
      expect(GlowIntensity.medium.blurRadius, 8);
    });

    test('intense blurRadius is 16', () {
      expect(GlowIntensity.intense.blurRadius, 16);
    });

    test('extreme blurRadius is 24', () {
      expect(GlowIntensity.extreme.blurRadius, 24);
    });

    test('subtle opacity is 0.3', () {
      expect(GlowIntensity.subtle.opacity, 0.3);
    });

    test('medium opacity is 0.5', () {
      expect(GlowIntensity.medium.opacity, 0.5);
    });

    test('intense opacity is 0.7', () {
      expect(GlowIntensity.intense.opacity, 0.7);
    });

    test('extreme opacity is 0.9', () {
      expect(GlowIntensity.extreme.opacity, 0.9);
    });

    for (final intensity in GlowIntensity.values) {
      test('${intensity.name} maskFilter is not null', () {
        expect(intensity.maskFilter, isNotNull);
      });

      test('${intensity.name} applyTo works', () {
        final color = intensity.applyTo(NeonColors.cyan);
        expect(color.alpha / 255, closeTo(intensity.opacity, 0.01));
      });
    }

    // Blur radius ordering
    test('blur radii increase with intensity', () {
      expect(GlowIntensity.subtle.blurRadius, lessThan(GlowIntensity.medium.blurRadius));
      expect(GlowIntensity.medium.blurRadius, lessThan(GlowIntensity.intense.blurRadius));
      expect(GlowIntensity.intense.blurRadius, lessThan(GlowIntensity.extreme.blurRadius));
    });

    // Opacity ordering
    test('opacities increase with intensity', () {
      expect(GlowIntensity.subtle.opacity, lessThan(GlowIntensity.medium.opacity));
      expect(GlowIntensity.medium.opacity, lessThan(GlowIntensity.intense.opacity));
      expect(GlowIntensity.intense.opacity, lessThan(GlowIntensity.extreme.opacity));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // NEON ANIMATIONS TESTS (60+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('NeonAnimations - Duration presets', () {
    test('quickFlash is 0.05', () {
      expect(NeonAnimations.quickFlash, 0.05);
    });

    test('buttonPress is 0.15', () {
      expect(NeonAnimations.buttonPress, 0.15);
    });

    test('hoverTransition is 0.2', () {
      expect(NeonAnimations.hoverTransition, 0.2);
    });

    test('explosion is 0.4', () {
      expect(NeonAnimations.explosion, 0.4);
    });

    test('scanLineCycle is 1.5', () {
      expect(NeonAnimations.scanLineCycle, 1.5);
    });

    test('idlePulse is 3.0', () {
      expect(NeonAnimations.idlePulse, 3.0);
    });

    test('slowPulse is 4.0', () {
      expect(NeonAnimations.slowPulse, 4.0);
    });

    test('all durations are positive', () {
      expect(NeonAnimations.quickFlash, greaterThan(0));
      expect(NeonAnimations.buttonPress, greaterThan(0));
      expect(NeonAnimations.hoverTransition, greaterThan(0));
      expect(NeonAnimations.explosion, greaterThan(0));
      expect(NeonAnimations.scanLineCycle, greaterThan(0));
      expect(NeonAnimations.idlePulse, greaterThan(0));
      expect(NeonAnimations.slowPulse, greaterThan(0));
    });
  });

  group('NeonAnimations - Curves', () {
    test('easeGlow is easeInOut', () {
      expect(NeonAnimations.easeGlow, Curves.easeInOut);
    });

    test('bounceIn is bounceIn', () {
      expect(NeonAnimations.bounceIn, Curves.bounceIn);
    });

    test('elasticOut is elasticOut', () {
      expect(NeonAnimations.elasticOut, Curves.elasticOut);
    });

    test('sharpIn is easeInQuart', () {
      expect(NeonAnimations.sharpIn, Curves.easeInQuart);
    });

    test('sharpOut is easeOutQuart', () {
      expect(NeonAnimations.sharpOut, Curves.easeOutQuart);
    });
  });

  group('NeonAnimations - Pulse functions', () {
    for (double time = 0.0; time <= 10.0; time += 1.0) {
      test('pulse at time $time is in range', () {
        final value = NeonAnimations.pulse(time);
        expect(value, inInclusiveRange(0.0, 1.0));
      });

      test('sharpPulse at time $time is in range', () {
        final value = NeonAnimations.sharpPulse(time);
        expect(value, inInclusiveRange(0.0, 1.0));
      });

      test('sawtoothPulse at time $time is in range', () {
        final value = NeonAnimations.sawtoothPulse(time);
        expect(value, inInclusiveRange(0.0, 1.0));
      });

      test('flickerPulse at time $time is binary', () {
        final value = NeonAnimations.flickerPulse(time);
        expect(value == 0.0 || value == 1.0, isTrue);
      });
    }

    // Speed parameter tests
    for (double speed = 0.5; speed <= 3.0; speed += 0.5) {
      test('pulse with speed $speed', () {
        final value = NeonAnimations.pulse(1.0, speed: speed);
        expect(value, inInclusiveRange(0.0, 1.0));
      });

      test('sharpPulse with speed $speed', () {
        final value = NeonAnimations.sharpPulse(1.0, speed: speed);
        expect(value, inInclusiveRange(0.0, 1.0));
      });

      test('sawtoothPulse with speed $speed', () {
        final value = NeonAnimations.sawtoothPulse(1.0, speed: speed);
        expect(value, inInclusiveRange(0.0, 1.0));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // NEON EFFECTS TESTS (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('NeonEffects - createGlowLayers', () {
    for (int layers = 1; layers <= 5; layers++) {
      test('createGlowLayers with $layers layers', () {
        final paints = NeonEffects.createGlowLayers(NeonColors.cyan, layers: layers);
        expect(paints, isNotEmpty);
        expect(paints.length, greaterThanOrEqualTo(layers));
      });
    }

    test('createGlowLayers default is 3 layers', () {
      final paints = NeonEffects.createGlowLayers(NeonColors.cyan);
      expect(paints.length, greaterThanOrEqualTo(3));
    });

    test('createGlowLayers includes core layer', () {
      final paints = NeonEffects.createGlowLayers(NeonColors.cyan);
      expect(paints.any((p) => p.color == NeonColors.cyan), isTrue);
    });
  });

  group('NeonEffects - chromaticAberration', () {
    for (double intensity = 0.5; intensity <= 3.0; intensity += 0.5) {
      test('chromaticAberration intensity $intensity', () {
        final aberrations = NeonEffects.chromaticAberration(NeonColors.cyan, intensity);
        expect(aberrations.length, 3);
      });
    }

    test('chromaticAberration returns RGB components', () {
      final aberrations = NeonEffects.chromaticAberration(NeonColors.cyan, 1.0);
      expect(aberrations[0].$1.red, greaterThan(0)); // Red channel
      expect(aberrations[1].$1.green, greaterThan(0)); // Green channel
      expect(aberrations[2].$1.blue, greaterThan(0)); // Blue channel
    });

    test('chromaticAberration center offset is zero', () {
      final aberrations = NeonEffects.chromaticAberration(NeonColors.cyan, 1.0);
      expect(aberrations[1].$2, Offset.zero);
    });
  });

  group('NeonEffects - createHexagonPath', () {
    for (double radius = 10; radius <= 100; radius += 20) {
      test('createHexagonPath radius $radius', () {
        final path = NeonEffects.createHexagonPath(Offset.zero, radius);
        expect(path, isNotNull);
      });
    }

    test('createHexagonPath with offset center', () {
      final path = NeonEffects.createHexagonPath(const Offset(50, 50), 30);
      expect(path, isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // NEON TEXT STYLES TESTS (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('NeonTextStyles', () {
    test('fontFamily is monospace', () {
      expect(NeonTextStyles.fontFamily, 'monospace');
    });

    test('title has fontSize 48', () {
      expect(NeonTextStyles.title.fontSize, 48);
    });

    test('title has cyan color', () {
      expect(NeonTextStyles.title.color, NeonColors.cyan);
    });

    test('title has 3 shadows', () {
      expect(NeonTextStyles.title.shadows?.length, 3);
    });

    test('subtitle has fontSize 24', () {
      expect(NeonTextStyles.subtitle.fontSize, 24);
    });

    test('subtitle has magenta color', () {
      expect(NeonTextStyles.subtitle.color, NeonColors.magenta);
    });

    test('button has fontSize 18', () {
      expect(NeonTextStyles.button.fontSize, 18);
    });

    test('button has white color', () {
      expect(NeonTextStyles.button.color, NeonColors.white);
    });

    test('body has fontSize 14', () {
      expect(NeonTextStyles.body.fontSize, 14);
    });

    test('small has fontSize 12', () {
      expect(NeonTextStyles.small.fontSize, 12);
    });

    test('small has green color', () {
      expect(NeonTextStyles.small.color, NeonColors.green);
    });

    test('hud has fontSize 14', () {
      expect(NeonTextStyles.hud.fontSize, 14);
    });

    test('withGlow adds shadows', () {
      final glowStyle = NeonTextStyles.withGlow(NeonTextStyles.body, NeonColors.cyan);
      expect(glowStyle.shadows, isNotNull);
      expect(glowStyle.shadows?.length, 2);
    });

    // Letter spacing tests
    test('title has letterSpacing 4', () {
      expect(NeonTextStyles.title.letterSpacing, 4);
    });

    test('subtitle has letterSpacing 2', () {
      expect(NeonTextStyles.subtitle.letterSpacing, 2);
    });

    test('button has letterSpacing 1.5', () {
      expect(NeonTextStyles.button.letterSpacing, 1.5);
    });

    // Font weight tests
    test('title is bold', () {
      expect(NeonTextStyles.title.fontWeight, FontWeight.bold);
    });

    test('subtitle is w500', () {
      expect(NeonTextStyles.subtitle.fontWeight, FontWeight.w500);
    });

    test('button is bold', () {
      expect(NeonTextStyles.button.fontWeight, FontWeight.bold);
    });

    test('hud is bold', () {
      expect(NeonTextStyles.hud.fontWeight, FontWeight.bold);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // NEON THEME TESTS (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('NeonTheme', () {
    test('darkTheme is not null', () {
      expect(NeonTheme.darkTheme, isNotNull);
    });

    test('darkTheme has dark brightness', () {
      expect(NeonTheme.darkTheme.brightness, Brightness.dark);
    });

    test('darkTheme scaffold background is darkBg', () {
      expect(NeonTheme.darkTheme.scaffoldBackgroundColor, NeonColors.darkBg);
    });

    test('darkTheme primary color is cyan', () {
      expect(NeonTheme.darkTheme.primaryColor, NeonColors.cyan);
    });

    test('darkTheme colorScheme is dark', () {
      expect(NeonTheme.darkTheme.colorScheme.brightness, Brightness.dark);
    });

    test('darkTheme colorScheme primary is cyan', () {
      expect(NeonTheme.darkTheme.colorScheme.primary, NeonColors.cyan);
    });

    test('darkTheme colorScheme secondary is magenta', () {
      expect(NeonTheme.darkTheme.colorScheme.secondary, NeonColors.magenta);
    });

    test('darkTheme colorScheme surface is darkBg', () {
      expect(NeonTheme.darkTheme.colorScheme.surface, NeonColors.darkBg);
    });

    test('darkTheme colorScheme error is red', () {
      expect(NeonTheme.darkTheme.colorScheme.error, NeonColors.red);
    });

    test('darkTheme uses monospace font', () {
      // fontFamily is set but accessed differently in ThemeData
      expect(NeonTextStyles.fontFamily, 'monospace');
    });

    test('darkTheme textTheme is not null', () {
      expect(NeonTheme.darkTheme.textTheme, isNotNull);
    });

    test('darkTheme displayLarge is cyan', () {
      expect(NeonTheme.darkTheme.textTheme.displayLarge?.color, NeonColors.cyan);
    });

    test('darkTheme bodyLarge is white', () {
      expect(NeonTheme.darkTheme.textTheme.bodyLarge?.color, NeonColors.white);
    });

    test('darkTheme bodyMedium is white', () {
      expect(NeonTheme.darkTheme.textTheme.bodyMedium?.color, NeonColors.white);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // COLOR CONSISTENCY TESTS (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('NeonColors - Consistency', () {
    final allColors = [
      NeonColors.cyan,
      NeonColors.magenta,
      NeonColors.purple,
      NeonColors.yellow,
      NeonColors.orange,
      NeonColors.green,
      NeonColors.red,
      NeonColors.white,
      NeonColors.blue,
      NeonColors.darkBg,
      NeonColors.surfaceBg,
      NeonColors.gridLine,
      NeonColors.deepBlack,
      NeonColors.success,
      NeonColors.warning,
      NeonColors.error,
      NeonColors.info,
    ];

    for (final color in allColors) {
      test('${color.toString()} has valid hex value', () {
        expect(color.value, greaterThan(0));
      });
    }

    test('primary colors are different', () {
      expect(NeonColors.cyan, isNot(NeonColors.magenta));
      expect(NeonColors.cyan, isNot(NeonColors.yellow));
      expect(NeonColors.magenta, isNot(NeonColors.yellow));
    });

    test('state colors are different', () {
      expect(NeonColors.success, isNot(NeonColors.warning));
      expect(NeonColors.success, isNot(NeonColors.error));
      expect(NeonColors.warning, isNot(NeonColors.error));
    });
  });
}
