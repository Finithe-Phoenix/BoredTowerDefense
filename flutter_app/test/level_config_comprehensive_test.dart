import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/models/level_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LevelConfig - Constructor', () {
    test('stores id', () {
      const config = LevelConfig(
        id: 1,
        name: 'Test',
        mapFile: 'map1.json',
        waves: 10,
        difficulty: 1,
      );
      expect(config.id, 1);
    });

    test('stores name', () {
      const config = LevelConfig(
        id: 1,
        name: 'Test Level',
        mapFile: 'map1.json',
        waves: 10,
        difficulty: 1,
      );
      expect(config.name, 'Test Level');
    });

    test('stores mapFile', () {
      const config = LevelConfig(
        id: 1,
        name: 'Test',
        mapFile: 'levels/world1/map1.json',
        waves: 10,
        difficulty: 1,
      );
      expect(config.mapFile, 'levels/world1/map1.json');
    });

    test('stores waves', () {
      const config = LevelConfig(
        id: 1,
        name: 'Test',
        mapFile: 'map1.json',
        waves: 15,
        difficulty: 1,
      );
      expect(config.waves, 15);
    });

    test('stores difficulty', () {
      const config = LevelConfig(
        id: 1,
        name: 'Test',
        mapFile: 'map1.json',
        waves: 10,
        difficulty: 3,
      );
      expect(config.difficulty, 3);
    });

    test('unlockRequirement defaults to null', () {
      const config = LevelConfig(
        id: 1,
        name: 'Test',
        mapFile: 'map1.json',
        waves: 10,
        difficulty: 1,
      );
      expect(config.unlockRequirement, isNull);
    });

    test('stores unlockRequirement', () {
      const config = LevelConfig(
        id: 2,
        name: 'Test',
        mapFile: 'map2.json',
        waves: 10,
        difficulty: 1,
        unlockRequirement: 1,
      );
      expect(config.unlockRequirement, 1);
    });

    test('startingGold defaults to 200', () {
      const config = LevelConfig(
        id: 1,
        name: 'Test',
        mapFile: 'map1.json',
        waves: 10,
        difficulty: 1,
      );
      expect(config.startingGold, 200);
    });

    test('stores custom startingGold', () {
      const config = LevelConfig(
        id: 1,
        name: 'Test',
        mapFile: 'map1.json',
        waves: 10,
        difficulty: 1,
        startingGold: 300,
      );
      expect(config.startingGold, 300);
    });

    test('startingLives defaults to 20', () {
      const config = LevelConfig(
        id: 1,
        name: 'Test',
        mapFile: 'map1.json',
        waves: 10,
        difficulty: 1,
      );
      expect(config.startingLives, 20);
    });

    test('stores custom startingLives', () {
      const config = LevelConfig(
        id: 1,
        name: 'Test',
        mapFile: 'map1.json',
        waves: 10,
        difficulty: 1,
        startingLives: 25,
      );
      expect(config.startingLives, 25);
    });
  });

  group('LevelConfig - fromJson', () {
    test('parses required fields', () {
      final json = {
        'id': 1,
        'name': 'Level 1',
        'mapFile': 'map1.json',
        'waves': 10,
        'difficulty': 2,
      };

      final config = LevelConfig.fromJson(json);

      expect(config.id, 1);
      expect(config.name, 'Level 1');
      expect(config.mapFile, 'map1.json');
      expect(config.waves, 10);
      expect(config.difficulty, 2);
    });

    test('parses optional unlockRequirement', () {
      final json = {
        'id': 2,
        'name': 'Level 2',
        'mapFile': 'map2.json',
        'waves': 10,
        'difficulty': 2,
        'unlockRequirement': 1,
      };

      final config = LevelConfig.fromJson(json);
      expect(config.unlockRequirement, 1);
    });

    test('parses null unlockRequirement', () {
      final json = {
        'id': 1,
        'name': 'Level 1',
        'mapFile': 'map1.json',
        'waves': 10,
        'difficulty': 1,
        'unlockRequirement': null,
      };

      final config = LevelConfig.fromJson(json);
      expect(config.unlockRequirement, isNull);
    });

    test('parses optional startingGold', () {
      final json = {
        'id': 1,
        'name': 'Test',
        'mapFile': 'map1.json',
        'waves': 10,
        'difficulty': 1,
        'startingGold': 350,
      };

      final config = LevelConfig.fromJson(json);
      expect(config.startingGold, 350);
    });

    test('defaults startingGold to 200 when missing', () {
      final json = {
        'id': 1,
        'name': 'Test',
        'mapFile': 'map1.json',
        'waves': 10,
        'difficulty': 1,
      };

      final config = LevelConfig.fromJson(json);
      expect(config.startingGold, 200);
    });

    test('parses optional startingLives', () {
      final json = {
        'id': 1,
        'name': 'Test',
        'mapFile': 'map1.json',
        'waves': 10,
        'difficulty': 1,
        'startingLives': 30,
      };

      final config = LevelConfig.fromJson(json);
      expect(config.startingLives, 30);
    });

    test('defaults startingLives to 20 when missing', () {
      final json = {
        'id': 1,
        'name': 'Test',
        'mapFile': 'map1.json',
        'waves': 10,
        'difficulty': 1,
      };

      final config = LevelConfig.fromJson(json);
      expect(config.startingLives, 20);
    });

    test('parses all fields', () {
      final json = {
        'id': 42,
        'name': 'Challenge Mode',
        'mapFile': 'levels/challenge/map42.json',
        'waves': 20,
        'difficulty': 5,
        'unlockRequirement': 41,
        'startingGold': 150,
        'startingLives': 10,
      };

      final config = LevelConfig.fromJson(json);

      expect(config.id, 42);
      expect(config.name, 'Challenge Mode');
      expect(config.mapFile, 'levels/challenge/map42.json');
      expect(config.waves, 20);
      expect(config.difficulty, 5);
      expect(config.unlockRequirement, 41);
      expect(config.startingGold, 150);
      expect(config.startingLives, 10);
    });
  });

  group('LevelConfig - toJson', () {
    test('serializes all fields', () {
      const config = LevelConfig(
        id: 1,
        name: 'Test',
        mapFile: 'map1.json',
        waves: 10,
        difficulty: 2,
        unlockRequirement: null,
        startingGold: 200,
        startingLives: 20,
      );

      final json = config.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Test');
      expect(json['mapFile'], 'map1.json');
      expect(json['waves'], 10);
      expect(json['difficulty'], 2);
      expect(json['unlockRequirement'], isNull);
      expect(json['startingGold'], 200);
      expect(json['startingLives'], 20);
    });

    test('serializes with unlockRequirement', () {
      const config = LevelConfig(
        id: 2,
        name: 'Level 2',
        mapFile: 'map2.json',
        waves: 10,
        difficulty: 2,
        unlockRequirement: 1,
      );

      final json = config.toJson();
      expect(json['unlockRequirement'], 1);
    });

    test('round-trip serialization', () {
      const original = LevelConfig(
        id: 5,
        name: 'Round Trip',
        mapFile: 'rt.json',
        waves: 15,
        difficulty: 3,
        unlockRequirement: 4,
        startingGold: 250,
        startingLives: 25,
      );

      final json = original.toJson();
      final restored = LevelConfig.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.mapFile, original.mapFile);
      expect(restored.waves, original.waves);
      expect(restored.difficulty, original.difficulty);
      expect(restored.unlockRequirement, original.unlockRequirement);
      expect(restored.startingGold, original.startingGold);
      expect(restored.startingLives, original.startingLives);
    });
  });

  group('LevelConfig - copyWith', () {
    const base = LevelConfig(
      id: 1,
      name: 'Base',
      mapFile: 'base.json',
      waves: 10,
      difficulty: 2,
      startingGold: 200,
      startingLives: 20,
    );

    test('copyWith no changes', () {
      final copy = base.copyWith();
      expect(copy.id, base.id);
      expect(copy.name, base.name);
      expect(copy.mapFile, base.mapFile);
    });

    test('copyWith id', () {
      final copy = base.copyWith(id: 99);
      expect(copy.id, 99);
      expect(copy.name, base.name);
    });

    test('copyWith name', () {
      final copy = base.copyWith(name: 'New Name');
      expect(copy.name, 'New Name');
      expect(copy.id, base.id);
    });

    test('copyWith mapFile', () {
      final copy = base.copyWith(mapFile: 'new.json');
      expect(copy.mapFile, 'new.json');
    });

    test('copyWith waves', () {
      final copy = base.copyWith(waves: 25);
      expect(copy.waves, 25);
    });

    test('copyWith difficulty', () {
      final copy = base.copyWith(difficulty: 5);
      expect(copy.difficulty, 5);
    });

    test('copyWith unlockRequirement', () {
      final copy = base.copyWith(unlockRequirement: 10);
      expect(copy.unlockRequirement, 10);
    });

    test('copyWith startingGold', () {
      final copy = base.copyWith(startingGold: 500);
      expect(copy.startingGold, 500);
    });

    test('copyWith startingLives', () {
      final copy = base.copyWith(startingLives: 30);
      expect(copy.startingLives, 30);
    });

    test('copyWith multiple fields', () {
      final copy = base.copyWith(
        name: 'Modified',
        waves: 20,
        difficulty: 4,
        startingGold: 300,
      );

      expect(copy.id, base.id);
      expect(copy.name, 'Modified');
      expect(copy.waves, 20);
      expect(copy.difficulty, 4);
      expect(copy.startingGold, 300);
      expect(copy.startingLives, base.startingLives);
    });
  });

  group('LevelConfig - Difficulty values', () {
    for (int diff = 1; diff <= 5; diff++) {
      test('difficulty $diff is valid', () {
        final config = LevelConfig(
          id: diff,
          name: 'Diff $diff',
          mapFile: 'map.json',
          waves: 10,
          difficulty: diff,
        );
        expect(config.difficulty, diff);
      });
    }
  });

  group('LevelConfig - Wave counts', () {
    test('minimum waves', () {
      const config = LevelConfig(
        id: 1,
        name: 'Short',
        mapFile: 'map.json',
        waves: 1,
        difficulty: 1,
      );
      expect(config.waves, 1);
    });

    test('standard waves', () {
      const config = LevelConfig(
        id: 1,
        name: 'Standard',
        mapFile: 'map.json',
        waves: 10,
        difficulty: 2,
      );
      expect(config.waves, 10);
    });

    test('long waves', () {
      const config = LevelConfig(
        id: 1,
        name: 'Long',
        mapFile: 'map.json',
        waves: 50,
        difficulty: 5,
      );
      expect(config.waves, 50);
    });
  });

  group('LevelProgress - Constructor', () {
    test('stores levelId', () {
      const progress = LevelProgress(levelId: 1);
      expect(progress.levelId, 1);
    });

    test('completed defaults to false', () {
      const progress = LevelProgress(levelId: 1);
      expect(progress.completed, isFalse);
    });

    test('stores completed', () {
      const progress = LevelProgress(levelId: 1, completed: true);
      expect(progress.completed, isTrue);
    });

    test('stars defaults to 0', () {
      const progress = LevelProgress(levelId: 1);
      expect(progress.stars, 0);
    });

    test('stores stars', () {
      const progress = LevelProgress(levelId: 1, stars: 3);
      expect(progress.stars, 3);
    });

    test('highScore defaults to 0', () {
      const progress = LevelProgress(levelId: 1);
      expect(progress.highScore, 0);
    });

    test('stores highScore', () {
      const progress = LevelProgress(levelId: 1, highScore: 5000);
      expect(progress.highScore, 5000);
    });

    test('bestWave defaults to 0', () {
      const progress = LevelProgress(levelId: 1);
      expect(progress.bestWave, 0);
    });

    test('stores bestWave', () {
      const progress = LevelProgress(levelId: 1, bestWave: 10);
      expect(progress.bestWave, 10);
    });

    test('all custom values', () {
      const progress = LevelProgress(
        levelId: 42,
        completed: true,
        stars: 3,
        highScore: 10000,
        bestWave: 15,
      );

      expect(progress.levelId, 42);
      expect(progress.completed, isTrue);
      expect(progress.stars, 3);
      expect(progress.highScore, 10000);
      expect(progress.bestWave, 15);
    });
  });

  group('LevelProgress - fromJson', () {
    test('parses required levelId', () {
      final json = {'levelId': 1};
      final progress = LevelProgress.fromJson(json);
      expect(progress.levelId, 1);
    });

    test('parses completed', () {
      final json = {'levelId': 1, 'completed': true};
      final progress = LevelProgress.fromJson(json);
      expect(progress.completed, isTrue);
    });

    test('defaults completed to false', () {
      final json = {'levelId': 1};
      final progress = LevelProgress.fromJson(json);
      expect(progress.completed, isFalse);
    });

    test('parses stars', () {
      final json = {'levelId': 1, 'stars': 2};
      final progress = LevelProgress.fromJson(json);
      expect(progress.stars, 2);
    });

    test('defaults stars to 0', () {
      final json = {'levelId': 1};
      final progress = LevelProgress.fromJson(json);
      expect(progress.stars, 0);
    });

    test('parses highScore', () {
      final json = {'levelId': 1, 'highScore': 7500};
      final progress = LevelProgress.fromJson(json);
      expect(progress.highScore, 7500);
    });

    test('defaults highScore to 0', () {
      final json = {'levelId': 1};
      final progress = LevelProgress.fromJson(json);
      expect(progress.highScore, 0);
    });

    test('parses bestWave', () {
      final json = {'levelId': 1, 'bestWave': 8};
      final progress = LevelProgress.fromJson(json);
      expect(progress.bestWave, 8);
    });

    test('defaults bestWave to 0', () {
      final json = {'levelId': 1};
      final progress = LevelProgress.fromJson(json);
      expect(progress.bestWave, 0);
    });

    test('parses all fields', () {
      final json = {
        'levelId': 5,
        'completed': true,
        'stars': 3,
        'highScore': 15000,
        'bestWave': 20,
      };

      final progress = LevelProgress.fromJson(json);

      expect(progress.levelId, 5);
      expect(progress.completed, isTrue);
      expect(progress.stars, 3);
      expect(progress.highScore, 15000);
      expect(progress.bestWave, 20);
    });
  });

  group('LevelProgress - toJson', () {
    test('serializes all fields', () {
      const progress = LevelProgress(
        levelId: 1,
        completed: true,
        stars: 2,
        highScore: 5000,
        bestWave: 10,
      );

      final json = progress.toJson();

      expect(json['levelId'], 1);
      expect(json['completed'], isTrue);
      expect(json['stars'], 2);
      expect(json['highScore'], 5000);
      expect(json['bestWave'], 10);
    });

    test('serializes default values', () {
      const progress = LevelProgress(levelId: 1);

      final json = progress.toJson();

      expect(json['completed'], isFalse);
      expect(json['stars'], 0);
      expect(json['highScore'], 0);
      expect(json['bestWave'], 0);
    });

    test('round-trip serialization', () {
      const original = LevelProgress(
        levelId: 42,
        completed: true,
        stars: 3,
        highScore: 99999,
        bestWave: 25,
      );

      final json = original.toJson();
      final restored = LevelProgress.fromJson(json);

      expect(restored.levelId, original.levelId);
      expect(restored.completed, original.completed);
      expect(restored.stars, original.stars);
      expect(restored.highScore, original.highScore);
      expect(restored.bestWave, original.bestWave);
    });
  });

  group('LevelProgress - copyWith', () {
    const base = LevelProgress(
      levelId: 1,
      completed: false,
      stars: 0,
      highScore: 0,
      bestWave: 0,
    );

    test('copyWith no changes', () {
      final copy = base.copyWith();
      expect(copy.levelId, base.levelId);
      expect(copy.completed, base.completed);
    });

    test('copyWith completed', () {
      final copy = base.copyWith(completed: true);
      expect(copy.completed, isTrue);
      expect(copy.levelId, base.levelId);
    });

    test('copyWith stars', () {
      final copy = base.copyWith(stars: 3);
      expect(copy.stars, 3);
    });

    test('copyWith highScore', () {
      final copy = base.copyWith(highScore: 10000);
      expect(copy.highScore, 10000);
    });

    test('copyWith bestWave', () {
      final copy = base.copyWith(bestWave: 15);
      expect(copy.bestWave, 15);
    });

    test('copyWith multiple fields', () {
      final copy = base.copyWith(
        completed: true,
        stars: 2,
        highScore: 5000,
        bestWave: 10,
      );

      expect(copy.levelId, base.levelId);
      expect(copy.completed, isTrue);
      expect(copy.stars, 2);
      expect(copy.highScore, 5000);
      expect(copy.bestWave, 10);
    });

    test('levelId cannot be changed via copyWith', () {
      final copy = base.copyWith(stars: 1);
      expect(copy.levelId, base.levelId);
    });
  });

  group('LevelProgress - Stars range', () {
    for (int stars = 0; stars <= 3; stars++) {
      test('$stars stars is valid', () {
        final progress = LevelProgress(levelId: 1, stars: stars);
        expect(progress.stars, stars);
      });
    }
  });

  group('LevelProgress - Update scenarios', () {
    test('first completion', () {
      const initial = LevelProgress(levelId: 1);
      final completed = initial.copyWith(
        completed: true,
        stars: 2,
        highScore: 3000,
        bestWave: 10,
      );

      expect(completed.completed, isTrue);
      expect(completed.stars, 2);
      expect(completed.highScore, 3000);
      expect(completed.bestWave, 10);
    });

    test('improve stars', () {
      const previous = LevelProgress(
        levelId: 1,
        completed: true,
        stars: 1,
        highScore: 2000,
        bestWave: 10,
      );

      final improved = previous.copyWith(stars: 3, highScore: 5000);

      expect(improved.stars, 3);
      expect(improved.highScore, 5000);
    });

    test('partial progress (no completion)', () {
      const initial = LevelProgress(levelId: 1);
      final partial = initial.copyWith(bestWave: 5, highScore: 1500);

      expect(partial.completed, isFalse);
      expect(partial.bestWave, 5);
      expect(partial.highScore, 1500);
    });
  });

  group('LevelConfig + LevelProgress integration', () {
    test('new level starts with empty progress', () {
      const config = LevelConfig(
        id: 1,
        name: 'Level 1',
        mapFile: 'map1.json',
        waves: 10,
        difficulty: 2,
      );

      const progress = LevelProgress(levelId: 1);

      expect(progress.levelId, config.id);
      expect(progress.completed, isFalse);
      expect(progress.bestWave, lessThan(config.waves));
    });

    test('completed level matches config waves', () {
      const config = LevelConfig(
        id: 1,
        name: 'Level 1',
        mapFile: 'map1.json',
        waves: 10,
        difficulty: 2,
      );

      const progress = LevelProgress(
        levelId: 1,
        completed: true,
        bestWave: 10,
      );

      expect(progress.bestWave, config.waves);
    });

    test('unlock requirement chain', () {
      const level1 = LevelConfig(
        id: 1,
        name: 'Level 1',
        mapFile: 'map1.json',
        waves: 10,
        difficulty: 1,
      );

      const level2 = LevelConfig(
        id: 2,
        name: 'Level 2',
        mapFile: 'map2.json',
        waves: 10,
        difficulty: 2,
        unlockRequirement: 1,
      );

      const level3 = LevelConfig(
        id: 3,
        name: 'Level 3',
        mapFile: 'map3.json',
        waves: 10,
        difficulty: 3,
        unlockRequirement: 2,
      );

      expect(level1.unlockRequirement, isNull);
      expect(level2.unlockRequirement, level1.id);
      expect(level3.unlockRequirement, level2.id);
    });
  });
}
