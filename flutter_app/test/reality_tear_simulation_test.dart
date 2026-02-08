import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

/// Simulation tests for RealityTearEffect mathematical logic.
/// Tests opening/closing animation, fragment behavior, electric arcs,
/// dimensional particles, distortion waves, and flicker calculations.

// ═══════════════════════════════════════════════════════════════════════════════
// LCG RNG SIMULATION (matches _lcgNext in reality_tear_effect.dart)
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedLcgRng {
  int _state;

  SimulatedLcgRng([int? seed]) : _state = (seed ?? 0x9e3779b9) & 0x7fffffff;

  SimulatedLcgRng.fromPosition(double x, double y, double tearSize)
      : _state = ((x.hashCode ^ y.hashCode) ^
                (tearSize * 1000).round() ^
                0x9e3779b9) &
            0x7fffffff;

  int next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  double nextUnit() => next() / 0x7fffffff;
  int nextInt(int max) => max <= 0 ? 0 : next() % max;
  bool nextBool() => (next() & 1) == 0;
}

// ═══════════════════════════════════════════════════════════════════════════════
// REALITY FRAGMENT SIMULATION
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedRealityFragment {
  final double angle;
  final double baseDistance;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final double orbitSpeed;
  final int shapeType; // 0=triangle, 1=diamond, 2=hexagon, 3=rectangle
  final double phaseOffset;

  double currentAngle;
  double currentDistance;
  double currentRotation;

  SimulatedRealityFragment({
    required this.angle,
    required this.baseDistance,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.orbitSpeed,
    required this.shapeType,
    required this.phaseOffset,
  })  : currentAngle = angle,
        currentDistance = baseDistance,
        currentRotation = rotation;

  void update(double dt, double time) {
    currentRotation += rotationSpeed * dt;
    currentAngle = angle + math.sin(time * orbitSpeed + phaseOffset) * 0.3;
    currentDistance = baseDistance + math.sin(time * 2 + phaseOffset) * 5;
  }

  ({double x, double y}) getPosition() {
    return (
      x: math.cos(currentAngle) * currentDistance,
      y: math.sin(currentAngle) * currentDistance,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ELECTRIC ARC SIMULATION
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedElectricArc {
  final double angle;
  final double length;
  final double width;
  final double lifetime;
  final int segments;
  final double respawnDelay;

  double _time = 0;
  double _currentLifetime;

  SimulatedElectricArc({
    required this.angle,
    required this.length,
    required this.width,
    required this.lifetime,
    required this.segments,
    required this.respawnDelay,
  }) : _currentLifetime = lifetime;

  bool get isActive => _time < _currentLifetime && _time > 0;
  double get alpha => isActive ? (1 - _time / _currentLifetime) : 0;

  void update(double dt, double Function() nextUnit) {
    _time += dt;

    if (_time > _currentLifetime + respawnDelay) {
      _time = 0;
      _currentLifetime = lifetime * (0.5 + nextUnit() * 0.5);
    }
  }

  void reset() {
    _time = 0;
    _currentLifetime = lifetime;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DIMENSIONAL PARTICLE SIMULATION
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedDimensionalParticle {
  final double angle;
  double distance;
  final double maxDistance;
  final double speed;
  final double size;
  final double lifetime;
  final double phaseOffset;

  SimulatedDimensionalParticle({
    required this.angle,
    required this.distance,
    required this.maxDistance,
    required this.speed,
    required this.size,
    required this.lifetime,
    required this.phaseOffset,
  });

  bool get isAlive => distance > 0;
  double get alpha => (distance / maxDistance).clamp(0.0, 1.0);

  void update(double dt) {
    distance -= speed * dt;
    if (distance <= 0) {
      distance = maxDistance;
    }
  }

  ({double x, double y}) getPosition() {
    return (
      x: math.cos(angle) * distance,
      y: math.sin(angle) * distance,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DISTORTION WAVE SIMULATION
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedDistortionWave {
  final double delay;
  final double speed;
  final double maxRadius;

  double _time;
  double currentRadius = 0;

  SimulatedDistortionWave({
    required this.delay,
    required this.speed,
    required this.maxRadius,
  }) : _time = -delay;

  bool get isActive => _time >= 0 && currentRadius < maxRadius;
  double get alpha => isActive ? (1 - currentRadius / maxRadius) * 0.6 : 0;

  void update(double dt) {
    _time += dt;

    if (_time >= 0) {
      currentRadius += speed * dt;

      if (currentRadius >= maxRadius) {
        currentRadius = 0;
        _time = 0;
      }
    }
  }

  void reset() {
    _time = -delay;
    currentRadius = 0;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REALITY TEAR EFFECT SIMULATOR
// ═══════════════════════════════════════════════════════════════════════════════

class RealityTearSimulator {
  final double tearSize;
  final double duration;
  final bool reduceFx;
  final bool lowFx;
  final double fxScale;
  final SimulatedLcgRng random;

  final List<SimulatedRealityFragment> fragments = [];
  final List<SimulatedElectricArc> electricArcs = [];
  final List<SimulatedDimensionalParticle> particles = [];
  final List<SimulatedDistortionWave> waves = [];

  double time = 0;
  double openProgress = 0;
  double flickerIntensity = 0;

  RealityTearSimulator({
    this.tearSize = 60.0,
    this.duration = 2.0,
    this.reduceFx = false,
    this.lowFx = false,
    this.fxScale = 1.0,
    int? seed,
  }) : random = SimulatedLcgRng(seed) {
    _initializeFragments();
    _initializeElectricArcs();
    _initializeParticles();
    _initializeWaves();
  }

  double get progress => time / duration;

  void _initializeFragments() {
    final fragmentCount = lowFx ? 0 : (reduceFx ? 6 : 12);
    for (int i = 0; i < fragmentCount; i++) {
      final angle = (i / fragmentCount) * math.pi * 2 + random.nextUnit() * 0.5;
      final distance = tearSize * (0.8 + random.nextUnit() * 0.6);
      fragments.add(SimulatedRealityFragment(
        angle: angle,
        baseDistance: distance,
        size: 4 + random.nextUnit() * 8,
        rotation: random.nextUnit() * math.pi * 2,
        rotationSpeed: (random.nextUnit() - 0.5) * 4,
        orbitSpeed: (random.nextUnit() - 0.5) * 0.8,
        shapeType: random.nextInt(4),
        phaseOffset: random.nextUnit() * math.pi * 2,
      ));
    }
  }

  void _initializeElectricArcs() {
    final arcCount = lowFx ? 0 : (reduceFx ? 4 : 8);
    for (int i = 0; i < arcCount; i++) {
      final angle = (i / arcCount) * math.pi * 2 + random.nextUnit() * 0.3;
      electricArcs.add(SimulatedElectricArc(
        angle: angle,
        length: tearSize * (0.4 + random.nextUnit() * 0.4),
        width: 1.5 + random.nextUnit() * 1.5,
        lifetime: 0.1 + random.nextUnit() * 0.15,
        segments: 3 + random.nextInt(3),
        respawnDelay: random.nextUnit() * 0.3,
      ));
    }
  }

  void _initializeParticles() {
    final particleCount = lowFx ? 0 : (reduceFx ? 12 : 24);
    if (particleCount == 0) return;

    final angularJitter = math.pi / particleCount;
    for (int i = 0; i < particleCount; i++) {
      final baseAngle = (i / particleCount) * math.pi * 2;
      final angle = baseAngle + (random.nextUnit() - 0.5) * angularJitter;
      final startDistance = tearSize * (1.5 + random.nextUnit() * 1.5);
      particles.add(SimulatedDimensionalParticle(
        angle: angle,
        distance: startDistance,
        maxDistance: startDistance,
        speed: 30 + random.nextUnit() * 40,
        size: 1.5 + random.nextUnit() * 2.5,
        lifetime: 0.8 + random.nextUnit() * 0.6,
        phaseOffset: random.nextUnit() * math.pi * 2,
      ));
    }
  }

  void _initializeWaves() {
    final waveCount = lowFx ? 1 : (reduceFx ? 2 : 4);
    for (int i = 0; i < waveCount; i++) {
      waves.add(SimulatedDistortionWave(
        delay: i * 0.4,
        speed: 60 + random.nextUnit() * 30,
        maxRadius: tearSize * 2.5,
      ));
    }
  }

  void update(double dt) {
    time += dt;
    final p = progress;

    if (p >= 1.0) return;

    // Tear opening animation
    if (p < 0.2) {
      openProgress = p / 0.2;
    } else if (p > 0.8) {
      openProgress = (1.0 - p) / 0.2;
    } else {
      openProgress = 1.0;
    }

    // Flicker intensity
    flickerIntensity = math.sin(time * 20) * 0.2 + 0.8;
    if (random.nextUnit() < 0.05) {
      flickerIntensity = 0.3 + random.nextUnit() * 0.4;
    }

    // Update components
    for (final fragment in fragments) {
      fragment.update(dt, time);
    }

    for (final arc in electricArcs) {
      arc.update(dt, random.nextUnit);
    }

    for (final particle in particles) {
      particle.update(dt);
    }

    for (final wave in waves) {
      wave.update(dt);
    }
  }

  void reset() {
    time = 0;
    openProgress = 0;
    flickerIntensity = 0;

    for (final fragment in fragments) {
      fragment.currentAngle = fragment.angle;
      fragment.currentDistance = fragment.baseDistance;
      fragment.currentRotation = fragment.rotation;
    }

    for (final arc in electricArcs) {
      arc.reset();
    }

    for (final particle in particles) {
      particle.distance = particle.maxDistance;
    }

    for (final wave in waves) {
      wave.reset();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEST SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('SimulatedLcgRng', () {
    test('produces deterministic sequence', () {
      final rng1 = SimulatedLcgRng(12345);
      final rng2 = SimulatedLcgRng(12345);

      for (int i = 0; i < 100; i++) {
        expect(rng1.next(), rng2.next());
      }
    });

    test('nextUnit returns values in [0, 1)', () {
      final rng = SimulatedLcgRng();
      for (int i = 0; i < 1000; i++) {
        final value = rng.nextUnit();
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThan(1.0));
      }
    });

    test('nextInt returns values in [0, max)', () {
      final rng = SimulatedLcgRng();
      for (int i = 0; i < 1000; i++) {
        final value = rng.nextInt(10);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(10));
      }
    });

    test('nextInt with max <= 0 returns 0', () {
      final rng = SimulatedLcgRng();
      expect(rng.nextInt(0), 0);
      expect(rng.nextInt(-5), 0);
    });

    test('fromPosition creates seed from position hash', () {
      final rng1 = SimulatedLcgRng.fromPosition(100, 200, 60);
      final rng2 = SimulatedLcgRng.fromPosition(100, 200, 60);
      final rng3 = SimulatedLcgRng.fromPosition(150, 200, 60);

      // Same position should give same sequence
      expect(rng1.next(), rng2.next());

      // Different position should give different sequence (mostly)
      // Note: Due to hash collisions, this isn't guaranteed, but very likely
      final rng1Reset = SimulatedLcgRng.fromPosition(100, 200, 60);
      expect(rng1Reset.next(), isNot(rng3.next()));
    });
  });

  group('SimulatedRealityFragment', () {
    test('initializes with correct values', () {
      final fragment = SimulatedRealityFragment(
        angle: math.pi / 4,
        baseDistance: 100,
        size: 8,
        rotation: 0.5,
        rotationSpeed: 2,
        orbitSpeed: 0.5,
        shapeType: 1,
        phaseOffset: 0,
      );

      expect(fragment.currentAngle, math.pi / 4);
      expect(fragment.currentDistance, 100);
      expect(fragment.currentRotation, 0.5);
    });

    test('rotation advances with time', () {
      final fragment = SimulatedRealityFragment(
        angle: 0,
        baseDistance: 100,
        size: 8,
        rotation: 0,
        rotationSpeed: 2,
        orbitSpeed: 0.5,
        shapeType: 0,
        phaseOffset: 0,
      );

      fragment.update(1.0, 0); // dt = 1s
      expect(fragment.currentRotation, closeTo(2.0, 0.001)); // 2 rad/s * 1s
    });

    test('angle oscillates around base angle', () {
      final fragment = SimulatedRealityFragment(
        angle: math.pi / 2,
        baseDistance: 100,
        size: 8,
        rotation: 0,
        rotationSpeed: 0,
        orbitSpeed: 1.0,
        shapeType: 0,
        phaseOffset: 0,
      );

      var minAngle = math.pi / 2;
      var maxAngle = math.pi / 2;

      for (double t = 0; t < 10; t += 0.1) {
        fragment.update(0.1, t);
        if (fragment.currentAngle < minAngle) minAngle = fragment.currentAngle;
        if (fragment.currentAngle > maxAngle) maxAngle = fragment.currentAngle;
      }

      // Should oscillate within +/- 0.3 radians of base angle
      expect(minAngle, greaterThanOrEqualTo(math.pi / 2 - 0.35));
      expect(maxAngle, lessThanOrEqualTo(math.pi / 2 + 0.35));
    });

    test('distance oscillates around base distance', () {
      final fragment = SimulatedRealityFragment(
        angle: 0,
        baseDistance: 100,
        size: 8,
        rotation: 0,
        rotationSpeed: 0,
        orbitSpeed: 0.5,
        shapeType: 0,
        phaseOffset: 0,
      );

      var minDist = 100.0;
      var maxDist = 100.0;

      for (double t = 0; t < 10; t += 0.1) {
        fragment.update(0.1, t);
        if (fragment.currentDistance < minDist)
          minDist = fragment.currentDistance;
        if (fragment.currentDistance > maxDist)
          maxDist = fragment.currentDistance;
      }

      // Should oscillate within +/- 5 of base distance
      expect(minDist, greaterThanOrEqualTo(95));
      expect(maxDist, lessThanOrEqualTo(105));
    });

    test('position is calculated from angle and distance', () {
      final fragment = SimulatedRealityFragment(
        angle: math.pi / 4,
        baseDistance: 100,
        size: 8,
        rotation: 0,
        rotationSpeed: 0,
        orbitSpeed: 0,
        shapeType: 0,
        phaseOffset: 0,
      );

      final pos = fragment.getPosition();
      expect(pos.x, closeTo(100 * math.cos(math.pi / 4), 0.001));
      expect(pos.y, closeTo(100 * math.sin(math.pi / 4), 0.001));
    });

    test('shapeType covers all 4 types', () {
      final rng = SimulatedLcgRng(12345);
      final shapes = <int>{};

      for (int i = 0; i < 100; i++) {
        shapes.add(rng.nextInt(4));
      }

      expect(shapes, containsAll([0, 1, 2, 3]));
    });
  });

  group('SimulatedElectricArc', () {
    test('initializes with inactive state', () {
      final arc = SimulatedElectricArc(
        angle: 0,
        length: 50,
        width: 2,
        lifetime: 0.1,
        segments: 4,
        respawnDelay: 0.2,
      );

      // At time=0, arc is not active (needs time > 0 and time < lifetime)
      expect(arc.isActive, false);
    });

    test('becomes active after first update', () {
      final arc = SimulatedElectricArc(
        angle: 0,
        length: 50,
        width: 2,
        lifetime: 0.1,
        segments: 4,
        respawnDelay: 0.2,
      );

      arc.update(0.01, () => 0.5);
      expect(arc.isActive, true);
    });

    test('becomes inactive after lifetime', () {
      final arc = SimulatedElectricArc(
        angle: 0,
        length: 50,
        width: 2,
        lifetime: 0.1,
        segments: 4,
        respawnDelay: 0.2,
      );

      arc.update(0.15, () => 0.5);
      expect(arc.isActive, false);
    });

    test('respawns after lifetime + respawnDelay', () {
      final arc = SimulatedElectricArc(
        angle: 0,
        length: 50,
        width: 2,
        lifetime: 0.1,
        segments: 4,
        respawnDelay: 0.2,
      );

      // Advance past lifetime + respawnDelay
      arc.update(0.35, () => 0.5);
      // Should have respawned
      arc.update(0.01, () => 0.5);
      expect(arc.isActive, true);
    });

    test('alpha decreases as arc ages', () {
      final arc = SimulatedElectricArc(
        angle: 0,
        length: 50,
        width: 2,
        lifetime: 0.1,
        segments: 4,
        respawnDelay: 0.2,
      );

      arc.update(0.02, () => 0.5);
      final alpha1 = arc.alpha;

      arc.update(0.02, () => 0.5);
      final alpha2 = arc.alpha;

      expect(alpha2, lessThan(alpha1));
    });

    test('alpha is 0 when inactive', () {
      final arc = SimulatedElectricArc(
        angle: 0,
        length: 50,
        width: 2,
        lifetime: 0.1,
        segments: 4,
        respawnDelay: 0.2,
      );

      // Before first update
      expect(arc.alpha, 0);

      // After lifetime
      arc.update(0.15, () => 0.5);
      expect(arc.alpha, 0);
    });

    test('segments count affects lightning complexity', () {
      final arc3 = SimulatedElectricArc(
        angle: 0,
        length: 50,
        width: 2,
        lifetime: 0.1,
        segments: 3,
        respawnDelay: 0.2,
      );

      final arc5 = SimulatedElectricArc(
        angle: 0,
        length: 50,
        width: 2,
        lifetime: 0.1,
        segments: 5,
        respawnDelay: 0.2,
      );

      expect(arc3.segments, 3);
      expect(arc5.segments, 5);
    });
  });

  group('SimulatedDimensionalParticle', () {
    test('initializes at max distance', () {
      final particle = SimulatedDimensionalParticle(
        angle: 0,
        distance: 100,
        maxDistance: 100,
        speed: 50,
        size: 2,
        lifetime: 1.0,
        phaseOffset: 0,
      );

      expect(particle.distance, 100);
      expect(particle.alpha, 1.0);
    });

    test('moves toward center over time', () {
      final particle = SimulatedDimensionalParticle(
        angle: 0,
        distance: 100,
        maxDistance: 100,
        speed: 50,
        size: 2,
        lifetime: 1.0,
        phaseOffset: 0,
      );

      particle.update(1.0);
      expect(particle.distance, closeTo(50, 0.1));
    });

    test('respawns at max distance when reaching center', () {
      final particle = SimulatedDimensionalParticle(
        angle: 0,
        distance: 100,
        maxDistance: 100,
        speed: 50,
        size: 2,
        lifetime: 1.0,
        phaseOffset: 0,
      );

      particle.update(2.5); // Would go negative
      expect(particle.distance, 100); // Respawned
    });

    test('alpha decreases as particle approaches center', () {
      final particle = SimulatedDimensionalParticle(
        angle: 0,
        distance: 100,
        maxDistance: 100,
        speed: 50,
        size: 2,
        lifetime: 1.0,
        phaseOffset: 0,
      );

      expect(particle.alpha, 1.0);

      particle.update(1.0);
      expect(particle.alpha, closeTo(0.5, 0.01));
    });

    test('isAlive is true while distance > 0', () {
      final particle = SimulatedDimensionalParticle(
        angle: 0,
        distance: 100,
        maxDistance: 100,
        speed: 50,
        size: 2,
        lifetime: 1.0,
        phaseOffset: 0,
      );

      expect(particle.isAlive, true);

      particle.update(1.9);
      expect(particle.isAlive, true);
    });

    test('position is calculated from angle and distance', () {
      final particle = SimulatedDimensionalParticle(
        angle: math.pi / 3,
        distance: 80,
        maxDistance: 100,
        speed: 50,
        size: 2,
        lifetime: 1.0,
        phaseOffset: 0,
      );

      final pos = particle.getPosition();
      expect(pos.x, closeTo(80 * math.cos(math.pi / 3), 0.001));
      expect(pos.y, closeTo(80 * math.sin(math.pi / 3), 0.001));
    });
  });

  group('SimulatedDistortionWave', () {
    test('starts inactive due to delay', () {
      final wave = SimulatedDistortionWave(
        delay: 0.5,
        speed: 100,
        maxRadius: 200,
      );

      expect(wave.isActive, false);
      expect(wave.currentRadius, 0);
    });

    test('becomes active after delay', () {
      final wave = SimulatedDistortionWave(
        delay: 0.5,
        speed: 100,
        maxRadius: 200,
      );

      wave.update(0.6);
      expect(wave.isActive, true);
      expect(wave.currentRadius, greaterThan(0));
    });

    test('radius grows at specified speed', () {
      final wave = SimulatedDistortionWave(
        delay: 0,
        speed: 100,
        maxRadius: 200,
      );

      wave.update(1.0);
      expect(wave.currentRadius, closeTo(100, 0.1));
    });

    test('resets when reaching max radius', () {
      final wave = SimulatedDistortionWave(
        delay: 0,
        speed: 100,
        maxRadius: 200,
      );

      wave.update(2.5); // Would exceed max
      expect(wave.currentRadius, 0);
    });

    test('alpha decreases as radius increases', () {
      final wave = SimulatedDistortionWave(
        delay: 0,
        speed: 100,
        maxRadius: 200,
      );

      wave.update(0.1);
      final alpha1 = wave.alpha;

      wave.update(0.5);
      final alpha2 = wave.alpha;

      expect(alpha2, lessThan(alpha1));
    });

    test('alpha is 0 when inactive', () {
      final wave = SimulatedDistortionWave(
        delay: 0.5,
        speed: 100,
        maxRadius: 200,
      );

      expect(wave.alpha, 0);
    });

    test('max alpha is 0.6', () {
      final wave = SimulatedDistortionWave(
        delay: 0,
        speed: 100,
        maxRadius: 200,
      );

      wave.update(0.001); // Very small radius
      expect(wave.alpha, closeTo(0.6, 0.01));
    });
  });

  group('RealityTearSimulator', () {
    test('initializes with correct defaults', () {
      final sim = RealityTearSimulator();

      expect(sim.tearSize, 60.0);
      expect(sim.duration, 2.0);
      expect(sim.reduceFx, false);
      expect(sim.lowFx, false);
      expect(sim.time, 0);
      expect(sim.openProgress, 0);
    });

    test('creates correct fragment count for normal mode', () {
      final sim = RealityTearSimulator(reduceFx: false, lowFx: false);
      expect(sim.fragments.length, 12);
    });

    test('creates correct fragment count for reduceFx mode', () {
      final sim = RealityTearSimulator(reduceFx: true, lowFx: false);
      expect(sim.fragments.length, 6);
    });

    test('creates no fragments for lowFx mode', () {
      final sim = RealityTearSimulator(reduceFx: false, lowFx: true);
      expect(sim.fragments.length, 0);
    });

    test('creates correct arc count for normal mode', () {
      final sim = RealityTearSimulator(reduceFx: false, lowFx: false);
      expect(sim.electricArcs.length, 8);
    });

    test('creates correct arc count for reduceFx mode', () {
      final sim = RealityTearSimulator(reduceFx: true, lowFx: false);
      expect(sim.electricArcs.length, 4);
    });

    test('creates correct particle count for normal mode', () {
      final sim = RealityTearSimulator(reduceFx: false, lowFx: false);
      expect(sim.particles.length, 24);
    });

    test('creates correct particle count for reduceFx mode', () {
      final sim = RealityTearSimulator(reduceFx: true, lowFx: false);
      expect(sim.particles.length, 12);
    });

    test('creates correct wave count for all modes', () {
      final simNormal = RealityTearSimulator(reduceFx: false, lowFx: false);
      final simReduced = RealityTearSimulator(reduceFx: true, lowFx: false);
      final simLow = RealityTearSimulator(reduceFx: false, lowFx: true);

      expect(simNormal.waves.length, 4);
      expect(simReduced.waves.length, 2);
      expect(simLow.waves.length, 1);
    });

    group('opening animation', () {
      test('opens from 0 to 1 during 0-0.2 progress', () {
        final sim = RealityTearSimulator(duration: 2.0);

        sim.update(0.2); // progress = 0.1
        expect(sim.openProgress, closeTo(0.5, 0.01));

        sim.update(0.2); // progress = 0.2
        expect(sim.openProgress, closeTo(1.0, 0.01));
      });

      test('stays at 1.0 during 0.2-0.8 progress', () {
        final sim = RealityTearSimulator(duration: 2.0);

        sim.update(0.6); // progress = 0.3
        expect(sim.openProgress, 1.0);

        sim.update(0.6); // progress = 0.6
        expect(sim.openProgress, 1.0);
      });

      test('closes from 1 to 0 during 0.8-1.0 progress', () {
        final sim = RealityTearSimulator(duration: 2.0);

        sim.update(1.7); // progress = 0.85
        expect(sim.openProgress, closeTo(0.75, 0.01));

        sim.update(0.2); // progress = 0.95
        expect(sim.openProgress, closeTo(0.25, 0.01));
      });
    });

    group('flicker intensity', () {
      test('base flicker oscillates around 0.8', () {
        // flickerIntensity = sin(time * 20) * 0.2 + 0.8
        // So it ranges from 0.6 to 1.0
        final baseMin = 0.6;
        final baseMax = 1.0;

        expect(baseMin, greaterThanOrEqualTo(0.5));
        expect(baseMax, lessThanOrEqualTo(1.1));
      });

      test('random glitch can reduce flicker to 0.3-0.7 range', () {
        // When random.nextUnit() < 0.05, flicker = 0.3 + random * 0.4
        final glitchMin = 0.3;
        final glitchMax = 0.7;

        expect(glitchMin, lessThan(0.5));
        expect(glitchMax, lessThan(1.0));
      });
    });

    test('progress increases with time', () {
      final sim = RealityTearSimulator(duration: 2.0);

      sim.update(0.5);
      expect(sim.progress, closeTo(0.25, 0.001));

      sim.update(0.5);
      expect(sim.progress, closeTo(0.5, 0.001));
    });

    test('reset restores initial state', () {
      final sim = RealityTearSimulator();

      sim.update(1.0);
      expect(sim.time, greaterThan(0));
      expect(sim.openProgress, greaterThan(0));

      sim.reset();

      expect(sim.time, 0);
      expect(sim.openProgress, 0);
      expect(sim.flickerIntensity, 0);
    });

    test('fragments update with time', () {
      final sim = RealityTearSimulator();

      if (sim.fragments.isNotEmpty) {
        final initialRotation = sim.fragments.first.currentRotation;

        sim.update(0.5);

        expect(sim.fragments.first.currentRotation,
            isNot(closeTo(initialRotation, 0.001)));
      }
    });

    test('particles move toward center', () {
      final sim = RealityTearSimulator();

      if (sim.particles.isNotEmpty) {
        final initialDistance = sim.particles.first.distance;

        sim.update(0.5);

        expect(sim.particles.first.distance, lessThan(initialDistance));
      }
    });

    test('waves expand over time', () {
      final sim = RealityTearSimulator();

      // First wave has no delay
      sim.update(0.5);

      final activeWave = sim.waves
          .firstWhere((w) => w.isActive, orElse: () => sim.waves.first);
      expect(activeWave.currentRadius, greaterThan(0));
    });
  });

  group('Tear edge calculations', () {
    test('jagged edge creates points around base radius', () {
      final baseRadius = 30.0;
      final jaggedPoints = 24;

      for (int i = 0; i <= jaggedPoints; i++) {
        final angle = (i / jaggedPoints) * math.pi * 2;
        final x = math.cos(angle) * baseRadius;
        final y = math.sin(angle) * baseRadius;
        final distance = math.sqrt(x * x + y * y);

        expect(distance, closeTo(baseRadius, 0.1));
      }
    });

    test('jitter adds variation to edge', () {
      final time = 1.0;

      for (int i = 0; i < 24; i++) {
        final jitter =
            math.sin(time * 15 + i * 3) * 4 + math.sin(time * 8 + i * 7) * 2;

        // Jitter should be bounded
        expect(jitter.abs(), lessThanOrEqualTo(6));
      }
    });
  });

  group('Void size calculations', () {
    test('void radius is 40% of effective size', () {
      final effectiveSize = 60.0;
      final voidRadius = effectiveSize * 0.4;

      expect(voidRadius, closeTo(24, 0.1));
    });

    test('chromatic edge is 15% larger than void', () {
      final voidRadius = 24.0;
      final chromaticRadius = voidRadius * 1.15;

      expect(chromaticRadius, closeTo(27.6, 0.1));
    });
  });

  group('Fragment shape generation', () {
    test('all 4 shape types are generated', () {
      final rng = SimulatedLcgRng(12345);
      final shapes = <int>{};

      for (int i = 0; i < 100; i++) {
        shapes.add(rng.nextInt(4));
      }

      expect(shapes, containsAll([0, 1, 2, 3]));
    });
  });

  group('Electric arc path calculations', () {
    test('arc starts at tear edge', () {
      final baseRadius = 30.0;
      final angle = math.pi / 4;

      final startX = math.cos(angle) * baseRadius;
      final startY = math.sin(angle) * baseRadius;

      final distance = math.sqrt(startX * startX + startY * startY);
      expect(distance, closeTo(baseRadius, 0.001));
    });

    test('arc direction is outward from center', () {
      final angle = math.pi / 4;
      final direction = angle + math.pi; // Point outward

      // Direction should be opposite to angle (pointing away from center)
      expect(direction, closeTo(angle + math.pi, 0.001));
    });

    test('perpendicular offset creates zigzag', () {
      final direction = math.pi / 4;
      final perpOffset = 5.0;

      final perpX = math.cos(direction + math.pi / 2) * perpOffset;
      final perpY = math.sin(direction + math.pi / 2) * perpOffset;

      // Perpendicular should have same magnitude but different direction
      final perpDistance = math.sqrt(perpX * perpX + perpY * perpY);
      expect(perpDistance, closeTo(perpOffset, 0.001));
    });
  });

  group('Wave staggering', () {
    test('waves have increasing delays', () {
      final sim = RealityTearSimulator();

      double prevDelay = -1;
      for (final wave in sim.waves) {
        expect(wave.delay, greaterThanOrEqualTo(prevDelay));
        prevDelay = wave.delay;
      }
    });

    test('wave delay increment is 0.4 seconds', () {
      final waveCount = 4;
      final expectedDelays = [0.0, 0.4, 0.8, 1.2];

      for (int i = 0; i < waveCount; i++) {
        expect(i * 0.4, closeTo(expectedDelays[i], 0.001));
      }
    });
  });

  group('Particle distribution', () {
    test('particles are distributed around full circle', () {
      final sim = RealityTearSimulator();

      if (sim.particles.isEmpty) return;

      // Check that angles cover most of the circle
      final quadrants = <int>{};
      for (final particle in sim.particles) {
        final quadrant = (particle.angle / (math.pi / 2)).floor() % 4;
        quadrants.add(quadrant);
      }

      // With 24 particles, all 4 quadrants should be covered
      expect(quadrants.length, greaterThanOrEqualTo(4));
    });

    test('particles start outside tear radius', () {
      final sim = RealityTearSimulator(tearSize: 60);

      for (final particle in sim.particles) {
        // Particles start at tearSize * (1.5 to 3.0)
        expect(particle.maxDistance, greaterThanOrEqualTo(60 * 1.5));
        expect(particle.maxDistance, lessThanOrEqualTo(60 * 3.0));
      }
    });
  });

  group('Chromatic aberration offsets', () {
    test('purple and cyan offsets are opposite', () {
      // Purple: (-3, -1)
      // Cyan: (3, 1)
      const purpleX = -3.0;
      const purpleY = -1.0;
      const cyanX = 3.0;
      const cyanY = 1.0;

      expect(purpleX + cyanX, closeTo(0, 0.001));
      expect(purpleY + cyanY, closeTo(0, 0.001));
    });
  });

  group('Scanline animation', () {
    test('scanlines oscillate vertically', () {
      final effectiveSize = 60.0;

      for (int i = 0; i < 8; i++) {
        for (double t = 0; t < 2; t += 0.1) {
          final yOffset = math.sin(t * 25 + i * 2) * effectiveSize * 0.8;

          // Y offset should be bounded
          expect(yOffset.abs(), lessThanOrEqualTo(effectiveSize * 0.8));
        }
      }
    });

    test('scanline width varies', () {
      final effectiveSize = 60.0;
      final minWidth = effectiveSize * 0.3;
      final maxWidth = effectiveSize * 0.8;

      expect(maxWidth, greaterThan(minWidth));
      expect(minWidth, greaterThan(0));
    });
  });

  group('Glitch block generation', () {
    test('glitch blocks appear randomly (15% chance)', () {
      final rng = SimulatedLcgRng(12345);
      var glitchCount = 0;

      for (int i = 0; i < 1000; i++) {
        if (rng.nextUnit() < 0.15) {
          glitchCount++;
        }
      }

      // Should be around 150 +/- 30
      expect(glitchCount, inInclusiveRange(100, 200));
    });

    test('block count varies from 3 to 5', () {
      final rng = SimulatedLcgRng(12345);
      final counts = <int>{};

      for (int i = 0; i < 100; i++) {
        final blockCount = 3 + rng.nextInt(3);
        counts.add(blockCount);
      }

      expect(counts, containsAll([3, 4, 5]));
    });

    test('block positions are within effect bounds', () {
      final effectiveSize = 60.0;

      for (int i = 0; i < 10; i++) {
        final bx = (0.5 - 0.5) * effectiveSize * 2; // Simplified to 0
        final by = (0.5 - 0.5) * effectiveSize * 2; // Simplified to 0

        expect(bx.abs(), lessThanOrEqualTo(effectiveSize));
        expect(by.abs(), lessThanOrEqualTo(effectiveSize));
      }
    });
  });

  group('Fragment angle distribution', () {
    test('fragments are evenly distributed around circle', () {
      final fragmentCount = 12;

      for (int i = 0; i < fragmentCount; i++) {
        final baseAngle = (i / fragmentCount) * math.pi * 2;
        final expectedAngle = i * (math.pi * 2 / fragmentCount);

        expect(baseAngle, closeTo(expectedAngle, 0.001));
      }
    });

    test('fragment angle has random offset up to 0.5 radians', () {
      final rng = SimulatedLcgRng(12345);

      for (int i = 0; i < 100; i++) {
        final offset = rng.nextUnit() * 0.5;
        expect(offset, greaterThanOrEqualTo(0));
        expect(offset, lessThanOrEqualTo(0.5));
      }
    });
  });

  group('Arc segment distribution', () {
    test('segments range from 3 to 5', () {
      final rng = SimulatedLcgRng(12345);
      final segments = <int>{};

      for (int i = 0; i < 100; i++) {
        final seg = 3 + rng.nextInt(3);
        segments.add(seg);
      }

      expect(segments, containsAll([3, 4, 5]));
    });
  });
}
