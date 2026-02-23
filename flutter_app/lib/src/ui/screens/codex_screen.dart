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
  late AnimationController _hologramController;
  late AnimationController _dataStreamController;

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

    // Holographic effects
    _hologramController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    // Data stream animation
    _dataStreamController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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
    _hologramController.dispose();
    _dataStreamController.dispose();
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
                    // Holographic Database Title
                    _HolographicDatabaseTitle(
                      hologramController: _hologramController,
                      dataStreamController: _dataStreamController,
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
      height: 112,
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

    return _PowerNodeTab(
      category: category,
      label: label,
      icon: icon,
      isSelected: isSelected,
      hasEntries: hasEntries,
      unlocked: unlocked,
      total: total,
      pulseController: _pulseController,
      onTap: hasEntries
          ? () => setState(() {
                _selectedCategory = category;
                _selectedEntry = null;
              })
          : null,
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
    return _DataCrystalCard(
      entry: entry,
      index: index,
      pulseController: _pulseController,
      hologramController: _hologramController,
      onTap: () => setState(() => _selectedEntry = entry),
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

// ═══════════════════════════════════════════════════════════════════════════
// EPIC COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Holographic Database Title
class _HolographicDatabaseTitle extends StatelessWidget {
  const _HolographicDatabaseTitle({
    required this.hologramController,
    required this.dataStreamController,
  });

  final AnimationController hologramController;
  final AnimationController dataStreamController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([hologramController, dataStreamController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Rotating holographic rings
            for (int i = 0; i < 3; i++)
              Transform.rotate(
                angle: hologramController.value * math.pi * 2 + (i * math.pi / 3),
                child: Container(
                  width: 200 + (i * 30),
                  height: 200 + (i * 30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: NeonColors.cyan.withOpacity(0.1 - i * 0.03),
                      width: 1,
                    ),
                  ),
                ),
              ),

            // Data stream particles
            CustomPaint(
              size: const Size(300, 60),
              painter: _DataStreamParticlesPainter(
                animation: dataStreamController.value,
              ),
            ),

            // Main title with dual-color
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlitchText(
                  text: 'ARCHIVOS DEL SISTEMA',
                  style: NeonTextStyles.title.copyWith(
                    fontSize: 28,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: [NeonColors.cyan, NeonColors.magenta],
                      ).createShader(const Rect.fromLTWH(0, 0, 300, 50)),
                    letterSpacing: 4,
                    shadows: [
                      Shadow(color: NeonColors.cyan, blurRadius: 20),
                      Shadow(color: NeonColors.magenta, blurRadius: 40),
                    ],
                  ),
                  duration: const Duration(seconds: 4),
                ),
                const SizedBox(height: 4),
                Text(
                  '>>> DATABASE ONLINE <<<',
                  style: NeonTextStyles.small.copyWith(
                    color: NeonColors.cyan.withOpacity(0.7),
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Power Node Tab (Hexagonal)
class _PowerNodeTab extends StatefulWidget {
  const _PowerNodeTab({
    required this.category,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.hasEntries,
    required this.unlocked,
    required this.total,
    required this.pulseController,
    required this.onTap,
  });

  final LoreCategory? category;
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool hasEntries;
  final int unlocked;
  final int total;
  final AnimationController pulseController;
  final VoidCallback? onTap;

  @override
  State<_PowerNodeTab> createState() => _PowerNodeTabState();
}

class _PowerNodeTabState extends State<_PowerNodeTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.hasEntries ? setState(() => _isHovered = true) : null,
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: widget.pulseController,
          builder: (context, child) {
            final glowIntensity = widget.isSelected || _isHovered
                ? 0.5 + widget.pulseController.value * 0.3
                : 0.2;

            return Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? NeonColors.cyan.withOpacity(0.15)
                    : _isHovered
                        ? Colors.white.withOpacity(0.05)
                        : Colors.transparent,
                border: Border.all(
                  color: widget.isSelected
                      ? NeonColors.cyan.withOpacity(glowIntensity)
                      : widget.hasEntries
                          ? Colors.white.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                  width: widget.isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: widget.isSelected || _isHovered
                    ? [
                        BoxShadow(
                          color: NeonColors.cyan.withOpacity(glowIntensity * 0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with hexagonal background
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Hexagonal glow
                      if (widget.isSelected)
                        CustomPaint(
                          size: const Size(40, 40),
                          painter: _HexagonPainter(
                            color: NeonColors.cyan.withOpacity(glowIntensity * 0.3),
                          ),
                        ),

                      // Icon
                      Icon(
                        widget.icon,
                        size: 20,
                        color: widget.isSelected
                            ? NeonColors.cyan
                            : widget.hasEntries
                                ? Colors.white.withOpacity(0.7)
                                : Colors.white.withOpacity(0.3),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Label
                  Text(
                    widget.label,
                    style: NeonTextStyles.small.copyWith(
                      fontSize: 10,
                      color: widget.isSelected
                          ? NeonColors.cyan
                          : widget.hasEntries
                              ? Colors.white.withOpacity(0.8)
                              : Colors.white.withOpacity(0.3),
                      fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? NeonColors.cyan.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.unlocked}/${widget.total}',
                      style: NeonTextStyles.small.copyWith(
                        fontSize: 8,
                        color: widget.isSelected
                            ? NeonColors.cyan
                            : Colors.white.withOpacity(0.5),
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

/// Data Crystal Card (20+ Visual Layers)
class _DataCrystalCard extends StatefulWidget {
  const _DataCrystalCard({
    required this.entry,
    required this.index,
    required this.pulseController,
    required this.hologramController,
    required this.onTap,
  });

  final LoreEntry entry;
  final int index;
  final AnimationController pulseController;
  final AnimationController hologramController;
  final VoidCallback onTap;

  @override
  State<_DataCrystalCard> createState() => _DataCrystalCardState();
}

class _DataCrystalCardState extends State<_DataCrystalCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.pulseController, widget.hologramController]),
        builder: (context, child) {
          final glowIntensity = _isHovered
              ? 0.4 + widget.pulseController.value * 0.3
              : 0.2 + widget.pulseController.value * 0.1;

          return GestureDetector(
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Stack(
                children: [
                  // Layer 1-5: Crystalline facets background
                  for (int i = 0; i < 5; i++)
                    Positioned(
                      left: i * 2.0,
                      top: i * 2.0,
                      right: -i * 2.0,
                      bottom: -i * 2.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.entry.accentColor.withOpacity(0.01 * (5 - i)),
                          border: Border.all(
                            color: widget.entry.accentColor.withOpacity(0.05 * (5 - i)),
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                  // Layer 6: Main card container
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: NeonColors.surfaceBg.withOpacity(0.85),
                      border: Border.all(
                        color: widget.entry.accentColor.withOpacity(_isHovered ? 0.8 : 0.4),
                        width: _isHovered ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        // Layer 7-8: Double glow
                        BoxShadow(
                          color: widget.entry.accentColor.withOpacity(glowIntensity),
                          blurRadius: _isHovered ? 25 : 15,
                          spreadRadius: _isHovered ? 2 : -3,
                        ),
                        BoxShadow(
                          color: widget.entry.accentColor.withOpacity(glowIntensity * 0.5),
                          blurRadius: _isHovered ? 40 : 30,
                          spreadRadius: _isHovered ? 5 : 0,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Layer 9: Holographic shimmer surface
                        if (_isHovered)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _HolographicShimmerPainter(
                                animation: widget.hologramController.value,
                                color: widget.entry.accentColor,
                              ),
                            ),
                          ),

                        // Layer 10-15: Data fragments floating
                        if (_isHovered)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _DataFragmentsPainter(
                                animation: widget.hologramController.value,
                                color: widget.entry.accentColor,
                              ),
                            ),
                          ),

                        // Main content
                        Row(
                          children: [
                            // Layer 16-18: Category icon with effects
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer glow ring
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: widget.entry.accentColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                ),

                                // Icon container
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: widget.entry.accentColor.withOpacity(0.15),
                                    border: Border.all(
                                      color: widget.entry.accentColor.withOpacity(0.6),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.entry.accentColor.withOpacity(0.4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _getCategoryIcon(widget.entry.category),
                                      color: widget.entry.accentColor,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 16),

                            // Entry info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Layer 19: Category badge
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: widget.entry.accentColor.withOpacity(0.2),
                                          border: Border.all(
                                            color: widget.entry.accentColor.withOpacity(0.5),
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                          boxShadow: [
                                            BoxShadow(
                                              color: widget.entry.accentColor.withOpacity(0.3),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          widget.entry.categoryName,
                                          style: NeonTextStyles.small.copyWith(
                                            color: widget.entry.accentColor,
                                            fontSize: 9,
                                            letterSpacing: 1,
                                            shadows: [
                                              Shadow(
                                                color: widget.entry.accentColor,
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'NIVEL ${widget.entry.unlockLevel}+',
                                        style: NeonTextStyles.small.copyWith(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // Layer 20: Title text
                                  Text(
                                    widget.entry.title,
                                    style: NeonTextStyles.body.copyWith(
                                      color: Colors.white.withOpacity(0.95),
                                      fontWeight: FontWeight.bold,
                                      shadows: _isHovered
                                          ? [
                                              Shadow(
                                                color: widget.entry.accentColor,
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Arrow with pulse
                            Icon(
                              Icons.chevron_right,
                              color: widget.entry.accentColor.withOpacity(
                                _isHovered ? glowIntensity : 0.6,
                              ),
                              size: _isHovered ? 28 : 24,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Layer 21+: Corner energy connectors (when hovered)
                  if (_isHovered) ..._buildCornerConnectors(widget.entry.accentColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCornerConnectors(Color color) {
    return [
      Positioned(
        top: 0,
        left: 0,
        child: _CornerConnector(color: color, rotation: 0),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: _CornerConnector(color: color, rotation: math.pi / 2),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: _CornerConnector(color: color, rotation: -math.pi / 2),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: _CornerConnector(color: color, rotation: math.pi),
      ),
    ];
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

// Small corner connector widget
class _CornerConnector extends StatelessWidget {
  const _CornerConnector({required this.color, required this.rotation});

  final Color color;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: color.withOpacity(0.6), width: 2),
            left: BorderSide(color: color.withOpacity(0.6), width: 2),
          ),
        ),
      ),
    );
  }
}

// Custom Painters
class _DataStreamParticlesPainter extends CustomPainter {
  final double animation;

  _DataStreamParticlesPainter({required this.animation});

  static final Paint _particlePaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    int rngState = 0x54321;
    int lcgNext() {
      rngState = (1664525 * rngState + 1013904223) & 0x7fffffff;
      return rngState;
    }
    double nextUnit() => lcgNext() / 0x7fffffff;

    for (int i = 0; i < 20; i++) {
      final x = (nextUnit() * size.width + animation * size.width * 0.5) % size.width;
      final y = nextUnit() * size.height;
      final particleSize = 1 + nextUnit() * 2;

      _particlePaint.color = NeonColors.cyan.withOpacity(0.3 + nextUnit() * 0.4);
      canvas.drawCircle(Offset(x, y), particleSize, _particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DataStreamParticlesPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _HexagonPainter extends CustomPainter {
  final Color color;

  _HexagonPainter({required this.color});

  static final Paint _paint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    _paint.color = color;
    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(covariant _HexagonPainter oldDelegate) => false;
}

class _HolographicShimmerPainter extends CustomPainter {
  final double animation;
  final Color color;

  _HolographicShimmerPainter({required this.animation, required this.color});

  static final Paint _shimmerPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.transparent,
        color.withOpacity(0.05),
        Colors.transparent,
      ],
      stops: [0.0, 0.5, 1.0],
    );

    _shimmerPaint.shader = gradient.createShader(
      Rect.fromLTWH(-size.width + animation * size.width * 2, 0, size.width * 2, size.height),
    );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _shimmerPaint);
  }

  @override
  bool shouldRepaint(covariant _HolographicShimmerPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _DataFragmentsPainter extends CustomPainter {
  final double animation;
  final Color color;

  _DataFragmentsPainter({required this.animation, required this.color});

  static final Paint _fragmentPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    int rngState = 0x12abc;
    int lcgNext() {
      rngState = (1664525 * rngState + 1013904223) & 0x7fffffff;
      return rngState;
    }
    double nextUnit() => lcgNext() / 0x7fffffff;

    for (int i = 0; i < 8; i++) {
      final x = nextUnit() * size.width;
      final baseY = nextUnit() * size.height;
      final y = (baseY + animation * 30) % size.height;
      final fragmentSize = 2 + nextUnit() * 3;

      _fragmentPaint.color = color.withOpacity(0.1 + nextUnit() * 0.2);
      canvas.drawRect(
        Rect.fromLTWH(x, y, fragmentSize, fragmentSize / 2),
        _fragmentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DataFragmentsPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
