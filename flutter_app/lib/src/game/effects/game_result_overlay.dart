import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../ui/theme/neon_theme.dart';

/// Game result type
enum GameResultType {
  victory,
  defeat,
}

/// Holographic victory/defeat overlay with particle effects
class GameResultOverlay extends PositionComponent {
  GameResultOverlay({
    required this.gameSize,
    this.onComplete,
  }) : _random = math.Random();

  final Vector2 gameSize;
  final VoidCallback? onComplete;
  final math.Random _random;

  // State
  bool _isActive = false;
  GameResultType _resultType = GameResultType.victory;
  double _animationTime = 0;
  double _totalDuration = 2.0;
  bool reduceFx = false;
  bool allowBlur = true;

  // Stats for typewriter effect
  int _score = 0;
  int _wavesCompleted = 0;
  int _enemiesKilled = 0;
  int _towersBuilt = 0;

  // Typewriter state
  double _typewriterProgress = 0;
  int _currentStatLine = 0;

  // Particle systems
  List<_ResultParticle>? _particles;
  List<_EnergyWave>? _energyWaves;
  List<_GlitchLine>? _glitchLines;

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════

  // Layer 1: Background
  static final Paint _bgPaint = Paint();
  static final Paint _bgGradientPaint = Paint();

  // Layer 2: Holographic text
  static final Paint _textGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  static final Paint _textOuterGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
  static final Paint _textCorePaint = Paint();
  static final Paint _textScanlinePaint = Paint();
  static final Paint _textHologramPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  // Layer 3: Particles
  static final Paint _particlePaint = Paint();
  static final Paint _particleGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  // Layer 4: Border/frame
  static final Paint _borderOuterPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _borderMidPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _borderCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _borderNodePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _borderPulsePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

  // Layer 5: Stats
  static final Paint _statsBgPaint = Paint();
  static final Paint _statsBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _statsLinePaint = Paint()
    ..strokeWidth = 1;

  // Layer 6: Energy waves
  static final Paint _wavePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  // Layer 7: Glitch/scanlines
  static final Paint _scanlinePaint = Paint();
  static final Paint _glitchBlockPaint = Paint();
  static final Paint _glitchLinePaint = Paint()
    ..strokeWidth = 2;
  static final Paint _noisePaint = Paint();

  // Cached shaders
  Shader? _bgShader;
  Size? _lastBgSize;
  GameResultType? _lastBgType;

  // Cached TextPainters
  TextPainter? _titlePainter;
  TextPainter? _subtitlePainter;
  final List<TextPainter?> _statPainters = [null, null, null, null];
  String? _lastTitle;
  GameResultType? _lastPainterType;

  /// Whether the overlay is currently active
  bool get isActive => _isActive;

  /// Animation progress (0.0 to 1.0)
  double get progress => (_animationTime / _totalDuration).clamp(0.0, 1.0);

  /// Set quality flags
  void setQuality({required bool reduceFx, required bool allowBlur}) {
    this.reduceFx = reduceFx;
    this.allowBlur = allowBlur;
  }

  /// Trigger victory screen
  void triggerVictory({
    int score = 0,
    int wavesCompleted = 0,
    int enemiesKilled = 0,
    int towersBuilt = 0,
  }) {
    _resultType = GameResultType.victory;
    _score = score;
    _wavesCompleted = wavesCompleted;
    _enemiesKilled = enemiesKilled;
    _towersBuilt = towersBuilt;
    _startAnimation();
  }

  /// Trigger defeat screen
  void triggerDefeat({
    int score = 0,
    int wavesCompleted = 0,
    int enemiesKilled = 0,
    int towersBuilt = 0,
  }) {
    _resultType = GameResultType.defeat;
    _score = score;
    _wavesCompleted = wavesCompleted;
    _enemiesKilled = enemiesKilled;
    _towersBuilt = towersBuilt;
    _startAnimation();
  }

  void _startAnimation() {
    _isActive = true;
    _animationTime = 0;
    _typewriterProgress = 0;
    _currentStatLine = 0;
    _initializeParticles();
    _initializeEnergyWaves();
    _initializeGlitchLines();
    _invalidatePainterCache();
  }

