import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/screens/chronicle_reader_screen.dart';
import 'package:bored_games/src/data/world_chronicles.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';

void main() {
  // Create minimal test chronicle data
  const testChronicle = WorldChronicle(
    worldId: 1,
    name: 'TEST CHRONICLE',
    codename: 'TEST_CODE',
    subtitle: 'Test Subtitle',
    accentColor: NeonColors.cyan,
    secondaryColor: Color(0xFF004466),
    epoch: 'Test Epoch',
    openingCinematic: 'Test cinematic',
    closingQuote: 'Test quote',
    narrator: ChronicleCharacters.narrator,
    ambientDescriptions: ['Test description'],
    chapters: [
      ChronicleChapter(
        index: 1,
        title: 'Test Chapter',
        subtitle: 'Test subtitle',
        mood: ChapterMood.epic,
        visualCues: ['test_cue'],
        paragraphs: [
          'First paragraph.',
          'Second paragraph.',
        ],
      ),
      ChronicleChapter(
        index: 2,
        title: 'Chapter Two',
        subtitle: 'Second subtitle',
        mood: ChapterMood.mysterious,
        visualCues: ['mystery_cue'],
        paragraphs: [
          'Third paragraph.',
        ],
        interlude: 'An interlude text.',
      ),
    ],
  );

  group('ChronicleReaderScreen', () {
    testWidgets('renders chronicle reader screen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      expect(find.byType(ChronicleReaderScreen), findsOneWidget);
    });

    testWidgets('shows chapter title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      // Pump for animation
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Test Chapter'), findsOneWidget);
    });

    testWidgets('shows chapter subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      // Pump for animation
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Test subtitle'), findsOneWidget);
    });

    testWidgets('has scaffold with black background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('displays chronicle name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      // Pump for animation
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('TEST CHRONICLE'), findsOneWidget);
    });

    testWidgets('shows back button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('shows pause button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('toggles pause on button press', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('uses Stack for layered content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('uses GestureDetector for tap navigation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('contains CustomPaint for background graphics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('animates over time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      // Pump through animation frames
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(ChronicleReaderScreen), findsOneWidget);
    });

    testWidgets('can be disposed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Replace widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('REPLACED')),
        ),
      );

      expect(find.byType(ChronicleReaderScreen), findsNothing);
    });

    testWidgets('accepts startChapter parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(
            chronicle: testChronicle,
            startChapter: 1,
          ),
        ),
      );

      // Pump for animation
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Chapter Two'), findsOneWidget);
    });

    testWidgets('uses SafeArea for content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('uses SingleChildScrollView for scrolling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('tap advances content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      // Wait for initial rendering
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Tap to skip typewriter
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(find.byType(ChronicleReaderScreen), findsOneWidget);
    });

    testWidgets('shows tap hint text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(chronicle: testChronicle),
        ),
      );

      // Pump for animation to complete
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Should show tap hint
      expect(
        find.textContaining('Toca'),
        findsWidgets,
      );
    });

    testWidgets('has back button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChronicleReaderScreen(
            chronicle: testChronicle,
          ),
        ),
      );

      // Wait for the screen to render
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Check that back button icon exists
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });
  });

  group('ChapterMood', () {
    test('has all expected values', () {
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
  });

  group('ChronicleCharacter', () {
    test('narrator has correct properties', () {
      expect(ChronicleCharacters.narrator.id, 'narrator');
      expect(ChronicleCharacters.narrator.name, 'SISTEMA');
      expect(ChronicleCharacters.narrator.prefix, '[ SISTEMA ]');
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

  group('WorldChronicle', () {
    test('can be constructed', () {
      expect(testChronicle.worldId, 1);
      expect(testChronicle.name, 'TEST CHRONICLE');
      expect(testChronicle.chapters.length, 2);
    });
  });

  group('ChronicleChapter', () {
    test('can have interlude', () {
      final chapterWithInterlude = testChronicle.chapters[1];
      expect(chapterWithInterlude.interlude, isNotNull);
      expect(chapterWithInterlude.interlude, 'An interlude text.');
    });

    test('can have speaker', () {
      const chapterWithSpeaker = ChronicleChapter(
        index: 1,
        title: 'Test',
        subtitle: 'Sub',
        mood: ChapterMood.epic,
        visualCues: [],
        paragraphs: ['Text'],
        speaker: ChronicleCharacters.aria,
      );
      expect(chapterWithSpeaker.speaker, isNotNull);
      expect(chapterWithSpeaker.speaker!.name, 'A.R.I.A.');
    });
  });

  group('WorldChronicles', () {
    test('all returns all chronicles', () {
      expect(WorldChronicles.all, isNotEmpty);
    });

    test('getChronicle returns chronicle by worldId', () {
      final chronicle = WorldChronicles.getChronicle(1);
      expect(chronicle, isNotNull);
      expect(chronicle!.name, 'NEON FRONTIER');
    });

    test('getChronicle returns null for invalid worldId', () {
      final chronicle = WorldChronicles.getChronicle(9999);
      expect(chronicle, isNull);
    });
  });

  group('getChronicleByWorldId', () {
    test('returns chronicle for valid worldId', () {
      final chronicle = getChronicleByWorldId(1);
      expect(chronicle, isNotNull);
    });

    test('returns null for invalid worldId', () {
      final chronicle = getChronicleByWorldId(9999);
      expect(chronicle, isNull);
    });
  });
}
