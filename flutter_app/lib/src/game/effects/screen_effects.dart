import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Screen-wide visual effects manager
class ScreenEffects extends PositionComponent {
  ScreenEffects({
    required this.gameSize,
    this.enableCRT = true,
    this.enableVignette = true,
    this.enableScanlines = true,
    this.enableFlash = true,
  }) : _random = math.Random();

  final Vector2 gameSize;
  final bool enableCRT;
  final bool enableVignette;
  final bool enableScanlines;
  final bool enableFlash;
  final math.Random _random;
  bool reduceFx = false;
  bool allowBlur = true;

  // Screen shake
  double _shakeIntensity = 0;
  double _shakeDuration = 0;
  double _shakeTimer = 0;
  Vector2 _shakeOffset = Vector2.zero();

  // Damage vignette (red flash on edges)
  double _damageVignetteIntensity = 0;
  double _damageVignetteTimer = 0;

  // CRT effect timing
  double _crtTime = 0;
  double _scanlineOffset = 0;

  // Chromatic aberration during shake
  double _chromaticAberration = 0;

  // Trauma value for shader-based post-process (0-1)
  double _trauma = 0;
  static const double _traumaDecay = 0.7;

  // Flash effect
  double _flashIntensity = 0;
  double _flashTimer = 0;
  Color _flashColor = Colors.white;

  /// Current trauma value (0-1) for shader overlays
  double get trauma => _trauma;

  void setQuality({required bool reduceFx, required bool allowBlur}) {
    this.reduceFx = reduceFx;
    this.allowBlur = allowBlur;
  }

  /// Add trauma intensity (0-1)
  void addTrauma(double amount) {
    _trauma = (_trauma + amount).clamp(0.0, 1.0);
  }

  /// Current shake offset to apply to camera
  Vector2 get shakeOffset => _shakeOffset;

  /// Trigger screen shake
  void triggerShake({
    double intensity = 5.0,
    double duration = 0.2,
  }) {
    _shakeIntensity = math.max(_shakeIntensity, intensity);
    _shakeDuration = duration;
    _shakeTimer = 0;
    _chromaticAberration = intensity * 0.3;
  }

  /// Trigger damage vignette (red flash on edges)
  void triggerDamageVignette({double intensity = 0.5}) {
    _damageVignetteIntensity = intensity.clamp(0.0, 1.0);
    _damageVignetteTimer = 0.3;
  }

  /// Trigger full screen flash
  void triggerFlash({
    Color color = Colors.white,
    double intensity = 0.5,
    double duration = 0.1,
  }) {
    if (!enableFlash) return;
    _flashColor = color;
    _flashIntensity = intensity;
    _flashTimer = duration;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _crtTime += dt;
    _scanlineOffset = (_scanlineOffset + dt * 50) % 4;

    // Update screen shake
    if (_shakeTimer < _shakeDuration) {
      _shakeTimer += dt;
      final progress = _shakeTimer / _shakeDuration;
      final decay = 1 - progress;

      _shakeOffset = Vector2(
        (_random.nextDouble() - 0.5) * 2 * _shakeIntensity * decay,
        (_random.nextDouble() - 0.5) * 2 * _shakeIntensity * decay,
      );

      _chromaticAberration = _shakeIntensity * 0.3 * decay;
    } else {
      _shakeOffset = Vector2.zero();
      _shakeIntensity = 0;
      _chromaticAberration = 0;
    }

    // Update damage vignette
    if (_damageVignetteTimer > 0) {
      _damageVignetteTimer -= dt;
      if (_damageVignetteTimer <= 0) {
        _damageVignetteIntensity = 0;
      }
    }

    // Update flash
    if (_flashTimer > 0) {
      _flashTimer -= dt;
    }

    // Decay trauma
    if (_trauma > 0) {
      _trauma = (_trauma - dt * _traumaDecay).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final screenRect = Rect.fromLTWH(0, 0, gameSize.x, gameSize.y);

    // Draw CRT effects
    if (enableCRT && !reduceFx) {
      _renderCRTEffect(canvas, screenRect);
    }

    // Draw scanlines
    if (enableScanlines && !reduceFx) {
      _renderScanlines(canvas, screenRect);
    }

    // Draw vignette
    if (enableVignette && !reduceFx) {
      _renderVignette(canvas, screenRect);
    }

    // Draw damage vignette
    if (_damageVignetteIntensity > 0) {
      _renderDamageVignette(canvas, screenRect);
    }

    // Draw flash
    if (_flashTimer > 0 && enableFlash) {
      _renderFlash(canvas, screenRect);
    }

    // Draw chromatic aberration hint at edges
    if (_chromaticAberration > 0 && !reduceFx) {
      _renderChromaticHint(canvas, screenRect);
    }
  }

  void _renderCRTEffect(Canvas canvas, Rect screenRect) {
    // Subtle CRT curvature effect at corners
    final cornerDarkness = 0.15;

    // Top-left corner
    _drawCornerShadow(canvas, screenRect.topLeft, cornerDarkness);
    // Top-right corner
    _drawCornerShadow(canvas, screenRect.topRight, cornerDarkness);
    // Bottom-left corner
    _drawCornerShadow(canvas, screenRect.bottomLeft, cornerDarkness);
    // Bottom-right corner
    _drawCornerShadow(canvas, screenRect.bottomRight, cornerDarkness);

    // Subtle flicker effect
    final flickerIntensity = math.sin(_crtTime * 60) * 0.01 + 0.01;
    if (flickerIntensity > 0.015) {
      canvas.drawRect(
        screenRect,
        Paint()..color = Colors.white.withOpacity(flickerIntensity),
      );
    }
  }

  void _drawCornerShadow(Canvas canvas, Offset corner, double intensity) {
    final gradient = RadialGradient(
      center: Alignment(
        corner.dx < gameSize.x / 2 ? -1 : 1,
        corner.dy < gameSize.y / 2 ? -1 : 1,
      ),
      radius: 0.8,
      colors: [
        Colors.black.withOpacity(intensity),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: corner, radius: gameSize.x * 0.4));

    canvas.drawCircle(
      corner,
      gameSize.x * 0.4,
      Paint()..shader = gradient,
    );
  }

  void _renderScanlines(Canvas canvas, Rect screenRect) {
    // Draw horizontal scanlines
    final scanlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.08);

    for (double y = _scanlineOffset; y < screenRect.height; y += 4) {
      canvas.drawLine(
        Offset(0, y),
        Offset(screenRect.width, y),
        scanlinePaint,
      );
    }

    // Occasional brighter scanline (moving)
    final brightScanlineY = ((_crtTime * 30) % screenRect.height);
    canvas.drawLine(
      Offset(0, brightScanlineY),
      Offset(screenRect.width, brightScanlineY),
      Paint()
        ..color = Colors.white.withOpacity(0.03)
        ..strokeWidth = 2,
    );
  }

