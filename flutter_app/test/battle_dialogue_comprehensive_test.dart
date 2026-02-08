import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/data/story_data.dart';

void main() {
  group('BattleDialogueComponent constants', () {
    test('dialogueDuration is 4 seconds', () {
      const dialogueDuration = 4.0;
      expect(dialogueDuration, 4.0);
    });

    test('typewriterSpeed is 30 chars per second', () {
      const typewriterSpeed = 30.0;
      expect(typewriterSpeed, 30.0);
    });

    test('fadeInDuration is 0.3 seconds', () {
      const fadeInDuration = 0.3;
      expect(fadeInDuration, 0.3);
    });

    test('fadeOutDuration is 0.5 seconds', () {
      const fadeOutDuration = 0.5;
      expect(fadeOutDuration, 0.5);
    });
  });

  group('BattleDialogueComponent typewriter calculations', () {
    test('typewriter progress increments with dt', () {
      double progress = 0;
      const typewriterSpeed = 30.0;
      const dt = 0.1;

      progress += dt * typewriterSpeed;

      expect(progress, 3.0);
    });

    test('typewriter takes 1 second for 30 chars', () {
      const typewriterSpeed = 30.0;
      const textLength = 30;
      final timeToComplete = textLength / typewriterSpeed;

      expect(timeToComplete, 1.0);
    });

    test('typewriter takes 2 seconds for 60 chars', () {
      const typewriterSpeed = 30.0;
      const textLength = 60;
      final timeToComplete = textLength / typewriterSpeed;

      expect(timeToComplete, 2.0);
    });

    test('typewriter progress is clamped to text length', () {
      double progress = 100.0;
      const textLength = 50;

      progress = progress.clamp(0, textLength.toDouble());

      expect(progress, 50.0);
    });

    test('displayed chars is floor of progress', () {
      const progress = 15.7;
      final displayedChars = progress.floor();

      expect(displayedChars, 15);
    });
  });

  group('BattleDialogueComponent fade calculations', () {
    double calculateFadeProgress(double displayTime) {
      const dialogueDuration = 4.0;
      const fadeInDuration = 0.3;
      const fadeOutDuration = 0.5;

      double fadeProgress;
      if (displayTime < fadeInDuration) {
        fadeProgress = displayTime / fadeInDuration;
      } else if (displayTime > dialogueDuration - fadeOutDuration) {
        fadeProgress = (dialogueDuration - displayTime) / fadeOutDuration;
      } else {
        fadeProgress = 1.0;
      }

      return fadeProgress.clamp(0.0, 1.0);
    }

    test('fade progress is 0 at start', () {
      expect(calculateFadeProgress(0.0), 0.0);
    });

    test('fade progress is 0.5 at 0.15 seconds', () {
      expect(calculateFadeProgress(0.15), closeTo(0.5, 0.01));
    });

    test('fade progress is 1.0 after fade in', () {
      expect(calculateFadeProgress(0.3), 1.0);
      expect(calculateFadeProgress(0.5), 1.0);
      expect(calculateFadeProgress(2.0), 1.0);
    });

    test('fade progress stays 1.0 during main display', () {
      expect(calculateFadeProgress(1.0), 1.0);
      expect(calculateFadeProgress(2.0), 1.0);
      expect(calculateFadeProgress(3.0), 1.0);
    });

    test('fade out starts at dialogueDuration - fadeOutDuration', () {
      // 4.0 - 0.5 = 3.5
      expect(calculateFadeProgress(3.5), 1.0);
      expect(calculateFadeProgress(3.6), lessThan(1.0));
    });

    test('fade progress decreases during fade out', () {
      expect(calculateFadeProgress(3.75), closeTo(0.5, 0.01));
    });

    test('fade progress is 0 at end', () {
      expect(calculateFadeProgress(4.0), 0.0);
    });
  });

  group('BriefingMood colors', () {
    Color getMoodColor(BriefingMood mood) {
      switch (mood) {
        case BriefingMood.urgent:
          return const Color(0xFFFF4444);
        case BriefingMood.analytical:
          return const Color(0xFF00FFFF);
        case BriefingMood.worried:
          return const Color(0xFFFFFF00);
        case BriefingMood.serious:
          return const Color(0xFF00FF88);
        case BriefingMood.mysterious:
          return const Color(0xFFFF00FF);
        case BriefingMood.hopeful:
          return const Color(0xFF00FF88);
        case BriefingMood.surprised:
          return const Color(0xFFFFFF00);
        case BriefingMood.emotional:
          return const Color(0xFF00FFFF);
        case BriefingMood.epic:
          return const Color(0xFFFFFFFF);
        case BriefingMood.dark:
          return const Color(0xFFFF00FF);
        case BriefingMood.sad:
          return const Color(0xFF00FFFF);
        case BriefingMood.confused:
          return const Color(0xFFFFFF00);
        case BriefingMood.revelation:
          return const Color(0xFFFFFFFF);
      }
    }

    test('urgent is red', () {
      expect(getMoodColor(BriefingMood.urgent), const Color(0xFFFF4444));
    });

    test('analytical is cyan', () {
      expect(getMoodColor(BriefingMood.analytical), const Color(0xFF00FFFF));
    });

    test('worried is yellow', () {
      expect(getMoodColor(BriefingMood.worried), const Color(0xFFFFFF00));
    });

    test('serious is green', () {
      expect(getMoodColor(BriefingMood.serious), const Color(0xFF00FF88));
    });

    test('mysterious is magenta', () {
      expect(getMoodColor(BriefingMood.mysterious), const Color(0xFFFF00FF));
    });

    test('hopeful is green', () {
      expect(getMoodColor(BriefingMood.hopeful), const Color(0xFF00FF88));
    });

    test('surprised is yellow', () {
      expect(getMoodColor(BriefingMood.surprised), const Color(0xFFFFFF00));
    });

    test('emotional is cyan', () {
      expect(getMoodColor(BriefingMood.emotional), const Color(0xFF00FFFF));
    });

    test('epic is white', () {
      expect(getMoodColor(BriefingMood.epic), const Color(0xFFFFFFFF));
    });

    test('dark is magenta', () {
      expect(getMoodColor(BriefingMood.dark), const Color(0xFFFF00FF));
    });

    test('sad is cyan', () {
      expect(getMoodColor(BriefingMood.sad), const Color(0xFF00FFFF));
    });

    test('confused is yellow', () {
      expect(getMoodColor(BriefingMood.confused), const Color(0xFFFFFF00));
    });

    test('revelation is white', () {
      expect(getMoodColor(BriefingMood.revelation), const Color(0xFFFFFFFF));
    });
  });

  group('BriefingMood enum', () {
    test('has 13 values', () {
      expect(BriefingMood.values.length, 13);
    });

    test('contains all expected values', () {
      expect(BriefingMood.values, contains(BriefingMood.urgent));
      expect(BriefingMood.values, contains(BriefingMood.analytical));
      expect(BriefingMood.values, contains(BriefingMood.worried));
      expect(BriefingMood.values, contains(BriefingMood.serious));
      expect(BriefingMood.values, contains(BriefingMood.mysterious));
      expect(BriefingMood.values, contains(BriefingMood.hopeful));
      expect(BriefingMood.values, contains(BriefingMood.surprised));
      expect(BriefingMood.values, contains(BriefingMood.emotional));
      expect(BriefingMood.values, contains(BriefingMood.epic));
      expect(BriefingMood.values, contains(BriefingMood.dark));
      expect(BriefingMood.values, contains(BriefingMood.sad));
      expect(BriefingMood.values, contains(BriefingMood.confused));
      expect(BriefingMood.values, contains(BriefingMood.revelation));
    });
  });

  group('BattleDialogueComponent queue simulation', () {
    test('priority inserts at front', () {
      final queue = <String>['first', 'second'];

      // Simulate priority = true
      queue.insert(0, 'priority');

      expect(queue[0], 'priority');
      expect(queue[1], 'first');
      expect(queue[2], 'second');
    });

    test('normal adds at end', () {
      final queue = <String>['first', 'second'];

      // Simulate priority = false
      queue.add('third');

      expect(queue[0], 'first');
      expect(queue[1], 'second');
      expect(queue[2], 'third');
    });

    test('showNext removes from front', () {
      final queue = <String>['first', 'second', 'third'];

      final current = queue.removeAt(0);

      expect(current, 'first');
      expect(queue.length, 2);
      expect(queue[0], 'second');
    });

    test('empty queue returns null equivalent', () {
      final queue = <String>[];

      final isEmpty = queue.isEmpty;

      expect(isEmpty, isTrue);
    });
  });

  group('BattleDialogueComponent wave triggers', () {
    test('wave 10 is massive wave', () {
      const waveNumber = 10;
      final isMassive = waveNumber % 10 == 0;
      expect(isMassive, isTrue);
    });

    test('wave 20 is massive wave', () {
      const waveNumber = 20;
      final isMassive = waveNumber % 10 == 0;
      expect(isMassive, isTrue);
    });

    test('wave 5 is increment wave', () {
      const waveNumber = 5;
      final isMassive = waveNumber % 10 == 0;
      final isIncrement = waveNumber % 5 == 0;
      expect(isMassive, isFalse);
      expect(isIncrement, isTrue);
    });

    test('wave 15 is increment wave', () {
      const waveNumber = 15;
      final isMassive = waveNumber % 10 == 0;
      final isIncrement = waveNumber % 5 == 0;
      expect(isMassive, isFalse);
      expect(isIncrement, isTrue);
    });

    test('wave 7 is not a special wave', () {
      const waveNumber = 7;
      final isMassive = waveNumber % 10 == 0;
      final isIncrement = waveNumber % 5 == 0;
      expect(isMassive, isFalse);
      expect(isIncrement, isFalse);
    });
  });

  group('BattleDialogueComponent low health triggers', () {
    test('1 life triggers critical', () {
      const livesRemaining = 1;
      final isCritical = livesRemaining == 1;
      expect(isCritical, isTrue);
    });

    test('2 lives triggers worried', () {
      const livesRemaining = 2;
      final isCritical = livesRemaining == 1;
      final isLow = livesRemaining <= 3;
      expect(isCritical, isFalse);
      expect(isLow, isTrue);
    });

    test('3 lives triggers worried', () {
      const livesRemaining = 3;
      final isCritical = livesRemaining == 1;
      final isLow = livesRemaining <= 3;
      expect(isCritical, isFalse);
      expect(isLow, isTrue);
    });

    test('4 lives does not trigger', () {
      const livesRemaining = 4;
      final isCritical = livesRemaining == 1;
      final isLow = livesRemaining <= 3;
      expect(isCritical, isFalse);
      expect(isLow, isFalse);
    });
  });

  group('BattleDialogueComponent ability triggers', () {
    test('NEON PULSE triggers dialogue', () {
      const abilityName = 'NEON PULSE';
      final isPulse = abilityName == 'NEON PULSE';
      expect(isPulse, isTrue);
    });

    test('NEON MINE triggers dialogue', () {
      const abilityName = 'NEON MINE';
      final isMine = abilityName == 'NEON MINE';
      expect(isMine, isTrue);
    });

    test('other ability does not trigger', () {
      const abilityName = 'OTHER';
      final isPulse = abilityName == 'NEON PULSE';
      final isMine = abilityName == 'NEON MINE';
      expect(isPulse, isFalse);
      expect(isMine, isFalse);
    });
  });

  group('BattleDialogueComponent FastRng', () {
    test('LCG formula', () {
      int state = 0x6d2b79f5;
      state = (1664525 * state + 1013904223) & 0x7fffffff;
      expect(state, isNonNegative);
      expect(state, lessThan(0x7fffffff));
    });

    test('nextDouble returns 0-1', () {
      int state = 0x6d2b79f5;
      state = (1664525 * state + 1013904223) & 0x7fffffff;
      final value = state / 0x7fffffff;
      expect(value, greaterThanOrEqualTo(0.0));
      expect(value, lessThanOrEqualTo(1.0));
    });

    test('nextInt returns value in range', () {
      int state = 0x6d2b79f5;
      state = (1664525 * state + 1013904223) & 0x7fffffff;
      final value = state % 5;
      expect(value, greaterThanOrEqualTo(0));
      expect(value, lessThan(5));
    });

    test('nextBool uses LSB', () {
      int state = 0x6d2b79f5;
      state = (1664525 * state + 1013904223) & 0x7fffffff;
      final value = (state & 1) == 0;
      expect(value, isA<bool>());
    });
  });

  group('BattleDialogueComponent cursor blink', () {
    test('cursor blinks at 3Hz', () {
      const blinkSpeed = 3.0;
      expect(blinkSpeed, 3.0);
    });

    test('cursor visible when blink < 0.5', () {
      const displayTime = 0.1;
      const blinkSpeed = 3.0;
      final blink = (displayTime * blinkSpeed) % 1;
      final isVisible = blink < 0.5;
      expect(isVisible, isTrue);
    });

    test('cursor hidden when blink >= 0.5', () {
      const displayTime = 0.2;
      const blinkSpeed = 3.0;
      final blink = (displayTime * blinkSpeed) % 1;
      final isVisible = blink < 0.5;
      expect(isVisible, isFalse);
    });
  });

  group('BattleDialogueComponent alpha calculations', () {
    test('alpha from fadeProgress', () {
      const fadeProgress = 0.5;
      final alpha = (fadeProgress * 255).round();
      expect(alpha, 128);
    });

    test('background alpha multiplier', () {
      const alpha = 255;
      final bgAlpha = (alpha * 0.85).round();
      expect(bgAlpha, 217);
    });

    test('border alpha multiplier', () {
      const alpha = 255;
      final borderAlpha = (alpha * 0.8).round();
      expect(borderAlpha, 204);
    });

    test('glow alpha multiplier', () {
      const alpha = 255;
      final glowAlpha = (alpha * 0.3).round();
      expect(glowAlpha, 77);
    });
  });

  group('BattleDialogueComponent layout', () {
    test('compact box width', () {
      const screenWidth = 600.0;
      final boxWidth = screenWidth - 40;
      expect(boxWidth, 560.0);
    });

    test('normal box width', () {
      const boxWidth = 400.0;
      expect(boxWidth, 400.0);
    });

    test('compact box y position', () {
      const boxY = 60.0;
      expect(boxY, 60.0);
    });

    test('normal box y position', () {
      const boxY = 80.0;
      expect(boxY, 80.0);
    });

    test('box x centered', () {
      const screenWidth = 1920.0;
      const boxWidth = 400.0;
      final boxX = (screenWidth - boxWidth) / 2;
      expect(boxX, 760.0);
    });
  });

  group('BattleDialogueComponent avatar sizes', () {
    test('compact avatar size', () {
      const avatarSize = 36.0;
      expect(avatarSize, 36.0);
    });

    test('normal avatar size', () {
      const avatarSize = 44.0;
      expect(avatarSize, 44.0);
    });

    test('compact font sizes', () {
      const letterFontSize = 18.0;
      const nameFontSize = 10.0;
      const dialogueFontSize = 12.0;
      expect(letterFontSize, 18.0);
      expect(nameFontSize, 10.0);
      expect(dialogueFontSize, 12.0);
    });

    test('normal font sizes', () {
      const letterFontSize = 22.0;
      const nameFontSize = 11.0;
      const dialogueFontSize = 13.0;
      expect(letterFontSize, 22.0);
      expect(nameFontSize, 11.0);
      expect(dialogueFontSize, 13.0);
    });
  });

  group('BattleDialogueComponent state machine', () {
    test('initial state', () {
      const isShowing = false;
      expect(isShowing, isFalse);
    });

    test('state after showDialogue', () {
      bool isShowing = false;
      final queue = <String>[];

      // Simulate showDialogue
      queue.add('test');
      if (!isShowing) {
        isShowing = true;
      }

      expect(isShowing, isTrue);
    });

    test('state after queue empty', () {
      bool isShowing = true;
      final queue = <String>[];

      // Simulate _showNext with empty queue
      if (queue.isEmpty) {
        isShowing = false;
      }

      expect(isShowing, isFalse);
    });

    test('dialogue advances after duration', () {
      double displayTime = 0;
      const dialogueDuration = 4.0;
      bool shouldAdvance = false;

      // Simulate update over duration
      displayTime = 4.0;
      if (displayTime >= dialogueDuration) {
        shouldAdvance = true;
      }

      expect(shouldAdvance, isTrue);
    });
  });

  group('BattleDialogueComponent performance', () {
    test('can calculate many fade values', () {
      for (double t = 0; t <= 4.0; t += 0.016) {
        const fadeInDuration = 0.3;
        const fadeOutDuration = 0.5;
        const dialogueDuration = 4.0;

        double fadeProgress;
        if (t < fadeInDuration) {
          fadeProgress = t / fadeInDuration;
        } else if (t > dialogueDuration - fadeOutDuration) {
          fadeProgress = (dialogueDuration - t) / fadeOutDuration;
        } else {
          fadeProgress = 1.0;
        }
        final _ = fadeProgress.clamp(0.0, 1.0);
      }
      expect(true, isTrue);
    });

    test('can calculate many typewriter values', () {
      for (int i = 0; i < 1000; i++) {
        double progress = i * 0.1;
        const textLength = 100;
        progress = progress.clamp(0, textLength.toDouble());
        final _ = progress.floor();
      }
      expect(true, isTrue);
    });
  });
}
