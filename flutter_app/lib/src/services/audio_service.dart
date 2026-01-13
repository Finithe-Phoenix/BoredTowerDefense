import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

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
  /// Note: In a real implementation, this would use audioplayers or just_audio
  /// For now, this logs the sound for debugging and can be expanded later
  void _playTone({
    required double frequency,
    required double duration,
    required WaveType type,
    double frequencySlide = 0,
    double volume = 0.8,
  }) {
    // In web/mobile, we'd generate actual PCM data and play it
    // For this implementation, we'll use a visual feedback system
    // that can be replaced with actual audio later

    final actualVolume = volume * _sfxVolume;

    // Debug logging (can be disabled in production)
    if (kDebugMode) {
      debugPrint('🔊 ${type.name}: ${frequency.toInt()}Hz, ${(duration * 1000).toInt()}ms, vol:${actualVolume.toStringAsFixed(2)}');
    }

    // Generate waveform data (for future audio implementation)
    _generateWaveform(
      frequency: frequency,
      duration: duration,
      type: type,
      frequencySlide: frequencySlide,
      volume: actualVolume,
    );
  }

  /// Generate PCM waveform data
  /// This can be used with audioplayers or platform channels for actual playback
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
  /// This can be used with audioplayers or platform channels for actual playback
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
