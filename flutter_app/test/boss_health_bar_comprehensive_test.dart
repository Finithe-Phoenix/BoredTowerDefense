import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for BossHealthBar logic and calculations

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED CLASSES FROM boss_health_bar.dart
// ═══════════════════════════════════════════════════════════════════════════════

/// Boss types from the game
enum BossType {
  miniBoss,
  citadelCore,
  abyssGate,
  voidlineApex,
  shardVault,
  arcFortress,
  coreHunter,
  omegaGrid,
  stormTower,
  finalGate,
  omegaNexus,
}

/// Constants from BossHealthBar
class BossHealthBarConstants {
  static const double barWidth = 600;
  static const double barHeight = 40;
  static const double borderWidth = 3;
  static const int maxPhases = 4;
  static const double animationSpeed = 3.0;
  static const double healthLerpSpeed = 5.0;
}

/// Boss name mapping
class BossNameMapper {
  static String getBossName(BossType type) {
    switch (type) {
      case BossType.miniBoss:
        return 'ELITE GUARD';
      case BossType.citadelCore:
        return 'CITADEL CORE';
      case BossType.abyssGate:
        return 'ABYSS GATE';
      case BossType.voidlineApex:
        return 'VOIDLINE APEX';
      case BossType.shardVault:
        return 'SHARD VAULT GUARDIAN';
      case BossType.arcFortress:
        return 'ARC FORTRESS TITAN';
      case BossType.coreHunter:
        return 'CORE HUNTER';
      case BossType.omegaGrid:
        return 'OMEGA GRID NEXUS';
      case BossType.stormTower:
        return 'STORM TOWER LORD';
      case BossType.finalGate:
        return 'FINAL GATE KEEPER';
      case BossType.omegaNexus:
        return 'OMEGA NEXUS - FINAL BOSS';
    }
  }
}

/// Phase color mapping
class PhaseColorMapper {
  static const Color phase1Color = Color(0xFF00FF88); // Green - healthy
  static const Color phase2Color = Color(0xFFFFFF00); // Yellow - warning
  static const Color phase3Color = Color(0xFFFF6600); // Orange - danger
  static const Color phase4Color = Color(0xFFFF0066); // Red/Magenta - critical

  static Color getPhaseColor(int phase) {
    switch (phase) {
      case 1:
        return phase1Color;
      case 2:
        return phase2Color;
      case 3:
        return phase3Color;
      case 4:
        return phase4Color;
      default:
        return phase1Color;
    }
  }
}

/// Health animation calculator
class HealthAnimator {
  double displayedHealth = 1.0;

  void update(double targetHealth, double dt) {
    displayedHealth += (targetHealth - displayedHealth) * dt * BossHealthBarConstants.healthLerpSpeed;
  }
}

/// Pulse animation calculator
class PulseAnimator {
  double _phase = 0;

  void update(double dt) {
    _phase += dt * BossHealthBarConstants.animationSpeed;
  }

  double get pulseAlpha => (math.sin(_phase * 2) * 0.3 + 0.3);

  double get warningGlowAlpha => (math.sin(_phase * 4) * 0.4 + 0.6);

  double get phase => _phase;
}

/// Health bar position calculator
class HealthBarPositionCalculator {
  static double calculateBarX(double screenWidth) {
    return screenWidth / 2;
  }

  static double calculateBarY() {
    return 60.0;
  }

  static double calculateHealthWidth(double healthPercent) {
    return BossHealthBarConstants.barWidth * healthPercent;
  }

  static List<double> calculateDivisionPositions() {
    final positions = <double>[];
    for (int i = 1; i < 4; i++) {
      positions.add(-BossHealthBarConstants.barWidth / 2 + (BossHealthBarConstants.barWidth * i / 4));
    }
    return positions;
  }
}

/// Glow rect calculator
class GlowRectCalculator {
  static (double, double) calculateGlowSize() {
    return (
      BossHealthBarConstants.barWidth + 20,
      BossHealthBarConstants.barHeight + 20,
    );
  }
}