  void _initializeParticles() {
    final isVictory = _resultType == GameResultType.victory;
    final particleCount = reduceFx ? 30 : 80;

    _particles = List.generate(particleCount, (i) {
      // Spawn from text area (center of screen)
      final centerX = gameSize.x / 2;
      final centerY = gameSize.y * 0.35;

      if (isVictory) {
        // Confetti: spread outward and upward
        final angle = _random.nextDouble() * math.pi * 2;
        final speed = 100 + _random.nextDouble() * 200;
        return _ResultParticle(
          x: centerX + (_random.nextDouble() - 0.5) * 100,
          y: centerY + (_random.nextDouble() - 0.5) * 40,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 80, // Bias upward
          life: 1.5 + _random.nextDouble() * 1.0,
          maxLife: 1.5 + _random.nextDouble() * 1.0,
          size: 3 + _random.nextDouble() * 5,
          rotation: _random.nextDouble() * math.pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 8,
          color: _getConfettiColor(),
          type: _ParticleType.confetti,
          delay: _random.nextDouble() * 0.5,
        );
      } else {
        // Debris: fall downward with some spread
        final angle = _random.nextDouble() * math.pi - math.pi / 2; // Mostly downward
        final speed = 50 + _random.nextDouble() * 150;
        return _ResultParticle(
          x: centerX + (_random.nextDouble() - 0.5) * 200,
          y: centerY + (_random.nextDouble() - 0.5) * 60,
          vx: math.cos(angle) * speed * 0.5,
          vy: math.sin(angle).abs() * speed + 30, // Bias downward
          life: 1.2 + _random.nextDouble() * 0.8,
          maxLife: 1.2 + _random.nextDouble() * 0.8,
          size: 2 + _random.nextDouble() * 4,
          rotation: _random.nextDouble() * math.pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 5,
          color: _getDebrisColor(),
          type: _ParticleType.debris,
          delay: _random.nextDouble() * 0.3,
        );
      }
    });
  }

