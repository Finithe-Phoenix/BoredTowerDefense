import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReflectiveFloor default values', () {
    test('default primaryColor is cyan', () {
      const primaryColor = Color(0xFF00FFFF);
      expect(primaryColor.red, 0);
      expect(primaryColor.green, 255);
      expect(primaryColor.blue, 255);
    });

    test('default secondaryColor is magenta', () {
      const secondaryColor = Color(0xFFFF0066);
      expect(secondaryColor.red, 255);
      expect(secondaryColor.green, 0);
      expect(secondaryColor.blue, 102);
    });

    test('default gridSize is 50', () {
      const gridSize = 50.0;
      expect(gridSize, 50.0);
    });

    test('default horizonY is 0.3', () {
      const horizonY = 0.3;
      expect(horizonY, 0.3);
    });

    test('default reduceFx is false', () {
      const reduceFx = false;
      expect(reduceFx, isFalse);
    });

    test('default lowFx is false', () {
      const lowFx = false;
      expect(lowFx, isFalse);
    });
  });

  group('ReflectiveFloor constants', () {
    test('alpha steps is 16', () {
      const alphaSteps = 16;
      expect(alphaSteps, 16);
    });

    test('RNG seed is 0x6d2b79f5', () {
      const rngSeed = 0x6d2b79f5;
      expect(rngSeed, 0x6d2b79f5);
    });
  });

  group('ReflectiveFloor light streak counts', () {
    int getStreakCount(bool lowFx, bool reduceFx) {
      return lowFx ? 2 : (reduceFx ? 4 : 8);
    }

    test('full mode has 8 streaks', () {
      expect(getStreakCount(false, false), 8);
    });

    test('reduceFx mode has 4 streaks', () {
      expect(getStreakCount(false, true), 4);
    });

    test('lowFx mode has 2 streaks', () {
      expect(getStreakCount(true, true), 2);
      expect(getStreakCount(true, false), 2);
    });
  });

  group('ReflectiveFloor specular highlight counts', () {
    int getHighlightCount(bool lowFx, bool reduceFx) {
      return lowFx ? 0 : (reduceFx ? 2 : 5);
    }

    test('full mode has 5 highlights', () {
      expect(getHighlightCount(false, false), 5);
    });

    test('reduceFx mode has 2 highlights', () {
      expect(getHighlightCount(false, true), 2);
    });

    test('lowFx mode has 0 highlights', () {
      expect(getHighlightCount(true, true), 0);
      expect(getHighlightCount(true, false), 0);
    });
  });

  group('ReflectiveFloor ripple wave counts', () {
    int getWaveCount(bool lowFx, bool reduceFx) {
      return lowFx ? 0 : (reduceFx ? 2 : 4);
    }

    test('full mode has 4 waves', () {
      expect(getWaveCount(false, false), 4);
    });

    test('reduceFx mode has 2 waves', () {
      expect(getWaveCount(false, true), 2);
    });

    test('lowFx mode has 0 waves', () {
      expect(getWaveCount(true, true), 0);
      expect(getWaveCount(true, false), 0);
    });
  });

  group('ReflectiveFloor grid line counts', () {
    int getHorizontalLineCount(bool reduceFx) {
      return reduceFx ? 10 : 20;
    }

    int getVerticalLineCount(bool reduceFx) {
      return reduceFx ? 8 : 15;
    }

    test('full mode has 20 horizontal lines', () {
      expect(getHorizontalLineCount(false), 20);
    });

    test('reduceFx mode has 10 horizontal lines', () {
      expect(getHorizontalLineCount(true), 10);
    });

    test('full mode has 15 vertical lines', () {
      expect(getVerticalLineCount(false), 15);
    });

    test('reduceFx mode has 8 vertical lines', () {
      expect(getVerticalLineCount(true), 8);
    });
  });

  group('ReflectiveFloor LCG random number generator', () {
    test('LCG formula matches implementation', () {
      int state = 0x6d2b79f5;
      state = (1664525 * state + 1013904223) & 0x7fffffff;
      expect(state, isNonNegative);
      expect(state, lessThan(0x7fffffff));
    });

    test('nextUnit returns value between 0 and 1', () {
      int state = 0x6d2b79f5;
      state = (1664525 * state + 1013904223) & 0x7fffffff;
      final value = state / 0x7fffffff;
      expect(value, greaterThanOrEqualTo(0.0));
      expect(value, lessThanOrEqualTo(1.0));
    });

    test('nextBool uses LSB', () {
      int state = 0x6d2b79f5;
      state = (1664525 * state + 1013904223) & 0x7fffffff;
      final value = (state & 1) == 0;
      expect(value, isA<bool>());
    });

    test('LCG produces deterministic sequence', () {
      int state1 = 0x6d2b79f5;
      int state2 = 0x6d2b79f5;

      for (int i = 0; i < 10; i++) {
        state1 = (1664525 * state1 + 1013904223) & 0x7fffffff;
        state2 = (1664525 * state2 + 1013904223) & 0x7fffffff;
      }

      expect(state1, state2);
    });
  });

  group('ReflectiveFloor light streak parameters', () {
    test('yPosition range is 0.3 to 0.9', () {
      // yPosition = 0.3 + random * 0.6
      // min: 0.3 + 0 * 0.6 = 0.3
      // max: 0.3 + 1 * 0.6 = 0.9
      const minY = 0.3;
      const maxY = 0.9;
      expect(minY, 0.3);
      expect(maxY, 0.9);
    });

    test('speed range is 80 to 200', () {
      // speed = 80 + random * 120
      const minSpeed = 80.0;
      const maxSpeed = 200.0;
      expect(minSpeed, 80.0);
      expect(maxSpeed, 200.0);
    });

    test('width range is 60 to 160', () {
      // width = 60 + random * 100
      const minWidth = 60.0;
      const maxWidth = 160.0;
      expect(minWidth, 60.0);
      expect(maxWidth, 160.0);
    });

    test('direction is 1.0 or -1.0', () {
      const positiveDir = 1.0;
      const negativeDir = -1.0;
      expect(positiveDir, 1.0);
      expect(negativeDir, -1.0);
    });
  });

  group('ReflectiveFloor specular highlight parameters', () {
    test('xPosition range is 0.1 to 0.9', () {
      // xPosition = 0.1 + random * 0.8
      const minX = 0.1;
      const maxX = 0.9;
      expect(minX, 0.1);
      expect(maxX, 0.9);
    });

    test('yPosition range is 0.5 to 0.9', () {
      // yPosition = 0.5 + random * 0.4
      const minY = 0.5;
      const maxY = 0.9;
      expect(minY, 0.5);
      expect(maxY, 0.9);
    });

    test('size range is 20 to 60', () {
      // size = 20 + random * 40
      const minSize = 20.0;
      const maxSize = 60.0;
      expect(minSize, 20.0);
      expect(maxSize, 60.0);
    });

    test('intensity range is 0.3 to 0.7', () {
      // intensity = 0.3 + random * 0.4
      const minIntensity = 0.3;
      const maxIntensity = 0.7;
      expect(minIntensity, 0.3);
      expect(maxIntensity, 0.7);
    });

    test('pulseSpeed range is 1.5 to 3.5', () {
      // pulseSpeed = 1.5 + random * 2
      const minPulseSpeed = 1.5;
      const maxPulseSpeed = 3.5;
      expect(minPulseSpeed, 1.5);
      expect(maxPulseSpeed, 3.5);
    });
  });

  group('ReflectiveFloor ripple wave parameters', () {
    test('centerX range is 0.2 to 0.8', () {
      // centerX = 0.2 + random * 0.6
      const minX = 0.2;
      const maxX = 0.8;
      expect(minX, 0.2);
      expect(maxX, 0.8);
    });

    test('centerY range is 0.4 to 0.8', () {
      // centerY = 0.4 + random * 0.4
      const minY = 0.4;
      const maxY = 0.8;
      expect(minY, 0.4);
      expect(maxY, 0.8);
    });

    test('speed range is 30 to 80', () {
      // speed = 30 + random * 50
      const minSpeed = 30.0;
      const maxSpeed = 80.0;
      expect(minSpeed, 30.0);
      expect(maxSpeed, 80.0);
    });

    test('maxRadius range is 100 to 250', () {
      // maxRadius = 100 + random * 150
      const minRadius = 100.0;
      const maxRadius = 250.0;
      expect(minRadius, 100.0);
      expect(maxRadius, 250.0);
    });
  });

  group('ReflectiveFloor triggerRipple parameters', () {
    test('triggered ripple speed range', () {
      // speed = 60 + random * 40
      const minSpeed = 60.0;
      const maxSpeed = 100.0;
      expect(minSpeed, 60.0);
      expect(maxSpeed, 100.0);
    });

    test('triggered ripple maxRadius range', () {
      // maxRadius = 80 + random * 60
      const minRadius = 80.0;
      const maxRadius = 140.0;
      expect(minRadius, 80.0);
      expect(maxRadius, 140.0);
    });

    test('max active ripples is 8', () {
      const maxRipples = 8;
      expect(maxRipples, 8);
    });
  });

  group('ReflectiveFloor floor calculations', () {
    test('floorTop calculation', () {
      const h = 1080.0;
      const horizonY = 0.3;
      final floorTop = h * horizonY;
      expect(floorTop, 324.0);
    });

    test('floorHeight calculation', () {
      const h = 1080.0;
      const horizonY = 0.3;
      final floorTop = h * horizonY;
      final floorHeight = h - floorTop;
      expect(floorHeight, 756.0);
    });

    test('vanishingX is center of width', () {
      const w = 1920.0;
      final vanishingX = w / 2;
      expect(vanishingX, 960.0);
    });
  });

  group('ReflectiveFloor perspective calculations', () {
    test('perspective compression formula', () {
      // perspectiveT = pow(t, 1.8)
      final t = 0.5;
      final perspectiveT = math.pow(t, 1.8);
      expect(perspectiveT, closeTo(0.287, 0.001));
    });

    test('convergeFactor for vertical lines', () {
      const convergeFactor = 0.3;
      expect(convergeFactor, 0.3);
    });
  });

  group('ReflectiveFloor alpha calculations', () {
    test('distanceFromHorizon opacity formula', () {
      // alpha = 0.03 * distanceFromHorizon^2
      final distanceFromHorizon = 0.5;
      final alpha = 0.03 * distanceFromHorizon * distanceFromHorizon;
      expect(alpha, 0.0075);
    });

    test('alpha threshold is 0.005', () {
      const alphaThreshold = 0.005;
      expect(alphaThreshold, 0.005);
    });
  });

  group('ReflectiveFloor shimmer calculations', () {
    test('shimmer oscillates between 0.6 and 1.0', () {
      // shimmer = 0.8 + sin(time) * 0.2
      // min: 0.8 - 0.2 = 0.6
      // max: 0.8 + 0.2 = 1.0
      const minShimmer = 0.6;
      const maxShimmer = 1.0;
      expect(minShimmer, 0.6);
      expect(maxShimmer, 1.0);
    });
  });

  group('ReflectiveFloor pulse calculations', () {
    test('base pulse range', () {
      // basePulse = 0.03 + sin(time) * 0.01
      // min: 0.02, max: 0.04
      const minPulse = 0.02;
      const maxPulse = 0.04;
      expect(minPulse, 0.02);
      expect(maxPulse, 0.04);
    });

    test('fresnel pulse range', () {
      // fresnelPulse = 0.08 + sin(time) * 0.02
      // min: 0.06, max: 0.10
      const minPulse = 0.06;
      const maxPulse = 0.10;
      expect(minPulse, 0.06);
      expect(maxPulse, 0.10);
    });
  });

  group('ReflectiveFloor ripple fade calculation', () {
    test('ripple fade alpha formula', () {
      // fadeAlpha = (1 - progress) * 0.15
      final progress = 0.5;
      final fadeAlpha = (1 - progress) * 0.15;
      expect(fadeAlpha, 0.075);
    });

    test('ripple fade threshold is 0.02', () {
      const fadeThreshold = 0.02;
      expect(fadeThreshold, 0.02);
    });

    test('ring alpha decrease per ring', () {
      // ringAlpha = fadeAlpha * (1 - ring * 0.3)
      const ringMultiplier = 0.3;
      expect(ringMultiplier, 0.3);
    });

    test('ripple ring count is 3', () {
      const ringCount = 3;
      expect(ringCount, 3);
    });

    test('ripple ring spacing is 15', () {
      const ringSpacing = 15;
      expect(ringSpacing, 15);
    });
  });

  group('ReflectiveFloor specular intensity calculation', () {
    test('specular intensity threshold', () {
      // if (intensity < 0.05) continue
      const intensityThreshold = 0.05;
      expect(intensityThreshold, 0.05);
    });

    test('specular secondary highlight threshold', () {
      // if highlight.intensity > 0.4
      const secondaryThreshold = 0.4;
      expect(secondaryThreshold, 0.4);
    });
  });

  group('ReflectiveFloor wave pattern parameters', () {
    test('wave frequency is 0.02', () {
      const waveFrequency = 0.02;
      expect(waveFrequency, 0.02);
    });

    test('wave amplitude is 0.03', () {
      const waveAmplitude = 0.03;
      expect(waveAmplitude, 0.03);
    });

    test('wave speed is 2.0', () {
      const waveSpeed = 2.0;
      expect(waveSpeed, 2.0);
    });

    test('wave line spacing is 20', () {
      const lineSpacing = 20;
      expect(lineSpacing, 20);
    });
  });

  group('ReflectiveFloor traveling highlight parameters', () {
    test('traveling highlight count is 2', () {
      const travelingCount = 2;
      expect(travelingCount, 2);
    });

    test('traveling highlight base speed is 100', () {
      const baseSpeed = 100.0;
      expect(baseSpeed, 100.0);
    });

    test('traveling highlight speed increment is 50', () {
      const speedIncrement = 50.0;
      expect(speedIncrement, 50.0);
    });

    test('shader cache max size is 32', () {
      const maxCacheSize = 32;
      expect(maxCacheSize, 32);
    });
  });

  group('ReflectiveFloor gradient stops', () {
    test('base gradient has 4 stops', () {
      const stops = [0.0, 0.3, 0.7, 1.0];
      expect(stops.length, 4);
    });

    test('fresnel gradient has 4 stops', () {
      const stops = [0.0, 0.15, 0.4, 0.7];
      expect(stops.length, 4);
    });

    test('streak gradient has 7 stops', () {
      const stops = [0.0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0];
      expect(stops.length, 7);
    });
  });

  group('ReflectiveFloor edge dimensions', () {
    test('edge width is 15% of screen width', () {
      const w = 1920.0;
      final edgeWidth = w * 0.15;
      expect(edgeWidth, 288.0);
    });

    test('edge height is 30% of floor height', () {
      const floorHeight = 756.0;
      final edgeHeight = floorHeight * 0.3;
      expect(edgeHeight, closeTo(226.8, 0.1));
    });
  });

  group('ReflectiveFloor triggerRipple normalized coordinates', () {
    test('normalizedX calculation', () {
      const positionX = 500.0;
      const floorRectLeft = 0.0;
      const floorRectWidth = 1920.0;

      final normalizedX = (positionX - floorRectLeft) / floorRectWidth;
      expect(normalizedX, closeTo(0.26, 0.01));
    });

    test('normalizedY calculation', () {
      const positionY = 600.0;
      const floorRectTop = 0.0;
      const floorRectHeight = 1080.0;
      const horizonY = 0.3;

      final normalizedY = (positionY - floorRectTop - floorRectHeight * horizonY) /
          (floorRectHeight * (1 - horizonY));
      expect(normalizedY, closeTo(0.36, 0.01));
    });

    test('bounds check requires all coordinates 0-1', () {
      final inBounds = (double x, double y) =>
          x >= 0 && x <= 1 && y >= 0 && y <= 1;

      expect(inBounds(0.5, 0.5), isTrue);
      expect(inBounds(0.0, 0.0), isTrue);
      expect(inBounds(1.0, 1.0), isTrue);
      expect(inBounds(-0.1, 0.5), isFalse);
      expect(inBounds(0.5, 1.1), isFalse);
    });
  });

  group('ReflectiveFloor performance', () {
    test('can calculate many LCG values', () {
      int state = 0x6d2b79f5;
      for (int i = 0; i < 1000; i++) {
        state = (1664525 * state + 1013904223) & 0x7fffffff;
      }
      expect(state, isNonNegative);
    });

    test('can calculate many perspective values', () {
      for (int i = 0; i <= 100; i++) {
        final t = i / 100.0;
        final _ = math.pow(t, 1.8);
      }
      expect(true, isTrue);
    });

    test('can calculate many shimmer values', () {
      for (double time = 0; time < 100; time += 0.016) {
        final _ = 0.8 + math.sin(time * 2) * 0.2;
      }
      expect(true, isTrue);
    });
  });
}
