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

class _LayerMix {
  const _LayerMix({
    required this.bass,
    required this.lead,
    required this.pad,
    required this.drum,
    required this.arp,
    required this.global,
  });

  final double bass;
  final double lead;
  final double pad;
  final double drum;
  final double arp;
  final double global;
}

/// Procedural Synthwave Music Generator
/// Inspired by TTGL, Daft Punk, and TRON soundtracks
///
/// Creates dynamic, layered electronic music with:
/// - Pulsing bass lines
/// - Arpeggio synthesizers
/// - Atmospheric pads
/// - Driving drum patterns
class ProceduralMusicService {
  ProceduralMusicService._();
  static final instance = ProceduralMusicService._();

  // Audio configuration
  static const int _sampleRate = 44100;
  static const int _bitsPerSample = 16;
  static const int _numChannels = 2; // Stereo

  // Music state
  bool _initialized = false;
  bool _isPlaying = false;
  double _volume = 0.7;
  int _currentWorld = 1;
  int _leitmotifWorld = 1;
  double _intensity = 0.5; // 0.0 = calm, 1.0 = intense battle
  String _mixProfile = 'high';
  bool _bossLeitmotifActive = false;
  int _bossPhase = 1;
  double _cinematicDuckAmount = 0.0;
  int _cinematicDuckUntilMicros = 0;

  // Cached last effective mix (for testing and diagnostics)
  double _lastBassMix = 0.0;
  double _lastLeadMix = 0.0;
  double _lastPadMix = 0.0;
  double _lastDrumMix = 0.0;
  double _lastArpMix = 0.0;
  double _lastGlobalMix = 0.0;

  // Audio players for layered tracks
  AudioPlayer? _bassPlayer;
  AudioPlayer? _leadPlayer;
  AudioPlayer? _padPlayer;
  AudioPlayer? _drumPlayer;
  AudioPlayer? _arpeggioPlayer;

  // Cached track data - using file paths for more reliable playback
  final Map<String, String> _trackFilePaths = {};
  Directory? _tempDir;

  // Musical constants
  final _random = _FastRng();

  // BPM per world (TRON/synthwave style: 100-140 BPM)
  static const Map<int, int> _worldBPM = {
    1: 110, // Tutorial - Moderate
    2: 118, // First challenge - Building tension
    3: 125, // Mid game - Energetic
    4: 130, // Advanced - Intense
    5: 140, // Final boss - Epic
  };

  // Musical scales (pentatonic and minor for synthwave feel)
  static const List<int> _minorScale = [0, 2, 3, 5, 7, 8, 10]; // Natural minor
  static const List<int> _pentatonicMinor = [
    0,
    3,
    5,
    7,
    10
  ]; // Pentatonic minor

  // Root notes per world (in MIDI note numbers)
  static const Map<int, int> _worldRootNotes = {
    1: 36, // C2 - Deep, foundational
    2: 38, // D2 - Slight tension
    3: 41, // F2 - Emotional
    4: 43, // G2 - Powerful
    5: 33, // A1 - Epic low
  };

  // World color themes (affects sound character)
  static const Map<int, WorldSoundTheme> _worldThemes = {
    1: WorldSoundTheme.neonBlue, // Tutorial - Clean, digital
    2: WorldSoundTheme.magentaPulse, // Challenge - Energetic
    3: WorldSoundTheme.cyanStorm, // Mid - Atmospheric
    4: WorldSoundTheme.orangeHeat, // Advanced - Aggressive
    5: WorldSoundTheme.voidPurple, // Final - Dark, epic
  };

  bool get isPlaying => _isPlaying;
  double get volume => _volume;
  String get mixProfile => _mixProfile;

  // Main Menu specific player
  AudioPlayer? _mainMenuPlayer;
  bool _isMainMenuPlaying = false;

  // ============================================================
  // MAIN MENU EPIC THEME - "NEON HORIZON"
  // A majestic synthwave anthem for the main menu
  // Inspired by TRON Legacy, Blade Runner, and Daft Punk
  // ============================================================

  /// Play the epic main menu theme "NEON HORIZON"
  /// A slow-burning, atmospheric synthwave masterpiece
  Future<void> playMainMenuMusic() async {
    if (!_initialized) await initialize();

    // Stop any currently playing music
    await stop();
    await stopFinalBossMusic();

    _mainMenuPlayer?.dispose();
    _mainMenuPlayer = AudioPlayer();
    await _mainMenuPlayer?.setReleaseMode(ReleaseMode.loop);

    // Generate the epic main menu track
    final epicMenuTrack = _generateMainMenuTrack();

    if (_tempDir != null) {
      final file = File('${_tempDir!.path}/main_menu.wav');
      await file.writeAsBytes(epicMenuTrack);
      _trackFilePaths['main_menu'] = file.path;
      await _mainMenuPlayer?.play(DeviceFileSource(file.path), volume: _volume);
    }

    _isMainMenuPlaying = true;
    _isPlaying = true;

    if (kDebugMode) {
      debugPrint('Playing MAIN MENU theme: NEON HORIZON');
    }
  }

  /// Stop main menu music
  Future<void> stopMainMenuMusic() async {
    _isMainMenuPlaying = false;
    await _mainMenuPlayer?.stop();
  }

  /// Fade out main menu music smoothly over the specified duration
  /// Perfect for transitioning to gameplay or other screens
  Future<void> fadeOutMainMenuMusic({
    Duration duration = const Duration(milliseconds: 1500),
  }) async {
    if (!_isMainMenuPlaying || _mainMenuPlayer == null) return;

    final steps = 30; // Number of volume steps for smooth fade
    final stepDuration = duration.inMilliseconds ~/ steps;
    final initialVolume = _volume;

    for (int i = steps; i >= 0; i--) {
      if (!_isMainMenuPlaying) break; // Stop if already stopped

      final fadeVolume = (initialVolume * i / steps);
      await _mainMenuPlayer?.setVolume(fadeVolume);
      await Future.delayed(Duration(milliseconds: stepDuration));
    }

    await stopMainMenuMusic();

    // Restore volume setting for next time
    await _mainMenuPlayer?.setVolume(_volume);

    if (kDebugMode) {
      debugPrint('Main menu music faded out');
    }
  }

  /// Generate the epic main menu track "NEON HORIZON"
  /// Structure: Ambient Intro -> Build -> Main Theme -> Breakdown -> Reprise
  Uint8List _generateMainMenuTrack() {
    // 95 BPM - Slow, majestic, epic
    const bpm = 95;
    const rootNote = 33; // A1 - Deep, powerful foundation

    // 48 bars for a full epic loop (~2 minutes)
    const beatsPerBar = 4;
    const bars = 48;
    const totalBeats = bars * beatsPerBar;
    final beatDuration = 60.0 / bpm;
    final totalDuration = totalBeats * beatDuration;

    final samples = (totalDuration * _sampleRate).toInt();
    final leftChannel = Float32List(samples);
    final rightChannel = Float32List(samples);

    // Generate each layer with epic, cinematic quality
    _generateMenuSubBass(leftChannel, rightChannel, bpm, rootNote, bars);
    _generateMenuPads(leftChannel, rightChannel, bpm, rootNote, bars);
    _generateMenuArpeggio(leftChannel, rightChannel, bpm, rootNote, bars);
    _generateMenuLead(leftChannel, rightChannel, bpm, rootNote, bars);
    _generateMenuDrums(leftChannel, rightChannel, bpm, bars);
    _generateMenuAmbience(leftChannel, rightChannel, bpm, bars);
    _generateMenuRisers(leftChannel, rightChannel, bpm, bars);

    return _mixToStereoSource(leftChannel, rightChannel);
  }

  /// Get menu section based on bar number
  _MenuSection _getMenuSection(int bar, int totalBars) {
    if (bar < 8) return _MenuSection.ambientIntro;
    if (bar < 16) return _MenuSection.build;
    if (bar < 32) return _MenuSection.mainTheme;
    if (bar < 40) return _MenuSection.breakdown;
    return _MenuSection.reprise;
  }

  /// Deep sub-bass with sidechained pulse - the heartbeat of the menu
  void _generateMenuSubBass(
    Float32List left,
    Float32List right,
    int bpm,
    int rootNote,
    int bars,
  ) {
    final beatDuration = 60.0 / bpm;
    final totalBeats = bars * 4;

    // Epic chord progression for bass: Am - F - C - G (i - VI - III - VII)
    final bassProgression = [
      0,
      8,
      3,
      10,
      0,
      8,
      5,
      10
    ]; // Root notes relative to A

    for (int beat = 0; beat < totalBeats; beat++) {
      final bar = beat ~/ 4;
      final section = _getMenuSection(bar, bars);
      final beatInBar = beat % 4;

      // Skip some beats in ambient intro for sparse feel
      if (section == _MenuSection.ambientIntro && bar < 4 && beatInBar != 0)
        continue;

      // Get bass note from progression
      final progIndex = (bar ~/ 2) % bassProgression.length;
      final noteOffset = bassProgression[progIndex];

      double volume;
      double noteLength;

      switch (section) {
        case _MenuSection.ambientIntro:
          volume = 0.3 + (bar / 8) * 0.1;
          noteLength = 0.9;
          break;
        case _MenuSection.build:
          volume = 0.45;
          noteLength = 0.85;
          break;
        case _MenuSection.mainTheme:
          volume = 0.55;
          noteLength = 0.8;
          break;
        case _MenuSection.breakdown:
          volume = 0.35;
          noteLength = 1.2;
          break;
        case _MenuSection.reprise:
          volume = 0.5;
          noteLength = 0.85;
          break;
      }

      final freq = _midiToFreq(rootNote + noteOffset);
      final startSample = (beat * beatDuration * _sampleRate).toInt();
      final noteSamples = (noteLength * beatDuration * _sampleRate).toInt();

      _renderMenuBassNote(
          left, right, startSample, noteSamples, freq, volume, section);
    }
  }

  void _renderMenuBassNote(
    Float32List left,
    Float32List right,
    int startSample,
    int numSamples,
    double frequency,
    double volume,
    _MenuSection section,
  ) {
    for (int i = 0; i < numSamples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final progress = i / numSamples;

      // Smooth sidechain pump effect
      final sidechain = section == _MenuSection.mainTheme ||
              section == _MenuSection.reprise
          ? (progress < 0.08 ? math.pow(progress / 0.08, 0.7) : 1.0) * 0.85 +
              0.15
          : 1.0;

      // Deep sub (sine) - the foundation
      final sub = math.sin(2 * math.pi * frequency * t);

      // Warm saw for character, heavily filtered
      final saw = 2.0 * ((frequency * t) % 1.0) - 1.0;
      final filteredSaw = saw * 0.2 * (1.0 - progress * 0.5);

      // Sub-octave for extra depth in main sections
      final subOctave =
          section == _MenuSection.mainTheme || section == _MenuSection.reprise
              ? math.sin(2 * math.pi * (frequency / 2) * t) * 0.25
              : 0.0;

      // Smooth envelope
      final envelope = _smoothEnvelope(progress, 0.02, 0.25);

      final sample = (sub * 0.55 + filteredSaw + subOctave) *
          envelope *
          volume *
          sidechain;

      left[startSample + i] += sample;
      right[startSample + i] += sample;
    }
  }

  /// Lush atmospheric pads - the soul of the cyberpunk aesthetic
  void _generateMenuPads(
    Float32List left,
    Float32List right,
    int bpm,
    int rootNote,
    int bars,
  ) {
    final beatDuration = 60.0 / bpm;
    final padOctave = rootNote + 12;

    // Cinematic chord progression with extensions
    // Am9 - Fmaj7 - Cmaj9 - Gsus4
    final lushChords = [
      [0, 3, 7, 10, 14], // Am9
      [8, 12, 15, 19, 20], // Fmaj7
      [3, 7, 10, 14, 17], // Cmaj9
      [10, 14, 17, 22, 15], // Gsus4add9
    ];

    for (int bar = 0; bar < bars; bar++) {
      final section = _getMenuSection(bar, bars);

      // Pads start from bar 2 for atmosphere
      if (bar < 2) continue;

      final chordIndex = (bar ~/ 4) % lushChords.length;
      final chord = lushChords[chordIndex];

      final startBeat = bar * 4;
      final startSample = (startBeat * beatDuration * _sampleRate).toInt();
      final barSamples = (4 * beatDuration * _sampleRate).toInt();

      double volume;
      switch (section) {
        case _MenuSection.ambientIntro:
          volume = 0.12 + (bar - 2) * 0.015;
          break;
        case _MenuSection.build:
          volume = 0.18 + ((bar - 8) / 8) * 0.08;
          break;
        case _MenuSection.mainTheme:
          volume = 0.2;
          break;
        case _MenuSection.breakdown:
          volume = 0.28;
          break;
        case _MenuSection.reprise:
          volume = 0.22;
          break;
      }

      // Render each note in the chord
      for (int noteIdx = 0; noteIdx < chord.length; noteIdx++) {
        final interval = chord[noteIdx];
        final freq = _midiToFreq(padOctave + interval);
        _renderMenuPadNote(left, right, startSample, barSamples, freq, volume,
            section, noteIdx);
      }
    }
  }

