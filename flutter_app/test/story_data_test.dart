import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/data/story_data.dart';

void main() {
  group('StoryData', () {
    test('story data lookups return expected entries', () {
      final world = StoryData.worlds.first;
      expect(world.id, 1);
      expect(StoryData.getCinematic('prologue'), isNotNull);
      expect(StoryData.getCinematic('missing'), isNull);
      expect(StoryData.getEnemyProfile('runner'), isNotNull);
      expect(StoryData.getEnemyProfile('missing'), isNull);
    });

    test('worlds list is not empty', () {
      expect(StoryData.worlds, isNotEmpty);
      expect(StoryData.worlds.length, greaterThanOrEqualTo(5));
    });

    test('each world has required fields', () {
      for (final world in StoryData.worlds) {
        expect(world.id, greaterThan(0));
        expect(world.name, isNotEmpty);
        expect(world.subtitle, isNotEmpty);
        expect(world.description, isNotEmpty);
        expect(world.atmosphere, isNotEmpty);
        expect(world.threat, isNotEmpty);
        expect(world.objective, isNotEmpty);
        expect(world.narrativeBeats, isNotEmpty);
        expect(world.loreEntries, isNotEmpty);
      }
    });

    test('getWorldById returns correct world', () {
      final world1 = StoryData.getWorldById(1);
      expect(world1, isNotNull);
      expect(world1!.name, 'NEON FRONTIER');

      final world2 = StoryData.getWorldById(2);
      expect(world2, isNotNull);
      expect(world2!.name, 'RIFT WARS');
    });

    test('getWorldById returns null for non-existent world', () {
      final world = StoryData.getWorldById(999);
      expect(world, isNull);
    });

    test('getBriefingForLevel returns briefing', () {
      final briefing1 = StoryData.getBriefingForLevel(1);
      expect(briefing1, isNotNull);
      expect(briefing1!.levelId, 1);
      expect(briefing1.title, isNotEmpty);
    });

    test('getBriefingForLevel returns null for level without briefing', () {
      final briefing = StoryData.getBriefingForLevel(999);
      expect(briefing, isNull);
    });
  });

  group('StoryData memory fragments', () {
    test('memory fragments unlock by level', () {
      final low = StoryData.getUnlockedMemories(1);
      final mid = StoryData.getUnlockedMemories(20);
      final high = StoryData.getUnlockedMemories(100);

      expect(low.isNotEmpty, isTrue);
      expect(mid.length >= low.length, isTrue);
      expect(high.length >= mid.length, isTrue);
    });

    test('all memory fragments have required fields', () {
      final memories = StoryData.getUnlockedMemories(100);
      for (final memory in memories) {
        expect(memory.id, isNotEmpty);
        expect(memory.title, isNotEmpty);
        expect(memory.cycle, isNotEmpty);
        expect(memory.content, isNotEmpty);
        expect(memory.speaker, isNotNull);
        expect(memory.unlockLevel, greaterThan(0));
      }
    });

    test('memory fragments can be filtered by unlock level', () {
      final allMemories = StoryData.getUnlockedMemories(100);
      final earlyMemories = StoryData.getUnlockedMemories(5);

      // Early memories should be subset of all memories
      expect(earlyMemories.length, lessThanOrEqualTo(allMemories.length));

      // All early memories should be unlocked at or before level 5
      for (final memory in earlyMemories) {
        expect(memory.unlockLevel, lessThanOrEqualTo(5));
      }
    });
  });

  group('StoryData enemy profiles', () {
    test('all expected enemies exist', () {
      expect(StoryData.getEnemyProfile('runner'), isNotNull);
      expect(StoryData.getEnemyProfile('tank'), isNotNull);
      expect(StoryData.getEnemyProfile('phantom'), isNotNull);
      expect(StoryData.getEnemyProfile('overloaded'), isNotNull);
      expect(StoryData.getEnemyProfile('splitter'), isNotNull);
      expect(StoryData.getEnemyProfile('healer'), isNotNull);
    });

    test('enemy profiles have required fields', () {
      final runner = StoryData.getEnemyProfile('runner')!;
      expect(runner.name, isNotEmpty);
      expect(runner.classification, isNotEmpty);
      expect(runner.description, isNotEmpty);
      expect(runner.origin, isNotEmpty);
      expect(runner.weakness, isNotEmpty);
      expect(runner.dangerLevel, inInclusiveRange(1, 10));
    });

    test('final boss has highest danger level', () {
      final boss = StoryData.getEnemyProfile('final_boss')!;
      expect(boss.dangerLevel, 10);
      expect(boss.name, 'OMEGA NEXUS');
    });
  });

  group('StoryData cinematics', () {
    test('prologue cinematic exists', () {
      final prologue = StoryData.getCinematic('prologue');
      expect(prologue, isNotNull);
      expect(prologue!.id, 'prologue');
      expect(prologue.title, isNotEmpty);
      expect(prologue.scenes, isNotEmpty);
    });

    test('cinematics have scenes with lines', () {
      final prologue = StoryData.getCinematic('prologue')!;
      for (final scene in prologue.scenes) {
        expect(scene.title, isNotEmpty);
        expect(scene.lines, isNotEmpty);
        for (final line in scene.lines) {
          expect(line.text, isNotEmpty);
        }
      }
    });

    test('getCinematic returns null for missing id', () {
      final missing = StoryData.getCinematic('non_existent');
      expect(missing, isNull);
    });
  });

  group('StoryData lore entries', () {
    test('getUnlockedLore returns entries by level', () {
      final low = StoryData.getUnlockedLore(1);
      final high = StoryData.getUnlockedLore(100);

      expect(low, isNotEmpty);
      expect(high.length, greaterThanOrEqualTo(low.length));
    });

    test('lore entries are sorted by unlock level', () {
      final lore = StoryData.getUnlockedLore(100);
      for (int i = 1; i < lore.length; i++) {
        expect(
          lore[i].unlockLevel >= lore[i - 1].unlockLevel,
          isTrue,
        );
      }
    });
  });

  group('LoreCategory', () {
    test('lore category names are non-empty', () {
      for (final category in LoreCategory.values) {
        final entry = LoreEntry(
          id: 'id',
          title: 'title',
          category: category,
          content: 'content',
          unlockLevel: 1,
          accentColor: const Color(0xFF000000),
        );
        expect(entry.categoryName.isNotEmpty, isTrue);
      }
    });

    test('each category has unique name', () {
      final names = <String>{};
      for (final category in LoreCategory.values) {
        final entry = LoreEntry(
          id: 'id',
          title: 'title',
          category: category,
          content: 'content',
          unlockLevel: 1,
          accentColor: const Color(0xFF000000),
        );
        names.add(entry.categoryName);
      }
      expect(names.length, LoreCategory.values.length);
    });

    test('all categories return Spanish names', () {
      final entry = LoreEntry(
        id: 'id',
        title: 'title',
        category: LoreCategory.systemLogs,
        content: 'content',
        unlockLevel: 1,
        accentColor: const Color(0xFF000000),
      );
      expect(entry.categoryName, 'LOGS DEL SISTEMA');

      final entry2 = LoreEntry(
        id: 'id',
        title: 'title',
        category: LoreCategory.secrets,
        content: 'content',
        unlockLevel: 1,
        accentColor: const Color(0xFF000000),
      );
      expect(entry2.categoryName, 'SECRETOS');
    });
  });

  group('BriefingMood', () {
    test('all mood values exist', () {
      expect(BriefingMood.values, contains(BriefingMood.urgent));
      expect(BriefingMood.values, contains(BriefingMood.analytical));
      expect(BriefingMood.values, contains(BriefingMood.worried));
      expect(BriefingMood.values, contains(BriefingMood.serious));
      expect(BriefingMood.values, contains(BriefingMood.mysterious));
      expect(BriefingMood.values, contains(BriefingMood.hopeful));
      expect(BriefingMood.values, contains(BriefingMood.epic));
      expect(BriefingMood.values, contains(BriefingMood.dark));
    });
  });

  group('CinematicVisual', () {
    test('all visual types exist', () {
      expect(CinematicVisual.values, contains(CinematicVisual.characterReveal));
      expect(CinematicVisual.values, contains(CinematicVisual.locationPan));
      expect(CinematicVisual.values, contains(CinematicVisual.dataStream));
      expect(CinematicVisual.values, contains(CinematicVisual.corruption));
      expect(CinematicVisual.values, contains(CinematicVisual.memory));
      expect(CinematicVisual.values, contains(CinematicVisual.battle));
      expect(CinematicVisual.values, contains(CinematicVisual.void_));
    });
  });

  group('Character', () {
    test('main characters are defined', () {
      expect(StoryData.architect.id, 'architect');
      expect(StoryData.architect.name, isNotEmpty);

      expect(StoryData.aria.id, 'aria');
      expect(StoryData.aria.name, isNotEmpty);

      expect(StoryData.decompiler.id, 'decompiler');
      expect(StoryData.decompiler.name, isNotEmpty);

      expect(StoryData.echo.id, 'echo');
      expect(StoryData.echo.name, isNotEmpty);
    });

    test('characters have dialogue prefix', () {
      expect(StoryData.architect.dialoguePrefix, isNotEmpty);
      expect(StoryData.aria.dialoguePrefix, isNotEmpty);
      expect(StoryData.decompiler.dialoguePrefix, isNotEmpty);
      expect(StoryData.echo.dialoguePrefix, isNotEmpty);
    });
  });

  group('Data classes', () {
    test('DialogueLine can be created', () {
      const line = DialogueLine(
        speaker: StoryData.aria,
        text: 'Test message',
        mood: BriefingMood.analytical,
      );
      expect(line.speaker.id, 'aria');
      expect(line.text, 'Test message');
      expect(line.mood, BriefingMood.analytical);
    });

    test('CinematicLine can be created with optional speaker', () {
      const lineWithSpeaker = CinematicLine(
        speaker: StoryData.architect,
        text: 'With speaker',
        mood: BriefingMood.serious,
      );
      expect(lineWithSpeaker.speaker, isNotNull);

      const lineWithoutSpeaker = CinematicLine(
        text: 'Narration',
        mood: BriefingMood.mysterious,
      );
      expect(lineWithoutSpeaker.speaker, isNull);
    });

    test('MemoryFragment tracks corruption', () {
      final normal = StoryData.getUnlockedMemories(100)
          .firstWhere((m) => !m.isCorrupted);
      expect(normal.isCorrupted, isFalse);
    });
  });
}
