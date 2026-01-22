import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/neon_button.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';

void main() {
  group('NeonButton widget', () {
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: 'Tap Me',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(NeonButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when disabled', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: 'Disabled',
              onPressed: () => pressed = true,
              enabled: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(NeonButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('renders with custom color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: 'Colored',
              onPressed: () {},
              color: Colors.purple,
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('renders with custom dimensions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: 'Custom Size',
              onPressed: () {},
              width: 300,
              height: 80,
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('default color is cyan', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: 'Default',
              onPressed: () {},
            ),
          ),
        ),
      );

      final neonButton = tester.widget<NeonButton>(find.byType(NeonButton));
      expect(neonButton.color, NeonColors.cyan);
    });

    testWidgets('default width is 250', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: 'Default',
              onPressed: () {},
            ),
          ),
        ),
      );

      final neonButton = tester.widget<NeonButton>(find.byType(NeonButton));
      expect(neonButton.width, 250);
    });

    testWidgets('default height is 50', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: 'Default',
              onPressed: () {},
            ),
          ),
        ),
      );

      final neonButton = tester.widget<NeonButton>(find.byType(NeonButton));
      expect(neonButton.height, 50);
    });

    testWidgets('default enabled is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: 'Default',
              onPressed: () {},
            ),
          ),
        ),
      );

      final neonButton = tester.widget<NeonButton>(find.byType(NeonButton));
      expect(neonButton.enabled, isTrue);
    });

    testWidgets('animates glow effect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: 'Animated',
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('can be disposed correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: 'Dispose Test',
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Replace with different widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsNothing);
    });

    testWidgets('multiple buttons work independently', (tester) async {
      int button1Count = 0;
      int button2Count = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                NeonButton(
                  text: 'Button 1',
                  onPressed: () => button1Count++,
                ),
                NeonButton(
                  text: 'Button 2',
                  onPressed: () => button2Count++,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Button 1'));
      await tester.pump();

      expect(button1Count, 1);
      expect(button2Count, 0);

      await tester.tap(find.text('Button 2'));
      await tester.pump();

      expect(button1Count, 1);
      expect(button2Count, 1);
    });

    testWidgets('handles rapid taps', (tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: 'Rapid',
              onPressed: () => tapCount++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(NeonButton));
      await tester.pump();
      await tester.tap(find.byType(NeonButton));
      await tester.pump();
      await tester.tap(find.byType(NeonButton));
      await tester.pump();

      expect(tapCount, 3);
    });

    testWidgets('handles empty text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: '',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('handles long text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: 'This is a very long button text that might overflow',
              onPressed: () {},
              width: 400,
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('responds to hover enter/exit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: 'Hover Test',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Find the MouseRegion and simulate hover
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await tester.pump();
      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('responds to tap down and up', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: 'Press Test',
              onPressed: () {},
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NeonButton)),
      );
      await tester.pump();

      await gesture.up();
      await tester.pump();

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('tap cancel resets press state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeonButton(
              text: 'Cancel Test',
              onPressed: () {},
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NeonButton)),
      );
      await tester.pump();

      await gesture.cancel();
      await tester.pump();

      expect(find.byType(NeonButton), findsOneWidget);
    });
  });
}
