import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/screens/chronicle_reader_screen.dart';
import 'package:bored_games/src/ui/screens/story_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('StoryScreen renders header and first chapter card',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StoryScreen()));

    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('THE ARCHITECT LOGS'), findsOneWidget);
    expect(find.text('NEON FRONTIER'), findsOneWidget);
    expect(find.text('RETURN TO MENU'), findsOneWidget);
  });

  testWidgets('StoryScreen opens ChronicleReaderScreen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StoryScreen()));

    await tester.pump(const Duration(milliseconds: 250));

    final readFinder = find.textContaining('LEER');
    expect(readFinder, findsWidgets);

    await tester.tap(readFinder.first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(find.byType(ChronicleReaderScreen), findsOneWidget);
  });

  testWidgets('StoryScreen shows narrative deck summary and active report CTA',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StoryScreen()));

    await tester.pump(const Duration(milliseconds: 350));

    expect(find.textContaining('MUNDOS DESBLOQUEADOS:'), findsOneWidget);
    expect(find.text('LEER INFORME ACTIVO'), findsOneWidget);
  });

  testWidgets('StoryScreen active report CTA opens ChronicleReaderScreen',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StoryScreen()));

    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.text('LEER INFORME ACTIVO'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 550));

    expect(find.byType(ChronicleReaderScreen), findsOneWidget);
  });

  testWidgets('StoryScreen return button pops back to previous route',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StoryScreen(),
                      ),
                    );
                  },
                  child: const Text('OPEN STORY'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN STORY'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 1800));

    expect(find.byType(StoryScreen), findsOneWidget);

    final returnButton = find.text('RETURN TO MENU');
    await tester.ensureVisible(returnButton);
    await tester.tap(returnButton, warnIfMissed: false);

    var popped = false;
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(StoryScreen).evaluate().isEmpty) {
        popped = true;
        break;
      }
    }

    expect(popped, isTrue);
    expect(find.text('OPEN STORY'), findsOneWidget);
  });
}
