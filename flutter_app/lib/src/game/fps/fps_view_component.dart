import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart' hide Vector3;
import 'package:flutter/material.dart';
import '../entities/tower.dart';
import '../entities/enemy.dart';
import '../bored_games_game.dart';
import 'fps_camera_3d.dart';
import 'fps_tower_3d.dart';
import 'fps_enemy_3d.dart';

/// First-person view mode that provides unique interface for each tower type
/// Activates BOOST mode when a boss is present
class FpsViewComponent extends PositionComponent with HasGameRef<BoredGamesGame> {
  FpsViewComponent({
    required this.tower,
  }) : super(priority: 500) {
    _initializeForTowerType();
    
    // Initialize 3D camera
    _camera = Camera3D(
      position: Vector3(0, 150, -300), // Camera behind and above
      lookAt: Vector3(0, 50, 0), // Looking at center
      fov: 75.0,
    );
  }

  final Tower tower;

  // 3D Camera System
  late final Camera3D _camera;
  final List<Tower3D> _towers3d = [];
  final List<Enemy3D> _enemies3d = [];
  Tower3D? _hoveredTower;
  Tower3D? _selectedTower;
  Enemy3D? _targetedEnemy3d;

  // Performance optimizations
  double _tower3dUpdateTimer = 0;
  static const double _tower3dUpdateInterval = 0.1; // 10 veces/segundo
  Vector2? _lastMousePosForRaycast;

  // Overdrive Timer
  double _remainingOverdriveTime = 10.0;
  static const double overdriveDuration = 10.0;

  // Boost mode visuals
  double _boostFlash = 0;
  final List<_BoostParticle> _boostParticles = [];
  final List<_DataParticle> _dataParticles = [];
  
  // Cockpit visual effects
  double _glitchTimer = 0;
  bool _isGlitching = false;

  // Tower-specific data
  late Color _primaryColor;
  late Color _secondaryColor;
  late String _towerName;
  late String _weaponType;

  // Materialization Animation
  double _introTime = 0;
  static const double _phaseWireframe = 0.5;
  static const double _phaseSolidify = 1.0;
  static const double _phaseBoot = 1.6;
  bool get _isWireframePhase => _introTime < _phaseSolidify;
  bool get _isBootPhase => _introTime >= _phaseSolidify;
  bool get _introComplete => _introTime >= _phaseBoot;
  
  // Real-time state
  double _animationTime = 0;
  bool _isBoostMode = false;
  double _boostIntensity = 0;
  double _recoilOffset = 0;
  Enemy? _currentTarget;
  double _targetLockProgress = 0;
  double _crosshairPulse = 0;
  double _crosshairRotation = 0;
  double _reloadProgress = 0;

  // Dynamic Tilt
  final Vector2 _currentTilt = Vector2.zero();
  final Vector2 _targetTilt = Vector2.zero();
  static const double _tiltLerp = 4.0;
  static const double _maxTilt = 40.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _gridPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _vignettePaint = Paint();
  static final Paint _particlePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _bowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _stringPaint = Paint()
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _arrowPaint = Paint()
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  static final Paint _arrowGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _wingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _barrelPaint = Paint()
    ..style = PaintingStyle.fill;
  static final Paint _segmentPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _chargePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _muzzleFlashPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _coilPaint = Paint()
    ..strokeWidth = 3;
  static final Paint _staffPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;
  static final Paint _crystalGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _crystalPaint = Paint()
    ..style = PaintingStyle.fill;
  static final Paint _orbParticlePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _riftPaint = Paint()
    ..strokeWidth = 2;
  static final Paint _emitterGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _emitterCorePaint = Paint();
  static final Paint _shimmerPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _beamPaint = Paint()
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _burstPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _reloadBgPaint = Paint();
  static final Paint _reloadFillPaint = Paint();
  static final Paint _reloadBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _bracketPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _crosshairPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _crosshairGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _lockPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _scanlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _glitchPaint = Paint();
  static final Paint _flashPaint = Paint();
  static final Paint _metalPaint = Paint();
  static final Paint _edgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
  static final Paint _neonPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _corePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _deckPaint = Paint();
  static final Paint _deckRimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _graphPaint = Paint()
    ..strokeWidth = 2;
  static final Paint _dataParticlePaint = Paint();
  static final Paint _simpleFillPaint = Paint();
  static final Paint _simpleStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _targetReticlePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _centerDotPaint = Paint();
  static final Paint _timerBgPaint = Paint();
  static final Paint _timerFillPaint = Paint();
  static final Paint _targetLockBracketPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

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
      case TowerType.ionSniper:
        _primaryColor = const Color(0xFF00E5FF);
        _secondaryColor = const Color(0xFF00B2FF);
        _towerName = 'ION SNIPER';
        _weaponType = 'RAIL CANNON';
        break;
      case TowerType.teslaTerminal:
        _primaryColor = const Color(0xFFFFFF00);
        _secondaryColor = const Color(0xFFFFAA00);
        _towerName = 'TESLA TERMINAL';
        _weaponType = 'VOLTAIC COIL';
        break;
      case TowerType.resonanceSiphon:
        _primaryColor = const Color(0xFFFF0066);
        _secondaryColor = const Color(0xFFFF00CC);
        _towerName = 'RESONANCE SIPHON';
        _weaponType = 'ENERGY SYNERGIST';
        break;
      case TowerType.neuralDisruptor:
        _primaryColor = const Color(0xFF00FF00);
        _secondaryColor = const Color(0xFF88FF00);
        _towerName = 'NEURAL DISRUPTOR';
        _weaponType = 'SYNAPTIC BEAM';
        break;
      case TowerType.plasmaBubble:
        _primaryColor = const Color(0xFFE040FB);
        _secondaryColor = const Color(0xFFFF80FF);
        _towerName = 'PLASMA BUBBLE';
        _weaponType = 'BUBBLE LAUNCHER';
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
    _introTime += dt;
    
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

