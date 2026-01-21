import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

/// Epic animated title with hologram effect, glitch corruption, chromatic aberration,
/// electric arcs, scanner line, and energy pulse
class EpicNeonTitle extends StatefulWidget {
  const EpicNeonTitle({
    super.key,
    required this.text,
    this.fontSize = 56,
    this.primaryColor = NeonColors.cyan,
    this.secondaryColor = NeonColors.magenta,
  });

  final String text;
  final double fontSize;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  State<EpicNeonTitle> createState() => _EpicNeonTitleState();
}

class _EpicNeonTitleState extends State<EpicNeonTitle>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glitchController;
  late AnimationController _scanController;
  late AnimationController _electricController;
  late AnimationController _hologramController;
  late AnimationController _corruptionController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;
  late Animation<double> _hologramAnimation;

  double _glitchOffset = 0;
  double _glitchVertical = 0;
  bool _showGlitch = false;
  bool _showCorruption = false;
  int _corruptedCharIndex = -1;
  final _random = math.Random();
  Timer? _glitchTimer;
  Timer? _corruptionTimer;

  // Electric arc points
  List<_ElectricArc> _arcs = [];

  @override
  void initState() {
    super.initState();

    // Pulse animation - breathing glow effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Glitch effect controller
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _glitchController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showGlitch = false;
          _glitchOffset = 0;
          _glitchVertical = 0;
        });
      }
    });

    // Random glitch trigger
    _triggerRandomGlitch();

    // Scanner line - sweeps across
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(begin: -0.1, end: 1.1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );

    // Electric arcs controller
    _electricController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..repeat();
    _electricController.addListener(_generateArcs);

    // Hologram flicker
    _hologramController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();

    _hologramAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _hologramController,
    );

    // Character corruption controller
    _corruptionController = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _corruptionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showCorruption = false;
          _corruptedCharIndex = -1;
        });
      }
    });
    _triggerRandomCorruption();
  }

  void _triggerRandomGlitch() {
    _glitchTimer?.cancel();
    _glitchTimer = Timer(
      Duration(milliseconds: 1500 + _random.nextInt(3500)),
      () {
        if (!mounted) return;
        setState(() {
          _showGlitch = true;
          _glitchOffset = (_random.nextDouble() - 0.5) * 12;
          _glitchVertical = (_random.nextDouble() - 0.5) * 4;
        });
        _glitchController.forward(from: 0);
        _triggerRandomGlitch();
      },
    );
  }

  void _triggerRandomCorruption() {
    _corruptionTimer?.cancel();
    _corruptionTimer = Timer(
      Duration(milliseconds: 800 + _random.nextInt(2000)),
      () {
        if (!mounted) return;
        setState(() {
          _showCorruption = true;
          _corruptedCharIndex = _random.nextInt(widget.text.length);
        });
        _corruptionController.forward(from: 0);
        _triggerRandomCorruption();
      },
    );
  }

  void _generateArcs() {
    if (!mounted) return;
    if (_random.nextDouble() > 0.15) return; // Only occasionally generate arcs

    setState(() {
      _arcs = List.generate(_random.nextInt(3) + 1, (_) {
        final startX = _random.nextDouble();
        return _ElectricArc(
          start: Offset(startX, _random.nextDouble() * 0.3),
          end: Offset(startX + (_random.nextDouble() - 0.5) * 0.2, 0.7 + _random.nextDouble() * 0.3),
          intensity: _random.nextDouble(),
        );
      });
    });
  }

  @override
  void dispose() {
    _glitchTimer?.cancel();
    _corruptionTimer?.cancel();
    _pulseController.dispose();
    _glitchController.dispose();
    _scanController.dispose();
    _electricController.dispose();
    _hologramController.dispose();
    _corruptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _scanAnimation,
        _hologramAnimation,
        _electricController,
      ]),
      builder: (context, child) {
        // Hologram flicker effect
        final hologramFlicker = _calculateHologramFlicker();

        return SizedBox(
          height: widget.fontSize * 2.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background energy field
              Positioned.fill(
                child: CustomPaint(
                  painter: _EnergyFieldPainter(
                    progress: _hologramAnimation.value,
                    primaryColor: widget.primaryColor,
                    secondaryColor: widget.secondaryColor,
                    intensity: _pulseAnimation.value,
                  ),
                ),
              ),

              // Electric arcs behind text
              Positioned.fill(
                child: CustomPaint(
                  painter: _ElectricArcPainter(
                    arcs: _arcs,
                    primaryColor: widget.primaryColor,
                    secondaryColor: widget.secondaryColor,
                  ),
                ),
              ),

              // Hologram scanlines layer
              Positioned.fill(
                child: ClipRect(
                  child: CustomPaint(
                    painter: _HologramScanlinesPainter(
                      progress: _hologramAnimation.value,
                      color: widget.primaryColor,
                      intensity: hologramFlicker,
                    ),
                  ),
                ),
              ),

              // Chromatic aberration - red channel (far)
              if (_showGlitch)
                Transform.translate(
                  offset: Offset(_glitchOffset * 2.5, _glitchVertical),
                  child: Opacity(
                    opacity: 0.6,
                    child: _buildText(NeonColors.red, _pulseAnimation.value * 0.7),
                  ),
                ),

              // Chromatic aberration - blue channel (medium)
              if (_showGlitch)
                Transform.translate(
                  offset: Offset(-_glitchOffset * 2.5, -_glitchVertical),
                  child: Opacity(
                    opacity: 0.6,
                    child: _buildText(NeonColors.cyan, _pulseAnimation.value * 0.7),
                  ),
                ),

              // Chromatic aberration - green channel (slight)
              if (_showGlitch)
                Transform.translate(
                  offset: Offset(_glitchOffset * 0.5, 0),
                  child: Opacity(
                    opacity: 0.4,
                    child: _buildText(NeonColors.green, _pulseAnimation.value * 0.5),
                  ),
                ),

              // Main text with gradient and corruption
              Opacity(
                opacity: hologramFlicker,
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      widget.primaryColor,
                      Color.lerp(widget.primaryColor, widget.secondaryColor, 0.3)!,
                      widget.secondaryColor,
                      Color.lerp(widget.secondaryColor, widget.primaryColor, 0.3)!,
                      widget.primaryColor,
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  ).createShader(bounds),
                  child: _showCorruption
                      ? _buildCorruptedText(_pulseAnimation.value)
                      : _buildText(Colors.white, _pulseAnimation.value),
                ),
              ),

              // Outer glow layer
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _OuterGlowPainter(
                      text: widget.text,
                      fontSize: widget.fontSize,
                      primaryColor: widget.primaryColor,
                      secondaryColor: widget.secondaryColor,
                      intensity: _pulseAnimation.value,
                    ),
                  ),
                ),
              ),

              // Scanner line overlay
              Positioned.fill(
                child: ClipRect(
                  child: CustomPaint(
                    painter: _ScanLinePainter(
                      progress: _scanAnimation.value,
                      color: widget.primaryColor,
                    ),
                  ),
                ),
              ),

              // Glitch slice effect
              if (_showGlitch)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GlitchSlicePainter(
                      offset: _glitchOffset,
                      color: widget.secondaryColor,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double _calculateHologramFlicker() {
    final flickerPhase = _hologramAnimation.value * math.pi * 20;
    final baseFlicker = 0.92 + 0.08 * math.sin(flickerPhase);
    // Occasional stronger flicker
    if (_random.nextDouble() > 0.98) {
      return baseFlicker * (0.7 + _random.nextDouble() * 0.3);
    }
    return baseFlicker;
  }

  Widget _buildText(Color color, double intensity) {
    return Text(
      widget.text,
      style: _buildTextStyle(color, intensity),
    );
  }

  Widget _buildCorruptedText(double intensity) {
    return RichText(
      text: TextSpan(
        children: List.generate(widget.text.length, (index) {
          final isCorrupted = index == _corruptedCharIndex;
          final char = isCorrupted
              ? _getCorruptedChar(widget.text[index])
              : widget.text[index];
          return TextSpan(
            text: char,
            style: _buildTextStyle(
              isCorrupted ? NeonColors.red : Colors.white,
              intensity,
            ).copyWith(
              color: isCorrupted ? NeonColors.red : Colors.white,
            ),
          );
        }),
      ),
    );
  }

  String _getCorruptedChar(String original) {
    const glitchChars = '!@#\$%^&*░▒▓█▀▄■□◊◦●○';
    return glitchChars[_random.nextInt(glitchChars.length)];
  }

  TextStyle _buildTextStyle(Color color, double intensity) {
    return TextStyle(
      fontFamily: NeonTextStyles.fontFamily,
      fontSize: widget.fontSize,
      fontWeight: FontWeight.bold,
      color: color,
      letterSpacing: 8,
      shadows: [
        // Inner glow
        Shadow(
          color: color.withOpacity(intensity),
          blurRadius: 5,
        ),
        // Primary glow
        Shadow(
          color: color.withOpacity(intensity * 0.9),
          blurRadius: 15,
        ),
        // Secondary glow
        Shadow(
          color: color.withOpacity(intensity * 0.7),
          blurRadius: 30,
        ),
        // Outer glow
        Shadow(
          color: color.withOpacity(intensity * 0.5),
          blurRadius: 50,
        ),
        // Far glow
        Shadow(
          color: color.withOpacity(intensity * 0.3),
          blurRadius: 80,
        ),
      ],
    );
  }
}

