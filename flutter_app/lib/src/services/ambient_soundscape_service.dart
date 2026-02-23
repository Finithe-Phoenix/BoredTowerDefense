import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

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

enum AmbientLayerType {
  drone,
  texture,
  atmosphere,
  accent,
}

/// Ambient Soundscape Generator
/// Creates unique, immersive ambient audio for each game world.
///
/// Each world has its own sonic identity:
/// - World 1: NEON FRONTIER - Clean digital meditation
/// - World 2: RIFT WARS - Temporal echoes and dimensional ripples
/// - World 3: SIGNAL WASTES - Desolate silence and lost transmissions
/// - World 4: ION CROWN - Electric storm atmosphere
/// - World 5: SHARD VAULT - Memory whispers and ghostly echoes
/// - World 6: FINAL GATE - Transcendent void and cosmic harmonics
class AmbientSoundscapeService {
  AmbientSoundscapeService._();
  static final instance = AmbientSoundscapeService._();

  // Audio configuration
  static const int _sampleRate = 44100;
  static const int _bitsPerSample = 16;
  static const int _numChannels = 2;

  // State
  bool _initialized = false;
  bool _isPlaying = false;
  double _volume = 0.65; // Ambient volume increased for better atmosphere
  double _intensity = 0.5; // 0.0 = calm, 1.0 = intense
  int _currentWorld = 0;

  // Multiple layers for rich ambient sound
  AudioPlayer? _dronePlayer;
  AudioPlayer? _texturePlayer;
  AudioPlayer? _atmospherePlayer;
  AudioPlayer? _accentPlayer;

  Directory? _tempDir;
  final _random = _FastRng(42); // Seeded for consistent generation

  bool get isPlaying => _isPlaying;
  double get volume => _volume;
  double get intensity => _intensity;
  int get currentWorld => _currentWorld;

  /// Initialize the ambient soundscape service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _tempDir = await getTemporaryDirectory();
      _tempDir = Directory('${_tempDir!.path}/neon_ambient');
      if (!await _tempDir!.exists()) {
        await _tempDir!.create(recursive: true);
      }

      _dronePlayer = AudioPlayer();
      _texturePlayer = AudioPlayer();
      _atmospherePlayer = AudioPlayer();
      _accentPlayer = AudioPlayer();

      await _dronePlayer?.setReleaseMode(ReleaseMode.loop);
      await _texturePlayer?.setReleaseMode(ReleaseMode.loop);
      await _atmospherePlayer?.setReleaseMode(ReleaseMode.loop);
      await _accentPlayer?.setReleaseMode(ReleaseMode.loop);

      _initialized = true;

