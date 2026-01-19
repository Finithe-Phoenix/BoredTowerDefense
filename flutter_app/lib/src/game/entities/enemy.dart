import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';

/// Callback types for enemy events
typedef EnemyDeathCallback = void Function(Enemy enemy);
typedef EnemyReachBaseCallback = void Function(Enemy enemy);

/// Enemy type with visual and stat modifiers
/// Organized by world themes for unique encounters
enum EnemyType {
  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 1: NEON FRONTIER - Basic enemy types (tutorial)
  // ═══════════════════════════════════════════════════════════════════════════
  runner(color: Color(0xFFFF7043), speedMult: 1.0, healthMult: 1.0, sizeMult: 1.0, isPhantom: false, world: 1),
  overloaded(color: Color(0xFFFF0066), speedMult: 1.4, healthMult: 0.8, sizeMult: 0.9, isPhantom: false, world: 1),
  juggernaut(color: Color(0xFF9C27B0), speedMult: 0.6, healthMult: 2.5, sizeMult: 1.4, isPhantom: false, world: 1),
  phantom(color: Color(0xFF00FFAA), speedMult: 1.1, healthMult: 1.2, sizeMult: 0.95, isPhantom: true, world: 1),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 2: RIFT WARS - Dimensional glitch enemies
  // ═══════════════════════════════════════════════════════════════════════════
  glitcher(color: Color(0xFF00FFFF), speedMult: 1.2, healthMult: 0.9, sizeMult: 0.85, isPhantom: false, world: 2),
  riftwalker(color: Color(0xFFFF00FF), speedMult: 0.8, healthMult: 1.8, sizeMult: 1.2, isPhantom: true, world: 2),
  voidling(color: Color(0xFF6600FF), speedMult: 1.3, healthMult: 0.7, sizeMult: 0.75, isPhantom: false, world: 2),
  dimensionBreaker(color: Color(0xFFFF3399), speedMult: 0.5, healthMult: 3.0, sizeMult: 1.5, isPhantom: false, world: 2),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 3: SIGNAL WASTES - Corrupted data enemies
  // ═══════════════════════════════════════════════════════════════════════════
  corruptedByte(color: Color(0xFF33FF33), speedMult: 1.1, healthMult: 1.0, sizeMult: 0.9, isPhantom: false, world: 3),
  malware(color: Color(0xFFFF0000), speedMult: 0.9, healthMult: 1.5, sizeMult: 1.1, isPhantom: false, world: 3),
  dataWorm(color: Color(0xFF99FF00), speedMult: 1.5, healthMult: 0.6, sizeMult: 0.7, isPhantom: false, world: 3),
  virusCarrier(color: Color(0xFFCC0066), speedMult: 0.7, healthMult: 2.2, sizeMult: 1.3, isPhantom: false, world: 3),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 4: ION CROWN - Electric/plasma enemies
  // ═══════════════════════════════════════════════════════════════════════════
  sparkDrone(color: Color(0xFFFFFF00), speedMult: 1.3, healthMult: 0.8, sizeMult: 0.8, isPhantom: false, world: 4),
  plasmaCore(color: Color(0xFFFFAA00), speedMult: 0.7, healthMult: 2.0, sizeMult: 1.25, isPhantom: false, world: 4),
  ionSurge(color: Color(0xFF00CCFF), speedMult: 1.6, healthMult: 0.5, sizeMult: 0.65, isPhantom: false, world: 4),
  thunderHulk(color: Color(0xFFFF6600), speedMult: 0.4, healthMult: 3.5, sizeMult: 1.6, isPhantom: false, world: 4),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 5: SHARD VAULT - Crystal/mineral enemies
  // ═══════════════════════════════════════════════════════════════════════════
  crystalShard(color: Color(0xFF66FFFF), speedMult: 1.0, healthMult: 1.3, sizeMult: 0.95, isPhantom: false, world: 5),
  gemCarrier(color: Color(0xFFFF66FF), speedMult: 0.8, healthMult: 1.8, sizeMult: 1.15, isPhantom: false, world: 5),
  prismWalker(color: Color(0xFFFFFFFF), speedMult: 1.2, healthMult: 1.0, sizeMult: 0.9, isPhantom: true, world: 5),
  diamondGolem(color: Color(0xFF00FFCC), speedMult: 0.35, healthMult: 4.0, sizeMult: 1.7, isPhantom: false, world: 5),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 6: ARC FORTRESS - Mechanical/robotic enemies
  // ═══════════════════════════════════════════════════════════════════════════
  sentryBot(color: Color(0xFF888888), speedMult: 0.9, healthMult: 1.4, sizeMult: 1.0, isPhantom: false, world: 6),
  droneSwarm(color: Color(0xFFCCCCCC), speedMult: 1.5, healthMult: 0.5, sizeMult: 0.6, isPhantom: false, world: 6),
  siegeWalker(color: Color(0xFF555555), speedMult: 0.5, healthMult: 2.8, sizeMult: 1.45, isPhantom: false, world: 6),
  cloakedAssassin(color: Color(0xFF333333), speedMult: 1.4, healthMult: 1.0, sizeMult: 0.85, isPhantom: true, world: 6),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 7: OMEGA GRID - Digital/matrix enemies
  // ═══════════════════════════════════════════════════════════════════════════
  codeFragment(color: Color(0xFF00FF00), speedMult: 1.2, healthMult: 0.9, sizeMult: 0.8, isPhantom: false, world: 7),
  matrixAgent(color: Color(0xFF009900), speedMult: 1.0, healthMult: 1.5, sizeMult: 1.05, isPhantom: false, world: 7),
  firewallBreaker(color: Color(0xFF66FF66), speedMult: 0.6, healthMult: 2.5, sizeMult: 1.35, isPhantom: false, world: 7),
  systemGhost(color: Color(0xFF003300), speedMult: 1.3, healthMult: 1.1, sizeMult: 0.9, isPhantom: true, world: 7),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 8: STORM TOWER - Weather/elemental enemies
  // ═══════════════════════════════════════════════════════════════════════════
  stormRunner(color: Color(0xFF3399FF), speedMult: 1.4, healthMult: 0.85, sizeMult: 0.9, isPhantom: false, world: 8),
  cycloneSpirit(color: Color(0xFF99CCFF), speedMult: 1.1, healthMult: 1.2, sizeMult: 1.0, isPhantom: true, world: 8),
  thunderTitan(color: Color(0xFF0066CC), speedMult: 0.45, healthMult: 3.2, sizeMult: 1.55, isPhantom: false, world: 8),
  lightningWraith(color: Color(0xFFCCFFFF), speedMult: 1.7, healthMult: 0.6, sizeMult: 0.7, isPhantom: false, world: 8),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 9: FINAL GATE - Void/dark enemies
  // ═══════════════════════════════════════════════════════════════════════════
  voidStalker(color: Color(0xFF660066), speedMult: 1.2, healthMult: 1.3, sizeMult: 1.0, isPhantom: true, world: 9),
  abyssWalker(color: Color(0xFF330033), speedMult: 0.8, healthMult: 2.0, sizeMult: 1.2, isPhantom: false, world: 9),
  shadowSwarm(color: Color(0xFF990099), speedMult: 1.6, healthMult: 0.7, sizeMult: 0.65, isPhantom: false, world: 9),
  darknessTitan(color: Color(0xFF220022), speedMult: 0.4, healthMult: 3.8, sizeMult: 1.65, isPhantom: false, world: 9),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 10: OMEGA NEXUS - Ultimate hybrid enemies
  // ═══════════════════════════════════════════════════════════════════════════
  nexusHunter(color: Color(0xFFFF0099), speedMult: 1.3, healthMult: 1.5, sizeMult: 1.1, isPhantom: false, world: 10),
  omegaSentinel(color: Color(0xFF9900FF), speedMult: 0.7, healthMult: 2.5, sizeMult: 1.4, isPhantom: false, world: 10),
  realityShifter(color: Color(0xFFFFFF00), speedMult: 1.1, healthMult: 1.3, sizeMult: 1.0, isPhantom: true, world: 10),
  apocalypseHerald(color: Color(0xFFFF3300), speedMult: 0.3, healthMult: 5.0, sizeMult: 1.8, isPhantom: false, world: 10);

  const EnemyType({
    required this.color,
    required this.speedMult,
    required this.healthMult,
    required this.sizeMult,
    required this.isPhantom,
    this.world = 1,
  });

  final Color color;
  final double speedMult;
  final double healthMult;
  final double sizeMult;
  final bool isPhantom;
  final int world;

  /// Get all enemy types for a specific world
  static List<EnemyType> getWorldEnemies(int worldIndex) {
    return EnemyType.values.where((e) => e.world == worldIndex).toList();
  }

  /// Get basic enemy types (for fallback/mixed waves)
  static List<EnemyType> get basicTypes => [runner, overloaded, juggernaut, phantom];
}

class Enemy extends PositionComponent {
  static const String _appEnv =
      String.fromEnvironment('APP_ENV', defaultValue: 'prod');
  static const bool disablePhantomStealth =
      bool.fromEnvironment('DISABLE_PHANTOM_STEALTH', defaultValue: false) ||
      _appEnv == 'dev';
  static bool lowFx = false;
  static bool forceLowFx = false;
  static bool allowBlur = true;
  static bool throttleOffscreen = false;
  static Vector2 screenOffset = Vector2.zero();
  static Vector2 screenSize = Vector2.zero();
  static double screenScale = 1.0;
  static const double offscreenPadding = 60.0;
  static const double offscreenUpdateInterval = 0.12;

  // ═══════════════════════════════════════════════════════════════════════
  // CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════
  static final Paint _outerGlowPaint = Paint();
  static final Paint _bodyGlowPaint = Paint();
  static final Paint _highlightPaint = Paint();
  static final Paint _trailPaint = Paint();
  static final Paint _particlePaint = Paint();
  static final Paint _circuitPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _auraPaint = Paint();
  static final Paint _corePaint = Paint();

  // Reusable paths to avoid per-frame allocations
  static final Path _reusableBodyPath = Path();
  static final Path _reusableCrownPath = Path();
  static final Path _reusableLayerPath = Path();
  static final Path _reusableOverlayPath = Path();
  static final Path _reusableHexPath = Path();

  // Particle list limits
  static const int _maxDataBits = 20;
  static const int _maxPlasmaParticles = 15;

  Enemy({
    required this.path,
    double speed = 80,
    double maxHealth = 100,
    this.goldReward = 10,
    this.type = EnemyType.runner,
    this.spawnIndex = 0,
    this.threatTier = 0,
    this.worldIndex = 1,
    Vector2? startPosition,
    this.onDeath,
    this.onReachBase,
  }) : _baseSpeed = speed,
       _baseMaxHealth = maxHealth,
       _currentTargetIndex = 0,
       _random = math.Random() {
    _animationPhase = _random.nextDouble() * math.pi * 2;
    _circuitSeed = _random.nextDouble();
    _visualRandom = math.Random(
      (spawnIndex + 1) * 1000003 ^ (_circuitSeed * 1000000).toInt(),
    );
    _initializeCircuitry();
    _initializePhantomNoise();

    // Apply type multipliers
    _maxHealth = _baseMaxHealth * type.healthMult * _tierHealthMult;
    _health = _maxHealth;
    _speed = _baseSpeed * type.speedMult * _tierSpeedMult;

    size = Vector2.all(24 * type.sizeMult * _tierSizeMult);
    anchor = Anchor.center;
    position = startPosition ?? (path.isNotEmpty ? path.first.clone() : Vector2.zero());
    _lastPosition = position.clone();

    // Initialize trail
    _trailPositions = List.generate(_maxTrailLength, (_) => position.clone());
  }

  final List<Vector2> path;
  final double _baseSpeed;
  final double _baseMaxHealth;
  final math.Random _random;
  late final math.Random _visualRandom;
  final int goldReward;
  final EnemyType type;
  final int spawnIndex;
  final int threatTier;
  final int worldIndex;

  int _currentTargetIndex;
  late double _health;
  late double _maxHealth;
  late double _speed;
  late double _animationPhase;

  // Slow effect
  double _slowFactor = 1.0;
  double _slowDuration = 0;

  // Visual trail
  static const int _maxTrailLength = 8;
  late List<Vector2> _trailPositions;
  double _trailUpdateTimer = 0;
  static const double _trailUpdateInterval = 0.03;

  // Hit flash effect
  double _hitFlashTimer = 0;
  static const double _hitFlashDuration = 0.06;

  // Pulse animation
  double _pulseScale = 1.0;

  // Walking animation
  double _walkPhase = 0;
  double _wobbleOffset = 0;
  double _verticalBob = 0;
  Vector2 _lastPosition = Vector2.zero();
  double _speedIndicator = 0;
  double _offscreenAccumulator = 0;

  // New visual state for overhaul
  double _animationTimer = 0;
  final List<_DataBit> _dataBits = [];
  final List<_PlasmaParticle> _plasmaParticles = [];
  late final double _circuitSeed;
  final List<_CircuitSegment> _circuitSegments = [];
  final List<_NoiseBit> _phantomNoise = [];
  double _orbitalRotation = 0;
  double _lastHealth = 0;

  // Damage particles
  final List<_DamageParticle> _damageParticles = [];
  static const int _maxDamageParticles = 12;

  /// Callbacks for events
  EnemyDeathCallback? onDeath;
  EnemyReachBaseCallback? onReachBase;

  /// Current health (read-only)
  double get health => _health;

  /// Max health
  double get maxHealth => _maxHealth;

  /// Current speed (after modifiers)
  double get speed => _speed * _slowFactor;

  /// Health percentage (0.0 to 1.0)
  double get healthPercent => _health / _maxHealth;

  /// Whether enemy is still alive
  bool get isAlive => _health > 0;

  /// Whether enemy has reached the end of path
  bool get hasReachedBase => _currentTargetIndex >= path.length;

  /// Whether enemy is currently slowed
  bool get isSlowed => _slowFactor < 1.0;

  /// The index of the current waypoint the enemy is moving towards.
  int get currentPathIndex => _currentTargetIndex;

  /// Progress along the path (0.0 start, 1.0 end)
  double get pathProgress {
    if (path.isEmpty) return 0.0;
    return (_currentTargetIndex / path.length).clamp(0.0, 1.0);
  }

  /// Whether this enemy is a phantom type
  bool get isPhantom => type.isPhantom;

  /// Whether this enemy is a boss (overridden in Boss class)
  bool get isBoss => false;

  /// Display name for UI (overridden in Boss class)
  String get displayName => type.name.toUpperCase();

  /// Current movement direction (normalized vector towards next waypoint)
  Vector2 get movementDirection {
    if (path.isEmpty || _currentTargetIndex >= path.length) {
      return Vector2(1, 0); // Default direction
    }
    final target = path[_currentTargetIndex];
    final direction = target - position;
    if (direction.length < 0.01) return Vector2(1, 0);
    return direction.normalized();
  }

  double get _tierHealthMult => 1 + (threatTier * 0.2);

  double get _tierSpeedMult => 1 + (threatTier * 0.04);

  double get _tierSizeMult => 1 + (threatTier * 0.08);

  Color get _threatColor {
    if (threatTier <= 0) return type.color;
    final mix = (0.2 + threatTier * 0.12).clamp(0.2, 0.6);
    return Color.lerp(type.color, const Color(0xFFFF3344), mix)!;
  }

