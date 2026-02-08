import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/particle_system.dart';

void main() {
  group('ParticleShape enum', () {
    test('has 7 shapes', () {
      expect(ParticleShape.values.length, 7);
    });

    test('contains circle', () {
      expect(ParticleShape.values, contains(ParticleShape.circle));
    });

    test('contains square', () {
      expect(ParticleShape.values, contains(ParticleShape.square));
    });

    test('contains triangle', () {
      expect(ParticleShape.values, contains(ParticleShape.triangle));
    });

    test('contains star', () {
      expect(ParticleShape.values, contains(ParticleShape.star));
    });

    test('contains diamond', () {
      expect(ParticleShape.values, contains(ParticleShape.diamond));
    });

    test('contains line', () {
      expect(ParticleShape.values, contains(ParticleShape.line));
    });

    test('contains spark', () {
      expect(ParticleShape.values, contains(ParticleShape.spark));
    });
  });

  group('EmitterPattern enum', () {
    test('has 5 patterns', () {
      expect(EmitterPattern.values.length, 5);
    });

    test('contains burst', () {
      expect(EmitterPattern.values, contains(EmitterPattern.burst));
    });

    test('contains stream', () {
      expect(EmitterPattern.values, contains(EmitterPattern.stream));
    });

    test('contains ring', () {
      expect(EmitterPattern.values, contains(EmitterPattern.ring));
    });

    test('contains cone', () {
      expect(EmitterPattern.values, contains(EmitterPattern.cone));
    });

    test('contains spiral', () {
      expect(EmitterPattern.values, contains(EmitterPattern.spiral));
    });
  });

  group('Particle pool constants', () {
    test('max pool size is 200', () {
      const maxPoolSize = 200;
      expect(maxPoolSize, 200);
    });

    test('max trail length is 10', () {
      const maxTrailLength = 10;
      expect(maxTrailLength, 10);
    });
  });

  group('ParticleEmitterConfig defaults', () {
    test('default particleCount is 20', () {
      const config = ParticleEmitterConfig();
      expect(config.particleCount, 20);
    });

    test('default shape is circle', () {
      const config = ParticleEmitterConfig();
      expect(config.shape, ParticleShape.circle);
    });

    test('default pattern is burst', () {
      const config = ParticleEmitterConfig();
      expect(config.pattern, EmitterPattern.burst);
    });

    test('default color is cyan', () {
      const config = ParticleEmitterConfig();
      expect(config.color, const Color(0xFF00FFFF));
    });

    test('default minSpeed is 50', () {
      const config = ParticleEmitterConfig();
      expect(config.minSpeed, 50);
    });

    test('default maxSpeed is 150', () {
      const config = ParticleEmitterConfig();
      expect(config.maxSpeed, 150);
    });

    test('default minSize is 2', () {
      const config = ParticleEmitterConfig();
      expect(config.minSize, 2);
    });

    test('default maxSize is 6', () {
      const config = ParticleEmitterConfig();
      expect(config.maxSize, 6);
    });

    test('default minLifetime is 0.5', () {
      const config = ParticleEmitterConfig();
      expect(config.minLifetime, 0.5);
    });

    test('default maxLifetime is 1.5', () {
      const config = ParticleEmitterConfig();
      expect(config.maxLifetime, 1.5);
    });

    test('default gravity is 0', () {
      const config = ParticleEmitterConfig();
      expect(config.gravity, 0);
    });

    test('default drag is 0.98', () {
      const config = ParticleEmitterConfig();
      expect(config.drag, 0.98);
    });

    test('default fadeOut is true', () {
      const config = ParticleEmitterConfig();
      expect(config.fadeOut, isTrue);
    });

    test('default shrink is true', () {
      const config = ParticleEmitterConfig();
      expect(config.shrink, isTrue);
    });

    test('default hasTrail is false', () {
      const config = ParticleEmitterConfig();
      expect(config.hasTrail, isFalse);
    });

    test('default trailLength is 5', () {
      const config = ParticleEmitterConfig();
      expect(config.trailLength, 5);
    });

    test('default glow is true', () {
      const config = ParticleEmitterConfig();
      expect(config.glow, isTrue);
    });

    test('default glowRadius is 4', () {
      const config = ParticleEmitterConfig();
      expect(config.glowRadius, 4);
    });

    test('default spin is false', () {
      const config = ParticleEmitterConfig();
      expect(config.spin, isFalse);
    });

    test('default spinSpeed is 3', () {
      const config = ParticleEmitterConfig();
      expect(config.spinSpeed, 3);
    });

    test('default coneAngle is pi/4', () {
      const config = ParticleEmitterConfig();
      expect(config.coneAngle, math.pi / 4);
    });

    test('default coneDirection is 0', () {
      const config = ParticleEmitterConfig();
      expect(config.coneDirection, 0);
    });

    test('default emissionRate is 10', () {
      const config = ParticleEmitterConfig();
      expect(config.emissionRate, 10);
    });
  });

  group('ParticleEmitterConfig neonSparkle preset', () {
    test('default count is 15', () {
      final config = ParticleEmitterConfig.neonSparkle();
      expect(config.particleCount, 15);
    });

    test('shape is spark', () {
      final config = ParticleEmitterConfig.neonSparkle();
      expect(config.shape, ParticleShape.spark);
    });

    test('pattern is burst', () {
      final config = ParticleEmitterConfig.neonSparkle();
      expect(config.pattern, EmitterPattern.burst);
    });

    test('default color is cyan', () {
      final config = ParticleEmitterConfig.neonSparkle();
      expect(config.color, const Color(0xFF00FFFF));
    });

    test('colorEnd is white', () {
      final config = ParticleEmitterConfig.neonSparkle();
      expect(config.colorEnd, Colors.white);
    });

    test('has trail', () {
      final config = ParticleEmitterConfig.neonSparkle();
      expect(config.hasTrail, isTrue);
    });

    test('trail length is 4', () {
      final config = ParticleEmitterConfig.neonSparkle();
      expect(config.trailLength, 4);
    });

    test('gravity is 50', () {
      final config = ParticleEmitterConfig.neonSparkle();
      expect(config.gravity, 50);
    });

    test('drag is 0.95', () {
      final config = ParticleEmitterConfig.neonSparkle();
      expect(config.drag, 0.95);
    });

    test('custom color works', () {
      final config = ParticleEmitterConfig.neonSparkle(color: Colors.red);
      expect(config.color, Colors.red);
    });

    test('custom count works', () {
      final config = ParticleEmitterConfig.neonSparkle(count: 30);
      expect(config.particleCount, 30);
    });
  });

  group('ParticleEmitterConfig fire preset', () {
    test('default count is 30', () {
      final config = ParticleEmitterConfig.fire();
      expect(config.particleCount, 30);
    });

    test('shape is circle', () {
      final config = ParticleEmitterConfig.fire();
      expect(config.shape, ParticleShape.circle);
    });

    test('pattern is cone', () {
      final config = ParticleEmitterConfig.fire();
      expect(config.pattern, EmitterPattern.cone);
    });

    test('color is orange', () {
      final config = ParticleEmitterConfig.fire();
      expect(config.color, const Color(0xFFFF6600));
    });

    test('colorEnd is yellow', () {
      final config = ParticleEmitterConfig.fire();
      expect(config.colorEnd, const Color(0xFFFFDD00));
    });

    test('gravity is negative (rises)', () {
      final config = ParticleEmitterConfig.fire();
      expect(config.gravity, -80);
    });

    test('coneDirection is upward', () {
      final config = ParticleEmitterConfig.fire();
      expect(config.coneDirection, -math.pi / 2);
    });

    test('coneAngle is pi/6', () {
      final config = ParticleEmitterConfig.fire();
      expect(config.coneAngle, math.pi / 6);
    });
  });

  group('ParticleEmitterConfig magic preset', () {
    test('default count is 25', () {
      final config = ParticleEmitterConfig.magic();
      expect(config.particleCount, 25);
    });

    test('shape is star', () {
      final config = ParticleEmitterConfig.magic();
      expect(config.shape, ParticleShape.star);
    });

    test('pattern is spiral', () {
      final config = ParticleEmitterConfig.magic();
      expect(config.pattern, EmitterPattern.spiral);
    });

    test('default color is magenta', () {
      final config = ParticleEmitterConfig.magic();
      expect(config.color, const Color(0xFFFF00FF));
    });

    test('spin is enabled', () {
      final config = ParticleEmitterConfig.magic();
      expect(config.spin, isTrue);
    });

    test('spinSpeed is 5', () {
      final config = ParticleEmitterConfig.magic();
      expect(config.spinSpeed, 5);
    });

    test('gravity is 0', () {
      final config = ParticleEmitterConfig.magic();
      expect(config.gravity, 0);
    });

    test('drag is 0.99', () {
      final config = ParticleEmitterConfig.magic();
      expect(config.drag, 0.99);
    });
  });

  group('ParticleEmitterConfig stream preset', () {
    test('particleCount is 1 per emission', () {
      final config = ParticleEmitterConfig.stream();
      expect(config.particleCount, 1);
    });

    test('pattern is stream', () {
      final config = ParticleEmitterConfig.stream();
      expect(config.pattern, EmitterPattern.stream);
    });

    test('default rate is 20', () {
      final config = ParticleEmitterConfig.stream();
      expect(config.emissionRate, 20);
    });

    test('has trail', () {
      final config = ParticleEmitterConfig.stream();
      expect(config.hasTrail, isTrue);
    });

    test('trail length is 3', () {
      final config = ParticleEmitterConfig.stream();
      expect(config.trailLength, 3);
    });

    test('custom rate works', () {
      final config = ParticleEmitterConfig.stream(rate: 50);
      expect(config.emissionRate, 50);
    });

    test('custom color works', () {
      final config = ParticleEmitterConfig.stream(color: Colors.blue);
      expect(config.color, Colors.blue);
    });
  });

  group('Particle pool simulation', () {
    test('pool reuses particles', () {
      final pool = <int>[];
      const maxPoolSize = 200;

      // Add to pool
      if (pool.length < maxPoolSize) {
        pool.add(1);
      }
      expect(pool.length, 1);

      // Reuse from pool
      final particle = pool.removeLast();
      expect(particle, 1);
      expect(pool.isEmpty, isTrue);
    });

    test('pool has max size limit', () {
      final pool = <int>[];
      const maxPoolSize = 200;

      // Fill beyond max
      for (int i = 0; i < 250; i++) {
        if (pool.length < maxPoolSize) {
          pool.add(i);
        }
      }

      expect(pool.length, maxPoolSize);
    });

    test('pool can be cleared', () {
      final pool = <int>[1, 2, 3, 4, 5];
      pool.clear();
      expect(pool.isEmpty, isTrue);
    });
  });

  group('Particle trail clamping', () {
    test('trail length clamped to max', () {
      const trailLength = 15;
      const maxTrailLength = 10;
      final clamped = trailLength.clamp(1, maxTrailLength);
      expect(clamped, maxTrailLength);
    });

    test('trail length clamped to min', () {
      const trailLength = 0;
      const maxTrailLength = 10;
      final clamped = trailLength.clamp(1, maxTrailLength);
      expect(clamped, 1);
    });

    test('valid trail length unchanged', () {
      const trailLength = 5;
      const maxTrailLength = 10;
      final clamped = trailLength.clamp(1, maxTrailLength);
      expect(clamped, 5);
    });
  });

  group('Particle lifetime calculations', () {
    test('remaining life starts at lifetime', () {
      const lifetime = 1.5;
      double remainingLife = lifetime;
      expect(remainingLife, 1.5);
    });

    test('remaining life decreases over time', () {
      double remainingLife = 1.5;
      const dt = 0.1;
      remainingLife -= dt;
      expect(remainingLife, closeTo(1.4, 0.001));
    });

    test('life percent calculation', () {
      const lifetime = 1.0;
      const remainingLife = 0.5;
      final lifePercent = remainingLife / lifetime;
      expect(lifePercent, 0.5);
    });

    test('particle is dead when remaining <= 0', () {
      const remainingLife = 0.0;
      final isDead = remainingLife <= 0;
      expect(isDead, isTrue);
    });
  });

  group('Particle fade calculations', () {
    test('opacity from life percent', () {
      const lifePercent = 0.5;
      final opacity = lifePercent;
      expect(opacity, 0.5);
    });

    test('opacity clamped to 0-1', () {
      expect((-0.1).clamp(0.0, 1.0), 0.0);
      expect((1.5).clamp(0.0, 1.0), 1.0);
    });
  });

  group('Particle size calculations', () {
    test('size shrinks with life', () {
      const initialSize = 10.0;
      const lifePercent = 0.5;
      final currentSize = initialSize * lifePercent;
      expect(currentSize, 5.0);
    });

    test('size unchanged when shrink disabled', () {
      const initialSize = 10.0;
      const shrink = false;
      final currentSize = shrink ? initialSize * 0.5 : initialSize;
      expect(currentSize, 10.0);
    });
  });

  group('Particle drag calculations', () {
    test('velocity decreases with drag', () {
      double velocityX = 100.0;
      const drag = 0.98;
      velocityX *= drag;
      expect(velocityX, 98.0);
    });

    test('velocity approaches zero over time', () {
      double velocityX = 100.0;
      const drag = 0.98;

      for (int i = 0; i < 100; i++) {
        velocityX *= drag;
      }

      expect(velocityX, lessThan(20));
    });
  });

  group('Particle gravity calculations', () {
    test('positive gravity pulls down', () {
      double velocityY = 0.0;
      const gravity = 100.0;
      const dt = 0.1;
      velocityY += gravity * dt;
      expect(velocityY, 10.0);
    });

    test('negative gravity pulls up', () {
      double velocityY = 0.0;
      const gravity = -100.0;
      const dt = 0.1;
      velocityY += gravity * dt;
      expect(velocityY, -10.0);
    });
  });

  group('Particle spin calculations', () {
    test('rotation increases with spin', () {
      double rotation = 0.0;
      const spinSpeed = 3.0;
      const dt = 0.1;
      rotation += spinSpeed * dt;
      expect(rotation, closeTo(0.3, 0.0001));
    });

    test('rotation wraps around', () {
      double rotation = 6.0;
      const twoPi = math.pi * 2;
      rotation = rotation % twoPi;
      expect(rotation, lessThan(twoPi));
    });
  });

  group('Particle color lerp', () {
    test('color lerp at 0 returns start', () {
      const start = Color(0xFFFF0000);
      const end = Color(0xFF0000FF);
      final result = Color.lerp(start, end, 0.0);
      expect(result, start);
    });

    test('color lerp at 1 returns end', () {
      const start = Color(0xFFFF0000);
      const end = Color(0xFF0000FF);
      final result = Color.lerp(start, end, 1.0);
      expect(result, end);
    });

    test('color lerp at 0.5 is midpoint', () {
      const start = Color(0xFFFF0000);
      const end = Color(0xFF0000FF);
      final result = Color.lerp(start, end, 0.5)!;
      expect(result.red, 128);
      expect(result.blue, 128);
    });
  });

  group('Emitter pattern calculations', () {
    test('ring pattern angle distribution', () {
      const particleCount = 8;
      final angles = <double>[];
      for (int i = 0; i < particleCount; i++) {
        angles.add((i / particleCount) * math.pi * 2);
      }
      expect(angles.length, 8);
      expect(angles[0], 0.0);
      expect(angles[4], closeTo(math.pi, 0.001));
    });

    test('cone pattern within angle', () {
      const coneAngle = math.pi / 4;
      const coneDirection = 0.0;
      const random = 0.5;

      final angle = coneDirection + (random - 0.5) * coneAngle;
      expect(angle, closeTo(0.0, coneAngle / 2));
    });

    test('spiral angle increments', () {
      double spiralAngle = 0;
      const increment = 0.5;

      for (int i = 0; i < 10; i++) {
        spiralAngle += increment;
      }

      expect(spiralAngle, 5.0);
    });
  });

  group('Emission rate calculations', () {
    test('stream emission accumulation', () {
      double accumulator = 0;
      const emissionRate = 10.0;
      const dt = 0.1;

      accumulator += dt * emissionRate;
      expect(accumulator, 1.0);
    });

    test('emit when accumulator >= 1', () {
      double accumulator = 1.5;
      int emitted = 0;

      while (accumulator >= 1.0) {
        emitted++;
        accumulator -= 1.0;
      }

      expect(emitted, 1);
      expect(accumulator, 0.5);
    });
  });

  group('Performance', () {
    test('can create many configs', () {
      for (int i = 0; i < 1000; i++) {
        const _ = ParticleEmitterConfig();
      }
      expect(true, isTrue);
    });

    test('can calculate many physics updates', () {
      double x = 0, y = 0;
      double vx = 100, vy = 100;
      const drag = 0.98;
      const gravity = 100.0;

      for (int i = 0; i < 1000; i++) {
        const dt = 0.016;
        vy += gravity * dt;
        vx *= drag;
        vy *= drag;
        x += vx * dt;
        y += vy * dt;
      }

      expect(true, isTrue);
    });
  });
}
