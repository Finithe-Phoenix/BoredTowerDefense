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
  
  // Colors (matching Pulse Archer default or generic)
  final Color _primaryColor = const Color(0xFF00FFFF); 
  final Color _secondaryColor = const Color(0xFF0088FF);

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
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas); // likely empty
    
    // Draw in order
    _renderSkybox(canvas);
    _renderTerrain(canvas);
    _renderAtmosphere(canvas);
  }

  void _renderSkybox(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0D0221), // Deep space purple
        const Color(0xFF1A0033),
        const Color(0xFF240046), 
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
    
    // Draw Stars
    final starPaint = Paint()..color = Colors.white.withOpacity(0.6);
    final r = math.Random(1337); 
    for(int i=0; i<100; i++) {
        canvas.drawCircle(Offset(r.nextDouble() * size.x, r.nextDouble() * size.y * 0.6), r.nextDouble() * 1.5, starPaint);
    }
  }

  void _renderTerrain(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final horizonY = h * 0.55; 
    
    // Grid Setup
    final gridPaint = Paint()
      ..color = _primaryColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    final scrollZ = _animationTime * 100; 
    
    // Vertical perspective lines
    for (double x = -w; x < w * 2; x += 50) {
       final p1 = Offset(x, horizonY);
       final p2 = Offset((x - w/2) * 5 + w/2, h); 
       canvas.drawLine(p1, p2, gridPaint);
    }
    
    // Horizontal Hills
    final hillPaint = Paint()
       ..color = _secondaryColor.withOpacity(0.5)
       ..style = PaintingStyle.stroke
       ..strokeWidth = 2;
       
    for (double z = 0; z < 10; z+=0.5) {
       final dist = z * 50; 
       final depthScale = 1.0 / (z + 1.0);
       final yBase = horizonY + dist * 0.1; 
       if (yBase > h) break;
       
       final path = Path();
       bool started = false;
       final waveOffset = scrollZ * 0.05;
       
       for(double x = 0; x <= w; x+=20) {
           final noise1 = math.sin(x * 0.01 + z * 0.5 + waveOffset);
           final noise2 = math.cos(x * 0.03 - z * 0.2);
           final height = (noise1 * 30 + noise2 * 10) * depthScale;
           
           final yPos = horizonY + (height * math.max(0, 1.0 - z*0.1)) + (z*15)*depthScale; 
           
           if (!started) {
               path.moveTo(x, yPos);
               started = true;
           } else {
               path.lineTo(x, yPos);
           }
       }
       canvas.drawPath(path, hillPaint);
    }
  }
  
  void _renderAtmosphere(Canvas canvas) {
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
     canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
     
     // Floor Fade (crucial to blend with game world)
     final floorRect = Rect.fromLTWH(0, h * 0.8, size.x, h * 0.2);
     final floorGrad = LinearGradient(
       begin: Alignment.topCenter,
       end: Alignment.bottomCenter,
       colors: [Colors.transparent, Colors.black],
     );
     canvas.drawRect(floorRect, Paint()..shader = floorGrad.createShader(floorRect));
  }
}
