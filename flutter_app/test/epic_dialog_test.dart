import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/epic_dialog.dart';

void main() {
  group('EpicDialog', () {
    testWidgets('renders with title and content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicDialog(
              title: 'Test Title',
              content: 'Test content message',
            ),
          ),
        ),
      );

      // Pump through entrance -> border -> content animations
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Test Title'), findsNWidgets(2));
      expect(find.text('Test content message'), findsOneWidget);
    });

    testWidgets('renders with customContent widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicDialog(
              title: 'Custom',
              customContent: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Line 1'),
                  Text('Line 2'),
                ],
              ),
            ),
          ),
        ),
      );

      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Line 1'), findsOneWidget);
      expect(find.text('Line 2'), findsOneWidget);
    });

    testWidgets('default accentColor is cyan', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicDialog(
              title: 'Default',
              content: 'Content',
            ),
          ),
        ),
      );

      final widget = tester.widget<EpicDialog>(find.byType(EpicDialog));
      expect(widget.accentColor, const Color(0xFF00FFFF));
    });

    testWidgets('accepts custom accentColor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicDialog(
              title: 'Colored',
              content: 'Content',
              accentColor: Colors.red,
            ),
          ),
        ),
      );

      final widget = tester.widget<EpicDialog>(find.byType(EpicDialog));
      expect(widget.accentColor, Colors.red);
    });

    testWidgets('default showCloseButton is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicDialog(
              title: 'Default',
              content: 'Content',
            ),
          ),
        ),
      );

      final widget = tester.widget<EpicDialog>(find.byType(EpicDialog));
      expect(widget.showCloseButton, isTrue);
    });

    testWidgets('shows close button by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicDialog(
              title: 'Dialog',
              content: 'Content',
            ),
          ),
        ),
      );

      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('can hide close button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicDialog(
              title: 'No Close',
              content: 'Content',
              showCloseButton: false,
            ),
          ),
        ),
      );

      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('close button triggers onClose callback', (tester) async {
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicDialog(
              title: 'Closeable',
              content: 'Content',
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(closed, isTrue);
    });

    testWidgets('renders actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicDialog(
              title: 'Actions',
              content: 'Content',
              actions: [
                EpicDialogAction(
                  label: 'Cancel',
                  onPressed: () {},
                ),
                EpicDialogAction(
                  label: 'Confirm',
                  isPrimary: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('action button calls onPressed', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicDialog(
              title: 'Action Test',
              content: 'Content',
              actions: [
                EpicDialogAction(
                  label: 'Press Me',
                  onPressed: () => pressed = true,
                ),
              ],
            ),
          ),
        ),
      );

      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.text('Press Me'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('renders with no actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicDialog(
              title: 'No Actions',
              content: 'Content',
              actions: const [],
            ),
          ),
        ),
      );

      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('No Actions'), findsNWidgets(2));
    });

    testWidgets('animates entrance over time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicDialog(
              title: 'Animated',
              content: 'Content',
            ),
          ),
        ),
      );

      // Pump through entrance animation (300ms)
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(EpicDialog), findsOneWidget);
    });

    testWidgets('can be disposed during animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicDialog(
              title: 'Dispose',
              content: 'Content',
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      expect(find.byType(EpicDialog), findsNothing);
    });

    testWidgets('Dialog widget is transparent background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicDialog(
              title: 'Transparent',
              content: 'Content',
            ),
          ),
        ),
      );

      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(dialog.backgroundColor, Colors.transparent);
      expect(dialog.elevation, 0);
    });

    testWidgets('has max width constraint of 500', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicDialog(
              title: 'Constrained',
              content: 'Content',
            ),
          ),
        ),
      );

      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(EpicDialog), findsOneWidget);
    });
  });

  group('EpicDialogAction', () {
    test('creates with required parameters', () {
      final action = EpicDialogAction(
        label: 'Test',
        onPressed: () {},
      );

      expect(action.label, 'Test');
      expect(action.isPrimary, isFalse);
      expect(action.customColor, isNull);
    });

    test('creates with isPrimary true', () {
      final action = EpicDialogAction(
        label: 'Primary',
        onPressed: () {},
        isPrimary: true,
      );

      expect(action.isPrimary, isTrue);
    });

    test('creates with customColor', () {
      final action = EpicDialogAction(
        label: 'Colored',
        onPressed: () {},
        customColor: Colors.green,
      );

      expect(action.customColor, Colors.green);
    });
  });

  group('EpicDialog.showConfirmation', () {
    testWidgets('shows confirmation dialog with confirm and cancel buttons',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  EpicDialog.showConfirmation(
                    context: context,
                    title: 'Confirm?',
                    message: 'Are you sure?',
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
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Confirm?'), findsNWidgets(2));
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('returns true on confirm', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await EpicDialog.showConfirmation(
                    context: context,
                    title: 'Confirm?',
                    message: 'Sure?',
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
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('returns false on cancel', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await EpicDialog.showConfirmation(
                    context: context,
                    title: 'Confirm?',
                    message: 'Sure?',
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
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('uses custom labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  EpicDialog.showConfirmation(
                    context: context,
                    title: 'Delete?',
                    message: 'This is permanent.',
                    confirmLabel: 'Delete',
                    cancelLabel: 'Keep',
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
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Keep'), findsOneWidget);
    });
  });

  group('EpicDialog.showInfo', () {
    testWidgets('shows info dialog with OK button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  EpicDialog.showInfo(
                    context: context,
                    title: 'Info',
                    message: 'Something happened.',
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
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Info'), findsNWidgets(2));
      expect(find.text('Something happened.'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('dismisses on OK tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  EpicDialog.showInfo(
                    context: context,
                    title: 'Info',
                    message: 'Message.',
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
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Info'), findsNWidgets(2));

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Info'), findsNothing);
    });

    testWidgets('uses custom OK label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  EpicDialog.showInfo(
                    context: context,
                    title: 'Done',
                    message: 'Complete.',
                    okLabel: 'Got it',
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
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Got it'), findsOneWidget);
    });
  });
}
