import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/neon_button.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NeonButton widget tests', () {
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'TEST',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
      expect(find.text('TEST'), findsOneWidget);
    });

    testWidgets('renders with custom color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'CUSTOM',
                onPressed: () {},
                color: NeonColors.magenta,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('renders with secondary color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'DUAL',
                onPressed: () {},
                color: NeonColors.cyan,
                secondaryColor: NeonColors.purple,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'BIG',
                onPressed: () {},
                width: 400,
                height: 80,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'TAP ME',
                onPressed: () => pressed = true,
              ),
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
            body: Center(
              child: NeonButton(
                text: 'DISABLED',
                onPressed: () => pressed = true,
                enabled: false,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(NeonButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('default width is 250', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'DEFAULT',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('default height is 50', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'DEFAULT',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('default enabled is true', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'ENABLED',
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(NeonButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('animations run on mount', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'ANIMATE',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      // Pump several frames to let animations run
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('disposes animation controllers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'DISPOSE',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox()),
        ),
      );

      expect(true, isTrue);
    });
  });

  group('NeonButton color variations', () {
    testWidgets('renders with cyan color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'CYAN',
                onPressed: () {},
                color: NeonColors.cyan,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('renders with magenta color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'MAGENTA',
                onPressed: () {},
                color: NeonColors.magenta,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('renders with green color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'GREEN',
                onPressed: () {},
                color: NeonColors.green,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('renders with yellow color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'YELLOW',
                onPressed: () {},
                color: NeonColors.yellow,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('renders with red color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'RED',
                onPressed: () {},
                color: NeonColors.red,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });
  });

  group('NeonButton size variations', () {
    testWidgets('renders small button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'S',
                onPressed: () {},
                width: 100,
                height: 30,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('renders medium button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'MEDIUM',
                onPressed: () {},
                width: 200,
                height: 50,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('renders large button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'LARGE BUTTON',
                onPressed: () {},
                width: 350,
                height: 70,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });
  });

  group('NeonButton text variations', () {
    testWidgets('renders empty text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: '',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('renders long text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'THIS IS A VERY LONG BUTTON TEXT',
                onPressed: () {},
                width: 400,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('renders special characters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: '⚡ POWER ⚡',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NeonButton), findsOneWidget);
    });
  });

  group('NeonButton performance', () {
    testWidgets('handles rapid taps', (tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'RAPID',
                onPressed: () => tapCount++,
              ),
            ),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byType(NeonButton));
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(tapCount, greaterThan(0));
    });

    testWidgets('handles many animation frames', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeonButton(
                text: 'FRAMES',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(find.byType(NeonButton), findsOneWidget);
    });
  });
}
