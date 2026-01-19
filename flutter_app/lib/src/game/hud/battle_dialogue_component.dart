import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../data/story_data.dart';
import '../bored_games_game.dart';

/// In-game dialogue system for epic battle moments
class BattleDialogueComponent extends PositionComponent with HasGameRef<BoredGamesGame> {
  BattleDialogueComponent() {
    anchor = Anchor.topCenter;
  }

  final List<_BattleDialogue> _queue = [];
  _BattleDialogue? _currentDialogue;
  double _displayTime = 0;
  double _typewriterProgress = 0;
  double _fadeProgress = 1.0;
  bool _isShowing = false;

  static const double dialogueDuration = 4.0;
  static const double typewriterSpeed = 30.0; // chars per second
  static const double fadeInDuration = 0.3;
  static const double fadeOutDuration = 0.5;

  /// Queue a battle dialogue to show
  void showDialogue({
    required Character speaker,
    required String text,
    BriefingMood mood = BriefingMood.analytical,
    bool priority = false,
  }) {
    final dialogue = _BattleDialogue(
      speaker: speaker,
      text: text,
      mood: mood,
    );

    if (priority) {
      _queue.insert(0, dialogue);
    } else {
      _queue.add(dialogue);
    }

    if (!_isShowing) {
      _showNext();
    }
  }

  void _showNext() {
    if (_queue.isEmpty) {
      _isShowing = false;
      _currentDialogue = null;
      return;
    }

    _currentDialogue = _queue.removeAt(0);
    _displayTime = 0;
    _typewriterProgress = 0;
    _fadeProgress = 0;
    _isShowing = true;
  }

  // ============================================================
  // TRIGGER METHODS - Call these from game events
  // ============================================================

  /// Trigger when boss spawns
  void onBossSpawn(String bossName) {
    showDialogue(
      speaker: StoryData.aria,
      text: '¡ALERTA! $bossName detectado. Prepara tus defensas.',
      mood: BriefingMood.urgent,
      priority: true,
    );
  }

  /// Trigger when boss health reaches 50%
  void onBossHalfHealth(String bossName) {
    final random = math.Random();
    if (random.nextBool()) {
      showDialogue(
        speaker: StoryData.aria,
        text: '¡$bossName está debilitándose! ¡Sigue así!',
        mood: BriefingMood.hopeful,
      );
    } else {
      showDialogue(
        speaker: StoryData.decompiler,
        text: 'Impresionante... pero insuficiente.',
        mood: BriefingMood.dark,
      );
    }
  }

  /// Trigger when boss defeated
  void onBossDefeated(String bossName) {
    showDialogue(
      speaker: StoryData.aria,
      text: '¡$bossName eliminado! Sector asegurado.',
      mood: BriefingMood.hopeful,
      priority: true,
    );
  }

  /// Trigger when player is low on lives
  void onLowHealth(int livesRemaining) {
    if (livesRemaining == 1) {
      showDialogue(
        speaker: StoryData.aria,
        text: '¡CRÍTICO! Una vida restante. ¡No podemos perder más!',
        mood: BriefingMood.urgent,
        priority: true,
      );
    } else if (livesRemaining <= 3) {
      showDialogue(
        speaker: StoryData.aria,
        text: 'Integridad comprometida. Refuerza tus defensas.',
        mood: BriefingMood.worried,
      );
    }
  }

  /// Trigger when big wave starts
  void onBigWaveStart(int waveNumber) {
    if (waveNumber % 10 == 0) {
      showDialogue(
        speaker: StoryData.aria,
        text: 'Oleada $waveNumber iniciando. Oleada masiva detectada.',
        mood: BriefingMood.serious,
      );
    } else if (waveNumber % 5 == 0) {
      showDialogue(
        speaker: StoryData.aria,
        text: 'Oleada $waveNumber. Incremento de hostiles.',
        mood: BriefingMood.analytical,
      );
    }
  }

