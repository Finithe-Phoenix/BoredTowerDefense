import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bored_games/src/services/level_service.dart';
import 'package:bored_games/src/services/storage_service.dart';
import 'package:bored_games/src/services/upgrade_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
    await UpgradeService.instance.initialize();
    await LevelService.instance.initialize();
  });

  setUp(() async {
    await LevelService.instance.resetProgress();
  });

  test('level 1 is unlocked by default', () {
    expect(LevelService.instance.isLevelUnlocked(1), isTrue);
  });

  test('locked levels stay locked until prerequisite completed', () {
    expect(LevelService.instance.isLevelUnlocked(2), isFalse);
    expect(LevelService.instance.isLevelUnlocked(3), isFalse);
  });

  test('completing a level unlocks the next level', () async {
    await LevelService.instance.updateProgress(
      levelId: 1,
      completed: true,
      score: 1234,
      wavesCleared: 5,
      livesRemaining: 10,
      maxLives: 10,
    );

    expect(LevelService.instance.isLevelUnlocked(2), isTrue);
  });

  test('perfect clear awards 3 stars', () async {
    await LevelService.instance.updateProgress(
      levelId: 1,
      completed: true,
      score: 1500,
      wavesCleared: 5,
      livesRemaining: 10,
      maxLives: 10,
    );

    final progress = LevelService.instance.getProgress(1);
    expect(progress.stars, 3);
  });

  test('aggregated totals update with progress', () async {
    await LevelService.instance.updateProgress(
      levelId: 1,
      completed: true,
      score: 1000,
      wavesCleared: 5,
      livesRemaining: 8,
      maxLives: 10,
    );
    await LevelService.instance.updateProgress(
      levelId: 2,
      completed: false,
      score: 300,
      wavesCleared: 3,
      livesRemaining: 0,
      maxLives: 10,
    );

    expect(LevelService.instance.totalStars, greaterThanOrEqualTo(1));
    expect(LevelService.instance.maxStars, LevelService.instance.levels.length * 3);
    expect(LevelService.instance.completedLevels, 1);
    expect(LevelService.instance.totalHighScore, greaterThanOrEqualTo(1000));
  });

  test('resetProgress clears unlocked levels except level 1', () async {
    await LevelService.instance.updateProgress(
      levelId: 1,
      completed: true,
      score: 400,
      wavesCleared: 3,
      livesRemaining: 5,
      maxLives: 10,
    );
    expect(LevelService.instance.isLevelUnlocked(2), isTrue);

    await LevelService.instance.resetProgress();
    expect(LevelService.instance.isLevelUnlocked(2), isFalse);
    expect(LevelService.instance.completedLevels, 0);
  });

  test('unlockAllLevels override unlocks every level', () async {
    LevelService.overrideUnlockAllLevels = true;
    LevelService.instance.resetForTesting();
    await LevelService.instance.initialize();

    expect(LevelService.instance.isLevelUnlocked(50), isTrue);
    await LevelService.instance.resetProgress();
    expect(LevelService.instance.isLevelUnlocked(75), isTrue);

    LevelService.overrideUnlockAllLevels = null;
    await LevelService.instance.resetProgress();
  });

  test('loadProgress restores stored progress and ensures level 1', () async {
    StorageService.includeLevelOneAlways = false;
    await StorageService.instance.clearAll();
    await StorageService.instance.saveUnlockedLevels({2});
    await StorageService.instance.saveLevelProgress(
      levelId: 2,
      completed: true,
      stars: 2,
      highScore: 1200,
      bestWave: 6,
    );

    LevelService.instance.resetForTesting();
    await LevelService.instance.initialize();

    expect(LevelService.instance.isLevelUnlocked(1), isTrue);
    expect(LevelService.instance.getProgress(2).completed, isTrue);
    StorageService.includeLevelOneAlways = true;
  });

  test('getLevel returns null for missing level', () {
    final missing = LevelService.instance.getLevel(9999);
    expect(missing, isNull);
  });

  test('isLevelUnlocked throws for unknown level id', () {
    expect(() => LevelService.instance.isLevelUnlocked(9999), throwsArgumentError);
  });
}
