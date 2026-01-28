import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/tower.dart';

void main() {
  group('TowerType enum', () {
    test('all tower types exist', () {
      expect(TowerType.values, contains(TowerType.pulseArcher));
      expect(TowerType.values, contains(TowerType.circuitCannon));
      expect(TowerType.values, contains(TowerType.phaseMage));
      expect(TowerType.values, contains(TowerType.glimmerField));
      expect(TowerType.values, contains(TowerType.ionSniper));
      expect(TowerType.values, contains(TowerType.teslaTerminal));
      expect(TowerType.values, contains(TowerType.resonanceSiphon));
      expect(TowerType.values, contains(TowerType.neuralDisruptor));
    });

    test('tower type count is 9', () {
      expect(TowerType.values.length, 9);
    });

    test('tower types expose valid numeric stats', () {
      for (final type in TowerType.values) {
        expect(type.name.isNotEmpty, isTrue);
        expect(type.cost, greaterThan(0));
        expect(type.range, greaterThan(0));
        expect(type.fireRate, greaterThan(0));
        expect(type.damage, greaterThanOrEqualTo(0));
        expect(type.projectileSpeed, greaterThanOrEqualTo(0));
        if (type.damage == 0) {
          expect(type, TowerType.resonanceSiphon);
        }
        if (type.projectileSpeed == 0) {
          expect(
            type == TowerType.teslaTerminal || type == TowerType.resonanceSiphon,
            isTrue,
          );
        }
      }
    });

    test('all towers have colors', () {
      for (final type in TowerType.values) {
        expect(type.color, isA<Color>());
        expect(type.color.alpha, greaterThan(0));
      }
    });
  });

  group('TowerType specific values', () {
    test('pulseArcher has correct stats', () {
      const type = TowerType.pulseArcher;
      expect(type.name, 'Pulse Archer');
      expect(type.damage, 15);
      expect(type.fireRate, 2.0);
      expect(type.range, 160);
      expect(type.cost, 50);
      expect(type.projectileSpeed, 400);
      expect(type.slowAmount, 0);
      expect(type.slowDuration, 0);
      expect(type.canDetectPhantom, isFalse);
    });

    test('circuitCannon has correct stats', () {
      const type = TowerType.circuitCannon;
      expect(type.name, 'Circuit Cannon');
      expect(type.damage, 50);
      expect(type.fireRate, 0.5);
      expect(type.range, 140);
      expect(type.cost, 100);
      expect(type.projectileSpeed, 250);
      expect(type.canDetectPhantom, isFalse);
    });

    test('phaseMage has correct stats and can detect phantoms', () {
      const type = TowerType.phaseMage;
      expect(type.name, 'Phase Mage');
      expect(type.damage, 25);
      expect(type.fireRate, 1.2);
      expect(type.range, 200);
      expect(type.cost, 80);
      expect(type.projectileSpeed, 350);
      expect(type.slowAmount, 0.5);
      expect(type.slowDuration, 1.5);
      expect(type.canDetectPhantom, isTrue);
    });

    test('glimmerField has correct stats', () {
      const type = TowerType.glimmerField;
      expect(type.name, 'Glimmer Field');
      expect(type.damage, 8);
      expect(type.fireRate, 4.0);
      expect(type.range, 120);
      expect(type.cost, 120);
      expect(type.projectileSpeed, 500);
      expect(type.slowAmount, 0.3);
      expect(type.slowDuration, 0.5);
    });

    test('ionSniper has correct stats', () {
      const type = TowerType.ionSniper;
      expect(type.name, 'Ion Sniper');
      expect(type.damage, 180);
      expect(type.fireRate, 0.4);
      expect(type.range, 300);
      expect(type.cost, 250);
      expect(type.projectileSpeed, 800);
    });

    test('teslaTerminal has instant hit (zero projectile speed)', () {
      const type = TowerType.teslaTerminal;
      expect(type.name, 'Tesla Terminal');
      expect(type.damage, 12);
      expect(type.fireRate, 3.5);
      expect(type.range, 150);
      expect(type.cost, 180);
      expect(type.projectileSpeed, 0);
    });

    test('resonanceSiphon has zero damage', () {
      const type = TowerType.resonanceSiphon;
      expect(type.name, 'Resonance Siphon');
      expect(type.damage, 0);
      expect(type.fireRate, 1.0);
      expect(type.range, 100);
      expect(type.cost, 150);
      expect(type.projectileSpeed, 0);
    });

    test('neuralDisruptor has correct stats', () {
      const type = TowerType.neuralDisruptor;
      expect(type.name, 'Neural Disruptor');
      expect(type.damage, 5);
      expect(type.fireRate, 2.0);
      expect(type.range, 130);
      expect(type.cost, 200);
      expect(type.projectileSpeed, 450);
    });
  });

  group('TowerType appliesSlow', () {
    test('phaseMage applies slow', () {
      expect(TowerType.phaseMage.appliesSlow, isTrue);
    });

    test('glimmerField applies slow', () {
      expect(TowerType.glimmerField.appliesSlow, isTrue);
    });

    test('pulseArcher does not apply slow', () {
      expect(TowerType.pulseArcher.appliesSlow, isFalse);
    });

    test('circuitCannon does not apply slow', () {
      expect(TowerType.circuitCannon.appliesSlow, isFalse);
    });

    test('ionSniper does not apply slow', () {
      expect(TowerType.ionSniper.appliesSlow, isFalse);
    });

    test('teslaTerminal does not apply slow', () {
      expect(TowerType.teslaTerminal.appliesSlow, isFalse);
    });

    test('resonanceSiphon does not apply slow', () {
      expect(TowerType.resonanceSiphon.appliesSlow, isFalse);
    });

    test('neuralDisruptor does not apply slow', () {
      expect(TowerType.neuralDisruptor.appliesSlow, isFalse);
    });
  });

  group('TowerType phantom detection', () {
    test('only phaseMage can detect phantoms', () {
      for (final type in TowerType.values) {
        if (type == TowerType.phaseMage) {
          expect(type.canDetectPhantom, isTrue);
        } else {
          expect(type.canDetectPhantom, isFalse);
        }
      }
    });
  });

  group('TowerType cost comparison', () {
    test('pulseArcher is cheapest', () {
      final costs = TowerType.values.map((t) => t.cost).toList();
      expect(TowerType.pulseArcher.cost, costs.reduce((a, b) => a < b ? a : b));
    });

    test('ionSniper is most expensive', () {
      final costs = TowerType.values.map((t) => t.cost).toList();
      expect(TowerType.ionSniper.cost, costs.reduce((a, b) => a > b ? a : b));
    });
  });

  group('TowerType damage comparison', () {
    test('ionSniper has highest damage', () {
      final damages = TowerType.values.map((t) => t.damage).toList();
      expect(TowerType.ionSniper.damage, damages.reduce((a, b) => a > b ? a : b));
    });

    test('resonanceSiphon has lowest damage (zero)', () {
      final damages = TowerType.values.map((t) => t.damage).toList();
      expect(TowerType.resonanceSiphon.damage, damages.reduce((a, b) => a < b ? a : b));
    });
  });

  group('TowerType range comparison', () {
    test('ionSniper has longest range', () {
      final ranges = TowerType.values.map((t) => t.range).toList();
      expect(TowerType.ionSniper.range, ranges.reduce((a, b) => a > b ? a : b));
    });

    test('resonanceSiphon has shortest range', () {
      final ranges = TowerType.values.map((t) => t.range).toList();
      expect(TowerType.resonanceSiphon.range, ranges.reduce((a, b) => a < b ? a : b));
    });
  });

  group('TowerType fire rate comparison', () {
    test('glimmerField has highest fire rate', () {
      final rates = TowerType.values.map((t) => t.fireRate).toList();
      expect(TowerType.glimmerField.fireRate, rates.reduce((a, b) => a > b ? a : b));
    });

    test('ionSniper has lowest fire rate', () {
      final rates = TowerType.values.map((t) => t.fireRate).toList();
      expect(TowerType.ionSniper.fireRate, rates.reduce((a, b) => a < b ? a : b));
    });
  });

  group('TargetMode enum', () {
    test('all target modes exist', () {
      expect(TargetMode.values, contains(TargetMode.first));
      expect(TargetMode.values, contains(TargetMode.last));
      expect(TargetMode.values, contains(TargetMode.strongest));
      expect(TargetMode.values, contains(TargetMode.weakest));
      expect(TargetMode.values, contains(TargetMode.closest));
    });

    test('target mode count is 5', () {
      expect(TargetMode.values.length, 5);
    });
  });
}
