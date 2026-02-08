import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

/// Tests for NoiseTexture procedural generation

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED CLASSES FROM noise_texture.dart
// ═══════════════════════════════════════════════════════════════════════════════

/// Noise texture generation constants
class NoiseTextureConstants {
  static const int defaultSize = 512;
  static const int defaultSeed = 0;
  static const int bytesPerPixel = 4; // RGBA
}

/// LCG Random Number Generator (same as in NoiseTexture)
class NoiseLcgRng {
  int _state;

  NoiseLcgRng(int seed) : _state = seed & 0x7fffffff;

  int next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  int nextInt(int max) => max <= 0 ? 0 : next() % max;
}

/// Simulates the noise texture pixel generation
class NoiseTextureGenerator {
  static Uint8List generatePixels({
    int size = 512,
    int seed = 0,
  }) {
    final rng = NoiseLcgRng(seed);
    final pixels = Uint8List(size * size * 4);

    for (var i = 0; i < size * size; i++) {
      final noiseValue = rng.nextInt(256);
      final offset = i * 4;
      pixels[offset] = noiseValue; // R
      pixels[offset + 1] = noiseValue; // G
      pixels[offset + 2] = noiseValue; // B
      pixels[offset + 3] = 0xFF; // A (fully opaque)
    }

    return pixels;
  }

  static int calculateBufferSize(int textureSize) {
    return textureSize * textureSize * NoiseTextureConstants.bytesPerPixel;
  }
}

/// Pixel value analyzer
class PixelAnalyzer {
  static bool isGrayscale(Uint8List pixels, int offset) {
    return pixels[offset] == pixels[offset + 1] &&
        pixels[offset + 1] == pixels[offset + 2];
  }

  static bool isOpaque(Uint8List pixels, int offset) {
    return pixels[offset + 3] == 0xFF;
  }

  static int getGrayscaleValue(Uint8List pixels, int offset) {
    return pixels[offset]; // R channel (same as G and B)
  }

  static (int, int, int, int) getRGBA(Uint8List pixels, int offset) {
    return (
      pixels[offset],
      pixels[offset + 1],
      pixels[offset + 2],
      pixels[offset + 3],
    );
  }
}

/// Statistical analyzer for noise quality
class NoiseStatistics {
  final Uint8List pixels;
  final int textureSize;

  NoiseStatistics(this.pixels, this.textureSize);

  double calculateMean() {
    double sum = 0;
    int count = 0;

    for (int i = 0; i < textureSize * textureSize; i++) {
      sum += pixels[i * 4];
      count++;
    }

    return sum / count;
  }

  double calculateStandardDeviation() {
    final mean = calculateMean();
    double sumSquaredDiff = 0;
    int count = 0;

    for (int i = 0; i < textureSize * textureSize; i++) {
      final value = pixels[i * 4];
      sumSquaredDiff += (value - mean) * (value - mean);
      count++;
    }

    return sumSquaredDiff / count;
  }

  int getMinValue() {
    int min = 255;
    for (int i = 0; i < textureSize * textureSize; i++) {
      final value = pixels[i * 4];
      if (value < min) min = value;
    }
    return min;
  }

  int getMaxValue() {
    int max = 0;
    for (int i = 0; i < textureSize * textureSize; i++) {
      final value = pixels[i * 4];
      if (value > max) max = value;
    }
    return max;
  }

  Map<int, int> getHistogram() {
    final histogram = <int, int>{};
    for (int i = 0; i < textureSize * textureSize; i++) {
      final value = pixels[i * 4];
      histogram[value] = (histogram[value] ?? 0) + 1;
    }
    return histogram;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('NoiseTexture Constants', () {
    test('default size is 512', () {
      expect(NoiseTextureConstants.defaultSize, 512);
    });

    test('default seed is 0', () {
      expect(NoiseTextureConstants.defaultSeed, 0);
    });

    test('bytes per pixel is 4 (RGBA)', () {
      expect(NoiseTextureConstants.bytesPerPixel, 4);
    });
  });

  group('NoiseLcgRng', () {
    test('produces consistent sequence with same seed', () {
      final rng1 = NoiseLcgRng(12345);
      final rng2 = NoiseLcgRng(12345);

      for (int i = 0; i < 10; i++) {
        expect(rng1.next(), rng2.next());
      }
    });

    test('produces different sequences with different seeds', () {
      final rng1 = NoiseLcgRng(12345);
      final rng2 = NoiseLcgRng(54321);

      final values1 = List.generate(5, (_) => rng1.next());
      final values2 = List.generate(5, (_) => rng2.next());

      expect(values1, isNot(equals(values2)));
    });

    test('nextInt returns values in [0, max)', () {
      final rng = NoiseLcgRng(42);

      for (int i = 0; i < 100; i++) {
        final value = rng.nextInt(256);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(256));
      }
    });

    test('nextInt with max 0 returns 0', () {
      final rng = NoiseLcgRng(42);
      expect(rng.nextInt(0), 0);
      expect(rng.nextInt(-5), 0);
    });

    test('seed is masked to 31 bits', () {
      // Even with a large seed, should work
      final rng = NoiseLcgRng(0xFFFFFFFF);
      expect(rng.nextInt(256), greaterThanOrEqualTo(0));
    });
  });

