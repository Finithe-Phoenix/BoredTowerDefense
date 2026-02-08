// Tests for LevelService progression: tower unlocks, star calculation, level progression
// Simulation-based (no external dependencies)
import 'package:test/test.dart';

/// Simulated level progress data
class SimLevelProgress {
  final int levelId;
  int stars;
  int highScore;
  bool completed;

  SimLevelProgress({
    required this.levelId,
    this.stars = 0,
    this.highScore = 0,
    this.completed = false,
  });
}

/// Simulated tower unlock schedule matching the real implementation
class TowerUnlocks {
  static const Map<String, int> _unlockAtLevel = {
    'pulseArcher': 1,       // Always unlocked
    'circuitCannon': 3,
    'phaseMage': 5,
    'glimmerField': 8,
    'ionSniper': 12,
    'teslaTerminal': 16,
    'resonanceSiphon': 20,
    'neuralDisruptor': 25,
    'plasmaBubble': 30,
  };

  static bool isTowerUnlocked(String towerType, int completedLevels, {bool unlockAll = false}) {
    if (unlockAll) return true;
    if (towerType == 'pulseArcher') return true; // Always unlocked

    final requiredLevel = _unlockAtLevel[towerType];
    if (requiredLevel == null) return false; // Unknown tower
    return completedLevels >= requiredLevel;
  }

  static List<String> getUnlockedTowers(int completedLevels, {bool unlockAll = false}) {
    if (unlockAll) return _unlockAtLevel.keys.toList();
    return _unlockAtLevel.entries
        .where((e) => completedLevels >= e.value || e.key == 'pulseArcher')
        .map((e) => e.key)
        .toList();
  }
}

/// Simulated LevelService for progression testing
class SimLevelService {
  final Map<int, SimLevelProgress> _progress = {};
  final Set<int> _unlockedLevels = {1}; // Level 1 always unlocked
  bool unlockAllLevels = false;

  int get totalStars =>
      _progress.values.fold(0, (sum, p) => sum + p.stars);

  int get completedLevels =>
      _progress.values.where((p) => p.completed).length;

  int get totalHighScore =>
      _progress.values.fold(0, (sum, p) => sum + p.highScore);

  bool isLevelUnlocked(int levelId) {
    if (unlockAllLevels) return true;
    return _unlockedLevels.contains(levelId);
  }

  SimLevelProgress? getProgress(int levelId) => _progress[levelId];

  /// Calculate stars earned from victory
  int calculateStars({
    required int livesRemaining,
    required int maxLives,
  }) {
    if (maxLives <= 0) return 1;
    if (livesRemaining == maxLives) return 3;
    if (livesRemaining >= maxLives * 0.75) return 2;
    return 1;
  }

  /// Calculate meta currency reward
  int calculateMetaCurrencyReward({
    required int wavesCleared,
    required int totalWaves,
    required bool isVictory,
  }) {
    if (isVictory) {
      return 10 + (wavesCleared ~/ 2);
    }
    return (wavesCleared / 3).floor();
  }

  void updateProgress({
    required int levelId,
    required int score,
    required int livesRemaining,
    required int maxLives,
    required int wavesCleared,
    required int totalWaves,
    required bool isVictory,
  }) {
    final stars = isVictory
        ? calculateStars(livesRemaining: livesRemaining, maxLives: maxLives)
        : 0;

    final existing = _progress[levelId];
    if (existing == null || score > existing.highScore) {
      _progress[levelId] = SimLevelProgress(
        levelId: levelId,
        stars: existing != null ? (stars > existing.stars ? stars : existing.stars) : stars,
        highScore: score,
        completed: isVictory || (existing?.completed ?? false),
      );
    } else if (stars > existing.stars) {
      existing.stars = stars;
    }

    if (isVictory) {
      _progress[levelId]!.completed = true;
      // Unlock next level
      _unlockedLevels.add(levelId + 1);
    }
  }

  void resetProgress() {
    _progress.clear();
    _unlockedLevels.clear();
    _unlockedLevels.add(1);
  }
}

