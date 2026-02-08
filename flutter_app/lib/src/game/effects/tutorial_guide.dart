import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bored_games_game.dart';
import '../../ui/theme/neon_theme.dart';

class TutorialGuide extends PositionComponent with HasGameRef<BoredGamesGame> {
  TutorialGuide() {
    anchor = Anchor.topCenter;
  }

  Picture? _messagePicture;
  Picture? _iconPicture;
  double _messageWidth = 0;
  double _messageHeight = 0;
  double _iconWidth = 0;
  double _iconHeight = 0;
  int _cachedStep = -1;
  bool _cachedTouchLayout = false;
  int _cachedAccentColorValue = 0;
  final Path _framePath = Path();
  double _frameX = 0;
  double _frameY = 0;
  double _frameWidth = 0;
  double _frameHeight = 0;

  // Icons for each step (using unicode symbols)
  static const List<String> _stepIcons = ['◆', '▶', '⚡', '✦', '⊕', '◈'];

  static const List<String> _touchMessages = [
    'Toca una torre para armarla',
    'Arrastra a una casilla verde',
    'Las olas inician automáticamente',
    'Activa PULSE o MINE en el campo',
    'Toca 5x una torre para Focus Mode',
    'Usa SELL para recuperar oro',
  ];

  static const List<String> _desktopMessages = [
    'Selecciona una torre para armarla',
    'Arrastra a una casilla verde',
    'Las olas inician automáticamente',
    'Presiona SPACE/M para habilidades',
    'Clic 5x en torre para Focus Mode',
    'Usa SELL para recuperar oro',
  ];

  static const List<double> _autoAdvanceDelays = [
    0,
    0,
    0,
    7.0,
    7.0,
    6.0,
  ];

  int _step = 0;
  bool _hidden = false;
  double _stepTimer = 0;
  double _animTime = 0;
  double _fadeIn = 0;

  BoredGamesGame? _resolveGame() {
    final game = findGame();
    return game is BoredGamesGame ? game : null;
  }

  List<String> _messagesForGame(BoredGamesGame? game) {
    return (game?.isTouchLayout ?? true) ? _touchMessages : _desktopMessages;
  }

  void _advance() {
    _stepTimer = 0;
    _fadeIn = 0;
    if (_step < _activeMessages.length - 1) {
      _step++;
    } else {
      _hidden = true;
    }
  }

  List<String> get _activeMessages {
    return _messagesForGame(_resolveGame());
  }

  void onTowerSelected() {
    if (_step == 0) _advance();
  }

  void onTowerPlaced() {
    if (_step == 1) _advance();
  }

  void onWaveStarted() {
    if (_step == 2) _advance();
  }

  void onAbilityUsed() {
    if (_step == 3) _advance();
  }

  void onFocusMode() {
    if (_step == 4) _advance();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final game = _resolveGame();
    final activeMessages = _messagesForGame(game);
    _animTime += dt;
    _fadeIn = (_fadeIn + dt * 3).clamp(0.0, 1.0);

    if (_hidden) return;
    if (_step < 0 || _step >= activeMessages.length) {
      _hidden = true;
      return;
    }
    final delay = _autoAdvanceDelays[_step];
    if (delay <= 0) return;
    _stepTimer += dt;
    if (_stepTimer >= delay) {
      _advance();
    }
  }

  // Static paints for optimization
  static final Paint _bgPaint = Paint();
  static final Paint _glowPaint = Paint();
  static final Paint _borderPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _accentPaint = Paint()..strokeCap = StrokeCap.round;
  static final Paint _scanlinePaint = Paint();
  static final Paint _cornerPaint = Paint();
  static final Paint _bottomLinePaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _dotGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _dotActivePaint = Paint();
  static final Paint _dotPastPaint = Paint();
  static final Paint _dotFuturePaint = Paint();
  static final Paint _rightDotGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _rightDotCorePaint = Paint();
  static final Paint _layerPaint = Paint();
  static final Map<int, Shader> _bgShaderCache = {};

