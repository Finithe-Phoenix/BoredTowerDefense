import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../entities/boss.dart';

/// Epic boss health bar displayed at the top of the screen
class BossHealthBar extends PositionComponent {
  BossHealthBar({
    required this.screenWidth,
    required this.screenHeight,
  }) : super(priority: 1000) {
    position = Vector2(screenWidth / 2, 60);
    anchor = Anchor.center;
  }

  final double screenWidth;
  final double screenHeight;

  Boss? _currentBoss;
  double _animationPhase = 0;
  double _displayedHealth = 1.0;
  String _bossName = '';
  int _currentPhase = 1;

  TextPainter? _bossNamePainter;
  String _bossNameText = '';
  int _bossNameColorValue = 0;
  TextPainter? _healthPainter;
  String _healthText = '';
  TextPainter? _phasePainter;
  String _phaseText = '';
  int _phaseColorValue = 0;

  // Visual constants
  double _barWidth = 520;
  double _barHeight = 32;
  double _nameGap = 16;
  double _healthGap = 10;
  double _phaseOffsetX = 15;
  double _phaseDotOffsetY = 15;
  double _nameFontSize = 20;
  double _healthFontSize = 14;
  double _phaseFontSize = 13;
  double _lastLayoutWidth = -1;
  double _lastLayoutTopInset = -1;
  bool _compact = false;
  static const double _borderWidth = 3;
  static final Paint _phaseDotPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _skullPaint = Paint()
    ..color = const Color(0xFFFF0066)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _barBgPaint = Paint();
  static final Paint _healthFillPaint = Paint();
  static final Paint _pulsePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _divisionPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _barBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = _borderWidth;
  static final Paint _accentPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 4;
  Shader? _healthFillShader;
  double _healthShaderWidth = -1;
  int _healthShaderPhaseColor = 0;

  void updateLayout({
    required double screenWidth,
    required double topInset,
    required bool compact,
  }) {
    if (_lastLayoutWidth == screenWidth &&
        _lastLayoutTopInset == topInset &&
        _compact == compact) {
      return;
    }

    _lastLayoutWidth = screenWidth;
    _lastLayoutTopInset = topInset;
    _compact = compact;

    final widthTarget = screenWidth * (compact ? 0.55 : 0.7);
    _barWidth = widthTarget.clamp(260.0, 520.0);
    _barHeight = compact ? 26.0 : 32.0;
    _nameGap = compact ? 8.0 : 12.0;
    _healthGap = compact ? 6.0 : 8.0;
    _phaseOffsetX = compact ? 10.0 : 15.0;
    _phaseDotOffsetY = compact ? 10.0 : 15.0;
    _nameFontSize = compact ? 16.0 : 20.0;
    _healthFontSize = compact ? 12.0 : 14.0;
    _phaseFontSize = compact ? 11.0 : 13.0;

    position = Vector2(
      screenWidth / 2,
      topInset - (compact ? 4.0 : 2.0),
    );

    _bossNamePainter = null;
    _healthPainter = null;
    _phasePainter = null;
    _healthFillShader = null;
    _healthShaderWidth = -1;
  }

  /// Update the boss being tracked
  void setBoss(Boss? boss) {
    _currentBoss = boss;
    if (boss != null) {
      _displayedHealth = boss.healthPercent;
      _bossName = _getBossName(boss.bossType);
      _currentPhase = boss.currentPhase;
    }
  }

  String _getBossName(BossType type) {
    switch (type) {
      case BossType.miniBoss:
        return 'ELITE GUARD';
      case BossType.citadelCore:
        return 'CITADEL CORE';
      case BossType.abyssGate:
        return 'ABYSS GATE';
      case BossType.voidlineApex:
        return 'VOIDLINE APEX';
      case BossType.shardVault:
        return 'SHARD VAULT GUARDIAN';
      case BossType.arcFortress:
        return 'ARC FORTRESS TITAN';
      case BossType.coreHunter:
        return 'CORE HUNTER';
      case BossType.omegaGrid:
        return 'OMEGA GRID NEXUS';
      case BossType.stormTower:
        return 'STORM TOWER LORD';
      case BossType.finalGate:
        return 'FINAL GATE KEEPER';
      case BossType.omegaNexus:
        return 'OMEGA NEXUS - FINAL BOSS';
    }
  }

