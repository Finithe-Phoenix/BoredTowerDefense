import 'dart:math' as math;
import 'package:test/test.dart';

/// Simulation test for Projectile logic without Flutter/Flame dependencies.
/// Tests: circular buffer trail, stress levels, color palette caching,
/// HSL color derivation, FastRng, trail decay, type-specific initialization.

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED RNG - Exact copy from projectile.dart
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedFastRng {
  int _state;

  SimulatedFastRng([int? seed]) : _state = (seed ?? 0x6d2b79f5) & 0x7fffffff;

  int _next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  double nextDouble() => _next() / 0x7fffffff;

  int nextInt(int max) => max <= 0 ? 0 : _next() % max;

  bool nextBool() => (_next() & 1) == 0;

  int get state => _state;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED COLOR - Simple color representation without Flutter
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedColor {
  final int value;

  const SimulatedColor(this.value);

  int get red => (value >> 16) & 0xFF;
  int get green => (value >> 8) & 0xFF;
  int get blue => value & 0xFF;
  int get alpha => (value >> 24) & 0xFF;

  double get opacity => alpha / 255.0;

  SimulatedColor withOpacity(double opacity) {
    final a = (opacity.clamp(0.0, 1.0) * 255).round();
    return SimulatedColor((a << 24) | (value & 0x00FFFFFF));
  }

  @override
  bool operator ==(Object other) =>
      other is SimulatedColor && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Color(0x${value.toRadixString(16).padLeft(8, '0')})';
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED HSL COLOR CONVERSION
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedHSLColor {
  final double hue;
  final double saturation;
  final double lightness;
  final double alpha;

  const SimulatedHSLColor({
    required this.hue,
    required this.saturation,
    required this.lightness,
    this.alpha = 1.0,
  });

  factory SimulatedHSLColor.fromColor(SimulatedColor color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    final maxVal = math.max(r, math.max(g, b));
    final minVal = math.min(r, math.min(g, b));
    final l = (maxVal + minVal) / 2.0;

    double h, s;

    if (maxVal == minVal) {
      h = s = 0.0;
    } else {
      final d = maxVal - minVal;
      s = l > 0.5 ? d / (2.0 - maxVal - minVal) : d / (maxVal + minVal);

      if (maxVal == r) {
        h = ((g - b) / d + (g < b ? 6.0 : 0.0)) / 6.0;
      } else if (maxVal == g) {
        h = ((b - r) / d + 2.0) / 6.0;
      } else {
        h = ((r - g) / d + 4.0) / 6.0;
      }
    }

    return SimulatedHSLColor(
      hue: h * 360.0,
      saturation: s,
      lightness: l,
      alpha: color.opacity,
    );
  }

  SimulatedHSLColor withHue(double hue) {
    return SimulatedHSLColor(
      hue: hue % 360,
      saturation: saturation,
      lightness: lightness,
      alpha: alpha,
    );
  }

  SimulatedHSLColor withLightness(double lightness) {
    return SimulatedHSLColor(
      hue: hue,
      saturation: saturation,
      lightness: lightness.clamp(0.0, 1.0),
      alpha: alpha,
    );
  }

  SimulatedColor toColor() {
    double _hueToRgb(double p, double q, double t) {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    }

    final h = hue / 360.0;
    final s = saturation;
    final l = lightness;

    double r, g, b;

    if (s == 0) {
      r = g = b = l;
    } else {
      final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      final p = 2 * l - q;
      r = _hueToRgb(p, q, h + 1 / 3);
      g = _hueToRgb(p, q, h);
      b = _hueToRgb(p, q, h - 1 / 3);
    }

    return SimulatedColor(
      ((alpha * 255).round() << 24) |
          ((r * 255).round() << 16) |
          ((g * 255).round() << 8) |
          (b * 255).round(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED COLOR PALETTE - Exact copy from projectile.dart
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedColorPalette {
  SimulatedColorPalette(SimulatedColor base)
      : o10 = base.withOpacity(0.1),
        o15 = base.withOpacity(0.15),
        o20 = base.withOpacity(0.2),
        o25 = base.withOpacity(0.25),
        o30 = base.withOpacity(0.3),
        o40 = base.withOpacity(0.4),
        o50 = base.withOpacity(0.5),
        o60 = base.withOpacity(0.6),
        o70 = base.withOpacity(0.7),
        o80 = base.withOpacity(0.8),
        o85 = base.withOpacity(0.85),
        o90 = base.withOpacity(0.9),
        this.base = base;

  final SimulatedColor base;
  final SimulatedColor o10;
  final SimulatedColor o15;
  final SimulatedColor o20;
  final SimulatedColor o25;
  final SimulatedColor o30;
  final SimulatedColor o40;
  final SimulatedColor o50;
  final SimulatedColor o60;
  final SimulatedColor o70;
  final SimulatedColor o80;
  final SimulatedColor o85;
  final SimulatedColor o90;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED PALETTE CACHE - Exact logic from projectile.dart
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedPaletteCache {
  final Map<int, SimulatedColorPalette> _cache = {};
  static const int maxSize = 32;

  SimulatedColorPalette getPalette(SimulatedColor color) {
    final key = color.value;
    var palette = _cache[key];
    if (palette == null) {
      // Evict oldest entry if cache is full
      if (_cache.length >= maxSize) {
        _cache.remove(_cache.keys.first);
      }
      palette = SimulatedColorPalette(color);
      _cache[key] = palette;
    }
    return palette;
  }

  void clear() {
    _cache.clear();
  }

  int get size => _cache.length;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED CIRCULAR BUFFER TRAIL - Exact logic from projectile.dart
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedTrailBuffer {
  final int maxLength;
  final List<double> positions; // Simplified: just x values for testing
  final List<double> alphas;
  int head = 0;

  SimulatedTrailBuffer(this.maxLength)
      : positions = List.filled(maxLength, 0.0),
        alphas = List.filled(maxLength, 0.0);

  /// Get physical index from logical index (0 = newest, maxLength-1 = oldest)
  int getPhysicalIndex(int logicalIndex) {
    return (head - logicalIndex + maxLength) % maxLength;
  }

  /// Update trail - O(1) circular buffer operation
  void update(double newPosition) {
    // Decay all alphas first
    for (int i = 0; i < maxLength; i++) {
      alphas[i] *= 0.85;
    }

    // Move head forward and write new position
    head = (head + 1) % maxLength;
    positions[head] = newPosition;
    alphas[head] = 1.0;
  }

  double getPosition(int logicalIndex) {
    return positions[getPhysicalIndex(logicalIndex)];
  }

  double getAlpha(int logicalIndex) {
    return alphas[getPhysicalIndex(logicalIndex)];
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED STRESS LEVEL SYSTEM - Exact logic from projectile.dart
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedStressSystem {
  int stressLevel = 0;
  bool lowFx = false;

  void setStressLevel(int level) {
    stressLevel = level.clamp(0, 2);
    lowFx = stressLevel >= 2;
  }

  /// Calculate adjusted trail length based on stress
  int adjustTrailLength(int baseLength) {
    if (stressLevel >= 2 || lowFx) {
      return math.max(2, (baseLength * 0.35).round());
    }
    if (stressLevel >= 1) {
      return math.max(3, (baseLength * 0.5).round());
    }
    return baseLength;
  }

  /// Calculate adjusted particle count based on stress
  int adjustParticleCount(int baseCount) {
    if (stressLevel >= 2 || lowFx) {
      final result = (baseCount * 0.25).round();
      return result < 0 ? 0 : result;
    }
    if (stressLevel >= 1) {
      return math.max(2, (baseCount * 0.5).round());
    }
    return baseCount;
  }

  /// Whether wobble should be disabled
  bool get disableWobble => lowFx || stressLevel >= 2;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED TOWER TYPE - For type-specific initialization tests
// ═══════════════════════════════════════════════════════════════════════════════

enum SimulatedTowerType {
  pulseArcher,
  circuitCannon,
  phaseMage,
  glimmerField,
  ionSniper,
  teslaTerminal,
  resonanceSiphon,
  neuralDisruptor,
  plasmaBubble,
}

class SimulatedTypeEffects {
  int maxTrailLength = 12;
  int particleCount = 8;
  double wobbleAmount = 0;
  int electricSegmentCount = 0;
  double sizeX = 6;
  double sizeY = 6;

  void initializeForType(SimulatedTowerType type) {
    maxTrailLength = 12;
    particleCount = 8;
    wobbleAmount = 0;
    electricSegmentCount = 0;
    sizeX = 6;
    sizeY = 6;

    switch (type) {
      case SimulatedTowerType.pulseArcher:
        maxTrailLength = 10;
        particleCount = 6;
        break;
      case SimulatedTowerType.circuitCannon:
        maxTrailLength = 6;
        particleCount = 4;
        sizeX = 10;
        sizeY = 10;
        break;
      case SimulatedTowerType.phaseMage:
        maxTrailLength = 16;
        particleCount = 10;
        wobbleAmount = 0.3;
        electricSegmentCount = 5;
        break;
      case SimulatedTowerType.glimmerField:
        maxTrailLength = 8;
        particleCount = 12;
        sizeX = 4;
        sizeY = 4;
        wobbleAmount = 0.1;
        break;
      case SimulatedTowerType.ionSniper:
        maxTrailLength = 20;
        particleCount = 4;
        sizeX = 12;
        sizeY = 4;
        break;
      case SimulatedTowerType.teslaTerminal:
      case SimulatedTowerType.resonanceSiphon:
      case SimulatedTowerType.neuralDisruptor:
        maxTrailLength = 12;
        particleCount = 8;
        break;
      case SimulatedTowerType.plasmaBubble:
        maxTrailLength = 14;
        particleCount = 6;
        wobbleAmount = 0.5;
        sizeX = 14;
        sizeY = 14;
        break;
    }
  }

  void applyStressReduction(SimulatedStressSystem stress) {
    if (stress.stressLevel >= 1) {
      maxTrailLength = math.max(3, (maxTrailLength * 0.5).round());
      particleCount = math.max(2, (particleCount * 0.5).round());
    }
    if (stress.lowFx || stress.stressLevel >= 2) {
      maxTrailLength = math.max(2, (maxTrailLength * 0.35).round());
      particleCount = (particleCount * 0.25).round();
      if (particleCount < 0) particleCount = 0;
      wobbleAmount = 0;
      electricSegmentCount = 0;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED HSL COLOR CACHING - Exact logic from projectile.dart
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedHSLColorCache {
  late SimulatedColor pinkColor;
  late SimulatedColor purpleColor;
  late SimulatedColor brightColor;
  late SimulatedColor secondaryColor;
  late SimulatedColor tertiaryColor;
  late SimulatedColor complementColor;

  void cacheColors(SimulatedColor baseColor) {
    final hsl = SimulatedHSLColor.fromColor(baseColor);
    pinkColor = hsl.withHue((hsl.hue + 20) % 360).toColor();
    purpleColor = hsl.withHue((hsl.hue - 30 + 360) % 360).toColor();
    brightColor =
        hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
    secondaryColor = hsl.withHue((hsl.hue + 30) % 360).toColor();
    tertiaryColor = hsl.withHue((hsl.hue + 60) % 360).toColor();
    complementColor = hsl.withHue((hsl.hue + 180) % 360).toColor();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEST SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('SimulatedFastRng', () {
    test('default seed produces consistent sequence', () {
      final rng1 = SimulatedFastRng();
      final rng2 = SimulatedFastRng();

      for (int i = 0; i < 10; i++) {
        expect(rng1.nextDouble(), equals(rng2.nextDouble()));
      }
    });

    test('same seed produces same sequence', () {
      final rng1 = SimulatedFastRng(12345);
      final rng2 = SimulatedFastRng(12345);

      for (int i = 0; i < 100; i++) {
        expect(rng1.nextDouble(), equals(rng2.nextDouble()));
      }
    });

    test('different seeds produce different sequences', () {
      final rng1 = SimulatedFastRng(12345);
      final rng2 = SimulatedFastRng(54321);

      // At least one should be different in first 10
      bool foundDifferent = false;
      for (int i = 0; i < 10; i++) {
        if (rng1.nextDouble() != rng2.nextDouble()) {
          foundDifferent = true;
          break;
        }
      }
      expect(foundDifferent, isTrue);
    });

    test('nextDouble returns values in [0, 1)', () {
      final rng = SimulatedFastRng();
      for (int i = 0; i < 1000; i++) {
        final value = rng.nextDouble();
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThan(1.0));
      }
    });

    test('nextInt returns values in [0, max)', () {
      final rng = SimulatedFastRng();
      for (int max = 1; max <= 100; max++) {
        for (int i = 0; i < 50; i++) {
          final value = rng.nextInt(max);
          expect(value, greaterThanOrEqualTo(0));
          expect(value, lessThan(max));
        }
      }
    });

    test('nextInt with max 0 returns 0', () {
      final rng = SimulatedFastRng();
      expect(rng.nextInt(0), equals(0));
    });

    test('nextInt with negative max returns 0', () {
      final rng = SimulatedFastRng();
      expect(rng.nextInt(-5), equals(0));
    });

    test('nextBool returns both true and false', () {
      final rng = SimulatedFastRng();
      bool foundTrue = false;
      bool foundFalse = false;

      for (int i = 0; i < 100; i++) {
        if (rng.nextBool()) {
          foundTrue = true;
        } else {
          foundFalse = true;
        }
        if (foundTrue && foundFalse) break;
      }

      expect(foundTrue, isTrue);
      expect(foundFalse, isTrue);
    });

    test('LCG formula is correct', () {
      final rng = SimulatedFastRng(1);

      // First iteration: (1664525 * 1 + 1013904223) & 0x7fffffff
      final expected = (1664525 * 1 + 1013904223) & 0x7fffffff;
      rng.nextDouble(); // Advance state

      // State should be the expected value after one iteration
      expect(rng.state, equals(expected));
    });

    test('state masking keeps values in 31-bit range', () {
      final rng = SimulatedFastRng();
      for (int i = 0; i < 1000; i++) {
        rng.nextDouble();
        expect(rng.state, lessThanOrEqualTo(0x7fffffff));
        expect(rng.state, greaterThanOrEqualTo(0));
      }
    });
  });

  group('SimulatedTrailBuffer - Circular Buffer', () {
    test('initial state has all zeros', () {
      final buffer = SimulatedTrailBuffer(10);

      for (int i = 0; i < 10; i++) {
        expect(buffer.getPosition(i), equals(0.0));
        expect(buffer.getAlpha(i), equals(0.0));
      }
    });

    test('first update sets position and alpha', () {
      final buffer = SimulatedTrailBuffer(10);
      buffer.update(100.0);

      expect(buffer.getPosition(0), equals(100.0));
      expect(buffer.getAlpha(0), equals(1.0));
    });

    test('physical index calculation is correct', () {
      final buffer = SimulatedTrailBuffer(5);

      // Initial head is 0
      // After update, head becomes 1
      buffer.update(10.0);
      expect(buffer.head, equals(1));

      // Logical 0 (newest) should map to physical 1
      expect(buffer.getPhysicalIndex(0), equals(1));

      // Logical 1 should map to physical 0
      expect(buffer.getPhysicalIndex(1), equals(0));
    });

    test('circular buffer wraps correctly', () {
      final buffer = SimulatedTrailBuffer(5);

      for (int i = 0; i < 7; i++) {
        buffer.update(i.toDouble());
      }

      // After 7 updates, head = 7 % 5 = 2
      expect(buffer.head, equals(2));

      // Newest (logical 0) should be 6.0
      expect(buffer.getPosition(0), equals(6.0));
    });

    test('alpha decay is applied correctly', () {
      final buffer = SimulatedTrailBuffer(10);

      buffer.update(1.0); // alpha[1] = 1.0
      expect(buffer.getAlpha(0), equals(1.0));

      buffer.update(2.0); // alpha[1] *= 0.85, alpha[2] = 1.0
      expect(buffer.getAlpha(0), equals(1.0)); // Newest
      expect(buffer.getAlpha(1), closeTo(0.85, 0.0001)); // Previous
    });

    test('multiple updates decay alphas exponentially', () {
      final buffer = SimulatedTrailBuffer(10);

      buffer.update(1.0);
      buffer.update(2.0);
      buffer.update(3.0);
      buffer.update(4.0);

      // Newest should be 1.0
      expect(buffer.getAlpha(0), equals(1.0));

      // Second newest: 0.85
      expect(buffer.getAlpha(1), closeTo(0.85, 0.0001));

      // Third: 0.85^2 = 0.7225
      expect(buffer.getAlpha(2), closeTo(0.7225, 0.0001));

      // Fourth: 0.85^3 = 0.614125
      expect(buffer.getAlpha(3), closeTo(0.614125, 0.0001));
    });

    test('O(1) update complexity - no shifting', () {
      final buffer = SimulatedTrailBuffer(1000);

      // Even with large buffer, update is O(1) for position write
      // (Note: alpha decay is O(n), but position is O(1))
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 10000; i++) {
        buffer.update(i.toDouble());
      }

      stopwatch.stop();
      // Should complete quickly (O(n) for alphas, O(1) for position)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('SimulatedColorPalette', () {
    test('creates all opacity variants', () {
      final color = SimulatedColor(0xFF00FFFF); // Cyan
      final palette = SimulatedColorPalette(color);

      expect(palette.base.value, equals(0xFF00FFFF));
      expect(palette.o10.alpha, equals((0.1 * 255).round()));
      expect(palette.o25.alpha, equals((0.25 * 255).round()));
      expect(palette.o50.alpha, equals((0.5 * 255).round()));
      expect(palette.o80.alpha, equals((0.8 * 255).round()));
      expect(palette.o90.alpha, equals((0.9 * 255).round()));
    });

    test('preserves RGB values in opacity variants', () {
      final color = SimulatedColor(0xFFFF8800); // Orange
      final palette = SimulatedColorPalette(color);

      expect(palette.o50.red, equals(0xFF));
      expect(palette.o50.green, equals(0x88));
      expect(palette.o50.blue, equals(0x00));
    });
  });

  group('SimulatedPaletteCache', () {
    test('caches palettes for repeated colors', () {
      final cache = SimulatedPaletteCache();
      final color = SimulatedColor(0xFF00FFFF);

      final palette1 = cache.getPalette(color);
      final palette2 = cache.getPalette(color);

      expect(identical(palette1, palette2), isTrue);
      expect(cache.size, equals(1));
    });

    test('creates different palettes for different colors', () {
      final cache = SimulatedPaletteCache();

      final palette1 = cache.getPalette(SimulatedColor(0xFF00FFFF));
      final palette2 = cache.getPalette(SimulatedColor(0xFFFF00FF));

      expect(identical(palette1, palette2), isFalse);
      expect(cache.size, equals(2));
    });

    test('evicts oldest entry when cache is full', () {
      final cache = SimulatedPaletteCache();

      // Fill cache to max
      for (int i = 0; i < 32; i++) {
        cache.getPalette(SimulatedColor(0xFF000000 + i));
      }

      expect(cache.size, equals(32));

      // Add one more - should evict oldest
      cache.getPalette(SimulatedColor(0xFF000100));
      expect(cache.size, equals(32)); // Still 32
    });

    test('clear empties the cache', () {
      final cache = SimulatedPaletteCache();

      cache.getPalette(SimulatedColor(0xFF00FFFF));
      cache.getPalette(SimulatedColor(0xFFFF00FF));
      expect(cache.size, equals(2));

      cache.clear();
      expect(cache.size, equals(0));
    });
  });

  group('SimulatedStressSystem', () {
    test('default stress level is 0', () {
      final stress = SimulatedStressSystem();
      expect(stress.stressLevel, equals(0));
      expect(stress.lowFx, isFalse);
    });

    test('setStressLevel clamps to 0-2', () {
      final stress = SimulatedStressSystem();

      stress.setStressLevel(-1);
      expect(stress.stressLevel, equals(0));

      stress.setStressLevel(5);
      expect(stress.stressLevel, equals(2));

      stress.setStressLevel(1);
      expect(stress.stressLevel, equals(1));
    });

    test('lowFx is true at stress level 2', () {
      final stress = SimulatedStressSystem();

      stress.setStressLevel(0);
      expect(stress.lowFx, isFalse);

      stress.setStressLevel(1);
      expect(stress.lowFx, isFalse);

      stress.setStressLevel(2);
      expect(stress.lowFx, isTrue);
    });

    test('trail length adjustment at stress 0', () {
      final stress = SimulatedStressSystem();
      stress.setStressLevel(0);

      expect(stress.adjustTrailLength(12), equals(12));
      expect(stress.adjustTrailLength(16), equals(16));
    });

    test('trail length adjustment at stress 1', () {
      final stress = SimulatedStressSystem();
      stress.setStressLevel(1);

      // 12 * 0.5 = 6, max(3, 6) = 6
      expect(stress.adjustTrailLength(12), equals(6));

      // 16 * 0.5 = 8, max(3, 8) = 8
      expect(stress.adjustTrailLength(16), equals(8));

      // 4 * 0.5 = 2, max(3, 2) = 3
      expect(stress.adjustTrailLength(4), equals(3));
    });

    test('trail length adjustment at stress 2', () {
      final stress = SimulatedStressSystem();
      stress.setStressLevel(2);

      // 12 * 0.35 = 4.2 -> 4, max(2, 4) = 4
      expect(stress.adjustTrailLength(12), equals(4));

      // 16 * 0.35 = 5.6 -> 6, max(2, 6) = 6
      expect(stress.adjustTrailLength(16), equals(6));

      // 4 * 0.35 = 1.4 -> 1, max(2, 1) = 2
      expect(stress.adjustTrailLength(4), equals(2));
    });

    test('particle count adjustment at stress 0', () {
      final stress = SimulatedStressSystem();
      stress.setStressLevel(0);

      expect(stress.adjustParticleCount(8), equals(8));
      expect(stress.adjustParticleCount(12), equals(12));
    });

    test('particle count adjustment at stress 1', () {
      final stress = SimulatedStressSystem();
      stress.setStressLevel(1);

      // 8 * 0.5 = 4, max(2, 4) = 4
      expect(stress.adjustParticleCount(8), equals(4));

      // 12 * 0.5 = 6, max(2, 6) = 6
      expect(stress.adjustParticleCount(12), equals(6));

      // 2 * 0.5 = 1, max(2, 1) = 2
      expect(stress.adjustParticleCount(2), equals(2));
    });

    test('particle count adjustment at stress 2', () {
      final stress = SimulatedStressSystem();
      stress.setStressLevel(2);

      // 8 * 0.25 = 2
      expect(stress.adjustParticleCount(8), equals(2));

      // 12 * 0.25 = 3
      expect(stress.adjustParticleCount(12), equals(3));

      // 4 * 0.25 = 1
      expect(stress.adjustParticleCount(4), equals(1));
    });

    test('wobble disabled at high stress', () {
      final stress = SimulatedStressSystem();

      stress.setStressLevel(0);
      expect(stress.disableWobble, isFalse);

      stress.setStressLevel(1);
      expect(stress.disableWobble, isFalse);

      stress.setStressLevel(2);
      expect(stress.disableWobble, isTrue);
    });
  });

  group('SimulatedTypeEffects', () {
    test('pulseArcher initialization', () {
      final effects = SimulatedTypeEffects();
      effects.initializeForType(SimulatedTowerType.pulseArcher);

      expect(effects.maxTrailLength, equals(10));
      expect(effects.particleCount, equals(6));
      expect(effects.wobbleAmount, equals(0));
      expect(effects.sizeX, equals(6));
    });

    test('circuitCannon initialization', () {
      final effects = SimulatedTypeEffects();
      effects.initializeForType(SimulatedTowerType.circuitCannon);

      expect(effects.maxTrailLength, equals(6));
      expect(effects.particleCount, equals(4));
      expect(effects.sizeX, equals(10));
      expect(effects.sizeY, equals(10));
    });

    test('phaseMage initialization', () {
      final effects = SimulatedTypeEffects();
      effects.initializeForType(SimulatedTowerType.phaseMage);

      expect(effects.maxTrailLength, equals(16));
      expect(effects.particleCount, equals(10));
      expect(effects.wobbleAmount, equals(0.3));
      expect(effects.electricSegmentCount, equals(5));
    });

    test('glimmerField initialization', () {
      final effects = SimulatedTypeEffects();
      effects.initializeForType(SimulatedTowerType.glimmerField);

      expect(effects.maxTrailLength, equals(8));
      expect(effects.particleCount, equals(12));
      expect(effects.wobbleAmount, equals(0.1));
      expect(effects.sizeX, equals(4));
      expect(effects.sizeY, equals(4));
    });

    test('ionSniper initialization', () {
      final effects = SimulatedTypeEffects();
      effects.initializeForType(SimulatedTowerType.ionSniper);

      expect(effects.maxTrailLength, equals(20));
      expect(effects.particleCount, equals(4));
      expect(effects.sizeX, equals(12));
      expect(effects.sizeY, equals(4));
    });

    test('plasmaBubble initialization', () {
      final effects = SimulatedTypeEffects();
      effects.initializeForType(SimulatedTowerType.plasmaBubble);

      expect(effects.maxTrailLength, equals(14));
      expect(effects.particleCount, equals(6));
      expect(effects.wobbleAmount, equals(0.5));
      expect(effects.sizeX, equals(14));
      expect(effects.sizeY, equals(14));
    });

    test('stress reduction at level 1', () {
      final effects = SimulatedTypeEffects();
      effects.initializeForType(SimulatedTowerType.phaseMage);

      final stress = SimulatedStressSystem();
      stress.setStressLevel(1);
      effects.applyStressReduction(stress);

      // 16 * 0.5 = 8, max(3, 8) = 8
      expect(effects.maxTrailLength, equals(8));
      // 10 * 0.5 = 5, max(2, 5) = 5
      expect(effects.particleCount, equals(5));
      // Wobble preserved
      expect(effects.wobbleAmount, equals(0.3));
      // Electric segments preserved
      expect(effects.electricSegmentCount, equals(5));
    });

    test('stress reduction at level 2', () {
      final effects = SimulatedTypeEffects();
      effects.initializeForType(SimulatedTowerType.phaseMage);

      final stress = SimulatedStressSystem();
      stress.setStressLevel(2);
      effects.applyStressReduction(stress);

      // First stress 1 reduction, then stress 2
      // After stress 1: trail = 8, particles = 5
      // Then stress 2: trail = max(2, 8*0.35=2.8) = 3
      //                particles = 5 * 0.25 = 1.25 -> 1
      expect(effects.maxTrailLength, equals(3));
      expect(effects.particleCount, equals(1));
      // Wobble disabled
      expect(effects.wobbleAmount, equals(0));
      // Electric segments cleared
      expect(effects.electricSegmentCount, equals(0));
    });

    test('all tower types have valid defaults', () {
      final effects = SimulatedTypeEffects();

      for (final type in SimulatedTowerType.values) {
        effects.initializeForType(type);

        expect(effects.maxTrailLength, greaterThan(0));
        expect(effects.particleCount, greaterThanOrEqualTo(0));
        expect(effects.sizeX, greaterThan(0));
        expect(effects.sizeY, greaterThan(0));
        expect(effects.wobbleAmount, greaterThanOrEqualTo(0));
      }
    });
  });

  group('SimulatedHSLColorCache', () {
    test('caches pink color (+20 hue)', () {
      final cache = SimulatedHSLColorCache();
      final cyan = SimulatedColor(0xFF00FFFF);
      cache.cacheColors(cyan);

      final cyanHSL = SimulatedHSLColor.fromColor(cyan);
      final expectedPink = cyanHSL.withHue((cyanHSL.hue + 20) % 360).toColor();

      expect(cache.pinkColor.value, equals(expectedPink.value));
    });

    test('caches purple color (-30 hue)', () {
      final cache = SimulatedHSLColorCache();
      final cyan = SimulatedColor(0xFF00FFFF);
      cache.cacheColors(cyan);

      final cyanHSL = SimulatedHSLColor.fromColor(cyan);
      final expectedPurple =
          cyanHSL.withHue((cyanHSL.hue - 30 + 360) % 360).toColor();

      expect(cache.purpleColor.value, equals(expectedPurple.value));
    });

    test('caches bright color (+0.2 lightness)', () {
      final cache = SimulatedHSLColorCache();
      final color = SimulatedColor(0xFF808080); // Mid gray
      cache.cacheColors(color);

      final hsl = SimulatedHSLColor.fromColor(color);
      final expectedBright =
          hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();

      expect(cache.brightColor.value, equals(expectedBright.value));
    });

    test('caches secondary color (+30 hue)', () {
      final cache = SimulatedHSLColorCache();
      final red = SimulatedColor(0xFFFF0000);
      cache.cacheColors(red);

      final redHSL = SimulatedHSLColor.fromColor(red);
      final expectedSecondary =
          redHSL.withHue((redHSL.hue + 30) % 360).toColor();

      expect(cache.secondaryColor.value, equals(expectedSecondary.value));
    });

    test('caches tertiary color (+60 hue)', () {
      final cache = SimulatedHSLColorCache();
      final blue = SimulatedColor(0xFF0000FF);
      cache.cacheColors(blue);

      final blueHSL = SimulatedHSLColor.fromColor(blue);
      final expectedTertiary =
          blueHSL.withHue((blueHSL.hue + 60) % 360).toColor();

      expect(cache.tertiaryColor.value, equals(expectedTertiary.value));
    });

    test('caches complement color (+180 hue)', () {
      final cache = SimulatedHSLColorCache();
      final green = SimulatedColor(0xFF00FF00);
      cache.cacheColors(green);

      final greenHSL = SimulatedHSLColor.fromColor(green);
      final expectedComplement =
          greenHSL.withHue((greenHSL.hue + 180) % 360).toColor();

      expect(cache.complementColor.value, equals(expectedComplement.value));
    });

    test('lightness clamps to 1.0 max', () {
      final cache = SimulatedHSLColorCache();
      final brightColor = SimulatedColor(0xFFFFFFFF); // White (L=1.0)
      cache.cacheColors(brightColor);

      final hsl = SimulatedHSLColor.fromColor(cache.brightColor);
      expect(hsl.lightness, lessThanOrEqualTo(1.0));
    });
  });

  group('SimulatedHSLColor', () {
    test('converts red correctly', () {
      final red = SimulatedColor(0xFFFF0000);
      final hsl = SimulatedHSLColor.fromColor(red);

      expect(hsl.hue, closeTo(0.0, 1.0));
      expect(hsl.saturation, closeTo(1.0, 0.01));
      expect(hsl.lightness, closeTo(0.5, 0.01));
    });

    test('converts green correctly', () {
      final green = SimulatedColor(0xFF00FF00);
      final hsl = SimulatedHSLColor.fromColor(green);

      expect(hsl.hue, closeTo(120.0, 1.0));
      expect(hsl.saturation, closeTo(1.0, 0.01));
      expect(hsl.lightness, closeTo(0.5, 0.01));
    });

    test('converts blue correctly', () {
      final blue = SimulatedColor(0xFF0000FF);
      final hsl = SimulatedHSLColor.fromColor(blue);

      expect(hsl.hue, closeTo(240.0, 1.0));
      expect(hsl.saturation, closeTo(1.0, 0.01));
      expect(hsl.lightness, closeTo(0.5, 0.01));
    });

    test('converts gray correctly', () {
      final gray = SimulatedColor(0xFF808080);
      final hsl = SimulatedHSLColor.fromColor(gray);

      expect(hsl.saturation, closeTo(0.0, 0.01));
      expect(hsl.lightness, closeTo(0.5, 0.01));
    });

    test('converts white correctly', () {
      final white = SimulatedColor(0xFFFFFFFF);
      final hsl = SimulatedHSLColor.fromColor(white);

      expect(hsl.lightness, closeTo(1.0, 0.01));
    });

    test('converts black correctly', () {
      final black = SimulatedColor(0xFF000000);
      final hsl = SimulatedHSLColor.fromColor(black);

      expect(hsl.lightness, closeTo(0.0, 0.01));
    });

    test('round-trip conversion preserves color', () {
      final originalColors = [
        SimulatedColor(0xFFFF0000),
        SimulatedColor(0xFF00FF00),
        SimulatedColor(0xFF0000FF),
        SimulatedColor(0xFF00FFFF),
        SimulatedColor(0xFFFF00FF),
        SimulatedColor(0xFFFFFF00),
        SimulatedColor(0xFF808080),
      ];

      for (final original in originalColors) {
        final hsl = SimulatedHSLColor.fromColor(original);
        final converted = hsl.toColor();

        // Allow small rounding differences
        expect((original.red - converted.red).abs(), lessThanOrEqualTo(1));
        expect((original.green - converted.green).abs(), lessThanOrEqualTo(1));
        expect((original.blue - converted.blue).abs(), lessThanOrEqualTo(1));
      }
    });

    test('withHue wraps around 360', () {
      final hsl = SimulatedHSLColor(hue: 350, saturation: 1.0, lightness: 0.5);
      final shifted = hsl.withHue(370);

      expect(shifted.hue, closeTo(10.0, 0.01));
    });

    test('withLightness clamps to [0, 1]', () {
      final hsl = SimulatedHSLColor(hue: 0, saturation: 1.0, lightness: 0.5);

      final bright = hsl.withLightness(1.5);
      expect(bright.lightness, equals(1.0));

      final dark = hsl.withLightness(-0.5);
      expect(dark.lightness, equals(0.0));
    });
  });

  group('Integration - Projectile Update Simulation', () {
    test('trail buffer maintains proper decay over time', () {
      final buffer = SimulatedTrailBuffer(10);

      // Simulate 30 frames of movement
      for (int frame = 0; frame < 30; frame++) {
        buffer.update(frame * 10.0);
      }

      // Newest position should be 290.0
      expect(buffer.getPosition(0), equals(290.0));

      // Alpha decay should be exponential
      expect(buffer.getAlpha(0), equals(1.0));
      expect(buffer.getAlpha(1), closeTo(0.85, 0.0001));
      expect(buffer.getAlpha(2), closeTo(0.7225, 0.0001));
    });

    test('stress level affects all visual parameters', () {
      final effects = SimulatedTypeEffects();
      final stress = SimulatedStressSystem();

      // Test phaseMage at different stress levels
      for (int level = 0; level <= 2; level++) {
        effects.initializeForType(SimulatedTowerType.phaseMage);
        stress.setStressLevel(level);
        effects.applyStressReduction(stress);

        if (level == 0) {
          expect(effects.maxTrailLength, equals(16));
          expect(effects.particleCount, equals(10));
          expect(effects.wobbleAmount, equals(0.3));
        } else if (level == 1) {
          expect(effects.maxTrailLength, equals(8));
          expect(effects.particleCount, equals(5));
          expect(effects.wobbleAmount, equals(0.3));
        } else {
          expect(effects.maxTrailLength, lessThanOrEqualTo(3));
          expect(effects.particleCount, lessThanOrEqualTo(1));
          expect(effects.wobbleAmount, equals(0));
        }
      }
    });

    test('color palette caching prevents redundant allocations', () {
      final cache = SimulatedPaletteCache();
      final cyan = SimulatedColor(0xFF00FFFF);

      // First access creates palette
      final p1 = cache.getPalette(cyan);
      expect(cache.size, equals(1));

      // Subsequent accesses return cached instance
      for (int i = 0; i < 1000; i++) {
        final p = cache.getPalette(cyan);
        expect(identical(p, p1), isTrue);
      }

      expect(cache.size, equals(1));
    });

    test('RNG produces good distribution for particle offsets', () {
      final rng = SimulatedFastRng();
      final buckets = List.filled(10, 0);

      for (int i = 0; i < 10000; i++) {
        final value = rng.nextDouble();
        final bucket = (value * 10).floor().clamp(0, 9);
        buckets[bucket]++;
      }

      // Each bucket should have roughly 1000 entries
      for (final count in buckets) {
        expect(count, greaterThan(800));
        expect(count, lessThan(1200));
      }
    });
  });
}
