import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/tron_card.dart';

void main() {
  testWidgets('TronCard fires onTap after materialization', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: TronCard(
          materializationDuration: const Duration(milliseconds: 120),
          child: const SizedBox(width: 120, height: 80),
          onTap: () => taps++,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(TronCard));
    await tester.pump();

    expect(taps, 1);
  });
}
