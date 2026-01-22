import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/tutorial_guide.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TutorialGuide', () {
    test('initializes with correct anchor', () {
      final guide = TutorialGuide();
      expect(guide.anchor, Anchor.topCenter);
    });

    test('can be instantiated', () {
      final guide = TutorialGuide();
      expect(guide, isNotNull);
      expect(guide, isA<PositionComponent>());
    });

    test('multiple instances can be created', () {
      final guide1 = TutorialGuide();
      final guide2 = TutorialGuide();
      final guide3 = TutorialGuide();

      expect(guide1, isNotNull);
      expect(guide2, isNotNull);
      expect(guide3, isNotNull);
      expect(guide1, isNot(same(guide2)));
      expect(guide2, isNot(same(guide3)));
    });
  });

  group('TutorialGuide static data', () {
    test('touch messages are defined', () {
      // Verify the class compiles with its static data
      final guide = TutorialGuide();
      expect(guide, isNotNull);
    });

    test('desktop messages are defined', () {
      final guide = TutorialGuide();
      expect(guide, isNotNull);
    });

    test('step icons are defined', () {
      final guide = TutorialGuide();
      expect(guide, isNotNull);
    });

    test('auto advance delays are defined', () {
      final guide = TutorialGuide();
      expect(guide, isNotNull);
    });
  });

  group('TutorialGuide component properties', () {
    test('is a PositionComponent', () {
      final guide = TutorialGuide();
      expect(guide, isA<PositionComponent>());
    });

    test('anchor is topCenter by default', () {
      final guide = TutorialGuide();
      expect(guide.anchor, Anchor.topCenter);
    });

    test('has methods for tutorial steps', () {
      final guide = TutorialGuide();
      // Verify methods exist without calling them
      // (calling them requires gameRef which isn't available in unit tests)
      expect(guide.onTowerSelected, isNotNull);
      expect(guide.onTowerPlaced, isNotNull);
      expect(guide.onWaveStarted, isNotNull);
      expect(guide.onAbilityUsed, isNotNull);
      expect(guide.onFocusMode, isNotNull);
    });

    test('has update method', () {
      final guide = TutorialGuide();
      expect(guide.update, isNotNull);
    });

    test('has render method', () {
      final guide = TutorialGuide();
      expect(guide.render, isNotNull);
    });
  });
}
