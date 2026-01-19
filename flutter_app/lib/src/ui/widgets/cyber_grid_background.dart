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
  final math.Random _random = math.Random();

  double _glitchIntensity = 0.0;
  double _glitchOffsetX = 0.0;
  double _glitchOffsetY = 0.0;
  bool _isGlitching = false;

  @override
  void initState() {
    super.initState();

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
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 1 + _random.nextDouble() * 3,
        speed: 0.0005 + _random.nextDouble() * 0.002,
        opacity: 0.2 + _random.nextDouble() * 0.5,
        color: _random.nextBool() ? NeonColors.cyan : NeonColors.magenta,
        phase: _random.nextDouble() * math.pi * 2,
      ));
    }
  }

  void _initDataStreams() {
    _dataStreams.clear();
    for (int i = 0; i < 8; i++) {
      _dataStreams.add(_DataStream(
        x: _random.nextDouble(),
        speed: 0.02 + _random.nextDouble() * 0.03,
        length: 0.1 + _random.nextDouble() * 0.2,
        color: [NeonColors.cyan, NeonColors.magenta, NeonColors.green, NeonColors.purple][i % 4],
        characters: List.generate(10 + _random.nextInt(15), (_) => _random.nextInt(2).toString()),
      ));
    }
  }

  void _updateParticles() {
    for (final p in _particles) {
      p.y -= p.speed;
      p.x += math.sin(_particleController.value * math.pi * 2 + p.phase) * 0.0005;
      if (p.y < -0.1) {
        p.y = 1.1;
        p.x = _random.nextDouble();
      }
    }
  }

  void _scheduleNextGlitch() {
    if (!mounted) return;
    Future.delayed(Duration(milliseconds: 2000 + _random.nextInt(5000)), () {
      if (!mounted) return;
      _triggerGlitch();
      _scheduleNextGlitch();
    });
  }

  void _triggerGlitch() {
    if (!widget.enableGlitch) return;
    setState(() {
      _isGlitching = true;
      _glitchIntensity = 0.5 + _random.nextDouble() * 0.5;
      _glitchOffsetX = (_random.nextDouble() - 0.5) * 10;
      _glitchOffsetY = (_random.nextDouble() - 0.5) * 5;
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
    _gridController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _glitchController.dispose();
    _dataStreamController.dispose();
    super.dispose();
  }

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

  @override
  void paint(Canvas canvas, Size size) {
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
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF050510),
        const Color(0xFF0A0A1A),
        const Color(0xFF050515),
        const Color(0xFF030308),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  void _drawDistantStars(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42); // Fixed seed for consistent stars

    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.5;
      final twinkle = 0.3 + 0.7 * math.sin(particleAnimation * math.pi * 2 + i);
      final starSize = 0.5 + random.nextDouble() * 1.5;

      starPaint.color = Colors.white.withOpacity(0.2 * twinkle);
      canvas.drawCircle(Offset(x, y), starSize, starPaint);
    }
  }

  void _drawPerspectiveGrid(Canvas canvas, Size size) {
    final horizonY = size.height * 0.38;
    final vanishingPointX = size.width / 2;

    final linePaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Vertical lines going to horizon
    const verticalLineCount = 40;
    for (int i = -verticalLineCount ~/ 2; i <= verticalLineCount ~/ 2; i++) {
      final bottomX = vanishingPointX + i * (size.width / verticalLineCount) * 2.5;
      final alpha = (1 - (i.abs() / (verticalLineCount / 2))).clamp(0.0, 1.0);

      linePaint.color = NeonColors.cyan.withOpacity(alpha * 0.25);
      canvas.drawLine(
        Offset(vanishingPointX, horizonY),
        Offset(bottomX, size.height),
        linePaint,
      );
    }

    // Horizontal lines with perspective
    const horizontalLineCount = 25;
    for (int i = 0; i <= horizontalLineCount; i++) {
      final t = i / horizontalLineCount;
      final perspectiveT = math.pow(t, 1.8);
      final y = horizonY + (size.height - horizonY) * perspectiveT;
      final alpha = t.clamp(0.05, 0.4);

      linePaint.color = NeonColors.cyan.withOpacity(alpha);
      final leftX = vanishingPointX - (size.width / 2 + 300) * perspectiveT;
      final rightX = vanishingPointX + (size.width / 2 + 300) * perspectiveT;

      canvas.drawLine(Offset(leftX, y), Offset(rightX, y), linePaint);
    }

    // Animated flowing lines (faster, more dramatic)
    final flowOffset = gridAnimation * size.height * 0.5;
    for (int i = 0; i < 8; i++) {
      final baseT = (i / 8 + flowOffset / size.height) % 1.0;
      final perspectiveT = math.pow(baseT, 1.8);
      final y = horizonY + (size.height - horizonY) * perspectiveT;

      if (y > horizonY && y < size.height) {
        // Glow line
        final glowPaint = Paint()
          ..color = NeonColors.magenta.withOpacity(0.7 * baseT)
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        final leftX = vanishingPointX - (size.width / 2 + 300) * perspectiveT;
        final rightX = vanishingPointX + (size.width / 2 + 300) * perspectiveT;

        canvas.drawLine(Offset(leftX, y), Offset(rightX, y), glowPaint);

        // Core line
        final corePaint = Paint()
          ..color = NeonColors.magenta.withOpacity(0.9 * baseT)
          ..strokeWidth = 1;
        canvas.drawLine(Offset(leftX, y), Offset(rightX, y), corePaint);
      }
    }

    // Additional cyan flowing lines (opposite direction feel)
    for (int i = 0; i < 4; i++) {
      final baseT = ((i / 4 + 0.5) + flowOffset / size.height * 0.7) % 1.0;
      final perspectiveT = math.pow(baseT, 1.8);
      final y = horizonY + (size.height - horizonY) * perspectiveT;

      if (y > horizonY && y < size.height) {
        final glowPaint = Paint()
          ..color = NeonColors.cyan.withOpacity(0.5 * baseT)
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        final leftX = vanishingPointX - (size.width / 2 + 300) * perspectiveT;
        final rightX = vanishingPointX + (size.width / 2 + 300) * perspectiveT;

        canvas.drawLine(Offset(leftX, y), Offset(rightX, y), glowPaint);
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
        final wavePaint = Paint()
          ..color = NeonColors.purple.withOpacity(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        canvas.drawCircle(Offset(centerX, centerY), radius, wavePaint);
      }
    }

    // Inner energy pulses
    for (int i = 0; i < 3; i++) {
      final pulseProgress = (pulseAnimation * 2 + i * 0.33) % 1.0;
      final radius = 20 + pulseProgress * 60;
      final alpha = (1 - pulseProgress) * 0.4;

      if (alpha > 0.01) {
        final pulsePaint = Paint()
          ..color = NeonColors.cyan.withOpacity(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawCircle(Offset(centerX, centerY), radius, pulsePaint);
      }
    }
  }

  void _drawFloatingParticles(Canvas canvas, Size size) {
    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final x = p.x * size.width;
      final y = p.y * size.height;

      // Particle glow
      particlePaint
        ..color = p.color.withOpacity(p.opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), p.size * 2, particlePaint);

      // Particle core
      particlePaint
        ..color = p.color.withOpacity(p.opacity)
        ..maskFilter = null;
      canvas.drawCircle(Offset(x, y), p.size, particlePaint);
    }
  }

  void _drawDataStreams(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final stream in dataStreams) {
      final x = stream.x * size.width;
      final progress = (dataStreamAnimation * stream.speed * 10) % 1.5;

      for (int i = 0; i < stream.characters.length; i++) {
        final charProgress = (progress - i * 0.03).clamp(0.0, 1.0);
        if (charProgress <= 0) continue;

        final y = charProgress * size.height * 1.2 - size.height * 0.1;
        final alpha = (1 - (i / stream.characters.length)) * 0.6;

        if (y >= 0 && y <= size.height) {
          textPainter.text = TextSpan(
            text: stream.characters[i],
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: stream.color.withOpacity(alpha * charProgress),
              shadows: [
                Shadow(
                  color: stream.color.withOpacity(alpha * 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(x, y));
        }
      }
    }
  }

  void _drawHexagonPattern(Canvas canvas, Size size) {
    final hexPaint = Paint()
      ..color = NeonColors.gridLine.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const hexSize = 50.0;
    final rows = (size.height / (hexSize * 1.5)).ceil() + 1;
    final cols = (size.width / (hexSize * 1.732)).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final xOffset = col * hexSize * 1.732;
        final yOffset = row * hexSize * 1.5 + (col.isOdd ? hexSize * 0.75 : 0);

        // Only draw in upper portion with fade
        if (yOffset < size.height * 0.45) {
          final fadeAlpha = 1 - (yOffset / (size.height * 0.45));
          hexPaint.color = NeonColors.gridLine.withOpacity(0.1 * fadeAlpha);
          _drawHexagon(canvas, Offset(xOffset, yOffset), hexSize * 0.4, hexPaint);
        }
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
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
    final glowPaint = Paint()
      ..color = NeonColors.cyan.withOpacity(0.4)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Core layer
    final accentPaint = Paint()
      ..color = NeonColors.cyan.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw each corner with both layers
    void drawCorner(Offset p1H, Offset p2H, Offset p1V, Offset p2V) {
      canvas.drawLine(p1H, p2H, glowPaint);
      canvas.drawLine(p1V, p2V, glowPaint);
      canvas.drawLine(p1H, p2H, accentPaint);
      canvas.drawLine(p1V, p2V, accentPaint);

      // Add small dot at corner
      canvas.drawCircle(p1H, 3, Paint()..color = NeonColors.cyan.withOpacity(0.9));
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
    canvas.drawCircle(
      Offset(centerX, centerY),
      80 * pulse,
      Paint()
        ..color = NeonColors.cyan.withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );

    // Inner glow
    canvas.drawCircle(
      Offset(centerX, centerY),
      40 * pulse,
      Paint()
        ..color = NeonColors.magenta.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
  }

  void _drawGlitchEffect(Canvas canvas, Size size) {
    final random = math.Random();

    // Horizontal glitch bars
    for (int i = 0; i < (glitchIntensity * 10).round(); i++) {
      final y = random.nextDouble() * size.height;
      final height = 2 + random.nextDouble() * 8;
      final offsetX = (random.nextDouble() - 0.5) * 20 * glitchIntensity;

      // Cyan glitch
      canvas.drawRect(
        Rect.fromLTWH(offsetX, y, size.width, height),
        Paint()..color = NeonColors.cyan.withOpacity(0.3 * glitchIntensity),
      );

      // Magenta glitch (offset)
      canvas.drawRect(
        Rect.fromLTWH(-offsetX, y + 2, size.width, height * 0.5),
        Paint()..color = NeonColors.magenta.withOpacity(0.3 * glitchIntensity),
      );
    }

    // RGB split effect on edges
    canvas.drawRect(
      Rect.fromLTWH(glitchOffsetX, 0, size.width * 0.3, size.height),
      Paint()..color = const Color(0xFFFF0000).withOpacity(0.05 * glitchIntensity),
    );
    canvas.drawRect(
      Rect.fromLTWH(-glitchOffsetX + size.width * 0.7, 0, size.width * 0.3, size.height),
      Paint()..color = const Color(0xFF00FFFF).withOpacity(0.05 * glitchIntensity),
    );
  }

  void _drawVignette(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
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

    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
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

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle scanlines
    final scanPaint = Paint()
      ..color = Colors.black.withOpacity(0.03);

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanPaint);
    }

    // Moving scan beam
    final scanY = (animation * size.height * 1.5) % (size.height + 100) - 50;
    final scanGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        NeonColors.cyan.withOpacity(0.08),
        NeonColors.cyan.withOpacity(0.15),
        NeonColors.cyan.withOpacity(0.08),
        Colors.transparent,
      ],
    );

    canvas.drawRect(
      Rect.fromLTWH(0, scanY, size.width, 80),
      Paint()..shader = scanGradient.createShader(Rect.fromLTWH(0, scanY, size.width, 80)),
    );

    // CRT flicker effect
    if (glitchIntensity > 0.3) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white.withOpacity(0.02 * glitchIntensity),
      );
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.glitchIntensity != glitchIntensity;
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
