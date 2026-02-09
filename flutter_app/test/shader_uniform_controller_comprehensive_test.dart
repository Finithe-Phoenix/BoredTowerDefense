import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

/// Tests for ShaderUniformController logic and calculations
/// Tests pure mathematical functions without requiring game context

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED CLASSES FROM shader_uniform_controller.dart
// ═══════════════════════════════════════════════════════════════════════════════

/// Quality levels that affect entity limits
enum QualityLevel { low, medium, high, extreme }

/// Constants from ShaderUniformController
class ShaderConstants {
  static const int maxEntities = 10;
  static const int textureWidth = maxEntities;
  static const int textureHeight = 2;
  static const double updateInterval = 1 / 12;
  static const int pixelBufferSize = textureWidth * textureHeight * 4;
}

/// Simulates quality-based entity limit calculation
class EntityLimitCalculator {
  static int calculateLimit(QualityLevel quality) {
    return switch (quality) {
      QualityLevel.extreme => ShaderConstants.maxEntities,
      QualityLevel.high => ShaderConstants.maxEntities,
      QualityLevel.medium => 6,
      QualityLevel.low => 0,
    };
  }
}

/// Simulates position buffer operations
class PositionBuffer {
  final Float32List buffer;
  final int maxEntities;

  PositionBuffer({int? maxEntities})
      : maxEntities = maxEntities ?? ShaderConstants.maxEntities,
        buffer = Float32List((maxEntities ?? ShaderConstants.maxEntities) * 2);

  void setPosition(int index, double x, double y) {
    if (index >= maxEntities) return;
    buffer[index * 2] = x;
    buffer[index * 2 + 1] = y;
  }

  (double, double) getPosition(int index) {
    if (index >= maxEntities) return (0, 0);
    return (buffer[index * 2], buffer[index * 2 + 1]);
  }

  int get length => maxEntities;
}

/// Simulates tower position filling
class TowerPositionFiller {
  static int fillBuffer({
    required Float32List buffer,
    required List<(double, double, double, double)>
        towers, // (x, y, sizeX, sizeY)
    required int limit,
    required double scale,
    required double offsetX,
    required double offsetY,
    required double worldScale,
  }) {
    if (limit == 0) return 0;
    final count = towers.length < limit ? towers.length : limit;

    for (var i = 0; i < count; i++) {
      final (posX, posY, sizeX, sizeY) = towers[i];
      final worldX = posX + sizeX * 0.5;
      final worldY = posY + sizeY * 0.5;
      buffer[i * 2] = offsetX + worldX * worldScale;
      buffer[i * 2 + 1] = offsetY + worldY * worldScale;
    }
    return count;
  }
}

/// Simulates enemy position filling
class EnemyPositionFiller {
  static int fillBuffer({
    required Float32List buffer,
    required List<(double, double)> enemyPositions,
    required int limit,
    required double scale,
    required double offsetX,
    required double offsetY,
    required double worldScale,
  }) {
    if (limit == 0) return 0;
    final count = enemyPositions.length < limit ? enemyPositions.length : limit;

    for (var i = 0; i < count; i++) {
      final (posX, posY) = enemyPositions[i];
      buffer[i * 2] = offsetX + posX * worldScale;
      buffer[i * 2 + 1] = offsetY + posY * worldScale;
    }
    return count;
  }
}

/// Simulates pixel buffer row writing
class PixelRowWriter {
  static void writeRow({
    required Uint8List pixelBuffer,
    required int row,
    required Float32List positions,
    required int count,
    required double scaledWidth,
    required double scaledHeight,
    required int textureWidth,
  }) {
    for (var i = 0; i < textureWidth; i++) {
      final base = (row * textureWidth + i) * 4;
      if (i >= count) {
        pixelBuffer[base + 3] = 0; // Alpha = 0 for unused slots
        continue;
      }

      final x = positions[i * 2];
      final y = positions[i * 2 + 1];
      final nx = (x / scaledWidth).clamp(0.0, 1.0);
      final ny = (y / scaledHeight).clamp(0.0, 1.0);

      pixelBuffer[base] = (nx * 255).round();
      pixelBuffer[base + 1] = (ny * 255).round();
      pixelBuffer[base + 2] = 0;
      pixelBuffer[base + 3] = 255; // Alpha = 255 for active entities
    }
  }
}

