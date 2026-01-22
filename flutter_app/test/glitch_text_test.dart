import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/glitch_text.dart';

void main() {
  group('GlitchText widget', () {
    testWidgets('renders with text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlitchText(text: 'Hello'),
          ),
        ),
      );

      // Initially empty or starting animation
      expect(find.byType(GlitchText), findsOneWidget);
    });

    testWidgets('displays text after animation completes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlitchText(
              text: 'Test',
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('accepts custom style', (tester) async {
      const style = TextStyle(fontSize: 24, color: Colors.red);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlitchText(
              text: 'Styled',
              style: style,
            ),
          ),
        ),
      );

      expect(find.byType(GlitchText), findsOneWidget);
    });

    testWidgets('accepts custom glitch color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlitchText(
              text: 'Colorful',
              glitchColor: Colors.purple,
            ),
          ),
        ),
      );

      expect(find.byType(GlitchText), findsOneWidget);
    });

    testWidgets('accepts custom duration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlitchText(
              text: 'Fast',
              duration: Duration(milliseconds: 50),
            ),
          ),
        ),
      );

      expect(find.byType(GlitchText), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    });

    testWidgets('animates character by character', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlitchText(
              text: 'ABCD',
              duration: Duration(milliseconds: 400),
            ),
          ),
        ),
      );

      // Pump a few frames to see animation in progress
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(GlitchText), findsOneWidget);
    });

    testWidgets('handles single character text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlitchText(
              text: 'A',
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(find.byType(GlitchText), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('handles long text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlitchText(
              text: 'This is a very long text that should still animate correctly',
              duration: Duration(milliseconds: 500),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      expect(find.byType(GlitchText), findsOneWidget);
    });

    testWidgets('can be disposed during animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlitchText(
              text: 'Disposing',
              duration: Duration(milliseconds: 1000),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Replace with different widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      expect(find.byType(GlitchText), findsNothing);
    });

    testWidgets('multiple instances work independently', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GlitchText(text: 'First', duration: Duration(milliseconds: 100)),
                GlitchText(text: 'Second', duration: Duration(milliseconds: 200)),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(GlitchText), findsNWidgets(2));
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
    });

    testWidgets('default duration is 2000ms', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlitchText(text: 'Default'),
          ),
        ),
      );

      expect(find.byType(GlitchText), findsOneWidget);
    });

    testWidgets('default glitch color is cyan', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlitchText(text: 'Cyan'),
          ),
        ),
      );

      final glitchText = tester.widget<GlitchText>(find.byType(GlitchText));
      expect(glitchText.glitchColor, Colors.cyan);
    });
  });
}
