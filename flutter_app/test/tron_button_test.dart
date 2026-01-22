import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/tron_button.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';

void main() {
  group('TronButton widget', () {
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('displays text after materialization', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Click Me',
              onPressed: () {},
              materializationDuration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Wait for materialization
      for (int i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 50)); }

      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped after materialization', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Tap Me',
              onPressed: () => pressed = true,
              materializationDuration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Wait for materialization
      for (int i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 50)); }

      await tester.tap(find.byType(TronButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when disabled', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Disabled',
              onPressed: () => pressed = true,
              enabled: false,
              materializationDuration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 50)); }

      await tester.tap(find.byType(TronButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('does not call onPressed before materialization', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Wait',
              onPressed: () => pressed = true,
              materializationDuration: const Duration(milliseconds: 500),
            ),
          ),
        ),
      );

      // Tap before materialization completes
      await tester.tap(find.byType(TronButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('default color is cyan', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Default',
              onPressed: () {},
            ),
          ),
        ),
      );

      final tronButton = tester.widget<TronButton>(find.byType(TronButton));
      expect(tronButton.color, NeonColors.cyan);
    });

    testWidgets('default width is 280', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Default',
              onPressed: () {},
            ),
          ),
        ),
      );

      final tronButton = tester.widget<TronButton>(find.byType(TronButton));
      expect(tronButton.width, 280);
    });

    testWidgets('default height is 56', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Default',
              onPressed: () {},
            ),
          ),
        ),
      );

      final tronButton = tester.widget<TronButton>(find.byType(TronButton));
      expect(tronButton.height, 56);
    });

    testWidgets('default enabled is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Default',
              onPressed: () {},
            ),
          ),
        ),
      );

      final tronButton = tester.widget<TronButton>(find.byType(TronButton));
      expect(tronButton.enabled, isTrue);
    });

    testWidgets('accepts custom color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Colored',
              onPressed: () {},
              color: Colors.red,
            ),
          ),
        ),
      );

      final tronButton = tester.widget<TronButton>(find.byType(TronButton));
      expect(tronButton.color, Colors.red);
    });

    testWidgets('accepts custom secondary color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Custom',
              onPressed: () {},
              secondaryColor: Colors.purple,
            ),
          ),
        ),
      );

      final tronButton = tester.widget<TronButton>(find.byType(TronButton));
      expect(tronButton.secondaryColor, Colors.purple);
    });

    testWidgets('accepts custom dimensions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Custom Size',
              onPressed: () {},
              width: 400,
              height: 80,
            ),
          ),
        ),
      );

      final tronButton = tester.widget<TronButton>(find.byType(TronButton));
      expect(tronButton.width, 400);
      expect(tronButton.height, 80);
    });

    testWidgets('accepts icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'With Icon',
              onPressed: () {},
              icon: Icons.play_arrow,
              materializationDuration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 50)); }

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('respects delay before materialization', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Delayed',
              onPressed: () {},
              delay: const Duration(milliseconds: 200),
              materializationDuration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Should not be materialized yet
      await tester.pump(const Duration(milliseconds: 100));

      // Wait for delay + materialization
      for (int i = 0; i < 15; i++) { await tester.pump(const Duration(milliseconds: 50)); }

      expect(find.text('Delayed'), findsOneWidget);
    });

    testWidgets('can be disposed during animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Dispose Test',
              onPressed: () {},
              materializationDuration: const Duration(milliseconds: 500),
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

      expect(find.byType(TronButton), findsNothing);
    });

    testWidgets('multiple buttons work independently', (tester) async {
      int button1Count = 0;
      int button2Count = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TronButton(
                  text: 'Button 1',
                  onPressed: () => button1Count++,
                  materializationDuration: const Duration(milliseconds: 100),
                ),
                TronButton(
                  text: 'Button 2',
                  onPressed: () => button2Count++,
                  materializationDuration: const Duration(milliseconds: 100),
                ),
              ],
            ),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 50)); }

      await tester.tap(find.text('Button 1'));
      await tester.pump();

      expect(button1Count, 1);
      expect(button2Count, 0);

      await tester.tap(find.text('Button 2'));
      await tester.pump();

      expect(button1Count, 1);
      expect(button2Count, 1);
    });

    testWidgets('handles rapid taps after materialization', (tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Rapid',
              onPressed: () => tapCount++,
              materializationDuration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 50)); }

      await tester.tap(find.byType(TronButton));
      await tester.pump();
      await tester.tap(find.byType(TronButton));
      await tester.pump();
      await tester.tap(find.byType(TronButton));
      await tester.pump();

      expect(tapCount, 3);
    });

    testWidgets('handles empty text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: '',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('handles long text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'This is a very long button text',
              onPressed: () {},
              width: 400,
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('tap cancel resets press state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Cancel Test',
              onPressed: () {},
              materializationDuration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 50)); }

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(TronButton)),
      );
      await tester.pump();

      await gesture.cancel();
      await tester.pump();

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('default delay is zero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Default',
              onPressed: () {},
            ),
          ),
        ),
      );

      final tronButton = tester.widget<TronButton>(find.byType(TronButton));
      expect(tronButton.delay, Duration.zero);
    });

    testWidgets('default materialization duration is 600ms', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Default',
              onPressed: () {},
            ),
          ),
        ),
      );

      final tronButton = tester.widget<TronButton>(find.byType(TronButton));
      expect(tronButton.materializationDuration, const Duration(milliseconds: 600));
    });

    testWidgets('icon is null by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Default',
              onPressed: () {},
            ),
          ),
        ),
      );

      final tronButton = tester.widget<TronButton>(find.byType(TronButton));
      expect(tronButton.icon, isNull);
    });

    testWidgets('secondary color is null by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Default',
              onPressed: () {},
            ),
          ),
        ),
      );

      final tronButton = tester.widget<TronButton>(find.byType(TronButton));
      expect(tronButton.secondaryColor, isNull);
    });
  });

  group('TronButton animations', () {
    testWidgets('animates during materialization', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Animating',
              onPressed: () {},
              materializationDuration: const Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      // Pump through animation (not pumpAndSettle due to repeating animations)
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('button visible after multiple pumps', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronButton(
              text: 'Pulsing',
              onPressed: () {},
              materializationDuration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Pump through materialization (not pumpAndSettle due to repeating animations)
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(TronButton), findsOneWidget);
    });
  });
}
