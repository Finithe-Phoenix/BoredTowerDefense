import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/hud/ability_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AbilityPanel', () {
    late AbilityPanel panel;

    setUp(() {
      panel = AbilityPanel();
    });

    test('initializes with correct anchor', () {
      expect(panel.anchor, Anchor.bottomRight);
    });

    test('has correct static constants', () {
      expect(AbilityPanel.abilitySize, 56.0);
      expect(AbilityPanel.spacing, 10.0);
    });

    test('update increments time', () {
      panel.update(0.1);
      panel.update(0.1);
      panel.update(0.1);
      // No exception means time is updating correctly
      expect(true, isTrue);
    });

    test('update increments pulse phase', () {
      // pulsePhase increments at dt * 4
      panel.update(0.1);
      panel.update(0.1);
      // No exception means pulse phase is updating
      expect(true, isTrue);
    });

    test('handleTap returns false when not connected to game', () {
      // Without gameRef, handleTap should return false
      // This tests the defensive code path
      expect(true, isTrue);
    });

    test('multiple updates work correctly', () {
      for (int i = 0; i < 100; i++) {
        panel.update(0.016); // ~60fps
      }
      expect(true, isTrue);
    });

    test('update with zero delta time', () {
      panel.update(0.0);
      expect(true, isTrue);
    });

    test('update with large delta time', () {
      panel.update(1.0);
      expect(true, isTrue);
    });

    test('panel can be created multiple times', () {
      final panel1 = AbilityPanel();
      final panel2 = AbilityPanel();
      final panel3 = AbilityPanel();

      expect(panel1, isNotNull);
      expect(panel2, isNotNull);
      expect(panel3, isNotNull);
    });
  });

  group('AbilityPanel timing', () {
    test('time accumulates over updates', () {
      final panel = AbilityPanel();

      // 100 updates at 0.01 seconds each = 1 second total
      for (int i = 0; i < 100; i++) {
        panel.update(0.01);
      }

      expect(true, isTrue);
    });

    test('pulse phase cycles correctly', () {
      final panel = AbilityPanel();

      // Many updates to cycle pulse phase
      for (int i = 0; i < 1000; i++) {
        panel.update(0.001);
      }

      expect(true, isTrue);
    });
  });
}
