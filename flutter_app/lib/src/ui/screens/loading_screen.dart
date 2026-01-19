import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../../services/audio_service.dart';
import '../../services/procedural_music_service.dart';
import '../../services/sprite_cache_service.dart';
import '../../services/storage_service.dart';
import '../../services/level_service.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late AnimationController _textController;

  String _loadingText = 'INITIALIZING';
  double _progress = 0.0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Stage 1: Storage
    setState(() {
      _loadingText = 'LOADING STORAGE';
      _progress = 0.2;
    });
    await StorageService.instance.initialize();
    await Future.delayed(const Duration(milliseconds: 300));

    // Stage 2: Level Service
    setState(() {
      _loadingText = 'LOADING LEVELS';
      _progress = 0.5;
    });
    await LevelService.instance.initialize();
    await Future.delayed(const Duration(milliseconds: 300));

    // Stage 3: Audio
    setState(() {
      _loadingText = 'LOADING AUDIO';
      _progress = 0.7;
    });
    await AudioService.instance.initialize();
    await Future.delayed(const Duration(milliseconds: 200));

    // Stage 4: Music System
    setState(() {
      _loadingText = 'INITIALIZING MUSIC';
      _progress = 0.80;
    });
    await ProceduralMusicService.instance.initialize();
    await Future.delayed(const Duration(milliseconds: 200));

    // Stage 5: Sprite Cache (pre-render sprites for performance)
    setState(() {
      _loadingText = 'PRE-RENDERING SPRITES';
      _progress = 0.90;
    });
    await SpriteCacheService.instance.initialize();
    await Future.delayed(const Duration(milliseconds: 100));

    // Stage 6: Final Assets
    setState(() {
      _loadingText = 'LOADING ASSETS';
      _progress = 0.95;
    });
    await Future.delayed(const Duration(milliseconds: 200));

    // Stage 7: Complete
    setState(() {
      _loadingText = 'READY';
      _progress = 1.0;
      _isComplete = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));

    // Navigate to main menu
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/menu');
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.darkBg,
      body: Stack(
        children: [
          // Animated background grid
          CustomPaint(
            painter: _GridPainter(animation: _spinController),
            size: Size.infinite,
          ),

          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Neon Spinner
                SizedBox(
                  width: 150,
                  height: 150,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_spinController, _pulseController]),
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _NeonSpinnerPainter(
                          spinProgress: _spinController.value,
                          pulseProgress: _pulseController.value,
                          loadProgress: _progress,
                          isComplete: _isComplete,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 48),

                // Loading text with glow
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    final opacity = 0.7 + _textController.value * 0.3;
                    return Text(
                      _loadingText,
                      style: NeonTextStyles.subtitle.copyWith(
                        color: _isComplete ? NeonColors.green : NeonColors.cyan,
                        letterSpacing: 6,
                        shadows: [
                          Shadow(
                            color: (_isComplete ? NeonColors.green : NeonColors.cyan)
                                .withOpacity(opacity),
                            blurRadius: 15,
                          ),
                          Shadow(
                            color: (_isComplete ? NeonColors.green : NeonColors.cyan)
                                .withOpacity(opacity * 0.5),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Progress bar
                SizedBox(
                  width: 250,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _ProgressBarPainter(
                          progress: _progress,
                          pulseProgress: _pulseController.value,
                          isComplete: _isComplete,
                        ),
                        size: const Size(250, 8),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Percentage
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: NeonTextStyles.body.copyWith(
                    color: NeonColors.cyan.withOpacity(0.7),
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),

          // Corner decorations
          ..._buildCornerDecorations(),

          // Bottom version text
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'NEON DEFENSE v1.0.0',
                style: NeonTextStyles.small.copyWith(
                  color: NeonColors.cyan.withOpacity(0.4),
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerDecorations() {
    return [
      // Top left
      Positioned(
        top: 20,
        left: 20,
        child: _CornerDecoration(color: NeonColors.cyan),
      ),
      // Top right
      Positioned(
        top: 20,
        right: 20,
        child: Transform.scale(
          scaleX: -1,
          child: _CornerDecoration(color: NeonColors.magenta),
        ),
      ),
      // Bottom left
      Positioned(
        bottom: 60,
        left: 20,
        child: Transform.scale(
          scaleY: -1,
          child: _CornerDecoration(color: NeonColors.magenta),
        ),
      ),
      // Bottom right
      Positioned(
        bottom: 60,
        right: 20,
        child: Transform.scale(
          scaleX: -1,
          scaleY: -1,
          child: _CornerDecoration(color: NeonColors.cyan),
        ),
      ),
    ];
  }
}

class _CornerDecoration extends StatelessWidget {
  final Color color;

  const _CornerDecoration({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CornerPainter(color: color),
      size: const Size(40, 40),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;

  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.6, 0);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  final Animation<double> animation;

  _GridPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NeonColors.gridLine.withOpacity(0.3)
      ..strokeWidth = 1;

    const spacing = 50.0;
    final offset = (animation.value * spacing) % spacing;

    // Vertical lines
    for (double x = offset; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = offset; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _NeonSpinnerPainter extends CustomPainter {
  final double spinProgress;
  final double pulseProgress;
  final double loadProgress;
  final bool isComplete;

  _NeonSpinnerPainter({
    required this.spinProgress,
    required this.pulseProgress,
    required this.loadProgress,
    required this.isComplete,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Outer glow ring
    final outerGlowPaint = Paint()
      ..color = (isComplete ? NeonColors.green : NeonColors.cyan)
          .withOpacity(0.15 + pulseProgress * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, radius, outerGlowPaint);

    // Background track
    final trackPaint = Paint()
      ..color = NeonColors.gridLine.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc (shows load progress)
    final progressPaint = Paint()
      ..color = (isComplete ? NeonColors.green : NeonColors.magenta)
          .withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * loadProgress,
      false,
      progressPaint,
    );

    // Spinning indicator
    if (!isComplete) {
      final spinAngle = spinProgress * math.pi * 2;

      // Primary spinner arc
      final spinnerPaint = Paint()
        ..shader = SweepGradient(
          startAngle: spinAngle,
          endAngle: spinAngle + math.pi,
          colors: [
            NeonColors.cyan.withOpacity(0),
            NeonColors.cyan,
            NeonColors.cyan.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 8),
        spinAngle,
        math.pi * 0.7,
        false,
        spinnerPaint,
      );

      // Secondary spinner (opposite direction)
      final secondaryPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -spinAngle * 1.5,
          endAngle: -spinAngle * 1.5 + math.pi,
          colors: [
            NeonColors.magenta.withOpacity(0),
            NeonColors.magenta.withOpacity(0.6),
            NeonColors.magenta.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius - 16))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 16),
        -spinAngle * 1.5,
        math.pi * 0.5,
        false,
        secondaryPaint,
      );
    }

    // Center hexagon
    _drawHexagon(canvas, center, 25 + pulseProgress * 3, isComplete);

    // Center dot
    final dotPaint = Paint()
      ..color = isComplete ? NeonColors.green : NeonColors.cyan
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, 4, dotPaint);
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, bool complete) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final hexPaint = Paint()
      ..color = (complete ? NeonColors.green : NeonColors.cyan).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final hexGlowPaint = Paint()
      ..color = (complete ? NeonColors.green : NeonColors.cyan).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, hexGlowPaint);
    canvas.drawPath(path, hexPaint);
  }

  @override
  bool shouldRepaint(covariant _NeonSpinnerPainter oldDelegate) => true;
}

class _ProgressBarPainter extends CustomPainter {
  final double progress;
  final double pulseProgress;
  final bool isComplete;

  _ProgressBarPainter({
    required this.progress,
    required this.pulseProgress,
    required this.isComplete,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    // Background
    final bgPaint = Paint()..color = NeonColors.gridLine.withOpacity(0.5);
    canvas.drawRRect(rrect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = (isComplete ? NeonColors.green : NeonColors.cyan).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);

    // Progress fill
    if (progress > 0) {
      final fillWidth = size.width * progress;
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, fillWidth, size.height),
        const Radius.circular(4),
      );

      // Gradient fill
      final fillPaint = Paint()
        ..shader = LinearGradient(
          colors: isComplete
              ? [NeonColors.green, NeonColors.cyan]
              : [NeonColors.cyan, NeonColors.magenta],
        ).createShader(rect);
      canvas.drawRRect(fillRect, fillPaint);

      // Glow effect
      final glowPaint = Paint()
        ..color = (isComplete ? NeonColors.green : NeonColors.cyan)
            .withOpacity(0.3 + pulseProgress * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(fillRect, glowPaint);

      // Shine highlight
      if (!isComplete) {
        final shineX = fillWidth * pulseProgress;
        final shinePaint = Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(shineX, size.height / 2), 3, shinePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressBarPainter oldDelegate) => true;
}
