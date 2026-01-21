import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/transitions/tron_page_route.dart';
import 'package:bored_games/src/ui/widgets/tron_materialization_widget.dart';

void main() {
  test('TronPageRoute variants expose expected patterns', () {
    final grid = TronGridPageRoute(builder: (_) => const SizedBox());
    final hex = TronHexPageRoute(builder: (_) => const SizedBox());
    final radial = TronRadialPageRoute(builder: (_) => const SizedBox());

    expect(grid.pattern, TronPattern.grid);
    expect(hex.pattern, TronPattern.hexagonal);
    expect(radial.pattern, TronPattern.radial);
  });

  testWidgets('TronPageRoute wraps content in materialization', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  TronPageRoute(
                    builder: (_) => const Text('NEXT'),
                    transitionDuration: const Duration(milliseconds: 200),
                  ),
                );
              },
              child: const Text('GO'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('GO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TronMaterializationWidget), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
  });
}
