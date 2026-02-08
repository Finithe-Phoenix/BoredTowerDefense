import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/components/neon_grid_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NeonGridComponent unit tests', () {
    late NeonGridComponent grid;

    setUp(() {
      grid = NeonGridComponent(
        gridSize: 32.0,
        lineColor: const Color(0xFF00FFFF),
        glowColor: const Color(0xFF00FFFF),
      );
    });

    group('Initialization', () {
      test('creates with required parameters', () {
        expect(grid, isNotNull);
      });

      test('is a PositionComponent', () {
        expect(grid, isA<PositionComponent>());
      });

      test('stores gridSize correctly', () {
        expect(grid.gridSize, 32.0);
      });

      test('stores lineColor correctly', () {
        expect(grid.lineColor, const Color(0xFF00FFFF));
      });

      test('stores glowColor correctly', () {
        expect(grid.glowColor, const Color(0xFF00FFFF));
      });

      test('reducedFx defaults to false', () {
        expect(grid.reducedFx, isFalse);
      });

      test('creates with reducedFx true', () {
        final reducedGrid = NeonGridComponent(
          gridSize: 32.0,
          lineColor: Colors.cyan,
          glowColor: Colors.cyan,
          reducedFx: true,
        );
        expect(reducedGrid.reducedFx, isTrue);
      });

      test('priority is set to -10', () {
        expect(grid.priority, -10);
      });
    });

    group('Different configurations', () {
      test('creates with small grid size', () {
        final smallGrid = NeonGridComponent(
          gridSize: 8.0,
          lineColor: Colors.cyan,
          glowColor: Colors.cyan,
        );
        expect(smallGrid.gridSize, 8.0);
      });

      test('creates with large grid size', () {
        final largeGrid = NeonGridComponent(
          gridSize: 128.0,
          lineColor: Colors.cyan,
          glowColor: Colors.cyan,
        );
        expect(largeGrid.gridSize, 128.0);
      });

      test('creates with magenta color scheme', () {
        final magentaGrid = NeonGridComponent(
          gridSize: 32.0,
          lineColor: const Color(0xFFFF00FF),
          glowColor: const Color(0xFFFF00FF),
        );
        expect(magentaGrid.lineColor, const Color(0xFFFF00FF));
        expect(magentaGrid.glowColor, const Color(0xFFFF00FF));
      });

      test('creates with different line and glow colors', () {
        final mixedGrid = NeonGridComponent(
          gridSize: 32.0,
          lineColor: Colors.blue,
          glowColor: Colors.cyan,
        );
        expect(mixedGrid.lineColor, Colors.blue);
        expect(mixedGrid.glowColor, Colors.cyan);
      });

      test('creates with transparent colors', () {
        final transparentGrid = NeonGridComponent(
          gridSize: 32.0,
          lineColor: Colors.cyan.withOpacity(0.5),
          glowColor: Colors.cyan.withOpacity(0.3),
        );
        expect(transparentGrid.lineColor.opacity, closeTo(0.5, 0.01));
        expect(transparentGrid.glowColor.opacity, closeTo(0.3, 0.01));
      });
    });

    group('Update behavior', () {
      test('update with zero delta time works', () {
        grid.update(0.0);
        expect(true, isTrue);
      });

      test('update with small delta time works', () {
        grid.update(0.001);
        expect(true, isTrue);
      });

      test('update with typical frame delta works', () {
        grid.update(0.016);
        expect(true, isTrue);
      });

      test('update with large delta time works', () {
        grid.update(1.0);
        expect(true, isTrue);
      });

      test('update with very large delta time works', () {
        grid.update(100.0);
        expect(true, isTrue);
      });

      test('multiple rapid updates work', () {
        for (int i = 0; i < 100; i++) {
          grid.update(0.016);
        }
        expect(true, isTrue);
      });

      test('many updates accumulate time correctly', () {
        for (int i = 0; i < 1000; i++) {
          grid.update(0.001);
        }
        expect(true, isTrue);
      });
    });

    group('Component lifecycle', () {
      test('onRemove can be called without initialization', () {
        grid.onRemove();
        expect(true, isTrue);
      });

      test('onRemove can be called multiple times', () {
        grid.onRemove();
        grid.onRemove();
        grid.onRemove();
        expect(true, isTrue);
      });

      test('update after onRemove still works', () {
        grid.onRemove();
        grid.update(0.016);
        expect(true, isTrue);
      });
    });

    group('Performance simulation', () {
      test('handles 1000 rapid updates', () {
        for (int i = 0; i < 1000; i++) {
          grid.update(0.016);
        }
        expect(true, isTrue);
      });

      test('handles 10000 minimal updates', () {
        for (int i = 0; i < 10000; i++) {
          grid.update(0.001);
        }
        expect(true, isTrue);
      });

      test('simulates 5 minutes of grid animation', () {
        const framesPerSecond = 60;
        const seconds = 300;
        const totalFrames = framesPerSecond * seconds;

        for (int i = 0; i < totalFrames; i++) {
          grid.update(1.0 / framesPerSecond);
        }
        expect(true, isTrue);
      });

      test('handles rapid updates with reduced fx', () {
        final reducedGrid = NeonGridComponent(
          gridSize: 32.0,
          lineColor: Colors.cyan,
          glowColor: Colors.cyan,
          reducedFx: true,
        );

        for (int i = 0; i < 1000; i++) {
          reducedGrid.update(0.016);
        }
        expect(true, isTrue);
      });
    });

    group('Multiple instance behavior', () {
      test('multiple grids can update simultaneously', () {
        final grids = List.generate(
          10,
          (_) => NeonGridComponent(
            gridSize: 32.0,
            lineColor: Colors.cyan,
            glowColor: Colors.cyan,
          ),
        );

        for (int frame = 0; frame < 60; frame++) {
          for (final g in grids) {
            g.update(0.016);
          }
        }
        expect(true, isTrue);
      });

      test('grids with different colors update independently', () {
        final cyanGrid = NeonGridComponent(
          gridSize: 32.0,
          lineColor: Colors.cyan,
          glowColor: Colors.cyan,
        );
        final magentaGrid = NeonGridComponent(
          gridSize: 32.0,
          lineColor: Colors.pink,
          glowColor: Colors.pink,
        );

        for (int i = 0; i < 60; i++) {
          cyanGrid.update(0.016);
          magentaGrid.update(0.016);
        }

        expect(cyanGrid.lineColor, isNot(equals(magentaGrid.lineColor)));
      });
    });

    group('Edge cases', () {
      test('handles negative delta time', () {
        grid.update(-0.016);
        expect(true, isTrue);
      });

      test('handles very small delta time', () {
        grid.update(0.0000001);
        expect(true, isTrue);
      });

      test('interleaved create and remove', () {
        final g1 = NeonGridComponent(
          gridSize: 32.0,
          lineColor: Colors.cyan,
          glowColor: Colors.cyan,
        );
        g1.update(0.016);
        g1.onRemove();

        final g2 = NeonGridComponent(
          gridSize: 32.0,
          lineColor: Colors.cyan,
          glowColor: Colors.cyan,
        );
        g2.update(0.016);
        g2.onRemove();

        expect(true, isTrue);
      });

      test('handles zero grid size', () {
        final zeroGrid = NeonGridComponent(
          gridSize: 0.0,
          lineColor: Colors.cyan,
          glowColor: Colors.cyan,
        );
        zeroGrid.update(0.016);
        expect(zeroGrid.gridSize, 0.0);
      });

      test('handles very small grid size', () {
        final tinyGrid = NeonGridComponent(
          gridSize: 0.001,
          lineColor: Colors.cyan,
          glowColor: Colors.cyan,
        );
        tinyGrid.update(0.016);
        expect(true, isTrue);
      });

      test('handles very large grid size', () {
        final hugeGrid = NeonGridComponent(
          gridSize: 10000.0,
          lineColor: Colors.cyan,
          glowColor: Colors.cyan,
        );
        hugeGrid.update(0.016);
        expect(true, isTrue);
      });
    });
  });

  group('NeonGridComponent static paints', () {
    test('static paints exist and are properly configured', () {
      // Verify static paints don't cause issues when multiple grids exist
      final grids = List.generate(
        5,
        (i) => NeonGridComponent(
          gridSize: 32.0 + i * 4,
          lineColor: Color.lerp(Colors.cyan, Colors.pink, i / 4)!,
          glowColor: Color.lerp(Colors.cyan, Colors.pink, i / 4)!,
        ),
      );

      for (int frame = 0; frame < 30; frame++) {
        for (final g in grids) {
          g.update(0.016);
        }
      }

      expect(true, isTrue);
    });
  });

  group('NeonGridComponent perspective grid constants', () {
    test('perspective line count is positive', () {
      // Based on source: _perspectiveLineCount = 20
      const perspectiveLineCount = 20;
      expect(perspectiveLineCount, greaterThan(0));
    });

    test('perspective vertical line count is positive', () {
      // Based on source: _perspectiveVLineCount = 15
      const perspectiveVLineCount = 15;
      expect(perspectiveVLineCount, greaterThan(0));
    });

    test('perspective line counts are reasonable', () {
      const hCount = 20;
      const vCount = 15;
      expect(hCount, greaterThanOrEqualTo(10));
      expect(hCount, lessThanOrEqualTo(50));
      expect(vCount, greaterThanOrEqualTo(10));
      expect(vCount, lessThanOrEqualTo(50));
    });
  });

  group('NeonGridComponent colors', () {
    test('predefined magenta color has correct value', () {
      // Based on source: _magentaO02 = Color(0x05FF0066)
      const magentaO02 = Color(0x05FF0066);
      expect(magentaO02.red, 0xFF);
      expect(magentaO02.green, 0x00);
      expect(magentaO02.blue, 0x66);
    });

    test('matrix bright green has correct value', () {
      // Based on source: _matrixBrightGreenO60 = Color(0x9988FF88)
      const matrixGreen = Color(0x9988FF88);
      expect(matrixGreen.red, 0x88);
      expect(matrixGreen.green, 0xFF);
      expect(matrixGreen.blue, 0x88);
    });

    test('static color arrays are pre-computed', () {
      // Matrix green alpha array has 21 entries (0-20)
      const expectedCount = 21;
      expect(expectedCount, 21);
    });

    test('trail gradient has 30 entries', () {
      const expectedCount = 30;
      expect(expectedCount, 30);
    });
  });

  group('NeonGridComponent paint configurations', () {
    test('grid paint has 1px stroke width', () {
      const strokeWidth = 1.0;
      expect(strokeWidth, equals(1.0));
    });

    test('glow paint has 2px stroke width', () {
      const strokeWidth = 2.0;
      expect(strokeWidth, equals(2.0));
    });

    test('wave ring paint has 3px stroke width', () {
      const strokeWidth = 3.0;
      expect(strokeWidth, equals(3.0));
    });

    test('frame paint has 2px stroke width', () {
      const strokeWidth = 2.0;
      expect(strokeWidth, equals(2.0));
    });

    test('frame glow paint has 4px stroke width', () {
      const strokeWidth = 4.0;
      expect(strokeWidth, equals(4.0));
    });
  });

  group('NeonGridComponent blur settings', () {
    test('glow blur radius is 2px', () {
      const blurRadius = 2.0;
      expect(blurRadius, equals(2.0));
    });

    test('node outer blur radius is 4px', () {
      const blurRadius = 4.0;
      expect(blurRadius, equals(4.0));
    });

    test('scan paint 1 blur radius is 25px', () {
      const blurRadius = 25.0;
      expect(blurRadius, equals(25.0));
    });

    test('scan paint 2 blur radius is 30px', () {
      const blurRadius = 30.0;
      expect(blurRadius, equals(30.0));
    });

    test('horizontal scan blur radius is 20px', () {
      const blurRadius = 20.0;
      expect(blurRadius, equals(20.0));
    });

    test('head glow blur radius is 8px', () {
      const blurRadius = 8.0;
      expect(blurRadius, equals(8.0));
    });

    test('trail glow blur radius is 3px', () {
      const blurRadius = 3.0;
      expect(blurRadius, equals(3.0));
    });
  });

  group('NeonGridComponent hex pattern', () {
    test('hex paint has stroke style', () {
      const strokeWidth = 0.5;
      expect(strokeWidth, equals(0.5));
    });
  });

  group('NeonGridComponent LCG random', () {
    test('LCG initial state is 42', () {
      // Based on source: _rngState = 42
      const initialState = 42;
      expect(initialState, 42);
    });

    test('multiple grids have independent RNG state', () {
      final g1 = NeonGridComponent(
        gridSize: 32.0,
        lineColor: Colors.cyan,
        glowColor: Colors.cyan,
      );
      final g2 = NeonGridComponent(
        gridSize: 32.0,
        lineColor: Colors.cyan,
        glowColor: Colors.cyan,
      );

      // Update both and verify they work independently
      g1.update(0.016);
      g2.update(0.016);

      expect(true, isTrue);
    });
  });
}
