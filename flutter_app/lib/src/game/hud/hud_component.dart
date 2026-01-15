import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../bored_games_game.dart';
import '../entities/tower.dart';
import '../../ui/theme/neon_theme.dart';
import 'hud_button.dart';
import 'boss_health_bar.dart';

/// Professional HUD with cyberpunk aesthetic
class HudComponent extends PositionComponent with HasGameRef<BoredGamesGame> {
  // Button references for state updates
  late HudButton pulseArcherBtn;
  late HudButton circuitCannonBtn;
  late HudButton phaseMageBtn;
  late HudButton glimmerFieldBtn;
  late HudButton pulseAbilityBtn;
  late HudButton mineAbilityBtn;
  late HudButton sellButton;
  late HudButton upgradeButton;
  late HudButton waveButton;

  double _time = 0;
  final Map<String, _TextCache> _textCache = {};
  TextPainter? _instructionPainter;
  String _instructionText = '';
  TowerType? _lastSelected;
  TextPainter? _selectionNamePainter;
  TextPainter? _selectionStatsPainter;
  TextPainter? _towerInfoNamePainter;
  TextPainter? _towerInfoStatsPainter;
  int _selectionCacheKey = 0;
  int _lastGold = -1;
  int _lastLives = -1;
  int _lastScore = -1;
  int _lastWave = -1;
  int _lastEnemies = -1;
  int _lastTowers = -1;
  Rect? _topPanelRect;
  Shader? _topPanelShader;
  Rect? _bottomPanelRect;
  Shader? _bottomPanelShader;
  Rect? _towerInfoRect;
  TowerType? _towerInfoType;
  Shader? _towerInfoShader;
  final Map<int, _CardShaderCache> _resourceCardShaders = {};
  Path? _hexagonPath;
  double _hexagonRadius = 0;
  final Paint _panelPaint = Paint();
  final Paint _towerInfoPanelPaint = Paint();
  final Paint _resourceCardPaint = Paint();
  final Paint _resourceCardBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Paint _towerInfoBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Paint _resourceCardAccentPaint = Paint()
    ..strokeWidth = 2;
  final Paint _resourceCardDotGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  final Paint _resourceCardDotCorePaint = Paint();
  final Paint _selectionGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  final Paint _selectionBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final Paint _progressBarBackPaint = Paint()..color = const Color(0xFF0a0a18);
  final Paint _progressBarBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Paint _progressBarFillPaint = Paint();
  final Paint _progressBarGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  final Paint _glowLineOuterPaint = Paint()
    ..strokeWidth = 6
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  final Paint _glowLineCorePaint = Paint()
    ..strokeWidth = 1;
  final Paint _hexPatternPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;

  double _layoutButtonWidth = 100.0;
  double _layoutAbilityWidth = 110.0;
  double _layoutMineWidth = 90.0;
  double _layoutSellWidth = 90.0;
  double _layoutUpgradeWidth = 110.0;
  double _layoutWaveWidth = 100.0;
  double _layoutSpacing = buttonSpacing;
  double _layoutStartX = 0.0;
  double _layoutRow1StartX = 0.0;
  double _layoutRow2StartX = 0.0;
  double _layoutRow1Y = 0.0;
  double _layoutRow2Y = 0.0;
  double _layoutSingleRowY = 0.0;
  bool _layoutTwoRows = false;
  BossHealthBar? _bossHealthBar;

  // Layout constants
  static double topBarHeight = 60.0;
  static double bottomBarHeight = 100.0;
  static double buttonHeight = 44.0;
  static double buttonSpacing = 12.0;
  static const bool reduceFlicker = true;

  static void applyLayoutMetrics({
    required double width,
    required double height,
    required bool compact,
  }) {
    final verticalTight = height < 700;
    if (compact || verticalTight) {
      topBarHeight = compact ? 70.0 : 60.0;
      buttonHeight = compact ? 38.0 : 40.0;
      buttonSpacing = compact ? 10.0 : 11.0;
    } else {
      topBarHeight = 60.0;
      buttonHeight = 44.0;
      buttonSpacing = 12.0;
    }

    final twoRows = width < 780;
    final rowSpacing = compact ? 8.0 : 10.0;
    final minBottom = twoRows
        ? (buttonHeight * 2 + rowSpacing + 22)
        : (buttonHeight + 46);
    bottomBarHeight = math.max(compact ? 90.0 : 100.0, minBottom);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    priority = 100;

    // Initialize boss health bar
    _bossHealthBar = BossHealthBar(
      screenWidth: gameRef.size.x,
      screenHeight: gameRef.size.y,
    );
    add(_bossHealthBar!);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _invalidateLayoutCaches();
    _repositionButtons();
  }

  bool _isCompactHud(double width, double height) {
    return gameRef.isTouchLayout || width < 820 || height < 560;
  }

