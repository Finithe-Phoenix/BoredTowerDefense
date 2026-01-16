import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';

/// Callback types for enemy events
typedef EnemyDeathCallback = void Function(Enemy enemy);
typedef EnemyReachBaseCallback = void Function(Enemy enemy);

/// Enemy type with visual and stat modifiers
enum EnemyType {
  runner(color: Color(0xFFFF7043), speedMult: 1.0, healthMult: 1.0, sizeMult: 1.0, isPhantom: false),
  overloaded(color: Color(0xFFFF0066), speedMult: 1.4, healthMult: 0.8, sizeMult: 0.9, isPhantom: false),
  juggernaut(color: Color(0xFF9C27B0), speedMult: 0.6, healthMult: 2.5, sizeMult: 1.4, isPhantom: false),
  phantom(color: Color(0xFF00FFAA), speedMult: 1.1, healthMult: 1.2, sizeMult: 0.95, isPhantom: true);

  const EnemyType({
    required this.color,
    required this.speedMult,
    required this.healthMult,
    required this.sizeMult,
    required this.isPhantom,
  });

  final Color color;
  final double speedMult;
  final double healthMult;
  final double sizeMult;
  final bool isPhantom;
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
       _animationPhase = math.Random().nextDouble() * math.pi * 2,
       _circuitSeed = math.Random().nextDouble() {
    // Apply type multipliers
    _maxHealth = _baseMaxHealth * type.healthMult * _tierHealthMult;
    _health = _maxHealth;
    _speed = _baseSpeed * type.speedMult * _tierSpeedMult;

    size = Vector2.all(24 * type.sizeMult * _tierSizeMult);
    anchor = Anchor.center;
    position = startPosition ?? (path.isNotEmpty ? path.first.clone() : Vector2.zero());

    // Initialize trail
    _trailPositions = List.generate(_maxTrailLength, (_) => position.clone());
  }

  final List<Vector2> path;
  final double _baseSpeed;
  final double _baseMaxHealth;
  final int goldReward;
  final EnemyType type;
  final int spawnIndex;
  final int threatTier;
  final int worldIndex;

  int _currentTargetIndex;
  late double _health;
  late double _maxHealth;
  late double _speed;
  double _animationPhase;

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
    final random = math.Random();
    
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

