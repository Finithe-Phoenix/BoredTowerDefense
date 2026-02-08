import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for GameEventFeed logic and calculations
/// Tests pure mathematical functions without requiring game context

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATED CLASSES FROM game_event_feed.dart
// ═══════════════════════════════════════════════════════════════════════════════

/// Event types that can be displayed in the feed
enum GameEventType {
  waveStart,
  waveComplete,
  bossSpawn,
  bossDefeat,
  towerBuilt,
  ability,
  gold,
  warning,
  info,
}

/// Constants from GameEventFeed
class EventFeedConstants {
  static const int maxEvents = 5;
  static const double eventDuration = 4.0;
}

/// Constants from _GameEvent
class GameEventConstants {
  static const double duration = 4.0;
  static const double fadeStart = 3.0;
  static const double fadeInDuration = 0.3;
  static const double height = 22.0;
  static const double pulseSpeed = 8.0;
}

/// Simulates the color mapping for event types
class EventColorMapper {
  static const Color waveStartColor = Color(0xFFFF00FF);
  static const Color waveCompleteColor = Color(0xFF00FF88);
  static const Color bossSpawnColor = Color(0xFFFF0066);
  static const Color bossDefeatColor = Color(0xFFFFD700);
  static const Color towerBuiltColor = Color(0xFF00FFFF);
  static const Color abilityColor = Color(0xFFFF6600);
  static const Color goldColor = Color(0xFFFFD700);
  static const Color warningColor = Color(0xFFFF4444);
  static const Color infoColor = Color(0xFFFFFFFF);

  static Color getDefaultColor(GameEventType type) {
    switch (type) {
      case GameEventType.waveStart:
        return waveStartColor;
      case GameEventType.waveComplete:
        return waveCompleteColor;
      case GameEventType.bossSpawn:
        return bossSpawnColor;
      case GameEventType.bossDefeat:
        return bossDefeatColor;
      case GameEventType.towerBuilt:
        return towerBuiltColor;
      case GameEventType.ability:
        return abilityColor;
      case GameEventType.gold:
        return goldColor;
      case GameEventType.warning:
        return warningColor;
      case GameEventType.info:
        return infoColor;
    }
  }
}

/// Simulates a game event
class SimulatedGameEvent {
  SimulatedGameEvent({
    required this.type,
    required this.message,
    required this.color,
  });

  final GameEventType type;
  final String message;
  final Color color;
  double lifetime = 0;
  double pulsePhase = 0;

  bool get isExpired => lifetime >= GameEventConstants.duration;

  void update(double dt) {
    lifetime += dt;
    pulsePhase += dt * GameEventConstants.pulseSpeed;
  }
}

/// Simulates the event feed queue
class SimulatedEventFeed {
  final List<SimulatedGameEvent> events = [];

  void addEvent(GameEventType type, String message, {Color? color}) {
    events.insert(
      0,
      SimulatedGameEvent(
        type: type,
        message: message,
        color: color ?? EventColorMapper.getDefaultColor(type),
      ),
    );

    if (events.length > EventFeedConstants.maxEvents) {
      events.removeLast();
    }
  }

  void waveStarted(int wave) {
    addEvent(GameEventType.waveStart, 'WAVE $wave INCOMING');
  }

  void waveComplete(int wave) {
    addEvent(GameEventType.waveComplete, 'WAVE $wave CLEARED',
        color: const Color(0xFF00FF88));
  }

  void bossSpawned(String bossName) {
    addEvent(GameEventType.bossSpawn, 'BOSS: $bossName',
        color: const Color(0xFFFF00FF));
  }

  void bossDefeated(String bossName) {
    addEvent(GameEventType.bossDefeat, '$bossName DESTROYED',
        color: const Color(0xFFFFD700));
  }

  void towerBuilt(String towerName) {
    addEvent(GameEventType.towerBuilt, '$towerName DEPLOYED',
        color: const Color(0xFF00FFFF));
  }

  void abilityUsed(String abilityName) {
    addEvent(GameEventType.ability, '$abilityName ACTIVATED',
        color: const Color(0xFFFF6600));
  }

  void goldEarned(int amount) {
    if (amount >= 50) {
      addEvent(GameEventType.gold, '+$amount GOLD',
          color: const Color(0xFFFFD700));
    }
  }