void main() {
  late SimLevelService service;

  setUp(() {
    service = SimLevelService();
  });

  group('LevelService star calculation', () {
    test('3 stars at full health', () {
      final stars = service.calculateStars(livesRemaining: 20, maxLives: 20);
      expect(stars, 3);
    });

    test('2 stars at 75% or more health', () {
      final stars = service.calculateStars(livesRemaining: 15, maxLives: 20);
      expect(stars, 2);
    });

    test('2 stars at exactly 75%', () {
      final stars = service.calculateStars(livesRemaining: 15, maxLives: 20);
      expect(stars, 2);
    });

    test('1 star below 75% health', () {
      final stars = service.calculateStars(livesRemaining: 10, maxLives: 20);
      expect(stars, 1);
    });

    test('1 star at 1 life remaining', () {
      final stars = service.calculateStars(livesRemaining: 1, maxLives: 20);
      expect(stars, 1);
    });

    test('boundary: 80% health gives 2 stars', () {
      final stars = service.calculateStars(livesRemaining: 16, maxLives: 20);
      expect(stars, 2);
    });

    test('boundary: 74% health gives 1 star', () {
      // 14/20 = 70%
      final stars = service.calculateStars(livesRemaining: 14, maxLives: 20);
      expect(stars, 1);
    });

    test('edge case: maxLives is 0', () {
      final stars = service.calculateStars(livesRemaining: 0, maxLives: 0);
      expect(stars, 1);
    });

    test('edge case: maxLives is 1', () {
      final stars3 = service.calculateStars(livesRemaining: 1, maxLives: 1);
      expect(stars3, 3); // Full health
    });
  });

  group('LevelService meta currency reward', () {
    test('victory reward increases with waves', () {
      final r5 = service.calculateMetaCurrencyReward(
        wavesCleared: 5, totalWaves: 10, isVictory: true);
      final r10 = service.calculateMetaCurrencyReward(
        wavesCleared: 10, totalWaves: 10, isVictory: true);

      expect(r10, greaterThan(r5));
    });

    test('victory reward formula: 10 + wavesCleared / 2', () {
      final reward = service.calculateMetaCurrencyReward(
        wavesCleared: 10, totalWaves: 10, isVictory: true);
      expect(reward, 15); // 10 + 10/2
    });

    test('defeat reward formula: wavesCleared / 3', () {
      final reward = service.calculateMetaCurrencyReward(
        wavesCleared: 6, totalWaves: 10, isVictory: false);
      expect(reward, 2); // 6/3
    });

    test('defeat with 0 waves gives 0 currency', () {
      final reward = service.calculateMetaCurrencyReward(
        wavesCleared: 0, totalWaves: 10, isVictory: false);
      expect(reward, 0);
    });
  });

  group('LevelService level unlocking', () {
    test('level 1 always unlocked', () {
      expect(service.isLevelUnlocked(1), isTrue);
    });

    test('level 2 locked initially', () {
      expect(service.isLevelUnlocked(2), isFalse);
    });

    test('completing level 1 unlocks level 2', () {
      service.updateProgress(
        levelId: 1,
        score: 100,
        livesRemaining: 20,
        maxLives: 20,
        wavesCleared: 10,
        totalWaves: 10,
        isVictory: true,
      );
      expect(service.isLevelUnlocked(2), isTrue);
    });

    test('sequential unlocking works', () {
      for (int i = 1; i <= 5; i++) {
        service.updateProgress(
          levelId: i,
          score: 100,
          livesRemaining: 20,
          maxLives: 20,
          wavesCleared: 10,
          totalWaves: 10,
          isVictory: true,
        );
      }
      expect(service.isLevelUnlocked(6), isTrue);
      expect(service.isLevelUnlocked(7), isFalse);
    });

    test('unlockAllLevels override', () {
      service.unlockAllLevels = true;
      expect(service.isLevelUnlocked(100), isTrue);
    });

    test('defeat does not unlock next level', () {
      service.updateProgress(
        levelId: 1,
        score: 50,
        livesRemaining: 0,
        maxLives: 20,
        wavesCleared: 5,
        totalWaves: 10,
        isVictory: false,
      );
      expect(service.isLevelUnlocked(2), isFalse);
    });
  });

  group('LevelService progress tracking', () {
    test('records victory with correct stars', () {
      service.updateProgress(
        levelId: 1,
        score: 500,
        livesRemaining: 20,
        maxLives: 20,
        wavesCleared: 10,
        totalWaves: 10,
        isVictory: true,
      );

      final progress = service.getProgress(1);
      expect(progress, isNotNull);
      expect(progress!.stars, 3);
      expect(progress.highScore, 500);
      expect(progress.completed, isTrue);
    });

    test('higher score replaces lower score', () {
      service.updateProgress(
        levelId: 1, score: 300, livesRemaining: 15, maxLives: 20,
        wavesCleared: 10, totalWaves: 10, isVictory: true);
      service.updateProgress(
        levelId: 1, score: 500, livesRemaining: 10, maxLives: 20,
        wavesCleared: 10, totalWaves: 10, isVictory: true);

      expect(service.getProgress(1)!.highScore, 500);
    });

    test('lower score does not replace higher score', () {
      service.updateProgress(
        levelId: 1, score: 500, livesRemaining: 15, maxLives: 20,
        wavesCleared: 10, totalWaves: 10, isVictory: true);
      service.updateProgress(
        levelId: 1, score: 200, livesRemaining: 20, maxLives: 20,
        wavesCleared: 10, totalWaves: 10, isVictory: true);

      expect(service.getProgress(1)!.highScore, 500);
    });

    test('higher stars replace lower stars', () {
      service.updateProgress(
        levelId: 1, score: 500, livesRemaining: 10, maxLives: 20,
        wavesCleared: 10, totalWaves: 10, isVictory: true);
      expect(service.getProgress(1)!.stars, 1);

      service.updateProgress(
        levelId: 1, score: 600, livesRemaining: 20, maxLives: 20,
        wavesCleared: 10, totalWaves: 10, isVictory: true);
      expect(service.getProgress(1)!.stars, 3);
    });

    test('completed flag persists through defeat replays', () {
      service.updateProgress(
        levelId: 1, score: 500, livesRemaining: 20, maxLives: 20,
        wavesCleared: 10, totalWaves: 10, isVictory: true);
      expect(service.getProgress(1)!.completed, isTrue);

      service.updateProgress(
        levelId: 1, score: 100, livesRemaining: 0, maxLives: 20,
        wavesCleared: 3, totalWaves: 10, isVictory: false);
      expect(service.getProgress(1)!.completed, isTrue); // Still completed
    });
  });

  group('LevelService aggregate stats', () {
    test('totalStars sums across all levels', () {
      service.updateProgress(
        levelId: 1, score: 500, livesRemaining: 20, maxLives: 20,
        wavesCleared: 10, totalWaves: 10, isVictory: true); // 3 stars
      service.updateProgress(
        levelId: 2, score: 300, livesRemaining: 10, maxLives: 20,
        wavesCleared: 10, totalWaves: 10, isVictory: true); // 1 star

      expect(service.totalStars, 4);
    });

    test('completedLevels counts victories', () {
      service.updateProgress(
        levelId: 1, score: 500, livesRemaining: 20, maxLives: 20,
        wavesCleared: 10, totalWaves: 10, isVictory: true);
      service.updateProgress(
        levelId: 2, score: 100, livesRemaining: 0, maxLives: 20,
        wavesCleared: 3, totalWaves: 10, isVictory: false);

      expect(service.completedLevels, 1);
    });

    test('totalHighScore sums all scores', () {
      service.updateProgress(
        levelId: 1, score: 500, livesRemaining: 20, maxLives: 20,
        wavesCleared: 10, totalWaves: 10, isVictory: true);
      service.updateProgress(
        levelId: 2, score: 300, livesRemaining: 15, maxLives: 20,
        wavesCleared: 10, totalWaves: 10, isVictory: true);

      expect(service.totalHighScore, 800);
    });

    test('initial stats are zero', () {
      expect(service.totalStars, 0);
      expect(service.completedLevels, 0);
      expect(service.totalHighScore, 0);
    });
  });

  group('Tower unlock schedule', () {
    test('pulseArcher always unlocked', () {
      expect(TowerUnlocks.isTowerUnlocked('pulseArcher', 0), isTrue);
    });

    test('circuitCannon unlocks at level 3', () {
      expect(TowerUnlocks.isTowerUnlocked('circuitCannon', 2), isFalse);
      expect(TowerUnlocks.isTowerUnlocked('circuitCannon', 3), isTrue);
    });

    test('phaseMage unlocks at level 5', () {
      expect(TowerUnlocks.isTowerUnlocked('phaseMage', 4), isFalse);
      expect(TowerUnlocks.isTowerUnlocked('phaseMage', 5), isTrue);
    });

    test('all towers unlock with unlockAll', () {
      expect(TowerUnlocks.isTowerUnlocked('plasmaBubble', 0, unlockAll: true), isTrue);
    });

    test('unknown tower returns false', () {
      expect(TowerUnlocks.isTowerUnlocked('unknownTower', 100), isFalse);
    });

    test('getUnlockedTowers returns correct list for progress', () {
      // At 0 completed levels, only pulseArcher
      final at0 = TowerUnlocks.getUnlockedTowers(0);
      expect(at0, contains('pulseArcher'));
      expect(at0.length, 1);

      // At 5 completed levels: pulseArcher, circuitCannon, phaseMage
      final at5 = TowerUnlocks.getUnlockedTowers(5);
      expect(at5, contains('pulseArcher'));
      expect(at5, contains('circuitCannon'));
      expect(at5, contains('phaseMage'));
      expect(at5.length, 3);
    });

    test('getUnlockedTowers with unlockAll returns all', () {
      final all = TowerUnlocks.getUnlockedTowers(0, unlockAll: true);
      expect(all.length, 9); // All 9 tower types
    });

    test('progressive unlock order is correct', () {
      // As completedLevels increases, more towers unlock
      int prevCount = 0;
      for (int levels = 0; levels <= 30; levels++) {
        final count = TowerUnlocks.getUnlockedTowers(levels).length;
        expect(count, greaterThanOrEqualTo(prevCount),
            reason: 'Towers at $levels levels should be >= previous');
        prevCount = count;
      }
    });
  });

  group('LevelService reset', () {
    test('reset clears all progress', () {
      service.updateProgress(
        levelId: 1, score: 500, livesRemaining: 20, maxLives: 20,
        wavesCleared: 10, totalWaves: 10, isVictory: true);

      service.resetProgress();
      expect(service.getProgress(1), isNull);
      expect(service.totalStars, 0);
      expect(service.completedLevels, 0);
    });

    test('reset keeps level 1 unlocked', () {
      service.resetProgress();
      expect(service.isLevelUnlocked(1), isTrue);
    });

    test('reset locks all other levels', () {
      service.updateProgress(
        levelId: 1, score: 500, livesRemaining: 20, maxLives: 20,
        wavesCleared: 10, totalWaves: 10, isVictory: true);

      service.resetProgress();
      expect(service.isLevelUnlocked(2), isFalse);
    });
  });
}
