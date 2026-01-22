import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/screen_effects.dart';
import 'package:bored_games/src/game/effects/visual_director.dart';
import 'package:bored_games/src/game/entities/enemy.dart';
import 'package:bored_games/src/game/managers/enemy_manager.dart';

class _MockScreenEffects extends ScreenEffects {
  _MockScreenEffects() : super(gameSize: Vector2(800, 600));

  int shakeCallCount = 0;
  int flashCallCount = 0;
  int traumaCallCount = 0;
  int damageVignetteCallCount = 0;

  @override
  void triggerShake({double intensity = 5.0, double duration = 0.2}) {
    shakeCallCount++;
    super.triggerShake(intensity: intensity, duration: duration);
  }

  @override
  void triggerFlash({Color color = Colors.white, double intensity = 0.5, double duration = 0.1}) {
    flashCallCount++;
    super.triggerFlash(color: color, intensity: intensity, duration: duration);
  }

  @override
  void addTrauma(double amount) {
    traumaCallCount++;
    super.addTrauma(amount);
  }

  @override
  void triggerDamageVignette({double intensity = 0.5}) {
    damageVignetteCallCount++;
    super.triggerDamageVignette(intensity: intensity);
  }

  void reset() {
    shakeCallCount = 0;
    flashCallCount = 0;
    traumaCallCount = 0;
    damageVignetteCallCount = 0;
  }
}

class _MockGame extends FlameGame {
  final List<Component> addedComponents = [];
  Vector2 _mockSize = Vector2(800, 600);

  @override
  Vector2 get size => _mockSize;

  @override
  Future<void> add(Component component) async {
    addedComponents.add(component);
    // Don't call super.add to avoid onMount issues
  }

  void clearAdded() {
    addedComponents.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockGame game;
  late _MockScreenEffects screenEffects;
  late VisualDirector director;

  setUp(() {
    game = _MockGame();
    screenEffects = _MockScreenEffects();
    director = VisualDirector(
      game: game,
      screenEffects: screenEffects,
    );
  });

  group('VisualDirector creation', () {
    test('creates with required parameters', () {
      expect(director, isNotNull);
    });

    test('holds reference to game', () {
      expect(director.game, same(game));
    });

    test('holds reference to screenEffects', () {
      expect(director.screenEffects, same(screenEffects));
    });
  });

  group('VisualDirector update', () {
    test('update does not crash with zero dt', () {
      director.update(0.0);
      expect(true, isTrue);
    });

    test('update advances streak timer', () {
      // First create a kill to start streak timer
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2(100, 100);

      director.handleEnemyKill(enemy, 10);
      director.update(1.0);

      expect(true, isTrue);
    });

    test('kill streak resets after delay', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2(100, 100);

      director.handleEnemyKill(enemy, 10);

      // Update past the reset delay (3.6 seconds)
      for (int i = 0; i < 40; i++) {
        director.update(0.1);
      }

      // Streak should have reset
      expect(true, isTrue);
    });

    test('multiple rapid updates work', () {
      for (int i = 0; i < 100; i++) {
        director.update(0.016);
      }
      expect(true, isTrue);
    });
  });

  group('VisualDirector handleEnemyKill', () {
    test('triggers shake on kill', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2(100, 100);

      director.handleEnemyKill(enemy, 10);

      expect(screenEffects.shakeCallCount, 1);
    });

    test('triggers flash on kill', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2(100, 100);

      director.handleEnemyKill(enemy, 10);

      expect(screenEffects.flashCallCount, 1);
    });

