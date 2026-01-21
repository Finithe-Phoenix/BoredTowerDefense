import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/epic_neon_title.dart';

void main() {
  testWidgets('EpicNeonTitle shows the provided text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EpicNeonTitle(text: 'NEON SIGNAL'),
        ),
      ),
    );

    expect(find.text('NEON SIGNAL'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
