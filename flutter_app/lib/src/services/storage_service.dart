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
  @visibleForTesting
  static bool forceInitFailure = false;
  @visibleForTesting
  static bool includeLevelOneAlways = true;

  // Keys for storage
  static const String _keyLevelProgress = 'level_progress_';
  static const String _keySettings = 'game_settings';
  static const String _keyQualitySettings = 'quality_settings';
  static const String _keyStats = 'game_stats';
  static const String _keyUnlockedLevels = 'unlocked_levels';
  static const String _keyMetaCurrency = 'meta_currency';
  static const String _keyUpgradeLevels = 'upgrade_levels';
  static const String _keyTutorialCompleted = 'tutorial_completed';

  /// Initialize storage - must be called before using any other methods
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (forceInitFailure) {
        throw Exception('Forced initialization failure');
      }
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      _log('[StorageService] Initialized successfully');
    } catch (e) {
      _log('[StorageService] Failed to initialize: $e');
    }
  }

  @visibleForTesting
  void resetForTesting() {
    _prefs = null;
    _initialized = false;
  }

  /// Check if storage is ready
  bool get isReady => _initialized && _prefs != null;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Save level progress
  Future<void> saveLevelProgress({
    required int levelId,
    required bool completed,
    required int stars,
    required int highScore,
    required int bestWave,
  }) async {
    if (!isReady) {
      _log('[StorageService] Not initialized, skipping save');
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
    _log('[StorageService] Saved progress for level $levelId: stars=$stars, score=$highScore');
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
      _log('[StorageService] Failed to parse level progress: $e');
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

    _log('[StorageService] Loaded ${result.length} level progress entries');
    return result;
  }

  /// Save unlocked levels list
  Future<void> saveUnlockedLevels(Set<int> levelIds) async {
    if (!isReady) return;

    final list = levelIds.toList()..sort();
    await _prefs!.setString(_keyUnlockedLevels, jsonEncode(list));
    _log('[StorageService] Saved ${list.length} unlocked levels');
  }

  /// Load unlocked levels list
  Set<int> loadUnlockedLevels() {
    if (!isReady) return {1}; // Level 1 always unlocked

    final jsonStr = _prefs!.getString(_keyUnlockedLevels);
    if (jsonStr == null) return {1};

    try {
      final list = jsonDecode(jsonStr) as List;
      final result = list.map((e) => e as int).toSet();
      if (includeLevelOneAlways) {
        result.add(1); // Always include level 1
      }
      return result;
    } catch (e) {
      _log('[StorageService] Failed to parse unlocked levels: $e');
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
    _log('[StorageService] Saved settings');
  }

  /// Save quality settings
  Future<void> saveQualitySettings({
    required String preset,
    required bool autoQuality,
  }) async {
    if (!isReady) return;

    final data = {
      'preset': preset,
      'autoQuality': autoQuality,
    };

    await _prefs!.setString(_keyQualitySettings, jsonEncode(data));
    _log('[StorageService] Saved quality settings');
  }

  /// Load settings
  Map<String, dynamic>? loadSettings() {
    if (!isReady) return null;

    final jsonStr = _prefs!.getString(_keySettings);
    if (jsonStr == null) return null;

    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      _log('[StorageService] Failed to parse settings: $e');
      return null;
    }
  }

  /// Load quality settings
  Map<String, dynamic>? loadQualitySettings() {
    if (!isReady) return null;

    final jsonStr = _prefs!.getString(_keyQualitySettings);
    if (jsonStr == null) return null;

    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      _log('[StorageService] Failed to parse quality settings: $e');
      return null;
    }
  }

  /// Save meta currency
  Future<void> saveMetaCurrency(int value) async {
    if (!isReady) return;
    await _prefs!.setInt(_keyMetaCurrency, value);
    _log('[StorageService] Saved meta currency: $value');
  }

  /// Load meta currency
  int loadMetaCurrency() {
    if (!isReady) return 0;
    return _prefs!.getInt(_keyMetaCurrency) ?? 0;
  }

  /// Save upgrade levels
  Future<void> saveUpgradeLevels(Map<String, int> levels) async {
    if (!isReady) return;
    final data = jsonEncode(levels);
    await _prefs!.setString(_keyUpgradeLevels, data);
    _log('[StorageService] Saved upgrade levels');
  }

  /// Load upgrade levels
  Map<String, int> loadUpgradeLevels() {
    if (!isReady) return {};
    final jsonStr = _prefs!.getString(_keyUpgradeLevels);
    if (jsonStr == null) return {};

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return map.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      _log('[StorageService] Failed to parse upgrade levels: $e');
      return {};
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
    _log('[StorageService] Saved stats');
  }

  /// Load stats
  Map<String, dynamic>? loadStats() {
    if (!isReady) return null;

    final jsonStr = _prefs!.getString(_keyStats);
    if (jsonStr == null) return null;

    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      _log('[StorageService] Failed to parse stats: $e');
      return null;
    }
  }

  /// Clear all game data (reset progress)
  Future<void> clearAll() async {
    if (!isReady) return;

    await _prefs!.clear();
    _log('[StorageService] Cleared all data');
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
    _log('[StorageService] Cleared progress data');
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

      _log('[StorageService] Imported data successfully');
      return true;
    } catch (e) {
      _log('[StorageService] Failed to import data: $e');
      return false;
    }
  }

  /// Mark tutorial as completed
  Future<void> setTutorialCompleted(bool completed) async {
    if (!isReady) return;
    await _prefs!.setBool(_keyTutorialCompleted, completed);
    _log('[StorageService] Tutorial completion set to: $completed');
  }

  /// Check if tutorial has been completed
  bool isTutorialCompleted() {
    if (!isReady) return false;
    return _prefs!.getBool(_keyTutorialCompleted) ?? false;
  }
}
