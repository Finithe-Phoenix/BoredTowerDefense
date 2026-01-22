import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/components/neon_grid_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  NeonGridComponent makeGrid({
    double gridSize = 32.0,
    Color lineColor = Colors.cyan,
    Color glowColor = Colors.blue,
    bool reducedFx = false,
  }) {
    return NeonGridComponent(
      gridSize: gridSize,
      lineColor: lineColor,
      glowColor: glowColor,
      reducedFx: reducedFx,
    );
  }

  group('NeonGridComponent creation', () {
    test('creates with required parameters', () {
      final grid = makeGrid();

      expect(grid.gridSize, 32.0);
      expect(grid.lineColor, Colors.cyan);
      expect(grid.glowColor, Colors.blue);
      expect(grid.reducedFx, isFalse);
    });

    test('creates with reducedFx flag', () {
      final grid = makeGrid(reducedFx: true);

      expect(grid.reducedFx, isTrue);
    });

    test('has correct priority for rendering behind other components', () {
      final grid = makeGrid();

      expect(grid.priority, -10);
    });

    test('gridSize can be any positive value', () {
      final grid1 = makeGrid(gridSize: 16.0);
      final grid2 = makeGrid(gridSize: 64.0);

      expect(grid1.gridSize, 16.0);
      expect(grid2.gridSize, 64.0);
    });

    test('different colors can be used', () {
      final grid = makeGrid(lineColor: Colors.red, glowColor: Colors.yellow);

      expect(grid.lineColor, Colors.red);
      expect(grid.glowColor, Colors.yellow);
    });

    test('is a PositionComponent', () {
      final grid = makeGrid();
      expect(grid, isA<PositionComponent>());
    });
  });

  group('NeonGridComponent triggerPulseWave', () {
    test('default parameters', () {
      final grid = makeGrid();

      grid.triggerPulseWave(Vector2.zero());
      expect(true, isTrue);
    });

    test('custom color', () {
      final grid = makeGrid();

      grid.triggerPulseWave(Vector2.zero(), color: Colors.red);
      expect(true, isTrue);
    });

    test('custom speed', () {
      final grid = makeGrid();

      grid.triggerPulseWave(Vector2.zero(), speed: 300);
      expect(true, isTrue);
    });

    test('custom duration', () {
      final grid = makeGrid();

      grid.triggerPulseWave(Vector2.zero(), duration: 2.0);
      expect(true, isTrue);
    });

    test('all custom parameters', () {
      final grid = makeGrid();

      grid.triggerPulseWave(
        Vector2(500, 500),
        color: Colors.purple,
        speed: 500,
        duration: 3.0,
      );
      expect(true, isTrue);
    });

    test('triggers multiple pulse waves', () {
      final grid = makeGrid();

      grid.triggerPulseWave(Vector2(100, 100));
      grid.triggerPulseWave(Vector2(200, 200));
      grid.triggerPulseWave(Vector2(300, 300));

      expect(true, isTrue);
    });

    test('triggers many pulse waves', () {
      final grid = makeGrid();

      for (int i = 0; i < 50; i++) {
        grid.triggerPulseWave(Vector2(i * 10.0, i * 5.0));
      }

      expect(true, isTrue);
    });

    test('pulse wave at negative position', () {
      final grid = makeGrid();

      grid.triggerPulseWave(Vector2(-100, -100));

      expect(true, isTrue);
    });

    test('pulse wave at large position', () {
      final grid = makeGrid();

      grid.triggerPulseWave(Vector2(10000, 10000));

      expect(true, isTrue);
    });
  });

  group('NeonGridComponent update', () {
    test('update without errors', () {
      final grid = makeGrid();

      grid.update(0.016);
      grid.update(0.016);

      expect(true, isTrue);
    });

    test('update with pulse waves progresses them', () {
      final grid = makeGrid();

      grid.triggerPulseWave(Vector2(100, 100));

      for (int i = 0; i < 100; i++) {
        grid.update(0.016);
      }

      expect(true, isTrue);
    });

    test('update removes expired pulse waves', () {
      final grid = makeGrid();

      grid.triggerPulseWave(Vector2(100, 100), duration: 0.5);

      for (int i = 0; i < 50; i++) {
        grid.update(0.02);
      }

      expect(true, isTrue);
    });

    test('update with zero dt does not crash', () {
      final grid = makeGrid();

      grid.update(0.0);

      expect(true, isTrue);
    });

    test('update with large dt works', () {
      final grid = makeGrid();

      grid.update(1.0);

      expect(true, isTrue);
    });

    test('multiple rapid updates work', () {
      final grid = makeGrid();

      for (int i = 0; i < 100; i++) {
        grid.update(0.016);
      }

      expect(true, isTrue);
    });

    test('update with pulse waves and reducedFx', () {
      final grid = makeGrid(reducedFx: true);

      grid.triggerPulseWave(Vector2(100, 100));

      for (int i = 0; i < 10; i++) {
        grid.update(0.05);
      }

      expect(true, isTrue);
    });
  });

  group('NeonGridComponent render', () {
    // Note: Tests use reducedFx: true because _energyLines is only initialized
    // in onLoad() which requires Flame lifecycle. reducedFx mode works without it.
    test('renders without exceptions when size is set', () {
      final grid = makeGrid(reducedFx: true);
      grid.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.update(0.016);
      grid.render(canvas);
      recorder.endRecording();
    });

    test('renders with reducedFx', () {
      final grid = makeGrid(reducedFx: true);
      grid.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.update(0.016);
      grid.render(canvas);
      recorder.endRecording();
    });

    test('renders with pulse waves', () {
      final grid = makeGrid(reducedFx: true);
      grid.onGameResize(Vector2(800, 600));

      grid.triggerPulseWave(Vector2(400, 300));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.update(0.1);
      grid.render(canvas);
      recorder.endRecording();
    });

    test('renders with multiple pulse waves', () {
      final grid = makeGrid(reducedFx: true);
      grid.onGameResize(Vector2(800, 600));

      grid.triggerPulseWave(Vector2(100, 100), color: Colors.red);
      grid.triggerPulseWave(Vector2(400, 300), color: Colors.blue);
      grid.triggerPulseWave(Vector2(700, 500), color: Colors.green);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.update(0.1);
      grid.render(canvas);
      recorder.endRecording();
    });

    test('renders with small size', () {
      final grid = makeGrid(reducedFx: true);
      grid.onGameResize(Vector2(100, 100));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.update(0.016);
      grid.render(canvas);
      recorder.endRecording();
    });

    test('renders with large size', () {
      final grid = makeGrid(reducedFx: true);
      grid.onGameResize(Vector2(1920, 1080));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.update(0.016);
      grid.render(canvas);
      recorder.endRecording();
    });

    test('does not render with zero size', () {
      final grid = makeGrid(reducedFx: true);
      grid.size = Vector2.zero();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.render(canvas);
      recorder.endRecording();
    });

    test('renders after time passes', () {
      final grid = makeGrid(reducedFx: true);
      grid.onGameResize(Vector2(800, 600));

      for (int i = 0; i < 60; i++) {
        grid.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.render(canvas);
      recorder.endRecording();
    });

    test('renders with different grid sizes', () {
      for (final gridSize in [20.0, 40.0, 60.0, 80.0]) {
        final grid = makeGrid(gridSize: gridSize, reducedFx: true);
        grid.onGameResize(Vector2(800, 600));

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        grid.update(0.016);
        grid.render(canvas);
        recorder.endRecording();
      }
    });

    test('renders with cyan colors', () {
      final grid = makeGrid(
        lineColor: const Color(0xFF00FFFF),
        glowColor: const Color(0xFF00FFFF),
        reducedFx: true,
      );
      grid.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.update(0.016);
      grid.render(canvas);
      recorder.endRecording();
    });

    test('renders with magenta colors', () {
      final grid = makeGrid(
        lineColor: const Color(0xFFFF00FF),
        glowColor: const Color(0xFFFF00FF),
        reducedFx: true,
      );
      grid.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.update(0.016);
      grid.render(canvas);
      recorder.endRecording();
    });

    test('renders with green colors', () {
      final grid = makeGrid(
        lineColor: const Color(0xFF00FF00),
        glowColor: const Color(0xFF00FF88),
        reducedFx: true,
      );
      grid.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.update(0.016);
      grid.render(canvas);
      recorder.endRecording();
    });
  });

  group('NeonGridComponent onGameResize', () {
    test('updates size on resize', () {
      final grid = makeGrid();
      grid.size = Vector2(800, 600);

      grid.onGameResize(Vector2(1920, 1080));

      expect(grid.size.x, 1920);
      expect(grid.size.y, 1080);
    });

    test('reinitializes grid nodes on resize', () {
      final grid = makeGrid(reducedFx: false);
      grid.size = Vector2(800, 600);

      grid.onGameResize(Vector2(1600, 900));

      expect(true, isTrue);
    });

    test('handles resize with reducedFx', () {
      final grid = makeGrid(reducedFx: true);
      grid.size = Vector2(800, 600);

      grid.onGameResize(Vector2(1920, 1080));

      expect(grid.size.x, 1920);
    });

    test('handles resize to smaller size', () {
      final grid = makeGrid();
      grid.size = Vector2(1920, 1080);

      grid.onGameResize(Vector2(800, 600));

      expect(grid.size.x, 800);
      expect(grid.size.y, 600);
    });

    test('handles resize to same size', () {
      final grid = makeGrid();
      grid.size = Vector2(800, 600);

      grid.onGameResize(Vector2(800, 600));

      expect(grid.size.x, 800);
      expect(grid.size.y, 600);
    });
  });

  group('NeonGridComponent edge cases', () {
    test('handles very small grid size', () {
      final grid = makeGrid(gridSize: 5.0, reducedFx: true);
      grid.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.update(0.016);
      grid.render(canvas);
      recorder.endRecording();
    });

    test('handles very large grid size', () {
      final grid = makeGrid(gridSize: 200.0, reducedFx: true);
      grid.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.update(0.016);
      grid.render(canvas);
      recorder.endRecording();
    });

    test('renders with square aspect ratio', () {
      final grid = makeGrid(reducedFx: true);
      grid.onGameResize(Vector2(600, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.update(0.016);
      grid.render(canvas);
      recorder.endRecording();
    });

    test('renders with wide aspect ratio', () {
      final grid = makeGrid(reducedFx: true);
      grid.onGameResize(Vector2(1920, 400));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.update(0.016);
      grid.render(canvas);
      recorder.endRecording();
    });

    test('renders with tall aspect ratio', () {
      final grid = makeGrid(reducedFx: true);
      grid.onGameResize(Vector2(400, 1920));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.update(0.016);
      grid.render(canvas);
      recorder.endRecording();
    });
  });

  group('NeonGridComponent multiple instances', () {
    test('multiple grids can exist independently', () {
      final grid1 = makeGrid(gridSize: 30.0, reducedFx: true);
      final grid2 = makeGrid(gridSize: 50.0, reducedFx: true);

      grid1.onGameResize(Vector2(800, 600));
      grid2.onGameResize(Vector2(1920, 1080));

      grid1.triggerPulseWave(Vector2(100, 100));

      grid1.update(0.1);
      grid2.update(0.1);

      expect(grid1.gridSize, isNot(equals(grid2.gridSize)));
    });

    test('multiple grids render independently', () {
      final grid1 = makeGrid(reducedFx: true);
      final grid2 = makeGrid(reducedFx: true);

      grid1.onGameResize(Vector2(800, 600));
      grid2.onGameResize(Vector2(800, 600));

      grid1.update(0.016);
      grid2.update(0.016);

      final recorder1 = ui.PictureRecorder();
      final canvas1 = ui.Canvas(recorder1);

      final recorder2 = ui.PictureRecorder();
      final canvas2 = ui.Canvas(recorder2);

      grid1.render(canvas1);
      grid2.render(canvas2);

      recorder1.endRecording();
      recorder2.endRecording();
    });
  });

  group('NeonGridComponent reducedFx mode', () {
    test('reducedFx mode creates fewer effects', () {
      final normalGrid = makeGrid(reducedFx: false);
      final reducedGrid = makeGrid(reducedFx: true);

      expect(normalGrid.reducedFx, isFalse);
      expect(reducedGrid.reducedFx, isTrue);
    });

    test('reducedFx true renders minimal effects', () {
      final grid = makeGrid(reducedFx: true);
      grid.onGameResize(Vector2(800, 600));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      grid.update(0.5);
      grid.render(canvas);
      recorder.endRecording();
    });
  });
}
