import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/services/audio_service.dart';

void main() {
  setUp(() {
    AudioService.instance.dispose();
    AudioService.instance.setEnabled(true);
    AudioService.instance.setMusicVolume(0.7);
    AudioService.instance.setSfxVolume(0.8);
  });

  test('initialize is idempotent and clamps volumes', () async {
    await AudioService.instance.initialize();
    await AudioService.instance.initialize();
    expect(AudioService.instance.enabled, isTrue);

    AudioService.instance.setMusicVolume(2.0);
    expect(AudioService.instance.musicVolume, 1.0);
    AudioService.instance.setMusicVolume(-1.0);
    expect(AudioService.instance.musicVolume, 0.0);

    AudioService.instance.setSfxVolume(2.0);
    expect(AudioService.instance.sfxVolume, 1.0);
    AudioService.instance.setSfxVolume(-1.0);
    expect(AudioService.instance.sfxVolume, 0.0);
  });

  test('play methods are safe when disabled', () async {
    await AudioService.instance.initialize();
    AudioService.instance.setEnabled(false);
    AudioService.instance.playShoot();
    AudioService.instance.playHit();
    AudioService.instance.playExplosion();
    AudioService.instance.playBuild();
    AudioService.instance.playPulse();
    AudioService.instance.playMineDeploy();
    AudioService.instance.playMineExplode();
    AudioService.instance.playButton();
    AudioService.instance.playEnemyLeak();
    AudioService.instance.playPhantomReveal();
    AudioService.instance.playGoldEarned();
  });

  test('play methods trigger tone generation when enabled', () async {
    await AudioService.instance.initialize();
    AudioService.instance.playShoot();
    AudioService.instance.playHit();
    AudioService.instance.playExplosion();
    AudioService.instance.playBuild();
    AudioService.instance.playPulse();
    AudioService.instance.playMineDeploy();
    AudioService.instance.playMineExplode();
    AudioService.instance.playButton();
    AudioService.instance.playEnemyLeak();
    AudioService.instance.playPhantomReveal();
    AudioService.instance.playGoldEarned();

    fakeAsync((async) {
      AudioService.instance.playWaveStart();
      AudioService.instance.playVictory();
      AudioService.instance.playGameOver();
      async.elapse(const Duration(milliseconds: 600));
    });
  });

  test('generateWaveformForTesting covers wave types', () async {
    await AudioService.instance.initialize();
    final saw = AudioService.instance.generateWaveformForTesting(
      frequency: 440,
      duration: 0.02,
      type: WaveType.sawtooth,
      volume: 0.5,
    );
    final sine = AudioService.instance.generateWaveformForTesting(
      frequency: 220,
      duration: 0.02,
      type: WaveType.sine,
    );
    final tri = AudioService.instance.generateWaveformForTesting(
      frequency: 330,
      duration: 0.02,
      type: WaveType.triangle,
    );
    expect(saw.isNotEmpty, isTrue);
    expect(sine.isNotEmpty, isTrue);
    expect(tri.isNotEmpty, isTrue);
  });
}
