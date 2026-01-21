import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pattern type for the wireframe materialization
enum TronPattern {
  grid,
  hexagonal,
  radial,
  lightCycle,
}

/// Tron-style materialization effect widget
/// Creates a wireframe build-up animation with light trails
class TronMaterializationWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color primaryColor;
  final Color secondaryColor;
  final bool autoStart;
  final VoidCallback? onComplete;
  final TronPattern pattern;
  final bool reducedMotion;

  const TronMaterializationWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.primaryColor = const Color(0xFF00FFFF), // Cyan
    this.secondaryColor = const Color(0xFFFF6600), // Orange
    this.autoStart = true,
    this.onComplete,
    this.pattern = TronPattern.grid,
    this.reducedMotion = false,
  });

  @override
  State<TronMaterializationWidget> createState() =>
      _TronMaterializationWidgetState();
}

class _TronMaterializationWidgetState extends State<TronMaterializationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _buildProgress;
  List<_WireframeLine> _lines = [];
  List<_LightParticle> _particles = [];
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _buildProgress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        if (_lastSize != size) {
          _lastSize = size;
          _generatePattern(size);
        }
      }
    });
  }

  void _generatePattern(Size size) {
    _lines = [];
    _particles = [];

    switch (widget.pattern) {
      case TronPattern.grid:
        _generateGridPattern(size);
        break;
      case TronPattern.hexagonal:
        _generateHexPattern(size);
        break;
      case TronPattern.radial:
        _generateRadialPattern(size);
        break;
      case TronPattern.lightCycle:
        _generateLightCyclePattern(size);
        break;
    }

    // Generate particles
    if (!widget.reducedMotion) {
      _generateParticles(size);
    }
  }

  void _generateGridPattern(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const gridSize = 80.0;
    final rows = (size.height / gridSize).ceil();
    final cols = (size.width / gridSize).ceil();

    // Horizontal lines from center
    for (int i = -rows ~/ 2; i <= rows ~/ 2; i++) {
      final y = center.dy + i * gridSize;
      final distance = i.abs() / (rows / 2).clamp(1, double.infinity);

      _lines.add(_WireframeLine(
        start: center,
        end: Offset(0, y),
        startTime: distance * 0.3,
        endTime: distance * 0.3 + 0.4,
      ));

      _lines.add(_WireframeLine(
        start: center,
        end: Offset(size.width, y),
        startTime: distance * 0.3,
        endTime: distance * 0.3 + 0.4,
      ));
    }

    // Vertical lines from center
    for (int i = -cols ~/ 2; i <= cols ~/ 2; i++) {
      final x = center.dx + i * gridSize;
      final distance = i.abs() / (cols / 2).clamp(1, double.infinity);

      _lines.add(_WireframeLine(
        start: center,
        end: Offset(x, 0),
        startTime: distance * 0.3,
        endTime: distance * 0.3 + 0.4,
      ));

      _lines.add(_WireframeLine(
        start: center,
        end: Offset(x, size.height),
        startTime: distance * 0.3,
        endTime: distance * 0.3 + 0.4,
      ));
    }
  }

  void _generateHexPattern(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const maxRings = 6;
    const hexRadius = 60.0;

    // Central point connections
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final end = Offset(
        center.dx + math.cos(angle) * hexRadius * maxRings,
        center.dy + math.sin(angle) * hexRadius * maxRings,
      );

      _lines.add(_WireframeLine(
        start: center,
        end: end,
        startTime: 0.0,
        endTime: 0.5,
      ));
    }

    // Hexagonal rings
    for (int ring = 1; ring <= maxRings; ring++) {
      final ringDelay = ring * 0.08;
      final radius = ring * hexRadius;

      for (int i = 0; i < 6; i++) {
        final angle1 = i * math.pi / 3 - math.pi / 6;
        final angle2 = (i + 1) * math.pi / 3 - math.pi / 6;

        final p1 = Offset(
          center.dx + math.cos(angle1) * radius,
          center.dy + math.sin(angle1) * radius,
        );
        final p2 = Offset(
          center.dx + math.cos(angle2) * radius,
          center.dy + math.sin(angle2) * radius,
        );

        _lines.add(_WireframeLine(
          start: p1,
          end: p2,
          startTime: 0.2 + ringDelay,
          endTime: 0.4 + ringDelay,
        ));
      }
    }
  }

  void _generateRadialPattern(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const numRays = 24;
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;

    // Radial rays
    for (int i = 0; i < numRays; i++) {
      final angle = i * 2 * math.pi / numRays;
      final end = Offset(
        center.dx + math.cos(angle) * maxRadius,
        center.dy + math.sin(angle) * maxRadius,
      );

      _lines.add(_WireframeLine(
        start: center,
        end: end,
        startTime: (i / numRays) * 0.3,
        endTime: (i / numRays) * 0.3 + 0.5,
      ));
    }

    // Concentric circles (approximated with lines)
    const numRings = 5;
    for (int ring = 1; ring <= numRings; ring++) {
      final radius = (maxRadius / numRings) * ring;
      final ringDelay = ring * 0.1;
      const segments = 36;

      for (int i = 0; i < segments; i++) {
        final angle1 = i * 2 * math.pi / segments;
        final angle2 = (i + 1) * 2 * math.pi / segments;

        final p1 = Offset(
          center.dx + math.cos(angle1) * radius,
          center.dy + math.sin(angle1) * radius,
        );
        final p2 = Offset(
          center.dx + math.cos(angle2) * radius,
          center.dy + math.sin(angle2) * radius,
        );

        _lines.add(_WireframeLine(
          start: p1,
          end: p2,
          startTime: 0.3 + ringDelay + (i / segments) * 0.1,
          endTime: 0.5 + ringDelay + (i / segments) * 0.1,
        ));
      }
    }
  }

  void _generateLightCyclePattern(Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Light cycle trails - zig-zag pattern from center
    final paths = <List<Offset>>[
      // Cyan trail (right-going)
      [
        center,
        Offset(center.dx + 100, center.dy),
        Offset(center.dx + 100, center.dy - 80),
        Offset(center.dx + 200, center.dy - 80),
        Offset(center.dx + 200, center.dy + 40),
        Offset(size.width, center.dy + 40),
      ],
      // Orange trail (left-going)
      [
        center,
        Offset(center.dx - 100, center.dy),
        Offset(center.dx - 100, center.dy + 80),
        Offset(center.dx - 200, center.dy + 80),
        Offset(center.dx - 200, center.dy - 40),
        Offset(0, center.dy - 40),
      ],
      // Upper trail
      [
        center,
        Offset(center.dx, center.dy - 100),
        Offset(center.dx + 60, center.dy - 100),
        Offset(center.dx + 60, 0),
      ],
      // Lower trail
      [
        center,
        Offset(center.dx, center.dy + 100),
        Offset(center.dx - 60, center.dy + 100),
        Offset(center.dx - 60, size.height),
      ],
    ];

    for (int pathIdx = 0; pathIdx < paths.length; pathIdx++) {
      final path = paths[pathIdx];
      final baseDelay = pathIdx * 0.15;

      for (int i = 0; i < path.length - 1; i++) {
        final segmentDelay = i * 0.1;
        _lines.add(_WireframeLine(
          start: path[i],
          end: path[i + 1],
          startTime: baseDelay + segmentDelay,
          endTime: baseDelay + segmentDelay + 0.2,
        ));
      }
    }
  }

  void _generateParticles(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(42);

    final particleCount = widget.reducedMotion ? 10 : 30;

    for (int i = 0; i < particleCount; i++) {
      _particles.add(_LightParticle(
        position: Offset(
          center.dx + (random.nextDouble() - 0.5) * size.width * 0.8,
          center.dy + (random.nextDouble() - 0.5) * size.height * 0.8,
        ),
        spawnTime: random.nextDouble() * 0.5,
        velocity: Offset(
          (random.nextDouble() - 0.5) * 100,
          (random.nextDouble() - 0.5) * 100,
        ),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _buildProgress,
      builder: (context, child) {
        return Stack(
          children: [
            // Wireframe overlay
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _TronMaterializationPainter(
                    progress: _buildProgress.value,
                    lines: _lines,
                    particles: _particles,
                    primaryColor: widget.primaryColor,
                    secondaryColor: widget.secondaryColor,
                    reducedMotion: widget.reducedMotion,
                  ),
                ),
              ),
            ),
            // Actual content with fade-in
            Opacity(
              opacity: _buildProgress.value,
              child: widget.child,
            ),
          ],
        );
      },
    );
  }
}