  Color _getConfettiColor() {
    final colors = [
      NeonColors.cyan,
      NeonColors.green,
      NeonColors.yellow,
      NeonColors.magenta,
      const Color(0xFF00AAFF),
      Colors.white,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  Color _getDebrisColor() {
    final colors = [
      NeonColors.red,
      NeonColors.orange,
      const Color(0xFFFF3333),
      const Color(0xFF880000),
      const Color(0xFFFFAA00),
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _initializeEnergyWaves() {
    _energyWaves = List.generate(5, (i) {
      return _EnergyWave(
        radius: 0,
        maxRadius: math.max(gameSize.x, gameSize.y) * 0.8,
        speed: 150 + i * 30,
        delay: i * 0.3,
        alpha: 0.6 - i * 0.1,
      );
    });
  }

  void _initializeGlitchLines() {
    _glitchLines = List.generate(reduceFx ? 5 : 15, (i) {
      return _GlitchLine(
        y: _random.nextDouble() * gameSize.y,
        width: 20 + _random.nextDouble() * 100,
        height: 2 + _random.nextDouble() * 6,
        offset: (_random.nextDouble() - 0.5) * 20,
        duration: 0.05 + _random.nextDouble() * 0.1,
        timer: _random.nextDouble() * 2,
        interval: 0.5 + _random.nextDouble() * 1.5,
      );
    });
  }

  void _invalidatePainterCache() {
    _titlePainter?.dispose();
    _titlePainter = null;
    _subtitlePainter?.dispose();
    _subtitlePainter = null;
    for (int i = 0; i < _statPainters.length; i++) {
      _statPainters[i]?.dispose();
      _statPainters[i] = null;
    }
    _lastTitle = null;
    _lastPainterType = null;
  }

  void _ensurePaintersValid() {
    final isVictory = _resultType == GameResultType.victory;
    final titleText = isVictory ? 'VICTORY' : 'DEFEAT';
    final primaryColor = isVictory ? NeonColors.cyan : NeonColors.red;

    if (_lastTitle == titleText && _lastPainterType == _resultType) return;

    _invalidatePainterCache();

    // Title painter
    _titlePainter = TextPainter(
      text: TextSpan(
        text: titleText,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 72,
          fontWeight: FontWeight.bold,
          color: primaryColor,
          letterSpacing: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Subtitle
    final subtitleText = isVictory ? 'MISSION COMPLETE' : 'BASE DESTROYED';
    _subtitlePainter = TextPainter(
      text: TextSpan(
        text: subtitleText,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: primaryColor.withOpacity(0.8),
          letterSpacing: 4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Stat lines
    final statLines = [
      'SCORE: $_score',
      'WAVES: $_wavesCompleted',
      'KILLS: $_enemiesKilled',
      'TOWERS: $_towersBuilt',
    ];

    for (int i = 0; i < statLines.length; i++) {
      _statPainters[i] = TextPainter(
        text: TextSpan(
          text: statLines[i],
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    _lastTitle = titleText;
    _lastPainterType = _resultType;
  }

  void _ensureBgShaderValid() {
    final currentSize = Size(gameSize.x, gameSize.y);
    if (_bgShader != null && _lastBgSize == currentSize && _lastBgType == _resultType) {
      return;
    }

    final isVictory = _resultType == GameResultType.victory;
    final primaryColor = isVictory ? const Color(0xFF001830) : const Color(0xFF300010);
    final secondaryColor = isVictory ? const Color(0xFF002040) : const Color(0xFF400015);

    _bgShader = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        secondaryColor,
        primaryColor,
        const Color(0xFF000008),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, gameSize.x, gameSize.y));

    _lastBgSize = currentSize;
    _lastBgType = _resultType;
  }

  /// Hide the overlay
  void hide() {
    _isActive = false;
    _particles = null;
    _energyWaves = null;
    _glitchLines = null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isActive) return;

    _animationTime += dt;

    // Update typewriter effect (starts after 0.8s)
    if (_animationTime > 0.8) {
      _typewriterProgress += dt * 15; // Characters per second
      _currentStatLine = (_typewriterProgress / 20).floor().clamp(0, 3);
    }

    // Update particles
    final particles = _particles;
    if (particles != null) {
      for (final p in particles) {
        if (_animationTime < p.delay) continue;

        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.rotation += p.rotationSpeed * dt;
        p.life -= dt;

        // Apply gravity for confetti/debris
        if (p.type == _ParticleType.confetti) {
          p.vy += 150 * dt; // Light gravity
          p.vx *= 0.99; // Air resistance
        } else {
          p.vy += 200 * dt; // Heavier gravity for debris
        }
      }
    }

    // Update energy waves
    final waves = _energyWaves;
    if (waves != null) {
      for (final w in waves) {
        if (_animationTime < w.delay) continue;
        w.radius += w.speed * dt;
        if (w.radius > w.maxRadius) {
          w.radius = 0;
        }
      }
    }

    // Update glitch lines
    final glitches = _glitchLines;
    if (glitches != null && !reduceFx) {
      for (final g in glitches) {
        g.timer += dt;
        if (g.timer >= g.interval) {
          g.timer = 0;
          g.y = _random.nextDouble() * gameSize.y;
          g.offset = (_random.nextDouble() - 0.5) * 30;
          g.width = 20 + _random.nextDouble() * 150;
        }
      }
    }

    // Call completion callback after animation
    if (_animationTime >= _totalDuration + 1.0) {
      onComplete?.call();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!_isActive) return;

    final screenRect = Rect.fromLTWH(0, 0, gameSize.x, gameSize.y);
    final animProgress = progress;

    // Ensure cached resources are valid
    _ensureBgShaderValid();
    _ensurePaintersValid();

    // Dramatic entrance animation
    final entranceProgress = _easeOutQuart((animProgress * 2).clamp(0.0, 1.0));

    // Layer 1: Background darken/tint
    _renderBackground(canvas, screenRect, entranceProgress);

    // Layer 6: Pulsing energy waves (behind text)
    if (!reduceFx) {
      _renderEnergyWaves(canvas, entranceProgress);
    }

    // Layer 4: Animated frame/border with glow
    _renderAnimatedBorder(canvas, screenRect, entranceProgress);

    // Layer 2: Large holographic text
    _renderHolographicText(canvas, entranceProgress);

    // Layer 3: Particle burst
    _renderParticles(canvas, entranceProgress);

    // Layer 5: Score/stats with typewriter effect
    if (animProgress > 0.4) {
      _renderStats(canvas, entranceProgress);
    }

    // Layer 7: Glitch/scanline overlay
    if (!reduceFx) {
      _renderGlitchOverlay(canvas, screenRect, entranceProgress);
    }
  }

  void _renderBackground(Canvas canvas, Rect screenRect, double progress) {
    // Fade in background
    final alpha = (progress * 0.85).clamp(0.0, 0.85);

    // Dark overlay
    _bgPaint.color = Colors.black.withOpacity(alpha);
    canvas.drawRect(screenRect, _bgPaint);

    // Colored gradient overlay
    if (_bgShader != null && progress > 0.1) {
      _bgGradientPaint.shader = _bgShader;
      _bgGradientPaint.color = Colors.white.withOpacity((progress - 0.1) * 0.7);
      canvas.drawRect(screenRect, _bgGradientPaint);
    }
  }

  void _renderHolographicText(Canvas canvas, double progress) {
    if (_titlePainter == null || _subtitlePainter == null) return;

    final isVictory = _resultType == GameResultType.victory;
    final primaryColor = isVictory ? NeonColors.cyan : NeonColors.red;
    final centerX = gameSize.x / 2;
    final titleY = gameSize.y * 0.30;
    final subtitleY = titleY + 80;

    // Scale and fade animation
    final textScale = 0.5 + progress * 0.5;
    final textAlpha = progress;

    // Holographic flicker
    final flicker = 0.9 + math.sin(_animationTime * 20) * 0.1;
    final hologramOffset = math.sin(_animationTime * 15) * 2;

    canvas.save();
    canvas.translate(centerX, titleY);
    canvas.scale(textScale, textScale);

    // ═══════════════════════════════════════════════════════════════════════
    // TITLE TEXT LAYERS
    // ═══════════════════════════════════════════════════════════════════════

    // Outer glow
    if (allowBlur) {
      _textOuterGlowPaint.color = primaryColor.withOpacity(textAlpha * 0.3 * flicker);
      canvas.saveLayer(null, _textOuterGlowPaint);
      _titlePainter!.paint(canvas, Offset(-_titlePainter!.width / 2, 0));
      canvas.restore();
    }

    // Mid glow
    if (allowBlur) {
      _textGlowPaint.color = primaryColor.withOpacity(textAlpha * 0.5 * flicker);
      canvas.saveLayer(null, _textGlowPaint);
      _titlePainter!.paint(canvas, Offset(-_titlePainter!.width / 2, 0));
      canvas.restore();
    }

    // Hologram scanlines effect
    if (!reduceFx) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(
        -_titlePainter!.width / 2 - 10,
        -10,
        _titlePainter!.width + 20,
        _titlePainter!.height + 20,
      ));

      for (double y = (_animationTime * 100) % 8; y < _titlePainter!.height + 20; y += 8) {
        _textScanlinePaint.color = primaryColor.withOpacity(0.1 * textAlpha);
        canvas.drawRect(
          Rect.fromLTWH(-_titlePainter!.width / 2 - 10, y - 10, _titlePainter!.width + 20, 2),
          _textScanlinePaint,
        );
      }
      canvas.restore();
    }

    // Chromatic aberration (hologram split)
    if (!reduceFx && allowBlur) {
      // Red channel offset
      _textHologramPaint.color = Colors.red.withOpacity(textAlpha * 0.3);
      canvas.saveLayer(null, _textHologramPaint);
      _titlePainter!.paint(canvas, Offset(-_titlePainter!.width / 2 - 3 + hologramOffset, 0));
      canvas.restore();

      // Cyan channel offset
      _textHologramPaint.color = Colors.cyan.withOpacity(textAlpha * 0.3);
      canvas.saveLayer(null, _textHologramPaint);
      _titlePainter!.paint(canvas, Offset(-_titlePainter!.width / 2 + 3 - hologramOffset, 0));
      canvas.restore();
    }

    // Core text
    _textCorePaint.color = Colors.white.withOpacity(textAlpha * flicker);
    canvas.saveLayer(null, _textCorePaint);
    _titlePainter!.paint(canvas, Offset(-_titlePainter!.width / 2, 0));
    canvas.restore();

    canvas.restore();

    // ═══════════════════════════════════════════════════════════════════════
    // SUBTITLE
    // ═══════════════════════════════════════════════════════════════════════
    if (progress > 0.3) {
      final subtitleAlpha = ((progress - 0.3) / 0.3).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(centerX, subtitleY);

      // Glow
      if (allowBlur) {
        _textGlowPaint.color = primaryColor.withOpacity(subtitleAlpha * 0.4);
        canvas.saveLayer(null, _textGlowPaint);
        _subtitlePainter!.paint(canvas, Offset(-_subtitlePainter!.width / 2, 0));
        canvas.restore();
      }

      // Core
      _textCorePaint.color = Colors.white.withOpacity(subtitleAlpha * 0.9);
      canvas.saveLayer(null, _textCorePaint);
      _subtitlePainter!.paint(canvas, Offset(-_subtitlePainter!.width / 2, 0));
      canvas.restore();

      canvas.restore();
    }
  }

  void _renderParticles(Canvas canvas, double progress) {
    final particles = _particles;
    if (particles == null || progress < 0.2) return;

    for (final p in particles) {
      if (p.life <= 0 || _animationTime < p.delay) continue;

      final lifeRatio = (p.life / p.maxLife).clamp(0.0, 1.0);
      final alpha = lifeRatio * progress;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (p.type == _ParticleType.confetti) {
        // Confetti: colorful rectangles
        if (allowBlur && !reduceFx) {
          _particleGlowPaint.color = p.color.withOpacity(alpha * 0.5);
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.size * 1.5, height: p.size * 0.5),
            _particleGlowPaint,
          );
        }

        _particlePaint.color = p.color.withOpacity(alpha);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.4),
          _particlePaint,
        );
      } else {
        // Debris: angular shards
        if (allowBlur && !reduceFx) {
          _particleGlowPaint.color = p.color.withOpacity(alpha * 0.4);
          canvas.drawCircle(Offset.zero, p.size * 0.8, _particleGlowPaint);
        }

        final path = Path()
          ..moveTo(0, -p.size * 0.6)
          ..lineTo(p.size * 0.4, p.size * 0.3)
          ..lineTo(-p.size * 0.5, p.size * 0.4)
          ..close();

        _particlePaint.color = p.color.withOpacity(alpha);
        canvas.drawPath(path, _particlePaint);
      }

      canvas.restore();
    }
  }

  void _renderAnimatedBorder(Canvas canvas, Rect screenRect, double progress) {
    if (progress < 0.1) return;

    final isVictory = _resultType == GameResultType.victory;
    final primaryColor = isVictory ? NeonColors.cyan : NeonColors.red;
    final secondaryColor = isVictory ? NeonColors.green : NeonColors.orange;

    final w = screenRect.width;
    final h = screenRect.height;
    final borderProgress = ((progress - 0.1) / 0.4).clamp(0.0, 1.0);
    final pulse = 0.7 + math.sin(_animationTime * 3) * 0.3;

    // Border inset
    final inset = 30.0;
    final borderRect = Rect.fromLTWH(inset, inset, w - inset * 2, h - inset * 2);

    // ═══════════════════════════════════════════════════════════════════════
    // OUTER GLOW
    // ═══════════════════════════════════════════════════════════════════════
    if (allowBlur) {
      _borderOuterPaint.color = primaryColor.withOpacity(borderProgress * 0.3 * pulse);
      canvas.drawRect(
        Rect.fromLTWH(inset - 8, inset - 8, w - inset * 2 + 16, h - inset * 2 + 16),
        _borderOuterPaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ANIMATED BORDER LINES (draw progressively)
    // ═══════════════════════════════════════════════════════════════════════
    _borderCorePaint.color = primaryColor.withOpacity(borderProgress * 0.8);

    final totalPerimeter = 2 * (borderRect.width + borderRect.height);
    final drawnLength = totalPerimeter * borderProgress;

    final borderPath = Path();
    var remaining = drawnLength;

    // Top edge
    if (remaining > 0) {
      final segLen = math.min(remaining, borderRect.width);
      borderPath.moveTo(borderRect.left, borderRect.top);
      borderPath.lineTo(borderRect.left + segLen, borderRect.top);
      remaining -= segLen;
    }

    // Right edge
    if (remaining > 0) {
      final segLen = math.min(remaining, borderRect.height);
      borderPath.lineTo(borderRect.right, borderRect.top + segLen);
      remaining -= segLen;
    }

    // Bottom edge
    if (remaining > 0) {
      final segLen = math.min(remaining, borderRect.width);
      borderPath.lineTo(borderRect.right - segLen, borderRect.bottom);
      remaining -= segLen;
    }

    // Left edge
    if (remaining > 0) {
      final segLen = math.min(remaining, borderRect.height);
      borderPath.lineTo(borderRect.left, borderRect.bottom - segLen);
    }

    canvas.drawPath(borderPath, _borderCorePaint);

    // ═══════════════════════════════════════════════════════════════════════
    // CORNER NODES
    // ═══════════════════════════════════════════════════════════════════════
    if (borderProgress > 0.5) {
      final nodeAlpha = ((borderProgress - 0.5) * 2).clamp(0.0, 1.0);
      final nodeSize = 8.0;

      void drawCornerNode(double cx, double cy) {
        if (allowBlur) {
          _borderNodePaint.color = primaryColor.withOpacity(nodeAlpha * 0.6 * pulse);
          canvas.drawCircle(Offset(cx, cy), nodeSize * 1.5, _borderNodePaint);
        }

        _particlePaint.color = primaryColor.withOpacity(nodeAlpha * pulse);
        canvas.drawCircle(Offset(cx, cy), nodeSize, _particlePaint);

        _particlePaint.color = Colors.white.withOpacity(nodeAlpha * 0.8);
        canvas.drawCircle(Offset(cx, cy), nodeSize * 0.4, _particlePaint);
      }

      drawCornerNode(borderRect.left, borderRect.top);
      drawCornerNode(borderRect.right, borderRect.top);
      drawCornerNode(borderRect.left, borderRect.bottom);
      drawCornerNode(borderRect.right, borderRect.bottom);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // TRAVELING ENERGY PULSE
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx && borderProgress > 0.8) {
      final pulsePos = (_animationTime * 200) % totalPerimeter;
      final pulseLen = 60.0;

      Offset getPosOnBorder(double dist) {
        var d = dist % totalPerimeter;
        if (d < borderRect.width) {
          return Offset(borderRect.left + d, borderRect.top);
        }
        d -= borderRect.width;
        if (d < borderRect.height) {
          return Offset(borderRect.right, borderRect.top + d);
        }
        d -= borderRect.height;
        if (d < borderRect.width) {
          return Offset(borderRect.right - d, borderRect.bottom);
        }
        d -= borderRect.width;
        return Offset(borderRect.left, borderRect.bottom - d);
      }

      for (double i = 0; i < pulseLen; i += 4) {
        final pos = getPosOnBorder(pulsePos + i);
        final intensity = 1.0 - (i / pulseLen);

        if (allowBlur) {
          _borderPulsePaint.color = secondaryColor.withOpacity(intensity * 0.6);
          canvas.drawCircle(pos, 6, _borderPulsePaint);
        }

        _particlePaint.color = Colors.white.withOpacity(intensity * 0.8);
        canvas.drawCircle(pos, 3, _particlePaint);
      }
    }
  }

  void _renderStats(Canvas canvas, double progress) {
    final statsAlpha = ((progress - 0.4) / 0.3).clamp(0.0, 1.0);
    if (statsAlpha <= 0) return;

    final isVictory = _resultType == GameResultType.victory;
    final primaryColor = isVictory ? NeonColors.cyan : NeonColors.red;

    final centerX = gameSize.x / 2;
    final startY = gameSize.y * 0.55;
    final boxWidth = 280.0;
    final boxHeight = 140.0;

    // Stats background box
    final boxRect = Rect.fromCenter(
      center: Offset(centerX, startY + boxHeight / 2),
      width: boxWidth,
      height: boxHeight,
    );

    // Background
    _statsBgPaint.color = const Color(0xFF0a0a18).withOpacity(statsAlpha * 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(4)),
      _statsBgPaint,
    );

    // Border
    _statsBorderPaint.color = primaryColor.withOpacity(statsAlpha * 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(4)),
      _statsBorderPaint,
    );

    // Corner accents
    final accentLen = 15.0;
    _statsLinePaint.color = primaryColor.withOpacity(statsAlpha * 0.8);

    // Top-left
    canvas.drawLine(
      Offset(boxRect.left, boxRect.top),
      Offset(boxRect.left + accentLen, boxRect.top),
      _statsLinePaint,
    );
    canvas.drawLine(
      Offset(boxRect.left, boxRect.top),
      Offset(boxRect.left, boxRect.top + accentLen),
      _statsLinePaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(boxRect.right, boxRect.top),
      Offset(boxRect.right - accentLen, boxRect.top),
      _statsLinePaint,
    );
    canvas.drawLine(
      Offset(boxRect.right, boxRect.top),
      Offset(boxRect.right, boxRect.top + accentLen),
      _statsLinePaint,
    );

    // Bottom corners
    canvas.drawLine(
      Offset(boxRect.left, boxRect.bottom),
      Offset(boxRect.left + accentLen, boxRect.bottom),
      _statsLinePaint,
    );
    canvas.drawLine(
      Offset(boxRect.left, boxRect.bottom),
      Offset(boxRect.left, boxRect.bottom - accentLen),
      _statsLinePaint,
    );
    canvas.drawLine(
      Offset(boxRect.right, boxRect.bottom),
      Offset(boxRect.right - accentLen, boxRect.bottom),
      _statsLinePaint,
    );
    canvas.drawLine(
      Offset(boxRect.right, boxRect.bottom),
      Offset(boxRect.right, boxRect.bottom - accentLen),
      _statsLinePaint,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // TYPEWRITER TEXT
    // ═══════════════════════════════════════════════════════════════════════
    final lineHeight = 28.0;
    final textStartY = startY + 15;

    for (int i = 0; i < _statPainters.length; i++) {
      final painter = _statPainters[i];
      if (painter == null) continue;

      // Calculate how much of this line to show
      final lineStart = i * 20.0; // Characters before this line
      final lineChars = 20; // Approx chars per line
      final visibleChars = (_typewriterProgress - lineStart).clamp(0.0, lineChars.toDouble());

      if (visibleChars <= 0) continue;

      final lineAlpha = statsAlpha * (visibleChars / lineChars).clamp(0.0, 1.0);

      canvas.save();

      // Clip to show only typed characters
      final charWidth = painter.width / painter.text!.toPlainText().length;
      final visibleWidth = charWidth * visibleChars;

      canvas.clipRect(Rect.fromLTWH(
        centerX - boxWidth / 2 + 20,
        textStartY + i * lineHeight - 5,
        visibleWidth,
        lineHeight,
      ));

      _textCorePaint.color = Colors.white.withOpacity(lineAlpha);
      canvas.saveLayer(null, _textCorePaint);
      painter.paint(canvas, Offset(centerX - boxWidth / 2 + 20, textStartY + i * lineHeight));
      canvas.restore();

      canvas.restore();

      // Cursor blink at end of current line
      if (i == _currentStatLine && visibleChars < lineChars) {
        final cursorBlink = math.sin(_animationTime * 10) > 0;
        if (cursorBlink) {
          _statsLinePaint.color = primaryColor.withOpacity(statsAlpha);
          canvas.drawRect(
            Rect.fromLTWH(
              centerX - boxWidth / 2 + 20 + visibleWidth,
              textStartY + i * lineHeight,
              8,
              16,
            ),
            _statsLinePaint,
          );
        }
      }
    }
  }

  void _renderEnergyWaves(Canvas canvas, double progress) {
    final waves = _energyWaves;
    if (waves == null || progress < 0.3) return;

    final isVictory = _resultType == GameResultType.victory;
    final primaryColor = isVictory ? NeonColors.cyan : NeonColors.red;
    final centerX = gameSize.x / 2;
    final centerY = gameSize.y * 0.35;

    for (final w in waves) {
      if (_animationTime < w.delay || w.radius <= 0) continue;

      final waveProgress = (w.radius / w.maxRadius).clamp(0.0, 1.0);
      final alpha = w.alpha * (1 - waveProgress) * progress;

      _wavePaint.color = primaryColor.withOpacity(alpha);
      canvas.drawCircle(Offset(centerX, centerY), w.radius, _wavePaint);
    }
  }

  void _renderGlitchOverlay(Canvas canvas, Rect screenRect, double progress) {
    if (progress < 0.2) return;

    final glitchAlpha = progress * 0.15;

    // ═══════════════════════════════════════════════════════════════════════
    // SCANLINES
    // ═══════════════════════════════════════════════════════════════════════
    _scanlinePaint.color = Colors.black.withOpacity(glitchAlpha * 0.3);
    for (double y = 0; y < screenRect.height; y += 4) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, screenRect.width, 1),
        _scanlinePaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GLITCH LINES
    // ═══════════════════════════════════════════════════════════════════════
    final glitches = _glitchLines;
    if (glitches != null) {
      final isVictory = _resultType == GameResultType.victory;
      final glitchColor = isVictory ? NeonColors.cyan : NeonColors.red;

      for (final g in glitches) {
        if (g.timer > g.duration) continue;

        final glitchProgress = g.timer / g.duration;
        final alpha = (1 - glitchProgress) * progress * 0.4;

        // Horizontal displacement block
        _glitchBlockPaint.color = Colors.black.withOpacity(alpha * 0.5);
        canvas.drawRect(
          Rect.fromLTWH(0, g.y, screenRect.width, g.height),
          _glitchBlockPaint,
        );

        // Color fringe
        _glitchLinePaint.color = glitchColor.withOpacity(alpha);
        canvas.drawLine(
          Offset(g.offset, g.y),
          Offset(g.offset + g.width, g.y),
          _glitchLinePaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // NOISE FLICKER
    // ═══════════════════════════════════════════════════════════════════════
    if (_random.nextDouble() < 0.05) {
      _noisePaint.color = Colors.white.withOpacity(_random.nextDouble() * 0.03);
      canvas.drawRect(screenRect, _noisePaint);
    }
  }

  /// Smooth ease-out quart for dramatic entrance
  static double _easeOutQuart(double t) {
    return 1 - math.pow(1 - t, 4).toDouble();
  }

  @override
  void onRemove() {
    _invalidatePainterCache();
    super.onRemove();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════════

enum _ParticleType {
  confetti,
  debris,
}

class _ResultParticle {
  _ResultParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.type,
    required this.delay,
  });

  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double maxLife;
  final double size;
  double rotation;
  final double rotationSpeed;
  final Color color;
  final _ParticleType type;
  final double delay;
}

class _EnergyWave {
  _EnergyWave({
    required this.radius,
    required this.maxRadius,
    required this.speed,
    required this.delay,
    required this.alpha,
  });

  double radius;
  final double maxRadius;
  final double speed;
  final double delay;
  final double alpha;
}

class _GlitchLine {
  _GlitchLine({
    required this.y,
    required this.width,
    required this.height,
    required this.offset,
    required this.duration,
    required this.timer,
    required this.interval,
  });

  double y;
  double width;
  double height;
  double offset;
  final double duration;
  double timer;
  final double interval;
}
