import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

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

/// A simple particle for visual effects
class Particle {
  Particle({
    required this.position,
    required this.velocity,
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
       _trail = hasTrail ? List.generate(trailLength, (_) => position.clone()) : null;

  Vector2 position;
  Vector2 velocity;
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

  final double _initialSize;
  double _rotation;
  List<Vector2>? _trail;

  bool get isDead => remainingLife <= 0;

  double get lifePercent => (remainingLife / lifetime).clamp(0.0, 1.0);
  double get progress => 1.0 - lifePercent;

  void update(double dt) {
    // Update trail
    if (_trail != null) {
      for (int i = _trail!.length - 1; i > 0; i--) {
        _trail![i] = _trail![i - 1].clone();
      }
      _trail![0] = position.clone();
    }

    // Apply gravity
    velocity.y += gravity * dt;

    // Apply drag
    velocity.scale(drag);

    // Move
    position += velocity * dt;
    remainingLife -= dt;

    // Update size
    if (shrink) {
      size = _initialSize * lifePercent;
    }

    // Update rotation
    if (spin) {
      _rotation += spinSpeed * dt;
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

    // Render trail first
    if (_trail != null && hasTrail) {
      _renderTrail(canvas, particleColor);
    }

    // Render glow
    if (glow && alpha > 0.1) {
      canvas.drawCircle(
        Offset(position.x, position.y),
        size + glowRadius,
        Paint()
          ..color = particleColor.withOpacity(alpha * 0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius),
      );
    }

    // Render particle based on shape
    canvas.save();
    canvas.translate(position.x, position.y);
    if (spin) {
      canvas.rotate(_rotation);
    }

    final paint = Paint()..color = particleColor;

    switch (shape) {
      case ParticleShape.circle:
        canvas.drawCircle(Offset.zero, size, paint);
        break;

      case ParticleShape.square:
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: size * 2, height: size * 2),
          paint,
        );
        break;

      case ParticleShape.triangle:
        _drawTriangle(canvas, size, paint);
        break;

      case ParticleShape.star:
        _drawStar(canvas, size, paint);
        break;

      case ParticleShape.diamond:
        _drawDiamond(canvas, size, paint);
        break;

      case ParticleShape.line:
        _drawLine(canvas, size, paint);
        break;

      case ParticleShape.spark:
        _drawSpark(canvas, size, paint, particleColor);
        break;
    }

    canvas.restore();
  }

  void _renderTrail(Canvas canvas, Color baseColor) {
    if (_trail == null) return;

    for (int i = 1; i < _trail!.length; i++) {
      final t = i / _trail!.length;
      final trailAlpha = baseColor.opacity * (1 - t) * 0.5;
      final trailSize = size * (1 - t * 0.7);

      canvas.drawCircle(
        Offset(_trail![i].x, _trail![i].y),
        trailSize,
        Paint()
          ..color = baseColor.withOpacity(trailAlpha.clamp(0.0, 1.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  void _drawTriangle(Canvas canvas, double size, Paint paint) {
    final path = Path();
    path.moveTo(0, -size);
    path.lineTo(size * 0.866, size * 0.5);
    path.lineTo(-size * 0.866, size * 0.5);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    const points = 5;
    const innerRatio = 0.4;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final radius = i.isEven ? size : size * innerRatio;
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDiamond(Canvas canvas, double size, Paint paint) {
    final path = Path();
    path.moveTo(0, -size);
    path.lineTo(size * 0.6, 0);
    path.lineTo(0, size);
    path.lineTo(-size * 0.6, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawLine(Canvas canvas, double size, Paint paint) {
    // Draw line in velocity direction
    final angle = math.atan2(velocity.y, velocity.x);
    canvas.rotate(angle);
    canvas.drawLine(
      Offset(-size, 0),
      Offset(size, 0),
      paint..strokeWidth = size * 0.3,
    );
  }

  void _drawSpark(Canvas canvas, double size, Paint paint, Color color) {
    // Central bright point
    canvas.drawCircle(
      Offset.zero,
      size * 0.5,
      Paint()..color = Colors.white.withOpacity(color.opacity),
    );

    // Four pointed rays
    final rayPaint = Paint()
      ..color = color
      ..strokeWidth = size * 0.3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final length = i.isEven ? size * 1.5 : size;
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(angle) * length, math.sin(angle) * length),
        rayPaint,
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
       _emissionAccumulator = 0;

  final Vector2 position;
  final int maxParticles;
  final ParticleEmitterConfig? config;
  final bool autoRemove;
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  double _spiralAngle;
  double _emissionAccumulator;
  bool _hasEmittedBurst = false;

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
    for (int i = 0; i < config!.particleCount; i++) {
      _emitConfiguredParticle(i, config!.particleCount);
    }
  }

  void _emitConfiguredParticle(int index, int total) {
    if (_particles.length >= maxParticles || config == null) return;

    double angle;

    switch (config!.pattern) {
      case EmitterPattern.burst:
        angle = _random.nextDouble() * math.pi * 2;
        break;

      case EmitterPattern.ring:
        angle = (index / total) * math.pi * 2;
        break;

      case EmitterPattern.cone:
        final spread = config!.coneAngle;
        angle = config!.coneDirection + (_random.nextDouble() - 0.5) * spread;
        break;

      case EmitterPattern.spiral:
        _spiralAngle += 0.3;
        angle = _spiralAngle;
        break;

      case EmitterPattern.stream:
        angle = config!.coneDirection + (_random.nextDouble() - 0.5) * config!.coneAngle;
        break;
    }

    final speed = config!.minSpeed +
        _random.nextDouble() * (config!.maxSpeed - config!.minSpeed);
    final size = config!.minSize +
        _random.nextDouble() * (config!.maxSize - config!.minSize);
    final lifetime = config!.minLifetime +
        _random.nextDouble() * (config!.maxLifetime - config!.minLifetime);

    _particles.add(Particle(
      position: position.clone(),
      velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
      color: config!.color,
      colorEnd: config!.colorEnd,
      lifetime: lifetime,
      size: size,
      shape: config!.shape,
      gravity: config!.gravity,
      drag: config!.drag,
      fadeOut: config!.fadeOut,
      shrink: config!.shrink,
      hasTrail: config!.hasTrail,
      trailLength: config!.trailLength,
      glow: config!.glow,
      glowRadius: config!.glowRadius,
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
    for (int i = 0; i < count && _particles.length < maxParticles; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final spd = speed * (0.5 + _random.nextDouble() * 0.5);

      _particles.add(Particle(
        position: center.clone(),
        velocity: Vector2(math.cos(angle) * spd, math.sin(angle) * spd),
        color: color,
        colorEnd: colorEnd,
        lifetime: lifetime * (0.5 + _random.nextDouble() * 0.5),
        size: size * (0.5 + _random.nextDouble() * 0.5),
        shape: shape,
        hasTrail: hasTrail,
        trailLength: 4,
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

    for (int i = 0; i < count && _particles.length < maxParticles; i++) {
      final angle = baseAngle + (_random.nextDouble() - 0.5) * spread;
      final spd = speed * (0.7 + _random.nextDouble() * 0.3);

      _particles.add(Particle(
        position: start.clone(),
        velocity: Vector2(math.cos(angle) * spd, math.sin(angle) * spd),
        color: color,
        lifetime: lifetime * (0.7 + _random.nextDouble() * 0.3),
        size: 3 + _random.nextDouble() * 2,
        shape: shape,
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

    _particles.add(Particle(
      position: position.clone(),
      velocity: Vector2(
        (_random.nextDouble() - 0.5) * 20,
        (_random.nextDouble() - 0.5) * 20,
      ),
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
    for (int i = 0; i < count && _particles.length < maxParticles; i++) {
      final angle = (i / count) * math.pi * 2;
      final pos = Vector2(
        center.x + math.cos(angle) * radius,
        center.y + math.sin(angle) * radius,
      );

      _particles.add(Particle(
        position: pos,
        velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
        color: color,
        lifetime: lifetime,
        size: 4,
        shape: shape,
      ));
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
    for (int i = 0; i < count && _particles.length < maxParticles; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final spd = speed * (0.6 + _random.nextDouble() * 0.4);

      _particles.add(Particle(
        position: center.clone(),
        velocity: Vector2(math.cos(angle) * spd, math.sin(angle) * spd),
        color: color,
        colorEnd: Colors.white,
        lifetime: lifetime * (0.5 + _random.nextDouble() * 0.5),
        size: 3 + _random.nextDouble() * 3,
        shape: ParticleShape.spark,
        gravity: 80,
        drag: 0.94,
        hasTrail: true,
        trailLength: 4,
        glow: true,
        glowRadius: 5,
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
    for (int i = 0; i < count && _particles.length < maxParticles; i++) {
      _spiralAngle += 0.4;
      final spd = speed * (0.5 + _random.nextDouble() * 0.5);

      _particles.add(Particle(
        position: center.clone(),
        velocity: Vector2(math.cos(_spiralAngle) * spd, math.sin(_spiralAngle) * spd),
        color: color,
        colorEnd: Colors.white,
        lifetime: lifetime * (0.6 + _random.nextDouble() * 0.4),
        size: 4 + _random.nextDouble() * 4,
        shape: ParticleShape.star,
        spin: true,
        spinSpeed: 4 + _random.nextDouble() * 3,
        glow: true,
        glowRadius: 8,
      ));
    }
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

    _particles.removeWhere((p) => p.isDead);

    // Auto-remove when empty (for configured burst emitters)
    if (autoRemove && isEmpty && config != null && config!.pattern != EmitterPattern.stream) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

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
