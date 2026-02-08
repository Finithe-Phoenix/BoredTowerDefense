import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CACHED STATIC PAINTS FOR ALL PARTICLES - Avoid per-frame allocations
// ═══════════════════════════════════════════════════════════════════════════
final Paint _particleGlowPaint = Paint();
final Paint _particleMainPaint = Paint();
final Paint _particleTrailPaint = Paint()
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
final Paint _particleSparkCenterPaint = Paint();
final Paint _particleSparkRayPaint = Paint()
  ..strokeCap = StrokeCap.round;
final Path _particleReusablePath = Path();
final List<Offset> _particleStarUnitPoints = List<Offset>.unmodifiable(
  _buildStarUnitPoints(),
);
const List<Offset> _particleSparkDirs = [
  Offset(1, 0),
  Offset(0, 1),
  Offset(-1, 0),
  Offset(0, -1),
];

List<Offset> _buildStarUnitPoints() {
  const points = 5;
  const innerRatio = 0.4;
  final result = <Offset>[];
  for (int i = 0; i < points * 2; i++) {
    final angle = (i * math.pi / points) - math.pi / 2;
    final radius = i.isEven ? 1.0 : innerRatio;
    result.add(Offset(math.cos(angle) * radius, math.sin(angle) * radius));
  }
  return result;
}

// Cached MaskFilter for common blur values
const MaskFilter _blur2 = MaskFilter.blur(BlurStyle.normal, 2);

/// Particle shapes for visual variety
enum ParticleShape {
  circle,
  square,
  triangle,
  star,
  diamond,
  line,
  spark,
}

/// Emitter patterns
enum EmitterPattern {
  burst,    // All particles at once
  stream,   // Continuous emission
  ring,     // Particles in a ring
  cone,     // Particles in a cone direction
  spiral,   // Spiral outward pattern
}

/// A simple particle for visual effects - with object pooling
class Particle {
  // ═══════════════════════════════════════════════════════════════════════════
  // OBJECT POOLING - Avoid per-particle allocations
  // ═══════════════════════════════════════════════════════════════════════════
  static const int _maxPoolSize = 200;
  static final List<Particle> _pool = [];

  /// Pre-allocated trail vectors pool (max trail length = 10)
  static const int _maxTrailLength = 10;

  /// Spawn a particle from the pool or create new one
  static Particle spawn({
    required Vector2 position,
    required Vector2 velocity,
    required Color color,
    required double lifetime,
    double size = 4.0,
    bool fadeOut = true,
    ParticleShape shape = ParticleShape.circle,
    double gravity = 0,
    double drag = 0.98,
    bool spin = false,
    double spinSpeed = 3.0,
    bool hasTrail = false,
    int trailLength = 5,
    Color? colorEnd,
    bool glow = true,
    double glowRadius = 4.0,
    bool shrink = true,
  }) {
    Particle particle;
    if (_pool.isNotEmpty) {
      particle = _pool.removeLast();
      particle._reset(
        position: position,
        velocity: velocity,
        color: color,
        lifetime: lifetime,
        size: size,
        fadeOut: fadeOut,
        shape: shape,
        gravity: gravity,
        drag: drag,
        spin: spin,
        spinSpeed: spinSpeed,
        hasTrail: hasTrail,
        trailLength: trailLength,
        colorEnd: colorEnd,
        glow: glow,
        glowRadius: glowRadius,
        shrink: shrink,
      );
    } else {
      particle = Particle._internal(
        position: position,
        velocity: velocity,
        color: color,
        lifetime: lifetime,
        size: size,
        fadeOut: fadeOut,
        shape: shape,
        gravity: gravity,
        drag: drag,
        spin: spin,
        spinSpeed: spinSpeed,
        hasTrail: hasTrail,
        trailLength: trailLength,
        colorEnd: colorEnd,
        glow: glow,
        glowRadius: glowRadius,
        shrink: shrink,
      );
    }
    return particle;
  }

  /// Return particle to pool for reuse
  void recycle() {
    if (_pool.length < _maxPoolSize) {
      _pool.add(this);
    }
  }

  /// Clear the pool (call between games)
  static void clearPool() {
    _pool.clear();
  }

  // Private constructor for internal use
  Particle._internal({
    required Vector2 position,
    required Vector2 velocity,
    required this.color,
    required this.lifetime,
    this.size = 4.0,
    this.fadeOut = true,
    this.shape = ParticleShape.circle,
    this.gravity = 0,
    this.drag = 0.98,
    this.spin = false,
    this.spinSpeed = 3.0,
    this.hasTrail = false,
    this.trailLength = 5,
    this.colorEnd,
    this.glow = true,
    this.glowRadius = 4.0,
    this.shrink = true,
  }) : remainingLife = lifetime,
       _initialSize = size,
       _rotation = 0,
       // Pre-allocate position and velocity vectors
       this.position = position.clone(),
       this.velocity = velocity.clone() {
    _velocityAngle = shape == ParticleShape.line
        ? math.atan2(this.velocity.y, this.velocity.x)
        : 0;
    // Pre-allocate trail vectors if needed
    if (hasTrail && trailLength > 0) {
      final len = trailLength.clamp(1, _maxTrailLength);
      _trail = List.generate(len, (_) => this.position.clone());
    }
  }

