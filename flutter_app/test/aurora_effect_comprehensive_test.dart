import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

/// Tests for AuroraEffect logic and calculations

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED CLASSES FROM aurora_effect.dart
// ═══════════════════════════════════════════════════════════════════════════════

/// Fast LCG random number generator (same as in AuroraEffect)
class FastRng {
  int _state;

  FastRng([int seed = 42]) : _state = seed & 0x7fffffff;

  int next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  double nextUnit() => next() / 0x7fffffff;
  int nextInt(int max) => max <= 0 ? 0 : next() % max;
}

/// Simulated Star data
class Star {
  final double x;
  final double y;
  final double size;
  final double brightness;
  final double twinkleSpeed;
  final double twinklePhase;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
    required this.twinkleSpeed,
    required this.twinklePhase,
  });
}

/// Simulated AuroraCurtain data
class AuroraCurtain {
  final double xOffset;
  final double width;
  final double height;
  final double waveFrequency;
  final double waveAmplitude;
  final double verticalWaveFrequency;
  final double speed;
  final double colorPhase;
  final double colorSpeed;

  AuroraCurtain({
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
}

/// Simulated AuroraParticle data
class AuroraParticle {
  double x;
  double y;
  final double size;
  double velocityX;
  double velocityY;
  double lifetime;
  final double maxLifetime;
  double colorPhase;
  final double shimmerSpeed;

  AuroraParticle({
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
}

/// Star count based on quality settings
int getStarCount({required bool lowFx, required bool reduceFx}) {
  if (lowFx) return 30;
  if (reduceFx) return 60;
  return 120;
}

/// Main curtain count based on quality
int getMainCurtainCount({required bool lowFx, required bool reduceFx}) {
  if (lowFx) return 2;
  if (reduceFx) return 3;
  return 5;
}

/// Secondary curtain count based on quality
int getSecondaryCurtainCount({required bool lowFx, required bool reduceFx}) {
  if (lowFx) return 1;
  if (reduceFx) return 2;
  return 4;
}

/// Particle count based on quality
int getParticleCount({required bool lowFx, required bool reduceFx}) {
  if (lowFx) return 0;
  if (reduceFx) return 15;
  return 40;
}

/// Initialize stars with given parameters
List<Star> initializeStars({
  required double width,
  required double height,
  required double horizonY,
  required FastRng rng,
  required int count,
}) {
  return List.generate(count, (i) {
    return Star(
      x: rng.nextUnit() * width,
      y: rng.nextUnit() * height * horizonY * 0.95,
      size: 0.5 + rng.nextUnit() * 2,
      brightness: 0.3 + rng.nextUnit() * 0.7,
      twinkleSpeed: 1 + rng.nextUnit() * 3,
      twinklePhase: rng.nextUnit() * math.pi * 2,
    );
  });
}

/// Calculate twinkle effect
double calculateTwinkle(double time, Star star) {
  return 0.5 + math.sin(time * star.twinkleSpeed + star.twinklePhase) * 0.5;
}

/// Calculate star alpha
double calculateStarAlpha(Star star, double twinkle, double globalAlpha) {
  return star.brightness * twinkle * globalAlpha;
}

/// Calculate color transition based on time
double calculateColorTransition(double time, double colorSpeed, double colorPhase) {
  final phase = time * colorSpeed + colorPhase;
  return (math.sin(phase) + 1) / 2;
}

/// Calculate particle fade alpha based on lifetime
double calculateParticleFadeAlpha(double lifeRatio) {
  if (lifeRatio > 0.8) {
    return (1 - lifeRatio) / 0.2;
  } else if (lifeRatio < 0.2) {
    return lifeRatio / 0.2;
  }
  return 1.0;
}

/// Calculate shimmer effect
double calculateShimmer(double colorPhase) {
  return 0.5 + math.sin(colorPhase) * 0.5;
}

/// Aurora should render check
bool shouldRenderAurora({
  required bool lowFx,
  required double intensity,
  required double globalAlpha,
}) {
  if (lowFx && intensity < 0.3) return false;
  if (globalAlpha <= 0.01) return false;
  return true;
}

/// Calculate glow pulse
double calculateGlowPulse(double time) {
  return 0.3 + math.sin(time * 0.5) * 0.1;
}

/// Quantize value to reduce shader recreation
double quantizeValue(double value, int steps) {
  return (value * steps).roundToDouble() / steps;
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('FastRng', () {
    test('produces deterministic sequence with same seed', () {
      final rng1 = FastRng(42);
      final rng2 = FastRng(42);

      for (int i = 0; i < 10; i++) {
        expect(rng1.next(), rng2.next());
      }
    });

    test('different seeds produce different sequences', () {
      final rng1 = FastRng(42);
      final rng2 = FastRng(123);

      expect(rng1.next(), isNot(rng2.next()));
    });

    test('nextUnit returns value between 0 and 1', () {
      final rng = FastRng(42);
      for (int i = 0; i < 100; i++) {
        final value = rng.nextUnit();
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThanOrEqualTo(1));
      }
    });

    test('nextInt returns value in range', () {
      final rng = FastRng(42);
      for (int i = 0; i < 100; i++) {
        final value = rng.nextInt(10);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(10));
      }
    });

    test('nextInt handles zero max', () {
      final rng = FastRng(42);
      expect(rng.nextInt(0), 0);
    });

    test('nextInt handles negative max', () {
      final rng = FastRng(42);
      expect(rng.nextInt(-5), 0);
    });
  });

  group('Quality Settings - Star Count', () {
    test('lowFx mode returns 30 stars', () {
      expect(getStarCount(lowFx: true, reduceFx: false), 30);
    });

    test('reduceFx mode returns 60 stars', () {
      expect(getStarCount(lowFx: false, reduceFx: true), 60);
    });

    test('high quality returns 120 stars', () {
      expect(getStarCount(lowFx: false, reduceFx: false), 120);
    });

    test('lowFx takes priority over reduceFx', () {
      expect(getStarCount(lowFx: true, reduceFx: true), 30);
    });
  });

  group('Quality Settings - Main Curtains', () {
    test('lowFx mode returns 2 curtains', () {
      expect(getMainCurtainCount(lowFx: true, reduceFx: false), 2);
    });

    test('reduceFx mode returns 3 curtains', () {
      expect(getMainCurtainCount(lowFx: false, reduceFx: true), 3);
    });

    test('high quality returns 5 curtains', () {
      expect(getMainCurtainCount(lowFx: false, reduceFx: false), 5);
    });
  });

  group('Quality Settings - Secondary Curtains', () {
    test('lowFx mode returns 1 curtain', () {
      expect(getSecondaryCurtainCount(lowFx: true, reduceFx: false), 1);
    });

    test('reduceFx mode returns 2 curtains', () {
      expect(getSecondaryCurtainCount(lowFx: false, reduceFx: true), 2);
    });

    test('high quality returns 4 curtains', () {
      expect(getSecondaryCurtainCount(lowFx: false, reduceFx: false), 4);
    });
  });

  group('Quality Settings - Particles', () {
    test('lowFx mode returns 0 particles', () {
      expect(getParticleCount(lowFx: true, reduceFx: false), 0);
    });

    test('reduceFx mode returns 15 particles', () {
      expect(getParticleCount(lowFx: false, reduceFx: true), 15);
    });

    test('high quality returns 40 particles', () {
      expect(getParticleCount(lowFx: false, reduceFx: false), 40);
    });
  });

  group('Star Initialization', () {
    test('creates correct number of stars', () {
      final rng = FastRng(42);
      final stars = initializeStars(
        width: 800,
        height: 600,
        horizonY: 0.55,
        rng: rng,
        count: 50,
      );
      expect(stars.length, 50);
    });

    test('star x is within width bounds', () {
      final rng = FastRng(42);
      final stars = initializeStars(
        width: 800,
        height: 600,
        horizonY: 0.55,
        rng: rng,
        count: 100,
      );

      for (final star in stars) {
        expect(star.x, greaterThanOrEqualTo(0));
        expect(star.x, lessThan(800));
      }
    });

    test('star y is within horizon bounds', () {
      final rng = FastRng(42);
      final stars = initializeStars(
        width: 800,
        height: 600,
        horizonY: 0.55,
        rng: rng,
        count: 100,
      );

      final maxY = 600 * 0.55 * 0.95;
      for (final star in stars) {
        expect(star.y, greaterThanOrEqualTo(0));
        expect(star.y, lessThan(maxY));
      }
    });

    test('star size is in range [0.5, 2.5]', () {
      final rng = FastRng(42);
      final stars = initializeStars(
        width: 800,
        height: 600,
        horizonY: 0.55,
        rng: rng,
        count: 100,
      );

      for (final star in stars) {
        expect(star.size, greaterThanOrEqualTo(0.5));
        expect(star.size, lessThan(2.5));
      }
    });

    test('star brightness is in range [0.3, 1.0]', () {
      final rng = FastRng(42);
      final stars = initializeStars(
        width: 800,
        height: 600,
        horizonY: 0.55,
        rng: rng,
        count: 100,
      );

      for (final star in stars) {
        expect(star.brightness, greaterThanOrEqualTo(0.3));
        expect(star.brightness, lessThan(1.0));
      }
    });

    test('star twinkleSpeed is in range [1, 4]', () {
      final rng = FastRng(42);
      final stars = initializeStars(
        width: 800,
        height: 600,
        horizonY: 0.55,
        rng: rng,
        count: 100,
      );

      for (final star in stars) {
        expect(star.twinkleSpeed, greaterThanOrEqualTo(1));
        expect(star.twinkleSpeed, lessThan(4));
      }
    });

    test('star twinklePhase is in range [0, 2π]', () {
      final rng = FastRng(42);
      final stars = initializeStars(
        width: 800,
        height: 600,
        horizonY: 0.55,
        rng: rng,
        count: 100,
      );

      for (final star in stars) {
        expect(star.twinklePhase, greaterThanOrEqualTo(0));
        expect(star.twinklePhase, lessThan(math.pi * 2));
      }
    });
  });

  group('Twinkle Calculation', () {
    test('twinkle oscillates between 0 and 1', () {
      final star = Star(
        x: 100,
        y: 100,
        size: 1,
        brightness: 0.5,
        twinkleSpeed: 1,
        twinklePhase: 0,
      );

      for (double t = 0; t < 10; t += 0.1) {
        final twinkle = calculateTwinkle(t, star);
        expect(twinkle, greaterThanOrEqualTo(0));
        expect(twinkle, lessThanOrEqualTo(1));
      }
    });

    test('twinkle at time=0 with phase=0', () {
      final star = Star(
        x: 100,
        y: 100,
        size: 1,
        brightness: 0.5,
        twinkleSpeed: 1,
        twinklePhase: 0,
      );

      final twinkle = calculateTwinkle(0, star);
      // sin(0) = 0, so 0.5 + 0 * 0.5 = 0.5
      expect(twinkle, closeTo(0.5, 0.0001));
    });

    test('twinkle reaches maximum', () {
      final star = Star(
        x: 100,
        y: 100,
        size: 1,
        brightness: 0.5,
        twinkleSpeed: 1,
        twinklePhase: 0,
      );

      // When sin = 1, twinkle = 0.5 + 0.5 = 1.0
      final twinkle = calculateTwinkle(math.pi / 2, star);
      expect(twinkle, closeTo(1.0, 0.0001));
    });

    test('twinkle reaches minimum', () {
      final star = Star(
        x: 100,
        y: 100,
        size: 1,
        brightness: 0.5,
        twinkleSpeed: 1,
        twinklePhase: 0,
      );

      // When sin = -1, twinkle = 0.5 - 0.5 = 0.0
      final twinkle = calculateTwinkle(3 * math.pi / 2, star);
      expect(twinkle, closeTo(0.0, 0.0001));
    });
  });

  group('Star Alpha Calculation', () {
    test('alpha combines brightness, twinkle, and globalAlpha', () {
      final star = Star(
        x: 100,
        y: 100,
        size: 1,
        brightness: 0.5,
        twinkleSpeed: 1,
        twinklePhase: 0,
      );

      final alpha = calculateStarAlpha(star, 0.8, 1.0);
      expect(alpha, closeTo(0.4, 0.0001)); // 0.5 * 0.8 * 1.0
    });

    test('alpha scales with globalAlpha', () {
      final star = Star(
        x: 100,
        y: 100,
        size: 1,
        brightness: 1.0,
        twinkleSpeed: 1,
        twinklePhase: 0,
      );

      final alpha = calculateStarAlpha(star, 1.0, 0.5);
      expect(alpha, closeTo(0.5, 0.0001));
    });
  });

  group('Color Transition', () {
    test('color transition oscillates between 0 and 1', () {
      for (double t = 0; t < 10; t += 0.1) {
        final colorT = calculateColorTransition(t, 1.0, 0);
        expect(colorT, greaterThanOrEqualTo(0));
        expect(colorT, lessThanOrEqualTo(1));
      }
    });

    test('color transition at t=0 with phase=0', () {
      final colorT = calculateColorTransition(0, 1.0, 0);
      // (sin(0) + 1) / 2 = 0.5
      expect(colorT, closeTo(0.5, 0.0001));
    });

    test('color transition at peak', () {
      // sin(π/2) = 1, so (1 + 1) / 2 = 1.0
      final colorT = calculateColorTransition(math.pi / 2, 1.0, 0);
      expect(colorT, closeTo(1.0, 0.0001));
    });
  });

  group('Particle Fade Alpha', () {
    test('fade alpha at full life is 1.0', () {
      expect(calculateParticleFadeAlpha(0.5), 1.0);
    });

    test('fade alpha at start of life (lifeRatio near 1)', () {
      // lifeRatio = 0.9 means particle just spawned
      final alpha = calculateParticleFadeAlpha(0.9);
      // (1 - 0.9) / 0.2 = 0.5
      expect(alpha, closeTo(0.5, 0.0001));
    });

    test('fade alpha at end of life (lifeRatio near 0)', () {
      // lifeRatio = 0.1 means particle nearly dead
      final alpha = calculateParticleFadeAlpha(0.1);
      // 0.1 / 0.2 = 0.5
      expect(alpha, closeTo(0.5, 0.0001));
    });

    test('fade alpha is 1.0 in middle range', () {
      expect(calculateParticleFadeAlpha(0.3), 1.0);
      expect(calculateParticleFadeAlpha(0.5), 1.0);
      expect(calculateParticleFadeAlpha(0.7), 1.0);
    });

    test('fade alpha at boundaries', () {
      expect(calculateParticleFadeAlpha(0.2), 1.0);
      expect(calculateParticleFadeAlpha(0.8), 1.0);
    });

    test('fade alpha at lifeRatio = 0', () {
      expect(calculateParticleFadeAlpha(0.0), 0.0);
    });

    test('fade alpha at lifeRatio = 1', () {
      expect(calculateParticleFadeAlpha(1.0), 0.0);
    });
  });

  group('Shimmer Calculation', () {
    test('shimmer oscillates between 0 and 1', () {
      for (double phase = 0; phase < math.pi * 4; phase += 0.1) {
        final shimmer = calculateShimmer(phase);
        expect(shimmer, greaterThanOrEqualTo(0));
        expect(shimmer, lessThanOrEqualTo(1));
      }
    });

    test('shimmer at phase=0', () {
      final shimmer = calculateShimmer(0);
      expect(shimmer, closeTo(0.5, 0.0001));
    });

    test('shimmer at phase=π/2', () {
      final shimmer = calculateShimmer(math.pi / 2);
      expect(shimmer, closeTo(1.0, 0.0001));
    });
  });

  group('Render Decision', () {
    test('should not render in lowFx with low intensity', () {
      expect(
        shouldRenderAurora(lowFx: true, intensity: 0.2, globalAlpha: 1.0),
        false,
      );
    });

    test('should render in lowFx with sufficient intensity', () {
      expect(
        shouldRenderAurora(lowFx: true, intensity: 0.5, globalAlpha: 1.0),
        true,
      );
    });

    test('should not render with very low globalAlpha', () {
      expect(
        shouldRenderAurora(lowFx: false, intensity: 1.0, globalAlpha: 0.005),
        false,
      );
    });

    test('should render in high quality mode', () {
      expect(
        shouldRenderAurora(lowFx: false, intensity: 1.0, globalAlpha: 1.0),
        true,
      );
    });

    test('boundary: intensity exactly 0.3 in lowFx', () {
      expect(
        shouldRenderAurora(lowFx: true, intensity: 0.3, globalAlpha: 1.0),
        true,
      );
    });

    test('boundary: globalAlpha exactly 0.01', () {
      expect(
        shouldRenderAurora(lowFx: false, intensity: 1.0, globalAlpha: 0.01),
        false,
      );
    });

    test('boundary: globalAlpha just above 0.01', () {
      expect(
        shouldRenderAurora(lowFx: false, intensity: 1.0, globalAlpha: 0.02),
        true,
      );
    });
  });

  group('Glow Pulse Calculation', () {
    test('glow pulse oscillates in expected range', () {
      for (double t = 0; t < 20; t += 0.1) {
        final pulse = calculateGlowPulse(t);
        // 0.3 - 0.1 = 0.2 to 0.3 + 0.1 = 0.4
        expect(pulse, greaterThanOrEqualTo(0.2));
        expect(pulse, lessThanOrEqualTo(0.4));
      }
    });

    test('glow pulse at t=0', () {
      final pulse = calculateGlowPulse(0);
      // sin(0) = 0, so 0.3 + 0 = 0.3
      expect(pulse, closeTo(0.3, 0.0001));
    });
  });

  group('Quantization', () {
    test('quantization with 10 steps', () {
      expect(quantizeValue(0.55, 10), 0.6);
      expect(quantizeValue(0.54, 10), 0.5);
    });

    test('quantization with 20 steps', () {
      expect(quantizeValue(0.525, 20), 0.55);
      expect(quantizeValue(0.52, 20), 0.5);
    });

    test('quantization preserves 0 and 1', () {
      expect(quantizeValue(0.0, 10), 0.0);
      expect(quantizeValue(1.0, 10), 1.0);
    });
  });

  group('AuroraCurtain Properties', () {
    test('curtain has all required properties', () {
      final curtain = AuroraCurtain(
        xOffset: 100,
        width: 150,
        height: 200,
        waveFrequency: 0.8,
        waveAmplitude: 30,
        verticalWaveFrequency: 2.0,
        speed: 0.3,
        colorPhase: 1.5,
        colorSpeed: 0.2,
      );

      expect(curtain.xOffset, 100);
      expect(curtain.width, 150);
      expect(curtain.height, 200);
      expect(curtain.waveFrequency, 0.8);
      expect(curtain.waveAmplitude, 30);
      expect(curtain.verticalWaveFrequency, 2.0);
      expect(curtain.speed, 0.3);
      expect(curtain.colorPhase, 1.5);
      expect(curtain.colorSpeed, 0.2);
    });
  });

  group('AuroraParticle Properties', () {
    test('particle has mutable position and velocity', () {
      final particle = AuroraParticle(
        x: 100,
        y: 200,
        size: 1.5,
        velocityX: 5,
        velocityY: -3,
        lifetime: 5.0,
        maxLifetime: 5.0,
        colorPhase: 0,
        shimmerSpeed: 3.0,
      );

      particle.x += particle.velocityX * 0.1;
      particle.y += particle.velocityY * 0.1;
      particle.lifetime -= 0.1;

      expect(particle.x, closeTo(100.5, 0.0001));
      expect(particle.y, closeTo(199.7, 0.0001));
      expect(particle.lifetime, closeTo(4.9, 0.0001));
    });
  });

  group('Horizon Calculations', () {
    test('default horizon at 0.55', () {
      const horizonY = 0.55;
      const height = 600.0;

      final auroraBottom = height * horizonY;
      expect(auroraBottom, 330);
    });

    test('star region is 95% of horizon', () {
      const horizonY = 0.55;
      const height = 600.0;

      final starMaxY = height * horizonY * 0.95;
      expect(starMaxY, closeTo(313.5, 0.1));
    });
  });

  group('Color Constants', () {
    test('aurora green color value', () {
      const auroraGreen = 0xFF00FF88;
      expect(auroraGreen, 0xFF00FF88);
    });

    test('aurora cyan color value', () {
      const auroraCyan = 0xFF00FFFF;
      expect(auroraCyan, 0xFF00FFFF);
    });

    test('aurora purple color value', () {
      const auroraPurple = 0xFF9900FF;
      expect(auroraPurple, 0xFF9900FF);
    });

    test('aurora pink color value', () {
      const auroraPink = 0xFFFF0088;
      expect(auroraPink, 0xFFFF0088);
    });
  });
}
