import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// TRON-style button with wireframe materialization, energy trails,
/// electric arcs, hologram flicker, and reactive hover effects
class TronButton extends StatefulWidget {
  const TronButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = NeonColors.cyan,
    this.secondaryColor,
    this.width = 280,
    this.height = 56,
    this.enabled = true,
    this.icon,
    this.delay = Duration.zero,
    this.materializationDuration = const Duration(milliseconds: 600),
  });

  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color? secondaryColor;
  final double width;
  final double height;
  final bool enabled;
  final IconData? icon;
  final Duration delay;
  final Duration materializationDuration;

  @override
  State<TronButton> createState() => _TronButtonState();
}

class _TronButtonState extends State<TronButton>
    with TickerProviderStateMixin {
  late AnimationController _materializeController;
  late AnimationController _pulseController;
  late AnimationController _hoverController;
  late AnimationController _energyController;
  late AnimationController _glitchController;

  late Animation<double> _materializeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _hoverAnimation;

  bool _isHovered = false;
  bool _isPressed = false;
  bool _isMaterialized = false;
  bool _showGlitch = false;
  double _glitchOffset = 0;

  Timer? _materializeTimer;
  Timer? _glitchTimer;

  final _random = math.Random();
  List<_EnergyParticle> _particles = [];
  List<_ElectricArc> _arcs = [];

  @override
  void initState() {
    super.initState();

    _materializeController = AnimationController(
      duration: widget.materializationDuration,
      vsync: this,
    );

    _materializeAnimation = CurvedAnimation(
      parent: _materializeController,
      curve: Curves.easeOutCubic,
    );

    _materializeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isMaterialized = true);
      }
    });

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

    _energyController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..repeat();
    _energyController.addListener(_updateParticlesAndArcs);

    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _glitchController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showGlitch = false;
          _glitchOffset = 0;
        });
      }
    });

    // Start materialization after delay
    _materializeTimer = Timer(widget.delay, () {
      if (mounted) {
        _materializeController.forward();
        _pulseController.repeat(reverse: true);
        _triggerRandomGlitch();
      }
    });
  }

  void _triggerRandomGlitch() {
    _glitchTimer?.cancel();
    _glitchTimer = Timer(Duration(milliseconds: 3000 + _random.nextInt(5000)), () {
      if (mounted && _isMaterialized) {
        setState(() {
          _showGlitch = true;
          _glitchOffset = (_random.nextDouble() - 0.5) * 6;
        });
        _glitchController.forward(from: 0);
        _triggerRandomGlitch();
      }
    });
  }

  void _updateParticlesAndArcs() {
    if (!mounted || !_isMaterialized) return;

    setState(() {
      // Update existing particles
      _particles = _particles.where((p) {
        p.life -= 0.02;
        p.x += p.vx;
        p.y += p.vy;
        return p.life > 0;
      }).toList();

      // Add new particles on hover
      if (_isHovered && _random.nextDouble() > 0.7) {
        _particles.add(_EnergyParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          vx: (_random.nextDouble() - 0.5) * 0.02,
          vy: (_random.nextDouble() - 0.5) * 0.02,
          life: 1.0,
          size: 2 + _random.nextDouble() * 3,
        ));
      }

      // Generate electric arcs on hover
      if (_isHovered && _random.nextDouble() > 0.85) {
        _arcs = List.generate(_random.nextInt(2) + 1, (_) {
          final isHorizontal = _random.nextBool();
          if (isHorizontal) {
            final y = _random.nextDouble();
            return _ElectricArc(
              start: Offset(0, y),
              end: Offset(1, y + (_random.nextDouble() - 0.5) * 0.2),
              intensity: _random.nextDouble(),
            );
          } else {
            final x = _random.nextDouble();
            return _ElectricArc(
              start: Offset(x, 0),
              end: Offset(x + (_random.nextDouble() - 0.5) * 0.2, 1),
              intensity: _random.nextDouble(),
            );
          }
        });
      } else if (!_isHovered) {
        _arcs = [];
      }
    });
  }

  @override
  void dispose() {
    _materializeTimer?.cancel();
    _glitchTimer?.cancel();
    _materializeController.dispose();
    _pulseController.dispose();
    _hoverController.dispose();
    _energyController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    if (!_isMaterialized) return;
    setState(() => _isHovered = hovering);
    if (hovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
      _particles.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.enabled ? widget.color : Colors.grey;
    final secondaryColor = widget.secondaryColor ?? const Color(0xFFFF6600);

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTapDown: (_) {
          if (_isMaterialized) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (_isMaterialized) {
            setState(() => _isPressed = false);
            if (widget.enabled) widget.onPressed();
          }
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _materializeAnimation,
            _pulseAnimation,
            _hoverAnimation,
            _energyController,
          ]),
          builder: (context, child) {
            final materializeProgress = _materializeAnimation.value;
            final glowIntensity = _isHovered
                ? 1.0
                : 0.3 + _pulseAnimation.value * 0.4;
            final scale = _isPressed ? 0.95 : (_isHovered ? 1.04 : 1.0);
            final contentOpacity = materializeProgress.clamp(0.0, 1.0);

            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: Stack(
                  children: [
                    // Main button painter
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _TronButtonPainter(
                          progress: materializeProgress,
                          primaryColor: effectiveColor,
                          secondaryColor: secondaryColor,
                          glowIntensity: glowIntensity * materializeProgress,
                          isHovered: _isHovered,
                          hoverProgress: _hoverAnimation.value,
                          particles: _particles,
                          arcs: _arcs,
                          showGlitch: _showGlitch,
                          glitchOffset: _glitchOffset,
                        ),
                      ),
                    ),

                    // Content
                    Positioned.fill(
                      child: Opacity(
                        opacity: contentOpacity,
                        child: Center(
                          child: _showGlitch
                              ? _buildGlitchedContent(effectiveColor, glowIntensity)
                              : _buildContent(effectiveColor, glowIntensity),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(Color color, double glowIntensity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            color: color,
            size: 22,
            shadows: [
              Shadow(
                color: color.withOpacity(0.8),
                blurRadius: 10,
              ),
              Shadow(
                color: color.withOpacity(0.5),
                blurRadius: 20,
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
        Text(
          widget.text,
          style: TextStyle(
            fontFamily: NeonTextStyles.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            color: color,
            shadows: [
              Shadow(
                color: color.withOpacity(glowIntensity),
                blurRadius: 8,
              ),
              Shadow(
                color: color.withOpacity(glowIntensity * 0.5),
                blurRadius: 16,
              ),
              Shadow(
                color: color.withOpacity(glowIntensity * 0.3),
                blurRadius: 24,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlitchedContent(Color color, double glowIntensity) {
    return Stack(
      children: [
        // Red offset
        Transform.translate(
          offset: Offset(_glitchOffset * 2, 0),
          child: Opacity(
            opacity: 0.5,
            child: _buildContent(NeonColors.red, glowIntensity * 0.5),
          ),
        ),
        // Cyan offset
        Transform.translate(
          offset: Offset(-_glitchOffset * 2, 0),
          child: Opacity(
            opacity: 0.5,
            child: _buildContent(NeonColors.cyan, glowIntensity * 0.5),
          ),
        ),
        // Main content
        _buildContent(color, glowIntensity),
      ],
    );
  }
}

class _EnergyParticle {
  double x, y, vx, vy, life, size;

  _EnergyParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.size,
  });
}

class _ElectricArc {
  final Offset start;
  final Offset end;
  final double intensity;

  _ElectricArc({required this.start, required this.end, required this.intensity});
}

class _TronButtonPainter extends CustomPainter {
  _TronButtonPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.glowIntensity,
    required this.isHovered,
    required this.hoverProgress,
    required this.particles,
    required this.arcs,
    required this.showGlitch,
    required this.glitchOffset,
  });

  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final double glowIntensity;
  final bool isHovered;
  final double hoverProgress;
  final List<_EnergyParticle> particles;
  final List<_ElectricArc> arcs;
  final bool showGlitch;
  final double glitchOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    // Background fill (fades in)
    if (progress > 0.3) {
      final bgOpacity = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);

      // Gradient background on hover
      final bgPaint = Paint();
      if (isHovered) {
        bgPaint.shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(size.width, size.height),
          [
            Colors.black.withOpacity(0.8 * bgOpacity),
            primaryColor.withOpacity(0.15 * bgOpacity * hoverProgress),
            Colors.black.withOpacity(0.8 * bgOpacity),
          ],
        );
      } else {
        bgPaint.color = Colors.black.withOpacity(0.7 * bgOpacity);
      }
      canvas.drawRRect(rrect, bgPaint);
    }

    // Draw wireframe lines from center
    _drawWireframeLines(canvas, size, center);

    // Draw energy particles
    _drawParticles(canvas, size);

    // Draw electric arcs
    _drawElectricArcs(canvas, size);

    // Draw border with glow (appears after wireframe)
    if (progress > 0.5) {
      final borderProgress = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
      _drawBorder(canvas, size, borderProgress);
    }

    // Draw corner decorations
    if (progress > 0.7) {
      final cornerProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
      _drawCorners(canvas, size, cornerProgress);
    }

    // Draw hover energy field
    if (isHovered && hoverProgress > 0) {
      _drawEnergyField(canvas, size);
    }

    // Draw construction particles
    _drawConstructionParticles(canvas, size, center);

    // Draw glitch slices
    if (showGlitch) {
      _drawGlitchSlices(canvas, size);
    }

    // Draw scanline effect
    _drawScanline(canvas, size);
  }

  void _drawWireframeLines(Canvas canvas, Size size, Offset center) {
    if (progress <= 0) return;

    // Fade out internal wireframe lines after construction completes
    final fadeOutStart = 0.7;
    final fadeOutEnd = 1.0;
    final wireframeFade = progress >= fadeOutEnd
        ? 0.0
        : progress <= fadeOutStart
            ? 1.0
            : 1.0 - ((progress - fadeOutStart) / (fadeOutEnd - fadeOutStart));

    // Internal construction lines (these fade out)
    final internalLines = <_WireLine>[
      // Horizontal lines from center
      _WireLine(center, Offset(0, center.dy), 0.0, 0.4),
      _WireLine(center, Offset(size.width, center.dy), 0.0, 0.4),
      // Vertical lines from center
      _WireLine(center, Offset(center.dx, 0), 0.1, 0.5),
      _WireLine(center, Offset(center.dx, size.height), 0.1, 0.5),
      // Diagonal lines to corners
      _WireLine(center, Offset(0, 0), 0.2, 0.6),
      _WireLine(center, Offset(size.width, 0), 0.2, 0.6),
      _WireLine(center, Offset(0, size.height), 0.2, 0.6),
      _WireLine(center, Offset(size.width, size.height), 0.2, 0.6),
    ];

    // Only draw internal lines if they haven't faded out
    if (wireframeFade > 0) {
      for (final line in internalLines) {
        if (progress >= line.startTime) {
          final lineProgress = progress >= line.endTime
              ? 1.0
              : ((progress - line.startTime) / (line.endTime - line.startTime)).clamp(0.0, 1.0);

          final currentEnd = Offset.lerp(line.start, line.end, lineProgress)!;

          // Glow (fades out)
          final glowPaint = Paint()
            ..color = primaryColor.withOpacity(0.3 * glowIntensity * wireframeFade)
            ..strokeWidth = 4
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawLine(line.start, currentEnd, glowPaint);

          // Main line (fades out)
          final linePaint = Paint()
            ..color = primaryColor.withOpacity(0.8 * wireframeFade)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke;
          canvas.drawLine(line.start, currentEnd, linePaint);

          // Light trail at the end
          if (lineProgress > 0 && lineProgress < 1) {
            const trailLength = 0.15;
            final trailStart = math.max(0.0, lineProgress - trailLength);
            final trailStartPoint = Offset.lerp(line.start, line.end, trailStart)!;

            final trailPaint = Paint()
              ..shader = ui.Gradient.linear(
                trailStartPoint,
                currentEnd,
                [
                  secondaryColor.withOpacity(0),
                  secondaryColor.withOpacity(0.8),
                  Colors.white,
                ],
                [0.0, 0.6, 1.0],
              )
              ..strokeWidth = 3
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
            canvas.drawLine(trailStartPoint, currentEnd, trailPaint);

            // Bright point at the front
            final pointPaint = Paint()
              ..color = Colors.white
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
            canvas.drawCircle(currentEnd, 3, pointPaint);
          }
        }
      }
    }
  }

  void _drawBorder(Canvas canvas, Size size, double borderProgress) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    // Outer glow - more intense on hover
    final glowRadius = isHovered ? 15.0 : 10.0;
    final glowOpacity = isHovered ? 0.6 : 0.4;
    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(glowIntensity * glowOpacity * borderProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovered ? 12 : 8
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);
    canvas.drawRRect(rrect, glowPaint);

    // Border with gradient on hover
    if (isHovered && hoverProgress > 0) {
      final gradientBorderPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(size.width, size.height),
          [
            primaryColor,
            secondaryColor,
            primaryColor,
          ],
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(rrect, gradientBorderPaint);
    } else {
      final borderPaint = Paint()
        ..color = primaryColor.withOpacity(borderProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  void _drawCorners(Canvas canvas, Size size, double cornerProgress) {
    const cornerSize = 14.0;
    final cornerPaint = Paint()
      ..color = primaryColor.withOpacity(cornerProgress)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = secondaryColor.withOpacity(cornerProgress * 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Top-left
    canvas.drawLine(
      const Offset(4, 4),
      Offset(4, 4 + cornerSize * cornerProgress),
      cornerPaint,
    );
    canvas.drawLine(
      const Offset(4, 4),
      Offset(4 + cornerSize * cornerProgress, 4),
      cornerPaint,
    );
    // Accent dot
    canvas.drawCircle(const Offset(4, 4), 2 * cornerProgress, accentPaint);

    // Top-right
    canvas.drawLine(
      Offset(size.width - 4, 4),
      Offset(size.width - 4, 4 + cornerSize * cornerProgress),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - 4, 4),
      Offset(size.width - 4 - cornerSize * cornerProgress, 4),
      cornerPaint,
    );
    canvas.drawCircle(Offset(size.width - 4, 4), 2 * cornerProgress, accentPaint);

    // Bottom-left
    canvas.drawLine(
      Offset(4, size.height - 4),
      Offset(4, size.height - 4 - cornerSize * cornerProgress),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(4, size.height - 4),
      Offset(4 + cornerSize * cornerProgress, size.height - 4),
      cornerPaint,
    );
    canvas.drawCircle(Offset(4, size.height - 4), 2 * cornerProgress, accentPaint);

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - 4, size.height - 4),
      Offset(size.width - 4, size.height - 4 - cornerSize * cornerProgress),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - 4, size.height - 4),
      Offset(size.width - 4 - cornerSize * cornerProgress, size.height - 4),
      cornerPaint,
    );
    canvas.drawCircle(Offset(size.width - 4, size.height - 4), 2 * cornerProgress, accentPaint);
  }

  void _drawParticles(Canvas canvas, Size size) {
    for (final particle in particles) {
      final pos = Offset(particle.x * size.width, particle.y * size.height);

      // Glow
      final glowPaint = Paint()
        ..color = primaryColor.withOpacity(particle.life * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(pos, particle.size * 1.5, glowPaint);

      // Core
      final corePaint = Paint()
        ..color = Colors.white.withOpacity(particle.life);
      canvas.drawCircle(pos, particle.size * 0.5, corePaint);
    }
  }

  void _drawElectricArcs(Canvas canvas, Size size) {
    final random = math.Random(42);

    for (final arc in arcs) {
      final start = Offset(arc.start.dx * size.width, arc.start.dy * size.height);
      final end = Offset(arc.end.dx * size.width, arc.end.dy * size.height);

      // Draw jagged lightning path
      final path = Path();
      path.moveTo(start.dx, start.dy);

      const segments = 5;
      for (int i = 1; i <= segments; i++) {
        final t = i / segments;
        final target = Offset.lerp(start, end, t)!;
        final jitter = Offset(
          (random.nextDouble() - 0.5) * 15 * (1 - t),
          (random.nextDouble() - 0.5) * 8,
        );
        final current = target + jitter;
        path.lineTo(current.dx, current.dy);
      }

      // Glow
      final glowPaint = Paint()
        ..color = primaryColor.withOpacity(0.4 * arc.intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawPath(path, glowPaint);

      // Core
      final corePaint = Paint()
        ..color = Colors.white.withOpacity(arc.intensity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPath(path, corePaint);
    }
  }

  void _drawEnergyField(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Inner energy glow
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        size.width * 0.6,
        [
          primaryColor.withOpacity(0.15 * hoverProgress),
          primaryColor.withOpacity(0.05 * hoverProgress),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawConstructionParticles(Canvas canvas, Size size, Offset center) {
    if (progress < 0.2 || progress > 0.8) return;

    final random = math.Random(42);
    final particleProgress = ((progress - 0.2) / 0.6).clamp(0.0, 1.0);

    for (int i = 0; i < 10; i++) {
      final spawnTime = random.nextDouble() * 0.5;
      if (particleProgress < spawnTime) continue;

      final age = particleProgress - spawnTime;
      if (age > 0.4) continue;

      final alpha = (1.0 - age / 0.4).clamp(0.0, 1.0);
      final angle = random.nextDouble() * math.pi * 2;
      final distance = random.nextDouble() * size.width * 0.4 * (1 + age);

      final pos = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      // Glow
      final glowPaint = Paint()
        ..color = secondaryColor.withOpacity(alpha * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pos, 4, glowPaint);

      // Core
      final corePaint = Paint()
        ..color = Colors.white.withOpacity(alpha);
      canvas.drawCircle(pos, 2, corePaint);
    }
  }

  void _drawGlitchSlices(Canvas canvas, Size size) {
    final random = math.Random((glitchOffset * 100).toInt());

    for (int i = 0; i < 2; i++) {
      final y = random.nextDouble() * size.height;
      final height = 2.0 + random.nextDouble() * 4;
      final xOffset = (random.nextDouble() - 0.5) * glitchOffset * 3;

      final slicePaint = Paint()
        ..color = secondaryColor.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawRect(
        Rect.fromLTWH(xOffset, y, size.width, height),
        slicePaint,
      );
    }
  }

  void _drawScanline(Canvas canvas, Size size) {
    // Subtle horizontal scanlines
    final linePaint = Paint()
      ..color = primaryColor.withOpacity(0.02 * glowIntensity);

    for (double y = 0; y < size.height; y += 2) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TronButtonPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        glowIntensity != oldDelegate.glowIntensity ||
        isHovered != oldDelegate.isHovered ||
        hoverProgress != oldDelegate.hoverProgress ||
        particles.length != oldDelegate.particles.length ||
        arcs.length != oldDelegate.arcs.length ||
        showGlitch != oldDelegate.showGlitch;
  }
}

class _WireLine {
  final Offset start;
  final Offset end;
  final double startTime;
  final double endTime;

  _WireLine(this.start, this.end, this.startTime, this.endTime);
}
