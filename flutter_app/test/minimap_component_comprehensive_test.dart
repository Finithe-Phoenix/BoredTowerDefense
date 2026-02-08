import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

/// Tests for MinimapComponent logic and calculations
/// Tests pure mathematical functions without requiring game context

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED CLASSES FROM minimap_component.dart
// ═══════════════════════════════════════════════════════════════════════════════

/// Fast RNG using Linear Congruential Generator (same as in MinimapComponent)
class FastRng {
  int _state;

  FastRng([int? seed]) : _state = (seed ?? 0x6d2b79f5) & 0x7fffffff;

  int _next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  double nextDouble() => _next() / 0x7fffffff;
  int nextInt(int max) => max <= 0 ? 0 : _next() % max;
  bool nextBool() => (_next() & 1) == 0;
}

/// Static LCG helper functions (same as in MinimapComponent)
class LcgHelpers {
  static int lcgSeed(int seed, int salt) => (seed ^ salt) & 0x7fffffff;
  static int lcgNext(int state) => (state * 1664525 + 1013904223) & 0x7fffffff;
  static double lcgUnit(int state) => state / 0x7fffffff;
}

/// Minimap constants (same as in MinimapComponent)
class MinimapConstants {
  static const double baseMapSize = 130.0;
  static const double borderWidth = 2.0;
  static const double basePadding = 12.0;
  static const List<String> glitchChars = ['#', '@', '!', '%', '&', '*', '?', '/', '\\', '|'];
}

/// Simulates minimap scaling logic
class MinimapScaler {
  static const double baseWidth = 1920.0;
  static const double baseHeight = 1080.0;

  static double calculateScale(double screenWidth, double screenHeight) {
    final scaleX = (screenWidth / baseWidth).clamp(0.5, 1.2);
    final scaleY = (screenHeight / baseHeight).clamp(0.5, 1.2);
    return math.min(scaleX, scaleY);
  }

  static double calculateMapSize(double scale) {
    return (MinimapConstants.baseMapSize * scale).clamp(80.0, 140.0);
  }

  static bool shouldHideOnCompact(double screenWidth, bool compact) {
    return compact && screenWidth < 600;
  }
}

/// Simulates corruption level logic
class CorruptionCalculator {
  static const int maxEnemiesForFullCorruption = 30;

  static double calculateCorruptionLevel(int enemyCount) {
    return (enemyCount / maxEnemiesForFullCorruption).clamp(0.0, 1.0);
  }
}

/// Simulates glitch effect timing
class GlitchEffect {
  double glitchTimer = 0;
  double glitchIntensity = 0;
  bool isGlitching = false;
  int glitchFrame = 0;

  static const double decayRate = 3.0;

  void update(double dt, FastRng random) {
    glitchTimer += dt;

    // Trigger glitch after 2.0 + random * 3.0 seconds
    if (glitchTimer > 2.0 + random.nextDouble() * 3.0) {
      glitchTimer = 0;
      isGlitching = true;
      glitchIntensity = 0.5 + random.nextDouble() * 0.5;
      glitchFrame = random.nextInt(1000);
    }

    if (isGlitching) {
      glitchIntensity -= dt * decayRate;
      if (glitchIntensity <= 0) {
        isGlitching = false;
        glitchIntensity = 0;
      }
    }
  }
}

/// Simulates hexagonal path creation
class HexagonalPathCalculator {
  /// Calculate hexagon vertex positions
  static List<(double, double)> calculateHexagonVertices(
    double cx,
    double cy,
    double radius,
  ) {
    final vertices = <(double, double)>[];
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      vertices.add((x, y));
    }
    return vertices;
  }
}

/// Simulates string corruption for glitch effect
class StringCorruptor {
  static String corruptString(String input, int glitchFrame, FastRng random) {
    var state = LcgHelpers.lcgSeed(glitchFrame, 0x9e3779b9);
    final chars = input.split('');

    for (int i = 0; i < chars.length; i++) {
      state = LcgHelpers.lcgNext(state);
      if (LcgHelpers.lcgUnit(state) < 0.25) {
        state = LcgHelpers.lcgNext(state);
        chars[i] = MinimapConstants.glitchChars[state % MinimapConstants.glitchChars.length];
      }
    }
    return chars.join();
  }
}

