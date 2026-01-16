import 'package:flutter/foundation.dart';

import '../models/level_config.dart';
import 'storage_service.dart';
import 'upgrade_service.dart';
import '../game/entities/tower.dart';

/// Service to manage level configurations and progress
class LevelService {
  LevelService._();
  static final instance = LevelService._();

  static const String _appEnv =
      String.fromEnvironment('APP_ENV', defaultValue: 'prod');
  static const bool _unlockAllLevelsEnv =
      bool.fromEnvironment('UNLOCK_ALL_LEVELS', defaultValue: false);
  @visibleForTesting
  static bool? overrideUnlockAllLevels;
  static bool get _unlockAllLevels =>
      overrideUnlockAllLevels ??
      (_unlockAllLevelsEnv || _appEnv == 'dev');

  bool _initialized = false;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Tower Unlocking Schedule
  static final Map<int, TowerType> _towerUnlocks = {
    1: TowerType.pulseArcher,
    3: TowerType.circuitCannon,
    5: TowerType.phaseMage,
    7: TowerType.glimmerField,
    9: TowerType.ionSniper,
    10: TowerType.teslaTerminal,
    11: TowerType.resonanceSiphon, // World 2 Lvl 1
    13: TowerType.neuralDisruptor, // World 2 Lvl 3
  };

  /// Returns whether a specific tower type is unlocked based on progression
  bool isTowerUnlocked(TowerType type) {
    if (_unlockAllLevels) return true;
    
    // Pulse Archer is always unlocked
    if (type == TowerType.pulseArcher) return true;

    // Check progress
    final storage = StorageService.instance;
    for (final entry in _towerUnlocks.entries) {
      if (entry.value == type) {
        // Tower is unlocked if the level associated with it is unlocked
        // (meaning user reached that level)
        return isLevelUnlocked(entry.key);
      }
    }
    
    return false;
  }

  /// Get list of all unlocked towers for current progression
  List<TowerType> getUnlockedTowers() {
    return TowerType.values.where((t) => isTowerUnlocked(t)).toList();
  }

