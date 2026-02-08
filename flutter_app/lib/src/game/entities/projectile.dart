import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show HSLColor, RadialGradient;

import 'enemy.dart';
import 'tower.dart';
import '../../services/audio_service.dart';
import '../../services/sprite_cache_service.dart';
import '../effects/impact_effect.dart';
import '../managers/bullet_manager.dart';

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

class Projectile extends PositionComponent {
  static bool lowFx = false;
  static bool allowTrails = true;
  static bool allowGlow = true;

  /// Nivel de estrés del sistema (0-2)
  /// 0: Full quality (<200 bullets)
  /// 1: Reduced trails (200-400 bullets)
  /// 2: Minimal FX (400+ bullets)
  static int stressLevel = 0;

  /// Configura el nivel de estrés del sistema de proyectiles
  static void setStressLevel(int level) {
    stressLevel = level.clamp(0, 2);
    lowFx = stressLevel >= 2;
    // Nivel 1: reduce trails pero mantiene glow
    // Nivel 2: reduce todo (lowFx = true)
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════
  static final Paint _simplePaint = Paint();
  static final Paint _glowPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _trailGlowPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _trailCorePaint = Paint();
  static final Paint _trailLinePaint = Paint()..strokeCap = StrokeCap.round;
  static final Paint _particlePaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _arcPaint = Paint()
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _circuitLinePaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  // Additional cached paints for optimization
  static final Paint _energyRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _orbPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _phasePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _phaseGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _sparkPaint = Paint();
  static final Paint _flickerGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  // ═══════════════════════════════════════════════════════════════════════
  // PLASMA TRAIL EFFECT PAINTS
  // ═══════════════════════════════════════════════════════════════════════
  static final Paint _plasmaOuterGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _plasmaCorePaint = Paint();
  static final Paint _plasmaRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _plasmaWispPaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Paint _plasmaSparkPaint = Paint();
  static final Paint _plasmaEnergyPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _plasmaArcPaint = Paint()
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Paint _plasmaHeatPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _plasmaChromaPaint = Paint();
  static final Paint _plasmaVortexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  // ═══════════════════════════════════════════════════════════════════════
  // PLASMA BUBBLE PROJECTILE PAINTS
  // ═══════════════════════════════════════════════════════════════════════
  static final Paint _bubbleMembraneGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _bubbleMembranePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _bubblePlasmaCorePaint = Paint();
  static final Paint _bubbleInnerGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _bubbleSwirlPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _bubbleShimmerPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _bubbleEnergyCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _bubbleOrbitPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _bubbleDistortionPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _bubbleHighlightPaint = Paint();

  // Reusable paths to avoid per-frame allocations
  static final Path _reusableArrowPath = Path();
  static final Path _reusableArcPath = Path();
  static final Path _reusableRunePath = Path();
  static final Path _reusableStarPath = Path();
  static final Path _reusablePlasmaPath = Path();
  static final Path _reusablePlasmaWispPath = Path();
  static final Path _reusablePlasmaVortexPath = Path();
  static final Path _reusableBubbleSwirlPath = Path();
  static final List<Offset> _unitCardinal = List<Offset>.unmodifiable([
    const Offset(1, 0),
    const Offset(0, 1),
    const Offset(-1, 0),
    const Offset(0, -1),
  ]);
  static final List<Offset> _unitOct = List<Offset>.unmodifiable(_buildUnitOct());
  static final List<Offset> _unitHex = List<Offset>.unmodifiable(_buildUnitHex());
  static final List<Offset> _starUnitPoints = List<Offset>.unmodifiable(
    _buildStarUnitPoints(),
  );
  static final List<double> _glimmerSinOffsets = List<double>.unmodifiable(
    _buildSinOffsets(8, 1.0),
  );
  static final List<double> _glimmerCosOffsets = List<double>.unmodifiable(
    _buildCosOffsets(8, 1.0),
  );
  static final List<double> _glimmerSinOffsetsFast = List<double>.unmodifiable(
    _buildSinOffsets(8, 1.5),
  );
  static final List<double> _glimmerCosOffsetsFast = List<double>.unmodifiable(
    _buildCosOffsets(8, 1.5),
  );

  // Reusable Offset objects for loops
  static Offset _tempOffset1 = Offset.zero;
  static Offset _tempOffset2 = Offset.zero;

  static List<Offset> _buildUnitHex() {
    final points = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      points.add(Offset(math.cos(angle), math.sin(angle)));
    }
    return points;
  }

