import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'enemy.dart';
import '../managers/enemy_manager.dart';
import '../bored_games_game.dart';
import '../../ui/theme/neon_theme.dart';
import '../../models/upgrade_data.dart';

/// Targeting modes for towers
enum TargetMode { first, last, strongest, weakest, closest }

/// Tower type definitions with stats
enum TowerType {
  pulseArcher(
    name: 'Pulse Archer',
    damage: 15,
    fireRate: 2.0, // shots per second
    range: 160,
    cost: 50,
    color: Color(0xFF00FFFF), // Cyan
    projectileSpeed: 400,
    slowAmount: 0,
    slowDuration: 0,
    canDetectPhantom: false,
  ),
  circuitCannon(
    name: 'Circuit Cannon',
    damage: 50,
    fireRate: 0.5,
    range: 140,
    cost: 100,
    color: Color(0xFFFF00FF), // Magenta
    projectileSpeed: 250,
    slowAmount: 0,
    slowDuration: 0,
    canDetectPhantom: false,
  ),
  phaseMage(
    name: 'Phase Mage',
    damage: 25,
    fireRate: 1.2,
    range: 200,
    cost: 80,
    color: Color(0xFF9C27B0), // Purple
    projectileSpeed: 350,
    slowAmount: 0.5, // 50% slow
    slowDuration: 1.5,
    canDetectPhantom: true, // Can detect and reveal phantom enemies!
  ),
  glimmerField(
    name: 'Glimmer Field',
    damage: 8,
    fireRate: 4.0, // Very fast
    range: 120,
    cost: 120,
    color: Color(0xFFFFEB3B), // Yellow
    projectileSpeed: 500,
    slowAmount: 0.3, // 70% slow
    slowDuration: 0.5,
    canDetectPhantom: false,
  ),
  ionSniper(
    name: 'Ion Sniper',
    damage: 180,
    fireRate: 0.4,
    range: 300,
    cost: 250,
    color: Color(0xFF00E5FF),
    projectileSpeed: 800,
  ),
  teslaTerminal(
    name: 'Tesla Terminal',
    damage: 12,
    fireRate: 3.5,
    range: 150,
    cost: 180,
    color: Color(0xFFFFFF00),
    projectileSpeed: 0, // Instant hit (lightning)
  ),
  resonanceSiphon(
    name: 'Resonance Siphon',
    damage: 0,
    fireRate: 1.0,
    range: 100,
    cost: 150,
    color: Color(0xFFFF0066),
    projectileSpeed: 0,
  ),
  neuralDisruptor(
    name: 'Neural Disruptor',
    damage: 5,
    fireRate: 2.0,
    range: 130,
    cost: 200,
    color: Color(0xFF00FF00),
    projectileSpeed: 450,
  ),
  plasmaBubble(
    name: 'Plasma Bubble',
    damage: 35,
    fireRate: 0.8,
    range: 175,
    cost: 175,
    color: Color(0xFFE040FB), // Purple/Pink plasma
    projectileSpeed: 280,
    slowAmount: 0.4, // 40% slow on pop
    slowDuration: 2.0,
    canDetectPhantom: false,
  );

  const TowerType({
    required this.name,
    required this.damage,
    required this.fireRate,
    required this.range,
    required this.cost,
    required this.color,
    required this.projectileSpeed,
    this.slowAmount = 0,
    this.slowDuration = 0,
    this.canDetectPhantom = false,
  });

  final String name;
  final double damage;
  final double fireRate;
  final double range;
  final int cost;
  final Color color;
  final double projectileSpeed;
  final double slowAmount; // 0 = no slow, 0.5 = 50% slow
  final double slowDuration;
  final bool canDetectPhantom; // Whether this tower can see and attack phantom enemies

  /// Whether this tower applies slow on hit
  bool get appliesSlow => slowAmount > 0 && slowDuration > 0;
}

/// Callback for when tower fires
typedef TowerFireCallback = void Function(
    Tower tower, Enemy target, Vector2 targetPos);

class Tower extends PositionComponent with HasGameRef<BoredGamesGame> {
  static bool lowFx = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC PAINT OBJECTS FOR HYPER-OPTIMIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  // Outer glow and effects
  static final Paint _outerGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _pulseRingPaint = Paint();
  static final Paint _circuitGearPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _phaseArcPaint = Paint()
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _glowDotPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _runePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _sparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _fieldPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _chargePaint = Paint();
  static final Paint _vibrationPaint = Paint();
  static final Paint _wavePaint = Paint();
  static final Paint _noisePaint = Paint();

  // Base and mega-tower paints
  static final Paint _basePaint = Paint();
  static final Paint _baseBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _dotTrimPaint = Paint();
  static final Paint _panelTrimPaint = Paint();

  // Orbit particle paints
  static final Paint _particleGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _particleCorePaint = Paint();

  // Type decoration paints
  static final Paint _decorArcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _decorPlatePaint = Paint();
  static final Paint _decorCirclePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _decorLinePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
  static final Paint _decorPinPaint = Paint()..strokeWidth = 2;
  static final Paint _decorCoilPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _decorTrianglePaint = Paint();

  // Energy core paints
  static final Paint _coreOuterGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _coreGradientPaint = Paint();
  static final Paint _coreCenterPaint = Paint();
  static final Paint _coreArmPaint = Paint()..strokeWidth = 1.5;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATED ENERGY CORE PAINTS (6 Layers)
  // ═══════════════════════════════════════════════════════════════════════════
  // Layer 1: Inner core sphere with pulsing glow
  static final Paint _energyCoreInnerGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _energyCoreSpherePaint = Paint();
  static final Paint _energyCoreBrightCenterPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  // Layer 2: Rotating energy rings
  static final Paint _energyCoreRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _energyCoreRingGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  // Layer 3: Orbiting energy particles
  static final Paint _energyCoreParticlePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _energyCoreParticleTrailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  // Layer 4: Energy conduit lines from core to edges
  static final Paint _energyCoreConduitPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _energyCoreConduitGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  static final Paint _energyCoreConduitNodePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  // Layer 5: Plasma tendrils emanating from core
  static final Paint _energyCoreTendrilPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _energyCoreTendrilGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  // Layer 6: Core intensity pulse based on charge
  static final Paint _energyCoreIntensityPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _energyCoreFlashPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  // Reusable path for energy core shapes
  static final Path _energyCorePath = Path();

  // Turret head paints
  static final Paint _turretFillPaint = Paint();
  static final Paint _turretAccentPaint = Paint();
  static final Paint _turretStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _turretProngPaint = Paint();
  static final Paint _turretVentPaint = Paint();
  static final Paint _turretPrismPaint = Paint();
  static final Paint _turretPetalPaint = Paint();
  static final Paint _turretFunnelPaint = Paint();

  // Targeting paints
  static final Paint _targetLensFillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _targetLensStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _targetLineGlowPaint = Paint()
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _targetLineCorePaint = Paint()..strokeWidth = 1.5;
  static final Paint _targetDashPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _targetReticlePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _targetCrosshairPaint = Paint()..strokeWidth = 1;

  // ═══════════════════════════════════════════════════════════════════════
  // HOLOGRAPHIC TARGETING RETICLE PAINTS
  // ═══════════════════════════════════════════════════════════════════════
  static final Paint _holoReticleOuterPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _holoReticleCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _holoReticleFillPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _holoReticleArcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _holoReticleDataPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  static final Paint _holoReticleMarkerPaint = Paint();
  static final Paint _holoReticleScanPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _holoReticleBeamPaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Paint _holoReticleHexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.6;
  static final Path _holoReticlePath = Path();

  // Charge indicator paints
  static final Paint _chargeGlowArcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _chargeCoreArcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _chargeCompletePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  // ═══════════════════════════════════════════════════════════════════════
  // ENERGY ABSORPTION PARTICLE PAINTS
  // ═══════════════════════════════════════════════════════════════════════
  static final Paint _absorptionOuterGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _absorptionParticlePaint = Paint();
  static final Paint _absorptionTrailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _absorptionRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _absorptionVortexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _absorptionSparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _absorptionCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _absorptionBeamPaint = Paint()
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _absorptionPulsePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _absorptionWispPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;

  // ═══════════════════════════════════════════════════════════════════════════
  // HEAT DISTORTION EFFECT PAINTS
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _heatShimmerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _heatWavePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _heatGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _heatSparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _heatRipplePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Path _heatPath = Path();

  // ═══════════════════════════════════════════════════════════════════════════
  // ICE CRYSTAL EFFECT PAINTS (Freeze Tower - Phase Mage)
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _iceCrystalPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.bevel;
  static final Paint _iceCrystalFillPaint = Paint();
  static final Paint _iceGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _iceShardPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  static final Paint _iceSparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _iceFrostPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _iceAuraPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _iceSnowflakePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  static final Path _icePath = Path();

  // ═══════════════════════════════════════════════════════════════════════════
  // ENERGY WEB EFFECT PAINTS (Slow Towers - Phase Mage, Glimmer Field)
  // ═══════════════════════════════════════════════════════════════════════════
  // Layer 1: Central hub glow
  static final Paint _webHubGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _webHubCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  // Layer 2: Radial web strands
  static final Paint _webStrandPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _webStrandGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  // Layer 3: Concentric connecting rings
  static final Paint _webRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  // Layer 4: Energy pulses traveling along strands
  static final Paint _webPulsePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _webPulseCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
  // Layer 5: Trapped enemy highlighting
  static final Paint _webTrapGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _webTrapRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  // Layer 6: Web shimmer/flicker
  static final Paint _webShimmerPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  // Layer 7: Strand tension lines to trapped enemies
  static final Paint _webTensionPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _webTensionGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  // Reusable path for web shapes
  static final Path _webPath = Path();
  // Random for web effects
  static final math.Random _webRandom = math.Random();

  // ═══════════════════════════════════════════════════════════════════════════
  // VORTEX/BLACK HOLE EFFECT PAINTS (Resonance Siphon)
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _vortexCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _vortexRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _vortexSpiralPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  static final Paint _vortexParticlePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _vortexGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _vortexEventHorizonPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _vortexArcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  static final Paint _vortexDistortPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Path _vortexPath = Path();
  static final math.Random _vortexRandom = math.Random();

  // ═══════════════════════════════════════════════════════════════════════════
  // ORBITAL SATELLITE EFFECT PAINTS (Support Tower - Resonance Siphon)
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _satelliteBodyPaint = Paint();
  static final Paint _satelliteGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _satelliteCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _satelliteOrbitPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _satelliteTetherPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _satelliteDataPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _satellitePulsePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _satelliteHoloPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  static final Paint _satelliteStreamPaint = Paint()
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  static final Path _satellitePath = Path();

  // Muzzle flash paints
  static final Paint _flashConePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _flashCirclePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _flashGenericPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _muzzleParticlePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  // Range indicator paints
  static final Paint _rangePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _rangeCornerPaint = Paint();

  // Type symbol paints
  static final Paint _symbolPaint = Paint()
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  static final Paint _symbolFillPaint = Paint();

  // Reusable Offset objects for loops
  static Offset _tempOffset1 = Offset.zero;
  static Offset _tempOffset2 = Offset.zero;
  static Offset _tempOffset3 = Offset.zero;
  static Offset _tempOffset4 = Offset.zero;

  // Cached Rects for frequent use
  static Rect _tempRect = Rect.zero;

  // Reusable Path objects
  static final Path _tempPath1 = Path();
  static final Path _tempPath2 = Path();
  static final Path _absorptionPath1 = Path();
  static final Path _absorptionPath2 = Path();
  static final Path _absorptionVortexPath = Path();

  // ═══════════════════════════════════════════════════════════════════════════
  // ENHANCED GRAPHICS PAINTS
  // ═══════════════════════════════════════════════════════════════════════════

  // Holographic grid overlay
  static final Paint _holoGridPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Paint _holoScanlinePaint = Paint();

  // Energy conduits on base edges
  static final Paint _conduitGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _conduitCorePaint = Paint()..strokeWidth = 1.5;
  static final Paint _conduitPulsePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  // Enhanced plasma core effects
  static final Paint _plasmaRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _plasmaWispPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _plasmaSwirlPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  // Boost/Shield effects
  static final Paint _shieldGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _shieldRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _shieldHexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  // Data stream effects
  static final Paint _dataStreamPaint = Paint()
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;

  // ═══════════════════════════════════════════════════════════════════════════
  // DYNAMIC LIGHTING/GLOW PAINTS (Activity-based)
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _dynamicAmbientGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  static final Paint _dynamicInnerGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _dynamicChargeGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _dynamicFireFlashPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
  static final Paint _dynamicTargetPulsePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _dynamicEnergyRayPaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _dynamicCorePulsePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _dynamicHaloRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _dynamicSparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _dynamicGroundGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
  static final Paint _dynamicArcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  static final Paint _dynamicFlareRayPaint = Paint()
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Path _dynamicLightingPath = Path();

  // ═══════════════════════════════════════════════════════════════════════════
  // ENERGY WAVE RIPPLE PAINTS
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _rippleOuterGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _rippleCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _rippleInnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _rippleChromaRedPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..blendMode = BlendMode.plus
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _rippleChromaCyanPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..blendMode = BlendMode.plus
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _rippleSparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _rippleArcSegmentPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _rippleHexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _rippleDataPaint = Paint()
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  static final Paint _rippleDistortionPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Path _ripplePath = Path();

  // ═══════════════════════════════════════════════════════════════════════════
  // VOLUMETRIC ENERGY BEAM PAINTS
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _beamCorePaint = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Paint _beamInnerGlowPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _beamOuterGlowPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _beamVolumetricRayPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _beamSparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _beamPulsePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _beamHeatDistortPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _beamAuraPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Path _beamPath = Path();
  static final math.Random _beamRandom = math.Random();

  // ═══════════════════════════════════════════════════════════════════════════
  // ELECTRIC ARC CONNECTION PAINTS (Between nearby towers)
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _electricArcGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _electricArcCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _electricArcInnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  static final Paint _electricArcNodePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _electricArcSparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _electricArcBranchPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  static final Paint _electricArcFlashPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Path _electricArcPath = Path();
  static final math.Random _electricArcRandom = math.Random();
  static const double _electricArcMaxDistance = 180.0; // Max distance for arcs
  static const double _electricArcMinDistance = 50.0; // Min distance for arcs

  // ═══════════════════════════════════════════════════════════════════════════
  // DYNAMIC SHADOW PAINTS
  // ═══════════════════════════════════════════════════════════════════════════
  // Layer 1: Main shadow silhouette
  static final Paint _shadowMainPaint = Paint()
    ..style = PaintingStyle.fill;
  // Layer 2: Soft shadow edge with blur
  static final Paint _shadowSoftEdgePaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  // Layer 3: Secondary ambient shadow (lighter, wider)
  static final Paint _shadowAmbientPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
  // Layer 4: Ground contact shadow (darker at base)
  static final Paint _shadowGroundContactPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  // Layer 5: Shadow animation pulse
  static final Paint _shadowPulsePaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  // Layer 6: Neon light bounce (colored shadow edges)
  static final Paint _shadowNeonBouncePaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  // Reusable path for shadow shapes
  static final Path _shadowPath = Path();

  // ═══════════════════════════════════════════════════════════════════════════
  // DRONE SWARM EFFECT PAINTS (Neural Disruptor)
  // ═══════════════════════════════════════════════════════════════════════════
  // Layer 1: Drone body paint
  static final Paint _droneBodyPaint = Paint();
  static final Paint _droneBodyGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  // Layer 2: Drone engine glow trails
  static final Paint _droneEngineGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _droneEngineTrailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  // Layer 3: Energy tethers between drones and tower
  static final Paint _droneTetherPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _droneTetherCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8
    ..strokeCap = StrokeCap.round;
  // Layer 4: Scanning beam from each drone
  static final Paint _droneScanBeamPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _droneScanLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  // Layer 5: Data link particles between drones
  static final Paint _droneDataLinkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _droneDataParticlePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  // Layer 6: Drone formation pattern indicators
  static final Paint _droneFormationPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  // Layer 7: Drone body highlights and details
  static final Paint _droneHighlightPaint = Paint();
  static final Paint _droneDetailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Paint _dronePulsePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  // Reusable path for drone shapes
  static final Path _dronePath = Path();

  // ═══════════════════════════════════════════════════════════════════════════
  // RADAR SWEEP EFFECT PAINTS (for detection-type towers like neuralDisruptor)
  // ═══════════════════════════════════════════════════════════════════════════
  // Layer 1: Radar dish/antenna
  static final Paint _radarDishPaint = Paint();
  static final Paint _radarDishGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _radarDishStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  // Layer 2: Rotating sweep beam (pie slice)
  static final Paint _radarSweepPaint = Paint();
  static final Paint _radarSweepGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  // Layer 3: Concentric range circles
  static final Paint _radarRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  static final Paint _radarRingGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  // Layer 4: Detected enemy blips
  static final Paint _radarBlipPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _radarBlipCorePaint = Paint();
  static final Paint _radarBlipPulsePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  // Layer 5: Sweep trail (fading arc behind sweep line)
  static final Paint _radarTrailPaint = Paint()
    ..style = PaintingStyle.fill;
  // Layer 6: Scan line grid pattern
  static final Paint _radarGridPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Paint _radarGridNodePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
  // Layer 7: Data readout near detected enemies
  static final Paint _radarDataPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
  static final Paint _radarDataGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _radarDataLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  // Reusable path for radar shapes
  static final Path _radarPath = Path();
  // Random for radar effects
  static final math.Random _radarRandom = math.Random();

  // ═══════════════════════════════════════════════════════════════════════════
  // HOLOGRAPHIC CONSTRUCTION EFFECT PAINTS
  // ═══════════════════════════════════════════════════════════════════════════
  // Layer 1: Holographic wireframe outline
  static final Paint _constructWireframePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _constructWireframeGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  // Layer 2: Blueprint grid pattern
  static final Paint _constructGridPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Paint _constructGridNodePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  // Layer 3: Scanning line
  static final Paint _constructScanLinePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _constructScanGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  // Layer 4: Materializing particles
  static final Paint _constructParticlePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _constructParticleTrailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  // Layer 5: Data stream text effect
  static final Paint _constructDataPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
  static final Paint _constructDataGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  // Layer 6: Progress ring
  static final Paint _constructProgressBgPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _constructProgressPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _constructProgressGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  // Layer 7: Materialization flash
  static final Paint _constructFlashPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  static final Paint _constructFlashRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  // Reusable path for construction shapes
  static final Path _constructPath = Path();
  // Random for construction effects
  static final math.Random _constructRandom = math.Random();

  // ═══════════════════════════════════════════════════════════════════════════
  // DAMAGE FRACTURE EFFECT PAINTS
  // ═══════════════════════════════════════════════════════════════════════════
  // Layer 1: Main fracture lines radiating from impact points
  static final Paint _fracturePrimaryPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;
  static final Paint _fracturePrimaryGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  // Layer 2: Secondary crack branches
  static final Paint _fractureSecondaryPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..strokeCap = StrokeCap.round;
  static final Paint _fractureSecondaryGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  // Layer 3: Glowing edges (energy leaking)
  static final Paint _fractureEnergyLeakPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _fractureEnergyCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8
    ..strokeCap = StrokeCap.round;
  // Layer 4: Hexagonal stress patterns
  static final Paint _fractureHexStressPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
  static final Paint _fractureHexFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  // Layer 5: Flickering damaged sections
  static final Paint _fractureFlickerPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  // Layer 6: Sparking at crack intersections
  static final Paint _fractureSparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _fractureSparkCorePaint = Paint();
  static final Paint _fractureSparkArcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  // Reusable path for fracture shapes
  static final Path _fracturePath = Path();
  // Random for fracture effects
  static final math.Random _fractureRandom = math.Random();

  // ═══════════════════════════════════════════════════════════════════════════
  // ENERGY SIPHON BEAM PAINTS (Resonance Siphon - drains energy from enemies)
  // ═══════════════════════════════════════════════════════════════════════════
  // Layer 1: Main beam connection (wavy line between entities)
  static final Paint _siphonBeamCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  // Layer 2: Beam glow effect (blurred behind)
  static final Paint _siphonBeamGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _siphonBeamOuterGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 14
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  // Layer 3: Energy particles flowing along beam
  static final Paint _siphonParticlePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _siphonParticleCorePaint = Paint();
  static final Paint _siphonParticleTrailPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  // Layer 4: Energy accumulation at source end
  static final Paint _siphonAccumulationGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _siphonAccumulationCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _siphonAccumulationRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  // Layer 5: Drain effect at target end (dimming glow)
  static final Paint _siphonDrainGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _siphonDrainVortexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  // Layer 6: Beam pulse waves traveling along connection
  static final Paint _siphonPulseWavePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  static final Paint _siphonPulseRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  // Layer 7: Crackling electricity at connection points
  static final Paint _siphonElectricGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _siphonElectricCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  static final Paint _siphonElectricSparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  // Reusable path for siphon beam
  static final Path _siphonBeamPath = Path();
  // Random for siphon effects
  static final math.Random _siphonRandom = math.Random();
  // ═══════════════════════════════════════════════════════════════════════════

  Tower({
    required Vector2 position,
    required double size,
    this.type = TowerType.pulseArcher,
    this.targetMode = TargetMode.first,
    this.onFire,
    this.buildCost = 0,
    double damageMultiplier = 1.0,
    double rangeMultiplier = 1.0,
    double fireRateMultiplier = 1.0,
    double projectileSpeedMultiplier = 1.0,
    double slowMultiplier = 1.0,
  }) : _fireCooldown = 0,
       _animationPhase = math.Random().nextDouble() * math.pi * 2,
       _random = math.Random(),
       _damageMultiplier = damageMultiplier,
       _rangeMultiplier = rangeMultiplier,
       _fireRateMultiplier = fireRateMultiplier,
       _projectileSpeedMultiplier = projectileSpeedMultiplier,
       _slowMultiplier = slowMultiplier {
    anchor = Anchor.topLeft;
    this.position = position;
    this.size = Vector2.all(size);
    _initializeParticles();
  }

  final TowerType type;
  TargetMode targetMode;
  TowerFireCallback? onFire;
  final int buildCost;
  final math.Random _random;
  double _damageMultiplier;
  double _rangeMultiplier;
  double _fireRateMultiplier;
  double _projectileSpeedMultiplier;
  double _slowMultiplier;
  int _resonanceBoosters = 0;
  bool get _isBoosted => _isManualBoosted || _resonanceBoosters > 0;
  bool _isManualBoosted = false;

  Enemy? _currentTarget;
  Enemy? _manualTarget;
  bool _manualTargeting = false;
  double _fireCooldown;
  double _animationPhase;
  double _pulseAnimation = 0;
  double _rotationAngle = 0;
  double _chargeLevel = 0;
  bool _isFiring = false;
  double _fireFlashTimer = 0;
  final List<Enemy> _candidateEnemies = [];

  // Idle animation particles (orbiting energy)
  final List<_TowerParticle> _orbitParticles = [];
  static const int _particleCount = 6;

  // Muzzle flash particles
  final List<_MuzzleParticle> _muzzleParticles = [];
  static const int _muzzleParticleCount = 12;

  // Energy wave ripples
  final List<_EnergyWaveRipple> _energyWaveRipples = [];
  static const int _maxRipples = 8;

  // Electric arc points for Phase Mage
  final List<Offset> _arcPoints = [];

  // Energy web state for slow towers
  final List<Enemy> _slowedEnemies = [];
  double _webExpansion = 0.0; // 0.0 = contracted, 1.0 = expanded
  double _webPulsePhase = 0.0;

  // Radar sweep state for detection towers (neuralDisruptor, phaseMage)
  double _radarSweepAngle = 0.0; // Current sweep angle in radians
  final List<_RadarBlip> _radarBlips = []; // Tracked enemy blips with ping state
  static const double _radarSweepSpeed = 2.5; // Radians per second
  static const int _maxRadarBlips = 12;

  // Construction animation state
  bool _isConstructing = false;
  double _constructionProgress = 0.0; // 0.0 to 1.0
  double _constructionDuration = 2.0; // seconds
  double _constructionFlashTimer = 0.0;
  final List<_ConstructionParticle> _constructionParticles = [];
  static const int _constructionParticleCount = 24;

  // Health and damage tracking
  double _health = 100.0;
  double _maxHealth = 100.0;
  double get health => _health;
  double get maxHealth => _maxHealth;
  double get healthPercent => _health / _maxHealth;
  bool get isDamaged => _health < _maxHealth;

  // Damage fracture state
  final List<_FractureImpactPoint> _fractureImpactPoints = [];
  double _fractureFlickerTimer = 0.0;
  double _fractureSparkTimer = 0.0;
  static const int _maxFractureImpacts = 5;
  static const double _fractureFlickerSpeed = 15.0;
  static const double _fractureSparkInterval = 0.08;

  /// Apply damage to the tower
  void takeDamage(double amount) {
    _health -= amount;
    if (_health < 0) _health = 0;

    // Add impact point for fracture rendering when damaged
    if (amount > 0 && _fractureImpactPoints.length < _maxFractureImpacts) {
      final angle = _random.nextDouble() * math.pi * 2;
      final distance = size.x * 0.2 + _random.nextDouble() * size.x * 0.15;
      _fractureImpactPoints.add(_FractureImpactPoint(
        offset: Offset(math.cos(angle) * distance, math.sin(angle) * distance),
        angle: angle,
        intensity: (amount / 20.0).clamp(0.3, 1.0),
        branchCount: 2 + _random.nextInt(3),
      ));
    }
  }

  /// Heal the tower
  void heal(double amount) {
    _health += amount;
    if (_health > _maxHealth) _health = _maxHealth;

    // Remove impact points as tower heals
    if (healthPercent > 0.8 && _fractureImpactPoints.isNotEmpty) {
      _fractureImpactPoints.removeLast();
    }
  }

  /// Set tower health directly (for initialization or special effects)
  void setHealth(double health, {double? maxHealth}) {
    if (maxHealth != null) _maxHealth = maxHealth;
    _health = health.clamp(0, _maxHealth);
  }

  void _initializeParticles() {
    _orbitParticles.clear();
    for (int i = 0; i < _particleCount; i++) {
      _orbitParticles.add(_TowerParticle(
        angle: (i / _particleCount) * math.pi * 2,
        radius: 12 + _random.nextDouble() * 4,
        speed: 1.0 + _random.nextDouble() * 0.5,
        size: 1.5 + _random.nextDouble(),
        phase: _random.nextDouble() * math.pi * 2,
      ));
    }

    // Initialize muzzle particles
    _muzzleParticles.clear();
    for (int i = 0; i < _muzzleParticleCount; i++) {
      _muzzleParticles.add(_MuzzleParticle(
        angle: _random.nextDouble() * math.pi * 2,
        speed: 50 + _random.nextDouble() * 100,
        size: 1.5 + _random.nextDouble() * 2,
        lifetime: 0,
        maxLifetime: 0.15 + _random.nextDouble() * 0.1,
      ));
    }

    // Initialize construction particles
    _constructionParticles.clear();
    for (int i = 0; i < _constructionParticleCount; i++) {
      _constructionParticles.add(_ConstructionParticle(
        angle: _random.nextDouble() * math.pi * 2,
        radius: 30 + _random.nextDouble() * 40,
        speed: 0.5 + _random.nextDouble() * 1.0,
        size: 1.5 + _random.nextDouble() * 2,
        phase: _random.nextDouble() * math.pi * 2,
        targetRadius: 5 + _random.nextDouble() * 15,
        spiralRate: 2 + _random.nextDouble() * 2,
      ));
    }
  }

  /// Center position for targeting calculations
  Vector2 get centerPosition => position + size / 2;

  double get _boostMultiplier => _isBoosted ? 1.2 : 1.0;

  /// Get tower stats from type
  double get damage => type.damage * _damageMultiplier * (_isBoosted ? 2.2 : 1.0);
  double get fireRate => type.fireRate * _fireRateMultiplier * (_isBoosted ? 2.2 : 1.0);
  double get range => type.range * _rangeMultiplier;
  Color get color => type.color;
  double get projectileSpeed => type.projectileSpeed * _projectileSpeedMultiplier;
  double get slowAmount => type.slowAmount * _slowMultiplier;
  double get slowDuration => type.slowDuration;

  // FPS view support
  double get currentDamage => damage;
  double get currentFireRate => fireRate;
  double get currentRange => range;
  Enemy? get currentTarget => _currentTarget;
  double _lastFireTime = 0;
  double get lastFireTime => _lastFireTime;

  /// Whether the tower is ready to fire
  bool get isReady => _fireCooldown <= 0;

  void applyUpgradeStats(UpgradeStats stats) {
    _damageMultiplier = stats.towerDamageMult;
    _rangeMultiplier = stats.towerRangeMult;
    _fireRateMultiplier = stats.towerFireRateMult;
    _projectileSpeedMultiplier = stats.projectileSpeedMult;
    _slowMultiplier = stats.slowMult;
  }

  /// Manually reset the fire cooldown after a shot
  void resetCooldown() {
    _fireCooldown = 1.0 / fireRate;
    _chargeLevel = 0;
    _triggerMuzzleFlash();
  }

  void enterFpsBoost() {
    _isManualBoosted = true;
  }

  void exitFpsBoost() {
    _isManualBoosted = false;
  }

  void setResonanceBoost(bool boosted) {
    if (boosted) _resonanceBoosters++;
    else _resonanceBoosters = math.max(0, _resonanceBoosters - 1);
  }

  void resetResonanceBoost() {
    _resonanceBoosters = 0;
  }

  bool get manualTargeting => _manualTargeting;

  Enemy? get manualTarget => _manualTarget;

  void setManualMode(bool enabled) {
    _manualTargeting = enabled;
    if (!enabled) {
      _manualTarget = null;
    }
  }

