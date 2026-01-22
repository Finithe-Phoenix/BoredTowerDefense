import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/materialization_overlay.dart';

void main() {
  group('MaterializationOverlay', () {
    testWidgets('completes and hides', (tester) async {
      var completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MaterializationOverlay(
            onComplete: () => completed = true,
          ),
        ),
      );

      expect(find.text('INITIALIZING SYSTEM'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2300));

      expect(completed, isTrue);
      expect(find.text('INITIALIZING SYSTEM'), findsNothing);
    });

    testWidgets('renders with required onComplete callback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MaterializationOverlay(
            onComplete: () {},
          ),
        ),
      );

      expect(find.byType(MaterializationOverlay), findsOneWidget);
    });

    testWidgets('shows initializing text at start', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MaterializationOverlay(
            onComplete: () {},
          ),
        ),
      );

      expect(find.text('INITIALIZING SYSTEM'), findsOneWidget);
    });

    testWidgets('animates over time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MaterializationOverlay(
            onComplete: () {},
          ),
        ),
      );

      // Pump through animation frames
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(MaterializationOverlay), findsOneWidget);
    });

    testWidgets('can be disposed during animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MaterializationOverlay(
            onComplete: () {},
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Replace widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(),
        ),
      );

      expect(find.byType(MaterializationOverlay), findsNothing);
    });

    testWidgets('callback is called once animation completes', (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MaterializationOverlay(
            onComplete: () => callCount++,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2500));

      expect(callCount, 1);
    });

    testWidgets('hides after animation completes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MaterializationOverlay(
            onComplete: () {},
          ),
        ),
      );

      // Initially visible
      expect(find.text('INITIALIZING SYSTEM'), findsOneWidget);

      // Wait for animation to complete
      await tester.pump(const Duration(milliseconds: 2500));

      // Text should be hidden
      expect(find.text('INITIALIZING SYSTEM'), findsNothing);
    });
  });
}
