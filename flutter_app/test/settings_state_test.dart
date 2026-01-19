import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/bloc/settings/settings_state.dart';

void main() {
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
  });

  test('equatable props compare equality', () {
    const a = SettingsState();
    const b = SettingsState();
    const c = SettingsState(musicVolume: 0.5);

    expect(a, equals(b));
    expect(a == c, isFalse);
  });
}
