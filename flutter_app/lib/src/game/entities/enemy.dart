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
  Enemy({
    required this.path,
    double speed = 80,
    double maxHealth = 100,
    this.goldReward = 10,
    this.type = EnemyType.runner,
    Vector2? startPosition,
    this.onDeath,
    this.onReachBase,
  }) : _baseSpeed = speed,
       _baseMaxHealth = maxHealth,
       _currentTargetIndex = 0,
       _animationPhase = math.Random().nextDouble() * math.pi * 2 {
    // Apply type multipliers
    _maxHealth = _baseMaxHealth * type.healthMult;
    _health = _maxHealth;
    _speed = _baseSpeed * type.speedMult;

    size = Vector2.all(24 * type.sizeMult);
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
  static const double _hitFlashDuration = 0.1;

  // Pulse animation
  double _pulseScale = 1.0;

  // Walking animation
  double _walkPhase = 0;
  double _wobbleOffset = 0;
  double _verticalBob = 0;
  Vector2 _lastPosition = Vector2.zero();
  double _speedIndicator = 0;

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

  /// Whether this enemy is a phantom type
  bool get isPhantom => type.isPhantom;

  /// Whether the phantom has been revealed (damaged or detected)
  bool _isRevealed = false;
  double _revealTimer = 0;
  static const double _revealDuration = 3.0; // Stays visible for 3 seconds after detection

  /// Whether the phantom is currently visible
  bool get isVisible => !isPhantom || _isRevealed;

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
    final random = math.Random();
    final particleCount = 4 + random.nextInt(4);

    for (int i = 0; i < particleCount && _damageParticles.length < _maxDamageParticles; i++) {
      _damageParticles.add(_DamageParticle(
        angle: random.nextDouble() * math.pi * 2,
        speed: 30 + random.nextDouble() * 50,
        size: 2 + random.nextDouble() * 3,
        lifetime: 0.3 + random.nextDouble() * 0.2,
      ));
    }
  }

  /// Apply slow effect
  void applySlow(double factor, double duration) {
    _slowFactor = factor.clamp(0.1, 1.0);
    _slowDuration = duration;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Calculate opacity for phantom (invisible when not revealed)
    double phantomOpacity = 1.0;
    if (isPhantom && !_isRevealed) {
      // Barely visible shimmer effect when invisible
      phantomOpacity = 0.08 + math.sin(_animationPhase * 4) * 0.04;
    } else if (isPhantom && _isRevealed) {
      // Fade out as reveal timer expires
      phantomOpacity = (_revealTimer / _revealDuration).clamp(0.4, 1.0);
    }

    // Render trail first (behind enemy)
    _renderTrail(canvas, phantomOpacity);

    // Render damage particles
    _renderDamageParticles(canvas);

    // Apply walking bob transformation
    canvas.save();
    canvas.translate(_wobbleOffset, _verticalBob);

    // Animation pulse
    final animScale = _pulseScale * (1 + math.sin(_animationPhase) * 0.05);
    final radius = (size.x / 2) * animScale;

    // Speed-based motion blur when moving fast
    if (_speedIndicator > 0.3) {
      _renderMotionBlur(canvas, radius, phantomOpacity);
    }

    // Outer glow (pulsing intensity based on walk phase)
    final glowPulse = 0.2 + math.sin(_walkPhase) * 0.05;
    final outerGlowPaint = Paint()
      ..color = type.color.withOpacity(glowPulse * phantomOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset.zero, radius * 1.3, outerGlowPaint);

    // Main body glow
    final bodyGlowPaint = Paint()
      ..color = type.color.withOpacity(0.5 * phantomOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset.zero, radius, bodyGlowPaint);

    // Enemy body - solid core
    final bodyPaint = Paint()..color = type.color.withOpacity(phantomOpacity);
    canvas.drawCircle(Offset.zero, radius * 0.8, bodyPaint);

    // Inner highlight (bobs with movement)
    final highlightOffset = Offset(
      -radius * 0.2 + math.sin(_walkPhase * 0.5) * 1,
      -radius * 0.2 + math.cos(_walkPhase * 0.5) * 1,
    );
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3 * phantomOpacity);
    canvas.drawCircle(highlightOffset, radius * 0.3, highlightPaint);

    // Walking legs/tentacles effect (type-specific)
    _renderWalkingEffect(canvas, radius, phantomOpacity);

    // Type-specific effects
    _renderTypeEffects(canvas, radius, phantomOpacity);

    canvas.restore();

    // Hit flash overlay (outside canvas transform)
    if (_hitFlashTimer > 0) {
      _renderHitFlash(canvas, radius, phantomOpacity);
    }

    // Slow indicator (ice crystal effect)
    if (isSlowed) {
      _renderSlowEffect(canvas, radius);
    }

    // Health bar (only show if damaged and visible)
    if (healthPercent < 1.0 && phantomOpacity > 0.3) {
      _renderHealthBar(canvas);
    }
  }

  void _renderMotionBlur(Canvas canvas, double radius, double opacity) {
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
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 + i * 2.0),
      );
    }
  }

  void _renderWalkingEffect(Canvas canvas, double radius, double opacity) {
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
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
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
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
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
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
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
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
            );
          }
        }
        break;
    }
  }

  void _renderHitFlash(Canvas canvas, double radius, double opacity) {
    final flashProgress = _hitFlashTimer / _hitFlashDuration;

    // Flash overlay
    canvas.drawCircle(
      Offset.zero,
      radius * 1.2,
      Paint()
        ..color = Colors.white.withOpacity(flashProgress * 0.8 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Expanding ring
    final ringRadius = radius * (1.2 + (1 - flashProgress) * 0.5);
    canvas.drawCircle(
      Offset.zero,
      ringRadius,
      Paint()
        ..color = const Color(0xFFFF0066).withOpacity(flashProgress * 0.6 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Directional damage sparks
    for (int i = 0; i < 4; i++) {
      final sparkAngle = i * math.pi / 2 + _animationPhase;
      final sparkDist = radius * (1 + (1 - flashProgress) * 0.8);
      final sparkX = math.cos(sparkAngle) * sparkDist;
      final sparkY = math.sin(sparkAngle) * sparkDist;

      canvas.drawCircle(
        Offset(sparkX, sparkY),
        2 * flashProgress,
        Paint()
          ..color = Colors.white.withOpacity(flashProgress * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  void _renderDamageParticles(Canvas canvas) {
    for (final particle in _damageParticles) {
      if (!particle.isActive) continue;

      final px = math.cos(particle.angle) * particle.distance;
      final py = math.sin(particle.angle) * particle.distance;
      final alpha = particle.alpha;

      // Particle with glow
      canvas.drawCircle(
        Offset(px, py),
        particle.size * 1.5,
        Paint()
          ..color = type.color.withOpacity(alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      canvas.drawCircle(
        Offset(px, py),
        particle.size * (1 - particle.progress * 0.5),
        Paint()..color = type.color.withOpacity(alpha),
      );
    }
  }

  void _renderTrail(Canvas canvas, [double opacity = 1.0]) {
    for (int i = 0; i < _trailPositions.length; i++) {
      final t = i / _trailPositions.length;
      final alpha = (1 - t) * 0.4 * opacity;
      final trailSize = size.x * 0.3 * (1 - t);

      // Calculate offset from current position
      final offset = _trailPositions[i] - position;

      final trailPaint = Paint()
        ..color = type.color.withOpacity(alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(
        Offset(offset.x, offset.y),
        trailSize,
        trailPaint,
      );
    }
  }

  void _renderTypeEffects(Canvas canvas, double radius, [double opacity = 1.0]) {
    switch (type) {
      case EnemyType.runner:
        // Motion lines
        final motionPaint = Paint()
          ..color = type.color.withOpacity(0.4 * opacity)
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawLine(
          Offset(-radius * 1.5, 0),
          Offset(-radius * 0.8, 0),
          motionPaint,
        );
        break;

      case EnemyType.overloaded:
        // Pulsing energy core
        final coreRadius = radius * 0.4 * (1 + math.sin(_animationPhase * 3) * 0.3);
        final corePaint = Paint()
          ..color = Colors.white.withOpacity(0.8 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset.zero, coreRadius, corePaint);

        // Energy sparks
        for (int i = 0; i < 4; i++) {
          final sparkAngle = _animationPhase * 2 + i * math.pi / 2;
          final sparkDist = radius * 0.6;
          final sparkPaint = Paint()
            ..color = Colors.white.withOpacity(0.6 * opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
          canvas.drawCircle(
            Offset(math.cos(sparkAngle) * sparkDist, math.sin(sparkAngle) * sparkDist),
            2,
            sparkPaint,
          );
        }
        break;

      case EnemyType.juggernaut:
        // Armor ring
        final armorPaint = Paint()
          ..color = type.color.withOpacity(0.6 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(Offset.zero, radius * 0.9, armorPaint);

        // Shield glow
        final shieldPaint = Paint()
          ..color = Colors.white.withOpacity(0.15 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(Offset.zero, radius * 1.1, shieldPaint);
        break;

      case EnemyType.phantom:
        // Glitch/distortion effect - digital scan lines
        final glitchPaint = Paint()
          ..color = type.color.withOpacity(0.5 * opacity)
          ..strokeWidth = 1;

        // Horizontal glitch lines that shift
        for (int i = 0; i < 5; i++) {
          final yOffset = (i - 2) * radius * 0.3;
          final glitchShift = math.sin(_animationPhase * 8 + i) * radius * 0.3;
          canvas.drawLine(
            Offset(-radius + glitchShift, yOffset),
            Offset(radius + glitchShift, yOffset),
            glitchPaint,
          );
        }

        // Digital noise particles around the phantom
        for (int i = 0; i < 8; i++) {
          final noiseAngle = _animationPhase * 3 + i * math.pi / 4;
          final noiseDist = radius * (0.8 + math.sin(_animationPhase * 5 + i) * 0.4);
          final noiseSize = 2.0 + math.sin(_animationPhase * 7 + i * 2) * 1.5;

          // Flicker effect - only show some particles at a time
          if (math.sin(_animationPhase * 10 + i * 3) > 0) {
            final noisePaint = Paint()
              ..color = type.color.withOpacity(0.7 * opacity)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset(
                  math.cos(noiseAngle) * noiseDist,
                  math.sin(noiseAngle) * noiseDist,
                ),
                width: noiseSize,
                height: noiseSize,
              ),
              noisePaint,
            );
          }
        }

        // Ghostly outer ring that phases in/out
        final ringOpacity = (0.3 + math.sin(_animationPhase * 2) * 0.2) * opacity;
        final ringPaint = Paint()
          ..color = type.color.withOpacity(ringOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset.zero, radius * 1.2, ringPaint);

        // Inner data core (when revealed)
        if (_isRevealed) {
          final corePaint = Paint()
            ..color = Colors.white.withOpacity(0.6 * opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          canvas.drawCircle(Offset.zero, radius * 0.3, corePaint);
        }
        break;
    }
  }

  void _renderSlowEffect(Canvas canvas, double radius) {
    final slowPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

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
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset.zero, radius * 1.4, auraPaint);
  }

  void _renderHealthBar(Canvas canvas) {
    final barWidth = 32.0 * type.sizeMult;
    const barHeight = 5.0;
    final barY = -22.0 * type.sizeMult;

    // Background with glow
    final bgRect = Rect.fromCenter(
      center: Offset(0, barY),
      width: barWidth + 2,
      height: barHeight + 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFF000000).withOpacity(0.6),
    );

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(2)),
      Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
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
        healthColor,
        healthColor.withOpacity(0.7),
      ],
    ).createShader(fillRect.outerRect);

    canvas.drawRRect(fillRect, Paint()..shader = gradient);

    // Glow on health bar
    canvas.drawRRect(
      fillRect,
      Paint()
        ..color = healthColor.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
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

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;

    // Animation updates
    _animationPhase += dt * 4;

    // Walk animation based on speed
    final walkSpeed = switch (type) {
      EnemyType.runner => 15.0,
      EnemyType.overloaded => 18.0,
      EnemyType.juggernaut => 8.0,
      EnemyType.phantom => 12.0,
    };
    _walkPhase += dt * walkSpeed;

    // Calculate speed indicator for motion effects
    final currentSpeed = (position - _lastPosition).length / dt;
    _speedIndicator = (currentSpeed / (_baseSpeed * 2)).clamp(0.0, 1.0);

    // Walking bob effect - different per type
    final bobAmount = switch (type) {
      EnemyType.runner => 2.0,
      EnemyType.overloaded => 1.5,
      EnemyType.juggernaut => 3.0,
      EnemyType.phantom => 0.5,
    };

    _verticalBob = math.sin(_walkPhase * 2) * bobAmount * _speedIndicator;
    _wobbleOffset = math.sin(_walkPhase) * bobAmount * 0.3 * _speedIndicator;

    // Store last position for motion blur
    _lastPosition = position.clone();

    // Pulse scale decay
    if (_pulseScale > 1.0) {
      _pulseScale = math.max(1.0, _pulseScale - dt * 2);
    }

    // Hit flash decay
    if (_hitFlashTimer > 0) {
      _hitFlashTimer -= dt;
    }

    // Update damage particles
    _damageParticles.removeWhere((p) => !p.isActive);
    for (final particle in _damageParticles) {
      particle.update(dt);
    }

    // Update trail
    _trailUpdateTimer += dt;
    if (_trailUpdateTimer >= _trailUpdateInterval) {
      _trailUpdateTimer = 0;
      // Shift trail positions
      for (int i = _trailPositions.length - 1; i > 0; i--) {
        _trailPositions[i] = _trailPositions[i - 1].clone();
      }
      _trailPositions[0] = position.clone();
    }

    // Update slow effect
    if (_slowDuration > 0) {
      _slowDuration -= dt;
      if (_slowDuration <= 0) {
        _slowFactor = 1.0;
        _slowDuration = 0;
      }
    }

    // Update phantom reveal timer
    if (isPhantom && _isRevealed && _revealTimer > 0) {
      _revealTimer -= dt;
      if (_revealTimer <= 0) {
        _isRevealed = false;
        _revealTimer = 0;
      }
    }

    if (path.isEmpty || _currentTargetIndex >= path.length) {
      // Reached the base
      onReachBase?.call(this);
      removeFromParent();
      return;
    }

    final target = path[_currentTargetIndex];
    final direction = (target - position);
    final distance = direction.length;

    if (distance < 1) {
      _currentTargetIndex++;
      return;
    }

    final step = direction.normalized() * speed * dt;
    if (step.length >= distance) {
      position = target;
      _currentTargetIndex++;
    } else {
      position += step;
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
    distance += speed * dt * (1 - progress * 0.5); // Slow down over time
  }
}
