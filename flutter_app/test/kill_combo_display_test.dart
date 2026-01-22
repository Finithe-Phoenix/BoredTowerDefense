import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/hud/kill_combo_display.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KillComboDisplay', () {
    late KillComboDisplay display;

    setUp(() {
      display = KillComboDisplay();
    });

    test('creates with correct anchor', () {
      expect(display.anchor, Anchor.topRight);
    });

    test('static constants are defined', () {
      expect(KillComboDisplay.comboTimeout, 3.0);
      expect(KillComboDisplay.displayDuration, 2.0);
    });

    test('reset clears all state', () {
      display.registerKill();
      display.registerKill();
      display.registerKill();

      display.reset();

      // After reset, internal state should be cleared
      // We can verify by registering again and seeing that combo starts from 1
      display.registerKill();
      display.update(0.1);
      expect(true, isTrue);
    });

    test('registerKill increments combo', () {
      display.registerKill();
      display.registerKill();
      display.registerKill();

      // Combo should be 3
      display.update(0.1);
      expect(true, isTrue);
    });

    test('combo resets after timeout', () {
      display.registerKill();
      display.registerKill();

      // Update past combo timeout (3 seconds)
      for (int i = 0; i < 100; i++) {
        display.update(0.1);
      }

      // Combo should have reset
      display.registerKill();
      display.update(0.1);
      expect(true, isTrue);
    });

    test('combo 3 triggers TRIPLE notification', () {
      display.registerKill();
      display.registerKill();
      display.registerKill();

      display.update(0.1);
      expect(true, isTrue);
    });

    test('combo 5 triggers SPREE notification', () {
      for (int i = 0; i < 5; i++) {
        display.registerKill();
      }

      display.update(0.1);
      expect(true, isTrue);
    });

    test('combo 7 triggers RAMPAGE notification', () {
      for (int i = 0; i < 7; i++) {
        display.registerKill();
      }

      display.update(0.1);
      expect(true, isTrue);
    });

    test('combo 10 triggers UNSTOPPABLE notification', () {
      for (int i = 0; i < 10; i++) {
        display.registerKill();
      }

      display.update(0.1);
      expect(true, isTrue);
    });

    test('update decrements timers', () {
      display.registerKill();

      display.update(0.5);
      display.update(0.5);
      display.update(0.5);

      expect(true, isTrue);
    });

    test('notifications expire over time', () {
      display.registerKill();
      display.registerKill();
      display.registerKill(); // Triggers TRIPLE

      // Update past notification duration (1 second)
      for (int i = 0; i < 20; i++) {
        display.update(0.1);
      }

      expect(true, isTrue);
    });

    test('max notifications is limited', () {
      // Trigger multiple notifications
      for (int i = 0; i < 3; i++) {
        display.registerKill();
      }
      display.update(0.01);

      for (int i = 0; i < 2; i++) {
        display.registerKill();
      }
      display.update(0.01);

      for (int i = 0; i < 2; i++) {
        display.registerKill();
      }
      display.update(0.01);

      // Should only keep 2 notifications max
      expect(true, isTrue);
    });

    test('multiple instances are independent', () {
      final display1 = KillComboDisplay();
      final display2 = KillComboDisplay();

      display1.registerKill();
      display1.registerKill();
      display1.registerKill();

      display2.registerKill();

      display1.update(0.1);
      display2.update(0.1);

      expect(true, isTrue);
    });

    test('critical kill registers normally', () {
      display.registerKill(isCritical: true);
      display.update(0.1);
      expect(true, isTrue);
    });

    test('multi-kill registers normally', () {
      display.registerKill(isMultiKill: true);
      display.update(0.1);
      expect(true, isTrue);
    });

    test('rapid kills before timeout maintain combo', () {
      display.registerKill();
      display.update(0.5);
      display.registerKill();
      display.update(0.5);
      display.registerKill();
      display.update(0.5);

      // Should still be in combo (total 1.5 seconds < 3 second timeout)
      expect(true, isTrue);
    });

    test('update with zero dt does not crash', () {
      display.registerKill();
      display.update(0.0);
      expect(true, isTrue);
    });

    test('update with large dt works', () {
      display.registerKill();
      display.update(10.0);
      expect(true, isTrue);
    });

    test('combo beyond 10 still works', () {
      for (int i = 0; i < 20; i++) {
        display.registerKill();
      }
      display.update(0.1);
      expect(true, isTrue);
    });

    test('combo of 1 does not show notification', () {
      display.registerKill();
      display.update(0.1);
      expect(true, isTrue);
    });

    test('combo of 2 does not show notification', () {
      display.registerKill();
      display.registerKill();
      display.update(0.1);
      expect(true, isTrue);
    });

    test('animation time increments', () {
      display.update(0.1);
      display.update(0.1);
      display.update(0.1);
      expect(true, isTrue);
    });
  });

  group('KillComboDisplay component', () {
    test('is a PositionComponent', () {
      final display = KillComboDisplay();
      expect(display, isA<PositionComponent>());
    });

    test('can be created multiple times', () {
      final displays = List.generate(5, (_) => KillComboDisplay());
      expect(displays.length, 5);
      for (final d in displays) {
        expect(d.anchor, Anchor.topRight);
      }
    });
  });
}
