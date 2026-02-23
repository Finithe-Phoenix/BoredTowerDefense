import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/universal_transition.dart';

void main() {
  group('UniversalTransition.dataStreamWipe', () {
    testWidgets('creates a valid PageRouteBuilder', (tester) async {
      final route = UniversalTransition.dataStreamWipe(
        builder: (context) => const Text('New Screen'),
      );

      expect(route, isA<PageRouteBuilder>());
    });

    testWidgets('navigates to the new screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    UniversalTransition.dataStreamWipe(
                      builder: (context) =>
                          const Scaffold(body: Text('NEW SCREEN')),
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
      await tester.pumpAndSettle();

      expect(find.text('NEW SCREEN'), findsOneWidget);
    });

    testWidgets('uses default duration of 500ms', (tester) async {
      final route = UniversalTransition.dataStreamWipe(
        builder: (context) => const SizedBox(),
      );

      expect(route.transitionDuration, const Duration(milliseconds: 500));
    });

    testWidgets('accepts custom duration', (tester) async {
      final route = UniversalTransition.dataStreamWipe(
        builder: (context) => const SizedBox(),
        duration: const Duration(milliseconds: 800),
      );

      expect(route.transitionDuration, const Duration(milliseconds: 800));
    });

    testWidgets('reverse transition duration matches forward', (tester) async {
      final route = UniversalTransition.dataStreamWipe(
        builder: (context) => const SizedBox(),
        duration: const Duration(milliseconds: 700),
      );

      expect(route.reverseTransitionDuration,
          const Duration(milliseconds: 700));
    });

    testWidgets('animates during transition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    UniversalTransition.dataStreamWipe(
                      builder: (context) =>
                          const Scaffold(body: Text('TARGET')),
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

      // Pump through animation frames
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('TARGET'), findsOneWidget);
    });
  });

  group('UniversalTransition.hexagonReveal', () {
    testWidgets('creates a valid PageRouteBuilder', (tester) async {
      final route = UniversalTransition.hexagonReveal(
        builder: (context) => const Text('Hex Screen'),
      );

      expect(route, isA<PageRouteBuilder>());
    });

    testWidgets('navigates to the new screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    UniversalTransition.hexagonReveal(
                      builder: (context) =>
                          const Scaffold(body: Text('HEX SCREEN')),
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
      await tester.pumpAndSettle();

      expect(find.text('HEX SCREEN'), findsOneWidget);
    });

    testWidgets('uses default duration of 600ms', (tester) async {
      final route = UniversalTransition.hexagonReveal(
        builder: (context) => const SizedBox(),
      );

      expect(route.transitionDuration, const Duration(milliseconds: 600));
    });

    testWidgets('accepts custom duration', (tester) async {
      final route = UniversalTransition.hexagonReveal(
        builder: (context) => const SizedBox(),
        duration: const Duration(milliseconds: 900),
      );

      expect(route.transitionDuration, const Duration(milliseconds: 900));
    });

    testWidgets('animates during transition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    UniversalTransition.hexagonReveal(
                      builder: (context) =>
                          const Scaffold(body: Text('HEX TARGET')),
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
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('HEX TARGET'), findsOneWidget);
    });
  });

  group('UniversalTransition.energyBurst', () {
    testWidgets('creates a valid PageRouteBuilder', (tester) async {
      final route = UniversalTransition.energyBurst(
        builder: (context) => const Text('Energy'),
      );

      expect(route, isA<PageRouteBuilder>());
    });

    testWidgets('navigates to the new screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    UniversalTransition.energyBurst(
                      builder: (context) =>
                          const Scaffold(body: Text('ENERGY SCREEN')),
                    ),
                  );
                },
                child: const Text('BURST'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('BURST'));
      await tester.pumpAndSettle();

      expect(find.text('ENERGY SCREEN'), findsOneWidget);
    });

    testWidgets('uses default duration of 550ms', (tester) async {
      final route = UniversalTransition.energyBurst(
        builder: (context) => const SizedBox(),
      );

      expect(route.transitionDuration, const Duration(milliseconds: 550));
    });

    testWidgets('accepts custom duration', (tester) async {
      final route = UniversalTransition.energyBurst(
        builder: (context) => const SizedBox(),
        duration: const Duration(milliseconds: 1000),
      );

      expect(route.transitionDuration, const Duration(milliseconds: 1000));
    });
  });

  group('UniversalTransition.glitchDistortion', () {
    testWidgets('creates a valid PageRouteBuilder', (tester) async {
      final route = UniversalTransition.glitchDistortion(
        builder: (context) => const Text('Glitch'),
      );

      expect(route, isA<PageRouteBuilder>());
    });

    testWidgets('navigates to the new screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    UniversalTransition.glitchDistortion(
                      builder: (context) =>
                          const Scaffold(body: Text('GLITCH SCREEN')),
                    ),
                  );
                },
                child: const Text('GLITCH'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('GLITCH'));
      await tester.pumpAndSettle();

      expect(find.text('GLITCH SCREEN'), findsOneWidget);
    });

    testWidgets('uses default duration of 400ms', (tester) async {
      final route = UniversalTransition.glitchDistortion(
        builder: (context) => const SizedBox(),
      );

      expect(route.transitionDuration, const Duration(milliseconds: 400));
    });

    testWidgets('accepts custom duration', (tester) async {
      final route = UniversalTransition.glitchDistortion(
        builder: (context) => const SizedBox(),
        duration: const Duration(milliseconds: 600),
      );

      expect(route.transitionDuration, const Duration(milliseconds: 600));
    });

    testWidgets('animates glitch effect mid-transition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    UniversalTransition.glitchDistortion(
                      builder: (context) =>
                          const Scaffold(body: Text('GLITCH TARGET')),
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

      // Pump through transition frames to hit glitch peak (0.3-0.5)
      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }

      expect(find.text('GLITCH TARGET'), findsOneWidget);
    });
  });

  group('UniversalTransition.epic', () {
    testWidgets('creates a valid PageRouteBuilder', (tester) async {
      final route = UniversalTransition.epic(
        builder: (context) => const Text('Epic'),
      );

      expect(route, isA<PageRouteBuilder>());
    });

    testWidgets('navigates to the new screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    UniversalTransition.epic(
                      builder: (context) =>
                          const Scaffold(body: Text('EPIC SCREEN')),
                    ),
                  );
                },
                child: const Text('EPIC'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('EPIC'));
      await tester.pumpAndSettle();

      expect(find.text('EPIC SCREEN'), findsOneWidget);
    });

    testWidgets('uses default duration of 500ms (same as dataStreamWipe)',
        (tester) async {
      final route = UniversalTransition.epic(
        builder: (context) => const SizedBox(),
      );

      expect(route.transitionDuration, const Duration(milliseconds: 500));
    });

    testWidgets('accepts custom duration', (tester) async {
      final route = UniversalTransition.epic(
        builder: (context) => const SizedBox(),
        duration: const Duration(milliseconds: 750),
      );

      expect(route.transitionDuration, const Duration(milliseconds: 750));
    });
  });

  group('UniversalTransition back navigation', () {
    testWidgets('dataStreamWipe supports pop navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    UniversalTransition.dataStreamWipe(
                      builder: (context) => Scaffold(
                        body: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('GO BACK'),
                        ),
                      ),
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

      expect(find.text('GO BACK'), findsOneWidget);

      await tester.tap(find.text('GO BACK'));
      await tester.pumpAndSettle();

      expect(find.text('FORWARD'), findsOneWidget);
    });

    testWidgets('hexagonReveal supports pop navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    UniversalTransition.hexagonReveal(
                      builder: (context) => Scaffold(
                        body: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('GO BACK'),
                        ),
                      ),
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

      await tester.tap(find.text('GO BACK'));
      await tester.pumpAndSettle();

      expect(find.text('FORWARD'), findsOneWidget);
    });
  });
}