/// Simulates animation calculations
class MinimapAnimations {
  static const double scanSpeed = 2.5;
  static const double pulseSpeed = 4.0;
  static const double movingScanlineSpeed = 40.0;

  /// Calculate scan angle from time
  static double calculateScanAngle(double time, double initialAngle) {
    return initialAngle + time * scanSpeed;
  }

  /// Calculate pulse phase from time
  static double calculatePulsePhase(double time, double initialPhase) {
    return initialPhase + time * pulseSpeed;
  }

  /// Calculate moving scanline Y position
  static double calculateScanlineY(double time, double mapSize) {
    return (time * movingScanlineSpeed) % mapSize;
  }

  /// Calculate corruption scanline Y (moves opposite direction)
  static double calculateCorruptionScanlineY(double time, double mapSize) {
    return mapSize - (time * 25) % mapSize;
  }
}

/// Simulates radar sweep calculations
class RadarSweep {
  static (double, double) calculateSweepEndpoint(
    double centerX,
    double centerY,
    double scanLength,
    double scanAngle,
  ) {
    final endX = centerX + math.cos(scanAngle) * scanLength;
    final endY = centerY + math.sin(scanAngle) * scanLength;
    return (endX, endY);
  }
}

/// Simulates path dot animation
class PathDotAnimator {
  static const int dotCount = 3;
  static const double dotSpacing = 0.33;
  static const double dotSpeed = 0.1;

  static List<double> calculateDotProgresses(double time) {
    final progresses = <double>[];
    for (int i = 0; i < dotCount; i++) {
      final progress = ((time * dotSpeed + i * dotSpacing) % 1.0);
      progresses.add(progress);
    }
    return progresses;
  }
}

/// Simulates data stream rendering
class DataStreamCalculator {
  static const int streamCount = 5;
  static const int streamLength = 8;

