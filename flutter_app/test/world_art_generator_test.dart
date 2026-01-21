import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/world_art_generator.dart';

void main() {
  testWidgets('WorldArtGenerator respects the provided size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: WorldArtGenerator(
            worldId: 1,
            accentColor: Colors.cyan,
            width: 240,
            height: 160,
            animate: false,
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(WorldArtGenerator)), const Size(240, 160));
  });

  testWidgets('WorldArtGenerator invokes onTap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: WorldArtGenerator(
            worldId: 2,
            accentColor: Colors.cyan,
            width: 200,
            height: 140,
            animate: false,
            onTap: () => tapped++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(WorldArtGenerator));
    await tester.pump();

    expect(tapped, 1);
  });
}
