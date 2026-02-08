// Simulation tests for LevelConfig and LevelProgress
// Tests JSON serialization, copyWith, and validation logic
// No Flutter/Flame dependencies - pure Dart logic testing

import 'package:test/test.dart';

/// Simulated LevelConfig matching the original implementation
class SimulatedLevelConfig {
  const SimulatedLevelConfig({
    required this.id,
    required this.name,
    required this.mapFile,
    required this.waves,
    required this.difficulty,
    this.unlockRequirement,
    this.startingGold = 200,
    this.startingLives = 20,
  });

  final int id;
  final String name;
  final String mapFile;
  final int waves;
  final int difficulty; // 1-5 stars
  final int? unlockRequirement; // Level ID required to unlock, null = always unlocked
  final int startingGold;
  final int startingLives;

  /// Create from JSON map
  factory SimulatedLevelConfig.fromJson(Map<String, dynamic> json) {
    return SimulatedLevelConfig(
      id: json['id'] as int,
      name: json['name'] as String,
      mapFile: json['mapFile'] as String,
      waves: json['waves'] as int,
      difficulty: json['difficulty'] as int,
      unlockRequirement: json['unlockRequirement'] as int?,
      startingGold: json['startingGold'] as int? ?? 200,
      startingLives: json['startingLives'] as int? ?? 20,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mapFile': mapFile,
        'waves': waves,
        'difficulty': difficulty,
        'unlockRequirement': unlockRequirement,
        'startingGold': startingGold,
        'startingLives': startingLives,
      };

  /// Create a copy with modified values
  SimulatedLevelConfig copyWith({
    int? id,
    String? name,
    String? mapFile,
    int? waves,
    int? difficulty,
    int? unlockRequirement,
    int? startingGold,
    int? startingLives,
  }) {
    return SimulatedLevelConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      mapFile: mapFile ?? this.mapFile,
      waves: waves ?? this.waves,
      difficulty: difficulty ?? this.difficulty,
      unlockRequirement: unlockRequirement ?? this.unlockRequirement,
      startingGold: startingGold ?? this.startingGold,
      startingLives: startingLives ?? this.startingLives,
    );
  }
}

/// Simulated LevelProgress matching the original implementation
class SimulatedLevelProgress {
  const SimulatedLevelProgress({
    required this.levelId,
    this.completed = false,
    this.stars = 0,
    this.highScore = 0,
    this.bestWave = 0,
  });

  final int levelId;
  final bool completed;
  final int stars; // 0-3
  final int highScore;
  final int bestWave;

