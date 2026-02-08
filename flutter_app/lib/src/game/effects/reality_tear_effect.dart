import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../entities/enemy.dart';

/// Reality tear/dimensional portal effect for enemy spawn portals or special abilities.
/// Features 7 layers of visual effects:
/// - Layer 1: Central void (pure black with chromatic edge)
/// - Layer 2: Tear edges (jagged, glitchy outline)
/// - Layer 3: Reality distortion waves emanating outward
/// - Layer 4: Fragments of "broken" reality floating nearby
/// - Layer 5: Electric energy crackling around edges
/// - Layer 6: Dimensional particles being sucked in
/// - Layer 7: Flickering between realities (overlay glitch)
class RealityTearEffect extends PositionComponent {
  RealityTearEffect._internal({
    required Vector2 position,
    required double tearSize,
    required double duration,
    required bool reduceFx,
    required bool lowFx,
  }) {
    _reset(
      position: position,
      tearSize: tearSize,
      duration: duration,
      reduceFx: reduceFx,
      lowFx: lowFx,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OBJECT POOL CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  static const int maxPool = 16;
  static const int maxActive = 12;
  static final List<RealityTearEffect> _pool = [];
  static int _activeCount = 0;
  static double fxScale = 1.0;
  static int get activeCount => _activeCount;
  static final Map<int, MaskFilter> _blurCache = {};

  static MaskFilter _blur(double sigma) {
    var key = sigma.round();
    if (key < 1) key = 1;
    if (key > 40) key = 40;
    return _blurCache.putIfAbsent(
      key,
      () => MaskFilter.blur(BlurStyle.normal, key.toDouble()),
    );
  }

  /// Clear the static pool to prevent memory accumulation between games
  static void clearPool() {
    _pool.clear();
    _activeCount = 0;
  }

  /// Spawn a new reality tear effect from the pool
  static RealityTearEffect? spawn({
    required Vector2 position,
    double tearSize = 60.0,
    double duration = 2.0,
    bool reduceFx = false,
    bool lowFx = false,
  }) {
    if (_activeCount >= maxActive) return null;
    RealityTearEffect effect;
    if (_pool.isNotEmpty) {
      effect = _pool.removeLast();
      effect._reset(
        position: position,
        tearSize: tearSize,
        duration: duration,
        reduceFx: reduceFx,
        lowFx: lowFx,
      );
    } else {
      effect = RealityTearEffect._internal(
        position: position,
        tearSize: tearSize,
        duration: duration,
        reduceFx: reduceFx,
        lowFx: lowFx,
      );
    }
    effect._markActive();
    return effect;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EFFECT PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary portal color (purple)
  static const Color primaryColor = Color(0xFF8B00FF);

  /// Secondary portal color (cyan)
  static const Color secondaryColor = Color(0xFF00FFFF);

  /// Void color (pure black)
  static const Color voidColor = Color(0xFF000000);

  double tearSize = 60.0;
  double duration = 2.0;
  bool reduceFx = false;
  bool lowFx = false;

  final List<_RealityFragment> _fragments = [];
  final List<_ElectricArc> _electricArcs = [];
  final List<_DimensionalParticle> _particles = [];
  final List<_DistortionWave> _waves = [];
  double _time = 0;
  int _rngState = 0x9e3779b9;
  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }

  double _nextUnit() => _lcgNext() / 0x7fffffff;
  int _nextInt(int max) => max <= 0 ? 0 : _lcgNext() % max;
  bool _nextBool() => (_lcgNext() & 1) == 0;
  bool _counted = false;
  bool _inPool = false;
  double _offscreenAccumulator = 0;
  static const double _offscreenUpdateInterval = 0.12;

  // Tear opening/closing animation
  double _openProgress = 0;
  double _flickerIntensity = 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════

  // Layer 1: Central void paints
  final Paint _voidCorePaint = Paint()..color = voidColor;
  final Paint _voidGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _chromaticEdgePaintPurple = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  final Paint _chromaticEdgePaintCyan = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  // Layer 2: Tear edges paints
  final Paint _tearEdgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  final Paint _tearEdgeGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _glitchLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  // Layer 3: Distortion waves paints
  final Paint _waveRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  final Paint _waveGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  // Layer 4: Reality fragments paints
  final Paint _fragmentPaint = Paint();
  final Paint _fragmentGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  final Paint _fragmentOutlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  // Layer 5: Electric energy paints
  final Paint _electricPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  final Paint _electricGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

  // Layer 6: Dimensional particles paints
  final Paint _particlePaint = Paint();
  final Paint _particleTrailPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  // Layer 7: Glitch overlay paints
  final Paint _glitchOverlayPaint = Paint()..blendMode = BlendMode.screen;
  final Paint _scanlinePaint = Paint();
  final Paint _glitchBlockPaint = Paint();

  // Reusable paths
  final Path _tearPath = Path();
  final Path _fragmentPath = Path();
  final Path _electricPath = Path();

  void _markActive() {
    if (_counted) return;
    _counted = true;
    _inPool = false;
    _activeCount++;
  }

  void _reset({
    required Vector2 position,
    required double tearSize,
    required double duration,
    required bool reduceFx,
    required bool lowFx,
  }) {
    this.position.setFrom(position);
    anchor = Anchor.center;
    this.tearSize = tearSize;
    this.duration = duration;
    this.reduceFx = reduceFx;
    this.lowFx = lowFx;
    _rngState = (position.hashCode ^ (tearSize * 1000).round() ^ 0x9e3779b9) &
        0x7fffffff;
    _time = 0;
    _openProgress = 0;
    _flickerIntensity = 0;
    _fragments.clear();
    _electricArcs.clear();
    _particles.clear();
    _waves.clear();
    _initializeFragments();
    _initializeElectricArcs();
    _initializeParticles();
    _initializeWaves();
  }

  void _initializeFragments() {
    final fragmentCount = lowFx ? 0 : (reduceFx ? 6 : 12);
    for (int i = 0; i < fragmentCount; i++) {
      final angle = (i / fragmentCount) * math.pi * 2 + _nextUnit() * 0.5;
      final distance = tearSize * (0.8 + _nextUnit() * 0.6);
      _fragments.add(_RealityFragment(
        angle: angle,
        baseDistance: distance,
        size: 4 + _nextUnit() * 8,
        rotation: _nextUnit() * math.pi * 2,
        rotationSpeed: (_nextUnit() - 0.5) * 4,
        orbitSpeed: (_nextUnit() - 0.5) * 0.8,
        shapeType: _nextInt(4),
        phaseOffset: _nextUnit() * math.pi * 2,
      ));
    }
  }

  void _initializeElectricArcs() {
    final arcCount = lowFx ? 0 : (reduceFx ? 4 : 8);
    for (int i = 0; i < arcCount; i++) {
      final angle = (i / arcCount) * math.pi * 2 + _nextUnit() * 0.3;
      _electricArcs.add(_ElectricArc(
        angle: angle,
        length: tearSize * (0.4 + _nextUnit() * 0.4),
        width: 1.5 + _nextUnit() * 1.5,
        lifetime: 0.1 + _nextUnit() * 0.15,
        segments: 3 + _nextInt(3),
        respawnDelay: _nextUnit() * 0.3,
      ));
    }
  }

  void _initializeParticles() {
    final particleCount = lowFx ? 0 : (reduceFx ? 12 : 24);
    if (particleCount == 0) return;

    final angularJitter = math.pi / particleCount;
    for (int i = 0; i < particleCount; i++) {
      // Even angular distribution with subtle jitter keeps the ring coverage
      // visually uniform while still feeling organic.
      final baseAngle = (i / particleCount) * math.pi * 2;
      final angle = baseAngle + (_nextUnit() - 0.5) * angularJitter;
      final startDistance = tearSize * (1.5 + _nextUnit() * 1.5);
      _particles.add(_DimensionalParticle(
        angle: angle,
        distance: startDistance,
        maxDistance: startDistance,
        speed: 30 + _nextUnit() * 40,
        size: 1.5 + _nextUnit() * 2.5,
        lifetime: 0.8 + _nextUnit() * 0.6,
        phaseOffset: _nextUnit() * math.pi * 2,
      ));
    }
  }

  void _initializeWaves() {
    final waveCount = lowFx ? 1 : (reduceFx ? 2 : 4);
    for (int i = 0; i < waveCount; i++) {
      _waves.add(_DistortionWave(
        delay: i * 0.4,
        speed: 60 + _nextUnit() * 30,
        maxRadius: tearSize * 2.5,
      ));
    }
  }

  int _scaledCount(int base, {bool allowZero = false}) {
    final scaled = (base * fxScale).round();
    if (scaled <= 0 && !allowZero) {
      return 1;
    }
    return scaled;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isOffscreen()) {
      _offscreenAccumulator += dt;
      if (_offscreenAccumulator < _offscreenUpdateInterval) {
        return;
      }
      dt = _offscreenAccumulator;
      _offscreenAccumulator = 0;
    } else if (_offscreenAccumulator > 0) {
      dt += _offscreenAccumulator;
      _offscreenAccumulator = 0;
    }

    _time += dt;
    final progress = _time / duration;

    if (progress >= 1.0) {
      _recycle();
      return;
    }

    // Tear opening animation (opens in first 20%, stays open, closes in last 20%)
    if (progress < 0.2) {
      _openProgress = progress / 0.2;
    } else if (progress > 0.8) {
      _openProgress = (1.0 - progress) / 0.2;
    } else {
      _openProgress = 1.0;
    }

    // Flicker intensity based on progress
    _flickerIntensity = math.sin(_time * 20) * 0.2 + 0.8;
    if (_nextUnit() < 0.05) {
      _flickerIntensity = 0.3 + _nextUnit() * 0.4;
    }

    // Update fragments
    for (final fragment in _fragments) {
      fragment.update(dt, _time);
    }

    // Update electric arcs
    for (final arc in _electricArcs) {
      arc.update(dt, _nextUnit);
    }

    // Update particles (moving toward center)
    for (final particle in _particles) {
      particle.update(dt, _time);
    }

    // Update distortion waves
    for (final wave in _waves) {
      wave.update(dt, _time);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_isOffscreen()) return;
    super.render(canvas);

    if (_openProgress <= 0) return;

    final effectiveSize = tearSize * _openProgress;
    if (effectiveSize <= 1) return;
    if (_fragments.isEmpty &&
        _electricArcs.isEmpty &&
        _particles.isEmpty &&
        _waves.isEmpty &&
        reduceFx) {
      return;
    }

    // Layer 7: Flickering reality overlay (background)
    _drawGlitchBackground(canvas, effectiveSize);

    // Layer 3: Reality distortion waves
    _drawDistortionWaves(canvas, effectiveSize);

    // Layer 6: Dimensional particles being sucked in
    if (!lowFx) {
      _drawDimensionalParticles(canvas, effectiveSize);
    }

    // Layer 4: Fragments of broken reality
    if (!lowFx) {
      _drawRealityFragments(canvas, effectiveSize);
    }

    // Layer 5: Electric energy crackling
    if (!lowFx) {
      _drawElectricEnergy(canvas, effectiveSize);
    }

    // Layer 2: Tear edges (jagged outline)
    _drawTearEdges(canvas, effectiveSize);

    // Layer 1: Central void with chromatic edge
    _drawCentralVoid(canvas, effectiveSize);

    // Layer 7: Glitch overlay (foreground)
    if (!reduceFx) {
      _drawGlitchOverlay(canvas, effectiveSize);
    }
  }

  bool _isOffscreen({double padding = 120}) {
    if (Enemy.screenSize.isZero()) return false;
    if (Enemy.screenScale <= 0) return false;
    final screenX = Enemy.screenOffset.x + position.x * Enemy.screenScale;
    final screenY = Enemy.screenOffset.y + position.y * Enemy.screenScale;
    return screenX < -padding ||
        screenY < -padding ||
        screenX > Enemy.screenSize.x + padding ||
        screenY > Enemy.screenSize.y + padding;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 1: CENTRAL VOID
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawCentralVoid(Canvas canvas, double effectiveSize) {
    final voidRadius = effectiveSize * 0.4;

    // Chromatic aberration edge - purple offset
    _chromaticEdgePaintPurple.color =
        primaryColor.withOpacity(0.6 * _flickerIntensity);
    canvas.drawCircle(
      const Offset(-3, -1),
      voidRadius * 1.15,
      _chromaticEdgePaintPurple,
    );

    // Chromatic aberration edge - cyan offset
    _chromaticEdgePaintCyan.color =
        secondaryColor.withOpacity(0.6 * _flickerIntensity);
    canvas.drawCircle(
      const Offset(3, 1),
      voidRadius * 1.15,
      _chromaticEdgePaintCyan,
    );

    // Void glow (dark purple)
    _voidGlowPaint.color = primaryColor.withOpacity(0.3 * _flickerIntensity);
    canvas.drawCircle(Offset.zero, voidRadius * 1.3, _voidGlowPaint);

    // Pure black void center
    _voidCorePaint.color = voidColor;
    canvas.drawCircle(Offset.zero, voidRadius, _voidCorePaint);

    // Inner void gradient (darker at center)
    final innerGlowRadius = voidRadius * 0.6;
    _voidGlowPaint.color = const Color(0xFF1A001A).withOpacity(0.8);
    canvas.drawCircle(Offset.zero, innerGlowRadius, _voidGlowPaint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 2: TEAR EDGES (JAGGED GLITCHY OUTLINE)
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawTearEdges(Canvas canvas, double effectiveSize) {
    final baseRadius = effectiveSize * 0.45;
    final jaggedPoints = lowFx ? 12 : 24;

    // Build jagged tear path
    _tearPath.reset();
    for (int i = 0; i <= jaggedPoints; i++) {
      final angle = (i / jaggedPoints) * math.pi * 2;
      final jitter =
          math.sin(_time * 15 + i * 3) * 4 + math.sin(_time * 8 + i * 7) * 2;
      final glitchOffset = _nextUnit() < 0.1 ? _nextUnit() * 6 : 0;
      final radius = baseRadius + jitter + glitchOffset;

      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;

      if (i == 0) {
        _tearPath.moveTo(x, y);
      } else {
        _tearPath.lineTo(x, y);
      }
    }
    _tearPath.close();

    // Outer glow
    _tearEdgeGlowPaint.color =
        primaryColor.withOpacity(0.4 * _flickerIntensity);
    canvas.drawPath(_tearPath, _tearEdgeGlowPaint);

    // Main edge - alternating colors
    _tearEdgePaint.color = Color.lerp(
      primaryColor,
      secondaryColor,
      (math.sin(_time * 5) + 1) / 2,
    )!
        .withOpacity(0.8 * _flickerIntensity);
    canvas.drawPath(_tearPath, _tearEdgePaint);

    // Glitch lines extending from tear
    if (!reduceFx) {
      final glitchLineCount = 6;
      for (int i = 0; i < glitchLineCount; i++) {
        if (_nextUnit() > 0.7) continue;

        final angle = (i / glitchLineCount) * math.pi * 2 + _time * 2;
        final startRadius = baseRadius + 5;
        final endRadius = baseRadius + 10 + _nextUnit() * 15;

        final startX = math.cos(angle) * startRadius;
        final startY = math.sin(angle) * startRadius;
        final endX = math.cos(angle) * endRadius;
        final endY = math.sin(angle) * endRadius;

        _glitchLinePaint.color =
            secondaryColor.withOpacity(0.6 * _flickerIntensity);
        canvas.drawLine(
            Offset(startX, startY), Offset(endX, endY), _glitchLinePaint);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 3: REALITY DISTORTION WAVES
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawDistortionWaves(Canvas canvas, double effectiveSize) {
    if (_waves.isEmpty) return;
    for (final wave in _waves) {
      if (!wave.isActive) continue;

      final waveAlpha = wave.alpha * _flickerIntensity;
      if (waveAlpha <= 0.05) continue;

      // Outer distortion ring
      _waveGlowPaint.color = primaryColor.withOpacity(waveAlpha * 0.3);
      canvas.drawCircle(Offset.zero, wave.currentRadius, _waveGlowPaint);

      // Inner wave ring - purple
      _waveRingPaint.color = primaryColor.withOpacity(waveAlpha * 0.6);
      canvas.drawCircle(Offset.zero, wave.currentRadius, _waveRingPaint);

      // Secondary wave ring - cyan (slightly offset)
      _waveRingPaint.color = secondaryColor.withOpacity(waveAlpha * 0.4);
      canvas.drawCircle(Offset.zero, wave.currentRadius * 0.95, _waveRingPaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 4: REALITY FRAGMENTS
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawRealityFragments(Canvas canvas, double effectiveSize) {
    final fragmentAlpha = _flickerIntensity * 0.8;
    if (fragmentAlpha <= 0.05) return;
    for (final fragment in _fragments) {
      final x = math.cos(fragment.currentAngle) * fragment.currentDistance;
      final y = math.sin(fragment.currentAngle) * fragment.currentDistance;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(fragment.currentRotation);

      // Build fragment shape
      _fragmentPath.reset();
      switch (fragment.shapeType) {
        case 0: // Triangle
          _fragmentPath.moveTo(0, -fragment.size / 2);
          _fragmentPath.lineTo(-fragment.size / 2, fragment.size / 2);
          _fragmentPath.lineTo(fragment.size / 2, fragment.size / 2);
          _fragmentPath.close();
          break;
        case 1: // Diamond
          _fragmentPath.moveTo(0, -fragment.size / 2);
          _fragmentPath.lineTo(fragment.size / 3, 0);
          _fragmentPath.lineTo(0, fragment.size / 2);
          _fragmentPath.lineTo(-fragment.size / 3, 0);
          _fragmentPath.close();
          break;
        case 2: // Hexagon shard
          for (int i = 0; i < 6; i++) {
            final angle = i * math.pi / 3 + math.pi / 6;
            final px = math.cos(angle) * fragment.size * 0.4;
            final py = math.sin(angle) * fragment.size * 0.4;
            if (i == 0) {
              _fragmentPath.moveTo(px, py);
            } else {
              _fragmentPath.lineTo(px, py);
            }
          }
          _fragmentPath.close();
          break;
        default: // Rectangle
          _fragmentPath.addRect(Rect.fromCenter(
            center: Offset.zero,
            width: fragment.size * 0.8,
            height: fragment.size * 0.5,
          ));
      }

      // Fragment glow
      final fragmentColor = Color.lerp(
        primaryColor,
        secondaryColor,
        (math.sin(fragment.phaseOffset + _time * 3) + 1) / 2,
      )!;
      _fragmentGlowPaint.color = fragmentColor.withOpacity(fragmentAlpha * 0.4);
      canvas.drawPath(_fragmentPath, _fragmentGlowPaint);

      // Fragment fill (dark with color tint)
      _fragmentPaint.color = Color.lerp(
        voidColor,
        fragmentColor,
        0.3,
      )!
          .withOpacity(fragmentAlpha * 0.8);
      canvas.drawPath(_fragmentPath, _fragmentPaint);

      // Fragment outline
      _fragmentOutlinePaint.color =
          fragmentColor.withOpacity(fragmentAlpha * 0.7);
      canvas.drawPath(_fragmentPath, _fragmentOutlinePaint);

      canvas.restore();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 5: ELECTRIC ENERGY CRACKLING
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawElectricEnergy(Canvas canvas, double effectiveSize) {
    final baseRadius = effectiveSize * 0.45;
    if (_electricArcs.isEmpty) return;
    if (_flickerIntensity <= 0.05) return;

    for (final arc in _electricArcs) {
      if (!arc.isActive) continue;

      final arcAlpha = arc.alpha * _flickerIntensity;
      if (arcAlpha <= 0.1) continue;

      // Starting point on the tear edge
      final startX = math.cos(arc.angle) * baseRadius;
      final startY = math.sin(arc.angle) * baseRadius;

      // Build lightning path
      _electricPath.reset();
      _electricPath.moveTo(startX, startY);

      double currentX = startX;
      double currentY = startY;
      final direction = arc.angle + math.pi; // Point outward

      for (int seg = 0; seg < arc.segments; seg++) {
        final segLength = arc.length / arc.segments;
        final perpOffset = (_nextUnit() - 0.5) * 12;

        currentX += math.cos(direction) * segLength +
            math.cos(direction + math.pi / 2) * perpOffset;
        currentY += math.sin(direction) * segLength +
            math.sin(direction + math.pi / 2) * perpOffset;

        _electricPath.lineTo(currentX, currentY);
      }

      // Electric glow (cyan)
      _electricGlowPaint
        ..color = secondaryColor.withOpacity(arcAlpha * 0.5)
        ..strokeWidth = arc.width * 3;
      canvas.drawPath(_electricPath, _electricGlowPaint);

      // Electric core (white/cyan)
      _electricPaint
        ..color =
            Color.lerp(Colors.white, secondaryColor, 0.3)!.withOpacity(arcAlpha)
        ..strokeWidth = arc.width;
      canvas.drawPath(_electricPath, _electricPaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 6: DIMENSIONAL PARTICLES BEING SUCKED IN
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawDimensionalParticles(Canvas canvas, double effectiveSize) {
    if (_particles.isEmpty) return;
    if (_flickerIntensity <= 0.05) return;
    for (final particle in _particles) {
      if (!particle.isAlive) continue;

      final particleAlpha = particle.alpha * _flickerIntensity;
      if (particleAlpha <= 0.05) continue;

      final x = math.cos(particle.angle) * particle.distance;
      final y = math.sin(particle.angle) * particle.distance;

      // Trail toward center
      final trailLength = particle.size * 3;
      final trailEndX =
          math.cos(particle.angle) * (particle.distance + trailLength);
      final trailEndY =
          math.sin(particle.angle) * (particle.distance + trailLength);

      final particleColor = Color.lerp(
        primaryColor,
        secondaryColor,
        (math.sin(particle.phaseOffset + _time * 5) + 1) / 2,
      )!;

      _particleTrailPaint
        ..color = particleColor.withOpacity(particleAlpha * 0.4)
        ..strokeWidth = particle.size * 0.8;
      canvas.drawLine(
          Offset(x, y), Offset(trailEndX, trailEndY), _particleTrailPaint);

      // Particle core
      _particlePaint.color = particleColor.withOpacity(particleAlpha);
      canvas.drawCircle(Offset(x, y), particle.size, _particlePaint);

      // Particle glow
      _particlePaint.color = Colors.white.withOpacity(particleAlpha * 0.6);
      canvas.drawCircle(Offset(x, y), particle.size * 0.5, _particlePaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER 7: GLITCH OVERLAY (FLICKERING BETWEEN REALITIES)
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawGlitchBackground(Canvas canvas, double effectiveSize) {
    // Ambient glow around the entire effect
    _voidGlowPaint.color = primaryColor.withOpacity(0.15 * _flickerIntensity);
    _voidGlowPaint.maskFilter = _blur(effectiveSize * 0.5);
    canvas.drawCircle(Offset.zero, effectiveSize * 1.5, _voidGlowPaint);
    _voidGlowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  }

  void _drawGlitchOverlay(Canvas canvas, double effectiveSize) {
    // Scanlines
    final scanlineCount = 8;
    for (int i = 0; i < scanlineCount; i++) {
      if (_nextUnit() > 0.6) continue;

      final yOffset = (math.sin(_time * 25 + i * 2) * effectiveSize * 0.8);
      final scanlineWidth = effectiveSize * (0.3 + _nextUnit() * 0.5);
      final scanlineAlpha = _flickerIntensity * 0.2 * _nextUnit();

      // Purple scanline
      _scanlinePaint.color = primaryColor.withOpacity(scanlineAlpha);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(-2, yOffset),
          width: scanlineWidth,
          height: 2,
        ),
        _scanlinePaint,
      );

      // Cyan scanline (offset)
      _scanlinePaint.color = secondaryColor.withOpacity(scanlineAlpha * 0.8);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(2, yOffset),
          width: scanlineWidth,
          height: 2,
        ),
        _scanlinePaint,
      );
    }

    // Random glitch blocks
    if (_nextUnit() < 0.15) {
      final blockCount = 3 + _nextInt(3);
      for (int i = 0; i < blockCount; i++) {
        final bx = (_nextUnit() - 0.5) * effectiveSize * 2;
        final by = (_nextUnit() - 0.5) * effectiveSize * 2;
        final bw = 4 + _nextUnit() * 12;
        final bh = 2 + _nextUnit() * 6;

        final blockColor = _nextBool() ? primaryColor : secondaryColor;
        _glitchBlockPaint.color =
            blockColor.withOpacity(0.4 * _flickerIntensity);
        canvas.drawRect(
          Rect.fromCenter(center: Offset(bx, by), width: bw, height: bh),
          _glitchBlockPaint,
        );
      }
    }

    // Chromatic aberration overlay circles
    if (_nextUnit() < 0.1) {
      final chromeRadius = effectiveSize * (0.3 + _nextUnit() * 0.3);
      _glitchOverlayPaint.color = primaryColor.withOpacity(0.15);
      canvas.drawCircle(
          const Offset(-4, -2), chromeRadius, _glitchOverlayPaint);
      _glitchOverlayPaint.color = secondaryColor.withOpacity(0.12);
      canvas.drawCircle(const Offset(4, 2), chromeRadius, _glitchOverlayPaint);
    }
  }

  void _recycle() {
    if (_counted) {
      if (_activeCount > 0) {
        _activeCount -= 1;
      }
      _counted = false;
    }
    if (parent != null) {
      removeFromParent();
    }
    if (_inPool) return;
    if (_pool.length < maxPool) {
      _inPool = true;
      _pool.add(this);
    }
  }

  @override
  void onRemove() {
    if (_counted) {
      if (_activeCount > 0) {
        _activeCount -= 1;
      }
      _counted = false;
    }
    super.onRemove();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER CLASSES FOR EFFECT ELEMENTS
// ═══════════════════════════════════════════════════════════════════════════════

class _RealityFragment {
  _RealityFragment({
    required this.angle,
    required this.baseDistance,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.orbitSpeed,
    required this.shapeType,
    required this.phaseOffset,
  })  : currentAngle = angle,
        currentDistance = baseDistance,
        currentRotation = rotation;

  final double angle;
  final double baseDistance;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final double orbitSpeed;
  final int shapeType;
  final double phaseOffset;

  double currentAngle;
  double currentDistance;
  double currentRotation;

  void update(double dt, double time) {
    currentRotation += rotationSpeed * dt;
    currentAngle = angle + math.sin(time * orbitSpeed + phaseOffset) * 0.3;
    currentDistance = baseDistance + math.sin(time * 2 + phaseOffset) * 5;
  }
}

class _ElectricArc {
  _ElectricArc({
    required this.angle,
    required this.length,
    required this.width,
    required this.lifetime,
    required this.segments,
    required this.respawnDelay,
  })  : _time = 0,
        _currentLifetime = lifetime;

  final double angle;
  final double length;
  final double width;
  final double lifetime;
  final int segments;
  final double respawnDelay;

  double _time;
  double _currentLifetime;

  bool get isActive => _time < _currentLifetime && _time > 0;
  double get alpha => isActive ? (1 - _time / _currentLifetime) : 0;

  void update(double dt, double Function() nextUnit) {
    _time += dt;

    // Respawn arc after delay
    if (_time > _currentLifetime + respawnDelay) {
      _time = 0;
      _currentLifetime = lifetime * (0.5 + nextUnit() * 0.5);
    }
  }
}

class _DimensionalParticle {
  _DimensionalParticle({
    required this.angle,
    required this.distance,
    required this.maxDistance,
    required this.speed,
    required this.size,
    required this.lifetime,
    required this.phaseOffset,
  }) : _time = 0;

  final double angle;
  double distance;
  final double maxDistance;
  final double speed;
  final double size;
  final double lifetime;
  final double phaseOffset;

  double _time;

  bool get isAlive => distance > 0;
  double get alpha => (distance / maxDistance).clamp(0.0, 1.0);

  void update(double dt, double time) {
    _time += dt;

    // Move toward center with slight spiral
    distance -= speed * dt;

    // Respawn when reaching center
    if (distance <= 0) {
      distance = maxDistance;
      _time = 0;
    }
  }
}

class _DistortionWave {
  _DistortionWave({
    required this.delay,
    required this.speed,
    required this.maxRadius,
  })  : _time = -delay,
        currentRadius = 0;

  final double delay;
  final double speed;
  final double maxRadius;

  double _time;
  double currentRadius;

  bool get isActive => _time >= 0 && currentRadius < maxRadius;
  double get alpha => isActive ? (1 - currentRadius / maxRadius) * 0.6 : 0;

  void update(double dt, double totalTime) {
    _time += dt;

    if (_time >= 0) {
      currentRadius += speed * dt;

      // Reset wave when it reaches max
      if (currentRadius >= maxRadius) {
        currentRadius = 0;
        _time = 0;
      }
    }
  }
}
