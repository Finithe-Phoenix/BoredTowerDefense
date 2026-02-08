import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bored_games_game.dart';

class _FastRng {
  int _state;

  _FastRng([int? seed]) : _state = (seed ?? 0x6d2b79f5) & 0x7fffffff;

  int _next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  double nextDouble() => _next() / 0x7fffffff;

  int nextInt(int max) => max <= 0 ? 0 : _next() % max;

  bool nextBool() => (_next() & 1) == 0;
}

/// Holographic countdown timer with cyberpunk aesthetic and visual urgency effects.
/// Displays time remaining with multiple layers of visual feedback:
/// - Layer 1: Outer ring progress arc
/// - Layer 2: Digital number display
/// - Layer 3: Holographic frame with glitch effect
/// - Layer 4: Urgency pulse (intensifies as time runs low)
/// - Layer 5: Warning indicators when time < 30%
/// - Layer 6: Final countdown flash effects (last 10 seconds)
class CountdownTimerComponent extends PositionComponent
    with HasGameRef<BoredGamesGame> {
  CountdownTimerComponent({
    this.totalDuration = 60.0,
    this.onComplete,
  });

  /// Total countdown duration in seconds
  double totalDuration;

  /// Callback when countdown reaches zero
  final VoidCallback? onComplete;

  // Timer state
  double _remainingTime = 0;
  bool _isActive = false;
  bool _hasCompleted = false;

  // Animation state
  double _time = 0;
  double _pulsePhase = 0;
  double _glitchTimer = 0;
  double _glitchIntensity = 0;
  int _glitchFrame = 0;
  bool _isGlitching = false;
  double _urgencyShakeX = 0;
  double _urgencyShakeY = 0;
  double _flashAlpha = 0;

  // Cached random for glitch effects
  final _FastRng _random = _FastRng();

  // Layout constants
  static const double baseSize = 120.0;
  static const double ringThickness = 6.0;
  static const double innerRingThickness = 3.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC PAINT OBJECTS (Avoid per-frame allocations)
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _bgPaint = Paint();
  static final Paint _ringBgPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = ringThickness
    ..strokeCap = StrokeCap.round;
  static final Paint _ringProgressPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = ringThickness
    ..strokeCap = StrokeCap.round;
  static final Paint _ringGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = ringThickness + 6
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _innerRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = innerRingThickness;
  static final Paint _framePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _frameGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _cornerPaint = Paint()
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  static final Paint _pulseRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _warningPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _flashPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _digitPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  static final Paint _digitGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _glitchPaint = Paint();
  static final Paint _hexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Paint _scanlinePaint = Paint();
  static final Paint _dataPaint = Paint()
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;

  // Reusable path objects
  static final Path _ringPath = Path();
  static final Path _hexPath = Path();

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Current remaining time in seconds
  double get remainingTime => _remainingTime;

  /// Whether the timer is currently running
  bool get isActive => _isActive;

  /// Progress from 0.0 (full time) to 1.0 (no time)
  double get progress =>
      totalDuration > 0 ? 1.0 - (_remainingTime / totalDuration) : 1.0;

  /// Urgency level from 0.0 (calm) to 1.0 (critical)
  double get urgencyLevel {
    if (totalDuration <= 0) return 1.0;
    final percent = _remainingTime / totalDuration;
    if (percent > 0.3) return 0.0;
    if (percent > 0.1) return (0.3 - percent) / 0.2; // Ramp from 30% to 10%
    return 1.0; // Max urgency under 10%
  }

  /// Whether in warning state (< 30% time remaining)
  bool get isWarning => _remainingTime / totalDuration < 0.3;

  /// Whether in critical state (< 10 seconds)
  bool get isCritical => _remainingTime < 10.0;

  /// Get color based on time remaining (cyan -> yellow -> red)
  Color get timerColor {
    if (totalDuration <= 0) return const Color(0xFFFF0044);
    final percent = _remainingTime / totalDuration;
    if (percent > 0.5) {
      // Cyan to yellow (100% to 50%)
      final t = (percent - 0.5) / 0.5;
      return Color.lerp(const Color(0xFFFFFF00), const Color(0xFF00FFFF), t)!;
    } else if (percent > 0.3) {
      // Yellow range (50% to 30%)
      return const Color(0xFFFFFF00);
    } else {
      // Yellow to red (30% to 0%)
      final t = percent / 0.3;
      return Color.lerp(const Color(0xFFFF0044), const Color(0xFFFFFF00), t)!;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start the countdown timer
  void start({double? duration}) {
    if (duration != null) {
      totalDuration = duration;
    }
    _remainingTime = totalDuration;
    _isActive = true;
    _hasCompleted = false;
    _flashAlpha = 0;
  }

  /// Pause the timer
  void pause() {
    _isActive = false;
  }

  /// Resume the timer
  void resume() {
    if (!_hasCompleted) {
      _isActive = true;
    }
  }

  /// Stop and reset the timer
  void stop() {
    _isActive = false;
    _remainingTime = totalDuration;
    _hasCompleted = false;
    _flashAlpha = 0;
  }

  /// Add time to the countdown
  void addTime(double seconds) {
    _remainingTime = (_remainingTime + seconds).clamp(0.0, totalDuration);
    if (_remainingTime > 0) {
      _hasCompleted = false;
    }
  }

  /// Set remaining time directly
  void setTime(double seconds) {
    _remainingTime = seconds.clamp(0.0, totalDuration);
    if (_remainingTime > 0) {
      _hasCompleted = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    priority = 110; // Above HUD
    _remainingTime = totalDuration;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _pulsePhase += dt * 4;

    // Update timer
    if (_isActive && _remainingTime > 0) {
      _remainingTime -= dt;
      if (_remainingTime <= 0) {
        _remainingTime = 0;
        _isActive = false;
        _hasCompleted = true;
        onComplete?.call();
      }
    }

    // Update glitch effect timing
    _glitchTimer += dt;
    final glitchThreshold = isCritical ? 0.5 : (isWarning ? 1.5 : 3.0);
    if (_glitchTimer > glitchThreshold + _random.nextDouble() * 2.0) {
      _glitchTimer = 0;
      _isGlitching = true;
      _glitchIntensity = 0.5 + _random.nextDouble() * 0.5;
      _glitchFrame = _random.nextInt(1000);
    }

    if (_isGlitching) {
      _glitchIntensity -= dt * 3;
      if (_glitchIntensity <= 0) {
        _isGlitching = false;
        _glitchIntensity = 0;
      }
    }

    // Update urgency shake (only when under 10 seconds)
    if (isCritical && _isActive) {
      final shakeIntensity = (1.0 - _remainingTime / 10.0) * 3.0;
      _urgencyShakeX = (math.sin(_time * 50) + math.cos(_time * 37)) *
          shakeIntensity *
          _random.nextDouble();
      _urgencyShakeY = (math.cos(_time * 45) + math.sin(_time * 31)) *
          shakeIntensity *
          _random.nextDouble();
    } else {
      _urgencyShakeX = 0;
      _urgencyShakeY = 0;
    }

    // Update flash effect (last 10 seconds, pulses each second)
    if (isCritical && _isActive) {
      final secondFraction = _remainingTime - _remainingTime.floor();
      if (secondFraction > 0.9) {
        _flashAlpha = (secondFraction - 0.9) / 0.1 * 0.3;
      } else {
        _flashAlpha *= 0.9; // Fade out
      }
    } else {
      _flashAlpha = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (gameRef.hideHud || gameRef.focusModeActive) return;

    // Check for low FX mode
    final reduceFx = gameRef.reduceFx;

    final screenWidth = gameRef.size.x;
    final screenHeight = gameRef.size.y;

    // Calculate responsive scale
    final baseWidth = 1920.0;
    final baseHeight = 1080.0;
    final scaleX = (screenWidth / baseWidth).clamp(0.5, 1.2);
    final scaleY = (screenHeight / baseHeight).clamp(0.5, 1.2);
    final scale = math.min(scaleX, scaleY);

    // Timer size and position (top-center, below wave indicator)
    final timerSize = (baseSize * scale).clamp(80.0, 140.0);
    final timerX = screenWidth / 2;
    // Wave indicator ends at y~116, position timer below with margin
    final timerY = 130.0 * scale + timerSize / 2;

    canvas.save();

    // Apply urgency shake
    canvas.translate(timerX + _urgencyShakeX, timerY + _urgencyShakeY);

    // Apply glitch offset
    if (_isGlitching && _glitchIntensity > 0.3 && !reduceFx) {
      canvas.translate(
        (math.sin(_time * 50) * 3 * _glitchIntensity),
        (math.cos(_time * 40) * 1.5 * _glitchIntensity),
      );
    }

    final color = timerColor;
    final center = Offset.zero;
    final radius = timerSize / 2;

    // ═════════════════════════════════════════════════════════════════════════
    // LAYER 0: BACKGROUND
    // ═════════════════════════════════════════════════════════════════════════
    _renderBackground(canvas, center, radius, color, reduceFx);

    // ═════════════════════════════════════════════════════════════════════════
    // LAYER 1: OUTER RING PROGRESS ARC
    // ═════════════════════════════════════════════════════════════════════════
    _renderOuterRing(canvas, center, radius, color, reduceFx);

    // ═════════════════════════════════════════════════════════════════════════
    // LAYER 2: DIGITAL NUMBER DISPLAY
    // ═════════════════════════════════════════════════════════════════════════
    _renderDigitalDisplay(canvas, center, radius, color, reduceFx);

    // ═════════════════════════════════════════════════════════════════════════
    // LAYER 3: HOLOGRAPHIC FRAME WITH GLITCH EFFECT
    // ═════════════════════════════════════════════════════════════════════════
    _renderHolographicFrame(canvas, center, radius, color, reduceFx);

    // ═════════════════════════════════════════════════════════════════════════
    // LAYER 4: URGENCY PULSE
    // ═════════════════════════════════════════════════════════════════════════
    if (!reduceFx) {
      _renderUrgencyPulse(canvas, center, radius, color);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // LAYER 5: WARNING INDICATORS (< 30%)
    // ═════════════════════════════════════════════════════════════════════════
    if (isWarning && !reduceFx) {
      _renderWarningIndicators(canvas, center, radius, color);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // LAYER 6: FINAL COUNTDOWN FLASH (last 10 seconds)
    // ═════════════════════════════════════════════════════════════════════════
    if (_flashAlpha > 0.01 && !reduceFx) {
      _renderFlashEffect(canvas, center, radius, color);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // GLITCH OVERLAY
    // ═════════════════════════════════════════════════════════════════════════
    if (_isGlitching && !reduceFx) {
      _renderGlitchOverlay(canvas, center, radius, color);
    }

    canvas.restore();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RENDER LAYERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _renderBackground(
      Canvas canvas, Offset center, double radius, Color color, bool reduceFx) {
    // Dark background with subtle gradient
    final bgGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        const Color(0xFF0a0a15).withOpacity(0.9),
        const Color(0xFF050510).withOpacity(0.95),
        Colors.black.withOpacity(0.98),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    _bgPaint.shader = bgGradient;
    canvas.drawCircle(center, radius - 4, _bgPaint);
    _bgPaint.shader = null;

    // Hex grid overlay
    if (!reduceFx) {
      _hexPaint.color = color.withOpacity(0.05);
      final hexSize = 8.0;
      for (double y = -radius; y < radius; y += hexSize * 0.866) {
        final rowOffset = ((y + radius) / (hexSize * 0.866)).floor() % 2 == 0
            ? 0.0
            : hexSize / 2;
        for (double x = -radius + rowOffset; x < radius; x += hexSize) {
          final dist = math.sqrt(x * x + y * y);
          if (dist < radius - 8) {
            _drawMiniHex(canvas, center.dx + x, center.dy + y, hexSize / 2);
          }
        }
      }
    }

    // Scanlines
    _scanlinePaint.color = Colors.black.withOpacity(0.1);
    for (double y = -radius; y < radius; y += 3) {
      final dx = math.sqrt(math.max(0, radius * radius - y * y));
      canvas.drawLine(
        Offset(center.dx - dx + 4, center.dy + y),
        Offset(center.dx + dx - 4, center.dy + y),
        _scanlinePaint,
      );
    }
  }

  void _renderOuterRing(
      Canvas canvas, Offset center, double radius, Color color, bool reduceFx) {
    final ringRadius = radius - ringThickness / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: ringRadius);

    // Background ring
    _ringBgPaint.color = color.withOpacity(0.1);
    canvas.drawArc(rect, 0, math.pi * 2, false, _ringBgPaint);

    // Progress arc (fills as time passes, so we draw remaining time)
    final sweepAngle = -math.pi * 2 * (1.0 - progress);
    final startAngle = -math.pi / 2; // Start from top

    // Glow
    if (!reduceFx) {
      _ringGlowPaint.color = color.withOpacity(0.3 + urgencyLevel * 0.2);
      canvas.drawArc(rect, startAngle, sweepAngle, false, _ringGlowPaint);
    }

    // Main progress arc
    _ringProgressPaint.color = color.withOpacity(0.9);
    canvas.drawArc(rect, startAngle, sweepAngle, false, _ringProgressPaint);

    // Inner decorative ring
    final innerRadius = radius - ringThickness - 6;
    _innerRingPaint.color = color.withOpacity(0.3);
    canvas.drawCircle(center, innerRadius, _innerRingPaint);

    // Tick marks
    _dataPaint.color = color.withOpacity(0.4);
    for (int i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + (i / 12) * math.pi * 2;
      final innerR = ringRadius - ringThickness / 2 - 3;
      final outerR = ringRadius - ringThickness / 2 + 3;
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * innerR,
            center.dy + math.sin(angle) * innerR),
        Offset(center.dx + math.cos(angle) * outerR,
            center.dy + math.sin(angle) * outerR),
        _dataPaint,
      );
    }
  }

  void _renderDigitalDisplay(
      Canvas canvas, Offset center, double radius, Color color, bool reduceFx) {
    // Format time as MM:SS or just SS if under a minute
    final seconds = _remainingTime.ceil();
    final displayMinutes = seconds ~/ 60;
    final displaySeconds = seconds % 60;

    String timeText;
    if (displayMinutes > 0) {
      timeText =
          '${displayMinutes.toString().padLeft(2, '0')}:${displaySeconds.toString().padLeft(2, '0')}';
    } else {
      timeText = displaySeconds.toString().padLeft(2, '0');
    }

    // Draw using seven-segment style digits
    final digitHeight = radius * 0.5;
    final digitWidth = digitHeight * 0.6;
    final digitSpacing = digitWidth * 0.3;
    final colonWidth = digitWidth * 0.3;

    // Calculate total width
    double totalWidth;
    if (displayMinutes > 0) {
      totalWidth = digitWidth * 4 + digitSpacing * 3 + colonWidth;
    } else {
      totalWidth = digitWidth * 2 + digitSpacing;
    }

    var x = center.dx - totalWidth / 2;
    final y = center.dy - digitHeight / 2;

    // Glow layer
    if (!reduceFx) {
      _digitGlowPaint.color = color.withOpacity(0.5);
    }
    _digitPaint.color = color.withOpacity(0.95);

    if (displayMinutes > 0) {
      // Minutes
      _drawDigit(canvas, x, y, digitWidth, digitHeight,
          displayMinutes ~/ 10, color, reduceFx);
      x += digitWidth + digitSpacing;
      _drawDigit(canvas, x, y, digitWidth, digitHeight,
          displayMinutes % 10, color, reduceFx);
      x += digitWidth + digitSpacing;

      // Colon
      _drawColon(canvas, x, y, colonWidth, digitHeight, color, reduceFx);
      x += colonWidth + digitSpacing;
    }

    // Seconds
    _drawDigit(canvas, x, y, digitWidth, digitHeight,
        displaySeconds ~/ 10, color, reduceFx);
    x += digitWidth + digitSpacing;
    _drawDigit(canvas, x, y, digitWidth, digitHeight,
        displaySeconds % 10, color, reduceFx);

    // Label below digits
    final labelY = center.dy + digitHeight / 2 + 8;
    _dataPaint.color = color.withOpacity(0.5);
    _dataPaint.strokeWidth = 1;

    // Draw "TIME" as small text using lines
    final labelX = center.dx - 15;
    // T
    canvas.drawLine(Offset(labelX, labelY), Offset(labelX + 6, labelY), _dataPaint);
    canvas.drawLine(Offset(labelX + 3, labelY), Offset(labelX + 3, labelY + 6), _dataPaint);
    // I
    canvas.drawLine(Offset(labelX + 9, labelY), Offset(labelX + 9, labelY + 6), _dataPaint);
    // M
    canvas.drawLine(Offset(labelX + 12, labelY + 6), Offset(labelX + 12, labelY), _dataPaint);
    canvas.drawLine(Offset(labelX + 12, labelY), Offset(labelX + 15, labelY + 3), _dataPaint);
    canvas.drawLine(Offset(labelX + 15, labelY + 3), Offset(labelX + 18, labelY), _dataPaint);
    canvas.drawLine(Offset(labelX + 18, labelY), Offset(labelX + 18, labelY + 6), _dataPaint);
    // E
    canvas.drawLine(Offset(labelX + 21, labelY), Offset(labelX + 21, labelY + 6), _dataPaint);
    canvas.drawLine(Offset(labelX + 21, labelY), Offset(labelX + 26, labelY), _dataPaint);
    canvas.drawLine(Offset(labelX + 21, labelY + 3), Offset(labelX + 25, labelY + 3), _dataPaint);
    canvas.drawLine(Offset(labelX + 21, labelY + 6), Offset(labelX + 26, labelY + 6), _dataPaint);
  }

  void _renderHolographicFrame(
      Canvas canvas, Offset center, double radius, Color color, bool reduceFx) {
    final pulse = 0.6 + math.sin(_pulsePhase) * 0.2;

    // Outer frame glow
    if (!reduceFx) {
      _frameGlowPaint.color = color.withOpacity(0.2 * pulse);
      canvas.drawCircle(center, radius, _frameGlowPaint);
    }

    // Main frame
    _framePaint.color = color.withOpacity(0.6 * pulse);
    canvas.drawCircle(center, radius, _framePaint);

    // Corner brackets
    _cornerPaint.color = color.withOpacity(0.9);
    final bracketLen = radius * 0.25;
    final bracketOffset = radius * 0.85;

    // Top-left
    _drawCornerBracket(
        canvas, center.dx - bracketOffset, center.dy - bracketOffset,
        bracketLen, true, true);
    // Top-right
    _drawCornerBracket(
        canvas, center.dx + bracketOffset, center.dy - bracketOffset,
        bracketLen, false, true);
    // Bottom-left
    _drawCornerBracket(
        canvas, center.dx - bracketOffset, center.dy + bracketOffset,
        bracketLen, true, false);
    // Bottom-right
    _drawCornerBracket(
        canvas, center.dx + bracketOffset, center.dy + bracketOffset,
        bracketLen, false, false);

    // Data lines emanating from corners
    if (!reduceFx) {
      _dataPaint.color = color.withOpacity(0.3);
      _dataPaint.strokeWidth = 1;
      final dataLen = radius * 0.15;

      for (int i = 0; i < 4; i++) {
        final angle = -math.pi / 4 + (i * math.pi / 2);
        final startR = radius + 2;
        final endR = radius + 2 + dataLen;
        canvas.drawLine(
          Offset(center.dx + math.cos(angle) * startR,
              center.dy + math.sin(angle) * startR),
          Offset(center.dx + math.cos(angle) * endR,
              center.dy + math.sin(angle) * endR),
          _dataPaint,
        );
      }
    }
  }

  void _renderUrgencyPulse(
      Canvas canvas, Offset center, double radius, Color color) {
    if (urgencyLevel <= 0) return;

    // Pulsing rings that expand outward
    final pulseCount = isCritical ? 3 : (isWarning ? 2 : 1);
    for (int i = 0; i < pulseCount; i++) {
      final phase = (_pulsePhase * 2 + i * (math.pi * 2 / pulseCount)) %
          (math.pi * 2);
      final pulseProgress = phase / (math.pi * 2);
      final pulseRadius = radius + pulseProgress * 20;
      final pulseAlpha = (1.0 - pulseProgress) * urgencyLevel * 0.4;

      _pulseRingPaint.color = color.withOpacity(pulseAlpha);
      canvas.drawCircle(center, pulseRadius, _pulseRingPaint);
    }
  }

  void _renderWarningIndicators(
      Canvas canvas, Offset center, double radius, Color color) {
    // Warning triangles at cardinal points
    final warningPulse = 0.5 + math.sin(_pulsePhase * 3) * 0.5;
    _warningPaint.color = color.withOpacity(warningPulse * 0.6);

    final triangleSize = radius * 0.12;
    final triangleDistance = radius + 15;

    for (int i = 0; i < 4; i++) {
      final angle = -math.pi / 2 + (i * math.pi / 2);
      final tx = center.dx + math.cos(angle) * triangleDistance;
      final ty = center.dy + math.sin(angle) * triangleDistance;

      // Draw small warning triangle pointing outward
      _hexPath.reset();
      _hexPath.moveTo(
          tx + math.cos(angle) * triangleSize,
          ty + math.sin(angle) * triangleSize);
      _hexPath.lineTo(
          tx + math.cos(angle + 2.5) * triangleSize * 0.6,
          ty + math.sin(angle + 2.5) * triangleSize * 0.6);
      _hexPath.lineTo(
          tx + math.cos(angle - 2.5) * triangleSize * 0.6,
          ty + math.sin(angle - 2.5) * triangleSize * 0.6);
      _hexPath.close();

      canvas.drawPath(_hexPath, _warningPaint);
    }

    // "WARNING" text indicator at bottom
    if (isCritical) {
      final warningY = center.dy + radius + 25;
      _dataPaint.color = color.withOpacity(warningPulse);
      _dataPaint.strokeWidth = 1.5;

      // Draw "CRITICAL" using lines
      final critX = center.dx - 30;
      // C
      canvas.drawLine(
          Offset(critX + 5, warningY), Offset(critX, warningY), _dataPaint);
      canvas.drawLine(
          Offset(critX, warningY), Offset(critX, warningY + 6), _dataPaint);
      canvas.drawLine(
          Offset(critX, warningY + 6), Offset(critX + 5, warningY + 6), _dataPaint);
      // R
      canvas.drawLine(
          Offset(critX + 8, warningY), Offset(critX + 8, warningY + 6), _dataPaint);
      canvas.drawLine(
          Offset(critX + 8, warningY), Offset(critX + 12, warningY), _dataPaint);
      canvas.drawLine(
          Offset(critX + 12, warningY), Offset(critX + 12, warningY + 3), _dataPaint);
      canvas.drawLine(
          Offset(critX + 12, warningY + 3), Offset(critX + 8, warningY + 3), _dataPaint);
      canvas.drawLine(
          Offset(critX + 10, warningY + 3), Offset(critX + 13, warningY + 6), _dataPaint);
      // I
      canvas.drawLine(
          Offset(critX + 16, warningY), Offset(critX + 16, warningY + 6), _dataPaint);
      // T
      canvas.drawLine(
          Offset(critX + 19, warningY), Offset(critX + 25, warningY), _dataPaint);
      canvas.drawLine(
          Offset(critX + 22, warningY), Offset(critX + 22, warningY + 6), _dataPaint);
    }
  }

  void _renderFlashEffect(
      Canvas canvas, Offset center, double radius, Color color) {
    // Flash overlay
    _flashPaint.color = color.withOpacity(_flashAlpha);
    canvas.drawCircle(center, radius + 10, _flashPaint);

    // Bright ring flash
    _pulseRingPaint.color = Colors.white.withOpacity(_flashAlpha * 0.8);
    _pulseRingPaint.strokeWidth = 4;
    canvas.drawCircle(center, radius, _pulseRingPaint);
    _pulseRingPaint.strokeWidth = 2; // Reset
  }

  void _renderGlitchOverlay(
      Canvas canvas, Offset center, double radius, Color color) {
    final random = _FastRng(_glitchFrame);

    // Horizontal glitch bars
    final barCount = (5 * _glitchIntensity).floor();
    for (int i = 0; i < barCount; i++) {
      final y = center.dy - radius + random.nextDouble() * radius * 2;
      final height = 1 + random.nextDouble() * 3;
      final xOffset = (random.nextDouble() - 0.5) * 10 * _glitchIntensity;
      final barColor =
          random.nextBool() ? const Color(0xFF00FFFF) : const Color(0xFFFF0044);

      _glitchPaint.color = barColor.withOpacity(0.3 * _glitchIntensity);

      final dx = math.sqrt(math.max(0, radius * radius - (y - center.dy) * (y - center.dy)));
      canvas.drawRect(
        Rect.fromLTWH(center.dx - dx + xOffset, y, dx * 2, height),
        _glitchPaint,
      );
    }

    // Chromatic aberration on digits
    if (_glitchIntensity > 0.5) {
      // Red shift
      _glitchPaint.color = const Color(0xFFFF0044).withOpacity(0.2 * _glitchIntensity);
      canvas.save();
      canvas.translate(-2 * _glitchIntensity, 0);
      canvas.drawCircle(center, radius * 0.3, _glitchPaint);
      canvas.restore();

      // Cyan shift
      _glitchPaint.color = const Color(0xFF00FFFF).withOpacity(0.2 * _glitchIntensity);
      canvas.save();
      canvas.translate(2 * _glitchIntensity, 0);
      canvas.drawCircle(center, radius * 0.3, _glitchPaint);
      canvas.restore();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void _drawMiniHex(Canvas canvas, double cx, double cy, double radius) {
    _hexPath.reset();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        _hexPath.moveTo(x, y);
      } else {
        _hexPath.lineTo(x, y);
      }
    }
    _hexPath.close();
    canvas.drawPath(_hexPath, _hexPaint);
  }

  void _drawCornerBracket(Canvas canvas, double x, double y, double size,
      bool left, bool top) {
    final hDir = left ? 1.0 : -1.0;
    final vDir = top ? 1.0 : -1.0;

    canvas.drawLine(
      Offset(x, y),
      Offset(x + size * hDir, y),
      _cornerPaint,
    );
    canvas.drawLine(
      Offset(x, y),
      Offset(x, y + size * vDir),
      _cornerPaint,
    );
  }

  /// Draw a seven-segment style digit
  void _drawDigit(Canvas canvas, double x, double y, double width,
      double height, int digit, Color color, bool reduceFx) {
    // Seven segment layout:
    //  _0_
    // |   |
    // 5   1
    // |_6_|
    // |   |
    // 4   2
    // |_3_|

    final segments = _getSegments(digit);
    final segmentLength = width * 0.8;
    final segmentGap = width * 0.1;
    final halfHeight = height / 2;

    final cx = x + width / 2;

    if (!reduceFx) {
      _digitGlowPaint.color = color.withOpacity(0.4);
    }
    _digitPaint.color = color.withOpacity(0.95);

    // Segment 0 (top horizontal)
    if (segments[0]) {
      _drawSegment(canvas, cx - segmentLength / 2, y, cx + segmentLength / 2, y,
          color, reduceFx);
    }

    // Segment 1 (top-right vertical)
    if (segments[1]) {
      _drawSegment(canvas, cx + segmentLength / 2, y + segmentGap,
          cx + segmentLength / 2, y + halfHeight - segmentGap, color, reduceFx);
    }

    // Segment 2 (bottom-right vertical)
    if (segments[2]) {
      _drawSegment(canvas, cx + segmentLength / 2, y + halfHeight + segmentGap,
          cx + segmentLength / 2, y + height - segmentGap, color, reduceFx);
    }

    // Segment 3 (bottom horizontal)
    if (segments[3]) {
      _drawSegment(canvas, cx - segmentLength / 2, y + height,
          cx + segmentLength / 2, y + height, color, reduceFx);
    }

    // Segment 4 (bottom-left vertical)
    if (segments[4]) {
      _drawSegment(canvas, cx - segmentLength / 2, y + halfHeight + segmentGap,
          cx - segmentLength / 2, y + height - segmentGap, color, reduceFx);
    }

    // Segment 5 (top-left vertical)
    if (segments[5]) {
      _drawSegment(canvas, cx - segmentLength / 2, y + segmentGap,
          cx - segmentLength / 2, y + halfHeight - segmentGap, color, reduceFx);
    }

    // Segment 6 (middle horizontal)
    if (segments[6]) {
      _drawSegment(canvas, cx - segmentLength / 2, y + halfHeight,
          cx + segmentLength / 2, y + halfHeight, color, reduceFx);
    }
  }

  void _drawSegment(Canvas canvas, double x1, double y1, double x2, double y2,
      Color color, bool reduceFx) {
    if (!reduceFx) {
      _digitGlowPaint.color = color.withOpacity(0.4);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), _digitGlowPaint);
    }
    _digitPaint.color = color.withOpacity(0.95);
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), _digitPaint);
  }

  void _drawColon(Canvas canvas, double x, double y, double width,
      double height, Color color, bool reduceFx) {
    final cx = x + width / 2;
    final dotRadius = width * 0.2;

    // Blink effect for colon
    final blink = math.sin(_pulsePhase * 2) > 0 ? 1.0 : 0.4;

    if (!reduceFx) {
      _digitGlowPaint.color = color.withOpacity(0.4 * blink);
      canvas.drawCircle(
          Offset(cx, y + height * 0.3), dotRadius + 2, _digitGlowPaint);
      canvas.drawCircle(
          Offset(cx, y + height * 0.7), dotRadius + 2, _digitGlowPaint);
    }

    _digitPaint.color = color.withOpacity(0.95 * blink);
    _digitPaint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, y + height * 0.3), dotRadius, _digitPaint);
    canvas.drawCircle(Offset(cx, y + height * 0.7), dotRadius, _digitPaint);
    _digitPaint.style = PaintingStyle.stroke;
  }

  /// Returns which segments should be lit for a digit (0-9)
  List<bool> _getSegments(int digit) {
    // Segment order: [0-top, 1-topRight, 2-bottomRight, 3-bottom,
    //                 4-bottomLeft, 5-topLeft, 6-middle]
    const segmentMap = <int, List<bool>>{
      0: [true, true, true, true, true, true, false],
      1: [false, true, true, false, false, false, false],
      2: [true, true, false, true, true, false, true],
      3: [true, true, true, true, false, false, true],
      4: [false, true, true, false, false, true, true],
      5: [true, false, true, true, false, true, true],
      6: [true, false, true, true, true, true, true],
      7: [true, true, true, false, false, false, false],
      8: [true, true, true, true, true, true, true],
      9: [true, true, true, true, false, true, true],
    };
    return segmentMap[digit] ?? [false, false, false, false, false, false, false];
  }
}