    // New Data Bits
    final bitCount = 3 + random.nextInt(4);
    for (int i = 0; i < bitCount; i++) {
      _dataBits.add(_DataBit(
        position: Vector2.zero(),
        velocity: Vector2(
          (random.nextDouble() - 0.5) * 80,
          (random.nextDouble() - 0.5) * 80,
        ),
        color: type.color,
        size: 2 + random.nextDouble() * 2,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animationTimer += dt;
    _animationPhase += dt * 2;
    _walkPhase += dt * speed / 15.0;

    // Update particles
    _updateParticles(dt);

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

    _orbitalRotation += dt * 2;
    _updatePlasmaParticles(dt);
    _lastHealth = _health;

    _move(dt);
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
    
    // Spawn plasma smoke if health is low
    if (healthPercent < 0.4 && math.Random().nextDouble() < 0.15) {
      _plasmaParticles.add(_PlasmaParticle(
        position: Vector2.zero(),
        velocity: Vector2((math.Random().nextDouble() - 0.5) * 30, -30 - math.Random().nextDouble() * 30),
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

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final reduceFx = Enemy.lowFx || Enemy.forceLowFx;
    final allowBlur = Enemy.allowBlur;

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

    // Reactive distortion at low health
    final hpFactor = healthPercent;
    if (hpFactor < 0.5 && !reduceFx) {
      final glitchChance = 0.1 + (0.5 - hpFactor) * 0.8;
      if (math.Random().nextDouble() < glitchChance) {
        canvas.translate((math.Random().nextDouble() - 0.5) * 3, (math.Random().nextDouble() - 0.5) * 3);
      }
    }

    if (!reduceFx) {
      // Render trail first (behind enemy)
      _renderTrail(canvas, phantomOpacity, allowBlur);

      // Render damage particles
      _renderDamageParticles(canvas, allowBlur);
    }

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
    final glowPulse = 0.2 + math.sin(_walkPhase) * 0.05;
    final outerGlowPaint = Paint()
      ..color = type.color.withOpacity(glowPulse * phantomOpacity)
      ..maskFilter = _blur(allowBlur, 12);
    canvas.drawCircle(Offset.zero, radius * 1.3, outerGlowPaint);

    // Main body glow
    final bodyGlowPaint = Paint()
      ..color = type.color.withOpacity(0.5 * phantomOpacity)
      ..maskFilter = _blur(allowBlur, 5);
    canvas.drawCircle(Offset.zero, radius, bodyGlowPaint);

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
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3 * phantomOpacity);
    canvas.drawCircle(highlightOffset, radius * 0.3, highlightPaint);

    if (threatTier > 0) {
      _renderThreatCrown(canvas, radius, phantomOpacity, allowBlur, reduceFx);
    }

    if (!reduceFx) {
      // Walking legs/tentacles effect (type-specific)
      _renderWalkingEffect(canvas, radius, phantomOpacity, allowBlur);

      // Type-specific effects
      _renderTypeEffects(canvas, radius, phantomOpacity, allowBlur);
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
      final blurOffset = -direction * (i * 4.0);
      final blurAlpha = (1 - i / blurCount) * 0.2 * opacity * _speedIndicator;

      canvas.drawCircle(
        Offset(blurOffset.x, blurOffset.y),
        radius * 0.8,
        Paint()
          ..color = type.color.withOpacity(blurAlpha)
          ..maskFilter = _blur(allowBlur, 4.0 + i * 2.0),
      );
    }
  }

  void _renderWalkingEffect(Canvas canvas, double radius, double opacity, bool allowBlur) {
    switch (type) {
      case EnemyType.runner:
        // Fast running legs
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
              ..strokeCap = StrokeCap.round
              ..maskFilter = _blur(allowBlur, 2),
          );
        }
        break;

      case EnemyType.overloaded:
        // Energy tendrils
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
              ..strokeCap = StrokeCap.round
              ..maskFilter = _blur(allowBlur, 3),
          );
        }
        break;

      case EnemyType.juggernaut:
        // Heavy stomping feet (fewer, bigger)
        for (int i = 0; i < 2; i++) {
          final footPhase = _walkPhase + i * math.pi;
          final footAngle = math.pi / 2 + i * math.pi;
          final footOffset = math.sin(footPhase) * radius * 0.3;

          final footX = math.cos(footAngle) * (radius * 0.7 + footOffset);
          final footY = math.sin(footAngle) * (radius * 0.7 + footOffset) + math.sin(footPhase).abs() * 3;

          // Stomp impact when foot is down
          if (math.sin(footPhase) < -0.8) {
            canvas.drawCircle(
              Offset(footX, footY + 2),
              4,
            Paint()
              ..color = type.color.withOpacity(0.3 * opacity)
              ..maskFilter = _blur(allowBlur, 6),
          );
          }

          canvas.drawCircle(
            Offset(footX, footY),
            radius * 0.25,
            Paint()
              ..color = type.color.withOpacity(0.7 * opacity),
          );
        }
        break;

      case EnemyType.phantom:
        // Ghostly wisps that follow
        for (int i = 0; i < 4; i++) {
          final wispPhase = _animationPhase * 2 + i * math.pi / 2;
          final wispDist = radius * (0.9 + math.sin(wispPhase * 0.5) * 0.3);
          final wispAngle = wispPhase * 0.3 + i * math.pi / 2;

          final wispX = math.cos(wispAngle) * wispDist;
          final wispY = math.sin(wispAngle) * wispDist;

          // Wisp with trail
          for (int j = 0; j < 3; j++) {
            final trailAlpha = (1 - j / 3) * 0.4 * opacity;
            final trailOffset = j * 3.0;

            canvas.drawCircle(
              Offset(wispX - math.cos(wispAngle) * trailOffset,
                     wispY - math.sin(wispAngle) * trailOffset),
              2 - j * 0.5,
            Paint()
              ..color = type.color.withOpacity(trailAlpha)
              ..maskFilter = _blur(allowBlur, 2),
            );
          }
        }
        break;
    }
  }

