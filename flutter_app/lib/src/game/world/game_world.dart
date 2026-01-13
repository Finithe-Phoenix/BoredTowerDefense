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
    isBuildable = List.generate(mapHeight, (_) => List<bool>.filled(mapWidth, true));
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
      debugPrint('[GameWorld] Ensured starting build zone around $startCell ($safeCells)');
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
  double _pathLength = 0;
  final List<double> _segmentLengths = [];
  int _cachedWaypointCount = -1;

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

    // Draw path line overlay
    _drawPathOverlay(canvas);

    // Draw start and end markers
    _drawStartEndMarkers(canvas);
  }

  @override
  void onRemove() {
    _staticTiles?.dispose();
    super.onRemove();
  }

  void invalidateCache() {
    _cacheReady = false;
    _staticTiles?.dispose();
    _staticTiles = null;
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

    if (world.waypoints.length < 2) return;

    final path = Path();
    path.moveTo(world.waypoints.first.x, world.waypoints.first.y);
    for (int i = 1; i < world.waypoints.length; i++) {
      path.lineTo(world.waypoints[i].x, world.waypoints[i].y);
      final segmentLength = (world.waypoints[i] - world.waypoints[i - 1]).length;
      _segmentLengths.add(segmentLength);
      _pathLength += segmentLength;
    }
    _pathOverlay = path;
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
    final basePaint = Paint()..color = const Color(0xFF0a0a18);
    canvas.drawRect(rect, basePaint);

    // Building structure with 3D effect
    final buildingRect = rect.deflate(2);

    // Top face (lighter)
    final topPaint = Paint()..color = const Color(0xFF181828);
    canvas.drawRect(
      Rect.fromLTRB(buildingRect.left, buildingRect.top, buildingRect.right, buildingRect.top + 6),
      topPaint,
    );

    // Main face
    final mainPaint = Paint()..color = const Color(0xFF101020);
    canvas.drawRect(buildingRect, mainPaint);

    // Windows - glowing cyan
    final windowGlow = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.4 + math.sin(_time * 2 + x * 0.5) * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final windowPaint = Paint()..color = const Color(0xFF00DDFF).withOpacity(0.8);

    // Window grid pattern
    final windowSize = 4.0;
    final windowSpacing = 6.0;
    final startX = rect.left + 5;
    final startY = rect.top + 8;

    for (int wy = 0; wy < 2; wy++) {
      for (int wx = 0; wx < 3; wx++) {
        // Some windows are lit, some are dark
        final isLit = ((x + wx) * 3 + (y + wy) * 7 + (_time * 0.5).floor()) % 5 != 0;
        if (isLit) {
          final windowRect = Rect.fromLTWH(
            startX + wx * windowSpacing,
            startY + wy * windowSpacing,
            windowSize,
            windowSize - 1,
          );
          canvas.drawRect(windowRect, windowGlow);
          canvas.drawRect(windowRect, windowPaint);
        }
      }
    }

    // Rooftop antenna/structure
    if ((x + y) % 4 == 0) {
      final antennaPaint = Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(0.6)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(rect.center.dx, rect.top + 2),
        Offset(rect.center.dx, rect.top - 4),
        antennaPaint,
      );
      // Blinking light
      if (math.sin(_time * 4 + x) > 0) {
        final blinkPaint = Paint()
          ..color = const Color(0xFFFF0044)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(rect.center.dx, rect.top - 4), 2, blinkPaint);
      }
    }

    // Neon edge trim
    final edgePaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(buildingRect, edgePaint);
  }

  void _drawServerRack(Canvas canvas, Rect rect, int x, int y) {
    // Dark base
    final basePaint = Paint()..color = const Color(0xFF080812);
    canvas.drawRect(rect, basePaint);

    // Rack frame
    final framePaint = Paint()
      ..color = const Color(0xFF1a1a2e)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect.deflate(3), framePaint);

    // Server slots with blinking lights
    final slotHeight = 5.0;
    final startY = rect.top + 6;

    for (int i = 0; i < 4; i++) {
      final slotY = startY + i * slotHeight;

      // Slot background
      final slotPaint = Paint()..color = const Color(0xFF0d0d1a);
      canvas.drawRect(
        Rect.fromLTWH(rect.left + 5, slotY, rect.width - 10, slotHeight - 1),
        slotPaint,
      );

      // LED indicators
      for (int led = 0; led < 4; led++) {
        final ledActive = math.sin(_time * 3 + x + y + i * 2 + led) > 0;
        final ledColor = ledActive
            ? (led == 0 ? const Color(0xFF00FF00) : const Color(0xFF00FFFF))
            : const Color(0xFF333344);
        final ledPaint = Paint()
          ..color = ledColor.withOpacity(ledActive ? 0.9 : 0.3);
        if (ledActive) {
          ledPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        }
        canvas.drawCircle(
          Offset(rect.left + 8 + led * 4, slotY + slotHeight / 2),
          1.5,
          ledPaint,
        );
      }
    }

    // Ventilation grille at bottom
    final ventPaint = Paint()
      ..color = const Color(0xFF2a2a44).withOpacity(0.5)
      ..strokeWidth = 1;
    for (int v = 0; v < 5; v++) {
      canvas.drawLine(
        Offset(rect.left + 6 + v * 4, rect.bottom - 4),
        Offset(rect.left + 6 + v * 4, rect.bottom - 2),
        ventPaint,
      );
    }
  }

  void _drawEnergyCore(Canvas canvas, Rect rect, int x, int y) {
    // Dark containment base
    final basePaint = Paint()..color = const Color(0xFF050510);
    canvas.drawRect(rect, basePaint);

    // Containment ring
    final ringPaint = Paint()
      ..color = const Color(0xFF1a1a2e)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(rect.center, rect.width * 0.35, ringPaint);

    // Energy core - pulsing
    final pulseScale = 0.8 + math.sin(_time * 4 + x + y) * 0.2;
    final coreRadius = rect.width * 0.2 * pulseScale;

    // Core glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF00FF).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(rect.center, coreRadius * 2, glowPaint);

    // Core inner
    final corePaint = Paint()
      ..color = const Color(0xFFFF44FF).withOpacity(0.9);
    canvas.drawCircle(rect.center, coreRadius, corePaint);

    // Core bright center
    final centerPaint = Paint()..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(rect.center, coreRadius * 0.4, centerPaint);

    // Energy arcs
    final arcPaint = Paint()
      ..color = const Color(0xFFFF00FF).withOpacity(0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

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
      canvas.drawLine(arcStart, arcEnd, arcPaint);
    }

    // Corner brackets
    final bracketPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.5)
      ..strokeWidth = 1;
    _drawCornerBrackets(canvas, rect, 6, bracketPaint);
  }

  void _drawDataNode(Canvas canvas, Rect rect, int x, int y) {
    // Dark base
    final basePaint = Paint()..color = const Color(0xFF0a0a14);
    canvas.drawRect(rect, basePaint);

    // Hexagonal pattern overlay
    final hexPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw hex grid pattern
    final hexSize = 8.0;
    for (double hx = rect.left; hx < rect.right; hx += hexSize * 1.5) {
      for (double hy = rect.top; hy < rect.bottom; hy += hexSize * 0.866) {
        _drawHexagon(canvas, Offset(hx, hy), hexSize * 0.4, hexPaint);
      }
    }

    // Central data display
    final displayRect = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.6,
      height: rect.height * 0.5,
    );

    // Display background
    final displayBg = Paint()..color = const Color(0xFF001122);
    canvas.drawRect(displayRect, displayBg);

    // Display border glow
    final displayGlow = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.4 + math.sin(_time * 3) * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawRect(displayRect, displayGlow);

    // Scrolling data lines
    final dataPaint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.6)
      ..strokeWidth = 1;

    final dataOffset = (_time * 20) % 8;
    for (int line = 0; line < 3; line++) {
      final lineY = displayRect.top + 3 + line * 4 + dataOffset * 0.3;
      if (lineY < displayRect.bottom - 2) {
        final lineWidth = ((x + y + line) % 3 + 1) * 4.0;
        canvas.drawLine(
          Offset(displayRect.left + 2, lineY),
          Offset(displayRect.left + 2 + lineWidth, lineY),
          dataPaint,
        );
      }
    }

    // Status indicators on corners
    final indicatorPaint = Paint()
      ..color = const Color(0xFF00FF00).withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(rect.left + 4, rect.top + 4), 2, indicatorPaint);
    canvas.drawCircle(Offset(rect.right - 4, rect.top + 4), 2, indicatorPaint);
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect, double size, Paint paint) {
    // Top-left
    canvas.drawLine(Offset(rect.left, rect.top + size), Offset(rect.left, rect.top), paint);
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + size, rect.top), paint);
    // Top-right
    canvas.drawLine(Offset(rect.right - size, rect.top), Offset(rect.right, rect.top), paint);
    canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + size), paint);
    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom - size), Offset(rect.left, rect.bottom), paint);
    canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + size, rect.bottom), paint);
    // Bottom-right
    canvas.drawLine(Offset(rect.right - size, rect.bottom), Offset(rect.right, rect.bottom), paint);
    canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right, rect.bottom - size), paint);
  }

  void _drawPathTile(Canvas canvas, Rect rect, int x, int y) {
    // Dark energy conduit base
    final basePaint = Paint()..color = const Color(0xFF080010);
    canvas.drawRect(rect, basePaint);

    // Outer energy glow - pulsing
    final pulsePhase = _time * 4 + x * 0.3 + y * 0.2;
    final pulseAlpha = 0.2 + math.sin(pulsePhase) * 0.1;
    final outerGlow = Paint()
      ..color = const Color(0xFFFF0066).withOpacity(pulseAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(rect, outerGlow);

    // Inner conduit channel
    final channelRect = rect.deflate(3);
    final channelPaint = Paint()..color = const Color(0xFF0a0015);
    canvas.drawRect(channelRect, channelPaint);

    // Energy flow lines - animated
    final flowOffset = (_time * 60) % 20;
    final flowPaint = Paint()
      ..color = const Color(0xFFFF0088).withOpacity(0.4)
      ..strokeWidth = 1;

    // Horizontal flow lines
    for (int i = 0; i < 3; i++) {
      final lineY = rect.top + 8 + i * 8 + (flowOffset * 0.2);
      if (lineY < rect.bottom - 4) {
        canvas.drawLine(
          Offset(rect.left + 4, lineY),
          Offset(rect.right - 4, lineY),
          flowPaint,
        );
      }
    }

    // Central energy core
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final coreRadius = 4.0 + math.sin(_time * 5 + x + y) * 1.0;

    // Core glow
    final coreGlow = Paint()
      ..color = const Color(0xFFFF0066).withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx, cy), coreRadius * 1.5, coreGlow);

    // Core center
    final corePaint = Paint()..color = const Color(0xFFFF4488);
    canvas.drawCircle(Offset(cx, cy), coreRadius * 0.6, corePaint);

    // Corner energy nodes
    final nodePaint = Paint()
      ..color = const Color(0xFFFF0066).withOpacity(0.5 + math.sin(_time * 3 + x) * 0.2);
    canvas.drawCircle(Offset(rect.left + 4, rect.top + 4), 2, nodePaint);
    canvas.drawCircle(Offset(rect.right - 4, rect.top + 4), 2, nodePaint);
    canvas.drawCircle(Offset(rect.left + 4, rect.bottom - 4), 2, nodePaint);
    canvas.drawCircle(Offset(rect.right - 4, rect.bottom - 4), 2, nodePaint);

    // Connection lines from corners to center
    final connPaint = Paint()
      ..color = const Color(0xFFFF0066).withOpacity(0.2)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(rect.left + 4, rect.top + 4), Offset(cx, cy), connPaint);
    canvas.drawLine(Offset(rect.right - 4, rect.top + 4), Offset(cx, cy), connPaint);
    canvas.drawLine(Offset(rect.left + 4, rect.bottom - 4), Offset(cx, cy), connPaint);
    canvas.drawLine(Offset(rect.right - 4, rect.bottom - 4), Offset(cx, cy), connPaint);

    // Neon border with double line effect
    final borderOuter = Paint()
      ..color = const Color(0xFFFF0066).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect.deflate(1), borderOuter);

    final borderInner = Paint()
      ..color = const Color(0xFFFF4488).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(rect.deflate(4), borderInner);
  }

  void _drawBuildableTile(Canvas canvas, Rect rect, int x, int y) {
    // Dark tech floor base
    final basePaint = Paint()..color = const Color(0xFF0a0a16);
    canvas.drawRect(rect, basePaint);

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
    final gridPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRect(rect.deflate(1), gridPaint);

    // Corner anchor points
    final anchorGlow = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final anchorCore = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.4);

    for (final corner in [
      Offset(rect.left + 3, rect.top + 3),
      Offset(rect.right - 3, rect.top + 3),
      Offset(rect.left + 3, rect.bottom - 3),
      Offset(rect.right - 3, rect.bottom - 3),
    ]) {
      canvas.drawCircle(corner, 2.5, anchorGlow);
      canvas.drawCircle(corner, 1.2, anchorCore);
    }

    // Random data flicker effect
    if ((x * 7 + y * 11 + (_time * 2).floor()) % 23 == 0) {
      final flickerPaint = Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRect(rect, flickerPaint);
    }
  }

  void _drawCircuitPattern(Canvas canvas, Rect rect, int x, int y) {
    final tracePaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.15)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final cx = rect.center.dx;
    final cy = rect.center.dy;

    // Horizontal trace
    canvas.drawLine(
      Offset(rect.left + 4, cy),
      Offset(rect.right - 4, cy),
      tracePaint,
    );

    // Vertical trace with break
    canvas.drawLine(
      Offset(cx, rect.top + 4),
      Offset(cx, cy - 4),
      tracePaint,
    );
    canvas.drawLine(
      Offset(cx, cy + 4),
      Offset(cx, rect.bottom - 4),
      tracePaint,
    );

    // Center node
    final nodePaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.25 + math.sin(_time * 2 + x + y) * 0.1);
    canvas.drawCircle(Offset(cx, cy), 2, nodePaint);
  }

  void _drawHexGridPattern(Canvas canvas, Rect rect) {
    final hexPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final hexSize = 6.0;
    final cx = rect.center.dx;
    final cy = rect.center.dy;

    // Draw a single hex at center
    _drawHexagon(canvas, Offset(cx, cy), hexSize, hexPaint);

    // Corner hexes (partial)
    for (final offset in [
      Offset(-hexSize * 1.5, -hexSize * 0.866),
      Offset(hexSize * 1.5, -hexSize * 0.866),
      Offset(-hexSize * 1.5, hexSize * 0.866),
      Offset(hexSize * 1.5, hexSize * 0.866),
    ]) {
      _drawHexagon(canvas, Offset(cx + offset.dx, cy + offset.dy), hexSize * 0.5, hexPaint);
    }
  }

  void _drawDiamondPattern(Canvas canvas, Rect rect, int x, int y) {
    final diamondPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final size = 8.0;

    final path = Path()
      ..moveTo(cx, cy - size)
      ..lineTo(cx + size, cy)
      ..lineTo(cx, cy + size)
      ..lineTo(cx - size, cy)
      ..close();

    canvas.drawPath(path, diamondPaint);

    // Inner diamond
    final innerPath = Path()
      ..moveTo(cx, cy - size * 0.5)
      ..lineTo(cx + size * 0.5, cy)
      ..lineTo(cx, cy + size * 0.5)
      ..lineTo(cx - size * 0.5, cy)
      ..close();

    final innerPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.06 + math.sin(_time + x) * 0.02)
      ..style = PaintingStyle.fill;
    canvas.drawPath(innerPath, innerPaint);
  }

  void _drawStandardGrid(Canvas canvas, Rect rect, int x, int y) {
    // Cross pattern
    final crossPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.08)
      ..strokeWidth = 0.5;

    final cx = rect.center.dx;
    final cy = rect.center.dy;

    canvas.drawLine(Offset(cx - 6, cy), Offset(cx + 6, cy), crossPaint);
    canvas.drawLine(Offset(cx, cy - 6), Offset(cx, cy + 6), crossPaint);

    // Tick marks at edges
    canvas.drawLine(Offset(rect.left + 2, cy), Offset(rect.left + 5, cy), crossPaint);
    canvas.drawLine(Offset(rect.right - 5, cy), Offset(rect.right - 2, cy), crossPaint);
    canvas.drawLine(Offset(cx, rect.top + 2), Offset(cx, rect.top + 5), crossPaint);
    canvas.drawLine(Offset(cx, rect.bottom - 5), Offset(cx, rect.bottom - 2), crossPaint);
  }

  void _drawPathOverlay(Canvas canvas) {
    if (world.waypoints.length < 2) return;
    _ensurePathCache();
    if (_pathOverlay == null) return;

    final path = _pathOverlay!;

    // Outer glow - wide and diffuse
    final outerGlow = Paint()
      ..color = const Color(0xFFFF0066).withOpacity(0.2)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = world.allowBlur ? const MaskFilter.blur(BlurStyle.normal, 10) : null;
    if (!world.reduceFx) {
      canvas.drawPath(path, outerGlow);
    }

    // Middle glow
    final middleGlow = Paint()
      ..color = const Color(0xFFFF0066).withOpacity(0.5)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = world.allowBlur ? const MaskFilter.blur(BlurStyle.normal, 4) : null;
    canvas.drawPath(path, middleGlow);

    // Core line - bright
    final coreLine = Paint()
      ..color = const Color(0xFFFF4488)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, coreLine);

    // Waypoint nodes
    _drawWaypointNodes(canvas);

    // Animated energy pulses
    _drawEnergyPulses(canvas);
  }

  void _drawWaypointNodes(Canvas canvas) {
    for (int i = 0; i < world.waypoints.length; i++) {
      final pos = world.waypoints[i];
      final isCorner = i > 0 && i < world.waypoints.length - 1;

      if (isCorner) {
        // Corner node - junction point
        final nodeGlow = Paint()
          ..color = const Color(0xFFFF0066).withOpacity(0.6)
          ..maskFilter = world.allowBlur ? const MaskFilter.blur(BlurStyle.normal, 6) : null;
        if (!world.reduceFx) {
          canvas.drawCircle(Offset(pos.x, pos.y), 8, nodeGlow);
        }

        final nodeRing = Paint()
          ..color = const Color(0xFFFF4488).withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(pos.x, pos.y), 6, nodeRing);

        final nodeCore = Paint()..color = const Color(0xFFFF0066);
        canvas.drawCircle(Offset(pos.x, pos.y), 3, nodeCore);
      }
    }
  }

  void _drawEnergyPulses(Canvas canvas) {
    if (_pathLength <= 0) return;

    // Multiple energy pulses with trails
    final pulseCount = world.reduceFx ? 4 : 8;
    final trailCount = world.reduceFx ? 3 : 5;
    final pulseSpeed = world.reduceFx ? 55.0 : 80.0;
    for (int p = 0; p < pulseCount; p++) {
      final baseProgress =
          ((_time * pulseSpeed + p * _pathLength / pulseCount) % _pathLength) / _pathLength;

      // Draw pulse with trail
      for (int t = 0; t < trailCount; t++) {
        final trailProgress = baseProgress - (t * 0.01);
        if (trailProgress < 0) continue;

        final pos = _getPositionOnPath(trailProgress);
        if (pos == null) continue;

        final trailAlpha = 1.0 - (t / trailCount);
        final trailSize = 4.0 - (t * 0.6);

        if (t == 0) {
          // Leading pulse - brightest
          final pulseGlow = Paint()
            ..color = const Color(0xFFFF0066).withOpacity(0.9)
            ..maskFilter = world.allowBlur ? const MaskFilter.blur(BlurStyle.normal, 8) : null;
          if (!world.reduceFx) {
            canvas.drawCircle(Offset(pos.x, pos.y), 6, pulseGlow);
          }

          final pulseCore = Paint()..color = Colors.white;
          canvas.drawCircle(Offset(pos.x, pos.y), 3, pulseCore);
        } else {
          // Trail particles
          final trailPaint = Paint()
            ..color = const Color(0xFFFF4488).withOpacity(trailAlpha * 0.6)
            ..maskFilter = world.allowBlur ? const MaskFilter.blur(BlurStyle.normal, 2) : null;
          canvas.drawCircle(Offset(pos.x, pos.y), trailSize, trailPaint);
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
    final outerRingPaint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = world.allowBlur ? const MaskFilter.blur(BlurStyle.normal, 4) : null;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(ringAngle);

    // Draw segmented ring
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final startAngle = angle;
      final sweepAngle = math.pi / 4;

      final arcRect = Rect.fromCircle(center: Offset.zero, radius: tileSize * 0.6);
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, outerRingPaint);
    }
    canvas.restore();

    // Inner portal glow
    final portalGlow = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.5 + math.sin(_time * 4) * 0.2)
      ..maskFilter = world.allowBlur ? const MaskFilter.blur(BlurStyle.normal, 12) : null;
    if (!world.reduceFx) {
      canvas.drawCircle(Offset(cx, cy), tileSize * 0.4, portalGlow);
    }

    // Portal core
    final portalCore = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.9);
    canvas.drawCircle(Offset(cx, cy), tileSize * 0.25, portalCore);

    // Center bright spot
    final centerSpot = Paint()..color = Colors.white.withOpacity(0.9);
    canvas.drawCircle(Offset(cx, cy), tileSize * 0.1, centerSpot);

    // Spawn arrow indicator
    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Arrow pointing right (spawn direction)
    canvas.drawLine(Offset(cx - 6, cy), Offset(cx + 8, cy), arrowPaint);
    canvas.drawLine(Offset(cx + 4, cy - 4), Offset(cx + 8, cy), arrowPaint);
    canvas.drawLine(Offset(cx + 4, cy + 4), Offset(cx + 8, cy), arrowPaint);

    // "SPAWN" label glow
    final labelPaint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.6)
      ..maskFilter = world.allowBlur ? const MaskFilter.blur(BlurStyle.normal, 2) : null;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy - tileSize * 0.8), width: 40, height: 12),
      labelPaint,
    );
  }

  void _drawCoreTarget(Canvas canvas, Vector2 pos, double tileSize) {
    final cx = pos.x;
    final cy = pos.y;

    // Pulsing danger zone
    final pulseRadius = tileSize * (0.7 + math.sin(_time * 3) * 0.1);
    final dangerZone = Paint()
      ..color = const Color(0xFFFF0066).withOpacity(0.2)
      ..maskFilter = world.allowBlur ? const MaskFilter.blur(BlurStyle.normal, 15) : null;
    if (!world.reduceFx) {
      canvas.drawCircle(Offset(cx, cy), pulseRadius, dangerZone);
    }

    // Rotating warning triangles
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-_time * 1.5);

    final warningPaint = Paint()
      ..color = const Color(0xFFFF0066).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final angle = i * math.pi * 2 / 3;
      final dist = tileSize * 0.5;
      final triangleCenter = Offset(math.cos(angle) * dist, math.sin(angle) * dist);

      final trianglePath = Path()
        ..moveTo(triangleCenter.dx, triangleCenter.dy - 6)
        ..lineTo(triangleCenter.dx + 5, triangleCenter.dy + 4)
        ..lineTo(triangleCenter.dx - 5, triangleCenter.dy + 4)
        ..close();

      canvas.drawPath(trianglePath, warningPaint);
    }
    canvas.restore();

    // Core rings
    final ringPaint = Paint()
      ..color = const Color(0xFFFF0066).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), tileSize * 0.35, ringPaint);

    final innerRing = Paint()
      ..color = const Color(0xFFFF4488).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), tileSize * 0.25, innerRing);

    // Core center - pulsing
    final coreGlow = Paint()
      ..color = const Color(0xFFFF0066).withOpacity(0.8)
      ..maskFilter = world.allowBlur ? const MaskFilter.blur(BlurStyle.normal, 8) : null;
    if (!world.reduceFx) {
      canvas.drawCircle(Offset(cx, cy), tileSize * 0.2, coreGlow);
    }

    final coreCenter = Paint()..color = const Color(0xFFFF4488);
    canvas.drawCircle(Offset(cx, cy), tileSize * 0.12, coreCenter);

    // X mark
    final xPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 5, cy - 5), Offset(cx + 5, cy + 5), xPaint);
    canvas.drawLine(Offset(cx + 5, cy - 5), Offset(cx - 5, cy + 5), xPaint);
  }
}
