import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bored_games/src/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
  });

  setUp(() async {
    await StorageService.instance.clearAll();
  });

  test('methods are safe before initialization', () async {
    StorageService.instance.resetForTesting();
    await StorageService.instance.saveLevelProgress(
      levelId: 1,
      completed: false,
      stars: 0,
      highScore: 0,
      bestWave: 0,
    );
    await StorageService.instance.saveUnlockedLevels({1});
    await StorageService.instance.saveSettings(
      musicVolume: 0.2,
      sfxVolume: 0.2,
      showFps: false,
      showGrid: false,
      screenShake: false,
      particleIntensity: 0.0,
      graphicsQuality: 'low',
    );
    await StorageService.instance.saveQualitySettings(
      preset: 'low',
      autoQuality: false,
    );
    await StorageService.instance.saveMetaCurrency(4);
    await StorageService.instance.saveUpgradeLevels({'core': 1});
    await StorageService.instance.saveStats(
      totalScore: 0,
      totalEnemiesKilled: 0,
      totalTowersPlaced: 0,
      totalPulsesUsed: 0,
      totalGamesPlayed: 0,
      totalVictories: 0,
      totalPlayTime: Duration.zero,
    );
    await StorageService.instance.clearAll();
    await StorageService.instance.clearProgress();

    expect(StorageService.instance.loadLevelProgress(1), isNull);
    expect(StorageService.instance.loadAllLevelProgress(), isEmpty);
    expect(StorageService.instance.loadUnlockedLevels(), {1});
    expect(StorageService.instance.loadSettings(), isNull);
    expect(StorageService.instance.loadQualitySettings(), isNull);
    expect(StorageService.instance.loadMetaCurrency(), 0);
    expect(StorageService.instance.loadUpgradeLevels(), isEmpty);
    expect(StorageService.instance.loadStats(), isNull);
    expect(StorageService.instance.exportData(), '{}');
    final ok = await StorageService.instance.importData('{"a":1}');
    expect(ok, isFalse);

    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
  });

  test('initialize failure leaves storage not ready', () async {
    StorageService.forceInitFailure = true;
    StorageService.instance.resetForTesting();
    await StorageService.instance.initialize();
    expect(StorageService.instance.isReady, isFalse);
    StorageService.forceInitFailure = false;
    await StorageService.instance.initialize();
    expect(StorageService.instance.isReady, isTrue);
  });

  test('saves and loads meta currency and upgrade levels', () async {
    await StorageService.instance.saveMetaCurrency(42);
    await StorageService.instance.saveUpgradeLevels({'core': 2, 'range': 1});

    expect(StorageService.instance.loadMetaCurrency(), 42);
    expect(StorageService.instance.loadUpgradeLevels(), {
      'core': 2,
      'range': 1,
    });
  });

  test('saves and loads level progress and unlocked levels', () async {
    await StorageService.instance.saveLevelProgress(
      levelId: 2,
      completed: true,
      stars: 3,
      highScore: 900,
      bestWave: 12,
    );

    await StorageService.instance.saveUnlockedLevels({1, 2, 3});
    final progress = StorageService.instance.loadLevelProgress(2);
    expect(progress?['completed'], isTrue);
    expect(progress?['stars'], 3);

    final unlocked = StorageService.instance.loadUnlockedLevels();
    expect(unlocked.contains(1), isTrue);
    expect(unlocked.contains(3), isTrue);

    final allProgress = StorageService.instance.loadAllLevelProgress();
    expect(allProgress.containsKey(2), isTrue);
  });

  test('saves and loads settings, quality, and stats', () async {
    await StorageService.instance.saveSettings(
      musicVolume: 0.5,
      sfxVolume: 0.7,
      showFps: true,
      showGrid: false,
      screenShake: true,
      particleIntensity: 1.0,
      graphicsQuality: 'high',
    );
    await StorageService.instance.saveQualitySettings(
      preset: 'medium',
      autoQuality: true,
    );
    await StorageService.instance.saveStats(
      totalScore: 1000,
      totalEnemiesKilled: 25,
      totalTowersPlaced: 5,
      totalPulsesUsed: 3,
      totalGamesPlayed: 2,
      totalVictories: 1,
      totalPlayTime: const Duration(seconds: 90),
    );

    final settings = StorageService.instance.loadSettings();
    expect(settings?['musicVolume'], 0.5);
    expect(settings?['screenShake'], isTrue);
    expect(settings?['particleIntensity'], 1.0);
    expect(settings?['graphicsQuality'], 'high');

    final quality = StorageService.instance.loadQualitySettings();
    expect(quality?['preset'], 'medium');
    expect(quality?['autoQuality'], isTrue);

    final stats = StorageService.instance.loadStats();
    expect(stats?['totalScore'], 1000);
    expect(stats?['totalPlayTimeSeconds'], 90);
  });

  test('loaders return defaults on invalid JSON', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('level_progress_9', '{bad json');
    await prefs.setString('unlocked_levels', '{bad json');
    await prefs.setString('game_settings', '{bad json');
    await prefs.setString('quality_settings', '{bad json');
    await prefs.setString('upgrade_levels', '{bad json');
    await prefs.setString('game_stats', '{bad json');

    expect(StorageService.instance.loadLevelProgress(9), isNull);
    expect(StorageService.instance.loadUnlockedLevels(), {1});
    expect(StorageService.instance.loadSettings(), isNull);
    expect(StorageService.instance.loadQualitySettings(), isNull);
    expect(StorageService.instance.loadUpgradeLevels(), isEmpty);
    expect(StorageService.instance.loadStats(), isNull);
  });

  test('export and import data round trip', () async {
    await StorageService.instance.saveMetaCurrency(12);
    await StorageService.instance.saveUnlockedLevels({1, 2});
    final exportJson = StorageService.instance.exportData();
    await StorageService.instance.clearAll();

    final ok = await StorageService.instance.importData(exportJson);
    expect(ok, isTrue);

    final exported = jsonDecode(StorageService.instance.exportData()) as Map<String, dynamic>;
    expect(exported.isNotEmpty, isTrue);
    expect(StorageService.instance.loadMetaCurrency(), 12);
    expect(StorageService.instance.loadUnlockedLevels().contains(2), isTrue);
  });

  test('importData handles list values', () async {
    final ok = await StorageService.instance.importData(
      jsonEncode({'list': [1, 2, 3], 'ratio': 0.5, 'flag': true}),
    );
    expect(ok, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('list'), ['1', '2', '3']);
    expect(prefs.getDouble('ratio'), 0.5);
    expect(prefs.getBool('flag'), isTrue);
  });

  test('importData returns false on invalid JSON', () async {
    final ok = await StorageService.instance.importData('{bad json');
    expect(ok, isFalse);
  });

  test('clearProgress keeps settings but removes progress and stats', () async {
    await StorageService.instance.saveSettings(
      musicVolume: 0.2,
      sfxVolume: 0.4,
      showFps: false,
      showGrid: true,
      screenShake: false,
      particleIntensity: 0.3,
      graphicsQuality: 'medium',
    );
    await StorageService.instance.saveLevelProgress(
      levelId: 1,
      completed: true,
      stars: 2,
      highScore: 500,
      bestWave: 6,
    );
    await StorageService.instance.saveStats(
      totalScore: 500,
      totalEnemiesKilled: 5,
      totalTowersPlaced: 2,
      totalPulsesUsed: 1,
      totalGamesPlayed: 1,
      totalVictories: 0,
      totalPlayTime: const Duration(seconds: 30),
    );
    await StorageService.instance.saveUnlockedLevels({1, 2});

    await StorageService.instance.clearProgress();

    expect(StorageService.instance.loadSettings(), isNotNull);
    expect(StorageService.instance.loadStats(), isNull);
    expect(StorageService.instance.loadLevelProgress(1), isNull);
    expect(StorageService.instance.loadUnlockedLevels(), {1});
  });

  test('tutorial completion defaults to false and can be toggled', () async {
    expect(StorageService.instance.isTutorialCompleted(), isFalse);

    await StorageService.instance.setTutorialCompleted(true);
    expect(StorageService.instance.isTutorialCompleted(), isTrue);

    await StorageService.instance.setTutorialCompleted(false);
    expect(StorageService.instance.isTutorialCompleted(), isFalse);
  });

  test('tutorial completion methods are safe before initialization', () async {
    StorageService.instance.resetForTesting();

    await StorageService.instance.setTutorialCompleted(true);
    expect(StorageService.instance.isTutorialCompleted(), isFalse);

    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
  });

  test('loadUnlockedLevels can exclude level 1 when include flag disabled', () async {
    final originalFlag = StorageService.includeLevelOneAlways;
    addTearDown(() => StorageService.includeLevelOneAlways = originalFlag);

    StorageService.includeLevelOneAlways = false;
    await StorageService.instance.saveUnlockedLevels({2, 3});

    expect(StorageService.instance.loadUnlockedLevels(), {2, 3});
  });
}
