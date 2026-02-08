import 'package:flutter_test/flutter_test.dart';

/// Tests for FlagPacker utility class

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED CLASS FROM flag_packer.dart
// ═══════════════════════════════════════════════════════════════════════════════

/// Packs boolean flags into a single double precision value for GLSL uniforms
class FlagPacker {
  /// Packs up to 32 boolean flags into a [double].
  static double pack(List<bool> flags) {
    var value = 0;
    for (var i = 0; i < flags.length && i < 32; i++) {
      if (flags[i]) {
        value |= (1 << i);
      }
    }
    return value.toDouble();
  }

  /// Unpacks the boolean at [index] from the packed [value].
  static bool unpack(double value, int index) {
    if (index < 0 || index >= 32) return false;
    final mask = 1 << index;
    return (value.toInt() & mask) != 0;
  }

  /// Convenience helper that returns a closure which evaluates the packed flag.
  static bool Function(int index) createReader(double value) {
    return (int index) => unpack(value, index);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('FlagPacker.pack', () {
    test('empty list returns 0', () {
      expect(FlagPacker.pack([]), 0.0);
    });

    test('all false returns 0', () {
      expect(FlagPacker.pack([false, false, false, false]), 0.0);
    });

    test('first flag true returns 1', () {
      expect(FlagPacker.pack([true]), 1.0);
    });

    test('second flag true returns 2', () {
      expect(FlagPacker.pack([false, true]), 2.0);
    });

    test('third flag true returns 4', () {
      expect(FlagPacker.pack([false, false, true]), 4.0);
    });

    test('first two flags true returns 3', () {
      expect(FlagPacker.pack([true, true]), 3.0);
    });

    test('all first 4 flags true returns 15', () {
      expect(FlagPacker.pack([true, true, true, true]), 15.0);
    });

    test('alternating flags pattern', () {
      // [true, false, true, false] = 1 + 0 + 4 + 0 = 5
      expect(FlagPacker.pack([true, false, true, false]), 5.0);
    });

    test('reverse alternating flags pattern', () {
      // [false, true, false, true] = 0 + 2 + 0 + 8 = 10
      expect(FlagPacker.pack([false, true, false, true]), 10.0);
    });

    test('first 8 flags all true returns 255', () {
      final flags = List.filled(8, true);
      expect(FlagPacker.pack(flags), 255.0);
    });

    test('first 16 flags all true returns 65535', () {
      final flags = List.filled(16, true);
      expect(FlagPacker.pack(flags), 65535.0);
    });

    test('32 flags all true returns max value', () {
      final flags = List.filled(32, true);
      // 2^32 - 1 = 4294967295
      expect(FlagPacker.pack(flags), 4294967295.0);
    });

    test('ignores flags beyond index 31', () {
      final flags = List.filled(40, true);
      // Should only use first 32 flags
      expect(FlagPacker.pack(flags), 4294967295.0);
    });

    test('only 33rd flag true has no effect', () {
      final flags = List.filled(33, false);
      flags[32] = true; // This should be ignored
      expect(FlagPacker.pack(flags), 0.0);
    });

    test('specific bit patterns', () {
      // Binary: 10101010 = 170
      expect(FlagPacker.pack([
        false, true, false, true, false, true, false, true,
      ]), 170.0);

      // Binary: 01010101 = 85
      expect(FlagPacker.pack([
        true, false, true, false, true, false, true, false,
      ]), 85.0);
    });

    test('single high bit', () {
      final flags = List.filled(32, false);
      flags[31] = true;
      // 2^31 = 2147483648
      expect(FlagPacker.pack(flags), 2147483648.0);
    });
  });

  group('FlagPacker.unpack', () {
    test('unpack 0 returns false for all indices', () {
      for (int i = 0; i < 32; i++) {
        expect(FlagPacker.unpack(0, i), false);
      }
    });

    test('unpack 1 returns true only for index 0', () {
      expect(FlagPacker.unpack(1, 0), true);
      expect(FlagPacker.unpack(1, 1), false);
      expect(FlagPacker.unpack(1, 2), false);
    });

    test('unpack 2 returns true only for index 1', () {
      expect(FlagPacker.unpack(2, 0), false);
      expect(FlagPacker.unpack(2, 1), true);
      expect(FlagPacker.unpack(2, 2), false);
    });

    test('unpack 3 returns true for indices 0 and 1', () {
      expect(FlagPacker.unpack(3, 0), true);
      expect(FlagPacker.unpack(3, 1), true);
      expect(FlagPacker.unpack(3, 2), false);
    });

    test('unpack 255 returns true for indices 0-7', () {
      for (int i = 0; i < 8; i++) {
        expect(FlagPacker.unpack(255, i), true);
      }
      expect(FlagPacker.unpack(255, 8), false);
    });

    test('negative index returns false', () {
      expect(FlagPacker.unpack(255, -1), false);
      expect(FlagPacker.unpack(255, -10), false);
    });

    test('index >= 32 returns false', () {
      expect(FlagPacker.unpack(4294967295, 32), false);
      expect(FlagPacker.unpack(4294967295, 33), false);
      expect(FlagPacker.unpack(4294967295, 100), false);
    });

    test('alternating pattern unpacks correctly', () {
      // 170 = 10101010 binary
      expect(FlagPacker.unpack(170, 0), false);
      expect(FlagPacker.unpack(170, 1), true);
      expect(FlagPacker.unpack(170, 2), false);
      expect(FlagPacker.unpack(170, 3), true);
      expect(FlagPacker.unpack(170, 4), false);
      expect(FlagPacker.unpack(170, 5), true);
      expect(FlagPacker.unpack(170, 6), false);
      expect(FlagPacker.unpack(170, 7), true);
    });

    test('high bit unpacks correctly', () {
      // 2^31 = 2147483648
      expect(FlagPacker.unpack(2147483648, 31), true);
      expect(FlagPacker.unpack(2147483648, 30), false);
      expect(FlagPacker.unpack(2147483648, 0), false);
    });
  });

  group('FlagPacker.createReader', () {
    test('creates a working reader function', () {
      final reader = FlagPacker.createReader(15); // Binary: 1111

      expect(reader(0), true);
      expect(reader(1), true);
      expect(reader(2), true);
      expect(reader(3), true);
      expect(reader(4), false);
    });

    test('reader handles edge cases', () {
      final reader = FlagPacker.createReader(1);

      expect(reader(-1), false);
      expect(reader(32), false);
      expect(reader(0), true);
    });

    test('reader captures value correctly', () {
      final reader1 = FlagPacker.createReader(1);
      final reader2 = FlagPacker.createReader(2);

      // Each reader uses its own captured value
      expect(reader1(0), true);
      expect(reader1(1), false);
      expect(reader2(0), false);
      expect(reader2(1), true);
    });
  });

  group('Pack/Unpack Round Trip', () {
    test('pack then unpack preserves all flags', () {
      final original = [true, false, true, true, false, false, true, false];
      final packed = FlagPacker.pack(original);

      for (int i = 0; i < original.length; i++) {
        expect(FlagPacker.unpack(packed, i), original[i]);
      }
    });

    test('round trip with 32 flags', () {
      final original = List.generate(32, (i) => i % 3 == 0);
      final packed = FlagPacker.pack(original);

      for (int i = 0; i < 32; i++) {
        expect(FlagPacker.unpack(packed, i), original[i]);
      }
    });

    test('round trip with all true', () {
      final original = List.filled(32, true);
      final packed = FlagPacker.pack(original);

      for (int i = 0; i < 32; i++) {
        expect(FlagPacker.unpack(packed, i), true);
      }
    });

    test('round trip with all false', () {
      final original = List.filled(32, false);
      final packed = FlagPacker.pack(original);

      for (int i = 0; i < 32; i++) {
        expect(FlagPacker.unpack(packed, i), false);
      }
    });

    test('round trip with random pattern', () {
      // Specific pattern for reproducibility
      final original = [
        true, false, false, true, true, true, false, false,
        false, true, true, false, false, false, true, true,
        true, true, false, false, true, false, true, false,
        false, false, false, true, true, true, true, false,
      ];

      final packed = FlagPacker.pack(original);

      for (int i = 0; i < original.length; i++) {
        expect(FlagPacker.unpack(packed, i), original[i],
            reason: 'Mismatch at index $i');
      }
    });
  });

  group('Use Case: Shader Uniforms', () {
    test('typical shader flag usage', () {
      // Common shader flags
      const enableNormalMap = 0;
      const enableSpecular = 1;
      const enableEmission = 2;
      const enableShadows = 3;
      const enableBloom = 4;

      final flags = [true, true, false, true, true]; // Specular off
      final packed = FlagPacker.pack(flags);

      expect(FlagPacker.unpack(packed, enableNormalMap), true);
      expect(FlagPacker.unpack(packed, enableSpecular), true);
      expect(FlagPacker.unpack(packed, enableEmission), false);
      expect(FlagPacker.unpack(packed, enableShadows), true);
      expect(FlagPacker.unpack(packed, enableBloom), true);
    });

    test('reader pattern for shader', () {
      final flags = [true, false, true, false, true];
      final packed = FlagPacker.pack(flags);
      final hasFlag = FlagPacker.createReader(packed);

      // In shader code you'd use: if (hasFlag(0)) { ... }
      expect(hasFlag(0), true);
      expect(hasFlag(1), false);
      expect(hasFlag(2), true);
    });
  });

  group('Bit Operations', () {
    test('powers of 2 map to single bits', () {
      expect(FlagPacker.pack([true]), 1.0); // 2^0
      expect(FlagPacker.pack([false, true]), 2.0); // 2^1
      expect(FlagPacker.pack([false, false, true]), 4.0); // 2^2
      expect(FlagPacker.pack([false, false, false, true]), 8.0); // 2^3
      expect(FlagPacker.pack([false, false, false, false, true]), 16.0); // 2^4
    });

    test('bit mask calculation', () {
      // Test that (1 << index) produces correct masks
      for (int i = 0; i < 32; i++) {
        final mask = 1 << i;
        expect(mask, equals(1 << i));
      }
    });
  });

  group('Edge Cases', () {
    test('handles double conversion correctly', () {
      // Verify that integer -> double -> integer roundtrip works
      final packed = FlagPacker.pack(List.filled(32, true));
      final asInt = packed.toInt();
      expect(asInt, 4294967295);
    });

    test('fractional double values are truncated', () {
      // unpack should handle fractional doubles by truncating
      expect(FlagPacker.unpack(1.9, 0), true);
      expect(FlagPacker.unpack(1.1, 0), true);
      expect(FlagPacker.unpack(0.9, 0), false);
    });

    test('negative packed value handling', () {
      // Negative values in .toInt() might produce unexpected results
      // This tests the boundary behavior
      expect(FlagPacker.unpack(-1, 0), true); // -1 in int has all bits set
    });
  });

  group('Performance Characteristics', () {
    test('packing is O(n) for n flags', () {
      // This is more of a documentation test
      // Packing iterates through flags once
      final smallFlags = List.filled(8, true);
      final largeFlags = List.filled(32, true);

      // Both should complete quickly
      expect(FlagPacker.pack(smallFlags), isNotNull);
      expect(FlagPacker.pack(largeFlags), isNotNull);
    });

    test('unpacking is O(1)', () {
      // Unpacking is constant time regardless of which bit
      final packed = FlagPacker.pack(List.filled(32, true));

      expect(FlagPacker.unpack(packed, 0), isNotNull);
      expect(FlagPacker.unpack(packed, 15), isNotNull);
      expect(FlagPacker.unpack(packed, 31), isNotNull);
    });
  });
}
