import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bored_games/src/services/storage_service.dart';
import 'package:bored_games/src/services/upgrade_service.dart';
import 'package:bored_games/src/ui/screens/upgrades_screen.dart';
import 'package:bored_games/src/ui/widgets/epic_neon_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetForTesting();
    UpgradeService.instance.resetForTesting();
  });

  testWidgets('UpgradesScreen shows loading then content', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: UpgradesScreen()));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('UPGRADE FORGE'), findsOneWidget);
    expect(find.text('DATA CORES'), findsOneWidget);
    expect(find.byType(EpicNeonButton), findsWidgets);
  });

  testWidgets('UpgradesScreen returns to previous route', (tester) async {
    late BuildContext rootContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            rootContext = context;
            return ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UpgradesScreen()),
              ),
              child: const Text('OPEN'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(UpgradesScreen), findsOneWidget);

    expect(Navigator.of(rootContext).canPop(), isTrue);
    Navigator.of(rootContext).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(UpgradesScreen), findsNothing);
    expect(find.text('OPEN'), findsOneWidget);
  });
}