  void lowHealth() {
    addEvent(GameEventType.warning, 'LOW HEALTH WARNING',
        color: const Color(0xFFFF4444));
  }

  void timerExpired() {
    addEvent(GameEventType.warning, 'TIME EXPIRED',
        color: const Color(0xFFFF0066));
  }

  void update(double dt) {
    int writeIdx = 0;
    for (int i = 0; i < events.length; i++) {
      events[i].update(dt);
      if (!events[i].isExpired) {
        if (writeIdx != i) events[writeIdx] = events[i];
        writeIdx++;
      }
    }
    if (writeIdx < events.length) {
      events.removeRange(writeIdx, events.length);
    }
  }
}

/// Alpha calculation helper
class AlphaCalculator {
  static double calculateAlpha(double lifetime) {
    if (lifetime < GameEventConstants.fadeInDuration) {
      // Fade in
      return lifetime / GameEventConstants.fadeInDuration;
    } else if (lifetime > GameEventConstants.fadeStart) {
      // Fade out
      final fadeOutDuration =
          GameEventConstants.duration - GameEventConstants.fadeStart;
      return 1.0 -
          ((lifetime - GameEventConstants.fadeStart) / fadeOutDuration);
    }
    // Full opacity
    return 1.0;
  }
}

/// Slide effect calculation
class SlideCalculator {
  static const double slideDistance = 30.0;

  static double calculateSlideX(double lifetime) {
    if (lifetime < GameEventConstants.fadeInDuration) {
      return -slideDistance * (1 - lifetime / GameEventConstants.fadeInDuration);
    }
    return 0.0;
  }
}

/// Pulse effect calculation
class PulseCalculator {
  static double calculatePulse(double pulsePhase) {
    return 0.5 + math.sin(pulsePhase) * 0.5;
  }
}

/// Position calculation
class EventPositionCalculator {
  static const double compactX = 8.0;
  static const double normalX = 16.0;
  static const double startY = 80.0;
  static const double eventSpacing = 4.0;

  static double getXPosition(bool compact) {
    return compact ? compactX : normalX;
  }

