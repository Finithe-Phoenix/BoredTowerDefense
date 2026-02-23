import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/main.dart';
import 'package:bored_games/src/ui/screens/benchmark_screen.dart';
import 'package:bored_games/src/ui/screens/codex_screen.dart';
import 'package:bored_games/src/ui/screens/game_screen.dart';
import 'package:bored_games/src/ui/screens/level_select_screen.dart';
import 'package:bored_games/src/ui/screens/loading_screen.dart';
import 'package:bored_games/src/ui/screens/main_menu_screen.dart';
import 'package:bored_games/src/ui/screens/settings_screen.dart';
import 'package:bored_games/src/ui/screens/story_screen.dart';
import 'package:bored_games/src/ui/screens/upgrades_screen.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';
import 'package:bored_games/src/ui/transitions/tron_page_route.dart';
import 'package:bored_games/src/ui/widgets/tron_materialization_widget.dart';

class _TronRouteExpectation {
  const _TronRouteExpectation({
    required this.path,
    required this.pattern,
    required this.duration,
    required this.primaryColor,
    required this.secondaryColor,
    required this.screenType,
  });

  final String path;
  final TronPattern pattern;
  final Duration duration;
  final Color primaryColor;
  final Color secondaryColor;
  final Type screenType;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Route<dynamic> _routeFor(
    WidgetTester tester,
    String path, {
    Object? arguments,
  }) {
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final route = app.onGenerateRoute?.call(
      RouteSettings(name: path, arguments: arguments),
    );
    expect(route, isNotNull, reason: 'Expected route for $path');
    return route!;
  }

  BuildContext _appContext(WidgetTester tester) {
    return tester.element(find.byType(MaterialApp));
  }

  group('NeonDefenseApp routing', () {
    testWidgets('configures app shell and loading entrypoint', (tester) async {
      await tester.pumpWidget(const NeonDefenseApp());

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, 'Neon Defense');
      expect(app.debugShowCheckedModeBanner, isFalse);
      expect(app.initialRoute, '/');
      expect(
        app.theme?.scaffoldBackgroundColor,
        NeonTheme.darkTheme.scaffoldBackgroundColor,
      );
      expect(find.byType(LoadingScreen), findsOneWidget);
    });

    testWidgets('maps named Tron routes to expected screens and visuals',
        (tester) async {
      await tester.pumpWidget(const NeonDefenseApp());
      final context = _appContext(tester);

      const expectations = <_TronRouteExpectation>[
        _TronRouteExpectation(
          path: '/menu',
          pattern: TronPattern.lightCycle,
          duration: Duration(milliseconds: 900),
          primaryColor: NeonColors.cyan,
          secondaryColor: Color(0xFFFF6600),
          screenType: MainMenuScreen,
        ),
        _TronRouteExpectation(
          path: '/levels',
          pattern: TronPattern.hexagonal,
          duration: Duration(milliseconds: 850),
          primaryColor: NeonColors.magenta,
          secondaryColor: NeonColors.cyan,
          screenType: LevelSelectScreen,
        ),
        _TronRouteExpectation(
          path: '/story',
          pattern: TronPattern.grid,
          duration: Duration(milliseconds: 800),
          primaryColor: NeonColors.purple,
          secondaryColor: NeonColors.cyan,
          screenType: StoryScreen,
        ),
        _TronRouteExpectation(
          path: '/settings',
          pattern: TronPattern.lightCycle,
          duration: Duration(milliseconds: 800),
          primaryColor: NeonColors.blue,
          secondaryColor: NeonColors.cyan,
          screenType: SettingsScreen,
        ),
        _TronRouteExpectation(
          path: '/upgrades',
          pattern: TronPattern.hexagonal,
          duration: Duration(milliseconds: 850),
          primaryColor: NeonColors.yellow,
          secondaryColor: NeonColors.orange,
          screenType: UpgradesScreen,
        ),
        _TronRouteExpectation(
          path: '/benchmark',
          pattern: TronPattern.radial,
          duration: Duration(milliseconds: 900),
          primaryColor: Color(0xFFFF6600),
          secondaryColor: NeonColors.cyan,
          screenType: BenchmarkScreen,
        ),
        _TronRouteExpectation(
          path: '/codex',
          pattern: TronPattern.grid,
          duration: Duration(milliseconds: 850),
          primaryColor: NeonColors.magenta,
          secondaryColor: NeonColors.cyan,
          screenType: CodexScreen,
        ),
      ];

      for (final expected in expectations) {
        final route = _routeFor(tester, expected.path);
        expect(route, isA<TronPageRoute<dynamic>>());

        final tronRoute = route as TronPageRoute<dynamic>;
        expect(tronRoute.pattern, expected.pattern);
        expect(tronRoute.transitionDuration, expected.duration);
        expect(tronRoute.primaryColor, expected.primaryColor);
        expect(tronRoute.secondaryColor, expected.secondaryColor);
        expect(tronRoute.builder(context).runtimeType, expected.screenType);
      }
    });

    testWidgets('maps /game route with default and explicit level IDs',
        (tester) async {
      await tester.pumpWidget(const NeonDefenseApp());
      final context = _appContext(tester);

      final defaultRoute = _routeFor(tester, '/game');
      expect(defaultRoute, isA<TronPageRoute<dynamic>>());
      final defaultTronRoute = defaultRoute as TronPageRoute<dynamic>;
      final defaultGame = defaultTronRoute.builder(context) as GameScreen;
      expect(defaultTronRoute.pattern, TronPattern.radial);
      expect(
        defaultTronRoute.transitionDuration,
        const Duration(milliseconds: 1000),
      );
      expect(defaultGame.levelId, 1);

      final explicitRoute = _routeFor(tester, '/game', arguments: 7);
      expect(explicitRoute, isA<TronPageRoute<dynamic>>());
      final explicitGame = (explicitRoute as TronPageRoute<dynamic>)
          .builder(context) as GameScreen;
      expect(explicitGame.levelId, 7);
    });

    testWidgets('falls back to loading route for unknown paths',
        (tester) async {
      await tester.pumpWidget(const NeonDefenseApp());
      final context = _appContext(tester);

      final route = _routeFor(tester, '/not-found');
      expect(route, isA<MaterialPageRoute<dynamic>>());
      final fallback = (route as MaterialPageRoute<dynamic>).builder(context);
      expect(fallback, isA<LoadingScreen>());
    });
  });
}
