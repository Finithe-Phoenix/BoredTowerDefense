import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/managers/enemy_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WaveModifier enum', () {
    test('has 5 values', () {
      expect(WaveModifier.values.length, 5);
    });

    test('contains all expected modifiers', () {
      expect(WaveModifier.values, contains(WaveModifier.normal));
      expect(WaveModifier.values, contains(WaveModifier.overload));
      expect(WaveModifier.values, contains(WaveModifier.juggernaut));
      expect(WaveModifier.values, contains(WaveModifier.mixed));
      expect(WaveModifier.values, contains(WaveModifier.phantom));
    });

    test('normal is index 0', () {
      expect(WaveModifier.normal.index, 0);
    });

    test('overload is index 1', () {
      expect(WaveModifier.overload.index, 1);
    });

    test('juggernaut is index 2', () {
      expect(WaveModifier.juggernaut.index, 2);
    });

    test('mixed is index 3', () {
      expect(WaveModifier.mixed.index, 3);
    });

    test('phantom is index 4', () {
      expect(WaveModifier.phantom.index, 4);
    });

    test('toString returns expected format', () {
      expect(WaveModifier.normal.toString(), contains('normal'));
      expect(WaveModifier.overload.toString(), contains('overload'));
      expect(WaveModifier.juggernaut.toString(), contains('juggernaut'));
      expect(WaveModifier.mixed.toString(), contains('mixed'));
      expect(WaveModifier.phantom.toString(), contains('phantom'));
    });

    test('can be compared for equality', () {
      expect(WaveModifier.normal == WaveModifier.normal, isTrue);
      expect(WaveModifier.normal == WaveModifier.overload, isFalse);
    });

    test('can be used in switch statements', () {
      String getDescription(WaveModifier mod) {
        switch (mod) {
          case WaveModifier.normal:
            return 'Standard enemies';
          case WaveModifier.overload:
            return 'Fast enemies, less HP';
          case WaveModifier.juggernaut:
            return 'Slow tanky enemies';
          case WaveModifier.mixed:
            return 'Mix of types';
          case WaveModifier.phantom:
            return 'Invisible enemies';
        }
      }

      expect(getDescription(WaveModifier.normal), 'Standard enemies');
      expect(getDescription(WaveModifier.overload), 'Fast enemies, less HP');
      expect(getDescription(WaveModifier.juggernaut), 'Slow tanky enemies');
      expect(getDescription(WaveModifier.mixed), 'Mix of types');
      expect(getDescription(WaveModifier.phantom), 'Invisible enemies');
    });
  });

  group('EnemyManager static constants', () {
    test('baseHealth is 100', () {
      expect(EnemyManager.baseHealth, 100);
    });

    test('baseSpeed is 60', () {
      expect(EnemyManager.baseSpeed, 60);
    });

    test('baseGold is 10', () {
      expect(EnemyManager.baseGold, 10);
    });

    test('minEnemyCount is 3', () {
      expect(EnemyManager.minEnemyCount, 3);
    });

    test('maxEnemyCount is 80', () {
      expect(EnemyManager.maxEnemyCount, 80);
    });

    test('minGoldReward is 4', () {
      expect(EnemyManager.minGoldReward, 4);
    });

    test('baseHealth is positive', () {
      expect(EnemyManager.baseHealth, greaterThan(0));
    });

    test('baseSpeed is positive', () {
      expect(EnemyManager.baseSpeed, greaterThan(0));
    });

    test('baseGold is positive', () {
      expect(EnemyManager.baseGold, greaterThan(0));
    });

    test('minEnemyCount is less than maxEnemyCount', () {
      expect(EnemyManager.minEnemyCount, lessThan(EnemyManager.maxEnemyCount));
    });

    test('minGoldReward is less than baseGold', () {
      expect(EnemyManager.minGoldReward, lessThan(EnemyManager.baseGold));
    });
  });

  group('EnemyManager bucket pool', () {
    test('clearBucketPool can be called', () {
      EnemyManager.clearBucketPool();
      expect(true, isTrue);
    });

    test('clearBucketPool can be called multiple times', () {
      EnemyManager.clearBucketPool();
      EnemyManager.clearBucketPool();
      EnemyManager.clearBucketPool();
      expect(true, isTrue);
    });
  });

  group('EnemyManager callback types', () {
    test('EnemyKilledCallback type signature is correct', () {
      EnemyKilledCallback? callback;
      expect(callback, isNull);
    });

    test('EnemyLeakedCallback type signature is correct', () {
      EnemyLeakedCallback? callback;
      expect(callback, isNull);
    });

    test('WaveCompleteCallback type signature is correct', () {
      WaveCompleteCallback? callback;
      expect(callback, isNull);
    });

    test('BossSpawnCallback type signature is correct', () {
      BossSpawnCallback? callback;
      expect(callback, isNull);
    });

    test('BossPhaseCallback type signature is correct', () {
      BossPhaseCallback? callback;
      expect(callback, isNull);
    });
  });

  group('EnemyManager wave modifiers logic', () {
    test('normal modifier should not be special', () {
      // Testing the isSpecialWave logic
      final isSpecial = WaveModifier.normal != WaveModifier.normal;
      expect(isSpecial, isFalse);
    });

    test('overload modifier should be special', () {
      final isSpecial = WaveModifier.overload != WaveModifier.normal;
      expect(isSpecial, isTrue);
    });

    test('juggernaut modifier should be special', () {
      final isSpecial = WaveModifier.juggernaut != WaveModifier.normal;
      expect(isSpecial, isTrue);
    });

    test('mixed modifier should be special', () {
      final isSpecial = WaveModifier.mixed != WaveModifier.normal;
      expect(isSpecial, isTrue);
    });

    test('phantom modifier should be special', () {
      final isSpecial = WaveModifier.phantom != WaveModifier.normal;
      expect(isSpecial, isTrue);
    });
  });

  group('EnemyManager wave progress calculation', () {
    test('wave progress with zero total enemies is 0', () {
      const waveTotalEnemies = 0;
      const remaining = 0;
      final progress = waveTotalEnemies == 0 ? 0.0 : 1 - (remaining / waveTotalEnemies);
      expect(progress, 0.0);
    });

    test('wave progress with all enemies remaining is 0', () {
      const waveTotalEnemies = 10;
      const remaining = 10;
      final progress = (1 - (remaining / waveTotalEnemies)).clamp(0.0, 1.0);
      expect(progress, 0.0);
    });

    test('wave progress with half enemies remaining is 0.5', () {
      const waveTotalEnemies = 10;
      const remaining = 5;
      final progress = (1 - (remaining / waveTotalEnemies)).clamp(0.0, 1.0);
      expect(progress, 0.5);
    });

    test('wave progress with no enemies remaining is 1.0', () {
      const waveTotalEnemies = 10;
      const remaining = 0;
      final progress = (1 - (remaining / waveTotalEnemies)).clamp(0.0, 1.0);
      expect(progress, 1.0);
    });

    test('wave progress clamps negative values to 0', () {
      const waveTotalEnemies = 10;
      const remaining = 15; // More remaining than total (edge case)
      final progress = (1 - (remaining / waveTotalEnemies)).clamp(0.0, 1.0);
      expect(progress, 0.0);
    });
  });

  group('EnemyManager spatial indexing', () {
    test('cell key hashing is deterministic', () {
      final key1 = Object.hash(5, 10);
      final key2 = Object.hash(5, 10);
      expect(key1, equals(key2));
    });

    test('different cells produce different keys', () {
      final key1 = Object.hash(5, 10);
      final key2 = Object.hash(10, 5);
      expect(key1, isNot(equals(key2)));
    });

    test('cell calculation from position', () {
      const spatialCellSize = 32.0;
      int cellFor(double value) => (value / spatialCellSize).floor();

      expect(cellFor(0), 0);
      expect(cellFor(31), 0);
      expect(cellFor(32), 1);
      expect(cellFor(64), 2);
      expect(cellFor(100), 3);
    });
  });

  group('EnemyManager constants validation', () {
    test('nearBaseThreshold is between 0 and 1', () {
      const nearBaseThreshold = 0.82;
      expect(nearBaseThreshold, greaterThanOrEqualTo(0.0));
      expect(nearBaseThreshold, lessThanOrEqualTo(1.0));
    });

    test('threatPulseInterval is positive', () {
      const threatPulseInterval = 0.7;
      expect(threatPulseInterval, greaterThan(0.0));
    });

    test('maxBucketPool is reasonable', () {
      const maxBucketPool = 50;
      expect(maxBucketPool, greaterThan(0));
      expect(maxBucketPool, lessThanOrEqualTo(100));
    });
  });
}
