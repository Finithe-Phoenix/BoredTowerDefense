import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/ui/screens/codex_screen.dart';
import 'package:bored_games/src/ui/widgets/epic_neon_button.dart';
import 'package:bored_games/src/ui/widgets/glitch_text.dart';

void main() {
  testWidgets('CodexScreen shows header and navigation button', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: CodexScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1200));

    final headerFinder = find.byWidgetPredicate(
      (widget) => widget is GlitchText && widget.text == 'ARCHIVOS DEL SISTEMA',
    );
    expect(headerFinder, findsOneWidget);
    expect(find.text('TODOS'), findsWidgets);
    expect(find.widgetWithText(EpicNeonButton, 'VOLVER'), findsOneWidget);
  });

  testWidgets('CodexScreen category tabs keep stable layout height', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: CodexScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1200));

    final tabsListFinder = find.byWidgetPredicate(
      (widget) => widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    expect(tabsListFinder, findsOneWidget);

    final tabsContainerFinders = find.ancestor(
      of: tabsListFinder,
      matching: find.byType(Container),
    );
    final hasTabsHeight = tabsContainerFinders.evaluate().any(
      (element) =>
          (element.widget as Container).constraints?.maxHeight == 112,
    );
    expect(hasTabsHeight, isTrue);
  });
}
