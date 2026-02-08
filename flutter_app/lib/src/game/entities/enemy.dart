import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../bored_games_game.dart';
import '../effects/damage_number_effect.dart';

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

/// Callback types for enemy events
typedef EnemyDeathCallback = void Function(Enemy enemy);
typedef EnemyReachBaseCallback = void Function(Enemy enemy);

/// Enemy type with visual and stat modifiers
/// Organized by world themes for unique encounters
enum EnemyType {
  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 1: NEON FRONTIER - Basic enemy types (tutorial)
  // ═══════════════════════════════════════════════════════════════════════════
  runner(
      color: Color(0xFFFF7043),
      speedMult: 1.0,
      healthMult: 1.0,
      sizeMult: 1.0,
      isPhantom: false,
      world: 1),
  overloaded(
      color: Color(0xFFFF0066),
      speedMult: 1.4,
      healthMult: 0.8,
      sizeMult: 0.9,
      isPhantom: false,
      world: 1),
  juggernaut(
      color: Color(0xFF9C27B0),
      speedMult: 0.6,
      healthMult: 2.5,
      sizeMult: 1.4,
      isPhantom: false,
      world: 1),
  phantom(
      color: Color(0xFF00FFAA),
      speedMult: 1.1,
      healthMult: 1.2,
      sizeMult: 0.95,
      isPhantom: true,
      world: 1),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 2: RIFT WARS - Dimensional glitch enemies
  // ═══════════════════════════════════════════════════════════════════════════
  glitcher(
      color: Color(0xFF00FFFF),
      speedMult: 1.2,
      healthMult: 0.9,
      sizeMult: 0.85,
      isPhantom: false,
      world: 2),
  riftwalker(
      color: Color(0xFFFF00FF),
      speedMult: 0.8,
      healthMult: 1.8,
      sizeMult: 1.2,
      isPhantom: true,
      world: 2),
  voidling(
      color: Color(0xFF6600FF),
      speedMult: 1.3,
      healthMult: 0.7,
      sizeMult: 0.75,
      isPhantom: false,
      world: 2),
  dimensionBreaker(
      color: Color(0xFFFF3399),
      speedMult: 0.5,
      healthMult: 3.0,
      sizeMult: 1.5,
      isPhantom: false,
      world: 2),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 3: SIGNAL WASTES - Corrupted data enemies
  // ═══════════════════════════════════════════════════════════════════════════
  corruptedByte(
      color: Color(0xFF33FF33),
      speedMult: 1.1,
      healthMult: 1.0,
      sizeMult: 0.9,
      isPhantom: false,
      world: 3),
  malware(
      color: Color(0xFFFF0000),
      speedMult: 0.9,
      healthMult: 1.5,
      sizeMult: 1.1,
      isPhantom: false,
      world: 3),
  dataWorm(
      color: Color(0xFF99FF00),
      speedMult: 1.5,
      healthMult: 0.6,
      sizeMult: 0.7,
      isPhantom: false,
      world: 3),
  virusCarrier(
      color: Color(0xFFCC0066),
      speedMult: 0.7,
      healthMult: 2.2,
      sizeMult: 1.3,
      isPhantom: false,
      world: 3),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 4: ION CROWN - Electric/plasma enemies
  // ═══════════════════════════════════════════════════════════════════════════
  sparkDrone(
      color: Color(0xFFFFFF00),
      speedMult: 1.3,
      healthMult: 0.8,
      sizeMult: 0.8,
      isPhantom: false,
      world: 4),
  plasmaCore(
      color: Color(0xFFFFAA00),
      speedMult: 0.7,
      healthMult: 2.0,
      sizeMult: 1.25,
      isPhantom: false,
      world: 4),
  ionSurge(
      color: Color(0xFF00CCFF),
      speedMult: 1.6,
      healthMult: 0.5,
      sizeMult: 0.65,
      isPhantom: false,
      world: 4),
  thunderHulk(
      color: Color(0xFFFF6600),
      speedMult: 0.4,
      healthMult: 3.5,
      sizeMult: 1.6,
      isPhantom: false,
      world: 4),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 5: SHARD VAULT - Crystal/mineral enemies
  // ═══════════════════════════════════════════════════════════════════════════
  crystalShard(
      color: Color(0xFF66FFFF),
      speedMult: 1.0,
      healthMult: 1.3,
      sizeMult: 0.95,
      isPhantom: false,
      world: 5),
  gemCarrier(
      color: Color(0xFFFF66FF),
      speedMult: 0.8,
      healthMult: 1.8,
      sizeMult: 1.15,
      isPhantom: false,
      world: 5),
  prismWalker(
      color: Color(0xFFFFFFFF),
      speedMult: 1.2,
      healthMult: 1.0,
      sizeMult: 0.9,
      isPhantom: true,
      world: 5),
  diamondGolem(
      color: Color(0xFF00FFCC),
      speedMult: 0.35,
      healthMult: 4.0,
      sizeMult: 1.7,
      isPhantom: false,
      world: 5),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 6: ARC FORTRESS - Mechanical/robotic enemies
  // ═══════════════════════════════════════════════════════════════════════════
  sentryBot(
      color: Color(0xFF888888),
      speedMult: 0.9,
      healthMult: 1.4,
      sizeMult: 1.0,
      isPhantom: false,
      world: 6),
  droneSwarm(
      color: Color(0xFFCCCCCC),
      speedMult: 1.5,
      healthMult: 0.5,
      sizeMult: 0.6,
      isPhantom: false,
      world: 6),
  siegeWalker(
      color: Color(0xFF555555),
      speedMult: 0.5,
      healthMult: 2.8,
      sizeMult: 1.45,
      isPhantom: false,
      world: 6),
  cloakedAssassin(
      color: Color(0xFF333333),
      speedMult: 1.4,
      healthMult: 1.0,
      sizeMult: 0.85,
      isPhantom: true,
      world: 6),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 7: OMEGA GRID - Digital/matrix enemies
  // ═══════════════════════════════════════════════════════════════════════════
  codeFragment(
      color: Color(0xFF00FF00),
      speedMult: 1.2,
      healthMult: 0.9,
      sizeMult: 0.8,
      isPhantom: false,
      world: 7),
  matrixAgent(
      color: Color(0xFF009900),
      speedMult: 1.0,
      healthMult: 1.5,
      sizeMult: 1.05,
      isPhantom: false,
      world: 7),
  firewallBreaker(
      color: Color(0xFF66FF66),
      speedMult: 0.6,
      healthMult: 2.5,
      sizeMult: 1.35,
      isPhantom: false,
      world: 7),
  systemGhost(
      color: Color(0xFF003300),
      speedMult: 1.3,
      healthMult: 1.1,
      sizeMult: 0.9,
      isPhantom: true,
      world: 7),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 8: STORM TOWER - Weather/elemental enemies
  // ═══════════════════════════════════════════════════════════════════════════
  stormRunner(
      color: Color(0xFF3399FF),
      speedMult: 1.4,
      healthMult: 0.85,
      sizeMult: 0.9,
      isPhantom: false,
      world: 8),
  cycloneSpirit(
      color: Color(0xFF99CCFF),
      speedMult: 1.1,
      healthMult: 1.2,
      sizeMult: 1.0,
      isPhantom: true,
      world: 8),
  thunderTitan(
      color: Color(0xFF0066CC),
      speedMult: 0.45,
      healthMult: 3.2,
      sizeMult: 1.55,
      isPhantom: false,
      world: 8),
  lightningWraith(
      color: Color(0xFFCCFFFF),
      speedMult: 1.7,
      healthMult: 0.6,
      sizeMult: 0.7,
      isPhantom: false,
      world: 8),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 9: FINAL GATE - Void/dark enemies
  // ═══════════════════════════════════════════════════════════════════════════
  voidStalker(
      color: Color(0xFF660066),
      speedMult: 1.2,
      healthMult: 1.3,
      sizeMult: 1.0,
      isPhantom: true,
      world: 9),
  abyssWalker(
      color: Color(0xFF330033),
      speedMult: 0.8,
      healthMult: 2.0,
      sizeMult: 1.2,
      isPhantom: false,
      world: 9),
  shadowSwarm(
      color: Color(0xFF990099),
      speedMult: 1.6,
      healthMult: 0.7,
      sizeMult: 0.65,
      isPhantom: false,
      world: 9),
  darknessTitan(
      color: Color(0xFF220022),
      speedMult: 0.4,
      healthMult: 3.8,
      sizeMult: 1.65,
      isPhantom: false,
      world: 9),

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD 10: OMEGA NEXUS - Ultimate hybrid enemies
  // ═══════════════════════════════════════════════════════════════════════════
  nexusHunter(
      color: Color(0xFFFF0099),
      speedMult: 1.3,
      healthMult: 1.5,
      sizeMult: 1.1,
      isPhantom: false,
      world: 10),
  omegaSentinel(
      color: Color(0xFF9900FF),
      speedMult: 0.7,
      healthMult: 2.5,
      sizeMult: 1.4,
      isPhantom: false,
      world: 10),
  realityShifter(
      color: Color(0xFFFFFF00),
      speedMult: 1.1,
      healthMult: 1.3,
      sizeMult: 1.0,
      isPhantom: true,
      world: 10),
  apocalypseHerald(
      color: Color(0xFFFF3300),
      speedMult: 0.3,
      healthMult: 5.0,
      sizeMult: 1.8,
      isPhantom: false,
      world: 10);

  const EnemyType({
    required this.color,
    required this.speedMult,
    required this.healthMult,
    required this.sizeMult,
    required this.isPhantom,
    this.world = 1,
  });

  final Color color;
  final double speedMult;
  final double healthMult;
  final double sizeMult;
  final bool isPhantom;
  final int world;

  // HYPER-OPTIMIZED: Cached world enemies (avoids list allocation per call)
  static final Map<int, List<EnemyType>> _worldEnemiesCache = {};

  static bool _isElectricEnemyType(EnemyType type) {
    switch (type) {
      case EnemyType.sparkDrone:
      case EnemyType.ionSurge:
      case EnemyType.plasmaCore:
      case EnemyType.thunderHulk:
      case EnemyType.lightningWraith:
      case EnemyType.stormRunner:
      case EnemyType.cycloneSpirit:
      case EnemyType.thunderTitan:
        return true;
      default:
        return false;
    }
  }

  /// Get all enemy types for a specific world (cached)
  static List<EnemyType> getWorldEnemies(int worldIndex) {
    return _worldEnemiesCache.putIfAbsent(
      worldIndex,
      () => EnemyType.values.where((e) => e.world == worldIndex).toList(),
    );
  }

  /// Get basic enemy types (for fallback/mixed waves)
  static List<EnemyType> get basicTypes =>
      [runner, overloaded, juggernaut, phantom];
}

class Enemy extends PositionComponent {
  static const String _appEnv =
      String.fromEnvironment('APP_ENV', defaultValue: 'prod');
  static const bool disablePhantomStealth =
      bool.fromEnvironment('DISABLE_PHANTOM_STEALTH', defaultValue: false) ||
          _appEnv == 'dev';
  static bool lowFx = false;
  static bool forceLowFx = false;
  static bool allowBlur = true;
  static bool throttleOffscreen = false;
  static Vector2 screenOffset = Vector2.zero();
  static Vector2 screenSize = Vector2.zero();
  static double screenScale = 1.0;
  static const double offscreenPadding = 60.0;
  static const double offscreenUpdateInterval = 0.12;

  // ═══════════════════════════════════════════════════════════════════════
  // CACHED PAINT OBJECTS - Avoid per-frame allocations (MEGA OPTIMIZED)
  // ═══════════════════════════════════════════════════════════════════════
  static final Paint _outerGlowPaint = Paint();
  static final Paint _bodyGlowPaint = Paint();
  static final Paint _highlightPaint = Paint();
  static final Paint _trailPaint = Paint();
  static final Paint _particlePaint = Paint();
  static final Paint _circuitPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _auraPaint = Paint();
  static final Paint _corePaint = Paint();
  static final Paint _shadowPaint = Paint();
  static final Paint _3dLightPaint = Paint();
  // Additional cached paints for walk/eye effects (prevents 55+ allocations per frame)
  static final Paint _legPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _tendrilPaint = Paint();
  static final Paint _wispPaint = Paint();
  static final Paint _glitchPaint = Paint();
  static final Paint _sparkPaint = Paint();
  static final Paint _crystalPaint = Paint();
  static final Paint _metalPaint = Paint();
  static final Paint _dataPaint = Paint();
  static final Paint _windPaint = Paint();
  static final Paint _voidPaint = Paint();
  static final Paint _omegaPaint = Paint();
  static final Paint _eyePaint = Paint();
  static final Paint _pupilPaint = Paint();
  static final Paint _veinPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _flamePaint = Paint();
  static final Paint _facetPaint = Paint();
  static final Paint _swirlPaint = Paint();
  static final Paint _healthBarPaint = Paint();
  static final Paint _healthBarBgPaint = Paint();
  static final Paint _extrusionPaint = Paint();
  // Additional per-frame Paint optimizations (44 more allocations eliminated)
  static final Paint _socketPaint = Paint();
  static final Paint _irisPaint = Paint();
  static final Paint _scanPaint = Paint();
  static final Paint _reticlePaint = Paint();
  static final Paint _barPaint = Paint();
  static final Paint _chromaPaint = Paint();
  static final Paint _slicePaint = Paint();
  static final Paint _shardPaint = Paint();
  static final Paint _fillPaint = Paint();
  static final Paint _strokePaint = Paint();
  static final Paint _arcPaint = Paint();
  static final Paint _slowPaint = Paint();
  static final Paint _slowAuraPaint = Paint();
  static final Paint _gearPaint = Paint();
  static final Paint _warnPaint = Paint();
  static final Paint _codePaint = Paint();
  static final Paint _bracePaint = Paint();
  static final Paint _spikePaint = Paint();
  static final Paint _bladePaint = Paint();
  static final Paint _stripePaint = Paint();
  static final Paint _tearPaint = Paint();
  static final Paint _corruptPaint = Paint();
  static final Paint _errorPaint = Paint();
  static final Paint _riftPaint = Paint();
  static final Paint _platePaint = Paint();
  static final Paint _shellPaint = Paint();
  static final Paint _hullPaint = Paint();
  static final Paint _outlinePaint = Paint();
  static final Paint _slashPaint = Paint();
  static final Paint _specularPaint = Paint();
  static final Paint _pulsePaint = Paint();
  static final Paint _bitPaint = Paint();
  static final Paint _layerPaint = Paint();
  static final Paint _bottomGlowPaint = Paint();
  static final Paint _impactPaint = Paint();
  static final Paint _footPaint = Paint();
  static final Paint _rayPaint = Paint();

  // Cached opacity filters to avoid per-frame ColorFilter allocations for shaders.
  static const int _opacityLevels = 128;
  static final List<ColorFilter> _opacityFilters = List<ColorFilter>.generate(
    _opacityLevels + 1,
    (i) => ColorFilter.mode(
      Color.fromARGB(((i * 255) / _opacityLevels).round(), 255, 255, 255),
      BlendMode.modulate,
    ),
  );

  static ColorFilter _opacityFilter(double opacity) {
    final idx = (opacity.clamp(0.0, 1.0) * _opacityLevels).round();
    return _opacityFilters[idx];
  }

  // Reusable gradient lists to avoid per-frame allocations in health bar rendering.
  static final List<Color> _healthGradientColors =
      List<Color>.filled(3, Colors.white, growable: false);
  static final List<double> _healthGradientStops = <double>[0.0, 0.5, 1.0];

  // ═══════════════════════════════════════════════════════════════════════
  // SPAWN/MATERIALIZE EFFECT PAINTS (Enemy teleporting into existence)
  // ═══════════════════════════════════════════════════════════════════════
  static final Paint _spawnNoisePaint = Paint();
  static final Paint _spawnParticlePaint = Paint();
  static final Paint _spawnHoloPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _spawnScanlinePaint = Paint();
  static final Paint _spawnBurstPaint = Paint();
  static final Paint _spawnPortalPaint = Paint();
  static final Paint _spawnPortalGlowPaint = Paint()
    ..style = PaintingStyle.stroke;
  static final Paint _spawnGlitchPaint = Paint();
  static final Path _spawnPath = Path();
  static final _FastRng _spawnRandom = _FastRng();

  // ═══════════════════════════════════════════════════════════════════════
  // ENERGY VEIN EFFECT PAINTS (Pulsing veins of light in enemy bodies)
  // ═══════════════════════════════════════════════════════════════════════
  static final Paint _energyVeinGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _energyVeinCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _energyVeinNodePaint = Paint();
  static final Paint _energyVeinDotPaint = Paint();
  static final Paint _energyVeinMicroPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _energyVeinHeartbeatPaint = Paint();
  static final Path _energyVeinPath = Path();

  // ═══════════════════════════════════════════════════════════════════════
  // WARP/TELEPORT EFFECT PAINTS (Fast enemies phasing through dimensions)
  // ═══════════════════════════════════════════════════════════════════════
  static final Paint _warpAfterimgPaint = Paint();
  static final Paint _warpStreakPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _warpDistortPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _warpParticlePaint = Paint();
  static final Paint _warpLightningPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _warpChromaPaint = Paint();
  static final Paint _warpFlickerPaint = Paint();
  static final Path _warpPath = Path();
  static final _FastRng _warpRandom = _FastRng();
  static double _warpFlickerPhase = 0;

  // ═══════════════════════════════════════════════════════════════════════
  // HOLOGRAPHIC SHIELD EFFECT PAINTS
  // ═══════════════════════════════════════════════════════════════════════
  static final Paint _shieldHexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _shieldGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _shieldRipplePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _shieldDataPaint = Paint();
  static final Paint _shieldInterferencePaint = Paint();
  static final Paint _shieldFragmentPaint = Paint();
  static final Paint _shieldCorePaint = Paint();

  // ═══════════════════════════════════════════════════════════════════════
  // HOLOGRAPHIC HEALTH BAR EFFECT PAINTS
  // ═══════════════════════════════════════════════════════════════════════
  static final Paint _holoBarFramePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  static final Paint _holoBarGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _holoBarScanlinePaint = Paint();
  static final Paint _holoBarDataPaint = Paint();
  static final Paint _holoBarHexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Paint _holoBarEnergyPaint = Paint()..strokeCap = StrokeCap.round;
  static final Paint _holoBarGlitchPaint = Paint();
  static final Paint _holoBarCornerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Path _holoBarPath = Path();
  static final _FastRng _holoBarRandom = _FastRng();

  // ═══════════════════════════════════════════════════════════════════════
  // LIGHTNING CHAIN EFFECT PAINTS (Between nearby enemies)
  // ═══════════════════════════════════════════════════════════════════════
  static final Paint _lightningCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _lightningGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _lightningInnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  static final Paint _lightningSparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _lightningNodePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Path _lightningPath = Path();
  static final _FastRng _lightningRandom = _FastRng();
  static final List<Enemy> _lightningCandidates = <Enemy>[];
  static const double _lightningChainMinDistance = 30.0;
  static const double _lightningChainMaxDistance = 120.0;

  // ═══════════════════════════════════════════════════════════════════════
  // HOLOGRAPHIC STATUS ICON PAINTS (Above entity indicators)
  // ═══════════════════════════════════════════════════════════════════════
  static final Paint _statusIconBasePaint = Paint()..style = PaintingStyle.fill;
  static final Paint _statusIconGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _statusIconStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final Paint _statusIconTimerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _statusIconScanlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Path _statusIconPath = Path();

  // Status icon colors
  static const Color _slowIconColor = Color(0xFF00CCFF); // Blue
  static const Color _burnIconColor = Color(0xFFFF6600); // Orange-red
  static const Color _shieldIconColor = Color(0xFF00FFCC); // Cyan
  static const Color _boostIconColor = Color(0xFF00FF66); // Green
  static const Color _stunIconColor = Color(0xFFFFFF00); // Yellow

  // ═══════════════════════════════════════════════════════════════════════
  // NEON TRAIL EFFECT PAINTS (Smooth movement path visualization)
  // ═══════════════════════════════════════════════════════════════════════
  static final Paint _neonTrailOuterGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final Paint _neonTrailCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final Paint _neonTrailGradientPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _neonTrailParticlePaint = Paint();
  static final Paint _neonTrailNodePaint = Paint();
  static final Paint _neonTrailScanlinePaint = Paint()
    ..style = PaintingStyle.stroke;
  static final Path _neonTrailPath = Path();
  static final _FastRng _neonTrailRandom = _FastRng(42);

  // ═══════════════════════════════════════════════════════════════════════
  // REUSABLE OFFSETS - Avoid per-loop Offset allocations (50+ per frame)
  // ═══════════════════════════════════════════════════════════════════════
  static Offset _tempOffset1 = Offset.zero;
  static Offset _tempOffset2 = Offset.zero;
  static Offset _tempOffset3 = Offset.zero;
  static Offset _tempOffset4 = Offset.zero;

  // ═══════════════════════════════════════════════════════════════════════
  // CACHED LISTS - Avoid per-frame list allocations
  // ═══════════════════════════════════════════════════════════════════════
  // Hive eye positions as fractions of radius (multiply by radius when using)
  static final List<Offset> _hiveEyePositions = [
    const Offset(0.25, -0.15),
    const Offset(0.1, -0.25),
    const Offset(-0.05, -0.2),
    const Offset(0.3, 0),
    const Offset(0.15, 0.1),
    const Offset(-0.1, 0.05),
  ];

  static final List<Color> _flameColors = [
    const Color(0xFFFF3300),
    const Color(0xFFFF6600),
    const Color(0xFFFFAA00),
    const Color(0xFFFFFF00),
    Colors.white,
  ];

  // Reusable paths to avoid per-frame allocations
  static final Path _reusableBodyPath = Path();
  static final Path _reusableCrownPath = Path();
  static final Path _reusableLayerPath = Path();
  static final Path _reusableOverlayPath = Path();
  static final Path _reusableHexPath = Path();
  static final Path _reusableShieldPath = Path();
  // Reusable Vector2 for temporary spawn position calculations
  static final Vector2 _tempSpawnPos = Vector2.zero();

  // Particle list limits
  static const int _maxDataBits = 20;
  static const int _maxPlasmaParticles = 15;

  Enemy({
    required this.path,
    double speed = 80,
    double maxHealth = 100,
    this.goldReward = 10,
    this.type = EnemyType.runner,
    this.spawnIndex = 0,
    this.threatTier = 0,
    this.worldIndex = 1,
    Vector2? startPosition,
    this.onDeath,
    this.onReachBase,
    this.onMoved,
  })  : _baseSpeed = speed,
        _baseMaxHealth = maxHealth,
        _currentTargetIndex = 0,
        _random = _FastRng() {
    _animationPhase = _random.nextDouble() * math.pi * 2;
    _circuitSeed = _random.nextDouble();
    _visualRandom = _FastRng(
      (spawnIndex + 1) * 1000003 ^ (_circuitSeed * 1000000).toInt(),
    );
    _initializeCircuitry();
    _initializePhantomNoise();

    _isElectricType = EnemyType._isElectricEnemyType(type);
    _chainColor = _isElectricType
        ? type.color
        : Color.lerp(type.color, const Color(0xFF00FFFF), 0.5)!;
    final chainHsl = HSLColor.fromColor(_chainColor);
    _chainSecondaryColor =
        chainHsl.withHue((chainHsl.hue + 30) % 360).toColor();

    // Apply type multipliers
    _maxHealth = _baseMaxHealth * type.healthMult * _tierHealthMult;
    _health = _maxHealth;
    _speed = _baseSpeed * type.speedMult * _tierSpeedMult;

    size = Vector2.all(24 * type.sizeMult * _tierSizeMult);
    anchor = Anchor.center;
    if (startPosition != null) {
      position.setFrom(startPosition);
    } else if (path.isNotEmpty) {
      position.setFrom(path.first);
    } else {
      position.setZero();
    }
    _lastPosition.setFrom(position);

    // Initialize trail (circular buffer)
    _trailPositions = List.generate(_maxTrailLength, (_) => position.clone());
    _trailHead = 0;

    // Cache body shape and walk style (never changes, avoids per-frame calls)
    _cachedBodyShape = _getBodyShape();
    _cachedWalkStyle = _getWalkingStyle();
    _buildShaderCache();
  }

