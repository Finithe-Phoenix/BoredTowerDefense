import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../widgets/cyber_grid_background.dart';
import '../widgets/epic_neon_button.dart';
import '../widgets/epic_neon_title.dart';
import '../widgets/universe_graph_widget.dart';
import '../../game/balance/difficulty_curve.dart';
import '../../models/level_config.dart';
import '../../services/level_service.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen>
    with TickerProviderStateMixin {
  const int _levelsPerWorld = 10;

  static const List<WorldInfo> _worlds = [
    WorldInfo(
      id: 1,
      name: 'Neon Frontier',
      tagline: 'Reignite the grid and lock the first gates.',
      accent: NeonColors.cyan,
    ),
    WorldInfo(
      id: 2,
      name: 'Rift Wars',
      tagline: 'Shattered lanes and phantom storms rise.',
      accent: NeonColors.magenta,
    ),
    WorldInfo(
      id: 3,
      name: 'Signal Wastes',
      tagline: 'Dead zones flicker with rogue pulses.',
      accent: NeonColors.yellow,
    ),
    WorldInfo(
      id: 4,
      name: 'Ion Crown',
      tagline: 'Arc storms crown the upper lattice.',
      accent: NeonColors.green,
    ),
    WorldInfo(
      id: 5,
      name: 'Shard Vault',
      tagline: 'Ancient caches awaken with hostile code.',
      accent: NeonColors.red,
    ),
    WorldInfo(
      id: 6,
      name: 'Arc Fortress',
      tagline: 'Enemy sieges compress into tighter lanes.',
      accent: NeonColors.purple,
    ),
    WorldInfo(
      id: 7,
      name: 'Core Hunt',
      tagline: 'Every wave targets your core directly.',
      accent: NeonColors.orange,
    ),
    WorldInfo(
      id: 8,
      name: 'Omega Grid',
      tagline: 'Feedback loops overload the lattice.',
      accent: NeonColors.blue,
    ),
    WorldInfo(
      id: 9,
      name: 'Storm Tower',
      tagline: 'Lightning corridors fracture movement.',
      accent: NeonColors.cyan,
    ),
    WorldInfo(
      id: 10,
      name: 'Final Gate',
      tagline: 'The last lock holds the endless surge.',
      accent: NeonColors.white,
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }


  void _handleWorldSelected(int worldId) {
    final worldLevels = _levelsForWorld(worldId);
    if (worldLevels.isEmpty) return;

    // Find the first available level (either next locked or first level)
    final targetLevel = worldLevels.firstWhere(
      (level) => LevelService.instance.isLevelUnlocked(level.id),
      orElse: () => worldLevels.first,
    );

    // Play "Materialization" sequence start sound if any exists (planned)
    
    // Launch directly
    Navigator.pushNamed(
      context,
      '/game',
      arguments: targetLevel.id,
    );
  }


  int _worldForLevel(int levelId) => ((levelId - 1) ~/ _levelsPerWorld) + 1;

  List<LevelConfig> _levelsForWorld(int worldId) {
    return LevelService.instance.levels
        .where((level) => _worldForLevel(level.id) == worldId)
        .toList(growable: false);
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CyberGridBackground(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const EpicNeonTitle(
                text: 'UNIVERSE SELECTION',
                fontSize: 42,
                primaryColor: NeonColors.cyan,
                secondaryColor: NeonColors.magenta,
              ),
              const SizedBox(height: 8),
              Text(
                'Select sector to materialize transmission.',
                style: NeonTextStyles.body.copyWith(
                  color: NeonColors.cyan.withOpacity(0.5),
                  letterSpacing: 2,
                ),
              ),
              Expanded(
                child: UniverseGraphWidget(
                  worlds: _worlds,
                  onWorldSelected: _handleWorldSelected,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: EpicNeonButton(
                  text: 'RETURN',
                  width: 180,
                  height: 44,
                  onPressed: () => Navigator.pop(context),
                  color: NeonColors.magenta,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Public classes that were previously private, so AnimatedTronGrid can use them.
class WorldInfo {
  const WorldInfo({
    required this.id,
    required this.name,
    required this.tagline,
    required this.accent,
  });

  final int id;
  final String name;
  final String tagline;
  final Color accent;
}

class WorldProgress {
  const WorldProgress({
    required this.total,
    required this.completed,
    required this.stars,
  });

  final int total;
  final int completed;
  final int stars;
}
