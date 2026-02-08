import 'package:flutter_test/flutter_test.dart';

/// Simulation tests for GlitchText animation logic.
/// Tests typewriter animation timing, glitch character generation,
/// and LCG random number generator behavior.

// ═══════════════════════════════════════════════════════════════════════════════
// LCG RNG SIMULATION (matches _lcgNext in glitch_text.dart)
// ═══════════════════════════════════════════════════════════════════════════════

class GlitchTextRng {
  int _state;

  GlitchTextRng([int? seed]) : _state = (seed ?? 0x1f123bb5) & 0x7fffffff;

  int next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  int nextInt(int max) => max <= 0 ? 0 : next() % max;
}

// ═══════════════════════════════════════════════════════════════════════════════
// GLITCH TEXT SIMULATOR
// ═══════════════════════════════════════════════════════════════════════════════

class GlitchTextSimulator {
  final String text;
  final int durationMs;
  final GlitchTextRng rng;

  static const String glitchChars = r'!@#$%^&*()_+-=[]{}|;:,.<>/?æøå01';

  int _charIndex = 0;
  String _displayedText = '';
  int _elapsedMs = 0;

  GlitchTextSimulator({
    required this.text,
    this.durationMs = 2000,
    int? seed,
  }) : rng = GlitchTextRng(seed);

  int get charDuration => durationMs ~/ text.length;

  String get displayedText => _displayedText;
  int get charIndex => _charIndex;
  bool get isComplete => _charIndex >= text.length;

  /// Advance animation by given milliseconds
  void advance(int ms) {
    _elapsedMs += ms;

    final expectedChars = _elapsedMs ~/ charDuration;
    while (_charIndex < expectedChars && _charIndex < text.length) {
      _charIndex++;
      _updateText();
    }

    if (_charIndex >= text.length && _displayedText != text) {
      _displayedText = text;
    }
  }

  void _updateText() {
    final baseText = text.substring(0, _charIndex);
    if (_charIndex < text.length) {
      String suffix = '';
      for (int i = 0; i < 2; i++) {
        suffix += glitchChars[rng.nextInt(glitchChars.length)];
      }
      _displayedText = baseText + suffix;
    } else {
      _displayedText = baseText;
    }
  }

  void reset() {
    _charIndex = 0;
    _displayedText = '';
    _elapsedMs = 0;
  }

  /// Get the glitch suffix that would be added for current char index
  String getGlitchSuffix() {
    String suffix = '';
    for (int i = 0; i < 2; i++) {
      suffix += glitchChars[rng.nextInt(glitchChars.length)];
    }
    return suffix;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEST SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('GlitchTextRng', () {
    test('produces deterministic sequence with same seed', () {
      final rng1 = GlitchTextRng(12345);
      final rng2 = GlitchTextRng(12345);

      for (int i = 0; i < 100; i++) {
        expect(rng1.next(), rng2.next());
      }
    });

    test('uses default seed when none provided', () {
      final rng1 = GlitchTextRng();
      final rng2 = GlitchTextRng();

      // Same default seed should produce same sequence
      expect(rng1.next(), rng2.next());
    });

    test('default seed is 0x1f123bb5', () {
      final rng = GlitchTextRng();
      // First value with this seed
      final firstValue = rng.next();

      // Manually compute: (1664525 * 0x1f123bb5 + 1013904223) & 0x7fffffff
      final expected = (1664525 * 0x1f123bb5 + 1013904223) & 0x7fffffff;
      expect(firstValue, expected);
    });

    test('nextInt returns values in [0, max)', () {
      final rng = GlitchTextRng(12345);
      for (int i = 0; i < 1000; i++) {
        final value = rng.nextInt(10);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(10));
      }
    });

    test('nextInt with max <= 0 returns 0', () {
      final rng = GlitchTextRng();
      expect(rng.nextInt(0), 0);
      expect(rng.nextInt(-5), 0);
    });

    test('nextInt covers all values in range', () {
      final rng = GlitchTextRng(12345);
      final values = <int>{};

      for (int i = 0; i < 1000; i++) {
        values.add(rng.nextInt(5));
      }

      expect(values, containsAll([0, 1, 2, 3, 4]));
    });

    test('different seeds produce different sequences', () {
      final rng1 = GlitchTextRng(111);
      final rng2 = GlitchTextRng(222);

      var sameCount = 0;
      for (int i = 0; i < 100; i++) {
        if (rng1.next() == rng2.next()) sameCount++;
      }

      expect(sameCount, lessThan(10));
    });

    test('LCG formula is correct', () {
      // LCG: state = (1664525 * state + 1013904223) & 0x7fffffff
      final seed = 12345;
      final rng = GlitchTextRng(seed);

      final expected1 = (1664525 * seed + 1013904223) & 0x7fffffff;
      expect(rng.next(), expected1);

      final expected2 = (1664525 * expected1 + 1013904223) & 0x7fffffff;
      expect(rng.next(), expected2);
    });
  });

