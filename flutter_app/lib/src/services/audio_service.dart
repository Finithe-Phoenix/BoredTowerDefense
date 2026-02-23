import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flame_audio/flame_audio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../game/entities/tower.dart';
import 'ambient_soundscape_service.dart';

class _FastRng {
  int _state;

  _FastRng([int? seed]) : _state = (seed ?? 0x6d2b79f5) & 0x7fffffff;

  int _next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  double nextDouble() => _next() / 0x7fffffff;

  int nextInt(int max) => max <= 0 ? 0 : _next() % max;

  bool nextBool() => (_next() & 1) == 0;
}

class _SfxLayer {
  const _SfxLayer({
    required this.frequency,
    required this.duration,
    required this.type,
    this.frequencySlide = 0,
    this.volume = 0.8,
    this.attack = 0.01,
    this.decay = 0.08,
    this.sustain = 0.6,
    this.release = 0.25,
    this.startDelay = 0.0,
    this.vibratoRate = 0.0,
    this.vibratoDepth = 0.0,
  });

  final double frequency;
  final double duration;
  final WaveType type;
  final double frequencySlide;
  final double volume;
  final double attack;
  final double decay;
  final double sustain;
  final double release;
  final double startDelay;
  final double vibratoRate;
  final double vibratoDepth;
}

enum _TowerArchetype { precision, heavy, arcane, utility }

/// Synthwave audio service with procedural sound generation
/// Generates 8-bit style sound effects for the neon aesthetic
class AudioService {
  AudioService._();
  static final instance = AudioService._();

  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;
  bool _enabled = true;
  bool _initialized = false;
  String _soundProfile = 'high';
  bool _combatHeavyLoad = false;
  bool _combatSevereLoad = false;
  int _priorityDuckingUntilMicros = 0;
  double _priorityCombatDuckScale = 1.0;
  double _battleIntensity = 0.35;
  bool _bossActive = false;
  int _comboLevel = 0;
  int _epicBoostUntilMicros = 0;
  double _epicBoostScale = 0.0;
  int _epicStage = 0;
  int _epicStageCueCooldownUntilMicros = 0;
  String _lastPlayedKey = '';

  // Pool of audio players to reuse
  final List<AudioPlayer> _playerPool = [];
  static const int _poolSize = 12;
  int _currentPlayerIndex = 0;

  // SFX Cache
  final Map<String, BytesSource> _sfxCache = {};

  // Sound generation parameters
  static const int _sampleRate = 32000;
  final _random = _FastRng();
  final Map<String, int> _lastSfxPlayMicros = <String, int>{};
  final Map<String, int> _combatPatternCounts = <String, int>{};
  final Map<String, int> _sfxDurationMicros = <String, int>{};
  final List<int> _activeSfxUntilMicros = <int>[];
  int _lastAnySfxPlayMicros = 0;
  double _lastHeadroomScale = 1.0;
  int _lastConcurrentVoices = 0;
  double _lastAppliedPan = 0.0;
  double _lastAppliedDistance = 0.0;
  double _lastAppliedPlaybackRate = 1.0;
  String _lastResolvedKey = '';

  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  bool get enabled => _enabled;
  String get soundProfile => _soundProfile;

  /// Initialize audio system
  Future<void> initialize() async {
    if (_initialized) return;

    // Create player pool
    for (int i = 0; i < _poolSize; i++) {
      _playerPool.add(AudioPlayer());
    }

    // Pre-cache core sounds
    await _cacheAllSounds();

    // Initialize ambient soundscape service with current music volume
    await AmbientSoundscapeService.instance.initialize();
    await AmbientSoundscapeService.instance.setVolume(_musicVolume);

    _initialized = true;
    if (kDebugMode) {
      debugPrint(
          'AudioService initialized (Pool size: $_poolSize, Cached sounds: ${_sfxCache.length})');
    }
  }