  bool _useTwoRowLayout(double width) => width < 780;

  void _repositionButtons() {
    children.whereType<HudButton>().toList().forEach((b) => b.removeFromParent());

    final screenWidth = gameRef.size.x;
    final screenHeight = gameRef.size.y;
    final compact = _isCompactHud(screenWidth, screenHeight);
    applyLayoutMetrics(
      width: screenWidth,
      height: screenHeight,
      compact: compact,
    );
    final bottomBarTop = screenHeight - bottomBarHeight;
    final useTwoRows = _useTwoRowLayout(screenWidth);
    _layoutTwoRows = useTwoRows;

    // Tower buttons - centered with better spacing
    const baseButtonWidth = 100.0;
    const baseAbilityWidth = 110.0;
    const baseMineWidth = 90.0;
    const baseSellWidth = 90.0;
    const baseUpgradeWidth = 110.0;
    const baseWaveWidth = 100.0;
    final availableWidth = screenWidth - 24;
    final baseSpacing = buttonSpacing;
    final row1Width =
        4 * baseButtonWidth + 3 * baseSpacing;
    final row2Width =
        baseAbilityWidth +
        baseMineWidth +
        baseSellWidth +
        baseUpgradeWidth +
        baseWaveWidth +
        4 * baseSpacing;
    final baseTotalWidth =
        4 * baseButtonWidth +
        baseAbilityWidth +
        baseMineWidth +
        baseSellWidth +
        baseUpgradeWidth +
        baseWaveWidth +
        8 * baseSpacing;
    final targetWidth = useTwoRows ? math.max(row1Width, row2Width) : baseTotalWidth;
    final scale = (availableWidth / targetWidth).clamp(0.64, 1.0);
    _layoutButtonWidth = baseButtonWidth * scale;
    _layoutAbilityWidth = baseAbilityWidth * scale;
    _layoutMineWidth = baseMineWidth * scale;
    _layoutSellWidth = baseSellWidth * scale;
    _layoutUpgradeWidth = baseUpgradeWidth * scale;
    _layoutWaveWidth = baseWaveWidth * scale;
    _layoutSpacing = baseSpacing * scale;

    if (useTwoRows) {
      final rowSpacing = compact ? 8.0 : 10.0;
      final rowsHeight = buttonHeight * 2 + rowSpacing;
      _layoutRow1Y = bottomBarTop + (bottomBarHeight - rowsHeight) / 2;
      _layoutRow2Y = _layoutRow1Y + buttonHeight + rowSpacing;
      final row1Total =
          4 * _layoutButtonWidth + 3 * _layoutSpacing;
      final row2Total =
          _layoutAbilityWidth +
          _layoutMineWidth +
          _layoutSellWidth +
          _layoutUpgradeWidth +
          _layoutWaveWidth +
          4 * _layoutSpacing;
      _layoutRow1StartX = math.max(8.0, (screenWidth - row1Total) / 2);
      _layoutRow2StartX = math.max(8.0, (screenWidth - row2Total) / 2);
    } else {
      final totalWidth =
          4 * _layoutButtonWidth +
          _layoutAbilityWidth +
          _layoutMineWidth +
          _layoutSellWidth +
          _layoutUpgradeWidth +
          _layoutWaveWidth +
          8 * _layoutSpacing;
      _layoutStartX = math.max(8.0, (screenWidth - totalWidth) / 2);
      _layoutSingleRowY = bottomBarTop + (bottomBarHeight - buttonHeight) / 2;
    }

    pulseArcherBtn = HudButton(
      label: 'ARCHER',
      position: Vector2(
        useTwoRows ? _layoutRow1StartX : _layoutStartX,
        useTwoRows ? _layoutRow1Y : _layoutSingleRowY,
      ),
      size: Vector2(_layoutButtonWidth, buttonHeight),
      color: TowerType.pulseArcher.color,
      isSelected: true,
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.towerManager.setSelectedTowerType(TowerType.pulseArcher),
    );

    circuitCannonBtn = HudButton(
      label: 'CANNON',
      position: Vector2(
        (useTwoRows ? _layoutRow1StartX : _layoutStartX) +
            _layoutButtonWidth +
            _layoutSpacing,
        useTwoRows ? _layoutRow1Y : _layoutSingleRowY,
      ),
      size: Vector2(_layoutButtonWidth, buttonHeight),
      color: TowerType.circuitCannon.color,
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.towerManager.setSelectedTowerType(TowerType.circuitCannon),
    );

    phaseMageBtn = HudButton(
      label: 'MAGE',
      position: Vector2(
        (useTwoRows ? _layoutRow1StartX : _layoutStartX) +
            2 * (_layoutButtonWidth + _layoutSpacing),
        useTwoRows ? _layoutRow1Y : _layoutSingleRowY,
      ),
      size: Vector2(_layoutButtonWidth, buttonHeight),
      color: TowerType.phaseMage.color,
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.towerManager.setSelectedTowerType(TowerType.phaseMage),
    );

    glimmerFieldBtn = HudButton(
      label: 'GLIMMER',
      position: Vector2(
        (useTwoRows ? _layoutRow1StartX : _layoutStartX) +
            3 * (_layoutButtonWidth + _layoutSpacing),
        useTwoRows ? _layoutRow1Y : _layoutSingleRowY,
      ),
      size: Vector2(_layoutButtonWidth, buttonHeight),
      color: TowerType.glimmerField.color,
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.towerManager.setSelectedTowerType(TowerType.glimmerField),
    );

    pulseAbilityBtn = HudButton(
      label: 'PULSE',
      position: Vector2(
        useTwoRows
            ? _layoutRow2StartX
            : _layoutStartX + 4 * (_layoutButtonWidth + _layoutSpacing),
        useTwoRows ? _layoutRow2Y : _layoutSingleRowY,
      ),
      size: Vector2(_layoutAbilityWidth, buttonHeight),
      color: const Color(0xFF00FFFF),
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.activateNeonPulse(),
    );

    mineAbilityBtn = HudButton(
      label: 'MINE',
      position: Vector2(
        useTwoRows
            ? _layoutRow2StartX + _layoutAbilityWidth + _layoutSpacing
            : _layoutStartX +
                4 * (_layoutButtonWidth + _layoutSpacing) +
                _layoutAbilityWidth +
                _layoutSpacing,
        useTwoRows ? _layoutRow2Y : _layoutSingleRowY,
      ),
      size: Vector2(_layoutMineWidth, buttonHeight),
      color: const Color(0xFFFF0066),
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.deployMine(),
    );

    sellButton = HudButton(
      label: 'SELL',
      position: Vector2(
        useTwoRows
            ? _layoutRow2StartX +
                _layoutAbilityWidth +
                _layoutMineWidth +
                2 * _layoutSpacing
            : _layoutStartX +
                4 * (_layoutButtonWidth + _layoutSpacing) +
                _layoutAbilityWidth +
                _layoutMineWidth +
                2 * _layoutSpacing,
        useTwoRows ? _layoutRow2Y : _layoutSingleRowY,
      ),
      size: Vector2(_layoutSellWidth, buttonHeight),
      color: const Color(0xFFFFAA00),
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.toggleSellMode(),
    );

    upgradeButton = HudButton(
      label: 'UPGRADE',
      position: Vector2(
        useTwoRows
            ? _layoutRow2StartX +
                _layoutAbilityWidth +
                _layoutMineWidth +
                _layoutSellWidth +
                3 * _layoutSpacing
            : _layoutStartX +
                4 * (_layoutButtonWidth + _layoutSpacing) +
                _layoutAbilityWidth +
                _layoutMineWidth +
                _layoutSellWidth +
                3 * _layoutSpacing,
        useTwoRows ? _layoutRow2Y : _layoutSingleRowY,
      ),
      size: Vector2(_layoutUpgradeWidth, buttonHeight),
      color: NeonColors.purple,
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.toggleRunUpgradeOverlay(),
    );

    waveButton = HudButton(
      label: 'START WAVE',
      position: Vector2(
        useTwoRows
            ? _layoutRow2StartX +
                _layoutAbilityWidth +
                _layoutMineWidth +
                _layoutSellWidth +
                _layoutUpgradeWidth +
                4 * _layoutSpacing
            : _layoutStartX +
                4 * (_layoutButtonWidth + _layoutSpacing) +
                _layoutAbilityWidth +
                _layoutMineWidth +
                _layoutSellWidth +
                _layoutUpgradeWidth +
                4 * _layoutSpacing,
        useTwoRows ? _layoutRow2Y : _layoutSingleRowY,
      ),
      size: Vector2(_layoutWaveWidth, buttonHeight),
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
      sellButton,
      upgradeButton,
      waveButton,
    ]);
  }

  void _invalidateLayoutCaches() {
    _topPanelRect = null;
    _topPanelShader = null;
    _bottomPanelRect = null;
    _bottomPanelShader = null;
    _towerInfoRect = null;
    _towerInfoShader = null;
    _resourceCardShaders.clear();
    _instructionPainter = null;
    _instructionText = '';
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
    pulseAbilityBtn.isSelected =
        gameRef.pendingAbility == PendingAbility.pulse;
    mineAbilityBtn.isSelected =
        gameRef.pendingAbility == PendingAbility.mine;
    sellButton.enabled = gameRef.towerManager.towers.isNotEmpty;
    sellButton.isSelected = gameRef.sellMode;
    upgradeButton.isSelected =
        gameRef.awaitingUpgradeChoice || gameRef.upgradeOverlayActive;
    _updateSelectionCache(selected);
    _updateResourceCache();

    // Update boss health bar
    _bossHealthBar?.setBoss(gameRef.enemyManager.currentBoss);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final screenWidth = gameRef.size.x;
    final screenHeight = gameRef.size.y;

    _drawTopPanel(canvas, screenWidth);
    _drawBottomPanel(canvas, screenWidth, screenHeight);

    if (!_isCompactHud(screenWidth, screenHeight)) {
      _drawSelectionInfo(canvas, screenWidth);
    }

    // Instruction prompt
    final instructionText = gameRef.isTouchLayout
        ? 'Tap a tower, then drag to place it'
        : 'Select a tower and drag to place it';
    if (_instructionPainter == null || _instructionText != instructionText) {
      _instructionText = instructionText;
      _instructionPainter = _buildPainter(
        instructionText,
        const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontFamily: 'monospace',
          letterSpacing: 0.8,
        ),
      );
    }
    if (!_isCompactHud(screenWidth, screenHeight)) {
      _instructionPainter!.paint(
        canvas,
        Offset(24, screenHeight - bottomBarHeight - 26),
      );
    }

    _drawAbilityTargetHint(canvas, screenHeight);
  }

  void _drawAbilityTargetHint(Canvas canvas, double screenHeight) {
    final pending = gameRef.pendingAbility;
    if (pending == PendingAbility.none) return;

    final isTouch = gameRef.isTouchLayout;
    final label = switch (pending) {
      PendingAbility.pulse =>
        isTouch ? 'TOCA EL CAMPO' : 'CLICK EL CAMPO',
      PendingAbility.mine =>
        isTouch ? 'TOCA EL CAMINO' : 'CLICK EL CAMINO',
      PendingAbility.none => '',
    };
    if (label.isEmpty) return;

    final color = pending == PendingAbility.pulse
        ? const Color(0xFF00FFFF)
        : const Color(0xFFFF0066);
    final button = pending == PendingAbility.pulse
        ? pulseAbilityBtn
        : mineAbilityBtn;

    final painter = _getPainter(
      'ability-hint-$label-${isTouch ? 't' : 'd'}',
      label,
      TextStyle(
        color: color,
        fontSize: 9,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 6)],
      ),
    );

    final x = button.position.x + (button.size.x - painter.width) / 2;
    final y = math.max(
      button.position.y - painter.height - 6,
      screenHeight - bottomBarHeight + 6,
    );
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x - 6, y - 2, painter.width + 12, painter.height + 4),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = Colors.black.withOpacity(0.6),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    painter.paint(canvas, Offset(x, y));
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

    _selectionGlowPaint.color = selected.color.withOpacity(0.08);
    canvas.drawRRect(rrect, _selectionGlowPaint);

    _selectionBorderPaint.color = NeonColors.gridLine.withOpacity(0.4);
    canvas.drawRRect(rrect, _selectionBorderPaint);

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

    final damage = gameRef.towerDamage(selected).round();
    final range = gameRef.towerRange(selected).round();
    final fireRate = gameRef.towerFireRate(selected);
    final statsText =
        'DMG $damage    RNG $range    SPD ${fireRate.toStringAsFixed(1)}';
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
    final compact = _isCompactHud(screenWidth, gameRef.size.y);
    // Main panel background
    final panelRect = Rect.fromLTWH(0, 0, screenWidth, topBarHeight);

    // Multi-layer background
    _panelPaint.shader = _getTopPanelShader(panelRect);
    canvas.drawRect(panelRect, _panelPaint);

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
    if (!compact) {
      _drawCenterLogo(canvas, screenWidth);
    }

    // Progress bars
    if (!compact) {
      _drawProgressBars(canvas, screenWidth);
    }

    // Wave alert (if active)
    _drawWaveAlert(canvas, screenWidth);
  }

  void _drawResourcePanels(Canvas canvas, double screenWidth) {
    final compact = _isCompactHud(screenWidth, gameRef.size.y);
    if (compact) {
      const gap = 6.0;
      final cardWidth = ((screenWidth - 32 - gap * 2) / 3).clamp(72.0, 110.0);
      const cardHeight = 32.0;
      const startX = 16.0;
      const rowY = 6.0;
      final row2Y = rowY + cardHeight + 6;
      _drawResourceCard(
        canvas,
        startX,
        rowY,
        'GOLD',
        '${gameRef.gold}',
        const Color(0xFFFFD700),
        0,
        width: cardWidth,
        height: cardHeight,
        compact: true,
      );
      _drawResourceCard(
        canvas,
        startX + cardWidth + gap,
        rowY,
        'LIVES',
        '${gameRef.lives}',
        const Color(0xFFFF4466),
        1,
        width: cardWidth,
        height: cardHeight,
        compact: true,
      );
      _drawResourceCard(
        canvas,
        startX + (cardWidth + gap) * 2,
        rowY,
        'SCORE',
        '${gameRef.score}',
        const Color(0xFF00FF88),
        2,
        width: cardWidth,
        height: cardHeight,
        compact: true,
      );
      _drawResourceCard(
        canvas,
        startX,
        row2Y,
        'WAVE',
        '${gameRef.enemyManager.currentWave}',
        const Color(0xFFFF00FF),
        3,
        width: cardWidth,
        height: cardHeight,
        compact: true,
      );
      _drawResourceCard(
        canvas,
        startX + cardWidth + gap,
        row2Y,
        'ENEMIES',
        '${gameRef.enemyManager.aliveCount}',
        const Color(0xFFFF6644),
        4,
        width: cardWidth,
        height: cardHeight,
        compact: true,
      );
      _drawResourceCard(
        canvas,
        startX + (cardWidth + gap) * 2,
        row2Y,
        'TOWERS',
        '${gameRef.towerManager.towers.length}',
        const Color(0xFF44AAFF),
        5,
        width: cardWidth,
        height: cardHeight,
        compact: true,
      );
      return;
    }

    // Left side resources
    _drawResourceCard(canvas, 20, 8, 'GOLD', '${gameRef.gold}', const Color(0xFFFFD700), 0);
    _drawResourceCard(canvas, 130, 8, 'LIVES', '${gameRef.lives}', const Color(0xFFFF4466), 1);
    _drawResourceCard(canvas, 240, 8, 'SCORE', '${gameRef.score}', const Color(0xFF00FF88), 2);

    // Right side resources
    _drawResourceCard(canvas, screenWidth - 340, 8, 'WAVE', '${gameRef.enemyManager.currentWave}', const Color(0xFFFF00FF), 3);
    _drawResourceCard(canvas, screenWidth - 230, 8, 'ENEMIES', '${gameRef.enemyManager.aliveCount}', const Color(0xFFFF6644), 4);
    _drawResourceCard(canvas, screenWidth - 120, 8, 'TOWERS', '${gameRef.towerManager.towers.length}', const Color(0xFF44AAFF), 5);
  }

  void _drawResourceCard(
    Canvas canvas,
    double x,
    double y,
    String label,
    String value,
    Color color,
    int index, {
    double width = 100.0,
    double height = 42.0,
    bool compact = false,
  }) {
    final cardWidth = width;
    final cardHeight = height;
    final cardRect = Rect.fromLTWH(x, y, cardWidth, cardHeight);

    final rrect = RRect.fromRectAndRadius(cardRect, const Radius.circular(4));
    _resourceCardPaint.shader = _getResourceCardShader(cardRect, color);
    canvas.drawRRect(rrect, _resourceCardPaint);

    // Animated border
    final borderAlpha = reduceFlicker
        ? 0.35
        : 0.3 + math.sin(_time * 2 + index * 0.5) * 0.1;
    _resourceCardBorderPaint.color = color.withOpacity(borderAlpha);
    canvas.drawRRect(rrect, _resourceCardBorderPaint);

    // Corner accents
    _resourceCardAccentPaint.color = color.withOpacity(0.7);

    // Top-left corner
    canvas.drawLine(Offset(x, y + 8), Offset(x, y), _resourceCardAccentPaint);
    canvas.drawLine(Offset(x, y), Offset(x + 8, y), _resourceCardAccentPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(x + cardWidth - 8, y + cardHeight), Offset(x + cardWidth, y + cardHeight), _resourceCardAccentPaint);
    canvas.drawLine(Offset(x + cardWidth, y + cardHeight - 8), Offset(x + cardWidth, y + cardHeight), _resourceCardAccentPaint);

    // Icon indicator (glowing dot)
    _resourceCardDotGlowPaint.color = color.withOpacity(0.8);
    final dotRadius = compact ? 3.5 : 5.0;
    canvas.drawCircle(Offset(x + 12, y + cardHeight / 2), dotRadius, _resourceCardDotGlowPaint);

    _resourceCardDotCorePaint.color = color;
    canvas.drawCircle(Offset(x + 12, y + cardHeight / 2), dotRadius * 0.6, _resourceCardDotCorePaint);

    // Label
    final labelPainter = _getPainter(
      'label-$label',
      label,
      TextStyle(
        color: color.withOpacity(0.7),
        fontSize: compact ? 7 : 9,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
      ),
    );
    labelPainter.paint(canvas, Offset(x + 22, y + (compact ? 4 : 6)));

    final valuePainter = _getPainter(
      'value-$label',
      value,
      TextStyle(
        color: color,
        fontSize: compact ? 14 : 18,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        shadows: [
          Shadow(color: color.withOpacity(0.8), blurRadius: 8),
        ],
      ),
    );
    valuePainter.paint(canvas, Offset(x + 22, y + (compact ? 14 : 20)));
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

  void _drawProgressBars(Canvas canvas, double screenWidth) {
    if (_isCompactHud(screenWidth, gameRef.size.y)) return;
    final leftEdge = 340.0;
    final rightEdge = screenWidth - 340.0;
    final available = rightEdge - leftEdge;
    if (available < 160) return;

    final barWidth = math.min(260.0, available - 20);
    final startX = (screenWidth - barWidth) / 2;
    const barHeight = 8.0;
    const spacing = 6.0;
    const labelGap = 6.0;

    final totalWaves = gameRef.totalWaves <= 0 ? 1 : gameRef.totalWaves;
    final currentWave = gameRef.enemyManager.currentWave;
    final waveProgress = gameRef.enemyManager.waveProgress.clamp(0.0, 1.0);
    final waveActive = gameRef.enemyManager.spawning || gameRef.enemyManager.aliveCount > 0;
    double levelProgress = 0.0;
    if (currentWave > 0) {
      final completed = waveActive ? (currentWave - 1 + waveProgress) : currentWave.toDouble();
      levelProgress = (completed / totalWaves).clamp(0.0, 1.0);
    }

    final levelLabel = _getPainter(
      'progress-level-label',
      'LEVEL',
      TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 9,
        fontFamily: 'monospace',
        letterSpacing: 1.2,
      ),
    );
    final levelValue = _getPainter(
      'progress-level-value-$currentWave-$totalWaves',
      '$currentWave/$totalWaves',
      TextStyle(
        color: const Color(0xFF00FFFF),
        fontSize: 9,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );

    final waveLabel = _getPainter(
      'progress-wave-label',
      'WAVE',
      TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 9,
        fontFamily: 'monospace',
        letterSpacing: 1.2,
      ),
    );
    final wavePercent = (waveProgress * 100).round();
    final waveValue = _getPainter(
      'progress-wave-value-$wavePercent',
      '$wavePercent%',
      TextStyle(
        color: const Color(0xFFFF00FF),
        fontSize: 9,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );

    final levelY = 10.0;
    final waveY = levelY + barHeight + spacing + 12;

    _drawProgressBar(
      canvas,
      x: startX,
      y: levelY,
      width: barWidth,
      height: barHeight,
      progress: levelProgress,
      color: const Color(0xFF00FFFF),
    );

    _drawProgressBar(
      canvas,
      x: startX,
      y: waveY,
      width: barWidth,
      height: barHeight,
      progress: waveProgress,
      color: const Color(0xFFFF00FF),
    );

    // Labels
    levelLabel.paint(canvas, Offset(startX - levelLabel.width - labelGap, levelY - 3));
    levelValue.paint(canvas, Offset(startX + barWidth + labelGap, levelY - 3));
    waveLabel.paint(canvas, Offset(startX - waveLabel.width - labelGap, waveY - 3));
    waveValue.paint(canvas, Offset(startX + barWidth + labelGap, waveY - 3));
  }

  void _drawProgressBar(
    Canvas canvas, {
    required double x,
    required double y,
    required double width,
    required double height,
    required double progress,
    required Color color,
  }) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, _progressBarBackPaint);

    if (progress > 0) {
      final fillWidth = (width - 2) * progress;
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 1, y + 1, fillWidth, height - 2),
        const Radius.circular(3),
      );
      _progressBarGlowPaint.color = color.withOpacity(0.35);
      canvas.drawRRect(fillRect, _progressBarGlowPaint);

      _progressBarFillPaint.color = color.withOpacity(0.7);
      canvas.drawRRect(fillRect, _progressBarFillPaint);
    }

    _progressBarBorderPaint.color = color.withOpacity(0.5);
    canvas.drawRRect(rect, _progressBarBorderPaint);
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
    _panelPaint.shader = _getBottomPanelShader(panelRect);
    canvas.drawRect(panelRect, _panelPaint);

    // Top edge glow
    _drawGlowingLine(canvas, 0, screenHeight - bottomBarHeight + 2, screenWidth, screenHeight - bottomBarHeight + 2, const Color(0xFF00FFFF), 0.5);

    // Hexagonal accents
    _drawHexPattern(canvas, 10, screenHeight - bottomBarHeight + 10, 3, 0.1);
    _drawHexPattern(canvas, screenWidth - 50, screenHeight - bottomBarHeight + 10, 3, 0.1);

    if (!_isCompactHud(screenWidth, screenHeight)) {
      // Tower info panel (left side)
      _drawTowerInfoPanel(canvas, screenHeight);

      // Ability cooldowns (right side)
      _drawAbilityCooldowns(canvas, screenWidth, screenHeight);
    }

    // Cost indicators above buttons
    _drawCostIndicators(canvas, screenWidth, screenHeight);
  }

  void _drawTowerInfoPanel(Canvas canvas, double screenHeight) {
    final selected = gameRef.towerManager.selectedTowerType;
    final panelY = screenHeight - bottomBarHeight + 8;

    // Panel background
    final panelRect = Rect.fromLTWH(15, panelY, 180, 25);
    _towerInfoPanelPaint.shader = _getTowerInfoShader(panelRect, selected);
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(3)),
      _towerInfoPanelPaint,
    );

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(3)),
      _towerInfoBorderPaint..color = selected.color.withOpacity(0.4),
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
    final damage = gameRef.towerDamage(selected).round();
    final range = gameRef.towerRange(selected).round();
    final fireRate = gameRef.towerFireRate(selected);
    final statsText =
        'DMG:$damage RNG:$range SPD:${fireRate.toStringAsFixed(1)}';
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
    if (_isCompactHud(screenWidth, screenHeight)) return;
    final barY = screenHeight - bottomBarHeight + 8;
    const barWidth = 85.0;
    const barHeight = 22.0;
    const spacing = 6.0;
    final showHotkeys = _shouldShowHotkeys();

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
      hotkey: showHotkeys ? '[SPACE]' : '',
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
      hotkey: showHotkeys ? '[M]' : '',
      count: '${gameRef.activeMineCount}/${gameRef.maxActiveMines}',
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
    final hotkeyText = hotkey.isEmpty ? '' : ' $hotkey';
    final displayText = count != null && ready
        ? '$label $count'
        : (ready ? '$label$hotkeyText' : '${(progress * 100).toInt()}%');

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

  bool _shouldShowHotkeys() {
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      return false;
    }
    if (kIsWeb) {
      return gameRef.size.x >= 820 && gameRef.size.y >= 520;
    }
    return true;
  }

  void _drawCostIndicators(Canvas canvas, double screenWidth, double screenHeight) {
    final useTwoRows = _layoutTwoRows;
    final buttonWidth = _layoutButtonWidth;
    final abilityWidth = _layoutAbilityWidth;
    final mineWidth = _layoutMineWidth;
    final spacing = _layoutSpacing;
    final fontSize = useTwoRows ? 9.0 : 10.0;
    final row1BaseY = useTwoRows ? _layoutRow1Y : _layoutSingleRowY;
    final row2BaseY = useTwoRows ? _layoutRow2Y : _layoutSingleRowY;
    final row1CostY = row1BaseY - 12;
    final row2CostY = row2BaseY - 12;
    final totalWidth = 4 * buttonWidth +
        abilityWidth +
        mineWidth +
        _layoutSellWidth +
        _layoutUpgradeWidth +
        _layoutWaveWidth +
        8 * spacing;
    final startX = useTwoRows
        ? _layoutRow1StartX
        : (_layoutStartX == 0.0
            ? math.max(8.0, (screenWidth - totalWidth) / 2)
            : _layoutStartX);

    final costs = [
      (gameRef.towerCost(TowerType.pulseArcher), TowerType.pulseArcher.color),
      (gameRef.towerCost(TowerType.circuitCannon), TowerType.circuitCannon.color),
      (gameRef.towerCost(TowerType.phaseMage), TowerType.phaseMage.color),
      (gameRef.towerCost(TowerType.glimmerField), TowerType.glimmerField.color),
    ];

    for (int i = 0; i < costs.length; i++) {
      final x = startX + i * (buttonWidth + spacing) + buttonWidth / 2;
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
          fontSize: fontSize,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          shadows: canAfford
              ? [Shadow(color: costs[i].$2.withOpacity(0.5), blurRadius: 4)]
              : null,
        ),
      );

      costPainter.paint(canvas, Offset(x - costPainter.width / 2, row1CostY));
    }

    // Pulse cost
    final pulseX = useTwoRows
        ? _layoutRow2StartX + abilityWidth / 2
        : startX + 4 * (buttonWidth + spacing) + abilityWidth / 2;
    final canAffordPulse = gameRef.gold >= gameRef.pulseCost && gameRef.pulseReady;
    final pulseColor = canAffordPulse
        ? const Color(0xFF00FFFF).withOpacity(0.9)
        : const Color(0xFFFF4444).withOpacity(0.7);
    final pulseKey = 'cost-pulse-${pulseColor.value}';
    final pulseCostPainter = _getPainter(
      pulseKey,
      '${gameRef.pulseCost}g',
      TextStyle(
        color: pulseColor,
        fontSize: fontSize,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
      ),
    );
    pulseCostPainter.paint(
      canvas,
      Offset(pulseX - pulseCostPainter.width / 2, useTwoRows ? row2CostY : row1CostY),
    );

    // Mine cost
    final mineX = useTwoRows
        ? _layoutRow2StartX + abilityWidth + spacing + mineWidth / 2
        : startX +
            4 * (buttonWidth + spacing) +
            abilityWidth +
            spacing +
            mineWidth / 2;
    final canAffordMine = gameRef.gold >= gameRef.mineCost && gameRef.mineReady;
    final mineColor = canAffordMine
        ? const Color(0xFFFF0066).withOpacity(0.9)
        : const Color(0xFFFF4444).withOpacity(0.7);
    final mineKey = 'cost-mine-${mineColor.value}';
    final mineCostPainter = _getPainter(
      mineKey,
      '${gameRef.mineCost}g',
      TextStyle(
        color: mineColor,
        fontSize: fontSize,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
      ),
    );
    mineCostPainter.paint(
      canvas,
      Offset(mineX - mineCostPainter.width / 2, useTwoRows ? row2CostY : row1CostY),
    );
  }

  void _drawGlowingLine(Canvas canvas, double x1, double y1, double x2, double y2, Color color, double intensity) {
    // Outer glow
    _glowLineOuterPaint.color = color.withOpacity(intensity * 0.3);
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), _glowLineOuterPaint);

    // Core line
    _glowLineCorePaint.color = color.withOpacity(intensity);
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), _glowLineCorePaint);
  }

  void _drawHexPattern(Canvas canvas, double x, double y, int count, double alpha) {
    _hexPatternPaint.color = const Color(0xFF00FFFF).withOpacity(alpha);

    const hexSize = 8.0;
    for (int i = 0; i < count; i++) {
      for (int j = 0; j < 2; j++) {
        final offsetX = x + i * hexSize * 1.5;
        final offsetY = y + j * hexSize * 0.866 + (i % 2) * hexSize * 0.433;
        _drawHexagon(canvas, Offset(offsetX, offsetY), hexSize * 0.4, _hexPatternPaint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = _getHexagonPath(radius);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  Shader _getTopPanelShader(Rect rect) {
    if (_topPanelRect == rect && _topPanelShader != null) {
      return _topPanelShader!;
    }
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0a0a14),
        const Color(0xFF080810),
        const Color(0xFF060608).withOpacity(0.95),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 0.85, 1.0],
    ).createShader(rect);
    _topPanelRect = rect;
    _topPanelShader = shader;
    return shader;
  }

  Shader _getBottomPanelShader(Rect rect) {
    if (_bottomPanelRect == rect && _bottomPanelShader != null) {
      return _bottomPanelShader!;
    }
    final shader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        const Color(0xFF0a0a14),
        const Color(0xFF080810),
        const Color(0xFF060608).withOpacity(0.95),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.85, 1.0],
    ).createShader(rect);
    _bottomPanelRect = rect;
    _bottomPanelShader = shader;
    return shader;
  }

  Shader _getTowerInfoShader(Rect rect, TowerType type) {
    if (_towerInfoRect == rect && _towerInfoShader != null && _towerInfoType == type) {
      return _towerInfoShader!;
    }
    final shader = LinearGradient(
      colors: [
        type.color.withOpacity(0.1),
        const Color(0xFF0a0a14).withOpacity(0.8),
      ],
    ).createShader(rect);
    _towerInfoRect = rect;
    _towerInfoType = type;
    _towerInfoShader = shader;
    return shader;
  }

  Shader _getResourceCardShader(Rect rect, Color color) {
    final key = Object.hash(rect.left, rect.top, rect.width, rect.height, color.value);
    final cached = _resourceCardShaders[key];
    if (cached != null && cached.rect == rect && cached.color == color) {
      return cached.shader;
    }
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withOpacity(0.08),
        const Color(0xFF0a0a14).withOpacity(0.9),
        color.withOpacity(0.05),
      ],
    ).createShader(rect);
    _resourceCardShaders[key] = _CardShaderCache(rect, color, shader);
    return shader;
  }

  Path _getHexagonPath(double radius) {
    if (_hexagonPath != null && _hexagonRadius == radius) {
      return _hexagonPath!;
    }
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final point = Offset(
        radius * math.cos(angle),
        radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    _hexagonPath = path;
    _hexagonRadius = radius;
    return path;
  }

  void _updateSelectionCache(TowerType selected) {
    final damage = gameRef.towerDamage(selected).round();
    final range = gameRef.towerRange(selected).round();
    final fireRate = gameRef.towerFireRate(selected).toStringAsFixed(1);
    final cacheKey = Object.hash(selected, damage, range, fireRate);
    if (_lastSelected == selected &&
        _selectionCacheKey == cacheKey &&
        _selectionNamePainter != null &&
        _selectionStatsPainter != null &&
        _towerInfoNamePainter != null &&
        _towerInfoStatsPainter != null) {
      return;
    }

    _lastSelected = selected;
    _selectionCacheKey = cacheKey;
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
      'DMG $damage    RNG $range    SPD $fireRate',
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
      'DMG:$damage RNG:$range SPD:$fireRate',
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

class _CardShaderCache {
  _CardShaderCache(this.rect, this.color, this.shader);

  final Rect rect;
  final Color color;
  final Shader shader;
}

