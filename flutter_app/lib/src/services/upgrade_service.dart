import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/upgrade_data.dart';
import 'storage_service.dart';

class _FastRng {
  int _state;

  _FastRng([int? seed]) : _state = (seed ?? 0x6d2b79f5) & 0x7fffffff;

  int _next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state;
  }

  double nextDouble() => _next() / 0x7fffffff;

  int nextInt(int max) => max <= 0 ? 0 : _next() % max;

  bool nextBool() => (_next() & 1) == 0;
}

class UpgradeService {
  UpgradeService._();
  static final instance = UpgradeService._();

  bool _initialized = false;
  int _currency = 0;
  final Map<String, int> _metaLevels = {};
  final _FastRng _random = _FastRng();

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    _currency = 0;
    _metaLevels.clear();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (!StorageService.instance.isReady) {
      await StorageService.instance.initialize();
    }
    _currency = StorageService.instance.loadMetaCurrency();
    _metaLevels.addAll(StorageService.instance.loadUpgradeLevels());
    _initialized = true;
  }

  int get currency => _currency;

  Map<String, int> get levels => UnmodifiableMapView(_metaLevels);

  List<UpgradeDefinition> get metaUpgrades => _metaUpgrades;

  List<RunUpgradeDefinition> get runUpgrades => _runUpgrades;

  int levelFor(String id) => _metaLevels[id] ?? 0;

  UpgradeDefinition? upgradeById(String id) {
    for (final upgrade in _metaUpgrades) {
      if (upgrade.id == id) return upgrade;
    }
    return null;
  }

  bool canPurchase(UpgradeDefinition upgrade) {
    final level = levelFor(upgrade.id);
    if (level >= upgrade.maxLevel) return false;
    return _currency >= upgrade.costForLevel(level);
  }

  Future<bool> purchase(String id) async {
    final upgrade = upgradeById(id);
    if (upgrade == null) return false;
    await initialize();

    final level = levelFor(id);
    if (level >= upgrade.maxLevel) return false;
    final cost = upgrade.costForLevel(level);
    if (_currency < cost) return false;

    _currency -= cost;
    _metaLevels[id] = level + 1;
    await StorageService.instance.saveMetaCurrency(_currency);
    await StorageService.instance.saveUpgradeLevels(_metaLevels);
    return true;
  }

  Future<void> addCurrency(int amount) async {
    if (amount <= 0) return;
    await initialize();
    _currency += amount;
    await StorageService.instance.saveMetaCurrency(_currency);
  }

  UpgradeStats get metaStats {
    var stats = const UpgradeStats();
    for (final upgrade in _metaUpgrades) {
      final level = math.min(levelFor(upgrade.id), upgrade.maxLevel);
      if (level <= 0) continue;
      stats = stats.merge(upgrade.statsForLevel(level));
    }
    return stats;
  }

  List<RunUpgradeDefinition> rollRunUpgrades({
    required Map<String, int> currentStacks,
    int count = 3,
  }) {
    final available = _runUpgrades.where((upgrade) {
      final stacks = currentStacks[upgrade.id] ?? 0;
      return stacks < upgrade.maxStacks;
    }).toList(growable: false);

    if (available.isEmpty) return const [];
    final result = <RunUpgradeDefinition>[];
    final pool = available.toList();
    while (result.length < count && pool.isNotEmpty) {
      final index = _random.nextInt(pool.length);
      result.add(pool.removeAt(index));
    }
    return result;
  }
}

