import 'dart:math' as math;
import 'package:test/test.dart';

/// Simulation tests for AuroraEffect - northern lights background effect.
/// Tests: LCG RNG, star generation, curtain parameters, particle updates,
/// quality level adjustments, color interpolation.

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED LCG RNG - Exact copy from aurora_effect.dart
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedAuroraRng {
  int _state;

  SimulatedAuroraRng([int seed = 42]) : _state = seed;

  int lcgNext() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  double nextUnit() => lcgNext() / 0x7fffffff;

  int nextInt(int max) => max <= 0 ? 0 : lcgNext() % max;

  int get state => _state;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedStar {
  final double x;
  final double y;
  final double size;
  final double brightness;
  final double twinkleSpeed;
  final double twinklePhase;

  SimulatedStar({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
    required this.twinkleSpeed,
    required this.twinklePhase,
  });

  /// Calculate current twinkle value at given time
  double getTwinkle(double time) {
    return 0.5 + math.sin(time * twinkleSpeed + twinklePhase) * 0.5;
  }

  /// Calculate current alpha at given time with global alpha
  double getAlpha(double time, double globalAlpha) {
    return brightness * getTwinkle(time) * globalAlpha;
  }
}

class SimulatedAuroraCurtain {
  final double xOffset;
  final double width;
  final double height;
  final double waveFrequency;
  final double waveAmplitude;
  final double verticalWaveFrequency;
  final double speed;
  final double colorPhase;
  final double colorSpeed;

  SimulatedAuroraCurtain({
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

  /// Calculate color t value at given time (0-1 range)
  double getColorT(double time) {
    final phase = time * colorSpeed + colorPhase;
    return (math.sin(phase) + 1) / 2;
  }

  /// Calculate wave offset at given time
  double getWaveOffset(double time) {
    return time * speed;
  }

  /// Calculate horizontal wave position at given t (0-1 along curtain height)
  double getHorizontalWave(double time, double t) {
    final waveOffset = getWaveOffset(time);
    final wave = math.sin(waveOffset * waveFrequency + t * verticalWaveFrequency);
    return wave * waveAmplitude * (1 - t * 0.3);
  }
}

class SimulatedAuroraParticle {
  double x;
  double y;
  final double size;
  double velocityX;
  double velocityY;
  double lifetime;
  final double maxLifetime;
  double colorPhase;
  final double shimmerSpeed;

  SimulatedAuroraParticle({
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

  /// Update particle position and state
  void update(double dt) {
    x += velocityX * dt;
    y += velocityY * dt;
    lifetime -= dt;
    colorPhase += shimmerSpeed * dt;
  }

  /// Get life ratio (0-1)
  double get lifeRatio => lifetime / maxLifetime;

  /// Calculate fade alpha based on life ratio
  double getFadeAlpha() {
    final ratio = lifeRatio;
    if (ratio <= 0) return 0;
    if (ratio > 0.8) return (1 - ratio) / 0.2;
    if (ratio < 0.2) return ratio / 0.2;
    return 1.0;
  }

  /// Calculate shimmer value
  double getShimmer() {
    return 0.5 + math.sin(colorPhase) * 0.5;
  }

  /// Get current alpha
  double getAlpha(double globalAlpha) {
    return globalAlpha * getFadeAlpha() * getShimmer();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED AURORA EFFECT GENERATOR
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedAuroraGenerator {
  final SimulatedAuroraRng _rng;
  final double width;
  final double height;
  final double horizonY;
  bool reduceFx;
  bool lowFx;
  double intensity;

  SimulatedAuroraGenerator({
    required this.width,
    required this.height,
    this.horizonY = 0.55,
    this.reduceFx = false,
    this.lowFx = false,
    this.intensity = 1.0,
    int seed = 42,
  }) : _rng = SimulatedAuroraRng(seed);

  List<SimulatedStar> generateStars() {
    final starCount = lowFx ? 30 : (reduceFx ? 60 : 120);
    return List.generate(starCount, (i) {
      return SimulatedStar(
        x: _rng.nextUnit() * width,
        y: _rng.nextUnit() * height * horizonY * 0.95,
        size: 0.5 + _rng.nextUnit() * 2,
        brightness: 0.3 + _rng.nextUnit() * 0.7,
        twinkleSpeed: 1 + _rng.nextUnit() * 3,
        twinklePhase: _rng.nextUnit() * math.pi * 2,
      );
    });
  }

  List<SimulatedAuroraCurtain> generateMainCurtains() {
    final curtainCount = lowFx ? 2 : (reduceFx ? 3 : 5);
    return List.generate(curtainCount, (i) {
      final t = i / curtainCount;
      return SimulatedAuroraCurtain(
        xOffset: t * width * 0.8,
        width: 150 + _rng.nextUnit() * 200,
        height: height * horizonY * (0.4 + _rng.nextUnit() * 0.3),
        waveFrequency: 0.8 + _rng.nextUnit() * 0.6,
        waveAmplitude: 30 + _rng.nextUnit() * 50,
        verticalWaveFrequency: 2 + _rng.nextUnit() * 2,
        speed: 0.3 + _rng.nextUnit() * 0.4,
        colorPhase: _rng.nextUnit() * math.pi * 2,
        colorSpeed: 0.2 + _rng.nextUnit() * 0.3,
      );
    });
  }

  List<SimulatedAuroraCurtain> generateSecondaryCurtains() {
    final curtainCount = lowFx ? 1 : (reduceFx ? 2 : 4);
    return List.generate(curtainCount, (i) {
      final t = i / curtainCount;
      return SimulatedAuroraCurtain(
        xOffset: t * width + _rng.nextUnit() * 100,
        width: 200 + _rng.nextUnit() * 300,
        height: height * horizonY * (0.25 + _rng.nextUnit() * 0.2),
        waveFrequency: 0.5 + _rng.nextUnit() * 0.4,
        waveAmplitude: 40 + _rng.nextUnit() * 60,
        verticalWaveFrequency: 1.5 + _rng.nextUnit() * 1.5,
        speed: 0.15 + _rng.nextUnit() * 0.25,
        colorPhase: _rng.nextUnit() * math.pi * 2 + math.pi,
        colorSpeed: 0.15 + _rng.nextUnit() * 0.2,
      );
    });
  }

  List<SimulatedAuroraParticle> generateParticles() {
    final particleCount = lowFx ? 0 : (reduceFx ? 15 : 40);
    return List.generate(particleCount, (i) {
      final maxLife = 3 + _rng.nextUnit() * 4;
      return SimulatedAuroraParticle(
        x: _rng.nextUnit() * width,
        y: _rng.nextUnit() * height * horizonY * 0.8,
        size: 1 + _rng.nextUnit() * 2.5,
        velocityX: (_rng.nextUnit() - 0.5) * 8,
        velocityY: (_rng.nextUnit() - 0.5) * 4,
        lifetime: maxLife,
        maxLifetime: maxLife,
        colorPhase: _rng.nextUnit() * math.pi * 2,
        shimmerSpeed: 3 + _rng.nextUnit() * 4,
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COLOR INTERPOLATION HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

class SimulatedColor {
  final int value;
  const SimulatedColor(this.value);

  int get r => (value >> 16) & 0xFF;
  int get g => (value >> 8) & 0xFF;
  int get b => value & 0xFF;

  static SimulatedColor lerp(SimulatedColor a, SimulatedColor b, double t) {
    final r = (a.r + (b.r - a.r) * t).round().clamp(0, 255);
    final g = (a.g + (b.g - a.g) * t).round().clamp(0, 255);
    final bl = (a.b + (b.b - a.b) * t).round().clamp(0, 255);
    return SimulatedColor(0xFF000000 | (r << 16) | (g << 8) | bl);
  }
}

/// Aurora color palette
const auroraGreen = SimulatedColor(0xFF00FF88);
const auroraCyan = SimulatedColor(0xFF00FFFF);
const auroraPurple = SimulatedColor(0xFF9900FF);
const auroraPink = SimulatedColor(0xFFFF0088);

/// Get aurora color for given t value (0-1)
SimulatedColor getAuroraColor(double t) {
  final quantizedT = (t * 24).roundToDouble() / 24;

  if (quantizedT < 0.25) {
    return SimulatedColor.lerp(auroraGreen, auroraCyan, quantizedT / 0.25);
  } else if (quantizedT < 0.5) {
    return SimulatedColor.lerp(auroraCyan, auroraPurple, (quantizedT - 0.25) / 0.25);
  } else if (quantizedT < 0.75) {
    return SimulatedColor.lerp(auroraPurple, auroraPink, (quantizedT - 0.5) / 0.25);
  } else {
    return SimulatedColor.lerp(auroraPink, auroraGreen, (quantizedT - 0.75) / 0.25);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEST SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('SimulatedAuroraRng', () {
    test('same seed produces same sequence', () {
      final rng1 = SimulatedAuroraRng(42);
      final rng2 = SimulatedAuroraRng(42);

      for (int i = 0; i < 100; i++) {
        expect(rng1.nextUnit(), equals(rng2.nextUnit()));
      }
    });

    test('nextUnit returns values in [0, 1)', () {
      final rng = SimulatedAuroraRng();
      for (int i = 0; i < 1000; i++) {
        final value = rng.nextUnit();
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThan(1.0));
      }
    });

    test('nextInt respects bounds', () {
      final rng = SimulatedAuroraRng();
      for (int max = 1; max <= 100; max++) {
        for (int i = 0; i < 10; i++) {
          final value = rng.nextInt(max);
          expect(value, greaterThanOrEqualTo(0));
          expect(value, lessThan(max));
        }
      }
    });

    test('nextInt with zero or negative returns 0', () {
      final rng = SimulatedAuroraRng();
      expect(rng.nextInt(0), equals(0));
      expect(rng.nextInt(-5), equals(0));
    });

    test('LCG formula is correct', () {
      final rng = SimulatedAuroraRng(1);

      // First step
      final s1 = rng.lcgNext();
      expect(s1, equals((1664525 * 1 + 1013904223) & 0x7fffffff));
      expect(rng.state, equals(1015568748));

      // Second step
      final s2 = rng.lcgNext();
      expect(s2, equals((1664525 * 1015568748 + 1013904223) & 0x7fffffff));
      expect(rng.state, equals(s2));
    });
  });

  group('Star Generation', () {
    test('generates correct count for each quality level', () {
      final fullQuality = SimulatedAuroraGenerator(
        width: 800,
        height: 600,
        lowFx: false,
        reduceFx: false,
      );
      expect(fullQuality.generateStars().length, equals(120));

      final reducedQuality = SimulatedAuroraGenerator(
        width: 800,
        height: 600,
        lowFx: false,
        reduceFx: true,
      );
      expect(reducedQuality.generateStars().length, equals(60));

      final lowQuality = SimulatedAuroraGenerator(
        width: 800,
        height: 600,
        lowFx: true,
        reduceFx: false,
      );
      expect(lowQuality.generateStars().length, equals(30));
    });

    test('stars are within bounds', () {
      final gen = SimulatedAuroraGenerator(width: 800, height: 600);
      final stars = gen.generateStars();

      for (final star in stars) {
        expect(star.x, greaterThanOrEqualTo(0));
        expect(star.x, lessThan(800));
        expect(star.y, greaterThanOrEqualTo(0));
        expect(star.y, lessThan(600 * 0.55 * 0.95)); // horizonY * 0.95
      }
    });

    test('star properties are within valid ranges', () {
      final gen = SimulatedAuroraGenerator(width: 800, height: 600);
      final stars = gen.generateStars();

      for (final star in stars) {
        expect(star.size, greaterThanOrEqualTo(0.5));
        expect(star.size, lessThan(2.5));
        expect(star.brightness, greaterThanOrEqualTo(0.3));
        expect(star.brightness, lessThan(1.0));
        expect(star.twinkleSpeed, greaterThanOrEqualTo(1));
        expect(star.twinkleSpeed, lessThan(4));
        expect(star.twinklePhase, greaterThanOrEqualTo(0));
        expect(star.twinklePhase, lessThan(math.pi * 2));
      }
    });

    test('star twinkle calculation', () {
      final star = SimulatedStar(
        x: 100,
        y: 100,
        size: 1.5,
        brightness: 0.8,
        twinkleSpeed: 2,
        twinklePhase: 0,
      );

      // At time 0, twinkle = 0.5 + sin(0) * 0.5 = 0.5
      expect(star.getTwinkle(0), closeTo(0.5, 0.001));

      // At time pi/4, twinkle = 0.5 + sin(pi/2) * 0.5 = 1.0
      expect(star.getTwinkle(math.pi / 4), closeTo(1.0, 0.001));
    });
  });

  group('Curtain Generation', () {
    test('main curtains count by quality', () {
      final full = SimulatedAuroraGenerator(width: 800, height: 600);
      expect(full.generateMainCurtains().length, equals(5));

      final reduced = SimulatedAuroraGenerator(width: 800, height: 600, reduceFx: true);
      expect(reduced.generateMainCurtains().length, equals(3));

      final low = SimulatedAuroraGenerator(width: 800, height: 600, lowFx: true);
      expect(low.generateMainCurtains().length, equals(2));
    });

    test('secondary curtains count by quality', () {
      final full = SimulatedAuroraGenerator(width: 800, height: 600);
      expect(full.generateSecondaryCurtains().length, equals(4));

      final reduced = SimulatedAuroraGenerator(width: 800, height: 600, reduceFx: true);
      expect(reduced.generateSecondaryCurtains().length, equals(2));

      final low = SimulatedAuroraGenerator(width: 800, height: 600, lowFx: true);
      expect(low.generateSecondaryCurtains().length, equals(1));
    });

    test('curtain properties are valid', () {
      final gen = SimulatedAuroraGenerator(width: 800, height: 600);
      final curtains = gen.generateMainCurtains();

      for (final curtain in curtains) {
        expect(curtain.width, greaterThanOrEqualTo(150));
        expect(curtain.width, lessThan(350));
        expect(curtain.waveAmplitude, greaterThanOrEqualTo(30));
        expect(curtain.waveAmplitude, lessThan(80));
        expect(curtain.speed, greaterThanOrEqualTo(0.3));
        expect(curtain.speed, lessThan(0.7));
      }
    });

    test('curtain color oscillation', () {
      final curtain = SimulatedAuroraCurtain(
        xOffset: 100,
        width: 200,
        height: 300,
        waveFrequency: 1,
        waveAmplitude: 50,
        verticalWaveFrequency: 2,
        speed: 0.5,
        colorPhase: 0,
        colorSpeed: 1,
      );

      // Color t oscillates between 0 and 1
      final t0 = curtain.getColorT(0);
      expect(t0, closeTo(0.5, 0.001)); // sin(0) + 1) / 2 = 0.5

      final tPiHalf = curtain.getColorT(math.pi / 2);
      expect(tPiHalf, closeTo(1.0, 0.001)); // (sin(pi/2) + 1) / 2 = 1.0
    });

    test('curtain wave calculation', () {
      final curtain = SimulatedAuroraCurtain(
        xOffset: 0,
        width: 100,
        height: 200,
        waveFrequency: 1,
        waveAmplitude: 50,
        verticalWaveFrequency: 1,
        speed: 1,
        colorPhase: 0,
        colorSpeed: 0.5,
      );

      // At t=0 (bottom), wave amplitude is full
      final waveBottom = curtain.getHorizontalWave(0, 0);
      expect(waveBottom.abs(), lessThanOrEqualTo(50)); // Within amplitude

      // At t=1 (top), amplitude is reduced by 30%
      final waveTop = curtain.getHorizontalWave(0, 1);
      expect(waveTop.abs(), lessThanOrEqualTo(35)); // 50 * 0.7
    });
  });

  group('Particle Generation', () {
    test('particle count by quality', () {
      final full = SimulatedAuroraGenerator(width: 800, height: 600);
      expect(full.generateParticles().length, equals(40));

      final reduced = SimulatedAuroraGenerator(width: 800, height: 600, reduceFx: true);
      expect(reduced.generateParticles().length, equals(15));

      final low = SimulatedAuroraGenerator(width: 800, height: 600, lowFx: true);
      expect(low.generateParticles().length, equals(0));
    });

    test('particle properties are valid', () {
      final gen = SimulatedAuroraGenerator(width: 800, height: 600);
      final particles = gen.generateParticles();

      for (final p in particles) {
        expect(p.x, greaterThanOrEqualTo(0));
        expect(p.x, lessThan(800));
        expect(p.size, greaterThanOrEqualTo(1));
        expect(p.size, lessThan(3.5));
        expect(p.velocityX, greaterThanOrEqualTo(-4));
        expect(p.velocityX, lessThan(4));
        expect(p.velocityY, greaterThanOrEqualTo(-2));
        expect(p.velocityY, lessThan(2));
        expect(p.maxLifetime, greaterThanOrEqualTo(3));
        expect(p.maxLifetime, lessThan(7));
      }
    });

    test('particle update movement', () {
      final particle = SimulatedAuroraParticle(
        x: 100,
        y: 100,
        size: 2,
        velocityX: 10,
        velocityY: -5,
        lifetime: 5,
        maxLifetime: 5,
        colorPhase: 0,
        shimmerSpeed: 2,
      );

      particle.update(1.0); // 1 second

      expect(particle.x, closeTo(110, 0.001));
      expect(particle.y, closeTo(95, 0.001));
      expect(particle.lifetime, closeTo(4, 0.001));
    });

    test('particle fade alpha calculation', () {
      final particle = SimulatedAuroraParticle(
        x: 100,
        y: 100,
        size: 2,
        velocityX: 0,
        velocityY: 0,
        lifetime: 5,
        maxLifetime: 5,
        colorPhase: 0,
        shimmerSpeed: 0,
      );

      // At full lifetime (ratio = 1.0)
      expect(particle.getFadeAlpha(), closeTo(0, 0.001)); // (1 - 1) / 0.2 = 0

      // At 90% lifetime (ratio = 0.9)
      particle.lifetime = 4.5;
      expect(particle.getFadeAlpha(), closeTo(0.5, 0.001)); // (1 - 0.9) / 0.2 = 0.5

      // At 50% lifetime (ratio = 0.5)
      particle.lifetime = 2.5;
      expect(particle.getFadeAlpha(), closeTo(1.0, 0.001)); // Middle = full

      // At 10% lifetime (ratio = 0.1)
      particle.lifetime = 0.5;
      expect(particle.getFadeAlpha(), closeTo(0.5, 0.001)); // 0.1 / 0.2 = 0.5

      // At 0% lifetime
      particle.lifetime = 0;
      expect(particle.getFadeAlpha(), closeTo(0, 0.001));
    });

    test('particle shimmer calculation', () {
      final particle = SimulatedAuroraParticle(
        x: 100,
        y: 100,
        size: 2,
        velocityX: 0,
        velocityY: 0,
        lifetime: 5,
        maxLifetime: 5,
        colorPhase: 0,
        shimmerSpeed: 1,
      );

      // At colorPhase 0: shimmer = 0.5 + sin(0) * 0.5 = 0.5
      expect(particle.getShimmer(), closeTo(0.5, 0.001));

      // At colorPhase pi/2: shimmer = 0.5 + sin(pi/2) * 0.5 = 1.0
      particle.colorPhase = math.pi / 2;
      expect(particle.getShimmer(), closeTo(1.0, 0.001));
    });
  });

  group('Color Interpolation', () {
    test('aurora color at t=0 is green', () {
      final color = getAuroraColor(0);
      expect(color.r, equals(auroraGreen.r));
      expect(color.g, equals(auroraGreen.g));
      expect(color.b, equals(auroraGreen.b));
    });

    test('aurora color cycles through all colors', () {
      // At 0.25, should be near cyan
      final cyan = getAuroraColor(0.25);
      expect(cyan.r, lessThan(50)); // Cyan has low red
      expect(cyan.g, greaterThan(200)); // High green
      expect(cyan.b, greaterThan(200)); // High blue

      // At 0.5, should be near purple
      final purple = getAuroraColor(0.5);
      expect(purple.r, greaterThan(100)); // Purple has red
      expect(purple.b, greaterThan(200)); // High blue

      // At 0.75, should be near pink
      final pink = getAuroraColor(0.75);
      expect(pink.r, greaterThan(200)); // Pink has high red
      expect(pink.b, greaterThan(100)); // Some blue
    });

    test('color lerp works correctly', () {
      final red = SimulatedColor(0xFFFF0000);
      final blue = SimulatedColor(0xFF0000FF);

      final mid = SimulatedColor.lerp(red, blue, 0.5);

      expect(mid.r, closeTo(128, 1));
      expect(mid.g, equals(0));
      expect(mid.b, closeTo(128, 1));
    });

    test('color lerp at extremes', () {
      final a = SimulatedColor(0xFF112233);
      final b = SimulatedColor(0xFFAABBCC);

      final atZero = SimulatedColor.lerp(a, b, 0);
      expect(atZero.r, equals(a.r));
      expect(atZero.g, equals(a.g));
      expect(atZero.b, equals(a.b));

      final atOne = SimulatedColor.lerp(a, b, 1);
      expect(atOne.r, equals(b.r));
      expect(atOne.g, equals(b.g));
      expect(atOne.b, equals(b.b));
    });
  });

  group('Quality Level Transitions', () {
    test('quality affects all generation counts', () {
      final gen = SimulatedAuroraGenerator(width: 800, height: 600);

      // Full quality
      gen.reduceFx = false;
      gen.lowFx = false;
      expect(gen.generateStars().length, equals(120));
      expect(gen.generateMainCurtains().length, equals(5));
      expect(gen.generateParticles().length, equals(40));

      // Reduced FX
      gen.reduceFx = true;
      gen.lowFx = false;
      // Need new generator with same seed to get consistent results
      final reduced = SimulatedAuroraGenerator(
        width: 800,
        height: 600,
        reduceFx: true,
      );
      expect(reduced.generateStars().length, equals(60));
      expect(reduced.generateMainCurtains().length, equals(3));
      expect(reduced.generateParticles().length, equals(15));

      // Low FX
      final low = SimulatedAuroraGenerator(
        width: 800,
        height: 600,
        lowFx: true,
      );
      expect(low.generateStars().length, equals(30));
      expect(low.generateMainCurtains().length, equals(2));
      expect(low.generateParticles().length, equals(0));
    });
  });

  group('Horizon Calculations', () {
    test('default horizon is 55% of height', () {
      final gen = SimulatedAuroraGenerator(width: 800, height: 600);

      expect(gen.horizonY, equals(0.55));

      // Aurora bottom would be at 600 * 0.55 = 330
      final auroraBottom = gen.height * gen.horizonY;
      expect(auroraBottom, equals(330));
    });

    test('custom horizon affects star positions', () {
      final gen = SimulatedAuroraGenerator(
        width: 800,
        height: 600,
        horizonY: 0.3, // Lower horizon
      );

      final stars = gen.generateStars();

      for (final star in stars) {
        expect(star.y, lessThan(600 * 0.3 * 0.95));
      }
    });
  });

  group('Animation Time Calculations', () {
    test('sky gradient color shift oscillates', () {
      // colorShift = sin(time * 0.1) * 0.5 + 0.5
      // Range: [0, 1]

      double getColorShift(double time) {
        return math.sin(time * 0.1) * 0.5 + 0.5;
      }

      expect(getColorShift(0), closeTo(0.5, 0.001));
      expect(getColorShift(math.pi * 5), closeTo(1.0, 0.001)); // sin(pi/2) = 1
      expect(getColorShift(math.pi * 15), closeTo(0.0, 0.001)); // sin(3pi/2) = -1
    });

    test('glow pulse oscillates', () {
      // glowPulse = 0.3 + sin(time * 0.5) * 0.1
      // Range: [0.2, 0.4]

      double getGlowPulse(double time) {
        return 0.3 + math.sin(time * 0.5) * 0.1;
      }

      expect(getGlowPulse(0), closeTo(0.3, 0.001));
      expect(getGlowPulse(math.pi), closeTo(0.4, 0.001)); // sin(pi/2) = 1
    });
  });

  group('Edge Cases', () {
    test('zero size screen', () {
      final gen = SimulatedAuroraGenerator(width: 0, height: 0);

      // Should not crash, but stars might have weird positions
      final stars = gen.generateStars();
      expect(stars, isNotEmpty); // Still generates count
    });

    test('intensity affects alpha', () {
      final particle = SimulatedAuroraParticle(
        x: 100,
        y: 100,
        size: 2,
        velocityX: 0,
        velocityY: 0,
        lifetime: 2.5, // 50% life
        maxLifetime: 5,
        colorPhase: math.pi / 2, // Max shimmer
        shimmerSpeed: 0,
      );

      // Full intensity
      expect(particle.getAlpha(1.0), closeTo(1.0, 0.001));

      // Half intensity
      expect(particle.getAlpha(0.5), closeTo(0.5, 0.001));

      // Zero intensity
      expect(particle.getAlpha(0.0), closeTo(0.0, 0.001));
    });

    test('negative time values work', () {
      final curtain = SimulatedAuroraCurtain(
        xOffset: 0,
        width: 100,
        height: 200,
        waveFrequency: 1,
        waveAmplitude: 50,
        verticalWaveFrequency: 1,
        speed: 1,
        colorPhase: 0,
        colorSpeed: 1,
      );

      // Negative time should work (sin handles it)
      final colorT = curtain.getColorT(-math.pi);
      expect(colorT, greaterThanOrEqualTo(0));
      expect(colorT, lessThanOrEqualTo(1));
    });
  });
}
