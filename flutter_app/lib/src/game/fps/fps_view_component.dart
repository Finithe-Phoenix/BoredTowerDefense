import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../entities/tower.dart';
import '../entities/boss.dart';
import '../entities/enemy.dart';
import '../bored_games_game.dart';

/// First-person view mode that provides unique interface for each tower type
/// Activates BOOST mode when a boss is present
class FpsViewComponent extends PositionComponent with HasGameRef<BoredGamesGame> {
  FpsViewComponent({
    required this.tower,
  }) : super(priority: 500) {
    _initializeForTowerType();
  }

  final Tower tower;

  // Overdrive Timer
  double _remainingOverdriveTime = 10.0;
  static const double overdriveDuration = 10.0;

  // Boost mode visuals
  double _boostFlash = 0;
  final List<_BoostParticle> _boostParticles = [];
  
  // Cockpit visual effects
  double _glitchTimer = 0;
  bool _isGlitching = false;

  // Tower-specific data
  late Color _primaryColor;
  late Color _secondaryColor;
  late String _towerName;
  late String _weaponType;

  void _initializeForTowerType() {
    switch (tower.type) {
      case TowerType.pulseArcher:
        _primaryColor = const Color(0xFF00FFFF);
        _secondaryColor = const Color(0xFF0088FF);
        _towerName = 'PULSE ARCHER';
        _weaponType = 'ENERGY BOW';
        break;
      case TowerType.circuitCannon:
        _primaryColor = const Color(0xFFFF00FF);
        _secondaryColor = const Color(0xFFFF0088);
        _towerName = 'CIRCUIT CANNON';
        _weaponType = 'PLASMA ARTILLERY';
        break;
      case TowerType.phaseMage:
        _primaryColor = const Color(0xFF9C27B0);
        _secondaryColor = const Color(0xFFAA00FF);
        _towerName = 'PHASE MAGE';
        _weaponType = 'ARCANE STAFF';
        break;
      case TowerType.glimmerField:
        _primaryColor = const Color(0xFFFFEB3B);
        _secondaryColor = const Color(0xFFFFAA00);
        _towerName = 'GLIMMER FIELD';
        _weaponType = 'PRISMATIC ARRAY';
        break;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2.zero();
    this.size = size.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _animationTime += dt;

    // Check for boss to activate BOOST mode
    final boss = gameRef.enemyManager.currentBoss;
    _isBoostMode = boss != null && boss.isAlive;

    // Smoothly transition boost intensity
    final targetBoost = _isBoostMode ? 1.0 : 0.0;
    _boostIntensity += (targetBoost - _boostIntensity) * dt * 3;

    // Overdrive Timer Logic
    _remainingOverdriveTime -= dt;
    if (_remainingOverdriveTime <= 0) {
      _remainingOverdriveTime = 0;
      gameRef.exitFocusMode(); // Automatically exit after 10s
    }

    // Cockpit Glitch effect
    if (math.Random().nextDouble() < 0.005) {
      _isGlitching = true;
      _glitchTimer = 0.05 + math.Random().nextDouble() * 0.1;
    }
    if (_isGlitching) {
      _glitchTimer -= dt;
      if (_glitchTimer <= 0) _isGlitching = false;
    }

    // Update reload progress
    final timeSinceLastShot = gameRef.gameTime - tower.lastFireTime;
    final reloadTime = 1.0 / tower.currentFireRate;
    _reloadProgress = (timeSinceLastShot / reloadTime).clamp(0.0, 1.0);

    // Get current target
    _currentTarget = tower.currentTarget;

    // Update target lock progress
    if (_currentTarget != null) {
      _targetLockProgress = math.min(_targetLockProgress + dt * 2, 1.0);
    } else {
      _targetLockProgress = math.max(_targetLockProgress - dt * 4, 0.0);
    }

    // Crosshair animations
    _crosshairPulse = math.sin(_animationTime * 4) * 0.5 + 0.5;
    _crosshairRotation += dt * 0.5;

    // Recoil decay
    if (_recoilOffset > 0) {
      _recoilOffset = math.max(0, _recoilOffset - dt * 100);
    }

    // Boost particles
    if (_isBoostMode) {
      _spawnBoostParticles(dt);
    }
    _updateBoostParticles(dt);

    // Boost flash decay
    if (_boostFlash > 0) {
      _boostFlash = math.max(0, _boostFlash - dt * 3);
    }
  }

  void _spawnBoostParticles(double dt) {
    // Spawn rate increases with boost intensity
    if (math.Random().nextDouble() < dt * 30 * _boostIntensity) {
      _boostParticles.add(_BoostParticle(
        position: Vector2(
          math.Random().nextDouble() * size.x,
          size.y,
        ),
        velocity: Vector2(
          (math.Random().nextDouble() - 0.5) * 100,
          -100 - math.Random().nextDouble() * 200,
        ),
        color: _primaryColor,
        size: 2 + math.Random().nextDouble() * 4,
      ));
    }

    // Limit particle count
    if (_boostParticles.length > 50) {
      _boostParticles.removeAt(0);
    }
  }

  void _updateBoostParticles(double dt) {
    _boostParticles.removeWhere((p) => !p.isAlive);
    for (final particle in _boostParticles) {
      particle.update(dt);
    }
  }

  /// Trigger recoil effect when tower fires
  void triggerRecoil() {
    _recoilOffset = 20;
    _boostFlash = 1.0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Render boost mode background
    if (_boostIntensity > 0) {
      _renderBoostBackground(canvas);
    }

    // Render cockpit glass/frame
    _renderCockpitFrame(canvas);

    // Render boost particles
    _renderBoostParticles(canvas);

    // Render overdrive timer
    _renderOverdriveTimer(canvas);

    // Render weapon based on tower type
    _renderWeapon(canvas);

    // Render HUD overlay
    _renderHUD(canvas);

    // Render scanlines for CRT effect
    _renderScanlines(canvas);

    // Render crosshair
    _renderCrosshair(canvas);

    // Render target lock indicators
    if (_currentTarget != null) {
      _renderTargetLock(canvas);
    }

    // Boost mode warning flash
    if (_boostFlash > 0) {
      _renderBoostFlash(canvas);
    }
  }

  void _renderBoostBackground(Canvas canvas) {
    // Animated background grid
    final gridPaint = Paint()
      ..color = _primaryColor.withOpacity(0.1 * _boostIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final gridSize = 50.0;
    final offset = (_animationTime * 50) % gridSize;

    // Vertical lines
    for (double x = -offset; x < size.x + gridSize; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.y),
        gridPaint,
      );
    }

    // Horizontal lines
    for (double y = -offset; y < size.y + gridSize; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.x, y),
        gridPaint,
      );
    }

    // Vignette effect
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          _primaryColor.withOpacity(0.3 * _boostIntensity),
        ],
        stops: const [0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      vignettePaint,
    );
  }

  void _renderBoostParticles(Canvas canvas) {
    for (final particle in _boostParticles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(
        Offset(particle.position.x, particle.position.y),
        particle.size,
        paint,
      );
    }
  }

  void _renderWeapon(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y - 100 + _recoilOffset);

    switch (tower.type) {
      case TowerType.pulseArcher:
        _renderPulseArcherWeapon(canvas);
        break;
      case TowerType.circuitCannon:
        _renderCircuitCannonWeapon(canvas);
        break;
      case TowerType.phaseMage:
        _renderPhaseMageWeapon(canvas);
        break;
      case TowerType.glimmerField:
        _renderGlimmerFieldWeapon(canvas);
        break;
    }

    canvas.restore();
  }

  void _renderPulseArcherWeapon(Canvas canvas) {
    // Energy Bow design
    final bowPaint = Paint()
      ..color = _primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Bow arc
    final bowPath = Path()
      ..moveTo(-60, -20)
      ..quadraticBezierTo(-70, 0, -60, 20);

    canvas.drawPath(bowPath, bowPaint);

    // Energy string
    final stringPaint = Paint()
      ..color = _primaryColor.withOpacity(0.6 + _crosshairPulse * 0.4)
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawLine(
      const Offset(-60, -20),
      const Offset(-60, 20),
      stringPaint,
    );

    // Charged arrow (when ready to fire)
    if (_reloadProgress >= 1.0) {
      final arrowPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        const Offset(-55, 0),
        const Offset(0, 0),
        arrowPaint,
      );

      // Arrow glow
      final glowPaint = Paint()
        ..color = _primaryColor.withOpacity(_crosshairPulse * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawLine(
        const Offset(-55, 0),
        const Offset(0, 0),
        glowPaint,
      );
    }

    // BOOST mode: Energy wings
    if (_boostIntensity > 0) {
      final wingPaint = Paint()
        ..color = _primaryColor.withOpacity(0.3 * _boostIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (int i = 0; i < 3; i++) {
        final offset = i * 10.0;
        final wingPath = Path()
          ..moveTo(-60 - offset, -20 - offset)
          ..quadraticBezierTo(-70 - offset, 0, -60 - offset, 20 + offset);
        canvas.drawPath(wingPath, wingPaint);
      }
    }
  }

  void _renderCircuitCannonWeapon(Canvas canvas) {
    // Heavy cannon barrel
    final barrelPaint = Paint()
      ..color = _primaryColor
      ..style = PaintingStyle.fill;

    final barrelRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-15, -40, 30, 80),
      const Radius.circular(5),
    );

    canvas.drawRRect(barrelRect, barrelPaint);

    // Barrel segments
    final segmentPaint = Paint()
      ..color = _secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 4; i++) {
      final y = -30.0 + i * 20;
      canvas.drawLine(
        Offset(-15, y),
        Offset(15, y),
        segmentPaint,
      );
    }

    // Charging indicator (when reloading)
    if (_reloadProgress < 1.0) {
      final chargePaint = Paint()
        ..color = _primaryColor.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      final chargeHeight = 80 * _reloadProgress;
      canvas.drawRect(
        Rect.fromLTWH(-15, 40 - chargeHeight, 30, chargeHeight),
        chargePaint,
      );
    }

    // Muzzle flash when ready
    if (_reloadProgress >= 1.0) {
      final flashPaint = Paint()
        ..color = Colors.white.withOpacity(_crosshairPulse * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(const Offset(0, -40), 15, flashPaint);
    }

    // BOOST mode: Energy coils
    if (_boostIntensity > 0) {
      for (int i = 0; i < 6; i++) {
        final angle = _animationTime * 3 + i * math.pi / 3;
        final radius = 25.0;
        final x = math.cos(angle) * radius;
        final y = math.sin(angle) * radius * 0.3;

        final coilPaint = Paint()
          ..color = _secondaryColor.withOpacity(0.6 * _boostIntensity)
          ..strokeWidth = 3;

        canvas.drawCircle(Offset(x, y), 5, coilPaint);
      }
    }
  }

  void _renderPhaseMageWeapon(Canvas canvas) {
    // Arcane staff with crystal
    final staffPaint = Paint()
      ..color = _primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Staff shaft
    canvas.drawLine(
      const Offset(0, 40),
      const Offset(0, -60),
      staffPaint,
    );

    // Floating crystal
    final crystalY = -60 + math.sin(_animationTime * 2) * 5;

    // Crystal glow
    final glowPaint = Paint()
      ..color = _primaryColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawCircle(Offset(0, crystalY), 20, glowPaint);

    // Crystal core
    final crystalPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 + _animationTime;
      final x = math.cos(angle) * 12;
      final y = crystalY + math.sin(angle) * 12;
      if (i == 0) {
        crystalPath.moveTo(x, y);
      } else {
        crystalPath.lineTo(x, y);
      }
    }
    crystalPath.close();

    final crystalPaint = Paint()
      ..color = _primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(crystalPath, crystalPaint);

    // Energy particles orbiting crystal
    for (int i = 0; i < 4; i++) {
      final angle = _animationTime * 4 + i * math.pi / 2;
      final radius = 25.0;
      final x = math.cos(angle) * radius;
      final y = crystalY + math.sin(angle) * radius;

      final particlePaint = Paint()
        ..color = _secondaryColor.withOpacity(0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(x, y), 3, particlePaint);
    }

    // BOOST mode: Phase rift effect
    if (_boostIntensity > 0) {
      for (int i = 0; i < 8; i++) {
        final angle = i / 8 * math.pi * 2;
        final dist = 40 + math.sin(_animationTime * 5 + i) * 10;
        final x = math.cos(angle) * dist;
        final y = crystalY + math.sin(angle) * dist;

        final riftPaint = Paint()
          ..color = _primaryColor.withOpacity(0.4 * _boostIntensity)
          ..strokeWidth = 2;

        canvas.drawLine(
          Offset(0, crystalY),
          Offset(x, y),
          riftPaint,
        );
      }
    }
  }

  void _renderGlimmerFieldWeapon(Canvas canvas) {
    // Prismatic array - multiple small emitters
    for (int i = 0; i < 5; i++) {
      final x = (i - 2) * 25.0;
      final y = -20 + math.sin(_animationTime * 3 + i) * 10;

      // Emitter glow
      final glowPaint = Paint()
        ..color = _primaryColor.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(x, y), 12, glowPaint);

      // Emitter core
      final corePaint = Paint()
        ..color = _primaryColor;

      canvas.drawCircle(Offset(x, y), 6, corePaint);

      // Rainbow shimmer effect
      final hue = (i / 5 * 360 + _animationTime * 50) % 360;
      final shimmerPaint = Paint()
        ..color = HSVColor.fromAHSV(0.6, hue, 1.0, 1.0).toColor()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(x, y), 8, shimmerPaint);
    }

    // Energy beams when ready
    if (_reloadProgress >= 0.8) {
      for (int i = 0; i < 5; i++) {
        final x = (i - 2) * 25.0;
        final y = -20 + math.sin(_animationTime * 3 + i) * 10;

        final beamPaint = Paint()
          ..color = Colors.white.withOpacity(_crosshairPulse * 0.6)
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

        canvas.drawLine(
          Offset(x, y),
          Offset(x, y - 100),
          beamPaint,
        );
      }
    }

    // BOOST mode: Prismatic explosion
    if (_boostIntensity > 0) {
      for (int ring = 0; ring < 3; ring++) {
        final ringRadius = 60 + ring * 30 * _boostIntensity;
        for (int i = 0; i < 12; i++) {
          final angle = _animationTime * 2 + i / 12 * math.pi * 2 + ring * 0.5;
          final x = math.cos(angle) * ringRadius;
          final y = math.sin(angle) * ringRadius;

          final hue = (i / 12 * 360) % 360;
          final burstPaint = Paint()
            ..color = HSVColor.fromAHSV(0.4 * _boostIntensity, hue, 1.0, 1.0).toColor()
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

          canvas.drawCircle(Offset(x, y), 4, burstPaint);
        }
      }
    }
  }

  void _renderHUD(Canvas canvas) {
    // Top-left: Tower info
    _renderTowerInfo(canvas);

    // Top-right: Stats
    _renderStats(canvas);

    // Bottom-left: Reload indicator
    _renderReloadIndicator(canvas);

    // Bottom-right: BOOST mode indicator
    if (_isBoostMode) {
      _renderBoostIndicator(canvas);
    }
  }

  void _renderTowerInfo(Canvas canvas) {
    final namePainter = TextPainter(
      text: TextSpan(
        text: _towerName,
        style: TextStyle(
          color: _primaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          shadows: [
            Shadow(
              color: _primaryColor.withOpacity(0.8),
              blurRadius: 8,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    namePainter.layout();
    namePainter.paint(canvas, const Offset(20, 20));

    final weaponPainter = TextPainter(
      text: TextSpan(
        text: _weaponType,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 14,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    weaponPainter.layout();
    weaponPainter.paint(canvas, const Offset(20, 50));
  }

  void _renderStats(Canvas canvas) {
    final stats = [
      'DMG: ${tower.currentDamage.toInt()}',
      'RNG: ${tower.currentRange.toInt()}',
      'ROF: ${tower.currentFireRate.toStringAsFixed(1)}/s',
    ];

    double y = 20;
    for (final stat in stats) {
      final painter = TextPainter(
        text: TextSpan(
          text: stat,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      painter.layout();
      painter.paint(canvas, Offset(size.x - painter.width - 20, y));
      y += 25;
    }
  }

  void _renderReloadIndicator(Canvas canvas) {
    const barWidth = 200.0;
    const barHeight = 30.0;
    final barX = 20.0;
    final barY = size.y - 60;

    // Background
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.6);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(5),
      ),
      bgPaint,
    );

    // Reload fill
    final fillPaint = Paint()
      ..color = _reloadProgress >= 1.0 ? Colors.green : _primaryColor;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth * _reloadProgress, barHeight),
        const Radius.circular(5),
      ),
      fillPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = _primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(5),
      ),
      borderPaint,
    );

    // Text
    final text = _reloadProgress >= 1.0 ? 'READY' : 'RELOADING';
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(barX + barWidth / 2 - textPainter.width / 2, barY + 7),
    );
  }

  void _renderBoostIndicator(Canvas canvas) {
    final x = size.x - 250;
    final y = size.y - 80;

    // BOOST text with pulsing glow
    final boostPainter = TextPainter(
      text: TextSpan(
        text: 'BOOST MODE',
        style: TextStyle(
          color: _primaryColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
          shadows: [
            Shadow(
              color: _primaryColor.withOpacity(_crosshairPulse),
              blurRadius: 15,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    boostPainter.layout();
    boostPainter.paint(canvas, Offset(x, y));

    // Warning brackets
    final bracketPaint = Paint()
      ..color = _primaryColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Left bracket
    canvas.drawLine(Offset(x - 10, y), Offset(x - 20, y), bracketPaint);
    canvas.drawLine(Offset(x - 20, y), Offset(x - 20, y + 30), bracketPaint);
    canvas.drawLine(Offset(x - 20, y + 30), Offset(x - 10, y + 30), bracketPaint);

    // Right bracket
    final rightX = x + boostPainter.width;
    canvas.drawLine(Offset(rightX + 10, y), Offset(rightX + 20, y), bracketPaint);
    canvas.drawLine(Offset(rightX + 20, y), Offset(rightX + 20, y + 30), bracketPaint);
    canvas.drawLine(Offset(rightX + 20, y + 30), Offset(rightX + 10, y + 30), bracketPaint);
  }

  void _renderCrosshair(Canvas canvas) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    // Crosshair color changes when target locked
    final crosshairColor = _targetLockProgress > 0.5
        ? Colors.red
        : _primaryColor;

    final crosshairPaint = Paint()
      ..color = crosshairColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final glowPaint = Paint()
      ..color = crosshairColor.withOpacity(_crosshairPulse * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Rotating outer ring
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(_crosshairRotation);

    final radius = 30.0 + _crosshairPulse * 5;

    // Outer ring segments
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      canvas.save();
      canvas.rotate(angle);

      // Segment arc
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        -math.pi / 8,
        math.pi / 4,
        false,
        crosshairPaint,
      );

      // Glow
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        -math.pi / 8,
        math.pi / 4,
        false,
        glowPaint,
      );

      canvas.restore();
    }

    canvas.restore();

    // Center dot
    canvas.drawCircle(
      Offset(centerX, centerY),
      3,
      Paint()..color = crosshairColor,
    );

    // Target lock indicator
    if (_targetLockProgress > 0) {
      final lockPaint = Paint()
        ..color = Colors.red.withOpacity(_targetLockProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(
        Offset(centerX, centerY),
        40 - _targetLockProgress * 10,
        lockPaint,
      );
    }
  }

  void _renderTargetLock(Canvas canvas) {
    // Lock-on brackets around target
    if (_currentTarget == null) return;

    // This would need to project 3D target position to screen
    // For now, show indicator at top center
    final centerX = size.x / 2;
    final y = 120.0;

    final lockPaint = Paint()
      ..color = Colors.red.withOpacity(_targetLockProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Target brackets
    final bracketSize = 20.0;

    // Top-left
    canvas.drawLine(Offset(centerX - 40, y - 20), Offset(centerX - 40 + bracketSize, y - 20), lockPaint);
    canvas.drawLine(Offset(centerX - 40, y - 20), Offset(centerX - 40, y - 20 + bracketSize), lockPaint);

    // Top-right
    canvas.drawLine(Offset(centerX + 40 - bracketSize, y - 20), Offset(centerX + 40, y - 20), lockPaint);
    canvas.drawLine(Offset(centerX + 40, y - 20), Offset(centerX + 40, y - 20 + bracketSize), lockPaint);

    // Bottom-left
    canvas.drawLine(Offset(centerX - 40, y + 20 - bracketSize), Offset(centerX - 40, y + 20), lockPaint);
    canvas.drawLine(Offset(centerX - 40, y + 20), Offset(centerX - 40 + bracketSize, y + 20), lockPaint);

    // Bottom-right
    canvas.drawLine(Offset(centerX + 40, y + 20 - bracketSize), Offset(centerX + 40, y + 20), lockPaint);
    canvas.drawLine(Offset(centerX + 40 - bracketSize, y + 20), Offset(centerX + 40, y + 20), lockPaint);

    // Target info
    final targetPainter = TextPainter(
      text: TextSpan(
        text: 'TARGET LOCKED',
        style: TextStyle(
          color: Colors.red.withOpacity(_targetLockProgress),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    targetPainter.layout();
    targetPainter.paint(
      canvas,
      Offset(centerX - targetPainter.width / 2, y - 35),
    );
  }

  void _renderCockpitFrame(Canvas canvas) {
    final framePaint = Paint()
      ..color = _primaryColor.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    // Outer frame bevel
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      framePaint,
    );

    // Corner brackets
    final cornerPaint = Paint()
      ..color = _primaryColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    const cornerSize = 100.0;
    
    // Top-Left
    canvas.drawLine(const Offset(0, cornerSize), const Offset(0, 0), cornerPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(cornerSize, 0), cornerPaint);
    
    // Top-Right
    canvas.drawLine(Offset(size.x - cornerSize, 0), Offset(size.x, 0), cornerPaint);
    canvas.drawLine(Offset(size.x, 0), Offset(size.x, cornerSize), cornerPaint);
    
    // Bottom-Left
    canvas.drawLine(Offset(0, size.y - cornerSize), Offset(0, size.y), cornerPaint);
    canvas.drawLine(Offset(0, size.y), Offset(cornerSize, size.y), cornerPaint);
    
    // Bottom-Right
    canvas.drawLine(Offset(size.x - cornerSize, size.y), Offset(size.x, size.y), cornerPaint);
    canvas.drawLine(Offset(size.x, size.y), Offset(size.x, size.y - cornerSize), cornerPaint);

    // Glass Reflection
    final reflectionsPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.05),
          Colors.transparent,
          Colors.white.withOpacity(0.02),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), reflectionsPaint);
  }

  void _renderOverdriveTimer(Canvas canvas) {
    final centerX = size.x / 2;
    final y = size.y - 150;
    const barWidth = 300.0;
    const barHeight = 8.0;

    // Timer background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, y), width: barWidth, height: barHeight),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    // Progress
    final progress = _remainingOverdriveTime / overdriveDuration;
    final color = Color.lerp(Colors.red, _primaryColor, progress)!;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX - (barWidth/2 * (1 - progress)), y), width: barWidth * progress, height: barHeight),
        const Radius.circular(4),
      ),
      Paint()..color = color,
    );

    // Indicator Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'OVERDRIVE: ${_remainingOverdriveTime.toStringAsFixed(1)}s',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX - textPainter.width/2, y - 20));
  }

  void _renderScanlines(Canvas canvas) {
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double y = 0; y < size.y; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), linePaint);
    }

    if (_isGlitching) {
      final glitchPaint = Paint()
        ..color = _primaryColor.withOpacity(0.1);
      final glitchY = math.Random().nextDouble() * size.y;
      canvas.drawRect(Rect.fromLTWH(0, glitchY, size.x, 20), glitchPaint);
    }
  }

  void _renderBoostFlash(Canvas canvas) {
    final flashPaint = Paint()
      ..color = Colors.white.withOpacity(_boostFlash * 0.3);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      flashPaint,
    );
  }
}

class _BoostParticle {
  _BoostParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
  }) : lifetime = 2.0;

  final Vector2 position;
  final Vector2 velocity;
  final Color color;
  final double size;
  final double lifetime;

  double age = 0;

  bool get isAlive => age < lifetime;
  double get alpha => (1 - age / lifetime).clamp(0.0, 1.0);

  void update(double dt) {
    age += dt;
    position.add(velocity * dt);
    velocity.y -= 50 * dt; // Gravity
  }
}
