import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/models/level_config.dart';

void main() {
  test('LevelConfig json round trip', () {
    const config = LevelConfig(
      id: 7,
      name: 'Test Lane',
      mapFile: 'maps/level7.tmx',
      waves: 9,
      difficulty: 3,
      unlockRequirement: 6,
      startingGold: 180,
      startingLives: 12,
    );

    final json = config.toJson();
    final parsed = LevelConfig.fromJson(json);

    expect(parsed.id, 7);
    expect(parsed.name, 'Test Lane');
    expect(parsed.mapFile, 'maps/level7.tmx');
    expect(parsed.waves, 9);
    expect(parsed.difficulty, 3);
    expect(parsed.unlockRequirement, 6);
    expect(parsed.startingGold, 180);
    expect(parsed.startingLives, 12);
  });

  test('LevelProgress json and copyWith', () {
    const progress = LevelProgress(
      levelId: 3,
      completed: false,
      stars: 1,
      highScore: 1200,
      bestWave: 4,
    );

    final json = progress.toJson();
    final parsed = LevelProgress.fromJson(json);
    expect(parsed.levelId, 3);
    expect(parsed.stars, 1);
    expect(parsed.bestWave, 4);

    final updated = progress.copyWith(
      completed: true,
      stars: 2,
      highScore: 1500,
    );
    expect(updated.completed, isTrue);
    expect(updated.stars, 2);
    expect(updated.highScore, 1500);
    expect(updated.bestWave, 4);
  });

  test('LevelProgress copyWith keeps defaults', () {
    const progress = LevelProgress(
      levelId: 9,
      completed: true,
      stars: 2,
      highScore: 800,
      bestWave: 6,
    );

    final same = progress.copyWith();
    expect(same.completed, isTrue);
    expect(same.stars, 2);
    expect(same.highScore, 800);
    expect(same.bestWave, 6);
  });
}