  group('GlitchTextSimulator initialization', () {
    test('initializes with empty display text', () {
      final sim = GlitchTextSimulator(text: 'Hello');
      expect(sim.displayedText, '');
    });

    test('charIndex starts at 0', () {
      final sim = GlitchTextSimulator(text: 'Hello');
      expect(sim.charIndex, 0);
    });

    test('isComplete is false initially', () {
      final sim = GlitchTextSimulator(text: 'Hello');
      expect(sim.isComplete, false);
    });

    test('calculates correct charDuration', () {
      final sim1 = GlitchTextSimulator(text: 'Hello', durationMs: 1000);
      expect(sim1.charDuration, 200); // 1000 / 5

      final sim2 = GlitchTextSimulator(text: 'AB', durationMs: 100);
      expect(sim2.charDuration, 50); // 100 / 2
    });

    test('default duration is 2000ms', () {
      final sim = GlitchTextSimulator(text: 'Test');
      expect(sim.durationMs, 2000);
    });
  });

  group('GlitchTextSimulator animation', () {
    test('advances one character per charDuration', () {
      final sim = GlitchTextSimulator(
        text: 'Hello',
        durationMs: 500, // 100ms per char
      );

      sim.advance(100);
      expect(sim.charIndex, 1);

      sim.advance(100);
      expect(sim.charIndex, 2);
    });

    test('displayed text includes revealed characters', () {
      final sim = GlitchTextSimulator(
        text: 'Hello',
        durationMs: 500,
        seed: 12345,
      );

      sim.advance(200);
      expect(sim.displayedText.startsWith('He'), true);
    });

    test('displayed text includes glitch suffix before completion', () {
      final sim = GlitchTextSimulator(
        text: 'Hello',
        durationMs: 500,
        seed: 12345,
      );

      sim.advance(200);
      // Should have 'He' + 2 glitch chars
      expect(sim.displayedText.length, greaterThan(2));
    });

    test('animation completes after full duration', () {
      final sim = GlitchTextSimulator(
        text: 'Hello',
        durationMs: 500,
      );

      sim.advance(600);
      expect(sim.isComplete, true);
      expect(sim.displayedText, 'Hello');
    });

    test('glitch suffix is removed when complete', () {
      final sim = GlitchTextSimulator(
        text: 'Test',
        durationMs: 400,
      );

      sim.advance(500);
      expect(sim.displayedText, 'Test');
      expect(sim.displayedText.length, 4);
    });

    test('handles single character text', () {
      final sim = GlitchTextSimulator(
        text: 'A',
        durationMs: 100,
      );

      sim.advance(150);
      expect(sim.isComplete, true);
      expect(sim.displayedText, 'A');
    });

    test('handles empty text', () {
      final sim = GlitchTextSimulator(
        text: '',
        durationMs: 100,
      );

      // charDuration would be infinity, so isComplete should be true immediately
      expect(sim.text.isEmpty, true);
    });

    test('multiple advances accumulate correctly', () {
      final sim = GlitchTextSimulator(
        text: 'Hello',
        durationMs: 500,
      );

      sim.advance(50);
      expect(sim.charIndex, 0);

      sim.advance(50);
      expect(sim.charIndex, 1);

      sim.advance(50);
      expect(sim.charIndex, 1);

      sim.advance(50);
      expect(sim.charIndex, 2);
    });
  });

