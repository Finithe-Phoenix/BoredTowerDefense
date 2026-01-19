import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bored_games_game.dart';

/// Modern ability panel with enhanced cooldown visualization
class AbilityPanel extends PositionComponent with HasGameRef<BoredGamesGame> {
  AbilityPanel() {
    anchor = Anchor.bottomRight;
  }

  double _time = 0;
  double _pulsePhase = 0;

  // Cached rects for tap detection
  Rect? _pulseRect;
  Rect? _mineRect;
  Rect? _overdriveRect;

  static const double abilitySize = 56.0;
  static const double spacing = 10.0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _pulsePhase += dt * 4;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (gameRef.hideHud || gameRef.focusModeActive) return;

    final screenWidth = gameRef.size.x;
    final screenHeight = gameRef.size.y;
    final compact = gameRef.isTouchLayout || screenWidth < 820;

    // Don't render if using compact button layout (abilities are in main bar)
    if (compact) return;

    // Position in bottom-right
    final panelX = screenWidth - 200;
    final panelY = screenHeight - 140;

    canvas.save();
    canvas.translate(panelX, panelY);

    // Panel background
    _renderPanelBackground(canvas);

    // Abilities
    _renderAbility(
      canvas,
      x: 10,
      y: 10,
      label: 'PULSE',
      hotkey: 'SPACE',
      color: const Color(0xFF00FFFF),
      ready: gameRef.pulseReady,
      progress: gameRef.pulseReady ? 1.0 : (1.0 - gameRef.pulseCooldownPercent),
      cost: gameRef.pulseCost,
      isActive: gameRef.pendingAbility == PendingAbility.pulse,
      index: 0,
    );

    _renderAbility(
      canvas,
      x: 10 + abilitySize + spacing,
      y: 10,
      label: 'MINE',
      hotkey: 'M',
      color: const Color(0xFFFF0066),
      ready: gameRef.mineReady,
      progress: gameRef.mineReady ? 1.0 : (1.0 - gameRef.mineCooldownPercent),
      cost: gameRef.mineCost,
      isActive: gameRef.pendingAbility == PendingAbility.mine,
      count: '${gameRef.activeMineCount}/${gameRef.maxActiveMines}',
      index: 1,
    );

    _renderOverdriveIndicator(
      canvas,
      x: 10 + (abilitySize + spacing) * 2,
      y: 10,
    );

    canvas.restore();

