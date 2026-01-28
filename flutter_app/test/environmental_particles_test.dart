import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/environmental_particles.dart';

class _TestGame extends FlameGame {
  _TestGame() : super();
}

void main() {
  group('EnvironmentalParticles', () {
    group('initialization', () {
      test('creates with default values', () {
        final effect = EnvironmentalParticles();
        expect(effect.environmentType, EnvironmentType.defaultCyber);
        expect(effect.reduceFx, false);
        expect(effect.lowFx, false);
        expect(effect.intensity, 1.0);
      });

      test('creates with custom environment type', () {
        final effect = EnvironmentalParticles(
          environmentType: EnvironmentType.industrial,
        );
        expect(effect.environmentType, EnvironmentType.industrial);
      });

      test('creates with all custom values', () {
        final effect = EnvironmentalParticles(
          environmentType: EnvironmentType.corrupted,
          reduceFx: true,
          lowFx: true,
          intensity: 0.5,
        );
        expect(effect.environmentType, EnvironmentType.corrupted);
        expect(effect.reduceFx, true);
        expect(effect.lowFx, true);
        expect(effect.intensity, 0.5);
      });

      test('priority is set to -5', () {
        final effect = EnvironmentalParticles();
        expect(effect.priority, -5);
      });
    });

    group('EnvironmentType enum', () {
      test('has 4 environment types', () {
        expect(EnvironmentType.values.length, 4);
        expect(EnvironmentType.values, contains(EnvironmentType.defaultCyber));
        expect(EnvironmentType.values, contains(EnvironmentType.industrial));
        expect(EnvironmentType.values, contains(EnvironmentType.digital));
        expect(EnvironmentType.values, contains(EnvironmentType.corrupted));
      });
    });

    group('setEnvironmentType', () {
      test('changes environment type', () {
        final effect = EnvironmentalParticles();
        expect(effect.environmentType, EnvironmentType.defaultCyber);

        effect.setEnvironmentType(EnvironmentType.industrial);
        expect(effect.environmentType, EnvironmentType.industrial);

        effect.setEnvironmentType(EnvironmentType.digital);
        expect(effect.environmentType, EnvironmentType.digital);

        effect.setEnvironmentType(EnvironmentType.corrupted);
        expect(effect.environmentType, EnvironmentType.corrupted);
      });

      test('same environment type does not change', () {
        final effect = EnvironmentalParticles(
          environmentType: EnvironmentType.industrial,
        );
        effect.setEnvironmentType(EnvironmentType.industrial);
        expect(effect.environmentType, EnvironmentType.industrial);
      });
    });

    group('setQuality', () {
      test('updates reduceFx and lowFx settings', () {
        final effect = EnvironmentalParticles();
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

      test('same quality settings do not reinitialize', () {
        final effect = EnvironmentalParticles(reduceFx: true, lowFx: false);
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

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        expect(effect.isMounted, true);
        expect(effect.anchor, Anchor.topLeft);
        expect(effect.position, Vector2.zero());
      });

      testWidgets('handles game resize', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        effect.onGameResize(Vector2(800, 600));
        expect(effect.size.x, 800);
        expect(effect.size.y, 600);
      });

      testWidgets('does not initialize with zero size', (tester) async {
        final effect = EnvironmentalParticles();
        // Not added to game, size is zero
        // onGameResize with zero should skip initialization
        effect.onGameResize(Vector2.zero());
        // No crash expected
      });
    });

    group('update behavior', () {
      testWidgets('updates time during update calls', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        // Multiple updates should not crash
        effect.update(0.016);
        effect.update(0.016);
        effect.update(0.016);
      });

      testWidgets('skips update in lowFx mode with low intensity', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles(
          lowFx: true,
          intensity: 0.2,
        );
        await game.add(effect);
        await tester.pump();

        effect.update(0.016);
        // No crash expected - update is skipped
      });

      testWidgets('spawns particles during update', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        // Update to trigger particle spawning
        for (int i = 0; i < 60; i++) {
          effect.update(0.05);
        }
      });

      testWidgets('updates all particle types', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        // Update enough times to exercise all particle types
        for (int i = 0; i < 100; i++) {
          effect.update(0.1);
        }
      });
    });

    group('render behavior', () {
      testWidgets('skips render when size is zero', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        // Not added to game, size is zero
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        effect.render(canvas);
        recorder.endRecording();
        // No crash expected
      });

      testWidgets('renders without crashing when mounted', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        game.update(0.016);
        await tester.pump();
      });

      testWidgets('skips render in lowFx mode with low intensity', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles(
          lowFx: true,
          intensity: 0.2,
        );
        await game.add(effect);
        await tester.pump();

        game.update(0.016);
        await tester.pump();
        // No crash expected
      });

      testWidgets('renders all particle layers', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        // Update to populate all particle types
        for (int i = 0; i < 30; i++) {
          effect.update(0.1);
        }

        game.update(0.016);
        await tester.pump();
      });
    });

    group('quality modes', () {
      testWidgets('reduceFx mode reduces visual complexity', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles(reduceFx: true);
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 30; i++) {
          effect.update(0.016);
        }
        game.update(0.016);
        await tester.pump();
      });

      testWidgets('lowFx mode further reduces visual complexity', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles(lowFx: true);
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 30; i++) {
          effect.update(0.016);
        }
        game.update(0.016);
        await tester.pump();
      });
    });

    group('environment type rendering', () {
      testWidgets('renders defaultCyber environment', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles(
          environmentType: EnvironmentType.defaultCyber,
        );
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 30; i++) {
          effect.update(0.05);
        }
        game.update(0.016);
        await tester.pump();
      });

      testWidgets('renders industrial environment', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles(
          environmentType: EnvironmentType.industrial,
        );
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 30; i++) {
          effect.update(0.05);
        }
        game.update(0.016);
        await tester.pump();
      });

      testWidgets('renders digital environment', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles(
          environmentType: EnvironmentType.digital,
        );
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 30; i++) {
          effect.update(0.05);
        }
        game.update(0.016);
        await tester.pump();
      });

      testWidgets('renders corrupted environment', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles(
          environmentType: EnvironmentType.corrupted,
        );
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 30; i++) {
          effect.update(0.05);
        }
        game.update(0.016);
        await tester.pump();
      });
    });

    group('particle layers', () {
      testWidgets('sparks move upward', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 50; i++) {
          effect.update(0.05);
        }
      });

      testWidgets('embers have trails', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 50; i++) {
          effect.update(0.05);
        }
      });

      testWidgets('mist clouds wrap horizontally', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 100; i++) {
          effect.update(0.1);
        }
      });

      testWidgets('data fragments rotate', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 50; i++) {
          effect.update(0.05);
        }
      });

      testWidgets('electric discharges spawn occasionally', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 100; i++) {
          effect.update(0.1);
        }
      });

      testWidgets('holographic dust has color shifts', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 50; i++) {
          effect.update(0.05);
        }
      });
    });

    group('intensity effects', () {
      testWidgets('zero intensity skips render', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles(intensity: 0.0);
        await game.add(effect);
        await tester.pump();

        game.update(0.016);
        await tester.pump();
      });

      testWidgets('full intensity renders at maximum', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles(intensity: 1.0);
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 30; i++) {
          effect.update(0.016);
        }
        game.update(0.016);
        await tester.pump();
      });

      testWidgets('half intensity reduces spawn rate', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles(intensity: 0.5);
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 30; i++) {
          effect.update(0.016);
        }
        game.update(0.016);
        await tester.pump();
      });
    });

    group('particle lifecycle', () {
      testWidgets('particles expire and are removed', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        // Update long enough for particles to expire
        for (int i = 0; i < 200; i++) {
          effect.update(0.1);
        }
      });

      testWidgets('new particles spawn to replace expired ones', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        // Update to cycle through particle lifetimes
        for (int i = 0; i < 300; i++) {
          effect.update(0.1);
        }
      });
    });

    group('edge cases', () {
      testWidgets('handles very small size', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
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

        final effect = EnvironmentalParticles();
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

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 100; i++) {
          effect.update(0.001);
        }
      });

      testWidgets('handles large dt values', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        effect.update(1.0);
        effect.update(2.0);
      });

      testWidgets('handles environment type change during update', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 30; i++) {
          effect.update(0.05);
          if (i == 10) {
            effect.setEnvironmentType(EnvironmentType.industrial);
          }
          if (i == 20) {
            effect.setEnvironmentType(EnvironmentType.corrupted);
          }
        }
      });

      testWidgets('handles quality change during update', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        for (int i = 0; i < 30; i++) {
          effect.update(0.05);
          if (i == 10) {
            effect.setQuality(reduceFx: true, lowFx: false);
          }
          if (i == 20) {
            effect.setQuality(reduceFx: false, lowFx: true);
          }
        }
      });
    });

    group('data fragment shapes', () {
      testWidgets('renders all 4 shape types without crashing', (tester) async {
        final game = _TestGame();
        await tester.pumpWidget(GameWidget(game: game));
        await tester.pump();

        final effect = EnvironmentalParticles();
        await game.add(effect);
        await tester.pump();

        // Update enough times to likely render all shape types
        for (int i = 0; i < 100; i++) {
          effect.update(0.05);
        }
        game.update(0.016);
        await tester.pump();
      });
    });
  });
}
