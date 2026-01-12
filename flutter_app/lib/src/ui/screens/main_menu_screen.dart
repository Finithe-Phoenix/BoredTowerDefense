import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../widgets/cyber_grid_background.dart';
import '../widgets/epic_neon_button.dart';
import '../widgets/epic_neon_title.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late List<Animation<double>> _buttonAnimations;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Staggered button animations
    _buttonAnimations = List.generate(5, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: Interval(
            0.2 + index * 0.15,
            0.5 + index * 0.15,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CyberGridBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Animated Title Entry
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _fadeController,
                    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _fadeController,
                      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
                    )),
                    child: const Column(
                      children: [
                        EpicNeonTitle(
                          text: 'NEON DEFENSE',
                          fontSize: 52,
                          primaryColor: NeonColors.cyan,
                          secondaryColor: NeonColors.magenta,
                        ),
                        SizedBox(height: 8),
                        _SubtitleWidget(),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Staggered Menu Buttons
                _buildAnimatedButton(
                  animation: _buttonAnimations[0],
                  child: EpicNeonButton(
                    text: 'CAMPAIGN',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => Navigator.pushNamed(context, '/levels'),
                    color: NeonColors.cyan,
                  ),
                ),
                const SizedBox(height: 16),

                _buildAnimatedButton(
                  animation: _buttonAnimations[1],
                  child: EpicNeonButton(
                    text: 'STORY',
                    icon: Icons.auto_stories_rounded,
                    onPressed: () => Navigator.pushNamed(context, '/story'),
                    color: NeonColors.yellow,
                  ),
                ),
                const SizedBox(height: 16),

                _buildAnimatedButton(
                  animation: _buttonAnimations[2],
                  child: EpicNeonButton(
                    text: 'QUICK PLAY',
                    icon: Icons.bolt_rounded,
                    onPressed: () => Navigator.pushNamed(context, '/game', arguments: 1),
                    color: NeonColors.green,
                  ),
                ),
                const SizedBox(height: 16),

                _buildAnimatedButton(
                  animation: _buttonAnimations[3],
                  child: EpicNeonButton(
                    text: 'SETTINGS',
                    icon: Icons.tune_rounded,
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                    color: NeonColors.purple,
                  ),
                ),
                const SizedBox(height: 16),

                _buildAnimatedButton(
                  animation: _buttonAnimations[4],
                  child: EpicNeonButton(
                    text: 'CREDITS',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: () => _showCreditsDialog(context),
                    color: NeonColors.magenta,
                  ),
                ),

                const Spacer(flex: 3),

                // Version info with fade
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _fadeController,
                    curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
                  ),
                  child: const _VersionBadge(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required Animation<double> animation,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
    );
  }

  void _showCreditsDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Credits',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: const _CreditsDialog(),
          ),
        );
      },
    );
  }
}

class _SubtitleWidget extends StatefulWidget {
  const _SubtitleWidget();

  @override
  State<_SubtitleWidget> createState() => _SubtitleWidgetState();
}

class _SubtitleWidgetState extends State<_SubtitleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              NeonColors.magenta,
              NeonColors.purple,
              NeonColors.cyan,
              NeonColors.purple,
              NeonColors.magenta,
            ],
            stops: [
              0.0,
              _controller.value * 0.5,
              _controller.value,
              _controller.value * 0.5 + 0.5,
              1.0,
            ].map((e) => e.clamp(0.0, 1.0)).toList(),
          ).createShader(bounds),
          child: Text(
            'TOWER DEFENSE',
            style: NeonTextStyles.subtitle.copyWith(
              letterSpacing: 10,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: NeonColors.cyan.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: NeonColors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: NeonColors.green.withOpacity(0.8),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'v1.0.0',
            style: NeonTextStyles.small.copyWith(
              color: NeonColors.cyan.withOpacity(0.7),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditsDialog extends StatelessWidget {
  const _CreditsDialog();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: NeonColors.darkBg.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: NeonColors.magenta, width: 2),
          boxShadow: [
            BoxShadow(
              color: NeonColors.magenta.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: NeonColors.magenta,
                  size: 28,
                  shadows: [
                    Shadow(
                      color: NeonColors.magenta.withOpacity(0.8),
                      blurRadius: 10,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Text(
                  'CREDITS',
                  style: NeonTextStyles.subtitle.copyWith(
                    color: NeonColors.magenta,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: NeonColors.gridLine, height: 1),
            const SizedBox(height: 24),

            // Content
            _creditItem('GAME', 'NEON DEFENSE', NeonColors.cyan),
            const SizedBox(height: 16),
            _creditItem('ENGINE', 'Flutter + Flame', NeonColors.green),
            const SizedBox(height: 16),
            _creditItem('STYLE', 'Tron / Synthwave', NeonColors.purple),
            const SizedBox(height: 16),
            _creditItem('VERSION', '1.0.0 Release', NeonColors.yellow),

            const SizedBox(height: 32),

            // Close button
            EpicNeonButton(
              text: 'CLOSE',
              width: 160,
              height: 44,
              color: NeonColors.magenta,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _creditItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 100,
          child: Text(
            label,
            style: NeonTextStyles.small.copyWith(
              color: NeonColors.white.withOpacity(0.5),
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: NeonTextStyles.body.copyWith(
              color: color,
              shadows: [
                Shadow(color: color.withOpacity(0.5), blurRadius: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
