import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../../services/audio_service.dart';

/// Epic Neon Button with advanced visual effects:
/// - Multiple animated energy pulses traveling around border
/// - Electric arc effects on hover
/// - Holographic scanline interference
/// - Particle burst system
/// - Chromatic aberration on interaction
/// - Data circuit patterns
/// - Energy field ripples
/// - Glitch effects
class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = NeonColors.cyan,
    this.secondaryColor,
    this.width = 250,
    this.height = 50,
    this.enabled = true,
  });

  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color? secondaryColor;
  final double width;
  final double height;
  final bool enabled;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _borderPulseController;
  late AnimationController _shimmerController;
  late AnimationController _particleController;
  late AnimationController _electricController;
  late Animation<double> _glowAnimation;

  bool _isHovered = false;
  bool _isPressed = false;

  final _random = math.Random();
  final List<_Particle> _particles = [];
  final List<_ElectricArc> _arcs = [];
  double _glitchOffset = 0;
  bool _showGlitch = false;

  @override
  void initState() {
    super.initState();

    // Glow pulse animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Border pulse animation (multiple energy pulses)
    _borderPulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Shimmer and holographic effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    )..repeat();

    // Particle system
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..repeat();
    _particleController.addListener(_updateParticles);

    // Electric arc timing
    _electricController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..repeat();
    _electricController.addListener(_updateElectricArcs);

    // Initialize particles
    _initParticles();
  }

  void _initParticles() {
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        vx: (_random.nextDouble() - 0.5) * 0.01,
        vy: (_random.nextDouble() - 0.5) * 0.01,
        size: 1 + _random.nextDouble() * 2,
        life: _random.nextDouble(),
        maxLife: 0.5 + _random.nextDouble() * 0.5,
      ));
    }
  }

  void _updateParticles() {
    if (!mounted) return;

    for (final p in _particles) {
      p.life -= 0.016;
      if (p.life <= 0) {
        // Respawn particle
        if (_isHovered) {
          p.x = _random.nextDouble();
          p.y = _random.nextDouble();
          p.vx = (_random.nextDouble() - 0.5) * 0.02;
          p.vy = (_random.nextDouble() - 0.5) * 0.02;
          p.life = p.maxLife;
        }
      } else {
        p.x += p.vx;
        p.y += p.vy;
        // Boundary wrap
        if (p.x < 0) p.x = 1;
        if (p.x > 1) p.x = 0;
        if (p.y < 0) p.y = 1;
        if (p.y > 1) p.y = 0;
      }
    }

    // Random glitch trigger
    if (_isHovered && _random.nextDouble() > 0.995) {
      _showGlitch = true;
      _glitchOffset = (_random.nextDouble() - 0.5) * 8;
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) setState(() => _showGlitch = false);
      });
    }
  }

  void _updateElectricArcs() {
    if (!mounted || !_isHovered) {
      _arcs.clear();
      return;
    }

    // Generate new arcs randomly
    if (_random.nextDouble() > 0.9 && _arcs.length < 3) {
      _arcs.add(_ElectricArc(
        startX: _random.nextDouble(),
        startY: _random.nextBool() ? 0 : 1,
        segments: 4 + _random.nextInt(4),
        life: 0.1 + _random.nextDouble() * 0.1,
        intensity: 0.5 + _random.nextDouble() * 0.5,
      ));
    }

    // Update existing arcs
    _arcs.removeWhere((arc) {
      arc.life -= 0.016;
      return arc.life <= 0;
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _borderPulseController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    _electricController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.enabled ? widget.color : Colors.grey;
    final secondaryColor = widget.secondaryColor ?? NeonColors.magenta;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _arcs.clear();
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (widget.enabled) {
            AudioService.instance.playButton();
            widget.onPressed();
          }
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _glowAnimation,
            _borderPulseController,
            _shimmerController,
            _particleController,
          ]),
          builder: (context, child) {
            final glowIntensity = _isHovered ? 1.0 : _glowAnimation.value;
            final scale = _isPressed ? 0.95 : (_isHovered ? 1.03 : 1.0);

            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: CustomPaint(
                  painter: _EpicNeonButtonPainter(
                    color: effectiveColor,
                    secondaryColor: secondaryColor,
                    glowIntensity: glowIntensity,
                    borderPulseProgress: _borderPulseController.value,
                    shimmerProgress: _shimmerController.value,
                    isHovered: _isHovered,
                    isPressed: _isPressed,
                    particles: _particles,
                    arcs: _arcs,
                    showGlitch: _showGlitch,
                    glitchOffset: _glitchOffset,
                  ),
                  child: Center(
                    child: _showGlitch
                        ? _buildGlitchedText(effectiveColor, secondaryColor, glowIntensity)
                        : _buildText(effectiveColor, glowIntensity),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildText(Color color, double glowIntensity) {
    return Text(
      widget.text,
      style: NeonTextStyles.button.copyWith(
        color: color,
        shadows: [
          Shadow(color: color.withOpacity(glowIntensity), blurRadius: 8),
          Shadow(color: color.withOpacity(glowIntensity * 0.5), blurRadius: 16),
          Shadow(color: color.withOpacity(glowIntensity * 0.3), blurRadius: 32),
        ],
      ),
    );
  }

  Widget _buildGlitchedText(Color color, Color secondary, double glowIntensity) {
    return Stack(
      children: [
        Transform.translate(
          offset: Offset(_glitchOffset, 0),
          child: Text(
            widget.text,
            style: NeonTextStyles.button.copyWith(
              color: NeonColors.cyan.withOpacity(0.5),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(-_glitchOffset, 0),
          child: Text(
            widget.text,
            style: NeonTextStyles.button.copyWith(
              color: NeonColors.red.withOpacity(0.5),
            ),
          ),
        ),
        _buildText(color, glowIntensity),
      ],
    );
  }
}

class _Particle {
  double x, y, vx, vy, size, life, maxLife;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.maxLife,
  });
}

class _ElectricArc {
  double startX;
  double startY;
  int segments;
  double life;
  double intensity;

  _ElectricArc({
    required this.startX,
    required this.startY,
    required this.segments,
    required this.life,
    required this.intensity,
  });
}

class _EpicNeonButtonPainter extends CustomPainter {
  _EpicNeonButtonPainter({
    required this.color,
    required this.secondaryColor,
    required this.glowIntensity,
    required this.borderPulseProgress,
    required this.shimmerProgress,
    required this.isHovered,
    required this.isPressed,
    required this.particles,
    required this.arcs,
    required this.showGlitch,
    required this.glitchOffset,
  });

  final Color color;
  final Color secondaryColor;
  final double glowIntensity;
  final double borderPulseProgress;
  final double shimmerProgress;
  final bool isHovered;
  final bool isPressed;
  final List<_Particle> particles;
  final List<_ElectricArc> arcs;
  final bool showGlitch;
  final double glitchOffset;

  final _random = math.Random(42);

  // Reusable Paint objects - avoids ~80+ allocations per frame.
  // Safe because painting is single-threaded; properties reset before each use.
  static final Paint _fp = Paint();
  static final Paint _sp = Paint()..style = PaintingStyle.stroke;

  // Cached MaskFilter instances (const - zero allocation)
  static const MaskFilter _blur2 = MaskFilter.blur(BlurStyle.normal, 2);
  static const MaskFilter _blur3 = MaskFilter.blur(BlurStyle.normal, 3);
  static const MaskFilter _blur4 = MaskFilter.blur(BlurStyle.normal, 4);
  static const MaskFilter _blur6 = MaskFilter.blur(BlurStyle.normal, 6);
  static const MaskFilter _blur10 = MaskFilter.blur(BlurStyle.normal, 10);
  static const MaskFilter _blur15 = MaskFilter.blur(BlurStyle.normal, 15);

  // Cached constant colors
  static final Color _darkBg90 = NeonColors.darkBg.withOpacity(0.9);
  static final Color _redAberration = const Color(0xFFFF0000).withOpacity(0.15);
  static final Color _cyanAberration = const Color(0xFF00FFFF).withOpacity(0.15);

  @override
  void paint(Canvas canvas, Size size) {
    // Reset shared paints to safe default state
    _fp.shader = null;
    _fp.maskFilter = null;
    _sp.maskFilter = null;
    _sp.strokeCap = StrokeCap.butt;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    // LAYER 1: Deep outer glow (multiple layers)
    _drawDeepGlow(canvas, rect, rrect);

    // LAYER 2: Background with energy field
    _drawBackground(canvas, rect, rrect);

    // LAYER 3: Data circuit pattern
    _drawCircuitPattern(canvas, size);

    // LAYER 4: Energy grid
    _drawEnergyGrid(canvas, size);

    // LAYER 5: Holographic interference
    _drawHolographicInterference(canvas, size);

    // LAYER 6: Shimmer wave
    _drawShimmerWave(canvas, size);

    // LAYER 7: Particle system
    _drawParticles(canvas, size);

    // LAYER 8: Electric arcs
    _drawElectricArcs(canvas, size);

    // LAYER 9: Multi-pulse border
    _drawMultiPulseBorder(canvas, rrect, size);

    // LAYER 10: Energy ripples
    if (isHovered) {
      _drawEnergyRipples(canvas, size);
    }

    // LAYER 11: Corner energy nodes
    _drawCornerNodes(canvas, size);

    // LAYER 12: Scanlines
    _drawScanlines(canvas, size);

    // LAYER 13: Chromatic aberration on edges
    if (isHovered || isPressed) {
      _drawChromaticAberration(canvas, size);
    }

    // LAYER 14: Glitch overlay
    if (showGlitch) {
      _drawGlitchEffect(canvas, size);
    }

    // LAYER 15: Final outer glow
    _drawFinalGlow(canvas, rrect);
  }

  void _drawDeepGlow(Canvas canvas, Rect rect, RRect rrect) {
    for (int i = 3; i >= 0; i--) {
      final glowRadius = 20.0 + i * 8;
      final glowOpacity = glowIntensity * (0.1 - i * 0.02);
      if (glowOpacity > 0) {
        _fp.color = color.withOpacity(glowOpacity);
        _fp.maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);
        canvas.drawRRect(rrect.inflate(glowRadius), _fp);
      }
    }
    _fp.maskFilter = null;
  }

  void _drawBackground(Canvas canvas, Rect rect, RRect rrect) {
    _fp.color = _darkBg90;
    canvas.drawRRect(rrect, _fp);

    final gradientOpacity = isHovered ? 0.15 : 0.05;
    _fp.shader = ui.Gradient.linear(
      rect.topLeft,
      rect.bottomRight,
      [
        color.withOpacity(gradientOpacity),
        Colors.transparent,
        secondaryColor.withOpacity(gradientOpacity * 0.5),
      ],
      [0.0, 0.5, 1.0],
    );
    canvas.drawRRect(rrect, _fp);
    _fp.shader = null;

    if (isHovered) {
      final center = rect.center;
      _fp.shader = ui.Gradient.radial(
        center,
        rect.width * 0.6,
        [
          color.withOpacity(0.1),
          color.withOpacity(0.05),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );
      canvas.drawRRect(rrect, _fp);
      _fp.shader = null;
    }
  }

  void _drawCircuitPattern(Canvas canvas, Size size) {
    _sp.color = color.withOpacity(0.04 + glowIntensity * 0.03);
    _sp.strokeWidth = 0.5;

    for (int i = 1; i <= 4; i++) {
      final y = size.height * i / 5;
      final startX = 10.0 + (i % 2) * 15;
      final endX = size.width - 10 - ((i + 1) % 2) * 20;
      canvas.drawLine(Offset(startX, y), Offset(endX, y), _sp);

      for (double x = startX + 20; x < endX - 20; x += 25) {
        if ((x.toInt() + i) % 3 == 0) {
          canvas.drawLine(Offset(x, y - 3), Offset(x, y + 3), _sp);
        }
      }
    }

    for (int i = 1; i <= 5; i++) {
      final x = size.width * i / 6;
      final startY = 8.0 + (i % 2) * 10;
      final endY = size.height - 8 - ((i + 1) % 2) * 10;

      if (i % 2 == 0) {
        canvas.drawLine(Offset(x, startY), Offset(x, endY), _sp);
      }
    }

    final nodeColor = color.withOpacity(0.08 + glowIntensity * 0.06);
    final nodePositions = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.8, size.height * 0.7),
      Offset(size.width * 0.3, size.height * 0.8),
      Offset(size.width * 0.7, size.height * 0.2),
    ];

    for (final pos in nodePositions) {
      final pulsePhase = (borderPulseProgress + pos.dx / size.width) % 1.0;
      final nodeOpacity = 0.2 + math.sin(pulsePhase * math.pi * 2) * 0.15;

      _fp.color = color.withOpacity(nodeOpacity);
      _fp.maskFilter = _blur3;
      canvas.drawCircle(pos, 3, _fp);
      _fp.maskFilter = null;
      _fp.color = nodeColor;
      canvas.drawCircle(pos, 1.5, _fp);
    }
  }

  void _drawEnergyGrid(Canvas canvas, Size size) {
    if (!isHovered) return;

    _sp.color = color.withOpacity(0.03);
    _sp.strokeWidth = 0.3;

    const gridSpacing = 15.0;
    for (double d = -size.height; d < size.width + size.height; d += gridSpacing) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        _sp,
      );
      canvas.drawLine(
        Offset(d + size.height, 0),
        Offset(d, size.height),
        _sp,
      );
    }
  }

  void _drawHolographicInterference(Canvas canvas, Size size) {
    final bandY = (shimmerProgress * size.height * 2) % (size.height + 40) - 20;

    _fp.shader = ui.Gradient.linear(
      Offset(0, bandY - 15),
      Offset(0, bandY + 15),
      [
        Colors.transparent,
        color.withOpacity(0.06 * glowIntensity),
        secondaryColor.withOpacity(0.04 * glowIntensity),
        Colors.transparent,
      ],
      [0.0, 0.4, 0.6, 1.0],
    );

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    ));
    canvas.drawRect(
      Rect.fromLTWH(0, bandY - 15, size.width, 30),
      _fp,
    );
    canvas.restore();
    _fp.shader = null;

    final band2Y = ((shimmerProgress + 0.5) * size.height * 1.5) % (size.height + 30) - 15;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    ));
    _fp.color = secondaryColor.withOpacity(0.03 * glowIntensity);
    canvas.drawRect(
      Rect.fromLTWH(0, band2Y - 5, size.width, 10),
      _fp,
    );
    canvas.restore();
  }

  void _drawShimmerWave(Canvas canvas, Size size) {
    final shimmerX = shimmerProgress * (size.width + 100) - 50;

    _fp.shader = ui.Gradient.linear(
      Offset(shimmerX - 40, 0),
      Offset(shimmerX + 40, size.height),
      [
        Colors.transparent,
        secondaryColor.withOpacity(0.08 * glowIntensity),
        color.withOpacity(0.12 * glowIntensity),
        Colors.white.withOpacity(0.2 * glowIntensity),
        color.withOpacity(0.12 * glowIntensity),
        secondaryColor.withOpacity(0.08 * glowIntensity),
        Colors.transparent,
      ],
      [0.0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0],
    );

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    ));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      _fp,
    );
    canvas.restore();
    _fp.shader = null;
  }

  void _drawParticles(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.life <= 0 || p.maxLife <= 0) continue;

      final alpha = ((p.life / p.maxLife) * (isHovered ? 0.8 : 0.3)).clamp(0.0, 1.0);
      final pos = Offset(p.x * size.width, p.y * size.height);

      // Particle glow
      _fp.color = color.withOpacity((alpha * 0.3).clamp(0.0, 1.0));
      _fp.maskFilter = _blur4;
      canvas.drawCircle(pos, p.size * 2, _fp);

      // Particle core
      _fp.maskFilter = null;
      _fp.color = Colors.white.withOpacity(alpha);
      canvas.drawCircle(pos, p.size, _fp);
    }
  }

  void _drawElectricArcs(Canvas canvas, Size size) {
    for (final arc in arcs) {
      final path = Path();
      final startX = arc.startX * size.width;
      final startY = arc.startY * size.height;
      final endY = arc.startY == 0 ? size.height : 0;

      path.moveTo(startX, startY);

      double currentX = startX;
      double currentY = startY;
      final segmentHeight = (endY - startY) / arc.segments;

      for (int i = 1; i <= arc.segments; i++) {
        final jitterX = (i == arc.segments) ? 0 : (_random.nextDouble() - 0.5) * 30;
        currentY = startY + segmentHeight * i;
        currentX = startX + jitterX;
        path.lineTo(currentX, currentY);
      }

      // Arc glow
      _sp.color = color.withOpacity(arc.intensity * 0.4 * (arc.life * 10).clamp(0, 1));
      _sp.strokeWidth = 4;
      _sp.maskFilter = _blur6;
      canvas.drawPath(path, _sp);

      // Arc core
      _sp.color = Colors.white.withOpacity(arc.intensity * 0.8 * (arc.life * 10).clamp(0, 1));
      _sp.strokeWidth = 1.5;
      _sp.maskFilter = null;
      canvas.drawPath(path, _sp);
    }
  }

  void _drawMultiPulseBorder(Canvas canvas, RRect rrect, Size size) {
    // Base border
    _sp.color = color.withOpacity(glowIntensity * 0.7);
    _sp.strokeWidth = isHovered ? 2.5 : 1.5;
    canvas.drawRRect(rrect, _sp);

    final perimeter = 2 * (size.width + size.height);

    for (int pulseIndex = 0; pulseIndex < 4; pulseIndex++) {
      final pulseOffset = pulseIndex * 0.25;
      final pulseProgress = (borderPulseProgress + pulseOffset) % 1.0;
      final pulsePosition = pulseProgress * perimeter;
      final pulseLength = 50.0 + pulseIndex * 10;
      final pulseIntensity = 1.0 - pulseIndex * 0.2;

      final pulsePoints = _calculatePulsePoints(size, pulsePosition, pulseLength);

      if (pulsePoints.isNotEmpty) {
        final pulsePath = Path();
        pulsePath.moveTo(pulsePoints.first.dx, pulsePoints.first.dy);
        for (int i = 1; i < pulsePoints.length; i++) {
          pulsePath.lineTo(pulsePoints[i].dx, pulsePoints[i].dy);
        }

        final pulseColor = pulseIndex % 2 == 0 ? color : secondaryColor;

        // Glow
        _sp.color = pulseColor.withOpacity(0.5 * pulseIntensity);
        _sp.strokeWidth = 8;
        _sp.strokeCap = StrokeCap.round;
        _sp.maskFilter = _blur6;
        canvas.drawPath(pulsePath, _sp);

        // Core
        _sp.color = Colors.white.withOpacity(0.9 * pulseIntensity);
        _sp.strokeWidth = 2;
        _sp.maskFilter = null;
        canvas.drawPath(pulsePath, _sp);

        // Head point
        _fp.color = Colors.white;
        _fp.maskFilter = _blur3;
        canvas.drawCircle(pulsePoints.last, 4 * pulseIntensity, _fp);
        _fp.maskFilter = null;
      }
    }
    _sp.strokeCap = StrokeCap.butt;
  }

  List<Offset> _calculatePulsePoints(Size size, double position, double length) {
    final points = <Offset>[];
    final w = size.width;
    final h = size.height;

    double pos = position;
    double remaining = length;

    while (remaining > 0 && points.length < 100) {
      final normalizedPos = pos % (2 * (w + h));
      Offset point;

      if (normalizedPos < w) {
        point = Offset(normalizedPos, 0);
      } else if (normalizedPos < w + h) {
        point = Offset(w, normalizedPos - w);
      } else if (normalizedPos < 2 * w + h) {
        point = Offset(w - (normalizedPos - w - h), h);
      } else {
        point = Offset(0, h - (normalizedPos - 2 * w - h));
      }

      points.add(point);
      pos -= 3;
      remaining -= 3;
    }

    return points.reversed.toList();
  }

  void _drawEnergyRipples(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 3; i++) {
      final rippleProgress = (borderPulseProgress + i * 0.33) % 1.0;
      final radius = rippleProgress * size.width * 0.8;
      final alpha = (1 - rippleProgress) * 0.15;

      if (alpha > 0.01) {
        _sp.color = color.withOpacity(alpha);
        _sp.strokeWidth = 1.5;
        _sp.maskFilter = _blur2;
        canvas.drawCircle(center, radius, _sp);
      }
    }
    _sp.maskFilter = null;
  }

  void _drawCornerNodes(Canvas canvas, Size size) {
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];

    for (int i = 0; i < corners.length; i++) {
      final corner = corners[i];
      final pulsePhase = (borderPulseProgress + i * 0.25) % 1.0;
      final nodeIntensity = 0.5 + math.sin(pulsePhase * math.pi * 2) * 0.3;

      const bracketLength = 12.0;
      final xDir = corner.dx == 0 ? 1.0 : -1.0;
      final yDir = corner.dy == 0 ? 1.0 : -1.0;

      _sp.color = color.withOpacity(glowIntensity * 0.8);
      _sp.strokeWidth = 2;
      canvas.drawLine(corner, Offset(corner.dx + bracketLength * xDir, corner.dy), _sp);
      canvas.drawLine(corner, Offset(corner.dx, corner.dy + bracketLength * yDir), _sp);

      // Node glow
      _fp.color = color.withOpacity(0.3 * nodeIntensity);
      _fp.maskFilter = _blur4;
      canvas.drawCircle(corner, 6 * nodeIntensity, _fp);

      // Node core
      _fp.maskFilter = null;
      _fp.color = isHovered
          ? Colors.white.withOpacity(nodeIntensity)
          : color.withOpacity(nodeIntensity * 0.8);
      canvas.drawCircle(corner, 3, _fp);
    }
  }

  void _drawScanlines(Canvas canvas, Size size) {
    _fp.color = color.withOpacity(0.02 * glowIntensity);

    for (double y = 0; y < size.height; y += 2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _fp);
    }

    final scanY = (borderPulseProgress * size.height * 3) % (size.height + 20) - 10;
    _fp.color = color.withOpacity(0.08 * glowIntensity);
    canvas.drawRect(
      Rect.fromLTWH(0, scanY, size.width, 1),
      _fp,
    );
  }

  void _drawChromaticAberration(Canvas canvas, Size size) {
    final aberrationAmount = isPressed ? 3.0 : 1.5;

    _fp.color = _redAberration;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, aberrationAmount, size.height),
      _fp,
    );

    _fp.color = _cyanAberration;
    canvas.drawRect(
      Rect.fromLTWH(size.width - aberrationAmount, 0, aberrationAmount, size.height),
      _fp,
    );
  }

  void _drawGlitchEffect(Canvas canvas, Size size) {
    for (int i = 0; i < 3; i++) {
      final y = _random.nextDouble() * size.height;
      final barHeight = 2 + _random.nextDouble() * 6;
      final xOffset = glitchOffset * (1 + i * 0.5);

      _fp.color = color.withOpacity(0.3);
      canvas.drawRect(
        Rect.fromLTWH(xOffset, y, size.width, barHeight),
        _fp,
      );

      _fp.color = secondaryColor.withOpacity(0.2);
      canvas.drawRect(
        Rect.fromLTWH(-xOffset, y + 2, size.width, barHeight * 0.5),
        _fp,
      );
    }
  }

  void _drawFinalGlow(Canvas canvas, RRect rrect) {
    _sp.color = color.withOpacity(glowIntensity * 0.5);
    _sp.strokeWidth = isHovered ? 12 : 8;
    _sp.maskFilter = isHovered ? _blur15 : _blur10;
    canvas.drawRRect(rrect, _sp);
    _sp.maskFilter = null;
  }

  @override
  bool shouldRepaint(_EpicNeonButtonPainter oldDelegate) {
    // Quantize continuous animation values to reduce repaint frequency
    return oldDelegate.color != color ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isHovered != isHovered ||
        oldDelegate.isPressed != isPressed ||
        oldDelegate.showGlitch != showGlitch ||
        (oldDelegate.glowIntensity * 20).round() != (glowIntensity * 20).round() ||
        (oldDelegate.borderPulseProgress * 40).round() != (borderPulseProgress * 40).round() ||
        (oldDelegate.shimmerProgress * 30).round() != (shimmerProgress * 30).round();
  }
}
