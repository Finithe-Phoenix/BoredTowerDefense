import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/neon_theme.dart';
import '../../bloc/settings/settings_cubit.dart';
import '../../services/audio_service.dart';
import '../../services/procedural_music_service.dart';
import '../../services/sprite_cache_service.dart';
import '../../services/storage_service.dart';
import '../../services/level_service.dart';

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

class _PendingDelay {
  _PendingDelay({
    required this.timer,
    required this.completer,
  });

  final Timer timer;
  final Completer<void> completer;
}

/// Tech-grid loading screen with cyberpunk visual effects.
///
/// Layers (bottom to top):
/// 1. Dark background with animated hexagonal grid
/// 2. Scanning lines moving across screen
/// 3. Central loading indicator (rotating tech circle)
/// 4. Progress bar with neon glow
/// 5. Loading text with glitch effect
/// 6. Data stream particles flowing
/// 7. Corner decorations with status indicators
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _gridController;
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late AnimationController _textController;
  late AnimationController _scanController;
  late AnimationController _particleController;

  // State
  String _loadingText = 'INITIALIZING';
  double _progress = 0.0;
  bool _isComplete = false;
  bool _reduceFx = false; // Performance flag

  // Glitch state
  double _glitchOffset = 0.0;
  bool _isGlitching = false;
  int _glitchFrame = 0;

  // Data stream particles
  final List<_DataParticle> _particles = [];
  final _FastRng _random = _FastRng();

  // Timers for cleanup
  Timer? _glitchDelayTimer;
  Timer? _glitchResetTimer;
  final List<_PendingDelay> _pendingDelays = <_PendingDelay>[];
  bool _disposed = false;

  @override
  void initState() {
    super.initState();

    // Grid animation (slow movement)
    _gridController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Spin animation for central indicator
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Pulse animation for glow effects
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Text flicker animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    // Scan line animation
    _scanController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Initialize particles
    _initParticles();

    // Start glitch effect
    _startGlitchEffect();

    // Update particles
    _particleController.addListener(_updateParticles);

    _initializeServices();
  }

  void _initParticles() {
    _particles.clear();
    for (int i = 0; i < 40; i++) {
      _particles.add(_DataParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.002 + _random.nextDouble() * 0.005,
        size: 1.0 + _random.nextDouble() * 2.0,
        opacity: 0.3 + _random.nextDouble() * 0.5,
        color: _random.nextBool() ? NeonColors.cyan : NeonColors.magenta,
        char: _random.nextInt(2).toString(),
      ));
    }
  }

  void _updateParticles() {
    for (final p in _particles) {
      p.y += p.speed;
      if (p.y > 1.1) {
        p.y = -0.1;
        p.x = _random.nextDouble();
        p.char = _random.nextInt(2).toString();
      }
    }
  }

  void _startGlitchEffect() {
    _glitchDelayTimer?.cancel();
    _glitchDelayTimer =
        Timer(Duration(milliseconds: 500 + _random.nextInt(2000)), () {
      if (!mounted) return;
      setState(() {
        _isGlitching = true;
        _glitchOffset = (_random.nextDouble() - 0.5) * 10;
        _glitchFrame++;
      });
      _glitchResetTimer?.cancel();
      _glitchResetTimer = Timer(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        setState(() {
          _isGlitching = false;
          _glitchOffset = 0;
        });
        _startGlitchEffect();
      });
    });
  }

  /// Update the loading progress (0.0 to 1.0).
  void updateProgress(double progress) {
    setState(() {
      _progress = progress.clamp(0.0, 1.0);
    });
  }

  /// Update the loading text with optional glitch effect.
  void updateLoadingText(String text) {
    setState(() {
      _loadingText = text;
    });
  }

  void _setLoadingState({
    String? text,
    double? progress,
    bool? isComplete,
  }) {
    if (!mounted) return;
    setState(() {
      if (text != null) _loadingText = text;
      if (progress != null) _progress = progress.clamp(0.0, 1.0);
      if (isComplete != null) _isComplete = isComplete;
    });
  }

  Future<void> _delay(Duration duration) {
    if (_disposed || !mounted) return Future.value();

    final completer = Completer<void>();
    late final Timer timer;
    timer = Timer(duration, () {
      _pendingDelays.removeWhere((entry) => identical(entry.timer, timer));
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    _pendingDelays.add(_PendingDelay(timer: timer, completer: completer));
    return completer.future;
  }

  void _cancelPendingDelays() {
    for (final entry in _pendingDelays) {
      entry.timer.cancel();
      if (!entry.completer.isCompleted) {
        entry.completer.complete();
      }
    }
    _pendingDelays.clear();
  }

  void _logLoading(String message) {
    if (kDebugMode) {
      debugPrint('[LoadingScreen] $message');
    }
  }

  Future<void> _runInitStage({
    required String label,
    required double targetProgress,
    required Future<void> Function() task,
    Duration timeout = const Duration(seconds: 4),
    String? degradedLabel,
  }) async {
    _setLoadingState(text: label);

    final stageStart = _progress;
    final stageCeiling = math.max(stageStart, targetProgress - 0.02);
    var completed = false;
    var failed = false;

    final operation = task().then((_) {
      completed = true;
    }).catchError((Object error, StackTrace stackTrace) {
      completed = true;
      failed = true;
      _logLoading('Stage "$label" failed: $error');
    });

    final watch = Stopwatch()..start();
    while (mounted && !completed && watch.elapsed < timeout) {
      final t =
          (watch.elapsedMilliseconds / timeout.inMilliseconds).clamp(0.0, 1.0);
      final eased = Curves.easeOut.transform(t);
      final visualProgress = stageStart + (stageCeiling - stageStart) * eased;
      if (visualProgress > _progress) {
        _setLoadingState(progress: visualProgress);
      }
      await _delay(const Duration(milliseconds: 80));
    }

    final timedOut = !completed;
    if (timedOut) {
      _logLoading('Stage "$label" timed out after ${timeout.inMilliseconds}ms');
      unawaited(operation);
    } else {
      await operation;
    }

    if (failed || timedOut) {
      _setLoadingState(text: degradedLabel ?? '$label (SAFE MODE)');
    }

    if (mounted && _progress < targetProgress) {
      _setLoadingState(progress: targetProgress);
    }
  }

  Future<void> _initializeServices() async {
    try {
      await _runInitStage(
        label: 'LOADING STORAGE',
        targetProgress: 0.15,
        timeout: const Duration(seconds: 4),
        degradedLabel: 'STORAGE DELAYED',
        task: () => StorageService.instance.initialize(),
      );

      SettingsCubit? settingsCubit;
      try {
        settingsCubit = context.read<SettingsCubit>();
      } catch (_) {
        settingsCubit = null;
      }
      if (settingsCubit != null) {
        final activeSettingsCubit = settingsCubit;
        await _runInitStage(
          label: 'SYNCING SETTINGS',
          targetProgress: 0.30,
          timeout: const Duration(seconds: 2),
          degradedLabel: 'SETTINGS DEFAULTED',
          task: () => activeSettingsCubit.loadSettings(),
        );

        final quality = activeSettingsCubit.state.graphicsQuality;
        if ((quality == 'low' || quality == 'medium') &&
            mounted &&
            !_reduceFx) {
          setState(() {
            _reduceFx = true;
          });
        }
      } else {
        _logLoading('SettingsCubit not found; using default graphics settings');
      }

      await _runInitStage(
        label: 'LOADING LEVELS',
        targetProgress: 0.50,
        timeout: const Duration(seconds: 4),
        degradedLabel: 'LEVEL CACHE DELAYED',
        task: () => LevelService.instance.initialize(),
      );

      await _runInitStage(
        label: 'LOADING AUDIO',
        targetProgress: 0.70,
        timeout: const Duration(seconds: 4),
        degradedLabel: 'AUDIO DELAYED',
        task: () => AudioService.instance.initialize(),
      );

      await _runInitStage(
        label: 'WARMING MUSIC ENGINE',
        targetProgress: 0.84,
        timeout: const Duration(seconds: 3),
        degradedLabel: 'MUSIC WARMUP IN BACKGROUND',
        task: () => ProceduralMusicService.instance.initialize(),
      );

      await _runInitStage(
        label: 'BUILDING SPRITE CACHE',
        targetProgress: 0.96,
        timeout: const Duration(seconds: 3),
        degradedLabel: 'SPRITE CACHE CONTINUES IN BACKGROUND',
        task: () => SpriteCacheService.instance.initialize(),
      );
    } catch (error, stackTrace) {
      _logLoading('Unexpected initialization error: $error');
      _logLoading('$stackTrace');
      _setLoadingState(text: 'SAFE MODE BOOT');
    }

    _setLoadingState(
      text: 'READY',
      progress: 1.0,
      isComplete: true,
    );
    await _delay(const Duration(milliseconds: 350));

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/menu');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _glitchDelayTimer?.cancel();
    _glitchResetTimer?.cancel();
    _cancelPendingDelays();
    _gridController.dispose();
    _spinController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _scanController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.darkBg,
      body: Stack(
        children: [
          // LAYER 1: Animated hexagonal grid background
          AnimatedBuilder(
            animation: _gridController,
            builder: (context, child) {
              return CustomPaint(
                painter: _HexGridPainter(
                  animation: _gridController.value,
                  reduceFx: _reduceFx,
                ),
                size: Size.infinite,
              );
            },
          ),

          // LAYER 2: Scanning lines
          if (!_reduceFx)
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ScanLinePainter(
                    animation: _scanController.value,
                    pulseAnimation: _pulseController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),

          // LAYER 6: Data stream particles (behind center content)
          if (!_reduceFx)
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _DataStreamPainter(
                    particles: _particles,
                    animation: _particleController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),

          // Center content (LAYERS 3, 4, 5)
          Center(
            child: Transform.translate(
              offset: _isGlitching ? Offset(_glitchOffset, 0) : Offset.zero,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LAYER 3: Central loading indicator (rotating tech circle)
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: AnimatedBuilder(
                      animation:
                          Listenable.merge([_spinController, _pulseController]),
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _TechCirclePainter(
                            spinProgress: _spinController.value,
                            pulseProgress: _pulseController.value,
                            loadProgress: _progress,
                            isComplete: _isComplete,
                            reduceFx: _reduceFx,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 48),

                  // LAYER 5: Loading text with glitch effect
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return _GlitchTextWidget(
                        text: _loadingText,
                        isGlitching: _isGlitching,
                        glitchFrame: _glitchFrame,
                        flickerOpacity: 0.7 + _textController.value * 0.3,
                        isComplete: _isComplete,
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // LAYER 4: Progress bar with neon glow
                  SizedBox(
                    width: 280,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _NeonProgressBarPainter(
                            progress: _progress,
                            pulseProgress: _pulseController.value,
                            isComplete: _isComplete,
                            reduceFx: _reduceFx,
                          ),
                          size: const Size(280, 12),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Percentage display
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
          ),

          // LAYER 7: Corner decorations with status indicators
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
      // Top left - with status indicator
      Positioned(
        top: 20,
        left: 20,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return _CornerDecoration(
              color: NeonColors.cyan,
              pulseProgress: _pulseController.value,
              statusText: 'SYS',
              isActive: true,
            );
          },
        ),
      ),
      // Top right
      Positioned(
        top: 20,
        right: 20,
        child: Transform.scale(
          scaleX: -1,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return _CornerDecoration(
                color: NeonColors.magenta,
                pulseProgress: _pulseController.value,
                statusText: 'NET',
                isActive: _progress > 0.3,
              );
            },
          ),
        ),
      ),
      // Bottom left
      Positioned(
        bottom: 60,
        left: 20,
        child: Transform.scale(
          scaleY: -1,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return _CornerDecoration(
                color: NeonColors.magenta,
                pulseProgress: _pulseController.value,
                statusText: 'MEM',
                isActive: _progress > 0.5,
              );
            },
          ),
        ),
      ),
      // Bottom right
      Positioned(
        bottom: 60,
        right: 20,
        child: Transform.scale(
          scaleX: -1,
          scaleY: -1,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return _CornerDecoration(
                color: _isComplete ? NeonColors.green : NeonColors.cyan,
                pulseProgress: _pulseController.value,
                statusText: _isComplete ? 'OK' : 'CPU',
                isActive: _progress > 0.7,
              );
            },
          ),
        ),
      ),
    ];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA PARTICLE CLASS