  Future<void> _cacheAllSounds() async {
    _sfxCache.clear();

    _SfxLayer layer({
      required double freq,
      required double dur,
      required WaveType type,
      double slide = 0,
      double vol = 0.8,
      double attack = 0.01,
      double decay = 0.08,
      double sustain = 0.6,
      double release = 0.25,
      double delay = 0.0,
      double vibratoRate = 0.0,
      double vibratoDepth = 0.0,
    }) {
      return _SfxLayer(
        frequency: freq,
        duration: dur,
        type: type,
        frequencySlide: slide,
        volume: vol,
        attack: attack,
        decay: decay,
        sustain: sustain,
        release: release,
        startDelay: delay,
        vibratoRate: vibratoRate,
        vibratoDepth: vibratoDepth,
      );
    }

    // Core SFX
    _sfxCache['shoot_default'] = _generateLayeredSource(
      [
        layer(
          freq: 1600,
          dur: 0.06,
          type: WaveType.square,
          slide: -700,
          vol: 0.7,
          attack: 0.002,
          decay: 0.04,
          sustain: 0.35,
          release: 0.1,
        ),
        layer(
          freq: 2200,
          dur: 0.05,
          type: WaveType.sine,
          slide: -1200,
          vol: 0.35,
          attack: 0.002,
          decay: 0.03,
          sustain: 0.25,
          release: 0.08,
        ),
        layer(
          freq: 600,
          dur: 0.02,
          type: WaveType.noise,
          vol: 0.18,
          attack: 0.001,
          decay: 0.02,
          sustain: 0.0,
          release: 0.05,
        ),
      ],
      masterVolume: 0.9,
      drive: 0.25,
    );

    _sfxCache['hit_default'] = _generateLayeredSource(
      [
        layer(
          freq: 220,
          dur: 0.12,
          type: WaveType.noise,
          slide: -200,
          vol: 0.7,
          attack: 0.001,
          decay: 0.05,
          sustain: 0.2,
          release: 0.2,
        ),
        layer(
          freq: 180,
          dur: 0.1,
          type: WaveType.sine,
          slide: -60,
          vol: 0.4,
          attack: 0.002,
          decay: 0.05,
          sustain: 0.4,
          release: 0.2,
        ),
        layer(
          freq: 90,
          dur: 0.08,
          type: WaveType.triangle,
          slide: -20,
          vol: 0.3,
          attack: 0.002,
          decay: 0.04,
          sustain: 0.3,
          release: 0.15,
        ),
      ],
      masterVolume: 0.95,
      drive: 0.35,
    );

    _sfxCache['explosion'] = _generateLayeredSource(
      [
        layer(
          freq: 140,
          dur: 0.6,
          type: WaveType.noise,
          slide: -220,
          vol: 0.9,
          attack: 0.002,
          decay: 0.15,
          sustain: 0.4,
          release: 0.35,
        ),
        layer(
          freq: 60,
          dur: 0.7,
          type: WaveType.sine,
          slide: -40,
          vol: 0.9,
          attack: 0.003,
          decay: 0.1,
          sustain: 0.5,
          release: 0.4,
        ),
        layer(
          freq: 140,
          dur: 0.35,
          type: WaveType.sawtooth,
          slide: -120,
          vol: 0.35,
          attack: 0.002,
          decay: 0.08,
          sustain: 0.2,
          release: 0.25,
        ),
      ],
      masterVolume: 1.0,
      drive: 0.45,
      echoDelayMs: 90,
      echoDecay: 0.35,
    );

    _sfxCache['build'] = _generateLayeredSource(
      [
        layer(
          freq: 440,
          dur: 0.18,
          type: WaveType.triangle,
          slide: 320,
          vol: 0.6,
          attack: 0.005,
          decay: 0.05,
          sustain: 0.4,
          release: 0.2,
        ),
        layer(
          freq: 660,
          dur: 0.14,
          type: WaveType.sine,
          slide: 500,
          vol: 0.35,
          attack: 0.005,
          decay: 0.05,
          sustain: 0.3,
          release: 0.15,
        ),
        layer(
          freq: 1200,
          dur: 0.04,
          type: WaveType.square,
          slide: -400,
          vol: 0.2,
          attack: 0.002,
          decay: 0.02,
          sustain: 0.1,
          release: 0.08,
          delay: 0.08,
        ),
        layer(
          freq: 700,
          dur: 0.02,
          type: WaveType.noise,
          vol: 0.12,
          attack: 0.001,
          decay: 0.02,
          sustain: 0.0,
          release: 0.05,
        ),
      ],
      masterVolume: 0.9,
      drive: 0.1,
    );

    _sfxCache['pulse'] = _generateLayeredSource(
      [
        layer(
          freq: 120,
          dur: 0.5,
          type: WaveType.sine,
          slide: 480,
          vol: 0.8,
          attack: 0.01,
          decay: 0.12,
          sustain: 0.5,
          release: 0.3,
        ),
        layer(
          freq: 240,
          dur: 0.4,
          type: WaveType.triangle,
          slide: 320,
          vol: 0.45,
          attack: 0.01,
          decay: 0.1,
          sustain: 0.4,
          release: 0.25,
        ),
        layer(
          freq: 500,
          dur: 0.35,
          type: WaveType.noise,
          vol: 0.2,
          attack: 0.01,
          decay: 0.15,
          sustain: 0.2,
          release: 0.2,
        ),
      ],
      masterVolume: 0.95,
      drive: 0.2,
      echoDelayMs: 120,
      echoDecay: 0.25,
    );

    _sfxCache['mine_deploy'] = _generateLayeredSource(
      [
        layer(
          freq: 880,
          dur: 0.07,
          type: WaveType.square,
          slide: -220,
          vol: 0.5,
          attack: 0.003,
          decay: 0.04,
          sustain: 0.2,
          release: 0.1,
        ),
        layer(
          freq: 1320,
          dur: 0.05,
          type: WaveType.sine,
          slide: -330,
          vol: 0.3,
          attack: 0.003,
          decay: 0.03,
          sustain: 0.2,
          release: 0.08,
        ),
        layer(
          freq: 700,
          dur: 0.015,
          type: WaveType.noise,
          vol: 0.12,
          attack: 0.001,
          decay: 0.02,
          sustain: 0.0,
          release: 0.05,
        ),
      ],
      masterVolume: 0.8,
    );

    _sfxCache['mine_explode'] = _generateLayeredSource(
      [
        layer(
          freq: 120,
          dur: 0.55,
          type: WaveType.noise,
          slide: -180,
          vol: 0.8,
          attack: 0.002,
          decay: 0.12,
          sustain: 0.4,
          release: 0.3,
        ),
        layer(
          freq: 70,
          dur: 0.6,
          type: WaveType.sine,
          slide: -30,
          vol: 0.7,
          attack: 0.003,
          decay: 0.1,
          sustain: 0.4,
          release: 0.3,
        ),
        layer(
          freq: 160,
          dur: 0.3,
          type: WaveType.sawtooth,
          slide: -90,
          vol: 0.3,
          attack: 0.002,
          decay: 0.06,
          sustain: 0.2,
          release: 0.2,
        ),
      ],
      masterVolume: 1.0,
      drive: 0.4,
      echoDelayMs: 80,
      echoDecay: 0.3,
    );

    _sfxCache['button'] = _generateLayeredSource(
      [
        layer(
          freq: 1400,
          dur: 0.03,
          type: WaveType.square,
          slide: -300,
          vol: 0.2,
          attack: 0.001,
          decay: 0.02,
          sustain: 0.1,
          release: 0.05,
        ),
        layer(
          freq: 1000,
          dur: 0.02,
          type: WaveType.sine,
          slide: -100,
          vol: 0.18,
          attack: 0.001,
          decay: 0.02,
          sustain: 0.1,
          release: 0.05,
        ),
        layer(
          freq: 700,
          dur: 0.03,
          type: WaveType.noise,
          vol: 0.15,
          attack: 0.001,
          decay: 0.02,
          sustain: 0.0,
          release: 0.06,
        ),
      ],
      masterVolume: 0.7,
    );

    _sfxCache['gold'] = _generateLayeredSource(
      [
        layer(
          freq: 1320,
          dur: 0.06,
          type: WaveType.triangle,
          slide: 180,
          vol: 0.4,
          attack: 0.005,
          decay: 0.04,
          sustain: 0.3,
          release: 0.15,
        ),
        layer(
          freq: 2640,
          dur: 0.04,
          type: WaveType.sine,
          slide: -200,
          vol: 0.25,
          attack: 0.003,
          decay: 0.03,
          sustain: 0.2,
          release: 0.1,
          delay: 0.02,
        ),
        layer(
          freq: 900,
          dur: 0.02,
          type: WaveType.noise,
          vol: 0.12,
          attack: 0.001,
          decay: 0.02,
          sustain: 0.0,
          release: 0.05,
        ),
      ],
      masterVolume: 0.85,
      echoDelayMs: 60,
      echoDecay: 0.2,
    );

    _sfxCache['critical'] = _generateLayeredSource(
      [
        layer(
          freq: 2200,
          dur: 0.06,
          type: WaveType.sine,
          slide: 400,
          vol: 0.4,
          attack: 0.002,
          decay: 0.02,
          sustain: 0.2,
          release: 0.1,
        ),
        layer(
          freq: 1600,
          dur: 0.05,
          type: WaveType.triangle,
          slide: 200,
          vol: 0.3,
          attack: 0.002,
          decay: 0.02,
          sustain: 0.2,
          release: 0.1,
        ),
      ],
      masterVolume: 0.9,
      drive: 0.2,
    );

    _sfxCache['wave_start'] = _generateLayeredSource(
      [
        layer(
          freq: 440,
          dur: 0.3,
          type: WaveType.sine,
          slide: 440,
          vol: 0.5,
          attack: 0.01,
          decay: 0.08,
          sustain: 0.4,
          release: 0.2,
        ),
        layer(
          freq: 220,
          dur: 0.3,
          type: WaveType.triangle,
          slide: 220,
          vol: 0.35,
          attack: 0.01,
          decay: 0.08,
          sustain: 0.4,
          release: 0.2,
        ),
        layer(
          freq: 880,
          dur: 0.06,
          type: WaveType.square,
          slide: 120,
          vol: 0.2,
          attack: 0.002,
          decay: 0.02,
          sustain: 0.2,
          release: 0.08,
          delay: 0.18,
        ),
      ],
      masterVolume: 0.9,
      echoDelayMs: 90,
      echoDecay: 0.2,
    );

    _sfxCache['wave_complete'] = _generateLayeredSource(
      [
        layer(
          freq: 660,
          dur: 0.12,
          type: WaveType.triangle,
          slide: 120,
          vol: 0.4,
          attack: 0.004,
          decay: 0.04,
          sustain: 0.3,
          release: 0.12,
        ),
        layer(
          freq: 880,
          dur: 0.12,
          type: WaveType.sine,
          slide: 180,
          vol: 0.35,
          attack: 0.004,
          decay: 0.04,
          sustain: 0.3,
          release: 0.12,
          delay: 0.08,
        ),
        layer(
          freq: 1320,
          dur: 0.1,
          type: WaveType.sine,
          slide: 220,
          vol: 0.3,
          attack: 0.004,
          decay: 0.04,
          sustain: 0.3,
          release: 0.12,
          delay: 0.16,
        ),
      ],
      masterVolume: 0.9,
      echoDelayMs: 80,
      echoDecay: 0.2,
    );

    _sfxCache['boss_spawn'] = _generateLayeredSource(
      [
        layer(
          freq: 120,
          dur: 0.7,
          type: WaveType.noise,
          slide: -220,
          vol: 0.9,
          attack: 0.002,
          decay: 0.18,
          sustain: 0.5,
          release: 0.35,
        ),
        layer(
          freq: 55,
          dur: 0.8,
          type: WaveType.sine,
          slide: -20,
          vol: 0.9,
          attack: 0.003,
          decay: 0.1,
          sustain: 0.6,
          release: 0.4,
        ),
        layer(
          freq: 120,
          dur: 0.5,
          type: WaveType.sawtooth,
          slide: -60,
          vol: 0.4,
          attack: 0.003,
          decay: 0.08,
          sustain: 0.3,
          release: 0.3,
        ),
        layer(
          freq: 880,
          dur: 0.6,
          type: WaveType.sine,
          slide: -600,
          vol: 0.25,
          attack: 0.01,
          decay: 0.12,
          sustain: 0.4,
          release: 0.3,
        ),
      ],
      masterVolume: 1.0,
      drive: 0.5,
      echoDelayMs: 120,
      echoDecay: 0.35,
    );

    _sfxCache['boss_phase'] = _generateLayeredSource(
      [
        layer(
          freq: 320,
          dur: 0.25,
          type: WaveType.sine,
          slide: 420,
          vol: 0.45,
          attack: 0.006,
          decay: 0.06,
          sustain: 0.4,
          release: 0.18,
        ),
        layer(
          freq: 1200,
          dur: 0.2,
          type: WaveType.square,
          slide: -600,
          vol: 0.3,
          attack: 0.004,
          decay: 0.04,
          sustain: 0.3,
          release: 0.15,
        ),
        layer(
          freq: 600,
          dur: 0.08,
          type: WaveType.noise,
          vol: 0.18,
          attack: 0.004,
          decay: 0.03,
          sustain: 0.2,
          release: 0.1,
        ),
      ],
      masterVolume: 0.9,
      echoDelayMs: 90,
      echoDecay: 0.25,
    );

    _sfxCache['enemy_leak'] = _generateLayeredSource(
      [
        layer(
          freq: 240,
          dur: 0.2,
          type: WaveType.sine,
          slide: -120,
          vol: 0.5,
          attack: 0.01,
          decay: 0.05,
          sustain: 0.4,
          release: 0.15,
        ),
        layer(
          freq: 880,
          dur: 0.06,
          type: WaveType.square,
          slide: -400,
          vol: 0.25,
          attack: 0.002,
          decay: 0.02,
          sustain: 0.2,
          release: 0.08,
          delay: 0.12,
        ),
      ],
      masterVolume: 0.9,
    );

    _sfxCache['phantom_reveal'] = _generateLayeredSource(
      [
        layer(
          freq: 1200,
          dur: 0.12,
          type: WaveType.sine,
          slide: 360,
          vol: 0.32,
          attack: 0.01,
          decay: 0.05,
          sustain: 0.3,
          release: 0.12,
        ),
        layer(
          freq: 800,
          dur: 0.12,
          type: WaveType.triangle,
          slide: 300,
          vol: 0.28,
          attack: 0.01,
          decay: 0.05,
          sustain: 0.3,
          release: 0.12,
        ),
        layer(
          freq: 700,
          dur: 0.06,
          type: WaveType.noise,
          vol: 0.15,
          attack: 0.01,
          decay: 0.03,
          sustain: 0.2,
          release: 0.1,
        ),
      ],
      masterVolume: 0.85,
      echoDelayMs: 60,
      echoDecay: 0.2,
    );

    _sfxCache['game_over'] = _generateLayeredSource(
      [
        layer(
          freq: 220,
          dur: 0.6,
          type: WaveType.sawtooth,
          slide: -140,
          vol: 0.6,
          attack: 0.01,
          decay: 0.1,
          sustain: 0.4,
          release: 0.4,
        ),
        layer(
          freq: 110,
          dur: 0.6,
          type: WaveType.sine,
          slide: -55,
          vol: 0.45,
          attack: 0.01,
          decay: 0.1,
          sustain: 0.4,
          release: 0.4,
        ),
        layer(
          freq: 160,
          dur: 0.3,
          type: WaveType.noise,
          vol: 0.25,
          attack: 0.005,
          decay: 0.06,
          sustain: 0.2,
          release: 0.2,
        ),
      ],
      masterVolume: 0.95,
      drive: 0.3,
      echoDelayMs: 120,
      echoDecay: 0.35,
    );

    _sfxCache['victory'] = _generateLayeredSource(
      [
        layer(
          freq: 660,
          dur: 0.12,
          type: WaveType.sine,
          slide: 120,
          vol: 0.35,
          attack: 0.005,
          decay: 0.04,
          sustain: 0.3,
          release: 0.12,
        ),
        layer(
          freq: 880,
          dur: 0.12,
          type: WaveType.triangle,
          slide: 180,
          vol: 0.35,
          attack: 0.005,
          decay: 0.04,
          sustain: 0.3,
          release: 0.12,
          delay: 0.1,
        ),
        layer(
          freq: 1320,
          dur: 0.14,
          type: WaveType.sine,
          slide: 240,
          vol: 0.3,
          attack: 0.005,
          decay: 0.05,
          sustain: 0.3,
          release: 0.15,
          delay: 0.2,
        ),
        layer(
          freq: 900,
          dur: 0.05,
          type: WaveType.noise,
          vol: 0.12,
          attack: 0.005,
          decay: 0.02,
          sustain: 0.2,
          release: 0.08,
          delay: 0.16,
        ),
      ],
      masterVolume: 0.95,
      echoDelayMs: 100,
      echoDecay: 0.25,
    );

    _sfxCache['wave_start_epic'] = _generateLayeredSource(
      [
        layer(
          freq: 240,
          dur: 0.4,
          type: WaveType.sawtooth,
          slide: 620,
          vol: 0.42,
          attack: 0.01,
          decay: 0.09,
          sustain: 0.5,
          release: 0.22,
        ),
        layer(
          freq: 420,
          dur: 0.35,
          type: WaveType.square,
          slide: 900,
          vol: 0.28,
          attack: 0.006,
          decay: 0.08,
          sustain: 0.4,
          release: 0.2,
          delay: 0.03,
        ),
        layer(
          freq: 1200,
          dur: 0.1,
          type: WaveType.noise,
          vol: 0.14,
          attack: 0.004,
          decay: 0.03,
          sustain: 0.2,
          release: 0.08,
          delay: 0.2,
        ),
      ],
      masterVolume: 0.95,
      drive: 0.22,
      echoDelayMs: 80,
      echoDecay: 0.22,
    );

    _sfxCache['wave_complete_epic'] = _generateLayeredSource(
      [
        layer(
          freq: 460,
          dur: 0.22,
          type: WaveType.sine,
          slide: 220,
          vol: 0.34,
          attack: 0.004,
          decay: 0.05,
          sustain: 0.35,
          release: 0.12,
        ),
        layer(
          freq: 740,
          dur: 0.2,
          type: WaveType.triangle,
          slide: 400,
          vol: 0.32,
          attack: 0.004,
          decay: 0.05,
          sustain: 0.35,
          release: 0.13,
          delay: 0.05,
        ),
        layer(
          freq: 980,
          dur: 0.24,
          type: WaveType.sine,
          slide: 520,
          vol: 0.3,
          attack: 0.004,
          decay: 0.05,
          sustain: 0.32,
          release: 0.15,
          delay: 0.1,
        ),
      ],
      masterVolume: 0.98,
      echoDelayMs: 96,
      echoDecay: 0.25,
    );

    _sfxCache['boss_spawn_epic'] = _generateLayeredSource(
      [
        layer(
          freq: 110,
          dur: 0.65,
          type: WaveType.sawtooth,
          slide: -40,
          vol: 0.62,
          attack: 0.006,
          decay: 0.1,
          sustain: 0.55,
          release: 0.35,
        ),
        layer(
          freq: 340,
          dur: 0.5,
          type: WaveType.square,
          slide: 120,
          vol: 0.34,
          attack: 0.006,
          decay: 0.09,
          sustain: 0.45,
          release: 0.25,
          delay: 0.04,
        ),
        layer(
          freq: 70,
          dur: 0.58,
          type: WaveType.noise,
          slide: -70,
          vol: 0.24,
          attack: 0.004,
          decay: 0.08,
          sustain: 0.45,
          release: 0.28,
        ),
      ],
      masterVolume: 1.0,
      drive: 0.42,
      echoDelayMs: 120,
      echoDecay: 0.3,
    );

    _sfxCache['boss_phase_epic'] = _generateLayeredSource(
      [
        layer(
          freq: 220,
          dur: 0.45,
          type: WaveType.square,
          slide: 500,
          vol: 0.5,
          attack: 0.004,
          decay: 0.08,
          sustain: 0.45,
          release: 0.22,
        ),
        layer(
          freq: 700,
          dur: 0.3,
          type: WaveType.sine,
          slide: -160,
          vol: 0.28,
          attack: 0.004,
          decay: 0.06,
          sustain: 0.3,
          release: 0.15,
          delay: 0.08,
        ),
        layer(
          freq: 1200,
          dur: 0.16,
          type: WaveType.noise,
          vol: 0.15,
          attack: 0.002,
          decay: 0.05,
          sustain: 0.2,
          release: 0.08,
          delay: 0.12,
        ),
      ],
      masterVolume: 0.96,
      drive: 0.3,
      echoDelayMs: 90,
      echoDecay: 0.22,
    );

    _sfxCache['victory_epic'] = _generateLayeredSource(
      [
        layer(
          freq: 520,
          dur: 0.18,
          type: WaveType.sine,
          slide: 160,
          vol: 0.32,
          attack: 0.005,
          decay: 0.05,
          sustain: 0.35,
          release: 0.12,
        ),
        layer(
          freq: 780,
          dur: 0.18,
          type: WaveType.triangle,
          slide: 220,
          vol: 0.32,
          attack: 0.005,
          decay: 0.05,
          sustain: 0.35,
          release: 0.12,
          delay: 0.07,
        ),
        layer(
          freq: 1040,
          dur: 0.2,
          type: WaveType.sine,
          slide: 300,
          vol: 0.3,
          attack: 0.005,
          decay: 0.06,
          sustain: 0.35,
          release: 0.14,
          delay: 0.14,
        ),
        layer(
          freq: 1560,
          dur: 0.2,
          type: WaveType.triangle,
          slide: 420,
          vol: 0.26,
          attack: 0.005,
          decay: 0.06,
          sustain: 0.32,
          release: 0.14,
          delay: 0.21,
        ),
      ],
      masterVolume: 1.0,
      drive: 0.2,
      echoDelayMs: 110,
      echoDecay: 0.24,
    );

    _sfxCache['combo_triple'] = _generateLayeredSource(
      [
        layer(
          freq: 700,
          dur: 0.14,
          type: WaveType.sine,
          slide: 280,
          vol: 0.32,
          attack: 0.003,
          decay: 0.04,
          sustain: 0.35,
          release: 0.1,
        ),
        layer(
          freq: 1050,
          dur: 0.12,
          type: WaveType.square,
          slide: 420,
          vol: 0.22,
          attack: 0.003,
          decay: 0.03,
          sustain: 0.3,
          release: 0.09,
          delay: 0.03,
        ),
      ],
      masterVolume: 0.88,
      echoDelayMs: 70,
      echoDecay: 0.18,
    );

    _sfxCache['combo_spree'] = _generateLayeredSource(
      [
        layer(
          freq: 520,
          dur: 0.16,
          type: WaveType.triangle,
          slide: 260,
          vol: 0.34,
          attack: 0.003,
          decay: 0.04,
          sustain: 0.35,
          release: 0.1,
        ),
        layer(
          freq: 880,
          dur: 0.14,
          type: WaveType.sine,
          slide: 360,
          vol: 0.28,
          attack: 0.003,
          decay: 0.04,
          sustain: 0.35,
          release: 0.1,
          delay: 0.04,
        ),
      ],
      masterVolume: 0.9,
      echoDelayMs: 72,
      echoDecay: 0.2,
    );

    _sfxCache['combo_rampage'] = _generateLayeredSource(
      [
        layer(
          freq: 260,
          dur: 0.2,
          type: WaveType.sawtooth,
          slide: 220,
          vol: 0.38,
          attack: 0.003,
          decay: 0.05,
          sustain: 0.4,
          release: 0.14,
        ),
        layer(
          freq: 620,
          dur: 0.18,
          type: WaveType.square,
          slide: 420,
          vol: 0.3,
          attack: 0.003,
          decay: 0.05,
          sustain: 0.35,
          release: 0.12,
          delay: 0.05,
        ),
      ],
      masterVolume: 0.95,
      drive: 0.2,
      echoDelayMs: 78,
      echoDecay: 0.22,
    );

    _sfxCache['combo_unstoppable'] = _generateLayeredSource(
      [
        layer(
          freq: 190,
          dur: 0.26,
          type: WaveType.sawtooth,
          slide: 220,
          vol: 0.45,
          attack: 0.003,
          decay: 0.06,
          sustain: 0.42,
          release: 0.16,
        ),
        layer(
          freq: 560,
          dur: 0.22,
          type: WaveType.square,
          slide: 460,
          vol: 0.34,
          attack: 0.003,
          decay: 0.05,
          sustain: 0.36,
          release: 0.14,
          delay: 0.05,
        ),
        layer(
          freq: 1200,
          dur: 0.14,
          type: WaveType.sine,
          slide: 320,
          vol: 0.22,
          attack: 0.003,
          decay: 0.04,
          sustain: 0.3,
          release: 0.1,
          delay: 0.1,
        ),
      ],
      masterVolume: 1.0,
      drive: 0.3,
      echoDelayMs: 85,
      echoDecay: 0.24,
    );

    _sfxCache['epic_stage_1'] = _generateLayeredSource(
      [
        layer(
          freq: 240,
          dur: 0.18,
          type: WaveType.sawtooth,
          slide: 360,
          vol: 0.28,
          attack: 0.004,
          decay: 0.05,
          sustain: 0.35,
          release: 0.1,
        ),
        layer(
          freq: 580,
          dur: 0.16,
          type: WaveType.square,
          slide: 260,
          vol: 0.22,
          attack: 0.004,
          decay: 0.04,
          sustain: 0.3,
          release: 0.09,
          delay: 0.02,
        ),
      ],
      masterVolume: 0.84,
      echoDelayMs: 65,
      echoDecay: 0.16,
    );

    _sfxCache['epic_stage_2'] = _generateLayeredSource(
      [
        layer(
          freq: 180,
          dur: 0.24,
          type: WaveType.sawtooth,
          slide: 420,
          vol: 0.35,
          attack: 0.004,
          decay: 0.06,
          sustain: 0.4,
          release: 0.12,
        ),
        layer(
          freq: 520,
          dur: 0.2,
          type: WaveType.square,
          slide: 320,
          vol: 0.28,
          attack: 0.004,
          decay: 0.05,
          sustain: 0.35,
          release: 0.1,
          delay: 0.03,
        ),
        layer(
          freq: 980,
          dur: 0.12,
          type: WaveType.noise,
          vol: 0.12,
          attack: 0.002,
          decay: 0.03,
          sustain: 0.18,
          release: 0.08,
          delay: 0.08,
        ),
      ],
      masterVolume: 0.9,
      drive: 0.2,
      echoDelayMs: 75,
      echoDecay: 0.2,
    );

    _sfxCache['epic_stage_3'] = _generateLayeredSource(
      [
        layer(
          freq: 110,
          dur: 0.32,
          type: WaveType.sawtooth,
          slide: 360,
          vol: 0.42,
          attack: 0.004,
          decay: 0.07,
          sustain: 0.45,
          release: 0.14,
        ),
        layer(
          freq: 420,
          dur: 0.26,
          type: WaveType.square,
          slide: 520,
          vol: 0.34,
          attack: 0.004,
          decay: 0.06,
          sustain: 0.4,
          release: 0.12,
          delay: 0.03,
        ),
        layer(
          freq: 860,
          dur: 0.18,
          type: WaveType.sine,
          slide: 260,
          vol: 0.2,
          attack: 0.003,
          decay: 0.04,
          sustain: 0.28,
          release: 0.1,
          delay: 0.08,
        ),
      ],
      masterVolume: 0.98,
      drive: 0.34,
      echoDelayMs: 90,
      echoDecay: 0.24,
    );

    _sfxCache['kill_chain_minor'] = _generateLayeredSource(
      [
        layer(
          freq: 460,
          dur: 0.14,
          type: WaveType.triangle,
          slide: 240,
          vol: 0.28,
          attack: 0.003,
          decay: 0.04,
          sustain: 0.32,
          release: 0.1,
        ),
        layer(
          freq: 760,
          dur: 0.12,
          type: WaveType.sine,
          slide: 360,
          vol: 0.22,
          attack: 0.003,
          decay: 0.03,
          sustain: 0.3,
          release: 0.08,
          delay: 0.03,
        ),
      ],
      masterVolume: 0.82,
      echoDelayMs: 58,
      echoDecay: 0.14,
    );

    _sfxCache['kill_chain_major'] = _generateLayeredSource(
      [
        layer(
          freq: 220,
          dur: 0.2,
          type: WaveType.sawtooth,
          slide: 300,
          vol: 0.34,
          attack: 0.003,
          decay: 0.05,
          sustain: 0.38,
          release: 0.12,
        ),
        layer(
          freq: 620,
          dur: 0.16,
          type: WaveType.square,
          slide: 420,
          vol: 0.28,
          attack: 0.003,
          decay: 0.04,
          sustain: 0.34,
          release: 0.1,
          delay: 0.03,
        ),
      ],
      masterVolume: 0.9,
      drive: 0.18,
      echoDelayMs: 72,
      echoDecay: 0.18,
    );

    _sfxCache['build_heavy'] = _generateLayeredSource(
      [
        layer(
          freq: 180,
          dur: 0.24,
          type: WaveType.sawtooth,
          slide: -60,
          vol: 0.38,
          attack: 0.006,
          decay: 0.08,
          sustain: 0.42,
          release: 0.16,
        ),
        layer(
          freq: 90,
          dur: 0.2,
          type: WaveType.sine,
          slide: -30,
          vol: 0.28,
          attack: 0.006,
          decay: 0.07,
          sustain: 0.4,
          release: 0.14,
        ),
      ],
      masterVolume: 0.88,
    );

    _sfxCache['build_arcane'] = _generateLayeredSource(
      [
        layer(
          freq: 620,
          dur: 0.18,
          type: WaveType.sine,
          slide: 220,
          vol: 0.3,
          attack: 0.006,
          decay: 0.05,
          sustain: 0.32,
          release: 0.12,
        ),
        layer(
          freq: 940,
          dur: 0.16,
          type: WaveType.triangle,
          slide: 300,
          vol: 0.24,
          attack: 0.006,
          decay: 0.05,
          sustain: 0.3,
          release: 0.11,
          delay: 0.04,
        ),
      ],
      masterVolume: 0.84,
      echoDelayMs: 64,
      echoDecay: 0.16,
    );

    _sfxCache['build_utility'] = _generateLayeredSource(
      [
        layer(
          freq: 340,
          dur: 0.16,
          type: WaveType.square,
          slide: 140,
          vol: 0.28,
          attack: 0.005,
          decay: 0.04,
          sustain: 0.3,
          release: 0.1,
        ),
        layer(
          freq: 520,
          dur: 0.14,
          type: WaveType.sine,
          slide: 200,
          vol: 0.2,
          attack: 0.005,
          decay: 0.04,
          sustain: 0.28,
          release: 0.09,
          delay: 0.03,
        ),
      ],
      masterVolume: 0.8,
      echoDelayMs: 52,
      echoDecay: 0.12,
    );

    // Tower-specific shoot sounds
    _sfxCache['shoot_pulseArcher'] = _generateLayeredSource(
      [
        layer(
          freq: 1150,
          dur: 0.08,
          type: WaveType.square,
          slide: -500,
          vol: 0.5,
          attack: 0.002,
          decay: 0.03,
          sustain: 0.28,
          release: 0.08,
        ),
        layer(
          freq: 1800,
          dur: 0.06,
          type: WaveType.sine,
          slide: -800,
          vol: 0.26,
          attack: 0.002,
          decay: 0.03,
          sustain: 0.22,
          release: 0.07,
        ),
      ],
      masterVolume: 0.9,
      drive: 0.16,
    );

    _sfxCache['shoot_glimmerField'] = _generateLayeredSource(
      [
        layer(
          freq: 1320,
          dur: 0.05,
          type: WaveType.triangle,
          slide: 180,
          vol: 0.32,
          attack: 0.002,
          decay: 0.02,
          sustain: 0.24,
          release: 0.06,
        ),
        layer(
          freq: 2100,
          dur: 0.04,
          type: WaveType.sine,
          slide: 260,
          vol: 0.2,
          attack: 0.002,
          decay: 0.02,
          sustain: 0.2,
          release: 0.05,
          delay: 0.01,
        ),
      ],
      masterVolume: 0.84,
      echoDelayMs: 48,
      echoDecay: 0.12,
    );

    _sfxCache['shoot_neuralDisruptor'] = _generateLayeredSource(
      [
        layer(
          freq: 560,
          dur: 0.14,
          type: WaveType.sawtooth,
          slide: -120,
          vol: 0.36,
          attack: 0.004,
          decay: 0.05,
          sustain: 0.34,
          release: 0.12,
        ),
        layer(
          freq: 980,
          dur: 0.1,
          type: WaveType.square,
          slide: -300,
          vol: 0.28,
          attack: 0.003,
          decay: 0.04,
          sustain: 0.25,
          release: 0.1,
          delay: 0.02,
        ),
        layer(
          freq: 820,
          dur: 0.08,
          type: WaveType.noise,
          vol: 0.14,
          attack: 0.002,
          decay: 0.04,
          sustain: 0.15,
          release: 0.08,
          delay: 0.03,
        ),
      ],
      masterVolume: 0.88,
      drive: 0.2,
    );

    _sfxCache['shoot_plasmaBubble'] = _generateLayeredSource(
      [
        layer(
          freq: 360,
          dur: 0.2,
          type: WaveType.sine,
          slide: 220,
          vol: 0.44,
          attack: 0.01,
          decay: 0.06,
          sustain: 0.42,
          release: 0.16,
        ),
        layer(
          freq: 760,
          dur: 0.16,
          type: WaveType.triangle,
          slide: 340,
          vol: 0.28,
          attack: 0.008,
          decay: 0.05,
          sustain: 0.36,
          release: 0.14,
          delay: 0.03,
        ),
      ],
      masterVolume: 0.9,
      echoDelayMs: 70,
      echoDecay: 0.2,
    );

    _sfxCache['shoot_resonanceSiphon'] = _generateLayeredSource(
      [
        layer(
          freq: 240,
          dur: 0.26,
          type: WaveType.sine,
          slide: -40,
          vol: 0.4,
          attack: 0.01,
          decay: 0.07,
          sustain: 0.5,
          release: 0.18,
        ),
        layer(
          freq: 490,
          dur: 0.2,
          type: WaveType.triangle,
          slide: 80,
          vol: 0.22,
          attack: 0.01,
          decay: 0.06,
          sustain: 0.45,
          release: 0.14,
        ),
      ],
      masterVolume: 0.82,
      echoDelayMs: 90,
      echoDecay: 0.2,
    );

    _sfxCache['shoot_ionSniper'] = _generateLayeredSource(
      [
        layer(
          freq: 520,
          dur: 0.45,
          type: WaveType.sine,
          slide: -280,
          vol: 0.7,
          attack: 0.01,
          decay: 0.1,
          sustain: 0.6,
          release: 0.25,
        ),
        layer(
          freq: 1800,
          dur: 0.12,
          type: WaveType.square,
          slide: -900,
          vol: 0.25,
          attack: 0.004,
          decay: 0.05,
          sustain: 0.2,
          release: 0.1,
          delay: 0.12,
        ),
        layer(
          freq: 700,
          dur: 0.03,
          type: WaveType.noise,
          vol: 0.12,
          attack: 0.01,
          decay: 0.03,
          sustain: 0.2,
          release: 0.08,
          delay: 0.1,
        ),
      ],
      masterVolume: 0.95,
      drive: 0.15,
    );

    _sfxCache['shoot_teslaTerminal'] = _generateLayeredSource(
      [
        layer(
          freq: 900,
          dur: 0.12,
          type: WaveType.noise,
          vol: 0.4,
          attack: 0.002,
          decay: 0.06,
          sustain: 0.2,
          release: 0.2,
        ),
        layer(
          freq: 1400,
          dur: 0.08,
          type: WaveType.square,
          slide: 400,
          vol: 0.4,
          attack: 0.003,
          decay: 0.03,
          sustain: 0.2,
          release: 0.08,
        ),
        layer(
          freq: 600,
          dur: 0.12,
          type: WaveType.sine,
          slide: 300,
          vol: 0.25,
          attack: 0.01,
          decay: 0.06,
          sustain: 0.3,
          release: 0.18,
        ),
      ],
      masterVolume: 0.9,
      drive: 0.25,
    );

    _sfxCache['shoot_circuitCannon'] = _generateLayeredSource(
      [
        layer(
          freq: 220,
          dur: 0.25,
          type: WaveType.sawtooth,
          slide: -120,
          vol: 0.55,
          attack: 0.005,
          decay: 0.08,
          sustain: 0.4,
          release: 0.2,
        ),
        layer(
          freq: 90,
          dur: 0.22,
          type: WaveType.sine,
          slide: -40,
          vol: 0.45,
          attack: 0.004,
          decay: 0.06,
          sustain: 0.4,
          release: 0.18,
        ),
        layer(
          freq: 160,
          dur: 0.18,
          type: WaveType.noise,
          vol: 0.25,
          attack: 0.004,
          decay: 0.06,
          sustain: 0.2,
          release: 0.2,
        ),
      ],
      masterVolume: 1.0,
      drive: 0.4,
    );

    _sfxCache['shoot_phaseMage'] = _generateLayeredSource(
      [
        layer(
          freq: 880,
          dur: 0.16,
          type: WaveType.sine,
          slide: 360,
          vol: 0.45,
          attack: 0.01,
          decay: 0.06,
          sustain: 0.4,
          release: 0.18,
        ),
        layer(
          freq: 660,
          dur: 0.14,
          type: WaveType.triangle,
          slide: 220,
          vol: 0.35,
          attack: 0.01,
          decay: 0.05,
          sustain: 0.3,
          release: 0.15,
        ),
        layer(
          freq: 900,
          dur: 0.05,
          type: WaveType.noise,
          vol: 0.12,
          attack: 0.01,
          decay: 0.05,
          sustain: 0.2,
          release: 0.15,
          delay: 0.05,
        ),
      ],
      masterVolume: 0.9,
      echoDelayMs: 60,
      echoDecay: 0.2,
    );

    // Tower-specific hit sounds
    _sfxCache['hit_ionSniper'] = _generateLayeredSource(
      [
        layer(
          freq: 140,
          dur: 0.12,
          type: WaveType.noise,
          vol: 0.4,
          attack: 0.003,
          decay: 0.05,
          sustain: 0.3,
          release: 0.15,
        ),
        layer(
          freq: 120,
          dur: 0.12,
          type: WaveType.sine,
          slide: -40,
          vol: 0.3,
          attack: 0.003,
          decay: 0.05,
          sustain: 0.3,
          release: 0.15,
        ),
        layer(
          freq: 800,
          dur: 0.05,
          type: WaveType.square,
          slide: -300,
          vol: 0.2,
          attack: 0.002,
          decay: 0.02,
          sustain: 0.2,
          release: 0.08,
        ),
      ],
      masterVolume: 0.85,
      drive: 0.2,
    );

    _sfxCache['hit_teslaTerminal'] = _generateLayeredSource(
      [
        layer(
          freq: 1600,
          dur: 0.05,
          type: WaveType.square,
          slide: 600,
          vol: 0.3,
          attack: 0.002,
          decay: 0.02,
          sustain: 0.2,
          release: 0.08,
        ),
        layer(
          freq: 500,
          dur: 0.06,
          type: WaveType.noise,
          vol: 0.3,
          attack: 0.002,
          decay: 0.04,
          sustain: 0.2,
          release: 0.1,
        ),
        layer(
          freq: 420,
          dur: 0.08,
          type: WaveType.sine,
          slide: 200,
          vol: 0.2,
          attack: 0.004,
          decay: 0.05,
          sustain: 0.2,
          release: 0.12,
        ),
      ],
      masterVolume: 0.8,
      drive: 0.25,
    );

    _sfxCache['hit_circuitCannon'] = _generateLayeredSource(
      [
        layer(
          freq: 100,
          dur: 0.22,
          type: WaveType.noise,
          vol: 0.5,
          attack: 0.003,
          decay: 0.08,
          sustain: 0.3,
          release: 0.2,
        ),
        layer(
          freq: 80,
          dur: 0.18,
          type: WaveType.sine,
          slide: -30,
          vol: 0.35,
          attack: 0.004,
          decay: 0.06,
          sustain: 0.3,
          release: 0.18,
        ),
        layer(
          freq: 160,
          dur: 0.12,
          type: WaveType.sawtooth,
          slide: -80,
          vol: 0.25,
          attack: 0.004,
          decay: 0.05,
          sustain: 0.2,
          release: 0.15,
        ),
      ],
      masterVolume: 0.95,
      drive: 0.35,
    );

    _sfxCache['hit_phaseMage'] = _generateLayeredSource(
      [
        layer(
          freq: 900,
          dur: 0.08,
          type: WaveType.sine,
          slide: 200,
          vol: 0.25,
          attack: 0.006,
          decay: 0.04,
          sustain: 0.25,
          release: 0.12,
        ),
        layer(
          freq: 600,
          dur: 0.1,
          type: WaveType.triangle,
          slide: 180,
          vol: 0.3,
          attack: 0.006,
          decay: 0.05,
          sustain: 0.3,
          release: 0.12,
        ),
        layer(
          freq: 700,
          dur: 0.06,
          type: WaveType.noise,
          vol: 0.15,
          attack: 0.006,
          decay: 0.03,
          sustain: 0.2,
          release: 0.1,
        ),
      ],
      masterVolume: 0.85,
    );

    _sfxCache['hit_pulseArcher'] = _generateLayeredSource(
      [
        layer(
          freq: 260,
          dur: 0.09,
          type: WaveType.noise,
          slide: -120,
          vol: 0.34,
          attack: 0.002,
          decay: 0.03,
          sustain: 0.2,
          release: 0.09,
        ),
        layer(
          freq: 320,
          dur: 0.08,
          type: WaveType.sine,
          slide: -40,
          vol: 0.22,
          attack: 0.003,
          decay: 0.03,
          sustain: 0.22,
          release: 0.08,
        ),
      ],
      masterVolume: 0.82,
    );

    _sfxCache['hit_glimmerField'] = _generateLayeredSource(
      [
        layer(
          freq: 520,
          dur: 0.07,
          type: WaveType.sine,
          slide: 120,
          vol: 0.24,
          attack: 0.003,
          decay: 0.025,
          sustain: 0.2,
          release: 0.07,
        ),
        layer(
          freq: 880,
          dur: 0.06,
          type: WaveType.noise,
          vol: 0.12,
          attack: 0.002,
          decay: 0.02,
          sustain: 0.16,
          release: 0.06,
        ),
      ],
      masterVolume: 0.76,
      echoDelayMs: 42,
      echoDecay: 0.1,
    );

    _sfxCache['hit_neuralDisruptor'] = _generateLayeredSource(
      [
        layer(
          freq: 300,
          dur: 0.12,
          type: WaveType.sawtooth,
          slide: -80,
          vol: 0.3,
          attack: 0.003,
          decay: 0.04,
          sustain: 0.3,
          release: 0.12,
        ),
        layer(
          freq: 620,
          dur: 0.1,
          type: WaveType.square,
          slide: 150,
          vol: 0.22,
          attack: 0.003,
          decay: 0.04,
          sustain: 0.24,
          release: 0.1,
          delay: 0.02,
        ),
      ],
      masterVolume: 0.84,
      drive: 0.16,
    );

    _sfxCache['hit_plasmaBubble'] = _generateLayeredSource(
      [
        layer(
          freq: 140,
          dur: 0.16,
          type: WaveType.noise,
          slide: -80,
          vol: 0.34,
          attack: 0.003,
          decay: 0.05,
          sustain: 0.28,
          release: 0.14,
        ),
        layer(
          freq: 280,
          dur: 0.15,
          type: WaveType.sine,
          slide: -40,
          vol: 0.26,
          attack: 0.004,
          decay: 0.05,
          sustain: 0.3,
          release: 0.13,
        ),
        layer(
          freq: 640,
          dur: 0.09,
          type: WaveType.triangle,
          slide: 120,
          vol: 0.16,
          attack: 0.004,
          decay: 0.03,
          sustain: 0.2,
          release: 0.08,
          delay: 0.02,
        ),
      ],
      masterVolume: 0.9,
      echoDelayMs: 70,
      echoDecay: 0.16,
    );

    _sfxCache['hit_resonanceSiphon'] = _generateLayeredSource(
      [
        layer(
          freq: 220,
          dur: 0.14,
          type: WaveType.sine,
          slide: -30,
          vol: 0.24,
          attack: 0.004,
          decay: 0.05,
          sustain: 0.3,
          release: 0.12,
        ),
        layer(
          freq: 430,
          dur: 0.12,
          type: WaveType.triangle,
          slide: 60,
          vol: 0.2,
          attack: 0.004,
          decay: 0.05,
          sustain: 0.3,
          release: 0.11,
        ),
      ],
      masterVolume: 0.75,
      echoDelayMs: 65,
      echoDecay: 0.14,
    );

    _rebuildSfxDurationIndex();
  }

