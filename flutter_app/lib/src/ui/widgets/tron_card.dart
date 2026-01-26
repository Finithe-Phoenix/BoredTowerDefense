import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// EPIC TRON-style card with 15+ visual layers of effects
/// Features: Particle systems, electric arcs, holographic interference,
/// data streams, energy fields, power cores, scanlines, chromatic aberration
class TronCard extends StatefulWidget {
  const TronCard({
    super.key,
    required this.child,
    this.color = NeonColors.cyan,
    this.secondaryColor,
    this.delay = Duration.zero,
    this.materializationDuration = const Duration(milliseconds: 500),
    this.width,
    this.height,
    this.onTap,
    this.borderRadius = 12.0,
    this.enabled = true,
  });

  final Widget child;
  final Color color;
  final Color? secondaryColor;
  final Duration delay;
  final Duration materializationDuration;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool enabled;

  @override
  State<TronCard> createState() => _TronCardState();
}

class _TronCardState extends State<TronCard>
    with TickerProviderStateMixin {
  // Core animation controllers
  late AnimationController _materializeController;
  late AnimationController _pulseController;
  late AnimationController _hoverController;

  // Advanced effect controllers
  late AnimationController _particleController;
  late AnimationController _electricController;
  late AnimationController _dataStreamController;
  late AnimationController _glitchController;

  late Animation<double> _materializeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _hoverAnimation;

  bool _isHovered = false;
  bool _isPressed = false;
  bool _isMaterialized = false;

  // Particle system
  final List<_CardParticle> _particles = [];
  final math.Random _random = math.Random();

  // Electric arc system
  final List<_ElectricArc> _electricArcs = [];

  // Data stream system
  final List<_DataStream> _dataStreams = [];

  // Glitch effect
  double _glitchOffset = 0;
  bool _glitchActive = false;

  @override
  void initState() {
    super.initState();

    _initializeParticles();
    _initializeDataStreams();

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

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_pulseController);

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..addListener(_updateParticles);

    // Electric arc animation
    _electricController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..addListener(_updateElectricArcs);

    // Data stream animation
    _dataStreamController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..addListener(_updateDataStreams);

    // Glitch controller
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..addListener(_updateGlitch);

    Future.delayed(widget.delay, () {
      if (mounted) {
        _materializeController.forward();
        _pulseController.repeat();
        _particleController.repeat();
        _dataStreamController.repeat();
      }
    });
  }

  void _initializeParticles() {
    for (int i = 0; i < 30; i++) {
      _particles.add(_CardParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        vx: (_random.nextDouble() - 0.5) * 0.003,
        vy: (_random.nextDouble() - 0.5) * 0.003,
        size: _random.nextDouble() * 2 + 0.5,
        opacity: _random.nextDouble() * 0.5 + 0.2,
        type: _random.nextInt(3),
      ));
    }
  }

  void _initializeDataStreams() {
    for (int i = 0; i < 8; i++) {
      _dataStreams.add(_DataStream(
        position: _random.nextDouble(),
        speed: _random.nextDouble() * 0.02 + 0.01,
        length: _random.nextDouble() * 0.15 + 0.05,
        isVertical: _random.nextBool(),
        side: _random.nextInt(4),
      ));
    }
  }

  void _updateParticles() {
    if (!mounted) return;
    for (final particle in _particles) {
      particle.x += particle.vx;
      particle.y += particle.vy;

      // Wrap around
      if (particle.x < 0) particle.x = 1;
      if (particle.x > 1) particle.x = 0;
      if (particle.y < 0) particle.y = 1;
      if (particle.y > 1) particle.y = 0;

      // Pulsate opacity
      particle.opacity = 0.2 + math.sin(DateTime.now().millisecondsSinceEpoch * 0.005 + particle.x * 10) * 0.3;
    }
    setState(() {});
  }

  void _updateElectricArcs() {
    if (!mounted || !_isHovered) return;

    // Randomly generate new arcs
    if (_random.nextDouble() < 0.3) {
      final side = _random.nextInt(4);
      _electricArcs.add(_ElectricArc(
        startPos: _random.nextDouble(),
        side: side,
        segments: List.generate(6, (_) => _random.nextDouble() * 0.04 - 0.02),
        life: 1.0,
      ));
    }

    // Update and remove dead arcs
    for (int i = _electricArcs.length - 1; i >= 0; i--) {
      _electricArcs[i].life -= 0.15;
      if (_electricArcs[i].life <= 0) {
        _electricArcs.removeAt(i);
      }
    }
    setState(() {});
  }

  void _updateDataStreams() {
    if (!mounted) return;
    for (final stream in _dataStreams) {
      stream.position += stream.speed;
      if (stream.position > 1.0 + stream.length) {
        stream.position = -stream.length;
      }
    }
    setState(() {});
  }

  void _updateGlitch() {
    if (!mounted) return;
    if (_glitchActive) {
      _glitchOffset = (_random.nextDouble() - 0.5) * 4;
      if (_random.nextDouble() < 0.2) {
        _glitchActive = false;
        _glitchController.stop();
      }
    }
    setState(() {});
  }

  void _triggerGlitch() {
    if (!_glitchActive && _random.nextDouble() < 0.1) {
      _glitchActive = true;
      _glitchController.repeat();
      Future.delayed(Duration(milliseconds: 50 + _random.nextInt(100)), () {
        if (mounted) {
          _glitchActive = false;
          _glitchOffset = 0;
          _glitchController.stop();
        }
      });
    }
  }

  @override
  void dispose() {
    _materializeController.dispose();
    _pulseController.dispose();
    _hoverController.dispose();
    _particleController.dispose();
    _electricController.dispose();
    _dataStreamController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    if (!_isMaterialized || !widget.enabled) return;
    setState(() => _isHovered = hovering);
    if (hovering) {
      _hoverController.forward();
      _electricController.repeat();
    } else {
      _hoverController.reverse();
      _electricController.stop();
      _electricArcs.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.enabled ? widget.color : Colors.grey;
    final secondaryColor = widget.secondaryColor ?? const Color(0xFFFF6600);

    // Occasionally trigger glitch
    if (_isMaterialized && _random.nextDouble() < 0.002) {
      _triggerGlitch();
    }

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTapDown: (_) {
          if (_isMaterialized && widget.enabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (_isMaterialized && widget.enabled) {
            setState(() => _isPressed = false);
            widget.onTap?.call();
          }
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _materializeAnimation,
            _pulseAnimation,
            _hoverAnimation,
          ]),
          builder: (context, child) {
            final progress = _materializeAnimation.value;
            final pulseValue = _pulseAnimation.value;
            final hoverValue = _hoverAnimation.value;
            final scale = _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0);

            return Transform.scale(
              scale: scale,
              child: Transform.translate(
                offset: Offset(_glitchOffset, 0),
                child: SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: CustomPaint(
                    painter: _EpicTronCardPainter(
                      progress: progress,
                      pulseValue: pulseValue,
                      hoverValue: hoverValue,
                      primaryColor: effectiveColor,
                      secondaryColor: secondaryColor,
                      isHovered: _isHovered,
                      borderRadius: widget.borderRadius,
                      particles: _particles,
                      electricArcs: _electricArcs,
                      dataStreams: _dataStreams,
                      glitchActive: _glitchActive,
                      glitchOffset: _glitchOffset,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      child: Opacity(
                        opacity: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: NeonColors.darkBg.withOpacity(0.9 * progress),
                            borderRadius: BorderRadius.circular(widget.borderRadius),
                          ),
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EpicTronCardPainter extends CustomPainter {
  _EpicTronCardPainter({
    required this.progress,
    required this.pulseValue,
    required this.hoverValue,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isHovered,
    required this.borderRadius,
    required this.particles,
    required this.electricArcs,
    required this.dataStreams,
    required this.glitchActive,
    required this.glitchOffset,
  });

  final double progress;
  final double pulseValue;
  final double hoverValue;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isHovered;
  final double borderRadius;
  final List<_CardParticle> particles;
  final List<_ElectricArc> electricArcs;
  final List<_DataStream> dataStreams;
  final bool glitchActive;
  final double glitchOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Save for clipping effects
    canvas.save();
    canvas.clipRRect(rrect);

    // ========== LAYER 1: Deep outer glow ==========
    _drawOuterGlow(canvas, rrect, size);

    // ========== LAYER 2: Energy field background ==========
    _drawEnergyField(canvas, size);

    // ========== LAYER 3: Data matrix pattern ==========
    _drawDataMatrix(canvas, size);

    // ========== LAYER 4: Holographic interference ==========
    _drawHolographicInterference(canvas, size);

    // ========== LAYER 5: Power grid ==========
    _drawPowerGrid(canvas, size);

    // ========== LAYER 6: Particle system ==========
    _drawParticles(canvas, size);

    // ========== LAYER 7: Data streams ==========
    _drawDataStreams(canvas, size);

    canvas.restore();

    // ========== LAYER 8: Wireframe construction ==========
    _drawWireframe(canvas, size);

    // ========== LAYER 9: Multi-layer border ==========
    _drawMultiLayerBorder(canvas, rrect, size);

    // ========== LAYER 10: Electric arcs ==========
    _drawElectricArcs(canvas, size);

    // ========== LAYER 11: Energy pulses on border ==========
    _drawEnergyPulses(canvas, rrect, size);

    // ========== LAYER 12: Corner power nodes ==========
    _drawCornerPowerNodes(canvas, size);

    // ========== LAYER 13: Scanlines ==========
    _drawScanlines(canvas, size, rrect);

    // ========== LAYER 14: Chromatic aberration ==========
    if (glitchActive) {
      _drawChromaticAberration(canvas, rrect, size);
    }

    // ========== LAYER 15: Corner energy connectors ==========
    _drawEnergyConnectors(canvas, size);
  }

  void _drawOuterGlow(Canvas canvas, RRect rrect, Size size) {
    if (progress < 0.3) return;

    final glowProgress = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);
    final glowIntensity = isHovered ? 1.0 : (0.4 + math.sin(pulseValue * math.pi * 2) * 0.3);

    // Multiple glow layers
    for (int i = 4; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = primaryColor.withOpacity(glowProgress * glowIntensity * 0.08 * (5 - i) / 4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 * i
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 * i);
      canvas.drawRRect(rrect, glowPaint);
    }

    // Secondary color glow when hovered
    if (isHovered) {
      final hoverGlowPaint = Paint()
        ..color = secondaryColor.withOpacity(glowProgress * hoverValue * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawRRect(rrect, hoverGlowPaint);
    }
  }

  void _drawEnergyField(Canvas canvas, Size size) {
    if (progress < 0.5) return;

    final fieldProgress = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
    final time = pulseValue * math.pi * 2;

    // Radial energy waves
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;

    for (int i = 0; i < 4; i++) {
      final waveOffset = (time + i * math.pi / 2) % (math.pi * 2);
      final waveRadius = (waveOffset / (math.pi * 2)) * maxRadius;

      final wavePaint = Paint()
        ..color = primaryColor.withOpacity(fieldProgress * 0.03 * (1 - waveOffset / (math.pi * 2)))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(center, waveRadius, wavePaint);
    }
  }

  void _drawDataMatrix(Canvas canvas, Size size) {
    if (progress < 0.6) return;

    final matrixProgress = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
    final padding = 15.0;

    final matrixPaint = Paint()
      ..color = primaryColor.withOpacity(matrixProgress * 0.04)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Hexagonal grid pattern
    final hexSize = 20.0;
    final hexHeight = hexSize * math.sqrt(3);

    for (double y = padding; y < size.height - padding; y += hexHeight * 0.75) {
      for (double x = padding; x < size.width - padding; x += hexSize * 1.5) {
        final offsetX = ((y ~/ (hexHeight * 0.75)) % 2 == 0) ? 0.0 : hexSize * 0.75;
        _drawHexagon(canvas, Offset(x + offsetX, y), hexSize * 0.4, matrixPaint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHolographicInterference(Canvas canvas, Size size) {
    if (progress < 0.7 || !isHovered) return;

    final holoProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0) * hoverValue;
    final time = pulseValue * math.pi * 2;

    // Interference bands
    for (int i = 0; i < 12; i++) {
      final bandY = (time * 0.5 + i * size.height / 12) % size.height;
      final bandOpacity = math.sin((bandY / size.height) * math.pi) * holoProgress * 0.08;

      final bandPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, bandY),
          Offset(size.width, bandY),
          [
            primaryColor.withOpacity(0),
            primaryColor.withOpacity(bandOpacity),
            secondaryColor.withOpacity(bandOpacity),
            primaryColor.withOpacity(0),
          ],
          [0.0, 0.3, 0.7, 1.0],
        );

      canvas.drawRect(
        Rect.fromLTWH(0, bandY - 2, size.width, 4),
        bandPaint,
      );
    }
  }

  void _drawPowerGrid(Canvas canvas, Size size) {
    if (progress < 0.5) return;

    final gridProgress = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
    final time = pulseValue * math.pi * 2;
    final padding = 10.0;

    final gridPaint = Paint()
      ..color = primaryColor.withOpacity(gridProgress * 0.06)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = secondaryColor.withOpacity(gridProgress * 0.08)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Vertical lines
    final vSpacing = (size.width - padding * 2) / 8;
    for (int i = 0; i <= 8; i++) {
      final x = padding + i * vSpacing;
      final brightness = math.sin(time + i * 0.5) * 0.5 + 0.5;
      final paint = brightness > 0.7 ? accentPaint : gridPaint;
      canvas.drawLine(Offset(x, padding), Offset(x, size.height - padding), paint);
    }

    // Horizontal lines
    final hSpacing = (size.height - padding * 2) / 6;
    for (int i = 0; i <= 6; i++) {
      final y = padding + i * hSpacing;
      final brightness = math.sin(time + i * 0.7) * 0.5 + 0.5;
      final paint = brightness > 0.7 ? accentPaint : gridPaint;
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), paint);
    }

    // Grid intersection nodes
    final nodePaint = Paint()
      ..color = primaryColor.withOpacity(gridProgress * 0.15);

    for (int i = 0; i <= 8; i++) {
      for (int j = 0; j <= 6; j++) {
        final x = padding + i * vSpacing;
        final y = padding + j * hSpacing;
        final nodePhase = math.sin(time * 2 + i + j);
        if (nodePhase > 0.5) {
          canvas.drawCircle(Offset(x, y), 1.5, nodePaint);
        }
      }
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    if (progress < 0.7) return;

    final particleProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);

    for (final particle in particles) {
      final x = particle.x * size.width;
      final y = particle.y * size.height;

      Color particleColor;
      switch (particle.type) {
        case 0:
          particleColor = primaryColor;
          break;
        case 1:
          particleColor = secondaryColor;
          break;
        default:
          particleColor = Colors.white;
      }

      // Particle glow
      canvas.drawCircle(
        Offset(x, y),
        particle.size * 2,
        Paint()
          ..color = particleColor.withOpacity(particle.opacity * particleProgress * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Particle core
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        Paint()..color = particleColor.withOpacity(particle.opacity * particleProgress),
      );
    }
  }

  void _drawDataStreams(Canvas canvas, Size size) {
    if (progress < 0.8) return;

    final streamProgress = ((progress - 0.8) / 0.2).clamp(0.0, 1.0);

    for (final stream in dataStreams) {
      Offset start, end;

      switch (stream.side) {
        case 0: // Top
          start = Offset(stream.position * size.width, 5);
          end = Offset((stream.position + stream.length) * size.width, 5);
          break;
        case 1: // Right
          start = Offset(size.width - 5, stream.position * size.height);
          end = Offset(size.width - 5, (stream.position + stream.length) * size.height);
          break;
        case 2: // Bottom
          start = Offset(stream.position * size.width, size.height - 5);
          end = Offset((stream.position + stream.length) * size.width, size.height - 5);
          break;
        default: // Left
          start = Offset(5, stream.position * size.height);
          end = Offset(5, (stream.position + stream.length) * size.height);
      }

      final streamPaint = Paint()
        ..shader = ui.Gradient.linear(
          start,
          end,
          [
            primaryColor.withOpacity(0),
            primaryColor.withOpacity(streamProgress * 0.6),
            Colors.white.withOpacity(streamProgress * 0.8),
          ],
          [0.0, 0.5, 1.0],
        )
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawLine(start, end, streamPaint);
    }
  }

  void _drawWireframe(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 0.8) return;

    final center = Offset(size.width / 2, size.height / 2);
    final wireframeFade = progress >= 0.6
        ? 1.0 - ((progress - 0.6) / 0.2).clamp(0.0, 1.0)
        : 1.0;

    if (wireframeFade <= 0) return;

    final lines = [
      _CardLine(center, Offset(0, center.dy), 0.0, 0.3),
      _CardLine(center, Offset(size.width, center.dy), 0.0, 0.3),
      _CardLine(center, Offset(center.dx, 0), 0.05, 0.35),
      _CardLine(center, Offset(center.dx, size.height), 0.05, 0.35),
      _CardLine(center, Offset.zero, 0.1, 0.4),
      _CardLine(center, Offset(size.width, 0), 0.1, 0.4),
      _CardLine(center, Offset(0, size.height), 0.1, 0.4),
      _CardLine(center, Offset(size.width, size.height), 0.1, 0.4),
    ];

    for (final line in lines) {
      if (progress >= line.startTime) {
        final lineProgress = progress >= line.endTime
            ? 1.0
            : ((progress - line.startTime) / (line.endTime - line.startTime)).clamp(0.0, 1.0);

        final currentEnd = Offset.lerp(line.start, line.end, lineProgress)!;

        // Glow
        canvas.drawLine(line.start, currentEnd, Paint()
          ..color = primaryColor.withOpacity(0.2 * wireframeFade)
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

        // Line
        canvas.drawLine(line.start, currentEnd, Paint()
          ..color = primaryColor.withOpacity(0.5 * wireframeFade)
          ..strokeWidth = 1);

        // Trail point
        if (lineProgress > 0 && lineProgress < 1) {
          canvas.drawCircle(currentEnd, 3, Paint()
            ..color = Colors.white.withOpacity(wireframeFade)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
        }
      }
    }
  }

  void _drawMultiLayerBorder(Canvas canvas, RRect rrect, Size size) {
    if (progress < 0.4) return;

    final borderProgress = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
    final pulseIntensity = isHovered ? 1.0 : (0.5 + math.sin(pulseValue * math.pi * 2) * 0.3);

    // Inner subtle border
    canvas.drawRRect(rrect.deflate(2), Paint()
      ..color = primaryColor.withOpacity(borderProgress * 0.15 * pulseIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);

    // Main border
    canvas.drawRRect(rrect, Paint()
      ..color = primaryColor.withOpacity(borderProgress * (isHovered ? 0.9 : 0.6) * pulseIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovered ? 2.5 : 1.5);

    // Outer energy border
    if (isHovered) {
      canvas.drawRRect(rrect.inflate(2), Paint()
        ..color = secondaryColor.withOpacity(borderProgress * hoverValue * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
  }

  void _drawElectricArcs(Canvas canvas, Size size) {
    if (!isHovered) return;

    for (final arc in electricArcs) {
      final arcOpacity = arc.life;

      Offset start;
      bool isHorizontal;

      switch (arc.side) {
        case 0: // Top
          start = Offset(arc.startPos * size.width, 0);
          isHorizontal = false;
          break;
        case 1: // Right
          start = Offset(size.width, arc.startPos * size.height);
          isHorizontal = true;
          break;
        case 2: // Bottom
          start = Offset(arc.startPos * size.width, size.height);
          isHorizontal = false;
          break;
        default: // Left
          start = Offset(0, arc.startPos * size.height);
          isHorizontal = true;
      }

      final path = Path()..moveTo(start.dx, start.dy);
      Offset current = start;

      final direction = arc.side == 1 ? -1.0 : (arc.side == 3 ? 1.0 : (arc.side == 0 ? 1.0 : -1.0));

      for (int i = 0; i < arc.segments.length; i++) {
        final segmentLength = 8.0 + i * 3;
        if (isHorizontal) {
          current = Offset(
            current.dx + direction * segmentLength,
            current.dy + arc.segments[i] * size.height,
          );
        } else {
          current = Offset(
            current.dx + arc.segments[i] * size.width,
            current.dy + direction * segmentLength,
          );
        }
        path.lineTo(current.dx, current.dy);
      }

      // Arc glow
      canvas.drawPath(path, Paint()
        ..color = primaryColor.withOpacity(arcOpacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

      // Arc core
      canvas.drawPath(path, Paint()
        ..color = Colors.white.withOpacity(arcOpacity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round);
    }
  }

  void _drawEnergyPulses(Canvas canvas, RRect rrect, Size size) {
    if (progress < 0.6) return;

    final pulseProgress = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);

    // 4 energy pulses traveling around the border
    for (int i = 0; i < 4; i++) {
      final pulsePhase = (pulseValue + i * 0.25) % 1.0;
      final perimeter = 2 * (size.width + size.height);
      final pulsePos = pulsePhase * perimeter;

      Offset position;
      if (pulsePos < size.width) {
        position = Offset(pulsePos, 0);
      } else if (pulsePos < size.width + size.height) {
        position = Offset(size.width, pulsePos - size.width);
      } else if (pulsePos < 2 * size.width + size.height) {
        position = Offset(size.width - (pulsePos - size.width - size.height), size.height);
      } else {
        position = Offset(0, size.height - (pulsePos - 2 * size.width - size.height));
      }

      // Pulse glow
      canvas.drawCircle(position, 8, Paint()
        ..color = (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(pulseProgress * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

      // Pulse core
      canvas.drawCircle(position, 3, Paint()
        ..color = Colors.white.withOpacity(pulseProgress * 0.9));
    }
  }

  void _drawCornerPowerNodes(Canvas canvas, Size size) {
    if (progress < 0.6) return;

    final cornerProgress = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
    final pulseIntensity = 0.5 + math.sin(pulseValue * math.pi * 4) * 0.5;

    final corners = [
      const Offset(6, 6),
      Offset(size.width - 6, 6),
      Offset(6, size.height - 6),
      Offset(size.width - 6, size.height - 6),
    ];

    const cornerSize = 20.0;

    for (int i = 0; i < corners.length; i++) {
      final corner = corners[i];
      final isActive = isHovered || (pulseIntensity > 0.7 && i % 2 == (pulseValue * 4).floor() % 2);

      // Corner brackets
      final bracketPaint = Paint()
        ..color = primaryColor.withOpacity(cornerProgress * (isHovered ? 0.9 : 0.6))
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final xDir = (i % 2 == 0) ? 1.0 : -1.0;
      final yDir = (i < 2) ? 1.0 : -1.0;

      // L-shaped bracket
      canvas.drawLine(
        corner,
        Offset(corner.dx + cornerSize * xDir * cornerProgress, corner.dy),
        bracketPaint,
      );
      canvas.drawLine(
        corner,
        Offset(corner.dx, corner.dy + cornerSize * yDir * cornerProgress),
        bracketPaint,
      );

      // Inner bracket
      final innerBracketPaint = Paint()
        ..color = secondaryColor.withOpacity(cornerProgress * 0.4 * pulseIntensity)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(corner.dx + 3 * xDir, corner.dy + 3 * yDir),
        Offset(corner.dx + (cornerSize - 5) * xDir * cornerProgress, corner.dy + 3 * yDir),
        innerBracketPaint,
      );
      canvas.drawLine(
        Offset(corner.dx + 3 * xDir, corner.dy + 3 * yDir),
        Offset(corner.dx + 3 * xDir, corner.dy + (cornerSize - 5) * yDir * cornerProgress),
        innerBracketPaint,
      );

      // Power node
      if (isActive) {
        // Outer glow
        canvas.drawCircle(corner, 8 * cornerProgress, Paint()
          ..color = primaryColor.withOpacity(cornerProgress * 0.3 * pulseIntensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

        // Middle glow
        canvas.drawCircle(corner, 5 * cornerProgress, Paint()
          ..color = primaryColor.withOpacity(cornerProgress * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

        // Inner glow
        canvas.drawCircle(corner, 3 * cornerProgress, Paint()
          ..color = Colors.white.withOpacity(cornerProgress * 0.7));
      } else {
        // Dim node
        canvas.drawCircle(corner, 2 * cornerProgress, Paint()
          ..color = primaryColor.withOpacity(cornerProgress * 0.4));
      }
    }
  }

  void _drawScanlines(Canvas canvas, Size size, RRect rrect) {
    if (progress < 0.8) return;

    final scanProgress = ((progress - 0.8) / 0.2).clamp(0.0, 1.0);

    canvas.save();
    canvas.clipRRect(rrect);

    // Subtle horizontal scanlines
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()..color = Colors.black.withOpacity(scanProgress * 0.03),
      );
    }

    // Moving scan line
    final scanY = (pulseValue * size.height * 2) % (size.height * 2);
    if (scanY < size.height) {
      canvas.drawRect(
        Rect.fromLTWH(0, scanY, size.width, 2),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, scanY),
            Offset(size.width, scanY),
            [
              primaryColor.withOpacity(0),
              primaryColor.withOpacity(scanProgress * 0.15),
              primaryColor.withOpacity(0),
            ],
            [0.0, 0.5, 1.0],
          ),
      );
    }

    canvas.restore();
  }

  void _drawChromaticAberration(Canvas canvas, RRect rrect, Size size) {
    // Red channel offset
    canvas.drawRRect(rrect.shift(Offset(-glitchOffset * 0.5, 0)), Paint()
      ..color = Colors.red.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..blendMode = BlendMode.screen);

    // Blue channel offset
    canvas.drawRRect(rrect.shift(Offset(glitchOffset * 0.5, 0)), Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..blendMode = BlendMode.screen);
  }

  void _drawEnergyConnectors(Canvas canvas, Size size) {
    if (progress < 0.7 || !isHovered) return;

    final connectorProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0) * hoverValue;

    final corners = [
      const Offset(6, 6),
      Offset(size.width - 6, 6),
      Offset(6, size.height - 6),
      Offset(size.width - 6, size.height - 6),
    ];

    // Diagonal connections
    final connectionPaint = Paint()
      ..color = secondaryColor.withOpacity(connectorProgress * 0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawLine(corners[0], corners[3], connectionPaint);
    canvas.drawLine(corners[1], corners[2], connectionPaint);

    // Center node
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 4, Paint()
      ..color = secondaryColor.withOpacity(connectorProgress * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(center, 2, Paint()
      ..color = Colors.white.withOpacity(connectorProgress * 0.5));
  }

  @override
  bool shouldRepaint(_EpicTronCardPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        pulseValue != oldDelegate.pulseValue ||
        hoverValue != oldDelegate.hoverValue ||
        isHovered != oldDelegate.isHovered ||
        glitchActive != oldDelegate.glitchActive ||
        glitchOffset != oldDelegate.glitchOffset ||
        particles != oldDelegate.particles ||
        electricArcs != oldDelegate.electricArcs ||
        dataStreams != oldDelegate.dataStreams;
  }
}

// Particle class
class _CardParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;
  int type;

  _CardParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
    required this.type,
  });
}

// Electric arc class
class _ElectricArc {
  double startPos;
  int side;
  List<double> segments;
  double life;

  _ElectricArc({
    required this.startPos,
    required this.side,
    required this.segments,
    required this.life,
  });
}

// Data stream class
class _DataStream {
  double position;
  double speed;
  double length;
  bool isVertical;
  int side;

  _DataStream({
    required this.position,
    required this.speed,
    required this.length,
    required this.isVertical,
    required this.side,
  });
}

// Wireframe line class
class _CardLine {
  final Offset start;
  final Offset end;
  final double startTime;
  final double endTime;

  _CardLine(this.start, this.end, this.startTime, this.endTime);
}
