import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../bored_games_game.dart';
import '../entities/tower.dart';
import '../managers/enemy_manager.dart' show WaveModifier;
import '../../ui/theme/neon_theme.dart';
import 'hud_button.dart';
import 'boss_health_bar.dart';
import '../../services/level_service.dart';

/// Professional HUD with cyberpunk aesthetic
class HudComponent extends PositionComponent with HasGameRef<BoredGamesGame> {
  // Button references for state updates
  final List<HudButton> _towerButtons = [];
  late HudButton pulseAbilityBtn;
  late HudButton mineAbilityBtn;
  late HudButton sellButton;
  late HudButton upgradeButton;
  late HudButton waveButton;

  double _time = 0;
  final Map<String, _TextCache> _textCache = {};
  static const int _maxTextCacheSize = 100; // Limit cache to prevent memory leak

  // Speed control
  static const List<double> speedOptions = [1.0, 2.0];
  Rect? _speed1xRect;
  Rect? _speed2xRect;
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

  // Wave transition animation state
  double _waveTransitionTimer = 0;
  int _waveTransitionFrom = 0;
  bool _waveTransitionActive = false;
  static const double _waveTransitionDuration = 1.2;
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
  static double bottomBarHeight = 20.0; // Reduced since buttons are now on sides
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

    // New side-panel layout doesn't need a large bottom bar
    bottomBarHeight = 20.0;
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
    _layoutTwoRows = false;

    // ═══════════════════════════════════════════════════════════════════════
    // RESPONSIVE LAYOUT: Adapts to screen size
    // ═══════════════════════════════════════════════════════════════════════

    // Calculate scale factor based on screen size
    final baseWidth = 1920.0;
    final baseHeight = 1080.0;
    final scaleX = (screenWidth / baseWidth).clamp(0.5, 1.2);
    final scaleY = (screenHeight / baseHeight).clamp(0.5, 1.2);
    final scale = math.min(scaleX, scaleY);

    // Responsive dimensions
    final leftPanelX = 12.0 * scale;
    final leftButtonWidth = (100.0 * scale).clamp(70.0, 120.0);
    final leftButtonHeight = (36.0 * scale).clamp(28.0, 44.0);
    final leftButtonSpacing = (5.0 * scale).clamp(3.0, 8.0);

    // Calculate available height for left panel
    final topOffset = topBarHeight + 100 * scale; // Below top bar and wave indicator
    final availableHeight = screenHeight - topOffset - 20;

    // Dynamic tower buttons based on unlocks
    final unlockedTowers = LevelService.instance.getUnlockedTowers();
    _towerButtons.clear();
    _layoutButtonWidth = leftButtonWidth;

    // Calculate total buttons needed (towers + sell + upgrades + wave)
    final totalLeftButtons = unlockedTowers.length + 3;
    final totalButtonsHeight = totalLeftButtons * leftButtonHeight + (totalLeftButtons - 1) * leftButtonSpacing;

    // Adjust button height if needed to fit
    var adjustedButtonHeight = leftButtonHeight;
    var adjustedSpacing = leftButtonSpacing;
    if (totalButtonsHeight > availableHeight) {
      final ratio = availableHeight / totalButtonsHeight;
      adjustedButtonHeight = (leftButtonHeight * ratio).clamp(24.0, leftButtonHeight);
      adjustedSpacing = (leftButtonSpacing * ratio).clamp(2.0, leftButtonSpacing);
    }

    final leftPanelStartY = topOffset;

    for (int i = 0; i < unlockedTowers.length; i++) {
      final type = unlockedTowers[i];
      final y = leftPanelStartY + i * (adjustedButtonHeight + adjustedSpacing);

      final btn = HudButton(
        label: type.name.split(' ').last.toUpperCase(),
        position: Vector2(leftPanelX, y),
        size: Vector2(leftButtonWidth, adjustedButtonHeight),
        color: type.color,
        isSelected: gameRef.towerManager.selectedTowerType == type,
        reduceFlicker: reduceFlicker,
        onPressed: () => gameRef.towerManager.setSelectedTowerType(type),
      );
      _towerButtons.add(btn);
      add(btn);
    }

    // Action buttons below tower buttons
    final actionButtonsStartY = leftPanelStartY + unlockedTowers.length * (adjustedButtonHeight + adjustedSpacing) + adjustedSpacing * 2;

    sellButton = HudButton(
      label: 'SELL',
      position: Vector2(leftPanelX, actionButtonsStartY),
      size: Vector2(leftButtonWidth, adjustedButtonHeight),
      color: const Color(0xFFFFAA00),
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.toggleSellMode(),
    );

    upgradeButton = HudButton(
      label: 'UPGRADES',
      position: Vector2(leftPanelX, actionButtonsStartY + adjustedButtonHeight + adjustedSpacing),
      size: Vector2(leftButtonWidth, adjustedButtonHeight),
      color: const Color(0xFF9C27B0),
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.toggleRunUpgradeOverlay(),
    );

