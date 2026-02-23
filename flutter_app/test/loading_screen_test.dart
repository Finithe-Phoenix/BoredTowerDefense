import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bored_games/src/bloc/settings/settings_cubit.dart';
import 'package:bored_games/src/ui/screens/loading_screen.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';

// Helper to dispose LoadingScreen by replacing the widget, triggering timer cleanup
Future<void> disposeLoadingScreen(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
  await tester.pump();
}

int loadingPercent(WidgetTester tester) {
  final percentFinder = find.textContaining('%');
  expect(percentFinder, findsOneWidget);
  final progressText = tester.widget<Text>(percentFinder).data ?? '0%';
  return int.tryParse(progressText.replaceAll('%', '').trim()) ?? 0;
}

class _SlowSettingsCubit extends SettingsCubit {
  _SlowSettingsCubit({required this.delay});

  final Duration delay;

  @override
  Future<void> loadSettings() async {
    await Future<void>.delayed(delay);
  }
}

Widget _buildLoadingApp({
  SettingsCubit? settingsCubit,
  Widget? menuScreen,
}) {
  final app = MaterialApp(
    routes: {
      '/': (context) => const LoadingScreen(),
      '/menu': (context) => menuScreen ?? const Scaffold(body: Text('MENU')),
    },
  );

  if (settingsCubit == null) {
    return app;
  }

  return BlocProvider<SettingsCubit>.value(
    value: settingsCubit,
    child: app,
  );
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

    testWidgets('starts from zero percent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => const LoadingScreen(),
            '/menu': (context) => const Scaffold(body: Text('MENU')),
          },
        ),
      );

      expect(loadingPercent(tester), 0);

      await disposeLoadingScreen(tester);
    });

    testWidgets('shows all corner status indicators', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => const LoadingScreen(),
            '/menu': (context) => const Scaffold(body: Text('MENU')),
          },
        ),
      );

      expect(find.text('SYS'), findsOneWidget);
      expect(find.text('NET'), findsOneWidget);
      expect(find.text('MEM'), findsOneWidget);
      expect(find.text('CPU'), findsOneWidget);
      expect(find.text('OK'), findsNothing);

      await disposeLoadingScreen(tester);
    });

    testWidgets('supports route target for menu transition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => const LoadingScreen(),
            '/menu': (context) => const Scaffold(body: Text('MENU')),
          },
        ),
      );

      expect(find.byType(LoadingScreen), findsOneWidget);
      expect(find.text('MENU'), findsNothing);

      await disposeLoadingScreen(tester);
    });

    testWidgets(
        'updateProgress clamps values and updateLoadingText updates text',
        (tester) async {
      await tester.pumpWidget(_buildLoadingApp());

      final dynamic state = tester.state(find.byType(LoadingScreen));
      state.updateProgress(1.5);
      await tester.pump();
      expect(loadingPercent(tester), 100);

      state.updateProgress(-1.0);
      await tester.pump();
      expect(loadingPercent(tester), 0);

      state.updateLoadingText('PATCHING CACHE');
      await tester.pump();
      expect(find.text('PATCHING CACHE'), findsOneWidget);

      await disposeLoadingScreen(tester);
    });

    testWidgets('keeps loading screen visible while settings sync is pending',
        (tester) async {
      final cubit = _SlowSettingsCubit(delay: const Duration(seconds: 5));
      addTearDown(cubit.close);

      await tester.pumpWidget(_buildLoadingApp(settingsCubit: cubit));
      await tester.pump(const Duration(milliseconds: 1200));

      expect(find.byType(LoadingScreen), findsOneWidget);
      expect(find.text('MENU'), findsNothing);

      await disposeLoadingScreen(tester);
    });

    testWidgets('glitch layer appears while loading is active', (tester) async {
      final cubit = _SlowSettingsCubit(delay: const Duration(seconds: 5));
      addTearDown(cubit.close);

      await tester.pumpWidget(_buildLoadingApp(settingsCubit: cubit));
      await tester.pump();

      final baselineTransforms =
          tester.widgetList<Transform>(find.byType(Transform)).length;

      var sawGlitchTransforms = false;
      for (int i = 0; i < 35; i++) {
        await tester.pump(const Duration(milliseconds: 80));

        if (find.byType(LoadingScreen).evaluate().isEmpty) {
          break;
        }

        final transformCount =
            tester.widgetList<Transform>(find.byType(Transform)).length;
        if (transformCount > baselineTransforms) {
          sawGlitchTransforms = true;
          break;
        }
      }

      expect(sawGlitchTransforms, isTrue);

      await disposeLoadingScreen(tester);
    });
  });
}
