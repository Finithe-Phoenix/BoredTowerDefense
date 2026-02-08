import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

/// Tests for WorldUberShaderComponent logic and calculations
/// Tests pure mathematical functions without requiring game context

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED CLASSES FROM world_uber_shader_component.dart
// ═══════════════════════════════════════════════════════════════════════════════

/// Constants from WorldUberShaderComponent
class UberShaderConstants {
  static const int priority = -20;
  static const int fallbackColorValue = 0xFF02030F;
  static const int uniformCount = 8;
}

/// Uniform indices used in the shader
class UniformIndices {
  static const int width = 0;
  static const int height = 1;
  static const int time = 2;
  static const int pointerX = 3;
  static const int pointerY = 4;
  static const int waveIntensity = 5;
  static const int towerCount = 6;
  static const int enemyCount = 7;
}

/// Simulates render metrics calculation
class RenderMetricsCalculator {
  double _lastScale = -1;
  double _lastWidth = -1;
  double _lastHeight = -1;
  double renderWidth = 0;
  double renderHeight = 0;

  bool needsUpdate(double scale, double width, double height) {
    return scale != _lastScale || width != _lastWidth || height != _lastHeight;
  }

  void update(double scale, double width, double height) {
    if (!needsUpdate(scale, width, height)) return;

    _lastScale = scale;
    _lastWidth = width;
    _lastHeight = height;
    renderWidth = width * scale;
    renderHeight = height * scale;
  }

  (double, double, double, double) getRenderRect() {
    return (0, 0, renderWidth, renderHeight);
  }
}

/// Simulates uniform buffer writing
class UniformBuffer {
  final Float32List uniforms = Float32List(UberShaderConstants.uniformCount);

  void writeUniforms({
    required double renderWidth,
    required double renderHeight,
    required double time,
    required double pointerX,
    required double pointerY,
    required double waveIntensity,
    required int towerCount,
    required int enemyCount,
  }) {
    uniforms[UniformIndices.width] = renderWidth;
    uniforms[UniformIndices.height] = renderHeight;
    uniforms[UniformIndices.time] = time;
    uniforms[UniformIndices.pointerX] = pointerX;
    uniforms[UniformIndices.pointerY] = pointerY;
    uniforms[UniformIndices.waveIntensity] = waveIntensity;
    uniforms[UniformIndices.towerCount] = towerCount.toDouble();
    uniforms[UniformIndices.enemyCount] = enemyCount.toDouble();
  }

  double get width => uniforms[UniformIndices.width];
  double get height => uniforms[UniformIndices.height];
  double get time => uniforms[UniformIndices.time];
  double get pointerX => uniforms[UniformIndices.pointerX];
  double get pointerY => uniforms[UniformIndices.pointerY];
  double get waveIntensity => uniforms[UniformIndices.waveIntensity];
  double get towerCount => uniforms[UniformIndices.towerCount];
  double get enemyCount => uniforms[UniformIndices.enemyCount];
}

/// Simulates pointer scaling
class PointerScaler {
  static (double, double) scalePointer(double? x, double? y, double scale) {
    final scaledX = (x ?? 0) * scale;
    final scaledY = (y ?? 0) * scale;
    return (scaledX, scaledY);
  }
}

/// Simulates scale transformation
class CanvasScaler {
  static double calculateInverseScale(double scale) {
    return 1 / scale;
  }

  static bool needsScaling(double scale) {
    return scale != 1.0;
  }
}

/// Simulates time accumulation
class TimeAccumulator {
  double _time = 0;

  void update(double dt) {
    _time += dt;
  }

  double get time => _time;

