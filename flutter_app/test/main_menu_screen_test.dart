import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/screens/main_menu_screen.dart';
import 'package:bored_games/src/ui/widgets/tron_button.dart';

void main() {
  testWidgets('MainMenuScreen shows menu buttons after intro', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainMenuScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('NEON DEFENSE'), findsOneWidget);
    expect(find.widgetWithText(TronButton, 'CAMPAIGN'), findsOneWidget);
    expect(find.widgetWithText(TronButton, 'STORY'), findsOneWidget);
    expect(find.widgetWithText(TronButton, 'CODEX'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
