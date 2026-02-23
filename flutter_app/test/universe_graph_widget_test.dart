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
    final widget = tester.widget<UniverseGraphWidget>(graphFinder);
    widget.onWorldSelected(worlds.first.id);
    await tester.pump();

    expect(selectedWorld, worlds.first.id);
  });
}