  /// Whether the phantom has been revealed (damaged or detected)
  bool _isRevealed = false;
  double _revealTimer = 0;
  static const double _revealDuration = 3.0; // Stays visible for 3 seconds after detection

  /// Whether the phantom is currently visible
  bool get isVisible => !isPhantom || _isRevealed || disablePhantomStealth;

  /// Reveal the phantom temporarily
  void reveal() {
    if (isPhantom && !_isRevealed) {
      _isRevealed = true;
      _revealTimer = _revealDuration;
      AudioService.instance.playPhantomReveal();
    } else if (isPhantom) {
      // Already revealed, just refresh timer
      _revealTimer = _revealDuration;
    }
  }

  /// Apply damage to the enemy
  void takeDamage(double amount) {
    if (!isAlive) return;

    // Reveal phantom when damaged
    if (isPhantom) {
      reveal();
    }

    _health -= amount;
    _hitFlashTimer = _hitFlashDuration;
    _pulseScale = 1.15; // Brief scale up on hit

    // Spawn damage particles
    _spawnDamageParticles();

    if (_health <= 0) {
      _health = 0;
      onDeath?.call(this);
      removeFromParent();
    }
  }

  void _spawnDamageParticles() {
    if (Enemy.lowFx || Enemy.forceLowFx) return;
    final random = _random;
    
    // Standard sparks
    final particleCount = 2 + random.nextInt(3);
    for (int i = 0; i < particleCount && _damageParticles.length < _maxDamageParticles; i++) {
      _damageParticles.add(_DamageParticle(
        angle: random.nextDouble() * math.pi * 2,
        speed: 30 + random.nextDouble() * 50,
        size: 2 + random.nextDouble() * 3,
        lifetime: 0.3 + random.nextDouble() * 0.2,
      ));
    }

    // New Data Bits - with cap to prevent memory leak
    final bitCount = 3 + random.nextInt(4);
    for (int i = 0; i < bitCount && _dataBits.length < _maxDataBits; i++) {
      _dataBits.add(_DataBit(
        position: Vector2.zero(),
        velocity: Vector2(
          (random.nextDouble() - 0.5) * 80,
          (random.nextDouble() - 0.5) * 80,
        ),
        color: type.color,
        size: 2 + random.nextDouble() * 2,
        rotation: random.nextDouble() * math.pi * 2,
        lifetime: 0.6 + random.nextDouble() * 0.4,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final prevX = position.x;
    final prevY = position.y;
    if (throttleOffscreen && _isOffscreen()) {
      _updateStatusTimers(dt);
      _move(dt);
      _postMoveUpdate(prevX, prevY, dt);
      return;
    }

    _animationTimer += dt;
    _animationPhase += dt * 2;
    _walkPhase += dt * speed / 15.0;

    // Update particles
    _updateParticles(dt);
    _updateStatusTimers(dt);

    _orbitalRotation += dt * 2;
    _updatePlasmaParticles(dt);
    _lastHealth = _health;

    _move(dt);
    _postMoveUpdate(prevX, prevY, dt);
  }

  /// Apply slow effect to the enemy
  void applySlow(double factor, double duration) {
    // factor is 0.0 to 1.0 (e.g., 0.5 = 50% slow)
    // _slowFactor is speed multiplier (e.g., 0.5 = 50% speed)
    final newFactor = (1.0 - factor).clamp(0.1, 1.0);
    if (newFactor < _slowFactor) {
      _slowFactor = newFactor;
    }
    if (duration > _slowDuration) {
      _slowDuration = duration;
    }
  }

  void _updatePlasmaParticles(double dt) {
    if (Enemy.lowFx || Enemy.forceLowFx) {
      _plasmaParticles.clear();
      return;
    }

    // Spawn plasma smoke if health is low - with cap to prevent memory leak
    if (healthPercent < 0.4 && _plasmaParticles.length < _maxPlasmaParticles && _random.nextDouble() < 0.15) {
      _plasmaParticles.add(_PlasmaParticle(
        position: Vector2.zero(),
        velocity: Vector2((_random.nextDouble() - 0.5) * 30, -30 - _random.nextDouble() * 30),
        color: type.color,
      ));
    }

    for (int i = _plasmaParticles.length - 1; i >= 0; i--) {
      _plasmaParticles[i].update(dt);
      if (!_plasmaParticles[i].isActive) {
        _plasmaParticles.removeAt(i);
      }
    }
  }

  void _updateParticles(double dt) {
    for (int i = _damageParticles.length - 1; i >= 0; i--) {
      _damageParticles[i].update(dt);
      if (!_damageParticles[i].isActive) {
        _damageParticles.removeAt(i);
      }
    }

    for (int i = _dataBits.length - 1; i >= 0; i--) {
      _dataBits[i].update(dt);
      if (!_dataBits[i].isActive) {
        _dataBits.removeAt(i);
      }
    }
  }

  void _updateStatusTimers(double dt) {
    if (_hitFlashTimer > 0) {
      _hitFlashTimer -= dt;
    }

    if (_pulseScale > 1.0) {
      _pulseScale -= dt * 2;
      if (_pulseScale < 1.0) _pulseScale = 1.0;
    }

    if (isPhantom && _isRevealed) {
      _revealTimer -= dt;
      if (_revealTimer <= 0) {
        _isRevealed = false;
        _revealTimer = 0;
      }
    }

    // Slow effect decay
    if (_slowDuration > 0) {
      _slowDuration -= dt;
      if (_slowDuration <= 0) {
        _slowDuration = 0;
        _slowFactor = 1.0;
      }
    }
  }

  void _initializeCircuitry() {
    _circuitSegments.clear();
    final rand = math.Random((_circuitSeed * 1000).toInt());
    for (int i = 0; i < 4; i++) {
      _circuitSegments.add(_CircuitSegment(
        Offset((rand.nextDouble() - 0.5) * 1.4, (rand.nextDouble() - 0.5) * 1.4),
        Offset((rand.nextDouble() - 0.5) * 1.4, (rand.nextDouble() - 0.5) * 1.4),
      ));
    }
  }

  void _initializePhantomNoise() {
    _phantomNoise.clear();
    if (type != EnemyType.phantom) return;

    final rand = math.Random(spawnIndex);
    for (int i = 0; i < 6; i++) {
      if (rand.nextDouble() < 0.6) {
        _phantomNoise.add(_NoiseBit(
          offset: Offset(
            (rand.nextDouble() - 0.5) * 2.5,
            (rand.nextDouble() - 0.5) * 2.5,
          ),
          phase: rand.nextDouble() * math.pi * 2,
          size: 1.6 + rand.nextDouble() * 1.2,
        ));
      }
    }
  }

  void _postMoveUpdate(double prevX, double prevY, double dt) {
    final dx = position.x - prevX;
    final dy = position.y - prevY;
    if (dt > 0) {
      final distance = math.sqrt(dx * dx + dy * dy);
      _speedIndicator = (distance / (speed * dt + 0.0001)).clamp(0.0, 1.0);
    } else {
      _speedIndicator = 0;
    }
    _lastPosition.setFrom(position);

    _trailUpdateTimer += dt;
    if (_trailUpdateTimer >= _trailUpdateInterval && _trailPositions.isNotEmpty) {
      _trailUpdateTimer = 0;
      final recycled = _trailPositions.removeLast();
      recycled.setFrom(position);
      _trailPositions.insert(0, recycled);
    }
  }

  bool _isOffscreen() {
    if (screenSize.isZero()) return false;
    if (screenScale <= 0) return false;
    final screenX = screenOffset.x + position.x * screenScale;
    final screenY = screenOffset.y + position.y * screenScale;
    final padding = offscreenPadding + size.x;
    return screenX < -padding ||
        screenX > screenSize.x + padding ||
        screenY < -padding ||
        screenY > screenSize.y + padding;
  }

  void _renderLowFx(Canvas canvas, double opacity) {
    final radius = size.x / 2;

    _bodyGlowPaint
      ..color = type.color.withOpacity(0.45 * opacity)
      ..maskFilter = null;
    canvas.drawCircle(Offset.zero, radius, _bodyGlowPaint);

    if (threatTier > 0) {
      _circuitPaint
        ..color = _threatColor.withOpacity(0.5 * opacity)
        ..strokeWidth = 1.2
        ..maskFilter = null;
      canvas.drawCircle(Offset.zero, radius * (1.05 + threatTier * 0.06), _circuitPaint);
    }

    _corePaint
      ..color = Colors.white.withOpacity(0.6 * opacity)
      ..maskFilter = null;
    canvas.drawCircle(Offset.zero, radius * 0.35, _corePaint);

    if (opacity > 0.2) {
      _renderHealthBar(canvas, visibility: opacity);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final reduceFx = Enemy.lowFx || Enemy.forceLowFx;
    final allowBlur = Enemy.allowBlur;
    if (throttleOffscreen && _isOffscreen()) return;

    // Calculate opacity for phantom (invisible when not revealed)
    double phantomOpacity = 1.0;
    if (isPhantom && !disablePhantomStealth) {
      if (!_isRevealed) {
        // Barely visible shimmer effect when invisible
        phantomOpacity = 0.08 + math.sin(_animationPhase * 4) * 0.04;
      } else {
        // Fade out as reveal timer expires
        phantomOpacity = (_revealTimer / _revealDuration).clamp(0.4, 1.0);
      }
    } else if (isPhantom && disablePhantomStealth) {
      // Keep phantoms visible in dev/testing builds.
      phantomOpacity = 0.6 + math.sin(_animationPhase * 3) * 0.08;
    }

    if (reduceFx) {
      _renderLowFx(canvas, phantomOpacity);
      return;
    }

    // Reactive distortion at low health
    final hpFactor = healthPercent;
    if (hpFactor < 0.5) {
      final glitchChance = 0.1 + (0.5 - hpFactor) * 0.8;
      if (_random.nextDouble() < glitchChance) {
        canvas.translate((_random.nextDouble() - 0.5) * 3, (_random.nextDouble() - 0.5) * 3);
      }
    }

    // Render trail first (behind enemy)
    _renderTrail(canvas, phantomOpacity, allowBlur);

    // Render damage particles
    _renderDamageParticles(canvas, allowBlur);

    // Apply world-specific distortions/effects
    _applyWorldVisuals(canvas);

    // Apply walking bob transformation
    canvas.save();
    canvas.translate(_wobbleOffset, _verticalBob);

    // Animation pulse
    final animScale = _pulseScale * (1 + math.sin(_animationPhase) * 0.05);
    final radius = (size.x / 2) * animScale;

    // Speed-based motion blur when moving fast
    if (!reduceFx && _speedIndicator > 0.3) {
      _renderMotionBlur(canvas, radius, phantomOpacity, allowBlur);
    }

    // Outer glow (pulsing intensity based on walk phase)
    final glowPulse = 0.18 + math.sin(_walkPhase) * 0.05;
    final glowPath = _createBodyPath(radius * 1.05);
    _outerGlowPaint
      ..color = type.color.withOpacity(glowPulse * phantomOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.16
      ..strokeJoin = StrokeJoin.bevel
      ..maskFilter = _blur(allowBlur, 8);
    canvas.drawPath(glowPath, _outerGlowPaint);

    // Main body glow
    final bodyPath = _createBodyPath(radius * 0.95);
    _bodyGlowPaint
      ..color = type.color.withOpacity(0.28 * phantomOpacity)
      ..style = PaintingStyle.fill
      ..maskFilter = _blur(allowBlur, 3);
    canvas.drawPath(bodyPath, _bodyGlowPaint);

    // Draw Internal Circuitry
    _drawInternalCircuitry(canvas, radius, phantomOpacity);

    // Draw Data Aura & Fragments
    if (!reduceFx) _drawDataAura(canvas, radius, phantomOpacity);

    // MEGA GEOMETRY: Core, Shell and Plates
    _drawMegaGeometry(canvas, radius, phantomOpacity, allowBlur);

    // Inner highlight (bobs with movement)
    final highlightOffset = Offset(
      -radius * 0.2 + math.sin(_walkPhase * 0.5) * 1,
      -radius * 0.2 + math.cos(_walkPhase * 0.5) * 1,
    );
    _highlightPaint
      ..color = Colors.white.withOpacity(0.35 * phantomOpacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.08;
    canvas.drawLine(
      highlightOffset + Offset(-radius * 0.3, -radius * 0.12),
      highlightOffset + Offset(radius * 0.35, -radius * 0.28),
      _highlightPaint,
    );
    _highlightPaint.strokeWidth = radius * 0.04;
    canvas.drawLine(
      highlightOffset + Offset(-radius * 0.22, 0),
      highlightOffset + Offset(radius * 0.28, -radius * 0.14),
      _highlightPaint,
    );

    if (threatTier > 0) {
      _renderThreatCrown(canvas, radius, phantomOpacity, allowBlur, reduceFx);
    }

    if (!reduceFx) {
      // Walking legs/tentacles effect (type-specific)
      _renderWalkingEffect(canvas, radius, phantomOpacity, allowBlur);

      // Corruption aura (system fracture)
      _renderCorruptionAura(canvas, radius, phantomOpacity, allowBlur);

      // Type-specific effects
      _renderTypeEffects(canvas, radius, phantomOpacity, allowBlur);

      // Glitch overlay on top
      _renderGlitchOverlay(canvas, radius, phantomOpacity, allowBlur);
    }

    canvas.restore(); // Restore world visuals
    canvas.restore(); // Restore walking bob

    // Hit flash overlay (outside canvas transform)
    if (!reduceFx && _hitFlashTimer > 0) {
      _renderHitFlash(canvas, radius, phantomOpacity, allowBlur);
    }

    // Plasma Smoke effect for damaged enemies
    if (!reduceFx && healthPercent < 0.45) {
      _renderPlasmaSmoke(canvas, radius, phantomOpacity);
    }

    // Slow indicator (ice crystal effect)
    if (!reduceFx && isSlowed) {
      _renderSlowEffect(canvas, radius, allowBlur);
    }

    // Health bar (always show while visible enough)
    if (phantomOpacity > 0.2) {
      _renderHealthBar(canvas, visibility: phantomOpacity);
    }
  }

  void _renderMotionBlur(Canvas canvas, double radius, double opacity, bool allowBlur) {
    // Create motion blur effect based on movement direction
    final direction = position - _lastPosition;
    if (direction.length < 0.5) return;

    direction.normalize();
    final blurCount = 3;
    for (int i = 1; i <= blurCount; i++) {
      final blurOffset = -direction * (i * 5.0);
      final blurAlpha = (1 - i / (blurCount + 1)) * 0.35 * opacity * _speedIndicator;
      final blurPath = _createBodyPath(radius * (0.9 - i * 0.08));
      _trailPaint
        ..color = type.color.withOpacity(blurAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.08
        ..strokeCap = StrokeCap.square
        ..maskFilter = _blur(allowBlur, 3.0 + i * 1.5);
      canvas.save();
      canvas.translate(blurOffset.x, blurOffset.y);
      canvas.drawPath(blurPath, _trailPaint);
      canvas.restore();
    }
  }

  void _renderWalkingEffect(Canvas canvas, double radius, double opacity, bool allowBlur) {
    // Get visual style based on enemy archetype
    final style = _getWalkingStyle();

    switch (style) {
      case _WalkStyle.legs:
        _renderLegsEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.tendrils:
        _renderTendrilsEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.stomp:
        _renderStompEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.wisps:
        _renderWispsEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.glitch:
        _renderGlitchWalkEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.electric:
        _renderElectricWalkEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.crystal:
        _renderCrystalWalkEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.mechanical:
        _renderMechanicalWalkEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.digital:
        _renderDigitalWalkEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.storm:
        _renderStormWalkEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.void_:
        _renderVoidWalkEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.omega:
        _renderOmegaWalkEffect(canvas, radius, opacity, allowBlur);
        break;
    }
  }

  _WalkStyle _getWalkingStyle() {
    switch (type) {
      // World 1 - Basic
      case EnemyType.runner:
        return _WalkStyle.legs;
      case EnemyType.overloaded:
        return _WalkStyle.tendrils;
      case EnemyType.juggernaut:
        return _WalkStyle.stomp;
      case EnemyType.phantom:
        return _WalkStyle.wisps;
      // World 2 - Rift Wars (Glitch)
      case EnemyType.glitcher:
      case EnemyType.riftwalker:
      case EnemyType.voidling:
      case EnemyType.dimensionBreaker:
        return _WalkStyle.glitch;
      // World 3 - Signal Wastes (Digital corruption)
      case EnemyType.corruptedByte:
      case EnemyType.malware:
      case EnemyType.dataWorm:
      case EnemyType.virusCarrier:
        return _WalkStyle.digital;
      // World 4 - Ion Crown (Electric)
      case EnemyType.sparkDrone:
      case EnemyType.plasmaCore:
      case EnemyType.ionSurge:
      case EnemyType.thunderHulk:
        return _WalkStyle.electric;
      // World 5 - Shard Vault (Crystal)
      case EnemyType.crystalShard:
      case EnemyType.gemCarrier:
      case EnemyType.prismWalker:
      case EnemyType.diamondGolem:
        return _WalkStyle.crystal;
      // World 6 - Arc Fortress (Mechanical)
      case EnemyType.sentryBot:
      case EnemyType.droneSwarm:
      case EnemyType.siegeWalker:
      case EnemyType.cloakedAssassin:
        return _WalkStyle.mechanical;
      // World 7 - Omega Grid (Matrix)
      case EnemyType.codeFragment:
      case EnemyType.matrixAgent:
      case EnemyType.firewallBreaker:
      case EnemyType.systemGhost:
        return _WalkStyle.digital;
      // World 8 - Storm Tower (Weather)
      case EnemyType.stormRunner:
      case EnemyType.cycloneSpirit:
      case EnemyType.thunderTitan:
      case EnemyType.lightningWraith:
        return _WalkStyle.storm;
      // World 9 - Final Gate (Void)
      case EnemyType.voidStalker:
      case EnemyType.abyssWalker:
      case EnemyType.shadowSwarm:
      case EnemyType.darknessTitan:
        return _WalkStyle.void_;
      // World 10 - Omega Nexus (Ultimate)
      case EnemyType.nexusHunter:
      case EnemyType.omegaSentinel:
      case EnemyType.realityShifter:
      case EnemyType.apocalypseHerald:
        return _WalkStyle.omega;
    }
  }

  void _renderLegsEffect(Canvas canvas, double radius, double opacity, bool allowBlur) {
    for (int i = 0; i < 4; i++) {
      final legPhase = _walkPhase * 2 + i * math.pi / 2;
      final legAngle = math.pi / 2 + i * math.pi / 2 + math.sin(legPhase) * 0.3;
      final legLength = radius * 0.8 + math.sin(legPhase) * radius * 0.2;
      final legX = math.cos(legAngle) * legLength;
      final legY = math.sin(legAngle) * legLength;
      canvas.drawLine(
        Offset.zero,
        Offset(legX, legY),
        Paint()
          ..color = type.color.withOpacity(0.6 * opacity)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.square
          ..maskFilter = _blur(allowBlur, 2),
      );
    }
  }

  void _renderTendrilsEffect(Canvas canvas, double radius, double opacity, bool allowBlur) {
    for (int i = 0; i < 6; i++) {
      final tendrilAngle = _animationPhase * 1.5 + i * math.pi / 3;
      final tendrilLength = radius * (0.8 + math.sin(_walkPhase + i) * 0.3);
      final endX = math.cos(tendrilAngle) * tendrilLength;
      final endY = math.sin(tendrilAngle) * tendrilLength;
      canvas.drawLine(
        Offset.zero,
        Offset(endX, endY),
        Paint()
          ..color = Colors.white.withOpacity(0.4 * opacity)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.square
          ..maskFilter = _blur(allowBlur, 3),
      );
    }
  }

  void _renderStompEffect(Canvas canvas, double radius, double opacity, bool allowBlur) {
    for (int i = 0; i < 2; i++) {
      final footPhase = _walkPhase + i * math.pi;
      final footAngle = math.pi / 2 + i * math.pi;
      final footOffset = math.sin(footPhase) * radius * 0.3;
      final footX = math.cos(footAngle) * (radius * 0.7 + footOffset);
      final footY = math.sin(footAngle) * (radius * 0.7 + footOffset) + math.sin(footPhase).abs() * 3;

      if (math.sin(footPhase) < -0.8) {
        final impactRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(footX, footY + 2), width: radius * 0.6, height: radius * 0.18),
          Radius.circular(radius * 0.04),
        );
        canvas.drawRRect(impactRect, Paint()..color = type.color.withOpacity(0.3 * opacity)..maskFilter = _blur(allowBlur, 6));
      }

      final footRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(footX, footY), width: radius * 0.5, height: radius * 0.22),
        Radius.circular(radius * 0.05),
      );
      canvas.drawRRect(footRect, Paint()..color = type.color.withOpacity(0.7 * opacity));
    }
  }

  void _renderWispsEffect(Canvas canvas, double radius, double opacity, bool allowBlur) {
    for (int i = 0; i < 4; i++) {
      final wispPhase = _animationPhase * 2 + i * math.pi / 2;
      final wispDist = radius * (0.9 + math.sin(wispPhase * 0.5) * 0.3);
      final wispAngle = wispPhase * 0.3 + i * math.pi / 2;
      final wispX = math.cos(wispAngle) * wispDist;
      final wispY = math.sin(wispAngle) * wispDist;

      for (int j = 0; j < 3; j++) {
        final trailAlpha = (1 - j / 3) * 0.4 * opacity;
        final trailOffset = j * 3.0;
        final shardX = wispX - math.cos(wispAngle) * trailOffset;
        final shardY = wispY - math.sin(wispAngle) * trailOffset;
        canvas.save();
        canvas.translate(shardX, shardY);
        canvas.rotate(wispAngle + _animationPhase * 0.4);
        _particlePaint..color = type.color.withOpacity(trailAlpha)..style = PaintingStyle.fill..maskFilter = _blur(allowBlur, 2);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 4.0 - j, height: 1.5), _particlePaint);
        canvas.restore();
      }
    }
  }

  void _renderGlitchWalkEffect(Canvas canvas, double radius, double opacity, bool allowBlur) {
    // Dimensional rifts and glitchy teleport trails
    final glitchPaint = Paint()
      ..color = type.color.withOpacity(0.5 * opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;

    for (int i = 0; i < 5; i++) {
      final glitchPhase = _animationTimer * 8 + i * 1.2;
      final flicker = math.sin(glitchPhase) > 0.3 ? 1.0 : 0.0;
      if (flicker == 0) continue;

      final angle = (i / 5) * math.pi * 2 + _animationTimer * 2;
      final dist = radius * (0.7 + math.sin(glitchPhase * 0.5) * 0.4);
      final x = math.cos(angle) * dist;
      final y = math.sin(angle) * dist;

      // Glitch line with offset
      final offsetX = math.sin(glitchPhase * 3) * 4;
      canvas.drawLine(
        Offset(x + offsetX, y - 4),
        Offset(x - offsetX, y + 4),
        glitchPaint..maskFilter = _blur(allowBlur, 3),
      );
    }

    // Rift portal effect
    if (type == EnemyType.riftwalker || type == EnemyType.dimensionBreaker) {
      final riftPaint = Paint()
        ..color = const Color(0xFFFF00FF).withOpacity(0.3 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: radius * 1.8, height: radius * 0.6),
        riftPaint..maskFilter = _blur(allowBlur, 4),
      );
    }
  }

  void _renderElectricWalkEffect(Canvas canvas, double radius, double opacity, bool allowBlur) {
    // Electric arcs and sparks
    final sparkPaint = Paint()
      ..color = type.color.withOpacity(0.7 * opacity)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 6; i++) {
      final sparkPhase = _animationTimer * 12 + i * 0.8;
      final active = math.sin(sparkPhase) > 0.2;
      if (!active) continue;

      final angle = (i / 6) * math.pi * 2;
      final startDist = radius * 0.6;
      final endDist = radius * (1.0 + math.sin(sparkPhase * 2) * 0.3);

      // Jagged lightning bolt
      final startX = math.cos(angle) * startDist;
      final startY = math.sin(angle) * startDist;
      final endX = math.cos(angle) * endDist;
      final endY = math.sin(angle) * endDist;

      final midX = (startX + endX) / 2 + math.sin(sparkPhase * 5) * 3;
      final midY = (startY + endY) / 2 + math.cos(sparkPhase * 5) * 3;

      canvas.drawLine(Offset(startX, startY), Offset(midX, midY), sparkPaint);
      canvas.drawLine(Offset(midX, midY), Offset(endX, endY), sparkPaint);
    }

    // Electric aura for larger enemies
    if (type == EnemyType.thunderHulk || type == EnemyType.plasmaCore) {
      final auraPaint = Paint()
        ..color = type.color.withOpacity(0.2 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = _blur(allowBlur, 8);
      canvas.drawCircle(Offset.zero, radius * 1.3, auraPaint);
    }
  }

  void _renderCrystalWalkEffect(Canvas canvas, double radius, double opacity, bool allowBlur) {
    // Floating crystal shards
    final crystalPaint = Paint()
      ..color = type.color.withOpacity(0.6 * opacity)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final phase = _animationTimer * 1.5 + i * math.pi * 0.4;
      final dist = radius * (0.9 + math.sin(phase) * 0.2);
      final angle = (i / 5) * math.pi * 2 + _animationTimer * 0.5;
      final x = math.cos(angle) * dist;
      final y = math.sin(angle) * dist;
      final shardSize = radius * (0.15 + 0.05 * math.sin(phase * 2));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + _animationTimer);

      // Diamond shard shape
      _reusableOverlayPath.reset();
      _reusableOverlayPath.moveTo(0, -shardSize);
      _reusableOverlayPath.lineTo(shardSize * 0.5, 0);
      _reusableOverlayPath.lineTo(0, shardSize);
      _reusableOverlayPath.lineTo(-shardSize * 0.5, 0);
      _reusableOverlayPath.close();

      canvas.drawPath(_reusableOverlayPath, crystalPaint);
      canvas.drawPath(_reusableOverlayPath, Paint()
        ..color = Colors.white.withOpacity(0.3 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
      canvas.restore();
    }

    // Prismatic light rays for special types
    if (type == EnemyType.prismWalker || type == EnemyType.diamondGolem) {
      for (int i = 0; i < 3; i++) {
        final rayAngle = _animationTimer * 2 + i * math.pi * 2 / 3;
        final rayColor = [const Color(0xFFFF0000), const Color(0xFF00FF00), const Color(0xFF0000FF)][i];
        canvas.drawLine(
          Offset.zero,
          Offset(math.cos(rayAngle) * radius * 1.5, math.sin(rayAngle) * radius * 1.5),
          Paint()..color = rayColor.withOpacity(0.15 * opacity)..strokeWidth = 2..maskFilter = _blur(allowBlur, 4),
        );
      }
    }
  }

  void _renderMechanicalWalkEffect(Canvas canvas, double radius, double opacity, bool allowBlur) {
    // Mechanical legs/treads
    final metalPaint = Paint()
      ..color = type.color.withOpacity(0.7 * opacity)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square;

    if (type == EnemyType.droneSwarm) {
      // Propeller effect
      for (int i = 0; i < 4; i++) {
        final bladeAngle = _animationTimer * 20 + i * math.pi / 2;
        final bladeLen = radius * 0.8;
        canvas.drawLine(
          Offset.zero,
          Offset(math.cos(bladeAngle) * bladeLen, math.sin(bladeAngle) * bladeLen),
          metalPaint..maskFilter = _blur(allowBlur, 2),
        );
      }
    } else {
      // Piston legs
      for (int i = 0; i < 4; i++) {
        final legPhase = _walkPhase * 1.5 + i * math.pi / 2;
        final extension = math.sin(legPhase) * radius * 0.3;
        final angle = math.pi / 2 + i * math.pi / 2;
        final baseLen = radius * 0.7;

        final x1 = math.cos(angle) * baseLen;
        final y1 = math.sin(angle) * baseLen;
        final x2 = math.cos(angle) * (baseLen + extension);
        final y2 = math.sin(angle) * (baseLen + extension);

        // Piston joint
        canvas.drawCircle(Offset(x1, y1), 2, Paint()..color = Colors.white.withOpacity(0.5 * opacity));
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), metalPaint);
      }
    }