/// Simulates update timer logic
class UpdateTimer {
  double _timer = 0;
  final double interval;

  UpdateTimer({double? interval})
      : interval = interval ?? ShaderConstants.updateInterval;

  bool update(double dt) {
    _timer += dt;
    if (_timer < interval) return false;
    _timer = 0;
    return true;
  }

  double get currentTime => _timer;

  void reset() => _timer = 0;
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('ShaderUniformController Constants', () {
    test('maxEntities is 10', () {
      expect(ShaderConstants.maxEntities, 10);
    });

    test('texture dimensions are correct', () {
      expect(ShaderConstants.textureWidth, 10);
      expect(ShaderConstants.textureHeight, 2);
    });

    test('update interval is 1/12 second (~83ms)', () {
      expect(ShaderConstants.updateInterval, closeTo(0.0833, 0.001));
    });

    test('pixel buffer size is textureWidth * textureHeight * 4', () {
      expect(ShaderConstants.pixelBufferSize, 80); // 10 * 2 * 4
    });
  });

  group('QualityLevel', () {
    test('has 4 quality levels', () {
      expect(QualityLevel.values.length, 4);
    });

    test('quality level enum values', () {
      expect(QualityLevel.values, contains(QualityLevel.medium));
      expect(QualityLevel.values, contains(QualityLevel.low));
      expect(QualityLevel.values, contains(QualityLevel.high));
      expect(QualityLevel.values, contains(QualityLevel.extreme));
    });
  });

  group('EntityLimitCalculator', () {
    test('high quality allows 10 entities', () {
      expect(EntityLimitCalculator.calculateLimit(QualityLevel.high), 10);
    });

    test('extreme quality allows 10 entities', () {
      expect(EntityLimitCalculator.calculateLimit(QualityLevel.extreme), 10);
    });

    test('medium quality allows 6 entities', () {
      expect(EntityLimitCalculator.calculateLimit(QualityLevel.medium), 6);
    });

    test('low quality allows 0 entities (disabled)', () {
      expect(EntityLimitCalculator.calculateLimit(QualityLevel.low), 0);
    });

    test('entity limit is always <= maxEntities', () {
      for (final quality in QualityLevel.values) {
        final limit = EntityLimitCalculator.calculateLimit(quality);
        expect(limit, lessThanOrEqualTo(ShaderConstants.maxEntities));
      }
    });
  });

  group('PositionBuffer', () {
    test('creates buffer with correct size', () {
      final buffer = PositionBuffer();
      expect(buffer.buffer.length, 20); // 10 * 2
    });

    test('creates custom size buffer', () {
      final buffer = PositionBuffer(maxEntities: 5);
      expect(buffer.buffer.length, 10); // 5 * 2
    });

    test('sets and gets positions correctly', () {
      final buffer = PositionBuffer();
      buffer.setPosition(0, 100.0, 200.0);
      buffer.setPosition(1, 300.0, 400.0);

      final (x0, y0) = buffer.getPosition(0);
      final (x1, y1) = buffer.getPosition(1);

      expect(x0, 100.0);
      expect(y0, 200.0);
      expect(x1, 300.0);
      expect(y1, 400.0);
    });

    test('ignores out of bounds index on set', () {
      final buffer = PositionBuffer(maxEntities: 5);
      buffer.setPosition(10, 100.0, 200.0); // Out of bounds

      // Buffer should be unchanged at that location
      final (x, y) = buffer.getPosition(0);
      expect(x, 0.0);
      expect(y, 0.0);
    });

    test('returns (0,0) for out of bounds index on get', () {
      final buffer = PositionBuffer(maxEntities: 5);
      final (x, y) = buffer.getPosition(10);
      expect(x, 0.0);
      expect(y, 0.0);
    });

    test('buffer length matches maxEntities', () {
      final buffer = PositionBuffer(maxEntities: 7);
      expect(buffer.length, 7);
    });
  });

