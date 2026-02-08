import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../entities/enemy.dart';

/// Type of damage for different visual styles
enum DamageNumberType {
  /// Normal damage (red/orange)
  damage,

  /// Critical hit (yellow/white, larger)
  critical,

  /// Healing effect (green)
  heal,

  /// Shield damage (cyan)
  shield,
}

/// Holographic damage numbers with physics bounce effect
/// Features: glow, scanlines, chromatic aberration, physics simulation
class DamageNumberEffect extends PositionComponent {
  DamageNumberEffect._internal({
    required Vector2 position,
    required int damageAmount,
    required DamageNumberType type,
    required double duration,
  }) : _rngState = 0x1234abcd {
    _reset(
      position: position,
      damageAmount: damageAmount,
      type: type,
      duration: duration,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OBJECT POOLING - Follows explosion_effect.dart pattern
  // ═══════════════════════════════════════════════════════════════════════════
  static const int maxPool = 32;
  static const int maxActive = 24;
  static final List<DamageNumberEffect> _pool = [];
  static int _activeCount = 0;
  static double fxScale = 1.0;
  static bool reduceFx = false;
  static bool lowFx = false;
  static int get activeCount => _activeCount;

  /// Cached blur filters to avoid per-frame allocations
  static final Map<int, MaskFilter> _blurCache = {};

  static MaskFilter _blur(double sigma) {
    var key = sigma.round();
    if (key < 1) key = 1;
    if (key > 20) key = 20;
    return _blurCache.putIfAbsent(
      key,
      () => MaskFilter.blur(BlurStyle.normal, key.toDouble()),
    );
  }

  /// Clear the static pool to prevent memory accumulation between games
  static void clearPool() {
    for (final item in _pool) {
      item._cachedPainter?.dispose();
      item._cachedPainter = null;
    }
    _pool.clear();
    _activeCount = 0;
  }

  /// Spawn a damage number effect from the pool
  static DamageNumberEffect? spawn({
    required Vector2 position,
    required int damageAmount,
    DamageNumberType type = DamageNumberType.damage,
    double duration = 1.5,
  }) {
    if (_activeCount >= maxActive) return null;
    DamageNumberEffect effect;
    if (_pool.isNotEmpty) {
      effect = _pool.removeLast();
      effect._reset(
        position: position,
        damageAmount: damageAmount,
        type: type,
        duration: duration,
      );
    } else {
      effect = DamageNumberEffect._internal(
        position: position,
        damageAmount: damageAmount,
        type: type,
        duration: duration,
      );
    }
    effect._markActive();
    return effect;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _textShadowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _scanlinePaint = Paint();
  static final Paint _chromaRedPaint = Paint()
    ..blendMode = BlendMode.plus;
  static final Paint _chromaBluePaint = Paint()
    ..blendMode = BlendMode.plus;
  static final Paint _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _holoPaint = Paint();
  static final Paint _flickerPaint = Paint();
  static final Paint _alphaPaint = Paint();

  // Reusable path for scanlines
  static final Path _scanlinePath = Path();
  static int _staticRngState = 0x5f3759df;
  static int _lcgNext(int state) => (state * 1664525 + 1013904223) & 0x7fffffff;
  static double _staticUnit() {
    _staticRngState = _lcgNext(_staticRngState);
    return _staticRngState / 0x7fffffff;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INSTANCE PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════════
  int damageAmount = 0;
  DamageNumberType type = DamageNumberType.damage;
  double duration = 1.5;

  int _rngState;
  int _lcgNextLocal(int state) => (state * 1664525 + 1013904223) & 0x7fffffff;
  double _nextUnit() {
    _rngState = _lcgNextLocal(_rngState);
    return _rngState / 0x7fffffff;
  }
  double _timer = 0;
  bool _counted = false;
  bool _inPool = false;
  double _offscreenAccumulator = 0;
  static const double _offscreenUpdateInterval = 0.12;

  // Physics simulation
  double _velocityY = 0;
  double _velocityX = 0;
  static const double _gravity = 280.0;
  static const double _initialUpwardVelocity = -120.0;
  static const double _bounceThreshold = 30.0; // Y offset where bounce occurs
  static const double _bounceDamping = 0.4;
  int _bounceCount = 0;
  static const int _maxBounces = 1;
  double _yOffset = 0;

  // Visual effects state
  double _flickerTimer = 0;
  double _glitchOffset = 0;
  late double _wobblePhase;
  late double _scaleVariation;

  // Cached TextPainter
  TextPainter? _cachedPainter;
  String _cachedText = '';
  double _cachedFontSize = 0;
  double _cachedTextWidth = 0;
  double _cachedTextHeight = 0;
  Rect? _cachedTextLayerRect;

  void _markActive() {
    if (_counted) return;
    _counted = true;
    _inPool = false;
    _activeCount++;
  }

  void _reset({
    required Vector2 position,
    required int damageAmount,
    required DamageNumberType type,
    required double duration,
  }) {
    this.position.setFrom(position);
    anchor = Anchor.center;
    this.damageAmount = damageAmount;
    this.type = type;
    this.duration = duration;
    _timer = 0;
    _yOffset = 0;
    _bounceCount = 0;

    // Initialize physics with random horizontal velocity
    _velocityY = _initialUpwardVelocity * (0.8 + _nextUnit() * 0.4);
    _velocityX = (_nextUnit() - 0.5) * 40;

    // Visual effect randomization
    _flickerTimer = 0;
    _glitchOffset = 0;
    _wobblePhase = _nextUnit() * math.pi * 2;
    _scaleVariation = 0.9 + _nextUnit() * 0.2;
  }

  /// Get the base color for damage type
  Color get _baseColor {
    switch (type) {
      case DamageNumberType.damage:
        return const Color(0xFFFF3366); // Neon red/pink
      case DamageNumberType.critical:
        return const Color(0xFFFFDD00); // Bright yellow
      case DamageNumberType.heal:
        return const Color(0xFF00FF88); // Neon green
      case DamageNumberType.shield:
        return const Color(0xFF00DDFF); // Cyan
    }
  }

  /// Get the glow color (usually brighter version of base)
  Color get _glowColor {
    switch (type) {
      case DamageNumberType.damage:
        return const Color(0xFFFF0044);
      case DamageNumberType.critical:
        return const Color(0xFFFFFF00);
      case DamageNumberType.heal:
        return const Color(0xFF00FFAA);
      case DamageNumberType.shield:
        return const Color(0xFF00FFFF);
    }
  }

  /// Calculate font size based on damage amount
  double get _fontSize {
    // Base size scales with damage
    double base = 14.0;
    if (damageAmount >= 1000) {
      base = 22.0;
    } else if (damageAmount >= 500) {
      base = 20.0;
    } else if (damageAmount >= 100) {
      base = 18.0;
    } else if (damageAmount >= 50) {
      base = 16.0;
    }

    // Critical hits are larger
    if (type == DamageNumberType.critical) {
      base *= 1.3;
    }

    return base * _scaleVariation;
  }

  /// Format the damage text
  String get _displayText {
    if (type == DamageNumberType.heal) {
      return '+$damageAmount';
    }
    return damageAmount.toString();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isOffscreen()) {
      _offscreenAccumulator += dt;
      if (_offscreenAccumulator < _offscreenUpdateInterval) {
        return;
      }
      dt = _offscreenAccumulator;
      _offscreenAccumulator = 0;
    } else if (_offscreenAccumulator > 0) {
      dt += _offscreenAccumulator;
      _offscreenAccumulator = 0;
    }

    _timer += dt;
    _flickerTimer += dt;

    if (_timer >= duration) {
      _recycle();
      return;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PHYSICS SIMULATION
    // ═══════════════════════════════════════════════════════════════════════
    // Apply gravity
    _velocityY += _gravity * dt;

    // Update position
    _yOffset += _velocityY * dt;
    position.x += _velocityX * dt;

    // Apply drag to horizontal movement
    _velocityX *= 0.98;

    // Bounce physics
    if (_yOffset > _bounceThreshold && _bounceCount < _maxBounces && _velocityY > 0) {
      _velocityY = -_velocityY * _bounceDamping;
      _yOffset = _bounceThreshold;
      _bounceCount++;

      // Add a glitch effect on bounce
      _glitchOffset = (_nextUnit() - 0.5) * 8;
    }

    // Gradually reduce glitch offset
    _glitchOffset *= 0.9;

    // Random flicker for holographic effect
    if (_flickerTimer > 0.05 + _nextUnit() * 0.1) {
      _flickerTimer = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_isOffscreen()) return;
    super.render(canvas);

    if (lowFx) {
      _renderSimple(canvas);
      return;
    }

    final progress = (_timer / duration).clamp(0.0, 1.0);

    // Fade out in the last 30% of duration
    double alpha;
    if (progress < 0.7) {
      alpha = 1.0;
    } else {
      alpha = 1.0 - ((progress - 0.7) / 0.3);
    }
    if (alpha <= 0.01) return;

    // Scale animation - pop in, then slight shrink
    double scale;
    if (progress < 0.1) {
      // Quick pop-in
      scale = progress / 0.1 * 1.2;
    } else if (progress < 0.2) {
      // Settle to normal
      scale = 1.2 - (progress - 0.1) / 0.1 * 0.2;
    } else {
      // Gradual shrink
      scale = 1.0 - (progress - 0.2) * 0.15;
    }

    // Apply holographic wobble
    final wobble = math.sin(_timer * 15 + _wobblePhase) * 0.02;
    scale *= (1 + wobble);

    // Ensure we have a valid painter
    _ensurePainter();
    if (_cachedPainter == null) return;

    canvas.save();

    // Apply Y offset from physics
    canvas.translate(_glitchOffset, _yOffset);

    // Apply scale
    canvas.scale(scale, scale);

    final textWidth = _cachedTextWidth;
    final textHeight = _cachedTextHeight;
    final textOffset = Offset(-textWidth / 2, -textHeight / 2);
    final textLayerRect = _cachedTextLayerRect!;

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: GLOW BEHIND TEXT
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx) {
      _glowPaint.color = _glowColor.withOpacity(alpha * 0.5);
      canvas.saveLayer(textLayerRect, _glowPaint);
      _cachedPainter!.paint(canvas, textOffset);
      canvas.restore();

      // Secondary softer glow
      _textShadowPaint.color = _baseColor.withOpacity(alpha * 0.3);
      _textShadowPaint.maskFilter = _blur(12);
      canvas.saveLayer(textLayerRect, _textShadowPaint);
      _cachedPainter!.paint(canvas, textOffset);
      canvas.restore();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: CHROMATIC ABERRATION
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx) {
      final chromaOffset = 1.5 + math.sin(_timer * 8) * 0.5;

      // Red channel offset
      _chromaRedPaint.color = const Color(0xFFFF0000).withOpacity(alpha * 0.25);
      canvas.saveLayer(textLayerRect, _chromaRedPaint);
      _cachedPainter!.paint(canvas, textOffset + Offset(-chromaOffset, 0));
      canvas.restore();

      // Blue channel offset
      _chromaBluePaint.color = const Color(0xFF0066FF).withOpacity(alpha * 0.25);
      canvas.saveLayer(textLayerRect, _chromaBluePaint);
      _cachedPainter!.paint(canvas, textOffset + Offset(chromaOffset, 0));
      canvas.restore();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: MAIN TEXT
    // ═══════════════════════════════════════════════════════════════════════
    if (alpha >= 0.99) {
      _cachedPainter!.paint(canvas, textOffset);
    } else {
      _alphaPaint.color = Color.fromRGBO(255, 255, 255, alpha);
      canvas.saveLayer(textLayerRect, _alphaPaint);
      _cachedPainter!.paint(canvas, textOffset);
      canvas.restore();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: SCANLINES ACROSS TEXT
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx && alpha > 0.2) {
      _drawScanlines(canvas, textOffset, textWidth, textHeight, alpha);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: HOLOGRAPHIC OUTLINE
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx && type == DamageNumberType.critical && alpha > 0.25) {
      // Draw pulsing outline for critical hits
      final outlineAlpha = alpha * (0.4 + math.sin(_timer * 20) * 0.2);
      _outlinePaint.color = Colors.white.withOpacity(outlineAlpha);
      _outlinePaint.maskFilter = _blur(2);
      canvas.saveLayer(textLayerRect, _outlinePaint);
      _cachedPainter!.paint(canvas, textOffset + const Offset(-1, -1));
      _cachedPainter!.paint(canvas, textOffset + const Offset(1, -1));
      _cachedPainter!.paint(canvas, textOffset + const Offset(-1, 1));
      _cachedPainter!.paint(canvas, textOffset + const Offset(1, 1));
      canvas.restore();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: HOLOGRAPHIC FLICKER
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx && _flickerTimer < 0.02 && alpha > 0.25) {
      // Brief bright flash
      _flickerPaint.color = Colors.white.withOpacity(alpha * 0.3);
      canvas.saveLayer(textLayerRect, _flickerPaint);
      _cachedPainter!.paint(canvas, textOffset);
      canvas.restore();
    }

    canvas.restore();
  }

  bool _isOffscreen({double padding = 40}) {
    if (Enemy.screenSize.isZero()) return false;
    if (Enemy.screenScale <= 0) return false;
    final screenX = Enemy.screenOffset.x + position.x * Enemy.screenScale;
    final screenY = Enemy.screenOffset.y + position.y * Enemy.screenScale;
    return screenX < -padding ||
        screenY < -padding ||
        screenX > Enemy.screenSize.x + padding ||
        screenY > Enemy.screenSize.y + padding;
  }

  /// Render simplified version for low FX mode
  void _renderSimple(Canvas canvas) {
    final progress = (_timer / duration).clamp(0.0, 1.0);
    final alpha = progress < 0.7 ? 1.0 : 1.0 - ((progress - 0.7) / 0.3);

    _ensurePainter();
    if (_cachedPainter == null) return;

    canvas.save();
    canvas.translate(0, _yOffset);

    final textLayerRect = _cachedTextLayerRect!;
    final textOffset = Offset(-_cachedTextWidth / 2, -_cachedTextHeight / 2);
    if (alpha >= 0.99) {
      _cachedPainter!.paint(canvas, textOffset);
    } else {
      _alphaPaint.color = Color.fromRGBO(255, 255, 255, alpha);
      canvas.saveLayer(textLayerRect, _alphaPaint);
      _cachedPainter!.paint(canvas, textOffset);
      canvas.restore();
    }

    canvas.restore();
  }

  /// Draw holographic scanlines over the text
  void _drawScanlines(
    Canvas canvas,
    Offset textOffset,
    double textWidth,
    double textHeight,
    double alpha,
  ) {
    // Animate scanlines moving down
    final scanlineOffset = (_timer * 50) % 6;

    _scanlinePath.reset();

    // Draw horizontal scanlines
    for (double y = textOffset.dy - 2 + scanlineOffset; y < textOffset.dy + textHeight + 2; y += 6) {
      _scanlinePath.moveTo(textOffset.dx - 4, y);
      _scanlinePath.lineTo(textOffset.dx + textWidth + 4, y);
    }

    _scanlinePaint
      ..color = _baseColor.withOpacity(alpha * 0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawPath(_scanlinePath, _scanlinePaint);

    // Occasional brighter scanline
    if (_staticUnit() > 0.97) {
      final brightY = textOffset.dy + _staticUnit() * textHeight;
      _scanlinePaint.color = Colors.white.withOpacity(alpha * 0.3);
      canvas.drawLine(
        Offset(textOffset.dx - 4, brightY),
        Offset(textOffset.dx + textWidth + 4, brightY),
        _scanlinePaint,
      );
    }
  }

  /// Ensure the text painter is created and cached
  void _ensurePainter() {
    final text = _displayText;
    final fontSize = _fontSize;

    if (_cachedPainter != null && _cachedText == text && _cachedFontSize == fontSize) {
      return;
    }

    _cachedText = text;
    _cachedFontSize = fontSize;
    _cachedPainter?.dispose();

    _cachedPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: _baseColor,
          fontSize: fontSize,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _cachedTextWidth = _cachedPainter!.width;
    _cachedTextHeight = _cachedPainter!.height;
    _cachedTextLayerRect = Rect.fromLTWH(
      -_cachedTextWidth / 2 - 24,
      -_cachedTextHeight / 2 - 24,
      _cachedTextWidth + 48,
      _cachedTextHeight + 48,
    );
  }

  void _recycle() {
    if (_counted) {
      if (_activeCount > 0) {
        _activeCount -= 1;
      }
      _counted = false;
    }
    if (parent != null) {
      removeFromParent();
    }
    if (_inPool) return;

    // Dispose painter before pooling
    _cachedPainter?.dispose();
    _cachedPainter = null;
    _cachedText = '';
    _cachedFontSize = 0;
    _cachedTextWidth = 0;
    _cachedTextHeight = 0;
    _cachedTextLayerRect = null;

    if (_pool.length < maxPool) {
      _inPool = true;
      _pool.add(this);
    }
  }

  @override
  void onRemove() {
    if (_counted) {
      if (_activeCount > 0) {
        _activeCount -= 1;
      }
      _counted = false;
    }

    // Dispose painter on removal
    _cachedPainter?.dispose();
    _cachedPainter = null;
    _cachedText = '';
    _cachedFontSize = 0;
    _cachedTextWidth = 0;
    _cachedTextHeight = 0;
    _cachedTextLayerRect = null;

    super.onRemove();
  }
}
