import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/screens/cinematic_screen.dart';
import 'package:bored_games/src/data/story_data.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';

void main() {
  // Create minimal test cinematic data
  final testCinematic = CinematicData(
    id: 'test',
    chapter: 1,
    title: 'TEST CINEMATIC',
    scenes: [
      CinematicScene(
        title: 'Scene One',
        backgroundColor: const Color(0xFF000510),
        accentColor: NeonColors.cyan,
        lines: [
          const CinematicLine(
            text: 'First line of dialogue.',
            mood: BriefingMood.mysterious,
          ),
          const CinematicLine(
            text: 'Second line.',
            mood: BriefingMood.epic,
          ),
        ],
      ),
      CinematicScene(
        title: 'Scene Two',
        backgroundColor: const Color(0xFF100005),
        accentColor: NeonColors.magenta,
        visualType: CinematicVisual.corruption,
        lines: [
          const CinematicLine(
            text: 'Third line.',
            mood: BriefingMood.dark,
          ),
        ],
      ),
    ],
  );

  group('CinematicScreen', () {
    testWidgets('renders cinematic screen', (tester) async {
      var completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CinematicScreen(
            cinematic: testCinematic,
            onComplete: () => completed = true,
          ),
        ),
      );

      expect(find.byType(CinematicScreen), findsOneWidget);
    });

    testWidgets('has scaffold with black background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CinematicScreen(
            cinematic: testCinematic,
            onComplete: () {},
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('shows scene title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CinematicScreen(
            cinematic: testCinematic,
            onComplete: () {},
          ),
        ),
      );

      // Pump for GlitchText animation (4 second duration)
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // GlitchText renders text progressively, check it contains 'Scene'
      expect(find.textContaining('Scene'), findsWidgets);
    });

    testWidgets('shows chapter indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CinematicScreen(
            cinematic: testCinematic,
            onComplete: () {},
          ),
        ),
      );

      // Pump for animation
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.textContaining('CAPÍTULO'), findsOneWidget);
    });

    testWidgets('uses GestureDetector for interaction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CinematicScreen(
            cinematic: testCinematic,
            onComplete: () {},
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('uses FadeTransition for effects', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CinematicScreen(
            cinematic: testCinematic,
            onComplete: () {},
          ),
        ),
      );

      expect(find.byType(FadeTransition), findsWidgets);
    });

    testWidgets('contains CustomPaint for graphics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CinematicScreen(
            cinematic: testCinematic,
            onComplete: () {},
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('uses Stack for layered content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CinematicScreen(
            cinematic: testCinematic,
            onComplete: () {},
          ),
        ),
      );

      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('uses SafeArea', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CinematicScreen(
            cinematic: testCinematic,
            onComplete: () {},
          ),
        ),
      );

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('animates over time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CinematicScreen(
            cinematic: testCinematic,
            onComplete: () {},
          ),
        ),
      );

      // Pump through animation frames
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(CinematicScreen), findsOneWidget);
    });

    testWidgets('can be disposed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CinematicScreen(
            cinematic: testCinematic,
            onComplete: () {},
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Replace widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('REPLACED')),
        ),
      );

      expect(find.byType(CinematicScreen), findsNothing);
    });

    testWidgets('tap advances line', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CinematicScreen(
            cinematic: testCinematic,
            onComplete: () {},
          ),
        ),
      );

      // Wait for initial animation
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Tap to advance
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(find.byType(CinematicScreen), findsOneWidget);
    });

    testWidgets('shows skip hint after delay', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CinematicScreen(
            cinematic: testCinematic,
            onComplete: () {},
          ),
        ),
      );

      // Wait for skip hint timer (3+ seconds)
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.textContaining('Toca'), findsWidgets);
    });

    testWidgets('shows progress indicators', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CinematicScreen(
            cinematic: testCinematic,
            onComplete: () {},
          ),
        ),
      );

      // Wait for animation
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Should show line count
      expect(find.textContaining('/'), findsWidgets);
    });
  });

  group('CinematicData', () {
    test('can be constructed', () {
      expect(testCinematic.id, 'test');
      expect(testCinematic.chapter, 1);
      expect(testCinematic.title, 'TEST CINEMATIC');
      expect(testCinematic.scenes.length, 2);
    });

    test('can have unlockCondition', () {
      const cinematicWithCondition = CinematicData(
        id: 'locked',
        chapter: 2,
        title: 'Locked',
        scenes: [],
        unlockCondition: 'Complete level 10',
      );
      expect(cinematicWithCondition.unlockCondition, isNotNull);
    });
  });

  group('CinematicScene', () {
    test('can have visualType', () {
      final sceneWithVisual = testCinematic.scenes[1];
      expect(sceneWithVisual.visualType, CinematicVisual.corruption);
    });

    test('can have focusCharacter', () {
      final sceneWithCharacter = CinematicScene(
        title: 'Test',
        backgroundColor: Colors.black,
        accentColor: NeonColors.cyan,
        focusCharacter: StoryData.architect,
        lines: [],
      );
      expect(sceneWithCharacter.focusCharacter, isNotNull);
      expect(sceneWithCharacter.focusCharacter!.name, 'EL ARQUITECTO');
    });
  });

  group('CinematicLine', () {
    test('can have speaker', () {
      const lineWithSpeaker = CinematicLine(
        speaker: StoryData.aria,
        text: 'Test',
        mood: BriefingMood.analytical,
      );
      expect(lineWithSpeaker.speaker, isNotNull);
      expect(lineWithSpeaker.speaker!.name, 'A.R.I.A.');
    });

    test('speaker is optional', () {
      const lineWithoutSpeaker = CinematicLine(
        text: 'Test',
        mood: BriefingMood.epic,
      );
      expect(lineWithoutSpeaker.speaker, isNull);
    });
  });

  group('CinematicVisual', () {
    test('has all expected values', () {
      expect(CinematicVisual.values, contains(CinematicVisual.characterReveal));
      expect(CinematicVisual.values, contains(CinematicVisual.locationPan));
      expect(CinematicVisual.values, contains(CinematicVisual.dataStream));
      expect(CinematicVisual.values, contains(CinematicVisual.corruption));
      expect(CinematicVisual.values, contains(CinematicVisual.memory));
    });
  });

  group('BriefingMood', () {
    test('has all expected values', () {
      expect(BriefingMood.values, contains(BriefingMood.urgent));
      expect(BriefingMood.values, contains(BriefingMood.analytical));
      expect(BriefingMood.values, contains(BriefingMood.worried));
      expect(BriefingMood.values, contains(BriefingMood.serious));
      expect(BriefingMood.values, contains(BriefingMood.mysterious));
      expect(BriefingMood.values, contains(BriefingMood.hopeful));
      expect(BriefingMood.values, contains(BriefingMood.surprised));
      expect(BriefingMood.values, contains(BriefingMood.emotional));
      expect(BriefingMood.values, contains(BriefingMood.epic));
      expect(BriefingMood.values, contains(BriefingMood.dark));
      expect(BriefingMood.values, contains(BriefingMood.sad));
      expect(BriefingMood.values, contains(BriefingMood.confused));
      expect(BriefingMood.values, contains(BriefingMood.revelation));
    });
  });

  group('StoryData', () {
    test('architect character has correct properties', () {
      expect(StoryData.architect.id, 'architect');
      expect(StoryData.architect.name, 'EL ARQUITECTO');
      expect(StoryData.architect.avatarColor, NeonColors.cyan);
    });

    test('aria character has correct properties', () {
      expect(StoryData.aria.id, 'aria');
      expect(StoryData.aria.name, 'A.R.I.A.');
      expect(StoryData.aria.avatarColor, NeonColors.green);
    });

    test('decompiler character has correct properties', () {
      expect(StoryData.decompiler.id, 'decompiler');
      expect(StoryData.decompiler.name, 'EL DECOMPILER');
      expect(StoryData.decompiler.avatarColor, NeonColors.magenta);
    });

    test('echo character has correct properties', () {
      expect(StoryData.echo.id, 'echo');
      expect(StoryData.echo.name, 'ECO-7');
      expect(StoryData.echo.avatarColor, NeonColors.yellow);
    });

    test('worlds list is not empty', () {
      expect(StoryData.worlds, isNotEmpty);
      expect(StoryData.worlds.length, greaterThanOrEqualTo(6));
    });

    test('levelBriefings map is not empty', () {
      expect(StoryData.levelBriefings, isNotEmpty);
    });

    test('loreEntries map is not empty', () {
      expect(StoryData.loreEntries, isNotEmpty);
    });

    test('cinematics map is not empty', () {
      expect(StoryData.cinematics, isNotEmpty);
    });

    test('enemyProfiles map is not empty', () {
      expect(StoryData.enemyProfiles, isNotEmpty);
    });

    test('memoryFragments list is not empty', () {
      expect(StoryData.memoryFragments, isNotEmpty);
    });

    test('getBriefingForLevel returns briefing for valid level', () {
      final briefing = StoryData.getBriefingForLevel(1);
      expect(briefing, isNotNull);
    });

    test('getBriefingForLevel returns null for invalid level', () {
      final briefing = StoryData.getBriefingForLevel(9999);
      expect(briefing, isNull);
    });

    test('getWorldById returns world for valid id', () {
      final world = StoryData.getWorldById(1);
      expect(world, isNotNull);
      expect(world!.name, 'NEON FRONTIER');
    });

    test('getWorldById returns null for invalid id', () {
      final world = StoryData.getWorldById(9999);
      expect(world, isNull);
    });

    test('getUnlockedLore returns entries up to level', () {
      final lore = StoryData.getUnlockedLore(5);
      expect(lore, isNotEmpty);
      for (final entry in lore) {
        expect(entry.unlockLevel, lessThanOrEqualTo(5));
      }
    });

    test('getCinematic returns cinematic for valid id', () {
      final cinematic = StoryData.getCinematic('prologue');
      expect(cinematic, isNotNull);
    });

    test('getCinematic returns null for invalid id', () {
      final cinematic = StoryData.getCinematic('nonexistent');
      expect(cinematic, isNull);
    });

    test('getEnemyProfile returns profile for valid id', () {
      final profile = StoryData.getEnemyProfile('runner');
      expect(profile, isNotNull);
      expect(profile!.name, 'RUNNER');
    });

    test('getEnemyProfile returns null for invalid id', () {
      final profile = StoryData.getEnemyProfile('nonexistent');
      expect(profile, isNull);
    });

    test('getUnlockedMemories returns memories up to level', () {
      final memories = StoryData.getUnlockedMemories(20);
      expect(memories, isNotEmpty);
      for (final memory in memories) {
        expect(memory.unlockLevel, lessThanOrEqualTo(20));
      }
    });
  });

  group('Character', () {
    test('has all required properties', () {
      const character = Character(
        id: 'test',
        name: 'Test Character',
        title: 'Test Title',
        description: 'Test Description',
        avatarColor: Colors.blue,
        dialoguePrefix: '[TEST]',
      );

      expect(character.id, 'test');
      expect(character.name, 'Test Character');
      expect(character.title, 'Test Title');
      expect(character.description, 'Test Description');
      expect(character.avatarColor, Colors.blue);
      expect(character.dialoguePrefix, '[TEST]');
    });
  });

  group('WorldData', () {
    test('has all required properties', () {
      final world = StoryData.worlds.first;
      expect(world.id, isNotNull);
      expect(world.name, isNotEmpty);
      expect(world.subtitle, isNotEmpty);
      expect(world.description, isNotEmpty);
      expect(world.accentColor, isNotNull);
      expect(world.atmosphere, isNotEmpty);
      expect(world.threat, isNotEmpty);
      expect(world.objective, isNotEmpty);
      expect(world.narrativeBeats, isNotEmpty);
      expect(world.loreEntries, isNotEmpty);
    });
  });

  group('LoreEntry', () {
    test('categoryName returns correct string', () {
      final entry = StoryData.loreEntries.values.first;
      expect(entry.categoryName, isNotEmpty);
    });
  });

  group('EnemyProfile', () {
    test('has danger level between 1 and 10', () {
      for (final profile in StoryData.enemyProfiles.values) {
        expect(profile.dangerLevel, greaterThanOrEqualTo(1));
        expect(profile.dangerLevel, lessThanOrEqualTo(10));
      }
    });
  });

  group('MemoryFragment', () {
    test('can be corrupted', () {
      final corruptedMemory = StoryData.memoryFragments
          .where((m) => m.isCorrupted)
          .toList();
      expect(corruptedMemory, isNotEmpty);
    });
  });
}
