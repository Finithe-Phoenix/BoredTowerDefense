import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/settings/settings_cubit.dart';
import '../../bloc/settings/settings_state.dart';
import '../theme/neon_theme.dart';
import '../widgets/cyber_grid_background.dart';
import '../widgets/epic_neon_title.dart';
import '../widgets/tron_button.dart';
import '../widgets/tron_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CyberGridBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    TronCard(
                      color: NeonColors.cyan,
                      width: 48,
                      height: 48,
                      delay: const Duration(milliseconds: 100),
                      onTap: () => Navigator.pop(context),
                      child: const Center(
                        child: Icon(Icons.arrow_back, color: NeonColors.cyan),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: EpicNeonTitle(
                          text: 'SETTINGS',
                          fontSize: 32,
                          primaryColor: NeonColors.purple,
                          secondaryColor: NeonColors.cyan,
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
                          _SectionTitle('AUDIO', delay: const Duration(milliseconds: 200)),
                          const SizedBox(height: 16),
                          _TronSliderSetting(
                            label: 'Music Volume',
                            value: settings.musicVolume,
                            color: NeonColors.cyan,
                            delay: const Duration(milliseconds: 250),
                            onChanged: (v) =>
                                context.read<SettingsCubit>().setMusicVolume(v),
                          ),
                          const SizedBox(height: 12),
                          _TronSliderSetting(
                            label: 'SFX Volume',
                            value: settings.sfxVolume,
                            color: NeonColors.magenta,
                            delay: const Duration(milliseconds: 300),
                            onChanged: (v) =>
                                context.read<SettingsCubit>().setSfxVolume(v),
                          ),

                          const SizedBox(height: 32),
                          _SectionTitle('GRAPHICS', delay: const Duration(milliseconds: 350)),
                          const SizedBox(height: 16),
                          _TronToggleSetting(
                            label: 'Show FPS Counter',
                            value: settings.showFps,
                            color: NeonColors.green,
                            delay: const Duration(milliseconds: 400),
                            onChanged: (_) =>
                                context.read<SettingsCubit>().toggleFps(),
                          ),
                          const SizedBox(height: 12),
                          _TronToggleSetting(
                            label: 'Show Build Grid',
                            value: settings.showGrid,
                            color: NeonColors.yellow,
                            delay: const Duration(milliseconds: 450),
                            onChanged: (_) =>
                                context.read<SettingsCubit>().toggleGrid(),
                          ),
                          const SizedBox(height: 12),
                          _TronSliderSetting(
                            label: 'Particle Intensity',
                            value: settings.particleIntensity,
                            color: NeonColors.orange,
                            delay: const Duration(milliseconds: 500),
                            onChanged: (v) => context
                                .read<SettingsCubit>()
                                .setParticleIntensity(v),
                          ),

                          const SizedBox(height: 32),
                          _SectionTitle('GAMEPLAY', delay: const Duration(milliseconds: 550)),
                          const SizedBox(height: 16),
                          _TronToggleSetting(
                            label: 'Screen Shake',
                            value: settings.screenShake,
                            color: NeonColors.red,
                            delay: const Duration(milliseconds: 600),
                            onChanged: (_) =>
                                context.read<SettingsCubit>().toggleScreenShake(),
                          ),

                          const SizedBox(height: 40),
                          Center(
                            child: TronButton(
                              text: 'RESET TO DEFAULTS',
                              width: 260,
                              color: NeonColors.red,
                              delay: const Duration(milliseconds: 700),
                              onPressed: () =>
                                  context.read<SettingsCubit>().resetToDefaults(),
                            ),
                          ),
                          const SizedBox(height: 20),
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

class _SectionTitle extends StatefulWidget {
  const _SectionTitle(this.text, {this.delay = Duration.zero});
  final String text;
  final Duration delay;

  @override
  State<_SectionTitle> createState() => _SectionTitleState();
}

class _SectionTitleState extends State<_SectionTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(-20 * (1 - _animation.value), 0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: NeonColors.cyan.withOpacity(_animation.value),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: NeonColors.cyan.withOpacity(0.5 * _animation.value),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.text,
                  style: NeonTextStyles.subtitle.copyWith(
                    fontSize: 18,
                    letterSpacing: 4,
                    color: NeonColors.white.withOpacity(_animation.value),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TronSliderSetting extends StatelessWidget {
  const _TronSliderSetting({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
    this.delay = Duration.zero,
  });

  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TronCard(
      color: color,
      delay: delay,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: NeonTextStyles.body),
                Text(
                  '${(value * 100).toInt()}%',
                  style: NeonTextStyles.button.copyWith(
                    color: color,
                    shadows: [
                      Shadow(color: color.withOpacity(0.5), blurRadius: 8),
                    ],
                  ),
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
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: value,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TronToggleSetting extends StatelessWidget {
  const _TronToggleSetting({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
    this.delay = Duration.zero,
  });

  final String label;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TronCard(
      color: value ? color : color.withOpacity(0.5),
      delay: delay,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: NeonTextStyles.body),
            _TronToggle(value: value, color: color),
          ],
        ),
      ),
    );
  }
}

class _TronToggle extends StatelessWidget {
  const _TronToggle({required this.value, required this.color});

  final bool value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 26,
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.3) : Colors.transparent,
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(13),
        boxShadow: value
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
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
                      color: color.withOpacity(0.8),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
