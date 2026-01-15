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

/// Boss-specific mechanics data
class BossMechanicState {
  // Citadel Core
  double shieldAngle = 0;
  int shieldCount = 4;
  double empChargeTimer = 0;

  // Abyss Gate
  double teleportCooldown = 0;
  final List<Vector2> portalPositions = [];
  double portalSpawnTimer = 0;

  // Voidline Apex
  bool isSplit = false;
  int splitCount = 0;
  final List<Vector2> clonePositions = [];

  // Shard Vault
  bool reflectionActive = false;
  double prismRotation = 0;

  // Arc Fortress
  final List<double> turretAngles = [];
  double turretFireTimer = 0;

  // Core Hunter
  double timeScale = 1.0;
  bool isPhaseShift = false;

  // Omega Grid
  double hackPulseTimer = 0;
  final List<int> hackedTowerIds = [];

  // Storm Tower
  double stormIntensity = 0;
  double lightningTimer = 0;
  final List<Vector2> lightningTargets = [];

  // Final Gate
  int currentPhase = 1;
  double phaseTransitionTimer = 0;

  // Omega Nexus
  int mechanicCycle = 0;
  double ultimateTimer = 0;

  // MiniBoss
  double minionSpawnTimer = 0;
}

/// Callback for boss events
typedef BossPhaseChangeCallback = void Function(Boss boss, int phase);
typedef BossAbilityCallback = void Function(Boss boss, String abilityName);

class Boss extends Enemy {
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

