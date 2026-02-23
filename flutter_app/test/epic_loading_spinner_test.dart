import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/epic_loading_spinner.dart';

void main() {
  group('EpicLoadingSpinner', () {
    testWidgets('renders with default parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicLoadingSpinner(),
          ),
        ),
      );

      expect(find.byType(EpicLoadingSpinner), findsOneWidget);
    });

    testWidgets('default size is 80', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicLoadingSpinner(),
          ),
        ),
      );

      final widget =
          tester.widget<EpicLoadingSpinner>(find.byType(EpicLoadingSpinner));
      expect(widget.size, 80);
    });

    testWidgets('default accentColor is cyan', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicLoadingSpinner(),
          ),
        ),
      );

      final widget =
          tester.widget<EpicLoadingSpinner>(find.byType(EpicLoadingSpinner));
      expect(widget.accentColor, const Color(0xFF00FFFF));
    });

    testWidgets('default showLoadingText is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicLoadingSpinner(),
          ),
        ),
      );

      final widget =
          tester.widget<EpicLoadingSpinner>(find.byType(EpicLoadingSpinner));
      expect(widget.showLoadingText, isFalse);
    });

    testWidgets('default strokeWidth is 2.0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicLoadingSpinner(),
          ),
        ),
      );

      final widget =
          tester.widget<EpicLoadingSpinner>(find.byType(EpicLoadingSpinner));
      expect(widget.strokeWidth, 2.0);
    });

    testWidgets('accepts custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicLoadingSpinner(size: 120),
          ),
        ),
      );

      final widget =
          tester.widget<EpicLoadingSpinner>(find.byType(EpicLoadingSpinner));
      expect(widget.size, 120);
    });

    testWidgets('accepts custom accentColor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicLoadingSpinner(accentColor: Colors.red),
          ),
        ),
      );

      final widget =
          tester.widget<EpicLoadingSpinner>(find.byType(EpicLoadingSpinner));
      expect(widget.accentColor, Colors.red);
    });

    testWidgets('shows loading text when showLoadingText is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicLoadingSpinner(showLoadingText: true),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('LOADING'), findsOneWidget);
    });

    testWidgets('shows custom text when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicLoadingSpinner(
              showLoadingText: true,
              customText: 'INITIALIZING',
            ),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('INITIALIZING'), findsOneWidget);
    });

    testWidgets('does not show text when showLoadingText is false',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicLoadingSpinner(showLoadingText: false),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('LOADING'), findsNothing);
    });

    testWidgets('animates over time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicLoadingSpinner(),
          ),
        ),
      );

      // Pump through multiple animation frames
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(EpicLoadingSpinner), findsOneWidget);
    });

    testWidgets('can be disposed correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicLoadingSpinner(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      expect(find.byType(EpicLoadingSpinner), findsNothing);
    });

    testWidgets('accepts custom strokeWidth', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicLoadingSpinner(strokeWidth: 4.0),
          ),
        ),
      );

      final widget =
          tester.widget<EpicLoadingSpinner>(find.byType(EpicLoadingSpinner));
      expect(widget.strokeWidth, 4.0);
    });

    testWidgets('renders spinner area with correct size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: EpicLoadingSpinner(size: 100),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(EpicLoadingSpinner),
          matching: find.byType(SizedBox).first,
        ),
      );
      expect(sizedBox.width, 100);
      expect(sizedBox.height, 100);
    });

    testWidgets('renders with small size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicLoadingSpinner(size: 20),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(EpicLoadingSpinner), findsOneWidget);
    });

    testWidgets('renders with large size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicLoadingSpinner(size: 200),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(EpicLoadingSpinner), findsOneWidget);
    });

    testWidgets('multiple spinners work independently', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                EpicLoadingSpinner(size: 40, accentColor: Colors.red),
                EpicLoadingSpinner(size: 60, accentColor: Colors.blue),
              ],
            ),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(EpicLoadingSpinner), findsNWidgets(2));
    });
  });

  group('EpicLoadingSpinner.show', () {
    testWidgets('shows spinner as dialog overlay', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  EpicLoadingSpinner.show(context: context);
                },
                child: const Text('SHOW'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('SHOW'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(EpicLoadingSpinner), findsOneWidget);
    });

    testWidgets('shows spinner with custom text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  EpicLoadingSpinner.show(
                    context: context,
                    text: 'SAVING',
                  );
                },
                child: const Text('SHOW'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('SHOW'));
      await tester.pump();
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('SAVING'), findsOneWidget);
    });

    testWidgets('dismiss removes the overlay', (tester) async {
      late BuildContext savedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              savedContext = context;
              return ElevatedButton(
                onPressed: () {
                  EpicLoadingSpinner.show(context: context);
                },
                child: const Text('SHOW'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('SHOW'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(EpicLoadingSpinner), findsOneWidget);

      EpicLoadingSpinner.dismiss(savedContext);
      await tester.pumpAndSettle();

      expect(find.byType(EpicLoadingSpinner), findsNothing);
    });
  });
}
