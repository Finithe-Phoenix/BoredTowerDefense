import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/tron_card.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';

void main() {
  group('TronCard', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            child: const Text('CARD CONTENT'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('CARD CONTENT'), findsOneWidget);
    });

    testWidgets('fires onTap after materialization', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            materializationDuration: const Duration(milliseconds: 120),
            child: const SizedBox(width: 120, height: 80),
            onTap: () => taps++,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byType(TronCard));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('default color is cyan', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      final widget = tester.widget<TronCard>(find.byType(TronCard));
      expect(widget.color, NeonColors.cyan);
    });

    testWidgets('default delay is zero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      final widget = tester.widget<TronCard>(find.byType(TronCard));
      expect(widget.delay, Duration.zero);
    });

    testWidgets('default materializationDuration is 500ms', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      final widget = tester.widget<TronCard>(find.byType(TronCard));
      expect(widget.materializationDuration, const Duration(milliseconds: 500));
    });

    testWidgets('default borderRadius is 12.0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      final widget = tester.widget<TronCard>(find.byType(TronCard));
      expect(widget.borderRadius, 12.0);
    });

    testWidgets('default enabled is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      final widget = tester.widget<TronCard>(find.byType(TronCard));
      expect(widget.enabled, isTrue);
    });

    testWidgets('accepts custom color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            color: Colors.red,
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      final widget = tester.widget<TronCard>(find.byType(TronCard));
      expect(widget.color, Colors.red);
    });

    testWidgets('accepts custom secondaryColor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            secondaryColor: Colors.green,
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      final widget = tester.widget<TronCard>(find.byType(TronCard));
      expect(widget.secondaryColor, Colors.green);
    });

    testWidgets('accepts custom delay', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            delay: const Duration(milliseconds: 200),
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 800));

      final widget = tester.widget<TronCard>(find.byType(TronCard));
      expect(widget.delay, const Duration(milliseconds: 200));
    });

    testWidgets('accepts custom materializationDuration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            materializationDuration: const Duration(milliseconds: 1000),
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1100));

      final widget = tester.widget<TronCard>(find.byType(TronCard));
      expect(widget.materializationDuration, const Duration(milliseconds: 1000));
    });

    testWidgets('accepts custom width and height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            width: 200,
            height: 150,
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      final widget = tester.widget<TronCard>(find.byType(TronCard));
      expect(widget.width, 200);
      expect(widget.height, 150);
    });

    testWidgets('accepts custom borderRadius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            borderRadius: 24.0,
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      final widget = tester.widget<TronCard>(find.byType(TronCard));
      expect(widget.borderRadius, 24.0);
    });

    testWidgets('can be disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            enabled: false,
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      final widget = tester.widget<TronCard>(find.byType(TronCard));
      expect(widget.enabled, isFalse);
    });

    testWidgets('does not fire onTap when disabled', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            enabled: false,
            materializationDuration: const Duration(milliseconds: 100),
            child: const SizedBox(width: 120, height: 80),
            onTap: () => taps++,
          ),
        ),
      );

      // Wait for materialization to complete
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.byType(TronCard));
      await tester.pump();

      expect(taps, 0);
    });

    testWidgets('does not fire onTap before materialization completes', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            materializationDuration: const Duration(milliseconds: 1000),
            child: const SizedBox(width: 120, height: 80),
            onTap: () => taps++,
          ),
        ),
      );

      // Tap immediately before materialization completes
      await tester.pump(const Duration(milliseconds: 1));
      await tester.tap(find.byType(TronCard));
      await tester.pump(const Duration(milliseconds: 1100));

      expect(taps, 0);
    });

    testWidgets('animates over time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            child: const Text('Animated'),
          ),
        ),
      );

      // Pump through animation frames
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(TronCard), findsOneWidget);
    });

    testWidgets('can be disposed during animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Replace widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(),
        ),
      );

      expect(find.byType(TronCard), findsNothing);
    });

    testWidgets('respects delay before starting animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            delay: const Duration(milliseconds: 500),
            child: const SizedBox(),
          ),
        ),
      );

      // Widget exists but animation hasn't started
      expect(find.byType(TronCard), findsOneWidget);

      // Pump past the delay
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(TronCard), findsOneWidget);
    });

    testWidgets('handles hover enter and exit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            materializationDuration: const Duration(milliseconds: 100),
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      );

      // Wait for materialization
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      // Move into the card
      await gesture.moveTo(tester.getCenter(find.byType(TronCard)));
      await tester.pump();

      // Move out of the card
      await gesture.moveTo(Offset.zero);
      await tester.pump();

      expect(find.byType(TronCard), findsOneWidget);
    });

    testWidgets('handles tap down and up', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            materializationDuration: const Duration(milliseconds: 100),
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      );

      // Wait for materialization
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(TronCard)),
      );
      await tester.pump();

      await gesture.up();
      await tester.pump();

      expect(find.byType(TronCard), findsOneWidget);
    });

    testWidgets('handles tap cancel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            materializationDuration: const Duration(milliseconds: 100),
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      );

      // Wait for materialization
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(TronCard)),
      );
      await tester.pump();

      await gesture.cancel();
      await tester.pump();

      expect(find.byType(TronCard), findsOneWidget);
    });

    testWidgets('renders without onTap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            child: const Text('No tap handler'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('No tap handler'), findsOneWidget);
    });

    testWidgets('renders complex child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            child: Column(
              children: const [
                Text('Line 1'),
                Text('Line 2'),
                Icon(Icons.star),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Line 1'), findsOneWidget);
      expect(find.text('Line 2'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('multiple instances work independently', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              TronCard(
                child: const Text('Card 1'),
                color: Colors.red,
              ),
              TronCard(
                child: const Text('Card 2'),
                color: Colors.blue,
              ),
            ],
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(TronCard), findsNWidgets(2));
      expect(find.text('Card 1'), findsOneWidget);
      expect(find.text('Card 2'), findsOneWidget);
    });

    testWidgets('handles zero borderRadius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronCard(
            borderRadius: 0,
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      final widget = tester.widget<TronCard>(find.byType(TronCard));
      expect(widget.borderRadius, 0);
    });

    testWidgets('renders in Scaffold body', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronCard(
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Scaffold Card'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Scaffold Card'), findsOneWidget);
    });
  });
}
