import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../data/world_chronicles.dart';
import '../theme/neon_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CHRONICLE READER - IMMERSIVE STORY EXPERIENCE
/// Full-screen cinematic reading experience with:
/// - Typewriter text animation
/// - Atmospheric particle systems
/// - Dynamic lighting based on mood
/// - Character portrait animations
/// - Procedurally generated world art
/// - Ambient sound integration hooks
/// ═══════════════════════════════════════════════════════════════════════════

class ChronicleReaderScreen extends StatefulWidget {
  final WorldChronicle chronicle;
  final int startChapter;

  const ChronicleReaderScreen({
    super.key,
    required this.chronicle,
    this.startChapter = 0,
  });

  @override
  State<ChronicleReaderScreen> createState() => _ChronicleReaderScreenState();
}

class _ChronicleReaderScreenState extends State<ChronicleReaderScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _textController;
  late AnimationController _transitionController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  // State
  int _currentChapterIndex = 0;
  int _currentParagraphIndex = 0;
  int _revealedCharacters = 0;
  bool _isTransitioning = false;
  bool _showInterlude = false;
  bool _isPaused = false;
  final ScrollController _scrollController = ScrollController();

  // Particles
  final List<_AtmosphereParticle> _particles = [];
  final math.Random _random = math.Random();

  // Typewriter
  Timer? _typewriterTimer;
  static const int _charsPerTick = 2;
  static const Duration _tickDuration = Duration(milliseconds: 30);

  ChronicleChapter get _currentChapter =>
      widget.chronicle.chapters[_currentChapterIndex];

  String get _currentParagraph =>
      _currentChapter.paragraphs[_currentParagraphIndex];

  bool get _isLastParagraph =>
      _currentParagraphIndex >= _currentChapter.paragraphs.length - 1;

  bool get _isLastChapter =>
      _currentChapterIndex >= widget.chronicle.chapters.length - 1;

  bool get _isFullyRevealed => _revealedCharacters >= _currentParagraph.length;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.startChapter;

    // Background animation (slow rotation, color shifts)
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Text reveal animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Chapter transition
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Particle system
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..addListener(_updateParticles);
    _particleController.repeat();

    // Pulse for glowing effects
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Initialize particles
    _initializeParticles();

    // Start typewriter effect
    _startTypewriter();
  }

  void _initializeParticles() {
    _particles.clear();
    final mood = _currentChapter.mood;
    final count = _getParticleCountForMood(mood);

    for (int i = 0; i < count; i++) {
      _particles.add(_AtmosphereParticle.generate(
        _random,
        mood,
        widget.chronicle.accentColor,
      ));
    }
  }

  int _getParticleCountForMood(ChapterMood mood) {
    switch (mood) {
      case ChapterMood.epic:
      case ChapterMood.action:
        return 80;
      case ChapterMood.mysterious:
      case ChapterMood.dark:
      case ChapterMood.horror:
        return 40;
      case ChapterMood.hopeful:
      case ChapterMood.triumphant:
        return 60;
      default:
        return 50;
    }
  }

  void _updateParticles() {
    if (!mounted) return;
    for (final p in _particles) {
      p.update(0.016);
    }
    setState(() {});
  }

  void _startTypewriter() {
    _revealedCharacters = 0;
    _typewriterTimer?.cancel();
    _typewriterTimer = Timer.periodic(_tickDuration, (timer) {
      if (!mounted || _isPaused) return;
      setState(() {
        _revealedCharacters += _charsPerTick;
        if (_revealedCharacters >= _currentParagraph.length) {
          _revealedCharacters = _currentParagraph.length;
          timer.cancel();
        }
      });
    });
  }

  void _skipToEnd() {
    _typewriterTimer?.cancel();
    setState(() {
      _revealedCharacters = _currentParagraph.length;
    });
  }

  void _nextContent() {
    if (!_isFullyRevealed) {
      _skipToEnd();
      return;
    }

    // Check for interlude
    if (_isLastParagraph &&
        _currentChapter.interlude != null &&
        !_showInterlude) {
      setState(() => _showInterlude = true);
      return;
    }

    if (_isLastParagraph) {
      if (_isLastChapter) {
        _showCompletionDialog();
      } else {
        _transitionToNextChapter();
      }
    } else {
      setState(() {
        _currentParagraphIndex++;
        _showInterlude = false;
      });
      _startTypewriter();
      _scrollToTop();
    }
  }

  void _previousContent() {
    if (_showInterlude) {
      setState(() => _showInterlude = false);
      return;
    }

    if (_currentParagraphIndex > 0) {
      setState(() {
        _currentParagraphIndex--;
        _revealedCharacters = _currentParagraph.length;
      });
      _scrollToTop();
    } else if (_currentChapterIndex > 0) {
      setState(() {
        _currentChapterIndex--;
        _currentParagraphIndex = _currentChapter.paragraphs.length - 1;
        _revealedCharacters = _currentParagraph.length;
        _showInterlude = false;
      });
      _initializeParticles();
      _scrollToTop();
    }
  }

  void _transitionToNextChapter() async {
    setState(() => _isTransitioning = true);
    await _transitionController.forward();

    setState(() {
      _currentChapterIndex++;
      _currentParagraphIndex = 0;
      _showInterlude = false;
    });

    _initializeParticles();
    _startTypewriter();

    await _transitionController.reverse();
    setState(() => _isTransitioning = false);
    _scrollToTop();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CompletionDialog(
        chronicle: widget.chronicle,
        onClose: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _textController.dispose();
    _transitionController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _typewriterTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _nextContent,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 0) {
              _previousContent();
            } else {
              _nextContent();
            }
          }
        },
        child: Stack(
          children: [
            // Animated background
            _buildAnimatedBackground(),

            // Particle system
            _buildParticleSystem(),

            // Main content
            AnimatedBuilder(
              animation: _transitionController,
              builder: (context, child) {
                final opacity = _isTransitioning
                    ? 1.0 - _transitionController.value
                    : 1.0;
                return Opacity(
                  opacity: opacity,
                  child: child,
                );
              },
              child: _buildContent(),
            ),

            // Chapter transition overlay
            if (_isTransitioning) _buildTransitionOverlay(),

            // Navigation UI
            _buildNavigationUI(),

            // Progress indicator
            _buildProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _BackgroundPainter(
            time: _backgroundController.value,
            mood: _currentChapter.mood,
            primaryColor: widget.chronicle.accentColor,
            secondaryColor: widget.chronicle.secondaryColor,
            pulseValue: _pulseController.value,
          ),
        );
      },
    );
  }

  Widget _buildParticleSystem() {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _ParticlePainter(
        particles: _particles,
        accentColor: widget.chronicle.accentColor,
      ),
    );
  }

  Widget _buildContent() {
    final screenSize = MediaQuery.of(context).size;
    final isWide = screenSize.width > 800;
    final horizontalPadding = isWide ? screenSize.width * 0.15 : 24.0;

    return SafeArea(
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter header
            _buildChapterHeader(),

            const SizedBox(height: 40),

            // Speaker indicator (if any)
            if (_currentChapter.speaker != null) _buildSpeakerIndicator(),

            // Main text or interlude
            _showInterlude
                ? _buildInterlude()
                : _buildParagraphText(),

            const SizedBox(height: 60),

            // Tap hint
            _buildTapHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chapter number
        Text(
          'CAPÍTULO ${_currentChapter.index}',
          style: TextStyle(
            color: widget.chronicle.accentColor.withOpacity(0.6),
            fontSize: 12,
            fontFamily: 'monospace',
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // Chapter title
        Text(
          _currentChapter.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: widget.chronicle.accentColor.withOpacity(0.5),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle
        Text(
          _currentChapter.subtitle,
          style: TextStyle(
            color: widget.chronicle.accentColor.withOpacity(0.8),
            fontSize: 14,
            fontStyle: FontStyle.italic,
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 16),

        // Decorative line
        Container(
          width: 100,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.chronicle.accentColor,
                widget.chronicle.accentColor.withOpacity(0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakerIndicator() {
    final speaker = _currentChapter.speaker!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: speaker.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: speaker.color.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            speaker.prefix,
            style: TextStyle(
              color: speaker.color,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParagraphText() {
    final visibleText = _currentParagraph.substring(
      0,
      _revealedCharacters.clamp(0, _currentParagraph.length),
    );

    // Check if this is dialogue (starts with ")
    final isDialogue = _currentParagraph.startsWith('"');

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Text(
          visibleText,
          style: TextStyle(
            color: isDialogue
                ? widget.chronicle.accentColor.withOpacity(0.95)
                : Colors.white.withOpacity(0.9),
            fontSize: isDialogue ? 20 : 18,
            height: 1.8,
            fontStyle: isDialogue ? FontStyle.italic : FontStyle.normal,
            letterSpacing: 0.3,
            shadows: isDialogue
                ? [
                    Shadow(
                      color: widget.chronicle.accentColor.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }

  Widget _buildInterlude() {
    final lines = _currentChapter.interlude!.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        ...lines.map((line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                line,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.chronicle.accentColor.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1,
                ),
              ),
            )),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTapHint() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final opacity = 0.3 + _pulseController.value * 0.3;
          return Text(
            _isFullyRevealed ? 'Toca para continuar ▸' : 'Toca para saltar ▸▸',
            style: TextStyle(
              color: Colors.white.withOpacity(opacity),
              fontSize: 12,
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransitionOverlay() {
    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(_transitionController.value),
          child: Center(
            child: Text(
              'CAPÍTULO ${_currentChapterIndex + 2}',
              style: TextStyle(
                color: widget.chronicle.accentColor
                    .withOpacity(_transitionController.value),
                fontSize: 24,
                fontFamily: 'monospace',
                letterSpacing: 8,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationUI() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white.withOpacity(0.6),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),

              // World name
              Text(
                widget.chronicle.name,
                style: TextStyle(
                  color: widget.chronicle.accentColor.withOpacity(0.8),
                  fontSize: 14,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),

              // Pause/menu button
              IconButton(
                icon: Icon(
                  _isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white.withOpacity(0.6),
                ),
                onPressed: () {
                  setState(() => _isPaused = !_isPaused);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalParagraphs = widget.chronicle.chapters
        .fold<int>(0, (sum, ch) => sum + ch.paragraphs.length);
    var currentProgress = 0;
    for (int i = 0; i < _currentChapterIndex; i++) {
      currentProgress += widget.chronicle.chapters[i].paragraphs.length;
    }
    currentProgress += _currentParagraphIndex + 1;

    final progress = currentProgress / totalParagraphs;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.chronicle.accentColor,
              widget.chronicle.accentColor.withOpacity(0.3),
            ],
            stops: [progress, progress],
          ),
        ),
      ),
    );
  }
}

/// Background painter for atmospheric effects
class _BackgroundPainter extends CustomPainter {
  final double time;
  final ChapterMood mood;
  final Color primaryColor;
  final Color secondaryColor;
  final double pulseValue;

  _BackgroundPainter({
    required this.time,
    required this.mood,
    required this.primaryColor,
    required this.secondaryColor,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final baseGradient = RadialGradient(
      center: Alignment(
        math.sin(time * math.pi * 2) * 0.3,
        math.cos(time * math.pi * 2) * 0.3,
      ),
      radius: 1.5,
      colors: [
        _getMoodColor(mood).withOpacity(0.15 + pulseValue * 0.05),
        secondaryColor.withOpacity(0.08),
        Colors.black,
      ],
      stops: const [0.0, 0.4, 1.0],
    ).createShader(rect);

    canvas.drawRect(rect, Paint()..shader = baseGradient);

    // Grid lines (subtle)
    _drawGridLines(canvas, size);

    // Mood-specific effects
    _drawMoodEffects(canvas, size);
  }

  Color _getMoodColor(ChapterMood mood) {
    switch (mood) {
      case ChapterMood.epic:
      case ChapterMood.triumphant:
        return primaryColor;
      case ChapterMood.mysterious:
        return const Color(0xFF6600AA);
      case ChapterMood.dark:
      case ChapterMood.horror:
        return const Color(0xFF220011);
      case ChapterMood.hopeful:
        return const Color(0xFF00AA66);
      case ChapterMood.action:
        return const Color(0xFFFF4400);
      case ChapterMood.tragic:
        return const Color(0xFF4444AA);
      case ChapterMood.revelation:
        return const Color(0xFFFFAA00);
      case ChapterMood.philosophical:
        return const Color(0xFF444488);
    }
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 60.0;
    final offsetX = (time * 20) % spacing;
    final offsetY = (time * 10) % spacing;

    // Vertical lines
    for (double x = offsetX; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = offsetY; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawMoodEffects(Canvas canvas, Size size) {
    switch (mood) {
      case ChapterMood.action:
      case ChapterMood.epic:
        _drawEnergyWaves(canvas, size);
        break;
      case ChapterMood.mysterious:
      case ChapterMood.dark:
        _drawFog(canvas, size);
        break;
      case ChapterMood.horror:
        _drawGlitchLines(canvas, size);
        break;
      default:
        break;
    }
  }

  void _drawEnergyWaves(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final radius = size.width * (0.3 + i * 0.2 + time * 0.1) % size.width;
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.5),
        radius,
        paint,
      );
    }
  }

  void _drawFog(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    for (int i = 0; i < 5; i++) {
      final x = (math.sin(time * math.pi * 2 + i) * 0.5 + 0.5) * size.width;
      final y = (math.cos(time * math.pi + i * 0.7) * 0.5 + 0.5) * size.height;
      canvas.drawCircle(Offset(x, y), 150, paint);
    }
  }

  void _drawGlitchLines(Canvas canvas, Size size) {
    if ((time * 10).floor() % 5 != 0) return;

    final paint = Paint()
      ..color = primaryColor.withOpacity(0.3)
      ..strokeWidth = 2;

    final y = (time * 500) % size.height;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.pulseValue != pulseValue;
  }
}

/// Particle for atmosphere
class _AtmosphereParticle {
  double x, y;
  double vx, vy;
  double size;
  double alpha;
  double lifetime;
  Color color;

  _AtmosphereParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alpha,
    required this.lifetime,
    required this.color,
  });

  factory _AtmosphereParticle.generate(
    math.Random random,
    ChapterMood mood,
    Color baseColor,
  ) {
    final speed = _getSpeedForMood(mood, random);
    return _AtmosphereParticle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      vx: (random.nextDouble() - 0.5) * speed,
      vy: (random.nextDouble() - 0.5) * speed - 0.01, // Slight upward drift
      size: random.nextDouble() * 3 + 1,
      alpha: random.nextDouble() * 0.5 + 0.1,
      lifetime: random.nextDouble(),
      color: _getColorForMood(mood, baseColor, random),
    );
  }

  static double _getSpeedForMood(ChapterMood mood, math.Random random) {
    switch (mood) {
      case ChapterMood.action:
      case ChapterMood.epic:
        return 0.03 + random.nextDouble() * 0.02;
      case ChapterMood.mysterious:
      case ChapterMood.philosophical:
        return 0.005 + random.nextDouble() * 0.005;
      default:
        return 0.01 + random.nextDouble() * 0.01;
    }
  }

  static Color _getColorForMood(
    ChapterMood mood,
    Color baseColor,
    math.Random random,
  ) {
    switch (mood) {
      case ChapterMood.horror:
        return Color.lerp(baseColor, Colors.red, random.nextDouble() * 0.5)!;
      case ChapterMood.hopeful:
        return Color.lerp(baseColor, Colors.white, random.nextDouble() * 0.3)!;
      default:
        return baseColor;
    }
  }

  void update(double dt) {
    x += vx * dt * 60;
    y += vy * dt * 60;
    lifetime += dt * 0.1;

    // Wrap around
    if (x < 0) x = 1;
    if (x > 1) x = 0;
    if (y < 0) y = 1;
    if (y > 1) y = 0;

    // Pulse alpha
    alpha = (math.sin(lifetime * math.pi * 2) * 0.25 + 0.25).clamp(0.05, 0.5);
  }
}

/// Particle painter
class _ParticlePainter extends CustomPainter {
  final List<_AtmosphereParticle> particles;
  final Color accentColor;

  _ParticlePainter({
    required this.particles,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.alpha)
        ..maskFilter = p.size > 2
            ? const MaskFilter.blur(BlurStyle.normal, 3)
            : null;

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

/// Completion dialog
class _CompletionDialog extends StatelessWidget {
  final WorldChronicle chronicle;
  final VoidCallback onClose;

  const _CompletionDialog({
    required this.chronicle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF0a0a18).withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: chronicle.accentColor.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: chronicle.accentColor.withOpacity(0.2),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories,
              color: chronicle.accentColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'CRÓNICA COMPLETADA',
              style: TextStyle(
                color: chronicle.accentColor,
                fontSize: 18,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              chronicle.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: chronicle.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                chronicle.closingQuote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: chronicle.accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'VOLVER',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
