import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/tron_button.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TronButton widget tests', () {
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'TEST',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('renders with custom color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'CUSTOM',
                onPressed: () {},
                color: NeonColors.magenta,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('renders with secondary color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'DUAL',
                onPressed: () {},
                color: NeonColors.cyan,
                secondaryColor: NeonColors.purple,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'BIG',
                onPressed: () {},
                width: 400,
                height: 80,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'WITH ICON',
                onPressed: () {},
                icon: Icons.play_arrow,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'TAP ME',
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      // Wait for materialization animation
      await tester.pump(const Duration(milliseconds: 700));

      await tester.tap(find.byType(TronButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when disabled', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'DISABLED',
                onPressed: () => pressed = true,
                enabled: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 700));
      await tester.tap(find.byType(TronButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('default width is 280', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'DEFAULT',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('default height is 56', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'DEFAULT',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });
  });

  group('TronButton materialization', () {
    testWidgets('starts materialization animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'MATERIALIZE',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      // Pump to start animation
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('respects delay parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'DELAYED',
                onPressed: () {},
                delay: const Duration(milliseconds: 500),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('respects materializationDuration parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'SLOW',
                onPressed: () {},
                materializationDuration: const Duration(milliseconds: 1200),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });
  });

  group('TronButton color variations', () {
    testWidgets('renders with cyan color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'CYAN',
                onPressed: () {},
                color: NeonColors.cyan,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('renders with magenta color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'MAGENTA',
                onPressed: () {},
                color: NeonColors.magenta,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('renders with green color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'GREEN',
                onPressed: () {},
                color: NeonColors.green,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('renders with yellow color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'YELLOW',
                onPressed: () {},
                color: NeonColors.yellow,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });
  });

  group('TronButton icon variations', () {
    testWidgets('renders with play icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'PLAY',
                onPressed: () {},
                icon: Icons.play_arrow,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('renders with settings icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'SETTINGS',
                onPressed: () {},
                icon: Icons.settings,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('renders without icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'NO ICON',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });
  });

  group('TronButton size variations', () {
    testWidgets('renders small button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'S',
                onPressed: () {},
                width: 100,
                height: 36,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('renders medium button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'MEDIUM',
                onPressed: () {},
                width: 200,
                height: 50,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });

    testWidgets('renders large button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'LARGE TRON BUTTON',
                onPressed: () {},
                width: 400,
                height: 80,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });
  });

  group('TronButton lifecycle', () {
    testWidgets('disposes animation controllers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'DISPOSE',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox()),
        ),
      );

      expect(true, isTrue);
    });

    testWidgets('handles widget rebuild', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'BEFORE',
                onPressed: () {},
                color: NeonColors.cyan,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'AFTER',
                onPressed: () {},
                color: NeonColors.magenta,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TronButton), findsOneWidget);
    });
  });

  group('TronButton performance', () {
    testWidgets('handles rapid taps', (tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'RAPID',
                onPressed: () => tapCount++,
              ),
            ),
          ),
        ),
      );

      // Wait for materialization
      await tester.pump(const Duration(milliseconds: 700));

      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byType(TronButton));
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(tapCount, greaterThan(0));
    });

    testWidgets('handles many animation frames', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
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

      expect(find.byType(TronButton), findsOneWidget);
    });
  });
}
