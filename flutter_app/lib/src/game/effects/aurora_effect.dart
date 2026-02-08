import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// =============================================================================
// CACHED STATIC PAINTS - Avoid per-frame allocations
// =============================================================================

// Layer 1: Base sky gradient
final Paint _skyGradientPaint = Paint();

// Layer 2: Star field
final Paint _starPaint = Paint();
final Paint _starGlowPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

// Layer 3: Main aurora curtains
final Paint _auroraCurtainPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
final Paint _auroraCurtainCorePaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
final Paint _auroraCurtainBrightPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

// Layer 4: Secondary aurora layers
final Paint _auroraSecondaryPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
final Paint _auroraSecondaryCenterPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

// Layer 5: Aurora particles/shimmer
final Paint _auroraParticlePaint = Paint();
final Paint _auroraParticleGlowPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

// Layer 6: Atmospheric glow overlay
final Paint _atmosphericGlowPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

// Reusable Path objects
final Path _auroraPath = Path();
final Path _secondaryPath = Path();

/// Aurora borealis (northern lights) background effect for night levels.
/// Creates a cyberpunk-style aurora with multiple visual layers:
/// - Layer 1: Base sky gradient (dark blues/purples)
/// - Layer 2: Star field behind aurora
/// - Layer 3: Main aurora curtains (flowing vertical waves)
/// - Layer 4: Secondary aurora layers at different speeds
/// - Layer 5: Shimmering particles within aurora
/// - Layer 6: Atmospheric glow overlay
class AuroraEffect extends PositionComponent {
  AuroraEffect({
    this.reduceFx = false,
    this.lowFx = false,
    this.intensity = 1.0,
    this.horizonY = 0.55,
  }) : _rngState = 42;

  // ═══════════════════════════════════════════════════════════════════════════
  // SHADER CACHE - Avoid per-frame createShader() allocations
  // ═══════════════════════════════════════════════════════════════════════════
  Shader? _cachedSkyShader;
  double _cachedSkyColorShift = -1;
  double _cachedSkyAlpha = -1;
  double _cachedAuroraBottom = -1;

  // Atmospheric glow shaders
  Shader? _cachedHorizonGlowShader;
  Shader? _cachedUpperGlowShader;
  Shader? _cachedLeftGlowShader;
  Shader? _cachedRightGlowShader;
  double _cachedGlowPulse = -1;
  double _cachedGlowAlpha = -1;
  int _cachedGlowColorT = -1;

  void _invalidateShaderCache() {
    _cachedSkyShader = null;
    _cachedSkyColorShift = -1;
    _cachedHorizonGlowShader = null;
    _cachedUpperGlowShader = null;
    _cachedLeftGlowShader = null;
    _cachedRightGlowShader = null;
  }

  /// Reduce effects for performance
  bool reduceFx;

  /// Minimal effects mode
  bool lowFx;

  /// Overall intensity multiplier (0.0 - 1.0)
  double intensity;

  /// Horizon position as a fraction of height (0.0 = top, 1.0 = bottom)
  final double horizonY;

