import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/services/ambient_soundscape_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String headerTag(Uint8List bytes, int offset) {
    return String.fromCharCodes(bytes.sublist(offset, offset + 4));
  }

  void expectValidWav(Uint8List bytes) {
    expect(bytes.length, greaterThan(44));
    expect(headerTag(bytes, 0), 'RIFF');
    expect(headerTag(bytes, 8), 'WAVE');
    expect(headerTag(bytes, 12), 'fmt ');
    expect(headerTag(bytes, 36), 'data');
  }

  group('AmbientSoundscapeService fast generation', () {
    final service = AmbientSoundscapeService.instance;

    test('generates valid WAV for every world and every layer', () {
      for (int worldId = 1; worldId <= 10; worldId++) {
        for (final layer in AmbientLayerType.values) {
          final wav = service.generateLayerForTesting(
            worldId: worldId,
            layer: layer,
            durationSeconds: 0.02,
          );
          expectValidWav(wav);
        }
      }
    });

    test('supports unknown world fallback for switch defaults', () {
      final unknownDrone = service.generateLayerForTesting(
        worldId: 999,
        layer: AmbientLayerType.drone,
        durationSeconds: 0.02,
      );
      final unknownTexture = service.generateLayerForTesting(
        worldId: 999,
        layer: AmbientLayerType.texture,
        durationSeconds: 0.02,
      );
      expectValidWav(unknownDrone);
      expectValidWav(unknownTexture);
    });

    test('clamps test generation duration to safe bounds', () {
      final tooShort = service.generateLayerForTesting(
        worldId: 1,
        layer: AmbientLayerType.atmosphere,
        durationSeconds: 0.0,
      );
      final tooLong = service.generateLayerForTesting(
        worldId: 1,
        layer: AmbientLayerType.accent,
        durationSeconds: 999.0,
      );
      expectValidWav(tooShort);
      expectValidWav(tooLong);
    });

    test('intensity setter clamps to valid range', () {
      service.setIntensity(-1.0);
      expect(service.intensity, 0.0);

      service.setIntensity(0.42);
      expect(service.intensity, 0.42);

      service.setIntensity(9.0);
      expect(service.intensity, 1.0);
    });

    test('playWorldAmbient accepts short debug durations', () async {
      await service.playWorldAmbient(7, debugDurationSeconds: 0.005);
      expect(service.currentWorld, 7);

      await service.playWorldAmbient(10, debugDurationSeconds: 0.005);
      expect(service.currentWorld, 10);
    });
  });
}
