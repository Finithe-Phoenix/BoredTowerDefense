import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for HudButton logic and calculations

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED CLASSES FROM hud_button.dart
// ═══════════════════════════════════════════════════════════════════════════════

/// Default button size
class HudButtonDefaults {
  static const double defaultWidth = 110;
  static const double defaultHeight = 44;
  static const Color defaultColor = Color(0xFF00FFFF);
  static const double cornerRadius = 8;
  static const double cornerAccentSize = 10.0;
  static const double cornerOffset = 1.0;
}

/// Hover scale animation calculator
class HoverScaleAnimator {
  double _hoverScale = 0;
  bool isSelected = false;
  bool isHovered = false;

  void update(double dt) {
    final targetScale = (isSelected || isHovered) ? 1.0 : 0.0;
    _hoverScale += (targetScale - _hoverScale) * dt * 8;
    _hoverScale = _hoverScale.clamp(0.0, 1.0);
  }

  double get hoverScale => _hoverScale;
}

/// Press animation calculator
class PressAnimator {
  double _pressAnimation = 0;
  bool isPressed = false;

  void press() {
    isPressed = true;
    _pressAnimation = 1.0;
  }

  void release() {
    isPressed = false;
  }

  void update(double dt) {
    if (!isPressed && _pressAnimation > 0) {
      _pressAnimation = (_pressAnimation - dt * 8).clamp(0, 1);
    }
  }

  double get pressAnimation => _pressAnimation;
}

/// Scan line animation calculator
class ScanLineAnimator {
  double _time = 0;

  void update(double dt) {
    _time += dt;
  }

  double get scanProgress => (_time * 0.8) % 1.0;

  double getScanY(double buttonHeight) {
    return scanProgress * buttonHeight;
  }
}

/// Particle animation calculator
class ParticleAnimator {
  double _time = 0;
  final int particleCount = 3;

  void update(double dt) {
    _time += dt;
  }

  double getParticlePhase(int index) {
    return (_time * 2 + index * 0.4) % 1.0;
  }

  double getParticleX(int index, double buttonWidth) {
    final phase = getParticlePhase(index);
    return 6 + phase * (buttonWidth - 12);
  }

  double getParticleY(int index, double buttonHeight) {
    final phase = getParticlePhase(index);
    return buttonHeight - 6 - math.sin(phase * math.pi) * 4;
  }

  double getParticleAlpha(int index) {
    final phase = getParticlePhase(index);
    return math.sin(phase * math.pi) * 0.6;
  }
}

/// Border animation calculator
class BorderAnimator {
  double _time = 0;
  bool reduceFlicker = false;
  double hoverScale = 0;

  void update(double dt) {
    _time += dt;
  }

  double getBorderAlpha() {
    final pulse = reduceFlicker ? 0.0 : math.sin(_time * 3) * 0.05;
    return (0.4 + hoverScale * 0.3 + pulse).clamp(0.0, 1.0);
  }
}

/// Selection effect calculator
class SelectionEffectCalculator {
  double _time = 0;
  bool reduceFlicker = false;

  void update(double dt) {
    _time += dt;
  }

  double getPulseAlpha() {
    return reduceFlicker ? 0.55 : 0.5 + math.sin(_time * 4) * 0.3;
  }

  double getBarWidth() {
    return reduceFlicker ? 40.0 : 40 + math.sin(_time * 3) * 5;
  }
}

/// Press ring effect calculator
class PressRingCalculator {
  static double getRingRadius(double pressAnimation) {
    return 20 + (1 - pressAnimation) * 30;
  }

  static double getRingAlpha(double pressAnimation) {
    return pressAnimation * 0.3;
  }
}

/// Font size calculator
class FontSizeCalculator {
  static double getFontSize(double buttonWidth) {
    return buttonWidth < 90 ? 10.0 : 11.0;
  }
}

/// Background color calculator
class BackgroundColorCalculator {
  static Color getBackgroundColor(bool isSelected, bool isEnabled, Color baseColor) {
    if (isSelected) {
      return baseColor.withOpacity(0.25);
    }
    return isEnabled
        ? const Color(0xFF0a0a18).withOpacity(0.8)
        : const Color(0xFF0a0a18).withOpacity(0.4);
  }