  void _renderHitFlash(Canvas canvas, double radius, double opacity, bool allowBlur) {
    final flashProgress = _hitFlashTimer / _hitFlashDuration;

    // Flash overlay
    canvas.drawCircle(
      Offset.zero,
      radius * 1.15,
      Paint()
        ..color = Colors.white.withOpacity(flashProgress * 0.35 * opacity)
        ..maskFilter = _blur(allowBlur, 3),
    );

    // Expanding ring
    final ringRadius = radius * (1.1 + (1 - flashProgress) * 0.35);
    canvas.drawCircle(
      Offset.zero,
      ringRadius,
      Paint()
        ..color = const Color(0xFFFF0066).withOpacity(flashProgress * 0.35 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = _blur(allowBlur, 2),
    );

    // Directional damage sparks
    for (int i = 0; i < 4; i++) {
      final sparkAngle = i * math.pi / 2 + _animationPhase;
      final sparkDist = radius * (1 + (1 - flashProgress) * 0.8);
      final sparkX = math.cos(sparkAngle) * sparkDist;
      final sparkY = math.sin(sparkAngle) * sparkDist;

      canvas.drawCircle(
        Offset(sparkX, sparkY),
        1.5 * flashProgress,
        Paint()
          ..color = Colors.white.withOpacity(flashProgress * 0.5 * opacity)
          ..maskFilter = _blur(allowBlur, 2),
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

      canvas.drawCircle(
        Offset(px, py),
        particle.size * 1.5,
        Paint()
          ..color = type.color.withOpacity(alpha * 0.3)
          ..maskFilter = _blur(allowBlur, 3),
      );

      canvas.drawCircle(
        Offset(px, py),
        particle.size * (1 - particle.progress * 0.5),
        Paint()..color = type.color.withOpacity(alpha),
      );
    }

    // Data bits
    for (final bit in _dataBits) {
      if (!bit.isActive) continue;
      
      final paint = Paint()
        ..color = bit.color.withOpacity(bit.alpha)
        ..style = PaintingStyle.fill;
      
      canvas.save();
      canvas.translate(bit.position.x, bit.position.y);
      canvas.rotate(bit.rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: bit.size, height: bit.size),
        paint,
      );
      
      if (allowBlur) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: bit.size * 1.5, height: bit.size * 1.5),
          Paint()
            ..color = bit.color.withOpacity(bit.alpha * 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
      canvas.restore();
    }
  }

  void _renderTrail(Canvas canvas, double opacity, bool allowBlur) {
    for (int i = 0; i < _trailPositions.length; i++) {
      final t = i / _trailPositions.length;
      final alpha = (1 - t) * 0.4 * opacity;
      final trailSize = size.x * 0.3 * (1 - t);

      // Calculate offset from current position
      final offset = _trailPositions[i] - position;

      final trailPaint = Paint()
        ..color = type.color.withOpacity(alpha)
        ..maskFilter = _blur(allowBlur, 3);

      canvas.drawCircle(
        Offset(offset.x, offset.y),
        trailSize,
        trailPaint,
      );
    }
  }

  void _renderTypeEffects(Canvas canvas, double radius, double opacity, bool allowBlur) {
    final t = _animationTimer;
    switch (type) {
      case EnemyType.runner:
        // Streamers
        final streamerPaint = Paint()
          ..color = type.color.withOpacity(0.3 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        
        for (int i = 0; i < 3; i++) {
          final offset = math.sin(t * 10 + i) * 4;
          canvas.drawLine(
            Offset(-radius * 1.2, offset),
            Offset(-radius * 2.5, offset),
            streamerPaint,
          );
        }
        
        // Animated Chevrons
        final chevronPaint = Paint()
          ..color = Colors.white.withOpacity(0.3 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        
        for (int i = 0; i < 2; i++) {
          final x = -radius * 0.5 + ((t * 2 + i * 0.5) % 1.0) * radius;
          final chevronPath = Path()
            ..moveTo(x - 4, -4)
            ..lineTo(x, 0)
            ..lineTo(x - 4, 4);
          canvas.drawPath(chevronPath, chevronPaint);
        }
        break;

      case EnemyType.overloaded:
        // Fractal Core
        final spikes = 8;
        final fractalPath = Path();
        for (int i = 0; i < spikes * 2; i++) {
          final angle = (i / (spikes * 2)) * math.pi * 2 + t * 5;
          final r = (i % 2 == 0) 
            ? radius * 0.4 * (1 + math.sin(t * 15) * 0.1)
            : radius * 0.2;
          final x = math.cos(angle) * r;
          final y = math.sin(angle) * r;
          if (i == 0) fractalPath.moveTo(x, y);
          else fractalPath.lineTo(x, y);
        }
        fractalPath.close();
        
        canvas.drawPath(fractalPath, Paint()..color = Colors.white.withOpacity(0.8 * opacity));
        if (allowBlur) {
          canvas.drawPath(fractalPath, Paint()
            ..color = Colors.white.withOpacity(0.4 * opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        }

        // Energy Sparks
        if (math.Random().nextDouble() < 0.3) {
          final sparkAngle = math.Random().nextDouble() * math.pi * 2;
          final sparkDist = radius * 0.8;
          canvas.drawCircle(
            Offset(math.cos(sparkAngle) * sparkDist, math.sin(sparkAngle) * sparkDist),
            1.5,
            Paint()..color = Colors.white.withOpacity(0.9 * opacity),
          );
        }
        break;

      case EnemyType.juggernaut:
        // Rotating Hex-Shields
        canvas.save();
        canvas.rotate(t * 0.5);
        final shieldPaint = Paint()
          ..color = type.color.withOpacity(0.25 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
          
        for (int i = 0; i < 6; i++) {
          final angle = (i / 6) * math.pi * 2;
          final x = math.cos(angle) * radius * 1.25;
          final y = math.sin(angle) * radius * 1.25;
          
          final hex = Path();
          for (int j = 0; j < 6; j++) {
            final hAngle = (j / 6) * math.pi * 2 + t * 2;
            final hR = radius * 0.25;
            final hX = x + math.cos(hAngle) * hR;
            final hY = y + math.sin(hAngle) * hR;
            if (j == 0) hex.moveTo(hX, hY);
            else hex.lineTo(hX, hY);
          }
          hex.close();
          canvas.drawPath(hex, shieldPaint);
        }
        canvas.restore();
        break;

      case EnemyType.phantom:
        // Digital Hologram Upgrade
        final hologramPaint = Paint()
          ..color = type.color.withOpacity(0.4 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
          
        // Scanlines
        for (int i = 0; i < 8; i++) {
          final y = -radius + (radius * 2 * ((t * 0.5 + i / 8) % 1.0));
          canvas.drawLine(Offset(-radius, y), Offset(radius, y), hologramPaint);
        }
        
        // Data bits noise
        final rand = math.Random(spawnIndex);
        for (int i = 0; i < 5; i++) {
          if (rand.nextDouble() < 0.6) {
            final bx = (rand.nextDouble() - 0.5) * radius * 2.5;
            final by = (rand.nextDouble() - 0.5) * radius * 2.5;
            canvas.drawRect(
              Rect.fromLTWH(bx, by, 2, 2),
              Paint()..color = type.color.withOpacity(0.5 * opacity),
            );
          }
        }
        break;
    }
  }

  void _applyWorldVisuals(Canvas canvas) {
    canvas.save();
    
    final t = _animationTimer;
    final rand = math.Random((_circuitSeed * 100).toInt());

    switch (worldIndex) {
      case 2: // Rift Wars - Glitch style
        if (rand.nextDouble() < 0.15) {
          final shiftX = (rand.nextDouble() - 0.5) * 4;
          final shiftY = (rand.nextDouble() - 0.5) * 2;
          canvas.translate(shiftX, shiftY);
        }
        break;
      case 3: // Signal Wastes - Noise/Static
        if (math.sin(t * 20) > 0.8) {
          canvas.skew(0.05 * math.sin(t * 30), 0);
        }
        break;
      case 4: // Ion Crown - Arc/Electrical jitter
        final jitter = math.sin(t * 40) * 0.8;
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
    
    final paint = Paint()
      ..color = type.color.withOpacity(0.2 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
      
    final rand = math.Random((_circuitSeed * 1000).toInt());
    final pulse = 0.5 + math.sin(_animationTimer * 3) * 0.5;
    paint.color = paint.color.withOpacity(0.1 * opacity + 0.15 * pulse * opacity);

    for (int i = 0; i < 4; i++) {
      final x1 = (rand.nextDouble() - 0.5) * radius * 1.4;
      final y1 = (rand.nextDouble() - 0.5) * radius * 1.4;
      final x2 = (rand.nextDouble() - 0.5) * radius * 1.4;
      final y2 = (rand.nextDouble() - 0.5) * radius * 1.4;
      
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      canvas.drawCircle(Offset(x1, y1), 1.0, paint..style = PaintingStyle.fill);
    }
  }

  Path _createBodyPath(double radius) {
    final path = Path();
    switch (type) {
      case EnemyType.runner:
        // Sleek aerodynamic diamond
        path.moveTo(radius, 0);
        path.lineTo(0, -radius * 0.6);
        path.lineTo(-radius * 0.8, 0);
        path.lineTo(0, radius * 0.6);
        break;
      case EnemyType.overloaded:
        // Shifting fractal-like square
        final shift = math.sin(_animationTimer * 10) * radius * 0.1;
        path.addRect(Rect.fromCenter(
          center: Offset.zero, 
          width: radius * 1.6 + shift, 
          height: radius * 1.6 - shift,
        ));
        break;
      case EnemyType.juggernaut:
        // Heavy octagon
        for (int i = 0; i < 8; i++) {
          final angle = (i / 8) * math.pi * 2;
          final x = math.cos(angle) * radius;
          final y = math.sin(angle) * radius;
          if (i == 0) path.moveTo(x, y);
          else path.lineTo(x, y);
        }
        break;
      case EnemyType.phantom:
        // Unstable triangular ghost
        for (int i = 0; i < 3; i++) {
          final angle = (i / 3) * math.pi * 2 + _animationTimer * 2;
          final x = math.cos(angle) * radius;
          final y = math.sin(angle) * radius;
          if (i == 0) path.moveTo(x, y);
          else path.lineTo(x, y);
        }
        break;
    }
    path.close();
    return path;
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

    final crownPath = Path();
    for (int i = 0; i < pointCount; i++) {
      final angle = (i / pointCount) * math.pi * 2;
      final r = (i % 2 == 0) ? outerRadius : innerRadius;
      final x = math.cos(angle) * r;
      final y = math.sin(angle) * r;
      if (i == 0) {
        crownPath.moveTo(x, y);
      } else {
        crownPath.lineTo(x, y);
      }
    }
    crownPath.close();

    final fillPaint = Paint()
      ..color = color.withOpacity((reduceFx ? 0.3 : 0.45) * opacity);
    final strokePaint = Paint()
      ..color = color.withOpacity(0.7 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = reduceFx ? 1.0 : 1.6
      ..maskFilter = _blur(allowBlur, reduceFx ? 2 : 4);

    canvas.drawPath(crownPath, fillPaint);
    canvas.drawPath(crownPath, strokePaint);

    if (threatTier >= 2) {
      final eyeRadius = radius * (0.12 + threatTier * 0.03);
      final eyePaint = Paint()
        ..color = color.withOpacity(0.9 * opacity)
        ..maskFilter = _blur(allowBlur, 4);
      canvas.drawCircle(Offset.zero, eyeRadius, eyePaint);
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
      ..maskFilter = _blur(allowBlur, 8);
    canvas.drawCircle(Offset.zero, radius * 1.4, auraPaint);
  }

  MaskFilter? _blur(bool allowBlur, double sigma) {
    if (!allowBlur) return null;
    return MaskFilter.blur(BlurStyle.normal, sigma);
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
    final t = _animationTimer;
    final color = type.color.withOpacity(phantomOpacity);
    
    // Core Layer
    _drawCore(canvas, radius, color, phantomOpacity);
    
    // Shell Layer (Semi-transparent)
    _drawShell(canvas, radius, color, phantomOpacity, allowBlur);
    
    // Armor Plates (Independent rotation)
    _drawArmorPlates(canvas, radius, color, phantomOpacity);
  }

  void _drawCore(Canvas canvas, double radius, Color color, double opacity) {
    final coreRadius = radius * 0.6;
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(opacity), color],
        stops: const [0.0, 0.8],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: coreRadius));
      
    final corePath = _createTypeLayerPath(coreRadius, 0);
    canvas.drawPath(corePath, corePaint);
  }

  void _drawShell(Canvas canvas, double radius, Color color, double opacity, bool allowBlur) {
    final shellPaint = Paint()
      ..color = color.withOpacity(opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    if (allowBlur && !Enemy.lowFx) {
      shellPaint.maskFilter = MaskFilter.blur(BlurStyle.outer, 4 * (1 + math.sin(_animationTimer * 2).abs()));
    }

    final shellPath = _createTypeLayerPath(radius * 0.9, 1);
    canvas.drawPath(shellPath, shellPaint);
  }

  void _drawArmorPlates(Canvas canvas, double radius, Color color, double opacity) {
    final platePaint = Paint()
      ..color = color.withOpacity(opacity * 0.8)
      ..style = PaintingStyle.fill;
      
    final plateCount = switch (type) {
      EnemyType.juggernaut => 6,
      EnemyType.overloaded => 3,
      _ => 4,
    };

    for (int i = 0; i < plateCount; i++) {
        canvas.save();
        final angle = (i * 2 * math.pi / plateCount) + (_orbitalRotation * 0.5);
        canvas.rotate(angle);
        
        final plateDist = radius * 0.85;
        final plateSize = radius * 0.3;
        
        final platePath = Path()
          ..moveTo(plateDist, -plateSize/2)
          ..lineTo(plateDist + 4, 0)
          ..lineTo(plateDist, plateSize/2)
          ..close();
          
        canvas.drawPath(platePath, platePaint);
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
      final pPaint = Paint()
        ..color = particle.color.withOpacity(particle.opacity * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        
      canvas.drawCircle(particle.position.toOffset(), particle.size, pPaint);
    }
  }

  Path _createTypeLayerPath(double radius, int layer) {
    // Specialized geometry per type and layer
    switch (type) {
      case EnemyType.runner:
        return Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: radius));
        
      case EnemyType.overloaded:
        final path = Path();
        final sides = 3 + layer;
        for (int i = 0; i < sides; i++) {
          final angle = (i * 2 * math.pi / sides) + (layer * math.pi / sides);
          final point = Offset(math.cos(angle) * radius, math.sin(angle) * radius);
          if (i == 0) path.moveTo(point.dx, point.dy);
          else path.lineTo(point.dx, point.dy);
        }
        return path..close();
        
      case EnemyType.juggernaut:
        return Path()..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 2),
          Radius.circular(layer == 0 ? 4 : 8),
        ));
        
      case EnemyType.phantom:
        final path = Path();
        final points = 5 + layer;
        for (int i = 0; i < points * 2; i++) {
          final r = i.isEven ? radius : radius * 0.7;
          final angle = i * math.pi / points;
          final point = Offset(math.cos(angle) * r, math.sin(angle) * r);
          if (i == 0) path.moveTo(point.dx, point.dy);
          else path.lineTo(point.dx, point.dy);
        }
        return path..close();
    }
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
  }) : rotation = math.Random().nextDouble() * math.pi * 2,
       lifetime = 0.6 + math.Random().nextDouble() * 0.4;

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
