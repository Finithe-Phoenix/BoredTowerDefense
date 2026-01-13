import 'dart:async';

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'noise_texture.dart';

/// Singleton that compiles Flutter fragment shaders once and keeps them available
/// for every effect that needs GPU-driven glow, grid, HUD, or particle passes.
class ShaderManager {
  ShaderManager._();

  static final ShaderManager instance = ShaderManager._();

  final Map<String, ui.FragmentProgram> _cache = {};
  final Map<String, ShaderDescriptor> _descriptors = {};
  final Set<String> _failed = {};

  /// Loads a named shader from assets and caches its compiled [FragmentProgram].
  Future<void> loadShader({
    required String name,
    required String assetPath,
    ShaderDescriptor? descriptor,
  }) async {
    if (_cache.containsKey(name) || _failed.contains(name)) return;

    try {
      final program = await ui.FragmentProgram.fromAsset(assetPath);
      _cache[name] = program;
      if (descriptor != null) {
        _descriptors[name] = descriptor;
      }
    } catch (error) {
      _failed.add(name);
      if (kDebugMode) {
        debugPrint('[ShaderManager] Disabled shader "$name": $error');
      }
    }
  }

  Future<void> loadShaderFromAsset({
    required String name,
    required String assetPath,
    ShaderDescriptor? descriptor,
  }) async {
    await loadShader(name: name, assetPath: assetPath, descriptor: descriptor);
  }

  /// Bulk loading convenience.
  Future<void> preload(List<ShaderAsset> assets) {
    return Future.wait(
      assets.map((asset) => loadShader(
            name: asset.name,
            assetPath: asset.assetPath,
            descriptor: asset.descriptor,
          )),
    );
  }

  ui.FragmentProgram? program(String name) => _cache[name];

  ShaderDescriptor? descriptor(String name) => _descriptors[name];

  bool get isReady => _cache.isNotEmpty;

  Future<ui.Image> noiseTexture({
    int size = 512,
    int seed = 0,
  }) {
    _noiseCache ??= NoiseTexture.generate(size: size, seed: seed);
    return _noiseCache!;
  }

  Future<ui.Image>? _noiseCache;
}

/// Stores metadata about a shader (uniform layout, suggested uniforms, presets).
class ShaderDescriptor {
  const ShaderDescriptor({
    this.uniforms = const [],
    this.presetHints = const [],
  });

  final List<String> uniforms;
  final List<String> presetHints;
}

/// Helper describing how to load a shader asset.
class ShaderAsset {
  const ShaderAsset({
    required this.name,
    required this.assetPath,
    this.descriptor,
  });

  final String name;
  final String assetPath;
  final ShaderDescriptor? descriptor;
}
