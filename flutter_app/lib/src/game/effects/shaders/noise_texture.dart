import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Generates a procedural noise image that shaders can sample via shaders without
/// shipping a static PNG.
class NoiseTexture {
  /// Creates a grayscale noise image with the requested [size].
  static Future<ui.Image> generate({
    int size = 512,
    int seed = 0,
  }) {
    int rngState = seed & 0x7fffffff;
    int next() {
      rngState = (1664525 * rngState + 1013904223) & 0x7fffffff;
      return rngState;
    }

    int nextInt(int max) => max <= 0 ? 0 : next() % max;
    final pixels = Uint8List(size * size * 4);
    for (var i = 0; i < size * size; i++) {
      final noiseValue = nextInt(256);
      final offset = i * 4;
      pixels[offset] = noiseValue;
      pixels[offset + 1] = noiseValue;
      pixels[offset + 2] = noiseValue;
      pixels[offset + 3] = 0xFF;
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      size,
      size,
      ui.PixelFormat.rgba8888,
      (img) => completer.complete(img),
    );
    return completer.future;
  }
}

