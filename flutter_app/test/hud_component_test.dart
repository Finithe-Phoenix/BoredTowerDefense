import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/hud/hud_component.dart';

void main() {
  group('HudComponent', () {
    group('static layout constants', () {
      test('topBarHeight has default value', () {
        expect(HudComponent.topBarHeight, 60.0);
      });

      test('bottomBarHeight has default value', () {
        expect(HudComponent.bottomBarHeight, 20.0);
      });

      test('buttonHeight has default value', () {
        expect(HudComponent.buttonHeight, 44.0);
      });

      test('buttonSpacing has default value', () {
        expect(HudComponent.buttonSpacing, 12.0);
      });

      test('reduceFlicker is true by default', () {
        expect(HudComponent.reduceFlicker, isTrue);
      });
    });

    group('applyLayoutMetrics', () {
      setUp(() {
        // Reset to defaults before each test
        HudComponent.topBarHeight = 60.0;
        HudComponent.buttonHeight = 44.0;
        HudComponent.buttonSpacing = 12.0;
        HudComponent.bottomBarHeight = 20.0;
      });

      test('applies compact layout for small width', () {
        HudComponent.applyLayoutMetrics(
          width: 600,
          height: 800,
          compact: true,
        );

        expect(HudComponent.topBarHeight, 70.0);
        expect(HudComponent.buttonHeight, 38.0);
        expect(HudComponent.buttonSpacing, 10.0);
      });

      test('applies compact layout for short height', () {
        HudComponent.applyLayoutMetrics(
          width: 1200,
          height: 600,
          compact: false,
        );

        expect(HudComponent.topBarHeight, 60.0);
        expect(HudComponent.buttonHeight, 40.0);
        expect(HudComponent.buttonSpacing, 11.0);
      });

      test('applies normal layout for large screens', () {
        HudComponent.applyLayoutMetrics(
          width: 1920,
          height: 1080,
          compact: false,
        );

        expect(HudComponent.topBarHeight, 60.0);
        expect(HudComponent.buttonHeight, 44.0);
        expect(HudComponent.buttonSpacing, 12.0);
      });

      test('always sets bottomBarHeight to 20', () {
        HudComponent.applyLayoutMetrics(
          width: 800,
          height: 600,
          compact: true,
        );
        expect(HudComponent.bottomBarHeight, 20.0);

        HudComponent.applyLayoutMetrics(
          width: 1920,
          height: 1080,
          compact: false,
        );
        expect(HudComponent.bottomBarHeight, 20.0);
      });
    });

    group('speedOptions', () {
      test('contains expected speed values', () {
        expect(HudComponent.speedOptions, [1.0, 2.0]);
      });

      test('has 2 options', () {
        expect(HudComponent.speedOptions.length, 2);
      });

      test('first option is normal speed', () {
        expect(HudComponent.speedOptions.first, 1.0);
      });

      test('second option is double speed', () {
        expect(HudComponent.speedOptions.last, 2.0);
      });
    });
  });
}