  static List<Offset> _buildUnitOct() {
    final points = <Offset>[];
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      points.add(Offset(math.cos(angle), math.sin(angle)));
    }
    return points;
  }

  static List<Offset> _buildStarUnitPoints() {
    final points = <Offset>[];
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      points.add(Offset(math.cos(angle), math.sin(angle)));
      final innerAngle = angle + math.pi / 4;
      points.add(Offset(math.cos(innerAngle) * 0.4, math.sin(innerAngle) * 0.4));
    }
    return points;
  }

  static List<double> _buildSinOffsets(int count, double step) {
    final values = <double>[];
    for (int i = 0; i < count; i++) {
      values.add(math.sin(i * step));
    }
    return values;
  }

  static List<double> _buildCosOffsets(int count, double step) {
    final values = <double>[];
    for (int i = 0; i < count; i++) {
      values.add(math.cos(i * step));
    }
    return values;
  }

  // Reusable Vector2 objects for calculations - avoid per-frame allocations

  // ═══════════════════════════════════════════════════════════════════════════
  // COLOR PALETTE CACHE - Avoid per-frame Color.withOpacity() allocations
  // ═══════════════════════════════════════════════════════════════════════════
  static final Map<int, _ColorPalette> _colorPaletteCache = {};
  static const int _maxPaletteCacheSize = 32;

  /// Get or create a cached color palette for the given color
  static _ColorPalette _getPalette(Color color) {
    final key = color.value;
    var palette = _colorPaletteCache[key];
    if (palette == null) {
      // Evict oldest entry if cache is full
      if (_colorPaletteCache.length >= _maxPaletteCacheSize) {
        _colorPaletteCache.remove(_colorPaletteCache.keys.first);
      }
      palette = _ColorPalette(color);
      _colorPaletteCache[key] = palette;
    }
    return palette;
  }

  /// Clear palette cache (call between games)
  static void clearPaletteCache() {
    _colorPaletteCache.clear();
  }

  Projectile({
    required Vector2 startPosition,
    required this.targetPosition,
    required this.speed,
    required this.damage,
    this.onHit,
    this.color = const Color(0xFF00FFFF),
    this.target,
    this.slowAmount = 0,
    this.slowDuration = 0,
    this.towerType = TowerType.pulseArcher,
  }) : _active = true,
       _random = _FastRng() {
    position.setFrom(startPosition);
    size = Vector2.all(6);
    anchor = Anchor.center;
    _cacheHSLColors();
    _initializeTypeEffects();
    _initializeTrail();
  }

  final Vector2 targetPosition;
  double speed;
  double damage;
  void Function(Enemy target, Vector2 hitPosition, bool killed)? onHit;
  Color color;
  double slowAmount;
  double slowDuration;
  TowerType towerType;
  Enemy? target;

  bool _active;
  double _time = 0;
  double _rotationAngle = 0;
  final _FastRng _random;

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHED HSL-DERIVED COLORS - Avoid per-frame HSLColor.fromColor() calls
  // ═══════════════════════════════════════════════════════════════════════════
  late Color _hslPinkColor;
  late Color _hslPurpleColor;
  late Color _hslBrightColor;
  late Color _hslSecondaryColor;  // hue + 30
  late Color _hslTertiaryColor;   // hue + 60
  late Color _hslComplementColor; // hue + 180

  void _cacheHSLColors() {
    final hsl = HSLColor.fromColor(color);
    _hslPinkColor = hsl.withHue((hsl.hue + 20) % 360).toColor();
    _hslPurpleColor = hsl.withHue((hsl.hue - 30) % 360).toColor();
    _hslBrightColor = hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
    _hslSecondaryColor = hsl.withHue((hsl.hue + 30) % 360).toColor();
    _hslTertiaryColor = hsl.withHue((hsl.hue + 60) % 360).toColor();
    _hslComplementColor = hsl.withHue((hsl.hue + 180) % 360).toColor();
  }

  // Trail system - circular buffer for O(1) updates instead of O(n) shifting
  int _maxTrailLength = 12;
  final List<Vector2> _trailPositions = [];
  final List<double> _trailAlphas = [];
  final List<Color> _trailBridgeColors = [];
  int _trailBridgeKey = 0;
  int _trailBridgeLength = 0;
  int _trailHead = 0; // Current write position in circular buffer

  /// Get physical index from logical index (0 = newest, _maxTrailLength-1 = oldest)
  int _getTrailPhysicalIndex(int logicalIndex) {
    return (_trailHead - logicalIndex + _maxTrailLength) % _maxTrailLength;
  }

  // Particle system
  int _particleCount = 8;
  final List<_ProjectileParticle> _particles = [];

  // Type-specific visual properties
  double _wobbleAmount = 0;
  double _spiralPhase = 0;
  List<_ElectricSegment> _electricSegments = [];
  double _pulsePhase = 0;

  /// Whether projectile is still flying
  bool get isActive => _active;

  /// Whether this projectile applies slow
  bool get appliesSlow => slowAmount > 0 && slowDuration > 0;

  void _initializeTypeEffects() {
    _maxTrailLength = 12;
    _particleCount = 8;
    _wobbleAmount = 0;
    _electricSegments.clear();
    switch (towerType) {
      case TowerType.pulseArcher:
        _maxTrailLength = 10;
        _particleCount = 6;
        break;
      case TowerType.circuitCannon:
        _maxTrailLength = 6;
        _particleCount = 4;
        size = Vector2.all(10); // Larger projectile
        break;
      case TowerType.phaseMage:
        _maxTrailLength = 16;
        _particleCount = 10;
        _wobbleAmount = 0.3;
        _ensureElectricSegments(5);
        break;
      case TowerType.glimmerField:
        _maxTrailLength = 8;
        _particleCount = 12;
        size = Vector2.all(4); // Smaller but more particles
        _wobbleAmount = 0.1;
        break;
      case TowerType.ionSniper:
        _maxTrailLength = 20;
        _particleCount = 4;
        size = Vector2(12, 4);
        break;
      case TowerType.teslaTerminal:
      case TowerType.resonanceSiphon:
      case TowerType.neuralDisruptor:
        _maxTrailLength = 12;
        _particleCount = 8;
        break;
      case TowerType.plasmaBubble:
        _maxTrailLength = 14;
        _particleCount = 6; // Orbiting particles around bubble
        _wobbleAmount = 0.5; // Bubble wobbles while moving
        size = Vector2.all(14); // Larger bubble projectile
        break;
    }

    // Ajustar calidad según nivel de estrés
    if (stressLevel >= 1) {
      // Nivel 1: reduce trails y partículas moderadamente
      _maxTrailLength = math.max(3, (_maxTrailLength * 0.5).round());
      _particleCount = math.max(2, (_particleCount * 0.5).round());
    }
    if (lowFx || stressLevel >= 2) {
      // Nivel 2: reducción agresiva para alto estrés
      _maxTrailLength = math.max(2, (_maxTrailLength * 0.35).round());
      _particleCount = (_particleCount * 0.25).round();
      if (_particleCount < 0) {
        _particleCount = 0;
      }
      _wobbleAmount = 0;
      _electricSegments.clear();
    }
  }

  void _initializeTrail() {
    _trailHead = 0; // Reset circular buffer head
    if (allowTrails && !lowFx && _maxTrailLength > 1) {
      _ensureTrailCapacity(_maxTrailLength);
      _updateTrailColorCache();
      for (int i = 0; i < _maxTrailLength; i++) {
        _trailPositions[i].setFrom(position);
        _trailAlphas[i] = 0;
      }
    } else {
      _trailPositions.clear();
      _trailAlphas.clear();
      _trailBridgeColors.clear();
      _trailBridgeKey = 0;
      _trailBridgeLength = 0;
    }

    // Initialize particles
    if (!lowFx && _particleCount > 0) {
      _ensureParticles(_particleCount);
      for (int i = 0; i < _particleCount; i++) {
        _particles[i].reset(
          offset: Vector2(
            (_random.nextDouble() - 0.5) * 10,
            (_random.nextDouble() - 0.5) * 10,
          ),
          speed: 20 + _random.nextDouble() * 30,
          angle: _random.nextDouble() * math.pi * 2,
          size: 1 + _random.nextDouble() * 2,
          alpha: 0.3 + _random.nextDouble() * 0.5,
        );
      }
    } else {
      _particles.clear();
    }
  }

  void _ensureTrailCapacity(int length) {
    if (_trailPositions.length == length && _trailAlphas.length == length) return;
    if (_trailPositions.length < length) {
      for (int i = _trailPositions.length; i < length; i++) {
        _trailPositions.add(position.clone());
        _trailAlphas.add(0);
      }
    } else {
      _trailPositions.removeRange(length, _trailPositions.length);
      _trailAlphas.removeRange(length, _trailAlphas.length);
    }
  }

  void _updateTrailColorCache() {
    final length = _maxTrailLength;
    if (length <= 0) return;
    final key = color.value ^ _hslSecondaryColor.value;
    if (_trailBridgeKey == key &&
        _trailBridgeLength == length &&
        _trailBridgeColors.length == length) {
      return;
    }
    _trailBridgeKey = key;
    _trailBridgeLength = length;
    _trailBridgeColors.clear();
    for (int i = 0; i < length; i++) {
      final progress = i / length;
      _trailBridgeColors.add(Color.lerp(color, _hslSecondaryColor, progress)!);
    }
  }

  void _ensureParticles(int count) {
    if (_particles.length == count) return;
    if (_particles.length < count) {
      for (int i = _particles.length; i < count; i++) {
        _particles.add(_ProjectileParticle(
          offset: Vector2.zero(),
          speed: 0,
          angle: 0,
          size: 0,
          alpha: 0,
        ));
      }
    } else {
      _particles.removeRange(count, _particles.length);
    }
  }

  void _ensureElectricSegments(int count) {
    if (_electricSegments.length == count) {
      for (final segment in _electricSegments) {
        segment.reset(
          angle: _random.nextDouble() * math.pi * 2,
          length: 8 + _random.nextDouble() * 6,
          offset: _random.nextDouble() * math.pi * 2,
        );
      }
      return;
    }
    _electricSegments.clear();
    for (int i = 0; i < count; i++) {
      _electricSegments.add(_ElectricSegment(
        angle: _random.nextDouble() * math.pi * 2,
        length: 8 + _random.nextDouble() * 6,
        offset: _random.nextDouble() * math.pi * 2,
      ));
    }
  }

  /// Reset projectile for pool reuse
  void reset({
    required Vector2 startPosition,
    required Vector2 targetPosition,
    required double speed,
    required double damage,
    Color? color,
    Enemy? target,
    void Function(Enemy target, Vector2 hitPosition, bool killed)? onHit,
    double slowAmount = 0,
    double slowDuration = 0,
    TowerType towerType = TowerType.pulseArcher,
  }) {
    position.setFrom(startPosition);
    this.targetPosition.setFrom(targetPosition);
    this.speed = speed;
    this.damage = damage;
    this.color = color ?? this.color;
    this.slowAmount = slowAmount;
    this.slowDuration = slowDuration;
    this.towerType = towerType;
    this.target = target;
    this.onHit = onHit;
    _active = true;
    _time = 0;
    _rotationAngle = 0;
    _spiralPhase = 0;
    _pulsePhase = 0;
    size = Vector2.all(6);
    _electricSegments.clear();
    _cacheHSLColors();
    _initializeTypeEffects();
    _initializeTrail();
  }

  /// Deactivate projectile (for pooling)
  void deactivate() {
    _active = false;
    target = null;
    onHit = null;
    removeFromParent();
    BulletManager.returnToPool(this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;

    _time += dt;

    // Lifetime máximo (3 segundos) - evita balas zombies
    if (_time > 3.0) {
      deactivate();
      return;
    }

    // Bounds check - elimina balas fuera del mundo
    const maxBound = 1200.0;
    const minBound = -100.0;
    if (position.x < minBound || position.x > maxBound ||
        position.y < minBound || position.y > maxBound) {
      deactivate();
      return;
    }

    _rotationAngle += dt * 10;
    _spiralPhase += dt * 8;
    _pulsePhase += dt * 15;

    // Skip expensive visual updates for off-screen projectiles
    final isOnScreen = position.x > -50 && position.x < Enemy.screenSize.x + 50 &&
                       position.y > -50 && position.y < Enemy.screenSize.y + 50;

    // Update trail (only if on-screen)
    if (allowTrails && !lowFx && isOnScreen) {
      _updateTrail();
    }

    // Update particles (only if on-screen)
    if (!lowFx && isOnScreen) {
      for (final particle in _particles) {
        particle.update(dt);
      }
    }

    // Update electric segments for Phase Mage (only if on-screen)
    if (!lowFx && isOnScreen) {
      for (final segment in _electricSegments) {
        segment.update(dt, _random);
      }
    }

    // Move toward target position using scalar math to avoid repeated vector normalizations.
    final dx = targetPosition.x - position.x;
    final dy = targetPosition.y - position.y;
    final distanceSq = (dx * dx) + (dy * dy);

    if (distanceSq < 25) {
      // Hit - apply damage and effects if target still valid
      if (target != null && target!.isAlive) {
        target!.takeDamage(damage);
        final killed = !target!.isAlive;

        // Apply slow effect if applicable
        if (appliesSlow && target!.isAlive) {
          target!.applySlow(slowAmount, slowDuration);
        }

        onHit?.call(target!, target!.position.clone(), killed);

        // Spawn impact effect
        _spawnImpactEffect();
      }
      deactivate();
      return;
    }

    final distance = math.sqrt(distanceSq);
    final invDistance = distance > 0 ? 1.0 / distance : 0.0;
    var stepX = dx * invDistance * speed * dt;
    var stepY = dy * invDistance * speed * dt;

    // Add wobble for Phase Mage
    if (_wobbleAmount > 0) {
      final wobble = math.sin(_spiralPhase) * _wobbleAmount * dt * 100;
      stepX += -dy * invDistance * wobble;
      stepY += dx * invDistance * wobble;
    }

    final stepLenSq = (stepX * stepX) + (stepY * stepY);
    if (stepLenSq >= distanceSq) {
      position.setFrom(targetPosition);
    } else {
      position.x += stepX;
      position.y += stepY;
    }
  }

  void _spawnImpactEffect() {
    final effect = ImpactEffect.spawn(
      position: position.clone(),
      color: color,
      towerType: towerType,
    );
    if (effect != null) {
      parent?.add(effect);
    }
  }

  void _updateTrail() {
    // CIRCULAR BUFFER: O(1) update instead of O(n) array shifting
    // Decay all alphas first (applied once per update)
    for (int i = 0; i < _trailAlphas.length; i++) {
      _trailAlphas[i] *= 0.85;
    }

    // Move head forward and write new position
    _trailHead = (_trailHead + 1) % _maxTrailLength;
    _trailPositions[_trailHead].setFrom(position);
    _trailAlphas[_trailHead] = 1.0;
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;

    // OFF-SCREEN CULLING - Skip rendering projectiles outside visible area
    // This saves significant GPU time when many projectiles are off-screen
    final parent = this.parent;
    if (parent != null && parent is PositionComponent) {
      final screenPos = parent.position + position;
      const cullPadding = 50.0; // Extra padding for trails
      if (screenPos.x < -cullPadding ||
          screenPos.y < -cullPadding ||
          screenPos.x > Enemy.screenSize.x + cullPadding ||
          screenPos.y > Enemy.screenSize.y + cullPadding) {
        return; // Skip rendering - off-screen
      }
    }

    super.render(canvas);

    // Use cached sprites for maximum performance in high-stress mode
    if (lowFx || stressLevel >= 1) {
      _renderCachedSprite(canvas);
      return;
    }

    // Draw type-specific effects (full quality)
    switch (towerType) {
      case TowerType.pulseArcher:
        _renderPulseArcher(canvas);
        break;
      case TowerType.circuitCannon:
        _renderCircuitCannon(canvas);
        break;
      case TowerType.phaseMage:
        _renderPhaseMage(canvas);
        break;
      case TowerType.glimmerField:
        _renderGlimmerField(canvas);
        break;
      case TowerType.ionSniper:
      case TowerType.teslaTerminal:
      case TowerType.resonanceSiphon:
      case TowerType.neuralDisruptor:
        _renderPulseArcher(canvas); // Fallback to basic for now
        break;
      case TowerType.plasmaBubble:
        _renderPlasmaBubble(canvas);
        break;
    }
  }

  /// High-performance rendering using pre-cached sprites
  void _renderCachedSprite(Canvas canvas) {
    final spriteCache = SpriteCacheService.instance;

    // Try to get cached glow sprite
    final glowSprite = spriteCache.getProjectileGlowSprite(color);
    if (glowSprite != null && stressLevel < 2) {
      // Draw glow from cache
      final glowScale = size.x / 16.0;
      canvas.save();
      canvas.scale(glowScale, glowScale);
      canvas.drawImage(
        glowSprite,
        Offset(-glowSprite.width / 2, -glowSprite.height / 2),
        _simplePaint,
      );
      canvas.restore();
    }

    // Try to get cached projectile sprite
    final sprite = spriteCache.getProjectileSprite(color);
    if (sprite != null) {
      // Draw with rotation toward target
      final dx = targetPosition.x - position.x;
      final dy = targetPosition.y - position.y;
      final angle = (dx * dx + dy * dy) > 0 ? math.atan2(dy, dx) : 0.0;
      final spriteScale = size.x / 12.0;

      canvas.save();
      canvas.rotate(angle);
      canvas.scale(spriteScale, spriteScale);
      canvas.drawImage(
        sprite,
        Offset(-sprite.width / 2, -sprite.height / 2),
        _simplePaint,
      );
      canvas.restore();
    } else {
      // Fallback to simple circle if cache not ready
      _simplePaint.color = _getPalette(color).o85;
      canvas.drawCircle(Offset.zero, size.x * 0.4, _simplePaint);
    }
  }

  void _renderPulseArcher(Canvas canvas) {
    // Sleek arrow-like projectile
    if (allowTrails) {
      _drawTrail(canvas);
    }

    final pulseScale = 1.0 + math.sin(_pulsePhase) * 0.1;

    // Motion blur trail effect
    canvas.save();
    final dx = targetPosition.x - position.x;
    final dy = targetPosition.y - position.y;
    if ((dx * dx + dy * dy) > 0) {
      final angle = math.atan2(dy, dx);
      canvas.rotate(angle);
    }

    // Arrow shape glow
    final palette = _getPalette(color);
    _reusableArrowPath.reset();
    _reusableArrowPath.moveTo(size.x * 0.8, 0);
    _reusableArrowPath.lineTo(-size.x * 0.4, -size.x * 0.3);
    _reusableArrowPath.lineTo(-size.x * 0.2, 0);
    _reusableArrowPath.lineTo(-size.x * 0.4, size.x * 0.3);
    _reusableArrowPath.close();

    _glowPaint.color = palette.o30;
    canvas.drawPath(_reusableArrowPath, _glowPaint);

    _simplePaint.color = palette.o80;
    canvas.drawPath(_reusableArrowPath, _simplePaint);

    // Bright tip
    _glowPaint.color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(size.x * 0.6, 0), size.x * 0.2 * pulseScale, _glowPaint);

    canvas.restore();

    // Energy particles
    _drawParticles(canvas);
  }

  void _renderCircuitCannon(Canvas canvas) {
    // Heavy, powerful projectile
    if (allowTrails) {
      _drawTrail(canvas);
    }

    final palette = _getPalette(color);
    final pulseScale = 1.0 + math.sin(_pulsePhase * 0.5) * 0.2;

    // Outer shockwave ring
    _strokePaint
      ..color = palette.o20
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset.zero, size.x * 0.9 * pulseScale, _strokePaint);

    // Heavy core - layered circles (avoids per-frame RadialGradient allocation)
    _simplePaint.color = palette.o50;
    canvas.drawCircle(Offset.zero, size.x * 0.6 * pulseScale, _simplePaint);

    _simplePaint.color = color;
    canvas.drawCircle(Offset.zero, size.x * 0.4 * pulseScale, _simplePaint);

    _simplePaint.color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset.zero, size.x * 0.15 * pulseScale, _simplePaint);

    // Outer glow
    _glowPaint
      ..color = palette.o50
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, size.x * 0.7 * pulseScale, _glowPaint);

    // Rotating circuit lines
    canvas.save();
    canvas.rotate(_rotationAngle * 0.5);

    _circuitLinePaint.color = palette.o60;
    final innerR = size.x * 0.3;
    final outerR = size.x * 0.7;
    for (int i = 0; i < _unitCardinal.length; i++) {
      final dir = _unitCardinal[i];
      _tempOffset1 = Offset(dir.dx * innerR, dir.dy * innerR);
      _tempOffset2 = Offset(dir.dx * outerR, dir.dy * outerR);
      canvas.drawLine(_tempOffset1, _tempOffset2, _circuitLinePaint);
    }

    canvas.restore();
  }

  void _renderPhaseMage(Canvas canvas) {
    // Mystical, ethereal projectile with electric arcs
    if (allowTrails) {
      _drawTrail(canvas);
    }

    final palette = _getPalette(color);
    final pulseScale = 1.0 + math.sin(_pulsePhase) * 0.15;

    // Electric arcs around projectile
    _arcPaint
      ..color = palette.o70
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (final segment in _electricSegments) {
      final startX = segment.dirX * size.x * 0.3;
      final startY = segment.dirY * size.x * 0.3;

      // Create zigzag path using reusable path
      _reusableArcPath.reset();
      _reusableArcPath.moveTo(startX, startY);

      const steps = 4;
      for (int i = 1; i <= steps; i++) {
        final progress = i / steps;
        final baseX = startX + (segment.endDirX * segment.length - startX) * progress;
        final baseY = startY + (segment.endDirY * segment.length - startY) * progress;

        final jitter = math.sin(_time * 20 + i * 2) * 3;
        final jitterX = segment.perpX * jitter;
        final jitterY = segment.perpY * jitter;

        _reusableArcPath.lineTo(baseX + jitterX, baseY + jitterY);
      }

      canvas.drawPath(_reusableArcPath, _arcPaint);
    }

    // Mystical core with inner glow
    _glowPaint
      ..color = palette.o30
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset.zero, size.x * 0.5 * pulseScale, _glowPaint);

    // Spiraling rune ring
    canvas.save();
    canvas.rotate(_spiralPhase);

    for (int i = 0; i < _unitHex.length; i++) {
      final runeX = _unitHex[i].dx * size.x * 0.4;
      final runeY = _unitHex[i].dy * size.x * 0.4;
      final runeAlpha = 0.5 + math.sin(_pulsePhase + i) * 0.3;

      // Diamond rune using reusable path
      _reusableRunePath.reset();
      _reusableRunePath.moveTo(runeX, runeY - 2);
      _reusableRunePath.lineTo(runeX + 1.5, runeY);
      _reusableRunePath.lineTo(runeX, runeY + 2);
      _reusableRunePath.lineTo(runeX - 1.5, runeY);
      _reusableRunePath.close();

      _simplePaint.color = color.withOpacity(runeAlpha);
      canvas.drawPath(_reusableRunePath, _simplePaint);
    }

    canvas.restore();

    // Core
    _simplePaint.color = color;
    canvas.drawCircle(Offset.zero, size.x * 0.25 * pulseScale, _simplePaint);

    // Inner bright
    _simplePaint.color = const Color(0xFFFFFFFF).withOpacity(0.9);
    canvas.drawCircle(Offset.zero, size.x * 0.12 * pulseScale, _simplePaint);
  }

  void _renderGlimmerField(Canvas canvas) {
    // Rapid, sparkly projectile
    if (allowTrails) {
      _drawTrail(canvas);
    }

    final palette = _getPalette(color);
    final pulseScale = 1.0 + math.sin(_pulsePhase * 2) * 0.2;
    final spiralPhase2 = _spiralPhase * 2;
    final spiralCos = math.cos(spiralPhase2);
    final spiralSin = math.sin(spiralPhase2);
    final pulseSin = math.sin(_pulsePhase);
    final pulseCos = math.cos(_pulsePhase);
    final pulse2Sin = math.sin(_pulsePhase * 2);
    final pulse2Cos = math.cos(_pulsePhase * 2);

    // Multiple sparkle particles
    for (int i = 0; i < 8; i++) {
      final sinOffset = _glimmerSinOffsets[i];
      final cosOffset = _glimmerCosOffsets[i];
      final sinPulseOffset = pulseSin * cosOffset + pulseCos * sinOffset;
      final sparkDist = size.x * (0.3 + sinPulseOffset * 0.2);

      final base = _unitOct[i];
      final sparkX = (base.dx * spiralCos - base.dy * spiralSin) * sparkDist;
      final sparkY = (base.dx * spiralSin + base.dy * spiralCos) * sparkDist;

      final sinOffset2 = _glimmerSinOffsetsFast[i];
      final cosOffset2 = _glimmerCosOffsetsFast[i];
      final sinPulse2Offset = pulse2Sin * cosOffset2 + pulse2Cos * sinOffset2;
      final sparkAlpha = 0.4 + sinPulse2Offset * 0.4;

      if (sparkAlpha > 0.2) {
        _tempOffset1 = Offset(sparkX, sparkY);
        _sparkPaint.color = color.withOpacity(sparkAlpha);
        _drawStar(canvas, _tempOffset1, 2, _sparkPaint.color, spiralCos, spiralSin);
      }
    }

    // Central burst
    _glowPaint.color = palette.o40;
    canvas.drawCircle(Offset.zero, size.x * 0.4 * pulseScale, _glowPaint);

    // Flickering core - use palette for closest match
    _simplePaint.color = palette.o80;
    canvas.drawCircle(Offset.zero, size.x * 0.25 * pulseScale, _simplePaint);

    // Bright center
    _simplePaint.color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset.zero, size.x * 0.12 * pulseScale, _simplePaint);

    // Extra particles
    _drawParticles(canvas);
  }

  void _renderPlasmaBubble(Canvas canvas) {
    // Plasma bubble projectile with 7 visual layers
    // Uses purple/pink plasma colors with wobble effect

    final bubbleRadius = size.x * 0.5;
    final pulseScale = 1.0 + math.sin(_pulsePhase * 1.5) * 0.08;
    final wobbleX = math.sin(_time * 8) * 1.5 * _wobbleAmount;
    final wobbleY = math.cos(_time * 6) * 1.0 * _wobbleAmount;

    // Use cached HSL-derived colors (computed once at init, not per-frame)
    final pinkColor = _hslPinkColor;
    final purpleColor = _hslPurpleColor;
    final brightColor = _hslBrightColor;

    // Cached palettes for constant-opacity lookups
    final palette = _getPalette(color);
    final pinkPalette = _getPalette(pinkColor);
    final purplePalette = _getPalette(purpleColor);

    canvas.save();
    canvas.translate(wobbleX, wobbleY);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: DISTORTION TRAIL BEHIND BUBBLE
    // ═══════════════════════════════════════════════════════════════════════
    if (allowTrails && _trailPositions.length > 2) {
      for (int i = 1; i < _trailPositions.length; i++) {
        final physIdx = _getTrailPhysicalIndex(i);
        final alpha = _trailAlphas[physIdx];
        if (alpha < 0.1) continue;

        final trailOffset = _trailPositions[physIdx] - position;
        final progress = i / _maxTrailLength;
        final distortRadius = bubbleRadius * (1.2 - progress * 0.5);

        // Distortion ripples
        final ripplePhase = _time * 10 - i * 0.5;
        final rippleScale = 1.0 + math.sin(ripplePhase) * 0.15;

        _tempOffset1 = Offset(trailOffset.x - wobbleX, trailOffset.y - wobbleY);
        _bubbleDistortionPaint.color = purpleColor.withOpacity(alpha * 0.25);
        canvas.drawCircle(_tempOffset1, distortRadius * rippleScale, _bubbleDistortionPaint);

        // Secondary pink distortion
        if (alpha > 0.3) {
          _bubbleDistortionPaint.color = pinkColor.withOpacity(alpha * 0.15);
          canvas.drawCircle(_tempOffset1, distortRadius * 0.7 * rippleScale, _bubbleDistortionPaint);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: OUTER BUBBLE MEMBRANE (translucent sphere outline)
    // ═══════════════════════════════════════════════════════════════════════
    final membraneRadius = bubbleRadius * pulseScale;

    // Outer glow for bubble membrane
    if (allowGlow) {
      _bubbleMembraneGlowPaint.color = palette.o40;
      canvas.drawCircle(Offset.zero, membraneRadius * 1.2, _bubbleMembraneGlowPaint);

      // Secondary pink glow
      _bubbleMembraneGlowPaint.color = pinkPalette.o25;
      canvas.drawCircle(Offset.zero, membraneRadius * 1.4, _bubbleMembraneGlowPaint);
    }

    // Main membrane outline with varying thickness
    for (int ring = 0; ring < 3; ring++) {
      final ringOffset = ring * 0.08;
      final ringAlpha = 0.5 - ring * 0.15;
      final ringRadius = membraneRadius * (1.0 - ringOffset);

      _bubbleMembranePaint
        ..color = Color.lerp(color, pinkColor, ring / 3)!.withOpacity(ringAlpha)
        ..strokeWidth = 2.0 - ring * 0.5;
      canvas.drawCircle(Offset.zero, ringRadius, _bubbleMembranePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: INNER PLASMA SWIRL (animated rotating pattern)
    // ═══════════════════════════════════════════════════════════════════════
    final swirlAngle = _spiralPhase * 1.5;

    // Draw multiple swirl arms
    for (int arm = 0; arm < 3; arm++) {
      _reusableBubbleSwirlPath.reset();

      final armAngle = swirlAngle + arm * math.pi * 2 / 3;
      var started = false;

      // Create spiral from center outward
      for (int i = 0; i < 20; i++) {
        final progress = i / 20;
        final spiralRadius = membraneRadius * 0.15 + progress * membraneRadius * 0.65;
        final spiralAngle = armAngle + progress * math.pi * 2;

        // Add wobble to spiral
        final wobbleFactor = math.sin(_time * 12 + i * 0.5) * 0.1;
        final adjustedRadius = spiralRadius * (1.0 + wobbleFactor);

        final sx = math.cos(spiralAngle) * adjustedRadius;
        final sy = math.sin(spiralAngle) * adjustedRadius;

        if (!started) {
          _reusableBubbleSwirlPath.moveTo(sx, sy);
          started = true;
        } else {
          _reusableBubbleSwirlPath.lineTo(sx, sy);
        }
      }

      final swirlColor = Color.lerp(purpleColor, pinkColor, arm / 3)!;
      _bubbleSwirlPaint.color = swirlColor.withOpacity(0.6);
      if (allowGlow) {
        _bubbleSwirlPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      } else {
        _bubbleSwirlPaint.maskFilter = null;
      }
      canvas.drawPath(_reusableBubbleSwirlPath, _bubbleSwirlPaint);
    }

    // Inner plasma glow
    _bubbleInnerGlowPaint.color = color.withOpacity(0.3);
    canvas.drawCircle(Offset.zero, membraneRadius * 0.7, _bubbleInnerGlowPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: SURFACE SHIMMER HIGHLIGHTS
    // ═══════════════════════════════════════════════════════════════════════
    // Multiple shimmer points on the bubble surface
    for (int shimmer = 0; shimmer < 5; shimmer++) {
      final shimmerAngle = _time * 3 + shimmer * math.pi * 2 / 5;
      final shimmerPhase = math.sin(_time * 8 + shimmer * 1.3);

      // Only show shimmer when phase is positive (creates flickering effect)
      if (shimmerPhase > 0) {
        final shimmerDist = membraneRadius * (0.7 + shimmerPhase * 0.25);
        final shimmerX = math.cos(shimmerAngle) * shimmerDist;
        final shimmerY = math.sin(shimmerAngle) * shimmerDist;
        final shimmerSize = 2.0 + shimmerPhase * 1.5;

        _bubbleShimmerPaint.color = brightColor.withOpacity(shimmerPhase * 0.7);
        canvas.drawCircle(Offset(shimmerX, shimmerY), shimmerSize, _bubbleShimmerPaint);

        // White highlight core
        _bubbleHighlightPaint.color = const Color(0xFFFFFFFF).withOpacity(shimmerPhase * 0.5);
        canvas.drawCircle(Offset(shimmerX, shimmerY), shimmerSize * 0.5, _bubbleHighlightPaint);
      }
    }

    // Main specular highlight (top-left)
    final mainHighlightX = -membraneRadius * 0.35;
    final mainHighlightY = -membraneRadius * 0.35;
    final highlightPulse = 0.6 + math.sin(_time * 5) * 0.2;

    _bubbleShimmerPaint.color = const Color(0xFFFFFFFF).withOpacity(highlightPulse * 0.6);
    canvas.drawCircle(Offset(mainHighlightX, mainHighlightY), membraneRadius * 0.25, _bubbleShimmerPaint);

    _bubbleHighlightPaint.color = const Color(0xFFFFFFFF).withOpacity(highlightPulse * 0.8);
    canvas.drawCircle(Offset(mainHighlightX, mainHighlightY), membraneRadius * 0.12, _bubbleHighlightPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: ENERGY CORE GLOW AT CENTER
    // ═══════════════════════════════════════════════════════════════════════
    final coreRadius = membraneRadius * 0.3;
    final corePulse = 1.0 + math.sin(_pulsePhase * 2) * 0.2;

    // Outer core glow
    if (allowGlow) {
      _bubbleEnergyCorePaint.color = pinkPalette.o50;
      canvas.drawCircle(Offset.zero, coreRadius * 1.8 * corePulse, _bubbleEnergyCorePaint);

      _bubbleEnergyCorePaint.color = palette.o60;
      canvas.drawCircle(Offset.zero, coreRadius * 1.3 * corePulse, _bubbleEnergyCorePaint);
    }

    // Core - layered circles (avoids per-frame RadialGradient allocation)
    final coreR = coreRadius * corePulse;
    _bubblePlasmaCorePaint.color = purplePalette.o50;
    canvas.drawCircle(Offset.zero, coreR, _bubblePlasmaCorePaint);

    _bubblePlasmaCorePaint.color = color;
    canvas.drawCircle(Offset.zero, coreR * 0.6, _bubblePlasmaCorePaint);

    _bubblePlasmaCorePaint.color = brightColor;
    canvas.drawCircle(Offset.zero, coreR * 0.3, _bubblePlasmaCorePaint);

    _bubblePlasmaCorePaint.color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset.zero, coreR * 0.1, _bubblePlasmaCorePaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: SMALL ORBITING PARTICLES AROUND BUBBLE
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < 6; i++) {
      final orbitAngle = _time * 5 + i * math.pi / 3;
      final orbitRadius = membraneRadius * (1.1 + math.sin(_time * 3 + i) * 0.15);
      final particleX = math.cos(orbitAngle) * orbitRadius;
      final particleY = math.sin(orbitAngle) * orbitRadius;

      // Varying particle sizes
      final particleSize = 1.5 + math.sin(_time * 8 + i * 2) * 0.5;
      final particleAlpha = 0.5 + math.sin(_time * 6 + i * 1.5) * 0.3;

      // Particle glow
      final particleColor = Color.lerp(pinkColor, purpleColor, i / 6)!;
      _bubbleOrbitPaint.color = particleColor.withOpacity(particleAlpha * 0.7);
      canvas.drawCircle(Offset(particleX, particleY), particleSize * 2, _bubbleOrbitPaint);

      // Bright particle core
      _bubbleHighlightPaint.color = brightColor.withOpacity(particleAlpha);
      canvas.drawCircle(Offset(particleX, particleY), particleSize, _bubbleHighlightPaint);
    }

    // Inner orbiting particles (smaller, faster)
    for (int i = 0; i < 4; i++) {
      final innerOrbitAngle = -_time * 8 + i * math.pi / 2;
      final innerOrbitRadius = membraneRadius * 0.5;
      final innerParticleX = math.cos(innerOrbitAngle) * innerOrbitRadius;
      final innerParticleY = math.sin(innerOrbitAngle) * innerOrbitRadius;

      final innerSize = 1.0 + math.sin(_time * 12 + i) * 0.3;

      _bubbleHighlightPaint.color = const Color(0x99FFFFFF);
      canvas.drawCircle(Offset(innerParticleX, innerParticleY), innerSize, _bubbleHighlightPaint);
    }

    canvas.restore();

    // Draw additional particles around the projectile
    if (!lowFx) {
      _drawParticles(canvas);
    }
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double radius,
    Color starColor,
    double rotCos,
    double rotSin,
  ) {
    _reusableStarPath.reset();
    for (int i = 0; i < _starUnitPoints.length; i++) {
      final p = _starUnitPoints[i];
      final x = center.dx + (p.dx * rotCos - p.dy * rotSin) * radius;
      final y = center.dy + (p.dx * rotSin + p.dy * rotCos) * radius;
      if (i == 0) {
        _reusableStarPath.moveTo(x, y);
      } else {
        _reusableStarPath.lineTo(x, y);
      }
    }
    _reusableStarPath.close();

    _glowPaint.color = starColor;
    canvas.drawPath(_reusableStarPath, _glowPaint);
  }

  void _drawTrail(Canvas canvas) {
    if (_trailPositions.length < 2) return;

    // Use cached HSL-derived colors (computed once at init, not per-frame)
    final secondaryColor = _hslSecondaryColor;
    final tertiaryColor = _hslTertiaryColor;
    final complementColor = _hslComplementColor;
    final ringColor0 = color;
    final ringColor1 = Color.lerp(color, secondaryColor, 1 / 3)!;
    final ringColor2 = Color.lerp(color, secondaryColor, 2 / 3)!;
    final tendrilColor0 = color;
    final tendrilColor1 = Color.lerp(color, tertiaryColor, 1 / 4)!;
    final tendrilColor2 = Color.lerp(color, tertiaryColor, 2 / 4)!;
    final tendrilColor3 = Color.lerp(color, tertiaryColor, 3 / 4)!;
    final sparkColor0 = Color.lerp(color, const Color(0xFFFFFFFF), 0.3)!;
    final sparkColor1 = Color.lerp(color, const Color(0xFFFFFFFF), 0.5)!;
    final sparkColor2 = Color.lerp(color, const Color(0xFFFFFFFF), 0.7)!;

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: DEEP OUTER PLASMA GLOW WITH COLOR GRADIENT
    // ═══════════════════════════════════════════════════════════════════════
    if (allowGlow) {
      for (int i = 1; i < _trailPositions.length; i++) {
        final physIdx = _getTrailPhysicalIndex(i);
        final alpha = _trailAlphas[physIdx];
        if (alpha < 0.05) continue;

        final trailOffset = _trailPositions[physIdx] - position;
        final progress = i / _maxTrailLength;
        final trailSize = size.x * (1.2 - progress * 0.6);
        _tempOffset1 = Offset(trailOffset.x, trailOffset.y);

        // Outer plasma glow with gradient from primary to secondary color
        final gradientColor = _trailBridgeColors.isNotEmpty
            ? _trailBridgeColors[i]
            : Color.lerp(color, secondaryColor, progress)!;
        _plasmaOuterGlowPaint.color = gradientColor.withOpacity(alpha * 0.25);
        canvas.drawCircle(_tempOffset1, trailSize * 2.5, _plasmaOuterGlowPaint);

        // Secondary glow layer with tertiary color
        _plasmaOuterGlowPaint.color = tertiaryColor.withOpacity(alpha * 0.15);
        canvas.drawCircle(_tempOffset1, trailSize * 1.8, _plasmaOuterGlowPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: PLASMA ENERGY RINGS EXPANDING FROM TRAIL
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 1; i < _trailPositions.length; i += 2) {
      final physIdx = _getTrailPhysicalIndex(i);
      final alpha = _trailAlphas[physIdx];
      if (alpha < 0.1) continue;

      final trailOffset = _trailPositions[physIdx] - position;
      final progress = i / _maxTrailLength;
      _tempOffset1 = Offset(trailOffset.x, trailOffset.y);

      // Multiple concentric rings with phase offset
      for (int ring = 0; ring < 3; ring++) {
        final ringPhase = _time * 8 + ring * 0.5 + i * 0.2;
        final ringPulse = (math.sin(ringPhase) * 0.5 + 0.5);
        final ringRadius = size.x * (0.4 + ring * 0.25 + ringPulse * 0.3) * (1 - progress * 0.5);
        final ringAlpha = alpha * (0.4 - ring * 0.1) * (1 - ringPulse * 0.3);

        if (ringAlpha > 0.05) {
          final ringColor = ring == 0
              ? ringColor0
              : (ring == 1 ? ringColor1 : ringColor2);
          _plasmaRingPaint
            ..color = ringColor.withOpacity(ringAlpha)
            ..strokeWidth = 1.5 - ring * 0.3;
          canvas.drawCircle(_tempOffset1, ringRadius, _plasmaRingPaint);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: WISPY ENERGY TENDRILS FLOWING FROM PROJECTILE
    // ═══════════════════════════════════════════════════════════════════════
    if (_trailPositions.length > 3) {
      for (int tendril = 0; tendril < 4; tendril++) {
        _reusablePlasmaWispPath.reset();

        final tendrilAngle = _time * 3 + tendril * math.pi / 2;
        final tendrilOffset = math.sin(_time * 5 + tendril) * 3;

        bool started = false;
        for (int i = 0; i < _trailPositions.length - 1; i++) {
          final physIdx = _getTrailPhysicalIndex(i);
          final alpha = _trailAlphas[physIdx];
          if (alpha < 0.1) continue;

          final trailOffset = _trailPositions[physIdx] - position;
          final wispAngle = tendrilAngle + i * 0.3;
          final wispRadius = (3 + math.sin(_time * 6 + i * 0.5) * 2) * alpha;

          final wx = trailOffset.x + math.cos(wispAngle) * wispRadius + tendrilOffset;
          final wy = trailOffset.y + math.sin(wispAngle) * wispRadius;

          if (!started) {
            _reusablePlasmaWispPath.moveTo(wx, wy);
            started = true;
          } else {
            _reusablePlasmaWispPath.lineTo(wx, wy);
          }
        }

        if (started) {
          final tendrilColor = tendril == 0
              ? tendrilColor0
              : (tendril == 1
                  ? tendrilColor1
                  : (tendril == 2 ? tendrilColor2 : tendrilColor3));
          _plasmaWispPaint
            ..color = tendrilColor.withOpacity(0.4)
            ..strokeWidth = 2 - tendril * 0.3;
          if (allowGlow) {
            _plasmaWispPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          }
          canvas.drawPath(_reusablePlasmaWispPath, _plasmaWispPaint);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: COLOR-SHIFTING CHROMATIC PLASMA BANDS
    // ═══════════════════════════════════════════════════════════════════════
    for (int band = 0; band < 3; band++) {
      final bandOffset = (band - 1) * 2.0;

      for (int i = 1; i < _trailPositions.length; i++) {
        final physIdx = _getTrailPhysicalIndex(i);
        final alpha = _trailAlphas[physIdx];
        if (alpha < 0.15) continue;

        final trailOffset = _trailPositions[physIdx] - position;
        final progress = i / _maxTrailLength;
        final trailSize = size.x * 0.3 * (1 - progress * 0.7);

        // Chromatic split effect - each band slightly offset
        final chromaColor = band == 0
            ? Color.fromARGB((alpha * 180).toInt(), 255, 100, 100)
            : band == 1
                ? Color.fromARGB((alpha * 180).toInt(), 100, 255, 100)
                : Color.fromARGB((alpha * 180).toInt(), 100, 100, 255);

        _tempOffset1 = Offset(trailOffset.x + bandOffset, trailOffset.y + bandOffset * 0.5);
        _plasmaChromaPaint.color = chromaColor;
        canvas.drawCircle(_tempOffset1, trailSize, _plasmaChromaPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: PLASMA VORTEX SPIRAL EFFECT
    // ═══════════════════════════════════════════════════════════════════════
    _reusablePlasmaVortexPath.reset();
    bool vortexStarted = false;

    for (int arm = 0; arm < 2; arm++) {
      final armAngle = _time * 4 + arm * math.pi;

      for (int i = 0; i < _trailPositions.length; i++) {
        final physIdx = _getTrailPhysicalIndex(i);
        final alpha = _trailAlphas[physIdx];
        if (alpha < 0.1) continue;

        final trailOffset = _trailPositions[physIdx] - position;
        final spiralAngle = armAngle + i * 0.4;
        final spiralRadius = (2 + i * 0.3) * alpha;

        final sx = trailOffset.x + math.cos(spiralAngle) * spiralRadius;
        final sy = trailOffset.y + math.sin(spiralAngle) * spiralRadius;

        if (!vortexStarted) {
          _reusablePlasmaVortexPath.moveTo(sx, sy);
          vortexStarted = true;
        } else {
          _reusablePlasmaVortexPath.lineTo(sx, sy);
        }
      }
    }

    if (vortexStarted) {
      _plasmaVortexPaint.color = secondaryColor.withOpacity(0.35);
      if (allowGlow) {
        _plasmaVortexPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      }
      canvas.drawPath(_reusablePlasmaVortexPath, _plasmaVortexPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: ELECTRIC MICRO-ARCS BETWEEN TRAIL POINTS
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < _trailPositions.length - 2; i += 2) {
      final physIdxStart = _getTrailPhysicalIndex(i);
      final physIdxEnd = _getTrailPhysicalIndex(i + 2);
      final alpha = _trailAlphas[physIdxStart];
      if (alpha < 0.2) continue;

      final start = _trailPositions[physIdxStart] - position;
      final end = _trailPositions[physIdxEnd] - position;

      _reusablePlasmaPath.reset();
      _reusablePlasmaPath.moveTo(start.x, start.y);

      // Create zigzag lightning effect
      const segments = 4;
      for (int seg = 1; seg <= segments; seg++) {
        final progress = seg / segments;
        final baseX = start.x + (end.x - start.x) * progress;
        final baseY = start.y + (end.y - start.y) * progress;

        // Add jitter perpendicular to line
        final perpAngle = math.atan2(end.y - start.y, end.x - start.x) + math.pi / 2;
        final jitter = math.sin(_time * 25 + i * 3 + seg * 2) * 2 * alpha;

        _reusablePlasmaPath.lineTo(
          baseX + math.cos(perpAngle) * jitter,
          baseY + math.sin(perpAngle) * jitter,
        );
      }

      _plasmaArcPaint.color = color.withOpacity(alpha * 0.6);
      if (allowGlow) {
        _plasmaArcPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      }
      canvas.drawPath(_reusablePlasmaPath, _plasmaArcPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: HOT PLASMA CORE WITH WHITE CENTER
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 1; i < _trailPositions.length; i++) {
      final physIdx = _getTrailPhysicalIndex(i);
      final alpha = _trailAlphas[physIdx];
      if (alpha < 0.1) continue;

      final trailOffset = _trailPositions[physIdx] - position;
      final progress = i / _maxTrailLength;
      final coreSize = size.x * 0.4 * (1 - progress * 0.6);
      _tempOffset1 = Offset(trailOffset.x, trailOffset.y);

      // Layered circles approximating gradient (avoids per-frame RadialGradient allocation)
      _plasmaCorePaint.color = secondaryColor.withOpacity(alpha * 0.3);
      canvas.drawCircle(_tempOffset1, coreSize, _plasmaCorePaint);

      _plasmaCorePaint.color = color.withOpacity(alpha * 0.7);
      canvas.drawCircle(_tempOffset1, coreSize * 0.4, _plasmaCorePaint);

      _plasmaCorePaint.color = Color.fromRGBO(255, 255, 255, alpha * 0.9);
      canvas.drawCircle(_tempOffset1, coreSize * 0.15, _plasmaCorePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 8: FLOATING PLASMA SPARKS AND EMBERS
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < _trailPositions.length; i += 2) {
      final physIdx = _getTrailPhysicalIndex(i);
      final alpha = _trailAlphas[physIdx];
      if (alpha < 0.15) continue;

      final trailOffset = _trailPositions[physIdx] - position;

      // Generate multiple sparks around each trail point
      for (int spark = 0; spark < 3; spark++) {
        final sparkAngle = _time * 10 + i * 1.5 + spark * 2.1;
        final sparkDist = (4 + math.sin(_time * 8 + spark) * 3) * alpha;
        final sparkSize = (1.5 + _random.nextDouble()) * alpha;

        final sparkX = trailOffset.x + math.cos(sparkAngle) * sparkDist;
        final sparkY = trailOffset.y + math.sin(sparkAngle) * sparkDist;

        final sparkColor = spark == 0
            ? sparkColor0
            : (spark == 1 ? sparkColor1 : sparkColor2);
        _plasmaSparkPaint.color = sparkColor.withOpacity(alpha * 0.7);
        canvas.drawCircle(Offset(sparkX, sparkY), sparkSize, _plasmaSparkPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 9: HEAT DISTORTION WAVE EFFECT
    // ═══════════════════════════════════════════════════════════════════════
    if (allowGlow && _trailPositions.length > 4) {
      for (int wave = 0; wave < 2; wave++) {
        final wavePhase = _time * 6 + wave * math.pi;
        final waveIndex = (wavePhase * 2).toInt() % _trailPositions.length;

        if (waveIndex > 0 && waveIndex < _trailPositions.length) {
          final physIdx = _getTrailPhysicalIndex(waveIndex);
          final alpha = _trailAlphas[physIdx];
          if (alpha > 0.2) {
            final trailOffset = _trailPositions[physIdx] - position;
            final waveRadius = size.x * (0.8 + math.sin(wavePhase) * 0.3);

            _tempOffset1 = Offset(trailOffset.x, trailOffset.y);
            _plasmaHeatPaint.color = complementColor.withOpacity(alpha * 0.2);
            canvas.drawCircle(_tempOffset1, waveRadius, _plasmaHeatPaint);
          }
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 10: TRAILING ENERGY RIBBON
    // ═══════════════════════════════════════════════════════════════════════
    if (_trailPositions.length > 2) {
      _reusablePlasmaPath.reset();
      bool ribbonStarted = false;

      // Draw smooth ribbon through trail points
      for (int i = 0; i < _trailPositions.length; i++) {
        final physIdx = _getTrailPhysicalIndex(i);
        final alpha = _trailAlphas[physIdx];
        if (alpha < 0.05) continue;

        final trailOffset = _trailPositions[physIdx] - position;
        final ribbonWave = math.sin(_time * 4 + i * 0.8) * 2;

        if (!ribbonStarted) {
          _reusablePlasmaPath.moveTo(trailOffset.x, trailOffset.y + ribbonWave);
          ribbonStarted = true;
        } else {
          _reusablePlasmaPath.lineTo(trailOffset.x, trailOffset.y + ribbonWave);
        }
      }

      if (ribbonStarted) {
        _plasmaEnergyPaint.color = tertiaryColor.withOpacity(0.5);
        _trailLinePaint
          ..color = tertiaryColor.withOpacity(0.5)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
        canvas.drawPath(_reusablePlasmaPath, _trailLinePaint);
        _trailLinePaint.style = PaintingStyle.fill;
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 11: CONNECTING PLASMA BRIDGES
    // ═══════════════════════════════════════════════════════════════════════
    _trailLinePaint
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2.5
      ..maskFilter = allowGlow ? const MaskFilter.blur(BlurStyle.normal, 3) : null;

    for (int i = 0; i < _trailPositions.length - 1; i++) {
      final physIdxStart = _getTrailPhysicalIndex(i);
      final physIdxEnd = _getTrailPhysicalIndex(i + 1);
      if (_trailAlphas[physIdxStart] < 0.1 || _trailAlphas[physIdxEnd] < 0.1) continue;

      final start = _trailPositions[physIdxStart] - position;
      final end = _trailPositions[physIdxEnd] - position;
      _tempOffset1 = Offset(start.x, start.y);
      _tempOffset2 = Offset(end.x, end.y);

      // Color gradient along the trail
      final bridgeColor = _trailBridgeColors.isNotEmpty
          ? _trailBridgeColors[i]
          : Color.lerp(color, secondaryColor, i / _maxTrailLength)!;
      _trailLinePaint.color =
          bridgeColor.withOpacity(_trailAlphas[physIdxStart] * 0.5);
      canvas.drawLine(_tempOffset1, _tempOffset2, _trailLinePaint);
    }
  }

  void _drawParticles(Canvas canvas) {
    // Set up paint once before loop - no per-particle MaskFilter allocation
    _particlePaint.maskFilter = allowGlow ? const MaskFilter.blur(BlurStyle.normal, 2) : null;

    for (final particle in _particles) {
      final phase = _time * particle.speed * 0.1;
      final phaseSin = math.sin(phase);
      final phaseCos = math.cos(phase);
      final px = (particle.baseCos * phaseCos - particle.baseSin * phaseSin) * particle.offset.x;
      final py = (particle.baseSin * phaseCos + particle.baseCos * phaseSin) * particle.offset.y;

      _particlePaint.color = color.withOpacity(
        particle.alpha * (0.5 + math.sin(_time * 5 + particle.angle) * 0.3),
      );
      _tempOffset1 = Offset(px, py);
      canvas.drawCircle(_tempOffset1, particle.size, _particlePaint);
    }
  }
}

class _ProjectileParticle {
  _ProjectileParticle({
    required this.offset,
    required this.speed,
    required this.angle,
    required this.size,
    required this.alpha,
  }) : baseCos = math.cos(angle),
       baseSin = math.sin(angle);

  Vector2 offset;
  double speed;
  double angle;
  double size;
  double alpha;
  double baseCos;
  double baseSin;

  void reset({
    required Vector2 offset,
    required double speed,
    required double angle,
    required double size,
    required double alpha,
  }) {
    this.offset.setFrom(offset);
    this.speed = speed;
    this.angle = angle;
    baseCos = math.cos(angle);
    baseSin = math.sin(angle);
    this.size = size;
    this.alpha = alpha;
  }

  void update(double dt) {
    angle += dt * speed * 0.05;
    baseCos = math.cos(angle);
    baseSin = math.sin(angle);
  }
}

class _ElectricSegment {
  _ElectricSegment({
    required this.angle,
    required this.length,
    required this.offset,
  }) {
    _recomputeDirs();
  }

  double angle;
  double length;
  double offset;
  double _timer = 0;
  double dirX = 0;
  double dirY = 0;
  double perpX = 0;
  double perpY = 0;
  double endDirX = 0;
  double endDirY = 0;

  void reset({
    required double angle,
    required double length,
    required double offset,
  }) {
    this.angle = angle;
    this.length = length;
    this.offset = offset;
    _timer = 0;
    _recomputeDirs();
  }

  void update(double dt, _FastRng random) {
    _timer += dt;
    if (_timer > 0.1) {
      _timer = 0;
      // Randomly adjust angle
      angle += (random.nextDouble() - 0.5) * 0.5;
      offset = random.nextDouble() * math.pi * 2;
      _recomputeDirs();
    }
  }

  void _recomputeDirs() {
    dirX = math.cos(angle);
    dirY = math.sin(angle);
    perpX = -dirY;
    perpY = dirX;
    final endAngle = angle + offset;
    endDirX = math.cos(endAngle);
    endDirY = math.sin(endAngle);
  }
}

/// Pre-computed color palette to avoid per-frame Color.withOpacity() allocations.
/// Each projectile color gets a cached palette with common opacity variations.
class _ColorPalette {
  _ColorPalette(Color base)
      : o10 = base.withOpacity(0.1),
        o15 = base.withOpacity(0.15),
        o20 = base.withOpacity(0.2),
        o25 = base.withOpacity(0.25),
        o30 = base.withOpacity(0.3),
        o40 = base.withOpacity(0.4),
        o50 = base.withOpacity(0.5),
        o60 = base.withOpacity(0.6),
        o70 = base.withOpacity(0.7),
        o80 = base.withOpacity(0.8),
        o85 = base.withOpacity(0.85),
        o90 = base.withOpacity(0.9),
        base = base;

  final Color base;
  final Color o10;
  final Color o15;
  final Color o20;
  final Color o25;
  final Color o30;
  final Color o40;
  final Color o50;
  final Color o60;
  final Color o70;
  final Color o80;
  final Color o85;
  final Color o90;
}

