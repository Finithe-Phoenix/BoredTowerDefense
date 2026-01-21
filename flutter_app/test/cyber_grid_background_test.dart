import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/cyber_grid_background.dart';

void main() {
  testWidgets('CyberGridBackground renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CyberGridBackground(
          enableGlitch: false,
          child: Text('CYBER GRID'),
        ),
      ),
    );

    expect(find.text('CYBER GRID'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('CyberGridBackground omits scanlines when glitch is disabled', (tester) async {
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

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