const List<UpgradeDefinition> _metaUpgrades = [
  UpgradeDefinition(
    id: 'core_amplifier',
    name: 'Core Amplifier',
    description: 'Tower damage +7% per level.',
    maxLevel: 8,
    baseCost: 60,
    costStep: 25,
    perLevel: UpgradeStats(towerDamageMult: 1.07),
  ),
  UpgradeDefinition(
    id: 'range_array',
    name: 'Range Array',
    description: 'Tower range +5% per level.',
    maxLevel: 6,
    baseCost: 55,
    costStep: 20,
    perLevel: UpgradeStats(towerRangeMult: 1.05),
  ),
  UpgradeDefinition(
    id: 'overclock_grid',
    name: 'Overclock Grid',
    description: 'Tower fire rate +6% per level.',
    maxLevel: 6,
    baseCost: 70,
    costStep: 30,
    perLevel: UpgradeStats(towerFireRateMult: 1.06),
  ),
  UpgradeDefinition(
    id: 'ballistics_sync',
    name: 'Ballistics Sync',
    description: 'Projectile speed +5% per level.',
    maxLevel: 5,
    baseCost: 50,
    costStep: 20,
    perLevel: UpgradeStats(projectileSpeedMult: 1.05),
  ),
  UpgradeDefinition(
    id: 'battery_cells',
    name: 'Battery Cells',
    description: 'Starting gold +15 per level.',
    maxLevel: 8,
    baseCost: 40,
    costStep: 18,
    perLevel: UpgradeStats(startingGoldBonus: 15),
  ),
  UpgradeDefinition(
    id: 'shield_matrix',
    name: 'Shield Matrix',
    description: 'Starting lives +1 per level.',
    maxLevel: 10,
    baseCost: 45,
    costStep: 20,
    perLevel: UpgradeStats(startingLivesBonus: 1),
  ),
  UpgradeDefinition(
    id: 'efficiency_loop',
    name: 'Efficiency Loop',
    description: 'Tower costs -4% per level.',
    maxLevel: 6,
    baseCost: 65,
    costStep: 25,
    perLevel: UpgradeStats(towerCostMult: 0.96),
  ),
  UpgradeDefinition(
    id: 'pulse_reactor',
    name: 'Pulse Reactor',
    description: 'Pulse cooldown -8% per level.',
    maxLevel: 5,
    baseCost: 80,
    costStep: 35,
    perLevel: UpgradeStats(pulseCooldownMult: 0.92),
  ),
  UpgradeDefinition(
    id: 'mine_forge',
    name: 'Mine Forge',
    description: 'Mine cooldown -8% and +1 max mine per level.',
    maxLevel: 3,
    baseCost: 75,
    costStep: 35,
    perLevel: UpgradeStats(mineCooldownMult: 0.92, maxMinesBonus: 1),
  ),
  UpgradeDefinition(
    id: 'salvage_protocol',
    name: 'Salvage Protocol',
    description: 'Gold per kill +6% per level.',
    maxLevel: 6,
    baseCost: 60,
    costStep: 25,
    perLevel: UpgradeStats(goldGainMult: 1.06),
  ),
  UpgradeDefinition(
    id: 'phase_tuning',
    name: 'Phase Tuning',
    description: 'Slow strength +8% per level.',
    maxLevel: 5,
    baseCost: 55,
    costStep: 20,
    perLevel: UpgradeStats(slowMult: 1.08),
  ),
];

const List<RunUpgradeDefinition> _runUpgrades = [
  RunUpgradeDefinition(
    id: 'run_damage',
    name: 'Damage Surge',
    description: 'Tower damage +12% this run.',
    stats: UpgradeStats(towerDamageMult: 1.12),
    maxStacks: 4,
  ),
  RunUpgradeDefinition(
    id: 'run_range',
    name: 'Range Boost',
    description: 'Tower range +10% this run.',
    stats: UpgradeStats(towerRangeMult: 1.1),
    maxStacks: 3,
  ),
  RunUpgradeDefinition(
    id: 'run_fire',
    name: 'Overclock Burst',
    description: 'Tower fire rate +12% this run.',
    stats: UpgradeStats(towerFireRateMult: 1.12),
    maxStacks: 4,
  ),
  RunUpgradeDefinition(
    id: 'run_gold',
    name: 'Gold Overflow',
    description: 'Gold gain +15% this run.',
    stats: UpgradeStats(goldGainMult: 1.15),
    maxStacks: 4,
  ),
  RunUpgradeDefinition(
    id: 'run_pulse',
    name: 'Pulse Cooldown',
    description: 'Pulse cooldown -20% this run.',
    stats: UpgradeStats(pulseCooldownMult: 0.8),
    maxStacks: 3,
  ),
  RunUpgradeDefinition(
    id: 'run_mine',
    name: 'Mine Cooldown',
    description: 'Mine cooldown -20% this run.',
    stats: UpgradeStats(mineCooldownMult: 0.8),
    maxStacks: 3,
  ),
  RunUpgradeDefinition(
    id: 'run_lives',
    name: 'Shield Recharge',
    description: 'Gain +2 lives immediately.',
    stats: UpgradeStats(),
    maxStacks: 2,
    instantLives: 2,
  ),
  RunUpgradeDefinition(
    id: 'run_cash',
    name: 'Emergency Credits',
    description: 'Gain +80 gold immediately.',
    stats: UpgradeStats(),
    maxStacks: 3,
    instantGold: 80,
  ),
  RunUpgradeDefinition(
    id: 'run_cost',
    name: 'Discount Circuit',
    description: 'Tower costs -10% this run.',
    stats: UpgradeStats(towerCostMult: 0.9),
    maxStacks: 2,
  ),
  RunUpgradeDefinition(
    id: 'run_slow',
    name: 'Stasis Field',
    description: 'Slow strength +15% this run.',
    stats: UpgradeStats(slowMult: 1.15),
    maxStacks: 3,
  ),
];

