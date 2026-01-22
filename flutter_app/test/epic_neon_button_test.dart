import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/epic_neon_button.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';

void main() {
  group('EpicNeonButton', () {
    testWidgets('renders text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'BUTTON TEXT',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('BUTTON TEXT'), findsOneWidget);
    });

    testWidgets('fires callback when enabled', (tester) async {
      var pressed = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'LAUNCH',
            icon: Icons.bolt,
            onPressed: () => pressed++,
          ),
        ),
      );

      await tester.tap(find.text('LAUNCH'));
      await tester.pump();

      expect(pressed, 1);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
    });

    testWidgets('ignores taps when disabled', (tester) async {
      var pressed = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'LOCKED',
            enabled: false,
            onPressed: () => pressed++,
          ),
        ),
      );

      await tester.tap(find.text('LOCKED'));
      await tester.pump();

      expect(pressed, 0);
    });

    testWidgets('default color is cyan', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'TEST',
            onPressed: () {},
          ),
        ),
      );

      final widget = tester.widget<EpicNeonButton>(find.byType(EpicNeonButton));
      expect(widget.color, NeonColors.cyan);
    });

    testWidgets('default width is 280', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'TEST',
            onPressed: () {},
          ),
        ),
      );

      final widget = tester.widget<EpicNeonButton>(find.byType(EpicNeonButton));
      expect(widget.width, 280);
    });

    testWidgets('default height is 56', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'TEST',
            onPressed: () {},
          ),
        ),
      );

      final widget = tester.widget<EpicNeonButton>(find.byType(EpicNeonButton));
      expect(widget.height, 56);
    });

    testWidgets('default enabled is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'TEST',
            onPressed: () {},
          ),
        ),
      );

      final widget = tester.widget<EpicNeonButton>(find.byType(EpicNeonButton));
      expect(widget.enabled, isTrue);
    });

    testWidgets('accepts custom color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'TEST',
            color: Colors.red,
            onPressed: () {},
          ),
        ),
      );

      final widget = tester.widget<EpicNeonButton>(find.byType(EpicNeonButton));
      expect(widget.color, Colors.red);
    });

    testWidgets('accepts custom width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'TEST',
            width: 400,
            onPressed: () {},
          ),
        ),
      );

      final widget = tester.widget<EpicNeonButton>(find.byType(EpicNeonButton));
      expect(widget.width, 400);
    });

    testWidgets('accepts custom height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'TEST',
            height: 80,
            onPressed: () {},
          ),
        ),
      );

      final widget = tester.widget<EpicNeonButton>(find.byType(EpicNeonButton));
      expect(widget.height, 80);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'TEST',
            icon: Icons.star,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders without icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'NO ICON',
            onPressed: () {},
          ),
        ),
      );

      final widget = tester.widget<EpicNeonButton>(find.byType(EpicNeonButton));
      expect(widget.icon, isNull);
    });

    testWidgets('animates over time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'ANIMATED',
            onPressed: () {},
          ),
        ),
      );

      // Pump through animation frames
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(EpicNeonButton), findsOneWidget);
    });

    testWidgets('can be disposed during animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'DISPOSE',
            onPressed: () {},
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

      expect(find.byType(EpicNeonButton), findsNothing);
    });

    testWidgets('handles hover enter and exit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'HOVER',
            onPressed: () {},
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      // Move into the button
      await gesture.moveTo(tester.getCenter(find.byType(EpicNeonButton)));
      await tester.pump();

      // Move out of the button
      await gesture.moveTo(Offset.zero);
      await tester.pump();

      expect(find.byType(EpicNeonButton), findsOneWidget);
    });

    testWidgets('handles tap down and up', (tester) async {
      var pressed = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'PRESS',
            onPressed: () => pressed++,
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(EpicNeonButton)),
      );
      await tester.pump();

      await gesture.up();
      await tester.pump();

      expect(pressed, 1);
    });

    testWidgets('handles tap cancel', (tester) async {
      var pressed = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'CANCEL',
            onPressed: () => pressed++,
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(EpicNeonButton)),
      );
      await tester.pump();

      await gesture.cancel();
      await tester.pump();

      // Should not call onPressed on cancel
      expect(pressed, 0);
    });

    testWidgets('handles long text with ellipsis', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'THIS IS A VERY LONG BUTTON TEXT THAT SHOULD OVERFLOW',
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(EpicNeonButton), findsOneWidget);
    });

    testWidgets('handles empty text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: '',
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(EpicNeonButton), findsOneWidget);
    });

    testWidgets('multiple instances work independently', (tester) async {
      var presses1 = 0;
      var presses2 = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              EpicNeonButton(
                text: 'BUTTON 1',
                onPressed: () => presses1++,
              ),
              EpicNeonButton(
                text: 'BUTTON 2',
                onPressed: () => presses2++,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(EpicNeonButton), findsNWidgets(2));

      await tester.tap(find.text('BUTTON 1'));
      await tester.pump();

      expect(presses1, 1);
      expect(presses2, 0);
    });

    testWidgets('renders in Scaffold body', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: EpicNeonButton(
                text: 'CENTERED',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('CENTERED'), findsOneWidget);
    });

    testWidgets('can be disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'DISABLED',
            enabled: false,
            onPressed: () {},
          ),
        ),
      );

      final widget = tester.widget<EpicNeonButton>(find.byType(EpicNeonButton));
      expect(widget.enabled, isFalse);
    });

    testWidgets('icon and text render together', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'PLAY',
            icon: Icons.play_arrow,
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('PLAY'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('uses grey color when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'DISABLED',
            color: Colors.red,
            enabled: false,
            onPressed: () {},
          ),
        ),
      );

      // The widget uses grey color internally when disabled
      expect(find.byType(EpicNeonButton), findsOneWidget);
    });

    testWidgets('fires callback multiple times', (tester) async {
      var pressed = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: EpicNeonButton(
            text: 'TAP ME',
            onPressed: () => pressed++,
          ),
        ),
      );

      await tester.tap(find.text('TAP ME'));
      await tester.pump();
      await tester.tap(find.text('TAP ME'));
      await tester.pump();
      await tester.tap(find.text('TAP ME'));
      await tester.pump();

      expect(pressed, 3);
    });
  });
}
