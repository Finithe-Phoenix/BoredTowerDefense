import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/epic_neon_title.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';

void main() {
  group('EpicNeonTitle', () {
    testWidgets('shows the provided text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicNeonTitle(text: 'NEON SIGNAL'),
          ),
        ),
      );

      expect(find.text('NEON SIGNAL'), findsWidgets);
    });

    testWidgets('renders with required text parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicNeonTitle(text: 'TEST TITLE'),
          ),
        ),
      );

      expect(find.byType(EpicNeonTitle), findsOneWidget);
    });

    testWidgets('accepts custom fontSize', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicNeonTitle(text: 'BIG', fontSize: 72),
          ),
        ),
      );

      final widget = tester.widget<EpicNeonTitle>(find.byType(EpicNeonTitle));
      expect(widget.fontSize, 72);
    });

    testWidgets('default fontSize is 56', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicNeonTitle(text: 'DEFAULT'),
          ),
        ),
      );

      final widget = tester.widget<EpicNeonTitle>(find.byType(EpicNeonTitle));
      expect(widget.fontSize, 56);
    });

    testWidgets('accepts custom primary color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicNeonTitle(text: 'COLORED', primaryColor: Colors.red),
          ),
        ),
      );

      final widget = tester.widget<EpicNeonTitle>(find.byType(EpicNeonTitle));
      expect(widget.primaryColor, Colors.red);
    });

    testWidgets('accepts custom secondary color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicNeonTitle(text: 'SECONDARY', secondaryColor: Colors.green),
          ),
        ),
      );

      final widget = tester.widget<EpicNeonTitle>(find.byType(EpicNeonTitle));
      expect(widget.secondaryColor, Colors.green);
    });

    testWidgets('default primary color is cyan', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicNeonTitle(text: 'DEFAULT'),
          ),
        ),
      );

      final widget = tester.widget<EpicNeonTitle>(find.byType(EpicNeonTitle));
      expect(widget.primaryColor, NeonColors.cyan);
    });

    testWidgets('default secondary color is magenta', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicNeonTitle(text: 'DEFAULT'),
          ),
        ),
      );

      final widget = tester.widget<EpicNeonTitle>(find.byType(EpicNeonTitle));
      expect(widget.secondaryColor, NeonColors.magenta);
    });

    testWidgets('animates over time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicNeonTitle(text: 'ANIMATED'),
          ),
        ),
      );

      // Pump through animation frames (not pumpAndSettle due to repeating animations)
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(EpicNeonTitle), findsOneWidget);
    });

    testWidgets('can be disposed during animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicNeonTitle(text: 'DISPOSE'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Replace widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      expect(find.byType(EpicNeonTitle), findsNothing);
    });

    testWidgets('handles empty text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicNeonTitle(text: ''),
          ),
        ),
      );

      expect(find.byType(EpicNeonTitle), findsOneWidget);
    });

    testWidgets('handles long text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicNeonTitle(text: 'THIS IS A VERY LONG TITLE FOR TESTING'),
          ),
        ),
      );

      expect(find.byType(EpicNeonTitle), findsOneWidget);
    });

    testWidgets('multiple instances work independently', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                EpicNeonTitle(text: 'TITLE 1'),
                EpicNeonTitle(text: 'TITLE 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(EpicNeonTitle), findsNWidgets(2));
    });
  });
}
