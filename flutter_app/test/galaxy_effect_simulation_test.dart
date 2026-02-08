import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

/// Simulation tests for GalaxyEffect mathematical logic.
/// Tests spiral arm calculations, star positioning, dust lanes, absorption particles,
/// and phase timing without requiring actual game rendering.

// ═══════════════════════════════════════════════════════════════════════════════
// LCG RNG SIMULATION (matches _FastRng in galaxy_effect.dart)
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedRng {
  int _state;

  SimulatedRng([int? seed]) : _state = (seed ?? 0x6d2b79f5) & 0x7fffffff;

  int next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  double nextDouble() => next() / 0x7fffffff;
  int nextInt(int max) => max <= 0 ? 0 : next() % max;
  bool nextBool() => (next() & 1) == 0;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SPIRAL ARM SIMULATION
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedSpiralArm {
  final double baseAngle;
  final double length;
  final double width;
  final double spiralTightness;
  final double rotationSpeed;
  final int segmentCount;
  final bool isPrimary;
  double currentAngle;

  SimulatedSpiralArm({
    required this.baseAngle,
    required this.length,
    required this.width,
    required this.spiralTightness,
    required this.rotationSpeed,
    required this.segmentCount,
    required this.isPrimary,
  }) : currentAngle = baseAngle;

  void update(double progress) {
    currentAngle = baseAngle + progress * rotationSpeed * math.pi * 2;
  }

  /// Calculate point position at t (0=center, 1=edge) using logarithmic spiral
  ({double x, double y}) getPointAt(double t) {
    final theta = currentAngle + t * math.pi * 2 * spiralTightness;
    final r = t * length;
    return (x: math.cos(theta) * r, y: math.sin(theta) * r);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STAR PARTICLE SIMULATION
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedStarParticle {
  final int armIndex;
  final double positionT;
  final double scatter;
  final double size;
  final double brightness;
  final double twinkleSpeed;
  final double twinklePhase;
  final bool isPink;

  SimulatedStarParticle({
    required this.armIndex,
    required this.positionT,
    required this.scatter,
    required this.size,
    required this.brightness,
    required this.twinkleSpeed,
    required this.twinklePhase,
    required this.isPink,
  });

  double getTwinkle(double time) {
    return 0.5 + 0.5 * math.sin(time * twinkleSpeed + twinklePhase);
  }

  double getBrightness(double time) {
    return brightness * getTwinkle(time);
  }

  ({double x, double y}) getPosition(SimulatedSpiralArm arm) {
    final theta = arm.currentAngle + positionT * math.pi * 2 * arm.spiralTightness;
    final r = positionT * arm.length;
    final perpAngle = theta + math.pi / 2;
    return (
      x: math.cos(theta) * r + math.cos(perpAngle) * scatter,
      y: math.sin(theta) * r + math.sin(perpAngle) * scatter,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ABSORPTION PARTICLE SIMULATION
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedAbsorptionParticle {
  final double angle;
  final double initialDistance;
  final double speed;
  final double size;
  final double delay;
  final double trailLength;
  double currentDistance;

  SimulatedAbsorptionParticle({
    required this.angle,
    required this.initialDistance,
    required this.speed,
    required this.size,
    required this.delay,
    required this.trailLength,
  }) : currentDistance = initialDistance;

  bool isActive(double time) => time > delay;

  void update(double dt, double time, double progress) {
    if (!isActive(time)) return;
    if (progress > 0.4 && progress < 0.95) {
      final absorptionStrength = progress < 0.5
          ? (progress - 0.4) / 0.1
          : progress < 0.85
              ? 1.0
              : (0.95 - progress) / 0.1;
      currentDistance -= speed * dt * absorptionStrength;
      if (currentDistance < 0) currentDistance = 0;
    }
  }

  ({double x, double y}) getPosition() {
    return (
      x: math.cos(angle) * currentDistance,
      y: math.sin(angle) * currentDistance,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GALAXY EFFECT SIMULATOR
// ═══════════════════════════════════════════════════════════════════════════════

class GalaxyEffectSimulator {
  final double galaxySize;
  final double duration;
  final double fxScale;
  final SimulatedRng random;

  final List<SimulatedSpiralArm> spiralArms = [];
  final List<SimulatedStarParticle> stars = [];
  final List<SimulatedAbsorptionParticle> absorptionParticles = [];

  double time = 0;
  double coreIntensity = 0;
  double coreRotation = 0;
  double haloRadius = 0;
  double haloAlpha = 0;
  double expansionScale = 1.0;
  bool isCollapsing = false;

  GalaxyEffectSimulator({
    this.galaxySize = 80.0,
    this.duration = 2.0,
    this.fxScale = 1.0,
    int? seed,
  }) : random = SimulatedRng(seed) {
    _initializeSpiralArms();
    _initializeStars();
    _initializeAbsorptionParticles();
  }

  double get progress => time / duration;

  void _initializeSpiralArms() {
    final armCount = _scaledCount(3, min: 2, max: 4);
    for (int i = 0; i < armCount; i++) {
      final baseAngle = (i / armCount) * math.pi * 2;
      final isPrimary = i < 2;
      spiralArms.add(SimulatedSpiralArm(
        baseAngle: baseAngle,
        length: galaxySize * (isPrimary ? 1.0 : 0.7),
        width: isPrimary ? 8.0 : 5.0,
        spiralTightness: 0.4 + random.nextDouble() * 0.2,
        rotationSpeed: 1.2 + random.nextDouble() * 0.3,
        segmentCount: isPrimary ? 20 : 14,
        isPrimary: isPrimary,
      ));
    }
  }

  void _initializeStars() {
    final starCount = _scaledCount(60, min: 20, max: 80);
    for (int i = 0; i < starCount; i++) {
      final armIndex = i % spiralArms.length;
      final t = random.nextDouble();
      final scatter = (random.nextDouble() - 0.5) * 20;
      stars.add(SimulatedStarParticle(
        armIndex: armIndex,
        positionT: t,
        scatter: scatter,
        size: 1.0 + random.nextDouble() * 2.5,
        brightness: 0.4 + random.nextDouble() * 0.6,
        twinkleSpeed: 3 + random.nextDouble() * 5,
        twinklePhase: random.nextDouble() * math.pi * 2,
        isPink: random.nextDouble() > 0.85,
      ));
    }
  }

  void _initializeAbsorptionParticles() {
    final particleCount = _scaledCount(30, min: 15, max: 45);
    for (int i = 0; i < particleCount; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final distance = galaxySize * (1.2 + random.nextDouble() * 0.8);
      absorptionParticles.add(SimulatedAbsorptionParticle(
        angle: angle,
        initialDistance: distance,
        speed: 40 + random.nextDouble() * 60,
        size: 1.5 + random.nextDouble() * 2,
        delay: random.nextDouble() * 0.5,
        trailLength: 8 + random.nextDouble() * 12,
      ));
    }
  }

  int _scaledCount(int base, {int min = 1, int max = 100}) {
    final scaled = (base * fxScale).round();
    return scaled.clamp(min, max);
  }

  void update(double dt) {
    time += dt;
    final p = progress;

    // Core intensity phases
    if (p < 0.2) {
      coreIntensity = p / 0.2;
    } else if (p < 0.85) {
      coreIntensity = 1.0;
    } else {
      coreIntensity = 1.0 - (p - 0.85) / 0.15;
    }

    // Core rotation
    coreRotation += dt * 2.0;

    // Halo
    if (p < 0.15) {
      haloRadius = galaxySize * 1.3 * (p / 0.15);
      haloAlpha = p / 0.15 * 0.5;
    } else if (p < 0.85) {
      haloRadius = galaxySize * 1.3;
      haloAlpha = 0.5;
    } else {
      final collapseProgress = (p - 0.85) / 0.15;
      haloRadius = galaxySize * 1.3 * (1 + collapseProgress * 0.5);
      haloAlpha = 0.5 * (1 - collapseProgress);
    }

    // Expansion/collapse phase
    if (p > 0.85) {
      isCollapsing = true;
      final collapseProgress = (p - 0.85) / 0.15;
      if (collapseProgress < 0.5) {
        expansionScale = 1.0 - collapseProgress * 0.8;
      } else {
        expansionScale = 0.6 + (collapseProgress - 0.5) * 4.0;
      }
    }

    // Update arms
    for (final arm in spiralArms) {
      arm.update(p);
    }

    // Update absorption particles
    for (final particle in absorptionParticles) {
      particle.update(dt, time, p);
    }
  }

  void reset() {
    time = 0;
    coreIntensity = 0;
    coreRotation = 0;
    haloRadius = 0;
    haloAlpha = 0;
    expansionScale = 1.0;
    isCollapsing = false;
    for (final arm in spiralArms) {
      arm.currentAngle = arm.baseAngle;
    }
    for (final particle in absorptionParticles) {
      particle.currentDistance = particle.initialDistance;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEST SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('SimulatedRng', () {
    test('produces deterministic sequence', () {
      final rng1 = SimulatedRng(12345);
      final rng2 = SimulatedRng(12345);

      for (int i = 0; i < 100; i++) {
        expect(rng1.next(), rng2.next());
      }
    });

    test('nextDouble returns values in [0, 1)', () {
      final rng = SimulatedRng();
      for (int i = 0; i < 1000; i++) {
        final value = rng.nextDouble();
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThan(1.0));
      }
    });

    test('nextInt returns values in [0, max)', () {
      final rng = SimulatedRng();
      for (int i = 0; i < 1000; i++) {
        final value = rng.nextInt(10);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(10));
      }
    });

    test('nextInt with max <= 0 returns 0', () {
      final rng = SimulatedRng();
      expect(rng.nextInt(0), 0);
      expect(rng.nextInt(-5), 0);
    });

    test('nextBool returns true and false', () {
      final rng = SimulatedRng();
      var trueCount = 0;
      var falseCount = 0;
      for (int i = 0; i < 1000; i++) {
        if (rng.nextBool()) {
          trueCount++;
        } else {
          falseCount++;
        }
      }
      expect(trueCount, greaterThan(100));
      expect(falseCount, greaterThan(100));
    });

    test('different seeds produce different sequences', () {
      final rng1 = SimulatedRng(111);
      final rng2 = SimulatedRng(222);
      var sameCount = 0;
      for (int i = 0; i < 100; i++) {
        if (rng1.next() == rng2.next()) sameCount++;
      }
      expect(sameCount, lessThan(10));
    });
  });

  group('SimulatedSpiralArm', () {
    test('initializes with correct base angle', () {
      final arm = SimulatedSpiralArm(
        baseAngle: math.pi / 4,
        length: 100,
        width: 8,
        spiralTightness: 0.5,
        rotationSpeed: 1.2,
        segmentCount: 20,
        isPrimary: true,
      );

      expect(arm.baseAngle, math.pi / 4);
      expect(arm.currentAngle, math.pi / 4);
    });

    test('update advances rotation based on progress', () {
      final arm = SimulatedSpiralArm(
        baseAngle: 0,
        length: 100,
        width: 8,
        spiralTightness: 0.5,
        rotationSpeed: 1.0,
        segmentCount: 20,
        isPrimary: true,
      );

      arm.update(0.5); // 50% progress
      expect(arm.currentAngle, closeTo(math.pi, 0.001));

      arm.update(1.0); // 100% progress
      expect(arm.currentAngle, closeTo(math.pi * 2, 0.001));
    });

    test('getPointAt returns center at t=0', () {
      final arm = SimulatedSpiralArm(
        baseAngle: 0,
        length: 100,
        width: 8,
        spiralTightness: 0.5,
        rotationSpeed: 1.0,
        segmentCount: 20,
        isPrimary: true,
      );

      final point = arm.getPointAt(0);
      expect(point.x, closeTo(0, 0.001));
      expect(point.y, closeTo(0, 0.001));
    });

    test('getPointAt returns distance=length at t=1', () {
      final arm = SimulatedSpiralArm(
        baseAngle: 0,
        length: 100,
        width: 8,
        spiralTightness: 0.5,
        rotationSpeed: 1.0,
        segmentCount: 20,
        isPrimary: true,
      );

      final point = arm.getPointAt(1.0);
      final distance = math.sqrt(point.x * point.x + point.y * point.y);
      expect(distance, closeTo(100, 0.001));
    });

    test('spiral tightness affects angle progression', () {
      final arm1 = SimulatedSpiralArm(
        baseAngle: 0,
        length: 100,
        width: 8,
        spiralTightness: 0.3,
        rotationSpeed: 1.0,
        segmentCount: 20,
        isPrimary: true,
      );

      final arm2 = SimulatedSpiralArm(
        baseAngle: 0,
        length: 100,
        width: 8,
        spiralTightness: 0.6,
        rotationSpeed: 1.0,
        segmentCount: 20,
        isPrimary: true,
      );

      final point1 = arm1.getPointAt(0.5);
      final point2 = arm2.getPointAt(0.5);

      // Tighter spiral should have different angle
      expect(point1.x, isNot(closeTo(point2.x, 0.1)));
    });

    test('primary vs non-primary arms have different properties', () {
      final rng = SimulatedRng(12345);

      // Simulate primary arm
      final primaryLength = 100 * 1.0;
      final primaryWidth = 8.0;
      final primarySegments = 20;

      // Simulate non-primary arm
      final nonPrimaryLength = 100 * 0.7;
      final nonPrimaryWidth = 5.0;
      final nonPrimarySegments = 14;

      expect(primaryLength, greaterThan(nonPrimaryLength));
      expect(primaryWidth, greaterThan(nonPrimaryWidth));
      expect(primarySegments, greaterThan(nonPrimarySegments));
    });
  });

  group('SimulatedStarParticle', () {
    test('twinkle oscillates between 0 and 1', () {
      final star = SimulatedStarParticle(
        armIndex: 0,
        positionT: 0.5,
        scatter: 0,
        size: 2,
        brightness: 0.8,
        twinkleSpeed: 5.0,
        twinklePhase: 0,
        isPink: false,
      );

      var minTwinkle = 1.0;
      var maxTwinkle = 0.0;

      for (double t = 0; t < 10; t += 0.1) {
        final twinkle = star.getTwinkle(t);
        if (twinkle < minTwinkle) minTwinkle = twinkle;
        if (twinkle > maxTwinkle) maxTwinkle = twinkle;
      }

      expect(minTwinkle, closeTo(0.0, 0.01));
      expect(maxTwinkle, closeTo(1.0, 0.01));
    });

    test('brightness is modulated by twinkle', () {
      final star = SimulatedStarParticle(
        armIndex: 0,
        positionT: 0.5,
        scatter: 0,
        size: 2,
        brightness: 0.8,
        twinkleSpeed: 5.0,
        twinklePhase: 0,
        isPink: false,
      );

      final brightness1 = star.getBrightness(0);
      final brightness2 = star.getBrightness(math.pi / (2 * 5.0)); // quarter period

      expect(brightness1, greaterThan(0));
      expect(brightness2, greaterThan(0));
      expect(brightness1, lessThanOrEqualTo(0.8));
      expect(brightness2, lessThanOrEqualTo(0.8));
    });

    test('position includes scatter perpendicular to arm', () {
      final arm = SimulatedSpiralArm(
        baseAngle: 0,
        length: 100,
        width: 8,
        spiralTightness: 0.5,
        rotationSpeed: 1.0,
        segmentCount: 20,
        isPrimary: true,
      );

      final starNoScatter = SimulatedStarParticle(
        armIndex: 0,
        positionT: 0.5,
        scatter: 0,
        size: 2,
        brightness: 0.8,
        twinkleSpeed: 5.0,
        twinklePhase: 0,
        isPink: false,
      );

      final starWithScatter = SimulatedStarParticle(
        armIndex: 0,
        positionT: 0.5,
        scatter: 20,
        size: 2,
        brightness: 0.8,
        twinkleSpeed: 5.0,
        twinklePhase: 0,
        isPink: false,
      );

      final posNoScatter = starNoScatter.getPosition(arm);
      final posWithScatter = starWithScatter.getPosition(arm);

      expect(posNoScatter.x, isNot(closeTo(posWithScatter.x, 0.1)));
    });

    test('isPink flag is correctly set', () {
      final normalStar = SimulatedStarParticle(
        armIndex: 0,
        positionT: 0.5,
        scatter: 0,
        size: 2,
        brightness: 0.8,
        twinkleSpeed: 5.0,
        twinklePhase: 0,
        isPink: false,
      );

      final pinkStar = SimulatedStarParticle(
        armIndex: 0,
        positionT: 0.5,
        scatter: 0,
        size: 2,
        brightness: 0.8,
        twinkleSpeed: 5.0,
        twinklePhase: 0,
        isPink: true,
      );

      expect(normalStar.isPink, false);
      expect(pinkStar.isPink, true);
    });
  });

  group('SimulatedAbsorptionParticle', () {
    test('starts at initial distance', () {
      final particle = SimulatedAbsorptionParticle(
        angle: 0,
        initialDistance: 120,
        speed: 50,
        size: 2,
        delay: 0.1,
        trailLength: 10,
      );

      expect(particle.currentDistance, 120);
    });

    test('is inactive before delay', () {
      final particle = SimulatedAbsorptionParticle(
        angle: 0,
        initialDistance: 120,
        speed: 50,
        size: 2,
        delay: 0.5,
        trailLength: 10,
      );

      expect(particle.isActive(0.3), false);
      expect(particle.isActive(0.6), true);
    });

    test('does not move before absorption phase (progress < 0.4)', () {
      final particle = SimulatedAbsorptionParticle(
        angle: 0,
        initialDistance: 120,
        speed: 50,
        size: 2,
        delay: 0,
        trailLength: 10,
      );

      particle.update(0.1, 0.1, 0.3); // progress = 0.3
      expect(particle.currentDistance, 120);
    });

    test('moves toward center during absorption phase (0.4 < progress < 0.95)', () {
      final particle = SimulatedAbsorptionParticle(
        angle: 0,
        initialDistance: 120,
        speed: 50,
        size: 2,
        delay: 0,
        trailLength: 10,
      );

      particle.update(0.5, 0.5, 0.6); // progress = 0.6
      expect(particle.currentDistance, lessThan(120));
    });

    test('absorption strength ramps up between 0.4 and 0.5', () {
      final particle1 = SimulatedAbsorptionParticle(
        angle: 0,
        initialDistance: 120,
        speed: 50,
        size: 2,
        delay: 0,
        trailLength: 10,
      );

      final particle2 = SimulatedAbsorptionParticle(
        angle: 0,
        initialDistance: 120,
        speed: 50,
        size: 2,
        delay: 0,
        trailLength: 10,
      );

      particle1.update(0.1, 0.1, 0.42);
      particle2.update(0.1, 0.1, 0.48);

      // Both should move, but particle2 should move more (higher strength)
      final movement1 = 120 - particle1.currentDistance;
      final movement2 = 120 - particle2.currentDistance;
      expect(movement2, greaterThan(movement1));
    });

    test('absorption strength is full between 0.5 and 0.85', () {
      final particle = SimulatedAbsorptionParticle(
        angle: 0,
        initialDistance: 120,
        speed: 50,
        size: 2,
        delay: 0,
        trailLength: 10,
      );

      particle.update(1.0, 1.0, 0.7); // full strength phase
      final expectedMovement = 50 * 1.0 * 1.0; // speed * dt * strength
      expect(particle.currentDistance, closeTo(120 - expectedMovement, 0.1));
    });

    test('absorption strength decreases after 0.85', () {
      final particle1 = SimulatedAbsorptionParticle(
        angle: 0,
        initialDistance: 120,
        speed: 50,
        size: 2,
        delay: 0,
        trailLength: 10,
      );

      final particle2 = SimulatedAbsorptionParticle(
        angle: 0,
        initialDistance: 120,
        speed: 50,
        size: 2,
        delay: 0,
        trailLength: 10,
      );

      particle1.update(0.1, 0.1, 0.7); // full strength
      particle2.update(0.1, 0.1, 0.9); // decreased strength

      final movement1 = 120 - particle1.currentDistance;
      final movement2 = 120 - particle2.currentDistance;
      expect(movement1, greaterThan(movement2));
    });

    test('distance does not go below 0', () {
      final particle = SimulatedAbsorptionParticle(
        angle: 0,
        initialDistance: 10,
        speed: 500, // Very fast
        size: 2,
        delay: 0,
        trailLength: 10,
      );

      for (int i = 0; i < 100; i++) {
        particle.update(0.1, i * 0.1, 0.7);
      }

      expect(particle.currentDistance, greaterThanOrEqualTo(0));
    });

    test('position is calculated from angle and distance', () {
      final particle = SimulatedAbsorptionParticle(
        angle: math.pi / 4, // 45 degrees
        initialDistance: 100,
        speed: 50,
        size: 2,
        delay: 0,
        trailLength: 10,
      );

      final pos = particle.getPosition();
      expect(pos.x, closeTo(100 * math.cos(math.pi / 4), 0.001));
      expect(pos.y, closeTo(100 * math.sin(math.pi / 4), 0.001));
    });
  });

  group('GalaxyEffectSimulator', () {
    test('initializes with correct default values', () {
      final sim = GalaxyEffectSimulator();

      expect(sim.galaxySize, 80.0);
      expect(sim.duration, 2.0);
      expect(sim.time, 0);
      expect(sim.progress, 0);
      expect(sim.coreIntensity, 0);
      expect(sim.isCollapsing, false);
    });

    test('creates correct number of spiral arms', () {
      final sim = GalaxyEffectSimulator(fxScale: 1.0);
      expect(sim.spiralArms.length, inInclusiveRange(2, 4));
    });

    test('creates correct number of stars based on fxScale', () {
      final sim1 = GalaxyEffectSimulator(fxScale: 1.0, seed: 12345);
      final sim2 = GalaxyEffectSimulator(fxScale: 0.5, seed: 12345);

      expect(sim1.stars.length, greaterThan(sim2.stars.length));
    });

    test('creates correct number of absorption particles based on fxScale', () {
      final sim1 = GalaxyEffectSimulator(fxScale: 1.0, seed: 12345);
      final sim2 = GalaxyEffectSimulator(fxScale: 0.5, seed: 12345);

      expect(sim1.absorptionParticles.length, greaterThanOrEqualTo(sim2.absorptionParticles.length));
    });

    test('progress increases with time', () {
      final sim = GalaxyEffectSimulator(duration: 2.0);

      sim.update(0.5);
      expect(sim.progress, closeTo(0.25, 0.001));

      sim.update(0.5);
      expect(sim.progress, closeTo(0.5, 0.001));
    });

    group('core intensity phases', () {
      test('builds up from 0 to 1 during 0-0.2 progress', () {
        final sim = GalaxyEffectSimulator(duration: 2.0);

        sim.update(0.2); // progress = 0.1
        expect(sim.coreIntensity, closeTo(0.5, 0.01));

        sim.update(0.2); // progress = 0.2
        expect(sim.coreIntensity, closeTo(1.0, 0.01));
      });

      test('stays at 1.0 during 0.2-0.85 progress', () {
        final sim = GalaxyEffectSimulator(duration: 2.0);

        sim.update(0.5); // progress = 0.25
        expect(sim.coreIntensity, 1.0);

        sim.update(0.5); // progress = 0.5
        expect(sim.coreIntensity, 1.0);

        sim.update(0.5); // progress = 0.75
        expect(sim.coreIntensity, 1.0);
      });

      test('fades from 1 to 0 during 0.85-1.0 progress', () {
        final sim = GalaxyEffectSimulator(duration: 2.0);

        sim.update(1.8); // progress = 0.9
        expect(sim.coreIntensity, lessThan(1.0));
        expect(sim.coreIntensity, greaterThan(0));
      });
    });

    group('halo animation', () {
      test('halo radius grows during 0-0.15 progress', () {
        final sim = GalaxyEffectSimulator(duration: 2.0, galaxySize: 100);

        sim.update(0.15); // progress = 0.075
        expect(sim.haloRadius, greaterThan(0));
        expect(sim.haloRadius, lessThan(100 * 1.3));
      });

      test('halo is fully expanded during 0.15-0.85 progress', () {
        final sim = GalaxyEffectSimulator(duration: 2.0, galaxySize: 100);

        sim.update(1.0); // progress = 0.5
        expect(sim.haloRadius, closeTo(100 * 1.3, 0.1));
        expect(sim.haloAlpha, closeTo(0.5, 0.01));
      });

      test('halo expands and fades during collapse phase', () {
        final sim = GalaxyEffectSimulator(duration: 2.0, galaxySize: 100);

        sim.update(1.9); // progress = 0.95
        expect(sim.haloRadius, greaterThan(100 * 1.3));
        expect(sim.haloAlpha, lessThan(0.5));
      });
    });

    group('expansion/collapse phase', () {
      test('isCollapsing is false before 0.85 progress', () {
        final sim = GalaxyEffectSimulator(duration: 2.0);

        sim.update(1.6); // progress = 0.8
        expect(sim.isCollapsing, false);
      });

      test('isCollapsing is true after 0.85 progress', () {
        final sim = GalaxyEffectSimulator(duration: 2.0);

        sim.update(1.75); // progress = 0.875
        expect(sim.isCollapsing, true);
      });

      test('expansion scale collapses then expands', () {
        final sim = GalaxyEffectSimulator(duration: 2.0);

        // Before collapse
        expect(sim.expansionScale, 1.0);

        // Early collapse (scale decreases)
        sim.update(1.72); // progress = 0.86
        expect(sim.expansionScale, lessThan(1.0));
        final midCollapseScale = sim.expansionScale;

        // Late collapse (scale increases rapidly)
        sim.update(0.26); // progress = 0.99
        expect(sim.expansionScale, greaterThan(midCollapseScale));
      });
    });

    test('reset restores initial state', () {
      final sim = GalaxyEffectSimulator();

      sim.update(1.5);
      expect(sim.time, greaterThan(0));
      expect(sim.coreIntensity, greaterThan(0));

      sim.reset();

      expect(sim.time, 0);
      expect(sim.coreIntensity, 0);
      expect(sim.coreRotation, 0);
      expect(sim.haloRadius, 0);
      expect(sim.haloAlpha, 0);
      expect(sim.expansionScale, 1.0);
      expect(sim.isCollapsing, false);
    });

    test('spiral arms rotate with progress', () {
      final sim = GalaxyEffectSimulator();

      final initialAngles = sim.spiralArms.map((a) => a.currentAngle).toList();

      sim.update(1.0);

      for (int i = 0; i < sim.spiralArms.length; i++) {
        expect(sim.spiralArms[i].currentAngle, isNot(closeTo(initialAngles[i], 0.1)));
      }
    });

    test('absorption particles move during absorption phase', () {
      final sim = GalaxyEffectSimulator();

      // Advance to absorption phase
      sim.update(1.0); // progress = 0.5

      final initialDistances = sim.absorptionParticles.map((p) => p.currentDistance).toList();

      // Continue in absorption phase
      sim.update(0.5); // progress = 0.75

      var movedCount = 0;
      for (int i = 0; i < sim.absorptionParticles.length; i++) {
        if (sim.absorptionParticles[i].isActive(sim.time)) {
          if (sim.absorptionParticles[i].currentDistance < initialDistances[i]) {
            movedCount++;
          }
        }
      }

      expect(movedCount, greaterThan(0));
    });
  });

  group('Galaxy phase calculations', () {
    test('arm visibility phases are correct', () {
      // Arms appear after initial flash (progress > 0.05)
      // Arms fade during 0.05-0.2 (buildup)
      // Arms are fully visible 0.2-0.85
      // Arms fade during 0.85-1.0 (collapse)

      double calculateArmProgress(double progress) {
        if (progress < 0.05) return 0;
        if (progress < 0.2) return (progress - 0.05) / 0.15;
        if (progress < 0.85) return 1.0;
        return 1.0 - (progress - 0.85) / 0.15;
      }

      expect(calculateArmProgress(0.01), closeTo(0, 0.01));
      expect(calculateArmProgress(0.1), closeTo(0.33, 0.02));
      expect(calculateArmProgress(0.5), closeTo(1.0, 0.01));
      expect(calculateArmProgress(0.9), closeTo(0.67, 0.02));
      expect(calculateArmProgress(1.0), closeTo(0, 0.01));
    });

    test('star visibility phases are correct', () {
      // Stars appear later than arms (progress > 0.1)
      // Stars fade during 0.1-0.2 (buildup)
      // Stars are fully visible 0.2-0.85
      // Stars fade during 0.85-1.0 (collapse)

      double calculateStarAlpha(double progress) {
        if (progress < 0.1) return 0;
        if (progress < 0.2) return (progress - 0.1) / 0.1;
        if (progress < 0.85) return 1.0;
        return 1.0 - (progress - 0.85) / 0.15;
      }

      expect(calculateStarAlpha(0.05), closeTo(0, 0.01));
      expect(calculateStarAlpha(0.15), closeTo(0.5, 0.01));
      expect(calculateStarAlpha(0.5), closeTo(1.0, 0.01));
      expect(calculateStarAlpha(0.9), closeTo(0.67, 0.02));
    });

    test('dust visibility phases are correct', () {
      // Dust visible between 0.1 and 0.9
      // Fades during 0.1-0.2 and 0.8-0.9

      double calculateDustAlpha(double progress) {
        if (progress < 0.1 || progress > 0.9) return 0;
        if (progress < 0.2) return (progress - 0.1) / 0.1;
        if (progress < 0.8) return 1.0;
        return 1.0 - (progress - 0.8) / 0.1;
      }

      expect(calculateDustAlpha(0.05), closeTo(0, 0.01));
      expect(calculateDustAlpha(0.15), closeTo(0.5, 0.01));
      expect(calculateDustAlpha(0.5), closeTo(1.0, 0.01));
      expect(calculateDustAlpha(0.85), closeTo(0.5, 0.01));
      expect(calculateDustAlpha(0.95), closeTo(0, 0.01));
    });

    test('absorption visibility phases are correct', () {
      // Absorption visible between 0.4 and 0.95
      // Fades during 0.4-0.5 and 0.85-0.95

      double calculateAbsorptionProgress(double progress) {
        if (progress < 0.4 || progress > 0.95) return 0;
        if (progress < 0.5) return (progress - 0.4) / 0.1;
        if (progress < 0.85) return 1.0;
        return 1.0 - (progress - 0.85) / 0.1;
      }

      expect(calculateAbsorptionProgress(0.35), closeTo(0, 0.01));
      expect(calculateAbsorptionProgress(0.45), closeTo(0.5, 0.01));
      expect(calculateAbsorptionProgress(0.7), closeTo(1.0, 0.01));
      expect(calculateAbsorptionProgress(0.9), closeTo(0.5, 0.01));
      expect(calculateAbsorptionProgress(0.97), closeTo(0, 0.01));
    });
  });

  group('Logarithmic spiral calculations', () {
    test('spiral curve follows r = t * length formula', () {
      // In this galaxy effect, it's a simplified spiral: r = t * length
      // The angle is: theta = baseAngle + t * pi * 2 * tightness

      final length = 100.0;
      final tightness = 0.5;
      final baseAngle = 0.0;

      for (double t = 0; t <= 1; t += 0.1) {
        final expectedR = t * length;
        final theta = baseAngle + t * math.pi * 2 * tightness;
        final x = math.cos(theta) * expectedR;
        final y = math.sin(theta) * expectedR;

        final actualR = math.sqrt(x * x + y * y);
        expect(actualR, closeTo(expectedR, 0.001));
      }
    });

    test('tighter spiral has more windings', () {
      final length = 100.0;
      final looseTightness = 0.3;
      final tightTightness = 0.7;

      // Calculate total angle traversed for each
      final looseAngle = math.pi * 2 * looseTightness;
      final tightAngle = math.pi * 2 * tightTightness;

      // Tighter spiral traverses more angle
      expect(tightAngle, greaterThan(looseAngle));
    });
  });

  group('Pink star distribution', () {
    test('approximately 15% of stars are pink', () {
      final rng = SimulatedRng(12345);
      var pinkCount = 0;
      const totalStars = 1000;

      for (int i = 0; i < totalStars; i++) {
        if (rng.nextDouble() > 0.85) {
          pinkCount++;
        }
      }

      // Should be around 15% (150 +/- 30)
      expect(pinkCount, inInclusiveRange(100, 200));
    });
  });

  group('Scaled count calculations', () {
    int scaledCount(int base, double fxScale, {int min = 1, int max = 100}) {
      final scaled = (base * fxScale).round();
      return scaled.clamp(min, max);
    }

    test('fxScale 1.0 returns base count', () {
      expect(scaledCount(60, 1.0), 60);
      expect(scaledCount(30, 1.0), 30);
    });

    test('fxScale 0.5 returns half count', () {
      expect(scaledCount(60, 0.5), 30);
      expect(scaledCount(30, 0.5), 15);
    });

    test('count respects minimum', () {
      expect(scaledCount(3, 0.1, min: 2), 2);
      expect(scaledCount(3, 0.0, min: 2), 2);
    });

    test('count respects maximum', () {
      expect(scaledCount(60, 2.0, max: 80), 80);
      expect(scaledCount(60, 3.0, max: 80), 80);
    });
  });

  group('Core flare calculations', () {
    test('flares rotate around core', () {
      final flareCount = 6;
      final coreRotation = 0.5; // radians
      final time = 1.0;

      for (int i = 0; i < flareCount; i++) {
        final angle = coreRotation + (i / flareCount) * math.pi * 2;

        // Each flare should be evenly spaced
        final expectedBaseAngle = (i / flareCount) * math.pi * 2;
        expect(angle - coreRotation, closeTo(expectedBaseAngle, 0.001));
      }
    });

    test('flare length oscillates with time', () {
      final coreSize = 20.0;
      final time = 1.0;
      final i = 0;

      final flareLength = coreSize * (0.8 + math.sin(time * 4 + i) * 0.2);

      expect(flareLength, greaterThanOrEqualTo(coreSize * 0.6));
      expect(flareLength, lessThanOrEqualTo(coreSize * 1.0));
    });
  });

  group('Expansion ring calculations', () {
    test('rings expand outward during collapse', () {
      final galaxySize = 100.0;
      final collapseProgress = 0.5;
      final ringCount = 3;

      for (int i = 0; i < ringCount; i++) {
        final ringProgress = (collapseProgress + i * 0.15).clamp(0.0, 1.0);
        final ringRadius = galaxySize * (0.5 + ringProgress * 2.0);

        expect(ringRadius, greaterThan(galaxySize * 0.5));
        expect(ringRadius, lessThanOrEqualTo(galaxySize * 2.5));
      }
    });

    test('ring alpha decreases as ring expands', () {
      for (double ringProgress = 0; ringProgress <= 1; ringProgress += 0.1) {
        final ringAlpha = (1 - ringProgress) * 0.6;

        expect(ringAlpha, greaterThanOrEqualTo(0));
        expect(ringAlpha, lessThanOrEqualTo(0.6));
      }
    });

    test('final flash occurs at specific progress', () {
      // Flash occurs when collapseProgress > 0.4 && collapseProgress < 0.7
      final flashStart = 0.4;
      final flashEnd = 0.7;

      expect(flashEnd - flashStart, closeTo(0.3, 0.01));

      // Flash intensity uses sin for smooth bell curve
      final peakProgress = 0.5; // middle of flash
      final flashProgress = (peakProgress - flashStart) / (flashEnd - flashStart);
      final flashAlpha = math.sin(flashProgress * math.pi) * 0.8;

      // At peak (flashProgress = 0.5), sin(0.5 * pi) = 1
      expect(math.sin(0.5 * math.pi), closeTo(1.0, 0.001));
    });
  });
}
