import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import 'enemy.dart';

/// Boss types with unique mechanics
enum BossType {
  // Mini-bosses (appear at end of each level)
  miniBoss,

  // World bosses (final level of each world)
  citadelCore,       // World 1: Rotating shields + EMP pulses
  abyssGate,         // World 2: Teleportation + portal spawning
  voidlineApex,      // World 3: Split into copies
  shardVault,        // World 4: Reflect projectiles + prismatic effects
  arcFortress,       // World 5: Orbiting turrets
  coreHunter,        // World 6: Time manipulation
  omegaGrid,         // World 7: Tower hacking
  stormTower,        // World 8: Electric storm + chain lightning
  finalGate,         // World 9: Multi-phase transformations
  omegaNexus,        // World 10: Ultimate boss with all mechanics
}

/// Boss-specific mechanics data - with pre-allocated lists to avoid per-frame allocations
class BossMechanicState {
  // Pre-allocated list capacities
  static const int _maxPortals = 4;
  static const int _maxClones = 4;
  static const int _maxTurrets = 8;
  static const int _maxHackedTowers = 10;
  static const int _maxLightningTargets = 6;

  // Citadel Core
  double shieldAngle = 0;
  int shieldCount = 4;
  double empChargeTimer = 0;

  // Abyss Gate
  double teleportCooldown = 0;
  final List<Vector2> portalPositions;
  double portalSpawnTimer = 0;

  // Voidline Apex
  bool isSplit = false;
  int splitCount = 0;
  final List<Vector2> clonePositions;

  // Shard Vault
  bool reflectionActive = false;
  double prismRotation = 0;

  // Arc Fortress
  final List<double> turretAngles;
  double turretFireTimer = 0;

  // Core Hunter
  double timeScale = 1.0;
  bool isPhaseShift = false;

  // Omega Grid
  double hackPulseTimer = 0;
  final List<int> hackedTowerIds;

  // Storm Tower
  double stormIntensity = 0;
  double lightningTimer = 0;
  final List<Vector2> lightningTargets;

  // Final Gate
  int currentPhase = 1;
  double phaseTransitionTimer = 0;

  // Omega Nexus
  int mechanicCycle = 0;
  double ultimateTimer = 0;

  // MiniBoss
  double minionSpawnTimer = 0;

  /// Constructor with pre-allocated lists
  BossMechanicState()
      : portalPositions = List<Vector2>.generate(_maxPortals, (_) => Vector2.zero(), growable: true),
        clonePositions = List<Vector2>.generate(_maxClones, (_) => Vector2.zero(), growable: true),
        turretAngles = List<double>.filled(_maxTurrets, 0, growable: true),
        hackedTowerIds = List<int>.empty(growable: true),
        lightningTargets = List<Vector2>.generate(_maxLightningTargets, (_) => Vector2.zero(), growable: true) {
    // Clear pre-allocated elements (they're just placeholders)
    portalPositions.clear();
    clonePositions.clear();
    turretAngles.clear();
    lightningTargets.clear();
  }

  /// Reset state for reuse
  void reset() {
    shieldAngle = 0;
    shieldCount = 4;
    empChargeTimer = 0;
    teleportCooldown = 0;
    portalPositions.clear();
    portalSpawnTimer = 0;
    isSplit = false;
    splitCount = 0;
    clonePositions.clear();
    reflectionActive = false;
    prismRotation = 0;
    turretAngles.clear();
    turretFireTimer = 0;
    timeScale = 1.0;
    isPhaseShift = false;
    hackPulseTimer = 0;
    hackedTowerIds.clear();
    stormIntensity = 0;
    lightningTimer = 0;
    lightningTargets.clear();
    currentPhase = 1;
    phaseTransitionTimer = 0;
    mechanicCycle = 0;
    ultimateTimer = 0;
    minionSpawnTimer = 0;
  }
}

/// Callback for boss events
typedef BossPhaseChangeCallback = void Function(Boss boss, int phase);
typedef BossAbilityCallback = void Function(Boss boss, String abilityName);

class Boss extends Enemy {
  // ═══════════════════════════════════════════════════════════════════════════
  // CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _shieldPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8;
  static final Paint _portalPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  static final Paint _clonePaint = Paint();
  static final Paint _prismPaint = Paint();
  static final Paint _turretPaint = Paint();
  static final Paint _turretBarrelPaint = Paint()
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;
  static final Paint _stormPaint = Paint();
  static final Paint _stormArcPaint = Paint()
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  static final Paint _hexFillPaint = Paint();
  static final Paint _hexStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _triPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _segmentPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _petalPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _centerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _nodeGlowPaint = Paint();
  static final Paint _nodeCorePaint = Paint();
  static final Paint _pulsePaint = Paint()
    ..style = PaintingStyle.stroke;
  static final Paint _crackPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _crackGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  static final Paint _crownPaint = Paint();
  static final Paint _crownOutlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _auraPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  // Cached Path objects
  static final Path _hexPath = Path();
  static final Path _crackPath = Path();
  static final Path _crownPath = Path();