// ═══════════════════════════════════════════════════════════════════════════
class _DataParticle {
  _DataParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.color,
    required this.char,
  });

  double x;
  double y;
  final double speed;
  final double size;
  final double opacity;
  final Color color;
  String char;
}

// ═══════════════════════════════════════════════════════════════════════════
// LAYER 1: HEXAGONAL GRID PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class _HexGridPainter extends CustomPainter {
  _HexGridPainter({
    required this.animation,
    required this.reduceFx,
  });

  final double animation;
  final bool reduceFx;

  // Static paints to avoid per-frame allocations
  static final Paint _bgPaint = Paint();
  static final Paint _hexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _hexGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _gridLinePaint = Paint()..strokeWidth = 1;
  static final Path _hexPath = Path();

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        NeonColors.deepBlack,
        NeonColors.darkBg,
        const Color(0xFF0A0A1A),
        NeonColors.deepBlack,
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
    _bgPaint.shader = bgGradient.createShader(bgRect);
    canvas.drawRect(bgRect, _bgPaint);

    // Animated hexagonal grid
    const hexSize = 60.0;
    final offset = animation * hexSize;
    final rows = (size.height / (hexSize * 1.5)).ceil() + 2;
    final cols = (size.width / (hexSize * 1.732)).ceil() + 2;

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final xPos = col * hexSize * 1.732 + (offset % (hexSize * 1.732));
        final yPos = row * hexSize * 1.5 + (col.isOdd ? hexSize * 0.75 : 0);

        // Calculate distance from center for fade effect
        final dx = xPos - size.width / 2;
        final dy = yPos - size.height / 2;
        final dist = math.sqrt(dx * dx + dy * dy);
        final maxDist =
            math.sqrt(size.width * size.width + size.height * size.height) / 2;
        final fadeAlpha = (1 - (dist / maxDist)).clamp(0.0, 1.0);

        // Base hex color
        final baseOpacity = 0.15 * fadeAlpha;
        _hexPaint.color = NeonColors.gridLine.withOpacity(baseOpacity);
        _drawHexagon(canvas, Offset(xPos, yPos), hexSize * 0.4, _hexPaint);

        // Glow effect on some hexagons (pulsing)
        if (!reduceFx && (row + col) % 5 == 0) {
          final pulseOffset = animation * math.pi * 2 + row + col;
          final pulse = (math.sin(pulseOffset) + 1) / 2;
          _hexGlowPaint.color =
              NeonColors.cyan.withOpacity(0.1 * pulse * fadeAlpha);
          _drawHexagon(
              canvas, Offset(xPos, yPos), hexSize * 0.4, _hexGlowPaint);
        }
      }
    }

    // Subtle grid lines overlay
    _gridLinePaint.color = NeonColors.gridLine.withOpacity(0.1);
    const gridSpacing = 80.0;
    for (double x = (offset * 0.5) % gridSpacing;
        x < size.width;
        x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _gridLinePaint);
    }
    for (double y = (offset * 0.3) % gridSpacing;
        y < size.height;
        y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridLinePaint);
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    _hexPath.reset();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        _hexPath.moveTo(x, y);
      } else {
        _hexPath.lineTo(x, y);
      }
    }
    _hexPath.close();
    canvas.drawPath(_hexPath, paint);
  }

  @override
  bool shouldRepaint(covariant _HexGridPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

// ═══════════════════════════════════════════════════════════════════════════
// LAYER 2: SCAN LINE PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class _ScanLinePainter extends CustomPainter {
  _ScanLinePainter({
    required this.animation,
    required this.pulseAnimation,
  });

  final double animation;
  final double pulseAnimation;

  // Static paints
  static final Paint _scanPaint = Paint();
  static final Paint _subtleScanPaint = Paint()
    ..color = const Color(0x08000000);
  static final Paint _verticalScanPaint = Paint();
  static final Map<int, Shader> _scanShaderCache = {};
  static final Map<int, Shader> _verticalShaderCache = {};
  static double _scanShaderWidth = 0;
  static double _verticalShaderHeight = 0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    // Subtle horizontal scanlines (CRT effect)
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _subtleScanPaint);
    }

    // Primary horizontal scan beam
    final scanY = animation * (size.height + 100) - 50;
    final scanRect = Rect.fromLTWH(0, scanY, size.width, 80);
    if (_scanShaderWidth != size.width) {
      _scanShaderWidth = size.width;
      _scanShaderCache.clear();
    }
    const pulseLevels = 16;
    final pulseLevel =
        (pulseAnimation * pulseLevels).round().clamp(0, pulseLevels);
    final scanKey = (_scanShaderWidth.round() << 8) ^ pulseLevel;
    final scanShader = _scanShaderCache.putIfAbsent(scanKey, () {
      final midOpacity = 0.2 + (pulseLevel / pulseLevels) * 0.1;
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          NeonColors.cyan.withOpacity(0.08),
          NeonColors.cyan.withOpacity(midOpacity),
          NeonColors.cyan.withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, _scanShaderWidth, 80));
    });
    _scanPaint.shader = scanShader;
    canvas.drawRect(scanRect, _scanPaint);

    // Secondary vertical scan beam (slower)
    final scanX = ((animation * 0.7) % 1.0) * (size.width + 60) - 30;
    final vScanRect = Rect.fromLTWH(scanX, 0, 60, size.height);
    if (_verticalShaderHeight != size.height) {
      _verticalShaderHeight = size.height;
      _verticalShaderCache.clear();
    }
    final vKey = _verticalShaderHeight.round();
    final vShader = _verticalShaderCache.putIfAbsent(vKey, () {
      return LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          NeonColors.magenta.withOpacity(0.05),
          NeonColors.magenta.withOpacity(0.12),
          NeonColors.magenta.withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, 60, _verticalShaderHeight));
    });
    _verticalScanPaint.shader = vShader;
    canvas.drawRect(vScanRect, _verticalScanPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.pulseAnimation != pulseAnimation;
}

