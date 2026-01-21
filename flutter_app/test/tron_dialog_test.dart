import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/tron_dialog.dart';

void main() {
  testWidgets('TronDialog show renders and closes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                TronDialog.show(
                  context: context,
                  title: 'DIALOG',
                  builder: (_) => const Text('CONTENT'),
                );
              },
              child: const Text('OPEN'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('DIALOG'), findsOneWidget);
    expect(find.text('CONTENT'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('DIALOG'), findsNothing);
  });
}