  void reset() {
    _time = 0;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('UberShader Constants', () {
    test('priority is -20', () {
      expect(UberShaderConstants.priority, -20);
    });

    test('fallback color is dark blue', () {
      expect(UberShaderConstants.fallbackColorValue, 0xFF02030F);
    });

    test('uniform count is 8', () {
      expect(UberShaderConstants.uniformCount, 8);
    });
  });

  group('Uniform Indices', () {
    test('width is at index 0', () {
      expect(UniformIndices.width, 0);
    });

    test('height is at index 1', () {
      expect(UniformIndices.height, 1);
    });

    test('time is at index 2', () {
      expect(UniformIndices.time, 2);
    });

    test('pointerX is at index 3', () {
      expect(UniformIndices.pointerX, 3);
    });

    test('pointerY is at index 4', () {
      expect(UniformIndices.pointerY, 4);
    });

    test('waveIntensity is at index 5', () {
      expect(UniformIndices.waveIntensity, 5);
    });

    test('towerCount is at index 6', () {
      expect(UniformIndices.towerCount, 6);
    });

    test('enemyCount is at index 7', () {
      expect(UniformIndices.enemyCount, 7);
    });

    test('all indices are unique', () {
      final indices = [
        UniformIndices.width,
        UniformIndices.height,
        UniformIndices.time,
        UniformIndices.pointerX,
        UniformIndices.pointerY,
        UniformIndices.waveIntensity,
        UniformIndices.towerCount,
        UniformIndices.enemyCount,
      ];

      expect(indices.toSet().length, 8);
    });

    test('all indices are within uniform count', () {
      expect(UniformIndices.width, lessThan(UberShaderConstants.uniformCount));
      expect(UniformIndices.height, lessThan(UberShaderConstants.uniformCount));
      expect(UniformIndices.time, lessThan(UberShaderConstants.uniformCount));
      expect(UniformIndices.pointerX, lessThan(UberShaderConstants.uniformCount));
      expect(UniformIndices.pointerY, lessThan(UberShaderConstants.uniformCount));
      expect(UniformIndices.waveIntensity, lessThan(UberShaderConstants.uniformCount));
      expect(UniformIndices.towerCount, lessThan(UberShaderConstants.uniformCount));
      expect(UniformIndices.enemyCount, lessThan(UberShaderConstants.uniformCount));
    });
  });

  group('RenderMetricsCalculator', () {
    test('initially needs update', () {
      final calc = RenderMetricsCalculator();
      expect(calc.needsUpdate(1.0, 1920, 1080), true);
    });

    test('does not need update after same values', () {
      final calc = RenderMetricsCalculator();
      calc.update(1.0, 1920, 1080);
      expect(calc.needsUpdate(1.0, 1920, 1080), false);
    });

    test('needs update when scale changes', () {
      final calc = RenderMetricsCalculator();
      calc.update(1.0, 1920, 1080);
      expect(calc.needsUpdate(0.5, 1920, 1080), true);
    });

    test('needs update when width changes', () {
      final calc = RenderMetricsCalculator();
      calc.update(1.0, 1920, 1080);
      expect(calc.needsUpdate(1.0, 1280, 1080), true);
    });

    test('needs update when height changes', () {
      final calc = RenderMetricsCalculator();
      calc.update(1.0, 1920, 1080);
      expect(calc.needsUpdate(1.0, 1920, 720), true);
    });

    test('calculates render dimensions with scale 1.0', () {
      final calc = RenderMetricsCalculator();
      calc.update(1.0, 1920, 1080);

      expect(calc.renderWidth, 1920);
      expect(calc.renderHeight, 1080);
    });

    test('calculates render dimensions with scale 0.5', () {
      final calc = RenderMetricsCalculator();
      calc.update(0.5, 1920, 1080);

      expect(calc.renderWidth, 960);
      expect(calc.renderHeight, 540);
    });

    test('calculates render dimensions with scale 2.0', () {
      final calc = RenderMetricsCalculator();
      calc.update(2.0, 1920, 1080);

      expect(calc.renderWidth, 3840);
      expect(calc.renderHeight, 2160);
    });

    test('render rect starts at origin', () {
      final calc = RenderMetricsCalculator();
      calc.update(1.0, 1920, 1080);

      final (x, y, w, h) = calc.getRenderRect();
      expect(x, 0);
      expect(y, 0);
      expect(w, 1920);
      expect(h, 1080);
    });
  });

  group('UniformBuffer', () {
    test('creates buffer with correct size', () {
      final buffer = UniformBuffer();
      expect(buffer.uniforms.length, 8);
    });

    test('writes all uniforms correctly', () {
      final buffer = UniformBuffer();

      buffer.writeUniforms(
        renderWidth: 1920,
        renderHeight: 1080,
        time: 5.5,
        pointerX: 500,
        pointerY: 300,
        waveIntensity: 0.75,
        towerCount: 5,
        enemyCount: 10,
      );

      expect(buffer.width, 1920);
      expect(buffer.height, 1080);
      expect(buffer.time, 5.5);
      expect(buffer.pointerX, 500);
      expect(buffer.pointerY, 300);
      expect(buffer.waveIntensity, 0.75);
      expect(buffer.towerCount, 5);
      expect(buffer.enemyCount, 10);
    });

    test('converts int counts to double', () {
      final buffer = UniformBuffer();

      buffer.writeUniforms(
        renderWidth: 100,
        renderHeight: 100,
        time: 0,
        pointerX: 0,
        pointerY: 0,
        waveIntensity: 0,
        towerCount: 7,
        enemyCount: 15,
      );

      // Should be doubles, not ints
      expect(buffer.towerCount, isA<double>());
      expect(buffer.enemyCount, isA<double>());
      expect(buffer.towerCount, 7.0);
      expect(buffer.enemyCount, 15.0);
    });

    test('uniforms can be updated', () {
      final buffer = UniformBuffer();

      buffer.writeUniforms(
        renderWidth: 1920,
        renderHeight: 1080,
        time: 1.0,
        pointerX: 100,
        pointerY: 100,
        waveIntensity: 0.5,
        towerCount: 3,
        enemyCount: 5,
      );

      expect(buffer.time, 1.0);

      buffer.writeUniforms(
        renderWidth: 1920,
        renderHeight: 1080,
        time: 2.0,
        pointerX: 200,
        pointerY: 200,
        waveIntensity: 0.8,
        towerCount: 4,
        enemyCount: 8,
      );

      expect(buffer.time, 2.0);
      expect(buffer.pointerX, 200);
      expect(buffer.waveIntensity, closeTo(0.8, 0.0001));
    });
  });

  group('PointerScaler', () {
    test('scales pointer with scale 1.0', () {
      final (x, y) = PointerScaler.scalePointer(100, 200, 1.0);
      expect(x, 100);
      expect(y, 200);
    });

    test('scales pointer with scale 0.5', () {
      final (x, y) = PointerScaler.scalePointer(100, 200, 0.5);
      expect(x, 50);
      expect(y, 100);
    });

    test('scales pointer with scale 2.0', () {
      final (x, y) = PointerScaler.scalePointer(100, 200, 2.0);
      expect(x, 200);
      expect(y, 400);
    });

    test('handles null pointer X', () {
      final (x, y) = PointerScaler.scalePointer(null, 200, 1.0);
      expect(x, 0);
      expect(y, 200);
    });

    test('handles null pointer Y', () {
      final (x, y) = PointerScaler.scalePointer(100, null, 1.0);
      expect(x, 100);
      expect(y, 0);
    });

    test('handles both null', () {
      final (x, y) = PointerScaler.scalePointer(null, null, 2.0);
      expect(x, 0);
      expect(y, 0);
    });

    test('handles negative coordinates', () {
      final (x, y) = PointerScaler.scalePointer(-50, -100, 2.0);
      expect(x, -100);
      expect(y, -200);
    });
  });

  group('CanvasScaler', () {
    test('calculates inverse scale', () {
      expect(CanvasScaler.calculateInverseScale(1.0), 1.0);
      expect(CanvasScaler.calculateInverseScale(0.5), 2.0);
      expect(CanvasScaler.calculateInverseScale(2.0), 0.5);
    });

    test('needs scaling when scale != 1.0', () {
      expect(CanvasScaler.needsScaling(1.0), false);
      expect(CanvasScaler.needsScaling(0.5), true);
      expect(CanvasScaler.needsScaling(2.0), true);
      expect(CanvasScaler.needsScaling(0.99), true);
      expect(CanvasScaler.needsScaling(1.01), true);
    });

    test('inverse scale * scale = 1', () {
      for (double scale = 0.1; scale <= 3.0; scale += 0.1) {
        final inverse = CanvasScaler.calculateInverseScale(scale);
        expect(scale * inverse, closeTo(1.0, 0.0001));
      }
    });
  });

  group('TimeAccumulator', () {
    test('starts at zero', () {
      final acc = TimeAccumulator();
      expect(acc.time, 0);
    });

    test('accumulates time', () {
      final acc = TimeAccumulator();
      acc.update(0.016);
      expect(acc.time, closeTo(0.016, 0.0001));

      acc.update(0.016);
      expect(acc.time, closeTo(0.032, 0.0001));
    });

    test('handles large dt values', () {
      final acc = TimeAccumulator();
      acc.update(1.0);
      acc.update(2.0);
      acc.update(3.0);
      expect(acc.time, 6.0);
    });

    test('handles small dt values', () {
      final acc = TimeAccumulator();
      for (int i = 0; i < 1000; i++) {
        acc.update(0.001);
      }
      expect(acc.time, closeTo(1.0, 0.0001));
    });

    test('reset sets time to zero', () {
      final acc = TimeAccumulator();
      acc.update(5.0);
      expect(acc.time, 5.0);

      acc.reset();
      expect(acc.time, 0);
    });
  });

  group('Integration: Full Uniform Pipeline', () {
    test('complete uniform setup workflow', () {
      // 1. Calculate render metrics
      final metrics = RenderMetricsCalculator();
      metrics.update(0.5, 1920, 1080);

      expect(metrics.renderWidth, 960);
      expect(metrics.renderHeight, 540);

      // 2. Scale pointer
      const rawPointerX = 400.0;
      const rawPointerY = 300.0;
      final (pointerX, pointerY) =
          PointerScaler.scalePointer(rawPointerX, rawPointerY, 0.5);

      expect(pointerX, 200);
      expect(pointerY, 150);

      // 3. Accumulate time
      final time = TimeAccumulator();
      time.update(1.0);

      // 4. Write uniforms
      final buffer = UniformBuffer();
      buffer.writeUniforms(
        renderWidth: metrics.renderWidth,
        renderHeight: metrics.renderHeight,
        time: time.time,
        pointerX: pointerX,
        pointerY: pointerY,
        waveIntensity: 0.5,
        towerCount: 3,
        enemyCount: 7,
      );

      // Verify all uniforms
      expect(buffer.width, 960);
      expect(buffer.height, 540);
      expect(buffer.time, 1.0);
      expect(buffer.pointerX, 200);
      expect(buffer.pointerY, 150);
      expect(buffer.waveIntensity, 0.5);
      expect(buffer.towerCount, 3);
      expect(buffer.enemyCount, 7);
    });

    test('uniform updates during gameplay loop', () {
      final metrics = RenderMetricsCalculator();
      final time = TimeAccumulator();
      final buffer = UniformBuffer();

      // Frame 1
      metrics.update(1.0, 1920, 1080);
      time.update(0.016);
      buffer.writeUniforms(
        renderWidth: metrics.renderWidth,
        renderHeight: metrics.renderHeight,
        time: time.time,
        pointerX: 100,
        pointerY: 100,
        waveIntensity: 0.0,
        towerCount: 0,
        enemyCount: 0,
      );

      expect(buffer.time, closeTo(0.016, 0.0001));
      expect(buffer.enemyCount, 0);

      // Frame 2 - enemies spawn
      time.update(0.016);
      buffer.writeUniforms(
        renderWidth: metrics.renderWidth,
        renderHeight: metrics.renderHeight,
        time: time.time,
        pointerX: 150,
        pointerY: 150,
        waveIntensity: 0.2,
        towerCount: 1,
        enemyCount: 5,
      );

      expect(buffer.time, closeTo(0.032, 0.0001));
      expect(buffer.enemyCount, 5);
      expect(buffer.waveIntensity, closeTo(0.2, 0.0001));
    });
  });

  group('Edge Cases', () {
    test('handles zero scale', () {
      final metrics = RenderMetricsCalculator();
      metrics.update(0.0, 1920, 1080);

      expect(metrics.renderWidth, 0);
      expect(metrics.renderHeight, 0);
    });

    test('handles very small scale', () {
      final metrics = RenderMetricsCalculator();
      metrics.update(0.001, 1920, 1080);

      expect(metrics.renderWidth, closeTo(1.92, 0.01));
      expect(metrics.renderHeight, closeTo(1.08, 0.01));
    });

    test('handles very large scale', () {
      final metrics = RenderMetricsCalculator();
      metrics.update(10.0, 1920, 1080);

      expect(metrics.renderWidth, 19200);
      expect(metrics.renderHeight, 10800);
    });

    test('handles zero dimensions', () {
      final metrics = RenderMetricsCalculator();
      metrics.update(1.0, 0, 0);

      expect(metrics.renderWidth, 0);
      expect(metrics.renderHeight, 0);
    });

    test('handles negative dimensions gracefully', () {
      final metrics = RenderMetricsCalculator();
      metrics.update(1.0, -100, -100);

      // Negative dimensions would result in negative render size
      // (actual component would clamp this)
      expect(metrics.renderWidth, -100);
      expect(metrics.renderHeight, -100);
    });
  });

  group('Fallback Behavior', () {
    test('fallback color is valid ARGB', () {
      final color = UberShaderConstants.fallbackColorValue;

      final a = (color >> 24) & 0xFF;
      final r = (color >> 16) & 0xFF;
      final g = (color >> 8) & 0xFF;
      final b = color & 0xFF;

      expect(a, 0xFF); // Full alpha
      expect(r, 0x02); // Very dark red
      expect(g, 0x03); // Very dark green
      expect(b, 0x0F); // Dark blue
    });
  });

  group('Wave Intensity', () {
    test('wave intensity is passed to shader', () {
      final buffer = UniformBuffer();

      buffer.writeUniforms(
        renderWidth: 100,
        renderHeight: 100,
        time: 0,
        pointerX: 0,
        pointerY: 0,
        waveIntensity: 0.0,
        towerCount: 0,
        enemyCount: 0,
      );
      expect(buffer.waveIntensity, 0.0);

      buffer.writeUniforms(
        renderWidth: 100,
        renderHeight: 100,
        time: 0,
        pointerX: 0,
        pointerY: 0,
        waveIntensity: 0.5,
        towerCount: 0,
        enemyCount: 0,
      );
      expect(buffer.waveIntensity, 0.5);

      buffer.writeUniforms(
        renderWidth: 100,
        renderHeight: 100,
        time: 0,
        pointerX: 0,
        pointerY: 0,
        waveIntensity: 1.0,
        towerCount: 0,
        enemyCount: 0,
      );
      expect(buffer.waveIntensity, 1.0);
    });
  });

  group('Entity Counts', () {
    test('tower count is passed to shader', () {
      final buffer = UniformBuffer();

      for (int count = 0; count <= 20; count++) {
        buffer.writeUniforms(
          renderWidth: 100,
          renderHeight: 100,
          time: 0,
          pointerX: 0,
          pointerY: 0,
          waveIntensity: 0,
          towerCount: count,
          enemyCount: 0,
        );
        expect(buffer.towerCount, count.toDouble());
      }
    });

    test('enemy count is passed to shader', () {
      final buffer = UniformBuffer();

      for (int count = 0; count <= 50; count += 5) {
        buffer.writeUniforms(
          renderWidth: 100,
          renderHeight: 100,
          time: 0,
          pointerX: 0,
          pointerY: 0,
          waveIntensity: 0,
          towerCount: 0,
          enemyCount: count,
        );
        expect(buffer.enemyCount, count.toDouble());
      }
    });
  });

  group('Float32List Memory', () {
    test('uniform buffer is contiguous', () {
      final buffer = UniformBuffer();

      buffer.writeUniforms(
        renderWidth: 1.0,
        renderHeight: 2.0,
        time: 3.0,
        pointerX: 4.0,
        pointerY: 5.0,
        waveIntensity: 6.0,
        towerCount: 7,
        enemyCount: 8,
      );

      // Direct access to underlying array
      expect(buffer.uniforms[0], 1.0);
      expect(buffer.uniforms[1], 2.0);
      expect(buffer.uniforms[2], 3.0);
      expect(buffer.uniforms[3], 4.0);
      expect(buffer.uniforms[4], 5.0);
      expect(buffer.uniforms[5], 6.0);
      expect(buffer.uniforms[6], 7.0);
      expect(buffer.uniforms[7], 8.0);
    });

    test('float32list has correct byte length', () {
      final buffer = UniformBuffer();
      // Float32 = 4 bytes, 8 uniforms = 32 bytes
      expect(buffer.uniforms.lengthInBytes, 32);
    });
  });

  group('Caching Behavior', () {
    test('metrics caching prevents redundant updates', () {
      final metrics = RenderMetricsCalculator();

      // First update
      expect(metrics.needsUpdate(1.0, 1920, 1080), true);
      metrics.update(1.0, 1920, 1080);

      // Same values - no update needed
      for (int i = 0; i < 100; i++) {
        expect(metrics.needsUpdate(1.0, 1920, 1080), false);
      }
    });

    test('any change invalidates cache', () {
      final metrics = RenderMetricsCalculator();
      metrics.update(1.0, 1920, 1080);

      // Change scale
      expect(metrics.needsUpdate(1.1, 1920, 1080), true);
      metrics.update(1.1, 1920, 1080);

      // Change width
      expect(metrics.needsUpdate(1.1, 1919, 1080), true);
      metrics.update(1.1, 1919, 1080);

      // Change height
      expect(metrics.needsUpdate(1.1, 1919, 1079), true);
    });
  });
}