    waveButton = HudButton(
      label: 'START WAVE',
      position: Vector2(leftPanelX, actionButtonsStartY + 2 * (adjustedButtonHeight + adjustedSpacing)),
      size: Vector2(leftButtonWidth, adjustedButtonHeight),
      color: const Color(0xFF00FF88),
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.startWave(count: 6),
      enabled: !gameRef.enemyManager.spawning,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // RIGHT SIDE: Minimap is handled separately, abilities below it
    // ═══════════════════════════════════════════════════════════════════════

    // Minimap dimensions (from MinimapComponent)
    final minimapSize = (130.0 * scale).clamp(90.0, 140.0);
    final minimapPadding = 12.0 * scale;
    final minimapY = 120.0 * scale; // Below top bar

    // Right panel positioning - below minimap
    final rightButtonWidth = (100.0 * scale).clamp(70.0, 120.0);
    final rightButtonHeight = (40.0 * scale).clamp(30.0, 48.0);
    final rightButtonSpacing = (6.0 * scale).clamp(4.0, 10.0);

    // Position abilities below minimap with gap
    final rightPanelX = screenWidth - rightButtonWidth - minimapPadding;
    final rightAbilitiesY = minimapY + minimapSize + 30 * scale;

    pulseAbilityBtn = HudButton(
      label: 'PULSE',
      position: Vector2(rightPanelX, rightAbilitiesY),
      size: Vector2(rightButtonWidth, rightButtonHeight),
      color: const Color(0xFF00FFFF),
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.activateNeonPulse(),
    );

    mineAbilityBtn = HudButton(
      label: 'MINE',
      position: Vector2(rightPanelX, rightAbilitiesY + rightButtonHeight + rightButtonSpacing),
      size: Vector2(rightButtonWidth, rightButtonHeight),
      color: const Color(0xFFFF0066),
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.deployMine(),
    );

    // Store layout values for cost indicators
    _layoutStartX = leftPanelX;
    _layoutSingleRowY = leftPanelStartY;
    _layoutSpacing = adjustedSpacing;
    _layoutButtonWidth = leftButtonWidth;

    // Store right panel info for other renders
    _rightPanelX = rightPanelX;
    _rightAbilitiesY = rightAbilitiesY;
    _rightButtonWidth = rightButtonWidth;
    _rightButtonHeight = rightButtonHeight;
    _rightButtonSpacing = rightButtonSpacing;
    _currentScale = scale;

    addAll(_towerButtons);
    addAll([
      pulseAbilityBtn,
      mineAbilityBtn,
      sellButton,
      upgradeButton,
      waveButton,
    ]);
  }

  // Layout variables for right panel
  double _rightPanelX = 0;
  double _rightAbilitiesY = 0;
  double _rightButtonWidth = 100;
  double _rightButtonHeight = 40;
  double _rightButtonSpacing = 6;
  double _currentScale = 1.0;

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

    // Wave transition animation
    final currentWave = gameRef.enemyManager.currentWave;
    if (currentWave != _waveTransitionFrom && currentWave > 0) {
      if (_waveTransitionFrom > 0 && currentWave > _waveTransitionFrom) {
        _waveTransitionActive = true;
        _waveTransitionTimer = 0;
      }
      _waveTransitionFrom = currentWave;
    }
    if (_waveTransitionActive) {
      _waveTransitionTimer += dt;
      if (_waveTransitionTimer >= _waveTransitionDuration) {
        _waveTransitionActive = false;
      }
    }

    final selected = gameRef.towerManager.selectedTowerType;
    for (final btn in _towerButtons) {
        final btnType = TowerType.values.firstWhere((t) => btn.label == t.name.split(' ').last.toUpperCase());
        btn.isSelected = selected == btnType;
    }

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
  void renderTree(Canvas canvas) {
    if (gameRef.hideHud) return; // Hide in benchmark mode
    if (gameRef.focusModeActive) return;
    super.renderTree(canvas);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final screenWidth = gameRef.size.x;
    final screenHeight = gameRef.size.y;

    if (gameRef.hideHud) return; // Hide HUD in benchmark/screenshot mode
    if (gameRef.focusModeActive) return; // Hide standard HUD in FPS mode

    _drawTopPanel(canvas, screenWidth);
    _drawBottomPanel(canvas, screenWidth, screenHeight);

    // No instruction prompt needed - modern HUD is self-explanatory

    _drawAbilityTargetHint(canvas, screenHeight);
    _drawFocusTimerOverlay(canvas, screenWidth, screenHeight);

    // ═══ WAVE TRANSITION FLASH - EPIC SCREEN EFFECT ═══
    if (_waveTransitionActive && !reduceFlicker) {
      final t = (_waveTransitionTimer / _waveTransitionDuration).clamp(0.0, 1.0);

      // Flash intensity - peaks early then fades
      double flashAlpha = 0.0;
      if (t < 0.1) {
        // Explosive white flash
        flashAlpha = (t / 0.1) * 0.6;
      } else if (t < 0.25) {
        // Rapid fade
        flashAlpha = 0.6 - ((t - 0.1) / 0.15) * 0.5;
      } else if (t < 0.5) {
        // Lingering glow
        flashAlpha = 0.1 - ((t - 0.25) / 0.25) * 0.1;
      }

      if (flashAlpha > 0.01) {
        // Main flash - white core
        canvas.drawRect(
          Rect.fromLTWH(0, 0, screenWidth, screenHeight),
          Paint()..color = Colors.white.withOpacity(flashAlpha * 0.5),
        );

        // Cyberpunk color overlay - cyan/magenta
        final colorFlash = t < 0.15
            ? const Color(0xFF00FFFF).withOpacity(flashAlpha * 0.3)
            : const Color(0xFFFF00FF).withOpacity(flashAlpha * 0.2);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, screenWidth, screenHeight),
          Paint()..color = colorFlash,
        );

        // Horizontal scan lines during flash
        if (t < 0.3) {
          final scanCount = 8;
          for (int i = 0; i < scanCount; i++) {
            final scanY = (screenHeight / scanCount) * i + (_time * 500 % (screenHeight / scanCount));
            canvas.drawLine(
              Offset(0, scanY),
              Offset(screenWidth, scanY),
              Paint()
                ..color = const Color(0xFF00FFFF).withOpacity(flashAlpha * 0.4)
                ..strokeWidth = 2,
            );
          }
        }
      }

