import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/shaders/shader_presets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void mockAssets(Map<String, String> assets) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      if (message == null) {
        return null;
      }

      final key = utf8.decode(message.buffer.asUint8List());
      final assetValue = assets[key];
      if (assetValue == null) {
        return null;
      }

      final bytes = Uint8List.fromList(utf8.encode(assetValue));
      return ByteData.view(bytes.buffer);
    });
  }

  void clearMockAssets() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  }

  tearDown(clearMockAssets);

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

  group('ShaderPresetConfig.load', () {
    test('loads preset map from asset and applies numeric fallbacks', () async {
      const assetPath = 'assets/test/shader_presets_case_1.json';
      mockAssets({
        assetPath: jsonEncode({
          'presets': {
            'Balanced': {
              'gridIterations': 3,
              'glowIntensity': 0.65,
              'scanlineFrequency': 'invalid',
              'particleIntensity': 1,
              'chromaIntensity': 0.4,
            },
            'Extreme': {
              // gridIterations intentionally omitted to use default 1
              'glowIntensity': null,
              'scanlineFrequency': 0.2,
              'particleIntensity': 'bad',
              'chromaIntensity': 0.8,
            },
          },
        }),
      });

      final config = await ShaderPresetConfig.load(assetPath);

      expect(config.presets.length, 2);

      final balanced = config.preset('Balanced');
      expect(balanced.gridIterations, 3);
      expect(balanced.glowIntensity, 0.65);
      expect(balanced.scanlineFrequency, 0.5);
      expect(balanced.particleIntensity, 1.0);
      expect(balanced.chromaIntensity, 0.4);

      final extreme = config.preset('Extreme');
      expect(extreme.gridIterations, 1);
      expect(extreme.glowIntensity, 0.5);
      expect(extreme.scanlineFrequency, 0.2);
      expect(extreme.particleIntensity, 0.5);
      expect(extreme.chromaIntensity, 0.8);
    });

    test('falls back to built-in Balanced preset when presets are empty',
        () async {
      const assetPath = 'assets/test/shader_presets_case_2.json';
      mockAssets({
        assetPath: jsonEncode({'presets': {}}),
      });

      final config = await ShaderPresetConfig.load(assetPath);
      final balanced = config.preset('Balanced');

      expect(config.presets.keys, contains('Balanced'));
      expect(config.presets.length, 1);
      expect(balanced.gridIterations, 2);
      expect(balanced.glowIntensity, 0.7);
      expect(balanced.scanlineFrequency, 0.7);
      expect(balanced.particleIntensity, 0.7);
      expect(balanced.chromaIntensity, 0.6);
    });

    test('falls back to built-in Balanced preset when key is missing',
        () async {
      const assetPath = 'assets/test/shader_presets_case_3.json';
      mockAssets({
        assetPath: jsonEncode({'version': 1}),
      });

      final config = await ShaderPresetConfig.load(assetPath);

      expect(config.presets.keys, contains('Balanced'));
      expect(config.presets.length, 1);
    });
  });
}