class _ElectricArc {
  final Offset start;
  final Offset end;
  final double intensity;

  _ElectricArc({required this.start, required this.end, required this.intensity});
}

class _EnergyFieldPainter extends CustomPainter {
  _EnergyFieldPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.intensity,
  });

  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Rotating energy rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + i * 0.33) % 1.0;
      final radius = size.width * 0.3 + ringProgress * size.width * 0.2;
      final opacity = (1.0 - ringProgress) * 0.15 * intensity;

      final paint = Paint()
        ..color = (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(progress * math.pi * 2 + i * math.pi / 3);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 0.3),
        paint,
      );
      canvas.restore();
    }

    // Central energy pulse
    final pulseRadius = 20 + intensity * 30;
    final pulsePaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        pulseRadius,
        [
          primaryColor.withOpacity(0.3 * intensity),
          secondaryColor.withOpacity(0.1 * intensity),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawCircle(center, pulseRadius, pulsePaint);
  }

  @override
  bool shouldRepaint(_EnergyFieldPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.intensity != intensity;
}

class _ElectricArcPainter extends CustomPainter {
  _ElectricArcPainter({
    required this.arcs,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final List<_ElectricArc> arcs;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);

    for (final arc in arcs) {
      final start = Offset(arc.start.dx * size.width, arc.start.dy * size.height);
      final end = Offset(arc.end.dx * size.width, arc.end.dy * size.height);

      // Draw jagged lightning path
      final path = Path();
      path.moveTo(start.dx, start.dy);

      final segments = 6;
      var current = start;
      for (int i = 1; i <= segments; i++) {
        final t = i / segments;
        final target = Offset.lerp(start, end, t)!;
        final jitter = Offset(
          (random.nextDouble() - 0.5) * 20 * (1 - t),
          (random.nextDouble() - 0.5) * 10,
        );
        current = target + jitter;
        path.lineTo(current.dx, current.dy);
      }

      // Glow
      final glowPaint = Paint()
        ..color = primaryColor.withOpacity(0.5 * arc.intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, glowPaint);

      // Core
      final corePaint = Paint()
        ..color = Colors.white.withOpacity(arc.intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, corePaint);
    }
  }

