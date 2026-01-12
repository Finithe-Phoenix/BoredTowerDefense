import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void setMusicVolume(double volume) {
    emit(state.copyWith(musicVolume: volume.clamp(0.0, 1.0)));
  }

  void setSfxVolume(double volume) {
    emit(state.copyWith(sfxVolume: volume.clamp(0.0, 1.0)));
  }

  void toggleFps() {
    emit(state.copyWith(showFps: !state.showFps));
  }

  void toggleGrid() {
    emit(state.copyWith(showGrid: !state.showGrid));
  }

  void setParticleIntensity(double intensity) {
    emit(state.copyWith(particleIntensity: intensity.clamp(0.0, 1.0)));
  }

  void toggleScreenShake() {
    emit(state.copyWith(screenShake: !state.screenShake));
  }

  void resetToDefaults() {
    emit(const SettingsState());
  }
}
