import 'package:flutter/foundation.dart';

import '../models/level_config.dart';
import 'storage_service.dart';

/// Service to manage level configurations and progress
class LevelService {
  LevelService._();
  static final instance = LevelService._();

  bool _initialized = false;

  /// All available levels (hardcoded for now, could load from JSON)
  final List<LevelConfig> levels = const [
    LevelConfig(
      id: 1,
      name: 'Grid Alpha',
      mapFile: 'maps/level1.tmx',
      waves: 5,
      difficulty: 1,
      unlockRequirement: null, // Always unlocked
      startingGold: 250,
      startingLives: 25,
    ),
    LevelConfig(
      id: 2,
      name: 'Neon Corridor',
      mapFile: 'maps/level2.tmx',
      waves: 8,
      difficulty: 1,
      unlockRequirement: 1,
      startingGold: 200,
      startingLives: 20,
    ),
    LevelConfig(
      id: 3,
      name: 'Circuit Maze',
      mapFile: 'maps/level3.tmx',
      waves: 10,
      difficulty: 2,
      unlockRequirement: 2,
      startingGold: 200,
      startingLives: 20,
    ),
    LevelConfig(
      id: 4,
      name: 'Data Stream',
      mapFile: 'maps/level4.tmx',
      waves: 12,
      difficulty: 2,
      unlockRequirement: 3,
      startingGold: 180,
      startingLives: 18,
    ),
    LevelConfig(
      id: 5,
      name: 'Core Junction',
      mapFile: 'maps/level5.tmx',
      waves: 15,
      difficulty: 3,
      unlockRequirement: 4,
      startingGold: 150,
      startingLives: 15,
    ),
    LevelConfig(
      id: 6,
      name: 'Pulse Network',
      mapFile: 'maps/level6.tmx',
      waves: 18,
      difficulty: 3,
      unlockRequirement: 5,
      startingGold: 150,
      startingLives: 15,
    ),
    LevelConfig(
      id: 7,
      name: 'Firewall',
      mapFile: 'maps/level7.tmx',
      waves: 20,
      difficulty: 4,
      unlockRequirement: 6,
      startingGold: 120,
      startingLives: 12,
    ),
    LevelConfig(
      id: 8,
      name: 'Mainframe',
      mapFile: 'maps/level8.tmx',
      waves: 25,
      difficulty: 5,
      unlockRequirement: 7,
      startingGold: 100,
      startingLives: 10,
    ),
  ];

  /// Player progress per level (loaded from storage)
  final Map<int, LevelProgress> _progress = {};

  /// Set of unlocked level IDs
  Set<int> _unlockedLevels = {1};

  /// Initialize and load progress from storage
  Future<void> initialize() async {
    if (_initialized) return;

    await StorageService.instance.initialize();
    await _loadProgress();
    _initialized = true;

    debugPrint('[LevelService] Initialized with ${_progress.length} level progress entries');
    debugPrint('[LevelService] Unlocked levels: $_unlockedLevels');
  }

  /// Load progress from persistent storage
  Future<void> _loadProgress() async {
    // Load unlocked levels
    _unlockedLevels = StorageService.instance.loadUnlockedLevels();
    if (!_unlockedLevels.contains(1)) {
      _unlockedLevels.add(1);
    }

    // Load all level progress
    final allProgress = StorageService.instance.loadAllLevelProgress();
    for (final entry in allProgress.entries) {
      _progress[entry.key] = LevelProgress.fromJson(entry.value);
    }

    // Ensure level 1 always has a progress entry
    _progress.putIfAbsent(1, () => const LevelProgress(levelId: 1));
  }

  /// Get progress for a level
  LevelProgress getProgress(int levelId) {
    return _progress[levelId] ?? LevelProgress(levelId: levelId);
  }

  /// Check if a level is unlocked
  bool isLevelUnlocked(int levelId) {
    // Level 1 is always unlocked
    if (levelId == 1) return true;

    // Check if explicitly unlocked
    if (_unlockedLevels.contains(levelId)) return true;

    // Check if prerequisite is completed
    final level = levels.firstWhere(
      (l) => l.id == levelId,
      orElse: () => throw ArgumentError('Level $levelId not found'),
    );

    if (level.unlockRequirement == null) return true;

    final requiredProgress = getProgress(level.unlockRequirement!);
    return requiredProgress.completed;
  }

  /// Update progress after completing a level
  Future<void> updateProgress({
    required int levelId,
    required bool completed,
    required int score,
    required int wavesCleared,
    required int livesRemaining,
    required int maxLives,
  }) async {
    final current = getProgress(levelId);

    // Calculate stars based on performance
    int stars = 0;
    if (completed) {
      stars = 1; // Base star for completion
      if (livesRemaining >= maxLives * 0.75) stars = 2; // Good health
      if (livesRemaining == maxLives) stars = 3; // Perfect
    }

    final newProgress = current.copyWith(
      completed: completed || current.completed,
      stars: stars > current.stars ? stars : current.stars,
      highScore: score > current.highScore ? score : current.highScore,
      bestWave: wavesCleared > current.bestWave ? wavesCleared : current.bestWave,
    );

    _progress[levelId] = newProgress;

    // Save to storage
    await StorageService.instance.saveLevelProgress(
      levelId: levelId,
      completed: newProgress.completed,
      stars: newProgress.stars,
      highScore: newProgress.highScore,
      bestWave: newProgress.bestWave,
    );

    // Unlock next level if completed
    if (completed) {
      final nextLevelId = levelId + 1;
      if (levels.any((l) => l.id == nextLevelId)) {
        _unlockedLevels.add(nextLevelId);
        _progress.putIfAbsent(
          nextLevelId,
          () => LevelProgress(levelId: nextLevelId),
        );

        // Save unlocked levels
        await StorageService.instance.saveUnlockedLevels(_unlockedLevels);
      }
    }

    debugPrint('[LevelService] Updated progress for level $levelId: stars=${newProgress.stars}, score=${newProgress.highScore}');
  }

  /// Get level config by ID
  LevelConfig? getLevel(int levelId) {
    try {
      return levels.firstWhere((l) => l.id == levelId);
    } catch (_) {
      return null;
    }
  }

  /// Get total stars collected across all levels
  int get totalStars {
    return _progress.values.fold(0, (sum, p) => sum + p.stars);
  }

  /// Get maximum possible stars
  int get maxStars => levels.length * 3;

  /// Get number of completed levels
  int get completedLevels {
    return _progress.values.where((p) => p.completed).length;
  }

  /// Get total high score across all levels
  int get totalHighScore {
    return _progress.values.fold(0, (sum, p) => sum + p.highScore);
  }

  /// Reset all progress (for debugging or user request)
  Future<void> resetProgress() async {
    _progress.clear();
    _unlockedLevels = {1};
    _progress[1] = const LevelProgress(levelId: 1);

    await StorageService.instance.clearProgress();
    await StorageService.instance.saveUnlockedLevels(_unlockedLevels);

    debugPrint('[LevelService] Progress reset');
  }
}
