// Tests for SettingsCubit: state management, volume clamping, toggles, service integration
// Rewritten without bloc_test dependency
import 'package:flutter_test/flutter_test.dart';
import 'package:bored_games/src/bloc/settings/settings_cubit.dart';
import 'package:bored_games/src/bloc/settings/settings_state.dart';
import 'helpers/fake_audioplayers_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFakeAudioplayersPlatform();
  });

  group('SettingsCubit initial state', () {
    test('has correct defaults', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());
      expect(cubit.state.musicVolume, 0.7);
      expect(cubit.state.sfxVolume, 0.8);
      expect(cubit.state.showFps, isTrue);
      expect(cubit.state.showGrid, isTrue);
      expect(cubit.state.particleIntensity, 1.0);
      expect(cubit.state.screenShake, isTrue);
    });
  });

  group('SettingsCubit setMusicVolume', () {
    test('sets volume to specified value', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());
      cubit.setMusicVolume(0.5);
      expect(cubit.state.musicVolume, closeTo(0.5, 0.001));
    });

    test('clamps volume above 1.0 to 1.0', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());
      cubit.setMusicVolume(1.5);
      expect(cubit.state.musicVolume, 1.0);
    });

    test('clamps volume below 0.0 to 0.0', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());
      cubit.setMusicVolume(-0.5);
      expect(cubit.state.musicVolume, 0.0);
    });

    test('sets volume to 0.0', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());
      cubit.setMusicVolume(0.0);
      expect(cubit.state.musicVolume, 0.0);
    });

    test('sets volume to 1.0', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());
      cubit.setMusicVolume(1.0);
      expect(cubit.state.musicVolume, 1.0);
    });
  });

  group('SettingsCubit setSfxVolume', () {
    test('sets SFX volume', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());
      cubit.setSfxVolume(0.3);
      expect(cubit.state.sfxVolume, closeTo(0.3, 0.001));
    });

    test('clamps SFX volume above 1.0', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());
      cubit.setSfxVolume(2.0);
      expect(cubit.state.sfxVolume, 1.0);
    });

    test('clamps SFX volume below 0.0', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());
      cubit.setSfxVolume(-1.0);
      expect(cubit.state.sfxVolume, 0.0);
    });
  });

  group('SettingsCubit toggles', () {
    test('toggleFps flips showFps from true to false', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());
      expect(cubit.state.showFps, isTrue);
      cubit.toggleFps();
      expect(cubit.state.showFps, isFalse);
    });

    test('double toggleFps returns to original', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());
      cubit.toggleFps();
      expect(cubit.state.showFps, isFalse);
      cubit.toggleFps();
      expect(cubit.state.showFps, isTrue);
    });

    test('toggleGrid flips showGrid', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());
      expect(cubit.state.showGrid, isTrue);
      cubit.toggleGrid();
      expect(cubit.state.showGrid, isFalse);
    });

    test('toggleScreenShake flips screenShake', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());
      expect(cubit.state.screenShake, isTrue);
      cubit.toggleScreenShake();
      expect(cubit.state.screenShake, isFalse);
    });
  });

  group('SettingsCubit setParticleIntensity', () {
    test('sets particle intensity', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());
      cubit.setParticleIntensity(0.5);
      expect(cubit.state.particleIntensity, 0.5);
    });

    test('clamps particle intensity above 1.0', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());
      cubit.setParticleIntensity(1.5);
      expect(cubit.state.particleIntensity, 1.0);
    });

    test('clamps particle intensity below 0.0', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());
      cubit.setParticleIntensity(-0.5);
      expect(cubit.state.particleIntensity, 0.0);
    });
  });

  group('SettingsCubit resetToDefaults', () {
    test('resets all values to defaults', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());

      // Change everything
      cubit.setMusicVolume(0.1);
      cubit.setSfxVolume(0.2);
      cubit.toggleFps();
      cubit.toggleGrid();
      cubit.setParticleIntensity(0.3);
      cubit.toggleScreenShake();

      // Verify changed
      expect(cubit.state.musicVolume, closeTo(0.1, 0.001));
      expect(cubit.state.showFps, isFalse);

      // Reset
      cubit.resetToDefaults();

      // Verify defaults
      expect(cubit.state.musicVolume, 0.7);
      expect(cubit.state.sfxVolume, 0.8);
      expect(cubit.state.showFps, isTrue);
      expect(cubit.state.showGrid, isTrue);
      expect(cubit.state.particleIntensity, 1.0);
      expect(cubit.state.screenShake, isTrue);
    });

    test('reset is idempotent', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());

      cubit.resetToDefaults();
      final state1 = cubit.state;
      cubit.resetToDefaults();
      final state2 = cubit.state;

      expect(state1, equals(state2));
      expect(cubit.state, const SettingsState());
    });
  });

  group('SettingsCubit rapid state changes', () {
    test('many rapid volume changes all applied', () async {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());

      final states = <SettingsState>[];
      cubit.stream.listen(states.add);

      for (int i = 0; i <= 10; i++) {
        cubit.setMusicVolume(i / 10.0);
      }

      // Stream listener processes asynchronously, wait for microtasks
      await Future.delayed(Duration.zero);

      expect(states.length, 11);
      for (int i = 0; i <= 10; i++) {
        expect(states[i].musicVolume, closeTo(i / 10.0, 0.001));
      }
      // Final state should be 1.0
      expect(cubit.state.musicVolume, closeTo(1.0, 0.001));
    });

    test('interleaved toggle and volume changes', () {
      final cubit = SettingsCubit();
      addTearDown(() => cubit.close());

      cubit.setMusicVolume(0.5);
      cubit.toggleFps();
      cubit.setSfxVolume(0.3);
      cubit.toggleGrid();

      expect(cubit.state.musicVolume, closeTo(0.5, 0.001));
      expect(cubit.state.showFps, isFalse);
      expect(cubit.state.sfxVolume, closeTo(0.3, 0.001));
      expect(cubit.state.showGrid, isFalse);
    });
  });

  group('SettingsState equality', () {
    test('equal states are equal', () {
      const s1 = SettingsState(musicVolume: 0.5, sfxVolume: 0.8);
      const s2 = SettingsState(musicVolume: 0.5, sfxVolume: 0.8);
      expect(s1, equals(s2));
    });

    test('different states are not equal', () {
      const s1 = SettingsState(musicVolume: 0.5);
      const s2 = SettingsState(musicVolume: 0.7);
      expect(s1, isNot(equals(s2)));
    });

    test('copyWith preserves other fields', () {
      const state = SettingsState(
        musicVolume: 0.5,
        sfxVolume: 0.3,
        showFps: false,
        showGrid: false,
        particleIntensity: 0.5,
        screenShake: false,
      );
      final copied = state.copyWith(musicVolume: 0.8);
      expect(copied.musicVolume, 0.8);
      expect(copied.sfxVolume, 0.3);
      expect(copied.showFps, isFalse);
      expect(copied.showGrid, isFalse);
      expect(copied.particleIntensity, 0.5);
      expect(copied.screenShake, isFalse);
    });

    test('default state props are complete', () {
      const state = SettingsState();
      expect(state.props.length, 6); // All 6 fields
    });
  });
}
