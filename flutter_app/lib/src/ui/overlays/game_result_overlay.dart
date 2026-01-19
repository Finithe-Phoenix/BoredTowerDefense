import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../data/story_data.dart';
import '../theme/neon_theme.dart';
import '../widgets/epic_neon_button.dart';
import '../widgets/glitch_text.dart';

/// Game result overlay showing victory or defeat with narrative context
class GameResultOverlay extends StatefulWidget {
  final bool isVictory;
  final int levelId;
  final int score;
  final int wavesCleared;
  final int towersBuilt;
  final int enemiesKilled;
  final VoidCallback onContinue;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  const GameResultOverlay({
    super.key,
    required this.isVictory,
    required this.levelId,
    required this.score,
    required this.wavesCleared,
    required this.towersBuilt,
    required this.enemiesKilled,
    required this.onContinue,
    required this.onRetry,
    required this.onExit,
  });

  @override
  State<GameResultOverlay> createState() => _GameResultOverlayState();
}

class _GameResultOverlayState extends State<GameResultOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _glitchController;
  late AnimationController _statsController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _statsAnimation;

  int _displayedScore = 0;
  bool _showingDialogue = true;
  int _dialogueIndex = 0;
  List<_ResultDialogue> _dialogues = [];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _statsAnimation = CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOutCubic,
    );

    _loadDialogues();
    _fadeController.forward();

    // Animate score counting
    _statsController.addListener(() {
      setState(() {
        _displayedScore = (widget.score * _statsAnimation.value).round();
      });
    });
  }

  void _loadDialogues() {
    _dialogues = widget.isVictory
        ? _getVictoryDialogues()
        : _getDefeatDialogues();
  }

  List<_ResultDialogue> _getVictoryDialogues() {
    final level = widget.levelId;

    // Boss victory dialogues
    if (level == 10) {
      return [
        _ResultDialogue(
          speaker: StoryData.aria,
          text: '¡Excelente trabajo, Arquitecto! El Guardián del Sector ha caído.',
          mood: BriefingMood.hopeful,
        ),
        _ResultDialogue(
          speaker: StoryData.aria,
          text: 'Los datos recuperados revelan anomalías en la siguiente zona.',
          mood: BriefingMood.analytical,
        ),
        _ResultDialogue(
          speaker: StoryData.aria,
          text: 'Rift Wars nos espera. Prepárate para lo desconocido.',
          mood: BriefingMood.serious,
        ),
      ];
    } else if (level == 20) {
      return [
        _ResultDialogue(
          speaker: StoryData.echo,
          text: 'Lo has logrado... donde yo fallé.',
          mood: BriefingMood.emotional,
        ),
        _ResultDialogue(
          speaker: StoryData.aria,
          text: 'Las grietas temporales se estabilizan. Buen trabajo.',
          mood: BriefingMood.hopeful,
        ),
      ];
    } else if (level == 50) {
      return [
        _ResultDialogue(
          speaker: StoryData.aria,
          text: 'La verdad ha sido revelada. El Decompiler era... nuestro.',
          mood: BriefingMood.revelation,
        ),
        _ResultDialogue(
          speaker: StoryData.echo,
          text: 'Ahora lo sabes. La única salida es el Núcleo.',
          mood: BriefingMood.serious,
        ),
      ];
    } else if (level == 100) {
      return [
        _ResultDialogue(
          speaker: StoryData.aria,
          text: '¡LO LOGRASTE! ¡El Decompiler ha sido destruido!',
          mood: BriefingMood.epic,
        ),
        _ResultDialogue(
          speaker: StoryData.echo,
          text: 'Gracias, Arquitecto. Finalmente... podemos descansar.',
          mood: BriefingMood.emotional,
        ),
        _ResultDialogue(
          speaker: StoryData.aria,
          text: 'El Grid está a salvo. Tú eres la leyenda que nos salvó.',
          mood: BriefingMood.hopeful,
        ),
        _ResultDialogue(
          speaker: StoryData.architect,
          text: 'Por el Grid. Por todos.',
          mood: BriefingMood.epic,
        ),
      ];
    }

    // Generic victory dialogues
    return [
      _ResultDialogue(
        speaker: StoryData.aria,
        text: 'Sector asegurado. La restauración avanza.',
        mood: BriefingMood.analytical,
      ),
      _ResultDialogue(
        speaker: StoryData.aria,
        text: 'Continúa, Arquitecto. El Grid cuenta contigo.',
        mood: BriefingMood.hopeful,
      ),
    ];
  }

  List<_ResultDialogue> _getDefeatDialogues() {
    final level = widget.levelId;

    // Boss defeat dialogues
    if (level >= 70) {
      return [
        _ResultDialogue(
          speaker: StoryData.decompiler,
          text: 'Patético. ¿Esto es todo lo que el Grid puede ofrecer?',
          mood: BriefingMood.dark,
        ),
        _ResultDialogue(
          speaker: StoryData.aria,
          text: '¡No! Arquitecto, debemos reagruparnos...',
          mood: BriefingMood.urgent,
        ),
        _ResultDialogue(
          speaker: StoryData.echo,
          text: 'No te rindas. Yo tampoco lo hice. Hasta el final.',
          mood: BriefingMood.hopeful,
        ),
      ];
    }

    // Generic defeat dialogues
    return [
      _ResultDialogue(
        speaker: StoryData.aria,
        text: 'Defensas comprometidas. Iniciando protocolo de recuperación.',
        mood: BriefingMood.worried,
      ),
      _ResultDialogue(
        speaker: StoryData.aria,
        text: 'Analiza tu estrategia. Aprende del fallo. Vuelve más fuerte.',
        mood: BriefingMood.analytical,
      ),
    ];
  }

  void _nextDialogue() {
    if (_dialogueIndex < _dialogues.length - 1) {
      setState(() {
        _dialogueIndex++;
      });
    } else {
      setState(() {
        _showingDialogue = false;
      });
      _statsController.forward();
      _triggerGlitch();
    }
  }

  void _triggerGlitch() {
    _glitchController.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _glitchController.forward(from: 0);
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _glitchController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isVictory ? NeonColors.green : NeonColors.red;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: Stack(
          children: [
            // Background effects
            _buildBackgroundEffects(accentColor),

            // Main content
            Center(
              child: Container(
                width: 500,
                constraints: const BoxConstraints(maxHeight: 600),
                child: _showingDialogue
                    ? _buildDialogueView(accentColor)
                    : _buildResultsView(accentColor),
              ),
            ),

            // Corner decorations
            _buildCornerDecorations(accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundEffects(Color accentColor) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                accentColor.withOpacity(0.1 * _pulseController.value),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogueView(Color accentColor) {
    if (_dialogues.isEmpty) {
      _showingDialogue = false;
      return _buildResultsView(accentColor);
    }

    final dialogue = _dialogues[_dialogueIndex];
    final speaker = dialogue.speaker;
    final moodColor = _getMoodColor(dialogue.mood);

    return GestureDetector(
      onTap: _nextDialogue,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Result header
          _buildResultHeader(accentColor),

          const SizedBox(height: 24),

          // Dialogue box
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: NeonColors.darkBg.withOpacity(0.9),
              border: Border.all(color: speaker.avatarColor.withOpacity(0.6), width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: speaker.avatarColor.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Speaker info
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: speaker.avatarColor.withOpacity(0.2),
                        border: Border.all(color: speaker.avatarColor, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          speaker.name[0],
                          style: NeonTextStyles.title.copyWith(
                            color: speaker.avatarColor,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            speaker.dialoguePrefix,
                            style: NeonTextStyles.small.copyWith(
                              color: speaker.avatarColor,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            speaker.title,
                            style: NeonTextStyles.small.copyWith(
                              color: speaker.avatarColor.withOpacity(0.6),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: speaker.avatarColor.withOpacity(0.2)),
                const SizedBox(height: 16),

                // Dialogue text
                Text(
                  dialogue.text,
                  style: NeonTextStyles.body.copyWith(
                    color: Colors.white.withOpacity(0.95),
                    height: 1.6,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_dialogues.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _dialogueIndex ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index <= _dialogueIndex
                      ? accentColor
                      : accentColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          Text(
            'Toca para continuar',
            style: NeonTextStyles.small.copyWith(
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(Color accentColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Result header
        _buildResultHeader(accentColor),

        const SizedBox(height: 24),

        // Stats card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: NeonColors.surfaceBg.withOpacity(0.9),
            border: Border.all(color: accentColor.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Score
              Text(
                _displayedScore.toString().padLeft(8, '0'),
                style: NeonTextStyles.title.copyWith(
                  color: accentColor,
                  fontSize: 48,
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: accentColor.withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              Text(
                'PUNTUACIÓN',
                style: NeonTextStyles.small.copyWith(
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 4,
                ),
              ),

              const SizedBox(height: 24),
              Divider(color: accentColor.withOpacity(0.2)),
              const SizedBox(height: 24),

              // Stats grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    icon: Icons.waves,
                    value: widget.wavesCleared.toString(),
                    label: 'OLEADAS',
                    color: NeonColors.cyan,
                  ),
                  _buildStatItem(
                    icon: Icons.cell_tower,
                    value: widget.towersBuilt.toString(),
                    label: 'TORRES',
                    color: NeonColors.green,
                  ),
                  _buildStatItem(
                    icon: Icons.dangerous,
                    value: widget.enemiesKilled.toString(),
                    label: 'ELIMINADOS',
                    color: NeonColors.red,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isVictory) ...[
              EpicNeonButton(
                text: 'CONTINUAR',
                icon: Icons.arrow_forward,
                color: NeonColors.green,
                width: 160,
                height: 48,
                onPressed: widget.onContinue,
              ),
              const SizedBox(width: 16),
            ],
            EpicNeonButton(
              text: 'REINTENTAR',
              icon: Icons.refresh,
              color: NeonColors.yellow,
              width: 160,
              height: 48,
              onPressed: widget.onRetry,
            ),
          ],
        ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: widget.onExit,
          child: Text(
            'VOLVER AL MENÚ',
            style: NeonTextStyles.small.copyWith(
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultHeader(Color accentColor) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glitchController,
          builder: (context, child) {
            final glitch = math.sin(_glitchController.value * math.pi * 10) * 2;
            return Transform.translate(
              offset: Offset(glitch, 0),
              child: GlitchText(
                text: widget.isVictory ? 'VICTORIA' : 'DERROTA',
                style: NeonTextStyles.title.copyWith(
                  fontSize: 52,
                  color: accentColor,
                  letterSpacing: 8,
                  shadows: [
                    Shadow(
                      color: accentColor.withOpacity(0.8),
                      blurRadius: 30,
                    ),
                  ],
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          widget.isVictory
              ? 'SECTOR ${widget.levelId} ASEGURADO'
              : 'SECTOR ${widget.levelId} PERDIDO',
          style: NeonTextStyles.body.copyWith(
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: NeonTextStyles.subtitle.copyWith(
            color: color,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          label,
          style: NeonTextStyles.small.copyWith(
            color: Colors.white.withOpacity(0.5),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildCornerDecorations(Color accentColor) {
    return Stack(
      children: [
        Positioned(
          top: 20,
          left: 20,
          child: _CornerDecoration(color: accentColor),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Transform.scale(
            scaleX: -1,
            child: _CornerDecoration(color: accentColor),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: Transform.scale(
            scaleY: -1,
            child: _CornerDecoration(color: accentColor),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: Transform.scale(
            scaleX: -1,
            scaleY: -1,
            child: _CornerDecoration(color: accentColor),
          ),
        ),
      ],
    );
  }

  Color _getMoodColor(BriefingMood mood) {
    switch (mood) {
      case BriefingMood.urgent:
        return NeonColors.red;
      case BriefingMood.analytical:
        return NeonColors.cyan;
      case BriefingMood.worried:
        return NeonColors.yellow;
      case BriefingMood.serious:
        return NeonColors.green;
      case BriefingMood.mysterious:
        return NeonColors.magenta;
      case BriefingMood.hopeful:
        return NeonColors.green;
      case BriefingMood.surprised:
        return NeonColors.yellow;
      case BriefingMood.emotional:
        return NeonColors.cyan;
      case BriefingMood.epic:
        return NeonColors.white;
      case BriefingMood.dark:
        return NeonColors.magenta;
      case BriefingMood.sad:
        return NeonColors.cyan;
      case BriefingMood.confused:
        return NeonColors.yellow;
      case BriefingMood.revelation:
        return NeonColors.white;
    }
  }
}

class _ResultDialogue {
  final Character speaker;
  final String text;
  final BriefingMood mood;

  const _ResultDialogue({
    required this.speaker,
    required this.text,
    required this.mood,
  });
}

class _CornerDecoration extends StatelessWidget {
  final Color color;

  const _CornerDecoration({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(
        painter: _CornerPainter(color: color),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;

  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.7, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
