import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bored_games_game.dart';

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
  final _random = math.Random();

  // Precomputed paint objects for performance
  final Paint _bgPaint = Paint();
  final Paint _gridPaint = Paint()..strokeWidth = 0.5;
  final Paint _scanPaint = Paint()..strokeWidth = 2..strokeCap = StrokeCap.round;
  final Paint _glowPaint = Paint();
  final Paint _framePaint = Paint()..style = PaintingStyle.stroke;

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
    final hexPath = _createHexagonalPath(mapSize / 2, mapSize / 2, mapSize / 2 - 2);
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

    canvas.drawPath(
      hexPath,
      _glowPaint
        ..color = glowColor.withOpacity(0.2 + _pulsePhase.sin().abs() * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  void _renderNoiseTexture(Canvas canvas, Rect rect) {
    if (!_isGlitching) return;

    final noisePaint = Paint();
    final random = math.Random(_glitchFrame);

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * mapSize;
      final y = random.nextDouble() * mapSize;
      final size = 1.0 + random.nextDouble() * 2;

      noisePaint.color = (random.nextBool() ? Colors.white : const Color(0xFF00FFFF))
          .withOpacity(random.nextDouble() * 0.3 * _glitchIntensity);

      canvas.drawRect(Rect.fromLTWH(x, y, size, size), noisePaint);
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

    final crossPaint = Paint()
      ..color = primaryColor.withOpacity(crossPulse)
      ..strokeWidth = 1.5;

    // Animated crosshair
    final crossSize = 10.0 + math.sin(_pulsePhase) * 2;
    canvas.drawLine(Offset(centerX - crossSize, centerY), Offset(centerX - 4, centerY), crossPaint);
    canvas.drawLine(Offset(centerX + 4, centerY), Offset(centerX + crossSize, centerY), crossPaint);
    canvas.drawLine(Offset(centerX, centerY - crossSize), Offset(centerX, centerY - 4), crossPaint);
    canvas.drawLine(Offset(centerX, centerY + 4), Offset(centerX, centerY + crossSize), crossPaint);

    // Center dot
    canvas.drawCircle(
      Offset(centerX, centerY),
      2,
      Paint()
        ..color = primaryColor.withOpacity(0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  void _renderGlitchScanlines(Canvas canvas) {
    final scanlinePaint = Paint()..color = Colors.black.withOpacity(0.15);

    // Static scanlines
    for (double y = 0; y < mapSize; y += 2) {
      canvas.drawLine(Offset(0, y), Offset(mapSize, y), scanlinePaint);
    }

    // Moving scanline
    final scanY = (_time * 40) % mapSize;
    final movingScanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF00FFFF).withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 5, mapSize, 10));

    canvas.drawRect(Rect.fromLTWH(0, scanY - 5, mapSize, 10), movingScanPaint);

    // Corruption scanlines (red, when enemies present)
    if (_corruptionLevel > 0.2) {
      final corruptScanY = (mapSize - (_time * 25) % mapSize);
      final corruptPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFFFF0044).withOpacity(0.08 * _corruptionLevel),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, corruptScanY - 8, mapSize, 16));

      canvas.drawRect(Rect.fromLTWH(0, corruptScanY - 8, mapSize, 16), corruptPaint);
    }
  }

  void _renderDataStream(Canvas canvas) {
    // Vertical data streams (Matrix-style)
    final streamPaint = Paint()..strokeWidth = 1;
    final random = math.Random(42);

    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * mapSize;
      final speed = 20 + random.nextDouble() * 30;
      final baseY = (_time * speed + i * 50) % (mapSize + 30) - 15;

      for (int j = 0; j < 8; j++) {
        final y = baseY + j * 4;
        if (y < 0 || y > mapSize) continue;

        final alpha = (1.0 - j / 8.0) * 0.3;
        streamPaint.color = const Color(0xFF00FFFF).withOpacity(alpha);
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 2), streamPaint);
      }
    }
  }

  void _renderPath(Canvas canvas) {
    // Get actual path from game if available, otherwise show stylized path
    final pathPaint = Paint()
      ..color = const Color(0xFFFF6600).withOpacity(0.4 + math.sin(_pulsePhase * 0.5) * 0.1)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Glowing path effect
    final glowPaint = Paint()
      ..color = const Color(0xFFFF6600).withOpacity(0.15)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Simplified S-curve path
    final path = Path()
      ..moveTo(0, mapSize * 0.25)
      ..lineTo(mapSize * 0.25, mapSize * 0.25)
      ..lineTo(mapSize * 0.25, mapSize * 0.75)
      ..lineTo(mapSize * 0.75, mapSize * 0.75)
      ..lineTo(mapSize * 0.75, mapSize * 0.25)
      ..lineTo(mapSize, mapSize * 0.25);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, pathPaint);

    // Animated dots along path
    _renderPathDots(canvas, path);
  }

  void _renderPathDots(Canvas canvas, Path path) {
    final metrics = path.computeMetrics().first;
    final pathLength = metrics.length;

    final dotPaint = Paint()..color = const Color(0xFFFFAA00);

    for (int i = 0; i < 3; i++) {
      final progress = ((_time * 0.1 + i * 0.33) % 1.0);
      final tangent = metrics.getTangentForOffset(progress * pathLength);

      if (tangent != null) {
        final pulse = 0.6 + math.sin(_pulsePhase + i) * 0.4;
        canvas.drawCircle(
          tangent.position,
          2 * pulse,
          dotPaint..color = const Color(0xFFFFAA00).withOpacity(pulse),
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
        Paint()
          ..color = tower.color.withOpacity(0.1)
          ..style = PaintingStyle.fill,
      );

      // Tower glow
      canvas.drawCircle(
        Offset(mapX, mapY),
        6,
        Paint()
          ..color = tower.color.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Tower icon (hexagonal)
      _drawHexagon(canvas, mapX, mapY, 3.5, tower.color.withOpacity(0.9));

      // Pulse ring effect (based on animation timer)
      final pulseProgress = (math.sin(_pulsePhase * 2 + tower.hashCode * 0.1) + 1) / 2;
      if (pulseProgress > 0.7) {
        canvas.drawCircle(
          Offset(mapX, mapY),
          4 + pulseProgress * 4,
          Paint()
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
          Paint()
            ..color = baseColor.withOpacity(0.3 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );

        // Boss warning ring
        canvas.drawCircle(
          Offset(mapX, mapY),
          8 + math.sin(_pulsePhase * 3) * 2,
          Paint()
            ..color = baseColor.withOpacity(0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }

      // Enemy dot
      canvas.drawCircle(
        Offset(mapX, mapY),
        size * pulse,
        Paint()..color = baseColor.withOpacity(0.9),
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
        Paint()
          ..color = baseColor.withOpacity(0.6)
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
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: _scanAngle - 0.8,
        endAngle: _scanAngle,
        colors: [
          Colors.transparent,
          sweepColor.withOpacity(0.05),
          sweepColor.withOpacity(0.15),
        ],
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: scanLength));

    canvas.drawCircle(Offset(centerX, centerY), scanLength, sweepPaint);

    // Main scan line with glow
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(endX, endY),
      Paint()
        ..color = sweepColor.withOpacity(0.3)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
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
      Paint()
        ..color = sweepColor.withOpacity(0.6)
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
      Paint()..shader = vignetteGradient,
    );

    // Corruption artifacts
    if (_corruptionLevel > 0.5) {
      final artifactRandom = math.Random((_time * 10).floor());
      for (int i = 0; i < (_corruptionLevel * 5).floor(); i++) {
        final x = artifactRandom.nextDouble() * mapSize;
        final y = artifactRandom.nextDouble() * mapSize;
        final w = 5 + artifactRandom.nextDouble() * 15;

        canvas.drawRect(
          Rect.fromLTWH(x, y, w, 1),
          Paint()..color = const Color(0xFFFF0044).withOpacity(0.2 * _corruptionLevel),
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

    final hexPath = _createHexagonalPath(mapSize / 2, mapSize / 2, mapSize / 2 - 2);

    // Main frame
    _framePaint
      ..color = frameColor.withOpacity(0.6 + math.sin(_pulsePhase) * 0.2)
      ..strokeWidth = borderWidth;
    canvas.drawPath(hexPath, _framePaint);

    // Inner frame
    final innerHex = _createHexagonalPath(mapSize / 2, mapSize / 2, mapSize / 2 - 6);
    _framePaint
      ..color = frameColor.withOpacity(0.2)
      ..strokeWidth = 1;
    canvas.drawPath(innerHex, _framePaint);

    // Corner tech details
    _renderCornerDetails(canvas, frameColor);

    // Glitch frame displacement
    if (_isGlitching && _glitchIntensity > 0.5) {
      canvas.drawPath(
        hexPath,
        Paint()
          ..color = const Color(0xFFFF0044).withOpacity(0.4 * _glitchIntensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _renderCornerDetails(Canvas canvas, Color color) {
    final detailPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Tech brackets at corners
    const bracketSize = 15.0;
    const offset = 8.0;

    // Top-left
    canvas.drawLine(Offset(offset, offset + bracketSize), Offset(offset, offset), detailPaint);
    canvas.drawLine(Offset(offset, offset), Offset(offset + bracketSize, offset), detailPaint);

    // Top-right
    canvas.drawLine(Offset(mapSize - offset - bracketSize, offset), Offset(mapSize - offset, offset), detailPaint);
    canvas.drawLine(Offset(mapSize - offset, offset), Offset(mapSize - offset, offset + bracketSize), detailPaint);

    // Bottom-left
    canvas.drawLine(Offset(offset, mapSize - offset - bracketSize), Offset(offset, mapSize - offset), detailPaint);
    canvas.drawLine(Offset(offset, mapSize - offset), Offset(offset + bracketSize, mapSize - offset), detailPaint);

    // Bottom-right
    canvas.drawLine(Offset(mapSize - offset - bracketSize, mapSize - offset), Offset(mapSize - offset, mapSize - offset), detailPaint);
    canvas.drawLine(Offset(mapSize - offset, mapSize - offset - bracketSize), Offset(mapSize - offset, mapSize - offset), detailPaint);

    // Corner dots with glow
    final dotPositions = [
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
        Paint()
          ..color = color.withOpacity(0.3 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(pos, 2, Paint()..color = color.withOpacity(pulse));
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

    final labelPainter = TextPainter(
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

    labelPainter.paint(canvas, Offset((mapSize - labelPainter.width) / 2, mapSize + 6));

    // Status indicators on sides
    _renderSideStatus(canvas, titleColor);
  }

  void _renderSideStatus(Canvas canvas, Color color) {
    // Enemy count indicator (left side)
    final enemyCount = gameRef.enemyManager.aliveCount;
    final enemyText = enemyCount.toString().padLeft(2, '0');

    final enemyPainter = TextPainter(
      text: TextSpan(
        text: enemyText,
        style: TextStyle(
          color: _corruptionLevel > 0.5 ? const Color(0xFFFF4444) : color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          shadows: [Shadow(color: color, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Rotate for side display
    canvas.save();
    canvas.translate(-12, mapSize / 2);
    canvas.rotate(-math.pi / 2);
    enemyPainter.paint(canvas, Offset(-enemyPainter.width / 2, 0));
    canvas.restore();

    // Tower count (right side)
    final towerCount = gameRef.towerManager.towers.length;
    final towerText = towerCount.toString().padLeft(2, '0');

    final towerPainter = TextPainter(
      text: TextSpan(
        text: towerText,
        style: TextStyle(
          color: const Color(0xFF00FF88),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          shadows: [Shadow(color: const Color(0xFF00FF88), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(mapSize + 12, mapSize / 2);
    canvas.rotate(math.pi / 2);
    towerPainter.paint(canvas, Offset(-towerPainter.width / 2, 0));
    canvas.restore();
  }

  void _renderGlitchBars(Canvas canvas) {
    if (!_isGlitching || _glitchIntensity < 0.2) return;

    final random = math.Random(_glitchFrame);

    for (int i = 0; i < (5 * _glitchIntensity).floor(); i++) {
      final y = random.nextDouble() * mapSize;
      final height = 1 + random.nextDouble() * 3;
      final xOffset = (random.nextDouble() - 0.5) * 10 * _glitchIntensity;
      final color = random.nextBool() ? const Color(0xFF00FFFF) : const Color(0xFFFF0044);

      canvas.drawRect(
        Rect.fromLTWH(xOffset, y, mapSize, height),
        Paint()..color = color.withOpacity(0.2 * _glitchIntensity),
      );
    }
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

    canvas.drawPath(path, Paint()..color = color);
  }

  String _corruptString(String input) {
    final glitchChars = ['#', '@', '!', '%', '&', '*', '?', '/', '\\', '|'];
    final random = math.Random(_glitchFrame);
    final chars = input.split('');

    for (int i = 0; i < chars.length; i++) {
      if (random.nextDouble() < 0.25) {
        chars[i] = glitchChars[random.nextInt(glitchChars.length)];
      }
    }
    return chars.join();
  }
}

// Extension for sin on double
extension on double {
  double sin() => math.sin(this);
}
