import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../bored_games_game.dart';

class FpsBackgroundComponent extends PositionComponent with HasGameRef<BoredGamesGame> {
  FpsBackgroundComponent() : super(priority: -100);

  double _animationTime = 0;
  // Use a fixed intro time or sync it if needed. 
  // For background, we can assume it's always "on" or fades in quickly.
  double _introTime = 0;

  // Cached static layer (skybox + static grid + atmosphere).
  Picture? _staticLayer;
  bool _staticLayerDirty = true;
  double _staticLayerWidth = 0;
  double _staticLayerHeight = 0;
  final List<_Star> _stars = [];
  bool _starsDirty = true;
  final List<double> _hillSampleXs = [];
  double _hillSampleWidth = 0;

  static final Paint _skyPaint = Paint();
  static final Paint _starPaint = Paint()..color = Colors.white;
  static final Paint _gridPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _horizonGlowPaint = Paint();
  static final Paint _floorFadePaint = Paint();
  final Path _hillPath = Path();

  // Colors (matching Pulse Archer default or generic)
  final Color _primaryColor = const Color(0xFF00FFFF); 
  final Color _secondaryColor = const Color(0xFF0088FF);
  late final Paint _hillPaint = Paint()
    ..color = _secondaryColor.withOpacity(0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2.zero();
    this.size = size.clone();
    _staticLayerDirty = true;
    _staticLayer?.dispose();
    _staticLayer = null;
    _starsDirty = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animationTime += dt;
    _introTime += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas); // likely empty
    if (size.isZero()) return;

    _ensureStaticLayer();
    if (_staticLayer != null) {
      canvas.drawPicture(_staticLayer!);
    }

    // Draw dynamic layers
    _renderTerrainDynamic(canvas);
  }

  void _ensureStaticLayer() {
    if (!_staticLayerDirty &&
        _staticLayerWidth == size.x &&
        _staticLayerHeight == size.y) {
      return;
    }

    _staticLayerWidth = size.x;
    _staticLayerHeight = size.y;
    final recorder = PictureRecorder();
    final staticCanvas = Canvas(recorder);
    _renderSkyboxStatic(staticCanvas);
    _renderTerrainStatic(staticCanvas);
    _renderAtmosphereStatic(staticCanvas);
    _staticLayer?.dispose();
    _staticLayer = recorder.endRecording();
    _staticLayerDirty = false;
  }

  void _renderSkyboxStatic(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0D0221), // Deep space purple
        Color(0xFF1A0033),
        Color(0xFF240046), 
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    
    _skyPaint.shader = gradient.createShader(rect);
    canvas.drawRect(rect, _skyPaint);
    
    // Draw Stars
    _ensureStars();
    _starPaint.color = Colors.white.withOpacity(0.6);
    for (final star in _stars) {
      canvas.drawCircle(star.position, star.radius, _starPaint);
    }
  }

  void _renderTerrainStatic(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final horizonY = h * 0.55; 
    
    // Grid Setup
    _gridPaint.color = _primaryColor.withOpacity(0.3);
      
    // Vertical perspective lines
    for (double x = -w; x < w * 2; x += 50) {
       final p1 = Offset(x, horizonY);
       final p2 = Offset((x - w/2) * 5 + w/2, h); 
       canvas.drawLine(p1, p2, _gridPaint);
    }
  }

  void _renderTerrainDynamic(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final horizonY = h * 0.55;
    final scrollZ = _animationTime * 100;
    _ensureHillSamples(w);

    // Horizontal Hills
    for (double z = 0; z < 10; z+=0.5) {
       final dist = z * 50; 
       final depthScale = 1.0 / (z + 1.0);
       final yBase = horizonY + dist * 0.1; 
       if (yBase > h) break;
       _hillPath.reset();
       bool started = false;
       final waveOffset = scrollZ * 0.05;
       
       for (final x in _hillSampleXs) {
         final noise1 = math.sin(x * 0.01 + z * 0.5 + waveOffset);
         final noise2 = math.cos(x * 0.03 - z * 0.2);
         final height = (noise1 * 30 + noise2 * 10) * depthScale;
         
         final yPos = horizonY + (height * math.max(0, 1.0 - z*0.1)) + (z*15)*depthScale; 
         
         if (!started) {
           _hillPath.moveTo(x, yPos);
           started = true;
         } else {
           _hillPath.lineTo(x, yPos);
         }
       }
       canvas.drawPath(_hillPath, _hillPaint);
    }
  }
  
  void _renderAtmosphereStatic(Canvas canvas) {
     final h = size.y;
     final horizonY = h * 0.55;
     
     // Horizon Glow
     final rect = Rect.fromLTWH(0, horizonY - 50, size.x, 150);
     final gradient = LinearGradient(
       begin: Alignment.topCenter,
       end: Alignment.bottomCenter,
       colors: [
         Colors.transparent,
         _primaryColor.withOpacity(0.4),
         Colors.transparent,
       ],
       stops: const [0.0, 0.5, 1.0],
     );
     _horizonGlowPaint.shader = gradient.createShader(rect);
     canvas.drawRect(rect, _horizonGlowPaint);
     
     // Floor Fade (crucial to blend with game world)
     final floorRect = Rect.fromLTWH(0, h * 0.8, size.x, h * 0.2);
     const floorGrad = LinearGradient(
       begin: Alignment.topCenter,
       end: Alignment.bottomCenter,
       colors: [Colors.transparent, Colors.black],
     );
     _floorFadePaint.shader = floorGrad.createShader(floorRect);
     canvas.drawRect(floorRect, _floorFadePaint);
  }

  void _ensureStars() {
    if (!_starsDirty && _stars.isNotEmpty) {
      return;
    }
    _starsDirty = false;
    _stars.clear();
    final width = size.x;
    final height = size.y * 0.6;
    int seed = 1337;
    for (int i = 0; i < 100; i++) {
      seed = (1664525 * seed + 1013904223) & 0x7fffffff;
      final x = (seed / 0x7fffffff) * width;
      seed = (1664525 * seed + 1013904223) & 0x7fffffff;
      final y = (seed / 0x7fffffff) * height;
      seed = (1664525 * seed + 1013904223) & 0x7fffffff;
      final r = (seed / 0x7fffffff) * 1.5;
      _stars.add(_Star(Offset(x, y), r));
    }
  }

  void _ensureHillSamples(double width) {
    if (_hillSampleWidth == width && _hillSampleXs.isNotEmpty) {
      return;
    }
    _hillSampleWidth = width;
    _hillSampleXs.clear();
    for (double x = 0; x <= width; x += 20) {
      _hillSampleXs.add(x);
    }
  }
}

class _Star {
  _Star(this.position, this.radius);

  final Offset position;
  final double radius;
}