  factory SimulatedLevelProgress.fromJson(Map<String, dynamic> json) {
    return SimulatedLevelProgress(
      levelId: json['levelId'] as int,
      completed: json['completed'] as bool? ?? false,
      stars: json['stars'] as int? ?? 0,
      highScore: json['highScore'] as int? ?? 0,
      bestWave: json['bestWave'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'completed': completed,
        'stars': stars,
        'highScore': highScore,
        'bestWave': bestWave,
      };

  SimulatedLevelProgress copyWith({
    bool? completed,
    int? stars,
    int? highScore,
    int? bestWave,
  }) {
    return SimulatedLevelProgress(
      levelId: levelId,
      completed: completed ?? this.completed,
      stars: stars ?? this.stars,
      highScore: highScore ?? this.highScore,
      bestWave: bestWave ?? this.bestWave,
    );
  }
}

/// Helper class to simulate level progression system
class SimulatedLevelManager {
  final List<SimulatedLevelConfig> levels;
  final Map<int, SimulatedLevelProgress> progress = {};

  SimulatedLevelManager(this.levels);

  /// Check if a level is unlocked based on requirements
  bool isLevelUnlocked(int levelId) {
    final config = levels.firstWhere(
      (l) => l.id == levelId,
      orElse: () => throw Exception('Level not found: $levelId'),
    );

    // No unlock requirement means always unlocked
    if (config.unlockRequirement == null) {
      return true;
    }

    // Check if required level is completed
    final requiredProgress = progress[config.unlockRequirement];
    return requiredProgress?.completed ?? false;
  }

  /// Get available levels (unlocked ones)
  List<SimulatedLevelConfig> getAvailableLevels() {
    return levels.where((l) => isLevelUnlocked(l.id)).toList();
  }

  /// Complete a level with score
  void completeLevel(int levelId, int score, int wave, int livesRemaining) {
    final config = levels.firstWhere((l) => l.id == levelId);
    final existingProgress = progress[levelId];

    // Calculate stars based on lives remaining percentage
    final livesPercentage = livesRemaining / config.startingLives;
    int stars;
    if (livesPercentage >= 0.8) {
      stars = 3;
    } else if (livesPercentage >= 0.5) {
      stars = 2;
    } else if (livesPercentage > 0) {
      stars = 1;
    } else {
      stars = 0;
    }

    progress[levelId] = SimulatedLevelProgress(
      levelId: levelId,
      completed: true,
      stars: (existingProgress?.stars ?? 0) > stars
          ? existingProgress!.stars
          : stars,
      highScore: (existingProgress?.highScore ?? 0) > score
          ? existingProgress!.highScore
          : score,
      bestWave: (existingProgress?.bestWave ?? 0) > wave
          ? existingProgress!.bestWave
          : wave,
    );
  }

  /// Get total stars earned
  int getTotalStars() {
    return progress.values.fold(0, (sum, p) => sum + p.stars);
  }
}

void main() {
  group('LevelConfig JSON Serialization', () {
    test('should serialize all fields to JSON', () {
      const config = SimulatedLevelConfig(
        id: 1,
        name: 'First Battle',
        mapFile: 'level1.json',
        waves: 10,
        difficulty: 2,
        unlockRequirement: null,
        startingGold: 250,
        startingLives: 15,
      );

      final json = config.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'First Battle');
      expect(json['mapFile'], 'level1.json');
      expect(json['waves'], 10);
      expect(json['difficulty'], 2);
      expect(json['unlockRequirement'], null);
      expect(json['startingGold'], 250);
      expect(json['startingLives'], 15);
    });

    test('should deserialize all fields from JSON', () {
      final json = {
        'id': 5,
        'name': 'Boss Level',
        'mapFile': 'boss.json',
        'waves': 25,
        'difficulty': 5,
        'unlockRequirement': 4,
        'startingGold': 500,
        'startingLives': 30,
      };

      final config = SimulatedLevelConfig.fromJson(json);

      expect(config.id, 5);
      expect(config.name, 'Boss Level');
      expect(config.mapFile, 'boss.json');
      expect(config.waves, 25);
      expect(config.difficulty, 5);
      expect(config.unlockRequirement, 4);
      expect(config.startingGold, 500);
      expect(config.startingLives, 30);
    });

    test('should use default values when optional fields are missing', () {
      final json = {
        'id': 1,
        'name': 'Tutorial',
        'mapFile': 'tutorial.json',
        'waves': 5,
        'difficulty': 1,
      };

      final config = SimulatedLevelConfig.fromJson(json);

      expect(config.startingGold, 200); // default
      expect(config.startingLives, 20); // default
      expect(config.unlockRequirement, null); // no requirement
    });

    test('should round-trip serialize correctly', () {
      const original = SimulatedLevelConfig(
        id: 7,
        name: 'Endgame',
        mapFile: 'endgame.json',
        waves: 50,
        difficulty: 5,
        unlockRequirement: 6,
        startingGold: 1000,
        startingLives: 5,
      );

      final json = original.toJson();
      final restored = SimulatedLevelConfig.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.mapFile, original.mapFile);
      expect(restored.waves, original.waves);
      expect(restored.difficulty, original.difficulty);
      expect(restored.unlockRequirement, original.unlockRequirement);
      expect(restored.startingGold, original.startingGold);
      expect(restored.startingLives, original.startingLives);
    });

    test('should handle null unlockRequirement in JSON', () {
      final json = {
        'id': 1,
        'name': 'First Level',
        'mapFile': 'first.json',
        'waves': 10,
        'difficulty': 1,
        'unlockRequirement': null,
        'startingGold': 200,
        'startingLives': 20,
      };

      final config = SimulatedLevelConfig.fromJson(json);
      expect(config.unlockRequirement, null);
    });

    test('should preserve explicit unlockRequirement in serialization', () {
      const config = SimulatedLevelConfig(
        id: 3,
        name: 'Level 3',
        mapFile: 'level3.json',
        waves: 15,
        difficulty: 3,
        unlockRequirement: 2,
      );

      final json = config.toJson();
      expect(json['unlockRequirement'], 2);
    });
  });

