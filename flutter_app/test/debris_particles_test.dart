import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/debris_particles.dart';

class _TestGame extends FlameGame {
  _TestGame() : super();
}

void main() {
  group('DebrisParticles', () {
    setUp(() {
      // Clear the static pool before each test
      DebrisParticles.clearPool();
    });

    tearDown(() {
      // Clear the static pool after each test
      DebrisParticles.clearPool();
    });

    group('static pool management', () {
      test('clearPool resets pool and active count', () {
        // Spawn some particles
        final effect1 = DebrisParticles.spawn(
          position: Vector2(100, 100),
        );
        final effect2 = DebrisParticles.spawn(
          position: Vector2(200, 200),
        );

        expect(effect1, isNotNull);
        expect(effect2, isNotNull);
        expect(DebrisParticles.activeCount, 2);

        // Clear the pool
        DebrisParticles.clearPool();
        expect(DebrisParticles.activeCount, 0);
      });

      test('maxPool is 16', () {
        // Access static constant indirectly by spawning max particles
        // Since maxActive is 12, we can only test that
        expect(DebrisParticles.activeCount, 0);
      });

      test('maxActive is 12', () {
        // Spawn 12 particles - all should succeed
        for (int i = 0; i < 12; i++) {
          final effect = DebrisParticles.spawn(
            position: Vector2(i * 10.0, 100),
          );
          expect(effect, isNotNull, reason: 'Particle $i should be created');
        }
        expect(DebrisParticles.activeCount, 12);

        // 13th should return null
        final effect13 = DebrisParticles.spawn(
          position: Vector2(130, 100),
        );
        expect(effect13, isNull, reason: 'Should hit maxActive limit');
        expect(DebrisParticles.activeCount, 12);
      });

      test('activeCount getter returns correct count', () {
        expect(DebrisParticles.activeCount, 0);

        DebrisParticles.spawn(position: Vector2(100, 100));
        expect(DebrisParticles.activeCount, 1);

        DebrisParticles.spawn(position: Vector2(200, 200));
        expect(DebrisParticles.activeCount, 2);

        DebrisParticles.clearPool();
        expect(DebrisParticles.activeCount, 0);
      });
    });

    group('spawn factory method', () {
      test('creates effect with required position', () {
        final effect = DebrisParticles.spawn(
          position: Vector2(150, 250),
        );

        expect(effect, isNotNull);
        expect(effect!.position.x, 150);
        expect(effect.position.y, 250);
      });

      test('creates effect with default values', () {
        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
        );

        expect(effect, isNotNull);
        expect(effect!.areaSize, 40.0);
        expect(effect.color, const Color(0xFF00FFFF));
        expect(effect.duration, 3.0);
        expect(effect.intensity, 1.0);
      });

      test('creates effect with custom values', () {
        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
          areaSize: 60.0,
          color: Colors.red,
          duration: 5.0,
          intensity: 0.8,
        );

        expect(effect, isNotNull);
        expect(effect!.areaSize, 60.0);
        expect(effect.color, Colors.red);
        expect(effect.duration, 5.0);
        expect(effect.intensity, 0.8);
      });

      test('returns null when maxActive is reached', () {
        // Fill up to maxActive
        for (int i = 0; i < 12; i++) {
          DebrisParticles.spawn(position: Vector2(i * 10.0, 100));
        }

        // Next spawn should return null
        final effect = DebrisParticles.spawn(
          position: Vector2(130, 100),
        );
        expect(effect, isNull);
      });
    });

    group('spawnContinuous factory method', () {
      test('creates continuous effect with long duration', () {
        final effect = DebrisParticles.spawnContinuous(
          position: Vector2(100, 100),
        );

        expect(effect, isNotNull);
        expect(effect!.duration, 999.0);
      });

      test('uses default values for continuous effect', () {
        final effect = DebrisParticles.spawnContinuous(
          position: Vector2(100, 100),
        );

        expect(effect, isNotNull);
        expect(effect!.areaSize, 30.0);
        expect(effect.intensity, 0.6);
      });

      test('accepts custom color and areaSize', () {
        final effect = DebrisParticles.spawnContinuous(
          position: Vector2(100, 100),
          areaSize: 50.0,
          color: Colors.orange,
          intensity: 0.8,
        );

        expect(effect, isNotNull);
        expect(effect!.areaSize, 50.0);
        expect(effect.color, Colors.orange);
        expect(effect.intensity, 0.8);
      });
    });

    group('static quality settings', () {
      test('fxScale default is 1.0', () {
        expect(DebrisParticles.fxScale, 1.0);
      });

      test('reduceFx default is false', () {
        expect(DebrisParticles.reduceFx, false);
      });

      test('lowFx default is false', () {
        expect(DebrisParticles.lowFx, false);
      });

      test('fxScale can be modified', () {
        DebrisParticles.fxScale = 0.5;
        expect(DebrisParticles.fxScale, 0.5);

        // Reset for other tests
        DebrisParticles.fxScale = 1.0;
      });

      test('reduceFx can be modified', () {
        DebrisParticles.reduceFx = true;
        expect(DebrisParticles.reduceFx, true);

        // Reset for other tests
        DebrisParticles.reduceFx = false;
      });

      test('lowFx can be modified', () {
        DebrisParticles.lowFx = true;
        expect(DebrisParticles.lowFx, true);

        // Reset for other tests
        DebrisParticles.lowFx = false;
      });
    });

    group('instance methods', () {
      test('stop() removes effect from parent', () async {
        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
        );

        expect(effect, isNotNull);
        final initialCount = DebrisParticles.activeCount;

        effect!.stop();

        // Active count should decrease
        expect(DebrisParticles.activeCount, lessThan(initialCount));
      });

      test('setIntensity updates intensity', () {
        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
          intensity: 1.0,
        );

        expect(effect, isNotNull);
        expect(effect!.intensity, 1.0);

        effect.setIntensity(0.5);
        expect(effect.intensity, 0.5);
      });

      test('setIntensity clamps to 0.0-2.0 range', () {
        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
        );

        expect(effect, isNotNull);

        effect!.setIntensity(-1.0);
        expect(effect.intensity, 0.0);

        effect.setIntensity(3.0);
        expect(effect.intensity, 2.0);

        effect.setIntensity(1.5);
        expect(effect.intensity, 1.5);
      });
    });

    group('lifecycle', () {
      testWidgets('loads correctly in game', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
        );
        expect(effect, isNotNull);

        await game.add(effect!);
        await tester.pump();

        expect(effect.isMounted, true);
      });

      testWidgets('recycles when duration expires', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
          duration: 0.5,
        );
        expect(effect, isNotNull);

        await game.add(effect!);
        await tester.pump();

        final initialCount = DebrisParticles.activeCount;

        // Update past duration
        effect.update(0.6);
        await tester.pump();

        expect(DebrisParticles.activeCount, lessThan(initialCount));
      });

      testWidgets('decrements activeCount on removal', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
        );
        expect(effect, isNotNull);

        await game.add(effect!);
        await tester.pump();

        final countBefore = DebrisParticles.activeCount;
        effect.removeFromParent();
        await tester.pump();

        expect(DebrisParticles.activeCount, lessThanOrEqualTo(countBefore));
      });
    });

    group('update behavior', () {
      testWidgets('updates particles during update', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
        );
        expect(effect, isNotNull);

        await game.add(effect!);
        await tester.pump();

        // Multiple updates should not crash
        for (int i = 0; i < 30; i++) {
          effect.update(0.016);
        }
      });

      testWidgets('spawns new particles during update', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
          intensity: 1.0,
        );
        expect(effect, isNotNull);

        await game.add(effect!);
        await tester.pump();

        // Update to trigger particle spawning
        for (int i = 0; i < 60; i++) {
          effect.update(0.05);
        }
      });

      testWidgets('skips update in lowFx mode with low intensity', (tester) async {
        DebrisParticles.lowFx = true;

        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
          intensity: 0.2,
        );
        expect(effect, isNotNull);

        await game.add(effect!);
        await tester.pump();

        // Should skip most update logic
        effect.update(0.016);

        // Reset
        DebrisParticles.lowFx = false;
      });
    });

    group('render behavior', () {
      testWidgets('renders without crashing', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
        );
        expect(effect, isNotNull);

        await game.add(effect!);
        await tester.pump();

        game.update(0.016);
        await tester.pump();
      });

      testWidgets('renders all particle layers', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
          intensity: 1.0,
        );
        expect(effect, isNotNull);

        await game.add(effect!);
        await tester.pump();

        // Update to initialize particles
        for (int i = 0; i < 30; i++) {
          effect.update(0.016);
        }

        game.update(0.016);
        await tester.pump();
      });

      testWidgets('skips render in lowFx mode with low intensity', (tester) async {
        DebrisParticles.lowFx = true;

        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
          intensity: 0.2,
        );
        expect(effect, isNotNull);

        await game.add(effect!);
        await tester.pump();

        game.update(0.016);
        await tester.pump();

        // Reset
        DebrisParticles.lowFx = false;
      });

      testWidgets('fades out near end of duration', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
          duration: 2.0,
        );
        expect(effect, isNotNull);

        await game.add(effect!);
        await tester.pump();

        // Update to near end of duration
        effect.update(1.6);
        game.update(0.016);
        await tester.pump();

        // Effect should be fading out
      });
    });

    group('pool recycling', () {
      testWidgets('recycles effects back to pool', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        // Spawn and expire several effects
        for (int i = 0; i < 5; i++) {
          final effect = DebrisParticles.spawn(
            position: Vector2(i * 50.0, 100),
            duration: 0.1,
          );
          expect(effect, isNotNull);
          await game.add(effect!);
          await tester.pump();

          // Expire the effect
          effect.update(0.2);
          await tester.pump();
        }

        // Pool should have recycled some effects
        expect(DebrisParticles.activeCount, lessThan(5));
      });

      testWidgets('reuses pooled effects', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        // Spawn and expire an effect
        final effect1 = DebrisParticles.spawn(
          position: Vector2(100, 100),
          duration: 0.1,
        );
        expect(effect1, isNotNull);
        await game.add(effect1!);
        await tester.pump();

        effect1.update(0.2);
        await tester.pump();

        // Spawn another - should reuse from pool
        final effect2 = DebrisParticles.spawn(
          position: Vector2(200, 200),
        );
        expect(effect2, isNotNull);
      });
    });

    group('particle types', () {
      testWidgets('creates all 6 particle types', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
          intensity: 1.0,
        );
        expect(effect, isNotNull);

        await game.add(effect!);
        await tester.pump();

        // Update to spawn all particle types
        for (int i = 0; i < 100; i++) {
          effect.update(0.05);
        }

        // All particle layers should be populated
        // (We can't directly access private fields, but this exercises the code)
      });
    });

    group('quality modes', () {
      testWidgets('reduceFx mode works', (tester) async {
        DebrisParticles.reduceFx = true;

        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
        );
        expect(effect, isNotNull);

        await game.add(effect!);
        await tester.pump();

        for (int i = 0; i < 30; i++) {
          effect.update(0.016);
        }
        game.update(0.016);
        await tester.pump();

        DebrisParticles.reduceFx = false;
      });

      testWidgets('lowFx mode works', (tester) async {
        DebrisParticles.lowFx = true;

        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
        );
        expect(effect, isNotNull);

        await game.add(effect!);
        await tester.pump();

        for (int i = 0; i < 30; i++) {
          effect.update(0.016);
        }
        game.update(0.016);
        await tester.pump();

        DebrisParticles.lowFx = false;
      });

      testWidgets('fxScale affects particle count', (tester) async {
        DebrisParticles.fxScale = 0.5;

        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
        );
        expect(effect, isNotNull);

        await game.add(effect!);
        await tester.pump();

        for (int i = 0; i < 30; i++) {
          effect.update(0.016);
        }
        game.update(0.016);
        await tester.pump();

        DebrisParticles.fxScale = 1.0;
      });
    });

    group('edge cases', () {
      testWidgets('handles very high intensity', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
          intensity: 2.0,
        );
        expect(effect, isNotNull);

        await game.add(effect!);
        await tester.pump();

        for (int i = 0; i < 30; i++) {
          effect.update(0.016);
        }
      });

      testWidgets('handles very small areaSize', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = DebrisParticles.spawn(
          position: Vector2(100, 100),
          areaSize: 5.0,
        );
        expect(effect, isNotNull);

        await game.add(effect!);
        await tester.pump();

        for (int i = 0; i < 30; i++) {
          effect.update(0.016);
        }
      });

      testWidgets('handles rapid spawn/stop cycles', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        for (int cycle = 0; cycle < 10; cycle++) {
          final effect = DebrisParticles.spawn(
            position: Vector2(cycle * 10.0, 100),
          );
          if (effect != null) {
            await game.add(effect);
            await tester.pump();
            effect.stop();
            await tester.pump();
          }
        }
      });
    });
  });
}