  // Cached TextPainter for announcement
  TextPainter? _announcementPainter;
  double _lastAnnouncementAlpha = -1;

  // Cached Random instance to avoid per-frame allocations
  static final math.Random _random = math.Random();

  // Pre-allocated Vector2 for temporary calculations in render methods
  static final Vector2 _tempOffset = Vector2.zero();

  Boss({
    required super.path,
    required this.bossType,
    required this.bossLevel,
    super.speed = 40, // Bosses are slower
    super.maxHealth = 10000, // Much higher health
    super.goldReward = 500,
    super.type = EnemyType.juggernaut,
    super.startPosition,
    super.onDeath,
    super.onReachBase,
    this.onPhaseChange,
    this.onAbilityUsed,
  }) : _mechanicState = BossMechanicState() {
    // Apply boss size multiplier
    size = size * bossSizeMultiplier;

    // Initialize boss-specific mechanics
    _initializeMechanics();
  }

  final BossType bossType;
  final int bossLevel;
  final BossMechanicState _mechanicState;

  BossPhaseChangeCallback? onPhaseChange;
  BossAbilityCallback? onAbilityUsed;

  /// Boss appearance warning
  bool _hasAnnounced = false;
  double _announcementTimer = 0;
  static const double _announcementDuration = 3.0;

  /// Visual effect variables
  double _pulseScale = 1.0;
  double _animationPhase = 0.0;
  int _currentTargetIndex = 0;
  final List<_AuraParticle> _auraParticles = [];

  /// Boss is much larger
  double get bossSizeMultiplier {
    if (bossType == BossType.miniBoss) return 2.0;
    if (bossType == BossType.omegaNexus) return 4.5;
    return 3.0 + (bossLevel / 20); // Scales with level
  }

  @override
  bool get isBoss => true;

  @override
  String get displayName => _getBossDisplayName();

  String _getBossDisplayName() {
    switch (bossType) {
      case BossType.miniBoss:
        return 'ELITE GUARD';
      case BossType.citadelCore:
        return 'CITADEL CORE';
      case BossType.abyssGate:
        return 'ABYSS GATE';
      case BossType.voidlineApex:
        return 'VOIDLINE APEX';
      case BossType.shardVault:
        return 'SHARD VAULT';
      case BossType.arcFortress:
        return 'ARC FORTRESS';
      case BossType.coreHunter:
        return 'CORE HUNTER';
      case BossType.omegaGrid:
        return 'OMEGA GRID';
      case BossType.stormTower:
        return 'STORM TOWER';
      case BossType.finalGate:
        return 'FINAL GATE';
      case BossType.omegaNexus:
        return 'OMEGA NEXUS';
    }
  }

  /// Boss phases (health thresholds)
  int get currentPhase {
    final healthPercent = health / maxHealth;
    if (healthPercent > 0.75) return 1;
    if (healthPercent > 0.50) return 2;
    if (healthPercent > 0.25) return 3;
    return 4;
  }

  /// Check if boss changed phase
  void _checkPhaseChange() {
    final phase = currentPhase;
    if (phase != _mechanicState.currentPhase) {
      _mechanicState.currentPhase = phase;
      onPhaseChange?.call(this, phase);

      // Play phase change audio
      AudioService.instance.playExplosion();

      // Visual effect for phase change
      _pulseScale = 1.5;
    }
  }