// ═══════════════════════════════════════════════════════════════════════════
// LAYER 3: TECH CIRCLE (CENTRAL LOADING INDICATOR)
// ═══════════════════════════════════════════════════════════════════════════
class _TechCirclePainter extends CustomPainter {
  _TechCirclePainter({
    required this.spinProgress,
    required this.pulseProgress,
    required this.loadProgress,
    required this.isComplete,
    required this.reduceFx,
  });

  final double spinProgress;
  final double pulseProgress;
  final double loadProgress;
  final bool isComplete;
  final bool reduceFx;

  // Static paints
  static final Paint _outerGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 20
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _trackPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  static final Paint _progressPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;
  static final Paint _spinnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  static final Paint _secondarySpinnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _innerRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _hexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _hexGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _dotPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _tickPaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _dataPaint = Paint()..strokeWidth = 1;
  static final Path _hexPath = Path();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15;
    final primaryColor = isComplete ? NeonColors.green : NeonColors.cyan;
    final secondaryColor = isComplete ? NeonColors.cyan : NeonColors.magenta;

    // Layer 1: Outer glow ring (pulsing)
    if (!reduceFx) {
      _outerGlowPaint.color =
          primaryColor.withOpacity(0.15 + pulseProgress * 0.1);
      canvas.drawCircle(center, radius, _outerGlowPaint);
    }