  group('TowerPositionFiller', () {
    test('fills buffer with tower positions', () {
      final buffer = Float32List(20);
      final towers = [
        (100.0, 200.0, 50.0, 50.0), // Tower at (100,200) size 50x50
        (300.0, 400.0, 60.0, 60.0), // Tower at (300,400) size 60x60
      ];

      final count = TowerPositionFiller.fillBuffer(
        buffer: buffer,
        towers: towers,
        limit: 10,
        scale: 1.0,
        offsetX: 0.0,
        offsetY: 0.0,
        worldScale: 1.0,
      );

      expect(count, 2);
      // Tower center = position + size * 0.5
      // Tower 0: (100 + 25, 200 + 25) = (125, 225)
      expect(buffer[0], 125.0);
      expect(buffer[1], 225.0);
      // Tower 1: (300 + 30, 400 + 30) = (330, 430)
      expect(buffer[2], 330.0);
      expect(buffer[3], 430.0);
    });

    test('respects entity limit', () {
      final buffer = Float32List(20);
      final towers = List.generate(15, (i) => (i * 10.0, i * 20.0, 10.0, 10.0));

      final count = TowerPositionFiller.fillBuffer(
        buffer: buffer,
        towers: towers,
        limit: 5,
        scale: 1.0,
        offsetX: 0.0,
        offsetY: 0.0,
        worldScale: 1.0,
      );

      expect(count, 5);
    });

    test('applies offset and scale', () {
      final buffer = Float32List(20);
      final towers = [(100.0, 100.0, 0.0, 0.0)];

      TowerPositionFiller.fillBuffer(
        buffer: buffer,
        towers: towers,
        limit: 10,
        scale: 1.0,
        offsetX: 50.0,
        offsetY: 25.0,
        worldScale: 2.0,
      );

      // Position = offsetX + worldX * worldScale
      // = 50 + 100 * 2 = 250
      expect(buffer[0], 250.0);
      expect(buffer[1], 225.0); // 25 + 100 * 2
    });

    test('returns 0 when limit is 0', () {
      final buffer = Float32List(20);
      final towers = [(100.0, 200.0, 50.0, 50.0)];

      final count = TowerPositionFiller.fillBuffer(
        buffer: buffer,
        towers: towers,
        limit: 0,
        scale: 1.0,
        offsetX: 0.0,
        offsetY: 0.0,
        worldScale: 1.0,
      );

      expect(count, 0);
    });

    test('handles empty tower list', () {
      final buffer = Float32List(20);
      final towers = <(double, double, double, double)>[];

      final count = TowerPositionFiller.fillBuffer(
        buffer: buffer,
        towers: towers,
        limit: 10,
        scale: 1.0,
        offsetX: 0.0,
        offsetY: 0.0,
        worldScale: 1.0,
      );

      expect(count, 0);
    });
  });

  group('EnemyPositionFiller', () {
    test('fills buffer with enemy positions', () {
      final buffer = Float32List(20);
      final enemies = [
        (100.0, 200.0),
        (300.0, 400.0),
        (500.0, 600.0),
      ];

      final count = EnemyPositionFiller.fillBuffer(
        buffer: buffer,
        enemyPositions: enemies,
        limit: 10,
        scale: 1.0,
        offsetX: 0.0,
        offsetY: 0.0,
        worldScale: 1.0,
      );

      expect(count, 3);
      expect(buffer[0], 100.0);
      expect(buffer[1], 200.0);
      expect(buffer[2], 300.0);
      expect(buffer[3], 400.0);
      expect(buffer[4], 500.0);
      expect(buffer[5], 600.0);
    });

    test('respects entity limit', () {
      final buffer = Float32List(20);
      final enemies = List.generate(15, (i) => (i * 10.0, i * 20.0));

      final count = EnemyPositionFiller.fillBuffer(
        buffer: buffer,
        enemyPositions: enemies,
        limit: 6,
        scale: 1.0,
        offsetX: 0.0,
        offsetY: 0.0,
        worldScale: 1.0,
      );

      expect(count, 6);
    });

    test('applies offset and scale', () {
      final buffer = Float32List(20);
      final enemies = [(100.0, 200.0)];

      EnemyPositionFiller.fillBuffer(
        buffer: buffer,
        enemyPositions: enemies,
        limit: 10,
        scale: 1.0,
        offsetX: 10.0,
        offsetY: 20.0,
        worldScale: 0.5,
      );

      // Position = offsetX + posX * worldScale = 10 + 100 * 0.5 = 60
      expect(buffer[0], 60.0);
      expect(buffer[1], 120.0); // 20 + 200 * 0.5
    });

    test('returns 0 when limit is 0', () {
      final buffer = Float32List(20);
      final enemies = [(100.0, 200.0)];

      final count = EnemyPositionFiller.fillBuffer(
        buffer: buffer,
        enemyPositions: enemies,
        limit: 0,
        scale: 1.0,
        offsetX: 0.0,
        offsetY: 0.0,
        worldScale: 1.0,
      );

      expect(count, 0);
    });
  });