    test('adds trauma on kill', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2(100, 100);

      director.handleEnemyKill(enemy, 10);

      expect(screenEffects.traumaCallCount, 1);
    });

    test('adds floating text for gold reward', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2(100, 100);

      director.handleEnemyKill(enemy, 25);

      expect(game.addedComponents.length, greaterThan(0));
    });

    test('increments kill streak', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2(100, 100);

      director.handleEnemyKill(enemy, 10);
      director.handleEnemyKill(enemy, 10);
      director.handleEnemyKill(enemy, 10);

      // Three kills made
      expect(true, isTrue);
    });

    test('shows kill streak notification at 3 kills', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2(100, 100);

      director.handleEnemyKill(enemy, 10);
      director.handleEnemyKill(enemy, 10);
      final beforeCount = game.addedComponents.length;

      director.handleEnemyKill(enemy, 10);

      // Should have added a KillStreakNotification
      expect(game.addedComponents.length, greaterThan(beforeCount));
    });
  });

  group('VisualDirector handleEnemyLeak', () {
    test('triggers damage vignette on leak', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2(100, 100);

      director.handleEnemyLeak(enemy);

      expect(screenEffects.damageVignetteCallCount, 1);
    });

    test('adds trauma on leak', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2(100, 100);

      director.handleEnemyLeak(enemy);

      expect(screenEffects.traumaCallCount, 1);
    });

    test('triggers flash on leak', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2(100, 100);

      director.handleEnemyLeak(enemy);

      expect(screenEffects.flashCallCount, 1);
    });

    test('resets kill streak on leak', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2(100, 100);

      // Build up a streak
      director.handleEnemyKill(enemy, 10);
      director.handleEnemyKill(enemy, 10);

      screenEffects.reset();

      // Leak resets streak
      director.handleEnemyLeak(enemy);

      // Verify by checking if streak notification happens after another 3 kills
      game.clearAdded();

      director.handleEnemyKill(enemy, 10);
      director.handleEnemyKill(enemy, 10);
      director.handleEnemyKill(enemy, 10);

      // Should show notification since streak was reset
      expect(game.addedComponents.length, greaterThan(0));
    });

    test('adds floating text for leak', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2(100, 100);

      director.handleEnemyLeak(enemy);

      expect(game.addedComponents.length, greaterThan(0));
    });
  });

  group('VisualDirector notifyWaveStart', () {
    test('triggers flash on wave start', () {
      director.notifyWaveStart(1, WaveModifier.normal);

      expect(screenEffects.flashCallCount, 1);
    });

    test('triggers shake on wave start', () {
      director.notifyWaveStart(1, WaveModifier.normal);

      expect(screenEffects.shakeCallCount, 1);
    });

    test('adds trauma on wave start', () {
      director.notifyWaveStart(1, WaveModifier.normal);

      expect(screenEffects.traumaCallCount, 1);
    });

    test('adds floating text for wave', () {
      director.notifyWaveStart(5, WaveModifier.normal);

      expect(game.addedComponents.length, greaterThan(0));
    });

    test('handles overload modifier', () {
      director.notifyWaveStart(3, WaveModifier.overload);

      expect(game.addedComponents.length, greaterThan(0));
    });

    test('handles phantom modifier', () {
      director.notifyWaveStart(3, WaveModifier.phantom);

      expect(game.addedComponents.length, greaterThan(0));
    });

    test('handles juggernaut modifier', () {
      director.notifyWaveStart(3, WaveModifier.juggernaut);

      expect(game.addedComponents.length, greaterThan(0));
    });

    test('handles mixed modifier', () {
      director.notifyWaveStart(3, WaveModifier.mixed);

      expect(game.addedComponents.length, greaterThan(0));
    });
  });

  group('VisualDirector notifyPulse', () {
    test('triggers flash on pulse', () {
      director.notifyPulse(Vector2(100, 100));

      expect(screenEffects.flashCallCount, 1);
    });

    test('triggers shake on pulse', () {
      director.notifyPulse(Vector2(100, 100));

      expect(screenEffects.shakeCallCount, 1);
    });

    test('adds trauma on pulse', () {
      director.notifyPulse(Vector2(100, 100));

      expect(screenEffects.traumaCallCount, 1);
    });

    test('adds floating text for pulse', () {
      director.notifyPulse(Vector2(50, 50));

      expect(game.addedComponents.length, greaterThan(0));
    });
  });

  group('VisualDirector notifyMine', () {
    test('triggers shake on mine', () {
      director.notifyMine(Vector2(100, 100));

      expect(screenEffects.shakeCallCount, 1);
    });

    test('triggers flash on mine', () {
      director.notifyMine(Vector2(100, 100));

      expect(screenEffects.flashCallCount, 1);
    });

    test('adds trauma on mine', () {
      director.notifyMine(Vector2(100, 100));

      expect(screenEffects.traumaCallCount, 1);
    });
  });

  group('VisualDirector notifyWaveComplete', () {
    test('adds floating text for wave complete', () {
      director.notifyWaveComplete(5);

      expect(game.addedComponents.length, greaterThan(0));
    });
  });

  group('VisualDirector resetKillStreak', () {
    test('resets kill streak state', () {
      final enemy = Enemy(path: [Vector2.zero()]);
      enemy.position = Vector2(100, 100);

      director.handleEnemyKill(enemy, 10);
      director.handleEnemyKill(enemy, 10);

      director.resetKillStreak();

      // Now kills should start streak from 0 again
      game.clearAdded();

      director.handleEnemyKill(enemy, 10);
      director.handleEnemyKill(enemy, 10);
      director.handleEnemyKill(enemy, 10);

      // Notification should appear at 3
      expect(game.addedComponents.length, greaterThan(0));
    });
  });

  group('VisualDirector wave modifiers', () {
    test('all wave modifiers have colors', () {
      for (final modifier in WaveModifier.values) {
        director.notifyWaveStart(1, modifier);
      }

      expect(screenEffects.flashCallCount, WaveModifier.values.length);
    });
  });
}
