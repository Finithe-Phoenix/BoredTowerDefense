import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/data/world_chronicles.dart';

void main() {
  group('WorldChronicle class', () {
    test('has required properties', () {
      expect(worldChronicle1.worldId, 1);
      expect(worldChronicle1.name, isNotEmpty);
      expect(worldChronicle1.codename, isNotEmpty);
      expect(worldChronicle1.subtitle, isNotEmpty);
      expect(worldChronicle1.accentColor, isA<Color>());
      expect(worldChronicle1.secondaryColor, isA<Color>());
      expect(worldChronicle1.epoch, isNotEmpty);
      expect(worldChronicle1.chapters, isNotEmpty);
      expect(worldChronicle1.ambientDescriptions, isNotEmpty);
      expect(worldChronicle1.openingCinematic, isNotEmpty);
      expect(worldChronicle1.closingQuote, isNotEmpty);
      expect(worldChronicle1.narrator, isA<ChronicleCharacter>());
    });
  });

  group('ChronicleChapter class', () {
    test('has required properties', () {
      final chapter = worldChronicle1.chapters.first;
      expect(chapter.index, greaterThan(0));
      expect(chapter.title, isNotEmpty);
      expect(chapter.subtitle, isNotEmpty);
      expect(chapter.paragraphs, isNotEmpty);
      expect(chapter.mood, isA<ChapterMood>());
      expect(chapter.visualCues, isNotEmpty);
    });

    test('chapters are properly ordered', () {
      for (final chronicle in allWorldChronicles) {
        for (int i = 0; i < chronicle.chapters.length; i++) {
          expect(chronicle.chapters[i].index, i + 1);
        }
      }
    });
  });

  group('ChronicleCharacter class', () {
    test('narrator has correct properties', () {
      expect(ChronicleCharacters.narrator.id, 'narrator');
      expect(ChronicleCharacters.narrator.name, isNotEmpty);
      expect(ChronicleCharacters.narrator.title, isNotEmpty);
      expect(ChronicleCharacters.narrator.color, isA<Color>());
      expect(ChronicleCharacters.narrator.prefix, isNotEmpty);
    });

    test('architect has correct properties', () {
      expect(ChronicleCharacters.architect.id, 'architect');
      expect(ChronicleCharacters.architect.name, 'EL ARQUITECTO');
    });

    test('aria has correct properties', () {
      expect(ChronicleCharacters.aria.id, 'aria');
      expect(ChronicleCharacters.aria.name, 'A.R.I.A.');
    });

    test('decompiler has correct properties', () {
      expect(ChronicleCharacters.decompiler.id, 'decompiler');
      expect(ChronicleCharacters.decompiler.name, 'EL DECOMPILER');
    });

    test('echo7 has correct properties', () {
      expect(ChronicleCharacters.echo7.id, 'echo7');
      expect(ChronicleCharacters.echo7.name, 'ECO-7');
    });

    test('primeArchitect has correct properties', () {
      expect(ChronicleCharacters.primeArchitect.id, 'prime');
      expect(ChronicleCharacters.primeArchitect.name, 'ARQUITECTO PRIME');
    });
  });

  group('ChapterMood enum', () {
    test('has all expected mood types', () {
      expect(ChapterMood.values, contains(ChapterMood.epic));
      expect(ChapterMood.values, contains(ChapterMood.mysterious));
      expect(ChapterMood.values, contains(ChapterMood.dark));
      expect(ChapterMood.values, contains(ChapterMood.hopeful));
      expect(ChapterMood.values, contains(ChapterMood.tragic));
      expect(ChapterMood.values, contains(ChapterMood.revelation));
      expect(ChapterMood.values, contains(ChapterMood.action));
      expect(ChapterMood.values, contains(ChapterMood.philosophical));
      expect(ChapterMood.values, contains(ChapterMood.horror));
      expect(ChapterMood.values, contains(ChapterMood.triumphant));
    });

    test('has 10 mood types', () {
      expect(ChapterMood.values.length, 10);
    });
  });

  group('allWorldChronicles', () {
    test('contains chronicles', () {
      expect(allWorldChronicles, isNotEmpty);
    });

    test('all chronicles have valid world IDs', () {
      for (final chronicle in allWorldChronicles) {
        expect(chronicle.worldId, greaterThan(0));
      }
    });

    test('all chronicles have chapters', () {
      for (final chronicle in allWorldChronicles) {
        expect(chronicle.chapters, isNotEmpty);
        expect(chronicle.chapters.length, greaterThanOrEqualTo(1));
      }
    });

    test('all chronicles have ambient descriptions', () {
      for (final chronicle in allWorldChronicles) {
        expect(chronicle.ambientDescriptions, isNotEmpty);
      }
    });

    test('all chapters have paragraphs', () {
      for (final chronicle in allWorldChronicles) {
        for (final chapter in chronicle.chapters) {
          expect(chapter.paragraphs, isNotEmpty);
        }
      }
    });

    test('all chapters have visual cues', () {
      for (final chronicle in allWorldChronicles) {
        for (final chapter in chronicle.chapters) {
          expect(chapter.visualCues, isNotEmpty);
        }
      }
    });
  });

  group('getChronicleByWorldId', () {
    test('returns chronicle for valid world ID', () {
      final chronicle = getChronicleByWorldId(1);
      expect(chronicle, isNotNull);
      expect(chronicle!.worldId, 1);
      expect(chronicle.name, 'NEON FRONTIER');
    });

    test('returns null for invalid world ID', () {
      final chronicle = getChronicleByWorldId(999);
      expect(chronicle, isNull);
    });

    test('returns correct chronicle for each world', () {
      expect(getChronicleByWorldId(1)?.name, 'NEON FRONTIER');
      expect(getChronicleByWorldId(2)?.name, 'RIFT WARS');
      expect(getChronicleByWorldId(3)?.name, 'SIGNAL WASTES');
      expect(getChronicleByWorldId(4)?.name, 'ION CROWN');
      expect(getChronicleByWorldId(5)?.name, 'SHARD VAULT');
      expect(getChronicleByWorldId(10)?.name, 'FINAL GATE');
    });
  });

  group('WorldChronicles static accessor', () {
    test('all returns all chronicles', () {
      expect(WorldChronicles.all, allWorldChronicles);
      expect(WorldChronicles.all, isNotEmpty);
    });

    test('getChronicle returns chronicle for valid ID', () {
      final chronicle = WorldChronicles.getChronicle(1);
      expect(chronicle, isNotNull);
      expect(chronicle!.worldId, 1);
    });

    test('getChronicle returns null for invalid ID', () {
      final chronicle = WorldChronicles.getChronicle(999);
      expect(chronicle, isNull);
    });
  });

  group('World 1: NEON FRONTIER', () {
    test('has correct basic info', () {
      expect(worldChronicle1.worldId, 1);
      expect(worldChronicle1.name, 'NEON FRONTIER');
      expect(worldChronicle1.codename, 'SECTOR_ZERO');
    });

    test('has 5 chapters', () {
      expect(worldChronicle1.chapters.length, 5);
    });

    test('chapter 1 is EL DESPERTAR', () {
      expect(worldChronicle1.chapters[0].title, 'EL DESPERTAR');
      expect(worldChronicle1.chapters[0].mood, ChapterMood.mysterious);
    });
  });

  group('World 2: RIFT WARS', () {
    test('has correct basic info', () {
      expect(worldChronicle2.worldId, 2);
      expect(worldChronicle2.name, 'RIFT WARS');
      expect(worldChronicle2.codename, 'TEMPORAL_FRACTURE');
    });

    test('has 5 chapters', () {
      expect(worldChronicle2.chapters.length, 5);
    });
  });

  group('World 3: SIGNAL WASTES', () {
    test('has correct basic info', () {
      expect(worldChronicle3.worldId, 3);
      expect(worldChronicle3.name, 'SIGNAL WASTES');
      expect(worldChronicle3.codename, 'SILENT_ZONE');
    });

    test('has 5 chapters', () {
      expect(worldChronicle3.chapters.length, 5);
    });
  });

  group('World 4: ION CROWN', () {
    test('has correct basic info', () {
      expect(worldChronicle4.worldId, 4);
      expect(worldChronicle4.name, 'ION CROWN');
      expect(worldChronicle4.codename, 'STORM_CITADEL');
    });

    test('has 5 chapters', () {
      expect(worldChronicle4.chapters.length, 5);
    });
  });

  group('World 5: SHARD VAULT', () {
    test('has correct basic info', () {
      expect(worldChronicle5.worldId, 5);
      expect(worldChronicle5.name, 'SHARD VAULT');
      expect(worldChronicle5.codename, 'MEMORY_SANCTUM');
    });

    test('has 5 chapters', () {
      expect(worldChronicle5.chapters.length, 5);
    });
  });

  group('World 6 (10): FINAL GATE', () {
    test('has correct basic info', () {
      expect(worldChronicle6.worldId, 10);
      expect(worldChronicle6.name, 'FINAL GATE');
      expect(worldChronicle6.codename, 'CORE_NEXUS');
    });

    test('has 5 chapters', () {
      expect(worldChronicle6.chapters.length, 5);
    });

    test('final chapter has hopeful mood', () {
      final lastChapter = worldChronicle6.chapters.last;
      expect(lastChapter.mood, ChapterMood.hopeful);
    });
  });

  group('Chapter moods throughout chronicles', () {
    test('world 1 has varied moods', () {
      final moods = worldChronicle1.chapters.map((c) => c.mood).toSet();
      expect(moods.length, greaterThan(1));
    });

    test('all chapters have a mood', () {
      for (final chronicle in allWorldChronicles) {
        for (final chapter in chronicle.chapters) {
          expect(chapter.mood, isNotNull);
          expect(ChapterMood.values, contains(chapter.mood));
        }
      }
    });
  });

  group('Optional chapter properties', () {
    test('some chapters have speakers', () {
      bool foundSpeaker = false;
      for (final chronicle in allWorldChronicles) {
        for (final chapter in chronicle.chapters) {
          if (chapter.speaker != null) {
            foundSpeaker = true;
            expect(chapter.speaker!.id, isNotEmpty);
          }
        }
      }
      expect(foundSpeaker, isTrue);
    });

    test('some chapters have interludes', () {
      bool foundInterlude = false;
      for (final chronicle in allWorldChronicles) {
        for (final chapter in chronicle.chapters) {
          if (chapter.interlude != null) {
            foundInterlude = true;
            expect(chapter.interlude, isNotEmpty);
          }
        }
      }
      expect(foundInterlude, isTrue);
    });
  });
}