  @override
  void onRemove() {
    _messagePicture?.dispose();
    _iconPicture?.dispose();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final game = _resolveGame();
    if (game == null) return;
    if (_hidden || game.size.y == 0) return;
    if (game.hideHud) return;

    final activeMessages = _messagesForGame(game);
    final screenWidth = game.size.x;
    final opacity = _fadeIn;
    if (opacity <= 0.01) return;

    // Determine accent color based on step
    final accentColor = _getStepColor(_step);
    final secondaryColor = Color.lerp(accentColor, Colors.white, 0.3)!;

    _ensureTextPictures(accentColor, game);

    // CYBERPUNK HEX FRAME DESIGN
    final contentWidth = _iconWidth + 12 + _messageWidth;
    final frameWidth = contentWidth + 48;
    final frameHeight = 36.0;
    final x = (screenWidth - frameWidth) / 2;
    // Position below the countdown timer (timer now ends around y=250)
    final y = 260.0;

    _ensureFramePath(x, y, frameWidth, frameHeight);

    // Multi-layer background for depth
    const opacitySteps = 16;
    final opacityStep =
        (opacity * opacitySteps).round().clamp(1, opacitySteps) as int;
    final shaderOpacity = opacityStep / opacitySteps;
    final bgKey = Object.hash(
      x.round(),
      y.round(),
      frameWidth.round(),
      frameHeight.round(),
      opacityStep,
    );
    final bgShader = _bgShaderCache.putIfAbsent(bgKey, () {
      if (_bgShaderCache.length > 32) {
        _bgShaderCache.clear();
      }
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF08081a).withOpacity(0.95 * shaderOpacity),
          const Color(0xFF0c0418).withOpacity(0.92 * shaderOpacity),
          const Color(0xFF100820).withOpacity(0.90 * shaderOpacity),
        ],
      ).createShader(Rect.fromLTWH(x, y, frameWidth, frameHeight));
    });
    _bgPaint.shader = bgShader;
    canvas.drawPath(_framePath, _bgPaint);

    // Outer glow (pulsing)
    final pulseIntensity = 0.25 + math.sin(_animTime * 2.5) * 0.15;
    _glowPaint
      ..color = accentColor.withOpacity(pulseIntensity * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(_framePath, _glowPaint);

    // Inner glow
    _glowPaint
      ..color = accentColor.withOpacity(0.15 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(_framePath, _glowPaint);

    // Animated scanline effect
    final scanY = y + ((_animTime * 25) % frameHeight);
    _scanlinePaint.color = accentColor.withOpacity(0.08 * opacity);
    canvas.drawRect(
      Rect.fromLTWH(x + 2, scanY, frameWidth - 4, 2),
      _scanlinePaint,
    );

    // Main border
    _borderPaint
      ..color = accentColor.withOpacity(0.7 * opacity)
      ..strokeWidth = 1.5;
    canvas.drawPath(_framePath, _borderPaint);

    // Corner accents (cyberpunk style)
    const cut = 8.0;
    _cornerPaint.color = secondaryColor.withOpacity(0.9 * opacity);

    // Top-left corner accent
    canvas.drawLine(Offset(x + cut, y), Offset(x + cut + 12, y),
        _cornerPaint..strokeWidth = 2);
    canvas.drawLine(Offset(x, y + cut), Offset(x, y + cut + 8),
        _cornerPaint..strokeWidth = 2);

    // Top-right corner accent
    canvas.drawLine(Offset(x + frameWidth - cut - 12, y),
        Offset(x + frameWidth - cut, y), _cornerPaint);
    canvas.drawLine(Offset(x + frameWidth, y + cut),
        Offset(x + frameWidth, y + cut + 8), _cornerPaint);

    // Bottom decorative line
    final lineWidth = frameWidth * 0.4;
    final lineX = x + (frameWidth - lineWidth) / 2;
    _bottomLinePaint.color = accentColor.withOpacity(0.6 * opacity);
    canvas.drawLine(
      Offset(lineX, y + frameHeight),
      Offset(lineX + lineWidth, y + frameHeight),
      _bottomLinePaint,
    );

    // Left accent bar (animated)
    final barHeight = 14.0;
    final barPulse = 0.7 + math.sin(_animTime * 3) * 0.3;
    _accentPaint
      ..color = accentColor.withOpacity(barPulse * opacity)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(x + 10, y + (frameHeight - barHeight) / 2),
      Offset(x + 10, y + (frameHeight + barHeight) / 2),
      _accentPaint,
    );

    // Icon with extra glow
    if (_iconPicture != null && _messagePicture != null) {
      final textLayerRect = Rect.fromLTWH(x, y, frameWidth, frameHeight);
      if (opacity >= 0.99) {
        canvas.save();
        canvas.translate(x + 20, y + (frameHeight - _iconHeight) / 2);
        canvas.drawPicture(_iconPicture!);
        canvas.restore();

        canvas.save();
        canvas.translate(
            x + 20 + _iconWidth + 12, y + (frameHeight - _messageHeight) / 2);
        canvas.drawPicture(_messagePicture!);
        canvas.restore();
      } else {
        _layerPaint.color = Colors.white.withOpacity(opacity);
        canvas.saveLayer(textLayerRect, _layerPaint);

        canvas.save();
        canvas.translate(x + 20, y + (frameHeight - _iconHeight) / 2);
        canvas.drawPicture(_iconPicture!);
        canvas.restore();

        canvas.save();
        canvas.translate(
            x + 20 + _iconWidth + 12, y + (frameHeight - _messageHeight) / 2);
        canvas.drawPicture(_messagePicture!);
        canvas.restore();

        canvas.restore();
      }
    }

    // Right-side decorative element
    final rightX = x + frameWidth - 18;
    final dotY = y + frameHeight / 2;
    _rightDotGlowPaint.color = accentColor.withOpacity(0.8 * opacity);
    canvas.drawCircle(Offset(rightX, dotY), 3, _rightDotGlowPaint);
    _rightDotCorePaint.color = Colors.white.withOpacity(0.9 * opacity);
    canvas.drawCircle(Offset(rightX, dotY), 2, _rightDotCorePaint);

    // Step indicator dots with enhanced style
    _drawStepDots(
      canvas,
      screenWidth,
      y + frameHeight + 10,
      opacity,
      accentColor,
      activeMessages.length,
    );
  }

  void _drawStepDots(
    Canvas canvas,
    double screenWidth,
    double y,
    double opacity,
    Color activeColor,
    int totalSteps,
  ) {
    const dotSize = 4.0;
    const dotSpacing = 10.0;
    final totalWidth =
        totalSteps * dotSize + (totalSteps - 1) * (dotSpacing - dotSize);
    final startX = (screenWidth - totalWidth) / 2;

    for (int i = 0; i < totalSteps; i++) {
      final isActive = i == _step;
      final isPast = i < _step;
      final dotX = startX + i * dotSpacing;

      if (isActive) {
        // Active dot with glow
        _dotGlowPaint.color = activeColor.withOpacity(0.4 * opacity);
        canvas.drawCircle(Offset(dotX, y), dotSize + 1, _dotGlowPaint);
        _dotActivePaint.color = activeColor.withOpacity(opacity);
        canvas.drawCircle(Offset(dotX, y), dotSize, _dotActivePaint);
      } else if (isPast) {
        // Completed dot
        _dotPastPaint.color = activeColor.withOpacity(0.5 * opacity);
        canvas.drawCircle(Offset(dotX, y), dotSize * 0.7, _dotPastPaint);
      } else {
        // Future dot
        _dotFuturePaint.color = Colors.white.withOpacity(0.2 * opacity);
        canvas.drawCircle(Offset(dotX, y), dotSize * 0.5, _dotFuturePaint);
      }
    }
  }

  Color _getStepColor(int step) {
    switch (step) {
      case 0:
        return const Color(0xFF00FFFF); // Cyan - tower selection
      case 1:
        return const Color(0xFF00FF88); // Green - placement
      case 2:
        return const Color(0xFFFF00FF); // Magenta - waves
      case 3:
        return const Color(0xFFFFAA00); // Orange - abilities
      case 4:
        return const Color(0xFF00FFFF); // Cyan - focus mode
      case 5:
        return const Color(0xFFFFD700); // Gold - sell
      default:
        return NeonColors.cyan;
    }
  }

  void _ensureTextPictures(Color accentColor, BoredGamesGame? game) {
    final isTouch = game?.isTouchLayout ?? true;
    final activeMessages = _messagesForGame(game);
    final accentValue = accentColor.value;
    if (_cachedStep == _step &&
        _cachedTouchLayout == isTouch &&
        _cachedAccentColorValue == accentValue &&
        _messagePicture != null &&
        _iconPicture != null) {
      return;
    }

    _cachedStep = _step;
    _cachedTouchLayout = isTouch;
    _cachedAccentColorValue = accentValue;

    _messagePicture?.dispose();
    _iconPicture?.dispose();

    if (_step < 0 || _step >= activeMessages.length) {
      return;
    }
    final message = activeMessages[_step].toUpperCase();
    final messagePainter = TextPainter(
      text: TextSpan(
        text: message,
        style: TextStyle(
          color: Colors.white.withOpacity(0.95),
          fontSize: 11,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _messageWidth = messagePainter.width;
    _messageHeight = messagePainter.height;
    final messageRecorder = PictureRecorder();
    final messageCanvas = Canvas(messageRecorder);
    messagePainter.paint(messageCanvas, Offset.zero);
    _messagePicture = messageRecorder.endRecording();

    final icon = _stepIcons[_step];
    final iconPainter = TextPainter(
      text: TextSpan(
        text: icon,
        style: TextStyle(
          color: accentColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: accentColor.withOpacity(0.9), blurRadius: 8),
            Shadow(color: accentColor.withOpacity(0.5), blurRadius: 16),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _iconWidth = iconPainter.width;
    _iconHeight = iconPainter.height;
    final iconRecorder = PictureRecorder();
    final iconCanvas = Canvas(iconRecorder);
    iconPainter.paint(iconCanvas, Offset.zero);
    _iconPicture = iconRecorder.endRecording();
  }

  void _ensureFramePath(
      double x, double y, double frameWidth, double frameHeight) {
    if (_frameX == x &&
        _frameY == y &&
        _frameWidth == frameWidth &&
        _frameHeight == frameHeight) {
      return;
    }

    _frameX = x;
    _frameY = y;
    _frameWidth = frameWidth;
    _frameHeight = frameHeight;

    const cut = 8.0;
    _framePath
      ..reset()
      ..moveTo(x + cut, y)
      ..lineTo(x + frameWidth - cut, y)
      ..lineTo(x + frameWidth, y + cut)
      ..lineTo(x + frameWidth, y + frameHeight - cut)
      ..lineTo(x + frameWidth - cut, y + frameHeight)
      ..lineTo(x + cut, y + frameHeight)
      ..lineTo(x, y + frameHeight - cut)
      ..lineTo(x, y + cut)
      ..close();
  }
}