  BytesSource _generateSource({
    required double frequency,
    required double duration,
    required WaveType type,
    double frequencySlide = 0,
    double volume = 0.8,
  }) {
    final pcmFloat32 = _generateWaveform(
      frequency: frequency,
      duration: duration,
      type: type,
      frequencySlide: frequencySlide,
      volume: volume,
    );

    final pcm16 = Int16List(pcmFloat32.length);
    for (var i = 0; i < pcmFloat32.length; i++) {
      final sample = (pcmFloat32[i] * 32767.0).clamp(-32768.0, 32767.0);
      pcm16[i] = sample.toInt();
    }
    return BytesSource(_addWavHeader(pcm16.buffer.asUint8List()));
  }

  BytesSource _generateLayeredSource(
    List<_SfxLayer> layers, {
    double masterVolume = 0.9,
    double drive = 0.0,
    double echoDelayMs = 0,
    double echoDecay = 0.0,
  }) {
    final pcmFloat32 = _generateLayeredWaveform(
      layers,
      masterVolume: masterVolume,
      drive: drive,
      echoDelayMs: echoDelayMs,
      echoDecay: echoDecay,
    );

    final pcm16 = Int16List(pcmFloat32.length);
    for (var i = 0; i < pcmFloat32.length; i++) {
      final sample = (pcmFloat32[i] * 32767.0).clamp(-32768.0, 32767.0);
      pcm16[i] = sample.toInt();
    }
    return BytesSource(_addWavHeader(pcm16.buffer.asUint8List()));
  }