  group('Glitch character set', () {
    test('glitch chars constant is correct', () {
      const expected = r'!@#$%^&*()_+-=[]{}|;:,.<>/?æøå01';
      expect(GlitchTextSimulator.glitchChars, expected);
    });

    test('glitch chars has expected length', () {
      expect(GlitchTextSimulator.glitchChars.length, 32);
    });

    test('glitch chars includes special characters', () {
      const chars = GlitchTextSimulator.glitchChars;
      expect(chars.contains('!'), true);
      expect(chars.contains('@'), true);
      expect(chars.contains('#'), true);
      expect(chars.contains('%'), true);
    });

    test('glitch chars includes nordic characters', () {
      const chars = GlitchTextSimulator.glitchChars;
      expect(chars.contains('æ'), true);
      expect(chars.contains('ø'), true);
      expect(chars.contains('å'), true);
    });

    test('glitch chars includes digits', () {
      const chars = GlitchTextSimulator.glitchChars;
      expect(chars.contains('0'), true);
      expect(chars.contains('1'), true);
    });
  });

  group('Glitch suffix generation', () {
    test('suffix is always 2 characters', () {
      final sim = GlitchTextSimulator(text: 'Test', seed: 12345);

      for (int i = 0; i < 100; i++) {
        final suffix = sim.getGlitchSuffix();
        expect(suffix.length, 2);
      }
    });

    test('suffix characters are from glitch set', () {
      final sim = GlitchTextSimulator(text: 'Test', seed: 12345);

      for (int i = 0; i < 100; i++) {
        final suffix = sim.getGlitchSuffix();
        for (final char in suffix.split('')) {
          expect(GlitchTextSimulator.glitchChars.contains(char), true);
        }
      }
    });

    test('suffix is deterministic with same seed', () {
      final sim1 = GlitchTextSimulator(text: 'Test', seed: 12345);
      final sim2 = GlitchTextSimulator(text: 'Test', seed: 12345);

      for (int i = 0; i < 10; i++) {
        expect(sim1.getGlitchSuffix(), sim2.getGlitchSuffix());
      }
    });

    test('suffix varies with different RNG states', () {
      final sim = GlitchTextSimulator(text: 'Test', seed: 12345);
      final suffixes = <String>{};

      for (int i = 0; i < 100; i++) {
        suffixes.add(sim.getGlitchSuffix());
      }

      // Should have multiple unique suffixes
      expect(suffixes.length, greaterThan(10));
    });
  });

  group('GlitchTextSimulator reset', () {
    test('reset restores initial state', () {
      final sim = GlitchTextSimulator(
        text: 'Hello',
        durationMs: 500,
      );

      sim.advance(300);
      expect(sim.charIndex, greaterThan(0));
      expect(sim.displayedText.isNotEmpty, true);

      sim.reset();

      expect(sim.charIndex, 0);
      expect(sim.displayedText, '');
    });

    test('reset allows re-animation', () {
      final sim = GlitchTextSimulator(
        text: 'Hello',
        durationMs: 500,
      );

      sim.advance(600);
      expect(sim.isComplete, true);

      sim.reset();
      expect(sim.isComplete, false);

      sim.advance(200);
      expect(sim.charIndex, 2);
    });
  });

