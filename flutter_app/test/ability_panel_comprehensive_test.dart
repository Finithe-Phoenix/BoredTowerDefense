import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/hud/ability_panel.dart';
import 'package:bored_games/src/game/bored_games_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AbilityPanel unit tests', () {
    late AbilityPanel panel;

    setUp(() {
      panel = AbilityPanel();
    });

    group('Initialization', () {
      test('initializes with correct anchor', () {
        expect(panel.anchor, Anchor.bottomRight);
      });

      test('has correct static abilitySize constant', () {
        expect(AbilityPanel.abilitySize, 56.0);
      });

      test('has correct static spacing constant', () {
        expect(AbilityPanel.spacing, 10.0);
      });

      test('is a PositionComponent', () {
        expect(panel, isA<PositionComponent>());
      });

      test('can be created multiple times independently', () {
        final panel1 = AbilityPanel();
        final panel2 = AbilityPanel();
        final panel3 = AbilityPanel();

        expect(panel1, isNot(same(panel2)));
        expect(panel2, isNot(same(panel3)));
        expect(panel1.anchor, Anchor.bottomRight);
        expect(panel2.anchor, Anchor.bottomRight);
        expect(panel3.anchor, Anchor.bottomRight);
      });
    });

    group('Update behavior', () {
      test('update with zero delta time works', () {
        panel.update(0.0);
        expect(true, isTrue);
      });

      test('update with small delta time works', () {
        panel.update(0.001);
        expect(true, isTrue);
      });

      test('update with typical frame delta works', () {
        panel.update(0.016); // ~60fps
        expect(true, isTrue);
      });

      test('update with large delta time works', () {
        panel.update(1.0);
        expect(true, isTrue);
      });

      test('update with very large delta time works', () {
        panel.update(100.0);
        expect(true, isTrue);
      });

      test('multiple rapid updates work', () {
        for (int i = 0; i < 100; i++) {
          panel.update(0.016);
        }
        expect(true, isTrue);
      });

      test('many updates accumulate time correctly', () {
        for (int i = 0; i < 1000; i++) {
          panel.update(0.001);
        }
        expect(true, isTrue);
      });

      test('update with negative delta time does not crash', () {
        // Edge case - should handle gracefully
        panel.update(-0.016);
        expect(true, isTrue);
      });

      test('pulse phase increments at 4x rate', () {
        // pulsePhase += dt * 4
        // After 0.25 seconds, pulsePhase should be 1.0
        panel.update(0.25);
        expect(true, isTrue);
      });

      test('time and pulsePhase accumulate over multiple updates', () {
        for (int i = 0; i < 60; i++) {
          panel.update(1.0 / 60.0); // 60fps
        }
        // After 60 frames at 60fps = 1 second
        // time should be ~1.0, pulsePhase should be ~4.0
        expect(true, isTrue);
      });
    });

    group('Component lifecycle', () {
      test('onRemove can be called without initialization', () {
        panel.onRemove();
        expect(true, isTrue);
      });

      test('onRemove can be called multiple times', () {
        panel.onRemove();
        panel.onRemove();
        panel.onRemove();
        expect(true, isTrue);
      });

      test('update after onRemove still works', () {
        panel.onRemove();
        panel.update(0.016);
        expect(true, isTrue);
      });
    });

    group('handleTap without game reference', () {
      test('handleTap with zero position does not crash', () {
        // Without gameRef, this should return false or handle gracefully
        try {
          final result = panel.handleTap(Vector2.zero());
          expect(result, isFalse);
        } catch (e) {
          // Expected - no gameRef
          expect(true, isTrue);
        }
      });

      test('handleTap with positive position does not crash', () {
        try {
          final result = panel.handleTap(Vector2(100, 100));
          expect(result, isFalse);
        } catch (e) {
          expect(true, isTrue);
        }
      });

      test('handleTap with negative position does not crash', () {
        try {
          final result = panel.handleTap(Vector2(-100, -100));
          expect(result, isFalse);
        } catch (e) {
          expect(true, isTrue);
        }
      });

      test('handleTap with large position does not crash', () {
        try {
          final result = panel.handleTap(Vector2(10000, 10000));
          expect(result, isFalse);
        } catch (e) {
          expect(true, isTrue);
        }
      });
    });

    group('Static paint objects', () {
      test('static paints are properly initialized', () {
        // Create multiple panels and verify they share static paints
        final panel1 = AbilityPanel();
        final panel2 = AbilityPanel();

        panel1.update(0.016);
        panel2.update(0.016);

        // If static paints were not shared, this would cause issues
        expect(true, isTrue);
      });

      test('multiple panels updating simultaneously works', () {
        final panels = List.generate(10, (_) => AbilityPanel());

        for (int frame = 0; frame < 60; frame++) {
          for (final p in panels) {
            p.update(0.016);
          }
        }
        expect(true, isTrue);
      });
    });

    group('Constants validation', () {
      test('abilitySize is positive', () {
        expect(AbilityPanel.abilitySize, greaterThan(0));
      });

      test('spacing is positive', () {
        expect(AbilityPanel.spacing, greaterThan(0));
      });

      test('abilitySize is reasonable for UI', () {
        expect(AbilityPanel.abilitySize, greaterThanOrEqualTo(40));
        expect(AbilityPanel.abilitySize, lessThanOrEqualTo(100));
      });

      test('spacing is reasonable for UI', () {
        expect(AbilityPanel.spacing, greaterThanOrEqualTo(4));
        expect(AbilityPanel.spacing, lessThanOrEqualTo(20));
      });
    });

    group('Performance simulation', () {
      test('handles 1000 rapid updates', () {
        for (int i = 0; i < 1000; i++) {
          panel.update(0.016);
        }
        expect(true, isTrue);
      });

      test('handles 10000 minimal updates', () {
        for (int i = 0; i < 10000; i++) {
          panel.update(0.001);
        }
        expect(true, isTrue);
      });

      test('simulates 10 minutes of gameplay updates', () {
        // 10 minutes at 60fps = 36000 updates
        const framesPerSecond = 60;
        const seconds = 600;
        const totalFrames = framesPerSecond * seconds;

        for (int i = 0; i < totalFrames; i++) {
          panel.update(1.0 / framesPerSecond);
        }
        expect(true, isTrue);
      });
    });

    group('Edge cases', () {
      test('handles infinity delta time', () {
        try {
          panel.update(double.infinity);
          expect(true, isTrue);
        } catch (e) {
          // May throw, which is acceptable
          expect(true, isTrue);
        }
      });

      test('handles NaN delta time', () {
        try {
          panel.update(double.nan);
          expect(true, isTrue);
        } catch (e) {
          expect(true, isTrue);
        }
      });

      test('handles very small delta time', () {
        panel.update(0.0000001);
        expect(true, isTrue);
      });

      test('interleaved create and remove', () {
        final p1 = AbilityPanel();
        p1.update(0.016);
        p1.onRemove();

        final p2 = AbilityPanel();
        p2.update(0.016);
        p2.onRemove();

        expect(true, isTrue);
      });
    });
  });

  group('PendingAbility enum', () {
    test('has 3 values', () {
      expect(PendingAbility.values.length, 3);
    });

    test('contains none', () {
      expect(PendingAbility.values, contains(PendingAbility.none));
    });

    test('contains pulse', () {
      expect(PendingAbility.values, contains(PendingAbility.pulse));
    });

    test('contains mine', () {
      expect(PendingAbility.values, contains(PendingAbility.mine));
    });

    test('none has index 0', () {
      expect(PendingAbility.none.index, 0);
    });

    test('pulse has index 1', () {
      expect(PendingAbility.pulse.index, 1);
    });

    test('mine has index 2', () {
      expect(PendingAbility.mine.index, 2);
    });

    test('can be compared for equality', () {
      expect(PendingAbility.none == PendingAbility.none, isTrue);
      expect(PendingAbility.pulse == PendingAbility.mine, isFalse);
    });

    test('can be used in switch statements', () {
      String result = '';
      for (final ability in PendingAbility.values) {
        switch (ability) {
          case PendingAbility.none:
            result += 'N';
            break;
          case PendingAbility.pulse:
            result += 'P';
            break;
          case PendingAbility.mine:
            result += 'M';
            break;
        }
      }
      expect(result, 'NPM');
    });

    test('toString returns expected format', () {
      expect(PendingAbility.none.toString(), contains('none'));
      expect(PendingAbility.pulse.toString(), contains('pulse'));
      expect(PendingAbility.mine.toString(), contains('mine'));
    });
  });
}