  // Legacy constructor for backwards compatibility
  Particle({
    required Vector2 position,
    required Vector2 velocity,
    required this.color,
    required this.lifetime,
    this.size = 4.0,
    this.fadeOut = true,
    this.shape = ParticleShape.circle,
    this.gravity = 0,
    this.drag = 0.98,
    this.spin = false,
    this.spinSpeed = 3.0,
    this.hasTrail = false,
    this.trailLength = 5,
    this.colorEnd,
    this.glow = true,
    this.glowRadius = 4.0,
    this.shrink = true,
  }) : remainingLife = lifetime,
       _initialSize = size,
       _rotation = 0,
       this.position = position.clone(),
       this.velocity = velocity.clone() {
    _velocityAngle = shape == ParticleShape.line
        ? math.atan2(this.velocity.y, this.velocity.x)
        : 0;
    if (hasTrail && trailLength > 0) {
      final len = trailLength.clamp(1, _maxTrailLength);
      _trail = List.generate(len, (_) => this.position.clone());
    }
  }

  /// Reset particle state for reuse from pool
  void _reset({
    required Vector2 position,
    required Vector2 velocity,
    required Color color,
    required double lifetime,
    double size = 4.0,
    bool fadeOut = true,
    ParticleShape shape = ParticleShape.circle,
    double gravity = 0,
    double drag = 0.98,
    bool spin = false,
    double spinSpeed = 3.0,
    bool hasTrail = false,
    int trailLength = 5,
    Color? colorEnd,
    bool glow = true,
    double glowRadius = 4.0,
    bool shrink = true,
  }) {
    // Reuse existing Vector2 objects
    this.position.setFrom(position);
    this.velocity.setFrom(velocity);
    this.color = color;
    this.colorEnd = colorEnd;
    this.lifetime = lifetime;
    this.remainingLife = lifetime;
    this.size = size;
    _initialSize = size;
    this.fadeOut = fadeOut;
    this.shape = shape;
    this.gravity = gravity;
    this.drag = drag;
    this.spin = spin;
    this.spinSpeed = spinSpeed;
    this.hasTrail = hasTrail;
    this.trailLength = trailLength;
    this.glow = glow;
    this.glowRadius = glowRadius;
    this.shrink = shrink;
    _rotation = 0;
    _velocityAngle = shape == ParticleShape.line
        ? math.atan2(this.velocity.y, this.velocity.x)
        : 0;

    // Handle trail - reuse existing trail vectors if possible
    if (hasTrail && trailLength > 0) {
      final len = trailLength.clamp(1, _maxTrailLength);
      if (_trail == null || _trail!.length != len) {
        _trail = List.generate(len, (_) => this.position.clone());
      } else {
        // Reuse existing trail vectors
        for (final v in _trail!) {
          v.setFrom(this.position);
        }
      }
    } else {
      _trail = null;
    }
  }

  final Vector2 position;
  final Vector2 velocity;
  Color color;
  Color? colorEnd;
  double lifetime;
  double remainingLife;
  double size;
  bool fadeOut;
  ParticleShape shape;
  double gravity;
  double drag;
  bool spin;
  double spinSpeed;
  bool hasTrail;
  int trailLength;
  bool glow;
  double glowRadius;
  bool shrink;

  double _initialSize;
  double _rotation;
  double _velocityAngle = 0;
  List<Vector2>? _trail;

  bool get isDead => remainingLife <= 0;

  double get lifePercent => (remainingLife / lifetime).clamp(0.0, 1.0);
  double get progress => 1.0 - lifePercent;

  void update(double dt) {
    // Update trail - reuse Vector2 objects instead of cloning
    if (_trail != null) {
      for (int i = _trail!.length - 1; i > 0; i--) {
        _trail![i].setFrom(_trail![i - 1]);
      }
      _trail![0].setFrom(position);
    }

    // Apply gravity
    velocity.y += gravity * dt;

    // Apply drag
    velocity.scale(drag);

    // Move - avoid creating new Vector2
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;
    remainingLife -= dt;

    // Update size
    if (shrink) {
      size = _initialSize * lifePercent;
    }

    // Update rotation
    if (spin) {
      _rotation += spinSpeed * dt;
    }
    if (shape == ParticleShape.line) {
      _velocityAngle = math.atan2(velocity.y, velocity.x);
    }
  }