  Color _getPhaseColor(int phase) {
    switch (phase) {
      case 1:
        return const Color(0xFF00FF88); // Green - healthy
      case 2:
        return const Color(0xFFFFFF00); // Yellow - warning
      case 3:
        return const Color(0xFFFF6600); // Orange - danger
      case 4:
        return const Color(0xFFFF0066); // Red/Magenta - critical
      default:
        return const Color(0xFF00FF88);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _animationPhase += dt * 3;

    if (_currentBoss != null && _currentBoss!.isAlive) {
      // Smoothly animate health bar
      final targetHealth = _currentBoss!.healthPercent;
      _displayedHealth += (targetHealth - _displayedHealth) * dt * 5;

      // Update phase
      _currentPhase = _currentBoss!.currentPhase;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_currentBoss == null || !_currentBoss!.isAlive) return;

    // Center the health bar
    canvas.save();

    // Draw background glow
    _renderGlow(canvas);

    // Draw main health bar
    _renderHealthBar(canvas);

    // Draw boss name
    _renderBossName(canvas);

    // Draw phase indicator
    _renderPhaseIndicator(canvas);

    canvas.restore();
  }

  void _renderGlow(Canvas canvas) {
    final glowRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: _barWidth + 20,
        height: _barHeight + 20,
      ),
      const Radius.circular(8),
    );

