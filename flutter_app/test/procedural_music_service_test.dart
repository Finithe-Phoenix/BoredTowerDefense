import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:bored_games/src/services/procedural_music_service.dart';
import 'helpers/fake_audioplayers_platform.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.tempPath);

  final String tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFakeAudioplayersPlatform();
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('music_service_test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    await ProceduralMusicService.instance.dispose();
    await tempDir.delete(recursive: true);
  });

  testWidgets('initialize clamps volume and handles playback controls', (tester) async {
    final service = ProceduralMusicService.instance;

    await tester.runAsync(() async {
      await service.initialize();
    });

    expect(service.isPlaying, isFalse);
    expect(service.volume, closeTo(0.7, 0.0001));

    service.setVolume(2.5);
    expect(service.volume, 1.0);
    service.setVolume(-1.0);
    expect(service.volume, 0.0);

    service.setIntensity(1.5);
    service.triggerBossMode();
    service.triggerNormalMode();

    await tester.runAsync(() async {
      await service.pause();
      await service.resume();
      await service.stop();
    });

    expect(service.isPlaying, isFalse);
  });

  testWidgets('playWorldMusic generates tracks and cleans up files', (tester) async {
    final service = ProceduralMusicService.instance;

    await tester.runAsync(() async {
      await service.playWorldMusic(99);
    });

    expect(service.isPlaying, isTrue);

    final musicDir = Directory('${tempDir.path}/neon_music');
    final wavFiles = musicDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.wav'))
        .toList();
    expect(wavFiles, isNotEmpty);
    expect(wavFiles.any((file) => file.path.contains('bass_5')), isTrue);

    await tester.runAsync(() async {
      await service.stop();
      await service.cleanupTempFiles();
    });

    final remaining = musicDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.wav'))
        .toList();
    expect(remaining, isEmpty);
  });

  testWidgets('playFinalBossMusic generates epic track', (tester) async {
    final service = ProceduralMusicService.instance;

    await tester.runAsync(() async {
      await service.playFinalBossMusic();
    });

    expect(service.isPlaying, isTrue);

    final musicDir = Directory('${tempDir.path}/neon_music');
    expect(File('${musicDir.path}/final_boss.wav').existsSync(), isTrue);

    await tester.runAsync(() async {
      await service.stopFinalBossMusic();
    });
  });

  testWidgets('playVictory and playDefeat write stingers', (tester) async {
    final service = ProceduralMusicService.instance;

    await tester.runAsync(() async {
      await service.initialize();
      await service.playVictory();
      await service.playDefeat();
    });

    final musicDir = Directory('${tempDir.path}/neon_music');
    expect(File('${musicDir.path}/victory.wav').existsSync(), isTrue);
    expect(File('${musicDir.path}/defeat.wav').existsSync(), isTrue);
  });
}
