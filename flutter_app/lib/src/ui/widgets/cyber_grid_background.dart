import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// Epic cyberpunk grid background with perspective, energy waves, particles, and glitch effects.
class CyberGridBackground extends StatefulWidget {
  const CyberGridBackground({
    super.key,
    this.child,
    this.backgroundColor = NeonColors.deepBlack,
    this.enableParticles = true,
    this.enableGlitch = true,
    this.enableDataStreams = true,
  });

  final Widget? child;
  final Color backgroundColor;
  final bool enableParticles;
  final bool enableGlitch;
  final bool enableDataStreams;

  @override
  State<CyberGridBackground> createState() => _CyberGridBackgroundState();
}

class _CyberGridBackgroundState extends State<CyberGridBackground>
    with TickerProviderStateMixin {
  late AnimationController _gridController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _glitchController;
  late AnimationController _dataStreamController;

  final List<_FloatingParticle> _particles = [];
  final List<_DataStream> _dataStreams = [];
  int _rngState = 0x6d2b79f5;
  Timer? _glitchTimer;

  double _glitchIntensity = 0.0;
  double _glitchOffsetX = 0.0;
  double _glitchOffsetY = 0.0;
  bool _isGlitching = false;

  @override
  void initState() {
    super.initState();
    _rngState = 0x6d2b79f5 ^ DateTime.now().millisecondsSinceEpoch;

    _gridController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _dataStreamController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Initialize particles
    _initParticles();
    _initDataStreams();

    // Random glitch trigger
    _scheduleNextGlitch();

    _particleController.addListener(_updateParticles);
  }

  void _initParticles() {
    _particles.clear();
    for (int i = 0; i < 50; i++) {
      _particles.add(_FloatingParticle(
        x: _nextUnit(),
        y: _nextUnit(),
        size: 1 + _nextUnit() * 3,
        speed: 0.0005 + _nextUnit() * 0.002,
        opacity: 0.2 + _nextUnit() * 0.5,
        color: _nextBool() ? NeonColors.cyan : NeonColors.magenta,
        phase: _nextUnit() * math.pi * 2,
      ));
    }
  }

  void _initDataStreams() {
    _dataStreams.clear();
    for (int i = 0; i < 8; i++) {
      _dataStreams.add(_DataStream(
        x: _nextUnit(),
        speed: 0.02 + _nextUnit() * 0.03,
        length: 0.1 + _nextUnit() * 0.2,
        color: [NeonColors.cyan, NeonColors.magenta, NeonColors.green, NeonColors.purple][i % 4],
        characters: List.generate(10 + _nextInt(15), (_) => _nextInt(2).toString()),
      ));
    }
  }

  void _updateParticles() {
    for (final p in _particles) {
      p.y -= p.speed;
      p.x += math.sin(_particleController.value * math.pi * 2 + p.phase) * 0.0005;
      if (p.y < -0.1) {
        p.y = 1.1;
        p.x = _nextUnit();
      }
    }
  }

  void _scheduleNextGlitch() {
    if (!mounted || !widget.enableGlitch) return;
    _glitchTimer?.cancel();
    _glitchTimer = Timer(
      Duration(milliseconds: 2000 + _nextInt(5000)),
      () {
        if (!mounted) return;
        _triggerGlitch();
        _scheduleNextGlitch();
      },
    );
  }

  void _triggerGlitch() {
    if (!widget.enableGlitch) return;
    setState(() {
      _isGlitching = true;
      _glitchIntensity = 0.5 + _nextUnit() * 0.5;
      _glitchOffsetX = (_nextUnit() - 0.5) * 10;
      _glitchOffsetY = (_nextUnit() - 0.5) * 5;
    });

    _glitchController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _isGlitching = false;
          _glitchIntensity = 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _glitchTimer?.cancel();
    _gridController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _glitchController.dispose();
    _dataStreamController.dispose();
    super.dispose();
  }

  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }

  double _nextUnit() => _lcgNext() / 0x7fffffff;

  int _nextInt(int max) => max <= 0 ? 0 : _lcgNext() % max;

  bool _nextBool() => (_lcgNext() & 1) == 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _gridController,
          _pulseController,
          _particleController,
          _dataStreamController,
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Main background painter
              CustomPaint(
                painter: _CyberGridPainter(
                  gridAnimation: _gridController.value,
                  pulseAnimation: _pulseController.value,
                  particleAnimation: _particleController.value,
                  dataStreamAnimation: _dataStreamController.value,
                  particles: widget.enableParticles ? _particles : [],
                  dataStreams: widget.enableDataStreams ? _dataStreams : [],
                  glitchIntensity: _glitchIntensity,
                  glitchOffsetX: _glitchOffsetX,
                  glitchOffsetY: _glitchOffsetY,
                  isGlitching: _isGlitching,
                ),
                size: Size.infinite,
              ),

              // Scanline overlay
              if (widget.enableGlitch)
                IgnorePointer(
                  child: CustomPaint(
                    painter: _ScanlinePainter(
                      animation: _gridController.value,
                      glitchIntensity: _glitchIntensity,
                    ),
                    size: Size.infinite,
                  ),
                ),

              // Child content with optional glitch transform
              if (widget.child != null)
                Transform.translate(
                  offset: _isGlitching
                      ? Offset(_glitchOffsetX * 0.5, _glitchOffsetY * 0.5)
                      : Offset.zero,
                  child: widget.child,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CyberGridPainter extends CustomPainter {
  _CyberGridPainter({
    required this.gridAnimation,
    required this.pulseAnimation,
    required this.particleAnimation,
    required this.dataStreamAnimation,
    required this.particles,
    required this.dataStreams,
    required this.glitchIntensity,
    required this.glitchOffsetX,
    required this.glitchOffsetY,
    required this.isGlitching,
  });

  final double gridAnimation;
  final double pulseAnimation;
  final double particleAnimation;
  final double dataStreamAnimation;
  final List<_FloatingParticle> particles;
  final List<_DataStream> dataStreams;
  final double glitchIntensity;
  final double glitchOffsetX;
  final double glitchOffsetY;
  final bool isGlitching;

  static const LinearGradient _spaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF050510),
      Color(0xFF0A0A1A),
      Color(0xFF050515),
      Color(0xFF030308),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static final Paint _spacePaint = Paint();
  static final Paint _starPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _gridLinePaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;
  static final Paint _gridGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _gridCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _gridCyanGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _wavePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _pulsePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _particleGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _particleCorePaint = Paint()..style = PaintingStyle.fill;
  static const int _streamCharCacheLimit = 96;
  static final Map<int, TextPainter> _streamCharCache = {};
  static final Paint _hexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Path _hexPath = Path();
  static final Paint _cornerGlowPaint = Paint()
    ..strokeWidth = 4
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _cornerAccentPaint = Paint()
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  static final Paint _cornerDotPaint = Paint();
  static final Paint _energyCoreOuterPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
  static final Paint _energyCoreInnerPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  static final Paint _glitchCyanPaint = Paint();
  static final Paint _glitchMagentaPaint = Paint();
  static final Paint _glitchRedSplitPaint = Paint();
  static final Paint _glitchCyanSplitPaint = Paint();
  static final Paint _vignettePaint = Paint();
  static Size? _spaceShaderSize;
  static Shader? _spaceShader;
  static Size? _vignetteShaderSize;
  static Shader? _vignetteShader;

  static final List<_DistantStar> _distantStars = _buildDistantStars();
  static final List<Offset> _hexUnitPoints = _buildHexUnitPoints();
  static Size? _gridCacheSize;
  static List<_LineSeg> _verticalLines = const [];
  static List<_LineSeg> _horizontalLines = const [];
  static Size? _hexCacheSize;
  static List<_HexCell> _hexCells = const [];

  static int _lcgNext(int state) => (state * 1664525 + 1013904223) & 0x7fffffff;
  static double _lcgUnit(int state) => state / 0x7fffffff;

  static List<_DistantStar> _buildDistantStars() {
    int state = 42;
    return List.generate(100, (i) {
      state = _lcgNext(state);
      final x = _lcgUnit(state);
      state = _lcgNext(state);
      final y = _lcgUnit(state) * 0.5;
      state = _lcgNext(state);
      final size = 0.5 + _lcgUnit(state) * 1.5;
      return _DistantStar(
        x: x,
        y: y,
        size: size,
      );
    });
  }

  static List<Offset> _buildHexUnitPoints() {
    final points = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      points.add(Offset(math.cos(angle), math.sin(angle)));
    }
    return points;
  }

  static void _ensureGridCache(Size size) {
    if (_gridCacheSize == size) return;
    _gridCacheSize = size;

    final horizonY = size.height * 0.38;
    final vanishingPointX = size.width / 2;

    const verticalLineCount = 40;
    final verticalLines = <_LineSeg>[];
    for (int i = -verticalLineCount ~/ 2; i <= verticalLineCount ~/ 2; i++) {
      final bottomX = vanishingPointX + i * (size.width / verticalLineCount) * 2.5;
      final alpha = (1 - (i.abs() / (verticalLineCount / 2))).clamp(0.0, 1.0);
      verticalLines.add(_LineSeg(
        Offset(vanishingPointX, horizonY),
        Offset(bottomX, size.height),
        alpha.toDouble(),
      ));
    }

    const horizontalLineCount = 25;
    final horizontalLines = <_LineSeg>[];
    for (int i = 0; i <= horizontalLineCount; i++) {
      final t = i / horizontalLineCount;
      final perspectiveT = math.pow(t, 1.8).toDouble();
      final y = horizonY + (size.height - horizonY) * perspectiveT;
      final alpha = t.clamp(0.05, 0.4);
      final leftX = vanishingPointX - (size.width / 2 + 300) * perspectiveT;
      final rightX = vanishingPointX + (size.width / 2 + 300) * perspectiveT;
      horizontalLines.add(_LineSeg(
        Offset(leftX, y),
        Offset(rightX, y),
        alpha.toDouble(),
      ));
    }

    _verticalLines = verticalLines;
    _horizontalLines = horizontalLines;
  }

  static void _ensureHexCache(Size size) {
    if (_hexCacheSize == size) return;
    _hexCacheSize = size;

    const hexSize = 50.0;
    final rows = (size.height / (hexSize * 1.5)).ceil() + 1;
    final cols = (size.width / (hexSize * 1.732)).ceil() + 1;
    final cells = <_HexCell>[];

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final xOffset = col * hexSize * 1.732;
        final yOffset = row * hexSize * 1.5 + (col.isOdd ? hexSize * 0.75 : 0);

        if (yOffset < size.height * 0.45) {
          final fadeAlpha = 1 - (yOffset / (size.height * 0.45));
          cells.add(_HexCell(Offset(xOffset, yOffset), fadeAlpha));
        }
      }
    }

    _hexCells = cells;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    // Layer 1: Deep space gradient
    _drawSpaceGradient(canvas, size);

    // Layer 2: Distant stars
    _drawDistantStars(canvas, size);

    // Layer 3: Main perspective grid
    _drawPerspectiveGrid(canvas, size);

    // Layer 4: Energy waves
    _drawEnergyWaves(canvas, size);

    // Layer 5: Floating particles
    _drawFloatingParticles(canvas, size);

    // Layer 6: Data streams (Matrix rain)
    _drawDataStreams(canvas, size);

    // Layer 7: Hexagon pattern
    _drawHexagonPattern(canvas, size);

    // Layer 8: Corner accents with glow
    _drawCornerAccents(canvas, size);

    // Layer 9: Central energy core
    _drawEnergyCoreEffect(canvas, size);

    // Layer 10: Glitch effect overlay
    if (isGlitching) {
      _drawGlitchEffect(canvas, size);
    }

    // Layer 11: Vignette
    _drawVignette(canvas, size);
  }

  void _drawSpaceGradient(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    if (_spaceShader == null || _spaceShaderSize != size) {
      _spaceShaderSize = size;
      _spaceShader = _spaceGradient.createShader(rect);
    }
    _spacePaint.shader = _spaceShader;
    canvas.drawRect(rect, _spacePaint);
  }

  void _drawDistantStars(Canvas canvas, Size size) {
    for (int i = 0; i < _distantStars.length; i++) {
      final star = _distantStars[i];
      final x = star.x * size.width;
      final y = star.y * size.height;
      final twinkle = (0.3 + 0.7 * math.sin(particleAnimation * math.pi * 2 + i))
          .clamp(0.0, 1.0)
          .toDouble();

      _starPaint.color = Colors.white.withOpacity(0.2 * twinkle);
      canvas.drawCircle(Offset(x, y), star.size, _starPaint);
    }
  }

  void _drawPerspectiveGrid(Canvas canvas, Size size) {
    _ensureGridCache(size);
    final horizonY = size.height * 0.38;
    final vanishingPointX = size.width / 2;

    // Vertical lines going to horizon
    for (final line in _verticalLines) {
      _gridLinePaint.color = NeonColors.cyan.withOpacity(line.alpha * 0.25);
      canvas.drawLine(line.start, line.end, _gridLinePaint);
    }

    // Horizontal lines with perspective
    for (final line in _horizontalLines) {
      _gridLinePaint.color = NeonColors.cyan.withOpacity(line.alpha);
      canvas.drawLine(line.start, line.end, _gridLinePaint);
    }

    // Animated flowing lines (faster, more dramatic)
    final flowOffset = gridAnimation * size.height * 0.5;
    for (int i = 0; i < 8; i++) {
      final baseT = (i / 8 + flowOffset / size.height) % 1.0;
      final perspectiveT = math.pow(baseT, 1.8);
      final y = horizonY + (size.height - horizonY) * perspectiveT;

      if (y > horizonY && y < size.height) {
        // Glow line
        _gridGlowPaint.color = NeonColors.magenta.withOpacity(0.7 * baseT);

        final leftX = vanishingPointX - (size.width / 2 + 300) * perspectiveT;
        final rightX = vanishingPointX + (size.width / 2 + 300) * perspectiveT;

        canvas.drawLine(Offset(leftX, y), Offset(rightX, y), _gridGlowPaint);

        // Core line
        _gridCorePaint.color = NeonColors.magenta.withOpacity(0.9 * baseT);
        canvas.drawLine(Offset(leftX, y), Offset(rightX, y), _gridCorePaint);
      }
    }

    // Additional cyan flowing lines (opposite direction feel)
    for (int i = 0; i < 4; i++) {
      final baseT = ((i / 4 + 0.5) + flowOffset / size.height * 0.7) % 1.0;
      final perspectiveT = math.pow(baseT, 1.8);
      final y = horizonY + (size.height - horizonY) * perspectiveT;

      if (y > horizonY && y < size.height) {
        _gridCyanGlowPaint.color = NeonColors.cyan.withOpacity(0.5 * baseT);

        final leftX = vanishingPointX - (size.width / 2 + 300) * perspectiveT;
        final rightX = vanishingPointX + (size.width / 2 + 300) * perspectiveT;

        canvas.drawLine(Offset(leftX, y), Offset(rightX, y), _gridCyanGlowPaint);
      }
    }
  }

  void _drawEnergyWaves(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.55;

    // Multiple wave rings
    for (int i = 0; i < 5; i++) {
      final waveProgress = (pulseAnimation + i * 0.2) % 1.0;
      final radius = waveProgress * size.width * 0.6;
      final alpha = (1 - waveProgress) * 0.25;

      if (alpha > 0.01) {
        _wavePaint.color = NeonColors.purple.withOpacity(alpha);
        canvas.drawCircle(Offset(centerX, centerY), radius, _wavePaint);
      }
    }

    // Inner energy pulses
    for (int i = 0; i < 3; i++) {
      final pulseProgress = (pulseAnimation * 2 + i * 0.33) % 1.0;
      final radius = 20 + pulseProgress * 60;
      final alpha = (1 - pulseProgress) * 0.4;

      if (alpha > 0.01) {
        _pulsePaint.color = NeonColors.cyan.withOpacity(alpha);
        canvas.drawCircle(Offset(centerX, centerY), radius, _pulsePaint);
      }
    }
  }

  void _drawFloatingParticles(Canvas canvas, Size size) {
    for (final p in particles) {
      final x = p.x * size.width;
      final y = p.y * size.height;

      // Particle glow
      _particleGlowPaint.color = p.color.withOpacity(p.opacity * 0.3);
      canvas.drawCircle(Offset(x, y), p.size * 2, _particleGlowPaint);

      // Particle core
      _particleCorePaint.color = p.color.withOpacity(p.opacity);
      canvas.drawCircle(Offset(x, y), p.size, _particleCorePaint);
    }
  }

  void _drawDataStreams(Canvas canvas, Size size) {
    var cacheExceeded = false;
    for (final stream in dataStreams) {
      final x = stream.x * size.width;
      final progress = (dataStreamAnimation * stream.speed * 10) % 1.5;

      for (int i = 0; i < stream.characters.length; i++) {
        final charProgress = (progress - i * 0.03).clamp(0.0, 1.0);
        if (charProgress <= 0) continue;

        final y = charProgress * size.height * 1.2 - size.height * 0.1;
        final alpha = (1 - (i / stream.characters.length)) * 0.6;

        if (y >= 0 && y <= size.height) {
          final textAlpha = alpha * charProgress;
          if (textAlpha > 0.05) {
            final alphaKey = (textAlpha * 32).round().clamp(0, 32);
            final rgb = stream.color.value & 0x00FFFFFF;
            final charCode = stream.characters[i].codeUnitAt(0) & 0xFF;
            final cacheKey = (alphaKey << 32) | (charCode << 24) | rgb;
            final painter = _streamCharCache.putIfAbsent(cacheKey, () {
              final tp = TextPainter(textDirection: TextDirection.ltr);
              tp.text = TextSpan(
                text: stream.characters[i],
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: stream.color.withOpacity(alphaKey / 32),
                  shadows: [
                    Shadow(
                      color: stream.color.withOpacity(alphaKey / 64),
                      blurRadius: 4,
                    ),
                  ],
                ),
              );
              tp.layout();
              return tp;
            });
            painter.paint(canvas, Offset(x, y));
            if (_streamCharCache.length > _streamCharCacheLimit) {
              cacheExceeded = true;
            }
          }
        }
      }
    }
    if (cacheExceeded) {
      for (final tp in _streamCharCache.values) {
        tp.dispose();
      }
      _streamCharCache.clear();
    }
  }

  void _drawHexagonPattern(Canvas canvas, Size size) {
    _ensureHexCache(size);
    const hexSize = 50.0;
    final radius = hexSize * 0.4;

    for (final cell in _hexCells) {
      _hexPaint.color = NeonColors.gridLine.withOpacity(0.1 * cell.fade);
      _drawHexagon(canvas, cell.center, radius, _hexPaint);
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = _hexPath..reset();
    for (int i = 0; i < _hexUnitPoints.length; i++) {
      final p = _hexUnitPoints[i];
      final x = center.dx + p.dx * radius;
      final y = center.dy + p.dy * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCornerAccents(Canvas canvas, Size size) {
    const length = 100.0;
    const offset = 25.0;

    // Glow layer
    _cornerGlowPaint.color = NeonColors.cyan.withOpacity(0.4);

    // Core layer
    _cornerAccentPaint.color = NeonColors.cyan.withOpacity(0.8);
    _cornerDotPaint.color = NeonColors.cyan.withOpacity(0.9);

    // Draw each corner with both layers
    void drawCorner(Offset p1H, Offset p2H, Offset p1V, Offset p2V) {
      canvas.drawLine(p1H, p2H, _cornerGlowPaint);
      canvas.drawLine(p1V, p2V, _cornerGlowPaint);
      canvas.drawLine(p1H, p2H, _cornerAccentPaint);
      canvas.drawLine(p1V, p2V, _cornerAccentPaint);

      // Add small dot at corner
      canvas.drawCircle(p1H, 3, _cornerDotPaint);
    }

    // Top-left
    drawCorner(
      const Offset(offset, offset),
      const Offset(offset + length, offset),
      const Offset(offset, offset),
      const Offset(offset, offset + length),
    );

    // Top-right
    drawCorner(
      Offset(size.width - offset, offset),
      Offset(size.width - offset - length, offset),
      Offset(size.width - offset, offset),
      Offset(size.width - offset, offset + length),
    );

    // Bottom-left
    drawCorner(
      Offset(offset, size.height - offset),
      Offset(offset + length, size.height - offset),
      Offset(offset, size.height - offset),
      Offset(offset, size.height - offset - length),
    );

    // Bottom-right
    drawCorner(
      Offset(size.width - offset, size.height - offset),
      Offset(size.width - offset - length, size.height - offset),
      Offset(size.width - offset, size.height - offset),
      Offset(size.width - offset, size.height - offset - length),
    );
  }

  void _drawEnergyCoreEffect(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.18;
    final pulse = 0.8 + 0.2 * math.sin(pulseAnimation * math.pi * 2);

    // Outer glow
    _energyCoreOuterPaint.color = NeonColors.cyan.withOpacity(0.1);
    canvas.drawCircle(
      Offset(centerX, centerY),
      80 * pulse,
      _energyCoreOuterPaint,
    );

    // Inner glow
    _energyCoreInnerPaint.color = NeonColors.magenta.withOpacity(0.15);
    canvas.drawCircle(
      Offset(centerX, centerY),
      40 * pulse,
      _energyCoreInnerPaint,
    );
  }

  void _drawGlitchEffect(Canvas canvas, Size size) {
    int state = ((gridAnimation * 1000000).toInt() ^
            (glitchIntensity * 10000).toInt() ^
            (glitchOffsetX * 1000).toInt() ^
            (glitchOffsetY * 1000).toInt()) &
        0x7fffffff;

    _glitchCyanPaint.color = NeonColors.cyan.withOpacity(0.3 * glitchIntensity);
    _glitchMagentaPaint.color =
        NeonColors.magenta.withOpacity(0.3 * glitchIntensity);

    // Horizontal glitch bars
    for (int i = 0; i < (glitchIntensity * 10).round(); i++) {
      state = _lcgNext(state);
      final y = _lcgUnit(state) * size.height;
      state = _lcgNext(state);
      final height = 2 + _lcgUnit(state) * 8;
      state = _lcgNext(state);
      final offsetX = (_lcgUnit(state) - 0.5) * 20 * glitchIntensity;

      // Cyan glitch
      canvas.drawRect(
        Rect.fromLTWH(offsetX, y, size.width, height),
        _glitchCyanPaint,
      );

      // Magenta glitch (offset)
      canvas.drawRect(
        Rect.fromLTWH(-offsetX, y + 2, size.width, height * 0.5),
        _glitchMagentaPaint,
      );
    }

    // RGB split effect on edges
    _glitchRedSplitPaint.color =
        const Color(0xFFFF0000).withOpacity(0.05 * glitchIntensity);
    _glitchCyanSplitPaint.color =
        const Color(0xFF00FFFF).withOpacity(0.05 * glitchIntensity);
    canvas.drawRect(
      Rect.fromLTWH(glitchOffsetX, 0, size.width * 0.3, size.height),
      _glitchRedSplitPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(-glitchOffsetX + size.width * 0.7, 0, size.width * 0.3, size.height),
      _glitchCyanSplitPaint,
    );
  }

  void _drawVignette(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    if (_vignetteShader == null || _vignetteShaderSize != size) {
      _vignetteShaderSize = size;
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.transparent,
          Colors.transparent,
          NeonColors.darkBg.withOpacity(0.4),
          NeonColors.darkBg.withOpacity(0.85),
        ],
        stops: const [0.0, 0.4, 0.75, 1.0],
      );
      _vignetteShader = gradient.createShader(rect);
    }
    _vignettePaint.shader = _vignetteShader;
    canvas.drawRect(rect, _vignettePaint);
  }

  @override
  bool shouldRepaint(_CyberGridPainter oldDelegate) => true;
}

