import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/settings/settings_cubit.dart';
import '../../bloc/settings/settings_state.dart';
import '../theme/neon_theme.dart';
import '../widgets/animated_grid_background.dart';
import '../widgets/neon_title.dart';
import '../widgets/neon_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGridBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: NeonColors.cyan),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: NeonTitle(
                          text: 'SETTINGS',
                          fontSize: 32,
                          color: NeonColors.purple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Settings content
              Expanded(
                child: BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, settings) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle('AUDIO'),
                          const SizedBox(height: 16),
                          _SliderSetting(
                            label: 'Music Volume',
                            value: settings.musicVolume,
                            color: NeonColors.cyan,
                            onChanged: (v) =>
                                context.read<SettingsCubit>().setMusicVolume(v),
                          ),
                          const SizedBox(height: 12),
                          _SliderSetting(
                            label: 'SFX Volume',
                            value: settings.sfxVolume,
                            color: NeonColors.magenta,
                            onChanged: (v) =>
                                context.read<SettingsCubit>().setSfxVolume(v),
                          ),

                          const SizedBox(height: 32),
                          _SectionTitle('GRAPHICS'),
                          const SizedBox(height: 16),
                          _ToggleSetting(
                            label: 'Show FPS Counter',
                            value: settings.showFps,
                            color: NeonColors.green,
                            onChanged: (_) =>
                                context.read<SettingsCubit>().toggleFps(),
                          ),
                          const SizedBox(height: 12),
                          _ToggleSetting(
                            label: 'Show Build Grid',
                            value: settings.showGrid,
                            color: NeonColors.yellow,
                            onChanged: (_) =>
                                context.read<SettingsCubit>().toggleGrid(),
                          ),
                          const SizedBox(height: 12),
                          _SliderSetting(
                            label: 'Particle Intensity',
                            value: settings.particleIntensity,
                            color: NeonColors.orange,
                            onChanged: (v) => context
                                .read<SettingsCubit>()
                                .setParticleIntensity(v),
                          ),

                          const SizedBox(height: 32),
                          _SectionTitle('GAMEPLAY'),
                          const SizedBox(height: 16),
                          _ToggleSetting(
                            label: 'Screen Shake',
                            value: settings.screenShake,
                            color: NeonColors.red,
                            onChanged: (_) =>
                                context.read<SettingsCubit>().toggleScreenShake(),
                          ),

                          const SizedBox(height: 40),
                          Center(
                            child: NeonButton(
                              text: 'RESET TO DEFAULTS',
                              width: 220,
                              color: NeonColors.red,
                              onPressed: () =>
                                  context.read<SettingsCubit>().resetToDefaults(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: NeonTextStyles.subtitle.copyWith(
        fontSize: 18,
        letterSpacing: 4,
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonColors.darkBg.withOpacity(0.8),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: NeonTextStyles.body),
              Text(
                '${(value * 100).toInt()}%',
                style: NeonTextStyles.button.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  const _ToggleSetting({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NeonColors.darkBg.withOpacity(0.8),
          border: Border.all(
            color: value ? color : color.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: NeonTextStyles.body),
            Container(
              width: 50,
              height: 26,
              decoration: BoxDecoration(
                color: value ? color.withOpacity(0.3) : Colors.transparent,
                border: Border.all(color: color),
                borderRadius: BorderRadius.circular(13),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: value ? color : color.withOpacity(0.5),
                    shape: BoxShape.circle,
                    boxShadow: value
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
