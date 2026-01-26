import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../ui/theme/neon_theme.dart';
import '../bored_games_game.dart';
import '../entities/enemy.dart';
import '../effects/floating_text.dart';
import '../effects/particle_system.dart';
import '../effects/screen_effects.dart';
import '../managers/enemy_manager.dart';

/// Orchestrates the extreme visual layer described in VISUAL_UPGRADE_GUIDE.md.
class VisualDirector {
  VisualDirector({
    required this.game,
    required this.screenEffects,
  });

  final FlameGame game;
  final ScreenEffects screenEffects;

  int _killStreak = 0;
  double _streakTimer = 0;
  bool _streakNotified = false;
  static const double _streakResetDelay = 3.6;

  void update(double dt) {
    if (_killStreak > 0) {
      _streakTimer += dt;
      if (_streakTimer >= _streakResetDelay) {
        _killStreak = 0;
        _streakTimer = 0;
        _streakNotified = false;
      }
    }
  }

  void handleEnemyKill(Enemy enemy, int goldReward) {
    _killStreak++;
    _streakTimer = 0;
    _streakNotified = false;

    screenEffects.triggerShake(
      intensity: 4.0 + enemy.type.sizeMult * 2.0,
      duration: 0.2,
    );
    screenEffects.addTrauma(0.05);
    screenEffects.triggerFlash(
      color: enemy.type.color,
      intensity: 0.22,
      duration: 0.15,
    );

    GameParticles.instance.magic(enemy.position, enemy.type.color, count: 12);
    GameParticles.instance.sparks(enemy.position, enemy.type.color, count: 18);

    game.add(FloatingText(
      position: _toScreen(enemy.position),
      text: '+$goldReward',
      type: FloatingTextType.gold,
      fontSize: 16,
      duration: 1.1,
    ));

    if (_killStreak >= 3 && !_streakNotified) {
      _streakNotified = true;
      game.add(KillStreakNotification(
        position: Vector2(game.size.x / 2, 70),
        streakCount: _killStreak,
      ));
    }
  }

  void handleEnemyLeak(Enemy enemy) {
    resetKillStreak();

    screenEffects.triggerDamageVignette(intensity: 0.8);
    screenEffects.addTrauma(0.35);
    screenEffects.triggerFlash(
      color: NeonColors.red,
      intensity: 0.3,
      duration: 0.2,
    );

    GameParticles.instance.sparks(enemy.position, NeonColors.red, count: 12);

    game.add(FloatingText(
      position: _toScreen(enemy.position),
      text: 'LEAK',
      type: FloatingTextType.damage,
      customColor: NeonColors.red,
      fontSize: 14,
      duration: 1.0,
      riseSpeed: 25,
    ));
  }

  void notifyWaveStart(int wave, WaveModifier modifier) {
    final modifierLabel = _modifierLabel(modifier);
    final color = _modifierColor(modifier);
    final descriptor = modifierLabel.isNotEmpty ? ' • $modifierLabel' : '';

    screenEffects.triggerFlash(
      color: color,
      intensity: 0.18,
      duration: 0.2,
    );
    screenEffects.triggerShake(intensity: 2.0, duration: 0.15);
    screenEffects.addTrauma(0.12);

    GameParticles.instance.sparks(
      Vector2(game.size.x / 2, 60),
      color,
      count: 18,
    );

    game.add(FloatingText(
      position: Vector2(game.size.x / 2, 48),
      text: 'WAVE $wave$descriptor',
      type: FloatingTextType.combo,
      fontSize: 20,
      customColor: color,
      duration: 1.4,
      riseSpeed: 30,
    ));
  }

  void notifyPulse(Vector2 center) {
    screenEffects.triggerFlash(
      color: NeonColors.cyan,
      intensity: 0.25,
      duration: 0.15,
    );

    screenEffects.triggerShake(intensity: 3.5, duration: 0.15);
    screenEffects.addTrauma(0.08);

    GameParticles.instance.pulse(center, NeonColors.cyan, 90);
    GameParticles.instance.magic(center, NeonColors.cyan, count: 10);

    game.add(FloatingText(
      position: _toScreen(center),
      text: 'SLOW FIELD',
      type: FloatingTextType.combo,
      customColor: NeonColors.cyan,
      fontSize: 14,
      duration: 0.9,
      riseSpeed: 28,
    ));
  }

  void notifyMine(Vector2 center) {
    screenEffects.triggerShake(intensity: 5.5, duration: 0.25);
    screenEffects.triggerFlash(
      color: NeonColors.red,
      intensity: 0.35,
      duration: 0.2,
    );
    screenEffects.addTrauma(0.4);

    GameParticles.instance.explosion(
      center,
      NeonColors.red,
      shape: ParticleShape.star,
    );
  }

  void notifyWaveComplete(int wave) {
    game.add(FloatingText(
      position: Vector2(game.size.x - 120, 40),
      text: 'WAVE $wave',
      type: FloatingTextType.levelUp,
      customColor: NeonColors.green,
      fontSize: 12,
      duration: 1.0,
      riseSpeed: 30,
    ));
  }

  Vector2 _toScreen(Vector2 worldPosition) {
    if (game is BoredGamesGame) {
      return (game as BoredGamesGame).worldToScreen(worldPosition);
    }
    return worldPosition;
  }

  void resetKillStreak() {
    _killStreak = 0;
    _streakTimer = 0;
    _streakNotified = false;
  }

  Color _modifierColor(WaveModifier modifier) {
    switch (modifier) {
      case WaveModifier.overload:
        return NeonColors.magenta;
      case WaveModifier.phantom:
        return NeonColors.cyan;
      case WaveModifier.juggernaut:
        return NeonColors.purple;
      case WaveModifier.mixed:
        return NeonColors.yellow;
      case WaveModifier.normal:
        return NeonColors.green;
    }
  }

  String _modifierLabel(WaveModifier modifier) {
    switch (modifier) {
      case WaveModifier.overload:
        return 'OVERLOAD';
      case WaveModifier.phantom:
        return 'PHANTOM';
      case WaveModifier.juggernaut:
        return 'JUGGERNAUT';
      case WaveModifier.mixed:
        return 'MIXED';
      case WaveModifier.normal:
        return '';
    }
  }
}