  Float32List _generateLayeredWaveform(
    List<_SfxLayer> layers, {
    required double masterVolume,
    required double drive,
    required double echoDelayMs,
    required double echoDecay,
  }) {
    var totalDuration = 0.0;
    for (final layer in layers) {
      final endTime = layer.startDelay + layer.duration;
      if (endTime > totalDuration) totalDuration = endTime;
    }
    final samples = (totalDuration * _sampleRate).ceil().clamp(1, 1 << 30);
    final data = Float32List(samples);

    for (final layer in layers) {
      final layerSamples = (layer.duration * _sampleRate).ceil();
      final startIndex = (layer.startDelay * _sampleRate).round();
      var noiseLast = 0.0;

      for (int i = 0; i < layerSamples && startIndex + i < data.length; i++) {
        final t = i / _sampleRate;
        final progress = layerSamples > 0 ? i / layerSamples : 1.0;
        var freq = layer.frequency + (layer.frequencySlide * progress);
        if (layer.vibratoDepth > 0 && layer.vibratoRate > 0) {
          freq += math.sin(2 * math.pi * layer.vibratoRate * t) *
              layer.vibratoDepth;
        }

        double sample;
        switch (layer.type) {
          case WaveType.sine:
            sample = math.sin(2 * math.pi * freq * t);
            break;
          case WaveType.square:
            sample = math.sin(2 * math.pi * freq * t) > 0 ? 1.0 : -1.0;
            break;
          case WaveType.triangle:
            final phase = (freq * t) % 1.0;
            sample = 4.0 * (phase < 0.5 ? phase : 1.0 - phase) - 1.0;
            break;
          case WaveType.sawtooth:
            sample = 2.0 * ((freq * t) % 1.0) - 1.0;
            break;
          case WaveType.noise:
            sample = _random.nextDouble() * 2.0 - 1.0;
            if (i > 0) sample = noiseLast * 0.65 + sample * 0.35;
            noiseLast = sample;
            break;
        }

        final envelope = _adsrEnvelope(
            progress, layer.attack, layer.decay, layer.sustain, layer.release);
        final mixed = sample * layer.volume * envelope;
        data[startIndex + i] += mixed;
      }
    }

    if (echoDelayMs > 0 && echoDecay > 0) {
      final delaySamples =
          ((echoDelayMs / 1000.0) * _sampleRate).round().clamp(1, samples);
      for (int i = delaySamples; i < data.length; i++) {
        data[i] += data[i - delaySamples] * echoDecay;
      }
    }

    if (drive > 0) {
      final driven = 1 + drive * 4.0;
      for (int i = 0; i < data.length; i++) {
        final x = data[i] * driven;
        data[i] = (x / (1.0 + x.abs())).clamp(-1.0, 1.0);
      }
    }

    _applyMasteringToWaveform(
      data,
      masterVolume: masterVolume.clamp(0.0, 1.0),
      drive: drive,
    );

    return data;
  }

