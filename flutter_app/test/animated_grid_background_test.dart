import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/animated_grid_background.dart';

void main() {
  testWidgets('AnimatedGridBackground renders child content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnimatedGridBackground(
          child: Text('GRID CHILD'),
        ),
      ),
    );

    expect(find.text('GRID CHILD'), findsOneWidget);
  });
}
