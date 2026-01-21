import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/screens/chronicle_reader_screen.dart';
import 'package:bored_games/src/ui/screens/story_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('StoryScreen renders header and first chapter card', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StoryScreen()));

    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('THE ARCHITECT LOGS'), findsOneWidget);
    expect(find.text('NEON FRONTIER'), findsOneWidget);
    expect(find.text('RETURN TO MENU'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
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

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