  void _initializeMechanics() {
    switch (bossType) {
      case BossType.citadelCore:
        _mechanicState.shieldCount = 4;
        break;
      case BossType.arcFortress:
        for (int i = 0; i < 6; i++) {
          _mechanicState.turretAngles.add(i * math.pi / 3);
        }
        break;
      case BossType.voidlineApex:
        _mechanicState.splitCount = 3;
        break;
      default:
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isAlive) return;

    // Update animation phase
    _animationPhase += dt;

    // Decay pulse scale
    if (_pulseScale > 1.0) {
      _pulseScale -= dt * 2;
      if (_pulseScale < 1.0) _pulseScale = 1.0;
    }

    // Update aura particles with single-pass removal
    int writeIdx = 0;
    for (int i = 0; i < _auraParticles.length; i++) {
      final particle = _auraParticles[i];
      particle.update(dt);
      if (particle.isAlive) {
        if (writeIdx != i) _auraParticles[writeIdx] = particle;
        writeIdx++;
      }
    }
    if (writeIdx < _auraParticles.length) {
      _auraParticles.removeRange(writeIdx, _auraParticles.length);
    }
    // Spawn new particles using cached Random instance
    if (_auraParticles.length < 50) {
      final angle = _random.nextDouble() * math.pi * 2;
      final dist = _random.nextDouble() * size.x * 0.5;
      // Reuse _tempOffset to avoid Vector2 allocation
      _tempOffset.setValues(math.cos(angle) * dist, math.sin(angle) * dist);
      _auraParticles.add(_AuraParticle(
        startOffset: _tempOffset.clone(),
        color: type.color,
        random: _random,
      ));
    }

    // Check for phase changes
    _checkPhaseChange();

    // Update boss-specific mechanics
    _updateBossMechanics(dt);

    // Announcement timer
    if (!_hasAnnounced) {
      _announcementTimer += dt;
      if (_announcementTimer >= _announcementDuration) {
        _hasAnnounced = true;
      }
    }
  }

  void _updateBossMechanics(double dt) {
    switch (bossType) {
      case BossType.citadelCore:
        _updateCitadelCore(dt);
        break;
      case BossType.abyssGate:
        _updateAbyssGate(dt);
        break;
      case BossType.voidlineApex:
        _updateVoidlineApex(dt);
        break;
      case BossType.shardVault:
        _updateShardVault(dt);
        break;
      case BossType.arcFortress:
        _updateArcFortress(dt);
        break;
      case BossType.coreHunter:
        _updateCoreHunter(dt);
        break;
      case BossType.omegaGrid:
        _updateOmegaGrid(dt);
        break;
      case BossType.stormTower:
        _updateStormTower(dt);
        break;
      case BossType.finalGate:
        _updateFinalGate(dt);
        break;
      case BossType.omegaNexus:
        _updateOmegaNexus(dt);
        break;
      case BossType.miniBoss:
        _updateMiniBoss(dt);
        break;
    }
  }

  void _updateCitadelCore(double dt) {
    // Rotate shields
    _mechanicState.shieldAngle += dt * 0.8;

    // EMP pulse ability
    _mechanicState.empChargeTimer += dt;
    if (_mechanicState.empChargeTimer >= 5.0) {
      _mechanicState.empChargeTimer = 0;
      _triggerEmpPulse();
    }
  }

  void _updateAbyssGate(double dt) {
    // Teleport cooldown
    if (_mechanicState.teleportCooldown > 0) {
      _mechanicState.teleportCooldown -= dt;
    } else if (currentPhase >= 2) {
      _teleport();
      _mechanicState.teleportCooldown = 8.0;
    }

    // Spawn portals
    _mechanicState.portalSpawnTimer += dt;
    if (_mechanicState.portalSpawnTimer >= 6.0 && currentPhase >= 2) {
      _mechanicState.portalSpawnTimer = 0;
      _spawnPortal();
    }
  }

  void _updateVoidlineApex(double dt) {
    // Split mechanic at phase 2 and 4
    if ((currentPhase == 2 || currentPhase == 4) && !_mechanicState.isSplit) {
      _splitIntoClones();
    }
  }

  void _updateShardVault(double dt) {
    // Rotate prisms
    _mechanicState.prismRotation += dt * 1.2;

    // Activate reflection in phase 2+
    _mechanicState.reflectionActive = currentPhase >= 2;
  }

  void _updateArcFortress(double dt) {
    // Rotate turrets
    for (int i = 0; i < _mechanicState.turretAngles.length; i++) {
      _mechanicState.turretAngles[i] += dt * 0.5;
    }

    // Fire from turrets
    _mechanicState.turretFireTimer += dt;
    if (_mechanicState.turretFireTimer >= 2.0) {
      _mechanicState.turretFireTimer = 0;
      _fireTurrets();
    }
  }

  void _updateCoreHunter(double dt) {
    // Alternate between speed up and slow down
    final cycle = (dt * 0.3) % (math.pi * 2);
    _mechanicState.timeScale = 0.5 + math.sin(cycle) * 0.5;

    // Phase shift in phase 3+
    if (currentPhase >= 3) {
      _mechanicState.isPhaseShift = (cycle % math.pi) < math.pi / 2;
    }
  }

