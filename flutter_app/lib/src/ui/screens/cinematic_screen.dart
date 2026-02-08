import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/story_data.dart';
import '../theme/neon_theme.dart';
import '../widgets/glitch_text.dart';

/// Epic cinematic screen for story moments between worlds
class CinematicScreen extends StatefulWidget {
  final CinematicData cinematic;
  final VoidCallback onComplete;

  const CinematicScreen({
    super.key,
    required this.cinematic,
    required this.onComplete,
  });

  @override
  State<CinematicScreen> createState() => _CinematicScreenState();
}

class _CinematicScreenState extends State<CinematicScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _glitchController;
  late AnimationController _parallaxController;

  int _currentSceneIndex = 0;
  int _currentLineIndex = 0;
  String _displayedText = '';
  bool _isTyping = false;
  bool _showSkipHint = false;
  Timer? _typewriterTimer;
  Timer? _skipHintTimer;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _parallaxController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _fadeController.forward();
    _startScene();

    // Show skip hint after 3 seconds
    _skipHintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSkipHint = true);
    });
  }

  CinematicScene get _currentScene => widget.cinematic.scenes[_currentSceneIndex];

  void _startScene() {
    _currentLineIndex = 0;
    _startTypewriter();
  }

  void _startTypewriter() {
    if (_currentLineIndex >= _currentScene.lines.length) {
      _advanceScene();
      return;
    }

    setState(() {
      _isTyping = true;
      _displayedText = '';
    });

    final line = _currentScene.lines[_currentLineIndex];
    final fullText = line.text;
    int charIndex = 0;

    // Speed varies by mood
    final speed = line.mood == BriefingMood.epic
        ? const Duration(milliseconds: 50)
        : const Duration(milliseconds: 35);

    _typewriterTimer?.cancel();
    _typewriterTimer = Timer.periodic(speed, (timer) {
      if (charIndex < fullText.length) {
        setState(() {
          _displayedText = fullText.substring(0, charIndex + 1);
        });
        charIndex++;

        // Haptic feedback on punctuation for dramatic effect
        if (fullText[charIndex - 1] == '.' ||
            fullText[charIndex - 1] == '!' ||
            fullText[charIndex - 1] == '?') {
          HapticFeedback.lightImpact();
        }
      } else {
        timer.cancel();
        setState(() => _isTyping = false);
      }
    });
  }

  void _skipTypewriter() {
    if (_isTyping) {
      _typewriterTimer?.cancel();
      setState(() {
        _displayedText = _currentScene.lines[_currentLineIndex].text;
        _isTyping = false;
      });
    }
  }

  void _advanceLine() {
    if (_isTyping) {
      _skipTypewriter();
      return;
    }

    if (_currentLineIndex < _currentScene.lines.length - 1) {
      setState(() => _currentLineIndex++);
      _startTypewriter();
    } else {
      _advanceScene();
    }
  }

  void _advanceScene() {
    if (_currentSceneIndex < widget.cinematic.scenes.length - 1) {
      // Transition effect
      _triggerGlitch();
      _fadeController.reverse().then((_) {
        setState(() {
          _currentSceneIndex++;
          _currentLineIndex = 0;
        });
        _fadeController.forward();
        _startTypewriter();
      });
    } else {
      _complete();
    }
  }

  void _triggerGlitch() {
    _glitchController.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _complete() {
    _fadeController.reverse().then((_) {
      widget.onComplete();
    });
  }

  void _skipAll() {
    HapticFeedback.heavyImpact();
    _complete();
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _skipHintTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    _glitchController.dispose();
    _parallaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = _currentScene;
    final currentLine = scene.lines.isNotEmpty && _currentLineIndex < scene.lines.length
        ? scene.lines[_currentLineIndex]
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _advanceLine,
        onLongPress: _skipAll,
        child: FadeTransition(
          opacity: _fadeController,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Animated background
              _buildAnimatedBackground(scene),

              // Vignette overlay
              _buildVignette(),

              // Scan lines
              _buildScanLines(),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Scene title
                    _buildSceneTitle(scene),

                    const Spacer(),

                    // Visual element (if any)
                    if (scene.visualType != null)
                      _buildVisualElement(scene),

                    const Spacer(),

                    // Dialogue box
                    if (currentLine != null)
                      _buildDialogueBox(currentLine),

                    const SizedBox(height: 20),

                    // Progress indicators
                    _buildProgress(),

                    const SizedBox(height: 10),

                    // Skip hint
                    if (_showSkipHint)
                      _buildSkipHint(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Glitch overlay
              _buildGlitchOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(CinematicScene scene) {
    return AnimatedBuilder(
      animation: _parallaxController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                math.sin(_parallaxController.value * math.pi * 2) * 0.3,
                math.cos(_parallaxController.value * math.pi * 2) * 0.3,
              ),
              radius: 1.5,
              colors: [
                scene.backgroundColor.withOpacity(0.3),
                Colors.black,
              ],
            ),
          ),
          child: CustomPaint(
            painter: _StarfieldPainter(
              time: _parallaxController.value,
              color: scene.accentColor,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildVignette() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
            stops: const [0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildScanLines() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Opacity(
            opacity: 0.03 + _pulseController.value * 0.02,
            child: CustomPaint(
              painter: _ScanLinesPainter(),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSceneTitle(CinematicScene scene) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Chapter indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: scene.accentColor.withOpacity(0.5)),
            ),
            child: Text(
              'CAPÍTULO ${widget.cinematic.chapter}',
              style: NeonTextStyles.small.copyWith(
                color: scene.accentColor,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GlitchText(
              text: scene.title,
              style: NeonTextStyles.subtitle.copyWith(
                color: scene.accentColor,
                letterSpacing: 4,
                shadows: [
                  Shadow(
                    color: scene.accentColor.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualElement(CinematicScene scene) {
    switch (scene.visualType) {
      case CinematicVisual.characterReveal:
        return _buildCharacterReveal(scene);
      case CinematicVisual.locationPan:
        return _buildLocationPan(scene);
      case CinematicVisual.dataStream:
        return _buildDataStream(scene);
      case CinematicVisual.corruption:
        return _buildCorruption(scene);
      case CinematicVisual.memory:
        return _buildMemoryFragment(scene);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCharacterReveal(CinematicScene scene) {
    final character = scene.focusCharacter;
    if (character == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: character.avatarColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: character.avatarColor.withOpacity(0.3 + _pulseController.value * 0.2),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  character.name[0],
                  style: NeonTextStyles.title.copyWith(
                    fontSize: 72,
                    color: character.avatarColor,
                  ),
                ),
                Text(
                  character.name,
                  style: NeonTextStyles.small.copyWith(
                    color: character.avatarColor,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationPan(CinematicScene scene) {
    return AnimatedBuilder(
      animation: _parallaxController,
      builder: (context, child) {
        return Container(
          height: 150,
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            border: Border.all(color: scene.accentColor.withOpacity(0.3)),
          ),
          child: ClipRect(
            child: CustomPaint(
              painter: _GridWorldPainter(
                offset: _parallaxController.value,
                color: scene.accentColor,
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataStream(CinematicScene scene) {
    return SizedBox(
      height: 100,
      child: AnimatedBuilder(
        animation: _parallaxController,
        builder: (context, child) {
          return CustomPaint(
            painter: _DataStreamPainter(
              time: _parallaxController.value,
              color: scene.accentColor,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildCorruption(CinematicScene scene) {
    return AnimatedBuilder(
      animation: _glitchController,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: _CorruptionPainter(
              time: _parallaxController.value,
              glitchIntensity: _glitchController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildMemoryFragment(CinematicScene scene) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final opacity = 0.5 + _pulseController.value * 0.5;
        return Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: NeonColors.yellow.withOpacity(0.1),
            border: Border.all(
              color: NeonColors.yellow.withOpacity(opacity),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.memory,
                color: NeonColors.yellow.withOpacity(opacity),
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'FRAGMENTO DE MEMORIA',
                style: NeonTextStyles.small.copyWith(
                  color: NeonColors.yellow.withOpacity(opacity),
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogueBox(CinematicLine line) {
    final speaker = line.speaker;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(
          color: speaker?.avatarColor ?? _currentScene.accentColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (speaker?.avatarColor ?? _currentScene.accentColor).withOpacity(0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speaker info
          if (speaker != null)
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: speaker.avatarColor.withOpacity(0.2),
                    border: Border.all(color: speaker.avatarColor),
                  ),
                  child: Center(
                    child: Text(
                      speaker.name[0],
                      style: NeonTextStyles.title.copyWith(
                        color: speaker.avatarColor,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      speaker.dialoguePrefix,
                      style: NeonTextStyles.small.copyWith(
                        color: speaker.avatarColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      speaker.title,
                      style: NeonTextStyles.small.copyWith(
                        color: speaker.avatarColor.withOpacity(0.6),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  Icons.format_quote,
                  color: _currentScene.accentColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'NARRACIÓN',
                  style: NeonTextStyles.small.copyWith(
                    color: _currentScene.accentColor,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Dialogue text
          Text(
            _displayedText,
            style: NeonTextStyles.body.copyWith(
              color: Colors.white.withOpacity(0.95),
              height: 1.8,
              fontSize: 18,
            ),
          ),

          // Typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildTypingIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = math.sin((_pulseController.value + delay) * math.pi * 2);
            return Container(
              margin: const EdgeInsets.only(right: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentScene.accentColor.withOpacity(0.5 + value * 0.5),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildProgress() {
    final totalScenes = widget.cinematic.scenes.length;
    final totalLines = _currentScene.lines.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Scene progress
        ...List.generate(totalScenes, (index) {
          final isActive = index == _currentSceneIndex;
          final isPast = index < _currentSceneIndex;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 30 : 12,
            height: 4,
            decoration: BoxDecoration(
              color: isPast
                  ? _currentScene.accentColor
                  : isActive
                      ? _currentScene.accentColor.withOpacity(0.8)
                      : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),

        const SizedBox(width: 16),

        // Line progress within scene
        Text(
          '${_currentLineIndex + 1}/$totalLines',
          style: NeonTextStyles.small.copyWith(
            color: Colors.white.withOpacity(0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildSkipHint() {
    return AnimatedOpacity(
      opacity: _showSkipHint ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Text(
        'Toca para avanzar • Mantén presionado para saltar',
        style: NeonTextStyles.small.copyWith(
          color: Colors.white.withOpacity(0.3),
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildGlitchOverlay() {
    return AnimatedBuilder(
      animation: _glitchController,
      builder: (context, child) {
        if (_glitchController.value == 0) return const SizedBox.shrink();

        return IgnorePointer(
          child: Container(
            color: _currentScene.accentColor.withOpacity(_glitchController.value * 0.3),
          ),
        );
      },
    );
  }
}

// Custom Painters

class _StarfieldPainter extends CustomPainter {
  final double time;
  final Color color;

  _StarfieldPainter({required this.time, required this.color});

  static final Paint _starPaint = Paint();
  static int _lcgNext(int state) => (state * 1664525 + 1013904223) & 0x7fffffff;
  static double _lcgUnit(int state) => state / 0x7fffffff;

  @override
  void paint(Canvas canvas, Size size) {
    var state = 42;

    for (int i = 0; i < 100; i++) {
      state = _lcgNext(state);
      final x = _lcgUnit(state) * size.width;
      state = _lcgNext(state);
      final y =
          (_lcgUnit(state) * size.height + time * 50 * (i % 3 + 1)) % size.height;
      state = _lcgNext(state);
      final radius = _lcgUnit(state) * 1.5 + 0.5;
      state = _lcgNext(state);
      final alpha = _lcgUnit(state) * 0.5 + 0.2;

      _starPaint.color = color.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), radius, _starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

class _ScanLinesPainter extends CustomPainter {
  static final Paint _scanPaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _scanPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridWorldPainter extends CustomPainter {
  final double offset;
  final Color color;

  _GridWorldPainter({required this.offset, required this.color});

  static final Paint _gridPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    _gridPaint.color = color.withOpacity(0.3);

    // Horizon line
    final horizonY = size.height * 0.4;
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(size.width, horizonY),
      _gridPaint..color = color,
    );

    // Grid lines
    for (int i = 0; i < 20; i++) {
      final progress = (i / 20 + offset) % 1.0;
      final y = horizonY + (size.height - horizonY) * progress;
      final alpha = progress * 0.5;

      _gridPaint.color = color.withOpacity(alpha);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridPaint);
    }

    // Vertical lines (perspective)
    for (int i = -5; i <= 5; i++) {
      final x = size.width / 2 + i * 40;
      _gridPaint.color = color.withOpacity(0.2);
      canvas.drawLine(
        Offset(size.width / 2, horizonY),
        Offset(x + (i * 100), size.height),
        _gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridWorldPainter oldDelegate) {
    return oldDelegate.offset != offset;
  }
}

class _DataStreamPainter extends CustomPainter {
  final double time;
  final Color color;

  _DataStreamPainter({required this.time, required this.color});

  static final TextPainter _textPainter = TextPainter(textDirection: TextDirection.ltr);
  static const int _charPainterCacheLimit = 64;
  static final Map<int, TextPainter> _charPainterCache = {};
  static int _lcgNext(int state) => (state * 1664525 + 1013904223) & 0x7fffffff;
  static double _lcgUnit(int state) => state / 0x7fffffff;

  @override
  void paint(Canvas canvas, Size size) {
    var state = 123;
    var cacheExceeded = false;

    for (int col = 0; col < 40; col++) {
      final x = col * (size.width / 40);
      state = _lcgNext(state);
      final speed = _lcgUnit(state) * 0.5 + 0.5;
      final offset = (time * speed * 100) % size.height;

      for (int row = 0; row < 8; row++) {
        final y = (row * 15 + offset) % size.height;
        state = _lcgNext(state);
        final char = (state & 0x1) == 0 ? '1' : '0';
        final alpha = (1 - y / size.height) * 0.8;

        if (alpha > 0.05) {
          final alphaKey = (alpha * 32).round().clamp(0, 32);
          final rgb = color.value & 0x00FFFFFF;
          final charCode = char.codeUnitAt(0) & 0xFF;
          final cacheKey = (alphaKey << 32) | (charCode << 24) | rgb;
          final painter = _charPainterCache.putIfAbsent(cacheKey, () {
            final tp = TextPainter(textDirection: TextDirection.ltr);
            tp.text = TextSpan(
              text: char,
              style: TextStyle(
                color: color.withOpacity(alphaKey / 32),
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            );
            tp.layout();
            return tp;
          });
          painter.paint(canvas, Offset(x, y));
          if (_charPainterCache.length > _charPainterCacheLimit) {
            cacheExceeded = true;
          }
        }
      }
    }
    if (cacheExceeded) {
      for (final tp in _charPainterCache.values) {
        tp.dispose();
      }
      _charPainterCache.clear();
    }
  }

  @override
  bool shouldRepaint(covariant _DataStreamPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

class _CorruptionPainter extends CustomPainter {
  final double time;
  final double glitchIntensity;

  _CorruptionPainter({required this.time, required this.glitchIntensity});

  static final Paint _tendrilPaint = Paint()
    ..color = NeonColors.magenta.withOpacity(0.6)
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  static final Paint _coreGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _corePaint = Paint();
  final Path _tendrilPath = Path();
  static int _lcgNext(int state) => (state * 1664525 + 1013904223) & 0x7fffffff;
  static double _lcgUnit(int state) => state / 0x7fffffff;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    var state = (time * 1000).toInt();

    // Corruption tendrils
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2 + time * math.pi;
      state = _lcgNext(state);
      final length = 30 + _lcgUnit(state) * 50 + glitchIntensity * 20;

      _tendrilPath
        ..reset()
        ..moveTo(center.dx, center.dy);

      for (int j = 0; j < 5; j++) {
        final dist = (j / 5) * length;
        state = _lcgNext(state);
        final wobble = _lcgUnit(state) * 10 - 5;
        final x = center.dx + math.cos(angle + wobble * 0.1) * dist;
        final y = center.dy + math.sin(angle + wobble * 0.1) * dist;
        _tendrilPath.lineTo(x, y);
      }

      canvas.drawPath(_tendrilPath, _tendrilPaint);
    }

    // Central void
    canvas.drawCircle(
      center,
      20 + glitchIntensity * 10,
      _coreGlowPaint
        ..color = NeonColors.magenta.withOpacity(0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawCircle(
      center,
      15,
      _corePaint..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(covariant _CorruptionPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.glitchIntensity != glitchIntensity;
  }
}