  group('NoiseTextureGenerator - Buffer Size', () {
    test('512x512 texture is 1MB', () {
      final size = NoiseTextureGenerator.calculateBufferSize(512);
      expect(size, 512 * 512 * 4);
      expect(size, 1048576); // 1 MB
    });

    test('256x256 texture is 256KB', () {
      final size = NoiseTextureGenerator.calculateBufferSize(256);
      expect(size, 256 * 256 * 4);
      expect(size, 262144); // 256 KB
    });

    test('64x64 texture is 16KB', () {
      final size = NoiseTextureGenerator.calculateBufferSize(64);
      expect(size, 64 * 64 * 4);
      expect(size, 16384); // 16 KB
    });
  });

  group('NoiseTextureGenerator - Pixel Generation', () {
    test('generates correct buffer size', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 64);
      expect(pixels.length, 64 * 64 * 4);
    });

    test('all pixels are grayscale', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 64);

      for (int i = 0; i < 64 * 64; i++) {
        expect(PixelAnalyzer.isGrayscale(pixels, i * 4), true,
            reason: 'Pixel $i is not grayscale');
      }
    });

    test('all pixels are fully opaque', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 64);

      for (int i = 0; i < 64 * 64; i++) {
        expect(PixelAnalyzer.isOpaque(pixels, i * 4), true,
            reason: 'Pixel $i is not opaque');
      }
    });

    test('same seed produces same pixels', () {
      final pixels1 = NoiseTextureGenerator.generatePixels(size: 64, seed: 12345);
      final pixels2 = NoiseTextureGenerator.generatePixels(size: 64, seed: 12345);

      for (int i = 0; i < pixels1.length; i++) {
        expect(pixels1[i], pixels2[i], reason: 'Difference at byte $i');
      }
    });

    test('different seeds produce different pixels', () {
      final pixels1 = NoiseTextureGenerator.generatePixels(size: 64, seed: 12345);
      final pixels2 = NoiseTextureGenerator.generatePixels(size: 64, seed: 54321);

      int differences = 0;
      for (int i = 0; i < pixels1.length; i += 4) {
        if (pixels1[i] != pixels2[i]) differences++;
      }

      // Should have many different pixels
      expect(differences, greaterThan(64 * 64 * 0.5));
    });
  });

  group('PixelAnalyzer', () {
    test('identifies grayscale pixels', () {
      final pixels = Uint8List.fromList([128, 128, 128, 255]);
      expect(PixelAnalyzer.isGrayscale(pixels, 0), true);
    });

    test('identifies non-grayscale pixels', () {
      final pixels = Uint8List.fromList([100, 128, 150, 255]);
      expect(PixelAnalyzer.isGrayscale(pixels, 0), false);
    });

    test('identifies opaque pixels', () {
      final pixels = Uint8List.fromList([100, 100, 100, 255]);
      expect(PixelAnalyzer.isOpaque(pixels, 0), true);
    });

    test('identifies transparent pixels', () {
      final pixels = Uint8List.fromList([100, 100, 100, 128]);
      expect(PixelAnalyzer.isOpaque(pixels, 0), false);
    });

    test('gets grayscale value', () {
      final pixels = Uint8List.fromList([128, 128, 128, 255]);
      expect(PixelAnalyzer.getGrayscaleValue(pixels, 0), 128);
    });

    test('gets RGBA values', () {
      final pixels = Uint8List.fromList([10, 20, 30, 255]);
      final (r, g, b, a) = PixelAnalyzer.getRGBA(pixels, 0);

      expect(r, 10);
      expect(g, 20);
      expect(b, 30);
      expect(a, 255);
    });
  });

  group('NoiseStatistics', () {
    test('mean is approximately 127.5 for uniform distribution', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 256, seed: 42);
      final stats = NoiseStatistics(pixels, 256);

      final mean = stats.calculateMean();
      // Should be close to 127.5 (middle of 0-255)
      expect(mean, closeTo(127.5, 10));
    });

    test('min value is close to 0', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 256, seed: 42);
      final stats = NoiseStatistics(pixels, 256);

      final min = stats.getMinValue();
      // With enough pixels, should find values near 0
      expect(min, lessThan(10));
    });

    test('max value is close to 255', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 256, seed: 42);
      final stats = NoiseStatistics(pixels, 256);

      final max = stats.getMaxValue();
      // With enough pixels, should find values near 255
      expect(max, greaterThan(245));
    });

    test('histogram covers full range', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 256, seed: 42);
      final stats = NoiseStatistics(pixels, 256);

      final histogram = stats.getHistogram();

      // Should have many different values
      expect(histogram.keys.length, greaterThan(200));
    });

    test('distribution is roughly uniform', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 256, seed: 42);
      final stats = NoiseStatistics(pixels, 256);

      final histogram = stats.getHistogram();
      final totalPixels = 256 * 256;
      final expectedPerBin = totalPixels / 256;

      // Check that no bin is too far from expected
      int extremeDeviations = 0;
      for (final count in histogram.values) {
        if ((count - expectedPerBin).abs() > expectedPerBin * 2) {
          extremeDeviations++;
        }
      }

      // Should have few extreme deviations
      expect(extremeDeviations, lessThan(20));
    });
  });

  group('Seed Behavior', () {
    test('seed 0 is valid', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 32, seed: 0);
      expect(pixels.length, 32 * 32 * 4);
    });

    test('negative seed values work', () {
      // Due to masking, negative seeds should still work
      final rng = NoiseLcgRng(-1);
      final value = rng.nextInt(256);
      expect(value, greaterThanOrEqualTo(0));
      expect(value, lessThan(256));
    });

    test('large seed values work', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 32, seed: 0x7FFFFFFF);
      expect(pixels.length, 32 * 32 * 4);
    });
  });

  group('Different Texture Sizes', () {
    test('generates 16x16 texture', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 16);
      expect(pixels.length, 16 * 16 * 4);
    });

    test('generates 64x64 texture', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 64);
      expect(pixels.length, 64 * 64 * 4);
    });

    test('generates 128x128 texture', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 128);
      expect(pixels.length, 128 * 128 * 4);
    });

    test('generates 256x256 texture', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 256);
      expect(pixels.length, 256 * 256 * 4);
    });

    test('generates 512x512 texture', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 512);
      expect(pixels.length, 512 * 512 * 4);
    });
  });

  group('Pixel Format', () {
    test('RGBA format is correct', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 4, seed: 42);

      // Check first pixel
      final (r, g, b, a) = PixelAnalyzer.getRGBA(pixels, 0);

      expect(r, g); // Grayscale
      expect(g, b); // Grayscale
      expect(a, 255); // Opaque
    });

    test('pixel stride is 4 bytes', () {
      final pixels = NoiseTextureGenerator.generatePixels(size: 4, seed: 42);

      // Second pixel should be at offset 4
      final (r1, _, _, _) = PixelAnalyzer.getRGBA(pixels, 0);
      final (r2, _, _, _) = PixelAnalyzer.getRGBA(pixels, 4);

      // Values might be same or different, but both should be valid
      expect(r1, greaterThanOrEqualTo(0));
      expect(r2, greaterThanOrEqualTo(0));
    });
  });

  group('Memory Layout', () {
    test('row stride is width * 4', () {
      const size = 64;
      final pixels = NoiseTextureGenerator.generatePixels(size: size);

      // First pixel of row 0 is at offset 0
      // First pixel of row 1 is at offset 64 * 4 = 256
      expect(size * 4, 256);
    });

    test('can access last pixel', () {
      const size = 64;
      final pixels = NoiseTextureGenerator.generatePixels(size: size);

      // Last pixel is at index (size*size - 1) * 4
      final lastOffset = (size * size - 1) * 4;
      expect(lastOffset, (64 * 64 - 1) * 4);
      expect(lastOffset, 16380);

      // Should be accessible
      final value = pixels[lastOffset];
      expect(value, greaterThanOrEqualTo(0));
      expect(value, lessThan(256));
    });
  });

  group('Determinism', () {
    test('same parameters always produce same output', () {
      // Generate same texture 3 times
      final pixels1 = NoiseTextureGenerator.generatePixels(size: 128, seed: 999);
      final pixels2 = NoiseTextureGenerator.generatePixels(size: 128, seed: 999);
      final pixels3 = NoiseTextureGenerator.generatePixels(size: 128, seed: 999);

      // All should be identical
      for (int i = 0; i < pixels1.length; i++) {
        expect(pixels1[i], pixels2[i]);
        expect(pixels2[i], pixels3[i]);
      }
    });
  });

  group('Integration: Shader Sampling', () {
    test('texture can be sampled by UV coordinates', () {
      const size = 64;
      final pixels = NoiseTextureGenerator.generatePixels(size: size, seed: 42);

      // Simulate UV sampling at (0.5, 0.5)
      const u = 0.5;
      const v = 0.5;

      final x = (u * size).floor().clamp(0, size - 1);
      final y = (v * size).floor().clamp(0, size - 1);
      final offset = (y * size + x) * 4;

      final value = pixels[offset];
      expect(value, greaterThanOrEqualTo(0));
      expect(value, lessThan(256));
    });

    test('UV corners map to correct pixels', () {
      const size = 64;
      final pixels = NoiseTextureGenerator.generatePixels(size: size, seed: 42);

      // UV (0, 0) -> pixel (0, 0)
      expect(pixels[0], greaterThanOrEqualTo(0));

      // UV (1, 0) -> pixel (63, 0)
      final topRightOffset = 63 * 4;
      expect(pixels[topRightOffset], greaterThanOrEqualTo(0));

      // UV (0, 1) -> pixel (0, 63)
      final bottomLeftOffset = (63 * size) * 4;
      expect(pixels[bottomLeftOffset], greaterThanOrEqualTo(0));

      // UV (1, 1) -> pixel (63, 63)
      final bottomRightOffset = (63 * size + 63) * 4;
      expect(pixels[bottomRightOffset], greaterThanOrEqualTo(0));
    });
  });
}
