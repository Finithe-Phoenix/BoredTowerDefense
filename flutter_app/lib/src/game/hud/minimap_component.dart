import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bored_games_game.dart';

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

/// CYBERPUNK CORRUPTED MINIMAP - Extreme TRON aesthetic with glitch effects
class MinimapComponent extends PositionComponent with HasGameRef<BoredGamesGame> {
  MinimapComponent() {
    anchor = Anchor.topLeft;
  }

  // Base dimensions - will be scaled
  static const double baseMapSize = 130.0;
  static const double borderWidth = 2.0;
  static const double basePadding = 12.0;

  // Actual dimensions after scaling
  double mapSize = baseMapSize;
  double padding = basePadding;

  Path? _hexPath;
  Path? _innerHexPath;
  Path? _routePath;
  PathMetric? _routeMetric;
  double _routeLength = 0;
  double _geometryMapSize = -1;
  List<Offset>? _cornerDots;
  TextPainter? _titlePainter;
  String _titleText = '';
  int _titleColorValue = 0;
  TextPainter? _enemyCountPainter;
  String _enemyCountText = '';
  int _enemyCountColorValue = 0;
  int _enemyShadowColorValue = 0;
  TextPainter? _towerCountPainter;
  String _towerCountText = '';
  Picture? _scanlineLayer;
  double _scanlineLayerSize = -1;

  // Animation states
  double _time = 0;
  double _scanAngle = 0;
  double _pulsePhase = 0;
  double _glitchTimer = 0;
  double _glitchIntensity = 0;
  int _glitchFrame = 0;
  bool _isGlitching = false;
  double _corruptionLevel = 0;

  // Cached random for consistent glitch patterns
  final _random = _FastRng();

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _bgPaint = Paint();
  static final Paint _gridPaint = Paint()..strokeWidth = 0.5;
  static final Paint _scanPaint = Paint()..strokeWidth = 2..strokeCap = StrokeCap.round;
  static final Paint _glowPaint = Paint();
  static final Paint _framePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _noisePaint = Paint();
  static final Paint _outerGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _pathPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _pathGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _towerFillPaint = Paint();
  static final Paint _towerGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _enemyPaint = Paint();
  static final Paint _enemyGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _bossPaint = Paint();
  static final Paint _bossGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _radarSweepPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _corruptionPaint = Paint();
  static final Paint _statusPaint = Paint();
  static final Paint _glitchBarPaint = Paint();
  static final Paint _streamPaint = Paint()..strokeWidth = 1;
  static const List<String> _glitchChars = ['#', '@', '!', '%', '&', '*', '?', '/', '\\', '|'];

  static int _lcgSeed(int seed, int salt) => (seed ^ salt) & 0x7fffffff;
  static int _lcgNext(int state) => (state * 1664525 + 1013904223) & 0x7fffffff;
  static double _lcgUnit(int state) => state / 0x7fffffff;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _scanAngle += dt * 2.5;
    _pulsePhase += dt * 4;

    // Glitch timing - random bursts
    _glitchTimer += dt;
    if (_glitchTimer > 2.0 + _random.nextDouble() * 3.0) {
      _glitchTimer = 0;
      _isGlitching = true;
      _glitchIntensity = 0.5 + _random.nextDouble() * 0.5;
      _glitchFrame = _random.nextInt(1000);
    }

    if (_isGlitching) {
      _glitchIntensity -= dt * 3;
      if (_glitchIntensity <= 0) {
        _isGlitching = false;
        _glitchIntensity = 0;
      }
    }

