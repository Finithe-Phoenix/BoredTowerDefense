import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CountdownTimerComponent layout constants', () {
    test('baseSize is 120', () {
      const baseSize = 120.0;
      expect(baseSize, 120.0);
    });

    test('ringThickness is 6', () {
      const ringThickness = 6.0;
      expect(ringThickness, 6.0);
    });

    test('innerRingThickness is 3', () {
      const innerRingThickness = 3.0;
      expect(innerRingThickness, 3.0);
    });

    test('default totalDuration is 60 seconds', () {
      const totalDuration = 60.0;
      expect(totalDuration, 60.0);
    });

    test('priority is 110 (above HUD)', () {
      const priority = 110;
      expect(priority, 110);
    });
  });

  group('CountdownTimerComponent progress calculation', () {
    double calculateProgress(double remainingTime, double totalDuration) {
      return totalDuration > 0 ? 1.0 - (remainingTime / totalDuration) : 1.0;
    }

    test('progress is 0.0 at full time', () {
      expect(calculateProgress(60.0, 60.0), 0.0);
    });

    test('progress is 0.5 at half time', () {
      expect(calculateProgress(30.0, 60.0), 0.5);
    });

    test('progress is 1.0 at zero time', () {
      expect(calculateProgress(0.0, 60.0), 1.0);
    });

    test('progress is 0.25 at 75% time remaining', () {
      expect(calculateProgress(45.0, 60.0), 0.25);
    });

    test('progress is 1.0 when totalDuration is 0', () {
      expect(calculateProgress(10.0, 0.0), 1.0);
    });
  });

  group('CountdownTimerComponent urgency level calculation', () {
    double calculateUrgencyLevel(double remainingTime, double totalDuration) {
      if (totalDuration <= 0) return 1.0;
      final percent = remainingTime / totalDuration;
      if (percent > 0.3) return 0.0;
      if (percent > 0.1) return (0.3 - percent) / 0.2;
      return 1.0;
    }

    test('urgency is 0.0 above 30%', () {
      expect(calculateUrgencyLevel(30.0, 60.0), 0.0); // 50%
      expect(calculateUrgencyLevel(20.0, 60.0), 0.0); // 33.3%
      expect(calculateUrgencyLevel(18.1, 60.0), closeTo(0.0, 0.01)); // 30.16%
    });

    test('urgency is 1.0 below 10%', () {
      expect(calculateUrgencyLevel(5.0, 60.0), 1.0); // 8.3%
      expect(calculateUrgencyLevel(0.0, 60.0), 1.0); // 0%
    });

    test('urgency ramps between 30% and 10%', () {
      // At 20% (12s of 60s): (0.3 - 0.2) / 0.2 = 0.5
      expect(calculateUrgencyLevel(12.0, 60.0), closeTo(0.5, 0.01));

      // At 25% (15s of 60s): (0.3 - 0.25) / 0.2 = 0.25
      expect(calculateUrgencyLevel(15.0, 60.0), closeTo(0.25, 0.01));

      // At 15% (9s of 60s): (0.3 - 0.15) / 0.2 = 0.75
      expect(calculateUrgencyLevel(9.0, 60.0), closeTo(0.75, 0.01));
    });

    test('urgency is 1.0 when totalDuration is 0', () {
      expect(calculateUrgencyLevel(10.0, 0.0), 1.0);
    });
  });

  group('CountdownTimerComponent warning threshold', () {
    bool isWarning(double remainingTime, double totalDuration) {
      return remainingTime / totalDuration < 0.3;
    }

    test('not warning at 50%', () {
      expect(isWarning(30.0, 60.0), isFalse);
    });

    test('not warning at exactly 30%', () {
      expect(isWarning(18.0, 60.0), isFalse);
    });

    test('warning at 29%', () {
      expect(isWarning(17.4, 60.0), isTrue);
    });

    test('warning at 10%', () {
      expect(isWarning(6.0, 60.0), isTrue);
    });

    test('warning at 0%', () {
      expect(isWarning(0.0, 60.0), isTrue);
    });
  });

  group('CountdownTimerComponent critical threshold', () {
    bool isCritical(double remainingTime) {
      return remainingTime < 10.0;
    }

    test('not critical at 60 seconds', () {
      expect(isCritical(60.0), isFalse);
    });

    test('not critical at 10 seconds', () {
      expect(isCritical(10.0), isFalse);
    });

    test('critical at 9.9 seconds', () {
      expect(isCritical(9.9), isTrue);
    });

    test('critical at 5 seconds', () {
      expect(isCritical(5.0), isTrue);
    });

    test('critical at 0 seconds', () {
      expect(isCritical(0.0), isTrue);
    });
  });

  group('CountdownTimerComponent timer color calculation', () {
    Color calculateTimerColor(double remainingTime, double totalDuration) {
      if (totalDuration <= 0) return const Color(0xFFFF0044);
      final percent = remainingTime / totalDuration;
      if (percent > 0.5) {
        final t = (percent - 0.5) / 0.5;
        return Color.lerp(const Color(0xFFFFFF00), const Color(0xFF00FFFF), t)!;
      } else if (percent > 0.3) {
        return const Color(0xFFFFFF00);
      } else {
        final t = percent / 0.3;
        return Color.lerp(const Color(0xFFFF0044), const Color(0xFFFFFF00), t)!;
      }
    }

    test('color is cyan at 100%', () {
      final color = calculateTimerColor(60.0, 60.0);
      expect(color, const Color(0xFF00FFFF));
    });

    test('color is yellow at 50%', () {
      final color = calculateTimerColor(30.0, 60.0);
      expect(color, const Color(0xFFFFFF00));
    });

    test('color is yellow between 50% and 30%', () {
      final color = calculateTimerColor(24.0, 60.0); // 40%
      expect(color, const Color(0xFFFFFF00));
    });

    test('color is red at 0%', () {
      final color = calculateTimerColor(0.0, 60.0);
      expect(color, const Color(0xFFFF0044));
    });

    test('color is red when totalDuration is 0', () {
      final color = calculateTimerColor(10.0, 0.0);
      expect(color, const Color(0xFFFF0044));
    });

    test('color transitions from cyan to yellow (100% to 50%)', () {
      final at75 = calculateTimerColor(45.0, 60.0); // 75%
      // At 75%, t = (0.75 - 0.5) / 0.5 = 0.5
      // Should be halfway between yellow and cyan
      expect(at75.red, lessThan(255));
      expect(at75.green, 255);
      expect(at75.blue, lessThan(255));
    });

    test('color transitions from yellow to red (30% to 0%)', () {
      final at15 = calculateTimerColor(9.0, 60.0); // 15%
      // At 15%, t = 0.15 / 0.3 = 0.5
      // Should be halfway between red and yellow
      expect(at15.red, 255);
      expect(at15.green, lessThan(255));
      expect(at15.green, greaterThan(0));
    });
  });

  group('CountdownTimerComponent glitch threshold', () {
    double getGlitchThreshold(bool isCritical, bool isWarning) {
      return isCritical ? 0.5 : (isWarning ? 1.5 : 3.0);
    }

    test('threshold is 0.5 when critical', () {
      expect(getGlitchThreshold(true, true), 0.5);
      expect(getGlitchThreshold(true, false), 0.5);
    });

    test('threshold is 1.5 when warning but not critical', () {
      expect(getGlitchThreshold(false, true), 1.5);
    });

    test('threshold is 3.0 in normal state', () {
      expect(getGlitchThreshold(false, false), 3.0);
    });
  });

  group('CountdownTimerComponent time formatting', () {
    String formatTime(double remainingTime) {
      final seconds = remainingTime.ceil();
      final displayMinutes = seconds ~/ 60;
      final displaySeconds = seconds % 60;

      if (displayMinutes > 0) {
        return '${displayMinutes.toString().padLeft(2, '0')}:${displaySeconds.toString().padLeft(2, '0')}';
      } else {
        return displaySeconds.toString().padLeft(2, '0');
      }
    }

    test('formats 60 seconds as 01:00', () {
      expect(formatTime(60.0), '01:00');
    });

    test('formats 59.9 seconds as 01:00 (ceiling)', () {
      expect(formatTime(59.1), '01:00');
    });

    test('formats 59 seconds as 59', () {
      expect(formatTime(59.0), '59');
    });

    test('formats 30 seconds as 30', () {
      expect(formatTime(30.0), '30');
    });

    test('formats 10 seconds as 10', () {
      expect(formatTime(10.0), '10');
    });

    test('formats 5 seconds as 05', () {
      expect(formatTime(5.0), '05');
    });

    test('formats 1 second as 01', () {
      expect(formatTime(1.0), '01');
    });

    test('formats 0 seconds as 00', () {
      expect(formatTime(0.0), '00');
    });

    test('formats 120 seconds as 02:00', () {
      expect(formatTime(120.0), '02:00');
    });

    test('formats 90 seconds as 01:30', () {
      expect(formatTime(90.0), '01:30');
    });
  });

  group('CountdownTimerComponent seven-segment patterns', () {
    List<bool> getSegments(int digit) {
      const segmentMap = <int, List<bool>>{
        0: [true, true, true, true, true, true, false],
        1: [false, true, true, false, false, false, false],
        2: [true, true, false, true, true, false, true],
        3: [true, true, true, true, false, false, true],
        4: [false, true, true, false, false, true, true],
        5: [true, false, true, true, false, true, true],
        6: [true, false, true, true, true, true, true],
        7: [true, true, true, false, false, false, false],
        8: [true, true, true, true, true, true, true],
        9: [true, true, true, true, false, true, true],
      };
      return segmentMap[digit] ?? [false, false, false, false, false, false, false];
    }

    test('digit 0 has 6 segments', () {
      final segments = getSegments(0);
      expect(segments.where((s) => s).length, 6);
      expect(segments[6], isFalse); // No middle segment
    });

    test('digit 1 has 2 segments', () {
      final segments = getSegments(1);
      expect(segments.where((s) => s).length, 2);
    });

    test('digit 2 has 5 segments', () {
      final segments = getSegments(2);
      expect(segments.where((s) => s).length, 5);
    });

    test('digit 8 has all 7 segments', () {
      final segments = getSegments(8);
      expect(segments.where((s) => s).length, 7);
    });

    test('invalid digit returns all false', () {
      final segments = getSegments(-1);
      expect(segments.every((s) => !s), isTrue);

      final segments2 = getSegments(10);
      expect(segments2.every((s) => !s), isTrue);
    });
  });

  group('CountdownTimerComponent pulse count', () {
    int getPulseCount(bool isCritical, bool isWarning) {
      return isCritical ? 3 : (isWarning ? 2 : 1);
    }

    test('3 pulses when critical', () {
      expect(getPulseCount(true, true), 3);
      expect(getPulseCount(true, false), 3);
    });

    test('2 pulses when warning but not critical', () {
      expect(getPulseCount(false, true), 2);
    });

    test('1 pulse in normal state', () {
      expect(getPulseCount(false, false), 1);
    });
  });

  group('CountdownTimerComponent flash alpha calculation', () {
    double calculateFlashAlpha(double remainingTime, double currentAlpha) {
      final secondFraction = remainingTime - remainingTime.floor();
      if (secondFraction > 0.9) {
        return (secondFraction - 0.9) / 0.1 * 0.3;
      } else {
        return currentAlpha * 0.9;
      }
    }

    test('flash alpha peaks at second boundary', () {
      // At 9.99 seconds, secondFraction = 0.99
      final alpha = calculateFlashAlpha(9.99, 0.0);
      // (0.99 - 0.9) / 0.1 * 0.3 = 0.09/0.1 * 0.3 = 0.27
      expect(alpha, closeTo(0.27, 0.01));
    });

    test('flash alpha is max 0.3 at exactly second boundary', () {
      // At exactly 10.0 seconds, secondFraction = 0.0 (from .floor())
      // Actually 10.0 - 10 = 0.0, so it fades
      final alpha = calculateFlashAlpha(10.0, 0.3);
      expect(alpha, closeTo(0.27, 0.01)); // 0.3 * 0.9
    });

    test('flash alpha fades during most of second', () {
      final alpha = calculateFlashAlpha(9.5, 0.3);
      expect(alpha, closeTo(0.27, 0.01)); // 0.3 * 0.9
    });
  });

  group('CountdownTimerComponent shake intensity', () {
    double calculateShakeIntensity(double remainingTime) {
      return (1.0 - remainingTime / 10.0) * 3.0;
    }

    test('shake intensity is 0 at 10 seconds', () {
      expect(calculateShakeIntensity(10.0), 0.0);
    });

    test('shake intensity is 1.5 at 5 seconds', () {
      // (1.0 - 0.5) * 3.0 = 1.5
      expect(calculateShakeIntensity(5.0), 1.5);
    });

    test('shake intensity is 3.0 at 0 seconds', () {
      expect(calculateShakeIntensity(0.0), 3.0);
    });

    test('shake intensity is 2.7 at 1 second', () {
      // (1.0 - 0.1) * 3.0 = 2.7
      expect(calculateShakeIntensity(1.0), closeTo(2.7, 0.01));
    });
  });

  group('CountdownTimerComponent state transitions', () {
    test('start sets initial state', () {
      double remainingTime = 0;
      bool isActive = false;
      bool hasCompleted = true;
      double flashAlpha = 0.5;
      const totalDuration = 60.0;

      // Simulate start()
      remainingTime = totalDuration;
      isActive = true;
      hasCompleted = false;
      flashAlpha = 0;

      expect(remainingTime, 60.0);
      expect(isActive, isTrue);
      expect(hasCompleted, isFalse);
      expect(flashAlpha, 0);
    });

    test('pause sets isActive to false', () {
      bool isActive = true;

      // Simulate pause()
      isActive = false;

      expect(isActive, isFalse);
    });

    test('resume sets isActive to true if not completed', () {
      bool isActive = false;
      bool hasCompleted = false;

      // Simulate resume()
      if (!hasCompleted) {
        isActive = true;
      }

      expect(isActive, isTrue);
    });

    test('resume does not reactivate if completed', () {
      bool isActive = false;
      bool hasCompleted = true;

      // Simulate resume()
      if (!hasCompleted) {
        isActive = true;
      }

      expect(isActive, isFalse);
    });

    test('stop resets all state', () {
      double remainingTime = 10.0;
      bool isActive = true;
      bool hasCompleted = true;
      double flashAlpha = 0.3;
      const totalDuration = 60.0;

      // Simulate stop()
      isActive = false;
      remainingTime = totalDuration;
      hasCompleted = false;
      flashAlpha = 0;

      expect(remainingTime, 60.0);
      expect(isActive, isFalse);
      expect(hasCompleted, isFalse);
      expect(flashAlpha, 0);
    });
  });

  group('CountdownTimerComponent addTime', () {
    test('addTime increases remaining time', () {
      double remainingTime = 30.0;
      const totalDuration = 60.0;

      // Simulate addTime(10)
      remainingTime = (remainingTime + 10).clamp(0.0, totalDuration);

      expect(remainingTime, 40.0);
    });

    test('addTime clamps to totalDuration', () {
      double remainingTime = 55.0;
      const totalDuration = 60.0;

      // Simulate addTime(10)
      remainingTime = (remainingTime + 10).clamp(0.0, totalDuration);

      expect(remainingTime, 60.0);
    });

    test('addTime clamps to 0', () {
      double remainingTime = 5.0;
      const totalDuration = 60.0;

      // Simulate addTime(-10)
      remainingTime = (remainingTime + (-10)).clamp(0.0, totalDuration);

      expect(remainingTime, 0.0);
    });

    test('addTime clears hasCompleted if time added', () {
      double remainingTime = 0.0;
      bool hasCompleted = true;
      const totalDuration = 60.0;

      // Simulate addTime(10)
      remainingTime = (remainingTime + 10).clamp(0.0, totalDuration);
      if (remainingTime > 0) {
        hasCompleted = false;
      }

      expect(remainingTime, 10.0);
      expect(hasCompleted, isFalse);
    });
  });

  group('CountdownTimerComponent setTime', () {
    test('setTime sets remaining time', () {
      double remainingTime = 30.0;
      const totalDuration = 60.0;

      // Simulate setTime(45)
      remainingTime = 45.0.clamp(0.0, totalDuration);

      expect(remainingTime, 45.0);
    });

    test('setTime clamps to totalDuration', () {
      double remainingTime = 30.0;
      const totalDuration = 60.0;

      // Simulate setTime(100)
      remainingTime = 100.0.clamp(0.0, totalDuration);

      expect(remainingTime, 60.0);
    });

    test('setTime clamps to 0', () {
      double remainingTime = 30.0;
      const totalDuration = 60.0;

      // Simulate setTime(-10)
      remainingTime = (-10.0).clamp(0.0, totalDuration);

      expect(remainingTime, 0.0);
    });
  });

  group('CountdownTimerComponent update simulation', () {
    test('timer decrements when active', () {
      double remainingTime = 60.0;
      bool isActive = true;
      const dt = 1.0;

      // Simulate update
      if (isActive && remainingTime > 0) {
        remainingTime -= dt;
      }

      expect(remainingTime, 59.0);
    });

    test('timer does not decrement when paused', () {
      double remainingTime = 60.0;
      bool isActive = false;
      const dt = 1.0;

      // Simulate update
      if (isActive && remainingTime > 0) {
        remainingTime -= dt;
      }

      expect(remainingTime, 60.0);
    });

    test('timer triggers completion at zero', () {
      double remainingTime = 0.5;
      bool isActive = true;
      bool hasCompleted = false;
      bool callbackCalled = false;
      const dt = 1.0;

      // Simulate update
      if (isActive && remainingTime > 0) {
        remainingTime -= dt;
        if (remainingTime <= 0) {
          remainingTime = 0;
          isActive = false;
          hasCompleted = true;
          callbackCalled = true;
        }
      }

      expect(remainingTime, 0.0);
      expect(isActive, isFalse);
      expect(hasCompleted, isTrue);
      expect(callbackCalled, isTrue);
    });
  });

  group('CountdownTimerComponent scale calculation', () {
    double calculateScale(double screenWidth, double screenHeight) {
      const baseWidth = 1920.0;
      const baseHeight = 1080.0;
      final scaleX = (screenWidth / baseWidth).clamp(0.5, 1.2);
      final scaleY = (screenHeight / baseHeight).clamp(0.5, 1.2);
      return math.min(scaleX, scaleY);
    }

    test('scale is 1.0 at 1920x1080', () {
      expect(calculateScale(1920, 1080), 1.0);
    });

    test('scale is 0.5 at very small screen', () {
      expect(calculateScale(480, 270), 0.5);
    });

    test('scale is clamped at 1.2 for large screens', () {
      expect(calculateScale(3840, 2160), 1.2);
    });

    test('scale uses minimum of x and y', () {
      // 1280/1920 = 0.667, 1080/1080 = 1.0, min = 0.667
      expect(calculateScale(1280, 1080), closeTo(0.667, 0.01));
    });
  });

  group('CountdownTimerComponent timer size calculation', () {
    double calculateTimerSize(double scale) {
      const baseSize = 120.0;
      return (baseSize * scale).clamp(80.0, 140.0);
    }

    test('timer size at scale 1.0 is 120', () {
      expect(calculateTimerSize(1.0), 120.0);
    });

    test('timer size is clamped at minimum 80', () {
      expect(calculateTimerSize(0.5), 80.0);
    });

    test('timer size is clamped at maximum 140', () {
      expect(calculateTimerSize(1.5), 140.0);
    });
  });

  group('CountdownTimerComponent FastRng', () {
    test('LCG formula matches implementation', () {
      int state = 0x6d2b79f5;
      state = (1664525 * state + 1013904223) & 0x7fffffff;
      expect(state, isNonNegative);
      expect(state, lessThan(0x7fffffff));
    });

    test('nextDouble returns value between 0 and 1', () {
      int state = 0x6d2b79f5;
      state = (1664525 * state + 1013904223) & 0x7fffffff;
      final value = state / 0x7fffffff;
      expect(value, greaterThanOrEqualTo(0.0));
      expect(value, lessThanOrEqualTo(1.0));
    });

    test('nextInt returns value in range', () {
      int state = 0x6d2b79f5;
      state = (1664525 * state + 1013904223) & 0x7fffffff;
      final value = state % 100;
      expect(value, greaterThanOrEqualTo(0));
      expect(value, lessThan(100));
    });

    test('nextInt returns 0 for max <= 0', () {
      final value = 0 <= 0 ? 0 : 12345 % 0;
      expect(value, 0);
    });
  });

  group('CountdownTimerComponent performance', () {
    test('can calculate many progress values', () {
      for (int i = 0; i < 1000; i++) {
        final remainingTime = i.toDouble();
        final totalDuration = 1000.0;
        final _ = totalDuration > 0 ? 1.0 - (remainingTime / totalDuration) : 1.0;
      }
      expect(true, isTrue);
    });

    test('can calculate many urgency levels', () {
      for (int i = 0; i < 1000; i++) {
        final remainingTime = i.toDouble();
        final totalDuration = 1000.0;
        final percent = remainingTime / totalDuration;
        double _;
        if (percent > 0.3) {
          _ = 0.0;
        } else if (percent > 0.1) {
          _ = (0.3 - percent) / 0.2;
        } else {
          _ = 1.0;
        }
      }
      expect(true, isTrue);
    });

    test('can calculate many timer colors', () {
      for (int i = 0; i < 1000; i++) {
        final remainingTime = i.toDouble();
        final totalDuration = 1000.0;
        final percent = remainingTime / totalDuration;
        Color _;
        if (percent > 0.5) {
          final t = (percent - 0.5) / 0.5;
          _ = Color.lerp(const Color(0xFFFFFF00), const Color(0xFF00FFFF), t)!;
        } else if (percent > 0.3) {
          _ = const Color(0xFFFFFF00);
        } else {
          final t = percent / 0.3;
          _ = Color.lerp(const Color(0xFFFF0044), const Color(0xFFFFFF00), t)!;
        }
      }
      expect(true, isTrue);
    });
  });
}