  void _updateOmegaGrid(double dt) {
    // Hack pulse
    _mechanicState.hackPulseTimer += dt;
    if (_mechanicState.hackPulseTimer >= 7.0 && currentPhase >= 2) {
      _mechanicState.hackPulseTimer = 0;
      _hackNearbyTowers();
    }
  }

  void _updateStormTower(double dt) {
    // Build storm intensity
    _mechanicState.stormIntensity = (currentPhase / 4.0).clamp(0.0, 1.0);

    // Chain lightning
    _mechanicState.lightningTimer += dt;
    if (_mechanicState.lightningTimer >= 3.0) {
      _mechanicState.lightningTimer = 0;
      _triggerChainLightning();
    }
  }

  void _updateFinalGate(double dt) {
    // Phase transitions with different mechanics per phase
    if (_mechanicState.phaseTransitionTimer > 0) {
      _mechanicState.phaseTransitionTimer -= dt;
    }
  }

  void _updateOmegaNexus(double dt) {
    // Cycle through all boss mechanics
    _mechanicState.ultimateTimer += dt;

    // Change mechanic every 10 seconds
    if (_mechanicState.ultimateTimer >= 10.0) {
      _mechanicState.ultimateTimer = 0;
      _mechanicState.mechanicCycle = (_mechanicState.mechanicCycle + 1) % 9;
      _activateOmegaMechanic();
    }
  }

  void _updateMiniBoss(double dt) {
    // Mini-bosses have enhanced stats and now spawn minions
    _mechanicState.minionSpawnTimer += dt;
    if (_mechanicState.minionSpawnTimer >= 5.0) {
      _mechanicState.minionSpawnTimer = 0;
      _spawnMinions();
    }
  }

  // Boss ability implementations
  void _spawnMinions() {
    onAbilityUsed?.call(this, 'spawn_minions');
    AudioService.instance.playShoot(); // Reuse a sound for feedback
  }

  void _triggerEmpPulse() {
    onAbilityUsed?.call(this, 'emp_pulse');
    AudioService.instance.playExplosion();
  }

  void _teleport() {
    // Find random position on path ahead
    if (path.isNotEmpty && _currentTargetIndex < path.length - 3) {
      final targetIndex = math.min(_currentTargetIndex + 5, path.length - 1);
      position.setFrom(path[targetIndex]);
      _currentTargetIndex = targetIndex;
      onAbilityUsed?.call(this, 'teleport');
    }
  }

  void _spawnPortal() {
    // Store portal position for rendering
    _mechanicState.portalPositions.add(position.clone());
    if (_mechanicState.portalPositions.length > 3) {
      _mechanicState.portalPositions.removeAt(0);
    }
    onAbilityUsed?.call(this, 'spawn_portal');
  }

  void _splitIntoClones() {
    _mechanicState.isSplit = true;
    _mechanicState.clonePositions.clear();

    // Create visual clone positions around boss
    for (int i = 0; i < _mechanicState.splitCount; i++) {
      final angle = (i / _mechanicState.splitCount) * math.pi * 2;
      final offset = Vector2(
        math.cos(angle) * size.x * 2,
        math.sin(angle) * size.x * 2,
      );
      _mechanicState.clonePositions.add(position + offset);
    }

    onAbilityUsed?.call(this, 'split');
  }

  void _fireTurrets() {
    onAbilityUsed?.call(this, 'turret_fire');
  }

  void _hackNearbyTowers() {
    onAbilityUsed?.call(this, 'tower_hack');
  }

  void _triggerChainLightning() {
    onAbilityUsed?.call(this, 'chain_lightning');
    AudioService.instance.playExplosion();
  }

  void _activateOmegaMechanic() {
    final mechanics = [
      'emp_pulse',
      'teleport',
      'split',
      'reflection',
      'turret_fire',
      'time_manipulation',
      'tower_hack',
      'chain_lightning',
      'phase_shift',
    ];

    if (_mechanicState.mechanicCycle < mechanics.length) {
      onAbilityUsed?.call(this, mechanics[_mechanicState.mechanicCycle]);
    }
  }

  @override
  void render(Canvas canvas) {
    // Render boss announcement
    if (!_hasAnnounced) {
      _renderAnnouncement(canvas);
    }

    // Render boss-specific visuals
    _renderBossEffects(canvas);

    // Render base enemy
    super.render(canvas);

    // Boss crown/aura
    _renderBossCrown(canvas);
  }

