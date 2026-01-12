import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting game data using SharedPreferences
/// Works on web (localStorage), mobile, and desktop
class StorageService {
  StorageService._();
  static final instance = StorageService._();

  SharedPreferences? _prefs;
  bool _initialized = false;

  // Keys for storage
  static const String _keyLevelProgress = 'level_progress_';
  static const String _keySettings = 'game_settings';
  static const String _keyStats = 'game_stats';
  static const String _keyUnlockedLevels = 'unlocked_levels';

  /// Initialize storage - must be called before using any other methods
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      debugPrint('[StorageService] Initialized successfully');
    } catch (e) {
      debugPrint('[StorageService] Failed to initialize: $e');
    }
  }

  /// Check if storage is ready
  bool get isReady => _initialized && _prefs != null;

  /// Save level progress
  Future<void> saveLevelProgress({
    required int levelId,
    required bool completed,
    required int stars,
    required int highScore,
    required int bestWave,
  }) async {
    if (!isReady) {
      debugPrint('[StorageService] Not initialized, skipping save');
      return;
    }

    final data = {
      'levelId': levelId,
      'completed': completed,
      'stars': stars,
      'highScore': highScore,
      'bestWave': bestWave,
    };

    final key = '$_keyLevelProgress$levelId';
    await _prefs!.setString(key, jsonEncode(data));
    debugPrint('[StorageService] Saved progress for level $levelId: stars=$stars, score=$highScore');
  }

  /// Load level progress
  Map<String, dynamic>? loadLevelProgress(int levelId) {
    if (!isReady) return null;

    final key = '$_keyLevelProgress$levelId';
    final jsonStr = _prefs!.getString(key);

    if (jsonStr == null) return null;

    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[StorageService] Failed to parse level progress: $e');
      return null;
    }
  }

  /// Load all level progress
  Map<int, Map<String, dynamic>> loadAllLevelProgress() {
    if (!isReady) return {};

    final result = <int, Map<String, dynamic>>{};
    final keys = _prefs!.getKeys();

    for (final key in keys) {
      if (key.startsWith(_keyLevelProgress)) {
        final levelIdStr = key.substring(_keyLevelProgress.length);
        final levelId = int.tryParse(levelIdStr);
        if (levelId != null) {
          final progress = loadLevelProgress(levelId);
          if (progress != null) {
            result[levelId] = progress;
          }
        }
      }
    }

    debugPrint('[StorageService] Loaded ${result.length} level progress entries');
    return result;
  }

  /// Save unlocked levels list
  Future<void> saveUnlockedLevels(Set<int> levelIds) async {
    if (!isReady) return;

    final list = levelIds.toList()..sort();
    await _prefs!.setString(_keyUnlockedLevels, jsonEncode(list));
    debugPrint('[StorageService] Saved ${list.length} unlocked levels');
  }

  /// Load unlocked levels list
  Set<int> loadUnlockedLevels() {
    if (!isReady) return {1}; // Level 1 always unlocked

    final jsonStr = _prefs!.getString(_keyUnlockedLevels);
    if (jsonStr == null) return {1};

    try {
      final list = jsonDecode(jsonStr) as List;
      final result = list.map((e) => e as int).toSet();
      result.add(1); // Always include level 1
      return result;
    } catch (e) {
      debugPrint('[StorageService] Failed to parse unlocked levels: $e');
      return {1};
    }
  }

  /// Save settings
  Future<void> saveSettings({
    required double musicVolume,
    required double sfxVolume,
    required bool showFps,
    required bool showGrid,
    required bool particlesEnabled,
    required bool screenShake,
  }) async {
    if (!isReady) return;

    final data = {
      'musicVolume': musicVolume,
      'sfxVolume': sfxVolume,
      'showFps': showFps,
      'showGrid': showGrid,
      'particlesEnabled': particlesEnabled,
      'screenShake': screenShake,
    };

    await _prefs!.setString(_keySettings, jsonEncode(data));
    debugPrint('[StorageService] Saved settings');
  }

  /// Load settings
  Map<String, dynamic>? loadSettings() {
    if (!isReady) return null;

    final jsonStr = _prefs!.getString(_keySettings);
    if (jsonStr == null) return null;

    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[StorageService] Failed to parse settings: $e');
      return null;
    }
  }

  /// Save total stats
  Future<void> saveStats({
    required int totalScore,
    required int totalEnemiesKilled,
    required int totalTowersPlaced,
    required int totalPulsesUsed,
    required int totalGamesPlayed,
    required int totalVictories,
    required Duration totalPlayTime,
  }) async {
    if (!isReady) return;

    final data = {
      'totalScore': totalScore,
      'totalEnemiesKilled': totalEnemiesKilled,
      'totalTowersPlaced': totalTowersPlaced,
      'totalPulsesUsed': totalPulsesUsed,
      'totalGamesPlayed': totalGamesPlayed,
      'totalVictories': totalVictories,
      'totalPlayTimeSeconds': totalPlayTime.inSeconds,
    };

    await _prefs!.setString(_keyStats, jsonEncode(data));
    debugPrint('[StorageService] Saved stats');
  }

  /// Load stats
  Map<String, dynamic>? loadStats() {
    if (!isReady) return null;

    final jsonStr = _prefs!.getString(_keyStats);
    if (jsonStr == null) return null;

    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[StorageService] Failed to parse stats: $e');
      return null;
    }
  }

  /// Clear all game data (reset progress)
  Future<void> clearAll() async {
    if (!isReady) return;

    await _prefs!.clear();
    debugPrint('[StorageService] Cleared all data');
  }

  /// Clear only level progress (keep settings)
  Future<void> clearProgress() async {
    if (!isReady) return;

    final keys = _prefs!.getKeys().toList();
    for (final key in keys) {
      if (key.startsWith(_keyLevelProgress) || key == _keyUnlockedLevels || key == _keyStats) {
        await _prefs!.remove(key);
      }
    }
    debugPrint('[StorageService] Cleared progress data');
  }

  /// Export all data as JSON (for debugging/backup)
  String exportData() {
    if (!isReady) return '{}';

    final data = <String, dynamic>{};
    for (final key in _prefs!.getKeys()) {
      data[key] = _prefs!.get(key);
    }
    return jsonEncode(data);
  }

  /// Import data from JSON (restore backup)
  Future<bool> importData(String json) async {
    if (!isReady) return false;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;

      for (final entry in data.entries) {
        final value = entry.value;
        if (value is String) {
          await _prefs!.setString(entry.key, value);
        } else if (value is int) {
          await _prefs!.setInt(entry.key, value);
        } else if (value is double) {
          await _prefs!.setDouble(entry.key, value);
        } else if (value is bool) {
          await _prefs!.setBool(entry.key, value);
        } else if (value is List) {
          await _prefs!.setStringList(entry.key, value.map((e) => e.toString()).toList());
        }
      }

      debugPrint('[StorageService] Imported data successfully');
      return true;
    } catch (e) {
      debugPrint('[StorageService] Failed to import data: $e');
      return false;
    }
  }
}
