import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/cyber_grid_background.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';

void main() {
  group('CyberGridBackground', () {
    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CyberGridBackground(
            enableGlitch: false,
            child: Text('CYBER GRID'),
          ),
        ),
      );

      expect(find.text('CYBER GRID'), findsOneWidget);
    });

    testWidgets('omits scanlines when glitch is disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CyberGridBackground(
            enableGlitch: false,
          ),
        ),
      );

      final scanlineFinder = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter != null &&
            widget.painter.runtimeType.toString() == '_ScanlinePainter',
      );

      expect(scanlineFinder, findsNothing);
    });

    testWidgets('renders without child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CyberGridBackground(
            enableGlitch: false,
          ),
        ),
      );

      expect(find.byType(CyberGridBackground), findsOneWidget);
    });

    testWidgets('default backgroundColor is deepBlack', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CyberGridBackground(enableGlitch: false),
        ),
      );

      final widget = tester.widget<CyberGridBackground>(
        find.byType(CyberGridBackground),
      );
      expect(widget.backgroundColor, NeonColors.deepBlack);
    });

    testWidgets('default enableParticles is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CyberGridBackground(enableGlitch: false),
        ),
      );

      final widget = tester.widget<CyberGridBackground>(
        find.byType(CyberGridBackground),
      );
      expect(widget.enableParticles, isTrue);
    });

    testWidgets('default enableGlitch is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CyberGridBackground(),
        ),
      );

      final widget = tester.widget<CyberGridBackground>(
        find.byType(CyberGridBackground),
      );
      expect(widget.enableGlitch, isTrue);
    });

    testWidgets('default enableDataStreams is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CyberGridBackground(enableGlitch: false),
        ),
      );

      final widget = tester.widget<CyberGridBackground>(
        find.byType(CyberGridBackground),
      );
      expect(widget.enableDataStreams, isTrue);
    });

    testWidgets('accepts custom backgroundColor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CyberGridBackground(
            backgroundColor: Colors.blue,
            enableGlitch: false,
          ),
        ),
      );

      final widget = tester.widget<CyberGridBackground>(
        find.byType(CyberGridBackground),
      );
      expect(widget.backgroundColor, Colors.blue);
    });

    testWidgets('can disable particles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CyberGridBackground(
            enableParticles: false,
            enableGlitch: false,
          ),
        ),
      );

      final widget = tester.widget<CyberGridBackground>(
        find.byType(CyberGridBackground),
      );
      expect(widget.enableParticles, isFalse);
    });

    testWidgets('can disable data streams', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CyberGridBackground(
            enableDataStreams: false,
            enableGlitch: false,
          ),
        ),
      );

      final widget = tester.widget<CyberGridBackground>(
        find.byType(CyberGridBackground),
      );
      expect(widget.enableDataStreams, isFalse);
    });

    testWidgets('animates over time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CyberGridBackground(
            enableGlitch: false,
            child: Text('Animated'),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }

      expect(find.byType(CyberGridBackground), findsOneWidget);
    });

    testWidgets('can be disposed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CyberGridBackground(
            enableGlitch: false,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(),
        ),
      );

      expect(find.byType(CyberGridBackground), findsNothing);
    });

    testWidgets('renders with all effects disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CyberGridBackground(
            enableParticles: false,
            enableGlitch: false,
            enableDataStreams: false,
            child: Text('Minimal'),
          ),
        ),
      );

      expect(find.text('Minimal'), findsOneWidget);
    });

    testWidgets('renders complex child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CyberGridBackground(
            enableGlitch: false,
            child: Column(
              children: [
                Text('Line 1'),
                Text('Line 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Line 1'), findsOneWidget);
      expect(find.text('Line 2'), findsOneWidget);
    });
  });
}