    if (_introTime > _phaseWireframe) {
       // Spawn Data Particles (reduced in low quality)
       final spawnChance = gameRef.reduceFx ? 0.05 : 0.3;
       final maxParticles = gameRef.reduceFx ? 20 : 100;
       
       if (math.Random().nextDouble() < spawnChance) {
          if (_dataParticles.length < maxParticles) {
            _dataParticles.add(_DataParticle());
          }
       }
       // Update data particles with single-pass removal
       int dataWriteIdx = 0;
       for (int i = 0; i < _dataParticles.length; i++) {
         final p = _dataParticles[i];
         p.update(dt);
         if (p.z < 1.0 && p.life > 0) {
           if (dataWriteIdx != i) _dataParticles[dataWriteIdx] = p;
           dataWriteIdx++;
         }
       }
       if (dataWriteIdx < _dataParticles.length) {
         _dataParticles.removeRange(dataWriteIdx, _dataParticles.length);
       }
    }

    // Boost flash decay
    if (_boostFlash > 0) {
      _boostFlash = math.max(0, _boostFlash - dt * 3);
    }

    // Cockpit Tilt based on mouse position
    final mousePos = gameRef.mousePosition;
    final center = size / 2;
    if (mousePos != null && center.x > 0 && center.y > 0) {
      final delta = (mousePos - center);
      _targetTilt.setValues(
        (delta.x / center.x).clamp(-1.0, 1.0) * _maxTilt,
        (delta.y / center.y).clamp(-1.0, 1.0) * _maxTilt,
      );
      
      _currentTilt.setValues(
        _currentTilt.x + (_targetTilt.x - _currentTilt.x) * dt * _tiltLerp,
        _currentTilt.y + (_targetTilt.y - _currentTilt.y) * dt * _tiltLerp,
      );
    }

    // Update 3D towers and enemies (throttled for performance)
    _tower3dUpdateTimer += dt;
    if (_tower3dUpdateTimer >= _tower3dUpdateInterval) {
      _tower3dUpdateTimer = 0;
      _updateTowers3D();
      _updateEnemies3D(dt);
    }

    // Update enemy animations every frame
    for (final enemy3d in _enemies3d) {
      enemy3d.update(dt);
    }

