import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Neon Tron color palette - Enhanced with gradients and glow presets
class NeonColors {
  // Primary colors
  static const Color cyan = Color(0xFF00FFFF);
  static const Color magenta = Color(0xFFFF00FF);
  static const Color purple = Color(0xFF9C27B0);
  static const Color yellow = Color(0xFFFFEB3B);
  static const Color orange = Color(0xFFFF7043);
  static const Color green = Color(0xFF00FF88);
  static const Color red = Color(0xFFFF0066);
  static const Color white = Color(0xFFFFFFFF);
  static const Color blue = Color(0xFF0088FF);

  // Background colors
  static const Color darkBg = Color(0xFF0A0A0F);
  static const Color surfaceBg = Color(0xFF1A1A2E);
  static const Color surface = surfaceBg;
  static const Color gridLine = Color(0xFF1A1A2E);
  static const Color deepBlack = Color(0xFF030308);

  // State colors
  static const Color success = Color(0xFF00FF88);
  static const Color warning = Color(0xFFFFAA00);
  static const Color error = Color(0xFFFF4444);
  static const Color info = Color(0xFF00AAFF);

  // Gradient presets
  static const List<Color> cyanMagentaGradient = [cyan, magenta];
  static const List<Color> cyanPurpleGradient = [cyan, purple];
  static const List<Color> magentaOrangeGradient = [magenta, orange];
  static const List<Color> yellowOrangeGradient = [yellow, orange];
  static const List<Color> greenCyanGradient = [green, cyan];
  static const List<Color> redMagentaGradient = [red, magenta];

  // Color blend presets
  static Color blendWithGlow(Color base, double intensity) {
    return Color.lerp(base, white, intensity * 0.3)!;
  }

  static Color dimmed(Color base, double factor) {
    return Color.lerp(base, darkBg, factor)!;
  }
}

/// Glow intensity levels
enum GlowIntensity {
  subtle(blurRadius: 4, opacity: 0.3),
  medium(blurRadius: 8, opacity: 0.5),
  intense(blurRadius: 16, opacity: 0.7),
  extreme(blurRadius: 24, opacity: 0.9);

  const GlowIntensity({required this.blurRadius, required this.opacity});

  final double blurRadius;
  final double opacity;

  MaskFilter get maskFilter => MaskFilter.blur(BlurStyle.normal, blurRadius);

  Color applyTo(Color color) => color.withOpacity(opacity);
}

/// Animation timing constants
class NeonAnimations {
  // Duration presets (in seconds)
  static const double quickFlash = 0.05;
  static const double buttonPress = 0.15;
  static const double hoverTransition = 0.2;
  static const double explosion = 0.4;
  static const double scanLineCycle = 1.5;
  static const double idlePulse = 3.0;
  static const double slowPulse = 4.0;

  // Animation curves
  static const Curve easeGlow = Curves.easeInOut;
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve sharpIn = Curves.easeInQuart;
  static const Curve sharpOut = Curves.easeOutQuart;

  // Pulse patterns (returns 0.0 - 1.0)
  static double pulse(double time, {double speed = 1.0}) {
    return (math.sin(time * speed) + 1) / 2;
  }

  static double sharpPulse(double time, {double speed = 1.0}) {
    return math.pow((math.sin(time * speed) + 1) / 2, 2).toDouble();
  }

  static double sawtoothPulse(double time, {double speed = 1.0}) {
    return (time * speed) % 1.0;
  }

  static double flickerPulse(double time) {
    return math.sin(time * 15) * math.sin(time * 23) > 0.7 ? 1.0 : 0.0;
  }
}

/// Visual effects helper class
class NeonEffects {
  static final Paint _scanlinePaint = Paint();
  static final Paint _glowOuterPaint = Paint();
  static final Paint _glowMediumPaint = Paint();
  static final Paint _glowCorePaint = Paint();
  static final Paint _glowCenterPaint = Paint();
  static final Paint _lineGlowPaint = Paint()..strokeCap = StrokeCap.round;
  static final Paint _lineCorePaint = Paint()..strokeCap = StrokeCap.round;
  static final Paint _lineCenterPaint = Paint()..strokeCap = StrokeCap.round;
  static final Paint _cornerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _cornerGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Path _cornerPath = Path();

  /// Create layered glow effect paint list
  static List<Paint> createGlowLayers(Color color, {int layers = 3}) {
    final paints = <Paint>[];
    for (int i = layers - 1; i >= 0; i--) {
      final intensity = (i + 1) / layers;
      paints.add(Paint()
        ..color = color.withOpacity(0.3 * intensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + i * 8));
    }
    // Core layer
    paints.add(Paint()..color = color);
    // Bright center
    paints.add(Paint()..color = Colors.white.withOpacity(0.5));
    return paints;
  }

  /// Create chromatic aberration offset colors
  static List<(Color, Offset)> chromaticAberration(Color base, double intensity) {
    return [
      (const Color(0xFFFF0000).withOpacity(0.3), Offset(-intensity, 0)),
      (const Color(0xFF00FF00).withOpacity(0.3), Offset.zero),
      (const Color(0xFF0000FF).withOpacity(0.3), Offset(intensity, 0)),
    ];
  }