    // Layer 2: Background track
    _trackPaint.color = NeonColors.gridLine.withOpacity(0.5);
    canvas.drawCircle(center, radius, _trackPaint);

    // Layer 3: Progress arc
    _progressPaint.color = secondaryColor.withOpacity(0.8);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * loadProgress,
      false,
      _progressPaint,
    );

    // Layer 4: Spinning indicator arcs
    if (!isComplete) {
      final spinAngle = spinProgress * math.pi * 2;

      // Primary spinner arc
      _spinnerPaint.shader = SweepGradient(
        startAngle: spinAngle,
        endAngle: spinAngle + math.pi,
        colors: [
          primaryColor.withOpacity(0),
          primaryColor,
          primaryColor.withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 8));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 8),
        spinAngle,
        math.pi * 0.7,
        false,
        _spinnerPaint,
      );

      // Secondary spinner (opposite direction)
      if (!reduceFx) {
        _secondarySpinnerPaint.shader = SweepGradient(
          startAngle: -spinAngle * 1.5,
          endAngle: -spinAngle * 1.5 + math.pi,
          colors: [
            secondaryColor.withOpacity(0),
            secondaryColor.withOpacity(0.6),
            secondaryColor.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius - 16));

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - 16),
          -spinAngle * 1.5,
          math.pi * 0.5,
          false,
          _secondarySpinnerPaint,
        );
      }
    }

    // Layer 5: Inner rotating ring
    if (!reduceFx) {
      final innerRadius = radius * 0.6;
      final innerAngle = spinProgress * math.pi * 2 * 0.5;
      _innerRingPaint.color = primaryColor.withOpacity(0.3);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(innerAngle);
      canvas.drawCircle(Offset.zero, innerRadius, _innerRingPaint);

      // Tick marks on inner ring
      _tickPaint.color = primaryColor.withOpacity(0.5);
      for (int i = 0; i < 12; i++) {
        final angle = i * math.pi / 6;
        final startR = innerRadius - 8;
        final endR = innerRadius;
        canvas.drawLine(
          Offset(math.cos(angle) * startR, math.sin(angle) * startR),
          Offset(math.cos(angle) * endR, math.sin(angle) * endR),
          _tickPaint,
        );
      }
      canvas.restore();
    }

    // Layer 6: Center hexagon
    final hexRadius = 25 + pulseProgress * 3;
    _hexGlowPaint.color = primaryColor.withOpacity(0.2);
    _hexPaint.color = primaryColor.withOpacity(0.3);
    _drawHexagon(canvas, center, hexRadius, _hexGlowPaint);
    _drawHexagon(canvas, center, hexRadius, _hexPaint);

    // Layer 7: Inner hexagon (smaller, rotating)
    if (!reduceFx) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-spinProgress * math.pi * 2 * 0.3);
      _hexPaint.color = secondaryColor.withOpacity(0.25);
      _drawHexagon(canvas, Offset.zero, hexRadius * 0.6, _hexPaint);
      canvas.restore();
    }

    // Layer 8: Center dot with glow
    _dotPaint.color = isComplete ? NeonColors.green : primaryColor;
    canvas.drawCircle(center, 6, _dotPaint);
    _dotPaint.maskFilter = null;
    _dotPaint.color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(center, 3, _dotPaint);
    _dotPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Layer 9: Data readout lines (decorative)
    if (!reduceFx) {
      _dataPaint.color = primaryColor.withOpacity(0.3);
      for (int i = 0; i < 4; i++) {
        final angle = (spinProgress + i * 0.25) * math.pi * 2;
        final startX = center.dx + math.cos(angle) * (radius + 5);
        final startY = center.dy + math.sin(angle) * (radius + 5);
        final endX = center.dx + math.cos(angle) * (radius + 15);
        final endY = center.dy + math.sin(angle) * (radius + 15);
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), _dataPaint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    _hexPath.reset();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        _hexPath.moveTo(x, y);
      } else {
        _hexPath.lineTo(x, y);
      }
    }
    _hexPath.close();
    canvas.drawPath(_hexPath, paint);
  }

  @override
  bool shouldRepaint(covariant _TechCirclePainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// LAYER 4: NEON PROGRESS BAR
// ═══════════════════════════════════════════════════════════════════════════
class _NeonProgressBarPainter extends CustomPainter {
  _NeonProgressBarPainter({
    required this.progress,
    required this.pulseProgress,
    required this.isComplete,
    required this.reduceFx,
  });

  final double progress;
  final double pulseProgress;
  final bool isComplete;
  final bool reduceFx;

  // Static paints
  static final Paint _bgPaint = Paint();
  static final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _fillPaint = Paint();
  static final Paint _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _shinePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _segmentPaint = Paint()..strokeWidth = 1;
  static final Paint _edgeGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    final primaryColor = isComplete ? NeonColors.green : NeonColors.cyan;
    final secondaryColor = isComplete ? NeonColors.cyan : NeonColors.magenta;

    // Background
    _bgPaint.color = NeonColors.gridLine.withOpacity(0.4);
    canvas.drawRRect(rrect, _bgPaint);

    // Border with glow
    _borderPaint.color = primaryColor.withOpacity(0.4);
    canvas.drawRRect(rrect, _borderPaint);

    // Progress fill
    if (progress > 0) {
      final fillWidth = size.width * progress;
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, fillWidth, size.height),
        const Radius.circular(6),
      );

      // Gradient fill
      _fillPaint.shader = LinearGradient(
        colors: [primaryColor, secondaryColor],
      ).createShader(rect);
      canvas.drawRRect(fillRect, _fillPaint);

      // Outer glow
      if (!reduceFx) {
        _glowPaint.color = primaryColor.withOpacity(0.3 + pulseProgress * 0.2);
        canvas.drawRRect(fillRect, _glowPaint);
      }

      // Edge glow at progress point
      if (!reduceFx && progress < 1.0) {
        _edgeGlowPaint.color = Colors.white.withOpacity(0.6);
        canvas.drawCircle(
          Offset(fillWidth - 2, size.height / 2),
          size.height * 0.4,
          _edgeGlowPaint,
        );
      }

      // Segment lines (tech look)
      if (!reduceFx) {
        _segmentPaint.color = NeonColors.darkBg.withOpacity(0.3);
        for (double x = 20; x < fillWidth; x += 20) {
          canvas.drawLine(
            Offset(x, 2),
            Offset(x, size.height - 2),
            _segmentPaint,
          );
        }
      }

      // Animated shine highlight
      if (!isComplete && !reduceFx) {
        final shineX = fillWidth * pulseProgress;
        _shinePaint.color = Colors.white.withOpacity(0.5);
        canvas.drawCircle(Offset(shineX, size.height / 2), 4, _shinePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NeonProgressBarPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// LAYER 5: GLITCH TEXT WIDGET
// ═══════════════════════════════════════════════════════════════════════════
class _GlitchTextWidget extends StatelessWidget {
  const _GlitchTextWidget({
    required this.text,
    required this.isGlitching,
    required this.glitchFrame,
    required this.flickerOpacity,
    required this.isComplete,
  });

  final String text;
  final bool isGlitching;
  final int glitchFrame;
  final double flickerOpacity;
  final bool isComplete;

  static const _glitchChars = r'!@#$%^&*()_+-=[]{}|;:<>/?01';

  String _generateGlitchText(String original, _FastRng random) {
    if (!isGlitching) return original;
    final chars = original.split('');
    final glitchCount = (chars.length * 0.3).round();
    for (int i = 0; i < glitchCount; i++) {
      final idx = random.nextInt(chars.length);
      chars[idx] = _glitchChars[random.nextInt(_glitchChars.length)];
    }
    return chars.join('');
  }

  @override
  Widget build(BuildContext context) {
    final random = _FastRng(glitchFrame);
    final displayText = _generateGlitchText(text, random);
    final primaryColor = isComplete ? NeonColors.green : NeonColors.cyan;

    return Stack(
      children: [
        // Chromatic aberration layers (when glitching)
        if (isGlitching) ...[
          Transform.translate(
            offset: const Offset(-2, 0),
            child: Text(
              displayText,
              style: NeonTextStyles.subtitle.copyWith(
                color: const Color(0xFFFF0000).withOpacity(0.5),
                letterSpacing: 6,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(2, 0),
            child: Text(
              displayText,
              style: NeonTextStyles.subtitle.copyWith(
                color: const Color(0xFF00FFFF).withOpacity(0.5),
                letterSpacing: 6,
              ),
            ),
          ),
        ],
        // Main text
        Text(
          displayText,
          style: NeonTextStyles.subtitle.copyWith(
            color: primaryColor,
            letterSpacing: 6,
            shadows: [
              Shadow(
                color: primaryColor.withOpacity(flickerOpacity),
                blurRadius: 15,
              ),
              Shadow(
                color: primaryColor.withOpacity(flickerOpacity * 0.5),
                blurRadius: 30,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LAYER 6: DATA STREAM PARTICLES
// ═══════════════════════════════════════════════════════════════════════════
class _DataStreamPainter extends CustomPainter {
  _DataStreamPainter({
    required this.particles,
    required this.animation,
  });

  final List<_DataParticle> particles;
  final double animation;

  static final Paint _particlePaint = Paint();
  static final Paint _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static const int _charPainterCacheLimit = 64;
  static final Map<int, TextPainter> _charPainterCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    var cacheExceeded = false;
    for (final p in particles) {
      if (p.opacity <= 0.02) continue;
      final x = p.x * size.width;
      final y = p.y * size.height;

      // Particle glow
      final glowAlpha = p.opacity * 0.3;
      if (glowAlpha > 0.01) {
        _glowPaint.color = p.color.withOpacity(glowAlpha);
        canvas.drawCircle(Offset(x, y), p.size * 2, _glowPaint);
      }

      // Particle core
      _particlePaint.color = p.color.withOpacity(p.opacity);
      canvas.drawCircle(Offset(x, y), p.size, _particlePaint);

      // Binary character above particle
      final textAlpha = p.opacity * 0.7;
      if (textAlpha >= 0.05) {
        final alphaKey = (textAlpha * 32).round().clamp(0, 32);
        final rgb = p.color.value & 0x00FFFFFF;
        final charCode = p.char.codeUnitAt(0) & 0xFF;
        final cacheKey = (alphaKey << 32) | (charCode << 24) | rgb;
        final painter = _charPainterCache.putIfAbsent(cacheKey, () {
          final tp = TextPainter(textDirection: TextDirection.ltr);
          tp.text = TextSpan(
            text: p.char,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: p.color.withOpacity(alphaKey / 32),
            ),
          );
          tp.layout();
          return tp;
        });
        painter.paint(canvas, Offset(x - 3, y - 14));
        if (_charPainterCache.length > _charPainterCacheLimit) {
          cacheExceeded = true;
        }
      }
    }
    if (cacheExceeded) {
      for (final tp in _charPainterCache.values) {
        tp.dispose();
      }
      _charPainterCache.clear();
    }
  }

  @override
  bool shouldRepaint(covariant _DataStreamPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// LAYER 7: CORNER DECORATION WITH STATUS INDICATOR
// ═══════════════════════════════════════════════════════════════════════════
class _CornerDecoration extends StatelessWidget {
  const _CornerDecoration({
    required this.color,
    required this.pulseProgress,
    required this.statusText,
    required this.isActive,
  });

  final Color color;
  final double pulseProgress;
  final String statusText;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 60,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          pulseProgress: pulseProgress,
          isActive: isActive,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 28),
          child: Text(
            statusText,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: isActive
                  ? color.withOpacity(0.6 + pulseProgress * 0.4)
                  : NeonColors.gridLine.withOpacity(0.5),
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({
    required this.color,
    required this.pulseProgress,
    required this.isActive,
  });

  final Color color;
  final double pulseProgress;
  final bool isActive;

  // Static paints
  static final Paint _linePaint = Paint()
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  static final Paint _glowPaint = Paint()
    ..strokeWidth = 4
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _dotPaint = Paint();
  static final Paint _dotGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  @override
  void paint(Canvas canvas, Size size) {
    final activeColor = isActive ? color : NeonColors.gridLine;
    final opacity = isActive ? 0.6 + pulseProgress * 0.4 : 0.3;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.8, 0);

    // Glow layer
    _glowPaint.color = activeColor.withOpacity(opacity * 0.5);
    canvas.drawPath(path, _glowPaint);

    // Main line
    _linePaint.color = activeColor.withOpacity(opacity);
    canvas.drawPath(path, _linePaint);

    // Status indicator dot
    if (isActive) {
      final dotOpacity = 0.5 + pulseProgress * 0.5;
      _dotGlowPaint.color = color.withOpacity(dotOpacity * 0.5);
      canvas.drawCircle(const Offset(4, 4), 5, _dotGlowPaint);

      _dotPaint.color = color.withOpacity(dotOpacity);
      canvas.drawCircle(const Offset(4, 4), 3, _dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.pulseProgress != pulseProgress ||
      oldDelegate.isActive != isActive;
}