  Color get currentColor {
    if (colorEnd == null) {
      return fadeOut ? color.withOpacity(lifePercent.clamp(0.0, 1.0)) : color;
    }

    // Lerp between colors
    final t = progress;
    final r = (color.red + (colorEnd!.red - color.red) * t).round().clamp(0, 255);
    final g = (color.green + (colorEnd!.green - color.green) * t).round().clamp(0, 255);
    final b = (color.blue + (colorEnd!.blue - color.blue) * t).round().clamp(0, 255);
    final a = fadeOut ? (lifePercent * 255).round().clamp(0, 255) : 255;

    return Color.fromARGB(a, r, g, b);
  }

  void render(Canvas canvas) {
    if (isDead || size <= 0) return;

    final particleColor = currentColor;
    final alpha = particleColor.opacity;
    if (alpha <= 0.01) return;

    // Render trail first
    if (_trail != null && hasTrail) {
      _renderTrail(canvas, particleColor);
    }

    // Render glow using cached paint
    if (glow && alpha > 0.1) {
      _particleGlowPaint
        ..color = particleColor.withOpacity(alpha * 0.3)
        ..maskFilter = _blur2; // Use cached MaskFilter instead of creating new one
      canvas.drawCircle(
        Offset(position.x, position.y),
        size + glowRadius,
        _particleGlowPaint,
      );
    }

    // Render particle based on shape
    canvas.save();
    canvas.translate(position.x, position.y);
    if (spin) {
      canvas.rotate(_rotation);
    }

    _particleMainPaint.color = particleColor;

    switch (shape) {
      case ParticleShape.circle:
        canvas.drawCircle(Offset.zero, size, _particleMainPaint);
        break;

      case ParticleShape.square:
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: size * 2, height: size * 2),
          _particleMainPaint,
        );
        break;

      case ParticleShape.triangle:
        _drawTriangle(canvas, size);
        break;

      case ParticleShape.star:
        _drawStar(canvas, size);
        break;

      case ParticleShape.diamond:
        _drawDiamond(canvas, size);
        break;

      case ParticleShape.line:
        _drawLine(canvas, size);
        break;

      case ParticleShape.spark:
        _drawSpark(canvas, size, particleColor);
        break;
    }

    canvas.restore();
  }

  void _renderTrail(Canvas canvas, Color baseColor) {
    if (_trail == null) return;
    if (baseColor.opacity <= 0.01) return;

    // Set MaskFilter once for all trail segments
    _particleTrailPaint.maskFilter = _blur2;

    for (int i = 1; i < _trail!.length; i++) {
      final t = i / _trail!.length;
      final trailAlpha = baseColor.opacity * (1 - t) * 0.5;
      final trailSize = size * (1 - t * 0.7);

      _particleTrailPaint.color = baseColor.withOpacity(trailAlpha.clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(_trail![i].x, _trail![i].y),
        trailSize,
        _particleTrailPaint,
      );
    }
  }

  void _drawTriangle(Canvas canvas, double size) {
    _particleReusablePath.reset();
    _particleReusablePath.moveTo(0, -size);
    _particleReusablePath.lineTo(size * 0.866, size * 0.5);
    _particleReusablePath.lineTo(-size * 0.866, size * 0.5);
    _particleReusablePath.close();
    canvas.drawPath(_particleReusablePath, _particleMainPaint);
  }

  void _drawStar(Canvas canvas, double size) {
    _particleReusablePath.reset();
    for (int i = 0; i < _particleStarUnitPoints.length; i++) {
      final p = _particleStarUnitPoints[i];
      final x = p.dx * size;
      final y = p.dy * size;
      if (i == 0) {
        _particleReusablePath.moveTo(x, y);
      } else {
        _particleReusablePath.lineTo(x, y);
      }
    }
    _particleReusablePath.close();
    canvas.drawPath(_particleReusablePath, _particleMainPaint);
  }

  void _drawDiamond(Canvas canvas, double size) {
    _particleReusablePath.reset();
    _particleReusablePath.moveTo(0, -size);
    _particleReusablePath.lineTo(size * 0.6, 0);
    _particleReusablePath.lineTo(0, size);
    _particleReusablePath.lineTo(-size * 0.6, 0);
    _particleReusablePath.close();
    canvas.drawPath(_particleReusablePath, _particleMainPaint);
  }

  void _drawLine(Canvas canvas, double size) {
    // Draw line in velocity direction
    canvas.rotate(_velocityAngle);
    _particleMainPaint.strokeWidth = size * 0.3;
    canvas.drawLine(
      Offset(-size, 0),
      Offset(size, 0),
      _particleMainPaint,
    );
  }

  void _drawSpark(Canvas canvas, double size, Color color) {
    // Central bright point
    _particleSparkCenterPaint.color = Colors.white.withOpacity(color.opacity);
    canvas.drawCircle(
      Offset.zero,
      size * 0.5,
      _particleSparkCenterPaint,
    );

    // Four pointed rays
    _particleSparkRayPaint
      ..color = color
      ..strokeWidth = size * 0.3;

    for (int i = 0; i < _particleSparkDirs.length; i++) {
      final length = i.isEven ? size * 1.5 : size;
      final dir = _particleSparkDirs[i];
      canvas.drawLine(
        Offset.zero,
        Offset(dir.dx * length, dir.dy * length),
        _particleSparkRayPaint,
      );
    }
  }
}