  int _rngState;
  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }
  double _nextUnit() => _lcgNext() / 0x7fffffff;
  int _nextInt(int max) => max <= 0 ? 0 : _lcgNext() % max;
  double _time = 0;

  // Aurora color palette - cyberpunk night theme
  static const Color _auroraGreen = Color(0xFF00FF88);
  static const Color _auroraCyan = Color(0xFF00FFFF);
  static const Color _auroraPurple = Color(0xFF9900FF);
  static const Color _auroraPink = Color(0xFFFF0088);

  // Star field data
  late List<_Star> _stars;

  // Aurora curtain data (main layer)
  late List<_AuroraCurtain> _mainCurtains;

  // Secondary aurora layers
  late List<_AuroraCurtain> _secondaryCurtains;

  // Shimmer particles
  late List<_AuroraParticle> _particles;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    priority = -99; // Render behind most elements, just above background
    _initializeStars();
    _initializeMainCurtains();
    _initializeSecondaryCurtains();
    _initializeParticles();
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
    position = Vector2.zero();
    _invalidateShaderCache(); // Invalidate cached shaders on resize
    _initializeStars();
    _initializeMainCurtains();
    _initializeSecondaryCurtains();
    _initializeParticles();
  }

  void _initializeStars() {
    if (size.isZero()) return;

    final starCount = lowFx ? 30 : (reduceFx ? 60 : 120);
    _stars = List.generate(starCount, (i) {
      return _Star(
        x: _nextUnit() * size.x,
        y: _nextUnit() * size.y * horizonY * 0.95,
        size: 0.5 + _nextUnit() * 2,
        brightness: 0.3 + _nextUnit() * 0.7,
        twinkleSpeed: 1 + _nextUnit() * 3,
        twinklePhase: _nextUnit() * math.pi * 2,
      );
    });
  }

  void _initializeMainCurtains() {
    if (size.isZero()) return;

    final curtainCount = lowFx ? 2 : (reduceFx ? 3 : 5);
    _mainCurtains = List.generate(curtainCount, (i) {
      final t = i / curtainCount;
      return _AuroraCurtain(
        xOffset: t * size.x * 0.8,
        width: 150 + _nextUnit() * 200,
        height: size.y * horizonY * (0.4 + _nextUnit() * 0.3),
        waveFrequency: 0.8 + _nextUnit() * 0.6,
        waveAmplitude: 30 + _nextUnit() * 50,
        verticalWaveFrequency: 2 + _nextUnit() * 2,
        speed: 0.3 + _nextUnit() * 0.4,
        colorPhase: _nextUnit() * math.pi * 2,
        colorSpeed: 0.2 + _nextUnit() * 0.3,
      );
    });
  }

  void _initializeSecondaryCurtains() {
    if (size.isZero()) return;

    final curtainCount = lowFx ? 1 : (reduceFx ? 2 : 4);
    _secondaryCurtains = List.generate(curtainCount, (i) {
      final t = i / curtainCount;
      return _AuroraCurtain(
        xOffset: t * size.x + _nextUnit() * 100,
        width: 200 + _nextUnit() * 300,
        height: size.y * horizonY * (0.25 + _nextUnit() * 0.2),
        waveFrequency: 0.5 + _nextUnit() * 0.4,
        waveAmplitude: 40 + _nextUnit() * 60,
        verticalWaveFrequency: 1.5 + _nextUnit() * 1.5,
        speed: 0.15 + _nextUnit() * 0.25,
        colorPhase: _nextUnit() * math.pi * 2 + math.pi,
        colorSpeed: 0.15 + _nextUnit() * 0.2,
      );
    });
  }

  void _initializeParticles() {
    if (size.isZero()) return;

    final particleCount = lowFx ? 0 : (reduceFx ? 15 : 40);
    _particles = List.generate(particleCount, (i) {
      return _AuroraParticle(
        x: _nextUnit() * size.x,
        y: _nextUnit() * size.y * horizonY * 0.8,
        size: 1 + _nextUnit() * 2.5,
        velocityX: (_nextUnit() - 0.5) * 8,
        velocityY: (_nextUnit() - 0.5) * 4,
        lifetime: 3 + _nextUnit() * 4,
        maxLifetime: 3 + _nextUnit() * 4,
        colorPhase: _nextUnit() * math.pi * 2,
        shimmerSpeed: 3 + _nextUnit() * 4,
      );
    });
  }

  /// Set quality level
  void setQuality({required bool reduceFx, required bool lowFx}) {
    final needsReinit = this.reduceFx != reduceFx || this.lowFx != lowFx;
    this.reduceFx = reduceFx;
    this.lowFx = lowFx;
    if (needsReinit && !size.isZero()) {
      _initializeStars();
      _initializeMainCurtains();
      _initializeSecondaryCurtains();
      _initializeParticles();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (lowFx && intensity < 0.3) return;

    _time += dt;

    // Update particles
    if (_particles.isNotEmpty) {
      _updateParticles(dt);
    }
  }

  void _updateParticles(double dt) {
    for (final particle in _particles) {
      particle.x += particle.velocityX * dt;
      particle.y += particle.velocityY * dt;
      particle.lifetime -= dt;
      particle.colorPhase += particle.shimmerSpeed * dt;

      // Wrap around horizontally
      if (particle.x < 0) particle.x = size.x;
      if (particle.x > size.x) particle.x = 0;

      // Respawn if lifetime expired or out of bounds
      if (particle.lifetime <= 0 || particle.y < 0 || particle.y > size.y * horizonY) {
        particle.x = _nextUnit() * size.x;
        particle.y = _nextUnit() * size.y * horizonY * 0.8;
        particle.lifetime = particle.maxLifetime;
        particle.velocityX = (_nextUnit() - 0.5) * 8;
        particle.velocityY = (_nextUnit() - 0.5) * 4;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.isZero()) return;
    if (lowFx && intensity < 0.3) return;

    final globalAlpha = intensity.clamp(0.0, 1.0);
    if (globalAlpha <= 0.01) return;
    final auroraBottom = size.y * horizonY;
    if (_stars.isEmpty &&
        _mainCurtains.isEmpty &&
        _secondaryCurtains.isEmpty &&
        _particles.isEmpty &&
        reduceFx) {
      return;
    }

    // Clip to aurora region (above horizon)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.x, auroraBottom));

    // =========================================================================
    // LAYER 1: Base sky gradient (dark blues/purples)
    // =========================================================================
    _renderSkyGradient(canvas, globalAlpha, auroraBottom);

    // =========================================================================
    // LAYER 2: Star field behind aurora
    // =========================================================================
    _renderStarField(canvas, globalAlpha);

    // =========================================================================
    // LAYER 3: Secondary aurora layers (behind main, slower)
    // =========================================================================
    if (!lowFx) {
      _renderSecondaryCurtains(canvas, globalAlpha, auroraBottom);
    }

    // =========================================================================
    // LAYER 4: Main aurora curtains (flowing vertical waves)
    // =========================================================================
    _renderMainCurtains(canvas, globalAlpha, auroraBottom);

    // =========================================================================
    // LAYER 5: Shimmering particles within aurora
    // =========================================================================
    if (!lowFx) {
      _renderParticles(canvas, globalAlpha);
    }

    // =========================================================================
    // LAYER 6: Atmospheric glow overlay
    // =========================================================================
    if (!reduceFx) {
      _renderAtmosphericGlow(canvas, globalAlpha, auroraBottom);
    }

    canvas.restore();
  }

  /// Layer 1: Base sky gradient with cyberpunk night colors
  void _renderSkyGradient(Canvas canvas, double globalAlpha, double auroraBottom) {
    final rect = Rect.fromLTWH(0, 0, size.x, auroraBottom);

    // Animated color shift - quantize to avoid excessive shader recreation
    final colorShift = math.sin(_time * 0.1) * 0.5 + 0.5;
    final quantizedColorShift = (colorShift * 20).roundToDouble() / 20; // ~20 discrete steps

    // Use cached shader if parameters haven't changed significantly
    if (_cachedSkyShader == null ||
        _cachedSkyColorShift != quantizedColorShift ||
        _cachedSkyAlpha != globalAlpha ||
        _cachedAuroraBottom != auroraBottom) {
      _cachedSkyShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(const Color(0xFF0D0221), const Color(0xFF050510), quantizedColorShift)!
              .withOpacity(globalAlpha), // Deep space at top
          Color.lerp(const Color(0xFF1A0033), const Color(0xFF0A0020), quantizedColorShift)!
              .withOpacity(globalAlpha),
          Color.lerp(const Color(0xFF240046), const Color(0xFF150030), quantizedColorShift)!
              .withOpacity(globalAlpha),
          Color.lerp(const Color(0xFF1A0033), const Color(0xFF0D0221), quantizedColorShift)!
              .withOpacity(globalAlpha * 0.8), // Fade toward horizon
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(rect);
      _cachedSkyColorShift = quantizedColorShift;
      _cachedSkyAlpha = globalAlpha;
      _cachedAuroraBottom = auroraBottom;
    }

    _skyGradientPaint.shader = _cachedSkyShader;
    canvas.drawRect(rect, _skyGradientPaint);
  }

  /// Layer 2: Twinkling star field
  void _renderStarField(Canvas canvas, double globalAlpha) {
    for (final star in _stars) {
      // Twinkle effect
      final twinkle = 0.5 + math.sin(_time * star.twinkleSpeed + star.twinklePhase) * 0.5;
      final alpha = star.brightness * twinkle * globalAlpha;

      if (alpha < 0.1) continue;

      // Star glow (only in non-reduced mode)
      if (!reduceFx && star.size > 1.2) {
        _starGlowPaint.color = _auroraCyan.withOpacity(alpha * 0.3);
        canvas.drawCircle(Offset(star.x, star.y), star.size * 2, _starGlowPaint);
      }

      // Star core
      _starPaint.color = Colors.white.withOpacity(alpha);
      canvas.drawCircle(Offset(star.x, star.y), star.size, _starPaint);
    }
  }

  /// Layer 3: Secondary aurora curtains (behind main layer, slower movement)
  void _renderSecondaryCurtains(Canvas canvas, double globalAlpha, double auroraBottom) {
    for (final curtain in _secondaryCurtains) {
      _renderSingleCurtain(
        canvas,
        curtain,
        globalAlpha * 0.4,
        auroraBottom,
        _auroraSecondaryPaint,
        _auroraSecondaryCenterPaint,
        isSecondary: true,
      );
    }
  }

  /// Layer 4: Main aurora curtains with color transitions
  void _renderMainCurtains(Canvas canvas, double globalAlpha, double auroraBottom) {
    for (final curtain in _mainCurtains) {
      _renderSingleCurtain(
        canvas,
        curtain,
        globalAlpha * 0.7,
        auroraBottom,
        _auroraCurtainPaint,
        _auroraCurtainCorePaint,
        isSecondary: false,
      );
    }
  }

  /// Render a single aurora curtain
  void _renderSingleCurtain(
    Canvas canvas,
    _AuroraCurtain curtain,
    double alpha,
    double auroraBottom,
    Paint outerPaint,
    Paint innerPaint, {
    required bool isSecondary,
  }) {
    // Calculate animated color based on time and curtain phase
    final colorPhase = _time * curtain.colorSpeed + curtain.colorPhase;
    final colorT = (math.sin(colorPhase) + 1) / 2;
    final colorKey = (colorT * 200).round();
    final alphaKey = (alpha * 200).round();
    final quantizedColorT = (colorT * 24).roundToDouble() / 24;

    // Color transition: green -> cyan -> purple -> pink -> green
    Color baseColor;
    Color brightColor;

    if (quantizedColorT < 0.25) {
      final t = quantizedColorT / 0.25;
      baseColor = Color.lerp(_auroraGreen, _auroraCyan, t)!;
      brightColor = Color.lerp(_auroraCyan, Colors.white, 0.3)!;
    } else if (quantizedColorT < 0.5) {
      final t = (quantizedColorT - 0.25) / 0.25;
      baseColor = Color.lerp(_auroraCyan, _auroraPurple, t)!;
      brightColor = Color.lerp(_auroraCyan, Colors.white, 0.3)!;
    } else if (quantizedColorT < 0.75) {
      final t = (quantizedColorT - 0.5) / 0.25;
      baseColor = Color.lerp(_auroraPurple, _auroraPink, t)!;
      brightColor = Color.lerp(_auroraPink, Colors.white, 0.3)!;
    } else {
      final t = (quantizedColorT - 0.75) / 0.25;
      baseColor = Color.lerp(_auroraPink, _auroraGreen, t)!;
      brightColor = Color.lerp(_auroraGreen, Colors.white, 0.3)!;
    }

    // Build curtain path using sine waves
    final path = isSecondary ? _secondaryPath : _auroraPath;
    path.reset();

    final steps = reduceFx ? 20 : 40;

    // Animated wave offset
    final waveOffset = _time * curtain.speed;

    // Start from bottom left of curtain
    final startX = curtain.xOffset + math.sin(waveOffset * curtain.waveFrequency) * curtain.waveAmplitude;
    path.moveTo(startX, auroraBottom);

    // Draw left edge going up
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final y = auroraBottom - curtain.height * t;

      // Horizontal wave (curtain undulation)
      final horizontalWave = math.sin(
            waveOffset * curtain.waveFrequency + t * curtain.verticalWaveFrequency,
          ) *
          curtain.waveAmplitude *
          (1 - t * 0.3); // Reduce amplitude toward top

      // Add secondary wave for more natural look
      final secondaryWave = math.sin(
            waveOffset * curtain.waveFrequency * 1.7 + t * curtain.verticalWaveFrequency * 2.3,
          ) *
          curtain.waveAmplitude *
          0.3 *
          (1 - t * 0.5);

      final x = curtain.xOffset + horizontalWave + secondaryWave;
      path.lineTo(x, y);
    }

    // Draw right edge going down
    for (int i = steps; i >= 0; i--) {
      final t = i / steps;
      final y = auroraBottom - curtain.height * t;

      // Offset wave for right edge
      final horizontalWave = math.sin(
            waveOffset * curtain.waveFrequency + t * curtain.verticalWaveFrequency + 0.5,
          ) *
          curtain.waveAmplitude *
          (1 - t * 0.3);

      final secondaryWave = math.sin(
            waveOffset * curtain.waveFrequency * 1.7 + t * curtain.verticalWaveFrequency * 2.3 + 0.3,
          ) *
          curtain.waveAmplitude *
          0.3 *
          (1 - t * 0.5);

      final x = curtain.xOffset + curtain.width + horizontalWave + secondaryWave;
      path.lineTo(x, y);
    }

    path.close();

    // Create vertical gradient for curtain
    final gradientRect = Rect.fromLTWH(
      curtain.xOffset - curtain.waveAmplitude,
      auroraBottom - curtain.height,
      curtain.width + curtain.waveAmplitude * 2,
      curtain.height,
    );
    final rectW = gradientRect.width.round();
    final rectH = gradientRect.height.round();

    // Outer glow layer
    outerPaint.shader = curtain.getOuterShader(
      colorKey: colorKey,
      alphaKey: alphaKey,
      rectW: rectW,
      rectH: rectH,
      baseColor: baseColor,
      alpha: alpha,
      rect: gradientRect,
    );

    canvas.drawPath(path, outerPaint);

    // Inner brighter core
    if (!reduceFx) {
      innerPaint.shader = curtain.getInnerShader(
        colorKey: colorKey,
        alphaKey: alphaKey,
        rectW: rectW,
        rectH: rectH,
        brightColor: brightColor,
        alpha: alpha,
        rect: gradientRect,
      );

      canvas.drawPath(path, innerPaint);
    }

    // Brightest core (center streak) - only for main curtains
    if (!isSecondary && !reduceFx) {
      // Draw bright vertical streaks within the curtain
      final streakCount = lowFx ? 2 : 4;
      for (int s = 0; s < streakCount; s++) {
        final streakT = (s + 0.5) / streakCount;
        final streakPhase = _time * (0.5 + s * 0.1) + s * math.pi / 2;
        final streakX = curtain.xOffset +
            curtain.width * streakT +
            math.sin(streakPhase) * curtain.waveAmplitude * 0.5;

        final streakHeight = curtain.height * (0.4 + math.sin(streakPhase * 1.3) * 0.2);
        final streakTop = auroraBottom - streakHeight;

        _auroraCurtainBrightPaint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            brightColor.withOpacity(alpha * 0.3),
            Colors.white.withOpacity(alpha * 0.4),
            brightColor.withOpacity(alpha * 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
        ).createShader(Rect.fromLTWH(streakX - 10, streakTop, 20, streakHeight));

        canvas.drawRect(
          Rect.fromLTWH(streakX - 5, streakTop, 10, streakHeight),
          _auroraCurtainBrightPaint,
        );
      }
    }
  }

  /// Layer 5: Shimmering particles floating within aurora
  void _renderParticles(Canvas canvas, double globalAlpha) {
    if (_particles.isEmpty) return;
    for (final particle in _particles) {
      final lifeRatio = particle.lifetime / particle.maxLifetime;
      if (lifeRatio <= 0) continue;

      // Fade in/out at start and end of life
      double fadeAlpha;
      if (lifeRatio > 0.8) {
        fadeAlpha = (1 - lifeRatio) / 0.2;
      } else if (lifeRatio < 0.2) {
        fadeAlpha = lifeRatio / 0.2;
      } else {
        fadeAlpha = 1.0;
      }

      // Shimmer effect
      final shimmer = 0.5 + math.sin(particle.colorPhase) * 0.5;
      final alpha = globalAlpha * fadeAlpha * shimmer;

      if (alpha < 0.1) continue;

      // Color based on phase
      final colorT = (math.sin(particle.colorPhase * 0.3) + 1) / 2;
      final particleColor = Color.lerp(_auroraCyan, _auroraGreen, colorT)!;

      // Glow
      _auroraParticleGlowPaint.color = particleColor.withOpacity(alpha * 0.4);
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size * 2.5,
        _auroraParticleGlowPaint,
      );

      // Core
      _auroraParticlePaint.color =
          Color.lerp(particleColor, Colors.white, shimmer * 0.5)!.withOpacity(alpha);
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        _auroraParticlePaint,
      );
    }
  }

  /// Layer 6: Atmospheric glow overlay at horizon
  void _renderAtmosphericGlow(Canvas canvas, double globalAlpha, double auroraBottom) {
    // Animated glow intensity - quantize to reduce shader recreation
    final glowPulse = 0.3 + math.sin(_time * 0.5) * 0.1;
    final quantizedGlowPulse = (glowPulse * 10).roundToDouble() / 10;

    // Calculate dominant aurora color from time - quantize
    final colorPhase = _time * 0.15;
    final colorT = (math.sin(colorPhase) + 1) / 2;
    final quantizedColorT = (colorT * 10).round(); // 0-10 discrete steps
    final glowColor = Color.lerp(_auroraGreen, _auroraCyan, colorT)!;

    // Check if we need to recreate cached shaders
    final needsRecreate = _cachedHorizonGlowShader == null ||
        _cachedGlowPulse != quantizedGlowPulse ||
        _cachedGlowAlpha != globalAlpha ||
        _cachedGlowColorT != quantizedColorT ||
        _cachedAuroraBottom != auroraBottom;

    // Horizon glow (where aurora meets the horizon)
    final horizonRect = Rect.fromLTWH(
      0,
      auroraBottom - 80,
      size.x,
      100,
    );

    if (needsRecreate) {
      _cachedHorizonGlowShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          glowColor.withOpacity(quantizedGlowPulse * globalAlpha * 0.3),
          glowColor.withOpacity(quantizedGlowPulse * globalAlpha * 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(horizonRect);
    }

    _atmosphericGlowPaint.shader = _cachedHorizonGlowShader;
    canvas.drawRect(horizonRect, _atmosphericGlowPaint);

    // Upper sky glow (reflection on atmosphere)
    final upperRect = Rect.fromLTWH(0, 0, size.x, auroraBottom * 0.3);

    if (needsRecreate) {
      _cachedUpperGlowShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          glowColor.withOpacity(quantizedGlowPulse * globalAlpha * 0.05),
          glowColor.withOpacity(quantizedGlowPulse * globalAlpha * 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(upperRect);
    }

    _atmosphericGlowPaint.shader = _cachedUpperGlowShader;
    canvas.drawRect(upperRect, _atmosphericGlowPaint);

    // Side glows (aurora light bleeding to edges)
    if (!reduceFx) {
      final sideWidth = size.x * 0.2;

      // Left side glow
      final leftRect = Rect.fromLTWH(0, 0, sideWidth, auroraBottom);
      if (needsRecreate) {
        _cachedLeftGlowShader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _auroraPurple.withOpacity(quantizedGlowPulse * globalAlpha * 0.08),
            Colors.transparent,
          ],
        ).createShader(leftRect);
      }
      _atmosphericGlowPaint.shader = _cachedLeftGlowShader;
      canvas.drawRect(leftRect, _atmosphericGlowPaint);

      // Right side glow
      final rightRect = Rect.fromLTWH(size.x - sideWidth, 0, sideWidth, auroraBottom);
      if (needsRecreate) {
        _cachedRightGlowShader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            _auroraPink.withOpacity(quantizedGlowPulse * globalAlpha * 0.08),
            Colors.transparent,
          ],
        ).createShader(rightRect);
      }
      _atmosphericGlowPaint.shader = _cachedRightGlowShader;
      canvas.drawRect(rightRect, _atmosphericGlowPaint);
    }

    // Update cache tracking variables
    if (needsRecreate) {
      _cachedGlowPulse = quantizedGlowPulse;
      _cachedGlowAlpha = globalAlpha;
      _cachedGlowColorT = quantizedColorT;
      _cachedAuroraBottom = auroraBottom;
    }
  }
}

