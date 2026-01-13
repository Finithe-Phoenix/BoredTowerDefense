import 'package:flutter/material.dart';
import '../../models/upgrade_data.dart';
import '../../services/upgrade_service.dart';
import '../theme/neon_theme.dart';
import '../widgets/cyber_grid_background.dart';
import '../widgets/epic_neon_button.dart';
import '../widgets/epic_neon_title.dart';

class UpgradesScreen extends StatefulWidget {
  const UpgradesScreen({super.key});

  @override
  State<UpgradesScreen> createState() => _UpgradesScreenState();
}

class _UpgradesScreenState extends State<UpgradesScreen> {
  final UpgradeService _service = UpgradeService.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _buyUpgrade(UpgradeDefinition upgrade) async {
    final ok = await _service.purchase(upgrade.id);
    if (mounted) {
      setState(() {});
    }
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough cores or max level reached.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CyberGridBackground(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: NeonColors.cyan),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: EpicNeonTitle(
                              text: 'UPGRADE FORGE',
                              fontSize: 34,
                              primaryColor: NeonColors.cyan,
                              secondaryColor: NeonColors.magenta,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _CurrencyBanner(cores: _service.currency),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: _service.metaUpgrades.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final upgrade = _service.metaUpgrades[index];
                          final level = _service.levelFor(upgrade.id);
                          final maxed = level >= upgrade.maxLevel;
                          final cost = upgrade.costForLevel(level);
                          final canAfford = _service.currency >= cost;
                          return _UpgradeCard(
                            upgrade: upgrade,
                            level: level,
                            cost: cost,
                            canAfford: canAfford,
                            isMaxed: maxed,
                            onUpgrade: () => _buyUpgrade(upgrade),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CurrencyBanner extends StatelessWidget {
  const _CurrencyBanner({required this.cores});

  final int cores;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: NeonColors.darkBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NeonColors.cyan.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: NeonColors.cyan.withOpacity(0.2),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.memory, color: NeonColors.cyan),
          const SizedBox(width: 10),
          Text(
            'DATA CORES',
            style: NeonTextStyles.small.copyWith(
              color: NeonColors.cyan.withOpacity(0.8),
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          Text(
            cores.toString(),
            style: NeonTextStyles.title.copyWith(
              fontSize: 20,
              color: NeonColors.yellow,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.upgrade,
    required this.level,
    required this.cost,
    required this.canAfford,
    required this.isMaxed,
    required this.onUpgrade,
  });

  final UpgradeDefinition upgrade;
  final int level;
  final int cost;
  final bool canAfford;
  final bool isMaxed;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final progress = level / upgrade.maxLevel;
    final accent = NeonColors.cyan;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonColors.darkBg.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            upgrade.name,
            style: NeonTextStyles.title.copyWith(
              fontSize: 18,
              color: NeonColors.white,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            upgrade.description,
            style: NeonTextStyles.small.copyWith(
              color: NeonColors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            NeonColors.magenta.withOpacity(0.9),
                            NeonColors.cyan.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$level/${upgrade.maxLevel}',
                style: NeonTextStyles.small.copyWith(
                  color: NeonColors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                isMaxed ? 'MAXED' : 'COST $cost',
                style: NeonTextStyles.small.copyWith(
                  color: isMaxed
                      ? NeonColors.green
                      : (canAfford ? NeonColors.yellow : NeonColors.red),
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              EpicNeonButton(
                text: isMaxed ? 'MAX' : 'UPGRADE',
                height: 36,
                width: 140,
                color: isMaxed ? NeonColors.green : NeonColors.cyan,
                onPressed: onUpgrade,
                enabled: !isMaxed && canAfford,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