/// Configuration for advanced particle emitters
class ParticleEmitterConfig {
  const ParticleEmitterConfig({
    this.particleCount = 20,
    this.shape = ParticleShape.circle,
    this.pattern = EmitterPattern.burst,
    this.color = const Color(0xFF00FFFF),
    this.colorEnd,
    this.minSpeed = 50,
    this.maxSpeed = 150,
    this.minSize = 2,
    this.maxSize = 6,
    this.minLifetime = 0.5,
    this.maxLifetime = 1.5,
    this.gravity = 0,
    this.drag = 0.98,
    this.fadeOut = true,
    this.shrink = true,
    this.hasTrail = false,
    this.trailLength = 5,
    this.glow = true,
    this.glowRadius = 4,
    this.spin = false,
    this.spinSpeed = 3,
    this.coneAngle = math.pi / 4,
    this.coneDirection = 0,
    this.emissionRate = 10, // particles per second for stream
  });

  final int particleCount;
  final ParticleShape shape;
  final EmitterPattern pattern;
  final Color color;
  final Color? colorEnd;
  final double minSpeed;
  final double maxSpeed;
  final double minSize;
  final double maxSize;
  final double minLifetime;
  final double maxLifetime;
  final double gravity;
  final double drag;
  final bool fadeOut;
  final bool shrink;
  final bool hasTrail;
  final int trailLength;
  final bool glow;
  final double glowRadius;
  final bool spin;
  final double spinSpeed;
  final double coneAngle;
  final double coneDirection;
  final double emissionRate;

  /// Create a preset for neon sparkles
  static ParticleEmitterConfig neonSparkle({
    Color color = const Color(0xFF00FFFF),
    int count = 15,
  }) {
    return ParticleEmitterConfig(
      particleCount: count,
      shape: ParticleShape.spark,
      pattern: EmitterPattern.burst,
      color: color,
      colorEnd: Colors.white,
      minSpeed: 80,
      maxSpeed: 200,
      minSize: 2,
      maxSize: 5,
      minLifetime: 0.3,
      maxLifetime: 0.8,
      gravity: 50,
      drag: 0.95,
      hasTrail: true,
      trailLength: 4,
      glow: true,
      glowRadius: 6,
    );
  }

  /// Create a preset for fire particles
  static ParticleEmitterConfig fire({
    int count = 30,
  }) {
    return ParticleEmitterConfig(
      particleCount: count,
      shape: ParticleShape.circle,
      pattern: EmitterPattern.cone,
      color: const Color(0xFFFF6600),
      colorEnd: const Color(0xFFFFDD00),
      minSpeed: 40,
      maxSpeed: 100,
      minSize: 3,
      maxSize: 8,
      minLifetime: 0.4,
      maxLifetime: 1.0,
      gravity: -80, // Rise upward
      drag: 0.97,
      fadeOut: true,
      shrink: true,
      glow: true,
      glowRadius: 8,
      coneAngle: math.pi / 6,
      coneDirection: -math.pi / 2, // Upward
    );
  }

  /// Create a preset for magic/mystical particles
  static ParticleEmitterConfig magic({
    Color color = const Color(0xFFFF00FF),
    int count = 25,
  }) {
    return ParticleEmitterConfig(
      particleCount: count,
      shape: ParticleShape.star,
      pattern: EmitterPattern.spiral,
      color: color,
      colorEnd: Colors.white,
      minSpeed: 30,
      maxSpeed: 80,
      minSize: 3,
      maxSize: 7,
      minLifetime: 0.8,
      maxLifetime: 1.5,
      gravity: 0,
      drag: 0.99,
      spin: true,
      spinSpeed: 5,
      glow: true,
      glowRadius: 10,
    );
  }

