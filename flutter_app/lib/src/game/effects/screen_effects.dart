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
  }) {
    _instance = this;
  }

  /// Static instance for global access
  static ScreenEffects? _instance;
  static ScreenEffects? get instance => _instance;

  final Vector2 gameSize;
  final bool enableCRT;
  final bool enableVignette;
  final bool enableScanlines;
  final bool enableFlash;
  int _rngState = 0x12345678;
  bool reduceFx = false;
  bool allowBlur = true;

  int _lcgNext(int state) => (state * 1664525 + 1013904223) & 0x7fffffff;

  double _nextUnit() {
    _rngState = _lcgNext(_rngState);
    return _rngState / 0x7fffffff;
  }

  int _nextInt(int max) {
    if (max <= 0) return 0;
    _rngState = _lcgNext(_rngState);
    return _rngState % max;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHED SHADERS - Avoid per-frame gradient.createShader() allocations
  // ═══════════════════════════════════════════════════════════════════════════
  Shader? _vignetteShader;
  Shader? _cornerShader0; // top-left
  Shader? _cornerShader1; // top-right
  Shader? _cornerShader2; // bottom-left
  Shader? _cornerShader3; // bottom-right
  Size? _lastCachedSize;

  // Cached scanline layer
  Picture? _scanlineLayer;
  double _scanlineLayerWidth = 0;
  double _scanlineLayerHeight = 0;

  // Cached Paint objects for scanlines and borders
  final Paint _scanlinePaint = Paint()
    ..color = const Color(0x14000000); // 0.08 opacity
  final Paint _brightScanlinePaint = Paint()
    ..color = const Color(0x08FFFFFF) // 0.03 opacity
    ..strokeWidth = 2;
  final Paint _flickerPaint = Paint();
  final Paint _neonBorderPaint = Paint();
  final Paint _chromaticRedPaint = Paint()
    ..color = const Color(0x1AFF0000); // 0.1 opacity
  final Paint _chromaticCyanPaint = Paint()
    ..color = const Color(0x1A00FFFF); // 0.1 opacity

  // ═══════════════════════════════════════════════════════════════════════════
  // BIG HIT CHROMATIC SPLIT PAINTS (RGB channel separation)
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _bigHitRedPaint = Paint()
    ..color = const Color(0x33FF0000) // Red channel
    ..blendMode = BlendMode.screen;
  static final Paint _bigHitBluePaint = Paint()
    ..color = const Color(0x330066FF) // Blue channel
    ..blendMode = BlendMode.screen;
  static final Paint _bigHitFlashPaint = Paint()
    ..color = const Color(0x40FFFFFF);
  static final Paint _bigHitVignettePaint = Paint();
  static final Paint _bigHitGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  // ═══════════════════════════════════════════════════════════════════════════
  // ENERGY SHIELD FLASH PAINTS (Base damage protection visualization)
  // ═══════════════════════════════════════════════════════════════════════════
  final Paint _shieldHexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _shieldHexFillPaint = Paint();
  final Paint _shieldGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  final Paint _shieldImpactPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
  final Paint _shieldRipplePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  final Paint _shieldSparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  final Paint _shieldCrackPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  final Paint _shieldOverlayPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _shieldFragmentPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final Paint _shieldCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  final Path _shieldPath = Path();

  // ═══════════════════════════════════════════════════════════════════════════
  // LENS FLARE EFFECT PAINTS (6-Layer Cinematic Light Artifact System)
  // ═══════════════════════════════════════════════════════════════════════════
  // Layer 1: Central bright source glow
  static final Paint _lensFlareSourceGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
  static final Paint _lensFlareSourceCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  // Layer 2: Anamorphic streak (horizontal light streak)
  static final Paint _lensFlareStreakPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  // Layer 3: Hexagonal flare artifacts
  static final Paint _lensFlareHexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _lensFlareHexFillPaint = Paint();
  // Layer 4: Circular rainbow artifacts (chromatic aberration)
  static final Paint _lensFlareRainbowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  // Layer 5: Starburst rays
  static final Paint _lensFlareStarburstPaint = Paint()
    ..strokeCap = StrokeCap.round;
  // Layer 6: Bloom/halo
  static final Paint _lensFlareHaloPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
  // Reusable path for lens flare shapes
  static final Path _lensFlarePath = Path();

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATED NEON BORDER PAINTS
  // ═══════════════════════════════════════════════════════════════════════════
  final Paint _neonBorderOuterGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  final Paint _neonBorderMidGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _neonBorderCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  final Paint _neonBorderPulsePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  final Paint _neonBorderTravelPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  final Paint _neonBorderCornerPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  final Paint _neonBorderScanPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  final Paint _neonBorderAccentPaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  final Paint _neonBorderTickPaint = Paint()..strokeWidth = 1;

  // ═══════════════════════════════════════════════════════════════════════════
  // ADDITIONAL CACHED PAINTS - Avoid per-frame allocations in render methods
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _cornerShaderPaint = Paint();
  static final Paint _vignetteShaderPaint = Paint();
  static final Paint _damageVignettePaint = Paint();
  static final Paint _flashPaint = Paint();
  static final Paint _warningFlashPaint = Paint();

  // Cached border pulse shaders (avoid per-frame createShader)
  Shader? _pulseHorizontalPrimaryShader;
  Shader? _pulseHorizontalSecondaryShader;
  Shader? _pulseVerticalPrimaryShader;
  Shader? _pulseVerticalAccentShader;
  double _pulseShaderWidth = 0;
  double _pulseShaderThickness = 0;
  List<double> _borderTickXs = const [];
  List<double> _borderTickYs = const [];
  double _borderTickWidth = 0;
  double _borderTickHeight = 0;

  // Cached damage vignette / big hit glow shaders
  Shader? _damageVignetteShader;
  Size? _damageVignetteSize;
  Shader? _bigHitGlowShader;
  Size? _bigHitGlowSize;
  double _bigHitGlowRadius = 0;
  static const int _bigHitVignetteLevels = 64;
  final Map<int, Shader> _bigHitVignetteCache = {};
  Size? _bigHitVignetteSize;
  final Map<int, ColorFilter> _intensityFilterCache = {};

  void _invalidateShaderCache() {
    _vignetteShader = null;
    _cornerShader0 = null;
    _cornerShader1 = null;
    _cornerShader2 = null;
    _cornerShader3 = null;
    _lastCachedSize = null;
    _borderTickWidth = 0;
    _borderTickHeight = 0;
    _borderTickXs = const [];
    _borderTickYs = const [];
  }

  void _ensureBorderTickCache(double w, double h) {
    if (w == _borderTickWidth && h == _borderTickHeight) return;
    _borderTickWidth = w;
    _borderTickHeight = h;
    if (w <= 0 || h <= 0) {
      _borderTickXs = const [];
      _borderTickYs = const [];
      return;
    }
    const tickSpacing = 50.0;
    final xs = <double>[];
    for (double x = tickSpacing; x < w - tickSpacing; x += tickSpacing) {
      xs.add(x);
    }
    final ys = <double>[];
    for (double y = tickSpacing; y < h - tickSpacing; y += tickSpacing) {
      ys.add(y);
    }
    _borderTickXs = xs;
    _borderTickYs = ys;
  }

  void _ensureShadersValid(Size size) {
    if (_lastCachedSize == size) return;

    // Cache vignette shader
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(size.width, size.height) * 0.7;
    _vignetteShader = const RadialGradient(
      colors: [
        Colors.transparent,
        Colors.transparent,
        Color(0x4D000000), // 0.3 opacity
        Color(0x99000000), // 0.6 opacity
      ],
      stops: [0.0, 0.5, 0.8, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Cache corner shaders
    final cornerRadius = size.width * 0.4;
    const cornerDarkness = 0.15;
    final cornerGradient = RadialGradient(
      colors: [
        Colors.black.withOpacity(cornerDarkness),
        Colors.transparent,
      ],
    );

    // Top-left
    _cornerShader0 = RadialGradient(
      center: const Alignment(-1, -1),
      radius: 0.8,
      colors: [
        Colors.black.withOpacity(cornerDarkness),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: cornerRadius));

    // Top-right
    _cornerShader1 = RadialGradient(
      center: const Alignment(1, -1),
      radius: 0.8,
      colors: [
        Colors.black.withOpacity(cornerDarkness),
        Colors.transparent,
      ],
    ).createShader(
        Rect.fromCircle(center: Offset(size.width, 0), radius: cornerRadius));

    // Bottom-left
    _cornerShader2 = RadialGradient(
      center: const Alignment(-1, 1),
      radius: 0.8,
      colors: [
        Colors.black.withOpacity(cornerDarkness),
        Colors.transparent,
      ],
    ).createShader(
        Rect.fromCircle(center: Offset(0, size.height), radius: cornerRadius));

    // Bottom-right
    _cornerShader3 = RadialGradient(
      center: const Alignment(1, 1),
      radius: 0.8,
      colors: [
        Colors.black.withOpacity(cornerDarkness),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
        center: Offset(size.width, size.height), radius: cornerRadius));

    _lastCachedSize = size;
  }

  void _ensureScanlineLayer(Size size) {
    if (_scanlineLayer != null &&
        _scanlineLayerWidth == size.width &&
        _scanlineLayerHeight == size.height) {
      return;
    }

    final recorder = PictureRecorder();
    final staticCanvas = Canvas(recorder);
    final height = size.height + 4;
    for (double y = 0; y < height; y += 4) {
      staticCanvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        _scanlinePaint,
      );
    }

    _scanlineLayer?.dispose();
    _scanlineLayer = recorder.endRecording();
    _scanlineLayerWidth = size.width;
    _scanlineLayerHeight = size.height;
  }

  void _ensureBorderPulseShaders(Color primaryColor, Color secondaryColor,
      Color accentColor, double pulseWidth, double thickness) {
    if (_pulseShaderWidth == pulseWidth &&
        _pulseShaderThickness == thickness &&
        _pulseHorizontalPrimaryShader != null) {
      return;
    }

    _pulseShaderWidth = pulseWidth;
    _pulseShaderThickness = thickness;

    _pulseHorizontalPrimaryShader = LinearGradient(
      colors: [
        Colors.transparent,
        primaryColor.withOpacity(0.8),
        Colors.white.withOpacity(0.9),
        primaryColor.withOpacity(0.8),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, pulseWidth, thickness));

    _pulseHorizontalSecondaryShader = LinearGradient(
      colors: [
        Colors.transparent,
        secondaryColor.withOpacity(0.8),
        Colors.white.withOpacity(0.9),
        secondaryColor.withOpacity(0.8),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, pulseWidth, thickness));

    _pulseVerticalPrimaryShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        primaryColor.withOpacity(0.8),
        Colors.white.withOpacity(0.9),
        primaryColor.withOpacity(0.8),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, thickness, pulseWidth));

    _pulseVerticalAccentShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        accentColor.withOpacity(0.8),
        Colors.white.withOpacity(0.9),
        accentColor.withOpacity(0.8),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, thickness, pulseWidth));
  }

  ColorFilter _getIntensityFilter(double intensity) {
    const levels = 32;
    final level = (intensity * levels).round().clamp(0, levels);
    return _intensityFilterCache.putIfAbsent(
      level,
      () => ColorFilter.mode(
        Colors.white.withOpacity(level / levels),
        BlendMode.modulate,
      ),
    );
  }

  void _ensureDamageVignetteShader(Size size) {
    if (_damageVignetteShader != null && _damageVignetteSize == size) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(size.width, size.height) * 0.6;

    _damageVignetteShader = const RadialGradient(
      colors: [
        Colors.transparent,
        Colors.transparent,
        Color(0x4DFF0066), // 0.3 opacity
        Color(0xB2FF0066), // 0.7 opacity
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    _damageVignetteSize = size;
  }

  void _ensureBigHitGlowShader(Size size) {
    final radius = math.min(size.width, size.height) * 0.4;
    if (_bigHitGlowShader != null &&
        _bigHitGlowSize == size &&
        _bigHitGlowRadius == radius) return;

    _bigHitGlowShader = const RadialGradient(
      colors: [
        Color(0xFFFFFFFF),
        Color(0x80FFFFFF),
        Color(0x00000000),
      ],
      stops: [0.0, 0.4, 1.0],
    ).createShader(Rect.fromCircle(
      center: Offset(0, 0),
      radius: radius,
    ));

    _bigHitGlowSize = size;
    _bigHitGlowRadius = radius;
  }

  // Screen shake
  double _shakeIntensity = 0;
  double _shakeDuration = 0;
  double _shakeTimer = 0;
  Vector2 _shakeOffset = Vector2.zero();
  double _shakeRotation = 0; // Subtle rotation shake

  // Big hit effect state (enhanced shake with chromatic split)
  double _bigHitIntensity = 0;
  double _bigHitDuration = 0;
  double _bigHitTimer = 0;
  double _bigHitChromaticOffset = 0; // RGB split distance
  double _bigHitFlashAlpha = 0;
  double _bigHitRotation = 0;

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

  // Energy shield flash state
  double _shieldFlashTimer = 0;
  double _shieldFlashDuration = 0;
  double _shieldFlashIntensity = 0;
  Vector2 _shieldImpactPoint = Vector2.zero();
  List<_ShieldCrack>? _shieldCracks;
  List<_ShieldSpark>? _shieldSparks;

  // ═══════════════════════════════════════════════════════════════════════════
  // LENS FLARE STATE - Tracks active bright sources
  // ═══════════════════════════════════════════════════════════════════════════
  final List<_LensFlareSource> _activeFlareSources = [];
  static const int _maxFlareSources = 8;
  bool enableLensFlare = true;

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

  /// Current shake rotation in radians (for subtle tilt effect)
  double get shakeRotation => _shakeRotation + _bigHitRotation;

  /// Current chromatic split offset (for big hit RGB separation)
  double get chromaticSplitOffset => _bigHitChromaticOffset;

  /// Whether a big hit effect is currently active
  bool get isBigHitActive =>
      _bigHitTimer < _bigHitDuration && _bigHitIntensity > 0;

  /// Smooth ease-out function (deceleration curve)
  static double _easeOutCubic(double t) {
    return 1.0 - math.pow(1 - t, 3).toDouble();
  }

  /// Smooth ease-out quart for stronger deceleration
  static double _easeOutQuart(double t) {
    return 1.0 - math.pow(1 - t, 4).toDouble();
  }

  /// Trigger screen shake with smooth decay
  void triggerShake({
    double intensity = 5.0,
    double duration = 0.2,
  }) {
    _shakeIntensity = math.max(_shakeIntensity, intensity);
    _shakeDuration = duration;
    _shakeTimer = 0;
    _chromaticAberration = intensity * 0.3;
  }

  /// Trigger big hit effect with chromatic split and screen flash
  /// Call this for heavy impacts like boss attacks or massive damage
  void triggerBigHit(double damage) {
    if (reduceFx) {
      // Reduced version for low-end devices
      triggerShake(intensity: damage * 0.4, duration: 0.15);
      return;
    }

    // Scale intensity based on damage (normalized 0-1, clamped)
    final normalizedDamage = (damage / 100).clamp(0.3, 1.0);

    _bigHitIntensity = 8.0 + normalizedDamage * 12.0; // 8-20 shake intensity
    _bigHitDuration = 0.25 + normalizedDamage * 0.15; // 0.25-0.4 seconds
    _bigHitTimer = 0;
    _bigHitChromaticOffset =
        4.0 + normalizedDamage * 8.0; // 4-12 pixel RGB split
    _bigHitFlashAlpha = 0.3 + normalizedDamage * 0.25; // Initial flash opacity

    // Add trauma for shader effects
    addTrauma(0.15 + normalizedDamage * 0.25);

    // Trigger accompanying flash
    triggerFlash(
      color: Colors.white,
      intensity: 0.25 + normalizedDamage * 0.2,
      duration: 0.08,
    );
  }

  /// Static convenience method to trigger shake from anywhere
  static void shake({double intensity = 5.0, double duration = 0.2}) {
    _instance?.triggerShake(intensity: intensity, duration: duration);
  }

  /// Static convenience method to trigger big hit from anywhere
  static void bigHit(double damage) {
    _instance?.triggerBigHit(damage);
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

  /// Trigger energy shield flash when base takes damage
  void triggerShieldFlash({
    double intensity = 0.8,
    double duration = 0.6,
    Vector2? impactPoint,
  }) {
    _shieldFlashIntensity = intensity.clamp(0.0, 1.0);
    _shieldFlashDuration = duration;
    _shieldFlashTimer = 0;
    _shieldImpactPoint = impactPoint ?? Vector2(gameSize.x / 2, gameSize.y);

    // Generate shield cracks from impact point
    _shieldCracks = List.generate(8 + _nextInt(6), (i) {
      final angle = _nextUnit() * math.pi * 2;
      final length = 60 + _nextUnit() * 120;
      return _ShieldCrack(
        angle: angle,
        length: length,
        segments: 3 + _nextInt(4),
        offsetX: (_nextUnit() - 0.5) * 20,
        offsetY: (_nextUnit() - 0.5) * 20,
      );
    });

    // Generate sparks
    _shieldSparks = List.generate(20 + _nextInt(15), (i) {
      final angle = _nextUnit() * math.pi * 2;
      final speed = 100 + _nextUnit() * 200;
      return _ShieldSpark(
        x: _shieldImpactPoint.x,
        y: _shieldImpactPoint.y,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        life: 0.3 + _nextUnit() * 0.4,
        size: 2 + _nextUnit() * 4,
      );
    });
  }

  /// Trigger a lens flare effect at the given position
  /// [position] - Screen position of the bright source
  /// [color] - Base color of the flare (typically tower/projectile color)
  /// [intensity] - Brightness intensity (0.0 - 1.0)
  /// [duration] - How long the flare lasts (in seconds)
  void triggerLensFlare({
    required Vector2 position,
    required Color color,
    double intensity = 0.8,
    double duration = 0.4,
  }) {
    if (!enableLensFlare || reduceFx) return;

    // Limit maximum active flares for performance
    if (_activeFlareSources.length >= _maxFlareSources) {
      // Remove oldest flare
      _activeFlareSources.removeAt(0);
    }

    _activeFlareSources.add(_LensFlareSource(
      position: position.clone(),
      color: color,
      intensity: intensity.clamp(0.0, 1.0),
      duration: duration,
      timer: 0,
      // Generate unique hexagon artifact positions along the flare axis
      hexArtifacts: _generateHexArtifacts(position, 4 + _nextInt(3)),
      // Rainbow artifact rings
      rainbowArtifacts: _generateRainbowArtifacts(position, 3 + _nextInt(2)),
    ));
  }

  /// Static convenience method to trigger lens flare from anywhere
  static void lensFlare({
    required Vector2 position,
    required Color color,
    double intensity = 0.8,
    double duration = 0.4,
  }) {
    _instance?.triggerLensFlare(
      position: position,
      color: color,
      intensity: intensity,
      duration: duration,
    );
  }

  /// Generate hexagonal artifact positions for lens flare
  List<_HexArtifact> _generateHexArtifacts(Vector2 sourcePos, int count) {
    final artifacts = <_HexArtifact>[];
    final screenCenter = Vector2(gameSize.x / 2, gameSize.y / 2);
    final direction = screenCenter - sourcePos;

    for (int i = 0; i < count; i++) {
      final t = (i + 1) / (count + 1) * 1.5; // Position along flare axis
      final artifactPos = sourcePos + direction * t;
      final size = 8 + _nextUnit() * 15 * (1 - t * 0.3);
      final rotation = _nextUnit() * math.pi;

      artifacts.add(_HexArtifact(
        position: artifactPos,
        size: size,
        rotation: rotation,
        opacity: 0.3 + _nextUnit() * 0.4,
      ));
    }

    return artifacts;
  }

  /// Generate rainbow artifact ring data for lens flare
  List<_RainbowArtifact> _generateRainbowArtifacts(
      Vector2 sourcePos, int count) {
    final artifacts = <_RainbowArtifact>[];
    final screenCenter = Vector2(gameSize.x / 2, gameSize.y / 2);
    final direction = screenCenter - sourcePos;

    for (int i = 0; i < count; i++) {
      final t = 0.4 + (i / count) * 0.8;
      final artifactPos = sourcePos + direction * t;
      final radius = 15 + _nextUnit() * 25;

      artifacts.add(_RainbowArtifact(
        position: artifactPos,
        radius: radius,
        rotation: _nextUnit() * math.pi * 2,
      ));
    }

    return artifacts;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final crtActive = enableCRT && !reduceFx;
    final scanlinesActive = enableScanlines && !reduceFx;
    if (crtActive) {
      _crtTime += dt;
    }
    if (scanlinesActive) {
      _scanlineOffset = (_scanlineOffset + dt * 50) % 4;
    }

    final hasShake = _shakeTimer < _shakeDuration;
    final hasBigHit = _bigHitTimer < _bigHitDuration && _bigHitIntensity > 0;
    final hasDamageVignette = _damageVignetteTimer > 0;
    final hasFlash = _flashTimer > 0;
    final hasTrauma = _trauma > 0;
    final hasShield = _shieldFlashTimer < _shieldFlashDuration;
    final hasLens = _activeFlareSources.isNotEmpty;
    if (!hasShake &&
        !hasBigHit &&
        !hasDamageVignette &&
        !hasFlash &&
        !hasTrauma &&
        !hasShield &&
        !hasLens) {
      return;
    }

    // Update screen shake with smooth ease-out decay
    if (hasShake) {
      _shakeTimer += dt;
      final progress = (_shakeTimer / _shakeDuration).clamp(0.0, 1.0);
      // Use ease-out for smooth deceleration
      final decay = 1 - _easeOutCubic(progress);
      final shakeX = (_nextUnit() - 0.5) * 2 * _shakeIntensity * decay;
      final shakeY = (_nextUnit() - 0.5) * 2 * _shakeIntensity * decay;
      _shakeOffset.setValues(shakeX, shakeY);

      // Add subtle rotation shake (max ~2 degrees)
      _shakeRotation =
          (_nextUnit() - 0.5) * 0.035 * _shakeIntensity * decay / 10;

      _chromaticAberration = _shakeIntensity * 0.3 * decay;
    } else {
      _shakeOffset.setZero();
      _shakeIntensity = 0;
      _shakeRotation = 0;
      _chromaticAberration = 0;
    }

    // Update big hit effect (chromatic split + enhanced shake)
    if (hasBigHit) {
      _bigHitTimer += dt;
      final progress = (_bigHitTimer / _bigHitDuration).clamp(0.0, 1.0);
      // Use stronger ease-out quart for dramatic falloff
      final decay = 1 - _easeOutQuart(progress);

      // Combine with regular shake for additive effect
      _shakeOffset.x += (_nextUnit() - 0.5) * 2 * _bigHitIntensity * decay;
      _shakeOffset.y += (_nextUnit() - 0.5) * 2 * _bigHitIntensity * decay;

      // Stronger rotation during big hits (max ~4 degrees)
      _bigHitRotation = (_nextUnit() - 0.5) * 0.07 * decay;

      // Update chromatic split intensity with smooth decay
      _bigHitChromaticOffset *= decay;
      _bigHitFlashAlpha *= decay;
    } else {
      _bigHitChromaticOffset = 0;
      _bigHitFlashAlpha = 0;
      _bigHitRotation = 0;
      _bigHitIntensity = 0;
    }

    // Update damage vignette
    if (hasDamageVignette) {
      _damageVignetteTimer -= dt;
      if (_damageVignetteTimer <= 0) {
        _damageVignetteIntensity = 0;
      }
    }

    // Update flash
    if (hasFlash) {
      _flashTimer -= dt;
    }

    // Decay trauma
    if (hasTrauma) {
      _trauma = (_trauma - dt * _traumaDecay).clamp(0.0, 1.0);
    }

    // Update shield flash
    if (hasShield) {
      _shieldFlashTimer += dt;

      // Update sparks
      final sparks = _shieldSparks;
      if (sparks != null) {
        for (final spark in sparks) {
          spark.x += spark.vx * dt;
          spark.y += spark.vy * dt;
          spark.life -= dt;
          spark.vx *= 0.95;
          spark.vy *= 0.95;
        }
      }
    }

    // Update lens flare sources with single-pass O(n) removal
    if (hasLens) {
      int writeIndex = 0;
      for (int readIndex = 0;
          readIndex < _activeFlareSources.length;
          readIndex++) {
        final source = _activeFlareSources[readIndex];
        source.timer += dt;
        if (source.timer < source.duration) {
          if (writeIndex != readIndex) {
            _activeFlareSources[writeIndex] = source;
          }
          writeIndex++;
        }
      }
      if (writeIndex < _activeFlareSources.length) {
        _activeFlareSources.removeRange(writeIndex, _activeFlareSources.length);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (gameSize.x <= 0 || gameSize.y <= 0) return;

    final crtActive = enableCRT && !reduceFx;
    final scanlinesActive = enableScanlines && !reduceFx;
    final vignetteActive = enableVignette && !reduceFx;
    final flashActive = _flashTimer > 0 && enableFlash;
    final damageActive = _damageVignetteIntensity > 0;
    final chromaActive = _chromaticAberration > 0 && !reduceFx;
    final bigHitActive = _bigHitChromaticOffset > 0.1 && !reduceFx;
    final shieldActive = _shieldFlashTimer < _shieldFlashDuration;
    final lensActive =
        enableLensFlare && _activeFlareSources.isNotEmpty && !reduceFx;

    if (!(crtActive ||
        scanlinesActive ||
        vignetteActive ||
        flashActive ||
        damageActive ||
        chromaActive ||
        bigHitActive ||
        shieldActive ||
        lensActive)) {
      return;
    }

    final screenRect = Rect.fromLTWH(0, 0, gameSize.x, gameSize.y);

    // Ensure shaders are cached only when needed
    final needsShaders = damageActive || (crtActive || vignetteActive);
    if (needsShaders) {
      _ensureShadersValid(Size(gameSize.x, gameSize.y));
    }

    // Draw CRT effects
    if (crtActive) {
      _renderCRTEffect(canvas, screenRect);
    }

    // Draw scanlines
    if (scanlinesActive && gameSize.y > 0) {
      _renderScanlines(canvas, screenRect);
    }

    // Draw vignette
    if (vignetteActive && gameSize.x > 0 && gameSize.y > 0) {
      _renderVignette(canvas, screenRect);
    }

    // Draw damage vignette
    if (damageActive) {
      _renderDamageVignette(canvas, screenRect);
    }

    // Draw flash
    if (flashActive) {
      _renderFlash(canvas, screenRect);
    }

    // Draw chromatic aberration hint at edges
    if (chromaActive) {
      _renderChromaticHint(canvas, screenRect);
    }

    // Draw big hit chromatic split effect (RGB channel separation)
    if (bigHitActive) {
      _renderBigHitChromaticSplit(canvas, screenRect);
    }

    // Draw energy shield flash
    if (shieldActive) {
      _renderShieldFlash(canvas, screenRect);
    }

    // Draw lens flare effects from bright sources
    if (lensActive) {
      _renderLensFlares(canvas, screenRect);
    }
  }

  @override
  void onRemove() {
    _invalidateShaderCache();
    _scanlineLayer?.dispose();
    _scanlineLayer = null;
    super.onRemove();
  }

  void _renderCRTEffect(Canvas canvas, Rect screenRect) {
    // Subtle CRT curvature effect at corners - using cached shaders
    final cornerRadius = gameSize.x * 0.4;

    // Top-left corner
    if (_cornerShader0 != null) {
      _cornerShaderPaint.shader = _cornerShader0;
      canvas.drawCircle(screenRect.topLeft, cornerRadius, _cornerShaderPaint);
    }
    // Top-right corner
    if (_cornerShader1 != null) {
      _cornerShaderPaint.shader = _cornerShader1;
      canvas.drawCircle(screenRect.topRight, cornerRadius, _cornerShaderPaint);
    }
    // Bottom-left corner
    if (_cornerShader2 != null) {
      _cornerShaderPaint.shader = _cornerShader2;
      canvas.drawCircle(
          screenRect.bottomLeft, cornerRadius, _cornerShaderPaint);
    }
    // Bottom-right corner
    if (_cornerShader3 != null) {
      _cornerShaderPaint.shader = _cornerShader3;
      canvas.drawCircle(
          screenRect.bottomRight, cornerRadius, _cornerShaderPaint);
    }

    // Subtle flicker effect - reuse cached paint
    final flickerIntensity = math.sin(_crtTime * 60) * 0.01 + 0.01;
    if (flickerIntensity > 0.015) {
      _flickerPaint.color = Colors.white.withOpacity(flickerIntensity);
      canvas.drawRect(screenRect, _flickerPaint);
    }
  }

  void _renderScanlines(Canvas canvas, Rect screenRect) {
    final w = screenRect.width;
    final h = screenRect.height;
    if (h <= 0 || w <= 0) return;
    _ensureScanlineLayer(Size(w, h));
    if (_scanlineLayer != null) {
      canvas.save();
      canvas.translate(0, -_scanlineOffset);
      canvas.drawPicture(_scanlineLayer!);
      canvas.restore();
    } else {
      // Fallback path if cache isn't ready
      for (double y = _scanlineOffset; y < h; y += 4) {
        canvas.drawLine(
          Offset(0, y),
          Offset(w, y),
          _scanlinePaint,
        );
      }
    }

    // Occasional brighter scanline (moving) - using cached paint
    final brightScanlineY = ((_crtTime * 30) % h);
    if (brightScanlineY >= 0 && brightScanlineY <= h) {
      canvas.drawLine(
        Offset(0, brightScanlineY),
        Offset(w, brightScanlineY),
        _brightScanlinePaint,
      );
    }
  }

  void _renderVignette(Canvas canvas, Rect screenRect) {
    if (screenRect.width <= 0 || screenRect.height <= 0) return;
    // Radial gradient vignette - using cached shader and paint
    if (_vignetteShader != null) {
      _vignetteShaderPaint.shader = _vignetteShader;
      canvas.drawRect(screenRect, _vignetteShaderPaint);
    }

    // Neon border glow
    _renderNeonBorder(canvas, screenRect);
  }

  void _renderNeonBorder(Canvas canvas, Rect screenRect) {
    final w = screenRect.width;
    final h = screenRect.height;
    if (w <= 0 || h <= 0) return;
    final primaryColor = const Color(0xFF00FFFF);
    final secondaryColor = const Color(0xFFFF0066);
    final accentColor = const Color(0xFF00FF88);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: OUTER GLOW (wide, soft)
    // ═══════════════════════════════════════════════════════════════════════
    final outerPulse = 0.2 + math.sin(_crtTime * 1.5) * 0.1;
    if (outerPulse <= 0.01) return;
    _neonBorderOuterGlowPaint.color = primaryColor.withOpacity(outerPulse);

    // Top
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 8), _neonBorderOuterGlowPaint);
    // Bottom
    canvas.drawRect(Rect.fromLTWH(0, h - 8, w, 8), _neonBorderOuterGlowPaint);
    // Left
    canvas.drawRect(Rect.fromLTWH(0, 0, 8, h), _neonBorderOuterGlowPaint);
    // Right
    canvas.drawRect(Rect.fromLTWH(w - 8, 0, 8, h), _neonBorderOuterGlowPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: MID GLOW (medium width)
    // ═══════════════════════════════════════════════════════════════════════
    final midPulse = 0.35 + math.sin(_crtTime * 2.5) * 0.15;
    _neonBorderMidGlowPaint.color = primaryColor.withOpacity(midPulse);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, 4), _neonBorderMidGlowPaint);
    canvas.drawRect(Rect.fromLTWH(0, h - 4, w, 4), _neonBorderMidGlowPaint);
    canvas.drawRect(Rect.fromLTWH(0, 0, 4, h), _neonBorderMidGlowPaint);
    canvas.drawRect(Rect.fromLTWH(w - 4, 0, 4, h), _neonBorderMidGlowPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: CORE LINE (thin, bright)
    // ═══════════════════════════════════════════════════════════════════════
    final corePulse = 0.5 + math.sin(_crtTime * 3) * 0.2;
    _neonBorderCorePaint.color = Colors.white.withOpacity(corePulse);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, 2), _neonBorderCorePaint);
    canvas.drawRect(Rect.fromLTWH(0, h - 2, w, 2), _neonBorderCorePaint);
    canvas.drawRect(Rect.fromLTWH(0, 0, 2, h), _neonBorderCorePaint);
    canvas.drawRect(Rect.fromLTWH(w - 2, 0, 2, h), _neonBorderCorePaint);

    // Skip detailed effects in low fx mode
    if (reduceFx) return;

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: TRAVELING ENERGY PULSES
    // ═══════════════════════════════════════════════════════════════════════
    final pulseWidth = 60.0;
    final pulseSpeed = 200.0;
    const pulseThickness = 6.0;

    _ensureBorderPulseShaders(
        primaryColor, secondaryColor, accentColor, pulseWidth, pulseThickness);

    // Top border pulse (left to right)
    final topPulseX =
        ((_crtTime * pulseSpeed) % (w + pulseWidth)) - pulseWidth / 2;
    _neonBorderTravelPaint.shader = _pulseHorizontalPrimaryShader;
    canvas.save();
    canvas.translate(topPulseX - pulseWidth / 2, 0);
    canvas.drawRect(Rect.fromLTWH(0, 0, pulseWidth, pulseThickness),
        _neonBorderTravelPaint);
    canvas.restore();

    // Bottom border pulse (right to left)
    final bottomPulseX = w -
        ((_crtTime * pulseSpeed * 0.8 + 100) % (w + pulseWidth)) +
        pulseWidth / 2;
    _neonBorderTravelPaint.shader = _pulseHorizontalSecondaryShader;
    canvas.save();
    canvas.translate(bottomPulseX - pulseWidth / 2, h - pulseThickness);
    canvas.drawRect(Rect.fromLTWH(0, 0, pulseWidth, pulseThickness),
        _neonBorderTravelPaint);
    canvas.restore();

    // Left border pulse (top to bottom)
    final leftPulseY =
        ((_crtTime * pulseSpeed * 0.7 + 200) % (h + pulseWidth)) -
            pulseWidth / 2;
    _neonBorderTravelPaint.shader = _pulseVerticalAccentShader;
    canvas.save();
    canvas.translate(0, leftPulseY - pulseWidth / 2);
    canvas.drawRect(Rect.fromLTWH(0, 0, pulseThickness, pulseWidth),
        _neonBorderTravelPaint);
    canvas.restore();

    // Right border pulse (bottom to top)
    final rightPulseY = h -
        ((_crtTime * pulseSpeed * 0.9 + 300) % (h + pulseWidth)) +
        pulseWidth / 2;
    _neonBorderTravelPaint.shader = _pulseVerticalPrimaryShader;
    canvas.save();
    canvas.translate(w - pulseThickness, rightPulseY - pulseWidth / 2);
    canvas.drawRect(Rect.fromLTWH(0, 0, pulseThickness, pulseWidth),
        _neonBorderTravelPaint);
    canvas.restore();

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: ANIMATED CORNER NODES
    // ═══════════════════════════════════════════════════════════════════════
    final cornerPulse = 0.5 + math.sin(_crtTime * 4) * 0.3;
    final cornerSize = 12.0;

    void drawCornerNode(double cx, double cy, Color color) {
      // Outer glow
      _neonBorderCornerPaint.color = color.withOpacity(cornerPulse * 0.4);
      canvas.drawCircle(Offset(cx, cy), cornerSize, _neonBorderCornerPaint);

      // Mid glow
      _neonBorderPulsePaint.color = color.withOpacity(cornerPulse * 0.6);
      canvas.drawCircle(
          Offset(cx, cy), cornerSize * 0.6, _neonBorderPulsePaint);

      // Core
      _neonBorderCorePaint.color = Colors.white.withOpacity(cornerPulse * 0.9);
      canvas.drawCircle(Offset(cx, cy), cornerSize * 0.3, _neonBorderCorePaint);
    }

    drawCornerNode(6, 6, primaryColor);
    drawCornerNode(w - 6, 6, accentColor);
    drawCornerNode(6, h - 6, secondaryColor);
    drawCornerNode(w - 6, h - 6, primaryColor);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: CORNER BRACKET ACCENTS
    // ═══════════════════════════════════════════════════════════════════════
    final bracketLen = 25.0 + math.sin(_crtTime * 2) * 3;
    _neonBorderAccentPaint.color = primaryColor.withOpacity(0.7);

    // Top-left
    canvas.drawLine(
        const Offset(0, 0), Offset(bracketLen, 0), _neonBorderAccentPaint);
    canvas.drawLine(
        const Offset(0, 0), Offset(0, bracketLen), _neonBorderAccentPaint);

    // Top-right
    canvas.drawLine(
        Offset(w, 0), Offset(w - bracketLen, 0), _neonBorderAccentPaint);
    canvas.drawLine(
        Offset(w, 0), Offset(w, bracketLen), _neonBorderAccentPaint);

    // Bottom-left
    canvas.drawLine(
        Offset(0, h), Offset(bracketLen, h), _neonBorderAccentPaint);
    canvas.drawLine(
        Offset(0, h), Offset(0, h - bracketLen), _neonBorderAccentPaint);

    // Bottom-right
    canvas.drawLine(
        Offset(w, h), Offset(w - bracketLen, h), _neonBorderAccentPaint);
    canvas.drawLine(
        Offset(w, h), Offset(w, h - bracketLen), _neonBorderAccentPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: DATA TICK MARKS ALONG BORDERS
    // ═══════════════════════════════════════════════════════════════════════
    const tickLen = 8.0;
    final tickPhase = _crtTime * 5;
    _ensureBorderTickCache(w, h);

    // Top border ticks
    for (final x in _borderTickXs) {
      final tickAlpha = 0.2 + math.sin(tickPhase + x * 0.01) * 0.15;
      _neonBorderTickPaint.color = primaryColor.withOpacity(tickAlpha);
      canvas.drawLine(Offset(x, 0), Offset(x, tickLen), _neonBorderTickPaint);
    }

    // Bottom border ticks
    for (final x in _borderTickXs) {
      final tickAlpha = 0.2 + math.sin(tickPhase + x * 0.01 + math.pi) * 0.15;
      _neonBorderTickPaint.color = secondaryColor.withOpacity(tickAlpha);
      canvas.drawLine(
          Offset(x, h), Offset(x, h - tickLen), _neonBorderTickPaint);
    }

    // Left border ticks
    for (final y in _borderTickYs) {
      final tickAlpha = 0.2 + math.sin(tickPhase + y * 0.01) * 0.15;
      _neonBorderTickPaint.color = accentColor.withOpacity(tickAlpha);
      canvas.drawLine(Offset(0, y), Offset(tickLen, y), _neonBorderTickPaint);
    }

    // Right border ticks
    for (final y in _borderTickYs) {
      final tickAlpha = 0.2 + math.sin(tickPhase + y * 0.01 + math.pi) * 0.15;
      _neonBorderTickPaint.color = primaryColor.withOpacity(tickAlpha);
      canvas.drawLine(
          Offset(w, y), Offset(w - tickLen, y), _neonBorderTickPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 8: SCAN LINE ALONG BORDER
    // ═══════════════════════════════════════════════════════════════════════
    final scanProgress = (_crtTime * 0.5) % 1.0;
    final perimeter = 2 * (w + h);
    final scanPos = scanProgress * perimeter;
    final scanLen = 100.0;

    _neonBorderScanPaint.color = Colors.white.withOpacity(0.6);

    // Calculate position along the perimeter
    double scanX1, scanY1, scanX2, scanY2;
    if (scanPos < w) {
      // Top edge
      scanX1 = scanPos;
      scanY1 = 0;
      scanX2 = math.min(scanPos + scanLen, w);
      scanY2 = 0;
      canvas.drawLine(
          Offset(scanX1, scanY1), Offset(scanX2, scanY2), _neonBorderScanPaint);
    } else if (scanPos < w + h) {
      // Right edge
      scanX1 = w;
      scanY1 = scanPos - w;
      scanX2 = w;
      scanY2 = math.min(scanY1 + scanLen, h);
      canvas.drawLine(
          Offset(scanX1, scanY1), Offset(scanX2, scanY2), _neonBorderScanPaint);
    } else if (scanPos < 2 * w + h) {
      // Bottom edge (reversed)
      scanX1 = w - (scanPos - w - h);
      scanY1 = h;
      scanX2 = math.max(scanX1 - scanLen, 0);
      scanY2 = h;
      canvas.drawLine(
          Offset(scanX1, scanY1), Offset(scanX2, scanY2), _neonBorderScanPaint);
    } else {
      // Left edge (reversed)
      scanX1 = 0;
      scanY1 = h - (scanPos - 2 * w - h);
      scanX2 = 0;
      scanY2 = math.max(scanY1 - scanLen, 0);
      canvas.drawLine(
          Offset(scanX1, scanY1), Offset(scanX2, scanY2), _neonBorderScanPaint);
    }
  }

  void _renderDamageVignette(Canvas canvas, Rect screenRect) {
    final vignetteProgress = _damageVignetteTimer / 0.3;
    final intensity = _damageVignetteIntensity * vignetteProgress;
    if (intensity <= 0) return;

    // Pulsing effect
    final pulse = 1 + math.sin(_crtTime * 20) * 0.1;

    _ensureDamageVignetteShader(Size(screenRect.width, screenRect.height));
    if (_damageVignetteShader != null) {
      _damageVignettePaint.shader = _damageVignetteShader;
      _damageVignettePaint.colorFilter = _getIntensityFilter(intensity * pulse);
      canvas.drawRect(screenRect, _damageVignettePaint);
      _damageVignettePaint.colorFilter = null;
    }
  }

  void _renderFlash(Canvas canvas, Rect screenRect) {
    final flashProgress = _flashTimer / 0.1;
    final alpha = _flashIntensity * flashProgress;
    if (alpha <= 0) return;

    _flashPaint.color = _flashColor.withOpacity(alpha);
    canvas.drawRect(screenRect, _flashPaint);
  }

  void _renderChromaticHint(Canvas canvas, Rect screenRect) {
    // Draw subtle color separation at edges during shake
    final aberrationAmount = _chromaticAberration;
    if (aberrationAmount <= 0) return;

    // Update cached paints with blur if allowed
    if (allowBlur) {
      _chromaticRedPaint.maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 3);
      _chromaticCyanPaint.maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 3);
    } else {
      _chromaticRedPaint.maskFilter = null;
      _chromaticCyanPaint.maskFilter = null;
    }

    // Red channel shift (left edge)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, aberrationAmount * 2, screenRect.height),
      _chromaticRedPaint,
    );

    // Cyan channel shift (right edge)
    canvas.drawRect(
      Rect.fromLTWH(
        screenRect.width - aberrationAmount * 2,
        0,
        aberrationAmount * 2,
        screenRect.height,
      ),
      _chromaticCyanPaint,
    );
  }

  /// Renders the big hit chromatic split effect (RGB channel separation)
  /// Red channel shifts left, Blue channel shifts right, Green stays center
  void _renderBigHitChromaticSplit(Canvas canvas, Rect screenRect) {
    final offset = _bigHitChromaticOffset;
    final flashAlpha = _bigHitFlashAlpha;
    if (offset <= 0.01 && flashAlpha <= 0.01) return;
    final w = screenRect.width;
    final h = screenRect.height;

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: INITIAL IMPACT FLASH OVERLAY (fades quickly)
    // ═══════════════════════════════════════════════════════════════════════
    if (flashAlpha > 0.05) {
      _bigHitFlashPaint.color = Colors.white.withOpacity(flashAlpha);
      canvas.drawRect(screenRect, _bigHitFlashPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: RED CHANNEL SHIFT (Left shift)
    // ═══════════════════════════════════════════════════════════════════════
    // Create a red-tinted strip on the LEFT edge (shifted left)
    final redAlpha = (offset / 12.0).clamp(0.1, 0.4);
    _bigHitRedPaint.color = Color.fromRGBO(255, 0, 0, redAlpha);

    if (allowBlur) {
      _bigHitRedPaint.maskFilter =
          MaskFilter.blur(BlurStyle.normal, offset * 0.5);
    } else {
      _bigHitRedPaint.maskFilter = null;
    }

    // Left edge red strip
    canvas.drawRect(
      Rect.fromLTWH(0, 0, offset * 3, h),
      _bigHitRedPaint,
    );

    // Also draw a subtle red overlay on the left half
    _bigHitRedPaint.color = Color.fromRGBO(255, 0, 0, redAlpha * 0.3);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w * 0.35, h),
      _bigHitRedPaint,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: BLUE CHANNEL SHIFT (Right shift)
    // ═══════════════════════════════════════════════════════════════════════
    final blueAlpha = (offset / 12.0).clamp(0.1, 0.4);
    _bigHitBluePaint.color = Color.fromRGBO(0, 100, 255, blueAlpha);

    if (allowBlur) {
      _bigHitBluePaint.maskFilter =
          MaskFilter.blur(BlurStyle.normal, offset * 0.5);
    } else {
      _bigHitBluePaint.maskFilter = null;
    }

    // Right edge blue strip
    canvas.drawRect(
      Rect.fromLTWH(w - offset * 3, 0, offset * 3, h),
      _bigHitBluePaint,
    );

    // Also draw a subtle blue overlay on the right half
    _bigHitBluePaint.color = Color.fromRGBO(0, 100, 255, blueAlpha * 0.3);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.65, 0, w * 0.35, h),
      _bigHitBluePaint,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: CENTER GLOW (impact emphasis)
    // ═══════════════════════════════════════════════════════════════════════
    if (allowBlur && offset > 2.0) {
      final centerAlpha = (offset / 20.0).clamp(0.05, 0.15);
      final glowRadius = math.min(w, h) * 0.4;

      _ensureBigHitGlowShader(Size(w, h));
      if (_bigHitGlowShader != null) {
        _bigHitGlowPaint.shader = _bigHitGlowShader;
        _bigHitGlowPaint.colorFilter = _getIntensityFilter(centerAlpha);
        canvas.save();
        canvas.translate(w / 2, h / 2);
        canvas.drawCircle(Offset.zero, glowRadius, _bigHitGlowPaint);
        canvas.restore();
        _bigHitGlowPaint.colorFilter = null;
        _bigHitGlowPaint.shader = null;
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: EDGE DISTORTION LINES (chromatic fringe)
    // ═══════════════════════════════════════════════════════════════════════
    if (offset > 3.0) {
      final lineAlpha = (offset / 15.0).clamp(0.1, 0.3);

      // Horizontal distortion lines
      _bigHitRedPaint.color = Color.fromRGBO(255, 0, 0, lineAlpha);
      _bigHitBluePaint.color = Color.fromRGBO(0, 100, 255, lineAlpha);

      for (double y = 0; y < h; y += h / 8) {
        // Red line shifted left
        canvas.drawRect(
          Rect.fromLTWH(0, y, offset * 1.5, 2),
          _bigHitRedPaint,
        );
        // Blue line shifted right
        canvas.drawRect(
          Rect.fromLTWH(w - offset * 1.5, y, offset * 1.5, 2),
          _bigHitBluePaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: VIGNETTE INTENSIFICATION
    // ═══════════════════════════════════════════════════════════════════════
    if (offset > 4.0) {
      final vignetteAlpha = (offset / 24.0).clamp(0.05, 0.2);
      final size = screenRect.size;
      if (_bigHitVignetteSize != size) {
        _bigHitVignetteCache.clear();
        _bigHitVignetteSize = size;
      }
      final level = (vignetteAlpha * _bigHitVignetteLevels)
          .round()
          .clamp(0, _bigHitVignetteLevels);
      final vignetteGradient = _bigHitVignetteCache.putIfAbsent(level, () {
        final quantAlpha =
            (level / _bigHitVignetteLevels).clamp(0.05, 0.2).toDouble();
        final center = Offset(size.width / 2, size.height / 2);
        final radius = math.max(size.width, size.height) * 0.7;
        return RadialGradient(
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(quantAlpha * 0.5),
            Colors.black.withOpacity(quantAlpha),
          ],
          stops: const [0.0, 0.5, 0.75, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      });

      _bigHitVignettePaint.shader = vignetteGradient;
      canvas.drawRect(screenRect, _bigHitVignettePaint);
      _bigHitVignettePaint.shader = null;
    }
  }

  void _renderShieldFlash(Canvas canvas, Rect screenRect) {
    final progress = (_shieldFlashTimer / _shieldFlashDuration).clamp(0.0, 1.0);
    final fadeOut = 1 - progress;
    final intensity = _shieldFlashIntensity * fadeOut;
    if (intensity <= 0.01) return;
    final impactX = _shieldImpactPoint.x;
    final impactY = _shieldImpactPoint.y;

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: IMPACT CORE FLASH
    // ═══════════════════════════════════════════════════════════════════════
    final coreRadius = 50 + progress * 150;
    _shieldCorePaint.color =
        const Color(0xFF00FFFF).withOpacity(intensity * 0.6);
    canvas.drawCircle(
      Offset(impactX, impactY),
      coreRadius,
      _shieldCorePaint,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: HEXAGONAL SHIELD PATTERN
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx) {
      const hexSize = 35.0;
      if (intensity > 0.02) {
        final maxDist = screenRect.width * 0.8;
        final minFactor = 0.02 / intensity;
        double maxActiveDist = maxDist * (1 - minFactor);
        if (maxActiveDist < 0) {
          maxActiveDist = 0;
        }

        final minX = math.max(-hexSize, impactX - maxActiveDist - hexSize);
        final maxX = math.min(
            screenRect.width + hexSize, impactX + maxActiveDist + hexSize);
        final minY = math.max(-hexSize, impactY - maxActiveDist - hexSize);
        final maxY = math.min(
            screenRect.height + hexSize, impactY + maxActiveDist + hexSize);

        final stepX = hexSize * 1.73;
        final stepY = hexSize * 1.5;
        final startHy = ((minY + hexSize) / stepY).floor() * stepY - hexSize;
        final startHx = ((minX + hexSize) / stepX).floor() * stepX - hexSize;
        final hexAlpha =
            intensity * 0.5 * (0.5 + math.sin(_crtTime * 15) * 0.5);
        final waveRadius = progress * maxDist * 2;
        const waveWidth = 100.0;
        final invMaxDist = 1 / maxDist;

        for (double hy = startHy; hy < maxY; hy += stepY) {
          for (double hx = startHx; hx < maxX; hx += stepX) {
            final offsetX =
                ((hy ~/ (hexSize * 1.5)) % 2 == 0) ? 0.0 : hexSize * 0.866;
            final hexCenterX = hx + offsetX;
            final hexCenterY = hy;

            // Calculate distance from impact for fade effect
            final dx = hexCenterX - impactX;
            final dy = hexCenterY - impactY;
            final dist = math.sqrt(dx * dx + dy * dy);
            final distFactor = (1 - (dist * invMaxDist)).clamp(0.0, 1.0);

            // Wave effect spreading from impact
            final inWave = (dist > waveRadius - waveWidth &&
                dist < waveRadius + waveWidth);
            final waveIntensity =
                inWave ? (1 - ((dist - waveRadius).abs() / waveWidth)) : 0.0;

            final hexIntensity =
                distFactor * intensity * (0.3 + waveIntensity * 0.7);
            if (hexIntensity < 0.02) continue;

            _shieldPath.reset();
            for (int i = 0; i < 6; i++) {
              final angle = (i * 60 - 30) * math.pi / 180;
              final px = hexCenterX + math.cos(angle) * hexSize * 0.45;
              final py = hexCenterY + math.sin(angle) * hexSize * 0.45;
              if (i == 0) {
                _shieldPath.moveTo(px, py);
              } else {
                _shieldPath.lineTo(px, py);
              }
            }
            _shieldPath.close();

            // Fill
            _shieldHexFillPaint.color =
                const Color(0xFF00FFFF).withOpacity(hexIntensity * 0.15);
            canvas.drawPath(_shieldPath, _shieldHexFillPaint);

            // Stroke
            _shieldHexPaint.color =
                const Color(0xFF00FFFF).withOpacity(hexIntensity * 0.6);
            canvas.drawPath(_shieldPath, _shieldHexPaint);
          }
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: EXPANDING RIPPLE RINGS
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < 3; i++) {
      final rippleProgress = (progress + i * 0.15).clamp(0.0, 1.0);
      final rippleAlpha = (1 - rippleProgress) * intensity * 0.5;
      if (rippleAlpha <= 0.01) continue;

      final rippleRadius = rippleProgress * screenRect.width * 0.8;
      _shieldRipplePaint.color =
          const Color(0xFF00FFFF).withOpacity(rippleAlpha);
      canvas.drawCircle(
        Offset(impactX, impactY),
        rippleRadius,
        _shieldRipplePaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: SHIELD CRACKS FROM IMPACT
    // ═══════════════════════════════════════════════════════════════════════
    final cracks = _shieldCracks;
    if (cracks != null && !reduceFx && intensity > 0.06) {
      for (final crack in cracks) {
        final crackProgress = (progress * 2).clamp(0.0, 1.0);
        final crackLength = crack.length * crackProgress;

        _shieldCrackPaint.color =
            const Color(0xFFFF0066).withOpacity(intensity * 0.8);

        var startX = impactX + crack.offsetX;
        var startY = impactY + crack.offsetY;

        for (int seg = 0; seg < crack.segments; seg++) {
          final segFraction = (seg + 1) / crack.segments;
          final segLength = crackLength * segFraction / crack.segments;

          // Add jitter to crack direction
          final jitteredAngle = crack.angle + (_nextUnit() - 0.5) * 0.5;
          final endX = startX + math.cos(jitteredAngle) * segLength;
          final endY = startY + math.sin(jitteredAngle) * segLength;

          canvas.drawLine(
              Offset(startX, startY), Offset(endX, endY), _shieldCrackPaint);

          startX = endX;
          startY = endY;
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: FLYING SPARKS
    // ═══════════════════════════════════════════════════════════════════════
    final sparks = _shieldSparks;
    if (sparks != null && !reduceFx && intensity > 0.06) {
      for (final spark in sparks) {
        if (spark.life <= 0) continue;

        final sparkAlpha = (spark.life / 0.5).clamp(0.0, 1.0) * intensity;
        _shieldSparkPaint.color =
            const Color(0xFF00FFFF).withOpacity(sparkAlpha);
        canvas.drawCircle(
            Offset(spark.x, spark.y), spark.size, _shieldSparkPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: EDGE GLOW INTENSIFICATION
    // ═══════════════════════════════════════════════════════════════════════
    _shieldGlowPaint.color =
        const Color(0xFF00FFFF).withOpacity(intensity * 0.3);

    // Top edge
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenRect.width, 10 + intensity * 20),
      _shieldGlowPaint,
    );
    // Bottom edge
    canvas.drawRect(
      Rect.fromLTWH(0, screenRect.height - 10 - intensity * 20,
          screenRect.width, 10 + intensity * 20),
      _shieldGlowPaint,
    );
    // Left edge
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 10 + intensity * 20, screenRect.height),
      _shieldGlowPaint,
    );
    // Right edge
    canvas.drawRect(
      Rect.fromLTWH(screenRect.width - 10 - intensity * 20, 0,
          10 + intensity * 20, screenRect.height),
      _shieldGlowPaint,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: CHROMATIC ABERRATION ON IMPACT
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx && intensity > 0.3) {
      final chromaOffset = intensity * 4;

      // Red shift
      _shieldOverlayPaint.color = Colors.red.withOpacity(intensity * 0.15);
      canvas.save();
      canvas.translate(-chromaOffset, 0);
      canvas.drawCircle(
          Offset(impactX, impactY), coreRadius * 0.8, _shieldOverlayPaint);
      canvas.restore();

      // Cyan shift
      _shieldOverlayPaint.color = Colors.cyan.withOpacity(intensity * 0.15);
      canvas.save();
      canvas.translate(chromaOffset, 0);
      canvas.drawCircle(
          Offset(impactX, impactY), coreRadius * 0.8, _shieldOverlayPaint);
      canvas.restore();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 8: WARNING OVERLAY FLASH
    // ═══════════════════════════════════════════════════════════════════════
    if (progress < 0.15) {
      final flashAlpha = (1 - progress / 0.15) * _shieldFlashIntensity * 0.25;
      if (flashAlpha > 0.01) {
        _warningFlashPaint.color =
            const Color(0xFFFF0066).withOpacity(flashAlpha);
        canvas.drawRect(screenRect, _warningFlashPaint);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LENS FLARE RENDERING - 6-Layer Cinematic Light Artifact System
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderLensFlares(Canvas canvas, Rect screenRect) {
    if (_activeFlareSources.isEmpty) return;
    final margin = math.max(screenRect.width, screenRect.height) * 0.2;
    final flareRect = screenRect.inflate(margin);
    for (final source in _activeFlareSources) {
      final progress = (source.timer / source.duration).clamp(0.0, 1.0);
      // Sharp attack, smooth decay envelope
      final envelope = progress < 0.15
          ? progress / 0.15 // Quick rise
          : 1 - ((progress - 0.15) / 0.85); // Slow decay
      final intensity = source.intensity * envelope;

      if (intensity < 0.01) continue;

      final sourcePos = Offset(source.position.x, source.position.y);
      if (!flareRect.contains(sourcePos)) {
        continue;
      }

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 1: CENTRAL BRIGHT SOURCE GLOW
      // ═══════════════════════════════════════════════════════════════════════
      _renderSourceGlow(canvas, sourcePos, source.color, intensity);

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 2: ANAMORPHIC STREAK (Horizontal Light Streak)
      // ═══════════════════════════════════════════════════════════════════════
      _renderAnamorphicStreak(
          canvas, source, sourcePos, source.color, intensity, screenRect);

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 3: HEXAGONAL FLARE ARTIFACTS
      // ═══════════════════════════════════════════════════════════════════════
      _renderHexagonalArtifacts(canvas, source, intensity, progress);

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 4: CIRCULAR RAINBOW ARTIFACTS (Chromatic Aberration)
      // ═══════════════════════════════════════════════════════════════════════
      _renderRainbowArtifacts(canvas, source, intensity, progress);

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 5: STARBURST RAYS
      // ═══════════════════════════════════════════════════════════════════════
      _renderStarburstRays(
          canvas, sourcePos, source.color, intensity, progress);

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 6: BLOOM/HALO
      // ═══════════════════════════════════════════════════════════════════════
      _renderBloomHalo(canvas, sourcePos, source.color, intensity);
    }
  }

  /// Layer 1: Central bright source glow with hot core
  void _renderSourceGlow(
      Canvas canvas, Offset pos, Color color, double intensity) {
    if (intensity <= 0.01) return;
    // Outer soft glow
    final outerRadius = 35 * intensity;
    _lensFlareSourceGlowPaint.color = color.withOpacity(intensity * 0.4);
    canvas.drawCircle(pos, outerRadius, _lensFlareSourceGlowPaint);

    // Mid glow layer
    final midRadius = 20 * intensity;
    _lensFlareSourceGlowPaint.color = color.withOpacity(intensity * 0.6);
    canvas.drawCircle(pos, midRadius, _lensFlareSourceGlowPaint);

    // Hot white core
    final coreRadius = 8 * intensity;
    _lensFlareSourceCorePaint.color = Colors.white.withOpacity(intensity * 0.9);
    canvas.drawCircle(pos, coreRadius, _lensFlareSourceCorePaint);

    // Tiny bright center
    _lensFlareSourceCorePaint.color = Colors.white.withOpacity(intensity);
    canvas.drawCircle(pos, coreRadius * 0.4, _lensFlareSourceCorePaint);
  }

  /// Layer 2: Anamorphic horizontal light streak
  void _renderAnamorphicStreak(Canvas canvas, _LensFlareSource source,
      Offset pos, Color color, double intensity, Rect screenRect) {
    if (intensity <= 0.02) return;
    final streakWidth = screenRect.width * 0.8 * intensity;
    final streakHeight = 3 + intensity * 8;
    const streakLevels = 16;
    final streakLevel =
        (intensity * streakLevels).round().clamp(0, streakLevels);

    final streakRect = Rect.fromCenter(
      center: pos,
      width: streakWidth,
      height: streakHeight,
    );

    // Cache streak shaders per source to avoid per-frame createShader
    if (source.streakShader == null ||
        source.streakWidth != streakWidth ||
        source.streakHeight != streakHeight ||
        source.streakLevel != streakLevel) {
      source.streakWidth = streakWidth;
      source.streakHeight = streakHeight;
      source.streakLevel = streakLevel;
      final q = streakLevel / streakLevels;

      source.streakShader = LinearGradient(
        colors: [
          Colors.transparent,
          color.withOpacity(q * 0.3),
          Colors.white.withOpacity(q * 0.5),
          color.withOpacity(q * 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, streakWidth, streakHeight));

      final secondaryWidth = streakWidth * 0.6;
      final secondaryHeight = streakHeight * 0.3;
      source.secondaryStreakShader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(q * 0.2),
          Colors.white.withOpacity(q * 0.4),
          Colors.white.withOpacity(q * 0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, secondaryWidth, secondaryHeight));
    }

    _lensFlareStreakPaint.shader = source.streakShader;
    canvas.save();
    canvas.translate(streakRect.left, streakRect.top);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, streakWidth, streakHeight), _lensFlareStreakPaint);
    canvas.restore();

    // Secondary thinner streak
    final secondaryWidth = streakWidth * 0.6;
    final secondaryHeight = streakHeight * 0.3;
    _lensFlareStreakPaint.shader = source.secondaryStreakShader;
    canvas.save();
    canvas.translate(pos.dx - secondaryWidth / 2, pos.dy - secondaryHeight / 2);
    canvas.drawRect(Rect.fromLTWH(0, 0, secondaryWidth, secondaryHeight),
        _lensFlareStreakPaint);
    canvas.restore();

    _lensFlareStreakPaint.shader = null;
  }

  /// Layer 3: Hexagonal flare artifacts along the flare axis
  void _renderHexagonalArtifacts(Canvas canvas, _LensFlareSource source,
      double intensity, double progress) {
    if (intensity <= 0.03) return;
    if (source.hexArtifacts.isEmpty) return;
    for (final hex in source.hexArtifacts) {
      final hexPos = Offset(hex.position.x, hex.position.y);
      final hexIntensity = intensity * hex.opacity;

      if (hexIntensity < 0.02) continue;

      // Draw hexagon
      _lensFlarePath.reset();
      for (int i = 0; i < 6; i++) {
        final angle = hex.rotation + i * math.pi / 3;
        final px = hexPos.dx + math.cos(angle) * hex.size;
        final py = hexPos.dy + math.sin(angle) * hex.size;
        if (i == 0) {
          _lensFlarePath.moveTo(px, py);
        } else {
          _lensFlarePath.lineTo(px, py);
        }
      }
      _lensFlarePath.close();

      // Fill with semi-transparent color
      _lensFlareHexFillPaint.color =
          source.color.withOpacity(hexIntensity * 0.15);
      canvas.drawPath(_lensFlarePath, _lensFlareHexFillPaint);

      // Stroke outline
      _lensFlareHexPaint.color = source.color.withOpacity(hexIntensity * 0.5);
      canvas.drawPath(_lensFlarePath, _lensFlareHexPaint);

      // Inner hexagon for depth effect
      _lensFlarePath.reset();
      for (int i = 0; i < 6; i++) {
        final angle = hex.rotation + i * math.pi / 3;
        final px = hexPos.dx + math.cos(angle) * hex.size * 0.6;
        final py = hexPos.dy + math.sin(angle) * hex.size * 0.6;
        if (i == 0) {
          _lensFlarePath.moveTo(px, py);
        } else {
          _lensFlarePath.lineTo(px, py);
        }
      }
      _lensFlarePath.close();

      _lensFlareHexPaint.color = Colors.white.withOpacity(hexIntensity * 0.3);
      canvas.drawPath(_lensFlarePath, _lensFlareHexPaint);
    }
  }

  /// Layer 4: Circular rainbow artifacts (chromatic aberration rings)
  void _renderRainbowArtifacts(Canvas canvas, _LensFlareSource source,
      double intensity, double progress) {
    if (intensity <= 0.03) return;
    if (source.rainbowArtifacts.isEmpty) return;
    // Rainbow colors for chromatic aberration effect
    const rainbowColors = [
      Color(0xFFFF0000), // Red
      Color(0xFFFF8800), // Orange
      Color(0xFFFFFF00), // Yellow
      Color(0xFF00FF00), // Green
      Color(0xFF00FFFF), // Cyan
      Color(0xFF0088FF), // Blue
      Color(0xFFFF00FF), // Magenta
    ];

    for (final rainbow in source.rainbowArtifacts) {
      final ringPos = Offset(rainbow.position.x, rainbow.position.y);
      final baseAlpha = intensity * 0.25;

      // Draw concentric rainbow rings
      for (int i = 0; i < rainbowColors.length; i++) {
        final ringRadius = rainbow.radius + i * 2.5;
        final ringColor = rainbowColors[i];
        final ringAlpha = baseAlpha * (1 - i * 0.1);

        if (ringAlpha < 0.01) continue;

        _lensFlareRainbowPaint
          ..color = ringColor.withOpacity(ringAlpha)
          ..strokeWidth = 1.5;
        canvas.drawCircle(ringPos, ringRadius, _lensFlareRainbowPaint);
      }

      // Central soft glow
      _lensFlareHaloPaint.color = source.color.withOpacity(intensity * 0.1);
      canvas.drawCircle(ringPos, rainbow.radius * 0.5, _lensFlareHaloPaint);
    }
  }

  /// Layer 5: Starburst rays emanating from source
  void _renderStarburstRays(Canvas canvas, Offset pos, Color color,
      double intensity, double progress) {
    if (intensity <= 0.04) return;
    const rayCount = 8;
    final rayLength = 50 + intensity * 30;
    final rayWidth = 1 + intensity * 2;
    final rotationOffset = progress * 0.3; // Subtle rotation animation

    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * math.pi * 2 + rotationOffset;

      // Vary ray lengths for more natural look
      final lengthVariation = 0.7 + (i % 2) * 0.3;
      final thisRayLength = rayLength * lengthVariation;

      // Calculate ray endpoints
      final startX = pos.dx + math.cos(angle) * 12 * intensity;
      final startY = pos.dy + math.sin(angle) * 12 * intensity;
      final endX = pos.dx + math.cos(angle) * thisRayLength;
      final endY = pos.dy + math.sin(angle) * thisRayLength;

      // Ray with gradient fade
      final rayAlpha = intensity * 0.4 * lengthVariation;

      _lensFlareStarburstPaint
        ..color = color.withOpacity(rayAlpha)
        ..strokeWidth = rayWidth;
      canvas.drawLine(
          Offset(startX, startY), Offset(endX, endY), _lensFlareStarburstPaint);

      // Brighter inner ray
      final innerEndX = pos.dx + math.cos(angle) * thisRayLength * 0.5;
      final innerEndY = pos.dy + math.sin(angle) * thisRayLength * 0.5;

      _lensFlareStarburstPaint
        ..color = Colors.white.withOpacity(rayAlpha * 0.6)
        ..strokeWidth = rayWidth * 0.5;
      canvas.drawLine(Offset(startX, startY), Offset(innerEndX, innerEndY),
          _lensFlareStarburstPaint);
    }

    // Secondary shorter rays between main rays
    for (int i = 0; i < rayCount; i++) {
      final angle = ((i + 0.5) / rayCount) * math.pi * 2 + rotationOffset;
      final shortRayLength = rayLength * 0.4;

      final startX = pos.dx + math.cos(angle) * 8 * intensity;
      final startY = pos.dy + math.sin(angle) * 8 * intensity;
      final endX = pos.dx + math.cos(angle) * shortRayLength;
      final endY = pos.dy + math.sin(angle) * shortRayLength;

      _lensFlareStarburstPaint
        ..color = color.withOpacity(intensity * 0.2)
        ..strokeWidth = rayWidth * 0.6;
      canvas.drawLine(
          Offset(startX, startY), Offset(endX, endY), _lensFlareStarburstPaint);
    }
  }

  /// Layer 6: Bloom/halo effect around the source
  void _renderBloomHalo(
      Canvas canvas, Offset pos, Color color, double intensity) {
    if (intensity <= 0.02) return;
    // Large soft outer bloom
    final outerBloomRadius = 60 * intensity;
    _lensFlareHaloPaint.color = color.withOpacity(intensity * 0.15);
    canvas.drawCircle(pos, outerBloomRadius, _lensFlareHaloPaint);

    // Medium bloom layer
    final midBloomRadius = 40 * intensity;
    _lensFlareHaloPaint.color = color.withOpacity(intensity * 0.2);
    canvas.drawCircle(pos, midBloomRadius, _lensFlareHaloPaint);

    // Inner bloom with white tint
    final innerBloomRadius = 25 * intensity;
    final innerColor = Color.lerp(color, Colors.white, 0.4)!;
    _lensFlareHaloPaint.color = innerColor.withOpacity(intensity * 0.25);
    canvas.drawCircle(pos, innerBloomRadius, _lensFlareHaloPaint);
  }
}

/// Helper class for shield crack effects
class _ShieldCrack {
  _ShieldCrack({
    required this.angle,
    required this.length,
    required this.segments,
    required this.offsetX,
    required this.offsetY,
  });

  final double angle;
  final double length;
  final int segments;
  final double offsetX;
  final double offsetY;
}

/// Helper class for shield spark particles
class _ShieldSpark {
  _ShieldSpark({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.size,
  });

  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double size;
}

// ═══════════════════════════════════════════════════════════════════════════════
// LENS FLARE HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════════════

/// Represents an active lens flare source
class _LensFlareSource {
  _LensFlareSource({
    required this.position,
    required this.color,
    required this.intensity,
    required this.duration,
    required this.timer,
    required this.hexArtifacts,
    required this.rainbowArtifacts,
  });

  final Vector2 position;
  final Color color;
  final double intensity;
  final double duration;
  double timer;
  final List<_HexArtifact> hexArtifacts;
  final List<_RainbowArtifact> rainbowArtifacts;

  // Cached streak shaders (reduce per-frame createShader in lens flares)
  Shader? streakShader;
  Shader? secondaryStreakShader;
  double streakWidth = 0;
  double streakHeight = 0;
  int streakLevel = -1;
}

/// Hexagonal artifact in the lens flare
class _HexArtifact {
  _HexArtifact({
    required this.position,
    required this.size,
    required this.rotation,
    required this.opacity,
  });

  final Vector2 position;
  final double size;
  final double rotation;
  final double opacity;
}

/// Rainbow ring artifact for chromatic aberration effect
class _RainbowArtifact {
  _RainbowArtifact({
    required this.position,
    required this.radius,
    required this.rotation,
  });

  final Vector2 position;
  final double radius;
  final double rotation;
}