    // Update aura particles
    _auraParticles.removeWhere((p) => !p.isAlive);
    for (final particle in _auraParticles) {
      particle.update(dt);
    }
    // Spawn new particles
    if (_auraParticles.length < 50) {
      final random = math.Random();
      final angle = random.nextDouble() * math.pi * 2;
      final offset = Vector2(math.cos(angle), math.sin(angle)) * (random.nextDouble() * size.x * 0.5);
      _auraParticles.add(_AuraParticle(startOffset: offset, color: type.color));
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
      position = path[targetIndex].clone();
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

    // Warning text
    final textPaint = TextPainter(
      text: TextSpan(
        text: 'BOSS INCOMING',
        style: TextStyle(
          color: Color(0xFFFF0066).withOpacity(alpha),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPaint.layout();
    textPaint.paint(
      canvas,
      Offset(-textPaint.width / 2, -size.y - 60),
    );
  }

  void _renderBossEffects(Canvas canvas) {
    final allowBlur = Enemy.allowBlur;

    // Render epic aura
    _renderAura(canvas);

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

    for (int i = 0; i < _mechanicState.shieldCount; i++) {
      final angle = _mechanicState.shieldAngle + (i * math.pi * 2 / _mechanicState.shieldCount);
      final arcStart = angle - math.pi / 8;
      final arcSweep = math.pi / 4;

      final shieldPaint = Paint()
        ..color = Color(0xFF00FFFF).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = allowBlur ? MaskFilter.blur(BlurStyle.normal, 4) : null;

      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: shieldRadius),
        arcStart,
        arcSweep,
        false,
        shieldPaint,
      );
    }
  }

  void _renderPortals(Canvas canvas, bool allowBlur) {
    for (final portalPos in _mechanicState.portalPositions) {
      final offset = portalPos - position;

      // Portal ring
      final portalPaint = Paint()
        ..color = Color(0xFFAA00FF).withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = allowBlur ? MaskFilter.blur(BlurStyle.normal, 6) : null;

      canvas.drawCircle(
        Offset(offset.x, offset.y),
        30,
        portalPaint,
      );
    }
  }

  void _renderClones(Canvas canvas, bool allowBlur) {
    if (!_mechanicState.isSplit) return;

    for (final clonePos in _mechanicState.clonePositions) {
      final offset = clonePos - position;

      // Ghost clone
      final clonePaint = Paint()
        ..color = type.color.withOpacity(0.4)
        ..maskFilter = allowBlur ? MaskFilter.blur(BlurStyle.normal, 8) : null;

      canvas.drawCircle(
        Offset(offset.x, offset.y),
        size.x / 2,
        clonePaint,
      );
    }
  }

  void _renderPrisms(Canvas canvas, bool allowBlur) {
    final radius = size.x / 2;
    final prismCount = 6;

    for (int i = 0; i < prismCount; i++) {
      final angle = _mechanicState.prismRotation + (i * math.pi * 2 / prismCount);
      final dist = radius * 2.0;
      final x = math.cos(angle) * dist;
      final y = math.sin(angle) * dist;

      // Rainbow prism effect
      final hue = (i / prismCount) * 360;
      final prismPaint = Paint()
        ..color = HSVColor.fromAHSV(0.6, hue, 1.0, 1.0).toColor()
        ..maskFilter = allowBlur ? MaskFilter.blur(BlurStyle.normal, 4) : null;

      canvas.drawCircle(Offset(x, y), 8, prismPaint);
    }
  }

  void _renderTurrets(Canvas canvas, bool allowBlur) {
    final radius = size.x / 2;

    for (int i = 0; i < _mechanicState.turretAngles.length; i++) {
      final angle = _mechanicState.turretAngles[i];
      final dist = radius * 1.5;
      final x = math.cos(angle) * dist;
      final y = math.sin(angle) * dist;

      // Turret
      final turretPaint = Paint()
        ..color = Color(0xFFFF6600).withOpacity(0.8);

      canvas.drawCircle(Offset(x, y), 12, turretPaint);

      // Turret barrel
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(angle) * 20, y + math.sin(angle) * 20),
        Paint()
          ..color = Color(0xFFFF3300)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _renderStorm(Canvas canvas, bool allowBlur) {
    final radius = size.x / 2;
    final stormRadius = radius * (2.0 + _mechanicState.stormIntensity * 2.0);

    // Storm aura
    final stormPaint = Paint()
      ..color = Color(0xFFFFFF00).withOpacity(0.3 * _mechanicState.stormIntensity)
      ..maskFilter = allowBlur ? MaskFilter.blur(BlurStyle.normal, 20) : null;

    canvas.drawCircle(Offset.zero, stormRadius, stormPaint);

    // Lightning arcs
    for (int i = 0; i < 6; i++) {
      final angle = (_animationPhase * 2 + i * math.pi / 3);
      final arcPaint = Paint()
        ..color = Color(0xFFFFFFFF).withOpacity(0.6)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset.zero,
        Offset(
          math.cos(angle) * stormRadius,
          math.sin(angle) * stormRadius,
        ),
        arcPaint,
      );
    }
  }

  void _renderBossCrown(Canvas canvas) {
    final allowBlur = Enemy.allowBlur;
    final radius = size.x / 2;
    final crownRadius = radius * 2.2;

    // Epic crown for boss
    final crownPath = Path();
    const spikes = 12;
    for (int i = 0; i < spikes * 2; i++) {
      final angle = (i / (spikes * 2)) * math.pi * 2;
      final r = (i % 2 == 0) ? crownRadius : crownRadius * 0.85;
      final x = math.cos(angle) * r;
      final y = math.sin(angle) * r;

      if (i == 0) {
        crownPath.moveTo(x, y);
      } else {
        crownPath.lineTo(x, y);
      }
    }
    crownPath.close();

    // Gradient crown
    final crownPaint = Paint()
      ..color = Color(0xFFFF0066).withOpacity(0.4)
      ..maskFilter = allowBlur ? MaskFilter.blur(BlurStyle.normal, 6) : null;

    canvas.drawPath(crownPath, crownPaint);

    // Crown outline
    final outlinePaint = Paint()
      ..color = Color(0xFFFF0066).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

// ... (end of _renderBossCrown method)
    canvas.drawPath(crownPath, outlinePaint);
  }
}

/// Particle for the boss's epic aura effect
class _AuraParticle {
  _AuraParticle({
    required this.startOffset,
    required this.color,
  }) {
    _timer = 0;
    _lifetime = 0.8 + math.Random().nextDouble() * 1.2;
    _velocity = Vector2(
      (math.Random().nextDouble() - 0.5) * 40,
      (math.Random().nextDouble() - 0.5) * 40,
    );
  }

  late final double _lifetime;
  late final Vector2 _velocity;
  late final Color color;

  Vector2 position = Vector2.zero();
  final Vector2 startOffset;
  double _timer;

  bool get isAlive => _timer < _lifetime;
  double get progress => (_timer / _lifetime).clamp(0.0, 1.0);

  void update(double dt) {
    _timer += dt;
    position = startOffset + _velocity * progress;
  }

  void render(Canvas canvas) {
    final opacity = (1.0 - progress) * 0.5;
    final size = (1.0 - progress) * 12;

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(position, size, paint);
  }
}
