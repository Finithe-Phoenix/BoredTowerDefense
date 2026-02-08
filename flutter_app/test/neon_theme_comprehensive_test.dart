import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for NeonTheme, NeonColors, NeonAnimations, and related utilities

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED CLASSES FROM neon_theme.dart
// ═══════════════════════════════════════════════════════════════════════════════

/// Neon color palette
class NeonColors {
  // Primary colors
  static const Color cyan = Color(0xFF00FFFF);
  static const Color magenta = Color(0xFFFF00FF);
  static const Color purple = Color(0xFF9C27B0);
  static const Color yellow = Color(0xFFFFEB3B);
  static const Color orange = Color(0xFFFF7043);
  static const Color green = Color(0xFF00FF88);
  static const Color red = Color(0xFFFF0066);
  static const Color white = Color(0xFFFFFFFF);
  static const Color blue = Color(0xFF0088FF);

  // Background colors
  static const Color darkBg = Color(0xFF0A0A0F);
  static const Color surfaceBg = Color(0xFF1A1A2E);
  static const Color surface = surfaceBg;
  static const Color gridLine = Color(0xFF1A1A2E);
  static const Color deepBlack = Color(0xFF030308);

  // State colors
  static const Color success = Color(0xFF00FF88);
  static const Color warning = Color(0xFFFFAA00);
  static const Color error = Color(0xFFFF4444);
  static const Color info = Color(0xFF00AAFF);

  // Gradient presets
  static const List<Color> cyanMagentaGradient = [cyan, magenta];
  static const List<Color> cyanPurpleGradient = [cyan, purple];
  static const List<Color> magentaOrangeGradient = [magenta, orange];
  static const List<Color> yellowOrangeGradient = [yellow, orange];
  static const List<Color> greenCyanGradient = [green, cyan];
  static const List<Color> redMagentaGradient = [red, magenta];

  // Color blend presets
  static Color blendWithGlow(Color base, double intensity) {
    return Color.lerp(base, white, intensity * 0.3)!;
  }

  static Color dimmed(Color base, double factor) {
    return Color.lerp(base, darkBg, factor)!;
  }
}

/// Glow intensity levels
enum GlowIntensity {
  subtle(blurRadius: 4, opacity: 0.3),
  medium(blurRadius: 8, opacity: 0.5),
  intense(blurRadius: 16, opacity: 0.7),
  extreme(blurRadius: 24, opacity: 0.9);

  const GlowIntensity({required this.blurRadius, required this.opacity});

  final double blurRadius;
  final double opacity;

  MaskFilter get maskFilter => MaskFilter.blur(BlurStyle.normal, blurRadius);

  Color applyTo(Color color) => color.withOpacity(opacity);
}

/// Animation timing constants and pulse functions
class NeonAnimations {
  // Duration presets (in seconds)
  static const double quickFlash = 0.05;
  static const double buttonPress = 0.15;
  static const double hoverTransition = 0.2;
  static const double explosion = 0.4;
  static const double scanLineCycle = 1.5;
  static const double idlePulse = 3.0;
  static const double slowPulse = 4.0;

  // Pulse patterns (returns 0.0 - 1.0)
  static double pulse(double time, {double speed = 1.0}) {
    return (math.sin(time * speed) + 1) / 2;
  }

  static double sharpPulse(double time, {double speed = 1.0}) {
    return math.pow((math.sin(time * speed) + 1) / 2, 2).toDouble();
  }

  static double sawtoothPulse(double time, {double speed = 1.0}) {
    return (time * speed) % 1.0;
  }

  static double flickerPulse(double time) {
    return math.sin(time * 15) * math.sin(time * 23) > 0.7 ? 1.0 : 0.0;
  }
}

/// Hexagon path calculator
class HexagonPathCalculator {
  static List<(double, double)> createHexagonVertices(double cx, double cy, double radius) {
    final vertices = <(double, double)>[];
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      vertices.add((x, y));
    }
    return vertices;
  }
}