  group('PixelRowWriter', () {
    test('writes positions as normalized coordinates', () {
      final pixelBuffer = Uint8List(80);
      final positions = Float32List(20);
      positions[0] = 50.0; // x at 50% of 100
      positions[1] = 75.0; // y at 75% of 100

      PixelRowWriter.writeRow(
        pixelBuffer: pixelBuffer,
        row: 0,
        positions: positions,
        count: 1,
        scaledWidth: 100.0,
        scaledHeight: 100.0,
        textureWidth: 10,
      );

      // Normalized: x=0.5, y=0.75
      // Pixel values: 0.5*255=127-128, 0.75*255=191
      expect(pixelBuffer[0], closeTo(128, 1)); // R = nx * 255
      expect(pixelBuffer[1], closeTo(191, 1)); // G = ny * 255
      expect(pixelBuffer[2], 0); // B = 0
      expect(pixelBuffer[3], 255); // A = 255 (active)
    });

    test('sets alpha to 0 for unused slots', () {
      final pixelBuffer = Uint8List(80);
      final positions = Float32List(20);

      PixelRowWriter.writeRow(
        pixelBuffer: pixelBuffer,
        row: 0,
        positions: positions,
        count: 1, // Only 1 entity
        scaledWidth: 100.0,
        scaledHeight: 100.0,
        textureWidth: 10,
      );

      // Slot 0 is used, slot 1+ are unused
      expect(pixelBuffer[3], 255); // Slot 0 alpha = 255
      expect(pixelBuffer[7], 0); // Slot 1 alpha = 0
      expect(pixelBuffer[11], 0); // Slot 2 alpha = 0
    });

    test('clamps coordinates to [0, 1]', () {
      final pixelBuffer = Uint8List(80);
      final positions = Float32List(20);
      positions[0] = -50.0; // Negative
      positions[1] = 200.0; // Greater than scaledHeight

      PixelRowWriter.writeRow(
        pixelBuffer: pixelBuffer,
        row: 0,
        positions: positions,
        count: 1,
        scaledWidth: 100.0,
        scaledHeight: 100.0,
        textureWidth: 10,
      );

      expect(pixelBuffer[0], 0); // Clamped to 0
      expect(pixelBuffer[1], 255); // Clamped to 1
    });

    test('writes to correct row offset', () {
      final pixelBuffer = Uint8List(80);
      final positions = Float32List(20);
      positions[0] = 50.0;
      positions[1] = 50.0;

      PixelRowWriter.writeRow(
        pixelBuffer: pixelBuffer,
        row: 1, // Second row
        positions: positions,
        count: 1,
        scaledWidth: 100.0,
        scaledHeight: 100.0,
        textureWidth: 10,
      );

      // Row 1 starts at index 10 * 4 = 40
      expect(pixelBuffer[40], closeTo(128, 1)); // R
      expect(pixelBuffer[41], closeTo(128, 1)); // G
      expect(pixelBuffer[42], 0); // B
      expect(pixelBuffer[43], 255); // A
    });

    test('writes correct number of entities', () {
      final pixelBuffer = Uint8List(80);
      final positions = Float32List(20);

      // Set 3 positions
      for (int i = 0; i < 3; i++) {
        positions[i * 2] = (i + 1) * 25.0;
        positions[i * 2 + 1] = (i + 1) * 25.0;
      }

      PixelRowWriter.writeRow(
        pixelBuffer: pixelBuffer,
        row: 0,
        positions: positions,
        count: 3,
        scaledWidth: 100.0,
        scaledHeight: 100.0,
        textureWidth: 10,
      );

      // First 3 slots should be active
      expect(pixelBuffer[3], 255); // Slot 0 active
      expect(pixelBuffer[7], 255); // Slot 1 active
      expect(pixelBuffer[11], 255); // Slot 2 active
      expect(pixelBuffer[15], 0); // Slot 3 inactive
    });
  });