  void _buildShaderCache() {
    _baseRadius = size.x / 2;
    _coreRadius = _baseRadius * 0.6;
    _specularRadius = _baseRadius * 0.25;
    _specularOffset = Offset(-_baseRadius * 0.3, -_baseRadius * 0.35);

    _highlightShader = SweepGradient(
      center: Alignment.center,
      startAngle: -math.pi * 0.75,
      endAngle: math.pi * 0.25,
      colors: [
        Colors.white.withOpacity(0.0),
        Colors.white.withOpacity(0.45),
        Colors.white.withOpacity(0.6),
        Colors.white.withOpacity(0.35),
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 0.2, 0.35, 0.5, 1.0],
    ).createShader(
      Rect.fromCircle(center: Offset.zero, radius: _baseRadius),
    );

    _specularShader = RadialGradient(
      colors: [
        Colors.white.withOpacity(0.55),
        Colors.white.withOpacity(0.2),
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 0.4, 1.0],
    ).createShader(
      Rect.fromCircle(center: _specularOffset, radius: _specularRadius),
    );

    _coreShader = LinearGradient(
      colors: [
        Colors.black.withOpacity(0.85),
        type.color,
        Colors.white.withOpacity(0.35),
      ],
      stops: const [0.0, 0.65, 1.0],
      begin: const Alignment(-0.6, -0.6),
      end: const Alignment(0.8, 0.8),
    ).createShader(
      Rect.fromCircle(center: Offset.zero, radius: _coreRadius),
    );

    _voidEyeRadius = _baseRadius * 0.15;
    _voidEyePos1 = Offset(_baseRadius * 0.2, -_baseRadius * 0.15);
    _voidEyePos2 = Offset(-_baseRadius * 0.15, -_baseRadius * 0.1);
    final voidGradient = RadialGradient(
      colors: [
        Colors.black.withOpacity(0.95),
        Colors.black.withOpacity(0.7),
        type.color.withOpacity(0.2),
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    _voidEyeShader1 = voidGradient.createShader(
      Rect.fromCircle(center: _voidEyePos1, radius: _voidEyeRadius),
    );
    _voidEyeShader2 = voidGradient.createShader(
      Rect.fromCircle(center: _voidEyePos2, radius: _voidEyeRadius),
    );

    _crystalEyePos = Offset(_baseRadius * 0.12, -_baseRadius * 0.1);
    _crystalEyeRect = Rect.fromCenter(
      center: _crystalEyePos,
      width: _baseRadius * 0.4,
      height: _baseRadius * 0.4,
    );
    _crystalEyeShader = LinearGradient(
      colors: [
        Colors.white.withOpacity(0.9),
        type.color.withOpacity(0.7),
        type.color.withOpacity(0.3),
      ],
    ).createShader(_crystalEyeRect);
  }

  final List<Vector2> path;
  final double _baseSpeed;
  final double _baseMaxHealth;
  final _FastRng _random;
  late final _FastRng _visualRandom;
  final int goldReward;
  final EnemyType type;
  final int spawnIndex;
  final int threatTier;
  final int worldIndex;
  final void Function(Enemy enemy)? onMoved;

  late final bool _isElectricType;
  late final Color _chainColor;
  late final Color _chainSecondaryColor;
  BoredGamesGame? _cachedGame;

  // Index bookkeeping for O(1) removals and spatial buckets.
  int activeIndex = -1;
  int spatialKey = -1;
  int spatialIndex = -1;

  int _currentTargetIndex;
  late double _health;
  late double _maxHealth;
  late double _speed;
  late double _animationPhase;

  // Slow effect
  double _slowFactor = 1.0;
  double _slowDuration = 0;

  // Burn effect (damage over time)
  double _burnDamage = 0;
  double _burnDuration = 0;
  double _burnTickTimer = 0;
  static const double _burnTickInterval = 0.5;

  // Shield effect (damage reduction)
  double _shieldAmount = 0;
  double _shieldDuration = 0;
  double _shieldMaxAmount = 0;

  // Boost effect (speed increase)
  double _boostFactor = 1.0;
  double _boostDuration = 0;

  // Stun effect (complete stop)
  double _stunDuration = 0;

  // Visual trail - circular buffer for O(1) updates instead of O(n) list shifts
  static const int _maxTrailLength = 15;
  late List<Vector2> _trailPositions;
  double _trailUpdateTimer = 0;
  static const double _trailUpdateInterval = 0.03;
  int _trailHead = 0; // Current write position in circular buffer

  /// Get physical index from logical index (0 = newest, _maxTrailLength-1 = oldest)
  int _getTrailPhysicalIndex(int logicalIndex) {
    return (_trailHead - logicalIndex + _maxTrailLength) % _maxTrailLength;
  }

  // Hit flash effect
  double _hitFlashTimer = 0;
  static const double _hitFlashDuration = 0.06;

  // Pulse animation
  double _pulseScale = 1.0;

  // Walking animation
  double _walkPhase = 0;
  double _wobbleOffset = 0;
  double _verticalBob = 0;
  Vector2 _lastPosition = Vector2.zero();
  double _speedIndicator = 0;
  double _offscreenAccumulator = 0;

  // New visual state for overhaul
  double _animationTimer = 0;
  final List<_DataBit> _dataBits = [];
  final List<_PlasmaParticle> _plasmaParticles = [];
  late final double _circuitSeed;
  final List<_CircuitSegment> _circuitSegments = [];
  final List<_NoiseBit> _phantomNoise = [];
  double _orbitalRotation = 0;
  double _lastHealth = 0;

  // Cached body shape - never changes per enemy (avoids _getBodyShape() call every frame)
  late final _BodyShape _cachedBodyShape;
  // Cached walk style - never changes per enemy (avoids _getWalkingStyle() call every frame)
  late final _WalkStyle _cachedWalkStyle;
  // Cached shader geometry (per-enemy, avoids per-frame createShader).
  late final double _baseRadius;
  late final double _coreRadius;
  late final Offset _specularOffset;
  late final double _specularRadius;
  late final Shader _highlightShader;
  late final Shader _specularShader;
  late final Shader _coreShader;
  late final Offset _voidEyePos1;
  late final Offset _voidEyePos2;
  late final double _voidEyeRadius;
  late final Shader _voidEyeShader1;
  late final Shader _voidEyeShader2;
  late final Offset _crystalEyePos;
  late final Rect _crystalEyeRect;
  late final Shader _crystalEyeShader;

  // Damage particles
  final List<_DamageParticle> _damageParticles = [];
  static const int _maxDamageParticles = 12;

  // Spawn/materialize effect state
  bool _isSpawning = true;
  double _spawnProgress = 0.0;
  static const double _spawnDuration = 1.0;
  final List<_SpawnParticle> _spawnParticles = [];
  static const int _maxSpawnParticles = 24;

  /// Callbacks for events
  EnemyDeathCallback? onDeath;
  EnemyReachBaseCallback? onReachBase;

  /// Current health (read-only)
  double get health => _health;

  /// Max health
  double get maxHealth => _maxHealth;

  /// Current speed (after modifiers: slow, boost, stun)
  double get speed =>
      _stunDuration > 0 ? 0 : _speed * _slowFactor * _boostFactor;

  /// Health percentage (0.0 to 1.0)
  double get healthPercent => _health / _maxHealth;

  /// Whether enemy is still alive
  bool get isAlive => _health > 0;

  /// Whether enemy has reached the end of path
  bool get hasReachedBase => _currentTargetIndex >= path.length;

  /// Whether enemy is currently slowed
  bool get isSlowed => _slowFactor < 1.0;

  /// Whether enemy is currently burning
  bool get isBurning => _burnDuration > 0;

  /// Whether enemy has a shield
  bool get hasShield => _shieldAmount > 0;

  /// Whether enemy is currently boosted
  bool get isBoosted => _boostFactor > 1.0;

  /// Whether enemy is currently stunned
  bool get isStunned => _stunDuration > 0;

  /// Whether enemy is currently spawning/materializing
  bool get isSpawning => _isSpawning;

  /// Spawn progress (0.0 to 1.0)
  double get spawnProgress => _spawnProgress;

  /// Whether enemy has any active status effects
  bool get hasActiveStatusEffects =>
      isSlowed || isBurning || hasShield || isBoosted || isStunned;

  /// The index of the current waypoint the enemy is moving towards.
  int get currentPathIndex => _currentTargetIndex;

  /// Progress along the path (0.0 start, 1.0 end)
  double get pathProgress {
    if (path.isEmpty) return 0.0;
    return (_currentTargetIndex / path.length).clamp(0.0, 1.0);
  }

  /// Whether this enemy is a phantom type
  bool get isPhantom => type.isPhantom;

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHED HSL-DERIVED WARP COLORS - Avoid per-frame HSLColor.fromColor()
  // ═══════════════════════════════════════════════════════════════════════════
  late final Color _warpSecondaryColor = () {
    final hsl = HSLColor.fromColor(type.color);
    return hsl.withHue((hsl.hue + 180) % 360).toColor();
  }();
  late final Color _warpTertiaryColor = () {
    final hsl = HSLColor.fromColor(type.color);
    return hsl
        .withHue((hsl.hue + 90) % 360)
        .withSaturation((hsl.saturation * 1.2).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * 1.1).clamp(0.0, 1.0))
        .toColor();
  }();
  late final Color _worldAccentColor = () {
    switch (type.world) {
      case 1:
        return Color.lerp(type.color, _warpTertiaryColor, 0.45)!;
      case 2:
        return Color.lerp(type.color, _warpSecondaryColor, 0.65)!;
      case 3:
        return Color.lerp(type.color, const Color(0xFF00FF66), 0.55)!;
      case 4:
        return Color.lerp(type.color, const Color(0xFF66CCFF), 0.55)!;
      case 5:
        return Color.lerp(type.color, const Color(0xFFE8FFFF), 0.6)!;
      case 6:
        return Color.lerp(type.color, const Color(0xFFBFC6D1), 0.55)!;
      case 7:
        return Color.lerp(type.color, const Color(0xFF33FF66), 0.6)!;
      case 8:
        return Color.lerp(type.color, const Color(0xFF99D9FF), 0.6)!;
      case 9:
        return Color.lerp(type.color, const Color(0xFFB266FF), 0.5)!;
      case 10:
        return Color.lerp(type.color, _warpTertiaryColor, 0.7)!;
      default:
        return _warpTertiaryColor;
    }
  }();
  late final Color _worldEdgeColor = () {
    return Color.lerp(
      _worldAccentColor,
      Colors.white,
      type.isPhantom ? 0.35 : 0.22,
    )!;
  }();
  late final Color _worldGlowColor = () {
    return Color.lerp(_worldAccentColor, type.color, 0.5)!;
  }();

  Color get worldAccentColor => _worldAccentColor;
  Color get worldEdgeColor => _worldEdgeColor;
  Color get worldGlowColor => _worldGlowColor;

  /// Whether this enemy is a fast/warp type (speedMult >= 1.3)
  /// These enemies get special dimensional phasing visual effects
  bool get isFastWarpType =>
      type == EnemyType.overloaded || // 1.4 - World 1
      type == EnemyType.voidling || // 1.3 - World 2
      type == EnemyType.dataWorm || // 1.5 - World 3
      type == EnemyType.sparkDrone || // 1.3 - World 4
      type == EnemyType.ionSurge || // 1.6 - World 4
      type == EnemyType.droneSwarm || // 1.5 - World 6
      type == EnemyType.cloakedAssassin || // 1.4 - World 6
      type == EnemyType.stormRunner || // 1.4 - World 8
      type == EnemyType.lightningWraith || // 1.7 - World 8
      type == EnemyType.shadowSwarm || // 1.6 - World 9
      type == EnemyType.nexusHunter; // 1.3 - World 10

  /// Whether this enemy is a boss (overridden in Boss class)
  bool get isBoss => false;

  /// Display name for UI (overridden in Boss class)
  String get displayName => type.name.toUpperCase();

  /// Current movement direction (normalized vector towards next waypoint)
  Vector2 get movementDirection {
    if (path.isEmpty || _currentTargetIndex >= path.length) {
      return Vector2(1, 0); // Default direction
    }
    final target = path[_currentTargetIndex];
    final direction = target - position;
    if (direction.length < 0.01) return Vector2(1, 0);
    return direction.normalized();
  }

  double get _tierHealthMult => 1 + (threatTier * 0.2);

  double get _tierSpeedMult => 1 + (threatTier * 0.04);

  double get _tierSizeMult => 1 + (threatTier * 0.08);

  Color get _threatColor {
    if (threatTier <= 0) return type.color;
    final mix = (0.2 + threatTier * 0.12).clamp(0.2, 0.6);
    return Color.lerp(type.color, const Color(0xFFFF3344), mix)!;
  }

  /// Whether the phantom has been revealed (damaged or detected)
  bool _isRevealed = false;
  double _revealTimer = 0;
  static const double _revealDuration =
      3.0; // Stays visible for 3 seconds after detection

  /// Whether the phantom is currently visible
  bool get isVisible => !isPhantom || _isRevealed || disablePhantomStealth;

  /// Reveal the phantom temporarily
  void reveal() {
    if (isPhantom && !_isRevealed) {
      _isRevealed = true;
      _revealTimer = _revealDuration;
      AudioService.instance.playPhantomReveal();
    } else if (isPhantom) {
      // Already revealed, just refresh timer
      _revealTimer = _revealDuration;
    }
  }

  /// Apply damage to the enemy
  /// [amount] - The damage amount to apply
  /// [isCritical] - Whether this was a critical hit (for visual effect)
  void takeDamage(double amount, {bool isCritical = false}) {
    if (!isAlive) return;

    // Reveal phantom when damaged
    if (isPhantom) {
      reveal();
    }

    _health -= amount;
    _hitFlashTimer = _hitFlashDuration;
    _pulseScale = 1.15; // Brief scale up on hit

    // Spawn damage particles
    _spawnDamageParticles();

    // Spawn holographic damage number
    _spawnDamageNumber(amount, isCritical: isCritical);

    if (_health <= 0) {
      _health = 0;
      onDeath?.call(this);
      removeFromParent();
    }
  }

  /// Spawn a holographic damage number at the enemy position
  void _spawnDamageNumber(double amount, {bool isCritical = false}) {
    // Skip if effects are disabled or parent is null
    if (Enemy.lowFx || Enemy.forceLowFx || parent == null) return;

    // Determine damage type
    final type =
        isCritical ? DamageNumberType.critical : DamageNumberType.damage;

    // Spawn slightly above the enemy center - use reusable vector
    _tempSpawnPos.setFrom(position);
    _tempSpawnPos.y -= size.y * 0.3;

    final effect = DamageNumberEffect.spawn(
      position: _tempSpawnPos,
      damageAmount: amount.round(),
      type: type,
    );

    if (effect != null) {
      parent!.add(effect);
    }
  }

  /// Apply healing to the enemy (spawns green healing number)
  void applyHeal(double amount) {
    if (!isAlive) return;

    final healAmount = amount.clamp(0, _maxHealth - _health);
    if (healAmount <= 0) return;

    _health += healAmount;

    // Spawn healing number effect - use reusable vector
    if (!Enemy.lowFx && !Enemy.forceLowFx && parent != null) {
      _tempSpawnPos.setFrom(position);
      _tempSpawnPos.y -= size.y * 0.3;
      final effect = DamageNumberEffect.spawn(
        position: _tempSpawnPos,
        damageAmount: healAmount.round(),
        type: DamageNumberType.heal,
      );
      if (effect != null) {
        parent!.add(effect);
      }
    }
  }

  void _spawnDamageParticles() {
    if (Enemy.lowFx || Enemy.forceLowFx) return;
    final random = _random;

    // Standard sparks
    final particleCount = 2 + random.nextInt(3);
    for (int i = 0;
        i < particleCount && _damageParticles.length < _maxDamageParticles;
        i++) {
      _damageParticles.add(_DamageParticle.obtain(
        angle: random.nextDouble() * math.pi * 2,
        speed: 30 + random.nextDouble() * 50,
        size: 2 + random.nextDouble() * 3,
        lifetime: 0.3 + random.nextDouble() * 0.2,
      ));
    }

    // New Data Bits - with cap to prevent memory leak
    final bitCount = 3 + random.nextInt(4);
    for (int i = 0; i < bitCount && _dataBits.length < _maxDataBits; i++) {
      _dataBits.add(_DataBit.obtain(
        position: Vector2.zero(),
        velocity: Vector2(
          (random.nextDouble() - 0.5) * 80,
          (random.nextDouble() - 0.5) * 80,
        ),
        color: type.color,
        size: 2 + random.nextDouble() * 2,
        rotation: random.nextDouble() * math.pi * 2,
        lifetime: 0.6 + random.nextDouble() * 0.4,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final offscreen = _isOffscreen();
    if (offscreen && Enemy.throttleOffscreen) {
      _offscreenAccumulator += dt;
      if (_offscreenAccumulator < offscreenUpdateInterval) return;
      dt = _offscreenAccumulator;
      _offscreenAccumulator = 0;
    } else if (_offscreenAccumulator != 0) {
      _offscreenAccumulator = 0;
    }
    final prevX = position.x;
    final prevY = position.y;
    if (offscreen) {
      _animationTimer += dt;
      _animationPhase += dt * 2;
      _walkPhase += dt * speed / 15.0;
      _updateSpawnEffect(dt);
      _updateStatusTimers(dt);
      if (_damageParticles.isNotEmpty) _recycleDamageParticles();
      if (_dataBits.isNotEmpty) _recycleDataBits();
      if (_plasmaParticles.isNotEmpty) _recyclePlasmaParticles();
      _move(dt);
      _postMoveUpdate(prevX, prevY, dt);
      return;
    }

    _animationTimer += dt;
    _animationPhase += dt * 2;
    _walkPhase += dt * speed / 15.0;

    // Update spawn effect
    _updateSpawnEffect(dt);

    // Update particles
    _updateParticles(dt);
    _updateStatusTimers(dt);

    _orbitalRotation += dt * 2;
    _updatePlasmaParticles(dt);
    _lastHealth = _health;

    _move(dt);
    _postMoveUpdate(prevX, prevY, dt);
  }

  /// Apply slow effect to the enemy
  void applySlow(double factor, double duration) {
    // factor is 0.0 to 1.0 (e.g., 0.5 = 50% slow)
    // _slowFactor is speed multiplier (e.g., 0.5 = 50% speed)
    final newFactor = (1.0 - factor).clamp(0.1, 1.0);
    if (newFactor < _slowFactor) {
      _slowFactor = newFactor;
    }
    if (duration > _slowDuration) {
      _slowDuration = duration;
    }
  }

  void _updatePlasmaParticles(double dt) {
    if (Enemy.lowFx || Enemy.forceLowFx) {
      if (_plasmaParticles.isNotEmpty) {
        _recyclePlasmaParticles();
      }
      return;
    }

    // Spawn plasma smoke if health is low - with cap to prevent memory leak
    if (healthPercent < 0.4 &&
        _plasmaParticles.length < _maxPlasmaParticles &&
        _random.nextDouble() < 0.15) {
      _plasmaParticles.add(_PlasmaParticle.obtain(
        position: Vector2.zero(),
        velocity: Vector2(
            (_random.nextDouble() - 0.5) * 30, -30 - _random.nextDouble() * 30),
        color: type.color,
      ));
    }

    var i = 0;
    while (i < _plasmaParticles.length) {
      final particle = _plasmaParticles[i];
      particle.update(dt);
      if (particle.isActive) {
        i++;
        continue;
      }
      particle.recycle();
      final lastIndex = _plasmaParticles.length - 1;
      if (i < lastIndex) {
        _plasmaParticles[i] = _plasmaParticles[lastIndex];
      }
      _plasmaParticles.removeLast();
    }
  }

  void _updateParticles(double dt) {
    var i = 0;
    while (i < _damageParticles.length) {
      final particle = _damageParticles[i];
      particle.update(dt);
      if (particle.isActive) {
        i++;
        continue;
      }
      particle.recycle();
      final lastIndex = _damageParticles.length - 1;
      if (i < lastIndex) {
        _damageParticles[i] = _damageParticles[lastIndex];
      }
      _damageParticles.removeLast();
    }

    i = 0;
    while (i < _dataBits.length) {
      final bit = _dataBits[i];
      bit.update(dt);
      if (bit.isActive) {
        i++;
        continue;
      }
      bit.recycle();
      final lastIndex = _dataBits.length - 1;
      if (i < lastIndex) {
        _dataBits[i] = _dataBits[lastIndex];
      }
      _dataBits.removeLast();
    }
  }

  void _recycleDamageParticles() {
    for (final particle in _damageParticles) {
      particle.recycle();
    }
    _damageParticles.clear();
  }

  void _recycleDataBits() {
    for (final bit in _dataBits) {
      bit.recycle();
    }
    _dataBits.clear();
  }

  void _recyclePlasmaParticles() {
    for (final particle in _plasmaParticles) {
      particle.recycle();
    }
    _plasmaParticles.clear();
  }

  void _updateStatusTimers(double dt) {
    if (_hitFlashTimer > 0) {
      _hitFlashTimer -= dt;
    }

    if (_pulseScale > 1.0) {
      _pulseScale -= dt * 2;
      if (_pulseScale < 1.0) _pulseScale = 1.0;
    }

    if (isPhantom && _isRevealed) {
      _revealTimer -= dt;
      if (_revealTimer <= 0) {
        _isRevealed = false;
        _revealTimer = 0;
      }
    }

    // Slow effect decay
    if (_slowDuration > 0) {
      _slowDuration -= dt;
      if (_slowDuration <= 0) {
        _slowDuration = 0;
        _slowFactor = 1.0;
      }
    }
  }

  void _initializeCircuitry() {
    _circuitSegments.clear();
    final rand = _FastRng((_circuitSeed * 1000).toInt());
    for (int i = 0; i < 4; i++) {
      _circuitSegments.add(_CircuitSegment(
        Offset(
            (rand.nextDouble() - 0.5) * 1.4, (rand.nextDouble() - 0.5) * 1.4),
        Offset(
            (rand.nextDouble() - 0.5) * 1.4, (rand.nextDouble() - 0.5) * 1.4),
      ));
    }
  }

  void _initializePhantomNoise() {
    _phantomNoise.clear();
    if (type != EnemyType.phantom) return;

    final rand = _FastRng(spawnIndex);
    for (int i = 0; i < 6; i++) {
      if (rand.nextDouble() < 0.6) {
        _phantomNoise.add(_NoiseBit(
          offset: Offset(
            (rand.nextDouble() - 0.5) * 2.5,
            (rand.nextDouble() - 0.5) * 2.5,
          ),
          phase: rand.nextDouble() * math.pi * 2,
          size: 1.6 + rand.nextDouble() * 1.2,
        ));
      }
    }
  }

  void _postMoveUpdate(double prevX, double prevY, double dt) {
    final dx = position.x - prevX;
    final dy = position.y - prevY;
    if (dt > 0) {
      final distance = math.sqrt(dx * dx + dy * dy);
      _speedIndicator = (distance / (speed * dt + 0.0001)).clamp(0.0, 1.0);
    } else {
      _speedIndicator = 0;
    }
    _lastPosition.setFrom(position);
    if (dx != 0 || dy != 0) {
      onMoved?.call(this);
    }

    _trailUpdateTimer += dt;
    if (_trailUpdateTimer >= _trailUpdateInterval &&
        _trailPositions.isNotEmpty) {
      _trailUpdateTimer = 0;
      // CIRCULAR BUFFER: O(1) update instead of O(n) removeLast + insert
      _trailHead = (_trailHead + 1) % _maxTrailLength;
      _trailPositions[_trailHead].setFrom(position);
    }
  }

  bool _isOffscreen() {
    if (screenSize.isZero()) return false;
    if (screenScale <= 0) return false;
    final screenX = screenOffset.x + position.x * screenScale;
    final screenY = screenOffset.y + position.y * screenScale;
    final padding = offscreenPadding + size.x;
    return screenX < -padding ||
        screenX > screenSize.x + padding ||
        screenY < -padding ||
        screenY > screenSize.y + padding;
  }

  void _renderLowFx(Canvas canvas, double opacity) {
    final radius = size.x / 2;

    // Spawn effect (simple ring) for low-fx mode
    if (_isSpawning) {
      final spawnRingRadius = radius * (1.5 + (1.0 - _spawnProgress) * 1.0);
      _spawnPortalPaint
        ..color = type.color.withOpacity(0.4 * (1.0 - _spawnProgress) * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = null;
      canvas.drawCircle(Offset.zero, spawnRingRadius, _spawnPortalPaint);
    }

    // 3D Shadow (simple ellipse below enemy)
    final shadowOffsetY = radius * 0.6;
    _shadowPaint
      ..color = Colors.black.withOpacity(0.4 * opacity)
      ..maskFilter = null;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(radius * 0.1, shadowOffsetY),
        width: radius * 1.3,
        height: radius * 0.4,
      ),
      _shadowPaint,
    );

    // 3D Extrusion (dark layer below)
    final darkColor = Color.lerp(type.color, Colors.black, 0.6)!;
    _bodyGlowPaint
      ..color = darkColor.withOpacity(0.5 * opacity)
      ..maskFilter = null;
    canvas.drawCircle(
        Offset(radius * 0.05, radius * 0.15), radius * 0.95, _bodyGlowPaint);

    // Main body
    _bodyGlowPaint
      ..color = type.color.withOpacity(0.55 * opacity)
      ..maskFilter = null;
    canvas.drawCircle(Offset.zero, radius, _bodyGlowPaint);

    // 3D Highlight (top-left bright spot)
    _corePaint
      ..color = Colors.white.withOpacity(0.35 * opacity)
      ..maskFilter = null;
    canvas.drawCircle(
        Offset(-radius * 0.3, -radius * 0.3), radius * 0.25, _corePaint);

    if (threatTier > 0) {
      _circuitPaint
        ..color = _threatColor.withOpacity(0.5 * opacity)
        ..strokeWidth = 1.2
        ..maskFilter = null;
      canvas.drawCircle(
          Offset.zero, radius * (1.05 + threatTier * 0.06), _circuitPaint);
    }

    // Core highlight
    _corePaint
      ..color = Colors.white.withOpacity(0.5 * opacity)
      ..maskFilter = null;
    canvas.drawCircle(Offset.zero, radius * 0.3, _corePaint);

    if (opacity > 0.2) {
      _renderHealthBar(canvas, visibility: opacity);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final reduceFx = Enemy.lowFx || Enemy.forceLowFx;
    final allowBlur = Enemy.allowBlur;
    if (_isOffscreen()) return;

    // Calculate opacity for phantom (invisible when not revealed)
    double phantomOpacity = 1.0;
    if (isPhantom && !disablePhantomStealth) {
      if (!_isRevealed) {
        // Barely visible shimmer effect when invisible
        phantomOpacity = 0.08 + math.sin(_animationPhase * 4) * 0.04;
      } else {
        // Fade out as reveal timer expires
        phantomOpacity = (_revealTimer / _revealDuration).clamp(0.4, 1.0);
      }
    } else if (isPhantom && disablePhantomStealth) {
      // Keep phantoms visible in dev/testing builds.
      phantomOpacity = 0.6 + math.sin(_animationPhase * 3) * 0.08;
    }

    // Apply spawn transparency (enemy fades in during spawn)
    double spawnOpacity = 1.0;
    if (_isSpawning) {
      // Enemy is partially transparent until fully spawned
      // Starts at 0.15 and increases to 1.0 as spawn progresses
      spawnOpacity = 0.15 + _spawnProgress * 0.85;
    }
    phantomOpacity *= spawnOpacity;

    if (reduceFx) {
      _renderLowFx(canvas, phantomOpacity);
      return;
    }

    // Reactive distortion at low health
    final hpFactor = healthPercent;
    if (hpFactor < 0.5) {
      final glitchChance = 0.1 + (0.5 - hpFactor) * 0.8;
      if (_random.nextDouble() < glitchChance) {
        canvas.translate(
            (_random.nextDouble() - 0.5) * 3, (_random.nextDouble() - 0.5) * 3);
      }
    }

    // Render trail first (behind enemy)
    _renderTrail(canvas, phantomOpacity, allowBlur);

    // Render damage particles
    _renderDamageParticles(canvas, allowBlur);

    // Render 3D ground shadow (creates depth illusion)
    _render3DShadow(canvas, phantomOpacity);

    // Apply world-specific distortions/effects
    _applyWorldVisuals(canvas);

    // Apply walking bob transformation
    canvas.save();
    canvas.translate(_wobbleOffset, _verticalBob);

    // Animation pulse
    final animScale = _pulseScale * (1 + math.sin(_animationPhase) * 0.05);
    final radius = (size.x / 2) * animScale;

    // Speed-based motion blur when moving fast
    if (!reduceFx && _speedIndicator > 0.3) {
      _renderMotionBlur(canvas, radius, phantomOpacity, allowBlur);
    }

    // Warp/teleport effect for fast enemies (dimensional phasing)
    if (!reduceFx && isFastWarpType) {
      _renderWarpEffect(canvas, radius, phantomOpacity, allowBlur);
    }

    // Spawn/materialize effect (enemy teleporting into existence)
    if (!reduceFx && _isSpawning) {
      _renderSpawnEffect(canvas, radius, phantomOpacity, allowBlur);
    }

    // Outer glow (pulsing intensity based on walk phase)
    final glowPulse = 0.18 + math.sin(_walkPhase) * 0.05;
    final glowPath = _createBodyPath(radius * 1.05);
    _outerGlowPaint
      ..color = _worldGlowColor.withOpacity(glowPulse * phantomOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.16
      ..strokeJoin = StrokeJoin.bevel
      ..maskFilter = _blur(allowBlur, 8);
    canvas.drawPath(glowPath, _outerGlowPaint);

    // Main body glow
    final bodyPath = _createBodyPath(radius * 0.95);
    _bodyGlowPaint
      ..color = type.color.withOpacity(0.28 * phantomOpacity)
      ..style = PaintingStyle.fill
      ..maskFilter = _blur(allowBlur, 3);
    canvas.drawPath(bodyPath, _bodyGlowPaint);

    _renderSilhouetteAccents(canvas, radius, phantomOpacity, allowBlur);

    // Draw Internal Circuitry
    _drawInternalCircuitry(canvas, radius, phantomOpacity);

    // Draw Data Aura & Fragments
    if (!reduceFx) _drawDataAura(canvas, radius, phantomOpacity);

    // MEGA GEOMETRY: Core, Shell and Plates
    _drawMegaGeometry(canvas, radius, phantomOpacity, allowBlur);

    // World identity glyph for faster visual recognition.
    _drawWorldEmblem(canvas, radius, phantomOpacity, allowBlur);

    // Energy veins (pulsing light network on enemy body)
    if (!reduceFx) {
      _renderEnergyVeins(canvas, radius, phantomOpacity, allowBlur);
    }

    // Inner highlight (bobs with movement)
    final highlightOffset = Offset(
      -radius * 0.2 + math.sin(_walkPhase * 0.5) * 1,
      -radius * 0.2 + math.cos(_walkPhase * 0.5) * 1,
    );
    _highlightPaint
      ..color = Colors.white.withOpacity(0.35 * phantomOpacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.08;
    canvas.drawLine(
      highlightOffset + Offset(-radius * 0.3, -radius * 0.12),
      highlightOffset + Offset(radius * 0.35, -radius * 0.28),
      _highlightPaint,
    );
    _highlightPaint.strokeWidth = radius * 0.04;
    canvas.drawLine(
      highlightOffset + Offset(-radius * 0.22, 0),
      highlightOffset + Offset(radius * 0.28, -radius * 0.14),
      _highlightPaint,
    );

    if (threatTier > 0) {
      _renderThreatCrown(canvas, radius, phantomOpacity, allowBlur, reduceFx);
    }

    if (!reduceFx) {
      // Walking legs/tentacles effect (type-specific)
      _renderWalkingEffect(canvas, radius, phantomOpacity, allowBlur);

      // Corruption aura (system fracture)
      _renderCorruptionAura(canvas, radius, phantomOpacity, allowBlur);

      // Type-specific effects
      _renderTypeEffects(canvas, radius, phantomOpacity, allowBlur);

      // Glitch overlay on top
      _renderGlitchOverlay(canvas, radius, phantomOpacity, allowBlur);
    }

    canvas.restore(); // Restore world visuals
    canvas.restore(); // Restore walking bob

    // Hit flash overlay (outside canvas transform)
    if (!reduceFx && _hitFlashTimer > 0) {
      _renderHitFlash(canvas, radius, phantomOpacity, allowBlur);
    }

    // Plasma Smoke effect for damaged enemies
    if (!reduceFx && healthPercent < 0.45) {
      _renderPlasmaSmoke(canvas, radius, phantomOpacity);
    }

    // Slow indicator (ice crystal effect)
    if (!reduceFx && isSlowed) {
      _renderSlowEffect(canvas, radius, allowBlur);
    }

    // Lightning chain connections to nearby enemies
    if (!reduceFx) {
      _renderLightningChains(canvas, phantomOpacity);
    }

    // Health bar (always show while visible enough)
    if (phantomOpacity > 0.2) {
      _renderHealthBar(canvas, visibility: phantomOpacity);
    }

    // Status icons (above health bar, showing active effects)
    if (phantomOpacity > 0.2 && hasActiveStatusEffects) {
      _renderStatusIcons(canvas, phantomOpacity, reduceFx);
    }
  }

  // Cached MaskFilters for shadow rendering (avoid per-frame allocations)
  static const MaskFilter _shadowBlur8 = MaskFilter.blur(BlurStyle.normal, 8);
  static const MaskFilter _shadowBlur5 = MaskFilter.blur(BlurStyle.normal, 5);
  static const MaskFilter _shadowBlur2 = MaskFilter.blur(BlurStyle.normal, 2);

  /// Renders a 3D ground shadow beneath the enemy for depth perception
  void _render3DShadow(Canvas canvas, double opacity) {
    // HYPER-OPTIMIZED: Precalculated values, cached MaskFilters
    final radius = size.x / 2;
    final isLowFx = Enemy.lowFx;

    // Precalculate radius multipliers
    final r008 = radius * 0.08;
    final r04 = radius * 0.4;
    final r02 = radius * 0.2;
    final r012 = radius * 0.12;
    final r055 = radius * 0.55;
    final r14 = radius * 1.4;
    final r045 = radius * 0.45;

    // Floating animation
    final floatOffset = isLowFx ? 0.0 : math.sin(_animationTimer * 2.5) * r008;
    final shadowHeight = r04 + floatOffset;

    // Shadow scaling
    final heightFactor = 1.0 - (floatOffset / r02).clamp(0.0, 0.3);
    final shadowScale = isLowFx
        ? 0.75
        : (0.75 + math.sin(_animationPhase * 2) * 0.05) * heightFactor;

    // Shadow position and size
    final shadowOffsetX = r012;
    final shadowOffsetY = r055 + shadowHeight;
    final sizeMultClamped = type.sizeMult.clamp(0.8, 1.5);
    final shadowWidth = r14 * shadowScale * sizeMultClamped;
    final shadowHeightSize = r045 * shadowScale;
    final shadowCenter = Offset(shadowOffsetX, shadowOffsetY);

    // LowFx: single simple shadow
    if (isLowFx) {
      _shadowPaint
        ..color = Colors.black.withOpacity(0.45 * opacity)
        ..maskFilter = null;
      canvas.drawOval(
        Rect.fromCenter(
            center: shadowCenter, width: shadowWidth, height: shadowHeightSize),
        _shadowPaint,
      );
      return;
    }

    // Full quality: Multi-layer shadow with cached MaskFilters
    final opacityHeightFactor = opacity * heightFactor;

    // Outer diffuse shadow
    _shadowPaint
      ..color = Colors.black.withOpacity(0.25 * opacityHeightFactor)
      ..maskFilter = _shadowBlur8;
    canvas.drawOval(
      Rect.fromCenter(
          center: shadowCenter,
          width: shadowWidth * 1.2,
          height: shadowHeightSize * 1.1),
      _shadowPaint,
    );

    // Main shadow
    _shadowPaint
      ..color = Colors.black.withOpacity(0.4 * opacityHeightFactor)
      ..maskFilter = _shadowBlur5;
    canvas.drawOval(
      Rect.fromCenter(
          center: shadowCenter, width: shadowWidth, height: shadowHeightSize),
      _shadowPaint,
    );

    // Inner shadow core
    _shadowPaint
      ..color = Colors.black.withOpacity(0.3 * opacityHeightFactor)
      ..maskFilter = _shadowBlur2;
    canvas.drawOval(
      Rect.fromCenter(
          center: shadowCenter,
          width: shadowWidth * 0.5,
          height: shadowHeightSize * 0.4),
      _shadowPaint,
    );

    // Contact shadow (tiny dark spot directly under enemy)
    if (heightFactor > 0.8) {
      _shadowPaint
        ..color = Colors.black.withOpacity(0.15 * opacity)
        ..maskFilter = null;

      canvas.drawOval(
        Rect.fromCenter(
          center:
              Offset(shadowOffsetX * 0.5, shadowOffsetY - shadowHeight * 0.3),
          width: shadowWidth * 0.25,
          height: shadowHeightSize * 0.2,
        ),
        _shadowPaint,
      );
    }
  }

  void _renderMotionBlur(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    // Create motion blur effect based on movement direction
    final direction = position - _lastPosition;
    if (direction.length < 0.5) return;

    direction.normalize();
    final blurCount = 3;
    for (int i = 1; i <= blurCount; i++) {
      final blurOffset = -direction * (i * 5.0);
      final blurAlpha =
          (1 - i / (blurCount + 1)) * 0.35 * opacity * _speedIndicator;
      final blurPath = _createBodyPath(radius * (0.9 - i * 0.08));
      _trailPaint
        ..color = type.color.withOpacity(blurAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.08
        ..strokeCap = StrokeCap.square
        ..maskFilter = _blur(allowBlur, 3.0 + i * 1.5);
      canvas.save();
      canvas.translate(blurOffset.x, blurOffset.y);
      canvas.drawPath(blurPath, _trailPaint);
      canvas.restore();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WARP/TELEPORT EFFECT - Dimensional phasing for fast enemies
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderWarpEffect(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    final t = _animationTimer;
    final direction = movementDirection;
    final warpIntensity = (type.speedMult - 1.0).clamp(0.2, 0.8);

    // Update flicker phase for teleport effect
    _warpFlickerPhase += 0.1;

    // Use cached HSL-derived colors (computed once at init, not per-frame)
    final secondaryColor = _warpSecondaryColor;
    final tertiaryColor = _warpTertiaryColor;

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: Trailing afterimages (3-4 dimensional ghosts behind)
    // ═══════════════════════════════════════════════════════════════════════
    final ghostCount = 4;
    for (int i = 1; i <= ghostCount; i++) {
      final ghostOffset = -direction * (i * radius * 0.6);
      final ghostAlpha =
          (1 - i / (ghostCount + 1)) * 0.3 * opacity * warpIntensity;
      final ghostScale = 1.0 - i * 0.08;
      final phaseShift = math.sin(t * 8 + i * 0.5) * radius * 0.1;

      final ghostPath = _createBodyPath(radius * ghostScale);
      _warpAfterimgPaint
        ..color = type.color.withOpacity(ghostAlpha)
        ..style = PaintingStyle.fill
        ..maskFilter = _blur(allowBlur, 4.0 + i * 2);

      canvas.save();
      canvas.translate(ghostOffset.x + phaseShift, ghostOffset.y);
      canvas.drawPath(ghostPath, _warpAfterimgPaint);
      canvas.restore();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: Motion blur streaks in movement direction
    // ═══════════════════════════════════════════════════════════════════════
    final streakCount = 6;
    for (int i = 0; i < streakCount; i++) {
      final streakOffset = (i - streakCount / 2) * radius * 0.25;
      final perpX = -direction.y;
      final perpY = direction.x;
      final startX = perpX * streakOffset;
      final startY = perpY * streakOffset;
      final streakLength = radius * (1.5 + warpIntensity * 2);
      final endX = startX - direction.x * streakLength;
      final endY = startY - direction.y * streakLength;

      final streakAlpha = (1 - (i / streakCount - 0.5).abs() * 2) *
          0.4 *
          opacity *
          warpIntensity;
      _warpStreakPaint
        ..color = secondaryColor.withOpacity(streakAlpha)
        ..strokeWidth = radius * 0.08 * (1 - i / streakCount * 0.5)
        ..maskFilter = _blur(allowBlur, 3);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        _warpStreakPaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: Dimensional distortion ring around enemy
    // ═══════════════════════════════════════════════════════════════════════
    final ringPulse = 0.8 + math.sin(t * 6) * 0.2;
    final distortRadius = radius * 1.4 * ringPulse;

    // Outer distortion ring
    _warpDistortPaint
      ..color = tertiaryColor.withOpacity(0.35 * opacity * warpIntensity)
      ..strokeWidth = radius * 0.1
      ..maskFilter = _blur(allowBlur, 6);
    canvas.drawCircle(Offset.zero, distortRadius, _warpDistortPaint);

    // Inner wobbling ring
    _warpPath.reset();
    final segments = 16;
    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * math.pi * 2;
      final wobble =
          math.sin(angle * 4 + t * 10) * radius * 0.08 * warpIntensity;
      final r = distortRadius * 0.75 + wobble;
      final x = math.cos(angle) * r;
      final y = math.sin(angle) * r;
      if (i == 0) {
        _warpPath.moveTo(x, y);
      } else {
        _warpPath.lineTo(x, y);
      }
    }
    _warpPath.close();

    _warpDistortPaint
      ..color = type.color.withOpacity(0.25 * opacity * warpIntensity)
      ..strokeWidth = radius * 0.06
      ..maskFilter = _blur(allowBlur, 4);
    canvas.drawPath(_warpPath, _warpDistortPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: Energy particles trailing behind
    // ═══════════════════════════════════════════════════════════════════════
    final particleCount = 8;
    for (int i = 0; i < particleCount; i++) {
      final seed = (i * 7919 + spawnIndex * 31) % 1000;
      final particlePhase = t * 3 + seed * 0.001 * math.pi * 2;
      final particleT = (particlePhase % 1.0);

      // Spiral trajectory behind enemy
      final spiralAngle =
          particleT * math.pi * 4 + i * (math.pi * 2 / particleCount);
      final spiralRadius = radius * 0.3 * (1 - particleT * 0.5);
      final trailDist = particleT * radius * 2;

      final px =
          -direction.x * trailDist + math.cos(spiralAngle) * spiralRadius;
      final py =
          -direction.y * trailDist + math.sin(spiralAngle) * spiralRadius;
      final particleSize = radius * 0.08 * (1 - particleT);
      final particleAlpha = (1 - particleT) * 0.6 * opacity * warpIntensity;

      _warpParticlePaint
        ..color = (i % 2 == 0 ? type.color : secondaryColor)
            .withOpacity(particleAlpha)
        ..maskFilter = _blur(allowBlur, 3);
      canvas.drawCircle(Offset(px, py), particleSize, _warpParticlePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: Warp lightning/electric arcs
    // ═══════════════════════════════════════════════════════════════════════
    final arcCount = 3;
    for (int i = 0; i < arcCount; i++) {
      final arcSeed = (i * 1234 + (t * 20).toInt()) % 1000;
      final arcRand = _FastRng(arcSeed);

      // Random start point around enemy
      final startAngle = arcRand.nextDouble() * math.pi * 2;
      final startR = radius * (0.6 + arcRand.nextDouble() * 0.3);
      final startX = math.cos(startAngle) * startR;
      final startY = math.sin(startAngle) * startR;

      // End point further out
      final endAngle =
          startAngle + (arcRand.nextDouble() - 0.5) * math.pi * 0.5;
      final endR = radius * (1.2 + arcRand.nextDouble() * 0.5);
      final endX = math.cos(endAngle) * endR;
      final endY = math.sin(endAngle) * endR;

      // Draw jagged lightning path
      _warpPath.reset();
      _warpPath.moveTo(startX, startY);

      final segmentCount = 4;
      for (int j = 1; j <= segmentCount; j++) {
        final segT = j / segmentCount;
        final baseX = startX + (endX - startX) * segT;
        final baseY = startY + (endY - startY) * segT;
        final jitter = (1 - segT) * radius * 0.15 * warpIntensity;
        final jx = baseX + (arcRand.nextDouble() - 0.5) * jitter * 2;
        final jy = baseY + (arcRand.nextDouble() - 0.5) * jitter * 2;
        _warpPath.lineTo(jx, jy);
      }

      // Glow layer
      _warpLightningPaint
        ..color = tertiaryColor.withOpacity(0.4 * opacity * warpIntensity)
        ..strokeWidth = radius * 0.08
        ..maskFilter = _blur(allowBlur, 5);
      canvas.drawPath(_warpPath, _warpLightningPaint);

      // Core layer
      _warpLightningPaint
        ..color = Colors.white.withOpacity(0.6 * opacity * warpIntensity)
        ..strokeWidth = radius * 0.03
        ..maskFilter = null;
      canvas.drawPath(_warpPath, _warpLightningPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: Chromatic aberration split on the enemy
    // ═══════════════════════════════════════════════════════════════════════
    final chromaOffset =
        radius * 0.08 * warpIntensity * (1 + math.sin(t * 12) * 0.3);
    final bodyPath = _createBodyPath(radius * 0.95);

    // Red channel offset
    _warpChromaPaint
      ..color =
          const Color(0xFFFF0044).withOpacity(0.25 * opacity * warpIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.04
      ..maskFilter = _blur(allowBlur, 2);
    canvas.save();
    canvas.translate(-chromaOffset, -chromaOffset * 0.5);
    canvas.drawPath(bodyPath, _warpChromaPaint);
    canvas.restore();

    // Cyan channel offset
    _warpChromaPaint
      ..color =
          const Color(0xFF00FFFF).withOpacity(0.25 * opacity * warpIntensity);
    canvas.save();
    canvas.translate(chromaOffset, chromaOffset * 0.5);
    canvas.drawPath(bodyPath, _warpChromaPaint);
    canvas.restore();

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: Teleport flicker effect (randomly blink visibility)
    // ═══════════════════════════════════════════════════════════════════════
    final flickerValue = math.sin(_warpFlickerPhase * 17 + spawnIndex) *
        math.sin(_warpFlickerPhase * 23 + spawnIndex * 0.7);
    final shouldFlicker = flickerValue > 0.7 && warpIntensity > 0.3;

    if (shouldFlicker) {
      // Bright flash effect during flicker
      _warpFlickerPaint
        ..color = Colors.white.withOpacity(0.4 * opacity)
        ..maskFilter = _blur(allowBlur, 8);
      canvas.drawCircle(Offset.zero, radius * 1.2, _warpFlickerPaint);

      // Dimensional rift lines during flicker
      final riftCount = 5;
      for (int i = 0; i < riftCount; i++) {
        final riftAngle = (i / riftCount) * math.pi * 2 + t * 4;
        final riftLen = radius * (0.8 + _warpRandom.nextDouble() * 0.6);
        final rx = math.cos(riftAngle) * riftLen;
        final ry = math.sin(riftAngle) * riftLen;

        _warpLightningPaint
          ..color = type.color.withOpacity(0.5 * opacity)
          ..strokeWidth = radius * 0.04
          ..maskFilter = _blur(allowBlur, 3);
        canvas.drawLine(Offset.zero, Offset(rx, ry), _warpLightningPaint);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SPAWN/MATERIALIZE EFFECT - Enemy teleporting into existence
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderSpawnEffect(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    final t = _animationTimer;
    final progress = _spawnProgress;
    final inverseProgress = 1.0 - progress;

    // Get secondary color for effects
    final hslColor = HSLColor.fromColor(type.color);
    final secondaryColor =
        hslColor.withHue((hslColor.hue + 180) % 360).toColor();

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: Ground portal/circle where enemy spawns (render first, behind)
    // ═══════════════════════════════════════════════════════════════════════
    final portalRadius =
        radius * (1.8 + math.sin(t * 8) * 0.1) * (0.5 + progress * 0.5);
    final portalY = radius * 0.5; // Slightly below center

    // Outer portal glow
    _spawnPortalGlowPaint
      ..color = type.color.withOpacity(0.4 * inverseProgress * opacity)
      ..strokeWidth = radius * 0.15
      ..maskFilter = _blur(allowBlur, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, portalY),
        width: portalRadius * 2,
        height: portalRadius * 0.4,
      ),
      _spawnPortalGlowPaint,
    );

    // Inner portal ring
    _spawnPortalGlowPaint
      ..color = secondaryColor.withOpacity(0.5 * inverseProgress * opacity)
      ..strokeWidth = radius * 0.08
      ..maskFilter = _blur(allowBlur, 5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, portalY),
        width: portalRadius * 1.6,
        height: portalRadius * 0.32,
      ),
      _spawnPortalGlowPaint,
    );

    // Portal core fill
    _spawnPortalPaint
      ..color = type.color.withOpacity(0.2 * inverseProgress * opacity)
      ..maskFilter = _blur(allowBlur, 3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, portalY),
        width: portalRadius * 1.4,
        height: portalRadius * 0.28,
      ),
      _spawnPortalPaint,
    );

    // Portal hex pattern
    final hexCount = 6;
    for (int i = 0; i < hexCount; i++) {
      final hexAngle = (i / hexCount) * math.pi * 2 + t * 3;
      final hexDist = portalRadius * 0.7;
      final hx = math.cos(hexAngle) * hexDist;
      final hy = portalY + math.sin(hexAngle) * hexDist * 0.2;
      final hexSize = radius * 0.12 * inverseProgress;

      _spawnPortalPaint
        ..color = Colors.white.withOpacity(0.3 * inverseProgress * opacity);
      canvas.drawCircle(Offset(hx, hy), hexSize, _spawnPortalPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: Digital noise static (enemy form assembling)
    // ═══════════════════════════════════════════════════════════════════════
    if (inverseProgress > 0.2) {
      final noiseIntensity = inverseProgress * 0.8;
      final noiseCount = (12 * noiseIntensity).toInt();

      for (int i = 0; i < noiseCount; i++) {
        // Use deterministic pseudo-random based on time and index
        final noiseSeed = ((t * 20).toInt() + i * 73 + spawnIndex * 17) % 1000;
        final noiseRand = _FastRng(noiseSeed);

        final noiseAngle = noiseRand.nextDouble() * math.pi * 2;
        final noiseDist = noiseRand.nextDouble() * radius * 1.2;
        final nx = math.cos(noiseAngle) * noiseDist;
        final ny = math.sin(noiseAngle) * noiseDist;

        // Noise block size varies
        final blockW = radius * (0.08 + noiseRand.nextDouble() * 0.12);
        final blockH = radius * (0.04 + noiseRand.nextDouble() * 0.08);

        // Random color between enemy color and white
        final noiseColor =
            Color.lerp(type.color, Colors.white, noiseRand.nextDouble() * 0.5)!;

        _spawnNoisePaint
          ..color = noiseColor.withOpacity(0.5 * noiseIntensity * opacity);
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(nx, ny), width: blockW, height: blockH),
          _spawnNoisePaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: Particle coalescence (particles converging to form)
    // ═══════════════════════════════════════════════════════════════════════
    final particleCount = 16;
    for (int i = 0; i < particleCount; i++) {
      // Particles start far out and converge as spawn progresses
      final baseAngle = (i / particleCount) * math.pi * 2 + t * 2;
      final convergeFactor = 1.0 - progress; // 1.0 at start, 0.0 at end
      final startDist = radius * 3.5;
      final endDist = radius * 0.3;
      final currentDist = endDist + (startDist - endDist) * convergeFactor;

      // Add spiral motion
      final spiralOffset =
          math.sin(t * 6 + i * 0.5) * radius * 0.2 * convergeFactor;
      final px = math.cos(baseAngle) * (currentDist + spiralOffset);
      final py = math.sin(baseAngle) * (currentDist + spiralOffset);

      // Particle size grows as it converges
      final particleSize = radius * 0.06 * (1.0 + progress * 0.5);
      final particleAlpha = (0.6 + progress * 0.4) * opacity;

      // Glow
      _spawnParticlePaint
        ..color = type.color.withOpacity(particleAlpha * 0.5)
        ..maskFilter = _blur(allowBlur, 4);
      canvas.drawCircle(
          Offset(px, py), particleSize * 1.5, _spawnParticlePaint);

      // Core
      _spawnParticlePaint
        ..color = Colors.white.withOpacity(particleAlpha * 0.8)
        ..maskFilter = null;
      canvas.drawCircle(Offset(px, py), particleSize, _spawnParticlePaint);

      // Trail line toward center
      if (convergeFactor > 0.1) {
        final trailEndDist = currentDist * 0.6;
        final trailEndX = math.cos(baseAngle) * trailEndDist;
        final trailEndY = math.sin(baseAngle) * trailEndDist;

        _spawnHoloPaint
          ..color = type.color.withOpacity(0.3 * convergeFactor * opacity)
          ..strokeWidth = radius * 0.02
          ..maskFilter = _blur(allowBlur, 2);
        canvas.drawLine(
            Offset(px, py), Offset(trailEndX, trailEndY), _spawnHoloPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: Holographic outline (flickering enemy silhouette)
    // ═══════════════════════════════════════════════════════════════════════
    if (progress > 0.15) {
      final holoOpacity = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
      final flickerValue = math.sin(t * 25) * math.sin(t * 17 + 0.5);
      final flicker = flickerValue > 0.6 ? 0.3 : 1.0;

      // Holographic body outline
      final bodyPath = _createBodyPath(radius * (0.7 + progress * 0.3));

      // Outer glow
      _spawnHoloPaint
        ..color = type.color.withOpacity(0.3 * holoOpacity * flicker * opacity)
        ..strokeWidth = radius * 0.12
        ..maskFilter = _blur(allowBlur, 6);
      canvas.drawPath(bodyPath, _spawnHoloPaint);

      // Core outline
      _spawnHoloPaint
        ..color =
            secondaryColor.withOpacity(0.5 * holoOpacity * flicker * opacity)
        ..strokeWidth = radius * 0.04
        ..maskFilter = _blur(allowBlur, 2);
      canvas.drawPath(bodyPath, _spawnHoloPaint);

      // Inner bright edge
      _spawnHoloPaint
        ..color =
            Colors.white.withOpacity(0.4 * holoOpacity * flicker * opacity)
        ..strokeWidth = radius * 0.02
        ..maskFilter = null;
      canvas.drawPath(bodyPath, _spawnHoloPaint);

      // Glitch slices (horizontal displacement)
      if (inverseProgress > 0.1 && flickerValue > 0.3) {
        final sliceCount = 3;
        for (int i = 0; i < sliceCount; i++) {
          final sliceSeed = ((t * 15).toInt() + i * 47) % 100;
          final sliceRand = _FastRng(sliceSeed);
          final sliceY = (sliceRand.nextDouble() - 0.5) * radius * 1.6;
          final sliceHeight = radius * 0.1;
          final sliceOffset = (sliceRand.nextDouble() - 0.5) * radius * 0.3;

          _spawnGlitchPaint
            ..color = type.color.withOpacity(0.4 * inverseProgress * opacity);

          canvas.save();
          canvas.clipRect(Rect.fromCenter(
            center: Offset(0, sliceY),
            width: radius * 3,
            height: sliceHeight,
          ));
          canvas.translate(sliceOffset, 0);
          canvas.drawPath(bodyPath, _spawnGlitchPaint);
          canvas.restore();
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: Scanline sweep (materialization scan)
    // ═══════════════════════════════════════════════════════════════════════
    final scanY = -radius * 1.5 + progress * radius * 3.0;
    final scanHeight = radius * 0.15;

    // Main scanline
    _spawnScanlinePaint
      ..color = Colors.white.withOpacity(0.6 * opacity)
      ..maskFilter = _blur(allowBlur, 3);
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(0, scanY), width: radius * 2.5, height: scanHeight),
      _spawnScanlinePaint,
    );

    // Glow around scanline
    _spawnScanlinePaint
      ..color = type.color.withOpacity(0.4 * opacity)
      ..maskFilter = _blur(allowBlur, 8);
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(0, scanY),
          width: radius * 2.8,
          height: scanHeight * 2),
      _spawnScanlinePaint,
    );

    // Secondary scanlines (fading echoes)
    for (int i = 1; i <= 3; i++) {
      final echoY = scanY - i * radius * 0.25;
      final echoAlpha = 0.3 / i;
      _spawnScanlinePaint
        ..color = type.color.withOpacity(echoAlpha * opacity)
        ..maskFilter = _blur(allowBlur, 2);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, echoY),
            width: radius * 2.2,
            height: scanHeight * 0.5),
        _spawnScanlinePaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: Energy burst when fully materialized (progress > 0.85)
    // ═══════════════════════════════════════════════════════════════════════
    if (progress > 0.85) {
      final burstProgress = (progress - 0.85) / 0.15; // 0 to 1 in last 15%
      final burstRadius = radius * (1.0 + burstProgress * 1.5);
      final burstAlpha = (1.0 - burstProgress) * 0.6;

      // Expanding ring
      _spawnBurstPaint
        ..color = Colors.white.withOpacity(burstAlpha * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.15 * (1.0 - burstProgress)
        ..maskFilter = _blur(allowBlur, 6);
      canvas.drawCircle(Offset.zero, burstRadius, _spawnBurstPaint);

      // Inner energy flash
      _spawnBurstPaint
        ..color = type.color.withOpacity(burstAlpha * 0.5 * opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = _blur(allowBlur, 10);
      canvas.drawCircle(Offset.zero, burstRadius * 0.6, _spawnBurstPaint);

      // Radial rays
      final rayCount = 8;
      for (int i = 0; i < rayCount; i++) {
        final rayAngle = (i / rayCount) * math.pi * 2 + t * 2;
        final rayLength = burstRadius * (0.8 + burstProgress * 0.5);
        final rx = math.cos(rayAngle) * rayLength;
        final ry = math.sin(rayAngle) * rayLength;

        _spawnHoloPaint
          ..color = Colors.white.withOpacity(burstAlpha * 0.8 * opacity)
          ..strokeWidth = radius * 0.06 * (1.0 - burstProgress)
          ..maskFilter = _blur(allowBlur, 4);
        canvas.drawLine(Offset.zero, Offset(rx, ry), _spawnHoloPaint);
      }
    }
  }

  /// Update spawn particles and progress
  void _updateSpawnEffect(double dt) {
    if (!_isSpawning) return;

    _spawnProgress += dt / _spawnDuration;

    if (_spawnProgress >= 1.0) {
      _spawnProgress = 1.0;
      _isSpawning = false;
      _spawnParticles.clear();
    }
  }

  void _renderWalkingEffect(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    // Use cached walk style (computed once in constructor)
    final style = _cachedWalkStyle;

    switch (style) {
      case _WalkStyle.legs:
        _renderLegsEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.tendrils:
        _renderTendrilsEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.stomp:
        _renderStompEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.wisps:
        _renderWispsEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.glitch:
        _renderGlitchWalkEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.electric:
        _renderElectricWalkEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.crystal:
        _renderCrystalWalkEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.mechanical:
        _renderMechanicalWalkEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.digital:
        _renderDigitalWalkEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.storm:
        _renderStormWalkEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.void_:
        _renderVoidWalkEffect(canvas, radius, opacity, allowBlur);
        break;
      case _WalkStyle.omega:
        _renderOmegaWalkEffect(canvas, radius, opacity, allowBlur);
        break;
    }
  }

  _WalkStyle _getWalkingStyle() {
    switch (type) {
      // World 1 - Basic
      case EnemyType.runner:
        return _WalkStyle.legs;
      case EnemyType.overloaded:
        return _WalkStyle.tendrils;
      case EnemyType.juggernaut:
        return _WalkStyle.stomp;
      case EnemyType.phantom:
        return _WalkStyle.wisps;
      // World 2 - Rift Wars (Glitch)
      case EnemyType.glitcher:
      case EnemyType.riftwalker:
      case EnemyType.voidling:
      case EnemyType.dimensionBreaker:
        return _WalkStyle.glitch;
      // World 3 - Signal Wastes (Digital corruption)
      case EnemyType.corruptedByte:
      case EnemyType.malware:
      case EnemyType.dataWorm:
      case EnemyType.virusCarrier:
        return _WalkStyle.digital;
      // World 4 - Ion Crown (Electric)
      case EnemyType.sparkDrone:
      case EnemyType.plasmaCore:
      case EnemyType.ionSurge:
      case EnemyType.thunderHulk:
        return _WalkStyle.electric;
      // World 5 - Shard Vault (Crystal)
      case EnemyType.crystalShard:
      case EnemyType.gemCarrier:
      case EnemyType.prismWalker:
      case EnemyType.diamondGolem:
        return _WalkStyle.crystal;
      // World 6 - Arc Fortress (Mechanical)
      case EnemyType.sentryBot:
      case EnemyType.droneSwarm:
      case EnemyType.siegeWalker:
      case EnemyType.cloakedAssassin:
        return _WalkStyle.mechanical;
      // World 7 - Omega Grid (Matrix)
      case EnemyType.codeFragment:
      case EnemyType.matrixAgent:
      case EnemyType.firewallBreaker:
      case EnemyType.systemGhost:
        return _WalkStyle.digital;
      // World 8 - Storm Tower (Weather)
      case EnemyType.stormRunner:
      case EnemyType.cycloneSpirit:
      case EnemyType.thunderTitan:
      case EnemyType.lightningWraith:
        return _WalkStyle.storm;
      // World 9 - Final Gate (Void)
      case EnemyType.voidStalker:
      case EnemyType.abyssWalker:
      case EnemyType.shadowSwarm:
      case EnemyType.darknessTitan:
        return _WalkStyle.void_;
      // World 10 - Omega Nexus (Ultimate)
      case EnemyType.nexusHunter:
      case EnemyType.omegaSentinel:
      case EnemyType.realityShifter:
      case EnemyType.apocalypseHerald:
        return _WalkStyle.omega;
    }
  }

  void _renderLegsEffect(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    // OPTIMIZED: Reuse paint, precalculate constants, cache sin/cos
    final r08 = radius * 0.8;
    final r02 = radius * 0.2;
    final walkPhase2 = _walkPhase * 2;
    final opacity06 = 0.6 * opacity;

    _legPaint
      ..color = type.color.withOpacity(opacity06)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square
      ..maskFilter = _blur(allowBlur, 2);

    for (int i = 0; i < 4; i++) {
      final legPhase = walkPhase2 + i * math.pi / 2;
      final sinLegPhase = math.sin(legPhase);
      final legAngle = math.pi / 2 + i * math.pi / 2 + sinLegPhase * 0.3;
      final legLength = r08 + sinLegPhase * r02;
      final cosAngle = math.cos(legAngle);
      final sinAngle = math.sin(legAngle);
      _tempOffset1 = Offset(cosAngle * legLength, sinAngle * legLength);
      canvas.drawLine(Offset.zero, _tempOffset1, _legPaint);
    }
  }

  void _renderTendrilsEffect(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    // OPTIMIZED: Reuse paint, precalculate, cache trig
    final r08 = radius * 0.8;
    final r03 = radius * 0.3;
    final animPhase15 = _animationPhase * 1.5;
    final opacity04 = 0.4 * opacity;

    _tendrilPaint
      ..color = Colors.white.withOpacity(opacity04)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.square
      ..maskFilter = _blur(allowBlur, 3);

    for (int i = 0; i < 6; i++) {
      final tendrilAngle = animPhase15 + i * math.pi / 3;
      final sinWalkPlusI = math.sin(_walkPhase + i);
      final tendrilLength = r08 + sinWalkPlusI * r03;
      final cosAngle = math.cos(tendrilAngle);
      final sinAngle = math.sin(tendrilAngle);
      _tempOffset1 = Offset(cosAngle * tendrilLength, sinAngle * tendrilLength);
      canvas.drawLine(Offset.zero, _tempOffset1, _tendrilPaint);
    }
  }

  void _renderStompEffect(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    // OPTIMIZED: Precalculate, reuse paints, cache sin/cos
    final r03 = radius * 0.3;
    final r07 = radius * 0.7;
    final r06 = radius * 0.6;
    final r05 = radius * 0.5;
    final r018 = radius * 0.18;
    final r022 = radius * 0.22;
    final impactRadius = Radius.circular(radius * 0.04);
    final footRadius = Radius.circular(radius * 0.05);
    final opacity03 = 0.3 * opacity;
    final opacity07 = 0.7 * opacity;

    // Setup paints once
    _impactPaint
      ..color = type.color.withOpacity(opacity03)
      ..maskFilter = _blur(allowBlur, 6);
    _footPaint.color = type.color.withOpacity(opacity07);

    for (int i = 0; i < 2; i++) {
      final footPhase = _walkPhase + i * math.pi;
      final sinFootPhase = math.sin(footPhase);
      final footAngle = math.pi / 2 + i * math.pi;
      final footOffset = sinFootPhase * r03;
      final baseLen = r07 + footOffset;
      final cosAngle = math.cos(footAngle);
      final sinAngle = math.sin(footAngle);
      final footX = cosAngle * baseLen;
      final footY = sinAngle * baseLen + sinFootPhase.abs() * 3;

      if (sinFootPhase < -0.8) {
        final impactRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(footX, footY + 2), width: r06, height: r018),
          impactRadius,
        );
        canvas.drawRRect(impactRect, _impactPaint);
      }

      final footRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(footX, footY), width: r05, height: r022),
        footRadius,
      );
      canvas.drawRRect(footRect, _footPaint);
    }
  }

  void _renderWispsEffect(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    // OPTIMIZED: Precalculate, cache trig, reuse paint
    final r09 = radius * 0.9;
    final r03 = radius * 0.3;
    final animPhase2 = _animationPhase * 2;
    final animPhase04 = _animationPhase * 0.4;
    final opacity04 = 0.4 * opacity;
    final blurFilter = _blur(allowBlur, 2);

    _wispPaint
      ..style = PaintingStyle.fill
      ..maskFilter = blurFilter;

    for (int i = 0; i < 4; i++) {
      final wispPhase = animPhase2 + i * math.pi / 2;
      final sinPhaseHalf = math.sin(wispPhase * 0.5);
      final wispDist = r09 + sinPhaseHalf * r03;
      final wispAngle = wispPhase * 0.3 + i * math.pi / 2;
      final cosAngle = math.cos(wispAngle);
      final sinAngle = math.sin(wispAngle);
      final wispX = cosAngle * wispDist;
      final wispY = sinAngle * wispDist;
      final rotAngle = wispAngle + animPhase04;

      for (int j = 0; j < 3; j++) {
        final trailAlpha = (1 - j / 3) * opacity04;
        final trailOffset = j * 3.0;
        final shardX = wispX - cosAngle * trailOffset;
        final shardY = wispY - sinAngle * trailOffset;
        canvas.save();
        canvas.translate(shardX, shardY);
        canvas.rotate(rotAngle);
        _wispPaint.color = type.color.withOpacity(trailAlpha);
        canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: 4.0 - j, height: 1.5),
            _wispPaint);
        canvas.restore();
      }
    }
  }

  void _renderGlitchWalkEffect(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    // OPTIMIZED: Reuse paints, precalculate, cache trig
    final r07 = radius * 0.7;
    final r04 = radius * 0.4;
    final animTimer8 = _animationTimer * 8;
    final animTimer2 = _animationTimer * 2;
    final blurFilter3 = _blur(allowBlur, 3);

    _glitchPaint
      ..color = type.color.withOpacity(0.5 * opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square
      ..maskFilter = blurFilter3;

    for (int i = 0; i < 5; i++) {
      final glitchPhase = animTimer8 + i * 1.2;
      final sinGlitch = math.sin(glitchPhase);
      if (sinGlitch <= 0.3) continue;

      final angle = (i / 5) * math.pi * 2 + animTimer2;
      final sinGlitchHalf = math.sin(glitchPhase * 0.5);
      final dist = r07 + sinGlitchHalf * r04;
      final cosAngle = math.cos(angle);
      final sinAngle = math.sin(angle);
      final x = cosAngle * dist;
      final y = sinAngle * dist;
      final offsetX = math.sin(glitchPhase * 3) * 4;

      _tempOffset1 = Offset(x + offsetX, y - 4);
      _tempOffset2 = Offset(x - offsetX, y + 4);
      canvas.drawLine(_tempOffset1, _tempOffset2, _glitchPaint);
    }

    // Rift portal effect
    if (type == EnemyType.riftwalker || type == EnemyType.dimensionBreaker) {
      _riftPaint
        ..color = const Color(0xFFFF00FF).withOpacity(0.3 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = _blur(allowBlur, 4);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: radius * 1.8, height: radius * 0.6),
        _riftPaint,
      );
    }
  }

  void _renderElectricWalkEffect(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    // OPTIMIZED: Reuse paints, precalculate, cache trig
    final r06 = radius * 0.6;
    final r03 = radius * 0.3;
    final animTimer12 = _animationTimer * 12;

    _sparkPaint
      ..color = type.color.withOpacity(0.7 * opacity)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      final sparkPhase = animTimer12 + i * 0.8;
      final sinSparkPhase = math.sin(sparkPhase);
      if (sinSparkPhase <= 0.2) continue;

      final angle = (i / 6) * math.pi * 2;
      final cosAngle = math.cos(angle);
      final sinAngle = math.sin(angle);
      final startDist = r06;
      final endDist = radius + sinSparkPhase * 2 * r03;

      final startX = cosAngle * startDist;
      final startY = sinAngle * startDist;
      final endX = cosAngle * endDist;
      final endY = sinAngle * endDist;

      final sparkPhase5 = sparkPhase * 5;
      final midX = (startX + endX) / 2 + math.sin(sparkPhase5) * 3;
      final midY = (startY + endY) / 2 + math.cos(sparkPhase5) * 3;

      _tempOffset1 = Offset(startX, startY);
      _tempOffset2 = Offset(midX, midY);
      _tempOffset3 = Offset(endX, endY);
      canvas.drawLine(_tempOffset1, _tempOffset2, _sparkPaint);
      canvas.drawLine(_tempOffset2, _tempOffset3, _sparkPaint);
    }

    // Electric aura for larger enemies
    if (type == EnemyType.thunderHulk || type == EnemyType.plasmaCore) {
      _auraPaint
        ..color = type.color.withOpacity(0.2 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = _blur(allowBlur, 8);
      canvas.drawCircle(Offset.zero, radius * 1.3, _auraPaint);
    }
  }

  // Static ray colors for crystal effect
  static const List<Color> _rayColors = [
    Color(0xFFFF0000),
    Color(0xFF00FF00),
    Color(0xFF0000FF)
  ];

  void _renderCrystalWalkEffect(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    // OPTIMIZED: Reuse paints, precalculate, cache trig
    final r09 = radius * 0.9;
    final r02 = radius * 0.2;
    final r015 = radius * 0.15;
    final r005 = radius * 0.05;
    final animTimer15 = _animationTimer * 1.5;
    final animTimer05 = _animationTimer * 0.5;
    final opacity06 = 0.6 * opacity;
    final opacity03 = 0.3 * opacity;

    _crystalPaint
      ..color = type.color.withOpacity(opacity06)
      ..style = PaintingStyle.fill;

    _strokePaint
      ..color = Colors.white.withOpacity(opacity03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      final phase = animTimer15 + i * math.pi * 0.4;
      final sinPhase = math.sin(phase);
      final dist = r09 + sinPhase * r02;
      final angle = (i / 5) * math.pi * 2 + animTimer05;
      final cosAngle = math.cos(angle);
      final sinAngle = math.sin(angle);
      final x = cosAngle * dist;
      final y = sinAngle * dist;
      final shardSize = r015 + r005 * math.sin(phase * 2);
      final shardHalf = shardSize * 0.5;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + _animationTimer);

      // Diamond shard shape
      _reusableOverlayPath.reset();
      _reusableOverlayPath.moveTo(0, -shardSize);
      _reusableOverlayPath.lineTo(shardHalf, 0);
      _reusableOverlayPath.lineTo(0, shardSize);
      _reusableOverlayPath.lineTo(-shardHalf, 0);
      _reusableOverlayPath.close();

      canvas.drawPath(_reusableOverlayPath, _crystalPaint);
      canvas.drawPath(_reusableOverlayPath, _strokePaint);
      canvas.restore();
    }

    // Prismatic light rays for special types
    if (type == EnemyType.prismWalker || type == EnemyType.diamondGolem) {
      final animTimer2 = _animationTimer * 2;
      final rayLen = radius * 1.5;
      final rayOpacity = 0.15 * opacity;
      final blurFilter = _blur(allowBlur, 4);

      _rayPaint
        ..strokeWidth = 2
        ..maskFilter = blurFilter;

      for (int i = 0; i < 3; i++) {
        final rayAngle = animTimer2 + i * math.pi * 2 / 3;
        final cosRay = math.cos(rayAngle);
        final sinRay = math.sin(rayAngle);
        _rayPaint.color = _rayColors[i].withOpacity(rayOpacity);
        _tempOffset1 = Offset(cosRay * rayLen, sinRay * rayLen);
        canvas.drawLine(Offset.zero, _tempOffset1, _rayPaint);
      }
    }
  }

  void _renderMechanicalWalkEffect(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    // HYPER-OPTIMIZED: All calculations precached, all paints static
    final r08 = radius * 0.8;
    final r07 = radius * 0.7;
    final r03 = radius * 0.3;
    final opacity07 = 0.7 * opacity;
    final opacity05 = 0.5 * opacity;

    _metalPaint
      ..color = type.color.withOpacity(opacity07)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square
      ..maskFilter = _blur(allowBlur, 2);

    if (type == EnemyType.droneSwarm) {
      final animTimer20 = _animationTimer * 20;
      for (int i = 0; i < 4; i++) {
        final bladeAngle = animTimer20 + i * math.pi / 2;
        _tempOffset1 =
            Offset(math.cos(bladeAngle) * r08, math.sin(bladeAngle) * r08);
        canvas.drawLine(Offset.zero, _tempOffset1, _metalPaint);
      }
    } else {
      final walkPhase15 = _walkPhase * 1.5;
      _corePaint.color = Colors.white.withOpacity(opacity05);

      for (int i = 0; i < 4; i++) {
        final legPhase = walkPhase15 + i * math.pi / 2;
        final sinLegPhase = math.sin(legPhase);
        final extension = sinLegPhase * r03;
        final angle = math.pi / 2 + i * math.pi / 2;
        final cosAngle = math.cos(angle);
        final sinAngle = math.sin(angle);

        final x1 = cosAngle * r07;
        final y1 = sinAngle * r07;
        final extLen = r07 + extension;
        final x2 = cosAngle * extLen;
        final y2 = sinAngle * extLen;

        _tempOffset1 = Offset(x1, y1);
        _tempOffset2 = Offset(x2, y2);
        canvas.drawCircle(_tempOffset1, 2, _corePaint);
        canvas.drawLine(_tempOffset1, _tempOffset2, _metalPaint);
      }
    }

    if (type == EnemyType.siegeWalker) {
      final exhaustPhase = _animationTimer * 4;
      if (math.sin(exhaustPhase) > 0.5) {
        _flamePaint
          ..color = const Color(0xFFFF6600).withOpacity(0.4 * opacity)
          ..maskFilter = _blur(allowBlur, 6);
        canvas.drawCircle(Offset(-radius * 0.8, 0), radius * 0.15, _flamePaint);
      }
    }
  }

  void _renderDigitalWalkEffect(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    // HYPER-OPTIMIZED: Precalc all, reuse paint
    final r05 = radius * 0.5;
    final r08 = radius * 0.8;
    final animTimer3 = _animationTimer * 3;
    final opacity06 = 0.6 * opacity;

    _dataPaint.style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final phase = animTimer3 + i * 0.4;
      final progress = phase % 1.0;
      final invProgress = 1 - progress;
      final angle = (i / 8) * math.pi * 2;
      final dist = r05 + progress * r08;
      final cosAngle = math.cos(angle);
      final sinAngle = math.sin(angle);
      final x = cosAngle * dist;
      final y = sinAngle * dist;
      final bitSize = 2 + invProgress * 2;

      _dataPaint.color = type.color.withOpacity(invProgress * opacity06);
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(x, y), width: bitSize, height: bitSize),
          _dataPaint);
    }

    if (type == EnemyType.matrixAgent || type == EnemyType.firewallBreaker) {
      final r06 = radius * 0.6;
      final r04 = radius * 0.4;
      final r2 = radius * 2;
      final animTimer2 = _animationTimer * 2;
      _dataPaint.color = const Color(0xFF00FF00).withOpacity(0.4 * opacity);

      for (int i = 0; i < 4; i++) {
        final rainX = -r06 + i * r04;
        final rainY = (((animTimer2 + i * 0.3) % 1.0) - 0.5) * r2;
        canvas.drawRect(
            Rect.fromCenter(center: Offset(rainX, rainY), width: 2, height: 6),
            _dataPaint);
      }
    }
  }

  void _renderStormWalkEffect(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    // HYPER-OPTIMIZED: All precalc, static paints
    final animTimer4 = _animationTimer * 4;
    final blurFilter3 = _blur(allowBlur, 3);

    _windPaint
      ..color = type.color.withOpacity(0.4 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = blurFilter3;

    for (int i = 0; i < 3; i++) {
      final spiralPhase = animTimer4 + i * math.pi * 2 / 3;
      final spiralRadius = radius * (0.6 + i * 0.2);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: spiralRadius),
        spiralPhase,
        math.pi * 0.7,
        false,
        _windPaint,
      );
    }

    if (type == EnemyType.thunderTitan || type == EnemyType.lightningWraith) {
      final boltPhase = _animationTimer * 15;
      final sinBolt = math.sin(boltPhase);
      if (sinBolt > 0.7) {
        final boltAngle = math.sin(boltPhase * 0.3) * math.pi;
        final r15 = radius * 1.5;
        _sparkPaint
          ..color = Colors.white.withOpacity(0.8 * opacity)
          ..strokeWidth = 2
          ..maskFilter = _blur(allowBlur, 4);
        _tempOffset1 =
            Offset(math.cos(boltAngle) * r15, math.sin(boltAngle) * r15);
        canvas.drawLine(Offset.zero, _tempOffset1, _sparkPaint);
      }
    }

    final r06 = radius * 0.6;
    final r2 = radius * 2;
    final animTimer3 = _animationTimer * 3;
    _swirlPaint
      ..color = const Color(0xFF99CCFF).withOpacity(0.3 * opacity)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final dropX = -radius + i * r06;
      final dropY = (((animTimer3 + i * 0.25) % 1.0) - 0.5) * r2;
      _tempOffset1 = Offset(dropX, dropY);
      _tempOffset2 = Offset(dropX - 2, dropY + 4);
      canvas.drawLine(_tempOffset1, _tempOffset2, _swirlPaint);
    }
  }

  void _renderVoidWalkEffect(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    // HYPER-OPTIMIZED: All precalc, static paints
    final r08 = radius * 0.8;
    final r03 = radius * 0.3;
    final animTimer15 = _animationTimer * 1.5;
    final blurFilter2 = _blur(allowBlur, 2);

    _voidPaint
      ..color = type.color.withOpacity(0.6 * opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = blurFilter2;

    for (int i = 0; i < 5; i++) {
      final tendrilPhase = animTimer15 + i * math.pi * 0.4;
      final sinPhase = math.sin(tendrilPhase);
      final sinPhase2 = math.sin(tendrilPhase * 2);
      final sinPhase3 = math.sin(tendrilPhase * 3);
      final angle = (i / 5) * math.pi * 2 + sinPhase * 0.3;
      final length = r08 + sinPhase2 * r03;
      final cosAngle = math.cos(angle);
      final sinAngle = math.sin(angle);

      final midAngle = angle + sinPhase3 * 0.2;
      final midDist = length * 0.5;
      final cosMid = math.cos(midAngle);
      final sinMid = math.sin(midAngle);
      final midX = cosMid * midDist;
      final midY = sinMid * midDist;
      final endX = cosAngle * length;
      final endY = sinAngle * length;

      _tempOffset1 = Offset(midX, midY);
      _tempOffset2 = Offset(endX, endY);
      canvas.drawLine(Offset.zero, _tempOffset1, _voidPaint);
      canvas.drawLine(_tempOffset1, _tempOffset2, _voidPaint);
    }

    _shadowPaint
      ..color = Colors.black.withOpacity(0.2 * opacity)
      ..maskFilter = _blur(allowBlur, 10);
    canvas.drawCircle(Offset.zero, radius * 1.2, _shadowPaint);

    if (type == EnemyType.shadowSwarm) {
      final animTimer2 = _animationTimer * 2;
      _particlePaint.color = type.color.withOpacity(0.4 * opacity);
      for (int i = 0; i < 6; i++) {
        final phase = animTimer2 + i;
        final px = math.cos(phase) * r08;
        final py = math.sin(phase) * r08;
        canvas.drawCircle(Offset(px, py), 2, _particlePaint);
      }
    }
  }

  void _renderOmegaWalkEffect(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    // HYPER-OPTIMIZED: All precalc, static paints
    final blurFilter3 = _blur(allowBlur, 3);
    final blurFilter2 = _blur(allowBlur, 2);
    final r05 = radius * 0.5;
    final r09 = radius * 0.9;
    final r03 = radius * 0.3;

    _omegaPaint
      ..color = type.color.withOpacity(0.5 * opacity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..maskFilter = blurFilter3;

    // Rotating energy rings
    for (int i = 0; i < 3; i++) {
      final ringPhase = _animationTimer * (2 + i * 0.5);
      final ringRadius = radius * (0.7 + i * 0.2);
      canvas.save();
      canvas.rotate(ringPhase);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: ringRadius),
        0,
        math.pi * 1.5,
        false,
        _omegaPaint,
      );
      canvas.restore();
    }

    // Energy spikes
    final animTimer3 = _animationTimer * 3;
    _sparkPaint
      ..color = Colors.white.withOpacity(0.6 * opacity)
      ..strokeWidth = 1.5
      ..maskFilter = blurFilter2;

    for (int i = 0; i < 6; i++) {
      final spikePhase = animTimer3 + i * math.pi / 3;
      final sinSpike2 = math.sin(spikePhase * 2);
      if (sinSpike2 <= 0) continue;

      final angle = (i / 6) * math.pi * 2;
      final cosAngle = math.cos(angle);
      final sinAngle = math.sin(angle);
      final sinSpike = math.sin(spikePhase);
      final length = r09 + sinSpike * r03;

      _tempOffset1 = Offset(cosAngle * r05, sinAngle * r05);
      _tempOffset2 = Offset(cosAngle * length, sinAngle * length);
      canvas.drawLine(_tempOffset1, _tempOffset2, _sparkPaint);
    }

    if (type == EnemyType.realityShifter) {
      final distortPhase = _animationTimer * 5;
      final sinDistort = math.sin(distortPhase);
      if (sinDistort > 0.5) {
        final distortPhase3 = distortPhase * 3;
        _auraPaint
          ..color = type.color.withOpacity(0.2 * opacity)
          ..maskFilter = _blur(allowBlur, 8);
        canvas.drawCircle(
          Offset(math.sin(distortPhase3) * 5, math.cos(distortPhase3) * 5),
          radius * 0.8,
          _auraPaint,
        );
      }
    }

    // Apocalypse flames for herald
    if (type == EnemyType.apocalypseHerald) {
      for (int i = 0; i < 4; i++) {
        final flamePhase = _animationTimer * 6 + i;
        final flameY = -radius * 0.5 - math.sin(flamePhase) * radius * 0.3;
        final flameX = (i - 1.5) * radius * 0.4;
        _flamePaint
          ..color = const Color(0xFFFF3300).withOpacity(0.4 * opacity)
          ..maskFilter = _blur(allowBlur, 5);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(flameX, flameY),
              width: radius * 0.2,
              height: radius * 0.4),
          _flamePaint,
        );
      }
    }
  }

  void _renderHitFlash(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    final flashProgress = _hitFlashTimer / _hitFlashDuration;

    // ═══════════════════════════════════════════════════════════════════════
    // EPIC HOLOGRAPHIC SHIELD BUBBLE EFFECT
    // ═══════════════════════════════════════════════════════════════════════

    // LAYER 1: Deep outer glow pulse
    _shieldGlowPaint
      ..color = type.color.withOpacity(flashProgress * 0.25 * opacity)
      ..maskFilter = _blur(allowBlur, 12);
    canvas.drawCircle(Offset.zero, radius * (1.4 + (1 - flashProgress) * 0.6),
        _shieldGlowPaint);

    // Secondary magenta glow
    _shieldGlowPaint
      ..color =
          const Color(0xFFFF0066).withOpacity(flashProgress * 0.15 * opacity)
      ..maskFilter = _blur(allowBlur, 8);
    canvas.drawCircle(Offset.zero, radius * (1.2 + (1 - flashProgress) * 0.4),
        _shieldGlowPaint);

    // LAYER 2: Multiple hexagonal shield rings expanding outward
    for (int ring = 0; ring < 3; ring++) {
      final ringDelay = ring * 0.15;
      final ringProgress =
          ((flashProgress - ringDelay) / (1 - ringDelay)).clamp(0.0, 1.0);
      if (ringProgress <= 0) continue;

      final hexRadius =
          radius * (1.1 + (1 - ringProgress) * (0.4 + ring * 0.2));
      final hexRotation = _animationPhase + ring * math.pi / 6;

      // Create hexagon path
      _reusableShieldPath.reset();
      for (int i = 0; i < 6; i++) {
        final angle = hexRotation + i * math.pi / 3;
        final x = math.cos(angle) * hexRadius;
        final y = math.sin(angle) * hexRadius;
        if (i == 0) {
          _reusableShieldPath.moveTo(x, y);
        } else {
          _reusableShieldPath.lineTo(x, y);
        }
      }
      _reusableShieldPath.close();

      // Hexagon glow
      _shieldHexPaint
        ..color = type.color
            .withOpacity(ringProgress * 0.4 * opacity * (1 - ring * 0.25))
        ..strokeWidth = 2.5 - ring * 0.5
        ..maskFilter = _blur(allowBlur, 4);
      canvas.drawPath(_reusableShieldPath, _shieldHexPaint);

      // Hexagon core line
      _shieldHexPaint
        ..color = Colors.white
            .withOpacity(ringProgress * 0.5 * opacity * (1 - ring * 0.2))
        ..strokeWidth = 1.5 - ring * 0.3
        ..maskFilter = null;
      canvas.drawPath(_reusableShieldPath, _shieldHexPaint);

      // Energy nodes at hexagon vertices
      for (int i = 0; i < 6; i++) {
        final angle = hexRotation + i * math.pi / 3;
        final nodeX = math.cos(angle) * hexRadius;
        final nodeY = math.sin(angle) * hexRadius;
        final nodePhase = math.sin(_animationPhase * 4 + i);

        if (nodePhase > 0.3) {
          _shieldCorePaint.color =
              Colors.white.withOpacity(ringProgress * 0.7 * opacity);
          canvas.drawCircle(
              Offset(nodeX, nodeY), 2.5 - ring * 0.5, _shieldCorePaint);

          _shieldGlowPaint
            ..color = type.color.withOpacity(ringProgress * 0.4 * opacity)
            ..maskFilter = _blur(allowBlur, 4);
          canvas.drawCircle(
              Offset(nodeX, nodeY), 4 - ring * 0.5, _shieldGlowPaint);
        }
      }
    }

    // LAYER 3: Energy ripple waves
    for (int i = 0; i < 4; i++) {
      final rippleDelay = i * 0.1;
      final rippleProgress =
          ((flashProgress - rippleDelay) / (1 - rippleDelay)).clamp(0.0, 1.0);
      if (rippleProgress <= 0) continue;

      final rippleRadius = radius * (0.9 + rippleProgress * 0.8);
      final rippleAlpha = (1 - rippleProgress) * flashProgress * 0.35;

      _shieldRipplePaint
        ..color = (i % 2 == 0 ? type.color : const Color(0xFFFF0066))
            .withOpacity(rippleAlpha * opacity)
        ..strokeWidth = 1.5 * (1 - rippleProgress * 0.5)
        ..maskFilter = _blur(allowBlur, 2);
      canvas.drawCircle(Offset.zero, rippleRadius, _shieldRipplePaint);
    }

    // LAYER 4: Holographic interference bands
    final bandCount = 8;
    for (int i = 0; i < bandCount; i++) {
      final bandAngle = _animationPhase * 2 + i * math.pi * 2 / bandCount;
      final bandRadius = radius * (0.8 + (1 - flashProgress) * 0.5);
      final bandLength = radius * 0.4;

      final startX = math.cos(bandAngle) * (bandRadius - bandLength * 0.5);
      final startY = math.sin(bandAngle) * (bandRadius - bandLength * 0.5);
      final endX = math.cos(bandAngle) * (bandRadius + bandLength * 0.5);
      final endY = math.sin(bandAngle) * (bandRadius + bandLength * 0.5);

      _shieldInterferencePaint
        ..color = (i % 3 == 0
                ? const Color(0xFF00FFFF)
                : i % 3 == 1
                    ? const Color(0xFFFF00FF)
                    : type.color)
            .withOpacity(flashProgress *
                0.2 *
                opacity *
                math.sin(_animationPhase * 3 + i).abs())
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..maskFilter = _blur(allowBlur, 1);
      canvas.drawLine(
          Offset(startX, startY), Offset(endX, endY), _shieldInterferencePaint);
    }

    // LAYER 5: Data fragment scatter
    for (int i = 0; i < 12; i++) {
      final fragmentAngle = _animationPhase + i * math.pi / 6;
      final fragmentSpeed = 0.5 + (i % 3) * 0.3;
      final fragmentDist = radius * (0.8 + (1 - flashProgress) * fragmentSpeed);
      final fragmentX = math.cos(fragmentAngle) * fragmentDist;
      final fragmentY = math.sin(fragmentAngle) * fragmentDist;

      final fragmentAlpha =
          flashProgress * 0.6 * (1 - (1 - flashProgress) * 0.7);
      _shieldFragmentPaint.color = (i % 2 == 0 ? type.color : Colors.white)
          .withOpacity(fragmentAlpha * opacity);

      // Small rectangles as data fragments
      canvas.save();
      canvas.translate(fragmentX, fragmentY);
      canvas.rotate(fragmentAngle + _animationPhase * 2);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 3, height: 1.5),
        _shieldFragmentPaint,
      );
      canvas.restore();
    }

    // LAYER 6: Electric arc discharge
    for (int i = 0; i < 6; i++) {
      final arcAngle = i * math.pi / 3 + _animationPhase;
      final arcStartRadius = radius * 0.9;
      final arcEndRadius = radius * (1.2 + (1 - flashProgress) * 0.4);

      final arcStartX = math.cos(arcAngle) * arcStartRadius;
      final arcStartY = math.sin(arcAngle) * arcStartRadius;

      _reusableOverlayPath.reset();
      _reusableOverlayPath.moveTo(arcStartX, arcStartY);
      final segments = 4;
      for (int s = 1; s <= segments; s++) {
        final t = s / segments;
        final currentRadius =
            arcStartRadius + (arcEndRadius - arcStartRadius) * t;
        final jitter = (s < segments) ? (_random.nextDouble() - 0.5) * 6 : 0.0;
        final perpAngle = arcAngle + math.pi / 2;
        final x =
            math.cos(arcAngle) * currentRadius + math.cos(perpAngle) * jitter;
        final y =
            math.sin(arcAngle) * currentRadius + math.sin(perpAngle) * jitter;
        _reusableOverlayPath.lineTo(x, y);
      }

      // Arc glow
      _shieldHexPaint
        ..color = type.color.withOpacity(flashProgress * 0.4 * opacity)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = _blur(allowBlur, 3);
      canvas.drawPath(_reusableOverlayPath, _shieldHexPaint);

      // Arc core
      _shieldHexPaint
        ..color = Colors.white.withOpacity(flashProgress * 0.7 * opacity)
        ..strokeWidth = 1
        ..maskFilter = null;
      canvas.drawPath(_reusableOverlayPath, _shieldHexPaint);
    }

    // LAYER 7: Central flash overlay
    final flashPath = _createBodyPath(radius * 1.1);
    _highlightPaint
      ..color = Colors.white.withOpacity(flashProgress * 0.4 * opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = _blur(allowBlur, 3);
    canvas.drawPath(flashPath, _highlightPaint);

    // LAYER 8: Chromatic aberration effect on body
    if (flashProgress > 0.5) {
      final chromaOffset = (flashProgress - 0.5) * 4;
      final chromaAlpha = (flashProgress - 0.5) * 0.3 * opacity;

      // Red channel offset
      canvas.save();
      canvas.translate(-chromaOffset, 0);
      _highlightPaint.color = Colors.red.withOpacity(chromaAlpha);
      canvas.drawPath(_createBodyPath(radius), _highlightPaint);
      canvas.restore();

      // Blue channel offset
      canvas.save();
      canvas.translate(chromaOffset, 0);
      _highlightPaint.color = Colors.blue.withOpacity(chromaAlpha);
      canvas.drawPath(_createBodyPath(radius), _highlightPaint);
      canvas.restore();
    }

    // LAYER 9: Energy pulse core
    final pulseRadius = radius * 0.3 * flashProgress;
    _shieldCorePaint.color =
        Colors.white.withOpacity(flashProgress * 0.8 * opacity);
    canvas.drawCircle(Offset.zero, pulseRadius, _shieldCorePaint);

    _shieldGlowPaint
      ..color = type.color.withOpacity(flashProgress * 0.5 * opacity)
      ..maskFilter = _blur(allowBlur, 6);
    canvas.drawCircle(Offset.zero, pulseRadius * 1.5, _shieldGlowPaint);

    // LAYER 10: Rotating energy arcs around body
    for (int i = 0; i < 4; i++) {
      final arcAngle = _animationPhase * 3 + i * math.pi / 2;
      final arcRadius = radius * 1.15;

      _shieldRipplePaint
        ..color = (i % 2 == 0 ? type.color : const Color(0xFFFF0066))
            .withOpacity(flashProgress * 0.4 * opacity)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..maskFilter = _blur(allowBlur, 2);

      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: arcRadius),
        arcAngle,
        math.pi * 0.25,
        false,
        _shieldRipplePaint,
      );
    }
  }

  void _renderDamageParticles(Canvas canvas, bool allowBlur) {
    // Standard sparks
    for (final particle in _damageParticles) {
      if (!particle.isActive) continue;

      final px = math.cos(particle.angle) * particle.distance;
      final py = math.sin(particle.angle) * particle.distance;
      final alpha = particle.alpha;
      final shardLength = particle.size * 2.6;
      final shardWidth = particle.size * 0.7;
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(particle.angle);

      _particlePaint
        ..color = type.color.withOpacity(alpha)
        ..style = PaintingStyle.fill
        ..maskFilter = null;
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: shardLength, height: shardWidth),
        _particlePaint,
      );

      if (allowBlur) {
        _particlePaint
          ..color = type.color.withOpacity(alpha * 0.35)
          ..maskFilter = _blur(true, 2);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: shardLength * 1.4,
            height: shardWidth * 1.4,
          ),
          _particlePaint,
        );
      }
      canvas.restore();
    }

    // Data bits
    for (final bit in _dataBits) {
      if (!bit.isActive) continue;

      canvas.save();
      canvas.translate(bit.position.x, bit.position.y);
      canvas.rotate(bit.rotation);
      _particlePaint
        ..color = bit.color.withOpacity(bit.alpha)
        ..style = PaintingStyle.fill
        ..maskFilter = null;
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: bit.size, height: bit.size),
        _particlePaint,
      );

      if (allowBlur) {
        _particlePaint
          ..color = bit.color.withOpacity(bit.alpha * 0.5)
          ..maskFilter = _blur(true, 2);
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero,
              width: bit.size * 1.5,
              height: bit.size * 1.5),
          _particlePaint,
        );
      }
      canvas.restore();
    }
  }

  void _renderTrail(Canvas canvas, double opacity, bool allowBlur) {
    _renderNeonTrail(canvas, opacity, allowBlur);
  }

  /// Renders an elaborate neon trail effect with multiple layers for cyberpunk aesthetic.
  /// Uses quadratic bezier curves for smooth path connections with gradient fade.
  void _renderNeonTrail(Canvas canvas, double opacity, bool allowBlur) {
    if (_trailPositions.length < 2) return;

    // Skip trail rendering if positions are too close (enemy stationary)
    // Use circular buffer index for newest position
    final firstPhysIdx = _getTrailPhysicalIndex(0);
    final firstOffset = _trailPositions[firstPhysIdx] - position;
    if (firstOffset.length < 1.0) return;

    final reduceFx = Enemy.lowFx || Enemy.forceLowFx;
    final t = _animationTimer;

    // Get HSL color for secondary/tertiary colors
    final hslColor = HSLColor.fromColor(type.color);
    final secondaryColor =
        hslColor.withHue((hslColor.hue + 180) % 360).toColor();
    final tertiaryColor = hslColor
        .withHue((hslColor.hue + 60) % 360)
        .withSaturation((hslColor.saturation * 0.8).clamp(0.0, 1.0))
        .withLightness((hslColor.lightness * 1.2).clamp(0.0, 1.0))
        .toColor();

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: Outer glow trail (wide, blurred, faded)
    // ═══════════════════════════════════════════════════════════════════════
    _neonTrailPath.reset();
    bool pathStarted = false;

    for (int i = 0; i < _trailPositions.length; i++) {
      final physIdx = _getTrailPhysicalIndex(i);
      final offset = _trailPositions[physIdx] - position;
      if (offset.length < 0.5) continue;

      if (!pathStarted) {
        _neonTrailPath.moveTo(offset.x, offset.y);
        pathStarted = true;
      } else if (i < _trailPositions.length - 1) {
        // Use quadratic bezier for smooth curves
        final nextPhysIdx = _getTrailPhysicalIndex(i + 1);
        final nextOffset = _trailPositions[nextPhysIdx] - position;
        final midX = (offset.x + nextOffset.x) / 2;
        final midY = (offset.y + nextOffset.y) / 2;
        _neonTrailPath.quadraticBezierTo(offset.x, offset.y, midX, midY);
      } else {
        _neonTrailPath.lineTo(offset.x, offset.y);
      }
    }

    if (pathStarted) {
      // Outer glow with pulsing intensity
      final glowPulse = 0.25 + math.sin(t * 4) * 0.1;
      _neonTrailOuterGlowPaint
        ..color = type.color.withOpacity(glowPulse * opacity * 0.4)
        ..strokeWidth = size.x * 0.35
        ..maskFilter = _blur(allowBlur, 12);
      canvas.drawPath(_neonTrailPath, _neonTrailOuterGlowPaint);

      // Secondary color outer glow (offset slightly for chromatic effect)
      if (!reduceFx) {
        _neonTrailOuterGlowPaint
          ..color = secondaryColor.withOpacity(glowPulse * opacity * 0.2)
          ..strokeWidth = size.x * 0.28
          ..maskFilter = _blur(allowBlur, 8);
        canvas.save();
        canvas.translate(1.5, 0.5);
        canvas.drawPath(_neonTrailPath, _neonTrailOuterGlowPaint);
        canvas.restore();
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: Core trail line (bright, thin)
    // ═══════════════════════════════════════════════════════════════════════
    if (pathStarted) {
      _neonTrailCorePaint
        ..color = Colors.white.withOpacity(opacity * 0.8)
        ..strokeWidth = size.x * 0.06
        ..maskFilter = _blur(allowBlur, 2);
      canvas.drawPath(_neonTrailPath, _neonTrailCorePaint);

      // Inner bright core
      _neonTrailCorePaint
        ..color = type.color.withOpacity(opacity * 0.9)
        ..strokeWidth = size.x * 0.04
        ..maskFilter = null;
      canvas.drawPath(_neonTrailPath, _neonTrailCorePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: Trail segments with gradient fade based on age
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < _trailPositions.length - 1; i++) {
      final segmentT = i / _trailPositions.length;
      final fadeAlpha = (1 - segmentT) * opacity;

      final physIdx = _getTrailPhysicalIndex(i);
      final nextPhysIdx = _getTrailPhysicalIndex(i + 1);
      final offset = _trailPositions[physIdx] - position;
      final nextOffset = _trailPositions[nextPhysIdx] - position;
      if (offset.length < 0.5 || nextOffset.length < 0.5) continue;

      // Gradient color based on age (bright at head, faded at tail)
      final gradientColor = Color.lerp(type.color, tertiaryColor, segmentT)!;
      final segmentWidth = size.x * (0.12 - segmentT * 0.08);

      _neonTrailGradientPaint
        ..color = gradientColor.withOpacity(fadeAlpha * 0.6)
        ..strokeWidth = segmentWidth
        ..maskFilter = _blur(allowBlur, 3);

      canvas.drawLine(
        Offset(offset.x, offset.y),
        Offset(nextOffset.x, nextOffset.y),
        _neonTrailGradientPaint,
      );
    }

    if (reduceFx) return; // Skip detailed effects in low-fx mode

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: Energy particles along the trail (small dots)
    // ═══════════════════════════════════════════════════════════════════════
    final particleCount = 8;
    for (int i = 0; i < particleCount; i++) {
      // Distribute particles along trail with animation offset
      final particleProgress = (i / particleCount + t * 0.5) % 1.0;
      final trailIndex =
          (particleProgress * (_trailPositions.length - 1)).floor();
      if (trailIndex >= _trailPositions.length - 1) continue;

      final physIdxA = _getTrailPhysicalIndex(trailIndex);
      final physIdxB = _getTrailPhysicalIndex(trailIndex + 1);
      final posA = _trailPositions[physIdxA] - position;
      final posB = _trailPositions[physIdxB] - position;
      final lerpT =
          (particleProgress * (_trailPositions.length - 1)) - trailIndex;

      final particleX = posA.x + (posB.x - posA.x) * lerpT;
      final particleY = posA.y + (posB.y - posA.y) * lerpT;

      // Add slight wobble to particles
      final wobbleX = math.sin(t * 8 + i * 2) * 2;
      final wobbleY = math.cos(t * 8 + i * 2) * 2;

      final particleAlpha = (1 - particleProgress) * opacity * 0.8;
      final particleSize = size.x * (0.08 - particleProgress * 0.04);

      // Particle glow
      _neonTrailParticlePaint
        ..color = type.color.withOpacity(particleAlpha * 0.5)
        ..maskFilter = _blur(allowBlur, 4);
      canvas.drawCircle(
        Offset(particleX + wobbleX, particleY + wobbleY),
        particleSize * 2,
        _neonTrailParticlePaint,
      );

      // Particle core
      _neonTrailParticlePaint
        ..color = Colors.white.withOpacity(particleAlpha)
        ..maskFilter = null;
      canvas.drawCircle(
        Offset(particleX + wobbleX, particleY + wobbleY),
        particleSize,
        _neonTrailParticlePaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: Pulsing nodes at regular intervals
    // ═══════════════════════════════════════════════════════════════════════
    final nodeInterval = 4; // Every 4th position
    for (int i = 0; i < _trailPositions.length; i += nodeInterval) {
      final physIdx = _getTrailPhysicalIndex(i);
      final offset = _trailPositions[physIdx] - position;
      if (offset.length < 1.0) continue;

      final nodeT = i / _trailPositions.length;
      final nodeAlpha = (1 - nodeT) * opacity;
      final nodePulse = 1.0 + math.sin(t * 6 + i) * 0.3;
      final nodeRadius = size.x * 0.1 * nodePulse * (1 - nodeT * 0.5);

      // Node outer glow
      _neonTrailNodePaint
        ..color = secondaryColor.withOpacity(nodeAlpha * 0.4)
        ..maskFilter = _blur(allowBlur, 6);
      canvas.drawCircle(
        Offset(offset.x, offset.y),
        nodeRadius * 2.5,
        _neonTrailNodePaint,
      );

      // Node middle glow
      _neonTrailNodePaint
        ..color = type.color.withOpacity(nodeAlpha * 0.7)
        ..maskFilter = _blur(allowBlur, 3);
      canvas.drawCircle(
        Offset(offset.x, offset.y),
        nodeRadius * 1.5,
        _neonTrailNodePaint,
      );

      // Node core
      _neonTrailNodePaint
        ..color = Colors.white.withOpacity(nodeAlpha * 0.9)
        ..maskFilter = null;
      canvas.drawCircle(
        Offset(offset.x, offset.y),
        nodeRadius * 0.5,
        _neonTrailNodePaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: Scanline effect along trail
    // ═══════════════════════════════════════════════════════════════════════
    final scanlineOffset = (t * 2) % 1.0;
    final scanlineIndex =
        (scanlineOffset * (_trailPositions.length - 1)).floor();
    if (scanlineIndex < _trailPositions.length - 1) {
      final scanPhysIdxA = _getTrailPhysicalIndex(scanlineIndex);
      final scanPhysIdxB = _getTrailPhysicalIndex(scanlineIndex + 1);
      final scanPosA = _trailPositions[scanPhysIdxA] - position;
      final scanPosB = _trailPositions[scanPhysIdxB] - position;
      final scanLerp =
          (scanlineOffset * (_trailPositions.length - 1)) - scanlineIndex;

      final scanX = scanPosA.x + (scanPosB.x - scanPosA.x) * scanLerp;
      final scanY = scanPosA.y + (scanPosB.y - scanPosA.y) * scanLerp;

      // Calculate perpendicular direction for scanline
      final dx = scanPosB.x - scanPosA.x;
      final dy = scanPosB.y - scanPosA.y;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len > 0.1) {
        final perpX = -dy / len;
        final perpY = dx / len;
        final scanWidth = size.x * 0.4;

        // Scanline glow
        _neonTrailScanlinePaint
          ..color = tertiaryColor.withOpacity(opacity * 0.6)
          ..strokeWidth = 3
          ..maskFilter = _blur(allowBlur, 4);
        canvas.drawLine(
          Offset(scanX - perpX * scanWidth, scanY - perpY * scanWidth),
          Offset(scanX + perpX * scanWidth, scanY + perpY * scanWidth),
          _neonTrailScanlinePaint,
        );

        // Scanline core
        _neonTrailScanlinePaint
          ..color = Colors.white.withOpacity(opacity * 0.9)
          ..strokeWidth = 1.5
          ..maskFilter = null;
        canvas.drawLine(
          Offset(scanX - perpX * scanWidth, scanY - perpY * scanWidth),
          Offset(scanX + perpX * scanWidth, scanY + perpY * scanWidth),
          _neonTrailScanlinePaint,
        );
      }
    }
  }

  void _renderTypeEffects(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    final t = _animationTimer;

    // ═══════════════════════════════════════════════════════════════════════════
    // RENDER TERRIFYING EYES - All enemies have menacing eyes
    // ═══════════════════════════════════════════════════════════════════════════
    _renderDemonicEyes(canvas, radius, opacity, allowBlur);

    // ═══════════════════════════════════════════════════════════════════════════
    // RENDER CORRUPTION TENDRILS - Writhing appendages
    // ═══════════════════════════════════════════════════════════════════════════
    _renderCorruptionTendrils(canvas, radius, opacity, allowBlur);

    // ═══════════════════════════════════════════════════════════════════════════
    // WORLD-SPECIFIC TERROR EFFECTS
    // ═══════════════════════════════════════════════════════════════════════════
    _renderWorldTerrorEffects(canvas, radius, opacity, allowBlur, t);
  }

  void _renderDemonicEyes(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    final t = _animationTimer;
    final eyeStyle = _getEyeStyle();

    switch (eyeStyle) {
      case _EyeStyle.predator:
        // Single menacing eye that tracks and pulses
        _renderPredatorEye(canvas, radius, opacity, allowBlur, t);
        break;
      case _EyeStyle.hive:
        // Multiple small eyes like an insect
        _renderHiveEyes(canvas, radius, opacity, allowBlur, t);
        break;
      case _EyeStyle.void_:
        // Empty void sockets that draw you in
        _renderVoidEyes(canvas, radius, opacity, allowBlur, t);
        break;
      case _EyeStyle.burning:
        // Eyes of flame/plasma
        _renderBurningEyes(canvas, radius, opacity, allowBlur, t);
        break;
      case _EyeStyle.crystal:
        // Faceted crystalline eyes
        _renderCrystalEyes(canvas, radius, opacity, allowBlur, t);
        break;
      case _EyeStyle.mechanical:
        // Cold robotic sensors
        _renderMechanicalEyes(canvas, radius, opacity, allowBlur, t);
        break;
      case _EyeStyle.corrupted:
        // Glitching digital eyes
        _renderCorruptedEyes(canvas, radius, opacity, allowBlur, t);
        break;
      case _EyeStyle.abyssal:
        // Deep void eyes that seem infinite
        _renderAbyssalEyes(canvas, radius, opacity, allowBlur, t);
        break;
    }
  }

  _EyeStyle _getEyeStyle() {
    switch (type.world) {
      case 1:
        return _EyeStyle.predator;
      case 2:
        return _EyeStyle.void_;
      case 3:
        return _EyeStyle.corrupted;
      case 4:
        return _EyeStyle.burning;
      case 5:
        return _EyeStyle.crystal;
      case 6:
        return _EyeStyle.mechanical;
      case 7:
        return _EyeStyle.corrupted;
      case 8:
        return _EyeStyle.burning;
      case 9:
        return _EyeStyle.abyssal;
      case 10:
        return _EyeStyle.hive;
      default:
        return _EyeStyle.predator;
    }
  }

  void _renderPredatorEye(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // HYPER-OPTIMIZED: Static paints, precalculated values
    final r015 = radius * 0.15;
    final r01 = radius * 0.1;
    final r05 = radius * 0.5;
    final r035 = radius * 0.35;
    final r025 = radius * 0.25;
    final r02 = radius * 0.2;
    final eyeCenterX = r015;
    final eyeCenterY = -r01;
    final eyeCenter = Offset(eyeCenterX, eyeCenterY);

    // Main eye socket
    _socketPaint.color = Colors.black.withOpacity(0.8 * opacity);
    canvas.drawOval(
        Rect.fromCenter(center: eyeCenter, width: r05, height: r035),
        _socketPaint);

    // Glowing iris
    final pulse = 0.7 + 0.3 * math.sin(t * 4);
    _irisPaint
      ..color = type.color.withOpacity(0.9 * opacity * pulse)
      ..maskFilter = _blur(allowBlur, 4);
    canvas.drawOval(
        Rect.fromCenter(center: eyeCenter, width: r035, height: r025),
        _irisPaint);

    // Slit pupil
    final t2 = t * 2;
    final pupilWidth = radius * 0.06 * (0.8 + 0.4 * math.sin(t2));
    _pupilPaint.color = Colors.black.withOpacity(0.95 * opacity);
    canvas.drawOval(
        Rect.fromCenter(center: eyeCenter, width: pupilWidth, height: r02),
        _pupilPaint);

    // Evil glint
    _corePaint.color = Colors.white.withOpacity(0.8 * opacity);
    canvas.drawCircle(
        Offset(radius * 0.08, -radius * 0.18), radius * 0.04, _corePaint);

    // Blood vessel streaks
    _veinPaint
      ..color = const Color(0xFFFF0033).withOpacity(0.4 * opacity)
      ..strokeWidth = 0.8;
    for (int i = 0; i < 4; i++) {
      final angle = -math.pi / 4 + i * 0.3 + math.sin(t2 + i) * 0.1;
      final cosAngle = math.cos(angle);
      final sinAngle = math.sin(angle);
      final startX = eyeCenterX + cosAngle * r02;
      final startY = eyeCenterY + sinAngle * r015;
      final endX = startX + cosAngle * r015;
      final endY = startY + sinAngle * r01;
      _tempOffset1 = Offset(startX, startY);
      _tempOffset2 = Offset(endX, endY);
      canvas.drawLine(_tempOffset1, _tempOffset2, _veinPaint);
    }
  }

  void _renderHiveEyes(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // OPTIMIZED: Uses static _hiveEyePositions list, cached sin, reusable paints
    final t3 = t * 3;
    final baseSize = radius * 0.08;
    final sizeVar = radius * 0.02;
    final opacity07 = 0.7 * opacity;
    final opacity08 = 0.8 * opacity;
    final opacity09 = 0.9 * opacity;

    for (int i = 0; i < _hiveEyePositions.length; i++) {
      final relPos = _hiveEyePositions[i];
      _tempOffset1 = Offset(relPos.dx * radius, relPos.dy * radius);

      final phase = t3 + i * 0.5;
      final sinPhase = math.sin(phase);
      final active = sinPhase > -0.3;
      final size = baseSize + sizeVar * math.sin(phase * 2);

      // Eye socket - reuse _socketPaint
      _socketPaint.color = Colors.black.withOpacity(opacity07);
      canvas.drawCircle(_tempOffset1, size * 1.2, _socketPaint);

      if (active) {
        // Glowing eye - reuse _eyePaint
        _eyePaint
          ..color = type.color.withOpacity(opacity08)
          ..maskFilter = _blur(allowBlur, 3);
        canvas.drawCircle(_tempOffset1, size, _eyePaint);

        // Tiny pupil - reuse _pupilPaint
        _pupilPaint.color = Colors.black.withOpacity(opacity09);
        canvas.drawCircle(_tempOffset1, size * 0.3, _pupilPaint);
      }
    }
    _eyePaint.maskFilter = null;
  }

  void _renderVoidEyes(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Empty sockets that seem to go forever
    final opacityFilter = _opacityFilter(opacity);

    _voidPaint
      ..shader = _voidEyeShader1
      ..colorFilter = opacityFilter;
    canvas.drawCircle(_voidEyePos1, _voidEyeRadius, _voidPaint);

    _voidPaint
      ..shader = _voidEyeShader2
      ..colorFilter = opacityFilter;
    canvas.drawCircle(_voidEyePos2, _voidEyeRadius, _voidPaint);

    _voidPaint
      ..shader = null
      ..colorFilter = null;

    // Swirling darkness inside
    _swirlPaint
      ..color = type.color.withOpacity(0.3 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final swirlRadius = _baseRadius * 0.08;
    canvas.drawArc(
      Rect.fromCircle(center: _voidEyePos1, radius: swirlRadius),
      t * 2,
      math.pi,
      false,
      _swirlPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: _voidEyePos2, radius: swirlRadius),
      t * 2,
      math.pi,
      false,
      _swirlPaint,
    );

    // Occasional glimmer from the depths
    if (math.sin(t * 5) > 0.8) {
      _sparkPaint.color = type.color.withOpacity(0.6 * opacity);
      canvas.drawCircle(
        _voidEyePos1 +
            Offset(math.sin(t * 3) * _baseRadius * 0.03,
                math.cos(t * 3) * _baseRadius * 0.03),
        _baseRadius * 0.02,
        _sparkPaint,
      );
      canvas.drawCircle(
        _voidEyePos2 +
            Offset(math.sin(t * 3) * _baseRadius * 0.03,
                math.cos(t * 3) * _baseRadius * 0.03),
        _baseRadius * 0.02,
        _sparkPaint,
      );
    }
  }

  void _renderBurningEyes(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // OPTIMIZED: Cached calculations, reusable paints, reduced allocations
    final eyePosX = radius * 0.15;
    final eyePosY = -radius * 0.1;
    final r002 = radius * 0.02;
    final r008 = radius * 0.08;
    final r01 = radius * 0.1;

    // Precalculate trig values used multiple times
    final t10 = t * 10;
    final t12 = t * 12;
    final t8 = t * 8;
    final t6 = t * 6;

    // Flame colors: index 1 uses type.color, others are static
    // [yellow, type.color, orange-red, dark-red]

    // Flame aura around eye - unrolled loop for fewer branches
    for (int i = 3; i >= 0; i--) {
      final flameSize = radius * (0.2 + i * 0.05);
      final sinVal = math.sin(t10 + i);
      final cosVal = math.cos(t12 + i);
      final jitterX = sinVal * r002;
      final jitterY = cosVal * r002 - i * r002;

      final flameColor = i == 1 ? type.color : _flameColors[i];
      final flameOpacity = (0.3 + i * 0.15) * opacity;

      _flamePaint
        ..color = flameColor.withOpacity(flameOpacity)
        ..maskFilter = _blur(allowBlur, 4 + i * 2);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(eyePosX + jitterX, eyePosY + jitterY),
          width: flameSize * 1.5,
          height: flameSize,
        ),
        _flamePaint,
      );
    }

    // Core of the eye - white hot
    _corePaint.color = Colors.white.withOpacity(0.9 * opacity);
    canvas.drawCircle(Offset(eyePosX, eyePosY), r008, _corePaint);

    // Flame licks rising from eye - reuse static paint
    _sparkPaint
      ..color = const Color(0xFFFF6600).withOpacity(0.6 * opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final baseY = eyePosY - r01;
    for (int i = 0; i < 3; i++) {
      final x = eyePosX + (i - 1) * r008;
      final height = radius * (0.15 + 0.1 * math.sin(t8 + i * 2));
      final tipX = x + math.sin(t6 + i) * radius * 0.05;
      canvas.drawLine(
          Offset(x, baseY), Offset(tipX, baseY - height), _sparkPaint);
    }
  }

  void _renderCrystalEyes(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Faceted gem-like eyes
    final eyePos = _crystalEyePos;

    // Outer facets
    _reusableOverlayPath.reset();
    const facets = 6;
    for (int i = 0; i < facets; i++) {
      final angle = (i / facets) * math.pi * 2 + t * 0.5;
      final r = radius * 0.18;
      final x = eyePos.dx + math.cos(angle) * r;
      final y = eyePos.dy + math.sin(angle) * r;
      if (i == 0)
        _reusableOverlayPath.moveTo(x, y);
      else
        _reusableOverlayPath.lineTo(x, y);
    }
    _reusableOverlayPath.close();

    // Fill with gradient
    _crystalPaint
      ..shader = _crystalEyeShader
      ..colorFilter = _opacityFilter(opacity);
    canvas.drawPath(_reusableOverlayPath, _crystalPaint);
    _crystalPaint
      ..shader = null
      ..colorFilter = null;

    // Facet lines
    _facetPaint
      ..color = Colors.white.withOpacity(0.6 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int i = 0; i < facets; i++) {
      final angle = (i / facets) * math.pi * 2 + t * 0.5;
      canvas.drawLine(
        eyePos,
        eyePos +
            Offset(math.cos(angle) * radius * 0.15,
                math.sin(angle) * radius * 0.15),
        _facetPaint,
      );
    }

    // Central gleam
    canvas.drawCircle(
      eyePos + Offset(-radius * 0.04, -radius * 0.04),
      radius * 0.03,
      _corePaint..color = Colors.white.withOpacity(0.95 * opacity),
    );

    // Prismatic refraction
    if (allowBlur) {
      const prismColors = [
        Color(0xFFFF0000),
        Color(0xFF00FF00),
        Color(0xFF0000FF),
      ];
      for (int i = 0; i < 3; i++) {
        final angle = t * 2 + i * math.pi * 2 / 3;
        final color = prismColors[i];
        canvas.drawLine(
          eyePos,
          eyePos +
              Offset(math.cos(angle) * radius * 0.25,
                  math.sin(angle) * radius * 0.25),
          _sparkPaint
            ..color = color.withOpacity(0.2 * opacity)
            ..strokeWidth = 2
            ..maskFilter = _blur(true, 4),
        );
      }
      _sparkPaint.maskFilter = null;
    }
  }

  void _renderMechanicalEyes(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Cold robotic sensor eye
    final eyePos = Offset(radius * 0.15, -radius * 0.08);

    // Metal housing
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: eyePos, width: radius * 0.4, height: radius * 0.25),
        Radius.circular(radius * 0.04),
      ),
      _metalPaint..color = const Color(0xFF333333).withOpacity(0.9 * opacity),
    );

    // Lens
    canvas.drawCircle(
      eyePos,
      radius * 0.1,
      _socketPaint..color = Colors.black.withOpacity(0.95 * opacity),
    );

    // Scanning laser
    final scanAngle = (t * 3) % (math.pi * 2);
    _scanPaint
      ..color = const Color(0xFFFF0000).withOpacity(0.8 * opacity)
      ..strokeWidth = 2
      ..maskFilter = _blur(allowBlur, 3);
    canvas.drawLine(
      eyePos,
      eyePos +
          Offset(math.cos(scanAngle) * radius * 0.08,
              math.sin(scanAngle) * radius * 0.08),
      _scanPaint,
    );

    // LED indicators
    for (int i = 0; i < 3; i++) {
      final ledOn = ((t * 4 + i).floor() % 3) == i;
      canvas.drawCircle(
        eyePos + Offset(radius * (-0.12 + i * 0.12), radius * 0.15),
        radius * 0.02,
        _sparkPaint
          ..color = (ledOn ? type.color : const Color(0xFF333333))
              .withOpacity(0.8 * opacity),
      );
    }

    // Targeting reticle
    _reticlePaint
      ..color = type.color.withOpacity(0.5 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(eyePos, radius * 0.06, _reticlePaint);
    canvas.drawLine(eyePos + Offset(-radius * 0.1, 0),
        eyePos + Offset(-radius * 0.03, 0), _reticlePaint);
    canvas.drawLine(eyePos + Offset(radius * 0.03, 0),
        eyePos + Offset(radius * 0.1, 0), _reticlePaint);
    canvas.drawLine(eyePos + Offset(0, -radius * 0.08),
        eyePos + Offset(0, -radius * 0.03), _reticlePaint);
    canvas.drawLine(eyePos + Offset(0, radius * 0.03),
        eyePos + Offset(0, radius * 0.08), _reticlePaint);
  }

  void _renderCorruptedEyes(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Glitching digital eyes
    final eyePos = Offset(radius * 0.15, -radius * 0.1);
    final glitchOffset = Offset(
      math.sin(t * 30) > 0.8 ? (math.sin(t * 50) * radius * 0.1) : 0,
      math.cos(t * 25) > 0.8 ? (math.cos(t * 45) * radius * 0.05) : 0,
    );

    // Chromatic aberration - RGB split
    canvas.drawCircle(
      eyePos + glitchOffset + Offset(-radius * 0.02, 0),
      radius * 0.12,
      _chromaPaint
        ..color = const Color(0xFFFF0000).withOpacity(0.4 * opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = null,
    );
    canvas.drawCircle(
      eyePos + glitchOffset + Offset(radius * 0.02, 0),
      radius * 0.12,
      _chromaPaint
        ..color = const Color(0xFF00FFFF).withOpacity(0.4 * opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = null,
    );

    // Main eye with corruption
    canvas.drawCircle(
      eyePos + glitchOffset,
      radius * 0.1,
      _eyePaint
        ..color = type.color.withOpacity(0.8 * opacity)
        ..maskFilter = null,
    );

    // Glitch bars
    if (math.sin(t * 15) > 0.6) {
      _barPaint.color = type.color.withOpacity(0.6 * opacity);
      for (int i = 0; i < 3; i++) {
        final y = eyePos.dy - radius * 0.15 + i * radius * 0.1;
        final width = radius * (0.1 + _random.nextDouble() * 0.2);
        canvas.drawRect(
          Rect.fromLTWH(eyePos.dx - width / 2, y, width, radius * 0.02),
          _barPaint,
        );
      }
    }

    // Error pupil - sometimes inverted
    final inverted = math.sin(t * 8) > 0.7;
    canvas.drawCircle(
      eyePos + glitchOffset,
      radius * 0.04,
      _pupilPaint
        ..color =
            (inverted ? type.color : Colors.black).withOpacity(0.9 * opacity),
    );
  }

  void _renderAbyssalEyes(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Infinite depth void eyes
    final eyePos1 = Offset(radius * 0.18, -radius * 0.12);
    final eyePos2 = Offset(-radius * 0.12, -radius * 0.08);
    for (int e = 0; e < 2; e++) {
      final pos = e == 0 ? eyePos1 : eyePos2;

      // Concentric rings going into infinity
      for (int i = 4; i >= 0; i--) {
        final ringRadius = radius * (0.15 - i * 0.025);
        final darkness = 0.5 + i * 0.1;
        canvas.drawCircle(
          pos,
          ringRadius,
          _voidPaint
            ..color = Color.lerp(type.color, Colors.black, darkness)!
                .withOpacity(0.8 * opacity),
        );
      }

      // Swirling abyss
      _swirlPaint
        ..color = type.color.withOpacity(0.3 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (int i = 0; i < 3; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: pos, radius: radius * (0.05 + i * 0.03)),
          t * 3 + i * math.pi / 3,
          math.pi * 0.8,
          false,
          _swirlPaint,
        );
      }

      // Occasional soul escaping
      if ((t * 2 + e).floor() % 3 == 0) {
        final soulY = pos.dy - (t % 1.0) * radius * 0.3;
        canvas.drawCircle(
          Offset(pos.dx, soulY),
          radius * 0.015,
          _sparkPaint
            ..color = Colors.white.withOpacity((1 - (t % 1.0)) * 0.5 * opacity)
            ..maskFilter = _blur(allowBlur, 2),
        );
        _sparkPaint.maskFilter = null;
      }
    }
  }

  void _renderCorruptionTendrils(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    // Skip for low-fx mode
    if (Enemy.lowFx || Enemy.forceLowFx) return;

    final t = _animationTimer;
    final tendrilCount = type.world >= 5 ? 6 : 4;
    final tendrilLength = radius * (0.8 + type.world * 0.1);

    _tendrilPaint
      ..color = type.color.withOpacity(0.5 * opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < tendrilCount; i++) {
      final baseAngle = (i / tendrilCount) * math.pi * 2 + t * 0.5;
      final segments = 5;

      _reusableOverlayPath.reset();
      var currentPos = Offset.zero;
      _reusableOverlayPath.moveTo(0, 0);

      for (int s = 0; s < segments; s++) {
        final segProgress = s / segments;
        final wave =
            math.sin(t * 4 + i * 0.8 + s * 0.5) * radius * 0.15 * segProgress;
        final segLength = tendrilLength / segments;
        final angle = baseAngle + wave * 0.1;

        currentPos = currentPos +
            Offset(
              math.cos(angle) * segLength,
              math.sin(angle) * segLength + wave * 0.3,
            );
        _reusableOverlayPath.lineTo(currentPos.dx, currentPos.dy);
      }

      // Main tendril
      canvas.drawPath(_reusableOverlayPath, _tendrilPaint);

      // Glow effect
      if (allowBlur) {
        _auraPaint
          ..color = type.color.withOpacity(0.2 * opacity)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = _blur(true, 4);
        canvas.drawPath(_reusableOverlayPath, _auraPaint);
      }

      // Tendril tip - barb or claw
      canvas.save();
      canvas.translate(currentPos.dx, currentPos.dy);
      canvas.rotate(baseAngle);

      // Sharp claw
      _reusableOverlayPath.reset();
      _reusableOverlayPath.moveTo(0, -radius * 0.04);
      _reusableOverlayPath.lineTo(radius * 0.08, 0);
      _reusableOverlayPath.lineTo(0, radius * 0.04);
      _reusableOverlayPath.close();
      _corePaint.color = Colors.white.withOpacity(0.7 * opacity);
      canvas.drawPath(_reusableOverlayPath, _corePaint);
      canvas.restore();
    }
  }

  void _renderWorldTerrorEffects(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    switch (type.world) {
      case 1:
        _renderNeonTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 2:
        _renderRiftTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 3:
        _renderCorruptionTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 4:
        _renderPlasmaTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 5:
        _renderCrystalTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 6:
        _renderMechTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 7:
        _renderMatrixTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 8:
        _renderStormTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 9:
        _renderVoidTerror(canvas, radius, opacity, allowBlur, t);
        break;
      case 10:
        _renderOmegaTerror(canvas, radius, opacity, allowBlur, t);
        break;
    }
  }

  void _renderNeonTerror(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Neon blade and predator markings
    _bladePaint.color = Colors.white.withOpacity(0.8 * opacity);
    _reusableOverlayPath.reset();
    _reusableOverlayPath.moveTo(radius * 0.9, 0);
    _reusableOverlayPath.lineTo(radius * 0.4, -radius * 0.15);
    _reusableOverlayPath.lineTo(radius * 0.4, radius * 0.15);
    _reusableOverlayPath.close();
    canvas.drawPath(_reusableOverlayPath, _bladePaint);

    // War paint stripes
    _stripePaint
      ..color = type.color.withOpacity(0.6 * opacity)
      ..strokeWidth = 2;
    for (int i = 0; i < 3; i++) {
      final y = -radius * 0.3 + i * radius * 0.15;
      canvas.drawLine(
        Offset(-radius * 0.3, y),
        Offset(-radius * 0.6, y + radius * 0.1),
        _stripePaint,
      );
    }
  }

  void _renderRiftTerror(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Dimensional tears and reality fractures
    _tearPaint
      ..color = const Color(0xFFFF00FF).withOpacity(0.5 * opacity)
      ..strokeWidth = 2
      ..maskFilter = _blur(allowBlur, 4);

    // Reality cracks
    for (int i = 0; i < 4; i++) {
      final angle = t * 2 + i * math.pi / 2;
      final len = radius * (0.6 + math.sin(t * 5 + i) * 0.2);
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(angle) * len, math.sin(angle) * len),
        _tearPaint,
      );
    }

    // Dimensional portal behind
    if (allowBlur) {
      _riftPaint
        ..color = const Color(0xFF6600FF).withOpacity(0.2 * opacity)
        ..maskFilter = _blur(true, 8);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: radius * 1.5, height: radius * 0.5),
        _riftPaint,
      );
    }
  }

  void _renderCorruptionTerror(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Glitch corruption and data rot
    _corruptPaint
      ..color = const Color(0xFF00FF00).withOpacity(0.6 * opacity)
      ..maskFilter = null;

    // Corruption blocks
    for (int i = 0; i < 6; i++) {
      if (math.sin(t * 10 + i * 2) > 0.5) {
        final x = (i % 3 - 1) * radius * 0.3;
        final y = (i ~/ 3 - 0.5) * radius * 0.4;
        canvas.drawRect(
          Rect.fromLTWH(x, y, radius * 0.15, radius * 0.08),
          _corruptPaint,
        );
      }
    }

    // Error text simulation
    _errorPaint
      ..color = const Color(0xFFFF0000).withOpacity(0.4 * opacity)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..maskFilter = null;
    if (math.sin(t * 8) > 0.7) {
      for (int i = 0; i < 4; i++) {
        final y = -radius * 0.4 + i * radius * 0.2;
        canvas.drawLine(
          Offset(-radius * 0.4, y),
          Offset(-radius * 0.4 + _random.nextDouble() * radius * 0.5, y),
          _errorPaint,
        );
      }
    }
  }

  void _renderPlasmaTerror(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Electric arcs and plasma discharge
    _arcPaint
      ..color = type.color.withOpacity(0.7 * opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 5; i++) {
      if (math.sin(t * 12 + i * 1.5) > 0.4) {
        final angle = (i / 5) * math.pi * 2 + t;
        final startR = radius * 0.4;
        final endR = radius * (0.9 + _random.nextDouble() * 0.3);

        // Jagged lightning
        final start =
            Offset(math.cos(angle) * startR, math.sin(angle) * startR);
        final mid = Offset(
          math.cos(angle + 0.2) * (startR + endR) / 2 +
              _random.nextDouble() * radius * 0.2,
          math.sin(angle + 0.2) * (startR + endR) / 2 +
              _random.nextDouble() * radius * 0.2,
        );
        final end = Offset(math.cos(angle) * endR, math.sin(angle) * endR);

        canvas.drawLine(start, mid, _arcPaint);
        canvas.drawLine(mid, end, _arcPaint);

        if (allowBlur) {
          _arcPaint.maskFilter = _blur(true, 4);
          canvas.drawLine(start, mid,
              _arcPaint..color = type.color.withOpacity(0.3 * opacity));
          _arcPaint.maskFilter = null;
        }
      }
    }
  }

  void _renderCrystalTerror(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Floating crystal shards
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * math.pi * 2 + t * 0.8;
      final dist = radius * (1.0 + math.sin(t * 2 + i) * 0.15);
      final pos = Offset(math.cos(angle) * dist, math.sin(angle) * dist);
      final size = radius * (0.1 + 0.03 * math.sin(t * 3 + i));

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle + t);

      // Crystal shard
      _reusableOverlayPath.reset();
      _reusableOverlayPath.moveTo(0, -size);
      _reusableOverlayPath.lineTo(size * 0.5, 0);
      _reusableOverlayPath.lineTo(0, size);
      _reusableOverlayPath.lineTo(-size * 0.5, 0);
      _reusableOverlayPath.close();

      _shardPaint.color = type.color.withOpacity(0.6 * opacity);
      canvas.drawPath(_reusableOverlayPath, _shardPaint);

      _strokePaint
        ..color = Colors.white.withOpacity(0.4 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..maskFilter = null;
      canvas.drawPath(_reusableOverlayPath, _strokePaint);
      canvas.restore();
    }
  }

  void _renderMechTerror(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Mechanical gears and warning lights
    // Rotating gear
    canvas.save();
    canvas.rotate(t * 2);
    _gearPaint
      ..color = const Color(0xFF666666).withOpacity(0.5 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const teeth = 8;
    for (int i = 0; i < teeth; i++) {
      final angle = (i / teeth) * math.pi * 2;
      canvas.drawLine(
        Offset(math.cos(angle) * radius * 0.6, math.sin(angle) * radius * 0.6),
        Offset(
            math.cos(angle) * radius * 0.75, math.sin(angle) * radius * 0.75),
        _gearPaint,
      );
    }
    canvas.restore();

    // Warning stripes
    _warnPaint
      ..color = const Color(0xFFFFCC00)
          .withOpacity(math.sin(t * 8) > 0 ? 0.6 : 0.2 * opacity)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      final x = -radius * 0.4 + i * radius * 0.2;
      canvas.drawRect(
        Rect.fromLTWH(x, radius * 0.5, radius * 0.1, radius * 0.15),
        _warnPaint,
      );
    }
  }

  void _renderMatrixTerror(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Matrix code rain
    _codePaint
      ..color = const Color(0xFF00FF00).withOpacity(0.5 * opacity)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      final x = -radius * 0.6 + i * radius * 0.25;
      final yOffset = ((t * 3 + i * 0.4) % 2.0) * radius;
      for (int j = 0; j < 4; j++) {
        final y = -radius + yOffset + j * radius * 0.15;
        if (y > -radius && y < radius) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, radius * 0.08, radius * 0.06),
            _codePaint
              ..color = const Color(0xFF00FF00)
                  .withOpacity((0.3 + j * 0.15) * opacity),
          );
        }
      }
    }
  }

  void _renderStormTerror(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Storm clouds and lightning
    // Swirling cloud
    _windPaint
      ..color = const Color(0xFF336699).withOpacity(0.3 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = _blur(allowBlur, 4);
    for (int i = 0; i < 3; i++) {
      final cloudAngle = t * (3 + i * 0.5);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius * (0.8 + i * 0.1)),
        cloudAngle,
        math.pi * 0.6,
        false,
        _windPaint,
      );
    }

    // Lightning flash
    if (math.sin(t * 15) > 0.9) {
      _pulsePaint
        ..color = Colors.white.withOpacity(0.3 * opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = _blur(allowBlur, 10);
      canvas.drawCircle(
        Offset.zero,
        radius * 1.2,
        _pulsePaint,
      );
    }
  }

  void _renderVoidTerror(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Consuming darkness and soul drain
    // Darkness tendrils reaching inward
    _voidPaint
      ..color = type.color.withOpacity(0.4 * opacity)
      ..maskFilter = _blur(allowBlur, 3);
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 + t * 0.3;
      final startR = radius * 1.3;
      final endR = radius * 0.3;
      final progress = (math.sin(t * 2 + i) + 1) / 2;
      final currentR = startR - (startR - endR) * progress;

      canvas.drawCircle(
        Offset(math.cos(angle) * currentR, math.sin(angle) * currentR),
        radius * 0.05,
        _voidPaint,
      );
    }
    _voidPaint.maskFilter = null;

    // Central void
    _shadowPaint
      ..color = Colors.black.withOpacity(0.7 * opacity)
      ..maskFilter = _blur(allowBlur, 5);
    canvas.drawCircle(
      Offset.zero,
      radius * 0.25,
      _shadowPaint,
    );
    _shadowPaint.maskFilter = null;
  }

  void _renderOmegaTerror(
      Canvas canvas, double radius, double opacity, bool allowBlur, double t) {
    // Ultimate terror - all effects combined
    // Omega symbol aura
    _omegaPaint
      ..color = type.color.withOpacity(0.6 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = _blur(allowBlur, 4);

    // Rotating energy rings
    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.rotate(t * (2 + i) * (i.isEven ? 1 : -1));
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero,
            width: radius * (1.2 + i * 0.15),
            height: radius * (0.6 + i * 0.1)),
        _omegaPaint,
      );
      canvas.restore();
    }

    // Reality distortion waves
    _pulsePaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..maskFilter = null;
    for (int i = 0; i < 4; i++) {
      final waveR = radius * (0.8 + ((t * 2 + i * 0.5) % 1.0) * 0.5);
      _pulsePaint.color = type.color
          .withOpacity((1 - ((t * 2 + i * 0.5) % 1.0)) * 0.3 * opacity);
      canvas.drawCircle(
        Offset.zero,
        waveR,
        _pulsePaint,
      );
    }

    // Apocalyptic flames at top
    for (int i = 0; i < 5; i++) {
      final flameX = (i - 2) * radius * 0.2;
      final flameH = radius * (0.3 + math.sin(t * 8 + i) * 0.1);
      _flamePaint
        ..color = const Color(0xFFFF3300).withOpacity(0.5 * opacity)
        ..maskFilter = _blur(allowBlur, 4);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(flameX, -radius * 0.7 - flameH / 2),
          width: radius * 0.12,
          height: flameH,
        ),
        _flamePaint,
      );
    }
  }

  /// Renders pulsing energy veins across the enemy body
  /// Creates a cyberpunk aesthetic with glowing vein network
  void _renderEnergyVeins(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    // HYPER-OPTIMIZED: Precalculated values, reuse static paints
    final t = _animationTimer;
    final walkT = _walkPhase;
    final veinColor = type.color;

    // Heartbeat timing - faster when damaged
    final heartbeatSpeed = 2.0 + (1.0 - healthPercent) * 3.0;
    final heartbeat = math.sin(t * heartbeatSpeed * math.pi);
    final heartbeatIntensity = (heartbeat * 0.5 + 0.5).clamp(0.0, 1.0);

    // Movement-based pulse (veins pulse with walking)
    final movementPulse = math.sin(walkT * 2) * 0.3 + 0.7;

    // Combined intensity
    final baseIntensity =
        (heartbeatIntensity * 0.6 + movementPulse * 0.4) * opacity;

    // Precalculate common radius multipliers
    final r02 = radius * 0.2;
    final r03 = radius * 0.3;
    final r04 = radius * 0.4;
    final r05 = radius * 0.5;
    final r06 = radius * 0.6;
    final r07 = radius * 0.7;
    final r08 = radius * 0.8;

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: Vein glow effect (blurred behind main lines) - Render first
    // ═══════════════════════════════════════════════════════════════════════
    _energyVeinGlowPaint
      ..color = veinColor.withOpacity(0.25 * baseIntensity)
      ..strokeWidth = 4.0
      ..maskFilter = _blur(allowBlur, 6);

    // Main vein branches with glow
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 + t * 0.3;
      final pulseOffset = math.sin(t * 3 + i * 0.8) * 0.1;
      final branchLength = r06 + pulseOffset * radius;

      final cosAngle = math.cos(angle);
      final sinAngle = math.sin(angle);

      // Glow layer
      _tempOffset1 = Offset(cosAngle * r02, sinAngle * r02);
      _tempOffset2 = Offset(cosAngle * branchLength, sinAngle * branchLength);
      canvas.drawLine(_tempOffset1, _tempOffset2, _energyVeinGlowPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: Main vein network (branching lines from center outward)
    // ═══════════════════════════════════════════════════════════════════════
    _energyVeinCorePaint
      ..color = veinColor.withOpacity(0.7 * baseIntensity)
      ..strokeWidth = 1.5;

    // Primary veins (6 main branches)
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 + t * 0.3;
      final pulseOffset = math.sin(t * 3 + i * 0.8) * 0.1;
      final branchLength = r06 + pulseOffset * radius;

      final cosAngle = math.cos(angle);
      final sinAngle = math.sin(angle);

      // Main vein line
      _tempOffset1 = Offset(cosAngle * r02, sinAngle * r02);
      _tempOffset2 = Offset(cosAngle * branchLength, sinAngle * branchLength);
      canvas.drawLine(_tempOffset1, _tempOffset2, _energyVeinCorePaint);

      // Secondary branches off main veins
      final branchAngle1 = angle + 0.4;
      final branchAngle2 = angle - 0.4;
      final midPoint = r04;

      _tempOffset1 = Offset(cosAngle * midPoint, sinAngle * midPoint);
      _tempOffset2 = Offset(
        math.cos(branchAngle1) * r05,
        math.sin(branchAngle1) * r05,
      );
      canvas.drawLine(_tempOffset1, _tempOffset2, _energyVeinCorePaint);

      _tempOffset2 = Offset(
        math.cos(branchAngle2) * r05,
        math.sin(branchAngle2) * r05,
      );
      canvas.drawLine(_tempOffset1, _tempOffset2, _energyVeinCorePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: Vein intersection nodes (brighter spots at junctions)
    // ═══════════════════════════════════════════════════════════════════════
    _energyVeinNodePaint
      ..color = veinColor.withOpacity(0.9 * baseIntensity)
      ..maskFilter = _blur(allowBlur, 3);

    // Center node (heart)
    final centerPulse = 1.0 + heartbeatIntensity * 0.3;
    canvas.drawCircle(
        Offset.zero, r02 * 0.4 * centerPulse, _energyVeinNodePaint);

    // Junction nodes at branch points
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 + t * 0.3;
      final nodePulse = math.sin(t * 4 + i * 1.2) * 0.2 + 0.8;

      // Main junction
      _tempOffset1 = Offset(math.cos(angle) * r04, math.sin(angle) * r04);
      canvas.drawCircle(_tempOffset1, 2.0 * nodePulse, _energyVeinNodePaint);

      // End node
      final endDist = r06 + math.sin(t * 3 + i * 0.8) * 0.1 * radius;
      _tempOffset2 =
          Offset(math.cos(angle) * endDist, math.sin(angle) * endDist);
      canvas.drawCircle(_tempOffset2, 1.5 * nodePulse, _energyVeinNodePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: Pulsing energy flow along veins (traveling dots)
    // ═══════════════════════════════════════════════════════════════════════
    _energyVeinDotPaint
      ..color = Colors.white.withOpacity(0.85 * baseIntensity)
      ..maskFilter = _blur(allowBlur, 2);

    // Energy dots traveling along each main vein
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 + t * 0.3;
      final cosAngle = math.cos(angle);
      final sinAngle = math.sin(angle);

      // Multiple dots per vein at different phases
      for (int j = 0; j < 2; j++) {
        // Dot travels from center outward cyclically
        final travelPhase = ((t * 2.5 + i * 0.4 + j * 0.5) % 1.0);
        final dotDist = r02 + travelPhase * r04;

        // Fade in/out at ends
        final dotOpacity = math.sin(travelPhase * math.pi);
        if (dotOpacity > 0.1) {
          _energyVeinDotPaint.color =
              Colors.white.withOpacity(0.85 * baseIntensity * dotOpacity);
          _tempOffset1 = Offset(cosAngle * dotDist, sinAngle * dotDist);
          canvas.drawCircle(_tempOffset1, 1.5, _energyVeinDotPaint);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: Secondary micro-veins between main veins
    // ═══════════════════════════════════════════════════════════════════════
    _energyVeinMicroPaint
      ..color = veinColor.withOpacity(0.35 * baseIntensity)
      ..strokeWidth = 0.8;

    // Thin connecting veins between main branches
    for (int i = 0; i < 6; i++) {
      final angle1 = (i / 6) * math.pi * 2 + t * 0.3;
      final angle2 = ((i + 1) / 6) * math.pi * 2 + t * 0.3;

      // Arc at mid-radius connecting adjacent veins
      final midAngle = (angle1 + angle2) / 2;
      final arcPulse = math.sin(t * 5 + i * 0.7) * 0.1 + 0.9;
      final arcRadius = r04 * arcPulse;

      _tempOffset1 = Offset(math.cos(angle1) * r03, math.sin(angle1) * r03);
      _tempOffset2 = Offset(
          math.cos(midAngle) * arcRadius, math.sin(midAngle) * arcRadius);
      _tempOffset3 = Offset(math.cos(angle2) * r03, math.sin(angle2) * r03);

      // Draw as two line segments forming an arc approximation
      canvas.drawLine(_tempOffset1, _tempOffset2, _energyVeinMicroPaint);
      canvas.drawLine(_tempOffset2, _tempOffset3, _energyVeinMicroPaint);

      // Inner ring micro-veins
      final innerAngle = midAngle + math.pi / 12;
      _tempOffset1 =
          Offset(math.cos(innerAngle) * r02, math.sin(innerAngle) * r02);
      _tempOffset2 =
          Offset(math.cos(innerAngle) * r03, math.sin(innerAngle) * r03);
      canvas.drawLine(_tempOffset1, _tempOffset2, _energyVeinMicroPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: Heartbeat pulse effect (periodic bright flash from center)
    // ═══════════════════════════════════════════════════════════════════════
    // Only render on strong heartbeat pulses
    if (heartbeatIntensity > 0.7) {
      final pulseExpand =
          (heartbeatIntensity - 0.7) / 0.3; // 0 to 1 during pulse
      final pulseRadius = r02 + pulseExpand * r06;
      final pulseOpacity = (1.0 - pulseExpand) * 0.4 * opacity;

      _energyVeinHeartbeatPaint
        ..color = veinColor.withOpacity(pulseOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1.0 - pulseExpand * 0.5)
        ..maskFilter = _blur(allowBlur, 4);

      canvas.drawCircle(Offset.zero, pulseRadius, _energyVeinHeartbeatPaint);

      // Inner bright flash
      if (pulseExpand < 0.3) {
        _energyVeinHeartbeatPaint
          ..color = Colors.white
              .withOpacity(0.6 * opacity * (1.0 - pulseExpand / 0.3))
          ..style = PaintingStyle.fill
          ..maskFilter = _blur(allowBlur, 6);
        canvas.drawCircle(Offset.zero, r02 * 0.5 * (1.0 - pulseExpand),
            _energyVeinHeartbeatPaint);
      }
    }
  }

  void _renderCorruptionAura(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    final corruption = ((1 - healthPercent) * 0.7 +
            threatTier * 0.08 +
            (isPhantom ? 0.2 : 0.0))
        .clamp(0.2, 1.0);
    final pulse = 0.6 + math.sin(_animationTimer * 8) * 0.2;
    final intensity = (corruption * pulse).clamp(0.2, 1.0);
    final auraColor = Color.lerp(
        type.color, const Color(0xFFFF005A), 0.45 + corruption * 0.3)!;

    _bracePaint
      ..color = auraColor.withOpacity(0.28 * opacity * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.square
      ..maskFilter = _blur(allowBlur, 3);
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 + _animationTimer * 0.4;
      final dist = radius * (1.1 + i * 0.03);
      final x = math.cos(angle) * dist;
      final y = math.sin(angle) * dist;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawLine(
        Offset(-radius * 0.12, 0),
        Offset(radius * 0.12, 0),
        _bracePaint,
      );
      canvas.restore();
    }

    final spikeCount = 6 + (corruption * 6).round();
    _spikePaint
      ..color = auraColor.withOpacity(0.35 * opacity * intensity)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke
      ..maskFilter = null;
    for (int i = 0; i < spikeCount; i++) {
      final angle = (i / spikeCount) * math.pi * 2 + _animationTimer * 0.7;
      final inner = radius * 1.02;
      final outer = radius * (1.25 + 0.15 * math.sin(_animationTimer * 5 + i));
      canvas.drawLine(
        Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        _spikePaint,
      );
    }
  }

  void _renderGlitchOverlay(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    final rand = _visualRandom;
    final hpFactor = 1 - healthPercent;
    final baseIntensity =
        (0.45 + hpFactor * 0.75 + threatTier * 0.1 + (isPhantom ? 0.25 : 0.0))
            .clamp(0.4, 1.0);
    final pulse = (math.sin(_animationTimer * 12) + 1) / 2;
    final intensity = (baseIntensity * (0.7 + pulse * 0.6)).clamp(0.3, 1.0);
    final trigger = rand.nextDouble() < (0.35 + baseIntensity * 0.4);
    if (!trigger) return;

    final glitchColor = Color.lerp(type.color, const Color(0xFFFF004C), 0.6)!;
    final scanColor = Color.lerp(type.color, const Color(0xFF33CCFF), 0.55)!;

    final bodyPath = _createBodyPath(radius);
    final offset = (math.sin(_animationTimer * 20) * 0.6 +
            (rand.nextDouble() - 0.5) * 0.5) *
        intensity;

    _chromaPaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..maskFilter = allowBlur ? _blur(true, 2) : null
      ..color = const Color(0xFFFF3355).withOpacity(0.25 * opacity * intensity);

    canvas.save();
    canvas.translate(-offset, 0);
    canvas.drawPath(bodyPath, _chromaPaint);
    canvas.restore();
    canvas.save();
    canvas.translate(offset, 0);
    _chromaPaint.color =
        const Color(0xFF33CCFF).withOpacity(0.22 * opacity * intensity);
    canvas.drawPath(bodyPath, _chromaPaint);
    canvas.restore();
    _chromaPaint
      ..style = PaintingStyle.fill
      ..maskFilter = null;

    canvas.save();
    canvas.clipPath(bodyPath);

    _slicePaint
      ..color = glitchColor.withOpacity(0.18 * opacity * intensity)
      ..style = PaintingStyle.fill
      ..maskFilter = allowBlur ? _blur(true, 2) : null;
    _scanPaint
      ..color = scanColor.withOpacity(0.12 * opacity * intensity)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..maskFilter = null;
    final sliceCount = 3 + (baseIntensity * 3).round();
    for (int i = 0; i < sliceCount; i++) {
      final sliceH = radius * (0.08 + rand.nextDouble() * 0.14);
      final y = (rand.nextDouble() - 0.5) * radius * 1.6;
      final xShift = (rand.nextDouble() - 0.5) * radius * 0.35 * intensity;
      canvas.drawRect(
        Rect.fromLTWH(-radius * 1.4 + xShift, y, radius * 2.8, sliceH),
        _slicePaint,
      );
    }

    final tearCount = 1 + (baseIntensity * 1.5).round();
    for (int i = 0; i < tearCount; i++) {
      final tearH = radius * (0.1 + rand.nextDouble() * 0.2);
      final tearY = (rand.nextDouble() - 0.5) * radius * 1.4;
      final tearOffset = (rand.nextDouble() - 0.5) * radius * 0.3 * intensity;
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(-radius * 1.4, tearY, radius * 2.8, tearH));
      canvas.translate(tearOffset, 0);
      _auraPaint
        ..color = glitchColor.withOpacity(0.22 * opacity * intensity)
        ..style = PaintingStyle.fill
        ..maskFilter = _blur(allowBlur, 2);
      canvas.drawPath(bodyPath, _auraPaint);
      canvas.restore();
    }

    for (int i = 0; i < 4; i++) {
      final y = -radius + (radius * 2) * ((pulse * 0.6 + i / 4) % 1.0);
      canvas.drawLine(
          Offset(-radius * 1.2, y), Offset(radius * 1.2, y), _scanPaint);
    }
    canvas.restore();

    _shardPaint.color = glitchColor.withOpacity(0.5 * opacity * intensity);
    for (int i = 0; i < 4; i++) {
      final bx = (rand.nextDouble() - 0.5) * radius * 2.4;
      final by = (rand.nextDouble() - 0.5) * radius * 2.4;
      final w = 2 + rand.nextDouble() * 3;
      canvas.drawRect(Rect.fromLTWH(bx, by, w, 1.5), _shardPaint);
    }
    _slicePaint.maskFilter = null;
  }

  void _applyWorldVisuals(Canvas canvas) {
    canvas.save();

    final t = _animationTimer;

    switch (worldIndex) {
      case 2: // Rift Wars - Glitch style
        final pulse = math.sin(t * 8 + _circuitSeed * 12);
        if (pulse > 0.6) {
          final shiftX = math.sin(t * 21 + _circuitSeed * 9) * 2.2;
          final shiftY = math.cos(t * 17 + _circuitSeed * 5) * 1.4;
          canvas.translate(shiftX, shiftY);
        }
        break;
      case 3: // Signal Wastes - Noise/Static
        if (math.sin(t * 20 + _circuitSeed * 2) > 0.8) {
          canvas.skew(0.05 * math.sin(t * 30 + _circuitSeed * 3), 0);
        }
        break;
      case 4: // Ion Crown - Arc/Electrical jitter
        final jitter = math.sin(t * 40 + _circuitSeed * 4) * 0.8;
        canvas.translate(jitter, jitter);
        break;
      case 5: // Shard Vault - Sharp Jumps
        if ((t * 2).toInt() % 2 == 0) {
          canvas.scale(1.02);
        }
        break;
      default:
        // Neon Frontier - Standard
        break;
    }
  }

  void _drawInternalCircuitry(Canvas canvas, double radius, double opacity) {
    if (Enemy.lowFx || Enemy.forceLowFx) return;

    _circuitPaint
      ..color = type.color.withOpacity(0.2 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final pulse = 0.5 + math.sin(_animationTimer * 3) * 0.5;
    _circuitPaint.color =
        _circuitPaint.color.withOpacity(0.1 * opacity + 0.15 * pulse * opacity);
    _particlePaint
      ..color = _circuitPaint.color
      ..style = PaintingStyle.fill;

    for (final segment in _circuitSegments) {
      final start =
          Offset(segment.start.dx * radius, segment.start.dy * radius);
      final end = Offset(segment.end.dx * radius, segment.end.dy * radius);
      canvas.drawLine(start, end, _circuitPaint);
      const dotSize = 1.6;
      canvas.drawRect(
        Rect.fromCenter(center: start, width: dotSize, height: dotSize),
        _particlePaint,
      );
    }
  }

  Path _createBodyPath(double radius) {
    // Reuse static path to avoid allocations
    _reusableBodyPath.reset();

    // Use cached shape (already computed in constructor)
    final shape = _cachedBodyShape;

    switch (shape) {
      case _BodyShape.dart:
        // Aerodynamic dart hull (runners, fast types)
        _reusableBodyPath.moveTo(radius * 1.05, 0);
        _reusableBodyPath.lineTo(radius * 0.3, -radius * 0.65);
        _reusableBodyPath.lineTo(-radius * 0.45, -radius * 0.45);
        _reusableBodyPath.lineTo(-radius * 0.85, 0);
        _reusableBodyPath.lineTo(-radius * 0.45, radius * 0.45);
        _reusableBodyPath.lineTo(radius * 0.3, radius * 0.65);
        break;

      case _BodyShape.fractured:
        // Fractured polygon (overloaded, glitchy types)
        final shift = math.sin(_animationTimer * 6) * radius * 0.12;
        final glitch = math.cos(_animationTimer * 4) * radius * 0.08;
        _reusableBodyPath.moveTo(radius * 0.8 + shift, -radius * 0.15);
        _reusableBodyPath.lineTo(radius * 0.2, -radius * 0.85);
        _reusableBodyPath.lineTo(-radius * 0.6, -radius * 0.55 + glitch);
        _reusableBodyPath.lineTo(-radius * 0.9, 0);
        _reusableBodyPath.lineTo(-radius * 0.5, radius * 0.7);
        _reusableBodyPath.lineTo(radius * 0.25, radius * 0.55 - shift);
        _reusableBodyPath.lineTo(radius * 0.9 + glitch, radius * 0.12);
        break;

      case _BodyShape.armored:
        // Beveled armored hull (tanks, heavy types)
        final inset = radius * 0.35;
        _reusableBodyPath.moveTo(radius, -inset);
        _reusableBodyPath.lineTo(radius * 0.65, -radius);
        _reusableBodyPath.lineTo(-radius * 0.65, -radius);
        _reusableBodyPath.lineTo(-radius, -inset);
        _reusableBodyPath.lineTo(-radius, inset);
        _reusableBodyPath.lineTo(-radius * 0.65, radius);
        _reusableBodyPath.lineTo(radius * 0.65, radius);
        _reusableBodyPath.lineTo(radius, inset);
        break;

      case _BodyShape.star:
        // Phase-shifted star (phantom, spectral types)
        const points = 6;
        for (int i = 0; i < points * 2; i++) {
          final wobble = math.sin(_animationTimer * 3 + i) * radius * 0.06;
          final r = i.isEven ? radius * 0.9 + wobble : radius * 0.55 + wobble;
          final angle = i * math.pi / points + _animationTimer * 1.6;
          final x = math.cos(angle) * r;
          final y = math.sin(angle) * r;
          if (i == 0)
            _reusableBodyPath.moveTo(x, y);
          else
            _reusableBodyPath.lineTo(x, y);
        }
        break;

      case _BodyShape.hexagon:
        // Hexagonal (crystal, gem types)
        for (int i = 0; i < 6; i++) {
          final angle = (i / 6) * math.pi * 2 - math.pi / 6;
          final pulse = 1.0 + math.sin(_animationTimer * 2 + i) * 0.05;
          final x = math.cos(angle) * radius * pulse;
          final y = math.sin(angle) * radius * pulse;
          if (i == 0)
            _reusableBodyPath.moveTo(x, y);
          else
            _reusableBodyPath.lineTo(x, y);
        }
        break;

      case _BodyShape.mechanical:
        // Mechanical box (robots, mechs)
        final pulse = math.sin(_animationTimer * 4) * radius * 0.03;
        _reusableBodyPath.moveTo(radius * 0.9 + pulse, -radius * 0.5);
        _reusableBodyPath.lineTo(radius * 0.5, -radius * 0.9);
        _reusableBodyPath.lineTo(-radius * 0.5, -radius * 0.9);
        _reusableBodyPath.lineTo(-radius * 0.9 - pulse, -radius * 0.5);
        _reusableBodyPath.lineTo(-radius * 0.9 - pulse, radius * 0.5);
        _reusableBodyPath.lineTo(-radius * 0.5, radius * 0.9);
        _reusableBodyPath.lineTo(radius * 0.5, radius * 0.9);
        _reusableBodyPath.lineTo(radius * 0.9 + pulse, radius * 0.5);
        break;

      case _BodyShape.electric:
        // Spiky electric (plasma, electric types)
        const spikes = 8;
        for (int i = 0; i < spikes * 2; i++) {
          final angle = (i / (spikes * 2)) * math.pi * 2;
          final jitter =
              math.sin(_animationTimer * 12 + i * 0.5) * radius * 0.08;
          final r = i.isEven ? radius * 0.95 + jitter : radius * 0.6;
          final x = math.cos(angle) * r;
          final y = math.sin(angle) * r;
          if (i == 0)
            _reusableBodyPath.moveTo(x, y);
          else
            _reusableBodyPath.lineTo(x, y);
        }
        break;

      case _BodyShape.storm:
        // Swirling storm shape
        const spiralPoints = 12;
        for (int i = 0; i < spiralPoints; i++) {
          final angle = (i / spiralPoints) * math.pi * 2 + _animationTimer * 2;
          final wobble = math.sin(_animationTimer * 4 + i) * radius * 0.1;
          final r = radius * (0.7 + (i % 2) * 0.25) + wobble;
          final x = math.cos(angle) * r;
          final y = math.sin(angle) * r;
          if (i == 0)
            _reusableBodyPath.moveTo(x, y);
          else
            _reusableBodyPath.lineTo(x, y);
        }
        break;

      case _BodyShape.void_:
        // Void/abyss - irregular dark shape
        const voidPoints = 7;
        for (int i = 0; i < voidPoints; i++) {
          final angle = (i / voidPoints) * math.pi * 2;
          final pulse =
              math.sin(_animationTimer * 1.5 + i * 0.8) * radius * 0.15;
          final r = radius * (0.75 + (i % 2) * 0.2) + pulse;
          final x = math.cos(angle) * r;
          final y = math.sin(angle) * r;
          if (i == 0)
            _reusableBodyPath.moveTo(x, y);
          else
            _reusableBodyPath.lineTo(x, y);
        }
        break;

      case _BodyShape.omega:
        // Ultimate omega shape - complex polygon
        const omegaPoints = 10;
        for (int i = 0; i < omegaPoints; i++) {
          final angle = (i / omegaPoints) * math.pi * 2;
          final layer = (i % 3 == 0)
              ? 1.0
              : (i % 3 == 1)
                  ? 0.8
                  : 0.9;
          final pulse = math.sin(_animationTimer * 3 + i) * radius * 0.08;
          final r = radius * layer + pulse;
          final x = math.cos(angle) * r;
          final y = math.sin(angle) * r;
          if (i == 0)
            _reusableBodyPath.moveTo(x, y);
          else
            _reusableBodyPath.lineTo(x, y);
        }
        break;
    }
    _reusableBodyPath.close();
    return _reusableBodyPath;
  }

  _BodyShape _getBodyShape() {
    switch (type) {
      // Fast/agile types - dart shape
      case EnemyType.runner:
      case EnemyType.voidling:
      case EnemyType.dataWorm:
      case EnemyType.ionSurge:
      case EnemyType.droneSwarm:
      case EnemyType.stormRunner:
      case EnemyType.lightningWraith:
      case EnemyType.shadowSwarm:
        return _BodyShape.dart;

      // Glitchy/fractured types
      case EnemyType.overloaded:
      case EnemyType.glitcher:
      case EnemyType.corruptedByte:
      case EnemyType.malware:
      case EnemyType.codeFragment:
        return _BodyShape.fractured;

      // Heavy/tank types - armored shape
      case EnemyType.juggernaut:
      case EnemyType.dimensionBreaker:
      case EnemyType.virusCarrier:
      case EnemyType.thunderHulk:
      case EnemyType.diamondGolem:
      case EnemyType.siegeWalker:
      case EnemyType.firewallBreaker:
      case EnemyType.thunderTitan:
      case EnemyType.darknessTitan:
      case EnemyType.omegaSentinel:
      case EnemyType.apocalypseHerald:
        return _BodyShape.armored;

      // Phantom/spectral types - star shape
      case EnemyType.phantom:
      case EnemyType.riftwalker:
      case EnemyType.prismWalker:
      case EnemyType.cloakedAssassin:
      case EnemyType.systemGhost:
      case EnemyType.cycloneSpirit:
      case EnemyType.voidStalker:
      case EnemyType.realityShifter:
        return _BodyShape.star;

      // Crystal types - hexagon
      case EnemyType.crystalShard:
      case EnemyType.gemCarrier:
        return _BodyShape.hexagon;

      // Mechanical types
      case EnemyType.sentryBot:
      case EnemyType.matrixAgent:
        return _BodyShape.mechanical;

      // Electric types
      case EnemyType.sparkDrone:
      case EnemyType.plasmaCore:
        return _BodyShape.electric;

      // Storm types
      case EnemyType.abyssWalker:
        return _BodyShape.storm;

      // Void types
      case EnemyType.nexusHunter:
        return _BodyShape.void_;
    }
  }

  void _renderThreatCrown(
    Canvas canvas,
    double radius,
    double opacity,
    bool allowBlur,
    bool reduceFx,
  ) {
    final color = _threatColor;
    final spikeCount = 6 + threatTier * 2;
    final innerRadius = radius * (1.05 + threatTier * 0.06);
    final outerRadius = innerRadius + radius * (0.22 + threatTier * 0.05);
    final pointCount = spikeCount * 2;

    _reusableCrownPath.reset();
    for (int i = 0; i < pointCount; i++) {
      final angle = (i / pointCount) * math.pi * 2;
      final r = (i % 2 == 0) ? outerRadius : innerRadius;
      final x = math.cos(angle) * r;
      final y = math.sin(angle) * r;
      if (i == 0) {
        _reusableCrownPath.moveTo(x, y);
      } else {
        _reusableCrownPath.lineTo(x, y);
      }
    }
    _reusableCrownPath.close();

    _fillPaint
      ..color = color.withOpacity((reduceFx ? 0.3 : 0.45) * opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = null;
    _strokePaint
      ..color = color.withOpacity(0.7 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = reduceFx ? 1.0 : 1.6
      ..maskFilter = _blur(allowBlur, reduceFx ? 2 : 4);

    canvas.drawPath(_reusableCrownPath, _fillPaint);
    canvas.drawPath(_reusableCrownPath, _strokePaint);
    _strokePaint.maskFilter = null;

    if (threatTier >= 2) {
      final eyeRadius = radius * (0.12 + threatTier * 0.03);
      _eyePaint
        ..color = color.withOpacity(0.9 * opacity)
        ..maskFilter = _blur(allowBlur, 4);
      _reusableOverlayPath.reset();
      _reusableOverlayPath.moveTo(0, -eyeRadius);
      _reusableOverlayPath.lineTo(eyeRadius, 0);
      _reusableOverlayPath.lineTo(0, eyeRadius);
      _reusableOverlayPath.lineTo(-eyeRadius, 0);
      _reusableOverlayPath.close();
      canvas.drawPath(_reusableOverlayPath, _eyePaint);
      _eyePaint.maskFilter = null;
    }

    if (!reduceFx && threatTier >= 3) {
      _arcPaint
        ..color = color.withOpacity(0.4 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..maskFilter = _blur(allowBlur, 3);
      final arcRadius = outerRadius + radius * 0.12;
      for (int i = 0; i < 3; i++) {
        final start = _animationPhase * 0.6 + i * (math.pi * 2 / 3);
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: arcRadius),
          start,
          math.pi / 3,
          false,
          _arcPaint,
        );
      }
      _arcPaint.maskFilter = null;
    }
  }

  void _renderSlowEffect(Canvas canvas, double radius, bool allowBlur) {
    _slowPaint
      ..color = const Color(0xFF00FFFF).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = _blur(allowBlur, 3);

    // Rotating ice crystals
    for (int i = 0; i < 6; i++) {
      final angle = _animationPhase * 0.5 + i * math.pi / 3;
      final x1 = math.cos(angle) * radius * 0.9;
      final y1 = math.sin(angle) * radius * 0.9;
      final x2 = math.cos(angle) * radius * 1.3;
      final y2 = math.sin(angle) * radius * 1.3;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), _slowPaint);
    }

    // Cold aura
    _slowAuraPaint
      ..color = const Color(0xFF00FFFF).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = _blur(allowBlur, 8);
    final chillSize = radius * 1.2;
    _reusableOverlayPath.reset();
    _reusableOverlayPath.moveTo(0, -chillSize);
    _reusableOverlayPath.lineTo(chillSize, 0);
    _reusableOverlayPath.lineTo(0, chillSize);
    _reusableOverlayPath.lineTo(-chillSize, 0);
    _reusableOverlayPath.close();
    canvas.drawPath(_reusableOverlayPath, _slowAuraPaint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHTNING CHAIN CONNECTIONS BETWEEN NEARBY ENEMIES
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderLightningChains(Canvas canvas, double opacity) {
    // Safely check if game reference is available
    if (!isMounted) return;

    final game = _cachedGame ?? findGame();
    if (game is! BoredGamesGame) return;
    _cachedGame = game;
    final enemies = game.enemyManager.activeEnemies;

    // Get this enemy's index to only draw chains to enemies with higher index
    // This prevents drawing the same chain twice
    var myIndex = activeIndex;
    if (myIndex < 0 ||
        myIndex >= enemies.length ||
        !identical(enemies[myIndex], this)) {
      return;
    }

    final myCenter = position;
    final animPhase = _animationPhase;

    // Determine chain intensity based on health and type
    final healthFactor = 1.0 - healthPercent; // More chains when damaged
    final typeBonus = _isElectricType ? 0.6 : 0.0;
    final chainIntensity = (healthFactor * 0.5 + typeBonus).clamp(0.0, 1.0);

    // Skip if no chain intensity
    if (chainIntensity < 0.1) return;

    // Electric chain colors
    final chainColor = _chainColor;
    final secondaryColor = _chainSecondaryColor;
    final minDistance = _lightningChainMinDistance;
    final maxDistance = _lightningChainMaxDistance;
    final minDistanceSq = minDistance * minDistance;
    final maxDistanceSq = maxDistance * maxDistance;

    final candidates = _lightningCandidates;
    game.enemyManager.queryEnemiesInRange(myCenter, maxDistance, candidates);

    for (int i = 0; i < candidates.length; i++) {
      final otherEnemy = candidates[i];
      if (identical(otherEnemy, this)) continue;
      final otherIndex = otherEnemy.activeIndex;
      if (otherIndex < 0 || otherIndex <= myIndex) continue;
      final otherCenter = otherEnemy.position;
      final dx = otherCenter.x - myCenter.x;
      final dy = otherCenter.y - myCenter.y;
      final distanceSq = (dx * dx) + (dy * dy);

      // Check if within chain range
      if (distanceSq < minDistanceSq || distanceSq > maxDistanceSq) continue;
      final distance = math.sqrt(distanceSq);
      if (distance <= 0) continue;
      final invDistance = 1.0 / distance;
      final dirX = dx * invDistance;
      final dirY = dy * invDistance;
      final perpX = -dirY;
      final perpY = dirX;

      // Calculate combined chain probability
      final otherHealthFactor = 1.0 - otherEnemy.healthPercent;
      final otherTypeBonus = otherEnemy._isElectricType ? 0.6 : 0.0;
      final otherIntensity =
          (otherHealthFactor * 0.5 + otherTypeBonus).clamp(0.0, 1.0);

      final combinedIntensity =
          ((chainIntensity + otherIntensity) / 2).clamp(0.0, 1.0);

      // Distance falloff
      final distanceFactor =
          1.0 - ((distance - minDistance) / (maxDistance - minDistance));
      final chainOpacity = combinedIntensity * distanceFactor * opacity * 0.7;

      if (chainOpacity < 0.1) continue;

      // Random flicker (chains appear and disappear)
      if (_lightningRandom.nextDouble() > chainOpacity + 0.3) continue;

      // Calculate start and end points (in local coordinates)
      const startX = 0.0; // Start from this enemy's center
      const startY = 0.0;
      final endX = dx;
      final endY = dy;

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 1: Outer glow (wide blur)
      // ═══════════════════════════════════════════════════════════════════════
      _lightningPath.reset();
      _generateLightningBolt(
        _lightningPath,
        startX, startY,
        endX, endY,
        8, // segments
        distance * 0.12, // displacement amplitude
        animPhase * 10,
      );

      _lightningGlowPaint.color = chainColor.withOpacity(chainOpacity * 0.3);
      canvas.drawPath(_lightningPath, _lightningGlowPaint);

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 2: Core lightning bolt
      // ═══════════════════════════════════════════════════════════════════════
      _lightningCorePaint.color = chainColor.withOpacity(chainOpacity * 0.8);
      canvas.drawPath(_lightningPath, _lightningCorePaint);

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 3: Inner white highlight
      // ═══════════════════════════════════════════════════════════════════════
      _lightningInnerPaint.color = Colors.white.withOpacity(chainOpacity * 0.6);
      canvas.drawPath(_lightningPath, _lightningInnerPaint);

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 4: Branch lightning (smaller bolts off the main one)
      // ═══════════════════════════════════════════════════════════════════════
      if (chainOpacity > 0.3 && !Enemy.lowFx) {
        final branchCount = 2 + _lightningRandom.nextInt(2);
        for (int b = 0; b < branchCount; b++) {
          final t = 0.25 + _lightningRandom.nextDouble() * 0.5;
          final branchX = startX + (endX - startX) * t;
          final branchY = startY + (endY - startY) * t;

          // Branch direction (perpendicular with random angle)
          final branchLength =
              distance * 0.15 * (0.5 + _lightningRandom.nextDouble() * 0.5);
          final branchSign = _lightningRandom.nextBool() ? 1.0 : -1.0;
          final jitter = (_lightningRandom.nextDouble() - 0.5) * 0.8;
          var branchDirX = perpX * branchSign + dirX * jitter;
          var branchDirY = perpY * branchSign + dirY * jitter;
          final branchDirLen =
              math.sqrt(branchDirX * branchDirX + branchDirY * branchDirY);
          if (branchDirLen > 0) {
            branchDirX /= branchDirLen;
            branchDirY /= branchDirLen;
          }
          final branchEndX = branchX + branchDirX * branchLength;
          final branchEndY = branchY + branchDirY * branchLength;

          _lightningPath.reset();
          _generateLightningBolt(
            _lightningPath,
            branchX, branchY,
            branchEndX, branchEndY,
            3, // fewer segments for branches
            branchLength * 0.15,
            animPhase * 12 + b,
          );

          _lightningCorePaint.color =
              secondaryColor.withOpacity(chainOpacity * 0.5);
          canvas.drawPath(_lightningPath, _lightningCorePaint);
        }
      }

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 5: Spark nodes at connection points
      // ═══════════════════════════════════════════════════════════════════════
      final sparkPulse = math.sin(animPhase * 8) * 0.3 + 0.7;

      // Spark at start
      _lightningNodePaint.color =
          Colors.white.withOpacity(chainOpacity * 0.8 * sparkPulse);
      canvas.drawCircle(
          Offset(startX, startY), 4 * sparkPulse, _lightningNodePaint);

      // Spark at end
      _lightningNodePaint.color =
          chainColor.withOpacity(chainOpacity * 0.6 * sparkPulse);
      canvas.drawCircle(
          Offset(endX, endY), 5 * sparkPulse, _lightningNodePaint);

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 6: Electric sparks along the chain
      // ═══════════════════════════════════════════════════════════════════════
      if (!Enemy.lowFx) {
        final sparkCount = (4 * chainOpacity).ceil();
        for (int s = 0; s < sparkCount; s++) {
          final t = _lightningRandom.nextDouble();
          final sparkX = startX + (endX - startX) * t;
          final sparkY = startY + (endY - startY) * t;
          final sparkOffset =
              (_lightningRandom.nextDouble() - 0.5) * distance * 0.1;
          final finalSparkX = sparkX + perpX * sparkOffset;
          final finalSparkY = sparkY + perpY * sparkOffset;

          final sparkAlpha = math.sin(animPhase * 15 + s * 2) * 0.5 + 0.5;
          if (sparkAlpha < 0.3) continue;

          _lightningSparkPaint.color =
              Colors.white.withOpacity(chainOpacity * sparkAlpha * 0.9);
          canvas.drawCircle(
            Offset(finalSparkX, finalSparkY),
            1.5 + sparkAlpha * 1.5,
            _lightningSparkPaint,
          );
        }
      }
    }
  }

  /// Generates a jagged lightning bolt path between two points
  void _generateLightningBolt(
    Path path,
    double startX,
    double startY,
    double endX,
    double endY,
    int segments,
    double displacement,
    double seed,
  ) {
    path.moveTo(startX, startY);

    final dx = endX - startX;
    final dy = endY - startY;
    final perpX = -dy;
    final perpY = dx;
    final perpLen = math.sqrt(perpX * perpX + perpY * perpY);
    final normPerpX = perpLen > 0 ? perpX / perpLen : 0;
    final normPerpY = perpLen > 0 ? perpY / perpLen : 0;

    for (int i = 1; i < segments; i++) {
      final t = i / segments;
      final baseX = startX + dx * t;
      final baseY = startY + dy * t;

      // Add random displacement perpendicular to the line
      final dispSeed = seed + i * 3.7;
      final centered = t * 2 - 1;
      final falloff = 1 - (centered * centered);
      final dispAmount = math.sin(dispSeed) * displacement * falloff;
      final pointX = baseX + normPerpX * dispAmount;
      final pointY = baseY + normPerpY * dispAmount;

      path.lineTo(pointX, pointY);
    }

    path.lineTo(endX, endY);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CACHED MASKFILTERS - Avoid per-frame allocations (CRITICAL for perf)
  // ═══════════════════════════════════════════════════════════════════════
  static final Map<int, MaskFilter> _blurCache = {};

  static MaskFilter? _blur(bool allowBlur, double sigma) {
    if (!allowBlur) return null;
    // Round sigma to int to limit cache size while keeping quality
    final key = sigma.round();
    return _blurCache.putIfAbsent(
      key,
      () => MaskFilter.blur(BlurStyle.normal, sigma),
    );
  }

  /// Clear blur cache (call between levels)
  static void clearBlurCache() {
    _blurCache.clear();
  }

  void _renderHealthBar(Canvas canvas, {double visibility = 1.0}) {
    final allowBlur = Enemy.allowBlur;
    final reduceFx = Enemy.lowFx;
    final barWidth = 42.0 * type.sizeMult;
    const barHeight = 8.0;
    final barY = -28.0 * type.sizeMult;
    final visibilityClamp = visibility.clamp(0.4, 1.0);
    final baseOpacity = (healthPercent >= 1.0 ? 0.5 : 0.95) * visibilityClamp;
    final healthColor = _getHealthColor();
    final animPhase = _animationTimer;

    // Extended holographic frame dimensions
    const frameExtendLeft = 6.0;
    const frameExtendRight = 18.0; // Extra space for data readout
    const frameExtendTop = 4.0;
    const frameExtendBottom = 3.0;

    final frameRect = Rect.fromLTRB(
      -barWidth / 2 - frameExtendLeft,
      barY - barHeight / 2 - frameExtendTop,
      barWidth / 2 + frameExtendRight,
      barY + barHeight / 2 + frameExtendBottom,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 1: Holographic background field
    // ═══════════════════════════════════════════════════════════════════════
    if (allowBlur) {
      _holoBarGlowPaint
        ..color = const Color(0xFF00FFFF).withOpacity(0.15 * baseOpacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(frameRect.inflate(3), const Radius.circular(2)),
        _holoBarGlowPaint,
      );
    }

    // Dark holographic panel background
    _holoBarDataPaint
      ..color = const Color(0xFF001122).withOpacity(0.85 * baseOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(1)),
      _holoBarDataPaint,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 2: Animated hexagonal grid pattern overlay
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx) {
      canvas.save();
      canvas.clipRRect(
          RRect.fromRectAndRadius(frameRect, const Radius.circular(1)));

      const hexSize = 4.0;
      final hexPhase = animPhase * 0.5;
      _holoBarHexPaint
        ..color = const Color(0xFF00FFFF).withOpacity(0.12 * baseOpacity);

      for (double hx = frameRect.left;
          hx < frameRect.right;
          hx += hexSize * 1.5) {
        for (double hy = frameRect.top;
            hy < frameRect.bottom;
            hy += hexSize * 1.73) {
          final offsetX = ((hy - frameRect.top) ~/ (hexSize * 1.73)) % 2 == 0
              ? 0.0
              : hexSize * 0.75;
          final pulse = math.sin(hexPhase + hx * 0.2 + hy * 0.15) * 0.5 + 0.5;
          if (pulse > 0.6) {
            _holoBarPath.reset();
            final cx = hx + offsetX;
            final cy = hy;
            for (int i = 0; i < 6; i++) {
              final angle = i * math.pi / 3;
              final px = cx + math.cos(angle) * hexSize * 0.4;
              final py = cy + math.sin(angle) * hexSize * 0.4;
              if (i == 0) {
                _holoBarPath.moveTo(px, py);
              } else {
                _holoBarPath.lineTo(px, py);
              }
            }
            _holoBarPath.close();
            canvas.drawPath(_holoBarPath, _holoBarHexPaint);
          }
        }
      }
      canvas.restore();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 3: Scanline effect
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx) {
      canvas.save();
      canvas.clipRRect(
          RRect.fromRectAndRadius(frameRect, const Radius.circular(1)));

      _holoBarScanlinePaint
        ..color = const Color(0xFF000000).withOpacity(0.15 * baseOpacity)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;

      final scanOffset = (animPhase * 15) % 3;
      for (double sy = frameRect.top + scanOffset;
          sy < frameRect.bottom;
          sy += 3) {
        canvas.drawLine(
          Offset(frameRect.left, sy),
          Offset(frameRect.right, sy),
          _holoBarScanlinePaint,
        );
      }
      canvas.restore();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 4: Health fill with animated energy gradient
    // ═══════════════════════════════════════════════════════════════════════
    final fillWidth = barWidth * healthPercent;
    final fillRect = Rect.fromLTWH(
      -barWidth / 2,
      barY - barHeight / 2 + 1,
      fillWidth,
      barHeight - 2,
    );

    // Animated gradient fill
    final gradientPhase = animPhase * 2;
    final energyShift = math.sin(gradientPhase) * 0.1;
    _healthGradientColors[0] =
        healthColor.withOpacity((0.9 + energyShift) * baseOpacity);
    _healthGradientColors[1] = Color.lerp(
      healthColor,
      const Color(0xFFFFFFFF),
      0.3,
    )!
        .withOpacity((0.7 + energyShift) * baseOpacity);
    _healthGradientColors[2] =
        healthColor.withOpacity((0.85 - energyShift) * baseOpacity);
    _healthGradientStops[1] = 0.5 + math.sin(gradientPhase * 0.7) * 0.2;
    final healthGradient = LinearGradient(
      colors: _healthGradientColors,
      stops: _healthGradientStops,
    ).createShader(fillRect);

    _holoBarDataPaint
      ..shader = healthGradient
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, const Radius.circular(1)),
      _holoBarDataPaint,
    );
    _holoBarDataPaint.shader = null;

    // Energy pulse line on fill
    if (!reduceFx && fillWidth > 5) {
      final pulseX = -barWidth / 2 + (animPhase * 40) % fillWidth;
      _holoBarEnergyPaint
        ..color = Colors.white.withOpacity(0.6 * baseOpacity)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(pulseX, fillRect.top),
        Offset(pulseX, fillRect.bottom),
        _holoBarEnergyPaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 5: Glow on health bar
    // ═══════════════════════════════════════════════════════════════════════
    if (allowBlur) {
      _holoBarGlowPaint..color = healthColor.withOpacity(0.5 * baseOpacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(fillRect, const Radius.circular(1)),
        _holoBarGlowPaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 6: Holographic frame with corner accents
    // ═══════════════════════════════════════════════════════════════════════
    _holoBarFramePaint
      ..color = const Color(0xFF00FFFF).withOpacity(0.7 * baseOpacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(1)),
      _holoBarFramePaint,
    );

    // Animated corner brackets
    const cornerLen = 4.0;
    final cornerPulse = math.sin(animPhase * 3) * 0.2 + 0.8;
    _holoBarCornerPaint
      ..color = const Color(0xFF00FFFF).withOpacity(cornerPulse * baseOpacity);

    // Top-left corner
    canvas.drawLine(
      Offset(frameRect.left, frameRect.top + cornerLen),
      Offset(frameRect.left, frameRect.top),
      _holoBarCornerPaint,
    );
    canvas.drawLine(
      Offset(frameRect.left, frameRect.top),
      Offset(frameRect.left + cornerLen, frameRect.top),
      _holoBarCornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(frameRect.left, frameRect.bottom - cornerLen),
      Offset(frameRect.left, frameRect.bottom),
      _holoBarCornerPaint,
    );
    canvas.drawLine(
      Offset(frameRect.left, frameRect.bottom),
      Offset(frameRect.left + cornerLen, frameRect.bottom),
      _holoBarCornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(frameRect.right, frameRect.top + cornerLen),
      Offset(frameRect.right, frameRect.top),
      _holoBarCornerPaint,
    );
    canvas.drawLine(
      Offset(frameRect.right, frameRect.top),
      Offset(frameRect.right - cornerLen, frameRect.top),
      _holoBarCornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(frameRect.right, frameRect.bottom - cornerLen),
      Offset(frameRect.right, frameRect.bottom),
      _holoBarCornerPaint,
    );
    canvas.drawLine(
      Offset(frameRect.right, frameRect.bottom),
      Offset(frameRect.right - cornerLen, frameRect.bottom),
      _holoBarCornerPaint,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 7: Data readout panel (health %, threat level)
    // ═══════════════════════════════════════════════════════════════════════
    final dataX = barWidth / 2 + 3;
    final dataY = barY;

    // Health percentage with animated flicker
    final healthPct = (healthPercent * 100).toInt();
    final flickerIntensity =
        reduceFx ? 1.0 : (math.sin(animPhase * 8) * 0.1 + 0.9);

    // Draw percentage digits
    _drawHoloDigits(
      canvas,
      healthPct.toString().padLeft(3, '0'),
      Offset(dataX, dataY - 2),
      const Color(0xFF00FF88),
      baseOpacity * flickerIntensity,
      2.5,
    );

    // Percent symbol
    _holoBarDataPaint
      ..color = const Color(0xFF00FFFF)
          .withOpacity(0.6 * baseOpacity * flickerIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(dataX + 11, dataY - 4), 1, _holoBarDataPaint);
    canvas.drawCircle(Offset(dataX + 14, dataY), 1, _holoBarDataPaint);
    canvas.drawLine(
      Offset(dataX + 10, dataY + 1),
      Offset(dataX + 15, dataY - 5),
      _holoBarFramePaint..strokeWidth = 0.8,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 8: Threat indicator bars
    // ═══════════════════════════════════════════════════════════════════════
    final threatLevel = (threatTier + 1).clamp(1, 5);
    for (int i = 0; i < 5; i++) {
      final barActive = i < threatLevel;
      final threatX = dataX + i * 3;
      final threatY = dataY + 4;
      final barH = barActive ? 3.0 : 2.0;

      _holoBarDataPaint
        ..color = (barActive
                ? (i < 2
                    ? const Color(0xFF00FF88)
                    : i < 4
                        ? const Color(0xFFFFFF00)
                        : const Color(0xFFFF0066))
                : const Color(0xFF333333))
            .withOpacity(baseOpacity * (barActive ? flickerIntensity : 0.5));
      canvas.drawRect(
        Rect.fromLTWH(threatX, threatY - barH / 2, 2, barH),
        _holoBarDataPaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 9: Glitch distortion effect (occasional)
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx) {
      final glitchChance = _holoBarRandom.nextDouble();
      if (glitchChance < 0.03 && healthPercent < 0.5) {
        // Random horizontal slice displacement
        final sliceY =
            frameRect.top + _holoBarRandom.nextDouble() * frameRect.height;
        final sliceH = 1.0 + _holoBarRandom.nextDouble() * 2;
        final sliceOffset = (_holoBarRandom.nextDouble() - 0.5) * 4;

        _holoBarGlitchPaint
          ..color = const Color(0xFFFF0066).withOpacity(0.4 * baseOpacity);
        canvas.drawRect(
          Rect.fromLTWH(frameRect.left + sliceOffset, sliceY,
              frameRect.width * 0.5, sliceH),
          _holoBarGlitchPaint,
        );

        _holoBarGlitchPaint
          ..color = const Color(0xFF00FFFF).withOpacity(0.3 * baseOpacity);
        canvas.drawRect(
          Rect.fromLTWH(frameRect.left - sliceOffset, sliceY + sliceH,
              frameRect.width * 0.3, sliceH),
          _holoBarGlitchPaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 10: Critical health warning flash
    // ═══════════════════════════════════════════════════════════════════════
    if (healthPercent < 0.25) {
      final warningPulse = math.sin(animPhase * 6) * 0.5 + 0.5;
      _holoBarGlitchPaint
        ..color = const Color(0xFFFF0066)
            .withOpacity(0.2 * warningPulse * baseOpacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(frameRect, const Radius.circular(1)),
        _holoBarGlitchPaint,
      );

      // Warning border flash
      if (!reduceFx) {
        _holoBarFramePaint
          ..color = const Color(0xFFFF0066)
              .withOpacity(0.8 * warningPulse * baseOpacity)
          ..strokeWidth = 1.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(frameRect, const Radius.circular(1)),
          _holoBarFramePaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 11: Holographic projection lines
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx && allowBlur) {
      final projectionOpacity = 0.3 * baseOpacity;
      _holoBarEnergyPaint
        ..color = const Color(0xFF00FFFF).withOpacity(projectionOpacity)
        ..strokeWidth = 0.5;

      // Vertical projection lines from corners
      canvas.drawLine(
        Offset(frameRect.left, frameRect.bottom),
        Offset(frameRect.left - 2, frameRect.bottom + 4),
        _holoBarEnergyPaint,
      );
      canvas.drawLine(
        Offset(frameRect.right, frameRect.bottom),
        Offset(frameRect.right + 2, frameRect.bottom + 4),
        _holoBarEnergyPaint,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HOLOGRAPHIC STATUS ICONS (Above entity indicators)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Renders holographic status icons above the entity
  void _renderStatusIcons(Canvas canvas, double visibility, bool reduceFx) {
    final allowBlur = Enemy.allowBlur && !reduceFx;
    final animPhase = _animationPhase;
    final baseOpacity = visibility.clamp(0.4, 1.0);

    // Calculate icon positions (horizontal stacking above health bar)
    const iconSize = 10.0;
    const iconSpacing = 14.0;
    final iconY = -48.0 * type.sizeMult; // Above health bar

    // Subtle bob animation using animation phase
    final bobOffset = reduceFx ? 0.0 : math.sin(animPhase * 2.5) * 1.5;

    // Collect active effects with their remaining durations
    final activeEffects = <_StatusIconData>[];

    if (isSlowed) {
      activeEffects.add(_StatusIconData(
        type: _StatusIconType.slow,
        color: _slowIconColor,
        duration: _slowDuration,
        maxDuration: 3.0, // Typical slow duration
      ));
    }
    if (isBurning) {
      activeEffects.add(_StatusIconData(
        type: _StatusIconType.burn,
        color: _burnIconColor,
        duration: _burnDuration,
        maxDuration: 5.0, // Typical burn duration
      ));
    }
    if (hasShield) {
      activeEffects.add(_StatusIconData(
        type: _StatusIconType.shield,
        color: _shieldIconColor,
        duration: _shieldDuration,
        maxDuration: _shieldDuration > 0 ? _shieldDuration : 1.0,
      ));
    }
    if (isBoosted) {
      activeEffects.add(_StatusIconData(
        type: _StatusIconType.boost,
        color: _boostIconColor,
        duration: _boostDuration,
        maxDuration: 5.0, // Typical boost duration
      ));
    }
    if (isStunned) {
      activeEffects.add(_StatusIconData(
        type: _StatusIconType.stun,
        color: _stunIconColor,
        duration: _stunDuration,
        maxDuration: 2.0, // Typical stun duration
      ));
    }

    if (activeEffects.isEmpty) return;

    // Calculate total width for centering
    final totalWidth =
        activeEffects.length * iconSpacing - (iconSpacing - iconSize);
    final startX = -totalWidth / 2 + iconSize / 2;

    for (int i = 0; i < activeEffects.length; i++) {
      final effect = activeEffects[i];
      final iconX = startX + i * iconSpacing;
      final iconCenter = Offset(iconX, iconY + bobOffset);

      // Pulsing animation (each icon has slight phase offset)
      final pulsePhase = animPhase + i * 0.5;
      final pulse = reduceFx ? 1.0 : 0.85 + math.sin(pulsePhase * 3) * 0.15;

      _renderSingleStatusIcon(
        canvas,
        effect,
        iconCenter,
        iconSize * pulse,
        baseOpacity,
        animPhase,
        allowBlur,
        reduceFx,
      );
    }
  }

  /// Renders a single holographic status icon
  void _renderSingleStatusIcon(
    Canvas canvas,
    _StatusIconData effect,
    Offset center,
    double size,
    double opacity,
    double animPhase,
    bool allowBlur,
    bool reduceFx,
  ) {
    final halfSize = size / 2;

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 1: Outer glow effect
    // ═══════════════════════════════════════════════════════════════════════
    if (allowBlur) {
      _statusIconGlowPaint..color = effect.color.withOpacity(0.4 * opacity);
      canvas.drawCircle(center, halfSize * 1.3, _statusIconGlowPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 2: Holographic base shape
    // ═══════════════════════════════════════════════════════════════════════
    _statusIconBasePaint..color = effect.color.withOpacity(0.15 * opacity);
    canvas.drawCircle(center, halfSize, _statusIconBasePaint);

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 3: Timer arc (remaining duration)
    // ═══════════════════════════════════════════════════════════════════════
    if (effect.duration > 0 && effect.maxDuration > 0) {
      final progress = (effect.duration / effect.maxDuration).clamp(0.0, 1.0);
      final sweepAngle = progress * math.pi * 2;

      _statusIconTimerPaint..color = effect.color.withOpacity(0.6 * opacity);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: halfSize * 0.85),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        _statusIconTimerPaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 4: Icon shape (type-specific)
    // ═══════════════════════════════════════════════════════════════════════
    _statusIconPath.reset();
    _statusIconStrokePaint..color = effect.color.withOpacity(0.9 * opacity);
    _statusIconBasePaint..color = effect.color.withOpacity(0.7 * opacity);

    switch (effect.type) {
      case _StatusIconType.slow:
        _drawSnowflakeIcon(
            canvas, center, halfSize * 0.7, opacity, effect.color);
        break;
      case _StatusIconType.burn:
        _drawFlameIcon(
            canvas, center, halfSize * 0.7, opacity, effect.color, animPhase);
        break;
      case _StatusIconType.shield:
        _drawHexagonIcon(canvas, center, halfSize * 0.7, opacity, effect.color);
        break;
      case _StatusIconType.boost:
        _drawArrowIcon(canvas, center, halfSize * 0.7, opacity, effect.color);
        break;
      case _StatusIconType.stun:
        _drawLightningIcon(
            canvas, center, halfSize * 0.7, opacity, effect.color, animPhase);
        break;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 5: Scanline overlay (holographic effect)
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx) {
      final scanY = (animPhase * 20) % (size * 2) - size;
      if (scanY > -halfSize && scanY < halfSize) {
        _statusIconScanlinePaint
          ..color = Colors.white.withOpacity(0.3 * opacity);
        canvas.drawLine(
          Offset(center.dx - halfSize, center.dy + scanY),
          Offset(center.dx + halfSize, center.dy + scanY),
          _statusIconScanlinePaint,
        );
      }
    }
  }

  /// Draws a snowflake icon for slow effect
  void _drawSnowflakeIcon(
      Canvas canvas, Offset center, double size, double opacity, Color color) {
    _statusIconStrokePaint
      ..color = color.withOpacity(0.9 * opacity)
      ..strokeWidth = 1.2;

    // Six-pointed snowflake with branches
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final cos = math.cos(angle);
      final sin = math.sin(angle);

      // Main branch
      canvas.drawLine(
        center,
        Offset(center.dx + cos * size, center.dy + sin * size),
        _statusIconStrokePaint,
      );

      // Small side branches
      final branchLen = size * 0.4;
      final branchStart = size * 0.5;
      for (final offset in [-0.4, 0.4]) {
        final branchAngle = angle + offset;
        canvas.drawLine(
          Offset(center.dx + cos * branchStart, center.dy + sin * branchStart),
          Offset(
            center.dx + cos * branchStart + math.cos(branchAngle) * branchLen,
            center.dy + sin * branchStart + math.sin(branchAngle) * branchLen,
          ),
          _statusIconStrokePaint,
        );
      }
    }

    // Center dot
    _statusIconBasePaint..color = color.withOpacity(0.8 * opacity);
    canvas.drawCircle(center, size * 0.15, _statusIconBasePaint);
  }

  /// Draws a flame icon for burn effect
  void _drawFlameIcon(Canvas canvas, Offset center, double size, double opacity,
      Color color, double animPhase) {
    // Animated flame flicker
    final flicker = math.sin(animPhase * 8) * 0.1;

    _statusIconPath.reset();

    // Outer flame shape
    _statusIconPath.moveTo(center.dx, center.dy + size * 0.8);
    _statusIconPath.quadraticBezierTo(
      center.dx - size * (0.7 + flicker),
      center.dy + size * 0.2,
      center.dx - size * 0.3,
      center.dy - size * 0.3,
    );
    _statusIconPath.quadraticBezierTo(
      center.dx - size * 0.1,
      center.dy - size * 0.1,
      center.dx,
      center.dy - size * (0.9 + flicker * 0.5),
    );
    _statusIconPath.quadraticBezierTo(
      center.dx + size * 0.1,
      center.dy - size * 0.1,
      center.dx + size * 0.3,
      center.dy - size * 0.3,
    );
    _statusIconPath.quadraticBezierTo(
      center.dx + size * (0.7 + flicker),
      center.dy + size * 0.2,
      center.dx,
      center.dy + size * 0.8,
    );
    _statusIconPath.close();

    // Gradient-like effect with multiple layers
    _statusIconBasePaint..color = color.withOpacity(0.7 * opacity);
    canvas.drawPath(_statusIconPath, _statusIconBasePaint);

    _statusIconStrokePaint
      ..color = Colors.white.withOpacity(0.6 * opacity)
      ..strokeWidth = 1.0;
    canvas.drawPath(_statusIconPath, _statusIconStrokePaint);

    // Inner bright core
    _statusIconBasePaint
      ..color = const Color(0xFFFFFF00).withOpacity(0.5 * opacity);
    canvas.drawCircle(
      Offset(center.dx, center.dy + size * 0.2),
      size * 0.25,
      _statusIconBasePaint,
    );
  }

  /// Draws a hexagon icon for shield effect
  void _drawHexagonIcon(
      Canvas canvas, Offset center, double size, double opacity, Color color) {
    _statusIconPath.reset();

    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6; // Flat top hexagon
      final x = center.dx + math.cos(angle) * size;
      final y = center.dy + math.sin(angle) * size;
      if (i == 0) {
        _statusIconPath.moveTo(x, y);
      } else {
        _statusIconPath.lineTo(x, y);
      }
    }
    _statusIconPath.close();

    // Fill with semi-transparent color
    _statusIconBasePaint..color = color.withOpacity(0.4 * opacity);
    canvas.drawPath(_statusIconPath, _statusIconBasePaint);

    // Stroke outline
    _statusIconStrokePaint
      ..color = color.withOpacity(0.9 * opacity)
      ..strokeWidth = 1.5;
    canvas.drawPath(_statusIconPath, _statusIconStrokePaint);

    // Inner highlight hexagon
    _statusIconPath.reset();
    final innerSize = size * 0.5;
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final x = center.dx + math.cos(angle) * innerSize;
      final y = center.dy + math.sin(angle) * innerSize;
      if (i == 0) {
        _statusIconPath.moveTo(x, y);
      } else {
        _statusIconPath.lineTo(x, y);
      }
    }
    _statusIconPath.close();

    _statusIconStrokePaint
      ..color = Colors.white.withOpacity(0.5 * opacity)
      ..strokeWidth = 0.8;
    canvas.drawPath(_statusIconPath, _statusIconStrokePaint);
  }

  /// Draws an upward arrow icon for boost effect
  void _drawArrowIcon(
      Canvas canvas, Offset center, double size, double opacity, Color color) {
    _statusIconPath.reset();

    // Arrow pointing up
    _statusIconPath.moveTo(center.dx, center.dy - size); // Top point
    _statusIconPath.lineTo(center.dx + size * 0.6, center.dy); // Right wing
    _statusIconPath.lineTo(center.dx + size * 0.25, center.dy); // Right indent
    _statusIconPath.lineTo(
        center.dx + size * 0.25, center.dy + size * 0.8); // Right bottom
    _statusIconPath.lineTo(
        center.dx - size * 0.25, center.dy + size * 0.8); // Left bottom
    _statusIconPath.lineTo(center.dx - size * 0.25, center.dy); // Left indent
    _statusIconPath.lineTo(center.dx - size * 0.6, center.dy); // Left wing
    _statusIconPath.close();

    // Fill
    _statusIconBasePaint..color = color.withOpacity(0.6 * opacity);
    canvas.drawPath(_statusIconPath, _statusIconBasePaint);

    // Stroke
    _statusIconStrokePaint
      ..color = color.withOpacity(0.9 * opacity)
      ..strokeWidth = 1.2;
    canvas.drawPath(_statusIconPath, _statusIconStrokePaint);

    // Speed lines
    _statusIconStrokePaint
      ..color = Colors.white.withOpacity(0.4 * opacity)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(center.dx, center.dy - size * 0.5),
      Offset(center.dx, center.dy - size * 0.2),
      _statusIconStrokePaint,
    );
  }

  /// Draws a lightning bolt icon for stun effect
  void _drawLightningIcon(Canvas canvas, Offset center, double size,
      double opacity, Color color, double animPhase) {
    // Flicker effect for lightning
    final flicker = (math.sin(animPhase * 12) > 0.3) ? 1.0 : 0.7;

    _statusIconPath.reset();

    // Lightning bolt shape
    _statusIconPath.moveTo(center.dx + size * 0.1, center.dy - size);
    _statusIconPath.lineTo(center.dx - size * 0.4, center.dy - size * 0.1);
    _statusIconPath.lineTo(center.dx, center.dy - size * 0.1);
    _statusIconPath.lineTo(center.dx - size * 0.2, center.dy + size);
    _statusIconPath.lineTo(center.dx + size * 0.3, center.dy + size * 0.1);
    _statusIconPath.lineTo(center.dx - size * 0.1, center.dy + size * 0.1);
    _statusIconPath.close();

    // Fill with flicker
    _statusIconBasePaint..color = color.withOpacity(0.7 * opacity * flicker);
    canvas.drawPath(_statusIconPath, _statusIconBasePaint);

    // Bright stroke
    _statusIconStrokePaint
      ..color = Colors.white.withOpacity(0.8 * opacity * flicker)
      ..strokeWidth = 1.0;
    canvas.drawPath(_statusIconPath, _statusIconStrokePaint);

    // Electric sparks around
    if (flicker > 0.9) {
      _statusIconBasePaint..color = Colors.white.withOpacity(0.6 * opacity);
      canvas.drawCircle(
        Offset(center.dx - size * 0.5, center.dy - size * 0.3),
        size * 0.1,
        _statusIconBasePaint,
      );
      canvas.drawCircle(
        Offset(center.dx + size * 0.4, center.dy + size * 0.4),
        size * 0.08,
        _statusIconBasePaint,
      );
    }
  }

  /// Draws holographic-style digits for data readouts
  void _drawHoloDigits(Canvas canvas, String text, Offset pos, Color color,
      double opacity, double scale) {
    // Simplified 7-segment style digit rendering
    final segmentWidth = 1.5 * scale;
    final digitWidth = 3.0 * scale;
    final digitHeight = 5.0 * scale;
    final spacing = 0.5 * scale;

    _holoBarDataPaint
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final dx = pos.dx + i * (digitWidth + spacing);
      final dy = pos.dy - digitHeight / 2;

      // Draw simplified digit segments
      final segments = _getDigitSegments(char);
      for (final seg in segments) {
        switch (seg) {
          case 'top':
            canvas.drawRect(Rect.fromLTWH(dx, dy, digitWidth, segmentWidth),
                _holoBarDataPaint);
            break;
          case 'mid':
            canvas.drawRect(
                Rect.fromLTWH(dx, dy + digitHeight / 2 - segmentWidth / 2,
                    digitWidth, segmentWidth),
                _holoBarDataPaint);
            break;
          case 'bot':
            canvas.drawRect(
                Rect.fromLTWH(dx, dy + digitHeight - segmentWidth, digitWidth,
                    segmentWidth),
                _holoBarDataPaint);
            break;
          case 'tl':
            canvas.drawRect(
                Rect.fromLTWH(dx, dy, segmentWidth, digitHeight / 2),
                _holoBarDataPaint);
            break;
          case 'tr':
            canvas.drawRect(
                Rect.fromLTWH(dx + digitWidth - segmentWidth, dy, segmentWidth,
                    digitHeight / 2),
                _holoBarDataPaint);
            break;
          case 'bl':
            canvas.drawRect(
                Rect.fromLTWH(
                    dx, dy + digitHeight / 2, segmentWidth, digitHeight / 2),
                _holoBarDataPaint);
            break;
          case 'br':
            canvas.drawRect(
                Rect.fromLTWH(dx + digitWidth - segmentWidth,
                    dy + digitHeight / 2, segmentWidth, digitHeight / 2),
                _holoBarDataPaint);
            break;
        }
      }
    }
  }

  /// Returns segments to draw for a digit character
  List<String> _getDigitSegments(String char) {
    switch (char) {
      case '0':
        return ['top', 'bot', 'tl', 'tr', 'bl', 'br'];
      case '1':
        return ['tr', 'br'];
      case '2':
        return ['top', 'mid', 'bot', 'tr', 'bl'];
      case '3':
        return ['top', 'mid', 'bot', 'tr', 'br'];
      case '4':
        return ['mid', 'tl', 'tr', 'br'];
      case '5':
        return ['top', 'mid', 'bot', 'tl', 'br'];
      case '6':
        return ['top', 'mid', 'bot', 'tl', 'bl', 'br'];
      case '7':
        return ['top', 'tr', 'br'];
      case '8':
        return ['top', 'mid', 'bot', 'tl', 'tr', 'bl', 'br'];
      case '9':
        return ['top', 'mid', 'bot', 'tl', 'tr', 'br'];
      default:
        return [];
    }
  }

  void _drawMegaGeometry(
      Canvas canvas, double radius, double phantomOpacity, bool allowBlur) {
    final color = type.color;

    // 3D Extrusion Layer (drawn first, behind everything)
    _draw3DExtrusion(canvas, radius, color, phantomOpacity, allowBlur);

    // Hull silhouette
    _drawHull(canvas, radius, color, phantomOpacity, allowBlur);

    // Core Layer
    _drawCore(canvas, phantomOpacity);

    // Shell Layer (Semi-transparent)
    _drawShell(canvas, radius, color, phantomOpacity, allowBlur);

    // Armor Plates (Independent rotation)
    _drawArmorPlates(canvas, radius, color, phantomOpacity);

    // 3D Highlight Rim (top edge lighting)
    _draw3DHighlight(canvas, radius, color, phantomOpacity, allowBlur);
  }

  /// Draws 3D extrusion layers below the enemy body for depth perception
  void _draw3DExtrusion(Canvas canvas, double radius, Color color,
      double opacity, bool allowBlur) {
    // Extrusion depth based on enemy size
    final extrusionDepth = radius * 0.35 * type.sizeMult.clamp(0.8, 1.5);

    // Use fewer layers in lowFx mode but still show 3D effect
    final layers = Enemy.lowFx ? 2 : 4;

    // Light direction simulation (from top-left)
    final lightOffsetX = -radius * 0.08;
    final lightOffsetY = radius * 0.12;

    for (int i = layers; i >= 1; i--) {
      final layerOffset = (i / layers) * extrusionDepth;
      final darkness = 0.3 + (i / layers) * 0.5; // Deeper = darker
      final layerColor = Color.lerp(color, Colors.black, darkness)!;

      canvas.save();
      canvas.translate(
        lightOffsetX * (i / layers),
        lightOffsetY + layerOffset,
      );

      final extrusionPath = _createBodyPath(radius * (0.92 - i * 0.02));

      _extrusionPaint.color =
          layerColor.withOpacity(opacity * (0.6 - i * 0.08));
      _extrusionPaint.style = PaintingStyle.fill;

      canvas.drawPath(extrusionPath, _extrusionPaint);
      canvas.restore();
    }

    // Bottom edge glow for depth (skip blur in lowFx mode)
    canvas.save();
    canvas.translate(lightOffsetX * 0.5, lightOffsetY + extrusionDepth * 0.8);

    final bottomGlowPath = _createBodyPath(radius * 0.88);
    _bottomGlowPaint.color = Colors.black.withOpacity(opacity * 0.4);
    _bottomGlowPaint.style = PaintingStyle.stroke;
    _bottomGlowPaint.strokeWidth = 2.5;
    _bottomGlowPaint.maskFilter = (allowBlur && !Enemy.lowFx)
        ? const MaskFilter.blur(BlurStyle.normal, 4)
        : null;

    canvas.drawPath(bottomGlowPath, _bottomGlowPaint);
    canvas.restore();
  }

  /// Draws 3D highlight rim on the top edge for lighting effect
  void _draw3DHighlight(Canvas canvas, double radius, Color color,
      double opacity, bool allowBlur) {
    final highlightPath = _createBodyPath(radius * 0.93);

    // In lowFx mode, draw simplified highlight (just specular spot)
    if (Enemy.lowFx) {
      // Simple specular highlight - always visible for 3D effect
      final specularRadius = radius * 0.2;
      final specularOffset = Offset(-radius * 0.25, -radius * 0.3);

      _specularPaint.color = Colors.white.withOpacity(opacity * 0.4);

      canvas.drawCircle(specularOffset, specularRadius, _specularPaint);
      return;
    }

    // Full quality: Top-left highlight (simulates light source)
    _highlightPaint
      ..shader = _highlightShader
      ..colorFilter = _opacityFilter(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..maskFilter =
          allowBlur ? const MaskFilter.blur(BlurStyle.normal, 2) : null;

    canvas.drawPath(highlightPath, _highlightPaint);

    // Inner specular highlight (small bright spot)
    final specularRadius = _specularRadius;
    final specularOffset = _specularOffset;

    _specularPaint
      ..shader = _specularShader
      ..colorFilter = _opacityFilter(opacity);

    canvas.drawCircle(specularOffset, specularRadius, _specularPaint);
    _highlightPaint
      ..shader = null
      ..colorFilter = null;
    _specularPaint
      ..shader = null
      ..colorFilter = null;

    // Animated energy pulse on edge (gives life to 3D effect)
    final pulsePhase = _animationTimer * 2;
    final pulseAlpha = (math.sin(pulsePhase) * 0.5 + 0.5) * opacity * 0.3;

    if (pulseAlpha > 0.05) {
      _pulsePaint.color = color.withOpacity(pulseAlpha);
      _pulsePaint.style = PaintingStyle.stroke;
      _pulsePaint.strokeWidth = 1.2;
      _pulsePaint.maskFilter =
          allowBlur ? const MaskFilter.blur(BlurStyle.normal, 3) : null;

      canvas.drawPath(highlightPath, _pulsePaint);
    }
  }

  void _drawHull(Canvas canvas, double radius, Color color, double opacity,
      bool allowBlur) {
    final hullPath = _createBodyPath(radius * 0.95);
    final baseColor = Color.lerp(color.withOpacity(1), Colors.black, 0.45)!;
    _hullPaint.color = baseColor.withOpacity(opacity * 0.65);
    _hullPaint.style = PaintingStyle.fill;
    canvas.drawPath(hullPath, _hullPaint);

    _outlinePaint.color = _worldEdgeColor.withOpacity(opacity * 0.85);
    _outlinePaint.style = PaintingStyle.stroke;
    _outlinePaint.strokeWidth = 1.4;
    _outlinePaint.strokeCap = StrokeCap.square;
    _outlinePaint.maskFilter =
        (allowBlur && !Enemy.lowFx) ? _blur(true, 3) : null;
    canvas.drawPath(hullPath, _outlinePaint);
  }

  void _drawCore(Canvas canvas, double opacity) {
    final coreRadius = _coreRadius;
    _corePaint
      ..shader = _coreShader
      ..colorFilter = _opacityFilter(opacity);

    final corePath = _createTypeLayerPath(coreRadius, 0);
    canvas.drawPath(corePath, _corePaint);
    _corePaint
      ..shader = null
      ..colorFilter = null;

    _slashPaint.color = Colors.white.withOpacity(0.45 * opacity);
    _slashPaint.strokeWidth = coreRadius * 0.18;
    _slashPaint.strokeCap = StrokeCap.square;
    canvas.save();
    canvas.clipPath(corePath);
    final slashLen = coreRadius * 1.1;
    canvas.drawLine(
      Offset(-slashLen * 0.4, -slashLen * 0.1),
      Offset(slashLen * 0.5, -slashLen * 0.25),
      _slashPaint,
    );
    _slashPaint.strokeWidth = coreRadius * 0.12;
    canvas.drawLine(
      Offset(-slashLen * 0.3, slashLen * 0.2),
      Offset(slashLen * 0.4, slashLen * 0.05),
      _slashPaint,
    );
    _drawCoreGlyph(canvas, coreRadius, opacity);
    canvas.restore();
  }

  void _drawCoreGlyph(Canvas canvas, double coreRadius, double opacity) {
    final pulse =
        0.5 + 0.5 * math.sin(_animationTimer * 2.4 + type.world * 0.4);
    final accent = _worldAccentColor;
    final alpha = (0.28 + 0.28 * pulse) * opacity;

    _strokePaint
      ..color = accent.withOpacity(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = coreRadius * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = null;
    _fillPaint
      ..color = accent.withOpacity(alpha * 0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = null;

    switch (type.world) {
      case 1:
        canvas.drawLine(
          Offset(-coreRadius * 0.35, coreRadius * 0.05),
          Offset(0, coreRadius * 0.35),
          _strokePaint,
        );
        canvas.drawLine(
          Offset(0, coreRadius * 0.35),
          Offset(coreRadius * 0.35, coreRadius * 0.05),
          _strokePaint,
        );
        canvas.drawCircle(
          Offset(0, -coreRadius * 0.1),
          coreRadius * 0.08,
          _fillPaint,
        );
        break;
      case 2:
        final ring =
            Rect.fromCircle(center: Offset.zero, radius: coreRadius * 0.55);
        canvas.drawArc(
            ring, _animationTimer * 0.7, math.pi * 0.6, false, _strokePaint);
        canvas.drawArc(
          ring,
          _animationTimer * 0.7 + math.pi,
          math.pi * 0.35,
          false,
          _strokePaint,
        );
        break;
      case 3:
        for (int i = -1; i <= 1; i++) {
          final x = i * coreRadius * 0.22;
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(x, coreRadius * 0.1),
              width: coreRadius * 0.14,
              height: coreRadius * 0.14,
            ),
            _fillPaint,
          );
        }
        break;
      case 4:
        _reusableOverlayPath
          ..reset()
          ..moveTo(-coreRadius * 0.1, -coreRadius * 0.5)
          ..lineTo(coreRadius * 0.12, -coreRadius * 0.05)
          ..lineTo(-coreRadius * 0.02, -coreRadius * 0.05)
          ..lineTo(coreRadius * 0.2, coreRadius * 0.5);
        canvas.drawPath(_reusableOverlayPath, _strokePaint);
        break;
      case 5:
        _reusableOverlayPath
          ..reset()
          ..moveTo(0, -coreRadius * 0.55)
          ..lineTo(coreRadius * 0.4, 0)
          ..lineTo(0, coreRadius * 0.55)
          ..lineTo(-coreRadius * 0.4, 0)
          ..close();
        canvas.drawPath(_reusableOverlayPath, _strokePaint);
        break;
      case 6:
        final r = coreRadius * 0.5;
        canvas.drawLine(Offset(-r, -r), Offset(-r * 0.4, -r), _strokePaint);
        canvas.drawLine(Offset(-r, -r), Offset(-r, -r * 0.4), _strokePaint);
        canvas.drawLine(Offset(r, -r), Offset(r * 0.4, -r), _strokePaint);
        canvas.drawLine(Offset(r, -r), Offset(r, -r * 0.4), _strokePaint);
        canvas.drawLine(Offset(-r, r), Offset(-r * 0.4, r), _strokePaint);
        canvas.drawLine(Offset(-r, r), Offset(-r, r * 0.4), _strokePaint);
        canvas.drawLine(Offset(r, r), Offset(r * 0.4, r), _strokePaint);
        canvas.drawLine(Offset(r, r), Offset(r, r * 0.4), _strokePaint);
        break;
      case 7:
        canvas.drawLine(
          Offset(-coreRadius * 0.5, 0),
          Offset(coreRadius * 0.5, 0),
          _strokePaint,
        );
        canvas.drawLine(
          Offset(0, -coreRadius * 0.5),
          Offset(0, coreRadius * 0.5),
          _strokePaint,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: coreRadius * 0.35,
            height: coreRadius * 0.35,
          ),
          _fillPaint,
        );
        break;
      case 8:
        final ring =
            Rect.fromCircle(center: Offset.zero, radius: coreRadius * 0.55);
        canvas.drawArc(
          ring,
          _animationTimer * 0.9,
          math.pi * 0.8,
          false,
          _strokePaint,
        );
        canvas.drawArc(
          ring,
          _animationTimer * 0.9 + math.pi,
          math.pi * 0.45,
          false,
          _strokePaint,
        );
        break;
      case 9:
        canvas.drawCircle(Offset.zero, coreRadius * 0.5, _strokePaint);
        canvas.drawCircle(
          Offset(coreRadius * 0.18, -coreRadius * 0.05),
          coreRadius * 0.12,
          _fillPaint,
        );
        break;
      case 10:
        for (int i = 0; i < 3; i++) {
          final angle = _animationTimer * 0.3 + (i / 3) * math.pi * 2;
          final tip = Offset(
            math.cos(angle) * coreRadius * 0.55,
            math.sin(angle) * coreRadius * 0.55,
          );
          final left = Offset(
            math.cos(angle + 0.6) * coreRadius * 0.2,
            math.sin(angle + 0.6) * coreRadius * 0.2,
          );
          final right = Offset(
            math.cos(angle - 0.6) * coreRadius * 0.2,
            math.sin(angle - 0.6) * coreRadius * 0.2,
          );
          _reusableOverlayPath
            ..reset()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(left.dx, left.dy)
            ..lineTo(right.dx, right.dy)
            ..close();
          canvas.drawPath(_reusableOverlayPath, _strokePaint);
        }
        break;
    }
  }

  void _drawShell(Canvas canvas, double radius, Color color, double opacity,
      bool allowBlur) {
    _shellPaint.color = color.withOpacity(opacity * 0.3);
    _shellPaint.style = PaintingStyle.stroke;
    _shellPaint.strokeWidth = 2;
    _shellPaint.maskFilter =
        (allowBlur && !Enemy.lowFx) ? _blur(true, 5) : null;

    final shellPath = _createTypeLayerPath(radius * 0.9, 1);
    canvas.drawPath(shellPath, _shellPaint);
  }

  void _drawArmorPlates(
      Canvas canvas, double radius, Color color, double opacity) {
    // Determine plate alpha based on speed (fast = less armor, slow = more armor)
    final plateAlpha =
        type.speedMult > 1.2 ? 0.45 : (type.healthMult > 2.0 ? 0.95 : 0.6);
    _platePaint.color = color.withOpacity(opacity * plateAlpha);
    _platePaint.style = PaintingStyle.fill;

    // Plate count based on size/health
    final plateCount =
        type.healthMult > 2.5 ? 6 : (type.healthMult > 1.5 ? 5 : 4);

    // Plate distance based on size
    final plateDist = radius * (0.85 + type.sizeMult * 0.1);

    // Plate size based on health multiplier
    final plateSize =
        radius * (0.18 + type.healthMult * 0.05).clamp(0.18, 0.35);

    for (int i = 0; i < plateCount; i++) {
      canvas.save();
      final angle = (i * 2 * math.pi / plateCount) + (_orbitalRotation * 0.5);
      canvas.rotate(angle);

      _reusableOverlayPath.reset();
      // Draw plate shape based on enemy characteristics
      if (type.healthMult > 2.0) {
        // Heavy/tank enemies get rectangular plates
        _reusableOverlayPath.addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(plateDist, 0),
            width: plateSize * 1.4,
            height: plateSize * 0.6,
          ),
          Radius.circular(plateSize * 0.2),
        ));
      } else if (type.speedMult > 1.2) {
        // Fast enemies get pointed/aggressive plates
        final jag =
            plateSize * (0.25 + 0.1 * math.sin(_animationTimer * 6 + i));
        _reusableOverlayPath.moveTo(plateDist, -plateSize);
        _reusableOverlayPath.lineTo(plateDist + plateSize * 0.6, -jag);
        _reusableOverlayPath.lineTo(plateDist + plateSize * 0.9, 0);
        _reusableOverlayPath.lineTo(plateDist + plateSize * 0.6, jag);
        _reusableOverlayPath.lineTo(plateDist, plateSize);
        _reusableOverlayPath.close();
      } else if (type.isPhantom) {
        // Phantom/stealth enemies get thin triangular plates
        _reusableOverlayPath.moveTo(plateDist, -plateSize);
        _reusableOverlayPath.lineTo(plateDist + plateSize * 0.5, 0);
        _reusableOverlayPath.lineTo(plateDist, plateSize);
        _reusableOverlayPath.close();
      } else {
        // Default triangular plates
        _reusableOverlayPath.moveTo(plateDist, -plateSize * 0.6);
        _reusableOverlayPath.lineTo(plateDist + plateSize * 0.9, 0);
        _reusableOverlayPath.lineTo(plateDist, plateSize * 0.6);
        _reusableOverlayPath.close();
      }

      canvas.drawPath(_reusableOverlayPath, _platePaint);
      canvas.restore();
    }
  }

  void _renderSilhouetteAccents(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    if (Enemy.lowFx || Enemy.forceLowFx) return;

    final accent = _worldEdgeColor;
    _strokePaint
      ..color = accent.withOpacity(0.25 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = _blur(allowBlur, 2);

    if (type.isPhantom) {
      final ring = Rect.fromCircle(center: Offset.zero, radius: radius * 0.75);
      final base = _animationTimer * 0.8;
      for (int i = 0; i < 3; i++) {
        canvas.drawArc(
            ring, base + i * 2.1, math.pi * 0.6, false, _strokePaint);
      }
      _strokePaint.maskFilter = null;
      return;
    }

    if (type.healthMult >= 2.0) {
      _fillPaint
        ..color = accent.withOpacity(0.16 * opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = null;
      final plateW = radius * 0.34;
      final plateH = radius * 0.7;
      final plateR = Radius.circular(radius * 0.12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(-radius * 0.72, 0),
            width: plateW,
            height: plateH,
          ),
          plateR,
        ),
        _fillPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(radius * 0.72, 0),
            width: plateW,
            height: plateH,
          ),
          plateR,
        ),
        _fillPaint,
      );
      canvas.drawLine(
        Offset(-radius * 0.85, -radius * 0.35),
        Offset(-radius * 0.55, -radius * 0.15),
        _strokePaint,
      );
      canvas.drawLine(
        Offset(radius * 0.85, -radius * 0.35),
        Offset(radius * 0.55, -radius * 0.15),
        _strokePaint,
      );
      _strokePaint.maskFilter = null;
      return;
    }

    if (type.speedMult >= 1.3) {
      final dir = movementDirection;
      final angle = math.atan2(dir.y, dir.x);
      final finLen = radius * 0.9;
      final finWidth = radius * 0.22;
      canvas.save();
      canvas.rotate(angle);

      _reusableOverlayPath
        ..reset()
        ..moveTo(-radius * 0.1, -finWidth)
        ..lineTo(finLen, 0)
        ..lineTo(-radius * 0.1, finWidth)
        ..close();
      canvas.drawPath(_reusableOverlayPath, _strokePaint);

      _reusableOverlayPath
        ..reset()
        ..moveTo(-radius * 0.3, -finWidth * 0.6)
        ..lineTo(finLen * 0.65, 0)
        ..lineTo(-radius * 0.3, finWidth * 0.6)
        ..close();
      canvas.drawPath(_reusableOverlayPath, _strokePaint);

      canvas.restore();
      _strokePaint.maskFilter = null;
      return;
    }

    _strokePaint.maskFilter = null;
  }

  void _drawWorldEmblem(
      Canvas canvas, double radius, double opacity, bool allowBlur) {
    final world = type.world;
    final pulse = 0.5 + 0.5 * math.sin(_animationTimer * 2.2 + world * 0.35);
    final accent = _worldAccentColor;
    final alpha = (0.2 + 0.22 * pulse) * opacity;
    final sigilRadius = radius * 0.42;

    _strokePaint
      ..color = accent.withOpacity(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = _blur(allowBlur && !Enemy.lowFx, 2);
    _fillPaint
      ..color = accent.withOpacity(alpha * 0.28)
      ..style = PaintingStyle.fill
      ..maskFilter = null;

    switch (world) {
      case 1:
        canvas.drawLine(
          Offset(-sigilRadius * 0.8, sigilRadius * 0.2),
          Offset(0, sigilRadius * 0.5),
          _strokePaint,
        );
        canvas.drawLine(
          Offset(0, sigilRadius * 0.5),
          Offset(sigilRadius * 0.8, sigilRadius * 0.2),
          _strokePaint,
        );
        break;
      case 2:
        final arcRect =
            Rect.fromCircle(center: Offset.zero, radius: sigilRadius);
        for (int i = 0; i < 3; i++) {
          canvas.drawArc(
            arcRect,
            _animationTimer * 0.6 + i * 2.05,
            math.pi / 2.8,
            false,
            _strokePaint,
          );
        }
        break;
      case 3:
        for (int i = -1; i <= 1; i++) {
          final y = i * sigilRadius * 0.35;
          canvas.drawLine(
            Offset(-sigilRadius * 0.9, y),
            Offset(sigilRadius * 0.9, y),
            _strokePaint,
          );
        }
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: sigilRadius * 0.35,
            height: sigilRadius * 0.35,
          ),
          _fillPaint,
        );
        break;
      case 4:
        _reusableOverlayPath
          ..reset()
          ..moveTo(-sigilRadius * 0.1, -sigilRadius * 0.9)
          ..lineTo(sigilRadius * 0.18, -sigilRadius * 0.18)
          ..lineTo(sigilRadius * 0.02, -sigilRadius * 0.18)
          ..lineTo(sigilRadius * 0.25, sigilRadius * 0.85);
        canvas.drawPath(_reusableOverlayPath, _strokePaint);
        break;
      case 5:
        _reusableOverlayPath
          ..reset()
          ..moveTo(0, -sigilRadius * 0.95)
          ..lineTo(sigilRadius * 0.65, 0)
          ..lineTo(0, sigilRadius * 0.95)
          ..lineTo(-sigilRadius * 0.65, 0)
          ..close();
        canvas.drawPath(_reusableOverlayPath, _strokePaint);
        canvas.drawLine(
          Offset(0, -sigilRadius * 0.95),
          Offset(0, sigilRadius * 0.95),
          _strokePaint,
        );
        break;
      case 6:
        final r = sigilRadius * 0.9;
        final c = sigilRadius * 0.38;
        canvas.drawLine(Offset(-r, -r), Offset(-c, -r), _strokePaint);
        canvas.drawLine(Offset(-r, -r), Offset(-r, -c), _strokePaint);
        canvas.drawLine(Offset(r, -r), Offset(c, -r), _strokePaint);
        canvas.drawLine(Offset(r, -r), Offset(r, -c), _strokePaint);
        canvas.drawLine(Offset(-r, r), Offset(-c, r), _strokePaint);
        canvas.drawLine(Offset(-r, r), Offset(-r, c), _strokePaint);
        canvas.drawLine(Offset(r, r), Offset(c, r), _strokePaint);
        canvas.drawLine(Offset(r, r), Offset(r, c), _strokePaint);
        break;
      case 7:
        canvas.drawLine(
          Offset(-sigilRadius * 0.95, 0),
          Offset(sigilRadius * 0.95, 0),
          _strokePaint,
        );
        canvas.drawLine(
          Offset(0, -sigilRadius * 0.95),
          Offset(0, sigilRadius * 0.95),
          _strokePaint,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: sigilRadius * 1.05,
            height: sigilRadius * 1.05,
          ),
          _strokePaint,
        );
        break;
      case 8:
        final arcRect =
            Rect.fromCircle(center: Offset.zero, radius: sigilRadius);
        final baseAngle = _animationTimer * 0.7;
        canvas.drawArc(arcRect, baseAngle, math.pi * 0.95, false, _strokePaint);
        canvas.drawArc(
            arcRect, baseAngle + math.pi, math.pi * 0.55, false, _strokePaint);
        break;
      case 9:
        canvas.drawCircle(Offset.zero, sigilRadius * 0.78, _strokePaint);
        _hullPaint
          ..color = Colors.black.withOpacity(alpha * 0.7)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(sigilRadius * 0.28, -sigilRadius * 0.03),
          sigilRadius * 0.5,
          _hullPaint,
        );
        break;
      case 10:
        final spin = _animationTimer * 0.28;
        for (int i = 0; i < 3; i++) {
          final angle = spin + (i / 3) * math.pi * 2;
          final tip = Offset(
            math.cos(angle) * sigilRadius * 0.95,
            math.sin(angle) * sigilRadius * 0.95,
          );
          final left = Offset(
            math.cos(angle + 0.55) * sigilRadius * 0.35,
            math.sin(angle + 0.55) * sigilRadius * 0.35,
          );
          final right = Offset(
            math.cos(angle - 0.55) * sigilRadius * 0.35,
            math.sin(angle - 0.55) * sigilRadius * 0.35,
          );
          _reusableOverlayPath
            ..reset()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(left.dx, left.dy)
            ..lineTo(right.dx, right.dy)
            ..close();
          canvas.drawPath(_reusableOverlayPath, _strokePaint);
        }
        break;
    }

    _strokePaint.maskFilter = null;
  }

  void _drawDataAura(Canvas canvas, double radius, double opacity) {
    final t = _animationTimer;
    _bitPaint
      ..color = type.color.withOpacity(opacity * 0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = null;
    _circuitPaint
      ..color = type.color.withOpacity(opacity * 0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..maskFilter = null;

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - _orbitalRotation;
      final dist = radius * 1.4 + 4 * math.sin(t * 3 + i);
      final bitPos = Offset(math.cos(angle) * dist, math.sin(angle) * dist);

      canvas.drawRect(
        Rect.fromCenter(center: bitPos, width: 3, height: 3),
        _bitPaint,
      );

      // Connect to center with thin line
      if (healthPercent > 0.8) {
        canvas.drawLine(
          Offset.zero,
          bitPos,
          _circuitPaint,
        );
      }
    }
  }

  void _renderPlasmaSmoke(Canvas canvas, double radius, double opacity) {
    for (final particle in _plasmaParticles) {
      final size = particle.size * 1.4;
      final angle = (_animationTimer * 0.8 +
          particle.position.x * 0.02 +
          particle.position.y * 0.02);
      canvas.save();
      canvas.translate(particle.position.x, particle.position.y);
      canvas.rotate(angle);
      _particlePaint
        ..color = particle.color.withOpacity(particle.opacity * opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: size * 1.2, height: size * 0.5),
        _particlePaint,
      );
      canvas.restore();
    }
  }

  Path _createTypeLayerPath(double radius, int layer) {
    // Reuse static path to avoid per-frame allocations
    _reusableLayerPath.reset();

    // Specialized geometry based on enemy characteristics
    if (type.healthMult > 2.0) {
      // Heavy/tank enemies - octagonal/boxy shape
      final inset = radius * 0.35;
      _reusableLayerPath.moveTo(radius, -inset);
      _reusableLayerPath.lineTo(radius * 0.65, -radius);
      _reusableLayerPath.lineTo(-radius * 0.65, -radius);
      _reusableLayerPath.lineTo(-radius, -inset);
      _reusableLayerPath.lineTo(-radius, inset);
      _reusableLayerPath.lineTo(-radius * 0.65, radius);
      _reusableLayerPath.lineTo(radius * 0.65, radius);
      _reusableLayerPath.lineTo(radius, inset);
      _reusableLayerPath.close();
    } else if (type.speedMult > 1.2) {
      // Fast enemies - polygon with wobble
      final sides = 4 + layer;
      final wobble = math.sin(_animationTimer * 5 + layer) * 0.08;
      for (int i = 0; i < sides; i++) {
        final angle = (i * 2 * math.pi / sides) + (layer * math.pi / sides);
        final scale = 1.0 + (i.isEven ? wobble : -wobble);
        final point = Offset(
            math.cos(angle) * radius * scale, math.sin(angle) * radius * scale);
        if (i == 0)
          _reusableLayerPath.moveTo(point.dx, point.dy);
        else
          _reusableLayerPath.lineTo(point.dx, point.dy);
      }
      _reusableLayerPath.close();
    } else if (type.isPhantom) {
      // Phantom/stealth enemies - star shape with drift
      final points = 5 + layer;
      for (int i = 0; i < points * 2; i++) {
        final r = i.isEven ? radius : radius * 0.6;
        final drift = math.sin(_animationTimer * 2 + i) * radius * 0.05;
        final angle = i * math.pi / points + _animationTimer * 0.8;
        final point = Offset(
            math.cos(angle) * (r + drift), math.sin(angle) * (r + drift));
        if (i == 0)
          _reusableLayerPath.moveTo(point.dx, point.dy);
        else
          _reusableLayerPath.lineTo(point.dx, point.dy);
      }
      _reusableLayerPath.close();
    } else {
      // Default - arrow/diamond shape
      _reusableLayerPath.moveTo(radius * 0.9, 0);
      _reusableLayerPath.lineTo(radius * 0.3, -radius * 0.55);
      _reusableLayerPath.lineTo(-radius * 0.4, -radius * 0.4);
      _reusableLayerPath.lineTo(-radius * 0.75, 0);
      _reusableLayerPath.lineTo(-radius * 0.4, radius * 0.4);
      _reusableLayerPath.lineTo(radius * 0.3, radius * 0.55);
      _reusableLayerPath.close();
    }
    return _reusableLayerPath;
  }

  Color _getHealthColor() {
    if (healthPercent > 0.6) {
      return const Color(0xFF00FF88); // Neon green
    } else if (healthPercent > 0.3) {
      return const Color(0xFFFFFF00); // Neon yellow
    } else {
      return const Color(0xFFFF0066); // Neon red/magenta
    }
  }

  void _move(double dt) {
    if (path.isEmpty || _currentTargetIndex >= path.length) {
      onReachBase?.call(this);
      removeFromParent();
      return;
    }

    final target = path[_currentTargetIndex];
    final moveDist = speed * dt;
    final dx = target.x - position.x;
    final dy = target.y - position.y;
    final distanceSq = (dx * dx) + (dy * dy);
    if (distanceSq <= 0.000001) {
      position.setFrom(target);
      _currentTargetIndex++;
      return;
    }

    if ((moveDist * moveDist) >= distanceSq) {
      position.setFrom(target);
      _currentTargetIndex++;
    } else {
      final invDistance = 1.0 / math.sqrt(distanceSq);
      position.x += dx * invDistance * moveDist;
      position.y += dy * invDistance * moveDist;
    }
  }
}

/// Walking visual style categories for different enemy types
enum _WalkStyle {
  legs, // Runner-style fast legs
  tendrils, // Energy tendrils
  stomp, // Heavy footsteps
  wisps, // Ghostly wisps
  glitch, // Dimensional glitch effects
  electric, // Electric arcs and sparks
  crystal, // Floating crystal shards
  mechanical, // Mechanical pistons
  digital, // Binary data streams
  storm, // Wind and lightning
  void_, // Dark void tendrils
  omega, // Ultimate combined effects
}

/// Body shape categories for different enemy types
enum _BodyShape {
  dart, // Aerodynamic dart (fast types)
  fractured, // Fractured polygon (glitchy types)
  armored, // Beveled armor (tank types)
  star, // Phase-shifted star (phantom types)
  hexagon, // Hexagonal (crystal types)
  mechanical, // Mechanical box (robot types)
  electric, // Spiky electric (plasma types)
  storm, // Swirling storm shape
  void_, // Irregular dark shape
  omega, // Complex ultimate shape
}

/// Eye style categories for terrifying enemy visuals
enum _EyeStyle {
  predator, // Single menacing slit eye
  hive, // Multiple compound eyes
  void_, // Empty sockets of darkness
  burning, // Eyes of flame
  crystal, // Faceted gem eyes
  mechanical, // Cold robotic sensors
  corrupted, // Glitching digital eyes
  abyssal, // Infinite depth void eyes
}

class _CircuitSegment {
  _CircuitSegment(this.start, this.end);

  final Offset start;
  final Offset end;
}

class _NoiseBit {
  _NoiseBit({
    required this.offset,
    required this.phase,
    required this.size,
  });

  final Offset offset;
  final double phase;
  final double size;
}

/// Particle emitted when enemy takes damage
class _DamageParticle {
  static const int _maxPoolSize = 200;
  static final List<_DamageParticle> _pool = [];

  static _DamageParticle obtain({
    required double angle,
    required double speed,
    required double size,
    required double lifetime,
  }) {
    if (_pool.isNotEmpty) {
      final particle = _pool.removeLast();
      particle.reset(
        angle: angle,
        speed: speed,
        size: size,
        lifetime: lifetime,
      );
      return particle;
    }
    return _DamageParticle._internal(
      angle: angle,
      speed: speed,
      size: size,
      lifetime: lifetime,
    );
  }

  _DamageParticle._internal({
    required this.angle,
    required this.speed,
    required this.size,
    required this.lifetime,
  })  : distance = 0,
        _timer = 0;

  void reset({
    required double angle,
    required double speed,
    required double size,
    required double lifetime,
  }) {
    this.angle = angle;
    this.speed = speed;
    this.size = size;
    this.lifetime = lifetime;
    distance = 0;
    _timer = 0;
  }

  void recycle() {
    if (_pool.length < _maxPoolSize) {
      _pool.add(this);
    }
  }

  double angle;
  double speed;
  double size;
  double lifetime;

  double distance;
  double _timer;

  bool get isActive => _timer < lifetime;
  double get progress => (_timer / lifetime).clamp(0.0, 1.0);
  double get alpha => (1 - progress).clamp(0.0, 1.0);

  void update(double dt) {
    _timer += dt;
    distance += speed * dt * (1 - progress * 0.5);
  }
}

class _DataBit {
  static const int _maxPoolSize = 200;
  static final List<_DataBit> _pool = [];

  static _DataBit obtain({
    required Vector2 position,
    required Vector2 velocity,
    required Color color,
    required double size,
    required double rotation,
    required double lifetime,
  }) {
    if (_pool.isNotEmpty) {
      final bit = _pool.removeLast();
      bit.reset(
        position: position,
        velocity: velocity,
        color: color,
        size: size,
        rotation: rotation,
        lifetime: lifetime,
      );
      return bit;
    }
    return _DataBit._internal(
      position: position,
      velocity: velocity,
      color: color,
      size: size,
      rotation: rotation,
      lifetime: lifetime,
    );
  }

  _DataBit._internal({
    required Vector2 position,
    required Vector2 velocity,
    required this.color,
    required this.size,
    required this.rotation,
    required this.lifetime,
  })  : position = position.clone(),
        velocity = velocity.clone(),
        _timer = 0;

  void reset({
    required Vector2 position,
    required Vector2 velocity,
    required Color color,
    required double size,
    required double rotation,
    required double lifetime,
  }) {
    this.position.setFrom(position);
    this.velocity.setFrom(velocity);
    this.color = color;
    this.size = size;
    this.rotation = rotation;
    this.lifetime = lifetime;
    _timer = 0;
  }

  void recycle() {
    if (_pool.length < _maxPoolSize) {
      _pool.add(this);
    }
  }

  final Vector2 position;
  final Vector2 velocity;
  Color color;
  double size;
  double rotation;
  double lifetime;
  double _timer;

  bool get isActive => _timer < lifetime;
  double get alpha => (1 - _timer / lifetime).clamp(0.0, 1.0);

  void update(double dt) {
    _timer += dt;
    position.add(velocity * dt);
    velocity.y += 150 * dt; // Gravity
  }
}

class _PlasmaParticle {
  static const int _maxPoolSize = 120;
  static final List<_PlasmaParticle> _pool = [];

  static _PlasmaParticle obtain({
    required Vector2 position,
    required Vector2 velocity,
    required Color color,
  }) {
    if (_pool.isNotEmpty) {
      final particle = _pool.removeLast();
      particle.reset(
        position: position,
        velocity: velocity,
        color: color,
      );
      return particle;
    }
    return _PlasmaParticle._internal(
      position: position,
      velocity: velocity,
      color: color,
    );
  }

  _PlasmaParticle._internal({
    required Vector2 position,
    required Vector2 velocity,
    required this.color,
  })  : position = position.clone(),
        velocity = velocity.clone();

  void reset({
    required Vector2 position,
    required Vector2 velocity,
    required Color color,
  }) {
    this.position.setFrom(position);
    this.velocity.setFrom(velocity);
    this.color = color;
    isActive = true;
    opacity = 0.8;
    size = 4.0;
  }

  void recycle() {
    if (_pool.length < _maxPoolSize) {
      _pool.add(this);
    }
  }

  Vector2 position;
  final Vector2 velocity;
  Color color;
  bool isActive = true;
  double opacity = 0.8;
  double size = 4.0;

  void update(double dt) {
    position += velocity * dt;
    opacity -= dt * 1.2;
    size -= dt * 2;
    if (opacity <= 0 || size <= 0) isActive = false;
  }
}

/// Particle used in spawn/materialize effect
class _SpawnParticle {
  _SpawnParticle({
    required this.angle,
    required this.distance,
    required this.speed,
    required this.size,
  });

  final double angle;
  double distance;
  final double speed;
  final double size;

  void update(double dt) {
    distance -= speed * dt;
  }
}

/// Types of status icons that can be displayed above enemies
enum _StatusIconType {
  slow, // Snowflake - blue
  burn, // Flame - orange/red
  shield, // Hexagon - cyan
  boost, // Arrow up - green
  stun, // Lightning - yellow
}

/// Data container for status icon rendering
class _StatusIconData {
  const _StatusIconData({
    required this.type,
    required this.color,
    required this.duration,
    required this.maxDuration,
  });

  final _StatusIconType type;
  final Color color;
  final double duration;
  final double maxDuration;
}
