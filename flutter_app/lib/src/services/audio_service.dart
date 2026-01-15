import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Synthwave audio service with procedural sound generation
/// Generates 8-bit style sound effects for the neon aesthetic
class AudioService {
  AudioService._();
  static final instance = AudioService._();

  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;
  bool _enabled = true;
  bool _initialized = false;

  // Sound generation parameters
  static const int _sampleRate = 22050;
  final _random = math.Random();

  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  bool get enabled => _enabled;

  /// Initialize audio system
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (kDebugMode) {
      debugPrint('AudioService initialized (procedural synth mode)');
    }
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

  /// Tower shoots - quick zap sound
  void playShoot() {
    if (!_canPlay) return;
    _playTone(
      frequency: 880,
      duration: 0.05,
      type: WaveType.square,
      frequencySlide: 1200,
    );
  }

  /// Bullet hits enemy - impact thud
  void playHit() {
    if (!_canPlay) return;
    _playTone(
      frequency: 220,
      duration: 0.08,
      type: WaveType.noise,
      frequencySlide: -100,
    );
  }

  /// Critical hit - sharp confirm tone
  void playCriticalHit() {
    if (!_canPlay) return;
    _playTone(
      frequency: 1600,
      duration: 0.06,
      type: WaveType.square,
      frequencySlide: -300,
      volume: 0.9,
    );
  }

  /// Enemy or mine explosion - big boom
  void playExplosion() {
    if (!_canPlay) return;
    _playTone(
      frequency: 150,
      duration: 0.3,
      type: WaveType.noise,
      frequencySlide: -140,
      volume: 0.9,
    );
  }

  /// Tower placed - construction sound
  void playBuild() {
    if (!_canPlay) return;
    _playTone(
      frequency: 440,
      duration: 0.15,
      type: WaveType.triangle,
      frequencySlide: 220,
    );
  }

  /// New wave starting - alert
  void playWaveStart() {
    if (!_canPlay) return;
    // Two-tone alert
    _playTone(frequency: 523, duration: 0.1, type: WaveType.square);
    Future.delayed(const Duration(milliseconds: 120), () {
      _playTone(frequency: 659, duration: 0.15, type: WaveType.square);
    });
  }

  /// Neon pulse activated - whoosh
  void playPulse() {
    if (!_canPlay) return;
    _playTone(
      frequency: 200,
      duration: 0.4,
      type: WaveType.sine,
      frequencySlide: 600,
      volume: 0.7,
    );
  }

  /// Mine deployed - beep
  void playMineDeploy() {
    if (!_canPlay) return;
    _playTone(
      frequency: 660,
      duration: 0.08,
      type: WaveType.square,
      frequencySlide: -200,
    );
  }

  /// Mine explodes - bigger explosion
  void playMineExplode() {
    if (!_canPlay) return;
    _playTone(
      frequency: 180,
      duration: 0.35,
      type: WaveType.noise,
      frequencySlide: -160,
      volume: 1.0,
    );
  }

