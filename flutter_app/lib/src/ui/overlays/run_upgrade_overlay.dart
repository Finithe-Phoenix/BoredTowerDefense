import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../game/bored_games_game.dart';
import '../../models/upgrade_data.dart';
import '../theme/neon_theme.dart';
import '../widgets/epic_neon_button.dart';

class RunUpgradeOverlay extends StatefulWidget {
  const RunUpgradeOverlay({super.key, required this.game});

  final BoredGamesGame game;

  @override
  State<RunUpgradeOverlay> createState() => _RunUpgradeOverlayState();
}

class _RunUpgradeOverlayState extends State<RunUpgradeOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late AnimationController _emergencyController;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _emergencyController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final choices = widget.game.pendingRunUpgrades;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Emergency background with pulsing grid
          AnimatedBuilder(
            animation: _emergencyController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      const Color(0xFF1a1a05).withOpacity(0.95),
                      const Color(0xFF0a0a02).withOpacity(0.98),
                      Colors.black.withOpacity(0.99),
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: _EmergencyGridPainter(
                    animation: _emergencyController.value,
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),

          // Warning scanlines
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return CustomPaint(
                painter: _WarningScanlinesPainter(
                  animation: _pulseController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Corner emergency indicators
          ..._buildEmergencyCorners(),

          // Main content
          FadeTransition(
            opacity: _entranceController,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 720;
                  return Column(
                    children: [
                      const SizedBox(height: 20),

                      // Emergency header
                      _buildEmergencyHeader(),

                      const SizedBox(height: 20),
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            width: isWide ? 760 : double.infinity,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 16,
                              runSpacing: 16,
                              children: choices.asMap().entries.map((entry) {
                                final index = entry.key;
                                final upgrade = entry.value;
                                return _EpicUpgradeCard(
                                  upgrade: upgrade,
                                  onSelect: () => widget.game.selectRunUpgrade(upgrade.id),
                                  delay: index * 100,
                                  entranceController: _entranceController,
                                  pulseController: _pulseController,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            EpicNeonButton(
                              text: 'CLOSE',
                              width: 160,
                              height: 40,
                              color: NeonColors.cyan,
                              onPressed: widget.game.closeRunUpgradeOverlay,
                            ),
                            EpicNeonButton(
                              text: 'SKIP',
                              width: 160,
                              height: 40,
                              color: NeonColors.magenta,
                              onPressed: widget.game.skipRunUpgrade,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyHeader() {
    return AnimatedBuilder(
      animation: _emergencyController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            border: Border.all(
              color: NeonColors.yellow.withOpacity(0.5 + _emergencyController.value * 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: NeonColors.yellow.withOpacity(0.2 + _emergencyController.value * 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt,
                    color: NeonColors.yellow.withOpacity(0.7 + _emergencyController.value * 0.3),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'EMERGENCY POWER-UP AVAILABLE',
                    style: NeonTextStyles.title.copyWith(
                      fontSize: 24,
                      color: NeonColors.yellow,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(color: NeonColors.yellow, blurRadius: 10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.bolt,
                    color: NeonColors.yellow.withOpacity(0.7 + _emergencyController.value * 0.3),
                    size: 28,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '>>> SELECT YOUR ENHANCEMENT IMMEDIATELY <<<',
                style: NeonTextStyles.small.copyWith(
                  color: NeonColors.orange.withOpacity(0.8),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildEmergencyCorners() {
    return [
      Positioned(
        top: 20,
        left: 20,
        child: _EmergencyCorner(
          pulseController: _emergencyController,
          message: 'POWER-UP READY',
        ),
      ),
      Positioned(
        top: 20,
        right: 20,
        child: _EmergencyCorner(
          pulseController: _emergencyController,
          message: 'BOOST AVAILABLE',
        ),
      ),
      Positioned(
        bottom: 20,
        left: 20,
        child: _EmergencyCorner(
          pulseController: _emergencyController,
          message: 'ENHANCEMENT ACTIVE',
        ),
      ),
      Positioned(
        bottom: 20,
        right: 20,
        child: _EmergencyCorner(
          pulseController: _emergencyController,
          message: 'UPGRADE STANDBY',
        ),
      ),
    ];
  }
}

class _EpicUpgradeCard extends StatefulWidget {
  const _EpicUpgradeCard({
    required this.upgrade,
    required this.onSelect,
    required this.delay,
    required this.entranceController,
    required this.pulseController,
  });

  final RunUpgradeDefinition upgrade;
  final VoidCallback onSelect;
  final int delay;
  final AnimationController entranceController;
  final AnimationController pulseController;

  @override
  State<_EpicUpgradeCard> createState() => _EpicUpgradeCardState();
}

class _EpicUpgradeCardState extends State<_EpicUpgradeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.entranceController,
      builder: (context, child) {
        final delayedProgress = ((widget.entranceController.value - widget.delay / 1000) * 1.5).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, 50 * (1 - delayedProgress)),
          child: Opacity(
            opacity: delayedProgress,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                onTap: widget.onSelect,
                child: AnimatedBuilder(
                  animation: widget.pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 240,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: NeonColors.darkBg.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (_isHovered ? NeonColors.yellow : NeonColors.cyan)
                              .withOpacity(0.5 + widget.pulseController.value * 0.3),
                          width: _isHovered ? 2 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isHovered ? NeonColors.yellow : NeonColors.cyan)
                                .withOpacity(0.2 + widget.pulseController.value * 0.2),
                            blurRadius: _isHovered ? 25 : 18,
                            spreadRadius: _isHovered ? 3 : 1,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Particle effect background
                          if (_isHovered)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _UpgradeParticlesPainter(
                                  animation: widget.pulseController.value,
                                ),
                              ),
                            ),

                          // Content
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Power indicator
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: NeonColors.yellow,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: NeonColors.yellow,
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'POWER-UP',
                                    style: NeonTextStyles.small.copyWith(
                                      color: NeonColors.yellow,
                                      fontSize: 10,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Upgrade name
                              Text(
                                widget.upgrade.name.toUpperCase(),
                                style: NeonTextStyles.subtitle.copyWith(
                                  fontSize: 17,
                                  color: NeonColors.white,
                                  shadows: _isHovered
                                      ? [Shadow(color: NeonColors.yellow, blurRadius: 10)]
                                      : [],
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Description
                              Text(
                                widget.upgrade.description,
                                style: NeonTextStyles.small.copyWith(
                                  color: NeonColors.white.withOpacity(0.7),
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Lock in button
                              Center(
                                child: EpicNeonButton(
                                  text: 'ACTIVATE',
                                  height: 38,
                                  width: 180,
                                  color: NeonColors.green,
                                  onPressed: widget.onSelect,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Emergency corner widget
class _EmergencyCorner extends StatelessWidget {
  final AnimationController pulseController;
  final String message;

  const _EmergencyCorner({
    required this.pulseController,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            border: Border.all(
              color: NeonColors.yellow.withOpacity(0.6 + pulseController.value * 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: NeonColors.yellow.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning,
                size: 14,
                color: NeonColors.yellow.withOpacity(0.8 + pulseController.value * 0.2),
              ),
              const SizedBox(width: 6),
              Text(
                message,
                style: TextStyle(
                  color: NeonColors.yellow,
                  fontSize: 9,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(color: NeonColors.yellow, blurRadius: 4),
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
class _EmergencyGridPainter extends CustomPainter {
  final double animation;

  _EmergencyGridPainter({required this.animation});

  static final Paint _linePaint = Paint()..strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    const spacing = 45.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      final opacity = 0.02 + (math.sin(x * 0.01 + animation * math.pi * 2) * 0.02);
      _linePaint.color = NeonColors.yellow.withOpacity(opacity.clamp(0.01, 0.06));
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _linePaint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      final opacity = 0.02 + (math.sin(y * 0.01 + animation * math.pi * 2) * 0.02);
      _linePaint.color = NeonColors.yellow.withOpacity(opacity.clamp(0.01, 0.06));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmergencyGridPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _WarningScanlinesPainter extends CustomPainter {
  final double animation;

  _WarningScanlinesPainter({required this.animation});

  static final Paint _scanPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final scanY = (animation * size.height * 2) % size.height;
    _scanPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        NeonColors.yellow.withOpacity(0),
        NeonColors.yellow.withOpacity(0.05),
        NeonColors.yellow.withOpacity(0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, 50));

    canvas.save();
    canvas.translate(0, scanY - 25);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 50), _scanPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WarningScanlinesPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _UpgradeParticlesPainter extends CustomPainter {
  final double animation;

  _UpgradeParticlesPainter({required this.animation});

  static final Paint _particlePaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    int rngState = (animation * 1000).toInt() ^ 0x12345;
    int lcgNext() {
      rngState = (1664525 * rngState + 1013904223) & 0x7fffffff;
      return rngState;
    }
    double nextUnit() => lcgNext() / 0x7fffffff;

    // Floating particles
    for (int i = 0; i < 15; i++) {
      final x = nextUnit() * size.width;
      final baseY = nextUnit() * size.height;
      final y = (baseY + animation * 50) % size.height;

      final particleSize = 1 + nextUnit() * 2;
      final opacity = 0.2 + nextUnit() * 0.4;

      _particlePaint.color = NeonColors.yellow.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), particleSize, _particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _UpgradeParticlesPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
