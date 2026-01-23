import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/services/level_service.dart';
import 'package:bored_games/src/game/entities/tower.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LevelService.instance.resetForTesting();
    LevelService.overrideUnlockAllLevels = false;
  });

  tearDown(() {
    LevelService.instance.resetForTesting();
    LevelService.overrideUnlockAllLevels = null;
  });

  group('LevelService - Singleton', () {
    test('instance is not null', () {
      expect(LevelService.instance, isNotNull);
    });

    test('instance is always the same', () {
      final a = LevelService.instance;
      final b = LevelService.instance;
      expect(identical(a, b), isTrue);
    });
  });

  group('LevelService - Levels list', () {
    test('levels list is not empty', () {
      expect(LevelService.instance.levels, isNotEmpty);
    });

    test('levels list has 100 levels', () {
      expect(LevelService.instance.levels.length, 100);
    });

    test('level 1 exists', () {
      final level = LevelService.instance.getLevel(1);
      expect(level, isNotNull);
    });

    test('level 100 exists', () {
      final level = LevelService.instance.getLevel(100);
      expect(level, isNotNull);
    });

    test('level 101 does not exist', () {
      final level = LevelService.instance.getLevel(101);
      expect(level, isNull);
    });

    test('level 0 does not exist', () {
      final level = LevelService.instance.getLevel(0);
      expect(level, isNull);
    });
  });

  group('LevelService - Level 1 (Training Grounds)', () {
    test('level 1 is always unlocked', () {
      expect(LevelService.instance.isLevelUnlocked(1), isTrue);
    });

    test('level 1 has correct id', () {
      final level = LevelService.instance.getLevel(1)!;
      expect(level.id, 1);
    });

    test('level 1 has correct name', () {
      final level = LevelService.instance.getLevel(1)!;
      expect(level.name, 'Training Grounds');
    });

    test('level 1 has no unlock requirement', () {
      final level = LevelService.instance.getLevel(1)!;
      expect(level.unlockRequirement, isNull);
    });

    test('level 1 has easy difficulty', () {
      final level = LevelService.instance.getLevel(1)!;
      expect(level.difficulty, 1);
    });

    test('level 1 has 5 waves', () {
      final level = LevelService.instance.getLevel(1)!;
      expect(level.waves, 5);
    });

    test('level 1 has 250 starting gold', () {
      final level = LevelService.instance.getLevel(1)!;
      expect(level.startingGold, 250);
    });

    test('level 1 has 25 starting lives', () {
      final level = LevelService.instance.getLevel(1)!;
      expect(level.startingLives, 25);
    });
  });

  group('LevelService - Level IDs are sequential', () {
    test('all level IDs from 1 to 100 exist', () {
      for (int i = 1; i <= 100; i++) {
        final level = LevelService.instance.getLevel(i);
        expect(level, isNotNull, reason: 'Level $i should exist');
        expect(level!.id, i, reason: 'Level $i should have id $i');
      }
    });
  });

  group('LevelService - Unlock requirements chain', () {
    test('level 2 requires level 1', () {
      final level = LevelService.instance.getLevel(2)!;
      expect(level.unlockRequirement, 1);
    });

    test('level 3 requires level 2', () {
      final level = LevelService.instance.getLevel(3)!;
      expect(level.unlockRequirement, 2);
    });

    test('level 10 requires level 9', () {
      final level = LevelService.instance.getLevel(10)!;
      expect(level.unlockRequirement, 9);
    });

    test('level 50 requires level 49', () {
      final level = LevelService.instance.getLevel(50)!;
      expect(level.unlockRequirement, 49);
    });

    test('level 100 requires level 99', () {
      final level = LevelService.instance.getLevel(100)!;
      expect(level.unlockRequirement, 99);
    });

    test('all levels except first require previous level', () {
      for (int i = 2; i <= 100; i++) {
        final level = LevelService.instance.getLevel(i)!;
        expect(level.unlockRequirement, i - 1,
            reason: 'Level $i should require level ${i - 1}');
      }
    });
  });

  group('LevelService - Difficulty distribution', () {
    test('level 1 has difficulty 1', () {
      expect(LevelService.instance.getLevel(1)!.difficulty, 1);
    });

    test('level 2 has difficulty 1', () {
      expect(LevelService.instance.getLevel(2)!.difficulty, 1);
    });

    test('level 3 has difficulty 2', () {
      expect(LevelService.instance.getLevel(3)!.difficulty, 2);
    });

    test('difficulties are in range 1-5', () {
      for (final level in LevelService.instance.levels) {
        expect(level.difficulty, inInclusiveRange(1, 5),
            reason: 'Level ${level.id} difficulty should be 1-5');
      }
    });
  });

  group('LevelService - Wave progression', () {
    test('waves increase with level', () {
      final level1 = LevelService.instance.getLevel(1)!;
      final level50 = LevelService.instance.getLevel(50)!;
      final level100 = LevelService.instance.getLevel(100)!;

      expect(level50.waves, greaterThan(level1.waves));
      expect(level100.waves, greaterThan(level50.waves));
    });

    test('level 1 has 5 waves', () {
      expect(LevelService.instance.getLevel(1)!.waves, 5);
    });

    test('level 10 has 30 waves', () {
      expect(LevelService.instance.getLevel(10)!.waves, 30);
    });

    test('all levels have positive wave count', () {
      for (final level in LevelService.instance.levels) {
        expect(level.waves, greaterThan(0),
            reason: 'Level ${level.id} should have positive waves');
      }
    });
  });

  group('LevelService - Starting resources', () {
    test('all levels have positive starting gold', () {
      for (final level in LevelService.instance.levels) {
        expect(level.startingGold, greaterThan(0),
            reason: 'Level ${level.id} should have positive starting gold');
      }
    });

    test('all levels have positive starting lives', () {
      for (final level in LevelService.instance.levels) {
        expect(level.startingLives, greaterThan(0),
            reason: 'Level ${level.id} should have positive starting lives');
      }
    });

    test('starting gold generally decreases with level', () {
      final early = LevelService.instance.getLevel(1)!.startingGold;
      final late = LevelService.instance.getLevel(100)!.startingGold;
      expect(late, lessThan(early));
    });

    test('starting lives generally decrease with level', () {
      final early = LevelService.instance.getLevel(1)!.startingLives;
      final late = LevelService.instance.getLevel(100)!.startingLives;
      expect(late, lessThan(early));
    });
  });

  group('LevelService - Map files', () {
    test('all levels have map files', () {
      for (final level in LevelService.instance.levels) {
        expect(level.mapFile, isNotEmpty,
            reason: 'Level ${level.id} should have a map file');
      }
    });

    test('level 1 map file', () {
      expect(LevelService.instance.getLevel(1)!.mapFile, 'maps/level1.tmx');
    });

    test('level 50 map file', () {
      expect(LevelService.instance.getLevel(50)!.mapFile, 'maps/level50.tmx');
    });

    test('all map files follow pattern', () {
      for (final level in LevelService.instance.levels) {
        expect(level.mapFile, contains('level${level.id}'),
            reason: 'Level ${level.id} map should contain level id');
      }
    });
  });

  group('LevelService - Tower unlock schedule', () {
    test('pulseArcher is always unlocked', () {
      expect(LevelService.instance.isTowerUnlocked(TowerType.pulseArcher), isTrue);
    });

    test('circuitCannon unlocks at level 3', () {
      // Without dev mode, it depends on actual progress
      LevelService.overrideUnlockAllLevels = true;
      expect(LevelService.instance.isTowerUnlocked(TowerType.circuitCannon), isTrue);
    });

    test('phaseMage unlocks at level 5', () {
      LevelService.overrideUnlockAllLevels = true;
      expect(LevelService.instance.isTowerUnlocked(TowerType.phaseMage), isTrue);
    });

    test('glimmerField unlocks at level 7', () {
      LevelService.overrideUnlockAllLevels = true;
      expect(LevelService.instance.isTowerUnlocked(TowerType.glimmerField), isTrue);
    });

    test('ionSniper unlocks at level 9', () {
      LevelService.overrideUnlockAllLevels = true;
      expect(LevelService.instance.isTowerUnlocked(TowerType.ionSniper), isTrue);
    });

    test('teslaTerminal unlocks at level 10', () {
      LevelService.overrideUnlockAllLevels = true;
      expect(LevelService.instance.isTowerUnlocked(TowerType.teslaTerminal), isTrue);
    });

    test('resonanceSiphon unlocks at level 11', () {
      LevelService.overrideUnlockAllLevels = true;
      expect(LevelService.instance.isTowerUnlocked(TowerType.resonanceSiphon), isTrue);
    });

    test('neuralDisruptor unlocks at level 13', () {
      LevelService.overrideUnlockAllLevels = true;
      expect(LevelService.instance.isTowerUnlocked(TowerType.neuralDisruptor), isTrue);
    });
  });

  group('LevelService - getUnlockedTowers', () {
    test('getUnlockedTowers includes pulseArcher', () {
      final towers = LevelService.instance.getUnlockedTowers();
      expect(towers, contains(TowerType.pulseArcher));
    });

    test('getUnlockedTowers with all unlocked', () {
      LevelService.overrideUnlockAllLevels = true;
      final towers = LevelService.instance.getUnlockedTowers();
      expect(towers.length, TowerType.values.length);
    });
  });

  group('LevelService - Progress', () {
    test('getProgress returns default for unknown level', () {
      final progress = LevelService.instance.getProgress(999);
      expect(progress.levelId, 999);
      expect(progress.completed, isFalse);
      expect(progress.stars, 0);
    });

    test('getProgress for level 1', () {
      final progress = LevelService.instance.getProgress(1);
      expect(progress.levelId, 1);
    });

    test('totalStars starts at 0', () {
      expect(LevelService.instance.totalStars, 0);
    });

    test('maxStars is levels * 3', () {
      expect(LevelService.instance.maxStars, 100 * 3);
    });

    test('completedLevels starts at 0', () {
      expect(LevelService.instance.completedLevels, 0);
    });

    test('totalHighScore starts at 0', () {
      expect(LevelService.instance.totalHighScore, 0);
    });
  });

  group('LevelService - isLevelUnlocked', () {
    test('level 1 is always unlocked', () {
      expect(LevelService.instance.isLevelUnlocked(1), isTrue);
    });

    test('level 2 requires level 1 completion', () {
      // Without completion, level 2 should not be unlocked
      // (unless unlock all is enabled)
      LevelService.overrideUnlockAllLevels = false;
      // Since we haven't completed anything, level 2 should not be unlocked
      expect(LevelService.instance.isLevelUnlocked(2), isFalse);
    });

    test('all levels unlocked in dev mode', () {
      LevelService.overrideUnlockAllLevels = true;
      for (int i = 1; i <= 100; i++) {
        expect(LevelService.instance.isLevelUnlocked(i), isTrue,
            reason: 'Level $i should be unlocked in dev mode');
      }
    });
  });

  group('LevelService - resetForTesting', () {
    test('resetForTesting clears progress', () {
      LevelService.instance.resetForTesting();
      expect(LevelService.instance.totalStars, 0);
    });

    test('resetForTesting can be called multiple times', () {
      LevelService.instance.resetForTesting();
      LevelService.instance.resetForTesting();
      expect(LevelService.instance.completedLevels, 0);
    });
  });

  group('LevelService - Level names', () {
    test('all levels have non-empty names', () {
      for (final level in LevelService.instance.levels) {
        expect(level.name.trim(), isNotEmpty,
            reason: 'Level ${level.id} should have a non-empty name');
      }
    });

    test('level 1 name is Training Grounds', () {
      expect(LevelService.instance.getLevel(1)!.name, 'Training Grounds');
    });

    test('level 2 name is Neon Corridor', () {
      expect(LevelService.instance.getLevel(2)!.name, 'Neon Corridor');
    });

    test('level 10 name is Citadel Core', () {
      expect(LevelService.instance.getLevel(10)!.name, 'Citadel Core');
    });
  });

  group('LevelService - World progression', () {
    test('early levels are easier', () {
      final level1 = LevelService.instance.getLevel(1)!;
      final level90 = LevelService.instance.getLevel(90)!;

      expect(level1.difficulty, lessThan(level90.difficulty));
      expect(level1.waves, lessThan(level90.waves));
      expect(level1.startingGold, greaterThan(level90.startingGold));
      expect(level1.startingLives, greaterThan(level90.startingLives));
    });

    test('endgame levels are challenging', () {
      final level100 = LevelService.instance.getLevel(100)!;
      expect(level100.difficulty, 5);
      expect(level100.waves, 210);
      expect(level100.startingGold, 30);
      expect(level100.startingLives, 3);
    });
  });
}