  void _rebuildSfxDurationIndex() {
    _sfxDurationMicros.clear();
    for (final entry in _sfxCache.entries) {
      _sfxDurationMicros[entry.key] =
          _estimateSourceDurationMicros(entry.value);
    }
  }

  int _estimateSourceDurationMicros(BytesSource source) {
    final bytesLength = source.bytes.length;
    if (bytesLength <= 44) return 100000;
    final pcmLength = bytesLength - 44;
    final samples = pcmLength ~/ 2; // 16-bit mono PCM
    if (samples <= 0) return 100000;
    final micros = ((samples / _sampleRate) * 1000000).round();
    return micros.clamp(30000, 4000000).toInt();
  }

  void _applyMasteringToWaveform(
    Float32List data, {
    required double masterVolume,
    required double drive,
  }) {
    if (data.isEmpty) return;
    _applyDcBlock(data);
    _applyToneContour(data, drive: drive);
    _applySoftLimiter(
      data,
      threshold: (0.9 - drive.clamp(0.0, 1.0) * 0.14).clamp(0.68, 0.92),
    );
    _normalizeByLoudness(
      data,
      targetRms: (0.21 + masterVolume * 0.09 + drive.clamp(0.0, 1.0) * 0.04)
          .clamp(0.16, 0.36),
      targetPeak: 0.94,
    );

    for (int i = 0; i < data.length; i++) {
      data[i] = (data[i] * masterVolume).clamp(-1.0, 1.0);
    }
  }

  void _applyDcBlock(Float32List data) {
    var prevInput = 0.0;
    var prevOutput = 0.0;
    const dcReject = 0.995;
    for (int i = 0; i < data.length; i++) {
      final current = data[i];
      final filtered = current - prevInput + dcReject * prevOutput;
      prevInput = current;
      prevOutput = filtered;
      data[i] = filtered;
    }
  }

  void _applyToneContour(
    Float32List data, {
    required double drive,
  }) {
    final normalizedDrive = drive.clamp(0.0, 1.0);
    final cutoffHz = (9800.0 - normalizedDrive * 2200.0).clamp(7200.0, 11000.0);
    final omega = 2 * math.pi * cutoffHz;
    final alpha = (omega / (_sampleRate + omega)).clamp(0.0, 1.0);
    final presence = 0.08 + normalizedDrive * 0.1;
    var lowPass = 0.0;
    var previousDry = 0.0;
    for (int i = 0; i < data.length; i++) {
      final dry = data[i];
      lowPass += alpha * (dry - lowPass);
      final bright = (dry - previousDry) * presence;
      previousDry = dry;
      data[i] = (dry * 0.72 + lowPass * 0.28 + bright).clamp(-1.0, 1.0);
    }
  }

  void _applySoftLimiter(
    Float32List data, {
    required double threshold,
  }) {
    final t = threshold.clamp(0.55, 0.96);
    const saturation = 4.6;
    for (int i = 0; i < data.length; i++) {
      final value = data[i];
      final absValue = value.abs();
      if (absValue <= t) continue;
      final compressed =
          t + ((absValue - t) / (1.0 + (absValue - t) * saturation));
      data[i] = value < 0 ? -compressed : compressed;
    }
  }

  void _normalizeByLoudness(
    Float32List data, {
    required double targetRms,
    required double targetPeak,
  }) {
    if (data.isEmpty) return;
    var peak = 0.0;
    var sumSquares = 0.0;
    for (final sample in data) {
      final absSample = sample.abs();
      if (absSample > peak) peak = absSample;
      sumSquares += sample * sample;
    }

    if (peak <= 0.000001) return;
    final rms = math.sqrt(sumSquares / data.length);
    var gain = 1.0;
    if (rms > 0.000001) {
      gain = (targetRms / rms).clamp(0.72, 1.38);
    }
    final target = targetPeak.clamp(0.7, 0.98);
    final postPeak = peak * gain;
    if (postPeak > target) {
      gain *= target / postPeak;
    }

    for (int i = 0; i < data.length; i++) {
      data[i] = (data[i] * gain).clamp(-1.0, 1.0);
    }
  }