  void _renderAnnouncement(Canvas canvas) {
    final progress = (_announcementTimer / _announcementDuration).clamp(0.0, 1.0);
    final alpha = progress < 0.5 ? progress * 2 : (1 - progress) * 2;

    // Only relayout if alpha changed significantly (reduces TextPainter work)
    if (_announcementPainter == null || (alpha - _lastAnnouncementAlpha).abs() > 0.01) {
      _lastAnnouncementAlpha = alpha;
      _announcementPainter = TextPainter(
        text: TextSpan(
          text: 'BOSS INCOMING',
          style: TextStyle(
            color: const Color(0xFFFF0066).withOpacity(alpha),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      _announcementPainter!.layout();
    }

    _announcementPainter!.paint(
      canvas,
      Offset(-_announcementPainter!.width / 2, -size.y - 60),
    );
  }

  void _renderBossEffects(Canvas canvas) {
    final allowBlur = Enemy.allowBlur;

    // Render epic aura
    _renderAura(canvas);

    // Render geometric pattern shield (all bosses)
    _renderGeometricShield(canvas, allowBlur);

    switch (bossType) {
      case BossType.citadelCore:
        _renderShields(canvas, allowBlur);
        break;
      case BossType.abyssGate:
        _renderPortals(canvas, allowBlur);
        break;
      case BossType.voidlineApex:
        _renderClones(canvas, allowBlur);
        break;
      case BossType.shardVault:
        _renderPrisms(canvas, allowBlur);
        break;
      case BossType.arcFortress:
        _renderTurrets(canvas, allowBlur);
        break;
      case BossType.stormTower:
        _renderStorm(canvas, allowBlur);
        break;
      default:
        break;
    }
  }

  void _renderAura(Canvas canvas) {
    for (final particle in _auraParticles) {
      particle.render(canvas);
    }
  }

  void _renderShields(Canvas canvas, bool allowBlur) {
    final radius = size.x / 2;
    final shieldRadius = radius * 1.8;

    _shieldPaint.color = const Color(0xFF00FFFF).withOpacity(0.6);
    _shieldPaint.maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 4) : null;

    for (int i = 0; i < _mechanicState.shieldCount; i++) {
      final angle = _mechanicState.shieldAngle + (i * math.pi * 2 / _mechanicState.shieldCount);
      final arcStart = angle - math.pi / 8;
      final arcSweep = math.pi / 4;

      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: shieldRadius),
        arcStart,
        arcSweep,
        false,
        _shieldPaint,
      );
    }
  }

  void _renderPortals(Canvas canvas, bool allowBlur) {
    _portalPaint.color = const Color(0xFFAA00FF).withOpacity(0.7);
    _portalPaint.maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 6) : null;

