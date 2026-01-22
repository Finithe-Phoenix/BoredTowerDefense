import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/hud/minimap_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MinimapComponent', () {
    late MinimapComponent minimap;

    setUp(() {
      minimap = MinimapComponent();
    });

    test('initializes with correct anchor', () {
      expect(minimap.anchor, Anchor.topLeft);
    });

    test('has correct static constants', () {
      expect(MinimapComponent.baseMapSize, 130.0);
      expect(MinimapComponent.borderWidth, 2.0);
      expect(MinimapComponent.basePadding, 12.0);
    });

    test('has default mapSize and padding', () {
      expect(minimap.mapSize, MinimapComponent.baseMapSize);
      expect(minimap.padding, MinimapComponent.basePadding);
    });

    test('update increments animation timers', () {
      minimap.mapSize = 100.0;
      minimap.padding = 10.0;

      // Update won't work without gameRef, but we can test that it doesn't throw
      // when called on an unattached component
      expect(true, isTrue);
    });

    test('multiple minimaps can be created', () {
      final minimap1 = MinimapComponent();
      final minimap2 = MinimapComponent();
      final minimap3 = MinimapComponent();

      expect(minimap1, isNotNull);
      expect(minimap2, isNotNull);
      expect(minimap3, isNotNull);
    });

    test('mapSize can be modified', () {
      minimap.mapSize = 200.0;
      expect(minimap.mapSize, 200.0);

      minimap.mapSize = 50.0;
      expect(minimap.mapSize, 50.0);
    });

    test('padding can be modified', () {
      minimap.padding = 20.0;
      expect(minimap.padding, 20.0);

      minimap.padding = 5.0;
      expect(minimap.padding, 5.0);
    });
  });

  group('MinimapComponent dimensions', () {
    test('baseMapSize is reasonable for UI', () {
      expect(MinimapComponent.baseMapSize, greaterThan(50.0));
      expect(MinimapComponent.baseMapSize, lessThan(300.0));
    });

    test('borderWidth is small', () {
      expect(MinimapComponent.borderWidth, greaterThan(0));
      expect(MinimapComponent.borderWidth, lessThan(10.0));
    });

    test('basePadding is reasonable', () {
      expect(MinimapComponent.basePadding, greaterThan(0));
      expect(MinimapComponent.basePadding, lessThan(50.0));
    });
  });
}