  void _renderMenuPadNote(
    Float32List left,
    Float32List right,
    int startSample,
    int numSamples,
    double frequency,
    double volume,
    _MenuSection section,
    int voiceIndex,
  ) {
    for (int i = 0; i < numSamples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final progress = i / numSamples;

      // Very slow, organic swell envelope
      final envelope = progress < 0.4
          ? math.pow(progress / 0.4, 0.6)
          : progress > 0.85
              ? math.pow((1.0 - progress) / 0.15, 0.5)
              : 1.0;

      // Evolving pad with 7 detuned voices + chorus LFO
      double sample = 0;
      for (int voice = 0; voice < 7; voice++) {
        final detune = (voice - 3) * 0.8;
        final lfoPhase = voice * 0.143;
        final chorusLfo = math.sin(2 * math.pi * 0.2 * t + lfoPhase) * 1.2;
        final voiceFreq = frequency + detune + chorusLfo;

        // Smooth triangle wave for warm pad
        final phase = (voiceFreq * t) % 1.0;
        final triangle = 4.0 * (phase < 0.5 ? phase : 1.0 - phase) - 1.0;

        // Add slight saw for brightness in main section
        final saw = section == _MenuSection.mainTheme
            ? (2.0 * ((voiceFreq * t) % 1.0) - 1.0) * 0.1
            : 0.0;

        sample += (triangle + saw) / 7.0;
      }

      // Subtle filter sweep
      final filterMod = 0.7 + 0.3 * math.sin(2 * math.pi * 0.05 * t);
      sample *= filterMod;

      sample *= envelope * volume;

      // Wide stereo spread based on voice index
      final pan = math.sin(t * 0.15 + voiceIndex * 0.5) * 0.45;
      left[startSample + i] += sample * (0.5 - pan);
      right[startSample + i] += sample * (0.5 + pan);
    }
  }

  /// TRON-style arpeggio - iconic and deliberate
  void _generateMenuArpeggio(
    Float32List left,
    Float32List right,
    int bpm,
    int rootNote,
    int bars,
  ) {
    final beatDuration = 60.0 / bpm;
    final arpOctave = rootNote + 24;
    final notesPerBeat = 4; // 16th notes
    final noteLength = beatDuration / notesPerBeat;

    // Iconic TRON-style arpeggio pattern (up then down with octave)
    final arpPattern = [0, 4, 7, 12, 16, 12, 7, 4];

    // Chord tones that shift with the progression
    final arpChords = [
      [0, 3, 7, 12], // Am
      [8, 12, 15, 20], // F
      [3, 7, 10, 15], // C
      [10, 14, 17, 22], // G
    ];

    for (int bar = 0; bar < bars; bar++) {
      final section = _getMenuSection(bar, bars);

      // Arpeggio starts from bar 6
      if (bar < 6) continue;
      if (section == _MenuSection.breakdown && bar < 36)
        continue; // Sparse in breakdown

      final chordIndex = (bar ~/ 4) % arpChords.length;
      final baseChord = arpChords[chordIndex];

      final startBeat = bar * 4;

      for (int beat = 0; beat < 4; beat++) {
        for (int sub = 0; sub < notesPerBeat; sub++) {
          final patternIndex = (beat * notesPerBeat + sub) % arpPattern.length;
          final arpOffset = arpPattern[patternIndex];

          // Map arpeggio to chord tones
          final chordToneIndex = arpOffset ~/ 4;
          final octaveOffset = (arpOffset ~/ 12) * 12;
          final interval =
              baseChord[chordToneIndex % baseChord.length] + octaveOffset;

          final freq = _midiToFreq(arpOctave + interval - 12);
          final absoluteBeat = startBeat + beat;
          final startSample =
              ((absoluteBeat * beatDuration + sub * noteLength) * _sampleRate)
                  .toInt();
          final noteSamples = (noteLength * 0.65 * _sampleRate).toInt();

          double volume;
          switch (section) {
            case _MenuSection.ambientIntro:
              volume = 0.15;
              break;
            case _MenuSection.build:
              volume = 0.2 + ((bar - 8) / 8) * 0.05;
              break;
            case _MenuSection.mainTheme:
              volume = 0.28;
              break;
            case _MenuSection.breakdown:
              volume = 0.18;
              break;
            case _MenuSection.reprise:
              volume = 0.25;
              break;
          }

          // Accent pattern for groove
          if (sub == 0) volume *= 1.2;
          if (sub == 2) volume *= 1.1;

          _renderMenuArpNote(left, right, startSample, noteSamples, freq,
              volume, section, sub);
        }
      }
    }
  }

  void _renderMenuArpNote(
    Float32List left,
    Float32List right,
    int startSample,
    int numSamples,
    double frequency,
    double volume,
    _MenuSection section,
    int subBeat,
  ) {
    for (int i = 0; i < numSamples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final envelope = _adsrEnvelope(i, numSamples, 0.008, 0.04, 0.35, 0.15);

      // Classic square wave with slight pulse width modulation
      final pwm = 0.5 + 0.05 * math.sin(2 * math.pi * 0.3 * t);
      final phase = (frequency * t) % 1.0;
      final square = phase < pwm ? 1.0 : -1.0;

      // Add subtle detuned layer for width
      final detunedSaw = (2.0 * (((frequency + 2) * t) % 1.0) - 1.0) * 0.15;

      final sample = (square * 0.85 + detunedSaw) * envelope * volume;

      // Ping-pong stereo based on sub-beat
      final pan = (subBeat % 2 == 0 ? 0.35 : -0.35) *
          (section == _MenuSection.mainTheme ? 1.0 : 0.7);
      left[startSample + i] += sample * (0.5 - pan);
      right[startSample + i] += sample * (0.5 + pan);
    }
  }

  /// Heroic lead melody - the emotional core
  void _generateMenuLead(
    Float32List left,
    Float32List right,
    int bpm,
    int rootNote,
    int bars,
  ) {
    final beatDuration = 60.0 / bpm;
    final leadOctave = rootNote + 24;

    // Epic, memorable melody inspired by heroic synthwave
    final heroicMelody = _getMenuHeroicMelody(bars);

    for (final note in heroicMelody) {
      if (note.pitch < 0) continue;

      final section = _getMenuSection(note.bar, bars);

      // Lead plays only in key sections
      if (section == _MenuSection.ambientIntro) continue;
      if (section == _MenuSection.build && note.bar < 12) continue;

      final freq = _midiToFreq(leadOctave + note.pitch);
      final startSample = (note.startBeat * beatDuration * _sampleRate).toInt();
      final noteSamples = (note.duration * beatDuration * _sampleRate).toInt();

      double volume;
      switch (section) {
        case _MenuSection.ambientIntro:
          volume = 0.0;
          break;
        case _MenuSection.build:
          volume = 0.25;
          break;
        case _MenuSection.mainTheme:
          volume = 0.38;
          break;
        case _MenuSection.breakdown:
          volume = 0.32;
          break;
        case _MenuSection.reprise:
          volume = 0.4;
          break;
      }

      _renderMenuLeadNote(
          left, right, startSample, noteSamples, freq, volume, section);
    }
  }

  List<_EpicMelodyNote> _getMenuHeroicMelody(int bars) {
    // Heroic, soaring melody with emotional contour
    // Inspired by classic synthwave anthems
    return [
      // Build section (bars 12-15) - Teaser melody
      _EpicMelodyNote(bar: 12, startBeat: 48, pitch: 0, duration: 4),
      _EpicMelodyNote(bar: 13, startBeat: 52, pitch: 3, duration: 2),
      _EpicMelodyNote(bar: 13, startBeat: 54, pitch: 5, duration: 2),
      _EpicMelodyNote(bar: 14, startBeat: 56, pitch: 7, duration: 4),
      _EpicMelodyNote(bar: 15, startBeat: 60, pitch: 5, duration: 4),

      // Main Theme (bars 16-31) - Full heroic melody
      _EpicMelodyNote(bar: 16, startBeat: 64, pitch: 7, duration: 2),
      _EpicMelodyNote(bar: 16, startBeat: 66, pitch: 10, duration: 2),
      _EpicMelodyNote(bar: 17, startBeat: 68, pitch: 12, duration: 4),
      _EpicMelodyNote(bar: 18, startBeat: 72, pitch: 10, duration: 2),
      _EpicMelodyNote(bar: 18, startBeat: 74, pitch: 7, duration: 2),
      _EpicMelodyNote(bar: 19, startBeat: 76, pitch: 5, duration: 4),

      _EpicMelodyNote(bar: 20, startBeat: 80, pitch: 7, duration: 2),
      _EpicMelodyNote(bar: 20, startBeat: 82, pitch: 10, duration: 2),
      _EpicMelodyNote(bar: 21, startBeat: 84, pitch: 14, duration: 4),
      _EpicMelodyNote(bar: 22, startBeat: 88, pitch: 12, duration: 2),
      _EpicMelodyNote(bar: 22, startBeat: 90, pitch: 10, duration: 2),
      _EpicMelodyNote(bar: 23, startBeat: 92, pitch: 7, duration: 4),

      // Second phrase - higher energy
      _EpicMelodyNote(bar: 24, startBeat: 96, pitch: 12, duration: 2),
      _EpicMelodyNote(bar: 24, startBeat: 98, pitch: 14, duration: 2),
      _EpicMelodyNote(bar: 25, startBeat: 100, pitch: 17, duration: 4),
      _EpicMelodyNote(bar: 26, startBeat: 104, pitch: 15, duration: 2),
      _EpicMelodyNote(bar: 26, startBeat: 106, pitch: 12, duration: 2),
      _EpicMelodyNote(bar: 27, startBeat: 108, pitch: 10, duration: 4),

      _EpicMelodyNote(bar: 28, startBeat: 112, pitch: 12, duration: 2),
      _EpicMelodyNote(bar: 28, startBeat: 114, pitch: 14, duration: 2),
      _EpicMelodyNote(bar: 29, startBeat: 116, pitch: 19, duration: 4),
      _EpicMelodyNote(bar: 30, startBeat: 120, pitch: 17, duration: 2),
      _EpicMelodyNote(bar: 30, startBeat: 122, pitch: 14, duration: 2),
      _EpicMelodyNote(bar: 31, startBeat: 124, pitch: 12, duration: 4),

      // Breakdown (bars 32-39) - Sparse, emotional
      _EpicMelodyNote(bar: 33, startBeat: 132, pitch: 7, duration: 6),
      _EpicMelodyNote(bar: 35, startBeat: 140, pitch: 10, duration: 6),
      _EpicMelodyNote(bar: 37, startBeat: 148, pitch: 12, duration: 6),
      _EpicMelodyNote(bar: 39, startBeat: 156, pitch: 14, duration: 4),

      // Reprise (bars 40-47) - Triumphant return
      _EpicMelodyNote(bar: 40, startBeat: 160, pitch: 12, duration: 2),
      _EpicMelodyNote(bar: 40, startBeat: 162, pitch: 14, duration: 2),
      _EpicMelodyNote(bar: 41, startBeat: 164, pitch: 17, duration: 4),
      _EpicMelodyNote(bar: 42, startBeat: 168, pitch: 19, duration: 2),
      _EpicMelodyNote(bar: 42, startBeat: 170, pitch: 17, duration: 2),
      _EpicMelodyNote(bar: 43, startBeat: 172, pitch: 14, duration: 4),

      _EpicMelodyNote(bar: 44, startBeat: 176, pitch: 12, duration: 2),
      _EpicMelodyNote(bar: 44, startBeat: 178, pitch: 14, duration: 2),
      _EpicMelodyNote(bar: 45, startBeat: 180, pitch: 19, duration: 4),
      _EpicMelodyNote(bar: 46, startBeat: 184, pitch: 17, duration: 2),
      _EpicMelodyNote(bar: 46, startBeat: 186, pitch: 14, duration: 2),
      _EpicMelodyNote(bar: 47, startBeat: 188, pitch: 12, duration: 4),
    ];
  }

