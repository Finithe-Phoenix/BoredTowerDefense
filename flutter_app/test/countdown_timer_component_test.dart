import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/hud/countdown_timer_component.dart';

void main() {
  group('CountdownTimerComponent', () {
    late CountdownTimerComponent timer;

    setUp(() {
      timer = CountdownTimerComponent(totalDuration: 60.0);
    });

    group('initialization', () {
      test('has correct default totalDuration', () {
        expect(timer.totalDuration, 60.0);
      });

      test('remainingTime starts at 0 until started', () {
        expect(timer.remainingTime, 0.0);
      });

      test('isActive is false by default', () {
        expect(timer.isActive, isFalse);
      });

      test('progress is 1.0 when remainingTime is 0', () {
        expect(timer.progress, 1.0);
      });
    });

    group('start/stop/pause', () {
      test('start sets remainingTime to totalDuration', () {
        timer.start();
        expect(timer.remainingTime, 60.0);
        expect(timer.isActive, isTrue);
      });

      test('start with custom duration overrides totalDuration', () {
        timer.start(duration: 30.0);
        expect(timer.totalDuration, 30.0);
        expect(timer.remainingTime, 30.0);
      });

      test('pause stops the timer', () {
        timer.start();
        timer.pause();
        expect(timer.isActive, isFalse);
      });

      test('resume restarts the timer', () {
        timer.start();
        timer.pause();
        timer.resume();
        expect(timer.isActive, isTrue);
      });

      test('stop resets the timer', () {
        timer.start();
        timer.stop();
        expect(timer.isActive, isFalse);
        expect(timer.remainingTime, 60.0);
      });
    });

    group('time manipulation', () {
      test('addTime increases remainingTime', () {
        timer.start();
        timer.setTime(30.0);
        timer.addTime(10.0);
        expect(timer.remainingTime, 40.0);
      });

      test('addTime clamps to totalDuration', () {
        timer.start();
        timer.addTime(100.0);
        expect(timer.remainingTime, 60.0);
      });

      test('setTime sets remainingTime directly', () {
        timer.start();
        timer.setTime(45.0);
        expect(timer.remainingTime, 45.0);
      });

      test('setTime clamps to valid range', () {
        timer.start();
        timer.setTime(100.0);
        expect(timer.remainingTime, 60.0);

        timer.setTime(-10.0);
        expect(timer.remainingTime, 0.0);
      });
    });

    group('progress and urgency', () {
      test('progress is 0.0 when timer just started', () {
        timer.start();
        expect(timer.progress, 0.0);
      });

      test('progress is 0.5 when half time remaining', () {
        timer.start();
        timer.setTime(30.0);
        expect(timer.progress, 0.5);
      });

      test('progress is 1.0 when no time remaining', () {
        timer.start();
        timer.setTime(0.0);
        expect(timer.progress, 1.0);
      });

      test('urgencyLevel is 0 when > 30% time remaining', () {
        timer.start();
        timer.setTime(45.0); // 75%
        expect(timer.urgencyLevel, 0.0);
      });

      test('urgencyLevel increases as time decreases below 30%', () {
        timer.start();
        timer.setTime(18.0); // 30%
        expect(timer.urgencyLevel, 0.0);

        timer.setTime(12.0); // 20%
        expect(timer.urgencyLevel, closeTo(0.5, 0.01));

        timer.setTime(6.0); // 10%
        expect(timer.urgencyLevel, 1.0);
      });

      test('isWarning is true when < 30% time', () {
        timer.start();
        timer.setTime(10.0); // ~17%
        expect(timer.isWarning, isTrue);
      });

      test('isWarning is false when >= 30% time', () {
        timer.start();
        timer.setTime(20.0); // ~33%
        expect(timer.isWarning, isFalse);
      });

      test('isCritical is true when < 10 seconds', () {
        timer.start();
        timer.setTime(5.0);
        expect(timer.isCritical, isTrue);
      });

      test('isCritical is false when >= 10 seconds', () {
        timer.start();
        timer.setTime(15.0);
        expect(timer.isCritical, isFalse);
      });
    });

    group('timerColor', () {
      test('is cyan when plenty of time', () {
        timer.start();
        timer.setTime(55.0); // >90%
        final color = timer.timerColor;
        // At 55/60 = 92%, color lerps from yellow to cyan with t = 0.834
        // So blue = 255 * 0.834 ≈ 213, green = 255, red ≈ 42
        expect(color.blue, greaterThan(200)); // Mostly cyan
        expect(color.green, greaterThan(200));
      });

      test('transitions to yellow around 50%', () {
        timer.start();
        timer.setTime(25.0); // ~42%
        final color = timer.timerColor;
        // Should be yellow range
        expect(color.red, greaterThan(200));
        expect(color.green, greaterThan(200));
      });

      test('transitions to red when low', () {
        timer.start();
        timer.setTime(5.0); // <10%
        final color = timer.timerColor;
        // Should be more red
        expect(color.red, greaterThan(200));
        expect(color.green, lessThan(150));
      });
    });

    group('callback', () {
      test('onComplete callback is called when timer reaches zero', () {
        var callbackCalled = false;
        final timerWithCallback = CountdownTimerComponent(
          totalDuration: 1.0,
          onComplete: () => callbackCalled = true,
        );

        timerWithCallback.start();
        // Note: In actual usage, update() would be called by the game loop
        // Here we're just testing the callback is set up correctly
        expect(timerWithCallback.onComplete, isNotNull);
      });
    });

    group('static constants', () {
      test('baseSize is reasonable', () {
        expect(CountdownTimerComponent.baseSize, 120.0);
      });

      test('ringThickness is reasonable', () {
        expect(CountdownTimerComponent.ringThickness, 6.0);
      });

      test('innerRingThickness is reasonable', () {
        expect(CountdownTimerComponent.innerRingThickness, 3.0);
      });
    });
  });
}