  group('UpdateTimer', () {
    test('does not trigger before interval', () {
      final timer = UpdateTimer();

      expect(timer.update(0.05), false); // 50ms < 83ms
      expect(timer.update(0.02), false); // 70ms < 83ms
    });

    test('triggers when interval exceeded', () {
      final timer = UpdateTimer();

      expect(timer.update(0.05), false);
      expect(timer.update(0.05), true); // 100ms > 83ms
    });

    test('resets after triggering', () {
      final timer = UpdateTimer();

      timer.update(0.1);
      expect(timer.currentTime, 0.0); // Reset after trigger
    });

    test('uses custom interval', () {
      final timer = UpdateTimer(interval: 0.5);

      expect(timer.update(0.3), false);
      expect(timer.update(0.3), true); // 600ms > 500ms
    });

    test('manual reset works', () {
      final timer = UpdateTimer();

      timer.update(0.05);
      expect(timer.currentTime, closeTo(0.05, 0.001));

      timer.reset();
      expect(timer.currentTime, 0.0);
    });

    test('accumulates time correctly', () {
      final timer = UpdateTimer();

      timer.update(0.01);
      expect(timer.currentTime, closeTo(0.01, 0.0001));

      timer.update(0.02);
      expect(timer.currentTime, closeTo(0.03, 0.0001));

      timer.update(0.03);
      expect(timer.currentTime, closeTo(0.06, 0.0001));
    });
  });

  group('Coordinate Normalization', () {
    test('center of screen maps to 0.5', () {
      const screenX = 500.0;
      const screenY = 400.0;
      const scaledWidth = 1000.0;
      const scaledHeight = 800.0;

      final nx = screenX / scaledWidth;
      final ny = screenY / scaledHeight;

      expect(nx, 0.5);
      expect(ny, 0.5);
    });

    test('top-left maps to (0, 0)', () {
      const screenX = 0.0;
      const screenY = 0.0;
      const scaledWidth = 1000.0;
      const scaledHeight = 800.0;

      final nx = screenX / scaledWidth;
      final ny = screenY / scaledHeight;

      expect(nx, 0.0);
      expect(ny, 0.0);
    });

    test('bottom-right maps to (1, 1)', () {
      const screenX = 1000.0;
      const screenY = 800.0;
      const scaledWidth = 1000.0;
      const scaledHeight = 800.0;

      final nx = screenX / scaledWidth;
      final ny = screenY / scaledHeight;

      expect(nx, 1.0);
      expect(ny, 1.0);
    });
  });

  group('Pixel Value Encoding', () {
    test('normalized 0.0 encodes to pixel 0', () {
      expect((0.0 * 255).round(), 0);
    });

    test('normalized 0.5 encodes to pixel 127-128', () {
      final pixel = (0.5 * 255).round();
      expect(pixel, closeTo(128, 1));
    });

    test('normalized 1.0 encodes to pixel 255', () {
      expect((1.0 * 255).round(), 255);
    });

    test('pixel encoding is uniform across range', () {
      for (double n = 0; n <= 1.0; n += 0.1) {
        final pixel = (n * 255).round();
        expect(pixel, greaterThanOrEqualTo(0));
        expect(pixel, lessThanOrEqualTo(255));
      }
    });
  });

