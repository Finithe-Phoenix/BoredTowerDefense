import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/shaders/shader_presets.dart';

void main() {
  group('ShaderPreset', () {
    test('can be created with all required parameters', () {
      const preset = ShaderPreset(
        gridIterations: 2,
        glowIntensity: 0.7,
        scanlineFrequency: 0.5,
        particleIntensity: 0.6,
        chromaIntensity: 0.4,
      );

      expect(preset.gridIterations, 2);
      expect(preset.glowIntensity, 0.7);
      expect(preset.scanlineFrequency, 0.5);
      expect(preset.particleIntensity, 0.6);
      expect(preset.chromaIntensity, 0.4);
    });

    test('gridIterations is an integer', () {
      const preset = ShaderPreset(
        gridIterations: 3,
        glowIntensity: 0.5,
        scanlineFrequency: 0.5,
        particleIntensity: 0.5,
        chromaIntensity: 0.5,
      );

      expect(preset.gridIterations, isA<int>());
    });

    test('intensity values are doubles', () {
      const preset = ShaderPreset(
        gridIterations: 1,
        glowIntensity: 0.123,
        scanlineFrequency: 0.456,
        particleIntensity: 0.789,
        chromaIntensity: 0.012,
      );

      expect(preset.glowIntensity, isA<double>());
      expect(preset.scanlineFrequency, isA<double>());
      expect(preset.particleIntensity, isA<double>());
      expect(preset.chromaIntensity, isA<double>());
    });

    test('can have zero intensity values', () {
      const preset = ShaderPreset(
        gridIterations: 0,
        glowIntensity: 0.0,
        scanlineFrequency: 0.0,
        particleIntensity: 0.0,
        chromaIntensity: 0.0,
      );

      expect(preset.gridIterations, 0);
      expect(preset.glowIntensity, 0.0);
      expect(preset.scanlineFrequency, 0.0);
      expect(preset.particleIntensity, 0.0);
      expect(preset.chromaIntensity, 0.0);
    });

    test('can have maximum intensity values', () {
      const preset = ShaderPreset(
        gridIterations: 10,
        glowIntensity: 1.0,
        scanlineFrequency: 1.0,
        particleIntensity: 1.0,
        chromaIntensity: 1.0,
      );

      expect(preset.gridIterations, 10);
      expect(preset.glowIntensity, 1.0);
      expect(preset.scanlineFrequency, 1.0);
      expect(preset.particleIntensity, 1.0);
      expect(preset.chromaIntensity, 1.0);
    });
  });

  group('ShaderPresetConfig', () {
    test('can be created with presets map', () {
      final presets = <String, ShaderPreset>{
        'Low': const ShaderPreset(
          gridIterations: 1,
          glowIntensity: 0.3,
          scanlineFrequency: 0.3,
          particleIntensity: 0.3,
          chromaIntensity: 0.3,
        ),
        'High': const ShaderPreset(
          gridIterations: 4,
          glowIntensity: 0.9,
          scanlineFrequency: 0.9,
          particleIntensity: 0.9,
          chromaIntensity: 0.9,
        ),
      };

      final config = ShaderPresetConfig(presets: presets);

      expect(config.presets.length, 2);
      expect(config.presets.containsKey('Low'), isTrue);
      expect(config.presets.containsKey('High'), isTrue);
    });

    test('preset method returns preset by name', () {
      final presets = <String, ShaderPreset>{
        'Medium': const ShaderPreset(
          gridIterations: 2,
          glowIntensity: 0.5,
          scanlineFrequency: 0.5,
          particleIntensity: 0.5,
          chromaIntensity: 0.5,
        ),
      };

      final config = ShaderPresetConfig(presets: presets);
      final preset = config.preset('Medium');

      expect(preset.gridIterations, 2);
      expect(preset.glowIntensity, 0.5);
    });

    test('preset method returns first preset for unknown name', () {
      final presets = <String, ShaderPreset>{
        'Default': const ShaderPreset(
          gridIterations: 1,
          glowIntensity: 0.5,
          scanlineFrequency: 0.5,
          particleIntensity: 0.5,
          chromaIntensity: 0.5,
        ),
      };

      final config = ShaderPresetConfig(presets: presets);
      final preset = config.preset('NonExistent');

      // Should return the first preset when name not found
      expect(preset, isNotNull);
      expect(preset.gridIterations, 1);
    });

    test('can have empty presets map', () {
      final config = ShaderPresetConfig(presets: {});

      expect(config.presets, isEmpty);
    });

    test('can have multiple presets', () {
      final presets = <String, ShaderPreset>{
        'Ultra Low': const ShaderPreset(
          gridIterations: 0,
          glowIntensity: 0.1,
          scanlineFrequency: 0.1,
          particleIntensity: 0.1,
          chromaIntensity: 0.1,
        ),
        'Low': const ShaderPreset(
          gridIterations: 1,
          glowIntensity: 0.3,
          scanlineFrequency: 0.3,
          particleIntensity: 0.3,
          chromaIntensity: 0.3,
        ),
        'Medium': const ShaderPreset(
          gridIterations: 2,
          glowIntensity: 0.5,
          scanlineFrequency: 0.5,
          particleIntensity: 0.5,
          chromaIntensity: 0.5,
        ),
        'High': const ShaderPreset(
          gridIterations: 3,
          glowIntensity: 0.7,
          scanlineFrequency: 0.7,
          particleIntensity: 0.7,
          chromaIntensity: 0.7,
        ),
        'Ultra': const ShaderPreset(
          gridIterations: 4,
          glowIntensity: 1.0,
          scanlineFrequency: 1.0,
          particleIntensity: 1.0,
          chromaIntensity: 1.0,
        ),
      };

      final config = ShaderPresetConfig(presets: presets);

      expect(config.presets.length, 5);
      expect(config.preset('Ultra Low').gridIterations, 0);
      expect(config.preset('Ultra').gridIterations, 4);
    });
  });
}