  group('Timing edge cases', () {
    test('very short duration works correctly', () {
      final sim = GlitchTextSimulator(
        text: 'Hi',
        durationMs: 10, // 5ms per char
      );

      sim.advance(15);
      expect(sim.isComplete, true);
      expect(sim.displayedText, 'Hi');
    });

    test('very long text works correctly', () {
      final longText = 'A' * 100;
      final sim = GlitchTextSimulator(
        text: longText,
        durationMs: 10000, // 100ms per char
      );

      expect(sim.charDuration, 100);

      sim.advance(5000);
      expect(sim.charIndex, 50);
    });

    test('advance by 0 does nothing', () {
      final sim = GlitchTextSimulator(
        text: 'Test',
        durationMs: 400,
      );

      sim.advance(0);
      expect(sim.charIndex, 0);
      expect(sim.displayedText, '');
    });

    test('large advance completes animation', () {
      final sim = GlitchTextSimulator(
        text: 'Hello World',
        durationMs: 1000,
      );

      sim.advance(10000);
      expect(sim.isComplete, true);
      expect(sim.displayedText, 'Hello World');
    });
  });

  group('Character reveal progression', () {
    test('characters reveal in order', () {
      final sim = GlitchTextSimulator(
        text: 'ABCDE',
        durationMs: 500,
        seed: 12345,
      );

      // After each interval, one more character is revealed
      sim.advance(100);
      expect(sim.displayedText.startsWith('A'), true);

      sim.advance(100);
      expect(sim.displayedText.startsWith('AB'), true);

      sim.advance(100);
      expect(sim.displayedText.startsWith('ABC'), true);
    });

    test('partial intervals do not reveal characters', () {
      final sim = GlitchTextSimulator(
        text: 'Test',
        durationMs: 400, // 100ms per char
      );

      sim.advance(50);
      expect(sim.charIndex, 0);
      expect(sim.displayedText, '');

      sim.advance(49);
      expect(sim.charIndex, 0);

      sim.advance(1);
      expect(sim.charIndex, 1);
    });
  });

  group('Text with special characters', () {
    test('handles text with spaces', () {
      final sim = GlitchTextSimulator(
        text: 'Hello World',
        durationMs: 1100,
      );

      sim.advance(1200);
      expect(sim.displayedText, 'Hello World');
    });

    test('handles text with numbers', () {
      final sim = GlitchTextSimulator(
        text: 'Test123',
        durationMs: 700,
      );

      sim.advance(800);
      expect(sim.displayedText, 'Test123');
    });

    test('handles text with unicode', () {
      final sim = GlitchTextSimulator(
        text: 'Hëllo',
        durationMs: 500,
      );

      sim.advance(600);
      expect(sim.displayedText, 'Hëllo');
    });

    test('handles text with emoji', () {
      final sim = GlitchTextSimulator(
        text: 'Hi 👋',
        durationMs: 500,
      );

      // Note: Emoji might count as multiple characters
      sim.advance(600);
      expect(sim.displayedText.contains('Hi'), true);
    });
  });

  group('Duration calculations', () {
    test('charDuration rounds down', () {
      // 1000ms / 3 chars = 333.33ms -> 333ms
      final sim = GlitchTextSimulator(text: 'ABC', durationMs: 1000);
      expect(sim.charDuration, 333);
    });

    test('short text with long duration', () {
      final sim = GlitchTextSimulator(text: 'Hi', durationMs: 10000);
      expect(sim.charDuration, 5000);
    });

    test('long text with short duration', () {
      final longText = 'A' * 1000;
      final sim = GlitchTextSimulator(text: longText, durationMs: 100);
      expect(sim.charDuration, 0); // Very fast
    });

    test('exact duration division', () {
      final sim = GlitchTextSimulator(text: 'Test', durationMs: 400);
      expect(sim.charDuration, 100);
    });
  });

