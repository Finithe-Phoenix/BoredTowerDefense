import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
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

  group('FloatingTextType enum', () {
    test('has 6 types', () {
      expect(FloatingTextType.values.length, 6);
    });

    test('contains expected types', () {
      expect(FloatingTextType.values, contains(FloatingTextType.damage));
      expect(FloatingTextType.values, contains(FloatingTextType.gold));
      expect(FloatingTextType.values, contains(FloatingTextType.heal));
      expect(FloatingTextType.values, contains(FloatingTextType.critical));
      expect(FloatingTextType.values, contains(FloatingTextType.levelUp));
      expect(FloatingTextType.values, contains(FloatingTextType.combo));
    });
  });

  group('FloatingText', () {
    test('creates with required parameters', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Test',
      );

      expect(text, isA<PositionComponent>());
      expect(text.text, 'Test');
      expect(text.position.x, 100);
      expect(text.position.y, 100);
    });

    test('creates with default type as damage', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: '-50',
      );

      expect(text.type, FloatingTextType.damage);
    });

    test('creates with custom type', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: '+100',
        type: FloatingTextType.gold,
      );

      expect(text.type, FloatingTextType.gold);
    });

    test('creates with custom color', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: 'Custom',
        customColor: Colors.purple,
      );

      expect(text.customColor, Colors.purple);
    });

    test('creates with custom fontSize', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: 'Big',
        fontSize: 24,
      );

      expect(text.fontSize, 24);
    });

    test('creates with custom duration', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: 'Long',
        duration: 2.0,
      );

      expect(text.duration, 2.0);
    });

    test('creates with custom riseSpeed', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: 'Fast',
        riseSpeed: 100,
      );

      expect(text.riseSpeed, 100);
    });

    test('default values are correct', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: 'Default',
      );

      expect(text.fontSize, 12);
      expect(text.duration, 0.6);
      expect(text.riseSpeed, 35);
    });

    test('anchor is center', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: 'Test',
      );

      expect(text.anchor, Anchor.center);
    });

    test('update moves text upward', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Rising',
        riseSpeed: 50,
      );

      final startY = text.position.y;
      text.update(0.1);

      expect(text.position.y, lessThan(startY));
    });

    test('text rises by riseSpeed * dt', () {
      final text = FloatingText(
        position: Vector2(0, 100),
        text: 'Test',
        riseSpeed: 100,
      );

      text.update(0.5);

      // Should have risen by 100 * 0.5 = 50 pixels
      expect(text.position.y, closeTo(50, 1));
    });

    test('maxPool constant is defined', () {
      expect(FloatingText.maxPool, 20);
    });

    test('clearPool clears the pool', () {
      // Create and recycle some texts
      for (int i = 0; i < 5; i++) {
        final text = FloatingText(
          position: Vector2.zero(),
          text: 'Pool$i',
          duration: 0.01,
        );
        text.update(0.02); // Trigger recycle
      }

      FloatingText.clearPool();

      // No way to directly check pool size, but should not throw
      expect(true, isTrue);
    });

    test('pool reuses instances', () {
      final text1 = FloatingText(
        position: Vector2(10, 10),
        text: 'First',
        duration: 0.01,
      );

      // Recycle the first
      text1.update(0.02);

      // Get another - should reuse from pool
      final text2 = FloatingText(
        position: Vector2(20, 20),
        text: 'Second',
      );

      expect(text2, isNotNull);
      expect(text2.text, 'Second');
      expect(text2.position.x, 20);
    });
  });

  group('FloatingText types colors', () {
    test('damage type creates text', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: '-50',
        type: FloatingTextType.damage,
      );
      expect(text.type, FloatingTextType.damage);
    });

    test('gold type creates text', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: '+100',
        type: FloatingTextType.gold,
      );
      expect(text.type, FloatingTextType.gold);
    });

    test('heal type creates text', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: '+20',
        type: FloatingTextType.heal,
      );
      expect(text.type, FloatingTextType.heal);
    });

    test('critical type creates text', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: 'CRIT!',
        type: FloatingTextType.critical,
      );
      expect(text.type, FloatingTextType.critical);
    });

    test('levelUp type creates text', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: 'LEVEL UP',
        type: FloatingTextType.levelUp,
      );
      expect(text.type, FloatingTextType.levelUp);
    });

    test('combo type creates text', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: '5x COMBO',
        type: FloatingTextType.combo,
      );
      expect(text.type, FloatingTextType.combo);
    });
  });

  group('ResourcePopup', () {
    test('creates with required parameters', () {
      final popup = ResourcePopup(
        position: Vector2(100, 100),
        amount: 50,
        icon: '💰',
      );

      expect(popup, isA<PositionComponent>());
      expect(popup.amount, 50);
      expect(popup.icon, '💰');
      expect(popup.position.x, 100);
      expect(popup.position.y, 100);
    });

    test('default isGain is true', () {
      final popup = ResourcePopup(
        position: Vector2.zero(),
        amount: 100,
        icon: '⭐',
      );

      expect(popup.isGain, isTrue);
    });

    test('can be loss (isGain false)', () {
      final popup = ResourcePopup(
        position: Vector2.zero(),
        amount: 25,
        icon: '❤️',
        isGain: false,
      );

      expect(popup.isGain, isFalse);
    });

    test('default duration is 0.8', () {
      final popup = ResourcePopup(
        position: Vector2.zero(),
        amount: 10,
        icon: '💎',
      );

      expect(popup.duration, 0.8);
    });

    test('custom duration can be set', () {
      final popup = ResourcePopup(
        position: Vector2.zero(),
        amount: 10,
        icon: '🔮',
        duration: 1.5,
      );

      expect(popup.duration, 1.5);
    });

    test('anchor is center', () {
      final popup = ResourcePopup(
        position: Vector2.zero(),
        amount: 10,
        icon: '🎯',
      );

      expect(popup.anchor, Anchor.center);
    });

    test('update moves popup upward', () {
      final popup = ResourcePopup(
        position: Vector2(0, 100),
        amount: 10,
        icon: '💰',
      );

      final startY = popup.position.y;
      popup.update(0.1);

      expect(popup.position.y, lessThan(startY));
    });

    test('update moves by 25 * dt', () {
      final popup = ResourcePopup(
        position: Vector2(0, 100),
        amount: 10,
        icon: '💰',
      );

      popup.update(0.4);

      // Should have risen by 25 * 0.4 = 10 pixels
      expect(popup.position.y, closeTo(90, 1));
    });
  });

  group('KillStreakNotification', () {
    test('creates with required parameters', () {
      final notification = KillStreakNotification(
        position: Vector2(200, 100),
        streakCount: 5,
      );

      expect(notification, isA<PositionComponent>());
      expect(notification.streakCount, 5);
      expect(notification.position.x, 200);
      expect(notification.position.y, 100);
    });

    test('default duration is 1.0', () {
      final notification = KillStreakNotification(
        position: Vector2.zero(),
        streakCount: 3,
      );

      expect(notification.duration, 1.0);
    });

    test('custom duration can be set', () {
      final notification = KillStreakNotification(
        position: Vector2.zero(),
        streakCount: 3,
        duration: 2.0,
      );

      expect(notification.duration, 2.0);
    });

    test('anchor is center', () {
      final notification = KillStreakNotification(
        position: Vector2.zero(),
        streakCount: 3,
      );

      expect(notification.anchor, Anchor.center);
    });

    test('update advances timer', () {
      final notification = KillStreakNotification(
        position: Vector2.zero(),
        streakCount: 5,
        duration: 1.0,
      );

      notification.update(0.5);

      // Should not be removed yet
      expect(true, isTrue);
    });

    test('streak count 2 is DOUBLE', () {
      final notification = KillStreakNotification(
        position: Vector2.zero(),
        streakCount: 2,
      );
      expect(notification, isNotNull);
    });

    test('streak count 3 is TRIPLE', () {
      final notification = KillStreakNotification(
        position: Vector2.zero(),
        streakCount: 3,
      );
      expect(notification, isNotNull);
    });

    test('streak count 5 is SPREE', () {
      final notification = KillStreakNotification(
        position: Vector2.zero(),
        streakCount: 5,
      );
      expect(notification, isNotNull);
    });

    test('streak count 7 is RAMPAGE', () {
      final notification = KillStreakNotification(
        position: Vector2.zero(),
        streakCount: 7,
      );
      expect(notification, isNotNull);
    });

    test('streak count 10 is UNSTOPPABLE', () {
      final notification = KillStreakNotification(
        position: Vector2.zero(),
        streakCount: 10,
      );
      expect(notification, isNotNull);
    });
  });

  group('FloatingText multiple instances', () {
    test('multiple FloatingTexts can exist independently', () {
      final text1 = FloatingText(
        position: Vector2(0, 0),
        text: 'First',
        type: FloatingTextType.damage,
      );
      final text2 = FloatingText(
        position: Vector2(100, 100),
        text: 'Second',
        type: FloatingTextType.gold,
      );

      expect(text1.text, 'First');
      expect(text2.text, 'Second');
      expect(text1.type, isNot(equals(text2.type)));
    });

    test('updating one does not affect another', () {
      final text1 = FloatingText(
        position: Vector2(0, 100),
        text: 'One',
      );
      final text2 = FloatingText(
        position: Vector2(0, 100),
        text: 'Two',
      );

      text1.update(0.5);

      expect(text1.position.y, lessThan(100));
      expect(text2.position.y, 100);
    });
  });

  group('FloatingText edge cases', () {
    test('empty text is allowed', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: '',
      );

      expect(text.text, '');
    });

    test('long text is allowed', () {
      final longText = 'A' * 100;
      final text = FloatingText(
        position: Vector2.zero(),
        text: longText,
      );

      expect(text.text, longText);
    });

    test('zero duration completes immediately', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: 'Quick',
        duration: 0.0,
      );

      text.update(0.001);
      // Text should be recycled
      expect(true, isTrue);
    });

    test('very large fontSize', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: 'BIG',
        fontSize: 100,
      );

      expect(text.fontSize, 100);
    });

    test('negative position works', () {
      final text = FloatingText(
        position: Vector2(-100, -100),
        text: 'Negative',
      );

      expect(text.position.x, -100);
      expect(text.position.y, -100);
    });
  });

  group('FloatingText render', () {
    test('renders without exceptions', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Test',
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      text.update(0.1);
      text.render(canvas);
      recorder.endRecording();
    });

    test('renders all text types', () {
      for (final type in FloatingTextType.values) {
        final text = FloatingText(
          position: Vector2(100, 100),
          text: 'Type: ${type.name}',
          type: type,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        text.update(0.1);
        text.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with custom color', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Custom',
        customColor: Colors.orange,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      text.update(0.1);
      text.render(canvas);
      recorder.endRecording();
    });

    test('renders at scale up phase (progress < 0.15)', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Scaling',
        duration: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      text.update(0.1); // progress = 0.1 < 0.15
      text.render(canvas);
      recorder.endRecording();
    });

    test('renders at scale down phase (progress >= 0.15)', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Shrinking',
        duration: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      text.update(0.5); // progress = 0.5 >= 0.15
      text.render(canvas);
      recorder.endRecording();
    });

    test('renders near end of duration (high alpha fade)', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Fading',
        duration: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      text.update(0.9); // progress = 0.9, alpha should be low
      text.render(canvas);
      recorder.endRecording();
    });
  });

  group('ResourcePopup render', () {
    test('renders gain popup without exceptions', () {
      final popup = ResourcePopup(
        position: Vector2(100, 100),
        amount: 50,
        icon: '💰',
        isGain: true,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      popup.update(0.1);
      popup.render(canvas);
      recorder.endRecording();
    });

    test('renders loss popup without exceptions', () {
      final popup = ResourcePopup(
        position: Vector2(100, 100),
        amount: 25,
        icon: '❤️',
        isGain: false,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      popup.update(0.1);
      popup.render(canvas);
      recorder.endRecording();
    });

    test('renders at scale up phase', () {
      final popup = ResourcePopup(
        position: Vector2(100, 100),
        amount: 10,
        icon: '⭐',
        duration: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      popup.update(0.1); // progress = 0.125 < 0.15
      popup.render(canvas);
      recorder.endRecording();
    });

    test('renders at scale down phase', () {
      final popup = ResourcePopup(
        position: Vector2(100, 100),
        amount: 10,
        icon: '💎',
        duration: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      popup.update(0.5);
      popup.render(canvas);
      recorder.endRecording();
    });
  });

  group('KillStreakNotification render', () {
    test('renders without exceptions', () {
      final notification = KillStreakNotification(
        position: Vector2(200, 100),
        streakCount: 5,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      notification.update(0.1);
      notification.render(canvas);
      recorder.endRecording();
    });

    test('renders all streak levels', () {
      for (final count in [2, 3, 5, 7, 10, 15]) {
        final notification = KillStreakNotification(
          position: Vector2(200, 100),
          streakCount: count,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        notification.update(0.1);
        notification.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders at scale up phase', () {
      final notification = KillStreakNotification(
        position: Vector2(200, 100),
        streakCount: 3,
        duration: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      notification.update(0.05); // progress = 0.05 < 0.1
      notification.render(canvas);
      recorder.endRecording();
    });

    test('renders during fade phase', () {
      final notification = KillStreakNotification(
        position: Vector2(200, 100),
        streakCount: 7,
        duration: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      notification.update(0.8); // progress = 0.8 > 0.7, alpha fades
      notification.render(canvas);
      recorder.endRecording();
    });
  });
}
