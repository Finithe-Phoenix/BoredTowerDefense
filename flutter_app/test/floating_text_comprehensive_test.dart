import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/floating_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FloatingTextType enum', () {
    test('has 6 text types', () {
      expect(FloatingTextType.values.length, 6);
    });

    test('contains damage', () {
      expect(FloatingTextType.values, contains(FloatingTextType.damage));
    });

    test('contains gold', () {
      expect(FloatingTextType.values, contains(FloatingTextType.gold));
    });

    test('contains heal', () {
      expect(FloatingTextType.values, contains(FloatingTextType.heal));
    });

    test('contains critical', () {
      expect(FloatingTextType.values, contains(FloatingTextType.critical));
    });

    test('contains levelUp', () {
      expect(FloatingTextType.values, contains(FloatingTextType.levelUp));
    });

    test('contains combo', () {
      expect(FloatingTextType.values, contains(FloatingTextType.combo));
    });

    test('damage is index 0', () {
      expect(FloatingTextType.damage.index, 0);
    });

    test('gold is index 1', () {
      expect(FloatingTextType.gold.index, 1);
    });

    test('heal is index 2', () {
      expect(FloatingTextType.heal.index, 2);
    });

    test('critical is index 3', () {
      expect(FloatingTextType.critical.index, 3);
    });

    test('levelUp is index 4', () {
      expect(FloatingTextType.levelUp.index, 4);
    });

    test('combo is index 5', () {
      expect(FloatingTextType.combo.index, 5);
    });
  });

  group('FloatingText static constants', () {
    test('maxPool is 20', () {
      expect(FloatingText.maxPool, 20);
    });
  });

  group('FloatingText pool management', () {
    setUp(() {
      FloatingText.clearPool();
    });

    test('clearPool can be called', () {
      expect(() => FloatingText.clearPool(), returnsNormally);
    });

    test('clearPool can be called multiple times', () {
      FloatingText.clearPool();
      FloatingText.clearPool();
      FloatingText.clearPool();
      expect(true, isTrue);
    });
  });

  group('FloatingText creation', () {
    setUp(() {
      FloatingText.clearPool();
    });

    test('can create FloatingText with minimum parameters', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '10',
      );

      expect(text, isNotNull);
      expect(text, isA<FloatingText>());
    });

    test('can create FloatingText with all parameters', () {
      final text = FloatingText(
        position: Vector2(50, 50),
        text: '+100',
        type: FloatingTextType.gold,
        customColor: Colors.yellow,
        fontSize: 16,
        duration: 1.0,
        riseSpeed: 50,
      );

      expect(text, isNotNull);
      expect(text.text, '+100');
      expect(text.type, FloatingTextType.gold);
      expect(text.fontSize, 16);
      expect(text.duration, 1.0);
      expect(text.riseSpeed, 50);
    });

    test('default type is damage', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '25',
      );

      expect(text.type, FloatingTextType.damage);
    });

    test('default fontSize is 12', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '25',
      );

      expect(text.fontSize, 12);
    });

    test('default duration is 0.6', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '25',
      );

      expect(text.duration, 0.6);
    });

    test('default riseSpeed is 35', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '25',
      );

      expect(text.riseSpeed, 35);
    });

    test('anchor is center', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '25',
      );

      expect(text.anchor, Anchor.center);
    });
  });

  group('FloatingText per-type creation', () {
    setUp(() {
      FloatingText.clearPool();
    });

    test('damage text', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '-50',
        type: FloatingTextType.damage,
      );

      expect(text.type, FloatingTextType.damage);
    });

    test('gold text', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '+10',
        type: FloatingTextType.gold,
      );

      expect(text.type, FloatingTextType.gold);
    });

    test('heal text', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '+25',
        type: FloatingTextType.heal,
      );

      expect(text.type, FloatingTextType.heal);
    });

    test('critical text', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'CRIT!',
        type: FloatingTextType.critical,
      );

      expect(text.type, FloatingTextType.critical);
    });

    test('levelUp text', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'LEVEL UP!',
        type: FloatingTextType.levelUp,
      );

      expect(text.type, FloatingTextType.levelUp);
    });

    test('combo text', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'x5 COMBO',
        type: FloatingTextType.combo,
      );

      expect(text.type, FloatingTextType.combo);
    });
  });

  group('FloatingText update behavior', () {
    setUp(() {
      FloatingText.clearPool();
    });

    test('update with zero delta time works', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '10',
      );

      expect(() => text.update(0), returnsNormally);
    });

    test('update with small delta time works', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '10',
      );

      expect(() => text.update(0.016), returnsNormally);
    });

    test('text rises upward over time', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '10',
        riseSpeed: 35,
      );

      final initialY = text.position.y;

      for (int i = 0; i < 10; i++) {
        text.update(0.016);
      }

      expect(text.position.y, lessThan(initialY));
    });

    test('multiple updates accumulate movement', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '10',
        riseSpeed: 50,
      );

      final initialY = text.position.y;

      for (int i = 0; i < 30; i++) {
        text.update(0.016);
      }

      // After ~0.5 seconds at 50 speed, should have risen ~25 units
      expect(text.position.y, lessThan(initialY - 10));
    });
  });

  group('FloatingText with custom colors', () {
    setUp(() {
      FloatingText.clearPool();
    });

    test('can set custom color for damage', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '-100',
        type: FloatingTextType.damage,
        customColor: Colors.red,
      );

      expect(text.customColor, Colors.red);
    });

    test('can set custom color for gold', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '+50',
        type: FloatingTextType.gold,
        customColor: const Color(0xFFFFD700),
      );

      expect(text.customColor, const Color(0xFFFFD700));
    });

    test('can set custom color for heal', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '+30',
        type: FloatingTextType.heal,
        customColor: Colors.green,
      );

      expect(text.customColor, Colors.green);
    });
  });

  group('FloatingText fontSize variations', () {
    setUp(() {
      FloatingText.clearPool();
    });

    test('small font size', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '5',
        fontSize: 8,
      );

      expect(text.fontSize, 8);
    });

    test('medium font size', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '50',
        fontSize: 14,
      );

      expect(text.fontSize, 14);
    });

    test('large font size', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '100',
        fontSize: 24,
      );

      expect(text.fontSize, 24);
    });

    test('very large font size for level up', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'LEVEL UP!',
        type: FloatingTextType.levelUp,
        fontSize: 32,
      );

      expect(text.fontSize, 32);
    });
  });

  group('FloatingText duration variations', () {
    setUp(() {
      FloatingText.clearPool();
    });

    test('short duration', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Quick!',
        duration: 0.3,
      );

      expect(text.duration, 0.3);
    });

    test('medium duration', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Medium',
        duration: 1.0,
      );

      expect(text.duration, 1.0);
    });

    test('long duration', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Long lasting',
        duration: 3.0,
      );

      expect(text.duration, 3.0);
    });
  });

  group('FloatingText riseSpeed variations', () {
    setUp(() {
      FloatingText.clearPool();
    });

    test('slow rise speed', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Slow',
        riseSpeed: 20,
      );

      expect(text.riseSpeed, 20);
    });

    test('fast rise speed', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Fast!',
        riseSpeed: 80,
      );

      expect(text.riseSpeed, 80);
    });

    test('very fast rise speed for critical', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'CRIT!',
        type: FloatingTextType.critical,
        riseSpeed: 100,
      );

      expect(text.riseSpeed, 100);
    });
  });

  group('FloatingText performance', () {
    setUp(() {
      FloatingText.clearPool();
    });

    test('can create many floating texts', () {
      final texts = <FloatingText>[];

      for (int i = 0; i < 50; i++) {
        texts.add(FloatingText(
          position: Vector2(i.toDouble() * 10, 100),
          text: '$i',
        ));
      }

      expect(texts.length, 50);
    });

    test('can update many floating texts', () {
      final texts = List.generate(30, (i) => FloatingText(
        position: Vector2(i.toDouble() * 10, 100),
        text: '$i',
      ));

      for (int frame = 0; frame < 30; frame++) {
        for (final text in texts) {
          text.update(0.016);
        }
      }

      expect(true, isTrue);
    });
  });

  group('FloatingText edge cases', () {
    setUp(() {
      FloatingText.clearPool();
    });

    test('handles empty text', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '',
      );

      expect(text.text, '');
      expect(() => text.update(0.016), returnsNormally);
    });

    test('handles very long text', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'This is a very long floating text message!',
      );

      expect(text.text, 'This is a very long floating text message!');
    });

    test('handles special characters', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '+1,000,000',
      );

      expect(text.text, '+1,000,000');
    });

    test('handles unicode characters', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: '⚡ POWER UP ⚡',
      );

      expect(text.text, '⚡ POWER UP ⚡');
    });

    test('handles zero position', () {
      final text = FloatingText(
        position: Vector2.zero(),
        text: 'Zero',
      );

      expect(text.position.x, 0);
      expect(text.position.y, 0);
    });

    test('handles negative position', () {
      final text = FloatingText(
        position: Vector2(-50, -50),
        text: 'Negative',
      );

      expect(text.position.x, -50);
      expect(text.position.y, -50);
    });

    test('handles zero riseSpeed', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Static',
        riseSpeed: 0,
      );

      final initialY = text.position.y;
      text.update(0.5);

      // Should not move vertically
      expect(text.position.y, initialY);
    });

    test('handles negative riseSpeed (sinking)', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Sink',
        riseSpeed: -35,
      );

      final initialY = text.position.y;
      text.update(0.1);

      // Should move downward
      expect(text.position.y, greaterThan(initialY));
    });
  });

  group('FloatingText lifecycle', () {
    setUp(() {
      FloatingText.clearPool();
    });

    test('onRemove can be called', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Test',
      );

      expect(() => text.onRemove(), returnsNormally);
    });

    test('onRemove can be called multiple times', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Test',
      );

      text.onRemove();
      text.onRemove();
      text.onRemove();

      expect(true, isTrue);
    });

    test('update after onRemove works', () {
      final text = FloatingText(
        position: Vector2(100, 100),
        text: 'Test',
      );

      text.onRemove();
      expect(() => text.update(0.016), returnsNormally);
    });
  });
}