      if (kDebugMode) {
        debugPrint('AmbientSoundscapeService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AmbientSoundscapeService initialization error: $e');
      }
    }
  }

  /// Set the master volume for ambient sounds
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _updateVolumes();
  }

  /// Set ambient intensity (0.0 = calm, 1.0 = intense)
  void setIntensity(double intensity) {
    _intensity = intensity.clamp(0.0, 1.0);
    unawaited(_updateVolumes());
  }

  Future<void> _updateVolumes() async {
    final intensity = _intensity.clamp(0.0, 1.0);

    final droneMultiplier = (0.8 - 0.2 * intensity).clamp(0.0, 1.0);
    final textureMultiplier = (0.45 + 0.1 * intensity).clamp(0.0, 1.0);
    final atmosphereMultiplier = (0.5 + 0.2 * intensity).clamp(0.0, 1.0);
    final accentMultiplier = (0.25 + 0.3 * intensity).clamp(0.0, 1.0);

    await _dronePlayer?.setVolume(_volume * droneMultiplier);
    await _texturePlayer?.setVolume(_volume * textureMultiplier);
    await _atmospherePlayer?.setVolume(_volume * atmosphereMultiplier);
    await _accentPlayer?.setVolume(_volume * accentMultiplier);
  }

  /// Play ambient soundscape for a specific world
  Future<void> playWorldAmbient(
    int worldId, {
    double? debugDurationSeconds,
  }) async {
    if (!_initialized) await initialize();

    // Don't restart if already playing this world
    if (_isPlaying && _currentWorld == worldId) return;

    await stop();
    _currentWorld = worldId;

    try {
      // Generate all ambient layers for this world
      final drone = _generateDroneLayer(
        worldId,
        durationSeconds: debugDurationSeconds ?? 30.0,
      );
      final texture = _generateTextureLayer(
        worldId,
        durationSeconds: debugDurationSeconds ?? 45.0,
      );
      final atmosphere = _generateAtmosphereLayer(
        worldId,
        durationSeconds: debugDurationSeconds ?? 60.0,
      );
      final accent = _generateAccentLayer(
        worldId,
        durationSeconds: debugDurationSeconds ?? 90.0,
      );

      // Save to temp files
      if (_tempDir != null) {
        final droneFile = File('${_tempDir!.path}/drone_$worldId.wav');
        final textureFile = File('${_tempDir!.path}/texture_$worldId.wav');
        final atmosphereFile =
            File('${_tempDir!.path}/atmosphere_$worldId.wav');
        final accentFile = File('${_tempDir!.path}/accent_$worldId.wav');

        await droneFile.writeAsBytes(drone);
        await textureFile.writeAsBytes(texture);
        await atmosphereFile.writeAsBytes(atmosphere);
        await accentFile.writeAsBytes(accent);

        // Start all layers
        await _dronePlayer?.play(DeviceFileSource(droneFile.path));
        await _texturePlayer?.play(DeviceFileSource(textureFile.path));
        await _atmospherePlayer?.play(DeviceFileSource(atmosphereFile.path));
        await _accentPlayer?.play(DeviceFileSource(accentFile.path));

        await _updateVolumes();
        _isPlaying = true;

        if (kDebugMode) {
          debugPrint(
              'Playing ambient soundscape for World $worldId: ${_getWorldName(worldId)}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error playing ambient: $e');
      }
    }
  }

  String _getWorldName(int worldId) {
    switch (worldId) {
      case 1:
        return 'NEON FRONTIER';
      case 2:
        return 'RIFT WARS';
      case 3:
        return 'SIGNAL WASTES';
      case 4:
        return 'ION CROWN';
      case 5:
        return 'SHARD VAULT';
      case 6:
        return 'FINAL GATE';
      case 7:
        return 'CORE HUNT';
      case 8:
        return 'OMEGA GRID';
      case 9:
        return 'STORM TOWER';
      case 10:
        return 'THE END';
      default:
        return 'UNKNOWN';
    }
  }

  /// Stop all ambient sounds
  Future<void> stop() async {
    _isPlaying = false;
    await _dronePlayer?.stop();
    await _texturePlayer?.stop();
    await _atmospherePlayer?.stop();
    await _accentPlayer?.stop();
  }

  /// Pause all ambient sounds
  Future<void> pause() async {
    await _dronePlayer?.pause();
    await _texturePlayer?.pause();
    await _atmospherePlayer?.pause();
    await _accentPlayer?.pause();
  }

  /// Resume all ambient sounds
  Future<void> resume() async {
    if (_isPlaying) {
      await _dronePlayer?.resume();
      await _texturePlayer?.resume();
      await _atmospherePlayer?.resume();
      await _accentPlayer?.resume();
    }
  }

  /// Fade out ambient sounds
  Future<void> fadeOut({Duration duration = const Duration(seconds: 2)}) async {
    if (!_isPlaying) return;

    final steps = 30;
    final stepDuration = duration.inMilliseconds ~/ steps;
    final initialVolume = _volume;

    for (int i = steps; i >= 0; i--) {
      if (!_isPlaying) break;
      final fadeVolume = initialVolume * i / steps;
      _volume = fadeVolume;
      await _updateVolumes();
      await Future.delayed(Duration(milliseconds: stepDuration));
    }

    await stop();
    _volume = initialVolume;
  }

  /// Generate a specific ambient layer with a short duration for fast tests.
  @visibleForTesting
  Uint8List generateLayerForTesting({
    required int worldId,
    required AmbientLayerType layer,
    double durationSeconds = 0.02,
  }) {
    final safeDuration = durationSeconds.clamp(0.005, 1.0).toDouble();
    switch (layer) {
      case AmbientLayerType.drone:
        return _generateDroneLayer(
          worldId,
          durationSeconds: safeDuration,
        );
      case AmbientLayerType.texture:
        return _generateTextureLayer(
          worldId,
          durationSeconds: safeDuration,
        );
      case AmbientLayerType.atmosphere:
        return _generateAtmosphereLayer(
          worldId,
          durationSeconds: safeDuration,
        );
      case AmbientLayerType.accent:
        return _generateAccentLayer(
          worldId,
          durationSeconds: safeDuration,
        );
    }
  }

  // ============================================================
  // WORLD 1: NEON FRONTIER - Clean Digital Meditation
  // A pristine digital dawn, pure frequencies, crystalline clarity
  // ============================================================

  Uint8List _generateWorld1Drone(
      int samples, Float32List left, Float32List right) {
    // Pure, clean foundation drone - A2 (110 Hz) with gentle harmonics
    const baseFreq = 110.0;

    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;
      final progress = i / samples;

      // Ultra-slow evolving LFO for organic movement
      final lfo1 = math.sin(2 * math.pi * 0.02 * t) * 0.5 + 0.5;
      final lfo2 = math.sin(2 * math.pi * 0.013 * t + 1.2) * 0.5 + 0.5;
      final lfo3 = math.sin(2 * math.pi * 0.007 * t + 2.4) * 0.5 + 0.5;

      // Clean sine foundation
      final fundamental = math.sin(2 * math.pi * baseFreq * t) * 0.4;

      // Gentle fifth (perfect harmony)
      final fifth = math.sin(2 * math.pi * baseFreq * 1.5 * t) * 0.15 * lfo1;

      // Crystalline octave shimmer
      final octave = math.sin(2 * math.pi * baseFreq * 2 * t) * 0.08 * lfo2;

      // High harmonic sparkle
      final sparkle = math.sin(2 * math.pi * baseFreq * 4 * t) * 0.03 * lfo3;

      // Breathing sub-bass
      final subBreath = math.sin(2 * math.pi * 0.1 * t);
      final sub =
          math.sin(2 * math.pi * 55 * t) * 0.25 * (0.7 + subBreath * 0.3);

      final sample = (fundamental + fifth + octave + sparkle + sub) * 0.5;

      // Gentle stereo width
      final pan = math.sin(2 * math.pi * 0.03 * t) * 0.15;
      left[i] += sample * (0.5 - pan);
      right[i] += sample * (0.5 + pan);
    }

    return Uint8List(0); // Will be processed later
  }

  Uint8List _generateWorld1Texture(
      int samples, Float32List left, Float32List right) {
    // Digital wind - filtered noise with resonance
    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Slowly evolving filter frequency
      final filterLfo = math.sin(2 * math.pi * 0.015 * t) * 0.5 + 0.5;
      final filterFreq = 200 + filterLfo * 800;

      // Generate pink-ish noise
      final noise = _pinkNoise() * 0.15;

      // Simple lowpass approximation
      final filtered = noise * (1.0 / (1.0 + (1000 / filterFreq)));

      // Stereo movement
      final pan = math.sin(2 * math.pi * 0.008 * t + 0.5) * 0.4;
      left[i] += filtered * (0.5 - pan);
      right[i] += filtered * (0.5 + pan);
    }

    return Uint8List(0);
  }

  // ============================================================
  // WORLD 2: RIFT WARS - Temporal Echoes
  // Time fractures, dimensional ripples, echoing distortions
  // ============================================================

  Uint8List _generateWorld2Drone(
      int samples, Float32List left, Float32List right) {
    // Unstable, warping drone - D2 with pitch drift
    const baseFreq = 73.42; // D2

    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Time distortion - irregular pitch warping
      final warp1 = math.sin(2 * math.pi * 0.07 * t) * 3;
      final warp2 = math.sin(2 * math.pi * 0.11 * t + 0.7) * 2;
      final warp3 = math.sin(2 * math.pi * 0.03 * t + 1.4) * 5;
      final freqMod = baseFreq + warp1 + warp2 + warp3;

      // Phasing drone layers
      double sample = 0;
      for (int voice = 0; voice < 5; voice++) {
        final phaseOffset = voice * 0.2;
        final detune = (voice - 2) * 0.5;
        final voiceFreq = freqMod + detune;

        // Detuned triangle waves for warmer tone
        final phase = (voiceFreq * t + phaseOffset) % 1.0;
        final triangle = 4.0 * (phase < 0.5 ? phase : 1.0 - phase) - 1.0;
        sample += triangle / 5.0;
      }

      sample *= 0.35;

      // Temporal echo effect - delays
      final echo1 = i > 22050 ? left[i - 22050] * 0.3 : 0.0;
      final echo2 = i > 44100 ? right[i - 44100] * 0.2 : 0.0;

      // Stereo rifts
      final riftPan = math.sin(2 * math.pi * 0.05 * t) * 0.5;
      left[i] += sample * (0.5 - riftPan) + echo1;
      right[i] += sample * (0.5 + riftPan) + echo2;
    }

    return Uint8List(0);
  }

  Uint8List _generateWorld2Texture(
      int samples, Float32List left, Float32List right) {
    // Dimensional ripples - granular-like texture
    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Multiple ripple frequencies
      final ripple1 =
          math.sin(2 * math.pi * 1.3 * t) * math.sin(2 * math.pi * 0.02 * t);
      final ripple2 = math.sin(2 * math.pi * 2.1 * t + 0.5) *
          math.sin(2 * math.pi * 0.017 * t);
      final ripple3 = math.sin(2 * math.pi * 0.7 * t + 1.0) *
          math.sin(2 * math.pi * 0.025 * t);

      // High-frequency shimmer
      final shimmer = math.sin(2 * math.pi * 3000 * t) * 0.02 * ripple1.abs();

      final sample =
          (ripple1 * 0.1 + ripple2 * 0.08 + ripple3 * 0.06 + shimmer);

      // Phase-shifted stereo
      left[i] += sample;
      right[i] += sample * math.cos(2 * math.pi * 0.01 * t);
    }

    return Uint8List(0);
  }

  // ============================================================
  // WORLD 3: SIGNAL WASTES - Desolate Silence
  // Abandoned frequencies, static ruins, lost transmissions
  // ============================================================

  Uint8List _generateWorld3Drone(
      int samples, Float32List left, Float32List right) {
    // Sparse, lonely drone - F2 with decay
    const baseFreq = 87.31; // F2

    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Very slow, mournful LFO
      final lfo = math.sin(2 * math.pi * 0.008 * t) * 0.5 + 0.5;

      // Hollow sine with slight detuning for loneliness
      final fundamental = math.sin(2 * math.pi * baseFreq * t);
      final detunedFund = math.sin(2 * math.pi * (baseFreq * 1.002) * t);

      // Distant, decaying harmonics
      final harm3 = math.sin(2 * math.pi * baseFreq * 3 * t) * 0.05 * lfo;

      // Signal decay envelope - occasional dropouts
      final dropout = math.sin(2 * math.pi * 0.03 * t);
      final signalStrength = dropout > 0.7 ? 0.3 : 1.0;

      final sample =
          ((fundamental + detunedFund) * 0.5 * 0.25 + harm3) * signalStrength;

      // Desolate stereo - wide and empty
      final pan = math.sin(2 * math.pi * 0.005 * t) * 0.6;
      left[i] += sample * (0.5 - pan);
      right[i] += sample * (0.5 + pan);
    }

    return Uint8List(0);
  }

  Uint8List _generateWorld3Texture(
      int samples, Float32List left, Float32List right) {
    // Static and lost radio signals
    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Static bursts
      final staticLfo = math.sin(2 * math.pi * 0.04 * t);
      final staticAmt = staticLfo > 0.6 ? (staticLfo - 0.6) / 0.4 : 0.0;
      final staticNoise = _random.nextDouble() * 2 - 1;
      final staticSample = staticNoise * staticAmt * 0.08;

      // Distant signal blips (very occasional)
      final blipLfo = math.sin(2 * math.pi * 0.007 * t);
      final blip = blipLfo > 0.95
          ? math.sin(2 * math.pi * 1200 * t) * 0.03 * (blipLfo - 0.95) / 0.05
          : 0.0;

      // Wind through ruins
      final windLfo = math.sin(2 * math.pi * 0.012 * t) * 0.5 + 0.5;
      final wind = _pinkNoise() * 0.04 * windLfo;

      final sample = staticSample + blip + wind;

      // Scattered stereo
      left[i] += sample * (1.0 + math.sin(t * 0.1) * 0.3);
      right[i] += sample * (1.0 - math.sin(t * 0.1) * 0.3);
    }

    return Uint8List(0);
  }

  // ============================================================
  // WORLD 4: ION CROWN - Electric Storm Atmosphere
  // Charged air, thunder resonance, power grid tension
  // ============================================================

  Uint8List _generateWorld4Drone(
      int samples, Float32List left, Float32List right) {
    // Powerful, electric drone - G2 with harmonics
    const baseFreq = 98.0; // G2

    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Electric tension LFO
      final tensionLfo = math.sin(2 * math.pi * 0.025 * t) * 0.5 + 0.5;
      final surgeLfo = math.sin(2 * math.pi * 0.08 * t);

      // Power grid hum (60Hz undertone)
      final gridHum = math.sin(2 * math.pi * 60 * t) * 0.1;

      // Main drone with electric character
      final fundamental = math.sin(2 * math.pi * baseFreq * t);

      // Sawtooth harmonics for aggressive edge
      final saw = 2.0 * ((baseFreq * t) % 1.0) - 1.0;

      // Power surge harmonics
      final surge = math.sin(2 * math.pi * baseFreq * 2 * t) * surgeLfo * 0.15;

      final sample =
          (fundamental * 0.3 + saw * 0.15 * tensionLfo + surge + gridHum) * 0.4;

      // Electric stereo crackle
      final pan = math.sin(2 * math.pi * 0.04 * t) * 0.3;
      left[i] += sample * (0.5 - pan);
      right[i] += sample * (0.5 + pan);
    }

    return Uint8List(0);
  }

  Uint8List _generateWorld4Texture(
      int samples, Float32List left, Float32List right) {
    // Thunder rumbles and electric crackles
    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Distant thunder rumble
      final thunderLfo = math.sin(2 * math.pi * 0.02 * t);
      final thunderAmt = thunderLfo > 0.7 ? (thunderLfo - 0.7) / 0.3 : 0.0;
      final thunder = _pinkNoise() * thunderAmt * 0.2;

      // Low thunder resonance
      final thunderRes = math.sin(2 * math.pi * 40 * t) * thunderAmt * 0.15;

      // Electric crackles
      final crackleChance = _random.nextDouble();
      final crackle =
          crackleChance > 0.998 ? (_random.nextDouble() * 2 - 1) * 0.3 : 0.0;

      // Charged air hiss
      final chargedAir =
          _pinkNoise() * 0.02 * (0.5 + math.sin(2 * math.pi * 0.015 * t) * 0.3);

      final sample = thunder + thunderRes + crackle + chargedAir;

      // Storm stereo movement
      final stormPan = math.sin(2 * math.pi * 0.03 * t) * 0.5;
      left[i] += sample * (0.5 - stormPan);
      right[i] += sample * (0.5 + stormPan);
    }

    return Uint8List(0);
  }

  // ============================================================
  // WORLD 5: SHARD VAULT - Memory Whispers
  // Ghostly echoes, melancholic drones, crystalline memories
  // ============================================================

  Uint8List _generateWorld5Drone(
      int samples, Float32List left, Float32List right) {
    // Melancholic, haunting drone - A1 minor with tears
    const baseFreq = 55.0; // A1

    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Slow, sorrowful breathing
      final breathLfo = math.sin(2 * math.pi * 0.04 * t) * 0.5 + 0.5;
      final tearLfo = math.sin(2 * math.pi * 0.007 * t);

      // Deep, resonant fundamental
      final fundamental = math.sin(2 * math.pi * baseFreq * t) * 0.35;

      // Minor third - the color of sadness (C)
      final minorThird =
          math.sin(2 * math.pi * baseFreq * 1.2 * t) * 0.12 * breathLfo;

      // Fifth for hollow resonance
      final fifth =
          math.sin(2 * math.pi * baseFreq * 1.5 * t) * 0.1 * tearLfo.abs();

      // High harmonic tears - crystalline memory shards
      final tears = math.sin(2 * math.pi * baseFreq * 6 * t) *
          0.02 *
          (tearLfo > 0.5 ? 1.0 : 0.0);

      // Heartbeat-like pulse
      final heartbeatPhase = (t * 0.8) % 1.0;
      final heartbeat = heartbeatPhase < 0.1
          ? math.sin(2 * math.pi * 30 * t) * (0.1 - heartbeatPhase) * 2
          : 0.0;

      final sample =
          (fundamental + minorThird + fifth + tears + heartbeat) * 0.5;

      // Ghostly stereo width
      final ghostPan = math.sin(2 * math.pi * 0.02 * t) * 0.4;
      left[i] += sample * (0.5 - ghostPan);
      right[i] += sample * (0.5 + ghostPan);
    }

    return Uint8List(0);
  }

  Uint8List _generateWorld5Texture(
      int samples, Float32List left, Float32List right) {
    // Whispers and memory fragments
    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Ghostly whisper texture
      final whisperLfo = math.sin(2 * math.pi * 0.03 * t) * 0.5 + 0.5;
      final whisperNoise = _pinkNoise() * 0.03 * whisperLfo;

      // Memory fragment tones (occasional high bells)
      final fragmentLfo = math.sin(2 * math.pi * 0.01 * t);
      final fragment = fragmentLfo > 0.9
          ? math.sin(2 * math.pi * 2000 * t) *
              0.02 *
              math.exp(-((fragmentLfo - 0.9) * 20))
          : 0.0;

      // Distant, ethereal choir-like pad
      double choir = 0;
      final choirFreqs = [220.0, 277.18, 329.63]; // A minor triad
      for (final freq in choirFreqs) {
        final vibrato = math.sin(2 * math.pi * 4 * t + freq * 0.01) * 2;
        choir += math.sin(2 * math.pi * (freq + vibrato) * t) * 0.015;
      }
      choir *= (0.3 + math.sin(2 * math.pi * 0.008 * t) * 0.2);

      final sample = whisperNoise + fragment + choir;

      // Ethereal stereo
      left[i] += sample * (0.6 + math.sin(t * 0.05) * 0.2);
      right[i] += sample * (0.6 - math.sin(t * 0.05) * 0.2);
    }

    return Uint8List(0);
  }

  // ============================================================
  // WORLD 6: FINAL GATE - Transcendent Void
  // Cosmic harmonics, infinite space, pure transcendence
  // ============================================================

  Uint8List _generateWorld6Drone(
      int samples, Float32List left, Float32List right) {
    // Transcendent, cosmic drone - perfect intervals, pure tones
    const baseFreq = 65.41; // C2 - the universal root

    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Cosmic breathing - very slow, infinite feel
      final cosmicBreath = math.sin(2 * math.pi * 0.005 * t) * 0.5 + 0.5;
      final infinityLfo = math.sin(2 * math.pi * 0.002 * t);

      // Pure fundamental - the source
      final fundamental = math.sin(2 * math.pi * baseFreq * t) * 0.25;

      // Perfect octave - unity
      final octave =
          math.sin(2 * math.pi * baseFreq * 2 * t) * 0.15 * cosmicBreath;

      // Perfect fifth - cosmic harmony
      final fifth = math.sin(2 * math.pi * baseFreq * 1.5 * t) * 0.12;

      // High celestial harmonics - approaching infinity
      final celestial1 = math.sin(2 * math.pi * baseFreq * 4 * t) *
          0.05 *
          (infinityLfo * 0.5 + 0.5);
      final celestial2 = math.sin(2 * math.pi * baseFreq * 6 * t) * 0.03;
      final celestial3 =
          math.sin(2 * math.pi * baseFreq * 8 * t) * 0.02 * cosmicBreath;

      // Sub-bass - the void beneath
      final voidBass = math.sin(2 * math.pi * 32.7 * t) * 0.2;

      final sample = (fundamental +
              octave +
              fifth +
              celestial1 +
              celestial2 +
              celestial3 +
              voidBass) *
          0.5;

      // Infinite stereo space
      final cosmicPan = math.sin(2 * math.pi * 0.01 * t) * 0.25;
      left[i] += sample * (0.5 - cosmicPan);
      right[i] += sample * (0.5 + cosmicPan);
    }

    return Uint8List(0);
  }

  Uint8List _generateWorld6Texture(
      int samples, Float32List left, Float32List right) {
    // Cosmic wind and celestial choir
    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Cosmic wind - filtered white noise
      final windLfo = math.sin(2 * math.pi * 0.006 * t) * 0.5 + 0.5;
      final cosmicWind = _pinkNoise() * 0.02 * windLfo;

      // Celestial choir - major triad with shimmer
      double choir = 0;
      final choirNotes = [261.63, 329.63, 392.0, 523.25]; // C major with octave
      for (int v = 0; v < choirNotes.length; v++) {
        final freq = choirNotes[v];
        final vibrato = math.sin(2 * math.pi * 3 * t + v * 0.5) * 1.5;
        final shimmer = math.sin(2 * math.pi * 0.1 * t + v * 0.25) * 0.5 + 0.5;
        choir += math.sin(2 * math.pi * (freq + vibrato) * t) * 0.02 * shimmer;
      }

      // Stellar sparkles
      final sparkleChance = _random.nextDouble();
      final sparkle = sparkleChance > 0.9995
          ? math.sin(2 * math.pi * (2000 + _random.nextDouble() * 2000) * t) *
              0.03
          : 0.0;

      final sample = cosmicWind + choir + sparkle;

      // Wide cosmic stereo
      left[i] += sample * (0.55 + math.sin(t * 0.03) * 0.15);
      right[i] += sample * (0.55 - math.sin(t * 0.03) * 0.15);
    }

    return Uint8List(0);
  }

  // ============================================================
  // WORLD 7: CORE HUNT - Digital Hunt Atmosphere
  // Predator and prey dynamics, scanning pulses, tracking signals
  // ============================================================

  Uint8List _generateWorld7Drone(
      int samples, Float32List left, Float32List right) {
    // Tense, hunting drone - E2 with aggressive edge
    const baseFreq = 82.41; // E2

    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Hunt tension LFO - stalking rhythm
      final huntLfo = math.sin(2 * math.pi * 0.06 * t) * 0.5 + 0.5;
      final stalkLfo = math.sin(2 * math.pi * 0.09 * t);

      // Aggressive fundamental with edge
      final fundamental = math.sin(2 * math.pi * baseFreq * t) * 0.35;

      // Sawtooth for aggressive hunt character
      final saw = 2.0 * ((baseFreq * t) % 1.0) - 1.0;

      // Tritone (diminished fifth) - the devil's interval for unease
      final tritone =
          math.sin(2 * math.pi * baseFreq * 1.414 * t) * 0.15 * huntLfo;

      // Pulsing sub-bass - heartbeat of the hunt
      final huntPulse = math.sin(2 * math.pi * 0.7 * t);
      final subPulse = math.sin(2 * math.pi * 41 * t) * 0.2 * huntPulse.abs();

      final sample = (fundamental * 0.7 +
              saw * 0.2 * stalkLfo.abs() +
              tritone +
              subPulse) *
          0.45;

      // Aggressive stereo panning
      final pan = math.sin(2 * math.pi * 0.08 * t) * 0.4;
      left[i] += sample * (0.5 - pan);
      right[i] += sample * (0.5 + pan);
    }

    return Uint8List(0);
  }

  Uint8List _generateWorld7Texture(
      int samples, Float32List left, Float32List right) {
    // Scanning pulses and tracking signals
    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Radar sweep pulses
      final sweepLfo = math.sin(2 * math.pi * 0.6 * t);
      final sweep = sweepLfo > 0.8
          ? math.sin(2 * math.pi * (400 + (sweepLfo - 0.8) * 2000) * t) *
              0.025 *
              (1.0 - sweepLfo)
          : 0.0;

      // Target lock signals
      final lockLfo = math.sin(2 * math.pi * 0.35 * t);
      final lock = lockLfo > 0.9
          ? math.sin(2 * math.pi * 1600 * t) * 0.015 * (lockLfo - 0.9) * 10
          : 0.0;

      // Hunt tension noise
      final tensionNoise = _pinkNoise() * 0.02 * (0.6 + sweepLfo.abs() * 0.4);

      final sample = sweep + lock + tensionNoise;

      // Dynamic stereo
      final pan = math.sin(2 * math.pi * 0.12 * t) * 0.5;
      left[i] += sample * (0.5 - pan);
      right[i] += sample * (0.5 + pan);
    }

    return Uint8List(0);
  }

  // ============================================================
  // WORLD 8: OMEGA GRID - Final Grid Atmosphere
  // Grid collapse, system strain, terminal pressure
  // ============================================================

  Uint8List _generateWorld8Drone(
      int samples, Float32List left, Float32List right) {
    // Heavy, oppressive drone - B1 with weight
    const baseFreq = 61.74; // B1

    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // System strain LFO
      final strainLfo = math.sin(2 * math.pi * 0.04 * t) * 0.5 + 0.5;
      final collapseLfo = math.sin(2 * math.pi * 0.015 * t);

      // Heavy fundamental
      final fundamental = math.sin(2 * math.pi * baseFreq * t) * 0.4;

      // Multiple detuned layers for thickness
      double layers = 0;
      for (int v = 0; v < 7; v++) {
        final detune = (v - 3) * 0.3;
        final phase = (v * 0.15);
        layers += math.sin(2 * math.pi * (baseFreq + detune) * t + phase) / 7.0;
      }

      // Massive sub-bass - the weight of the grid
      final sub = math.sin(2 * math.pi * 30.87 * t) * 0.3;

      // System overload harmonics
      final overload = math.sin(2 * math.pi * baseFreq * 2 * t) *
          0.1 *
          (collapseLfo * 0.5 + 0.5);

      final sample =
          (fundamental * 0.6 + layers * 0.25 + sub + overload * strainLfo) *
              0.5;

      // Heavy stereo
      final pan = math.sin(2 * math.pi * 0.02 * t) * 0.3;
      left[i] += sample * (0.5 - pan);
      right[i] += sample * (0.5 + pan);
    }

    return Uint8List(0);
  }

  Uint8List _generateWorld8Texture(
      int samples, Float32List left, Float32List right) {
    // Grid hum and system warnings
    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Grid power hum (lower frequency for massive scale)
      final gridHum = math.sin(2 * math.pi * 90 * t) *
          0.025 *
          (0.7 + math.sin(2 * math.pi * 0.08 * t) * 0.3);

      // System warning tones
      final warningLfo = math.sin(2 * math.pi * 0.18 * t);
      final warning = warningLfo > 0.75
          ? math.sin(2 * math.pi * 440 * t) * 0.02 * (warningLfo - 0.75) * 4
          : 0.0;

      // Heavy pressure noise
      final pressure = _pinkNoise() * 0.025;

      final sample = gridHum + warning + pressure;

      // Solid stereo
      final pan = math.sin(2 * math.pi * 0.05 * t) * 0.4;
      left[i] += sample * (0.5 - pan);
      right[i] += sample * (0.5 + pan);
    }

    return Uint8List(0);
  }

  // ============================================================
  // WORLD 9: STORM TOWER - Chaotic Storm Atmosphere
  // Violent weather, electrical chaos, destructive power
  // ============================================================

  Uint8List _generateWorld9Drone(
      int samples, Float32List left, Float32List right) {
    // Chaotic, storm drone - G#1 with violence
    const baseFreq = 51.91; // G#1

    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Violent storm LFOs
      final stormLfo1 = math.sin(2 * math.pi * 0.11 * t);
      final stormLfo2 = math.sin(2 * math.pi * 0.17 * t + 0.8);
      final stormLfo3 = math.sin(2 * math.pi * 0.07 * t + 1.5);

      // Chaotic frequency modulation
      final freqMod = baseFreq + stormLfo1 * 8 + stormLfo2 * 5 + stormLfo3 * 12;

      // Fundamental with chaos
      final fundamental = math.sin(2 * math.pi * freqMod * t) * 0.35;

      // Sawtooth for harsh storm character
      final saw = 2.0 * ((freqMod * t) % 1.0) - 1.0;

      // Lightning harmonics - high and violent
      final lightning1 = math.sin(2 * math.pi * baseFreq * 7 * t) *
          0.08 *
          (stormLfo1 > 0.7 ? 1.0 : 0.0);
      final lightning2 = math.sin(2 * math.pi * baseFreq * 11 * t) *
          0.05 *
          (stormLfo2 > 0.8 ? 1.0 : 0.0);

      // Thunder sub-bass
      final thunder =
          math.sin(2 * math.pi * 26 * t) * 0.25 * (0.6 + stormLfo3.abs() * 0.4);

      final sample =
          (fundamental + saw * 0.25 + lightning1 + lightning2 + thunder) * 0.5;

      // Chaotic stereo
      final pan = stormLfo1 * 0.6;
      left[i] += sample * (0.5 - pan);
      right[i] += sample * (0.5 + pan);
    }

    return Uint8List(0);
  }

  Uint8List _generateWorld9Texture(
      int samples, Float32List left, Float32List right) {
    // Storm violence and lightning
    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Violent wind
      final windLfo = math.sin(2 * math.pi * 0.13 * t) * 0.5 + 0.5;
      final wind = _pinkNoise() * 0.04 * windLfo;

      // Lightning strikes
      final lightningChance = _random.nextDouble();
      final lightning = lightningChance > 0.997
          ? (_random.nextDouble() * 2 - 1) * 0.5 * math.exp(-(i % 2205) / 441.0)
          : 0.0;

      // Thunder rumble with decay
      final thunderLfo = math.sin(2 * math.pi * 0.06 * t);
      final thunderAmt = thunderLfo > 0.8 ? (thunderLfo - 0.8) * 5 : 0.0;
      final thunder = _pinkNoise() * 0.035 * thunderAmt +
          math.sin(2 * math.pi * 35 * t) * 0.025 * thunderAmt;

      final sample = wind + lightning + thunder;

      // Violent stereo movement
      final pan = math.sin(2 * math.pi * 0.09 * t) * 0.7;
      left[i] += sample * (0.5 - pan);
      right[i] += sample * (0.5 + pan);
    }

    return Uint8List(0);
  }

  // ============================================================
  // WORLD 10: THE END - Apocalyptic Atmosphere
  // System death, digital apocalypse, the final collapse
  // ============================================================

  Uint8List _generateWorld10Drone(
      int samples, Float32List left, Float32List right) {
    // Apocalyptic drone - C1 (lowest) with darkness
    const baseFreq = 32.70; // C1 - the abyss

    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Apocalypse breathing - extremely slow
      final apocalypseLfo = math.sin(2 * math.pi * 0.003 * t) * 0.5 + 0.5;
      final deathLfo = math.sin(2 * math.pi * 0.001 * t);

      // Deep fundamental - the void
      final fundamental = math.sin(2 * math.pi * baseFreq * t) * 0.35;

      // Octave for depth
      final octave = math.sin(2 * math.pi * baseFreq * 2 * t) * 0.2;

      // Dissonant intervals - the death chord
      final minor2nd =
          math.sin(2 * math.pi * baseFreq * 1.06 * t) * 0.15 * apocalypseLfo;
      final tritone = math.sin(2 * math.pi * baseFreq * 1.414 * t) *
          0.12 *
          (deathLfo * 0.5 + 0.5);

      // Deep sub-bass - primordial
      final abyss = math.sin(2 * math.pi * 16.35 * t) * 0.25;

      // High noise shimmer - digital decay
      final decay =
          _pinkNoise() * 0.01 * (apocalypseLfo > 0.5 ? apocalypseLfo : 0);

      final sample =
          (fundamental + octave + minor2nd + tritone + abyss + decay) * 0.5;

      // Minimal stereo - collapsing space
      final pan = math.sin(2 * math.pi * 0.005 * t) * 0.2;
      left[i] += sample * (0.5 - pan);
      right[i] += sample * (0.5 + pan);
    }

    return Uint8List(0);
  }

  Uint8List _generateWorld10Texture(
      int samples, Float32List left, Float32List right) {
    // System death and glitch decay
    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;

      // Digital glitches - system failure
      final glitchChance = _random.nextDouble();
      double glitch = 0;
      if (glitchChance > 0.992) {
        final glitchFreq = 100 + _random.nextDouble() * 2000;
        final glitchDecay = math.exp(-((i % 4410) / 882.0));
        glitch = math.sin(2 * math.pi * glitchFreq * t) * 0.05 * glitchDecay;
      }

      // System flatline - dying tones
      final flatlineLfo = math.sin(2 * math.pi * 0.004 * t);
      final flatline = flatlineLfo > 0.92
          ? math.sin(2 * math.pi * 800 * t) *
              0.02 *
              math.exp(-(flatlineLfo - 0.92) * 125)
          : 0.0;

      // Void noise - sparse and dark
      final voidNoise =
          _pinkNoise() * 0.015 * (math.sin(2 * math.pi * 0.006 * t).abs());

      // Death rattle harmonics
      final rattle = math.sin(2 * math.pi * 20 * t) *
          0.01 *
          (flatlineLfo > 0.85 ? 1.0 : 0.0);

      final sample = glitch + flatline + voidNoise + rattle;

      // Collapsing stereo
      final pan = math.sin(2 * math.pi * 0.003 * t) * 0.3;
      left[i] += sample * (0.5 - pan);
      right[i] += sample * (0.5 + pan);
    }

    return Uint8List(0);
  }

  // ============================================================
  // LAYER GENERATION - Combines world-specific elements
  // ============================================================

  Uint8List _generateDroneLayer(
    int worldId, {
    double durationSeconds = 30.0,
  }) {
    final samples = (durationSeconds * _sampleRate).toInt();
    final leftChannel = Float32List(samples);
    final rightChannel = Float32List(samples);

    switch (worldId) {
      case 1:
        _generateWorld1Drone(samples, leftChannel, rightChannel);
        break;
      case 2:
        _generateWorld2Drone(samples, leftChannel, rightChannel);
        break;
      case 3:
        _generateWorld3Drone(samples, leftChannel, rightChannel);
        break;
      case 4:
        _generateWorld4Drone(samples, leftChannel, rightChannel);
        break;
      case 5:
        _generateWorld5Drone(samples, leftChannel, rightChannel);
        break;
      case 6:
        _generateWorld6Drone(samples, leftChannel, rightChannel);
        break;
      case 7:
        _generateWorld7Drone(samples, leftChannel, rightChannel);
        break;
      case 8:
        _generateWorld8Drone(samples, leftChannel, rightChannel);
        break;
      case 9:
        _generateWorld9Drone(samples, leftChannel, rightChannel);
        break;
      case 10:
        _generateWorld10Drone(samples, leftChannel, rightChannel);
        break;
      default:
        _generateWorld1Drone(samples, leftChannel, rightChannel);
    }

    return _mixToStereoWav(leftChannel, rightChannel);
  }

  Uint8List _generateTextureLayer(
    int worldId, {
    double durationSeconds = 45.0,
  }) {
    final samples = (durationSeconds * _sampleRate).toInt();
    final leftChannel = Float32List(samples);
    final rightChannel = Float32List(samples);

    switch (worldId) {
      case 1:
        _generateWorld1Texture(samples, leftChannel, rightChannel);
        break;
      case 2:
        _generateWorld2Texture(samples, leftChannel, rightChannel);
        break;
      case 3:
        _generateWorld3Texture(samples, leftChannel, rightChannel);
        break;
      case 4:
        _generateWorld4Texture(samples, leftChannel, rightChannel);
        break;
      case 5:
        _generateWorld5Texture(samples, leftChannel, rightChannel);
        break;
      case 6:
        _generateWorld6Texture(samples, leftChannel, rightChannel);
        break;
      case 7:
        _generateWorld7Texture(samples, leftChannel, rightChannel);
        break;
      case 8:
        _generateWorld8Texture(samples, leftChannel, rightChannel);
        break;
      case 9:
        _generateWorld9Texture(samples, leftChannel, rightChannel);
        break;
      case 10:
        _generateWorld10Texture(samples, leftChannel, rightChannel);
        break;
      default:
        _generateWorld1Texture(samples, leftChannel, rightChannel);
    }

    return _mixToStereoWav(leftChannel, rightChannel);
  }

  Uint8List _generateAtmosphereLayer(
    int worldId, {
    double durationSeconds = 60.0,
  }) {
    final samples = (durationSeconds * _sampleRate).toInt();
    final leftChannel = Float32List(samples);
    final rightChannel = Float32List(samples);

    // Generate world-specific atmospheric elements
    _generateWorldAtmosphere(worldId, samples, leftChannel, rightChannel);

    return _mixToStereoWav(leftChannel, rightChannel);
  }

  void _generateWorldAtmosphere(
      int worldId, int samples, Float32List left, Float32List right) {
    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;
      double sample = 0;
      double pan = 0;

      switch (worldId) {
        case 1: // Clean digital pulses
          final pulse = math.sin(2 * math.pi * 0.5 * t);
          sample = pulse > 0.9 ? math.sin(2 * math.pi * 800 * t) * 0.02 : 0;
          pan = math.sin(2 * math.pi * 0.02 * t) * 0.3;
          break;

        case 2: // Time echoes
          final echo = math.sin(2 * math.pi * 0.3 * t) *
              math.sin(2 * math.pi * 0.07 * t);
          sample = echo * math.sin(2 * math.pi * 400 * t) * 0.03;
          pan = math.sin(2 * math.pi * 0.05 * t) * 0.5;
          break;

        case 3: // Distant signals
          final signal = math.sin(2 * math.pi * 0.02 * t);
          sample = signal > 0.8
              ? math.sin(2 * math.pi * 1500 * t) * 0.01 * (signal - 0.8) * 5
              : 0;
          sample += _pinkNoise() * 0.01;
          pan = math.sin(2 * math.pi * 0.01 * t) * 0.6;
          break;

        case 4: // Electric crackle
          final crackle =
              _random.nextDouble() > 0.997 ? _random.nextDouble() * 0.1 : 0;
          sample = crackle + math.sin(2 * math.pi * 120 * t) * 0.02;
          pan = (_random.nextDouble() - 0.5) * 0.8;
          break;

        case 5: // Memory glimmers
          final glimmer = math.sin(2 * math.pi * 0.008 * t);
          sample = glimmer > 0.7
              ? math.sin(2 * math.pi * 3000 * t) *
                  0.01 *
                  math.exp(-(glimmer - 0.7) * 10)
              : 0;
          pan = math.sin(2 * math.pi * 0.03 * t) * 0.4;
          break;

        case 6: // Celestial bells
          final bell = math.sin(2 * math.pi * 0.01 * t);
          if (bell > 0.95) {
            final bellFreq = 500 + (bell - 0.95) * 10000;
            sample = math.sin(2 * math.pi * bellFreq * t) *
                0.02 *
                math.exp(-(bell - 0.95) * 20);
          }
          pan = math.sin(2 * math.pi * 0.007 * t) * 0.25;
          break;

        case 7: // Digital hunt pulses
          final hunt = math.sin(2 * math.pi * 0.4 * t);
          sample = hunt > 0.85
              ? math.sin(2 * math.pi * 600 * t) * 0.025 * (hunt - 0.85) * 6.67
              : 0;
          pan = math.sin(2 * math.pi * 0.06 * t) * 0.4;
          break;

        case 8: // Omega grid hum
          final grid = math.sin(2 * math.pi * 0.15 * t);
          sample = math.sin(2 * math.pi * 180 * t) * 0.02 * (0.5 + grid * 0.5);
          sample +=
              _random.nextDouble() > 0.996 ? _random.nextDouble() * 0.08 : 0;
          pan = math.sin(2 * math.pi * 0.04 * t) * 0.5;
          break;

        case 9: // Storm chaos
          final storm = math.sin(2 * math.pi * 0.25 * t);
          sample = _pinkNoise() * 0.03 * (0.7 + storm * 0.3);
          sample += _random.nextDouble() > 0.995
              ? (_random.nextDouble() * 2 - 1) * 0.15
              : 0;
          pan = (_random.nextDouble() - 0.5) * 0.9;
          break;

        case 10: // Apocalyptic glitches
          final glitch = math.sin(2 * math.pi * 0.08 * t);
          if (_random.nextDouble() > 0.993) {
            final glitchFreq = 200 + _random.nextDouble() * 1800;
            sample = math.sin(2 * math.pi * glitchFreq * t) * 0.04;
          }
          sample += math.sin(2 * math.pi * 40 * t) * 0.015 * glitch.abs();
          pan = (_random.nextDouble() - 0.5) * 0.7;
          break;
      }

      left[i] += sample * (0.5 - pan);
      right[i] += sample * (0.5 + pan);
    }
  }

  Uint8List _generateAccentLayer(
    int worldId, {
    double durationSeconds = 90.0,
  }) {
    final samples = (durationSeconds * _sampleRate).toInt();
    final leftChannel = Float32List(samples);
    final rightChannel = Float32List(samples);

    // Sparse, occasional accents specific to each world
    _generateWorldAccents(worldId, samples, leftChannel, rightChannel);

    return _mixToStereoWav(leftChannel, rightChannel);
  }

  void _generateWorldAccents(
      int worldId, int samples, Float32List left, Float32List right) {
    // Very sparse, evocative accents
    final accentCount = 10 + _random.nextInt(10);

    for (int a = 0; a < accentCount; a++) {
      final startSample = _random.nextInt(samples - _sampleRate);
      final accentDuration = 0.5 + _random.nextDouble() * 2.0;
      final accentSamples = (accentDuration * _sampleRate).toInt();

      for (int i = 0; i < accentSamples && startSample + i < samples; i++) {
        final t = i / _sampleRate;
        final progress = i / accentSamples;
        final envelope = _smoothEnvelope(progress, 0.1, 0.4);

        double sample = 0;
        double pan = (_random.nextDouble() - 0.5) * 0.6;

        switch (worldId) {
          case 1: // Crystal chime
            sample =
                math.sin(2 * math.pi * (1000 + a * 100) * t) * 0.02 * envelope;
            break;
          case 2: // Temporal whoosh
            final sweep = 200 + progress * 800;
            sample = math.sin(2 * math.pi * sweep * t) * 0.015 * envelope;
            break;
          case 3: // Radio blip
            sample = math.sin(2 * math.pi * 1800 * t) *
                0.01 *
                envelope *
                (1 - progress);
            break;
          case 4: // Thunder boom
            sample = _pinkNoise() * 0.03 * envelope * (1 - progress * 0.5);
            sample += math.sin(2 * math.pi * 35 * t) * 0.02 * envelope;
            break;
          case 5: // Whisper sigh
            sample = _pinkNoise() * 0.01 * envelope;
            sample += math.sin(2 * math.pi * 400 * t) * 0.008 * envelope;
            break;
          case 6: // Cosmic tone
            sample =
                math.sin(2 * math.pi * (300 + a * 50) * t) * 0.015 * envelope;
            sample +=
                math.sin(2 * math.pi * (600 + a * 100) * t) * 0.008 * envelope;
            break;
          case 7: // Hunt siren
            final huntSweep = 400 + progress * 600;
            sample = math.sin(2 * math.pi * huntSweep * t) * 0.018 * envelope;
            break;
          case 8: // Grid pulse
            sample =
                math.sin(2 * math.pi * (150 + a * 30) * t) * 0.02 * envelope;
            sample += math.sin(2 * math.pi * 900 * t) *
                0.01 *
                envelope *
                (1 - progress);
            break;
          case 9: // Storm crash
            sample = _pinkNoise() * 0.04 * envelope;
            sample += math.sin(2 * math.pi * 50 * t) * 0.025 * envelope;
            break;
          case 10: // Digital scream
            final screamFreq = 2000 - progress * 1500;
            sample = math.sin(2 * math.pi * screamFreq * t) * 0.025 * envelope;
            sample += _pinkNoise() * 0.015 * envelope * progress;
            break;
        }

        left[startSample + i] += sample * (0.5 - pan);
        right[startSample + i] += sample * (0.5 + pan);
      }
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  double _pinkNoise() {
    // Simple pink noise approximation
    return (_random.nextDouble() * 2 - 1) * 0.7 +
        (_random.nextDouble() * 2 - 1) * 0.2 +
        (_random.nextDouble() * 2 - 1) * 0.1;
  }

  double _smoothEnvelope(double progress, double attack, double release) {
    if (progress < attack) {
      return progress / attack;
    } else if (progress > 1.0 - release) {
      return (1.0 - progress) / release;
    }
    return 1.0;
  }

  Uint8List _mixToStereoWav(Float32List left, Float32List right) {
    _masterAmbientStereo(left, right);

    // Normalize
    double maxSample = 0.0;
    for (int i = 0; i < left.length; i++) {
      maxSample = math.max(maxSample, left[i].abs());
      maxSample = math.max(maxSample, right[i].abs());
    }

    final normalize = maxSample > 0.9 ? 0.9 / maxSample : 1.0;

    // Interleave stereo
    final pcm16 = Int16List(left.length * 2);
    for (int i = 0; i < left.length; i++) {
      pcm16[i * 2] =
          ((left[i] * normalize * 32767).clamp(-32768.0, 32767.0)).toInt();
      pcm16[i * 2 + 1] =
          ((right[i] * normalize * 32767).clamp(-32768.0, 32767.0)).toInt();
    }

    return _addWavHeader(pcm16.buffer.asUint8List());
  }

  void _masterAmbientStereo(Float32List left, Float32List right) {
    if (left.isEmpty || right.isEmpty) return;

    // Gentle width and cleanup to avoid muddy ambience.
    const stereoWidth = 1.08;
    for (int i = 0; i < left.length; i++) {
      final mid = (left[i] + right[i]) * 0.5;
      final side = (left[i] - right[i]) * 0.5 * stereoWidth;
      left[i] = (mid + side).clamp(-1.0, 1.0);
      right[i] = (mid - side).clamp(-1.0, 1.0);
    }

    _applyAmbientDcBlock(left, right);
    _applyAmbientLimiter(left, right, threshold: 0.88);
    _normalizeAmbientLoudness(left, right, targetRms: 0.2, targetPeak: 0.88);
  }

  void _applyAmbientDcBlock(Float32List left, Float32List right) {
    const reject = 0.996;
    var prevInL = 0.0;
    var prevOutL = 0.0;
    var prevInR = 0.0;
    var prevOutR = 0.0;
    for (int i = 0; i < left.length; i++) {
      final l = left[i];
      final r = right[i];
      final lOut = l - prevInL + reject * prevOutL;
      final rOut = r - prevInR + reject * prevOutR;
      prevInL = l;
      prevOutL = lOut;
      prevInR = r;
      prevOutR = rOut;
      left[i] = lOut;
      right[i] = rOut;
    }
  }

  void _applyAmbientLimiter(
    Float32List left,
    Float32List right, {
    required double threshold,
  }) {
    final t = threshold.clamp(0.6, 0.95);
    const curve = 4.2;
    for (int i = 0; i < left.length; i++) {
      left[i] = _limitAmbientSample(left[i], threshold: t, curve: curve);
      right[i] = _limitAmbientSample(right[i], threshold: t, curve: curve);
    }
  }

  double _limitAmbientSample(
    double sample, {
    required double threshold,
    required double curve,
  }) {
    final absSample = sample.abs();
    if (absSample <= threshold) return sample;
    final limited = threshold +
        ((absSample - threshold) / (1.0 + (absSample - threshold) * curve));
    return sample < 0 ? -limited : limited;
  }

  void _normalizeAmbientLoudness(
    Float32List left,
    Float32List right, {
    required double targetRms,
    required double targetPeak,
  }) {
    var peak = 0.0;
    var sumSquares = 0.0;
    final count = left.length * 2;
    for (int i = 0; i < left.length; i++) {
      final l = left[i];
      final r = right[i];
      sumSquares += l * l + r * r;
      peak = math.max(peak, l.abs());
      peak = math.max(peak, r.abs());
    }
    if (peak <= 0.000001 || count <= 0) return;

    final rms = math.sqrt(sumSquares / count);
    var gain = rms > 0.000001 ? (targetRms / rms).clamp(0.72, 1.38) : 1.0;
    final postPeak = peak * gain;
    if (postPeak > targetPeak) {
      gain *= targetPeak / postPeak;
    }
    for (int i = 0; i < left.length; i++) {
      left[i] = (left[i] * gain).clamp(-1.0, 1.0);
      right[i] = (right[i] * gain).clamp(-1.0, 1.0);
    }
  }

  Uint8List _addWavHeader(Uint8List pcmBytes) {
    final int pcmLength = pcmBytes.length;
    final int totalLength = pcmLength + 36;
    const int sampleRate = _sampleRate;
    const int numChannels = _numChannels;
    const int bitsPerSample = _bitsPerSample;
    final int byteRate = (sampleRate * numChannels * bitsPerSample) ~/ 8;
    final int blockAlign = (numChannels * bitsPerSample) ~/ 8;

    final header = ByteData(44);
    header.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    header.setUint32(4, totalLength, Endian.little);
    header.setUint32(8, 0x57415645, Endian.big); // "WAVE"
    header.setUint32(12, 0x666d7420, Endian.big); // "fmt "
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
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

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    if (_tempDir != null && await _tempDir!.exists()) {
      try {
        await _tempDir!.delete(recursive: true);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error cleaning ambient temp files: $e');
        }
      }
    }
  }

  /// Reset the service state (useful between game sessions)
  Future<void> reset() async {
    await stop();
    _currentWorld = 0;
    _volume = 0.65;
    _intensity = 0.5;

    if (kDebugMode) {
      debugPrint('AmbientSoundscapeService reset');
    }
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    await stop();
    await cleanupTempFiles();

    await _dronePlayer?.dispose();
    await _texturePlayer?.dispose();
    await _atmospherePlayer?.dispose();
    await _accentPlayer?.dispose();

    _dronePlayer = null;
    _texturePlayer = null;
    _atmospherePlayer = null;
    _accentPlayer = null;

    _initialized = false;

    if (kDebugMode) {
      debugPrint('AmbientSoundscapeService disposed');
    }
  }
}