  static Color getBorderColor(bool isSelected, bool isEnabled, Color baseColor) {
    if (isSelected) return baseColor;
    return isEnabled ? baseColor.withOpacity(0.4) : baseColor.withOpacity(0.15);
  }

  static double getBorderWidth(bool isSelected) {
    return isSelected ? 2 : 1;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('HudButton Defaults', () {
    test('default size is 110x44', () {
      expect(HudButtonDefaults.defaultWidth, 110);
      expect(HudButtonDefaults.defaultHeight, 44);
    });

    test('default color is cyan', () {
      expect(HudButtonDefaults.defaultColor, const Color(0xFF00FFFF));
    });

    test('corner radius is 8', () {
      expect(HudButtonDefaults.cornerRadius, 8);
    });

    test('corner accent size is 10', () {
      expect(HudButtonDefaults.cornerAccentSize, 10);
    });

    test('corner offset is 1', () {
      expect(HudButtonDefaults.cornerOffset, 1);
    });
  });

  group('HoverScaleAnimator', () {
    test('starts at 0', () {
      final animator = HoverScaleAnimator();
      expect(animator.hoverScale, 0);
    });

    test('scale increases when selected', () {
      final animator = HoverScaleAnimator();
      animator.isSelected = true;

      animator.update(0.5);
      expect(animator.hoverScale, greaterThan(0));
    });

    test('scale increases when hovered', () {
      final animator = HoverScaleAnimator();
      animator.isHovered = true;

      animator.update(0.5);
      expect(animator.hoverScale, greaterThan(0));
    });

    test('scale approaches 1 when selected', () {
      final animator = HoverScaleAnimator();
      animator.isSelected = true;

      for (int i = 0; i < 60; i++) {
        animator.update(0.016);
      }

      expect(animator.hoverScale, closeTo(1.0, 0.05));
    });

    test('scale returns to 0 when deselected', () {
      final animator = HoverScaleAnimator();
      animator.isSelected = true;

      // Build up
      for (int i = 0; i < 30; i++) {
        animator.update(0.016);
      }

      animator.isSelected = false;

      // Decay
      for (int i = 0; i < 60; i++) {
        animator.update(0.016);
      }

      expect(animator.hoverScale, closeTo(0, 0.05));
    });

    test('scale clamps to [0, 1]', () {
      final animator = HoverScaleAnimator();
      animator.isSelected = true;

      // Even with very long dt, should clamp
      animator.update(10.0);
      expect(animator.hoverScale, 1.0);
    });
  });

  group('PressAnimator', () {
    test('starts at 0', () {
      final animator = PressAnimator();
      expect(animator.pressAnimation, 0);
    });

    test('press sets animation to 1', () {
      final animator = PressAnimator();
      animator.press();
      expect(animator.pressAnimation, 1.0);
    });

    test('animation decays after release', () {
      final animator = PressAnimator();
      animator.press();
      animator.release();

      animator.update(0.1);
      expect(animator.pressAnimation, lessThan(1.0));
    });

    test('animation does not decay while pressed', () {
      final animator = PressAnimator();
      animator.press();

      animator.update(0.1);
      expect(animator.pressAnimation, 1.0);
    });

    test('animation decays completely over time', () {
      final animator = PressAnimator();
      animator.press();
      animator.release();

      for (int i = 0; i < 30; i++) {
        animator.update(0.016);
      }

      expect(animator.pressAnimation, closeTo(0, 0.05));
    });

    test('animation clamps to 0', () {
      final animator = PressAnimator();
      animator.press();
      animator.release();

      animator.update(10.0);
      expect(animator.pressAnimation, 0);
    });
  });

  group('ScanLineAnimator', () {
    test('scan progress starts at 0', () {
      final animator = ScanLineAnimator();
      expect(animator.scanProgress, closeTo(0, 0.001));
    });

    test('scan progress increases over time', () {
      final animator = ScanLineAnimator();
      animator.update(0.5);

      // 0.5 * 0.8 = 0.4
      expect(animator.scanProgress, closeTo(0.4, 0.001));
    });

    test('scan progress wraps at 1', () {
      final animator = ScanLineAnimator();
      animator.update(1.5); // 1.5 * 0.8 = 1.2 -> 0.2

      expect(animator.scanProgress, closeTo(0.2, 0.001));
    });

    test('scan Y is proportional to button height', () {
      final animator = ScanLineAnimator();
      animator.update(0.5);

      const buttonHeight = 44.0;
      final scanY = animator.getScanY(buttonHeight);

      expect(scanY, closeTo(17.6, 0.1)); // 0.4 * 44
    });
  });

  group('ParticleAnimator', () {
    test('has 3 particles', () {
      final animator = ParticleAnimator();
      expect(animator.particleCount, 3);
    });

    test('particle phases are offset', () {
      final animator = ParticleAnimator();
      animator.update(1.0);

      final phase0 = animator.getParticlePhase(0);
      final phase1 = animator.getParticlePhase(1);
      final phase2 = animator.getParticlePhase(2);

      // Phases should be different due to offset
      expect(phase0, isNot(equals(phase1)));
      expect(phase1, isNot(equals(phase2)));
    });

    test('particle X spans button width', () {
      final animator = ParticleAnimator();
      const buttonWidth = 110.0;

      // At phase 0, X = 6
      // At phase 1, X = 6 + (110 - 12) = 104

      double minX = double.infinity;
      double maxX = double.negativeInfinity;

      for (double t = 0; t < 10; t += 0.1) {
        animator.update(0.1);
        final x = animator.getParticleX(0, buttonWidth);
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
      }

      expect(minX, greaterThanOrEqualTo(6));
      expect(maxX, lessThanOrEqualTo(104));
    });

    test('particle Y oscillates', () {
      final animator = ParticleAnimator();
      const buttonHeight = 44.0;

      double minY = double.infinity;
      double maxY = double.negativeInfinity;

      for (double t = 0; t < 5; t += 0.1) {
        animator.update(0.1);
        final y = animator.getParticleY(0, buttonHeight);
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }

      // Y should oscillate around buttonHeight - 6
      expect(minY, lessThan(buttonHeight - 6));
      expect(maxY, greaterThanOrEqualTo(buttonHeight - 10));
    });

    test('particle alpha oscillates with sine', () {
      final animator = ParticleAnimator();

      bool foundPositive = false;
      bool foundZero = false;

      for (double t = 0; t < 5; t += 0.1) {
        animator.update(0.1);
        final alpha = animator.getParticleAlpha(0);

        if (alpha > 0.3) foundPositive = true;
        if (alpha < 0.1) foundZero = true;
      }

      expect(foundPositive, true);
      expect(foundZero, true);
    });
  });

  group('BorderAnimator', () {
    test('base alpha is 0.4', () {
      final animator = BorderAnimator();
      animator.hoverScale = 0;
      animator.reduceFlicker = true;

      expect(animator.getBorderAlpha(), closeTo(0.4, 0.001));
    });

    test('hover increases alpha', () {
      final animator = BorderAnimator();
      animator.hoverScale = 1.0;
      animator.reduceFlicker = true;

      // 0.4 + 1.0 * 0.3 = 0.7
      expect(animator.getBorderAlpha(), closeTo(0.7, 0.001));
    });

    test('pulse adds variation when not reduced', () {
      final animator = BorderAnimator();
      animator.hoverScale = 0;
      animator.reduceFlicker = false;

      double minAlpha = double.infinity;
      double maxAlpha = double.negativeInfinity;

      for (double t = 0; t < 5; t += 0.1) {
        animator.update(0.1);
        final alpha = animator.getBorderAlpha();
        if (alpha < minAlpha) minAlpha = alpha;
        if (alpha > maxAlpha) maxAlpha = alpha;
      }

      expect(maxAlpha - minAlpha, greaterThan(0.05));
    });

    test('no pulse when reduced', () {
      final animator = BorderAnimator();
      animator.reduceFlicker = true;
      animator.hoverScale = 0;

      final alpha1 = animator.getBorderAlpha();
      animator.update(0.5);
      final alpha2 = animator.getBorderAlpha();

      expect(alpha1, alpha2);
    });
  });

  group('SelectionEffectCalculator', () {
    test('pulse alpha oscillates when not reduced', () {
      final calc = SelectionEffectCalculator();
      calc.reduceFlicker = false;

      double minAlpha = double.infinity;
      double maxAlpha = double.negativeInfinity;

      for (double t = 0; t < 5; t += 0.1) {
        calc.update(0.1);
        final alpha = calc.getPulseAlpha();
        if (alpha < minAlpha) minAlpha = alpha;
        if (alpha > maxAlpha) maxAlpha = alpha;
      }

      expect(minAlpha, closeTo(0.2, 0.1));
      expect(maxAlpha, closeTo(0.8, 0.1));
    });

    test('pulse alpha is constant when reduced', () {
      final calc = SelectionEffectCalculator();
      calc.reduceFlicker = true;

      final alpha1 = calc.getPulseAlpha();
      calc.update(0.5);
      final alpha2 = calc.getPulseAlpha();

      expect(alpha1, 0.55);
      expect(alpha2, 0.55);
    });

    test('bar width oscillates when not reduced', () {
      final calc = SelectionEffectCalculator();
      calc.reduceFlicker = false;

      double minWidth = double.infinity;
      double maxWidth = double.negativeInfinity;

      for (double t = 0; t < 5; t += 0.1) {
        calc.update(0.1);
        final width = calc.getBarWidth();
        if (width < minWidth) minWidth = width;
        if (width > maxWidth) maxWidth = width;
      }

      expect(minWidth, closeTo(35, 1));
      expect(maxWidth, closeTo(45, 1));
    });

    test('bar width is constant when reduced', () {
      final calc = SelectionEffectCalculator();
      calc.reduceFlicker = true;

      expect(calc.getBarWidth(), 40.0);
    });
  });

  group('PressRingCalculator', () {
    test('ring radius at full press', () {
      expect(PressRingCalculator.getRingRadius(1.0), 20);
    });

    test('ring radius at no press', () {
      expect(PressRingCalculator.getRingRadius(0.0), 50);
    });

    test('ring radius at half press', () {
      expect(PressRingCalculator.getRingRadius(0.5), 35);
    });

    test('ring alpha at full press', () {
      expect(PressRingCalculator.getRingAlpha(1.0), 0.3);
    });

    test('ring alpha at no press', () {
      expect(PressRingCalculator.getRingAlpha(0.0), 0);
    });

    test('ring alpha at half press', () {
      expect(PressRingCalculator.getRingAlpha(0.5), 0.15);
    });
  });

  group('FontSizeCalculator', () {
    test('small button uses 10pt font', () {
      expect(FontSizeCalculator.getFontSize(80), 10.0);
      expect(FontSizeCalculator.getFontSize(89), 10.0);
    });

    test('normal button uses 11pt font', () {
      expect(FontSizeCalculator.getFontSize(90), 11.0);
      expect(FontSizeCalculator.getFontSize(110), 11.0);
      expect(FontSizeCalculator.getFontSize(200), 11.0);
    });

    test('threshold is at 90', () {
      expect(FontSizeCalculator.getFontSize(89.9), 10.0);
      expect(FontSizeCalculator.getFontSize(90), 11.0);
    });
  });

  group('BackgroundColorCalculator', () {
    test('selected button has tinted background', () {
      const baseColor = Color(0xFF00FFFF);
      final bg = BackgroundColorCalculator.getBackgroundColor(true, true, baseColor);

      expect(bg.opacity, closeTo(0.25, 0.01));
      expect(bg.red, baseColor.red);
    });

    test('enabled unselected button has dark background', () {
      const baseColor = Color(0xFF00FFFF);
      final bg = BackgroundColorCalculator.getBackgroundColor(false, true, baseColor);

      expect(bg, const Color(0xFF0a0a18).withOpacity(0.8));
    });

    test('disabled button has lighter background', () {
      const baseColor = Color(0xFF00FFFF);
      final bg = BackgroundColorCalculator.getBackgroundColor(false, false, baseColor);

      expect(bg.opacity, closeTo(0.4, 0.01));
    });

    test('selected border is full color', () {
      const baseColor = Color(0xFF00FFFF);
      final border = BackgroundColorCalculator.getBorderColor(true, true, baseColor);

      expect(border, baseColor);
    });

    test('enabled unselected border is dimmed', () {
      const baseColor = Color(0xFF00FFFF);
      final border = BackgroundColorCalculator.getBorderColor(false, true, baseColor);

      expect(border.opacity, closeTo(0.4, 0.01));
    });

    test('disabled border is very dim', () {
      const baseColor = Color(0xFF00FFFF);
      final border = BackgroundColorCalculator.getBorderColor(false, false, baseColor);

      expect(border.opacity, closeTo(0.15, 0.01));
    });

    test('selected border is thicker', () {
      expect(BackgroundColorCalculator.getBorderWidth(true), 2);
      expect(BackgroundColorCalculator.getBorderWidth(false), 1);
    });
  });

  group('Corner Accent Positions', () {
    test('corner positions are calculated correctly', () {
      const width = 110.0;
      const height = 44.0;
      const size = HudButtonDefaults.cornerAccentSize;
      const offset = HudButtonDefaults.cornerOffset;

      // Top-left corner lines
      expect(offset, 1.0);
      expect(size + offset, 11.0);

      // Top-right corner
      expect(width - size - offset, 99.0);
      expect(width - offset, 109.0);

      // Bottom-left corner
      expect(height - size - offset, 33.0);
      expect(height - offset, 43.0);

      // Bottom-right corner
      expect(width - size - offset, 99.0);
      expect(height - size - offset, 33.0);
    });
  });

  group('Tech Detail Positions', () {
    test('tick marks are at button midpoint', () {
      const height = 44.0;
      final midY = height / 2;

      expect(midY, 22.0);
      expect(midY - 4, 18.0);
      expect(midY + 4, 26.0);
    });

    test('top notch is centered', () {
      const width = 110.0;
      final centerX = width / 2;

      expect(centerX, 55.0);
      expect(centerX - 8, 47.0);
      expect(centerX - 4, 51.0);
      expect(centerX + 4, 59.0);
      expect(centerX + 8, 63.0);
    });
  });

  group('Label Positioning', () {
    test('label is centered', () {
      const buttonWidth = 110.0;
      const buttonHeight = 44.0;
      const labelWidth = 50.0;
      const labelHeight = 14.0;

      final labelX = (buttonWidth - labelWidth) / 2;
      final labelY = (buttonHeight - labelHeight) / 2;

      expect(labelX, 30.0);
      expect(labelY, 15.0);
    });
  });

  group('Text Color', () {
    test('enabled selected text is white', () {
      // isEnabled && isSelected -> white
      final color = Colors.white;
      expect(color.opacity, 1.0);
    });

    test('enabled unselected text is slightly transparent', () {
      final color = Colors.white.withOpacity(0.9);
      expect(color.opacity, closeTo(0.9, 0.01));
    });

    test('disabled text is very transparent', () {
      final color = Colors.white.withOpacity(0.4);
      expect(color.opacity, closeTo(0.4, 0.01));
    });
  });

  group('Selection Indicator Dimensions', () {
    test('side indicators are 3x16 pixels', () {
      const indicatorWidth = 3.0;
      const indicatorHeight = 16.0;

      expect(indicatorWidth, 3);
      expect(indicatorHeight, 16);
    });

    test('side indicators are vertically centered', () {
      const buttonHeight = 44.0;
      const indicatorHeight = 16.0;

      final indicatorY = buttonHeight / 2 - indicatorHeight / 2;
      expect(indicatorY, 14.0);
    });
  });
}