  /// Enable/disable all audio
  void setEnabled(bool value) {
    _enabled = value;
  }

  /// Set music volume (0.0 - 1.0)
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    // Also update ambient soundscape volume
    AmbientSoundscapeService.instance.setVolume(_musicVolume);
  }

  /// Set SFX volume (0.0 - 1.0)
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  /// Sets adaptive SFX profile (`low`, `medium`, `high`, `extreme`).
  void setSoundProfile(String profile) {
    _soundProfile = _normalizeSoundProfile(profile);
  }

  /// Applies runtime load pressure to adaptive SFX limiting.
  void setCombatLoad({
    required bool heavyLoad,
    required bool severeLoad,
  }) {
    _combatSevereLoad = severeLoad;
    _combatHeavyLoad = heavyLoad || severeLoad;
  }

  /// Feeds live battle context to drive adaptive "epic" SFX behavior.
  void setBattleSnapshot({
    required int enemyCount,
    required double waveProgress,
    required bool bossActive,
    int comboLevel = 0,
  }) {
    final enemiesScore = (enemyCount / 55.0).clamp(0.0, 1.0);
    final waveScore = waveProgress.clamp(0.0, 1.0);
    final comboScore = (comboLevel / 12.0).clamp(0.0, 1.0);
    var target =
        0.2 + enemiesScore * 0.42 + waveScore * 0.2 + comboScore * 0.22;
    if (bossActive) {
      target += 0.24;
    }
    target = target.clamp(0.15, 1.0);
    final smoothing = bossActive ? 0.45 : 0.24;
    _battleIntensity =
        (_battleIntensity + (target - _battleIntensity) * smoothing)
            .clamp(0.12, 1.0);
    _bossActive = bossActive;
    _comboLevel = comboLevel.clamp(0, 99);
    _updateEpicStage(signalIfEscalating: true);
  }

  /// Temporarily ducks combat SFX so priority cues are clearer.
  void triggerPriorityDucking({
    Duration duration = const Duration(milliseconds: 700),
    double combatScale = 0.45,
  }) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final until = now + duration.inMicroseconds.clamp(0, 8000000);
    final clampedScale = combatScale.clamp(0.2, 1.0);

    if (until >= _priorityDuckingUntilMicros) {
      _priorityCombatDuckScale = clampedScale;
      _priorityDuckingUntilMicros = until;
    } else {
      _priorityCombatDuckScale =
          math.min(_priorityCombatDuckScale, clampedScale);
    }
  }

  /// Temporarily boosts cue energy for epic moments (boss, combo, wave climax).
  void triggerEpicMoment({
    Duration duration = const Duration(milliseconds: 900),
    double boostScale = 0.22,
  }) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final until = now + duration.inMicroseconds.clamp(0, 10000000);
    final clampedBoost = boostScale.clamp(0.0, 0.6);
    _epicBoostScale = math.max(_epicBoostScale, clampedBoost);
    _epicBoostUntilMicros = math.max(_epicBoostUntilMicros, until);
    _updateEpicStage(signalIfEscalating: true);
  }

  // ============ Sound Effect Methods ============

  bool get _canPlay => _enabled && _sfxVolume > 0 && _initialized;

  void _playCached(
    String key, {
    double volumeMult = 1.0,
    double pan = 0.0,
    double distance = 0.0,
    double playbackRate = 1.0,
  }) {
    if (!_canPlay) return;
    final canonicalKey = _canonicalSfxKey(key);
    final nowMicros = DateTime.now().microsecondsSinceEpoch;
    final previousSameMicros = _lastSfxPlayMicros[canonicalKey];
    if (!_allowSfxNow(
      key: canonicalKey,
      nowMicros: nowMicros,
      minIntervalMs: _minIntervalForSfxKey(canonicalKey),
    )) {
      return;
    }

    final resolvedKey = _resolveSourceKey(key, canonicalKey);
    final source = _sfxCache[resolvedKey] ?? _sfxCache['shoot_default'];
    if (source == null) return;
    _lastPlayedKey = key;
    _lastResolvedKey = resolvedKey;
    _pruneActiveSfxVoices(nowMicros);

    var finalVolumeMult = volumeMult;
    if (_isCombatKey(canonicalKey)) {
      finalVolumeMult *= _effectiveCombatVolumeScale();
    }
    if (_isEpicCueKey(canonicalKey)) {
      finalVolumeMult *= _effectiveCueVolumeScale(canonicalKey);
    }
    finalVolumeMult *= _distanceVolumeScale(distance);
    finalVolumeMult *= _combatAccentScale(canonicalKey);
    finalVolumeMult *=
        _repeatSmoothingScale(canonicalKey, previousSameMicros, nowMicros);
    finalVolumeMult *= _headroomScaleForActiveMix(canonicalKey);

    final actualVolume = (_sfxVolume * finalVolumeMult).clamp(0.0, 1.0);
    final spatialPan = _effectivePan(pan);
    final rate = _effectivePlaybackRate(
      playbackRate *
          _repeatRateHumanization(canonicalKey, previousSameMicros, nowMicros),
    );
    _registerActiveSfxVoice(nowMicros, resolvedKey, canonicalKey);

    final player = _playerPool[_currentPlayerIndex];
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _poolSize;
    _lastAppliedPan = spatialPan;
    _lastAppliedDistance = distance.clamp(0.0, 1.0);
    _lastAppliedPlaybackRate = rate;
    unawaited(_playOnPlayer(
      player: player,
      source: source,
      volume: actualVolume,
      pan: spatialPan,
      playbackRate: rate,
    ));
  }

  /// Tower shoots - quick zap sound
  void playShoot({
    TowerType? type,
    double pan = 0.0,
    double distance = 0.0,
  }) {
    final key =
        type != null ? 'shoot_${_towerSfxToken(type)}' : 'shoot_default';
    _playCached(
      key,
      pan: pan,
      distance: distance,
      playbackRate: _randomizedRate(_pitchSpreadForKey(key)),
    );
  }

  /// Bullet hits enemy - impact thud
  void playHit({
    TowerType? type,
    double pan = 0.0,
    double distance = 0.0,
  }) {
    final key = type != null ? 'hit_${_towerSfxToken(type)}' : 'hit_default';
    _playCached(
      key,
      pan: pan,
      distance: distance,
      playbackRate: _randomizedRate(_pitchSpreadForKey(key)),
    );
  }

  /// Critical hit - sharp confirm tone
  void playCriticalHit() => _playCached('critical', volumeMult: 1.1);

  /// Enemy or mine explosion - big boom
  void playExplosion() => _playCached('explosion');

  /// Tower placed - construction sound
  void playBuild({
    TowerType? type,
    double pan = 0.0,
    double distance = 0.0,
  }) {
    final key = switch (_towerArchetype(type)) {
      _TowerArchetype.heavy => 'build_heavy',
      _TowerArchetype.arcane => 'build_arcane',
      _TowerArchetype.utility => 'build_utility',
      _TowerArchetype.precision => 'build',
    };
    _playCached(
      key,
      pan: pan,
      distance: distance,
      playbackRate: _randomizedRate(0.02),
    );
  }

  /// New wave starting - alert
  void playWaveStart() => _playCached(_resolveCueKey('wave_start'));

  /// Wave complete - triumphant cadence
  void playWaveComplete() => _playCached(_resolveCueKey('wave_complete'));

  /// Neon pulse activated - whoosh
  void playPulse() => _playCached('pulse');

  /// Mine deployed - beep
  void playMineDeploy() => _playCached('mine_deploy');

  /// Mine explodes - bigger explosion
  void playMineExplode() => _playCached('mine_explode');

  /// UI button click
  void playButton() => _playCached('button');

  /// Enemy reaches base - warning (DISABLED - sound removed)
  void playEnemyLeak() {} // No-op: enemy leak sound disabled

  /// Gold earned
  void playGoldEarned() => _playCached('gold');

  /// Phantom enemy revealed
  void playPhantomReveal() => _playCached('phantom_reveal');

  /// Game Over - sad tone
  void playGameOver() => _playCached('game_over');

  /// Victory - fanfare
  void playVictory() => _playCached(_resolveCueKey('victory'));

  /// Boss spawn - heavy alert
  void playBossSpawn() => _playCached(_resolveCueKey('boss_spawn'));

  /// Boss phase shift - stinger
  void playBossPhase() => _playCached(_resolveCueKey('boss_phase'));

  /// Combo milestone celebration cue.
  void playComboMilestone(int combo) {
    final key = _comboMilestoneKey(combo);
    if (key == null) return;
    final boost = switch (key) {
      'combo_triple' => 0.12,
      'combo_spree' => 0.16,
      'combo_rampage' => 0.22,
      'combo_unstoppable' => 0.3,
      _ => 0.12,
    };
    triggerEpicMoment(
      duration: const Duration(milliseconds: 780),
      boostScale: boost,
    );
    _playCached(key, volumeMult: 1.06);
  }

  /// Contextual kill-chain cue that ramps with combo and bosses.
  void playKillChain({
    required int combo,
    bool boss = false,
    double pan = 0.0,
    double distance = 0.0,
  }) {
    if (combo < 4 && !boss) return;
    final useMajor = boss || combo >= 8;
    final key = useMajor ? 'kill_chain_major' : 'kill_chain_minor';
    final boost = useMajor ? 0.2 : 0.12;
    triggerEpicMoment(
      duration: Duration(milliseconds: useMajor ? 950 : 620),
      boostScale: boost,
    );
    _playCached(
      key,
      pan: pan,
      distance: distance,
      volumeMult: useMajor ? 1.08 : 0.98,
      playbackRate: _randomizedRate(useMajor ? 0.015 : 0.02),
    );
  }

  String _normalizeSoundProfile(String profile) {
    switch (profile) {
      case 'low':
      case 'medium':
      case 'high':
      case 'extreme':
        return profile;
      default:
        return 'high';
    }
  }

  bool _allowSfxNow({
    required String key,
    required int nowMicros,
    required int minIntervalMs,
  }) {
    const globalFloorIntervalMs = 8;
    final globalDelta = nowMicros - _lastAnySfxPlayMicros;
    if (_lastAnySfxPlayMicros > 0 &&
        globalDelta < globalFloorIntervalMs * 1000) {
      return false;
    }

    final last = _lastSfxPlayMicros[key];
    if (last != null && minIntervalMs > 0) {
      final delta = nowMicros - last;
      if (delta < minIntervalMs * 1000) {
        return false;
      }
    }

    _lastAnySfxPlayMicros = nowMicros;
    _lastSfxPlayMicros[key] = nowMicros;
    return true;
  }

  void _pruneActiveSfxVoices(int nowMicros) {
    _activeSfxUntilMicros.removeWhere((until) => nowMicros >= until);
    _lastConcurrentVoices = _activeSfxUntilMicros.length;
  }

  void _registerActiveSfxVoice(
    int nowMicros,
    String resolvedKey,
    String canonicalKey,
  ) {
    final duration = _sfxDurationMicros[resolvedKey] ??
        _sfxDurationMicros[canonicalKey] ??
        110000;
    final releaseTailMs = switch (_soundProfile) {
      'low' => 22,
      'medium' => 28,
      'high' => 34,
      'extreme' => 40,
      _ => 30,
    };
    final until = nowMicros + duration + releaseTailMs * 1000;
    _activeSfxUntilMicros.add(until);
    _lastConcurrentVoices = _activeSfxUntilMicros.length;
  }

  double _headroomScaleForActiveMix(String canonicalKey) {
    final active = _activeSfxUntilMicros.length;
    if (active <= 1) {
      _lastHeadroomScale = 1.0;
      return 1.0;
    }

    final (slope, floor) = switch (_soundProfile) {
      'low' => (0.27, 0.58),
      'medium' => (0.22, 0.62),
      'high' => (0.19, 0.68),
      'extreme' => (0.16, 0.74),
      _ => (0.19, 0.68),
    };
    final pressure = math.max(0, active - 2);
    var scale = (1.0 / (1.0 + pressure * slope)).clamp(floor, 1.0);
    if (_isEpicCueKey(canonicalKey)) {
      scale = (scale + 0.14).clamp(0.78, 1.0);
    } else if (!_isCombatKey(canonicalKey)) {
      scale = (scale + 0.06).clamp(0.74, 1.0);
    }
    _lastHeadroomScale = scale;
    return scale;
  }

  double _repeatSmoothingScale(
    String canonicalKey,
    int? previousMicros,
    int nowMicros,
  ) {
    if (previousMicros == null) return 1.0;
    final deltaMs = (nowMicros - previousMicros) / 1000.0;
    if (deltaMs >= 180) return 1.0;
    final pressure = ((180 - deltaMs) / 180).clamp(0.0, 1.0);
    final amount = canonicalKey.startsWith('shoot_')
        ? 0.09
        : (canonicalKey.startsWith('hit_') ? 0.07 : 0.05);
    var scale = 1.0 - pressure * amount;
    if (_isEpicCueKey(canonicalKey)) {
      scale = math.max(scale, 0.96);
    }
    return scale.clamp(0.84, 1.0);
  }

  double _repeatRateHumanization(
    String canonicalKey,
    int? previousMicros,
    int nowMicros,
  ) {
    if (previousMicros == null) return 1.0;
    final deltaMs = (nowMicros - previousMicros) / 1000.0;
    if (deltaMs >= 140) return 1.0;
    final pressure = ((140 - deltaMs) / 140).clamp(0.0, 1.0);
    final spread = switch (_soundProfile) {
      'low' => 0.004,
      'medium' => 0.006,
      'high' => 0.008,
      'extreme' => 0.01,
      _ => 0.008,
    };
    final cueBoost = _isEpicCueKey(canonicalKey) ? 0.55 : 1.0;
    final jitter =
        (_random.nextDouble() * 2.0 - 1.0) * spread * pressure * cueBoost;
    return (1.0 + jitter).clamp(0.94, 1.06);
  }

  String _resolveSourceKey(String requestedKey, String canonicalKey) {
    if (_sfxCache.containsKey(requestedKey)) return requestedKey;
    if (_sfxCache.containsKey(canonicalKey)) return canonicalKey;
    return 'shoot_default';
  }

  Future<void> _playOnPlayer({
    required AudioPlayer player,
    required BytesSource source,
    required double volume,
    required double pan,
    required double playbackRate,
  }) async {
    try {
      await player.setBalance(pan);
      await player.setPlaybackRate(playbackRate);
      await player.play(source, volume: volume);
    } catch (_) {
      // Ignore playback failures; audio should never break game flow.
    }
  }

  double _effectivePan(double pan) {
    final clamped = pan.clamp(-1.0, 1.0);
    final widthScale = switch (_soundProfile) {
      'low' => 0.35,
      'medium' => 0.5,
      'high' => 0.72,
      'extreme' => 0.88,
      _ => 0.72,
    };
    final stageWidthBoost = 1.0 + _epicStage * 0.08;
    final equalPowerPan = math.sin(clamped * math.pi * 0.5);
    return (equalPowerPan * widthScale * stageWidthBoost).clamp(-1.0, 1.0);
  }

  double _distanceVolumeScale(double distance) {
    final clamped = distance.clamp(0.0, 1.0);
    final attenuation = switch (_soundProfile) {
      'low' => 0.44,
      'medium' => 0.38,
      'high' => 0.33,
      'extreme' => 0.28,
      _ => 0.33,
    };
    final stageRelief = _epicStage * 0.02;
    final curvedDistance = math.pow(clamped, 1.14).toDouble();
    return (1.0 - curvedDistance * math.max(0.16, attenuation - stageRelief))
        .clamp(0.55, 1.0);
  }

  double _pitchSpreadForKey(String key) {
    if (key.startsWith('shoot_')) return 0.04;
    if (key.startsWith('hit_')) return 0.035;
    if (key.startsWith('kill_chain_')) return 0.018;
    if (key.startsWith('epic_stage_')) return 0.012;
    if (key.startsWith('combo_')) return 0.02;
    if (_isEpicCueKey(_canonicalSfxKey(key))) return 0.016;
    return 0.0;
  }

  double _randomizedRate(double spread) {
    if (spread <= 0) return 1.0;
    final jitter = (_random.nextDouble() * 2.0 - 1.0) * spread;
    return (1.0 + jitter).clamp(0.82, 1.24);
  }

  double _effectivePlaybackRate(double baseRate) {
    final profileScale = switch (_soundProfile) {
      'low' => 0.985,
      'medium' => 0.995,
      'high' => 1.0,
      'extreme' => 1.01,
      _ => 1.0,
    };
    return (baseRate * profileScale).clamp(0.82, 1.24);
  }

  double _combatAccentScale(String canonicalKey) {
    if (!canonicalKey.startsWith('shoot_') &&
        !canonicalKey.startsWith('hit_')) {
      return 1.0;
    }
    final count = (_combatPatternCounts[canonicalKey] ?? 0) + 1;
    _combatPatternCounts[canonicalKey] = count;
    final cadence = _soundProfile == 'extreme' ? 4 : 5;
    final isAccent = count % cadence == 0;
    if (!isAccent) return 1.0;
    final epic = _epicBoostNow();
    return (1.04 + _battleIntensity * 0.05 + epic * 0.08).clamp(1.02, 1.18);
  }

  bool _isCombatKey(String key) {
    return key.startsWith('shoot_') ||
        key.startsWith('hit_') ||
        key == 'explosion' ||
        key == 'mine_explode' ||
        key == 'critical';
  }

  int _minIntervalForSfxKey(String key) {
    if (key.startsWith('shoot_')) return _effectiveCombatIntervalMs(22);
    if (key.startsWith('hit_')) return _effectiveCombatIntervalMs(18);
    if (key == 'explosion' || key == 'mine_explode') {
      return _effectiveCombatIntervalMs(80);
    }
    if (key == 'critical') return _effectiveCombatIntervalMs(55);
    if (key == 'button') return _effectiveUiIntervalMs(36);
    if (key == 'gold') return _effectiveUiIntervalMs(60);
    if (key.startsWith('kill_chain_')) return 180;
    if (key.startsWith('epic_stage_')) return 650;
    if (key.startsWith('combo_')) return 160;
    if (key == 'wave_start' ||
        key == 'wave_complete' ||
        key == 'boss_spawn' ||
        key == 'boss_phase' ||
        key == 'game_over' ||
        key == 'victory') {
      return 120;
    }
    return 0;
  }

  int _effectiveUiIntervalMs(int baseMs) {
    final profileFactor = switch (_soundProfile) {
      'low' => 1.4,
      'medium' => 1.2,
      'high' => 1.0,
      'extreme' => 0.9,
      _ => 1.0,
    };
    return (baseMs * profileFactor).round().clamp(8, 300);
  }

  int _effectiveCombatIntervalMs(int baseMs) {
    final profileFactor = switch (_soundProfile) {
      'low' => 1.8,
      'medium' => 1.35,
      'high' => 1.0,
      'extreme' => 0.8,
      _ => 1.0,
    };
    final loadFactor =
        _combatSevereLoad ? 1.7 : (_combatHeavyLoad ? 1.35 : 1.0);
    final stageFactor = 1.0 - _epicStage * 0.03;
    final intensityFactor =
        1.04 - (_battleIntensity * 0.16) - (_epicBoostNow() * 0.12);
    return (baseMs * profileFactor * loadFactor * intensityFactor * stageFactor)
        .round()
        .clamp(8, 400);
  }

  double _effectiveCombatVolumeScale() {
    final profileScale = switch (_soundProfile) {
      'low' => 0.72,
      'medium' => 0.86,
      'high' => 1.0,
      'extreme' => 1.08,
      _ => 1.0,
    };
    final loadScale =
        _combatSevereLoad ? 0.72 : (_combatHeavyLoad ? 0.86 : 1.0);
    final stageScale = 1.0 + _epicStage * 0.04;
    final battleScale = (0.9 + _battleIntensity * 0.24 + _epicBoostNow() * 0.16)
        .clamp(0.75, 1.25);
    return (profileScale *
            loadScale *
            battleScale *
            stageScale *
            _priorityCombatScaleNow())
        .clamp(0.2, 1.3);
  }

  double _priorityCombatScaleNow() {
    if (_priorityDuckingUntilMicros <= 0) return 1.0;
    final now = DateTime.now().microsecondsSinceEpoch;
    if (now >= _priorityDuckingUntilMicros) {
      _priorityDuckingUntilMicros = 0;
      _priorityCombatDuckScale = 1.0;
      return 1.0;
    }
    return _priorityCombatDuckScale;
  }

  double _epicBoostNow() {
    if (_epicBoostUntilMicros <= 0 || _epicBoostScale <= 0) {
      return 0.0;
    }
    final now = DateTime.now().microsecondsSinceEpoch;
    if (now >= _epicBoostUntilMicros) {
      _epicBoostUntilMicros = 0;
      _epicBoostScale = 0.0;
      return 0.0;
    }
    return _epicBoostScale;
  }

  String _canonicalSfxKey(String key) {
    if (key.endsWith('_epic')) {
      return key.substring(0, key.length - 5);
    }
    return key;
  }

  bool _isEpicCueKey(String key) {
    return key == 'wave_start' ||
        key == 'wave_complete' ||
        key == 'boss_spawn' ||
        key == 'boss_phase' ||
        key == 'victory' ||
        key.startsWith('kill_chain_') ||
        key.startsWith('epic_stage_') ||
        key.startsWith('combo_');
  }

  double _effectiveCueVolumeScale(String key) {
    var scale = 0.94 +
        _battleIntensity * 0.16 +
        _epicBoostNow() * 0.32 +
        _epicStage * 0.04;
    if (_bossActive && (key == 'boss_spawn' || key == 'boss_phase')) {
      scale += 0.12;
    }
    if (key.startsWith('combo_')) {
      scale += (_comboLevel / 40.0).clamp(0.0, 0.2);
    }
    if (key.startsWith('kill_chain_')) {
      scale += 0.06;
    }
    if (key.startsWith('epic_stage_')) {
      scale += 0.08;
    }
    return scale.clamp(0.78, 1.45);
  }

  bool _preferEpicCues() {
    if (_soundProfile == 'extreme') return true;
    if (_soundProfile != 'high') return false;
    return _battleIntensity >= 0.58 || _bossActive || _comboLevel >= 7;
  }

  String _resolveCueKey(String baseKey) {
    if (!_preferEpicCues()) return baseKey;
    final epicKey = '${baseKey}_epic';
    return _sfxCache.containsKey(epicKey) ? epicKey : baseKey;
  }

  String? _comboMilestoneKey(int combo) {
    if (combo >= 10) return 'combo_unstoppable';
    if (combo >= 7) return 'combo_rampage';
    if (combo >= 5) return 'combo_spree';
    if (combo >= 3) return 'combo_triple';
    return null;
  }

  double _epicEnergyNow() {
    final comboFactor = (_comboLevel / 12.0).clamp(0.0, 1.0);
    var energy =
        _battleIntensity * 0.72 + comboFactor * 0.22 + _epicBoostNow() * 0.42;
    if (_bossActive) {
      energy += 0.26;
    }
    return energy.clamp(0.0, 1.4);
  }

  int _computeEpicStage(double energy) {
    if (energy >= 1.02) return 3; // overdrive
    if (energy >= 0.75) return 2; // climax
    if (energy >= 0.5) return 1; // combat
    return 0; // calm
  }

  void _updateEpicStage({required bool signalIfEscalating}) {
    final nextStage = _computeEpicStage(_epicEnergyNow());
    final previousStage = _epicStage;
    _epicStage = nextStage;

    if (!signalIfEscalating || nextStage <= previousStage) return;
    if (!_canPlay || nextStage <= 0) return;

    final now = DateTime.now().microsecondsSinceEpoch;
    if (now < _epicStageCueCooldownUntilMicros) return;
    _epicStageCueCooldownUntilMicros = now + 1400000;
    _playCached(
      'epic_stage_$nextStage',
      volumeMult: 0.94 + nextStage * 0.06,
      playbackRate: _randomizedRate(0.012),
    );
  }

  _TowerArchetype _towerArchetype(TowerType? type) {
    if (type == null) return _TowerArchetype.precision;
    return switch (type) {
      TowerType.pulseArcher => _TowerArchetype.precision,
      TowerType.circuitCannon => _TowerArchetype.heavy,
      TowerType.phaseMage => _TowerArchetype.arcane,
      TowerType.glimmerField => _TowerArchetype.utility,
      TowerType.ionSniper => _TowerArchetype.heavy,
      TowerType.teslaTerminal => _TowerArchetype.arcane,
      TowerType.resonanceSiphon => _TowerArchetype.utility,
      TowerType.neuralDisruptor => _TowerArchetype.utility,
      TowerType.plasmaBubble => _TowerArchetype.heavy,
    };
  }

  String _towerSfxToken(TowerType type) {
    return switch (type) {
      TowerType.pulseArcher => 'pulseArcher',
      TowerType.circuitCannon => 'circuitCannon',
      TowerType.phaseMage => 'phaseMage',
      TowerType.glimmerField => 'glimmerField',
      TowerType.ionSniper => 'ionSniper',
      TowerType.teslaTerminal => 'teslaTerminal',
      TowerType.resonanceSiphon => 'resonanceSiphon',
      TowerType.neuralDisruptor => 'neuralDisruptor',
      TowerType.plasmaBubble => 'plasmaBubble',
    };
  }

  // ============ Audio Synthesis ============

  Uint8List _addWavHeader(Uint8List pcmBytes) {
    final int pcmLength = pcmBytes.length;
    final int totalLength = pcmLength + 36;
    const int sampleRate = _sampleRate;
    const int numChannels = 1;
    const int bitsPerSample = 16;
    final int byteRate = (sampleRate * numChannels * bitsPerSample) ~/ 8;
    final int blockAlign = (numChannels * bitsPerSample) ~/ 8;

    final header = ByteData(44);
    header.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    header.setUint32(4, totalLength, Endian.little);
    header.setUint32(8, 0x57415645, Endian.big); // "WAVE"
    header.setUint32(12, 0x666d7420, Endian.big); // "fmt "
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    header.setUint32(36, 0x64617461, Endian.big); // "data"
    header.setUint32(40, pcmLength, Endian.little);

    final out = Uint8List(44 + pcmBytes.length);
    out.setRange(0, 44, header.buffer.asUint8List());
    out.setRange(44, out.length, pcmBytes);
    return out;
  }

  Float32List _generateWaveform({
    required double frequency,
    required double duration,
    required WaveType type,
    double frequencySlide = 0,
    double volume = 0.8,
  }) {
    final samples = (duration * _sampleRate).toInt();
    final data = Float32List(samples);

    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;
      final progress = i / samples;
      final freq = frequency + (frequencySlide * progress);

      double sample;
      switch (type) {
        case WaveType.sine:
          sample = math.sin(2 * math.pi * freq * t);
          break;
        case WaveType.square:
          sample = math.sin(2 * math.pi * freq * t) > 0 ? 1.0 : -1.0;
          break;
        case WaveType.triangle:
          final phase = (freq * t) % 1.0;
          sample = 4.0 * (phase < 0.5 ? phase : 1.0 - phase) - 1.0;
          break;
        case WaveType.sawtooth:
          sample = 2.0 * ((freq * t) % 1.0) - 1.0;
          break;
        case WaveType.noise:
          sample = _random.nextDouble() * 2.0 - 1.0;
          if (i > 0) sample = data[i - 1] * 0.7 + sample * 0.3;
          break;
      }

      final envelope = _calculateEnvelope(progress);
      data[i] = (sample * volume * envelope).clamp(-1.0, 1.0);
    }
    return data;
  }

  double _calculateEnvelope(double progress) {
    const attackTime = 0.01;
    const decayStart = 0.1;
    if (progress < attackTime) return progress / attackTime;
    if (progress < decayStart) return 1.0;
    return 1.0 - ((progress - decayStart) / (1.0 - decayStart));
  }

  double _adsrEnvelope(
    double progress,
    double attack,
    double decay,
    double sustain,
    double release,
  ) {
    if (progress <= 0) return 0.0;
    if (progress >= 1.0) return 0.0;
    if (attack <= 0) attack = 0.001;
    if (decay <= 0) decay = 0.001;
    if (release <= 0) release = 0.001;

    if (progress < attack) {
      return (progress / attack).clamp(0.0, 1.0);
    }

    if (progress < attack + decay) {
      final d = (progress - attack) / decay;
      return (1.0 - (1.0 - sustain) * d).clamp(0.0, 1.0);
    }

    if (progress < 1.0 - release) {
      return sustain.clamp(0.0, 1.0);
    }

    final r = (progress - (1.0 - release)) / release;
    return (sustain * (1.0 - r)).clamp(0.0, 1.0);
  }

  /// Reset all audio players between game sessions
  /// Stops all playing sounds without disposing players
  void reset() {
    for (final player in _playerPool) {
      player.stop();
    }
    _currentPlayerIndex = 0;
    _lastAnySfxPlayMicros = 0;
    _lastSfxPlayMicros.clear();
    _combatPatternCounts.clear();
    _activeSfxUntilMicros.clear();
    _combatHeavyLoad = false;
    _combatSevereLoad = false;
    _priorityDuckingUntilMicros = 0;
    _priorityCombatDuckScale = 1.0;
    _battleIntensity = 0.35;
    _bossActive = false;
    _comboLevel = 0;
    _epicBoostUntilMicros = 0;
    _epicBoostScale = 0.0;
    _epicStage = 0;
    _epicStageCueCooldownUntilMicros = 0;
    _lastPlayedKey = '';
    _lastResolvedKey = '';
    _lastAppliedPan = 0.0;
    _lastAppliedDistance = 0.0;
    _lastAppliedPlaybackRate = 1.0;
    _lastHeadroomScale = 1.0;
    _lastConcurrentVoices = 0;

    if (kDebugMode) {
      debugPrint('AudioService reset');
    }
  }

  /// Refresh player pool - dispose and recreate all players
  /// Call this every 5 levels to prevent resource accumulation
  Future<void> refresh() async {
    if (!_initialized) return;

    // Stop and dispose all existing players
    for (final player in _playerPool) {
      await player.stop();
      await player.dispose();
    }
    _playerPool.clear();

    // Recreate player pool
    for (int i = 0; i < _poolSize; i++) {
      _playerPool.add(AudioPlayer());
    }
    _currentPlayerIndex = 0;

    if (kDebugMode) {
      debugPrint('AudioService refreshed player pool');
    }
  }

  void dispose() {
    for (final player in _playerPool) {
      player.dispose();
    }
    _playerPool.clear();
    _sfxCache.clear();
    _sfxDurationMicros.clear();
    _lastSfxPlayMicros.clear();
    _combatPatternCounts.clear();
    _activeSfxUntilMicros.clear();
    _lastAnySfxPlayMicros = 0;
    _combatHeavyLoad = false;
    _combatSevereLoad = false;
    _priorityDuckingUntilMicros = 0;
    _priorityCombatDuckScale = 1.0;
    _battleIntensity = 0.35;
    _bossActive = false;
    _comboLevel = 0;
    _epicBoostUntilMicros = 0;
    _epicBoostScale = 0.0;
    _epicStage = 0;
    _epicStageCueCooldownUntilMicros = 0;
    _lastPlayedKey = '';
    _lastResolvedKey = '';
    _lastAppliedPan = 0.0;
    _lastAppliedDistance = 0.0;
    _lastAppliedPlaybackRate = 1.0;
    _lastHeadroomScale = 1.0;
    _lastConcurrentVoices = 0;
    _soundProfile = 'high';
    _initialized = false;

    if (kDebugMode) {
      debugPrint('AudioService disposed');
    }
  }

  /// Expose waveform generation for testing purposes only
  Float32List generateWaveformForTesting({
    required double frequency,
    required double duration,
    required WaveType type,
    double frequencySlide = 0,
    double volume = 0.8,
  }) {
    return _generateWaveform(
      frequency: frequency,
      duration: duration,
      type: type,
      frequencySlide: frequencySlide,
      volume: volume,
    );
  }

  @visibleForTesting
  int get debugShootIntervalMs => _effectiveCombatIntervalMs(22);

  @visibleForTesting
  int get debugHitIntervalMs => _effectiveCombatIntervalMs(18);

  @visibleForTesting
  double get debugCombatVolumeScale => _effectiveCombatVolumeScale();

  @visibleForTesting
  bool get debugPriorityDuckingActive => _priorityCombatScaleNow() < 1.0;

  @visibleForTesting
  double get debugBattleIntensity => _battleIntensity;

  @visibleForTesting
  double get debugEpicBoostScale => _epicBoostNow();

  @visibleForTesting
  int get debugEpicStage => _epicStage;

  @visibleForTesting
  bool get debugPrefersEpicCues => _preferEpicCues();

  @visibleForTesting
  String get debugLastPlayedKey => _lastPlayedKey;

  @visibleForTesting
  String get debugLastResolvedKey => _lastResolvedKey;

  @visibleForTesting
  double get debugLastAppliedPan => _lastAppliedPan;

  @visibleForTesting
  double get debugLastAppliedDistance => _lastAppliedDistance;

  @visibleForTesting
  double get debugLastAppliedPlaybackRate => _lastAppliedPlaybackRate;

  @visibleForTesting
  double get debugLastHeadroomScale => _lastHeadroomScale;

  @visibleForTesting
  int get debugConcurrentVoices => _lastConcurrentVoices;

  @visibleForTesting
  bool debugHasSfxKey(String key) => _sfxCache.containsKey(key);

  @visibleForTesting
  String debugTowerSfxTokenFor(TowerType type) => _towerSfxToken(type);

  @visibleForTesting
  String? debugComboMilestoneKeyFor(int combo) => _comboMilestoneKey(combo);
}

enum WaveType { sine, square, triangle, sawtooth, noise }