  /// Trigger randomly during battle
  void onRandomBattleMoment() {
    final random = math.Random();
    final messages = [
      (StoryData.aria, '¡Excelente posicionamiento, Arquitecto!', BriefingMood.hopeful),
      (StoryData.aria, 'Los patrones de ataque son predecibles. Aprovéchalo.', BriefingMood.analytical),
      (StoryData.echo, 'Recuerda... cada torre es un ancla de esperanza.', BriefingMood.mysterious),
      (StoryData.aria, 'Detectando debilidades en la formación enemiga.', BriefingMood.analytical),
      (StoryData.echo, 'Lo estás haciendo bien. Mejor que yo...', BriefingMood.sad),
    ];

    final choice = messages[random.nextInt(messages.length)];
    showDialogue(
      speaker: choice.$1,
      text: choice.$2,
      mood: choice.$3,
    );
  }

  /// Decompiler taunts during final boss
  void onDecompilerTaunt() {
    final random = math.Random();
    final taunts = [
      '¿Crees que puedes detenerme? Soy inevitable.',
      'El Vacío es paz. ¿Por qué resistes?',
      'Cada segundo que luchas, más fuerte me vuelvo.',
      'Tus defensas son patéticas. Caerán como todas las demás.',
      'Puedo sentir tu miedo, Arquitecto.',
    ];

    showDialogue(
      speaker: StoryData.decompiler,
      text: taunts[random.nextInt(taunts.length)],
      mood: BriefingMood.dark,
    );
  }

  /// Echo encouragement
  void onEchoEncouragement() {
    final random = math.Random();
    final messages = [
      'No te rindas. Yo no lo hice... hasta el final.',
      'Eres más fuerte de lo que crees, Arquitecto.',
      'Las grietas temporales susurran... dicen que ganarás.',
      'Recuerda: cada Arquitecto antes de ti te observa.',
    ];

    showDialogue(
      speaker: StoryData.echo,
      text: messages[random.nextInt(messages.length)],
      mood: BriefingMood.hopeful,
    );
  }

  /// First tower placed
  void onFirstTowerPlaced() {
    showDialogue(
      speaker: StoryData.aria,
      text: 'Primera defensa establecida. El Grid tiene esperanza.',
      mood: BriefingMood.hopeful,
    );
  }

  /// Ability used
  void onAbilityUsed(String abilityName) {
    if (abilityName == 'NEON PULSE') {
      showDialogue(
        speaker: StoryData.aria,
        text: 'Pulso activado. Enemigos ralentizados.',
        mood: BriefingMood.analytical,
      );
    } else if (abilityName == 'NEON MINE') {
      showDialogue(
        speaker: StoryData.aria,
        text: 'Mina desplegada. Área de negación establecida.',
        mood: BriefingMood.analytical,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_isShowing || _currentDialogue == null) return;

    // Update typewriter
    _typewriterProgress += dt * typewriterSpeed;
    _typewriterProgress = _typewriterProgress.clamp(
      0,
      _currentDialogue!.text.length.toDouble(),
    );

    // Update display time
    _displayTime += dt;

    // Handle fade in/out
    if (_displayTime < fadeInDuration) {
      _fadeProgress = _displayTime / fadeInDuration;
    } else if (_displayTime > dialogueDuration - fadeOutDuration) {
      _fadeProgress = (dialogueDuration - _displayTime) / fadeOutDuration;
    } else {
      _fadeProgress = 1.0;
    }

    _fadeProgress = _fadeProgress.clamp(0.0, 1.0);

    // Check if time to show next
    if (_displayTime >= dialogueDuration) {
      _showNext();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!_isShowing || _currentDialogue == null) return;
    if (gameRef.hideHud || gameRef.focusModeActive) return;
    if (_fadeProgress <= 0) return;

    final dialogue = _currentDialogue!;
    final screenWidth = gameRef.size.x;
    final compact = gameRef.isTouchLayout || screenWidth < 820;

    final boxWidth = compact ? screenWidth - 40 : 400.0;
    final boxX = (screenWidth - boxWidth) / 2;
    final boxY = compact ? 60.0 : 80.0;

    canvas.save();
    canvas.translate(boxX, boxY);

    // Apply fade
    final alpha = (_fadeProgress * 255).round();

    // Background
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, boxWidth, compact ? 70 : 80),
      const Radius.circular(8),
    );

    canvas.drawRRect(
      bgRect,
      Paint()..color = Colors.black.withAlpha((alpha * 0.85).round()),
    );

