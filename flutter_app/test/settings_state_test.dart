import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/bloc/settings/settings_state.dart';

void main() {
  group('SettingsState default values', () {
    test('default constructor has expected values', () {
      const state = SettingsState();
      expect(state.musicVolume, 0.7);
      expect(state.sfxVolume, 0.8);
      expect(state.showFps, isTrue);
      expect(state.showGrid, isTrue);
      expect(state.particleIntensity, 1.0);
      expect(state.screenShake, isTrue);
      expect(state.graphicsQuality, 'high');
    });

    test('can create with all default values', () {
      const state = SettingsState();
      expect(state, isA<SettingsState>());
    });
  });

  group('SettingsState custom values', () {
    test('can create with custom musicVolume', () {
      const state = SettingsState(musicVolume: 0.5);
      expect(state.musicVolume, 0.5);
    });

    test('can create with custom sfxVolume', () {
      const state = SettingsState(sfxVolume: 0.3);
      expect(state.sfxVolume, 0.3);
    });

    test('can create with showFps false', () {
      const state = SettingsState(showFps: false);
      expect(state.showFps, isFalse);
    });

    test('can create with showGrid false', () {
      const state = SettingsState(showGrid: false);
      expect(state.showGrid, isFalse);
    });

    test('can create with custom particleIntensity', () {
      const state = SettingsState(particleIntensity: 0.5);
      expect(state.particleIntensity, 0.5);
    });

    test('can create with screenShake false', () {
      const state = SettingsState(screenShake: false);
      expect(state.screenShake, isFalse);
    });

    test('can create with custom graphicsQuality', () {
      const state = SettingsState(graphicsQuality: 'extreme');
      expect(state.graphicsQuality, 'extreme');
    });

    test('can create with all custom values', () {
      const state = SettingsState(
        musicVolume: 0.1,
        sfxVolume: 0.2,
        showFps: false,
        showGrid: false,
        particleIntensity: 0.3,
        screenShake: false,
      );

      expect(state.musicVolume, 0.1);
      expect(state.sfxVolume, 0.2);
      expect(state.showFps, isFalse);
      expect(state.showGrid, isFalse);
      expect(state.particleIntensity, 0.3);
      expect(state.screenShake, isFalse);
    });
  });

  group('SettingsState copyWith', () {
    test('copyWith updates provided fields', () {
      const base = SettingsState(
        musicVolume: 0.6,
        sfxVolume: 0.7,
        showFps: false,
        showGrid: true,
        particleIntensity: 0.8,
        screenShake: false,
      );

      final updated = base.copyWith(
        musicVolume: 0.3,
        showGrid: false,
      );

      expect(updated.musicVolume, 0.3);
      expect(updated.sfxVolume, 0.7);
      expect(updated.showFps, isFalse);
      expect(updated.showGrid, isFalse);
      expect(updated.particleIntensity, 0.8);
      expect(updated.screenShake, isFalse);
      expect(updated.graphicsQuality, 'high');
    });

    test('copyWith with no arguments preserves all values', () {
      const base = SettingsState(
        musicVolume: 0.5,
        sfxVolume: 0.6,
        showFps: false,
        showGrid: false,
        particleIntensity: 0.7,
        screenShake: false,
      );

      final copy = base.copyWith();

      expect(copy.musicVolume, base.musicVolume);
      expect(copy.sfxVolume, base.sfxVolume);
      expect(copy.showFps, base.showFps);
      expect(copy.showGrid, base.showGrid);
      expect(copy.particleIntensity, base.particleIntensity);
      expect(copy.screenShake, base.screenShake);
      expect(copy.graphicsQuality, base.graphicsQuality);
    });

    test('copyWith can update musicVolume only', () {
      const base = SettingsState();
      final updated = base.copyWith(musicVolume: 0.0);

      expect(updated.musicVolume, 0.0);
      expect(updated.sfxVolume, base.sfxVolume);
    });

    test('copyWith can update sfxVolume only', () {
      const base = SettingsState();
      final updated = base.copyWith(sfxVolume: 0.0);

      expect(updated.sfxVolume, 0.0);
      expect(updated.musicVolume, base.musicVolume);
    });

    test('copyWith can update showFps only', () {
      const base = SettingsState();
      final updated = base.copyWith(showFps: false);

      expect(updated.showFps, isFalse);
      expect(updated.showGrid, base.showGrid);
    });

    test('copyWith can update showGrid only', () {
      const base = SettingsState();
      final updated = base.copyWith(showGrid: false);

      expect(updated.showGrid, isFalse);
      expect(updated.showFps, base.showFps);
    });

    test('copyWith can update particleIntensity only', () {
      const base = SettingsState();
      final updated = base.copyWith(particleIntensity: 0.5);

      expect(updated.particleIntensity, 0.5);
      expect(updated.screenShake, base.screenShake);
    });

    test('copyWith can update screenShake only', () {
      const base = SettingsState();
      final updated = base.copyWith(screenShake: false);

      expect(updated.screenShake, isFalse);
      expect(updated.particleIntensity, base.particleIntensity);
    });

    test('copyWith can update graphicsQuality only', () {
      const base = SettingsState();
      final updated = base.copyWith(graphicsQuality: 'extreme');

      expect(updated.graphicsQuality, 'extreme');
      expect(updated.musicVolume, base.musicVolume);
    });

    test('copyWith can update all fields', () {
      const base = SettingsState();
      final updated = base.copyWith(
        musicVolume: 0.1,
        sfxVolume: 0.2,
        showFps: false,
        showGrid: false,
        particleIntensity: 0.3,
        screenShake: false,
        graphicsQuality: 'extreme',
      );

      expect(updated.musicVolume, 0.1);
      expect(updated.sfxVolume, 0.2);
      expect(updated.showFps, isFalse);
      expect(updated.showGrid, isFalse);
      expect(updated.particleIntensity, 0.3);
      expect(updated.screenShake, isFalse);
      expect(updated.graphicsQuality, 'extreme');
    });

    test('copyWith returns new instance', () {
      const base = SettingsState();
      final copy = base.copyWith();

      expect(identical(base, copy), isFalse);
    });
  });

  group('SettingsState Equatable', () {
    test('equatable props compare equality', () {
      const a = SettingsState();
      const b = SettingsState();
      const c = SettingsState(musicVolume: 0.5);

      expect(a, equals(b));
      expect(a == c, isFalse);
    });

    test('equal states have same hashCode', () {
      const a = SettingsState();
      const b = SettingsState();

      expect(a.hashCode, b.hashCode);
    });

    test('different musicVolume creates different state', () {
      const a = SettingsState(musicVolume: 0.5);
      const b = SettingsState(musicVolume: 0.6);

      expect(a, isNot(equals(b)));
    });

    test('different sfxVolume creates different state', () {
      const a = SettingsState(sfxVolume: 0.5);
      const b = SettingsState(sfxVolume: 0.6);

      expect(a, isNot(equals(b)));
    });

    test('different showFps creates different state', () {
      const a = SettingsState(showFps: true);
      const b = SettingsState(showFps: false);

      expect(a, isNot(equals(b)));
    });

    test('different showGrid creates different state', () {
      const a = SettingsState(showGrid: true);
      const b = SettingsState(showGrid: false);

      expect(a, isNot(equals(b)));
    });

    test('different particleIntensity creates different state', () {
      const a = SettingsState(particleIntensity: 0.5);
      const b = SettingsState(particleIntensity: 0.6);

      expect(a, isNot(equals(b)));
    });

    test('different screenShake creates different state', () {
      const a = SettingsState(screenShake: true);
      const b = SettingsState(screenShake: false);

      expect(a, isNot(equals(b)));
    });

    test('different graphicsQuality creates different state', () {
      const a = SettingsState(graphicsQuality: 'high');
      const b = SettingsState(graphicsQuality: 'extreme');

      expect(a, isNot(equals(b)));
    });

    test('props includes all fields', () {
      const state = SettingsState(
        musicVolume: 0.5,
        sfxVolume: 0.6,
        showFps: false,
        showGrid: false,
        particleIntensity: 0.7,
        screenShake: false,
        graphicsQuality: 'extreme',
      );

      expect(state.props.length, 7);
      expect(state.props, contains(0.5));
      expect(state.props, contains(0.6));
      expect(state.props, contains(false));
      expect(state.props, contains(0.7));
      expect(state.props, contains('extreme'));
    });
  });

  group('SettingsState volume ranges', () {
    test('volume can be 0', () {
      const state = SettingsState(musicVolume: 0.0, sfxVolume: 0.0);
      expect(state.musicVolume, 0.0);
      expect(state.sfxVolume, 0.0);
    });

    test('volume can be 1', () {
      const state = SettingsState(musicVolume: 1.0, sfxVolume: 1.0);
      expect(state.musicVolume, 1.0);
      expect(state.sfxVolume, 1.0);
    });

    test('particleIntensity can be 0', () {
      const state = SettingsState(particleIntensity: 0.0);
      expect(state.particleIntensity, 0.0);
    });

    test('particleIntensity can be 1', () {
      const state = SettingsState(particleIntensity: 1.0);
      expect(state.particleIntensity, 1.0);
    });
  });
}
