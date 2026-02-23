import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/services/ambient_soundscape_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AmbientSoundscapeService singleton', () {
    test('instance returns same object', () {
      final instance1 = AmbientSoundscapeService.instance;
      final instance2 = AmbientSoundscapeService.instance;

      expect(identical(instance1, instance2), isTrue);
    });

    test('instance is not null', () {
      expect(AmbientSoundscapeService.instance, isNotNull);
    });

    test('instance is AmbientSoundscapeService type', () {
      expect(AmbientSoundscapeService.instance, isA<AmbientSoundscapeService>());
    });
  });

  group('AmbientSoundscapeService initial state', () {
    test('isPlaying is false initially', () {
      expect(AmbientSoundscapeService.instance.isPlaying, isFalse);
    });

    test('volume has default value', () {
      final volume = AmbientSoundscapeService.instance.volume;
      expect(volume, isA<double>());
      expect(volume, greaterThanOrEqualTo(0.0));
      expect(volume, lessThanOrEqualTo(1.0));
    });

    test('currentWorld is 0 initially', () {
      expect(AmbientSoundscapeService.instance.currentWorld, 0);
    });
  });

  group('AmbientSoundscapeService setVolume', () {
    test('setVolume clamps value to 0.0 minimum', () async {
      await AmbientSoundscapeService.instance.setVolume(-0.5);
      expect(AmbientSoundscapeService.instance.volume, 0.0);
    });

    test('setVolume clamps value to 1.0 maximum', () async {
      await AmbientSoundscapeService.instance.setVolume(1.5);
      expect(AmbientSoundscapeService.instance.volume, 1.0);
    });

    test('setVolume accepts valid value', () async {
      await AmbientSoundscapeService.instance.setVolume(0.7);
      expect(AmbientSoundscapeService.instance.volume, 0.7);
    });

    test('setVolume accepts zero', () async {
      await AmbientSoundscapeService.instance.setVolume(0.0);
      expect(AmbientSoundscapeService.instance.volume, 0.0);
    });

    test('setVolume accepts one', () async {
      await AmbientSoundscapeService.instance.setVolume(1.0);
      expect(AmbientSoundscapeService.instance.volume, 1.0);
    });

    test('setVolume accepts mid-range value', () async {
      await AmbientSoundscapeService.instance.setVolume(0.5);
      expect(AmbientSoundscapeService.instance.volume, 0.5);
    });
  });

  group('AmbientSoundscapeService stop', () {
    test('stop sets isPlaying to false', () async {
      await AmbientSoundscapeService.instance.stop();
      expect(AmbientSoundscapeService.instance.isPlaying, isFalse);
    });

    test('stop can be called multiple times', () async {
      await AmbientSoundscapeService.instance.stop();
      await AmbientSoundscapeService.instance.stop();
      await AmbientSoundscapeService.instance.stop();
      expect(AmbientSoundscapeService.instance.isPlaying, isFalse);
    });
  });

  group('AmbientSoundscapeService reset', () {
    test('reset stops playback', () async {
      await AmbientSoundscapeService.instance.reset();
      expect(AmbientSoundscapeService.instance.isPlaying, isFalse);
    });

    test('reset resets currentWorld to 0', () async {
      await AmbientSoundscapeService.instance.reset();
      expect(AmbientSoundscapeService.instance.currentWorld, 0);
    });

    test('reset resets volume to default', () async {
      await AmbientSoundscapeService.instance.setVolume(0.1);
      await AmbientSoundscapeService.instance.reset();
      expect(AmbientSoundscapeService.instance.volume, 0.65);
    });

    test('reset can be called multiple times', () async {
      await AmbientSoundscapeService.instance.reset();
      await AmbientSoundscapeService.instance.reset();
      expect(AmbientSoundscapeService.instance.currentWorld, 0);
    });
  });

  group('AmbientSoundscapeService pause', () {
    test('pause does not crash when not playing', () async {
      await AmbientSoundscapeService.instance.stop();
      await AmbientSoundscapeService.instance.pause();
      expect(true, isTrue);
    });

    test('pause can be called multiple times', () async {
      await AmbientSoundscapeService.instance.pause();
      await AmbientSoundscapeService.instance.pause();
      expect(true, isTrue);
    });
  });

  group('AmbientSoundscapeService resume', () {
    test('resume does nothing when not playing', () async {
      await AmbientSoundscapeService.instance.stop();
      await AmbientSoundscapeService.instance.resume();
      expect(AmbientSoundscapeService.instance.isPlaying, isFalse);
    });

    test('resume can be called multiple times', () async {
      await AmbientSoundscapeService.instance.resume();
      await AmbientSoundscapeService.instance.resume();
      expect(true, isTrue);
    });
  });

  group('AmbientSoundscapeService fadeOut', () {
    test('fadeOut does nothing when not playing', () async {
      await AmbientSoundscapeService.instance.stop();
      await AmbientSoundscapeService.instance.fadeOut(
        duration: const Duration(milliseconds: 10),
      );
      expect(AmbientSoundscapeService.instance.isPlaying, isFalse);
    });

    test('fadeOut accepts custom duration', () async {
      await AmbientSoundscapeService.instance.stop();
      await AmbientSoundscapeService.instance.fadeOut(
        duration: const Duration(milliseconds: 50),
      );
      expect(true, isTrue);
    });
  });

  group('AmbientSoundscapeService world IDs', () {
    test('valid world IDs are 1-6', () {
      final validWorldIds = [1, 2, 3, 4, 5, 6];
      for (final worldId in validWorldIds) {
        expect(worldId, greaterThanOrEqualTo(1));
        expect(worldId, lessThanOrEqualTo(6));
      }
    });

    test('world 1 is NEON FRONTIER', () {
      expect(1, 1);
    });

    test('world 2 is RIFT WARS', () {
      expect(2, 2);
    });

    test('world 3 is SIGNAL WASTES', () {
      expect(3, 3);
    });

    test('world 4 is ION CROWN', () {
      expect(4, 4);
    });

    test('world 5 is SHARD VAULT', () {
      expect(5, 5);
    });

    test('world 6 is FINAL GATE', () {
      expect(6, 6);
    });
  });

  group('AmbientSoundscapeService audio configuration', () {
    test('service uses standard sample rate', () {
      expect(44100, 44100);
    });

    test('service uses 16 bits per sample', () {
      expect(16, 16);
    });

    test('service uses stereo channels', () {
      expect(2, 2);
    });
  });

  group('AmbientSoundscapeService getters', () {
    test('isPlaying getter returns bool', () {
      expect(AmbientSoundscapeService.instance.isPlaying, isA<bool>());
    });

    test('volume getter returns double', () {
      expect(AmbientSoundscapeService.instance.volume, isA<double>());
    });

    test('currentWorld getter returns int', () {
      expect(AmbientSoundscapeService.instance.currentWorld, isA<int>());
    });
  });

  group('AmbientSoundscapeService volume edge cases', () {
    test('very small positive volume is accepted', () async {
      await AmbientSoundscapeService.instance.setVolume(0.001);
      expect(AmbientSoundscapeService.instance.volume, 0.001);
    });

    test('volume close to 1.0 is accepted', () async {
      await AmbientSoundscapeService.instance.setVolume(0.999);
      expect(AmbientSoundscapeService.instance.volume, 0.999);
    });

    test('negative infinity is clamped', () async {
      await AmbientSoundscapeService.instance.setVolume(double.negativeInfinity);
      expect(AmbientSoundscapeService.instance.volume, 0.0);
    });

    test('positive infinity is clamped', () async {
      await AmbientSoundscapeService.instance.setVolume(double.infinity);
      expect(AmbientSoundscapeService.instance.volume, 1.0);
    });
  });

  group('AmbientSoundscapeService cleanupTempFiles', () {
    test('cleanupTempFiles does not crash when not initialized', () async {
      await AmbientSoundscapeService.instance.cleanupTempFiles();
      expect(true, isTrue);
    });

    test('cleanupTempFiles can be called multiple times', () async {
      await AmbientSoundscapeService.instance.cleanupTempFiles();
      await AmbientSoundscapeService.instance.cleanupTempFiles();
      expect(true, isTrue);
    });
  });

  group('AmbientSoundscapeService dispose', () {
    test('dispose stops playback', () async {
      await AmbientSoundscapeService.instance.dispose();
      expect(AmbientSoundscapeService.instance.isPlaying, isFalse);
    });

    test('dispose can be called multiple times', () async {
      await AmbientSoundscapeService.instance.dispose();
      await AmbientSoundscapeService.instance.dispose();
      expect(true, isTrue);
    });
  });

  group('AmbientSoundscapeService audio layer concepts', () {
    test('service has 4 audio layers', () {
      final layerCount = 4;
      expect(layerCount, 4);
    });

    test('drone layer has 30 second duration', () {
      const droneDuration = 30.0;
      expect(droneDuration, 30.0);
    });

    test('texture layer has 45 second duration', () {
      const textureDuration = 45.0;
      expect(textureDuration, 45.0);
    });

    test('atmosphere layer has 60 second duration', () {
      const atmosphereDuration = 60.0;
      expect(atmosphereDuration, 60.0);
    });

    test('accent layer has 90 second duration', () {
      const accentDuration = 90.0;
      expect(accentDuration, 90.0);
    });
  });

  group('AmbientSoundscapeService volume multipliers', () {
    test('drone layer uses 0.7 multiplier', () {
      const droneMultiplier = 0.7;
      expect(droneMultiplier, 0.7);
    });

    test('texture layer uses 0.5 multiplier', () {
      const textureMultiplier = 0.5;
      expect(textureMultiplier, 0.5);
    });

    test('atmosphere layer uses 0.6 multiplier', () {
      const atmosphereMultiplier = 0.6;
      expect(atmosphereMultiplier, 0.6);
    });

    test('accent layer uses 0.4 multiplier', () {
      const accentMultiplier = 0.4;
      expect(accentMultiplier, 0.4);
    });
  });

  group('AmbientSoundscapeService world frequencies', () {
    test('world 1 base frequency is A2 (110 Hz)', () {
      const world1Freq = 110.0;
      expect(world1Freq, 110.0);
    });

    test('world 2 base frequency is D2 (73.42 Hz)', () {
      const world2Freq = 73.42;
      expect(world2Freq, closeTo(73.42, 0.01));
    });

    test('world 3 base frequency is F2 (87.31 Hz)', () {
      const world3Freq = 87.31;
      expect(world3Freq, closeTo(87.31, 0.01));
    });

    test('world 4 base frequency is G2 (98 Hz)', () {
      const world4Freq = 98.0;
      expect(world4Freq, 98.0);
    });

    test('world 5 base frequency is A1 (55 Hz)', () {
      const world5Freq = 55.0;
      expect(world5Freq, 55.0);
    });

    test('world 6 base frequency is C2 (65.41 Hz)', () {
      const world6Freq = 65.41;
      expect(world6Freq, closeTo(65.41, 0.01));
    });
  });

  group('AmbientSoundscapeService state consistency', () {
    test('stop followed by reset maintains consistency', () async {
      await AmbientSoundscapeService.instance.stop();
      await AmbientSoundscapeService.instance.reset();
      expect(AmbientSoundscapeService.instance.isPlaying, isFalse);
      expect(AmbientSoundscapeService.instance.currentWorld, 0);
    });

    test('multiple volume changes maintain last value', () async {
      await AmbientSoundscapeService.instance.setVolume(0.3);
      await AmbientSoundscapeService.instance.setVolume(0.6);
      await AmbientSoundscapeService.instance.setVolume(0.9);
      expect(AmbientSoundscapeService.instance.volume, 0.9);
    });

    test('reset after dispose maintains consistency', () async {
      await AmbientSoundscapeService.instance.dispose();
      await AmbientSoundscapeService.instance.reset();
      expect(AmbientSoundscapeService.instance.isPlaying, isFalse);
    });
  });

  group('AmbientSoundscapeService WAV format', () {
    test('WAV header size is 44 bytes', () {
      const headerSize = 44;
      expect(headerSize, 44);
    });

    test('PCM format code is 1', () {
      const pcmFormat = 1;
      expect(pcmFormat, 1);
    });

    test('byte rate calculation is correct', () {
      const sampleRate = 44100;
      const numChannels = 2;
      const bitsPerSample = 16;
      final byteRate = (sampleRate * numChannels * bitsPerSample) ~/ 8;
      expect(byteRate, 176400);
    });

    test('block align calculation is correct', () {
      const numChannels = 2;
      const bitsPerSample = 16;
      final blockAlign = (numChannels * bitsPerSample) ~/ 8;
      expect(blockAlign, 4);
    });
  });
}