  /// Create a preset for continuous stream
  static ParticleEmitterConfig stream({
    Color color = const Color(0xFF00FF88),
    double rate = 20,
  }) {
    return ParticleEmitterConfig(
      particleCount: 1, // Per emission
      shape: ParticleShape.circle,
      pattern: EmitterPattern.stream,
      color: color,
      minSpeed: 100,
      maxSpeed: 150,
      minSize: 2,
      maxSize: 4,
      minLifetime: 0.5,
      maxLifetime: 1.0,
      gravity: 30,
      drag: 0.98,
      hasTrail: true,
      trailLength: 3,
      emissionRate: rate,
    );
  }
}

/// Component for rendering particle effects (enhanced version)
class ParticleEmitter extends Component {
  ParticleEmitter({
    required this.position,
    this.maxParticles = 100,
    this.config,
    this.autoRemove = false,
  }) : _spiralAngle = 0,
       _emissionAccumulator = 0 {
    _rngState = 0x6d2b79f5 ^ position.hashCode;
  }

  final Vector2 position;
  final int maxParticles;
  final ParticleEmitterConfig? config;
  final bool autoRemove;
  final List<Particle> _particles = [];
  final Vector2 _tempVelocity = Vector2.zero();
  final Vector2 _tempPosition = Vector2.zero();
  int _rngState = 0x6d2b79f5;
  double _spiralAngle;
  double _emissionAccumulator;
  bool _hasEmittedBurst = false;

  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }

  double _nextUnit() => _lcgNext() / 0x7fffffff;

  int _nextInt(int max) => max <= 0 ? 0 : _lcgNext() % max;

  bool get isEmpty => _particles.isEmpty;

  @override
  void onMount() {
    super.onMount();
    // Emit initial burst if configured
    if (config != null && config!.pattern != EmitterPattern.stream && !_hasEmittedBurst) {
      _emitConfiguredBurst();
      _hasEmittedBurst = true;
    }
  }

  void _emitConfiguredBurst() {
    if (config == null) return;
    final count = _scaledCount(config!.particleCount);
    if (config!.pattern == EmitterPattern.ring && count > 0) {
      _emitConfiguredRingBurst(count);
      return;
    }
    for (int i = 0; i < count; i++) {
      _emitConfiguredParticle(i, count);
    }
  }

  void _emitConfiguredRingBurst(int count) {
    if (config == null) return;
    if (_particles.length >= maxParticles) return;
    final angleStep = (math.pi * 2) / count;
    final sinStep = math.sin(angleStep);
    final cosStep = math.cos(angleStep);
    var dirX = 1.0;
    var dirY = 0.0;
    for (int i = 0; i < count && _particles.length < maxParticles; i++) {
      _emitConfiguredParticleWithDir(dirX, dirY);
      final nextX = dirX * cosStep - dirY * sinStep;
      final nextY = dirX * sinStep + dirY * cosStep;
      dirX = nextX;
      dirY = nextY;
    }
  }

  void _emitConfiguredParticle(int index, int total) {
    if (_particles.length >= maxParticles || config == null) return;

    double angle;

    switch (config!.pattern) {
      case EmitterPattern.burst:
        angle = _nextUnit() * math.pi * 2;
        break;

      case EmitterPattern.ring:
        angle = (index / total) * math.pi * 2;
        break;

      case EmitterPattern.cone:
        final spread = config!.coneAngle;
        angle = config!.coneDirection + (_nextUnit() - 0.5) * spread;
        break;

      case EmitterPattern.spiral:
        _spiralAngle += 0.3;
        angle = _spiralAngle;
        break;

      case EmitterPattern.stream:
        angle = config!.coneDirection + (_nextUnit() - 0.5) * config!.coneAngle;
        break;
    }

    final speed = config!.minSpeed +
        _nextUnit() * (config!.maxSpeed - config!.minSpeed);
    final size = config!.minSize +
        _nextUnit() * (config!.maxSize - config!.minSize);
    final lifetime = config!.minLifetime +
        _nextUnit() * (config!.maxLifetime - config!.minLifetime);

    final quality = GameParticles.instance;
    final hasTrail = config!.hasTrail && quality.allowTrails;
    final glow = config!.glow && quality.allowGlow;
    final trailLength = hasTrail ? config!.trailLength : 0;

    _particles.add(Particle.spawn(
      position: position,
      velocity: _tempVelocity..setValues(math.cos(angle) * speed, math.sin(angle) * speed),
      color: config!.color,
      colorEnd: config!.colorEnd,
      lifetime: lifetime,
      size: size,
      shape: config!.shape,
      gravity: config!.gravity,
      drag: config!.drag,
      fadeOut: config!.fadeOut,
      shrink: config!.shrink,
      hasTrail: hasTrail,
      trailLength: trailLength,
      glow: glow,
      glowRadius: glow ? config!.glowRadius : 0,
      spin: config!.spin,
      spinSpeed: config!.spinSpeed,
    ));
  }

  void _emitConfiguredParticleWithDir(double dirX, double dirY) {
    if (_particles.length >= maxParticles || config == null) return;
    final speed = config!.minSpeed +
        _nextUnit() * (config!.maxSpeed - config!.minSpeed);
    final size = config!.minSize +
        _nextUnit() * (config!.maxSize - config!.minSize);
    final lifetime = config!.minLifetime +
        _nextUnit() * (config!.maxLifetime - config!.minLifetime);

    final quality = GameParticles.instance;
    final hasTrail = config!.hasTrail && quality.allowTrails;
    final glow = config!.glow && quality.allowGlow;
    final trailLength = hasTrail ? config!.trailLength : 0;

    _particles.add(Particle.spawn(
      position: position,
      velocity: _tempVelocity..setValues(dirX * speed, dirY * speed),
      color: config!.color,
      colorEnd: config!.colorEnd,
      lifetime: lifetime,
      size: size,
      shape: config!.shape,
      gravity: config!.gravity,
      drag: config!.drag,
      fadeOut: config!.fadeOut,
      shrink: config!.shrink,
      hasTrail: hasTrail,
      trailLength: trailLength,
      glow: glow,
      glowRadius: glow ? config!.glowRadius : 0,
      spin: config!.spin,
      spinSpeed: config!.spinSpeed,
    ));
  }

  /// Emit an explosion of particles
  void emitExplosion({
    required Vector2 center,
    required Color color,
    int count = 20,
    double speed = 100,
    double lifetime = 0.5,
    double size = 4,
    ParticleShape shape = ParticleShape.circle,
    bool hasTrail = false,
    Color? colorEnd,
  }) {
    final scaledCount = _scaledCount(count);
    final quality = GameParticles.instance;
    for (int i = 0; i < scaledCount && _particles.length < maxParticles; i++) {
      final angle = _nextUnit() * math.pi * 2;
      final spd = speed * (0.5 + _nextUnit() * 0.5);

      _particles.add(Particle.spawn(
        position: center,
        velocity: _tempVelocity..setValues(math.cos(angle) * spd, math.sin(angle) * spd),
        color: color,
        colorEnd: colorEnd,
        lifetime: lifetime * (0.5 + _nextUnit() * 0.5),
        size: size * (0.5 + _nextUnit() * 0.5),
        shape: shape,
        hasTrail: hasTrail && quality.allowTrails,
        trailLength: hasTrail && quality.allowTrails ? 4 : 0,
        glow: quality.allowGlow,
        glowRadius: quality.allowGlow ? 4 : 0,
      ));
    }
  }

  /// Emit a directional burst
  void emitBurst({
    required Vector2 start,
    required Vector2 direction,
    required Color color,
    int count = 10,
    double speed = 150,
    double spread = 0.5,
    double lifetime = 0.3,
    ParticleShape shape = ParticleShape.circle,
  }) {
    final baseAngle = math.atan2(direction.y, direction.x);

    final scaledCount = _scaledCount(count);
    final quality = GameParticles.instance;
    for (int i = 0; i < scaledCount && _particles.length < maxParticles; i++) {
      final angle = baseAngle + (_nextUnit() - 0.5) * spread;
      final spd = speed * (0.7 + _nextUnit() * 0.3);

      _particles.add(Particle.spawn(
        position: start,
        velocity: _tempVelocity..setValues(math.cos(angle) * spd, math.sin(angle) * spd),
        color: color,
        lifetime: lifetime * (0.7 + _nextUnit() * 0.3),
        size: 3 + _nextUnit() * 2,
        shape: shape,
        glow: quality.allowGlow,
        glowRadius: quality.allowGlow ? 3 : 0,
      ));
    }
  }

  /// Emit a trail particle
  void emitTrail({
    required Vector2 position,
    required Color color,
    double size = 3,
    double lifetime = 0.2,
    ParticleShape shape = ParticleShape.circle,
  }) {
    if (_particles.length >= maxParticles) return;
    final quality = GameParticles.instance;
    if (!quality.allowTrails) return;

    _particles.add(Particle.spawn(
      position: position,
      velocity: _tempVelocity
        ..setValues((_nextUnit() - 0.5) * 20, (_nextUnit() - 0.5) * 20),
      color: color,
      lifetime: lifetime,
      size: size,
      shape: shape,
    ));
  }

  /// Emit a ring of particles (for pulse effect)
  void emitRing({
    required Vector2 center,
    required Color color,
    required double radius,
    int count = 30,
    double lifetime = 0.5,
    ParticleShape shape = ParticleShape.circle,
    double speed = 50,
  }) {
    final scaledCount = _scaledCount(count);
    final quality = GameParticles.instance;
    if (scaledCount <= 0) return;
    final angleStep = (math.pi * 2) / count;
    final sinStep = math.sin(angleStep);
    final cosStep = math.cos(angleStep);
    var dirX = 1.0;
    var dirY = 0.0;
    for (int i = 0; i < scaledCount && _particles.length < maxParticles; i++) {
      _tempPosition.setValues(
        center.x + dirX * radius,
        center.y + dirY * radius,
      );

      _particles.add(Particle.spawn(
        position: _tempPosition,
        velocity: _tempVelocity..setValues(dirX * speed, dirY * speed),
        color: color,
        lifetime: lifetime,
        size: 4,
        shape: shape,
        glow: quality.allowGlow,
        glowRadius: quality.allowGlow ? 4 : 0,
      ));
      final nextX = dirX * cosStep - dirY * sinStep;
      final nextY = dirX * sinStep + dirY * cosStep;
      dirX = nextX;
      dirY = nextY;
    }
  }

  /// Emit sparks (for impacts, hits)
  void emitSparks({
    required Vector2 center,
    required Color color,
    int count = 12,
    double speed = 120,
    double lifetime = 0.4,
  }) {
    final scaledCount = _scaledCount(count);
    final quality = GameParticles.instance;
    for (int i = 0; i < scaledCount && _particles.length < maxParticles; i++) {
      final angle = _nextUnit() * math.pi * 2;
      final spd = speed * (0.6 + _nextUnit() * 0.4);

      _particles.add(Particle.spawn(
        position: center,
        velocity: _tempVelocity..setValues(math.cos(angle) * spd, math.sin(angle) * spd),
        color: color,
        colorEnd: Colors.white,
        lifetime: lifetime * (0.5 + _nextUnit() * 0.5),
        size: 3 + _nextUnit() * 3,
        shape: ParticleShape.spark,
        gravity: 80,
        drag: 0.94,
        hasTrail: quality.allowTrails,
        trailLength: quality.allowTrails ? 4 : 0,
        glow: quality.allowGlow,
        glowRadius: quality.allowGlow ? 5 : 0,
      ));
    }
  }

  /// Emit magic particles (stars, spiraling)
  void emitMagic({
    required Vector2 center,
    required Color color,
    int count = 15,
    double speed = 60,
    double lifetime = 1.0,
  }) {
    final scaledCount = _scaledCount(count);
    final quality = GameParticles.instance;
    for (int i = 0; i < scaledCount && _particles.length < maxParticles; i++) {
      _spiralAngle += 0.4;
      final spd = speed * (0.5 + _nextUnit() * 0.5);

      _particles.add(Particle.spawn(
        position: center,
        velocity: _tempVelocity..setValues(math.cos(_spiralAngle) * spd, math.sin(_spiralAngle) * spd),
        color: color,
        colorEnd: Colors.white,
        lifetime: lifetime * (0.6 + _nextUnit() * 0.4),
        size: 4 + _nextUnit() * 4,
        shape: ParticleShape.star,
        spin: true,
        spinSpeed: 4 + _nextUnit() * 3,
        glow: quality.allowGlow,
        glowRadius: quality.allowGlow ? 8 : 0,
      ));
    }
  }

  int _scaledCount(int count) {
    final scale = GameParticles.instance.burstScale;
    if (count <= 0) return 0;
    if (scale >= 1) return count;
    final scaled = (count * scale).round();
    return scaled.clamp(1, count);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Stream emission
    if (config != null && config!.pattern == EmitterPattern.stream) {
      _emissionAccumulator += dt * config!.emissionRate;
      while (_emissionAccumulator >= 1) {
        _emitConfiguredParticle(0, 1);
        _emissionAccumulator -= 1;
      }
    }

    for (final particle in _particles) {
      particle.update(dt);
    }

    // Recycle dead particles to pool using efficient single-pass removal
    int writeIndex = 0;
    for (int readIndex = 0; readIndex < _particles.length; readIndex++) {
      final particle = _particles[readIndex];
      if (particle.isDead) {
        particle.recycle(); // Return to pool
      } else {
        if (writeIndex != readIndex) {
          _particles[writeIndex] = particle;
        }
        writeIndex++;
      }
    }
    if (writeIndex < _particles.length) {
      _particles.removeRange(writeIndex, _particles.length);
    }

    // Auto-remove when empty (for configured burst emitters)
    if (autoRemove && isEmpty && config != null && config!.pattern != EmitterPattern.stream) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_particles.isEmpty) return;

    for (final particle in _particles) {
      particle.render(canvas);
    }
  }

  /// Clear all particles
  void clear() {
    _particles.clear();
  }

  /// Stop streaming (for stream emitters)
  void stop() {
    _emissionAccumulator = -999999;
  }
}