    // Exhaust ports for heavy mechs
    if (type == EnemyType.siegeWalker) {
      final exhaustPhase = _animationTimer * 4;
      if (math.sin(exhaustPhase) > 0.5) {
        canvas.drawCircle(
          Offset(-radius * 0.8, 0),
          radius * 0.15,
          Paint()..color = const Color(0xFFFF6600).withOpacity(0.4 * opacity)..maskFilter = _blur(allowBlur, 6),
        );
      }
    }
  }

  void _renderDigitalWalkEffect(Canvas canvas, double radius, double opacity, bool allowBlur) {
    // Binary/data stream effect
    final dataPaint = Paint()
      ..color = type.color.withOpacity(0.5 * opacity)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final phase = _animationTimer * 3 + i * 0.4;
      final progress = (phase % 1.0);
      final angle = (i / 8) * math.pi * 2;
      final dist = radius * (0.5 + progress * 0.8);
      final x = math.cos(angle) * dist;
      final y = math.sin(angle) * dist;
      final bitSize = 2 + (1 - progress) * 2;

      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: bitSize, height: bitSize),
        dataPaint..color = type.color.withOpacity((1 - progress) * 0.6 * opacity),
      );
    }

    // Matrix rain for matrix agents
    if (type == EnemyType.matrixAgent || type == EnemyType.firewallBreaker) {
      for (int i = 0; i < 4; i++) {
        final rainX = -radius * 0.6 + i * radius * 0.4;
        final rainY = (((_animationTimer * 2 + i * 0.3) % 1.0) - 0.5) * radius * 2;
        canvas.drawRect(
          Rect.fromCenter(center: Offset(rainX, rainY), width: 2, height: 6),
          Paint()..color = const Color(0xFF00FF00).withOpacity(0.4 * opacity),
        );
      }
    }
  }

  void _renderStormWalkEffect(Canvas canvas, double radius, double opacity, bool allowBlur) {
    // Wind/cyclone effect
    final windPaint = Paint()
      ..color = type.color.withOpacity(0.4 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Spiral wind lines
    for (int i = 0; i < 3; i++) {
      final spiralPhase = _animationTimer * 4 + i * math.pi * 2 / 3;
      final spiralRadius = radius * (0.6 + i * 0.2);

      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: spiralRadius),
        spiralPhase,
        math.pi * 0.7,
        false,
        windPaint..maskFilter = _blur(allowBlur, 3),
      );
    }

    // Lightning for thunder types
    if (type == EnemyType.thunderTitan || type == EnemyType.lightningWraith) {
      final boltPhase = _animationTimer * 15;
      if (math.sin(boltPhase) > 0.7) {
        final boltAngle = math.sin(boltPhase * 0.3) * math.pi;
        canvas.drawLine(
          Offset.zero,
          Offset(math.cos(boltAngle) * radius * 1.5, math.sin(boltAngle) * radius * 1.5),
          Paint()..color = Colors.white.withOpacity(0.8 * opacity)..strokeWidth = 2..maskFilter = _blur(allowBlur, 4),
        );
      }
    }

    // Rain drops
    for (int i = 0; i < 4; i++) {
      final dropX = -radius + i * radius * 0.6;
      final dropY = (((_animationTimer * 3 + i * 0.25) % 1.0) - 0.5) * radius * 2;
      canvas.drawLine(
        Offset(dropX, dropY),
        Offset(dropX - 2, dropY + 4),
        Paint()..color = const Color(0xFF99CCFF).withOpacity(0.3 * opacity)..strokeWidth = 1,
      );
    }
  }

  void _renderVoidWalkEffect(Canvas canvas, double radius, double opacity, bool allowBlur) {
    // Dark void tendrils
    final voidPaint = Paint()
      ..color = type.color.withOpacity(0.6 * opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      final tendrilPhase = _animationTimer * 1.5 + i * math.pi * 0.4;
      final angle = (i / 5) * math.pi * 2 + math.sin(tendrilPhase) * 0.3;
      final length = radius * (0.8 + math.sin(tendrilPhase * 2) * 0.3);

      // Wavy tendril
      final midAngle = angle + math.sin(tendrilPhase * 3) * 0.2;
      final midDist = length * 0.5;
      final midX = math.cos(midAngle) * midDist;
      final midY = math.sin(midAngle) * midDist;
      final endX = math.cos(angle) * length;
      final endY = math.sin(angle) * length;

      canvas.drawLine(Offset.zero, Offset(midX, midY), voidPaint..maskFilter = _blur(allowBlur, 2));
      canvas.drawLine(Offset(midX, midY), Offset(endX, endY), voidPaint);
    }

    // Darkness aura
    canvas.drawCircle(
      Offset.zero,
      radius * 1.2,
      Paint()
        ..color = Colors.black.withOpacity(0.2 * opacity)
        ..maskFilter = _blur(allowBlur, 10),
    );

    // Shadow particles for swarm type
    if (type == EnemyType.shadowSwarm) {
      for (int i = 0; i < 6; i++) {
        final px = math.cos(_animationTimer * 2 + i) * radius * 0.8;
        final py = math.sin(_animationTimer * 2 + i) * radius * 0.8;
        canvas.drawCircle(
          Offset(px, py),
          2,
          Paint()..color = type.color.withOpacity(0.4 * opacity),
        );
      }
    }
  }

  void _renderOmegaWalkEffect(Canvas canvas, double radius, double opacity, bool allowBlur) {
    // Ultimate combined effects - energy + void + electric
    final omegaPaint = Paint()
      ..color = type.color.withOpacity(0.5 * opacity)
      ..strokeWidth = 2;

    // Rotating energy rings
    for (int i = 0; i < 3; i++) {
      final ringPhase = _animationTimer * (2 + i * 0.5);
      final ringRadius = radius * (0.7 + i * 0.2);

      canvas.save();
      canvas.rotate(ringPhase);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: ringRadius),
        0,
        math.pi * 1.5,
        false,
        omegaPaint..style = PaintingStyle.stroke..maskFilter = _blur(allowBlur, 3),
      );
      canvas.restore();
    }

    // Energy spikes
    for (int i = 0; i < 6; i++) {
      final spikePhase = _animationTimer * 3 + i * math.pi / 3;
      final active = math.sin(spikePhase * 2) > 0;
      if (!active) continue;

      final angle = (i / 6) * math.pi * 2;
      final length = radius * (0.9 + math.sin(spikePhase) * 0.3);

      canvas.drawLine(
        Offset(math.cos(angle) * radius * 0.5, math.sin(angle) * radius * 0.5),
        Offset(math.cos(angle) * length, math.sin(angle) * length),
        Paint()
          ..color = Colors.white.withOpacity(0.6 * opacity)
          ..strokeWidth = 1.5
          ..maskFilter = _blur(allowBlur, 2),
      );
    }

    // Reality distortion for shifter
    if (type == EnemyType.realityShifter) {
      final distortPhase = _animationTimer * 5;
      if (math.sin(distortPhase) > 0.5) {
        canvas.drawCircle(
          Offset(math.sin(distortPhase * 3) * 5, math.cos(distortPhase * 3) * 5),
          radius * 0.8,
          Paint()..color = type.color.withOpacity(0.2 * opacity)..maskFilter = _blur(allowBlur, 8),
        );
      }
    }

    // Apocalypse flames for herald
    if (type == EnemyType.apocalypseHerald) {
      for (int i = 0; i < 4; i++) {
        final flamePhase = _animationTimer * 6 + i;
        final flameY = -radius * 0.5 - math.sin(flamePhase) * radius * 0.3;
        final flameX = (i - 1.5) * radius * 0.4;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(flameX, flameY), width: radius * 0.2, height: radius * 0.4),
          Paint()..color = const Color(0xFFFF3300).withOpacity(0.4 * opacity)..maskFilter = _blur(allowBlur, 5),
        );
      }
    }
  }

  void _renderHitFlash(Canvas canvas, double radius, double opacity, bool allowBlur) {
    final flashProgress = _hitFlashTimer / _hitFlashDuration;

    // Flash overlay
    final flashPath = _createBodyPath(radius * 1.1);
    _highlightPaint
      ..color = Colors.white.withOpacity(flashProgress * 0.35 * opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = _blur(allowBlur, 3);
    canvas.drawPath(flashPath, _highlightPaint);

    // Expanding ring
    final ringRadius = radius * (1.1 + (1 - flashProgress) * 0.35);
    final ringPath = _createBodyPath(ringRadius);
    _circuitPaint
      ..color = const Color(0xFFFF0066).withOpacity(flashProgress * 0.35 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.square
      ..maskFilter = _blur(allowBlur, 2);
    canvas.drawPath(ringPath, _circuitPaint);

    // Directional damage sparks
    for (int i = 0; i < 4; i++) {
      final sparkAngle = i * math.pi / 2 + _animationPhase;
      final sparkDist = radius * (1 + (1 - flashProgress) * 0.8);
      final sparkX = math.cos(sparkAngle) * sparkDist;
      final sparkY = math.sin(sparkAngle) * sparkDist;

      _particlePaint
        ..color = Colors.white.withOpacity(flashProgress * 0.5 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.square
        ..maskFilter = _blur(allowBlur, 2);
      canvas.drawLine(
        Offset(sparkX, sparkY),
        Offset(
          sparkX + math.cos(sparkAngle) * radius * 0.2,
          sparkY + math.sin(sparkAngle) * radius * 0.2,
        ),
        _particlePaint,
      );
    }
  }

  void _renderDamageParticles(Canvas canvas, bool allowBlur) {
    // Standard sparks
    for (final particle in _damageParticles) {
      if (!particle.isActive) continue;

      final px = math.cos(particle.angle) * particle.distance;
      final py = math.sin(particle.angle) * particle.distance;
      final alpha = particle.alpha;
      final shardLength = particle.size * 2.6;
      final shardWidth = particle.size * 0.7;
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(particle.angle);

      _particlePaint
        ..color = type.color.withOpacity(alpha)
        ..style = PaintingStyle.fill
        ..maskFilter = null;
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: shardLength, height: shardWidth),
        _particlePaint,
      );

      if (allowBlur) {
        _particlePaint
          ..color = type.color.withOpacity(alpha * 0.35)
          ..maskFilter = _blur(true, 2);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: shardLength * 1.4,
            height: shardWidth * 1.4,
          ),
          _particlePaint,
        );
      }
      canvas.restore();
    }

    // Data bits
    for (final bit in _dataBits) {
      if (!bit.isActive) continue;

      canvas.save();
      canvas.translate(bit.position.x, bit.position.y);
      canvas.rotate(bit.rotation);
      _particlePaint
        ..color = bit.color.withOpacity(bit.alpha)
        ..style = PaintingStyle.fill
        ..maskFilter = null;
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: bit.size, height: bit.size),
        _particlePaint,
      );
      
      if (allowBlur) {
        _particlePaint
          ..color = bit.color.withOpacity(bit.alpha * 0.5)
          ..maskFilter = _blur(true, 2);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: bit.size * 1.5, height: bit.size * 1.5),
          _particlePaint,
        );
      }
      canvas.restore();
    }
  }

  void _renderTrail(Canvas canvas, double opacity, bool allowBlur) {
    for (int i = 0; i < _trailPositions.length; i++) {
      final t = i / _trailPositions.length;
      final alpha = (1 - t) * 0.35 * opacity;

      // Calculate offset from current position
      final offset = _trailPositions[i] - position;
      if (offset.length < 0.5) continue;

      final angle = math.atan2(offset.y, offset.x);
      final streakLength = size.x * (0.55 - t * 0.3);
      final streakWidth = size.x * (0.08 - t * 0.04);

      _trailPaint
        ..color = type.color.withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = streakWidth
        ..strokeCap = StrokeCap.square
        ..maskFilter = _blur(allowBlur, 2);

      canvas.save();
      canvas.translate(offset.x, offset.y);
      canvas.rotate(angle);
      canvas.drawLine(Offset.zero, Offset(streakLength, 0), _trailPaint);
      canvas.restore();
    }
  }

  void _renderTypeEffects(Canvas canvas, double radius, double opacity, bool allowBlur) {
    final t = _animationTimer;

    // ═══════════════════════════════════════════════════════════════════════════
    // RENDER TERRIFYING EYES - All enemies have menacing eyes
    // ═══════════════════════════════════════════════════════════════════════════
    _renderDemonicEyes(canvas, radius, opacity, allowBlur);

    // ═══════════════════════════════════════════════════════════════════════════
    // RENDER CORRUPTION TENDRILS - Writhing appendages
    // ═══════════════════════════════════════════════════════════════════════════
    _renderCorruptionTendrils(canvas, radius, opacity, allowBlur);

    // ═══════════════════════════════════════════════════════════════════════════
    // WORLD-SPECIFIC TERROR EFFECTS
    // ═══════════════════════════════════════════════════════════════════════════
    _renderWorldTerrorEffects(canvas, radius, opacity, allowBlur, t);
  }

  void _renderDemonicEyes(Canvas canvas, double radius, double opacity, bool allowBlur) {
    final t = _animationTimer;
    final eyeStyle = _getEyeStyle();

    switch (eyeStyle) {
      case _EyeStyle.predator:
        // Single menacing eye that tracks and pulses
        _renderPredatorEye(canvas, radius, opacity, allowBlur, t);
        break;
      case _EyeStyle.hive:
        // Multiple small eyes like an insect
        _renderHiveEyes(canvas, radius, opacity, allowBlur, t);
        break;
      case _EyeStyle.void_:
        // Empty void sockets that draw you in
        _renderVoidEyes(canvas, radius, opacity, allowBlur, t);
        break;
      case _EyeStyle.burning:
        // Eyes of flame/plasma
        _renderBurningEyes(canvas, radius, opacity, allowBlur, t);
        break;
      case _EyeStyle.crystal:
        // Faceted crystalline eyes
        _renderCrystalEyes(canvas, radius, opacity, allowBlur, t);
        break;
      case _EyeStyle.mechanical:
        // Cold robotic sensors
        _renderMechanicalEyes(canvas, radius, opacity, allowBlur, t);
        break;
      case _EyeStyle.corrupted:
        // Glitching digital eyes
        _renderCorruptedEyes(canvas, radius, opacity, allowBlur, t);
        break;
      case _EyeStyle.abyssal:
        // Deep void eyes that seem infinite
        _renderAbyssalEyes(canvas, radius, opacity, allowBlur, t);
        break;
    }
  }

  _EyeStyle _getEyeStyle() {
    switch (type.world) {
      case 1: return _EyeStyle.predator;
      case 2: return _EyeStyle.void_;
      case 3: return _EyeStyle.corrupted;
      case 4: return _EyeStyle.burning;
      case 5: return _EyeStyle.crystal;
      case 6: return _EyeStyle.mechanical;
      case 7: return _EyeStyle.corrupted;
      case 8: return _EyeStyle.burning;
      case 9: return _EyeStyle.abyssal;
      case 10: return _EyeStyle.hive;
      default: return _EyeStyle.predator;
    }
  }

  void _renderPredatorEye(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Main eye socket - dark recess
    final socketPaint = Paint()
      ..color = Colors.black.withOpacity(0.8 * opacity);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(radius * 0.15, -radius * 0.1), width: radius * 0.5, height: radius * 0.35),
      socketPaint,
    );

    // Glowing iris - pulsing menacingly
    final pulse = 0.7 + 0.3 * math.sin(t * 4);
    final irisPaint = Paint()
      ..color = type.color.withOpacity(0.9 * opacity * pulse)
      ..maskFilter = _blur(allowBlur, 4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(radius * 0.15, -radius * 0.1), width: radius * 0.35, height: radius * 0.25),
      irisPaint,
    );

    // Slit pupil - vertical and menacing
    final pupilPaint = Paint()..color = Colors.black.withOpacity(0.95 * opacity);
    final pupilWidth = radius * 0.06 * (0.8 + 0.4 * math.sin(t * 2)); // Dilating
    canvas.drawOval(
      Rect.fromCenter(center: Offset(radius * 0.15, -radius * 0.1), width: pupilWidth, height: radius * 0.2),
      pupilPaint,
    );

    // Evil glint
    canvas.drawCircle(
      Offset(radius * 0.08, -radius * 0.18),
      radius * 0.04,
      Paint()..color = Colors.white.withOpacity(0.8 * opacity),
    );

    // Blood vessel streaks around eye
    final veinPaint = Paint()
      ..color = const Color(0xFFFF0033).withOpacity(0.4 * opacity)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 4; i++) {
      final angle = -math.pi / 4 + i * 0.3 + math.sin(t * 2 + i) * 0.1;
      final startX = radius * 0.15 + math.cos(angle) * radius * 0.2;
      final startY = -radius * 0.1 + math.sin(angle) * radius * 0.15;
      final endX = startX + math.cos(angle) * radius * 0.15;
      final endY = startY + math.sin(angle) * radius * 0.1;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), veinPaint);
    }
  }

  void _renderHiveEyes(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Multiple compound eyes like an insect nightmare
    final eyePositions = [
      Offset(radius * 0.25, -radius * 0.15),
      Offset(radius * 0.1, -radius * 0.25),
      Offset(-radius * 0.05, -radius * 0.2),
      Offset(radius * 0.3, 0),
      Offset(radius * 0.15, radius * 0.1),
      Offset(-radius * 0.1, radius * 0.05),
    ];

    for (int i = 0; i < eyePositions.length; i++) {
      final pos = eyePositions[i];
      final phase = t * 3 + i * 0.5;
      final active = math.sin(phase) > -0.3;
      final size = radius * (0.08 + 0.02 * math.sin(phase * 2));

      // Eye socket
      canvas.drawCircle(pos, size * 1.2, Paint()..color = Colors.black.withOpacity(0.7 * opacity));

      if (active) {
        // Glowing eye
        canvas.drawCircle(
          pos,
          size,
          Paint()
            ..color = type.color.withOpacity(0.8 * opacity)
            ..maskFilter = _blur(allowBlur, 3),
        );
        // Tiny pupil
        canvas.drawCircle(pos, size * 0.3, Paint()..color = Colors.black.withOpacity(0.9 * opacity));
      }
    }
  }

  void _renderVoidEyes(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Empty sockets that seem to go forever
    final socketPositions = [
      Offset(radius * 0.2, -radius * 0.15),
      Offset(-radius * 0.15, -radius * 0.1),
    ];

    for (final pos in socketPositions) {
      // Deep black void
      final voidGradient = RadialGradient(
        colors: [
          Colors.black.withOpacity(0.95 * opacity),
          Colors.black.withOpacity(0.7 * opacity),
          type.color.withOpacity(0.2 * opacity),
        ],
        stops: const [0.0, 0.6, 1.0],
      );

      canvas.drawCircle(
        pos,
        radius * 0.15,
        Paint()..shader = voidGradient.createShader(Rect.fromCircle(center: pos, radius: radius * 0.15)),
      );

      // Swirling darkness inside
      final swirlPaint = Paint()
        ..color = type.color.withOpacity(0.3 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawArc(
        Rect.fromCircle(center: pos, radius: radius * 0.08),
        t * 2,
        math.pi,
        false,
        swirlPaint,
      );

      // Occasional glimmer from the depths
      if (math.sin(t * 5) > 0.8) {
        canvas.drawCircle(
          pos + Offset(math.sin(t * 3) * radius * 0.03, math.cos(t * 3) * radius * 0.03),
          radius * 0.02,
          Paint()..color = type.color.withOpacity(0.6 * opacity),
        );
      }
    }
  }

  void _renderBurningEyes(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Eyes of pure fire/plasma
    final eyePos = Offset(radius * 0.15, -radius * 0.1);
    final flameColors = [
      const Color(0xFFFFFF00),
      type.color,
      const Color(0xFFFF3300),
      const Color(0xFF660000),
    ];

    // Flame aura around eye
    for (int i = 3; i >= 0; i--) {
      final flameSize = radius * (0.2 + i * 0.05);
      final jitter = Offset(
        math.sin(t * 10 + i) * radius * 0.02,
        math.cos(t * 12 + i) * radius * 0.02 - i * radius * 0.02,
      );
      canvas.drawOval(
        Rect.fromCenter(center: eyePos + jitter, width: flameSize * 1.5, height: flameSize),
        Paint()
          ..color = flameColors[i].withOpacity((0.3 + i * 0.15) * opacity)
          ..maskFilter = _blur(allowBlur, 4 + i * 2),
      );
    }

    // Core of the eye - white hot
    canvas.drawCircle(
      eyePos,
      radius * 0.08,
      Paint()..color = Colors.white.withOpacity(0.9 * opacity),
    );

    // Flame licks rising from eye
    final flamePaint = Paint()
      ..color = const Color(0xFFFF6600).withOpacity(0.6 * opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final x = eyePos.dx + (i - 1) * radius * 0.08;
      final height = radius * (0.15 + 0.1 * math.sin(t * 8 + i * 2));
      canvas.drawLine(
        Offset(x, eyePos.dy - radius * 0.1),
        Offset(x + math.sin(t * 6 + i) * radius * 0.05, eyePos.dy - radius * 0.1 - height),
        flamePaint,
      );
    }
  }

  void _renderCrystalEyes(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Faceted gem-like eyes
    final eyePos = Offset(radius * 0.12, -radius * 0.1);

    // Outer facets
    _reusableOverlayPath.reset();
    const facets = 6;
    for (int i = 0; i < facets; i++) {
      final angle = (i / facets) * math.pi * 2 + t * 0.5;
      final r = radius * 0.18;
      final x = eyePos.dx + math.cos(angle) * r;
      final y = eyePos.dy + math.sin(angle) * r;
      if (i == 0) _reusableOverlayPath.moveTo(x, y);
      else _reusableOverlayPath.lineTo(x, y);
    }
    _reusableOverlayPath.close();

    // Fill with gradient
    canvas.drawPath(
      _reusableOverlayPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9 * opacity),
            type.color.withOpacity(0.7 * opacity),
            type.color.withOpacity(0.3 * opacity),
          ],
        ).createShader(Rect.fromCenter(center: eyePos, width: radius * 0.4, height: radius * 0.4)),
    );

    // Facet lines
    final facetPaint = Paint()
      ..color = Colors.white.withOpacity(0.6 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int i = 0; i < facets; i++) {
      final angle = (i / facets) * math.pi * 2 + t * 0.5;
      canvas.drawLine(
        eyePos,
        eyePos + Offset(math.cos(angle) * radius * 0.15, math.sin(angle) * radius * 0.15),
        facetPaint,
      );
    }

    // Central gleam
    canvas.drawCircle(
      eyePos + Offset(-radius * 0.04, -radius * 0.04),
      radius * 0.03,
      Paint()..color = Colors.white.withOpacity(0.95 * opacity),
    );

    // Prismatic refraction
    if (allowBlur) {
      for (int i = 0; i < 3; i++) {
        final angle = t * 2 + i * math.pi * 2 / 3;
        final color = [const Color(0xFFFF0000), const Color(0xFF00FF00), const Color(0xFF0000FF)][i];
        canvas.drawLine(
          eyePos,
          eyePos + Offset(math.cos(angle) * radius * 0.25, math.sin(angle) * radius * 0.25),
          Paint()
            ..color = color.withOpacity(0.2 * opacity)
            ..strokeWidth = 2
            ..maskFilter = _blur(true, 4),
        );
      }
    }
  }

  void _renderMechanicalEyes(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Cold robotic sensor eye
    final eyePos = Offset(radius * 0.15, -radius * 0.08);

    // Metal housing
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: eyePos, width: radius * 0.4, height: radius * 0.25),
        Radius.circular(radius * 0.04),
      ),
      Paint()..color = const Color(0xFF333333).withOpacity(0.9 * opacity),
    );

    // Lens
    canvas.drawCircle(
      eyePos,
      radius * 0.1,
      Paint()..color = Colors.black.withOpacity(0.95 * opacity),
    );

    // Scanning laser
    final scanAngle = (t * 3) % (math.pi * 2);
    final scanPaint = Paint()
      ..color = const Color(0xFFFF0000).withOpacity(0.8 * opacity)
      ..strokeWidth = 2
      ..maskFilter = _blur(allowBlur, 3);
    canvas.drawLine(
      eyePos,
      eyePos + Offset(math.cos(scanAngle) * radius * 0.08, math.sin(scanAngle) * radius * 0.08),
      scanPaint,
    );

    // LED indicators
    for (int i = 0; i < 3; i++) {
      final ledOn = ((t * 4 + i).floor() % 3) == i;
      canvas.drawCircle(
        eyePos + Offset(radius * (-0.12 + i * 0.12), radius * 0.15),
        radius * 0.02,
        Paint()..color = (ledOn ? type.color : const Color(0xFF333333)).withOpacity(0.8 * opacity),
      );
    }

    // Targeting reticle
    final reticlePaint = Paint()
      ..color = type.color.withOpacity(0.5 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(eyePos, radius * 0.06, reticlePaint);
    canvas.drawLine(eyePos + Offset(-radius * 0.1, 0), eyePos + Offset(-radius * 0.03, 0), reticlePaint);
    canvas.drawLine(eyePos + Offset(radius * 0.03, 0), eyePos + Offset(radius * 0.1, 0), reticlePaint);
    canvas.drawLine(eyePos + Offset(0, -radius * 0.08), eyePos + Offset(0, -radius * 0.03), reticlePaint);
    canvas.drawLine(eyePos + Offset(0, radius * 0.03), eyePos + Offset(0, radius * 0.08), reticlePaint);
  }

  void _renderCorruptedEyes(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Glitching digital eyes
    final eyePos = Offset(radius * 0.15, -radius * 0.1);
    final glitchOffset = Offset(
      math.sin(t * 30) > 0.8 ? (math.sin(t * 50) * radius * 0.1) : 0,
      math.cos(t * 25) > 0.8 ? (math.cos(t * 45) * radius * 0.05) : 0,
    );

    // Chromatic aberration - RGB split
    canvas.drawCircle(
      eyePos + glitchOffset + Offset(-radius * 0.02, 0),
      radius * 0.12,
      Paint()..color = const Color(0xFFFF0000).withOpacity(0.4 * opacity),
    );
    canvas.drawCircle(
      eyePos + glitchOffset + Offset(radius * 0.02, 0),
      radius * 0.12,
      Paint()..color = const Color(0xFF00FFFF).withOpacity(0.4 * opacity),
    );

    // Main eye with corruption
    canvas.drawCircle(
      eyePos + glitchOffset,
      radius * 0.1,
      Paint()..color = type.color.withOpacity(0.8 * opacity),
    );

    // Glitch bars
    if (math.sin(t * 15) > 0.6) {
      final barPaint = Paint()..color = type.color.withOpacity(0.6 * opacity);
      for (int i = 0; i < 3; i++) {
        final y = eyePos.dy - radius * 0.15 + i * radius * 0.1;
        final width = radius * (0.1 + _random.nextDouble() * 0.2);
        canvas.drawRect(
          Rect.fromLTWH(eyePos.dx - width / 2, y, width, radius * 0.02),
          barPaint,
        );
      }
    }

    // Error pupil - sometimes inverted
    final inverted = math.sin(t * 8) > 0.7;
    canvas.drawCircle(
      eyePos + glitchOffset,
      radius * 0.04,
      Paint()..color = (inverted ? type.color : Colors.black).withOpacity(0.9 * opacity),
    );
  }

  void _renderAbyssalEyes(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Infinite depth void eyes
    final eyePositions = [
      Offset(radius * 0.18, -radius * 0.12),
      Offset(-radius * 0.12, -radius * 0.08),
    ];

    for (int e = 0; e < eyePositions.length; e++) {
      final pos = eyePositions[e];

      // Concentric rings going into infinity
      for (int i = 4; i >= 0; i--) {
        final ringRadius = radius * (0.15 - i * 0.025);
        final darkness = 0.5 + i * 0.1;
        canvas.drawCircle(
          pos,
          ringRadius,
          Paint()
            ..color = Color.lerp(type.color, Colors.black, darkness)!.withOpacity(0.8 * opacity),
        );
      }

      // Swirling abyss
      final swirlPaint = Paint()
        ..color = type.color.withOpacity(0.3 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (int i = 0; i < 3; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: pos, radius: radius * (0.05 + i * 0.03)),
          t * 3 + i * math.pi / 3,
          math.pi * 0.8,
          false,
          swirlPaint,
        );
      }

      // Occasional soul escaping
      if ((t * 2 + e).floor() % 3 == 0) {
        final soulY = pos.dy - (t % 1.0) * radius * 0.3;
        canvas.drawCircle(
          Offset(pos.dx, soulY),
          radius * 0.015,
          Paint()
            ..color = Colors.white.withOpacity((1 - (t % 1.0)) * 0.5 * opacity)
            ..maskFilter = _blur(allowBlur, 2),
        );
      }
    }
  }

  void _renderCorruptionTendrils(Canvas canvas, double radius, double opacity, bool allowBlur) {
    // Skip for low-fx mode
    if (Enemy.lowFx || Enemy.forceLowFx) return;

    final t = _animationTimer;
    final tendrilCount = type.world >= 5 ? 6 : 4;
    final tendrilLength = radius * (0.8 + type.world * 0.1);

    final tendrilPaint = Paint()
      ..color = type.color.withOpacity(0.5 * opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < tendrilCount; i++) {
      final baseAngle = (i / tendrilCount) * math.pi * 2 + t * 0.5;
      final segments = 5;

      _reusableOverlayPath.reset();
      var currentPos = Offset.zero;
      _reusableOverlayPath.moveTo(0, 0);

      for (int s = 0; s < segments; s++) {
        final segProgress = s / segments;
        final wave = math.sin(t * 4 + i * 0.8 + s * 0.5) * radius * 0.15 * segProgress;
        final segLength = tendrilLength / segments;
        final angle = baseAngle + wave * 0.1;

        currentPos = currentPos + Offset(
          math.cos(angle) * segLength,
          math.sin(angle) * segLength + wave * 0.3,
        );
        _reusableOverlayPath.lineTo(currentPos.dx, currentPos.dy);
      }

      // Main tendril
      canvas.drawPath(_reusableOverlayPath, tendrilPaint);

      // Glow effect
      if (allowBlur) {
        canvas.drawPath(
          _reusableOverlayPath,
          Paint()
            ..color = type.color.withOpacity(0.2 * opacity)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke
            ..maskFilter = _blur(true, 4),
        );
      }

      // Tendril tip - barb or claw
      canvas.save();
      canvas.translate(currentPos.dx, currentPos.dy);
      canvas.rotate(baseAngle);

      // Sharp claw
      _reusableOverlayPath.reset();
      _reusableOverlayPath.moveTo(0, -radius * 0.04);
      _reusableOverlayPath.lineTo(radius * 0.08, 0);
      _reusableOverlayPath.lineTo(0, radius * 0.04);
      _reusableOverlayPath.close();
      canvas.drawPath(
        _reusableOverlayPath,
        Paint()..color = Colors.white.withOpacity(0.7 * opacity),
      );
      canvas.restore();
    }
  }

  void _renderWorldTerrorEffects(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    switch (type.world) {
      case 1:
        _renderNeonTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 2:
        _renderRiftTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 3:
        _renderCorruptionTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 4:
        _renderPlasmaTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 5:
        _renderCrystalTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 6:
        _renderMechTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 7:
        _renderMatrixTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 8:
        _renderStormTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 9:
        _renderVoidTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 10:
        _renderOmegaTerror(canvas, radius, opacity, allowBlur, t);
        break;
    }
  }

  void _renderNeonTerror(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Neon blade and predator markings
    final bladePaint = Paint()..color = Colors.white.withOpacity(0.8 * opacity);
    _reusableOverlayPath.reset();
    _reusableOverlayPath.moveTo(radius * 0.9, 0);
    _reusableOverlayPath.lineTo(radius * 0.4, -radius * 0.15);
    _reusableOverlayPath.lineTo(radius * 0.4, radius * 0.15);
    _reusableOverlayPath.close();
    canvas.drawPath(_reusableOverlayPath, bladePaint);

    // War paint stripes
    final stripePaint = Paint()
      ..color = type.color.withOpacity(0.6 * opacity)
      ..strokeWidth = 2;
    for (int i = 0; i < 3; i++) {
      final y = -radius * 0.3 + i * radius * 0.15;
      canvas.drawLine(
        Offset(-radius * 0.3, y),
        Offset(-radius * 0.6, y + radius * 0.1),
        stripePaint,
      );
    }
  }

  void _renderRiftTerror(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Dimensional tears and reality fractures
    final tearPaint = Paint()
      ..color = const Color(0xFFFF00FF).withOpacity(0.5 * opacity)
      ..strokeWidth = 2
      ..maskFilter = _blur(allowBlur, 4);

    // Reality cracks
    for (int i = 0; i < 4; i++) {
      final angle = t * 2 + i * math.pi / 2;
      final len = radius * (0.6 + math.sin(t * 5 + i) * 0.2);
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(angle) * len, math.sin(angle) * len),
        tearPaint,
      );
    }

    // Dimensional portal behind
    if (allowBlur) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: radius * 1.5, height: radius * 0.5),
        Paint()
          ..color = const Color(0xFF6600FF).withOpacity(0.2 * opacity)
          ..maskFilter = _blur(true, 8),
      );
    }
  }

  void _renderCorruptionTerror(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Glitch corruption and data rot
    final corruptPaint = Paint()..color = const Color(0xFF00FF00).withOpacity(0.6 * opacity);

    // Corruption blocks
    for (int i = 0; i < 6; i++) {
      if (math.sin(t * 10 + i * 2) > 0.5) {
        final x = (i % 3 - 1) * radius * 0.3;
        final y = (i ~/ 3 - 0.5) * radius * 0.4;
        canvas.drawRect(
          Rect.fromLTWH(x, y, radius * 0.15, radius * 0.08),
          corruptPaint,
        );
      }
    }

    // Error text simulation
    final errorPaint = Paint()
      ..color = const Color(0xFFFF0000).withOpacity(0.4 * opacity)
      ..strokeWidth = 1;
    if (math.sin(t * 8) > 0.7) {
      for (int i = 0; i < 4; i++) {
        final y = -radius * 0.4 + i * radius * 0.2;
        canvas.drawLine(
          Offset(-radius * 0.4, y),
          Offset(-radius * 0.4 + _random.nextDouble() * radius * 0.5, y),
          errorPaint,
        );
      }
    }
  }

  void _renderPlasmaTerror(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Electric arcs and plasma discharge
    final arcPaint = Paint()
      ..color = type.color.withOpacity(0.7 * opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      if (math.sin(t * 12 + i * 1.5) > 0.4) {
        final angle = (i / 5) * math.pi * 2 + t;
        final startR = radius * 0.4;
        final endR = radius * (0.9 + _random.nextDouble() * 0.3);

        // Jagged lightning
        final start = Offset(math.cos(angle) * startR, math.sin(angle) * startR);
        final mid = Offset(
          math.cos(angle + 0.2) * (startR + endR) / 2 + _random.nextDouble() * radius * 0.2,
          math.sin(angle + 0.2) * (startR + endR) / 2 + _random.nextDouble() * radius * 0.2,
        );
        final end = Offset(math.cos(angle) * endR, math.sin(angle) * endR);

        canvas.drawLine(start, mid, arcPaint);
        canvas.drawLine(mid, end, arcPaint);

        if (allowBlur) {
          arcPaint.maskFilter = _blur(true, 4);
          canvas.drawLine(start, mid, arcPaint..color = type.color.withOpacity(0.3 * opacity));
          arcPaint.maskFilter = null;
        }
      }
    }
  }

  void _renderCrystalTerror(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Floating crystal shards
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * math.pi * 2 + t * 0.8;
      final dist = radius * (1.0 + math.sin(t * 2 + i) * 0.15);
      final pos = Offset(math.cos(angle) * dist, math.sin(angle) * dist);
      final size = radius * (0.1 + 0.03 * math.sin(t * 3 + i));

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle + t);

      // Crystal shard
      _reusableOverlayPath.reset();
      _reusableOverlayPath.moveTo(0, -size);
      _reusableOverlayPath.lineTo(size * 0.5, 0);
      _reusableOverlayPath.lineTo(0, size);
      _reusableOverlayPath.lineTo(-size * 0.5, 0);
      _reusableOverlayPath.close();

      canvas.drawPath(
        _reusableOverlayPath,
        Paint()..color = type.color.withOpacity(0.6 * opacity),
      );
      canvas.drawPath(
        _reusableOverlayPath,
        Paint()
          ..color = Colors.white.withOpacity(0.4 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.restore();
    }
  }

  void _renderMechTerror(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Mechanical gears and warning lights
    // Rotating gear
    canvas.save();
    canvas.rotate(t * 2);
    final gearPaint = Paint()
      ..color = const Color(0xFF666666).withOpacity(0.5 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const teeth = 8;
    for (int i = 0; i < teeth; i++) {
      final angle = (i / teeth) * math.pi * 2;
      canvas.drawLine(
        Offset(math.cos(angle) * radius * 0.6, math.sin(angle) * radius * 0.6),
        Offset(math.cos(angle) * radius * 0.75, math.sin(angle) * radius * 0.75),
        gearPaint,
      );
    }
    canvas.restore();

    // Warning stripes
    final warnPaint = Paint()
      ..color = const Color(0xFFFFCC00).withOpacity(math.sin(t * 8) > 0 ? 0.6 : 0.2 * opacity);
    for (int i = 0; i < 3; i++) {
      final x = -radius * 0.4 + i * radius * 0.2;
      canvas.drawRect(
        Rect.fromLTWH(x, radius * 0.5, radius * 0.1, radius * 0.15),
        warnPaint,
      );
    }
  }

  void _renderMatrixTerror(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Matrix code rain
    final codePaint = Paint()..color = const Color(0xFF00FF00).withOpacity(0.5 * opacity);
    for (int i = 0; i < 6; i++) {
      final x = -radius * 0.6 + i * radius * 0.25;
      final yOffset = ((t * 3 + i * 0.4) % 2.0) * radius;
      for (int j = 0; j < 4; j++) {
        final y = -radius + yOffset + j * radius * 0.15;
        if (y > -radius && y < radius) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, radius * 0.08, radius * 0.06),
            codePaint..color = const Color(0xFF00FF00).withOpacity((0.3 + j * 0.15) * opacity),
          );
        }
      }
    }
  }

  void _renderStormTerror(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Storm clouds and lightning
    // Swirling cloud
    for (int i = 0; i < 3; i++) {
      final cloudAngle = t * (3 + i * 0.5);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius * (0.8 + i * 0.1)),
        cloudAngle,
        math.pi * 0.6,
        false,
        Paint()
          ..color = const Color(0xFF336699).withOpacity(0.3 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = _blur(allowBlur, 4),
      );
    }

    // Lightning flash
    if (math.sin(t * 15) > 0.9) {
      canvas.drawCircle(
        Offset.zero,
        radius * 1.2,
        Paint()
          ..color = Colors.white.withOpacity(0.3 * opacity)
          ..maskFilter = _blur(allowBlur, 10),
      );
    }
  }

  void _renderVoidTerror(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Consuming darkness and soul drain
    // Darkness tendrils reaching inward
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 + t * 0.3;
      final startR = radius * 1.3;
      final endR = radius * 0.3;
      final progress = (math.sin(t * 2 + i) + 1) / 2;
      final currentR = startR - (startR - endR) * progress;

      canvas.drawCircle(
        Offset(math.cos(angle) * currentR, math.sin(angle) * currentR),
        radius * 0.05,
        Paint()
          ..color = type.color.withOpacity(0.4 * opacity)
          ..maskFilter = _blur(allowBlur, 3),
      );
    }

    // Central void
    canvas.drawCircle(
      Offset.zero,
      radius * 0.25,
      Paint()
        ..color = Colors.black.withOpacity(0.7 * opacity)
        ..maskFilter = _blur(allowBlur, 5),
    );
  }

  void _renderOmegaTerror(Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Ultimate terror - all effects combined
    // Omega symbol aura
    final omegaPaint = Paint()
      ..color = type.color.withOpacity(0.6 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = _blur(allowBlur, 4);

    // Rotating energy rings
    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.rotate(t * (2 + i) * (i.isEven ? 1 : -1));
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: radius * (1.2 + i * 0.15), height: radius * (0.6 + i * 0.1)),
        omegaPaint,
      );
      canvas.restore();
    }

    // Reality distortion waves
    for (int i = 0; i < 4; i++) {
      final waveR = radius * (0.8 + ((t * 2 + i * 0.5) % 1.0) * 0.5);
      canvas.drawCircle(
        Offset.zero,
        waveR,
        Paint()
          ..color = type.color.withOpacity((1 - ((t * 2 + i * 0.5) % 1.0)) * 0.3 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Apocalyptic flames at top
    for (int i = 0; i < 5; i++) {
      final flameX = (i - 2) * radius * 0.2;
      final flameH = radius * (0.3 + math.sin(t * 8 + i) * 0.1);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(flameX, -radius * 0.7 - flameH / 2),
          width: radius * 0.12,
          height: flameH,
        ),
        Paint()
          ..color = const Color(0xFFFF3300).withOpacity(0.5 * opacity)
          ..maskFilter = _blur(allowBlur, 4),
      );
    }
  }

  void _renderCorruptionAura(Canvas canvas, double radius, double opacity, bool allowBlur) {
    final corruption =
        ((1 - healthPercent) * 0.7 + threatTier * 0.08 + (isPhantom ? 0.2 : 0.0))
            .clamp(0.2, 1.0);
    final pulse = 0.6 + math.sin(_animationTimer * 8) * 0.2;
    final intensity = (corruption * pulse).clamp(0.2, 1.0);
    final auraColor =
        Color.lerp(type.color, const Color(0xFFFF005A), 0.45 + corruption * 0.3)!;

    final bracePaint = Paint()
      ..color = auraColor.withOpacity(0.28 * opacity * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.square
      ..maskFilter = _blur(allowBlur, 3);
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 + _animationTimer * 0.4;
      final dist = radius * (1.1 + i * 0.03);
      final x = math.cos(angle) * dist;
      final y = math.sin(angle) * dist;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawLine(
        Offset(-radius * 0.12, 0),
        Offset(radius * 0.12, 0),
        bracePaint,
      );
      canvas.restore();
    }

    final spikeCount = 6 + (corruption * 6).round();
    final spikePaint = Paint()
      ..color = auraColor.withOpacity(0.35 * opacity * intensity)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.square;
    for (int i = 0; i < spikeCount; i++) {
      final angle = (i / spikeCount) * math.pi * 2 + _animationTimer * 0.7;
      final inner = radius * 1.02;
      final outer = radius * (1.25 + 0.15 * math.sin(_animationTimer * 5 + i));
      canvas.drawLine(
        Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        spikePaint,
      );
    }
  }

  void _renderGlitchOverlay(Canvas canvas, double radius, double opacity, bool allowBlur) {
    final rand = _visualRandom;
    final hpFactor = 1 - healthPercent;
    final baseIntensity =
        (0.45 + hpFactor * 0.75 + threatTier * 0.1 + (isPhantom ? 0.25 : 0.0))
            .clamp(0.4, 1.0);
    final pulse = (math.sin(_animationTimer * 12) + 1) / 2;
    final intensity = (baseIntensity * (0.7 + pulse * 0.6)).clamp(0.3, 1.0);
    final trigger = rand.nextDouble() < (0.35 + baseIntensity * 0.4);
    if (!trigger) return;

    final glitchColor =
        Color.lerp(type.color, const Color(0xFFFF004C), 0.6)!;
    final scanColor =
        Color.lerp(type.color, const Color(0xFF33CCFF), 0.55)!;

    final bodyPath = _createBodyPath(radius);
    final offset = (math.sin(_animationTimer * 20) * 0.6 +
            (rand.nextDouble() - 0.5) * 0.5) *
        intensity;

    final chromaPaintA = Paint()
      ..color = const Color(0xFFFF3355).withOpacity(0.25 * opacity * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final chromaPaintB = Paint()
      ..color = const Color(0xFF33CCFF).withOpacity(0.22 * opacity * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    if (allowBlur) {
      chromaPaintA.maskFilter = _blur(true, 2);
      chromaPaintB.maskFilter = _blur(true, 2);
    }

    canvas.save();
    canvas.translate(-offset, 0);
    canvas.drawPath(bodyPath, chromaPaintA);
    canvas.restore();
    canvas.save();
    canvas.translate(offset, 0);
    canvas.drawPath(bodyPath, chromaPaintB);
    canvas.restore();

    canvas.save();
    canvas.clipPath(bodyPath);

    final slicePaint = Paint()
      ..color = glitchColor.withOpacity(0.18 * opacity * intensity);
    if (allowBlur) {
      slicePaint.maskFilter = _blur(true, 2);
    }
    final scanPaint = Paint()
      ..color = scanColor.withOpacity(0.12 * opacity * intensity)
      ..strokeWidth = 1.0;
    final sliceCount = 3 + (baseIntensity * 3).round();
    for (int i = 0; i < sliceCount; i++) {
      final sliceH = radius * (0.08 + rand.nextDouble() * 0.14);
      final y = (rand.nextDouble() - 0.5) * radius * 1.6;
      final xShift = (rand.nextDouble() - 0.5) * radius * 0.35 * intensity;
      canvas.drawRect(
        Rect.fromLTWH(-radius * 1.4 + xShift, y, radius * 2.8, sliceH),
        slicePaint,
      );
    }

    final tearCount = 1 + (baseIntensity * 1.5).round();
    for (int i = 0; i < tearCount; i++) {
      final tearH = radius * (0.1 + rand.nextDouble() * 0.2);
      final tearY = (rand.nextDouble() - 0.5) * radius * 1.4;
      final tearOffset = (rand.nextDouble() - 0.5) * radius * 0.3 * intensity;
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(-radius * 1.4, tearY, radius * 2.8, tearH));
      canvas.translate(tearOffset, 0);
      _auraPaint
        ..color = glitchColor.withOpacity(0.22 * opacity * intensity)
        ..style = PaintingStyle.fill
        ..maskFilter = _blur(allowBlur, 2);
      canvas.drawPath(bodyPath, _auraPaint);
      canvas.restore();
    }

    for (int i = 0; i < 4; i++) {
      final y = -radius + (radius * 2) * ((pulse * 0.6 + i / 4) % 1.0);
      canvas.drawLine(Offset(-radius * 1.2, y), Offset(radius * 1.2, y), scanPaint);
    }
    canvas.restore();

    final shardPaint = Paint()
      ..color = glitchColor.withOpacity(0.5 * opacity * intensity);
    for (int i = 0; i < 4; i++) {
      final bx = (rand.nextDouble() - 0.5) * radius * 2.4;
      final by = (rand.nextDouble() - 0.5) * radius * 2.4;
      final w = 2 + rand.nextDouble() * 3;
      canvas.drawRect(Rect.fromLTWH(bx, by, w, 1.5), shardPaint);
    }
  }

  void _applyWorldVisuals(Canvas canvas) {
    canvas.save();
    
    final t = _animationTimer;

    switch (worldIndex) {
      case 2: // Rift Wars - Glitch style
        final pulse = math.sin(t * 8 + _circuitSeed * 12);
        if (pulse > 0.6) {
          final shiftX = math.sin(t * 21 + _circuitSeed * 9) * 2.2;
          final shiftY = math.cos(t * 17 + _circuitSeed * 5) * 1.4;
          canvas.translate(shiftX, shiftY);
        }
        break;
      case 3: // Signal Wastes - Noise/Static
        if (math.sin(t * 20 + _circuitSeed * 2) > 0.8) {
          canvas.skew(0.05 * math.sin(t * 30 + _circuitSeed * 3), 0);
        }
        break;
      case 4: // Ion Crown - Arc/Electrical jitter
        final jitter = math.sin(t * 40 + _circuitSeed * 4) * 0.8;
        canvas.translate(jitter, jitter);
        break;
      case 5: // Shard Vault - Sharp Jumps
        if ((t * 2).toInt() % 2 == 0) {
           canvas.scale(1.02);
        }
        break;
      default:
        // Neon Frontier - Standard
        break;
    }
  }

  void _drawInternalCircuitry(Canvas canvas, double radius, double opacity) {
    if (Enemy.lowFx || Enemy.forceLowFx) return;
    
    _circuitPaint
      ..color = type.color.withOpacity(0.2 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final pulse = 0.5 + math.sin(_animationTimer * 3) * 0.5;
    _circuitPaint.color =
        _circuitPaint.color.withOpacity(0.1 * opacity + 0.15 * pulse * opacity);
    _particlePaint
      ..color = _circuitPaint.color
      ..style = PaintingStyle.fill;

    for (final segment in _circuitSegments) {
      final start = Offset(segment.start.dx * radius, segment.start.dy * radius);
      final end = Offset(segment.end.dx * radius, segment.end.dy * radius);
      canvas.drawLine(start, end, _circuitPaint);
      const dotSize = 1.6;
      canvas.drawRect(
        Rect.fromCenter(center: start, width: dotSize, height: dotSize),
        _particlePaint,
      );
    }
  }

  Path _createBodyPath(double radius) {
    // Reuse static path to avoid allocations
    _reusableBodyPath.reset();

    // Get shape category based on enemy type
    final shape = _getBodyShape();

    switch (shape) {
      case _BodyShape.dart:
        // Aerodynamic dart hull (runners, fast types)
        _reusableBodyPath.moveTo(radius * 1.05, 0);
        _reusableBodyPath.lineTo(radius * 0.3, -radius * 0.65);
        _reusableBodyPath.lineTo(-radius * 0.45, -radius * 0.45);
        _reusableBodyPath.lineTo(-radius * 0.85, 0);
        _reusableBodyPath.lineTo(-radius * 0.45, radius * 0.45);
        _reusableBodyPath.lineTo(radius * 0.3, radius * 0.65);
        break;

      case _BodyShape.fractured:
        // Fractured polygon (overloaded, glitchy types)
        final shift = math.sin(_animationTimer * 6) * radius * 0.12;
        final glitch = math.cos(_animationTimer * 4) * radius * 0.08;
        _reusableBodyPath.moveTo(radius * 0.8 + shift, -radius * 0.15);
        _reusableBodyPath.lineTo(radius * 0.2, -radius * 0.85);
        _reusableBodyPath.lineTo(-radius * 0.6, -radius * 0.55 + glitch);
        _reusableBodyPath.lineTo(-radius * 0.9, 0);
        _reusableBodyPath.lineTo(-radius * 0.5, radius * 0.7);
        _reusableBodyPath.lineTo(radius * 0.25, radius * 0.55 - shift);
        _reusableBodyPath.lineTo(radius * 0.9 + glitch, radius * 0.12);
        break;

      case _BodyShape.armored:
        // Beveled armored hull (tanks, heavy types)
        final inset = radius * 0.35;
        _reusableBodyPath.moveTo(radius, -inset);
        _reusableBodyPath.lineTo(radius * 0.65, -radius);
        _reusableBodyPath.lineTo(-radius * 0.65, -radius);
        _reusableBodyPath.lineTo(-radius, -inset);
        _reusableBodyPath.lineTo(-radius, inset);
        _reusableBodyPath.lineTo(-radius * 0.65, radius);
        _reusableBodyPath.lineTo(radius * 0.65, radius);
        _reusableBodyPath.lineTo(radius, inset);
        break;

      case _BodyShape.star:
        // Phase-shifted star (phantom, spectral types)
        const points = 6;
        for (int i = 0; i < points * 2; i++) {
          final wobble = math.sin(_animationTimer * 3 + i) * radius * 0.06;
          final r = i.isEven ? radius * 0.9 + wobble : radius * 0.55 + wobble;
          final angle = i * math.pi / points + _animationTimer * 1.6;
          final x = math.cos(angle) * r;
          final y = math.sin(angle) * r;
          if (i == 0) _reusableBodyPath.moveTo(x, y);
          else _reusableBodyPath.lineTo(x, y);
        }
        break;

      case _BodyShape.hexagon:
        // Hexagonal (crystal, gem types)
        for (int i = 0; i < 6; i++) {
          final angle = (i / 6) * math.pi * 2 - math.pi / 6;
          final pulse = 1.0 + math.sin(_animationTimer * 2 + i) * 0.05;
          final x = math.cos(angle) * radius * pulse;
          final y = math.sin(angle) * radius * pulse;
          if (i == 0) _reusableBodyPath.moveTo(x, y);
          else _reusableBodyPath.lineTo(x, y);
        }
        break;

      case _BodyShape.mechanical:
        // Mechanical box (robots, mechs)
        final pulse = math.sin(_animationTimer * 4) * radius * 0.03;
        _reusableBodyPath.moveTo(radius * 0.9 + pulse, -radius * 0.5);
        _reusableBodyPath.lineTo(radius * 0.5, -radius * 0.9);
        _reusableBodyPath.lineTo(-radius * 0.5, -radius * 0.9);
        _reusableBodyPath.lineTo(-radius * 0.9 - pulse, -radius * 0.5);
        _reusableBodyPath.lineTo(-radius * 0.9 - pulse, radius * 0.5);
        _reusableBodyPath.lineTo(-radius * 0.5, radius * 0.9);
        _reusableBodyPath.lineTo(radius * 0.5, radius * 0.9);
        _reusableBodyPath.lineTo(radius * 0.9 + pulse, radius * 0.5);
        break;

      case _BodyShape.electric:
        // Spiky electric (plasma, electric types)
        const spikes = 8;
        for (int i = 0; i < spikes * 2; i++) {
          final angle = (i / (spikes * 2)) * math.pi * 2;
          final jitter = math.sin(_animationTimer * 12 + i * 0.5) * radius * 0.08;
          final r = i.isEven ? radius * 0.95 + jitter : radius * 0.6;
          final x = math.cos(angle) * r;
          final y = math.sin(angle) * r;
          if (i == 0) _reusableBodyPath.moveTo(x, y);
          else _reusableBodyPath.lineTo(x, y);
        }
        break;

      case _BodyShape.storm:
        // Swirling storm shape
        const spiralPoints = 12;
        for (int i = 0; i < spiralPoints; i++) {
          final angle = (i / spiralPoints) * math.pi * 2 + _animationTimer * 2;
          final wobble = math.sin(_animationTimer * 4 + i) * radius * 0.1;
          final r = radius * (0.7 + (i % 2) * 0.25) + wobble;
          final x = math.cos(angle) * r;
          final y = math.sin(angle) * r;
          if (i == 0) _reusableBodyPath.moveTo(x, y);
          else _reusableBodyPath.lineTo(x, y);
        }
        break;

      case _BodyShape.void_:
        // Void/abyss - irregular dark shape
        const voidPoints = 7;
        for (int i = 0; i < voidPoints; i++) {
          final angle = (i / voidPoints) * math.pi * 2;
          final pulse = math.sin(_animationTimer * 1.5 + i * 0.8) * radius * 0.15;
          final r = radius * (0.75 + (i % 2) * 0.2) + pulse;
          final x = math.cos(angle) * r;
          final y = math.sin(angle) * r;
          if (i == 0) _reusableBodyPath.moveTo(x, y);
          else _reusableBodyPath.lineTo(x, y);
        }
        break;

      case _BodyShape.omega:
        // Ultimate omega shape - complex polygon
        const omegaPoints = 10;
        for (int i = 0; i < omegaPoints; i++) {
          final angle = (i / omegaPoints) * math.pi * 2;
          final layer = (i % 3 == 0) ? 1.0 : (i % 3 == 1) ? 0.8 : 0.9;
          final pulse = math.sin(_animationTimer * 3 + i) * radius * 0.08;
          final r = radius * layer + pulse;
          final x = math.cos(angle) * r;
          final y = math.sin(angle) * r;
          if (i == 0) _reusableBodyPath.moveTo(x, y);
          else _reusableBodyPath.lineTo(x, y);
        }
        break;
    }
    _reusableBodyPath.close();
    return _reusableBodyPath;
  }

  _BodyShape _getBodyShape() {
    switch (type) {
      // Fast/agile types - dart shape
      case EnemyType.runner:
      case EnemyType.voidling:
      case EnemyType.dataWorm:
      case EnemyType.ionSurge:
      case EnemyType.droneSwarm:
      case EnemyType.stormRunner:
      case EnemyType.lightningWraith:
      case EnemyType.shadowSwarm:
        return _BodyShape.dart;

      // Glitchy/fractured types
      case EnemyType.overloaded:
      case EnemyType.glitcher:
      case EnemyType.corruptedByte:
      case EnemyType.malware:
      case EnemyType.codeFragment:
        return _BodyShape.fractured;

      // Heavy/tank types - armored shape
      case EnemyType.juggernaut:
      case EnemyType.dimensionBreaker:
      case EnemyType.virusCarrier:
      case EnemyType.thunderHulk:
      case EnemyType.diamondGolem:
      case EnemyType.siegeWalker:
      case EnemyType.firewallBreaker:
      case EnemyType.thunderTitan:
      case EnemyType.darknessTitan:
      case EnemyType.omegaSentinel:
      case EnemyType.apocalypseHerald:
        return _BodyShape.armored;

      // Phantom/spectral types - star shape
      case EnemyType.phantom:
      case EnemyType.riftwalker:
      case EnemyType.prismWalker:
      case EnemyType.cloakedAssassin:
      case EnemyType.systemGhost:
      case EnemyType.cycloneSpirit:
      case EnemyType.voidStalker:
      case EnemyType.realityShifter:
        return _BodyShape.star;

      // Crystal types - hexagon
      case EnemyType.crystalShard:
      case EnemyType.gemCarrier:
        return _BodyShape.hexagon;

      // Mechanical types
      case EnemyType.sentryBot:
      case EnemyType.matrixAgent:
        return _BodyShape.mechanical;

      // Electric types
      case EnemyType.sparkDrone:
      case EnemyType.plasmaCore:
        return _BodyShape.electric;

      // Storm types
      case EnemyType.abyssWalker:
        return _BodyShape.storm;

      // Void types
      case EnemyType.nexusHunter:
        return _BodyShape.void_;
    }
  }

  void _renderThreatCrown(
    Canvas canvas,
    double radius,
    double opacity,
    bool allowBlur,
    bool reduceFx,
  ) {
    final color = _threatColor;
    final spikeCount = 6 + threatTier * 2;
    final innerRadius = radius * (1.05 + threatTier * 0.06);
    final outerRadius = innerRadius + radius * (0.22 + threatTier * 0.05);
    final pointCount = spikeCount * 2;

    _reusableCrownPath.reset();
    for (int i = 0; i < pointCount; i++) {
      final angle = (i / pointCount) * math.pi * 2;
      final r = (i % 2 == 0) ? outerRadius : innerRadius;
      final x = math.cos(angle) * r;
      final y = math.sin(angle) * r;
      if (i == 0) {
        _reusableCrownPath.moveTo(x, y);
      } else {
        _reusableCrownPath.lineTo(x, y);
      }
    }
    _reusableCrownPath.close();

    final fillPaint = Paint()
      ..color = color.withOpacity((reduceFx ? 0.3 : 0.45) * opacity);
    final strokePaint = Paint()
      ..color = color.withOpacity(0.7 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = reduceFx ? 1.0 : 1.6
      ..maskFilter = _blur(allowBlur, reduceFx ? 2 : 4);

    canvas.drawPath(_reusableCrownPath, fillPaint);
    canvas.drawPath(_reusableCrownPath, strokePaint);

    if (threatTier >= 2) {
      final eyeRadius = radius * (0.12 + threatTier * 0.03);
      final eyePaint = Paint()
        ..color = color.withOpacity(0.9 * opacity)
        ..maskFilter = _blur(allowBlur, 4);
      _reusableOverlayPath.reset();
      _reusableOverlayPath.moveTo(0, -eyeRadius);
      _reusableOverlayPath.lineTo(eyeRadius, 0);
      _reusableOverlayPath.lineTo(0, eyeRadius);
      _reusableOverlayPath.lineTo(-eyeRadius, 0);
      _reusableOverlayPath.close();
      canvas.drawPath(_reusableOverlayPath, eyePaint);
    }

    if (!reduceFx && threatTier >= 3) {
      final arcPaint = Paint()
        ..color = color.withOpacity(0.4 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..maskFilter = _blur(allowBlur, 3);
      final arcRadius = outerRadius + radius * 0.12;
      for (int i = 0; i < 3; i++) {
        final start = _animationPhase * 0.6 + i * (math.pi * 2 / 3);
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: arcRadius),
          start,
          math.pi / 3,
          false,
          arcPaint,
        );
      }
    }
  }

  void _renderSlowEffect(Canvas canvas, double radius, bool allowBlur) {
    final slowPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = _blur(allowBlur, 3);

    // Rotating ice crystals
    for (int i = 0; i < 6; i++) {
      final angle = _animationPhase * 0.5 + i * math.pi / 3;
      final x1 = math.cos(angle) * radius * 0.9;
      final y1 = math.sin(angle) * radius * 0.9;
      final x2 = math.cos(angle) * radius * 1.3;
      final y2 = math.sin(angle) * radius * 1.3;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), slowPaint);
    }

    // Cold aura
    final auraPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = _blur(allowBlur, 8);
    final chillSize = radius * 1.2;
    _reusableOverlayPath.reset();
    _reusableOverlayPath.moveTo(0, -chillSize);
    _reusableOverlayPath.lineTo(chillSize, 0);
    _reusableOverlayPath.lineTo(0, chillSize);
    _reusableOverlayPath.lineTo(-chillSize, 0);
    _reusableOverlayPath.close();
    canvas.drawPath(_reusableOverlayPath, auraPaint);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CACHED MASKFILTERS - Avoid per-frame allocations (CRITICAL for perf)
  // ═══════════════════════════════════════════════════════════════════════
  static final Map<int, MaskFilter> _blurCache = {};

  static MaskFilter? _blur(bool allowBlur, double sigma) {
    if (!allowBlur) return null;
    // Round sigma to int to limit cache size while keeping quality
    final key = sigma.round();
    return _blurCache.putIfAbsent(
      key,
      () => MaskFilter.blur(BlurStyle.normal, sigma),
    );
  }

  /// Clear blur cache (call between levels)
  static void clearBlurCache() {
    _blurCache.clear();
  }

  void _renderHealthBar(Canvas canvas, {double visibility = 1.0}) {
    final allowBlur = Enemy.allowBlur;
    final barWidth = 34.0 * type.sizeMult;
    const barHeight = 6.0;
    final barY = -24.0 * type.sizeMult;
    final visibilityClamp = visibility.clamp(0.4, 1.0);
    final baseOpacity =
        (healthPercent >= 1.0 ? 0.45 : 0.9) * visibilityClamp;

    // Background with glow
    final bgRect = Rect.fromCenter(
      center: Offset(0, barY),
      width: barWidth + 2,
      height: barHeight + 2,
    );
    if (allowBlur) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect.inflate(1.5), const Radius.circular(3)),
        Paint()
          ..color = Colors.black.withOpacity(0.35 * baseOpacity)
          ..maskFilter = _blur(allowBlur, 6),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFF000000).withOpacity(0.65 * baseOpacity),
    );

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(2)),
      Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(0.6 * baseOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Health fill with gradient
    final fillWidth = barWidth * healthPercent;
    final healthColor = _getHealthColor();

    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-barWidth / 2, barY - barHeight / 2, fillWidth, barHeight),
      const Radius.circular(1),
    );

    // Gradient fill
    final gradient = LinearGradient(
      colors: [
        healthColor.withOpacity(0.95 * baseOpacity),
        healthColor.withOpacity(0.6 * baseOpacity),
      ],
    ).createShader(fillRect.outerRect);

    canvas.drawRRect(fillRect, Paint()..shader = gradient);

    // Glow on health bar
    canvas.drawRRect(
      fillRect,
      Paint()
        ..color = healthColor.withOpacity(0.55 * baseOpacity)
        ..maskFilter = _blur(allowBlur, 3),
    );
  }

  void _drawMegaGeometry(Canvas canvas, double radius, double phantomOpacity, bool allowBlur) {
    final color = type.color.withOpacity(phantomOpacity);

    // Hull silhouette
    _drawHull(canvas, radius, color, phantomOpacity, allowBlur);

    // Core Layer
    _drawCore(canvas, radius, color, phantomOpacity);
    
    // Shell Layer (Semi-transparent)
    _drawShell(canvas, radius, color, phantomOpacity, allowBlur);
    
    // Armor Plates (Independent rotation)
    _drawArmorPlates(canvas, radius, color, phantomOpacity);
  }

  void _drawHull(Canvas canvas, double radius, Color color, double opacity, bool allowBlur) {
    final hullPath = _createBodyPath(radius * 0.95);
    final baseColor = Color.lerp(color.withOpacity(1), Colors.black, 0.45)!;
    final hullPaint = Paint()
      ..color = baseColor.withOpacity(opacity * 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawPath(hullPath, hullPaint);

    final outlinePaint = Paint()
      ..color = color.withOpacity(opacity * 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.square;
    if (allowBlur && !Enemy.lowFx) {
      outlinePaint.maskFilter = _blur(true, 3);
    }
    canvas.drawPath(hullPath, outlinePaint);
  }

  void _drawCore(Canvas canvas, double radius, Color color, double opacity) {
    final coreRadius = radius * 0.6;
    final corePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.black.withOpacity(opacity * 0.85),
          color.withOpacity(opacity),
          Colors.white.withOpacity(opacity * 0.35),
        ],
        stops: const [0.0, 0.65, 1.0],
        begin: const Alignment(-0.6, -0.6),
        end: const Alignment(0.8, 0.8),
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: coreRadius));
      
    final corePath = _createTypeLayerPath(coreRadius, 0);
    canvas.drawPath(corePath, corePaint);

    final slashPaint = Paint()
      ..color = Colors.white.withOpacity(0.45 * opacity)
      ..strokeWidth = coreRadius * 0.18
      ..strokeCap = StrokeCap.square;
    canvas.save();
    canvas.clipPath(corePath);
    final slashLen = coreRadius * 1.1;
    canvas.drawLine(
      Offset(-slashLen * 0.4, -slashLen * 0.1),
      Offset(slashLen * 0.5, -slashLen * 0.25),
      slashPaint,
    );
    slashPaint.strokeWidth = coreRadius * 0.12;
    canvas.drawLine(
      Offset(-slashLen * 0.3, slashLen * 0.2),
      Offset(slashLen * 0.4, slashLen * 0.05),
      slashPaint,
    );
    canvas.restore();
  }

  void _drawShell(Canvas canvas, double radius, Color color, double opacity, bool allowBlur) {
    final shellPaint = Paint()
      ..color = color.withOpacity(opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (allowBlur && !Enemy.lowFx) {
      // Use fixed blur value to enable caching (animated blur is expensive)
      shellPaint.maskFilter = _blur(true, 5);
    }

    final shellPath = _createTypeLayerPath(radius * 0.9, 1);
    canvas.drawPath(shellPath, shellPaint);
  }

  void _drawArmorPlates(Canvas canvas, double radius, Color color, double opacity) {
    // Determine plate alpha based on speed (fast = less armor, slow = more armor)
    final plateAlpha = type.speedMult > 1.2 ? 0.45 : (type.healthMult > 2.0 ? 0.95 : 0.6);
    final platePaint = Paint()
      ..color = color.withOpacity(opacity * plateAlpha)
      ..style = PaintingStyle.fill;

    // Plate count based on size/health
    final plateCount = type.healthMult > 2.5 ? 6 : (type.healthMult > 1.5 ? 5 : 4);

    // Plate distance based on size
    final plateDist = radius * (0.85 + type.sizeMult * 0.1);

    // Plate size based on health multiplier
    final plateSize = radius * (0.18 + type.healthMult * 0.05).clamp(0.18, 0.35);

    for (int i = 0; i < plateCount; i++) {
      canvas.save();
      final angle = (i * 2 * math.pi / plateCount) + (_orbitalRotation * 0.5);
      canvas.rotate(angle);

      _reusableOverlayPath.reset();
      // Draw plate shape based on enemy characteristics
      if (type.healthMult > 2.0) {
        // Heavy/tank enemies get rectangular plates
        _reusableOverlayPath.addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(plateDist, 0),
            width: plateSize * 1.4,
            height: plateSize * 0.6,
          ),
          Radius.circular(plateSize * 0.2),
        ));
      } else if (type.speedMult > 1.2) {
        // Fast enemies get pointed/aggressive plates
        final jag = plateSize * (0.25 + 0.1 * math.sin(_animationTimer * 6 + i));
        _reusableOverlayPath.moveTo(plateDist, -plateSize);
        _reusableOverlayPath.lineTo(plateDist + plateSize * 0.6, -jag);
        _reusableOverlayPath.lineTo(plateDist + plateSize * 0.9, 0);
        _reusableOverlayPath.lineTo(plateDist + plateSize * 0.6, jag);
        _reusableOverlayPath.lineTo(plateDist, plateSize);
        _reusableOverlayPath.close();
      } else if (type.isPhantom) {
        // Phantom/stealth enemies get thin triangular plates
        _reusableOverlayPath.moveTo(plateDist, -plateSize);
        _reusableOverlayPath.lineTo(plateDist + plateSize * 0.5, 0);
        _reusableOverlayPath.lineTo(plateDist, plateSize);
        _reusableOverlayPath.close();
      } else {
        // Default triangular plates
        _reusableOverlayPath.moveTo(plateDist, -plateSize * 0.6);
        _reusableOverlayPath.lineTo(plateDist + plateSize * 0.9, 0);
        _reusableOverlayPath.lineTo(plateDist, plateSize * 0.6);
        _reusableOverlayPath.close();
      }

      canvas.drawPath(_reusableOverlayPath, platePaint);
      canvas.restore();
    }
  }

  void _drawDataAura(Canvas canvas, double radius, double opacity) {
    final t = _animationTimer;
    final bitPaint = Paint()..color = type.color.withOpacity(opacity * 0.6);
    
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - _orbitalRotation;
      final dist = radius * 1.4 + 4 * math.sin(t * 3 + i);
      final bitPos = Offset(math.cos(angle) * dist, math.sin(angle) * dist);
      
      canvas.drawRect(
        Rect.fromCenter(center: bitPos, width: 3, height: 3),
        bitPaint,
      );
      
      // Connect to center with thin line
      if (healthPercent > 0.8) {
        canvas.drawLine(
          Offset.zero, 
          bitPos, 
          Paint()..color = type.color.withOpacity(opacity * 0.1)..strokeWidth = 0.5
        );
      }
    }
  }

  void _renderPlasmaSmoke(Canvas canvas, double radius, double opacity) {
    for (final particle in _plasmaParticles) {
      final size = particle.size * 1.4;
      final angle = (_animationTimer * 0.8 + particle.position.x * 0.02 + particle.position.y * 0.02);
      canvas.save();
      canvas.translate(particle.position.x, particle.position.y);
      canvas.rotate(angle);
      _particlePaint
        ..color = particle.color.withOpacity(particle.opacity * opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: size * 1.2, height: size * 0.5),
        _particlePaint,
      );
      canvas.restore();
    }
  }

  Path _createTypeLayerPath(double radius, int layer) {
    // Reuse static path to avoid per-frame allocations
    _reusableLayerPath.reset();

    // Specialized geometry based on enemy characteristics
    if (type.healthMult > 2.0) {
      // Heavy/tank enemies - octagonal/boxy shape
      final inset = radius * 0.35;
      _reusableLayerPath.moveTo(radius, -inset);
      _reusableLayerPath.lineTo(radius * 0.65, -radius);
      _reusableLayerPath.lineTo(-radius * 0.65, -radius);
      _reusableLayerPath.lineTo(-radius, -inset);
      _reusableLayerPath.lineTo(-radius, inset);
      _reusableLayerPath.lineTo(-radius * 0.65, radius);
      _reusableLayerPath.lineTo(radius * 0.65, radius);
      _reusableLayerPath.lineTo(radius, inset);
      _reusableLayerPath.close();
    } else if (type.speedMult > 1.2) {
      // Fast enemies - polygon with wobble
      final sides = 4 + layer;
      final wobble = math.sin(_animationTimer * 5 + layer) * 0.08;
      for (int i = 0; i < sides; i++) {
        final angle = (i * 2 * math.pi / sides) + (layer * math.pi / sides);
        final scale = 1.0 + (i.isEven ? wobble : -wobble);
        final point = Offset(math.cos(angle) * radius * scale, math.sin(angle) * radius * scale);
        if (i == 0) _reusableLayerPath.moveTo(point.dx, point.dy);
        else _reusableLayerPath.lineTo(point.dx, point.dy);
      }
      _reusableLayerPath.close();
    } else if (type.isPhantom) {
      // Phantom/stealth enemies - star shape with drift
      final points = 5 + layer;
      for (int i = 0; i < points * 2; i++) {
        final r = i.isEven ? radius : radius * 0.6;
        final drift = math.sin(_animationTimer * 2 + i) * radius * 0.05;
        final angle = i * math.pi / points + _animationTimer * 0.8;
        final point = Offset(math.cos(angle) * (r + drift), math.sin(angle) * (r + drift));
        if (i == 0) _reusableLayerPath.moveTo(point.dx, point.dy);
        else _reusableLayerPath.lineTo(point.dx, point.dy);
      }
      _reusableLayerPath.close();
    } else {
      // Default - arrow/diamond shape
      _reusableLayerPath.moveTo(radius * 0.9, 0);
      _reusableLayerPath.lineTo(radius * 0.3, -radius * 0.55);
      _reusableLayerPath.lineTo(-radius * 0.4, -radius * 0.4);
      _reusableLayerPath.lineTo(-radius * 0.75, 0);
      _reusableLayerPath.lineTo(-radius * 0.4, radius * 0.4);
      _reusableLayerPath.lineTo(radius * 0.3, radius * 0.55);
      _reusableLayerPath.close();
    }
    return _reusableLayerPath;
  }

  Color _getHealthColor() {
    if (healthPercent > 0.6) {
      return const Color(0xFF00FF88); // Neon green
    } else if (healthPercent > 0.3) {
      return const Color(0xFFFFFF00); // Neon yellow
    } else {
      return const Color(0xFFFF0066); // Neon red/magenta
    }
  }

  void _move(double dt) {
    if (path.isEmpty || _currentTargetIndex >= path.length) {
      onReachBase?.call(this);
      removeFromParent();
      return;
    }

    final target = path[_currentTargetIndex];
    final direction = target - position;
    final distance = direction.length;
    final moveDist = speed * dt;

    if (moveDist >= distance) {
      position = target;
      _currentTargetIndex++;
    } else {
      position += direction.normalized() * moveDist;
    }
  }
}

