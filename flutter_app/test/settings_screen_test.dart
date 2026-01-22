import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/bloc/settings/settings_cubit.dart';
import 'package:bored_games/src/ui/screens/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen renders sections and reset button', (tester) async {
    final cubit = SettingsCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const SettingsScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('AUDIO'), findsOneWidget);
    expect(find.text('GRAPHICS'), findsOneWidget);
    expect(find.text('GAMEPLAY'), findsOneWidget);
    expect(find.text('RESET TO DEFAULTS'), findsOneWidget);
  });
}
