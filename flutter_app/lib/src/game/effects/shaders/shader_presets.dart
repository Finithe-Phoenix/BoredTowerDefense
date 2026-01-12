import 'dart:convert';

import 'package:flutter/services.dart';

class ShaderPresetConfig {
  ShaderPresetConfig({required this.presets});

  final Map<String, ShaderPreset> presets;

  static Future<ShaderPresetConfig> load(String assetPath) async {
    final data = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(data) as Map<String, dynamic>;
    final rawPresets = decoded['presets'] as Map<String, dynamic>? ?? {};
    final presets = <String, ShaderPreset>{};

    rawPresets.forEach((name, values) {
      final map = values as Map<String, dynamic>;
      presets[name] = ShaderPreset(
        gridIterations: (map['gridIterations'] ?? 1) as int,
        glowIntensity: _asDouble(map['glowIntensity'], 0.5),
        scanlineFrequency: _asDouble(map['scanlineFrequency'], 0.5),
        particleIntensity: _asDouble(map['particleIntensity'], 0.5),
        chromaIntensity: _asDouble(map['chromaIntensity'], 0.5),
      );
    });

    if (presets.isEmpty) {
      presets['Balanced'] = ShaderPreset(
        gridIterations: 2,
        glowIntensity: 0.7,
        scanlineFrequency: 0.7,
        particleIntensity: 0.7,
        chromaIntensity: 0.6,
      );
    }

    return ShaderPresetConfig(presets: presets);
  }

  ShaderPreset preset(String name) {
    return presets[name] ?? presets.values.first;
  }
}

class ShaderPreset {
  const ShaderPreset({
    required this.gridIterations,
    required this.glowIntensity,
    required this.scanlineFrequency,
    required this.particleIntensity,
    required this.chromaIntensity,
  });

  final int gridIterations;
  final double glowIntensity;
  final double scanlineFrequency;
  final double particleIntensity;
  final double chromaIntensity;
}

double _asDouble(dynamic value, double fallback) {
  if (value is num) return value.toDouble();
  return fallback;
}