  void _renderMenuLeadNote(
    Float32List left,
    Float32List right,
    int startSample,
    int numSamples,
    double frequency,
    double volume,
    _MenuSection section,
  ) {
    // Expressive vibrato
    final vibratoRate = 5.2;
    final vibratoDepth = section == _MenuSection.reprise ? 5.0 : 3.5;

    for (int i = 0; i < numSamples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final progress = i / numSamples;
      final envelope = _adsrEnvelope(i, numSamples, 0.04, 0.12, 0.65, 0.28);

      // Delayed vibrato for expression
      final vibrato = progress > 0.18
          ? math.sin(2 * math.pi * vibratoRate * t) *
              vibratoDepth *
              math.min(1.0, (progress - 0.18) * 5)
          : 0.0;

      final freq = frequency + vibrato;

      // Rich supersaw with 6 voices
      double sample = 0;
      for (int voice = 0; voice < 6; voice++) {
        final detune = (voice - 2.5) * 4.0;
        final voiceFreq = freq + detune;
        sample += (2.0 * ((voiceFreq * t) % 1.0) - 1.0) / 6.0;
      }

      // Add sub-layer for power in reprise
      if (section == _MenuSection.reprise) {
        sample += math.sin(2 * math.pi * (freq / 2) * t) * 0.12;
      }

      // Subtle filter motion
      final filterEnv = 0.8 + 0.2 * math.sin(2 * math.pi * 0.1 * t);
      sample *= filterEnv;

      sample *= envelope * volume;

      // Gentle stereo motion
      final pan = math.sin(t * 0.6) * 0.3;
      left[startSample + i] += sample * (0.5 - pan);
      right[startSample + i] += sample * (0.5 + pan);
    }
  }

  /// Half-time drums for epic grandeur
  void _generateMenuDrums(
    Float32List left,
    Float32List right,
    int bpm,
    int bars,
  ) {
    final beatDuration = 60.0 / bpm;
    final totalBeats = bars * 4;

    for (int beat = 0; beat < totalBeats; beat++) {
      final bar = beat ~/ 4;
      final section = _getMenuSection(bar, bars);
      final beatInBar = beat % 4;
      final startSample = (beat * beatDuration * _sampleRate).toInt();

      switch (section) {
        case _MenuSection.ambientIntro:
          // Very sparse - just occasional deep hits
          if (bar >= 4 && beatInBar == 0 && bar % 2 == 0) {
            _renderMenuKick(left, right, startSample, 0.4);
          }
          break;

        case _MenuSection.build:
          // Building energy
          if (beatInBar == 0) {
            _renderMenuKick(left, right, startSample, 0.5);
          }
          if (beatInBar == 2 && bar >= 12) {
            _renderMenuSnare(left, right, startSample, 0.35);
          }
          // Soft hi-hats on eighths
          if (bar >= 10) {
            _renderMenuHiHat(left, right, startSample, false, 0.18);
          }
          break;

        case _MenuSection.mainTheme:
          // Full half-time beat
          if (beatInBar == 0) {
            _renderMenuKick(left, right, startSample, 0.65);
          }
          if (beatInBar == 2) {
            _renderMenuSnare(left, right, startSample, 0.55);
          }
          // Hi-hats
          _renderMenuHiHat(left, right, startSample, false, 0.22);
          // Off-beat open hat
          final offbeat =
              startSample + (beatDuration / 2 * _sampleRate).toInt();
          if (offbeat < left.length && beatInBar % 2 == 1) {
            _renderMenuHiHat(left, right, offbeat, true, 0.25);
          }
          // Crash on section start
          if (bar == 16 && beatInBar == 0) {
            _renderMenuCrash(left, right, startSample, 0.5);
          }
          break;

        case _MenuSection.breakdown:
          // Minimal, atmospheric
          if (beatInBar == 0 && bar % 2 == 0) {
            _renderMenuKick(left, right, startSample, 0.4);
          }
          if (beatInBar == 2 && bar % 4 == 2) {
            _renderMenuSnare(left, right, startSample, 0.35);
          }
          break;

        case _MenuSection.reprise:
          // Full power return
          if (beatInBar == 0) {
            _renderMenuKick(left, right, startSample, 0.7);
          }
          if (beatInBar == 2) {
            _renderMenuSnare(left, right, startSample, 0.6);
          }
          _renderMenuHiHat(left, right, startSample, false, 0.24);
          final offbeat2 =
              startSample + (beatDuration / 2 * _sampleRate).toInt();
          if (offbeat2 < left.length) {
            _renderMenuHiHat(left, right, offbeat2, beatInBar % 2 == 1, 0.22);
          }
          if (bar == 40 && beatInBar == 0) {
            _renderMenuCrash(left, right, startSample, 0.55);
          }
          break;
      }
    }
  }

  void _renderMenuKick(
      Float32List left, Float32List right, int startSample, double volume) {
    final duration = 0.2;
    final samples = (duration * _sampleRate).toInt();

    for (int i = 0; i < samples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final progress = i / samples;

      // Deep, punchy kick with smooth pitch drop
      final freq = 160.0 - (110.0 * math.pow(progress, 0.7));
      final sine = math.sin(2 * math.pi * freq * t);

      // Soft click for attack
      final click = progress < 0.015 ? (1.0 - progress / 0.015) * 0.4 : 0.0;

      final envelope = math.pow(1.0 - progress, 2.0);
      final value = (sine + click) * envelope * volume;

      left[startSample + i] += value;
      right[startSample + i] += value;
    }
  }

  void _renderMenuSnare(
      Float32List left, Float32List right, int startSample, double volume) {
    final duration = 0.18;
    final samples = (duration * _sampleRate).toInt();

    for (int i = 0; i < samples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final progress = i / samples;

      // Body with harmonics
      final body = math.sin(2 * math.pi * 200 * t) * 0.35;
      final body2 = math.sin(2 * math.pi * 320 * t) * 0.15;

      // Noise layer
      final noise = (_random.nextDouble() * 2 - 1) * 0.6;

      final envelope = math.pow(1.0 - progress, 1.4);
      final value = (body + body2 + noise) * envelope * volume;

      left[startSample + i] += value;
      right[startSample + i] += value;
    }
  }

  void _renderMenuHiHat(Float32List left, Float32List right, int startSample,
      bool open, double volume) {
    final duration = open ? 0.18 : 0.05;
    final samples = (duration * _sampleRate).toInt();

    for (int i = 0; i < samples && startSample + i < left.length; i++) {
      final progress = i / samples;
      final noise = _random.nextDouble() * 2 - 1;
      final envelope = math.pow(1.0 - progress, open ? 1.3 : 3.2);
      final value = noise * envelope * volume;

      left[startSample + i] += value * 0.55;
      right[startSample + i] += value * 0.45;
    }
  }

  void _renderMenuCrash(
      Float32List left, Float32List right, int startSample, double volume) {
    final duration = 2.0;
    final samples = (duration * _sampleRate).toInt();

    for (int i = 0; i < samples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final progress = i / samples;

      // Metallic shimmer with multiple frequencies
      double sample = 0;
      final freqs = [2200.0, 2900.0, 3700.0, 4800.0, 6100.0];
      for (final f in freqs) {
        sample +=
            math.sin(2 * math.pi * f * t + _random.nextDouble() * 0.5) * 0.2;
      }
      sample += (_random.nextDouble() * 2 - 1) * 0.4;

      final envelope = math.pow(1.0 - progress, 0.6);
      final value = sample * envelope * volume;

      left[startSample + i] += value * 0.5;
      right[startSample + i] += value * 0.5;
    }
  }