  /// All available levels (hardcoded for now, could load from JSON)
  final List<LevelConfig> levels = const [
    LevelConfig(
      id: 1,
      name: 'Training Grounds',
      mapFile: 'maps/level1.tmx',
      waves: 5,
      difficulty: 1,
      unlockRequirement: null, // Always unlocked
      startingGold: 250,
      startingLives: 25,
    ),
    LevelConfig(
      id: 2,
      name: 'Neon Corridor',
      mapFile: 'maps/level2.tmx',
      waves: 8,
      difficulty: 1,
      unlockRequirement: 1,
      startingGold: 200,
      startingLives: 20,
    ),
    LevelConfig(
      id: 3,
      name: 'Circuit Maze',
      mapFile: 'maps/level3.tmx',
      waves: 10,
      difficulty: 2,
      unlockRequirement: 2,
      startingGold: 200,
      startingLives: 20,
    ),
    LevelConfig(
      id: 4,
      name: 'Data Stream',
      mapFile: 'maps/level4.tmx',
      waves: 12,
      difficulty: 2,
      unlockRequirement: 3,
      startingGold: 180,
      startingLives: 18,
    ),
    LevelConfig(
      id: 5,
      name: 'Core Junction',
      mapFile: 'maps/level5.tmx',
      waves: 15,
      difficulty: 3,
      unlockRequirement: 4,
      startingGold: 150,
      startingLives: 15,
    ),
    LevelConfig(
      id: 6,
      name: 'Pulse Network',
      mapFile: 'maps/level6.tmx',
      waves: 18,
      difficulty: 3,
      unlockRequirement: 5,
      startingGold: 150,
      startingLives: 15,
    ),
    LevelConfig(
      id: 7,
      name: 'Firewall',
      mapFile: 'maps/level7.tmx',
      waves: 20,
      difficulty: 4,
      unlockRequirement: 6,
      startingGold: 120,
      startingLives: 12,
    ),
    LevelConfig(
      id: 8,
      name: 'Mainframe',
      mapFile: 'maps/level8.tmx',
      waves: 25,
      difficulty: 5,
      unlockRequirement: 7,
      startingGold: 100,
      startingLives: 10,
    ),
    LevelConfig(
      id: 9,
      name: 'Neon Rift',
      mapFile: 'maps/level9.tmx',
      waves: 28,
      difficulty: 5,
      unlockRequirement: 8,
      startingGold: 95,
      startingLives: 9,
    ),
    LevelConfig(
      id: 10,
      name: 'Citadel Core',
      mapFile: 'maps/level10.tmx',
      waves: 30,
      difficulty: 5,
      unlockRequirement: 9,
      startingGold: 90,
      startingLives: 8,
    ),
    LevelConfig(
      id: 11,
      name: 'Riftwake',
      mapFile: 'maps/level11.tmx',
      waves: 32,
      difficulty: 3,
      unlockRequirement: 10,
      startingGold: 90,
      startingLives: 9,
    ),
    LevelConfig(
      id: 12,
      name: 'Signal Break',
      mapFile: 'maps/level12.tmx',
      waves: 34,
      difficulty: 3,
      unlockRequirement: 11,
      startingGold: 88,
      startingLives: 9,
    ),
    LevelConfig(
      id: 13,
      name: 'Ion Drift',
      mapFile: 'maps/level13.tmx',
      waves: 36,
      difficulty: 4,
      unlockRequirement: 12,
      startingGold: 86,
      startingLives: 8,
    ),
    LevelConfig(
      id: 14,
      name: 'Void Relay',
      mapFile: 'maps/level14.tmx',
      waves: 38,
      difficulty: 4,
      unlockRequirement: 13,
      startingGold: 84,
      startingLives: 8,
    ),
    LevelConfig(
      id: 15,
      name: 'Dark Circuit',
      mapFile: 'maps/level15.tmx',
      waves: 40,
      difficulty: 4,
      unlockRequirement: 14,
      startingGold: 82,
      startingLives: 8,
    ),
    LevelConfig(
      id: 16,
      name: 'Grav Surge',
      mapFile: 'maps/level16.tmx',
      waves: 42,
      difficulty: 5,
      unlockRequirement: 15,
      startingGold: 80,
      startingLives: 7,
    ),
    LevelConfig(
      id: 17,
      name: 'Pulse Quake',
      mapFile: 'maps/level17.tmx',
      waves: 44,
      difficulty: 5,
      unlockRequirement: 16,
      startingGold: 78,
      startingLives: 7,
    ),
    LevelConfig(
      id: 18,
      name: 'Echo Storm',
      mapFile: 'maps/level18.tmx',
      waves: 46,
      difficulty: 5,
      unlockRequirement: 17,
      startingGold: 76,
      startingLives: 7,
    ),
    LevelConfig(
      id: 19,
      name: 'Fracture Line',
      mapFile: 'maps/level19.tmx',
      waves: 48,
      difficulty: 5,
      unlockRequirement: 18,
      startingGold: 74,
      startingLives: 6,
    ),
    LevelConfig(
      id: 20,
      name: 'Abyss Gate',
      mapFile: 'maps/level20.tmx',
      waves: 50,
      difficulty: 5,
      unlockRequirement: 19,
      startingGold: 72,
      startingLives: 6,
    ),
    LevelConfig(
      id: 21,
      name: 'Flux Expanse',
      mapFile: 'maps/level21.tmx',
      waves: 52,
      difficulty: 5,
      unlockRequirement: 20,
      startingGold: 70,
      startingLives: 6,
    ),
    LevelConfig(
      id: 22,
      name: 'Signal Dunes',
      mapFile: 'maps/level22.tmx',
      waves: 54,
      difficulty: 5,
      unlockRequirement: 21,
      startingGold: 69,
      startingLives: 6,
    ),
    LevelConfig(
      id: 23,
      name: 'Ion Basin',
      mapFile: 'maps/level23.tmx',
      waves: 56,
      difficulty: 5,
      unlockRequirement: 22,
      startingGold: 68,
      startingLives: 6,
    ),
    LevelConfig(
      id: 24,
      name: 'Rift Crescent',
      mapFile: 'maps/level24.tmx',
      waves: 58,
      difficulty: 5,
      unlockRequirement: 23,
      startingGold: 67,
      startingLives: 6,
    ),
    LevelConfig(
      id: 25,
      name: 'Helix Divide',
      mapFile: 'maps/level25.tmx',
      waves: 60,
      difficulty: 5,
      unlockRequirement: 24,
      startingGold: 66,
      startingLives: 5,
    ),
    LevelConfig(
      id: 26,
      name: 'Ghost Meridian',
      mapFile: 'maps/level26.tmx',
      waves: 62,
      difficulty: 5,
      unlockRequirement: 25,
      startingGold: 65,
      startingLives: 5,
    ),
    LevelConfig(
      id: 27,
      name: 'Null Ridge',
      mapFile: 'maps/level27.tmx',
      waves: 64,
      difficulty: 5,
      unlockRequirement: 26,
      startingGold: 64,
      startingLives: 5,
    ),
    LevelConfig(
      id: 28,
      name: 'Arc Wastes',
      mapFile: 'maps/level28.tmx',
      waves: 66,
      difficulty: 5,
      unlockRequirement: 27,
      startingGold: 63,
      startingLives: 5,
    ),
    LevelConfig(
      id: 29,
      name: 'Horizon Break',
      mapFile: 'maps/level29.tmx',
      waves: 68,
      difficulty: 5,
      unlockRequirement: 28,
      startingGold: 62,
      startingLives: 5,
    ),
    LevelConfig(
      id: 30,
      name: 'Voidline Apex',
      mapFile: 'maps/level30.tmx',
      waves: 70,
      difficulty: 5,
      unlockRequirement: 29,
      startingGold: 61,
      startingLives: 5,
    ),
    LevelConfig(
      id: 31,
      name: 'Ion Crown Sector 1',
      mapFile: 'maps/level31.tmx',
      waves: 72,
      difficulty: 4,
      unlockRequirement: 30,
      startingGold: 60,
      startingLives: 5,
    ),
    LevelConfig(
      id: 32,
      name: 'Ion Crown Sector 2',
      mapFile: 'maps/level32.tmx',
      waves: 74,
      difficulty: 4,
      unlockRequirement: 31,
      startingGold: 59,
      startingLives: 5,
    ),
    LevelConfig(
      id: 33,
      name: 'Ion Crown Sector 3',
      mapFile: 'maps/level33.tmx',
      waves: 76,
      difficulty: 5,
      unlockRequirement: 32,
      startingGold: 58,
      startingLives: 5,
    ),
    LevelConfig(
      id: 34,
      name: 'Ion Crown Sector 4',
      mapFile: 'maps/level34.tmx',
      waves: 78,
      difficulty: 5,
      unlockRequirement: 33,
      startingGold: 57,
      startingLives: 5,
    ),
    LevelConfig(
      id: 35,
      name: 'Ion Crown Sector 5',
      mapFile: 'maps/level35.tmx',
      waves: 80,
      difficulty: 5,
      unlockRequirement: 34,
      startingGold: 56,
      startingLives: 5,
    ),
    LevelConfig(
      id: 36,
      name: 'Shard Vault Sector 6',
      mapFile: 'maps/level36.tmx',
      waves: 82,
      difficulty: 5,
      unlockRequirement: 35,
      startingGold: 51,
      startingLives: 3,
    ),
    LevelConfig(
      id: 37,
      name: 'Shard Vault Sector 7',
      mapFile: 'maps/level37.tmx',
      waves: 84,
      difficulty: 5,
      unlockRequirement: 36,
      startingGold: 50,
      startingLives: 3,
    ),
    LevelConfig(
      id: 38,
      name: 'Shard Vault Sector 8',
      mapFile: 'maps/level38.tmx',
      waves: 86,
      difficulty: 5,
      unlockRequirement: 37,
      startingGold: 49,
      startingLives: 3,
    ),
    LevelConfig(
      id: 39,
      name: 'Shard Vault Sector 9',
      mapFile: 'maps/level39.tmx',
      waves: 88,
      difficulty: 5,
      unlockRequirement: 38,
      startingGold: 48,
      startingLives: 3,
    ),
    LevelConfig(
      id: 40,
      name: 'Shard Vault Sector 10',
      mapFile: 'maps/level40.tmx',
      waves: 90,
      difficulty: 5,
      unlockRequirement: 39,
      startingGold: 47,
      startingLives: 3,
    ),
    LevelConfig(
      id: 41,
      name: 'Shard Vault Sector 1',
      mapFile: 'maps/level41.tmx',
      waves: 92,
      difficulty: 5,
      unlockRequirement: 40,
      startingGold: 56,
      startingLives: 4,
    ),
    LevelConfig(
      id: 42,
      name: 'Shard Vault Sector 2',
      mapFile: 'maps/level42.tmx',
      waves: 94,
      difficulty: 5,
      unlockRequirement: 41,
      startingGold: 55,
      startingLives: 4,
    ),
    LevelConfig(
      id: 43,
      name: 'Shard Vault Sector 3',
      mapFile: 'maps/level43.tmx',
      waves: 96,
      difficulty: 5,
      unlockRequirement: 42,
      startingGold: 54,
      startingLives: 4,
    ),
    LevelConfig(
      id: 44,
      name: 'Shard Vault Sector 4',
      mapFile: 'maps/level44.tmx',
      waves: 98,
      difficulty: 5,
      unlockRequirement: 43,
      startingGold: 53,
      startingLives: 4,
    ),
    LevelConfig(
      id: 45,
      name: 'Shard Vault Sector 5',
      mapFile: 'maps/level45.tmx',
      waves: 100,
      difficulty: 5,
      unlockRequirement: 44,
      startingGold: 52,
      startingLives: 4,
    ),
    LevelConfig(
      id: 46,
      name: 'Shard Vault Sector 6',
      mapFile: 'maps/level46.tmx',
      waves: 102,
      difficulty: 5,
      unlockRequirement: 45,
      startingGold: 51,
      startingLives: 3,
    ),
    LevelConfig(
      id: 47,
      name: 'Arc Fortress Sector 7',
      mapFile: 'maps/level47.tmx',
      waves: 104,
      difficulty: 5,
      unlockRequirement: 46,
      startingGold: 46,
      startingLives: 3,
    ),
    LevelConfig(
      id: 48,
      name: 'Arc Fortress Sector 8',
      mapFile: 'maps/level48.tmx',
      waves: 106,
      difficulty: 5,
      unlockRequirement: 47,
      startingGold: 45,
      startingLives: 3,
    ),
    LevelConfig(
      id: 49,
      name: 'Arc Fortress Sector 9',
      mapFile: 'maps/level49.tmx',
      waves: 108,
      difficulty: 5,
      unlockRequirement: 48,
      startingGold: 44,
      startingLives: 3,
    ),
    LevelConfig(
      id: 50,
      name: 'Arc Fortress Sector 10',
      mapFile: 'maps/level50.tmx',
      waves: 110,
      difficulty: 5,
      unlockRequirement: 49,
      startingGold: 43,
      startingLives: 3,
    ),
    LevelConfig(
      id: 51,
      name: 'Arc Fortress Sector 1',
      mapFile: 'maps/level51.tmx',
      waves: 112,
      difficulty: 5,
      unlockRequirement: 50,
      startingGold: 52,
      startingLives: 3,
    ),
    LevelConfig(
      id: 52,
      name: 'Arc Fortress Sector 2',
      mapFile: 'maps/level52.tmx',
      waves: 114,
      difficulty: 5,
      unlockRequirement: 51,
      startingGold: 51,
      startingLives: 3,
    ),
    LevelConfig(
      id: 53,
      name: 'Arc Fortress Sector 3',
      mapFile: 'maps/level53.tmx',
      waves: 116,
      difficulty: 5,
      unlockRequirement: 52,
      startingGold: 50,
      startingLives: 3,
    ),
    LevelConfig(
      id: 54,
      name: 'Arc Fortress Sector 4',
      mapFile: 'maps/level54.tmx',
      waves: 118,
      difficulty: 5,
      unlockRequirement: 53,
      startingGold: 49,
      startingLives: 3,
    ),
    LevelConfig(
      id: 55,
      name: 'Arc Fortress Sector 5',
      mapFile: 'maps/level55.tmx',
      waves: 120,
      difficulty: 5,
      unlockRequirement: 54,
      startingGold: 48,
      startingLives: 3,
    ),
    LevelConfig(
      id: 56,
      name: 'Core Hunt Sector 6',
      mapFile: 'maps/level56.tmx',
      waves: 122,
      difficulty: 5,
      unlockRequirement: 55,
      startingGold: 43,
      startingLives: 3,
    ),
    LevelConfig(
      id: 57,
      name: 'Core Hunt Sector 7',
      mapFile: 'maps/level57.tmx',
      waves: 124,
      difficulty: 5,
      unlockRequirement: 56,
      startingGold: 42,
      startingLives: 3,
    ),
    LevelConfig(
      id: 58,
      name: 'Core Hunt Sector 8',
      mapFile: 'maps/level58.tmx',
      waves: 126,
      difficulty: 5,
      unlockRequirement: 57,
      startingGold: 41,
      startingLives: 3,
    ),
    LevelConfig(
      id: 59,
      name: 'Core Hunt Sector 9',
      mapFile: 'maps/level59.tmx',
      waves: 128,
      difficulty: 5,
      unlockRequirement: 58,
      startingGold: 40,
      startingLives: 3,
    ),
    LevelConfig(
      id: 60,
      name: 'Core Hunt Sector 10',
      mapFile: 'maps/level60.tmx',
      waves: 130,
      difficulty: 5,
      unlockRequirement: 59,
      startingGold: 39,
      startingLives: 3,
    ),
    LevelConfig(
      id: 61,
      name: 'Core Hunt Sector 1',
      mapFile: 'maps/level61.tmx',
      waves: 132,
      difficulty: 5,
      unlockRequirement: 60,
      startingGold: 48,
      startingLives: 3,
    ),
    LevelConfig(
      id: 62,
      name: 'Core Hunt Sector 2',
      mapFile: 'maps/level62.tmx',
      waves: 134,
      difficulty: 5,
      unlockRequirement: 61,
      startingGold: 47,
      startingLives: 3,
    ),
    LevelConfig(
      id: 63,
      name: 'Core Hunt Sector 3',
      mapFile: 'maps/level63.tmx',
      waves: 136,
      difficulty: 5,
      unlockRequirement: 62,
      startingGold: 46,
      startingLives: 3,
    ),
    LevelConfig(
      id: 64,
      name: 'Core Hunt Sector 4',
      mapFile: 'maps/level64.tmx',
      waves: 138,
      difficulty: 5,
      unlockRequirement: 63,
      startingGold: 45,
      startingLives: 3,
    ),
    LevelConfig(
      id: 65,
      name: 'Core Hunt Sector 5',
      mapFile: 'maps/level65.tmx',
      waves: 140,
      difficulty: 5,
      unlockRequirement: 64,
      startingGold: 44,
      startingLives: 3,
    ),
    LevelConfig(
      id: 66,
      name: 'Core Hunt Sector 6',
      mapFile: 'maps/level66.tmx',
      waves: 142,
      difficulty: 5,
      unlockRequirement: 65,
      startingGold: 43,
      startingLives: 3,
    ),
    LevelConfig(
      id: 67,
      name: 'Omega Grid Sector 7',
      mapFile: 'maps/level67.tmx',
      waves: 144,
      difficulty: 5,
      unlockRequirement: 66,
      startingGold: 38,
      startingLives: 3,
    ),
    LevelConfig(
      id: 68,
      name: 'Omega Grid Sector 8',
      mapFile: 'maps/level68.tmx',
      waves: 146,
      difficulty: 5,
      unlockRequirement: 67,
      startingGold: 37,
      startingLives: 3,
    ),
    LevelConfig(
      id: 69,
      name: 'Omega Grid Sector 9',
      mapFile: 'maps/level69.tmx',
      waves: 148,
      difficulty: 5,
      unlockRequirement: 68,
      startingGold: 36,
      startingLives: 3,
    ),
    LevelConfig(
      id: 70,
      name: 'Omega Grid Sector 10',
      mapFile: 'maps/level70.tmx',
      waves: 150,
      difficulty: 5,
      unlockRequirement: 69,
      startingGold: 35,
      startingLives: 3,
    ),
    LevelConfig(
      id: 71,
      name: 'Omega Grid Sector 1',
      mapFile: 'maps/level71.tmx',
      waves: 152,
      difficulty: 5,
      unlockRequirement: 70,
      startingGold: 44,
      startingLives: 3,
    ),
    LevelConfig(
      id: 72,
      name: 'Omega Grid Sector 2',
      mapFile: 'maps/level72.tmx',
      waves: 154,
      difficulty: 5,
      unlockRequirement: 71,
      startingGold: 43,
      startingLives: 3,
    ),
    LevelConfig(
      id: 73,
      name: 'Omega Grid Sector 3',
      mapFile: 'maps/level73.tmx',
      waves: 156,
      difficulty: 5,
      unlockRequirement: 72,
      startingGold: 42,
      startingLives: 3,
    ),
    LevelConfig(
      id: 74,
      name: 'Omega Grid Sector 4',
      mapFile: 'maps/level74.tmx',
      waves: 158,
      difficulty: 5,
      unlockRequirement: 73,
      startingGold: 41,
      startingLives: 3,
    ),
    LevelConfig(
      id: 75,
      name: 'Omega Grid Sector 5',
      mapFile: 'maps/level75.tmx',
      waves: 160,
      difficulty: 5,
      unlockRequirement: 74,
      startingGold: 40,
      startingLives: 3,
    ),
    LevelConfig(
      id: 76,
      name: 'Storm Tower Sector 6',
      mapFile: 'maps/level76.tmx',
      waves: 162,
      difficulty: 5,
      unlockRequirement: 75,
      startingGold: 37,
      startingLives: 3,
    ),
    LevelConfig(
      id: 77,
      name: 'Storm Tower Sector 7',
      mapFile: 'maps/level77.tmx',
      waves: 164,
      difficulty: 5,
      unlockRequirement: 76,
      startingGold: 36,
      startingLives: 3,
    ),
    LevelConfig(
      id: 78,
      name: 'Storm Tower Sector 8',
      mapFile: 'maps/level78.tmx',
      waves: 166,
      difficulty: 5,
      unlockRequirement: 77,
      startingGold: 35,
      startingLives: 3,
    ),
    LevelConfig(
      id: 79,
      name: 'Storm Tower Sector 9',
      mapFile: 'maps/level79.tmx',
      waves: 168,
      difficulty: 5,
      unlockRequirement: 78,
      startingGold: 34,
      startingLives: 3,
    ),
    LevelConfig(
      id: 80,
      name: 'Storm Tower Sector 10',
      mapFile: 'maps/level80.tmx',
      waves: 170,
      difficulty: 5,
      unlockRequirement: 79,
      startingGold: 33,
      startingLives: 3,
    ),
    LevelConfig(
      id: 81,
      name: 'Storm Tower Sector 1',
      mapFile: 'maps/level81.tmx',
      waves: 172,
      difficulty: 5,
      unlockRequirement: 80,
      startingGold: 42,
      startingLives: 3,
    ),
    LevelConfig(
      id: 82,
      name: 'Storm Tower Sector 2',
      mapFile: 'maps/level82.tmx',
      waves: 174,
      difficulty: 5,
      unlockRequirement: 81,
      startingGold: 41,
      startingLives: 3,
    ),
    LevelConfig(
      id: 83,
      name: 'Storm Tower Sector 3',
      mapFile: 'maps/level83.tmx',
      waves: 176,
      difficulty: 5,
      unlockRequirement: 82,
      startingGold: 40,
      startingLives: 3,
    ),
    LevelConfig(
      id: 84,
      name: 'Storm Tower Sector 4',
      mapFile: 'maps/level84.tmx',
      waves: 178,
      difficulty: 5,
      unlockRequirement: 83,
      startingGold: 39,
      startingLives: 3,
    ),
    LevelConfig(
      id: 85,
      name: 'Storm Tower Sector 5',
      mapFile: 'maps/level85.tmx',
      waves: 180,
      difficulty: 5,
      unlockRequirement: 84,
      startingGold: 38,
      startingLives: 3,
    ),
    LevelConfig(
      id: 86,
      name: 'Storm Tower Sector 6',
      mapFile: 'maps/level86.tmx',
      waves: 182,
      difficulty: 5,
      unlockRequirement: 85,
      startingGold: 37,
      startingLives: 3,
    ),
    LevelConfig(
      id: 87,
      name: 'Final Gate Sector 7',
      mapFile: 'maps/level87.tmx',
      waves: 184,
      difficulty: 5,
      unlockRequirement: 86,
      startingGold: 34,
      startingLives: 3,
    ),
    LevelConfig(
      id: 88,
      name: 'Final Gate Sector 8',
      mapFile: 'maps/level88.tmx',
      waves: 186,
      difficulty: 5,
      unlockRequirement: 87,
      startingGold: 33,
      startingLives: 3,
    ),
    LevelConfig(
      id: 89,
      name: 'Final Gate Sector 9',
      mapFile: 'maps/level89.tmx',
      waves: 188,
      difficulty: 5,
      unlockRequirement: 88,
      startingGold: 32,
      startingLives: 3,
    ),
    LevelConfig(
      id: 90,
      name: 'Final Gate Sector 10',
      mapFile: 'maps/level90.tmx',
      waves: 190,
      difficulty: 5,
      unlockRequirement: 89,
      startingGold: 31,
      startingLives: 3,
    ),
    LevelConfig(
      id: 91,
      name: 'Final Gate Sector 1',
      mapFile: 'maps/level91.tmx',
      waves: 192,
      difficulty: 5,
      unlockRequirement: 90,
      startingGold: 40,
      startingLives: 3,
    ),
    LevelConfig(
      id: 92,
      name: 'Final Gate Sector 2',
      mapFile: 'maps/level92.tmx',
      waves: 194,
      difficulty: 5,
      unlockRequirement: 91,
      startingGold: 39,
      startingLives: 3,
    ),
    LevelConfig(
      id: 93,
      name: 'Final Gate Sector 3',
      mapFile: 'maps/level93.tmx',
      waves: 196,
      difficulty: 5,
      unlockRequirement: 92,
      startingGold: 38,
      startingLives: 3,
    ),
    LevelConfig(
      id: 94,
      name: 'Final Gate Sector 4',
      mapFile: 'maps/level94.tmx',
      waves: 198,
      difficulty: 5,
      unlockRequirement: 93,
      startingGold: 37,
      startingLives: 3,
    ),
    LevelConfig(
      id: 95,
      name: 'Final Gate Sector 5',
      mapFile: 'maps/level95.tmx',
      waves: 200,
      difficulty: 5,
      unlockRequirement: 94,
      startingGold: 36,
      startingLives: 3,
    ),
    LevelConfig(
      id: 96,
      name: ' Sector 6',
      mapFile: 'maps/level96.tmx',
      waves: 202,
      difficulty: 5,
      unlockRequirement: 95,
      startingGold: 30,
      startingLives: 3,
    ),
    LevelConfig(
      id: 97,
      name: ' Sector 7',
      mapFile: 'maps/level97.tmx',
      waves: 204,
      difficulty: 5,
      unlockRequirement: 96,
      startingGold: 30,
      startingLives: 3,
    ),
    LevelConfig(
      id: 98,
      name: ' Sector 8',
      mapFile: 'maps/level98.tmx',
      waves: 206,
      difficulty: 5,
      unlockRequirement: 97,
      startingGold: 30,
      startingLives: 3,
    ),
    LevelConfig(
      id: 99,
      name: ' Sector 9',
      mapFile: 'maps/level99.tmx',
      waves: 208,
      difficulty: 5,
      unlockRequirement: 98,
      startingGold: 30,
      startingLives: 3,
    ),
    LevelConfig(
      id: 100,
      name: ' Sector 10',
      mapFile: 'maps/level100.tmx',
      waves: 210,
      difficulty: 5,
      unlockRequirement: 99,
      startingGold: 30,
      startingLives: 3,
    ),
  ];

