import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/settings/settings_cubit.dart';
import '../../bloc/settings/settings_state.dart';
import '../theme/neon_theme.dart';
import '../widgets/cyber_grid_background.dart';
import '../widgets/epic_neon_title.dart';
import '../widgets/tron_button.dart';
import '../widgets/tron_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _glitchController;
  late AnimationController _cornerController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();

    // Glitch intro animation
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    // Corner animations
    _cornerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Particle effects
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _glitchController.dispose();
    _cornerController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Enhanced background
          CyberGridBackground(
            child: Stack(
              children: [
                // Floating particles
                AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _SettingsParticlesPainter(
                        animation: _particleController.value,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),

                // Main content
                SafeArea(
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
                                child: Icon(Icons.arrow_back,
                                    color: NeonColors.cyan),
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
                                  _EpicSectionHeader(
                                    text: 'AUDIO',
                                    icon: Icons.volume_up,
                                    color: NeonColors.cyan,
                                    delay: const Duration(milliseconds: 200),
                                  ),
                                  const SizedBox(height: 16),
                                  _TronSliderSetting(
                                    label: 'Music Volume',
                                    value: settings.musicVolume,
                                    color: NeonColors.cyan,
                                    delay: const Duration(milliseconds: 250),
                                    onChanged: (v) => context
                                        .read<SettingsCubit>()
                                        .setMusicVolume(v),
                                  ),
                                  const SizedBox(height: 12),
                                  _TronSliderSetting(
                                    label: 'SFX Volume',
                                    value: settings.sfxVolume,
                                    color: NeonColors.magenta,
                                    delay: const Duration(milliseconds: 300),
                                    onChanged: (v) => context
                                        .read<SettingsCubit>()
                                        .setSfxVolume(v),
                                  ),
                                  const SizedBox(height: 32),
                                  _EpicSectionHeader(
                                    text: 'GRAPHICS',
                                    icon: Icons.computer,
                                    color: NeonColors.green,
                                    delay: const Duration(milliseconds: 350),
                                  ),
                                  const SizedBox(height: 16),
                                  _TronToggleSetting(
                                    label: 'Show FPS Counter',
                                    value: settings.showFps,
                                    color: NeonColors.green,
                                    delay: const Duration(milliseconds: 400),
                                    onChanged: (_) => context
                                        .read<SettingsCubit>()
                                        .toggleFps(),
                                  ),
                                  const SizedBox(height: 12),
                                  _TronToggleSetting(
                                    label: 'Show Build Grid',
                                    value: settings.showGrid,
                                    color: NeonColors.yellow,
                                    delay: const Duration(milliseconds: 450),
                                    onChanged: (_) => context
                                        .read<SettingsCubit>()
                                        .toggleGrid(),
                                  ),
                                  const SizedBox(height: 12),
                                  _TronDropdownSetting(
                                    label: 'Graphics Quality',
                                    value: settings.graphicsQuality,
                                    options: const {
                                      'low': 'Low (Performance)',
                                      'medium': 'Medium (Balanced)',
                                      'high': 'High (Maximum Effects)',
                                      'extreme': 'Extreme (Ultra Effects)',
                                    },
                                    color: NeonColors.magenta,
                                    delay: const Duration(milliseconds: 475),
                                    onChanged: (quality) => context
                                        .read<SettingsCubit>()
                                        .setGraphicsQuality(quality),
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
                                  _EpicSectionHeader(
                                    text: 'GAMEPLAY',
                                    icon: Icons.gamepad,
                                    color: NeonColors.red,
                                    delay: const Duration(milliseconds: 550),
                                  ),
                                  const SizedBox(height: 16),
                                  _TronToggleSetting(
                                    label: 'Screen Shake',
                                    value: settings.screenShake,
                                    color: NeonColors.red,
                                    delay: const Duration(milliseconds: 600),
                                    onChanged: (_) => context
                                        .read<SettingsCubit>()
                                        .toggleScreenShake(),
                                  ),
                                  const SizedBox(height: 40),
                                  Center(
                                    child: _EpicResetButton(
                                      onPressed: () => context
                                          .read<SettingsCubit>()
                                          .resetToDefaults(),
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

                // Corner HUD decorations
                ..._buildCornerDecorations(),
              ],
            ),
          ),

          // Glitch intro overlay
          _GlitchIntroOverlay(controller: _glitchController),
        ],
      ),
    );
  }

  List<Widget> _buildCornerDecorations() {
    return [
      Positioned(
        top: 20,
        left: 20,
        child: _SettingsCornerHUD(
          controller: _cornerController,
          label: 'NETWORK',
          value: 'ONLINE',
          color: NeonColors.green,
        ),
      ),
      Positioned(
        top: 20,
        right: 20,
        child: _SettingsCornerHUD(
          controller: _cornerController,
          label: 'AUDIO',
          value: 'ACTIVE',
          color: NeonColors.cyan,
        ),
      ),
      Positioned(
        bottom: 20,
        left: 20,
        child: _SettingsCornerHUD(
          controller: _cornerController,
          label: 'GRAPHICS',
          value: 'OPTIMAL',
          color: NeonColors.yellow,
        ),
      ),
      Positioned(
        bottom: 20,
        right: 20,
        child: _SettingsCornerHUD(
          controller: _cornerController,
          label: 'CONTROLS',
          value: 'READY',
          color: NeonColors.magenta,
        ),
      ),
    ];
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
                        color:
                            NeonColors.cyan.withOpacity(0.5 * _animation.value),
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

// Epic Section Header with Materialization
class _EpicSectionHeader extends StatefulWidget {
  const _EpicSectionHeader({
    required this.text,
    required this.icon,
    required this.color,
    this.delay = Duration.zero,
  });

  final String text;
  final IconData icon;
  final Color color;
  final Duration delay;

  @override
  State<_EpicSectionHeader> createState() => _EpicSectionHeaderState();
}

class _EpicSectionHeaderState extends State<_EpicSectionHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
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
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.05),
              border: Border.all(
                color: widget.color.withOpacity(_animation.value * 0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.2 * _animation.value),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon with rotating ring
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating ring
                      Transform.rotate(
                        angle: _animation.value * math.pi * 2,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      // Icon
                      Icon(
                        widget.icon,
                        color: widget.color,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Text
                Expanded(
                  child: Text(
                    widget.text,
                    style: NeonTextStyles.subtitle.copyWith(
                      fontSize: 18,
                      letterSpacing: 4,
                      color: widget.color,
                      shadows: [
                        Shadow(color: widget.color, blurRadius: 10),
                      ],
                    ),
                  ),
                ),
                // Corner bracket
                CustomPaint(
                  size: const Size(20, 20),
                  painter: _CornerBracketPainter(
                    color: widget.color,
                    progress: _animation.value,
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

// Epic Reset Button
class _EpicResetButton extends StatefulWidget {
  const _EpicResetButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_EpicResetButton> createState() => _EpicResetButtonState();
}

class _EpicResetButtonState extends State<_EpicResetButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              width: 260,
              height: 50,
              decoration: BoxDecoration(
                color: NeonColors.red.withOpacity(_isHovered ? 0.15 : 0.05),
                border: Border.all(
                  color: NeonColors.red.withOpacity(_isHovered ? 0.8 : 0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: NeonColors.red.withOpacity(_isHovered ? 0.4 : 0.2),
                    blurRadius: _isHovered ? 25 : 15,
                    spreadRadius: _isHovered ? 3 : 1,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Energy particles
                  if (_isHovered)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ButtonParticlesPainter(
                          animation: _controller.value,
                          color: NeonColors.red,
                        ),
                      ),
                    ),

                  // Text
                  Center(
                    child: Text(
                      'RESET TO DEFAULTS',
                      style: NeonTextStyles.button.copyWith(
                        color: NeonColors.red,
                        fontSize: 16,
                        letterSpacing: 2,
                        shadows: _isHovered
                            ? [
                                Shadow(color: NeonColors.red, blurRadius: 10),
                                Shadow(
                                    color: NeonColors.orange, blurRadius: 20),
                              ]
                            : [Shadow(color: NeonColors.red, blurRadius: 8)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Glitch Intro Overlay
class _GlitchIntroOverlay extends StatelessWidget {
  const _GlitchIntroOverlay({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (controller.value >= 1.0) return const SizedBox.shrink();

        return IgnorePointer(
          child: Container(
            color: Colors.black.withOpacity((1 - controller.value) * 0.8),
            child: CustomPaint(
              painter: _GlitchBarsPainter(
                progress: controller.value,
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}

// Settings Corner HUD
class _SettingsCornerHUD extends StatelessWidget {
  const _SettingsCornerHUD({
    required this.controller,
    required this.label,
    required this.value,
    required this.color,
  });

  final AnimationController controller;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            border: Border.all(
              color: color.withOpacity(0.5 + controller.value * 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: color, blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 8,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(color: color, blurRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom Painters
class _SettingsParticlesPainter extends CustomPainter {
  final double animation;

  _SettingsParticlesPainter({required this.animation});

  static final Paint _particlePaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    int rngState = 0x98765;
    int lcgNext() {
      rngState = (1664525 * rngState + 1013904223) & 0x7fffffff;
      return rngState;
    }

    double nextUnit() => lcgNext() / 0x7fffffff;

    for (int i = 0; i < 40; i++) {
      final x = nextUnit() * size.width;
      final baseY = nextUnit() * size.height;
      final y = (baseY + animation * 100) % size.height;

      final particleSize = 1 + nextUnit() * 2;
      final opacity = 0.1 + nextUnit() * 0.3;

      final colors = [NeonColors.cyan, NeonColors.purple, NeonColors.magenta];
      final color = colors[i % colors.length];

      _particlePaint.color = color.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), particleSize, _particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SettingsParticlesPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _GlitchBarsPainter extends CustomPainter {
  final double progress;

  _GlitchBarsPainter({required this.progress});

  static final Paint _barPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    int rngState = (progress * 1000).toInt() ^ 0x12345;
    int lcgNext() {
      rngState = (1664525 * rngState + 1013904223) & 0x7fffffff;
      return rngState;
    }

    double nextUnit() => lcgNext() / 0x7fffffff;

    for (int i = 0; i < 15; i++) {
      final y = nextUnit() * size.height;
      final height = 2.0 + nextUnit() * 8;
      final xOffset = (nextUnit() - 0.5) * 30;

      _barPaint.color = NeonColors.cyan.withOpacity((1 - progress) * 0.3);
      canvas.drawRect(
        Rect.fromLTWH(xOffset, y, size.width, height),
        _barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlitchBarsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double progress;

  _CornerBracketPainter({required this.color, required this.progress});

  static final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    _paint.color = color.withOpacity(progress);

    final path = Path()
      ..moveTo(size.width * 0.6, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.6);

    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ButtonParticlesPainter extends CustomPainter {
  final double animation;
  final Color color;

  _ButtonParticlesPainter({required this.animation, required this.color});

  static final Paint _particlePaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    int rngState = (animation * 1000).toInt() ^ 0xabcde;
    int lcgNext() {
      rngState = (1664525 * rngState + 1013904223) & 0x7fffffff;
      return rngState;
    }

    double nextUnit() => lcgNext() / 0x7fffffff;

    for (int i = 0; i < 10; i++) {
      final x = nextUnit() * size.width;
      final y = nextUnit() * size.height;
      final particleSize = 1 + nextUnit() * 1.5;

      _particlePaint.color = color.withOpacity(0.3 + nextUnit() * 0.4);
      canvas.drawCircle(Offset(x, y), particleSize, _particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ButtonParticlesPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

// ============================================================================
// TRON DROPDOWN SETTING
// ============================================================================

class _TronDropdownSetting extends StatefulWidget {
  const _TronDropdownSetting({
    required this.label,
    required this.value,
    required this.options,
    required this.color,
    required this.onChanged,
    this.delay = Duration.zero,
  });

  final String label;
  final String value;
  final Map<String, String> options; // value -> displayName
  final Color color;
  final ValueChanged<String> onChanged;
  final Duration delay;

  @override
  State<_TronDropdownSetting> createState() => _TronDropdownSettingState();
}

class _TronDropdownSettingState extends State<_TronDropdownSetting> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return TronCard(
      color: widget.color,
      delay: widget.delay,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with label and current value
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.label, style: NeonTextStyles.body),
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.2),
                      border: Border.all(color: widget.color, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.options[widget.value] ?? widget.value,
                          style: NeonTextStyles.body.copyWith(
                            color: widget.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: widget.color,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Expanded options list
            if (_isExpanded) ...[
              const SizedBox(height: 12),
              ...widget.options.entries.map((entry) {
                final isSelected = entry.key == widget.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      widget.onChanged(entry.key);
                      setState(() => _isExpanded = false);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.color.withOpacity(0.3)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? widget.color
                              : widget.color.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.value,
                        style: NeonTextStyles.body.copyWith(
                          color: isSelected
                              ? widget.color
                              : widget.color.withOpacity(0.7),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
