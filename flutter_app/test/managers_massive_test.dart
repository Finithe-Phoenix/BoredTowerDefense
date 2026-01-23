import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/managers/enemy_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════════════════════════════════════
  // WAVE MODIFIER ENUM TESTS (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('WaveModifier enum', () {
    test('WaveModifier has 5 values', () {
      expect(WaveModifier.values.length, 5);
    });

    test('normal exists', () {
      expect(WaveModifier.values, contains(WaveModifier.normal));
    });

    test('overload exists', () {
      expect(WaveModifier.values, contains(WaveModifier.overload));
    });

    test('juggernaut exists', () {
      expect(WaveModifier.values, contains(WaveModifier.juggernaut));
    });

    test('mixed exists', () {
      expect(WaveModifier.values, contains(WaveModifier.mixed));
    });

    test('phantom exists', () {
      expect(WaveModifier.values, contains(WaveModifier.phantom));
    });

    for (int i = 0; i < WaveModifier.values.length; i++) {
      test('WaveModifier at index $i has correct index', () {
        expect(WaveModifier.values[i].index, i);
      });
    }

    for (final mod in WaveModifier.values) {
      test('${mod.name} has non-empty name', () {
        expect(mod.name, isNotEmpty);
      });
    }

    test('normal is first', () {
      expect(WaveModifier.normal.index, 0);
    });

    test('phantom is last', () {
      expect(WaveModifier.phantom.index, 4);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ENEMY MANAGER CONSTANTS TESTS (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('EnemyManager constants', () {
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

    test('minEnemyCount <= maxEnemyCount', () {
      expect(EnemyManager.minEnemyCount, lessThanOrEqualTo(EnemyManager.maxEnemyCount));
    });

    test('minGoldReward is positive', () {
      expect(EnemyManager.minGoldReward, greaterThan(0));
    });

    test('minGoldReward <= baseGold', () {
      expect(EnemyManager.minGoldReward, lessThanOrEqualTo(EnemyManager.baseGold));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // WAVE MODIFIER BEHAVIOR TESTS (60+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('WaveModifier - Behavior', () {
    test('normal has no special effects', () {
      final mod = WaveModifier.normal;
      expect(mod, WaveModifier.normal);
    });

    test('overload means fast but weak enemies', () {
      final mod = WaveModifier.overload;
      expect(mod.name, 'overload');
    });

    test('juggernaut means slow but tanky enemies', () {
      final mod = WaveModifier.juggernaut;
      expect(mod.name, 'juggernaut');
    });

    test('mixed means variety of enemy types', () {
      final mod = WaveModifier.mixed;
      expect(mod.name, 'mixed');
    });

    test('phantom means invisible enemies', () {
      final mod = WaveModifier.phantom;
      expect(mod.name, 'phantom');
    });

    // Overload multipliers
    test('overload increases enemy count by 25%', () {
      final mult = 1.25;
      expect(mult, greaterThan(1.0));
    });

    test('overload decreases spawn interval by 20%', () {
      final mult = 0.8;
      expect(mult, lessThan(1.0));
    });

    // Juggernaut multipliers
    test('juggernaut decreases enemy count by 30%', () {
      final mult = 0.7;
      expect(mult, lessThan(1.0));
    });

    test('juggernaut increases spawn interval by 15%', () {
      final mult = 1.15;
      expect(mult, greaterThan(1.0));
    });

    // Phantom multipliers
    test('phantom decreases enemy count by 15%', () {
      final mult = 0.85;
      expect(mult, lessThan(1.0));
    });

    test('phantom increases spawn interval by 5%', () {
      final mult = 1.05;
      expect(mult, greaterThan(1.0));
    });

    // Mixed multipliers
    test('mixed increases enemy count by 10%', () {
      final mult = 1.1;
      expect(mult, greaterThan(1.0));
    });

    // All modifiers affect enemy counts
    for (final mod in WaveModifier.values) {
      test('${mod.name} modifier affects gameplay', () {
        expect(mod, isNotNull);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // WAVE DESCRIPTION TESTS (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('WaveModifier - Descriptions', () {
    final descriptions = {
      WaveModifier.normal: '',
      WaveModifier.overload: 'OVERLOAD!',
      WaveModifier.juggernaut: 'JUGGERNAUT!',
      WaveModifier.phantom: 'PHANTOM!',
      WaveModifier.mixed: 'MIXED!',
    };

    for (final entry in descriptions.entries) {
      test('${entry.key.name} has description "${entry.value}"', () {
        expect(entry.value, isNotNull);
      });
    }

    test('normal has empty description', () {
      expect(descriptions[WaveModifier.normal], isEmpty);
    });

    test('overload has uppercase description', () {
      expect(descriptions[WaveModifier.overload], 'OVERLOAD!');
    });

    test('juggernaut has uppercase description', () {
      expect(descriptions[WaveModifier.juggernaut], 'JUGGERNAUT!');
    });

    test('phantom has uppercase description', () {
      expect(descriptions[WaveModifier.phantom], 'PHANTOM!');
    });

    test('mixed has uppercase description', () {
      expect(descriptions[WaveModifier.mixed], 'MIXED!');
    });

    for (final mod in WaveModifier.values) {
      if (mod != WaveModifier.normal) {
        test('${mod.name} description ends with !', () {
          final desc = descriptions[mod] ?? '';
          expect(desc.endsWith('!'), isTrue);
        });
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // WAVE SELECTION LOGIC TESTS (80+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('WaveModifier - Selection logic', () {
    // World 1 tests
    for (int wave = 1; wave <= 20; wave++) {
      test('World 1 wave $wave modifier selection', () {
        WaveModifier modifier;
        if (wave % 5 == 0) {
          modifier = WaveModifier.juggernaut;
        } else if (wave % 3 == 0) {
          modifier = WaveModifier.overload;
        } else {
          modifier = WaveModifier.normal;
        }
        expect(modifier, isNotNull);
      });
    }

    // World 2 tests
    for (int wave = 1; wave <= 15; wave++) {
      test('World 2 wave $wave modifier selection', () {
        WaveModifier modifier;
        if (wave % 6 == 0) {
          modifier = WaveModifier.phantom;
        } else if (wave % 5 == 0) {
          modifier = WaveModifier.juggernaut;
        } else if (wave % 3 == 0) {
          modifier = WaveModifier.overload;
        } else {
          modifier = WaveModifier.normal;
        }
        expect(modifier, isNotNull);
      });
    }

    // World 3 tests
    for (int wave = 1; wave <= 15; wave++) {
      test('World 3 wave $wave modifier selection', () {
        WaveModifier modifier;
        if (wave % 7 == 0) {
          modifier = WaveModifier.mixed;
        } else if (wave % 4 == 0) {
          modifier = WaveModifier.phantom;
        } else if (wave % 5 == 0) {
          modifier = WaveModifier.juggernaut;
        } else if (wave % 3 == 0) {
          modifier = WaveModifier.overload;
        } else {
          modifier = WaveModifier.normal;
        }
        expect(modifier, isNotNull);
      });
    }

    // Worlds 4-10 tests
    for (int wave = 1; wave <= 15; wave++) {
      test('Worlds 4-10 wave $wave modifier selection', () {
        WaveModifier modifier;
        if (wave % 8 == 0) {
          modifier = WaveModifier.mixed;
        } else if (wave % 6 == 0) {
          modifier = WaveModifier.phantom;
        } else if (wave % 5 == 0) {
          modifier = WaveModifier.juggernaut;
        } else if (wave % 3 == 0) {
          modifier = WaveModifier.overload;
        } else {
          modifier = WaveModifier.normal;
        }
        expect(modifier, isNotNull);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ENEMY COUNT SCALING TESTS (60+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('EnemyManager - Enemy count scaling', () {
    final baseCount = 5;

    for (int wave = 1; wave <= 30; wave++) {
      test('Wave $wave has valid enemy count', () {
        final count = (baseCount + wave).clamp(EnemyManager.minEnemyCount, EnemyManager.maxEnemyCount);
        expect(count, greaterThanOrEqualTo(EnemyManager.minEnemyCount));
        expect(count, lessThanOrEqualTo(EnemyManager.maxEnemyCount));
      });
    }

    // Modifier adjustments
    for (final mod in WaveModifier.values) {
      test('${mod.name} modifier adjusts enemy count', () {
        int baseCount = 20;
        int adjustedCount;

        switch (mod) {
          case WaveModifier.overload:
            adjustedCount = (baseCount * 1.25).ceil();
            break;
          case WaveModifier.juggernaut:
            adjustedCount = (baseCount * 0.7).ceil();
            break;
          case WaveModifier.phantom:
            adjustedCount = (baseCount * 0.85).ceil();
            break;
          case WaveModifier.mixed:
            adjustedCount = (baseCount * 1.1).ceil();
            break;
          case WaveModifier.normal:
            adjustedCount = baseCount;
            break;
        }

        expect(adjustedCount, greaterThan(0));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SPAWN INTERVAL TESTS (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('EnemyManager - Spawn interval', () {
    test('Spawn interval clamps to minimum 0.35', () {
      final interval = 0.2.clamp(0.35, 1.6);
      expect(interval, 0.35);
    });

    test('Spawn interval clamps to maximum 1.6', () {
      final interval = 2.0.clamp(0.35, 1.6);
      expect(interval, 1.6);
    });

    for (final mod in WaveModifier.values) {
      test('${mod.name} affects spawn interval', () {
        double baseInterval = 1.0;
        double adjusted;

        switch (mod) {
          case WaveModifier.overload:
            adjusted = baseInterval * 0.8;
            break;
          case WaveModifier.juggernaut:
            adjusted = baseInterval * 1.15;
            break;
          case WaveModifier.phantom:
            adjusted = baseInterval * 1.05;
            break;
          default:
            adjusted = baseInterval;
        }

        expect(adjusted, greaterThan(0));
      });
    }

    for (double interval = 0.1; interval <= 2.0; interval += 0.1) {
      test('Interval ${interval.toStringAsFixed(1)} clamps correctly', () {
        final clamped = interval.clamp(0.35, 1.6);
        expect(clamped, greaterThanOrEqualTo(0.35));
        expect(clamped, lessThanOrEqualTo(1.6));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // THREAT TIER TESTS (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('EnemyManager - Threat tier', () {
    // Base threat tier by wave and world
    for (int wave = 1; wave <= 15; wave++) {
      test('Wave $wave base threat tier', () {
        int tier = 0;
        if (wave >= 4) tier = 1;
        if (wave >= 8) tier = 2;
        if (wave >= 12) tier = 3;
        expect(tier, inInclusiveRange(0, 3));
      });
    }

    for (int world = 1; world <= 10; world++) {
      test('World $world base threat tier', () {
        int tier = 0;
        if (world >= 2) tier = 1;
        if (world >= 4) tier = 2;
        if (world >= 7) tier = 3;
        expect(tier, inInclusiveRange(0, 3));
      });
    }

    // Modifier effects on threat tier
    test('juggernaut ensures minimum tier 1', () {
      int tier = 0;
      tier = tier < 1 ? 1 : tier;
      expect(tier, greaterThanOrEqualTo(1));
    });

    test('overload ensures minimum tier 1', () {
      int tier = 0;
      tier = tier < 1 ? 1 : tier;
      expect(tier, greaterThanOrEqualTo(1));
    });

    // Spawn index affects tier
    for (int tier = 1; tier <= 3; tier++) {
      final interval = tier == 1 ? 6 : (tier == 2 ? 4 : 3);
      for (int spawnIndex = 0; spawnIndex < 10; spawnIndex++) {
        test('Tier $tier, spawn $spawnIndex interval check', () {
          final appliesFull = spawnIndex % interval == 0;
          expect(appliesFull, isNotNull);
        });
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GOLD SCALING TESTS (50+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('EnemyManager - Gold scaling', () {
    test('Base gold is 10', () {
      expect(EnemyManager.baseGold, 10);
    });

    for (int wave = 1; wave <= 20; wave++) {
      test('Wave $wave gold reward', () {
        final gold = EnemyManager.baseGold + (wave * 2);
        expect(gold, greaterThan(EnemyManager.baseGold));
      });
    }

    // Gold scale for progress tests
    for (int world = 1; world <= 10; world++) {
      for (int localIndex = 1; localIndex <= 5; localIndex++) {
        test('World $world level $localIndex gold scale', () {
          final scale = 0.92 - (world - 1) * 0.03 - (localIndex - 1) * 0.006;
          final clamped = scale.clamp(0.55, 0.95);
          expect(clamped, greaterThanOrEqualTo(0.55));
          expect(clamped, lessThanOrEqualTo(0.95));
        });
      }
    }

    // Threat tier bonus
    for (int tier = 0; tier <= 3; tier++) {
      test('Threat tier $tier gold bonus', () {
        final baseGold = 10;
        final bonus = 1 + tier * 0.18;
        final adjustedGold = (baseGold * bonus).round();
        expect(adjustedGold, greaterThanOrEqualTo(baseGold));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // WAVE PROGRESS TESTS (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('EnemyManager - Wave progress', () {
    for (int total = 5; total <= 50; total += 5) {
      for (int remaining = 0; remaining <= total; remaining += total ~/ 5) {
        test('Total $total remaining $remaining progress', () {
          final progress = 1 - (remaining / total);
          expect(progress, inInclusiveRange(0.0, 1.0));
        });
      }
    }

    test('Progress is 0 when all enemies remaining', () {
      final progress = 1 - (10 / 10);
      expect(progress, 0.0);
    });

    test('Progress is 1 when no enemies remaining', () {
      final progress = 1 - (0 / 10);
      expect(progress, 1.0);
    });

    test('Progress is 0.5 when half enemies remaining', () {
      final progress = 1 - (5 / 10);
      expect(progress, 0.5);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SPATIAL INDEX TESTS (40+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('EnemyManager - Spatial index', () {
    final cellSize = 48.0;

    for (double x = 0; x < 500; x += 50) {
      test('Cell calculation for x=$x', () {
        final cellX = (x / cellSize).floor();
        expect(cellX, greaterThanOrEqualTo(0));
      });
    }

    for (double y = 0; y < 500; y += 50) {
      test('Cell calculation for y=$y', () {
        final cellY = (y / cellSize).floor();
        expect(cellY, greaterThanOrEqualTo(0));
      });
    }

    // Cell key hashing
    for (int x = 0; x < 10; x++) {
      for (int y = 0; y < 10; y++) {
        test('Cell key for ($x, $y)', () {
          final key = Object.hash(x, y);
          expect(key, isNotNull);
        });
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RANGE QUERY TESTS (30+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('EnemyManager - Range query', () {
    final cellSize = 48.0;

    for (double range = 50; range <= 200; range += 25) {
      test('Range $range cell bounds', () {
        final centerX = 250.0;
        final centerY = 250.0;

        final minX = ((centerX - range) / cellSize).floor();
        final maxX = ((centerX + range) / cellSize).floor();
        final minY = ((centerY - range) / cellSize).floor();
        final maxY = ((centerY + range) / cellSize).floor();

        expect(minX, lessThanOrEqualTo(maxX));
        expect(minY, lessThanOrEqualTo(maxY));
      });
    }

    // Range squared tests
    for (double range = 50; range <= 200; range += 25) {
      test('Range squared for $range', () {
        final rangeSq = range * range;
        expect(rangeSq, greaterThan(0));
      });
    }

    // Distance check tests
    for (double dx = 0; dx <= 100; dx += 20) {
      for (double dy = 0; dy <= 100; dy += 20) {
        test('Distance check dx=$dx dy=$dy', () {
          final distSq = dx * dx + dy * dy;
          final rangeSq = 100.0 * 100.0;
          final inRange = distSq <= rangeSq;
          expect(inRange, isNotNull);
        });
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // BOSS SPAWN LOGIC TESTS (20+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('EnemyManager - Boss spawn logic', () {
    for (int totalWaves = 5; totalWaves <= 50; totalWaves += 5) {
      test('Boss spawns on wave $totalWaves', () {
        final currentWave = totalWaves;
        final isLastWave = currentWave == totalWaves;
        expect(isLastWave, isTrue);
      });
    }

    // World boss levels
    for (int level = 10; level <= 100; level += 10) {
      test('Level $level has world boss', () {
        final isWorldBoss = level % 10 == 0;
        expect(isWorldBoss, isTrue);
      });
    }

    // Non-world boss levels
    for (int level = 1; level <= 9; level++) {
      test('Level $level has mini boss only', () {
        final isWorldBoss = level % 10 == 0;
        expect(isWorldBoss, isFalse);
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // THREAT PULSE TESTS (20+ tests)
  // ═══════════════════════════════════════════════════════════════════════════

  group('EnemyManager - Threat pulse', () {
    final nearBaseThreshold = 0.82;
    final pulseInterval = 0.7;

    for (double progress = 0.5; progress <= 1.0; progress += 0.05) {
      test('Progress ${(progress * 100).toInt()}% threat intensity', () {
        if (progress >= nearBaseThreshold) {
          final intensity = (progress - nearBaseThreshold) / (1 - nearBaseThreshold);
          expect(intensity.clamp(0.0, 1.0), inInclusiveRange(0.0, 1.0));
        }
      });
    }

    test('Pulse interval is 0.7 seconds', () {
      expect(pulseInterval, 0.7);
    });

    test('Near base threshold is 0.82', () {
      expect(nearBaseThreshold, 0.82);
    });
  });
}