      // Edge glow effect - borders light up
      if (t < 0.4) {
        final edgeAlpha = t < 0.1 ? (t / 0.1) : (1 - (t - 0.1) / 0.3);
        const edgeWidth = 4.0;
        final edgeColor = const Color(0xFFFF00FF).withOpacity(edgeAlpha * 0.6);

        // Top edge
        canvas.drawRect(
          Rect.fromLTWH(0, 0, screenWidth, edgeWidth),
          Paint()
            ..color = edgeColor
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        // Bottom edge
        canvas.drawRect(
          Rect.fromLTWH(0, screenHeight - edgeWidth, screenWidth, edgeWidth),
          Paint()
            ..color = edgeColor
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        // Left edge
        canvas.drawRect(
          Rect.fromLTWH(0, 0, edgeWidth, screenHeight),
          Paint()
            ..color = edgeColor
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        // Right edge
        canvas.drawRect(
          Rect.fromLTWH(screenWidth - edgeWidth, 0, edgeWidth, screenHeight),
          Paint()
            ..color = edgeColor
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
    }
  }

  void _drawFocusTimerOverlay(Canvas canvas, double screenWidth, double screenHeight) {
    if (!gameRef.focusModeActive) return;
    
    final timer = gameRef.focusModeTimer;
    final max = gameRef.focusModeMaxDuration;
    final progress = (timer / max).clamp(0.0, 1.0);
    
    final barWidth = 200.0;
    final barHeight = 4.0;
    final x = (screenWidth - barWidth) / 2;
    final y = topBarHeight + 20;
    
    // Draw timer bar
    canvas.drawRect(
      Rect.fromLTWH(x, y, barWidth, barHeight),
      Paint()..color = Colors.black45,
    );
    
    final color = gameRef.focusTower?.color ?? const Color(0xFF00FFFF);
    canvas.drawRect(
      Rect.fromLTWH(x, y, barWidth * progress, barHeight),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    
    final labelPainter = _getPainter(
      'focus-timer-label',
      'OVERDRIVE ACTIVE - ${timer.toStringAsFixed(1)}s',
      TextStyle(
        color: color,
        fontSize: 10,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        shadows: [Shadow(color: color, blurRadius: 4)],
      ),
    );
    labelPainter.paint(canvas, Offset(x + (barWidth - labelPainter.width) / 2, y - 14));
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

    // Position hint to the left of the ability button (new right-side layout)
    final x = button.position.x - painter.width - 18;
    final y = button.position.y + (button.size.y - painter.height) / 2;

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
    final screenHeight = gameRef.size.y;

    // Modern gaming HUD - slim top bar with gradient fade
    final panelRect = Rect.fromLTWH(0, 0, screenWidth, 50);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF000000).withOpacity(0.9),
        const Color(0xFF000000).withOpacity(0.5),
        Colors.transparent,
      ],
      stops: const [0.0, 0.7, 1.0],
    ).createShader(panelRect);
    canvas.drawRect(panelRect, Paint()..shader = gradient);

    // ═══ LEFT SIDE: Gold & Lives (horizontal layout) ═══
    _drawCompactStat(canvas, 16, 14, 'GOLD', '${gameRef.gold}', const Color(0xFFFFD700));
    _drawCompactStat(canvas, 110, 14, 'LIVES', '${gameRef.lives}', const Color(0xFFFF4466));

    // ═══ CENTER: Speed controls ═══
    _drawSpeedControls(canvas, screenWidth);

    // ═══ RIGHT SIDE: Score ═══
    final scoreText = '${gameRef.score}';
    final scorePainter = _getPainter(
      'score-modern-$scoreText',
      scoreText,
      const TextStyle(
        color: Color(0xFF00FF88),
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
        shadows: [Shadow(color: Color(0xFF00FF88), blurRadius: 10)],
      ),
    );
    scorePainter.paint(canvas, Offset(screenWidth - scorePainter.width - 16, 8));

    final scoreLabelPainter = _getPainter(
      'score-label-modern',
      'SCORE',
      TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 9,
        fontWeight: FontWeight.w500,
        letterSpacing: 2,
      ),
    );
    scoreLabelPainter.paint(canvas, Offset(screenWidth - scorePainter.width - 16, 32));

    // ═══ WAVE INDICATOR - Below top bar, centered ═══
    _drawWaveIndicator(canvas, screenWidth);

    // Wave alert (if active)
    _drawWaveAlert(canvas, screenWidth);
  }