/// Walking visual style categories for different enemy types
enum _WalkStyle {
  legs,      // Runner-style fast legs
  tendrils,  // Energy tendrils
  stomp,     // Heavy footsteps
  wisps,     // Ghostly wisps
  glitch,    // Dimensional glitch effects
  electric,  // Electric arcs and sparks
  crystal,   // Floating crystal shards
  mechanical,// Mechanical pistons
  digital,   // Binary data streams
  storm,     // Wind and lightning
  void_,     // Dark void tendrils
  omega,     // Ultimate combined effects
}

/// Body shape categories for different enemy types
enum _BodyShape {
  dart,       // Aerodynamic dart (fast types)
  fractured,  // Fractured polygon (glitchy types)
  armored,    // Beveled armor (tank types)
  star,       // Phase-shifted star (phantom types)
  hexagon,    // Hexagonal (crystal types)
  mechanical, // Mechanical box (robot types)
  electric,   // Spiky electric (plasma types)
  storm,      // Swirling storm shape
  void_,      // Irregular dark shape
  omega,      // Complex ultimate shape
}

/// Eye style categories for terrifying enemy visuals
enum _EyeStyle {
  predator,   // Single menacing slit eye
  hive,       // Multiple compound eyes
  void_,      // Empty sockets of darkness
  burning,    // Eyes of flame
  crystal,    // Faceted gem eyes
  mechanical, // Cold robotic sensors
  corrupted,  // Glitching digital eyes
  abyssal,    // Infinite depth void eyes
}

