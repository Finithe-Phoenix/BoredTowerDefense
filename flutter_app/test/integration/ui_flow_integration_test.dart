import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bored_games/src/bloc/settings/settings_cubit.dart';
import 'package:bored_games/src/ui/screens/main_menu_screen.dart';
import 'package:bored_games/src/ui/screens/settings_screen.dart';
import 'package:bored_games/src/ui/screens/story_screen.dart';
import 'package:bored_games/src/ui/screens/level_select_screen.dart';
import 'package:bored_games/src/ui/screens/upgrades_screen.dart';
import 'package:bored_games/src/ui/theme/neon_theme.dart';
import 'package:bored_games/src/ui/widgets/tron_button.dart';
import 'package:bored_games/src/ui/widgets/cyber_grid_background.dart';
import 'package:bored_games/src/services/storage_service.dart';
import 'package:bored_games/src/services/level_service.dart';
import 'package:bored_games/src/services/upgrade_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/fake_audioplayers_platform.dart';

/// Integration tests for UI navigation flows
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFakeAudioplayersPlatform();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetForTesting();
    LevelService.overrideUnlockAllLevels = true;
    LevelService.instance.resetForTesting();
    UpgradeService.instance.resetForTesting();
    await StorageService.instance.initialize();
    await LevelService.instance.initialize();
    await UpgradeService.instance.initialize();
  });

  group('Main Menu Screen', () {
    testWidgets('renders main menu screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MainMenuScreen(),
          routes: {
            '/levels': (context) => const Scaffold(body: Text('LEVELS')),
            '/story': (context) => const Scaffold(body: Text('STORY')),
            '/codex': (context) => const Scaffold(body: Text('CODEX')),
            '/upgrades': (context) => const Scaffold(body: Text('UPGRADES')),
            '/settings': (context) => const Scaffold(body: Text('SETTINGS')),
            '/game': (context) => const Scaffold(body: Text('GAME')),
            '/benchmark': (context) => const Scaffold(body: Text('BENCHMARK')),
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(MainMenuScreen), findsOneWidget);
    });

    testWidgets('has cyber grid background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MainMenuScreen(),
          routes: {
            '/levels': (context) => const Scaffold(body: Text('LEVELS')),
            '/story': (context) => const Scaffold(body: Text('STORY')),
            '/codex': (context) => const Scaffold(body: Text('CODEX')),
            '/upgrades': (context) => const Scaffold(body: Text('UPGRADES')),
            '/settings': (context) => const Scaffold(body: Text('SETTINGS')),
            '/game': (context) => const Scaffold(body: Text('GAME')),
            '/benchmark': (context) => const Scaffold(body: Text('BENCHMARK')),
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(CyberGridBackground), findsOneWidget);
    });

    testWidgets('has tron buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MainMenuScreen(),
          routes: {
            '/levels': (context) => const Scaffold(body: Text('LEVELS')),
            '/story': (context) => const Scaffold(body: Text('STORY')),
            '/codex': (context) => const Scaffold(body: Text('CODEX')),
            '/upgrades': (context) => const Scaffold(body: Text('UPGRADES')),
            '/settings': (context) => const Scaffold(body: Text('SETTINGS')),
            '/game': (context) => const Scaffold(body: Text('GAME')),
            '/benchmark': (context) => const Scaffold(body: Text('BENCHMARK')),
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(TronButton), findsWidgets);
    });
  });

  group('Level Select Screen', () {
    testWidgets('renders level select screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LevelSelectScreen(),
          routes: {
            '/game': (context) => const Scaffold(body: Text('GAME')),
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(LevelSelectScreen), findsOneWidget);
    });

    testWidgets('shows cyber grid background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LevelSelectScreen(),
          routes: {
            '/game': (context) => const Scaffold(body: Text('GAME')),
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(CyberGridBackground), findsOneWidget);
    });
  });

  group('Settings Screen', () {
    testWidgets('renders settings screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => SettingsCubit(),
            child: const SettingsScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('Story Screen', () {
    testWidgets('renders story screen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StoryScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(StoryScreen), findsOneWidget);
    });
  });

  group('Upgrades Screen', () {
    testWidgets('renders upgrades screen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UpgradesScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(UpgradesScreen), findsOneWidget);
    });
  });

  group('Theme Integration', () {
    testWidgets('NeonColors are accessible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Container(
            color: NeonColors.darkBg,
            child: Text(
              'Test',
              style: TextStyle(color: NeonColors.cyan),
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('NeonTextStyles are accessible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(
              'Test',
              style: NeonTextStyles.title,
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });
  });

  group('Widget Integration', () {
    testWidgets('TronButton renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TronButton(
                text: 'TEST',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(TronButton), findsOneWidget);
      expect(find.textContaining('TEST'), findsOneWidget);
    });

    testWidgets('CyberGridBackground renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CyberGridBackground(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CyberGridBackground), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });
  });
}