  void _renderVignette(Canvas canvas, Rect screenRect) {
    // Radial gradient vignette
    final center = Offset(screenRect.width / 2, screenRect.height / 2);
    final radius = math.max(screenRect.width, screenRect.height) * 0.7;

    final gradient = RadialGradient(
      colors: [
        Colors.transparent,
        Colors.transparent,
        Colors.black.withOpacity(0.3),
        Colors.black.withOpacity(0.6),
      ],
      stops: const [0.0, 0.5, 0.8, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawRect(screenRect, Paint()..shader = gradient);

    // Neon border glow
    _renderNeonBorder(canvas, screenRect);
  }

  void _renderNeonBorder(Canvas canvas, Rect screenRect) {
    final borderPulse = 0.3 + math.sin(_crtTime * 2) * 0.1;

    // Cyan glow at edges
    final borderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00FFFF).withOpacity(borderPulse),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, screenRect.width, 10));

    // Top border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenRect.width, 3),
      Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(borderPulse * 0.5)
        ..maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 5) : null,
    );

    // Bottom border
    canvas.drawRect(
      Rect.fromLTWH(0, screenRect.height - 3, screenRect.width, 3),
      Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(borderPulse * 0.5)
        ..maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 5) : null,
    );

    // Left border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 3, screenRect.height),
      Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(borderPulse * 0.5)
        ..maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 5) : null,
    );

    // Right border
    canvas.drawRect(
      Rect.fromLTWH(screenRect.width - 3, 0, 3, screenRect.height),
      Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(borderPulse * 0.5)
        ..maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 5) : null,
    );
  }

  void _renderDamageVignette(Canvas canvas, Rect screenRect) {
    final center = Offset(screenRect.width / 2, screenRect.height / 2);
    final radius = math.max(screenRect.width, screenRect.height) * 0.6;

    final vignetteProgress = _damageVignetteTimer / 0.3;
    final intensity = _damageVignetteIntensity * vignetteProgress;

    // Pulsing effect
    final pulse = 1 + math.sin(_crtTime * 20) * 0.1;

    final gradient = RadialGradient(
      colors: [
        Colors.transparent,
        Colors.transparent,
        const Color(0xFFFF0066).withOpacity(intensity * 0.3 * pulse),
        const Color(0xFFFF0066).withOpacity(intensity * 0.7 * pulse),
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawRect(screenRect, Paint()..shader = gradient);
  }

  void _renderFlash(Canvas canvas, Rect screenRect) {
    final flashProgress = _flashTimer / 0.1;
    final alpha = _flashIntensity * flashProgress;

    canvas.drawRect(
      screenRect,
      Paint()..color = _flashColor.withOpacity(alpha),
    );
  }

  void _renderChromaticHint(Canvas canvas, Rect screenRect) {
    // Draw subtle color separation at edges during shake
    final aberrationAmount = _chromaticAberration;

    // Red channel shift (left edge)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, aberrationAmount * 2, screenRect.height),
      Paint()
        ..color = Colors.red.withOpacity(0.1)
        ..maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 3) : null,
    );

    // Cyan channel shift (right edge)
    canvas.drawRect(
      Rect.fromLTWH(
        screenRect.width - aberrationAmount * 2,
        0,
        aberrationAmount * 2,
        screenRect.height,
      ),
      Paint()
        ..color = Colors.cyan.withOpacity(0.1)
        ..maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 3) : null,
    );
  }
}
