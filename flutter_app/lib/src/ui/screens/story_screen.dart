import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../data/world_chronicles.dart';
import '../../models/level_config.dart';
import '../../services/level_service.dart';
import '../theme/neon_theme.dart';
import '../widgets/animated_grid_background.dart';
import '../widgets/epic_neon_button.dart';
import '../widgets/epic_neon_title.dart';
import '../widgets/world_art_generator.dart';
import 'chronicle_reader_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HYPER MEGA EPIC STORY SCREEN - THE ARCHITECT LOGS
/// Full holographic terminal experience with:
/// - Particle system background
/// - Holographic card effects with scanlines
/// - Typewriter text reveal animation
/// - Data stream borders
/// - Glitch effects on interaction
/// - Materialization animations
/// ═══════════════════════════════════════════════════════════════════════════

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> with TickerProviderStateMixin {
  static const int _levelsPerWorld = 10;

  late AnimationController _masterController;
  late AnimationController _pulseController;
  late AnimationController _scanlineController;
  late AnimationController _particleController;
  late AnimationController _glitchController;

  final List<_EnergyParticle> _particles = [];
  int _rngState = 0x2c1b3c6d;
  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }
  double _nextUnit() => _lcgNext() / 0x7fffffff;
  int _nextInt(int max) => max <= 0 ? 0 : _lcgNext() % max;
  double _glitchIntensity = 0;
  int _revealedCardIndex = 0;
  Timer? _cardRevealTimer;

  static const List<_StoryChapter> _chapters = [
    _StoryChapter(
      worldId: 1,
      title: 'NEON FRONTIER',
      subtitle: 'ERROR_01: EL ORIGEN DEL VACÍO',
      beats: [
        'El "Decompiler" ha perforado el Sector 0. La realidad digital se desmorona en fragmentos de ruido.',
        'Como el Arquitecto, tu misión es anclar la red antes de que la corrupción sea irreversible.',
        'Cada torre es un cortafuegos. Cada disparo, una línea de código recuperada.',
      ],
      accent: NeonColors.cyan,
      icon: Icons.blur_on,
    ),
    _StoryChapter(
      worldId: 2,
      title: 'RIFT WARS',
      subtitle: 'ERROR_02: CASCADA DE MEMORIA',
      beats: [
        'El virus ha creado anomalías temporales. Los datos del pasado se filtran en el presente.',
        'Las grietas de energía magenta son cicatrices en la malla. Debes sellarlas con pura potencia de fuego.',
        'El ruido se vuelve más denso. La red grita pidiendo restauración.',
      ],
      accent: NeonColors.magenta,
      icon: Icons.waves,
    ),
    _StoryChapter(
      worldId: 3,
      title: 'SIGNAL WASTES',
      subtitle: 'ERROR_03: ECO EN EL VACÍO',
      beats: [
        'Desiertos de estática donde la señal muere. El Decompiler acecha en las sombras del código.',
        'Sin visibilidad total, las torres son faros en una tormenta de bits perdidos.',
        'Si la luz se apaga aquí, el Grid caerá en el silencio eterno.',
      ],
      accent: NeonColors.yellow,
      icon: Icons.signal_cellular_null,
    ),
    _StoryChapter(
      worldId: 4,
      title: 'ION CROWN',
      subtitle: 'ERROR_04: LA CORONA DE TORMENTA',
      beats: [
        'La última línea de defensa antes del Núcleo Central. Tormentas iónicas azotan la infraestructura.',
        'El enemigo ha movilizado a sus unidades de asedio más pesadas. El tiempo de corrección se agota.',
        'Solo una voluntad de hierro puede sostener la corona de energía.',
      ],
      accent: NeonColors.green,
      icon: Icons.electric_bolt,
    ),
    _StoryChapter(
      worldId: 5,
      title: 'SHARD VAULT',
      subtitle: 'ERROR_05: MEMORIAS CORRUPTAS',
      beats: [
        'Bóvedas de seguridad donde se guardan las funciones raíz. El virus intenta borrarlas para siempre.',
        'Recupera los fragmentos de memoria. Evoluciona tus sistemas. No permitas que el pasado desaparezca.',
      ],
      accent: NeonColors.red,
      icon: Icons.memory,
    ),
    _StoryChapter(
      worldId: 10,
      title: 'FINAL GATE',
      subtitle: 'SYS_FINAL: EL ÚLTIMO UMBRAL',
      beats: [
        'Todo converge al Núcleo. El Decompiler está materializando su forma final.',
        'Si la Puerta Final cae, el sistema entero será formateado al Vacío.',
        'Es hora de ejecutar la secuencia final. Por el Grid.',
      ],
      accent: NeonColors.white,
      icon: Icons.door_front_door,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Master materialization animation
    _masterController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..forward();

    // Continuous pulse for breathing effects
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    // Scanline sweep
    _scanlineController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    // Particle system
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..addListener(_updateParticles)..repeat();

    // Glitch controller
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Initialize particles
    for (int i = 0; i < 60; i++) {
      _particles.add(_EnergyParticle.random(_nextUnit, _nextInt));
    }

    // Card reveal sequence
    _cardRevealTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_revealedCardIndex < _chapters.length) {
        setState(() => _revealedCardIndex++);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _masterController.dispose();
    _pulseController.dispose();
    _scanlineController.dispose();
    _particleController.dispose();
    _glitchController.dispose();
    _cardRevealTimer?.cancel();
    super.dispose();
  }

  void _updateParticles() {
    for (final p in _particles) {
      p.update(0.016);
    }
    if (mounted) setState(() {});
  }

  void _triggerGlitch() {
    setState(() => _glitchIntensity = 1.0);
    _glitchController.forward(from: 0).then((_) {
      if (mounted) setState(() => _glitchIntensity = 0);
    });
  }

  int _worldForLevel(int levelId) => ((levelId - 1) ~/ _levelsPerWorld) + 1;

  List<LevelConfig> _levelsForWorld(LevelService service, int worldId) {
    return service.levels
        .where((level) => _worldForLevel(level.id) == worldId)
        .toList(growable: false);
  }

  _WorldProgress _worldProgress(LevelService service, int worldId) {
    final levels = _levelsForWorld(service, worldId);
    int completed = 0;
    bool unlocked = false;
    for (final level in levels) {
      if (service.isLevelUnlocked(level.id)) {
        unlocked = true;
      }
      if (service.getProgress(level.id).completed) {
        completed += 1;
      }
    }
    return _WorldProgress(
      total: levels.length,
      completed: completed,
      unlocked: unlocked || worldId == 1,
    );
  }

  void _openChronicleReader(int worldId) {
    _triggerGlitch();

    // Get the chronicle for this world
    final chronicle = WorldChronicles.getChronicle(worldId);
    if (chronicle == null) return;

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ChronicleReaderScreen(chronicle: chronicle),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final levelService = LevelService.instance;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _masterController,
          _pulseController,
          _scanlineController,
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Layer 1: Animated grid background
              const AnimatedGridBackground(child: SizedBox.expand()),

              // Layer 2: Particle system
              CustomPaint(
                painter: _ParticleSystemPainter(
                  particles: _particles,
                  opacity: _masterController.value,
                ),
                size: MediaQuery.of(context).size,
              ),

              // Layer 3: Cyber scan overlay
              CustomPaint(
                painter: _CyberScanOverlayPainter(
                  scanProgress: _scanlineController.value,
                  pulseValue: _pulseController.value,
                  masterOpacity: _masterController.value,
                  glitchIntensity: _glitchIntensity,
                ),
                size: MediaQuery.of(context).size,
              ),

              // Layer 4: Main content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // Epic Title with data corruption effect
                      _buildEpicHeader(),

                      const SizedBox(height: 16),

                      // Story cards list
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: _chapters.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final chapter = _chapters[index];
                            final progress = _worldProgress(levelService, chapter.worldId);
                            final isRevealed = index < _revealedCardIndex;

                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 400),
                              opacity: isRevealed ? 1.0 : 0.0,
                              child: AnimatedSlide(
                                duration: const Duration(milliseconds: 500),
                                offset: isRevealed ? Offset.zero : const Offset(0.3, 0),
                                curve: Curves.easeOutCubic,
                                child: _EpicStoryCard(
                                  chapter: chapter,
                                  progress: progress,
                                  pulseValue: _pulseController.value,
                                  scanProgress: _scanlineController.value,
                                  onTap: _triggerGlitch,
                                  cardIndex: index,
                                  onReadChronicle: () => _openChronicleReader(chapter.worldId),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Return button with glitch effect
                      _buildReturnButton(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

            ],
          );
        },
      ),
    );
  }

  Widget _buildEpicHeader() {
    final fadeIn = Curves.easeOut.transform(_masterController.value.clamp(0.0, 0.5) * 2);
    final glitchOffset = _glitchIntensity * (_nextUnit() - 0.5) * 6;

    return Transform.translate(
      offset: Offset(glitchOffset, 0),
      child: Column(
        children: [
          // Main title
          Opacity(
            opacity: fadeIn,
            child: const EpicNeonTitle(
              text: 'THE ARCHITECT LOGS',
              fontSize: 32,
              primaryColor: NeonColors.white,
              secondaryColor: NeonColors.cyan,
            ),
          ),
          const SizedBox(height: 8),

          // Animated status bar
          Opacity(
            opacity: fadeIn,
            child: _AnimatedStatusBar(
              pulseValue: _pulseController.value,
              scanProgress: _scanlineController.value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnButton() {
    final fadeIn = Curves.easeOut.transform(
      ((_masterController.value - 0.5) * 2).clamp(0.0, 1.0),
    );

    return Opacity(
      opacity: fadeIn,
      child: EpicNeonButton(
        text: 'RETURN TO MENU',
        icon: Icons.arrow_back_rounded,
        color: NeonColors.cyan,
        width: 220,
        height: 48,
        onPressed: () {
          _triggerGlitch();
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) Navigator.pop(context);
          });
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED STATUS BAR - System status with glitch text
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedStatusBar extends StatefulWidget {
  final double pulseValue;
  final double scanProgress;

  const _AnimatedStatusBar({
    required this.pulseValue,
    required this.scanProgress,
  });

  @override
  State<_AnimatedStatusBar> createState() => _AnimatedStatusBarState();
}

class _AnimatedStatusBarState extends State<_AnimatedStatusBar> {
  String _displayText = '';
  int _charIndex = 0;
  Timer? _typewriterTimer;
  static const _fullText = 'ESTADO DEL SISTEMA: CRÍTICO - RECURSIVE_DECOMPILE_DETECTED';
  static const _glitchChars = r'!@#$%^&*()_+-=[]{}|;:<>/?01';
  int _rngState = 0x5bd1e995;
  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }
  int _nextInt(int max) => max <= 0 ? 0 : _lcgNext() % max;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    super.dispose();
  }

  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (_charIndex < _fullText.length) {
        setState(() {
          _charIndex++;
          _displayText = _fullText.substring(0, _charIndex);
          // Add random glitch char at end
          if (_charIndex < _fullText.length) {
            _displayText += _glitchChars[_nextInt(_glitchChars.length)];
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderGlow = 0.3 + widget.pulseValue * 0.2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: NeonColors.cyan.withOpacity(0.08),
        border: Border.all(
          color: NeonColors.cyan.withOpacity(borderGlow),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: NeonColors.cyan.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated warning icon
          _AnimatedWarningIcon(pulseValue: widget.pulseValue),
          const SizedBox(width: 8),

          // Typewriter text
          Expanded(
            child: Text(
              _displayText,
              style: NeonTextStyles.small.copyWith(
                color: NeonColors.cyan,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Animated cursor
          _BlinkingCursor(pulseValue: widget.pulseValue),
        ],
      ),
    );
  }
}

class _AnimatedWarningIcon extends StatelessWidget {
  final double pulseValue;

  const _AnimatedWarningIcon({required this.pulseValue});

  @override
  Widget build(BuildContext context) {
    final scale = 0.9 + pulseValue * 0.2;
    final glow = 0.5 + pulseValue * 0.5;

    return Transform.scale(
      scale: scale,
      child: Icon(
        Icons.warning_amber_rounded,
        color: NeonColors.yellow.withOpacity(glow),
        size: 14,
        shadows: [
          Shadow(
            color: NeonColors.yellow.withOpacity(glow * 0.8),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatelessWidget {
  final double pulseValue;

  const _BlinkingCursor({required this.pulseValue});

  @override
  Widget build(BuildContext context) {
    final opacity = pulseValue > 0.5 ? 1.0 : 0.3;

    return Container(
      width: 8,
      height: 14,
      color: NeonColors.cyan.withOpacity(opacity),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EPIC STORY CARD - Holographic card with all effects
// ═══════════════════════════════════════════════════════════════════════════

class _EpicStoryCard extends StatefulWidget {
  final _StoryChapter chapter;
  final _WorldProgress progress;
  final double pulseValue;
  final double scanProgress;
  final VoidCallback onTap;
  final int cardIndex;
  final VoidCallback? onReadChronicle;

  const _EpicStoryCard({
    required this.chapter,
    required this.progress,
    required this.pulseValue,
    required this.scanProgress,
    required this.onTap,
    required this.cardIndex,
    this.onReadChronicle,
  });

  @override
  State<_EpicStoryCard> createState() => _EpicStoryCardState();
}

class _EpicStoryCardState extends State<_EpicStoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;
  final List<String> _revealedBeats = [];
  Timer? _beatRevealTimer;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _startBeatReveal();
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _beatRevealTimer?.cancel();
    super.dispose();
  }

  void _startBeatReveal() {
    int beatIndex = 0;
    _beatRevealTimer = Timer.periodic(
      Duration(milliseconds: 600 + widget.cardIndex * 100),
      (timer) {
        if (beatIndex < widget.chapter.beats.length) {
          setState(() => _revealedBeats.add(widget.chapter.beats[beatIndex]));
          beatIndex++;
        } else {
          timer.cancel();
        }
      },
    );
  }

  String get _statusLabel {
    if (!widget.progress.unlocked) return 'LOCKED';
    if (widget.progress.total > 0 && widget.progress.completed >= widget.progress.total) {
      return 'CLEARED';
    }
    if (widget.progress.completed > 0) return 'IN PROGRESS';
    return 'UNLOCKED';
  }

  Color get _statusColor {
    if (!widget.progress.unlocked) return NeonColors.red;
    if (widget.progress.total > 0 && widget.progress.completed >= widget.progress.total) {
      return NeonColors.green;
    }
    if (widget.progress.completed > 0) return NeonColors.cyan;
    return NeonColors.magenta;
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;
    final progress = widget.progress;
    final opacity = progress.unlocked ? 1.0 : 0.55;
    final progressRatio = progress.total == 0 ? 0.0 : progress.completed / progress.total;
    final borderGlow = 0.4 + widget.pulseValue * 0.2 + (_isHovered ? 0.3 : 0);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTap: () {
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            final hoverScale = 1.0 + _hoverController.value * 0.02;

            return Transform.scale(
              scale: hoverScale,
              child: CustomPaint(
                painter: _HolographicCardPainter(
                  accent: chapter.accent,
                  opacity: opacity,
                  borderGlow: borderGlow,
                  scanProgress: widget.scanProgress,
                  isHovered: _isHovered,
                  cardIndex: widget.cardIndex,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with world info and status
                      _buildHeader(chapter, progress, opacity),
                      const SizedBox(height: 10),

                      // Animated progress bar
                      _buildProgressBar(progressRatio, chapter.accent, opacity),
                      const SizedBox(height: 12),

                      // Procedural World Art
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 140,
                          width: double.infinity,
                          child: WorldArtGenerator(
                            worldId: chapter.worldId,
                            accentColor: chapter.accent,
                            width: 400,
                            height: 140,
                            animate: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title with holographic icon
                      _buildTitle(chapter, opacity),
                      const SizedBox(height: 6),

                      // Subtitle
                      Text(
                        chapter.subtitle,
                        style: NeonTextStyles.body.copyWith(
                          color: NeonColors.white.withOpacity(0.7 * opacity),
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Story beats with typewriter reveal
                      ..._buildBeats(chapter.accent, opacity),

                      // Read Chronicle Button
                      if (progress.unlocked && widget.onReadChronicle != null)
                        _buildReadChronicleButton(chapter.accent, opacity),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(_StoryChapter chapter, _WorldProgress progress, double opacity) {
    return Row(
      children: [
        // World identifier with hex decoration
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: chapter.accent.withOpacity(0.15),
            border: Border.all(color: chapter.accent.withOpacity(0.5)),
          ),
          child: Text(
            'WORLD ${chapter.worldId.toString().padLeft(2, '0')}',
            style: NeonTextStyles.small.copyWith(
              color: chapter.accent.withOpacity(opacity),
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Status badge
        _AnimatedStatusBadge(
          label: _statusLabel,
          color: _statusColor,
          pulseValue: widget.pulseValue,
        ),

        const Spacer(),

        // Node count
        Row(
          children: [
            Icon(
              Icons.hexagon_outlined,
              color: NeonColors.white.withOpacity(0.5),
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              '${progress.completed}/${progress.total}',
              style: NeonTextStyles.small.copyWith(
                color: NeonColors.white.withOpacity(0.6),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(double ratio, Color accent, double opacity) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth * ratio.clamp(0.0, 1.0);

          return Stack(
            children: [
              // Animated fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withOpacity(0.9 * opacity),
                      accent.withOpacity(0.5 * opacity),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),

              // Energy pulse traveling along bar
              if (ratio > 0)
                Positioned(
                  left: width * widget.pulseValue - 4,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTitle(_StoryChapter chapter, double opacity) {
    return Row(
      children: [
        // Holographic icon
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                chapter.accent.withOpacity(0.4 * opacity),
                chapter.accent.withOpacity(0.1 * opacity),
              ],
            ),
            border: Border.all(
              color: chapter.accent.withOpacity(0.6 * opacity),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: chapter.accent.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Icon(
            chapter.icon,
            color: chapter.accent.withOpacity(opacity),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),

        // Title text with glow
        Expanded(
          child: Text(
            chapter.title,
            style: NeonTextStyles.title.copyWith(
              fontSize: 22,
              color: chapter.accent.withOpacity(opacity),
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: chapter.accent.withOpacity(0.6),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),

        // Animated accent bar
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                chapter.accent.withOpacity(0.9 * opacity),
                chapter.accent.withOpacity(0.3 * opacity),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: chapter.accent.withOpacity(0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBeats(Color accent, double opacity) {
    return _revealedBeats.map((beat) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated bullet point
            Container(
              margin: const EdgeInsets.only(top: 5),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(opacity),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Beat text
            Expanded(
              child: Text(
                beat,
                style: NeonTextStyles.body.copyWith(
                  color: NeonColors.white.withOpacity(0.85 * opacity),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildReadChronicleButton(Color accent, double opacity) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GestureDetector(
        onTap: widget.onReadChronicle,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            final glowIntensity = 0.4 + widget.pulseValue * 0.3;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withOpacity(0.2 * opacity),
                    accent.withOpacity(0.1 * opacity),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accent.withOpacity(glowIntensity * opacity),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.3 * opacity),
                    blurRadius: 12,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_stories,
                    color: accent.withOpacity(opacity),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'LEER CRÓNICA COMPLETA',
                    style: NeonTextStyles.body.copyWith(
                      color: accent.withOpacity(opacity),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: accent.withOpacity(0.7 * opacity),
                    size: 14,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double pulseValue;

  const _AnimatedStatusBadge({
    required this.label,
    required this.color,
    required this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    final glow = 0.3 + pulseValue * 0.3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(glow)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(glow * 0.5),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Text(
        label,
        style: NeonTextStyles.small.copyWith(
          color: color,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════

class _HolographicCardPainter extends CustomPainter {
  final Color accent;
  final double opacity;
  final double borderGlow;
  final double scanProgress;
  final bool isHovered;
  final int cardIndex;

  static final Paint _innerGradientPaint = Paint();
  static final Paint _scanlinePaint = Paint();
  static final Map<int, Shader> _innerGradientShaders = {};
  static final Map<int, Shader> _scanlineShaders = {};

  static int _innerGradientKey(Size size, int opacityStep, int colorValue) {
    return (size.width.round() << 32) ^ (size.height.round() << 16) ^ (opacityStep << 8) ^ colorValue;
  }

  static int _scanlineKey(Size size, int opacityStep, int colorValue) {
    return (size.width.round() << 16) ^ (opacityStep << 8) ^ colorValue;
  }

  _HolographicCardPainter({
    required this.accent,
    required this.opacity,
    required this.borderGlow,
    required this.scanProgress,
    required this.isHovered,
    required this.cardIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // Background
    final bgPaint = Paint()
      ..color = NeonColors.surfaceBg.withOpacity(0.85 * opacity);
    canvas.drawRRect(rrect, bgPaint);

    // Inner gradient overlay
    final opacityStep = (opacity * 60).round();
    final innerKey = _innerGradientKey(size, opacityStep, accent.value);
    final innerShader = _innerGradientShaders.putIfAbsent(innerKey, () {
      final scalar = opacityStep / 60.0;
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withOpacity(0.08 * scalar),
          Colors.transparent,
          accent.withOpacity(0.04 * scalar),
        ],
      ).createShader(rect);
    });
    _innerGradientPaint.shader = innerShader;
    canvas.drawRRect(rrect, _innerGradientPaint);

    // Scanline effect inside card
    final scanY = size.height * scanProgress;
    final scanKey = _scanlineKey(size, opacityStep, accent.value);
    final scanShader = _scanlineShaders.putIfAbsent(scanKey, () {
      final scalar = opacityStep / 60.0;
      return LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          accent.withOpacity(0.15 * scalar),
          accent.withOpacity(0.25 * scalar),
          accent.withOpacity(0.15 * scalar),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 4));
    });
    _scanlinePaint.shader = scanShader;
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.translate(0, scanY - 2);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 4), _scanlinePaint);
    canvas.restore();

    // Border with glow
    final borderPaint = Paint()
      ..color = accent.withOpacity(borderGlow * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovered ? 2 : 1.5;
    canvas.drawRRect(rrect, borderPaint);

    // Outer glow
    final glowPaint = Paint()
      ..color = accent.withOpacity(0.3 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, glowPaint);

    // Corner accents
    _drawCornerAccents(canvas, size, accent, opacity);

    // Data stream on left edge
    _drawDataStream(canvas, size, accent, opacity);
  }

  void _drawCornerAccents(Canvas canvas, Size size, Color color, double opacity) {
    const cornerSize = 12.0;
    final cornerPaint = Paint()
      ..color = color.withOpacity(0.7 * opacity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(
      const Offset(0, 12),
      const Offset(0, 0),
      cornerPaint,
    );
    canvas.drawLine(
      const Offset(0, 0),
      Offset(cornerSize, 0),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - cornerSize, 0),
      Offset(size.width, 0),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, 12),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(0, size.height - 12),
      Offset(0, size.height),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerSize, size.height),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - cornerSize, size.height),
      Offset(size.width, size.height),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - 12),
      Offset(size.width, size.height),
      cornerPaint,
    );
  }

  void _drawDataStream(Canvas canvas, Size size, Color color, double opacity) {
    final streamPaint = Paint()
      ..color = color.withOpacity(0.4 * opacity)
      ..strokeWidth = 1;

    final time = scanProgress * 10 + cardIndex;
    for (int i = 0; i < 5; i++) {
      final y = ((time + i * 0.2) % 1.0) * size.height;
      final length = 3.0 + (i % 3) * 2;
      canvas.drawLine(
        Offset(2, y),
        Offset(2, y + length),
        streamPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_HolographicCardPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress ||
        oldDelegate.isHovered != isHovered ||
        oldDelegate.borderGlow != borderGlow;
  }
}

class _ParticleSystemPainter extends CustomPainter {
  final List<_EnergyParticle> particles;
  final double opacity;

  static final Paint _glowPaint = Paint();
  static final Paint _corePaint = Paint();
  static final Map<int, MaskFilter> _blurCache = {};

  static MaskFilter _blur(double sigma) {
    var key = sigma.round();
    if (key < 1) key = 1;
    if (key > 20) key = 20;
    return _blurCache.putIfAbsent(
      key,
      () => MaskFilter.blur(BlurStyle.normal, key.toDouble()),
    );
  }

  _ParticleSystemPainter({
    required this.particles,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final pos = Offset(p.x * size.width, p.y * size.height);

      // Glow
      _glowPaint
        ..color = p.color.withOpacity(p.alpha * 0.5 * opacity)
        ..maskFilter = _blur(p.size * 2);
      canvas.drawCircle(pos, p.size * 1.2, _glowPaint);

      // Core
      _corePaint.color = p.color.withOpacity(p.alpha * 0.9 * opacity);
      canvas.drawCircle(pos, p.size * 0.5, _corePaint);
    }
  }

  @override
  bool shouldRepaint(_ParticleSystemPainter oldDelegate) => true;
}

class _CyberScanOverlayPainter extends CustomPainter {
  final double scanProgress;
  final double pulseValue;
  final double masterOpacity;
  final double glitchIntensity;

  static final Paint _scanlinePaint = Paint();
  static final Paint _scanline2Paint = Paint();
  static final Paint _crtLinePaint = Paint();
  static final Paint _glitchRedPaint = Paint();
  static final Paint _glitchCyanPaint = Paint();
  static final Paint _glitchNoisePaint = Paint();
  static final Map<int, Shader> _scanlineShaders = {};

  static int _scanlineKey(Size size, int opacityStep) {
    return (size.width.round() << 16) ^ opacityStep;
  }

  _CyberScanOverlayPainter({
    required this.scanProgress,
    required this.pulseValue,
    required this.masterOpacity,
    required this.glitchIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (masterOpacity <= 0.01 || size.width <= 0 || size.height <= 0) return;
    // Horizontal scan line
    final scanY = scanProgress * size.height;
    final opacityStep = (masterOpacity * 60).round();
    final scanKey = _scanlineKey(size, opacityStep);
    final scanShader = _scanlineShaders.putIfAbsent(scanKey, () {
      final scalar = opacityStep / 60.0;
      return LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          NeonColors.cyan.withOpacity(0.2 * scalar),
          NeonColors.cyan.withOpacity(0.4 * scalar),
          NeonColors.cyan.withOpacity(0.2 * scalar),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 4));
    });
    _scanlinePaint.shader = scanShader;
    canvas.save();
    canvas.translate(0, scanY - 2);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 4), _scanlinePaint);
    canvas.restore();

    // Secondary scan line (opposite direction)
    final scan2Y = (1 - scanProgress) * size.height;
    _scanline2Paint.color = NeonColors.magenta.withOpacity(0.1 * masterOpacity);
    canvas.drawRect(Rect.fromLTWH(0, scan2Y - 1, size.width, 2), _scanline2Paint);

    // CRT scanlines (subtle horizontal lines)
    _crtLinePaint.color = Colors.black.withOpacity(0.05 * masterOpacity);
    for (int i = 0; i < size.height ~/ 4; i++) {
      final y = i * 4.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _crtLinePaint);
    }

    // Glitch effect
    if (glitchIntensity > 0.01) {
      _drawGlitch(canvas, size);
    }
  }

  void _drawGlitch(Canvas canvas, Size size) {
    int rngState = ((scanProgress * 100000).round() ^ (glitchIntensity * 1000).round() ^ 0x9e3779b9) & 0x7fffffff;
    int lcgNext() {
      rngState = (1664525 * rngState + 1013904223) & 0x7fffffff;
      return rngState;
    }
    double nextUnit() => lcgNext() / 0x7fffffff;

    for (int i = 0; i < 8; i++) {
      final y = nextUnit() * size.height;
      final height = 2 + nextUnit() * 6;
      final offsetX = (nextUnit() - 0.5) * 15 * glitchIntensity;

      // RGB split
      _glitchRedPaint.color = Colors.red.withOpacity(0.15 * glitchIntensity);
      canvas.drawRect(
        Rect.fromLTWH(-offsetX, y, size.width, height),
        _glitchRedPaint,
      );
      _glitchCyanPaint.color = NeonColors.cyan.withOpacity(0.15 * glitchIntensity);
      canvas.drawRect(
        Rect.fromLTWH(offsetX, y, size.width, height),
        _glitchCyanPaint,
      );
    }

    // Static noise
    for (int i = 0; i < 30; i++) {
      final x = nextUnit() * size.width;
      final y = nextUnit() * size.height;
      final noiseAlpha = nextUnit() * 0.3 * glitchIntensity;
      if (noiseAlpha <= 0.01) continue;
      _glitchNoisePaint.color = Colors.white.withOpacity(noiseAlpha);
      canvas.drawRect(
        Rect.fromLTWH(x, y, 2, 2),
        _glitchNoisePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CyberScanOverlayPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress ||
        oldDelegate.glitchIntensity != glitchIntensity;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class _StoryChapter {
  const _StoryChapter({
    required this.worldId,
    required this.title,
    required this.subtitle,
    required this.beats,
    required this.accent,
    this.icon = Icons.blur_circular,
  });

  final int worldId;
  final String title;
  final String subtitle;
  final List<String> beats;
  final Color accent;
  final IconData icon;
}

class _WorldProgress {
  const _WorldProgress({
    required this.total,
    required this.completed,
    required this.unlocked,
  });

  final int total;
  final int completed;
  final bool unlocked;
}

class _EnergyParticle {
  double x, y;
  double vx, vy;
  double life;
  double maxLife;
  double size;
  Color color;
  int _rngState;

  _EnergyParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.color,
    required int rngState,
  }) : _rngState = rngState;

  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }
  double _nextUnit() => _lcgNext() / 0x7fffffff;
  int _nextInt(int max) => max <= 0 ? 0 : _lcgNext() % max;

  factory _EnergyParticle.random(double Function() nextUnit, int Function(int) nextInt) {
    final colors = [
      NeonColors.cyan,
      NeonColors.magenta,
      NeonColors.purple,
      NeonColors.blue,
    ];
    return _EnergyParticle(
      x: nextUnit(),
      y: nextUnit(),
      vx: (nextUnit() - 0.5) * 0.005,
      vy: -0.002 - nextUnit() * 0.005, // Mostly upward drift
      life: nextUnit(),
      maxLife: 0.8 + nextUnit() * 0.4,
      size: 1.5 + nextUnit() * 2.5,
      color: colors[nextInt(colors.length)],
      rngState: nextInt(0x7fffffff),
    );
  }

  void update(double dt) {
    x += vx;
    y += vy;
    life -= dt * 0.4;

    if (life <= 0 || y < -0.1 || x < -0.1 || x > 1.1) {
      x = _nextUnit();
      y = 1.0 + _nextUnit() * 0.1;
      life = maxLife;
    }
  }

  double get alpha => (life / maxLife).clamp(0.0, 1.0);
}