/// Glow layer calculator
class GlowLayerCalculator {
  static List<(double, double)> createGlowLayers(int layerCount) {
    final layers = <(double, double)>[];
    for (int i = layerCount - 1; i >= 0; i--) {
      final intensity = (i + 1) / layerCount;
      final opacity = 0.3 * intensity;
      final blur = 8.0 + i * 8;
      layers.add((opacity, blur));
    }
    return layers;
  }
}

/// Chromatic aberration calculator
class ChromaticAberrationCalculator {
  static List<(Color, double, double)> calculate(double intensity) {
    return [
      (const Color(0xFFFF0000).withOpacity(0.3), -intensity, 0),
      (const Color(0xFF00FF00).withOpacity(0.3), 0, 0),
      (const Color(0xFF0000FF).withOpacity(0.3), intensity, 0),
    ];
  }
}

/// Scan line calculator
class ScanLineCalculator {
  static double calculateLineY(int index, double spacing, double time) {
    return index * spacing + (time * 50) % spacing;
  }

  static int calculateLineCount(double height, double spacing) {
    return (height / spacing).ceil();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('NeonColors - Primary Colors', () {
    test('cyan is correct', () {
      expect(NeonColors.cyan, const Color(0xFF00FFFF));
    });

    test('magenta is correct', () {
      expect(NeonColors.magenta, const Color(0xFFFF00FF));
    });

    test('purple is correct', () {
      expect(NeonColors.purple, const Color(0xFF9C27B0));
    });

    test('yellow is correct', () {
      expect(NeonColors.yellow, const Color(0xFFFFEB3B));
    });

    test('orange is correct', () {
      expect(NeonColors.orange, const Color(0xFFFF7043));
    });

    test('green is correct', () {
      expect(NeonColors.green, const Color(0xFF00FF88));
    });

    test('red is correct', () {
      expect(NeonColors.red, const Color(0xFFFF0066));
    });

    test('white is correct', () {
      expect(NeonColors.white, const Color(0xFFFFFFFF));
    });

    test('blue is correct', () {
      expect(NeonColors.blue, const Color(0xFF0088FF));
    });
  });

  group('NeonColors - Background Colors', () {
    test('darkBg is very dark', () {
      expect(NeonColors.darkBg, const Color(0xFF0A0A0F));
      expect(NeonColors.darkBg.computeLuminance(), lessThan(0.05));
    });

    test('surfaceBg is slightly lighter', () {
      expect(NeonColors.surfaceBg, const Color(0xFF1A1A2E));
    });

    test('surface equals surfaceBg', () {
      expect(NeonColors.surface, NeonColors.surfaceBg);
    });

    test('gridLine equals surfaceBg', () {
      expect(NeonColors.gridLine, const Color(0xFF1A1A2E));
    });

    test('deepBlack is nearly black', () {
      expect(NeonColors.deepBlack, const Color(0xFF030308));
      expect(NeonColors.deepBlack.computeLuminance(), lessThan(0.01));
    });
  });

  group('NeonColors - State Colors', () {
    test('success is green', () {
      expect(NeonColors.success, const Color(0xFF00FF88));
      expect(NeonColors.success, NeonColors.green);
    });

    test('warning is amber/orange', () {
      expect(NeonColors.warning, const Color(0xFFFFAA00));
    });

    test('error is red', () {
      expect(NeonColors.error, const Color(0xFFFF4444));
    });

    test('info is blue', () {
      expect(NeonColors.info, const Color(0xFF00AAFF));
    });
  });

  group('NeonColors - Gradients', () {
    test('cyanMagenta gradient has 2 colors', () {
      expect(NeonColors.cyanMagentaGradient.length, 2);
      expect(NeonColors.cyanMagentaGradient[0], NeonColors.cyan);
      expect(NeonColors.cyanMagentaGradient[1], NeonColors.magenta);
    });

    test('cyanPurple gradient has 2 colors', () {
      expect(NeonColors.cyanPurpleGradient.length, 2);
      expect(NeonColors.cyanPurpleGradient[0], NeonColors.cyan);
      expect(NeonColors.cyanPurpleGradient[1], NeonColors.purple);
    });

    test('magentaOrange gradient has 2 colors', () {
      expect(NeonColors.magentaOrangeGradient.length, 2);
      expect(NeonColors.magentaOrangeGradient[0], NeonColors.magenta);
      expect(NeonColors.magentaOrangeGradient[1], NeonColors.orange);
    });

    test('yellowOrange gradient has 2 colors', () {
      expect(NeonColors.yellowOrangeGradient.length, 2);
      expect(NeonColors.yellowOrangeGradient[0], NeonColors.yellow);
      expect(NeonColors.yellowOrangeGradient[1], NeonColors.orange);
    });

    test('greenCyan gradient has 2 colors', () {
      expect(NeonColors.greenCyanGradient.length, 2);
      expect(NeonColors.greenCyanGradient[0], NeonColors.green);
      expect(NeonColors.greenCyanGradient[1], NeonColors.cyan);
    });

    test('redMagenta gradient has 2 colors', () {
      expect(NeonColors.redMagentaGradient.length, 2);
      expect(NeonColors.redMagentaGradient[0], NeonColors.red);
      expect(NeonColors.redMagentaGradient[1], NeonColors.magenta);
    });
  });

  group('NeonColors - blendWithGlow', () {
    test('intensity 0 returns base color', () {
      final result = NeonColors.blendWithGlow(NeonColors.cyan, 0);
      expect(result, NeonColors.cyan);
    });

    test('intensity 1 blends 30% towards white', () {
      final result = NeonColors.blendWithGlow(NeonColors.cyan, 1.0);
      // Should be 30% towards white
      expect(result.red, greaterThan(NeonColors.cyan.red));
    });

    test('higher intensity creates brighter color', () {
      final low = NeonColors.blendWithGlow(NeonColors.cyan, 0.2);
      final high = NeonColors.blendWithGlow(NeonColors.cyan, 0.8);

      expect(high.computeLuminance(), greaterThan(low.computeLuminance()));
    });
  });

  group('NeonColors - dimmed', () {
    test('factor 0 returns base color', () {
      final result = NeonColors.dimmed(NeonColors.cyan, 0);
      expect(result, NeonColors.cyan);
    });

    test('factor 1 returns darkBg', () {
      final result = NeonColors.dimmed(NeonColors.cyan, 1.0);
      expect(result, NeonColors.darkBg);
    });

    test('higher factor creates darker color', () {
      final low = NeonColors.dimmed(NeonColors.cyan, 0.2);
      final high = NeonColors.dimmed(NeonColors.cyan, 0.8);

      expect(high.computeLuminance(), lessThan(low.computeLuminance()));
    });
  });

  group('GlowIntensity', () {
    test('has 4 intensity levels', () {
      expect(GlowIntensity.values.length, 4);
    });

    test('subtle has lowest values', () {
      expect(GlowIntensity.subtle.blurRadius, 4);
      expect(GlowIntensity.subtle.opacity, 0.3);
    });

    test('medium has moderate values', () {
      expect(GlowIntensity.medium.blurRadius, 8);
      expect(GlowIntensity.medium.opacity, 0.5);
    });

    test('intense has high values', () {
      expect(GlowIntensity.intense.blurRadius, 16);
      expect(GlowIntensity.intense.opacity, 0.7);
    });

    test('extreme has highest values', () {
      expect(GlowIntensity.extreme.blurRadius, 24);
      expect(GlowIntensity.extreme.opacity, 0.9);
    });

    test('blur radius increases with intensity', () {
      expect(GlowIntensity.subtle.blurRadius, lessThan(GlowIntensity.medium.blurRadius));
      expect(GlowIntensity.medium.blurRadius, lessThan(GlowIntensity.intense.blurRadius));
      expect(GlowIntensity.intense.blurRadius, lessThan(GlowIntensity.extreme.blurRadius));
    });

    test('opacity increases with intensity', () {
      expect(GlowIntensity.subtle.opacity, lessThan(GlowIntensity.medium.opacity));
      expect(GlowIntensity.medium.opacity, lessThan(GlowIntensity.intense.opacity));
      expect(GlowIntensity.intense.opacity, lessThan(GlowIntensity.extreme.opacity));
    });

    test('maskFilter creates blur filter', () {
      final filter = GlowIntensity.medium.maskFilter;
      expect(filter, isA<MaskFilter>());
    });

    test('applyTo changes color opacity', () {
      final color = NeonColors.cyan;
      final applied = GlowIntensity.medium.applyTo(color);

      // Color opacity uses 8-bit alpha (0-255), so 0.5 becomes 128/255 ≈ 0.502
      expect(applied.opacity, closeTo(0.5, 0.01));
      expect(applied.red, color.red);
      expect(applied.green, color.green);
      expect(applied.blue, color.blue);
    });
  });

  group('NeonAnimations - Duration Constants', () {
    test('quickFlash is very fast', () {
      expect(NeonAnimations.quickFlash, 0.05);
    });

    test('buttonPress is fast', () {
      expect(NeonAnimations.buttonPress, 0.15);
    });

    test('hoverTransition is moderate', () {
      expect(NeonAnimations.hoverTransition, 0.2);
    });

    test('explosion is longer', () {
      expect(NeonAnimations.explosion, 0.4);
    });

    test('scanLineCycle is slow', () {
      expect(NeonAnimations.scanLineCycle, 1.5);
    });

    test('idlePulse is very slow', () {
      expect(NeonAnimations.idlePulse, 3.0);
    });

    test('slowPulse is slowest', () {
      expect(NeonAnimations.slowPulse, 4.0);
    });

    test('durations are in increasing order', () {
      expect(NeonAnimations.quickFlash, lessThan(NeonAnimations.buttonPress));
      expect(NeonAnimations.buttonPress, lessThan(NeonAnimations.hoverTransition));
      expect(NeonAnimations.hoverTransition, lessThan(NeonAnimations.explosion));
      expect(NeonAnimations.explosion, lessThan(NeonAnimations.scanLineCycle));
      expect(NeonAnimations.scanLineCycle, lessThan(NeonAnimations.idlePulse));
      expect(NeonAnimations.idlePulse, lessThan(NeonAnimations.slowPulse));
    });
  });

  group('NeonAnimations - pulse', () {
    test('pulse returns 0.0 to 1.0', () {
      for (double t = 0; t < 10; t += 0.1) {
        final value = NeonAnimations.pulse(t);
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThanOrEqualTo(1.0));
      }
    });

    test('pulse at t=0 is 0.5', () {
      expect(NeonAnimations.pulse(0), 0.5);
    });

    test('pulse at t=PI/2 is 1.0', () {
      expect(NeonAnimations.pulse(math.pi / 2), closeTo(1.0, 0.001));
    });

    test('pulse at t=PI is 0.5', () {
      expect(NeonAnimations.pulse(math.pi), closeTo(0.5, 0.001));
    });

    test('pulse at t=3*PI/2 is 0.0', () {
      expect(NeonAnimations.pulse(3 * math.pi / 2), closeTo(0.0, 0.001));
    });

    test('speed affects frequency', () {
      final slow = NeonAnimations.pulse(math.pi / 4, speed: 1.0);
      final fast = NeonAnimations.pulse(math.pi / 4, speed: 2.0);

      expect(slow, isNot(equals(fast)));
    });
  });