    // Store rects for tap detection
    _pulseRect = Rect.fromLTWH(panelX + 10, panelY + 10, abilitySize, abilitySize);
    _mineRect = Rect.fromLTWH(panelX + 10 + abilitySize + spacing, panelY + 10, abilitySize, abilitySize);
    _overdriveRect = Rect.fromLTWH(panelX + 10 + (abilitySize + spacing) * 2, panelY + 10, abilitySize, abilitySize);
  }

  void _renderPanelBackground(Canvas canvas) {
    final panelWidth = abilitySize * 3 + spacing * 2 + 20;
    final panelHeight = abilitySize + 20;

    final rect = Rect.fromLTWH(0, 0, panelWidth, panelHeight);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // Background
    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0xFF000000).withOpacity(0.6),
    );

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'ABILITIES',
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    labelPainter.paint(canvas, Offset((panelWidth - labelPainter.width) / 2, panelHeight + 4));
  }

  void _renderAbility(
    Canvas canvas, {
    required double x,
    required double y,
    required String label,
    required String hotkey,
    required Color color,
    required bool ready,
    required double progress,
    required int cost,
    required bool isActive,
    required int index,
    String? count,
  }) {
    final rect = Rect.fromLTWH(x, y, abilitySize, abilitySize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    final center = Offset(x + abilitySize / 2, y + abilitySize / 2);

    // Glow when ready or active
    if (ready || isActive) {
      canvas.drawRRect(
        rrect.inflate(3),
        Paint()
          ..color = color.withOpacity(isActive ? 0.6 : 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Background
    final bgColor = ready
        ? color.withOpacity(0.2)
        : const Color(0xFF0a0a18).withOpacity(0.8);
    canvas.drawRRect(rrect, Paint()..color = bgColor);

    // Progress arc (cooldown indicator)
    if (!ready && progress < 1.0) {
      final sweepAngle = progress * 2 * math.pi;
      final arcRect = Rect.fromCircle(center: center, radius: abilitySize / 2 - 4);

      // Dark overlay
      canvas.drawRRect(
        rrect,
        Paint()..color = Colors.black.withOpacity(0.5),
      );

      // Progress arc
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        sweepAngle,
        true,
        Paint()..color = color.withOpacity(0.3),
      );

      // Cooldown percentage
      final percentText = '${(progress * 100).toInt()}%';
      final percentPainter = TextPainter(
        text: TextSpan(
          text: percentText,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      percentPainter.paint(
        canvas,
        Offset(center.dx - percentPainter.width / 2, center.dy - percentPainter.height / 2),
      );
    } else {
      // Icon when ready
      _renderAbilityIcon(canvas, center, label, color);
    }

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = (isActive ? color : (ready ? color.withOpacity(0.6) : color.withOpacity(0.2)))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 2.5 : 1.5,
    );

    // Pulsing border when active
    if (isActive) {
      final pulse = 0.5 + math.sin(_pulsePhase) * 0.5;
      canvas.drawRRect(
        rrect.inflate(2),
        Paint()
          ..color = color.withOpacity(0.4 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Label below
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: ready ? color : Colors.white.withOpacity(0.5),
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Hotkey badge
    final hotkeyPainter = TextPainter(
      text: TextSpan(
        text: '[$hotkey]',
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 7,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    hotkeyPainter.paint(
      canvas,
      Offset(x + (abilitySize - hotkeyPainter.width) / 2, y - 10),
    );

    // Cost indicator
    final canAfford = gameRef.gold >= cost;
    final costText = '${cost}g';
    final costPainter = TextPainter(
      text: TextSpan(
        text: costText,
        style: TextStyle(
          color: canAfford ? const Color(0xFFFFD700) : const Color(0xFFFF4444),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    costPainter.paint(
      canvas,
      Offset(x + abilitySize - costPainter.width - 4, y + abilitySize - costPainter.height - 4),
    );

    // Count badge (for mines)
    if (count != null && ready) {
      final countPainter = TextPainter(
        text: TextSpan(
          text: count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + abilitySize - countPainter.width - 8, y + 2, countPainter.width + 6, 14),
          const Radius.circular(4),
        ),
        Paint()..color = color.withOpacity(0.8),
      );

      countPainter.paint(canvas, Offset(x + abilitySize - countPainter.width - 5, y + 3));
    }
  }

  void _renderAbilityIcon(Canvas canvas, Offset center, String label, Color color) {
    final iconPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..color = color.withOpacity(0.3);

    if (label == 'PULSE') {
      // Expanding circles icon
      for (int i = 0; i < 3; i++) {
        final radius = 6.0 + i * 5;
        final alpha = 1.0 - i * 0.3;
        canvas.drawCircle(center, radius, iconPaint..color = color.withOpacity(alpha));
      }
    } else if (label == 'MINE') {
      // Mine/bomb icon
      final path = Path()
        ..addOval(Rect.fromCircle(center: center, radius: 10));
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, iconPaint);

      // Spikes
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        final x1 = center.dx + math.cos(angle) * 10;
        final y1 = center.dy + math.sin(angle) * 10;
        final x2 = center.dx + math.cos(angle) * 14;
        final y2 = center.dy + math.sin(angle) * 14;
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), iconPaint);
      }
    }
  }

  void _renderOverdriveIndicator(Canvas canvas, {required double x, required double y}) {
    final uses = gameRef.fpsUsesTotal;
    final max = gameRef.maxFpsUsesMatch;
    final remaining = (max - uses).clamp(0, max);
    final ready = remaining > 0;

    final color = ready ? const Color(0xFFFF00FF) : const Color(0xFF444444);
    final rect = Rect.fromLTWH(x, y, abilitySize, abilitySize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    final center = Offset(x + abilitySize / 2, y + abilitySize / 2);

    // Glow when ready
    if (ready) {
      canvas.drawRRect(
        rrect.inflate(3),
        Paint()
          ..color = color.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Background
    canvas.drawRRect(
      rrect,
      Paint()..color = (ready ? color.withOpacity(0.2) : const Color(0xFF0a0a18).withOpacity(0.8)),
    );

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color.withOpacity(ready ? 0.6 : 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Eye icon for overdrive
    if (ready) {
      final iconPaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      // Eye shape
      final eyePath = Path()
        ..moveTo(center.dx - 12, center.dy)
        ..quadraticBezierTo(center.dx, center.dy - 8, center.dx + 12, center.dy)
        ..quadraticBezierTo(center.dx, center.dy + 8, center.dx - 12, center.dy);
      canvas.drawPath(eyePath, iconPaint);

      // Pupil
      canvas.drawCircle(center, 4, Paint()..color = color);
    }

    // Uses indicator (dots)
    for (int i = 0; i < max; i++) {
      final isUsed = i < uses;
      final dotX = x + 10 + i * 12;
      final dotY = y + abilitySize - 10;

      canvas.drawCircle(
        Offset(dotX, dotY),
        isUsed ? 3 : 4,
        Paint()
          ..color = isUsed ? Colors.white.withOpacity(0.2) : color
          ..maskFilter = isUsed ? null : const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // Hotkey
    final hotkeyPainter = TextPainter(
      text: TextSpan(
        text: '[5x TAP]',
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 6,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    hotkeyPainter.paint(
      canvas,
      Offset(x + (abilitySize - hotkeyPainter.width) / 2, y - 10),
    );
  }

  /// Check if a tap position hits any ability button
  bool handleTap(Vector2 tapPosition) {
    if (gameRef.hideHud || gameRef.focusModeActive) return false;
    if (gameRef.isTouchLayout || gameRef.size.x < 820) return false;

    final pos = Offset(tapPosition.x, tapPosition.y);

    if (_pulseRect != null && _pulseRect!.contains(pos)) {
      if (gameRef.pulseReady && gameRef.gold >= gameRef.pulseCost) {
        gameRef.activateNeonPulse();
        return true;
      }
    }

    if (_mineRect != null && _mineRect!.contains(pos)) {
      if (gameRef.mineReady && gameRef.gold >= gameRef.mineCost) {
        gameRef.deployMine();
        return true;
      }
    }

    return false;
  }
}
