import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/tron_dialog.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';

void main() {
  group('TronDialog', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              child: const Text('DIALOG CONTENT'),
            ),
          ),
        ),
      );

      // Pump through animation
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('DIALOG CONTENT'), findsOneWidget);
    });

    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              title: 'TEST TITLE',
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // Pump through animation
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('TEST TITLE'), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              title: 'With Icon',
              icon: Icons.settings,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // Pump through animation
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('default primaryColor is cyan', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              child: const SizedBox(),
            ),
          ),
        ),
      );

      final widget = tester.widget<TronDialog>(find.byType(TronDialog));
      expect(widget.primaryColor, NeonColors.cyan);
    });

    testWidgets('default width is 400', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              child: const SizedBox(),
            ),
          ),
        ),
      );

      final widget = tester.widget<TronDialog>(find.byType(TronDialog));
      expect(widget.width, 400);
    });

    testWidgets('default showCloseButton is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              child: const SizedBox(),
            ),
          ),
        ),
      );

      final widget = tester.widget<TronDialog>(find.byType(TronDialog));
      expect(widget.showCloseButton, isTrue);
    });

    testWidgets('accepts custom primaryColor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              primaryColor: Colors.red,
              child: const SizedBox(),
            ),
          ),
        ),
      );

      final widget = tester.widget<TronDialog>(find.byType(TronDialog));
      expect(widget.primaryColor, Colors.red);
    });

    testWidgets('accepts custom secondaryColor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              secondaryColor: Colors.green,
              child: const SizedBox(),
            ),
          ),
        ),
      );

      final widget = tester.widget<TronDialog>(find.byType(TronDialog));
      expect(widget.secondaryColor, Colors.green);
    });

    testWidgets('accepts custom width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              width: 600,
              child: const SizedBox(),
            ),
          ),
        ),
      );

      final widget = tester.widget<TronDialog>(find.byType(TronDialog));
      expect(widget.width, 600);
    });

    testWidgets('shows close button by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              title: 'Dialog',
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // Pump through animation
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('can hide close button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              title: 'Dialog',
              showCloseButton: false,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // Pump through animation
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('onClose callback is called when close button tapped', (tester) async {
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              title: 'Dialog',
              onClose: () => closed = true,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // Pump through animation
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(closed, isTrue);
    });

    testWidgets('animates over time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              child: const Text('Animated'),
            ),
          ),
        ),
      );

      // Pump through animation frames
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(TronDialog), findsOneWidget);
    });

    testWidgets('can be disposed during animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              child: const SizedBox(),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Replace widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      expect(find.byType(TronDialog), findsNothing);
    });

    testWidgets('renders complex child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Line 1'),
                  Text('Line 2'),
                  Icon(Icons.star),
                ],
              ),
            ),
          ),
        ),
      );

      // Pump through animation
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Line 1'), findsOneWidget);
      expect(find.text('Line 2'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders without title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // Pump through animation
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('renders without icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TronDialog(
              title: 'No Icon',
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // Pump through animation
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('No Icon'), findsOneWidget);
    });
  });

  group('TronDialog.show', () {
    testWidgets('shows dialog and closes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TronDialog.show(
                    context: context,
                    title: 'DIALOG',
                    builder: (_) => const Text('CONTENT'),
                  );
                },
                child: const Text('OPEN'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('DIALOG'), findsOneWidget);
      expect(find.text('CONTENT'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('DIALOG'), findsNothing);
    });

    testWidgets('shows dialog with icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TronDialog.show(
                    context: context,
                    title: 'With Icon',
                    icon: Icons.info,
                    builder: (_) => const Text('Content'),
                  );
                },
                child: const Text('OPEN'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.byIcon(Icons.info), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets('shows dialog with custom colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TronDialog.show(
                    context: context,
                    title: 'Colored',
                    primaryColor: Colors.red,
                    secondaryColor: Colors.orange,
                    builder: (_) => const Text('Content'),
                  );
                },
                child: const Text('OPEN'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('Colored'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets('shows dialog with custom width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TronDialog.show(
                    context: context,
                    title: 'Wide',
                    width: 600,
                    builder: (_) => const Text('Content'),
                  );
                },
                child: const Text('OPEN'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('Wide'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets('shows dialog without close button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TronDialog.show(
                    context: context,
                    title: 'No Close',
                    showCloseButton: false,
                    builder: (_) => const Text('Content'),
                  );
                },
                child: const Text('OPEN'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.text('No Close'), findsOneWidget);

      // Dismiss with barrier tap since there's no close button
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets('barrierDismissible works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TronDialog.show(
                    context: context,
                    title: 'Dismissible',
                    barrierDismissible: true,
                    builder: (_) => const Text('Content'),
                  );
                },
                child: const Text('OPEN'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('Dismissible'), findsOneWidget);

      // Tap outside to dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Dismissible'), findsNothing);
    });

    testWidgets('barrierDismissible false prevents barrier dismiss', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TronDialog.show(
                    context: context,
                    title: 'Not Dismissible',
                    barrierDismissible: false,
                    builder: (_) => const Text('Content'),
                  );
                },
                child: const Text('OPEN'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('Not Dismissible'), findsOneWidget);

      // Tap outside - should NOT dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Dialog should still be visible
      expect(find.text('Not Dismissible'), findsOneWidget);

      // Close via button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets('shows dialog without title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TronDialog.show(
                    context: context,
                    builder: (_) => const Text('Content Only'),
                  );
                },
                child: const Text('OPEN'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('Content Only'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets('returns result on close', (tester) async {
      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await TronDialog.show<String>(
                    context: context,
                    title: 'Result Dialog',
                    builder: (ctx) => ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, 'success'),
                      child: const Text('Confirm'),
                    ),
                  );
                },
                child: const Text('OPEN'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('Result Dialog'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, 'success');
    });
  });
}
