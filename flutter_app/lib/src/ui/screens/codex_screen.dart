import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../data/story_data.dart';
import '../../services/level_service.dart';
import '../theme/neon_theme.dart';
import '../widgets/animated_grid_background.dart';
import '../widgets/epic_neon_button.dart';
import '../widgets/glitch_text.dart';

/// Codex/Lore screen showing unlocked story entries
class CodexScreen extends StatefulWidget {
  const CodexScreen({super.key});

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;

  LoreCategory? _selectedCategory;
  LoreEntry? _selectedEntry;
  int _maxCompletedLevel = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scanController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _loadProgress();
  }

  void _loadProgress() {
    final levelService = LevelService.instance;
    int maxLevel = 0;
    for (final level in levelService.levels) {
      if (levelService.getProgress(level.id).completed) {
        if (level.id > maxLevel) maxLevel = level.id;
      }
    }
    setState(() {
      _maxCompletedLevel = maxLevel;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  List<LoreEntry> get _unlockedEntries {
    return StoryData.getUnlockedLore(_maxCompletedLevel);
  }

  List<LoreEntry> get _filteredEntries {
    if (_selectedCategory == null) return _unlockedEntries;
    return _unlockedEntries.where((e) => e.category == _selectedCategory).toList();
  }

  int _totalEntriesForCategory(LoreCategory? category) {
    if (category == null) {
      return StoryData.loreEntries.length;
    }
    return StoryData.loreEntries.values.where((e) => e.category == category).length;
  }

  int _unlockedEntriesForCategory(LoreCategory? category) {
    if (category == null) return _unlockedEntries.length;
    return _unlockedEntries.where((e) => e.category == category).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGridBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Category tabs
              _buildCategoryTabs(),

              // Content
              Expanded(
                child: _selectedEntry != null
                    ? _buildEntryDetail()
                    : _buildEntryList(),
              ),

              // Bottom bar
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Back button (if viewing detail)
              if (_selectedEntry != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: NeonColors.cyan),
                  onPressed: () => setState(() => _selectedEntry = null),
                ),

              Expanded(
                child: Column(
                  children: [
                    GlitchText(
                      text: 'ARCHIVOS DEL SISTEMA',
                      style: NeonTextStyles.title.copyWith(
                        fontSize: 28,
                        color: NeonColors.cyan,
                        letterSpacing: 4,
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                    const SizedBox(height: 8),
                    _buildProgressIndicator(),
                  ],
                ),
              ),

              // Placeholder for symmetry
              if (_selectedEntry != null)
                const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final total = StoryData.loreEntries.length;
    final unlocked = _unlockedEntries.length;
    final progress = total > 0 ? unlocked / total : 0.0;

    return Column(
      children: [
        Container(
          height: 6,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [NeonColors.cyan, NeonColors.magenta],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: NeonColors.cyan.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$unlocked / $total ARCHIVOS RECUPERADOS',
          style: NeonTextStyles.small.copyWith(
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryTab(null, 'TODOS', Icons.folder_open),
          _buildCategoryTab(LoreCategory.systemLogs, 'LOGS', Icons.terminal),
          _buildCategoryTab(LoreCategory.characters, 'PERFILES', Icons.person),
          _buildCategoryTab(LoreCategory.locations, 'ZONAS', Icons.map),
          _buildCategoryTab(LoreCategory.enemies, 'AMENAZAS', Icons.dangerous),
          _buildCategoryTab(LoreCategory.phenomena, 'FENÓMENOS', Icons.science),
          _buildCategoryTab(LoreCategory.secrets, 'SECRETOS', Icons.lock),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(LoreCategory? category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;
    final unlocked = _unlockedEntriesForCategory(category);
    final total = _totalEntriesForCategory(category);
    final hasEntries = unlocked > 0;

    return GestureDetector(
      onTap: hasEntries ? () => setState(() {
        _selectedCategory = category;
        _selectedEntry = null;
      }) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? NeonColors.cyan.withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? NeonColors.cyan
                : hasEntries
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? NeonColors.cyan
                  : hasEntries
                      ? Colors.white.withOpacity(0.6)
                      : Colors.white.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: NeonTextStyles.small.copyWith(
                color: isSelected
                    ? NeonColors.cyan
                    : hasEntries
                        ? Colors.white.withOpacity(0.8)
                        : Colors.white.withOpacity(0.3),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? NeonColors.cyan.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$unlocked/$total',
                style: NeonTextStyles.small.copyWith(
                  fontSize: 9,
                  color: isSelected
                      ? NeonColors.cyan
                      : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryList() {
    final entries = _filteredEntries;

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'SIN ARCHIVOS DESBLOQUEADOS',
              style: NeonTextStyles.subtitle.copyWith(
                color: Colors.white.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa niveles para recuperar archivos del sistema',
              style: NeonTextStyles.body.copyWith(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildEntryCard(entry, index);
      },
    );
  }

  Widget _buildEntryCard(LoreEntry entry, int index) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowIntensity = 0.2 + (_pulseController.value * 0.1);

        return GestureDetector(
          onTap: () => setState(() => _selectedEntry = entry),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NeonColors.surfaceBg.withOpacity(0.8),
              border: Border.all(
                color: entry.accentColor.withOpacity(0.4),
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: entry.accentColor.withOpacity(glowIntensity),
                  blurRadius: 15,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: entry.accentColor.withOpacity(0.15),
                    border: Border.all(color: entry.accentColor.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(entry.category),
                      color: entry.accentColor,
                      size: 24,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Entry info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: entry.accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.categoryName,
                              style: NeonTextStyles.small.copyWith(
                                color: entry.accentColor,
                                fontSize: 9,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'NIVEL ${entry.unlockLevel}+',
                            style: NeonTextStyles.small.copyWith(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.title,
                        style: NeonTextStyles.body.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: entry.accentColor.withOpacity(0.6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEntryDetail() {
    if (_selectedEntry == null) return const SizedBox.shrink();

    final entry = _selectedEntry!;

    return Stack(
      children: [
        // Scan line effect
        AnimatedBuilder(
          animation: _scanController,
          builder: (context, child) {
            return CustomPaint(
              painter: _ScanLinePainter(
                progress: _scanController.value,
                color: entry.accentColor.withOpacity(0.03),
              ),
              size: Size.infinite,
            );
          },
        ),

        // Content
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: entry.accentColor.withOpacity(0.1),
                  border: Border.all(color: entry.accentColor.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: entry.accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(entry.category),
                        color: entry.accentColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.categoryName,
                            style: NeonTextStyles.small.copyWith(
                              color: entry.accentColor,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GlitchText(
                            text: entry.title,
                            style: NeonTextStyles.subtitle.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Content box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: NeonColors.darkBg.withOpacity(0.9),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Terminal header
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: NeonColors.red.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: NeonColors.yellow.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: NeonColors.green.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ARCHIVO_${entry.id.toUpperCase()}.DAT',
                          style: NeonTextStyles.small.copyWith(
                            color: Colors.white.withOpacity(0.4),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 16),

                    // Entry content
                    SelectableText(
                      entry.content,
                      style: NeonTextStyles.body.copyWith(
                        color: entry.accentColor.withOpacity(0.9),
                        height: 1.8,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Unlock info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_open,
                      color: NeonColors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Desbloqueado al completar el nivel ${entry.unlockLevel}',
                      style: NeonTextStyles.small.copyWith(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: EpicNeonButton(
        text: 'VOLVER',
        icon: Icons.arrow_back,
        color: NeonColors.cyan,
        width: 180,
        height: 48,
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  IconData _getCategoryIcon(LoreCategory category) {
    switch (category) {
      case LoreCategory.systemLogs:
        return Icons.terminal;
      case LoreCategory.characters:
        return Icons.person;
      case LoreCategory.locations:
        return Icons.map;
      case LoreCategory.enemies:
        return Icons.dangerous;
      case LoreCategory.phenomena:
        return Icons.science;
      case LoreCategory.secrets:
        return Icons.lock;
    }
  }
}

/// Scan line painter for detail view
class _ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          color,
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 80));

    final y = progress * size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, y - 40, size.width, 80),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
