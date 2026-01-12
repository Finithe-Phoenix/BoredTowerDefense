import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bored_games_game.dart';
import '../entities/tower.dart';
import '../../ui/theme/neon_theme.dart';
import 'hud_button.dart';

/// Professional HUD with cyberpunk aesthetic
class HudComponent extends PositionComponent with HasGameRef<BoredGamesGame> {
  // Button references for state updates
  late HudButton pulseArcherBtn;
  late HudButton circuitCannonBtn;
  late HudButton phaseMageBtn;
  late HudButton glimmerFieldBtn;
  late HudButton pulseAbilityBtn;
  late HudButton mineAbilityBtn;
  late HudButton waveButton;

  double _time = 0;
  final Map<String, _TextCache> _textCache = {};
  TextPainter? _instructionPainter;
  TowerType? _lastSelected;
  TextPainter? _selectionNamePainter;
  TextPainter? _selectionStatsPainter;
  TextPainter? _towerInfoNamePainter;
  TextPainter? _towerInfoStatsPainter;
  int _lastGold = -1;
  int _lastLives = -1;
  int _lastScore = -1;
  int _lastWave = -1;
  int _lastEnemies = -1;
  int _lastTowers = -1;

  // Layout constants
  static const double topBarHeight = 60.0;
  static const double bottomBarHeight = 100.0;
  static const double buttonHeight = 44.0;
  static const double buttonSpacing = 12.0;
  static const bool reduceFlicker = true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    priority = 100;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _repositionButtons();
  }

  void _repositionButtons() {
    children.whereType<HudButton>().toList().forEach((b) => b.removeFromParent());

    final screenWidth = gameRef.size.x;
    final screenHeight = gameRef.size.y;
    final bottomY = screenHeight - bottomBarHeight + 35;

    // Tower buttons - centered with better spacing
    const buttonWidth = 100.0;
    const abilityWidth = 110.0;
    const mineWidth = 90.0;
    const waveWidth = 100.0;
    final totalWidth = 4 * buttonWidth + abilityWidth + mineWidth + waveWidth + 6 * buttonSpacing;
    final startX = (screenWidth - totalWidth) / 2;

    pulseArcherBtn = HudButton(
      label: 'ARCHER',
      position: Vector2(startX, bottomY),
      size: Vector2(buttonWidth, buttonHeight),
      color: TowerType.pulseArcher.color,
      isSelected: true,
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.towerManager.setSelectedTowerType(TowerType.pulseArcher),
    );

    circuitCannonBtn = HudButton(
      label: 'CANNON',
      position: Vector2(startX + buttonWidth + buttonSpacing, bottomY),
      size: Vector2(buttonWidth, buttonHeight),
      color: TowerType.circuitCannon.color,
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.towerManager.setSelectedTowerType(TowerType.circuitCannon),
    );

    phaseMageBtn = HudButton(
      label: 'MAGE',
      position: Vector2(startX + 2 * (buttonWidth + buttonSpacing), bottomY),
      size: Vector2(buttonWidth, buttonHeight),
      color: TowerType.phaseMage.color,
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.towerManager.setSelectedTowerType(TowerType.phaseMage),
    );

    glimmerFieldBtn = HudButton(
      label: 'GLIMMER',
      position: Vector2(startX + 3 * (buttonWidth + buttonSpacing), bottomY),
      size: Vector2(buttonWidth, buttonHeight),
      color: TowerType.glimmerField.color,
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.towerManager.setSelectedTowerType(TowerType.glimmerField),
    );

    pulseAbilityBtn = HudButton(
      label: 'PULSE',
      position: Vector2(startX + 4 * (buttonWidth + buttonSpacing), bottomY),
      size: Vector2(abilityWidth, buttonHeight),
      color: const Color(0xFF00FFFF),
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.activateNeonPulse(),
    );

    mineAbilityBtn = HudButton(
      label: 'MINE',
      position: Vector2(startX + 4 * (buttonWidth + buttonSpacing) + abilityWidth + buttonSpacing, bottomY),
      size: Vector2(mineWidth, buttonHeight),
      color: const Color(0xFFFF0066),
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.deployMine(),
    );

    waveButton = HudButton(
      label: 'START WAVE',
      position: Vector2(startX + 4 * (buttonWidth + buttonSpacing) + abilityWidth + mineWidth + 2 * buttonSpacing, bottomY),
      size: Vector2(waveWidth, buttonHeight),
      color: const Color(0xFF00FF88),
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.startWave(count: 6),
      enabled: !gameRef.enemyManager.spawning,
    );

    addAll([
      pulseArcherBtn,
      circuitCannonBtn,
      phaseMageBtn,
      glimmerFieldBtn,
      pulseAbilityBtn,
      mineAbilityBtn,
      waveButton,
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    final selected = gameRef.towerManager.selectedTowerType;
    pulseArcherBtn.isSelected = selected == TowerType.pulseArcher;
    circuitCannonBtn.isSelected = selected == TowerType.circuitCannon;
    phaseMageBtn.isSelected = selected == TowerType.phaseMage;
    glimmerFieldBtn.isSelected = selected == TowerType.glimmerField;

    waveButton.enabled = !gameRef.enemyManager.spawning;
    _updateSelectionCache(selected);
    _updateResourceCache();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final screenWidth = gameRef.size.x;
    final screenHeight = gameRef.size.y;

    _drawTopPanel(canvas, screenWidth);
    _drawBottomPanel(canvas, screenWidth, screenHeight);

    _drawSelectionInfo(canvas, screenWidth);

    // Instruction prompt
    _instructionPainter ??= _buildPainter(
      'Select a tower and drag to place it',
      const TextStyle(
        color: Colors.white70,
        fontSize: 11,
        fontFamily: 'monospace',
        letterSpacing: 0.8,
      ),
    );
    _instructionPainter!.paint(
      canvas,
      Offset(24, screenHeight - bottomBarHeight - 26),
    );
  }

  void _drawSelectionInfo(Canvas canvas, double screenWidth) {
    final selected = gameRef.towerManager.selectedTowerType;
    final panelWidth = 260.0;
    final panelHeight = 60.0;
    final panelX = (screenWidth - panelWidth) / 2;
    final panelY = 40.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(panelX, panelY, panelWidth, panelHeight),
      const Radius.circular(12),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = selected.color.withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = NeonColors.gridLine.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final labelPainter = _selectionNamePainter ??
        _buildPainter(
          selected.name.toUpperCase(),
          TextStyle(
            color: selected.color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        );

    labelPainter.paint(canvas, Offset(panelX + 12, panelY + 10));

    final statsText =
        'DMG ${selected.damage.toInt()}    RNG ${selected.range.toInt()}    SPD ${selected.fireRate.toStringAsFixed(1)}';
    final statsPainter = _selectionStatsPainter ??
        _buildPainter(
          statsText,
          TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        );

    statsPainter.paint(canvas, Offset(panelX + 12, panelY + 32));
  }

  void _drawTopPanel(Canvas canvas, double screenWidth) {
    // Main panel background
    final panelRect = Rect.fromLTWH(0, 0, screenWidth, topBarHeight);

    // Multi-layer background
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0a0a14),
        const Color(0xFF080810),
        const Color(0xFF060608).withOpacity(0.95),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 0.85, 1.0],
    ).createShader(panelRect);

    canvas.drawRect(panelRect, Paint()..shader = bgGradient);

    if (!reduceFlicker) {
      // Horizontal scan line effect
      final scanX = ((_time * 200) % (screenWidth + 400)) - 200;
      final scanGradient = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF00FFFF).withOpacity(0.03),
          const Color(0xFF00FFFF).withOpacity(0.08),
          const Color(0xFF00FFFF).withOpacity(0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(scanX, 0, 400, topBarHeight));
      canvas.drawRect(Rect.fromLTWH(scanX, 0, 400, topBarHeight), Paint()..shader = scanGradient);
    }

    // Bottom edge - glowing line
    _drawGlowingLine(canvas, 0, topBarHeight - 2, screenWidth, topBarHeight - 2, const Color(0xFF00FFFF), 0.6);

    // Hexagonal accent patterns on sides
    _drawHexPattern(canvas, 10, 10, 3, 0.15);
    _drawHexPattern(canvas, screenWidth - 50, 10, 3, 0.15);

    // Draw resource panels
    _drawResourcePanels(canvas, screenWidth);

    // Center title/logo area
    _drawCenterLogo(canvas, screenWidth);

    // Wave alert (if active)
    _drawWaveAlert(canvas, screenWidth);
  }

  void _drawResourcePanels(Canvas canvas, double screenWidth) {
    // Left side resources
    _drawResourceCard(canvas, 20, 8, 'GOLD', '${gameRef.gold}', const Color(0xFFFFD700), 0);
    _drawResourceCard(canvas, 130, 8, 'LIVES', '${gameRef.lives}', const Color(0xFFFF4466), 1);
    _drawResourceCard(canvas, 240, 8, 'SCORE', '${gameRef.score}', const Color(0xFF00FF88), 2);

    // Right side resources
    _drawResourceCard(canvas, screenWidth - 340, 8, 'WAVE', '${gameRef.enemyManager.currentWave}', const Color(0xFFFF00FF), 3);
    _drawResourceCard(canvas, screenWidth - 230, 8, 'ENEMIES', '${gameRef.enemyManager.aliveCount}', const Color(0xFFFF6644), 4);
    _drawResourceCard(canvas, screenWidth - 120, 8, 'TOWERS', '${gameRef.towerManager.towers.length}', const Color(0xFF44AAFF), 5);
  }

  void _drawResourceCard(Canvas canvas, double x, double y, String label, String value, Color color, int index) {
    const cardWidth = 100.0;
    const cardHeight = 42.0;
    final cardRect = Rect.fromLTWH(x, y, cardWidth, cardHeight);

    // Card background with subtle gradient
    final cardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withOpacity(0.08),
        const Color(0xFF0a0a14).withOpacity(0.9),
        color.withOpacity(0.05),
      ],
    ).createShader(cardRect);

    final rrect = RRect.fromRectAndRadius(cardRect, const Radius.circular(4));
    canvas.drawRRect(rrect, Paint()..shader = cardGradient);

    // Animated border
    final borderAlpha = reduceFlicker
        ? 0.35
        : 0.3 + math.sin(_time * 2 + index * 0.5) * 0.1;
    final borderPaint = Paint()
      ..color = color.withOpacity(borderAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);

    // Corner accents
    final accentPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2;

    // Top-left corner
    canvas.drawLine(Offset(x, y + 8), Offset(x, y), accentPaint);
    canvas.drawLine(Offset(x, y), Offset(x + 8, y), accentPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(x + cardWidth - 8, y + cardHeight), Offset(x + cardWidth, y + cardHeight), accentPaint);
    canvas.drawLine(Offset(x + cardWidth, y + cardHeight - 8), Offset(x + cardWidth, y + cardHeight), accentPaint);

    // Icon indicator (glowing dot)
    final dotPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(x + 14, y + cardHeight / 2), 5, dotPaint);

    final dotCore = Paint()..color = color;
    canvas.drawCircle(Offset(x + 14, y + cardHeight / 2), 3, dotCore);

    // Label
    final labelPainter = _getPainter(
      'label-$label',
      label,
      TextStyle(
        color: color.withOpacity(0.7),
        fontSize: 9,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
      ),
    );
    labelPainter.paint(canvas, Offset(x + 26, y + 6));

    final valuePainter = _getPainter(
      'value-$label',
      value,
      TextStyle(
        color: color,
        fontSize: 18,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        shadows: [
          Shadow(color: color.withOpacity(0.8), blurRadius: 8),
        ],
      ),
    );
    valuePainter.paint(canvas, Offset(x + 26, y + 20));
  }

  void _drawCenterLogo(Canvas canvas, double screenWidth) {
    final centerX = screenWidth / 2;

    // Decorative lines emanating from center
    final linePaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.2)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(centerX - 80, 30), Offset(centerX - 30, 30), linePaint);
    canvas.drawLine(Offset(centerX + 30, 30), Offset(centerX + 80, 30), linePaint);

    // Small diamond accent
    final diamondPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final diamondPath = Path()
      ..moveTo(centerX, 22)
      ..lineTo(centerX + 8, 30)
      ..lineTo(centerX, 38)
      ..lineTo(centerX - 8, 30)
      ..close();

    canvas.drawPath(diamondPath, diamondPaint);

    // Inner filled diamond
    final innerDiamond = Path()
      ..moveTo(centerX, 26)
      ..lineTo(centerX + 4, 30)
      ..lineTo(centerX, 34)
      ..lineTo(centerX - 4, 30)
      ..close();

    canvas.drawPath(innerDiamond, Paint()..color = const Color(0xFF00FFFF).withOpacity(0.3));
  }

  void _drawWaveAlert(Canvas canvas, double screenWidth) {
    final modifier = gameRef.enemyManager.waveDescription;
    if (modifier.isEmpty) return;

    final alertX = screenWidth / 2;
    final pulseAlpha = reduceFlicker ? 0.8 : 0.8 + math.sin(_time * 8) * 0.2;
    final pulseScale = reduceFlicker ? 1.0 : 1.0 + math.sin(_time * 6) * 0.02;

    // Alert background
    final alertBg = Paint()
      ..color = const Color(0xFFFF0066).withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(alertX, 48), width: 120 * pulseScale, height: 20),
        const Radius.circular(4),
      ),
      alertBg,
    );

    final alertPainter = TextPainter(
      text: TextSpan(
        text: 'ALERT $modifier',
        style: TextStyle(
          color: const Color(0xFFFF0066).withOpacity(pulseAlpha),
          fontSize: 12,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          shadows: [
            Shadow(color: const Color(0xFFFF0066).withOpacity(0.9), blurRadius: 12),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    alertPainter.paint(canvas, Offset(alertX - alertPainter.width / 2, 40));
  }

  void _drawBottomPanel(Canvas canvas, double screenWidth, double screenHeight) {
    final panelRect = Rect.fromLTWH(0, screenHeight - bottomBarHeight, screenWidth, bottomBarHeight);

    // Multi-layer background
    final bgGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        const Color(0xFF0a0a14),
        const Color(0xFF080810),
        const Color(0xFF060608).withOpacity(0.95),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.85, 1.0],
    ).createShader(panelRect);

    canvas.drawRect(panelRect, Paint()..shader = bgGradient);

    // Top edge glow
    _drawGlowingLine(canvas, 0, screenHeight - bottomBarHeight + 2, screenWidth, screenHeight - bottomBarHeight + 2, const Color(0xFF00FFFF), 0.5);

    // Hexagonal accents
    _drawHexPattern(canvas, 10, screenHeight - bottomBarHeight + 10, 3, 0.1);
    _drawHexPattern(canvas, screenWidth - 50, screenHeight - bottomBarHeight + 10, 3, 0.1);

    // Tower info panel (left side)
    _drawTowerInfoPanel(canvas, screenHeight);

    // Ability cooldowns (right side)
    _drawAbilityCooldowns(canvas, screenWidth, screenHeight);

    // Cost indicators above buttons
    _drawCostIndicators(canvas, screenWidth, screenHeight);
  }

  void _drawTowerInfoPanel(Canvas canvas, double screenHeight) {
    final selected = gameRef.towerManager.selectedTowerType;
    final panelY = screenHeight - bottomBarHeight + 8;

    // Panel background
    final panelRect = Rect.fromLTWH(15, panelY, 180, 25);
    final panelGradient = LinearGradient(
      colors: [
        selected.color.withOpacity(0.1),
        const Color(0xFF0a0a14).withOpacity(0.8),
      ],
    ).createShader(panelRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(3)),
      Paint()..shader = panelGradient,
    );

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(3)),
      Paint()
        ..color = selected.color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Tower name
    final namePainter = _towerInfoNamePainter ??
        _buildPainter(
          '>> ${selected.name.toUpperCase()}',
          TextStyle(
            color: selected.color,
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            shadows: [Shadow(color: selected.color.withOpacity(0.6), blurRadius: 6)],
          ),
        );
    namePainter.paint(canvas, Offset(22, panelY + 6));

    // Stats
    final statsText =
        'DMG:${selected.damage.toInt()} RNG:${selected.range.toInt()} SPD:${selected.fireRate.toStringAsFixed(1)}';
    final statsPainter = _towerInfoStatsPainter ??
        _buildPainter(
          statsText,
          TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 8,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
        );
    statsPainter.paint(canvas, Offset(100, panelY + 8));
  }

  void _drawAbilityCooldowns(Canvas canvas, double screenWidth, double screenHeight) {
    final barY = screenHeight - bottomBarHeight + 8;
    const barWidth = 85.0;
    const barHeight = 22.0;
    const spacing = 6.0;

    // Pulse cooldown
    _drawCooldownBar(
      canvas,
      x: screenWidth - 195,
      y: barY,
      width: barWidth,
      height: barHeight,
      ready: gameRef.pulseReady,
      progress: gameRef.pulseReady ? 1.0 : (1.0 - gameRef.pulseCooldownPercent),
      color: const Color(0xFF00FFFF),
      label: 'PULSE',
      hotkey: '[SPACE]',
    );

    // Mine cooldown
    _drawCooldownBar(
      canvas,
      x: screenWidth - 195 + barWidth + spacing,
      y: barY,
      width: barWidth,
      height: barHeight,
      ready: gameRef.mineReady,
      progress: gameRef.mineReady ? 1.0 : (1.0 - gameRef.mineCooldownPercent),
      color: const Color(0xFFFF0066),
      label: 'MINE',
      hotkey: '[M]',
      count: '${gameRef.activeMineCount}/${BoredGamesGame.maxActiveMines}',
    );
  }

  void _drawCooldownBar(
    Canvas canvas, {
    required double x,
    required double y,
    required double width,
    required double height,
    required bool ready,
    required double progress,
    required Color color,
    required String label,
    required String hotkey,
    String? count,
  }) {
    // Background
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRect, Paint()..color = const Color(0xFF0a0a18));

    // Progress fill
    if (progress > 0) {
      final progressColor = ready
          ? color
          : Color.lerp(const Color(0xFF1a1a3a), color, progress)!;

      final progressRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 2, y + 2, (width - 4) * progress, height - 4),
        const Radius.circular(2),
      );

      // Glow effect when ready
      if (ready) {
        canvas.drawRRect(
          progressRect,
          Paint()
            ..color = progressColor.withOpacity(0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }

      canvas.drawRRect(progressRect, Paint()..color = progressColor.withOpacity(0.8));

      // Animated highlight
      if (ready && !reduceFlicker) {
        final highlightX = x + 2 + ((_time * 80) % width);
        final highlightGradient = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.3),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(highlightX - 15, y, 30, height));

        canvas.save();
        canvas.clipRRect(progressRect);
        canvas.drawRect(Rect.fromLTWH(highlightX - 15, y, 30, height), Paint()..shader = highlightGradient);
        canvas.restore();
      }
    }

    // Border
    final borderPaint = Paint()
      ..color = (ready ? color : const Color(0xFF333355)).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(bgRect, borderPaint);

    // Label + hotkey or count
    final displayText = count != null && ready
        ? '$label $count'
        : (ready ? '$label $hotkey' : '${(progress * 100).toInt()}%');

    final labelPainter = _getPainter(
      'cooldown-$label',
      displayText,
      TextStyle(
        color: ready ? Colors.white : Colors.white.withOpacity(0.5),
        fontSize: 8,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        shadows: ready
            ? [Shadow(color: color, blurRadius: 6)]
            : null,
      ),
    );

    labelPainter.paint(
      canvas,
      Offset(x + (width - labelPainter.width) / 2, y + (height - labelPainter.height) / 2),
    );
  }

  void _drawCostIndicators(Canvas canvas, double screenWidth, double screenHeight) {
    final bottomY = screenHeight - bottomBarHeight + 35;
    const buttonWidth = 100.0;
    const abilityWidth = 110.0;
    const mineWidth = 90.0;
    const waveWidth = 100.0;
    final totalWidth = 4 * buttonWidth + abilityWidth + mineWidth + waveWidth + 6 * buttonSpacing;
    final startX = (screenWidth - totalWidth) / 2;

    final costs = [
      (TowerType.pulseArcher.cost, TowerType.pulseArcher.color),
      (TowerType.circuitCannon.cost, TowerType.circuitCannon.color),
      (TowerType.phaseMage.cost, TowerType.phaseMage.color),
      (TowerType.glimmerField.cost, TowerType.glimmerField.color),
    ];

    for (int i = 0; i < costs.length; i++) {
      final x = startX + i * (buttonWidth + buttonSpacing) + buttonWidth / 2;
      final canAfford = gameRef.gold >= costs[i].$1;

      final costColor = canAfford
          ? costs[i].$2.withOpacity(0.9)
          : const Color(0xFFFF4444).withOpacity(0.7);
      final costKey = 'cost-${costs[i].$1}-${costColor.value}';
      final costPainter = _getPainter(
        costKey,
        '${costs[i].$1}g',
        TextStyle(
          color: costColor,
          fontSize: 10,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          shadows: canAfford
              ? [Shadow(color: costs[i].$2.withOpacity(0.5), blurRadius: 4)]
              : null,
        ),
      );

      costPainter.paint(canvas, Offset(x - costPainter.width / 2, bottomY - 14));
    }

    // Pulse cost
    final pulseX = startX + 4 * (buttonWidth + buttonSpacing) + abilityWidth / 2;
    final canAffordPulse = gameRef.gold >= BoredGamesGame.pulseCost && gameRef.pulseReady;
    final pulseColor = canAffordPulse
        ? const Color(0xFF00FFFF).withOpacity(0.9)
        : const Color(0xFFFF4444).withOpacity(0.7);
    final pulseKey = 'cost-pulse-${pulseColor.value}';
    final pulseCostPainter = _getPainter(
      pulseKey,
      '${BoredGamesGame.pulseCost}g',
      TextStyle(
        color: pulseColor,
        fontSize: 10,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
      ),
    );
    pulseCostPainter.paint(canvas, Offset(pulseX - pulseCostPainter.width / 2, bottomY - 14));

    // Mine cost
    final mineX = startX + 4 * (buttonWidth + buttonSpacing) + abilityWidth + buttonSpacing + mineWidth / 2;
    final canAffordMine = gameRef.gold >= BoredGamesGame.mineCost && gameRef.mineReady;
    final mineColor = canAffordMine
        ? const Color(0xFFFF0066).withOpacity(0.9)
        : const Color(0xFFFF4444).withOpacity(0.7);
    final mineKey = 'cost-mine-${mineColor.value}';
    final mineCostPainter = _getPainter(
      mineKey,
      '${BoredGamesGame.mineCost}g',
      TextStyle(
        color: mineColor,
        fontSize: 10,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
      ),
    );
    mineCostPainter.paint(canvas, Offset(mineX - mineCostPainter.width / 2, bottomY - 14));
  }

  void _drawGlowingLine(Canvas canvas, double x1, double y1, double x2, double y2, Color color, double intensity) {
    // Outer glow
    canvas.drawLine(
      Offset(x1, y1),
      Offset(x2, y2),
      Paint()
        ..color = color.withOpacity(intensity * 0.3)
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Core line
    canvas.drawLine(
      Offset(x1, y1),
      Offset(x2, y2),
      Paint()
        ..color = color.withOpacity(intensity)
        ..strokeWidth = 1,
    );
  }

  void _drawHexPattern(Canvas canvas, double x, double y, int count, double alpha) {
    final hexPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const hexSize = 8.0;
    for (int i = 0; i < count; i++) {
      for (int j = 0; j < 2; j++) {
        final offsetX = x + i * hexSize * 1.5;
        final offsetY = y + j * hexSize * 0.866 + (i % 2) * hexSize * 0.433;
        _drawHexagon(canvas, Offset(offsetX, offsetY), hexSize * 0.4, hexPaint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _updateSelectionCache(TowerType selected) {
    if (_lastSelected == selected &&
        _selectionNamePainter != null &&
        _selectionStatsPainter != null &&
        _towerInfoNamePainter != null &&
        _towerInfoStatsPainter != null) {
      return;
    }

    _lastSelected = selected;
    _selectionNamePainter = _buildPainter(
      selected.name.toUpperCase(),
      TextStyle(
        color: selected.color,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
    _selectionStatsPainter = _buildPainter(
      'DMG ${selected.damage.toInt()}    RNG ${selected.range.toInt()}    SPD ${selected.fireRate.toStringAsFixed(1)}',
      TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 12,
        letterSpacing: 0.5,
      ),
    );
    _towerInfoNamePainter = _buildPainter(
      '>> ${selected.name.toUpperCase()}',
      TextStyle(
        color: selected.color,
        fontSize: 11,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        shadows: [Shadow(color: selected.color.withOpacity(0.6), blurRadius: 6)],
      ),
    );
    _towerInfoStatsPainter = _buildPainter(
      'DMG:${selected.damage.toInt()} RNG:${selected.range.toInt()} SPD:${selected.fireRate.toStringAsFixed(1)}',
      TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 8,
        fontFamily: 'monospace',
        letterSpacing: 0.5,
      ),
    );
  }

  void _updateResourceCache() {
    final gold = gameRef.gold;
    final lives = gameRef.lives;
    final score = gameRef.score;
    final wave = gameRef.enemyManager.currentWave;
    final enemies = gameRef.enemyManager.aliveCount;
    final towers = gameRef.towerManager.towers.length;

    if (gold != _lastGold) {
      _getPainter('value-GOLD', '$gold', _resourceValueStyle(const Color(0xFFFFD700)));
      _lastGold = gold;
    }
    if (lives != _lastLives) {
      _getPainter('value-LIVES', '$lives', _resourceValueStyle(const Color(0xFFFF4466)));
      _lastLives = lives;
    }
    if (score != _lastScore) {
      _getPainter('value-SCORE', '$score', _resourceValueStyle(const Color(0xFF00FF88)));
      _lastScore = score;
    }
    if (wave != _lastWave) {
      _getPainter('value-WAVE', '$wave', _resourceValueStyle(const Color(0xFFFF00FF)));
      _lastWave = wave;
    }
    if (enemies != _lastEnemies) {
      _getPainter('value-ENEMIES', '$enemies', _resourceValueStyle(const Color(0xFFFF6644)));
      _lastEnemies = enemies;
    }
    if (towers != _lastTowers) {
      _getPainter('value-TOWERS', '$towers', _resourceValueStyle(const Color(0xFF44AAFF)));
      _lastTowers = towers;
    }
  }

  TextStyle _resourceValueStyle(Color color) {
    return TextStyle(
      color: color,
      fontSize: 18,
      fontFamily: 'monospace',
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
      shadows: [
        Shadow(color: color.withOpacity(0.8), blurRadius: 8),
      ],
    );
  }

  TextPainter _getPainter(String key, String text, TextStyle style) {
    final cached = _textCache[key];
    if (cached != null && cached.text == text) {
      return cached.painter;
    }
    final painter = _buildPainter(text, style);
    _textCache[key] = _TextCache(text, painter);
    return painter;
  }

  TextPainter _buildPainter(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter;
  }
}

class _TextCache {
  _TextCache(this.text, this.painter);

  final String text;
  final TextPainter painter;
}