  @override
  bool shouldRepaint(_ElectricArcPainter oldDelegate) => true;
}

class _HologramScanlinesPainter extends CustomPainter {
  _HologramScanlinesPainter({
    required this.progress,
    required this.color,
    required this.intensity,
  });

  final double progress;
  final Color color;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    // Horizontal scanlines
    final linePaint = Paint()
      ..color = color.withOpacity(0.03 * intensity);

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }

    // Moving interference band
    final bandY = (progress * size.height * 1.5) % (size.height + 20) - 10;
    final bandPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, bandY - 5),
        Offset(0, bandY + 5),
        [
          Colors.transparent,
          color.withOpacity(0.1 * intensity),
          Colors.transparent,
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, bandY - 5, size.width, 10),
      bandPaint,
    );
  }

  @override
  bool shouldRepaint(_HologramScanlinesPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.intensity != intensity;
}

class _OuterGlowPainter extends CustomPainter {
  _OuterGlowPainter({
    required this.text,
    required this.fontSize,
    required this.primaryColor,
    required this.secondaryColor,
    required this.intensity,
  });

  final String text;
  final double fontSize;
  final Color primaryColor;
  final Color secondaryColor;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    // This creates a subtle ambient glow behind the text
    final center = Offset(size.width / 2, size.height / 2);
    final glowWidth = text.length * fontSize * 0.5;

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx - glowWidth / 2, center.dy),
        Offset(center.dx + glowWidth / 2, center.dy),
        [
          primaryColor.withOpacity(0.0),
          primaryColor.withOpacity(0.1 * intensity),
          secondaryColor.withOpacity(0.15 * intensity),
          secondaryColor.withOpacity(0.1 * intensity),
          primaryColor.withOpacity(0.0),
        ],
        const [0.0, 0.25, 0.5, 0.75, 1.0],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawRect(
      Rect.fromCenter(center: center, width: glowWidth, height: fontSize * 1.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(_OuterGlowPainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}

class _ScanLinePainter extends CustomPainter {
  _ScanLinePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;

    // Main scan line with intense glow
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, y - 30),
        Offset(0, y + 30),
        [
          Colors.transparent,
          color.withOpacity(0.2),
          color.withOpacity(0.6),
          Colors.white.withOpacity(0.9),
          color.withOpacity(0.6),
          color.withOpacity(0.2),
          Colors.transparent,
        ],
        [0.0, 0.2, 0.4, 0.5, 0.6, 0.8, 1.0],
      );

    canvas.drawRect(Rect.fromLTWH(0, y - 30, size.width, 60), paint);

    // Bright center line
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), centerPaint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _GlitchSlicePainter extends CustomPainter {
  _GlitchSlicePainter({required this.offset, required this.color});

  final double offset;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random((offset * 100).toInt());

    // Draw random glitch slices
    for (int i = 0; i < 3; i++) {
      final y = random.nextDouble() * size.height;
      final height = 2.0 + random.nextDouble() * 6;
      final xOffset = (random.nextDouble() - 0.5) * offset * 2;

      final slicePaint = Paint()
        ..color = color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawRect(
        Rect.fromLTWH(xOffset, y, size.width, height),
        slicePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GlitchSlicePainter oldDelegate) =>
      oldDelegate.offset != offset;
}