  group('LevelConfig copyWith', () {
    test('should copy all fields when no parameters given', () {
      const original = SimulatedLevelConfig(
        id: 1,
        name: 'Original',
        mapFile: 'original.json',
        waves: 10,
        difficulty: 3,
        unlockRequirement: null,
        startingGold: 300,
        startingLives: 25,
      );

      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.mapFile, original.mapFile);
      expect(copy.waves, original.waves);
      expect(copy.difficulty, original.difficulty);
      expect(copy.unlockRequirement, original.unlockRequirement);
      expect(copy.startingGold, original.startingGold);
      expect(copy.startingLives, original.startingLives);
    });

    test('should update only specified fields', () {
      const original = SimulatedLevelConfig(
        id: 1,
        name: 'Original',
        mapFile: 'original.json',
        waves: 10,
        difficulty: 3,
      );

      final modified = original.copyWith(
        name: 'Modified',
        waves: 20,
      );

      expect(modified.id, 1); // unchanged
      expect(modified.name, 'Modified'); // changed
      expect(modified.mapFile, 'original.json'); // unchanged
      expect(modified.waves, 20); // changed
      expect(modified.difficulty, 3); // unchanged
    });

    test('should update all fields individually', () {
      const original = SimulatedLevelConfig(
        id: 1,
        name: 'Original',
        mapFile: 'original.json',
        waves: 10,
        difficulty: 3,
      );

      expect(original.copyWith(id: 99).id, 99);
      expect(original.copyWith(name: 'New Name').name, 'New Name');
      expect(original.copyWith(mapFile: 'new.json').mapFile, 'new.json');
      expect(original.copyWith(waves: 50).waves, 50);
      expect(original.copyWith(difficulty: 5).difficulty, 5);
      expect(original.copyWith(unlockRequirement: 10).unlockRequirement, 10);
      expect(original.copyWith(startingGold: 999).startingGold, 999);
      expect(original.copyWith(startingLives: 100).startingLives, 100);
    });

    test('should not modify original when copying', () {
      const original = SimulatedLevelConfig(
        id: 1,
        name: 'Original',
        mapFile: 'original.json',
        waves: 10,
        difficulty: 3,
      );

      original.copyWith(id: 99, name: 'Modified');

      expect(original.id, 1);
      expect(original.name, 'Original');
    });
  });

  group('LevelConfig Default Values', () {
    test('should use default startingGold of 200', () {
      const config = SimulatedLevelConfig(
        id: 1,
        name: 'Test',
        mapFile: 'test.json',
        waves: 10,
        difficulty: 1,
      );

      expect(config.startingGold, 200);
    });

    test('should use default startingLives of 20', () {
      const config = SimulatedLevelConfig(
        id: 1,
        name: 'Test',
        mapFile: 'test.json',
        waves: 10,
        difficulty: 1,
      );

      expect(config.startingLives, 20);
    });

    test('should have null unlockRequirement by default', () {
      const config = SimulatedLevelConfig(
        id: 1,
        name: 'Test',
        mapFile: 'test.json',
        waves: 10,
        difficulty: 1,
      );

      expect(config.unlockRequirement, null);
    });
  });

  group('LevelProgress JSON Serialization', () {
    test('should serialize all fields to JSON', () {
      const progress = SimulatedLevelProgress(
        levelId: 5,
        completed: true,
        stars: 3,
        highScore: 15000,
        bestWave: 25,
      );

      final json = progress.toJson();

      expect(json['levelId'], 5);
      expect(json['completed'], true);
      expect(json['stars'], 3);
      expect(json['highScore'], 15000);
      expect(json['bestWave'], 25);
    });

    test('should deserialize all fields from JSON', () {
      final json = {
        'levelId': 3,
        'completed': true,
        'stars': 2,
        'highScore': 8500,
        'bestWave': 15,
      };

      final progress = SimulatedLevelProgress.fromJson(json);

      expect(progress.levelId, 3);
      expect(progress.completed, true);
      expect(progress.stars, 2);
      expect(progress.highScore, 8500);
      expect(progress.bestWave, 15);
    });

    test('should use default values for missing fields', () {
      final json = {
        'levelId': 1,
      };

      final progress = SimulatedLevelProgress.fromJson(json);

      expect(progress.levelId, 1);
      expect(progress.completed, false); // default
      expect(progress.stars, 0); // default
      expect(progress.highScore, 0); // default
      expect(progress.bestWave, 0); // default
    });

    test('should round-trip serialize correctly', () {
      const original = SimulatedLevelProgress(
        levelId: 7,
        completed: true,
        stars: 3,
        highScore: 99999,
        bestWave: 50,
      );

      final json = original.toJson();
      final restored = SimulatedLevelProgress.fromJson(json);

      expect(restored.levelId, original.levelId);
      expect(restored.completed, original.completed);
      expect(restored.stars, original.stars);
      expect(restored.highScore, original.highScore);
      expect(restored.bestWave, original.bestWave);
    });

    test('should handle incomplete progress', () {
      final json = {
        'levelId': 5,
        'completed': false,
        'bestWave': 7,
      };

      final progress = SimulatedLevelProgress.fromJson(json);

      expect(progress.completed, false);
      expect(progress.stars, 0);
      expect(progress.highScore, 0);
      expect(progress.bestWave, 7);
    });
  });

  group('LevelProgress copyWith', () {
    test('should copy all fields when no parameters given', () {
      const original = SimulatedLevelProgress(
        levelId: 1,
        completed: true,
        stars: 2,
        highScore: 5000,
        bestWave: 10,
      );

      final copy = original.copyWith();

      expect(copy.levelId, original.levelId);
      expect(copy.completed, original.completed);
      expect(copy.stars, original.stars);
      expect(copy.highScore, original.highScore);
      expect(copy.bestWave, original.bestWave);
    });

    test('should update only specified fields', () {
      const original = SimulatedLevelProgress(
        levelId: 1,
        completed: false,
        stars: 0,
        highScore: 0,
        bestWave: 5,
      );

      final modified = original.copyWith(
        completed: true,
        stars: 3,
        highScore: 10000,
        bestWave: 25,
      );

      expect(modified.levelId, 1); // immutable
      expect(modified.completed, true);
      expect(modified.stars, 3);
      expect(modified.highScore, 10000);
      expect(modified.bestWave, 25);
    });

    test('should not allow changing levelId', () {
      const original = SimulatedLevelProgress(levelId: 5);
      final copy = original.copyWith(completed: true);

      expect(copy.levelId, 5); // should remain unchanged
    });

    test('should update fields individually', () {
      const original = SimulatedLevelProgress(levelId: 1);

      expect(original.copyWith(completed: true).completed, true);
      expect(original.copyWith(stars: 2).stars, 2);
      expect(original.copyWith(highScore: 5000).highScore, 5000);
      expect(original.copyWith(bestWave: 15).bestWave, 15);
    });
  });

  group('LevelProgress Default Values', () {
    test('should default completed to false', () {
      const progress = SimulatedLevelProgress(levelId: 1);
      expect(progress.completed, false);
    });

    test('should default stars to 0', () {
      const progress = SimulatedLevelProgress(levelId: 1);
      expect(progress.stars, 0);
    });

    test('should default highScore to 0', () {
      const progress = SimulatedLevelProgress(levelId: 1);
      expect(progress.highScore, 0);
    });

    test('should default bestWave to 0', () {
      const progress = SimulatedLevelProgress(levelId: 1);
      expect(progress.bestWave, 0);
    });
  });

  group('Level Unlock System', () {
    late SimulatedLevelManager manager;

    setUp(() {
      manager = SimulatedLevelManager([
        const SimulatedLevelConfig(
          id: 1,
          name: 'Tutorial',
          mapFile: 'level1.json',
          waves: 5,
          difficulty: 1,
          unlockRequirement: null, // Always unlocked
        ),
        const SimulatedLevelConfig(
          id: 2,
          name: 'First Battle',
          mapFile: 'level2.json',
          waves: 10,
          difficulty: 2,
          unlockRequirement: 1, // Requires level 1
        ),
        const SimulatedLevelConfig(
          id: 3,
          name: 'The Challenge',
          mapFile: 'level3.json',
          waves: 15,
          difficulty: 3,
          unlockRequirement: 2, // Requires level 2
        ),
        const SimulatedLevelConfig(
          id: 4,
          name: 'Boss Fight',
          mapFile: 'level4.json',
          waves: 20,
          difficulty: 5,
          unlockRequirement: 3, // Requires level 3
        ),
      ]);
    });

    test('should unlock first level without requirement', () {
      expect(manager.isLevelUnlocked(1), true);
    });

    test('should lock levels that require completion', () {
      expect(manager.isLevelUnlocked(2), false);
      expect(manager.isLevelUnlocked(3), false);
      expect(manager.isLevelUnlocked(4), false);
    });

    test('should unlock next level after completing prerequisite', () {
      expect(manager.isLevelUnlocked(2), false);

      manager.completeLevel(1, 1000, 5, 20);

      expect(manager.isLevelUnlocked(2), true);
    });

    test('should unlock chain of levels progressively', () {
      manager.completeLevel(1, 1000, 5, 20);
      expect(manager.isLevelUnlocked(2), true);
      expect(manager.isLevelUnlocked(3), false);

      manager.completeLevel(2, 2000, 10, 15);
      expect(manager.isLevelUnlocked(3), true);
      expect(manager.isLevelUnlocked(4), false);

      manager.completeLevel(3, 3000, 15, 10);
      expect(manager.isLevelUnlocked(4), true);
    });

    test('should only return unlocked levels in available list', () {
      var available = manager.getAvailableLevels();
      expect(available.length, 1);
      expect(available[0].id, 1);

      manager.completeLevel(1, 1000, 5, 20);
      available = manager.getAvailableLevels();
      expect(available.length, 2);
      expect(available.map((l) => l.id).toList(), [1, 2]);
    });
  });

  group('Star Calculation', () {
    late SimulatedLevelManager manager;

    setUp(() {
      manager = SimulatedLevelManager([
        const SimulatedLevelConfig(
          id: 1,
          name: 'Test Level',
          mapFile: 'test.json',
          waves: 10,
          difficulty: 1,
          startingLives: 20,
        ),
      ]);
    });

    test('should award 3 stars for 80%+ lives remaining', () {
      manager.completeLevel(1, 1000, 10, 16); // 80%
      expect(manager.progress[1]!.stars, 3);
    });

    test('should award 3 stars for 100% lives remaining', () {
      manager.completeLevel(1, 1000, 10, 20); // 100%
      expect(manager.progress[1]!.stars, 3);
    });

    test('should award 2 stars for 50-79% lives remaining', () {
      manager.completeLevel(1, 1000, 10, 10); // 50%
      expect(manager.progress[1]!.stars, 2);
    });

    test('should award 2 stars for 79% lives remaining', () {
      manager.completeLevel(1, 1000, 10, 15); // 75%
      expect(manager.progress[1]!.stars, 2);
    });

    test('should award 1 star for 1-49% lives remaining', () {
      manager.completeLevel(1, 1000, 10, 5); // 25%
      expect(manager.progress[1]!.stars, 1);
    });

    test('should award 1 star for minimum lives', () {
      manager.completeLevel(1, 1000, 10, 1); // 5%
      expect(manager.progress[1]!.stars, 1);
    });

    test('should award 0 stars for 0 lives', () {
      manager.completeLevel(1, 1000, 10, 0); // 0%
      expect(manager.progress[1]!.stars, 0);
    });
  });

  group('High Score Tracking', () {
    late SimulatedLevelManager manager;

    setUp(() {
      manager = SimulatedLevelManager([
        const SimulatedLevelConfig(
          id: 1,
          name: 'Test Level',
          mapFile: 'test.json',
          waves: 10,
          difficulty: 1,
        ),
      ]);
    });

    test('should track initial high score', () {
      manager.completeLevel(1, 5000, 10, 10);
      expect(manager.progress[1]!.highScore, 5000);
    });

    test('should update high score when beaten', () {
      manager.completeLevel(1, 5000, 10, 10);
      manager.completeLevel(1, 7500, 10, 10);
      expect(manager.progress[1]!.highScore, 7500);
    });

    test('should not lower high score', () {
      manager.completeLevel(1, 7500, 10, 10);
      manager.completeLevel(1, 5000, 10, 10);
      expect(manager.progress[1]!.highScore, 7500);
    });

    test('should keep same score when tied', () {
      manager.completeLevel(1, 5000, 10, 10);
      manager.completeLevel(1, 5000, 10, 10);
      expect(manager.progress[1]!.highScore, 5000);
    });
  });

  group('Best Wave Tracking', () {
    late SimulatedLevelManager manager;

    setUp(() {
      manager = SimulatedLevelManager([
        const SimulatedLevelConfig(
          id: 1,
          name: 'Test Level',
          mapFile: 'test.json',
          waves: 20,
          difficulty: 1,
        ),
      ]);
    });

    test('should track initial best wave', () {
      manager.completeLevel(1, 1000, 15, 10);
      expect(manager.progress[1]!.bestWave, 15);
    });

    test('should update best wave when improved', () {
      manager.completeLevel(1, 1000, 15, 10);
      manager.completeLevel(1, 2000, 20, 10);
      expect(manager.progress[1]!.bestWave, 20);
    });

    test('should not lower best wave', () {
      manager.completeLevel(1, 2000, 20, 10);
      manager.completeLevel(1, 1000, 15, 10);
      expect(manager.progress[1]!.bestWave, 20);
    });
  });

  group('Star Preservation', () {
    late SimulatedLevelManager manager;

    setUp(() {
      manager = SimulatedLevelManager([
        const SimulatedLevelConfig(
          id: 1,
          name: 'Test Level',
          mapFile: 'test.json',
          waves: 10,
          difficulty: 1,
          startingLives: 20,
        ),
      ]);
    });

    test('should keep higher star rating', () {
      manager.completeLevel(1, 1000, 10, 20); // 3 stars
      expect(manager.progress[1]!.stars, 3);

      manager.completeLevel(1, 1000, 10, 5); // Would be 1 star
      expect(manager.progress[1]!.stars, 3); // Still 3 stars
    });

    test('should upgrade star rating when improved', () {
      manager.completeLevel(1, 1000, 10, 5); // 1 star
      expect(manager.progress[1]!.stars, 1);

      manager.completeLevel(1, 1000, 10, 20); // 3 stars
      expect(manager.progress[1]!.stars, 3);
    });
  });

  group('Total Stars Calculation', () {
    late SimulatedLevelManager manager;

    setUp(() {
      manager = SimulatedLevelManager([
        const SimulatedLevelConfig(
          id: 1,
          name: 'Level 1',
          mapFile: 'level1.json',
          waves: 10,
          difficulty: 1,
          startingLives: 20,
        ),
        const SimulatedLevelConfig(
          id: 2,
          name: 'Level 2',
          mapFile: 'level2.json',
          waves: 15,
          difficulty: 2,
          unlockRequirement: 1,
          startingLives: 20,
        ),
        const SimulatedLevelConfig(
          id: 3,
          name: 'Level 3',
          mapFile: 'level3.json',
          waves: 20,
          difficulty: 3,
          unlockRequirement: 2,
          startingLives: 20,
        ),
      ]);
    });

    test('should start with zero total stars', () {
      expect(manager.getTotalStars(), 0);
    });

    test('should accumulate stars from completed levels', () {
      manager.completeLevel(1, 1000, 10, 20); // 3 stars
      expect(manager.getTotalStars(), 3);

      manager.completeLevel(2, 1000, 15, 10); // 2 stars
      expect(manager.getTotalStars(), 5);

      manager.completeLevel(3, 1000, 20, 5); // 1 star
      expect(manager.getTotalStars(), 6);
    });

    test('should calculate maximum possible stars', () {
      manager.completeLevel(1, 1000, 10, 20); // 3 stars
      manager.completeLevel(2, 1000, 15, 20); // 3 stars
      manager.completeLevel(3, 1000, 20, 20); // 3 stars
      expect(manager.getTotalStars(), 9);
    });
  });

  group('Difficulty Levels', () {
    test('should support difficulty range 1-5', () {
      for (int diff = 1; diff <= 5; diff++) {
        final config = SimulatedLevelConfig(
          id: diff,
          name: 'Level $diff',
          mapFile: 'level$diff.json',
          waves: diff * 10,
          difficulty: diff,
        );

        expect(config.difficulty, diff);
        expect(config.difficulty, inInclusiveRange(1, 5));
      }
    });

    test('should serialize difficulty correctly', () {
      const config = SimulatedLevelConfig(
        id: 1,
        name: 'Hard Level',
        mapFile: 'hard.json',
        waves: 30,
        difficulty: 5,
      );

      final json = config.toJson();
      expect(json['difficulty'], 5);

      final restored = SimulatedLevelConfig.fromJson(json);
      expect(restored.difficulty, 5);
    });
  });

  group('Level Collection Serialization', () {
    test('should serialize multiple levels', () {
      final levels = [
        const SimulatedLevelConfig(
          id: 1,
          name: 'Level 1',
          mapFile: 'level1.json',
          waves: 10,
          difficulty: 1,
        ),
        const SimulatedLevelConfig(
          id: 2,
          name: 'Level 2',
          mapFile: 'level2.json',
          waves: 15,
          difficulty: 2,
          unlockRequirement: 1,
        ),
        const SimulatedLevelConfig(
          id: 3,
          name: 'Level 3',
          mapFile: 'level3.json',
          waves: 20,
          difficulty: 3,
          unlockRequirement: 2,
        ),
      ];

      final jsonList = levels.map((l) => l.toJson()).toList();

      expect(jsonList.length, 3);
      expect(jsonList[0]['id'], 1);
      expect(jsonList[1]['id'], 2);
      expect(jsonList[2]['id'], 3);
    });

    test('should deserialize multiple levels', () {
      final jsonList = [
        {
          'id': 1,
          'name': 'Level 1',
          'mapFile': 'level1.json',
          'waves': 10,
          'difficulty': 1,
        },
        {
          'id': 2,
          'name': 'Level 2',
          'mapFile': 'level2.json',
          'waves': 15,
          'difficulty': 2,
          'unlockRequirement': 1,
        },
      ];

      final levels =
          jsonList.map((j) => SimulatedLevelConfig.fromJson(j)).toList();

      expect(levels.length, 2);
      expect(levels[0].name, 'Level 1');
      expect(levels[1].name, 'Level 2');
      expect(levels[1].unlockRequirement, 1);
    });
  });

  group('Progress Collection Serialization', () {
    test('should serialize multiple progress entries', () {
      final progressList = [
        const SimulatedLevelProgress(
          levelId: 1,
          completed: true,
          stars: 3,
          highScore: 10000,
          bestWave: 10,
        ),
        const SimulatedLevelProgress(
          levelId: 2,
          completed: true,
          stars: 2,
          highScore: 8000,
          bestWave: 15,
        ),
        const SimulatedLevelProgress(
          levelId: 3,
          completed: false,
          stars: 0,
          highScore: 0,
          bestWave: 5,
        ),
      ];

      final jsonList = progressList.map((p) => p.toJson()).toList();

      expect(jsonList.length, 3);
      expect(jsonList[0]['completed'], true);
      expect(jsonList[2]['completed'], false);
    });

    test('should deserialize multiple progress entries', () {
      final jsonList = [
        {'levelId': 1, 'completed': true, 'stars': 3},
        {'levelId': 2, 'completed': false, 'bestWave': 7},
      ];

      final progressList =
          jsonList.map((j) => SimulatedLevelProgress.fromJson(j)).toList();

      expect(progressList.length, 2);
      expect(progressList[0].stars, 3);
      expect(progressList[1].bestWave, 7);
    });
  });

  group('Edge Cases', () {
    test('should handle very large wave counts', () {
      const config = SimulatedLevelConfig(
        id: 1,
        name: 'Endless',
        mapFile: 'endless.json',
        waves: 999999,
        difficulty: 5,
      );

      final json = config.toJson();
      final restored = SimulatedLevelConfig.fromJson(json);

      expect(restored.waves, 999999);
    });

    test('should handle very high scores', () {
      const progress = SimulatedLevelProgress(
        levelId: 1,
        completed: true,
        highScore: 999999999,
      );

      final json = progress.toJson();
      final restored = SimulatedLevelProgress.fromJson(json);

      expect(restored.highScore, 999999999);
    });

    test('should handle zero starting resources', () {
      const config = SimulatedLevelConfig(
        id: 1,
        name: 'Challenge',
        mapFile: 'challenge.json',
        waves: 10,
        difficulty: 5,
        startingGold: 0,
        startingLives: 1,
      );

      expect(config.startingGold, 0);
      expect(config.startingLives, 1);
    });

    test('should handle special characters in level name', () {
      const config = SimulatedLevelConfig(
        id: 1,
        name: 'Level: "The Beginning" (v2.0) - 日本語',
        mapFile: 'special.json',
        waves: 10,
        difficulty: 1,
      );

      final json = config.toJson();
      final restored = SimulatedLevelConfig.fromJson(json);

      expect(restored.name, 'Level: "The Beginning" (v2.0) - 日本語');
    });

    test('should handle empty level name', () {
      const config = SimulatedLevelConfig(
        id: 1,
        name: '',
        mapFile: 'empty.json',
        waves: 10,
        difficulty: 1,
      );

      expect(config.name, '');
    });
  });

  group('Multiple Unlock Paths', () {
    test('should support levels with same unlock requirement', () {
      final manager = SimulatedLevelManager([
        const SimulatedLevelConfig(
          id: 1,
          name: 'Tutorial',
          mapFile: 'tutorial.json',
          waves: 5,
          difficulty: 1,
        ),
        const SimulatedLevelConfig(
          id: 2,
          name: 'Path A',
          mapFile: 'path_a.json',
          waves: 10,
          difficulty: 2,
          unlockRequirement: 1,
        ),
        const SimulatedLevelConfig(
          id: 3,
          name: 'Path B',
          mapFile: 'path_b.json',
          waves: 10,
          difficulty: 2,
          unlockRequirement: 1, // Same requirement as Path A
        ),
      ]);

      expect(manager.isLevelUnlocked(2), false);
      expect(manager.isLevelUnlocked(3), false);

      manager.completeLevel(1, 1000, 5, 20);

      // Both paths should be unlocked
      expect(manager.isLevelUnlocked(2), true);
      expect(manager.isLevelUnlocked(3), true);

      expect(manager.getAvailableLevels().length, 3);
    });
  });
}
