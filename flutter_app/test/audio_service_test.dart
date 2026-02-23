import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/tower.dart';
import 'package:bored_games/src/services/audio_service.dart';
import 'helpers/fake_audioplayers_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFakeAudioplayersPlatform();
  });

  setUp(() {
    AudioService.instance.dispose();
    AudioService.instance.setEnabled(true);
    AudioService.instance.setMusicVolume(0.7);
    AudioService.instance.setSfxVolume(0.8);
  });

  tearDown(() {
    AudioService.instance.dispose();
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

    AudioService.instance.setSoundProfile('invalid');
    expect(AudioService.instance.soundProfile, 'high');
  });

  test('sound profile changes adaptive combat mix parameters', () async {
    await AudioService.instance.initialize();

    AudioService.instance.setSoundProfile('low');
    final lowShoot = AudioService.instance.debugShootIntervalMs;
    final lowHit = AudioService.instance.debugHitIntervalMs;
    final lowScale = AudioService.instance.debugCombatVolumeScale;

    AudioService.instance.setSoundProfile('extreme');
    final extremeShoot = AudioService.instance.debugShootIntervalMs;
    final extremeHit = AudioService.instance.debugHitIntervalMs;
    final extremeScale = AudioService.instance.debugCombatVolumeScale;

    expect(AudioService.instance.soundProfile, 'extreme');
    expect(extremeShoot, lessThan(lowShoot));
    expect(extremeHit, lessThan(lowHit));
    expect(extremeScale, greaterThan(lowScale));
  });

  test('tower-specific sound banks exist for all tower classes', () async {
    await AudioService.instance.initialize();

    for (final tower in TowerType.values) {
      final token = AudioService.instance.debugTowerSfxTokenFor(tower);
      expect(AudioService.instance.debugHasSfxKey('shoot_$token'), isTrue);
      expect(AudioService.instance.debugHasSfxKey('hit_$token'), isTrue);
    }
  });

  test('shoot and hit apply spatial panning and resolve dedicated keys',
      () async {
    await AudioService.instance.initialize();
    AudioService.instance.setSoundProfile('high');

    AudioService.instance.playShoot(
      type: TowerType.glimmerField,
      pan: 1.0,
      distance: 0.75,
    );
    expect(AudioService.instance.debugLastPlayedKey, 'shoot_glimmerField');
    expect(AudioService.instance.debugLastResolvedKey, 'shoot_glimmerField');
    expect(AudioService.instance.debugLastAppliedPan, closeTo(0.72, 0.02));
    expect(
        AudioService.instance.debugLastAppliedDistance, closeTo(0.75, 0.001));
    expect(AudioService.instance.debugLastAppliedPlaybackRate, isNot(1.0));

    await Future<void>.delayed(const Duration(milliseconds: 30));
    AudioService.instance.playHit(
      type: TowerType.neuralDisruptor,
      pan: -0.8,
      distance: 0.3,
    );
    expect(AudioService.instance.debugLastPlayedKey, 'hit_neuralDisruptor');
    expect(AudioService.instance.debugLastResolvedKey, 'hit_neuralDisruptor');
    expect(AudioService.instance.debugLastAppliedPan, closeTo(-0.684, 0.04));
    expect(AudioService.instance.debugLastAppliedDistance, closeTo(0.3, 0.001));
  });

  test('epic stage escalates from battle snapshot and emits stage cue',
      () async {
    await AudioService.instance.initialize();
    AudioService.instance.setSoundProfile('high');

    AudioService.instance.setBattleSnapshot(
      enemyCount: 90,
      waveProgress: 1.0,
      bossActive: true,
      comboLevel: 10,
    );

    expect(AudioService.instance.debugEpicStage, greaterThanOrEqualTo(2));
    expect(
      AudioService.instance.debugLastResolvedKey.startsWith('epic_stage_'),
      isTrue,
    );
  });

  test('build cues vary by tower archetype', () async {
    await AudioService.instance.initialize();

    AudioService.instance.playBuild(type: TowerType.circuitCannon);
    expect(AudioService.instance.debugLastResolvedKey, 'build_heavy');

    await Future<void>.delayed(const Duration(milliseconds: 12));
    AudioService.instance.playBuild(type: TowerType.phaseMage);
    expect(AudioService.instance.debugLastResolvedKey, 'build_arcane');

    await Future<void>.delayed(const Duration(milliseconds: 12));
    AudioService.instance.playBuild(type: TowerType.glimmerField);
    expect(AudioService.instance.debugLastResolvedKey, 'build_utility');
  });

  test('kill-chain cues choose minor or major variant by intensity', () async {
    await AudioService.instance.initialize();

    AudioService.instance.playKillChain(combo: 5, boss: false);
    expect(AudioService.instance.debugLastResolvedKey, 'kill_chain_minor');

    await Future<void>.delayed(const Duration(milliseconds: 12));
    AudioService.instance.playKillChain(combo: 10, boss: true);
    expect(AudioService.instance.debugLastResolvedKey, 'kill_chain_major');
  });

  test('adaptive headroom protects mix when many cues overlap', () async {
    await AudioService.instance.initialize();
    AudioService.instance.setSoundProfile('high');

    AudioService.instance.playBuild(type: TowerType.pulseArcher);
    await Future<void>.delayed(const Duration(milliseconds: 12));
    AudioService.instance.playBuild(type: TowerType.circuitCannon);
    await Future<void>.delayed(const Duration(milliseconds: 12));
    AudioService.instance.playBuild(type: TowerType.phaseMage);
    await Future<void>.delayed(const Duration(milliseconds: 12));
    AudioService.instance.playBuild(type: TowerType.glimmerField);

    expect(
        AudioService.instance.debugConcurrentVoices, greaterThanOrEqualTo(2));
    expect(AudioService.instance.debugLastHeadroomScale, lessThan(1.0));
  });

  test('extreme profile preserves more headroom than low profile', () async {
    await AudioService.instance.initialize();

    Future<double> sampleHeadroom(String profile) async {
      AudioService.instance.reset();
      AudioService.instance.setSoundProfile(profile);
      AudioService.instance.playBuild(type: TowerType.pulseArcher);
      await Future<void>.delayed(const Duration(milliseconds: 12));
      AudioService.instance.playBuild(type: TowerType.circuitCannon);
      await Future<void>.delayed(const Duration(milliseconds: 12));
      AudioService.instance.playBuild(type: TowerType.phaseMage);
      await Future<void>.delayed(const Duration(milliseconds: 12));
      AudioService.instance.playBuild(type: TowerType.glimmerField);
      return AudioService.instance.debugLastHeadroomScale;
    }

    final lowHeadroom = await sampleHeadroom('low');
    final extremeHeadroom = await sampleHeadroom('extreme');
    expect(extremeHeadroom, greaterThan(lowHeadroom));
  });

  test('combat load increases suppression and ducks combat volume', () async {
    await AudioService.instance.initialize();
    AudioService.instance.setSoundProfile('high');

    AudioService.instance.setCombatLoad(heavyLoad: false, severeLoad: false);
    final baselineShoot = AudioService.instance.debugShootIntervalMs;
    final baselineScale = AudioService.instance.debugCombatVolumeScale;

    AudioService.instance.setCombatLoad(heavyLoad: true, severeLoad: false);
    final heavyShoot = AudioService.instance.debugShootIntervalMs;
    final heavyScale = AudioService.instance.debugCombatVolumeScale;

    AudioService.instance.setCombatLoad(heavyLoad: false, severeLoad: true);
    final severeShoot = AudioService.instance.debugShootIntervalMs;
    final severeScale = AudioService.instance.debugCombatVolumeScale;

    expect(heavyShoot, greaterThan(baselineShoot));
    expect(severeShoot, greaterThan(heavyShoot));
    expect(heavyScale, lessThan(baselineScale));
    expect(severeScale, lessThan(heavyScale));
  });

  test('battle snapshot drives epic preference and denser combat cadence',
      () async {
    await AudioService.instance.initialize();
    AudioService.instance.setSoundProfile('high');
    AudioService.instance.setCombatLoad(heavyLoad: false, severeLoad: false);

    final baselineIntensity = AudioService.instance.debugBattleIntensity;
    final baselineShoot = AudioService.instance.debugShootIntervalMs;

    for (int i = 0; i < 4; i++) {
      AudioService.instance.setBattleSnapshot(
        enemyCount: 75,
        waveProgress: 1.0,
        bossActive: true,
        comboLevel: 9,
      );
    }

    final intenseShoot = AudioService.instance.debugShootIntervalMs;
    expect(AudioService.instance.debugBattleIntensity,
        greaterThan(baselineIntensity));
    expect(AudioService.instance.debugPrefersEpicCues, isTrue);
    expect(intenseShoot, lessThan(baselineShoot));
  });

  test('priority ducking is temporary and reduces combat scale', () async {
    await AudioService.instance.initialize();
    AudioService.instance.setSoundProfile('high');
    AudioService.instance.setCombatLoad(heavyLoad: false, severeLoad: false);

    final baseline = AudioService.instance.debugCombatVolumeScale;
    expect(AudioService.instance.debugPriorityDuckingActive, isFalse);

    AudioService.instance.triggerPriorityDucking(
      duration: const Duration(milliseconds: 70),
      combatScale: 0.4,
    );

    final ducked = AudioService.instance.debugCombatVolumeScale;
    expect(AudioService.instance.debugPriorityDuckingActive, isTrue);
    expect(ducked, lessThan(baseline));

    await Future<void>.delayed(const Duration(milliseconds: 110));

    final restored = AudioService.instance.debugCombatVolumeScale;
    expect(AudioService.instance.debugPriorityDuckingActive, isFalse);
    expect(restored, greaterThanOrEqualTo(baseline * 0.98));
  });

  test('priority ducking extends when retriggered', () async {
    await AudioService.instance.initialize();
    AudioService.instance.setSoundProfile('high');
    AudioService.instance.triggerPriorityDucking(
      duration: const Duration(milliseconds: 180),
      combatScale: 0.6,
    );

    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(AudioService.instance.debugPriorityDuckingActive, isTrue);

    AudioService.instance.triggerPriorityDucking(
      duration: const Duration(milliseconds: 220),
      combatScale: 0.5,
    );
    await Future<void>.delayed(const Duration(milliseconds: 140));
    expect(AudioService.instance.debugPriorityDuckingActive, isTrue);
  });

  test('epic moment boost is temporary and auto-restores', () async {
    await AudioService.instance.initialize();
    expect(AudioService.instance.debugEpicBoostScale, 0.0);

    AudioService.instance.triggerEpicMoment(
      duration: const Duration(milliseconds: 70),
      boostScale: 0.3,
    );
    expect(AudioService.instance.debugEpicBoostScale, greaterThan(0.0));

    await Future<void>.delayed(const Duration(milliseconds: 110));
    expect(AudioService.instance.debugEpicBoostScale, 0.0);
  });

  test('combo milestones map to dedicated epic keys', () async {
    await AudioService.instance.initialize();

    expect(AudioService.instance.debugComboMilestoneKeyFor(2), isNull);
    expect(AudioService.instance.debugComboMilestoneKeyFor(3), 'combo_triple');
    expect(AudioService.instance.debugComboMilestoneKeyFor(5), 'combo_spree');
    expect(AudioService.instance.debugComboMilestoneKeyFor(7), 'combo_rampage');
    expect(AudioService.instance.debugComboMilestoneKeyFor(10),
        'combo_unstoppable');

    AudioService.instance.playComboMilestone(7);
    expect(AudioService.instance.debugLastPlayedKey, 'combo_rampage');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });

  test('epic cue variants are used under extreme profile', () async {
    await AudioService.instance.initialize();
    AudioService.instance.setSoundProfile('extreme');

    AudioService.instance.playWaveStart();
    expect(AudioService.instance.debugLastPlayedKey, 'wave_start_epic');

    await Future<void>.delayed(const Duration(milliseconds: 12));
    AudioService.instance.playBossSpawn();
    expect(AudioService.instance.debugLastPlayedKey, 'boss_spawn_epic');

    await Future<void>.delayed(const Duration(milliseconds: 12));
    AudioService.instance.playVictory();
    expect(AudioService.instance.debugLastPlayedKey, 'victory_epic');
    await Future<void>.delayed(const Duration(milliseconds: 20));
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

  test('play methods are safe when muted', () async {
    await AudioService.instance.initialize();
    AudioService.instance.setSfxVolume(0);
    AudioService.instance.setCombatLoad(heavyLoad: true, severeLoad: true);
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
    AudioService.instance.playWaveStart();
    AudioService.instance.playVictory();
    AudioService.instance.playGameOver();
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

  test('timed SFX schedule without errors', () async {
    await AudioService.instance.initialize();
    expect(() {
      AudioService.instance.playWaveStart();
      AudioService.instance.playGameOver();
      AudioService.instance.playVictory();
    }, returnsNormally);

    // Allow async player calls to schedule and flush.
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });

  test('refresh and dispose reset the player pool', () async {
    await AudioService.instance.initialize();
    await AudioService.instance.refresh();
    AudioService.instance.dispose();
    await AudioService.instance.initialize();
    expect(AudioService.instance.enabled, isTrue);
  });
}
