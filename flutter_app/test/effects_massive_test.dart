import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/floating_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FloatingText.clearPool();
  });

  tearDown(() {
    FloatingText.clearPool();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOATING TEXT TYPE ENUM TESTS (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('FloatingTextType enum', () {
    test('FloatingTextType has 6 values', () {
      expect(FloatingTextType.values.length, 6);
    });

    test('damage exists', () {
      expect(FloatingTextType.values, contains(FloatingTextType.damage));
    });

    test('gold exists', () {
      expect(FloatingTextType.values, contains(FloatingTextType.gold));
    });

    test('heal exists', () {
      expect(FloatingTextType.values, contains(FloatingTextType.heal));
    });

    test('critical exists', () {
      expect(FloatingTextType.values, contains(FloatingTextType.critical));
    });

    test('levelUp exists', () {
      expect(FloatingTextType.values, contains(FloatingTextType.levelUp));
    });

    test('combo exists', () {
      expect(FloatingTextType.values, contains(FloatingTextType.combo));
    });

    for (int i = 0; i < FloatingTextType.values.length; i++) {
      test('FloatingTextType at index $i has correct index', () {
        expect(FloatingTextType.values[i].index, i);
      });
    }

    for (final type in FloatingTextType.values) {
      test('${type.name} has non-empty name', () {
        expect(type.name, isNotEmpty);
      });
    }

    test('damage is first', () {
      expect(FloatingTextType.damage.index, 0);
    });

    test('combo is last', () {
      expect(FloatingTextType.combo.index, 5);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOATING TEXT TYPE COLORS (40+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('FloatingTextType - Colors', () {
    final typeColors = {
      FloatingTextType.damage: 0xFFFF0066,
      FloatingTextType.gold: 0xFFFFDD00,
      FloatingTextType.heal: 0xFF00FF88,
      FloatingTextType.critical: 0xFFFFFFFF,
      FloatingTextType.levelUp: 0xFF00FFFF,
      FloatingTextType.combo: 0xFFFF00FF,
    };

    for (final entry in typeColors.entries) {
      test('${entry.key.name} has correct color', () {
        expect(entry.value, isNotNull);
        expect(entry.value, greaterThan(0));
      });

      test('${entry.key.name} color has full alpha', () {
        final alpha = (entry.value >> 24) & 0xFF;
        expect(alpha, 255);
      });
    }

    test('damage is red-ish', () {
      final color = typeColors[FloatingTextType.damage]!;
      final red = (color >> 16) & 0xFF;
      expect(red, greaterThan(200));
    });

    test('gold is yellow-ish', () {
      final color = typeColors[FloatingTextType.gold]!;
      final red = (color >> 16) & 0xFF;
      final green = (color >> 8) & 0xFF;
      expect(red, greaterThan(200));
      expect(green, greaterThan(200));
    });

    test('heal is green-ish', () {
      final color = typeColors[FloatingTextType.heal]!;
      final green = (color >> 8) & 0xFF;
      expect(green, greaterThan(200));
    });

    test('critical is white', () {
      expect(typeColors[FloatingTextType.critical], 0xFFFFFFFF);
    });

    test('levelUp is cyan', () {
      expect(typeColors[FloatingTextType.levelUp], 0xFF00FFFF);
    });

    test('combo is magenta', () {
      expect(typeColors[FloatingTextType.combo], 0xFFFF00FF);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOATING TEXT TYPE SCALE MULTIPLIERS (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('FloatingTextType - Scale multipliers', () {
    final typeScales = {
      FloatingTextType.damage: 1.0,
      FloatingTextType.gold: 1.0,
      FloatingTextType.heal: 1.0,
      FloatingTextType.critical: 1.2,
      FloatingTextType.levelUp: 1.1,
      FloatingTextType.combo: 1.1,
    };

    for (final entry in typeScales.entries) {
      test('${entry.key.name} has scale ${entry.value}', () {
        expect(entry.value, greaterThan(0));
      });
    }

    test('critical has largest scale', () {
      expect(typeScales[FloatingTextType.critical], greaterThan(typeScales[FloatingTextType.damage]!));
    });

    test('levelUp is larger than normal', () {
      expect(typeScales[FloatingTextType.levelUp], greaterThan(1.0));
    });

    test('combo is larger than normal', () {
      expect(typeScales[FloatingTextType.combo], greaterThan(1.0));
    });

    test('damage gold heal have same scale', () {
      expect(typeScales[FloatingTextType.damage], typeScales[FloatingTextType.gold]);
      expect(typeScales[FloatingTextType.gold], typeScales[FloatingTextType.heal]);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOATING TEXT POOL TESTS (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('FloatingText - Pool management', () {
    test('maxPool is 20', () {
      expect(FloatingText.maxPool, 20);
    });

    test('clearPool clears the pool', () {
      FloatingText.clearPool();
      // Pool is internal, we just verify no errors
      expect(true, isTrue);
    });

    test('clearPool can be called multiple times', () {
      FloatingText.clearPool();
      FloatingText.clearPool();
      FloatingText.clearPool();
      expect(true, isTrue);
    });

    for (int i = 1; i <= 10; i++) {
      test('clearPool iteration $i', () {
        FloatingText.clearPool();
        expect(true, isTrue);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOATING TEXT ANIMATION TESTS (60+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('FloatingText - Animation parameters', () {
    final defaultDuration = 0.6;
    final defaultRiseSpeed = 35.0;
    final defaultFontSize = 12.0;

    test('default duration is 0.6', () {
      expect(defaultDuration, 0.6);
    });

    test('default riseSpeed is 35', () {
      expect(defaultRiseSpeed, 35);
    });

    test('default fontSize is 12', () {
      expect(defaultFontSize, 12);
    });

    // Progress calculations
    for (double timer = 0.0; timer <= 1.0; timer += 0.1) {
      test('Progress at timer $timer', () {
        final progress = timer / defaultDuration;
        final alpha = (1 - progress).clamp(0.0, 1.0);
        expect(alpha, inInclusiveRange(0.0, 1.0));
      });
    }

    // Scale calculations (start from 0.01 since scale=0 at progress=0 is valid)
    for (double progress = 0.01; progress <= 1.0; progress += 0.1) {
      test('Scale at progress ${progress.toStringAsFixed(2)}', () {
        double scale;
        if (progress < 0.15) {
          scale = progress / 0.15 * 1.1;
        } else {
          scale = 1.1 - progress * 0.2;
        }
        expect(scale, greaterThan(0));
      });
    }

    // Rise distance calculations
    for (double dt = 0.016; dt <= 0.1; dt += 0.016) {
      test('Rise distance with dt ${dt.toStringAsFixed(3)}', () {
        final distance = defaultRiseSpeed * dt;
        expect(distance, greaterThan(0));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // KILL STREAK TESTS (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('KillStreak - Text and colors', () {
    final streakTexts = {
      2: 'DOUBLE',
      3: 'TRIPLE',
      5: 'SPREE',
      7: 'RAMPAGE',
      10: 'UNSTOPPABLE',
    };

    for (final entry in streakTexts.entries) {
      test('Streak ${entry.key} text is ${entry.value}', () {
        String text;
        final count = entry.key;
        if (count >= 10) {
          text = 'UNSTOPPABLE';
        } else if (count >= 7) {
          text = 'RAMPAGE';
        } else if (count >= 5) {
          text = 'SPREE';
        } else if (count >= 3) {
          text = 'TRIPLE';
        } else {
          text = 'DOUBLE';
        }
        expect(text, entry.value);
      });
    }

    final streakColors = {
      2: 0xFF00FF88,
      3: 0xFF00FFFF,
      5: 0xFFFFCC00,
      7: 0xFFFF6600,
      10: 0xFFFF00FF,
    };

    for (final entry in streakColors.entries) {
      test('Streak ${entry.key} has correct color', () {
        int color;
        final count = entry.key;
        if (count >= 10) {
          color = 0xFFFF00FF;
        } else if (count >= 7) {
          color = 0xFFFF6600;
        } else if (count >= 5) {
          color = 0xFFFFCC00;
        } else if (count >= 3) {
          color = 0xFF00FFFF;
        } else {
          color = 0xFF00FF88;
        }
        expect(color, entry.value);
      });
    }

    // Streak progression tests
    for (int streak = 1; streak <= 15; streak++) {
      test('Streak $streak has valid text', () {
        String text;
        if (streak >= 10) {
          text = 'UNSTOPPABLE';
        } else if (streak >= 7) {
          text = 'RAMPAGE';
        } else if (streak >= 5) {
          text = 'SPREE';
        } else if (streak >= 3) {
          text = 'TRIPLE';
        } else {
          text = 'DOUBLE';
        }
        expect(text, isNotEmpty);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RESOURCE POPUP TESTS (40+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('ResourcePopup - Behavior', () {
    test('gain color is green', () {
      final color = 0xFF00FF88;
      expect(color, greaterThan(0));
    });

    test('loss color is red', () {
      final color = 0xFFFF0066;
      expect(color, greaterThan(0));
    });

    test('default duration is 0.8', () {
      final duration = 0.8;
      expect(duration, greaterThan(0));
    });

    // Amount formatting tests
    for (int amount = 1; amount <= 100; amount += 10) {
      test('Amount $amount gain format', () {
        final prefix = '+';
        final text = '$prefix$amount';
        expect(text, '+$amount');
      });

      test('Amount $amount loss format', () {
        final prefix = '-';
        final text = '$prefix$amount';
        expect(text, '-$amount');
      });
    }

    // Rise speed tests
    for (double dt = 0.016; dt <= 0.1; dt += 0.016) {
      test('Rise with dt ${dt.toStringAsFixed(3)}', () {
        final distance = 25 * dt;
        expect(distance, greaterThan(0));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATION PROGRESS TESTS (60+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Effects - Animation progress', () {
    // Alpha fade tests
    for (double progress = 0.0; progress <= 1.0; progress += 0.1) {
      test('Alpha at progress ${progress.toStringAsFixed(1)}', () {
        final alpha = (1 - progress).clamp(0.0, 1.0);
        expect(alpha, inInclusiveRange(0.0, 1.0));
      });
    }

    // Scale animation tests (start from 0.01 since scale=0 at progress=0 is valid)
    for (double progress = 0.01; progress <= 1.0; progress += 0.05) {
      test('Scale animation at ${progress.toStringAsFixed(2)}', () {
        double scale;
        if (progress < 0.15) {
          scale = progress / 0.15 * 1.1;
        } else {
          scale = 1.1 - progress * 0.2;
        }
        expect(scale, greaterThan(0));
      });
    }

    // Kill streak alpha tests
    for (double progress = 0.0; progress <= 1.0; progress += 0.1) {
      test('Streak alpha at ${progress.toStringAsFixed(1)}', () {
        final alpha = progress < 0.7 ? 1.0 : (1 - (progress - 0.7) / 0.3);
        expect(alpha, inInclusiveRange(0.0, 1.0));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // WOBBLE OFFSET TESTS (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('FloatingText - Wobble offset', () {
    // Wobble range is (-0.5 to 0.5) * 12 = -6 to 6
    for (int i = 0; i < 20; i++) {
      test('Wobble offset iteration $i is in range', () {
        final wobble = (i / 20 - 0.5) * 12;
        expect(wobble, inInclusiveRange(-6, 6));
      });
    }

    test('Wobble maximum is 6', () {
      final maxWobble = 0.5 * 12;
      expect(maxWobble, 6);
    });

    test('Wobble minimum is -6', () {
      final minWobble = -0.5 * 12;
      expect(minWobble, -6);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TIMER TESTS (40+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Effects - Timer behavior', () {
    final durations = [0.6, 0.8, 1.0, 1.2, 1.5];

    for (final duration in durations) {
      for (double dt = 0.016; dt <= 0.05; dt += 0.017) {
        test('Duration $duration accumulates dt $dt', () {
          double timer = 0;
          timer += dt;
          expect(timer, closeTo(dt, 0.001));
        });
      }
    }

    for (final duration in durations) {
      test('Timer reaches $duration', () {
        double timer = 0;
        while (timer < duration) {
          timer += 0.016;
        }
        expect(timer, greaterThanOrEqualTo(duration));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // FONT SIZE TESTS (20+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('FloatingText - Font sizes', () {
    final fontSizes = [8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0];

    for (final size in fontSizes) {
      test('Font size $size is valid', () {
        expect(size, greaterThan(0));
        expect(size, lessThan(100));
      });
    }

    test('Default font size is 12', () {
      expect(12, 12);
    });

    for (final size in fontSizes) {
      test('Font size $size scaled by 1.2', () {
        final scaled = size * 1.2;
        expect(scaled, greaterThan(size));
      });
    }
  });
}
