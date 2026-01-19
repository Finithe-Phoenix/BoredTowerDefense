import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/story_data.dart';
import '../theme/neon_theme.dart';
import '../widgets/glitch_text.dart';
import '../widgets/epic_neon_button.dart';

/// Enhanced briefing overlay with multi-character dialogues and cinematic animations
class BriefingOverlay extends StatefulWidget {
  final int levelId;
  final VoidCallback onDismiss;

  const BriefingOverlay({
    super.key,
    required this.levelId,
    required this.onDismiss,
  });

  @override
  State<BriefingOverlay> createState() => _BriefingOverlayState();
}

class _BriefingOverlayState extends State<BriefingOverlay> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _isVisible = true;
  int _currentLineIndex = 0;
  bool _showingPreDialogue = true;
  bool _isTyping = false;
  String _displayedText = '';
  Timer? _typewriterTimer;

  LevelBriefing? _briefing;
  List<_DisplayLine> _allLines = [];

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    // Pulse animation for active elements
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Scan line animation
    _scanController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _fadeController.forward();
    _loadBriefing();
  }

  void _loadBriefing() {
    _briefing = StoryData.getBriefingForLevel(widget.levelId);

    if (_briefing != null) {
      // Build all lines: pre-dialogue first, then main lines
      _allLines = [];

      // Add pre-dialogue lines
      for (final line in _briefing!.preDialogue) {
        _allLines.add(_DisplayLine(
          speaker: line.speaker,
          text: line.text,
          mood: line.mood,
          isPreDialogue: true,
        ));
      }

      // Add main briefing lines
      for (final text in _briefing!.lines) {
        _allLines.add(_DisplayLine(
          speaker: _briefing!.speaker,
          text: text,
          mood: _briefing!.mood,
          isPreDialogue: false,
        ));
      }

      _showingPreDialogue = _briefing!.preDialogue.isNotEmpty;
    } else {
      // Fallback briefing
      _allLines = [
        _DisplayLine(
          speaker: StoryData.aria,
          text: _getFallbackText(),
          mood: BriefingMood.analytical,
          isPreDialogue: false,
        ),
      ];
      _showingPreDialogue = false;
    }

    // Start typewriter effect
    _startTypewriter();
  }

  String _getFallbackText() {
    if (widget.levelId <= 10) {
      return 'BRECHA DETECTADA EN EL SECTOR ${widget.levelId}. DESPLIEGA DEFENSAS INMEDIATAMENTE.';
    } else if (widget.levelId <= 20) {
      return 'ANOMALÍAS DETECTADAS. ADAPTA TUS ESTRATEGIAS. EL ENEMIGO ESTÁ EVOLUCIONANDO.';
    } else if (widget.levelId <= 30) {
      return 'ZONA DE BAJA SEÑAL. TUS TORRES SERÁN TUS OJOS. PROCEDE CON CAUTELA.';
    } else if (widget.levelId <= 40) {
      return 'TORMENTAS IÓNICAS ACTIVAS. PREPÁRATE PARA RESISTENCIA MÁXIMA.';
    } else {
      return 'ESTADO DEL SISTEMA: CRÍTICO. LA RESTAURACIÓN DEBE CONTINUAR.';
    }
  }

  void _startTypewriter() {
    if (_currentLineIndex >= _allLines.length) return;

    setState(() {
      _isTyping = true;
      _displayedText = '';
    });

    final currentLine = _allLines[_currentLineIndex];
    final fullText = currentLine.text;
    int charIndex = 0;

    _typewriterTimer?.cancel();
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (charIndex < fullText.length) {
        setState(() {
          _displayedText = fullText.substring(0, charIndex + 1);
        });
        charIndex++;
      } else {
        timer.cancel();
        setState(() {
          _isTyping = false;
        });
      }
    });
  }

  void _skipTypewriter() {
    if (_isTyping && _currentLineIndex < _allLines.length) {
      _typewriterTimer?.cancel();
      setState(() {
        _displayedText = _allLines[_currentLineIndex].text;
        _isTyping = false;
      });
    }
  }

  void _nextLine() {
    if (_isTyping) {
      _skipTypewriter();
      return;
    }

    if (_currentLineIndex < _allLines.length - 1) {
      setState(() {
        _currentLineIndex++;
      });
      _startTypewriter();
    } else {
      _dismiss();
    }
  }

  void _dismiss() {
    _fadeController.reverse().then((_) {
      setState(() => _isVisible = false);
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();
    if (_allLines.isEmpty) return const SizedBox.shrink();

    final currentLine = _allLines[_currentLineIndex];
    final speaker = currentLine.speaker;
    final mood = currentLine.mood;
    final moodColor = _getMoodColor(mood);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _nextLine,
        child: Container(
          color: Colors.black.withOpacity(0.9),
          child: Stack(
            children: [
              // Animated scan line background
              _buildScanLineBackground(),

              // Main content
              Center(
                child: Container(
                  width: 550,
                  constraints: const BoxConstraints(maxHeight: 500),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mission header
                      _buildMissionHeader(moodColor),

                      const SizedBox(height: 16),

                      // Main dialogue box
                      _buildDialogueBox(speaker, moodColor),

                      const SizedBox(height: 16),

                      // Progress and controls
                      _buildProgressAndControls(moodColor),
                    ],
                  ),
                ),
              ),

              // Corner decorations
              _buildCornerDecorations(moodColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanLineBackground() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScanLinePainter(
            progress: _scanController.value,
            color: NeonColors.cyan.withOpacity(0.05),
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildMissionHeader(Color accentColor) {
    final title = _briefing?.title ?? 'BRIEFING DE MISIÓN';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(color: accentColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(_pulseAnimation.value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Icon(Icons.warning_amber_rounded, color: accentColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NIVEL ${widget.levelId}',
                  style: NeonTextStyles.small.copyWith(
                    color: accentColor.withOpacity(0.7),
                    letterSpacing: 2,
                  ),
                ),
                GlitchText(
                  text: title,
                  style: NeonTextStyles.subtitle.copyWith(
                    color: accentColor,
                    letterSpacing: 3,
                  ),
                  duration: const Duration(seconds: 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogueBox(Character speaker, Color moodColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NeonColors.darkBg.withOpacity(0.95),
        border: Border.all(color: speaker.avatarColor.withOpacity(0.6), width: 2),
        borderRadius: BorderRadius.circular(4),
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
              // Avatar
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
              // Mood indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: moodColor.withOpacity(0.1),
                  border: Border.all(color: moodColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getMoodLabel(_allLines[_currentLineIndex].mood),
                  style: NeonTextStyles.small.copyWith(
                    color: moodColor,
                    fontSize: 8,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),

          // Dialogue text
          Container(
            constraints: const BoxConstraints(minHeight: 80),
            child: Text(
              _displayedText,
              style: NeonTextStyles.body.copyWith(
                color: NeonColors.white.withOpacity(0.95),
                height: 1.6,
                fontSize: 16,
              ),
            ),
          ),

          // Typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  _buildTypingDot(0),
                  _buildTypingDot(1),
                  _buildTypingDot(2),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final offset = index * 0.3;
        final value = math.sin((_pulseController.value + offset) * math.pi * 2);
        return Container(
          margin: const EdgeInsets.only(right: 4),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: NeonColors.cyan.withOpacity(0.5 + value * 0.5),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildProgressAndControls(Color accentColor) {
    final progress = (_currentLineIndex + 1) / _allLines.length;

    return Column(
      children: [
        // Progress bar
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor.withOpacity(0.5), accentColor],
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 6),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_currentLineIndex + 1} / ${_allLines.length}',
              style: NeonTextStyles.small.copyWith(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            Row(
              children: [
                if (_currentLineIndex < _allLines.length - 1)
                  TextButton(
                    onPressed: _dismiss,
                    child: Text(
                      'SALTAR',
                      style: NeonTextStyles.small.copyWith(
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                EpicNeonButton(
                  text: _currentLineIndex < _allLines.length - 1
                      ? 'CONTINUAR'
                      : 'EJECUTAR',
                  color: accentColor,
                  width: 140,
                  height: 42,
                  onPressed: _nextLine,
                ),
              ],
            ),
          ],
        ),

        // Tap hint
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            'Toca en cualquier lugar para continuar',
            style: NeonTextStyles.small.copyWith(
              color: Colors.white.withOpacity(0.3),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerDecorations(Color accentColor) {
    return Stack(
      children: [
        // Top left corner
        Positioned(
          top: 20,
          left: 20,
          child: _CornerDecoration(color: accentColor, rotation: 0),
        ),
        // Top right corner
        Positioned(
          top: 20,
          right: 20,
          child: _CornerDecoration(color: accentColor, rotation: math.pi / 2),
        ),
        // Bottom left corner
        Positioned(
          bottom: 20,
          left: 20,
          child: _CornerDecoration(color: accentColor, rotation: -math.pi / 2),
        ),
        // Bottom right corner
        Positioned(
          bottom: 20,
          right: 20,
          child: _CornerDecoration(color: accentColor, rotation: math.pi),
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

  String _getMoodLabel(BriefingMood mood) {
    switch (mood) {
      case BriefingMood.urgent:
        return 'URGENTE';
      case BriefingMood.analytical:
        return 'ANÁLISIS';
      case BriefingMood.worried:
        return 'ALERTA';
      case BriefingMood.serious:
        return 'SERIO';
      case BriefingMood.mysterious:
        return 'MISTERIO';
      case BriefingMood.hopeful:
        return 'ESPERANZA';
      case BriefingMood.surprised:
        return 'SORPRESA';
      case BriefingMood.emotional:
        return 'EMOTIVO';
      case BriefingMood.epic:
        return 'ÉPICO';
      case BriefingMood.dark:
        return 'OSCURO';
      case BriefingMood.sad:
        return 'MELANCOLÍA';
      case BriefingMood.confused:
        return 'CONFUSIÓN';
      case BriefingMood.revelation:
        return 'REVELACIÓN';
    }
  }
}

/// Internal class to represent a line of dialogue
class _DisplayLine {
  final Character speaker;
  final String text;
  final BriefingMood mood;
  final bool isPreDialogue;

  const _DisplayLine({
    required this.speaker,
    required this.text,
    required this.mood,
    required this.isPreDialogue,
  });
}

/// Corner decoration widget
class _CornerDecoration extends StatelessWidget {
  final Color color;
  final double rotation;

  const _CornerDecoration({required this.color, required this.rotation});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: SizedBox(
        width: 30,
        height: 30,
        child: CustomPaint(
          painter: _CornerPainter(color: color),
        ),
      ),
    );
  }
}

/// Corner painter
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

/// Scan line background painter
class _ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          color,
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 100));

    final y = progress * size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, y - 50, size.width, 100),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
