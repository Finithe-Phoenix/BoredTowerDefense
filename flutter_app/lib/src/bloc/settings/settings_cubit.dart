import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/audio_service.dart';
import '../../services/procedural_music_service.dart';
import '../../services/storage_service.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  /// Initialize settings from storage
  Future<void> loadSettings() async {
    final savedSettings = StorageService.instance.loadSettings();
    if (savedSettings != null) {
      final musicVolume =
          (savedSettings['musicVolume'] as num?)?.toDouble() ?? 0.7;
      final sfxVolume = (savedSettings['sfxVolume'] as num?)?.toDouble() ?? 0.8;
      final showFps = savedSettings['showFps'] as bool? ?? true;
      final showGrid = savedSettings['showGrid'] as bool? ?? true;
      final screenShake = savedSettings['screenShake'] as bool? ?? true;
      final particleIntensity =
          (savedSettings['particleIntensity'] as num?)?.toDouble() ?? 1.0;
      final rawGraphicsQuality = savedSettings['graphicsQuality'] as String?;
      final normalizedQuality = _normalizeGraphicsQuality(rawGraphicsQuality);
      final graphicsQuality =
          normalizedQuality.isEmpty ? 'high' : normalizedQuality;

      emit(SettingsState(
        musicVolume: musicVolume,
        sfxVolume: sfxVolume,
        showFps: showFps,
        showGrid: showGrid,
        screenShake: screenShake,
        particleIntensity: particleIntensity,
        graphicsQuality: graphicsQuality,
      ));

      // Apply audio settings immediately
      ProceduralMusicService.instance.setVolume(musicVolume);
      AudioService.instance.setSfxVolume(sfxVolume);
    }
  }

  /// Save current settings to storage
  Future<void> _saveSettings() async {
    await StorageService.instance.saveSettings(
      musicVolume: state.musicVolume,
      sfxVolume: state.sfxVolume,
      showFps: state.showFps,
      showGrid: state.showGrid,
      screenShake: state.screenShake,
      particleIntensity: state.particleIntensity,
      graphicsQuality: state.graphicsQuality,
    );
  }

  void setMusicVolume(double volume) {
    final clampedVolume = volume.clamp(0.0, 1.0);
    ProceduralMusicService.instance.setVolume(clampedVolume);
    emit(state.copyWith(musicVolume: clampedVolume));
    _saveSettings();
  }

  void setSfxVolume(double volume) {
    final clampedVolume = volume.clamp(0.0, 1.0);
    AudioService.instance.setSfxVolume(clampedVolume);
    emit(state.copyWith(sfxVolume: clampedVolume));
    _saveSettings();
  }

  void toggleFps() {
    emit(state.copyWith(showFps: !state.showFps));
    _saveSettings();
  }

  void toggleGrid() {
    emit(state.copyWith(showGrid: !state.showGrid));
    _saveSettings();
  }

  void setParticleIntensity(double intensity) {
    emit(state.copyWith(particleIntensity: intensity.clamp(0.0, 1.0)));
    _saveSettings();
  }

  void toggleScreenShake() {
    emit(state.copyWith(screenShake: !state.screenShake));
    _saveSettings();
  }

  void setGraphicsQuality(String quality) {
    // Validate quality value
    final normalized = _normalizeGraphicsQuality(quality);
    if (normalized.isEmpty) {
      return;
    }
    emit(state.copyWith(graphicsQuality: normalized));
    _saveSettings();
  }

  String _normalizeGraphicsQuality(String? quality) {
    switch (quality) {
      case 'low':
      case 'medium':
      case 'high':
      case 'extreme':
        return quality!;
      case 'auto':
        // Legacy value migration: replace auto profile with high quality.
        return 'high';
      default:
        return '';
    }
  }

  void resetToDefaults() {
    emit(const SettingsState());
    _saveSettings();
    // Apply defaults to services
    ProceduralMusicService.instance.setVolume(0.7);
    AudioService.instance.setSfxVolume(0.8);
  }
}
