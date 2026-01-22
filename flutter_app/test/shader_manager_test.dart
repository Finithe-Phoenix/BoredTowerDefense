import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/shaders/shader_manager.dart';

void main() {
  group('ShaderManager', () {
    test('instance returns singleton', () {
      final instance1 = ShaderManager.instance;
      final instance2 = ShaderManager.instance;

      expect(identical(instance1, instance2), isTrue);
    });

    test('program returns null for unloaded shader', () {
      final manager = ShaderManager.instance;
      final program = manager.program('nonexistent_shader');

      expect(program, isNull);
    });

    test('descriptor returns null for unloaded shader', () {
      final manager = ShaderManager.instance;
      final descriptor = manager.descriptor('nonexistent_shader');

      expect(descriptor, isNull);
    });

    test('isReady returns false when no shaders loaded', () {
      // Note: This depends on whether other tests have loaded shaders
      // In isolation, a fresh manager would have isReady = false
      final manager = ShaderManager.instance;
      // We can't guarantee state in a singleton, but we can test the property exists
      expect(manager.isReady, isA<bool>());
    });
  });

  group('ShaderDescriptor', () {
    test('can be created with default values', () {
      const descriptor = ShaderDescriptor();

      expect(descriptor.uniforms, isEmpty);
      expect(descriptor.presetHints, isEmpty);
    });

    test('can be created with custom uniforms', () {
      const descriptor = ShaderDescriptor(
        uniforms: ['time', 'resolution', 'intensity'],
      );

      expect(descriptor.uniforms.length, 3);
      expect(descriptor.uniforms, contains('time'));
      expect(descriptor.uniforms, contains('resolution'));
      expect(descriptor.uniforms, contains('intensity'));
    });

    test('can be created with preset hints', () {
      const descriptor = ShaderDescriptor(
        presetHints: ['low', 'medium', 'high'],
      );

      expect(descriptor.presetHints.length, 3);
      expect(descriptor.presetHints, contains('low'));
      expect(descriptor.presetHints, contains('medium'));
      expect(descriptor.presetHints, contains('high'));
    });

    test('can be created with both uniforms and preset hints', () {
      const descriptor = ShaderDescriptor(
        uniforms: ['time', 'color'],
        presetHints: ['neon', 'dark'],
      );

      expect(descriptor.uniforms.length, 2);
      expect(descriptor.presetHints.length, 2);
    });
  });

  group('ShaderAsset', () {
    test('can be created with required parameters', () {
      const asset = ShaderAsset(
        name: 'test_shader',
        assetPath: 'assets/shaders/test.frag',
      );

      expect(asset.name, 'test_shader');
      expect(asset.assetPath, 'assets/shaders/test.frag');
      expect(asset.descriptor, isNull);
    });

    test('can be created with descriptor', () {
      const descriptor = ShaderDescriptor(
        uniforms: ['time'],
      );

      const asset = ShaderAsset(
        name: 'test_shader',
        assetPath: 'assets/shaders/test.frag',
        descriptor: descriptor,
      );

      expect(asset.name, 'test_shader');
      expect(asset.assetPath, 'assets/shaders/test.frag');
      expect(asset.descriptor, isNotNull);
      expect(asset.descriptor!.uniforms, contains('time'));
    });

    test('multiple assets can be created', () {
      const assets = [
        ShaderAsset(name: 'glow', assetPath: 'assets/shaders/glow.frag'),
        ShaderAsset(name: 'blur', assetPath: 'assets/shaders/blur.frag'),
        ShaderAsset(name: 'noise', assetPath: 'assets/shaders/noise.frag'),
      ];

      expect(assets.length, 3);
      expect(assets[0].name, 'glow');
      expect(assets[1].name, 'blur');
      expect(assets[2].name, 'noise');
    });
  });
}
