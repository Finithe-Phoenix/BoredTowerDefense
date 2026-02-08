import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GameWorld extends Component {
  GameWorld({
    required this.tileSize,
    required this.mapFile,
  });

  final double tileSize;
  final String mapFile;
  static const int pathWidthTiles = 2;

  List<Vector2> waypoints = [];
  List<List<bool>> isBuildable = [];
  List<List<int>> tileTypes = []; // 0 = buildable, 1 = blocked, 2 = path
  math.Point<int>? startCell;
  math.Point<int>? endCell;
  int mapWidth = 0;
  int mapHeight = 0;
  bool reduceFx = false;
  bool allowBlur = true;
  late final _WorldRenderer _renderer;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadMap();

    // Add visual renderer after map is loaded
    _renderer = _WorldRenderer(world: this);
    add(_renderer);
  }

  void setQuality({required bool reduceFx, required bool allowBlur}) {
    this.reduceFx = reduceFx;
    this.allowBlur = allowBlur;
  }

  void invalidateCache() {
    _renderer.invalidateCache();
  }

  Future<void> _loadMap() async {
    final tiled = await TiledComponent.load(mapFile, Vector2.all(tileSize));
    // Don't add the tiled component - we render our own visuals

    final map = tiled.tileMap.map;
    mapWidth = map.width;
    mapHeight = map.height;
    isBuildable =
        List.generate(mapHeight, (_) => List<bool>.filled(mapWidth, true));
    tileTypes = List.generate(mapHeight, (_) => List<int>.filled(mapWidth, 0));

    for (final layer in map.layers) {
      if (layer.name == 'Path' && layer is ObjectGroup) {
        waypoints = layer.objects
            .map((obj) => Vector2(obj.x, obj.y))
            .toList(growable: false);

        // Mark path cells as non-buildable
        for (final obj in layer.objects) {
          final cx = (obj.x / tileSize).floor();
          final cy = (obj.y / tileSize).floor();
          if (cy >= 0 && cy < mapHeight && cx >= 0 && cx < mapWidth) {
            isBuildable[cy][cx] = false;
            tileTypes[cy][cx] = 2; // Path tile
          }
        }

        // Also mark cells between waypoints as path
        _markPathCells();

        if (waypoints.isNotEmpty) {
          startCell = math.Point<int>(
            (waypoints.first.x / tileSize).floor(),
            (waypoints.first.y / tileSize).floor(),
          );
          endCell = math.Point<int>(
            (waypoints.last.x / tileSize).floor(),
            (waypoints.last.y / tileSize).floor(),
          );
        }
        _ensureStartingBuildZone();
      }
      if (layer.name == 'Collision' && layer is TileLayer) {
        final tileData = layer.tileData;
        if (tileData != null) {
          for (int y = 0; y < mapHeight && y < tileData.length; y++) {
            for (int x = 0; x < mapWidth && x < tileData[y].length; x++) {
              final gid = tileData[y][x].tile;
              if (gid != 0) {
                isBuildable[y][x] = false;
                if (tileTypes[y][x] != 2) {
                  tileTypes[y][x] = 1; // Blocked tile
                }
              }
            }
          }
        }
      }
    }
  }

  void _markPathCells() {
    if (waypoints.isEmpty) return;
    for (int i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];

      // Mark cells along the path
      final startX = (start.x / tileSize).floor();
      final startY = (start.y / tileSize).floor();
      final endX = (end.x / tileSize).floor();
      final endY = (end.y / tileSize).floor();

      // Simple line marking
      final dx = (endX - startX).sign;
      final dy = (endY - startY).sign;
      final horizontal = (endX - startX).abs() >= (endY - startY).abs();

      var x = startX;
      var y = startY;

      while (true) {
        _markPathCell(x, y, horizontal: horizontal);

        if (x == endX && y == endY) {
          break;
        }

        if (x != endX) x += dx;
        if (y != endY) y += dy;
      }
    }
  }

  void _markPathCell(int x, int y, {required bool horizontal}) {
    final halfWidth = pathWidthTiles ~/ 2;
    final extra = pathWidthTiles % 2;
    if (horizontal) {
      for (int oy = -halfWidth; oy < halfWidth + extra; oy++) {
        _setPathCell(x, y + oy);
      }
    } else {
      for (int ox = -halfWidth; ox < halfWidth + extra; ox++) {
        _setPathCell(x + ox, y);
      }
    }
  }

  void _setPathCell(int x, int y) {
    if (y < 0 || y >= mapHeight || x < 0 || x >= mapWidth) return;
    isBuildable[y][x] = false;
    tileTypes[y][x] = 2;
  }

  void _ensureStartingBuildZone() {
    if (startCell == null) return;

    const int radius = 2;
    final safeCells = <math.Point<int>>[];

    for (int y = startCell!.y - radius; y <= startCell!.y + radius; y++) {
      for (int x = startCell!.x - radius; x <= startCell!.x + radius; x++) {
        if (y >= 0 && y < mapHeight && x >= 0 && x < mapWidth) {
          isBuildable[y][x] = true;
          if (tileTypes[y][x] != 2) {
            tileTypes[y][x] = 0;
          }
          safeCells.add(math.Point<int>(x, y));
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
          '[GameWorld] Ensured starting build zone around $startCell ($safeCells)');
    }
  }
}

class _WorldRenderer extends PositionComponent {
  _WorldRenderer({required this.world});

  final GameWorld world;
  double _time = 0;
  ui.Picture? _staticTiles;
  bool _cacheReady = false;
  Path? _pathOverlay;
  ui.Picture? _pathStaticLayer;
  bool _pathStaticDirty = true;
  bool _lastReduceFx = false;
  bool _lastAllowBlur = true;
  double _pathLength = 0;
  final List<double> _segmentLengths = [];
  int _cachedWaypointCount = -1;
  double _cachedWorldWidth = 0;
  double _cachedWorldHeight = 0;
  bool _veinCacheDirty = true;
  final List<List<Offset>> _veinPaths = [];
  final List<double> _veinPathLengths = [];
  final List<List<double>> _veinSegmentLengths = [];
  final List<List<double>> _veinSegmentStarts = [];
  final List<Offset> _veinNodes = [];
  final List<Path> _veinPathCache = [];
  bool _hexCacheDirty = true;
  double _hexCachedWorldWidth = 0;
  double _hexCachedWorldHeight = 0;
  final List<Path> _hexPaths = [];
  final List<int> _hexHighlightIndices = [];
  final List<double> _hexHighlightPhaseSeeds = [];
  final List<Offset> _hexCornerCenters = [];
  final List<Path> _hexAccentPaths = [];
  final Path _hexGridPath = Path();
  final Path _hexCornerPath = Path();
  final Path _hexAccentPath = Path();

  // ===== STATIC PAINT OBJECTS FOR PER-FRAME RENDERING =====
  // Path overlay paints
  static final Paint _pathOuterGlowPaint = Paint()
    ..color = const Color(0xFFFF0066).withOpacity(0.2)
    ..strokeWidth = 12
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  static final Paint _pathMiddleGlowPaint = Paint()
    ..color = const Color(0xFFFF0066).withOpacity(0.5)
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  static final Paint _pathCorePaint = Paint()
    ..color = const Color(0xFFFF4488)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  // Waypoint node paints
  static final Paint _nodeGlowPaint = Paint()
    ..color = const Color(0xFFFF0066).withOpacity(0.6);

