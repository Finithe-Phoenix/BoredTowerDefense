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

  // Visual constants
  static const double _barWidth = 600;
  static const double _barHeight = 40;
  static const double _borderWidth = 3;

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

    final glowPaint = Paint()
      ..color = _getPhaseColor(_currentPhase).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawRRect(glowRect, glowPaint);
  }

  void _renderHealthBar(Canvas canvas) {
    final barRect = Rect.fromCenter(
      center: Offset.zero,
      width: _barWidth,
      height: _barHeight,
    );

    // Background
    final bgPaint = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(6)),
      bgPaint,
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
    final gradient = LinearGradient(
      colors: [
        phaseColor,
        phaseColor.withOpacity(0.6),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(healthRect);

    final healthPaint = Paint()..shader = gradient;
    canvas.drawRRect(
      RRect.fromRectAndRadius(healthRect, const Radius.circular(4)),
      healthPaint,
    );

    // Animated pulse on health bar
    final pulseAlpha = (math.sin(_animationPhase * 2) * 0.3 + 0.3);
    final pulsePaint = Paint()
      ..color = Colors.white.withOpacity(pulseAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(healthRect, const Radius.circular(4)),
      pulsePaint,
    );

    // Segmented divisions (phase markers)
    final divisionPaint = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (int i = 1; i < 4; i++) {
      final x = -_barWidth / 2 + (_barWidth * i / 4);
      canvas.drawLine(
        Offset(x, -_barHeight / 2),
        Offset(x, _barHeight / 2),
        divisionPaint,
      );
    }

    // Border
    final borderPaint = Paint()
      ..color = phaseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _borderWidth;

    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(6)),
      borderPaint,
    );

    // Corner accents
    _renderCornerAccents(canvas, barRect, phaseColor);
  }

  void _renderCornerAccents(Canvas canvas, Rect barRect, Color color) {
    final accentPaint = Paint()
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
        accentPaint,
      );

      // Vertical line
      canvas.drawLine(
        corner,
        Offset(
          corner.dx,
          corner.dy + (isTop ? accentLength : -accentLength),
        ),
        accentPaint,
      );
    }
  }

  void _renderBossName(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: _bossName,
        style: TextStyle(
          color: _getPhaseColor(_currentPhase),
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
            Shadow(
              color: _getPhaseColor(_currentPhase).withOpacity(0.6),
              blurRadius: 10,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -_barHeight / 2 - 35),
    );

    // Subtitle: Health percentage
    final healthText = '${(_displayedHealth * 100).toInt()}%';
    final healthPainter = TextPainter(
      text: TextSpan(
        text: healthText,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 16,
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
    );

    healthPainter.layout();
    healthPainter.paint(
      canvas,
      Offset(-healthPainter.width / 2, _barHeight / 2 + 10),
    );
  }

  void _renderPhaseIndicator(Canvas canvas) {
    // Phase indicator on the right side
    final phaseText = 'PHASE $_currentPhase/4';
    final phasePainter = TextPainter(
      text: TextSpan(
        text: phaseText,
        style: TextStyle(
          color: _getPhaseColor(_currentPhase),
          fontSize: 14,
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
    );

    phasePainter.layout();
    phasePainter.paint(
      canvas,
      Offset(_barWidth / 2 + 15, -phasePainter.height / 2),
    );

    // Phase indicator dots
    for (int i = 0; i < 4; i++) {
      final isActive = i < _currentPhase;
      final dotPaint = Paint()
        ..color = isActive
            ? _getPhaseColor(_currentPhase)
            : Colors.grey.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      if (isActive) {
        dotPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      }

      canvas.drawCircle(
        Offset(_barWidth / 2 + 15 + (i * 12), phasePainter.height / 2 + 15),
        isActive ? 5 : 4,
        dotPaint,
      );
    }

    // Warning skull icon for phase 4
    if (_currentPhase >= 4) {
      _renderWarningSkull(canvas);
    }
  }

  void _renderWarningSkull(Canvas canvas) {
    // Simple skull warning indicator
    final skullPaint = Paint()
      ..color = const Color(0xFFFF0066)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final skullX = -_barWidth / 2 - 30;
    final skullY = 0.0;

    // Skull (simplified)
    canvas.drawCircle(Offset(skullX, skullY - 5), 12, skullPaint);

    // Crossbones
    canvas.drawLine(
      Offset(skullX - 8, skullY + 10),
      Offset(skullX + 8, skullY + 10),
      Paint()
        ..color = const Color(0xFFFF0066)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Pulsing glow
    final glowAlpha = (math.sin(_animationPhase * 4) * 0.4 + 0.6);
    canvas.drawCircle(
      Offset(skullX, skullY),
      18,
      Paint()
        ..color = const Color(0xFFFF0066).withOpacity(glowAlpha * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }
}
