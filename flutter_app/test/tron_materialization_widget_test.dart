import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/tron_materialization_widget.dart';

void main() {
  testWidgets('TronMaterializationWidget renders for each pattern', (tester) async {
    Future<void> pumpPattern(TronPattern pattern, {bool reducedMotion = false}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TronMaterializationWidget(
            duration: const Duration(milliseconds: 50),
            pattern: pattern,
            reducedMotion: reducedMotion,
            child: const Text('CHILD'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('CHILD'), findsOneWidget);
    }

    await pumpPattern(TronPattern.grid);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpPattern(TronPattern.hexagonal, reducedMotion: true);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpPattern(TronPattern.radial);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpPattern(TronPattern.lightCycle);
  });
}
