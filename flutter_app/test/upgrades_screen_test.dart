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

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('UPGRADE FORGE'), findsOneWidget);
    expect(find.text('DATA CORES'), findsOneWidget);
    expect(find.byType(EpicNeonButton), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('UpgradesScreen returns to previous route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UpgradesScreen()),
            ),
            child: const Text('OPEN'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(UpgradesScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(UpgradesScreen), findsNothing);
  });
}