  group('Buffer Memory Layout', () {
    test('position buffer uses interleaved XY layout', () {
      final buffer = Float32List(6);
      // Position 0: indices 0, 1
      // Position 1: indices 2, 3
      // Position 2: indices 4, 5

      buffer[0] = 10.0;
      buffer[1] = 20.0; // Position 0
      buffer[2] = 30.0;
      buffer[3] = 40.0; // Position 1
      buffer[4] = 50.0;
      buffer[5] = 60.0; // Position 2

      expect(buffer[0 * 2], 10.0); // Position 0 X
      expect(buffer[0 * 2 + 1], 20.0); // Position 0 Y
      expect(buffer[1 * 2], 30.0); // Position 1 X
      expect(buffer[1 * 2 + 1], 40.0); // Position 1 Y
    });

    test('pixel buffer uses RGBA layout', () {
      final buffer = Uint8List(8); // 2 pixels

      // Pixel 0
      buffer[0] = 255;
      buffer[1] = 128;
      buffer[2] = 64;
      buffer[3] = 200;

      // Pixel 1
      buffer[4] = 32;
      buffer[5] = 16;
      buffer[6] = 8;
      buffer[7] = 255;

      // Verify RGBA order
      expect(buffer[0], 255); // Pixel 0 R
      expect(buffer[1], 128); // Pixel 0 G
      expect(buffer[2], 64); // Pixel 0 B
      expect(buffer[3], 200); // Pixel 0 A
    });

    test('texture row stride is textureWidth * 4', () {
      const textureWidth = 10;
      const bytesPerPixel = 4;
      const rowStride = textureWidth * bytesPerPixel;

      expect(rowStride, 40);

      // Row 0 starts at 0
      // Row 1 starts at 40
      final row1Start = 1 * rowStride;
      expect(row1Start, 40);
    });
  });

  group('Scale Calculations', () {
    test('shader scale affects position transform', () {
      const worldX = 100.0;
      const worldY = 100.0;
      const offsetX = 50.0;
      const offsetY = 50.0;
      const worldScale = 0.5;

      final screenX = offsetX + worldX * worldScale;
      final screenY = offsetY + worldY * worldScale;

      expect(screenX, 100.0); // 50 + 100 * 0.5
      expect(screenY, 100.0);
    });

    test('different shader scales produce different positions', () {
      const worldX = 200.0;
      const offsetX = 0.0;

      final screenX1 = offsetX + worldX * 1.0;
      final screenX2 = offsetX + worldX * 0.5;
      final screenX3 = offsetX + worldX * 2.0;

      expect(screenX1, 200.0);
      expect(screenX2, 100.0);
      expect(screenX3, 400.0);
    });
  });

  group('Edge Cases', () {
    test('handles zero entities gracefully', () {
      final towerBuffer = Float32List(20);
      final enemyBuffer = Float32List(20);

      final towerCount = TowerPositionFiller.fillBuffer(
        buffer: towerBuffer,
        towers: [],
        limit: 10,
        scale: 1.0,
        offsetX: 0.0,
        offsetY: 0.0,
        worldScale: 1.0,
      );

      final enemyCount = EnemyPositionFiller.fillBuffer(
        buffer: enemyBuffer,
        enemyPositions: [],
        limit: 10,
        scale: 1.0,
        offsetX: 0.0,
        offsetY: 0.0,
        worldScale: 1.0,
      );

      expect(towerCount, 0);
      expect(enemyCount, 0);
    });

    test('handles more entities than limit', () {
      final buffer = Float32List(20);
      final towers = List.generate(20, (i) => (i * 10.0, i * 10.0, 5.0, 5.0));

      final count = TowerPositionFiller.fillBuffer(
        buffer: buffer,
        towers: towers,
        limit: 10,
        scale: 1.0,
        offsetX: 0.0,
        offsetY: 0.0,
        worldScale: 1.0,
      );

      expect(count, 10);
    });

    test('handles very large coordinates', () {
      final pixelBuffer = Uint8List(80);
      final positions = Float32List(20);
      positions[0] = 10000.0;
      positions[1] = 10000.0;

      PixelRowWriter.writeRow(
        pixelBuffer: pixelBuffer,
        row: 0,
        positions: positions,
        count: 1,
        scaledWidth: 1000.0,
        scaledHeight: 1000.0,
        textureWidth: 10,
      );

      // Clamped to 1.0
      expect(pixelBuffer[0], 255);
      expect(pixelBuffer[1], 255);
    });

    test('handles negative coordinates', () {
      final pixelBuffer = Uint8List(80);
      final positions = Float32List(20);
      positions[0] = -100.0;
      positions[1] = -100.0;

      PixelRowWriter.writeRow(
        pixelBuffer: pixelBuffer,
        row: 0,
        positions: positions,
        count: 1,
        scaledWidth: 1000.0,
        scaledHeight: 1000.0,
        textureWidth: 10,
      );

      // Clamped to 0.0
      expect(pixelBuffer[0], 0);
      expect(pixelBuffer[1], 0);
    });
  });

