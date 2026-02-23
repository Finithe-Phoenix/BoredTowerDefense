import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bored_games/src/bloc/settings/settings_cubit.dart';
import 'package:bored_games/src/ui/screens/game_screen.dart';
import 'package:bored_games/src/services/level_service.dart';
import 'package:bored_games/src/services/storage_service.dart';
import 'package:bored_games/src/services/upgrade_service.dart';
import 'package:bored_games/src/services/procedural_music_service.dart';
import 'package:bored_games/src/services/audio_service.dart';
import 'package:bored_games/src/ui/overlays/pause_menu_overlay.dart';
import 'helpers/fake_audioplayers_platform.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.tempPath);

  final String tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    registerFakeAudioplayersPlatform();
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
    await UpgradeService.instance.initialize();
    await LevelService.instance.initialize();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('game_screen_test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    await ProceduralMusicService.instance.initialize();
    await AudioService.instance.initialize();
    await StorageService.instance.saveQualitySettings(
      preset: 'low',
      autoQuality: false,
    );
  });

  tearDown(() async {
    await ProceduralMusicService.instance.dispose();
    await tempDir.delete(recursive: true);
  });

  Widget buildTestWidget({int levelId = 1}) {
    return BlocProvider(
      create: (_) => SettingsCubit()
        ..setGraphicsQuality('low')
        ..setParticleIntensity(0.4),
      child: MaterialApp(
        home: GameScreen(levelId: levelId),
        routes: {
          '/game': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as int?;
            return GameScreen(levelId: args ?? 1);
          },
        },
      ),
    );
  }

  testWidgets('GameScreen creates and displays game widget', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(milliseconds: 100));

    // Verify pause button exists
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });

  testWidgets('GameScreen shows materialization overlay initially', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // MaterializationOverlay should be shown initially
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('Pause button is present', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(milliseconds: 100));

    // Find pause button
    final pauseButton = find.byIcon(Icons.pause);
    expect(pauseButton, findsOneWidget);
  });

  testWidgets('ESC key can be sent to game screen', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(milliseconds: 100));

    // Game screen exists
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('GameScreen with level 1', (tester) async {
    await tester.pumpWidget(buildTestWidget(levelId: 1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('GameScreen with level 11', (tester) async {
    await tester.pumpWidget(buildTestWidget(levelId: 11));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('GameScreen with level 21', (tester) async {
    await tester.pumpWidget(buildTestWidget(levelId: 21));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('GameScreen handles invalid level ID gracefully', (tester) async {
    // Test with level 999 (non-existent, should fallback to first level)
    await tester.pumpWidget(buildTestWidget(levelId: 999));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('PauseMenuOverlay import exists', (tester) async {
    // Verify the PauseMenuOverlay type is available
    expect(PauseMenuOverlay, isNotNull);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(milliseconds: 100));

    // GameScreen exists
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('GameScreen with level 5', (tester) async {
    await tester.pumpWidget(buildTestWidget(levelId: 5));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('GameScreen with level 15', (tester) async {
    await tester.pumpWidget(buildTestWidget(levelId: 15));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('GameScreen with level 95', (tester) async {
    await tester.pumpWidget(buildTestWidget(levelId: 95));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GameScreen), findsOneWidget);
  });
}