  /// Victory fanfare
  void playVictory() {
    if (!_canPlay) return;
    // Ascending arpeggio
    const notes = [523.0, 659.0, 784.0, 1047.0];
    for (int i = 0; i < notes.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        _playTone(
          frequency: notes[i],
          duration: 0.2,
          type: WaveType.triangle,
        );
      });
    }
  }

  /// Game over sound
  void playGameOver() {
    if (!_canPlay) return;
    // Descending tones
    const notes = [392.0, 330.0, 262.0, 196.0];
    for (int i = 0; i < notes.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        _playTone(
          frequency: notes[i],
          duration: 0.25,
          type: WaveType.square,
        );
      });
    }
  }

  /// UI button click
  void playButton() {
    if (!_canPlay) return;
    _playTone(
      frequency: 1200,
      duration: 0.03,
      type: WaveType.square,
    );
  }

  /// Enemy reaches base - warning
  void playEnemyLeak() {
    if (!_canPlay) return;
    _playTone(
      frequency: 200,
      duration: 0.2,
      type: WaveType.square,
      frequencySlide: -100,
    );
  }

  /// Phantom revealed
  void playPhantomReveal() {
    if (!_canPlay) return;
    _playTone(
      frequency: 880,
      duration: 0.15,
      type: WaveType.sine,
      frequencySlide: -440,
    );
  }

  /// Gold earned
  void playGoldEarned() {
    if (!_canPlay) return;
    _playTone(
      frequency: 1318,
      duration: 0.05,
      type: WaveType.triangle,
    );
  }

  // ============ Internal Methods ============

  bool get _canPlay => _enabled && _sfxVolume > 0 && _initialized;

  /// Generate and play a procedural tone
  Future<void> _playTone({
    required double frequency,
    required double duration,
    required WaveType type,
    double frequencySlide = 0,
    double volume = 0.8,
  }) async {
    final actualVolume = volume * _sfxVolume;
    if (actualVolume <= 0) return;

    // Generate waveform data
    final pcmFloat32 = _generateWaveform(
      frequency: frequency,
      duration: duration,
      type: type,
      frequencySlide: frequencySlide,
      volume: actualVolume,
    );

    // Convert to 16-bit PCM
    final pcm16 = Int16List(pcmFloat32.length);
    for (var i = 0; i < pcmFloat32.length; i++) {
      final sample = (pcmFloat32[i] * 32767.0).clamp(-32768.0, 32767.0);
      pcm16[i] = sample.toInt();
    }
    final pcmBytes = pcm16.buffer.asUint8List();

    // Add WAV header and play
    final wavBytes = _addWavHeader(pcmBytes);
    await FlameAudio.playBytes(wavBytes, volume: actualVolume);

    if (kDebugMode) {
      debugPrint(
          '🔊 ${type.name}: ${frequency.toInt()}Hz, ${(duration * 1000).toInt()}ms, vol:${actualVolume.toStringAsFixed(2)}');
    }
  }

  /// Create a WAV file header for the given PCM data
  Uint8List _addWavHeader(Uint8List pcmBytes) {
    final int pcmLength = pcmBytes.length;
    final int totalLength = pcmLength + 36;
    const int sampleRate = _sampleRate;
    const int numChannels = 1;
    const int bitsPerSample = 16;
    final int byteRate = (sampleRate * numChannels * bitsPerSample) ~/ 8;
    final int blockAlign = (numChannels * bitsPerSample) ~/ 8;

    final header = ByteData(44);
    // RIFF header
    header.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    header.setUint32(4, totalLength, Endian.little);
    header.setUint32(8, 0x57415645, Endian.big); // "WAVE"

    // fmt sub-chunk
    header.setUint32(12, 0x666d7420, Endian.big); // "fmt "
    header.setUint32(16, 16, Endian.little); // Sub-chunk size for PCM
    header.setUint16(20, 1, Endian.little); // Audio format (1 = PCM)
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);

    // data sub-chunk
    header.setUint32(36, 0x64617461, Endian.big); // "data"
    header.setUint32(40, pcmLength, Endian.little);

    return Uint8List.fromList(header.buffer.asUint8List().toList() + pcmBytes.toList());
  }


  /// Generate PCM waveform data
  @visibleForTesting
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

  /// Generate PCM waveform data
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

      // Frequency with optional slide
      final freq = frequency + (frequencySlide * progress);

      // Generate sample based on wave type
      double sample;
      switch (type) {
        case WaveType.sine:
          sample = _sineSample(freq, t);
          break;
        case WaveType.square:
          sample = math.sin(2 * math.pi * freq * t) > 0 ? 1.0 : -1.0;
          break;
        case WaveType.triangle:
          sample = _triangleSample(freq, t);
          break;
        case WaveType.sawtooth:
          sample = _sawtoothSample(freq, t);
          break;
        case WaveType.noise:
          sample = _random.nextDouble() * 2.0 - 1.0;
          // Apply low-pass filter for explosion-like noise
          if (i > 0) {
            sample = data[i - 1] * 0.7 + sample * 0.3;
          }
          break;
      }

      // Apply envelope (attack-decay)
      final envelope = _calculateEnvelope(progress);

      data[i] = (sample * volume * envelope).clamp(-1.0, 1.0);
    }

    return data;
  }

  double _sineSample(double freq, double t) {
    return math.sin(2 * math.pi * freq * t);
  }

  double _triangleSample(double freq, double t) {
    final phase = (freq * t) % 1.0;
    return 4.0 * (phase < 0.5 ? phase : 1.0 - phase) - 1.0;
  }

  double _sawtoothSample(double freq, double t) {
    return 2.0 * ((freq * t) % 1.0) - 1.0;
  }

  /// Calculate ADSR-like envelope
  double _calculateEnvelope(double progress) {
    const attackTime = 0.01;
    const decayStart = 0.1;

    if (progress < attackTime) {
      // Attack
      return progress / attackTime;
    } else if (progress < decayStart) {
      // Sustain
      return 1.0;
    } else {
      // Decay
      return 1.0 - ((progress - decayStart) / (1.0 - decayStart));
    }
  }

  /// Clean up resources
  void dispose() {
    _initialized = false;
  }
}

/// Wave types for procedural audio
enum WaveType {
  sine,
  square,
  triangle,
  sawtooth,
  noise,
}
