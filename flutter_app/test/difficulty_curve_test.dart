import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/balance/difficulty_curve.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('level mapping produces consistent world/local/progress', () {
    expect(DifficultyCurve.worldForLevel(1), 1);
    expect(DifficultyCurve.localIndexForLevel(1), 1);
    expect(DifficultyCurve.progressIndex(levelId: 1), 0);

    expect(DifficultyCurve.worldForLevel(10), 1);
    expect(DifficultyCurve.localIndexForLevel(10), 10);
    expect(DifficultyCurve.progressIndex(levelId: 10), 9);

    expect(DifficultyCurve.worldForLevel(11), 2);
    expect(DifficultyCurve.localIndexForLevel(11), 1);
    expect(DifficultyCurve.progressIndex(levelId: 11), 10);
  });

  test('difficulty scale is linear in difficulty', () {
    expect(DifficultyCurve.difficultyScale(1), 1.0);
    expect(DifficultyCurve.difficultyScale(3), closeTo(1.16, 0.0001));
  });

  test('health and speed multipliers increase with wave/difficulty', () {
    final baseHealth = DifficultyCurve.healthMultiplier(
      progressIndexValue: 5,
      wave: 1,
      difficulty: 1,
    );
    final boostedHealth = DifficultyCurve.healthMultiplier(
      progressIndexValue: 5,
      wave: 4,
      difficulty: 3,
    );
    expect(boostedHealth, greaterThan(baseHealth));

    final baseSpeed = DifficultyCurve.speedMultiplier(
      progressIndexValue: 5,
      wave: 1,
      difficulty: 1,
    );
    final boostedSpeed = DifficultyCurve.speedMultiplier(
      progressIndexValue: 5,
      wave: 4,
      difficulty: 3,
    );
    expect(boostedSpeed, greaterThan(baseSpeed));
  });

  test('spawn interval clamps to min and max', () {
    final minClamped = DifficultyCurve.spawnInterval(
      progressIndexValue: 200,
      wave: 20,
      difficulty: 5,
    );
    expect(minClamped, closeTo(0.35, 0.0001));

    final maxClamped = DifficultyCurve.spawnInterval(
      progressIndexValue: 0,
      wave: 1,
      difficulty: 1,
      maxInterval: 0.9,
    );
    expect(maxClamped, closeTo(0.9, 0.0001));
  });

  test('enemy count and bonuses clamp and scale', () {
    final maxCount = DifficultyCurve.enemyCount(
      baseCount: 100,
      progressIndexValue: 1000,
      wave: 50,
      difficulty: 5,
      minCount: 3,
      maxCount: 80,
    );
    expect(maxCount, 80);

    final minCount = DifficultyCurve.enemyCount(
      baseCount: 1,
      progressIndexValue: 0,
      wave: 1,
      difficulty: 1,
      minCount: 3,
      maxCount: 80,
    );
    expect(minCount, 3);

    final noExtra = DifficultyCurve.towerCostMultiplier(
      2,
      graceCount: 2,
      step: 0.1,
    );
    expect(noExtra, 1.0);

    final extra = DifficultyCurve.towerCostMultiplier(
      5,
      graceCount: 2,
      step: 0.1,
    );
    expect(extra, closeTo(1.3, 0.0001));

    final minBonus = DifficultyCurve.waveClearBonus(
      progressIndexValue: 500,
      wave: 1,
      difficulty: 5,
      minBonus: 25,
      maxBonus: 40,
    );
    expect(minBonus, 25);

    final maxBonus = DifficultyCurve.waveClearBonus(
      progressIndexValue: 0,
      wave: 20,
      difficulty: 1,
      minBonus: 6,
      maxBonus: 30,
    );
    expect(maxBonus, 30);
  });
}
