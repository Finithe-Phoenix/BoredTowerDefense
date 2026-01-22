import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/screens/benchmark_screen.dart';
import 'package:bored_games/src/ui/widgets/tron_button.dart';

void main() {
  testWidgets('BenchmarkScreen renders start state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BenchmarkScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('BENCHMARK MODE'), findsOneWidget);
    expect(find.widgetWithText(TronButton, 'INICIAR BENCHMARK'), findsOneWidget);
  });
}
