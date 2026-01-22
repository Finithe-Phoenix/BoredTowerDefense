import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/animated_grid_background.dart';

void main() {
  group('AnimatedGridBackground', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedGridBackground(
            child: Text('GRID CHILD'),
          ),
        ),
      );

      expect(find.text('GRID CHILD'), findsOneWidget);
    });

    testWidgets('renders without child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedGridBackground(),
        ),
      );

      expect(find.byType(AnimatedGridBackground), findsOneWidget);
    });

    testWidgets('animates over time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedGridBackground(
            child: Text('Animated'),
          ),
        ),
      );

      // Pump through animation frames
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(AnimatedGridBackground), findsOneWidget);
    });

    testWidgets('can be disposed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedGridBackground(
            child: Text('Dispose'),
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

      expect(find.byType(AnimatedGridBackground), findsNothing);
    });

    testWidgets('renders in Scaffold body', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedGridBackground(
              child: Center(
                child: Text('Centered'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Centered'), findsOneWidget);
    });

    testWidgets('renders with complex child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedGridBackground(
            child: Column(
              children: [
                Text('Line 1'),
                Text('Line 2'),
                Text('Line 3'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Line 1'), findsOneWidget);
      expect(find.text('Line 2'), findsOneWidget);
      expect(find.text('Line 3'), findsOneWidget);
    });

    testWidgets('can stack multiple backgrounds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              AnimatedGridBackground(),
              Center(child: Text('Overlay')),
            ],
          ),
        ),
      );

      expect(find.byType(AnimatedGridBackground), findsOneWidget);
      expect(find.text('Overlay'), findsOneWidget);
    });
  });
}
