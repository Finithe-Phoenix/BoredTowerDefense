import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/models/level_config.dart';

void main() {
  group('LevelConfig', () {
    test('json round trip', () {
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

    test('fromJson with default values', () {
      final json = {
        'id': 1,
        'name': 'Level 1',
        'mapFile': 'maps/level1.tmx',
        'waves': 5,
        'difficulty': 1,
      };
      final config = LevelConfig.fromJson(json);

      expect(config.id, 1);
      expect(config.name, 'Level 1');
      expect(config.startingGold, 200); // default
      expect(config.startingLives, 20); // default
      expect(config.unlockRequirement, isNull);
    });

    test('fromJson with null unlockRequirement', () {
      final json = {
        'id': 1,
        'name': 'First Level',
        'mapFile': 'maps/level1.tmx',
        'waves': 3,
        'difficulty': 1,
        'unlockRequirement': null,
      };
      final config = LevelConfig.fromJson(json);

      expect(config.unlockRequirement, isNull);
    });

    test('toJson includes all fields', () {
      const config = LevelConfig(
        id: 5,
        name: 'Test',
        mapFile: 'maps/test.tmx',
        waves: 10,
        difficulty: 4,
        unlockRequirement: 4,
        startingGold: 250,
        startingLives: 15,
      );

      final json = config.toJson();

      expect(json['id'], 5);
      expect(json['name'], 'Test');
      expect(json['mapFile'], 'maps/test.tmx');
      expect(json['waves'], 10);
      expect(json['difficulty'], 4);
      expect(json['unlockRequirement'], 4);
      expect(json['startingGold'], 250);
      expect(json['startingLives'], 15);
    });

    test('copyWith modifies selected fields', () {
      const original = LevelConfig(
        id: 1,
        name: 'Original',
        mapFile: 'maps/orig.tmx',
        waves: 5,
        difficulty: 2,
      );

      final modified = original.copyWith(
        name: 'Modified',
        waves: 10,
        difficulty: 5,
      );

      expect(modified.id, 1); // unchanged
      expect(modified.name, 'Modified');
      expect(modified.mapFile, 'maps/orig.tmx'); // unchanged
      expect(modified.waves, 10);
      expect(modified.difficulty, 5);
    });

    test('copyWith with no changes returns equal values', () {
      const original = LevelConfig(
        id: 3,
        name: 'Test',
        mapFile: 'maps/test.tmx',
        waves: 7,
        difficulty: 3,
        startingGold: 200,
        startingLives: 20,
      );

      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.mapFile, original.mapFile);
      expect(copy.waves, original.waves);
      expect(copy.difficulty, original.difficulty);
      expect(copy.startingGold, original.startingGold);
      expect(copy.startingLives, original.startingLives);
    });

    test('copyWith can modify all fields', () {
      const original = LevelConfig(
        id: 1,
        name: 'Old',
        mapFile: 'old.tmx',
        waves: 1,
        difficulty: 1,
        unlockRequirement: 0,
        startingGold: 100,
        startingLives: 10,
      );

      final modified = original.copyWith(
        id: 2,
        name: 'New',
        mapFile: 'new.tmx',
        waves: 20,
        difficulty: 5,
        unlockRequirement: 1,
        startingGold: 500,
        startingLives: 50,
      );

      expect(modified.id, 2);
      expect(modified.name, 'New');
      expect(modified.mapFile, 'new.tmx');
      expect(modified.waves, 20);
      expect(modified.difficulty, 5);
      expect(modified.unlockRequirement, 1);
      expect(modified.startingGold, 500);
      expect(modified.startingLives, 50);
    });

    test('default values are applied', () {
      const config = LevelConfig(
        id: 1,
        name: 'Test',
        mapFile: 'test.tmx',
        waves: 5,
        difficulty: 1,
      );

      expect(config.startingGold, 200);
      expect(config.startingLives, 20);
      expect(config.unlockRequirement, isNull);
    });
  });

  group('LevelProgress', () {
    test('json and copyWith', () {
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

    test('copyWith keeps defaults', () {
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

    test('fromJson with default values', () {
      final json = {'levelId': 1};
      final progress = LevelProgress.fromJson(json);

      expect(progress.levelId, 1);
      expect(progress.completed, false); // default
      expect(progress.stars, 0); // default
      expect(progress.highScore, 0); // default
      expect(progress.bestWave, 0); // default
    });

    test('fromJson with partial values', () {
      final json = {
        'levelId': 5,
        'completed': true,
        'stars': 3,
      };
      final progress = LevelProgress.fromJson(json);

      expect(progress.levelId, 5);
      expect(progress.completed, true);
      expect(progress.stars, 3);
      expect(progress.highScore, 0); // default
      expect(progress.bestWave, 0); // default
    });

    test('toJson includes all fields', () {
      const progress = LevelProgress(
        levelId: 10,
        completed: true,
        stars: 3,
        highScore: 5000,
        bestWave: 15,
      );

      final json = progress.toJson();

      expect(json['levelId'], 10);
      expect(json['completed'], true);
      expect(json['stars'], 3);
      expect(json['highScore'], 5000);
      expect(json['bestWave'], 15);
    });

    test('copyWith can modify all fields', () {
      const original = LevelProgress(
        levelId: 1,
        completed: false,
        stars: 0,
        highScore: 0,
        bestWave: 0,
      );

      final modified = original.copyWith(
        completed: true,
        stars: 3,
        highScore: 10000,
        bestWave: 20,
      );

      expect(modified.levelId, 1); // levelId cannot be changed
      expect(modified.completed, true);
      expect(modified.stars, 3);
      expect(modified.highScore, 10000);
      expect(modified.bestWave, 20);
    });

    test('default constructor values', () {
      const progress = LevelProgress(levelId: 1);

      expect(progress.levelId, 1);
      expect(progress.completed, false);
      expect(progress.stars, 0);
      expect(progress.highScore, 0);
      expect(progress.bestWave, 0);
    });

    test('stars range 0-3', () {
      const progress0 = LevelProgress(levelId: 1, stars: 0);
      const progress1 = LevelProgress(levelId: 1, stars: 1);
      const progress2 = LevelProgress(levelId: 1, stars: 2);
      const progress3 = LevelProgress(levelId: 1, stars: 3);

      expect(progress0.stars, 0);
      expect(progress1.stars, 1);
      expect(progress2.stars, 2);
      expect(progress3.stars, 3);
    });
  });
}
