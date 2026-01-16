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

  int? _hoveredWorld;
  final List<_Star> _stars = [];
  final List<_WarpLine> _warpLines = [];
  final List<_EnergyParticle> _particles = [];
  final List<_Constellation> _constellations = [];
  final math.Random _random = math.Random();
  double _glitchIntensity = 0;

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

    // Initialize stars (distant background)
    for (int i = 0; i < 200; i++) {
      _stars.add(_Star.random(_random));
    }

    // Initialize warp lines
    for (int i = 0; i < 30; i++) {
      _warpLines.add(_WarpLine.random(_random));
    }

    // Initialize floating particles
    for (int i = 0; i < 80; i++) {
      _particles.add(_EnergyParticle.random(_random));
    }

    // Initialize constellations (connecting lines between stars)
    for (int i = 0; i < 15; i++) {
      _constellations.add(_Constellation.random(_random));
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _materializeController.dispose();
    _warpController.dispose();
    _glitchController.dispose();
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
            ]),
            builder: (context, child) {
              // Update animations
              _updateParticles();
              _updateWarpLines();

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
                    stars: _stars,
                    warpLines: _warpLines,
                    particles: _particles,
                    constellations: _constellations,
                    glitchIntensity: _glitchIntensity,
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
    for (int i = 0; i < widget.worlds.length; i++) {
      final nodePos = _getWorldPosition(i, center, radius);
      if ((tapPos - nodePos).distance < 55) {
        widget.onWorldSelected(widget.worlds[i].id);
        break;
      }
    }
  }
}

// ==================== DATA CLASSES ====================

class _Star {
  double x, y;
  double size;
  double twinklePhase;
  double twinkleSpeed;
  double brightness;
  Color color;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinklePhase,
    required this.twinkleSpeed,
    required this.brightness,
    required this.color,
  });

  factory _Star.random(math.Random r) {
    final colors = [Colors.white, Colors.white, NeonColors.cyan, NeonColors.blue];
    return _Star(
      x: r.nextDouble(),
      y: r.nextDouble(),
      size: 0.5 + r.nextDouble() * 2.5,
      twinklePhase: r.nextDouble() * math.pi * 2,
      twinkleSpeed: 0.5 + r.nextDouble() * 2,
      brightness: 0.3 + r.nextDouble() * 0.7,
      color: colors[r.nextInt(colors.length)],
    );
  }
}

class _WarpLine {
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

  factory _WarpLine.random(math.Random r) {
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
      angle = math.Random().nextDouble() * math.pi * 2;
    }
  }
}