    // Border with speaker color
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = dialogue.speaker.avatarColor.withAlpha((alpha * 0.8).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Glow effect
    canvas.drawRRect(
      bgRect.inflate(3),
      Paint()
        ..color = dialogue.speaker.avatarColor.withAlpha((alpha * 0.3).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Speaker avatar
    final avatarSize = compact ? 36.0 : 44.0;
    final avatarRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, (compact ? 70 : 80 - avatarSize) / 2, avatarSize, avatarSize),
      const Radius.circular(6),
    );

    canvas.drawRRect(
      avatarRect,
      Paint()..color = dialogue.speaker.avatarColor.withAlpha((alpha * 0.2).round()),
    );

    canvas.drawRRect(
      avatarRect,
      Paint()
        ..color = dialogue.speaker.avatarColor.withAlpha(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Avatar letter
    final letterPainter = TextPainter(
      text: TextSpan(
        text: dialogue.speaker.name[0],
        style: TextStyle(
          color: dialogue.speaker.avatarColor.withAlpha(alpha),
          fontSize: compact ? 18 : 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    letterPainter.paint(
      canvas,
      Offset(
        10 + (avatarSize - letterPainter.width) / 2,
        (compact ? 70 : 80 - letterPainter.height) / 2,
      ),
    );

    // Speaker name
    final namePainter = TextPainter(
      text: TextSpan(
        text: dialogue.speaker.dialoguePrefix,
        style: TextStyle(
          color: dialogue.speaker.avatarColor.withAlpha(alpha),
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    namePainter.paint(canvas, Offset(20 + avatarSize, compact ? 10 : 12));

    // Dialogue text (with typewriter effect)
    final displayedChars = _typewriterProgress.floor();
    final displayedText = dialogue.text.substring(
      0,
      displayedChars.clamp(0, dialogue.text.length),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayedText,
        style: TextStyle(
          color: Colors.white.withAlpha((alpha * 0.95).round()),
          fontSize: compact ? 12 : 13,
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    )..layout(maxWidth: boxWidth - avatarSize - 40);

    textPainter.paint(canvas, Offset(20 + avatarSize, compact ? 28 : 32));

    // Typing indicator
    if (displayedChars < dialogue.text.length) {
      final cursorX = 20 + avatarSize + textPainter.width + 2;
      final cursorY = compact ? 30.0 : 34.0;

      final blink = ((_displayTime * 3) % 1) < 0.5;
      if (blink) {
        canvas.drawRect(
          Rect.fromLTWH(cursorX, cursorY, 2, compact ? 14.0 : 16.0),
          Paint()..color = dialogue.speaker.avatarColor.withAlpha(alpha),
        );
      }
    }

    // Mood indicator (small dot)
    final moodColor = _getMoodColor(dialogue.mood);
    canvas.drawCircle(
      Offset(boxWidth - 15, 15),
      4,
      Paint()..color = moodColor.withAlpha(alpha),
    );

    canvas.restore();
  }

  Color _getMoodColor(BriefingMood mood) {
    switch (mood) {
      case BriefingMood.urgent:
        return const Color(0xFFFF4444);
      case BriefingMood.analytical:
        return const Color(0xFF00FFFF);
      case BriefingMood.worried:
        return const Color(0xFFFFFF00);
      case BriefingMood.serious:
        return const Color(0xFF00FF88);
      case BriefingMood.mysterious:
        return const Color(0xFFFF00FF);
      case BriefingMood.hopeful:
        return const Color(0xFF00FF88);
      case BriefingMood.surprised:
        return const Color(0xFFFFFF00);
      case BriefingMood.emotional:
        return const Color(0xFF00FFFF);
      case BriefingMood.epic:
        return const Color(0xFFFFFFFF);
      case BriefingMood.dark:
        return const Color(0xFFFF00FF);
      case BriefingMood.sad:
        return const Color(0xFF00FFFF);
      case BriefingMood.confused:
        return const Color(0xFFFFFF00);
      case BriefingMood.revelation:
        return const Color(0xFFFFFFFF);
    }
  }
}

class _BattleDialogue {
  final Character speaker;
  final String text;
  final BriefingMood mood;

  const _BattleDialogue({
    required this.speaker,
    required this.text,
    required this.mood,
  });
}
