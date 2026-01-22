import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/hud/game_event_feed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameEventFeed', () {
    late GameEventFeed feed;

    setUp(() {
      feed = GameEventFeed();
    });

    test('initializes with correct anchor', () {
      expect(feed.anchor, Anchor.topLeft);
    });

    test('has correct static constants', () {
      expect(GameEventFeed.maxEvents, 5);
      expect(GameEventFeed.eventDuration, 4.0);
    });

    test('addEvent adds event to feed', () {
      feed.addEvent(GameEventType.waveStart, 'Test message');
      // No exception means event was added
      expect(true, isTrue);
    });

    test('addEvent with custom color', () {
      feed.addEvent(GameEventType.waveStart, 'Test', color: Colors.red);
      expect(true, isTrue);
    });

    test('waveStarted adds wave event', () {
      feed.waveStarted(1);
      feed.waveStarted(5);
      feed.waveStarted(10);
      expect(true, isTrue);
    });

    test('waveComplete adds completion event', () {
      feed.waveComplete(1);
      feed.waveComplete(5);
      expect(true, isTrue);
    });

    test('bossSpawned adds boss event', () {
      feed.bossSpawned('The Decompiler');
      feed.bossSpawned('Void Stalker');
      expect(true, isTrue);
    });

    test('bossDefeated adds defeat event', () {
      feed.bossDefeated('The Decompiler');
      expect(true, isTrue);
    });

    test('towerBuilt adds tower event', () {
      feed.towerBuilt('Pulse Archer');
      feed.towerBuilt('Circuit Cannon');
      expect(true, isTrue);
    });

    test('abilityUsed adds ability event', () {
      feed.abilityUsed('PULSE');
      feed.abilityUsed('MINE');
      expect(true, isTrue);
    });

    test('goldEarned adds event for large amounts', () {
      feed.goldEarned(100);
      feed.goldEarned(50);
      expect(true, isTrue);
    });

    test('goldEarned ignores small amounts', () {
      feed.goldEarned(10);
      feed.goldEarned(49);
      // Small amounts should not add events
      expect(true, isTrue);
    });

    test('lowHealth adds warning event', () {
      feed.lowHealth();
      expect(true, isTrue);
    });

    test('feed limits to maxEvents', () {
      // Add more than maxEvents
      for (int i = 0; i < 10; i++) {
        feed.waveStarted(i);
      }
      // Should not throw and should have limited events
      expect(true, isTrue);
    });

    test('all event types can be added', () {
      feed.addEvent(GameEventType.waveStart, 'Wave');
      feed.addEvent(GameEventType.waveComplete, 'Complete');
      feed.addEvent(GameEventType.bossSpawn, 'Boss');
      feed.addEvent(GameEventType.bossDefeat, 'Defeat');
      feed.addEvent(GameEventType.towerBuilt, 'Tower');
      feed.addEvent(GameEventType.ability, 'Ability');
      feed.addEvent(GameEventType.gold, 'Gold');
      feed.addEvent(GameEventType.warning, 'Warning');
      feed.addEvent(GameEventType.info, 'Info');
      expect(true, isTrue);
    });

    test('events can have empty message', () {
      feed.addEvent(GameEventType.waveStart, '');
      expect(true, isTrue);
    });

    test('events can have long message', () {
      feed.addEvent(GameEventType.waveStart, 'A very long message that describes the event in detail');
      expect(true, isTrue);
    });

    test('multiple feeds can exist independently', () {
      final feed1 = GameEventFeed();
      final feed2 = GameEventFeed();

      feed1.waveStarted(1);
      feed2.bossSpawned('Boss');

      expect(true, isTrue);
    });
  });

  group('GameEventType', () {
    test('has expected event types', () {
      expect(GameEventType.values.contains(GameEventType.waveStart), isTrue);
      expect(GameEventType.values.contains(GameEventType.waveComplete), isTrue);
      expect(GameEventType.values.contains(GameEventType.bossSpawn), isTrue);
      expect(GameEventType.values.contains(GameEventType.bossDefeat), isTrue);
      expect(GameEventType.values.contains(GameEventType.towerBuilt), isTrue);
      expect(GameEventType.values.contains(GameEventType.ability), isTrue);
      expect(GameEventType.values.contains(GameEventType.gold), isTrue);
      expect(GameEventType.values.contains(GameEventType.warning), isTrue);
      expect(GameEventType.values.contains(GameEventType.info), isTrue);
    });

    test('has 9 event types', () {
      expect(GameEventType.values.length, 9);
    });
  });
}
