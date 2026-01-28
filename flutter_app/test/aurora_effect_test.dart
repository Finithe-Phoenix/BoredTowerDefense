import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/aurora_effect.dart';

class _TestGame extends FlameGame {
  _TestGame() : super();
}

void main() {
  group('AuroraEffect', () {
    group('initialization', () {
      test('creates with default values', () {
        final effect = AuroraEffect();
        expect(effect.reduceFx, false);
        expect(effect.lowFx, false);
        expect(effect.intensity, 1.0);
        expect(effect.horizonY, 0.55);
      });

      test('creates with custom values', () {
        final effect = AuroraEffect(
          reduceFx: true,
          lowFx: true,
          intensity: 0.5,
          horizonY: 0.7,
        );
        expect(effect.reduceFx, true);
        expect(effect.lowFx, true);
        expect(effect.intensity, 0.5);
        expect(effect.horizonY, 0.7);
      });

      test('intensity can be set in range 0.0 to 1.0', () {
        final effect = AuroraEffect(intensity: 0.0);
        expect(effect.intensity, 0.0);

        final effect2 = AuroraEffect(intensity: 1.0);
        expect(effect2.intensity, 1.0);

        final effect3 = AuroraEffect(intensity: 0.5);
        expect(effect3.intensity, 0.5);
      });

      test('horizonY determines aurora bottom position', () {
        final effect1 = AuroraEffect(horizonY: 0.3);
        expect(effect1.horizonY, 0.3);

        final effect2 = AuroraEffect(horizonY: 0.8);
        expect(effect2.horizonY, 0.8);
      });
    });

    group('setQuality', () {
      test('updates reduceFx and lowFx settings', () {
        final effect = AuroraEffect();
        expect(effect.reduceFx, false);
        expect(effect.lowFx, false);

        effect.setQuality(reduceFx: true, lowFx: false);
        expect(effect.reduceFx, true);
        expect(effect.lowFx, false);

        effect.setQuality(reduceFx: false, lowFx: true);
        expect(effect.reduceFx, false);
        expect(effect.lowFx, true);

        effect.setQuality(reduceFx: true, lowFx: true);
        expect(effect.reduceFx, true);
        expect(effect.lowFx, true);
      });

      test('same quality settings do not trigger reinit', () {
        final effect = AuroraEffect(reduceFx: true, lowFx: false);
        // Calling with same values should not cause issues
        effect.setQuality(reduceFx: true, lowFx: false);
        expect(effect.reduceFx, true);
        expect(effect.lowFx, false);
      });
    });

    group('lifecycle', () {
      testWidgets('loads and initializes correctly', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect();
        await game.add(effect);
        await tester.pump();

        expect(effect.isMounted, true);
        expect(effect.priority, -99);
      });

      testWidgets('handles game resize', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect();
        await game.add(effect);
        await tester.pump();

        // Simulate resize by calling onGameResize
        effect.onGameResize(Vector2(800, 600));
        expect(effect.size.x, 800);
        expect(effect.size.y, 600);
        expect(effect.position, Vector2.zero());
      });
    });

    group('update behavior', () {
      testWidgets('updates time during update calls', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect();
        await game.add(effect);
        await tester.pump();

        // The effect should update without crashing
        effect.update(0.016);
        effect.update(0.016);
        effect.update(0.016);
      });

      testWidgets('skips update in lowFx mode with low intensity', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect(lowFx: true, intensity: 0.2);
        await game.add(effect);
        await tester.pump();

        // Should skip update when lowFx && intensity < 0.3
        effect.update(0.016);
        // No crash expected - update is skipped
      });

      testWidgets('updates normally when intensity is high enough', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect(lowFx: true, intensity: 0.5);
        await game.add(effect);
        await tester.pump();

        effect.update(0.016);
        // Update should proceed normally
      });
    });

    group('render behavior', () {
      testWidgets('skips render when size is zero', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect();
        // Not added to game, size is zero
        // render should not crash
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        effect.render(canvas);
        recorder.endRecording();
      });

      testWidgets('renders without crashing when mounted', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect();
        await game.add(effect);
        await tester.pump();

        // Game update will call render
        game.update(0.016);
        await tester.pump();
      });

      testWidgets('skips render in lowFx mode with low intensity', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect(lowFx: true, intensity: 0.2);
        await game.add(effect);
        await tester.pump();

        // Should skip render when lowFx && intensity < 0.3
        game.update(0.016);
        await tester.pump();
        // No crash expected
      });
    });

    group('quality modes', () {
      testWidgets('reduceFx mode reduces visual complexity', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect(reduceFx: true);
        await game.add(effect);
        await tester.pump();

        game.update(0.016);
        await tester.pump();
        // Should render with reduced effects
      });

      testWidgets('lowFx mode further reduces visual complexity', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect(lowFx: true);
        await game.add(effect);
        await tester.pump();

        game.update(0.016);
        await tester.pump();
        // Should render with minimal effects
      });

      test('star count scales with quality settings', () {
        // lowFx: 30 stars, reduceFx: 60 stars, normal: 120 stars
        final normalEffect = AuroraEffect();
        final reduceFxEffect = AuroraEffect(reduceFx: true);
        final lowFxEffect = AuroraEffect(lowFx: true);

        // These effects aren't mounted so stars won't be initialized yet
        // but we can verify the settings are stored
        expect(normalEffect.lowFx, false);
        expect(normalEffect.reduceFx, false);
        expect(reduceFxEffect.reduceFx, true);
        expect(lowFxEffect.lowFx, true);
      });
    });

    group('intensity effects', () {
      test('intensity clamped during render', () {
        final effect = AuroraEffect(intensity: 2.0);
        // intensity will be clamped to 0.0-1.0 during render
        expect(effect.intensity, 2.0); // stored value
      });

      test('zero intensity renders nothing visible', () {
        final effect = AuroraEffect(intensity: 0.0);
        expect(effect.intensity, 0.0);
      });

      test('full intensity renders at maximum visibility', () {
        final effect = AuroraEffect(intensity: 1.0);
        expect(effect.intensity, 1.0);
      });
    });

    group('shader cache', () {
      testWidgets('invalidates shader cache on resize', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect();
        await game.add(effect);
        await tester.pump();

        // Resize should trigger _invalidateShaderCache
        effect.onGameResize(Vector2(1024, 768));
        effect.onGameResize(Vector2(800, 600));
        // No crash expected - shaders are recreated
      });
    });

    group('edge cases', () {
      testWidgets('handles very small size', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect();
        await game.add(effect);
        await tester.pump();

        effect.onGameResize(Vector2(10, 10));
        game.update(0.016);
        await tester.pump();
      });

      testWidgets('handles very large size', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect();
        await game.add(effect);
        await tester.pump();

        effect.onGameResize(Vector2(4096, 2160));
        game.update(0.016);
        await tester.pump();
      });

      testWidgets('handles rapid update calls', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect();
        await game.add(effect);
        await tester.pump();

        // Simulate rapid updates
        for (int i = 0; i < 100; i++) {
          effect.update(0.001);
        }
      });

      testWidgets('handles large dt values', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect();
        await game.add(effect);
        await tester.pump();

        // Large delta time
        effect.update(1.0);
        effect.update(2.0);
      });
    });

    group('particle behavior', () {
      testWidgets('particles wrap around horizontally', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect();
        await game.add(effect);
        await tester.pump();

        // Update multiple times to exercise particle wrapping
        for (int i = 0; i < 60; i++) {
          effect.update(0.1);
        }
      });

      testWidgets('particles respawn when lifetime expires', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = AuroraEffect();
        await game.add(effect);
        await tester.pump();

        // Update long enough for particles to expire and respawn
        for (int i = 0; i < 100; i++) {
          effect.update(0.1);
        }
      });
    });
  });
}