  /// Compact stat display for top bar (horizontal)
  void _drawCompactStat(Canvas canvas, double x, double y, String label, String value, Color color) {
    // Label
    final labelPainter = _getPainter(
      'compact-label-$label',
      label,
      TextStyle(
        color: color.withOpacity(0.7),
        fontSize: 9,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
    );
    labelPainter.paint(canvas, Offset(x, y));

    // Value
    final valuePainter = _getPainter(
      'compact-value-$label-$value',
      value,
      TextStyle(
        color: color,
        fontSize: 16,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 6)],
      ),
    );
    valuePainter.paint(canvas, Offset(x + labelPainter.width + 8, y - 2));
  }

  void _drawSpeedControls(Canvas canvas, double screenWidth) {
    final currentSpeed = gameRef.timeScale;
    final buttonWidth = 32.0;
    final buttonHeight = 20.0;
    final spacing = 4.0;
    final totalWidth = buttonWidth * 2 + spacing;
    // Center the speed controls
    final startX = (screenWidth - totalWidth) / 2;
    final y = 12.0;

    for (int i = 0; i < speedOptions.length; i++) {
      final speed = speedOptions[i];
      final isActive = (currentSpeed - speed).abs() < 0.01;
      final x = startX + i * (buttonWidth + spacing);
      final rect = Rect.fromLTWH(x, y, buttonWidth, buttonHeight);

      // Store rects for tap detection
      if (i == 0) {
        _speed1xRect = rect;
      } else {
        _speed2xRect = rect;
      }

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

      // Background
      final bgColor = isActive
          ? const Color(0xFF00FF88).withOpacity(0.25)
          : const Color(0xFF0a0a18).withOpacity(0.6);
      canvas.drawRRect(rrect, Paint()..color = bgColor);

      // Border
      final borderColor = isActive
          ? const Color(0xFF00FF88).withOpacity(0.8)
          : Colors.white.withOpacity(0.2);
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActive ? 1.5 : 1,
      );

      // Glow when active
      if (isActive) {
        canvas.drawRRect(
          rrect.inflate(2),
          Paint()
            ..color = const Color(0xFF00FF88).withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }

      // Label
      final label = '${speed.toInt()}x';
      final labelPainter = _getPainter(
        'speed-$label-$isActive',
        label,
        TextStyle(
          color: isActive ? const Color(0xFF00FF88) : Colors.white.withOpacity(0.5),
          fontSize: 11,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'monospace',
          shadows: isActive
              ? [const Shadow(color: Color(0xFF00FF88), blurRadius: 4)]
              : null,
        ),
      );
      labelPainter.paint(
        canvas,
        Offset(
          x + (buttonWidth - labelPainter.width) / 2,
          y + (buttonHeight - labelPainter.height) / 2,
        ),
      );
    }
  }

  /// Handle tap for speed controls, returns true if tap was consumed
  bool handleSpeedTap(Vector2 tapPosition) {
    if (gameRef.hideHud || gameRef.focusModeActive) return false;

    if (_speed1xRect != null && _speed1xRect!.contains(Offset(tapPosition.x, tapPosition.y))) {
      gameRef.timeScale = speedOptions[0];
      return true;
    }
    if (_speed2xRect != null && _speed2xRect!.contains(Offset(tapPosition.x, tapPosition.y))) {
      gameRef.timeScale = speedOptions[1];
      return true;
    }
    return false;
  }

  void _drawModernStat(Canvas canvas, double x, double y, String label, String value, Color color, IconData icon) {
    // Glowing background pill
    final pillWidth = 100.0;
    final pillHeight = 24.0;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, pillWidth, pillHeight),
      const Radius.circular(12),
    );

    // Background with color tint
    canvas.drawRRect(
      pillRect,
      Paint()..color = color.withOpacity(0.15),
    );

    // Border glow
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Icon circle
    canvas.drawCircle(
      Offset(x + 14, y + pillHeight / 2),
      8,
      Paint()..color = color.withOpacity(0.3),
    );
    canvas.drawCircle(
      Offset(x + 14, y + pillHeight / 2),
      4,
      Paint()..color = color,
    );

    // Value
    final valuePainter = _getPainter(
      'modern-$label-$value',
      value,
      TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
        shadows: [Shadow(color: color.withOpacity(0.8), blurRadius: 6)],
      ),
    );
    valuePainter.paint(canvas, Offset(x + 28, y + (pillHeight - valuePainter.height) / 2));
  }

  void _drawWaveIndicator(Canvas canvas, double screenWidth) {
    final centerX = screenWidth / 2;
    final currentWave = gameRef.enemyManager.currentWave;
    final totalWaves = gameRef.totalWaves <= 0 ? 1 : gameRef.totalWaves;
    final waveProgress = gameRef.enemyManager.waveProgress.clamp(0.0, 1.0);
    final isSpawning = gameRef.enemyManager.spawning;
    final enemiesAlive = gameRef.enemyManager.aliveCount;

    // ═══════════════════════════════════════════════════════════════════════
    // CLEAN WAVE INDICATOR - Below top bar
    // ═══════════════════════════════════════════════════════════════════════

    // Animation for wave transition
    double transitionScale = 1.0;
    double shakeX = 0.0;
    double shakeY = 0.0;
    if (_waveTransitionActive) {
      final t = (_waveTransitionTimer / _waveTransitionDuration).clamp(0.0, 1.0);
      if (t < 0.2) {
        transitionScale = 1.0 + (t / 0.2) * 0.3;
        shakeX = math.sin(t * 60) * 4 * (1 - t / 0.2);
        shakeY = math.cos(t * 40) * 2 * (1 - t / 0.2);
      } else {
        transitionScale = 1.3 - ((t - 0.2) / 0.8) * 0.3;
      }
    }

    // Colors
    const cyanColor = Color(0xFF00FFFF);
    const magentaColor = Color(0xFFFF00FF);
    final primaryColor = isSpawning ? magentaColor : cyanColor;

    // Container dimensions - compact, positioned below top bar
    const containerWidth = 160.0;
    const containerHeight = 56.0;
    final containerX = centerX - containerWidth / 2;
    const containerY = 45.0; // Below the top bar

    // ═══ CLEAN BACKGROUND ═══
    final bgPath = Path();
    const cut = 10.0;
    bgPath.moveTo(containerX + cut, containerY);
    bgPath.lineTo(containerX + containerWidth - cut, containerY);
    bgPath.lineTo(containerX + containerWidth, containerY + cut);
    bgPath.lineTo(containerX + containerWidth, containerY + containerHeight - cut);
    bgPath.lineTo(containerX + containerWidth - cut, containerY + containerHeight);
    bgPath.lineTo(containerX + cut, containerY + containerHeight);
    bgPath.lineTo(containerX, containerY + containerHeight - cut);
    bgPath.lineTo(containerX, containerY + cut);
    bgPath.close();

    // Dark background
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0a0a18).withOpacity(0.92),
        const Color(0xFF12061a).withOpacity(0.88),
      ],
    ).createShader(Rect.fromLTWH(containerX, containerY, containerWidth, containerHeight));
    canvas.drawPath(bgPath, Paint()..shader = bgGradient);

    // Border
    canvas.drawPath(
      bgPath,
      Paint()
        ..color = primaryColor.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Subtle glow
    canvas.drawPath(
      bgPath,
      Paint()
        ..color = primaryColor.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // ═══ WAVE NUMBER ═══
    final waveText = '$currentWave';
    final numberY = containerY + 4;

    canvas.save();
    canvas.translate(centerX + shakeX, numberY + 16 + shakeY);
    canvas.scale(transitionScale, transitionScale);
    canvas.translate(-(centerX + shakeX), -(numberY + 16 + shakeY));

    // Main number with glow
    final wavePainter = _getPainter(
      'wave-num-clean-$waveText-$isSpawning',
      waveText,
      TextStyle(
        color: Colors.white,
        fontSize: 36,
        fontWeight: FontWeight.w900,
        fontFamily: 'monospace',
        shadows: [
          Shadow(color: primaryColor, blurRadius: 16),
          Shadow(color: primaryColor.withOpacity(0.6), blurRadius: 32),
        ],
      ),
    );
    wavePainter.paint(canvas, Offset(centerX - wavePainter.width / 2, numberY));
    canvas.restore();

    // ═══ SUBTITLE ═══
    final subtitleY = containerY + 40;
    final subtitleText = 'WAVE $currentWave / $totalWaves';
    final subtitlePainter = _getPainter(
      'wave-subtitle-clean-$currentWave-$totalWaves',
      subtitleText,
      TextStyle(
        color: primaryColor.withOpacity(0.85),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        fontFamily: 'monospace',
      ),
    );
    subtitlePainter.paint(canvas, Offset(centerX - subtitlePainter.width / 2, subtitleY));

    // ═══ PROGRESS BAR ═══
    const barWidth = 140.0;
    const barHeight = 3.0;
    final barX = centerX - barWidth / 2;
    final barY = containerY + containerHeight - 8;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withOpacity(0.1),
    );

    // Progress fill
    if (waveProgress > 0) {
      final fillWidth = barWidth * waveProgress;
      final fillGradient = LinearGradient(
        colors: [cyanColor, magentaColor],
      ).createShader(Rect.fromLTWH(barX, barY, fillWidth, barHeight));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, fillWidth, barHeight),
          const Radius.circular(2),
        ),
        Paint()..shader = fillGradient,
      );

      // Glow on progress
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY - 1, fillWidth, barHeight + 2),
          const Radius.circular(2),
        ),
        Paint()
          ..shader = fillGradient
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // ═══ ENEMY COUNT (compact) ═══
    if (isSpawning && enemiesAlive > 0) {
      final enemyText = '$enemiesAlive';
      final urgentColor = enemiesAlive > 20
          ? const Color(0xFFFF0044)
          : (enemiesAlive > 10 ? const Color(0xFFFFFF00) : magentaColor);
      final enemyPainter = _getPainter(
        'wave-enemies-clean-$enemiesAlive',
        enemyText,
        TextStyle(
          color: urgentColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          shadows: [Shadow(color: urgentColor, blurRadius: 4)],
        ),
      );
      // Draw enemy icon and count to the right of the container
      final iconX = containerX + containerWidth + 8;
      final iconY = containerY + containerHeight / 2 - 6;

      // Small enemy indicator
      canvas.drawCircle(
        Offset(iconX + 4, iconY + 6),
        4,
        Paint()..color = urgentColor.withOpacity(0.3),
      );
      canvas.drawCircle(
        Offset(iconX + 4, iconY + 6),
        2,
        Paint()..color = urgentColor,
      );
      enemyPainter.paint(
        canvas,
        Offset(centerX - enemyPainter.width / 2, containerY + containerHeight + 4),
      );
    }

    // ═══ WAVE TRANSITION - SUBTLE EFFECT ═══
    if (_waveTransitionActive) {
      final t = (_waveTransitionTimer / _waveTransitionDuration).clamp(0.0, 1.0);
      final transitionAlpha = t < 0.4 ? t * 2.5 : (1 - t) * 1.67;
      if (transitionAlpha > 0.05) {
        final incomingPainter = _getPainter(
          'wave-incoming',
          'WAVE $currentWave INCOMING',
          TextStyle(
            color: magentaColor.withOpacity(transitionAlpha * 0.8),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontFamily: 'monospace',
            shadows: [
              Shadow(color: magentaColor.withOpacity(transitionAlpha * 0.5), blurRadius: 8),
            ],
          ),
        );
        incomingPainter.paint(
          canvas,
          Offset(centerX - incomingPainter.width / 2, containerY + containerHeight + 10),
        );
      }
    }
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

    // Overdrive (FPS) uses indicator
    _drawOverdriveUses(canvas, screenWidth);
  }

  void _drawOverdriveUses(Canvas canvas, double screenWidth) {
    if (_isCompactHud(screenWidth, gameRef.size.y)) return;
    
    final uses = gameRef.fpsUsesTotal;
    final max = gameRef.maxFpsUsesMatch;
    final remaining = (max - uses).clamp(0, max);
    final color = remaining > 0 ? const Color(0xFF00FFFF) : const Color(0xFFFF0066);
    
    final x = screenWidth / 2 - 145; // Below selection info or logo
    final y = 70.0;
    
    // Draw small circles/dots for available uses
    for (int i = 0; i < max; i++) {
      final isUsed = i < uses;
      final dotX = x + i * 20;
      final dotPaint = Paint()
        ..color = isUsed ? Colors.white12 : color.withOpacity(0.8)
        ..maskFilter = isUsed ? null : const MaskFilter.blur(BlurStyle.normal, 2);
      
      canvas.drawCircle(Offset(dotX, y), 4, dotPaint);
      if (!isUsed) {
        canvas.drawCircle(Offset(dotX, y), 2, Paint()..color = Colors.white);
      }
    }
    
    final labelPainter = _getPainter(
      'overdrive-label',
      'OVERDRIVE USES',
      TextStyle(
        color: color.withOpacity(0.6),
        fontSize: 8,
        fontFamily: 'monospace',
        letterSpacing: 1.0,
      ),
    );
    labelPainter.paint(canvas, Offset(x - 2, y + 8));
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
    final modifier = gameRef.enemyManager.currentModifier;
    if (modifier == WaveModifier.normal) return;

    final centerX = screenWidth / 2;

    // ═══════════════════════════════════════════════════════════════════════
    // CYBERPUNK AGRESIVO - WAVE MODIFIER ALERT
    // ═══════════════════════════════════════════════════════════════════════

    // Glitch and pulse effects
    final glitchCycle = (_time * 4).floor() % 5;
    final isGlitching = glitchCycle == 0;
    final glitchOffset = isGlitching ? math.sin(_time * 60) * 4 : 0.0;
    final pulseAlpha = reduceFlicker ? 0.95 : 0.8 + math.sin(_time * 6) * 0.2;
    final pulseScale = reduceFlicker ? 1.0 : 1.0 + math.sin(_time * 5) * 0.05;
    final dangerPulse = 0.7 + math.sin(_time * 8) * 0.3;

    // Get modifier-specific styling
    final (icon, label, color) = _getModifierStyle(modifier);

    // Badge dimensions - WIDER, more aggressive
    const badgeY = 78.0;
    const badgeHeight = 32.0;
    const iconSize = 18.0;

    // Calculate badge width based on text
    final labelPainter = _getPainter(
      'modifier-label-cyber-$label',
      label,
      TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
        fontFamily: 'monospace',
      ),
    );
    final badgeWidth = iconSize + labelPainter.width + 40;
    final badgeX = centerX - badgeWidth / 2 + glitchOffset;

    // ═══ FRAGMENTED CONTAINER - Cut corners ═══
    final alertPath = Path();
    const cut = 8.0;
    alertPath.moveTo(badgeX + cut, badgeY);
    alertPath.lineTo(badgeX + badgeWidth - cut, badgeY);
    alertPath.lineTo(badgeX + badgeWidth, badgeY + cut);
    alertPath.lineTo(badgeX + badgeWidth, badgeY + badgeHeight - cut);
    alertPath.lineTo(badgeX + badgeWidth - cut, badgeY + badgeHeight);
    alertPath.lineTo(badgeX + cut, badgeY + badgeHeight);
    alertPath.lineTo(badgeX, badgeY + badgeHeight - cut);
    alertPath.lineTo(badgeX, badgeY + cut);
    alertPath.close();

    // Danger glow - INTENSE
    canvas.drawPath(
      alertPath,
      Paint()
        ..color = color.withOpacity(0.5 * dangerPulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Secondary glow layer
    canvas.drawPath(
      alertPath,
      Paint()
        ..color = color.withOpacity(0.3 * pulseAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Dark background with gradient
    final alertGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.15),
        const Color(0xFF0a0a18).withOpacity(0.95),
      ],
    ).createShader(Rect.fromLTWH(badgeX, badgeY, badgeWidth, badgeHeight));
    canvas.drawPath(alertPath, Paint()..shader = alertGradient);

    // ═══ GLITCH SCANLINES ═══
    if (!reduceFlicker) {
      for (int i = 0; i < 4; i++) {
        final scanY = badgeY + (i * 8) + (_time * 30 % 8);
        if (scanY < badgeY + badgeHeight) {
          canvas.drawLine(
            Offset(badgeX, scanY),
            Offset(badgeX + badgeWidth, scanY),
            Paint()
              ..color = color.withOpacity(isGlitching ? 0.15 : 0.05)
              ..strokeWidth = 1,
          );
        }
      }
    }

    // Border - AGGRESSIVE double line
    canvas.drawPath(
      alertPath,
      Paint()
        ..color = color.withOpacity(0.9 * pulseAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Inner border for depth
    final innerPath = Path();
    const innerCut = 6.0;
    const inset = 2.0;
    innerPath.moveTo(badgeX + inset + innerCut, badgeY + inset);
    innerPath.lineTo(badgeX + badgeWidth - inset - innerCut, badgeY + inset);
    innerPath.lineTo(badgeX + badgeWidth - inset, badgeY + inset + innerCut);
    innerPath.lineTo(badgeX + badgeWidth - inset, badgeY + badgeHeight - inset - innerCut);
    innerPath.lineTo(badgeX + badgeWidth - inset - innerCut, badgeY + badgeHeight - inset);
    innerPath.lineTo(badgeX + inset + innerCut, badgeY + badgeHeight - inset);
    innerPath.lineTo(badgeX + inset, badgeY + badgeHeight - inset - innerCut);
    innerPath.lineTo(badgeX + inset, badgeY + inset + innerCut);
    innerPath.close();
    canvas.drawPath(
      innerPath,
      Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ═══ CORNER DANGER POINTS ═══
    final alertCorners = [
      Offset(badgeX + cut, badgeY),
      Offset(badgeX + badgeWidth - cut, badgeY),
      Offset(badgeX + badgeWidth, badgeY + cut),
      Offset(badgeX + badgeWidth, badgeY + badgeHeight - cut),
      Offset(badgeX + badgeWidth - cut, badgeY + badgeHeight),
      Offset(badgeX + cut, badgeY + badgeHeight),
      Offset(badgeX, badgeY + badgeHeight - cut),
      Offset(badgeX, badgeY + cut),
    ];
    for (int i = 0; i < alertCorners.length; i++) {
      final corner = alertCorners[i];
      final cornerPulse = 0.5 + math.sin(_time * 6 + i * 0.9) * 0.5;
      canvas.drawCircle(
        corner,
        3,
        Paint()
          ..color = color.withOpacity(cornerPulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(corner, 1.5, Paint()..color = Colors.white);
    }

    // ═══ WARNING ICON with glitch ═══
    final iconCenterY = badgeY + badgeHeight / 2;

    // Icon glow
    canvas.drawCircle(
      Offset(badgeX + 20 + glitchOffset * 0.3, iconCenterY),
      12,
      Paint()
        ..color = color.withOpacity(0.4 * dangerPulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Glitch layers for icon
    if (isGlitching) {
      final redIconPainter = _getPainter(
        'modifier-icon-red-$icon',
        icon,
        TextStyle(
          color: const Color(0xFFFF0044).withOpacity(0.6),
          fontSize: iconSize,
          fontWeight: FontWeight.bold,
        ),
      );
      redIconPainter.paint(
        canvas,
        Offset(badgeX + 14 - 2, iconCenterY - iconSize / 2),
      );

      final cyanIconPainter = _getPainter(
        'modifier-icon-cyan-$icon',
        icon,
        TextStyle(
          color: const Color(0xFF00FFFF).withOpacity(0.6),
          fontSize: iconSize,
          fontWeight: FontWeight.bold,
        ),
      );
      cyanIconPainter.paint(
        canvas,
        Offset(badgeX + 14 + 2, iconCenterY - iconSize / 2),
      );
    }

    // Main icon
    final iconPainter = _getPainter(
      'modifier-icon-main-$icon',
      icon,
      TextStyle(
        color: color.withOpacity(pulseAlpha),
        fontSize: iconSize,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: color, blurRadius: 8)],
      ),
    );
    iconPainter.paint(
      canvas,
      Offset(badgeX + 14, iconCenterY - iconSize / 2),
    );

    // ═══ LABEL with aggressive styling ═══
    // Glitch effect on label
    if (isGlitching) {
      final glitchLabelPainter = _getPainter(
        'modifier-glitch-$label',
        label,
        TextStyle(
          color: const Color(0xFFFF0044).withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
          fontFamily: 'monospace',
        ),
      );
      glitchLabelPainter.paint(
        canvas,
        Offset(badgeX + 36 - 1, iconCenterY - labelPainter.height / 2 - 1),
      );
    }

    // Main label with glow
    final mainLabelPainter = _getPainter(
      'modifier-main-$label',
      label,
      TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
        fontFamily: 'monospace',
        shadows: [
          Shadow(color: color, blurRadius: 6),
          Shadow(color: color.withOpacity(0.5), blurRadius: 12),
        ],
      ),
    );
    mainLabelPainter.paint(
      canvas,
      Offset(badgeX + 36, iconCenterY - mainLabelPainter.height / 2),
    );

    // ═══ DANGER DECORATORS ═══
    // Left and right chevrons
    final chevronPaint = Paint()
      ..color = color.withOpacity(0.6 * dangerPulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Left chevron
    final leftChevron = Path();
    leftChevron.moveTo(badgeX - 12, iconCenterY - 6);
    leftChevron.lineTo(badgeX - 6, iconCenterY);
    leftChevron.lineTo(badgeX - 12, iconCenterY + 6);
    canvas.drawPath(leftChevron, chevronPaint);

    // Right chevron
    final rightChevron = Path();
    rightChevron.moveTo(badgeX + badgeWidth + 12, iconCenterY - 6);
    rightChevron.lineTo(badgeX + badgeWidth + 6, iconCenterY);
    rightChevron.lineTo(badgeX + badgeWidth + 12, iconCenterY + 6);
    canvas.drawPath(rightChevron, chevronPaint);
  }

  /// Returns (icon, label, color) for wave modifier
  (String, String, Color) _getModifierStyle(WaveModifier modifier) {
    switch (modifier) {
      case WaveModifier.overload:
        return ('⚡', 'FAST SPAWN', const Color(0xFFFFDD00));
      case WaveModifier.juggernaut:
        return ('◆', 'HEAVY ARMOR', const Color(0xFFFF6600));
      case WaveModifier.phantom:
        return ('◎', 'STEALTH', const Color(0xFFAA00FF));
      case WaveModifier.mixed:
        return ('✦', 'MIXED TYPES', const Color(0xFFFF00FF));
      case WaveModifier.normal:
        return ('', '', Colors.white);
    }
  }

  void _drawBottomPanel(Canvas canvas, double screenWidth, double screenHeight) {
    // With the new side-panel layout, we only need a minimal bottom area
    // Draw cost indicators next to the tower buttons on the left
    _drawModernCostIndicators(canvas, screenWidth, screenHeight);

    // Draw ability cooldowns on the right side
    _drawAbilityCooldowns(canvas, screenWidth, screenHeight);
  }

  void _drawSelectedTowerInfo(Canvas canvas, double screenHeight) {
    final selected = gameRef.towerManager.selectedTowerType;
    final panelX = 12.0;
    final panelY = screenHeight - bottomBarHeight + 8;

    // Tower name
    final namePainter = _getPainter(
      'selected-tower-${selected.name}',
      selected.name.toUpperCase(),
      TextStyle(
        color: selected.color,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        shadows: [Shadow(color: selected.color.withOpacity(0.5), blurRadius: 4)],
      ),
    );
    namePainter.paint(canvas, Offset(panelX, panelY));

    // Stats in one line
    final damage = gameRef.towerDamage(selected).round();
    final range = gameRef.towerRange(selected).round();
    final fireRate = gameRef.towerFireRate(selected);
    final statsText = 'DMG $damage  •  RNG $range  •  SPD ${fireRate.toStringAsFixed(1)}';
    final statsPainter = _getPainter(
      'selected-stats-$damage-$range-$fireRate',
      statsText,
      TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 9,
        fontFamily: 'monospace',
      ),
    );
    statsPainter.paint(canvas, Offset(panelX, panelY + 14));
  }

  void _drawModernCostIndicators(Canvas canvas, double screenWidth, double screenHeight) {
    // Use responsive layout - get positions from tower buttons
    final unlockedTowers = LevelService.instance.getUnlockedTowers();

    for (int i = 0; i < unlockedTowers.length && i < _towerButtons.length; i++) {
      final type = unlockedTowers[i];
      final cost = gameRef.towerCost(type);
      final button = _towerButtons[i];
      final canAfford = gameRef.gold >= cost;

      final costColor = canAfford ? type.color : const Color(0xFFFF4444);

      // Position cost to the right of the button (responsive)
      final pillWidth = (36.0 * _currentScale).clamp(28.0, 44.0);
      final pillHeight = (12.0 * _currentScale).clamp(10.0, 16.0);
      final costX = button.position.x + button.size.x + 4 * _currentScale;
      final costY = button.position.y + (button.size.y - pillHeight) / 2;

      final pillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(costX, costY, pillWidth, pillHeight),
        Radius.circular(pillHeight / 2),
      );

      canvas.drawRRect(
        pillRect,
        Paint()..color = (canAfford ? type.color : const Color(0xFFFF4444)).withOpacity(0.2),
      );

      final fontSize = (9.0 * _currentScale).clamp(7.0, 11.0);
      final costPainter = _getPainter(
        'cost-modern-$cost-${costColor.value}-$fontSize',
        '${cost}g',
        TextStyle(
          color: costColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      );
      costPainter.paint(
        canvas,
        Offset(costX + (pillWidth - costPainter.width) / 2, costY + (pillHeight - costPainter.height) / 2),
      );
    }
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

    // Use responsive layout variables
    final barWidth = _rightButtonWidth;
    final barHeight = (16.0 * _currentScale).clamp(12.0, 20.0);
    final showHotkeys = _shouldShowHotkeys();

    // Pulse cooldown - below pulse button
    final pulseBarY = _rightAbilitiesY + _rightButtonHeight + 2;
    _drawCooldownBar(
      canvas,
      x: _rightPanelX,
      y: pulseBarY,
      width: barWidth,
      height: barHeight,
      ready: gameRef.pulseReady,
      progress: gameRef.pulseReady ? 1.0 : (1.0 - gameRef.pulseCooldownPercent),
      color: const Color(0xFF00FFFF),
      label: '',
      hotkey: showHotkeys ? '[SPACE]' : '',
    );

    // Mine cooldown - below mine button
    final mineBarY = _rightAbilitiesY + _rightButtonHeight + _rightButtonSpacing + _rightButtonHeight + 2;
    _drawCooldownBar(
      canvas,
      x: _rightPanelX,
      y: mineBarY,
      width: barWidth,
      height: barHeight,
      ready: gameRef.mineReady,
      progress: gameRef.mineReady ? 1.0 : (1.0 - gameRef.mineCooldownPercent),
      color: const Color(0xFFFF0066),
      label: '',
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
    // Evict oldest entries if cache is full to prevent memory leak
    if (_textCache.length >= _maxTextCacheSize) {
      // Remove first 20 entries (oldest) to make room
      final keysToRemove = _textCache.keys.take(20).toList();
      for (final k in keysToRemove) {
        _textCache.remove(k);
      }
    }
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