// =============================================================================
// HELPER DATA CLASSES
// =============================================================================

/// Star data for the star field layer
class _Star {
  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
    required this.twinkleSpeed,
    required this.twinklePhase,
  });

  final double x;
  final double y;
  final double size;
  final double brightness;
  final double twinkleSpeed;
  final double twinklePhase;
}

/// Aurora curtain data for main and secondary layers
class _AuroraCurtain {
  _AuroraCurtain({
    required this.xOffset,
    required this.width,
    required this.height,
    required this.waveFrequency,
    required this.waveAmplitude,
    required this.verticalWaveFrequency,
    required this.speed,
    required this.colorPhase,
    required this.colorSpeed,
  });

  final double xOffset;
  final double width;
  final double height;
  final double waveFrequency;
  final double waveAmplitude;
  final double verticalWaveFrequency;
  final double speed;
  final double colorPhase;
  final double colorSpeed;

  Shader? _outerShader;
  Shader? _innerShader;
  int _outerColorKey = -1;
  int _outerAlphaKey = -1;
  int _outerW = -1;
  int _outerH = -1;
  int _innerColorKey = -1;
  int _innerAlphaKey = -1;
  int _innerW = -1;
  int _innerH = -1;

  Shader getOuterShader({
    required int colorKey,
    required int alphaKey,
    required int rectW,
    required int rectH,
    required Color baseColor,
    required double alpha,
    required Rect rect,
  }) {
    if (_outerShader == null ||
        _outerColorKey != colorKey ||
        _outerAlphaKey != alphaKey ||
        _outerW != rectW ||
        _outerH != rectH) {
      _outerShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          baseColor.withOpacity(0),
          baseColor.withOpacity(alpha * 0.2),
          baseColor.withOpacity(alpha * 0.4),
          baseColor.withOpacity(alpha * 0.3),
          baseColor.withOpacity(0),
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(rect);
      _outerColorKey = colorKey;
      _outerAlphaKey = alphaKey;
      _outerW = rectW;
      _outerH = rectH;
    }
    return _outerShader!;
  }