class _EnergyParticle {
  double x, y;
  double vx, vy;
  double life;
  double maxLife;
  double size;
  Color color;
  double orbitAngle;
  double orbitRadius;
  bool isOrbiting;

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
  });

  factory _EnergyParticle.random(math.Random r) {
    final colors = [NeonColors.cyan, NeonColors.magenta, NeonColors.purple, NeonColors.orange];
    final isOrbit = r.nextDouble() > 0.7;
    return _EnergyParticle(
      x: r.nextDouble(),
      y: r.nextDouble(),
      vx: (r.nextDouble() - 0.5) * 0.015,
      vy: (r.nextDouble() - 0.5) * 0.015,
      life: r.nextDouble(),
      maxLife: 0.6 + r.nextDouble() * 0.4,
      size: 1 + r.nextDouble() * 3,
      color: colors[r.nextInt(colors.length)],
      orbitAngle: r.nextDouble() * math.pi * 2,
      orbitRadius: 0.3 + r.nextDouble() * 0.2,
      isOrbiting: isOrbit,
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
      final r = math.Random();
      x = r.nextDouble();
      y = r.nextDouble();
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

  factory _Constellation.random(math.Random r) {
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
  final List<_Star> stars;
  final List<_WarpLine> warpLines;
  final List<_EnergyParticle> particles;
  final List<_Constellation> constellations;
  final double glitchIntensity;

  _UltraEpicUniversePainter({
    required this.worlds,
    required this.mainAnimation,
    required this.pulseValue,
    required this.materializeValue,
    required this.warpValue,
    required this.center,
    required this.radius,
    required this.hoveredWorld,
    required this.stars,
    required this.warpLines,
    required this.particles,
    required this.constellations,
    required this.glitchIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

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

    // Base dark gradient
    final basePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [
          const Color(0xFF0a0a15),
          const Color(0xFF050510),
          Colors.black,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    // Purple nebula cloud
    final nebula1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.8,
        colors: [
          NeonColors.purple.withOpacity(0.12 * materializeValue),
          NeonColors.purple.withOpacity(0.05 * materializeValue),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, nebula1);

    // Cyan nebula cloud
    final nebula2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.4, 0.3),
        radius: 0.7,
        colors: [
          NeonColors.cyan.withOpacity(0.08 * materializeValue),
          NeonColors.blue.withOpacity(0.04 * materializeValue),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, nebula2);

    // Orange/pink nebula accent
    final nebula3 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.5, -0.5),
        radius: 0.5,
        colors: [
          NeonColors.orange.withOpacity(0.06 * materializeValue),
          NeonColors.magenta.withOpacity(0.03 * materializeValue),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, nebula3);
  }

  void _drawStarField(Canvas canvas, Size size) {
    if (materializeValue < 0.1) return;
    final starFade = ((materializeValue - 0.1) / 0.3).clamp(0.0, 1.0);

    for (final star in stars) {
      final twinkle = 0.5 + 0.5 * math.sin(mainAnimation * math.pi * 2 * star.twinkleSpeed + star.twinklePhase);
      final alpha = star.brightness * twinkle * starFade;

      // Star glow
      final glowPaint = Paint()
        ..color = star.color.withOpacity(alpha * 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.size * 2);

      final pos = Offset(star.x * size.width, star.y * size.height);
      canvas.drawCircle(pos, star.size * 1.5, glowPaint);

      // Star core
      final corePaint = Paint()
        ..color = star.color.withOpacity(alpha);
      canvas.drawCircle(pos, star.size * 0.5, corePaint);

      // Bright center for larger stars
      if (star.size > 1.5) {
        final brightPaint = Paint()
          ..color = Colors.white.withOpacity(alpha * 0.8);
        canvas.drawCircle(pos, star.size * 0.2, brightPaint);
      }
    }
  }

  void _drawConstellations(Canvas canvas, Size size) {
    if (materializeValue < 0.3) return;
    final constFade = ((materializeValue - 0.3) / 0.3).clamp(0.0, 1.0);

    for (final constellation in constellations) {
      if (constellation.points.length < 2) continue;

      final linePaint = Paint()
        ..color = constellation.color.withOpacity(constellation.opacity * constFade)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < constellation.points.length; i++) {
        final p = constellation.points[i];
        final pos = Offset(p.dx * size.width, p.dy * size.height);
        if (i == 0) {
          path.moveTo(pos.dx, pos.dy);
        } else {
          path.lineTo(pos.dx, pos.dy);
        }
      }
      canvas.drawPath(path, linePaint);

      // Small dots at constellation points
      final dotPaint = Paint()
        ..color = constellation.color.withOpacity(constellation.opacity * 2 * constFade);
      for (final p in constellation.points) {
        canvas.drawCircle(
          Offset(p.dx * size.width, p.dy * size.height),
          1.5,
          dotPaint,
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

      final linePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            line.color.withOpacity(warpFade * lineFade * 0.6),
            Colors.white.withOpacity(warpFade * lineFade * 0.8),
          ],
        ).createShader(Rect.fromPoints(startPos, endPos))
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(startPos, endPos, linePaint);
    }
  }

  void _drawBlackHole(Canvas canvas, Size size) {
    if (materializeValue < 0.2) return;
    final bhFade = ((materializeValue - 0.2) / 0.4).clamp(0.0, 1.0);
    final pulse = 0.85 + 0.15 * pulseValue;

    // Event horizon (complete black)
    final eventHorizonRadius = 35.0 * pulse;
    final eventHorizonPaint = Paint()
      ..color = Colors.black;
    canvas.drawCircle(center, eventHorizonRadius, eventHorizonPaint);

    // Photon sphere (bright ring at edge)
    final photonPaint = Paint()
      ..color = NeonColors.orange.withOpacity(0.8 * bhFade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, eventHorizonRadius + 2, photonPaint);

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
      final diskPaint = Paint()
        ..shader = SweepGradient(
          colors: [
            NeonColors.orange.withOpacity(opacity * bhFade),
            NeonColors.yellow.withOpacity(opacity * 0.7 * bhFade),
            NeonColors.orange.withOpacity(opacity * bhFade),
            Colors.red.withOpacity(opacity * 0.5 * bhFade),
            NeonColors.orange.withOpacity(opacity * bhFade),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: diskRadius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 - i * 1.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(center, diskRadius, diskPaint);
      canvas.restore();
    }

    // Inner glow
    final innerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          NeonColors.cyan.withOpacity(0.2 * bhFade),
          NeonColors.purple.withOpacity(0.3 * bhFade),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: eventHorizonRadius * 2));
    canvas.drawCircle(center, eventHorizonRadius * 2, innerGlow);

    // Gravitational lensing effect (distortion rings)
    for (int i = 0; i < 3; i++) {
      final lensRadius = eventHorizonRadius * (1.3 + i * 0.4);
      final lensPaint = Paint()
        ..color = Colors.white.withOpacity(0.05 * bhFade * (1 - i * 0.25))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, lensRadius, lensPaint);
    }

    // Central singularity text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '◉',
        style: TextStyle(
          fontSize: 14,
          color: NeonColors.cyan.withOpacity(bhFade * 0.9),
          shadows: [
            Shadow(color: NeonColors.cyan.withOpacity(0.8), blurRadius: 10),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  void _drawOrbitalPaths(Canvas canvas) {
    if (materializeValue < 0.5) return;
    final orbitFade = ((materializeValue - 0.5) / 0.3).clamp(0.0, 1.0);

    // Draw orbital paths for each world tier
    final orbitRadii = [radius * 0.75, radius * 0.95];

    for (int i = 0; i < orbitRadii.length; i++) {
      final orbitR = orbitRadii[i];

      // Dashed orbit ring
      final segmentCount = 60;
      for (int seg = 0; seg < segmentCount; seg++) {
        if (seg % 3 == 0) continue; // Skip every 3rd segment for dashed effect

        final startAngle = (seg / segmentCount) * math.pi * 2;
        final sweepAngle = (1 / segmentCount) * math.pi * 2 * 0.8;

        final orbitPaint = Paint()
          ..color = NeonColors.cyan.withOpacity(0.15 * orbitFade * (1 - i * 0.3))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: orbitR),
          startAngle + mainAnimation * 0.2,
          sweepAngle,
          false,
          orbitPaint,
        );
      }

      // Moving markers on orbit
      for (int m = 0; m < 3; m++) {
        final markerAngle = mainAnimation * math.pi * 2 * 0.5 + m * math.pi * 2 / 3;
        final markerPos = Offset(
          center.dx + orbitR * math.cos(markerAngle),
          center.dy + orbitR * math.sin(markerAngle),
        );

        final markerPaint = Paint()
          ..color = NeonColors.cyan.withOpacity(0.4 * orbitFade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(markerPos, 2, markerPaint);
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

      // Energy beam with gradient
      final beamPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            NeonColors.orange.withOpacity(connectionOpacity * 0.8),
            world.accent.withOpacity(connectionOpacity),
            world.accent.withOpacity(connectionOpacity * 0.3),
          ],
        ).createShader(Rect.fromPoints(center, pos))
        ..strokeWidth = isHovered ? 2 : 1;
      canvas.drawLine(center, pos, beamPaint);

      // Traveling energy pulse
      final pulseT = (mainAnimation * 2 + i * 0.2) % 1.0;
      final pulsePos = Offset.lerp(center, pos, pulseT)!;

      final pulsePaint = Paint()
        ..color = Colors.white.withOpacity(connectionOpacity * 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(pulsePos, isHovered ? 4 : 2, pulsePaint);

      // Connect to adjacent worlds
      final nextI = (i + 1) % worlds.length;
      final nextPos = _getWorldPosition(nextI);

      final linkPaint = Paint()
        ..color = world.accent.withOpacity(netFade * 0.15)
        ..strokeWidth = 0.5;
      canvas.drawLine(pos, nextPos, linkPaint);
    }
  }

  void _drawFloatingParticles(Canvas canvas, Size size) {
    for (final particle in particles) {
      final pos = Offset(particle.x * size.width, particle.y * size.height);

      // Glow
      final glowPaint = Paint()
        ..color = particle.color.withOpacity(particle.alpha * 0.5 * materializeValue)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 2);
      canvas.drawCircle(pos, particle.size * 1.5, glowPaint);

      // Core
      final corePaint = Paint()
        ..color = particle.color.withOpacity(particle.alpha * 0.8 * materializeValue);
      canvas.drawCircle(pos, particle.size * 0.6, corePaint);
    }
  }

  void _drawPlanetNode(Canvas canvas, Offset pos, WorldInfo world, int index, bool isHovered, Size size) {
    if (materializeValue < 0.65) return;
    final nodeFade = ((materializeValue - 0.65 - index * 0.02) / 0.25).clamp(0.0, 1.0);
    if (nodeFade <= 0) return;

    final planetRadius = isHovered ? 42.0 : 35.0;
    final pulse = 0.9 + 0.1 * math.sin(mainAnimation * math.pi * 4 + index);
    final scale = isHovered ? 1.12 : 1.0;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale * pulse);
    canvas.translate(-pos.dx, -pos.dy);

    // Outer energy aura
    final auraRadius = planetRadius * 2.2;
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          world.accent.withOpacity(isHovered ? 0.5 : 0.25 * nodeFade),
          world.accent.withOpacity(isHovered ? 0.2 : 0.1 * nodeFade),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: pos, radius: auraRadius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(pos, auraRadius, auraPaint);

    // Planet ring (Saturn-style) for some worlds
    if (index % 2 == 0) {
      _drawPlanetRing(canvas, pos, planetRadius * 1.6, world.accent, nodeFade, isHovered);
    }

    // Planet body with gradient
    final bodyGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        world.accent.withOpacity(0.9 * nodeFade),
        world.accent.withOpacity(0.5 * nodeFade),
        Colors.black.withOpacity(0.8 * nodeFade),
      ],
    );

    final bodyPaint = Paint()
      ..shader = bodyGradient.createShader(Rect.fromCircle(center: pos, radius: planetRadius));
    canvas.drawCircle(pos, planetRadius, bodyPaint);

    // Planet surface detail (bands)
    for (int band = 0; band < 3; band++) {
      final bandY = pos.dy - planetRadius * 0.5 + band * planetRadius * 0.5;
      final bandPaint = Paint()
        ..color = world.accent.withOpacity(0.3 * nodeFade)
        ..strokeWidth = 1;

      // Curved band
      final bandPath = Path();
      bandPath.moveTo(pos.dx - planetRadius * 0.8, bandY);
      bandPath.quadraticBezierTo(
        pos.dx, bandY + 5,
        pos.dx + planetRadius * 0.8, bandY,
      );
      canvas.drawPath(bandPath, bandPaint);
    }

    // Atmosphere glow
    final atmoPaint = Paint()
      ..color = world.accent.withOpacity(0.4 * nodeFade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(pos, planetRadius, atmoPaint);

    // Specular highlight
    final specularPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.5, -0.5),
        radius: 0.5,
        colors: [
          Colors.white.withOpacity(0.5 * nodeFade),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: pos, radius: planetRadius));
    canvas.drawCircle(pos, planetRadius * 0.5, specularPaint);

    // Small moon for some worlds
    if (index % 3 == 0) {
      _drawMoon(canvas, pos, planetRadius, mainAnimation, world.accent, nodeFade);
    }

    // World identifier
    final idPainter = TextPainter(
      text: TextSpan(
        text: 'W${world.id}',
        style: TextStyle(
          fontSize: isHovered ? 16 : 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: Colors.white.withOpacity(nodeFade),
          shadows: [
            Shadow(color: world.accent.withOpacity(0.9), blurRadius: 10),
            Shadow(color: world.accent.withOpacity(0.5), blurRadius: 20),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    idPainter.paint(canvas, pos - Offset(idPainter.width / 2, idPainter.height / 2));

    // Holographic info panel when hovered
    if (isHovered) {
      _drawHolographicPanel(canvas, pos, planetRadius, world, nodeFade);
      _drawTargetingBrackets(canvas, pos, planetRadius * 1.5, world.accent, nodeFade);
      _drawOrbitingParticles(canvas, pos, planetRadius * 1.4, world.accent, nodeFade);
    }

    // Pulsar beacon
    _drawPulsarBeacon(canvas, pos, planetRadius, world.accent, nodeFade, index);

    canvas.restore();
  }

  void _drawPlanetRing(Canvas canvas, Offset center, double radius, Color color, double opacity, bool isHovered) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.0, 0.25); // Flatten for ring perspective
    canvas.translate(-center.dx, -center.dy);

    // Ring gradient
    for (int r = 0; r < 3; r++) {
      final ringR = radius * (0.9 + r * 0.1);
      final ringPaint = Paint()
        ..color = color.withOpacity((0.4 - r * 0.1) * opacity * (isHovered ? 1.5 : 1))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (3 - r).toDouble();
      canvas.drawCircle(center, ringR, ringPaint);
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
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(moonPos, 8, glowPaint);

    // Moon body
    final moonPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Colors.white.withOpacity(0.8 * opacity),
          color.withOpacity(0.4 * opacity),
        ],
      ).createShader(Rect.fromCircle(center: moonPos, radius: 5));
    canvas.drawCircle(moonPos, 5, moonPaint);
  }

  void _drawHolographicPanel(Canvas canvas, Offset pos, double radius, WorldInfo world, double opacity) {
    final panelOffset = Offset(radius + 50, -30);
    final panelPos = pos + panelOffset;
    final panelWidth = 100.0;
    final panelHeight = 60.0;

    // Panel background
    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(panelPos.dx, panelPos.dy, panelWidth, panelHeight),
      const Radius.circular(4),
    );

    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7 * opacity);
    canvas.drawRRect(panelRect, bgPaint);

    // Panel border
    final borderPaint = Paint()
      ..color = world.accent.withOpacity(0.8 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(panelRect, borderPaint);

    // Connection line to planet
    final linePaint = Paint()
      ..color = world.accent.withOpacity(0.5 * opacity)
      ..strokeWidth = 1;
    canvas.drawLine(pos + Offset(radius, 0), panelPos + Offset(0, panelHeight / 2), linePaint);

    // World name
    final namePainter = TextPainter(
      text: TextSpan(
        text: world.name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: world.accent.withOpacity(opacity),
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    namePainter.paint(canvas, panelPos + const Offset(8, 8));

    // Tagline
    final tagPainter = TextPainter(
      text: TextSpan(
        text: world.tagline,
        style: TextStyle(
          fontSize: 8,
          color: Colors.white.withOpacity(0.7 * opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
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

    final statusBgPaint = Paint()
      ..color = Colors.white.withOpacity(0.2 * opacity);
    canvas.drawRect(statusRect, statusBgPaint);

    final progress = 0.3 + (world.id / 10) * 0.7; // Fake progress based on world id
    final statusFillRect = Rect.fromLTWH(
      statusRect.left,
      statusRect.top,
      statusWidth * progress,
      statusHeight,
    );
    final statusFillPaint = Paint()
      ..color = world.accent.withOpacity(opacity);
    canvas.drawRect(statusFillRect, statusFillPaint);
  }

  void _drawTargetingBrackets(Canvas canvas, Offset center, double radius, Color color, double opacity) {
    final bracketSize = 15.0;
    final bracketPaint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final corners = [
      Offset(center.dx - radius, center.dy - radius), // TL
      Offset(center.dx + radius, center.dy - radius), // TR
      Offset(center.dx - radius, center.dy + radius), // BL
      Offset(center.dx + radius, center.dy + radius), // BR
    ];

    final directions = [
      [Offset(1, 0), Offset(0, 1)],  // TL
      [Offset(-1, 0), Offset(0, 1)], // TR
      [Offset(1, 0), Offset(0, -1)], // BL
      [Offset(-1, 0), Offset(0, -1)], // BR
    ];

    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        corners[i],
        corners[i] + directions[i][0] * bracketSize,
        bracketPaint,
      );
      canvas.drawLine(
        corners[i],
        corners[i] + directions[i][1] * bracketSize,
        bracketPaint,
      );
    }

    // Corner dots
    final dotPaint = Paint()
      ..color = color.withOpacity(opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (final corner in corners) {
      canvas.drawCircle(corner, 3, dotPaint);
    }
  }

  void _drawOrbitingParticles(Canvas canvas, Offset center, double radius, Color color, double opacity) {
    for (int i = 0; i < 8; i++) {
      final angle = mainAnimation * math.pi * 8 + (i / 8) * math.pi * 2;
      final particlePos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      final particlePaint = Paint()
        ..color = color.withOpacity(0.8 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(particlePos, 3, particlePaint);
    }
  }

  void _drawPulsarBeacon(Canvas canvas, Offset pos, double radius, Color color, double opacity, int index) {
    // Pulsing energy beacon above planet
    final beaconY = pos.dy - radius - 15;
    final pulsePhase = (mainAnimation * 4 + index * 0.3) % 1.0;
    final beaconAlpha = math.sin(pulsePhase * math.pi);

    if (beaconAlpha > 0.1) {
      final beaconPaint = Paint()
        ..color = color.withOpacity(beaconAlpha * 0.6 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(pos.dx, beaconY), 4 + beaconAlpha * 2, beaconPaint);

      // Beacon ray upward
      final rayPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            color.withOpacity(beaconAlpha * 0.4 * opacity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(pos.dx - 1, beaconY - 20, 2, 20))
        ..strokeWidth = 2;
      canvas.drawLine(Offset(pos.dx, beaconY), Offset(pos.dx, beaconY - 20), rayPaint);
    }
  }

  void _drawScanLines(Canvas canvas, Size size) {
    if (materializeValue < 0.8) return;
    final scanFade = ((materializeValue - 0.8) / 0.2).clamp(0.0, 1.0);

    // Horizontal scan lines
    final scanY = (mainAnimation * 2 % 1.0) * size.height;

    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          NeonColors.cyan.withOpacity(0.15 * scanFade),
          NeonColors.cyan.withOpacity(0.3 * scanFade),
          NeonColors.cyan.withOpacity(0.15 * scanFade),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 2, size.width, 4));

    canvas.drawRect(Rect.fromLTWH(0, scanY - 2, size.width, 4), scanPaint);

    // Secondary scan line
    final scan2Y = ((mainAnimation * 2 + 0.5) % 1.0) * size.height;
    final scan2Paint = Paint()
      ..color = NeonColors.magenta.withOpacity(0.1 * scanFade);
    canvas.drawRect(Rect.fromLTWH(0, scan2Y - 1, size.width, 2), scan2Paint);
  }

  void _drawVolumetricRays(Canvas canvas, Size size) {
    if (materializeValue < 0.7) return;
    final rayFade = ((materializeValue - 0.7) / 0.3).clamp(0.0, 1.0);

    // Light rays from center
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 + mainAnimation * 0.3;
      final rayLength = size.width * 0.7;

      final endPos = Offset(
        center.dx + rayLength * math.cos(angle),
        center.dy + rayLength * math.sin(angle),
      );

      final rayPath = Path();
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

      final rayPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            NeonColors.cyan.withOpacity(0.03 * rayFade),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: rayLength));

      canvas.drawPath(rayPath, rayPaint);
    }
  }

  void _drawGlitchEffect(Canvas canvas, Size size) {
    final random = math.Random();

    // Random horizontal slice displacement
    for (int i = 0; i < 5; i++) {
      final sliceY = random.nextDouble() * size.height;
      final sliceHeight = 2 + random.nextDouble() * 8;
      final offsetX = (random.nextDouble() - 0.5) * 20 * glitchIntensity;

      // RGB split
      final redRect = Rect.fromLTWH(-offsetX, sliceY, size.width, sliceHeight);
      final cyanRect = Rect.fromLTWH(offsetX, sliceY, size.width, sliceHeight);

      canvas.drawRect(redRect, Paint()..color = Colors.red.withOpacity(0.1 * glitchIntensity));
      canvas.drawRect(cyanRect, Paint()..color = NeonColors.cyan.withOpacity(0.1 * glitchIntensity));
    }

    // Static noise
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final noiseSize = 1 + random.nextDouble() * 3;

      canvas.drawRect(
        Rect.fromLTWH(x, y, noiseSize, noiseSize),
        Paint()..color = Colors.white.withOpacity(random.nextDouble() * 0.3 * glitchIntensity),
      );
    }
  }

  void _drawVignette(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.transparent,
          Colors.black.withOpacity(0.4),
          Colors.black.withOpacity(0.8),
        ],
        stops: const [0.0, 0.5, 0.8, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