/// Global particle system for the game
class GameParticles {
  GameParticles._();
  static final instance = GameParticles._();

  ParticleEmitter? _emitter;
  double burstScale = 1.0;
  bool allowGlow = true;
  bool allowTrails = true;

  void setQuality({
    required double burstScale,
    required bool allowGlow,
    required bool allowTrails,
  }) {
    this.burstScale = burstScale.clamp(0.1, 1.0).toDouble();
    this.allowGlow = allowGlow;
    this.allowTrails = allowTrails;
  }

  void setEmitter(ParticleEmitter emitter) {
    _emitter = emitter;
  }

  void explosion(Vector2 center, Color color, {ParticleShape shape = ParticleShape.circle}) {
    _emitter?.emitExplosion(center: center, color: color, shape: shape);
  }

  void hit(Vector2 position, Color color) {
    _emitter?.emitBurst(
      start: position,
      direction: Vector2(0, -1),
      color: color,
      count: 5,
      speed: 80,
    );
  }

  void trail(Vector2 position, Color color, {ParticleShape shape = ParticleShape.circle}) {
    _emitter?.emitTrail(position: position, color: color, shape: shape);
  }

  void pulse(Vector2 center, Color color, double radius) {
    _emitter?.emitRing(center: center, color: color, radius: radius);
  }

