import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flame_audio/flame_audio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../game/entities/tower.dart';

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

/// Synthwave audio service with procedural sound generation
/// Generates 8-bit style sound effects for the neon aesthetic
class AudioService {
  AudioService._();
  static final instance = AudioService._();

  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;
  bool _enabled = true;
  bool _initialized = false;

  // Pool of audio players to reuse
  final List<AudioPlayer> _playerPool = [];
  static const int _poolSize = 12;
  int _currentPlayerIndex = 0;

  // SFX Cache
  final Map<String, BytesSource> _sfxCache = {};

  // Sound generation parameters
  static const int _sampleRate = 22050;
  final _random = _FastRng();

  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  bool get enabled => _enabled;

  /// Initialize audio system
  Future<void> initialize() async {
    if (_initialized) return;

    // Create player pool
    for (int i = 0; i < _poolSize; i++) {
      _playerPool.add(AudioPlayer());
    }

    // Pre-cache core sounds
    await _cacheAllSounds();

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

    // Tower-specific shoot sounds
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

    // Normalize and apply master volume
    var maxSample = 0.0;
    for (final value in data) {
      final absValue = value.abs();
      if (absValue > maxSample) maxSample = absValue;
    }
    final normalize = maxSample > 1.0 ? 1.0 / maxSample : 1.0;
    final master = masterVolume.clamp(0.0, 1.0) * normalize;
    for (int i = 0; i < data.length; i++) {
      data[i] = (data[i] * master).clamp(-1.0, 1.0);
    }

    return data;
  }

  /// Enable/disable all audio
  void setEnabled(bool value) {
    _enabled = value;
  }

  /// Set music volume (0.0 - 1.0)
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
  }

  /// Set SFX volume (0.0 - 1.0)
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  // ============ Sound Effect Methods ============

  bool get _canPlay => _enabled && _sfxVolume > 0 && _initialized;

  Future<void> _playCached(String key, {double volumeMult = 1.0}) async {
    if (!_canPlay) return;
    final source = _sfxCache[key] ?? _sfxCache['shoot_default'];
    if (source == null) return;

    final actualVolume = (_sfxVolume * volumeMult).clamp(0.0, 1.0);

    final player = _playerPool[_currentPlayerIndex];
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _poolSize;

    player.play(source, volume: actualVolume);
  }

  /// Tower shoots - quick zap sound
  void playShoot({TowerType? type}) {
    _playCached(type != null ? 'shoot_${type.name}' : 'shoot_default');
  }

  /// Bullet hits enemy - impact thud
  void playHit({TowerType? type}) {
    _playCached(type != null ? 'hit_${type.name}' : 'hit_default');
  }

  /// Critical hit - sharp confirm tone
  void playCriticalHit() => _playCached('critical', volumeMult: 1.1);

  /// Enemy or mine explosion - big boom
  void playExplosion() => _playCached('explosion');

  /// Tower placed - construction sound
  void playBuild() => _playCached('build');

  /// New wave starting - alert
  void playWaveStart() => _playCached('wave_start');

  /// Wave complete - triumphant cadence
  void playWaveComplete() => _playCached('wave_complete');

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
  void playVictory() => _playCached('victory');

  /// Boss spawn - heavy alert
  void playBossSpawn() => _playCached('boss_spawn');

  /// Boss phase shift - stinger
  void playBossPhase() => _playCached('boss_phase');

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
}

enum WaveType { sine, square, triangle, sawtooth, noise }