    for (final portalPos in _mechanicState.portalPositions) {
      // Use cached offset to avoid Vector2 allocation from subtraction
      _tempOffset.setFrom(portalPos);
      _tempOffset.sub(position);

      canvas.drawCircle(
        Offset(_tempOffset.x, _tempOffset.y),
        30,
        _portalPaint,
      );
    }
  }

  void _renderClones(Canvas canvas, bool allowBlur) {
    if (!_mechanicState.isSplit) return;

    _clonePaint.color = type.color.withOpacity(0.4);
    _clonePaint.maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 8) : null;

    final cloneRadius = size.x / 2;
    for (final clonePos in _mechanicState.clonePositions) {
      // Use cached offset to avoid Vector2 allocation from subtraction
      _tempOffset.setFrom(clonePos);
      _tempOffset.sub(position);

      canvas.drawCircle(
        Offset(_tempOffset.x, _tempOffset.y),
        cloneRadius,
        _clonePaint,
      );
    }
  }

  void _renderPrisms(Canvas canvas, bool allowBlur) {
    final radius = size.x / 2;
    final prismCount = 6;

    _prismPaint.maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 4) : null;

    for (int i = 0; i < prismCount; i++) {
      final angle = _mechanicState.prismRotation + (i * math.pi * 2 / prismCount);
      final dist = radius * 2.0;
      final x = math.cos(angle) * dist;
      final y = math.sin(angle) * dist;

      // Rainbow prism effect
      final hue = (i / prismCount) * 360;
      _prismPaint.color = HSVColor.fromAHSV(0.6, hue, 1.0, 1.0).toColor();

      canvas.drawCircle(Offset(x, y), 8, _prismPaint);
    }
  }

  void _renderTurrets(Canvas canvas, bool allowBlur) {
    final radius = size.x / 2;

    _turretPaint.color = const Color(0xFFFF6600).withOpacity(0.8);
    _turretBarrelPaint.color = const Color(0xFFFF3300);

    for (int i = 0; i < _mechanicState.turretAngles.length; i++) {
      final angle = _mechanicState.turretAngles[i];
      final dist = radius * 1.5;
      final x = math.cos(angle) * dist;
      final y = math.sin(angle) * dist;

      canvas.drawCircle(Offset(x, y), 12, _turretPaint);

      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(angle) * 20, y + math.sin(angle) * 20),
        _turretBarrelPaint,
      );
    }
  }

  void _renderStorm(Canvas canvas, bool allowBlur) {
    final radius = size.x / 2;
    final stormRadius = radius * (2.0 + _mechanicState.stormIntensity * 2.0);

    // Storm aura
    _stormPaint.color = const Color(0xFFFFFF00).withOpacity(0.3 * _mechanicState.stormIntensity);
    _stormPaint.maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 20) : null;

    canvas.drawCircle(Offset.zero, stormRadius, _stormPaint);

    // Lightning arcs
    _stormArcPaint.color = const Color(0xFFFFFFFF).withOpacity(0.6);

    for (int i = 0; i < 6; i++) {
      final angle = (_animationPhase * 2 + i * math.pi / 3);

      canvas.drawLine(
        Offset.zero,
        Offset(
          math.cos(angle) * stormRadius,
          math.sin(angle) * stormRadius,
        ),
        _stormArcPaint,
      );
    }
  }

  /// Renders a geometric pattern shield around the boss
  void _renderGeometricShield(Canvas canvas, bool allowBlur) {
    final radius = size.x / 2;
    final shieldRadius = radius * 1.6;
    final animPhase = _animationPhase;

    // Shield intensity based on health (stronger shield when damaged)
    final healthPct = health / maxHealth;
    final shieldIntensity = 0.4 + (1 - healthPct) * 0.5;

    // Boss-specific shield color
    Color shieldColor;
    switch (bossType) {
      case BossType.citadelCore:
        shieldColor = const Color(0xFF00FFFF);
        break;
      case BossType.abyssGate:
        shieldColor = const Color(0xFFAA00FF);
        break;
      case BossType.voidlineApex:
        shieldColor = const Color(0xFF6600FF);
        break;
      case BossType.shardVault:
        shieldColor = const Color(0xFFFF00FF);
        break;
      case BossType.arcFortress:
        shieldColor = const Color(0xFFFFFF00);
        break;
      case BossType.coreHunter:
        shieldColor = const Color(0xFF00FF00);
        break;
      case BossType.omegaGrid:
        shieldColor = const Color(0xFF00FF66);
        break;
      case BossType.stormTower:
        shieldColor = const Color(0xFF0099FF);
        break;
      case BossType.finalGate:
        shieldColor = const Color(0xFFFF3300);
        break;
      case BossType.omegaNexus:
        shieldColor = const Color(0xFFFF0066);
        break;
      case BossType.miniBoss:
        shieldColor = const Color(0xFFFF6600);
        break;
    }

    final secondaryColor = HSLColor.fromColor(shieldColor)
        .withHue((HSLColor.fromColor(shieldColor).hue + 60) % 360)
        .toColor();

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: OUTER HEXAGONAL GRID PATTERN
    // ═══════════════════════════════════════════════════════════════════════
    final hexCount = 12;
    final hexRadius = shieldRadius * 0.25;

    _hexFillPaint.maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 4) : null;

    for (int i = 0; i < hexCount; i++) {
      final hexAngle = (i * math.pi * 2 / hexCount) + animPhase * 0.3;
      final hexDist = shieldRadius * (0.9 + math.sin(animPhase * 2 + i) * 0.1);
      final hexX = math.cos(hexAngle) * hexDist;
      final hexY = math.sin(hexAngle) * hexDist;

      final hexAlpha = shieldIntensity * (0.3 + math.sin(animPhase * 3 + i * 0.5) * 0.15);

      // Draw hexagon using cached path
      _hexPath.reset();
      for (int j = 0; j < 6; j++) {
        final vertAngle = j * math.pi / 3 + animPhase * 0.5;
        final vx = hexX + math.cos(vertAngle) * hexRadius;
        final vy = hexY + math.sin(vertAngle) * hexRadius;
        if (j == 0) {
          _hexPath.moveTo(vx, vy);
        } else {
          _hexPath.lineTo(vx, vy);
        }
      }
      _hexPath.close();

      // Fill
      _hexFillPaint.color = shieldColor.withOpacity(hexAlpha * 0.2);
      canvas.drawPath(_hexPath, _hexFillPaint);

      // Stroke
      _hexStrokePaint.color = shieldColor.withOpacity(hexAlpha);
      canvas.drawPath(_hexPath, _hexStrokePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: TRIANGULAR LATTICE CONNECTIONS
    // ═══════════════════════════════════════════════════════════════════════
    final triangleCount = 8;
    final triR1 = shieldRadius * 0.5;
    final triR2 = shieldRadius * 1.1;

    for (int i = 0; i < triangleCount; i++) {
      final triAngle = (i * math.pi * 2 / triangleCount) + animPhase * 0.2;
      final nextAngle = ((i + 1) * math.pi * 2 / triangleCount) + animPhase * 0.2;

      final x1 = math.cos(triAngle) * triR1;
      final y1 = math.sin(triAngle) * triR1;
      final x2 = math.cos(triAngle) * triR2;
      final y2 = math.sin(triAngle) * triR2;
      final x3 = math.cos(nextAngle) * triR2;
      final y3 = math.sin(nextAngle) * triR2;

      final triAlpha = shieldIntensity * (0.2 + math.sin(animPhase * 4 + i * 0.8) * 0.1);

      _triPaint.color = secondaryColor.withOpacity(triAlpha);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), _triPaint);
      canvas.drawLine(Offset(x2, y2), Offset(x3, y3), _triPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: ROTATING GEOMETRIC RINGS
    // ═══════════════════════════════════════════════════════════════════════
    for (int ring = 0; ring < 3; ring++) {
      final ringRadius = shieldRadius * (0.6 + ring * 0.25);
      final ringAlpha = shieldIntensity * (0.25 - ring * 0.05);
      final ringRotation = animPhase * (0.5 + ring * 0.2) * (ring % 2 == 0 ? 1 : -1);

      // Draw segmented ring (not complete circle)
      final segmentCount = 6 + ring * 2;
      final gapAngle = math.pi / (segmentCount * 2);

      _segmentPaint.color = shieldColor.withOpacity(ringAlpha);
      _segmentPaint.strokeWidth = 2 - ring * 0.3;

      for (int s = 0; s < segmentCount; s++) {
        final segStart = ringRotation + (s * math.pi * 2 / segmentCount) + gapAngle;
        final segSweep = (math.pi * 2 / segmentCount) - gapAngle * 2;

        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: ringRadius),
          segStart,
          segSweep,
          false,
          _segmentPaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: SACRED GEOMETRY PATTERN (Center)
    // ═══════════════════════════════════════════════════════════════════════
    final sacredRadius = shieldRadius * 0.4;
    final sacredAlpha = shieldIntensity * 0.4;

    // Flower of life pattern (overlapping circles)
    final petalCount = 6;
    final petalRadius = sacredRadius * 0.5;

    _petalPaint.color = shieldColor.withOpacity(sacredAlpha * 0.5);
    _petalPaint.maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 2) : null;

    for (int i = 0; i < petalCount; i++) {
      final petalAngle = (i * math.pi * 2 / petalCount) + animPhase * 0.4;
      final petalX = math.cos(petalAngle) * petalRadius;
      final petalY = math.sin(petalAngle) * petalRadius;

      canvas.drawCircle(Offset(petalX, petalY), petalRadius, _petalPaint);
    }

    // Center circle
    _centerPaint.color = shieldColor.withOpacity(sacredAlpha);
    canvas.drawCircle(Offset.zero, petalRadius, _centerPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: ENERGY NODES AT INTERSECTIONS
    // ═══════════════════════════════════════════════════════════════════════
    final nodeCount = 6;
    final nodeDist = shieldRadius * 0.7;
    _nodeGlowPaint.maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 8) : null;

    for (int i = 0; i < nodeCount; i++) {
      final nodeAngle = (i * math.pi * 2 / nodeCount) + animPhase * 0.6;
      final nodeX = math.cos(nodeAngle) * nodeDist;
      final nodeY = math.sin(nodeAngle) * nodeDist;

      final nodePulse = 0.6 + math.sin(animPhase * 4 + i * 1.2) * 0.4;
      final nodeAlpha = shieldIntensity * nodePulse;

      // Node glow
      _nodeGlowPaint.color = shieldColor.withOpacity(nodeAlpha * 0.4);
      canvas.drawCircle(Offset(nodeX, nodeY), 6, _nodeGlowPaint);

      // Node core
      _nodeCorePaint.color = Colors.white.withOpacity(nodeAlpha * 0.8);
      canvas.drawCircle(Offset(nodeX, nodeY), 2, _nodeCorePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: SHIELD PULSE RIPPLES
    // ═══════════════════════════════════════════════════════════════════════
    _pulsePaint.maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 4) : null;

    for (int i = 0; i < 2; i++) {
      final pulsePhase = (animPhase * 1.5 + i * 0.5) % 1.0;
      final pulseRadius = shieldRadius * (0.3 + pulsePhase * 0.9);
      final pulseAlpha = (1 - pulsePhase) * shieldIntensity * 0.3;

      if (pulseAlpha < 0.03) continue;

      _pulsePaint.color = shieldColor.withOpacity(pulseAlpha);
      _pulsePaint.strokeWidth = 2 * (1 - pulsePhase);

      canvas.drawCircle(Offset.zero, pulseRadius, _pulsePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: DAMAGE CRACKS (When health is low)
    // ═══════════════════════════════════════════════════════════════════════
    if (healthPct < 0.5) {
      final crackIntensity = (0.5 - healthPct) * 2; // 0 to 1
      final crackCount = (4 * crackIntensity).ceil();

      _crackPaint.color = Colors.white.withOpacity(0.3 * crackIntensity);
      _crackGlowPaint.color = const Color(0xFFFF3300).withOpacity(0.2 * crackIntensity);
      _crackGlowPaint.maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 4) : null;

      for (int i = 0; i < crackCount; i++) {
        final crackAngle = _animationPhase * 0.1 + i * math.pi * 2 / crackCount + i * 0.5;
        final crackLength = shieldRadius * (0.3 + crackIntensity * 0.5);

        // Jagged crack line using cached path
        _crackPath.reset();
        _crackPath.moveTo(0, 0);

        double cx = 0, cy = 0;
        for (int j = 0; j < 5; j++) {
          final t = (j + 1) / 5;
          final jitter = (math.Random(i * 10 + j).nextDouble() - 0.5) * 15;
          cx = math.cos(crackAngle) * crackLength * t + jitter * math.sin(crackAngle);
          cy = math.sin(crackAngle) * crackLength * t + jitter * math.cos(crackAngle);
          _crackPath.lineTo(cx, cy);
        }

        canvas.drawPath(_crackPath, _crackPaint);
        canvas.drawPath(_crackPath, _crackGlowPaint);
      }
    }
  }

  void _renderBossCrown(Canvas canvas) {
    final allowBlur = Enemy.allowBlur;
    final radius = size.x / 2;
    final crownRadius = radius * 2.2;

    // Epic crown for boss using cached path
    _crownPath.reset();
    const spikes = 12;
    for (int i = 0; i < spikes * 2; i++) {
      final angle = (i / (spikes * 2)) * math.pi * 2;
      final r = (i % 2 == 0) ? crownRadius : crownRadius * 0.85;
      final x = math.cos(angle) * r;
      final y = math.sin(angle) * r;

      if (i == 0) {
        _crownPath.moveTo(x, y);
      } else {
        _crownPath.lineTo(x, y);
      }
    }
    _crownPath.close();

    // Gradient crown
    _crownPaint.color = const Color(0xFFFF0066).withOpacity(0.4);
    _crownPaint.maskFilter = allowBlur ? const MaskFilter.blur(BlurStyle.normal, 6) : null;

    canvas.drawPath(_crownPath, _crownPaint);

    // Crown outline
    _crownOutlinePaint.color = const Color(0xFFFF0066).withOpacity(0.8);

    canvas.drawPath(_crownPath, _crownOutlinePaint);
  }
}

/// Particle for the boss's epic aura effect
class _AuraParticle {
  _AuraParticle({
    required this.startOffset,
    required this.color,
    required math.Random random,
  }) {
    _timer = 0;
    _lifetime = 0.8 + random.nextDouble() * 1.2;
    _velocityX = (random.nextDouble() - 0.5) * 40;
    _velocityY = (random.nextDouble() - 0.5) * 40;
  }

  // Static cached paint for all aura particles
  static final Paint _paint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  late final double _lifetime;
  // Store velocity as separate doubles to avoid Vector2 allocations in update
  late final double _velocityX;
  late final double _velocityY;
  late final Color color;

  // Current position stored as doubles to avoid Vector2 operations
  double _posX = 0;
  double _posY = 0;
  final Vector2 startOffset;
  double _timer = 0;

  bool get isAlive => _timer < _lifetime;
  double get progress => (_timer / _lifetime).clamp(0.0, 1.0);

  void update(double dt) {
    _timer += dt;
    final p = progress;
    // Avoid Vector2 allocation by computing position directly
    _posX = startOffset.x + _velocityX * p;
    _posY = startOffset.y + _velocityY * p;
  }

  void render(Canvas canvas) {
    final opacity = (1.0 - progress) * 0.5;
    final size = (1.0 - progress) * 12;

    _paint.color = color.withOpacity(opacity);

    canvas.drawCircle(Offset(_posX, _posY), size, _paint);
  }
}