  void sparks(Vector2 center, Color color, {int count = 12}) {
    _emitter?.emitSparks(center: center, color: color, count: count);
  }

  void emitSparks({
    required Vector2 center,
    required Color color,
    int count = 12,
  }) {
    sparks(center, color, count: count);
  }

  void magic(Vector2 center, Color color, {int count = 15}) {
    _emitter?.emitMagic(center: center, color: color, count: count);
  }
}

/// Quick helper to spawn particle effects as standalone components
class ParticleHelper {
  static ParticleEmitter spawnSparkles(Vector2 position, {Color? color}) {
    return ParticleEmitter(
      position: position,
      config: ParticleEmitterConfig.neonSparkle(
        color: color ?? const Color(0xFF00FFFF),
      ),
      autoRemove: true,
    );
  }

  static ParticleEmitter spawnExplosion(Vector2 position, {Color? color, int count = 30}) {
    return ParticleEmitter(
      position: position,
      config: ParticleEmitterConfig(
        particleCount: count,
        shape: ParticleShape.spark,
        pattern: EmitterPattern.burst,
        color: color ?? const Color(0xFFFF6600),
        colorEnd: const Color(0xFFFFDD00),
        minSpeed: 100,
        maxSpeed: 300,
        minSize: 3,
        maxSize: 8,
        minLifetime: 0.3,
        maxLifetime: 0.8,
        gravity: 100,
        drag: 0.94,
        hasTrail: true,
        trailLength: 6,
        glow: true,
        glowRadius: 8,
      ),
      autoRemove: true,
    );
  }

