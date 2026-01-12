import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/tower.dart';

void main() {
  test('tower types expose valid numeric stats', () {
    for (final type in TowerType.values) {
      expect(type.name.isNotEmpty, isTrue);
      expect(type.cost, greaterThan(0));
      expect(type.range, greaterThan(0));
      expect(type.fireRate, greaterThan(0));
      expect(type.projectileSpeed, greaterThan(0));
    }
  });

  test('phase mage can detect phantoms', () {
    expect(TowerType.phaseMage.canDetectPhantom, isTrue);
  });
}