  group('Tower Center Calculation', () {
    test('tower center is position plus half size', () {
      const posX = 100.0;
      const posY = 200.0;
      const sizeX = 50.0;
      const sizeY = 60.0;

      final centerX = posX + sizeX * 0.5;
      final centerY = posY + sizeY * 0.5;

      expect(centerX, 125.0);
      expect(centerY, 230.0);
    });

    test('zero-sized tower has center at position', () {
      const posX = 100.0;
      const posY = 200.0;
      const sizeX = 0.0;
      const sizeY = 0.0;

      final centerX = posX + sizeX * 0.5;
      final centerY = posY + sizeY * 0.5;

      expect(centerX, 100.0);
      expect(centerY, 200.0);
    });
  });

  group('Integration: Full Pipeline', () {
    test('complete tower to pixel pipeline', () {
      // Simulate full pipeline: tower -> position buffer -> pixel buffer

      // 1. Setup tower
      final towers = [
        (100.0, 100.0, 50.0, 50.0)
      ]; // Tower at (100,100) size 50x50

      // 2. Fill position buffer
      final positionBuffer = Float32List(20);
      TowerPositionFiller.fillBuffer(
        buffer: positionBuffer,
        towers: towers,
        limit: 10,
        scale: 1.0,
        offsetX: 0.0,
        offsetY: 0.0,
        worldScale: 1.0,
      );

      // Tower center = (125, 125)
      expect(positionBuffer[0], 125.0);
      expect(positionBuffer[1], 125.0);

      // 3. Write to pixel buffer
      final pixelBuffer = Uint8List(80);
      PixelRowWriter.writeRow(
        pixelBuffer: pixelBuffer,
        row: 0,
        positions: positionBuffer,
        count: 1,
        scaledWidth: 1000.0,
        scaledHeight: 1000.0,
        textureWidth: 10,
      );

      // Normalized: 125/1000 = 0.125 -> pixel = 32
      expect(pixelBuffer[0], closeTo(32, 1));
      expect(pixelBuffer[1], closeTo(32, 1));
      expect(pixelBuffer[3], 255); // Active
    });

    test('complete enemy to pixel pipeline', () {
      // 1. Setup enemies
      final enemies = [(500.0, 400.0)];

      // 2. Fill position buffer
      final positionBuffer = Float32List(20);
      EnemyPositionFiller.fillBuffer(
        buffer: positionBuffer,
        enemyPositions: enemies,
        limit: 10,
        scale: 1.0,
        offsetX: 0.0,
        offsetY: 0.0,
        worldScale: 1.0,
      );

      expect(positionBuffer[0], 500.0);
      expect(positionBuffer[1], 400.0);

      // 3. Write to pixel buffer (row 1 for enemies)
      final pixelBuffer = Uint8List(80);
      PixelRowWriter.writeRow(
        pixelBuffer: pixelBuffer,
        row: 1,
        positions: positionBuffer,
        count: 1,
        scaledWidth: 1000.0,
        scaledHeight: 800.0,
        textureWidth: 10,
      );

      // Normalized: x=500/1000=0.5 -> 128, y=400/800=0.5 -> 128
      // Row 1 starts at byte 40
      expect(pixelBuffer[40], closeTo(128, 1));
      expect(pixelBuffer[41], closeTo(128, 1));
      expect(pixelBuffer[43], 255); // Active
    });
  });
}