class _TronMaterializationPainter extends CustomPainter {
  final double progress;
  final List<_WireframeLine> lines;
  final List<_LightParticle> particles;
  final Color primaryColor;
  final Color secondaryColor;
  final bool reducedMotion;

  _TronMaterializationPainter({
    required this.progress,
    required this.lines,
    required this.particles,
    required this.primaryColor,
    required this.secondaryColor,
    required this.reducedMotion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fade out effect for lines after materialization completes
    final lineFadeOut = (progress > 0.7
            ? 1.0 - ((progress - 0.7) / 0.3)
            : 1.0)
        .clamp(0.0, 1.0)
        .toDouble();

    // Draw wireframe lines
    for (final line in lines) {
      if (progress >= line.startTime) {
        final lineProgress = progress >= line.endTime
            ? 1.0
            : (progress - line.startTime) / (line.endTime - line.startTime);

        _drawWireframeLine(canvas, line, lineProgress, lineFadeOut);

        if (!reducedMotion && lineProgress < 1.0) {
          _drawLightTrail(canvas, line, lineProgress);
        }
      }
    }

    // Draw particles
    if (!reducedMotion) {
      for (final particle in particles) {
        if (progress >= particle.spawnTime) {
          _drawParticle(canvas, particle, progress);
        }
      }
    }
  }

  void _drawWireframeLine(
      Canvas canvas, _WireframeLine line, double lineProgress, double fadeOut) {
    final currentEnd = Offset.lerp(line.start, line.end, lineProgress)!;

    // Glow (skip if reduced motion)
    if (!reducedMotion) {
      final glowPaint = Paint()
        ..color = primaryColor.withOpacity(0.3 * fadeOut)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawLine(line.start, currentEnd, glowPaint);
    }

    // Main line
    final linePaint = Paint()
      ..color = primaryColor.withOpacity(fadeOut)
      ..strokeWidth = reducedMotion ? 1.0 : 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(line.start, currentEnd, linePaint);
  }

  void _drawLightTrail(Canvas canvas, _WireframeLine line, double progress) {
    const trailLength = 0.15;
    final trailStart = math.max(0.0, progress - trailLength);
    final trailEnd = progress;

    if (trailStart >= trailEnd) return;

    final startPoint = Offset.lerp(line.start, line.end, trailStart)!;
    final endPoint = Offset.lerp(line.start, line.end, trailEnd)!;

    // Gradient trail
    final trailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          secondaryColor.withOpacity(0),
          secondaryColor.withOpacity(0.8),
          Colors.white,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromPoints(startPoint, endPoint))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawLine(startPoint, endPoint, trailPaint);

    // Bright leading point
    final pointPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(endPoint, 3, pointPaint);
  }

  void _drawParticle(Canvas canvas, _LightParticle particle, double progress) {
    final age = progress - particle.spawnTime;
    if (age > 0.4) return;

    final alpha = (1.0 - age / 0.4).clamp(0.0, 1.0);
    final particleSize = 2.0 + alpha * 2.0;

    // Glow
    final glowPaint = Paint()
      ..color = secondaryColor.withOpacity(alpha * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(particle.position, particleSize * 2, glowPaint);

    // Core
    final corePaint = Paint()..color = Colors.white.withOpacity(alpha);

    canvas.drawCircle(particle.position, particleSize, corePaint);
  }

  @override
  bool shouldRepaint(_TronMaterializationPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

class _WireframeLine {
  final Offset start;
  final Offset end;
  final double startTime;
  final double endTime;

  _WireframeLine({
    required this.start,
    required this.end,
    required this.startTime,
    required this.endTime,
  });
}

class _LightParticle {
  final Offset position;
  final double spawnTime;
  final Offset velocity;

  _LightParticle({
    required this.position,
    required this.spawnTime,
    required this.velocity,
  });
}