    _glowPaint.color = _getPhaseColor(_currentPhase).withOpacity(0.3);
    canvas.drawRRect(glowRect, _glowPaint);
  }

  void _renderHealthBar(Canvas canvas) {
    final barRect = Rect.fromCenter(
      center: Offset.zero,
      width: _barWidth,
      height: _barHeight,
    );

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(6)),
      _barBgPaint..color = const Color(0xFF000000).withOpacity(0.8),
    );

    // Health fill with gradient
    final healthWidth = _barWidth * _displayedHealth;
    final healthRect = Rect.fromLTWH(
      -_barWidth / 2,
      -_barHeight / 2,
      healthWidth,
      _barHeight,
    );

    final phaseColor = _getPhaseColor(_currentPhase);
    if (_healthFillShader == null ||
        _healthShaderWidth != healthWidth ||
        _healthShaderPhaseColor != phaseColor.value) {
      _healthShaderWidth = healthWidth;
      _healthShaderPhaseColor = phaseColor.value;
      _healthFillShader = LinearGradient(
        colors: [
          phaseColor,
          phaseColor.withOpacity(0.6),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(healthRect);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(healthRect, const Radius.circular(4)),
      _healthFillPaint..shader = _healthFillShader,
    );

    // Animated pulse on health bar
    final pulseAlpha = (math.sin(_animationPhase * 2) * 0.3 + 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(healthRect, const Radius.circular(4)),
      _pulsePaint..color = Colors.white.withOpacity(pulseAlpha),
    );

    // Segmented divisions (phase markers)
    _divisionPaint.color = const Color(0xFF000000).withOpacity(0.6);

    for (int i = 1; i < 4; i++) {
      final x = -_barWidth / 2 + (_barWidth * i / 4);
      canvas.drawLine(
        Offset(x, -_barHeight / 2),
        Offset(x, _barHeight / 2),
        _divisionPaint,
      );
    }

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(6)),
      _barBorderPaint
        ..color = phaseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _borderWidth,
    );

    // Corner accents
    _renderCornerAccents(canvas, barRect, phaseColor);
  }

  void _renderCornerAccents(Canvas canvas, Rect barRect, Color color) {
    _accentPaint
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final accentLength = 15.0;
    final corners = [
      Offset(barRect.left, barRect.top), // Top-left
      Offset(barRect.right, barRect.top), // Top-right
      Offset(barRect.left, barRect.bottom), // Bottom-left
      Offset(barRect.right, barRect.bottom), // Bottom-right
    ];

    for (int i = 0; i < corners.length; i++) {
      final corner = corners[i];
      final isLeft = i == 0 || i == 2;
      final isTop = i == 0 || i == 1;

      // Horizontal line
      canvas.drawLine(
        corner,
        Offset(
          corner.dx + (isLeft ? accentLength : -accentLength),
          corner.dy,
        ),
        _accentPaint,
      );

      // Vertical line
      canvas.drawLine(
        corner,
        Offset(
          corner.dx,
          corner.dy + (isTop ? accentLength : -accentLength),
        ),
        _accentPaint,
      );
    }
  }

  void _renderBossName(Canvas canvas) {
    final phaseColor = _getPhaseColor(_currentPhase);
    if (_bossNamePainter == null ||
        _bossNameText != _bossName ||
        _bossNameColorValue != phaseColor.value) {
      _bossNameText = _bossName;
      _bossNameColorValue = phaseColor.value;
      _bossNamePainter = TextPainter(
        text: TextSpan(
          text: _bossName,
          style: TextStyle(
            color: phaseColor,
            fontSize: _nameFontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
              Shadow(
                color: phaseColor.withOpacity(0.6),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    _bossNamePainter!.paint(
      canvas,
      Offset(
        -_bossNamePainter!.width / 2,
        -_barHeight / 2 - _nameGap,
      ),
    );

    // Subtitle: Health percentage
    final healthText = '${(_displayedHealth * 100).toInt()}%';
    if (_healthPainter == null || _healthText != healthText) {
      _healthText = healthText;
      _healthPainter = TextPainter(
        text: TextSpan(
          text: healthText,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: _healthFontSize,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    _healthPainter!.paint(
      canvas,
      Offset(
        -_healthPainter!.width / 2,
        _barHeight / 2 + _healthGap,
      ),
    );
  }

  void _renderPhaseIndicator(Canvas canvas) {
    // Phase indicator on the right side
    final phaseText = 'PHASE $_currentPhase/4';
    final phaseColor = _getPhaseColor(_currentPhase);
    if (_phasePainter == null ||
        _phaseText != phaseText ||
        _phaseColorValue != phaseColor.value) {
      _phaseText = phaseText;
      _phaseColorValue = phaseColor.value;
      _phasePainter = TextPainter(
        text: TextSpan(
          text: phaseText,
          style: TextStyle(
            color: phaseColor,
            fontSize: _phaseFontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    _phasePainter!.paint(
      canvas,
      Offset(_barWidth / 2 + _phaseOffsetX, -_phasePainter!.height / 2),
    );

    // Phase indicator dots
    for (int i = 0; i < 4; i++) {
      final isActive = i < _currentPhase;
      _phaseDotPaint
        ..color = isActive ? phaseColor : Colors.grey.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter =
            isActive ? const MaskFilter.blur(BlurStyle.normal, 3) : null;

      canvas.drawCircle(
        Offset(
          _barWidth / 2 + _phaseOffsetX + (i * 12),
          _phasePainter!.height / 2 + _phaseDotOffsetY,
        ),
        isActive ? 5 : 4,
        _phaseDotPaint,
      );
    }

    // Warning skull icon for phase 4
    if (_currentPhase >= 4) {
      _renderWarningSkull(canvas);
    }
  }

  void _renderWarningSkull(Canvas canvas) {
    // Simple skull warning indicator
    _skullPaint
      ..color = const Color(0xFFFF0066)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final skullX = -_barWidth / 2 - 30;
    final skullY = 0.0;

    // Skull (simplified)
    canvas.drawCircle(Offset(skullX, skullY - 5), 12, _skullPaint);

    // Crossbones
    canvas.drawLine(
      Offset(skullX - 8, skullY + 10),
      Offset(skullX + 8, skullY + 10),
      _barBorderPaint
        ..color = const Color(0xFFFF0066)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Pulsing glow
    final glowAlpha = (math.sin(_animationPhase * 4) * 0.4 + 0.6);
    canvas.drawCircle(
      Offset(skullX, skullY),
      18,
      _glowPaint
        ..color = const Color(0xFFFF0066).withOpacity(glowAlpha * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }
}