    // Corruption level based on enemy count
    final enemyCount = gameRef.enemyManager.aliveCount;
    _corruptionLevel = (enemyCount / 30.0).clamp(0.0, 1.0);
  }

  @override
  void onRemove() {
    _scanlineLayer?.dispose();
    _scanlineLayer = null;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (gameRef.hideHud || gameRef.focusModeActive) return;

    final screenWidth = gameRef.size.x;
    final screenHeight = gameRef.size.y;
    final compact = gameRef.isTouchLayout || screenWidth < 820;

    if (compact && screenWidth < 600) return;

    // Calculate responsive scale
    final baseWidth = 1920.0;
    final baseHeight = 1080.0;
    final scaleX = (screenWidth / baseWidth).clamp(0.5, 1.2);
    final scaleY = (screenHeight / baseHeight).clamp(0.5, 1.2);
    final scale = math.min(scaleX, scaleY);

    // Update dimensions based on scale
    mapSize = (baseMapSize * scale).clamp(80.0, 140.0);
    padding = basePadding * scale;
    _ensureGeometry();

    final mapX = screenWidth - mapSize - padding;
    final mapY = 120.0 * scale; // Responsive top offset

    canvas.save();
    canvas.translate(mapX, mapY);

    // Apply glitch offset to entire minimap
    if (_isGlitching && _glitchIntensity > 0.3) {
      canvas.translate(
        (math.sin(_time * 50) * 3 * _glitchIntensity),
        (math.cos(_time * 40) * 1.5 * _glitchIntensity),
      );
    }

    _renderCorruptedBackground(canvas);
    _renderCyberGrid(canvas);
    _renderGlitchScanlines(canvas);
    _renderDataStream(canvas);
    _renderPath(canvas);
    _renderTowers(canvas);
    _renderEnemies(canvas);
    _renderRadarSweep(canvas);
    _renderCorruptionOverlay(canvas);
    _renderCyberFrame(canvas);
    _renderStatusIndicators(canvas);
    _renderGlitchBars(canvas);

    canvas.restore();
  }

  void _renderCorruptedBackground(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, mapSize, mapSize);

    // Multi-layer corrupted background
    final baseGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Color.lerp(const Color(0xFF001515), const Color(0xFF150505), _corruptionLevel)!.withOpacity(0.95),
        Color.lerp(const Color(0xFF000a0a), const Color(0xFF0a0000), _corruptionLevel)!.withOpacity(0.98),
        Colors.black.withOpacity(0.99),
      ],
    ).createShader(rect);

    // Clip to hexagonal shape for cyber effect
    final hexPath = _hexPath ?? _createHexagonalPath(mapSize / 2, mapSize / 2, mapSize / 2 - 2);
    canvas.save();
    canvas.clipPath(hexPath);

    canvas.drawRect(rect, _bgPaint..shader = baseGradient);

    // Noise texture overlay
    _renderNoiseTexture(canvas, rect);

    canvas.restore();

    // Outer glow - changes color based on threat
    final glowColor = Color.lerp(
      const Color(0xFF00FFFF),
      const Color(0xFFFF0044),
      _corruptionLevel,
    )!;

    _glowPaint
      ..color = glowColor.withOpacity(0.2 + _pulsePhase.sin().abs() * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawPath(hexPath, _glowPaint);
  }

  void _renderNoiseTexture(Canvas canvas, Rect rect) {
    if (!_isGlitching) return;

    var state = _lcgSeed(_glitchFrame, 0x6c8e9cf5);

    for (int i = 0; i < 50; i++) {
      state = _lcgNext(state);
      final x = _lcgUnit(state) * mapSize;
      state = _lcgNext(state);
      final y = _lcgUnit(state) * mapSize;
      state = _lcgNext(state);
      final size = 1.0 + _lcgUnit(state) * 2;
      state = _lcgNext(state);
      final useWhite = (state & 0x1) == 0;
      state = _lcgNext(state);
      final alpha = _lcgUnit(state) * 0.3 * _glitchIntensity;

      _noisePaint.color =
          (useWhite ? Colors.white : const Color(0xFF00FFFF)).withOpacity(alpha);

      canvas.drawRect(Rect.fromLTWH(x, y, size, size), _noisePaint);
    }
  }

  void _renderCyberGrid(Canvas canvas) {
    final primaryColor = Color.lerp(
      const Color(0xFF00FFFF),
      const Color(0xFFFF0044),
      _corruptionLevel * 0.5,
    )!;

    const divisions = 8;
    final step = mapSize / divisions;

    // Animated grid with pulse
    for (int i = 0; i <= divisions; i++) {
      final pulseOffset = math.sin(_pulsePhase + i * 0.3) * 0.3;
      final opacity = (0.08 + pulseOffset * 0.05).clamp(0.02, 0.15);

      _gridPaint.color = primaryColor.withOpacity(opacity);

      // Vertical lines with glitch offset
      var xOffset = 0.0;
      if (_isGlitching && i % 2 == 0) {
        xOffset = math.sin(_time * 30 + i) * 2 * _glitchIntensity;
      }

      canvas.drawLine(
        Offset(i * step + xOffset, 0),
        Offset(i * step + xOffset, mapSize),
        _gridPaint,
      );

      // Horizontal lines
      var yOffset = 0.0;
      if (_isGlitching && i % 3 == 0) {
        yOffset = math.cos(_time * 25 + i) * 2 * _glitchIntensity;
      }

      canvas.drawLine(
        Offset(0, i * step + yOffset),
        Offset(mapSize, i * step + yOffset),
        _gridPaint,
      );
    }

    // Cyber crosshair at center
    final centerX = mapSize / 2;
    final centerY = mapSize / 2;
    final crossPulse = 0.4 + math.sin(_pulsePhase * 2) * 0.2;

    _statusPaint
      ..color = primaryColor.withOpacity(crossPulse)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Animated crosshair
    final crossSize = 10.0 + math.sin(_pulsePhase) * 2;
    canvas.drawLine(Offset(centerX - crossSize, centerY), Offset(centerX - 4, centerY), _statusPaint);
    canvas.drawLine(Offset(centerX + 4, centerY), Offset(centerX + crossSize, centerY), _statusPaint);
    canvas.drawLine(Offset(centerX, centerY - crossSize), Offset(centerX, centerY - 4), _statusPaint);
    canvas.drawLine(Offset(centerX, centerY + 4), Offset(centerX, centerY + crossSize), _statusPaint);

    // Center dot
    _glowPaint
      ..color = primaryColor.withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 2, _glowPaint);
  }

  void _renderGlitchScanlines(Canvas canvas) {
    _ensureScanlineLayer();

    if (_scanlineLayer != null) {
      canvas.drawPicture(_scanlineLayer!);
    }

    _scanPaint
      ..color = Colors.black.withOpacity(0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Static scanlines
    // Moving scanline
    final scanY = (_time * 40) % mapSize;
    _radarSweepPaint
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF00FFFF).withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 5, mapSize, 10))
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, scanY - 5, mapSize, 10), _radarSweepPaint);

    // Corruption scanlines (red, when enemies present)
    if (_corruptionLevel > 0.2) {
      final corruptScanY = (mapSize - (_time * 25) % mapSize);
      _corruptionPaint
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFFFF0044).withOpacity(0.08 * _corruptionLevel),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, corruptScanY - 8, mapSize, 16))
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(0, corruptScanY - 8, mapSize, 16),
        _corruptionPaint,
      );
    }
  }

  void _renderDataStream(Canvas canvas) {
    // Vertical data streams (Matrix-style)
    var state = _lcgSeed(42, 0x51c3e9d7);

    for (int i = 0; i < 5; i++) {
      state = _lcgNext(state);
      final x = _lcgUnit(state) * mapSize;
      state = _lcgNext(state);
      final speed = 20 + _lcgUnit(state) * 30;
      final baseY = (_time * speed + i * 50) % (mapSize + 30) - 15;

      for (int j = 0; j < 8; j++) {
        final y = baseY + j * 4;
        if (y < 0 || y > mapSize) continue;

        final alpha = (1.0 - j / 8.0) * 0.3;
        _streamPaint.color = const Color(0xFF00FFFF).withOpacity(alpha);
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 2), _streamPaint);
      }
    }
  }

  void _renderPath(Canvas canvas) {
    // Get actual path from game if available, otherwise show stylized path
    _pathPaint
      ..color = const Color(0xFFFF6600).withOpacity(0.4 + math.sin(_pulsePhase * 0.5) * 0.1)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Glowing path effect
    _pathGlowPaint
      ..color = const Color(0xFFFF6600).withOpacity(0.15)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Simplified S-curve path
    final path = _routePath ??
        (Path()
          ..moveTo(0, mapSize * 0.25)
          ..lineTo(mapSize * 0.25, mapSize * 0.25)
          ..lineTo(mapSize * 0.25, mapSize * 0.75)
          ..lineTo(mapSize * 0.75, mapSize * 0.75)
          ..lineTo(mapSize * 0.75, mapSize * 0.25)
          ..lineTo(mapSize, mapSize * 0.25));

    canvas.drawPath(path, _pathGlowPaint);
    canvas.drawPath(path, _pathPaint);

    // Animated dots along path
    _renderPathDots(canvas, path);
  }

  void _renderPathDots(Canvas canvas, Path path) {
    final metric = _routeMetric ??
        (() {
          final iterator = path.computeMetrics().iterator;
          return iterator.moveNext() ? iterator.current : null;
        })();
    if (metric == null) return;
    final pathLength = _routeMetric != null ? _routeLength : metric.length;

    _statusPaint
      ..color = const Color(0xFFFFAA00)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final progress = ((_time * 0.1 + i * 0.33) % 1.0);
      final tangent = metric.getTangentForOffset(progress * pathLength);

      if (tangent != null) {
        final pulse = 0.6 + math.sin(_pulsePhase + i) * 0.4;
        canvas.drawCircle(
          tangent.position,
          2 * pulse,
          _statusPaint..color = const Color(0xFFFFAA00).withOpacity(pulse),
        );
      }
    }
  }

  void _renderTowers(Canvas canvas) {
    final towers = gameRef.towerManager.towers;
    final worldSize = gameRef.worldBounds;

    for (final tower in towers) {
      final mapX = (tower.position.x / worldSize.x) * mapSize;
      final mapY = (tower.position.y / worldSize.y) * mapSize;

      // Tower range indicator (subtle)
      final rangeRadius = (tower.range / worldSize.x) * mapSize * 0.3;
      canvas.drawCircle(
        Offset(mapX, mapY),
        rangeRadius,
        _towerFillPaint
          ..color = tower.color.withOpacity(0.1)
          ..style = PaintingStyle.fill,
      );

      // Tower glow
      canvas.drawCircle(
        Offset(mapX, mapY),
        6,
        _towerGlowPaint..color = tower.color.withOpacity(0.4),
      );

      // Tower icon (hexagonal)
      _drawHexagon(canvas, mapX, mapY, 3.5, tower.color.withOpacity(0.9));

      // Pulse ring effect (based on animation timer)
      final pulseProgress = (math.sin(_pulsePhase * 2 + tower.hashCode * 0.1) + 1) / 2;
      if (pulseProgress > 0.7) {
        canvas.drawCircle(
          Offset(mapX, mapY),
          4 + pulseProgress * 4,
          _towerFillPaint
            ..color = tower.color.withOpacity(0.5 * (1 - pulseProgress))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  void _renderEnemies(Canvas canvas) {
    final enemies = gameRef.enemyManager.activeEnemies.where((e) => e.isAlive);
    final worldSize = gameRef.worldBounds;

    for (final enemy in enemies) {
      final mapX = (enemy.position.x / worldSize.x) * mapSize;
      final mapY = (enemy.position.y / worldSize.y) * mapSize;

      if (mapX < -5 || mapX > mapSize + 5 || mapY < -5 || mapY > mapSize + 5) continue;

      final isBoss = enemy.isBoss;
      final baseColor = isBoss ? const Color(0xFFFF00FF) : const Color(0xFFFF4444);
      final size = isBoss ? 5.0 : 2.5;

      // Threat pulse
      final pulse = 1.0 + math.sin(_pulsePhase * 2 + enemy.hashCode * 0.1) * 0.4;

      // Enemy glow (stronger for bosses)
      if (isBoss) {
        canvas.drawCircle(
          Offset(mapX, mapY),
          12,
          _bossGlowPaint..color = baseColor.withOpacity(0.3 * pulse),
        );

        // Boss warning ring
        canvas.drawCircle(
          Offset(mapX, mapY),
          8 + math.sin(_pulsePhase * 3) * 2,
          _bossPaint
            ..color = baseColor.withOpacity(0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }

      // Enemy dot
      canvas.drawCircle(
        Offset(mapX, mapY),
        size * pulse,
        _enemyPaint
          ..color = baseColor.withOpacity(0.9)
          ..style = PaintingStyle.fill,
      );

      // Direction indicator for enemies (based on movement direction)
      final direction = enemy.movementDirection;
      final angle = math.atan2(direction.y, direction.x);
      final indicatorLength = isBoss ? 8.0 : 5.0;
      canvas.drawLine(
        Offset(mapX, mapY),
        Offset(
          mapX + math.cos(angle) * indicatorLength,
          mapY + math.sin(angle) * indicatorLength,
        ),
        _enemyPaint
          ..color = baseColor.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _renderRadarSweep(Canvas canvas) {
    final centerX = mapSize / 2;
    final centerY = mapSize / 2;
    final scanLength = mapSize * 0.48;

    // Main sweep line
    final endX = centerX + math.cos(_scanAngle) * scanLength;
    final endY = centerY + math.sin(_scanAngle) * scanLength;

    final sweepColor = Color.lerp(
      const Color(0xFF00FFFF),
      const Color(0xFFFF0044),
      _corruptionLevel * 0.7,
    )!;

    // Sweep trail (arc)
    _radarSweepPaint
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: _scanAngle - 0.8,
        endAngle: _scanAngle,
        colors: [
          Colors.transparent,
          sweepColor.withOpacity(0.05),
          sweepColor.withOpacity(0.15),
        ],
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: scanLength))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), scanLength, _radarSweepPaint);

    // Main scan line with glow
    _glowPaint
      ..color = sweepColor.withOpacity(0.3)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(endX, endY),
      _glowPaint,
    );

    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(endX, endY),
      _scanPaint
        ..color = sweepColor.withOpacity(0.8)
        ..strokeWidth = 2,
    );

    // Scan tip glow
    canvas.drawCircle(
      Offset(endX, endY),
      4,
      _glowPaint
        ..color = sweepColor.withOpacity(0.6)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _renderCorruptionOverlay(Canvas canvas) {
    if (_corruptionLevel < 0.1) return;

    // Red vignette when corruption is high
    final vignetteGradient = RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [
        Colors.transparent,
        const Color(0xFFFF0044).withOpacity(0.1 * _corruptionLevel),
      ],
    ).createShader(Rect.fromLTWH(0, 0, mapSize, mapSize));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, mapSize, mapSize),
      _corruptionPaint
        ..shader = vignetteGradient
        ..style = PaintingStyle.fill,
    );

    // Corruption artifacts
    if (_corruptionLevel > 0.5) {
      var state = _lcgSeed((_time * 10).floor(), 0x4d4f1f2b);
      for (int i = 0; i < (_corruptionLevel * 5).floor(); i++) {
        state = _lcgNext(state);
        final x = _lcgUnit(state) * mapSize;
        state = _lcgNext(state);
        final y = _lcgUnit(state) * mapSize;
        state = _lcgNext(state);
        final w = 5 + _lcgUnit(state) * 15;

        canvas.drawRect(
          Rect.fromLTWH(x, y, w, 1),
          _corruptionPaint
            ..shader = null
            ..color = const Color(0xFFFF0044).withOpacity(0.2 * _corruptionLevel),
        );
      }
    }
  }

  void _renderCyberFrame(Canvas canvas) {
    final frameColor = Color.lerp(
      const Color(0xFF00FFFF),
      const Color(0xFFFF0044),
      _corruptionLevel * 0.5,
    )!;

    final hexPath = _hexPath ?? _createHexagonalPath(mapSize / 2, mapSize / 2, mapSize / 2 - 2);

    // Main frame
    _framePaint
      ..color = frameColor.withOpacity(0.6 + math.sin(_pulsePhase) * 0.2)
      ..strokeWidth = borderWidth;
    canvas.drawPath(hexPath, _framePaint);

    // Inner frame
    final innerHex =
        _innerHexPath ?? _createHexagonalPath(mapSize / 2, mapSize / 2, mapSize / 2 - 6);
    _framePaint
      ..color = frameColor.withOpacity(0.2)
      ..strokeWidth = 1;
    canvas.drawPath(innerHex, _framePaint);

    // Corner tech details
    _renderCornerDetails(canvas, frameColor);

    // Glitch frame displacement
    if (_isGlitching && _glitchIntensity > 0.5) {
      _framePaint
        ..color = const Color(0xFFFF0044).withOpacity(0.4 * _glitchIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(hexPath, _framePaint);
    }
  }

  void _renderCornerDetails(Canvas canvas, Color color) {
    _statusPaint
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Tech brackets at corners
    const bracketSize = 15.0;
    const offset = 8.0;

    // Top-left
    canvas.drawLine(Offset(offset, offset + bracketSize), Offset(offset, offset), _statusPaint);
    canvas.drawLine(Offset(offset, offset), Offset(offset + bracketSize, offset), _statusPaint);

    // Top-right
    canvas.drawLine(
      Offset(mapSize - offset - bracketSize, offset),
      Offset(mapSize - offset, offset),
      _statusPaint,
    );
    canvas.drawLine(
      Offset(mapSize - offset, offset),
      Offset(mapSize - offset, offset + bracketSize),
      _statusPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(offset, mapSize - offset - bracketSize),
      Offset(offset, mapSize - offset),
      _statusPaint,
    );
    canvas.drawLine(
      Offset(offset, mapSize - offset),
      Offset(offset + bracketSize, mapSize - offset),
      _statusPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(mapSize - offset - bracketSize, mapSize - offset),
      Offset(mapSize - offset, mapSize - offset),
      _statusPaint,
    );
    canvas.drawLine(
      Offset(mapSize - offset, mapSize - offset - bracketSize),
      Offset(mapSize - offset, mapSize - offset),
      _statusPaint,
    );

    // Corner dots with glow
    final dotPositions = _cornerDots ??
        [
          Offset(offset, offset),
          Offset(mapSize - offset, offset),
          Offset(offset, mapSize - offset),
          Offset(mapSize - offset, mapSize - offset),
        ];

    for (var i = 0; i < dotPositions.length; i++) {
      final pos = dotPositions[i];
      final pulse = 0.5 + math.sin(_pulsePhase + i * 1.5) * 0.5;

      canvas.drawCircle(
        pos,
        3,
        _glowPaint
          ..color = color.withOpacity(0.3 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
          ..style = PaintingStyle.fill,
      );
      _statusPaint
        ..color = color.withOpacity(pulse)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 2, _statusPaint);
    }
  }

  void _renderStatusIndicators(Canvas canvas) {
    // Title with glitch effect
    final titleColor = Color.lerp(
      const Color(0xFF00FFFF),
      const Color(0xFFFF0044),
      _corruptionLevel * 0.5,
    )!;

    String titleText = 'TACTICAL GRID';
    if (_isGlitching && _glitchIntensity > 0.6) {
      titleText = _corruptString(titleText);
    }

    final titleColorValue = titleColor.value;
    if (_titlePainter == null || _titleText != titleText || _titleColorValue != titleColorValue) {
      _titleText = titleText;
      _titleColorValue = titleColorValue;
      _titlePainter = TextPainter(
        text: TextSpan(
          text: titleText,
          style: TextStyle(
            color: titleColor.withOpacity(0.7),
            fontSize: 8,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 2,
            shadows: [Shadow(color: titleColor, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    _titlePainter!.paint(
      canvas,
      Offset((mapSize - _titlePainter!.width) / 2, mapSize + 6),
    );

    // Status indicators on sides
    _renderSideStatus(canvas, titleColor);
  }

  void _renderSideStatus(Canvas canvas, Color color) {
    // Enemy count indicator (left side)
    final enemyCount = gameRef.enemyManager.aliveCount;
    final enemyText = enemyCount.toString().padLeft(2, '0');
    final enemyColor =
        _corruptionLevel > 0.5 ? const Color(0xFFFF4444) : color;
    final enemyColorValue = enemyColor.value;
    final shadowColorValue = color.value;

    if (_enemyCountPainter == null ||
        _enemyCountText != enemyText ||
        _enemyCountColorValue != enemyColorValue ||
        _enemyShadowColorValue != shadowColorValue) {
      _enemyCountText = enemyText;
      _enemyCountColorValue = enemyColorValue;
      _enemyShadowColorValue = shadowColorValue;
      _enemyCountPainter = TextPainter(
        text: TextSpan(
          text: enemyText,
          style: TextStyle(
            color: enemyColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            shadows: [Shadow(color: color, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    // Rotate for side display
    canvas.save();
    canvas.translate(-12, mapSize / 2);
    canvas.rotate(-math.pi / 2);
    _enemyCountPainter!.paint(canvas, Offset(-_enemyCountPainter!.width / 2, 0));
    canvas.restore();

    // Tower count (right side)
    final towerCount = gameRef.towerManager.towers.length;
    final towerText = towerCount.toString().padLeft(2, '0');

    if (_towerCountPainter == null || _towerCountText != towerText) {
      _towerCountText = towerText;
      _towerCountPainter = TextPainter(
        text: TextSpan(
          text: towerText,
          style: const TextStyle(
            color: Color(0xFF00FF88),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            shadows: [Shadow(color: Color(0xFF00FF88), blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    canvas.save();
    canvas.translate(mapSize + 12, mapSize / 2);
    canvas.rotate(math.pi / 2);
    _towerCountPainter!.paint(canvas, Offset(-_towerCountPainter!.width / 2, 0));
    canvas.restore();
  }

  void _renderGlitchBars(Canvas canvas) {
    if (!_isGlitching || _glitchIntensity < 0.2) return;

    var state = _lcgSeed(_glitchFrame, 0x2e6f7b51);

    for (int i = 0; i < (5 * _glitchIntensity).floor(); i++) {
      state = _lcgNext(state);
      final y = _lcgUnit(state) * mapSize;
      state = _lcgNext(state);
      final height = 1 + _lcgUnit(state) * 3;
      state = _lcgNext(state);
      final xOffset = (_lcgUnit(state) - 0.5) * 10 * _glitchIntensity;
      state = _lcgNext(state);
      final color = (state & 0x1) == 0 ? const Color(0xFF00FFFF) : const Color(0xFFFF0044);

      canvas.drawRect(
        Rect.fromLTWH(xOffset, y, mapSize, height),
        _glitchBarPaint..color = color.withOpacity(0.2 * _glitchIntensity),
      );
    }
  }

  void _ensureGeometry() {
    if (_geometryMapSize == mapSize && _hexPath != null && _routePath != null) {
      return;
    }

    _geometryMapSize = mapSize;
    _hexPath = _createHexagonalPath(mapSize / 2, mapSize / 2, mapSize / 2 - 2);
    _innerHexPath = _createHexagonalPath(mapSize / 2, mapSize / 2, mapSize / 2 - 6);

    const offset = 8.0;
    _cornerDots = [
      const Offset(offset, offset),
      Offset(mapSize - offset, offset),
      Offset(offset, mapSize - offset),
      Offset(mapSize - offset, mapSize - offset),
    ];

    _routePath = Path()
      ..moveTo(0, mapSize * 0.25)
      ..lineTo(mapSize * 0.25, mapSize * 0.25)
      ..lineTo(mapSize * 0.25, mapSize * 0.75)
      ..lineTo(mapSize * 0.75, mapSize * 0.75)
      ..lineTo(mapSize * 0.75, mapSize * 0.25)
      ..lineTo(mapSize, mapSize * 0.25);

    final metricIterator = _routePath!.computeMetrics().iterator;
    _routeMetric = metricIterator.moveNext() ? metricIterator.current : null;
    _routeLength = _routeMetric?.length ?? 0;
  }

  void _ensureScanlineLayer() {
    if (_scanlineLayer != null && _scanlineLayerSize == mapSize) {
      return;
    }

    _scanlineLayer?.dispose();
    final recorder = PictureRecorder();
    final scanCanvas = Canvas(recorder);

    _scanPaint
      ..color = Colors.black.withOpacity(0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double y = 0; y < mapSize; y += 2) {
      scanCanvas.drawLine(Offset(0, y), Offset(mapSize, y), _scanPaint);
    }

    _scanlineLayer = recorder.endRecording();
    _scanlineLayerSize = mapSize;
  }

  // Helper methods

  Path _createHexagonalPath(double cx, double cy, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _drawHexagon(Canvas canvas, double cx, double cy, double radius, Color color) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    _towerFillPaint
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, _towerFillPaint);
  }

  String _corruptString(String input) {
    var state = _lcgSeed(_glitchFrame, 0x9e3779b9);
    final chars = input.split('');

    for (int i = 0; i < chars.length; i++) {
      state = _lcgNext(state);
      if (_lcgUnit(state) < 0.25) {
        state = _lcgNext(state);
        chars[i] = _glitchChars[state % _glitchChars.length];
      }
    }
    return chars.join();
  }
}

// Extension for sin on double
extension on double {
  double sin() => math.sin(this);
}

