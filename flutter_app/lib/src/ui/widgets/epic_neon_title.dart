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
  int _rngState = 0x6d2b79f5;
  Timer? _glitchTimer;
  Timer? _corruptionTimer;
  ui.Shader? _titleGradientShader;
  Rect? _titleGradientBounds;
  Color? _titleGradientPrimary;
  Color? _titleGradientSecondary;

  // Electric arc points
  List<_ElectricArc> _arcs = [];

  @override
  void initState() {
    super.initState();
    _rngState = 0x6d2b79f5 ^ widget.text.hashCode;

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

  @override
  void didUpdateWidget(covariant EpicNeonTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryColor != widget.primaryColor ||
        oldWidget.secondaryColor != widget.secondaryColor) {
      _titleGradientShader = null;
      _titleGradientBounds = null;
      _titleGradientPrimary = null;
      _titleGradientSecondary = null;
    }
  }

  void _triggerRandomGlitch() {
    _glitchTimer?.cancel();
    _glitchTimer = Timer(
      Duration(milliseconds: 1500 + _nextInt(3500)),
      () {
        if (!mounted) return;
        setState(() {
          _showGlitch = true;
          _glitchOffset = (_nextUnit() - 0.5) * 12;
          _glitchVertical = (_nextUnit() - 0.5) * 4;
        });
        _glitchController.forward(from: 0);
        _triggerRandomGlitch();
      },
    );
  }

  void _triggerRandomCorruption() {
    _corruptionTimer?.cancel();
    _corruptionTimer = Timer(
      Duration(milliseconds: 800 + _nextInt(2000)),
      () {
        if (!mounted) return;
        setState(() {
          _showCorruption = true;
          _corruptedCharIndex = _nextInt(widget.text.length);
        });
        _corruptionController.forward(from: 0);
        _triggerRandomCorruption();
      },
    );
  }

  void _generateArcs() {
    if (!mounted) return;
    if (_nextUnit() > 0.15) return; // Only occasionally generate arcs

    setState(() {
      _arcs = List.generate(_nextInt(3) + 1, (_) {
        final startX = _nextUnit();
        return _ElectricArc(
          start: Offset(startX, _nextUnit() * 0.3),
          end: Offset(startX + (_nextUnit() - 0.5) * 0.2, 0.7 + _nextUnit() * 0.3),
          intensity: _nextUnit(),
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
                  shaderCallback: _getTitleShader,
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
    if (_nextUnit() > 0.98) {
      return baseFlicker * (0.7 + _nextUnit() * 0.3);
    }
    return baseFlicker;
  }

  Shader _getTitleShader(Rect bounds) {
    if (_titleGradientShader != null &&
        _titleGradientBounds == bounds &&
        _titleGradientPrimary == widget.primaryColor &&
        _titleGradientSecondary == widget.secondaryColor) {
      return _titleGradientShader!;
    }

    _titleGradientBounds = bounds;
    _titleGradientPrimary = widget.primaryColor;
    _titleGradientSecondary = widget.secondaryColor;

    _titleGradientShader = LinearGradient(
      colors: [
        widget.primaryColor,
        Color.lerp(widget.primaryColor, widget.secondaryColor, 0.3)!,
        widget.secondaryColor,
        Color.lerp(widget.secondaryColor, widget.primaryColor, 0.3)!,
        widget.primaryColor,
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    ).createShader(bounds);

    return _titleGradientShader!;
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
    return glitchChars[_nextInt(glitchChars.length)];
  }

  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }

  double _nextUnit() => _lcgNext() / 0x7fffffff;

  int _nextInt(int max) => max <= 0 ? 0 : _lcgNext() % max;

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

  static final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  static final Paint _pulsePaint = Paint();
  static final Map<int, ui.Shader> _pulseShaderCache = {};
  static const int _alphaSteps = 16;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);

    // Rotating energy rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + i * 0.33) % 1.0;
      final radius = size.width * 0.3 + ringProgress * size.width * 0.2;
      final opacity = (1.0 - ringProgress) * 0.15 * intensity;
      if (opacity <= 0.002) continue;

      _ringPaint.color =
          (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(opacity);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(progress * math.pi * 2 + i * math.pi / 3);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 0.3),
        _ringPaint,
      );
      canvas.restore();
    }

    // Central energy pulse
    final pulseRadius = 20 + intensity * 30;
    final intensityStep = (intensity * _alphaSteps).round().clamp(0, _alphaSteps) as int;
    if (intensityStep == 0) return;
    final cacheKey = Object.hash(
      size.width.round(),
      size.height.round(),
      pulseRadius.round(),
      primaryColor.value,
      secondaryColor.value,
      intensityStep,
    );
    final shader = _pulseShaderCache.putIfAbsent(cacheKey, () {
      if (_pulseShaderCache.length > 32) {
        _pulseShaderCache.clear();
      }
      final quantIntensity = intensityStep / _alphaSteps;
      return ui.Gradient.radial(
        center,
        pulseRadius,
        [
          primaryColor.withOpacity(0.3 * quantIntensity),
          secondaryColor.withOpacity(0.1 * quantIntensity),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );
    });
    _pulsePaint.shader = shader;
    canvas.drawCircle(center, pulseRadius, _pulsePaint);
    _pulsePaint.shader = null;
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

  static final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _corePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Path _arcPath = Path();

  static int _lcgNext(int state) => (state * 1664525 + 1013904223) & 0x7fffffff;
  static double _lcgUnit(int state) => state / 0x7fffffff;

  @override
  void paint(Canvas canvas, Size size) {
    int state = 42;

    for (final arc in arcs) {
      final start = Offset(arc.start.dx * size.width, arc.start.dy * size.height);
      final end = Offset(arc.end.dx * size.width, arc.end.dy * size.height);

      // Draw jagged lightning path
      final path = _arcPath..reset();
      path.moveTo(start.dx, start.dy);

      final segments = 6;
      var current = start;
      for (int i = 1; i <= segments; i++) {
        final t = i / segments;
        final target = Offset.lerp(start, end, t)!;
        state = _lcgNext(state);
        final jitterX = (_lcgUnit(state) - 0.5) * 20 * (1 - t);
        state = _lcgNext(state);
        final jitterY = (_lcgUnit(state) - 0.5) * 10;
        final jitter = Offset(
          jitterX,
          jitterY,
        );
        current = target + jitter;
        path.lineTo(current.dx, current.dy);
      }

      // Glow
      _glowPaint.color = primaryColor.withOpacity(0.5 * arc.intensity);
      canvas.drawPath(path, _glowPaint);

      // Core
      _corePaint.color = Colors.white.withOpacity(arc.intensity);
      canvas.drawPath(path, _corePaint);
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

  static final Paint _linePaint = Paint();
  static final Paint _bandPaint = Paint();
  static final Path _scanlinePath = Path();
  static Size? _scanlineSize;
  static final Map<int, ui.Shader> _bandShaderCache = {};
  static const int _alphaSteps = 16;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (intensity <= 0.01) return;
    // Horizontal scanlines
    _linePaint.color = color.withOpacity(0.03 * intensity);

    if (_scanlineSize != size) {
      _scanlineSize = size;
      _scanlinePath.reset();
      for (double y = 0; y < size.height; y += 3) {
        _scanlinePath
          ..moveTo(0, y)
          ..lineTo(size.width, y);
      }
    }
    canvas.drawPath(_scanlinePath, _linePaint);

    // Moving interference band
    final bandY = (progress * size.height * 1.5) % (size.height + 20) - 10;
    final intensityStep = (intensity * _alphaSteps).round().clamp(0, _alphaSteps) as int;
    if (intensityStep == 0) return;
    final key = Object.hash(size.width.round(), color.value, intensityStep);
    final shader = _bandShaderCache.putIfAbsent(key, () {
      if (_bandShaderCache.length > 32) {
        _bandShaderCache.clear();
      }
      final quantIntensity = intensityStep / _alphaSteps;
      return ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(0, 10),
        [
          Colors.transparent,
          color.withOpacity(0.1 * quantIntensity),
          Colors.transparent,
        ],
        const [0.0, 0.5, 1.0],
      );
    });
    _bandPaint.shader = shader;
    canvas.save();
    canvas.translate(0, bandY - 5);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 10),
      _bandPaint,
    );
    canvas.restore();
    _bandPaint.shader = null;
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

  static final Paint _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
  static final Map<int, ui.Shader> _glowShaderCache = {};
  static const int _alphaSteps = 16;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (intensity <= 0.01) return;
    // This creates a subtle ambient glow behind the text
    final center = Offset(size.width / 2, size.height / 2);
    final glowWidth = text.length * fontSize * 0.5;

    final intensityStep = (intensity * _alphaSteps).round().clamp(0, _alphaSteps) as int;
    if (intensityStep == 0) return;
    final key = Object.hash(glowWidth.round(), primaryColor.value, secondaryColor.value, intensityStep);
    final shader = _glowShaderCache.putIfAbsent(key, () {
      if (_glowShaderCache.length > 32) {
        _glowShaderCache.clear();
      }
      final quantIntensity = intensityStep / _alphaSteps;
      return ui.Gradient.linear(
        Offset(0, 0),
        Offset(glowWidth, 0),
        [
          primaryColor.withOpacity(0.0),
          primaryColor.withOpacity(0.1 * quantIntensity),
          secondaryColor.withOpacity(0.15 * quantIntensity),
          secondaryColor.withOpacity(0.1 * quantIntensity),
          primaryColor.withOpacity(0.0),
        ],
        const [0.0, 0.25, 0.5, 0.75, 1.0],
      );
    });
    _glowPaint.shader = shader;

    canvas.drawRect(
      Rect.fromCenter(center: center, width: glowWidth, height: fontSize * 1.5),
      _glowPaint,
    );
    _glowPaint.shader = null;
  }

  @override
  bool shouldRepaint(_OuterGlowPainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}

class _ScanLinePainter extends CustomPainter {
  _ScanLinePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static final Paint _scanPaint = Paint();
  static final Paint _centerPaint = Paint()
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Map<int, ui.Shader> _scanShaderCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final y = size.height * progress;

    // Main scan line with intense glow
    final key = Object.hash(size.width.round(), color.value);
    final shader = _scanShaderCache.putIfAbsent(key, () {
      if (_scanShaderCache.length > 32) {
        _scanShaderCache.clear();
      }
      return ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(0, 60),
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
    });
    _scanPaint.shader = shader;
    canvas.save();
    canvas.translate(0, y - 30);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 60), _scanPaint);
    canvas.restore();
    _scanPaint.shader = null;

    // Bright center line
    _centerPaint.color = Colors.white.withOpacity(0.8);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), _centerPaint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _GlitchSlicePainter extends CustomPainter {
  _GlitchSlicePainter({required this.offset, required this.color});

  final double offset;
  final Color color;

  static final Paint _slicePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  static int _lcgNext(int state) => (state * 1664525 + 1013904223) & 0x7fffffff;
  static double _lcgUnit(int state) => state / 0x7fffffff;

  @override
  void paint(Canvas canvas, Size size) {
    int state = (offset * 100).toInt() & 0x7fffffff;

    // Draw random glitch slices
    for (int i = 0; i < 3; i++) {
      state = _lcgNext(state);
      final y = _lcgUnit(state) * size.height;
      state = _lcgNext(state);
      final height = 2.0 + _lcgUnit(state) * 6;
      state = _lcgNext(state);
      final xOffset = (_lcgUnit(state) - 0.5) * offset * 2;

      _slicePaint.color = color.withOpacity(0.3);

      canvas.drawRect(
        Rect.fromLTWH(xOffset, y, size.width, height),
        _slicePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GlitchSlicePainter oldDelegate) =>
      oldDelegate.offset != offset;
}
