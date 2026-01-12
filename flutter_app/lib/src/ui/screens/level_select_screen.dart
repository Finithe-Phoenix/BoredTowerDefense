import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../widgets/animated_grid_background.dart';
import '../widgets/epic_neon_button.dart';
import '../widgets/neon_title.dart';
import '../../models/level_config.dart';
import '../../services/level_service.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  int? _selectedLevelId;

  @override
  void initState() {
    super.initState();
    final firstUnlocked = LevelService.instance.levels.firstWhere(
      (level) => LevelService.instance.isLevelUnlocked(level.id),
      orElse: () => LevelService.instance.levels.first,
    );
    _selectedLevelId = firstUnlocked.id;
  }

  void _selectLevel(int id) {
    setState(() {
      _selectedLevelId = id;
    });
  }

  String get _selectedHeadline {
    final selected = _currentLevel;
    if (selected == null) return '';
    return 'Stage ${selected.id}: ${selected.name}';
  }

  LevelConfig? get _currentLevel {
    return LevelService.instance.levels.firstWhere(
      (level) => level.id == _selectedLevelId,
      orElse: () => LevelService.instance.levels.first,
    );
  }

  List<String> get _currentLore {
    final id = _selectedLevelId ?? 1;
    return _levelLore[id] ??
        [
          'The Neon Frontier glows brighter with every cleared wave.',
          'Deploy towers to stitch the broken grid back together.',
        ];
  }

  static const Map<int, List<String>> _levelLore = {
    1: [
      'Rookie grid: welcome to the glow.',
      'Weak runners flicker through the cracks—train your towers wisely.',
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

  @override
  Widget build(BuildContext context) {
    final levelService = LevelService.instance;
    final selectedLevel = _currentLevel;
    final selectedProgress = selectedLevel != null
        ? levelService.getProgress(selectedLevel.id)
        : const LevelProgress(levelId: 1);

    return Scaffold(
      body: AnimatedGridBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: NeonColors.cyan),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const NeonTitle(
                            text: 'SELECT LEVEL',
                            fontSize: 32,
                            color: NeonColors.magenta,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Unlock beacons, read the story, and prepare for waves of neon fury.',
                            textAlign: TextAlign.center,
                            style: NeonTextStyles.body.copyWith(
                              color: NeonColors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Selected level hero
              if (selectedLevel != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF031028),
                          Color(0xFF05182F),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: NeonColors.cyan.withOpacity(0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: NeonColors.cyan.withOpacity(0.2),
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
                                color: NeonColors.magenta.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'LEVEL ${selectedLevel.id}',
                                style: NeonTextStyles.small.copyWith(color: NeonColors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedLevel.name.toUpperCase(),
                              style: NeonTextStyles.title.copyWith(
                                fontSize: 26,
                                color: NeonColors.cyan,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.flash_on,
                              color: NeonColors.yellow.withOpacity(0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${selectedProgress.stars}/3 STARS',
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
                              value: '★' * selectedLevel.difficulty,
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
                          'Narrative beats:',
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
                                    color: NeonColors.cyan.withOpacity(0.15),
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
                            Text(
                              'Starting gold ${selectedLevel.startingGold} • Lives ${selectedLevel.startingLives}',
                              style: NeonTextStyles.small.copyWith(
                                color: NeonColors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Level Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: levelService.levels.length,
                    itemBuilder: (context, index) {
                      final level = levelService.levels[index];
                      final progress = levelService.getProgress(level.id);
                      final isUnlocked = levelService.isLevelUnlocked(level.id);

                      return _LevelCard(
                        level: level,
                        progress: progress,
                        isUnlocked: isUnlocked,
                        isSelected: _selectedLevelId == level.id,
                        onSelect: isUnlocked ? () => _selectLevel(level.id) : null,
                        onTap: isUnlocked
                            ? () {
                                Navigator.pushNamed(
                                  context,
                                  '/game',
                                  arguments: level.id,
                                );
                              }
                            : null,
                      );
                    },
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
                              '${widget.level.id}',
                              style: NeonTextStyles.title.copyWith(
                                fontSize: 28,
                                color: _cardColor.withOpacity(
                                    widget.isUnlocked ? 1 : 0.3),
                              ),
                            ),
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