  /// Player progress per level (loaded from storage)
  final Map<int, LevelProgress> _progress = {};

  /// Set of unlocked level IDs
  Set<int> _unlockedLevels = {1};

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    _progress.clear();
    _unlockedLevels = {1};
  }

  /// Initialize and load progress from storage
  Future<void> initialize() async {
    if (_initialized) return;

    await StorageService.instance.initialize();
    await _loadProgress();
    _initialized = true;

    _log('[LevelService] Initialized with ${_progress.length} level progress entries');
    _log('[LevelService] Unlocked levels: $_unlockedLevels');
  }

  /// Load progress from persistent storage
  Future<void> _loadProgress() async {
    // Load unlocked levels (or force unlock for dev builds)
    if (_unlockAllLevels) {
      _unlockedLevels = levels.map((level) => level.id).toSet();
    } else {
      _unlockedLevels = StorageService.instance.loadUnlockedLevels();
      if (!_unlockedLevels.contains(1)) {
        _unlockedLevels.add(1);
      }
    }

    // Load all level progress
    final allProgress = StorageService.instance.loadAllLevelProgress();
    for (final entry in allProgress.entries) {
      _progress[entry.key] = LevelProgress.fromJson(entry.value);
    }

    // Ensure level 1 always has a progress entry
    _progress.putIfAbsent(1, () => const LevelProgress(levelId: 1));
  }

  /// Get progress for a level
  LevelProgress getProgress(int levelId) {
    return _progress[levelId] ?? LevelProgress(levelId: levelId);
  }

  /// Check if a level is unlocked
  bool isLevelUnlocked(int levelId) {
    if (_unlockAllLevels) return true;

    // Level 1 is always unlocked
    if (levelId == 1) return true;

    // Check if explicitly unlocked
    if (_unlockedLevels.contains(levelId)) return true;

    // Check if prerequisite is completed
    final level = levels.firstWhere(
      (l) => l.id == levelId,
      orElse: () => throw ArgumentError('Level $levelId not found'),
    );

    if (level.unlockRequirement == null) return true;

    final requiredProgress = getProgress(level.unlockRequirement!);
    return requiredProgress.completed;
  }

  /// Update progress after completing a level
  Future<void> updateProgress({
    required int levelId,
    required bool completed,
    required int score,
    required int wavesCleared,
    required int livesRemaining,
    required int maxLives,
  }) async {
    final current = getProgress(levelId);

    // Calculate stars based on performance
    int stars = 0;
    if (completed) {
      stars = 1; // Base star for completion
      if (livesRemaining >= maxLives * 0.75) stars = 2; // Good health
      if (livesRemaining == maxLives) stars = 3; // Perfect
    }

    final newProgress = current.copyWith(
      completed: completed || current.completed,
      stars: stars > current.stars ? stars : current.stars,
      highScore: score > current.highScore ? score : current.highScore,
      bestWave: wavesCleared > current.bestWave ? wavesCleared : current.bestWave,
    );

    _progress[levelId] = newProgress;

    // Save to storage
    await StorageService.instance.saveLevelProgress(
      levelId: levelId,
      completed: newProgress.completed,
      stars: newProgress.stars,
      highScore: newProgress.highScore,
      bestWave: newProgress.bestWave,
    );

    // Reward meta currency for progression
    final earnedStars = stars > current.stars ? stars - current.stars : 0;
    var reward = 0;
    if (completed) {
      reward = 12 + (earnedStars * 6);
    } else {
      reward = (wavesCleared / 3).floor();
    }
    if (reward > 0) {
      await UpgradeService.instance.addCurrency(reward);
    }

    // Unlock next level if completed
    if (completed) {
      final nextLevelId = levelId + 1;
      if (levels.any((l) => l.id == nextLevelId)) {
        _unlockedLevels.add(nextLevelId);
        _progress.putIfAbsent(
          nextLevelId,
          () => LevelProgress(levelId: nextLevelId),
        );

        // Save unlocked levels
        await StorageService.instance.saveUnlockedLevels(_unlockedLevels);
      }
    }

    _log('[LevelService] Updated progress for level $levelId: stars=${newProgress.stars}, score=${newProgress.highScore}');
  }

  /// Get level config by ID
  LevelConfig? getLevel(int levelId) {
    try {
      return levels.firstWhere((l) => l.id == levelId);
    } catch (_) {
      return null;
    }
  }

  /// Get total stars collected across all levels
  int get totalStars {
    return _progress.values.fold(0, (sum, p) => sum + p.stars);
  }

  /// Get maximum possible stars
  int get maxStars => levels.length * 3;

  /// Get number of completed levels
  int get completedLevels {
    return _progress.values.where((p) => p.completed).length;
  }

  /// Get total high score across all levels
  int get totalHighScore {
    return _progress.values.fold(0, (sum, p) => sum + p.highScore);
  }

  /// Reset all progress (for debugging or user request)
  Future<void> resetProgress() async {
    _progress.clear();
    _unlockedLevels = _unlockAllLevels
        ? levels.map((level) => level.id).toSet()
        : {1};
    _progress[1] = const LevelProgress(levelId: 1);

    await StorageService.instance.clearProgress();
    await StorageService.instance.saveUnlockedLevels(_unlockedLevels);

    _log('[LevelService] Progress reset');
  }
}

