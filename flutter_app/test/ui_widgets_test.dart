import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/widgets/glitch_text.dart';
import 'package:bored_games/src/ui/widgets/neon_button.dart';
import 'package:bored_games/src/ui/widgets/tron_button.dart';
import 'package:bored_games/src/ui/widgets/tron_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GlitchText resolves to full text after duration', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: GlitchText(
        text: 'TEST',
        duration: Duration(milliseconds: 20),
      ),
    ));

    await tester.pump(const Duration(milliseconds: 30));

    expect(find.text('TEST'), findsOneWidget);
  });

  testWidgets('NeonButton fires callback when enabled', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: NeonButton(
          text: 'Go',
          onPressed: () => pressed++,
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(pressed, 1);
  });

  testWidgets('NeonButton does not fire when disabled', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: NeonButton(
          text: 'Go',
          enabled: false,
          onPressed: () => pressed++,
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(pressed, 0);
  });

  testWidgets('TronButton fires after materialization', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TronButton(
          text: 'GO',
          onPressed: () => pressed++,
          delay: Duration.zero,
          materializationDuration: const Duration(milliseconds: 50),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
    final tronButton = tester.widget<TronButton>(find.byType(TronButton));
    tronButton.onPressed();
    expect(pressed, 1);
  });

  testWidgets('TronCard fires onTap when enabled', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TronCard(
          onTap: () => tapped++,
          delay: Duration.zero,
          materializationDuration: const Duration(milliseconds: 50),
          child: const Text('CARD'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
    final tronCard = tester.widget<TronCard>(find.byType(TronCard));
    tronCard.onTap?.call();
    expect(tapped, 1);
  });
}