  static ParticleEmitter spawnMagic(Vector2 position, {Color? color}) {
    return ParticleEmitter(
      position: position,
      config: ParticleEmitterConfig.magic(
        color: color ?? const Color(0xFFFF00FF),
      ),
      autoRemove: true,
    );
  }

  static ParticleEmitter spawnRing(Vector2 position, {Color? color, int count = 16}) {
    return ParticleEmitter(
      position: position,
      config: ParticleEmitterConfig(
        particleCount: count,
        shape: ParticleShape.diamond,
        pattern: EmitterPattern.ring,
        color: color ?? const Color(0xFF00FF88),
        minSpeed: 80,
        maxSpeed: 120,
        minSize: 3,
        maxSize: 5,
        minLifetime: 0.4,
        maxLifetime: 0.7,
        drag: 0.96,
        glow: true,
        glowRadius: 5,
      ),
      autoRemove: true,
    );
  }

  static ParticleEmitter spawnHit(Vector2 position, {Color? color}) {
    return ParticleEmitter(
      position: position,
      config: ParticleEmitterConfig(
        particleCount: 8,
        shape: ParticleShape.spark,
        pattern: EmitterPattern.burst,
        color: color ?? const Color(0xFFFFFFFF),
        minSpeed: 60,
        maxSpeed: 150,
        minSize: 2,
        maxSize: 4,
        minLifetime: 0.2,
        maxLifetime: 0.4,
        gravity: 50,
        drag: 0.92,
        hasTrail: true,
        trailLength: 3,
        glow: true,
        glowRadius: 4,
      ),
      autoRemove: true,
    );
  }

  static ParticleEmitter spawnFire(Vector2 position, {int count = 30}) {
    return ParticleEmitter(
      position: position,
      config: ParticleEmitterConfig.fire(count: count),
      autoRemove: true,
    );
  }
}

