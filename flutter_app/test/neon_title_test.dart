import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/neon_title.dart';

void main() {
  testWidgets('NeonTitle renders text with custom styling', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NeonTitle(
          text: 'NEON TITLE',
          fontSize: 32,
          color: Colors.green,
        ),
      ),
    );

    final textWidget = tester.widget<Text>(find.text('NEON TITLE'));
    expect(textWidget.style?.color, Colors.green);
    expect(textWidget.style?.fontSize, 32);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