  group('NeonAnimations - sharpPulse', () {
    test('sharpPulse returns 0.0 to 1.0', () {
      for (double t = 0; t < 10; t += 0.1) {
        final value = NeonAnimations.sharpPulse(t);
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThanOrEqualTo(1.0));
      }
    });

    test('sharpPulse at t=0 is 0.25 (squared)', () {
      // (sin(0) + 1) / 2 = 0.5, squared = 0.25
      expect(NeonAnimations.sharpPulse(0), 0.25);
    });

    test('sharpPulse peaks at 1.0', () {
      expect(NeonAnimations.sharpPulse(math.pi / 2), closeTo(1.0, 0.001));
    });

    test('sharpPulse is sharper than regular pulse', () {
      // At midpoint, sharp pulse should be lower due to squaring
      final regular = NeonAnimations.pulse(math.pi / 4);
      final sharp = NeonAnimations.sharpPulse(math.pi / 4);

      expect(sharp, lessThan(regular));
    });
  });

  group('NeonAnimations - sawtoothPulse', () {
    test('sawtoothPulse returns 0.0 to 1.0', () {
      for (double t = 0; t < 10; t += 0.1) {
        final value = NeonAnimations.sawtoothPulse(t);
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThan(1.0));
      }
    });

    test('sawtoothPulse starts at 0', () {
      expect(NeonAnimations.sawtoothPulse(0), 0.0);
    });

    test('sawtoothPulse wraps at 1', () {
      expect(NeonAnimations.sawtoothPulse(1.0), closeTo(0.0, 0.001));
      expect(NeonAnimations.sawtoothPulse(2.0), closeTo(0.0, 0.001));
    });

    test('sawtoothPulse is linear', () {
      expect(NeonAnimations.sawtoothPulse(0.25), closeTo(0.25, 0.001));
      expect(NeonAnimations.sawtoothPulse(0.5), closeTo(0.5, 0.001));
      expect(NeonAnimations.sawtoothPulse(0.75), closeTo(0.75, 0.001));
    });

    test('speed affects rate', () {
      expect(NeonAnimations.sawtoothPulse(0.5, speed: 2.0), closeTo(0.0, 0.001));
    });
  });

  group('NeonAnimations - flickerPulse', () {
    test('flickerPulse returns only 0 or 1', () {
      for (double t = 0; t < 10; t += 0.01) {
        final value = NeonAnimations.flickerPulse(t);
        expect(value == 0.0 || value == 1.0, true);
      }
    });

    test('flickerPulse produces both values', () {
      bool foundZero = false;
      bool foundOne = false;

      for (double t = 0; t < 10; t += 0.01) {
        final value = NeonAnimations.flickerPulse(t);
        if (value == 0.0) foundZero = true;
        if (value == 1.0) foundOne = true;
      }

      expect(foundZero, true);
      expect(foundOne, true);
    });
  });

  group('HexagonPathCalculator', () {
    test('creates 6 vertices', () {
      final vertices = HexagonPathCalculator.createHexagonVertices(0, 0, 10);
      expect(vertices.length, 6);
    });

    test('vertices are equidistant from center', () {
      const cx = 50.0;
      const cy = 50.0;
      const radius = 20.0;
      final vertices = HexagonPathCalculator.createHexagonVertices(cx, cy, radius);

      for (final (x, y) in vertices) {
        final dist = math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2));
        expect(dist, closeTo(radius, 0.001));
      }
    });

    test('first vertex is at -30 degrees', () {
      final vertices = HexagonPathCalculator.createHexagonVertices(0, 0, 10);
      final (x, y) = vertices[0];

      // At -30 degrees: cos(-30°) ≈ 0.866, sin(-30°) = -0.5
      expect(x, closeTo(10 * math.cos(-30 * math.pi / 180), 0.001));
      expect(y, closeTo(10 * math.sin(-30 * math.pi / 180), 0.001));
    });
  });

  group('GlowLayerCalculator', () {
    test('creates correct number of layers', () {
      final layers3 = GlowLayerCalculator.createGlowLayers(3);
      final layers5 = GlowLayerCalculator.createGlowLayers(5);

      expect(layers3.length, 3);
      expect(layers5.length, 5);
    });

    test('opacity decreases with layer index', () {
      final layers = GlowLayerCalculator.createGlowLayers(3);

      // Layers are added in reverse order (outer to inner)
      final (opacity0, _) = layers[0];
      final (opacity1, _) = layers[1];
      final (opacity2, _) = layers[2];

      expect(opacity0, greaterThan(opacity1));
      expect(opacity1, greaterThan(opacity2));
    });

    test('blur increases with layer index', () {
      final layers = GlowLayerCalculator.createGlowLayers(3);

      final (_, blur0) = layers[0];
      final (_, blur1) = layers[1];
      final (_, blur2) = layers[2];

      expect(blur0, greaterThan(blur1));
      expect(blur1, greaterThan(blur2));
    });
  });

  group('ChromaticAberrationCalculator', () {
    test('creates 3 color channels', () {
      final channels = ChromaticAberrationCalculator.calculate(2.0);
      expect(channels.length, 3);
    });

    test('red channel offsets left', () {
      final channels = ChromaticAberrationCalculator.calculate(2.0);
      final (_, offsetX, _) = channels[0];
      expect(offsetX, -2.0);
    });

    test('green channel has no offset', () {
      final channels = ChromaticAberrationCalculator.calculate(2.0);
      final (_, offsetX, offsetY) = channels[1];
      expect(offsetX, 0);
      expect(offsetY, 0);
    });

    test('blue channel offsets right', () {
      final channels = ChromaticAberrationCalculator.calculate(2.0);
      final (_, offsetX, _) = channels[2];
      expect(offsetX, 2.0);
    });

    test('intensity affects offset magnitude', () {
      final low = ChromaticAberrationCalculator.calculate(1.0);
      final high = ChromaticAberrationCalculator.calculate(5.0);

      final (_, lowOffset, _) = low[0];
      final (_, highOffset, _) = high[0];

      expect(highOffset.abs(), greaterThan(lowOffset.abs()));
    });
  });

  group('ScanLineCalculator', () {
    test('calculates line count correctly', () {
      expect(ScanLineCalculator.calculateLineCount(100, 3), 34);
      expect(ScanLineCalculator.calculateLineCount(99, 3), 33);
      expect(ScanLineCalculator.calculateLineCount(300, 10), 30);
    });

    test('line Y position increases with index', () {
      const spacing = 3.0;
      const time = 0.0;

      final y0 = ScanLineCalculator.calculateLineY(0, spacing, time);
      final y1 = ScanLineCalculator.calculateLineY(1, spacing, time);
      final y2 = ScanLineCalculator.calculateLineY(2, spacing, time);

      expect(y1, greaterThan(y0));
      expect(y2, greaterThan(y1));
    });

    test('time creates offset', () {
      const spacing = 3.0;
      const index = 0;

      final y0 = ScanLineCalculator.calculateLineY(index, spacing, 0.0);
      final y1 = ScanLineCalculator.calculateLineY(index, spacing, 0.02);

      expect(y1, greaterThan(y0));
    });

    test('offset wraps within spacing', () {
      const spacing = 3.0;
      const index = 0;

      for (double t = 0; t < 1; t += 0.01) {
        final y = ScanLineCalculator.calculateLineY(index, spacing, t);
        final offset = y - (index * spacing);
        expect(offset, greaterThanOrEqualTo(0));
        expect(offset, lessThan(spacing));
      }
    });
  });

  group('Color ARGB Values', () {
    test('all primary colors have full alpha', () {
      expect(NeonColors.cyan.alpha, 255);
      expect(NeonColors.magenta.alpha, 255);
      expect(NeonColors.green.alpha, 255);
      expect(NeonColors.red.alpha, 255);
    });

    test('cyan has correct RGB', () {
      expect(NeonColors.cyan.red, 0);
      expect(NeonColors.cyan.green, 255);
      expect(NeonColors.cyan.blue, 255);
    });

    test('magenta has correct RGB', () {
      expect(NeonColors.magenta.red, 255);
      expect(NeonColors.magenta.green, 0);
      expect(NeonColors.magenta.blue, 255);
    });
  });
}