  void setManualTarget(Enemy? target) {
    _manualTarget = target;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTRUCTION ANIMATION PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start the holographic construction animation
  /// [duration] - How long the construction takes (default 2.0 seconds)
  void startConstruction({double duration = 2.0}) {
    _isConstructing = true;
    _constructionProgress = 0.0;
    _constructionDuration = duration;
    _constructionFlashTimer = 0.0;

    // Re-randomize construction particles for variety
    for (int i = 0; i < _constructionParticles.length; i++) {
      final particle = _constructionParticles[i];
      particle.angle = _random.nextDouble() * math.pi * 2;
      particle.radius = 30 + _random.nextDouble() * 40;
      particle.phase = _random.nextDouble() * math.pi * 2;
    }
  }

  /// Whether the tower is currently being constructed
  bool get isConstructing => _isConstructing;

  /// Current construction progress (0.0 to 1.0)
  double get constructionProgress => _constructionProgress;

  /// Instantly complete construction (useful for testing or fast-forward)
  void completeConstruction() {
    if (_isConstructing) {
      _constructionProgress = 1.0;
      _isConstructing = false;
      _constructionFlashTimer = 0.5;
    }
  }

  /// Cancel construction and reset state
  void cancelConstruction() {
    _isConstructing = false;
    _constructionProgress = 0.0;
    _constructionFlashTimer = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update construction animation
    if (_isConstructing) {
      _constructionProgress += dt / _constructionDuration;
      if (_constructionProgress >= 1.0) {
        _constructionProgress = 1.0;
        _isConstructing = false;
        _constructionFlashTimer = 0.5; // Trigger completion flash
      }

      // Update construction particles during build
      for (final particle in _constructionParticles) {
        particle.update(dt, _constructionProgress);
      }

      // Skip normal updates while constructing
      _animationPhase += dt * 2;
      return;
    }

    // Update construction flash timer (after construction completes)
    if (_constructionFlashTimer > 0) {
      _constructionFlashTimer -= dt;
    }

    _fireCooldown -= dt;

    // Animation updates
    _animationPhase += dt * 2;
    _pulseAnimation = (math.sin(_animationPhase) + 1) / 2;

    // Update fire flash timer
    if (_fireFlashTimer > 0) {
      _fireFlashTimer -= dt;
      if (_fireFlashTimer <= 0) {
        _isFiring = false;
      }
    }

    // Update orbiting particles
    for (final particle in _orbitParticles) {
      particle.update(dt, type);
    }

    // Update muzzle particles
    for (final particle in _muzzleParticles) {
      particle.update(dt);
    }

    // Update energy wave ripples with single-pass removal
    int rippleWriteIdx = 0;
    for (int i = 0; i < _energyWaveRipples.length; i++) {
      final ripple = _energyWaveRipples[i];
      ripple.update(dt);
      if (ripple.isActive) {
        if (rippleWriteIdx != i) _energyWaveRipples[rippleWriteIdx] = ripple;
        rippleWriteIdx++;
      }
    }
    if (rippleWriteIdx < _energyWaveRipples.length) {
      _energyWaveRipples.removeRange(rippleWriteIdx, _energyWaveRipples.length);
    }

    // Generate electric arcs for Phase Mage idle
    if (type == TowerType.phaseMage && _random.nextDouble() < dt * 3) {
      _generateElectricArc();
    }

    // Update energy web animation for slow towers
    if (type.appliesSlow) {
      _webPulsePhase += dt * 3;
      // Expand web when enemies are slowed, contract when not
      final hasSlowedEnemies = _slowedEnemies.isNotEmpty;
      final targetExpansion = hasSlowedEnemies ? 1.0 : 0.0;
      final expansionSpeed = hasSlowedEnemies ? 4.0 : 2.0;
      _webExpansion += (targetExpansion - _webExpansion) * dt * expansionSpeed;
      _webExpansion = _webExpansion.clamp(0.0, 1.0);
      // Clean up dead enemies from slowed list (single-pass)
      int slowedWriteIdx = 0;
      for (int i = 0; i < _slowedEnemies.length; i++) {
        final e = _slowedEnemies[i];
        if (e.isAlive && e.isSlowed) {
          if (slowedWriteIdx != i) _slowedEnemies[slowedWriteIdx] = e;
          slowedWriteIdx++;
        }
      }
      if (slowedWriteIdx < _slowedEnemies.length) {
        _slowedEnemies.removeRange(slowedWriteIdx, _slowedEnemies.length);
      }
    }

    // Update radar sweep for detection towers
    if (type == TowerType.neuralDisruptor || type == TowerType.phaseMage) {
      final prevAngle = _radarSweepAngle;
      _radarSweepAngle += dt * _radarSweepSpeed;
      if (_radarSweepAngle > math.pi * 2) {
        _radarSweepAngle -= math.pi * 2;
      }
      // Update blip ping intensities (fade over time)
      for (final blip in _radarBlips) {
        blip.pingIntensity = (blip.pingIntensity - dt * 0.8).clamp(0.0, 1.0);
        blip.lastPingTime += dt;
      }
      // Remove dead enemies from blips (single-pass)
      int blipWriteIdx = 0;
      for (int i = 0; i < _radarBlips.length; i++) {
        final blip = _radarBlips[i];
        if (blip.enemy.isAlive) {
          if (blipWriteIdx != i) _radarBlips[blipWriteIdx] = blip;
          blipWriteIdx++;
        }
      }
      if (blipWriteIdx < _radarBlips.length) {
        _radarBlips.removeRange(blipWriteIdx, _radarBlips.length);
      }
    }

    // Charge animation when cooldown is ready
    if (_fireCooldown <= 0 && _chargeLevel < 1) {
      _chargeLevel = (_chargeLevel + dt * 3).clamp(0, 1);
    }

    // Update damage fracture timers
    if (healthPercent < 0.5) {
      _fractureFlickerTimer += dt * _fractureFlickerSpeed;
      _fractureSparkTimer += dt;
    }

    // Rotate towards target
    if (_currentTarget != null) {
      if (!_isTargetValid(_currentTarget!)) {
        _currentTarget = null;
      } else {
        final direction = _currentTarget!.position - centerPosition;
        final targetAngle = math.atan2(direction.y, direction.x);
        // Smooth rotation
        final angleDiff = _normalizeAngle(targetAngle - _rotationAngle);
        _rotationAngle += angleDiff * dt * 8;
      }
    }
  }

  /// Update targeting and shooting
  void updateTargeting(EnemyManager enemyManager) {
    final center = centerPosition;
    _currentTarget = null;
    if (_manualTargeting && _manualTarget != null) {
      if (_isTargetValid(_manualTarget!)) {
        _currentTarget = _manualTarget;
      } else {
        _manualTarget = null;
      }
    }

    if (_currentTarget == null) {
      enemyManager.queryEnemiesInRange(center, range, _candidateEnemies);
      _currentTarget = _findTarget(_candidateEnemies, center);
    }

    // Fire if ready and has target
    if (_currentTarget != null && _fireCooldown <= 0) {
      _fire(_currentTarget!);
      _fireCooldown = 1.0 / fireRate;
      _chargeLevel = 0;
      _triggerMuzzleFlash();
    }
  }

  void _generateElectricArc() {
    _arcPoints.clear();
    final arcLength = 8 + _random.nextDouble() * 6;
    final startAngle = _random.nextDouble() * math.pi * 2;
    Offset current = Offset(
      math.cos(startAngle) * 8,
      math.sin(startAngle) * 8,
    );
    _arcPoints.add(current);

    for (int i = 0; i < 4; i++) {
      final angle = startAngle + (i + 1) * 0.3 + (_random.nextDouble() - 0.5) * 0.5;
      current = Offset(
        math.cos(angle) * (8 + arcLength * (i + 1) / 4),
        math.sin(angle) * (8 + arcLength * (i + 1) / 4),
      );
      _arcPoints.add(current);
    }
  }

  void _triggerMuzzleFlash() {
    _isFiring = true;
    _fireFlashTimer = 0.15;

    // Reset and activate muzzle particles
    for (final particle in _muzzleParticles) {
      particle.reset(_random, _rotationAngle);
    }

    // Spawn energy wave ripples
    _spawnEnergyWaveRipples();
  }

  void _spawnEnergyWaveRipples() {
    // Limit the number of active ripples
    if (_energyWaveRipples.length >= _maxRipples) {
      _energyWaveRipples.removeAt(0);
    }

    // Get secondary color for variety
    final hslColor = HSLColor.fromColor(color);
    final secondaryColor = hslColor.withHue((hslColor.hue + 60) % 360).toColor();

    // Spawn main expanding ripple
    _energyWaveRipples.add(_EnergyWaveRipple(
      startRadius: size.x * 0.2,
      maxRadius: size.x * 1.2,
      duration: 0.4,
      color: color,
      isDirectional: false,
    ));

    // Spawn directional energy wave toward target
    if (_currentTarget != null) {
      _energyWaveRipples.add(_EnergyWaveRipple(
        startRadius: size.x * 0.15,
        maxRadius: size.x * 0.9,
        duration: 0.3,
        color: secondaryColor,
        isDirectional: true,
        direction: _rotationAngle,
        spreadAngle: math.pi / 2, // 90 degree cone
      ));
    }

    // Spawn delayed secondary ripple for echo effect
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_energyWaveRipples.length < _maxRipples) {
        _energyWaveRipples.add(_EnergyWaveRipple(
          startRadius: size.x * 0.25,
          maxRadius: size.x * 0.8,
          duration: 0.35,
          color: color.withOpacity(0.6),
          isDirectional: false,
        ));
      }
    });
  }

  double _normalizeAngle(double angle) {
    while (angle > math.pi) angle -= 2 * math.pi;
    while (angle < -math.pi) angle += 2 * math.pi;
    return angle;
  }

  bool _canTarget(Enemy enemy) {
    if (!enemy.isAlive) return false;
    if (enemy.isPhantom) {
      if (type.canDetectPhantom) {
        enemy.reveal();
      } else if (!enemy.isVisible) {
        return false;
      }
    }
    return true;
  }

  bool _isTargetValid(Enemy enemy) {
    if (!_canTarget(enemy)) return false;
    final center = centerPosition;
    final dx = enemy.position.x - center.x;
    final dy = enemy.position.y - center.y;
    return (dx * dx + dy * dy) <= range * range;
  }

  Enemy? _findTarget(List<Enemy> enemies, Vector2 center) {
    if (enemies.isEmpty) return null;

    Enemy? selected;
    switch (targetMode) {
      case TargetMode.first:
        var bestIndex = 1 << 30;
        for (final enemy in enemies) {
          if (!_canTarget(enemy)) continue;
          if (enemy.spawnIndex < bestIndex) {
            bestIndex = enemy.spawnIndex;
            selected = enemy;
          }
        }
        break;
      case TargetMode.last:
        var bestIndex = -1;
        for (final enemy in enemies) {
          if (!_canTarget(enemy)) continue;
          if (enemy.spawnIndex > bestIndex) {
            bestIndex = enemy.spawnIndex;
            selected = enemy;
          }
        }
        break;
      case TargetMode.strongest:
        var bestHealth = -1.0;
        for (final enemy in enemies) {
          if (!_canTarget(enemy)) continue;
          if (enemy.health > bestHealth) {
            bestHealth = enemy.health;
            selected = enemy;
          }
        }
        break;
      case TargetMode.weakest:
        var bestHealth = double.infinity;
        for (final enemy in enemies) {
          if (!_canTarget(enemy)) continue;
          if (enemy.health < bestHealth) {
            bestHealth = enemy.health;
            selected = enemy;
          }
        }
        break;
      case TargetMode.closest:
        var bestDistSq = double.infinity;
        final centerX = center.x;
        final centerY = center.y;
        for (final enemy in enemies) {
          if (!_canTarget(enemy)) continue;
          final dx = enemy.position.x - centerX;
          final dy = enemy.position.y - centerY;
          final distSq = (dx * dx) + (dy * dy);
          if (distSq < bestDistSq) {
            bestDistSq = distSq;
            selected = enemy;
          }
        }
        break;
    }
    return selected;
  }

  void _fire(Enemy target) {
    // Calculate lead position for moving target
    final targetPos = _calculateLeadPosition(target);

    // Try to get game time from the game instance
    try {
      final game = findGame();
      if (game != null) {
        _lastFireTime = (game as dynamic).gameTime ?? 0.0;
      }
    } catch (_) {
      // Fallback: use current time
      _lastFireTime = 0.0;
    }

    // Track slowed enemies for energy web effect
    if (type.appliesSlow && !_slowedEnemies.contains(target)) {
      _slowedEnemies.add(target);
    }

    onFire?.call(this, target, targetPos);
  }

  Vector2 _calculateLeadPosition(Enemy target) {
    // Simple leading: predict where enemy will be
    final distance = (target.position - centerPosition).length;
    final flightTime = distance / projectileSpeed;
    final direction = target.position - centerPosition;
    if (direction.length > 0) {
      direction.normalize();
    }
    // Assume enemy continues in same direction
    return target.position + (direction * target.speed * flightTime * 0.5);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final reduceFx = Tower.lowFx;
    final center = Offset(size.x / 2, size.y / 2);

    // CONSTRUCTION MODE: Render holographic construction effect instead of normal tower
    if (_isConstructing) {
      if (!reduceFx) {
        _renderConstructionEffect(canvas, center);
      } else {
        // Simplified construction effect for low-fx mode
        final progress = _constructionProgress;
        final holoColor = Color.lerp(color, const Color(0xFF00FFFF), 0.3)!;
        _constructProgressPaint.color = holoColor.withOpacity(0.5 + progress * 0.5);
        canvas.drawCircle(center, size.x * 0.4, _constructProgressPaint);

        // Simple progress arc
        _constructProgressPaint.color = color.withOpacity(0.8);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: size.x * 0.45),
          -math.pi / 2,
          progress * math.pi * 2,
          false,
          _constructProgressPaint,
        );
      }
      return; // Don't render normal tower while constructing
    }

    // POST-CONSTRUCTION FLASH: Render completion flash effect
    if (_constructionFlashTimer > 0 && !reduceFx) {
      _renderConstructionCompleteFlash(canvas, center);
    }

    // LAYER -3: Dynamic shadow casting (very first, below everything)
    if (!reduceFx) {
      _renderDynamicShadow(canvas, center);
    }

    // LAYER -2: Electric arc connections to nearby towers (very background)
    if (!reduceFx) {
      _renderElectricArcConnections(canvas, center);
    }

    // LAYER -1: Dynamic lighting/glow based on tower activity (background layer)
    if (!reduceFx) {
      _renderDynamicLighting(canvas, center);
    }

    // LAYER -0.5: Heat distortion effect for fire-type towers
    if (!reduceFx && type == TowerType.circuitCannon) {
      _renderHeatDistortion(canvas, center);
    }

    // LAYER -0.4: Ice crystal formation effect for freeze towers
    if (!reduceFx && type == TowerType.phaseMage) {
      _renderIceCrystalEffect(canvas, center);
    }

    // LAYER -0.35: Energy web trap effect for slow towers (Phase Mage, Glimmer Field)
    if (!reduceFx && type.appliesSlow && (_webExpansion > 0.01 || _slowedEnemies.isNotEmpty)) {
      _renderEnergyWeb(canvas, center);
    }

    // LAYER -0.3: Vortex/black hole effect for resonance siphon towers
    if (!reduceFx && type == TowerType.resonanceSiphon) {
      _renderVortexEffect(canvas, center);
    }

    // LAYER -0.2: Orbital satellite effects for support towers (resonance siphon)
    if (!reduceFx && type == TowerType.resonanceSiphon) {
      _renderOrbitalSatellites(canvas, center);
    }

    // LAYER -0.1: Drone swarm effect for neural disruptor towers
    if (!reduceFx && type == TowerType.neuralDisruptor) {
      _renderDroneSwarm(canvas, center);
    }

    // LAYER -0.05: Radar sweep effect for detection towers (neuralDisruptor, phaseMage)
    if (!reduceFx && (type == TowerType.neuralDisruptor || type == TowerType.phaseMage)) {
      _renderRadarSweep(canvas, center);
    }

    // LAYER 0: Boost/Shield effect (behind everything)
    if (!reduceFx && _isBoosted) {
      _renderBoostShield(canvas, center);
    }

    // LAYER 1: Type-specific idle effects
    if (!reduceFx) {
      _renderIdleEffects(canvas, center);
    }

    // LAYER 2: Outer glow ring (pulsing) - enhanced with plasma
    if (!reduceFx) {
      _renderOuterGlow(canvas, center);
    }

    // LAYER 3: Orbiting energy particles
    if (!reduceFx) {
      _renderOrbitParticles(canvas, center);
    }

    // LAYER 4: Base hexagon shape with gradient
    _renderMegaBase(canvas, center);

    // LAYER 5: Energy conduits along base edges
    if (!reduceFx) {
      _renderEnergyConduits(canvas, center);
    }

    // LAYER 6: Holographic grid overlay
    if (!reduceFx) {
      _renderHolographicOverlay(canvas, center);
    }

    if (!reduceFx) {
      _renderBaseTrim(canvas, center);
    }

    // LAYER 7: Type-specific core decoration
    _renderTypeDecoration(canvas, center);

    // LAYER 8: Inner core (rotates toward target)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_rotationAngle);

    // Enhanced energy core with plasma effects
    _renderEnergyCore(canvas);
    if (!reduceFx) {
      _renderPlasmaCore(canvas);
    }

    if (!reduceFx) {
      _renderTurretHead(canvas);
    }

    // Targeting line/focus lens when has target
    if (_currentTarget != null) {
      _renderTargetingLens(canvas);
      _renderTargetingLine(canvas);
    }

    canvas.restore();

    // LAYER 9: Charge indicator arcs
    if (_chargeLevel > 0) {
      _renderChargeIndicator(canvas, center);
    }

    // LAYER 10: Muzzle flash and particles
    if (!reduceFx && _isFiring) {
      _renderMuzzleFlash(canvas, center);
    }

    // LAYER 10.5: Energy wave ripples (always rendered when active)
    if (!reduceFx) {
      _renderEnergyWaveRipples(canvas, center);
    }

    // LAYER 11: Data streams when targeting
    if (!reduceFx && _currentTarget != null) {
      _renderDataStreams(canvas, center);
    }

    // LAYER 11.5: Volumetric energy beam for beam weapons (Ion Sniper, Tesla Terminal)
    if (!reduceFx && _currentTarget != null && _isFiring) {
      if (type == TowerType.ionSniper || type == TowerType.teslaTerminal) {
        _renderVolumetricBeam(canvas, center);
      }
    }

    // LAYER 11.6: Energy siphon beam for Resonance Siphon towers
    if (!reduceFx && type == TowerType.resonanceSiphon && _currentTarget != null) {
      _renderSiphonBeam(canvas, center);
    }

    // Range indicator when target acquired
    if (_currentTarget != null) {
      _renderRangeIndicator(canvas, center);
    }

    // Tower type indicator symbol
    _renderTypeSymbol(canvas, center);

    // LAYER 12: Damage fracture effects (when health < 50%)
    if (healthPercent < 0.5) {
      if (!reduceFx) {
        _renderDamageFractures(canvas, center);
      } else {
        // Simplified damage indicator for low-fx mode
        final damageIntensity = 1.0 - (healthPercent * 2); // 0 at 50%, 1 at 0%
        _fracturePrimaryPaint.color = const Color(0xFFFF4400).withOpacity(0.5 * damageIntensity);
        canvas.drawCircle(center, size.x * 0.3, _fracturePrimaryPaint);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENHANCED GRAPHICS METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void _renderOuterGlow(Canvas canvas, Offset center) {
    // Primary glow
    _outerGlowPaint.color = color.withOpacity(0.15 + _pulseAnimation * 0.1);
    canvas.drawCircle(center, size.x * 0.7, _outerGlowPaint);

    // Secondary pulsing glow ring
    final pulseRadius = size.x * (0.55 + _pulseAnimation * 0.15);
    _plasmaRingPaint.color = color.withOpacity(0.2 * _pulseAnimation);
    canvas.drawCircle(center, pulseRadius, _plasmaRingPaint);
  }

  void _renderBoostShield(Canvas canvas, Offset center) {
    final shieldPulse = 0.5 + math.sin(_animationPhase * 6) * 0.3;
    final boostColor = const Color(0xFFFFD700); // Golden boost

    // Outer shield glow
    _shieldGlowPaint.color = boostColor.withOpacity(0.15 * shieldPulse);
    canvas.drawCircle(center, size.x * 0.85, _shieldGlowPaint);

    // Animated hexagonal shield rings
    for (int i = 0; i < 2; i++) {
      final ringRadius = size.x * (0.6 + i * 0.15);
      final ringAlpha = (0.4 - i * 0.15) * shieldPulse;
      final hexPath = NeonEffects.createHexagonPath(center, ringRadius);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(_animationPhase * (i == 0 ? 0.5 : -0.3));
      canvas.translate(-center.dx, -center.dy);

      _shieldHexPaint.color = boostColor.withOpacity(ringAlpha);
      canvas.drawPath(hexPath, _shieldHexPaint);
      canvas.restore();
    }

    // Energy particles spiraling around
    for (int i = 0; i < 6; i++) {
      final angle = _animationPhase * 3 + i * math.pi / 3;
      final radius = size.x * (0.5 + math.sin(_animationPhase * 4 + i) * 0.1);
      final px = center.dx + math.cos(angle) * radius;
      final py = center.dy + math.sin(angle) * radius;

      _sparkPaint.color = boostColor.withOpacity(0.6 * shieldPulse);
      canvas.drawCircle(Offset(px, py), 2, _sparkPaint);
    }
  }

  void _renderEnergyConduits(Canvas canvas, Offset center) {
    final conduitRadius = size.x * 0.45;

    // Draw animated energy flowing along hexagon edges
    for (int i = 0; i < 6; i++) {
      final startAngle = i * math.pi / 3 - math.pi / 6;
      final endAngle = (i + 1) * math.pi / 3 - math.pi / 6;

      final startX = center.dx + math.cos(startAngle) * conduitRadius;
      final startY = center.dy + math.sin(startAngle) * conduitRadius;
      final endX = center.dx + math.cos(endAngle) * conduitRadius;
      final endY = center.dy + math.sin(endAngle) * conduitRadius;

      // Conduit glow line
      _conduitGlowPaint.color = color.withOpacity(0.3);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), _conduitGlowPaint);

      // Animated energy pulse along conduit
      final pulseProgress = ((_animationPhase * 2 + i * 0.3) % 1.0);
      final pulseX = startX + (endX - startX) * pulseProgress;
      final pulseY = startY + (endY - startY) * pulseProgress;

      _conduitPulsePaint.color = color.withOpacity(0.6);
      canvas.drawCircle(Offset(pulseX, pulseY), 3, _conduitPulsePaint);

      // Core conduit line
      _conduitCorePaint.color = color.withOpacity(0.5);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), _conduitCorePaint);
    }

    // Junction nodes at hexagon vertices
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final nodeX = center.dx + math.cos(angle) * conduitRadius;
      final nodeY = center.dy + math.sin(angle) * conduitRadius;

      final nodePulse = 0.5 + math.sin(_animationPhase * 4 + i) * 0.3;
      _conduitPulsePaint.color = color.withOpacity(0.4 * nodePulse);
      canvas.drawCircle(Offset(nodeX, nodeY), 4, _conduitPulsePaint);

      _dotTrimPaint.color = color.withOpacity(0.8);
      canvas.drawCircle(Offset(nodeX, nodeY), 2, _dotTrimPaint);
    }
  }

  void _renderHolographicOverlay(Canvas canvas, Offset center) {
    // Animated scanline effect
    final scanlineY = center.dy - size.y * 0.3 + ((_animationPhase * 0.5) % 1.0) * size.y * 0.6;
    _holoScanlinePaint.color = color.withOpacity(0.08);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx, scanlineY), width: size.x * 0.7, height: 2),
      _holoScanlinePaint,
    );

    // Subtle grid pattern inside base
    _holoGridPaint.color = color.withOpacity(0.06);
    final gridSize = size.x * 0.08;
    final gridExtent = size.x * 0.3;

    for (double x = -gridExtent; x <= gridExtent; x += gridSize) {
      canvas.drawLine(
        Offset(center.dx + x, center.dy - gridExtent),
        Offset(center.dx + x, center.dy + gridExtent),
        _holoGridPaint,
      );
    }
    for (double y = -gridExtent; y <= gridExtent; y += gridSize) {
      canvas.drawLine(
        Offset(center.dx - gridExtent, center.dy + y),
        Offset(center.dx + gridExtent, center.dy + y),
        _holoGridPaint,
      );
    }

    // Data display elements in corners
    final dataAlpha = 0.15 + _pulseAnimation * 0.1;
    _holoGridPaint.color = color.withOpacity(dataAlpha);

    // Top-left data block
    canvas.drawRect(
      Rect.fromLTWH(center.dx - size.x * 0.35, center.dy - size.y * 0.35, 6, 3),
      _holoGridPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(center.dx - size.x * 0.35, center.dy - size.y * 0.30, 4, 2),
      _holoGridPaint,
    );

    // Bottom-right data block
    canvas.drawRect(
      Rect.fromLTWH(center.dx + size.x * 0.25, center.dy + size.y * 0.30, 6, 3),
      _holoGridPaint,
    );
  }

  void _renderPlasmaCore(Canvas canvas) {
    final coreSize = size.x * 0.2;

    // Plasma wisps orbiting the core
    for (int i = 0; i < 4; i++) {
      final wispAngle = _animationPhase * 3 + i * math.pi / 2;
      final wispRadius = coreSize * (0.8 + math.sin(_animationPhase * 5 + i) * 0.3);
      final wispX = math.cos(wispAngle) * wispRadius;
      final wispY = math.sin(wispAngle) * wispRadius;

      _plasmaWispPaint.color = color.withOpacity(0.4);
      canvas.drawCircle(Offset(wispX, wispY), 3, _plasmaWispPaint);

      // Wisp trail
      final trailAngle = wispAngle - 0.3;
      final trailX = math.cos(trailAngle) * wispRadius * 0.9;
      final trailY = math.sin(trailAngle) * wispRadius * 0.9;

      _plasmaSwirlPaint.color = color.withOpacity(0.2);
      canvas.drawLine(Offset(trailX, trailY), Offset(wispX, wispY), _plasmaSwirlPaint);
    }

    // Inner plasma swirl
    _tempPath2.reset();
    for (int i = 0; i < 20; i++) {
      final t = i / 20.0;
      final swirlAngle = t * math.pi * 4 + _animationPhase * 2;
      final swirlRadius = coreSize * 0.3 * t;
      final sx = math.cos(swirlAngle) * swirlRadius;
      final sy = math.sin(swirlAngle) * swirlRadius;

      if (i == 0) {
        _tempPath2.moveTo(sx, sy);
      } else {
        _tempPath2.lineTo(sx, sy);
      }
    }
    _plasmaSwirlPaint.color = color.withOpacity(0.3);
    canvas.drawPath(_tempPath2, _plasmaSwirlPaint);

    // Energy ring pulses
    final ringPulse = (_animationPhase * 2) % 1.0;
    final ringRadius = coreSize * 0.5 + ringPulse * coreSize * 0.5;
    final ringAlpha = (1 - ringPulse) * 0.3;

    _plasmaRingPaint.color = color.withOpacity(ringAlpha);
    canvas.drawCircle(Offset.zero, ringRadius, _plasmaRingPaint);
  }

  void _renderDataStreams(Canvas canvas, Offset center) {
    // Animated data streams flowing toward target
    final targetDir = _rotationAngle;
    final streamLength = size.x * 0.4;

    for (int i = 0; i < 3; i++) {
      final streamOffset = (i - 1) * 0.15;
      final streamAngle = targetDir + streamOffset;

      // Animated dash pattern
      final dashProgress = ((_animationPhase * 4 + i * 0.2) % 1.0);

      for (int d = 0; d < 4; d++) {
        final dashT = ((dashProgress + d * 0.25) % 1.0);
        final dashDist = size.x * 0.15 + dashT * streamLength;

        final dx = center.dx + math.cos(streamAngle) * dashDist;
        final dy = center.dy + math.sin(streamAngle) * dashDist;

        final dashAlpha = (1 - dashT) * 0.4;
        _dataStreamPaint.color = color.withOpacity(dashAlpha);
        canvas.drawCircle(Offset(dx, dy), 1.5, _dataStreamPaint);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VOLUMETRIC ENERGY BEAM RENDERING
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderVolumetricBeam(Canvas canvas, Offset center) {
    if (_currentTarget == null) return;

    // Calculate beam endpoints
    final targetPos = _currentTarget!.position;
    final towerWorldPos = position + Vector2(size.x / 2, size.y / 2);
    final targetOffset = Offset(
      targetPos.x - towerWorldPos.x + center.dx,
      targetPos.y - towerWorldPos.y + center.dy,
    );

    final beamLength = (targetOffset - center).distance;
    if (beamLength < 1) return;

    // Get beam direction
    final beamDir = (targetOffset - center) / beamLength;
    final beamAngle = math.atan2(beamDir.dy, beamDir.dx);

    // Flash intensity for beam pulsing
    final flashIntensity = (_fireFlashTimer / 0.15).clamp(0.0, 1.0);
    final beamPulse = 0.7 + math.sin(_animationPhase * 10) * 0.3;

    // Get color variations using HSL
    final hslColor = HSLColor.fromColor(color);
    final secondaryColor = hslColor.withHue((hslColor.hue + 30) % 360).toColor();
    final tertiaryColor = hslColor.withHue((hslColor.hue + 180) % 360).toColor();
    final brightCore = Color.lerp(color, const Color(0xFFFFFFFF), 0.7)!;

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: VOLUMETRIC AURA (Background ambient glow)
    // ═══════════════════════════════════════════════════════════════════════
    final auraAlpha = 0.08 * flashIntensity * beamPulse;
    _beamAuraPaint.color = color.withOpacity(auraAlpha);

    // Draw aura as series of circles along beam
    for (double t = 0; t < 1.0; t += 0.15) {
      final px = center.dx + beamDir.dx * beamLength * t;
      final py = center.dy + beamDir.dy * beamLength * t;
      final auraSize = 25 + math.sin(_animationPhase * 4 + t * 10) * 8;
      canvas.drawCircle(Offset(px, py), auraSize, _beamAuraPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: OUTER GLOW (Wide diffuse glow)
    // ═══════════════════════════════════════════════════════════════════════
    final outerGlowAlpha = 0.2 * flashIntensity * beamPulse;
    _beamOuterGlowPaint
      ..color = color.withOpacity(outerGlowAlpha)
      ..strokeWidth = 16 + math.sin(_animationPhase * 6) * 4;
    canvas.drawLine(center, targetOffset, _beamOuterGlowPaint);

    // Secondary color outer glow offset
    _beamOuterGlowPaint
      ..color = secondaryColor.withOpacity(outerGlowAlpha * 0.5)
      ..strokeWidth = 12;
    final chromaOffset = Offset(
      math.cos(beamAngle + math.pi / 2) * 3,
      math.sin(beamAngle + math.pi / 2) * 3,
    );
    canvas.drawLine(
      center + chromaOffset,
      targetOffset + chromaOffset,
      _beamOuterGlowPaint,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: INNER GLOW (Concentrated energy)
    // ═══════════════════════════════════════════════════════════════════════
    final innerGlowAlpha = 0.4 * flashIntensity * beamPulse;
    _beamInnerGlowPaint
      ..color = color.withOpacity(innerGlowAlpha)
      ..strokeWidth = 8 + math.sin(_animationPhase * 8) * 2;
    canvas.drawLine(center, targetOffset, _beamInnerGlowPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: CORE BEAM (Bright white/cyan center)
    // ═══════════════════════════════════════════════════════════════════════
    final coreAlpha = 0.8 * flashIntensity;
    _beamCorePaint
      ..color = brightCore.withOpacity(coreAlpha)
      ..strokeWidth = 3 + math.sin(_animationPhase * 12) * 1;
    canvas.drawLine(center, targetOffset, _beamCorePaint);

    // Ultra-bright center line
    _beamCorePaint
      ..color = const Color(0xFFFFFFFF).withOpacity(coreAlpha * 0.9)
      ..strokeWidth = 1.5;
    canvas.drawLine(center, targetOffset, _beamCorePaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: VOLUMETRIC LIGHT RAYS (Emanating from beam)
    // ═══════════════════════════════════════════════════════════════════════
    const rayCount = 12;
    final perpAngle = beamAngle + math.pi / 2;

    for (int i = 0; i < rayCount; i++) {
      final t = i / rayCount;
      final rayProgress = (_animationPhase * 3 + t * 4) % 1.0;
      final rayFlicker = 0.3 + math.sin(_animationPhase * 15 + i * 2.5) * 0.7;

      if (rayFlicker < 0.4) continue;

      // Position along beam
      final beamT = t + rayProgress * 0.1;
      if (beamT > 1.0) continue;

      final rayBaseX = center.dx + beamDir.dx * beamLength * beamT;
      final rayBaseY = center.dy + beamDir.dy * beamLength * beamT;
      final rayBase = Offset(rayBaseX, rayBaseY);

      // Ray extends perpendicular to beam
      final rayLength = (8 + math.sin(_animationPhase * 8 + i) * 6) * flashIntensity;
      final rayDir = (i % 2 == 0) ? 1.0 : -1.0;

      final rayEndX = rayBaseX + math.cos(perpAngle) * rayLength * rayDir;
      final rayEndY = rayBaseY + math.sin(perpAngle) * rayLength * rayDir;
      final rayEnd = Offset(rayEndX, rayEndY);

      final rayAlpha = 0.25 * flashIntensity * rayFlicker;
      _beamVolumetricRayPaint
        ..color = color.withOpacity(rayAlpha)
        ..strokeWidth = 2;
      canvas.drawLine(rayBase, rayEnd, _beamVolumetricRayPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: PARTICLE SPARKS ALONG BEAM
    // ═══════════════════════════════════════════════════════════════════════
    const sparkCount = 16;
    for (int i = 0; i < sparkCount; i++) {
      final sparkPhase = (_animationPhase * 5 + i * 0.4) % 1.0;
      final sparkT = sparkPhase;

      // Spark position along beam with slight perpendicular offset
      final sparkBaseX = center.dx + beamDir.dx * beamLength * sparkT;
      final sparkBaseY = center.dy + beamDir.dy * beamLength * sparkT;

      // Add random perpendicular jitter
      final jitter = math.sin(_animationPhase * 20 + i * 3.7) * 4;
      final sparkX = sparkBaseX + math.cos(perpAngle) * jitter;
      final sparkY = sparkBaseY + math.sin(perpAngle) * jitter;

      final sparkAlpha = (1 - sparkT) * 0.7 * flashIntensity;
      final sparkSize = 2 + math.sin(_animationPhase * 10 + i) * 1;

      // Spark glow
      _beamSparkPaint.color = color.withOpacity(sparkAlpha * 0.5);
      canvas.drawCircle(Offset(sparkX, sparkY), sparkSize * 2, _beamSparkPaint);

      // Spark core
      _beamSparkPaint.color = brightCore.withOpacity(sparkAlpha);
      canvas.drawCircle(Offset(sparkX, sparkY), sparkSize, _beamSparkPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: ENERGY PULSE TRAVELING ALONG BEAM
    // ═══════════════════════════════════════════════════════════════════════
    const pulseCount = 3;
    for (int p = 0; p < pulseCount; p++) {
      final pulsePhase = (_animationPhase * 4 + p * 0.33) % 1.0;
      final pulseT = pulsePhase;

      final pulseX = center.dx + beamDir.dx * beamLength * pulseT;
      final pulseY = center.dy + beamDir.dy * beamLength * pulseT;

      final pulseAlpha = math.sin(pulseT * math.pi) * 0.6 * flashIntensity;
      final pulseSize = 6 + math.sin(_animationPhase * 8 + p) * 2;

      // Outer pulse glow
      _beamPulsePaint.color = color.withOpacity(pulseAlpha * 0.4);
      canvas.drawCircle(Offset(pulseX, pulseY), pulseSize * 2.5, _beamPulsePaint);

      // Inner pulse glow
      _beamPulsePaint.color = secondaryColor.withOpacity(pulseAlpha * 0.6);
      canvas.drawCircle(Offset(pulseX, pulseY), pulseSize * 1.5, _beamPulsePaint);

      // Pulse core
      _beamPulsePaint.color = brightCore.withOpacity(pulseAlpha);
      canvas.drawCircle(Offset(pulseX, pulseY), pulseSize * 0.5, _beamPulsePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 8: HEAT DISTORTION LINES
    // ═══════════════════════════════════════════════════════════════════════
    const distortCount = 6;
    for (int d = 0; d < distortCount; d++) {
      final distortPhase = (_animationPhase * 2 + d * 0.5) % 1.0;
      final distortT = distortPhase;

      // Build wavy distortion path
      _beamPath.reset();

      final startT = distortT.clamp(0.0, 0.9);
      final endT = (distortT + 0.15).clamp(0.0, 1.0);

      const segmentCount = 8;
      for (int s = 0; s <= segmentCount; s++) {
        final segT = startT + (endT - startT) * (s / segmentCount);
        final baseX = center.dx + beamDir.dx * beamLength * segT;
        final baseY = center.dy + beamDir.dy * beamLength * segT;

        // Wavy offset perpendicular to beam
        final waveAmp = 3 + math.sin(_animationPhase * 6 + d) * 2;
        final waveOffset = math.sin(_animationPhase * 12 + segT * 20 + d * 2) * waveAmp;
        final offsetDir = (d % 2 == 0) ? 1.0 : -1.0;

        final px = baseX + math.cos(perpAngle) * waveOffset * offsetDir * (8 + d * 2);
        final py = baseY + math.sin(perpAngle) * waveOffset * offsetDir * (8 + d * 2);

        if (s == 0) {
          _beamPath.moveTo(px, py);
        } else {
          _beamPath.lineTo(px, py);
        }
      }

      final distortAlpha = 0.15 * flashIntensity * (1 - distortT);
      _beamHeatDistortPaint.color = tertiaryColor.withOpacity(distortAlpha);
      canvas.drawPath(_beamPath, _beamHeatDistortPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // IMPACT POINT EFFECT
    // ═══════════════════════════════════════════════════════════════════════
    final impactPulse = 0.5 + math.sin(_animationPhase * 12) * 0.5;
    final impactAlpha = 0.5 * flashIntensity * impactPulse;

    // Impact outer glow
    _beamAuraPaint.color = color.withOpacity(impactAlpha * 0.3);
    canvas.drawCircle(targetOffset, 20, _beamAuraPaint);

    // Impact inner glow
    _beamPulsePaint.color = secondaryColor.withOpacity(impactAlpha * 0.5);
    canvas.drawCircle(targetOffset, 12, _beamPulsePaint);

    // Impact core
    _beamPulsePaint.color = brightCore.withOpacity(impactAlpha);
    canvas.drawCircle(targetOffset, 5, _beamPulsePaint);

    // Impact sparks
    for (int i = 0; i < 6; i++) {
      final sparkAngle = _animationPhase * 8 + i * math.pi / 3;
      final sparkDist = 8 + math.sin(_animationPhase * 10 + i) * 6;
      final sparkX = targetOffset.dx + math.cos(sparkAngle) * sparkDist;
      final sparkY = targetOffset.dy + math.sin(sparkAngle) * sparkDist;

      _beamSparkPaint.color = brightCore.withOpacity(impactAlpha * 0.8);
      canvas.drawCircle(Offset(sparkX, sparkY), 2, _beamSparkPaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENERGY SIPHON BEAM RENDERING (Resonance Siphon - drains energy from enemies)
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderSiphonBeam(Canvas canvas, Offset center) {
    if (_currentTarget == null) return;

    // Calculate beam endpoints
    final targetPos = _currentTarget!.position;
    final towerWorldPos = position + Vector2(size.x / 2, size.y / 2);
    final targetOffset = Offset(
      targetPos.x - towerWorldPos.x + center.dx,
      targetPos.y - towerWorldPos.y + center.dy,
    );

    final beamLength = (targetOffset - center).distance;
    if (beamLength < 1) return;

    // Get beam direction (from target to source for siphon effect)
    final beamDir = (targetOffset - center) / beamLength;
    final beamAngle = math.atan2(beamDir.dy, beamDir.dx);
    final perpAngle = beamAngle + math.pi / 2;

    // Siphon beam uses green/cyan colors for energy drain effect
    const siphonPrimaryColor = Color(0xFF00FF88); // Bright green
    const siphonSecondaryColor = Color(0xFF00FFCC); // Cyan-green
    const siphonCoreColor = Color(0xFFAAFFDD); // Pale green-white
    const siphonDrainColor = Color(0xFF00AA66); // Darker drain green

    // Animation values
    final beamPulse = 0.7 + math.sin(_animationPhase * 8) * 0.3;
    final flowSpeed = _animationPhase * 3; // Energy flowing from target to tower

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: MAIN BEAM CONNECTION (Wavy line between entities)
    // ═══════════════════════════════════════════════════════════════════════
    _siphonBeamPath.reset();

    // Create wavy beam path
    const waveSegments = 20;
    final waveAmplitude = 3 + math.sin(_animationPhase * 6) * 2;

    for (int i = 0; i <= waveSegments; i++) {
      final t = i / waveSegments;
      final baseX = center.dx + beamDir.dx * beamLength * t;
      final baseY = center.dy + beamDir.dy * beamLength * t;

      // Add wave oscillation perpendicular to beam
      final waveOffset = math.sin(t * math.pi * 4 + flowSpeed) * waveAmplitude;
      final waveX = baseX + math.cos(perpAngle) * waveOffset;
      final waveY = baseY + math.sin(perpAngle) * waveOffset;

      if (i == 0) {
        _siphonBeamPath.moveTo(waveX, waveY);
      } else {
        _siphonBeamPath.lineTo(waveX, waveY);
      }
    }

    // Draw outer glow first (behind)
    _siphonBeamOuterGlowPaint.color = siphonPrimaryColor.withOpacity(0.15 * beamPulse);
    canvas.drawPath(_siphonBeamPath, _siphonBeamOuterGlowPaint);

    // Draw inner glow
    _siphonBeamGlowPaint.color = siphonSecondaryColor.withOpacity(0.3 * beamPulse);
    canvas.drawPath(_siphonBeamPath, _siphonBeamGlowPaint);

    // Draw core beam
    _siphonBeamCorePaint.color = siphonCoreColor.withOpacity(0.8 * beamPulse);
    canvas.drawPath(_siphonBeamPath, _siphonBeamCorePaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: BEAM GLOW EFFECT (Additional blurred background)
    // ═══════════════════════════════════════════════════════════════════════
    // Draw ambient glow circles along beam for volumetric feel
    for (double t = 0.1; t < 0.9; t += 0.2) {
      final glowX = center.dx + beamDir.dx * beamLength * t;
      final glowY = center.dy + beamDir.dy * beamLength * t;
      final glowSize = 12 + math.sin(_animationPhase * 4 + t * 8) * 4;
      _siphonBeamOuterGlowPaint.color = siphonPrimaryColor.withOpacity(0.08 * beamPulse);
      canvas.drawCircle(Offset(glowX, glowY), glowSize, _siphonBeamOuterGlowPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: ENERGY PARTICLES FLOWING ALONG BEAM (from target to source)
    // ═══════════════════════════════════════════════════════════════════════
    const particleCount = 12;
    for (int i = 0; i < particleCount; i++) {
      // Particles flow from target (t=1) to tower (t=0) - reverse direction
      final particlePhase = (1.0 - ((flowSpeed + i * 0.25) % 1.0));
      final particleT = particlePhase;

      // Calculate position along beam
      final baseX = center.dx + beamDir.dx * beamLength * particleT;
      final baseY = center.dy + beamDir.dy * beamLength * particleT;

      // Add slight perpendicular jitter for organic feel
      final jitterPhase = _animationPhase * 12 + i * 2.7;
      final jitter = math.sin(jitterPhase) * 3;
      final particleX = baseX + math.cos(perpAngle) * jitter;
      final particleY = baseY + math.sin(perpAngle) * jitter;

      // Particle size varies - larger at target, smaller at tower
      final particleSize = 2 + particleT * 2;
      final particleAlpha = 0.7 * beamPulse;

      // Draw particle trail (behind)
      final trailLength = 8 * particleT;
      final trailEndX = particleX + beamDir.dx * trailLength;
      final trailEndY = particleY + beamDir.dy * trailLength;
      _siphonParticleTrailPaint.color = siphonSecondaryColor.withOpacity(particleAlpha * 0.3);
      canvas.drawLine(
        Offset(particleX, particleY),
        Offset(trailEndX, trailEndY),
        _siphonParticleTrailPaint..strokeWidth = particleSize,
      );

      // Draw particle glow
      _siphonParticlePaint.color = siphonPrimaryColor.withOpacity(particleAlpha * 0.5);
      canvas.drawCircle(Offset(particleX, particleY), particleSize * 2, _siphonParticlePaint);

      // Draw particle core
      _siphonParticleCorePaint.color = siphonCoreColor.withOpacity(particleAlpha);
      canvas.drawCircle(Offset(particleX, particleY), particleSize, _siphonParticleCorePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: ENERGY ACCUMULATION AT SOURCE END (Tower end)
    // ═══════════════════════════════════════════════════════════════════════
    final accumulationPulse = 0.6 + math.sin(_animationPhase * 10) * 0.4;

    // Outer accumulation glow
    _siphonAccumulationGlowPaint.color = siphonPrimaryColor.withOpacity(0.2 * accumulationPulse);
    canvas.drawCircle(center, 18, _siphonAccumulationGlowPaint);

    // Mid accumulation glow
    _siphonAccumulationCorePaint.color = siphonSecondaryColor.withOpacity(0.35 * accumulationPulse);
    canvas.drawCircle(center, 12, _siphonAccumulationCorePaint);

    // Bright core at tower center
    _siphonAccumulationCorePaint.color = siphonCoreColor.withOpacity(0.6 * accumulationPulse);
    canvas.drawCircle(center, 6, _siphonAccumulationCorePaint);

    // Pulsing rings around accumulation
    for (int r = 0; r < 2; r++) {
      final ringPhase = (_animationPhase * 3 + r * 0.5) % 1.0;
      final ringRadius = 8 + ringPhase * 12;
      final ringAlpha = (1.0 - ringPhase) * 0.4 * accumulationPulse;
      _siphonAccumulationRingPaint.color = siphonSecondaryColor.withOpacity(ringAlpha);
      canvas.drawCircle(center, ringRadius, _siphonAccumulationRingPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: DRAIN EFFECT AT TARGET END (Dimming glow on enemy)
    // ═══════════════════════════════════════════════════════════════════════
    final drainPulse = 0.5 + math.sin(_animationPhase * 8 + math.pi) * 0.5;

    // Outer drain glow - dimmer, shows energy being extracted
    _siphonDrainGlowPaint.color = siphonDrainColor.withOpacity(0.25 * drainPulse);
    canvas.drawCircle(targetOffset, 15, _siphonDrainGlowPaint);

    // Drain vortex spirals - energy being sucked out
    for (int v = 0; v < 3; v++) {
      final vortexAngle = _animationPhase * -4 + v * math.pi * 2 / 3;
      final vortexRadius = 10 + math.sin(_animationPhase * 6 + v) * 3;

      _siphonBeamPath.reset();
      for (int s = 0; s < 8; s++) {
        final spiralT = s / 8.0;
        final spiralAngle = vortexAngle + spiralT * math.pi * 0.8;
        final spiralRadius = vortexRadius * (1.0 - spiralT * 0.7);
        final sx = targetOffset.dx + math.cos(spiralAngle) * spiralRadius;
        final sy = targetOffset.dy + math.sin(spiralAngle) * spiralRadius;

        if (s == 0) {
          _siphonBeamPath.moveTo(sx, sy);
        } else {
          _siphonBeamPath.lineTo(sx, sy);
        }
      }

      final vortexAlpha = 0.5 * drainPulse * (1.0 - v * 0.2);
      _siphonDrainVortexPaint.color = siphonSecondaryColor.withOpacity(vortexAlpha);
      canvas.drawPath(_siphonBeamPath, _siphonDrainVortexPaint);
    }

    // Inner drain point - darker center
    _siphonDrainGlowPaint.color = siphonDrainColor.withOpacity(0.4 * drainPulse);
    canvas.drawCircle(targetOffset, 5, _siphonDrainGlowPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: BEAM PULSE WAVES TRAVELING ALONG CONNECTION
    // ═══════════════════════════════════════════════════════════════════════
    const pulseWaveCount = 4;
    for (int p = 0; p < pulseWaveCount; p++) {
      // Pulses travel from target to tower
      final pulsePhase = (1.0 - ((_animationPhase * 2 + p * 0.25) % 1.0));
      final pulseT = pulsePhase;

      final pulseX = center.dx + beamDir.dx * beamLength * pulseT;
      final pulseY = center.dy + beamDir.dy * beamLength * pulseT;

      // Pulse intensity peaks in middle of travel
      final pulseIntensity = math.sin(pulseT * math.pi) * beamPulse;
      final pulseRadius = 5 + pulseIntensity * 4;

      // Outer pulse glow
      _siphonPulseWavePaint.color = siphonPrimaryColor.withOpacity(0.3 * pulseIntensity);
      canvas.drawCircle(Offset(pulseX, pulseY), pulseRadius * 2, _siphonPulseWavePaint);

      // Inner pulse glow
      _siphonPulseWavePaint.color = siphonSecondaryColor.withOpacity(0.5 * pulseIntensity);
      canvas.drawCircle(Offset(pulseX, pulseY), pulseRadius, _siphonPulseWavePaint);

      // Pulse core
      _siphonPulseWavePaint.color = siphonCoreColor.withOpacity(0.7 * pulseIntensity);
      canvas.drawCircle(Offset(pulseX, pulseY), pulseRadius * 0.4, _siphonPulseWavePaint);

      // Expanding ring at pulse position
      final ringExpand = pulseIntensity * 8;
      _siphonPulseRingPaint.color = siphonSecondaryColor.withOpacity(0.25 * pulseIntensity);
      canvas.drawCircle(Offset(pulseX, pulseY), pulseRadius + ringExpand, _siphonPulseRingPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: CRACKLING ELECTRICITY AT CONNECTION POINTS
    // ═══════════════════════════════════════════════════════════════════════
    // Electric arcs at tower connection point
    final electricFlicker = 0.5 + _siphonRandom.nextDouble() * 0.5;
    if (electricFlicker > 0.6) {
      for (int e = 0; e < 4; e++) {
        final arcAngle = _animationPhase * 12 + e * math.pi / 2 + _siphonRandom.nextDouble() * 0.5;
        final arcLength = 8 + _siphonRandom.nextDouble() * 6;

        _siphonBeamPath.reset();
        _siphonBeamPath.moveTo(center.dx, center.dy);

        // Create jagged lightning path
        Offset current = center;
        const arcSegments = 4;
        for (int s = 1; s <= arcSegments; s++) {
          final segT = s / arcSegments;
          final baseAngle = arcAngle + (_siphonRandom.nextDouble() - 0.5) * 0.8;
          final segLength = arcLength * segT / arcSegments;
          final nextX = current.dx + math.cos(baseAngle) * segLength;
          final nextY = current.dy + math.sin(baseAngle) * segLength;
          _siphonBeamPath.lineTo(nextX, nextY);
          current = Offset(nextX, nextY);
        }

        // Draw electric arc glow
        _siphonElectricGlowPaint.color = siphonPrimaryColor.withOpacity(0.4 * electricFlicker);
        canvas.drawPath(_siphonBeamPath, _siphonElectricGlowPaint);

        // Draw electric arc core
        _siphonElectricCorePaint.color = siphonCoreColor.withOpacity(0.8 * electricFlicker);
        canvas.drawPath(_siphonBeamPath, _siphonElectricCorePaint);
      }

      // Spark at tower end
      _siphonElectricSparkPaint.color = siphonCoreColor.withOpacity(0.7 * electricFlicker);
      canvas.drawCircle(center, 3, _siphonElectricSparkPaint);
    }

    // Electric arcs at target connection point
    final targetElectricFlicker = 0.5 + _siphonRandom.nextDouble() * 0.5;
    if (targetElectricFlicker > 0.55) {
      for (int e = 0; e < 3; e++) {
        final arcAngle = _animationPhase * -10 + e * math.pi * 2 / 3 + _siphonRandom.nextDouble() * 0.6;
        final arcLength = 6 + _siphonRandom.nextDouble() * 5;

        _siphonBeamPath.reset();
        _siphonBeamPath.moveTo(targetOffset.dx, targetOffset.dy);

        // Create jagged lightning path pointing outward
        Offset current = targetOffset;
        const arcSegments = 3;
        for (int s = 1; s <= arcSegments; s++) {
          final segT = s / arcSegments;
          final baseAngle = arcAngle + (_siphonRandom.nextDouble() - 0.5) * 1.0;
          final segLength = arcLength * segT / arcSegments;
          final nextX = current.dx + math.cos(baseAngle) * segLength;
          final nextY = current.dy + math.sin(baseAngle) * segLength;
          _siphonBeamPath.lineTo(nextX, nextY);
          current = Offset(nextX, nextY);
        }

        // Draw electric arc glow
        _siphonElectricGlowPaint.color = siphonDrainColor.withOpacity(0.35 * targetElectricFlicker);
        canvas.drawPath(_siphonBeamPath, _siphonElectricGlowPaint);

        // Draw electric arc core
        _siphonElectricCorePaint.color = siphonSecondaryColor.withOpacity(0.7 * targetElectricFlicker);
        canvas.drawPath(_siphonBeamPath, _siphonElectricCorePaint);
      }

      // Spark at target end
      _siphonElectricSparkPaint.color = siphonSecondaryColor.withOpacity(0.6 * targetElectricFlicker);
      canvas.drawCircle(targetOffset, 2.5, _siphonElectricSparkPaint);
    }
  }

  void _renderIdleEffects(Canvas canvas, Offset center) {
    switch (type) {
      case TowerType.pulseArcher:
        // Pulsing rings emanating outward - reuse static paint
        _pulseRingPaint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        for (int i = 0; i < 3; i++) {
          final phase = (_animationPhase + i * 0.3) % 1.5;
          final ringRadius = size.x * 0.3 + phase * size.x * 0.3;
          final ringAlpha = (1 - phase / 1.5) * 0.2;
          _pulseRingPaint.color = color.withOpacity(ringAlpha);
          canvas.drawCircle(center, ringRadius, _pulseRingPaint);
        }
        break;

      case TowerType.circuitCannon:
        // Heavy rotating gear-like elements
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(_animationPhase * 0.3);

        // Setup paint once for all gears
        _circuitGearPaint
          ..color = color.withOpacity(0.3 + _pulseAnimation * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        final innerR = size.x * 0.5;
        final outerR = size.x * 0.58;
        for (int i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          final cosAM = math.cos(angle - 0.15);
          final sinAM = math.sin(angle - 0.15);
          final cosA = math.cos(angle);
          final sinA = math.sin(angle);
          final cosAP = math.cos(angle + 0.15);
          final sinAP = math.sin(angle + 0.15);

          _tempPath1
            ..reset()
            ..moveTo(cosAM * innerR, sinAM * innerR)
            ..lineTo(cosA * outerR, sinA * outerR)
            ..lineTo(cosAP * innerR, sinAP * innerR);

          canvas.drawPath(_tempPath1, _circuitGearPaint);
        }
        canvas.restore();
        break;

      case TowerType.phaseMage:
        // Electric arcs dancing around
        if (_arcPoints.length > 1) {
          _phaseArcPaint.color = color.withOpacity(0.6);

          _tempPath1.reset();
          _tempPath1.moveTo(center.dx + _arcPoints[0].dx, center.dy + _arcPoints[0].dy);
          for (int i = 1; i < _arcPoints.length; i++) {
            _tempPath1.lineTo(center.dx + _arcPoints[i].dx, center.dy + _arcPoints[i].dy);
          }
          canvas.drawPath(_tempPath1, _phaseArcPaint);

          // Glow at arc tips
          _tempOffset1 = Offset(center.dx + _arcPoints.last.dx, center.dy + _arcPoints.last.dy);
          _glowDotPaint.color = color.withOpacity(0.8);
          canvas.drawCircle(_tempOffset1, 3, _glowDotPaint);
        }

        // Mystical runes rotating
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(-_animationPhase * 0.5);

        final runeRadius = size.x * 0.55;
        for (int i = 0; i < 6; i++) {
          final angle = i * math.pi / 3;
          final runeX = math.cos(angle) * runeRadius;
          final runeY = math.sin(angle) * runeRadius;
          final runeAlpha = 0.3 + math.sin(_animationPhase * 2 + i) * 0.2;

          _tempPath2
            ..reset()
            ..moveTo(runeX, runeY - 3)
            ..lineTo(runeX + 2, runeY)
            ..lineTo(runeX, runeY + 3)
            ..lineTo(runeX - 2, runeY)
            ..close();

          _runePaint.color = color.withOpacity(runeAlpha);
          canvas.drawPath(_tempPath2, _runePaint);
        }
        canvas.restore();
        break;

      case TowerType.glimmerField:
        // Rapid flickering particles in a field
        for (int i = 0; i < 8; i++) {
          final sparkAngle = _animationPhase * 4 + i * math.pi / 4;
          final sparkRadius = size.x * (0.35 + math.sin(_animationPhase * 6 + i) * 0.15);
          final sparkX = center.dx + math.cos(sparkAngle) * sparkRadius;
          final sparkY = center.dy + math.sin(sparkAngle) * sparkRadius;
          final sparkAlpha = 0.4 + math.sin(_animationPhase * 8 + i * 2) * 0.4;

          if (sparkAlpha > 0.2) {
            _tempOffset1 = Offset(sparkX, sparkY);
            _sparkPaint.color = color.withOpacity(sparkAlpha);
            canvas.drawCircle(_tempOffset1, 1.5, _sparkPaint);
          }
        }

        // Energy field waves
        final fieldRadius = size.x * 0.5 + math.sin(_animationPhase * 5) * 3;
        _fieldPaint
          ..color = color.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(center, fieldRadius, _fieldPaint);
        break;

      case TowerType.ionSniper:
        // Slow energy accumulation
        final chargeOffset = math.sin(_animationPhase * 2) * 4;
        _tempOffset1 = Offset(center.dx, center.dy + chargeOffset);
        _chargePaint
          ..color = color.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawCircle(_tempOffset1, size.x * 0.4, _chargePaint);
        break;

      case TowerType.teslaTerminal:
        // Harmonic vibration
        final scale = 1.0 + math.sin(_animationPhase * 10) * 0.05;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.scale(scale);
        _vibrationPaint
          ..color = color.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(Offset.zero, size.x * 0.4, _vibrationPaint);
        canvas.restore();
        break;

      case TowerType.resonanceSiphon:
        // Expansion waves
        final wave = (_animationPhase * 0.5) % 1.0;
        _wavePaint
          ..color = color.withOpacity(0.2 * (1 - wave))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(center, size.x * 0.6 * wave, _wavePaint);
        break;

      case TowerType.neuralDisruptor:
        // Static noise field
        if (_random.nextDouble() < 0.2) {
          _tempRect = Rect.fromCenter(center: center, width: size.x * 0.8, height: 2);
          _noisePaint.color = color.withOpacity(0.3);
          canvas.drawRect(_tempRect, _noisePaint);
        }
        break;

      case TowerType.plasmaBubble:
        // Wobbling plasma orbs orbiting the tower
        for (int i = 0; i < 4; i++) {
          final orbitAngle = _animationPhase * 2 + i * math.pi / 2;
          final orbitRadius = size.x * 0.4 + math.sin(_animationPhase * 3 + i) * 4;
          final orbX = center.dx + math.cos(orbitAngle) * orbitRadius;
          final orbY = center.dy + math.sin(orbitAngle) * orbitRadius;
          final orbAlpha = 0.4 + math.sin(_animationPhase * 4 + i * 0.5) * 0.2;
          _pulseRingPaint
            ..color = color.withOpacity(orbAlpha)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawCircle(Offset(orbX, orbY), 3 + math.sin(_animationPhase * 5 + i) * 1, _pulseRingPaint);
        }
        break;
    }
  }

  // Cached gradients for mega base to avoid allocations
  static const RadialGradient _megaBaseGradient = RadialGradient(
    colors: [Color(0xFF151520), Color(0xFF0A0A0F)],
  );

  void _renderMegaBase(Canvas canvas, Offset center) {
    for (int i = 0; i < 2; i++) {
      final radius = size.x * (0.45 - i * 0.1);
      final hexPath = NeonEffects.createHexagonPath(center, radius);

      _tempRect = Rect.fromCircle(center: center, radius: radius);
      _basePaint.shader = _megaBaseGradient.createShader(_tempRect);
      canvas.drawPath(hexPath, _basePaint);

      _baseBorderPaint
        ..color = color.withOpacity((0.6 - i * 0.2) + _pulseAnimation * 0.2)
        ..strokeWidth = 2 - i * 0.5;
      canvas.drawPath(hexPath, _baseBorderPaint);
    }
  }

  void _renderBaseTrim(Canvas canvas, Offset center) {
    final trimRadius = size.x * 0.52;
    _dotTrimPaint.color = color.withOpacity(0.25 + _pulseAnimation * 0.1);

    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final dx = math.cos(angle) * trimRadius;
      final dy = math.sin(angle) * trimRadius;
      _tempOffset1 = Offset(center.dx + dx, center.dy + dy);
      canvas.drawCircle(_tempOffset1, 1.6, _dotTrimPaint);
    }

    _panelTrimPaint
      ..color = color.withOpacity(0.18 + _pulseAnimation * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final inner = size.x * 0.22;
    final outer = size.x * 0.38;
    for (int i = 0; i < 3; i++) {
      final angle = i * math.pi / 3;
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);
      _tempOffset1 = Offset(center.dx + cosA * inner, center.dy + sinA * inner);
      _tempOffset2 = Offset(center.dx + cosA * outer, center.dy + sinA * outer);
      canvas.drawLine(_tempOffset1, _tempOffset2, _panelTrimPaint);
    }
  }

  void _renderOrbitParticles(Canvas canvas, Offset center) {
    for (final particle in _orbitParticles) {
      final px = center.dx + math.cos(particle.angle) * particle.radius;
      final py = center.dy + math.sin(particle.angle) * particle.radius;
      final alpha = 0.5 + math.sin(_animationPhase * 3 + particle.phase) * 0.3;
      _tempOffset1 = Offset(px, py);

      // Particle glow
      _particleGlowPaint.color = color.withOpacity(alpha * 0.3);
      canvas.drawCircle(_tempOffset1, particle.size * 2, _particleGlowPaint);

      // Particle core
      _particleCorePaint.color = color.withOpacity(alpha);
      canvas.drawCircle(_tempOffset1, particle.size, _particleCorePaint);
    }
  }

  void _renderTypeDecoration(Canvas canvas, Offset center) {
    switch (type) {
      case TowerType.pulseArcher:
        // Concentric arc segments
        _decorArcPaint.color = color.withOpacity(0.3);
        for (int ring = 0; ring < 2; ring++) {
          final ringRadius = size.x * (0.25 + ring * 0.08);
          _tempRect = Rect.fromCircle(center: center, radius: ringRadius);
          for (int i = 0; i < 4; i++) {
            final startAngle = i * math.pi / 2 + _animationPhase * 0.5;
            canvas.drawArc(_tempRect, startAngle, math.pi / 4, false, _decorArcPaint);
          }
        }
        break;

      case TowerType.circuitCannon:
        // Heavy plating lines
        _decorPlatePaint
          ..color = color.withOpacity(0.4)
          ..strokeWidth = 2;

        final halfWidth = size.x * 0.25;
        for (int i = 0; i < 3; i++) {
          final offset = (i - 1) * 6.0;
          _tempOffset1 = Offset(center.dx - halfWidth, center.dy + offset);
          _tempOffset2 = Offset(center.dx + halfWidth, center.dy + offset);
          canvas.drawLine(_tempOffset1, _tempOffset2, _decorPlatePaint);
        }
        break;

      case TowerType.phaseMage:
        // Inner mystic circle
        _decorCirclePaint
          ..color = color.withOpacity(0.2 + _pulseAnimation * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawCircle(center, size.x * 0.22, _decorCirclePaint);
        break;

      case TowerType.glimmerField:
        // Radiating lines
        _decorLinePaint
          ..color = color.withOpacity(0.3)
          ..strokeWidth = 1;
        final inner = size.x * 0.15;
        final outer = size.x * 0.3;
        for (int i = 0; i < 8; i++) {
          final angle = i * math.pi / 4 + _animationPhase;
          final cosA = math.cos(angle);
          final sinA = math.sin(angle);
          _tempOffset1 = Offset(center.dx + cosA * inner, center.dy + sinA * inner);
          _tempOffset2 = Offset(center.dx + cosA * outer, center.dy + sinA * outer);
          canvas.drawLine(_tempOffset1, _tempOffset2, _decorLinePaint);
        }
        break;

      case TowerType.ionSniper:
        // Long cooling fins
        _decorPinPaint.color = color.withOpacity(0.5);
        for (int i = 0; i < 4; i++) {
          final angle = i * math.pi / 2 + math.pi / 4;
          final cosA = math.cos(angle);
          final sinA = math.sin(angle);
          _tempOffset1 = Offset(center.dx + cosA * 10, center.dy + sinA * 10);
          _tempOffset2 = Offset(center.dx + cosA * 25, center.dy + sinA * 25);
          canvas.drawLine(_tempOffset1, _tempOffset2, _decorPinPaint);
        }
        break;

      case TowerType.teslaTerminal:
        // Coils
        _decorCoilPaint.color = color.withOpacity(0.2);
        for (int i = 0; i < 3; i++) {
          canvas.drawCircle(center, 10 + i * 5.0, _decorCoilPaint);
        }
        break;

      case TowerType.resonanceSiphon:
        // Siphon triangles
        _decorTrianglePaint.color = color;
        for (int i = 0; i < 3; i++) {
          final angle = i * 2 * math.pi / 3 + _animationPhase;
          _tempOffset1 = Offset(center.dx + math.cos(angle) * 15, center.dy + math.sin(angle) * 15);
          canvas.drawCircle(_tempOffset1, 3, _decorTrianglePaint);
        }
        break;

      case TowerType.neuralDisruptor:
        // Binary patterns - skip for performance (10% chance)
        break;

      case TowerType.plasmaBubble:
        // Bubble-like decoration circles
        for (int i = 0; i < 4; i++) {
          final bubbleAngle = i * math.pi / 2 + _animationPhase * 0.8;
          final bubbleRadius = size.x * 0.3;
          final bx = center.dx + math.cos(bubbleAngle) * bubbleRadius;
          final by = center.dy + math.sin(bubbleAngle) * bubbleRadius;
          _decorCirclePaint.color = color.withOpacity(0.25 + math.sin(_animationPhase * 3 + i) * 0.1);
          canvas.drawCircle(Offset(bx, by), 4, _decorCirclePaint);
        }
        break;
    }
  }

  void _renderEnergyCore(Canvas canvas) {
    // Pulse faster when charging/firing
    final pulseSpeed = _isFiring ? 8.0 : (_chargeLevel > 0 ? 4.0 + _chargeLevel * 4.0 : 2.0);
    final corePulse = math.sin(_animationPhase * pulseSpeed);
    final baseCoreSize = size.x * 0.18;
    final coreSize = baseCoreSize + (_chargeLevel * size.x * 0.06) + corePulse * baseCoreSize * 0.1;
    final reduceFx = Tower.lowFx;

    // ═══════════════════════════════════════════════════════════════════════════
    // LAYER 6: Core intensity pulse based on charge level (background flash)
    // ═══════════════════════════════════════════════════════════════════════════
    if (!reduceFx && (_chargeLevel > 0.3 || _isFiring)) {
      final intensityPulse = math.sin(_animationPhase * pulseSpeed * 1.5) * 0.5 + 0.5;
      final flashIntensity = _isFiring ? 0.4 : _chargeLevel * 0.3;
      _energyCoreIntensityPaint.color = color.withOpacity(flashIntensity * intensityPulse);
      canvas.drawCircle(Offset.zero, coreSize * 2.5, _energyCoreIntensityPaint);

      // Extra flash burst when firing
      if (_isFiring) {
        final flashPulse = ((_animationPhase * 12) % 1.0);
        if (flashPulse < 0.3) {
          final flashAlpha = (1 - flashPulse / 0.3) * 0.5;
          _energyCoreFlashPaint.color = color.withOpacity(flashAlpha);
          canvas.drawCircle(Offset.zero, coreSize * 3, _energyCoreFlashPaint);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LAYER 5: Plasma tendrils emanating from core
    // ═══════════════════════════════════════════════════════════════════════════
    if (!reduceFx) {
      final tendrilCount = switch (type) {
        TowerType.teslaTerminal => 6,
        TowerType.ionSniper => 4,
        TowerType.phaseMage => 5,
        _ => 4
      };
      for (int i = 0; i < tendrilCount; i++) {
        final baseAngle = (i * 2 * math.pi / tendrilCount) + _animationPhase * 1.5;
        final tendrilLength = coreSize * (1.2 + corePulse * 0.3 + _chargeLevel * 0.5);

        // Build tendril path with sine wave distortion
        _energyCorePath.reset();
        _energyCorePath.moveTo(0, 0);

        const segments = 8;
        for (int s = 1; s <= segments; s++) {
          final t = s / segments;
          final dist = tendrilLength * t;
          // Tendril wiggles with phase offset
          final wiggle = math.sin(_animationPhase * 6 + t * math.pi * 3 + i) * (5 * t);
          final perpAngle = baseAngle + math.pi / 2;
          final px = math.cos(baseAngle) * dist + math.cos(perpAngle) * wiggle;
          final py = math.sin(baseAngle) * dist + math.sin(perpAngle) * wiggle;
          _energyCorePath.lineTo(px, py);
        }

        // Tendril glow
        _energyCoreTendrilGlowPaint.color = color.withOpacity(0.15 + _chargeLevel * 0.1);
        canvas.drawPath(_energyCorePath, _energyCoreTendrilGlowPaint);

        // Tendril core
        _energyCoreTendrilPaint.color = color.withOpacity(0.4 + _chargeLevel * 0.2);
        canvas.drawPath(_energyCorePath, _energyCoreTendrilPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LAYER 4: Energy conduit lines from core to tower edges
    // ═══════════════════════════════════════════════════════════════════════════
    if (!reduceFx) {
      const conduitCount = 6;
      final conduitLength = size.x * 0.35;
      for (int i = 0; i < conduitCount; i++) {
        final angle = (i * math.pi / 3) + math.pi / 6; // Offset to align with hexagon edges

        // Animated energy pulse along conduit
        final pulseProgress = ((_animationPhase * 3 + i * 0.2) % 1.0);
        final pulsePos = pulseProgress * conduitLength;

        // Conduit line
        final endX = math.cos(angle) * conduitLength;
        final endY = math.sin(angle) * conduitLength;

        // Conduit glow
        _energyCoreConduitGlowPaint.color = color.withOpacity(0.15);
        canvas.drawLine(Offset.zero, Offset(endX, endY), _energyCoreConduitGlowPaint);

        // Conduit core
        _energyCoreConduitPaint.color = color.withOpacity(0.4);
        canvas.drawLine(Offset.zero, Offset(endX, endY), _energyCoreConduitPaint);

        // Energy pulse traveling along conduit
        final pulseX = math.cos(angle) * pulsePos;
        final pulseY = math.sin(angle) * pulsePos;
        final pulseBrightness = 0.5 + corePulse * 0.3;
        _energyCoreConduitNodePaint.color = color.withOpacity(pulseBrightness);
        canvas.drawCircle(Offset(pulseX, pulseY), 2.5 + _chargeLevel * 1.5, _energyCoreConduitNodePaint);

        // Node at conduit end
        final nodePulse = math.sin(_animationPhase * 4 + i * 1.2) * 0.3 + 0.5;
        _energyCoreConduitNodePaint.color = color.withOpacity(0.3 * nodePulse);
        canvas.drawCircle(Offset(endX, endY), 3, _energyCoreConduitNodePaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LAYER 3: Orbiting energy particles around the core
    // ═══════════════════════════════════════════════════════════════════════════
    if (!reduceFx) {
      const particleCount = 8;
      for (int i = 0; i < particleCount; i++) {
        // Each particle orbits at different speed and radius
        final orbitSpeed = 2.0 + (i % 3) * 0.5;
        final orbitRadius = coreSize * (0.9 + (i % 4) * 0.15);
        final particleAngle = _animationPhase * orbitSpeed + (i * 2 * math.pi / particleCount);

        // Particle position with slight vertical oscillation for 3D effect
        final verticalOffset = math.sin(_animationPhase * 3 + i * 0.8) * 2;
        final px = math.cos(particleAngle) * orbitRadius;
        final py = math.sin(particleAngle) * orbitRadius + verticalOffset;

        // Particle trail
        final trailAngle = particleAngle - 0.4;
        final trailX = math.cos(trailAngle) * orbitRadius * 0.95;
        final trailY = math.sin(trailAngle) * orbitRadius * 0.95 + verticalOffset * 0.8;

        _energyCoreParticleTrailPaint.color = color.withOpacity(0.2);
        canvas.drawLine(Offset(trailX, trailY), Offset(px, py), _energyCoreParticleTrailPaint);

        // Particle glow
        final particleBrightness = 0.4 + math.sin(_animationPhase * 5 + i) * 0.2;
        final particleSize = 2.0 + _chargeLevel * 1.5;
        _energyCoreParticlePaint.color = color.withOpacity(particleBrightness);
        canvas.drawCircle(Offset(px, py), particleSize, _energyCoreParticlePaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LAYER 2: Rotating energy rings around the core
    // ═══════════════════════════════════════════════════════════════════════════
    if (!reduceFx) {
      // Ring 1: Horizontal ring (appears as ellipse due to perspective)
      final ring1Radius = coreSize * 1.1;
      final ring1Rotation = _animationPhase * 2;
      _tempRect = Rect.fromCenter(
        center: Offset.zero,
        width: ring1Radius * 2,
        height: ring1Radius * 0.4, // Flattened for perspective
      );

      canvas.save();
      canvas.rotate(ring1Rotation);
      _energyCoreRingGlowPaint.color = color.withOpacity(0.15);
      canvas.drawOval(_tempRect, _energyCoreRingGlowPaint);
      _energyCoreRingPaint.color = color.withOpacity(0.4);
      canvas.drawOval(_tempRect, _energyCoreRingPaint);
      canvas.restore();

      // Ring 2: Perpendicular ring (different rotation)
      final ring2Rotation = -_animationPhase * 1.5 + math.pi / 3;
      _tempRect = Rect.fromCenter(
        center: Offset.zero,
        width: ring1Radius * 1.15 * 2,
        height: ring1Radius * 1.15 * 0.35,
      );

      canvas.save();
      canvas.rotate(ring2Rotation);
      _energyCoreRingGlowPaint.color = color.withOpacity(0.1);
      canvas.drawOval(_tempRect, _energyCoreRingGlowPaint);
      _energyCoreRingPaint.color = color.withOpacity(0.3);
      canvas.drawOval(_tempRect, _energyCoreRingPaint);
      canvas.restore();

      // Ring 3: Outermost ring (slowest rotation)
      if (_chargeLevel > 0.2 || _isFiring) {
        final ring3Rotation = _animationPhase * 0.8 + math.pi / 6;
        final ring3Radius = coreSize * 1.3 + _chargeLevel * coreSize * 0.3;
        _tempRect = Rect.fromCenter(
          center: Offset.zero,
          width: ring3Radius * 2,
          height: ring3Radius * 0.3,
        );

        canvas.save();
        canvas.rotate(ring3Rotation);
        _energyCoreRingGlowPaint.color = color.withOpacity(0.2 * _chargeLevel);
        canvas.drawOval(_tempRect, _energyCoreRingGlowPaint);
        _energyCoreRingPaint.color = color.withOpacity(0.5 * _chargeLevel);
        canvas.drawOval(_tempRect, _energyCoreRingPaint);
        canvas.restore();
      }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LAYER 1: Inner core sphere with pulsing glow
    // ═══════════════════════════════════════════════════════════════════════════
    // Outer glow
    if (!reduceFx) {
      _energyCoreInnerGlowPaint.color = color.withOpacity(0.25 + corePulse * 0.1 + _chargeLevel * 0.15);
      canvas.drawCircle(Offset.zero, coreSize * 1.6, _energyCoreInnerGlowPaint);
    }

    // Core gradient sphere
    final brightColor = Color.lerp(color, const Color(0xFFFFFFFF), 0.5)!;
    _tempRect = Rect.fromCircle(center: Offset.zero, radius: coreSize);
    final coreGradient = RadialGradient(
      colors: [
        brightColor,
        color,
        color.withOpacity(0.6),
        color.withOpacity(0.2),
      ],
      stops: const [0, 0.35, 0.65, 1],
    ).createShader(_tempRect);

    _energyCoreSpherePaint.shader = coreGradient;
    canvas.drawCircle(Offset.zero, coreSize, _energyCoreSpherePaint);

    // Bright center highlight
    final centerPulse = 0.7 + corePulse * 0.2 + _chargeLevel * 0.1;
    _energyCoreBrightCenterPaint.color = const Color(0xFFFFFFFF).withOpacity(centerPulse);
    canvas.drawCircle(Offset.zero, coreSize * 0.35, _energyCoreBrightCenterPaint);

    // Inner spark highlight (offset for 3D effect)
    if (!reduceFx) {
      final sparkOffset = Offset(-coreSize * 0.15, -coreSize * 0.15);
      _energyCoreBrightCenterPaint.color = const Color(0xFFFFFFFF).withOpacity(0.6);
      canvas.drawCircle(sparkOffset, coreSize * 0.12, _energyCoreBrightCenterPaint);
    }

    // Rotating Energy Arms (kept from original for continuity)
    final arms = switch (type) {
      TowerType.ionSniper => 2,
      TowerType.teslaTerminal => 4,
      _ => 3
    };
    _coreArmPaint.color = color.withOpacity(0.5 + _chargeLevel * 0.2);
    final armLength = coreSize * (1.1 + _chargeLevel * 0.3);
    for (int i = 0; i < arms; i++) {
      final angle = (i * 2 * math.pi / arms) + _animationPhase * pulseSpeed * 0.5;
      _tempOffset1 = Offset(math.cos(angle) * armLength, math.sin(angle) * armLength);
      canvas.drawLine(Offset.zero, _tempOffset1, _coreArmPaint);
    }
  }

  void _renderTurretHead(Canvas canvas) {
    final s = size.x;
    _turretFillPaint.color = color.withOpacity(0.55);
    _turretAccentPaint.color = Colors.white.withOpacity(0.35 + _pulseAnimation * 0.2);
    _turretStrokePaint.color = color.withOpacity(0.9);

    switch (type) {
      case TowerType.pulseArcher:
        _turretProngPaint
          ..color = color.withOpacity(0.8)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        final prongOffset = s * 0.12;
        final prongEnd = s * 0.42;
        _tempOffset1 = Offset(s * 0.05, -prongOffset);
        _tempOffset2 = Offset(prongEnd, -prongOffset * 1.4);
        canvas.drawLine(_tempOffset1, _tempOffset2, _turretProngPaint);
        _tempOffset1 = Offset(s * 0.05, prongOffset);
        _tempOffset2 = Offset(prongEnd, prongOffset * 1.4);
        canvas.drawLine(_tempOffset1, _tempOffset2, _turretProngPaint);
        _tempPath1
          ..reset()
          ..moveTo(s * 0.45, 0)
          ..lineTo(s * 0.58, -s * 0.08)
          ..lineTo(s * 0.58, s * 0.08)
          ..close();
        canvas.drawPath(_tempPath1, _turretFillPaint);
        canvas.drawPath(_tempPath1, _turretStrokePaint);
        break;

      case TowerType.circuitCannon:
        final barrelRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(s * 0.25, 0), width: s * 0.5, height: s * 0.18),
          Radius.circular(s * 0.05),
        );
        canvas.drawRRect(barrelRect, _turretFillPaint);
        canvas.drawRRect(barrelRect, _turretStrokePaint);
        _tempOffset1 = Offset(s * 0.5, 0);
        canvas.drawCircle(_tempOffset1, s * 0.08, _turretStrokePaint);
        canvas.drawCircle(_tempOffset1, s * 0.04, _turretAccentPaint);
        _turretVentPaint
          ..color = color.withOpacity(0.6)
          ..strokeWidth = 1.2;
        _tempOffset1 = Offset(s * 0.05, -s * 0.06);
        _tempOffset2 = Offset(s * 0.2, -s * 0.06);
        canvas.drawLine(_tempOffset1, _tempOffset2, _turretVentPaint);
        _tempOffset1 = Offset(s * 0.05, s * 0.06);
        _tempOffset2 = Offset(s * 0.2, s * 0.06);
        canvas.drawLine(_tempOffset1, _tempOffset2, _turretVentPaint);
        break;

      case TowerType.phaseMage:
        _turretPrismPaint.color = color.withOpacity(0.45);
        _tempPath1
          ..reset()
          ..moveTo(s * 0.08, -s * 0.22)
          ..lineTo(s * 0.48, 0)
          ..lineTo(s * 0.08, s * 0.22)
          ..close();
        canvas.drawPath(_tempPath1, _turretPrismPaint);
        canvas.drawPath(_tempPath1, _turretStrokePaint);
        _tempOffset1 = Offset(s * 0.15, 0);
        canvas.drawCircle(_tempOffset1, s * 0.12, _turretStrokePaint);
        canvas.drawCircle(_tempOffset1, s * 0.05, _turretAccentPaint);
        break;

      case TowerType.glimmerField:
        _turretPetalPaint.color = color.withOpacity(0.55);
        final petalRadius = s * 0.34;
        for (int i = -1; i <= 1; i++) {
          final angle = i * 0.35;
          _tempOffset1 = Offset(math.cos(angle) * petalRadius, math.sin(angle) * petalRadius);
          canvas.drawCircle(_tempOffset1, s * 0.06, _turretPetalPaint);
          canvas.drawCircle(_tempOffset1, s * 0.06, _turretStrokePaint);
        }
        _tempOffset1 = Offset(s * 0.12, 0);
        canvas.drawCircle(_tempOffset1, s * 0.04, _turretAccentPaint);
        break;

      case TowerType.ionSniper:
        final railRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.02, -s * 0.05, s * 0.62, s * 0.1),
          Radius.circular(s * 0.04),
        );
        canvas.drawRRect(railRect, _turretFillPaint);
        canvas.drawRRect(railRect, _turretStrokePaint);
        _tempOffset1 = Offset(s * 0.58, 0);
        canvas.drawCircle(_tempOffset1, s * 0.07, _turretStrokePaint);
        canvas.drawCircle(_tempOffset1, s * 0.03, _turretAccentPaint);
        break;

      case TowerType.teslaTerminal:
        _turretProngPaint
          ..color = color.withOpacity(0.8)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        _tempOffset1 = Offset(s * 0.05, -s * 0.2);
        _tempOffset2 = Offset(s * 0.32, -s * 0.3);
        canvas.drawLine(_tempOffset1, _tempOffset2, _turretProngPaint);
        _tempOffset1 = Offset(s * 0.05, s * 0.2);
        _tempOffset2 = Offset(s * 0.32, s * 0.3);
        canvas.drawLine(_tempOffset1, _tempOffset2, _turretProngPaint);
        _tempOffset1 = Offset(s * 0.1, 0);
        canvas.drawCircle(_tempOffset1, s * 0.12, _turretStrokePaint);
        canvas.drawCircle(_tempOffset1, s * 0.05, _turretAccentPaint);
        break;

      case TowerType.resonanceSiphon:
        _turretFunnelPaint.color = color.withOpacity(0.5);
        _tempPath1
          ..reset()
          ..moveTo(s * 0.08, -s * 0.22)
          ..lineTo(s * 0.5, 0)
          ..lineTo(s * 0.08, s * 0.22)
          ..close();
        canvas.drawPath(_tempPath1, _turretFunnelPaint);
        canvas.drawPath(_tempPath1, _turretStrokePaint);
        _tempOffset1 = Offset(s * 0.22, 0);
        canvas.drawCircle(_tempOffset1, s * 0.06, _turretAccentPaint);
        break;

      case TowerType.neuralDisruptor:
        _tempRect = Rect.fromCenter(center: Offset(s * 0.22, 0), width: s * 0.24, height: s * 0.24);
        canvas.drawRect(_tempRect, _turretFillPaint);
        canvas.drawRect(_tempRect, _turretStrokePaint);
        _tempRect = Rect.fromLTWH(s * 0.38, -s * 0.05, s * 0.12, s * 0.1);
        canvas.drawRect(_tempRect, _turretAccentPaint);
        break;

      case TowerType.plasmaBubble:
        // Rounded bubble launcher nozzle
        canvas.drawCircle(Offset(s * 0.25, 0), s * 0.12, _turretFillPaint);
        canvas.drawCircle(Offset(s * 0.25, 0), s * 0.12, _turretStrokePaint);
        canvas.drawCircle(Offset(s * 0.38, 0), s * 0.08, _turretAccentPaint);
        break;
    }
  }

  void _renderTargetingLens(Canvas canvas) {
    final lensRadius = size.x * 0.15 * (1 + _chargeLevel * 0.2);
    _tempOffset1 = Offset(size.x * 0.3, 0);
    _targetLensFillPaint.color = color.withOpacity(0.2);
    canvas.drawCircle(_tempOffset1, lensRadius, _targetLensFillPaint);
    _targetLensStrokePaint.color = color.withOpacity(0.8);
    canvas.drawCircle(_tempOffset1, lensRadius, _targetLensStrokePaint);
  }

  void _renderTargetingLine(Canvas canvas) {
    final lineLength = size.x * 0.5;
    final reticleX = size.x * 0.45;
    final reticleCenter = Offset(reticleX, 0);

    // Get secondary color for visual variety
    final hslColor = HSLColor.fromColor(color);
    final secondaryColor = hslColor.withHue((hslColor.hue + 60) % 360).toColor();

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: HOLOGRAPHIC TARGETING BEAM
    // ═══════════════════════════════════════════════════════════════════════
    _tempOffset1 = Offset(lineLength, 0);

    // Outer glow beam
    if (!Tower.lowFx) {
      _targetLineGlowPaint.color = color.withOpacity(0.25);
      canvas.drawLine(Offset.zero, _tempOffset1, _targetLineGlowPaint);
    }

    // Core beam with pulse effect
    final beamPulse = 0.5 + math.sin(_animationPhase * 6) * 0.2;
    _targetLineCorePaint.color = color.withOpacity(beamPulse);
    canvas.drawLine(Offset.zero, _tempOffset1, _targetLineCorePaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: DATA FLOW PARTICLES ALONG BEAM
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < 5; i++) {
      final dashProgress = (_animationPhase * 3 + i * 0.2) % 1;
      final dashPos = dashProgress * lineLength;
      final dashAlpha = 0.6 + math.sin(_animationPhase * 8 + i) * 0.3;

      // Data particle glow
      if (!Tower.lowFx) {
        _targetDashPaint.color = color.withOpacity(dashAlpha * 0.4);
        canvas.drawCircle(Offset(dashPos, 0), 3, _targetDashPaint);
      }

      // Data particle core
      _targetDashPaint.color = const Color(0xFFFFFFFF).withOpacity(dashAlpha * 0.7);
      canvas.drawCircle(Offset(dashPos, 0), 1.5, _targetDashPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: HOLOGRAPHIC RETICLE OUTER GLOW
    // ═══════════════════════════════════════════════════════════════════════
    final reticlePulse = 1 + math.sin(_animationPhase * 4) * 0.2;
    final reticleRadius = 8 * reticlePulse;

    if (!Tower.lowFx) {
      _holoReticleFillPaint.color = color.withOpacity(0.15);
      canvas.drawCircle(reticleCenter, reticleRadius * 1.5, _holoReticleFillPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: ROTATING HOLOGRAPHIC RINGS
    // ═══════════════════════════════════════════════════════════════════════
    canvas.save();
    canvas.translate(reticleCenter.dx, reticleCenter.dy);

    // Outer rotating ring
    canvas.save();
    canvas.rotate(_animationPhase * 2);
    _holoReticleOuterPaint.color = color.withOpacity(0.5);
    canvas.drawCircle(Offset.zero, reticleRadius, _holoReticleOuterPaint);

    // Ring break markers
    for (int i = 0; i < 4; i++) {
      final markerAngle = i * math.pi / 2;
      final mx = math.cos(markerAngle) * reticleRadius;
      final my = math.sin(markerAngle) * reticleRadius;
      _holoReticleMarkerPaint.color = const Color(0xFFFFFFFF).withOpacity(0.8);
      canvas.drawCircle(Offset(mx, my), 1.5, _holoReticleMarkerPaint);
    }
    canvas.restore();

    // Inner counter-rotating ring
    canvas.save();
    canvas.rotate(-_animationPhase * 3);
    _holoReticleCorePaint.color = secondaryColor.withOpacity(0.6);
    canvas.drawCircle(Offset.zero, reticleRadius * 0.6, _holoReticleCorePaint);
    canvas.restore();

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: SCANNING ARCS
    // ═══════════════════════════════════════════════════════════════════════
    final scanAngle = _animationPhase * 4;

    for (int arc = 0; arc < 2; arc++) {
      final arcStartAngle = scanAngle + arc * math.pi;
      final arcRadius = reticleRadius * (0.7 + arc * 0.2);
      final arcAlpha = 0.6 + math.sin(_animationPhase * 6 + arc) * 0.2;

      _holoReticleArcPaint.color = color.withOpacity(arcAlpha);
      _holoReticlePath.reset();
      _holoReticlePath.addArc(
        Rect.fromCircle(center: Offset.zero, radius: arcRadius),
        arcStartAngle,
        math.pi * 0.4,
      );
      canvas.drawPath(_holoReticlePath, _holoReticleArcPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: CROSSHAIR LINES
    // ═══════════════════════════════════════════════════════════════════════
    final crosshairLength = reticleRadius * 1.3;
    final crosshairGap = reticleRadius * 0.3;
    final crosshairAlpha = 0.7 + math.sin(_animationPhase * 5) * 0.2;

    _targetCrosshairPaint.color = color.withOpacity(crosshairAlpha);

    // Horizontal crosshairs
    canvas.drawLine(Offset(-crosshairLength, 0), Offset(-crosshairGap, 0), _targetCrosshairPaint);
    canvas.drawLine(Offset(crosshairGap, 0), Offset(crosshairLength, 0), _targetCrosshairPaint);

    // Vertical crosshairs
    canvas.drawLine(Offset(0, -crosshairLength), Offset(0, -crosshairGap), _targetCrosshairPaint);
    canvas.drawLine(Offset(0, crosshairGap), Offset(0, crosshairLength), _targetCrosshairPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: CORNER BRACKETS
    // ═══════════════════════════════════════════════════════════════════════
    final bracketSize = reticleRadius * 0.9;
    final bracketLength = 4.0;

    _holoReticleDataPaint.color = color.withOpacity(0.7);

    // Top-left bracket
    canvas.drawLine(Offset(-bracketSize, -bracketSize), Offset(-bracketSize + bracketLength, -bracketSize), _holoReticleDataPaint);
    canvas.drawLine(Offset(-bracketSize, -bracketSize), Offset(-bracketSize, -bracketSize + bracketLength), _holoReticleDataPaint);

    // Top-right bracket
    canvas.drawLine(Offset(bracketSize, -bracketSize), Offset(bracketSize - bracketLength, -bracketSize), _holoReticleDataPaint);
    canvas.drawLine(Offset(bracketSize, -bracketSize), Offset(bracketSize, -bracketSize + bracketLength), _holoReticleDataPaint);

    // Bottom-left bracket
    canvas.drawLine(Offset(-bracketSize, bracketSize), Offset(-bracketSize + bracketLength, bracketSize), _holoReticleDataPaint);
    canvas.drawLine(Offset(-bracketSize, bracketSize), Offset(-bracketSize, bracketSize - bracketLength), _holoReticleDataPaint);

    // Bottom-right bracket
    canvas.drawLine(Offset(bracketSize, bracketSize), Offset(bracketSize - bracketLength, bracketSize), _holoReticleDataPaint);
    canvas.drawLine(Offset(bracketSize, bracketSize), Offset(bracketSize, bracketSize - bracketLength), _holoReticleDataPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 8: HEXAGONAL TARGETING PATTERN
    // ═══════════════════════════════════════════════════════════════════════
    if (!Tower.lowFx) {
      canvas.save();
      canvas.rotate(_animationPhase * 1.5);

      final hexRadius = reticleRadius * 0.5;
      final hexAlpha = 0.4 + math.sin(_animationPhase * 3) * 0.2;
      _holoReticleHexPaint.color = secondaryColor.withOpacity(hexAlpha);

      _holoReticlePath.reset();
      for (int i = 0; i < 6; i++) {
        final hexAngle = i * math.pi / 3;
        final hx = math.cos(hexAngle) * hexRadius;
        final hy = math.sin(hexAngle) * hexRadius;
        if (i == 0) {
          _holoReticlePath.moveTo(hx, hy);
        } else {
          _holoReticlePath.lineTo(hx, hy);
        }
      }
      _holoReticlePath.close();
      canvas.drawPath(_holoReticlePath, _holoReticleHexPaint);
      canvas.restore();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 9: SCANNING SWEEP EFFECT
    // ═══════════════════════════════════════════════════════════════════════
    if (!Tower.lowFx) {
      final sweepAngle = _animationPhase * 5;
      final sweepLength = reticleRadius * 1.2;

      for (int sweep = 0; sweep < 2; sweep++) {
        final sweepStartAngle = sweepAngle + sweep * math.pi;
        final sweepAlpha = 0.3 + math.sin(_animationPhase * 8 + sweep) * 0.15;

        final sx = math.cos(sweepStartAngle) * sweepLength;
        final sy = math.sin(sweepStartAngle) * sweepLength;

        _holoReticleScanPaint.color = color.withOpacity(sweepAlpha);
        canvas.drawLine(Offset.zero, Offset(sx, sy), _holoReticleScanPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 10: CENTER TARGET DOT
    // ═══════════════════════════════════════════════════════════════════════
    final dotPulse = 0.7 + math.sin(_animationPhase * 8) * 0.3;

    // Center glow
    _holoReticleMarkerPaint.color = color.withOpacity(dotPulse * 0.5);
    canvas.drawCircle(Offset.zero, 3, _holoReticleMarkerPaint);

    // Center bright dot
    _holoReticleMarkerPaint.color = const Color(0xFFFFFFFF).withOpacity(dotPulse);
    canvas.drawCircle(Offset.zero, 1.5, _holoReticleMarkerPaint);

    canvas.restore();

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 11: DISTANCE MARKERS ALONG BEAM
    // ═══════════════════════════════════════════════════════════════════════
    for (int marker = 1; marker < 4; marker++) {
      final markerX = marker * lineLength / 4;
      final markerAlpha = 0.4 + math.sin(_animationPhase * 4 + marker) * 0.2;

      _holoReticleDataPaint.color = color.withOpacity(markerAlpha);

      // Small tick marks
      canvas.drawLine(Offset(markerX, -2), Offset(markerX, 2), _holoReticleDataPaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DAMAGE FRACTURE EFFECT
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderDamageFractures(Canvas canvas, Offset center) {
    // Damage intensity scales from 0 at 50% health to 1 at 0% health
    final damageIntensity = (1.0 - healthPercent * 2).clamp(0.0, 1.0);
    final time = _animationPhase;

    // Damage colors - cyberpunk red/orange energy leaking
    const damageColorCore = Color(0xFFFF4400); // Deep orange
    const damageColorGlow = Color(0xFFFF2200); // Red-orange
    const damageColorEnergy = Color(0xFFFFAA00); // Yellow-orange energy

    // If no impact points exist yet, generate based on damage
    if (_fractureImpactPoints.isEmpty && damageIntensity > 0.1) {
      final impactCount = (damageIntensity * 3).ceil().clamp(1, _maxFractureImpacts);
      for (int i = 0; i < impactCount; i++) {
        final angle = _fractureRandom.nextDouble() * math.pi * 2;
        final distance = size.x * 0.15 + _fractureRandom.nextDouble() * size.x * 0.2;
        _fractureImpactPoints.add(_FractureImpactPoint(
          offset: Offset(math.cos(angle) * distance, math.sin(angle) * distance),
          angle: angle,
          intensity: 0.5 + _fractureRandom.nextDouble() * 0.5,
          branchCount: 2 + _fractureRandom.nextInt(3),
        ));
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: Main fracture lines radiating from impact points
    // ═══════════════════════════════════════════════════════════════════════
    for (final impact in _fractureImpactPoints) {
      final impactPos = center + impact.offset;
      final numCracks = 3 + (damageIntensity * 4).toInt();

      for (int i = 0; i < numCracks; i++) {
        final crackAngle = impact.angle + (i - numCracks / 2) * 0.4 +
            math.sin(time * 0.5 + i) * 0.05;
        final crackLength = size.x * (0.2 + damageIntensity * 0.25) * impact.intensity;

        // Glow layer
        _fracturePrimaryGlowPaint.color = damageColorGlow.withOpacity(
            0.4 * damageIntensity * impact.intensity);
        canvas.drawLine(
          impactPos,
          Offset(
            impactPos.dx + math.cos(crackAngle) * crackLength,
            impactPos.dy + math.sin(crackAngle) * crackLength,
          ),
          _fracturePrimaryGlowPaint,
        );

        // Core line
        _fracturePrimaryPaint.color = damageColorCore.withOpacity(
            0.7 * damageIntensity * impact.intensity);
        canvas.drawLine(
          impactPos,
          Offset(
            impactPos.dx + math.cos(crackAngle) * crackLength,
            impactPos.dy + math.sin(crackAngle) * crackLength,
          ),
          _fracturePrimaryPaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: Secondary crack branches
    // ═══════════════════════════════════════════════════════════════════════
    for (final impact in _fractureImpactPoints) {
      final impactPos = center + impact.offset;

      for (int branch = 0; branch < impact.branchCount; branch++) {
        final baseAngle = impact.angle + (branch - impact.branchCount / 2) * 0.6;
        final branchStart = size.x * 0.12;
        final branchLength = size.x * (0.08 + damageIntensity * 0.12);

        // Start point along main crack
        final startX = impactPos.dx + math.cos(baseAngle) * branchStart;
        final startY = impactPos.dy + math.sin(baseAngle) * branchStart;

        // Branch off at an angle
        final branchAngle = baseAngle + (branch % 2 == 0 ? 0.7 : -0.7) +
            _fractureRandom.nextDouble() * 0.3;

        _fractureSecondaryGlowPaint.color = damageColorGlow.withOpacity(
            0.3 * damageIntensity * impact.intensity);
        canvas.drawLine(
          Offset(startX, startY),
          Offset(
            startX + math.cos(branchAngle) * branchLength,
            startY + math.sin(branchAngle) * branchLength,
          ),
          _fractureSecondaryGlowPaint,
        );

        _fractureSecondaryPaint.color = damageColorCore.withOpacity(
            0.5 * damageIntensity * impact.intensity);
        canvas.drawLine(
          Offset(startX, startY),
          Offset(
            startX + math.cos(branchAngle) * branchLength,
            startY + math.sin(branchAngle) * branchLength,
          ),
          _fractureSecondaryPaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: Glowing edges on fractures (energy leaking out)
    // ═══════════════════════════════════════════════════════════════════════
    final energyPulse = 0.5 + math.sin(time * 8) * 0.5;
    for (final impact in _fractureImpactPoints) {
      final impactPos = center + impact.offset;

      // Energy leak glow at impact point
      final leakRadius = size.x * 0.06 * (1 + energyPulse * 0.3) * damageIntensity;
      _fractureEnergyLeakPaint.color = damageColorEnergy.withOpacity(
          0.5 * energyPulse * damageIntensity * impact.intensity);
      canvas.drawCircle(impactPos, leakRadius, _fractureEnergyLeakPaint);

      // Energy core at center
      _fractureEnergyCorePaint.color = damageColorEnergy.withOpacity(
          0.8 * damageIntensity * impact.intensity);
      canvas.drawCircle(impactPos, leakRadius * 0.4, _fractureEnergyCorePaint);

      // Energy wisps along cracks
      for (int i = 0; i < 3; i++) {
        final wispAngle = impact.angle + i * 0.8 - 0.8;
        final wispDist = size.x * (0.08 + math.sin(time * 6 + i * 2) * 0.04);
        final wispPos = Offset(
          impactPos.dx + math.cos(wispAngle) * wispDist,
          impactPos.dy + math.sin(wispAngle) * wispDist,
        );

        _fractureEnergyLeakPaint.color = damageColorEnergy.withOpacity(
            0.4 * energyPulse * damageIntensity);
        canvas.drawCircle(wispPos, size.x * 0.02, _fractureEnergyLeakPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: Hexagonal stress patterns
    // ═══════════════════════════════════════════════════════════════════════
    if (damageIntensity > 0.3) {
      final hexCount = (damageIntensity * 6).toInt().clamp(2, 6);
      final hexBaseRadius = size.x * 0.08;

      for (int h = 0; h < hexCount; h++) {
        // Position hex patterns around damage areas
        final hexAngle = (h / hexCount) * math.pi * 2 + time * 0.2;
        final hexDist = size.x * (0.25 + math.sin(time + h) * 0.05);
        final hexCenter = Offset(
          center.dx + math.cos(hexAngle) * hexDist,
          center.dy + math.sin(hexAngle) * hexDist,
        );

        // Determine if this hex is "stressed" (near damage)
        final stressLevel = damageIntensity * (0.5 + math.sin(time * 3 + h * 1.5) * 0.5);

        // Draw hexagon outline
        _fracturePath.reset();
        for (int v = 0; v < 6; v++) {
          final vertexAngle = v * math.pi / 3 - math.pi / 6;
          final vx = hexCenter.dx + math.cos(vertexAngle) * hexBaseRadius;
          final vy = hexCenter.dy + math.sin(vertexAngle) * hexBaseRadius;
          if (v == 0) {
            _fracturePath.moveTo(vx, vy);
          } else {
            _fracturePath.lineTo(vx, vy);
          }
        }
        _fracturePath.close();

        // Stressed fill
        if (stressLevel > 0.4) {
          _fractureHexFillPaint.color = damageColorGlow.withOpacity(
              0.15 * stressLevel);
          canvas.drawPath(_fracturePath, _fractureHexFillPaint);
        }

        // Outline
        _fractureHexStressPaint.color = damageColorCore.withOpacity(
            0.3 + stressLevel * 0.4);
        canvas.drawPath(_fracturePath, _fractureHexStressPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: Flickering damaged sections
    // ═══════════════════════════════════════════════════════════════════════
    if (damageIntensity > 0.2) {
      final flickerValue = math.sin(_fractureFlickerTimer) *
          math.sin(_fractureFlickerTimer * 1.7) *
          math.sin(_fractureFlickerTimer * 2.3);
      final flicker = (flickerValue + 1) / 2; // Normalize to 0-1

      // Create flickering damaged zone
      if (flicker > 0.6) {
        for (final impact in _fractureImpactPoints) {
          final flickerRadius = size.x * 0.1 * damageIntensity * flicker;
          final flickerPos = center + impact.offset * 0.7;

          _fractureFlickerPaint.color = damageColorGlow.withOpacity(
              0.3 * (flicker - 0.6) * damageIntensity);
          canvas.drawCircle(flickerPos, flickerRadius, _fractureFlickerPaint);
        }
      }

      // Random glitch rectangles (digital damage aesthetic)
      if (damageIntensity > 0.5 && flicker > 0.7) {
        final glitchCount = (damageIntensity * 3).toInt();
        for (int g = 0; g < glitchCount; g++) {
          final gx = center.dx + (_fractureRandom.nextDouble() - 0.5) * size.x * 0.6;
          final gy = center.dy + (_fractureRandom.nextDouble() - 0.5) * size.y * 0.6;
          final gw = size.x * 0.05 + _fractureRandom.nextDouble() * size.x * 0.1;
          final gh = size.y * 0.02 + _fractureRandom.nextDouble() * size.y * 0.04;

          _fractureFlickerPaint.color = damageColorEnergy.withOpacity(
              0.4 * flicker * damageIntensity);
          canvas.drawRect(
            Rect.fromCenter(center: Offset(gx, gy), width: gw, height: gh),
            _fractureFlickerPaint,
          );
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: Sparking at crack intersections
    // ═══════════════════════════════════════════════════════════════════════
    if (damageIntensity > 0.15) {
      // Spawn sparks periodically
      final shouldSpark = _fractureSparkTimer >= _fractureSparkInterval;

      for (final impact in _fractureImpactPoints) {
        final sparkPos = center + impact.offset;

        // Continuous spark glow
        final sparkPulse = 0.3 + math.sin(time * 12 + impact.angle * 3) * 0.7;
        if (sparkPulse > 0.5) {
          // Spark glow
          _fractureSparkPaint.color = damageColorEnergy.withOpacity(
              0.6 * sparkPulse * damageIntensity * impact.intensity);
          canvas.drawCircle(sparkPos, size.x * 0.03 * sparkPulse,
              _fractureSparkPaint);

          // Spark core
          _fractureSparkCorePaint.color = const Color(0xFFFFFFFF).withOpacity(
              0.8 * sparkPulse * damageIntensity);
          canvas.drawCircle(sparkPos, size.x * 0.01 * sparkPulse,
              _fractureSparkCorePaint);
        }

        // Occasional spark arcs
        if (shouldSpark && _fractureRandom.nextDouble() < 0.4 * damageIntensity) {
          final arcLength = size.x * (0.04 + _fractureRandom.nextDouble() * 0.06);
          final arcAngle = _fractureRandom.nextDouble() * math.pi * 2;

          // Draw jagged spark arc
          _fracturePath.reset();
          _fracturePath.moveTo(sparkPos.dx, sparkPos.dy);

          var currentX = sparkPos.dx;
          var currentY = sparkPos.dy;
          final segments = 3 + _fractureRandom.nextInt(3);
          final segmentLength = arcLength / segments;

          for (int s = 0; s < segments; s++) {
            final segAngle = arcAngle + (_fractureRandom.nextDouble() - 0.5) * 1.2;
            currentX += math.cos(segAngle) * segmentLength;
            currentY += math.sin(segAngle) * segmentLength;
            _fracturePath.lineTo(currentX, currentY);
          }

          _fractureSparkArcPaint.color = damageColorEnergy.withOpacity(
              0.7 * damageIntensity);
          canvas.drawPath(_fracturePath, _fractureSparkArcPaint);
        }
      }

      // Reset spark timer
      if (shouldSpark) {
        _fractureSparkTimer = 0;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HOLOGRAPHIC CONSTRUCTION EFFECT
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderConstructionEffect(Canvas canvas, Offset center) {
    final progress = _constructionProgress;
    final time = _animationPhase;

    // Get color variations using HSL for rich effects
    final hslColor = HSLColor.fromColor(color);
    final secondaryColor = hslColor.withHue((hslColor.hue + 60) % 360).toColor();
    final tertiaryColor = hslColor.withHue((hslColor.hue + 180) % 360).toColor();
    final holoColor = Color.lerp(color, const Color(0xFF00FFFF), 0.3)!;

    // Hologram base opacity (starts transparent, becomes solid)
    final holoOpacity = 0.3 + progress * 0.7;
    final flickerAmount = math.sin(time * 20) * 0.1 * (1 - progress);
    final effectiveOpacity = (holoOpacity + flickerAmount).clamp(0.0, 1.0);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: Holographic wireframe outline of the tower
    // ═══════════════════════════════════════════════════════════════════════
    final wireframeRadius = size.x * 0.45;
    final wireframeGlowAlpha = 0.6 * (1 - progress * 0.5);

    // Outer glow wireframe
    _constructWireframeGlowPaint.color = holoColor.withOpacity(wireframeGlowAlpha * effectiveOpacity);
    _constructPath.reset();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final x = center.dx + math.cos(angle) * wireframeRadius;
      final y = center.dy + math.sin(angle) * wireframeRadius;
      if (i == 0) {
        _constructPath.moveTo(x, y);
      } else {
        _constructPath.lineTo(x, y);
      }
    }
    _constructPath.close();
    canvas.drawPath(_constructPath, _constructWireframeGlowPaint);

    // Core wireframe with scanline distortion
    _constructWireframePaint.color = holoColor.withOpacity(0.8 * effectiveOpacity);
    canvas.drawPath(_constructPath, _constructWireframePaint);

    // Vertical wireframe lines (hexagon to center)
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final outerX = center.dx + math.cos(angle) * wireframeRadius;
      final outerY = center.dy + math.sin(angle) * wireframeRadius;
      final innerRadius = wireframeRadius * 0.3;
      final innerX = center.dx + math.cos(angle) * innerRadius;
      final innerY = center.dy + math.sin(angle) * innerRadius;

      final lineAlpha = 0.4 + math.sin(time * 3 + i) * 0.2;
      _constructWireframePaint.color = holoColor.withOpacity(lineAlpha * effectiveOpacity);
      canvas.drawLine(Offset(outerX, outerY), Offset(innerX, innerY), _constructWireframePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: Blueprint grid pattern overlay
    // ═══════════════════════════════════════════════════════════════════════
    final gridSize = size.x * 0.1;
    final gridExtent = wireframeRadius * 0.8;
    final gridAlpha = 0.15 * (1 - progress * 0.8);

    _constructGridPaint.color = holoColor.withOpacity(gridAlpha * effectiveOpacity);

    // Horizontal and vertical grid lines
    for (double offset = -gridExtent; offset <= gridExtent; offset += gridSize) {
      // Horizontal lines with wave distortion
      final waveOffset = math.sin(time * 4 + offset * 0.1) * 2 * (1 - progress);
      canvas.drawLine(
        Offset(center.dx - gridExtent + waveOffset, center.dy + offset),
        Offset(center.dx + gridExtent + waveOffset, center.dy + offset),
        _constructGridPaint,
      );
      // Vertical lines
      canvas.drawLine(
        Offset(center.dx + offset, center.dy - gridExtent),
        Offset(center.dx + offset, center.dy + gridExtent),
        _constructGridPaint,
      );
    }

    // Grid intersection nodes (pulsing)
    final nodeAlpha = 0.3 + math.sin(time * 6) * 0.2;
    _constructGridNodePaint.color = secondaryColor.withOpacity(nodeAlpha * effectiveOpacity * (1 - progress));
    for (double x = -gridExtent; x <= gridExtent; x += gridSize) {
      for (double y = -gridExtent; y <= gridExtent; y += gridSize) {
        final dist = math.sqrt(x * x + y * y);
        if (dist < wireframeRadius) {
          canvas.drawCircle(Offset(center.dx + x, center.dy + y), 1.5, _constructGridNodePaint);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: Scanning line moving through the hologram
    // ═══════════════════════════════════════════════════════════════════════
    final scanLineY = center.dy - wireframeRadius + ((time * 0.5) % 1.0) * wireframeRadius * 2;
    final scanLineWidth = wireframeRadius * 2;

    // Wide glow under scan line
    _constructScanGlowPaint.color = holoColor.withOpacity(0.3 * effectiveOpacity);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx, scanLineY), width: scanLineWidth, height: 20),
      _constructScanGlowPaint,
    );

    // Core scan line
    _constructScanLinePaint.color = Color.lerp(holoColor, Colors.white, 0.5)!.withOpacity(0.8 * effectiveOpacity);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx, scanLineY), width: scanLineWidth, height: 3),
      _constructScanLinePaint,
    );

    // Scan line edge particles
    for (int i = 0; i < 6; i++) {
      final particleX = center.dx - wireframeRadius + i * (wireframeRadius * 2 / 5);
      final particleOffset = math.sin(time * 10 + i * 2) * 3;
      _constructParticlePaint.color = Colors.white.withOpacity(0.6 * effectiveOpacity);
      canvas.drawCircle(Offset(particleX, scanLineY + particleOffset), 2, _constructParticlePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: Materializing particles coalescing into form
    // ═══════════════════════════════════════════════════════════════════════
    for (final particle in _constructionParticles) {
      final particleProgress = (progress * 1.5 - particle.phase * 0.3).clamp(0.0, 1.0);

      // Particles spiral inward as construction progresses
      final currentRadius = particle.radius * (1 - particleProgress) + particle.targetRadius * particleProgress;
      final spiralAngle = particle.angle + time * particle.spiralRate + particleProgress * math.pi * 4;

      final px = center.dx + math.cos(spiralAngle) * currentRadius;
      final py = center.dy + math.sin(spiralAngle) * currentRadius;

      // Particle visibility (fade in early, fade out when merged)
      final particleAlpha = particleProgress < 0.1
          ? particleProgress * 10
          : particleProgress > 0.9
              ? (1 - particleProgress) * 10
              : 1.0;

      // Particle glow
      _constructParticlePaint.color = holoColor.withOpacity(0.6 * particleAlpha * effectiveOpacity);
      canvas.drawCircle(Offset(px, py), particle.size * 1.5, _constructParticlePaint);

      // Particle core
      _constructParticlePaint.color = Colors.white.withOpacity(0.9 * particleAlpha * effectiveOpacity);
      canvas.drawCircle(Offset(px, py), particle.size * 0.5, _constructParticlePaint);

      // Particle trail
      if (particleProgress > 0.1 && particleProgress < 0.9) {
        final trailAngle = spiralAngle - 0.3;
        final trailRadius = currentRadius + 5;
        final trailX = center.dx + math.cos(trailAngle) * trailRadius;
        final trailY = center.dy + math.sin(trailAngle) * trailRadius;

        _constructParticleTrailPaint.color = holoColor.withOpacity(0.3 * particleAlpha * effectiveOpacity);
        canvas.drawLine(Offset(px, py), Offset(trailX, trailY), _constructParticleTrailPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: Data stream effects showing "CONSTRUCTING..."
    // ═══════════════════════════════════════════════════════════════════════
    final dataStreamY = center.dy - wireframeRadius - 15;
    final dataStreamWidth = wireframeRadius * 1.2;

    // Data bar background
    _constructDataPaint.color = tertiaryColor.withOpacity(0.2 * effectiveOpacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, dataStreamY), width: dataStreamWidth, height: 8),
        const Radius.circular(2),
      ),
      _constructDataPaint,
    );

    // Data bar fill (progress)
    _constructDataGlowPaint.color = holoColor.withOpacity(0.8 * effectiveOpacity);
    final fillWidth = dataStreamWidth * progress;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          center.dx - dataStreamWidth / 2,
          dataStreamY - 4,
          fillWidth,
          8,
        ),
        const Radius.circular(2),
      ),
      _constructDataGlowPaint,
    );

    // Scrolling data bits along the bar
    final bitCount = 8;
    for (int i = 0; i < bitCount; i++) {
      final bitX = center.dx - dataStreamWidth / 2 + ((time * 50 + i * 15) % dataStreamWidth);
      if (bitX < center.dx - dataStreamWidth / 2 + fillWidth) {
        final bitAlpha = 0.5 + _constructRandom.nextDouble() * 0.5;
        _constructDataPaint.color = Colors.white.withOpacity(bitAlpha * effectiveOpacity);
        canvas.drawRect(
          Rect.fromLTWH(bitX, dataStreamY - 2, 3, 4),
          _constructDataPaint,
        );
      }
    }

    // Small data blocks indicating status (visual progress indicator)
    for (int i = 0; i < 3; i++) {
      final blockX = center.dx + wireframeRadius * 0.6 + i * 6;
      final blockY = center.dy + wireframeRadius + 8;
      final blockAlpha = i < (progress * 3).floor() ? 0.8 : 0.2;
      _constructDataPaint.color = holoColor.withOpacity(blockAlpha * effectiveOpacity);
      canvas.drawRect(
        Rect.fromLTWH(blockX, blockY, 4, 4),
        _constructDataPaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: Progress ring around the base
    // ═══════════════════════════════════════════════════════════════════════
    final ringRadius = wireframeRadius + 8;

    // Background ring
    _constructProgressBgPaint.color = tertiaryColor.withOpacity(0.15 * effectiveOpacity);
    canvas.drawCircle(center, ringRadius, _constructProgressBgPaint);

    // Progress arc glow
    final sweepAngle = progress * math.pi * 2;
    _constructProgressGlowPaint.color = holoColor.withOpacity(0.5 * effectiveOpacity);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringRadius),
      -math.pi / 2,
      sweepAngle,
      false,
      _constructProgressGlowPaint,
    );

    // Progress arc core
    _constructProgressPaint.color = Color.lerp(holoColor, Colors.white, 0.3)!.withOpacity(0.9 * effectiveOpacity);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringRadius),
      -math.pi / 2,
      sweepAngle,
      false,
      _constructProgressPaint,
    );

    // Progress end marker
    if (progress > 0.05) {
      final endAngle = -math.pi / 2 + sweepAngle;
      final endX = center.dx + math.cos(endAngle) * ringRadius;
      final endY = center.dy + math.sin(endAngle) * ringRadius;

      _constructParticlePaint.color = Colors.white.withOpacity(0.9 * effectiveOpacity);
      canvas.drawCircle(Offset(endX, endY), 4, _constructParticlePaint);

      // Pulsing glow at progress head
      final pulseSize = 6 + math.sin(time * 10) * 2;
      _constructProgressGlowPaint.color = holoColor.withOpacity(0.4 * effectiveOpacity);
      canvas.drawCircle(Offset(endX, endY), pulseSize, _constructProgressGlowPaint);
    }

    // Tick marks around the ring
    for (int i = 0; i < 12; i++) {
      final tickAngle = i * math.pi / 6 - math.pi / 2;
      final tickInner = ringRadius - 3;
      final tickOuter = ringRadius + 3;
      final tickX1 = center.dx + math.cos(tickAngle) * tickInner;
      final tickY1 = center.dy + math.sin(tickAngle) * tickInner;
      final tickX2 = center.dx + math.cos(tickAngle) * tickOuter;
      final tickY2 = center.dy + math.sin(tickAngle) * tickOuter;

      final tickProgress = i / 12.0;
      final tickAlpha = tickProgress <= progress ? 0.8 : 0.2;
      _constructWireframePaint.color = holoColor.withOpacity(tickAlpha * effectiveOpacity);
      canvas.drawLine(Offset(tickX1, tickY1), Offset(tickX2, tickY2), _constructWireframePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: Final materialization flash when complete (or near complete)
    // ═══════════════════════════════════════════════════════════════════════
    if (progress > 0.95) {
      final flashProgress = (progress - 0.95) / 0.05; // 0 to 1 in final 5%
      final flashAlpha = math.sin(flashProgress * math.pi); // Peaks at middle

      // Central flash
      _constructFlashPaint.color = Colors.white.withOpacity(flashAlpha * 0.8);
      canvas.drawCircle(center, wireframeRadius * flashProgress * 2, _constructFlashPaint);

      // Expanding ring
      _constructFlashRingPaint.color = holoColor.withOpacity(flashAlpha * 0.6);
      canvas.drawCircle(center, wireframeRadius * (1 + flashProgress), _constructFlashRingPaint);

      // Secondary color ring
      _constructFlashRingPaint.color = secondaryColor.withOpacity(flashAlpha * 0.4);
      canvas.drawCircle(center, wireframeRadius * (1.2 + flashProgress * 0.5), _constructFlashRingPaint);
    }
  }

  /// Renders the completion flash effect after construction finishes
  void _renderConstructionCompleteFlash(Canvas canvas, Offset center) {
    if (_constructionFlashTimer <= 0) return;

    final flashProgress = 1 - (_constructionFlashTimer / 0.5); // 0 to 1 as flash fades
    final flashAlpha = (1 - flashProgress) * (1 - flashProgress); // Quadratic fade

    final hslColor = HSLColor.fromColor(color);
    final holoColor = Color.lerp(color, const Color(0xFF00FFFF), 0.3)!;
    final secondaryColor = hslColor.withHue((hslColor.hue + 60) % 360).toColor();

    // Expanding flash rings
    for (int i = 0; i < 3; i++) {
      final ringRadius = size.x * (0.5 + flashProgress * (0.8 + i * 0.3));
      final ringAlpha = flashAlpha * (1 - i * 0.3);

      _constructFlashRingPaint.color = (i == 0 ? Colors.white : i == 1 ? holoColor : secondaryColor)
          .withOpacity(ringAlpha * 0.6);
      canvas.drawCircle(center, ringRadius, _constructFlashRingPaint);
    }

    // Central bright flash
    _constructFlashPaint.color = Colors.white.withOpacity(flashAlpha * 0.5);
    canvas.drawCircle(center, size.x * 0.3 * (1 - flashProgress * 0.5), _constructFlashPaint);

    // Spark particles radiating outward
    for (int i = 0; i < 8; i++) {
      final sparkAngle = i * math.pi / 4 + flashProgress * math.pi * 0.5;
      final sparkRadius = size.x * (0.3 + flashProgress * 0.8);
      final sparkX = center.dx + math.cos(sparkAngle) * sparkRadius;
      final sparkY = center.dy + math.sin(sparkAngle) * sparkRadius;

      _constructParticlePaint.color = holoColor.withOpacity(flashAlpha * 0.8);
      canvas.drawCircle(Offset(sparkX, sparkY), 3 * (1 - flashProgress), _constructParticlePaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DYNAMIC SHADOW CASTING
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderDynamicShadow(Canvas canvas, Offset center) {
    // Shadow offset direction (bottom-right, simulating top-left light source)
    const double shadowOffsetX = 8.0;
    const double shadowOffsetY = 10.0;

    // Calculate shadow intensity based on tower activity
    final hasTarget = _currentTarget != null;
    final isCharging = _chargeLevel > 0;
    final isFiringNow = _isFiring && _fireFlashTimer > 0;

    // Base intensity increases with activity
    final activityIntensity = 0.6 +
        (hasTarget ? 0.15 : 0.0) +
        (isCharging ? _chargeLevel * 0.1 : 0.0) +
        (_isBoosted ? 0.1 : 0.0);

    // Fire pulse effect - shadow pulses when tower fires
    final firePulse = isFiringNow ? (1.0 - _fireFlashTimer / 0.15) * 0.2 : 0.0;
    final shadowScale = 1.0 + firePulse;

    // Subtle animation based on tower activity and time
    final shadowWobble = math.sin(_animationPhase * 2) * 0.5;
    final animatedOffsetX = shadowOffsetX + shadowWobble;
    final animatedOffsetY = shadowOffsetY + shadowWobble * 0.5;

    // Tower base radius for shadow calculations
    final baseRadius = size.x * 0.4;

    // ─────────────────────────────────────────────────────────────────────────
    // LAYER 3: Secondary ambient shadow (lighter, wider) - rendered first
    // ─────────────────────────────────────────────────────────────────────────
    final ambientOpacity = 0.08 * activityIntensity;
    _shadowAmbientPaint.color = const Color(0xFF000000).withOpacity(ambientOpacity);

    _shadowPath.reset();
    _shadowPath.addOval(Rect.fromCenter(
      center: Offset(
        center.dx + animatedOffsetX * 1.8,
        center.dy + animatedOffsetY * 1.8 + baseRadius * 0.3,
      ),
      width: baseRadius * 2.8 * shadowScale,
      height: baseRadius * 1.4 * shadowScale,
    ));
    canvas.drawPath(_shadowPath, _shadowAmbientPaint);

    // ─────────────────────────────────────────────────────────────────────────
    // LAYER 2: Soft shadow edge with blur
    // ─────────────────────────────────────────────────────────────────────────
    final softEdgeOpacity = 0.15 * activityIntensity;
    _shadowSoftEdgePaint.color = const Color(0xFF000000).withOpacity(softEdgeOpacity);

    _shadowPath.reset();
    _shadowPath.addOval(Rect.fromCenter(
      center: Offset(
        center.dx + animatedOffsetX * 1.3,
        center.dy + animatedOffsetY * 1.3 + baseRadius * 0.2,
      ),
      width: baseRadius * 2.2 * shadowScale,
      height: baseRadius * 1.1 * shadowScale,
    ));
    canvas.drawPath(_shadowPath, _shadowSoftEdgePaint);

    // ─────────────────────────────────────────────────────────────────────────
    // LAYER 1: Main shadow silhouette (offset and stretched)
    // ─────────────────────────────────────────────────────────────────────────
    final mainOpacity = 0.25 * activityIntensity;
    _shadowMainPaint.color = const Color(0xFF000000).withOpacity(mainOpacity);

    _shadowPath.reset();
    _shadowPath.addOval(Rect.fromCenter(
      center: Offset(
        center.dx + animatedOffsetX,
        center.dy + animatedOffsetY + baseRadius * 0.15,
      ),
      width: baseRadius * 1.8 * shadowScale,
      height: baseRadius * 0.9 * shadowScale,
    ));
    canvas.drawPath(_shadowPath, _shadowMainPaint);

    // ─────────────────────────────────────────────────────────────────────────
    // LAYER 4: Ground contact shadow (darker at base)
    // ─────────────────────────────────────────────────────────────────────────
    final groundContactOpacity = 0.35 * activityIntensity;
    _shadowGroundContactPaint.color = const Color(0xFF000000).withOpacity(groundContactOpacity);

    _shadowPath.reset();
    _shadowPath.addOval(Rect.fromCenter(
      center: Offset(
        center.dx + animatedOffsetX * 0.3,
        center.dy + animatedOffsetY * 0.4,
      ),
      width: baseRadius * 1.2,
      height: baseRadius * 0.6,
    ));
    canvas.drawPath(_shadowPath, _shadowGroundContactPaint);

    // ─────────────────────────────────────────────────────────────────────────
    // LAYER 5: Subtle shadow animation based on tower activity
    // ─────────────────────────────────────────────────────────────────────────
    if (hasTarget || isCharging || _isBoosted) {
      // Activity-based shadow pulse
      final pulsePhase = math.sin(_animationPhase * 4) * 0.5 + 0.5;
      final pulseOpacity = 0.1 * pulsePhase * activityIntensity;
      _shadowPulsePaint.color = const Color(0xFF000000).withOpacity(pulseOpacity);

      // Pulsing shadow ring around the main shadow
      final pulseRadius = baseRadius * (1.5 + pulsePhase * 0.3) * shadowScale;
      _shadowPath.reset();
      _shadowPath.addOval(Rect.fromCenter(
        center: Offset(
          center.dx + animatedOffsetX * 1.1,
          center.dy + animatedOffsetY * 1.1,
        ),
        width: pulseRadius * 1.6,
        height: pulseRadius * 0.8,
      ));
      canvas.drawPath(_shadowPath, _shadowPulsePaint);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // LAYER 6: Neon light bounce (colored shadow edges from tower glow)
    // ─────────────────────────────────────────────────────────────────────────
    // Create a subtle colored edge on the shadow from the tower's neon glow
    final glowBounceIntensity = 0.12 * activityIntensity;

    // Get the tower's color for neon bounce
    final towerColor = color;
    final hsl = HSLColor.fromColor(towerColor);

    // Shift the hue slightly for the bounce light effect
    final bounceColor = hsl.withLightness(0.3).withSaturation(0.8).toColor();
    _shadowNeonBouncePaint.color = bounceColor.withOpacity(glowBounceIntensity);

    // Render neon bounce on the opposite edge of the shadow (where light would bounce)
    _shadowPath.reset();
    _shadowPath.addOval(Rect.fromCenter(
      center: Offset(
        center.dx + animatedOffsetX * 0.6,
        center.dy + animatedOffsetY * 0.7,
      ),
      width: baseRadius * 1.4 * shadowScale,
      height: baseRadius * 0.7 * shadowScale,
    ));
    canvas.drawPath(_shadowPath, _shadowNeonBouncePaint);

    // Additional neon glow on the inner shadow edge (rim lighting effect)
    if (isFiringNow) {
      // Brighter neon bounce during firing
      final fireGlowIntensity = 0.25 * (1.0 - _fireFlashTimer / 0.15);
      _shadowNeonBouncePaint.color = towerColor.withOpacity(fireGlowIntensity);

      _shadowPath.reset();
      _shadowPath.addOval(Rect.fromCenter(
        center: Offset(
          center.dx + animatedOffsetX * 0.4,
          center.dy + animatedOffsetY * 0.5,
        ),
        width: baseRadius * 1.0,
        height: baseRadius * 0.5,
      ));
      canvas.drawPath(_shadowPath, _shadowNeonBouncePaint);
    }

    // Charging glow bounce effect
    if (isCharging && _chargeLevel > 0.3) {
      final chargeGlowIntensity = 0.08 * _chargeLevel;
      final chargeColor = hsl.withHue((hsl.hue + 30) % 360).toColor();
      _shadowNeonBouncePaint.color = chargeColor.withOpacity(chargeGlowIntensity);

      final chargeWobble = math.sin(_animationPhase * 6) * 2;
      _shadowPath.reset();
      _shadowPath.addOval(Rect.fromCenter(
        center: Offset(
          center.dx + animatedOffsetX * 0.5 + chargeWobble,
          center.dy + animatedOffsetY * 0.6,
        ),
        width: baseRadius * 1.2 * (1.0 + _chargeLevel * 0.2),
        height: baseRadius * 0.6 * (1.0 + _chargeLevel * 0.2),
      ));
      canvas.drawPath(_shadowPath, _shadowNeonBouncePaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ELECTRIC ARC CONNECTIONS BETWEEN NEARBY TOWERS
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderElectricArcConnections(Canvas canvas, Offset center) {
    // Safely check if game reference is available
    if (!isMounted) return;

    List<Tower> towers;
    try {
      towers = gameRef.towerManager.towers;
    } catch (_) {
      return; // Game not fully mounted yet
    }

    // Get this tower's index to only draw arcs to towers with higher index
    // This prevents drawing the same arc twice
    final myIndex = towers.indexOf(this);
    if (myIndex < 0) return;

    final myCenter = centerPosition;
    final animPhase = _animationPhase;

    // Calculate activity level for arc intensity
    final hasTarget = _currentTarget != null;
    final isCharging = _chargeLevel > 0;
    final activityLevel = (hasTarget ? 0.4 : 0.2) + (isCharging ? _chargeLevel * 0.3 : 0.0) + (_isFiring ? 0.4 : 0.0);

    // Get color info for arcs
    final hslColor = HSLColor.fromColor(color);
    final secondaryColor = hslColor.withHue((hslColor.hue + 180) % 360).toColor();

    for (int i = myIndex + 1; i < towers.length; i++) {
      final otherTower = towers[i];
      final otherCenter = otherTower.centerPosition;
      final distance = myCenter.distanceTo(otherCenter);

      // Check if within arc range
      if (distance < _electricArcMinDistance || distance > _electricArcMaxDistance) continue;

      // Calculate combined activity
      final otherHasTarget = otherTower._currentTarget != null;
      final otherIsCharging = otherTower._chargeLevel > 0;
      final otherActivity = (otherHasTarget ? 0.4 : 0.2) +
          (otherIsCharging ? otherTower._chargeLevel * 0.3 : 0.0) +
          (otherTower._isFiring ? 0.4 : 0.0);
      final combinedActivity = ((activityLevel + otherActivity) / 2).clamp(0.2, 1.0);

      // Distance falloff
      final distanceFactor = 1.0 - ((distance - _electricArcMinDistance) / (_electricArcMaxDistance - _electricArcMinDistance));
      final arcOpacity = combinedActivity * distanceFactor * 0.8;

      if (arcOpacity < 0.1) continue;

      // Calculate direction and offset for this tower's position
      final direction = Vector2(otherCenter.x - myCenter.x, otherCenter.y - myCenter.y);
      final startOffset = Offset(
        center.dx + direction.x,
        center.dy + direction.y,
      );
      final endOffset = Offset(
        center.dx,
        center.dy,
      );

      // For this tower, we draw arcs going toward us (from other tower's perspective)
      // Transform to local coordinates
      final localStartX = startOffset.dx;
      final localStartY = startOffset.dy;
      final localEndX = endOffset.dx;
      final localEndY = endOffset.dy;

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 1: Outer glow arc
      // ═══════════════════════════════════════════════════════════════════════
      _electricArcPath.reset();
      _generateLightningPath(
        _electricArcPath,
        localStartX, localStartY,
        localEndX, localEndY,
        6, // segments
        distance * 0.08, // displacement
        animPhase * 8,
      );

      final primaryColor = Color.lerp(color, otherTower.color, 0.5)!;
      _electricArcGlowPaint.color = primaryColor.withOpacity(arcOpacity * 0.3);
      canvas.drawPath(_electricArcPath, _electricArcGlowPaint);

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 2: Core arc line
      // ═══════════════════════════════════════════════════════════════════════
      _electricArcCorePaint.color = primaryColor.withOpacity(arcOpacity * 0.8);
      canvas.drawPath(_electricArcPath, _electricArcCorePaint);

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 3: Inner white highlight
      // ═══════════════════════════════════════════════════════════════════════
      _electricArcInnerPaint.color = Colors.white.withOpacity(arcOpacity * 0.5);
      canvas.drawPath(_electricArcPath, _electricArcInnerPaint);

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 4: Branch arcs (smaller lightning bolts branching off)
      // ═══════════════════════════════════════════════════════════════════════
      if (!Tower.lowFx && arcOpacity > 0.3) {
        final branchCount = 2 + (_electricArcRandom.nextInt(2));
        for (int b = 0; b < branchCount; b++) {
          final t = 0.3 + _electricArcRandom.nextDouble() * 0.4;
          final branchX = localStartX + (localEndX - localStartX) * t;
          final branchY = localStartY + (localEndY - localStartY) * t;

          final branchAngle = animPhase * 2 + b * math.pi * 0.7;
          final branchLen = distance * 0.15 * (_electricArcRandom.nextDouble() * 0.5 + 0.5);
          final branchEndX = branchX + math.cos(branchAngle) * branchLen;
          final branchEndY = branchY + math.sin(branchAngle) * branchLen;

          _electricArcPath.reset();
          _generateLightningPath(
            _electricArcPath,
            branchX, branchY,
            branchEndX, branchEndY,
            3,
            branchLen * 0.2,
            animPhase * 12 + b,
          );

          _electricArcBranchPaint.color = secondaryColor.withOpacity(arcOpacity * 0.4);
          canvas.drawPath(_electricArcPath, _electricArcBranchPaint);
        }
      }

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 5: Connection node glows at endpoints
      // ═══════════════════════════════════════════════════════════════════════
      final nodePulse = 0.6 + math.sin(animPhase * 5) * 0.4;
      final nodeSize = 4.0 * nodePulse * combinedActivity;

      _electricArcNodePaint.color = primaryColor.withOpacity(arcOpacity * 0.5);
      canvas.drawCircle(Offset(localStartX, localStartY), nodeSize, _electricArcNodePaint);
      canvas.drawCircle(Offset(localEndX, localEndY), nodeSize, _electricArcNodePaint);

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 6: Traveling sparks along the arc
      // ═══════════════════════════════════════════════════════════════════════
      if (!Tower.lowFx) {
        final sparkCount = 3;
        for (int s = 0; s < sparkCount; s++) {
          final sparkT = ((animPhase * 2 + s * 0.33) % 1.0);
          final sparkX = localStartX + (localEndX - localStartX) * sparkT;
          final sparkY = localStartY + (localEndY - localStartY) * sparkT;

          // Add some jitter
          final jitterX = math.sin(animPhase * 10 + s) * 3;
          final jitterY = math.cos(animPhase * 10 + s) * 3;

          _electricArcSparkPaint.color = Colors.white.withOpacity(arcOpacity * 0.7);
          canvas.drawCircle(
            Offset(sparkX + jitterX, sparkY + jitterY),
            2.0 + math.sin(animPhase * 8 + s) * 1.0,
            _electricArcSparkPaint,
          );
        }
      }

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 7: Occasional bright flash
      // ═══════════════════════════════════════════════════════════════════════
      if (!Tower.lowFx) {
        final flashChance = math.sin(animPhase * 3 + myIndex * 0.5 + i * 0.7);
        if (flashChance > 0.95) {
          final midX = (localStartX + localEndX) / 2;
          final midY = (localStartY + localEndY) / 2;

          _electricArcFlashPaint.color = Colors.white.withOpacity(arcOpacity * 0.4);
          canvas.drawCircle(Offset(midX, midY), 8.0, _electricArcFlashPaint);
        }
      }
    }
  }

  /// Generates a lightning bolt path between two points
  void _generateLightningPath(
    Path path,
    double x1, double y1,
    double x2, double y2,
    int segments,
    double displacement,
    double seed,
  ) {
    path.moveTo(x1, y1);

    final dx = x2 - x1;
    final dy = y2 - y1;
    final perpX = -dy;
    final perpY = dx;
    final perpLen = math.sqrt(perpX * perpX + perpY * perpY);
    final normPerpX = perpLen > 0 ? perpX / perpLen : 0;
    final normPerpY = perpLen > 0 ? perpY / perpLen : 0;

    double prevX = x1;
    double prevY = y1;

    for (int i = 1; i < segments; i++) {
      final t = i / segments;
      final baseX = x1 + dx * t;
      final baseY = y1 + dy * t;

      // Randomized offset perpendicular to the line
      final randomOffset = math.sin(seed * (i + 1) * 3.7) * displacement * (1 - math.pow(2 * t - 1, 2));
      final finalX = baseX + normPerpX * randomOffset;
      final finalY = baseY + normPerpY * randomOffset;

      path.lineTo(finalX, finalY);
      prevX = finalX;
      prevY = finalY;
    }

    path.lineTo(x2, y2);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DYNAMIC LIGHTING/GLOW BASED ON TOWER ACTIVITY
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderDynamicLighting(Canvas canvas, Offset center) {
    // Calculate activity intensity based on tower state
    final hasTarget = _currentTarget != null;
    final isCharging = _chargeLevel > 0;
    final baseActivity = hasTarget ? 0.3 : 0.1; // Higher when targeting
    final chargeActivity = _chargeLevel * 0.5; // Increases with charge
    final firingActivity = _isFiring ? 0.8 : 0.0; // Bright flash when firing
    final boostActivity = _isBoosted ? 0.3 : 0.0; // Extra glow when boosted

    final totalActivity = (baseActivity + chargeActivity + firingActivity + boostActivity).clamp(0.0, 1.0);

    // Get secondary and tertiary colors
    final hslColor = HSLColor.fromColor(color);
    final secondaryColor = hslColor.withHue((hslColor.hue + 60) % 360).toColor();
    final tertiaryColor = hslColor.withHue((hslColor.hue + 180) % 360).toColor();
    final boostColor = const Color(0xFFFFD700); // Golden for boost

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: DEEP AMBIENT GROUND GLOW
    // ═══════════════════════════════════════════════════════════════════════
    final groundGlowRadius = size.x * (0.9 + totalActivity * 0.3);
    final groundGlowAlpha = 0.05 + totalActivity * 0.12;

    _dynamicGroundGlowPaint.color = color.withOpacity(groundGlowAlpha);
    canvas.drawCircle(center, groundGlowRadius, _dynamicGroundGlowPaint);

    // Secondary color ambient glow
    if (!Tower.lowFx) {
      final secondaryGroundAlpha = groundGlowAlpha * 0.4;
      _dynamicGroundGlowPaint.color = secondaryColor.withOpacity(secondaryGroundAlpha);
      canvas.drawCircle(
        Offset(center.dx + math.cos(_animationPhase) * 3, center.dy + math.sin(_animationPhase) * 3),
        groundGlowRadius * 0.7,
        _dynamicGroundGlowPaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: ANIMATED AMBIENT GLOW RING
    // ═══════════════════════════════════════════════════════════════════════
    final ambientPulse = 0.7 + math.sin(_animationPhase * 3) * 0.3;
    final ambientRadius = size.x * (0.6 + totalActivity * 0.2 + ambientPulse * 0.05);
    final ambientAlpha = (0.1 + totalActivity * 0.2) * ambientPulse;

    _dynamicAmbientGlowPaint.color = color.withOpacity(ambientAlpha);
    canvas.drawCircle(center, ambientRadius, _dynamicAmbientGlowPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: INNER ACTIVITY GLOW (intensifies with charge)
    // ═══════════════════════════════════════════════════════════════════════
    if (isCharging || hasTarget) {
      final innerPulse = 0.8 + math.sin(_animationPhase * 5) * 0.2;
      final innerRadius = size.x * (0.4 + _chargeLevel * 0.15);
      final innerAlpha = (0.15 + _chargeLevel * 0.3) * innerPulse;

      _dynamicInnerGlowPaint.color = color.withOpacity(innerAlpha);
      canvas.drawCircle(center, innerRadius, _dynamicInnerGlowPaint);

      // Charge buildup secondary glow
      if (!Tower.lowFx && _chargeLevel > 0.3) {
        final chargeGlowRadius = size.x * 0.35 * _chargeLevel;
        _dynamicChargeGlowPaint.color = secondaryColor.withOpacity(innerAlpha * 0.6);
        canvas.drawCircle(center, chargeGlowRadius, _dynamicChargeGlowPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: FIRING FLASH BURST
    // ═══════════════════════════════════════════════════════════════════════
    if (_isFiring) {
      final flashIntensity = _fireFlashTimer / 0.15; // 0 to 1 based on timer
      final flashRadius = size.x * (0.7 + flashIntensity * 0.4);
      final flashAlpha = flashIntensity * 0.6;

      // Main flash
      _dynamicFireFlashPaint.color = color.withOpacity(flashAlpha);
      canvas.drawCircle(center, flashRadius, _dynamicFireFlashPaint);

      // White hot center flash
      final whiteFlashRadius = flashRadius * 0.5 * flashIntensity;
      _dynamicFireFlashPaint.color = const Color(0xFFFFFFFF).withOpacity(flashAlpha * 0.8);
      canvas.drawCircle(center, whiteFlashRadius, _dynamicFireFlashPaint);

      // Chromatic aberration flash rings
      if (!Tower.lowFx) {
        final chromaOffset = 3 * flashIntensity;
        _dynamicFireFlashPaint.color = const Color(0xFFFF0066).withOpacity(flashAlpha * 0.3);
        canvas.drawCircle(Offset(center.dx - chromaOffset, center.dy), flashRadius * 0.8, _dynamicFireFlashPaint);

        _dynamicFireFlashPaint.color = const Color(0xFF00FFFF).withOpacity(flashAlpha * 0.3);
        canvas.drawCircle(Offset(center.dx + chromaOffset, center.dy), flashRadius * 0.8, _dynamicFireFlashPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: TARGET LOCK PULSE WAVES
    // ═══════════════════════════════════════════════════════════════════════
    if (hasTarget && !Tower.lowFx) {
      // Expanding pulse rings when targeting
      for (int i = 0; i < 2; i++) {
        final pulsePhase = ((_animationPhase * 2 + i * 0.5) % 1.0);
        final pulseRadius = size.x * (0.3 + pulsePhase * 0.4);
        final pulseAlpha = (1 - pulsePhase) * 0.2 * (1 + _chargeLevel);

        _dynamicTargetPulsePaint.color = color.withOpacity(pulseAlpha);
        canvas.drawCircle(center, pulseRadius, _dynamicTargetPulsePaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: ENERGY RAY EMISSIONS
    // ═══════════════════════════════════════════════════════════════════════
    if (!Tower.lowFx && totalActivity > 0.3) {
      final rayCount = hasTarget ? 8 : 4;
      final rayLength = size.x * (0.4 + totalActivity * 0.3);

      for (int i = 0; i < rayCount; i++) {
        final rayAngle = (i * math.pi * 2 / rayCount) + _animationPhase * 0.5;
        final rayFlicker = 0.5 + math.sin(_animationPhase * 8 + i * 1.5) * 0.5;

        if (rayFlicker > 0.3) {
          final rayAlpha = totalActivity * rayFlicker * 0.4;
          final rayEndX = center.dx + math.cos(rayAngle) * rayLength;
          final rayEndY = center.dy + math.sin(rayAngle) * rayLength;

          _dynamicEnergyRayPaint.color = color.withOpacity(rayAlpha);
          canvas.drawLine(center, Offset(rayEndX, rayEndY), _dynamicEnergyRayPaint);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: CORE ACTIVITY PULSE
    // ═══════════════════════════════════════════════════════════════════════
    final corePulse = 0.6 + math.sin(_animationPhase * 6) * 0.4;
    final coreRadius = size.x * (0.15 + totalActivity * 0.1) * corePulse;
    final coreAlpha = (0.2 + totalActivity * 0.4) * corePulse;

    _dynamicCorePulsePaint.color = color.withOpacity(coreAlpha);
    canvas.drawCircle(center, coreRadius, _dynamicCorePulsePaint);

    // Bright white center when highly active
    if (totalActivity > 0.5) {
      final whiteCoreAlpha = (totalActivity - 0.5) * corePulse;
      _dynamicCorePulsePaint.color = const Color(0xFFFFFFFF).withOpacity(whiteCoreAlpha);
      canvas.drawCircle(center, coreRadius * 0.4, _dynamicCorePulsePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 8: HALO RINGS (charge level indicator)
    // ═══════════════════════════════════════════════════════════════════════
    if (isCharging && !Tower.lowFx) {
      final ringCount = (_chargeLevel * 3).ceil();
      for (int i = 0; i < ringCount; i++) {
        final ringPhase = (_animationPhase * 4 + i * 0.3) % (math.pi * 2);
        final ringRadius = size.x * (0.35 + i * 0.08);
        final ringAlpha = 0.3 * (1 - i * 0.2) * (0.7 + math.sin(ringPhase) * 0.3);

        _dynamicHaloRingPaint.color = color.withOpacity(ringAlpha * _chargeLevel);
        canvas.drawCircle(center, ringRadius, _dynamicHaloRingPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 9: ACTIVITY SPARKS
    // ═══════════════════════════════════════════════════════════════════════
    if (!Tower.lowFx && totalActivity > 0.4) {
      final sparkCount = (totalActivity * 8).round();
      for (int i = 0; i < sparkCount; i++) {
        final sparkPhase = _animationPhase * 3 + i * 0.8;
        final sparkAngle = sparkPhase + math.sin(sparkPhase * 2) * 0.5;
        final sparkDist = size.x * (0.25 + (sparkPhase % 1.0) * 0.35);
        final sparkAlpha = (1 - (sparkPhase % 1.0)) * totalActivity * 0.6;

        final sparkX = center.dx + math.cos(sparkAngle) * sparkDist;
        final sparkY = center.dy + math.sin(sparkAngle) * sparkDist;

        _dynamicSparkPaint.color = color.withOpacity(sparkAlpha);
        canvas.drawCircle(Offset(sparkX, sparkY), 2, _dynamicSparkPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 10: ELECTRIC ARCS (when highly charged)
    // ═══════════════════════════════════════════════════════════════════════
    if (!Tower.lowFx && _chargeLevel > 0.7) {
      final arcIntensity = (_chargeLevel - 0.7) / 0.3; // 0 to 1
      final arcCount = (arcIntensity * 4).ceil();

      for (int i = 0; i < arcCount; i++) {
        final arcStartAngle = _animationPhase * 5 + i * math.pi / 2;
        final arcEndAngle = arcStartAngle + math.pi / 4 + _random.nextDouble() * math.pi / 4;

        _dynamicLightingPath.reset();
        final startRadius = size.x * 0.2;
        final endRadius = size.x * (0.4 + _random.nextDouble() * 0.15);

        var currentX = center.dx + math.cos(arcStartAngle) * startRadius;
        var currentY = center.dy + math.sin(arcStartAngle) * startRadius;
        _dynamicLightingPath.moveTo(currentX, currentY);

        // Create jagged arc path
        final segments = 4;
        for (int s = 1; s <= segments; s++) {
          final t = s / segments;
          final angle = arcStartAngle + (arcEndAngle - arcStartAngle) * t;
          final radius = startRadius + (endRadius - startRadius) * t;
          final jitter = (_random.nextDouble() - 0.5) * 6 * arcIntensity;

          currentX = center.dx + math.cos(angle) * radius + jitter;
          currentY = center.dy + math.sin(angle) * radius + jitter;
          _dynamicLightingPath.lineTo(currentX, currentY);
        }

        final arcAlpha = arcIntensity * (0.5 + math.sin(_animationPhase * 12 + i) * 0.3);
        _dynamicArcPaint.color = color.withOpacity(arcAlpha);
        canvas.drawPath(_dynamicLightingPath, _dynamicArcPaint);

        // Arc endpoint glow
        _dynamicSparkPaint.color = color.withOpacity(arcAlpha * 0.8);
        canvas.drawCircle(Offset(currentX, currentY), 3, _dynamicSparkPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 11: BOOST AURA (golden enhancement glow)
    // ═══════════════════════════════════════════════════════════════════════
    if (_isBoosted) {
      final boostPulse = 0.6 + math.sin(_animationPhase * 8) * 0.4;
      final boostRadius = size.x * (0.65 + boostPulse * 0.1);
      final boostAlpha = 0.15 * boostPulse;

      _dynamicAmbientGlowPaint.color = boostColor.withOpacity(boostAlpha);
      canvas.drawCircle(center, boostRadius, _dynamicAmbientGlowPaint);

      // Boost flare rays
      if (!Tower.lowFx) {
        for (int i = 0; i < 6; i++) {
          final flareAngle = _animationPhase * 2 + i * math.pi / 3;
          final flareLength = size.x * (0.5 + math.sin(_animationPhase * 6 + i) * 0.15);
          final flareAlpha = boostPulse * 0.3;

          final flareEndX = center.dx + math.cos(flareAngle) * flareLength;
          final flareEndY = center.dy + math.sin(flareAngle) * flareLength;

          _dynamicFlareRayPaint.color = boostColor.withOpacity(flareAlpha);
          canvas.drawLine(center, Offset(flareEndX, flareEndY), _dynamicFlareRayPaint);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 12: DIRECTIONAL TARGETING GLOW
    // ═══════════════════════════════════════════════════════════════════════
    if (hasTarget && !Tower.lowFx) {
      final targetDir = _rotationAngle;
      final dirGlowLength = size.x * 0.5;
      final dirGlowAlpha = 0.15 + _chargeLevel * 0.2;

      // Create directional glow wedge
      _dynamicLightingPath.reset();
      _dynamicLightingPath.moveTo(center.dx, center.dy);

      final wedgeSpread = math.pi / 6; // 30 degree spread
      final wedgeX1 = center.dx + math.cos(targetDir - wedgeSpread) * dirGlowLength;
      final wedgeY1 = center.dy + math.sin(targetDir - wedgeSpread) * dirGlowLength;
      final wedgeX2 = center.dx + math.cos(targetDir + wedgeSpread) * dirGlowLength;
      final wedgeY2 = center.dy + math.sin(targetDir + wedgeSpread) * dirGlowLength;

      _dynamicLightingPath.lineTo(wedgeX1, wedgeY1);
      _dynamicLightingPath.lineTo(wedgeX2, wedgeY2);
      _dynamicLightingPath.close();

      _dynamicTargetPulsePaint.color = color.withOpacity(dirGlowAlpha);
      canvas.drawPath(_dynamicLightingPath, _dynamicTargetPulsePaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEAT DISTORTION EFFECT FOR FIRE-TYPE TOWERS (Circuit Cannon)
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderHeatDistortion(Canvas canvas, Offset center) {
    final heatIntensity = 0.6 + _chargeLevel * 0.4 + (_isFiring ? 0.3 : 0);
    final heatColor = const Color(0xFFFF4400); // Orange-red heat color
    final heatColorAlt = const Color(0xFFFFAA00); // Yellow-orange

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: RISING HEAT SHIMMER WAVES
    // ═══════════════════════════════════════════════════════════════════════
    final waveCount = 6;
    for (int i = 0; i < waveCount; i++) {
      // Each wave rises up from the tower
      final wavePhase = (_animationPhase * 1.5 + i * 0.4) % 1.0;
      final waveY = center.dy - wavePhase * size.y * 1.5;
      final waveAlpha = (1 - wavePhase) * heatIntensity * 0.3;

      if (waveAlpha < 0.02) continue;

      // Horizontal wavy distortion line
      _heatPath.reset();
      final waveWidth = size.x * (1.2 - wavePhase * 0.5);
      final waveHeight = 3 + math.sin(_animationPhase * 8 + i) * 2;

      for (double x = -waveWidth / 2; x <= waveWidth / 2; x += 4) {
        final distort = math.sin(x * 0.15 + _animationPhase * 10 + i * 2) * waveHeight;
        final py = waveY + distort;
        if (x == -waveWidth / 2) {
          _heatPath.moveTo(center.dx + x, py);
        } else {
          _heatPath.lineTo(center.dx + x, py);
        }
      }

      _heatShimmerPaint.color = heatColor.withOpacity(waveAlpha);
      canvas.drawPath(_heatPath, _heatShimmerPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: VERTICAL DISTORTION LINES
    // ═══════════════════════════════════════════════════════════════════════
    final lineCount = 8;
    for (int i = 0; i < lineCount; i++) {
      final lineX = center.dx + (i - lineCount / 2) * (size.x / lineCount) * 1.5;
      final lineFlicker = math.sin(_animationPhase * 12 + i * 1.3) * 0.5 + 0.5;

      if (lineFlicker < 0.3) continue;

      final lineAlpha = heatIntensity * lineFlicker * 0.25;

      // Wavy vertical line
      _heatPath.reset();
      final lineHeight = size.y * 0.8;

      for (double y = 0; y <= lineHeight; y += 5) {
        final xDistort = math.sin(y * 0.2 + _animationPhase * 6 + i) * (3 + heatIntensity * 3);
        final px = lineX + xDistort;
        final py = center.dy - y;

        if (y == 0) {
          _heatPath.moveTo(px, py);
        } else {
          _heatPath.lineTo(px, py);
        }
      }

      _heatWavePaint.color = heatColorAlt.withOpacity(lineAlpha);
      canvas.drawPath(_heatPath, _heatWavePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: HEAT RIPPLE RINGS
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < 3; i++) {
      final ripplePhase = (_animationPhase * 2 + i * 0.4) % 1.0;
      final rippleRadius = size.x * (0.3 + ripplePhase * 0.8);
      final rippleAlpha = (1 - ripplePhase) * heatIntensity * 0.2;

      if (rippleAlpha < 0.02) continue;

      _heatRipplePaint.color = heatColor.withOpacity(rippleAlpha);
      canvas.drawCircle(center, rippleRadius, _heatRipplePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: AMBIENT HEAT GLOW
    // ═══════════════════════════════════════════════════════════════════════
    final glowPulse = 0.7 + math.sin(_animationPhase * 4) * 0.3;
    final glowRadius = size.x * (0.7 + heatIntensity * 0.3);
    final glowAlpha = heatIntensity * 0.15 * glowPulse;

    _heatGlowPaint.color = heatColor.withOpacity(glowAlpha);
    canvas.drawCircle(center, glowRadius, _heatGlowPaint);

    // Secondary orange glow
    _heatGlowPaint.color = heatColorAlt.withOpacity(glowAlpha * 0.7);
    canvas.drawCircle(
      Offset(center.dx, center.dy - size.y * 0.15),
      glowRadius * 0.7,
      _heatGlowPaint,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: SPARKS AND EMBERS (rising particles)
    // ═══════════════════════════════════════════════════════════════════════
    final sparkCount = (6 * heatIntensity).ceil();
    for (int i = 0; i < sparkCount; i++) {
      final sparkPhase = (_animationPhase * 2 + i * 0.5) % 1.0;
      final sparkX = center.dx + ((_random.nextDouble() - 0.5) * size.x * 0.8);
      final sparkY = center.dy - sparkPhase * size.y * 1.2;
      final sparkAlpha = (1 - sparkPhase) * heatIntensity * 0.8;

      if (sparkAlpha < 0.1) continue;

      // Ember color varies from yellow to orange to red
      final emberHue = 30 + sparkPhase * 30; // Yellow to orange
      final emberColor = HSLColor.fromAHSL(1, emberHue, 1, 0.5 + (1 - sparkPhase) * 0.3).toColor();

      _heatSparkPaint.color = emberColor.withOpacity(sparkAlpha);
      canvas.drawCircle(Offset(sparkX, sparkY), 2 + (1 - sparkPhase) * 2, _heatSparkPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: HEAT HAZE OVERLAY (subtle distortion indicator)
    // ═══════════════════════════════════════════════════════════════════════
    if (_isFiring) {
      final hazeIntensity = _fireFlashTimer / 0.15;
      final hazeRadius = size.x * (0.9 + hazeIntensity * 0.3);
      final hazeAlpha = hazeIntensity * 0.2;

      _heatGlowPaint.color = Colors.white.withOpacity(hazeAlpha);
      canvas.drawCircle(center, hazeRadius, _heatGlowPaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ICE CRYSTAL FORMATION EFFECT FOR FREEZE TOWERS (Phase Mage)
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderIceCrystalEffect(Canvas canvas, Offset center) {
    final freezeIntensity = 0.5 + _chargeLevel * 0.5 + (_isFiring ? 0.4 : 0);
    final iceColor = const Color(0xFF88DDFF); // Light cyan ice
    final iceColorCore = const Color(0xFFAAEEFF); // Brighter core
    final iceColorDeep = const Color(0xFF4488CC); // Deep blue ice

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: AMBIENT FROST AURA
    // ═══════════════════════════════════════════════════════════════════════
    final auraPulse = 0.7 + math.sin(_animationPhase * 3) * 0.3;
    final auraRadius = size.x * (0.7 + freezeIntensity * 0.4);

    _iceFrostPaint.color = iceColor.withOpacity(freezeIntensity * 0.12 * auraPulse);
    canvas.drawCircle(center, auraRadius, _iceFrostPaint);

    // Inner cold core glow
    _iceFrostPaint.color = iceColorCore.withOpacity(freezeIntensity * 0.2 * auraPulse);
    canvas.drawCircle(center, auraRadius * 0.5, _iceFrostPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: FLOATING ICE CRYSTALS (hexagonal formations)
    // ═══════════════════════════════════════════════════════════════════════
    final crystalCount = 6;
    for (int i = 0; i < crystalCount; i++) {
      final crystalAngle = (i * math.pi * 2 / crystalCount) + _animationPhase * 0.5;
      final crystalDistance = size.x * (0.4 + math.sin(_animationPhase * 2 + i) * 0.15);
      final crystalX = center.dx + math.cos(crystalAngle) * crystalDistance;
      final crystalY = center.dy + math.sin(crystalAngle) * crystalDistance;

      // Crystal rotation
      final crystalRotation = _animationPhase * 1.5 + i * 0.7;
      final crystalSize = 4 + math.sin(_animationPhase * 3 + i * 1.2) * 2;
      final crystalAlpha = freezeIntensity * (0.5 + math.sin(_animationPhase * 4 + i) * 0.3);

      if (crystalAlpha < 0.1) continue;

      // Draw hexagonal crystal
      _icePath.reset();
      for (int j = 0; j < 6; j++) {
        final hexAngle = crystalRotation + j * math.pi / 3;
        final hx = crystalX + math.cos(hexAngle) * crystalSize;
        final hy = crystalY + math.sin(hexAngle) * crystalSize;
        if (j == 0) {
          _icePath.moveTo(hx, hy);
        } else {
          _icePath.lineTo(hx, hy);
        }
      }
      _icePath.close();

      // Fill with gradient effect
      _iceCrystalFillPaint.color = iceColorCore.withOpacity(crystalAlpha * 0.3);
      canvas.drawPath(_icePath, _iceCrystalFillPaint);

      // Outline
      _iceCrystalPaint.color = iceColor.withOpacity(crystalAlpha);
      canvas.drawPath(_icePath, _iceCrystalPaint);

      // Inner crystal structure lines
      for (int k = 0; k < 3; k++) {
        final lineAngle = crystalRotation + k * math.pi / 3;
        _iceShardPaint.color = iceColorCore.withOpacity(crystalAlpha * 0.6);
        canvas.drawLine(
          Offset(crystalX, crystalY),
          Offset(
            crystalX + math.cos(lineAngle) * crystalSize * 0.8,
            crystalY + math.sin(lineAngle) * crystalSize * 0.8,
          ),
          _iceShardPaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: SNOWFLAKE PARTICLES
    // ═══════════════════════════════════════════════════════════════════════
    final snowflakeCount = (8 * freezeIntensity).ceil();
    for (int i = 0; i < snowflakeCount; i++) {
      final snowPhase = (_animationPhase * 0.8 + i * 0.35) % 1.0;
      final fallDistance = size.y * 1.2;

      // Snowflakes drift down and outward
      final snowX = center.dx + math.sin(_animationPhase * 3 + i * 1.5) * size.x * 0.6;
      final snowY = center.dy - fallDistance / 2 + snowPhase * fallDistance;
      final snowAlpha = (1 - math.pow((snowPhase - 0.5).abs() * 2, 2)) * freezeIntensity * 0.7;

      if (snowAlpha < 0.1) continue;

      final snowSize = 2 + (i % 3);

      // Draw 6-pointed snowflake
      _iceSnowflakePaint.color = iceColorCore.withOpacity(snowAlpha);
      for (int j = 0; j < 6; j++) {
        final armAngle = j * math.pi / 3 + _animationPhase * 2;
        canvas.drawLine(
          Offset(snowX, snowY),
          Offset(
            snowX + math.cos(armAngle) * snowSize,
            snowY + math.sin(armAngle) * snowSize,
          ),
          _iceSnowflakePaint,
        );
        // Small branches on each arm
        final branchLen = snowSize * 0.4;
        final midX = snowX + math.cos(armAngle) * snowSize * 0.6;
        final midY = snowY + math.sin(armAngle) * snowSize * 0.6;
        canvas.drawLine(
          Offset(midX, midY),
          Offset(
            midX + math.cos(armAngle + 0.5) * branchLen,
            midY + math.sin(armAngle + 0.5) * branchLen,
          ),
          _iceSnowflakePaint,
        );
        canvas.drawLine(
          Offset(midX, midY),
          Offset(
            midX + math.cos(armAngle - 0.5) * branchLen,
            midY + math.sin(armAngle - 0.5) * branchLen,
          ),
          _iceSnowflakePaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: FROST SPIKES RADIATING OUTWARD
    // ═══════════════════════════════════════════════════════════════════════
    final spikeCount = 12;
    for (int i = 0; i < spikeCount; i++) {
      final spikeAngle = i * math.pi * 2 / spikeCount + math.sin(_animationPhase * 2) * 0.1;
      final spikeFlicker = math.sin(_animationPhase * 6 + i * 1.1) * 0.5 + 0.5;

      if (spikeFlicker < 0.25) continue;

      final spikeLength = size.x * (0.3 + spikeFlicker * 0.25 * freezeIntensity);
      final spikeWidth = 2 + spikeFlicker * 1.5;
      final spikeAlpha = freezeIntensity * spikeFlicker * 0.5;

      // Draw ice spike (elongated triangle)
      _icePath.reset();
      final spikeStart = size.x * 0.15;
      final perpAngle = spikeAngle + math.pi / 2;

      // Base of spike
      _icePath.moveTo(
        center.dx + math.cos(spikeAngle) * spikeStart + math.cos(perpAngle) * spikeWidth,
        center.dy + math.sin(spikeAngle) * spikeStart + math.sin(perpAngle) * spikeWidth,
      );
      // Tip of spike
      _icePath.lineTo(
        center.dx + math.cos(spikeAngle) * (spikeStart + spikeLength),
        center.dy + math.sin(spikeAngle) * (spikeStart + spikeLength),
      );
      // Other base corner
      _icePath.lineTo(
        center.dx + math.cos(spikeAngle) * spikeStart - math.cos(perpAngle) * spikeWidth,
        center.dy + math.sin(spikeAngle) * spikeStart - math.sin(perpAngle) * spikeWidth,
      );
      _icePath.close();

      // Spike fill
      _iceCrystalFillPaint.color = iceColorDeep.withOpacity(spikeAlpha * 0.4);
      canvas.drawPath(_icePath, _iceCrystalFillPaint);

      // Spike outline
      _iceCrystalPaint.color = iceColor.withOpacity(spikeAlpha);
      canvas.drawPath(_icePath, _iceCrystalPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: COLD AURA RINGS
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < 3; i++) {
      final ringPhase = (_animationPhase * 1.5 + i * 0.4) % 1.0;
      final ringRadius = size.x * (0.2 + ringPhase * 0.6);
      final ringAlpha = (1 - ringPhase) * freezeIntensity * 0.3;

      if (ringAlpha < 0.03) continue;

      _iceAuraPaint.color = iceColor.withOpacity(ringAlpha);
      canvas.drawCircle(center, ringRadius, _iceAuraPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: ICE SPARKLES / GLITTER
    // ═══════════════════════════════════════════════════════════════════════
    final sparkleCount = (10 * freezeIntensity).ceil();
    for (int i = 0; i < sparkleCount; i++) {
      final sparklePhase = (_animationPhase * 4 + i * 0.8) % 1.0;
      final sparkleFlash = math.pow(math.sin(sparklePhase * math.pi), 3);

      if (sparkleFlash < 0.2) continue;

      // Random position around the tower
      final sparkleRandom = math.Random(i * 31 + (_animationPhase * 10).floor());
      final sparkleAngle = sparkleRandom.nextDouble() * math.pi * 2;
      final sparkleDistance = sparkleRandom.nextDouble() * size.x * 0.8;
      final sparkleX = center.dx + math.cos(sparkleAngle) * sparkleDistance;
      final sparkleY = center.dy + math.sin(sparkleAngle) * sparkleDistance;

      final sparkleAlpha = sparkleFlash * freezeIntensity * 0.9;
      final double sparkleSize = 2.0 + sparkleFlash * 2.0;

      // Bright center
      _iceSparkPaint.color = Colors.white.withOpacity(sparkleAlpha);
      canvas.drawCircle(Offset(sparkleX, sparkleY), sparkleSize * 0.5, _iceSparkPaint);

      // Colored halo
      _iceSparkPaint.color = iceColorCore.withOpacity(sparkleAlpha * 0.6);
      canvas.drawCircle(Offset(sparkleX, sparkleY), sparkleSize, _iceSparkPaint);

      // Tiny cross-shaped glint
      _iceSnowflakePaint.color = Colors.white.withOpacity(sparkleAlpha * 0.8);
      canvas.drawLine(
        Offset(sparkleX - sparkleSize, sparkleY),
        Offset(sparkleX + sparkleSize, sparkleY),
        _iceSnowflakePaint,
      );
      canvas.drawLine(
        Offset(sparkleX, sparkleY - sparkleSize),
        Offset(sparkleX, sparkleY + sparkleSize),
        _iceSnowflakePaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: CENTRAL ICE GLOW (intensifies when charging/firing)
    // ═══════════════════════════════════════════════════════════════════════
    if (_chargeLevel > 0.3 || _isFiring) {
      final coreIntensity = _isFiring ? 1.0 : _chargeLevel;
      final corePulse = 0.8 + math.sin(_animationPhase * 8) * 0.2;
      final coreRadius = size.x * 0.3 * coreIntensity;

      // Bright white core
      _iceGlowPaint.color = Colors.white.withOpacity(coreIntensity * 0.4 * corePulse);
      canvas.drawCircle(center, coreRadius * 0.5, _iceGlowPaint);

      // Cyan outer glow
      _iceGlowPaint.color = iceColorCore.withOpacity(coreIntensity * 0.3 * corePulse);
      canvas.drawCircle(center, coreRadius, _iceGlowPaint);

      // Deep blue halo
      _iceGlowPaint.color = iceColorDeep.withOpacity(coreIntensity * 0.2 * corePulse);
      canvas.drawCircle(center, coreRadius * 1.5, _iceGlowPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 8: FREEZE BURST EFFECT WHEN FIRING
    // ═══════════════════════════════════════════════════════════════════════
    if (_isFiring && _fireFlashTimer > 0) {
      final burstProgress = _fireFlashTimer / 0.15;
      final burstRadius = size.x * (0.3 + (1 - burstProgress) * 0.6);
      final burstAlpha = burstProgress * 0.5;

      // Expanding freeze ring
      _iceAuraPaint.color = iceColorCore.withOpacity(burstAlpha);
      _iceAuraPaint.strokeWidth = 3 * burstProgress;
      canvas.drawCircle(center, burstRadius, _iceAuraPaint);
      _iceAuraPaint.strokeWidth = 2; // Reset

      // Radial ice shards burst
      for (int i = 0; i < 8; i++) {
        final shardAngle = i * math.pi / 4 + _animationPhase;
        final shardLength = burstRadius * 0.4 * burstProgress;
        final shardStart = burstRadius * 0.8;

        _iceShardPaint.color = iceColor.withOpacity(burstAlpha);
        canvas.drawLine(
          Offset(
            center.dx + math.cos(shardAngle) * shardStart,
            center.dy + math.sin(shardAngle) * shardStart,
          ),
          Offset(
            center.dx + math.cos(shardAngle) * (shardStart + shardLength),
            center.dy + math.sin(shardAngle) * (shardStart + shardLength),
          ),
          _iceShardPaint,
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENERGY WEB TRAP EFFECT FOR SLOW TOWERS (Phase Mage, Glimmer Field)
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderEnergyWeb(Canvas canvas, Offset center) {
    final webIntensity = _webExpansion * (0.6 + _chargeLevel * 0.3 + (_isFiring ? 0.4 : 0));
    if (webIntensity < 0.01) return;

    // Cyan/blue color scheme for energy web
    const webColorPrimary = Color(0xFF00DDFF); // Bright cyan
    const webColorSecondary = Color(0xFF0088FF); // Deep blue
    const webColorAccent = Color(0xFF00FFAA); // Cyan-green accent
    const webColorCore = Color(0xFFFFFFFF); // White core

    final strandCount = 12;
    final ringCount = 4;
    final maxWebRadius = range * _webExpansion;
    final baseRadius = size.x * 0.3;

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: CENTRAL WEB HUB AT TOWER POSITION
    // ═══════════════════════════════════════════════════════════════════════
    final hubPulse = 0.7 + math.sin(_webPulsePhase * 4) * 0.3;
    final hubRadius = size.x * 0.25 * webIntensity;

    // Outer hub glow
    _webHubGlowPaint.color = webColorPrimary.withOpacity(webIntensity * 0.3 * hubPulse);
    canvas.drawCircle(center, hubRadius * 2, _webHubGlowPaint);

    // Inner hub glow
    _webHubGlowPaint.color = webColorSecondary.withOpacity(webIntensity * 0.4 * hubPulse);
    canvas.drawCircle(center, hubRadius * 1.2, _webHubGlowPaint);

    // Hub core
    _webHubCorePaint.color = webColorCore.withOpacity(webIntensity * 0.6 * hubPulse);
    canvas.drawCircle(center, hubRadius * 0.5, _webHubCorePaint);

    // Hub ring
    _webRingPaint.color = webColorPrimary.withOpacity(webIntensity * 0.5);
    _webRingPaint.strokeWidth = 2;
    canvas.drawCircle(center, hubRadius, _webRingPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: RADIAL WEB STRANDS EXTENDING OUTWARD
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < strandCount; i++) {
      final strandAngle = i * math.pi * 2 / strandCount + _animationPhase * 0.1;
      final strandWobble = math.sin(_webPulsePhase * 2 + i * 0.5) * 0.05;
      final wobbledAngle = strandAngle + strandWobble;

      // Calculate strand length based on expansion
      final strandLength = baseRadius + (maxWebRadius - baseRadius) * _webExpansion;

      // Draw glow layer first
      _webStrandGlowPaint.color = webColorPrimary.withOpacity(webIntensity * 0.2);
      canvas.drawLine(
        Offset(
          center.dx + math.cos(wobbledAngle) * baseRadius * 0.5,
          center.dy + math.sin(wobbledAngle) * baseRadius * 0.5,
        ),
        Offset(
          center.dx + math.cos(wobbledAngle) * strandLength,
          center.dy + math.sin(wobbledAngle) * strandLength,
        ),
        _webStrandGlowPaint,
      );

      // Draw core strand
      final strandPulse = 0.5 + math.sin(_webPulsePhase * 3 + i) * 0.3;
      _webStrandPaint.color = webColorPrimary.withOpacity(webIntensity * 0.6 * strandPulse);
      canvas.drawLine(
        Offset(
          center.dx + math.cos(wobbledAngle) * baseRadius * 0.5,
          center.dy + math.sin(wobbledAngle) * baseRadius * 0.5,
        ),
        Offset(
          center.dx + math.cos(wobbledAngle) * strandLength,
          center.dy + math.sin(wobbledAngle) * strandLength,
        ),
        _webStrandPaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: CONCENTRIC CONNECTING RINGS BETWEEN STRANDS
    // ═══════════════════════════════════════════════════════════════════════
    for (int ring = 1; ring <= ringCount; ring++) {
      final ringProgress = ring / (ringCount + 1);
      final ringRadius = baseRadius + (maxWebRadius - baseRadius) * ringProgress * _webExpansion;

      if (ringRadius < baseRadius * 0.6) continue;

      final ringPulse = 0.4 + math.sin(_webPulsePhase * 2 + ring * 0.8) * 0.3;
      final ringAlpha = webIntensity * 0.4 * ringPulse * (1 - ringProgress * 0.3);

      // Draw segmented ring connecting strands
      _webPath.reset();
      for (int i = 0; i <= strandCount; i++) {
        final angle = i * math.pi * 2 / strandCount + _animationPhase * 0.1;
        final wobble = math.sin(_webPulsePhase * 2 + i * 0.5 + ring) * 0.03;
        final x = center.dx + math.cos(angle + wobble) * ringRadius;
        final y = center.dy + math.sin(angle + wobble) * ringRadius;

        if (i == 0) {
          _webPath.moveTo(x, y);
        } else {
          _webPath.lineTo(x, y);
        }
      }

      _webRingPaint.color = webColorSecondary.withOpacity(ringAlpha);
      _webRingPaint.strokeWidth = 1.5 - ring * 0.2;
      canvas.drawPath(_webPath, _webRingPaint);

      // Add glow to outer rings
      if (ring >= ringCount - 1) {
        _webShimmerPaint.color = webColorPrimary.withOpacity(ringAlpha * 0.3);
        canvas.drawCircle(center, ringRadius, _webShimmerPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: ENERGY PULSES TRAVELING ALONG WEB STRANDS
    // ═══════════════════════════════════════════════════════════════════════
    final pulseCount = (6 * webIntensity).ceil();
    for (int i = 0; i < pulseCount; i++) {
      // Each pulse travels along a strand
      final strandIndex = i % strandCount;
      final strandAngle = strandIndex * math.pi * 2 / strandCount + _animationPhase * 0.1;

      // Pulse travels outward along the strand
      final pulsePhase = (_webPulsePhase * 1.5 + i * 0.3) % 1.0;
      final strandLength = baseRadius + (maxWebRadius - baseRadius) * _webExpansion;
      final pulseDistance = baseRadius * 0.5 + (strandLength - baseRadius * 0.5) * pulsePhase;

      // Pulse fades at beginning and end
      final pulseAlpha = math.sin(pulsePhase * math.pi) * webIntensity * 0.8;
      if (pulseAlpha < 0.1) continue;

      final pulseX = center.dx + math.cos(strandAngle) * pulseDistance;
      final pulseY = center.dy + math.sin(strandAngle) * pulseDistance;
      final pulseSize = 3 + math.sin(_webPulsePhase * 6 + i) * 1.5;

      // Pulse glow
      _webPulsePaint.color = webColorPrimary.withOpacity(pulseAlpha * 0.5);
      canvas.drawCircle(Offset(pulseX, pulseY), pulseSize * 2, _webPulsePaint);

      // Pulse core
      _webPulseCorePaint.color = webColorCore.withOpacity(pulseAlpha);
      canvas.drawCircle(Offset(pulseX, pulseY), pulseSize, _webPulseCorePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: TRAPPED ENEMY HIGHLIGHTING (glow around affected enemies)
    // ═══════════════════════════════════════════════════════════════════════
    for (final enemy in _slowedEnemies) {
      if (!enemy.isAlive) continue;

      final enemyPos = Offset(
        enemy.position.x - position.x,
        enemy.position.y - position.y,
      );
      final distanceToEnemy = (enemyPos - center).distance;

      // Only highlight enemies within web range
      if (distanceToEnemy > maxWebRadius * 1.2) continue;

      final trapPulse = 0.6 + math.sin(_webPulsePhase * 5) * 0.4;
      final trapIntensity = webIntensity * (1 - distanceToEnemy / (maxWebRadius * 1.5)).clamp(0.0, 1.0);

      // Outer trap glow
      _webTrapGlowPaint.color = webColorAccent.withOpacity(trapIntensity * 0.25 * trapPulse);
      canvas.drawCircle(enemyPos, 20, _webTrapGlowPaint);

      // Inner trap glow
      _webTrapGlowPaint.color = webColorPrimary.withOpacity(trapIntensity * 0.35 * trapPulse);
      canvas.drawCircle(enemyPos, 12, _webTrapGlowPaint);

      // Trap ring
      _webTrapRingPaint.color = webColorPrimary.withOpacity(trapIntensity * 0.5 * trapPulse);
      canvas.drawCircle(enemyPos, 15, _webTrapRingPaint);

      // Hexagonal trap indicator
      _webPath.reset();
      for (int j = 0; j < 6; j++) {
        final hexAngle = j * math.pi / 3 + _webPulsePhase;
        final hexRadius = 10 + math.sin(_webPulsePhase * 4) * 2;
        final hx = enemyPos.dx + math.cos(hexAngle) * hexRadius;
        final hy = enemyPos.dy + math.sin(hexAngle) * hexRadius;
        if (j == 0) {
          _webPath.moveTo(hx, hy);
        } else {
          _webPath.lineTo(hx, hy);
        }
      }
      _webPath.close();
      _webRingPaint.color = webColorAccent.withOpacity(trapIntensity * 0.4 * trapPulse);
      _webRingPaint.strokeWidth = 1;
      canvas.drawPath(_webPath, _webRingPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: WEB SHIMMER/FLICKER EFFECT
    // ═══════════════════════════════════════════════════════════════════════
    final shimmerCount = (8 * webIntensity).ceil();
    for (int i = 0; i < shimmerCount; i++) {
      final shimmerPhase = (_webPulsePhase * 3 + i * 0.6) % 1.0;
      final shimmerFlash = math.pow(math.sin(shimmerPhase * math.pi), 4);

      if (shimmerFlash < 0.15) continue;

      // Random position along web structure
      final shimmerRandom = _webRandom.nextInt(1000) + i * 137 + (_webPulsePhase * 5).floor();
      final shimmerSeed = math.Random(shimmerRandom);
      final shimmerAngle = shimmerSeed.nextDouble() * math.pi * 2;
      final shimmerDistance = baseRadius + shimmerSeed.nextDouble() * (maxWebRadius - baseRadius) * _webExpansion;
      final shimmerX = center.dx + math.cos(shimmerAngle) * shimmerDistance;
      final shimmerY = center.dy + math.sin(shimmerAngle) * shimmerDistance;

      final shimmerAlpha = shimmerFlash * webIntensity * 0.7;
      final shimmerSize = 2 + shimmerFlash * 2;

      // Shimmer glow
      _webShimmerPaint.color = webColorCore.withOpacity(shimmerAlpha * 0.6);
      canvas.drawCircle(Offset(shimmerX, shimmerY), shimmerSize * 1.5, _webShimmerPaint);

      // Shimmer core
      _webPulseCorePaint.color = webColorCore.withOpacity(shimmerAlpha);
      canvas.drawCircle(Offset(shimmerX, shimmerY), shimmerSize * 0.5, _webPulseCorePaint);

      // Cross-shaped glint
      _webStrandPaint.color = webColorCore.withOpacity(shimmerAlpha * 0.8);
      canvas.drawLine(
        Offset(shimmerX - shimmerSize, shimmerY),
        Offset(shimmerX + shimmerSize, shimmerY),
        _webStrandPaint,
      );
      canvas.drawLine(
        Offset(shimmerX, shimmerY - shimmerSize),
        Offset(shimmerX, shimmerY + shimmerSize),
        _webStrandPaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: STRAND TENSION LINES TO TRAPPED ENEMIES
    // ═══════════════════════════════════════════════════════════════════════
    for (final enemy in _slowedEnemies) {
      if (!enemy.isAlive) continue;

      final enemyPos = Offset(
        enemy.position.x - position.x,
        enemy.position.y - position.y,
      );
      final distanceToEnemy = (enemyPos - center).distance;

      // Only draw tension lines to enemies within range
      if (distanceToEnemy > maxWebRadius * 1.3) continue;

      final tensionIntensity = webIntensity * (1 - distanceToEnemy / (maxWebRadius * 1.5)).clamp(0.0, 1.0);
      final tensionPulse = 0.5 + math.sin(_webPulsePhase * 6 + distanceToEnemy * 0.01) * 0.4;

      // Calculate the angle to the enemy
      final angleToEnemy = math.atan2(enemyPos.dy - center.dy, enemyPos.dx - center.dx);

      // Find nearest strand angle
      final nearestStrandIndex = ((angleToEnemy / (math.pi * 2 / strandCount)) % strandCount).round() % strandCount;
      final nearestStrandAngle = nearestStrandIndex * math.pi * 2 / strandCount + _animationPhase * 0.1;

      // Draw tension line from nearest strand intersection to enemy
      final strandLength = baseRadius + (maxWebRadius - baseRadius) * _webExpansion;
      final intersectionDistance = (distanceToEnemy * 0.7).clamp(baseRadius, strandLength);
      final intersectionX = center.dx + math.cos(nearestStrandAngle) * intersectionDistance;
      final intersectionY = center.dy + math.sin(nearestStrandAngle) * intersectionDistance;

      // Draw wavy tension line
      _webPath.reset();
      _webPath.moveTo(intersectionX, intersectionY);

      // Create curved path to enemy with slight wave
      final midX = (intersectionX + enemyPos.dx) / 2;
      final midY = (intersectionY + enemyPos.dy) / 2;
      final perpAngle = angleToEnemy + math.pi / 2;
      final waveAmount = math.sin(_webPulsePhase * 4) * 8 * tensionIntensity;
      final controlX = midX + math.cos(perpAngle) * waveAmount;
      final controlY = midY + math.sin(perpAngle) * waveAmount;

      _webPath.quadraticBezierTo(controlX, controlY, enemyPos.dx, enemyPos.dy);

      // Draw tension glow
      _webTensionGlowPaint.color = webColorAccent.withOpacity(tensionIntensity * 0.2 * tensionPulse);
      canvas.drawPath(_webPath, _webTensionGlowPaint);

      // Draw tension core
      _webTensionPaint.color = webColorPrimary.withOpacity(tensionIntensity * 0.5 * tensionPulse);
      canvas.drawPath(_webPath, _webTensionPaint);

      // Draw energy nodes along tension line
      final nodeCount = 3;
      for (int n = 1; n < nodeCount; n++) {
        final t = n / nodeCount;
        // Approximate position along the quadratic bezier
        final nodeX = (1 - t) * (1 - t) * intersectionX + 2 * (1 - t) * t * controlX + t * t * enemyPos.dx;
        final nodeY = (1 - t) * (1 - t) * intersectionY + 2 * (1 - t) * t * controlY + t * t * enemyPos.dy;

        final nodePulse = 0.5 + math.sin(_webPulsePhase * 5 + n * 1.2) * 0.5;
        final nodeAlpha = tensionIntensity * 0.6 * nodePulse;

        _webPulsePaint.color = webColorPrimary.withOpacity(nodeAlpha * 0.4);
        canvas.drawCircle(Offset(nodeX, nodeY), 4, _webPulsePaint);

        _webPulseCorePaint.color = webColorCore.withOpacity(nodeAlpha);
        canvas.drawCircle(Offset(nodeX, nodeY), 2, _webPulseCorePaint);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VORTEX/BLACK HOLE EFFECT FOR RESONANCE SIPHON TOWERS
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderVortexEffect(Canvas canvas, Offset center) {
    final vortexIntensity = 0.6 + _chargeLevel * 0.4 + (_isFiring ? 0.3 : 0);
    final vortexColor = const Color(0xFFFF0066); // Deep magenta/pink
    final vortexColorInner = const Color(0xFF6600FF); // Purple void
    final vortexColorAccent = const Color(0xFF00FFFF); // Cyan accent

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: OUTER GRAVITATIONAL DISTORTION FIELD
    // ═══════════════════════════════════════════════════════════════════════
    final distortRadius = size.x * (1.2 + vortexIntensity * 0.3);
    final distortCount = 24;
    for (int i = 0; i < distortCount; i++) {
      final angle = i * math.pi * 2 / distortCount + _animationPhase * 0.5;
      final distortWobble = math.sin(_animationPhase * 3 + i * 0.5) * 0.15;
      final radiusVar = distortRadius * (0.9 + distortWobble);
      final innerRadius = radiusVar * 0.3;
      final outerRadius = radiusVar;

      // Curved distortion lines being sucked inward
      _vortexPath.reset();
      for (int j = 0; j <= 8; j++) {
        final t = j / 8;
        final spiralAngle = angle + t * math.pi * 0.3;
        final r = outerRadius - (outerRadius - innerRadius) * t;
        final x = center.dx + math.cos(spiralAngle) * r;
        final y = center.dy + math.sin(spiralAngle) * r;
        if (j == 0) {
          _vortexPath.moveTo(x, y);
        } else {
          _vortexPath.lineTo(x, y);
        }
      }

      final lineAlpha = vortexIntensity * (0.15 + math.sin(_animationPhase * 4 + i) * 0.1);
      _vortexDistortPaint.color = vortexColor.withOpacity(lineAlpha);
      canvas.drawPath(_vortexPath, _vortexDistortPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: SPIRALING MATTER BEING ABSORBED
    // ═══════════════════════════════════════════════════════════════════════
    final spiralCount = 4;
    for (int i = 0; i < spiralCount; i++) {
      final spiralBaseAngle = i * math.pi * 2 / spiralCount + _animationPhase * 2;
      final spiralLength = size.x * (0.8 + vortexIntensity * 0.4);

      _vortexPath.reset();
      for (int j = 0; j <= 20; j++) {
        final t = j / 20;
        // Logarithmic spiral
        final spiralAngle = spiralBaseAngle + t * math.pi * 1.5;
        final r = spiralLength * (1 - math.pow(t, 0.6));
        final x = center.dx + math.cos(spiralAngle) * r;
        final y = center.dy + math.sin(spiralAngle) * r;

        if (j == 0) {
          _vortexPath.moveTo(x, y);
        } else {
          _vortexPath.lineTo(x, y);
        }
      }

      final spiralAlpha = vortexIntensity * (0.4 + math.sin(_animationPhase * 5 + i * 1.5) * 0.2);
      _vortexSpiralPaint.color = vortexColorAccent.withOpacity(spiralAlpha);
      canvas.drawPath(_vortexPath, _vortexSpiralPaint);

      // Secondary glow spiral
      _vortexSpiralPaint.strokeWidth = 3;
      _vortexSpiralPaint.color = vortexColor.withOpacity(spiralAlpha * 0.3);
      canvas.drawPath(_vortexPath, _vortexSpiralPaint);
      _vortexSpiralPaint.strokeWidth = 1.5;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: ACCRETION DISK RINGS
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < 5; i++) {
      final ringProgress = (_animationPhase * 1.5 + i * 0.3) % 1.0;
      final ringRadius = size.x * (0.2 + ringProgress * 0.7);
      final ringAlpha = (1 - ringProgress) * vortexIntensity * 0.35;

      if (ringAlpha < 0.03) continue;

      // Elliptical ring (simulating 3D perspective)
      final ellipseScaleY = 0.4 + math.sin(_animationPhase * 2) * 0.1;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(1.0, ellipseScaleY);
      canvas.translate(-center.dx, -center.dy);

      _vortexRingPaint.color = vortexColor.withOpacity(ringAlpha);
      canvas.drawCircle(center, ringRadius, _vortexRingPaint);

      // Inner bright edge
      _vortexRingPaint.strokeWidth = 1;
      _vortexRingPaint.color = vortexColorAccent.withOpacity(ringAlpha * 0.8);
      canvas.drawCircle(center, ringRadius * 0.95, _vortexRingPaint);
      _vortexRingPaint.strokeWidth = 2;

      canvas.restore();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: EVENT HORIZON (Inner dark circle with glowing edge)
    // ═══════════════════════════════════════════════════════════════════════
    final horizonRadius = size.x * 0.25;
    final horizonPulse = 0.9 + math.sin(_animationPhase * 6) * 0.1;

    // Dark void core
    _vortexCorePaint.color = const Color(0xFF000011).withOpacity(0.95);
    canvas.drawCircle(center, horizonRadius * horizonPulse, _vortexCorePaint);

    // Event horizon glow
    _vortexEventHorizonPaint.color = vortexColorInner.withOpacity(vortexIntensity * 0.7);
    canvas.drawCircle(center, horizonRadius * horizonPulse, _vortexEventHorizonPaint);

    // Outer horizon glow
    _vortexEventHorizonPaint.color = vortexColor.withOpacity(vortexIntensity * 0.5);
    canvas.drawCircle(center, horizonRadius * horizonPulse * 1.2, _vortexEventHorizonPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: PARTICLES BEING PULLED IN
    // ═══════════════════════════════════════════════════════════════════════
    final particleCount = (12 * vortexIntensity).ceil();
    for (int i = 0; i < particleCount; i++) {
      final particlePhase = (_animationPhase * 2 + i * 0.4) % 1.0;
      final particleAngle = i * math.pi * 2 / particleCount + _animationPhase * 3;

      // Particle spirals inward
      final outerR = size.x * 0.9;
      final innerR = size.x * 0.15;
      final particleR = outerR - (outerR - innerR) * math.pow(particlePhase, 0.5);
      final spiralOffset = particlePhase * math.pi * 1.2;

      final px = center.dx + math.cos(particleAngle + spiralOffset) * particleR;
      final py = center.dy + math.sin(particleAngle + spiralOffset) * particleR;

      final particleAlpha = (1 - particlePhase) * vortexIntensity * 0.8;
      final particleSize = 1.5 + (1 - particlePhase) * 2.5;

      // Particle glow
      _vortexParticlePaint.color = vortexColorAccent.withOpacity(particleAlpha);
      canvas.drawCircle(Offset(px, py), particleSize, _vortexParticlePaint);

      // Bright core
      _vortexParticlePaint.color = Colors.white.withOpacity(particleAlpha * 0.7);
      canvas.drawCircle(Offset(px, py), particleSize * 0.4, _vortexParticlePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: ENERGY ARCS (Hawking radiation style)
    // ═══════════════════════════════════════════════════════════════════════
    if (!Tower.lowFx) {
      final arcCount = 6;
      for (int i = 0; i < arcCount; i++) {
        final arcAngle = i * math.pi * 2 / arcCount + _animationPhase * 4;
        final arcFlicker = math.sin(_animationPhase * 8 + i * 1.5) * 0.5 + 0.5;

        if (arcFlicker < 0.3) continue;

        final arcStart = horizonRadius * horizonPulse * 1.1;
        final arcEnd = arcStart + size.x * 0.15 * arcFlicker;

        _vortexPath.reset();
        for (int j = 0; j <= 6; j++) {
          final t = j / 6;
          final r = arcStart + (arcEnd - arcStart) * t;
          final wobble = math.sin(t * math.pi * 2 + _animationPhase * 10) * 4 * (1 - t);
          final perpAngle = arcAngle + math.pi / 2;
          final x = center.dx + math.cos(arcAngle) * r + math.cos(perpAngle) * wobble;
          final y = center.dy + math.sin(arcAngle) * r + math.sin(perpAngle) * wobble;

          if (j == 0) {
            _vortexPath.moveTo(x, y);
          } else {
            _vortexPath.lineTo(x, y);
          }
        }

        final arcAlpha = vortexIntensity * arcFlicker * 0.6;
        _vortexArcPaint.color = vortexColorAccent.withOpacity(arcAlpha);
        canvas.drawPath(_vortexPath, _vortexArcPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: GRAVITATIONAL LENS GLOW
    // ═══════════════════════════════════════════════════════════════════════
    final glowPulse = 0.6 + math.sin(_animationPhase * 3) * 0.2;
    final glowRadius = size.x * (0.5 + vortexIntensity * 0.3);

    _vortexGlowPaint.color = vortexColorInner.withOpacity(vortexIntensity * 0.15 * glowPulse);
    canvas.drawCircle(center, glowRadius, _vortexGlowPaint);

    _vortexGlowPaint.color = vortexColor.withOpacity(vortexIntensity * 0.1 * glowPulse);
    canvas.drawCircle(center, glowRadius * 1.3, _vortexGlowPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 8: SINGULARITY FLASH WHEN FIRING
    // ═══════════════════════════════════════════════════════════════════════
    if (_isFiring && _fireFlashTimer > 0) {
      final flashProgress = _fireFlashTimer / 0.15;
      final flashRadius = horizonRadius * (0.5 + (1 - flashProgress) * 1.5);
      final flashAlpha = flashProgress * 0.8;

      // Bright white flash
      _vortexGlowPaint.color = Colors.white.withOpacity(flashAlpha);
      canvas.drawCircle(center, flashRadius * 0.5, _vortexGlowPaint);

      // Colored ring expanding outward
      _vortexEventHorizonPaint.color = vortexColor.withOpacity(flashAlpha * 0.7);
      canvas.drawCircle(center, flashRadius, _vortexEventHorizonPaint);

      // Distortion rings
      for (int i = 0; i < 3; i++) {
        final ringT = flashProgress + i * 0.2;
        if (ringT > 1) continue;
        final ringR = horizonRadius + size.x * 0.4 * (1 - ringT);
        final ringA = ringT * 0.4;
        _vortexRingPaint.color = vortexColorAccent.withOpacity(ringA);
        canvas.drawCircle(center, ringR, _vortexRingPaint);
      }
    }
  }

  /// Renders orbital satellite effects for support towers (Resonance Siphon).
  /// Creates 4 satellites orbiting at different heights and speeds with energy tethers,
  /// data streams, pulse waves, and holographic details.
  void _renderOrbitalSatellites(Canvas canvas, Offset center) {
    final satelliteIntensity = 0.6 + _chargeLevel * 0.4 + (_isFiring ? 0.2 : 0);
    final primaryColor = color; // Resonance Siphon pink: 0xFFFF0066

    // Get secondary and tertiary colors for visual variety
    final hslColor = HSLColor.fromColor(primaryColor);
    final secondaryColor = hslColor.withHue((hslColor.hue + 60) % 360).toColor();
    final tertiaryColor = hslColor.withHue((hslColor.hue + 180) % 360).toColor();
    final accentColor = hslColor.withLightness((hslColor.lightness + 0.2).clamp(0.0, 1.0)).toColor();

    // Satellite configuration: 4 satellites at different orbital heights and speeds
    const int satelliteCount = 4;
    final List<double> orbitRadii = [
      size.x * 0.55,
      size.x * 0.70,
      size.x * 0.85,
      size.x * 1.0,
    ];
    final List<double> orbitSpeeds = [1.2, -0.8, 1.5, -1.0]; // Varied speeds, some reverse
    final List<double> verticalOffsets = [0.0, -3.0, 2.0, -1.5]; // Simulate height variation

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: ORBITAL PATH RINGS (dashed/dotted effect)
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < satelliteCount; i++) {
      final orbitRadius = orbitRadii[i];
      final orbitAlpha = satelliteIntensity * (0.15 + i * 0.05);
      final dashCount = 24 + i * 8;
      final dashAngleSpan = math.pi * 2 / dashCount;
      final dashLength = dashAngleSpan * 0.4;

      for (int d = 0; d < dashCount; d++) {
        final dashStart = d * dashAngleSpan + _animationPhase * orbitSpeeds[i] * 0.3;

        // Orbital ring with dashed segments
        _satellitePath.reset();
        _satellitePath.addArc(
          Rect.fromCircle(center: center, radius: orbitRadius),
          dashStart,
          dashLength,
        );

        final dashPulse = 0.7 + math.sin(_animationPhase * 4 + d * 0.3) * 0.3;
        _satelliteOrbitPaint.color = primaryColor.withOpacity(orbitAlpha * dashPulse);
        canvas.drawPath(_satellitePath, _satelliteOrbitPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: SATELLITE GLOW EFFECTS (drawn before bodies for depth)
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < satelliteCount; i++) {
      final orbitRadius = orbitRadii[i];
      final speed = orbitSpeeds[i];
      final satelliteAngle = _animationPhase * speed + i * math.pi / 2;
      final vertOffset = verticalOffsets[i] + math.sin(_animationPhase * 2 + i) * 2;

      final satX = center.dx + math.cos(satelliteAngle) * orbitRadius;
      final satY = center.dy + math.sin(satelliteAngle) * orbitRadius * 0.6 + vertOffset;
      final satCenter = Offset(satX, satY);

      // Outer glow halo
      final glowPulse = 0.6 + math.sin(_animationPhase * 5 + i * 1.5) * 0.4;
      final glowRadius = 8 + glowPulse * 4;
      _satelliteGlowPaint.color = primaryColor.withOpacity(satelliteIntensity * 0.3 * glowPulse);
      canvas.drawCircle(satCenter, glowRadius, _satelliteGlowPaint);

      // Inner core glow
      _satelliteCorePaint.color = accentColor.withOpacity(satelliteIntensity * 0.5 * glowPulse);
      canvas.drawCircle(satCenter, glowRadius * 0.5, _satelliteCorePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: ENERGY TETHERS CONNECTING SATELLITES TO TOWER
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < satelliteCount; i++) {
      final orbitRadius = orbitRadii[i];
      final speed = orbitSpeeds[i];
      final satelliteAngle = _animationPhase * speed + i * math.pi / 2;
      final vertOffset = verticalOffsets[i] + math.sin(_animationPhase * 2 + i) * 2;

      final satX = center.dx + math.cos(satelliteAngle) * orbitRadius;
      final satY = center.dy + math.sin(satelliteAngle) * orbitRadius * 0.6 + vertOffset;

      // Draw curved energy tether from center to satellite
      _satellitePath.reset();
      final controlOffset = orbitRadius * 0.3;
      final controlAngle = satelliteAngle + math.pi / 4;
      final ctrlX = center.dx + math.cos(controlAngle) * controlOffset;
      final ctrlY = center.dy + math.sin(controlAngle) * controlOffset * 0.6;

      _satellitePath.moveTo(center.dx, center.dy);
      _satellitePath.quadraticBezierTo(ctrlX, ctrlY, satX, satY);

      // Pulsing energy along tether
      final tetherPulse = 0.5 + math.sin(_animationPhase * 6 + i * 2) * 0.5;
      _satelliteTetherPaint.color = secondaryColor.withOpacity(satelliteIntensity * 0.35 * tetherPulse);
      canvas.drawPath(_satellitePath, _satelliteTetherPaint);

      // Brighter core tether line
      _satelliteTetherPaint.strokeWidth = 1;
      _satelliteTetherPaint.color = accentColor.withOpacity(satelliteIntensity * 0.5 * tetherPulse);
      canvas.drawPath(_satellitePath, _satelliteTetherPaint);
      _satelliteTetherPaint.strokeWidth = 1.5;

      // Energy particles along tether
      const particleCount = 3;
      for (int p = 0; p < particleCount; p++) {
        final t = ((_animationPhase * 3 + i + p * 0.33) % 1.0);
        // Simple lerp along the tether (approximation)
        final px = center.dx + (satX - center.dx) * t;
        final py = center.dy + (satY - center.dy) * t;
        final particleAlpha = (1 - (t - 0.5).abs() * 2) * satelliteIntensity * 0.6;

        _satelliteDataPaint.color = accentColor.withOpacity(particleAlpha);
        canvas.drawCircle(Offset(px, py), 2, _satelliteDataPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: SATELLITE BODIES (small geometric shapes)
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < satelliteCount; i++) {
      final orbitRadius = orbitRadii[i];
      final speed = orbitSpeeds[i];
      final satelliteAngle = _animationPhase * speed + i * math.pi / 2;
      final vertOffset = verticalOffsets[i] + math.sin(_animationPhase * 2 + i) * 2;

      final satX = center.dx + math.cos(satelliteAngle) * orbitRadius;
      final satY = center.dy + math.sin(satelliteAngle) * orbitRadius * 0.6 + vertOffset;
      final satCenter = Offset(satX, satY);

      // Satellite body - small diamond/rhombus shape
      final satSize = 4 + i * 0.5;
      final satRotation = _animationPhase * 3 + i * 0.8;

      _satellitePath.reset();
      for (int j = 0; j < 4; j++) {
        final vertexAngle = satRotation + j * math.pi / 2;
        final vx = satX + math.cos(vertexAngle) * satSize;
        final vy = satY + math.sin(vertexAngle) * satSize * 0.7;
        if (j == 0) {
          _satellitePath.moveTo(vx, vy);
        } else {
          _satellitePath.lineTo(vx, vy);
        }
      }
      _satellitePath.close();

      // Fill satellite body
      _satelliteBodyPaint.color = primaryColor.withOpacity(satelliteIntensity * 0.8);
      canvas.drawPath(_satellitePath, _satelliteBodyPaint);

      // Bright center dot
      _satelliteCorePaint.color = Colors.white.withOpacity(satelliteIntensity * 0.9);
      canvas.drawCircle(satCenter, 1.5, _satelliteCorePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: DATA STREAM PARTICLES BETWEEN SATELLITES
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < satelliteCount; i++) {
      final nextI = (i + 1) % satelliteCount;

      final orbitRadius1 = orbitRadii[i];
      final orbitRadius2 = orbitRadii[nextI];
      final speed1 = orbitSpeeds[i];
      final speed2 = orbitSpeeds[nextI];
      final angle1 = _animationPhase * speed1 + i * math.pi / 2;
      final angle2 = _animationPhase * speed2 + nextI * math.pi / 2;
      final vertOffset1 = verticalOffsets[i] + math.sin(_animationPhase * 2 + i) * 2;
      final vertOffset2 = verticalOffsets[nextI] + math.sin(_animationPhase * 2 + nextI) * 2;

      final sat1X = center.dx + math.cos(angle1) * orbitRadius1;
      final sat1Y = center.dy + math.sin(angle1) * orbitRadius1 * 0.6 + vertOffset1;
      final sat2X = center.dx + math.cos(angle2) * orbitRadius2;
      final sat2Y = center.dy + math.sin(angle2) * orbitRadius2 * 0.6 + vertOffset2;

      // Data stream particles traveling between adjacent satellites
      const streamParticles = 4;
      for (int p = 0; p < streamParticles; p++) {
        final t = ((_animationPhase * 4 + i * 0.5 + p * 0.25) % 1.0);
        final px = sat1X + (sat2X - sat1X) * t;
        final py = sat1Y + (sat2Y - sat1Y) * t;
        final particleAlpha = (1 - (t - 0.5).abs() * 2) * satelliteIntensity * 0.5;

        // Alternate colors for data variety
        final particleColor = (p % 2 == 0) ? tertiaryColor : secondaryColor;
        _satelliteStreamPaint.color = particleColor.withOpacity(particleAlpha);
        canvas.drawCircle(Offset(px, py), 1.5, _satelliteStreamPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: PULSE WAVES EMANATING FROM SATELLITES
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < satelliteCount; i++) {
      final orbitRadius = orbitRadii[i];
      final speed = orbitSpeeds[i];
      final satelliteAngle = _animationPhase * speed + i * math.pi / 2;
      final vertOffset = verticalOffsets[i] + math.sin(_animationPhase * 2 + i) * 2;

      final satX = center.dx + math.cos(satelliteAngle) * orbitRadius;
      final satY = center.dy + math.sin(satelliteAngle) * orbitRadius * 0.6 + vertOffset;
      final satCenter = Offset(satX, satY);

      // Expanding pulse wave (staggered timing per satellite)
      final pulsePhase = ((_animationPhase * 1.5 + i * 0.5) % 1.0);
      final pulseRadius = 3 + pulsePhase * 15;
      final pulseAlpha = (1 - pulsePhase) * satelliteIntensity * 0.4;

      if (pulseAlpha > 0.05) {
        _satellitePulsePaint.color = primaryColor.withOpacity(pulseAlpha);
        canvas.drawCircle(satCenter, pulseRadius, _satellitePulsePaint);

        // Secondary inner pulse wave
        final innerPulsePhase = ((pulsePhase + 0.3) % 1.0);
        final innerPulseRadius = 2 + innerPulsePhase * 10;
        final innerPulseAlpha = (1 - innerPulsePhase) * satelliteIntensity * 0.3;

        if (innerPulseAlpha > 0.05) {
          _satellitePulsePaint.color = secondaryColor.withOpacity(innerPulseAlpha);
          canvas.drawCircle(satCenter, innerPulseRadius, _satellitePulsePaint);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: HOLOGRAPHIC SATELLITE DETAILS
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < satelliteCount; i++) {
      final orbitRadius = orbitRadii[i];
      final speed = orbitSpeeds[i];
      final satelliteAngle = _animationPhase * speed + i * math.pi / 2;
      final vertOffset = verticalOffsets[i] + math.sin(_animationPhase * 2 + i) * 2;

      final satX = center.dx + math.cos(satelliteAngle) * orbitRadius;
      final satY = center.dy + math.sin(satelliteAngle) * orbitRadius * 0.6 + vertOffset;

      // Holographic antenna/sensor lines extending from satellite
      const antennaCount = 3;
      final satRotation = _animationPhase * 3 + i * 0.8;

      for (int a = 0; a < antennaCount; a++) {
        final antennaAngle = satRotation + a * math.pi * 2 / antennaCount + math.pi / 6;
        final antennaLength = 6 + math.sin(_animationPhase * 4 + i + a) * 2;
        final antennaEndX = satX + math.cos(antennaAngle) * antennaLength;
        final antennaEndY = satY + math.sin(antennaAngle) * antennaLength * 0.7;

        final holoFlicker = 0.5 + math.sin(_animationPhase * 8 + i * 2 + a) * 0.5;
        _satelliteHoloPaint.color = accentColor.withOpacity(satelliteIntensity * 0.5 * holoFlicker);
        canvas.drawLine(
          Offset(satX, satY),
          Offset(antennaEndX, antennaEndY),
          _satelliteHoloPaint,
        );

        // Small node at antenna tip
        _satelliteDataPaint.color = tertiaryColor.withOpacity(satelliteIntensity * 0.6 * holoFlicker);
        canvas.drawCircle(Offset(antennaEndX, antennaEndY), 1, _satelliteDataPaint);
      }

      // Holographic data readout arc around satellite
      final dataArcRadius = 7.0 + i;
      final dataArcStart = satRotation;
      const dataArcSweep = math.pi * 0.5;
      final dataFlicker = 0.6 + math.sin(_animationPhase * 6 + i * 3) * 0.4;

      _satellitePath.reset();
      _satellitePath.addArc(
        Rect.fromCircle(center: Offset(satX, satY), radius: dataArcRadius),
        dataArcStart,
        dataArcSweep,
      );

      _satelliteHoloPaint.color = secondaryColor.withOpacity(satelliteIntensity * 0.4 * dataFlicker);
      canvas.drawPath(_satellitePath, _satelliteHoloPaint);

      // Small holographic tick marks on the arc
      const tickCount = 4;
      for (int t = 0; t <= tickCount; t++) {
        final tickAngle = dataArcStart + (dataArcSweep / tickCount) * t;
        final tickInner = dataArcRadius - 1;
        final tickOuter = dataArcRadius + 2;
        final tickX1 = satX + math.cos(tickAngle) * tickInner;
        final tickY1 = satY + math.sin(tickAngle) * tickInner;
        final tickX2 = satX + math.cos(tickAngle) * tickOuter;
        final tickY2 = satY + math.sin(tickAngle) * tickOuter;

        _satelliteHoloPaint.color = accentColor.withOpacity(satelliteIntensity * 0.35 * dataFlicker);
        canvas.drawLine(Offset(tickX1, tickY1), Offset(tickX2, tickY2), _satelliteHoloPaint);
      }
    }
  }

  /// Renders a swarm of cyberpunk drones orbiting the Neural Disruptor tower.
  /// The drones move in coordinated patterns, occasionally breaking formation,
  /// with energy tethers, scanning beams, and data links connecting them.
  void _renderDroneSwarm(Canvas canvas, Offset center) {
    final droneIntensity = 0.7 + _chargeLevel * 0.3 + (_isFiring ? 0.15 : 0);
    final primaryColor = color; // Neural Disruptor green: 0xFF00FF00

    // Get secondary colors for visual variety (green/cyan scheme)
    final hslColor = HSLColor.fromColor(primaryColor);
    final cyanColor = hslColor.withHue(180).toColor(); // Cyan accent
    final brightGreen = hslColor.withLightness((hslColor.lightness + 0.2).clamp(0.0, 1.0)).toColor();
    final darkGreen = hslColor.withLightness((hslColor.lightness - 0.2).clamp(0.0, 1.0)).toColor();

    // Drone configuration: 7 drones at various orbital parameters
    const int droneCount = 7;
    final List<double> orbitRadii = [
      size.x * 0.50,
      size.x * 0.62,
      size.x * 0.75,
      size.x * 0.58,
      size.x * 0.88,
      size.x * 0.70,
      size.x * 0.95,
    ];
    final List<double> orbitSpeeds = [1.3, -0.9, 1.1, -1.4, 0.8, -1.2, 1.0];
    final List<double> heightOffsets = [0.0, -4.0, 2.5, -2.0, 3.5, -1.0, 1.5]; // Simulate 3D height
    final List<double> phaseOffsets = [0.0, 0.9, 1.8, 2.7, 3.6, 4.5, 5.4]; // Initial angle offsets

    // Calculate drone positions first (used by multiple layers)
    final List<Offset> dronePositions = [];
    for (int i = 0; i < droneCount; i++) {
      final orbitRadius = orbitRadii[i];
      final speed = orbitSpeeds[i];
      final droneAngle = _animationPhase * speed + phaseOffsets[i];
      final vertOffset = heightOffsets[i] + math.sin(_animationPhase * 2.5 + i * 0.7) * 3;

      // Formation break effect: occasionally drones drift from their orbit
      final breakPhase = math.sin(_animationPhase * 0.5 + i * 1.2);
      final breakAmount = breakPhase > 0.7 ? (breakPhase - 0.7) * 15 : 0.0;
      final breakAngle = _animationPhase * 0.3 + i;

      final droneX = center.dx + math.cos(droneAngle) * orbitRadius +
          math.cos(breakAngle) * breakAmount;
      final droneY = center.dy + math.sin(droneAngle) * orbitRadius * 0.55 +
          vertOffset + math.sin(breakAngle) * breakAmount * 0.5;

      dronePositions.add(Offset(droneX, droneY));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: DRONE BODY GLOW HALOS (rendered first for depth)
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < droneCount; i++) {
      final droneCenter = dronePositions[i];
      final glowPulse = 0.5 + math.sin(_animationPhase * 4 + i * 1.3) * 0.5;
      final glowRadius = 10 + glowPulse * 5;

      // Outer glow halo
      _droneBodyGlowPaint.color = primaryColor.withOpacity(droneIntensity * 0.25 * glowPulse);
      canvas.drawCircle(droneCenter, glowRadius, _droneBodyGlowPaint);

      // Inner cyan accent glow
      _droneBodyGlowPaint.color = cyanColor.withOpacity(droneIntensity * 0.15 * glowPulse);
      canvas.drawCircle(droneCenter, glowRadius * 0.6, _droneBodyGlowPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: DRONE ENGINE GLOW TRAILS
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < droneCount; i++) {
      final droneCenter = dronePositions[i];
      final speed = orbitSpeeds[i];
      final droneAngle = _animationPhase * speed + phaseOffsets[i];

      // Trail extends opposite to movement direction
      final trailAngle = droneAngle + math.pi + (speed > 0 ? 0 : math.pi);
      final trailLength = 12 + math.sin(_animationPhase * 3 + i) * 4;

      // Engine glow point
      final engineOffset = 3.0;
      final engineX = droneCenter.dx + math.cos(trailAngle + math.pi) * engineOffset;
      final engineY = droneCenter.dy + math.sin(trailAngle + math.pi) * engineOffset * 0.55;
      final engineGlow = 0.6 + math.sin(_animationPhase * 8 + i * 2) * 0.4;

      _droneEngineGlowPaint.color = cyanColor.withOpacity(droneIntensity * 0.6 * engineGlow);
      canvas.drawCircle(Offset(engineX, engineY), 4, _droneEngineGlowPaint);

      // Trail line
      final trailEndX = droneCenter.dx + math.cos(trailAngle) * trailLength;
      final trailEndY = droneCenter.dy + math.sin(trailAngle) * trailLength * 0.55;

      _droneEngineTrailPaint.color = cyanColor.withOpacity(droneIntensity * 0.4 * engineGlow);
      canvas.drawLine(
        Offset(engineX, engineY),
        Offset(trailEndX, trailEndY),
        _droneEngineTrailPaint,
      );

      // Trail particles
      for (int p = 0; p < 3; p++) {
        final t = (p + 1) / 4.0;
        final px = engineX + (trailEndX - engineX) * t;
        final py = engineY + (trailEndY - engineY) * t;
        final particleAlpha = (1 - t) * droneIntensity * 0.5 * engineGlow;

        _droneEngineGlowPaint.color = primaryColor.withOpacity(particleAlpha);
        canvas.drawCircle(Offset(px, py), 2 * (1 - t), _droneEngineGlowPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: ENERGY TETHERS BETWEEN DRONES AND TOWER
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < droneCount; i++) {
      final droneCenter = dronePositions[i];
      final tetherPulse = 0.4 + math.sin(_animationPhase * 5 + i * 1.5) * 0.6;

      // Curved bezier tether from center to drone
      _dronePath.reset();
      final controlOffset = orbitRadii[i] * 0.4;
      final controlAngle = math.atan2(droneCenter.dy - center.dy, droneCenter.dx - center.dx) + math.pi / 3;
      final ctrlX = center.dx + math.cos(controlAngle) * controlOffset;
      final ctrlY = center.dy + math.sin(controlAngle) * controlOffset * 0.55;

      _dronePath.moveTo(center.dx, center.dy);
      _dronePath.quadraticBezierTo(ctrlX, ctrlY, droneCenter.dx, droneCenter.dy);

      // Outer glow tether
      _droneTetherPaint.color = primaryColor.withOpacity(droneIntensity * 0.25 * tetherPulse);
      canvas.drawPath(_dronePath, _droneTetherPaint);

      // Core bright tether line
      _droneTetherCorePaint.color = brightGreen.withOpacity(droneIntensity * 0.4 * tetherPulse);
      canvas.drawPath(_dronePath, _droneTetherCorePaint);

      // Energy pulses along tether
      for (int p = 0; p < 4; p++) {
        final t = ((_animationPhase * 4 + i * 0.4 + p * 0.25) % 1.0);
        // Approximate position along the quadratic bezier
        final oneMinusT = 1 - t;
        final px = oneMinusT * oneMinusT * center.dx + 2 * oneMinusT * t * ctrlX + t * t * droneCenter.dx;
        final py = oneMinusT * oneMinusT * center.dy + 2 * oneMinusT * t * ctrlY + t * t * droneCenter.dy;
        final pulseAlpha = (1 - (t - 0.5).abs() * 2) * droneIntensity * 0.6 * tetherPulse;

        _droneDataParticlePaint.color = cyanColor.withOpacity(pulseAlpha);
        canvas.drawCircle(Offset(px, py), 2.5, _droneDataParticlePaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: SCANNING BEAMS FROM EACH DRONE
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < droneCount; i++) {
      final droneCenter = dronePositions[i];
      final scanPulse = 0.3 + math.sin(_animationPhase * 3 + i * 0.8) * 0.7;

      // Only render scan beam when pulse is strong enough
      if (scanPulse > 0.5) {
        // Scan beam pointing downward with sweep
        final sweepAngle = math.sin(_animationPhase * 2 + i) * 0.4;
        final beamAngle = math.pi / 2 + sweepAngle; // Pointing down with sweep
        final beamLength = 20 + scanPulse * 10;
        final beamWidth = 8 + scanPulse * 4;

        final beamEndX = droneCenter.dx + math.cos(beamAngle) * beamLength;
        final beamEndY = droneCenter.dy + math.sin(beamAngle) * beamLength;

        // Triangular scan beam (cone shape)
        _dronePath.reset();
        _dronePath.moveTo(droneCenter.dx, droneCenter.dy);
        _dronePath.lineTo(
          beamEndX - math.cos(beamAngle + math.pi / 2) * beamWidth / 2,
          beamEndY - math.sin(beamAngle + math.pi / 2) * beamWidth / 2,
        );
        _dronePath.lineTo(
          beamEndX + math.cos(beamAngle + math.pi / 2) * beamWidth / 2,
          beamEndY + math.sin(beamAngle + math.pi / 2) * beamWidth / 2,
        );
        _dronePath.close();

        // Scan beam fill with gradient-like opacity
        _droneScanBeamPaint.color = primaryColor.withOpacity(droneIntensity * 0.15 * (scanPulse - 0.5) * 2);
        canvas.drawPath(_dronePath, _droneScanBeamPaint);

        // Scan line at the bottom of the beam
        _droneScanLinePaint.color = cyanColor.withOpacity(droneIntensity * 0.5 * (scanPulse - 0.5) * 2);
        canvas.drawLine(
          Offset(
            beamEndX - math.cos(beamAngle + math.pi / 2) * beamWidth / 2,
            beamEndY - math.sin(beamAngle + math.pi / 2) * beamWidth / 2,
          ),
          Offset(
            beamEndX + math.cos(beamAngle + math.pi / 2) * beamWidth / 2,
            beamEndY + math.sin(beamAngle + math.pi / 2) * beamWidth / 2,
          ),
          _droneScanLinePaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: DATA LINK PARTICLES BETWEEN DRONES
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < droneCount; i++) {
      // Connect to next drone in sequence (creates network pattern)
      final nextI = (i + 1) % droneCount;
      final drone1 = dronePositions[i];
      final drone2 = dronePositions[nextI];

      // Distance check - only link nearby drones
      final dx = drone2.dx - drone1.dx;
      final dy = drone2.dy - drone1.dy;
      final distance = math.sqrt(dx * dx + dy * dy);

      if (distance < size.x * 0.8) {
        // Faint connection line
        final linkAlpha = (1 - distance / (size.x * 0.8)) * droneIntensity * 0.2;
        _droneDataLinkPaint.color = primaryColor.withOpacity(linkAlpha);
        canvas.drawLine(drone1, drone2, _droneDataLinkPaint);

        // Data particles traveling along link
        for (int p = 0; p < 3; p++) {
          final t = ((_animationPhase * 5 + i * 0.6 + p * 0.33) % 1.0);
          final px = drone1.dx + dx * t;
          final py = drone1.dy + dy * t;
          final particleAlpha = (1 - (t - 0.5).abs() * 2) * droneIntensity * 0.5;

          final particleColor = (p % 2 == 0) ? cyanColor : primaryColor;
          _droneDataParticlePaint.color = particleColor.withOpacity(particleAlpha);
          canvas.drawCircle(Offset(px, py), 2, _droneDataParticlePaint);
        }
      }
    }

    // Also connect alternate drones for more complex network
    for (int i = 0; i < droneCount; i += 2) {
      final nextI = (i + 2) % droneCount;
      final drone1 = dronePositions[i];
      final drone2 = dronePositions[nextI];

      final dx = drone2.dx - drone1.dx;
      final dy = drone2.dy - drone1.dy;
      final distance = math.sqrt(dx * dx + dy * dy);

      if (distance < size.x * 1.0) {
        final linkFlicker = 0.3 + math.sin(_animationPhase * 6 + i) * 0.7;
        if (linkFlicker > 0.5) {
          final linkAlpha = (1 - distance / (size.x * 1.0)) * droneIntensity * 0.15 * (linkFlicker - 0.5) * 2;
          _droneDataLinkPaint.color = cyanColor.withOpacity(linkAlpha);
          canvas.drawLine(drone1, drone2, _droneDataLinkPaint);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: DRONE FORMATION PATTERN INDICATORS
    // ═══════════════════════════════════════════════════════════════════════
    // Draw faint hexagonal formation guide around the swarm
    final formationPulse = 0.3 + math.sin(_animationPhase * 1.5) * 0.2;
    final formationRadius = size.x * 0.85;

    // Dashed hexagon formation ring
    for (int i = 0; i < 6; i++) {
      final startAngle = i * math.pi / 3 + _animationPhase * 0.2;
      final endAngle = startAngle + math.pi / 6; // Half segment (dashed effect)

      _dronePath.reset();
      _dronePath.addArc(
        Rect.fromCircle(center: center, radius: formationRadius),
        startAngle,
        math.pi / 6,
      );

      _droneFormationPaint.color = primaryColor.withOpacity(droneIntensity * formationPulse * 0.3);
      canvas.drawPath(_dronePath, _droneFormationPaint);
    }

    // Corner markers at formation vertices
    for (int i = 0; i < 6; i++) {
      final markerAngle = i * math.pi / 3 + _animationPhase * 0.2;
      final markerX = center.dx + math.cos(markerAngle) * formationRadius;
      final markerY = center.dy + math.sin(markerAngle) * formationRadius * 0.6;

      // Small diamond marker
      _dronePath.reset();
      final markerSize = 3.0;
      _dronePath.moveTo(markerX, markerY - markerSize);
      _dronePath.lineTo(markerX + markerSize, markerY);
      _dronePath.lineTo(markerX, markerY + markerSize);
      _dronePath.lineTo(markerX - markerSize, markerY);
      _dronePath.close();

      _droneFormationPaint.color = cyanColor.withOpacity(droneIntensity * formationPulse * 0.5);
      canvas.drawPath(_dronePath, _droneFormationPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: DRONE BODIES WITH HIGHLIGHTS AND DETAILS
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < droneCount; i++) {
      final droneCenter = dronePositions[i];
      final speed = orbitSpeeds[i];
      final droneAngle = _animationPhase * speed + phaseOffsets[i];

      // Drone body size varies slightly
      final bodySize = 5.0 + i * 0.3;
      final bodyRotation = droneAngle * 2 + _animationPhase; // Drone spins as it moves

      // Main drone body (hexagonal shape for cyberpunk aesthetic)
      _dronePath.reset();
      for (int v = 0; v < 6; v++) {
        final vertexAngle = bodyRotation + v * math.pi / 3;
        final vx = droneCenter.dx + math.cos(vertexAngle) * bodySize;
        final vy = droneCenter.dy + math.sin(vertexAngle) * bodySize * 0.7;
        if (v == 0) {
          _dronePath.moveTo(vx, vy);
        } else {
          _dronePath.lineTo(vx, vy);
        }
      }
      _dronePath.close();

      // Drone body fill
      _droneBodyPaint.color = darkGreen.withOpacity(droneIntensity * 0.8);
      canvas.drawPath(_dronePath, _droneBodyPaint);

      // Body edge highlight
      _droneDetailPaint.color = primaryColor.withOpacity(droneIntensity * 0.9);
      canvas.drawPath(_dronePath, _droneDetailPaint);

      // Center core light
      final corePulse = 0.6 + math.sin(_animationPhase * 6 + i * 2) * 0.4;
      _droneHighlightPaint.color = Colors.white.withOpacity(droneIntensity * corePulse * 0.9);
      canvas.drawCircle(droneCenter, 2, _droneHighlightPaint);

      // Secondary cyan accent light
      final accentAngle = bodyRotation + math.pi / 6;
      final accentX = droneCenter.dx + math.cos(accentAngle) * bodySize * 0.5;
      final accentY = droneCenter.dy + math.sin(accentAngle) * bodySize * 0.35;
      _droneHighlightPaint.color = cyanColor.withOpacity(droneIntensity * corePulse * 0.7);
      canvas.drawCircle(Offset(accentX, accentY), 1.5, _droneHighlightPaint);

      // Antenna/sensor lines extending from drone
      for (int a = 0; a < 2; a++) {
        final antennaAngle = bodyRotation + (a == 0 ? math.pi / 4 : -math.pi / 4);
        final antennaLength = 4 + math.sin(_animationPhase * 5 + i + a) * 1.5;
        final antennaEndX = droneCenter.dx + math.cos(antennaAngle) * (bodySize + antennaLength);
        final antennaEndY = droneCenter.dy + math.sin(antennaAngle) * (bodySize + antennaLength) * 0.7;

        _droneDetailPaint.color = cyanColor.withOpacity(droneIntensity * 0.6);
        canvas.drawLine(
          Offset(
            droneCenter.dx + math.cos(antennaAngle) * bodySize,
            droneCenter.dy + math.sin(antennaAngle) * bodySize * 0.7,
          ),
          Offset(antennaEndX, antennaEndY),
          _droneDetailPaint,
        );

        // Antenna tip glow
        final tipPulse = 0.4 + math.sin(_animationPhase * 8 + i * 2 + a * 3) * 0.6;
        _droneHighlightPaint.color = primaryColor.withOpacity(droneIntensity * tipPulse * 0.8);
        canvas.drawCircle(Offset(antennaEndX, antennaEndY), 1, _droneHighlightPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7.5: CENTRAL PULSE WAVE (coordination signal)
    // ═══════════════════════════════════════════════════════════════════════
    // Expanding pulse wave from tower center to indicate drone coordination
    final pulsePhase = (_animationPhase * 1.2) % 1.0;
    final pulseRadius = size.x * (0.2 + pulsePhase * 0.8);
    final pulseAlpha = (1 - pulsePhase) * droneIntensity * 0.25;

    if (pulseAlpha > 0.02) {
      _dronePulsePaint.color = primaryColor.withOpacity(pulseAlpha);
      canvas.drawCircle(center, pulseRadius, _dronePulsePaint);

      // Secondary inner pulse (offset timing)
      final innerPulsePhase = ((_animationPhase * 1.2 + 0.5) % 1.0);
      final innerPulseRadius = size.x * (0.2 + innerPulsePhase * 0.8);
      final innerPulseAlpha = (1 - innerPulsePhase) * droneIntensity * 0.15;

      if (innerPulseAlpha > 0.02) {
        _dronePulsePaint.color = cyanColor.withOpacity(innerPulseAlpha);
        canvas.drawCircle(center, innerPulseRadius, _dronePulsePaint);
      }
    }
  }

  /// Renders a radar sweep effect for detection-type towers (neuralDisruptor, phaseMage).
  /// Creates a rotating radar display with sweep beam, range circles, enemy blips,
  /// and data readouts for a cyberpunk detection aesthetic.
  void _renderRadarSweep(Canvas canvas, Offset center) {
    final radarIntensity = 0.6 + _chargeLevel * 0.2 + (_isFiring ? 0.2 : 0);
    final primaryColor = color;

    // Get secondary colors for visual variety
    final hslColor = HSLColor.fromColor(primaryColor);
    final accentColor = hslColor.withHue((hslColor.hue + 120) % 360).toColor(); // Complementary accent
    final brightColor = hslColor.withLightness((hslColor.lightness + 0.3).clamp(0.0, 1.0)).toColor();
    final dimColor = hslColor.withLightness((hslColor.lightness - 0.2).clamp(0.0, 1.0)).toColor();

    // Radar dimensions
    final radarRadius = size.x * 0.75; // Outer radar range
    final innerRadius = size.x * 0.15; // Inner exclusion zone (tower body)
    final sweepAngle = _radarSweepAngle;
    final sweepWidth = math.pi / 6; // 30 degree sweep beam width

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: RADAR DISH/ANTENNA ON TOWER
    // ═══════════════════════════════════════════════════════════════════════
    // Rotating dish indicator at tower center
    final dishSize = size.x * 0.12;
    final dishAngle = sweepAngle;

    // Dish body glow
    _radarDishGlowPaint.color = primaryColor.withOpacity(radarIntensity * 0.3);
    canvas.drawCircle(center, dishSize * 1.5, _radarDishGlowPaint);

    // Dish body fill
    _radarDishPaint.color = dimColor.withOpacity(radarIntensity * 0.6);
    canvas.drawCircle(center, dishSize, _radarDishPaint);

    // Dish direction indicator (pointing in sweep direction)
    _radarPath.reset();
    final dishTipX = center.dx + math.cos(dishAngle) * dishSize * 1.8;
    final dishTipY = center.dy + math.sin(dishAngle) * dishSize * 1.8;
    final dishBaseLeftX = center.dx + math.cos(dishAngle + math.pi * 0.8) * dishSize * 0.6;
    final dishBaseLeftY = center.dy + math.sin(dishAngle + math.pi * 0.8) * dishSize * 0.6;
    final dishBaseRightX = center.dx + math.cos(dishAngle - math.pi * 0.8) * dishSize * 0.6;
    final dishBaseRightY = center.dy + math.sin(dishAngle - math.pi * 0.8) * dishSize * 0.6;

    _radarPath.moveTo(dishTipX, dishTipY);
    _radarPath.lineTo(dishBaseLeftX, dishBaseLeftY);
    _radarPath.lineTo(dishBaseRightX, dishBaseRightY);
    _radarPath.close();

    _radarDishPaint.color = primaryColor.withOpacity(radarIntensity * 0.7);
    canvas.drawPath(_radarPath, _radarDishPaint);

    // Dish stroke outline
    _radarDishStrokePaint.color = brightColor.withOpacity(radarIntensity * 0.9);
    canvas.drawPath(_radarPath, _radarDishStrokePaint);

    // Center core light
    final corePulse = 0.7 + math.sin(_animationPhase * 6) * 0.3;
    _radarDishPaint.color = brightColor.withOpacity(radarIntensity * corePulse);
    canvas.drawCircle(center, dishSize * 0.4, _radarDishPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: ROTATING SWEEP BEAM (PIE SLICE SHAPE)
    // ═══════════════════════════════════════════════════════════════════════
    // Main sweep beam with gradient-like layered opacity
    _tempRect = Rect.fromCircle(center: center, radius: radarRadius);

    // Outer sweep glow (widest, dimmest)
    _radarSweepGlowPaint.color = primaryColor.withOpacity(radarIntensity * 0.15);
    canvas.drawArc(_tempRect, sweepAngle - sweepWidth * 0.5, sweepWidth, true, _radarSweepGlowPaint);

    // Mid sweep layer
    _radarSweepPaint.color = primaryColor.withOpacity(radarIntensity * 0.25);
    _tempRect = Rect.fromCircle(center: center, radius: radarRadius * 0.9);
    canvas.drawArc(_tempRect, sweepAngle - sweepWidth * 0.4, sweepWidth * 0.8, true, _radarSweepPaint);

    // Inner sweep core (brightest)
    _radarSweepPaint.color = brightColor.withOpacity(radarIntensity * 0.4);
    _tempRect = Rect.fromCircle(center: center, radius: radarRadius * 0.75);
    canvas.drawArc(_tempRect, sweepAngle - sweepWidth * 0.3, sweepWidth * 0.6, true, _radarSweepPaint);

    // Leading edge beam line (bright)
    final beamEndX = center.dx + math.cos(sweepAngle) * radarRadius;
    final beamEndY = center.dy + math.sin(sweepAngle) * radarRadius;
    _radarDishStrokePaint.color = brightColor.withOpacity(radarIntensity * 0.8);
    canvas.drawLine(center, Offset(beamEndX, beamEndY), _radarDishStrokePaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: CONCENTRIC RANGE CIRCLES
    // ═══════════════════════════════════════════════════════════════════════
    const int ringCount = 4;
    for (int i = 1; i <= ringCount; i++) {
      final ringRadius = innerRadius + (radarRadius - innerRadius) * (i / ringCount);
      final ringPulse = 0.5 + math.sin(_animationPhase * 2 + i * 0.5) * 0.2;

      // Ring glow (subtle)
      _radarRingGlowPaint.color = primaryColor.withOpacity(radarIntensity * 0.1 * ringPulse);
      canvas.drawCircle(center, ringRadius, _radarRingGlowPaint);

      // Ring line
      _radarRingPaint.color = primaryColor.withOpacity(radarIntensity * 0.3 * ringPulse);
      canvas.drawCircle(center, ringRadius, _radarRingPaint);

      // Range markers at cardinal directions
      for (int j = 0; j < 8; j++) {
        final markerAngle = j * math.pi / 4;
        final markerInnerX = center.dx + math.cos(markerAngle) * (ringRadius - 3);
        final markerInnerY = center.dy + math.sin(markerAngle) * (ringRadius - 3);
        final markerOuterX = center.dx + math.cos(markerAngle) * (ringRadius + 3);
        final markerOuterY = center.dy + math.sin(markerAngle) * (ringRadius + 3);

        _radarGridPaint.color = accentColor.withOpacity(radarIntensity * 0.4);
        canvas.drawLine(
          Offset(markerInnerX, markerInnerY),
          Offset(markerOuterX, markerOuterY),
          _radarGridPaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: DETECTED ENEMY BLIPS
    // ═══════════════════════════════════════════════════════════════════════
    // Check enemies in range and create/update blips when sweep passes them
    for (final enemy in _candidateEnemies) {
      if (!enemy.isAlive) continue;

      final enemyOffset = Offset(
        enemy.position.x - position.x,
        enemy.position.y - position.y,
      );
      final distanceToEnemy = (enemyOffset - center).distance;

      // Only show blips within radar range
      if (distanceToEnemy > radarRadius || distanceToEnemy < innerRadius) continue;

      // Calculate enemy angle relative to tower
      final enemyAngle = math.atan2(enemyOffset.dy - center.dy, enemyOffset.dx - center.dx);
      final normalizedEnemyAngle = enemyAngle < 0 ? enemyAngle + math.pi * 2 : enemyAngle;
      final normalizedSweepAngle = sweepAngle % (math.pi * 2);

      // Check if sweep just passed this enemy (within sweep width)
      var angleDiff = (normalizedSweepAngle - normalizedEnemyAngle).abs();
      if (angleDiff > math.pi) angleDiff = math.pi * 2 - angleDiff;

      // Find or create blip for this enemy
      _RadarBlip? blip;
      for (final b in _radarBlips) {
        if (b.enemy == enemy) {
          blip = b;
          break;
        }
      }

      // Ping the blip when sweep passes
      if (angleDiff < sweepWidth * 0.5) {
        if (blip == null && _radarBlips.length < _maxRadarBlips) {
          blip = _RadarBlip(enemy: enemy, lastPingTime: 0, pingIntensity: 1.0);
          _radarBlips.add(blip);
        } else if (blip != null) {
          blip.pingIntensity = 1.0;
          blip.lastPingTime = 0;
        }
      }

      // Render the blip if it exists
      if (blip != null && blip.pingIntensity > 0.05) {
        final blipAlpha = blip.pingIntensity * radarIntensity;
        final blipSize = 4 + blip.pingIntensity * 3;

        // Blip outer pulse (fading ring)
        final pulseSize = blipSize * (1 + (1 - blip.pingIntensity) * 2);
        _radarBlipPulsePaint.color = accentColor.withOpacity(blipAlpha * 0.3);
        canvas.drawCircle(enemyOffset, pulseSize, _radarBlipPulsePaint);

        // Blip glow
        _radarBlipPaint.color = primaryColor.withOpacity(blipAlpha * 0.6);
        canvas.drawCircle(enemyOffset, blipSize * 1.5, _radarBlipPaint);

        // Blip core
        _radarBlipCorePaint.color = brightColor.withOpacity(blipAlpha);
        canvas.drawCircle(enemyOffset, blipSize * 0.5, _radarBlipCorePaint);

        // Diamond shape indicator around blip
        if (blip.pingIntensity > 0.5) {
          final diamondSize = blipSize * 2;
          _radarPath.reset();
          _radarPath.moveTo(enemyOffset.dx, enemyOffset.dy - diamondSize);
          _radarPath.lineTo(enemyOffset.dx + diamondSize, enemyOffset.dy);
          _radarPath.lineTo(enemyOffset.dx, enemyOffset.dy + diamondSize);
          _radarPath.lineTo(enemyOffset.dx - diamondSize, enemyOffset.dy);
          _radarPath.close();

          _radarRingPaint.color = accentColor.withOpacity(blipAlpha * 0.6);
          canvas.drawPath(_radarPath, _radarRingPaint);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: SWEEP TRAIL (FADING ARC BEHIND SWEEP LINE)
    // ═══════════════════════════════════════════════════════════════════════
    // Multiple trail arcs with decreasing opacity
    const int trailSegments = 6;
    for (int i = 1; i <= trailSegments; i++) {
      final trailAngleOffset = i * (math.pi / 12); // Each segment is 15 degrees behind
      final trailStartAngle = sweepAngle - trailAngleOffset - (math.pi / 24);
      final trailAlpha = radarIntensity * 0.15 * (1 - i / (trailSegments + 1));

      if (trailAlpha > 0.01) {
        _radarTrailPaint.color = primaryColor.withOpacity(trailAlpha);
        final trailRadius = radarRadius * (0.95 - i * 0.03);
        _tempRect = Rect.fromCircle(center: center, radius: trailRadius);
        canvas.drawArc(_tempRect, trailStartAngle, math.pi / 24, true, _radarTrailPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: SCAN LINE GRID PATTERN
    // ═══════════════════════════════════════════════════════════════════════
    // Radial grid lines (spokes)
    const int spokeCount = 12;
    for (int i = 0; i < spokeCount; i++) {
      final spokeAngle = i * (math.pi * 2 / spokeCount);
      final spokeInnerX = center.dx + math.cos(spokeAngle) * innerRadius;
      final spokeInnerY = center.dy + math.sin(spokeAngle) * innerRadius;
      final spokeOuterX = center.dx + math.cos(spokeAngle) * radarRadius;
      final spokeOuterY = center.dy + math.sin(spokeAngle) * radarRadius;

      // Spoke line with varying intensity based on proximity to sweep
      var spokeDiff = ((sweepAngle % (math.pi * 2)) - spokeAngle).abs();
      if (spokeDiff > math.pi) spokeDiff = math.pi * 2 - spokeDiff;
      final spokeHighlight = spokeDiff < sweepWidth ? (1 - spokeDiff / sweepWidth) * 0.5 : 0.0;

      _radarGridPaint.color = primaryColor.withOpacity(radarIntensity * (0.15 + spokeHighlight));
      canvas.drawLine(
        Offset(spokeInnerX, spokeInnerY),
        Offset(spokeOuterX, spokeOuterY),
        _radarGridPaint,
      );

      // Grid nodes at ring intersections
      for (int j = 1; j <= ringCount; j++) {
        final nodeRadius = innerRadius + (radarRadius - innerRadius) * (j / ringCount);
        final nodeX = center.dx + math.cos(spokeAngle) * nodeRadius;
        final nodeY = center.dy + math.sin(spokeAngle) * nodeRadius;

        final nodePulse = 0.3 + math.sin(_animationPhase * 3 + i + j) * 0.2 + spokeHighlight;
        _radarGridNodePaint.color = accentColor.withOpacity(radarIntensity * nodePulse * 0.5);
        canvas.drawCircle(Offset(nodeX, nodeY), 1.5, _radarGridNodePaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: DATA READOUT NEAR DETECTED ENEMIES
    // ═══════════════════════════════════════════════════════════════════════
    for (final blip in _radarBlips) {
      if (!blip.enemy.isAlive || blip.pingIntensity < 0.3) continue;

      final enemyOffset = Offset(
        blip.enemy.position.x - position.x,
        blip.enemy.position.y - position.y,
      );
      final distanceToEnemy = (enemyOffset - center).distance;

      if (distanceToEnemy > radarRadius) continue;

      final dataAlpha = blip.pingIntensity * radarIntensity * 0.8;

      // Data bracket around enemy position
      final bracketSize = 12.0;
      final bracketOffset = Offset(enemyOffset.dx + bracketSize * 1.5, enemyOffset.dy - bracketSize);

      // Bracket corners
      _radarDataLinePaint.color = accentColor.withOpacity(dataAlpha);

      // Top-left bracket
      canvas.drawLine(
        Offset(bracketOffset.dx, bracketOffset.dy),
        Offset(bracketOffset.dx + 6, bracketOffset.dy),
        _radarDataLinePaint,
      );
      canvas.drawLine(
        Offset(bracketOffset.dx, bracketOffset.dy),
        Offset(bracketOffset.dx, bracketOffset.dy + 4),
        _radarDataLinePaint,
      );

      // Bottom-right bracket
      canvas.drawLine(
        Offset(bracketOffset.dx + 25, bracketOffset.dy + 12),
        Offset(bracketOffset.dx + 19, bracketOffset.dy + 12),
        _radarDataLinePaint,
      );
      canvas.drawLine(
        Offset(bracketOffset.dx + 25, bracketOffset.dy + 12),
        Offset(bracketOffset.dx + 25, bracketOffset.dy + 8),
        _radarDataLinePaint,
      );

      // Connection line from blip to data readout
      _radarDataLinePaint.color = primaryColor.withOpacity(dataAlpha * 0.5);
      canvas.drawLine(enemyOffset, Offset(bracketOffset.dx, bracketOffset.dy + 6), _radarDataLinePaint);

      // Simulated data bars (health/threat indicator)
      final barCount = 4;
      final barWidth = 4.0;
      final barMaxHeight = 8.0;
      for (int i = 0; i < barCount; i++) {
        final barX = bracketOffset.dx + 4 + i * (barWidth + 1);
        final barHeight = barMaxHeight * (0.3 + _radarRandom.nextDouble() * 0.7 * blip.pingIntensity);

        // Bar glow
        _radarDataGlowPaint.color = primaryColor.withOpacity(dataAlpha * 0.4);
        canvas.drawRect(
          Rect.fromLTWH(barX - 1, bracketOffset.dy + 2, barWidth + 2, barHeight + 2),
          _radarDataGlowPaint,
        );

        // Bar fill
        _radarDataPaint.color = (i == 0 ? accentColor : primaryColor).withOpacity(dataAlpha * 0.8);
        canvas.drawRect(
          Rect.fromLTWH(barX, bracketOffset.dy + 3, barWidth, barHeight),
          _radarDataPaint,
        );
      }

      // Target lock indicator (flashing dot)
      if (blip.pingIntensity > 0.7) {
        final lockPulse = math.sin(_animationPhase * 10) * 0.5 + 0.5;
        _radarDataPaint.color = accentColor.withOpacity(dataAlpha * lockPulse);
        canvas.drawCircle(Offset(bracketOffset.dx + 22, bracketOffset.dy + 3), 2, _radarDataPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // OUTER BOUNDARY GLOW
    // ═══════════════════════════════════════════════════════════════════════
    // Subtle outer boundary with scanning effect
    final boundaryPulse = 0.3 + math.sin(_animationPhase * 1.5) * 0.1;
    _radarRingGlowPaint.color = primaryColor.withOpacity(radarIntensity * boundaryPulse * 0.2);
    canvas.drawCircle(center, radarRadius, _radarRingGlowPaint);

    _radarRingPaint.color = primaryColor.withOpacity(radarIntensity * boundaryPulse * 0.4);
    canvas.drawCircle(center, radarRadius, _radarRingPaint);
  }

  void _renderChargeIndicator(Canvas canvas, Offset center) {
    if (_chargeLevel <= 0) return;

    final sweepAngle = math.pi * 2 * _chargeLevel;

    // Get secondary colors for visual variety
    final hslColor = HSLColor.fromColor(color);
    final secondaryColor = hslColor.withHue((hslColor.hue + 40) % 360).toColor();
    final tertiaryColor = hslColor.withHue((hslColor.hue + 80) % 360).toColor();

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: DEEP OUTER ABSORPTION GLOW
    // ═══════════════════════════════════════════════════════════════════════
    if (!Tower.lowFx) {
      final outerGlowRadius = size.x * (0.8 + _chargeLevel * 0.3);
      final outerGlowPulse = math.sin(_animationPhase * 4) * 0.15 + 0.85;
      _absorptionOuterGlowPaint.color = color.withOpacity(_chargeLevel * 0.2 * outerGlowPulse);
      canvas.drawCircle(center, outerGlowRadius, _absorptionOuterGlowPaint);

      // Secondary glow layer
      _absorptionOuterGlowPaint.color = secondaryColor.withOpacity(_chargeLevel * 0.1);
      canvas.drawCircle(center, outerGlowRadius * 0.7, _absorptionOuterGlowPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: ENERGY PARTICLES FLYING INWARD
    // ═══════════════════════════════════════════════════════════════════════
    final particleCount = (8 * _chargeLevel).ceil();
    for (int i = 0; i < particleCount; i++) {
      // Each particle has its own phase based on time and index
      final particlePhase = _animationPhase * 3 + i * (math.pi * 2 / particleCount);
      final normalizedPhase = (particlePhase % (math.pi * 2)) / (math.pi * 2);

      // Particle spirals inward as charge increases
      final maxRadius = size.x * 0.8;
      final minRadius = size.x * 0.1;
      final particleRadius = maxRadius - (maxRadius - minRadius) * normalizedPhase;

      // Rotate around center
      final particleAngle = _animationPhase * 2 + i * (math.pi * 2 / particleCount) + normalizedPhase * math.pi;
      final px = center.dx + math.cos(particleAngle) * particleRadius;
      final py = center.dy + math.sin(particleAngle) * particleRadius;

      final particleAlpha = _chargeLevel * (0.8 - normalizedPhase * 0.5);
      final particleSize = 2 + (1 - normalizedPhase) * 3;

      // Particle glow
      if (!Tower.lowFx) {
        _absorptionSparkPaint.color = color.withOpacity(particleAlpha * 0.5);
        canvas.drawCircle(Offset(px, py), particleSize * 2, _absorptionSparkPaint);
      }

      // Particle core with color variation
      final particleColor = Color.lerp(color, secondaryColor, normalizedPhase)!;
      _absorptionParticlePaint.color = particleColor.withOpacity(particleAlpha);
      canvas.drawCircle(Offset(px, py), particleSize, _absorptionParticlePaint);

      // Trail effect for each particle
      if (!Tower.lowFx && particleAlpha > 0.3) {
        _absorptionPath1.reset();
        _absorptionPath1.moveTo(px, py);

        // Draw trail pointing outward (where particle came from)
        for (int t = 1; t <= 4; t++) {
          final trailProgress = t / 4;
          final trailRadius = particleRadius + trailProgress * size.x * 0.15;
          final trailAngle = particleAngle - trailProgress * 0.3;
          final tx = center.dx + math.cos(trailAngle) * trailRadius;
          final ty = center.dy + math.sin(trailAngle) * trailRadius;
          _absorptionPath1.lineTo(tx, ty);
        }

        _absorptionTrailPaint.color = color.withOpacity(particleAlpha * 0.3);
        canvas.drawPath(_absorptionPath1, _absorptionTrailPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: ENERGY VORTEX SPIRAL
    // ═══════════════════════════════════════════════════════════════════════
    if (!Tower.lowFx && _chargeLevel > 0.2) {
      for (int arm = 0; arm < 3; arm++) {
        _absorptionVortexPath.reset();
        final armBaseAngle = _animationPhase * 3 + arm * (math.pi * 2 / 3);

        bool started = false;
        for (int p = 0; p < 20; p++) {
          final progress = p / 20;
          final spiralRadius = size.x * (0.6 - progress * 0.4) * _chargeLevel;
          final spiralAngle = armBaseAngle + progress * math.pi * 1.5;

          final sx = center.dx + math.cos(spiralAngle) * spiralRadius;
          final sy = center.dy + math.sin(spiralAngle) * spiralRadius;

          if (!started) {
            _absorptionVortexPath.moveTo(sx, sy);
            started = true;
          } else {
            _absorptionVortexPath.lineTo(sx, sy);
          }
        }

        final armColor = Color.lerp(color, tertiaryColor, arm / 3)!;
        _absorptionVortexPaint.color = armColor.withOpacity(_chargeLevel * 0.4);
        canvas.drawPath(_absorptionVortexPath, _absorptionVortexPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: PULSING ABSORPTION RINGS
    // ═══════════════════════════════════════════════════════════════════════
    for (int ring = 0; ring < 3; ring++) {
      final ringPhase = _animationPhase * 5 + ring * 0.5;
      final ringProgress = (ringPhase % 1.0);
      final ringRadius = size.x * (0.2 + ringProgress * 0.5) * (0.5 + _chargeLevel * 0.5);
      final ringAlpha = _chargeLevel * (1 - ringProgress) * 0.5;

      if (ringAlpha > 0.05) {
        _tempRect = Rect.fromCircle(center: center, radius: ringRadius);

        final ringColor = Color.lerp(color, secondaryColor, ringProgress)!;
        _absorptionRingPaint.color = ringColor.withOpacity(ringAlpha);
        canvas.drawCircle(center, ringRadius, _absorptionRingPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: ELECTRIC ABSORPTION ARCS
    // ═══════════════════════════════════════════════════════════════════════
    if (!Tower.lowFx && _chargeLevel > 0.3) {
      for (int arc = 0; arc < 4; arc++) {
        final arcAngle = _animationPhase * 2 + arc * (math.pi / 2);
        final arcStartRadius = size.x * 0.5 * _chargeLevel;
        final arcEndRadius = size.x * 0.15;

        _absorptionPath2.reset();

        final startX = center.dx + math.cos(arcAngle) * arcStartRadius;
        final startY = center.dy + math.sin(arcAngle) * arcStartRadius;
        _absorptionPath2.moveTo(startX, startY);

        // Zigzag lightning effect toward center
        const segments = 5;
        for (int seg = 1; seg <= segments; seg++) {
          final segProgress = seg / segments;
          final segRadius = arcStartRadius - (arcStartRadius - arcEndRadius) * segProgress;

          final jitter = math.sin(_animationPhase * 20 + arc * 5 + seg * 3) * 4 * (1 - segProgress);
          final perpAngle = arcAngle + math.pi / 2;

          final segX = center.dx + math.cos(arcAngle) * segRadius + math.cos(perpAngle) * jitter;
          final segY = center.dy + math.sin(arcAngle) * segRadius + math.sin(perpAngle) * jitter;

          _absorptionPath2.lineTo(segX, segY);
        }

        _absorptionBeamPaint.color = color.withOpacity(_chargeLevel * 0.6);
        canvas.drawPath(_absorptionPath2, _absorptionBeamPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: ENERGY WISPS ORBITING
    // ═══════════════════════════════════════════════════════════════════════
    if (!Tower.lowFx && _chargeLevel > 0.15) {
      for (int wisp = 0; wisp < 6; wisp++) {
        final wispAngle = _animationPhase * 4 + wisp * (math.pi / 3);
        final wispRadius = size.x * (0.3 + math.sin(_animationPhase * 6 + wisp) * 0.1) * _chargeLevel;

        _absorptionPath1.reset();
        for (int p = 0; p < 8; p++) {
          final progress = p / 8;
          final wobble = math.sin(_animationPhase * 8 + p * 2 + wisp) * 3;
          final px = center.dx + math.cos(wispAngle + progress * 0.5) * (wispRadius - progress * size.x * 0.15) + wobble;
          final py = center.dy + math.sin(wispAngle + progress * 0.5) * (wispRadius - progress * size.x * 0.15);

          if (p == 0) {
            _absorptionPath1.moveTo(px, py);
          } else {
            _absorptionPath1.lineTo(px, py);
          }
        }

        final wispColor = Color.lerp(secondaryColor, tertiaryColor, wisp / 6)!;
        _absorptionWispPaint.color = wispColor.withOpacity(_chargeLevel * 0.5);
        canvas.drawPath(_absorptionPath1, _absorptionWispPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: CORE CHARGE ARCS (Original enhanced)
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < 2; i++) {
      final arcRadius = size.x * (0.32 + i * 0.06);
      final arcAlpha = _chargeLevel * (0.8 - i * 0.3);
      _tempRect = Rect.fromCircle(center: center, radius: arcRadius);

      // Glow
      if (!Tower.lowFx) {
        _chargeGlowArcPaint.color = color.withOpacity(arcAlpha * 0.5);
        canvas.drawArc(_tempRect, -math.pi / 2, sweepAngle, false, _chargeGlowArcPaint);
      }

      // Core arc
      _chargeCoreArcPaint.color = color.withOpacity(arcAlpha);
      canvas.drawArc(_tempRect, -math.pi / 2, sweepAngle, false, _chargeCoreArcPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 8: CENTRAL ABSORPTION CORE
    // ═══════════════════════════════════════════════════════════════════════
    if (!Tower.lowFx) {
      final coreRadius = size.x * 0.15 * _chargeLevel;
      final corePulse = 1 + math.sin(_animationPhase * 8) * 0.2 * _chargeLevel;

      // Core glow
      _absorptionCorePaint.color = color.withOpacity(_chargeLevel * 0.6);
      canvas.drawCircle(center, coreRadius * 2 * corePulse, _absorptionCorePaint);

      // Bright center
      _absorptionParticlePaint.color = const Color(0xFFFFFFFF).withOpacity(_chargeLevel * 0.8);
      canvas.drawCircle(center, coreRadius * corePulse, _absorptionParticlePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 9: ENERGY PULSE WAVES
    // ═══════════════════════════════════════════════════════════════════════
    if (!Tower.lowFx && _chargeLevel > 0.5) {
      for (int pulse = 0; pulse < 2; pulse++) {
        final pulsePhase = (_animationPhase * 3 + pulse * 0.5) % 1.0;
        final pulseRadius = size.x * (0.2 + pulsePhase * 0.4) * _chargeLevel;
        final pulseAlpha = _chargeLevel * (1 - pulsePhase) * 0.3;

        _absorptionPulsePaint.color = secondaryColor.withOpacity(pulseAlpha);
        canvas.drawCircle(center, pulseRadius, _absorptionPulsePaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 10: CHARGE COMPLETE BURST EFFECT
    // ═══════════════════════════════════════════════════════════════════════
    if (_chargeLevel >= 0.95 && !Tower.lowFx) {
      // Pulsing ready indicator
      final readyPulse = math.sin(_animationPhase * 12) * 0.3 + 0.7;
      _chargeCompletePaint.color = color.withOpacity(0.4 * readyPulse);
      canvas.drawCircle(center, size.x * 0.45, _chargeCompletePaint);

      // Rotating ready sparks
      for (int spark = 0; spark < 6; spark++) {
        final sparkAngle = _animationPhase * 6 + spark * (math.pi / 3);
        final sparkRadius = size.x * 0.4;
        final sparkX = center.dx + math.cos(sparkAngle) * sparkRadius;
        final sparkY = center.dy + math.sin(sparkAngle) * sparkRadius;

        _absorptionSparkPaint.color = const Color(0xFFFFFFFF).withOpacity(0.8 * readyPulse);
        canvas.drawCircle(Offset(sparkX, sparkY), 2, _absorptionSparkPaint);
      }

      // Electric ready arcs
      for (int arc = 0; arc < 3; arc++) {
        final arcAngle = _animationPhase * 8 + arc * (math.pi * 2 / 3);
        final arcRadius = size.x * 0.35;

        _absorptionPath1.reset();
        _absorptionPath1.moveTo(
          center.dx + math.cos(arcAngle) * arcRadius * 0.5,
          center.dy + math.sin(arcAngle) * arcRadius * 0.5,
        );

        for (int seg = 1; seg <= 3; seg++) {
          final progress = seg / 3;
          final jitter = math.sin(_animationPhase * 30 + arc * 7 + seg * 4) * 3;
          _absorptionPath1.lineTo(
            center.dx + math.cos(arcAngle) * arcRadius * (0.5 + progress * 0.5) + jitter,
            center.dy + math.sin(arcAngle) * arcRadius * (0.5 + progress * 0.5),
          );
        }

        _absorptionBeamPaint.color = tertiaryColor.withOpacity(0.7 * readyPulse);
        canvas.drawPath(_absorptionPath1, _absorptionBeamPaint);
      }
    }
  }

  void _renderMuzzleFlash(Canvas canvas, Offset center) {
    final flashIntensity = _fireFlashTimer / 0.15;

    // Type-specific muzzle flash
    switch (type) {
      case TowerType.pulseArcher:
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(_rotationAngle);

        _tempPath1
          ..reset()
          ..moveTo(size.x * 0.2, 0)
          ..lineTo(size.x * 0.6, -size.x * 0.15 * flashIntensity)
          ..lineTo(size.x * 0.6, size.x * 0.15 * flashIntensity)
          ..close();

        _flashConePaint.color = color.withOpacity(flashIntensity * 0.6);
        canvas.drawPath(_tempPath1, _flashConePaint);
        canvas.restore();
        break;

      case TowerType.circuitCannon:
      case TowerType.ionSniper:
        _flashCirclePaint.color = color.withOpacity(flashIntensity * 0.5);
        canvas.drawCircle(center, size.x * (0.3 + flashIntensity * 0.5), _flashCirclePaint);
        break;

      case TowerType.phaseMage:
      case TowerType.glimmerField:
      case TowerType.teslaTerminal:
      case TowerType.resonanceSiphon:
      case TowerType.neuralDisruptor:
      case TowerType.plasmaBubble:
        _flashGenericPaint.color = color.withOpacity(flashIntensity * 0.4);
        canvas.drawCircle(center, size.x * flashIntensity, _flashGenericPaint);
        break;
    }

    // Muzzle particles
    for (final particle in _muzzleParticles) {
      if (!particle.isActive) continue;

      final progress = particle.lifetime / particle.maxLifetime;
      final px = center.dx + math.cos(particle.angle) * particle.distance;
      final py = center.dy + math.sin(particle.angle) * particle.distance;
      final alpha = (1 - progress) * 0.8;

      _tempOffset1 = Offset(px, py);
      _muzzleParticlePaint.color = color.withOpacity(alpha);
      canvas.drawCircle(_tempOffset1, particle.size * (1 - progress * 0.5), _muzzleParticlePaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENERGY WAVE RIPPLES RENDER
  // ═══════════════════════════════════════════════════════════════════════════
  void _renderEnergyWaveRipples(Canvas canvas, Offset center) {
    if (_energyWaveRipples.isEmpty) return;

    // Get secondary colors
    final hslColor = HSLColor.fromColor(color);
    final secondaryColor = hslColor.withHue((hslColor.hue + 60) % 360).toColor();
    final tertiaryColor = hslColor.withHue((hslColor.hue + 180) % 360).toColor();

    for (final ripple in _energyWaveRipples) {
      if (!ripple.isActive) continue;

      final radius = ripple.radius;
      final alpha = ripple.alpha;
      final rippleColor = ripple.color;
      final progress = ripple.progress;

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 1: OUTER GLOW RING
      // ═══════════════════════════════════════════════════════════════════════
      final glowAlpha = alpha * 0.4;
      _rippleOuterGlowPaint.color = rippleColor.withOpacity(glowAlpha);

      if (ripple.isDirectional) {
        // Draw directional arc for targeted ripples
        final halfSpread = ripple.spreadAngle / 2;
        _ripplePath.reset();
        _ripplePath.addArc(
          Rect.fromCircle(center: center, radius: radius),
          ripple.direction - halfSpread,
          ripple.spreadAngle,
        );
        canvas.drawPath(_ripplePath, _rippleOuterGlowPaint);
      } else {
        // Full circular ripple
        canvas.drawCircle(center, radius, _rippleOuterGlowPaint);
      }

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 2: CORE RIPPLE RING
      // ═══════════════════════════════════════════════════════════════════════
      final coreAlpha = alpha * 0.7;
      _rippleCorePaint.color = rippleColor.withOpacity(coreAlpha);

      if (ripple.isDirectional) {
        _ripplePath.reset();
        final halfSpread = ripple.spreadAngle / 2;
        _ripplePath.addArc(
          Rect.fromCircle(center: center, radius: radius),
          ripple.direction - halfSpread,
          ripple.spreadAngle,
        );
        canvas.drawPath(_ripplePath, _rippleCorePaint);
      } else {
        canvas.drawCircle(center, radius, _rippleCorePaint);
      }

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 3: INNER BRIGHT RING
      // ═══════════════════════════════════════════════════════════════════════
      final innerRadius = radius * 0.85;
      final innerAlpha = alpha * 0.5;
      _rippleInnerPaint.color = const Color(0xFFFFFFFF).withOpacity(innerAlpha);

      if (ripple.isDirectional) {
        _ripplePath.reset();
        final halfSpread = ripple.spreadAngle / 2;
        _ripplePath.addArc(
          Rect.fromCircle(center: center, radius: innerRadius),
          ripple.direction - halfSpread,
          ripple.spreadAngle,
        );
        canvas.drawPath(_ripplePath, _rippleInnerPaint);
      } else {
        canvas.drawCircle(center, innerRadius, _rippleInnerPaint);
      }

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 4: CHROMATIC ABERRATION RINGS (red/cyan split)
      // ═══════════════════════════════════════════════════════════════════════
      if (!Tower.lowFx && !ripple.isDirectional) {
        final chromaOffset = 2 + progress * 4;
        final chromaAlpha = alpha * 0.3;

        // Red ring (offset left)
        _rippleChromaRedPaint.color = const Color(0xFFFF0066).withOpacity(chromaAlpha);
        canvas.drawCircle(Offset(center.dx - chromaOffset, center.dy), radius, _rippleChromaRedPaint);

        // Cyan ring (offset right)
        _rippleChromaCyanPaint.color = const Color(0xFF00FFFF).withOpacity(chromaAlpha);
        canvas.drawCircle(Offset(center.dx + chromaOffset, center.dy), radius, _rippleChromaCyanPaint);
      }

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 5: SPARKS ALONG RIPPLE EDGE
      // ═══════════════════════════════════════════════════════════════════════
      if (!Tower.lowFx) {
        final sparkCount = ripple.isDirectional ? 4 : 8;
        final startAngle = ripple.isDirectional ? ripple.direction - ripple.spreadAngle / 2 : 0.0;
        final angleRange = ripple.isDirectional ? ripple.spreadAngle : math.pi * 2;

        for (int i = 0; i < sparkCount; i++) {
          final sparkAngle = startAngle + (i + progress * 3) * angleRange / sparkCount;
          final sparkDist = radius * (0.95 + math.sin(progress * 10 + i) * 0.1);
          final sparkX = center.dx + math.cos(sparkAngle) * sparkDist;
          final sparkY = center.dy + math.sin(sparkAngle) * sparkDist;

          final sparkAlpha = alpha * (0.5 + math.sin(progress * 15 + i * 2) * 0.5);
          _rippleSparkPaint.color = rippleColor.withOpacity(sparkAlpha);
          canvas.drawCircle(Offset(sparkX, sparkY), 2 + (1 - progress) * 2, _rippleSparkPaint);
        }
      }

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 6: ARC SEGMENTS (broken ring effect)
      // ═══════════════════════════════════════════════════════════════════════
      if (!Tower.lowFx && !ripple.isDirectional && progress < 0.7) {
        final segmentCount = 6;
        final segmentAlpha = alpha * 0.6;
        _rippleArcSegmentPaint.color = secondaryColor.withOpacity(segmentAlpha);

        for (int i = 0; i < segmentCount; i++) {
          final segmentAngle = (i * math.pi * 2 / segmentCount) + progress * math.pi;
          final arcLength = math.pi / 8;

          _ripplePath.reset();
          _ripplePath.addArc(
            Rect.fromCircle(center: center, radius: radius * 1.1),
            segmentAngle,
            arcLength,
          );
          canvas.drawPath(_ripplePath, _rippleArcSegmentPaint);
        }
      }

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 7: HEXAGONAL PATTERN OVERLAY
      // ═══════════════════════════════════════════════════════════════════════
      if (!Tower.lowFx && !ripple.isDirectional && progress < 0.5) {
        final hexAlpha = alpha * (1 - progress * 2) * 0.4;
        _rippleHexPaint.color = rippleColor.withOpacity(hexAlpha);

        // Draw hexagon at ripple edge
        _ripplePath.reset();
        for (int i = 0; i < 6; i++) {
          final hexAngle = i * math.pi / 3 + progress * math.pi;
          final hx = center.dx + math.cos(hexAngle) * radius;
          final hy = center.dy + math.sin(hexAngle) * radius;
          if (i == 0) {
            _ripplePath.moveTo(hx, hy);
          } else {
            _ripplePath.lineTo(hx, hy);
          }
        }
        _ripplePath.close();
        canvas.drawPath(_ripplePath, _rippleHexPaint);
      }

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 8: DATA STREAM PARTICLES
      // ═══════════════════════════════════════════════════════════════════════
      if (!Tower.lowFx && ripple.isDirectional) {
        final dataCount = 5;
        final dataAlpha = alpha * 0.6;
        _rippleDataPaint.color = const Color(0xFFFFFFFF).withOpacity(dataAlpha);

        final halfSpread = ripple.spreadAngle / 2;
        for (int i = 0; i < dataCount; i++) {
          final dataProgress = (progress + i * 0.15) % 1.0;
          final dataAngle = ripple.direction + (i - dataCount / 2) * ripple.spreadAngle / dataCount;
          final dataDist = ripple.startRadius + (ripple.maxRadius - ripple.startRadius) * dataProgress;

          final dataX = center.dx + math.cos(dataAngle) * dataDist;
          final dataY = center.dy + math.sin(dataAngle) * dataDist;

          _rippleDataPaint.color = rippleColor.withOpacity(dataAlpha * (1 - dataProgress));
          canvas.drawCircle(Offset(dataX, dataY), 1.5, _rippleDataPaint);
        }
      }

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 9: DISTORTION WAVE (inner secondary ring)
      // ═══════════════════════════════════════════════════════════════════════
      if (!Tower.lowFx && !ripple.isDirectional && progress > 0.2) {
        final distortRadius = radius * 0.7;
        final distortAlpha = alpha * 0.25 * (1 - (progress - 0.2) / 0.8);
        _rippleDistortionPaint.color = tertiaryColor.withOpacity(distortAlpha);
        canvas.drawCircle(center, distortRadius, _rippleDistortionPaint);
      }

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 10: EDGE MARKERS
      // ═══════════════════════════════════════════════════════════════════════
      if (!Tower.lowFx && !ripple.isDirectional) {
        final markerCount = 4;
        final markerAlpha = alpha * 0.7;

        for (int i = 0; i < markerCount; i++) {
          final markerAngle = i * math.pi / 2 + progress * math.pi / 4;
          final markerX = center.dx + math.cos(markerAngle) * radius;
          final markerY = center.dy + math.sin(markerAngle) * radius;

          // Draw small cross marker
          _rippleDataPaint.color = const Color(0xFFFFFFFF).withOpacity(markerAlpha);
          canvas.drawLine(
            Offset(markerX - 2, markerY),
            Offset(markerX + 2, markerY),
            _rippleDataPaint,
          );
          canvas.drawLine(
            Offset(markerX, markerY - 2),
            Offset(markerX, markerY + 2),
            _rippleDataPaint,
          );
        }
      }
    }
  }

  void _renderRangeIndicator(Canvas canvas, Offset center) {
    final rangeAlpha = 0.05 + _pulseAnimation * 0.05;
    _rangePaint.color = color.withOpacity(rangeAlpha);
    _tempRect = Rect.fromCircle(center: center, radius: range);

    // Animated dashed circle - cache the rect
    final angleOffset = _animationPhase * 0.1;
    for (int i = 0; i < 36; i += 2) {
      final startAngle = i * math.pi / 18 + angleOffset;
      canvas.drawArc(_tempRect, startAngle, math.pi / 18, false, _rangePaint);
    }

    // Corner marks at cardinal directions
    _rangeCornerPaint.color = color.withOpacity(rangeAlpha * 2);
    final markOffset = _animationPhase * 0.05;
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + markOffset;
      _tempOffset1 = Offset(center.dx + math.cos(angle) * range, center.dy + math.sin(angle) * range);
      canvas.drawCircle(_tempOffset1, 2, _rangeCornerPaint);
    }
  }

  void _renderTypeSymbol(Canvas canvas, Offset center) {
    final symbolAlpha = 0.4 + _pulseAnimation * 0.2;
    _symbolPaint.color = color.withOpacity(symbolAlpha);

    canvas.save();
    canvas.translate(center.dx, center.dy);

    switch (type) {
      case TowerType.pulseArcher:
        _tempPath1
          ..reset()
          ..moveTo(-4, 3)
          ..lineTo(0, -4)
          ..lineTo(4, 3);
        canvas.drawPath(_tempPath1, _symbolPaint);
        break;

      case TowerType.circuitCannon:
        canvas.drawLine(const Offset(-5, 0), const Offset(5, 0), _symbolPaint);
        canvas.drawLine(const Offset(0, -5), const Offset(0, 5), _symbolPaint);
        canvas.drawCircle(Offset.zero, 3, _symbolPaint);
        break;

      case TowerType.phaseMage:
        canvas.drawCircle(Offset.zero, 4, _symbolPaint);
        _symbolFillPaint.color = color.withOpacity(symbolAlpha);
        canvas.drawCircle(Offset.zero, 1.5, _symbolFillPaint);
        break;

      case TowerType.glimmerField:
        for (int i = 0; i < 4; i++) {
          final angle = i * math.pi / 2;
          _tempOffset1 = Offset(math.cos(angle) * 5, math.sin(angle) * 5);
          canvas.drawLine(Offset.zero, _tempOffset1, _symbolPaint);
        }
        break;
      case TowerType.ionSniper:
        canvas.drawRect(const Rect.fromLTWH(-4, -1, 8, 2), _symbolPaint);
        canvas.drawRect(const Rect.fromLTWH(-1, -4, 2, 8), _symbolPaint);
        break;
      case TowerType.teslaTerminal:
        canvas.drawCircle(Offset.zero, 4, _symbolPaint);
        canvas.drawLine(const Offset(-4, -4), const Offset(4, 4), _symbolPaint);
        break;
      case TowerType.resonanceSiphon:
        canvas.drawCircle(Offset.zero, 5, _symbolPaint);
        canvas.drawCircle(Offset.zero, 2, _symbolPaint);
        break;
      case TowerType.neuralDisruptor:
        canvas.drawRect(const Rect.fromLTWH(-3, -3, 6, 6), _symbolPaint);
        break;
      case TowerType.plasmaBubble:
        // Bubble symbol - two overlapping circles
        canvas.drawCircle(const Offset(-2, 0), 3, _symbolPaint);
        canvas.drawCircle(const Offset(2, 0), 3, _symbolPaint);
        break;
    }

    canvas.restore();
  }
}

// Helper class for orbiting tower particles
class _TowerParticle {
  _TowerParticle({
    required this.angle,
    required this.radius,
    required this.speed,
    required this.size,
    required this.phase,
  });

  double angle;
  double radius;
  double speed;
  double size;
  double phase;

  void update(double dt, TowerType type) {
    // Different orbit speeds per tower type
    final speedMultiplier = switch (type) {
      TowerType.pulseArcher => 1.0,
      TowerType.circuitCannon => 0.5,
      TowerType.phaseMage => 1.5,
      TowerType.glimmerField => 2.0,
      TowerType.ionSniper => 0.4,
      TowerType.teslaTerminal => 1.8,
      TowerType.resonanceSiphon => 1.2,
      TowerType.neuralDisruptor => 1.4,
      TowerType.plasmaBubble => 1.0,
    };
    angle += dt * speed * speedMultiplier;
  }
}

// Helper class for muzzle flash particles
class _MuzzleParticle {
  _MuzzleParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.lifetime,
    required this.maxLifetime,
  }) : distance = 0;

  double angle;
  double speed;
  double size;
  double lifetime;
  double maxLifetime;
  double distance;

  bool get isActive => lifetime > 0 && lifetime < maxLifetime;

  void update(double dt) {
    if (lifetime > 0) {
      lifetime += dt;
      distance += speed * dt;
    }
  }

  void reset(math.Random random, double baseAngle) {
    angle = baseAngle + (random.nextDouble() - 0.5) * 0.8;
    speed = 50 + random.nextDouble() * 100;
    lifetime = 0.001; // Start active
    distance = 10;
  }
}

// Helper class for energy wave ripple effects
class _EnergyWaveRipple {
  _EnergyWaveRipple({
    required this.startRadius,
    required this.maxRadius,
    required this.duration,
    required this.color,
    this.isDirectional = false,
    this.direction = 0,
    this.spreadAngle = math.pi * 2,
  }) : progress = 0, age = 0;

  final double startRadius;
  final double maxRadius;
  final double duration;
  final Color color;
  final bool isDirectional;
  final double direction;
  final double spreadAngle;

  double progress; // 0 to 1
  double age;

  bool get isActive => progress < 1;
  double get radius => startRadius + (maxRadius - startRadius) * progress;
  double get alpha => (1 - progress) * (1 - progress); // Quadratic fade out

  void update(double dt) {
    age += dt;
    progress = (age / duration).clamp(0.0, 1.0);
  }
}

// Helper class for holographic construction particles
class _ConstructionParticle {
  _ConstructionParticle({
    required this.angle,
    required this.radius,
    required this.speed,
    required this.size,
    required this.phase,
    required this.targetRadius,
    required this.spiralRate,
  });

  double angle;         // Starting angle in radians
  double radius;        // Starting radius (far from center)
  double speed;         // Base rotation speed
  double size;          // Particle size
  double phase;         // Phase offset for staggered animation
  double targetRadius;  // Final radius when merged
  double spiralRate;    // How fast the particle spirals inward

  void update(double dt, double constructionProgress) {
    // Rotate faster as construction progresses
    angle += dt * speed * (1 + constructionProgress * 2);
  }
}

// Helper class for damage fracture impact points
class _FractureImpactPoint {
  _FractureImpactPoint({
    required this.offset,
    required this.angle,
    required this.intensity,
    required this.branchCount,
  });

  final Offset offset;     // Position offset from tower center
  final double angle;      // Impact angle in radians
  final double intensity;  // Damage intensity at this point (0-1)
  final int branchCount;   // Number of secondary branches from this impact
}

// Helper class for radar sweep enemy blips
class _RadarBlip {
  _RadarBlip({
    required this.enemy,
    required this.lastPingTime,
    required this.pingIntensity,
  });

  final Enemy enemy;          // Reference to the enemy being tracked
  double lastPingTime;        // Time since last sweep ping (animation phase)
  double pingIntensity;       // Current ping intensity (fades over time)
}
