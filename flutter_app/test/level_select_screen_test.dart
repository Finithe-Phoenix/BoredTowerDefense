import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/screens/level_select_screen.dart';
import 'package:bored_games/src/ui/widgets/universe_graph_widget.dart';

void main() {
  testWidgets('LevelSelectScreen switches to level grid after selection', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LevelSelectScreen(),
      ),
    );

    await tester.pump();

    final graphFinder = find.byType(UniverseGraphWidget);
    expect(graphFinder, findsOneWidget);

    final graph = tester.widget<UniverseGraphWidget>(graphFinder);
    final box = tester.renderObject<RenderBox>(graphFinder);
    final size = box.size;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.35;
    final count = math.max(1, graph.worlds.length);
    final baseAngle = (0 / count) * math.pi * 2 - math.pi / 2;
    final orbitRadius = radius * 0.75;
    final target = Offset(
      center.dx + orbitRadius * math.cos(baseAngle),
      center.dy + orbitRadius * math.sin(baseAngle),
    );

    await tester.tapAt(box.localToGlobal(target));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('level_grid')), findsOneWidget);
  });
}
