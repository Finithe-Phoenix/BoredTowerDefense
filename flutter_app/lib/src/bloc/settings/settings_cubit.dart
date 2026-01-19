import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/audio_service.dart';
import '../../services/procedural_music_service.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void setMusicVolume(double volume) {
    final clampedVolume = volume.clamp(0.0, 1.0);
    ProceduralMusicService.instance.setVolume(clampedVolume);
    emit(state.copyWith(musicVolume: clampedVolume));
  }

  void setSfxVolume(double volume) {
    final clampedVolume = volume.clamp(0.0, 1.0);
    AudioService.instance.setSfxVolume(clampedVolume);
    emit(state.copyWith(sfxVolume: clampedVolume));
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