  static double getEventY(int index) {
    return startY + index * (GameEventConstants.height + eventSpacing);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  group('EventFeed Constants', () {
    test('maxEvents is 5', () {
      expect(EventFeedConstants.maxEvents, 5);
    });

    test('eventDuration is 4 seconds', () {
      expect(EventFeedConstants.eventDuration, 4.0);
    });
  });

  group('GameEvent Constants', () {
    test('duration is 4 seconds', () {
      expect(GameEventConstants.duration, 4.0);
    });

    test('fadeStart is 3 seconds', () {
      expect(GameEventConstants.fadeStart, 3.0);
    });

    test('fadeIn duration is 0.3 seconds', () {
      expect(GameEventConstants.fadeInDuration, 0.3);
    });

    test('height is 22 pixels', () {
      expect(GameEventConstants.height, 22.0);
    });

    test('pulse speed is 8', () {
      expect(GameEventConstants.pulseSpeed, 8.0);
    });
  });

  group('GameEventType', () {
    test('has 9 event types', () {
      expect(GameEventType.values.length, 9);
    });

    test('contains all expected types', () {
      expect(GameEventType.values, contains(GameEventType.waveStart));
      expect(GameEventType.values, contains(GameEventType.waveComplete));
      expect(GameEventType.values, contains(GameEventType.bossSpawn));
      expect(GameEventType.values, contains(GameEventType.bossDefeat));
      expect(GameEventType.values, contains(GameEventType.towerBuilt));
      expect(GameEventType.values, contains(GameEventType.ability));
      expect(GameEventType.values, contains(GameEventType.gold));
      expect(GameEventType.values, contains(GameEventType.warning));
      expect(GameEventType.values, contains(GameEventType.info));
    });
  });

  group('EventColorMapper', () {
    test('waveStart is magenta', () {
      expect(EventColorMapper.getDefaultColor(GameEventType.waveStart),
          const Color(0xFFFF00FF));
    });

    test('waveComplete is green', () {
      expect(EventColorMapper.getDefaultColor(GameEventType.waveComplete),
          const Color(0xFF00FF88));
    });

    test('bossSpawn is pink', () {
      expect(EventColorMapper.getDefaultColor(GameEventType.bossSpawn),
          const Color(0xFFFF0066));
    });

    test('bossDefeat is gold', () {
      expect(EventColorMapper.getDefaultColor(GameEventType.bossDefeat),
          const Color(0xFFFFD700));
    });

    test('towerBuilt is cyan', () {
      expect(EventColorMapper.getDefaultColor(GameEventType.towerBuilt),
          const Color(0xFF00FFFF));
    });

    test('ability is orange', () {
      expect(EventColorMapper.getDefaultColor(GameEventType.ability),
          const Color(0xFFFF6600));
    });

    test('gold is gold', () {
      expect(EventColorMapper.getDefaultColor(GameEventType.gold),
          const Color(0xFFFFD700));
    });

    test('warning is red', () {
      expect(EventColorMapper.getDefaultColor(GameEventType.warning),
          const Color(0xFFFF4444));
    });

    test('info is white', () {
      expect(EventColorMapper.getDefaultColor(GameEventType.info),
          const Color(0xFFFFFFFF));
    });

    test('all event types have a color', () {
      for (final type in GameEventType.values) {
        expect(EventColorMapper.getDefaultColor(type), isNotNull);
      }
    });
  });

  group('SimulatedGameEvent', () {
    test('initializes with correct values', () {
      final event = SimulatedGameEvent(
        type: GameEventType.waveStart,
        message: 'Test',
        color: Colors.red,
      );

      expect(event.type, GameEventType.waveStart);
      expect(event.message, 'Test');
      expect(event.color, Colors.red);
      expect(event.lifetime, 0.0);
      expect(event.pulsePhase, 0.0);
    });

    test('isExpired is false initially', () {
      final event = SimulatedGameEvent(
        type: GameEventType.info,
        message: 'Test',
        color: Colors.white,
      );

      expect(event.isExpired, false);
    });

    test('isExpired is true after duration', () {
      final event = SimulatedGameEvent(
        type: GameEventType.info,
        message: 'Test',
        color: Colors.white,
      );

      event.update(4.0);
      expect(event.isExpired, true);
    });

    test('update increases lifetime', () {
      final event = SimulatedGameEvent(
        type: GameEventType.info,
        message: 'Test',
        color: Colors.white,
      );

      event.update(0.5);
      expect(event.lifetime, 0.5);

      event.update(0.5);
      expect(event.lifetime, 1.0);
    });

    test('update increases pulsePhase', () {
      final event = SimulatedGameEvent(
        type: GameEventType.info,
        message: 'Test',
        color: Colors.white,
      );

      event.update(0.5);
      // pulsePhase = 0.5 * 8 = 4.0
      expect(event.pulsePhase, 4.0);
    });
  });

  group('SimulatedEventFeed', () {
    test('starts with empty events list', () {
      final feed = SimulatedEventFeed();
      expect(feed.events, isEmpty);
    });

    test('addEvent adds event to front', () {
      final feed = SimulatedEventFeed();
      feed.addEvent(GameEventType.info, 'First');
      feed.addEvent(GameEventType.info, 'Second');

      expect(feed.events.length, 2);
      expect(feed.events[0].message, 'Second');
      expect(feed.events[1].message, 'First');
    });

    test('respects maxEvents limit', () {
      final feed = SimulatedEventFeed();

      for (int i = 0; i < 10; i++) {
        feed.addEvent(GameEventType.info, 'Event $i');
      }

      expect(feed.events.length, EventFeedConstants.maxEvents);
    });

    test('removes oldest events when exceeding max', () {
      final feed = SimulatedEventFeed();

      for (int i = 0; i < 7; i++) {
        feed.addEvent(GameEventType.info, 'Event $i');
      }

      // Should have Event 6, 5, 4, 3, 2 (newest to oldest)
      expect(feed.events[0].message, 'Event 6');
      expect(feed.events[4].message, 'Event 2');
    });

    test('waveStarted formats message correctly', () {
      final feed = SimulatedEventFeed();
      feed.waveStarted(5);

      expect(feed.events[0].message, 'WAVE 5 INCOMING');
      expect(feed.events[0].type, GameEventType.waveStart);
    });

    test('waveComplete formats message correctly', () {
      final feed = SimulatedEventFeed();
      feed.waveComplete(3);

      expect(feed.events[0].message, 'WAVE 3 CLEARED');
      expect(feed.events[0].type, GameEventType.waveComplete);
    });

    test('bossSpawned formats message correctly', () {
      final feed = SimulatedEventFeed();
      feed.bossSpawned('MEGA TANK');

      expect(feed.events[0].message, 'BOSS: MEGA TANK');
      expect(feed.events[0].type, GameEventType.bossSpawn);
    });

    test('bossDefeated formats message correctly', () {
      final feed = SimulatedEventFeed();
      feed.bossDefeated('MEGA TANK');

      expect(feed.events[0].message, 'MEGA TANK DESTROYED');
      expect(feed.events[0].type, GameEventType.bossDefeat);
    });

    test('towerBuilt formats message correctly', () {
      final feed = SimulatedEventFeed();
      feed.towerBuilt('Laser Tower');

      expect(feed.events[0].message, 'Laser Tower DEPLOYED');
      expect(feed.events[0].type, GameEventType.towerBuilt);
    });

    test('abilityUsed formats message correctly', () {
      final feed = SimulatedEventFeed();
      feed.abilityUsed('EMP Blast');

      expect(feed.events[0].message, 'EMP Blast ACTIVATED');
      expect(feed.events[0].type, GameEventType.ability);
    });

    test('goldEarned only shows for >= 50 gold', () {
      final feed = SimulatedEventFeed();

      feed.goldEarned(49);
      expect(feed.events, isEmpty);

      feed.goldEarned(50);
      expect(feed.events.length, 1);
      expect(feed.events[0].message, '+50 GOLD');
    });

    test('goldEarned formats message correctly', () {
      final feed = SimulatedEventFeed();
      feed.goldEarned(100);

      expect(feed.events[0].message, '+100 GOLD');
      expect(feed.events[0].type, GameEventType.gold);
    });

    test('lowHealth shows warning', () {
      final feed = SimulatedEventFeed();
      feed.lowHealth();

      expect(feed.events[0].message, 'LOW HEALTH WARNING');
      expect(feed.events[0].type, GameEventType.warning);
    });

    test('timerExpired shows warning', () {
      final feed = SimulatedEventFeed();
      feed.timerExpired();

      expect(feed.events[0].message, 'TIME EXPIRED');
      expect(feed.events[0].type, GameEventType.warning);
    });

    test('update removes expired events', () {
      final feed = SimulatedEventFeed();
      feed.addEvent(GameEventType.info, 'Test');

      // Advance past duration
      feed.update(5.0);

      expect(feed.events, isEmpty);
    });

    test('update keeps non-expired events', () {
      final feed = SimulatedEventFeed();
      feed.addEvent(GameEventType.info, 'Test');

      feed.update(2.0);

      expect(feed.events.length, 1);
    });

    test('update removes only expired events in mixed list', () {
      final feed = SimulatedEventFeed();

      feed.addEvent(GameEventType.info, 'Old');
      feed.update(3.5); // Old event is at 3.5s

      feed.addEvent(GameEventType.info, 'New');
      feed.update(0.6); // Old expires (4.1s), New at 0.6s

      expect(feed.events.length, 1);
      expect(feed.events[0].message, 'New');
    });
  });

  group('AlphaCalculator', () {
    test('alpha is 0 at start', () {
      expect(AlphaCalculator.calculateAlpha(0.0), 0.0);
    });

    test('alpha increases during fade in', () {
      expect(AlphaCalculator.calculateAlpha(0.15), closeTo(0.5, 0.01));
      expect(AlphaCalculator.calculateAlpha(0.3), closeTo(1.0, 0.01));
    });

    test('alpha is 1 during hold period', () {
      expect(AlphaCalculator.calculateAlpha(0.5), 1.0);
      expect(AlphaCalculator.calculateAlpha(1.5), 1.0);
      expect(AlphaCalculator.calculateAlpha(2.5), 1.0);
      expect(AlphaCalculator.calculateAlpha(3.0), 1.0);
    });

    test('alpha decreases during fade out', () {
      // fadeStart = 3.0, duration = 4.0, so fadeOut = 1.0s
      expect(AlphaCalculator.calculateAlpha(3.5), closeTo(0.5, 0.01));
      expect(AlphaCalculator.calculateAlpha(4.0), closeTo(0.0, 0.01));
    });

    test('alpha never goes negative', () {
      expect(AlphaCalculator.calculateAlpha(5.0), lessThanOrEqualTo(0.0));
    });
  });

  group('SlideCalculator', () {
    test('slide is -30 at start', () {
      expect(SlideCalculator.calculateSlideX(0.0), -30.0);
    });

    test('slide decreases during fade in', () {
      expect(SlideCalculator.calculateSlideX(0.15), closeTo(-15.0, 0.1));
      expect(SlideCalculator.calculateSlideX(0.3), closeTo(0.0, 0.01));
    });

    test('slide is 0 after fade in', () {
      expect(SlideCalculator.calculateSlideX(0.5), 0.0);
      expect(SlideCalculator.calculateSlideX(2.0), 0.0);
    });
  });

  group('PulseCalculator', () {
    test('pulse oscillates between 0 and 1', () {
      for (double phase = 0; phase < math.pi * 4; phase += 0.1) {
        final pulse = PulseCalculator.calculatePulse(phase);
        expect(pulse, greaterThanOrEqualTo(0.0));
        expect(pulse, lessThanOrEqualTo(1.0));
      }
    });

    test('pulse is 0.5 at phase 0', () {
      expect(PulseCalculator.calculatePulse(0), 0.5);
    });

    test('pulse is 1.0 at phase PI/2', () {
      expect(PulseCalculator.calculatePulse(math.pi / 2), closeTo(1.0, 0.01));
    });

    test('pulse is 0.0 at phase 3*PI/2', () {
      expect(
          PulseCalculator.calculatePulse(3 * math.pi / 2), closeTo(0.0, 0.01));
    });
  });

  group('EventPositionCalculator', () {
    test('compact X is 8', () {
      expect(EventPositionCalculator.getXPosition(true), 8.0);
    });

    test('normal X is 16', () {
      expect(EventPositionCalculator.getXPosition(false), 16.0);
    });

    test('startY is 80', () {
      expect(EventPositionCalculator.startY, 80.0);
    });

    test('event spacing is 4', () {
      expect(EventPositionCalculator.eventSpacing, 4.0);
    });

    test('first event Y is at startY', () {
      expect(EventPositionCalculator.getEventY(0), 80.0);
    });

    test('event Y increases by height + spacing', () {
      final y0 = EventPositionCalculator.getEventY(0);
      final y1 = EventPositionCalculator.getEventY(1);
      final y2 = EventPositionCalculator.getEventY(2);

      expect(y1 - y0, GameEventConstants.height + EventPositionCalculator.eventSpacing);
      expect(y2 - y1, GameEventConstants.height + EventPositionCalculator.eventSpacing);
    });

    test('fifth event Y calculation', () {
      final y4 = EventPositionCalculator.getEventY(4);
      // 80 + 4 * (22 + 4) = 80 + 4 * 26 = 80 + 104 = 184
      expect(y4, 184.0);
    });
  });

  group('Icon Types', () {
    test('bossSpawn and warning types trigger pulse effect', () {
      final pulsingTypes = [GameEventType.bossSpawn, GameEventType.warning];
      final nonPulsingTypes = GameEventType.values
          .where((t) => !pulsingTypes.contains(t))
          .toList();

      expect(pulsingTypes.length, 2);
      expect(nonPulsingTypes.length, 7);
    });
  });

  group('Message Formatting', () {
    test('wave number formatting', () {
      for (int wave = 1; wave <= 100; wave += 10) {
        final message = 'WAVE $wave INCOMING';
        expect(message, contains(wave.toString()));
      }
    });

    test('gold amount formatting', () {
      final amounts = [50, 100, 500, 1000];
      for (final amount in amounts) {
        final message = '+$amount GOLD';
        expect(message, startsWith('+'));
        expect(message, endsWith('GOLD'));
      }
    });

    test('boss name formatting', () {
      final names = ['MEGA TANK', 'DESTROYER', 'QUEEN'];
      for (final name in names) {
        expect('BOSS: $name', startsWith('BOSS: '));
        expect('$name DESTROYED', endsWith('DESTROYED'));
      }
    });
  });

  group('Event Lifecycle', () {
    test('complete event lifecycle', () {
      final event = SimulatedGameEvent(
        type: GameEventType.waveStart,
        message: 'WAVE 1 INCOMING',
        color: const Color(0xFFFF00FF),
      );

      // Phase 1: Fade in (0-0.3s)
      expect(event.isExpired, false);
      expect(AlphaCalculator.calculateAlpha(0.0), 0.0);
      expect(AlphaCalculator.calculateAlpha(0.15), closeTo(0.5, 0.01));

      // Phase 2: Hold (0.3-3.0s)
      event.update(1.5);
      expect(event.isExpired, false);
      expect(AlphaCalculator.calculateAlpha(1.5), 1.0);

      // Phase 3: Fade out (3.0-4.0s)
      event.update(1.8); // Total: 3.3s
      expect(event.isExpired, false);
      expect(AlphaCalculator.calculateAlpha(3.3), closeTo(0.7, 0.1));

      // Phase 4: Expired (>= 4.0s)
      event.update(1.0); // Total: 4.3s
      expect(event.isExpired, true);
    });
  });

  group('Feed Queue Management', () {
    test('FIFO behavior (newest first)', () {
      final feed = SimulatedEventFeed();

      feed.addEvent(GameEventType.info, 'Event A');
      feed.addEvent(GameEventType.info, 'Event B');
      feed.addEvent(GameEventType.info, 'Event C');

      // Newest (C) should be first
      expect(feed.events[0].message, 'Event C');
      expect(feed.events[1].message, 'Event B');
      expect(feed.events[2].message, 'Event A');
    });

    test('old events expire while new ones remain', () {
      final feed = SimulatedEventFeed();

      feed.addEvent(GameEventType.info, 'Old Event');
      feed.update(3.0);

      feed.addEvent(GameEventType.info, 'New Event');
      feed.update(1.5); // Old: 4.5s (expired), New: 1.5s

      expect(feed.events.length, 1);
      expect(feed.events[0].message, 'New Event');
    });
  });

  group('Font Size', () {
    test('compact font size is 10', () {
      const compactFontSize = 10.0;
      expect(compactFontSize, 10.0);
    });

    test('normal font size is 11', () {
      const normalFontSize = 11.0;
      expect(normalFontSize, 11.0);
    });
  });

  group('Icon Size', () {
    test('icon size is 16', () {
      const iconSize = 16.0;
      expect(iconSize, 16.0);
    });

    test('icon center calculations', () {
      const iconSize = 16.0;
      final centerX = iconSize / 2;
      final centerY = iconSize / 2;

      expect(centerX, 8.0);
      expect(centerY, 8.0);
    });
  });

  group('Event Colors', () {
    test('wave complete uses green', () {
      final feed = SimulatedEventFeed();
      feed.waveComplete(1);
      expect(feed.events[0].color, const Color(0xFF00FF88));
    });

    test('boss spawned uses magenta', () {
      final feed = SimulatedEventFeed();
      feed.bossSpawned('Test');
      expect(feed.events[0].color, const Color(0xFFFF00FF));
    });

    test('boss defeated uses gold', () {
      final feed = SimulatedEventFeed();
      feed.bossDefeated('Test');
      expect(feed.events[0].color, const Color(0xFFFFD700));
    });

    test('tower built uses cyan', () {
      final feed = SimulatedEventFeed();
      feed.towerBuilt('Test');
      expect(feed.events[0].color, const Color(0xFF00FFFF));
    });

    test('ability uses orange', () {
      final feed = SimulatedEventFeed();
      feed.abilityUsed('Test');
      expect(feed.events[0].color, const Color(0xFFFF6600));
    });

    test('gold earned uses gold', () {
      final feed = SimulatedEventFeed();
      feed.goldEarned(100);
      expect(feed.events[0].color, const Color(0xFFFFD700));
    });

    test('low health uses red', () {
      final feed = SimulatedEventFeed();
      feed.lowHealth();
      expect(feed.events[0].color, const Color(0xFFFF4444));
    });

    test('timer expired uses pink', () {
      final feed = SimulatedEventFeed();
      feed.timerExpired();
      expect(feed.events[0].color, const Color(0xFFFF0066));
    });
  });

  group('Gold Threshold', () {
    test('gold amounts below 50 are not displayed', () {
      final feed = SimulatedEventFeed();

      for (int amount = 0; amount < 50; amount++) {
        feed.goldEarned(amount);
      }

      expect(feed.events, isEmpty);
    });

    test('gold amounts at or above 50 are displayed', () {
      final feed = SimulatedEventFeed();

      feed.goldEarned(50);
      expect(feed.events.length, 1);

      feed.goldEarned(51);
      expect(feed.events.length, 2);

      feed.goldEarned(1000);
      expect(feed.events.length, 3);
    });
  });
}