class _ScanlinePainter extends CustomPainter {
  _ScanlinePainter({
    required this.animation,
    required this.glitchIntensity,
  });

  final double animation;
  final double glitchIntensity;

  static final Paint _scanlinePaint =
      Paint()..color = Colors.black.withOpacity(0.03);
  static final Paint _scanBeamPaint = Paint();
  static final Paint _flickerPaint = Paint();
  static double _scanBeamShaderWidth = 0;
  static Shader? _scanBeamShader;
  static final Path _scanlinePath = Path();
  static Size? _scanlineSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    // Subtle scanlines
    if (_scanlineSize != size) {
      _scanlineSize = size;
      _scanlinePath.reset();
      for (double y = 0; y < size.height; y += 3) {
        _scanlinePath
          ..moveTo(0, y)
          ..lineTo(size.width, y);
      }
    }
    canvas.drawPath(_scanlinePath, _scanlinePaint);

    // Moving scan beam
    final scanY = (animation * size.height * 1.5) % (size.height + 100) - 50;
    if (_scanBeamShader == null || _scanBeamShaderWidth != size.width) {
      _scanBeamShaderWidth = size.width;
      _scanBeamShader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Color(0x14FFFFFF),
          Color(0x26FFFFFF),
          Color(0x14FFFFFF),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, _scanBeamShaderWidth, 80));
    }
    _scanBeamPaint.shader = _scanBeamShader;
    _scanBeamPaint.colorFilter = const ColorFilter.mode(
      NeonColors.cyan,
      BlendMode.modulate,
    );
    canvas.save();
    canvas.translate(0, scanY);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 80),
      _scanBeamPaint,
    );
    canvas.restore();
    _scanBeamPaint.colorFilter = null;

    // CRT flicker effect
    if (glitchIntensity > 0.3) {
      _flickerPaint.color = Colors.white.withOpacity(0.02 * glitchIntensity);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        _flickerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.glitchIntensity != glitchIntensity;
}

class _DistantStar {
  _DistantStar({
    required this.x,
    required this.y,
    required this.size,
  });

  final double x;
  final double y;
  final double size;
}

class _LineSeg {
  _LineSeg(this.start, this.end, this.alpha);

  final Offset start;
  final Offset end;
  final double alpha;
}

class _HexCell {
  _HexCell(this.center, this.fade);

  final Offset center;
  final double fade;
}

class _FloatingParticle {
  _FloatingParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
    required this.phase,
  });

  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;
  final Color color;
  final double phase;
}

class _DataStream {
  _DataStream({
    required this.x,
    required this.speed,
    required this.length,
    required this.color,
    required this.characters,
  });

  final double x;
  final double speed;
  final double length;
  final Color color;
  final List<String> characters;
}
