import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/models/upgrade_data.dart';

void main() {
  test('merge multiplies multipliers and adds bonuses', () {
    const base = UpgradeStats(
      towerDamageMult: 1.1,
      towerRangeMult: 1.2,
      startingGoldBonus: 10,
      maxMinesBonus: 1,
    );
    const add = UpgradeStats(
      towerDamageMult: 1.05,
      towerFireRateMult: 1.2,
      startingGoldBonus: 5,
      maxMinesBonus: 2,
    );

    final merged = base.merge(add);
    expect(merged.towerDamageMult, closeTo(1.155, 0.0001));
    expect(merged.towerRangeMult, closeTo(1.2, 0.0001));
    expect(merged.towerFireRateMult, closeTo(1.2, 0.0001));
    expect(merged.startingGoldBonus, 15);
    expect(merged.maxMinesBonus, 3);
  });

  test('scale applies multipliers per level', () {
    const stats = UpgradeStats(
      towerDamageMult: 1.1,
      pulseCooldownMult: 0.9,
      startingGoldBonus: 5,
      maxMinesBonus: 1,
    );

    final scaled = stats.scale(3);
    expect(scaled.towerDamageMult, closeTo(1.331, 0.0001));
    expect(scaled.pulseCooldownMult, closeTo(0.729, 0.0001));
    expect(scaled.startingGoldBonus, 15);
    expect(scaled.maxMinesBonus, 3);
  });
}
