import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/bloc/game/game_event.dart';

void main() {
  group('GameEvent base class', () {
    test('GameEvent props is empty by default', () {
      const event = EnemyLeaked();
      expect(event.props, isEmpty);
    });
  });

  group('GameStarted', () {
    test('events with same props are equal', () {
      const a = GameStarted(
        levelId: 1,
        startingGold: 200,
        startingLives: 20,
        totalWaves: 10,
      );
      const b = GameStarted(
        levelId: 1,
        startingGold: 200,
        startingLives: 20,
        totalWaves: 10,
      );
      const c = GameStarted(
        levelId: 2,
        startingGold: 200,
        startingLives: 20,
        totalWaves: 10,
      );

      expect(a, equals(b));
      expect(a == c, isFalse);
    });

    test('props contains all fields', () {
      const event = GameStarted(
        levelId: 5,
        startingGold: 300,
        startingLives: 15,
        totalWaves: 8,
      );
      expect(event.props, containsAll([5, 300, 15, 8]));
      expect(event.props.length, 4);
    });

    test('fields are accessible', () {
      const event = GameStarted(
        levelId: 3,
        startingGold: 250,
        startingLives: 18,
        totalWaves: 12,
      );
      expect(event.levelId, 3);
      expect(event.startingGold, 250);
      expect(event.startingLives, 18);
      expect(event.totalWaves, 12);
    });
  });

  group('GoldChanged', () {
    test('equality by amount', () {
      const a = GoldChanged(50);
      const b = GoldChanged(50);
      const c = GoldChanged(100);

      expect(a, equals(b));
      expect(a == c, isFalse);
    });

    test('props contains amount', () {
      const event = GoldChanged(75);
      expect(event.props, [75]);
      expect(event.amount, 75);
    });

    test('can represent negative amounts', () {
      const event = GoldChanged(-50);
      expect(event.amount, -50);
    });
  });

  group('LivesChanged', () {
    test('equality by amount', () {
      const a = LivesChanged(-1);
      const b = LivesChanged(-1);
      const c = LivesChanged(-2);

      expect(a, equals(b));
      expect(a == c, isFalse);
    });

    test('props contains amount', () {
      const event = LivesChanged(-3);
      expect(event.props, [-3]);
      expect(event.amount, -3);
    });
  });

  group('ScoreIncreased', () {
    test('equality by amount', () {
      const a = ScoreIncreased(100);
      const b = ScoreIncreased(100);
      const c = ScoreIncreased(200);

      expect(a, equals(b));
      expect(a == c, isFalse);
    });

    test('props contains amount', () {
      const event = ScoreIncreased(500);
      expect(event.props, [500]);
      expect(event.amount, 500);
    });
  });

  group('WaveStarted', () {
    test('equality by wave number', () {
      const a = WaveStarted(1);
      const b = WaveStarted(1);
      const c = WaveStarted(2);

      expect(a, equals(b));
      expect(a == c, isFalse);
    });

    test('props contains wave number', () {
      const event = WaveStarted(5);
      expect(event.props, [5]);
      expect(event.waveNumber, 5);
    });
  });

  group('WaveCompleted', () {
    test('equality by wave number', () {
      const a = WaveCompleted(3);
      const b = WaveCompleted(3);
      const c = WaveCompleted(4);

      expect(a, equals(b));
      expect(a == c, isFalse);
    });

    test('props contains wave number', () {
      const event = WaveCompleted(7);
      expect(event.props, [7]);
      expect(event.waveNumber, 7);
    });
  });

  group('EnemyKilled', () {
    test('equality by gold reward', () {
      const a = EnemyKilled(goldReward: 10);
      const b = EnemyKilled(goldReward: 10);
      const c = EnemyKilled(goldReward: 20);

      expect(a, equals(b));
      expect(a == c, isFalse);
    });

    test('props contains gold reward', () {
      const event = EnemyKilled(goldReward: 15);
      expect(event.props, [15]);
      expect(event.goldReward, 15);
    });
  });

  group('EnemyLeaked', () {
    test('simple events compare by type', () {
      const leak1 = EnemyLeaked();
      const leak2 = EnemyLeaked();
      const pause = GamePauseToggled();

      expect(leak1, equals(leak2));
      expect(leak1 == pause, isFalse);
    });

    test('props is empty', () {
      const event = EnemyLeaked();
      expect(event.props, isEmpty);
    });
  });

  group('TowerPlaced', () {
    test('equality by cost and tower type', () {
      const a = TowerPlaced(cost: 50, towerType: 'pulseArcher');
      const b = TowerPlaced(cost: 50, towerType: 'pulseArcher');
      const c = TowerPlaced(cost: 50, towerType: 'circuitCannon');
      const d = TowerPlaced(cost: 100, towerType: 'pulseArcher');

      expect(a, equals(b));
      expect(a == c, isFalse);
      expect(a == d, isFalse);
    });

    test('props contains cost and tower type', () {
      const event = TowerPlaced(cost: 80, towerType: 'phaseMage');
      expect(event.props, containsAll([80, 'phaseMage']));
      expect(event.cost, 80);
      expect(event.towerType, 'phaseMage');
    });
  });

  group('PulseActivated', () {
    test('equality by cost', () {
      const a = PulseActivated(cost: 25);
      const b = PulseActivated(cost: 25);
      const c = PulseActivated(cost: 50);

      expect(a, equals(b));
      expect(a == c, isFalse);
    });

    test('props contains cost', () {
      const event = PulseActivated(cost: 30);
      expect(event.props, [30]);
      expect(event.cost, 30);
    });
  });

  group('GamePauseToggled', () {
    test('all instances are equal', () {
      const a = GamePauseToggled();
      const b = GamePauseToggled();

      expect(a, equals(b));
    });

    test('props is empty', () {
      const event = GamePauseToggled();
      expect(event.props, isEmpty);
    });
  });

  group('GameOver', () {
    test('all instances are equal', () {
      const a = GameOver();
      const b = GameOver();

      expect(a, equals(b));
    });

    test('props is empty', () {
      const event = GameOver();
      expect(event.props, isEmpty);
    });
  });

  group('Victory', () {
    test('all instances are equal', () {
      const a = Victory();
      const b = Victory();

      expect(a, equals(b));
    });

    test('props is empty', () {
      const event = Victory();
      expect(event.props, isEmpty);
    });
  });

  group('GameReset', () {
    test('all instances are equal', () {
      const a = GameReset();
      const b = GameReset();

      expect(a, equals(b));
    });

    test('props is empty', () {
      const event = GameReset();
      expect(event.props, isEmpty);
    });
  });

  group('Event type differentiation', () {
    test('different event types are not equal', () {
      const gameOver = GameOver();
      const victory = Victory();
      const reset = GameReset();
      const pause = GamePauseToggled();
      const leak = EnemyLeaked();

      expect(gameOver == victory, isFalse);
      expect(victory == reset, isFalse);
      expect(reset == pause, isFalse);
      expect(pause == leak, isFalse);
    });

    test('parameterized events with same values but different types are not equal', () {
      const waveStarted = WaveStarted(1);
      const waveCompleted = WaveCompleted(1);

      expect(waveStarted == waveCompleted, isFalse);
    });
  });
}
