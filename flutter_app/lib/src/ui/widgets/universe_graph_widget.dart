import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../screens/level_select_screen.dart';

class UniverseGraphWidget extends StatefulWidget {
  final List<WorldInfo> worlds;
  final Function(int worldId) onWorldSelected;

  const UniverseGraphWidget({
    super.key,
    required this.worlds,
    required this.onWorldSelected,
  });

  @override
  State<UniverseGraphWidget> createState() => _UniverseGraphWidgetState();
}

class _UniverseGraphWidgetState extends State<UniverseGraphWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _materializeController;
  late AnimationController _warpController;
  late AnimationController _glitchController;
  late AnimationController _planetEntranceController;
  late AnimationController _selectionController;
  late AnimationController _exitController;

  int? _hoveredWorld;
  int? _selectedWorld;
  bool _isExiting = false;
  final List<_Star> _stars = [];
  final List<_WarpLine> _warpLines = [];
  final List<_EnergyParticle> _particles = [];
  final List<_Constellation> _constellations = [];
  late final _FastRng _rng = _FastRng(DateTime.now().millisecondsSinceEpoch);
  double _glitchIntensity = 0;
  final List<double> _planetEntranceProgress = [];

  @override
  void initState() {
    super.initState();

    // Main slow rotation
    _mainController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    // Pulse for breathing effects
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    // Materialization
    _materializeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..forward();

    // Warp speed effect
    _warpController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    // Glitch effect
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // Planet entrance animation (staggered orbital insertion)
    _planetEntranceController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..forward();

    // Selection animation (zoom and energy pulse)
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Exit animation (planets disperse)
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Initialize planet entrance progress for each world
    for (int i = 0; i < widget.worlds.length; i++) {
      _planetEntranceProgress.add(0);
    }

    // Initialize stars (distant background)
    for (int i = 0; i < 200; i++) {
      _stars.add(_Star.random(_rng));
    }

    // Initialize warp lines
    for (int i = 0; i < 30; i++) {
      _warpLines.add(_WarpLine.random(_rng));
    }

    // Initialize floating particles
    for (int i = 0; i < 80; i++) {
      _particles.add(_EnergyParticle.random(_rng));
    }

    // Initialize constellations (connecting lines between stars)
    for (int i = 0; i < 15; i++) {
      _constellations.add(_Constellation.random(_rng));
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _materializeController.dispose();
    _warpController.dispose();
    _glitchController.dispose();
    _planetEntranceController.dispose();
    _selectionController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _triggerGlitch() {
    setState(() => _glitchIntensity = 1.0);
    _glitchController.forward(from: 0).then((_) {
      if (mounted) setState(() => _glitchIntensity = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final center = Offset(size.width / 2, size.height / 2);
        final radius = math.min(size.width, size.height) * 0.35;

        return MouseRegion(
          onHover: (event) => _updateHover(event.localPosition, center, radius),
          onExit: (_) => setState(() => _hoveredWorld = null),
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _mainController,
              _pulseController,
              _materializeController,
              _warpController,
              _planetEntranceController,
              _selectionController,
              _exitController,
            ]),
            builder: (context, child) {
              // Update animations
              _updateParticles();
              _updateWarpLines();
              _updatePlanetEntrance();

              return GestureDetector(
                onTapUp: (details) => _handleTap(details.localPosition, center, radius),
                child: CustomPaint(
                  size: size,
                  painter: _UltraEpicUniversePainter(
                    worlds: widget.worlds,
                    mainAnimation: _mainController.value,
                    pulseValue: _pulseController.value,
                    materializeValue: _materializeController.value,
                    warpValue: _warpController.value,
                    center: center,
                    radius: radius,
                    hoveredWorld: _hoveredWorld,
                    selectedWorld: _selectedWorld,
                    stars: _stars,
                    warpLines: _warpLines,
                    particles: _particles,
                    constellations: _constellations,
                    glitchIntensity: _glitchIntensity,
                    planetEntranceProgress: _planetEntranceProgress,
                    selectionProgress: _selectionController.value,
                    exitProgress: _exitController.value,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _updateParticles() {
    for (final p in _particles) {
      p.update(0.016);
    }
  }

  void _updateWarpLines() {
    for (final line in _warpLines) {
      line.update(0.016);
    }
  }

  void _updatePlanetEntrance() {
    final globalProgress = _planetEntranceController.value;
    for (int i = 0; i < widget.worlds.length; i++) {
      // Stagger each planet's entrance
      final delay = i * 0.08;
      final duration = 0.5;
      final planetProgress = ((globalProgress - delay) / duration).clamp(0.0, 1.0);
      _planetEntranceProgress[i] = planetProgress;
    }
  }

  void _updateHover(Offset pos, Offset center, double radius) {
    int? hovered;
    for (int i = 0; i < widget.worlds.length; i++) {
      final nodePos = _getWorldPosition(i, center, radius);
      if ((pos - nodePos).distance < 55) {
        hovered = widget.worlds[i].id;
        break;
      }
    }
    if (hovered != _hoveredWorld) {
      if (hovered != null) _triggerGlitch();
      setState(() => _hoveredWorld = hovered);
    }
  }

  Offset _getWorldPosition(int index, Offset center, double radius) {
    final count = widget.worlds.length;
    final baseAngle = (index / count) * math.pi * 2 - math.pi / 2;
    final orbitRadius = radius * (0.75 + (index % 2) * 0.2);

    return Offset(
      center.dx + orbitRadius * math.cos(baseAngle),
      center.dy + orbitRadius * math.sin(baseAngle),
    );
  }

  void _handleTap(Offset tapPos, Offset center, double radius) {
    if (_isExiting || _selectedWorld != null) return;

    for (int i = 0; i < widget.worlds.length; i++) {
      final nodePos = _getWorldPosition(i, center, radius);
      if ((tapPos - nodePos).distance < 55) {
        setState(() => _selectedWorld = widget.worlds[i].id);

        // Play selection animation
        _selectionController.forward(from: 0).then((_) {
          // Start exit animation
          setState(() => _isExiting = true);
          _exitController.forward(from: 0).then((_) {
            if (mounted) {
              widget.onWorldSelected(widget.worlds[i].id);
            }
          });
        });
        break;
      }
    }
  }
}

// ==================== DATA CLASSES ====================

class _FastRng {
  int _state;

  _FastRng(int seed) : _state = seed & 0x7fffffff;

  int _next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  double nextDouble() => _next() / 0x7fffffff;

  int nextInt(int max) => max <= 0 ? 0 : _next() % max;

  bool nextBool() => (_next() & 1) == 0;
}

class _Star {
  double x, y;
  double size;
  double twinklePhase;
  double twinkleSpeed;
  double brightness;
  Color color;
  final MaskFilter glowMask;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinklePhase,
    required this.twinkleSpeed,
    required this.brightness,
    required this.color,
    required this.glowMask,
  });

  factory _Star.random(_FastRng r) {
    final colors = [Colors.white, Colors.white, NeonColors.cyan, NeonColors.blue];
    final size = 0.5 + r.nextDouble() * 2.5;
    return _Star(
      x: r.nextDouble(),
      y: r.nextDouble(),
      size: size,
      twinklePhase: r.nextDouble() * math.pi * 2,
      twinkleSpeed: 0.5 + r.nextDouble() * 2,
      brightness: 0.3 + r.nextDouble() * 0.7,
      color: colors[r.nextInt(colors.length)],
      glowMask: MaskFilter.blur(BlurStyle.normal, size * 2),
    );
  }
}

class _WarpLine {
  static final _FastRng _rng = _FastRng(0x51f1e3);
  double angle;
  double startRadius;
  double length;
  double speed;
  double progress;
  Color color;

  _WarpLine({
    required this.angle,
    required this.startRadius,
    required this.length,
    required this.speed,
    required this.progress,
    required this.color,
  });

  factory _WarpLine.random(_FastRng r) {
    return _WarpLine(
      angle: r.nextDouble() * math.pi * 2,
      startRadius: 0.15 + r.nextDouble() * 0.1,
      length: 0.05 + r.nextDouble() * 0.15,
      speed: 0.3 + r.nextDouble() * 0.5,
      progress: r.nextDouble(),
      color: NeonColors.cyan.withOpacity(0.3 + r.nextDouble() * 0.4),
    );
  }

  void update(double dt) {
    progress += speed * dt;
    if (progress > 1) {
      progress = 0;
      angle = _rng.nextDouble() * math.pi * 2;
    }
  }
}

class _EnergyParticle {
  static final _FastRng _rng = _FastRng(0x63d2a5);
  double x, y;
  double vx, vy;
  double life;
  double maxLife;
  double size;
  Color color;
  double orbitAngle;
  double orbitRadius;
  bool isOrbiting;
  final MaskFilter glowMask;

  _EnergyParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.color,
    required this.orbitAngle,
    required this.orbitRadius,
    required this.isOrbiting,
    required this.glowMask,
  });

  factory _EnergyParticle.random(_FastRng r) {
    final colors = [NeonColors.cyan, NeonColors.magenta, NeonColors.purple, NeonColors.orange];
    final isOrbit = r.nextDouble() > 0.7;
    final size = 1 + r.nextDouble() * 3;
    return _EnergyParticle(
      x: r.nextDouble(),
      y: r.nextDouble(),
      vx: (r.nextDouble() - 0.5) * 0.015,
      vy: (r.nextDouble() - 0.5) * 0.015,
      life: r.nextDouble(),
      maxLife: 0.6 + r.nextDouble() * 0.4,
      size: size,
      color: colors[r.nextInt(colors.length)],
      orbitAngle: r.nextDouble() * math.pi * 2,
      orbitRadius: 0.3 + r.nextDouble() * 0.2,
      isOrbiting: isOrbit,
      glowMask: MaskFilter.blur(BlurStyle.normal, size * 2),
    );
  }

  void update(double dt) {
    if (isOrbiting) {
      orbitAngle += dt * 0.5;
      x = 0.5 + orbitRadius * math.cos(orbitAngle);
      y = 0.5 + orbitRadius * math.sin(orbitAngle);
    } else {
      x += vx;
      y += vy;
    }

    life -= dt * 0.25;
    if (life <= 0 || x < 0 || x > 1 || y < 0 || y > 1) {
      x = _rng.nextDouble();
      y = _rng.nextDouble();
      life = maxLife;
    }
  }

  double get alpha => (life / maxLife).clamp(0.0, 1.0);
}

class _Constellation {
  List<Offset> points;
  Color color;
  double opacity;

  _Constellation({
    required this.points,
    required this.color,
    required this.opacity,
  });

  factory _Constellation.random(_FastRng r) {
    final numPoints = 3 + r.nextInt(4);
    final baseX = r.nextDouble();
    final baseY = r.nextDouble();

    return _Constellation(
      points: List.generate(numPoints, (i) {
        return Offset(
          baseX + (r.nextDouble() - 0.5) * 0.15,
          baseY + (r.nextDouble() - 0.5) * 0.15,
        );
      }),
      color: NeonColors.cyan,
      opacity: 0.1 + r.nextDouble() * 0.15,
    );
  }
}

// ==================== MAIN PAINTER ====================

class _UltraEpicUniversePainter extends CustomPainter {
  final List<WorldInfo> worlds;
  final double mainAnimation;
  final double pulseValue;
  final double materializeValue;
  final double warpValue;
  final Offset center;
  final double radius;
  final int? hoveredWorld;
  final int? selectedWorld;
  final List<_Star> stars;
  final List<_WarpLine> warpLines;
  final List<_EnergyParticle> particles;
  final List<_Constellation> constellations;
  final double glitchIntensity;
  final List<double> planetEntranceProgress;
  final double selectionProgress;
  final double exitProgress;

  _UltraEpicUniversePainter({
    required this.worlds,
    required this.mainAnimation,
    required this.pulseValue,
    required this.materializeValue,
    required this.warpValue,
    required this.center,
    required this.radius,
    required this.hoveredWorld,
    required this.selectedWorld,
    required this.stars,
    required this.warpLines,
    required this.particles,
    required this.constellations,
    required this.glitchIntensity,
    required this.planetEntranceProgress,
    required this.selectionProgress,
    required this.exitProgress,
  });

  static final Paint _bgBasePaint = Paint();
  static final Paint _nebulaPaint1 = Paint();
  static final Paint _nebulaPaint2 = Paint();
  static final Paint _nebulaPaint3 = Paint();
  static final Paint _starGlowPaint = Paint();
  static final Paint _starCorePaint = Paint();
  static final Paint _starBrightPaint = Paint();
  static final Paint _constellationLinePaint = Paint()
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;
  static final Paint _constellationDotPaint = Paint();
  static final Path _constellationPath = Path();
  static final Paint _warpLinePaint = Paint()
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  static final Paint _eventHorizonPaint = Paint()..color = Colors.black;
  static final Paint _photonPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _diskPaint = Paint()
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _innerGlowPaint = Paint();
  static final Paint _lensPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _orbitPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _markerPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _beamPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _pulsePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _linkPaint = Paint()
    ..strokeWidth = 0.5;
  static final Paint _floatGlowPaint = Paint();
  static final Paint _floatCorePaint = Paint();
  static final Paint _planetAuraPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _planetBodyPaint = Paint();
  static final Paint _planetBandPaint = Paint()..strokeWidth = 1;
  static final Paint _planetAtmoPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  static final Paint _planetSpecularPaint = Paint();
  static final Paint _planetRingPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _moonGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _moonPaint = Paint();
  static final Paint _panelBgPaint = Paint();
  static final Paint _panelBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _panelLinePaint = Paint()..strokeWidth = 1;
  static final Paint _statusBgPaint = Paint();
  static final Paint _statusFillPaint = Paint();
  static final Paint _targetBracketPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _targetDotPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _orbitParticlePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _beaconPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _beaconRayPaint = Paint()..strokeWidth = 2;
  static final Paint _scanlinePaint = Paint();
  static final Paint _scanlinePaint2 = Paint();
  static final Paint _volumetricRayPaint = Paint();
  static final Paint _glitchRedPaint = Paint();
  static final Paint _glitchCyanPaint = Paint();
  static final Paint _glitchNoisePaint = Paint();
  static final Paint _vignettePaint = Paint();
  static final TextPainter _symbolPainter =
      TextPainter(textDirection: TextDirection.ltr);
  static final TextPainter _idPainter =
      TextPainter(textDirection: TextDirection.ltr);
  static final TextPainter _namePainter =
      TextPainter(textDirection: TextDirection.ltr);
  static final TextPainter _tagPainter =
      TextPainter(textDirection: TextDirection.ltr);
  static final Map<int, TextPainter> _idPainterCache = {};
  static final Map<int, TextPainter> _namePainterCache = {};
  static final Map<int, TextPainter> _tagPainterCache = {};
  static final Path _bandPath = Path();
  static final Path _volumetricRayPath = Path();

  static const int _bhFadeLevels = 32;
  static final Map<int, Shader> _diskShaderCache = {};
  static final Map<int, Shader> _innerGlowShaderCache = {};
  static int _symbolFadeLevel = -1;

  static Size? _beamShaderSize;
  static final Map<int, Shader> _beamShaderCache = {};
  static const int _beamOpacityLevels = 32;

  static Size? _planetShaderSize;
  static final Map<int, Shader> _planetAuraShaderCache = {};
  static final Map<int, Shader> _planetBodyShaderCache = {};
  static final Map<int, Shader> _planetSpecularShaderCache = {};
  static final Map<int, Shader> _moonShaderCache = {};
  static const int _planetFadeLevels = 32;

  static Size? _vignetteShaderSize;
  static Shader? _vignetteShader;

  static const int _warpIntensityLevels = 32;
  static final Map<int, ColorFilter> _warpFilterCache = {};
  static final Map<int, Shader> _warpShaderCache = {};

  static Size? _deepSpaceShaderSize;
  static int _deepSpaceShaderLevel = -1;
  static Shader? _bgBaseShader;
  static Shader? _nebulaShader1;
  static Shader? _nebulaShader2;
  static Shader? _nebulaShader3;

  static double _beaconRayShaderHeight = 0;
  static Shader? _beaconRayShader;
  static const int _beaconRayIntensityLevels = 32;
  static final Map<int, ColorFilter> _beaconRayFilterCache = {};

  static double _scanlineShaderWidth = 0;
  static Shader? _scanlineShader;
  static const int _scanlineIntensityLevels = 32;
  static final Map<int, ColorFilter> _scanlineFilterCache = {};

  static Size? _volumetricRayShaderSize;
  static Shader? _volumetricRayShader;
  static const int _volumetricRayIntensityLevels = 32;
  static final Map<int, ColorFilter> _volumetricRayFilterCache = {};

  static int _lcgNext(int state) => (state * 1664525 + 1013904223) & 0x7fffffff;
  static double _lcgUnit(int state) => state / 0x7fffffff;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    _ensureShaderCaches(size);

    // Layer 1: Deep space background
    _drawDeepSpaceBackground(canvas, size);

    // Layer 2: Star field with parallax
    _drawStarField(canvas, size);

    // Layer 3: Constellations
    _drawConstellations(canvas, size);

    // Layer 4: Warp speed lines
    _drawWarpLines(canvas, size);

    // Layer 5: Central black hole with accretion disk
    _drawBlackHole(canvas, size);

    // Layer 6: Orbital paths
    _drawOrbitalPaths(canvas);

    // Layer 7: Energy connections
    _drawEnergyNetwork(canvas);

    // Layer 8: Floating particles
    _drawFloatingParticles(canvas, size);

    // Layer 9: World nodes (planets)
    for (int i = 0; i < worlds.length; i++) {
      final pos = _getWorldPosition(i);
      final isHovered = hoveredWorld == worlds[i].id;
      _drawPlanetNode(canvas, pos, worlds[i], i, isHovered, size);
    }

    // Layer 10: Holographic scanlines
    _drawScanLines(canvas, size);

    // Layer 11: Volumetric light rays
    _drawVolumetricRays(canvas, size);

    // Layer 12: Glitch effect overlay
    if (glitchIntensity > 0) {
      _drawGlitchEffect(canvas, size);
    }

    // Layer 13: Edge vignette
    _drawVignette(canvas, size);
  }

  void _ensureShaderCaches(Size size) {
    if (_beamShaderSize != size) {
      _beamShaderSize = size;
      _beamShaderCache.clear();
    }
    if (_planetShaderSize != size) {
      _planetShaderSize = size;
      _planetAuraShaderCache.clear();
      _planetBodyShaderCache.clear();
      _planetSpecularShaderCache.clear();
      _moonShaderCache.clear();
    }
    if (_diskShaderCache.length > 128) _diskShaderCache.clear();
    if (_innerGlowShaderCache.length > 128) _innerGlowShaderCache.clear();
    if (_beamShaderCache.length > 128) _beamShaderCache.clear();
    if (_planetAuraShaderCache.length > 128) _planetAuraShaderCache.clear();
    if (_planetBodyShaderCache.length > 128) _planetBodyShaderCache.clear();
    if (_planetSpecularShaderCache.length > 128) _planetSpecularShaderCache.clear();
    if (_moonShaderCache.length > 128) _moonShaderCache.clear();
    if (_warpFilterCache.length > 64) _warpFilterCache.clear();
    if (_warpShaderCache.length > 64) _warpShaderCache.clear();
    if (_beaconRayFilterCache.length > 64) _beaconRayFilterCache.clear();
    if (_scanlineFilterCache.length > 64) _scanlineFilterCache.clear();
    if (_volumetricRayFilterCache.length > 64) _volumetricRayFilterCache.clear();
    if (_idPainterCache.length > 128) _idPainterCache.clear();
    if (_namePainterCache.length > 128) _namePainterCache.clear();
    if (_tagPainterCache.length > 128) _tagPainterCache.clear();
  }

  Offset _getWorldPosition(int index) {
    final count = worlds.length;
    final baseAngle = (index / count) * math.pi * 2 - math.pi / 2;
    final orbitRadius = radius * (0.75 + (index % 2) * 0.2);

    return Offset(
      center.dx + orbitRadius * math.cos(baseAngle),
      center.dy + orbitRadius * math.sin(baseAngle),
    );
  }

  void _drawDeepSpaceBackground(Canvas canvas, Size size) {
    // Multi-layer nebula gradient
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    _ensureDeepSpaceShaders(size);

    // Base dark gradient
    _bgBasePaint.shader = _bgBaseShader;
    canvas.drawRect(rect, _bgBasePaint);

    // Purple nebula cloud
    _nebulaPaint1.shader = _nebulaShader1;
    canvas.drawRect(rect, _nebulaPaint1);

    // Cyan nebula cloud
    _nebulaPaint2.shader = _nebulaShader2;
    canvas.drawRect(rect, _nebulaPaint2);

    // Orange/pink nebula accent
    _nebulaPaint3.shader = _nebulaShader3;
    canvas.drawRect(rect, _nebulaPaint3);
  }

  void _ensureDeepSpaceShaders(Size size) {
    const levels = 32;
    final level = (materializeValue * levels).round().clamp(0, levels);
    if (_deepSpaceShaderSize == size && _deepSpaceShaderLevel == level) {
      return;
    }

    _deepSpaceShaderSize = size;
    _deepSpaceShaderLevel = level;
    final t = level / levels;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    _bgBaseShader = const RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Color(0xFF0a0a15),
        Color(0xFF050510),
        Colors.black,
      ],
    ).createShader(rect);

    _nebulaShader1 = RadialGradient(
      center: const Alignment(-0.3, -0.4),
      radius: 0.8,
      colors: [
        NeonColors.purple.withOpacity(0.12 * t),
        NeonColors.purple.withOpacity(0.05 * t),
        Colors.transparent,
      ],
    ).createShader(rect);

    _nebulaShader2 = RadialGradient(
      center: const Alignment(0.4, 0.3),
      radius: 0.7,
      colors: [
        NeonColors.cyan.withOpacity(0.08 * t),
        NeonColors.blue.withOpacity(0.04 * t),
        Colors.transparent,
      ],
    ).createShader(rect);

    _nebulaShader3 = RadialGradient(
      center: const Alignment(0.5, -0.5),
      radius: 0.5,
      colors: [
        NeonColors.orange.withOpacity(0.06 * t),
        NeonColors.magenta.withOpacity(0.03 * t),
        Colors.transparent,
      ],
    ).createShader(rect);
  }

  void _drawStarField(Canvas canvas, Size size) {
    if (materializeValue < 0.1) return;
    final starFade = ((materializeValue - 0.1) / 0.3).clamp(0.0, 1.0);

    for (final star in stars) {
      final twinkle = 0.5 + 0.5 * math.sin(mainAnimation * math.pi * 2 * star.twinkleSpeed + star.twinklePhase);
      final alpha = star.brightness * twinkle * starFade;

      // Star glow
      _starGlowPaint
        ..color = star.color.withOpacity(alpha * 0.5)
        ..maskFilter = star.glowMask;

      final pos = Offset(star.x * size.width, star.y * size.height);
      canvas.drawCircle(pos, star.size * 1.5, _starGlowPaint);

      // Star core
      _starCorePaint.color = star.color.withOpacity(alpha);
      canvas.drawCircle(pos, star.size * 0.5, _starCorePaint);

      // Bright center for larger stars
      if (star.size > 1.5) {
        _starBrightPaint.color = Colors.white.withOpacity(alpha * 0.8);
        canvas.drawCircle(pos, star.size * 0.2, _starBrightPaint);
      }
    }
  }

  void _drawConstellations(Canvas canvas, Size size) {
    if (materializeValue < 0.3) return;
    final constFade = ((materializeValue - 0.3) / 0.3).clamp(0.0, 1.0);

    for (final constellation in constellations) {
      if (constellation.points.length < 2) continue;

      _constellationLinePaint.color =
          constellation.color.withOpacity(constellation.opacity * constFade);
      final path = _constellationPath..reset();
      for (int i = 0; i < constellation.points.length; i++) {
        final p = constellation.points[i];
        final pos = Offset(p.dx * size.width, p.dy * size.height);
        if (i == 0) {
          path.moveTo(pos.dx, pos.dy);
        } else {
          path.lineTo(pos.dx, pos.dy);
        }
      }
      canvas.drawPath(path, _constellationLinePaint);

      // Small dots at constellation points
      _constellationDotPaint.color =
          constellation.color.withOpacity(constellation.opacity * 2 * constFade);
      for (final p in constellation.points) {
        canvas.drawCircle(
          Offset(p.dx * size.width, p.dy * size.height),
          1.5,
          _constellationDotPaint,
        );
      }
    }
  }

  void _drawWarpLines(Canvas canvas, Size size) {
    if (materializeValue < 0.4) return;
    final warpFade = ((materializeValue - 0.4) / 0.3).clamp(0.0, 1.0);

    for (final line in warpLines) {
      final startR = line.startRadius + line.progress * 0.4;
      final endR = startR + line.length;

      final startPos = Offset(
        center.dx + startR * size.width * math.cos(line.angle),
        center.dy + startR * size.height * math.sin(line.angle),
      );
      final endPos = Offset(
        center.dx + endR * size.width * math.cos(line.angle),
        center.dy + endR * size.height * math.sin(line.angle),
      );

      // Fade based on progress
      final lineFade = math.sin(line.progress * math.pi);

      final dx = endPos.dx - startPos.dx;
      final dy = endPos.dy - startPos.dy;
      final length = math.sqrt(dx * dx + dy * dy);
      if (length <= 0.01) continue;

      final intensity = (warpFade * lineFade).clamp(0.0, 1.0);
      final level = (intensity * _warpIntensityLevels).round().clamp(0, _warpIntensityLevels);
      final filterKey = (line.color.value << 6) ^ level;
      _warpLinePaint.colorFilter = _warpFilterCache.putIfAbsent(
        filterKey,
        () => ColorFilter.mode(
          line.color.withOpacity(level / _warpIntensityLevels),
          BlendMode.modulate,
        ),
      );

      final lenKey = (length * 4).round();
      final shader = _warpShaderCache.putIfAbsent(
        lenKey,
        () => const LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white70,
            Colors.white,
          ],
          stops: [0.0, 0.7, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, lenKey / 4.0, 1)),
      );
      _warpLinePaint.shader = shader;

      canvas.save();
      canvas.translate(startPos.dx, startPos.dy);
      canvas.rotate(math.atan2(dy, dx));
      canvas.drawLine(Offset.zero, Offset(length, 0), _warpLinePaint);
      canvas.restore();
    }
    _warpLinePaint.shader = null;
    _warpLinePaint.colorFilter = null;
  }

  void _drawBlackHole(Canvas canvas, Size size) {
    if (materializeValue < 0.2) return;
    final bhFade = ((materializeValue - 0.2) / 0.4).clamp(0.0, 1.0);
    final bhLevel = (bhFade * _bhFadeLevels).round().clamp(0, _bhFadeLevels);
    final pulse = 0.85 + 0.15 * pulseValue;

    // Event horizon (complete black)
    final eventHorizonRadius = 35.0 * pulse;
    _eventHorizonPaint.color = Colors.black;
    canvas.drawCircle(center, eventHorizonRadius, _eventHorizonPaint);

    // Photon sphere (bright ring at edge)
    _photonPaint.color = NeonColors.orange.withOpacity(0.8 * bhFade);
    canvas.drawCircle(center, eventHorizonRadius + 2, _photonPaint);

    // Accretion disk - multiple rings with rotation
    for (int i = 0; i < 5; i++) {
      final diskRadius = eventHorizonRadius + 15 + i * 12.0;
      final rotation = mainAnimation * math.pi * 2 * (1 - i * 0.15);
      final opacity = 0.5 - i * 0.08;

      // Draw elliptical disk (perspective)
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      canvas.scale(1.0, 0.3); // Flatten for perspective
      canvas.translate(-center.dx, -center.dy);

      // Disk gradient
      final radiusKey = (diskRadius * 2).round();
      final shaderKey = (i << 24) ^ (bhLevel << 16) ^ radiusKey;
      final shader = _diskShaderCache.putIfAbsent(
        shaderKey,
        () => SweepGradient(
          colors: [
            NeonColors.orange.withOpacity(opacity * (bhLevel / _bhFadeLevels)),
            NeonColors.yellow.withOpacity(opacity * 0.7 * (bhLevel / _bhFadeLevels)),
            NeonColors.orange.withOpacity(opacity * (bhLevel / _bhFadeLevels)),
            Colors.red.withOpacity(opacity * 0.5 * (bhLevel / _bhFadeLevels)),
            NeonColors.orange.withOpacity(opacity * (bhLevel / _bhFadeLevels)),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: diskRadius)),
      );
      _diskPaint
        ..shader = shader
        ..strokeWidth = 8 - i * 1.0;

      canvas.drawCircle(center, diskRadius, _diskPaint);
      canvas.restore();
    }

    // Inner glow
    final innerRadiusKey = (eventHorizonRadius * 2 * 2).round();
    final innerShaderKey = (bhLevel << 16) ^ innerRadiusKey;
    _innerGlowPaint.shader = _innerGlowShaderCache.putIfAbsent(
      innerShaderKey,
      () => RadialGradient(
        colors: [
          Colors.transparent,
          NeonColors.cyan.withOpacity(0.2 * (bhLevel / _bhFadeLevels)),
          NeonColors.purple.withOpacity(0.3 * (bhLevel / _bhFadeLevels)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: eventHorizonRadius * 2)),
    );
    canvas.drawCircle(center, eventHorizonRadius * 2, _innerGlowPaint);

    // Gravitational lensing effect (distortion rings)
    for (int i = 0; i < 3; i++) {
      final lensRadius = eventHorizonRadius * (1.3 + i * 0.4);
      _lensPaint.color =
          Colors.white.withOpacity(0.05 * bhFade * (1 - i * 0.25));
      canvas.drawCircle(center, lensRadius, _lensPaint);
    }

    // Central singularity text
    if (_symbolFadeLevel != bhLevel) {
      _symbolFadeLevel = bhLevel;
      _symbolPainter.text = TextSpan(
        text: '◉',
        style: TextStyle(
          fontSize: 14,
          color: NeonColors.cyan.withOpacity((bhLevel / _bhFadeLevels) * 0.9),
          shadows: [
            Shadow(
              color: NeonColors.cyan.withOpacity(0.8),
              blurRadius: 10,
            ),
          ],
        ),
      );
      _symbolPainter.layout();
    }
    _symbolPainter.paint(
      canvas,
      center - Offset(_symbolPainter.width / 2, _symbolPainter.height / 2),
    );
  }

  void _drawOrbitalPaths(Canvas canvas) {
    if (materializeValue < 0.5) return;
    final orbitFade = ((materializeValue - 0.5) / 0.3).clamp(0.0, 1.0);

    // Draw orbital paths for each world tier
    for (int i = 0; i < 2; i++) {
      final orbitR = radius * (i == 0 ? 0.75 : 0.95);

      // Check if any world on this orbit is hovered
      bool orbitHovered = false;
      if (hoveredWorld != null) {
        for (int w = 0; w < worlds.length; w++) {
          if (worlds[w].id == hoveredWorld && w % 2 == i) {
            orbitHovered = true;
            break;
          }
        }
      }

      final orbitIntensity = orbitHovered ? 0.4 : 0.15;
      final orbitWidth = orbitHovered ? 2.0 : 1.0;

      // Dashed orbit ring
      final segmentCount = 60;
      for (int seg = 0; seg < segmentCount; seg++) {
        if (seg % 3 == 0) continue; // Skip every 3rd segment for dashed effect

        final startAngle = (seg / segmentCount) * math.pi * 2;
        final sweepAngle = (1 / segmentCount) * math.pi * 2 * 0.8;

        _orbitPaint
          ..color = NeonColors.cyan.withOpacity(orbitIntensity * orbitFade * (1 - i * 0.3))
          ..strokeWidth = orbitWidth;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: orbitR),
          startAngle + mainAnimation * 0.2,
          sweepAngle,
          false,
          _orbitPaint,
        );
      }

      // Moving markers on orbit
      final markerCount = orbitHovered ? 5 : 3;
      for (int m = 0; m < markerCount; m++) {
        final markerAngle = mainAnimation * math.pi * 2 * 0.5 + m * math.pi * 2 / markerCount;
        final markerPos = Offset(
          center.dx + orbitR * math.cos(markerAngle),
          center.dy + orbitR * math.sin(markerAngle),
        );

        _markerPaint.color = NeonColors.cyan.withOpacity((orbitHovered ? 0.7 : 0.4) * orbitFade);
        canvas.drawCircle(markerPos, orbitHovered ? 3 : 2, _markerPaint);
      }
    }
  }

  void _drawEnergyNetwork(Canvas canvas) {
    if (materializeValue < 0.6) return;
    final netFade = ((materializeValue - 0.6) / 0.3).clamp(0.0, 1.0);

    // Connect worlds to center
    for (int i = 0; i < worlds.length; i++) {
      final pos = _getWorldPosition(i);
      final world = worlds[i];
      final isHovered = hoveredWorld == world.id;

      // Connection to black hole center
      final pulseOffset = math.sin(mainAnimation * math.pi * 6 + i * 0.8);
      final connectionOpacity = netFade * (0.2 + pulseOffset * 0.1) * (isHovered ? 2 : 1);

      // Energy beam with cached gradient
      final dx = pos.dx - center.dx;
      final dy = pos.dy - center.dy;
      final length = math.sqrt(dx * dx + dy * dy);
      if (length > 0.01) {
        final level = (connectionOpacity * _beamOpacityLevels)
            .round()
            .clamp(0, _beamOpacityLevels);
        final lenKey = (length * 4).round();
        final shaderKey =
            (world.accent.value << 8) ^ (level << 16) ^ lenKey ^ (i << 24);
        final shader = _beamShaderCache.putIfAbsent(
          shaderKey,
          () => LinearGradient(
            colors: [
              NeonColors.orange.withOpacity(0.8 * (level / _beamOpacityLevels)),
              world.accent.withOpacity(level / _beamOpacityLevels),
              world.accent.withOpacity(0.3 * (level / _beamOpacityLevels)),
            ],
          ).createShader(Rect.fromLTWH(0, 0, lenKey / 4.0, 1)),
        );
        _beamPaint
          ..shader = shader
          ..strokeWidth = isHovered ? 2 : 1;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(math.atan2(dy, dx));
        canvas.drawLine(Offset.zero, Offset(length, 0), _beamPaint);
        canvas.restore();
        _beamPaint.shader = null;
      }

      // Traveling energy pulse
      final pulseT = (mainAnimation * 2 + i * 0.2) % 1.0;
      final pulsePos = Offset.lerp(center, pos, pulseT)!;

      _pulsePaint.color =
          Colors.white.withOpacity(connectionOpacity * 0.9);
      canvas.drawCircle(pulsePos, isHovered ? 4 : 2, _pulsePaint);

      // Connect to adjacent worlds
      final nextI = (i + 1) % worlds.length;
      final nextPos = _getWorldPosition(nextI);

      _linkPaint.color = world.accent.withOpacity(netFade * 0.15);
      canvas.drawLine(pos, nextPos, _linkPaint);
    }
  }

  void _drawFloatingParticles(Canvas canvas, Size size) {
    for (final particle in particles) {
      final pos = Offset(particle.x * size.width, particle.y * size.height);

      // Glow
      _floatGlowPaint
        ..color =
            particle.color.withOpacity(particle.alpha * 0.5 * materializeValue)
        ..maskFilter = particle.glowMask;
      canvas.drawCircle(pos, particle.size * 1.5, _floatGlowPaint);

      // Core
      _floatCorePaint.color =
          particle.color.withOpacity(particle.alpha * 0.8 * materializeValue);
      canvas.drawCircle(pos, particle.size * 0.6, _floatCorePaint);
    }
  }

  void _drawPlanetNode(Canvas canvas, Offset pos, WorldInfo world, int index, bool isHovered, Size size) {
    if (materializeValue < 0.65) return;
    final nodeFade = ((materializeValue - 0.65 - index * 0.02) / 0.25).clamp(0.0, 1.0);
    if (nodeFade <= 0) return;

    // Get entrance animation progress for this planet
    final entranceProgress = index < planetEntranceProgress.length ? planetEntranceProgress[index] : 1.0;
    if (entranceProgress <= 0) return;

    // Apply entrance easing (elastic ease-out for bounce effect)
    final easedEntrance = _elasticOut(entranceProgress);

    // Calculate entrance position (fly in from outer space)
    final entranceAngle = (index / worlds.length) * math.pi * 2 - math.pi / 2;
    final entranceDistance = radius * 3.0 * (1 - easedEntrance);
    final entranceOffset = Offset(
      math.cos(entranceAngle) * entranceDistance,
      math.sin(entranceAngle) * entranceDistance,
    );
    final animatedPos = pos + entranceOffset;

    final isSelected = selectedWorld == world.id;
    final baseRadius = 35.0;
    final hoverScale = isHovered ? 1.12 : 1.0;
    final selectionScale = isSelected ? (1.0 + selectionProgress * 0.3) : 1.0;
    final exitScale = exitProgress > 0 ? (1.0 + exitProgress * 2.0) : 1.0;

    final planetRadius = baseRadius * hoverScale * selectionScale * exitScale;
    final pulse = 0.9 + 0.1 * math.sin(mainAnimation * math.pi * 4 + index);

    // Exit animation: fade and fly away
    final exitOpacity = exitProgress > 0 ? (1.0 - exitProgress) : 1.0;
    final exitAngle = (index / worlds.length) * math.pi * 2 + exitProgress * math.pi * 4;
    final exitDistance = radius * 4.0 * exitProgress * exitProgress;
    final exitOffset = Offset(
      math.cos(exitAngle) * exitDistance,
      math.sin(exitAngle) * exitDistance,
    );
    final finalPos = animatedPos + exitOffset;

    canvas.save();
    canvas.translate(finalPos.dx, finalPos.dy);
    canvas.scale(pulse * easedEntrance);
    canvas.translate(-finalPos.dx, -finalPos.dy);

    // Selection pulse rings
    if (isSelected && selectionProgress > 0) {
      for (int i = 0; i < 3; i++) {
        final ringProgress = (selectionProgress * 2 - i * 0.3).clamp(0.0, 1.0);
        final ringRadius = planetRadius * (1.0 + ringProgress * 2.5);
        final ringOpacity = (1.0 - ringProgress) * 0.6;

        _planetAuraPaint
          ..shader = null
          ..color = world.accent.withOpacity(ringOpacity * exitOpacity);
        canvas.drawCircle(finalPos, ringRadius, _planetAuraPaint);
      }
    }

    // Outer energy aura
    final auraRadius = planetRadius * 2.2;
    final nodeLevel = (nodeFade * _planetFadeLevels).round().clamp(0, _planetFadeLevels);
    final auraLevel = isHovered ? _planetFadeLevels : nodeLevel;
    final auraOpacity = isSelected ? 0.8 : (isHovered ? 0.5 : 0.25);
    final auraKey = (world.accent.value << 8) ^
        (auraLevel << 16) ^
        (isHovered ? 1 : 0) ^
        (isSelected ? 2 : 0) ^
        (auraRadius * 2).round();
    _planetAuraPaint.shader = _planetAuraShaderCache.putIfAbsent(
      auraKey,
      () => RadialGradient(
        colors: [
          world.accent.withOpacity(auraOpacity * (auraLevel / _planetFadeLevels)),
          world.accent.withOpacity(auraOpacity * 0.4 * (auraLevel / _planetFadeLevels)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: auraRadius)),
    );
    canvas.save();
    canvas.translate(finalPos.dx, finalPos.dy);
    canvas.drawCircle(Offset.zero, auraRadius, _planetAuraPaint);
    canvas.restore();

    // Planet ring (Saturn-style) for some worlds
    if (index % 2 == 0) {
      _drawPlanetRing(canvas, finalPos, planetRadius * 1.6, world.accent, nodeFade * exitOpacity, isHovered);
    }

    // Planet body with gradient
    final bodyKey = (world.accent.value << 8) ^ (nodeLevel << 16) ^ (planetRadius * 2).round();
    _planetBodyPaint.shader = _planetBodyShaderCache.putIfAbsent(
      bodyKey,
      () => RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          world.accent.withOpacity(0.9 * (nodeLevel / _planetFadeLevels) * exitOpacity),
          world.accent.withOpacity(0.5 * (nodeLevel / _planetFadeLevels) * exitOpacity),
          Colors.black.withOpacity(0.8 * (nodeLevel / _planetFadeLevels) * exitOpacity),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: planetRadius)),
    );
    canvas.save();
    canvas.translate(finalPos.dx, finalPos.dy);
    canvas.drawCircle(Offset.zero, planetRadius, _planetBodyPaint);
    canvas.restore();

    // Planet surface detail (bands)
    for (int band = 0; band < 3; band++) {
      final bandY = finalPos.dy - planetRadius * 0.5 + band * planetRadius * 0.5;
      _planetBandPaint.color = world.accent.withOpacity(0.3 * nodeFade * exitOpacity);

      // Curved band
      final bandPath = _bandPath..reset();
      bandPath.moveTo(finalPos.dx - planetRadius * 0.8, bandY);
      bandPath.quadraticBezierTo(
        finalPos.dx, bandY + 5,
        finalPos.dx + planetRadius * 0.8, bandY,
      );
      canvas.drawPath(bandPath, _planetBandPaint);
    }

    // Atmosphere glow
    _planetAtmoPaint.color = world.accent.withOpacity(0.4 * nodeFade * exitOpacity);
    canvas.drawCircle(finalPos, planetRadius, _planetAtmoPaint);

    // Specular highlight
    final specKey = (nodeLevel << 16) ^ (planetRadius * 2).round();
    _planetSpecularPaint.shader = _planetSpecularShaderCache.putIfAbsent(
      specKey,
      () => RadialGradient(
        center: const Alignment(-0.5, -0.5),
        radius: 0.5,
        colors: [
          Colors.white.withOpacity(0.5 * (nodeLevel / _planetFadeLevels) * exitOpacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: planetRadius)),
    );
    canvas.save();
    canvas.translate(finalPos.dx, finalPos.dy);
    canvas.drawCircle(Offset.zero, planetRadius * 0.5, _planetSpecularPaint);
    canvas.restore();

    // Small moon for some worlds
    if (index % 3 == 0) {
      _drawMoon(canvas, finalPos, planetRadius, mainAnimation, world.accent, nodeFade * exitOpacity);
    }

    // World identifier
    final idLevel = (nodeFade * _planetFadeLevels).round().clamp(0, _planetFadeLevels);
    final idSize = isSelected ? 18.0 : (isHovered ? 16.0 : 13.0);
    final idKey = (world.id << 16) ^ (idLevel << 1) ^ (isHovered ? 1 : 0) ^ (isSelected ? 2 : 0);
    final idPainter = _idPainterCache.putIfAbsent(
      idKey,
      () {
        final painter = TextPainter(textDirection: TextDirection.ltr);
        painter.text = TextSpan(
          text: 'W${world.id}',
          style: TextStyle(
            fontSize: idSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white.withOpacity((idLevel / _planetFadeLevels) * exitOpacity),
            shadows: [
              Shadow(color: world.accent.withOpacity(0.9 * exitOpacity), blurRadius: 10),
              Shadow(color: world.accent.withOpacity(0.5 * exitOpacity), blurRadius: 20),
            ],
          ),
        );
        painter.layout();
        return painter;
      },
    );
    idPainter.paint(
      canvas,
      finalPos - Offset(idPainter.width / 2, idPainter.height / 2),
    );

    // Holographic info panel when hovered
    if (isHovered && exitProgress == 0) {
      _drawHolographicPanel(canvas, finalPos, planetRadius, world, nodeFade);
      _drawTargetingBrackets(canvas, finalPos, planetRadius * 1.5, world.accent, nodeFade);
      _drawOrbitingParticles(canvas, finalPos, planetRadius * 1.4, world.accent, nodeFade);
    }

    // Pulsar beacon
    _drawPulsarBeacon(canvas, finalPos, planetRadius, world.accent, nodeFade * exitOpacity, index);

    // Entrance trail effect
    if (entranceProgress < 1.0) {
      _drawEntranceTrail(canvas, finalPos, pos, world.accent, 1.0 - entranceProgress);
    }

    canvas.restore();
  }

  // Elastic ease-out function for bouncy entrance
  double _elasticOut(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    const p = 0.3;
    return math.pow(2, -10 * t) * math.sin((t - p / 4) * (2 * math.pi) / p) + 1;
  }

  void _drawEntranceTrail(Canvas canvas, Offset start, Offset end, Color color, double intensity) {
    if (intensity <= 0) return;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.6 * intensity),
          color.withOpacity(0.3 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromPoints(start, end))
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawLine(start, end, paint);

    // Trail particles
    for (int i = 0; i < 5; i++) {
      final t = i / 5.0;
      final particlePos = Offset.lerp(start, end, t)!;
      final particleSize = 2.0 * (1.0 - t) * intensity;

      final particlePaint = Paint()
        ..color = color.withOpacity((1.0 - t) * 0.8 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(particlePos, particleSize, particlePaint);
    }
  }

  void _drawPlanetRing(Canvas canvas, Offset center, double radius, Color color, double opacity, bool isHovered) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.0, 0.25); // Flatten for ring perspective
    canvas.translate(-center.dx, -center.dy);

    // Ring gradient
    for (int r = 0; r < 3; r++) {
      final ringR = radius * (0.9 + r * 0.1);
      _planetRingPaint
        ..color = color.withOpacity((0.4 - r * 0.1) * opacity * (isHovered ? 1.5 : 1))
        ..strokeWidth = (3 - r).toDouble();
      canvas.drawCircle(center, ringR, _planetRingPaint);
    }

    canvas.restore();
  }

  void _drawMoon(Canvas canvas, Offset planetPos, double planetRadius, double animation, Color color, double opacity) {
    final moonAngle = animation * math.pi * 4;
    final moonDistance = planetRadius * 1.6;
    final moonPos = Offset(
      planetPos.dx + moonDistance * math.cos(moonAngle),
      planetPos.dy + moonDistance * 0.4 * math.sin(moonAngle), // Elliptical orbit
    );

    // Moon glow
    _moonGlowPaint.color = color.withOpacity(0.3 * opacity);
    canvas.drawCircle(moonPos, 8, _moonGlowPaint);

    // Moon body
    final moonLevel = (opacity * _planetFadeLevels).round().clamp(0, _planetFadeLevels);
    final moonKey = (color.value << 8) ^ (moonLevel << 16);
    _moonPaint.shader = _moonShaderCache.putIfAbsent(
      moonKey,
      () => RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Colors.white.withOpacity(0.8 * (moonLevel / _planetFadeLevels)),
          color.withOpacity(0.4 * (moonLevel / _planetFadeLevels)),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 5)),
    );
    canvas.save();
    canvas.translate(moonPos.dx, moonPos.dy);
    canvas.drawCircle(Offset.zero, 5, _moonPaint);
    canvas.restore();
  }

  void _drawHolographicPanel(Canvas canvas, Offset pos, double radius, WorldInfo world, double opacity) {
    if (opacity <= 0.01) return;
    final panelOffset = Offset(radius + 50, -30);
    final panelPos = pos + panelOffset;
    final panelWidth = 100.0;
    final panelHeight = 60.0;

    // Panel background
    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(panelPos.dx, panelPos.dy, panelWidth, panelHeight),
      const Radius.circular(4),
    );

    _panelBgPaint.color = Colors.black.withOpacity(0.7 * opacity);
    canvas.drawRRect(panelRect, _panelBgPaint);

    // Panel border
    _panelBorderPaint.color = world.accent.withOpacity(0.8 * opacity);
    canvas.drawRRect(panelRect, _panelBorderPaint);

    // Connection line to planet
    _panelLinePaint.color = world.accent.withOpacity(0.5 * opacity);
    canvas.drawLine(
      pos + Offset(radius, 0),
      panelPos + Offset(0, panelHeight / 2),
      _panelLinePaint,
    );

    // World name
    final nameLevel = (opacity * _planetFadeLevels).round().clamp(0, _planetFadeLevels);
    final nameKey = world.name.hashCode ^ (nameLevel << 1) ^ world.accent.value;
    final namePainter = _namePainterCache.putIfAbsent(
      nameKey,
      () {
        final painter = TextPainter(textDirection: TextDirection.ltr);
        painter.text = TextSpan(
          text: world.name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: world.accent.withOpacity(nameLevel / _planetFadeLevels),
            letterSpacing: 1,
          ),
        );
        painter.layout();
        return painter;
      },
    );
    namePainter.paint(canvas, panelPos + const Offset(8, 8));

    // Tagline
    final tagLevel = (opacity * _planetFadeLevels).round().clamp(0, _planetFadeLevels);
    final tagKey = world.tagline.hashCode ^ (tagLevel << 1);
    final tagPainter = _tagPainterCache.putIfAbsent(
      tagKey,
      () {
        final painter = TextPainter(textDirection: TextDirection.ltr);
        painter.text = TextSpan(
          text: world.tagline,
          style: TextStyle(
            fontSize: 8,
            color: Colors.white.withOpacity(0.7 * (tagLevel / _planetFadeLevels)),
          ),
        );
        painter.layout();
        return painter;
      },
    );
    tagPainter.paint(canvas, panelPos + const Offset(8, 24));

    // Status bar
    final statusWidth = panelWidth - 16;
    final statusHeight = 4.0;
    final statusRect = Rect.fromLTWH(
      panelPos.dx + 8,
      panelPos.dy + panelHeight - 14,
      statusWidth,
      statusHeight,
    );

    _statusBgPaint.color = Colors.white.withOpacity(0.2 * opacity);
    canvas.drawRect(statusRect, _statusBgPaint);

    final progress = 0.3 + (world.id / 10) * 0.7; // Fake progress based on world id
    final statusFillRect = Rect.fromLTWH(
      statusRect.left,
      statusRect.top,
      statusWidth * progress,
      statusHeight,
    );
    _statusFillPaint.color = world.accent.withOpacity(opacity);
    canvas.drawRect(statusFillRect, _statusFillPaint);
  }

  void _drawTargetingBrackets(Canvas canvas, Offset center, double radius, Color color, double opacity) {
    if (opacity <= 0.01) return;
    final bracketSize = 15.0;
    _targetBracketPaint.color = color.withOpacity(opacity);

    final tl = Offset(center.dx - radius, center.dy - radius);
    final tr = Offset(center.dx + radius, center.dy - radius);
    final bl = Offset(center.dx - radius, center.dy + radius);
    final br = Offset(center.dx + radius, center.dy + radius);

    canvas.drawLine(tl, tl + Offset(bracketSize, 0), _targetBracketPaint);
    canvas.drawLine(tl, tl + Offset(0, bracketSize), _targetBracketPaint);
    canvas.drawLine(tr, tr + Offset(-bracketSize, 0), _targetBracketPaint);
    canvas.drawLine(tr, tr + Offset(0, bracketSize), _targetBracketPaint);
    canvas.drawLine(bl, bl + Offset(bracketSize, 0), _targetBracketPaint);
    canvas.drawLine(bl, bl + Offset(0, -bracketSize), _targetBracketPaint);
    canvas.drawLine(br, br + Offset(-bracketSize, 0), _targetBracketPaint);
    canvas.drawLine(br, br + Offset(0, -bracketSize), _targetBracketPaint);

    // Corner dots
    _targetDotPaint.color = color.withOpacity(opacity);
    canvas.drawCircle(tl, 3, _targetDotPaint);
    canvas.drawCircle(tr, 3, _targetDotPaint);
    canvas.drawCircle(bl, 3, _targetDotPaint);
    canvas.drawCircle(br, 3, _targetDotPaint);
  }

  void _drawOrbitingParticles(Canvas canvas, Offset center, double radius, Color color, double opacity) {
    if (opacity <= 0.01) return;
    for (int i = 0; i < 8; i++) {
      final angle = mainAnimation * math.pi * 8 + (i / 8) * math.pi * 2;
      final particlePos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      _orbitParticlePaint.color = color.withOpacity(0.8 * opacity);
      canvas.drawCircle(particlePos, 3, _orbitParticlePaint);
    }
  }

  void _drawPulsarBeacon(Canvas canvas, Offset pos, double radius, Color color, double opacity, int index) {
    // Pulsing energy beacon above planet
    if (opacity <= 0.01) return;
    final beaconY = pos.dy - radius - 15;
    final pulsePhase = (mainAnimation * 4 + index * 0.3) % 1.0;
    final beaconAlpha = math.sin(pulsePhase * math.pi);

    if (beaconAlpha > 0.1) {
      _beaconPaint.color = color.withOpacity(beaconAlpha * 0.6 * opacity);
      canvas.drawCircle(
        Offset(pos.dx, beaconY),
        4 + beaconAlpha * 2,
        _beaconPaint,
      );

      // Beacon ray upward
      if (_beaconRayShader == null || _beaconRayShaderHeight != 20) {
        _beaconRayShaderHeight = 20;
        _beaconRayShader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.white,
            Colors.transparent,
          ],
        ).createShader(const Rect.fromLTWH(0, 0, 2, 20));
      }
      _beaconRayPaint.shader = _beaconRayShader;
      final intensity = (beaconAlpha * 0.4 * opacity).clamp(0.0, 1.0);
      final level = (intensity * _beaconRayIntensityLevels)
          .round()
          .clamp(0, _beaconRayIntensityLevels);
      final key = (color.value << 6) ^ level;
      _beaconRayPaint.colorFilter = _beaconRayFilterCache.putIfAbsent(
        key,
        () => ColorFilter.mode(
          color.withOpacity(level / _beaconRayIntensityLevels),
          BlendMode.modulate,
        ),
      );
      canvas.save();
      canvas.translate(pos.dx - 1, beaconY - 20);
      canvas.drawLine(
        const Offset(1, 20),
        const Offset(1, 0),
        _beaconRayPaint,
      );
      canvas.restore();
      _beaconRayPaint.colorFilter = null;
    }
  }

  void _drawScanLines(Canvas canvas, Size size) {
    if (materializeValue < 0.8) return;
    final scanFade = ((materializeValue - 0.8) / 0.2).clamp(0.0, 1.0);
    if (scanFade <= 0.01) return;

    // Horizontal scan lines
    final scanY = (mainAnimation * 2 % 1.0) * size.height;

    if (_scanlineShader == null || _scanlineShaderWidth != size.width) {
      _scanlineShaderWidth = size.width;
      _scanlineShader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white54,
          Colors.white,
          Colors.white54,
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, _scanlineShaderWidth, 4));
    }
    _scanlinePaint.shader = _scanlineShader;
    final scanIntensity = (0.3 * scanFade).clamp(0.0, 1.0);
    final scanLevel = (scanIntensity * _scanlineIntensityLevels)
        .round()
        .clamp(0, _scanlineIntensityLevels);
    final scanKey = (NeonColors.cyan.value << 6) ^ scanLevel;
    _scanlinePaint.colorFilter = _scanlineFilterCache.putIfAbsent(
      scanKey,
      () => ColorFilter.mode(
        NeonColors.cyan.withOpacity(scanLevel / _scanlineIntensityLevels),
        BlendMode.modulate,
      ),
    );
    canvas.save();
    canvas.translate(0, scanY - 2);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 4), _scanlinePaint);
    canvas.restore();
    _scanlinePaint.colorFilter = null;

    // Secondary scan line
    final scan2Y = ((mainAnimation * 2 + 0.5) % 1.0) * size.height;
    _scanlinePaint2.color = NeonColors.magenta.withOpacity(0.1 * scanFade);
    canvas.drawRect(
      Rect.fromLTWH(0, scan2Y - 1, size.width, 2),
      _scanlinePaint2,
    );
  }

  void _drawVolumetricRays(Canvas canvas, Size size) {
    if (materializeValue < 0.7) return;
    final rayFade = ((materializeValue - 0.7) / 0.3).clamp(0.0, 1.0);
    if (rayFade <= 0.01) return;
    final rayLength = size.width * 0.7;
    if (_volumetricRayShader == null || _volumetricRayShaderSize != size) {
      _volumetricRayShaderSize = size;
      _volumetricRayShader = const RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          Colors.white,
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: rayLength));
    }
    _volumetricRayPaint.shader = _volumetricRayShader;
    final rayIntensity = (0.03 * rayFade).clamp(0.0, 1.0);
    final rayLevel = (rayIntensity * _volumetricRayIntensityLevels)
        .round()
        .clamp(0, _volumetricRayIntensityLevels);
    final rayKey = (NeonColors.cyan.value << 6) ^ rayLevel;
    _volumetricRayPaint.colorFilter = _volumetricRayFilterCache.putIfAbsent(
      rayKey,
      () => ColorFilter.mode(
        NeonColors.cyan.withOpacity(rayLevel / _volumetricRayIntensityLevels),
        BlendMode.modulate,
      ),
    );

    // Light rays from center
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 + mainAnimation * 0.3;

      final endPos = Offset(
        center.dx + rayLength * math.cos(angle),
        center.dy + rayLength * math.sin(angle),
      );

      final rayPath = _volumetricRayPath..reset();
      rayPath.moveTo(center.dx, center.dy);

      // Cone shape
      final perpAngle = angle + math.pi / 2;
      final spreadStart = 5.0;
      final spreadEnd = 30.0;

      rayPath.lineTo(
        endPos.dx + spreadEnd * math.cos(perpAngle),
        endPos.dy + spreadEnd * math.sin(perpAngle),
      );
      rayPath.lineTo(
        endPos.dx - spreadEnd * math.cos(perpAngle),
        endPos.dy - spreadEnd * math.sin(perpAngle),
      );
      rayPath.close();

      canvas.drawPath(rayPath, _volumetricRayPaint);
    }
    _volumetricRayPaint.colorFilter = null;
  }

  void _drawGlitchEffect(Canvas canvas, Size size) {
    if (glitchIntensity <= 0.01) return;
    if (size.width <= 0 || size.height <= 0) return;
    int state = ((mainAnimation * 1000000).toInt() ^
            (glitchIntensity * 10000).toInt()) &
        0x7fffffff;

    _glitchRedPaint.color = Colors.red.withOpacity(0.1 * glitchIntensity);
    _glitchCyanPaint.color = NeonColors.cyan.withOpacity(0.1 * glitchIntensity);

    // Random horizontal slice displacement
    for (int i = 0; i < 5; i++) {
      state = _lcgNext(state);
      final sliceY = _lcgUnit(state) * size.height;
      state = _lcgNext(state);
      final sliceHeight = 2 + _lcgUnit(state) * 8;
      state = _lcgNext(state);
      final offsetX = (_lcgUnit(state) - 0.5) * 20 * glitchIntensity;

      // RGB split
      final redRect = Rect.fromLTWH(-offsetX, sliceY, size.width, sliceHeight);
      final cyanRect = Rect.fromLTWH(offsetX, sliceY, size.width, sliceHeight);

      canvas.drawRect(redRect, _glitchRedPaint);
      canvas.drawRect(cyanRect, _glitchCyanPaint);
    }

    // Static noise
    for (int i = 0; i < 50; i++) {
      state = _lcgNext(state);
      final x = _lcgUnit(state) * size.width;
      state = _lcgNext(state);
      final y = _lcgUnit(state) * size.height;
      state = _lcgNext(state);
      final noiseSize = 1 + _lcgUnit(state) * 3;
      state = _lcgNext(state);
      final noiseAlpha = _lcgUnit(state) * 0.3 * glitchIntensity;
      if (noiseAlpha <= 0.01) continue;

      _glitchNoisePaint.color = Colors.white.withOpacity(noiseAlpha);
      canvas.drawRect(
        Rect.fromLTWH(x, y, noiseSize, noiseSize),
        _glitchNoisePaint,
      );
    }
  }

  void _drawVignette(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (_vignetteShader == null || _vignetteShaderSize != size) {
      _vignetteShaderSize = size;
      _vignetteShader = const RadialGradient(
        colors: [
          Colors.transparent,
          Colors.transparent,
          Color(0x66000000),
          Color(0xCC000000),
        ],
        stops: [0.0, 0.5, 0.8, 1.0],
      ).createShader(rect);
    }
    _vignettePaint.shader = _vignetteShader;

    canvas.drawRect(rect, _vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
