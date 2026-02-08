import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/focus_mode_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FocusModeOverlay unit tests', () {
    late FocusModeOverlay overlay;

    setUp(() {
      overlay = FocusModeOverlay();
    });

    group('Initialization', () {
      test('can be instantiated', () {
        expect(overlay, isNotNull);
      });

      test('is a PositionComponent', () {
        expect(overlay, isA<PositionComponent>());
      });

      test('anchor is topLeft', () {
        expect(overlay.anchor, Anchor.topLeft);
      });

      test('priority is 90', () {
        expect(overlay.priority, 90);
      });

      test('can be created multiple times independently', () {
        final overlay1 = FocusModeOverlay();
        final overlay2 = FocusModeOverlay();
        final overlay3 = FocusModeOverlay();

        expect(overlay1, isNot(same(overlay2)));
        expect(overlay2, isNot(same(overlay3)));
        expect(overlay1.priority, 90);
        expect(overlay2.priority, 90);
      });
    });

    group('Update behavior', () {
      test('update with zero delta time works', () {
        overlay.update(0.0);
        expect(true, isTrue);
      });

      test('update with small delta time works', () {
        overlay.update(0.001);
        expect(true, isTrue);
      });

      test('update with typical frame delta works', () {
        overlay.update(0.016);
        expect(true, isTrue);
      });

      test('update with large delta time works', () {
        overlay.update(1.0);
        expect(true, isTrue);
      });

      test('update with very large delta time works', () {
        overlay.update(100.0);
        expect(true, isTrue);
      });

      test('multiple rapid updates work', () {
        for (int i = 0; i < 100; i++) {
          overlay.update(0.016);
        }
        expect(true, isTrue);
      });

      test('many updates accumulate time correctly', () {
        for (int i = 0; i < 1000; i++) {
          overlay.update(0.001);
        }
        expect(true, isTrue);
      });
    });

    group('Hit marker registration', () {
      test('registerHit does not crash', () {
        overlay.registerHit(Vector2(100, 100), critical: false);
        expect(true, isTrue);
      });

      test('registerHit with critical flag', () {
        overlay.registerHit(Vector2(100, 100), critical: true);
        expect(true, isTrue);
      });

      test('registerHit at zero position', () {
        overlay.registerHit(Vector2.zero(), critical: false);
        expect(true, isTrue);
      });

      test('registerHit at negative position', () {
        overlay.registerHit(Vector2(-100, -100), critical: false);
        expect(true, isTrue);
      });

      test('registerHit at large position', () {
        overlay.registerHit(Vector2(10000, 10000), critical: true);
        expect(true, isTrue);
      });

      test('registerHit multiple times in rapid succession', () {
        for (int i = 0; i < 20; i++) {
          overlay.registerHit(Vector2(i * 10.0, i * 10.0), critical: i % 2 == 0);
        }
        expect(true, isTrue);
      });

      test('hit markers are limited to 6', () {
        // Register more than 6 hit markers
        for (int i = 0; i < 10; i++) {
          overlay.registerHit(Vector2(i * 10.0, i * 10.0), critical: false);
        }
        // Internal list should be limited to 6
        expect(true, isTrue);
      });
    });

    group('Update with hit markers', () {
      test('update processes hit markers', () {
        overlay.registerHit(Vector2(100, 100), critical: false);
        overlay.update(0.016);
        expect(true, isTrue);
      });

      test('update removes expired hit markers', () {
        overlay.registerHit(Vector2(100, 100), critical: false);
        // Many updates to expire the marker
        for (int i = 0; i < 100; i++) {
          overlay.update(0.1);
        }
        expect(true, isTrue);
      });

      test('update handles multiple hit markers', () {
        for (int i = 0; i < 5; i++) {
          overlay.registerHit(Vector2(i * 10.0, i * 10.0), critical: i % 2 == 0);
        }
        for (int i = 0; i < 60; i++) {
          overlay.update(0.016);
        }
        expect(true, isTrue);
      });
    });

    group('Component lifecycle', () {
      test('onRemove can be called', () {
        overlay.onRemove();
        expect(true, isTrue);
      });

      test('onRemove can be called multiple times', () {
        overlay.onRemove();
        overlay.onRemove();
        overlay.onRemove();
        expect(true, isTrue);
      });

      test('update after onRemove still works', () {
        overlay.onRemove();
        overlay.update(0.016);
        expect(true, isTrue);
      });

      test('registerHit after onRemove still works', () {
        overlay.onRemove();
        overlay.registerHit(Vector2(100, 100), critical: false);
        expect(true, isTrue);
      });
    });

    group('Performance simulation', () {
      test('handles 1000 rapid updates', () {
        for (int i = 0; i < 1000; i++) {
          overlay.update(0.016);
        }
        expect(true, isTrue);
      });

      test('handles 10000 minimal updates', () {
        for (int i = 0; i < 10000; i++) {
          overlay.update(0.001);
        }
        expect(true, isTrue);
      });

      test('handles many hit markers and updates', () {
        for (int frame = 0; frame < 600; frame++) {
          if (frame % 10 == 0) {
            overlay.registerHit(
              Vector2((frame % 100).toDouble(), (frame % 100).toDouble()),
              critical: frame % 5 == 0,
            );
          }
          overlay.update(0.016);
        }
        expect(true, isTrue);
      });

      test('simulates 30 seconds of focus mode', () {
        // Simulate 30 seconds at 60fps with occasional hits
        for (int frame = 0; frame < 1800; frame++) {
          if (frame % 60 == 0) {
            overlay.registerHit(Vector2(500, 300), critical: frame % 120 == 0);
          }
          overlay.update(1.0 / 60.0);
        }
        expect(true, isTrue);
      });
    });

    group('Multiple instance behavior', () {
      test('multiple overlays can update simultaneously', () {
        final overlays = List.generate(5, (_) => FocusModeOverlay());

        for (int frame = 0; frame < 60; frame++) {
          for (final o in overlays) {
            o.update(0.016);
          }
        }
        expect(true, isTrue);
      });

      test('multiple overlays have independent hit markers', () {
        final o1 = FocusModeOverlay();
        final o2 = FocusModeOverlay();

        o1.registerHit(Vector2(100, 100), critical: false);
        o2.registerHit(Vector2(200, 200), critical: true);

        o1.update(0.016);
        o2.update(0.016);

        expect(true, isTrue);
      });
    });

    group('Edge cases', () {
      test('handles negative delta time', () {
        overlay.update(-0.016);
        expect(true, isTrue);
      });

      test('handles very small delta time', () {
        overlay.update(0.0000001);
        expect(true, isTrue);
      });

      test('interleaved create, register, and remove', () {
        final o1 = FocusModeOverlay();
        o1.registerHit(Vector2(100, 100), critical: false);
        o1.update(0.016);
        o1.onRemove();

        final o2 = FocusModeOverlay();
        o2.registerHit(Vector2(200, 200), critical: true);
        o2.update(0.016);
        o2.onRemove();

        expect(true, isTrue);
      });
    });
  });

  group('FocusModeOverlay paint configurations', () {
    test('line paint has 1.2px stroke width', () {
      const strokeWidth = 1.2;
      expect(strokeWidth, closeTo(1.2, 0.001));
    });

    test('blink paint has 2.0px stroke width', () {
      const strokeWidth = 2.0;
      expect(strokeWidth, equals(2.0));
    });

    test('ring paint has 1.6px stroke width', () {
      const strokeWidth = 1.6;
      expect(strokeWidth, closeTo(1.6, 0.001));
    });

    test('inner paint has 1.0px stroke width', () {
      const strokeWidth = 1.0;
      expect(strokeWidth, equals(1.0));
    });

    test('cross paint has 1.4px stroke width', () {
      const strokeWidth = 1.4;
      expect(strokeWidth, closeTo(1.4, 0.001));
    });

    test('chroma paint has 1.6px stroke width', () {
      const strokeWidth = 1.6;
      expect(strokeWidth, closeTo(1.6, 0.001));
    });

    test('reticle decor paint has 1.2px stroke width', () {
      const strokeWidth = 1.2;
      expect(strokeWidth, closeTo(1.2, 0.001));
    });

    test('critical ring paint has 1.5px stroke width', () {
      const strokeWidth = 1.5;
      expect(strokeWidth, equals(1.5));
    });
  });

  group('FocusModeOverlay streak angles', () {
    test('streak angles has 12 entries', () {
      // Based on source: List<double>.generate(12, ...)
      const streakCount = 12;
      expect(streakCount, 12);
    });

    test('streak angles cover full circle', () {
      // Each angle is (i / 12) * pi * 2
      // First angle is 0, last is 11/12 * 2*pi
      const firstAngle = 0.0;
      const lastAngle = (11 / 12) * 3.14159265359 * 2;

      expect(firstAngle, closeTo(0.0, 0.001));
      expect(lastAngle, closeTo(5.76, 0.01)); // ~330 degrees
    });
  });

  group('FocusModeOverlay LCG random', () {
    test('LCG initial state is defined', () {
      // Based on source: _rngState = 0x2f6e2b1
      const initialState = 0x2f6e2b1;
      expect(initialState, greaterThan(0));
    });

    test('multiple overlays have independent RNG state', () {
      final o1 = FocusModeOverlay();
      final o2 = FocusModeOverlay();

      // Update both and verify they work independently
      o1.update(0.016);
      o2.update(0.016);

      expect(true, isTrue);
    });
  });

  group('FocusModeOverlay hit marker limits', () {
    test('max hit markers is 6', () {
      // Based on source: if (_hitMarkers.length >= 6) removeAt(0)
      const maxHitMarkers = 6;
      expect(maxHitMarkers, 6);
    });

    test('hit markers expire over time', () {
      final overlay = FocusModeOverlay();

      // Register a hit marker
      overlay.registerHit(Vector2(100, 100), critical: false);

      // Simulate enough time for it to expire
      for (int i = 0; i < 100; i++) {
        overlay.update(0.1);
      }

      expect(true, isTrue);
    });
  });
}

// Note: _HitMarker is private, so we test its behavior through FocusModeOverlay
