import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../data/world_chronicles.dart';
import '../theme/neon_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PROCEDURAL WORLD ART GENERATOR
/// Creates unique, animated artwork for each world based on its theme
/// ═══════════════════════════════════════════════════════════════════════════

class WorldArtGenerator extends StatefulWidget {
  final int worldId;
  final Color accentColor;
  final double width;
  final double height;
  final bool animate;
  final VoidCallback? onTap;

  const WorldArtGenerator({
    super.key,
    required this.worldId,
    required this.accentColor,
    this.width = 300,
    this.height = 200,
    this.animate = true,
    this.onTap,
  });

  @override
  State<WorldArtGenerator> createState() => _WorldArtGeneratorState();
}

class _WorldArtGeneratorState extends State<WorldArtGenerator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_WorldElement> _elements = [];
  int _rngState = 0x6d2b79f5;

  @override
  void initState() {
    super.initState();
    _rngState = 0x6d2b79f5 ^ widget.worldId ^ widget.accentColor.value;
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    if (widget.animate) {
      _controller.repeat();
    }
    _generateElements();
  }

  void _generateElements() {
    _elements.clear();
    switch (widget.worldId) {
      case 1: // Neon Frontier
        _generateNeonFrontierElements();
        break;
      case 2: // Rift Wars
        _generateRiftWarsElements();
        break;
      case 3: // Signal Wastes
        _generateSignalWastesElements();
        break;
      case 4: // Ion Crown
        _generateIonCrownElements();
        break;
      case 5: // Shard Vault
        _generateShardVaultElements();
        break;
      case 10: // Final Gate
        _generateFinalGateElements();
        break;
      default:
        _generateDefaultElements();
    }
  }

  void _generateNeonFrontierElements() {
    // Data towers
    for (int i = 0; i < 8; i++) {
      _elements.add(_WorldElement(
        type: ElementType.tower,
        x: 0.1 + _nextUnit() * 0.8,
        y: 0.5 + _nextUnit() * 0.3,
        scale: 0.3 + _nextUnit() * 0.7,
        color: widget.accentColor,
        speed: 0.5 + _nextUnit() * 0.5,
      ));
    }
    // Floating data particles
    for (int i = 0; i < 30; i++) {
      _elements.add(_WorldElement(
        type: ElementType.particle,
        x: _nextUnit(),
        y: _nextUnit(),
        scale: 0.3 + _nextUnit() * 0.7,
        color: widget.accentColor,
        speed: 0.2 + _nextUnit() * 0.8,
      ));
    }
    // Grid lines
    for (int i = 0; i < 5; i++) {
      _elements.add(_WorldElement(
        type: ElementType.gridLine,
        x: 0.1 + i * 0.2,
        y: 0,
        scale: 1,
        color: widget.accentColor,
        speed: 0.1,
      ));
    }
  }

  void _generateRiftWarsElements() {
    // Rifts
    for (int i = 0; i < 5; i++) {
      _elements.add(_WorldElement(
        type: ElementType.rift,
        x: 0.2 + _nextUnit() * 0.6,
        y: 0.2 + _nextUnit() * 0.6,
        scale: 0.5 + _nextUnit() * 0.5,
        color: widget.accentColor,
        speed: 0.3 + _nextUnit() * 0.4,
      ));
    }
    // Temporal echoes
    for (int i = 0; i < 15; i++) {
      _elements.add(_WorldElement(
        type: ElementType.echo,
        x: _nextUnit(),
        y: _nextUnit(),
        scale: 0.2 + _nextUnit() * 0.8,
        color: NeonColors.magenta,
        speed: 0.1 + _nextUnit() * 0.3,
      ));
    }
  }

  void _generateSignalWastesElements() {
    // Static noise areas
    for (int i = 0; i < 20; i++) {
      _elements.add(_WorldElement(
        type: ElementType.noise,
        x: _nextUnit(),
        y: _nextUnit(),
        scale: 0.5 + _nextUnit() * 1.5,
        color: widget.accentColor,
        speed: 0.5 + _nextUnit() * 1.0,
      ));
    }
    // Abandoned structures
    for (int i = 0; i < 4; i++) {
      _elements.add(_WorldElement(
        type: ElementType.ruin,
        x: 0.1 + _nextUnit() * 0.8,
        y: 0.6 + _nextUnit() * 0.2,
        scale: 0.4 + _nextUnit() * 0.6,
        color: Colors.grey,
        speed: 0,
      ));
    }
    // Beacon lights
    for (int i = 0; i < 3; i++) {
      _elements.add(_WorldElement(
        type: ElementType.beacon,
        x: 0.2 + i * 0.3,
        y: 0.5 + _nextUnit() * 0.2,
        scale: 0.5,
        color: widget.accentColor,
        speed: 1.0 + _nextUnit() * 0.5,
      ));
    }
  }

  void _generateIonCrownElements() {
    // Storm clouds
    for (int i = 0; i < 10; i++) {
      _elements.add(_WorldElement(
        type: ElementType.cloud,
        x: _nextUnit(),
        y: 0.1 + _nextUnit() * 0.3,
        scale: 0.8 + _nextUnit() * 0.4,
        color: const Color(0xFF003322),
        speed: 0.1 + _nextUnit() * 0.1,
      ));
    }
    // Lightning bolts
    for (int i = 0; i < 4; i++) {
      _elements.add(_WorldElement(
        type: ElementType.lightning,
        x: 0.1 + _nextUnit() * 0.8,
        y: 0.3,
        scale: 0.5 + _nextUnit() * 0.5,
        color: widget.accentColor,
        speed: 2.0 + _nextUnit() * 2.0,
      ));
    }
    // Crown structure
    _elements.add(_WorldElement(
      type: ElementType.crown,
      x: 0.5,
      y: 0.4,
      scale: 1.0,
      color: widget.accentColor,
      speed: 0.5,
    ));
    // Floating platforms
    for (int i = 0; i < 6; i++) {
      _elements.add(_WorldElement(
        type: ElementType.platform,
        x: 0.1 + _nextUnit() * 0.8,
        y: 0.5 + _nextUnit() * 0.3,
        scale: 0.3 + _nextUnit() * 0.4,
        color: const Color(0xFF224422),
        speed: 0.2 + _nextUnit() * 0.2,
      ));
    }
  }

  void _generateShardVaultElements() {
    // Memory crystals
    for (int i = 0; i < 25; i++) {
      _elements.add(_WorldElement(
        type: ElementType.crystal,
        x: _nextUnit(),
        y: _nextUnit(),
        scale: 0.2 + _nextUnit() * 0.6,
        color: _nextBool() ? widget.accentColor : const Color(0xFFFF4444),
        speed: 0.1 + _nextUnit() * 0.3,
      ));
    }
    // Vault structure
    for (int i = 0; i < 3; i++) {
      _elements.add(_WorldElement(
        type: ElementType.vault,
        x: 0.2 + i * 0.3,
        y: 0.6,
        scale: 0.6 + _nextUnit() * 0.4,
        color: const Color(0xFF441111),
        speed: 0,
      ));
    }
    // Data streams
    for (int i = 0; i < 8; i++) {
      _elements.add(_WorldElement(
        type: ElementType.stream,
        x: _nextUnit(),
        y: 0,
        scale: 0.5 + _nextUnit() * 0.5,
        color: widget.accentColor.withOpacity(0.5),
        speed: 0.5 + _nextUnit() * 0.5,
      ));
    }
  }

  void _generateFinalGateElements() {
    // Core light
    _elements.add(_WorldElement(
      type: ElementType.core,
      x: 0.5,
      y: 0.5,
      scale: 1.0,
      color: Colors.white,
      speed: 0.5,
    ));
    // Energy streams converging to center
    for (int i = 0; i < 12; i++) {
      _elements.add(_WorldElement(
        type: ElementType.energyStream,
        x: math.cos(i * math.pi / 6) * 0.5 + 0.5,
        y: math.sin(i * math.pi / 6) * 0.5 + 0.5,
        scale: 0.5,
        color: Color.lerp(
          NeonColors.cyan,
          NeonColors.magenta,
          i / 12.0,
        )!,
        speed: 0.3,
      ));
    }
    // Floating debris/data
    for (int i = 0; i < 20; i++) {
      _elements.add(_WorldElement(
        type: ElementType.debris,
        x: _nextUnit(),
        y: _nextUnit(),
        scale: 0.2 + _nextUnit() * 0.4,
        color: Colors.white.withOpacity(0.5),
        speed: 0.1 + _nextUnit() * 0.2,
      ));
    }
  }

  void _generateDefaultElements() {
    for (int i = 0; i < 30; i++) {
      _elements.add(_WorldElement(
        type: ElementType.particle,
        x: _nextUnit(),
        y: _nextUnit(),
        scale: 0.3 + _nextUnit() * 0.7,
        color: widget.accentColor,
        speed: 0.2 + _nextUnit() * 0.8,
      ));
    }
  }

  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }

  double _nextUnit() => _lcgNext() / 0x7fffffff;

  bool _nextBool() => (_lcgNext() & 1) == 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _WorldArtPainter(
                  worldId: widget.worldId,
                  accentColor: widget.accentColor,
                  elements: _elements,
                  time: _controller.value,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum ElementType {
  tower,
  particle,
  gridLine,
  rift,
  echo,
  noise,
  ruin,
  beacon,
  cloud,
  lightning,
  crown,
  platform,
  crystal,
  vault,
  stream,
  core,
  energyStream,
  debris,
}

class _WorldElement {
  final ElementType type;
  final double x, y;
  final double scale;
  final Color color;
  final double speed;

  _WorldElement({
    required this.type,
    required this.x,
    required this.y,
    required this.scale,
    required this.color,
    required this.speed,
  });
}

class _WorldArtPainter extends CustomPainter {
  final int worldId;
  final Color accentColor;
  final List<_WorldElement> elements;
  final double time;

  static final Paint _bgPaint = Paint();
  static final Paint _towerPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _towerGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _particlePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _gridLinePaint = Paint()..strokeWidth = 1;
  static final Paint _riftGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  static final Paint _riftCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _echoPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  static final Paint _noisePaint = Paint();
  static final Paint _ruinPaint = Paint();
  static final Paint _beaconGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _beaconCorePaint = Paint();
  static final Paint _beaconPolePaint = Paint()..strokeWidth = 3;
  static final Paint _cloudPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _lightningPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _crownRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  static final Paint _crownGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  static final Paint _platformPaint = Paint();
  static final Paint _crystalPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _vaultPaint = Paint();
  static final Paint _streamPaint = Paint()
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _coreOuterPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
  static final Paint _coreMidPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  static final Paint _corePaint = Paint();
  static final Paint _energyStreamPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  static final Paint _debrisPaint = Paint();
  static final Paint _vignettePaint = Paint();
  static final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  static final Path _towerPath = Path();
  static final Path _ruinPath = Path();
  static final Path _lightningPath = Path();
  static final Path _crystalPath = Path();
  static final Path _vaultPath = Path();

  static Size? _bgCacheSize;
  static int? _bgCacheWorldId;
  static Shader? _bgShader;
  static Size? _vignetteCacheSize;
  static Shader? _vignetteShader;

  static int _lcgNext(int state) =>
      (state * 1664525 + 1013904223) & 0x7fffffff;
  static double _lcgUnit(int state) => state / 0x7fffffff;

  _WorldArtPainter({
    required this.worldId,
    required this.accentColor,
    required this.elements,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    _drawBackground(canvas, size);

    // Draw elements by type (layered)
    for (final element in elements) {
      _drawElement(canvas, size, element);
    }

    // Vignette overlay
    _drawVignette(canvas, size);

    // Border glow
    _drawBorderGlow(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    Color bgColor1, bgColor2, bgColor3;
    switch (worldId) {
      case 1: // Neon Frontier
        bgColor1 = const Color(0xFF001122);
        bgColor2 = const Color(0xFF002244);
        bgColor3 = const Color(0xFF000811);
        break;
      case 2: // Rift Wars
        bgColor1 = const Color(0xFF110022);
        bgColor2 = const Color(0xFF220044);
        bgColor3 = const Color(0xFF080011);
        break;
      case 3: // Signal Wastes
        bgColor1 = const Color(0xFF111100);
        bgColor2 = const Color(0xFF222200);
        bgColor3 = const Color(0xFF080800);
        break;
      case 4: // Ion Crown
        bgColor1 = const Color(0xFF001108);
        bgColor2 = const Color(0xFF002211);
        bgColor3 = const Color(0xFF000808);
        break;
      case 5: // Shard Vault
        bgColor1 = const Color(0xFF110000);
        bgColor2 = const Color(0xFF220808);
        bgColor3 = const Color(0xFF080000);
        break;
      case 10: // Final Gate
        bgColor1 = const Color(0xFF080808);
        bgColor2 = const Color(0xFF111111);
        bgColor3 = const Color(0xFF000000);
        break;
      default:
        bgColor1 = const Color(0xFF0a0a18);
        bgColor2 = const Color(0xFF12061a);
        bgColor3 = const Color(0xFF000000);
    }

    if (_bgCacheSize != size || _bgCacheWorldId != worldId) {
      _bgCacheSize = size;
      _bgCacheWorldId = worldId;
      _bgShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [bgColor1, bgColor2, bgColor3],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    }

    _bgPaint.shader = _bgShader;
    canvas.drawRect(rect, _bgPaint);
  }

  void _drawElement(Canvas canvas, Size size, _WorldElement element) {
    final x = element.x * size.width;
    final y = element.y * size.height;
    final animOffset = math.sin(time * math.pi * 2 * element.speed) * 5;

    switch (element.type) {
      case ElementType.tower:
        _drawTower(canvas, x, y + animOffset, element, size);
        break;
      case ElementType.particle:
        _drawParticle(canvas, x, y, element, time);
        break;
      case ElementType.gridLine:
        _drawGridLine(canvas, x, size, element);
        break;
      case ElementType.rift:
        _drawRift(canvas, x, y, element, size, time);
        break;
      case ElementType.echo:
        _drawEcho(canvas, x, y, element, time);
        break;
      case ElementType.noise:
        _drawNoise(canvas, x, y, element, size, time);
        break;
      case ElementType.ruin:
        _drawRuin(canvas, x, y, element, size);
        break;
      case ElementType.beacon:
        _drawBeacon(canvas, x, y, element, time);
        break;
      case ElementType.cloud:
        _drawCloud(canvas, x + time * 20 * element.speed, y, element, size);
        break;
      case ElementType.lightning:
        _drawLightning(canvas, x, y, element, size, time);
        break;
      case ElementType.crown:
        _drawCrown(canvas, x, y, element, size, time);
        break;
      case ElementType.platform:
        _drawPlatform(canvas, x, y + animOffset * 2, element, size);
        break;
      case ElementType.crystal:
        _drawCrystal(canvas, x, y, element, time);
        break;
      case ElementType.vault:
        _drawVault(canvas, x, y, element, size);
        break;
      case ElementType.stream:
        _drawStream(canvas, x, element, size, time);
        break;
      case ElementType.core:
        _drawCore(canvas, x, y, element, size, time);
        break;
      case ElementType.energyStream:
        _drawEnergyStream(canvas, x, y, element, size, time);
        break;
      case ElementType.debris:
        _drawDebris(canvas, x, y, element, time);
        break;
    }
  }

  void _drawTower(Canvas canvas, double x, double y, _WorldElement e, Size size) {
    final height = e.scale * size.height * 0.4;
    final width = 8 + e.scale * 12;

    // Tower body
    final towerPath = _towerPath..reset();
    towerPath
      ..moveTo(x - width / 2, y)
      ..lineTo(x - width / 3, y - height)
      ..lineTo(x + width / 3, y - height)
      ..lineTo(x + width / 2, y)
      ..close();

    _towerPaint.color = e.color.withOpacity(0.6);
    canvas.drawPath(towerPath, _towerPaint);

    // Glow at top
    _towerGlowPaint.color = e.color.withOpacity(0.8);
    canvas.drawCircle(
      Offset(x, y - height),
      5 * e.scale,
      _towerGlowPaint,
    );
  }

  void _drawParticle(Canvas canvas, double x, double y, _WorldElement e, double t) {
    final offset = math.sin(t * math.pi * 2 * e.speed + e.x * 10) * 10;
    final alpha = (math.sin(t * math.pi * 4 * e.speed) * 0.3 + 0.5).clamp(0.1, 0.8);

    canvas.drawCircle(
      Offset(x, y + offset),
      2 * e.scale,
      _particlePaint..color = e.color.withOpacity(alpha),
    );
  }

  void _drawGridLine(Canvas canvas, double x, Size size, _WorldElement e) {
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      _gridLinePaint..color = e.color.withOpacity(0.1),
    );
  }

  void _drawRift(Canvas canvas, double x, double y, _WorldElement e, Size size, double t) {
    final scale = e.scale * (1 + math.sin(t * math.pi * 2 * e.speed) * 0.2);
    final width = 30 * scale;
    final height = 80 * scale;

    // Rift glow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: width * 1.5, height: height * 1.5),
      _riftGlowPaint..color = e.color.withOpacity(0.3),
    );

    // Rift core
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: width, height: height),
      _riftCorePaint..color = e.color.withOpacity(0.8),
    );
  }

  void _drawEcho(Canvas canvas, double x, double y, _WorldElement e, double t) {
    final alpha = (math.sin(t * math.pi * 4 * e.speed + e.x * 5) * 0.5 + 0.5) * 0.4;
    if (alpha < 0.1) return;

    canvas.drawCircle(
      Offset(x, y),
      10 * e.scale,
      _echoPaint..color = e.color.withOpacity(alpha),
    );
  }

  void _drawNoise(Canvas canvas, double x, double y, _WorldElement e, Size size, double t) {
    int state = ((t * 100000).toInt() ^ (x * 1000).toInt() ^ (y * 1000).toInt()) &
        0x7fffffff;
    state = _lcgNext(state);
    final noiseAlpha = (_lcgUnit(state) * 0.3).clamp(0.0, 0.3);
    if (noiseAlpha < 0.05) return;

    final rect = Rect.fromCenter(
      center: Offset(x, y),
      width: 30 * e.scale,
      height: 20 * e.scale,
    );

    canvas.drawRect(
      rect,
      _noisePaint..color = e.color.withOpacity(noiseAlpha),
    );
  }

  void _drawRuin(Canvas canvas, double x, double y, _WorldElement e, Size size) {
    final width = 40 * e.scale;
    final height = 60 * e.scale;

    // Ruined structure
    final path = _ruinPath..reset();
    path
      ..moveTo(x - width / 2, y)
      ..lineTo(x - width / 3, y - height * 0.7)
      ..lineTo(x - width / 4, y - height * 0.5)
      ..lineTo(x, y - height)
      ..lineTo(x + width / 4, y - height * 0.6)
      ..lineTo(x + width / 2, y)
      ..close();

    _ruinPaint.color = e.color.withOpacity(0.4);
    canvas.drawPath(path, _ruinPaint);
  }

  void _drawBeacon(Canvas canvas, double x, double y, _WorldElement e, double t) {
    final pulse = math.sin(t * math.pi * 4 * e.speed) * 0.5 + 0.5;

    // Beacon glow
    canvas.drawCircle(
      Offset(x, y - 30),
      15 + pulse * 10,
      _beaconGlowPaint..color = e.color.withOpacity(0.3 + pulse * 0.3),
    );

    // Beacon core
    canvas.drawCircle(
      Offset(x, y - 30),
      5,
      _beaconCorePaint..color = e.color,
    );

    // Beacon pole
    canvas.drawLine(
      Offset(x, y),
      Offset(x, y - 25),
      _beaconPolePaint..color = Colors.grey.withOpacity(0.5),
    );
  }

  void _drawCloud(Canvas canvas, double x, double y, _WorldElement e, Size size) {
    final wrappedX = x % size.width;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(wrappedX, y),
        width: 100 * e.scale,
        height: 30 * e.scale,
      ),
      _cloudPaint..color = e.color.withOpacity(0.4),
    );
  }

  void _drawLightning(Canvas canvas, double x, double y, _WorldElement e, Size size, double t) {
    // Only show lightning occasionally
    final show = (t * 10 * e.speed) % 1 < 0.1;
    if (!show) return;

    final path = _lightningPath..reset();
    path.moveTo(x, y);

    var currentY = y;
    var currentX = x;
    int state = ((t * 10000).toInt() ^ (x * 1000).toInt() ^ (y * 1000).toInt()) &
        0x7fffffff;
    while (currentY < size.height * 0.8) {
      state = _lcgNext(state);
      currentY += 20 + _lcgUnit(state) * 20;
      state = _lcgNext(state);
      currentX += (_lcgUnit(state) - 0.5) * 30;
      path.lineTo(currentX, currentY);
    }

    canvas.drawPath(
      path,
      _lightningPaint..color = e.color,
    );
  }

  void _drawCrown(Canvas canvas, double x, double y, _WorldElement e, Size size, double t) {
    final pulse = math.sin(t * math.pi * 2 * e.speed) * 0.2 + 1;

    // Crown ring
    canvas.drawCircle(
      Offset(x, y),
      50 * pulse,
      _crownRingPaint..color = e.color.withOpacity(0.3),
    );

    // Crown glow
    canvas.drawCircle(
      Offset(x, y),
      30,
      _crownGlowPaint..color = e.color.withOpacity(0.5),
    );
  }

  void _drawPlatform(Canvas canvas, double x, double y, _WorldElement e, Size size) {
    final width = 50 * e.scale;
    final height = 10 * e.scale;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y), width: width, height: height),
      const Radius.circular(3),
    );

    canvas.drawRRect(rrect, _platformPaint..color = e.color.withOpacity(0.6));
  }

  void _drawCrystal(Canvas canvas, double x, double y, _WorldElement e, double t) {
    final pulse = math.sin(t * math.pi * 4 * e.speed + e.x * 10) * 0.3 + 0.7;
    final size = 10 * e.scale;

    // Crystal shape (diamond)
    final path = _crystalPath..reset();
    path
      ..moveTo(x, y - size)
      ..lineTo(x + size * 0.6, y)
      ..lineTo(x, y + size * 0.4)
      ..lineTo(x - size * 0.6, y)
      ..close();

    canvas.drawPath(
      path,
      _crystalPaint..color = e.color.withOpacity(pulse),
    );
  }

  void _drawVault(Canvas canvas, double x, double y, _WorldElement e, Size size) {
    final width = 60 * e.scale;
    final height = 40 * e.scale;

    // Vault arch
    final path = _vaultPath..reset();
    path
      ..moveTo(x - width / 2, y)
      ..lineTo(x - width / 2, y - height * 0.6)
      ..quadraticBezierTo(x, y - height, x + width / 2, y - height * 0.6)
      ..lineTo(x + width / 2, y)
      ..close();

    canvas.drawPath(path, _vaultPaint..color = e.color.withOpacity(0.5));
  }

  void _drawStream(Canvas canvas, double x, _WorldElement e, Size size, double t) {
    final y = (t * e.speed * size.height * 2) % size.height;

    canvas.drawLine(
      Offset(x, y),
      Offset(x, y + 30),
      _streamPaint..color = e.color.withOpacity(0.5),
    );
  }

  void _drawCore(Canvas canvas, double x, double y, _WorldElement e, Size size, double t) {
    final pulse = math.sin(t * math.pi * 2 * e.speed) * 0.3 + 1;

    // Outer glow
    canvas.drawCircle(
      Offset(x, y),
      80 * pulse,
      _coreOuterPaint..color = e.color.withOpacity(0.1),
    );

    // Middle ring
    canvas.drawCircle(
      Offset(x, y),
      40 * pulse,
      _coreMidPaint..color = e.color.withOpacity(0.3),
    );

    // Core
    canvas.drawCircle(
      Offset(x, y),
      15,
      _corePaint..color = e.color,
    );
  }

  void _drawEnergyStream(Canvas canvas, double x, double y, _WorldElement e, Size size, double t) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final progress = (t * e.speed) % 1;
    final currentX = x + (centerX - x) * progress;
    final currentY = y + (centerY - y) * progress;

    canvas.drawCircle(
      Offset(currentX, currentY),
      5,
      _energyStreamPaint..color = e.color.withOpacity(0.7),
    );
  }

  void _drawDebris(Canvas canvas, double x, double y, _WorldElement e, double t) {
    final offset = math.sin(t * math.pi * 2 * e.speed + e.x * 5) * 5;
    final rotation = t * math.pi * 2 * e.speed;

    canvas.save();
    canvas.translate(x, y + offset);
    canvas.rotate(rotation);

    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 8 * e.scale, height: 8 * e.scale),
      _debrisPaint..color = e.color.withOpacity(0.5),
    );

    canvas.restore();
  }

  void _drawVignette(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    if (_vignetteCacheSize != size) {
      _vignetteCacheSize = size;
      _vignetteShader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.4),
          Colors.black.withOpacity(0.8),
        ],
        stops: const [0.3, 0.7, 1.0],
      ).createShader(rect);
    }

    _vignettePaint.shader = _vignetteShader;
    canvas.drawRect(rect, _vignettePaint);
  }

  void _drawBorderGlow(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    canvas.drawRRect(
      rect,
      _borderPaint..color = accentColor.withOpacity(0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _WorldArtPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
