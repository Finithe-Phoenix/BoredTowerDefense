import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../widgets/cyber_grid_background.dart';
import '../widgets/epic_neon_title.dart';
import '../widgets/tron_button.dart';
import '../widgets/tron_dialog.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
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

                // Staggered TRON Buttons with built-in materialization
                TronButton(
                  text: 'CAMPAIGN',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => Navigator.pushNamed(context, '/levels'),
                  color: NeonColors.cyan,
                  delay: const Duration(milliseconds: 200),
                ),
                const SizedBox(height: 16),

                TronButton(
                  text: 'STORY',
                  icon: Icons.auto_stories_rounded,
                  onPressed: () => Navigator.pushNamed(context, '/story'),
                  color: NeonColors.yellow,
                  delay: const Duration(milliseconds: 300),
                ),
                const SizedBox(height: 16),

                TronButton(
                  text: 'UPGRADES',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: () => Navigator.pushNamed(context, '/upgrades'),
                  color: NeonColors.cyan,
                  delay: const Duration(milliseconds: 400),
                ),
                const SizedBox(height: 16),

                TronButton(
                  text: 'QUICK PLAY',
                  icon: Icons.bolt_rounded,
                  onPressed: () => Navigator.pushNamed(context, '/game', arguments: 1),
                  color: NeonColors.green,
                  delay: const Duration(milliseconds: 500),
                ),
                const SizedBox(height: 16),

                TronButton(
                  text: 'SETTINGS',
                  icon: Icons.tune_rounded,
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                  color: NeonColors.purple,
                  delay: const Duration(milliseconds: 600),
                ),
                const SizedBox(height: 16),

                TronButton(
                  text: 'CREDITS',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: () => _showCreditsDialog(context),
                  color: NeonColors.magenta,
                  delay: const Duration(milliseconds: 700),
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

  void _showCreditsDialog(BuildContext context) {
    TronDialog.show(
      context: context,
      title: 'CREDITS',
      icon: Icons.auto_awesome_rounded,
      primaryColor: NeonColors.magenta,
      width: 380,
      builder: (context) => const _CreditsContent(),
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

class _CreditsContent extends StatelessWidget {
  const _CreditsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _creditItem('GAME', 'NEON DEFENSE', NeonColors.cyan),
        const SizedBox(height: 16),
        _creditItem('ENGINE', 'Flutter + Flame', NeonColors.green),
        const SizedBox(height: 16),
        _creditItem('STYLE', 'Tron / Synthwave', NeonColors.purple),
        const SizedBox(height: 16),
        _creditItem('VERSION', '1.0.0 Release', NeonColors.yellow),
        const SizedBox(height: 32),
        TronButton(
          text: 'CLOSE',
          width: 160,
          height: 44,
          color: NeonColors.magenta,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _creditItem(String label, String value, Color color) {
    return Row(
      children: [
        SizedBox(
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
