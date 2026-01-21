import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/screens/codex_screen.dart';
import 'package:bored_games/src/ui/widgets/epic_neon_button.dart';
import 'package:bored_games/src/ui/widgets/glitch_text.dart';

void main() {
  testWidgets('CodexScreen shows header and navigation button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CodexScreen(),
      ),
    );

    final header = tester.widget<GlitchText>(find.byType(GlitchText));
    expect(header.text, 'ARCHIVOS DEL SISTEMA');
    expect(find.text('TODOS'), findsOneWidget);
    expect(find.widgetWithText(EpicNeonButton, 'VOLVER'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
