import 'dart:math' as math;
import 'dart:ui';

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

  // Cached static panel background
  Picture? _panelBackground;
  bool _panelBackgroundDirty = true;
  double _panelBackgroundWidth = 0;
  double _panelBackgroundHeight = 0;
  TextPainter? _panelLabelPainter;
  TextPainter? _pulseHotkeyPainter;
  TextPainter? _mineHotkeyPainter;
  TextPainter? _overdriveHotkeyPainter;
  TextPainter? _pulsePercentPainter;
  int _pulsePercentValue = -1;
  TextPainter? _minePercentPainter;
  int _minePercentValue = -1;
  TextPainter? _pulseCostPainter;
  int _pulseCostValue = -1;
  bool _pulseCanAfford = false;
  TextPainter? _mineCostPainter;
  int _mineCostValue = -1;
  bool _mineCanAfford = false;
  TextPainter? _mineCountPainter;
  String? _mineCountValue;

  // Cached icon geometry
  final Path _mineIconPath = Path();
  bool _mineIconPathReady = false;

  static const double abilitySize = 56.0;
  static const double spacing = 10.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _bgPaint = Paint();
  static final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _arcPaint = Paint();
  static final Paint _pulsingBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _iconPaint = Paint()
    ..strokeWidth = 2.5
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _iconFillPaint = Paint();
  static final Paint _countBadgePaint = Paint();
  static final Paint _overdriveBgPaint = Paint();
  static final Paint _overdriveGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _overdriveFillPaint = Paint();
  static final Paint _overdriveBorderPaint = Paint()
    ..style = PaintingStyle.stroke;
  static final Paint _panelBgPaint = Paint()
    ..color = const Color(0xFF000000).withOpacity(0.6);
  static final Paint _panelBorderPaint = Paint()
    ..color = const Color(0xFF00FFFF).withOpacity(0.2)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _pulsePhase += dt * 4;
  }

  @override
  void onRemove() {
    _panelBackground?.dispose();
    _panelBackground = null;
    _panelLabelPainter?.dispose();
    _panelLabelPainter = null;
    _pulseHotkeyPainter?.dispose();
    _pulseHotkeyPainter = null;
    _mineHotkeyPainter?.dispose();
    _mineHotkeyPainter = null;
    _overdriveHotkeyPainter?.dispose();
    _overdriveHotkeyPainter = null;
    _pulsePercentPainter?.dispose();
    _pulsePercentPainter = null;
    _minePercentPainter?.dispose();
    _minePercentPainter = null;
    _pulseCostPainter?.dispose();
    _pulseCostPainter = null;
    _mineCostPainter?.dispose();
    _mineCostPainter = null;
    _mineCountPainter?.dispose();
    _mineCountPainter = null;
    super.onRemove();
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

    _ensurePanelBackground(panelWidth, panelHeight);
    if (_panelBackground != null) {
      canvas.drawPicture(_panelBackground!);
    }
  }

  void _ensurePanelBackground(double panelWidth, double panelHeight) {
    if (!_panelBackgroundDirty &&
        _panelBackgroundWidth == panelWidth &&
        _panelBackgroundHeight == panelHeight) {
      return;
    }

    _panelBackgroundWidth = panelWidth;
    _panelBackgroundHeight = panelHeight;
    final recorder = PictureRecorder();
    final staticCanvas = Canvas(recorder);

    final rect = Rect.fromLTWH(0, 0, panelWidth, panelHeight);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // Background
    staticCanvas.drawRRect(rrect, _panelBgPaint);

    // Border
    staticCanvas.drawRRect(rrect, _panelBorderPaint);

    // Label
    _panelLabelPainter ??= (TextPainter(
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
    )..layout());

    _panelLabelPainter!.paint(
      staticCanvas,
      Offset((panelWidth - _panelLabelPainter!.width) / 2, panelHeight + 4),
    );

    _panelBackground?.dispose();
    _panelBackground = recorder.endRecording();
    _panelBackgroundDirty = false;
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
      _glowPaint.color = color.withOpacity(isActive ? 0.6 : 0.3);
      canvas.drawRRect(
        rrect.inflate(3),
        _glowPaint,
      );
    }

    // Background
    final bgColor = ready
        ? color.withOpacity(0.2)
        : const Color(0xFF0a0a18).withOpacity(0.8);
    _bgPaint.color = bgColor;
    canvas.drawRRect(rrect, _bgPaint);

    // Progress arc (cooldown indicator)
    if (!ready && progress < 1.0) {
      final sweepAngle = progress * 2 * math.pi;
      final arcRect = Rect.fromCircle(center: center, radius: abilitySize / 2 - 4);

      // Dark overlay
      _bgPaint.color = Colors.black.withOpacity(0.5);
      canvas.drawRRect(
        rrect,
        _bgPaint,
      );

      // Progress arc
      _arcPaint.color = color.withOpacity(0.3);
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        sweepAngle,
        true,
        _arcPaint,
      );

      // Cooldown percentage
      final percentPainter = _getPercentPainter(index, (progress * 100).toInt(), color);
      percentPainter.paint(
        canvas,
        Offset(center.dx - percentPainter.width / 2, center.dy - percentPainter.height / 2),
      );
    } else {
      // Icon when ready
      _renderAbilityIcon(canvas, center, label, color);
    }

    // Border
    _borderPaint
      ..color = (isActive ? color : (ready ? color.withOpacity(0.6) : color.withOpacity(0.2)))
      ..strokeWidth = isActive ? 2.5 : 1.5;
    canvas.drawRRect(
      rrect,
      _borderPaint,
    );

    // Pulsing border when active
    if (isActive) {
      final pulse = 0.5 + math.sin(_pulsePhase) * 0.5;
      _pulsingBorderPaint.color = color.withOpacity(0.4 * pulse);
      canvas.drawRRect(
        rrect.inflate(2),
        _pulsingBorderPaint,
      );
    }

    // Hotkey badge
    final hotkeyPainter = _getHotkeyPainter(hotkey);

    hotkeyPainter.paint(
      canvas,
      Offset(x + (abilitySize - hotkeyPainter.width) / 2, y - 10),
    );

    // Cost indicator
    final canAfford = gameRef.gold >= cost;
    final costPainter = _getCostPainter(index, cost, canAfford);

    costPainter.paint(
      canvas,
      Offset(x + abilitySize - costPainter.width - 4, y + abilitySize - costPainter.height - 4),
    );

    // Count badge (for mines)
    if (count != null && ready) {
      final countPainter = _getMineCountPainter(count);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + abilitySize - countPainter.width - 8, y + 2, countPainter.width + 6, 14),
          const Radius.circular(4),
        ),
        _countBadgePaint
          ..color = color.withOpacity(0.8)
          ..maskFilter = null,
      );

      countPainter.paint(canvas, Offset(x + abilitySize - countPainter.width - 5, y + 3));
    }
  }

  void _renderAbilityIcon(Canvas canvas, Offset center, String label, Color color) {
    _iconPaint
      ..color = color
      ..strokeWidth = 2.5;
    _iconFillPaint.color = color.withOpacity(0.3);

    if (label == 'PULSE') {
      // Expanding circles icon
      for (int i = 0; i < 3; i++) {
        final radius = 6.0 + i * 5;
        final alpha = 1.0 - i * 0.3;
        _iconPaint.color = color.withOpacity(alpha);
        canvas.drawCircle(center, radius, _iconPaint);
      }
    } else if (label == 'MINE') {
      // Mine/bomb icon
      _ensureMineIconPath();
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.drawPath(_mineIconPath, _iconFillPaint);
      canvas.drawPath(_mineIconPath, _iconPaint);
      canvas.restore();

      // Spikes
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        final x1 = center.dx + math.cos(angle) * 10;
        final y1 = center.dy + math.sin(angle) * 10;
        final x2 = center.dx + math.cos(angle) * 14;
        final y2 = center.dy + math.sin(angle) * 14;
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), _iconPaint);
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
      _overdriveGlowPaint.color = color.withOpacity(0.3);
      canvas.drawRRect(
        rrect.inflate(3),
        _overdriveGlowPaint,
      );
    }

    // Background
    _overdriveBgPaint.color = (ready ? color.withOpacity(0.2) : const Color(0xFF0a0a18).withOpacity(0.8));
    canvas.drawRRect(
      rrect,
      _overdriveBgPaint,
    );

    // Border
    _overdriveBorderPaint
      ..color = color.withOpacity(ready ? 0.6 : 0.2)
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      rrect,
      _overdriveBorderPaint,
    );

    // Eye icon for overdrive
    if (ready) {
      _iconPaint
        ..color = color
        ..strokeWidth = 2;

      // Eye shape
      canvas.save();
      canvas.translate(center.dx, center.dy);
      final eyePath = Path()
        ..moveTo(-12, 0)
        ..quadraticBezierTo(0, -8, 12, 0)
        ..quadraticBezierTo(0, 8, -12, 0);
      canvas.drawPath(eyePath, _iconPaint);
      canvas.restore();

      // Pupil
      _iconFillPaint.color = color;
      canvas.drawCircle(center, 4, _iconFillPaint);
    }

    // Uses indicator (dots)
    for (int i = 0; i < max; i++) {
      final isUsed = i < uses;
      final dotX = x + 10 + i * 12;
      final dotY = y + abilitySize - 10;

      _countBadgePaint
        ..color = isUsed ? Colors.white.withOpacity(0.2) : color
        ..maskFilter = isUsed ? null : const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(
        Offset(dotX, dotY),
        isUsed ? 3 : 4,
        _countBadgePaint,
      );
    }

    // Hotkey
    final hotkeyPainter = _getOverdriveHotkeyPainter();

    hotkeyPainter.paint(
      canvas,
      Offset(x + (abilitySize - hotkeyPainter.width) / 2, y - 10),
    );
  }

  TextPainter _getHotkeyPainter(String hotkey) {
    if (hotkey == 'SPACE') {
      _pulseHotkeyPainter ??= (TextPainter(
        text: TextSpan(
          text: '[SPACE]',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 7,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout());
      return _pulseHotkeyPainter!;
    }
    if (hotkey == 'M') {
      _mineHotkeyPainter ??= (TextPainter(
        text: TextSpan(
          text: '[M]',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 7,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout());
      return _mineHotkeyPainter!;
    }

    final painter = TextPainter(
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
    return painter;
  }

  TextPainter _getPercentPainter(int index, int percent, Color color) {
    if (index == 0) {
      if (_pulsePercentPainter == null || _pulsePercentValue != percent) {
        _pulsePercentValue = percent;
        _pulsePercentPainter = TextPainter(
          text: TextSpan(
            text: '$percent%',
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
      }
      return _pulsePercentPainter!;
    }

    if (_minePercentPainter == null || _minePercentValue != percent) {
      _minePercentValue = percent;
      _minePercentPainter = TextPainter(
        text: TextSpan(
          text: '$percent%',
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    return _minePercentPainter!;
  }

  TextPainter _getCostPainter(int index, int cost, bool canAfford) {
    if (index == 0) {
      if (_pulseCostPainter == null ||
          _pulseCostValue != cost ||
          _pulseCanAfford != canAfford) {
        _pulseCostValue = cost;
        _pulseCanAfford = canAfford;
        _pulseCostPainter = TextPainter(
          text: TextSpan(
            text: '${cost}g',
            style: TextStyle(
              color: canAfford ? const Color(0xFFFFD700) : const Color(0xFFFF4444),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
      }
      return _pulseCostPainter!;
    }

    if (_mineCostPainter == null ||
        _mineCostValue != cost ||
        _mineCanAfford != canAfford) {
      _mineCostValue = cost;
      _mineCanAfford = canAfford;
      _mineCostPainter = TextPainter(
        text: TextSpan(
          text: '${cost}g',
          style: TextStyle(
            color: canAfford ? const Color(0xFFFFD700) : const Color(0xFFFF4444),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    return _mineCostPainter!;
  }

  TextPainter _getMineCountPainter(String count) {
    if (_mineCountPainter == null || _mineCountValue != count) {
      _mineCountValue = count;
      _mineCountPainter = TextPainter(
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
    }
    return _mineCountPainter!;
  }

  TextPainter _getOverdriveHotkeyPainter() {
    _overdriveHotkeyPainter ??= (TextPainter(
      text: TextSpan(
        text: '[5x TAP]',
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 6,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout());
    return _overdriveHotkeyPainter!;
  }

  void _ensureMineIconPath() {
    if (_mineIconPathReady) return;
    _mineIconPathReady = true;
    _mineIconPath.addOval(Rect.fromCircle(center: Offset.zero, radius: 10));
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
