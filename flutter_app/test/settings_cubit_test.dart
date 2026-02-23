import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bored_games/src/bloc/settings/settings_cubit.dart';
import 'package:bored_games/src/bloc/settings/settings_state.dart';
import 'package:bored_games/src/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsCubit initial state', () {
    test('initial state is default SettingsState', () {
      final cubit = SettingsCubit();
      expect(cubit.state, const SettingsState());
    });

    test('initial musicVolume is 0.7', () {
      final cubit = SettingsCubit();
      expect(cubit.state.musicVolume, 0.7);
    });

    test('initial sfxVolume is 0.8', () {
      final cubit = SettingsCubit();
      expect(cubit.state.sfxVolume, 0.8);
    });

    test('initial showFps is true', () {
      final cubit = SettingsCubit();
      expect(cubit.state.showFps, isTrue);
    });

    test('initial showGrid is true', () {
      final cubit = SettingsCubit();
      expect(cubit.state.showGrid, isTrue);
    });

    test('initial particleIntensity is 1.0', () {
      final cubit = SettingsCubit();
      expect(cubit.state.particleIntensity, 1.0);
    });

    test('initial screenShake is true', () {
      final cubit = SettingsCubit();
      expect(cubit.state.screenShake, isTrue);
    });

    test('initial graphicsQuality is high', () {
      final cubit = SettingsCubit();
      expect(cubit.state.graphicsQuality, 'high');
    });
  });

  group('SettingsCubit setMusicVolume', () {
    test('setMusicVolume clamps and updates state', () {
      final cubit = SettingsCubit();

      cubit.setMusicVolume(2.0);
      expect(cubit.state.musicVolume, 1.0);

      cubit.setMusicVolume(-1.0);
      expect(cubit.state.musicVolume, 0.0);
    });

    test('setMusicVolume updates to valid value', () {
      final cubit = SettingsCubit();
      cubit.setMusicVolume(0.5);
      expect(cubit.state.musicVolume, 0.5);
    });

    test('setMusicVolume to 0', () {
      final cubit = SettingsCubit();
      cubit.setMusicVolume(0.0);
      expect(cubit.state.musicVolume, 0.0);
    });

    test('setMusicVolume to 1', () {
      final cubit = SettingsCubit();
      cubit.setMusicVolume(1.0);
      expect(cubit.state.musicVolume, 1.0);
    });

    test('setMusicVolume preserves other state', () {
      final cubit = SettingsCubit();
      final originalSfx = cubit.state.sfxVolume;
      cubit.setMusicVolume(0.5);
      expect(cubit.state.sfxVolume, originalSfx);
    });
  });

  group('SettingsCubit setSfxVolume', () {
    test('setSfxVolume clamps and updates state', () {
      final cubit = SettingsCubit();

      cubit.setSfxVolume(2.0);
      expect(cubit.state.sfxVolume, 1.0);

      cubit.setSfxVolume(-1.0);
      expect(cubit.state.sfxVolume, 0.0);
    });

    test('setSfxVolume updates to valid value', () {
      final cubit = SettingsCubit();
      cubit.setSfxVolume(0.3);
      expect(cubit.state.sfxVolume, 0.3);
    });

    test('setSfxVolume to 0', () {
      final cubit = SettingsCubit();
      cubit.setSfxVolume(0.0);
      expect(cubit.state.sfxVolume, 0.0);
    });

    test('setSfxVolume to 1', () {
      final cubit = SettingsCubit();
      cubit.setSfxVolume(1.0);
      expect(cubit.state.sfxVolume, 1.0);
    });

    test('setSfxVolume preserves other state', () {
      final cubit = SettingsCubit();
      final originalMusic = cubit.state.musicVolume;
      cubit.setSfxVolume(0.5);
      expect(cubit.state.musicVolume, originalMusic);
    });
  });

  group('SettingsCubit toggleFps', () {
    test('toggle methods flip booleans', () {
      final cubit = SettingsCubit();
      final initial = cubit.state;

      cubit.toggleFps();
      cubit.toggleGrid();
      cubit.toggleScreenShake();

      expect(cubit.state.showFps, isNot(equals(initial.showFps)));
      expect(cubit.state.showGrid, isNot(equals(initial.showGrid)));
      expect(cubit.state.screenShake, isNot(equals(initial.screenShake)));
    });

    test('toggleFps toggles from true to false', () {
      final cubit = SettingsCubit();
      expect(cubit.state.showFps, isTrue);
      cubit.toggleFps();
      expect(cubit.state.showFps, isFalse);
    });

    test('toggleFps toggles from false to true', () {
      final cubit = SettingsCubit();
      cubit.toggleFps(); // true -> false
      cubit.toggleFps(); // false -> true
      expect(cubit.state.showFps, isTrue);
    });

    test('toggleFps preserves other state', () {
      final cubit = SettingsCubit();
      final originalGrid = cubit.state.showGrid;
      cubit.toggleFps();
      expect(cubit.state.showGrid, originalGrid);
    });
  });

  group('SettingsCubit toggleGrid', () {
    test('toggleGrid toggles from true to false', () {
      final cubit = SettingsCubit();
      expect(cubit.state.showGrid, isTrue);
      cubit.toggleGrid();
      expect(cubit.state.showGrid, isFalse);
    });

    test('toggleGrid toggles from false to true', () {
      final cubit = SettingsCubit();
      cubit.toggleGrid(); // true -> false
      cubit.toggleGrid(); // false -> true
      expect(cubit.state.showGrid, isTrue);
    });

    test('toggleGrid preserves other state', () {
      final cubit = SettingsCubit();
      final originalFps = cubit.state.showFps;
      cubit.toggleGrid();
      expect(cubit.state.showFps, originalFps);
    });
  });

  group('SettingsCubit toggleScreenShake', () {
    test('toggleScreenShake toggles from true to false', () {
      final cubit = SettingsCubit();
      expect(cubit.state.screenShake, isTrue);
      cubit.toggleScreenShake();
      expect(cubit.state.screenShake, isFalse);
    });

    test('toggleScreenShake toggles from false to true', () {
      final cubit = SettingsCubit();
      cubit.toggleScreenShake(); // true -> false
      cubit.toggleScreenShake(); // false -> true
      expect(cubit.state.screenShake, isTrue);
    });

    test('toggleScreenShake preserves other state', () {
      final cubit = SettingsCubit();
      final originalParticle = cubit.state.particleIntensity;
      cubit.toggleScreenShake();
      expect(cubit.state.particleIntensity, originalParticle);
    });
  });

  group('SettingsCubit setParticleIntensity', () {
    test('particle intensity clamps and reset restores defaults', () {
      final cubit = SettingsCubit();

      cubit.setParticleIntensity(2.0);
      expect(cubit.state.particleIntensity, 1.0);

      cubit.setParticleIntensity(-1.0);
      expect(cubit.state.particleIntensity, 0.0);

      cubit.resetToDefaults();
      expect(cubit.state, const SettingsState());
    });

    test('setParticleIntensity updates to valid value', () {
      final cubit = SettingsCubit();
      cubit.setParticleIntensity(0.5);
      expect(cubit.state.particleIntensity, 0.5);
    });

    test('setParticleIntensity to 0', () {
      final cubit = SettingsCubit();
      cubit.setParticleIntensity(0.0);
      expect(cubit.state.particleIntensity, 0.0);
    });

    test('setParticleIntensity to 1', () {
      final cubit = SettingsCubit();
      cubit.setParticleIntensity(1.0);
      expect(cubit.state.particleIntensity, 1.0);
    });

    test('setParticleIntensity preserves other state', () {
      final cubit = SettingsCubit();
      final originalShake = cubit.state.screenShake;
      cubit.setParticleIntensity(0.5);
      expect(cubit.state.screenShake, originalShake);
    });
  });

  group('SettingsCubit resetToDefaults', () {
    test('resetToDefaults restores all values', () {
      final cubit = SettingsCubit();

      // Modify all settings
      cubit.setMusicVolume(0.1);
      cubit.setSfxVolume(0.2);
      cubit.toggleFps();
      cubit.toggleGrid();
      cubit.setParticleIntensity(0.3);
      cubit.toggleScreenShake();

      // Verify modified
      expect(cubit.state.musicVolume, 0.1);
      expect(cubit.state.sfxVolume, 0.2);
      expect(cubit.state.showFps, isFalse);
      expect(cubit.state.showGrid, isFalse);
      expect(cubit.state.particleIntensity, 0.3);
      expect(cubit.state.screenShake, isFalse);

      // Reset
      cubit.resetToDefaults();

      // Verify defaults
      expect(cubit.state, const SettingsState());
      expect(cubit.state.musicVolume, 0.7);
      expect(cubit.state.sfxVolume, 0.8);
      expect(cubit.state.showFps, isTrue);
      expect(cubit.state.showGrid, isTrue);
      expect(cubit.state.particleIntensity, 1.0);
      expect(cubit.state.screenShake, isTrue);
      expect(cubit.state.graphicsQuality, 'high');
    });

    test('resetToDefaults can be called multiple times', () {
      final cubit = SettingsCubit();
      cubit.setMusicVolume(0.1);
      cubit.resetToDefaults();
      cubit.resetToDefaults();
      expect(cubit.state, const SettingsState());
    });
  });

  group('SettingsCubit setGraphicsQuality', () {
    test('accepts low, medium, high and extreme', () {
      final cubit = SettingsCubit();

      cubit.setGraphicsQuality('low');
      expect(cubit.state.graphicsQuality, 'low');

      cubit.setGraphicsQuality('medium');
      expect(cubit.state.graphicsQuality, 'medium');

      cubit.setGraphicsQuality('high');
      expect(cubit.state.graphicsQuality, 'high');

      cubit.setGraphicsQuality('extreme');
      expect(cubit.state.graphicsQuality, 'extreme');
    });

    test('rejects unknown values', () {
      final cubit = SettingsCubit();
      final before = cubit.state.graphicsQuality;
      cubit.setGraphicsQuality('ultra');
      expect(cubit.state.graphicsQuality, before);
    });

    test('legacy auto is migrated to high', () {
      final cubit = SettingsCubit();
      cubit.setGraphicsQuality('auto');
      expect(cubit.state.graphicsQuality, 'high');
    });
  });

  group('SettingsCubit loadSettings', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      StorageService.instance.resetForTesting();
      await StorageService.instance.initialize();
    });

    test('loadSettings applies persisted values', () async {
      await StorageService.instance.saveSettings(
        musicVolume: 0.35,
        sfxVolume: 0.45,
        showFps: false,
        showGrid: false,
        screenShake: false,
        particleIntensity: 0.6,
        graphicsQuality: 'medium',
      );

      final cubit = SettingsCubit();
      addTearDown(cubit.close);
      await cubit.loadSettings();

      expect(cubit.state.musicVolume, 0.35);
      expect(cubit.state.sfxVolume, 0.45);
      expect(cubit.state.showFps, isFalse);
      expect(cubit.state.showGrid, isFalse);
      expect(cubit.state.screenShake, isFalse);
      expect(cubit.state.particleIntensity, 0.6);
      expect(cubit.state.graphicsQuality, 'medium');
    });

    test('loadSettings migrates legacy auto quality to high', () async {
      await StorageService.instance.saveSettings(
        musicVolume: 0.7,
        sfxVolume: 0.8,
        showFps: true,
        showGrid: true,
        screenShake: true,
        particleIntensity: 1.0,
        graphicsQuality: 'auto',
      );

      final cubit = SettingsCubit();
      addTearDown(cubit.close);
      await cubit.loadSettings();

      expect(cubit.state.graphicsQuality, 'high');
    });

    test('loadSettings defaults invalid quality to high', () async {
      await StorageService.instance.saveSettings(
        musicVolume: 0.7,
        sfxVolume: 0.8,
        showFps: true,
        showGrid: true,
        screenShake: true,
        particleIntensity: 1.0,
        graphicsQuality: 'ultra',
      );

      final cubit = SettingsCubit();
      addTearDown(cubit.close);
      await cubit.loadSettings();

      expect(cubit.state.graphicsQuality, 'high');
    });

    test('loadSettings keeps defaults when storage is empty', () async {
      final cubit = SettingsCubit();
      addTearDown(cubit.close);
      await cubit.loadSettings();

      expect(cubit.state, const SettingsState());
    });
  });

  group('SettingsCubit state transitions', () {
    test('multiple state changes in sequence', () {
      final cubit = SettingsCubit();

      cubit.setMusicVolume(0.5);
      expect(cubit.state.musicVolume, 0.5);

      cubit.setSfxVolume(0.6);
      expect(cubit.state.sfxVolume, 0.6);
      expect(cubit.state.musicVolume, 0.5); // still preserved

      cubit.toggleFps();
      expect(cubit.state.showFps, isFalse);
      expect(cubit.state.musicVolume, 0.5);
      expect(cubit.state.sfxVolume, 0.6);
    });

    test('state changes emit new states', () {
      final cubit = SettingsCubit();
      final states = <SettingsState>[];

      cubit.stream.listen(states.add);

      cubit.setMusicVolume(0.5);
      cubit.setSfxVolume(0.6);
      cubit.toggleFps();

      // Allow stream to propagate
      Future.delayed(Duration.zero, () {
        expect(states.length, greaterThanOrEqualTo(3));
      });
    });
  });
}