class _CircuitSegment {
  _CircuitSegment(this.start, this.end);

  final Offset start;
  final Offset end;
}

class _NoiseBit {
  _NoiseBit({
    required this.offset,
    required this.phase,
    required this.size,
  });

  final Offset offset;
  final double phase;
  final double size;
}

/// Particle emitted when enemy takes damage
class _DamageParticle {
  _DamageParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.lifetime,
  }) : distance = 0,
       _timer = 0;

  final double angle;
  final double speed;
  final double size;
  final double lifetime;

  double distance;
  double _timer;

  bool get isActive => _timer < lifetime;
  double get progress => (_timer / lifetime).clamp(0.0, 1.0);
  double get alpha => (1 - progress).clamp(0.0, 1.0);

  void update(double dt) {
    _timer += dt;
    distance += speed * dt * (1 - progress * 0.5);
  }
}

class _DataBit {
  _DataBit({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.rotation,
    required this.lifetime,
  });

  final Vector2 position;
  final Vector2 velocity;
  final Color color;
  final double size;
  final double rotation;
  final double lifetime;
  double _timer = 0;

  bool get isActive => _timer < lifetime;
  double get alpha => (1 - _timer / lifetime).clamp(0.0, 1.0);

  void update(double dt) {
    _timer += dt;
    position.add(velocity * dt);
    velocity.y += 150 * dt; // Gravity
  }
}

class _PlasmaParticle {
  _PlasmaParticle({
    required this.position,
    required this.velocity,
    required this.color,
  });

  Vector2 position;
  final Vector2 velocity;
  final Color color;
  bool isActive = true;
  double opacity = 0.8;
  double size = 4.0;

  void update(double dt) {
    position += velocity * dt;
    opacity -= dt * 1.2;
    size -= dt * 2;
    if (opacity <= 0 || size <= 0) isActive = false;
  }
}
