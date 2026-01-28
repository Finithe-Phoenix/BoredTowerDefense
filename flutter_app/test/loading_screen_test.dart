import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/screens/loading_screen.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';

// Helper to dispose LoadingScreen by replacing the widget, triggering timer cleanup
Future<void> disposeLoadingScreen(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
  await tester.pump();
}

void main() {
  group('LoadingScreen', () {
    testWidgets('renders loading screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => const LoadingScreen(),
            '/menu': (context) => const Scaffold(body: Text('MENU')),
          },
        ),
      );

      expect(find.byType(LoadingScreen), findsOneWidget);

      await disposeLoadingScreen(tester);
    });

    testWidgets('shows loading status text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => const LoadingScreen(),
            '/menu': (context) => const Scaffold(body: Text('MENU')),
          },
        ),
      );

      // Should show some loading/status text
      await tester.pump();

      // The loading screen shows various loading states
      // Check for common loading-related text patterns
      final hasLoadingText =
          find.textContaining('LOADING').evaluate().isNotEmpty ||
          find.textContaining('INITIALIZING').evaluate().isNotEmpty ||
          find.textContaining('READY').evaluate().isNotEmpty;
      expect(hasLoadingText, isTrue);

      await disposeLoadingScreen(tester);
    });

    testWidgets('shows version text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => const LoadingScreen(),
            '/menu': (context) => const Scaffold(body: Text('MENU')),
          },
        ),
      );

      expect(find.textContaining('NEON DEFENSE'), findsOneWidget);

      await disposeLoadingScreen(tester);
    });

    testWidgets('shows progress percentage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => const LoadingScreen(),
            '/menu': (context) => const Scaffold(body: Text('MENU')),
          },
        ),
      );

      // Should show some percentage
      expect(find.textContaining('%'), findsOneWidget);

      await disposeLoadingScreen(tester);
    });

    testWidgets('has dark background color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => const LoadingScreen(),
            '/menu': (context) => const Scaffold(body: Text('MENU')),
          },
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, NeonColors.darkBg);

      await disposeLoadingScreen(tester);
    });

    testWidgets('contains CustomPaint widgets for graphics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => const LoadingScreen(),
            '/menu': (context) => const Scaffold(body: Text('MENU')),
          },
        ),
      );

      // Should have custom paint for spinner and grid
      expect(find.byType(CustomPaint), findsWidgets);

      await disposeLoadingScreen(tester);
    });

    testWidgets('animates over time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => const LoadingScreen(),
            '/menu': (context) => const Scaffold(body: Text('MENU')),
          },
        ),
      );

      // Pump through some frames
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(LoadingScreen), findsOneWidget);

      await disposeLoadingScreen(tester);
    });

    testWidgets('can be disposed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Replace widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('REPLACED')),
        ),
      );
      await tester.pump();

      expect(find.text('REPLACED'), findsOneWidget);
    });

    testWidgets('uses Stack for layered content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => const LoadingScreen(),
            '/menu': (context) => const Scaffold(body: Text('MENU')),
          },
        ),
      );

      expect(find.byType(Stack), findsWidgets);

      await disposeLoadingScreen(tester);
    });

    testWidgets('uses Center for main content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => const LoadingScreen(),
            '/menu': (context) => const Scaffold(body: Text('MENU')),
          },
        ),
      );

      expect(find.byType(Center), findsWidgets);

      await disposeLoadingScreen(tester);
    });

    testWidgets('uses Column for vertical layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => const LoadingScreen(),
            '/menu': (context) => const Scaffold(body: Text('MENU')),
          },
        ),
      );

      expect(find.byType(Column), findsWidgets);

      await disposeLoadingScreen(tester);
    });
  });
}
