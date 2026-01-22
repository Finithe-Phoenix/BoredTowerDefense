import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/transitions/tron_page_route.dart';
import 'package:bored_games/src/ui/widgets/tron_materialization_widget.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';

void main() {
  group('TronPageRoute', () {
    test('variants expose expected patterns', () {
      final grid = TronGridPageRoute(builder: (_) => const SizedBox());
      final hex = TronHexPageRoute(builder: (_) => const SizedBox());
      final radial = TronRadialPageRoute(builder: (_) => const SizedBox());

      expect(grid.pattern, TronPattern.grid);
      expect(hex.pattern, TronPattern.hexagonal);
      expect(radial.pattern, TronPattern.radial);
    });

    test('default pattern is lightCycle', () {
      final route = TronPageRoute(builder: (_) => const SizedBox());
      expect(route.pattern, TronPattern.lightCycle);
    });

    test('default colors are cyan and orange', () {
      final route = TronPageRoute(builder: (_) => const SizedBox());
      expect(route.primaryColor, NeonColors.cyan);
      expect(route.secondaryColor, const Color(0xFFFF6600));
    });

    test('custom colors are applied', () {
      final route = TronPageRoute(
        builder: (_) => const SizedBox(),
        primaryColor: Colors.red,
        secondaryColor: Colors.blue,
      );
      expect(route.primaryColor, Colors.red);
      expect(route.secondaryColor, Colors.blue);
    });

    test('barrierColor is black', () {
      final route = TronPageRoute(builder: (_) => const SizedBox());
      expect(route.barrierColor, Colors.black);
    });

    test('barrierLabel is null', () {
      final route = TronPageRoute(builder: (_) => const SizedBox());
      expect(route.barrierLabel, isNull);
    });

    test('maintainState is true', () {
      final route = TronPageRoute(builder: (_) => const SizedBox());
      expect(route.maintainState, isTrue);
    });

    test('default transition duration is 800ms', () {
      final route = TronPageRoute(builder: (_) => const SizedBox());
      expect(route.transitionDuration, const Duration(milliseconds: 800));
    });

    test('custom transition duration is applied', () {
      final route = TronPageRoute(
        builder: (_) => const SizedBox(),
        transitionDuration: const Duration(milliseconds: 500),
      );
      expect(route.transitionDuration, const Duration(milliseconds: 500));
    });

    test('settings are passed through', () {
      const settings = RouteSettings(name: '/test');
      final route = TronPageRoute(
        builder: (_) => const SizedBox(),
        settings: settings,
      );
      expect(route.settings.name, '/test');
    });

    testWidgets('wraps content in materialization', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    TronPageRoute(
                      builder: (_) => const Text('NEXT'),
                      transitionDuration: const Duration(milliseconds: 200),
                    ),
                  );
                },
                child: const Text('GO'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('GO'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TronMaterializationWidget), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
    });

    testWidgets('applies fade transition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    TronPageRoute(
                      builder: (_) => const Scaffold(body: Text('PAGE 2')),
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                },
                child: const Text('NAVIGATE'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('NAVIGATE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FadeTransition), findsWidgets);
    });
  });

  group('TronHexPageRoute', () {
    test('has hexagonal pattern', () {
      final route = TronHexPageRoute(builder: (_) => const SizedBox());
      expect(route.pattern, TronPattern.hexagonal);
    });

    test('default transition duration is 1000ms', () {
      final route = TronHexPageRoute(builder: (_) => const SizedBox());
      expect(route.transitionDuration, const Duration(milliseconds: 1000));
    });

    test('accepts custom colors', () {
      final route = TronHexPageRoute(
        builder: (_) => const SizedBox(),
        primaryColor: Colors.green,
      );
      expect(route.primaryColor, Colors.green);
    });

    testWidgets('navigates with hex pattern', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    TronHexPageRoute(
                      builder: (_) => const Text('HEX'),
                      transitionDuration: const Duration(milliseconds: 100),
                    ),
                  );
                },
                child: const Text('GO HEX'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('GO HEX'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('HEX'), findsOneWidget);
    });
  });

  group('TronRadialPageRoute', () {
    test('has radial pattern', () {
      final route = TronRadialPageRoute(builder: (_) => const SizedBox());
      expect(route.pattern, TronPattern.radial);
    });

    test('default transition duration is 900ms', () {
      final route = TronRadialPageRoute(builder: (_) => const SizedBox());
      expect(route.transitionDuration, const Duration(milliseconds: 900));
    });

    test('accepts custom secondary color', () {
      final route = TronRadialPageRoute(
        builder: (_) => const SizedBox(),
        secondaryColor: Colors.purple,
      );
      expect(route.secondaryColor, Colors.purple);
    });

    testWidgets('navigates with radial pattern', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    TronRadialPageRoute(
                      builder: (_) => const Text('RADIAL'),
                      transitionDuration: const Duration(milliseconds: 100),
                    ),
                  );
                },
                child: const Text('GO RADIAL'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('GO RADIAL'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('RADIAL'), findsOneWidget);
    });
  });

  group('TronGridPageRoute', () {
    test('has grid pattern', () {
      final route = TronGridPageRoute(builder: (_) => const SizedBox());
      expect(route.pattern, TronPattern.grid);
    });

    test('default transition duration is 800ms', () {
      final route = TronGridPageRoute(builder: (_) => const SizedBox());
      expect(route.transitionDuration, const Duration(milliseconds: 800));
    });

    test('accepts settings', () {
      final route = TronGridPageRoute(
        builder: (_) => const SizedBox(),
        settings: const RouteSettings(name: '/grid-page'),
      );
      expect(route.settings.name, '/grid-page');
    });

    testWidgets('navigates with grid pattern', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    TronGridPageRoute(
                      builder: (_) => const Text('GRID'),
                      transitionDuration: const Duration(milliseconds: 100),
                    ),
                  );
                },
                child: const Text('GO GRID'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('GO GRID'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('GRID'), findsOneWidget);
    });
  });

  group('Navigation behavior', () {
    testWidgets('can pop back from TronPageRoute', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    TronPageRoute(
                      builder: (ctx) => ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('BACK'),
                      ),
                      transitionDuration: const Duration(milliseconds: 100),
                    ),
                  );
                },
                child: const Text('FORWARD'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('FORWARD'));
      await tester.pumpAndSettle();

      expect(find.text('BACK'), findsOneWidget);

      await tester.tap(find.text('BACK'));
      await tester.pumpAndSettle();

      expect(find.text('FORWARD'), findsOneWidget);
    });

    testWidgets('multiple route types can be used in sequence', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    TronGridPageRoute(
                      builder: (ctx) => ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).push(
                            TronHexPageRoute(
                              builder: (_) => const Text('LEVEL 2'),
                              transitionDuration: const Duration(milliseconds: 50),
                            ),
                          );
                        },
                        child: const Text('LEVEL 1'),
                      ),
                      transitionDuration: const Duration(milliseconds: 50),
                    ),
                  );
                },
                child: const Text('START'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();

      expect(find.text('LEVEL 1'), findsOneWidget);

      await tester.tap(find.text('LEVEL 1'));
      await tester.pumpAndSettle();

      expect(find.text('LEVEL 2'), findsOneWidget);
    });
  });
}
