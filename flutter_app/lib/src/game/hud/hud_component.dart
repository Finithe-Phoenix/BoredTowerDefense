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
  final Map<HudButton, TowerType> _towerButtonTypes = <HudButton, TowerType>{};
  late HudButton pulseAbilityBtn;
  late HudButton mineAbilityBtn;
  late HudButton sellButton;
  late HudButton upgradeButton;
  late HudButton waveButton;

  double _time = 0;
  final Map<String, _TextCache> _textCache = {};
  static const int _maxTextCacheSize =
      100; // Limit cache to prevent memory leak

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
  final Paint _resourceCardAccentPaint = Paint()..strokeWidth = 2;
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
  final Paint _glowLineCorePaint = Paint()..strokeWidth = 1;
  final Paint _hexPatternPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  final Paint _abilityHintBgPaint = Paint();
  final Paint _abilityHintBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Paint _speedBgPaint = Paint();
  final Paint _speedBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Paint _speedGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  final Paint _statPillBgPaint = Paint();
  final Paint _statPillBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final Paint _statPillIconOuterPaint = Paint();
  final Paint _statPillIconInnerPaint = Paint();
  final Paint _centerLinePaint = Paint()..strokeWidth = 1;
  final Paint _centerDiamondPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Paint _centerInnerDiamondPaint = Paint();
  final Path _centerDiamondPath = Path();
  final Path _centerInnerDiamondPath = Path();
  final Paint _overdriveDotPaint = Paint();
  final Paint _overdriveDotCorePaint = Paint();
  final Paint _costPillPaint = Paint();

  // Wave Indicator optimized paints
  static final Paint _waveIndicatorBgPaint = Paint();
  static final Paint _waveIndicatorBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _waveIndicatorGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _waveIndicatorInnerGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _waveIndicatorScanlinePaint = Paint();
  static final Paint _waveIndicatorCornerPaint = Paint()..strokeWidth = 2;
  static final Paint _waveIndicatorAccentPaint = Paint()
    ..strokeCap = StrokeCap.round;
  static final Paint _waveIndicatorProgressBgPaint = Paint();
  static final Paint _waveIndicatorProgressFillPaint = Paint();
  static final Paint _waveIndicatorProgressGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _waveIndicatorEnemyDotPaint = Paint();
  static final Paint _waveIndicatorEnemyGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _waveIndicatorTipPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _waveIndicatorEnemyPanelBgPaint = Paint();
  static final Paint _waveIndicatorEnemyPanelBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _waveIndicatorBurstPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  static final Path _waveIndicatorFramePath = Path();
  static final Path _waveIndicatorEnemyPanelPath = Path();

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA STREAM EFFECT PAINTS (Towers to HUD connection visualization)
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _dataStreamBeamPaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _dataStreamCorePaint = Paint()
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  static final Paint _dataStreamParticlePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _dataStreamGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _dataStreamNodePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _dataStreamArcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  static final Paint _dataStreamHexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  static final Paint _dataStreamPulsePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Path _dataStreamPath = Path();

  // ═══════════════════════════════════════════════════════════════════════════
  // GLITCH DISTORTION EFFECT PAINTS (Wave transitions)
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _glitchRedPaint = Paint()
    ..blendMode = BlendMode.plus
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _glitchCyanPaint = Paint()
    ..blendMode = BlendMode.plus
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _glitchNoisePaint = Paint();
  static final Paint _glitchBlockPaint = Paint();
  static final Paint _glitchLinePaint = Paint()..strokeWidth = 2;
  static final Paint _glitchScanlinePaint = Paint()..strokeWidth = 1;
  static final Paint _glitchStaticPaint = Paint()..strokeWidth = 1;
  static final Paint _glitchEdgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _glitchFlashPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _glitchDataPaint = Paint()
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  static int _glitchRngState = 0x51f1e3;

  // ═══════════════════════════════════════════════════════════════════════════
  // CRT/SCANLINE EFFECT PAINTS (Retro monitor aesthetic)
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _crtScanlinePaint = Paint()
    ..color = const Color(0xFF000000);
  static final Paint _crtVignettePaint = Paint();
  static final Paint _crtScreenGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _crtRgbLinePaint = Paint()..strokeWidth = 1;
  static final Paint _crtFlickerPaint = Paint();
  static final Paint _crtPhosphorPaint = Paint()..blendMode = BlendMode.plus;
  static final Paint _crtCurveHighlightPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  static final Paint _crtInterlacePaint = Paint()..strokeWidth = 0.5;
  static final Paint _crtNoisePaint = Paint();
  static int _crtRngState = 0x63d2a5;
  static double _crtFlickerPhase = 0.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // HOLOGRAPHIC TOWER UPGRADE PREVIEW PAINTS
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _holoPreviewBgPaint = Paint();
  static final Paint _holoPreviewBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _holoPreviewGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _holoPreviewCornerPaint = Paint()
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  static final Paint _holoPreviewScanPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _holoPreviewHexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Paint _holoPreviewBarBgPaint = Paint();
  static final Paint _holoPreviewBarFillPaint = Paint();
  static final Paint _holoPreviewBarGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _holoPreviewIconPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _holoPreviewDataPaint = Paint()
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  static final Paint _holoPreviewBonusPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _holoPreviewProjectionPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _holoPreviewFramePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _holoPreviewPulsePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _holoPreviewDigitPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  static final Path _holoPreviewPath = Path();
  static int _holoPreviewRngState = 0x9e3779b;

  // ═══════════════════════════════════════════════════════════════════════════
  // HOLOGRAPHIC MINIMAP PAINTS
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _minimapBgPaint = Paint();
  static final Paint _minimapBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _minimapGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _minimapGridPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Paint _minimapTowerPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _minimapEnemyPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _minimapPathPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _minimapBasePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _minimapScanPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _minimapCornerPaint = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _minimapHexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.3;
  static final Paint _minimapDataPaint = Paint()..strokeCap = StrokeCap.round;
  static final Paint _minimapPulsePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Path _minimapPath = Path();
  static int _minimapRngState = 0x1f3d5b;
  static double _minimapScanAngle = 0.0;

  static int _lcgNext(int state) => (1664525 * state + 1013904223) & 0x7fffffff;

  static double _glitchNextUnit() {
    _glitchRngState = _lcgNext(_glitchRngState);
    return _glitchRngState / 0x7fffffff;
  }

  static int _glitchNextInt(int max) {
    if (max <= 0) return 0;
    _glitchRngState = _lcgNext(_glitchRngState);
    return _glitchRngState % max;
  }

  static bool _glitchNextBool() {
    _glitchRngState = _lcgNext(_glitchRngState);
    return (_glitchRngState & 1) == 0;
  }

  static double _crtNextUnit() {
    _crtRngState = _lcgNext(_crtRngState);
    return _crtRngState / 0x7fffffff;
  }

  static int _crtNextInt(int max) {
    if (max <= 0) return 0;
    _crtRngState = _lcgNext(_crtRngState);
    return _crtRngState % max;
  }

  static bool _crtNextBool() {
    _crtRngState = _lcgNext(_crtRngState);
    return (_crtRngState & 1) == 0;
  }

  static double _holoPreviewNextUnit() {
    _holoPreviewRngState = _lcgNext(_holoPreviewRngState);
    return _holoPreviewRngState / 0x7fffffff;
  }

  static bool _holoPreviewNextBool() {
    _holoPreviewRngState = _lcgNext(_holoPreviewRngState);
    return (_holoPreviewRngState & 1) == 0;
  }

  static double _minimapNextUnit() {
    _minimapRngState = _lcgNext(_minimapRngState);
    return _minimapRngState / 0x7fffffff;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADDITIONAL OPTIMIZED PAINTS (Avoid inline allocations in hot paths)
  // ═══════════════════════════════════════════════════════════════════════════
  static final Paint _colorFlashPaint = Paint();
  static final Paint _vignettePaint = Paint();
  static final Paint _focusTimerBgPaint = Paint()..color = Colors.black45;
  static final Paint _focusTimerFillPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _alertGradientPaint = Paint();
  static final Paint _panelGradientPaint = Paint();
  static final Paint _genericBgPaint = Paint();
  static final Paint _genericBorderPaint = Paint()
    ..style = PaintingStyle.stroke;
  static final Paint _progressFillPaint = Paint();
  static final Paint _highlightGradientPaint = Paint();
  static final Paint _cooldownBgPaint = Paint()
    ..color = const Color(0xFF0a0a18);
  static final Paint _cooldownGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _cooldownFillPaint = Paint();
  static final Paint _cooldownBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _alertGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
  static final Paint _alertSecondaryGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _alertBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _alertInnerBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _alertScanlinePaint = Paint()..strokeWidth = 1;
  static final Paint _alertCornerPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _alertCornerCorePaint = Paint();
  static final Paint _alertIconGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Path _alertPath = Path();
  static final Path _alertInnerPath = Path();
  static final Paint _alertChevronPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Path _alertLeftChevronPath = Path();
  static final Path _alertRightChevronPath = Path();

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
  static double bottomBarHeight =
      20.0; // Reduced since buttons are now on sides
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
    final game = findGame();
    if (game is! BoredGamesGame) {
      return;
    }

    // Initialize boss health bar
    _bossHealthBar = BossHealthBar(
      screenWidth: game.size.x,
      screenHeight: game.size.y,
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
    for (final b in [...children.whereType<HudButton>()]) {
      b.removeFromParent();
    }

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
    final compactWave = compact || screenHeight < 720;
    final waveOffset = compactWave ? 60.0 * scale : 100.0 * scale;
    final topOffset = topBarHeight + waveOffset;
    final availableHeight = screenHeight - topOffset - 20;

    // Dynamic tower buttons based on unlocks
    final unlockedTowers = LevelService.instance.getUnlockedTowers();
    _towerButtons.clear();
    _towerButtonTypes.clear();
    _layoutButtonWidth = leftButtonWidth;

    // Calculate total buttons needed (towers + sell + upgrades + wave)
    final totalLeftButtons = unlockedTowers.length + 3;
    final totalButtonsHeight = totalLeftButtons * leftButtonHeight +
        (totalLeftButtons - 1) * leftButtonSpacing;

    // Adjust button height if needed to fit
    var adjustedButtonHeight = leftButtonHeight;
    var adjustedSpacing = leftButtonSpacing;
    if (totalButtonsHeight > availableHeight) {
      final ratio = availableHeight / totalButtonsHeight;
      adjustedButtonHeight =
          (leftButtonHeight * ratio).clamp(24.0, leftButtonHeight);
      adjustedSpacing =
          (leftButtonSpacing * ratio).clamp(2.0, leftButtonSpacing);
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
      _towerButtonTypes[btn] = type;
    }

    // Action buttons below tower buttons
    final actionButtonsStartY = leftPanelStartY +
        unlockedTowers.length * (adjustedButtonHeight + adjustedSpacing) +
        adjustedSpacing * 2;

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
      position: Vector2(leftPanelX,
          actionButtonsStartY + adjustedButtonHeight + adjustedSpacing),
      size: Vector2(leftButtonWidth, adjustedButtonHeight),
      color: const Color(0xFF9C27B0),
      reduceFlicker: reduceFlicker,
      onPressed: () => gameRef.toggleRunUpgradeOverlay(),
    );

    waveButton = HudButton(
      label: 'START WAVE',
      position: Vector2(leftPanelX,
          actionButtonsStartY + 2 * (adjustedButtonHeight + adjustedSpacing)),
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
      position: Vector2(rightPanelX,
          rightAbilitiesY + rightButtonHeight + rightButtonSpacing),
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
    final game = findGame();
    if (game is! BoredGamesGame) {
      return;
    }

    // Wave transition animation
    final currentWave = game.enemyManager.currentWave;
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

    final selected = game.towerManager.selectedTowerType;
    for (final btn in _towerButtons) {
      btn.isSelected = identical(_towerButtonTypes[btn], selected);
    }

    waveButton.enabled = !game.enemyManager.spawning;
    pulseAbilityBtn.isSelected = game.pendingAbility == PendingAbility.pulse;
    mineAbilityBtn.isSelected = game.pendingAbility == PendingAbility.mine;
    sellButton.enabled = game.towerManager.towers.isNotEmpty;
    sellButton.isSelected = game.sellMode;
    upgradeButton.isSelected =
        game.awaitingUpgradeChoice || game.upgradeOverlayActive;
    _updateSelectionCache(selected);
    _updateResourceCache();

    // Update boss health bar
    _bossHealthBar?.setBoss(game.enemyManager.currentBoss);
    _bossHealthBar?.updateLayout(
      screenWidth: game.size.x,
      topInset: topBarHeight,
      compact: _isCompactHud(game.size.x, game.size.y) || game.size.y < 720,
    );
  }

  @override
  void renderTree(Canvas canvas) {
    final game = findGame();
    if (game is! BoredGamesGame) return;
    if (game.hideHud) return; // Hide in benchmark mode
    if (game.focusModeActive) return;
    super.renderTree(canvas);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final game = findGame();
    if (game is! BoredGamesGame) return;

    final screenWidth = game.size.x;
    final screenHeight = game.size.y;

    if (game.hideHud) return; // Hide HUD in benchmark/screenshot mode
    if (game.focusModeActive) return; // Hide standard HUD in FPS mode

    // Draw data stream effects (background layer - behind HUD panels)
    _drawDataStreamEffects(canvas, screenWidth, screenHeight);

    _drawTopPanel(canvas, screenWidth);
    _drawBottomPanel(canvas, screenWidth, screenHeight);

    // Draw holographic minimap (top-right corner)
    if (!game.reduceFx) {
      _drawHolographicMinimap(canvas, screenWidth, screenHeight);
    }

    // No instruction prompt needed - modern HUD is self-explanatory

    _drawAbilityTargetHint(canvas, screenHeight);
    _drawFocusTimerOverlay(canvas, screenWidth, screenHeight);

    // ═══ WAVE TRANSITION FLASH WITH GLITCH DISTORTION ═══
    if (_waveTransitionActive && !reduceFlicker) {
      _drawGlitchDistortionEffect(canvas, screenWidth, screenHeight);
    }

    // ═══ CRT/SCANLINE OVERLAY EFFECT (Always on for cyberpunk aesthetic) ═══
    if (!game.reduceFx) {
      _drawCrtScanlineEffect(canvas, screenWidth, screenHeight);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRT/SCANLINE EFFECT (Retro monitor aesthetic over HUD)
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawCrtScanlineEffect(
      Canvas canvas, double screenWidth, double screenHeight) {
    final animPhase = _time;
    _crtFlickerPhase += 0.016; // ~60fps time step

    // Only apply CRT effect over HUD areas (top and bottom panels)
    final topPanelHeight = HudComponent.topBarHeight + 10;
    final bottomPanelY = screenHeight - HudComponent.bottomBarHeight - 60;

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: SUBTLE HORIZONTAL SCANLINES (Top panel)
    // ═══════════════════════════════════════════════════════════════════════
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, screenWidth, topPanelHeight));

    _crtScanlinePaint.color = const Color(0xFF000000).withOpacity(0.08);
    final scanlineSpacing = 3.0;
    final scanlineOffset = (animPhase * 30) % scanlineSpacing;

    for (double y = scanlineOffset; y < topPanelHeight; y += scanlineSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(screenWidth, y),
        _crtScanlinePaint,
      );
    }
    canvas.restore();

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: RGB PHOSPHOR LINES (subtle color fringing)
    // ═══════════════════════════════════════════════════════════════════════
    if (!gameRef.reduceFx) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, screenWidth, topPanelHeight));

      final rgbSpacing = 6.0;
      for (double x = 0; x < screenWidth; x += rgbSpacing) {
        // Red line
        _crtRgbLinePaint.color = const Color(0xFFFF0000).withOpacity(0.02);
        canvas.drawLine(
            Offset(x, 0), Offset(x, topPanelHeight), _crtRgbLinePaint);

        // Green line
        _crtRgbLinePaint.color = const Color(0xFF00FF00).withOpacity(0.02);
        canvas.drawLine(
            Offset(x + 2, 0), Offset(x + 2, topPanelHeight), _crtRgbLinePaint);

        // Blue line
        _crtRgbLinePaint.color = const Color(0xFF0000FF).withOpacity(0.02);
        canvas.drawLine(
            Offset(x + 4, 0), Offset(x + 4, topPanelHeight), _crtRgbLinePaint);
      }
      canvas.restore();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: VIGNETTE EFFECT (Darker edges like CRT monitors)
    // ═══════════════════════════════════════════════════════════════════════
    // Top panel vignette
    final topVignetteGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Colors.transparent,
        const Color(0xFF000000).withOpacity(0.15),
        const Color(0xFF000000).withOpacity(0.35),
      ],
      stops: const [0.3, 0.7, 1.0],
    );

    _crtVignettePaint.shader = topVignetteGradient.createShader(
      Rect.fromLTWH(0, 0, screenWidth, topPanelHeight),
    );
    canvas.drawRect(
        Rect.fromLTWH(0, 0, screenWidth, topPanelHeight), _crtVignettePaint);
    _crtVignettePaint.shader = null;

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: SUBTLE SCREEN FLICKER (random brightness variation)
    // ═══════════════════════════════════════════════════════════════════════
    final flickerValue = math.sin(_crtFlickerPhase * 50) * 0.02;
    if (flickerValue.abs() > 0.01) {
      _crtFlickerPaint.color =
          Colors.white.withOpacity(flickerValue.abs() * 0.5);
      canvas.drawRect(
          Rect.fromLTWH(0, 0, screenWidth, topPanelHeight), _crtFlickerPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: INTERLACE EFFECT (alternating line brightness)
    // ═══════════════════════════════════════════════════════════════════════
    if (!gameRef.reduceFx) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, screenWidth, topPanelHeight));

      // Alternate frame - shift which lines are brighter
      final frameEven = (animPhase * 30).toInt() % 2 == 0;
      _crtInterlacePaint.color = const Color(0xFF000000).withOpacity(0.04);

      for (double y = frameEven ? 0 : 1; y < topPanelHeight; y += 2) {
        canvas.drawLine(
            Offset(0, y), Offset(screenWidth, y), _crtInterlacePaint);
      }
      canvas.restore();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: PHOSPHOR GLOW (subtle colored glow on edges)
    // ═══════════════════════════════════════════════════════════════════════
    final phosphorPulse = 0.5 + math.sin(animPhase * 2) * 0.3;
    _crtPhosphorPaint.color =
        const Color(0xFF00FFFF).withOpacity(0.02 * phosphorPulse);
    canvas.drawRect(Rect.fromLTWH(0, 0, screenWidth, 2), _crtPhosphorPaint);
    canvas.drawRect(Rect.fromLTWH(0, topPanelHeight - 2, screenWidth, 2),
        _crtPhosphorPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: SCREEN CURVE HIGHLIGHT (simulates curved CRT glass)
    // ═══════════════════════════════════════════════════════════════════════
    if (!gameRef.reduceFx) {
      final curveHighlightGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.03),
          Colors.transparent,
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 1.0],
      );

      _crtCurveHighlightPaint.shader = curveHighlightGradient.createShader(
        Rect.fromLTWH(0, 0, screenWidth * 0.4, topPanelHeight),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, screenWidth * 0.4, topPanelHeight),
        _crtCurveHighlightPaint,
      );
      _crtCurveHighlightPaint.shader = null;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 8: STATIC NOISE (occasional digital artifacts)
    // ═══════════════════════════════════════════════════════════════════════
    if (!gameRef.reduceFx && _crtNextUnit() < 0.05) {
      final noiseCount = 3 + _crtNextInt(5);
      for (int i = 0; i < noiseCount; i++) {
        final noiseX = _crtNextUnit() * screenWidth;
        final noiseY = _crtNextUnit() * topPanelHeight;
        final noiseW = 1 + _crtNextUnit() * 3;
        final noiseH = 1 + _crtNextUnit() * 2;

        _crtNoisePaint.color = _crtNextBool()
            ? Colors.white.withOpacity(0.15)
            : Colors.black.withOpacity(0.2);

        canvas.drawRect(
          Rect.fromLTWH(noiseX, noiseY, noiseW, noiseH),
          _crtNoisePaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 9: BOTTOM PANEL SCANLINES
    // ═══════════════════════════════════════════════════════════════════════
    if (bottomPanelY < screenHeight) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(
          0, bottomPanelY, screenWidth, screenHeight - bottomPanelY));

      _crtScanlinePaint.color = const Color(0xFF000000).withOpacity(0.06);
      for (double y = bottomPanelY + scanlineOffset;
          y < screenHeight;
          y += scanlineSpacing) {
        canvas.drawLine(
          Offset(0, y),
          Offset(screenWidth, y),
          _crtScanlinePaint,
        );
      }
      canvas.restore();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 10: CORNER EDGE GLOW (CRT monitor corner illumination)
    // ═══════════════════════════════════════════════════════════════════════
    if (!gameRef.reduceFx) {
      final edgeGlowAlpha = 0.05 + math.sin(animPhase * 1.5) * 0.02;

      // Top-left corner glow
      _crtScreenGlowPaint.color =
          const Color(0xFF00FFFF).withOpacity(edgeGlowAlpha);
      canvas.drawCircle(const Offset(0, 0), 60, _crtScreenGlowPaint);

      // Top-right corner glow
      _crtScreenGlowPaint.color =
          const Color(0xFFFF00FF).withOpacity(edgeGlowAlpha);
      canvas.drawCircle(Offset(screenWidth, 0), 60, _crtScreenGlowPaint);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HOLOGRAPHIC MINIMAP WITH REAL-TIME ENTITY TRACKING
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawHolographicMinimap(
      Canvas canvas, double screenWidth, double screenHeight) {
    // Minimap positioned at bottom-left corner
    const minimapSize = 120.0;
    const minimapMargin = 15.0;
    const minimapPadding = 8.0;

    // Check if we have enough vertical space (avoid overlapping with bottom panel)
    final bottomPanelTop = screenHeight - HudComponent.bottomBarHeight - 60;
    final minimapBottom = screenHeight - minimapMargin;
    if (minimapBottom - minimapSize < bottomPanelTop + 20)
      return; // Not enough space

    final minimapRect = Rect.fromLTWH(
      minimapMargin,
      bottomPanelTop - minimapSize - minimapMargin,
      minimapSize,
      minimapSize,
    );

    final animPhase = _time;
    _minimapScanAngle += 0.02; // Rotate radar scan

    // Get game entities for rendering
    final worldSize = Vector2(
      gameRef.worldLayer.mapWidth * gameRef.worldLayer.tileSize,
      gameRef.worldLayer.mapHeight * gameRef.worldLayer.tileSize,
    );
    final towers = gameRef.towerManager.towers;
    final enemies = gameRef.enemyManager.activeEnemies;
    final pathPoints = gameRef.worldLayer.waypoints;
    final basePos = pathPoints.isNotEmpty
        ? pathPoints.last
        : Vector2(worldSize.x, worldSize.y / 2);

    // Calculate scale factors
    final scaleX = (minimapSize - minimapPadding * 2) / worldSize.x;
    final scaleY = (minimapSize - minimapPadding * 2) / worldSize.y;
    final scale = math.min(scaleX, scaleY);
    final offsetX = minimapRect.left +
        minimapPadding +
        (minimapSize - minimapPadding * 2 - worldSize.x * scale) / 2;
    final offsetY = minimapRect.top +
        minimapPadding +
        (minimapSize - minimapPadding * 2 - worldSize.y * scale) / 2;

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: BACKGROUND WITH HOLOGRAPHIC TINT
    // ═══════════════════════════════════════════════════════════════════════
    _minimapBgPaint.color = const Color(0xFF050510).withOpacity(0.85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(minimapRect, const Radius.circular(6)),
      _minimapBgPaint,
    );

    // Outer glow
    final glowPulse = 0.4 + math.sin(animPhase * 2) * 0.15;
    _minimapGlowPaint.color = NeonTheme.cyberCyan.withOpacity(glowPulse * 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(minimapRect.inflate(3), const Radius.circular(8)),
      _minimapGlowPaint,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: HEXAGONAL GRID OVERLAY
    // ═══════════════════════════════════════════════════════════════════════
    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(minimapRect, const Radius.circular(6)));

    _minimapHexPaint.color = NeonTheme.cyberCyan.withOpacity(0.1);
    final hexGridSize = 12.0;
    for (double y = minimapRect.top;
        y < minimapRect.bottom;
        y += hexGridSize * 0.866) {
      final rowOffset =
          ((y - minimapRect.top) / (hexGridSize * 0.866)).floor() % 2 == 0
              ? 0.0
              : hexGridSize / 2;
      for (double x = minimapRect.left + rowOffset;
          x < minimapRect.right;
          x += hexGridSize) {
        _drawMiniHex(canvas, x, y, hexGridSize / 2, _minimapHexPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: PATH VISUALIZATION
    // ═══════════════════════════════════════════════════════════════════════
    if (pathPoints.length >= 2) {
      _minimapPath.reset();
      final firstPoint = pathPoints[0];
      _minimapPath.moveTo(
        offsetX + firstPoint.x * scale,
        offsetY + firstPoint.y * scale,
      );

      for (int i = 1; i < pathPoints.length; i++) {
        final point = pathPoints[i];
        _minimapPath.lineTo(
          offsetX + point.x * scale,
          offsetY + point.y * scale,
        );
      }

      // Path glow
      _minimapPathPaint.color = NeonTheme.cyberPurple.withOpacity(0.4);
      canvas.drawPath(_minimapPath, _minimapPathPaint);

      // Path flow animation (dots moving along path)
      final flowOffset = (animPhase * 0.5) % 1.0;
      _minimapDataPaint.strokeWidth = 2;
      for (int i = 0; i < 5; i++) {
        final t = (flowOffset + i * 0.2) % 1.0;
        final pathIndex = ((pathPoints.length - 1) * t).floor();
        final pathT = ((pathPoints.length - 1) * t) - pathIndex;

        if (pathIndex < pathPoints.length - 1) {
          final p1 = pathPoints[pathIndex];
          final p2 = pathPoints[pathIndex + 1];
          final dotX = offsetX + (p1.x + (p2.x - p1.x) * pathT) * scale;
          final dotY = offsetY + (p1.y + (p2.y - p1.y) * pathT) * scale;

          final dotAlpha = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
          _minimapDataPaint.color =
              NeonTheme.cyberMagenta.withOpacity(dotAlpha * 0.8);
          canvas.drawCircle(Offset(dotX, dotY), 2, _minimapDataPaint);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: TOWER MARKERS
    // ═══════════════════════════════════════════════════════════════════════
    for (final tower in towers) {
      final towerX = offsetX + tower.position.x * scale;
      final towerY = offsetY + tower.position.y * scale;

      // Tower range indicator (subtle)
      final rangeRadius = tower.range * scale * 0.5;
      _minimapPulsePaint.color = tower.color.withOpacity(0.1);
      canvas.drawCircle(
          Offset(towerX, towerY), rangeRadius, _minimapPulsePaint);

      // Tower glow
      _minimapTowerPaint.color = tower.color.withOpacity(0.7);
      canvas.drawCircle(Offset(towerX, towerY), 3.5, _minimapTowerPaint);

      // Tower core
      _minimapDataPaint.color = Colors.white.withOpacity(0.9);
      canvas.drawCircle(Offset(towerX, towerY), 1.5, _minimapDataPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: ENEMY MARKERS (Real-time tracking)
    // ═══════════════════════════════════════════════════════════════════════
    for (final enemy in enemies) {
      final enemyX = offsetX + enemy.position.x * scale;
      final enemyY = offsetY + enemy.position.y * scale;

      // Enemy glow based on health
      final healthFactor = enemy.healthPercent;
      final enemyAlpha = 0.5 + (1 - healthFactor) * 0.4;

      _minimapEnemyPaint.color = enemy.type.color.withOpacity(enemyAlpha);
      canvas.drawCircle(Offset(enemyX, enemyY), 2.5, _minimapEnemyPaint);

      // Direction indicator (small line showing movement direction)
      if (enemy.speed > 0) {
        final dir = enemy.movementDirection;
        _minimapDataPaint.color = enemy.type.color.withOpacity(0.6);
        _minimapDataPaint.strokeWidth = 1;
        canvas.drawLine(
          Offset(enemyX, enemyY),
          Offset(enemyX + dir.x * 4, enemyY + dir.y * 4),
          _minimapDataPaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: BASE MARKER (Pulsing target)
    // ═══════════════════════════════════════════════════════════════════════
    final baseX = offsetX + basePos.x * scale;
    final baseY = offsetY + basePos.y * scale;
    final basePulse = 0.7 + math.sin(animPhase * 4) * 0.3;

    // Base glow rings
    for (int i = 0; i < 3; i++) {
      final ringPhase = (animPhase * 2 + i * 0.4) % 1.0;
      final ringRadius = 4 + ringPhase * 6;
      final ringAlpha = (1 - ringPhase) * 0.4;
      _minimapPulsePaint.color = NeonTheme.cyberGreen.withOpacity(ringAlpha);
      canvas.drawCircle(Offset(baseX, baseY), ringRadius, _minimapPulsePaint);
    }

    // Base core
    _minimapBasePaint.color = NeonTheme.cyberGreen.withOpacity(basePulse);
    canvas.drawCircle(Offset(baseX, baseY), 4, _minimapBasePaint);
    _minimapDataPaint.color = Colors.white;
    canvas.drawCircle(Offset(baseX, baseY), 2, _minimapDataPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: RADAR SCAN SWEEP
    // ═══════════════════════════════════════════════════════════════════════
    final scanCenterX = minimapRect.center.dx;
    final scanCenterY = minimapRect.center.dy;
    final scanRadius = minimapSize / 2 - minimapPadding;

    // Draw scan line
    final scanEndX = scanCenterX + math.cos(_minimapScanAngle) * scanRadius;
    final scanEndY = scanCenterY + math.sin(_minimapScanAngle) * scanRadius;

    _minimapScanPaint.color = NeonTheme.cyberCyan.withOpacity(0.4);
    canvas.drawLine(
      Offset(scanCenterX, scanCenterY),
      Offset(scanEndX, scanEndY),
      _minimapScanPaint,
    );

    // Scan trail (fading arc behind the scan line)
    _minimapPath.reset();
    _minimapPath.moveTo(scanCenterX, scanCenterY);
    for (int i = 0; i <= 20; i++) {
      final trailAngle = _minimapScanAngle - (i / 20) * (math.pi / 3);
      final trailAlpha = (1 - i / 20) * 0.15;
      final trailX = scanCenterX + math.cos(trailAngle) * scanRadius;
      final trailY = scanCenterY + math.sin(trailAngle) * scanRadius;

      if (i == 0) {
        _minimapPath.lineTo(trailX, trailY);
      } else {
        _minimapPath.lineTo(trailX, trailY);
      }
    }
    _minimapPath.close();

    _minimapScanPaint.color = NeonTheme.cyberCyan.withOpacity(0.08);
    canvas.drawPath(_minimapPath, _minimapScanPaint);

    canvas.restore(); // Restore clip

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 8: BORDER AND CORNER ACCENTS
    // ═══════════════════════════════════════════════════════════════════════
    _minimapBorderPaint.color = NeonTheme.cyberCyan.withOpacity(0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(minimapRect, const Radius.circular(6)),
      _minimapBorderPaint,
    );

    // Tech corners
    final cornerLen = 12.0;
    _minimapCornerPaint.color = NeonTheme.cyberCyan.withOpacity(0.9);

    // Top-left corner
    canvas.drawLine(
      Offset(minimapRect.left, minimapRect.top + cornerLen),
      Offset(minimapRect.left, minimapRect.top),
      _minimapCornerPaint,
    );
    canvas.drawLine(
      Offset(minimapRect.left, minimapRect.top),
      Offset(minimapRect.left + cornerLen, minimapRect.top),
      _minimapCornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(minimapRect.right - cornerLen, minimapRect.top),
      Offset(minimapRect.right, minimapRect.top),
      _minimapCornerPaint,
    );
    canvas.drawLine(
      Offset(minimapRect.right, minimapRect.top),
      Offset(minimapRect.right, minimapRect.top + cornerLen),
      _minimapCornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(minimapRect.left, minimapRect.bottom - cornerLen),
      Offset(minimapRect.left, minimapRect.bottom),
      _minimapCornerPaint,
    );
    canvas.drawLine(
      Offset(minimapRect.left, minimapRect.bottom),
      Offset(minimapRect.left + cornerLen, minimapRect.bottom),
      _minimapCornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(minimapRect.right - cornerLen, minimapRect.bottom),
      Offset(minimapRect.right, minimapRect.bottom),
      _minimapCornerPaint,
    );
    canvas.drawLine(
      Offset(minimapRect.right, minimapRect.bottom),
      Offset(minimapRect.right, minimapRect.bottom - cornerLen),
      _minimapCornerPaint,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 9: MINIMAP LABEL
    // ═══════════════════════════════════════════════════════════════════════
    final labelY = minimapRect.top - 14;
    _minimapDataPaint.color = NeonTheme.cyberCyan.withOpacity(0.7);
    _minimapDataPaint.strokeWidth = 1;

    // Small "TACTICAL" text indicator (draw as lines to avoid TextPainter overhead)
    final labelX = minimapRect.left + 4;
    // T
    canvas.drawLine(
        Offset(labelX, labelY), Offset(labelX + 4, labelY), _minimapDataPaint);
    canvas.drawLine(Offset(labelX + 2, labelY), Offset(labelX + 2, labelY + 5),
        _minimapDataPaint);
    // A
    canvas.drawLine(Offset(labelX + 6, labelY + 5), Offset(labelX + 8, labelY),
        _minimapDataPaint);
    canvas.drawLine(Offset(labelX + 8, labelY), Offset(labelX + 10, labelY + 5),
        _minimapDataPaint);
    canvas.drawLine(Offset(labelX + 7, labelY + 3),
        Offset(labelX + 9, labelY + 3), _minimapDataPaint);
    // C
    canvas.drawLine(Offset(labelX + 14, labelY), Offset(labelX + 12, labelY),
        _minimapDataPaint);
    canvas.drawLine(Offset(labelX + 12, labelY),
        Offset(labelX + 12, labelY + 5), _minimapDataPaint);
    canvas.drawLine(Offset(labelX + 12, labelY + 5),
        Offset(labelX + 14, labelY + 5), _minimapDataPaint);

    // Entity count indicator
    final entityCount = enemies.length;
    if (entityCount > 0) {
      final countX = minimapRect.right - 25;
      final countPulse = math.sin(animPhase * 3) * 0.2 + 0.8;
      _minimapDataPaint.color = NeonTheme.cyberMagenta.withOpacity(countPulse);

      // Draw count as small dots (up to 10)
      final dotCount = math.min(entityCount, 10);
      for (int i = 0; i < dotCount; i++) {
        canvas.drawCircle(
          Offset(countX + (i % 5) * 4, labelY + (i ~/ 5) * 4 + 1),
          1,
          _minimapDataPaint,
        );
      }
      if (entityCount > 10) {
        // Plus indicator for > 10 enemies
        canvas.drawLine(
          Offset(countX + 22, labelY + 2),
          Offset(countX + 26, labelY + 2),
          _minimapDataPaint,
        );
        canvas.drawLine(
          Offset(countX + 24, labelY),
          Offset(countX + 24, labelY + 4),
          _minimapDataPaint,
        );
      }
    }
  }

  /// Draw a small hexagon for the minimap grid
  void _drawMiniHex(
      Canvas canvas, double cx, double cy, double radius, Paint paint) {
    _minimapPath.reset();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        _minimapPath.moveTo(x, y);
      } else {
        _minimapPath.lineTo(x, y);
      }
    }
    _minimapPath.close();
    canvas.drawPath(_minimapPath, paint);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GLITCH DISTORTION EFFECT (Wave transitions)
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawGlitchDistortionEffect(
      Canvas canvas, double screenWidth, double screenHeight) {
    final t = (_waveTransitionTimer / _waveTransitionDuration).clamp(0.0, 1.0);

    // Flash intensity - peaks early then fades
    double flashAlpha = 0.0;
    if (t < 0.1) {
      flashAlpha = (t / 0.1) * 0.6;
    } else if (t < 0.25) {
      flashAlpha = 0.6 - ((t - 0.1) / 0.15) * 0.5;
    } else if (t < 0.5) {
      flashAlpha = 0.1 - ((t - 0.25) / 0.25) * 0.1;
    }

    // Glitch intensity - highest in the middle of transition
    final glitchIntensity = t < 0.5 ? t * 2 : (1 - t) * 2;
    final isGlitching = _glitchNextUnit() < glitchIntensity * 0.8;

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: CHROMATIC ABERRATION (RGB SPLIT)
    // ═══════════════════════════════════════════════════════════════════════
    if (glitchIntensity > 0.2 && isGlitching) {
      final chromaOffset = glitchIntensity * 8;

      // Red channel shift - left
      _glitchRedPaint.color =
          const Color(0xFFFF0044).withOpacity(glitchIntensity * 0.15);
      canvas.save();
      canvas.translate(-chromaOffset, 0);
      canvas.drawRect(
          Rect.fromLTWH(0, 0, screenWidth, screenHeight), _glitchRedPaint);
      canvas.restore();

      // Cyan channel shift - right
      _glitchCyanPaint.color =
          const Color(0xFF00FFFF).withOpacity(glitchIntensity * 0.15);
      canvas.save();
      canvas.translate(chromaOffset, 0);
      canvas.drawRect(
          Rect.fromLTWH(0, 0, screenWidth, screenHeight), _glitchCyanPaint);
      canvas.restore();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: HORIZONTAL DISPLACEMENT GLITCH BLOCKS
    // ═══════════════════════════════════════════════════════════════════════
    if (glitchIntensity > 0.3) {
      final blockCount = (glitchIntensity * 6).round();
      for (int i = 0; i < blockCount; i++) {
        if (_glitchNextUnit() > 0.5) continue; // Random skip

        final blockY = _glitchNextUnit() * screenHeight;
        final blockHeight = 2 + _glitchNextUnit() * 15;
        final displacement = (_glitchNextUnit() - 0.5) * 30 * glitchIntensity;

        // Draw displaced block with color tint
        final blockColor = _glitchNextBool()
            ? const Color(0xFFFF0066)
            : const Color(0xFF00FFFF);

        _glitchBlockPaint.color = blockColor.withOpacity(glitchIntensity * 0.3);
        canvas.drawRect(
          Rect.fromLTWH(displacement, blockY, screenWidth, blockHeight),
          _glitchBlockPaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: DIGITAL NOISE BLOCKS
    // ═══════════════════════════════════════════════════════════════════════
    if (glitchIntensity > 0.4 && isGlitching) {
      final noiseCount = (glitchIntensity * 20).round();
      for (int i = 0; i < noiseCount; i++) {
        final noiseX = _glitchNextUnit() * screenWidth;
        final noiseY = _glitchNextUnit() * screenHeight;
        final noiseW = 5 + _glitchNextUnit() * 25;
        final noiseH = 2 + _glitchNextUnit() * 8;

        final noiseColor = _glitchNextUnit() < 0.3
            ? Colors.white
            : (_glitchNextBool()
                ? const Color(0xFFFF0066)
                : const Color(0xFF00FFFF));

        _glitchNoisePaint.color = noiseColor.withOpacity(glitchIntensity * 0.5);
        canvas.drawRect(
            Rect.fromLTWH(noiseX, noiseY, noiseW, noiseH), _glitchNoisePaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: SCANLINE DISTORTION
    // ═══════════════════════════════════════════════════════════════════════
    if (glitchIntensity > 0.15) {
      final scanlineSpacing = 3.0;
      final scanlineCount = (screenHeight / scanlineSpacing).round();

      for (int i = 0; i < scanlineCount; i++) {
        final y = i * scanlineSpacing;
        final jitter = isGlitching && _glitchNextUnit() < 0.1
            ? (_glitchNextUnit() - 0.5) * 10 * glitchIntensity
            : 0.0;

        final scanAlpha =
            (0.03 + math.sin(_time * 30 + i * 0.1) * 0.02) * glitchIntensity;
        _glitchScanlinePaint.color = Colors.black.withOpacity(scanAlpha);
        canvas.drawLine(
          Offset(jitter, y),
          Offset(screenWidth + jitter, y),
          _glitchScanlinePaint,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: STATIC NOISE LINES
    // ═══════════════════════════════════════════════════════════════════════
    if (glitchIntensity > 0.5 && isGlitching) {
      final staticLineCount = (glitchIntensity * 15).round();
      for (int i = 0; i < staticLineCount; i++) {
        final y = _glitchNextUnit() * screenHeight;
        final startX = _glitchNextUnit() * screenWidth * 0.3;
        final endX = startX + _glitchNextUnit() * screenWidth * 0.7;

        _glitchStaticPaint.color =
            Colors.white.withOpacity(glitchIntensity * 0.4);
        canvas.drawLine(Offset(startX, y), Offset(endX, y), _glitchStaticPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: MAIN FLASH EFFECT (from original)
    // ═══════════════════════════════════════════════════════════════════════
    if (flashAlpha > 0.01) {
      // White core flash
      _glitchFlashPaint.color = Colors.white.withOpacity(flashAlpha * 0.5);
      canvas.drawRect(
          Rect.fromLTWH(0, 0, screenWidth, screenHeight), _glitchFlashPaint);

      // Cyberpunk color overlay
      final colorFlash = t < 0.15
          ? const Color(0xFF00FFFF).withOpacity(flashAlpha * 0.3)
          : const Color(0xFFFF00FF).withOpacity(flashAlpha * 0.2);
      _colorFlashPaint.color = colorFlash;
      canvas.drawRect(
          Rect.fromLTWH(0, 0, screenWidth, screenHeight), _colorFlashPaint);

      // Animated scan lines
      if (t < 0.3) {
        for (int i = 0; i < 8; i++) {
          final scanY =
              (screenHeight / 8) * i + (_time * 500 % (screenHeight / 8));
          _glitchLinePaint.color =
              const Color(0xFF00FFFF).withOpacity(flashAlpha * 0.4);
          canvas.drawLine(
              Offset(0, scanY), Offset(screenWidth, scanY), _glitchLinePaint);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: GLITCH EDGE DISTORTION
    // ═══════════════════════════════════════════════════════════════════════
    if (t < 0.4) {
      final edgeAlpha = t < 0.1 ? (t / 0.1) : (1 - (t - 0.1) / 0.3);
      final edgeJitter = isGlitching ? (_glitchNextUnit() - 0.5) * 5 : 0.0;

      // Glitched border edges
      _glitchEdgePaint.color =
          const Color(0xFFFF00FF).withOpacity(edgeAlpha * 0.6);

      // Top edge with jitter
      canvas.drawLine(
        Offset(edgeJitter, 2),
        Offset(screenWidth + edgeJitter, 2),
        _glitchEdgePaint,
      );

      // Bottom edge
      canvas.drawLine(
        Offset(-edgeJitter, screenHeight - 2),
        Offset(screenWidth - edgeJitter, screenHeight - 2),
        _glitchEdgePaint,
      );

      // Cyan secondary edges
      _glitchEdgePaint.color =
          const Color(0xFF00FFFF).withOpacity(edgeAlpha * 0.4);
      canvas.drawLine(Offset(2, 0), Offset(2, screenHeight), _glitchEdgePaint);
      canvas.drawLine(Offset(screenWidth - 2, 0),
          Offset(screenWidth - 2, screenHeight), _glitchEdgePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 8: DATA CORRUPTION VISUAL (random "data" characters)
    // ═══════════════════════════════════════════════════════════════════════
    if (glitchIntensity > 0.6 && isGlitching) {
      final dataCount = (glitchIntensity * 8).round();
      for (int i = 0; i < dataCount; i++) {
        final dataX = _glitchNextUnit() * screenWidth;
        final dataY = _glitchNextUnit() * screenHeight;
        final dataLength = 3 + _glitchNextInt(8);

        _glitchDataPaint.color =
            const Color(0xFF00FF00).withOpacity(glitchIntensity * 0.4);

        // Draw small data blips
        for (int j = 0; j < dataLength; j++) {
          final blipX = dataX + j * 4;
          final blipHeight = 2 + _glitchNextUnit() * 6;
          canvas.drawLine(
            Offset(blipX, dataY),
            Offset(blipX, dataY + blipHeight),
            _glitchDataPaint,
          );
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 9: WAVE NUMBER GLITCH EFFECT
    // ═══════════════════════════════════════════════════════════════════════
    if (glitchIntensity > 0.3) {
      final waveNum = gameRef.enemyManager.currentWave.toString();
      final centerX = screenWidth / 2;
      final centerY = screenHeight / 2;

      // Glitched wave number - RGB split
      final textGlitchOffset = glitchIntensity * 4;

      // Red shadow
      final redPainter = _getPainter(
        'glitch-wave-red-$waveNum',
        'WAVE $waveNum',
        TextStyle(
          color: const Color(0xFFFF0044).withOpacity(glitchIntensity * 0.5),
          fontSize: 40 + glitchIntensity * 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      );
      redPainter.paint(
        canvas,
        Offset(centerX - redPainter.width / 2 - textGlitchOffset,
            centerY - redPainter.height / 2),
      );

      // Cyan shadow
      final cyanPainter = _getPainter(
        'glitch-wave-cyan-$waveNum',
        'WAVE $waveNum',
        TextStyle(
          color: const Color(0xFF00FFFF).withOpacity(glitchIntensity * 0.5),
          fontSize: 40 + glitchIntensity * 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      );
      cyanPainter.paint(
        canvas,
        Offset(centerX - cyanPainter.width / 2 + textGlitchOffset,
            centerY - cyanPainter.height / 2),
      );

      // Main text
      final mainPainter = _getPainter(
        'glitch-wave-main-$waveNum',
        'WAVE $waveNum',
        TextStyle(
          color: Colors.white.withOpacity(glitchIntensity * 0.8),
          fontSize: 40 + glitchIntensity * 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          shadows: [
            Shadow(color: const Color(0xFFFF00FF), blurRadius: 15),
            Shadow(color: const Color(0xFF00FFFF), blurRadius: 25),
          ],
        ),
      );
      mainPainter.paint(
        canvas,
        Offset(
            centerX - mainPainter.width / 2, centerY - mainPainter.height / 2),
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 10: VIGNETTE PULSE
    // ═══════════════════════════════════════════════════════════════════════
    if (glitchIntensity > 0.2) {
      final vignetteAlpha = glitchIntensity * 0.3;
      final vignetteGradient = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.transparent,
          const Color(0xFFFF00FF).withOpacity(vignetteAlpha),
          Colors.black.withOpacity(vignetteAlpha * 2),
        ],
        stops: const [0.0, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, screenWidth, screenHeight));

      _vignettePaint.shader = vignetteGradient;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, screenWidth, screenHeight),
        _vignettePaint,
      );
    }
  }

  void _drawFocusTimerOverlay(
      Canvas canvas, double screenWidth, double screenHeight) {
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
      _focusTimerBgPaint,
    );

    final color = gameRef.focusTower?.color ?? const Color(0xFF00FFFF);
    _focusTimerFillPaint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(x, y, barWidth * progress, barHeight),
      _focusTimerFillPaint,
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
    labelPainter.paint(
        canvas, Offset(x + (barWidth - labelPainter.width) / 2, y - 14));
  }

  void _drawAbilityTargetHint(Canvas canvas, double screenHeight) {
    final pending = gameRef.pendingAbility;
    if (pending == PendingAbility.none) return;

    final isTouch = gameRef.isTouchLayout;
    final label = switch (pending) {
      PendingAbility.pulse => isTouch ? 'TOCA EL CAMPO' : 'CLICK EL CAMPO',
      PendingAbility.mine => isTouch ? 'TOCA EL CAMINO' : 'CLICK EL CAMINO',
      PendingAbility.none => '',
    };
    if (label.isEmpty) return;

    final color = pending == PendingAbility.pulse
        ? const Color(0xFF00FFFF)
        : const Color(0xFFFF0066);
    final button =
        pending == PendingAbility.pulse ? pulseAbilityBtn : mineAbilityBtn;

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
    _abilityHintBgPaint.color = Colors.black.withOpacity(0.6);
    canvas.drawRRect(rect, _abilityHintBgPaint);
    _abilityHintBorderPaint.color = color.withOpacity(0.4);
    canvas.drawRRect(rect, _abilityHintBorderPaint);
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
    if (_topPanelRect != panelRect) {
      _topPanelRect = panelRect;
      _topPanelShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF000000).withOpacity(0.9),
          const Color(0xFF000000).withOpacity(0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(panelRect);
    }
    _panelPaint.shader = _topPanelShader;
    canvas.drawRect(panelRect, _panelPaint);
    _panelPaint.shader = null;

    // ═══ LEFT SIDE: Gold & Lives (horizontal layout) ═══
    _drawCompactStat(
        canvas, 16, 14, 'GOLD', '${gameRef.gold}', const Color(0xFFFFD700));
    _drawCompactStat(
        canvas, 110, 14, 'LIVES', '${gameRef.lives}', const Color(0xFFFF4466));

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
    scorePainter.paint(
        canvas, Offset(screenWidth - scorePainter.width - 16, 8));

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
    scoreLabelPainter.paint(
        canvas, Offset(screenWidth - scorePainter.width - 16, 32));

    // ═══ WAVE INDICATOR - Below top bar, centered ═══
    _drawWaveIndicator(canvas, screenWidth);

    // Wave alert (if active)
    _drawWaveAlert(canvas, screenWidth);
  }

  /// Compact stat display for top bar (horizontal)
  void _drawCompactStat(Canvas canvas, double x, double y, String label,
      String value, Color color) {
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
      _speedBgPaint.color = bgColor;
      canvas.drawRRect(rrect, _speedBgPaint);

      // Border
      final borderColor = isActive
          ? const Color(0xFF00FF88).withOpacity(0.8)
          : Colors.white.withOpacity(0.2);
      _speedBorderPaint
        ..color = borderColor
        ..strokeWidth = isActive ? 1.5 : 1;
      canvas.drawRRect(rrect, _speedBorderPaint);

      // Glow when active
      if (isActive) {
        _speedGlowPaint.color = const Color(0xFF00FF88).withOpacity(0.3);
        canvas.drawRRect(rrect.inflate(2), _speedGlowPaint);
      }

      // Label
      final label = '${speed.toInt()}x';
      final labelPainter = _getPainter(
        'speed-$label-$isActive',
        label,
        TextStyle(
          color: isActive
              ? const Color(0xFF00FF88)
              : Colors.white.withOpacity(0.5),
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

    if (_speed1xRect != null &&
        _speed1xRect!.contains(Offset(tapPosition.x, tapPosition.y))) {
      gameRef.timeScale = speedOptions[0];
      return true;
    }
    if (_speed2xRect != null &&
        _speed2xRect!.contains(Offset(tapPosition.x, tapPosition.y))) {
      gameRef.timeScale = speedOptions[1];
      return true;
    }
    return false;
  }

  void _drawModernStat(Canvas canvas, double x, double y, String label,
      String value, Color color, IconData icon) {
    // Glowing background pill
    final pillWidth = 100.0;
    final pillHeight = 24.0;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, pillWidth, pillHeight),
      const Radius.circular(12),
    );

    // Background with color tint
    _statPillBgPaint.color = color.withOpacity(0.15);
    canvas.drawRRect(pillRect, _statPillBgPaint);

    // Border glow
    _statPillBorderPaint.color = color.withOpacity(0.4);
    canvas.drawRRect(pillRect, _statPillBorderPaint);

    // Icon circle
    _statPillIconOuterPaint.color = color.withOpacity(0.3);
    canvas.drawCircle(
      Offset(x + 14, y + pillHeight / 2),
      8,
      _statPillIconOuterPaint,
    );
    canvas.drawCircle(
      Offset(x + 14, y + pillHeight / 2),
      4,
      _statPillIconInnerPaint..color = color,
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
    valuePainter.paint(
        canvas, Offset(x + 28, y + (pillHeight - valuePainter.height) / 2));
  }

  void _drawWaveIndicator(Canvas canvas, double screenWidth) {
    final centerX = screenWidth / 2;
    final currentWave = gameRef.enemyManager.currentWave;
    final totalWaves = gameRef.totalWaves <= 0 ? 1 : gameRef.totalWaves;
    final waveProgress = gameRef.enemyManager.waveProgress.clamp(0.0, 1.0);
    final isSpawning = gameRef.enemyManager.spawning;
    final enemiesAlive = gameRef.enemyManager.aliveCount;
    final bossActive = gameRef.enemyManager.currentBoss != null;
    final compactWave =
        _isCompactHud(screenWidth, gameRef.size.y) || gameRef.size.y < 720;

    if (bossActive || compactWave) {
      _drawCompactWaveIndicator(
        canvas,
        currentWave,
        totalWaves,
        isSpawning,
        enemiesAlive,
      );
      return;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ════════════════════════════════════════════════════════════════════════════
    // CYBERPUNK WAVE INDICATOR - Enhanced Design
    // ════════════════════════════════════════════════════════════════════════════

    // Animation calculations
    double transitionScale = 1.0;
    double shakeX = 0.0;
    double shakeY = 0.0;
    if (_waveTransitionActive) {
      final t =
          (_waveTransitionTimer / _waveTransitionDuration).clamp(0.0, 1.0);
      if (t < 0.2) {
        transitionScale = 1.0 + (t / 0.2) * 0.35;
        shakeX = math.sin(t * 60) * 5 * (1 - t / 0.2);
        shakeY = math.cos(t * 40) * 3 * (1 - t / 0.2);
      } else {
        transitionScale = 1.35 - ((t - 0.2) / 0.8) * 0.35;
      }
    }

    // Dynamic colors based on state
    const cyanColor = Color(0xFF00FFFF);
    const magentaColor = Color(0xFFFF00FF);
    const goldColor = Color(0xFFFFD700);
    final primaryColor = isSpawning ? magentaColor : cyanColor;
    final secondaryColor = Color.lerp(primaryColor, Colors.white, 0.3)!;
    final pulseIntensity = 0.3 + math.sin(_time * 2.5) * 0.15;

    // Container dimensions
    const containerWidth = 180.0;
    const containerHeight = 68.0;
    final containerX = centerX - containerWidth / 2;
    const containerY = 48.0;

    // ═══ HEXAGONAL CYBERPUNK FRAME ═══
    final framePath = _waveIndicatorFramePath..reset();
    const cut = 14.0;
    const innerCut = 6.0;
    framePath.moveTo(containerX + cut, containerY);
    framePath.lineTo(containerX + containerWidth - cut, containerY);
    framePath.lineTo(containerX + containerWidth, containerY + cut);
    framePath.lineTo(
        containerX + containerWidth, containerY + containerHeight - cut);
    framePath.lineTo(
        containerX + containerWidth - cut, containerY + containerHeight);
    framePath.lineTo(containerX + cut, containerY + containerHeight);
    framePath.lineTo(containerX, containerY + containerHeight - cut);
    framePath.lineTo(containerX, containerY + cut);
    framePath.close();

    // Multi-layer background with depth
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF08081a).withOpacity(0.96),
        const Color(0xFF0c0418).withOpacity(0.94),
        const Color(0xFF100820).withOpacity(0.92),
      ],
    ).createShader(
        Rect.fromLTWH(containerX, containerY, containerWidth, containerHeight));
    _waveIndicatorBgPaint.shader = bgGradient;
    canvas.drawPath(framePath, _waveIndicatorBgPaint);

    // Outer glow (pulsing)
    _waveIndicatorGlowPaint.color = primaryColor.withOpacity(pulseIntensity);
    canvas.drawPath(framePath, _waveIndicatorGlowPaint);

    // Inner glow layer
    _waveIndicatorInnerGlowPaint.color = primaryColor.withOpacity(0.12);
    canvas.drawPath(framePath, _waveIndicatorInnerGlowPaint);

    // Animated scanline effect
    final scanY = containerY + ((_time * 30) % containerHeight);
    _waveIndicatorScanlinePaint.color = primaryColor.withOpacity(0.06);
    canvas.drawRect(
      Rect.fromLTWH(containerX + 2, scanY, containerWidth - 4, 2),
      _waveIndicatorScanlinePaint,
    );

    // Main border
    _waveIndicatorBorderPaint.color = primaryColor.withOpacity(0.7);
    canvas.drawPath(framePath, _waveIndicatorBorderPaint);

    // ═══ CORNER ACCENTS (Cyberpunk style) ═══
    _waveIndicatorCornerPaint.color = secondaryColor.withOpacity(0.9);

    // Top-left corner
    canvas.drawLine(
      Offset(containerX + cut, containerY),
      Offset(containerX + cut + 16, containerY),
      _waveIndicatorCornerPaint,
    );
    canvas.drawLine(
      Offset(containerX, containerY + cut),
      Offset(containerX, containerY + cut + 12),
      _waveIndicatorCornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(containerX + containerWidth - cut - 16, containerY),
      Offset(containerX + containerWidth - cut, containerY),
      _waveIndicatorCornerPaint,
    );
    canvas.drawLine(
      Offset(containerX + containerWidth, containerY + cut),
      Offset(containerX + containerWidth, containerY + cut + 12),
      _waveIndicatorCornerPaint,
    );

    // Bottom corners
    canvas.drawLine(
      Offset(containerX + cut, containerY + containerHeight),
      Offset(containerX + cut + 16, containerY + containerHeight),
      _waveIndicatorCornerPaint,
    );
    canvas.drawLine(
      Offset(
          containerX + containerWidth - cut - 16, containerY + containerHeight),
      Offset(containerX + containerWidth - cut, containerY + containerHeight),
      _waveIndicatorCornerPaint,
    );

    // ═══ LEFT ACCENT BAR (Animated) ═══
    final barPulse = 0.7 + math.sin(_time * 3) * 0.3;
    _waveIndicatorAccentPaint
      ..color = primaryColor.withOpacity(barPulse)
      ..strokeWidth = 4;
    canvas.drawLine(
      Offset(containerX + 12, containerY + 16),
      Offset(containerX + 12, containerY + containerHeight - 16),
      _waveIndicatorAccentPaint,
    );

    // ═══ RIGHT ACCENT BAR ═══
    _waveIndicatorAccentPaint.color = primaryColor.withOpacity(0.5);
    canvas.drawLine(
      Offset(containerX + containerWidth - 12, containerY + 16),
      Offset(
          containerX + containerWidth - 12, containerY + containerHeight - 16),
      _waveIndicatorAccentPaint,
    );

    // ═══ WAVE NUMBER (Big, Bold, Glowing) ═══
    final waveText = '$currentWave';
    final numberY = containerY + 6;

    canvas.save();
    canvas.translate(centerX + shakeX, numberY + 18 + shakeY);
    canvas.scale(transitionScale, transitionScale);
    canvas.translate(-(centerX + shakeX), -(numberY + 18 + shakeY));

    final wavePainter = _getPainter(
      'wave-num-cyber-$waveText-$isSpawning',
      waveText,
      TextStyle(
        color: Colors.white,
        fontSize: 40,
        fontWeight: FontWeight.w900,
        fontFamily: 'monospace',
        shadows: [
          Shadow(color: primaryColor, blurRadius: 20),
          Shadow(color: primaryColor.withOpacity(0.7), blurRadius: 40),
          Shadow(color: primaryColor.withOpacity(0.3), blurRadius: 60),
        ],
      ),
    );
    wavePainter.paint(canvas, Offset(centerX - wavePainter.width / 2, numberY));
    canvas.restore();

    // ═══ WAVE LABEL ═══
    final labelPainter = _getPainter(
      'wave-label-cyber',
      '◆ WAVE ◆',
      TextStyle(
        color: secondaryColor.withOpacity(0.7),
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.5,
        fontFamily: 'monospace',
      ),
    );
    labelPainter.paint(
        canvas, Offset(centerX - labelPainter.width / 2, containerY + 4));

    // ═══ SUBTITLE WITH PROGRESS ═══
    final subtitleY = containerY + 48;
    final subtitleText = '$currentWave / $totalWaves';
    final subtitlePainter = _getPainter(
      'wave-subtitle-cyber-$currentWave-$totalWaves',
      subtitleText,
      TextStyle(
        color: primaryColor.withOpacity(0.9),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
        fontFamily: 'monospace',
      ),
    );
    subtitlePainter.paint(
        canvas, Offset(centerX - subtitlePainter.width / 2, subtitleY));

    // ═══ PROGRESS BAR (Enhanced) ═══
    const barWidth = 150.0;
    const progressBarHeight = 4.0;
    final barX = centerX - barWidth / 2;
    final barY = containerY + containerHeight - 10;

    // Background with inner shadow effect
    _waveIndicatorProgressBgPaint.color = Colors.white.withOpacity(0.08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, progressBarHeight),
        const Radius.circular(2),
      ),
      _waveIndicatorProgressBgPaint,
    );

    // Progress fill with gradient
    if (waveProgress > 0) {
      final fillWidth = barWidth * waveProgress;
      final fillGradient = LinearGradient(
        colors: [cyanColor, magentaColor, goldColor],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(barX, barY, fillWidth, progressBarHeight));

      _waveIndicatorProgressFillPaint.shader = fillGradient;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, fillWidth, progressBarHeight),
          const Radius.circular(2),
        ),
        _waveIndicatorProgressFillPaint,
      );

      // Glow effect on progress
      _waveIndicatorProgressGlowPaint.shader = fillGradient;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY - 1, fillWidth, progressBarHeight + 2),
          const Radius.circular(2),
        ),
        _waveIndicatorProgressGlowPaint,
      );

      // Progress tip glow
      if (fillWidth > 4) {
        _waveIndicatorTipPaint.color =
            Colors.white.withOpacity(0.8 * pulseIntensity);
        canvas.drawCircle(
          Offset(barX + fillWidth, barY + progressBarHeight / 2),
          4,
          _waveIndicatorTipPaint,
        );
      }
    }

    // ═══ ENEMY COUNT (Enhanced) ═══
    if (isSpawning && enemiesAlive > 0) {
      final enemyText = '$enemiesAlive';
      final urgentColor = enemiesAlive > 20
          ? const Color(0xFFFF0044)
          : (enemiesAlive > 10 ? const Color(0xFFFFFF00) : magentaColor);

      // Enemy count panel (right side)
      final enemyPanelX = containerX + containerWidth + 10;
      final enemyPanelY = containerY + containerHeight / 2 - 14;
      const enemyPanelWidth = 36.0;
      const enemyPanelHeight = 28.0;

      // Mini panel background
      final enemyPanelPath = _waveIndicatorEnemyPanelPath..reset();
      const miniCut = 5.0;
      enemyPanelPath.moveTo(enemyPanelX + miniCut, enemyPanelY);
      enemyPanelPath.lineTo(
          enemyPanelX + enemyPanelWidth - miniCut, enemyPanelY);
      enemyPanelPath.lineTo(
          enemyPanelX + enemyPanelWidth, enemyPanelY + miniCut);
      enemyPanelPath.lineTo(enemyPanelX + enemyPanelWidth,
          enemyPanelY + enemyPanelHeight - miniCut);
      enemyPanelPath.lineTo(enemyPanelX + enemyPanelWidth - miniCut,
          enemyPanelY + enemyPanelHeight);
      enemyPanelPath.lineTo(
          enemyPanelX + miniCut, enemyPanelY + enemyPanelHeight);
      enemyPanelPath.lineTo(
          enemyPanelX, enemyPanelY + enemyPanelHeight - miniCut);
      enemyPanelPath.lineTo(enemyPanelX, enemyPanelY + miniCut);
      enemyPanelPath.close();

      _waveIndicatorEnemyPanelBgPaint.color =
          const Color(0xFF0a0a18).withOpacity(0.9);
      canvas.drawPath(enemyPanelPath, _waveIndicatorEnemyPanelBgPaint);
      _waveIndicatorEnemyPanelBorderPaint.color = urgentColor.withOpacity(0.6);
      canvas.drawPath(enemyPanelPath, _waveIndicatorEnemyPanelBorderPaint);

      // Enemy indicator dot
      _waveIndicatorEnemyGlowPaint.color = urgentColor.withOpacity(0.5);
      canvas.drawCircle(
        Offset(enemyPanelX + 8, enemyPanelY + enemyPanelHeight / 2),
        4,
        _waveIndicatorEnemyGlowPaint,
      );
      _waveIndicatorEnemyDotPaint.color = urgentColor;
      canvas.drawCircle(
        Offset(enemyPanelX + 8, enemyPanelY + enemyPanelHeight / 2),
        2.5,
        _waveIndicatorEnemyDotPaint,
      );

      // Enemy count text
      final enemyPainter = _getPainter(
        'wave-enemies-cyber-$enemiesAlive',
        enemyText,
        TextStyle(
          color: urgentColor,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          shadows: [Shadow(color: urgentColor, blurRadius: 6)],
        ),
      );
      enemyPainter.paint(
        canvas,
        Offset(enemyPanelX + 16,
            enemyPanelY + (enemyPanelHeight - enemyPainter.height) / 2),
      );
    }

    // ═══ WAVE TRANSITION EFFECT ═══
    if (_waveTransitionActive) {
      final t =
          (_waveTransitionTimer / _waveTransitionDuration).clamp(0.0, 1.0);
      final transitionAlpha = t < 0.4 ? t * 2.5 : (1 - t) * 1.67;
      if (transitionAlpha > 0.05) {
        // "INCOMING" text with dramatic effect
        final incomingPainter = _getPainter(
          'wave-incoming-cyber',
          '▶ WAVE INCOMING ◀',
          TextStyle(
            color: magentaColor.withOpacity(transitionAlpha * 0.9),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontFamily: 'monospace',
            shadows: [
              Shadow(
                  color: magentaColor.withOpacity(transitionAlpha * 0.7),
                  blurRadius: 10),
              Shadow(
                  color: magentaColor.withOpacity(transitionAlpha * 0.4),
                  blurRadius: 20),
            ],
          ),
        );
        incomingPainter.paint(
          canvas,
          Offset(centerX - incomingPainter.width / 2,
              containerY + containerHeight + 14),
        );

        // Extra glow burst during transition
        if (t < 0.3) {
          final burstAlpha = (0.3 - t) / 0.3;
          _waveIndicatorBurstPaint.color =
              magentaColor.withOpacity(burstAlpha * 0.4);
          canvas.drawPath(framePath, _waveIndicatorBurstPaint);
        }
      }
    }
  }

  void _drawCompactWaveIndicator(
    Canvas canvas,
    int currentWave,
    int totalWaves,
    bool isSpawning,
    int enemiesAlive,
  ) {
    final waveText = 'WAVE $currentWave/$totalWaves';
    final enemyText = '$enemiesAlive EN';
    final primaryColor =
        isSpawning ? const Color(0xFFFF00FF) : const Color(0xFF00FFFF);

    final labelPainter = _getPainter(
      'wave-compact-$waveText',
      waveText,
      TextStyle(
        color: primaryColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        shadows: [Shadow(color: primaryColor.withOpacity(0.6), blurRadius: 4)],
      ),
    );
    final enemyPainter = _getPainter(
      'wave-compact-enemy-$enemyText',
      enemyText,
      TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );

    final paddingX = 10.0;
    final paddingY = 4.0;
    final pillWidth =
        math.max(labelPainter.width, enemyPainter.width) + paddingX * 2;
    final pillHeight = labelPainter.height + enemyPainter.height + paddingY * 3;

    final x = 16.0;
    final y = 32.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, pillWidth, pillHeight),
      const Radius.circular(10),
    );

    _waveIndicatorBgPaint.color = const Color(0xFF0b0b17).withOpacity(0.85);
    canvas.drawRRect(rrect, _waveIndicatorBgPaint);

    _waveIndicatorBorderPaint.color = primaryColor.withOpacity(0.7);
    canvas.drawRRect(rrect, _waveIndicatorBorderPaint);

    labelPainter.paint(
      canvas,
      Offset(
        x + (pillWidth - labelPainter.width) / 2,
        y + paddingY,
      ),
    );
    enemyPainter.paint(
      canvas,
      Offset(
        x + (pillWidth - enemyPainter.width) / 2,
        y + paddingY + labelPainter.height + 2,
      ),
    );
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
    _drawResourceCard(
        canvas, 20, 8, 'GOLD', '${gameRef.gold}', const Color(0xFFFFD700), 0);
    _drawResourceCard(canvas, 130, 8, 'LIVES', '${gameRef.lives}',
        const Color(0xFFFF4466), 1);
    _drawResourceCard(canvas, 240, 8, 'SCORE', '${gameRef.score}',
        const Color(0xFF00FF88), 2);

    // Right side resources
    _drawResourceCard(canvas, screenWidth - 340, 8, 'WAVE',
        '${gameRef.enemyManager.currentWave}', const Color(0xFFFF00FF), 3);
    _drawResourceCard(canvas, screenWidth - 230, 8, 'ENEMIES',
        '${gameRef.enemyManager.aliveCount}', const Color(0xFFFF6644), 4);
    _drawResourceCard(canvas, screenWidth - 120, 8, 'TOWERS',
        '${gameRef.towerManager.towers.length}', const Color(0xFF44AAFF), 5);

    // Overdrive (FPS) uses indicator
    _drawOverdriveUses(canvas, screenWidth);
  }

  void _drawOverdriveUses(Canvas canvas, double screenWidth) {
    if (_isCompactHud(screenWidth, gameRef.size.y)) return;

    final uses = gameRef.fpsUsesTotal;
    final max = gameRef.maxFpsUsesMatch;
    final remaining = (max - uses).clamp(0, max);
    final color =
        remaining > 0 ? const Color(0xFF00FFFF) : const Color(0xFFFF0066);

    final x = screenWidth / 2 - 145; // Below selection info or logo
    final y = 70.0;

    // Draw small circles/dots for available uses
    for (int i = 0; i < max; i++) {
      final isUsed = i < uses;
      final dotX = x + i * 20;
      _overdriveDotPaint
        ..color = isUsed ? Colors.white12 : color.withOpacity(0.8)
        ..maskFilter =
            isUsed ? null : const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(dotX, y), 4, _overdriveDotPaint);
      if (!isUsed) {
        _overdriveDotCorePaint.color = Colors.white;
        canvas.drawCircle(Offset(dotX, y), 2, _overdriveDotCorePaint);
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
    final borderAlpha =
        reduceFlicker ? 0.35 : 0.3 + math.sin(_time * 2 + index * 0.5) * 0.1;
    _resourceCardBorderPaint.color = color.withOpacity(borderAlpha);
    canvas.drawRRect(rrect, _resourceCardBorderPaint);

    // Corner accents
    _resourceCardAccentPaint.color = color.withOpacity(0.7);

    // Top-left corner
    canvas.drawLine(Offset(x, y + 8), Offset(x, y), _resourceCardAccentPaint);
    canvas.drawLine(Offset(x, y), Offset(x + 8, y), _resourceCardAccentPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(x + cardWidth - 8, y + cardHeight),
        Offset(x + cardWidth, y + cardHeight), _resourceCardAccentPaint);
    canvas.drawLine(Offset(x + cardWidth, y + cardHeight - 8),
        Offset(x + cardWidth, y + cardHeight), _resourceCardAccentPaint);

    // Icon indicator (glowing dot)
    _resourceCardDotGlowPaint.color = color.withOpacity(0.8);
    final dotRadius = compact ? 3.5 : 5.0;
    canvas.drawCircle(Offset(x + 12, y + cardHeight / 2), dotRadius,
        _resourceCardDotGlowPaint);

    _resourceCardDotCorePaint.color = color;
    canvas.drawCircle(Offset(x + 12, y + cardHeight / 2), dotRadius * 0.6,
        _resourceCardDotCorePaint);

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
    _centerLinePaint.color = const Color(0xFF00FFFF).withOpacity(0.2);

    canvas.drawLine(
        Offset(centerX - 80, 30), Offset(centerX - 30, 30), _centerLinePaint);
    canvas.drawLine(
        Offset(centerX + 30, 30), Offset(centerX + 80, 30), _centerLinePaint);

    // Small diamond accent
    _centerDiamondPaint.color = const Color(0xFF00FFFF).withOpacity(0.5);

    final diamondPath = _centerDiamondPath..reset();
    diamondPath
      ..moveTo(centerX, 22)
      ..lineTo(centerX + 8, 30)
      ..lineTo(centerX, 38)
      ..lineTo(centerX - 8, 30)
      ..close();

    canvas.drawPath(diamondPath, _centerDiamondPaint);

    // Inner filled diamond
    final innerDiamond = _centerInnerDiamondPath..reset();
    innerDiamond
      ..moveTo(centerX, 26)
      ..lineTo(centerX + 4, 30)
      ..lineTo(centerX, 34)
      ..lineTo(centerX - 4, 30)
      ..close();

    _centerInnerDiamondPaint.color = const Color(0xFF00FFFF).withOpacity(0.3);
    canvas.drawPath(innerDiamond, _centerInnerDiamondPaint);
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
    final waveActive =
        gameRef.enemyManager.spawning || gameRef.enemyManager.aliveCount > 0;
    double levelProgress = 0.0;
    if (currentWave > 0) {
      final completed = waveActive
          ? (currentWave - 1 + waveProgress)
          : currentWave.toDouble();
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
    levelLabel.paint(
        canvas, Offset(startX - levelLabel.width - labelGap, levelY - 3));
    levelValue.paint(canvas, Offset(startX + barWidth + labelGap, levelY - 3));
    waveLabel.paint(
        canvas, Offset(startX - waveLabel.width - labelGap, waveY - 3));
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
    final alertPath = _alertPath..reset();
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
    _alertGlowPaint.color = color.withOpacity(0.5 * dangerPulse);
    canvas.drawPath(alertPath, _alertGlowPaint);

    // Secondary glow layer
    _alertSecondaryGlowPaint.color = color.withOpacity(0.3 * pulseAlpha);
    canvas.drawPath(alertPath, _alertSecondaryGlowPaint);

    // Dark background with gradient
    final alertGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.15),
        const Color(0xFF0a0a18).withOpacity(0.95),
      ],
    ).createShader(Rect.fromLTWH(badgeX, badgeY, badgeWidth, badgeHeight));
    _alertGradientPaint.shader = alertGradient;
    canvas.drawPath(alertPath, _alertGradientPaint);

    // ═══ GLITCH SCANLINES ═══
    if (!reduceFlicker) {
      for (int i = 0; i < 4; i++) {
        final scanY = badgeY + (i * 8) + (_time * 30 % 8);
        if (scanY < badgeY + badgeHeight) {
          _alertScanlinePaint.color =
              color.withOpacity(isGlitching ? 0.15 : 0.05);
          canvas.drawLine(
            Offset(badgeX, scanY),
            Offset(badgeX + badgeWidth, scanY),
            _alertScanlinePaint,
          );
        }
      }
    }

    // Border - AGGRESSIVE double line
    _alertBorderPaint.color = color.withOpacity(0.9 * pulseAlpha);
    canvas.drawPath(alertPath, _alertBorderPaint);

    // Inner border for depth
    final innerPath = _alertInnerPath..reset();
    const innerCut = 6.0;
    const inset = 2.0;
    innerPath.moveTo(badgeX + inset + innerCut, badgeY + inset);
    innerPath.lineTo(badgeX + badgeWidth - inset - innerCut, badgeY + inset);
    innerPath.lineTo(badgeX + badgeWidth - inset, badgeY + inset + innerCut);
    innerPath.lineTo(
        badgeX + badgeWidth - inset, badgeY + badgeHeight - inset - innerCut);
    innerPath.lineTo(
        badgeX + badgeWidth - inset - innerCut, badgeY + badgeHeight - inset);
    innerPath.lineTo(badgeX + inset + innerCut, badgeY + badgeHeight - inset);
    innerPath.lineTo(badgeX + inset, badgeY + badgeHeight - inset - innerCut);
    innerPath.lineTo(badgeX + inset, badgeY + inset + innerCut);
    innerPath.close();
    _alertInnerBorderPaint.color = color.withOpacity(0.3);
    canvas.drawPath(innerPath, _alertInnerBorderPaint);

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
      _alertCornerPaint.color = color.withOpacity(cornerPulse);
      canvas.drawCircle(corner, 3, _alertCornerPaint);
      _alertCornerCorePaint.color = Colors.white;
      canvas.drawCircle(corner, 1.5, _alertCornerCorePaint);
    }

    // ═══ WARNING ICON with glitch ═══
    final iconCenterY = badgeY + badgeHeight / 2;

    // Icon glow
    _alertIconGlowPaint.color = color.withOpacity(0.4 * dangerPulse);
    canvas.drawCircle(
      Offset(badgeX + 20 + glitchOffset * 0.3, iconCenterY),
      12,
      _alertIconGlowPaint,
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
    _alertChevronPaint.color = color.withOpacity(0.6 * dangerPulse);

    // Left chevron
    final leftChevron = _alertLeftChevronPath..reset();
    leftChevron.moveTo(badgeX - 12, iconCenterY - 6);
    leftChevron.lineTo(badgeX - 6, iconCenterY);
    leftChevron.lineTo(badgeX - 12, iconCenterY + 6);
    canvas.drawPath(leftChevron, _alertChevronPaint);

    // Right chevron
    final rightChevron = _alertRightChevronPath..reset();
    rightChevron.moveTo(badgeX + badgeWidth + 12, iconCenterY - 6);
    rightChevron.lineTo(badgeX + badgeWidth + 6, iconCenterY);
    rightChevron.lineTo(badgeX + badgeWidth + 12, iconCenterY + 6);
    canvas.drawPath(rightChevron, _alertChevronPaint);
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

  void _drawBottomPanel(
      Canvas canvas, double screenWidth, double screenHeight) {
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
        shadows: [
          Shadow(color: selected.color.withOpacity(0.5), blurRadius: 4)
        ],
      ),
    );
    namePainter.paint(canvas, Offset(panelX, panelY));

    // Stats in one line
    final damage = gameRef.towerDamage(selected).round();
    final range = gameRef.towerRange(selected).round();
    final fireRate = gameRef.towerFireRate(selected);
    final statsText =
        'DMG $damage  •  RNG $range  •  SPD ${fireRate.toStringAsFixed(1)}';
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

  void _drawModernCostIndicators(
      Canvas canvas, double screenWidth, double screenHeight) {
    // Use responsive layout - get positions from tower buttons
    final unlockedTowers = LevelService.instance.getUnlockedTowers();

    for (int i = 0;
        i < unlockedTowers.length && i < _towerButtons.length;
        i++) {
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
        _costPillPaint
          ..color = (canAfford ? type.color : const Color(0xFFFF4444))
              .withOpacity(0.2),
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
        Offset(costX + (pillWidth - costPainter.width) / 2,
            costY + (pillHeight - costPainter.height) / 2),
      );
    }
  }

  void _drawTowerInfoPanel(Canvas canvas, double screenHeight) {
    final selected = gameRef.towerManager.selectedTowerType;
    final lowFx = gameRef.reduceFx;

    // Larger holographic panel
    const panelWidth = 220.0;
    const panelHeight = 110.0;
    final panelX = 12.0;
    final panelY = screenHeight - panelHeight - 8;
    final panelRect = Rect.fromLTWH(panelX, panelY, panelWidth, panelHeight);

    final hslColor = HSLColor.fromColor(selected.color);
    final secondaryColor =
        hslColor.withHue((hslColor.hue + 30) % 360).toColor();
    final tertiaryColor =
        hslColor.withHue((hslColor.hue + 180) % 360).toColor();

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: HOLOGRAPHIC PROJECTION GLOW
    // ═══════════════════════════════════════════════════════════════════════
    _holoPreviewGlowPaint.color =
        selected.color.withOpacity(0.15 + math.sin(_time * 2) * 0.05);
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect.inflate(8), const Radius.circular(8)),
      _holoPreviewGlowPaint,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 2: BACKGROUND WITH GRADIENT
    // ═══════════════════════════════════════════════════════════════════════
    _holoPreviewBgPaint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF0a0a18).withOpacity(0.95),
        const Color(0xFF0f0f24).withOpacity(0.9),
        selected.color.withOpacity(0.08),
      ],
    ).createShader(panelRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(6)),
      _holoPreviewBgPaint,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: HEXAGONAL PATTERN OVERLAY
    // ═══════════════════════════════════════════════════════════════════════
    if (!lowFx) {
      canvas.save();
      canvas.clipRRect(
          RRect.fromRectAndRadius(panelRect, const Radius.circular(6)));
      _holoPreviewHexPaint.color = selected.color.withOpacity(0.08);
      const hexSize = 12.0;
      for (double y = panelY - hexSize;
          y < panelY + panelHeight + hexSize;
          y += hexSize * 1.5) {
        for (double x = panelX - hexSize;
            x < panelX + panelWidth + hexSize;
            x += hexSize * 1.73) {
          final offsetX =
              ((y ~/ (hexSize * 1.5)) % 2 == 0) ? 0.0 : hexSize * 0.866;
          _holoPreviewPath.reset();
          for (int i = 0; i < 6; i++) {
            final angle = (i * 60 - 30) * math.pi / 180;
            final px = x + offsetX + math.cos(angle) * hexSize * 0.4;
            final py = y + math.sin(angle) * hexSize * 0.4;
            if (i == 0) {
              _holoPreviewPath.moveTo(px, py);
            } else {
              _holoPreviewPath.lineTo(px, py);
            }
          }
          _holoPreviewPath.close();
          canvas.drawPath(_holoPreviewPath, _holoPreviewHexPaint);
        }
      }
      canvas.restore();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: ANIMATED SCAN LINE
    // ═══════════════════════════════════════════════════════════════════════
    if (!lowFx) {
      final scanY = panelY + ((_time * 40) % panelHeight);
      _holoPreviewScanPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          selected.color.withOpacity(0.3),
          selected.color.withOpacity(0.5),
          selected.color.withOpacity(0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(panelX, scanY - 8, panelWidth, 16));
      canvas.drawRect(Rect.fromLTWH(panelX, scanY - 8, panelWidth, 16),
          _holoPreviewScanPaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: HOLOGRAPHIC FRAME WITH ANIMATED CORNERS
    // ═══════════════════════════════════════════════════════════════════════
    _holoPreviewBorderPaint.color = selected.color.withOpacity(0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(6)),
      _holoPreviewBorderPaint,
    );

    // Animated corner brackets
    _holoPreviewCornerPaint.color = selected.color;
    final cornerLen = 15.0 + math.sin(_time * 3) * 2;
    // Top-left
    canvas.drawLine(Offset(panelX, panelY + cornerLen), Offset(panelX, panelY),
        _holoPreviewCornerPaint);
    canvas.drawLine(Offset(panelX, panelY), Offset(panelX + cornerLen, panelY),
        _holoPreviewCornerPaint);
    // Top-right
    canvas.drawLine(Offset(panelX + panelWidth - cornerLen, panelY),
        Offset(panelX + panelWidth, panelY), _holoPreviewCornerPaint);
    canvas.drawLine(
        Offset(panelX + panelWidth, panelY),
        Offset(panelX + panelWidth, panelY + cornerLen),
        _holoPreviewCornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(panelX, panelY + panelHeight - cornerLen),
        Offset(panelX, panelY + panelHeight), _holoPreviewCornerPaint);
    canvas.drawLine(
        Offset(panelX, panelY + panelHeight),
        Offset(panelX + cornerLen, panelY + panelHeight),
        _holoPreviewCornerPaint);
    // Bottom-right
    canvas.drawLine(
        Offset(panelX + panelWidth - cornerLen, panelY + panelHeight),
        Offset(panelX + panelWidth, panelY + panelHeight),
        _holoPreviewCornerPaint);
    canvas.drawLine(
        Offset(panelX + panelWidth, panelY + panelHeight - cornerLen),
        Offset(panelX + panelWidth, panelY + panelHeight),
        _holoPreviewCornerPaint);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: TOWER NAME HEADER WITH GLITCH
    // ═══════════════════════════════════════════════════════════════════════
    final nameY = panelY + 8;

    // Glitch offset (occasional)
    double glitchX = 0;
    if (!lowFx && _holoPreviewNextUnit() < 0.02) {
      glitchX = (_holoPreviewNextUnit() - 0.5) * 4;
    }

    final namePainter = _towerInfoNamePainter ??
        _buildPainter(
          '◈ ${selected.name.toUpperCase()}',
          TextStyle(
            color: selected.color,
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            shadows: [
              Shadow(color: selected.color.withOpacity(0.8), blurRadius: 8),
              Shadow(color: selected.color.withOpacity(0.4), blurRadius: 16),
            ],
          ),
        );
    namePainter.paint(canvas, Offset(panelX + 10 + glitchX, nameY));

    // Type indicator line
    _holoPreviewFramePaint.color = selected.color.withOpacity(0.5);
    canvas.drawLine(
      Offset(panelX + 8, nameY + 18),
      Offset(panelX + panelWidth - 8, nameY + 18),
      _holoPreviewFramePaint,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 7: STAT BARS WITH HOLOGRAPHIC ENERGY FILLS
    // ═══════════════════════════════════════════════════════════════════════
    final damage = gameRef.towerDamage(selected);
    final range = gameRef.towerRange(selected);
    final fireRate = gameRef.towerFireRate(selected);
    final baseDamage = selected.damage;
    final baseRange = selected.range;
    final baseFireRate = selected.fireRate;

    final barY = nameY + 26;
    const barHeight = 14.0;
    const barWidth = 85.0;
    const labelWidth = 35.0;
    const barSpacing = 18.0;

    // Helper to draw stat bar
    void drawStatBar(double y, String label, double value, double maxValue,
        double baseValue, Color barColor) {
      // Label
      final labelPainter = _getPainter(
        'stat-$label',
        label,
        TextStyle(
          color: barColor.withOpacity(0.9),
          fontSize: 9,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      );
      labelPainter.paint(canvas, Offset(panelX + 10, y + 1));

      // Bar background
      final barX = panelX + labelWidth + 8;
      _holoPreviewBarBgPaint.color = const Color(0xFF0a0a18);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barX, y, barWidth, barHeight),
            const Radius.circular(2)),
        _holoPreviewBarBgPaint,
      );

      // Fill percentage
      final fillPercent = (value / maxValue).clamp(0.0, 1.0);
      final fillWidth = barWidth * fillPercent;

      // Glow behind fill
      if (!lowFx) {
        _holoPreviewBarGlowPaint.color = barColor.withOpacity(0.4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(barX, y, fillWidth, barHeight),
              const Radius.circular(2)),
          _holoPreviewBarGlowPaint,
        );
      }

      // Animated energy fill gradient
      _holoPreviewBarFillPaint.shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          barColor.withOpacity(0.9),
          barColor,
          barColor.withOpacity(0.7 + math.sin(_time * 4 + y) * 0.2),
        ],
      ).createShader(Rect.fromLTWH(barX, y, fillWidth, barHeight));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(barX + 1, y + 1, fillWidth - 2, barHeight - 2),
            const Radius.circular(1)),
        _holoPreviewBarFillPaint,
      );

      // Energy flow animation inside bar
      if (!lowFx && fillWidth > 10) {
        _holoPreviewDataPaint.color = Colors.white.withOpacity(0.3);
        final flowX = barX + ((_time * 60) % fillWidth);
        if (flowX < barX + fillWidth - 3) {
          canvas.drawLine(
            Offset(flowX, y + 3),
            Offset(flowX + 3, y + barHeight - 3),
            _holoPreviewDataPaint,
          );
        }
      }

      // Value display with upgrade indicator
      final hasBonus = value > baseValue;
      final valueText =
          label == 'SPD' ? value.toStringAsFixed(1) : value.round().toString();
      final bonusIndicator = hasBonus ? ' ▲' : '';
      final valuePainter = _getPainter(
        'val-$label-$valueText',
        '$valueText$bonusIndicator',
        TextStyle(
          color: hasBonus
              ? const Color(0xFF00FF88)
              : Colors.white.withOpacity(0.8),
          fontSize: 9,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          shadows: hasBonus
              ? [Shadow(color: const Color(0xFF00FF88), blurRadius: 4)]
              : null,
        ),
      );
      valuePainter.paint(canvas, Offset(barX + barWidth + 6, y + 1));
    }

    // Draw the three stat bars
    drawStatBar(barY, 'DMG', damage, 200, baseDamage, selected.color);
    drawStatBar(
        barY + barSpacing, 'RNG', range, 350, baseRange, secondaryColor);
    drawStatBar(barY + barSpacing * 2, 'SPD', fireRate, 5.0, baseFireRate,
        tertiaryColor);

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 8: COST DISPLAY WITH HOLOGRAPHIC CREDITS
    // ═══════════════════════════════════════════════════════════════════════
    final cost = gameRef.towerCost(selected);
    final costY = panelY + panelHeight - 20;
    final canAfford = gameRef.gold >= cost;

    // Cost pill background
    final costPillRect = Rect.fromLTWH(panelX + panelWidth - 70, costY, 60, 16);
    _holoPreviewBgPaint.shader = LinearGradient(
      colors: [
        (canAfford ? NeonColors.green : NeonColors.magenta).withOpacity(0.15),
        (canAfford ? NeonColors.green : NeonColors.magenta).withOpacity(0.05),
      ],
    ).createShader(costPillRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(costPillRect, const Radius.circular(8)),
      _holoPreviewBgPaint,
    );

    // Cost text
    final costPainter = _getPainter(
      'cost-$cost',
      '◆ $cost',
      TextStyle(
        color: canAfford ? NeonColors.green : NeonColors.magenta,
        fontSize: 10,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
              color: (canAfford ? NeonColors.green : NeonColors.magenta)
                  .withOpacity(0.6),
              blurRadius: 4),
        ],
      ),
    );
    costPainter.paint(
        canvas,
        Offset(costPillRect.left + (costPillRect.width - costPainter.width) / 2,
            costY + 2));

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 9: UPGRADE BONUSES INDICATOR
    // ═══════════════════════════════════════════════════════════════════════
    final stats = gameRef.upgradeStats;
    final hasBonuses = stats.towerDamageMult > 1.0 ||
        stats.towerRangeMult > 1.0 ||
        stats.towerFireRateMult > 1.0;

    if (hasBonuses) {
      final bonusX = panelX + 10;
      final bonusY = costY + 2;

      // Pulsing bonus indicator
      _holoPreviewBonusPaint.color =
          const Color(0xFF00FF88).withOpacity(0.6 + math.sin(_time * 4) * 0.3);
      canvas.drawCircle(
          Offset(bonusX + 4, bonusY + 6), 4, _holoPreviewBonusPaint);

      // UPGRADED text
      final upgradedPainter = _getPainter(
        'upgraded',
        'UPGRADED',
        TextStyle(
          color: const Color(0xFF00FF88),
          fontSize: 8,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      );
      upgradedPainter.paint(canvas, Offset(bonusX + 12, bonusY));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 10: HOLOGRAPHIC PROJECTION LINES
    // ═══════════════════════════════════════════════════════════════════════
    if (!lowFx) {
      _holoPreviewProjectionPaint.color =
          selected.color.withOpacity(0.2 + math.sin(_time * 2) * 0.1);

      // Top projection rays
      for (int i = 0; i < 3; i++) {
        final rayX = panelX + 40 + i * 50;
        canvas.drawLine(
          Offset(rayX, panelY),
          Offset(rayX + (_holoPreviewNextUnit() - 0.5) * 10,
              panelY - 15 - _holoPreviewNextUnit() * 10),
          _holoPreviewProjectionPaint,
        );
      }

      // Side data streams
      final streamPhase = (_time * 3) % 1.0;
      _holoPreviewDataPaint.color = selected.color.withOpacity(0.4);
      for (int i = 0; i < 4; i++) {
        final dotY = panelY + 10 + i * 25 + streamPhase * 25;
        if (dotY < panelY + panelHeight - 10) {
          canvas.drawCircle(Offset(panelX + panelWidth - 4, dotY), 1.5,
              _holoPreviewDataPaint);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 11: OUTER PULSE RING (when selected and can afford)
    // ═══════════════════════════════════════════════════════════════════════
    if (!lowFx && canAfford) {
      final pulsePhase = (_time * 1.5) % 1.0;
      final pulseRadius = 6 + pulsePhase * 20;
      _holoPreviewPulsePaint.color =
          selected.color.withOpacity((1 - pulsePhase) * 0.3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(panelRect.inflate(pulseRadius),
            Radius.circular(6 + pulseRadius * 0.3)),
        _holoPreviewPulsePaint,
      );
    }
  }

  void _drawAbilityCooldowns(
      Canvas canvas, double screenWidth, double screenHeight) {
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
    final mineBarY = _rightAbilitiesY +
        _rightButtonHeight +
        _rightButtonSpacing +
        _rightButtonHeight +
        2;
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
    canvas.drawRRect(bgRect, _cooldownBgPaint);

    // Progress fill
    if (progress > 0) {
      final progressColor =
          ready ? color : Color.lerp(const Color(0xFF1a1a3a), color, progress)!;

      final progressRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 2, y + 2, (width - 4) * progress, height - 4),
        const Radius.circular(2),
      );

      // Glow effect when ready
      if (ready) {
        _cooldownGlowPaint.color = progressColor.withOpacity(0.5);
        canvas.drawRRect(progressRect, _cooldownGlowPaint);
      }

      _cooldownFillPaint.color = progressColor.withOpacity(0.8);
      canvas.drawRRect(progressRect, _cooldownFillPaint);

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
        _highlightGradientPaint.shader = highlightGradient;
        canvas.drawRect(
          Rect.fromLTWH(highlightX - 15, y, 30, height),
          _highlightGradientPaint,
        );
        canvas.restore();
      }
    }

    // Border
    _cooldownBorderPaint.color =
        (ready ? color : const Color(0xFF333355)).withOpacity(0.6);
    canvas.drawRRect(bgRect, _cooldownBorderPaint);

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
        shadows: ready ? [Shadow(color: color, blurRadius: 6)] : null,
      ),
    );

    labelPainter.paint(
      canvas,
      Offset(x + (width - labelPainter.width) / 2,
          y + (height - labelPainter.height) / 2),
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

  void _drawCostIndicators(
      Canvas canvas, double screenWidth, double screenHeight) {
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
      (
        gameRef.towerCost(TowerType.circuitCannon),
        TowerType.circuitCannon.color
      ),
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
    final canAffordPulse =
        gameRef.gold >= gameRef.pulseCost && gameRef.pulseReady;
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
      Offset(pulseX - pulseCostPainter.width / 2,
          useTwoRows ? row2CostY : row1CostY),
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
      Offset(mineX - mineCostPainter.width / 2,
          useTwoRows ? row2CostY : row1CostY),
    );
  }

  void _drawGlowingLine(Canvas canvas, double x1, double y1, double x2,
      double y2, Color color, double intensity) {
    // Outer glow
    _glowLineOuterPaint.color = color.withOpacity(intensity * 0.3);
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), _glowLineOuterPaint);

    // Core line
    _glowLineCorePaint.color = color.withOpacity(intensity);
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), _glowLineCorePaint);
  }

  void _drawHexPattern(
      Canvas canvas, double x, double y, int count, double alpha) {
    _hexPatternPaint.color = const Color(0xFF00FFFF).withOpacity(alpha);

    const hexSize = 8.0;
    for (int i = 0; i < count; i++) {
      for (int j = 0; j < 2; j++) {
        final offsetX = x + i * hexSize * 1.5;
        final offsetY = y + j * hexSize * 0.866 + (i % 2) * hexSize * 0.433;
        _drawHexagon(
            canvas, Offset(offsetX, offsetY), hexSize * 0.4, _hexPatternPaint);
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
    if (_towerInfoRect == rect &&
        _towerInfoShader != null &&
        _towerInfoType == type) {
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
    final key =
        Object.hash(rect.left, rect.top, rect.width, rect.height, color.value);
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
        shadows: [
          Shadow(color: selected.color.withOpacity(0.6), blurRadius: 6)
        ],
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
      _getPainter(
          'value-GOLD', '$gold', _resourceValueStyle(const Color(0xFFFFD700)));
      _lastGold = gold;
    }
    if (lives != _lastLives) {
      _getPainter('value-LIVES', '$lives',
          _resourceValueStyle(const Color(0xFFFF4466)));
      _lastLives = lives;
    }
    if (score != _lastScore) {
      _getPainter('value-SCORE', '$score',
          _resourceValueStyle(const Color(0xFF00FF88)));
      _lastScore = score;
    }
    if (wave != _lastWave) {
      _getPainter(
          'value-WAVE', '$wave', _resourceValueStyle(const Color(0xFFFF00FF)));
      _lastWave = wave;
    }
    if (enemies != _lastEnemies) {
      _getPainter('value-ENEMIES', '$enemies',
          _resourceValueStyle(const Color(0xFFFF6644)));
      _lastEnemies = enemies;
    }
    if (towers != _lastTowers) {
      _getPainter('value-TOWERS', '$towers',
          _resourceValueStyle(const Color(0xFF44AAFF)));
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

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA STREAM EFFECTS (Towers to HUD connection visualization)
  // ═══════════════════════════════════════════════════════════════════════════
  void _drawDataStreamEffects(
      Canvas canvas, double screenWidth, double screenHeight) {
    // Only draw when there are active towers
    final towers = gameRef.towerManager.towers;
    if (towers.isEmpty || reduceFlicker) return;

    final targetY = topBarHeight; // HUD area at top
    final streamCount =
        math.min(towers.length, 6); // Limit streams for performance

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 1: AMBIENT DATA STREAMS FROM SCREEN EDGES
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < streamCount; i++) {
      final color = towers[i].color;
      final streamPhase = (_time * 2 + i * 0.4) % 1.0;

      // Calculate stream position - distribute across screen width
      final startX = (screenWidth / (streamCount + 1)) * (i + 1);
      final startY = screenHeight - 50;

      // Stream flows upward with animated particles
      for (int p = 0; p < 8; p++) {
        final particlePhase = (streamPhase + p * 0.12) % 1.0;
        final particleY = startY - particlePhase * (startY - targetY - 20);
        final particleX = startX + math.sin(_time * 3 + i + p * 0.5) * 3;

        final alpha = (1 - particlePhase) * 0.4;

        // Particle glow
        _dataStreamGlowPaint.color = color.withOpacity(alpha * 0.3);
        canvas.drawCircle(
            Offset(particleX, particleY), 4, _dataStreamGlowPaint);

        // Particle core
        _dataStreamParticlePaint.color = color.withOpacity(alpha);
        canvas.drawCircle(
            Offset(particleX, particleY), 2, _dataStreamParticlePaint);
      }

      // ═══════════════════════════════════════════════════════════════════════
      // LAYER 2: BEAM LINES CONNECTING PARTICLES
      // ═══════════════════════════════════════════════════════════════════════
      final beamAlpha = 0.1 + math.sin(_time * 4 + i) * 0.05;
      _dataStreamBeamPaint.color = color.withOpacity(beamAlpha);

      final beamStartY = startY - streamPhase * 100;
      final beamEndY = math.max(targetY + 30, beamStartY - 150);
      final beamStartX = startX + math.sin(_time * 2 + i) * 2;
      final beamEndX = startX + math.sin(_time * 2.5 + i) * 2;

      canvas.drawLine(
        Offset(beamStartX, beamStartY),
        Offset(beamEndX, beamEndY),
        _dataStreamBeamPaint,
      );

      // Core beam
      _dataStreamCorePaint.color = color.withOpacity(beamAlpha * 2);
      canvas.drawLine(
        Offset(beamStartX, beamStartY),
        Offset(beamEndX, beamEndY),
        _dataStreamCorePaint,
      );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 3: HUD ENTRY NODES (where data "enters" the HUD)
    // ═══════════════════════════════════════════════════════════════════════
    for (int i = 0; i < streamCount; i++) {
      final color = towers[i].color;
      final nodeX = (screenWidth / (streamCount + 1)) * (i + 1);
      final nodeY = targetY + 5;

      final nodePulse = 0.5 + math.sin(_time * 6 + i * 0.8) * 0.5;

      // Node glow
      _dataStreamNodePaint.color = color.withOpacity(nodePulse * 0.3);
      canvas.drawCircle(Offset(nodeX, nodeY), 6, _dataStreamNodePaint);

      // Node ring
      _dataStreamArcPaint.color = color.withOpacity(nodePulse * 0.5);
      canvas.drawCircle(Offset(nodeX, nodeY), 4, _dataStreamArcPaint);

      // Node core
      _dataStreamParticlePaint.color = color.withOpacity(nodePulse * 0.8);
      canvas.drawCircle(Offset(nodeX, nodeY), 2, _dataStreamParticlePaint);

      // Expanding pulse rings from nodes
      final pulsePhase = (_time * 3 + i * 0.3) % 1.0;
      final pulseRadius = 3 + pulsePhase * 12;
      final pulseAlpha = (1 - pulsePhase) * 0.3;

      _dataStreamPulsePaint.color = color.withOpacity(pulseAlpha);
      canvas.drawCircle(
          Offset(nodeX, nodeY), pulseRadius, _dataStreamPulsePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 4: HEXAGONAL DATA PATTERN (decorative)
    // ═══════════════════════════════════════════════════════════════════════
    if (towers.length >= 3) {
      final hexAlpha = 0.08 + math.sin(_time * 2) * 0.04;
      _dataStreamHexPaint.color = const Color(0xFF00FFFF).withOpacity(hexAlpha);

      // Draw small hexagons along the top panel edge
      for (int h = 0; h < 5; h++) {
        final hexX = screenWidth * (0.2 + h * 0.15);
        final hexY = targetY - 2;
        final hexSize = 3 + math.sin(_time * 4 + h) * 1;

        _dataStreamPath.reset();
        for (int v = 0; v < 6; v++) {
          final angle = v * math.pi / 3;
          final px = hexX + math.cos(angle) * hexSize;
          final py = hexY + math.sin(angle) * hexSize;
          if (v == 0) {
            _dataStreamPath.moveTo(px, py);
          } else {
            _dataStreamPath.lineTo(px, py);
          }
        }
        _dataStreamPath.close();
        canvas.drawPath(_dataStreamPath, _dataStreamHexPaint);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 5: SIDE EDGE DATA STREAMS
    // ═══════════════════════════════════════════════════════════════════════
    // Left side stream
    final leftStreamPhase = (_time * 1.5) % 1.0;
    for (int p = 0; p < 5; p++) {
      final particlePhase = (leftStreamPhase + p * 0.2) % 1.0;
      final py = screenHeight - particlePhase * (screenHeight - targetY - 30);
      final px = 8 + math.sin(_time * 2 + p) * 2;

      final alpha = (1 - particlePhase) * 0.25;
      _dataStreamParticlePaint.color =
          const Color(0xFF00FFFF).withOpacity(alpha);
      canvas.drawCircle(Offset(px, py), 1.5, _dataStreamParticlePaint);
    }

    // Right side stream
    final rightStreamPhase = (_time * 1.8 + 0.5) % 1.0;
    for (int p = 0; p < 5; p++) {
      final particlePhase = (rightStreamPhase + p * 0.2) % 1.0;
      final py = screenHeight - particlePhase * (screenHeight - targetY - 30);
      final px = screenWidth - 8 + math.sin(_time * 2.2 + p) * 2;

      final alpha = (1 - particlePhase) * 0.25;
      _dataStreamParticlePaint.color =
          const Color(0xFFFF00FF).withOpacity(alpha);
      canvas.drawCircle(Offset(px, py), 1.5, _dataStreamParticlePaint);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAYER 6: CONNECTING ARCS BETWEEN NODES
    // ═══════════════════════════════════════════════════════════════════════
    if (streamCount >= 2) {
      for (int i = 0; i < streamCount - 1; i++) {
        final x1 = (screenWidth / (streamCount + 1)) * (i + 1);
        final x2 = (screenWidth / (streamCount + 1)) * (i + 2);
        final y = targetY + 5;

        final arcPulse = 0.3 + math.sin(_time * 5 + i) * 0.2;
        final arcAlpha = arcPulse * 0.15;

        // Draw curved connection
        _dataStreamArcPaint.color =
            const Color(0xFF00FFFF).withOpacity(arcAlpha);
        _dataStreamPath.reset();
        _dataStreamPath.moveTo(x1 + 6, y);
        _dataStreamPath.quadraticBezierTo(
          (x1 + x2) / 2,
          y - 8,
          x2 - 6,
          y,
        );
        canvas.drawPath(_dataStreamPath, _dataStreamArcPaint);

        // Animated dot traveling along the arc
        final dotProgress = (_time * 2 + i * 0.3) % 1.0;
        final dotX = x1 + 6 + (x2 - x1 - 12) * dotProgress;
        final dotY = y - math.sin(dotProgress * math.pi) * 8;

        _dataStreamParticlePaint.color =
            const Color(0xFFFFFFFF).withOpacity(arcPulse);
        canvas.drawCircle(Offset(dotX, dotY), 1.5, _dataStreamParticlePaint);
      }
    }
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