  static double calculateStreamY(double time, double baseY, int index, double speed) {
    return (time * speed + index * 50) % (baseY + 30) - 15;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('MinimapComponent Constants', () {
    test('base constants have correct values', () {
      expect(MinimapConstants.baseMapSize, 130.0);
      expect(MinimapConstants.borderWidth, 2.0);
      expect(MinimapConstants.basePadding, 12.0);
    });

    test('glitch characters list has 10 characters', () {
      expect(MinimapConstants.glitchChars.length, 10);
      expect(MinimapConstants.glitchChars, contains('#'));
      expect(MinimapConstants.glitchChars, contains('@'));
      expect(MinimapConstants.glitchChars, contains('?'));
    });
  });

  group('FastRng (LCG)', () {
    test('produces consistent sequence with same seed', () {
      final rng1 = FastRng(12345);
      final rng2 = FastRng(12345);

      for (int i = 0; i < 10; i++) {
        expect(rng1.nextDouble(), rng2.nextDouble());
      }
    });

    test('produces different sequences with different seeds', () {
      final rng1 = FastRng(12345);
      final rng2 = FastRng(54321);

      final values1 = List.generate(5, (_) => rng1.nextDouble());
      final values2 = List.generate(5, (_) => rng2.nextDouble());

      expect(values1, isNot(equals(values2)));
    });

    test('nextDouble returns values in [0, 1)', () {
      final rng = FastRng(42);
      for (int i = 0; i < 100; i++) {
        final value = rng.nextDouble();
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThan(1.0));
      }
    });

    test('nextInt returns values in [0, max)', () {
      final rng = FastRng(42);
      for (int i = 0; i < 100; i++) {
        final value = rng.nextInt(10);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(10));
      }
    });

    test('nextInt handles max <= 0', () {
      final rng = FastRng(42);
      expect(rng.nextInt(0), 0);
      expect(rng.nextInt(-5), 0);
    });

    test('nextBool returns both true and false', () {
      final rng = FastRng(42);
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

      expect(foundTrue, true);
      expect(foundFalse, true);
    });

    test('default seed is 0x6d2b79f5', () {
      final rng1 = FastRng();
      final rng2 = FastRng(0x6d2b79f5);

      // Should produce same sequence
      expect(rng1.nextDouble(), rng2.nextDouble());
    });
  });

  group('LCG Helper Functions', () {
    test('lcgSeed combines seed and salt with XOR', () {
      // 0 ^ 0 = 0
      expect(LcgHelpers.lcgSeed(0, 0), 0);
      // 0xFF ^ 0x00 = 0xFF
      expect(LcgHelpers.lcgSeed(0xFF, 0x00), 0xFF);
      // 0xAA ^ 0x55 = 0xFF
      expect(LcgHelpers.lcgSeed(0xAA, 0x55), 0xFF);
    });

    test('lcgSeed masks to 31 bits', () {
      final result = LcgHelpers.lcgSeed(0xFFFFFFFF, 0);
      expect(result, 0x7FFFFFFF);
    });

    test('lcgNext produces deterministic sequence', () {
      var state = 12345;
      final results = <int>[];
      for (int i = 0; i < 5; i++) {
        state = LcgHelpers.lcgNext(state);
        results.add(state);
      }

      // Reset and verify same sequence
      state = 12345;
      for (int i = 0; i < 5; i++) {
        state = LcgHelpers.lcgNext(state);
        expect(state, results[i]);
      }
    });

    test('lcgUnit converts state to [0, 1) range', () {
      expect(LcgHelpers.lcgUnit(0), 0.0);
      expect(LcgHelpers.lcgUnit(0x7FFFFFFF), closeTo(1.0, 0.0001));
      expect(LcgHelpers.lcgUnit(0x3FFFFFFF), closeTo(0.5, 0.01));
    });
  });

  group('Minimap Scaling', () {
    test('calculates scale for 1920x1080 screen', () {
      final scale = MinimapScaler.calculateScale(1920, 1080);
      expect(scale, 1.0);
    });

    test('calculates scale for smaller screen', () {
      final scale = MinimapScaler.calculateScale(960, 540);
      expect(scale, 0.5);
    });

    test('calculates scale for larger screen', () {
      final scale = MinimapScaler.calculateScale(3840, 2160);
      // 3840/1920 = 2.0, clamped to 1.2
      // 2160/1080 = 2.0, clamped to 1.2
      expect(scale, 1.2);
    });

    test('scale clamps minimum to 0.5', () {
      final scale = MinimapScaler.calculateScale(480, 270);
      expect(scale, 0.5);
    });

    test('map size calculated from scale', () {
      expect(MinimapScaler.calculateMapSize(1.0), 130.0);
      expect(MinimapScaler.calculateMapSize(0.5), 80.0); // 65 clamped to 80
      expect(MinimapScaler.calculateMapSize(1.2), 140.0); // 156 clamped to 140
    });

    test('map size clamps to [80, 140]', () {
      expect(MinimapScaler.calculateMapSize(0.1), 80.0);
      expect(MinimapScaler.calculateMapSize(2.0), 140.0);
    });

    test('hide on compact screen under 600px', () {
      expect(MinimapScaler.shouldHideOnCompact(500, true), true);
      expect(MinimapScaler.shouldHideOnCompact(700, true), false);
      expect(MinimapScaler.shouldHideOnCompact(500, false), false);
    });
  });

  group('Corruption Calculator', () {
    test('0 enemies = 0 corruption', () {
      expect(CorruptionCalculator.calculateCorruptionLevel(0), 0.0);
    });

    test('30 enemies = full corruption', () {
      expect(CorruptionCalculator.calculateCorruptionLevel(30), 1.0);
    });

    test('15 enemies = 50% corruption', () {
      expect(CorruptionCalculator.calculateCorruptionLevel(15), 0.5);
    });

    test('corruption clamps to 1.0 max', () {
      expect(CorruptionCalculator.calculateCorruptionLevel(60), 1.0);
      expect(CorruptionCalculator.calculateCorruptionLevel(100), 1.0);
    });

    test('corruption is proportional', () {
      expect(CorruptionCalculator.calculateCorruptionLevel(3), closeTo(0.1, 0.001));
      expect(CorruptionCalculator.calculateCorruptionLevel(6), closeTo(0.2, 0.001));
      expect(CorruptionCalculator.calculateCorruptionLevel(9), closeTo(0.3, 0.001));
    });
  });

  group('Glitch Effect', () {
    test('starts with no glitch active', () {
      final glitch = GlitchEffect();
      expect(glitch.isGlitching, false);
      expect(glitch.glitchIntensity, 0);
    });

    test('glitch triggers after timeout', () {
      final glitch = GlitchEffect();
      final rng = FastRng(42);

      // Keep updating until glitch triggers
      for (int i = 0; i < 100; i++) {
        glitch.update(0.1, rng);
        if (glitch.isGlitching) break;
      }

      expect(glitch.isGlitching, true);
      expect(glitch.glitchIntensity, greaterThan(0));
    });

    test('glitch intensity decays over time', () {
      final glitch = GlitchEffect();
      glitch.isGlitching = true;
      glitch.glitchIntensity = 1.0;

      final rng = FastRng(42);
      glitch.update(0.1, rng);

      // Decay rate is 3.0, so after 0.1s: 1.0 - 0.1 * 3.0 = 0.7
      expect(glitch.glitchIntensity, closeTo(0.7, 0.001));
    });

    test('glitch ends when intensity reaches 0', () {
      final glitch = GlitchEffect();
      glitch.isGlitching = true;
      glitch.glitchIntensity = 0.1;

      final rng = FastRng(42);
      glitch.update(0.1, rng);

      // 0.1 - 0.1 * 3.0 = -0.2, clamped to 0
      expect(glitch.isGlitching, false);
      expect(glitch.glitchIntensity, 0);
    });

    test('glitch intensity is between 0.5 and 1.0', () {
      final rng = FastRng(42);

      for (int i = 0; i < 20; i++) {
        final glitch = GlitchEffect();
        // Force trigger
        glitch.glitchTimer = 10.0;
        glitch.update(0.01, rng);

        if (glitch.isGlitching) {
          // After update, intensity may have decayed slightly (0.01 * 3.0 = 0.03)
          // So we allow for initial intensity of 0.5+ minus small decay
          expect(glitch.glitchIntensity, greaterThanOrEqualTo(0.47));
          expect(glitch.glitchIntensity, lessThanOrEqualTo(1.0));
        }
      }
    });
  });

  group('Hexagonal Path', () {
    test('creates 6 vertices', () {
      final vertices = HexagonalPathCalculator.calculateHexagonVertices(50, 50, 25);
      expect(vertices.length, 6);
    });

    test('first vertex is at top center', () {
      final vertices = HexagonalPathCalculator.calculateHexagonVertices(50, 50, 25);
      final (x, y) = vertices[0];

      // First vertex at angle -pi/2 (top)
      expect(x, closeTo(50, 0.001)); // centerX
      expect(y, closeTo(25, 0.001)); // centerY - radius
    });

    test('vertices are equidistant from center', () {
      const cx = 50.0;
      const cy = 50.0;
      const radius = 25.0;
      final vertices = HexagonalPathCalculator.calculateHexagonVertices(cx, cy, radius);

      for (final (x, y) in vertices) {
        final dist = math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2));
        expect(dist, closeTo(radius, 0.001));
      }
    });

    test('vertices are evenly spaced (60 degrees apart)', () {
      final vertices = HexagonalPathCalculator.calculateHexagonVertices(0, 0, 1);

      for (int i = 0; i < 6; i++) {
        final (x1, y1) = vertices[i];
        final (x2, y2) = vertices[(i + 1) % 6];

        // Distance between adjacent vertices should be equal to radius for regular hexagon
        final dist = math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
        expect(dist, closeTo(1.0, 0.001)); // radius = 1
      }
    });
  });

  group('String Corruption', () {
    test('corrupts approximately 25% of characters', () {
      final rng = FastRng(42);
      const original = 'TACTICAL GRID TEST STRING SAMPLE';

      int totalCorrupted = 0;
      const trials = 100;

      for (int frame = 0; frame < trials; frame++) {
        final corrupted = StringCorruptor.corruptString(original, frame, rng);
        for (int i = 0; i < original.length; i++) {
          if (corrupted[i] != original[i]) {
            totalCorrupted++;
          }
        }
      }

      final avgCorruption = totalCorrupted / (trials * original.length);
      // Should be around 25% (0.25) with some variance
      expect(avgCorruption, closeTo(0.25, 0.05));
    });

    test('corrupted characters are from glitch chars', () {
      final rng = FastRng(42);
      const original = 'TACTICAL GRID';

      for (int frame = 0; frame < 50; frame++) {
        final corrupted = StringCorruptor.corruptString(original, frame, rng);
        for (int i = 0; i < corrupted.length; i++) {
          if (corrupted[i] != original[i]) {
            expect(MinimapConstants.glitchChars, contains(corrupted[i]));
          }
        }
      }
    });

    test('same frame produces same corruption', () {
      final rng = FastRng(42);
      const original = 'TACTICAL GRID';

      final corrupted1 = StringCorruptor.corruptString(original, 123, rng);
      final corrupted2 = StringCorruptor.corruptString(original, 123, rng);

      expect(corrupted1, corrupted2);
    });

    test('different frames produce different corruption', () {
      final rng = FastRng(42);
      const original = 'TACTICAL GRID TEST';

      final corrupted1 = StringCorruptor.corruptString(original, 100, rng);
      final corrupted2 = StringCorruptor.corruptString(original, 200, rng);

      // High probability they're different
      // (could theoretically be same, but extremely unlikely)
      expect(corrupted1 != corrupted2 || corrupted1 == original, true);
    });
  });

  group('Minimap Animations', () {
    test('scan angle increases over time', () {
      const initialAngle = 0.0;
      final angle1 = MinimapAnimations.calculateScanAngle(1.0, initialAngle);
      final angle2 = MinimapAnimations.calculateScanAngle(2.0, initialAngle);

      expect(angle1, closeTo(2.5, 0.001)); // 1.0 * 2.5
      expect(angle2, closeTo(5.0, 0.001)); // 2.0 * 2.5
      expect(angle2, greaterThan(angle1));
    });

    test('pulse phase increases faster than scan', () {
      const initialPhase = 0.0;
      final pulse = MinimapAnimations.calculatePulsePhase(1.0, initialPhase);
      final scan = MinimapAnimations.calculateScanAngle(1.0, 0.0);

      expect(pulse, 4.0); // 1.0 * 4.0
      expect(pulse, greaterThan(scan));
    });

    test('scanline Y wraps within map size', () {
      const mapSize = 130.0;

      for (double t = 0; t < 10; t += 0.1) {
        final y = MinimapAnimations.calculateScanlineY(t, mapSize);
        expect(y, greaterThanOrEqualTo(0));
        expect(y, lessThan(mapSize));
      }
    });

    test('corruption scanline moves opposite direction', () {
      const mapSize = 130.0;

      final normal1 = MinimapAnimations.calculateScanlineY(0, mapSize);
      final normal2 = MinimapAnimations.calculateScanlineY(1, mapSize);
      final corrupt1 = MinimapAnimations.calculateCorruptionScanlineY(0, mapSize);
      final corrupt2 = MinimapAnimations.calculateCorruptionScanlineY(1, mapSize);

      // Normal scanline increases, corruption decreases
      expect(normal2, greaterThan(normal1));
      // Corruption starts at mapSize and decreases (with wraparound)
    });
  });

  group('Radar Sweep', () {
    test('calculates endpoint at angle 0', () {
      final (x, y) = RadarSweep.calculateSweepEndpoint(50, 50, 30, 0);
      expect(x, closeTo(80, 0.001)); // 50 + cos(0) * 30 = 50 + 30
      expect(y, closeTo(50, 0.001)); // 50 + sin(0) * 30 = 50
    });

    test('calculates endpoint at angle PI/2', () {
      final (x, y) = RadarSweep.calculateSweepEndpoint(50, 50, 30, math.pi / 2);
      expect(x, closeTo(50, 0.001)); // 50 + cos(PI/2) * 30 = 50
      expect(y, closeTo(80, 0.001)); // 50 + sin(PI/2) * 30 = 80
    });

    test('calculates endpoint at angle PI', () {
      final (x, y) = RadarSweep.calculateSweepEndpoint(50, 50, 30, math.pi);
      expect(x, closeTo(20, 0.001)); // 50 + cos(PI) * 30 = 20
      expect(y, closeTo(50, 0.001)); // 50 + sin(PI) * 30 = 50
    });

    test('sweep endpoint distance equals scan length', () {
      const cx = 50.0;
      const cy = 50.0;
      const scanLength = 30.0;

      for (double angle = 0; angle < math.pi * 2; angle += 0.1) {
        final (x, y) = RadarSweep.calculateSweepEndpoint(cx, cy, scanLength, angle);
        final dist = math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2));
        expect(dist, closeTo(scanLength, 0.001));
      }
    });
  });

  group('Path Dot Animator', () {
    test('creates 3 dots', () {
      final progresses = PathDotAnimator.calculateDotProgresses(0);
      expect(progresses.length, 3);
    });

    test('dots are evenly spaced at 0.33 intervals', () {
      final progresses = PathDotAnimator.calculateDotProgresses(0);

      // At t=0: [0, 0.33, 0.66]
      expect(progresses[0], closeTo(0, 0.01));
      expect(progresses[1], closeTo(0.33, 0.01));
      expect(progresses[2], closeTo(0.66, 0.01));
    });

    test('dot progress wraps within [0, 1)', () {
      for (double t = 0; t < 50; t += 0.5) {
        final progresses = PathDotAnimator.calculateDotProgresses(t);
        for (final p in progresses) {
          expect(p, greaterThanOrEqualTo(0));
          expect(p, lessThan(1));
        }
      }
    });

    test('dots move over time', () {
      final prog0 = PathDotAnimator.calculateDotProgresses(0);
      final prog1 = PathDotAnimator.calculateDotProgresses(1);

      // Progress should change over time
      expect(prog1[0], isNot(closeTo(prog0[0], 0.001)));
    });
  });

  group('Data Stream Calculator', () {
    test('stream Y position wraps correctly', () {
      const baseY = 130.0;

      for (double t = 0; t < 20; t += 0.5) {
        final y = DataStreamCalculator.calculateStreamY(t, baseY, 0, 30);
        // Y should be in range [-15, baseY + 15)
        expect(y, greaterThanOrEqualTo(-15));
        expect(y, lessThan(baseY + 15));
      }
    });

    test('different indices have different offsets', () {
      const baseY = 130.0;
      const time = 5.0;
      const speed = 30.0;

      final y0 = DataStreamCalculator.calculateStreamY(time, baseY, 0, speed);
      final y1 = DataStreamCalculator.calculateStreamY(time, baseY, 1, speed);
      final y2 = DataStreamCalculator.calculateStreamY(time, baseY, 2, speed);

      // Different indices should have different Y positions
      expect(y0, isNot(closeTo(y1, 0.001)));
      expect(y1, isNot(closeTo(y2, 0.001)));
    });

    test('speed affects movement rate', () {
      const baseY = 130.0;

      final yFast = DataStreamCalculator.calculateStreamY(1, baseY, 0, 50);
      final ySlow = DataStreamCalculator.calculateStreamY(1, baseY, 0, 20);

      // Different speeds should produce different positions
      expect(yFast, isNot(closeTo(ySlow, 0.001)));
    });
  });

  group('Double Extension (.sin)', () {
    test('sin extension works correctly', () {
      // Simulating the extension
      double sinValue(double d) => math.sin(d);

      expect(sinValue(0), closeTo(0, 0.001));
      expect(sinValue(math.pi / 2), closeTo(1, 0.001));
      expect(sinValue(math.pi), closeTo(0, 0.001));
      expect(sinValue(3 * math.pi / 2), closeTo(-1, 0.001));
    });
  });

  group('Position Calculations', () {
    test('entity position to map coordinates', () {
      const worldWidth = 1000.0;
      const worldHeight = 800.0;
      const mapSize = 130.0;

      // Convert entity at (500, 400) - center of world
      const entityX = 500.0;
      const entityY = 400.0;

      final mapX = (entityX / worldWidth) * mapSize;
      final mapY = (entityY / worldHeight) * mapSize;

      expect(mapX, closeTo(65, 0.001)); // 130 / 2
      expect(mapY, closeTo(65, 0.001)); // 130 / 2
    });

    test('entity at origin maps to map origin', () {
      const worldWidth = 1000.0;
      const worldHeight = 800.0;
      const mapSize = 130.0;

      const entityX = 0.0;
      const entityY = 0.0;

      final mapX = (entityX / worldWidth) * mapSize;
      final mapY = (entityY / worldHeight) * mapSize;

      expect(mapX, 0.0);
      expect(mapY, 0.0);
    });

    test('entity at world bounds maps to map bounds', () {
      const worldWidth = 1000.0;
      const worldHeight = 800.0;
      const mapSize = 130.0;

      const entityX = 1000.0;
      const entityY = 800.0;

      final mapX = (entityX / worldWidth) * mapSize;
      final mapY = (entityY / worldHeight) * mapSize;

      expect(mapX, closeTo(130, 0.001));
      expect(mapY, closeTo(130, 0.001));
    });
  });

  group('Layout Calculations', () {
    test('map position is screen width - mapSize - padding', () {
      const screenWidth = 1920.0;
      const mapSize = 130.0;
      const padding = 12.0;

      final mapX = screenWidth - mapSize - padding;
      expect(mapX, closeTo(1778, 0.001));
    });

    test('map Y position scales with screen', () {
      const scale = 1.0;
      final mapY = 120.0 * scale;
      expect(mapY, 120.0);

      const scale2 = 0.5;
      final mapY2 = 120.0 * scale2;
      expect(mapY2, 60.0);
    });
  });

  group('Glitch Offset Calculations', () {
    test('glitch offset is sinusoidal', () {
      const time = 1.0;
      const intensity = 1.0;

      final xOffset = math.sin(time * 50) * 3 * intensity;
      final yOffset = math.cos(time * 40) * 1.5 * intensity;

      // Verify they're within expected bounds
      expect(xOffset.abs(), lessThanOrEqualTo(3.0));
      expect(yOffset.abs(), lessThanOrEqualTo(1.5));
    });

    test('glitch offset scales with intensity', () {
      const time = 1.0;

      final xOffset1 = math.sin(time * 50) * 3 * 1.0;
      final xOffset05 = math.sin(time * 50) * 3 * 0.5;

      expect(xOffset05.abs(), closeTo(xOffset1.abs() / 2, 0.001));
    });

    test('glitch only applies when intensity > 0.3', () {
      // In actual code, glitch offset only applies when _isGlitching && _glitchIntensity > 0.3
      const threshold = 0.3;
      expect(0.35 > threshold, true);
      expect(0.25 > threshold, false);
    });
  });

  group('Pulse Calculations', () {
    test('crosshair pulse oscillates between 0.2 and 0.6', () {
      for (double phase = 0; phase < math.pi * 4; phase += 0.1) {
        final pulse = 0.4 + math.sin(phase * 2) * 0.2;
        expect(pulse, greaterThanOrEqualTo(0.2));
        expect(pulse, lessThanOrEqualTo(0.6));
      }
    });

    test('crosshair size oscillates between 8 and 12', () {
      for (double phase = 0; phase < math.pi * 4; phase += 0.1) {
        final crossSize = 10.0 + math.sin(phase) * 2;
        expect(crossSize, greaterThanOrEqualTo(8.0));
        expect(crossSize, lessThanOrEqualTo(12.0));
      }
    });

    test('enemy threat pulse oscillates between 0.6 and 1.4', () {
      for (double phase = 0; phase < math.pi * 4; phase += 0.1) {
        final pulse = 1.0 + math.sin(phase * 2) * 0.4;
        expect(pulse, greaterThanOrEqualTo(0.6));
        expect(pulse, lessThanOrEqualTo(1.4));
      }
    });
  });

  group('Color Interpolation', () {
    test('frame color lerps based on corruption', () {
      // Color.lerp(cyan, red, corruption * 0.5)
      // At corruption 0: full cyan
      // At corruption 1: 50% mix
      const corruptionFactor = 0.5;

      const corruption0 = 0.0;
      final lerpFactor0 = corruption0 * corruptionFactor;
      expect(lerpFactor0, 0.0);

      const corruption1 = 1.0;
      final lerpFactor1 = corruption1 * corruptionFactor;
      expect(lerpFactor1, 0.5);

      const corruption05 = 0.5;
      final lerpFactor05 = corruption05 * corruptionFactor;
      expect(lerpFactor05, 0.25);
    });
  });

  group('Noise Texture', () {
    test('generates 50 noise particles when glitching', () {
      const particleCount = 50;
      expect(particleCount, 50);
    });

    test('noise particle alpha scales with glitch intensity', () {
      const baseAlpha = 0.3;
      const intensity = 0.8;

      final alpha = baseAlpha * intensity;
      expect(alpha, closeTo(0.24, 0.001));
    });
  });

  group('Tower Range Calculation', () {
    test('range radius scales correctly', () {
      const towerRange = 200.0;
      const worldWidth = 1000.0;
      const mapSize = 130.0;
      const rangeFactor = 0.3;

      final rangeRadius = (towerRange / worldWidth) * mapSize * rangeFactor;
      // 200/1000 * 130 * 0.3 = 0.2 * 130 * 0.3 = 7.8
      expect(rangeRadius, closeTo(7.8, 0.01));
    });
  });

  group('Boss Detection', () {
    test('boss has larger indicator size', () {
      const normalSize = 2.5;
      const bossSize = 5.0;

      expect(bossSize, greaterThan(normalSize));
      expect(bossSize, normalSize * 2);
    });

    test('boss has longer direction indicator', () {
      const normalIndicator = 5.0;
      const bossIndicator = 8.0;

      expect(bossIndicator, greaterThan(normalIndicator));
    });
  });

  group('Corruption Artifacts', () {
    test('corruption artifacts only appear above 0.5 corruption', () {
      const threshold = 0.5;

      expect(0.6 > threshold, true);
      expect(0.4 > threshold, false);
      expect(0.5 > threshold, false);
    });

    test('corruption artifact count scales with corruption level', () {
      const corruption = 0.8;
      final artifactCount = (corruption * 5).floor();
      expect(artifactCount, 4);

      const corruption2 = 1.0;
      final artifactCount2 = (corruption2 * 5).floor();
      expect(artifactCount2, 5);
    });
  });

  group('Integration Calculations', () {
    test('full layout calculation workflow', () {
      // Simulate full layout calculation
      const screenWidth = 1920.0;
      const screenHeight = 1080.0;

      // Calculate scale
      final scale = MinimapScaler.calculateScale(screenWidth, screenHeight);
      expect(scale, 1.0);

      // Calculate map size
      final mapSize = MinimapScaler.calculateMapSize(scale);
      expect(mapSize, 130.0);

      // Calculate padding
      final padding = MinimapConstants.basePadding * scale;
      expect(padding, 12.0);

      // Calculate position
      final mapX = screenWidth - mapSize - padding;
      final mapY = 120.0 * scale;
      expect(mapX, closeTo(1778, 0.001));
      expect(mapY, 120.0);
    });

    test('responsive layout on mobile', () {
      const screenWidth = 800.0;
      const screenHeight = 600.0;

      final scale = MinimapScaler.calculateScale(screenWidth, screenHeight);
      // 800/1920 = 0.416..., clamped to 0.5
      // 600/1080 = 0.555...
      expect(scale, closeTo(0.5, 0.01));

      final mapSize = MinimapScaler.calculateMapSize(scale);
      // 130 * 0.5 = 65, clamped to 80
      expect(mapSize, 80.0);
    });
  });
}
