import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/screens/level_select_screen.dart';
import 'package:bored_games/src/ui/widgets/universe_graph_widget.dart';

void main() {
  testWidgets('UniverseGraphWidget selects a world on tap', (tester) async {
    final worlds = [
      const WorldInfo(
        id: 1,
        name: 'Alpha',
        tagline: 'First',
        accent: Colors.cyan,
      ),
      const WorldInfo(
        id: 2,
        name: 'Beta',
        tagline: 'Second',
        accent: Color(0xFFFF00FF),
      ),
    ];
    int? selectedWorld;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 500,
              height: 500,
              child: UniverseGraphWidget(
                worlds: worlds,
                onWorldSelected: (id) => selectedWorld = id,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final graphFinder = find.byType(UniverseGraphWidget);
    final box = tester.renderObject<RenderBox>(graphFinder);
    final size = box.size;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.35;
    const index = 0;
    final baseAngle = (index / worlds.length) * math.pi * 2 - math.pi / 2;
    final orbitRadius = radius * 0.75;
    final target = Offset(
      center.dx + orbitRadius * math.cos(baseAngle),
      center.dy + orbitRadius * math.sin(baseAngle),
    );

    await tester.tapAt(box.localToGlobal(target));
    await tester.pump();

    expect(selectedWorld, worlds.first.id);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