  static final Paint _nodeRingPaint = Paint()
    ..color = const Color(0xFFFF4488).withOpacity(0.8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  static final Paint _nodeCorePaint = Paint()..color = const Color(0xFFFF0066);

  // Energy pulse paints
  static final Paint _pulseGlowPaint = Paint()
    ..color = const Color(0xFFFF0066).withOpacity(0.9);

  static final Paint _pulseCorePaint = Paint()..color = Colors.white;

  static final Paint _pulseTrailPaint = Paint();

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATED CIRCUIT PATTERN PAINTS
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _circuitTracePaint = Paint()
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Paint _circuitNodePaint = Paint();
  static final Paint _circuitGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _circuitDataFlowPaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Paint _circuitJunctionPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _circuitPulsePaint = Paint();
  static final Paint _circuitChipPaint = Paint();
  static final Paint _circuitChipBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _circuitHexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  static final Paint _circuitEnergyPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Path _circuitPath = Path();

  // ═══════════════════════════════════════════════════════════════════════════
  // HEXAGONAL GRID OVERLAY PAINTS
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _hexGridPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Paint _hexGridGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _hexGridNodePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _hexGridCornerPaint = Paint();
  static final Paint _hexGridPulsePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _hexGridHighlightPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  static final Paint _hexGridEnergyPaint = Paint()
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  static final Paint _hexGridAuraPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  // ═══════════════════════════════════════════════════════════════════════════
  // PULSING ENERGY VEINS PAINTS
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _veinGlowPaint = Paint()
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _veinCorePaint = Paint()
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Paint _veinPulsePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _veinNodePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _veinBranchPaint = Paint()
    ..strokeWidth = 0.8
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Paint _veinAuraPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _veinSparkPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  // Spawn portal paints
  static final Paint _portalRingPaint = Paint()
    ..color = const Color(0xFF00FF88).withOpacity(0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  static final Paint _portalGlowPaint = Paint();

  static final Paint _portalCorePaint = Paint()
    ..color = const Color(0xFF00FF88).withOpacity(0.9);

  static final Paint _portalCenterPaint = Paint()
    ..color = Colors.white.withOpacity(0.9);

  static final Paint _portalArrowPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  static final Paint _portalLabelPaint = Paint();

  // Core target paints
  static final Paint _dangerZonePaint = Paint()
    ..color = const Color(0xFFFF0066).withOpacity(0.2);

  static final Paint _warningPaint = Paint()
    ..color = const Color(0xFFFF0066).withOpacity(0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  static final Paint _coreRingPaint = Paint()
    ..color = const Color(0xFFFF0066).withOpacity(0.7)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  static final Paint _coreInnerRingPaint = Paint()
    ..color = const Color(0xFFFF4488).withOpacity(0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  static final Paint _coreGlowPaint = Paint()
    ..color = const Color(0xFFFF0066).withOpacity(0.8);

  static final Paint _coreCenterPaint = Paint()
    ..color = const Color(0xFFFF4488);

  static final Paint _coreXPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  // Blocked/buildable tile paints
  static final Paint _cyberBasePaint = Paint()..color = const Color(0xFF0a0a18);
  static final Paint _cyberTopPaint = Paint()..color = const Color(0xFF181828);
  static final Paint _cyberMainPaint = Paint()..color = const Color(0xFF101020);
  static final Paint _cyberWindowGlowPaint = Paint()..maskFilter = _blur2;
  static final Paint _cyberWindowPaint = Paint()
    ..color = const Color(0xFF00DDFF);
  static final Paint _cyberAntennaPaint = Paint()..strokeWidth = 1;
  static final Paint _cyberBlinkPaint = Paint()..maskFilter = _blur4;
  static final Paint _cyberEdgePaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;

  static final Paint _serverBasePaint = Paint()
    ..color = const Color(0xFF080812);
  static final Paint _serverFramePaint = Paint()
    ..color = const Color(0xFF1a1a2e)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _serverSlotPaint = Paint()
    ..color = const Color(0xFF0d0d1a);
  static final Paint _serverLedPaint = Paint();
  static final Paint _serverVentPaint = Paint()..strokeWidth = 1;

  static final Paint _energyBasePaint = Paint()
    ..color = const Color(0xFF050510);
  static final Paint _energyRingPaint = Paint()
    ..color = const Color(0xFF1a1a2e)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _energyGlowPaint = Paint()..maskFilter = _blur8;
  static final Paint _energyCorePaint = Paint()
    ..color = const Color(0xFFFF44FF);
  static final Paint _energyCenterPaint = Paint()..color = Colors.white;
  static final Paint _energyArcPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;
  static final Paint _energyBracketPaint = Paint()..strokeWidth = 1;

  static final Paint _dataBasePaint = Paint()..color = const Color(0xFF0a0a14);
  static final Paint _dataHexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Paint _dataDisplayBgPaint = Paint()
    ..color = const Color(0xFF001122);
  static final Paint _dataDisplayGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..maskFilter = _blur2;
  static final Paint _dataLinePaint = Paint()..strokeWidth = 1;
  static final Paint _dataIndicatorPaint = Paint()..maskFilter = _blur2;

  static final Paint _pathTileBasePaint = Paint()
    ..color = const Color(0xFF050012);
  static final Paint _pathTileGradientPaint = Paint();
  static Shader? _pathTileGradientShader;
  static Size? _pathTileGradientSize;

  static final Paint _buildableBasePaint = Paint()
    ..color = const Color(0xFF0a0a16);
  static final Paint _buildableGridPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Paint _buildableAnchorGlowPaint = Paint()..maskFilter = _blur2;
  static final Paint _buildableAnchorCorePaint = Paint();
  static final Paint _buildableFlickerPaint = Paint()..maskFilter = _blur4;
  static final Paint _buildableTracePaint = Paint()
    ..strokeWidth = 0.8
    ..style = PaintingStyle.stroke;
  static final Paint _buildableNodePaint = Paint();
  static final Paint _buildableHexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Paint _buildableDiamondPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Paint _buildableDiamondInnerPaint = Paint()
    ..style = PaintingStyle.fill;
  static final Paint _buildableCrossPaint = Paint()..strokeWidth = 0.5;
  static final Path _buildableDiamondPath = Path();
  static final Path _buildableDiamondInnerPath = Path();

  // Cached MaskFilters
  static const MaskFilter _blur2 = MaskFilter.blur(BlurStyle.normal, 2);
  static const MaskFilter _blur4 = MaskFilter.blur(BlurStyle.normal, 4);
  static const MaskFilter _blur6 = MaskFilter.blur(BlurStyle.normal, 6);
  static const MaskFilter _blur8 = MaskFilter.blur(BlurStyle.normal, 8);
  static const MaskFilter _blur10 = MaskFilter.blur(BlurStyle.normal, 10);
  static const MaskFilter _blur12 = MaskFilter.blur(BlurStyle.normal, 12);
  static const MaskFilter _blur15 = MaskFilter.blur(BlurStyle.normal, 15);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _buildStaticCache();
    _rebuildPathCache();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!_cacheReady) {
      _buildStaticCache();
    }
    if (_staticTiles != null) {
      canvas.drawPicture(_staticTiles!);
    } else {
      _renderTiles(canvas);
    }

    // Draw hexagonal grid overlay (background decoration)
    _drawHexagonalGridOverlay(canvas);

    // Draw pulsing energy veins
    _drawPulsingEnergyVeins(canvas);

    // Draw path line overlay
    _drawPathOverlay(canvas);

    // Draw start and end markers
    _drawStartEndMarkers(canvas);
  }

  @override
  void onRemove() {
    _staticTiles?.dispose();
    _pathStaticLayer?.dispose();
    super.onRemove();
  }

  void invalidateCache() {
    _cacheReady = false;
    _staticTiles?.dispose();
    _staticTiles = null;
    _pathStaticLayer?.dispose();
    _pathStaticLayer = null;
    _pathStaticDirty = true;
    _veinCacheDirty = true;
    _hexCacheDirty = true;
    _rebuildPathCache();
  }

  void _ensurePathCache() {
    if (_cachedWaypointCount != world.waypoints.length) {
      _rebuildPathCache();
    }
  }

  void _rebuildPathCache() {
    _cachedWaypointCount = world.waypoints.length;
    _pathOverlay = null;
    _pathLength = 0;
    _segmentLengths.clear();
    _pathStaticDirty = true;
    _pathStaticLayer?.dispose();
    _pathStaticLayer = null;

    if (world.waypoints.length < 2) return;

    final path = Path();
    path.moveTo(world.waypoints.first.x, world.waypoints.first.y);
    for (int i = 1; i < world.waypoints.length; i++) {
      path.lineTo(world.waypoints[i].x, world.waypoints[i].y);
      final segmentLength =
          (world.waypoints[i] - world.waypoints[i - 1]).length;
      _segmentLengths.add(segmentLength);
      _pathLength += segmentLength;
    }
    _pathOverlay = path;
  }

  void _ensureVeinCache() {
    final worldWidth = world.tileSize * world.mapWidth.toDouble();
    final worldHeight = world.tileSize * world.mapHeight.toDouble();
    if (!_veinCacheDirty &&
        _cachedWorldWidth == worldWidth &&
        _cachedWorldHeight == worldHeight) {
      return;
    }

    _cachedWorldWidth = worldWidth;
    _cachedWorldHeight = worldHeight;
    _veinPaths.clear();
    _veinPathLengths.clear();
    _veinSegmentLengths.clear();
    _veinSegmentStarts.clear();
    _veinNodes.clear();
    _veinPathCache.clear();

    // Main horizontal veins
    _veinPaths.add([
      Offset(0, worldHeight * 0.2),
      Offset(worldWidth * 0.15, worldHeight * 0.22),
      Offset(worldWidth * 0.35, worldHeight * 0.18),
      Offset(worldWidth * 0.5, worldHeight * 0.25),
      Offset(worldWidth * 0.7, worldHeight * 0.2),
      Offset(worldWidth * 0.85, worldHeight * 0.23),
      Offset(worldWidth, worldHeight * 0.2),
    ]);

    _veinPaths.add([
      Offset(0, worldHeight * 0.5),
      Offset(worldWidth * 0.2, worldHeight * 0.48),
      Offset(worldWidth * 0.4, worldHeight * 0.52),
      Offset(worldWidth * 0.6, worldHeight * 0.47),
      Offset(worldWidth * 0.8, worldHeight * 0.53),
      Offset(worldWidth, worldHeight * 0.5),
    ]);

    _veinPaths.add([
      Offset(0, worldHeight * 0.8),
      Offset(worldWidth * 0.25, worldHeight * 0.78),
      Offset(worldWidth * 0.45, worldHeight * 0.82),
      Offset(worldWidth * 0.65, worldHeight * 0.77),
      Offset(worldWidth * 0.9, worldHeight * 0.8),
      Offset(worldWidth, worldHeight * 0.8),
    ]);

    // Main vertical veins
    _veinPaths.add([
      Offset(worldWidth * 0.2, 0),
      Offset(worldWidth * 0.22, worldHeight * 0.3),
      Offset(worldWidth * 0.18, worldHeight * 0.6),
      Offset(worldWidth * 0.2, worldHeight),
    ]);

    _veinPaths.add([
      Offset(worldWidth * 0.5, 0),
      Offset(worldWidth * 0.48, worldHeight * 0.25),
      Offset(worldWidth * 0.52, worldHeight * 0.5),
      Offset(worldWidth * 0.48, worldHeight * 0.75),
      Offset(worldWidth * 0.5, worldHeight),
    ]);

    _veinPaths.add([
      Offset(worldWidth * 0.8, 0),
      Offset(worldWidth * 0.78, worldHeight * 0.35),
      Offset(worldWidth * 0.82, worldHeight * 0.7),
      Offset(worldWidth * 0.8, worldHeight),
    ]);

    // Diagonal connector veins
    _veinPaths.add([
      Offset(worldWidth * 0.1, worldHeight * 0.1),
      Offset(worldWidth * 0.3, worldHeight * 0.35),
      Offset(worldWidth * 0.4, worldHeight * 0.6),
    ]);

    _veinPaths.add([
      Offset(worldWidth * 0.9, worldHeight * 0.1),
      Offset(worldWidth * 0.7, worldHeight * 0.4),
      Offset(worldWidth * 0.6, worldHeight * 0.65),
    ]);

    for (int pathIndex = 0; pathIndex < _veinPaths.length; pathIndex++) {
      final path = _veinPaths[pathIndex];
      final segmentLengths = <double>[];
      final segmentStarts = <double>[];
      double totalLength = 0;
      for (int i = 1; i < path.length; i++) {
        final dx = path[i].dx - path[i - 1].dx;
        final dy = path[i].dy - path[i - 1].dy;
        final segmentLength = math.sqrt(dx * dx + dy * dy);
        segmentStarts.add(totalLength);
        segmentLengths.add(segmentLength);
        totalLength += segmentLength;
      }
      _veinPathLengths.add(totalLength);
      _veinSegmentLengths.add(segmentLengths);
      _veinSegmentStarts.add(segmentStarts);

      final cachedPath = Path();
      cachedPath.moveTo(path.first.dx, path.first.dy);
      for (int i = 1; i < path.length; i++) {
        cachedPath.lineTo(path[i].dx, path[i].dy);
      }
      _veinPathCache.add(cachedPath);
    }

    _veinNodes.addAll([
      Offset(worldWidth * 0.2, worldHeight * 0.2),
      Offset(worldWidth * 0.5, worldHeight * 0.25),
      Offset(worldWidth * 0.8, worldHeight * 0.2),
      Offset(worldWidth * 0.2, worldHeight * 0.5),
      Offset(worldWidth * 0.5, worldHeight * 0.5),
      Offset(worldWidth * 0.8, worldHeight * 0.5),
      Offset(worldWidth * 0.2, worldHeight * 0.8),
      Offset(worldWidth * 0.5, worldHeight * 0.75),
      Offset(worldWidth * 0.8, worldHeight * 0.8),
    ]);

    _veinCacheDirty = false;
  }

  void _ensureHexCache() {
    final worldWidth = world.tileSize * world.mapWidth.toDouble();
    final worldHeight = world.tileSize * world.mapHeight.toDouble();
    if (!_hexCacheDirty &&
        _hexCachedWorldWidth == worldWidth &&
        _hexCachedWorldHeight == worldHeight) {
      return;
    }

    _hexCachedWorldWidth = worldWidth;
    _hexCachedWorldHeight = worldHeight;

    const hexRadius = 25.0;
    const angles = <double>[
      -math.pi / 6,
      math.pi / 6,
      math.pi / 2,
      5 * math.pi / 6,
      -5 * math.pi / 6,
      -math.pi / 2,
    ];
    final hexWidth = hexRadius * 2;
    final hexHeight = hexRadius * math.sqrt(3);
    final horizontalSpacing = hexWidth * 0.75;
    final verticalSpacing = hexHeight;

    final colCount = (worldWidth / horizontalSpacing).ceil() + 1;
    final rowCount = (worldHeight / verticalSpacing).ceil() + 1;

    _hexPaths.clear();
    _hexHighlightIndices.clear();
    _hexHighlightPhaseSeeds.clear();
    _hexCornerCenters.clear();
    _hexAccentPaths.clear();
    _hexGridPath.reset();
    _hexCornerPath.reset();
    _hexAccentPath.reset();

    for (int row = 0; row < rowCount; row++) {
      final offsetX = (row % 2) * horizontalSpacing * 0.5;
      for (int col = 0; col < colCount; col++) {
        final centerX = col * horizontalSpacing + offsetX;
        final centerY = row * verticalSpacing;
        final center = Offset(centerX, centerY);

        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = angles[i];
          final px = centerX + math.cos(angle) * hexRadius;
          final py = centerY + math.sin(angle) * hexRadius;
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();

        final index = _hexPaths.length;
        _hexPaths.add(path);
        _hexGridPath.addPath(path, Offset.zero);
        if (row % 3 == 0 && col % 3 == 0) {
          _hexHighlightIndices.add(index);
          _hexHighlightPhaseSeeds.add(row * 0.3 + col * 0.4);
        }

        if (row % 2 == 0 && col % 2 == 0) {
          _hexCornerCenters.add(center);
          _hexCornerPath.addOval(
            Rect.fromCircle(center: center, radius: 1.5),
          );
        }
      }
    }

    final accentRadius = hexRadius * 0.6;
    for (int row = 1; row < rowCount; row += 5) {
      final offsetX = (row % 2) * horizontalSpacing * 0.5;
      for (int col = 1; col < colCount; col += 5) {
        final centerX = col * horizontalSpacing + offsetX;
        final centerY = row * verticalSpacing;

        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = angles[i];
          final px = centerX + math.cos(angle) * accentRadius;
          final py = centerY + math.sin(angle) * accentRadius;
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        _hexAccentPaths.add(path);
        _hexAccentPath.addPath(path, Offset.zero);
      }
    }

    _hexCacheDirty = false;
  }

  void _buildStaticCache() {
    if (_cacheReady || world.mapWidth == 0 || world.mapHeight == 0) return;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final previousTime = _time;
    _time = 0;
    _renderTiles(canvas);
    _time = previousTime;
    _staticTiles?.dispose();
    _staticTiles = recorder.endRecording();
    _cacheReady = true;
  }

  void _renderTiles(Canvas canvas) {
    final tileSize = world.tileSize;
    for (int y = 0; y < world.mapHeight; y++) {
      for (int x = 0; x < world.mapWidth; x++) {
        final rect = Rect.fromLTWH(
          x * tileSize,
          y * tileSize,
          tileSize,
          tileSize,
        );

        final tileType = world.tileTypes[y][x];

        if (tileType == 1) {
          _drawBlockedTile(canvas, rect, x, y);
        } else if (tileType == 2) {
          _drawPathTile(canvas, rect, x, y);
        } else {
          _drawBuildableTile(canvas, rect, x, y);
        }
      }
    }
  }

  void _drawBlockedTile(Canvas canvas, Rect rect, int x, int y) {
    // Determine structure type based on position clustering
    final structureType = _getStructureType(x, y);

    switch (structureType) {
      case 0:
        _drawCyberpunkBuilding(canvas, rect, x, y);
        break;
      case 1:
        _drawServerRack(canvas, rect, x, y);
        break;
      case 2:
        _drawEnergyCore(canvas, rect, x, y);
        break;
      case 3:
        _drawDataNode(canvas, rect, x, y);
        break;
      default:
        _drawCyberpunkBuilding(canvas, rect, x, y);
    }
  }

  int _getStructureType(int x, int y) {
    // Group tiles into clusters for consistent structure types
    final clusterX = x ~/ 3;
    final clusterY = y ~/ 2;
    return (clusterX * 7 + clusterY * 11) % 4;
  }

  void _drawCyberpunkBuilding(Canvas canvas, Rect rect, int x, int y) {
    // Dark metallic base
    canvas.drawRect(rect, _cyberBasePaint);

    // Building structure with 3D effect
    final buildingRect = rect.deflate(2);

    // Top face (lighter)
    canvas.drawRect(
      Rect.fromLTRB(buildingRect.left, buildingRect.top, buildingRect.right,
          buildingRect.top + 6),
      _cyberTopPaint,
    );

    // Main face
    canvas.drawRect(buildingRect, _cyberMainPaint);

    // Windows - glowing cyan
    _cyberWindowGlowPaint.color = const Color(0xFF00FFFF)
        .withOpacity(0.4 + math.sin(_time * 2 + x * 0.5) * 0.2);
    _cyberWindowPaint.color = const Color(0xFF00DDFF).withOpacity(0.8);

    // Window grid pattern
    final windowSize = 4.0;
    final windowSpacing = 6.0;
    final startX = rect.left + 5;
    final startY = rect.top + 8;

    for (int wy = 0; wy < 2; wy++) {
      for (int wx = 0; wx < 3; wx++) {
        // Some windows are lit, some are dark
        final isLit =
            ((x + wx) * 3 + (y + wy) * 7 + (_time * 0.5).floor()) % 5 != 0;
        if (isLit) {
          final windowRect = Rect.fromLTWH(
            startX + wx * windowSpacing,
            startY + wy * windowSpacing,
            windowSize,
            windowSize - 1,
          );
          canvas.drawRect(windowRect, _cyberWindowGlowPaint);
          canvas.drawRect(windowRect, _cyberWindowPaint);
        }
      }
    }

    // Rooftop antenna/structure
    if ((x + y) % 4 == 0) {
      _cyberAntennaPaint.color = const Color(0xFF00FFFF).withOpacity(0.6);
      canvas.drawLine(
        Offset(rect.center.dx, rect.top + 2),
        Offset(rect.center.dx, rect.top - 4),
        _cyberAntennaPaint,
      );
      // Blinking light
      if (math.sin(_time * 4 + x) > 0) {
        _cyberBlinkPaint.color = const Color(0xFFFF0044);
        canvas.drawCircle(
            Offset(rect.center.dx, rect.top - 4), 2, _cyberBlinkPaint);
      }
    }

    // Neon edge trim
    _cyberEdgePaint.color = const Color(0xFF00FFFF).withOpacity(0.3);
    canvas.drawRect(buildingRect, _cyberEdgePaint);
  }

  void _drawServerRack(Canvas canvas, Rect rect, int x, int y) {
    // Dark base
    canvas.drawRect(rect, _serverBasePaint);

    // Rack frame
    canvas.drawRect(rect.deflate(3), _serverFramePaint);

    // Server slots with blinking lights
    final slotHeight = 5.0;
    final startY = rect.top + 6;

    for (int i = 0; i < 4; i++) {
      final slotY = startY + i * slotHeight;

      // Slot background
      canvas.drawRect(
        Rect.fromLTWH(rect.left + 5, slotY, rect.width - 10, slotHeight - 1),
        _serverSlotPaint,
      );

      // LED indicators
      for (int led = 0; led < 4; led++) {
        final ledActive = math.sin(_time * 3 + x + y + i * 2 + led) > 0;
        final ledColor = ledActive
            ? (led == 0 ? const Color(0xFF00FF00) : const Color(0xFF00FFFF))
            : const Color(0xFF333344);
        _serverLedPaint
          ..color = ledColor.withOpacity(ledActive ? 0.9 : 0.3)
          ..maskFilter = ledActive ? _blur2 : null;
        canvas.drawCircle(
          Offset(rect.left + 8 + led * 4, slotY + slotHeight / 2),
          1.5,
          _serverLedPaint,
        );
      }
    }

    // Ventilation grille at bottom
    _serverVentPaint.color = const Color(0xFF2a2a44).withOpacity(0.5);
    for (int v = 0; v < 5; v++) {
      canvas.drawLine(
        Offset(rect.left + 6 + v * 4, rect.bottom - 4),
        Offset(rect.left + 6 + v * 4, rect.bottom - 2),
        _serverVentPaint,
      );
    }
  }

  void _drawEnergyCore(Canvas canvas, Rect rect, int x, int y) {
    // Dark containment base
    canvas.drawRect(rect, _energyBasePaint);

    // Containment ring
    canvas.drawCircle(rect.center, rect.width * 0.35, _energyRingPaint);

    // Energy core - pulsing
    final pulseScale = 0.8 + math.sin(_time * 4 + x + y) * 0.2;
    final coreRadius = rect.width * 0.2 * pulseScale;

    // Core glow
    _energyGlowPaint.color = const Color(0xFFFF00FF).withOpacity(0.4);
    canvas.drawCircle(rect.center, coreRadius * 2, _energyGlowPaint);

    // Core inner
    _energyCorePaint.color = const Color(0xFFFF44FF).withOpacity(0.9);
    canvas.drawCircle(rect.center, coreRadius, _energyCorePaint);

    // Core bright center
    _energyCenterPaint.color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(rect.center, coreRadius * 0.4, _energyCenterPaint);

    // Energy arcs
    _energyArcPaint.color = const Color(0xFFFF00FF).withOpacity(0.6);

    for (int a = 0; a < 4; a++) {
      final angle = _time * 2 + a * math.pi / 2;
      final arcStart = Offset(
        rect.center.dx + math.cos(angle) * coreRadius,
        rect.center.dy + math.sin(angle) * coreRadius,
      );
      final arcEnd = Offset(
        rect.center.dx + math.cos(angle) * rect.width * 0.35,
        rect.center.dy + math.sin(angle) * rect.width * 0.35,
      );
      canvas.drawLine(arcStart, arcEnd, _energyArcPaint);
    }

    // Corner brackets
    _energyBracketPaint.color = const Color(0xFF00FFFF).withOpacity(0.5);
    _drawCornerBrackets(canvas, rect, 6, _energyBracketPaint);
  }

  void _drawDataNode(Canvas canvas, Rect rect, int x, int y) {
    // Dark base
    canvas.drawRect(rect, _dataBasePaint);

    // Hexagonal pattern overlay
    _dataHexPaint.color = const Color(0xFF00FFFF).withOpacity(0.1);

    // Draw hex grid pattern
    final hexSize = 8.0;
    for (double hx = rect.left; hx < rect.right; hx += hexSize * 1.5) {
      for (double hy = rect.top; hy < rect.bottom; hy += hexSize * 0.866) {
        _drawHexagon(canvas, Offset(hx, hy), hexSize * 0.4, _dataHexPaint);
      }
    }

    // Central data display
    final displayRect = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.6,
      height: rect.height * 0.5,
    );

    // Display background
    canvas.drawRect(displayRect, _dataDisplayBgPaint);

    // Display border glow
    _dataDisplayGlowPaint.color =
        const Color(0xFF00FFFF).withOpacity(0.4 + math.sin(_time * 3) * 0.2);
    canvas.drawRect(displayRect, _dataDisplayGlowPaint);

    // Scrolling data lines
    _dataLinePaint.color = const Color(0xFF00FF88).withOpacity(0.6);

    final dataOffset = (_time * 20) % 8;
    for (int line = 0; line < 3; line++) {
      final lineY = displayRect.top + 3 + line * 4 + dataOffset * 0.3;
      if (lineY < displayRect.bottom - 2) {
        final lineWidth = ((x + y + line) % 3 + 1) * 4.0;
        canvas.drawLine(
          Offset(displayRect.left + 2, lineY),
          Offset(displayRect.left + 2 + lineWidth, lineY),
          _dataLinePaint,
        );
      }
    }

    // Status indicators on corners
    _dataIndicatorPaint.color = const Color(0xFF00FF00).withOpacity(0.8);
    canvas.drawCircle(
        Offset(rect.left + 4, rect.top + 4), 2, _dataIndicatorPaint);
    canvas.drawCircle(
        Offset(rect.right - 4, rect.top + 4), 2, _dataIndicatorPaint);
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    _circuitPath.reset();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        _circuitPath.moveTo(point.dx, point.dy);
      } else {
        _circuitPath.lineTo(point.dx, point.dy);
      }
    }
    _circuitPath.close();
    canvas.drawPath(_circuitPath, paint);
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect, double size, Paint paint) {
    // Top-left
    canvas.drawLine(
        Offset(rect.left, rect.top + size), Offset(rect.left, rect.top), paint);
    canvas.drawLine(
        Offset(rect.left, rect.top), Offset(rect.left + size, rect.top), paint);
    // Top-right
    canvas.drawLine(Offset(rect.right - size, rect.top),
        Offset(rect.right, rect.top), paint);
    canvas.drawLine(Offset(rect.right, rect.top),
        Offset(rect.right, rect.top + size), paint);
    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom - size),
        Offset(rect.left, rect.bottom), paint);
    canvas.drawLine(Offset(rect.left, rect.bottom),
        Offset(rect.left + size, rect.bottom), paint);
    // Bottom-right
    canvas.drawLine(Offset(rect.right - size, rect.bottom),
        Offset(rect.right, rect.bottom), paint);
    canvas.drawLine(Offset(rect.right, rect.bottom),
        Offset(rect.right, rect.bottom - size), paint);
  }

  void _drawPathTile(Canvas canvas, Rect rect, int x, int y) {
    final tilePhase = x * 0.7 + y * 0.5;
    final cx = rect.center.dx;
    final cy = rect.center.dy;

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: DARK TECH BASE WITH GRADIENT
    // ═══════════════════════════════════════════════════════════════════════
    canvas.drawRect(rect, _pathTileBasePaint);

    // Subtle radial gradient from center (cached per tile size)
    final tileSize = Size(rect.width, rect.height);
    if (_pathTileGradientSize != tileSize || _pathTileGradientShader == null) {
      _pathTileGradientSize = tileSize;
      _pathTileGradientShader = ui.Gradient.radial(
        Offset(tileSize.width / 2, tileSize.height / 2),
        tileSize.width * 0.7,
        [
          const Color(0xFF100025),
          const Color(0xFF050010),
        ],
      );
    }
    _pathTileGradientPaint.shader = _pathTileGradientShader;
    canvas.save();
    canvas.translate(rect.left, rect.top);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, rect.width, rect.height), _pathTileGradientPaint);
    canvas.restore();

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: ANIMATED CIRCUIT TRACE PATTERNS (reduced intensity)
    // ═══════════════════════════════════════════════════════════════════════
    final circuitPattern = (x + y * 7) % 4;
    final traceAlpha = 0.15 + math.sin(_time * 2 + tilePhase) * 0.05;
    _circuitTracePaint.color = const Color(0xFFFF0088).withOpacity(traceAlpha);

    // Draw circuit traces based on pattern type
    if (circuitPattern == 0) {
      // Horizontal main trace with vertical branches
      canvas.drawLine(Offset(rect.left + 3, cy), Offset(rect.right - 3, cy),
          _circuitTracePaint);
      canvas.drawLine(
          Offset(cx - 6, cy), Offset(cx - 6, rect.top + 5), _circuitTracePaint);
      canvas.drawLine(Offset(cx + 6, cy), Offset(cx + 6, rect.bottom - 5),
          _circuitTracePaint);
      canvas.drawLine(Offset(cx - 6, rect.top + 5),
          Offset(cx - 2, rect.top + 5), _circuitTracePaint);
      canvas.drawLine(Offset(cx + 6, rect.bottom - 5),
          Offset(cx + 2, rect.bottom - 5), _circuitTracePaint);
    } else if (circuitPattern == 1) {
      // Vertical main trace with horizontal branches
      canvas.drawLine(Offset(cx, rect.top + 3), Offset(cx, rect.bottom - 3),
          _circuitTracePaint);
      canvas.drawLine(Offset(cx, cy - 6), Offset(rect.left + 5, cy - 6),
          _circuitTracePaint);
      canvas.drawLine(Offset(cx, cy + 6), Offset(rect.right - 5, cy + 6),
          _circuitTracePaint);
    } else if (circuitPattern == 2) {
      // L-shaped traces from corners
      canvas.drawLine(Offset(rect.left + 4, rect.top + 4),
          Offset(rect.left + 4, cy), _circuitTracePaint);
      canvas.drawLine(
          Offset(rect.left + 4, cy), Offset(cx, cy), _circuitTracePaint);
      canvas.drawLine(Offset(rect.right - 4, rect.bottom - 4),
          Offset(rect.right - 4, cy), _circuitTracePaint);
      canvas.drawLine(
          Offset(rect.right - 4, cy), Offset(cx, cy), _circuitTracePaint);
    } else {
      // Cross pattern
      canvas.drawLine(Offset(rect.left + 4, rect.top + 4),
          Offset(rect.right - 4, rect.bottom - 4), _circuitTracePaint);
      canvas.drawLine(Offset(rect.right - 4, rect.top + 4),
          Offset(rect.left + 4, rect.bottom - 4), _circuitTracePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: FLOWING DATA PULSES ALONG CIRCUITS (reduced intensity)
    // ═══════════════════════════════════════════════════════════════════════
    final dataFlowPhase = (_time * 80 + tilePhase * 20) % rect.width;
    final dataAlpha = 0.3 + math.sin(_time * 8 + tilePhase) * 0.1;

    // Data pulse glow
    _circuitGlowPaint.color =
        const Color(0xFFFF00AA).withOpacity(dataAlpha * 0.2);
    final dataX = rect.left + dataFlowPhase;
    if (dataX < rect.right - 3) {
      canvas.drawCircle(Offset(dataX, cy), 3, _circuitGlowPaint);
      _circuitPulsePaint.color =
          const Color(0xFFFFFFFF).withOpacity(dataAlpha * 0.4);
      canvas.drawCircle(Offset(dataX, cy), 1.5, _circuitPulsePaint);
    }

    // Secondary data pulse (vertical)
    final dataFlowPhaseV = (_time * 60 + tilePhase * 15) % rect.height;
    final dataY = rect.top + dataFlowPhaseV;
    if (dataY < rect.bottom - 3) {
      canvas.drawCircle(Offset(cx, dataY), 2.5, _circuitGlowPaint);
      canvas.drawCircle(Offset(cx, dataY), 1, _circuitPulsePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: JUNCTION NODES WITH ANIMATION (reduced intensity)
    // ═══════════════════════════════════════════════════════════════════════
    final nodePhase = _time * 3 + tilePhase;
    final nodePulse = 0.25 + math.sin(nodePhase) * 0.1;

    // Corner junction nodes
    final junctionTopLeft = Offset(rect.left + 5, rect.top + 5);
    final junctionTopRight = Offset(rect.right - 5, rect.top + 5);
    final junctionBottomLeft = Offset(rect.left + 5, rect.bottom - 5);
    final junctionBottomRight = Offset(rect.right - 5, rect.bottom - 5);
    final junctionAlpha0 = nodePulse * (0.4 + math.sin(nodePhase) * 0.1);
    final junctionAlpha1 = nodePulse * (0.4 + math.sin(nodePhase + 1) * 0.1);
    final junctionAlpha2 = nodePulse * (0.4 + math.sin(nodePhase + 2) * 0.1);
    final junctionAlpha3 = nodePulse * (0.4 + math.sin(nodePhase + 3) * 0.1);

    _circuitJunctionPaint.color =
        const Color(0xFFFF0066).withOpacity(junctionAlpha0 * 0.25);
    canvas.drawCircle(junctionTopLeft, 4, _circuitJunctionPaint);
    _circuitNodePaint.color =
        const Color(0xFFFF4488).withOpacity(junctionAlpha0 * 0.5);
    canvas.drawCircle(junctionTopLeft, 2, _circuitNodePaint);
    _circuitNodePaint.color =
        const Color(0xFFFFFFFF).withOpacity(junctionAlpha0 * 0.4);
    canvas.drawCircle(junctionTopLeft, 0.8, _circuitNodePaint);

    _circuitJunctionPaint.color =
        const Color(0xFFFF0066).withOpacity(junctionAlpha1 * 0.25);
    canvas.drawCircle(junctionTopRight, 4, _circuitJunctionPaint);
    _circuitNodePaint.color =
        const Color(0xFFFF4488).withOpacity(junctionAlpha1 * 0.5);
    canvas.drawCircle(junctionTopRight, 2, _circuitNodePaint);
    _circuitNodePaint.color =
        const Color(0xFFFFFFFF).withOpacity(junctionAlpha1 * 0.4);
    canvas.drawCircle(junctionTopRight, 0.8, _circuitNodePaint);

    _circuitJunctionPaint.color =
        const Color(0xFFFF0066).withOpacity(junctionAlpha2 * 0.25);
    canvas.drawCircle(junctionBottomLeft, 4, _circuitJunctionPaint);
    _circuitNodePaint.color =
        const Color(0xFFFF4488).withOpacity(junctionAlpha2 * 0.5);
    canvas.drawCircle(junctionBottomLeft, 2, _circuitNodePaint);
    _circuitNodePaint.color =
        const Color(0xFFFFFFFF).withOpacity(junctionAlpha2 * 0.4);
    canvas.drawCircle(junctionBottomLeft, 0.8, _circuitNodePaint);

    _circuitJunctionPaint.color =
        const Color(0xFFFF0066).withOpacity(junctionAlpha3 * 0.25);
    canvas.drawCircle(junctionBottomRight, 4, _circuitJunctionPaint);
    _circuitNodePaint.color =
        const Color(0xFFFF4488).withOpacity(junctionAlpha3 * 0.5);
    canvas.drawCircle(junctionBottomRight, 2, _circuitNodePaint);
    _circuitNodePaint.color =
        const Color(0xFFFFFFFF).withOpacity(junctionAlpha3 * 0.4);
    canvas.drawCircle(junctionBottomRight, 0.8, _circuitNodePaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: MICROCHIP COMPONENT IN CENTER (reduced intensity)
    // ═══════════════════════════════════════════════════════════════════════
    final chipSize = 8.0;
    final chipRect = Rect.fromCenter(
        center: Offset(cx, cy), width: chipSize, height: chipSize);

    // Chip glow
    _circuitEnergyPaint.color = const Color(0xFFFF0066)
        .withOpacity(0.15 + math.sin(_time * 4 + tilePhase) * 0.05);
    canvas.drawRect(chipRect.inflate(2), _circuitEnergyPaint);

    // Chip body
    _circuitChipPaint.color = const Color(0xFF150030);
    canvas.drawRect(chipRect, _circuitChipPaint);

    // Chip border
    _circuitChipBorderPaint.color = const Color(0xFFFF0088).withOpacity(0.3);
    canvas.drawRect(chipRect, _circuitChipBorderPaint);

    // Chip pins (connections to traces)
    _circuitTracePaint.color = const Color(0xFFFF4488).withOpacity(0.25);
    final pinLength = 3.0;
    // Top pins
    canvas.drawLine(Offset(cx - 2, chipRect.top),
        Offset(cx - 2, chipRect.top - pinLength), _circuitTracePaint);
    canvas.drawLine(Offset(cx + 2, chipRect.top),
        Offset(cx + 2, chipRect.top - pinLength), _circuitTracePaint);
    // Bottom pins
    canvas.drawLine(Offset(cx - 2, chipRect.bottom),
        Offset(cx - 2, chipRect.bottom + pinLength), _circuitTracePaint);
    canvas.drawLine(Offset(cx + 2, chipRect.bottom),
        Offset(cx + 2, chipRect.bottom + pinLength), _circuitTracePaint);
    // Left pins
    canvas.drawLine(Offset(chipRect.left, cy - 2),
        Offset(chipRect.left - pinLength, cy - 2), _circuitTracePaint);
    canvas.drawLine(Offset(chipRect.left, cy + 2),
        Offset(chipRect.left - pinLength, cy + 2), _circuitTracePaint);
    // Right pins
    canvas.drawLine(Offset(chipRect.right, cy - 2),
        Offset(chipRect.right + pinLength, cy - 2), _circuitTracePaint);
    canvas.drawLine(Offset(chipRect.right, cy + 2),
        Offset(chipRect.right + pinLength, cy + 2), _circuitTracePaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: HEXAGONAL GRID OVERLAY (reduced intensity)
    // ═══════════════════════════════════════════════════════════════════════
    final hexAlpha = 0.06 + math.sin(_time * 1.5 + tilePhase) * 0.02;
    _circuitHexPaint.color = const Color(0xFFFF00AA).withOpacity(hexAlpha);

    // Draw small hexagons in corners
    for (int hx = 0; hx < 2; hx++) {
      for (int hy = 0; hy < 2; hy++) {
        final hexCx = rect.left + 8 + hx * (rect.width - 16);
        final hexCy = rect.top + 8 + hy * (rect.height - 16);
        _drawMiniHex(canvas, hexCx, hexCy, 4);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: ENERGY FLOW WAVES (reduced intensity)
    // ═══════════════════════════════════════════════════════════════════════
    final wavePhase = _time * 5 + tilePhase;
    for (int wave = 0; wave < 2; wave++) {
      final waveProgress = ((wavePhase + wave * 0.5) % 1.0);
      final waveAlpha = (1 - waveProgress) * 0.1;
      final waveRadius = 3 + waveProgress * 12;

      _circuitEnergyPaint.color =
          const Color(0xFFFF0088).withOpacity(waveAlpha);
      _circuitPath.reset();
      _circuitPath
          .addOval(Rect.fromCircle(center: Offset(cx, cy), radius: waveRadius));
      canvas.drawPath(
          _circuitPath,
          _circuitEnergyPaint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
      _circuitEnergyPaint.style = PaintingStyle.fill;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 8: DATA STREAM PARTICLES (reduced intensity)
    // ═══════════════════════════════════════════════════════════════════════
    for (int particle = 0; particle < 3; particle++) {
      final particlePhase = _time * 4 + particle * 1.5 + tilePhase;
      final particleProgress = (particlePhase % 1.0);
      final particleAlpha = (1 - particleProgress) * 0.25;

      // Particles moving along different paths
      final particleX = rect.left + 4 + particleProgress * (rect.width - 8);
      final particleY =
          rect.top + 6 + particle * 8 + math.sin(particlePhase * 3) * 2;

      if (particleY < rect.bottom - 4) {
        _circuitPulsePaint.color =
            const Color(0xFFFF44AA).withOpacity(particleAlpha);
        canvas.drawCircle(
            Offset(particleX, particleY), 1.2, _circuitPulsePaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 9: NEON BORDER WITH ANIMATED CORNERS (reduced intensity)
    // ═══════════════════════════════════════════════════════════════════════
    final borderAlpha = 0.2 + math.sin(_time * 3 + tilePhase) * 0.05;

    // Outer border glow
    _circuitGlowPaint.color =
        const Color(0xFFFF0066).withOpacity(borderAlpha * 0.15);
    canvas.drawRect(
        rect.deflate(1),
        _circuitGlowPaint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    _circuitGlowPaint.style = PaintingStyle.fill;

    // Core border
    _circuitTracePaint.color =
        const Color(0xFFFF0088).withOpacity(borderAlpha * 0.5);
    _circuitTracePaint.strokeWidth = 1.5;
    canvas.drawRect(rect.deflate(2), _circuitTracePaint);

    // Animated corner highlights
    final cornerLength = 6.0;
    final cornerAlpha = 0.3 + math.sin(_time * 6 + tilePhase) * 0.1;
    _circuitDataFlowPaint.color =
        const Color(0xFFFFFFFF).withOpacity(cornerAlpha);

    // Top-left corner
    canvas.drawLine(
        Offset(rect.left + 2, rect.top + 2),
        Offset(rect.left + 2 + cornerLength, rect.top + 2),
        _circuitDataFlowPaint);
    canvas.drawLine(
        Offset(rect.left + 2, rect.top + 2),
        Offset(rect.left + 2, rect.top + 2 + cornerLength),
        _circuitDataFlowPaint);

    // Top-right corner
    canvas.drawLine(
        Offset(rect.right - 2, rect.top + 2),
        Offset(rect.right - 2 - cornerLength, rect.top + 2),
        _circuitDataFlowPaint);
    canvas.drawLine(
        Offset(rect.right - 2, rect.top + 2),
        Offset(rect.right - 2, rect.top + 2 + cornerLength),
        _circuitDataFlowPaint);

    // Bottom-left corner
    canvas.drawLine(
        Offset(rect.left + 2, rect.bottom - 2),
        Offset(rect.left + 2 + cornerLength, rect.bottom - 2),
        _circuitDataFlowPaint);
    canvas.drawLine(
        Offset(rect.left + 2, rect.bottom - 2),
        Offset(rect.left + 2, rect.bottom - 2 - cornerLength),
        _circuitDataFlowPaint);

    // Bottom-right corner
    canvas.drawLine(
        Offset(rect.right - 2, rect.bottom - 2),
        Offset(rect.right - 2 - cornerLength, rect.bottom - 2),
        _circuitDataFlowPaint);
    canvas.drawLine(
        Offset(rect.right - 2, rect.bottom - 2),
        Offset(rect.right - 2, rect.bottom - 2 - cornerLength),
        _circuitDataFlowPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 10: CENTRAL PROCESSOR GLOW (reduced intensity)
    // ═══════════════════════════════════════════════════════════════════════
    final processorPulse = 0.2 + math.sin(_time * 6 + tilePhase) * 0.1;

    // Deep outer glow
    _circuitEnergyPaint.color =
        const Color(0xFFFF0066).withOpacity(processorPulse * 0.15);
    canvas.drawCircle(Offset(cx, cy), 6, _circuitEnergyPaint);

    // Inner bright core
    _circuitPulsePaint.color =
        const Color(0xFFFF4488).withOpacity(processorPulse * 0.3);
    canvas.drawCircle(Offset(cx, cy), 2.5, _circuitPulsePaint);

    // White hot center
    _circuitPulsePaint.color =
        const Color(0xFFFFFFFF).withOpacity(processorPulse * 0.4);
    canvas.drawCircle(Offset(cx, cy), 1, _circuitPulsePaint);
  }

  void _drawMiniHex(Canvas canvas, double cx, double cy, double radius) {
    _circuitPath.reset();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final px = cx + math.cos(angle) * radius;
      final py = cy + math.sin(angle) * radius;
      if (i == 0) {
        _circuitPath.moveTo(px, py);
      } else {
        _circuitPath.lineTo(px, py);
      }
    }
    _circuitPath.close();
    canvas.drawPath(_circuitPath, _circuitHexPaint);
  }

  void _drawBuildableTile(Canvas canvas, Rect rect, int x, int y) {
    // Dark tech floor base
    canvas.drawRect(rect, _buildableBasePaint);

    // Subtle tech pattern based on position
    final patternType = (x + y * 3) % 5;

    if (patternType == 0) {
      // Circuit trace pattern
      _drawCircuitPattern(canvas, rect, x, y);
    } else if (patternType == 1) {
      // Hex grid pattern
      _drawHexGridPattern(canvas, rect);
    } else if (patternType == 2) {
      // Diamond pattern
      _drawDiamondPattern(canvas, rect, x, y);
    } else {
      // Standard grid with nodes
      _drawStandardGrid(canvas, rect, x, y);
    }

    // Outer grid border - always present
    _buildableGridPaint.color = const Color(0xFF00FFFF).withOpacity(0.12);
    canvas.drawRect(rect.deflate(1), _buildableGridPaint);

    // Corner anchor points
    _buildableAnchorGlowPaint.color = const Color(0xFF00FFFF).withOpacity(0.2);
    _buildableAnchorCorePaint.color = const Color(0xFF00FFFF).withOpacity(0.4);
    final topLeft = Offset(rect.left + 3, rect.top + 3);
    final topRight = Offset(rect.right - 3, rect.top + 3);
    final bottomLeft = Offset(rect.left + 3, rect.bottom - 3);
    final bottomRight = Offset(rect.right - 3, rect.bottom - 3);
    canvas.drawCircle(topLeft, 2.5, _buildableAnchorGlowPaint);
    canvas.drawCircle(topLeft, 1.2, _buildableAnchorCorePaint);
    canvas.drawCircle(topRight, 2.5, _buildableAnchorGlowPaint);
    canvas.drawCircle(topRight, 1.2, _buildableAnchorCorePaint);
    canvas.drawCircle(bottomLeft, 2.5, _buildableAnchorGlowPaint);
    canvas.drawCircle(bottomLeft, 1.2, _buildableAnchorCorePaint);
    canvas.drawCircle(bottomRight, 2.5, _buildableAnchorGlowPaint);
    canvas.drawCircle(bottomRight, 1.2, _buildableAnchorCorePaint);

    // Random data flicker effect
    if ((x * 7 + y * 11 + (_time * 2).floor()) % 23 == 0) {
      _buildableFlickerPaint.color = const Color(0xFF00FFFF).withOpacity(0.08);
      canvas.drawRect(rect, _buildableFlickerPaint);
    }
  }

  void _drawCircuitPattern(Canvas canvas, Rect rect, int x, int y) {
    _buildableTracePaint.color = const Color(0xFF00FFFF).withOpacity(0.15);

    final cx = rect.center.dx;
    final cy = rect.center.dy;

    // Horizontal trace
    canvas.drawLine(
      Offset(rect.left + 4, cy),
      Offset(rect.right - 4, cy),
      _buildableTracePaint,
    );

    // Vertical trace with break
    canvas.drawLine(
      Offset(cx, rect.top + 4),
      Offset(cx, cy - 4),
      _buildableTracePaint,
    );
    canvas.drawLine(
      Offset(cx, cy + 4),
      Offset(cx, rect.bottom - 4),
      _buildableTracePaint,
    );

    // Center node
    _buildableNodePaint.color = const Color(0xFF00FFFF)
        .withOpacity(0.25 + math.sin(_time * 2 + x + y) * 0.1);
    canvas.drawCircle(Offset(cx, cy), 2, _buildableNodePaint);
  }

  void _drawHexGridPattern(Canvas canvas, Rect rect) {
    _buildableHexPaint.color = const Color(0xFF00FFFF).withOpacity(0.08);

    final hexSize = 6.0;
    final cx = rect.center.dx;
    final cy = rect.center.dy;

    // Draw a single hex at center
    _drawHexagon(canvas, Offset(cx, cy), hexSize, _buildableHexPaint);

    // Corner hexes (partial)
    _drawHexagon(canvas, Offset(cx - hexSize * 1.5, cy - hexSize * 0.866),
        hexSize * 0.5, _buildableHexPaint);
    _drawHexagon(canvas, Offset(cx + hexSize * 1.5, cy - hexSize * 0.866),
        hexSize * 0.5, _buildableHexPaint);
    _drawHexagon(canvas, Offset(cx - hexSize * 1.5, cy + hexSize * 0.866),
        hexSize * 0.5, _buildableHexPaint);
    _drawHexagon(canvas, Offset(cx + hexSize * 1.5, cy + hexSize * 0.866),
        hexSize * 0.5, _buildableHexPaint);
  }

  void _drawDiamondPattern(Canvas canvas, Rect rect, int x, int y) {
    _buildableDiamondPaint.color = const Color(0xFF00FFFF).withOpacity(0.1);

    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final size = 8.0;

    _buildableDiamondPath
      ..reset()
      ..moveTo(cx, cy - size)
      ..lineTo(cx + size, cy)
      ..lineTo(cx, cy + size)
      ..lineTo(cx - size, cy)
      ..close();
    canvas.drawPath(_buildableDiamondPath, _buildableDiamondPaint);

    // Inner diamond
    _buildableDiamondInnerPath
      ..reset()
      ..moveTo(cx, cy - size * 0.5)
      ..lineTo(cx + size * 0.5, cy)
      ..lineTo(cx, cy + size * 0.5)
      ..lineTo(cx - size * 0.5, cy)
      ..close();
    _buildableDiamondInnerPaint.color =
        const Color(0xFF00FFFF).withOpacity(0.06 + math.sin(_time + x) * 0.02);
    canvas.drawPath(_buildableDiamondInnerPath, _buildableDiamondInnerPaint);
  }

  void _drawStandardGrid(Canvas canvas, Rect rect, int x, int y) {
    // Cross pattern
    _buildableCrossPaint.color = const Color(0xFF00FFFF).withOpacity(0.08);

    final cx = rect.center.dx;
    final cy = rect.center.dy;

    canvas.drawLine(
        Offset(cx - 6, cy), Offset(cx + 6, cy), _buildableCrossPaint);
    canvas.drawLine(
        Offset(cx, cy - 6), Offset(cx, cy + 6), _buildableCrossPaint);

    // Tick marks at edges
    canvas.drawLine(Offset(rect.left + 2, cy), Offset(rect.left + 5, cy),
        _buildableCrossPaint);
    canvas.drawLine(Offset(rect.right - 5, cy), Offset(rect.right - 2, cy),
        _buildableCrossPaint);
    canvas.drawLine(Offset(cx, rect.top + 2), Offset(cx, rect.top + 5),
        _buildableCrossPaint);
    canvas.drawLine(Offset(cx, rect.bottom - 5), Offset(cx, rect.bottom - 2),
        _buildableCrossPaint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEXAGONAL GRID OVERLAY
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawHexagonalGridOverlay(Canvas canvas) {
    if (world.reduceFx) return; // Skip on low quality

    _ensureHexCache();

    final worldWidth = _hexCachedWorldWidth;
    final worldHeight = _hexCachedWorldHeight;
    const hexRadius = 25.0;
    final hexHeight = hexRadius * math.sqrt(3);
    final verticalSpacing = hexHeight;
    final rowCount = (worldHeight / verticalSpacing).ceil() + 1;
    // Cached geometry already prepared in _ensureHexCache().

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, worldWidth, worldHeight));

    // Base grid color with subtle animation
    final baseAlpha = 0.03 + math.sin(_time * 0.5) * 0.01;
    final glowAlpha = 0.05 + math.sin(_time * 0.8) * 0.02;

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: BASE HEXAGONAL GRID LINES
    // ═══════════════════════════════════════════════════════════════════════
    _hexGridPaint.color = const Color(0xFF00FFFF).withOpacity(baseAlpha);

    canvas.drawPath(_hexGridPath, _hexGridPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: GLOWING HIGHLIGHT HEXAGONS (sparse, animated)
    // ═══════════════════════════════════════════════════════════════════════
    _hexGridGlowPaint.color = const Color(0xFF00FFFF).withOpacity(glowAlpha);

    // Highlight every Nth hexagon with phase offset
    for (int i = 0; i < _hexHighlightIndices.length; i++) {
      final highlightPhase = math.sin(_time * 2 + _hexHighlightPhaseSeeds[i]);
      if (highlightPhase < 0.3) continue; // Only show some hexagons

      final highlightAlpha = glowAlpha * highlightPhase;
      _hexGridGlowPaint.color =
          const Color(0xFF00FFFF).withOpacity(highlightAlpha);
      canvas.drawPath(_hexPaths[_hexHighlightIndices[i]], _hexGridGlowPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: CORNER NODES (subtle dots at intersections)
    // ═══════════════════════════════════════════════════════════════════════
    _hexGridCornerPaint.color =
        const Color(0xFF00FFFF).withOpacity(baseAlpha * 2);

    canvas.drawPath(_hexCornerPath, _hexGridCornerPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: ANIMATED PULSE RINGS (traveling outward)
    // ═══════════════════════════════════════════════════════════════════════
    final pulseCount = 3;
    for (int p = 0; p < pulseCount; p++) {
      final pulsePhase = (_time * 0.3 + p * 0.33) % 1.0;
      final pulseCenterX = worldWidth * (0.2 + p * 0.3);
      final pulseCenterY = worldHeight * (0.3 + p * 0.2);
      final pulseRadius = pulsePhase * math.max(worldWidth, worldHeight) * 0.4;
      final pulseAlpha = (1 - pulsePhase) * 0.08;

      _hexGridPulsePaint.color =
          const Color(0xFF00FFFF).withOpacity(pulseAlpha);
      canvas.drawCircle(
          Offset(pulseCenterX, pulseCenterY), pulseRadius, _hexGridPulsePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: ENERGY FLOW LINES BETWEEN HEXAGONS
    // ═══════════════════════════════════════════════════════════════════════
    final flowPhase = (_time * 2) % 1.0;
    _hexGridEnergyPaint.color = const Color(0xFFFF00FF).withOpacity(0.04);

    // Draw horizontal flow lines
    for (int row = 0; row < rowCount; row += 4) {
      final y = row * verticalSpacing;
      final flowX = flowPhase * worldWidth;

      for (int i = 0; i < 5; i++) {
        final lineX = (flowX + i * worldWidth * 0.2) % worldWidth;
        final lineLength = 30 + math.sin(_time * 3 + i) * 15;

        canvas.drawLine(
          Offset(lineX, y),
          Offset(lineX + lineLength, y),
          _hexGridEnergyPaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: HIGHLIGHT CELLS NEAR ACTIVITY (towers, enemies)
    // ═══════════════════════════════════════════════════════════════════════
    // Create a subtle aura effect in active regions
    for (int i = 0; i < 3; i++) {
      final highlightX = worldWidth * (0.3 + math.sin(_time * 0.5 + i) * 0.2);
      final highlightY = worldHeight * (0.3 + math.cos(_time * 0.4 + i) * 0.2);
      final pos = Offset(highlightX, highlightY);
      final auraAlpha = 0.02 + math.sin(_time * 4) * 0.01;
      _hexGridAuraPaint.color = const Color(0xFF00FFFF).withOpacity(auraAlpha);
      canvas.drawCircle(pos, hexRadius * 2, _hexGridAuraPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: SECONDARY MAGENTA ACCENT HEXAGONS
    // ═══════════════════════════════════════════════════════════════════════
    final magentaAlpha = 0.02 + math.sin(_time * 1.2 + 2) * 0.01;
    _hexGridHighlightPaint.color =
        const Color(0xFFFF00FF).withOpacity(magentaAlpha);

    canvas.drawPath(_hexAccentPath, _hexGridHighlightPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 8: SCANNING LINE EFFECT
    // ═══════════════════════════════════════════════════════════════════════
    final scanY = (_time * 50) % worldHeight;
    final scanAlpha = 0.03;
    _hexGridEnergyPaint.color = const Color(0xFF00FFFF).withOpacity(scanAlpha);
    canvas.drawLine(
      Offset(0, scanY),
      Offset(worldWidth, scanY),
      _hexGridEnergyPaint,
    );

    // Trailing fade lines
    for (int trail = 1; trail < 4; trail++) {
      final trailY = scanY - trail * 5;
      if (trailY > 0) {
        _hexGridEnergyPaint.color =
            const Color(0xFF00FFFF).withOpacity(scanAlpha * (1 - trail * 0.25));
        canvas.drawLine(
          Offset(0, trailY),
          Offset(worldWidth, trailY),
          _hexGridEnergyPaint,
        );
      }
    }

    canvas.restore();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PULSING ENERGY VEINS
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawPulsingEnergyVeins(Canvas canvas) {
    if (world.reduceFx) return;
    _ensureVeinCache();
    final worldWidth = world.tileSize * world.mapWidth.toDouble();
    final worldHeight = world.tileSize * world.mapHeight.toDouble();
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, worldWidth, worldHeight));

    // Animation parameters
    final pulsePhase = (_time * 1.5) % 1.0;
    final baseBrightness = 0.3 + math.sin(_time * 2) * 0.1;

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: VEIN AURA (deep glow)
    // ═══════════════════════════════════════════════════════════════════════
    for (int v = 0; v < _veinPaths.length; v++) {
      if (_veinPaths[v].length < 2) continue;

      final veinColor =
          v % 2 == 0 ? const Color(0xFF00FFFF) : const Color(0xFFFF00FF);
      final auraAlpha = 0.02 + math.sin(_time * 1.5 + v) * 0.01;
      _veinAuraPaint.color = veinColor.withOpacity(auraAlpha);
      _veinAuraPaint.style = PaintingStyle.stroke;
      _veinAuraPaint.strokeWidth = 20;
      canvas.drawPath(_veinPathCache[v], _veinAuraPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: MAIN VEIN GLOW
    // ═══════════════════════════════════════════════════════════════════════
    for (int v = 0; v < _veinPaths.length; v++) {
      if (_veinPaths[v].length < 2) continue;

      final veinColor =
          v % 2 == 0 ? const Color(0xFF00FFFF) : const Color(0xFFFF00FF);
      final glowAlpha = (0.05 + baseBrightness * 0.05);
      _veinGlowPaint.color = veinColor.withOpacity(glowAlpha);

      canvas.drawPath(_veinPathCache[v], _veinGlowPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: VEIN CORE (bright center line)
    // ═══════════════════════════════════════════════════════════════════════
    for (int v = 0; v < _veinPaths.length; v++) {
      if (_veinPaths[v].length < 2) continue;

      final veinColor =
          v % 2 == 0 ? const Color(0xFF00FFFF) : const Color(0xFFFF00FF);
      final coreAlpha = (0.1 + baseBrightness * 0.1);
      _veinCorePaint.color = veinColor.withOpacity(coreAlpha);

      canvas.drawPath(_veinPathCache[v], _veinCorePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: TRAVELING PULSES ALONG VEINS
    // ═══════════════════════════════════════════════════════════════════════
    for (int v = 0; v < _veinPaths.length; v++) {
      if (_veinPaths[v].length < 2) continue;

      final veinColor =
          v % 2 == 0 ? const Color(0xFF00FFFF) : const Color(0xFFFF00FF);

      // Calculate pulse position along path
      final veinPulsePhase = (pulsePhase + v * 0.15) % 1.0;
      final totalLength = _veinPathLengths[v];
      final pulseDistance = veinPulsePhase * totalLength;

      // Find pulse position
      final pulsePos = _getVeinPositionAlongPath(v, pulseDistance);

      // Draw pulse glow
      final pulseAlpha = 0.15 + math.sin(_time * 8 + v) * 0.05;
      _veinPulsePaint.color = veinColor.withOpacity(pulseAlpha);
      canvas.drawCircle(pulsePos, 8, _veinPulsePaint);

      // Draw pulse core
      _veinNodePaint.color = Colors.white.withOpacity(pulseAlpha * 1.5);
      canvas.drawCircle(pulsePos, 3, _veinNodePaint);

      // Draw secondary pulses
      final secondaryPhase = (veinPulsePhase + 0.5) % 1.0;
      final secondaryDistance = secondaryPhase * totalLength;
      final secondaryPos = _getVeinPositionAlongPath(v, secondaryDistance);

      _veinPulsePaint.color = veinColor.withOpacity(pulseAlpha * 0.6);
      canvas.drawCircle(secondaryPos, 5, _veinPulsePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: JUNCTION NODES
    // ═══════════════════════════════════════════════════════════════════════
    // Calculate intersections and draw glowing nodes
    for (int n = 0; n < _veinNodes.length; n++) {
      final pos = _veinNodes[n];
      final nodePulse = 0.5 + math.sin(_time * 3 + n * 0.7) * 0.5;
      final nodeColor =
          n % 2 == 0 ? const Color(0xFF00FFFF) : const Color(0xFFFF00FF);

      // Node glow
      _veinNodePaint.color = nodeColor.withOpacity(nodePulse * 0.15);
      canvas.drawCircle(pos, 10, _veinNodePaint);

      // Node core
      _veinNodePaint.color = nodeColor.withOpacity(nodePulse * 0.3);
      canvas.drawCircle(pos, 4, _veinNodePaint);

      // Node center
      _veinNodePaint.color = Colors.white.withOpacity(nodePulse * 0.5);
      canvas.drawCircle(pos, 2, _veinNodePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: BRANCH VEINS (smaller offshoots)
    // ═══════════════════════════════════════════════════════════════════════
    final branchAlpha = 0.03 + math.sin(_time * 2.5) * 0.02;
    _veinBranchPaint.color = const Color(0xFF00FFFF).withOpacity(branchAlpha);

    // Draw small branch lines from nodes
    for (int n = 0; n < _veinNodes.length; n++) {
      final pos = _veinNodes[n];
      final branchCount = 3 + (n % 2);

      for (int b = 0; b < branchCount; b++) {
        final angle = (b * math.pi * 2 / branchCount) + _time * 0.1;
        final branchLength = 20 + math.sin(_time * 2 + b) * 10;
        final endX = pos.dx + math.cos(angle) * branchLength;
        final endY = pos.dy + math.sin(angle) * branchLength;

        canvas.drawLine(pos, Offset(endX, endY), _veinBranchPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: ENERGY SPARKS
    // ═══════════════════════════════════════════════════════════════════════
    final sparkCount = 6;
    for (int s = 0; s < sparkCount; s++) {
      final sparkPhase = (_time * 4 + s * 0.5) % 1.0;
      final pathIndex = s % _veinPaths.length;
      if (_veinPaths[pathIndex].length < 2) continue;

      final totalLength = _veinPathLengths[pathIndex];
      final sparkDistance = sparkPhase * totalLength;
      final sparkPos = _getVeinPositionAlongPath(pathIndex, sparkDistance);

      // Add small random offset
      final offsetX = math.sin(_time * 10 + s) * 3;
      final offsetY = math.cos(_time * 12 + s) * 3;

      final sparkAlpha = (1 - sparkPhase) * 0.3;
      _veinSparkPaint.color = Colors.white.withOpacity(sparkAlpha);
      canvas.drawCircle(
        Offset(sparkPos.dx + offsetX, sparkPos.dy + offsetY),
        2,
        _veinSparkPaint,
      );
    }
    canvas.restore();
  }

  Offset _getVeinPositionAlongPath(int pathIndex, double distance) {
    final path = _veinPaths[pathIndex];
    if (path.isEmpty) return Offset.zero;
    if (path.length < 2) return path.last;

    final totalLength = _veinPathLengths[pathIndex];
    if (distance <= 0) return path.first;
    if (distance >= totalLength) return path.last;

    final segmentLengths = _veinSegmentLengths[pathIndex];
    final segmentStarts = _veinSegmentStarts[pathIndex];
    for (int i = 0; i < segmentLengths.length; i++) {
      final segmentLength = segmentLengths[i];
      if (segmentLength <= 0) continue;
      final segmentStart = segmentStarts[i];
      final segmentEnd = segmentStart + segmentLength;
      if (distance <= segmentEnd) {
        final t = (distance - segmentStart) / segmentLength;
        final start = path[i];
        final end = path[i + 1];
        return Offset(
          start.dx + (end.dx - start.dx) * t,
          start.dy + (end.dy - start.dy) * t,
        );
      }
    }

    return path.last;
  }

  void _drawPathOverlay(Canvas canvas) {
    if (world.waypoints.length < 2) return;
    _ensurePathCache();
    if (_pathOverlay == null) return;
    final worldWidth = world.tileSize * world.mapWidth.toDouble();
    final worldHeight = world.tileSize * world.mapHeight.toDouble();
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, worldWidth, worldHeight));
    _ensurePathStaticLayer();
    if (_pathStaticLayer != null) {
      canvas.drawPicture(_pathStaticLayer!);
    }

    // Animated energy pulses
    _drawEnergyPulses(canvas);
    canvas.restore();
  }

  void _ensurePathStaticLayer() {
    if (_pathOverlay == null) return;
    final reduceFx = world.reduceFx;
    final allowBlur = world.allowBlur;
    if (!_pathStaticDirty &&
        _pathStaticLayer != null &&
        reduceFx == _lastReduceFx &&
        allowBlur == _lastAllowBlur) {
      return;
    }

    _pathStaticLayer?.dispose();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final path = _pathOverlay!;

    // Outer glow - wide and diffuse
    _pathOuterGlowPaint.maskFilter = allowBlur ? _blur10 : null;
    if (!reduceFx) {
      canvas.drawPath(path, _pathOuterGlowPaint);
    }

    // Middle glow
    _pathMiddleGlowPaint.maskFilter = allowBlur ? _blur4 : null;
    canvas.drawPath(path, _pathMiddleGlowPaint);

    // Core line - bright
    canvas.drawPath(path, _pathCorePaint);

    // Waypoint nodes
    _drawWaypointNodes(canvas);

    _pathStaticLayer = recorder.endRecording();
    _pathStaticDirty = false;
    _lastReduceFx = reduceFx;
    _lastAllowBlur = allowBlur;
  }

  void _drawWaypointNodes(Canvas canvas) {
    _nodeGlowPaint.maskFilter = world.allowBlur ? _blur6 : null;

    for (int i = 0; i < world.waypoints.length; i++) {
      final pos = world.waypoints[i];
      final isCorner = i > 0 && i < world.waypoints.length - 1;

      if (isCorner) {
        // Corner node - junction point
        if (!world.reduceFx) {
          canvas.drawCircle(Offset(pos.x, pos.y), 8, _nodeGlowPaint);
        }
        canvas.drawCircle(Offset(pos.x, pos.y), 6, _nodeRingPaint);
        canvas.drawCircle(Offset(pos.x, pos.y), 3, _nodeCorePaint);
      }
    }
  }

  void _drawEnergyPulses(Canvas canvas) {
    if (_pathLength <= 0) return;

    // Set MaskFilters once before loops
    _pulseGlowPaint.maskFilter = world.allowBlur ? _blur8 : null;
    _pulseTrailPaint.maskFilter = world.allowBlur ? _blur2 : null;

    // Multiple energy pulses with trails
    final pulseCount = world.reduceFx ? 4 : 8;
    final trailCount = world.reduceFx ? 3 : 5;
    final pulseSpeed = world.reduceFx ? 55.0 : 80.0;
    for (int p = 0; p < pulseCount; p++) {
      final baseProgress =
          ((_time * pulseSpeed + p * _pathLength / pulseCount) % _pathLength) /
              _pathLength;

      // Draw pulse with trail
      for (int t = 0; t < trailCount; t++) {
        final trailProgress = baseProgress - (t * 0.01);
        if (trailProgress < 0) continue;

        final pos = _getPositionOnPath(trailProgress);
        if (pos == null) continue;

        final trailSize = 4.0 - (t * 0.6);

        if (t == 0) {
          // Leading pulse - brightest
          if (!world.reduceFx) {
            canvas.drawCircle(Offset(pos.x, pos.y), 6, _pulseGlowPaint);
          }
          canvas.drawCircle(Offset(pos.x, pos.y), 3, _pulseCorePaint);
        } else {
          // Trail particles - update color with alpha
          final trailAlpha = 1.0 - (t / trailCount);
          _pulseTrailPaint.color =
              const Color(0xFFFF4488).withOpacity(trailAlpha * 0.6);
          canvas.drawCircle(Offset(pos.x, pos.y), trailSize, _pulseTrailPaint);
        }
      }
    }
  }

  Vector2? _getPositionOnPath(double progress) {
    if (_pathLength <= 0) return null;
    double targetDist = progress * _pathLength;
    double accDist = 0;

    for (int i = 0; i < _segmentLengths.length; i++) {
      final segmentLength = _segmentLengths[i];
      if (accDist + segmentLength >= targetDist) {
        final segmentProgress = (targetDist - accDist) / segmentLength;
        return world.waypoints[i] +
            (world.waypoints[i + 1] - world.waypoints[i]) * segmentProgress;
      }
      accDist += segmentLength;
    }
    return world.waypoints.isNotEmpty ? world.waypoints.last : null;
  }

  void _drawStartEndMarkers(Canvas canvas) {
    if (world.waypoints.isEmpty) return;

    final tileSize = world.tileSize;

    // === SPAWN PORTAL (Start) ===
    final startPos = world.waypoints.first;
    _drawSpawnPortal(canvas, startPos, tileSize);

    // === CORE TARGET (End) ===
    final endPos = world.waypoints.last;
    _drawCoreTarget(canvas, endPos, tileSize);
  }

  void _drawSpawnPortal(Canvas canvas, Vector2 pos, double tileSize) {
    final cx = pos.x;
    final cy = pos.y;

    // Outer rotating ring
    final ringAngle = _time * 2;
    _portalRingPaint.maskFilter = world.allowBlur ? _blur4 : null;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(ringAngle);

    // Draw segmented ring
    final arcRect =
        Rect.fromCircle(center: Offset.zero, radius: tileSize * 0.6);
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      canvas.drawArc(arcRect, angle, math.pi / 4, false, _portalRingPaint);
    }
    canvas.restore();

    // Inner portal glow
    _portalGlowPaint
      ..color =
          const Color(0xFF00FF88).withOpacity(0.5 + math.sin(_time * 4) * 0.2)
      ..maskFilter = world.allowBlur ? _blur12 : null;
    if (!world.reduceFx) {
      canvas.drawCircle(Offset(cx, cy), tileSize * 0.4, _portalGlowPaint);
    }

    // Portal core
    canvas.drawCircle(Offset(cx, cy), tileSize * 0.25, _portalCorePaint);

    // Center bright spot
    canvas.drawCircle(Offset(cx, cy), tileSize * 0.1, _portalCenterPaint);

    // Spawn arrow indicator
    canvas.drawLine(Offset(cx - 6, cy), Offset(cx + 8, cy), _portalArrowPaint);
    canvas.drawLine(
        Offset(cx + 4, cy - 4), Offset(cx + 8, cy), _portalArrowPaint);
    canvas.drawLine(
        Offset(cx + 4, cy + 4), Offset(cx + 8, cy), _portalArrowPaint);

    // "SPAWN" label glow
    _portalLabelPaint
      ..color = const Color(0xFF00FF88).withOpacity(0.6)
      ..maskFilter = world.allowBlur ? _blur2 : null;
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(cx, cy - tileSize * 0.8), width: 40, height: 12),
      _portalLabelPaint,
    );
  }

  void _drawCoreTarget(Canvas canvas, Vector2 pos, double tileSize) {
    final cx = pos.x;
    final cy = pos.y;

    // Pulsing danger zone
    final pulseRadius = tileSize * (0.7 + math.sin(_time * 3) * 0.1);
    _dangerZonePaint.maskFilter = world.allowBlur ? _blur15 : null;
    if (!world.reduceFx) {
      canvas.drawCircle(Offset(cx, cy), pulseRadius, _dangerZonePaint);
    }

    // Rotating warning triangles
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-_time * 1.5);

    final dist = tileSize * 0.5;
    for (int i = 0; i < 3; i++) {
      final angle = i * math.pi * 2 / 3;
      final triangleCenterX = math.cos(angle) * dist;
      final triangleCenterY = math.sin(angle) * dist;

      final trianglePath = Path()
        ..moveTo(triangleCenterX, triangleCenterY - 6)
        ..lineTo(triangleCenterX + 5, triangleCenterY + 4)
        ..lineTo(triangleCenterX - 5, triangleCenterY + 4)
        ..close();

      canvas.drawPath(trianglePath, _warningPaint);
    }
    canvas.restore();

    // Core rings
    canvas.drawCircle(Offset(cx, cy), tileSize * 0.35, _coreRingPaint);
    canvas.drawCircle(Offset(cx, cy), tileSize * 0.25, _coreInnerRingPaint);

    // Core center - pulsing
    _coreGlowPaint.maskFilter = world.allowBlur ? _blur8 : null;
    if (!world.reduceFx) {
      canvas.drawCircle(Offset(cx, cy), tileSize * 0.2, _coreGlowPaint);
    }

    canvas.drawCircle(Offset(cx, cy), tileSize * 0.12, _coreCenterPaint);

    // X mark
    canvas.drawLine(
        Offset(cx - 5, cy - 5), Offset(cx + 5, cy + 5), _coreXPaint);
    canvas.drawLine(
        Offset(cx + 5, cy - 5), Offset(cx - 5, cy + 5), _coreXPaint);
  }
}
