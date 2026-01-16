import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flame_audio/flame_audio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../game/entities/tower.dart';

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
  final _random = math.Random();

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
      debugPrint('AudioService initialized (Pool size: $_poolSize, Cached sounds: ${_sfxCache.length})');
    }
  }

  Future<void> _cacheAllSounds() async {
    // Basic SFX
    _sfxCache['shoot_default'] = _generateSource(frequency: 880, duration: 0.05, type: WaveType.square, frequencySlide: 1200);
    _sfxCache['hit_default'] = _generateSource(frequency: 220, duration: 0.08, type: WaveType.noise, frequencySlide: -100);
    _sfxCache['explosion'] = _generateSource(frequency: 150, duration: 0.3, type: WaveType.noise, frequencySlide: -140);
    _sfxCache['build'] = _generateSource(frequency: 440, duration: 0.15, type: WaveType.triangle, frequencySlide: 220);
    _sfxCache['pulse'] = _generateSource(frequency: 200, duration: 0.4, type: WaveType.sine, frequencySlide: 600, volume: 0.7);
    _sfxCache['mine_deploy'] = _generateSource(frequency: 660, duration: 0.08, type: WaveType.square, frequencySlide: -200);
    _sfxCache['button'] = _generateSource(frequency: 1200, duration: 0.03, type: WaveType.square);
    _sfxCache['gold'] = _generateSource(frequency: 1318, duration: 0.05, type: WaveType.triangle);

    // Tower-specific shoot sounds
    _sfxCache['shoot_ionSniper'] = _generateSource(frequency: 440, duration: 0.4, type: WaveType.sine, frequencySlide: -200, volume: 1.0);
    _sfxCache['shoot_teslaTerminal'] = _generateSource(frequency: 1200, duration: 0.1, type: WaveType.square, frequencySlide: 400, volume: 0.6);
    _sfxCache['shoot_circuitCannon'] = _generateSource(frequency: 220, duration: 0.2, type: WaveType.sawtooth, frequencySlide: -100, volume: 0.9);
    _sfxCache['shoot_phaseMage'] = _generateSource(frequency: 880, duration: 0.15, type: WaveType.sine, frequencySlide: 300, volume: 0.7);

    // Tower-specific hit sounds
    _sfxCache['hit_ionSniper'] = _generateSource(frequency: 110, duration: 0.15, type: WaveType.noise, frequencySlide: -50, volume: 0.8);
    _sfxCache['hit_teslaTerminal'] = _generateSource(frequency: 1600, duration: 0.05, type: WaveType.square, frequencySlide: 800, volume: 0.5);
    _sfxCache['hit_circuitCannon'] = _generateSource(frequency: 100, duration: 0.25, type: WaveType.noise, frequencySlide: -80, volume: 1.0);
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
  void playCriticalHit() => _playCached('shoot_default', volumeMult: 1.2);

  /// Enemy or mine explosion - big boom
  void playExplosion() => _playCached('explosion');

  /// Tower placed - construction sound
  void playBuild() => _playCached('build');

  /// New wave starting - alert
  void playWaveStart() {
    if (!_canPlay) return;
    _playCached('button');
    Future.delayed(const Duration(milliseconds: 100), () => _playCached('button', volumeMult: 0.8));
  }

  /// Neon pulse activated - whoosh
  void playPulse() => _playCached('pulse');

  /// Mine deployed - beep
  void playMineDeploy() => _playCached('mine_deploy');

  /// Mine explodes - bigger explosion
  void playMineExplode() => _playCached('explosion', volumeMult: 1.2);

  /// UI button click
  void playButton() => _playCached('button');

  /// Enemy reaches base - warning
  void playEnemyLeak() {
    if (!_canPlay) return;
    _playCached('hit_default', volumeMult: 1.5);
  }

  /// Gold earned
  void playGoldEarned() => _playCached('gold');

  /// Phantom enemy revealed
  void playPhantomReveal() => _playCached('button', volumeMult: 1.2);

  /// Game Over - sad tone
  void playGameOver() {
    _playCached('hit_default', volumeMult: 1.5);
    Future.delayed(const Duration(milliseconds: 200), () => _playCached('hit_default', volumeMult: 1.2));
  }

  /// Victory - fanfare
  void playVictory() {
    _playCached('button', volumeMult: 1.0);
    Future.delayed(const Duration(milliseconds: 150), () => _playCached('button', volumeMult: 1.2));
    Future.delayed(const Duration(milliseconds: 300), () => _playCached('gold', volumeMult: 1.0));
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

  void dispose() {
    for (final player in _playerPool) {
      player.dispose();
    }
    _playerPool.clear();
    _initialized = false;
  }
}

enum WaveType { sine, square, triangle, sawtooth, noise }
