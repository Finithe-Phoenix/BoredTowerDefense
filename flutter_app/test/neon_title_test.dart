import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/neon_title.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';

void main() {
  group('NeonTitle', () {
    testWidgets('renders text with custom styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NeonTitle(
            text: 'NEON TITLE',
            fontSize: 32,
            color: Colors.green,
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('NEON TITLE'));
      expect(textWidget.style?.color, Colors.green);
      expect(textWidget.style?.fontSize, 32);
    });

    testWidgets('renders with required text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NeonTitle(text: 'TEST'),
        ),
      );

      expect(find.text('TEST'), findsOneWidget);
    });

    testWidgets('default fontSize is 48', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NeonTitle(text: 'DEFAULT'),
        ),
      );

      final widget = tester.widget<NeonTitle>(find.byType(NeonTitle));
      expect(widget.fontSize, 48);
    });

    testWidgets('default color is cyan', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NeonTitle(text: 'CYAN'),
        ),
      );

      final widget = tester.widget<NeonTitle>(find.byType(NeonTitle));
      expect(widget.color, NeonColors.cyan);
    });

    testWidgets('accepts custom fontSize', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NeonTitle(text: 'BIG', fontSize: 72),
        ),
      );

      final widget = tester.widget<NeonTitle>(find.byType(NeonTitle));
      expect(widget.fontSize, 72);
    });

    testWidgets('accepts custom color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NeonTitle(text: 'RED', color: Colors.red),
        ),
      );

      final widget = tester.widget<NeonTitle>(find.byType(NeonTitle));
      expect(widget.color, Colors.red);
    });

    testWidgets('animates over time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NeonTitle(text: 'ANIMATED'),
        ),
      );

      // Pump through animation frames
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(NeonTitle), findsOneWidget);
    });

    testWidgets('can be disposed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NeonTitle(text: 'DISPOSE'),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(),
        ),
      );

      expect(find.byType(NeonTitle), findsNothing);
    });

    testWidgets('handles empty text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NeonTitle(text: ''),
        ),
      );

      expect(find.byType(NeonTitle), findsOneWidget);
    });

    testWidgets('handles long text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NeonTitle(text: 'THIS IS A VERY LONG TITLE'),
        ),
      );

      expect(find.byType(NeonTitle), findsOneWidget);
    });

    testWidgets('multiple instances work', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              NeonTitle(text: 'ONE'),
              NeonTitle(text: 'TWO'),
            ],
          ),
        ),
      );

      expect(find.byType(NeonTitle), findsNWidgets(2));
    });
  });
}