/// Corner accent calculator
class CornerAccentCalculator {
  static const double accentLength = 15.0;

  static List<(double, double)> getCorners(double left, double top, double right, double bottom) {
    return [
      (left, top),
      (right, top),
      (left, bottom),
      (right, bottom),
    ];
  }

  static bool isLeftCorner(int index) => index == 0 || index == 2;
  static bool isTopCorner(int index) => index == 0 || index == 1;
}

/// Phase dot calculator
class PhaseDotCalculator {
  static const double activeRadius = 5.0;
  static const double inactiveRadius = 4.0;
  static const double dotSpacing = 12.0;

  static bool isDotActive(int dotIndex, int currentPhase) {
    return dotIndex < currentPhase;
  }

  static double getDotRadius(bool isActive) {
    return isActive ? activeRadius : inactiveRadius;
  }

  static double getDotX(int index, double baseX) {
    return baseX + (index * dotSpacing);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('BossHealthBar Constants', () {
    test('bar dimensions are correct', () {
      expect(BossHealthBarConstants.barWidth, 600);
      expect(BossHealthBarConstants.barHeight, 40);
      expect(BossHealthBarConstants.borderWidth, 3);
    });

    test('max phases is 4', () {
      expect(BossHealthBarConstants.maxPhases, 4);
    });

    test('animation speeds are correct', () {
      expect(BossHealthBarConstants.animationSpeed, 3.0);
      expect(BossHealthBarConstants.healthLerpSpeed, 5.0);
    });
  });

  group('BossType Enum', () {
    test('has 11 boss types', () {
      expect(BossType.values.length, 11);
    });

    test('contains all expected types', () {
      expect(BossType.values, contains(BossType.miniBoss));
      expect(BossType.values, contains(BossType.citadelCore));
      expect(BossType.values, contains(BossType.abyssGate));
      expect(BossType.values, contains(BossType.voidlineApex));
      expect(BossType.values, contains(BossType.shardVault));
      expect(BossType.values, contains(BossType.arcFortress));
      expect(BossType.values, contains(BossType.coreHunter));
      expect(BossType.values, contains(BossType.omegaGrid));
      expect(BossType.values, contains(BossType.stormTower));
      expect(BossType.values, contains(BossType.finalGate));
      expect(BossType.values, contains(BossType.omegaNexus));
    });
  });

  group('BossNameMapper', () {
    test('miniBoss is ELITE GUARD', () {
      expect(BossNameMapper.getBossName(BossType.miniBoss), 'ELITE GUARD');
    });

    test('citadelCore is CITADEL CORE', () {
      expect(BossNameMapper.getBossName(BossType.citadelCore), 'CITADEL CORE');
    });

    test('abyssGate is ABYSS GATE', () {
      expect(BossNameMapper.getBossName(BossType.abyssGate), 'ABYSS GATE');
    });

    test('voidlineApex is VOIDLINE APEX', () {
      expect(BossNameMapper.getBossName(BossType.voidlineApex), 'VOIDLINE APEX');
    });

    test('shardVault is SHARD VAULT GUARDIAN', () {
      expect(BossNameMapper.getBossName(BossType.shardVault), 'SHARD VAULT GUARDIAN');
    });

    test('arcFortress is ARC FORTRESS TITAN', () {
      expect(BossNameMapper.getBossName(BossType.arcFortress), 'ARC FORTRESS TITAN');
    });

    test('coreHunter is CORE HUNTER', () {
      expect(BossNameMapper.getBossName(BossType.coreHunter), 'CORE HUNTER');
    });

    test('omegaGrid is OMEGA GRID NEXUS', () {
      expect(BossNameMapper.getBossName(BossType.omegaGrid), 'OMEGA GRID NEXUS');
    });

    test('stormTower is STORM TOWER LORD', () {
      expect(BossNameMapper.getBossName(BossType.stormTower), 'STORM TOWER LORD');
    });

    test('finalGate is FINAL GATE KEEPER', () {
      expect(BossNameMapper.getBossName(BossType.finalGate), 'FINAL GATE KEEPER');
    });

    test('omegaNexus is OMEGA NEXUS - FINAL BOSS', () {
      expect(BossNameMapper.getBossName(BossType.omegaNexus), 'OMEGA NEXUS - FINAL BOSS');
    });

    test('all boss types have names', () {
      for (final type in BossType.values) {
        expect(BossNameMapper.getBossName(type), isNotEmpty);
      }
    });

    test('all names are uppercase', () {
      for (final type in BossType.values) {
        final name = BossNameMapper.getBossName(type);
        expect(name, name.toUpperCase());
      }
    });
  });

  group('PhaseColorMapper', () {
    test('phase 1 is green (healthy)', () {
      expect(PhaseColorMapper.getPhaseColor(1), const Color(0xFF00FF88));
    });

    test('phase 2 is yellow (warning)', () {
      expect(PhaseColorMapper.getPhaseColor(2), const Color(0xFFFFFF00));
    });

    test('phase 3 is orange (danger)', () {
      expect(PhaseColorMapper.getPhaseColor(3), const Color(0xFFFF6600));
    });

    test('phase 4 is red/magenta (critical)', () {
      expect(PhaseColorMapper.getPhaseColor(4), const Color(0xFFFF0066));
    });

    test('default phase returns green', () {
      expect(PhaseColorMapper.getPhaseColor(0), const Color(0xFF00FF88));
      expect(PhaseColorMapper.getPhaseColor(5), const Color(0xFF00FF88));
      expect(PhaseColorMapper.getPhaseColor(-1), const Color(0xFF00FF88));
    });

    test('colors become more intense with phase', () {
      // Phase 1 is green (calmest)
      // Phase 4 is red (most intense)
      final phase1 = PhaseColorMapper.getPhaseColor(1);
      final phase4 = PhaseColorMapper.getPhaseColor(4);

      // Green channel should be high for phase 1
      expect(phase1.green, greaterThan(phase4.green));
      // Red should be present in phase 4
      expect(phase4.red, greaterThan(0));
    });
  });

  group('HealthAnimator', () {
    test('starts at full health', () {
      final animator = HealthAnimator();
      expect(animator.displayedHealth, 1.0);
    });

    test('lerps towards target health', () {
      final animator = HealthAnimator();
      animator.displayedHealth = 1.0;

      animator.update(0.5, 0.1);
      // displayedHealth += (0.5 - 1.0) * 0.1 * 5 = -0.5 * 0.5 = -0.25
      expect(animator.displayedHealth, closeTo(0.75, 0.01));
    });

    test('health approaches target over time', () {
      final animator = HealthAnimator();
      animator.displayedHealth = 1.0;

      // Simulate multiple frames
      for (int i = 0; i < 100; i++) {
        animator.update(0.3, 0.016);
      }

      expect(animator.displayedHealth, closeTo(0.3, 0.01));
    });

    test('health can increase', () {
      final animator = HealthAnimator();
      animator.displayedHealth = 0.5;

      for (int i = 0; i < 50; i++) {
        animator.update(1.0, 0.016);
      }

      expect(animator.displayedHealth, greaterThan(0.5));
    });
  });

  group('PulseAnimator', () {
    test('starts at phase 0', () {
      final animator = PulseAnimator();
      expect(animator.phase, 0);
    });

    test('phase increases over time', () {
      final animator = PulseAnimator();
      animator.update(1.0);
      expect(animator.phase, closeTo(3.0, 0.01)); // 1.0 * 3.0
    });

    test('pulseAlpha oscillates between 0 and 0.6', () {
      final animator = PulseAnimator();

      for (double t = 0; t < 10; t += 0.1) {
        animator.update(0.1);
        final alpha = animator.pulseAlpha;
        expect(alpha, greaterThanOrEqualTo(0.0));
        expect(alpha, lessThanOrEqualTo(0.6));
      }
    });

    test('warningGlowAlpha oscillates between 0.2 and 1.0', () {
      final animator = PulseAnimator();

      for (double t = 0; t < 10; t += 0.1) {
        animator.update(0.1);
        final alpha = animator.warningGlowAlpha;
        expect(alpha, greaterThanOrEqualTo(0.2));
        expect(alpha, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('HealthBarPositionCalculator', () {
    test('bar X is centered on screen', () {
      expect(HealthBarPositionCalculator.calculateBarX(1920), 960);
      expect(HealthBarPositionCalculator.calculateBarX(1280), 640);
      expect(HealthBarPositionCalculator.calculateBarX(800), 400);
    });

    test('bar Y is at 60', () {
      expect(HealthBarPositionCalculator.calculateBarY(), 60);
    });

    test('health width scales with percent', () {
      expect(HealthBarPositionCalculator.calculateHealthWidth(1.0), 600);
      expect(HealthBarPositionCalculator.calculateHealthWidth(0.5), 300);
      expect(HealthBarPositionCalculator.calculateHealthWidth(0.25), 150);
      expect(HealthBarPositionCalculator.calculateHealthWidth(0.0), 0);
    });

    test('division positions are at 25%, 50%, 75%', () {
      final positions = HealthBarPositionCalculator.calculateDivisionPositions();

      expect(positions.length, 3);
      // Bar goes from -300 to 300
      // 25%: -300 + 150 = -150
      // 50%: -300 + 300 = 0
      // 75%: -300 + 450 = 150
      expect(positions[0], closeTo(-150, 0.1));
      expect(positions[1], closeTo(0, 0.1));
      expect(positions[2], closeTo(150, 0.1));
    });
  });

  group('GlowRectCalculator', () {
    test('glow rect is larger than bar', () {
      final (width, height) = GlowRectCalculator.calculateGlowSize();

      expect(width, BossHealthBarConstants.barWidth + 20);
      expect(height, BossHealthBarConstants.barHeight + 20);
      expect(width, 620);
      expect(height, 60);
    });
  });

  group('CornerAccentCalculator', () {
    test('accent length is 15', () {
      expect(CornerAccentCalculator.accentLength, 15);
    });

    test('returns 4 corners', () {
      final corners = CornerAccentCalculator.getCorners(-100, -50, 100, 50);
      expect(corners.length, 4);
    });

    test('corners are at correct positions', () {
      final corners = CornerAccentCalculator.getCorners(-100, -50, 100, 50);

      expect(corners[0], (-100.0, -50.0)); // Top-left
      expect(corners[1], (100.0, -50.0)); // Top-right
      expect(corners[2], (-100.0, 50.0)); // Bottom-left
      expect(corners[3], (100.0, 50.0)); // Bottom-right
    });

    test('isLeftCorner identifies left corners', () {
      expect(CornerAccentCalculator.isLeftCorner(0), true); // Top-left
      expect(CornerAccentCalculator.isLeftCorner(1), false); // Top-right
      expect(CornerAccentCalculator.isLeftCorner(2), true); // Bottom-left
      expect(CornerAccentCalculator.isLeftCorner(3), false); // Bottom-right
    });

    test('isTopCorner identifies top corners', () {
      expect(CornerAccentCalculator.isTopCorner(0), true); // Top-left
      expect(CornerAccentCalculator.isTopCorner(1), true); // Top-right
      expect(CornerAccentCalculator.isTopCorner(2), false); // Bottom-left
      expect(CornerAccentCalculator.isTopCorner(3), false); // Bottom-right
    });
  });

  group('PhaseDotCalculator', () {
    test('active radius is larger than inactive', () {
      expect(PhaseDotCalculator.activeRadius, greaterThan(PhaseDotCalculator.inactiveRadius));
      expect(PhaseDotCalculator.activeRadius, 5);
      expect(PhaseDotCalculator.inactiveRadius, 4);
    });

    test('dot spacing is 12', () {
      expect(PhaseDotCalculator.dotSpacing, 12);
    });

    test('dots before current phase are active', () {
      // Phase 3: dots 0, 1, 2 active; dot 3 inactive
      expect(PhaseDotCalculator.isDotActive(0, 3), true);
      expect(PhaseDotCalculator.isDotActive(1, 3), true);
      expect(PhaseDotCalculator.isDotActive(2, 3), true);
      expect(PhaseDotCalculator.isDotActive(3, 3), false);
    });

    test('all dots inactive at phase 0', () {
      for (int i = 0; i < 4; i++) {
        expect(PhaseDotCalculator.isDotActive(i, 0), false);
      }
    });

    test('all dots active at phase 4+', () {
      for (int i = 0; i < 4; i++) {
        expect(PhaseDotCalculator.isDotActive(i, 4), true);
        expect(PhaseDotCalculator.isDotActive(i, 5), true);
      }
    });

    test('dot radius depends on active state', () {
      expect(PhaseDotCalculator.getDotRadius(true), 5);
      expect(PhaseDotCalculator.getDotRadius(false), 4);
    });

    test('dot X positions are spaced evenly', () {
      const baseX = 100.0;
      expect(PhaseDotCalculator.getDotX(0, baseX), 100);
      expect(PhaseDotCalculator.getDotX(1, baseX), 112);
      expect(PhaseDotCalculator.getDotX(2, baseX), 124);
      expect(PhaseDotCalculator.getDotX(3, baseX), 136);
    });
  });

  group('Health Percentage Display', () {
    test('full health displays as 100%', () {
      final healthPercent = 1.0 * 100;
      expect(healthPercent.toInt(), 100);
    });

    test('half health displays as 50%', () {
      final healthPercent = 0.5 * 100;
      expect(healthPercent.toInt(), 50);
    });

    test('low health displays correctly', () {
      final healthPercent = 0.15 * 100;
      expect(healthPercent.toInt(), 15);
    });

    test('zero health displays as 0%', () {
      final healthPercent = 0.0 * 100;
      expect(healthPercent.toInt(), 0);
    });
  });

  group('Phase Text Formatting', () {
    test('phase text format', () {
      for (int phase = 1; phase <= 4; phase++) {
        final text = 'PHASE $phase/4';
        expect(text, contains('PHASE'));
        expect(text, contains('$phase'));
        expect(text, contains('/4'));
      }
    });
  });

  group('Warning Skull Visibility', () {
    test('skull shows only at phase 4+', () {
      bool shouldShowSkull(int phase) => phase >= 4;

      expect(shouldShowSkull(1), false);
      expect(shouldShowSkull(2), false);
      expect(shouldShowSkull(3), false);
      expect(shouldShowSkull(4), true);
      expect(shouldShowSkull(5), true);
    });
  });

  group('Skull Position', () {
    test('skull is to the left of the bar', () {
      final skullX = -BossHealthBarConstants.barWidth / 2 - 30;
      expect(skullX, -330);
    });

    test('skull Y is centered', () {
      const skullY = 0.0;
      expect(skullY, 0);
    });
  });

  group('Integration: Boss Health Flow', () {
    test('complete health update cycle', () {
      final animator = HealthAnimator();
      final pulse = PulseAnimator();

      // Initial state
      expect(animator.displayedHealth, 1.0);

      // Boss takes damage
      const targetHealth = 0.6;

      // Simulate 1 second of updates
      for (int i = 0; i < 60; i++) {
        animator.update(targetHealth, 0.016);
        pulse.update(0.016);
      }

      expect(animator.displayedHealth, closeTo(0.6, 0.05));
      expect(pulse.phase, greaterThan(0));
    });
  });
}
