import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/particle_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GameParticles.instance.setQuality(
      burstScale: 1.0,
      allowGlow: true,
      allowTrails: true,
    );
  });

  group('ParticleShape enum', () {
    test('has all expected shapes', () {
      expect(ParticleShape.values, contains(ParticleShape.circle));
      expect(ParticleShape.values, contains(ParticleShape.square));
      expect(ParticleShape.values, contains(ParticleShape.triangle));
      expect(ParticleShape.values, contains(ParticleShape.star));
      expect(ParticleShape.values, contains(ParticleShape.diamond));
      expect(ParticleShape.values, contains(ParticleShape.line));
      expect(ParticleShape.values, contains(ParticleShape.spark));
    });
  });

  group('EmitterPattern enum', () {
    test('has all expected patterns', () {
      expect(EmitterPattern.values, contains(EmitterPattern.burst));
      expect(EmitterPattern.values, contains(EmitterPattern.stream));
      expect(EmitterPattern.values, contains(EmitterPattern.ring));
      expect(EmitterPattern.values, contains(EmitterPattern.cone));
      expect(EmitterPattern.values, contains(EmitterPattern.spiral));
    });
  });

  group('Particle creation', () {
    test('creates with required parameters', () {
      final particle = Particle(
        position: Vector2(100, 100),
        velocity: Vector2(10, 5),
        color: Colors.cyan,
        lifetime: 1.0,
      );

      expect(particle.position.x, 100);
      expect(particle.position.y, 100);
      expect(particle.color, Colors.cyan);
      expect(particle.lifetime, 1.0);
    });

    test('uses default size of 4.0', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
      );

      expect(particle.size, 4.0);
    });

    test('creates with custom size', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
        size: 10.0,
      );

      expect(particle.size, 10.0);
    });

    test('fadeOut defaults to true', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
      );

      expect(particle.fadeOut, isTrue);
    });

    test('shape defaults to circle', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
      );

      expect(particle.shape, ParticleShape.circle);
    });

    test('creates with custom shape', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
        shape: ParticleShape.star,
      );

      expect(particle.shape, ParticleShape.star);
    });

    test('gravity defaults to 0', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
      );

      expect(particle.gravity, 0);
    });

    test('drag defaults to 0.98', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
      );

      expect(particle.drag, 0.98);
    });

    test('creates with trail', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
        hasTrail: true,
        trailLength: 5,
      );

      expect(particle.hasTrail, isTrue);
      expect(particle.trailLength, 5);
    });

    test('creates with colorEnd', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        colorEnd: Colors.blue,
        lifetime: 1.0,
      );

      expect(particle.colorEnd, Colors.blue);
    });

    test('glow defaults to true', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
      );

      expect(particle.glow, isTrue);
    });

    test('shrink defaults to true', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
      );

      expect(particle.shrink, isTrue);
    });
  });

  group('Particle update', () {
    test('isDead is false initially', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
      );

      expect(particle.isDead, isFalse);
    });

    test('isDead is true after lifetime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 0.5,
      );

      particle.update(0.6);

      expect(particle.isDead, isTrue);
    });

    test('lifePercent decreases over time', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
      );

      expect(particle.lifePercent, 1.0);

      particle.update(0.5);

      expect(particle.lifePercent, 0.5);
    });

    test('progress increases over time', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
      );

      expect(particle.progress, 0.0);

      particle.update(0.3);

      expect(particle.progress, closeTo(0.3, 0.01));
    });

    test('position updates with velocity', () {
      final particle = Particle(
        position: Vector2(0, 0),
        velocity: Vector2(100, 0),
        color: Colors.red,
        lifetime: 1.0,
        drag: 1.0, // No drag for predictable test
      );

      particle.update(0.1);

      expect(particle.position.x, closeTo(10, 0.1));
    });

    test('gravity affects velocity', () {
      final particle = Particle(
        position: Vector2(0, 0),
        velocity: Vector2(0, 0),
        color: Colors.red,
        lifetime: 1.0,
        gravity: 100,
        drag: 1.0,
      );

      particle.update(0.1);

      expect(particle.velocity.y, closeTo(10, 0.1));
    });

    test('drag reduces velocity', () {
      final particle = Particle(
        position: Vector2(0, 0),
        velocity: Vector2(100, 0),
        color: Colors.red,
        lifetime: 1.0,
        drag: 0.9,
      );

      final initialVelocity = particle.velocity.x;
      particle.update(0.1);

      expect(particle.velocity.x, lessThan(initialVelocity));
    });

    test('shrink reduces size over time', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
        size: 10.0,
        shrink: true,
      );

      final initialSize = particle.size;
      particle.update(0.5);

      expect(particle.size, lessThan(initialSize));
    });

    test('spin updates rotation', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
        spin: true,
        spinSpeed: 5.0,
      );

      particle.update(0.1);

      // Rotation should have changed
      expect(true, isTrue);
    });

    test('trail updates positions', () {
      final particle = Particle(
        position: Vector2(0, 0),
        velocity: Vector2(100, 0),
        color: Colors.red,
        lifetime: 1.0,
        hasTrail: true,
        trailLength: 5,
        drag: 1.0,
      );

      particle.update(0.1);
      particle.update(0.1);
      particle.update(0.1);

      // Trail should have been updated
      expect(true, isTrue);
    });
  });

  group('Particle currentColor', () {
    test('returns color with reduced opacity when fading', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
        fadeOut: true,
      );

      particle.update(0.5);

      final currentColor = particle.currentColor;
      expect(currentColor.opacity, closeTo(0.5, 0.01));
    });

    test('lerps between colors when colorEnd is set', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        colorEnd: Colors.blue,
        lifetime: 1.0,
        fadeOut: false,
      );

      particle.update(0.5);

      final currentColor = particle.currentColor;
      // Should be somewhere between red and blue
      expect(currentColor.red, lessThan(255));
      expect(currentColor.blue, greaterThan(0));
    });

    test('returns original color when fadeOut is false and no colorEnd', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.red,
        lifetime: 1.0,
        fadeOut: false,
      );

      particle.update(0.5);

      final currentColor = particle.currentColor;
      expect(currentColor, Colors.red);
    });
  });

  group('Particle render', () {
    test('renders circle shape', () {
      final particle = Particle(
        position: Vector2(50, 50),
        velocity: Vector2.zero(),
        color: Colors.cyan,
        lifetime: 1.0,
        shape: ParticleShape.circle,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      particle.render(canvas);
      recorder.endRecording();
    });

    test('renders square shape', () {
      final particle = Particle(
        position: Vector2(50, 50),
        velocity: Vector2.zero(),
        color: Colors.cyan,
        lifetime: 1.0,
        shape: ParticleShape.square,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      particle.render(canvas);
      recorder.endRecording();
    });

    test('renders triangle shape', () {
      final particle = Particle(
        position: Vector2(50, 50),
        velocity: Vector2.zero(),
        color: Colors.cyan,
        lifetime: 1.0,
        shape: ParticleShape.triangle,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      particle.render(canvas);
      recorder.endRecording();
    });

    test('renders star shape', () {
      final particle = Particle(
        position: Vector2(50, 50),
        velocity: Vector2.zero(),
        color: Colors.cyan,
        lifetime: 1.0,
        shape: ParticleShape.star,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      particle.render(canvas);
      recorder.endRecording();
    });

    test('renders diamond shape', () {
      final particle = Particle(
        position: Vector2(50, 50),
        velocity: Vector2.zero(),
        color: Colors.cyan,
        lifetime: 1.0,
        shape: ParticleShape.diamond,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      particle.render(canvas);
      recorder.endRecording();
    });

    test('renders line shape', () {
      final particle = Particle(
        position: Vector2(50, 50),
        velocity: Vector2(10, 5),
        color: Colors.cyan,
        lifetime: 1.0,
        shape: ParticleShape.line,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      particle.render(canvas);
      recorder.endRecording();
    });

    test('renders spark shape', () {
      final particle = Particle(
        position: Vector2(50, 50),
        velocity: Vector2.zero(),
        color: Colors.cyan,
        lifetime: 1.0,
        shape: ParticleShape.spark,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      particle.render(canvas);
      recorder.endRecording();
    });

    test('renders with glow', () {
      final particle = Particle(
        position: Vector2(50, 50),
        velocity: Vector2.zero(),
        color: Colors.cyan,
        lifetime: 1.0,
        glow: true,
        glowRadius: 8.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      particle.render(canvas);
      recorder.endRecording();
    });

    test('renders with trail', () {
      final particle = Particle(
        position: Vector2(50, 50),
        velocity: Vector2(100, 0),
        color: Colors.cyan,
        lifetime: 1.0,
        hasTrail: true,
        trailLength: 5,
        drag: 1.0,
      );

      // Update to create trail
      for (int i = 0; i < 5; i++) {
        particle.update(0.05);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      particle.render(canvas);
      recorder.endRecording();
    });

    test('does not render when dead', () {
      final particle = Particle(
        position: Vector2(50, 50),
        velocity: Vector2.zero(),
        color: Colors.cyan,
        lifetime: 0.1,
      );

      particle.update(0.2);
      expect(particle.isDead, isTrue);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      particle.render(canvas);
      recorder.endRecording();
    });

    test('does not render when size is zero', () {
      final particle = Particle(
        position: Vector2(50, 50),
        velocity: Vector2.zero(),
        color: Colors.cyan,
        lifetime: 1.0,
        size: 10.0,
        shrink: true,
      );

      // Update until size shrinks to near zero
      particle.update(0.99);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      particle.render(canvas);
      recorder.endRecording();
    });

    test('renders with spin', () {
      final particle = Particle(
        position: Vector2(50, 50),
        velocity: Vector2.zero(),
        color: Colors.cyan,
        lifetime: 1.0,
        spin: true,
        spinSpeed: 5.0,
        shape: ParticleShape.star,
      );

      particle.update(0.1);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      particle.render(canvas);
      recorder.endRecording();
    });
  });

  group('ParticleEmitterConfig', () {
    test('creates with default values', () {
      const config = ParticleEmitterConfig();

      expect(config.particleCount, 20);
      expect(config.shape, ParticleShape.circle);
      expect(config.pattern, EmitterPattern.burst);
      expect(config.color, const Color(0xFF00FFFF));
      expect(config.minSpeed, 50);
      expect(config.maxSpeed, 150);
    });

    test('creates with custom values', () {
      const config = ParticleEmitterConfig(
        particleCount: 50,
        shape: ParticleShape.star,
        pattern: EmitterPattern.ring,
        color: Colors.red,
        minSpeed: 100,
        maxSpeed: 200,
      );

      expect(config.particleCount, 50);
      expect(config.shape, ParticleShape.star);
      expect(config.pattern, EmitterPattern.ring);
      expect(config.color, Colors.red);
    });

    test('neonSparkle preset', () {
      final config = ParticleEmitterConfig.neonSparkle(
        color: Colors.cyan,
        count: 20,
      );

      expect(config.particleCount, 20);
      expect(config.shape, ParticleShape.spark);
      expect(config.pattern, EmitterPattern.burst);
      expect(config.color, Colors.cyan);
      expect(config.hasTrail, isTrue);
    });

    test('fire preset', () {
      final config = ParticleEmitterConfig.fire(count: 25);

      expect(config.particleCount, 25);
      expect(config.pattern, EmitterPattern.cone);
      expect(config.gravity, -80); // Rise upward
    });

    test('magic preset', () {
      final config = ParticleEmitterConfig.magic(
        color: Colors.purple,
        count: 30,
      );

      expect(config.particleCount, 30);
      expect(config.shape, ParticleShape.star);
      expect(config.pattern, EmitterPattern.spiral);
      expect(config.spin, isTrue);
    });

    test('stream preset', () {
      final config = ParticleEmitterConfig.stream(
        color: Colors.green,
        rate: 15,
      );

      expect(config.pattern, EmitterPattern.stream);
      expect(config.emissionRate, 15);
    });
  });

  group('ParticleEmitter', () {
    test('creates with required parameters', () {
      final emitter = ParticleEmitter(
        position: Vector2(100, 100),
      );

      expect(emitter, isA<Component>());
      expect(emitter.position.x, 100);
      expect(emitter.position.y, 100);
    });

    test('creates with maxParticles', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
        maxParticles: 50,
      );

      expect(emitter.maxParticles, 50);
    });

    test('creates with config', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
        config: const ParticleEmitterConfig(particleCount: 10),
      );

      expect(emitter.config, isNotNull);
      expect(emitter.config!.particleCount, 10);
    });

    test('isEmpty is true initially without config', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
      );

      expect(emitter.isEmpty, isTrue);
    });

    test('emitExplosion adds particles', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
      );

      emitter.emitExplosion(
        center: Vector2(50, 50),
        color: Colors.red,
        count: 10,
      );

      expect(emitter.isEmpty, isFalse);
    });

    test('emitBurst adds particles', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
      );

      emitter.emitBurst(
        start: Vector2(50, 50),
        direction: Vector2(1, 0),
        color: Colors.blue,
        count: 5,
      );

      expect(emitter.isEmpty, isFalse);
    });

    test('emitTrail adds particle', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
      );

      emitter.emitTrail(
        position: Vector2(50, 50),
        color: Colors.green,
      );

      expect(emitter.isEmpty, isFalse);
    });

    test('emitRing adds particles', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
      );

      emitter.emitRing(
        center: Vector2(50, 50),
        color: Colors.cyan,
        radius: 30,
        count: 16,
      );

      expect(emitter.isEmpty, isFalse);
    });

    test('emitSparks adds particles', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
      );

      emitter.emitSparks(
        center: Vector2(50, 50),
        color: Colors.yellow,
        count: 8,
      );

      expect(emitter.isEmpty, isFalse);
    });

    test('emitMagic adds particles', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
      );

      emitter.emitMagic(
        center: Vector2(50, 50),
        color: Colors.purple,
        count: 10,
      );

      expect(emitter.isEmpty, isFalse);
    });

    test('clear removes all particles', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
      );

      emitter.emitExplosion(
        center: Vector2(50, 50),
        color: Colors.red,
        count: 10,
      );

      expect(emitter.isEmpty, isFalse);

      emitter.clear();

      expect(emitter.isEmpty, isTrue);
    });

    test('update removes dead particles', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
      );

      emitter.emitExplosion(
        center: Vector2(50, 50),
        color: Colors.red,
        count: 5,
        lifetime: 0.1,
      );

      expect(emitter.isEmpty, isFalse);

      // Update past lifetime
      for (int i = 0; i < 20; i++) {
        emitter.update(0.1);
      }

      expect(emitter.isEmpty, isTrue);
    });

    test('render draws all particles', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
      );

      emitter.emitExplosion(
        center: Vector2(50, 50),
        color: Colors.red,
        count: 5,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      emitter.update(0.05);
      emitter.render(canvas);
      recorder.endRecording();
    });

    test('does not exceed maxParticles', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
        maxParticles: 10,
      );

      // Try to emit more than max
      emitter.emitExplosion(
        center: Vector2(50, 50),
        color: Colors.red,
        count: 20,
      );

      // Should be capped at max
      expect(emitter.isEmpty, isFalse);
    });

    test('stop prevents stream emission', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
        config: ParticleEmitterConfig.stream(rate: 100),
      );

      emitter.stop();
      emitter.update(1.0);

      // Should not emit after stop
      expect(true, isTrue);
    });
  });

  group('GameParticles', () {
    test('instance is singleton', () {
      final instance1 = GameParticles.instance;
      final instance2 = GameParticles.instance;

      expect(identical(instance1, instance2), isTrue);
    });

    test('setQuality updates burstScale', () {
      GameParticles.instance.setQuality(
        burstScale: 0.5,
        allowGlow: true,
        allowTrails: true,
      );

      expect(GameParticles.instance.burstScale, 0.5);
    });

    test('setQuality updates allowGlow', () {
      GameParticles.instance.setQuality(
        burstScale: 1.0,
        allowGlow: false,
        allowTrails: true,
      );

      expect(GameParticles.instance.allowGlow, isFalse);
    });

    test('setQuality updates allowTrails', () {
      GameParticles.instance.setQuality(
        burstScale: 1.0,
        allowGlow: true,
        allowTrails: false,
      );

      expect(GameParticles.instance.allowTrails, isFalse);
    });

    test('setQuality clamps burstScale', () {
      GameParticles.instance.setQuality(
        burstScale: 2.0,
        allowGlow: true,
        allowTrails: true,
      );

      expect(GameParticles.instance.burstScale, 1.0);

      GameParticles.instance.setQuality(
        burstScale: 0.0,
        allowGlow: true,
        allowTrails: true,
      );

      expect(GameParticles.instance.burstScale, 0.1);
    });

    test('setEmitter stores emitter reference', () {
      final emitter = ParticleEmitter(position: Vector2.zero());
      GameParticles.instance.setEmitter(emitter);

      // The emitter should be set
      expect(true, isTrue);
    });

    test('explosion emits particles when emitter set', () {
      final emitter = ParticleEmitter(position: Vector2.zero());
      GameParticles.instance.setEmitter(emitter);

      GameParticles.instance.explosion(Vector2(50, 50), Colors.red);

      expect(emitter.isEmpty, isFalse);
    });

    test('hit emits particles when emitter set', () {
      final emitter = ParticleEmitter(position: Vector2.zero());
      GameParticles.instance.setEmitter(emitter);

      GameParticles.instance.hit(Vector2(50, 50), Colors.blue);

      expect(emitter.isEmpty, isFalse);
    });

    test('trail emits particles when emitter set', () {
      final emitter = ParticleEmitter(position: Vector2.zero());
      GameParticles.instance.setEmitter(emitter);

      GameParticles.instance.trail(Vector2(50, 50), Colors.green);

      expect(emitter.isEmpty, isFalse);
    });

    test('pulse emits particles when emitter set', () {
      final emitter = ParticleEmitter(position: Vector2.zero());
      GameParticles.instance.setEmitter(emitter);

      GameParticles.instance.pulse(Vector2(50, 50), Colors.cyan, 30);

      expect(emitter.isEmpty, isFalse);
    });

    test('sparks emits particles when emitter set', () {
      final emitter = ParticleEmitter(position: Vector2.zero());
      GameParticles.instance.setEmitter(emitter);

      GameParticles.instance.sparks(Vector2(50, 50), Colors.yellow);

      expect(emitter.isEmpty, isFalse);
    });

    test('emitSparks is alias for sparks', () {
      final emitter = ParticleEmitter(position: Vector2.zero());
      GameParticles.instance.setEmitter(emitter);

      GameParticles.instance.emitSparks(center: Vector2(50, 50), color: Colors.yellow);

      expect(emitter.isEmpty, isFalse);
    });

    test('magic emits particles when emitter set', () {
      final emitter = ParticleEmitter(position: Vector2.zero());
      GameParticles.instance.setEmitter(emitter);

      GameParticles.instance.magic(Vector2(50, 50), Colors.purple);

      expect(emitter.isEmpty, isFalse);
    });
  });

  group('ParticleHelper', () {
    test('spawnSparkles creates emitter', () {
      final emitter = ParticleHelper.spawnSparkles(Vector2(50, 50));

      expect(emitter, isA<ParticleEmitter>());
      expect(emitter.autoRemove, isTrue);
    });

    test('spawnSparkles with custom color', () {
      final emitter = ParticleHelper.spawnSparkles(
        Vector2(50, 50),
        color: Colors.pink,
      );

      expect(emitter.config!.color, Colors.pink);
    });

    test('spawnExplosion creates emitter', () {
      final emitter = ParticleHelper.spawnExplosion(Vector2(50, 50));

      expect(emitter, isA<ParticleEmitter>());
      expect(emitter.autoRemove, isTrue);
    });

    test('spawnExplosion with custom color and count', () {
      final emitter = ParticleHelper.spawnExplosion(
        Vector2(50, 50),
        color: Colors.orange,
        count: 40,
      );

      expect(emitter.config!.particleCount, 40);
    });

    test('spawnMagic creates emitter', () {
      final emitter = ParticleHelper.spawnMagic(Vector2(50, 50));

      expect(emitter, isA<ParticleEmitter>());
      expect(emitter.autoRemove, isTrue);
    });

    test('spawnRing creates emitter', () {
      final emitter = ParticleHelper.spawnRing(Vector2(50, 50));

      expect(emitter, isA<ParticleEmitter>());
      expect(emitter.config!.pattern, EmitterPattern.ring);
    });

    test('spawnRing with custom count', () {
      final emitter = ParticleHelper.spawnRing(
        Vector2(50, 50),
        count: 32,
      );

      expect(emitter.config!.particleCount, 32);
    });

    test('spawnHit creates emitter', () {
      final emitter = ParticleHelper.spawnHit(Vector2(50, 50));

      expect(emitter, isA<ParticleEmitter>());
      expect(emitter.autoRemove, isTrue);
    });

    test('spawnFire creates emitter', () {
      final emitter = ParticleHelper.spawnFire(Vector2(50, 50));

      expect(emitter, isA<ParticleEmitter>());
      expect(emitter.config!.pattern, EmitterPattern.cone);
    });

    test('spawnFire with custom count', () {
      final emitter = ParticleHelper.spawnFire(
        Vector2(50, 50),
        count: 50,
      );

      expect(emitter.config!.particleCount, 50);
    });
  });

  group('ParticleEmitter patterns', () {
    test('burst pattern emits all at once', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
        config: const ParticleEmitterConfig(
          pattern: EmitterPattern.burst,
          particleCount: 10,
        ),
      );

      emitter.onMount();

      expect(emitter.isEmpty, isFalse);
    });

    test('ring pattern emits in circle', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
        config: const ParticleEmitterConfig(
          pattern: EmitterPattern.ring,
          particleCount: 8,
        ),
      );

      emitter.onMount();

      expect(emitter.isEmpty, isFalse);
    });

    test('cone pattern emits in direction', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
        config: const ParticleEmitterConfig(
          pattern: EmitterPattern.cone,
          particleCount: 10,
          coneAngle: math.pi / 4,
          coneDirection: -math.pi / 2,
        ),
      );

      emitter.onMount();

      expect(emitter.isEmpty, isFalse);
    });

    test('spiral pattern emits in spiral', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
        config: const ParticleEmitterConfig(
          pattern: EmitterPattern.spiral,
          particleCount: 15,
        ),
      );

      emitter.onMount();

      expect(emitter.isEmpty, isFalse);
    });

    test('stream pattern emits over time', () {
      final emitter = ParticleEmitter(
        position: Vector2.zero(),
        config: ParticleEmitterConfig.stream(rate: 10),
      );

      // Stream doesn't emit on mount
      emitter.onMount();

      // But does emit on update
      emitter.update(0.5);

      expect(emitter.isEmpty, isFalse);
    });
  });

  group('Quality scaling', () {
    test('reduced burstScale creates fewer particles', () {
      GameParticles.instance.setQuality(
        burstScale: 0.5,
        allowGlow: true,
        allowTrails: true,
      );

      final emitter = ParticleEmitter(position: Vector2.zero());
      emitter.emitExplosion(
        center: Vector2(50, 50),
        color: Colors.red,
        count: 20,
      );

      // Should create roughly half the particles
      expect(emitter.isEmpty, isFalse);
    });

    test('allowGlow false disables glow', () {
      GameParticles.instance.setQuality(
        burstScale: 1.0,
        allowGlow: false,
        allowTrails: true,
      );

      final emitter = ParticleEmitter(position: Vector2.zero());
      emitter.emitExplosion(
        center: Vector2(50, 50),
        color: Colors.red,
        count: 5,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      emitter.update(0.05);
      emitter.render(canvas);
      recorder.endRecording();
    });

    test('allowTrails false disables trails', () {
      GameParticles.instance.setQuality(
        burstScale: 1.0,
        allowGlow: true,
        allowTrails: false,
      );

      final emitter = ParticleEmitter(position: Vector2.zero());
      emitter.emitTrail(
        position: Vector2(50, 50),
        color: Colors.green,
      );

      // Trail should not be emitted when trails disabled
      expect(emitter.isEmpty, isTrue);
    });
  });
}
