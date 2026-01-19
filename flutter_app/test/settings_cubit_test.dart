import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/bloc/settings/settings_cubit.dart';
import 'package:bored_games/src/bloc/settings/settings_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('setMusicVolume clamps and updates state', () {
    final cubit = SettingsCubit();

    cubit.setMusicVolume(2.0);
    expect(cubit.state.musicVolume, 1.0);

    cubit.setMusicVolume(-1.0);
    expect(cubit.state.musicVolume, 0.0);
  });

  test('setSfxVolume clamps and updates state', () {
    final cubit = SettingsCubit();

    cubit.setSfxVolume(2.0);
    expect(cubit.state.sfxVolume, 1.0);

    cubit.setSfxVolume(-1.0);
    expect(cubit.state.sfxVolume, 0.0);
  });

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

  test('particle intensity clamps and reset restores defaults', () {
    final cubit = SettingsCubit();

    cubit.setParticleIntensity(2.0);
    expect(cubit.state.particleIntensity, 1.0);

    cubit.setParticleIntensity(-1.0);
    expect(cubit.state.particleIntensity, 0.0);

    cubit.resetToDefaults();
    expect(cubit.state, const SettingsState());
  });
}