  /// Create scan line pattern
  static void drawScanLines(Canvas canvas, Size size, double time, {
    Color color = NeonColors.cyan,
    double spacing = 3.0,
    double opacity = 0.03,
  }) {
    _scanlinePaint.color = color.withOpacity(opacity);
    final lineCount = (size.height / spacing).ceil();

    for (int i = 0; i < lineCount; i++) {
      final y = i * spacing + (time * 50) % spacing;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        _scanlinePaint,
      );
    }
  }

  /// Draw glowing circle with proper layering
  static void drawGlowingCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    GlowIntensity glow = GlowIntensity.medium,
  }) {
    // Outer soft glow
    _glowOuterPaint
      ..color = color.withOpacity(0.2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius);
    canvas.drawCircle(
      center,
      radius * 1.5,
      _glowOuterPaint,
    );

    // Medium glow
    _glowMediumPaint
      ..color = color.withOpacity(glow.opacity * 0.7)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.5);
    canvas.drawCircle(
      center,
      radius * 1.2,
      _glowMediumPaint,
    );

    // Core
    _glowCorePaint.color = color;
    canvas.drawCircle(center, radius, _glowCorePaint);

    // Bright center
    _glowCenterPaint.color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(
      center,
      radius * 0.3,
      _glowCenterPaint,
    );
  }

  /// Draw neon line with glow
  static void drawGlowingLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color, {
    double width = 2.0,
    GlowIntensity glow = GlowIntensity.medium,
  }) {
    // Outer glow
    _lineGlowPaint
      ..color = color.withOpacity(glow.opacity * 0.5)
      ..strokeWidth = width + 6
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow.blurRadius);
    canvas.drawLine(
      start,
      end,
      _lineGlowPaint,
    );

    // Main line
    _lineCorePaint
      ..color = color
      ..strokeWidth = width;
    canvas.drawLine(
      start,
      end,
      _lineCorePaint,
    );

    // Bright center
    _lineCenterPaint
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = width * 0.3;
    canvas.drawLine(
      start,
      end,
      _lineCenterPaint,
    );
  }

  /// Draw hexagon shape
  static Path createHexagonPath(Offset center, double radius) {
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
    return path;
  }

  /// Draw corner bracket decoration
  static void drawCornerBracket(
    Canvas canvas,
    Offset position,
    double size,
    Color color, {
    bool topLeft = true,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
    double strokeWidth = 2.0,
  }) {
    _cornerPaint
      ..color = color
      ..strokeWidth = strokeWidth;
    _cornerGlowPaint
      ..color = color.withOpacity(0.4)
      ..strokeWidth = strokeWidth + 2;

    void drawBracket(double hDir, double vDir) {
      _cornerPath
        ..reset()
        ..moveTo(position.dx, position.dy + size * vDir)
        ..lineTo(position.dx, position.dy)
        ..lineTo(position.dx + size * hDir, position.dy);

      canvas.drawPath(_cornerPath, _cornerGlowPaint);
      canvas.drawPath(_cornerPath, _cornerPaint);
    }

    if (topLeft) drawBracket(1, 1);
    if (topRight) drawBracket(-1, 1);
    if (bottomLeft) drawBracket(1, -1);
    if (bottomRight) drawBracket(-1, -1);
  }
}

/// Neon text styles - Enhanced
class NeonTextStyles {
  static const String fontFamily = 'monospace';

  static TextStyle title = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: NeonColors.cyan,
    letterSpacing: 4,
    shadows: [
      Shadow(color: NeonColors.cyan, blurRadius: 20),
      Shadow(color: NeonColors.cyan, blurRadius: 40),
      Shadow(color: NeonColors.cyan, blurRadius: 60),
    ],
  );

  static TextStyle subtitle = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: NeonColors.magenta,
    letterSpacing: 2,
    shadows: [
      Shadow(color: NeonColors.magenta, blurRadius: 10),
      Shadow(color: NeonColors.magenta, blurRadius: 20),
    ],
  );

  static TextStyle button = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: NeonColors.white,
    letterSpacing: 1.5,
  );

  static TextStyle body = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    color: NeonColors.white,
  );

  static TextStyle small = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    color: NeonColors.green,
  );

  static TextStyle hud = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: NeonColors.white,
    letterSpacing: 0.5,
  );

  static TextStyle withGlow(TextStyle style, Color glowColor) {
    return style.copyWith(
      shadows: [
        Shadow(color: glowColor.withOpacity(0.8), blurRadius: 8),
        Shadow(color: glowColor.withOpacity(0.5), blurRadius: 16),
      ],
    );
  }
}

/// App theme data
class NeonTheme {
  // Cyberpunk color palette for HUD elements
  static const Color cyberCyan = Color(0xFF00FFFF);
  static const Color cyberMagenta = Color(0xFFFF00FF);
  static const Color cyberGreen = Color(0xFF00FF88);
  static const Color cyberPurple = Color(0xFF9C27B0);
  static const Color cyberRed = Color(0xFFFF0044);
  static const Color cyberYellow = Color(0xFFFFFF00);
  static const Color cyberOrange = Color(0xFFFF6600);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: NeonColors.darkBg,
        primaryColor: NeonColors.cyan,
        colorScheme: const ColorScheme.dark(
          primary: NeonColors.cyan,
          secondary: NeonColors.magenta,
          surface: NeonColors.darkBg,
          error: NeonColors.red,
        ),
        fontFamily: NeonTextStyles.fontFamily,
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: NeonColors.cyan),
          bodyLarge: TextStyle(color: NeonColors.white),
          bodyMedium: TextStyle(color: NeonColors.white),
        ),
      );
}