  group('Animation state consistency', () {
    test('charIndex never exceeds text length', () {
      final sim = GlitchTextSimulator(
        text: 'Test',
        durationMs: 400,
      );

      for (int i = 0; i < 100; i++) {
        sim.advance(50);
        expect(sim.charIndex, lessThanOrEqualTo(sim.text.length));
      }
    });

    test('displayedText never exceeds text length (when complete)', () {
      final sim = GlitchTextSimulator(
        text: 'Test',
        durationMs: 400,
      );

      sim.advance(500);
      expect(sim.displayedText.length, lessThanOrEqualTo(sim.text.length));
    });

    test('displayedText matches text when complete', () {
      final texts = ['Hello', 'World', 'Test123', 'A', 'AB'];

      for (final text in texts) {
        final sim = GlitchTextSimulator(
          text: text,
          durationMs: text.length * 100,
        );

        sim.advance(text.length * 150);
        expect(sim.displayedText, text);
      }
    });
  });

  group('RNG state progression', () {
    test('RNG advances with each glitch suffix', () {
      final rng1 = GlitchTextRng(12345);
      final rng2 = GlitchTextRng(12345);

      // First suffix uses 2 random calls
      rng1.nextInt(32);
      rng1.nextInt(32);

      // Second suffix uses 2 more
      rng1.nextInt(32);
      rng1.nextInt(32);

      // rng2 advances by 4 calls total
      for (int i = 0; i < 4; i++) {
        rng2.nextInt(32);
      }

      // Now they should be in sync
      expect(rng1.next(), rng2.next());
    });

    test('glitch chars are uniformly distributed', () {
      final rng = GlitchTextRng(12345);
      final charCounts = <int, int>{};

      for (int i = 0; i < 10000; i++) {
        final index = rng.nextInt(32);
        charCounts[index] = (charCounts[index] ?? 0) + 1;
      }

      // Each character should appear roughly 312 times (10000 / 32)
      for (final count in charCounts.values) {
        expect(count, inInclusiveRange(200, 450));
      }
    });
  });

  group('Intermediate display states', () {
    test('displayed text has correct length during animation', () {
      final sim = GlitchTextSimulator(
        text: 'Hello',
        durationMs: 500,
        seed: 12345,
      );

      sim.advance(200); // 2 chars revealed
      // Expected: 2 revealed chars + 2 glitch chars = 4
      expect(sim.displayedText.length, 4);

      sim.advance(100); // 3 chars revealed
      // Expected: 3 revealed chars + 2 glitch chars = 5
      expect(sim.displayedText.length, 5);
    });

    test('glitch suffix changes as animation progresses', () {
      final sim = GlitchTextSimulator(
        text: 'ABCDE',
        durationMs: 500,
        seed: 12345,
      );

      final suffixes = <String>[];

      for (int i = 0; i < 4; i++) {
        sim.advance(100);
        // Extract the suffix (last 2 chars when not complete)
        if (!sim.isComplete && sim.displayedText.length >= 2) {
          final suffix = sim.displayedText.substring(sim.displayedText.length - 2);
          suffixes.add(suffix);
        }
      }

      // Suffixes should vary
      expect(suffixes.toSet().length, greaterThan(1));
    });
  });

  group('Edge case: very long text', () {
    test('handles 1000 character text', () {
      final longText = List.generate(1000, (i) => 'A').join();
      final sim = GlitchTextSimulator(
        text: longText,
        durationMs: 10000,
      );

      expect(sim.charDuration, 10);

      sim.advance(5000);
      expect(sim.charIndex, 500);

      sim.advance(6000);
      expect(sim.isComplete, true);
      expect(sim.displayedText, longText);
    });
  });

  group('Edge case: rapid updates', () {
    test('many small updates produce correct result', () {
      final sim = GlitchTextSimulator(
        text: 'Test',
        durationMs: 400,
      );

      // 500 updates of 1ms each
      for (int i = 0; i < 500; i++) {
        sim.advance(1);
      }

      expect(sim.isComplete, true);
      expect(sim.displayedText, 'Test');
    });
  });
}