  /// Ambient textures - the atmosphere
  void _generateMenuAmbience(
    Float32List left,
    Float32List right,
    int bpm,
    int bars,
  ) {
    final beatDuration = 60.0 / bpm;
    final totalDuration = bars * 4 * beatDuration;
    final samples = left.length;

    // Subtle background texture throughout
    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;
      final progress = i / samples;
      final bar = (t / (4 * beatDuration)).floor();
      final section = _getMenuSection(bar, bars);

      // Volume based on section
      double volume;
      switch (section) {
        case _MenuSection.ambientIntro:
          volume = 0.08;
          break;
        case _MenuSection.build:
          volume = 0.06;
          break;
        case _MenuSection.mainTheme:
          volume = 0.04;
          break;
        case _MenuSection.breakdown:
          volume = 0.1;
          break;
        case _MenuSection.reprise:
          volume = 0.05;
          break;
      }

      // Filtered noise with slow modulation
      final noise = _random.nextDouble() * 2 - 1;
      final filterLfo = 0.5 + 0.5 * math.sin(2 * math.pi * 0.02 * t);
      final filtered = noise * filterLfo;

      // Very subtle drone
      final drone = math.sin(2 * math.pi * 55 * t) * 0.02;
      final drone2 = math.sin(2 * math.pi * 82.5 * t) * 0.015;

      final sample = (filtered * 0.15 + drone + drone2) * volume;

      // Wide stereo spread
      final pan = math.sin(t * 0.08) * 0.5;
      left[i] += sample * (0.5 - pan);
      right[i] += sample * (0.5 + pan);
    }
  }

  /// Risers for section transitions
  void _generateMenuRisers(
    Float32List left,
    Float32List right,
    int bpm,
    int bars,
  ) {
    final beatDuration = 60.0 / bpm;

    // Risers before main sections
    final riserPoints = [
      (14, 16), // Before main theme
      (38, 40), // Before reprise
    ];

    for (final (startBar, endBar) in riserPoints) {
      final startSample = (startBar * 4 * beatDuration * _sampleRate).toInt();
      final endSample = (endBar * 4 * beatDuration * _sampleRate).toInt();
      final riserSamples = endSample - startSample;

      for (int i = 0; i < riserSamples && startSample + i < left.length; i++) {
        final t = i / _sampleRate;
        final progress = i / riserSamples;

        // Rising noise sweep
        final noise = _random.nextDouble() * 2 - 1;

        // Exponential filter sweep
        final filterSweep = math.pow(progress, 2.5);

        // Rising pitch
        final freq = 150 + progress * 1500;
        final tone = math.sin(2 * math.pi * freq * t);

        // Combine with crescendo
        final envelope = filterSweep * 0.35;
        final value = (noise * 0.25 + tone * 0.75) * envelope;

        left[startSample + i] += value;
        right[startSample + i] += value;
      }
    }
  }

  /// Smooth envelope helper for organic sounds
  double _smoothEnvelope(double progress, double attack, double release) {
    if (progress < attack) {
      return math.pow(progress / attack, 0.5).toDouble();
    } else if (progress > 1.0 - release) {
      return math.pow((1.0 - progress) / release, 0.5).toDouble();
    }
    return 1.0;
  }

  /// Initialize the music system
  Future<void> initialize() async {
    if (_initialized) return;

    // Get temp directory for storing generated audio files
    try {
      _tempDir = await getTemporaryDirectory();
      final musicDir = Directory('${_tempDir!.path}/neon_music');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }
      _tempDir = musicDir;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'ProceduralMusicService: Failed to create temp directory: $e');
      }
    }

    _bassPlayer = AudioPlayer();
    _leadPlayer = AudioPlayer();
    _padPlayer = AudioPlayer();
    _drumPlayer = AudioPlayer();
    _arpeggioPlayer = AudioPlayer();

    // Set all players to loop
    await _bassPlayer?.setReleaseMode(ReleaseMode.loop);
    await _leadPlayer?.setReleaseMode(ReleaseMode.loop);
    await _padPlayer?.setReleaseMode(ReleaseMode.loop);
    await _drumPlayer?.setReleaseMode(ReleaseMode.loop);
    await _arpeggioPlayer?.setReleaseMode(ReleaseMode.loop);

    _initialized = true;
    _updateLayerVolumes();

    if (kDebugMode) {
      debugPrint(
          'ProceduralMusicService initialized (temp: ${_tempDir?.path})');
    }
  }

  /// Set music volume (0.0 - 1.0)
  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    _updateLayerVolumes();
  }

  /// Set intensity level (affects layer mixing and sound character)
  void setIntensity(double intensity) {
    _intensity = intensity.clamp(0.0, 1.0);
    _updateLayerVolumes();
  }

  /// Set adaptive music mix profile (`low`, `medium`, `high`, `extreme`).
  void setMixProfile(String profile) {
    _mixProfile = _normalizeMixProfile(profile);
    _updateLayerVolumes();
  }

  /// Apply short musical ducking so important SFX and cues cut through.
  void triggerCinematicDucking({
    Duration duration = const Duration(milliseconds: 650),
    double amount = 0.24,
  }) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final until = now + duration.inMicroseconds.clamp(0, 10000000);
    _cinematicDuckUntilMicros = math.max(_cinematicDuckUntilMicros, until);
    _cinematicDuckAmount =
        math.max(_cinematicDuckAmount, amount.clamp(0.0, 0.7));
    _updateLayerVolumes();
  }

  /// Enable/refresh boss leitmotif mood by world and phase.
  void setBossLeitmotif({
    required bool active,
    int? worldId,
    int phase = 1,
  }) {
    _bossLeitmotifActive = active;
    if (worldId != null) {
      _leitmotifWorld = worldId.clamp(1, 8);
    }
    _bossPhase = phase.clamp(1, 4);
    _updateLayerVolumes();
  }

  /// Start playing music for a specific world/level
  Future<void> playWorldMusic(int worldId) async {
    if (!_initialized) await initialize();

    _currentWorld = worldId.clamp(1, 5);
    _leitmotifWorld = _currentWorld;

    // Stop current music AND clean up old temp files
    await stop();
    await cleanupTempFiles();

    // Generate tracks for this world
    await _generateWorldTracks(_currentWorld);

    // Start all layers
    await _startAllLayers();

    _isPlaying = true;

    if (kDebugMode) {
      debugPrint('Playing music for world $_currentWorld');
    }
  }

  /// Stop all music
  Future<void> stop() async {
    _isPlaying = false;
    await _bassPlayer?.stop();
    await _leadPlayer?.stop();
    await _padPlayer?.stop();
    await _drumPlayer?.stop();
    await _arpeggioPlayer?.stop();
  }

  /// Clean up temporary audio files to prevent disk accumulation
  /// CRITICAL: Call this between level transitions to free disk space
  Future<void> cleanupTempFiles() async {
    for (final path in _trackFilePaths.values) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore deletion errors - file may be in use
        if (kDebugMode) {
          debugPrint(
              'ProceduralMusicService: Failed to delete temp file $path: $e');
        }
      }
    }
    _trackFilePaths.clear();

    if (kDebugMode) {
      debugPrint('ProceduralMusicService: Cleaned up temp files');
    }
  }

  /// Reset the service between level transitions
  /// Stops music and cleans up temp files
  Future<void> reset() async {
    await stop();
    await cleanupTempFiles();
    _bossLeitmotifActive = false;
    _bossPhase = 1;
    _leitmotifWorld = _currentWorld;
    _cinematicDuckUntilMicros = 0;
    _cinematicDuckAmount = 0.0;
    _updateLayerVolumes();
  }

  /// Pause music
  Future<void> pause() async {
    await _bassPlayer?.pause();
    await _leadPlayer?.pause();
    await _padPlayer?.pause();
    await _drumPlayer?.pause();
    await _arpeggioPlayer?.pause();
  }

  /// Resume music
  Future<void> resume() async {
    await _bassPlayer?.resume();
    await _leadPlayer?.resume();
    await _padPlayer?.resume();
    await _drumPlayer?.resume();
    await _arpeggioPlayer?.resume();
  }

  /// Transition to boss music (increases intensity)
  void triggerBossMode() {
    setIntensity(1.0);
  }

  /// Return to normal intensity
  void triggerNormalMode() {
    setIntensity(0.5);
  }

  // ============================================================
  // FINAL BOSS EPIC THEME - "BROKEN GRID"
  // Inspired by "Libera Me From Hell" (TTGL) + TRON/Daft Punk
  // ============================================================

  AudioPlayer? _finalBossPlayer;
  bool _isFinalBossPlaying = false;

  /// Play the epic final boss theme "BROKEN GRID"
  /// A synthwave opera combining orchestral builds with electronic drops
  Future<void> playFinalBossMusic() async {
    if (!_initialized) await initialize();

    // Stop regular music
    await stop();

    _finalBossPlayer?.dispose();
    _finalBossPlayer = AudioPlayer();
    await _finalBossPlayer?.setReleaseMode(ReleaseMode.loop);

    // Generate the epic final boss track and save to file
    final epicTrack = _generateFinalBossTrack();

    if (_tempDir != null) {
      final file = File('${_tempDir!.path}/final_boss.wav');
      await file.writeAsBytes(epicTrack);
      await _finalBossPlayer?.play(DeviceFileSource(file.path),
          volume: _volume);
    }

    _isFinalBossPlaying = true;
    _isPlaying = true;

    if (kDebugMode) {
      debugPrint('Playing FINAL BOSS theme: BROKEN GRID');
    }
  }

  /// Stop final boss music
  Future<void> stopFinalBossMusic() async {
    _isFinalBossPlaying = false;
    await _finalBossPlayer?.stop();
    _updateLayerVolumes();
  }

  /// Generate the epic final boss track
  /// Structure: Intro -> Build -> Drop -> Breakdown -> Final Drop
  Uint8List _generateFinalBossTrack() {
    // 150 BPM - Epic, driving tempo
    const bpm = 150;
    const rootNote = 33; // A1 - Deep, powerful

    // 32 bars total for a complete epic loop
    const beatsPerBar = 4;
    const bars = 32;
    const totalBeats = bars * beatsPerBar;
    final beatDuration = 60.0 / bpm;
    final totalDuration = totalBeats * beatDuration;

    final samples = (totalDuration * _sampleRate).toInt();
    final leftChannel = Float32List(samples);
    final rightChannel = Float32List(samples);

    // Generate each layer and mix
    _generateEpicBass(leftChannel, rightChannel, bpm, rootNote, bars);
    _generateEpicLead(leftChannel, rightChannel, bpm, rootNote, bars);
    _generateEpicPads(leftChannel, rightChannel, bpm, rootNote, bars);
    _generateEpicDrums(leftChannel, rightChannel, bpm, bars);
    _generateEpicArpeggio(leftChannel, rightChannel, bpm, rootNote, bars);
    _generateEpicRiser(leftChannel, rightChannel, bpm, bars);

    return _mixToStereoSource(leftChannel, rightChannel);
  }

  /// Epic bass - Heavy sidechained pulse with octave jumps
  void _generateEpicBass(
    Float32List left,
    Float32List right,
    int bpm,
    int rootNote,
    int bars,
  ) {
    final beatDuration = 60.0 / bpm;
    final totalBeats = bars * 4;

    // Epic bass pattern with octave jumps and power chords
    // Pattern changes per section
    for (int beat = 0; beat < totalBeats; beat++) {
      final bar = beat ~/ 4;
      final section = _getSection(bar, bars);

      // Skip bass in intro section (first 4 bars)
      if (section == _EpicSection.intro && bar < 2) continue;

      final beatInBar = beat % 4;
      int noteOffset = 0;
      double noteLength = 0.5;
      double volume = 0.6;

      // Different patterns per section
      switch (section) {
        case _EpicSection.intro:
          // Simple pulse on 1 and 3
          if (beatInBar == 0 || beatInBar == 2) {
            noteOffset = 0;
            noteLength = 0.4;
            volume = 0.4;
          } else {
            continue;
          }
          break;

        case _EpicSection.build:
          // Building intensity - add more notes
          if (beatInBar == 0) {
            noteOffset = 0;
            noteLength = 0.6;
            volume = 0.5;
          } else if (beatInBar == 2) {
            noteOffset = 7; // Fifth
            noteLength = 0.4;
            volume = 0.45;
          } else if (beatInBar == 3 && bar % 2 == 1) {
            noteOffset = 12; // Octave hit
            noteLength = 0.3;
            volume = 0.5;
          } else {
            continue;
          }
          break;

        case _EpicSection.drop:
          // FULL POWER - Heavy driving bass
          if (beatInBar == 0) {
            noteOffset = 0;
            noteLength = 0.7;
            volume = 0.7;
          } else if (beatInBar == 1) {
            noteOffset = 0;
            noteLength = 0.3;
            volume = 0.5;
          } else if (beatInBar == 2) {
            noteOffset = 7;
            noteLength = 0.5;
            volume = 0.6;
          } else {
            noteOffset = 12;
            noteLength = 0.3;
            volume = 0.55;
          }
          break;

        case _EpicSection.breakdown:
          // Sparse, tension building
          if (beatInBar == 0 && bar % 2 == 0) {
            noteOffset = 0;
            noteLength = 1.5;
            volume = 0.4;
          } else {
            continue;
          }
          break;

        case _EpicSection.finalDrop:
          // MAXIMUM POWER - All out assault
          noteOffset = [0, 0, 7, 12][beatInBar];
          noteLength = beatInBar == 0 ? 0.8 : 0.4;
          volume = 0.75;
          break;
      }

      final freq = _midiToFreq(rootNote + noteOffset);
      final startSample = (beat * beatDuration * _sampleRate).toInt();
      final noteSamples = (noteLength * beatDuration * _sampleRate).toInt();

      _renderEpicBassNote(
          left, right, startSample, noteSamples, freq, volume, section);
    }
  }

  void _renderEpicBassNote(
    Float32List left,
    Float32List right,
    int startSample,
    int numSamples,
    double frequency,
    double volume,
    _EpicSection section,
  ) {
    for (int i = 0; i < numSamples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final progress = i / numSamples;

      // Sidechain compression simulation (pumping effect)
      final sidechain =
          section == _EpicSection.drop || section == _EpicSection.finalDrop
              ? (progress < 0.1 ? progress / 0.1 : 1.0) * 0.7 + 0.3
              : 1.0;

      // Sub bass (sine) + distorted saw for grit
      final sub = math.sin(2 * math.pi * frequency * t);
      final saw = 2.0 * ((frequency * t) % 1.0) - 1.0;

      // Add distortion in intense sections
      double distortedSaw = saw;
      if (section == _EpicSection.drop || section == _EpicSection.finalDrop) {
        distortedSaw = (saw * 2.0).clamp(-1.0, 1.0); // Soft clip
      }

      // Envelope
      final envelope = _adsrEnvelope(i, numSamples, 0.01, 0.1, 0.8, 0.15);

      final sample =
          (sub * 0.5 + distortedSaw * 0.35) * envelope * volume * sidechain;

      left[startSample + i] += sample;
      right[startSample + i] += sample;
    }
  }

  /// Epic lead - Soaring synth melody with "Row Row Fight the Power" energy
  void _generateEpicLead(
    Float32List left,
    Float32List right,
    int bpm,
    int rootNote,
    int bars,
  ) {
    final beatDuration = 60.0 / bpm;
    final leadOctave = rootNote + 24; // 2 octaves up

    // Epic melody inspired by triumphant anime themes
    // Uses heroic intervals: fifths, octaves, major thirds
    final epicMelody = _getEpicMelody(bars);

    for (final note in epicMelody) {
      if (note.pitch < 0) continue;

      final section = _getSection(note.bar, bars);

      // Lead only plays in certain sections
      if (section == _EpicSection.intro) continue;
      if (section == _EpicSection.breakdown && note.bar % 2 == 0) continue;

      final freq = _midiToFreq(leadOctave + note.pitch);
      final startSample = (note.startBeat * beatDuration * _sampleRate).toInt();
      final noteSamples = (note.duration * beatDuration * _sampleRate).toInt();

      final volume = section == _EpicSection.finalDrop ? 0.5 : 0.4;
      _renderEpicLeadNote(
          left, right, startSample, noteSamples, freq, volume, section);
    }
  }

  void _renderEpicLeadNote(
    Float32List left,
    Float32List right,
    int startSample,
    int numSamples,
    double frequency,
    double volume,
    _EpicSection section,
  ) {
    // Vibrato and expression
    final vibratoRate = 5.5;
    final vibratoDepth = section == _EpicSection.finalDrop ? 6.0 : 4.0;

    for (int i = 0; i < numSamples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final progress = i / numSamples;
      final envelope = _adsrEnvelope(i, numSamples, 0.03, 0.1, 0.7, 0.25);

      // Delayed vibrato
      final vibrato = progress > 0.15
          ? math.sin(2 * math.pi * vibratoRate * t) * vibratoDepth
          : 0.0;

      final freq = frequency + vibrato;

      // Rich supersaw with 5 voices for epic sound
      double sample = 0;
      for (int voice = 0; voice < 5; voice++) {
        final detune = (voice - 2) * 5.0; // Wider detune for bigger sound
        final voiceFreq = freq + detune;
        sample += (2.0 * ((voiceFreq * t) % 1.0) - 1.0) / 5.0;
      }

      // Add sub-octave for power in final drop
      if (section == _EpicSection.finalDrop) {
        sample += math.sin(2 * math.pi * (freq / 2) * t) * 0.15;
      }

      sample *= envelope * volume;

      // Wide stereo spread
      final pan = math.sin(t * 0.7) * 0.35;
      left[startSample + i] += sample * (0.5 - pan);
      right[startSample + i] += sample * (0.5 + pan);
    }
  }

  /// Epic pads - Orchestral-style swells
  void _generateEpicPads(
    Float32List left,
    Float32List right,
    int bpm,
    int rootNote,
    int bars,
  ) {
    final beatDuration = 60.0 / bpm;
    final padOctave = rootNote + 12;

    // Power chord progression: i - VI - III - VII (epic minor progression)
    final epicChords = [
      [0, 7, 12], // Am power chord
      [8, 12, 15], // F major
      [3, 7, 10], // C major
      [10, 14, 17], // G major
    ];

    for (int bar = 0; bar < bars; bar++) {
      final section = _getSection(bar, bars);

      // Pads play throughout but with different intensity
      final chordIndex = (bar ~/ 2) % epicChords.length;
      final chord = epicChords[chordIndex];

      final startBeat = bar * 4;
      final startSample = (startBeat * beatDuration * _sampleRate).toInt();
      final barSamples = (4 * beatDuration * _sampleRate).toInt();

      double volume;
      switch (section) {
        case _EpicSection.intro:
          volume = 0.2;
          break;
        case _EpicSection.build:
          volume = 0.25 + (bar - 4) * 0.02; // Crescendo
          break;
        case _EpicSection.drop:
          volume = 0.15; // Pulled back for bass
          break;
        case _EpicSection.breakdown:
          volume = 0.35; // More prominent
          break;
        case _EpicSection.finalDrop:
          volume = 0.2;
          break;
      }

      for (final interval in chord) {
        final freq = _midiToFreq(padOctave + interval);
        _renderEpicPadNote(
            left, right, startSample, barSamples, freq, volume, section);
      }
    }
  }

  void _renderEpicPadNote(
    Float32List left,
    Float32List right,
    int startSample,
    int numSamples,
    double frequency,
    double volume,
    _EpicSection section,
  ) {
    for (int i = 0; i < numSamples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final progress = i / numSamples;

      // Slow swell envelope for orchestral feel
      final envelope = progress < 0.3
          ? progress / 0.3
          : progress > 0.8
              ? (1.0 - progress) / 0.2
              : 1.0;

      // Strings-like pad with chorus
      double sample = 0;
      for (int voice = 0; voice < 6; voice++) {
        final detune = (voice - 2.5) * 1.2;
        final lfoPhase = voice * 0.17;
        final lfo = math.sin(2 * math.pi * 0.3 * t + lfoPhase) * 1.5;
        final voiceFreq = frequency + detune + lfo;

        // Triangle wave for smooth pad
        final phase = (voiceFreq * t) % 1.0;
        sample += (4.0 * (phase < 0.5 ? phase : 1.0 - phase) - 1.0) / 6.0;
      }

      sample *= envelope * volume;

      // Wide stereo
      final pan = math.sin(t * 0.2 + frequency * 0.005) * 0.45;
      left[startSample + i] += sample * (0.5 - pan);
      right[startSample + i] += sample * (0.5 + pan);
    }
  }

  /// Epic drums - Four-on-the-floor meets orchestral hits
  void _generateEpicDrums(
    Float32List left,
    Float32List right,
    int bpm,
    int bars,
  ) {
    final beatDuration = 60.0 / bpm;
    final totalBeats = bars * 4;

    for (int beat = 0; beat < totalBeats; beat++) {
      final bar = beat ~/ 4;
      final section = _getSection(bar, bars);
      final beatInBar = beat % 4;
      final startSample = (beat * beatDuration * _sampleRate).toInt();

      // Different drum patterns per section
      switch (section) {
        case _EpicSection.intro:
          // Sparse, building
          if (beatInBar == 0 && bar % 2 == 0) {
            _renderEpicKick(left, right, startSample, 0.5);
          }
          if (beat % 8 == 7) {
            _renderEpicSnare(left, right, startSample, 0.3);
          }
          break;

        case _EpicSection.build:
          // Building energy
          if (beatInBar == 0 || beatInBar == 2) {
            _renderEpicKick(left, right, startSample, 0.6);
          }
          if (beatInBar == 1 || beatInBar == 3) {
            _renderEpicSnare(left, right, startSample, 0.4);
          }
          // Hi-hats on eighths
          _renderEpicHiHat(left, right, startSample, false, 0.25);
          final offbeatSample =
              startSample + (beatDuration / 2 * _sampleRate).toInt();
          if (offbeatSample < left.length) {
            _renderEpicHiHat(left, right, offbeatSample, false, 0.2);
          }
          break;

        case _EpicSection.drop:
          // FULL POWER four-on-the-floor
          _renderEpicKick(left, right, startSample, 0.8);
          if (beatInBar == 1 || beatInBar == 3) {
            _renderEpicSnare(left, right, startSample, 0.7);
          }
          // Open hi-hat on off-beats
          final offbeat =
              startSample + (beatDuration / 2 * _sampleRate).toInt();
          if (offbeat < left.length) {
            _renderEpicHiHat(left, right, offbeat, true, 0.35);
          }
          // Crash on bar 1 of drop
          if (bar == 8 && beatInBar == 0) {
            _renderEpicCrash(left, right, startSample, 0.6);
          }
          break;

        case _EpicSection.breakdown:
          // Half-time feel
          if (beatInBar == 0) {
            _renderEpicKick(left, right, startSample, 0.5);
          }
          if (beatInBar == 2) {
            _renderEpicSnare(left, right, startSample, 0.5);
          }
          break;

        case _EpicSection.finalDrop:
          // MAXIMUM INTENSITY
          _renderEpicKick(left, right, startSample, 0.9);
          if (beatInBar == 1 || beatInBar == 3) {
            _renderEpicSnare(left, right, startSample, 0.8);
          }
          // Double-time hi-hats
          final sixteenth = beatDuration / 4;
          for (int s = 0; s < 4; s++) {
            final subSample =
                startSample + (s * sixteenth * _sampleRate).toInt();
            if (subSample < left.length) {
              _renderEpicHiHat(left, right, subSample, s % 2 == 1, 0.3);
            }
          }
          // Crash at start
          if (bar == 24 && beatInBar == 0) {
            _renderEpicCrash(left, right, startSample, 0.8);
          }
          break;
      }
    }
  }

  void _renderEpicKick(
      Float32List left, Float32List right, int startSample, double volume) {
    final duration = 0.18;
    final samples = (duration * _sampleRate).toInt();

    for (int i = 0; i < samples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final progress = i / samples;

      // Punchy kick with pitch drop
      final freq = 180.0 - (130.0 * progress);
      final sine = math.sin(2 * math.pi * freq * t);

      // Click transient
      final click = progress < 0.02 ? (1.0 - progress / 0.02) * 0.5 : 0.0;

      final envelope = math.pow(1.0 - progress, 1.8);
      final value = (sine + click) * envelope * volume;

      left[startSample + i] += value;
      right[startSample + i] += value;
    }
  }

  void _renderEpicSnare(
      Float32List left, Float32List right, int startSample, double volume) {
    final duration = 0.15;
    final samples = (duration * _sampleRate).toInt();

    for (int i = 0; i < samples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final progress = i / samples;

      // Body tone
      final body = math.sin(2 * math.pi * 220 * t) * 0.4;

      // Noise layer
      final noise = (_random.nextDouble() * 2 - 1) * 0.7;

      final envelope = math.pow(1.0 - progress, 1.3);
      final value = (body + noise) * envelope * volume;

      left[startSample + i] += value;
      right[startSample + i] += value;
    }
  }

  void _renderEpicHiHat(Float32List left, Float32List right, int startSample,
      bool open, double volume) {
    final duration = open ? 0.2 : 0.06;
    final samples = (duration * _sampleRate).toInt();

    for (int i = 0; i < samples && startSample + i < left.length; i++) {
      final progress = i / samples;
      final noise = _random.nextDouble() * 2 - 1;
      final envelope = math.pow(1.0 - progress, open ? 1.2 : 3.5);
      final value = noise * envelope * volume;

      left[startSample + i] += value * 0.6;
      right[startSample + i] += value * 0.4;
    }
  }

  void _renderEpicCrash(
      Float32List left, Float32List right, int startSample, double volume) {
    final duration = 1.5;
    final samples = (duration * _sampleRate).toInt();

    for (int i = 0; i < samples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final progress = i / samples;

      // Metallic crash with multiple frequencies
      double sample = 0;
      final freqs = [2500.0, 3200.0, 4100.0, 5500.0];
      for (final f in freqs) {
        sample += math.sin(2 * math.pi * f * t + _random.nextDouble()) * 0.25;
      }
      sample += (_random.nextDouble() * 2 - 1) * 0.5;

      final envelope = math.pow(1.0 - progress, 0.8);
      final value = sample * envelope * volume;

      left[startSample + i] += value * 0.5;
      right[startSample + i] += value * 0.5;
    }
  }

  /// Epic arpeggio - TRON-style rapid sequences
  void _generateEpicArpeggio(
    Float32List left,
    Float32List right,
    int bpm,
    int rootNote,
    int bars,
  ) {
    final beatDuration = 60.0 / bpm;
    final arpOctave = rootNote + 24;
    final notesPerBeat = 4; // 16th notes
    final noteLength = beatDuration / notesPerBeat;
    final totalBeats = bars * 4;

    // Arpeggio pattern (chord tones)
    final arpPattern = [0, 4, 7, 12, 7, 4, 0, 7]; // Up and down octave

    for (int beat = 0; beat < totalBeats; beat++) {
      final bar = beat ~/ 4;
      final section = _getSection(bar, bars);

      // Arp plays in build, drop, and final drop
      if (section == _EpicSection.intro) continue;
      if (section == _EpicSection.breakdown) continue;

      final volume = section == _EpicSection.finalDrop ? 0.35 : 0.25;

      for (int sub = 0; sub < notesPerBeat; sub++) {
        final patternIndex = (beat * notesPerBeat + sub) % arpPattern.length;
        final interval = arpPattern[patternIndex];

        final freq = _midiToFreq(arpOctave + interval);
        final startSample =
            ((beat * beatDuration + sub * noteLength) * _sampleRate).toInt();
        final noteSamples = (noteLength * 0.6 * _sampleRate).toInt();

        _renderEpicArpNote(left, right, startSample, noteSamples, freq, volume);
      }
    }
  }

  void _renderEpicArpNote(
    Float32List left,
    Float32List right,
    int startSample,
    int numSamples,
    double frequency,
    double volume,
  ) {
    for (int i = 0; i < numSamples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final envelope = _adsrEnvelope(i, numSamples, 0.005, 0.03, 0.4, 0.1);

      // Bright square wave
      final square = math.sin(2 * math.pi * frequency * t) > 0 ? 1.0 : -1.0;
      final sample = square * envelope * volume;

      // Fast ping-pong panning
      final pan = math.sin(startSample / _sampleRate * 8) * 0.4;
      left[startSample + i] += sample * (0.5 - pan);
      right[startSample + i] += sample * (0.5 + pan);
    }
  }

  /// Generate risers for transitions
  void _generateEpicRiser(
    Float32List left,
    Float32List right,
    int bpm,
    int bars,
  ) {
    final beatDuration = 60.0 / bpm;

    // Riser before drops (bars 7-8, 23-24)
    final riserBars = [
      (6, 8), // Before first drop
      (22, 24), // Before final drop
    ];

    for (final (startBar, endBar) in riserBars) {
      final startSample = (startBar * 4 * beatDuration * _sampleRate).toInt();
      final endSample = (endBar * 4 * beatDuration * _sampleRate).toInt();
      final riserSamples = endSample - startSample;

      for (int i = 0; i < riserSamples && startSample + i < left.length; i++) {
        final t = i / _sampleRate;
        final progress = i / riserSamples;

        // Rising noise sweep
        final noise = _random.nextDouble() * 2 - 1;

        // Filter sweep (simulated with volume)
        final filterSweep = progress * progress; // Exponential rise

        // Pitch rise
        final freq = 200 + progress * 2000;
        final tone = math.sin(2 * math.pi * freq * t);

        final envelope = filterSweep * 0.4;
        final value = (noise * 0.3 + tone * 0.7) * envelope;

        left[startSample + i] += value;
        right[startSample + i] += value;
      }
    }
  }

  /// Get the section of the track based on bar number
  _EpicSection _getSection(int bar, int totalBars) {
    if (bar < 4) return _EpicSection.intro;
    if (bar < 8) return _EpicSection.build;
    if (bar < 16) return _EpicSection.drop;
    if (bar < 24) return _EpicSection.breakdown;
    return _EpicSection.finalDrop;
  }

  /// Get the epic melody for the final boss
  List<_EpicMelodyNote> _getEpicMelody(int bars) {
    // Heroic melody using power intervals
    // Inspired by "Row Row Fight the Power" triumphant feel
    return [
      // Build section (bars 4-7) - Rising tension
      _EpicMelodyNote(bar: 4, startBeat: 16, pitch: 0, duration: 2),
      _EpicMelodyNote(bar: 4, startBeat: 18, pitch: 3, duration: 2),
      _EpicMelodyNote(bar: 5, startBeat: 20, pitch: 5, duration: 2),
      _EpicMelodyNote(bar: 5, startBeat: 22, pitch: 7, duration: 2),
      _EpicMelodyNote(bar: 6, startBeat: 24, pitch: 7, duration: 4),
      _EpicMelodyNote(bar: 7, startBeat: 28, pitch: 12, duration: 4),

      // Drop section (bars 8-15) - Triumphant main melody
      _EpicMelodyNote(bar: 8, startBeat: 32, pitch: 12, duration: 2),
      _EpicMelodyNote(bar: 8, startBeat: 34, pitch: 10, duration: 1),
      _EpicMelodyNote(bar: 8, startBeat: 35, pitch: 7, duration: 1),
      _EpicMelodyNote(bar: 9, startBeat: 36, pitch: 5, duration: 2),
      _EpicMelodyNote(bar: 9, startBeat: 38, pitch: 7, duration: 2),
      _EpicMelodyNote(bar: 10, startBeat: 40, pitch: 12, duration: 4),
      _EpicMelodyNote(bar: 11, startBeat: 44, pitch: 15, duration: 2),
      _EpicMelodyNote(bar: 11, startBeat: 46, pitch: 12, duration: 2),
      _EpicMelodyNote(bar: 12, startBeat: 48, pitch: 10, duration: 2),
      _EpicMelodyNote(bar: 12, startBeat: 50, pitch: 7, duration: 2),
      _EpicMelodyNote(bar: 13, startBeat: 52, pitch: 5, duration: 2),
      _EpicMelodyNote(bar: 13, startBeat: 54, pitch: 3, duration: 2),
      _EpicMelodyNote(bar: 14, startBeat: 56, pitch: 0, duration: 4),
      _EpicMelodyNote(bar: 15, startBeat: 60, pitch: 7, duration: 4),

      // Breakdown section - sparse but emotional
      _EpicMelodyNote(bar: 17, startBeat: 68, pitch: 12, duration: 4),
      _EpicMelodyNote(bar: 19, startBeat: 76, pitch: 10, duration: 4),
      _EpicMelodyNote(bar: 21, startBeat: 84, pitch: 7, duration: 4),
      _EpicMelodyNote(bar: 23, startBeat: 92, pitch: 5, duration: 4),

      // Final drop (bars 24-31) - MAXIMUM POWER
      _EpicMelodyNote(bar: 24, startBeat: 96, pitch: 12, duration: 1),
      _EpicMelodyNote(bar: 24, startBeat: 97, pitch: 15, duration: 1),
      _EpicMelodyNote(bar: 24, startBeat: 98, pitch: 17, duration: 2),
      _EpicMelodyNote(bar: 25, startBeat: 100, pitch: 19, duration: 2),
      _EpicMelodyNote(bar: 25, startBeat: 102, pitch: 17, duration: 2),
      _EpicMelodyNote(bar: 26, startBeat: 104, pitch: 15, duration: 2),
      _EpicMelodyNote(bar: 26, startBeat: 106, pitch: 12, duration: 2),
      _EpicMelodyNote(bar: 27, startBeat: 108, pitch: 10, duration: 2),
      _EpicMelodyNote(bar: 27, startBeat: 110, pitch: 12, duration: 2),
      _EpicMelodyNote(bar: 28, startBeat: 112, pitch: 17, duration: 4),
      _EpicMelodyNote(bar: 29, startBeat: 116, pitch: 19, duration: 2),
      _EpicMelodyNote(bar: 29, startBeat: 118, pitch: 17, duration: 2),
      _EpicMelodyNote(bar: 30, startBeat: 120, pitch: 15, duration: 2),
      _EpicMelodyNote(bar: 30, startBeat: 122, pitch: 12, duration: 2),
      _EpicMelodyNote(bar: 31, startBeat: 124, pitch: 12, duration: 4),
    ];
  }

  /// Trigger victory fanfare
  Future<void> playVictory() async {
    await stop();
    // Generate and play a short victory sting
    final victoryData = _generateVictoryStinger();
    final player = AudioPlayer();

    if (_tempDir != null) {
      final file = File('${_tempDir!.path}/victory.wav');
      await file.writeAsBytes(victoryData);
      await player.play(DeviceFileSource(file.path), volume: _volume);
      await Future.delayed(const Duration(seconds: 3));
    }
    player.dispose();
  }

  /// Trigger defeat sound
  Future<void> playDefeat() async {
    await stop();
    final defeatData = _generateDefeatStinger();
    final player = AudioPlayer();

    if (_tempDir != null) {
      final file = File('${_tempDir!.path}/defeat.wav');
      await file.writeAsBytes(defeatData);
      await player.play(DeviceFileSource(file.path), volume: _volume);
      await Future.delayed(const Duration(seconds: 2));
    }
    player.dispose();
  }

  String _normalizeMixProfile(String profile) {
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

  double _cinematicDuckNow() {
    if (_cinematicDuckUntilMicros <= 0 || _cinematicDuckAmount <= 0) {
      return 0.0;
    }
    final now = DateTime.now().microsecondsSinceEpoch;
    if (now >= _cinematicDuckUntilMicros) {
      _cinematicDuckUntilMicros = 0;
      _cinematicDuckAmount = 0.0;
      return 0.0;
    }
    return _cinematicDuckAmount;
  }

  _LayerMix _calculateLayerMix() {
    final profile = switch (_mixProfile) {
      'low' => const [0.88, 0.84, 1.08, 0.8, 0.82],
      'medium' => const [0.94, 0.92, 1.02, 0.9, 0.9],
      'high' => const [1.0, 1.0, 1.0, 1.0, 1.0],
      'extreme' => const [1.08, 1.12, 0.94, 1.14, 1.12],
      _ => const [1.0, 1.0, 1.0, 1.0, 1.0],
    };

    var bassMix = (0.4 + (_intensity * 0.4)) * profile[0];
    var leadMix = (0.2 + (_intensity * 0.5)) * profile[1];
    var padMix = (0.6 - (_intensity * 0.3)) * profile[2];
    var drumMix = (0.3 + (_intensity * 0.5)) * profile[3];
    var arpMix = (0.3 + (_intensity * 0.3)) * profile[4];

    if (_bossLeitmotifActive) {
      final worldMood = switch (_leitmotifWorld) {
        1 => const [0.06, 0.04, -0.02],
        2 => const [0.08, 0.06, -0.03],
        3 => const [0.09, 0.08, -0.04],
        4 => const [0.11, 0.1, -0.05],
        5 => const [0.14, 0.12, -0.08],
        6 => const [0.12, 0.1, -0.06],
        7 => const [0.13, 0.11, -0.07],
        8 => const [0.15, 0.13, -0.08],
        _ => const [0.1, 0.08, -0.04],
      };
      final phaseBoost = (_bossPhase - 1).clamp(0, 3) * 0.07;
      leadMix += worldMood[0] + phaseBoost;
      drumMix += worldMood[1] + phaseBoost;
      arpMix += 0.05 + phaseBoost * 0.6;
      bassMix += 0.04 + phaseBoost * 0.3;
      padMix += worldMood[2] - phaseBoost * 0.3;
    }

    final duck = _cinematicDuckNow();
    final global = (1.0 - duck).clamp(0.35, 1.0);
    return _LayerMix(
      bass: bassMix.clamp(0.12, 1.45),
      lead: leadMix.clamp(0.1, 1.5),
      pad: padMix.clamp(0.08, 1.25),
      drum: drumMix.clamp(0.08, 1.55),
      arp: arpMix.clamp(0.08, 1.5),
      global: global,
    );
  }

  void _updateLayerVolumes() {
    final mix = _calculateLayerMix();
    _lastBassMix = mix.bass;
    _lastLeadMix = mix.lead;
    _lastPadMix = mix.pad;
    _lastDrumMix = mix.drum;
    _lastArpMix = mix.arp;
    _lastGlobalMix = mix.global;

    if (!_initialized) return;

    final base = _volume * mix.global;
    _bassPlayer?.setVolume(base * mix.bass);
    _leadPlayer?.setVolume(base * mix.lead);
    _padPlayer?.setVolume(base * mix.pad);
    _drumPlayer?.setVolume(base * mix.drum);
    _arpeggioPlayer?.setVolume(base * mix.arp);
    _finalBossPlayer?.setVolume(
        (_volume * (0.9 + _intensity * 0.2) * mix.global).clamp(0.0, 1.0));
    _mainMenuPlayer?.setVolume(
        (_volume * (0.92 + (1.0 - _intensity) * 0.08) * mix.global)
            .clamp(0.0, 1.0));
  }

  Future<void> _generateWorldTracks(int worldId) async {
    final bpm = _worldBPM[worldId] ?? 120;
    final rootNote = _worldRootNotes[worldId] ?? 36;
    final theme = _worldThemes[worldId] ?? WorldSoundTheme.neonBlue;

    if (kDebugMode) {
      debugPrint(
          'Generating tracks for world $worldId (BPM: $bpm, Root: $rootNote)');
    }

    // Generate each layer and save to temp files
    await _saveTrackToFile(
        'bass_$worldId', _generateBassTrack(bpm, rootNote, theme));
    await _saveTrackToFile(
        'lead_$worldId', _generateLeadTrack(bpm, rootNote, theme));
    await _saveTrackToFile(
        'pad_$worldId', _generatePadTrack(bpm, rootNote, theme));
    await _saveTrackToFile('drum_$worldId', _generateDrumTrack(bpm, theme));
    await _saveTrackToFile(
        'arp_$worldId', _generateArpeggioTrack(bpm, rootNote, theme));

    if (kDebugMode) {
      debugPrint('Tracks generated and saved to ${_tempDir?.path}');
    }
  }

  /// Save generated audio bytes to a temp file for reliable playback
  Future<void> _saveTrackToFile(String trackName, Uint8List wavData) async {
    if (_tempDir == null) {
      if (kDebugMode) {
        debugPrint(
            'ProceduralMusicService: Cannot save $trackName - temp dir is null');
      }
      return;
    }

    try {
      final file = File('${_tempDir!.path}/$trackName.wav');
      await file.writeAsBytes(wavData);
      _trackFilePaths[trackName] = file.path;

      if (kDebugMode) {
        debugPrint(
            'Saved track: $trackName (${wavData.length} bytes) -> ${file.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ProceduralMusicService: Error saving $trackName: $e');
      }
    }
  }

  Future<void> _startAllLayers() async {
    final worldId = _currentWorld;

    // Use DeviceFileSource for more reliable playback
    final bassPath = _trackFilePaths['bass_$worldId'];
    final leadPath = _trackFilePaths['lead_$worldId'];
    final padPath = _trackFilePaths['pad_$worldId'];
    final drumPath = _trackFilePaths['drum_$worldId'];
    final arpPath = _trackFilePaths['arp_$worldId'];

    try {
      if (bassPath != null) {
        await _bassPlayer?.play(DeviceFileSource(bassPath));
        if (kDebugMode) debugPrint('Bass layer started');
      }
      if (leadPath != null) {
        await _leadPlayer?.play(DeviceFileSource(leadPath));
        if (kDebugMode) debugPrint('Lead layer started');
      }
      if (padPath != null) {
        await _padPlayer?.play(DeviceFileSource(padPath));
        if (kDebugMode) debugPrint('Pad layer started');
      }
      if (drumPath != null) {
        await _drumPlayer?.play(DeviceFileSource(drumPath));
        if (kDebugMode) debugPrint('Drum layer started');
      }
      if (arpPath != null) {
        await _arpeggioPlayer?.play(DeviceFileSource(arpPath));
        if (kDebugMode) debugPrint('Arpeggio layer started');
      }

      _updateLayerVolumes();

      if (kDebugMode) {
        debugPrint('All layers started for world $worldId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ProceduralMusicService: Error starting layers: $e');
      }
    }
  }

  // ============================================================
  // TRACK GENERATION - The heart of procedural music
  // ============================================================

  Uint8List _generateBassTrack(int bpm, int rootNote, WorldSoundTheme theme) {
    // 8 bars of bass (loop point)
    final beatsPerBar = 4;
    final bars = 8;
    final totalBeats = bars * beatsPerBar;
    final beatDuration = 60.0 / bpm;
    final totalDuration = totalBeats * beatDuration;

    final samples = (totalDuration * _sampleRate).toInt();
    final leftChannel = Float32List(samples);
    final rightChannel = Float32List(samples);

    // Bass pattern: typical synthwave pulsing bass
    // Pattern: root on 1, fifth on 3, octave hits
    final pattern = _getBassPattern(theme);

    for (int beat = 0; beat < totalBeats; beat++) {
      final patternIndex = beat % pattern.length;
      final noteOffset = pattern[patternIndex];

      if (noteOffset >= -100) {
        // -100 = rest
        final noteFreq = _midiToFreq(rootNote + noteOffset);
        final startSample = (beat * beatDuration * _sampleRate).toInt();
        final noteDuration = beatDuration * 0.8;
        final noteSamples = (noteDuration * _sampleRate).toInt();

        _renderBassNote(
          leftChannel,
          rightChannel,
          startSample,
          noteSamples,
          noteFreq,
          theme,
        );
      }
    }

    return _mixToStereoSource(leftChannel, rightChannel);
  }

  Uint8List _generateLeadTrack(int bpm, int rootNote, WorldSoundTheme theme) {
    final beatsPerBar = 4;
    final bars = 8;
    final totalBeats = bars * beatsPerBar;
    final beatDuration = 60.0 / bpm;
    final totalDuration = totalBeats * beatDuration;

    final samples = (totalDuration * _sampleRate).toInt();
    final leftChannel = Float32List(samples);
    final rightChannel = Float32List(samples);

    // Lead melody - longer notes, uses scale
    // Inspired by TRON Legacy synth leads
    final melody = _generateMelody(totalBeats, theme);
    final leadOctave = rootNote + 24; // 2 octaves up

    for (int i = 0; i < melody.length; i++) {
      final note = melody[i];
      if (note.pitch >= 0) {
        final noteFreq = _midiToFreq(
            leadOctave + _minorScale[note.pitch % _minorScale.length]);
        final startSample =
            (note.startBeat * beatDuration * _sampleRate).toInt();
        final noteSamples =
            (note.duration * beatDuration * _sampleRate).toInt();

        _renderLeadNote(
          leftChannel,
          rightChannel,
          startSample,
          noteSamples,
          noteFreq,
          theme,
        );
      }
    }

    return _mixToStereoSource(leftChannel, rightChannel);
  }

  Uint8List _generatePadTrack(int bpm, int rootNote, WorldSoundTheme theme) {
    final beatsPerBar = 4;
    final bars = 8;
    final totalBeats = bars * beatsPerBar;
    final beatDuration = 60.0 / bpm;
    final totalDuration = totalBeats * beatDuration;

    final samples = (totalDuration * _sampleRate).toInt();
    final leftChannel = Float32List(samples);
    final rightChannel = Float32List(samples);

    // Atmospheric pad - sustained chords
    // Changes every 2 bars
    final padOctave = rootNote + 12;
    final chordProgression = _getChordProgression(theme);

    for (int bar = 0; bar < bars; bar++) {
      final chordIndex = (bar ~/ 2) % chordProgression.length;
      final chord = chordProgression[chordIndex];
      final startSample =
          (bar * beatsPerBar * beatDuration * _sampleRate).toInt();
      final chordSamples = (beatsPerBar * beatDuration * _sampleRate).toInt();

      // Render each note in the chord
      for (final interval in chord) {
        final noteFreq = _midiToFreq(padOctave + interval);
        _renderPadNote(
          leftChannel,
          rightChannel,
          startSample,
          chordSamples,
          noteFreq,
          theme,
        );
      }
    }

    return _mixToStereoSource(leftChannel, rightChannel);
  }

  Uint8List _generateDrumTrack(int bpm, WorldSoundTheme theme) {
    final beatsPerBar = 4;
    final bars = 8;
    final totalBeats = bars * beatsPerBar;
    final beatDuration = 60.0 / bpm;
    final totalDuration = totalBeats * beatDuration;

    final samples = (totalDuration * _sampleRate).toInt();
    final leftChannel = Float32List(samples);
    final rightChannel = Float32List(samples);

    // Drum pattern - electronic kick, snare, hi-hat
    // Daft Punk style four-on-the-floor with syncopation

    for (int beat = 0; beat < totalBeats; beat++) {
      final subBeat = beat % 4;
      final startSample = (beat * beatDuration * _sampleRate).toInt();

      // Kick on 1 and 3
      if (subBeat == 0 || subBeat == 2) {
        _renderKick(leftChannel, rightChannel, startSample, theme);
      }

      // Snare on 2 and 4
      if (subBeat == 1 || subBeat == 3) {
        _renderSnare(leftChannel, rightChannel, startSample, theme);
      }

      // Hi-hat on every eighth note
      final eighthDuration = beatDuration / 2;
      _renderHiHat(leftChannel, rightChannel, startSample, theme);
      final offbeatSample =
          startSample + (eighthDuration * _sampleRate).toInt();
      if (offbeatSample < samples) {
        _renderHiHat(leftChannel, rightChannel, offbeatSample, theme,
            open: beat % 8 == 7);
      }
    }

    return _mixToStereoSource(leftChannel, rightChannel);
  }

  Uint8List _generateArpeggioTrack(
      int bpm, int rootNote, WorldSoundTheme theme) {
    final beatsPerBar = 4;
    final bars = 8;
    final totalBeats = bars * beatsPerBar;
    final beatDuration = 60.0 / bpm;
    final totalDuration = totalBeats * beatDuration;

    final samples = (totalDuration * _sampleRate).toInt();
    final leftChannel = Float32List(samples);
    final rightChannel = Float32List(samples);

    // Arpeggio - TRON style rapid note sequences
    final arpOctave = rootNote + 24;
    final arpPattern = _getArpeggioPattern(theme);
    final notesPerBeat = 4; // 16th notes
    final noteLength = beatDuration / notesPerBeat;

    final chordProgression = _getChordProgression(theme);

    for (int beat = 0; beat < totalBeats; beat++) {
      final bar = beat ~/ beatsPerBar;
      final chordIndex = (bar ~/ 2) % chordProgression.length;
      final chord = chordProgression[chordIndex];

      for (int sub = 0; sub < notesPerBeat; sub++) {
        final patternIndex = (beat * notesPerBeat + sub) % arpPattern.length;
        final arpNote = arpPattern[patternIndex];

        if (arpNote >= 0 && arpNote < chord.length) {
          final interval = chord[arpNote % chord.length];
          final noteFreq = _midiToFreq(arpOctave + interval);
          final startSample =
              ((beat * beatDuration + sub * noteLength) * _sampleRate).toInt();
          final noteSamples = (noteLength * 0.7 * _sampleRate).toInt();

          _renderArpNote(
            leftChannel,
            rightChannel,
            startSample,
            noteSamples,
            noteFreq,
            theme,
          );
        }
      }
    }

    return _mixToStereoSource(leftChannel, rightChannel);
  }

  // ============================================================
  // SOUND SYNTHESIS METHODS
  // ============================================================

  void _renderBassNote(
    Float32List left,
    Float32List right,
    int startSample,
    int numSamples,
    double frequency,
    WorldSoundTheme theme,
  ) {
    for (int i = 0; i < numSamples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final envelope = _adsrEnvelope(i, numSamples, 0.01, 0.1, 0.7, 0.2);

      // Sub bass (sine) + punch (saw)
      final sub = math.sin(2 * math.pi * frequency * t);
      final saw = 2.0 * ((frequency * t) % 1.0) - 1.0;

      // Filter the saw for warmth
      final filtered = saw * 0.3;

      final sample = (sub * 0.6 + filtered * 0.4) * envelope * 0.5;

      left[startSample + i] += sample;
      right[startSample + i] += sample;
    }
  }

  void _renderLeadNote(
    Float32List left,
    Float32List right,
    int startSample,
    int numSamples,
    double frequency,
    WorldSoundTheme theme,
  ) {
    // Vibrato parameters
    final vibratoRate = 5.0;
    final vibratoDepth = 3.0;

    for (int i = 0; i < numSamples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final envelope = _adsrEnvelope(i, numSamples, 0.05, 0.15, 0.6, 0.3);

      // Add vibrato after attack
      final vibratoStart = numSamples * 0.2;
      final vibrato = i > vibratoStart
          ? math.sin(2 * math.pi * vibratoRate * t) * vibratoDepth
          : 0.0;

      final freq = frequency + vibrato;

      // Supersaw-like sound (detuned saws)
      double sample = 0;
      for (int voice = 0; voice < 3; voice++) {
        final detune = (voice - 1) * 3.0; // -3, 0, +3 Hz
        final voiceFreq = freq + detune;
        sample += (2.0 * ((voiceFreq * t) % 1.0) - 1.0) / 3.0;
      }

      sample *= envelope * 0.35;

      // Stereo spread
      final pan = math.sin(t * 0.5) * 0.3;
      left[startSample + i] += sample * (0.5 - pan);
      right[startSample + i] += sample * (0.5 + pan);
    }
  }

  void _renderPadNote(
    Float32List left,
    Float32List right,
    int startSample,
    int numSamples,
    double frequency,
    WorldSoundTheme theme,
  ) {
    for (int i = 0; i < numSamples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final envelope = _adsrEnvelope(i, numSamples, 0.3, 0.2, 0.8, 0.5);

      // Soft pad with slight chorus
      double sample = 0;
      for (int voice = 0; voice < 4; voice++) {
        final detune = (voice - 1.5) * 1.5;
        final phaseOffset = voice * 0.25;
        final voiceFreq = frequency + detune;
        // Triangle wave for smooth pad
        final phase = (voiceFreq * t + phaseOffset) % 1.0;
        sample += (4.0 * (phase < 0.5 ? phase : 1.0 - phase) - 1.0) / 4.0;
      }

      sample *= envelope * 0.15;

      // Wide stereo
      final pan = math.sin(t * 0.3 + frequency * 0.01) * 0.4;
      left[startSample + i] += sample * (0.5 - pan);
      right[startSample + i] += sample * (0.5 + pan);
    }
  }

  void _renderArpNote(
    Float32List left,
    Float32List right,
    int startSample,
    int numSamples,
    double frequency,
    WorldSoundTheme theme,
  ) {
    for (int i = 0; i < numSamples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final envelope = _adsrEnvelope(i, numSamples, 0.005, 0.05, 0.3, 0.1);

      // Sharp square wave for classic arp sound
      final square = math.sin(2 * math.pi * frequency * t) > 0 ? 1.0 : -1.0;

      final sample = square * envelope * 0.2;

      // Ping-pong panning based on note
      final pan = (startSample / _sampleRate) % 2 < 1 ? 0.3 : -0.3;
      left[startSample + i] += sample * (0.5 - pan);
      right[startSample + i] += sample * (0.5 + pan);
    }
  }

  void _renderKick(
    Float32List left,
    Float32List right,
    int startSample,
    WorldSoundTheme theme,
  ) {
    final duration = 0.15;
    final samples = (duration * _sampleRate).toInt();

    for (int i = 0; i < samples && startSample + i < left.length; i++) {
      final t = i / _sampleRate;
      final progress = i / samples;

      // Pitch drops from 150Hz to 50Hz
      final freq = 150.0 - (100.0 * progress);
      final sample = math.sin(2 * math.pi * freq * t);

      // Quick decay
      final envelope = math.pow(1.0 - progress, 2.0);

      final value = sample * envelope * 0.6;
      left[startSample + i] += value;
      right[startSample + i] += value;
    }
  }

  void _renderSnare(
    Float32List left,
    Float32List right,
    int startSample,
    WorldSoundTheme theme,
  ) {
    final duration = 0.12;
    final samples = (duration * _sampleRate).toInt();

    for (int i = 0; i < samples && startSample + i < left.length; i++) {
      final progress = i / samples;

      // Body tone
      final t = i / _sampleRate;
      final body = math.sin(2 * math.pi * 200 * t) * 0.4;

      // Noise for snare character
      final noise = (_random.nextDouble() * 2 - 1) * 0.6;

      final envelope = math.pow(1.0 - progress, 1.5);
      final value = (body + noise) * envelope * 0.35;

      left[startSample + i] += value;
      right[startSample + i] += value;
    }
  }

  void _renderHiHat(
    Float32List left,
    Float32List right,
    int startSample,
    WorldSoundTheme theme, {
    bool open = false,
  }) {
    final duration = open ? 0.15 : 0.05;
    final samples = (duration * _sampleRate).toInt();

    for (int i = 0; i < samples && startSample + i < left.length; i++) {
      final progress = i / samples;

      // High frequency noise
      final noise = _random.nextDouble() * 2 - 1;
      final envelope = math.pow(1.0 - progress, open ? 1.0 : 3.0);

      final value = noise * envelope * 0.15;

      // Slight stereo spread
      left[startSample + i] += value * 0.6;
      right[startSample + i] += value * 0.4;
    }
  }

  // ============================================================
  // VICTORY/DEFEAT STINGERS
  // ============================================================

  Uint8List _generateVictoryStinger() {
    final duration = 2.5;
    final samples = (duration * _sampleRate).toInt();
    final leftChannel = Float32List(samples);
    final rightChannel = Float32List(samples);

    // Epic rising arpeggio with fanfare
    final notes = [60, 64, 67, 72, 76, 79, 84]; // C major arpeggio up 2 octaves
    final noteLength = 0.2;

    for (int i = 0; i < notes.length; i++) {
      final freq = _midiToFreq(notes[i].toDouble());
      final startSample = (i * noteLength * _sampleRate).toInt();
      final noteSamples = (noteLength * 2 * _sampleRate).toInt();

      for (int j = 0; j < noteSamples && startSample + j < samples; j++) {
        final t = j / _sampleRate;
        final envelope = _adsrEnvelope(j, noteSamples, 0.02, 0.1, 0.5, 0.5);

        // Bright supersaw
        double sample = 0;
        for (int v = 0; v < 5; v++) {
          final detune = (v - 2) * 4.0;
          sample += (2.0 * (((freq + detune) * t) % 1.0) - 1.0) / 5.0;
        }

        sample *= envelope * 0.3;
        leftChannel[startSample + j] += sample;
        rightChannel[startSample + j] += sample;
      }
    }

    return _mixToStereoSource(leftChannel, rightChannel);
  }

  Uint8List _generateDefeatStinger() {
    final duration = 1.5;
    final samples = (duration * _sampleRate).toInt();
    final leftChannel = Float32List(samples);
    final rightChannel = Float32List(samples);

    // Descending minor chord with fade
    final notes = [60, 55, 51, 48]; // Descending
    final noteLength = 0.3;

    for (int i = 0; i < notes.length; i++) {
      final freq = _midiToFreq(notes[i].toDouble());
      final startSample = (i * noteLength * _sampleRate).toInt();
      final noteSamples = (noteLength * 1.5 * _sampleRate).toInt();

      for (int j = 0; j < noteSamples && startSample + j < samples; j++) {
        final t = j / _sampleRate;
        final envelope = _adsrEnvelope(j, noteSamples, 0.05, 0.2, 0.4, 0.6);

        // Dark filtered saw
        final saw = 2.0 * ((freq * t) % 1.0) - 1.0;
        final sample = saw * envelope * 0.25 * (1.0 - i * 0.15);

        leftChannel[startSample + j] += sample;
        rightChannel[startSample + j] += sample;
      }
    }

    return _mixToStereoSource(leftChannel, rightChannel);
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  double _midiToFreq(num midiNote) {
    return 440.0 * math.pow(2, (midiNote.toDouble() - 69) / 12);
  }

  double _adsrEnvelope(int sample, int totalSamples, double attack,
      double decay, double sustain, double release) {
    final progress = sample / totalSamples;

    if (progress < attack) {
      return progress / attack;
    } else if (progress < attack + decay) {
      final decayProgress = (progress - attack) / decay;
      return 1.0 - (1.0 - sustain) * decayProgress;
    } else if (progress < 1.0 - release) {
      return sustain;
    } else {
      final releaseProgress = (progress - (1.0 - release)) / release;
      return sustain * (1.0 - releaseProgress);
    }
  }

  List<int> _getBassPattern(WorldSoundTheme theme) {
    switch (theme) {
      case WorldSoundTheme.neonBlue:
        return [0, -100, 0, -100, 7, -100, 5, -100]; // Simple pulse
      case WorldSoundTheme.magentaPulse:
        return [0, 0, -100, 0, 7, -100, 5, 7]; // More active
      case WorldSoundTheme.cyanStorm:
        return [0, -100, 3, -100, 5, -100, 7, -100]; // Walking bass
      case WorldSoundTheme.orangeHeat:
        return [0, 0, 0, -100, 7, 7, 5, -100]; // Aggressive
      case WorldSoundTheme.voidPurple:
        return [0, -100, -100, 0, -100, 7, -100, 5]; // Dark, sparse
    }
  }

  List<List<int>> _getChordProgression(WorldSoundTheme theme) {
    switch (theme) {
      case WorldSoundTheme.neonBlue:
        return [
          [0, 3, 7],
          [5, 8, 12],
          [3, 7, 10],
          [7, 10, 14]
        ]; // i - VI - iv - VII
      case WorldSoundTheme.magentaPulse:
        return [
          [0, 3, 7],
          [7, 10, 14],
          [5, 8, 12],
          [3, 7, 10]
        ]; // i - VII - VI - iv
      case WorldSoundTheme.cyanStorm:
        return [
          [0, 3, 7],
          [3, 7, 10],
          [5, 8, 12],
          [0, 3, 7]
        ]; // i - iv - VI - i
      case WorldSoundTheme.orangeHeat:
        return [
          [0, 3, 7, 10],
          [5, 8, 12, 15],
          [7, 10, 14, 17],
          [0, 3, 7, 10]
        ]; // Extended chords
      case WorldSoundTheme.voidPurple:
        return [
          [0, 3, 7],
          [1, 4, 8],
          [3, 6, 10],
          [0, 3, 7]
        ]; // Darker progression
    }
  }

  List<int> _getArpeggioPattern(WorldSoundTheme theme) {
    switch (theme) {
      case WorldSoundTheme.neonBlue:
        return [0, 1, 2, 1, 0, 1, 2, 1]; // Up-down simple
      case WorldSoundTheme.magentaPulse:
        return [0, 2, 1, 2, 0, 2, 1, 2]; // Syncopated
      case WorldSoundTheme.cyanStorm:
        return [0, 1, 2, -1, 0, 1, 2, -1]; // With rests
      case WorldSoundTheme.orangeHeat:
        return [0, 0, 1, 2, 2, 1, 0, 2]; // Repeated notes
      case WorldSoundTheme.voidPurple:
        return [0, -1, 2, -1, 1, -1, 2, -1]; // Sparse, dark
    }
  }

  List<_MelodyNote> _generateMelody(int totalBeats, WorldSoundTheme theme) {
    final melody = <_MelodyNote>[];
    double currentBeat = 0;

    while (currentBeat < totalBeats) {
      // Random note from pentatonic scale
      final pitch = _random.nextInt(_pentatonicMinor.length);

      // Random duration (1, 2, or 4 beats)
      final durations = [1.0, 2.0, 4.0];
      final duration = durations[_random.nextInt(durations.length)];

      // Sometimes rest instead
      if (_random.nextDouble() < 0.3) {
        melody.add(
            _MelodyNote(pitch: -1, startBeat: currentBeat, duration: duration));
      } else {
        melody.add(_MelodyNote(
            pitch: pitch, startBeat: currentBeat, duration: duration));
      }

      currentBeat += duration;
    }

    return melody;
  }

  Uint8List _mixToStereoSource(Float32List left, Float32List right) {
    _masterStereoChannels(left, right);

    // Normalize and convert to 16-bit PCM
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

    return _addWavHeaderStereo(pcm16.buffer.asUint8List());
  }

  void _masterStereoChannels(Float32List left, Float32List right) {
    if (left.isEmpty || right.isEmpty) return;

    // Subtle M/S widening improves perceived depth without phasey artifacts.
    const stereoWidth = 1.06;
    for (int i = 0; i < left.length; i++) {
      final mid = (left[i] + right[i]) * 0.5;
      final side = (left[i] - right[i]) * 0.5 * stereoWidth;
      left[i] = (mid + side).clamp(-1.0, 1.0);
      right[i] = (mid - side).clamp(-1.0, 1.0);
    }

    _applyStereoDcBlock(left, right);
    _applyStereoSoftLimiter(left, right, threshold: 0.9);
    _normalizeStereoLoudness(left, right, targetRms: 0.24, targetPeak: 0.9);
  }

  void _applyStereoDcBlock(Float32List left, Float32List right) {
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

  void _applyStereoSoftLimiter(
    Float32List left,
    Float32List right, {
    required double threshold,
  }) {
    final t = threshold.clamp(0.6, 0.96);
    const curve = 4.2;
    for (int i = 0; i < left.length; i++) {
      left[i] = _softLimitedSample(left[i], threshold: t, curve: curve);
      right[i] = _softLimitedSample(right[i], threshold: t, curve: curve);
    }
  }

  double _softLimitedSample(
    double sample, {
    required double threshold,
    required double curve,
  }) {
    final absSample = sample.abs();
    if (absSample <= threshold) return sample;
    final compressed = threshold +
        ((absSample - threshold) / (1.0 + (absSample - threshold) * curve));
    return sample < 0 ? -compressed : compressed;
  }

  void _normalizeStereoLoudness(
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
    var gain = rms > 0.000001 ? (targetRms / rms).clamp(0.74, 1.34) : 1.0;
    final postPeak = peak * gain;
    if (postPeak > targetPeak) {
      gain *= targetPeak / postPeak;
    }

    for (int i = 0; i < left.length; i++) {
      left[i] = (left[i] * gain).clamp(-1.0, 1.0);
      right[i] = (right[i] * gain).clamp(-1.0, 1.0);
    }
  }

  Uint8List _addWavHeaderStereo(Uint8List pcmBytes) {
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

  @visibleForTesting
  bool get debugBossLeitmotifActive => _bossLeitmotifActive;

  @visibleForTesting
  int get debugBossPhase => _bossPhase;

  @visibleForTesting
  double get debugCinematicDuckAmount => _cinematicDuckNow();

  @visibleForTesting
  List<double> get debugLastLayerMix => [
        _lastBassMix,
        _lastLeadMix,
        _lastPadMix,
        _lastDrumMix,
        _lastArpMix,
        _lastGlobalMix
      ];

  Future<void> dispose() async {
    await stop();
    await stopMainMenuMusic();

    // CRITICAL: Delete all temp files to free disk space
    await cleanupTempFiles();

    await _safeDisposePlayer(_bassPlayer);
    await _safeDisposePlayer(_leadPlayer);
    await _safeDisposePlayer(_padPlayer);
    await _safeDisposePlayer(_drumPlayer);
    await _safeDisposePlayer(_arpeggioPlayer);
    await _safeDisposePlayer(_finalBossPlayer);
    await _safeDisposePlayer(_mainMenuPlayer);
    _bassPlayer = null;
    _leadPlayer = null;
    _padPlayer = null;
    _drumPlayer = null;
    _arpeggioPlayer = null;
    _finalBossPlayer = null;
    _mainMenuPlayer = null;
    _mixProfile = 'high';
    _bossLeitmotifActive = false;
    _bossPhase = 1;
    _leitmotifWorld = 1;
    _cinematicDuckAmount = 0.0;
    _cinematicDuckUntilMicros = 0;
    _lastBassMix = 0.0;
    _lastLeadMix = 0.0;
    _lastPadMix = 0.0;
    _lastDrumMix = 0.0;
    _lastArpMix = 0.0;
    _lastGlobalMix = 0.0;
    _initialized = false;

    if (kDebugMode) {
      debugPrint('ProceduralMusicService disposed');
    }
  }

  Future<void> _safeDisposePlayer(AudioPlayer? player) async {
    if (player == null) return;
    try {
      await player.dispose();
    } catch (_) {
      // Best effort cleanup; ignore double-dispose errors.
    }
  }
}

/// Sound theme per world - affects all instrument characteristics
enum WorldSoundTheme {
  neonBlue, // Clean, digital, tutorial vibe
  magentaPulse, // Energetic, driving
  cyanStorm, // Atmospheric, intense
  orangeHeat, // Aggressive, heavy
  voidPurple, // Dark, epic final boss
}

/// Internal class for melody generation
class _MelodyNote {
  final int pitch; // -1 = rest
  final double startBeat;
  final double duration;

  const _MelodyNote({
    required this.pitch,
    required this.startBeat,
    required this.duration,
  });
}

/// Section markers for the epic final boss track
enum _EpicSection {
  intro, // Bars 0-3: Atmospheric build
  build, // Bars 4-7: Rising tension
  drop, // Bars 8-15: First climax
  breakdown, // Bars 16-23: Emotional respite
  finalDrop, // Bars 24-31: MAXIMUM POWER
}

/// Section markers for the main menu track "NEON HORIZON"
enum _MenuSection {
  ambientIntro, // Bars 0-7: Atmospheric, sparse entry
  build, // Bars 8-15: Rising energy, introducing elements
  mainTheme, // Bars 16-31: Full epic theme with melody
  breakdown, // Bars 32-39: Emotional respite, sparse
  reprise, // Bars 40-47: Triumphant return, full power
}

/// Melody note for the epic final boss track
class _EpicMelodyNote {
  final int bar;
  final int startBeat;
  final int pitch;
  final int duration;

  const _EpicMelodyNote({
    required this.bar,
    required this.startBeat,
    required this.pitch,
    required this.duration,
  });
}
