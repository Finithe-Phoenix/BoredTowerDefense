import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../widgets/cyber_grid_background.dart';
import '../widgets/epic_neon_button.dart';
import '../widgets/epic_neon_title.dart';
import '../../models/level_config.dart';
import '../../services/level_service.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen>
    with TickerProviderStateMixin {
  int? _selectedLevelId;
  int _selectedWorld = 1;
  static const int _levelsPerWorld = 10;
  late final PageController _worldController;
  late final AnimationController _orbitController;

  static const List<_WorldInfo> _worlds = [
    _WorldInfo(
      id: 1,
      name: 'Neon Frontier',
      tagline: 'Reignite the grid and lock the first gates.',
      accent: NeonColors.cyan,
    ),
    _WorldInfo(
      id: 2,
      name: 'Rift Wars',
      tagline: 'Shattered lanes and phantom storms rise.',
      accent: NeonColors.magenta,
    ),
    _WorldInfo(
      id: 3,
      name: 'Signal Wastes',
      tagline: 'Dead zones flicker with rogue pulses.',
      accent: NeonColors.yellow,
    ),
    _WorldInfo(
      id: 4,
      name: 'Ion Crown',
      tagline: 'Arc storms crown the upper lattice.',
      accent: NeonColors.green,
    ),
    _WorldInfo(
      id: 5,
      name: 'Shard Vault',
      tagline: 'Ancient caches awaken with hostile code.',
      accent: NeonColors.red,
    ),
    _WorldInfo(
      id: 6,
      name: 'Arc Fortress',
      tagline: 'Enemy sieges compress into tighter lanes.',
      accent: NeonColors.purple,
    ),
    _WorldInfo(
      id: 7,
      name: 'Core Hunt',
      tagline: 'Every wave targets your core directly.',
      accent: NeonColors.orange,
    ),
    _WorldInfo(
      id: 8,
      name: 'Omega Grid',
      tagline: 'Feedback loops overload the lattice.',
      accent: NeonColors.blue,
    ),
    _WorldInfo(
      id: 9,
      name: 'Storm Tower',
      tagline: 'Lightning corridors fracture movement.',
      accent: NeonColors.cyan,
    ),
    _WorldInfo(
      id: 10,
      name: 'Final Gate',
      tagline: 'The last lock holds the endless surge.',
      accent: NeonColors.white,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final firstUnlocked = LevelService.instance.levels.firstWhere(
      (level) => LevelService.instance.isLevelUnlocked(level.id),
      orElse: () => LevelService.instance.levels.first,
    );
    _selectedLevelId = firstUnlocked.id;
    _selectedWorld = _worldForLevel(firstUnlocked.id);
    _worldController = PageController(initialPage: _selectedWorld - 1);
    _orbitController = AnimationController(
      duration: const Duration(seconds: 18),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _worldController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  void _selectLevel(int id) {
    setState(() {
      _selectedLevelId = id;
    });
  }

  void _selectWorld(int worldId) {
    if (_selectedWorld == worldId) return;
    setState(() {
      _selectedWorld = worldId;
      final worldLevels = _levelsForWorld(worldId);
      if (worldLevels.isEmpty) {
        _selectedLevelId = null;
        return;
      }
      final firstUnlocked = worldLevels.firstWhere(
        (level) => LevelService.instance.isLevelUnlocked(level.id),
        orElse: () => worldLevels.first,
      );
      _selectedLevelId = firstUnlocked.id;
    });
  }

  void _jumpToWorld(int worldId) {
    if (worldId < 1 || worldId > _worlds.length) return;
    if (_worldController.hasClients) {
      _worldController.animateToPage(
        worldId - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
    _selectWorld(worldId);
  }

  String get _selectedHeadline {
    final selected = _currentLevel;
    if (selected == null) return '';
    return 'Stage ${selected.id}: ${selected.name}';
  }

  LevelConfig? get _currentLevel {
    final worldLevels = _levelsForWorld(_selectedWorld);
    if (worldLevels.isEmpty) return null;
    if (_selectedLevelId == null) return worldLevels.first;
    for (final level in worldLevels) {
      if (level.id == _selectedLevelId) return level;
    }
    return worldLevels.first;
  }

  List<String> get _currentLore {
    final id = _selectedLevelId ?? 1;
    return _levelLore[id] ??
        _worldLore[_selectedWorld] ??
        [
          'The Neon Frontier glows brighter with every cleared wave.',
          'Deploy towers to stitch the broken grid back together.',
        ];
  }

  static const Map<int, List<String>> _levelLore = {
    1: [
      'Rookie grid: welcome to the glow.',
      'Weak runners flicker through the cracks. Train your towers wisely.',
    ],
    2: [
      'Circuit Canyon: paths fold on themselves.',
      'Use precision and timing, the Corridor moves fast.',
    ],
    3: [
      'Horizon Spire: Juggernauts rise from the deep.',
      'Hold choke points and detonate mines with purpose.',
    ],
    4: [
      'Pulse Sector: phantom specters skip across light.',
      'Phase mages reveal hidden foes and keep beams lit.',
    ],
  };

  static const Map<int, List<String>> _worldLore = {
    1: [
      'World 1: Neon Frontier ignites the first circuits.',
      'Build your rhythm and lock down every lane.',
    ],
    2: [
      'World 2: Rift Wars bend the lanes and spawn phantoms.',
      'Expect tighter corners and heavier swarms.',
    ],
    3: [
      'World 3: Signal Wastes strip the grid bare.',
      'Long corridors punish slow reactions.',
    ],
    4: [
      'World 4: Ion Crown tightens the choke points.',
      'Every lane tests precision placement.',
    ],
    5: [
      'World 5: Shard Vault hides sudden reroutes.',
      'Prepare for clustered spawns and fast pivots.',
    ],
    6: [
      'World 6: Arc Fortress floods lanes with overloads.',
      'Hold the midline or lose the core.',
    ],
    7: [
      'World 7: Core Hunt accelerates every surge.',
      'Phantoms spike between heavy waves.',
    ],
    8: [
      'World 8: Omega Grid breaks rhythm.',
      'Adapt to relentless pressure spikes.',
    ],
    9: [
      'World 9: Storm Tower fractures corridors.',
      'Every mistake compounds.',
    ],
    10: [
      'World 10: Final Gate is the last lock.',
      'Survive the endless cascade.',
    ],
  };

  int _worldForLevel(int levelId) => ((levelId - 1) ~/ _levelsPerWorld) + 1;

  int _levelInWorld(int levelId) => ((levelId - 1) % _levelsPerWorld) + 1;

  List<LevelConfig> _levelsForWorld(int worldId) {
    return LevelService.instance.levels
        .where((level) => _worldForLevel(level.id) == worldId)
        .toList(growable: false);
  }

  _WorldInfo _worldInfo(int worldId) {
    return _worlds.firstWhere(
      (world) => world.id == worldId,
      orElse: () => _worlds.first,
    );
  }

  _WorldProgress _worldProgress(LevelService service, int worldId) {
    final levels = _levelsForWorld(worldId);
    int completed = 0;
    int stars = 0;
    for (final level in levels) {
      final progress = service.getProgress(level.id);
      if (progress.completed) {
        completed += 1;
      }
      stars += progress.stars;
    }
    return _WorldProgress(
      total: levels.length,
      completed: completed,
      stars: stars,
    );
  }

  bool _isWorldUnlocked(LevelService service, int worldId) {
    final levels = _levelsForWorld(worldId);
    if (levels.isEmpty) return false;
    for (final level in levels) {
      if (service.isLevelUnlocked(level.id)) {
        return true;
      }
    }
    return false;
  }

  Widget _buildWorldProgressBar(double progress, Color accent) {
    final clamped = progress.clamp(0.0, 1.0);
    return Container(
      height: 6,
      width: 140,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withOpacity(0.9),
                accent.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: -2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorldOverview(_WorldInfo world, _WorldProgress progress) {
    final total = progress.total;
    final completion = total == 0 ? 0.0 : progress.completed / total;
    final maxStars = total * 3;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF070D18),
                Color(0xFF0D1B2C),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: world.accent.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: world.accent.withOpacity(0.22),
                blurRadius: 26,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WORLD ${world.id}',
                      style: NeonTextStyles.small.copyWith(
                        color: world.accent.withOpacity(0.9),
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      world.name.toUpperCase(),
                      style: NeonTextStyles.title.copyWith(
                        fontSize: 20,
                        color: NeonColors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      world.tagline,
                      style: NeonTextStyles.small.copyWith(
                        color: NeonColors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${progress.completed}/$total LEVELS',
                    style: NeonTextStyles.small.copyWith(
                      color: NeonColors.white.withOpacity(0.75),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${progress.stars}/$maxStars STARS',
                    style: NeonTextStyles.small.copyWith(
                      color: world.accent.withOpacity(0.8),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildWorldProgressBar(completion, world.accent),
                ],
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _CornerFramePainter(color: world.accent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderDivider(Color accent) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            accent.withOpacity(0.6),
            accent.withOpacity(0.9),
            accent.withOpacity(0.6),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeonColors.cyan.withOpacity(0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: NeonColors.cyan.withOpacity(0.25),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: NeonColors.cyan),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  String _difficultyBars(int value) {
    if (value <= 0) return '';
    return List.filled(value, 'I').join();
  }

  Widget _buildUniversePager(LevelService levelService) {
    return PageView.builder(
      controller: _worldController,
      onPageChanged: (index) => _selectWorld(_worlds[index].id),
      itemCount: _worlds.length,
      itemBuilder: (context, index) {
        final world = _worlds[index];
        final levels = _levelsForWorld(world.id);
        return _buildUniverseMap(
          world: world,
          levels: levels,
          levelService: levelService,
        );
      },
    );
  }

  Widget _buildUniverseMap({
    required _WorldInfo world,
    required List<LevelConfig> levels,
    required LevelService levelService,
  }) {
    return AnimatedBuilder(
      animation: _orbitController,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final center = Offset(size.width / 2, size.height / 2);
            final orbitRadius = math.min(size.width, size.height) * 0.32;
            final nodeRadius = math.max(14.0, math.min(size.width, size.height) * 0.04);
            final rotation = _orbitController.value * math.pi * 2 * 0.15;
            final count = math.max(1, levels.length);
            final angleStep = (math.pi * 2) / count;
            final startAngle = -math.pi / 2 + rotation;
            final nodePositions = <Offset>[];
            for (int i = 0; i < levels.length; i++) {
              final angle = startAngle + angleStep * i;
              nodePositions.add(Offset(
                center.dx + orbitRadius * math.cos(angle),
                center.dy + orbitRadius * math.sin(angle),
              ));
            }

            final progress = _worldProgress(levelService, world.id);

            return Stack(
              children: [
                CustomPaint(
                  size: size,
                  painter: _OrbitPainter(
                    center: center,
                    orbitRadius: orbitRadius,
                    nodePositions: nodePositions,
                    accent: world.accent,
                  ),
                ),
                Positioned(
                  left: center.dx - 120,
                  top: center.dy - 80,
                  child: _WorldCoreNode(
                    world: world,
                    progress: progress,
                  ),
                ),
                for (int i = 0; i < levels.length; i++)
                  Positioned(
                    left: nodePositions[i].dx - nodeRadius,
                    top: nodePositions[i].dy - nodeRadius,
                    child: _OrbitLevelNode(
                      radius: nodeRadius,
                      levelId: levels[i].id,
                      localIndex: _levelInWorld(levels[i].id),
                      accent: world.accent,
                      isSelected: _selectedLevelId == levels[i].id,
                      isUnlocked: levelService.isLevelUnlocked(levels[i].id),
                      stars: levelService.getProgress(levels[i].id).stars,
                      onTap: () => _selectLevel(levels[i].id),
                    ),
                  ),
                Positioned(
                  left: 12,
                  top: center.dy - 24,
                  child: _NavArrow(
                    icon: Icons.chevron_left,
                    enabled: world.id > 1,
                    onPressed: () => _jumpToWorld(world.id - 1),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: center.dy - 24,
                  child: _NavArrow(
                    icon: Icons.chevron_right,
                    enabled: world.id < _worlds.length,
                    onPressed: () => _jumpToWorld(world.id + 1),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLevelHero({
    required LevelService levelService,
    required _WorldInfo selectedWorld,
    required int selectedWorldIndex,
    required int selectedLocalLevel,
    required LevelConfig selectedLevel,
    required LevelProgress selectedProgress,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF031028),
            Color(0xFF05182F),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedWorld.accent.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: selectedWorld.accent.withOpacity(0.2),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: selectedWorld.accent.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'WORLD $selectedWorldIndex / LEVEL $selectedLocalLevel',
                  style: NeonTextStyles.small.copyWith(color: NeonColors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${selectedWorld.name.toUpperCase()} / ${selectedLevel.name.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NeonTextStyles.title.copyWith(
                    fontSize: 22,
                    color: selectedWorld.accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.flash_on,
                color: NeonColors.yellow.withOpacity(0.8),
              ),
              const SizedBox(width: 6),
              Text(
                '${selectedProgress.stars}/3',
                style: NeonTextStyles.small.copyWith(
                  color: NeonColors.yellow.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                label: 'WAVES',
                value: '${selectedLevel.waves}',
                color: NeonColors.green,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'DIFFICULTY',
                value: _difficultyBars(selectedLevel.difficulty),
                color: NeonColors.red,
                background: NeonColors.red.withOpacity(0.1),
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'BEST WAVE',
                value: '${selectedProgress.bestWave}',
                color: NeonColors.purple,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            selectedWorld.tagline,
            style: NeonTextStyles.small.copyWith(
              color: NeonColors.white.withOpacity(0.7),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            runSpacing: 4,
            spacing: 6,
            children: _currentLore
                .map(
                  (text) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selectedWorld.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      text,
                      style: NeonTextStyles.small.copyWith(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              EpicNeonButton(
                text: 'PLAY LEVEL',
                icon: Icons.play_arrow_rounded,
                color: NeonColors.green,
                width: 160,
                height: 44,
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/game',
                    arguments: selectedLevel.id,
                  );
                },
                enabled: levelService.isLevelUnlocked(selectedLevel.id),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Starting gold ${selectedLevel.startingGold} | Lives ${selectedLevel.startingLives}',
                  style: NeonTextStyles.small.copyWith(
                    color: NeonColors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelService = LevelService.instance;
    final selectedLevel = _currentLevel;
    final selectedProgress = selectedLevel != null
        ? levelService.getProgress(selectedLevel.id)
        : const LevelProgress(levelId: 1);
    final selectedWorld = _worldInfo(_selectedWorld);
    final selectedWorldIndex =
        selectedLevel != null ? _worldForLevel(selectedLevel.id) : _selectedWorld;
    final selectedLocalLevel =
        selectedLevel != null ? _levelInWorld(selectedLevel.id) : 1;

    return Scaffold(
      body: CyberGridBackground(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildBackButton(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              EpicNeonTitle(
                                text: 'WORLD GRID',
                                fontSize: 38,
                                primaryColor: selectedWorld.accent,
                                secondaryColor: NeonColors.cyan,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose a world, then lock in a level. The grid awaits.',
                                textAlign: TextAlign.center,
                                style: NeonTextStyles.body.copyWith(
                                  color: NeonColors.white.withOpacity(0.65),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 52),
                      ],
                    ),
                    _buildHeaderDivider(selectedWorld.accent),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildUniversePager(levelService),
                ),
              ),
              const SizedBox(height: 8),
              if (selectedLevel != null)
                Flexible(
                  flex: 4,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildLevelHero(
                      levelService: levelService,
                      selectedWorld: selectedWorld,
                      selectedWorldIndex: selectedWorldIndex,
                      selectedLocalLevel: selectedLocalLevel,
                      selectedLevel: selectedLevel,
                      selectedProgress: selectedProgress,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatefulWidget {
  const _LevelCard({
    required this.level,
    required this.progress,
    required this.isUnlocked,
    required this.isSelected,
    this.onTap,
    this.onSelect,
  });

  final LevelConfig level;
  final LevelProgress progress;
  final bool isUnlocked;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onSelect;

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  int _levelInWorld(int levelId) => ((levelId - 1) % 10) + 1;

  int _worldForLevel(int levelId) => ((levelId - 1) ~/ 10) + 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _cardColor {
    if (!widget.isUnlocked) return Colors.grey;
    if (widget.progress.completed) return NeonColors.green;
    return NeonColors.cyan;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          if (widget.isUnlocked) {
            widget.onSelect?.call();
            widget.onTap?.call();
          }
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final glowIntensity = _isHovered ? 1.0 : 0.3 + _controller.value * 0.3;
            final localLevel = _levelInWorld(widget.level.id);
            final worldIndex = _worldForLevel(widget.level.id);

            return Container(
              decoration: BoxDecoration(
                color: NeonColors.darkBg.withOpacity(0.9),
                border: Border.all(
                  color: widget.isSelected
                      ? NeonColors.yellow.withOpacity(0.9)
                      : _cardColor.withOpacity(widget.isUnlocked ? glowIntensity : 0.3),
                  width: widget.isSelected ? 3 : 2,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: widget.isUnlocked
                    ? [
                        BoxShadow(
                          color: widget.isSelected
                              ? NeonColors.yellow.withOpacity(0.35)
                              : _cardColor.withOpacity(glowIntensity * 0.3),
                          blurRadius: widget.isSelected ? 18 : (_isHovered ? 15 : 8),
                          spreadRadius: widget.isSelected ? 3 : (_isHovered ? 2 : 0),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Level number
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$localLevel',
                              style: NeonTextStyles.title.copyWith(
                                fontSize: 28,
                                color: _cardColor.withOpacity(
                                    widget.isUnlocked ? 1 : 0.3),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'W$worldIndex',
                                  style: NeonTextStyles.small.copyWith(
                                    color: _cardColor.withOpacity(
                                        widget.isUnlocked ? 0.8 : 0.3),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Stars
                                Row(
                                  children: List.generate(3, (i) {
                                    final earned = i < widget.progress.stars;
                                    return Icon(
                                      earned ? Icons.star : Icons.star_border,
                                      color: earned
                                          ? NeonColors.yellow
                                          : NeonColors.yellow.withOpacity(0.3),
                                      size: 16,
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Level name
                        Text(
                          widget.level.name,
                          style: NeonTextStyles.body.copyWith(
                            fontSize: 12,
                            color: widget.isUnlocked
                                ? NeonColors.white
                                : NeonColors.white.withOpacity(0.3),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Difficulty
                        Row(
                          children: List.generate(5, (i) {
                            final filled = i < widget.level.difficulty;
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 2),
                              decoration: BoxDecoration(
                                color: filled
                                    ? NeonColors.red.withOpacity(
                                        widget.isUnlocked ? 1 : 0.3)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: NeonColors.red.withOpacity(
                                      widget.isUnlocked ? 0.5 : 0.2),
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 4),

                        // Waves info
                        Text(
                          '${widget.level.waves} waves',
                          style: NeonTextStyles.small.copyWith(
                            fontSize: 10,
                            color: NeonColors.green.withOpacity(
                                widget.isUnlocked ? 0.8 : 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lock overlay
                  if (!widget.isUnlocked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
                      ),
                    ),

                  // Completed checkmark
                  if (widget.progress.completed)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: NeonColors.green,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: NeonColors.green.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: NeonColors.darkBg,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WorldInfo {
  const _WorldInfo({
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

class _WorldProgress {
  const _WorldProgress({
    required this.total,
    required this.completed,
    required this.stars,
  });

  final int total;
  final int completed;
  final int stars;
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    this.background,
  });

  final String label;
  final String value;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: NeonTextStyles.small.copyWith(
              color: NeonColors.white.withOpacity(0.6),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: NeonTextStyles.body.copyWith(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerFramePainter extends CustomPainter {
  _CornerFramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 8.0;
    const corner = 18.0;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final linePaint = Paint()
      ..color = color.withOpacity(0.85)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    void drawCorner(double x, double y, double hDir, double vDir) {
      final path = Path()
        ..moveTo(x, y + corner * vDir)
        ..lineTo(x, y)
        ..lineTo(x + corner * hDir, y);
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, linePaint);
    }

    drawCorner(inset, inset, 1, 1);
    drawCorner(size.width - inset, inset, -1, 1);
    drawCorner(inset, size.height - inset, 1, -1);
    drawCorner(size.width - inset, size.height - inset, -1, -1);
  }

  @override
  bool shouldRepaint(_CornerFramePainter oldDelegate) => oldDelegate.color != color;
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.center,
    required this.orbitRadius,
    required this.nodePositions,
    required this.accent,
  });

  final Offset center;
  final double orbitRadius;
  final List<Offset> nodePositions;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final ringPaint = Paint()
      ..color = accent.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, orbitRadius, ringPaint);

    final dashPaint = Paint()
      ..color = accent.withOpacity(0.2)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const dashCount = 14;
    for (int i = 0; i < dashCount; i++) {
      final angle = (i / dashCount) * math.pi * 2;
      final start = Offset(
        center.dx + (orbitRadius - 6) * math.cos(angle),
        center.dy + (orbitRadius - 6) * math.sin(angle),
      );
      final end = Offset(
        center.dx + (orbitRadius + 6) * math.cos(angle),
        center.dy + (orbitRadius + 6) * math.sin(angle),
      );
      canvas.drawLine(start, end, dashPaint);
    }

    final linkPaint = Paint()
      ..color = accent.withOpacity(0.16)
      ..strokeWidth = 1;
    for (final node in nodePositions) {
      canvas.drawLine(center, node, linkPaint);
    }

    final coreGlow = Paint()
      ..color = accent.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, orbitRadius * 0.08, coreGlow);
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) {
    return oldDelegate.nodePositions != nodePositions ||
        oldDelegate.accent != accent ||
        oldDelegate.orbitRadius != orbitRadius;
  }
}

class _WorldCoreNode extends StatelessWidget {
  const _WorldCoreNode({
    required this.world,
    required this.progress,
  });

  final _WorldInfo world;
  final _WorldProgress progress;

  @override
  Widget build(BuildContext context) {
    final maxStars = progress.total * 3;
    return SizedBox(
      width: 240,
      height: 160,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0B1326),
              Color(0xFF101B35),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: world.accent.withOpacity(0.6), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: world.accent.withOpacity(0.25),
              blurRadius: 22,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WORLD ${world.id}',
              style: NeonTextStyles.small.copyWith(
                color: world.accent.withOpacity(0.9),
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              world.name.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: NeonTextStyles.title.copyWith(
                fontSize: 18,
                color: NeonColors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              world.tagline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: NeonTextStyles.small.copyWith(
                color: NeonColors.white.withOpacity(0.6),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  '${progress.completed}/${progress.total} LVL',
                  style: NeonTextStyles.small.copyWith(
                    color: NeonColors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${progress.stars}/$maxStars STARS',
                  style: NeonTextStyles.small.copyWith(
                    color: world.accent.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitLevelNode extends StatelessWidget {
  const _OrbitLevelNode({
    required this.radius,
    required this.levelId,
    required this.localIndex,
    required this.accent,
    required this.isSelected,
    required this.isUnlocked,
    required this.stars,
    required this.onTap,
  });

  final double radius;
  final int levelId;
  final int localIndex;
  final Color accent;
  final bool isSelected;
  final bool isUnlocked;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked ? accent : Colors.grey;
    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.75),
          border: Border.all(
            color: isSelected ? NeonColors.yellow : color.withOpacity(0.7),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            if (isUnlocked)
              BoxShadow(
                color: color.withOpacity(isSelected ? 0.4 : 0.2),
                blurRadius: isSelected ? 14 : 8,
                spreadRadius: isSelected ? 2 : 0,
              ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$localIndex',
                style: NeonTextStyles.body.copyWith(
                  color: isUnlocked
                      ? (isSelected ? NeonColors.yellow : color)
                      : Colors.white.withOpacity(0.4),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!isUnlocked)
              const Center(
                child: Icon(
                  Icons.lock,
                  size: 14,
                  color: Colors.white54,
                ),
              ),
            if (stars > 0)
              Positioned(
                right: 4,
                bottom: 2,
                child: Row(
                  children: List.generate(
                    stars.clamp(0, 3),
                    (index) => Icon(
                      Icons.star,
                      size: 8,
                      color: NeonColors.yellow.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 32),
      color: enabled ? NeonColors.cyan.withOpacity(0.8) : Colors.white24,
    );
  }
}
