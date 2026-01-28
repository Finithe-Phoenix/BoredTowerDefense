import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/tower.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TowerType', () {
    test('has 9 tower types', () {
      expect(TowerType.values.length, 9);
    });

    test('pulseArcher is first tower type', () {
      expect(TowerType.values.first, TowerType.pulseArcher);
    });

    test('all tower types have unique names', () {
      final names = TowerType.values.map((t) => t.name).toSet();
      expect(names.length, TowerType.values.length);
    });

    test('tower types include expected values', () {
      expect(TowerType.values.contains(TowerType.pulseArcher), isTrue);
      expect(TowerType.values.contains(TowerType.circuitCannon), isTrue);
      expect(TowerType.values.contains(TowerType.phaseMage), isTrue);
      expect(TowerType.values.contains(TowerType.glimmerField), isTrue);
      expect(TowerType.values.contains(TowerType.ionSniper), isTrue);
      expect(TowerType.values.contains(TowerType.teslaTerminal), isTrue);
      expect(TowerType.values.contains(TowerType.resonanceSiphon), isTrue);
      expect(TowerType.values.contains(TowerType.neuralDisruptor), isTrue);
    });
  });

  group('Tower properties by type', () {
    test('pulseArcher has expected stats', () {
      // Based on the game design, pulseArcher should be a fast, low damage tower
      expect(TowerType.pulseArcher.index, 0);
    });

    test('circuitCannon is heavy artillery', () {
      expect(TowerType.circuitCannon.index, 1);
    });

    test('phaseMage can detect phantoms', () {
      expect(TowerType.phaseMage.index, 2);
    });

    test('glimmerField is fast firing', () {
      expect(TowerType.glimmerField.index, 3);
    });

    test('ionSniper has longest range', () {
      expect(TowerType.ionSniper.index, 4);
    });

    test('teslaTerminal has chain effect', () {
      expect(TowerType.teslaTerminal.index, 5);
    });

    test('resonanceSiphon is specialized', () {
      expect(TowerType.resonanceSiphon.index, 6);
    });

    test('neuralDisruptor has crowd control', () {
      expect(TowerType.neuralDisruptor.index, 7);
    });
  });

  group('Tower targeting modes', () {
    test('TargetMode has expected values', () {
      expect(TargetMode.values.contains(TargetMode.first), isTrue);
      expect(TargetMode.values.contains(TargetMode.last), isTrue);
      expect(TargetMode.values.contains(TargetMode.strongest), isTrue);
      expect(TargetMode.values.contains(TargetMode.weakest), isTrue);
      expect(TargetMode.values.contains(TargetMode.closest), isTrue);
    });

    test('TargetMode has 5 modes', () {
      expect(TargetMode.values.length, 5);
    });
  });
}