  Shader getInnerShader({
    required int colorKey,
    required int alphaKey,
    required int rectW,
    required int rectH,
    required Color brightColor,
    required double alpha,
    required Rect rect,
  }) {
    if (_innerShader == null ||
        _innerColorKey != colorKey ||
        _innerAlphaKey != alphaKey ||
        _innerW != rectW ||
        _innerH != rectH) {
      _innerShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          brightColor.withOpacity(0),
          brightColor.withOpacity(alpha * 0.15),
          brightColor.withOpacity(alpha * 0.25),
          brightColor.withOpacity(alpha * 0.15),
          brightColor.withOpacity(0),
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(rect);
      _innerColorKey = colorKey;
      _innerAlphaKey = alphaKey;
      _innerW = rectW;
      _innerH = rectH;
    }
    return _innerShader!;
  }
}

/// Particle data for shimmer effect within aurora
class _AuroraParticle {
  _AuroraParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.velocityX,
    required this.velocityY,
    required this.lifetime,
    required this.maxLifetime,
    required this.colorPhase,
    required this.shimmerSpeed,
  });

  double x;
  double y;
  final double size;
  double velocityX;
  double velocityY;
  double lifetime;
  final double maxLifetime;
  double colorPhase;
  final double shimmerSpeed;
}
