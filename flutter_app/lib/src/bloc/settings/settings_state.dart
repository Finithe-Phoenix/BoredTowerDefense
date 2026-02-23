import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.musicVolume = 0.7,
    this.sfxVolume = 0.8,
    this.showFps = true,
    this.showGrid = true,
    this.particleIntensity = 1.0,
    this.screenShake = true,
    this.graphicsQuality = 'high', // 'low', 'medium', 'high', 'extreme'
  });

  final double musicVolume;
  final double sfxVolume;
  final bool showFps;
  final bool showGrid;
  final double particleIntensity;
  final bool screenShake;
  final String graphicsQuality;

  SettingsState copyWith({
    double? musicVolume,
    double? sfxVolume,
    bool? showFps,
    bool? showGrid,
    double? particleIntensity,
    bool? screenShake,
    String? graphicsQuality,
  }) {
    return SettingsState(
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      showFps: showFps ?? this.showFps,
      showGrid: showGrid ?? this.showGrid,
      particleIntensity: particleIntensity ?? this.particleIntensity,
      screenShake: screenShake ?? this.screenShake,
      graphicsQuality: graphicsQuality ?? this.graphicsQuality,
    );
  }

  @override
  List<Object?> get props => [
        musicVolume,
        sfxVolume,
        showFps,
        showGrid,
        particleIntensity,
        screenShake,
        graphicsQuality,
      ];
}
