/// Configuration for a game level
class LevelConfig {
  const LevelConfig({
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
  factory LevelConfig.fromJson(Map<String, dynamic> json) {
    return LevelConfig(
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
  LevelConfig copyWith({
    int? id,
    String? name,
    String? mapFile,
    int? waves,
    int? difficulty,
    int? unlockRequirement,
    int? startingGold,
    int? startingLives,
  }) {
    return LevelConfig(
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

/// Player progress for a level
class LevelProgress {
  const LevelProgress({
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

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
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

  LevelProgress copyWith({
    bool? completed,
    int? stars,
    int? highScore,
    int? bestWave,
  }) {
    return LevelProgress(
      levelId: levelId,
      completed: completed ?? this.completed,
      stars: stars ?? this.stars,
      highScore: highScore ?? this.highScore,
      bestWave: bestWave ?? this.bestWave,
    );
  }
}
