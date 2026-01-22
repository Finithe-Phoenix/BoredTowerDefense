import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/tron_materialization_widget.dart';

void main() {
  testWidgets('TronMaterializationWidget renders grid pattern', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TronMaterializationWidget(
          duration: const Duration(milliseconds: 50),
          pattern: TronPattern.grid,
          child: const Text('CHILD'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('CHILD'), findsOneWidget);
  });

  testWidgets('TronMaterializationWidget renders hexagonal pattern', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TronMaterializationWidget(
          duration: const Duration(milliseconds: 50),
          pattern: TronPattern.hexagonal,
          reducedMotion: true,
          child: const Text('CHILD'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('CHILD'), findsOneWidget);
  });

  testWidgets('TronMaterializationWidget renders radial pattern', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TronMaterializationWidget(
          duration: const Duration(milliseconds: 50),
          pattern: TronPattern.radial,
          child: const Text('CHILD'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('CHILD'), findsOneWidget);
  });

  testWidgets('TronMaterializationWidget renders lightCycle pattern', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TronMaterializationWidget(
          duration: const Duration(milliseconds: 50),
          pattern: TronPattern.lightCycle,
          child: const Text('CHILD'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('CHILD'), findsOneWidget);
  });
}