    _updateHoveredTower();
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
    // Update boost particles with single-pass removal
    int boostWriteIdx = 0;
    for (int i = 0; i < _boostParticles.length; i++) {
      final particle = _boostParticles[i];
      particle.update(dt);
      if (particle.isAlive) {
        if (boostWriteIdx != i) _boostParticles[boostWriteIdx] = particle;
        boostWriteIdx++;
      }
    }
    if (boostWriteIdx < _boostParticles.length) {
      _boostParticles.removeRange(boostWriteIdx, _boostParticles.length);
    }
  }

  /// Update 3D tower positions and distances (optimized)
  void _updateTowers3D() {
    _towers3d.clear();
    final allTowers = gameRef.towerManager.towers;
    
    // Limitar número de torres en bajo rendimiento
    final maxTowers = gameRef.reduceFx ? 10 : 50;
    int count = 0;
    
    for (final tower in allTowers) {
      // Skip the tower we're controlling
      if (tower == this.tower) continue;
      if (count >= maxTowers) break;
      
      // Convert 2D world position to 3D camera space
      final worldPos = tower.centerPosition;
      final pos3d = _worldToCamera3D(worldPos);
      
      // Frustum culling: skip towers outside camera view
      final screenPos = _camera.project(pos3d, size);
      if (screenPos == null) continue; // Behind camera or outside frustum
      
      final tower3d = Tower3D(
        tower: tower,
        position3d: pos3d,
        distanceToCamera: _camera.distanceTo(pos3d),
      );
      
      _towers3d.add(tower3d);
      count++;
    }
    
    // Sort by distance (farthest first for proper rendering)
    _towers3d.sort((a, b) => b.distanceToCamera.compareTo(a.distanceToCamera));
  }

  /// Update 3D enemy positions and distances
  void _updateEnemies3D(double dt) {
    _enemies3d.clear();
    final allEnemies = gameRef.enemyManager.activeEnemies;

    // Limit number of enemies in low performance mode
    final maxEnemies = gameRef.reduceFx ? 15 : 60;
    int count = 0;

    for (final enemy in allEnemies) {
      if (!enemy.isAlive) continue;
      if (count >= maxEnemies) break;

      // Convert 2D world position to 3D camera space
      final worldPos = enemy.position;
      final pos3d = _worldToCamera3D(worldPos);

      // Frustum culling: skip enemies outside camera view
      final screenPos = _camera.project(pos3d, size);
      if (screenPos == null) continue;

      final enemy3d = Enemy3D(
        enemy: enemy,
        position3d: pos3d,
        distanceToCamera: _camera.distanceTo(pos3d),
        isTargeted: enemy == _currentTarget,
      );

      _enemies3d.add(enemy3d);
      count++;
    }

    // Sort by distance (farthest first for proper rendering - painter's algorithm)
    _enemies3d.sort((a, b) => b.distanceToCamera.compareTo(a.distanceToCamera));

    // Update targeted enemy reference
    _targetedEnemy3d = _enemies3d.where((e) => e.isTargeted).firstOrNull;
  }

  /// Update which tower is being hovered via raycasting (optimized)
  void _updateHoveredTower() {
    final mousePos = gameRef.mousePosition;
    if (mousePos == null) {
      _hoveredTower = null;
      for (final t in _towers3d) {
        t.isHovered = false;
      }
      return;
    }
    
    // Only raycast if mouse moved significantly (performance optimization)
    if (_lastMousePosForRaycast != null) {
      final dist = (mousePos - _lastMousePosForRaycast!).length;
      if (dist < 5.0) return; // Mouse barely moved, skip raycast
    }
    _lastMousePosForRaycast = mousePos.clone();
    
    final ray = _camera.createRayFromScreen(mousePos, size);
    Tower3D? closest;
    double closestDist = double.infinity;
    
    for (final tower3d in _towers3d) {
      final (min, max) = tower3d.getBoundingBox();
      final intersection = ray.intersectsAABB(min, max);
      
      if (intersection != null && intersection < closestDist) {
        closestDist = intersection;
        closest = tower3d;
      }
    }
    
    // Update hover states
    _hoveredTower = closest;
    for (final t in _towers3d) {
      t.isHovered = (t == _hoveredTower);
      t.isSelected = (t == _selectedTower);
    }
  }

  /// Convert 2D world position to 3D camera space
  Vector3 _worldToCamera3D(Vector2 worldPos) {
    // Map world coordinates to 3D space
    // Center the world around origin
    final centerX = gameRef.size.x / 2;
    final centerY = gameRef.size.y / 2;
    
    // X: left-right in world → left-right in 3D
    // Y: up-down in world → depth (Z) in 3D
    // Height: fixed Y in 3D
    
    return Vector3(
      (worldPos.x - centerX) * 0.8, // X spread
      0.0, // Ground level
      (worldPos.y - centerY) * 0.8, // Z depth
    );
  }

  /// Trigger recoil effect when tower fires
  void triggerRecoil() {
    _recoilOffset = 20;
    _boostFlash = 1.0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.save();
    // Apply reactive tilt (opposing movement for "parallax" feel)
    canvas.translate(-_currentTilt.x, -_currentTilt.y);

    // Render boost mode background
    if (_boostIntensity > 0) {
      _renderBoostBackground(canvas);
    }

    // Draw Data Particles (Floating dust)
    _renderDataParticles(canvas);

    // Render 3D towers
    _renderTowers3D(canvas);

    // Render 3D enemies
    _renderEnemies3D(canvas);

    // Draw 3D Cockpit Frame (Materializing)
    _renderCockpit3D(canvas);

    // Remove old pillars, cockpit handles it now

    // Render weapon based on tower type (only after wireframe starts solidifying)
    if (_introTime > _phaseWireframe) {
       _renderWeapon(canvas);
    }

    // Render HUD overlay (Slides in during Boot phase)
    if (_introTime > _phaseWireframe) {
      _renderHUD(canvas);
    }

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

    canvas.restore();
  }

  void _renderBoostBackground(Canvas canvas) {
    // Animated background grid
    _gridPaint.color = _primaryColor.withOpacity(0.1 * _boostIntensity);

    final gridSize = 50.0;
    final offset = (_animationTime * 50) % gridSize;

    // Vertical lines
    for (double x = -offset; x < size.x + gridSize + _maxTilt; x += gridSize) {
      canvas.drawLine(
        Offset(x, -_maxTilt),
        Offset(x, size.y + _maxTilt),
        _gridPaint,
      );
    }

    // Horizontal lines
    for (double y = -offset; y < size.y + gridSize + _maxTilt; y += gridSize) {
      canvas.drawLine(
        Offset(-_maxTilt, y),
        Offset(size.x + _maxTilt, y),
        _gridPaint,
      );
    }

    // Vignette effect
    _vignettePaint.shader = RadialGradient(
      colors: [
        Colors.transparent,
        _primaryColor.withOpacity(0.3 * _boostIntensity),
      ],
      stops: const [0.5, 1.0],
    ).createShader(Rect.fromLTWH(-_maxTilt, -_maxTilt, size.x + _maxTilt*2, size.y + _maxTilt*2));

    canvas.drawRect(
      Rect.fromLTWH(-_maxTilt, -_maxTilt, size.x + _maxTilt*2, size.y + _maxTilt*2),
      _vignettePaint,
    );
  }

  void _renderBoostParticles(Canvas canvas) {
    for (final particle in _boostParticles) {
      _particlePaint.color = particle.color.withOpacity(particle.alpha);
      canvas.drawCircle(
        Offset(particle.position.x, particle.position.y),
        particle.size,
        _particlePaint,
      );
    }
  }

  void _renderWeapon(Canvas canvas) {
    canvas.save();
    // Reposition weapon to bottom-center/right for "True FPS" feel
    canvas.translate(size.x / 2 + 100 + _currentTilt.x * 0.5, size.y - 80 + _recoilOffset + _currentTilt.y * 0.5);

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
      case TowerType.ionSniper:
      case TowerType.teslaTerminal:
      case TowerType.resonanceSiphon:
      case TowerType.neuralDisruptor:
      case TowerType.plasmaBubble:
        _renderPulseArcherWeapon(canvas); // Fallback
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
    // Parallax for HUD elements to feel 'projected'
    canvas.save();
    canvas.translate(_currentTilt.x * 0.5, _currentTilt.y * 0.5);

    // Calculate transparency/slide based on boot phase
    double hudAlpha = 1.0;
    double slideOffset = 0.0;
    
    if (!_introComplete) {
      final progress = ((_introTime - _phaseSolidify) / (_phaseBoot - _phaseSolidify)).clamp(0.0, 1.0);
      hudAlpha = progress;
      slideOffset = (1.0 - CurvedAnimation(parent: AlwaysStoppedAnimation(progress), curve: Curves.easeOutBack).value) * 100;
    }

    if (hudAlpha > 0) {
      // Top-left: Tower info
      canvas.save();
      canvas.translate(-slideOffset, 0);
      _renderTowerInfo(canvas, hudAlpha);
      canvas.restore();

      // Top-right: Stats
      canvas.save();
      canvas.translate(slideOffset, 0);
      _renderStats(canvas, hudAlpha);
      canvas.restore();

      // Bottom-left: Reload indicator
      canvas.save();
      canvas.translate(0, slideOffset);
      _renderReloadIndicator(canvas, hudAlpha);
      canvas.restore();

      // Bottom-right: BOOST mode indicator
      if (_isBoostMode) {
        canvas.save();
        canvas.translate(0, slideOffset);
        _renderBoostIndicator(canvas, hudAlpha);
        canvas.restore();
      }
      
      // Top Center: Overdrive Timer
      canvas.save();
      canvas.translate(0, -slideOffset);
      _renderOverdriveTimer(canvas, hudAlpha);
      canvas.restore();
    }
    
    canvas.restore();
  }

  void _renderTowerInfo(Canvas canvas, double alpha) {
    // Typing text effect
    final fullText = _towerName;
    int visibleChars = fullText.length;
    
    if (!_introComplete) {
       final progress = ((_introTime - _phaseSolidify) / (_phaseBoot - _phaseSolidify)).clamp(0.0, 1.0);
       visibleChars = (fullText.length * progress).floor();
    }
    
    final namePainter = TextPainter(
      text: TextSpan(
        text: fullText.substring(0, visibleChars),
        style: TextStyle(
          color: _primaryColor.withOpacity(alpha),
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

  void _renderStats(Canvas canvas, double alpha) {
    final stats = [
      'DMG: ${tower.currentDamage.toInt()}',
      'RNG: ${tower.currentRange.toInt()}',
      'ROF: ${tower.currentFireRate.toStringAsFixed(1)}/s',
    ];

    double y = 20;
    for (int i = 0; i < stats.length; i++) {
      // Staggered entry for stats
      if (!_introComplete) {
         final start = _phaseSolidify + (i * 0.1);
         if (_introTime < start) continue;
      }
      
      final stat = stats[i];
      final painter = TextPainter(
        text: TextSpan(
          text: stat,
           style: TextStyle(
            color: Colors.white.withOpacity(0.8 * alpha),
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

  void _renderReloadIndicator(Canvas canvas, double alpha) {
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

  void _renderBoostIndicator(Canvas canvas, double alpha) {
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

    _crosshairPaint.color = crosshairColor.withOpacity(0.8);
    _crosshairGlowPaint.color = crosshairColor.withOpacity(_crosshairPulse * 0.5);

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
        _crosshairPaint,
      );

      // Glow
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        -math.pi / 8,
        math.pi / 4,
        false,
        _crosshairGlowPaint,
      );

      canvas.restore();
    }

    canvas.restore();

    // Center dot
    _centerDotPaint.color = crosshairColor;
    canvas.drawCircle(
      Offset(centerX, centerY),
      3,
      _centerDotPaint,
    );

    // Target lock indicator
    if (_targetLockProgress > 0) {
      _lockPaint.color = Colors.red.withOpacity(_targetLockProgress);

      canvas.drawCircle(
        Offset(centerX, centerY),
        40 - _targetLockProgress * 10,
        _lockPaint,
      );
    }
  }

  void _renderTargetLock(Canvas canvas) {
    // Lock-on brackets around target
    if (_currentTarget == null) return;

    final centerX = size.x / 2;
    final y = 120.0;

    _targetLockBracketPaint.color = Colors.red.withOpacity(_targetLockProgress);

    // Target brackets
    const bracketSize = 20.0;

    // Top-left
    canvas.drawLine(Offset(centerX - 40, y - 20), Offset(centerX - 40 + bracketSize, y - 20), _targetLockBracketPaint);
    canvas.drawLine(Offset(centerX - 40, y - 20), Offset(centerX - 40, y - 20 + bracketSize), _targetLockBracketPaint);

    // Top-right
    canvas.drawLine(Offset(centerX + 40 - bracketSize, y - 20), Offset(centerX + 40, y - 20), _targetLockBracketPaint);
    canvas.drawLine(Offset(centerX + 40, y - 20), Offset(centerX + 40, y - 20 + bracketSize), _targetLockBracketPaint);

    // Bottom-left
    canvas.drawLine(Offset(centerX - 40, y + 20 - bracketSize), Offset(centerX - 40, y + 20), _targetLockBracketPaint);
    canvas.drawLine(Offset(centerX - 40, y + 20), Offset(centerX - 40 + bracketSize, y + 20), _targetLockBracketPaint);

    // Bottom-right
    canvas.drawLine(Offset(centerX + 40, y + 20 - bracketSize), Offset(centerX + 40, y + 20), _targetLockBracketPaint);
    canvas.drawLine(Offset(centerX + 40 - bracketSize, y + 20), Offset(centerX + 40, y + 20), _targetLockBracketPaint);

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



  void _renderOverdriveTimer(Canvas canvas, double alpha) {
    final centerX = size.x / 2;
    final y = size.y - 150;
    const barWidth = 300.0;
    const barHeight = 8.0;

    // Timer background
    _timerBgPaint.color = Colors.black.withOpacity(0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, y), width: barWidth, height: barHeight),
        const Radius.circular(4),
      ),
      _timerBgPaint,
    );

    // Progress
    final progress = _remainingOverdriveTime / overdriveDuration;
    final color = Color.lerp(Colors.red, _primaryColor, progress)!;

    _timerFillPaint.color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX - (barWidth/2 * (1 - progress)), y), width: barWidth * progress, height: barHeight),
        const Radius.circular(4),
      ),
      _timerFillPaint,
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
    _scanlinePaint.color = Colors.black.withOpacity(0.05);

    for (double y = 0; y < size.y; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), _scanlinePaint);
    }

    if (_isGlitching) {
      _glitchPaint.color = _primaryColor.withOpacity(0.1);
      final glitchY = math.Random().nextDouble() * size.y;
      canvas.drawRect(Rect.fromLTWH(0, glitchY, size.x, 20), _glitchPaint);
    }
  }

  void _renderBoostFlash(Canvas canvas) {
    _flashPaint.color = Colors.white.withOpacity(_boostFlash * 0.3);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _flashPaint,
    );
  }



  // REPLACING _renderCockpit3D with the EPIC version
  void _renderCockpit3D(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final progress = (_introTime / _phaseWireframe).clamp(0.0, 1.0);
    
    if (progress <= 0) return;
    
    // Scale for materialization effect
    final entranceScale = math.min(1.0, progress * 1.5);
    
    // --- 1. SOLID PILLARS (The Structure) ---
    final pillarWidth = w * 0.22;
    
    // Gradient for "Dark Industrial Metal"
    final metalGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
         const Color(0xFF080815), // Deep dark blue-black
         const Color(0xFF15152A), // Lighter metallic
         const Color(0xFF05050A), // Black base
      ],
      stops: const [0.0, 0.4, 1.0],
    );
    
    // Left Pillar Shape (Angular Cyberpunk)
    final leftPillar = Path()
      ..moveTo(0, 0)
      ..lineTo(pillarWidth * entranceScale, 0)
      ..lineTo(pillarWidth * 0.8 * entranceScale, h * 0.4)
      ..lineTo(pillarWidth * 0.9 * entranceScale, h)
      ..lineTo(0, h)
      ..close();
      
    // Right Pillar Shape
    final rightPillar = Path()
       ..moveTo(w, 0)
       ..lineTo(w - pillarWidth * entranceScale, 0)
       ..lineTo(w - pillarWidth * 0.8 * entranceScale, h * 0.4)
       ..lineTo(w - pillarWidth * 0.9 * entranceScale, h)
       ..lineTo(w, h)
       ..close();
       
    final metalPaint = Paint()..shader = metalGradient.createShader(Rect.fromLTWH(0,0,w,h));
    
    // Draw Pillars
    canvas.drawPath(leftPillar, metalPaint);
    canvas.drawPath(rightPillar, metalPaint);
    
    // Pillar Edges (Neon Highlight)
    final edgePaint = Paint()
      ..color = _primaryColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2); // Subtle glow
    
    canvas.drawPath(leftPillar, edgePaint);
    canvas.drawPath(rightPillar, edgePaint);
    
    // --- 2. NEON CORES (The Power) ---
    // Only show if fully materialized
    if (_introTime > _phaseWireframe) {
        final neonPaint = Paint()
          ..color = _primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10); // STRONG BLUR
          
        final corePaint = Paint()
           ..color = Colors.white
           ..style = PaintingStyle.stroke
           ..strokeWidth = 2;

        // Vertical Neon Flow in Pillars
        final leftLine = Path()..moveTo(pillarWidth * 0.4 * entranceScale, h * 0.2)..lineTo(pillarWidth * 0.5 * entranceScale, h * 0.8);
        final rightLine = Path()..moveTo(w - pillarWidth * 0.4 * entranceScale, h * 0.2)..lineTo(w - pillarWidth * 0.5 * entranceScale, h * 0.8);
        
        // Render Glows
        canvas.drawPath(leftLine, neonPaint);
        canvas.drawPath(rightLine, neonPaint);
        
        // Render Cores
        canvas.drawPath(leftLine, corePaint);
        canvas.drawPath(rightLine, corePaint);
    }
    
    // --- 3. GLASS CONTROL DECKS (The Interface) ---
    if (_introTime > _phaseSolidify) {
       _renderGlassDeck(canvas);
    }
  }

  void _renderGlassDeck(Canvas canvas) {
      final w = size.x;
      final h = size.y;
      
      // Bottom Center Curved Deck
      final deckPath = Path()
         ..moveTo(w * 0.2, h)
         ..lineTo(w * 0.25, h * 0.85)
         ..quadraticBezierTo(w * 0.5, h * 0.82, w * 0.75, h * 0.85) // Curve up
         ..lineTo(w * 0.8, h)
         ..close();
         
      // Glass Shader (Reflective)
      final glassGrad = LinearGradient(
         begin: Alignment.topCenter,
         end: Alignment.bottomCenter,
         colors: [
            _primaryColor.withOpacity(0.1),
            _primaryColor.withOpacity(0.2),
         ],
      );
      
      canvas.drawPath(deckPath, Paint()..shader = glassGrad.createShader(Rect.fromLTWH(0, h*0.8, w, h*0.2)));
      
      // Deck Rim
      canvas.drawPath(deckPath, Paint()..color = _primaryColor.withOpacity(0.8)..style=PaintingStyle.stroke..strokeWidth=2);
      
      // Holographic Graph Elements
      final graphPaint = Paint()..color = _secondaryColor.withOpacity(0.8)..strokeWidth=2;
      double gx = w * 0.3;
      double gy = h * 0.95;
      for(int i=0; i<15; i++) {
         double hBar = 5.0 + math.Random().nextDouble() * 25.0; // Dynamic data
         // Mirror effect
         canvas.drawLine(Offset(gx + i * 15, gy), Offset(gx + i * 15, gy - hBar), graphPaint);
         canvas.drawLine(Offset(w - (gx + i * 15), gy), Offset(w - (gx + i * 15), gy - hBar), graphPaint);
      }
  }
  
  void _renderMonitor(Canvas canvas, Rect rect, String label) {
     final paint = Paint()
       ..color = _primaryColor.withOpacity(0.1)
       ..style = PaintingStyle.fill;
     
     final border = Paint()
       ..color = _primaryColor.withOpacity(0.5)
       ..style = PaintingStyle.stroke;
       
     canvas.drawRect(rect, paint);
     canvas.drawRect(rect, border);
     
     // Scanline inside monitor
     final lineP = Paint()..color = _primaryColor.withOpacity(0.2);
     for(double y = rect.top; y < rect.bottom; y+= 5) {
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), lineP);
     }
  }
  
  void _renderDataParticles(Canvas canvas) {
    if (_introTime < _phaseWireframe) return;
    
    final center = size / 2;
    for (final p in _dataParticles) {
       if (p.z <= 0.05) continue;
       final paint = Paint()..color = Colors.white.withOpacity(p.life * 0.7);
       // Perspective scale
       final scale = p.z * 3.0;
       // Radial expansion
       canvas.drawCircle(Offset(center.x + p.x * p.z, center.y + p.y * p.z), scale, paint);
    }
  }

  /// Render all towers in 3D perspective (optimized)
  void _renderTowers3D(Canvas canvas) {
    if (_introTime < _phaseWireframe) return;
    
    // In low quality, render fewer towers
    final maxRender = gameRef.reduceFx ? 8 : _towers3d.length;
    
    // Render towers from farthest to nearest (painter's algorithm)
    for (int i = 0; i < math.min(maxRender, _towers3d.length); i++) {
      final tower3d = _towers3d[i];
      
      // Simplify rendering for distant towers in low quality
      if (gameRef.reduceFx && tower3d.distanceToCamera > 300) {
        _renderSimpleTower(canvas, tower3d);
      } else {
        tower3d.render(canvas, _camera, size);
      }
    }
    
    // Render targeting reticle for hovered tower
    if (_hoveredTower != null) {
      _renderTargetingReticle(canvas, _hoveredTower!);
    }
  }

  /// Render all enemies in 3D perspective
  void _renderEnemies3D(Canvas canvas) {
    if (_introTime < _phaseWireframe) return;

    // In low quality, render fewer enemies
    final maxRender = gameRef.reduceFx ? 10 : _enemies3d.length;

    // Render enemies from farthest to nearest (painter's algorithm)
    for (int i = 0; i < math.min(maxRender, _enemies3d.length); i++) {
      final enemy3d = _enemies3d[i];

      // Simplify rendering for distant enemies in low quality
      if (gameRef.reduceFx && enemy3d.distanceToCamera > 300) {
        _renderSimpleEnemy(canvas, enemy3d);
      } else {
        enemy3d.render(canvas, _camera, size);
      }
    }
  }

  /// Simplified enemy rendering for distant enemies (performance)
  void _renderSimpleEnemy(Canvas canvas, Enemy3D enemy3d) {
    final screenPos = _camera.project(enemy3d.position3d, size);
    if (screenPos == null) return;

    final scale = math.max(0.1, 1.0 / (enemy3d.distanceToCamera * 0.012));
    final renderSize = 15.0 * enemy3d.enemy.type.sizeMult * scale;

    final center = Offset(screenPos.x, screenPos.y);
    final color = enemy3d.enemy.type.color;

    // Simple shape based on enemy type
    if (enemy3d.enemy.type.isPhantom) {
      // Ghost-like transparent circle
      canvas.drawCircle(
        center,
        renderSize * 0.5,
        Paint()..color = color.withOpacity(0.3),
      );
    } else {
      // Solid circle
      canvas.drawCircle(
        center,
        renderSize * 0.5,
        Paint()..color = color.withOpacity(0.7),
      );
    }

    // Outline
    canvas.drawCircle(
      center,
      renderSize * 0.5,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Target indicator if targeted
    if (enemy3d.isTargeted) {
      canvas.drawCircle(
        center,
        renderSize * 0.7,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  /// Simplified tower rendering for distant towers (performance)
  void _renderSimpleTower(Canvas canvas, Tower3D tower3d) {
    final screenPos = _camera.project(tower3d.position3d, size);
    if (screenPos == null) return;

    final scale = math.max(0.1, 1.0 / (tower3d.distanceToCamera * 0.01));
    final renderSize = 20.0 * scale;

    // Simple circle without gradients or shadows
    final center = Offset(screenPos.x, screenPos.y);
    
    canvas.drawCircle(
      center,
      renderSize * 0.5,
      Paint()..color = tower3d.tower.color.withOpacity(0.6),
    );
    
    canvas.drawCircle(
      center,
      renderSize * 0.5,
      Paint()
        ..color = tower3d.tower.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  /// Render targeting reticle for selected tower
  void _renderTargetingReticle(Canvas canvas, Tower3D tower3d) {
    final screenPos = _camera.project(tower3d.position3d, size);
    if (screenPos == null) return;

    final center = Offset(screenPos.x, screenPos.y);
    final color = tower3d.isSelected ? Colors.red : Colors.yellow;

    // Animated crosshair
    final pulse = math.sin(_animationTime * 4) * 0.5 + 0.5;
    final crosshairPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - 20, center.dy),
      Offset(center.dx + 20, center.dy),
      crosshairPaint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - 20),
      Offset(center.dx, center.dy + 20),
      crosshairPaint,
    );

    // Pulsing outer circle
    canvas.drawCircle(
      center,
      15 + pulse * 5,
      Paint()
        ..color = color.withOpacity(0.4 + pulse * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Target lock text
    if (tower3d.isHovered) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Selecciona una torre para armarla.',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy + 40,
        ),
      );
    }
  }
}

class _DataParticle {
  double x, y, z; 
  double life;
  double speed;
  
  _DataParticle() 
     : x = (math.Random().nextDouble() - 0.5) * 5000, // Wide spread
       y = (math.Random().nextDouble() - 0.5) * 2000,
       z = 0.001,
       life = 0.0, // Fade in
       speed = 0.2 + math.Random().nextDouble() * 0.5;
       
  void update(double dt) {
     z += dt * speed; // Move towards camera
     life = math.min(life + dt * 2, 1.0); // Fade in
     
     // Fade out when close
     if (z > 0.8) {
        life = (1.0 - z) * 5.0;
     }
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

